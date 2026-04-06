import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/network/socket_service.dart';
import '../../../core/auth/auth_notifier.dart';
import '../notifiers/chat_room_notifier.dart';
import '../widgets/message_bubble.dart';

class ChatRoomScreen extends StatefulWidget {
  final String chatId;
  final String? chatName;

  const ChatRoomScreen({
    super.key,
    required this.chatId,
    this.chatName,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  late final ChatRoomNotifier _notifier;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _notifier = ChatRoomNotifier(
      chatId: widget.chatId,
      repo: sl.messagingRepo,
      socket: context.read<SocketService>(),
    );
    _notifier.addListener(_onMessagesUpdated);
    _notifier.init();
    _currentUserId = context.read<AuthNotifier>().userId;
  }

  @override
  void dispose() {
    _notifier.removeListener(_onMessagesUpdated);
    _notifier.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onMessagesUpdated() {
    if (mounted) setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    _notifier.notifyTyping(false);
    await _notifier.sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.chatName ?? 'Conversa')),
      body: Column(
        children: [
          Expanded(
            child: _notifier.loading
                ? const Center(child: CircularProgressIndicator())
                : _notifier.error != null
                    ? Center(child: Text(_notifier.error!))
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 16),
                        itemCount: _notifier.messages.length,
                        itemBuilder: (ctx, i) {
                          final msg = _notifier.messages[i];
                          final isMe = msg.senderId == _currentUserId;
                          return MessageBubble(message: msg, isMe: isMe);
                        },
                      ),
          ),
          if (_notifier.typingIndicator)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Row(
                children: [
                  Text('digitando...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTokens.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          )),
                ],
              ),
            ),
          const Divider(height: 1),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 12,
                right: 8,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Escreva uma mensagem...',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onChanged: (_) => _notifier.notifyTyping(true),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton.filled(
                    onPressed: _notifier.sending ? null : _send,
                    icon: _notifier.sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
