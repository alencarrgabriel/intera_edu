class ConnectionSuggestion {
  final String userId;
  final String? handle;
  final String fullName;
  final String? avatarUrl;
  final String? course;
  final String? institutionId;
  final int score;
  final String reason;

  ConnectionSuggestion({
    required this.userId,
    this.handle,
    required this.fullName,
    this.avatarUrl,
    this.course,
    this.institutionId,
    required this.score,
    required this.reason,
  });

  factory ConnectionSuggestion.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>? ?? const {};
    return ConnectionSuggestion(
      userId: (user['id'] ?? '').toString(),
      handle: user['handle'] as String?,
      fullName: (user['full_name'] ?? '').toString(),
      avatarUrl: user['avatar_url'] as String?,
      course: user['course'] as String?,
      institutionId: user['institution_id'] as String?,
      score: (json['score'] as num?)?.toInt() ?? 0,
      reason: (json['reason'] ?? '').toString(),
    );
  }
}
