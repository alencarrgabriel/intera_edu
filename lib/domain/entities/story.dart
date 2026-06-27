class StoryItem {
  final String id;
  final String mediaUrl;
  final String? mediaMime;
  final String? caption;
  final int viewCount;
  final bool viewed;
  final DateTime createdAt;
  final DateTime expiresAt;

  StoryItem({
    required this.id,
    required this.mediaUrl,
    this.mediaMime,
    this.caption,
    this.viewCount = 0,
    this.viewed = false,
    required this.createdAt,
    required this.expiresAt,
  });

  factory StoryItem.fromJson(Map<String, dynamic> json) => StoryItem(
        id: json['id'] as String,
        mediaUrl: (json['media_url'] ?? '').toString(),
        mediaMime: json['media_mime'] as String?,
        caption: json['caption'] as String?,
        viewCount: (json['view_count'] as num?)?.toInt() ?? 0,
        viewed: json['viewed'] == true,
        createdAt: DateTime.parse(json['created_at'] as String),
        expiresAt: DateTime.parse(json['expires_at'] as String),
      );

  StoryItem copyWith({bool? viewed}) => StoryItem(
        id: id,
        mediaUrl: mediaUrl,
        mediaMime: mediaMime,
        caption: caption,
        viewCount: viewCount,
        viewed: viewed ?? this.viewed,
        createdAt: createdAt,
        expiresAt: expiresAt,
      );
}

class StoryGroup {
  final String authorId;
  final String? authorName;
  final String? authorAvatarUrl;
  final bool allViewed;
  final List<StoryItem> stories;

  StoryGroup({
    required this.authorId,
    this.authorName,
    this.authorAvatarUrl,
    required this.allViewed,
    required this.stories,
  });

  factory StoryGroup.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>? ?? const {};
    return StoryGroup(
      authorId: (author['id'] ?? '').toString(),
      authorName: author['full_name'] as String?,
      authorAvatarUrl: author['avatar_url'] as String?,
      allViewed: json['all_viewed'] == true,
      stories: ((json['stories'] as List<dynamic>?) ?? const [])
          .map((e) => StoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
