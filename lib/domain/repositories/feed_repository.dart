abstract class FeedRepository {
  Future<Map<String, dynamic>> getFeed({
    required String scope,
    String? cursor,
    int limit = 20,
  });

  Future<String> createPost({required String content, String scope = 'global'});

  Future<void> deletePost(String postId);

  Future<void> addReaction(String postId, String reactionType);

  Future<void> removeReaction(String postId);

  Future<Map<String, dynamic>> getComments(String postId, {String? cursor});

  Future<void> addComment(String postId, String content, {String? parentCommentId});
}
