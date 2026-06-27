import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/design/app_tokens.dart';
import '../notifiers/tags_notifier.dart';
import '../../feed/widgets/post_card.dart';

class TagDetailScreen extends StatefulWidget {
  final String slug;
  const TagDetailScreen({super.key, required this.slug});

  @override
  State<TagDetailScreen> createState() => _TagDetailScreenState();
}

class _TagDetailScreenState extends State<TagDetailScreen> {
  final TagDetailNotifier _notifier = TagDetailNotifier();

  @override
  void initState() {
    super.initState();
    _notifier.load(widget.slug);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _notifier,
      child: Scaffold(
        backgroundColor: AppTokens.background,
        appBar: AppBar(
          backgroundColor: AppTokens.background,
          elevation: 0,
          title: Text('#${widget.slug}',
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
        body: Consumer<TagDetailNotifier>(
          builder: (_, n, __) {
            if (n.loading) return const Center(child: CircularProgressIndicator());
            return RefreshIndicator(
              onRefresh: () => n.load(widget.slug),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  if (n.tag != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTokens.surfaceContainerLow,
                        borderRadius:
                            BorderRadius.circular(AppTokens.radiusMd),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${n.tag!.postCount} posts',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${n.tag!.followerCount} seguidores',
                                  style: TextStyle(
                                      color: AppTokens.onSurfaceVariant,
                                      fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          FilledButton(
                            onPressed: n.toggleFollow,
                            style: FilledButton.styleFrom(
                              backgroundColor: n.tag!.isFollowed
                                  ? AppTokens.surfaceContainerLowest
                                  : AppTokens.primary,
                              foregroundColor: n.tag!.isFollowed
                                  ? AppTokens.onSurface
                                  : Colors.white,
                              side: n.tag!.isFollowed
                                  ? BorderSide(color: AppTokens.outlineVariant)
                                  : BorderSide.none,
                            ),
                            child: Text(
                              n.tag!.isFollowed ? 'Seguindo' : 'Seguir',
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (n.posts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'Nenhum post com essa tag ainda.',
                          style: TextStyle(color: AppTokens.onSurfaceVariant),
                        ),
                      ),
                    )
                  else
                    ...n.posts.map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: PostCard(
                            post: p,
                            onReact: (_) {},
                            onComment: () {},
                            onDelete: () {},
                            onReport: () {},
                          ),
                        )),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
