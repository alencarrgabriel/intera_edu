import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/router/app_router.dart';
import '../../../domain/entities/post.dart';
import '../notifiers/feed_notifier.dart';
import '../widgets/post_card.dart';
import '../widgets/post_card_skeleton.dart';
import '../widgets/comments_sheet.dart';
import '../../shared/error_retry_widget.dart';

/// Tela inicial "Início" no padrão Stitch: top bar com hamburger/marca/bell,
/// segmented control Local/Global no corpo, lista de PostCards e FAB
/// gradiente para criar nova publicação.
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
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTokens.radiusXl)),
      ),
      builder: (_) => CommentsSheet(
        postId: post.id,
        initialCount: post.commentCount,
      ),
    );
  }

  Future<void> _reportPost(String postId) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await sl.apiClient.post('/reports', body: {
        'target_type': 'post',
        'target_id': postId,
        'reason': 'abuse',
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('Denúncia enviada para revisão.')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _goToCreatePost() async {
    final created = await context.push<bool>(AppRoutes.createPost);
    if (created == true) _notifier.onPostCreated();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.background,
      appBar: const _StitchTopBar(),
      floatingActionButton: _GradientFab(onPressed: _goToCreatePost),
      body: Consumer<FeedNotifier>(
        builder: (_, notifier, __) {
          return SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: _ScopeSegmented(
                    scope: notifier.scope,
                    onChanged: notifier.changeScope,
                  ),
                ),
                Expanded(
                  child: _buildList(context, notifier),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildList(BuildContext context, FeedNotifier notifier) {
    if (notifier.loading) {
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => const PostCardSkeleton(),
      );
    }
    if (notifier.error != null) {
      return ErrorRetryWidget(
          message: notifier.error!, onRetry: notifier.load);
    }
    if (notifier.isEmpty) {
      return Center(
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
      );
    }
    return RefreshIndicator(
      onRefresh: notifier.load,
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        itemCount: notifier.posts.length + (notifier.loadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
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
            onReact: (type) => notifier.toggleReaction(post, type: type),
            onComment: () => _openComments(post),
            onDelete: () => notifier.deletePost(post.id),
            onReport: () => _reportPost(post.id),
          );
        },
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────

class _StitchTopBar extends StatelessWidget implements PreferredSizeWidget {
  const _StitchTopBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppTokens.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        onPressed: () {},
        icon: const Icon(Icons.menu_rounded, color: AppTokens.onSurface),
      ),
      title: Text(
        'InteraEdu',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTokens.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: () => context.push(AppRoutes.notifications),
          icon: const Icon(Icons.notifications_outlined,
              color: AppTokens.primary),
          tooltip: 'Notificações',
        ),
      ],
    );
  }
}

// ── Segmented Local / Global ──────────────────────────────────────────────────

class _ScopeSegmented extends StatelessWidget {
  const _ScopeSegmented({required this.scope, required this.onChanged});

  final String scope;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTokens.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTokens.radiusFull),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentTab(
              label: 'Local',
              selected: scope == 'local',
              onTap: () => onChanged('local'),
            ),
          ),
          Expanded(
            child: _SegmentTab(
              label: 'Global',
              selected: scope == 'global',
              onTap: () => onChanged('global'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  const _SegmentTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppTokens.surfaceContainerLowest
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppTokens.radiusFull),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppTokens.onSurface.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? AppTokens.onSurface
                  : AppTokens.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

// ── FAB gradiente "+" ─────────────────────────────────────────────────────────

class _GradientFab extends StatelessWidget {
  const _GradientFab({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppTokens.primaryGradient,
        shape: BoxShape.circle,
        boxShadow: AppTokens.primaryShadow,
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: const Center(
            child: Icon(Icons.add_rounded,
                color: AppTokens.onPrimary, size: 28),
          ),
        ),
      ),
    );
  }
}
