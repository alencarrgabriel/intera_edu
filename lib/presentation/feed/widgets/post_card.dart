import 'package:flutter/material.dart';

/// Card de uma publicação no feed com suporte a reações e comentários.
class PostCard extends StatefulWidget {
  final Map<String, dynamic> post;
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
    _reacted = widget.post['user_reaction'] != null;
    _reactionCount = (widget.post['reaction_count'] as num?)?.toInt() ?? 0;
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

  String _formatDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'agora mesmo';
      if (diff.inMinutes < 60) return 'há ${diff.inMinutes} min';
      if (diff.inHours < 24) return 'há ${diff.inHours} h';
      if (diff.inDays < 7) return 'há ${diff.inDays} d';
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = (widget.post['content'] ?? '').toString();
    final scope = (widget.post['scope'] ?? 'global').toString();
    final createdAt = widget.post['created_at']?.toString();
    final commentCount = (widget.post['comment_count'] as num?)?.toInt() ?? 0;

    // Dados do autor (podem vir aninhados como 'author' ou flat)
    final author = widget.post['author'] as Map<String, dynamic>?;
    final authorName = (author?['full_name'] ?? widget.post['author_name'] ?? 'Usuário').toString();
    final authorCourse = (author?['course'] ?? widget.post['author_course'])?.toString();
    final institutionName = (author?['institution']?['name'] ?? widget.post['institution_name'])?.toString();

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
                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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
                    Text(
                      _formatDate(createdAt),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: scope == 'local'
                            ? Theme.of(context).colorScheme.primaryContainer
                            : Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        scope == 'local' ? 'Local' : 'Global',
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
            child: Text(content, style: const TextStyle(height: 1.5)),
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
                    commentCount > 0 ? '$commentCount' : 'Comentar',
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
