import '../network/api_client.dart';
import '../storage/secure_storage.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/connection_repository_impl.dart';
import '../../data/repositories/feed_repository_impl.dart';
import '../../data/repositories/messaging_repository_impl.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../data/repositories/groups_repository.dart';
import '../../data/repositories/materials_repository.dart';
import '../../data/repositories/bookmarks_repository.dart';
import '../../data/repositories/stories_repository.dart';
import '../../data/repositories/tags_repository.dart';
import '../../data/repositories/suggestions_repository.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/connection_repository.dart';
import '../../domain/repositories/feed_repository.dart';
import '../../domain/repositories/messaging_repository.dart';
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
  MessagingRepository? _messagingRepo;
  GroupsRepository? _groupsRepo;
  MaterialsRepository? _materialsRepo;
  BookmarksRepository? _bookmarksRepo;
  StoriesRepository? _storiesRepo;
  TagsRepository? _tagsRepo;
  SuggestionsRepository? _suggestionsRepo;

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
  MessagingRepository get messagingRepo =>
      _messagingRepo ??= MessagingRepositoryImpl(api: apiClient);
  GroupsRepository get groupsRepo =>
      _groupsRepo ??= GroupsRepository(api: apiClient);
  MaterialsRepository get materialsRepo =>
      _materialsRepo ??= MaterialsRepository(api: apiClient, storage: storage);
  BookmarksRepository get bookmarksRepo =>
      _bookmarksRepo ??= BookmarksRepository(api: apiClient);
  StoriesRepository get storiesRepo =>
      _storiesRepo ??= StoriesRepository(api: apiClient, storage: storage);
  TagsRepository get tagsRepo =>
      _tagsRepo ??= TagsRepository(api: apiClient);
  SuggestionsRepository get suggestionsRepo =>
      _suggestionsRepo ??= SuggestionsRepository(api: apiClient);

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
    _messagingRepo = null;
    _groupsRepo = null;
    _materialsRepo = null;
    _bookmarksRepo = null;
    _storiesRepo = null;
    _tagsRepo = null;
    _suggestionsRepo = null;
  }
}

/// Atalho global para acesso conveniente: `sl.feedRepo`.
final ServiceLocator sl = ServiceLocator.instance;
