import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_notifier.dart';
import '../../../core/router/app_router.dart';
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
      appBar: AppBar(
        title: const Text('InteraEdu'),
        actions: [
          Consumer<FeedNotifier>(
            builder: (_, n, __) => SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'local',
                  icon: Icon(Icons.location_on, size: 18),
                  label: Text('Local'),
                ),
                ButtonSegment(
                  value: 'global',
                  icon: Icon(Icons.public, size: 18),
                  label: null,
                ),
              ],
              selected: {n.scope},
              showSelectedIcon: false,
              onSelectionChanged: (s) => n.changeScope(s.first),
            ),
          ),
          const SizedBox(width: 4),
          Consumer<FeedNotifier>(
            builder: (_, n, __) => IconButton(
              onPressed: n.loading ? null : n.load,
              icon: const Icon(Icons.refresh),
              tooltip: 'Atualizar',
            ),
          ),
          IconButton(
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToCreatePost,
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Publicar'),
      ),
      body: SafeArea(
        child: Consumer<FeedNotifier>(
          builder: (_, notifier, __) {
            if (notifier.loading) {
              return const Center(child: CircularProgressIndicator());
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
                        size: 64,
                        color: Theme.of(context).colorScheme.outline),
                    const SizedBox(height: 16),
                    const Text('Nenhuma publicação ainda.',
                        style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    const Text('Seja o primeiro a compartilhar algo!'),
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
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                itemCount:
                    notifier.posts.length + (notifier.loadingMore ? 1 : 0),
                separatorBuilder: (_, __) => const SizedBox(height: 8),
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
      ),
    );
  }
}
