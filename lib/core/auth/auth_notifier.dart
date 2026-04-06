import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../storage/secure_storage.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';

/// Estados possíveis da autenticação
enum AuthStatus { loading, authenticated, unauthenticated }

/// Gerenciador global de estado de autenticação.
/// Responsável por verificar sessão, login, logout e refresh de token.
class AuthNotifier extends ChangeNotifier {
  final AuthRepository _authRepo;
  final SecureStorageService _storage;

  AuthStatus _status = AuthStatus.loading;
  AuthStatus get status => _status;
  String? _userId;
  String? get userId => _userId;

  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthNotifier({
    AuthRepository? authRepo,
    SecureStorageService? storage,
  })  : _authRepo = authRepo ?? AuthRepositoryImpl(),
        _storage = storage ?? SecureStorageService();

  /// Verifica se há sessão válida ao iniciar o app.
  /// - Se tem access token → autenticado
  /// - Se tem refresh token → tenta renovar → autenticado ou não autenticado
  /// - Se não tem nada → não autenticado
  Future<void> checkSession() async {
    _setStatus(AuthStatus.loading);

    try {
      final accessToken = await _storage.getAccessToken();
      if (accessToken != null) {
        _userId = _decodeUserId(accessToken);
        _setStatus(AuthStatus.authenticated);
        return;
      }

      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken != null) {
        await _authRepo.refreshToken();
        _setStatus(AuthStatus.authenticated);
        return;
      }
    } catch (_) {
      // Refresh falhou ou token inválido — limpar storage
      await _storage.clearTokens();
    }

    _setStatus(AuthStatus.unauthenticated);
  }

  /// Realiza o login e atualiza o estado para autenticado.
  Future<void> login(String email, String password) async {
    await _authRepo.login(email, password);
    final token = await _storage.getAccessToken();
    _userId = token != null ? _decodeUserId(token) : null;
    _setStatus(AuthStatus.authenticated);
  }

  /// Realiza o logout: invalida token no servidor e limpa estado local.
  Future<void> logout() async {
    await _authRepo.logout();
    _setStatus(AuthStatus.unauthenticated);
  }

  /// Chamado pelo ApiClient quando recebe 401 e o refresh também falha.
  void forceLogout() {
    _storage.clearTokens();
    _setStatus(AuthStatus.unauthenticated);
  }

  void _setStatus(AuthStatus status) {
    _status = status;
    notifyListeners();
  }

  /// Decodes the JWT payload to extract the user ID (`sub` claim).
  /// No signature verification needed — we already trust our own storage.
  static String? _decodeUserId(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = parts[1];
      final normalized = base64.normalize(payload);
      final decoded = utf8.decode(base64.decode(normalized));
      final json = jsonDecode(decoded) as Map<String, dynamic>;
      return json['sub'] as String?;
    } catch (_) {
      return null;
    }
  }
}
