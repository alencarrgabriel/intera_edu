import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/network/socket_service.dart';
import '../../../domain/entities/chat.dart';
import '../../../domain/repositories/messaging_repository.dart';

/// Manages messages for a single chat room + real-time WebSocket updates.
class ChatRoomNotifier extends ChangeNotifier {
  final String chatId;
  final MessagingRepository _repo;
  final SocketService _socket;

  ChatRoomNotifier({
    required this.chatId,
    required MessagingRepository repo,
    required SocketService socket,
  })  : _repo = repo,
        _socket = socket;

  List<ChatMessage> messages = [];
  bool loading = false;
  bool sending = false;
  String? error;
  bool _typingIndicator = false;
  Timer? _typingTimer;
  StreamSubscription<Map<String, dynamic>>? _messageSub;
  StreamSubscription<Map<String, dynamic>>? _typingSub;

  bool get typingIndicator => _typingIndicator;

  void init() {
    loadMessages();
    _messageSub = _socket.onNewMessage.listen(_onNewMessage);
    _typingSub = _socket.onTyping.listen(_onTyping);
  }

  void _onNewMessage(Map<String, dynamic> data) {
    if (data['chat_id'] != chatId) return;
    final msg = ChatMessage(
      id: data['id'] as String? ?? '',
      chatId: chatId,
      senderId: data['sender_id'] as String? ?? '',
      content: data['content'] as String? ?? '',
      createdAt: DateTime.tryParse(data['created_at'] as String? ?? '') ?? DateTime.now(),
    );
    messages = [...messages, msg];
    notifyListeners();
  }

  void _onTyping(Map<String, dynamic> data) {
    if (data['chatId'] != chatId) return;
    _typingIndicator = data['isTyping'] == true;
    _typingTimer?.cancel();
    if (_typingIndicator) {
      _typingTimer = Timer(const Duration(seconds: 3), () {
        _typingIndicator = false;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  Future<void> loadMessages() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      messages = await _repo.getMessages(chatId);
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty || sending) return;
    sending = true;
    notifyListeners();

    try {
      // Try REST fallback; WebSocket broadcast handles the optimistic update
      await _repo.sendMessage(chatId, content.trim());
    } catch (_) {
      // Socket might have sent it already; ignore double-send errors
    } finally {
      sending = false;
      notifyListeners();
    }
  }

  void notifyTyping(bool isTyping) {
    _socket.emitTyping(chatId, isTyping: isTyping);
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    _typingSub?.cancel();
    _typingTimer?.cancel();
    super.dispose();
  }
}
