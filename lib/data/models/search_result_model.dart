import '../../domain/entities/user.dart';

class SearchResult {
  final String id;
  final String fullName;
  final String? course;
  final String? avatarUrl;
  final Institution? institution;

  SearchResult({
    required this.id,
    required this.fullName,
    this.course,
    this.avatarUrl,
    this.institution,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    final inst = json['institution'] as Map<String, dynamic>?;

    return SearchResult(
      id: json['id'].toString(),
      fullName: (json['full_name'] ?? 'Sem nome').toString(),
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
