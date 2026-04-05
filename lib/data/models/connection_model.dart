import '../../domain/entities/user.dart';

class Connection {
  final String id;
  final String status;
  final String? direction;
  final ConnectionUser? otherUser;
  final DateTime createdAt;

  Connection({
    required this.id,
    required this.status,
    this.direction,
    this.otherUser,
    required this.createdAt,
  });

  factory Connection.fromJson(Map<String, dynamic> json) {
    final user = json['other_user'] as Map<String, dynamic>?;

    return Connection(
      id: json['id'].toString(),
      status: (json['status'] ?? '').toString(),
      direction: json['direction']?.toString(),
      otherUser: user != null ? ConnectionUser.fromJson(user) : null,
      createdAt: DateTime.parse(
          json['created_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}

class ConnectionUser {
  final String id;
  final String fullName;
  final String? course;
  final String? avatarUrl;
  final Institution? institution;

  ConnectionUser({
    required this.id,
    required this.fullName,
    this.course,
    this.avatarUrl,
    this.institution,
  });

  factory ConnectionUser.fromJson(Map<String, dynamic> json) {
    final inst = json['institution'] as Map<String, dynamic>?;

    return ConnectionUser(
      id: json['id'].toString(),
      fullName: (json['full_name'] ?? 'Usuário').toString(),
      course: json['course']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      institution: inst != null
          ? Institution(
              id: inst['id']?.toString() ?? '',
              name: inst['name']?.toString() ?? '',
              slug: inst['slug']?.toString(),
            )
          : null,
    );
  }
}
