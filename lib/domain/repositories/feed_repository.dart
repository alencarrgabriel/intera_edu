abstract class FeedRepository {
  Future<Map<String, dynamic>> getFeed({required String scope, String? cursor, int limit = 20});
  Future<String> createPost({required String content, String scope = 'global'});
}

