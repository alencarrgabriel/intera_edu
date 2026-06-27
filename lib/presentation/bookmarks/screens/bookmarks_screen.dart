import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/design/app_tokens.dart';
import '../../shared/user_avatar.dart';
import '../notifiers/bookmarks_notifier.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookmarksNotifier>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTokens.background,
      appBar: AppBar(
        backgroundColor: AppTokens.background,
        elevation: 0,
        title: const Text('Salvos',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Consumer<BookmarksNotifier>(
        builder: (_, n, __) {
          if (n.loading && n.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (n.items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bookmark_border, size: 56, color: AppTokens.outlineVariant),
                    const SizedBox(height: 12),
                    Text('Nada salvo ainda',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Toque no ícone de marcador num post pra salvá-lo aqui.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTokens.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: n.load,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              itemCount: n.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final b = n.items[i];
                final p = b.post;
                return Card(
                  elevation: 0,
                  color: AppTokens.surfaceContainerLowest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                    side: BorderSide(color: AppTokens.outlineVariant),
                  ),
                  child: ListTile(
                    leading: UserAvatar(
                      name: p.authorName ?? '?',
                      imageUrl: p.authorAvatarUrl,
                      radius: 20,
                    ),
                    title: Text(p.authorName ?? '—',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      p.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.bookmark_remove_outlined),
                      onPressed: () => n.remove(p.id),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
