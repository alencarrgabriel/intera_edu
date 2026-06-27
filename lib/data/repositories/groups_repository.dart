import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../domain/entities/discipline_group.dart';
import '../../domain/entities/post.dart';
import '../models/post_model.dart';

class GroupMember {
  final String userId;
  final String role;
  final String? fullName;
  final String? avatarUrl;
  final String? course;
  GroupMember({
    required this.userId,
    required this.role,
    this.fullName,
    this.avatarUrl,
    this.course,
  });
}

class GroupsRepository {
  final ApiClient _api;
  GroupsRepository({ApiClient? api}) : _api = api ?? ApiClient();

  Future<List<Discipline>> listDisciplines({String? q}) async {
    final res = await _api.get(
      ApiEndpoints.disciplines,
      queryParams: {if (q != null && q.isNotEmpty) 'q': q},
    );
    return ((res['data'] as List<dynamic>?) ?? const [])
        .map((e) => Discipline.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Discipline> createDiscipline({
    required String code,
    required String name,
    String? period,
    String? description,
  }) async {
    final res = await _api.post(ApiEndpoints.disciplines, body: {
      'code': code,
      'name': name,
      if (period != null) 'period': period,
      if (description != null) 'description': description,
    });
    return Discipline.fromJson(res);
  }

  Future<List<DisciplineGroup>> listGroups({bool mine = false, String? q}) async {
    final res = await _api.get(
      ApiEndpoints.groups,
      queryParams: {
        if (mine) 'mine': 'true',
        if (q != null && q.isNotEmpty) 'q': q,
      },
    );
    return ((res['data'] as List<dynamic>?) ?? const [])
        .map((e) => DisciplineGroup.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DisciplineGroup> createGroup({
    required String disciplineId,
    String? name,
    String? description,
  }) async {
    final res = await _api.post(ApiEndpoints.groups, body: {
      'discipline_id': disciplineId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
    });
    return DisciplineGroup.fromJson(res);
  }

  Future<DisciplineGroup> getGroup(String groupId) async {
    final res = await _api.get(ApiEndpoints.group(groupId));
    return DisciplineGroup.fromJson(res);
  }

  Future<void> joinGroup(String groupId) =>
      _api.post(ApiEndpoints.groupJoin(groupId)).then((_) {});

  Future<void> leaveGroup(String groupId) =>
      _api.delete(ApiEndpoints.groupJoin(groupId));

  Future<List<Post>> groupFeed(String groupId, {String? cursor}) async {
    final res = await _api.get(ApiEndpoints.groupFeed(groupId), queryParams: {
      if (cursor != null) 'cursor': cursor,
    });
    return ((res['data'] as List<dynamic>?) ?? const [])
        .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<GroupMember>> listMembers(String groupId) async {
    final res = await _api.get(ApiEndpoints.groupMembers(groupId));
    final rawList = ((res['data'] as List<dynamic>?) ?? const []);
    if (rawList.isEmpty) return const [];
    final ids = rawList
        .map((e) => ((e as Map)['user_id'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toList();
    // Enriquece com profile data via /users/batch
    Map<String, Map<String, dynamic>> profiles = {};
    try {
      final batch = await _api.get('/users/batch', queryParams: {
        'ids': ids.join(','),
      });
      final list = ((batch['data'] as List<dynamic>?) ?? const []);
      profiles = {
        for (final p in list) (p as Map)['id'].toString(): Map<String, dynamic>.from(p),
      };
    } catch (_) {}
    return rawList.map((raw) {
      final m = raw as Map;
      final id = (m['user_id'] ?? '').toString();
      final p = profiles[id];
      return GroupMember(
        userId: id,
        role: (m['role'] ?? 'member').toString(),
        fullName: p?['full_name'] as String?,
        avatarUrl: p?['avatar_url'] as String?,
        course: p?['course'] as String?,
      );
    }).toList();
  }
}
