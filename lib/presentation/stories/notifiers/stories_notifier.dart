import 'package:flutter/foundation.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/entities/story.dart';

class StoriesNotifier extends ChangeNotifier {
  List<StoryGroup> groups = [];
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      groups = await sl.storiesRepo.listActive();
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  Future<void> markViewed(String storyId) async {
    try {
      await sl.storiesRepo.markViewed(storyId);
      for (int gi = 0; gi < groups.length; gi++) {
        final g = groups[gi];
        final si = g.stories.indexWhere((s) => s.id == storyId);
        if (si < 0) continue;
        final updated = List<StoryItem>.of(g.stories);
        updated[si] = g.stories[si].copyWith(viewed: true);
        final allViewed = updated.every((s) => s.viewed);
        groups[gi] = StoryGroup(
          authorId: g.authorId,
          authorName: g.authorName,
          authorAvatarUrl: g.authorAvatarUrl,
          allViewed: allViewed,
          stories: updated,
        );
        notifyListeners();
        return;
      }
    } catch (_) {}
  }
}
