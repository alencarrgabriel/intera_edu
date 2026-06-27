import 'package:flutter/foundation.dart';
import '../../../core/di/service_locator.dart';
import '../../../domain/entities/bookmark.dart';

class BookmarksNotifier extends ChangeNotifier {
  List<BookmarkedPost> items = [];
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      items = await sl.bookmarksRepo.list();
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  Future<void> remove(String postId) async {
    items = items.where((b) => b.post.id != postId).toList();
    notifyListeners();
    try {
      await sl.bookmarksRepo.remove(postId);
    } catch (_) {
      await load();
    }
  }
}
