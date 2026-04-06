import 'package:flutter/foundation.dart';
import '../../../domain/entities/chat.dart';
import '../../../domain/repositories/messaging_repository.dart';

/// Manages the list of chats for the Mensagens tab.
class MessagesNotifier extends ChangeNotifier {
  final MessagingRepository _repo;

  MessagesNotifier(this._repo);

  List<Chat> chats = [];
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      chats = await _repo.listChats();
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<Chat?> createDirectChat(String targetUserId) async {
    try {
      final chat = await _repo.createDirectChat(targetUserId);
      // Prepend to list if not already there
      if (!chats.any((c) => c.id == chat.id)) {
        chats = [chat, ...chats];
        notifyListeners();
      }
      return chat;
    } catch (_) {
      return null;
    }
  }
}
