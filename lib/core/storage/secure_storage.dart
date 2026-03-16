import 'package:flutter/foundation.dart';

/// Secure storage service for tokens.
/// In production, use flutter_secure_storage package.
/// This is a simplified in-memory implementation for development.
class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  String? _accessToken;
  String? _refreshToken;

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    debugPrint('[SecureStorage] Tokens saved');
  }

  Future<String?> getAccessToken() async => _accessToken;
  Future<String?> getRefreshToken() async => _refreshToken;

  Future<void> clearTokens() async {
    _accessToken = null;
    _refreshToken = null;
    debugPrint('[SecureStorage] Tokens cleared');
  }

  bool get isAuthenticated => _accessToken != null;
}
