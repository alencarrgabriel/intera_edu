import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/feed_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../models/search_result_model.dart';
import '../models/user_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ApiClient _api;
  ProfileRepositoryImpl({ApiClient? api}) : _api = api ?? ApiClient();

  @override
  Future<User> getMyProfile() async {
    final res = await _api.get(ApiEndpoints.myProfile);
    return UserModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  @override
  Future<User> updateProfile(Map<String, dynamic> data) async {
    final res = await _api.patch(ApiEndpoints.myProfile, body: data);
    return UserModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  @override
  Future<User> getUserProfile(String userId) async {
    final res = await _api.get(ApiEndpoints.userProfile(userId));
    return UserModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  @override
  Future<PaginatedResult<SearchResult>> searchUsers(
    String query, {
    String? skillId,
    String? institutionId,
    String? cursor,
  }) async {
    final res = await _api.get(ApiEndpoints.searchUsers, queryParams: {
      'q': query,
      if (skillId != null) 'skill_id': skillId,
      if (institutionId != null) 'institution_id': institutionId,
      if (cursor != null) 'cursor': cursor,
    });
    final data = (res['data'] as List<dynamic>? ?? [])
        .map((e) => SearchResult.fromJson(e as Map<String, dynamic>))
        .toList();
    return PaginatedResult(
      data: data,
      nextCursor: res['next_cursor'] as String?,
    );
  }

  @override
  Future<List<Skill>> getSkills({String? query}) async {
    final res = await _api.get(ApiEndpoints.skills, queryParams: {
      if (query != null && query.isNotEmpty) 'q': query,
    });
    final data = res['data'] as List<dynamic>? ?? [];
    return data
        .map((e) {
          final s = e as Map<String, dynamic>;
          return Skill(
            id: s['id'] as String,
            name: s['name'] as String,
            category: s['category'] as String? ?? '',
          );
        })
        .toList();
  }
}
