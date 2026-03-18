import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ApiClient _api;
  ProfileRepositoryImpl({ApiClient? api}) : _api = api ?? ApiClient();

  @override
  Future<Map<String, dynamic>> getMyProfile() {
    return _api.get(ApiEndpoints.myProfile);
  }

  @override
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) {
    return _api.patch(ApiEndpoints.myProfile, body: data);
  }

  @override
  Future<Map<String, dynamic>> getUserProfile(String userId) {
    return _api.get(ApiEndpoints.userProfile(userId));
  }

  @override
  Future<Map<String, dynamic>> searchUsers(
    String query, {
    String? skillId,
    String? institutionId,
    String? cursor,
  }) {
    return _api.get(ApiEndpoints.searchUsers, queryParams: {
      'q': query,
      if (skillId != null) 'skill_id': skillId,
      if (institutionId != null) 'institution_id': institutionId,
      if (cursor != null) 'cursor': cursor,
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getSkills({String? query}) async {
    final res = await _api.get(ApiEndpoints.skills, queryParams: {
      if (query != null && query.isNotEmpty) 'q': query,
    });
    final data = res['data'] as List<dynamic>? ?? [];
    return data.cast<Map<String, dynamic>>();
  }
}
