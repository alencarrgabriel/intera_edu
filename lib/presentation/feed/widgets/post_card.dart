import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/widgets/stitch_card.dart';
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

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  late bool _reacted;
  late int _reactionCount;
  late final AnimationController _likeController;
  late final Animation<double> _likeScale;

  @override
  void initState() {
    super.initState();
    _reacted = widget.post.userReaction != null;
    _reactionCount = widget.post.reactionCount;

    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _likeScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _likeController, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post != widget.post) {
      _reacted = widget.post.userReaction != null;
      _reactionCount = widget.post.reactionCount;
    }
  }

  @override
  void dispose() {
    _likeController.dispose();
    super.dispose();
  }

  void _handleReact() {
    setState(() {
      if (_reacted) {
        _reacted = false;
        _reactionCount = (_reactionCount - 1).clamp(0, 999999);
      } else {
        _reacted = true;
        _reactionCount++;
        _likeController.forward(from: 0); // animação apenas ao curtir
        HapticFeedback.lightImpact();
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

    return StitchCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Cabeçalho ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserAvatar(
                    name: authorName,
                    imageUrl: post.authorAvatarUrl,
                    radius: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorName,
                        style: Theme.of(context).textTheme.titleSmall,
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
                // Tempo + scope badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    RelativeTimeText(date: post.createdAt),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: post.scope == 'local'
                            ? AppTokens.primaryContainer
                            : AppTokens.surfaceContainerHigh,
                        borderRadius:
                            BorderRadius.circular(AppTokens.radiusFull),
                      ),
                      child: Text(
                        post.scope == 'local' ? 'Local' : 'Global',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: post.scope == 'local'
                                  ? AppTokens.onPrimaryContainer
                                  : AppTokens.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ],
                ),
                if (widget.onDelete != null)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert,
                        size: 18, color: AppTokens.onSurfaceVariant),
                    onSelected: (v) {
                      if (v == 'delete') widget.onDelete?.call();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete_outline,
                              size: 18, color: AppTokens.error),
                          SizedBox(width: 8),
                          Text('Excluir',
                              style: TextStyle(color: AppTokens.error)),
                        ]),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // ── Conteúdo ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: Text(
              post.content,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(height: 1.6),
            ),
          ),

          // ── Separador via color-shift ───────────────────────────────────
          Container(
            height: 1,
            color: AppTokens.surfaceContainerLow,
          ),

          // ── Ações ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: _handleReact,
                  icon: ScaleTransition(
                    scale: _likeScale,
                    child: Icon(
                      _reacted
                          ? Icons.thumb_up_rounded
                          : Icons.thumb_up_outlined,
                      size: 18,
                      color: _reacted
                          ? AppTokens.primary
                          : AppTokens.onSurfaceVariant,
                    ),
                  ),
                  label: Text(
                    _reactionCount > 0 ? '$_reactionCount' : 'Curtir',
                    style: TextStyle(
                      color: _reacted
                          ? AppTokens.primary
                          : AppTokens.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: widget.onComment,
                  icon: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 18,
                    color: AppTokens.onSurfaceVariant,
                  ),
                  label: Text(
                    post.commentCount > 0
                        ? '${post.commentCount}'
                        : 'Comentar',
                    style: const TextStyle(
                      color: AppTokens.onSurfaceVariant,
                      fontSize: 13,
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
