import '../../domain/entities/post.dart';

class PostModel extends Post {
  PostModel({
    required super.id,
    required super.authorId,
    required super.content,
    super.scope,
    super.mediaUrls,
    super.reactionCount,
    super.commentCount,
    super.userReaction,
    required super.createdAt,
    super.authorName,
    super.authorAvatarUrl,
    super.authorCourse,
    super.authorInstitutionName,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>?;

    return PostModel(
      id: json['id'] as String,
      authorId: (json['author_id'] ?? author?['id'] ?? '').toString(),
      content: (json['content'] ?? '').toString(),
      scope: (json['scope'] ?? 'global').toString(),
      mediaUrls: (json['media_urls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      reactionCount: (json['reaction_count'] as num?)?.toInt() ?? 0,
      commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
      userReaction: json['user_reaction'] as String?,
      createdAt: DateTime.parse(
          json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      authorName: (author?['full_name'] ?? json['author_name'])?.toString(),
      authorAvatarUrl:
          (author?['avatar_url'] ?? json['author_avatar_url'])?.toString(),
      authorCourse: (author?['course'] ?? json['author_course'])?.toString(),
      authorInstitutionName: (author?['institution']?['name'] ??
              json['institution_name'])
          ?.toString(),
    );
  }

  PostModel copyWith({
    bool? reacted,
    int? reactionCount,
    int? commentCount,
  }) {
    return PostModel(
      id: id,
      authorId: authorId,
      content: content,
      scope: scope,
      mediaUrls: mediaUrls,
      reactionCount: reactionCount ?? this.reactionCount,
      commentCount: commentCount ?? this.commentCount,
      userReaction: reacted != null
          ? (reacted ? (userReaction ?? 'like') : null)
          : userReaction,
      createdAt: createdAt,
      authorName: authorName,
      authorAvatarUrl: authorAvatarUrl,
      authorCourse: authorCourse,
      authorInstitutionName: authorInstitutionName,
    );
  }
}
