import 'package:flutter/foundation.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/entities/post.dart';
import '../../../domain/entities/tag.dart';

class TagsNotifier extends ChangeNotifier {
  List<Tag> trending = [];
  List<Tag> followed = [];
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      trending = await sl.tagsRepo.trending();
      followed = await sl.tagsRepo.myFollowed();
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  Future<void> toggleFollow(Tag tag) async {
    final updated = tag.copyWith(
      isFollowed: !tag.isFollowed,
      followerCount: tag.followerCount + (tag.isFollowed ? -1 : 1),
    );
    _replace(updated);
    notifyListeners();
    try {
      if (updated.isFollowed) {
        await sl.tagsRepo.follow(tag.slug);
      } else {
        await sl.tagsRepo.unfollow(tag.slug);
      }
    } catch (_) {
      _replace(tag);
      notifyListeners();
    }
  }

  void _replace(Tag t) {
    trending = trending.map((x) => x.slug == t.slug ? t : x).toList();
    followed = followed.map((x) => x.slug == t.slug ? t : x).toList();
  }
}

class TagDetailNotifier extends ChangeNotifier {
  Tag? tag;
  List<Post> posts = [];
  bool loading = false;
  String? error;

  Future<void> load(String slug) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      tag = await sl.tagsRepo.getBySlug(slug);
      posts = await sl.tagsRepo.postsByTag(slug);
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  Future<void> toggleFollow() async {
    final t = tag;
    if (t == null) return;
    tag = t.copyWith(
      isFollowed: !t.isFollowed,
      followerCount: t.followerCount + (t.isFollowed ? -1 : 1),
    );
    notifyListeners();
    try {
      if (tag!.isFollowed) {
        await sl.tagsRepo.follow(t.slug);
      } else {
        await sl.tagsRepo.unfollow(t.slug);
      }
    } catch (_) {
      tag = t;
      notifyListeners();
    }
  }
}
