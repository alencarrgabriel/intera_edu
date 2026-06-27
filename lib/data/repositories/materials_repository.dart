import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/storage/secure_storage.dart';
import '../../domain/entities/material.dart';

class MaterialsRepository {
  final ApiClient _api;
  final SecureStorageService _storage;
  MaterialsRepository({ApiClient? api, SecureStorageService? storage})
      : _api = api ?? ApiClient(),
        _storage = storage ?? SecureStorageService();

  Future<List<GroupMaterial>> list(String groupId) async {
    final res = await _api.get(ApiEndpoints.groupMaterials(groupId));
    return ((res['data'] as List<dynamic>?) ?? const [])
        .map((e) => GroupMaterial.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> upload({
    required String groupId,
    required String title,
    String? description,
    required List<int> fileBytes,
    required String filename,
    required String mimeType,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}${ApiEndpoints.groupMaterials(groupId)}');
    final token = await _storage.getAccessToken();
    if (token == null) throw Exception('Sessão expirada — faça login.');
    final mime = MediaType.parse(mimeType);
    final req = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['title'] = title
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: filename,
        contentType: mime,
      ));
    if (description != null) req.fields['description'] = description;
    final streamed = await req.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return (json['id'] ?? '').toString();
    }
    throw Exception('Falha ao enviar material (${streamed.statusCode}): $body');
  }

  Future<String> getDownloadUrl(String materialId) async {
    final res = await _api.get(ApiEndpoints.materialDownload(materialId));
    return (res['url'] ?? '').toString();
  }

  Future<void> rate(String materialId, int rating) async {
    await _api.post(ApiEndpoints.materialRate(materialId), body: {'rating': rating});
  }

  Future<void> delete(String materialId) =>
      _api.delete(ApiEndpoints.material(materialId));
}
