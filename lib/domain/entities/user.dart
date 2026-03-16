class User {
  final String id;
  final String email;
  final String fullName;
  final String? bio;
  final String? course;
  final int? period;
  final String privacyLevel;
  final String? avatarUrl;
  final Institution institution;
  final List<Skill> skills;
  final DateTime createdAt;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    this.bio,
    this.course,
    this.period,
    this.privacyLevel = 'local_only',
    this.avatarUrl,
    required this.institution,
    this.skills = const [],
    required this.createdAt,
  });
}

class Institution {
  final String id;
  final String name;
  final String? slug;

  Institution({required this.id, required this.name, this.slug});
}

class Skill {
  final String id;
  final String name;
  final String category;

  Skill({required this.id, required this.name, required this.category});
}
