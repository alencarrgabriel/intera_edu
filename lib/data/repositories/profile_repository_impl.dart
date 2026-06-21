import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/storage/secure_storage.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/feed_repository.dart';
import '../../domain/repositories/profile_repository.dart';
import '../models/search_result_model.dart';
import '../models/user_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ApiClient _api;
  final SecureStorageService _storage;
  ProfileRepositoryImpl({ApiClient? api, SecureStorageService? storage})
      : _api = api ?? ApiClient(),
        _storage = storage ?? SecureStorageService();

  @override
  Future<User> getMyProfile() async {
    final res = await _api.get(ApiEndpoints.myProfile);
    return UserModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  @override
  Future<User> updateProfile(Map<String, dynamic> data) async {
    final res = await _api.patch(ApiEndpoints.myProfile, body: data);
    return UserModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  @override
  Future<User> getUserProfile(String userId) async {
    final res = await _api.get(ApiEndpoints.userProfile(userId));
    return UserModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  @override
  Future<PaginatedResult<SearchResult>> searchUsers(
    String query, {
    String? skillId,
    String? institutionId,
    String? course,
    String? cursor,
  }) async {
    final res = await _api.get(ApiEndpoints.searchUsers, queryParams: {
      'q': query,
      // Backend reads `institution` (não `institution_id`) e `course`.
      // `skill_id` é filtrado no cliente até o backend ganhar esse filtro.
      if (institutionId != null) 'institution': institutionId,
      if (course != null) 'course': course,
      if (cursor != null) 'cursor': cursor,
    });
    var data = (res['data'] as List<dynamic>? ?? [])
        .map((e) => SearchResult.fromJson(e as Map<String, dynamic>))
        .toList();
    if (skillId != null) {
      data = data
          .where((r) => r.skills.any((s) => s.id == skillId))
          .toList(growable: false);
    }
    return PaginatedResult(
      data: data,
      nextCursor: res['next_cursor'] as String?,
    );
  }

  @override
  Future<String> uploadAvatar({
    required List<int> bytes,
    required String filename,
    required String mimeType,
  }) async {
    // O gateway agora encaminha multipart corretamente via
    // MultipartProxyMiddleware (stream raw), então usamos a URL pública.
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/users/me/avatar');
    final token = await _storage.getAccessToken();
    if (token == null) {
      throw Exception('Sessão expirada — faça login novamente');
    }

    final mime = MediaType.parse(mimeType);
    final req = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: mime,
      ));

    final streamed = await req.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['avatar_url'] as String;
    }
    String message;
    try {
      final err = jsonDecode(body);
      message = err is Map && err['error'] is Map
          ? (err['error']['message'] as String? ?? body)
          : body;
    } catch (_) {
      message = body;
    }
    throw Exception('Falha no upload (${streamed.statusCode}): $message');
  }

  @override
  Future<void> blockUser(String userId) =>
      _api.post(ApiEndpoints.blockUser(userId));

  @override
  Future<void> unblockUser(String userId) =>
      _api.delete(ApiEndpoints.blockUser(userId));

  @override
  Future<List<String>> listBlocked() async {
    final res = await _api.get(ApiEndpoints.myBlocks);
    final data = res['data'] as List<dynamic>? ?? [];
    return data.map((e) => e.toString()).toList();
  }

  @override
  Future<List<Skill>> getSkills({String? query}) async {
    final res = await _api.get(ApiEndpoints.skills, queryParams: {
      if (query != null && query.isNotEmpty) 'q': query,
    });
    final data = res['data'] as List<dynamic>? ?? [];
    return data
        .map((e) {
          final s = e as Map<String, dynamic>;
          return Skill(
            id: s['id'] as String,
            name: s['name'] as String,
            category: s['category'] as String? ?? '',
          );
        })
        .toList();
  }
}
