class Discipline {
  final String id;
  final String code;
  final String name;
  final String? period;
  final String? description;

  Discipline({
    required this.id,
    required this.code,
    required this.name,
    this.period,
    this.description,
  });

  factory Discipline.fromJson(Map<String, dynamic> json) => Discipline(
        id: json['id'] as String,
        code: (json['code'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        period: json['period'] as String?,
        description: json['description'] as String?,
      );
}

class DisciplineGroup {
  final String id;
  final String disciplineId;
  final String institutionId;
  final String name;
  final String? description;
  final String? coverUrl;
  final int memberCount;
  final int postCount;
  final int materialCount;
  final bool isMember;
  final DateTime createdAt;

  DisciplineGroup({
    required this.id,
    required this.disciplineId,
    required this.institutionId,
    required this.name,
    this.description,
    this.coverUrl,
    this.memberCount = 0,
    this.postCount = 0,
    this.materialCount = 0,
    this.isMember = false,
    required this.createdAt,
  });

  factory DisciplineGroup.fromJson(Map<String, dynamic> json) => DisciplineGroup(
        id: json['id'] as String,
        disciplineId: (json['discipline_id'] ?? '').toString(),
        institutionId: (json['institution_id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        description: json['description'] as String?,
        coverUrl: json['cover_url'] as String?,
        memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
        postCount: (json['post_count'] as num?)?.toInt() ?? 0,
        materialCount: (json['material_count'] as num?)?.toInt() ?? 0,
        isMember: json['is_member'] == true,
        createdAt: DateTime.parse(
          json['created_at'] as String? ?? DateTime.now().toIso8601String(),
        ),
      );

  DisciplineGroup copyWith({bool? isMember, int? memberCount}) => DisciplineGroup(
        id: id,
        disciplineId: disciplineId,
        institutionId: institutionId,
        name: name,
        description: description,
        coverUrl: coverUrl,
        memberCount: memberCount ?? this.memberCount,
        postCount: postCount,
        materialCount: materialCount,
        isMember: isMember ?? this.isMember,
        createdAt: createdAt,
      );
}
