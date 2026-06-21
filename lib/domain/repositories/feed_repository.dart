import '../entities/post.dart';

class PaginatedResult<T> {
  final List<T> data;
  final String? nextCursor;

  PaginatedResult({required this.data, this.nextCursor});
}

abstract class FeedRepository {
  Future<PaginatedResult<Post>> getFeed({
    required String scope,
    String? cursor,
    int limit = 20,
  });

  /// RF-16 — Cria post com texto e (opcionalmente) um arquivo (PDF/img ≤10MB).
  Future<String> createPost({
    required String content,
    String scope = 'global',
    List<int>? fileBytes,
    String? filename,
    String? mimeType,
  });

  Future<void> deletePost(String postId);

  Future<void> addReaction(String postId, String reactionType);

  Future<void> removeReaction(String postId);

  Future<PaginatedResult<Comment>> getComments(String postId, {String? cursor});

  Future<void> addComment(String postId, String content, {String? parentCommentId});
}
