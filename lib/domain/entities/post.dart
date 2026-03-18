import 'user.dart';

/// Representa uma publicação no feed acadêmico.
class Post {
  final String id;
  final String authorId;
  final String content;
  final String scope; // 'local' | 'global'
  final List<String> mediaUrls;
  final int reactionCount;
  final int commentCount;
  final String? userReaction; // 'like' | 'insightful' | 'support' | null
  final DateTime createdAt;

  // Dados do autor (enriquecidos pelo profile-service)
  final String? authorName;
  final String? authorAvatarUrl;
  final String? authorCourse;
  final String? authorInstitutionName;

  Post({
    required this.id,
    required this.authorId,
    required this.content,
    this.scope = 'global',
    this.mediaUrls = const [],
    this.reactionCount = 0,
    this.commentCount = 0,
    this.userReaction,
    required this.createdAt,
    this.authorName,
    this.authorAvatarUrl,
    this.authorCourse,
    this.authorInstitutionName,
  });
}

/// Representa um comentário em uma publicação.
class Comment {
  final String id;
  final String postId;
  final String authorId;
  final String content;
  final String? parentCommentId;
  final DateTime createdAt;

  // Dados do autor
  final String? authorName;
  final String? authorAvatarUrl;

  Comment({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.content,
    this.parentCommentId,
    required this.createdAt,
    this.authorName,
    this.authorAvatarUrl,
  });
}
