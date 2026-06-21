import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/design/app_tokens.dart';
import '../../../domain/entities/post.dart';
import '../../shared/user_avatar.dart';

/// Card de publicação no estilo do protótipo Stitch.
///
/// Header com avatar + nome + curso/instituição + menu de ações,
/// conteúdo, e linha inferior com botões "Curtir" (RF-21: tap=curtir,
/// long-press=seletor de Perspicaz/Apoio), "Comentar" e "Salvar".
class PostCard extends StatefulWidget {
  final Post post;
  // RF-21 — onReact recebe o tipo de reação escolhido (like|insightful|support).
  final void Function(String type)? onReact;
  final VoidCallback? onComment;
  final VoidCallback? onDelete;
  final VoidCallback? onReport;

  const PostCard({
    super.key,
    required this.post,
    this.onReact,
    this.onComment,
    this.onDelete,
    this.onReport,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard>
    with SingleTickerProviderStateMixin {
  String? _reactionType; // null | 'like' | 'insightful' | 'support'
  late int _reactionCount;
  bool _saved = false;
  late final AnimationController _likeController;
  late final Animation<double> _likeScale;

  @override
  void initState() {
    super.initState();
    _reactionType = widget.post.userReaction;
    _reactionCount = widget.post.reactionCount;
    _likeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _likeScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.9), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _likeController, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(PostCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.post != widget.post) {
      _reactionType = widget.post.userReaction;
      _reactionCount = widget.post.reactionCount;
    }
  }

  @override
  void dispose() {
    _likeController.dispose();
    super.dispose();
  }

  void _applyReaction(String type) {
    setState(() {
      if (_reactionType == type) {
        _reactionType = null;
        _reactionCount = (_reactionCount - 1).clamp(0, 999999);
      } else {
        final wasReacted = _reactionType != null;
        _reactionType = type;
        if (!wasReacted) _reactionCount++;
        _likeController.forward(from: 0);
        HapticFeedback.lightImpact();
      }
    });
    widget.onReact?.call(type);
  }

  void _handleReact() => _applyReaction('like');

  Future<void> _openReactionPicker() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppTokens.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTokens.radiusXl)),
      ),
      builder: (ctx) => _ReactionPicker(active: _reactionType),
    );
    if (picked != null && mounted) {
      _applyReaction(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final authorName = post.authorName ?? 'Usuário';
    final authorCourse = post.authorCourse;
    final institutionName = post.authorInstitutionName;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      decoration: BoxDecoration(
        color: AppTokens.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
        border: Border.all(
          color: AppTokens.outlineVariant.withValues(alpha: 0.18),
        ),
        boxShadow: AppTokens.ambientShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserAvatar(
                name: authorName,
                imageUrl: post.authorAvatarUrl,
                radius: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [authorCourse, institutionName]
                          .where((e) => e != null && e.isNotEmpty)
                          .join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppTokens.primary,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert,
                    size: 20, color: AppTokens.onSurfaceVariant),
                padding: EdgeInsets.zero,
                onSelected: (v) {
                  if (v == 'delete') widget.onDelete?.call();
                  if (v == 'report') widget.onReport?.call();
                },
                itemBuilder: (_) => [
                  if (widget.onDelete != null)
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
                  if (widget.onReport != null)
                    const PopupMenuItem(
                      value: 'report',
                      child: Row(children: [
                        Icon(Icons.flag_outlined,
                            size: 18, color: AppTokens.error),
                        SizedBox(width: 8),
                        Text('Denunciar'),
                      ]),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Conteúdo ────────────────────────────────────────────────────
          Text(
            post.content,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(height: 1.5, color: AppTokens.onSurface),
          ),
          const SizedBox(height: 14),

          // ── Ações: Curtir + Comentar (CTA) + Salvar ────────────────────
          Row(
            children: [
              _ReactButton(
                reactionType: _reactionType,
                count: _reactionCount,
                scale: _likeScale,
                onTap: _handleReact,
                onLongPress: _openReactionPicker,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CommentCta(
                  count: post.commentCount,
                  onTap: widget.onComment,
                ),
              ),
              const SizedBox(width: 8),
              _SaveButton(
                saved: _saved,
                onTap: () => setState(() => _saved = !_saved),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Mapeia tipo de reação para ícone/label exibidos no botão e no picker.
class _ReactionMeta {
  final IconData icon;
  final String label;
  const _ReactionMeta(this.icon, this.label);
}

const _reactionMetas = {
  'like': _ReactionMeta(Icons.thumb_up_rounded, 'Curtir'),
  'insightful': _ReactionMeta(Icons.lightbulb_rounded, 'Perspicaz'),
  'support': _ReactionMeta(Icons.favorite_rounded, 'Apoio'),
};

class _ReactButton extends StatelessWidget {
  const _ReactButton({
    required this.reactionType,
    required this.count,
    required this.scale,
    required this.onTap,
    required this.onLongPress,
  });

  final String? reactionType;
  final int count;
  final Animation<double> scale;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final reacted = reactionType != null;
    final meta = reacted
        ? _reactionMetas[reactionType] ?? _reactionMetas['like']!
        : const _ReactionMeta(Icons.thumb_up_outlined, 'Curtir');

    return SizedBox(
      height: 42,
      child: Material(
        color: reacted
            ? AppTokens.primaryContainer.withValues(alpha: 0.6)
            : AppTokens.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: scale,
                  child: Icon(
                    meta.icon,
                    color: reacted
                        ? AppTokens.primary
                        : AppTokens.onSurfaceVariant,
                    size: 18,
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 6),
                  Text(
                    '$count',
                    style: TextStyle(
                      color: reacted
                          ? AppTokens.primary
                          : AppTokens.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CommentCta extends StatelessWidget {
  const _CommentCta({required this.count, required this.onTap});
  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppTokens.primaryGradient,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          boxShadow: AppTokens.primaryShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: AppTokens.onPrimary,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    count > 0 ? 'Comentar · $count' : 'Comentar',
                    style: const TextStyle(
                      color: AppTokens.onPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.saved, required this.onTap});
  final bool saved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(
          saved
              ? Icons.bookmark_rounded
              : Icons.bookmark_outline_rounded,
          color: saved ? AppTokens.primary : AppTokens.onSurfaceVariant,
          size: 18,
        ),
        label: Text(
          saved ? 'Salvo' : 'Salvar',
          style: TextStyle(
            color: saved ? AppTokens.primary : AppTokens.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
        ),
      ),
    );
  }
}

/// RF-21 — Bottom sheet com as três reações disponíveis.
class _ReactionPicker extends StatelessWidget {
  const _ReactionPicker({this.active});
  final String? active;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 18),
              alignment: Alignment.center,
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTokens.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Reagir com',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
            const SizedBox(height: 12),
            ..._reactionMetas.entries.map((e) {
              final isActive = active == e.key;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pop(context, e.key),
                  borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isActive
                                ? AppTokens.primaryContainer
                                : AppTokens.surfaceContainerLow,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(e.value.icon,
                              size: 20,
                              color: isActive
                                  ? AppTokens.primary
                                  : AppTokens.onSurfaceVariant),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            e.value.label,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: AppTokens.onSurface,
                            ),
                          ),
                        ),
                        if (isActive)
                          const Icon(Icons.check_rounded,
                              color: AppTokens.primary),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
