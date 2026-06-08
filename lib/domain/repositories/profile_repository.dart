import '../../data/models/search_result_model.dart';
import '../entities/user.dart';
import 'feed_repository.dart';

abstract class ProfileRepository {
  Future<User> getMyProfile();
  Future<User> updateProfile(Map<String, dynamic> data);
  Future<User> getUserProfile(String userId);
  Future<PaginatedResult<SearchResult>> searchUsers(String query, {String? skillId, String? institutionId, String? cursor});
  Future<List<Skill>> getSkills({String? query});

  /// Faz upload de avatar a partir dos bytes (multipart/form-data).
  /// Retorna a URL pública.
  Future<String> uploadAvatar({
    required List<int> bytes,
    required String filename,
    required String mimeType,
  });
}
