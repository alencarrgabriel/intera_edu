import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../domain/repositories/feed_repository.dart';

class FeedRepositoryImpl implements FeedRepository {
  final ApiClient _api;
  FeedRepositoryImpl({ApiClient? api}) : _api = api ?? ApiClient();

  @override
  Future<Map<String, dynamic>> getFeed({
    required String scope,
    String? cursor,
    int limit = 20,
  }) {
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
    final res = await _api.post(ApiEndpoints.posts, body: {
      'content': content,
      'scope': scope,
    });
    return res['id'] as String;
  }

  @override
  Future<void> deletePost(String postId) async {
    await _api.delete(ApiEndpoints.post(postId));
  }

  @override
  Future<void> addReaction(String postId, String reactionType) async {
    await _api.post(ApiEndpoints.postReactions(postId), body: {'type': reactionType});
  }

  @override
  Future<void> removeReaction(String postId) async {
    await _api.delete(ApiEndpoints.postReactions(postId));
  }

  @override
  Future<Map<String, dynamic>> getComments(String postId, {String? cursor}) {
    return _api.get(
      ApiEndpoints.postComments(postId),
      queryParams: {
        'limit': '20',
        if (cursor != null) 'cursor': cursor,
      },
    );
  }

  @override
  Future<void> addComment(String postId, String content, {String? parentCommentId}) async {
    await _api.post(ApiEndpoints.postComments(postId), body: {
      'content': content,
      if (parentCommentId != null) 'parent_comment_id': parentCommentId,
    });
  }
}
