import '../../domain/entities/post.dart';

class CommentModel extends Comment {
  CommentModel({
    required super.id,
    required super.postId,
    required super.authorId,
    required super.content,
    super.parentCommentId,
    required super.createdAt,
    super.authorName,
    super.authorAvatarUrl,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>?;

    return CommentModel(
      id: json['id'] as String,
      postId: (json['post_id'] ?? '').toString(),
      authorId: (json['author_id'] ?? author?['id'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      parentCommentId: json['parent_comment_id'] as String?,
      createdAt: DateTime.parse(
          json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      authorName: (author?['full_name'] ?? json['author_name'])?.toString(),
      authorAvatarUrl:
          (author?['avatar_url'] ?? json['author_avatar_url'])?.toString(),
    );
  }
}
