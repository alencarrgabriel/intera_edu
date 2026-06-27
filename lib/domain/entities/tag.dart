class Tag {
  final String id;
  final String slug;
  final String name;
  final int postCount;
  final int followerCount;
  final bool isFollowed;

  Tag({
    required this.id,
    required this.slug,
    required this.name,
    this.postCount = 0,
    this.followerCount = 0,
    this.isFollowed = false,
  });

  factory Tag.fromJson(Map<String, dynamic> json) => Tag(
        id: (json['id'] ?? '').toString(),
        slug: (json['slug'] ?? '').toString(),
        name: (json['name'] ?? json['slug'] ?? '').toString(),
        postCount: (json['post_count'] as num?)?.toInt() ?? 0,
        followerCount: (json['follower_count'] as num?)?.toInt() ?? 0,
        isFollowed: json['is_followed'] == true,
      );

  Tag copyWith({bool? isFollowed, int? followerCount}) => Tag(
        id: id,
        slug: slug,
        name: name,
        postCount: postCount,
        followerCount: followerCount ?? this.followerCount,
        isFollowed: isFollowed ?? this.isFollowed,
      );
}
