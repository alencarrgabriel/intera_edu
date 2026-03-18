import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/auth/auth_notifier.dart';
import '../../../data/repositories/feed_repository_impl.dart';
import '../../../domain/repositories/feed_repository.dart';
import '../widgets/post_card.dart';
import '../widgets/comments_sheet.dart';
import 'create_post_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final FeedRepository _feedRepo = FeedRepositoryImpl();
  final ScrollController _scrollController = ScrollController();
  String _scope = 'local';
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  List<Map<String, dynamic>> _posts = [];
  String? _nextCursor;

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        _nextCursor != null) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _posts = [];
      _nextCursor = null;
    });
    await _fetchFeed();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _nextCursor == null) return;
    setState(() => _loadingMore = true);
    await _fetchFeed(cursor: _nextCursor);
    if (mounted) setState(() => _loadingMore = false);
  }

  Future<void> _fetchFeed({String? cursor}) async {
    try {
      final res = await _feedRepo.getFeed(
          scope: _scope, cursor: cursor, limit: 20);
      final data = (res['data'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      setState(() {
        if (cursor == null) {
          _posts = data;
        } else {
          _posts.addAll(data);
        }
        _nextCursor = res['next_cursor'] as String?;
      });
    } catch (e) {
      if (cursor == null) {
        setState(() => _error = e.toString());
      }
    }
  }

  Future<void> _handleReact(String postId) async {
    try {
      await _feedRepo.addReaction(postId, 'like');
    } catch (_) {
      // Falha silenciosa — o PostCard já fez atualização otimista
    }
  }

  void _openComments(Map<String, dynamic> post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CommentsSheet(
        postId: post['id'] as String,
        initialCount: (post['comment_count'] as num?)?.toInt() ?? 0,
      ),
    );
  }

  Future<void> _handleDelete(String postId) async {
    try {
      await _feedRepo.deletePost(postId);
      setState(() => _posts.removeWhere((p) => p['id'] == postId));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _goToCreatePost() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreatePostScreen()),
    );
    if (created == true) _load();
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
          SegmentedButton<String>(
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
            selected: {_scope},
            showSelectedIcon: false,
            onSelectionChanged: (s) {
              setState(() => _scope = s.first);
              _load();
            },
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
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
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 8),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        ElevatedButton(
                            onPressed: _load,
                            child: const Text('Tentar novamente')),
                      ],
                    ),
                  )
                : _posts.isEmpty
                    ? Center(
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
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                          itemCount: _posts.length + (_loadingMore ? 1 : 0),
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (ctx, i) {
                            if (i >= _posts.length) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }
                            final post = _posts[i];
                            return PostCard(
                              post: post,
                              onReact: () =>
                                  _handleReact(post['id'] as String),
                              onComment: () => _openComments(post),
                              onDelete: () =>
                                  _handleDelete(post['id'] as String),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}
