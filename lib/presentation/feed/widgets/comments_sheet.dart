import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/entities/post.dart';
import '../../../domain/repositories/feed_repository.dart';
import '../../shared/relative_time_text.dart';
import '../../shared/user_avatar.dart';
import '../notifiers/feed_notifier.dart';
import '../../../core/widgets/app_snackbar.dart';

/// Bottom sheet com lista de comentários e campo para adicionar novos comentários.
class CommentsSheet extends StatefulWidget {
  final String postId;
  final int initialCount;

  const CommentsSheet({
    super.key,
    required this.postId,
    this.initialCount = 0,
  });

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final FeedRepository _feedRepo = sl.feedRepo;
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _composerFocus = FocusNode();
  bool _loading = true;
  bool _sending = false;
  String? _error;
  List<Comment> _comments = [];
  // RF-22 — quando setado, o próximo envio será uma resposta a esse comentário.
  String? _replyTo;
  String? _replyToName;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _composerFocus.dispose();
    super.dispose();
  }

  /// RF-22 — Agrupa comentários em (root, replies). Limita a 1 nível.
  Map<String?, List<Comment>> _byParent() {
    final out = <String?, List<Comment>>{};
    for (final c in _comments) {
      out.putIfAbsent(c.parentCommentId, () => []).add(c);
    }
    return out;
  }

  Future<void> _loadComments() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await _feedRepo.getComments(widget.postId);
      setState(() => _comments = result.data);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendComment() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    setState(() => _sending = true);
    final feedNotifier = context.read<FeedNotifier>();
    try {
      await _feedRepo.addComment(
        widget.postId,
        content,
        parentCommentId: _replyTo,
      );
      _controller.clear();
      setState(() {
        _replyTo = null;
        _replyToName = null;
      });
      feedNotifier.incrementCommentCount(widget.postId);
      await _loadComments();
      // Rolar para o fim após novo comentário
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollController) => Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Título
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Comentários',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (_comments.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    '(${_comments.length})',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1),

          // Lista
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.error_outline, size: 40, color: Colors.red),
                          const SizedBox(height: 8),
                          const Text('Não foi possível carregar os comentários.'),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _loadComments,
                            child: const Text('Tentar novamente'),
                          ),
                        ]),
                      )
                    : _comments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                size: 40,
                                color: Theme.of(context).colorScheme.outline),
                            const SizedBox(height: 8),
                            const Text('Nenhum comentário ainda.'),
                            const Text('Seja o primeiro!'),
                          ],
                        ),
                      )
                    : _buildThreadedList(context),
          ),

          // RF-22 — Banner "respondendo a X" quando há replyTo ativo.
          if (_replyTo != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Theme.of(context).colorScheme.primaryContainer
                  .withValues(alpha: 0.4),
              child: Row(
                children: [
                  Icon(Icons.subdirectory_arrow_right_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('Respondendo a $_replyToName',
                        style: Theme.of(context).textTheme.labelMedium),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16),
                    onPressed: () => setState(() {
                      _replyTo = null;
                      _replyToName = null;
                    }),
                  ),
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
                      focusNode: _composerFocus,
                      decoration: InputDecoration(
                        hintText: _replyTo == null
                            ? 'Escreva um comentário...'
                            : 'Escreva sua resposta...',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      maxLines: 3,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendComment(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton.filled(
                    onPressed: _sending ? null : _sendComment,
                    icon: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
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

  /// RF-22 — Lista hierárquica com root + replies indentadas. 1 nível.
  Widget _buildThreadedList(BuildContext context) {
    final byParent = _byParent();
    final roots = byParent[null] ?? [];

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: roots.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (_, i) {
        final root = roots[i];
        final replies = byParent[root.id] ?? const <Comment>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CommentTile(
              comment: root,
              onReply: () {
                setState(() {
                  _replyTo = root.id;
                  _replyToName = root.authorName ?? 'Usuário';
                });
                _composerFocus.requestFocus();
              },
            ),
            if (replies.isNotEmpty) ...[
              const SizedBox(height: 10),
              for (final r in replies)
                Padding(
                  padding:
                      const EdgeInsets.only(left: 36, bottom: 8),
                  child: _CommentTile(comment: r),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment, this.onReply});
  final Comment comment;
  final VoidCallback? onReply;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final authorName = comment.authorName ?? 'Usuário';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        UserAvatar(
            name: authorName,
            imageUrl: comment.authorAvatarUrl,
            radius: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(authorName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        const Spacer(),
                        RelativeTimeText(
                            date: comment.createdAt, compact: true),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(comment.content),
                  ],
                ),
              ),
              if (onReply != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 6),
                  child: GestureDetector(
                    onTap: onReply,
                    child: Text(
                      'Responder',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
