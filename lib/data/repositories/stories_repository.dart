import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../core/config/server_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/storage/secure_storage.dart';
import '../../domain/entities/story.dart';

class StoriesRepository {
  final ApiClient _api;
  final SecureStorageService _storage;
  StoriesRepository({ApiClient? api, SecureStorageService? storage})
      : _api = api ?? ApiClient(),
        _storage = storage ?? SecureStorageService();

  Future<List<StoryGroup>> listActive() async {
    final res = await _api.get(ApiEndpoints.stories);
    return ((res['data'] as List<dynamic>?) ?? const [])
        .map((e) => StoryGroup.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> create({
    required List<int> fileBytes,
    required String filename,
    required String mimeType,
    String? caption,
  }) async {
    final uri = Uri.parse('${ServerConfig.instance.apiBaseUrl}${ApiEndpoints.stories}');
    final token = await _storage.getAccessToken();
    if (token == null) throw Exception('Sessão expirada — faça login.');
    final mime = MediaType.parse(mimeType);
    final req = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: filename,
        contentType: mime,
      ));
    if (caption != null && caption.isNotEmpty) req.fields['caption'] = caption;
    final streamed = await req.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return (json['id'] ?? '').toString();
    }
    throw Exception('Falha ao enviar story (${streamed.statusCode}): $body');
  }

  Future<void> markViewed(String storyId) =>
      _api.post(ApiEndpoints.storyView(storyId)).then((_) {});

  Future<void> delete(String storyId) =>
      _api.delete(ApiEndpoints.story(storyId));
}
