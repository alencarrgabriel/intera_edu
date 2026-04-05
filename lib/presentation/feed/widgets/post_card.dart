import 'package:flutter/material.dart';
import '../../../domain/entities/post.dart';
import '../../shared/relative_time_text.dart';
import '../../shared/user_avatar.dart';

/// Card de uma publicação no feed com suporte a reações e comentários.
class PostCard extends StatefulWidget {
  final Post post;
  final VoidCallback? onReact;
  final VoidCallback? onComment;
  final VoidCallback? onDelete;

  const PostCard({
    super.key,
    required this.post,
    this.onReact,
    this.onComment,
    this.onDelete,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool _reacted;
  late int _reactionCount;

  @override
  void initState() {
    super.initState();
    _reacted = widget.post.userReaction != null;
    _reactionCount = widget.post.reactionCount;
  }

  void _handleReact() {
    // Atualização otimista
    setState(() {
      if (_reacted) {
        _reacted = false;
        _reactionCount = (_reactionCount - 1).clamp(0, 999999);
      } else {
        _reacted = true;
        _reactionCount++;
      }
    });
    widget.onReact?.call();
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final authorName = post.authorName ?? 'Usuário';
    final authorCourse = post.authorCourse;
    final institutionName = post.authorInstitutionName;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho da publicação
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserAvatar(name: authorName, imageUrl: post.authorAvatarUrl, radius: 20),
                const SizedBox(width: 10),
                // Nome e metadados
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (authorCourse != null || institutionName != null)
                        Text(
                          [authorCourse, institutionName]
                              .where((e) => e != null && e.isNotEmpty)
                              .join(' · '),
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                // Tempo + scope
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    RelativeTimeText(date: post.createdAt),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: post.scope == 'local'
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        post.scope == 'local' ? 'Local' : 'Global',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  ],
                ),
                if (widget.onDelete != null)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 18),
                    onSelected: (v) {
                      if (v == 'delete') widget.onDelete?.call();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Excluir', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Conteúdo
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Text(post.content, style: const TextStyle(height: 1.5)),
          ),

          const Divider(height: 1),

          // Barra de ações
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                // Curtir
                TextButton.icon(
                  onPressed: _handleReact,
                  icon: Icon(
                    _reacted ? Icons.thumb_up : Icons.thumb_up_outlined,
                    size: 18,
                    color: _reacted
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  label: Text(
                    _reactionCount > 0 ? '$_reactionCount' : 'Curtir',
                    style: TextStyle(
                      color: _reacted
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Comentar
                TextButton.icon(
                  onPressed: widget.onComment,
                  icon: Icon(
                    Icons.chat_bubble_outline,
                    size: 18,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  label: Text(
                    post.commentCount > 0 ? '${post.commentCount}' : 'Comentar',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
