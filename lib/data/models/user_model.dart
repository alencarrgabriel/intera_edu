import '../../domain/entities/user.dart';

class UserModel extends User {
  UserModel({
    required super.id,
    required super.email,
    required super.fullName,
    super.bio,
    super.course,
    super.period,
    super.privacyLevel,
    super.avatarUrl,
    required super.institution,
    super.skills,
    required super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      bio: json['bio'] as String?,
      course: json['course'] as String?,
      period: json['period'] as int?,
      privacyLevel: json['privacy_level'] as String? ?? 'local_only',
      avatarUrl: json['avatar_url'] as String?,
      institution: Institution(
        id: json['institution']['id'] as String,
        name: json['institution']['name'] as String,
        slug: json['institution']['slug'] as String?,
      ),
      skills: (json['skills'] as List<dynamic>?)
          ?.map((s) => Skill(
                id: s['id'] as String,
                name: s['name'] as String,
                category: s['category'] as String? ?? '',
              ))
          .toList() ?? [],
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'bio': bio,
      'course': course,
      'period': period,
      'privacy_level': privacyLevel,
    };
  }
}
