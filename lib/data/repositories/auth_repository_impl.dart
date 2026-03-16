import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/storage/secure_storage.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final ApiClient _api;
  final SecureStorageService _storage;

  AuthRepositoryImpl({ApiClient? api, SecureStorageService? storage})
      : _api = api ?? ApiClient(),
        _storage = storage ?? SecureStorageService();

  @override
  Future<void> register(String email) async {
    await _api.post(ApiEndpoints.register, body: {'email': email});
  }

  @override
  Future<String> verifyOtp(String email, String code) async {
    final response = await _api.post(ApiEndpoints.verifyOtp, body: {
      'email': email,
      'code': code,
    });
    return response['temporary_token'] as String;
  }

  @override
  Future<void> completeRegistration({
    required String temporaryToken,
    required String password,
    required String fullName,
    String? course,
    int? period,
    List<String>? skillIds,
  }) async {
    final response = await _api.post(ApiEndpoints.completeRegistration, body: {
      'temporary_token': temporaryToken,
      'password': password,
      'full_name': fullName,
      if (course != null) 'course': course,
      if (period != null) 'period': period,
      if (skillIds != null) 'skill_ids': skillIds,
      'consent': {
        'terms_version': 'v1.0',
        'privacy_version': 'v1.0',
      },
    });
    await _saveTokens(response['tokens']);
  }

  @override
  Future<void> login(String email, String password) async {
    final response = await _api.post(ApiEndpoints.login, body: {
      'email': email,
      'password': password,
    });
    await _saveTokens(response['tokens']);
  }

  @override
  Future<void> refreshToken() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) throw Exception('No refresh token');

    final response = await _api.post(ApiEndpoints.refresh, body: {
      'refresh_token': refreshToken,
    });
    await _saveTokens(response['tokens']);
  }

  @override
  Future<void> logout() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken != null) {
      try {
        await _api.post(ApiEndpoints.logout, body: {'refresh_token': refreshToken});
      } catch (_) {
        // Logout should always succeed locally even if API fails
      }
    }
    await _storage.clearTokens();
  }

  @override
  bool get isAuthenticated => _storage.isAuthenticated;

  Future<void> _saveTokens(Map<String, dynamic> tokens) async {
    await _storage.saveTokens(
      accessToken: tokens['access_token'] as String,
      refreshToken: tokens['refresh_token'] as String,
    );
  }
}
