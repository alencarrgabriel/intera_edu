import 'post.dart';

class BookmarkedPost {
  final String bookmarkId;
  final DateTime bookmarkedAt;
  final Post post;

  BookmarkedPost({
    required this.bookmarkId,
    required this.bookmarkedAt,
    required this.post,
  });

  factory BookmarkedPost.fromJson(Map<String, dynamic> json) {
    final p = json['post'] as Map<String, dynamic>? ?? const {};
    final author = p['author'] as Map<String, dynamic>? ?? const {};
    return BookmarkedPost(
      bookmarkId: json['bookmark_id'] as String? ?? '',
      bookmarkedAt: DateTime.parse(
        json['bookmarked_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      post: Post(
        id: (p['id'] ?? '').toString(),
        authorId: (author['id'] ?? '').toString(),
        content: (p['content'] ?? '').toString(),
        mediaUrls: ((p['media_urls'] as List<dynamic>?) ?? const [])
            .map((e) => e.toString())
            .toList(),
        createdAt: DateTime.parse(p['created_at'] as String? ??
            DateTime.now().toIso8601String()),
        authorName: author['full_name'] as String?,
        authorAvatarUrl: author['avatar_url'] as String?,
        authorCourse: author['course'] as String?,
        isBookmarked: true,
      ),
    );
  }
}
