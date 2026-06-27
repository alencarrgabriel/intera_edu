import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/design/app_tokens.dart';
import '../../../core/router/app_router.dart';
import '../notifiers/stories_notifier.dart';

class StoriesRing extends StatelessWidget {
  const StoriesRing({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StoriesNotifier>(
      builder: (_, n, __) {
        return SizedBox(
          height: 96,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _addButton(context),
              ...n.groups.asMap().entries.map(
                    (e) => _ring(context, e.key, n),
                  ),
            ],
          ),
        );
      },
    );
  }

  Widget _addButton(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.createStory),
      child: Container(
        width: 72,
        margin: const EdgeInsets.only(right: 10),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTokens.surfaceContainerLow,
                border: Border.all(color: AppTokens.outlineVariant, width: 2),
              ),
              child: Icon(Icons.add, color: AppTokens.primary, size: 28),
            ),
            const SizedBox(height: 6),
            Text(
              'Seu story',
              style: TextStyle(
                fontSize: 11,
                color: AppTokens.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _ring(BuildContext context, int idx, StoriesNotifier n) {
    final g = n.groups[idx];
    return GestureDetector(
      onTap: () => context.push(
        AppRoutes.storyViewer(idx),
        extra: {'groups': n.groups, 'initialIndex': idx},
      ),
      child: Container(
        width: 72,
        margin: const EdgeInsets.only(right: 10),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: g.allViewed
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFFEC4899)],
                      ),
                border: g.allViewed
                    ? Border.all(color: AppTokens.outlineVariant, width: 1.5)
                    : null,
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: AppTokens.primaryContainer,
                backgroundImage: g.authorAvatarUrl != null
                    ? NetworkImage(g.authorAvatarUrl!)
                    : null,
                child: g.authorAvatarUrl == null
                    ? Text(
                        (g.authorName ?? '?').substring(0, 1).toUpperCase(),
                        style: TextStyle(
                            color: AppTokens.onPrimaryContainer,
                            fontWeight: FontWeight.w700),
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              g.authorName ?? '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
