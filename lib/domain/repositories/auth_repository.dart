/// Abstract auth repository — domain layer contract.
abstract class AuthRepository {
  Future<void> register(String email);
  Future<String> verifyOtp(String email, String code);
  Future<void> completeRegistration({
    required String temporaryToken,
    required String password,
    required String fullName,
    String? course,
    int? period,
    List<String>? skillIds,
  });
  Future<void> login(String email, String password);
  Future<void> refreshToken();
  Future<void> logout();
  bool get isAuthenticated;
}
