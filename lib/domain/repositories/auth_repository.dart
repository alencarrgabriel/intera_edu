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

  /// Faz login via Google enviando o ID token obtido no front-end pelo GIS.
  /// Lança [Exception] se o backend recusar o domínio do e-mail ou se o
  /// endpoint não estiver configurado (env GOOGLE_CLIENT_ID ausente → 503).
  Future<void> loginWithGoogleIdToken(String idToken);

  Future<void> refreshToken();
  Future<void> logout();
  bool get isAuthenticated;

  /// RF-06 — solicita OTP de recuperação de senha.
  Future<void> forgotPassword(String email);

  /// RF-06 — confirma OTP e define nova senha.
  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  });
}
