abstract class ProfileRepository {
  Future<Map<String, dynamic>> getMyProfile();
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data);
  Future<Map<String, dynamic>> getUserProfile(String userId);
  Future<Map<String, dynamic>> searchUsers(String query, {String? skillId, String? institutionId, String? cursor});
  Future<List<Map<String, dynamic>>> getSkills({String? query});
}
