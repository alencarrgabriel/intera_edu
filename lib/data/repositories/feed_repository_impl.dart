import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/storage/secure_storage.dart';
import '../../domain/entities/post.dart';
import '../../domain/repositories/feed_repository.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';

class FeedRepositoryImpl implements FeedRepository {
  final ApiClient _api;
  final SecureStorageService _storage;
  FeedRepositoryImpl({ApiClient? api, SecureStorageService? storage})
      : _api = api ?? ApiClient(),
        _storage = storage ?? SecureStorageService();

  @override
  Future<PaginatedResult<Post>> getFeed({
    required String scope,
    String? cursor,
    int limit = 20,
  }) async {
    final res = await _api.get(
      ApiEndpoints.posts,
      queryParams: {
        'scope': scope,
        'limit': '$limit',
        if (cursor != null) 'cursor': cursor,
      },
    );
    final data = (res['data'] as List<dynamic>? ?? [])
        .map((e) => PostModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return PaginatedResult(
      data: data,
      nextCursor: res['next_cursor'] as String?,
    );
  }

  @override
  Future<String> createPost({
    required String content,
    String scope = 'global',
    List<int>? fileBytes,
    String? filename,
    String? mimeType,
  }) async {
    if (fileBytes == null || fileBytes.isEmpty) {
      final res = await _api.post(ApiEndpoints.posts, body: {
        'content': content,
        'scope': scope,
      });
      return res['id'] as String;
    }
    // RF-16 — Caminho multipart quando há arquivo. Vai pelo gateway via
    // multipart middleware stream-friendly.
    final uri = Uri.parse('${AppConfig.apiBaseUrl}${ApiEndpoints.posts}');
    final token = await _storage.getAccessToken();
    if (token == null) throw Exception('Sessão expirada — faça login.');
    final mime = MediaType.parse(mimeType ?? 'application/octet-stream');
    final req = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['content'] = content
      ..fields['scope'] = scope
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: filename ?? 'arquivo',
        contentType: mime,
      ));
    final streamed = await req.send();
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode >= 200 && streamed.statusCode < 300) {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['id'] as String;
    }
    throw Exception('Falha ao publicar (${streamed.statusCode}): $body');
  }

  @override
  Future<void> deletePost(String postId) async {
    await _api.delete(ApiEndpoints.post(postId));
  }

  @override
  Future<void> addReaction(String postId, String reactionType) async {
    await _api.post(ApiEndpoints.postReactions(postId), body: {'type': reactionType});
  }

  @override
  Future<void> removeReaction(String postId) async {
    await _api.delete(ApiEndpoints.postReactions(postId));
  }

  @override
  Future<PaginatedResult<Comment>> getComments(String postId, {String? cursor}) async {
    final res = await _api.get(
      ApiEndpoints.postComments(postId),
      queryParams: {
        'limit': '20',
        if (cursor != null) 'cursor': cursor,
      },
    );
    final data = (res['data'] as List<dynamic>? ?? [])
        .map((e) => CommentModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return PaginatedResult(
      data: data,
      nextCursor: res['next_cursor'] as String?,
    );
  }

  @override
  Future<void> addComment(String postId, String content, {String? parentCommentId}) async {
    await _api.post(ApiEndpoints.postComments(postId), body: {
      'content': content,
      if (parentCommentId != null) 'parent_comment_id': parentCommentId,
    });
  }
}
