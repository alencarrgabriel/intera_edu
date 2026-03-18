import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Serviço de armazenamento seguro de tokens usando flutter_secure_storage.
/// Persiste os tokens entre sessões do app (armazenamento nativo seguro por plataforma).
class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _keyAccessToken, value: accessToken),
      _storage.write(key: _keyRefreshToken, value: refreshToken),
    ]);
    debugPrint('[SecureStorage] Tokens salvos');
  }

  Future<String?> getAccessToken() async =>
      _storage.read(key: _keyAccessToken);

  Future<String?> getRefreshToken() async =>
      _storage.read(key: _keyRefreshToken);

  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _keyAccessToken),
      _storage.delete(key: _keyRefreshToken),
    ]);
    debugPrint('[SecureStorage] Tokens removidos');
  }

  Future<bool> get isAuthenticatedAsync async {
    final token = await getAccessToken();
    return token != null;
  }

  /// Compatibilidade com código legado — preferir isAuthenticatedAsync
  bool get isAuthenticated => false;
}
