import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/tag.dart';
import '../models/post_model.dart';

class TagsRepository {
  final ApiClient _api;
  TagsRepository({ApiClient? api}) : _api = api ?? ApiClient();

  Future<List<Tag>> search({String? q}) async {
    final res = await _api.get(
      ApiEndpoints.tags,
      queryParams: {if (q != null && q.isNotEmpty) 'q': q},
    );
    return ((res['data'] as List<dynamic>?) ?? const [])
        .map((e) => Tag.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Tag>> trending() async {
    final res = await _api.get(ApiEndpoints.trendingTags);
    return ((res['data'] as List<dynamic>?) ?? const [])
        .map((e) => Tag.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Tag>> myFollowed() async {
    final res = await _api.get(ApiEndpoints.myTags);
    return ((res['data'] as List<dynamic>?) ?? const [])
        .map((e) => Tag.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Tag> getBySlug(String slug) async {
    final res = await _api.get(ApiEndpoints.tag(slug));
    return Tag.fromJson(res);
  }

  Future<List<Post>> postsByTag(String slug) async {
    final res = await _api.get(ApiEndpoints.tagPosts(slug));
    return ((res['data'] as List<dynamic>?) ?? const [])
        .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> follow(String slug) =>
      _api.post(ApiEndpoints.tagFollow(slug)).then((_) {});

  Future<void> unfollow(String slug) =>
      _api.delete(ApiEndpoints.tagFollow(slug));
}
