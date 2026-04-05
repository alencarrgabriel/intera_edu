import 'package:flutter/material.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/entities/post.dart';
import '../../../domain/repositories/feed_repository.dart';
import '../../shared/relative_time_text.dart';
import '../../shared/user_avatar.dart';

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
  bool _loading = true;
  bool _sending = false;
  List<Comment> _comments = [];

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => _loading = true);
    try {
      final result = await _feedRepo.getComments(widget.postId);
      setState(() => _comments = result.data);
    } catch (_) {
      // Falha silenciosa — exibe lista vazia
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendComment() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    setState(() => _sending = true);
    try {
      await _feedRepo.addComment(widget.postId, content);
      _controller.clear();
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
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
                    : ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: _comments.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final c = _comments[i];
                          final authorName = c.authorName ?? 'Usuário';

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              UserAvatar(
                                  name: authorName,
                                  imageUrl: c.authorAvatarUrl,
                                  radius: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            authorName,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13),
                                          ),
                                          const Spacer(),
                                          RelativeTimeText(
                                              date: c.createdAt, compact: true),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(c.content),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
          ),

          // Campo de texto para novo comentário
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
                        hintText: 'Escreva um comentário...',
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
}
