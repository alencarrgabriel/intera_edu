import '../network/api_client.dart';
import '../storage/secure_storage.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/connection_repository_impl.dart';
import '../../data/repositories/feed_repository_impl.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/connection_repository.dart';
import '../../domain/repositories/feed_repository.dart';
import '../../domain/repositories/profile_repository.dart';

/// Service locator minimalista para instanciar dependências compartilhadas
/// uma única vez (lazy singletons). Garante que o `ApiClient` seja único,
/// evitando múltiplas filas de refresh token e permitindo testes com overrides.
class ServiceLocator {
  ServiceLocator._();
  static final ServiceLocator instance = ServiceLocator._();

  ApiClient? _apiClient;
  SecureStorageService? _storage;
  AuthRepository? _authRepo;
  ProfileRepository? _profileRepo;
  FeedRepository? _feedRepo;
  ConnectionRepository? _connRepo;

  SecureStorageService get storage => _storage ??= SecureStorageService();
  ApiClient get apiClient => _apiClient ??= ApiClient();

  AuthRepository get authRepo =>
      _authRepo ??= AuthRepositoryImpl(api: apiClient);
  ProfileRepository get profileRepo =>
      _profileRepo ??= ProfileRepositoryImpl(api: apiClient);
  FeedRepository get feedRepo =>
      _feedRepo ??= FeedRepositoryImpl(api: apiClient);
  ConnectionRepository get connRepo =>
      _connRepo ??= ConnectionRepositoryImpl(api: apiClient);

  /// Substitui instâncias para testes. Chame `reset()` no `tearDown`.
  void registerOverrides({
    ApiClient? apiClient,
    SecureStorageService? storage,
    AuthRepository? authRepo,
    ProfileRepository? profileRepo,
    FeedRepository? feedRepo,
    ConnectionRepository? connRepo,
  }) {
    _apiClient = apiClient ?? _apiClient;
    _storage = storage ?? _storage;
    _authRepo = authRepo ?? _authRepo;
    _profileRepo = profileRepo ?? _profileRepo;
    _feedRepo = feedRepo ?? _feedRepo;
    _connRepo = connRepo ?? _connRepo;
  }

  void reset() {
    _apiClient = null;
    _storage = null;
    _authRepo = null;
    _profileRepo = null;
    _feedRepo = null;
    _connRepo = null;
  }
}

/// Atalho global para acesso conveniente: `sl.feedRepo`.
final ServiceLocator sl = ServiceLocator.instance;
