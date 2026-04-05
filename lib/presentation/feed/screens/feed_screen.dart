import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_notifier.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/post.dart';
import '../notifiers/feed_notifier.dart';
import '../widgets/post_card.dart';
import '../widgets/comments_sheet.dart';
import '../../shared/error_retry_widget.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late final FeedNotifier _notifier;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _notifier = context.read<FeedNotifier>();
    _scrollController.addListener(_onScroll);
    // Adiar o load para o primeiro frame evitar setState-during-build.
    if (_notifier.posts.isEmpty && !_notifier.loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _notifier.load());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_notifier.loadingMore) {
      _notifier.loadMore();
    }
  }

  void _openComments(Post post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTokens.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTokens.radiusXl)),
      ),
      builder: (_) => CommentsSheet(
        postId: post.id,
        initialCount: post.commentCount,
      ),
    );
  }

  Future<void> _goToCreatePost() async {
    final created = await context.push<bool>(AppRoutes.createPost);
    if (created == true) _notifier.onPostCreated();
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair'),
        content: const Text('Deseja encerrar sua sessão?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await context.read<AuthNotifier>().logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppTheme.glassAppBar(
        context: context,
        title: Text(
          'InteraEdu',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppTokens.primary,
                fontWeight: FontWeight.w800,
              ),
        ),
        actions: [
          Consumer<FeedNotifier>(
            builder: (_, n, __) => _ScopeToggle(
              scope: n.scope,
              onChanged: n.changeScope,
            ),
          ),
          const SizedBox(width: 4),
          Consumer<FeedNotifier>(
            builder: (_, n, __) => IconButton(
              onPressed: n.loading ? null : n.load,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Atualizar',
            ),
          ),
          IconButton(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sair',
          ),
        ],
      ),
      floatingActionButton: _GradientFab(onPressed: _goToCreatePost),
      body: Consumer<FeedNotifier>(
        builder: (_, notifier, __) {
          if (notifier.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (notifier.error != null) {
            return SafeArea(
              child: ErrorRetryWidget(
                  message: notifier.error!, onRetry: notifier.load),
            );
          }
          if (notifier.isEmpty) {
            return SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.article_outlined,
                        size: 64, color: AppTokens.outline),
                    const SizedBox(height: 16),
                    Text('Nenhuma publicação ainda.',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Seja o primeiro a compartilhar algo!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTokens.onSurfaceVariant)),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _goToCreatePost,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Criar publicação'),
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: notifier.load,
            child: ListView.separated(
              controller: _scrollController,
              padding: EdgeInsets.fromLTRB(
                  12, kToolbarHeight + 20, 12, 100),
              itemCount:
                  notifier.posts.length + (notifier.loadingMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                if (i >= notifier.posts.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final post = notifier.posts[i];
                return PostCard(
                  post: post,
                  onReact: () => notifier.toggleReaction(post),
                  onComment: () => _openComments(post),
                  onDelete: () => notifier.deletePost(post.id),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ── Scope toggle Stitch ────────────────────────────────────────────────────────
class _ScopeToggle extends StatelessWidget {
  const _ScopeToggle({required this.scope, required this.onChanged});
  final String scope;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: AppTokens.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTokens.radiusLg),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Tab(
              label: 'Local',
              icon: Icons.location_on_rounded,
              selected: scope == 'local',
              onTap: () => onChanged('local')),
          _Tab(
              label: 'Global',
              icon: Icons.public_rounded,
              selected: scope == 'global',
              onTap: () => onChanged('global')),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? AppTokens.surfaceContainerLowest
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          boxShadow: selected
              ? [BoxShadow(
                  color: AppTokens.onSurface.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                )]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: selected
                    ? AppTokens.primary
                    : AppTokens.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
                color: selected
                    ? AppTokens.primary
                    : AppTokens.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── FAB com gradiente ─────────────────────────────────────────────────────────
class _GradientFab extends StatelessWidget {
  const _GradientFab({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppTokens.primaryGradient,
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
        boxShadow: AppTokens.primaryShadow,
      ),
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.edit_outlined, color: AppTokens.onPrimary),
        label: const Text('Publicar',
            style: TextStyle(
                color: AppTokens.onPrimary, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
