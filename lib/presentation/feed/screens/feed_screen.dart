import 'package:flutter/material.dart';
import '../../../data/repositories/feed_repository_impl.dart';
import '../../../domain/repositories/feed_repository.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final FeedRepository _feedRepo = FeedRepositoryImpl();
  String _scope = 'local';
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _posts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await _feedRepo.getFeed(scope: _scope, limit: 20);
      final data = (res['data'] as List<dynamic>? ?? []);
      setState(() {
        _posts = data.cast<Map<String, dynamic>>();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createPost() async {
    final controller = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New post'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(hintText: 'What are you working on?'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Post'),
          ),
        ],
      ),
    );

    if (created != true) return;
    final content = controller.text.trim();
    if (content.isEmpty) return;

    try {
      await _feedRepo.createPost(content: content, scope: 'global');
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feed'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'local', label: Text('Local')),
                ButtonSegment(value: 'global', label: Text('Global')),
              ],
              selected: {_scope},
              onSelectionChanged: (s) {
                setState(() => _scope = s.first);
                _load();
              },
            ),
          ),
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createPost,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _posts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (ctx, i) {
                        final p = _posts[i];
                        final content = (p['content'] ?? '').toString();
                        final createdAt = (p['created_at'] ?? '').toString();
                        final scope = (p['scope'] ?? '').toString();
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(scope.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
                                    const Spacer(),
                                    Text(createdAt, style: Theme.of(context).textTheme.labelSmall),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(content),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}

