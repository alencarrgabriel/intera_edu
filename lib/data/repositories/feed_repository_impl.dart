import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../domain/repositories/feed_repository.dart';

class FeedRepositoryImpl implements FeedRepository {
  final ApiClient _api;
  FeedRepositoryImpl({ApiClient? api}) : _api = api ?? ApiClient();

  @override
  Future<Map<String, dynamic>> getFeed({required String scope, String? cursor, int limit = 20}) {
    return _api.get(
      ApiEndpoints.posts,
      queryParams: {
        'scope': scope,
        'limit': '$limit',
        if (cursor != null) 'cursor': cursor,
      },
    );
  }

  @override
  Future<String> createPost({required String content, String scope = 'global'}) async {
    final res = await _api.post(ApiEndpoints.posts, body: {'content': content, 'scope': scope});
    return res['id'] as String;
  }
}

