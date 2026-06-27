class GroupMaterial {
  final String id;
  final String groupId;
  final String uploaderId;
  final String title;
  final String? description;
  final String fileUrl;
  final String? fileMime;
  final int? fileSize;
  final String kind;
  final int downloadCount;
  final double ratingAvg;
  final int ratingCount;
  final DateTime createdAt;

  GroupMaterial({
    required this.id,
    required this.groupId,
    required this.uploaderId,
    required this.title,
    this.description,
    required this.fileUrl,
    this.fileMime,
    this.fileSize,
    this.kind = 'other',
    this.downloadCount = 0,
    this.ratingAvg = 0,
    this.ratingCount = 0,
    required this.createdAt,
  });

  factory GroupMaterial.fromJson(Map<String, dynamic> json) => GroupMaterial(
        id: json['id'] as String,
        groupId: (json['group_id'] ?? '').toString(),
        uploaderId: (json['uploader_id'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        description: json['description'] as String?,
        fileUrl: (json['file_url'] ?? '').toString(),
        fileMime: json['file_mime'] as String?,
        fileSize: (json['file_size'] as num?)?.toInt(),
        kind: (json['kind'] ?? 'other').toString(),
        downloadCount: (json['download_count'] as num?)?.toInt() ?? 0,
        ratingAvg: (json['rating_avg'] as num?)?.toDouble() ?? 0,
        ratingCount: (json['rating_count'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.parse(
          json['created_at'] as String? ?? DateTime.now().toIso8601String(),
        ),
      );
}
