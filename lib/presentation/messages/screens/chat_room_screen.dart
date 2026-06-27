import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_notifier.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/network/socket_service.dart';
import '../../../domain/entities/chat.dart';
import '../../shared/user_avatar.dart';
import '../notifiers/chat_room_notifier.dart';
import '../../../core/widgets/app_snackbar.dart';

/// Tela de conversa no padrão Stitch:
/// header com avatar + status online, separador de data, bolhas alinhadas
/// (cinza para recebidas, gradiente para enviadas), indicador de digitação,
/// composer pill com botão de envio circular.
class ChatRoomScreen extends StatefulWidget {
  final String chatId;
  final String? chatName;

  const ChatRoomScreen({super.key, required this.chatId, this.chatName});

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

  /// RF-27 — Anexa arquivo (PDF/imagem ≤10MB).
  Future<void> _attachFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      withData: true,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
    );
    if (result == null || result.files.isEmpty) return;
    final f = result.files.first;
    if (f.bytes == null) return;
    if (f.size > 10 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arquivo maior que 10 MB.')),
      );
      return;
    }
    final ext = (f.extension ?? '').toLowerCase();
    final mime = switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'pdf' => 'application/pdf',
      _ => 'image/jpeg',
    };
    try {
      await sl.messagingRepo.sendAttachment(
        chatId: widget.chatId,
        bytes: f.bytes!,
        filename: f.name,
        mimeType: mime,
      );
      await _notifier.loadMessages();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.chatName ?? 'Conversa';
    return Scaffold(
      backgroundColor: AppTokens.background,
      appBar: _ChatTopBar(name: name),
      body: Column(
        children: [
          Expanded(
            child: _notifier.loading
                ? const Center(child: CircularProgressIndicator())
                : _notifier.error != null
                    ? _ErrorState(message: _notifier.error!)
                    : _notifier.messages.isEmpty
                        ? _EmptyState(chatName: name)
                        : _MessageList(
                            controller: _scrollController,
                            messages: _notifier.messages,
                            currentUserId: _currentUserId,
                          ),
          ),
          if (_notifier.typingIndicator)
            _TypingIndicator(name: name),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'SEUS DADOS ESTÃO PROTEGIDOS SOB A LGPD.',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1.2,
                  color: AppTokens.outlineVariant,
                ),
              ),
            ),
          ),
          _Composer(
            controller: _controller,
            sending: _notifier.sending,
            onTyping: () => _notifier.notifyTyping(true),
            onSubmit: _send,
            onAttach: _attachFile,
          ),
        ],
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _ChatTopBar extends StatelessWidget implements PreferredSizeWidget {
  const _ChatTopBar({required this.name});
  final String name;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 4);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTokens.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leadingWidth: 40,
      leading: IconButton(
        onPressed: () => context.canPop()
            ? context.pop()
            : Navigator.of(context).maybePop(),
        icon: const Icon(Icons.arrow_back_rounded,
            color: AppTokens.onSurface),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          UserAvatar(name: name, radius: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                ),
                Consumer<SocketService>(
                  builder: (_, s, __) => Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: s.connected
                              ? const Color(0xFF22C55E)
                              : AppTokens.outlineVariant,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        s.connected ? 'Online' : 'Offline',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                              color: s.connected
                                  ? const Color(0xFF22C55E)
                                  : AppTokens.outlineVariant,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.videocam_outlined,
              color: AppTokens.primary),
          tooltip: 'Chamada de vídeo',
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.more_vert,
              color: AppTokens.onSurfaceVariant),
        ),
      ],
    );
  }
}

// ── Message list with date dividers ───────────────────────────────────────────

class _MessageList extends StatelessWidget {
  const _MessageList({
    required this.controller,
    required this.messages,
    required this.currentUserId,
  });

  final ScrollController controller;
  final List<ChatMessage> messages;
  final String? currentUserId;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    DateTime? lastDate;
    for (var i = 0; i < messages.length; i++) {
      final m = messages[i];
      final d = DateTime(
          m.createdAt.year, m.createdAt.month, m.createdAt.day);
      if (lastDate == null || d.isAtSameMomentAs(lastDate) == false) {
        items.add(_DateDivider(label: _dayLabel(d)));
      }
      lastDate = d;
      items.add(_Bubble(
        message: m,
        isMe: m.senderId == currentUserId,
      ));
    }

    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      children: items,
    );
  }

  String _dayLabel(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (d == today) return 'HOJE';
    if (d == yesterday) return 'ONTEM';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

class _DateDivider extends StatelessWidget {
  const _DateDivider({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: AppTokens.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppTokens.radiusFull),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: AppTokens.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.isMe});
  final ChatMessage message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final maxW = MediaQuery.of(context).size.width * 0.75;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxW),
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: isMe ? AppTokens.primaryGradient : null,
                      color:
                          isMe ? null : AppTokens.surfaceContainerHigh,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isMe ? 18 : 4),
                        bottomRight: Radius.circular(isMe ? 4 : 18),
                      ),
                      boxShadow: isMe
                          ? [
                              BoxShadow(
                                color: AppTokens.primary
                                    .withValues(alpha: 0.20),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message.fileUrl != null)
                          _AttachmentChip(
                            url: message.fileUrl!,
                            tinted: isMe,
                          ),
                        if (message.content.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(
                                top: message.fileUrl != null ? 6 : 0),
                            child: Text(
                              message.content,
                              style: TextStyle(
                                color: isMe
                                    ? AppTokens.onPrimary
                                    : AppTokens.onSurface,
                                fontSize: 14,
                                height: 1.45,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                    child: Text(
                      _formatTime(message.createdAt),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTokens.outlineVariant,
                            fontSize: 10,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime d) {
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

// ── Typing / Empty / Error ────────────────────────────────────────────────────

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator({required this.name});
  final String name;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, bottom: 6, top: 2),
      child: Row(
        children: [
          Text(
            '· · ·',
            style: TextStyle(
              fontSize: 18,
              color: AppTokens.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${name.split(' ').first} está digitando…',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: AppTokens.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.chatName});
  final String chatName;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppTokens.primaryContainer.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.waving_hand_outlined,
                size: 36, color: AppTokens.primaryDim),
          ),
          const SizedBox(height: 20),
          Text(
            'Comece a conversa com ${chatName.split(' ').first}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mensagens são entregues em tempo real.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTokens.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 48, color: AppTokens.error),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

// ── Composer ──────────────────────────────────────────────────────────────────

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onTyping,
    required this.onSubmit,
    required this.onAttach,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onTyping;
  final VoidCallback onSubmit;
  final VoidCallback onAttach;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            12, 6, 12, 10 + MediaQuery.of(context).viewInsets.bottom),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTokens.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: onAttach,
                icon: const Icon(Icons.attach_file_rounded,
                    color: AppTokens.primary, size: 20),
                padding: EdgeInsets.zero,
                tooltip: 'Anexar arquivo',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTokens.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(28),
                ),
                padding: const EdgeInsets.only(left: 16, right: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        decoration: const InputDecoration(
                          hintText: 'Escreva sua mensagem',
                          isCollapsed: true,
                          border: InputBorder.none,
                          contentPadding:
                              EdgeInsets.symmetric(vertical: 12),
                        ),
                        maxLines: 4,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onChanged: (_) => onTyping(),
                        onSubmitted: (_) => onSubmit(),
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.sentiment_satisfied_alt_outlined,
                          color: AppTokens.onSurfaceVariant),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                      tooltip: 'Emoji',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: sending ? null : AppTokens.primaryGradient,
                color: sending
                    ? AppTokens.outlineVariant.withValues(alpha: 0.4)
                    : null,
                shape: BoxShape.circle,
                boxShadow: sending ? null : AppTokens.primaryShadow,
              ),
              child: IconButton(
                onPressed: sending ? null : onSubmit,
                icon: sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded,
                        color: AppTokens.onPrimary, size: 20),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// RF-27 — Mostra um chip clicável para o anexo. Em produção poderíamos
/// renderizar a imagem inline se for image/*; PDFs sempre como chip.
class _AttachmentChip extends StatelessWidget {
  const _AttachmentChip({required this.url, required this.tinted});
  final String url;
  final bool tinted;

  bool get _isImage =>
      url.toLowerCase().endsWith('.png') ||
      url.toLowerCase().endsWith('.jpg') ||
      url.toLowerCase().endsWith('.jpeg') ||
      url.toLowerCase().endsWith('.webp');

  @override
  Widget build(BuildContext context) {
    if (_isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          width: 220,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            height: 80,
            width: 220,
            color: tinted ? Colors.white24 : AppTokens.surfaceContainerHigh,
            child: const Icon(Icons.image_not_supported_outlined,
                color: Colors.white70),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tinted
            ? Colors.white.withValues(alpha: 0.18)
            : AppTokens.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.picture_as_pdf_outlined,
              size: 18,
              color: tinted ? AppTokens.onPrimary : AppTokens.error),
          const SizedBox(width: 6),
          Text(
            url.split('/').last,
            style: TextStyle(
              fontSize: 13,
              color: tinted ? AppTokens.onPrimary : AppTokens.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
