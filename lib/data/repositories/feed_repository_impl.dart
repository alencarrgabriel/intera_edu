import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/feed_repository.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';

class FeedRepositoryImpl implements FeedRepository {
  final ApiClient _api;
  FeedRepositoryImpl({ApiClient? api}) : _api = api ?? ApiClient();

  @override
  Future<PaginatedResult<Post>> getFeed({
    required String scope,
    String? cursor,
    int limit = 20,
  }) async {
    final res = await _api.get(
      ApiEndpoints.posts,
      queryParams: {
        'scope': scope,
        'limit': '$limit',
        if (cursor != null) 'cursor': cursor,
      },
    );
    final data = (res['data'] as List<dynamic>? ?? [])
        .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return PaginatedResult(
      data: data,
      nextCursor: res['next_cursor'] as String?,
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
  Future<PaginatedResult<Comment>> getComments(String postId, {String? cursor}) async {
    final res = await _api.get(
      ApiEndpoints.postComments(postId),
      queryParams: {
        'limit': '20',
        if (cursor != null) 'cursor': cursor,
      },
    );
    final data = (res['data'] as List<dynamic>? ?? [])
        .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return PaginatedResult(
      data: data,
      nextCursor: res['next_cursor'] as String?,
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
