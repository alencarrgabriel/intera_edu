import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../domain/entities/bookmark.dart';

class BookmarksRepository {
  final ApiClient _api;
  BookmarksRepository({ApiClient? api}) : _api = api ?? ApiClient();

  Future<List<BookmarkedPost>> list() async {
    final res = await _api.get(ApiEndpoints.bookmarks);
    return ((res['data'] as List<dynamic>?) ?? const [])
        .map((e) => BookmarkedPost.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> add(String postId) =>
      _api.post(ApiEndpoints.postBookmark(postId)).then((_) {});

  Future<void> remove(String postId) =>
      _api.delete(ApiEndpoints.postBookmark(postId));
}
