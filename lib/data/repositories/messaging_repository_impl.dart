import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../core/storage/secure_storage.dart';
import '../../domain/entities/chat.dart';
import '../../domain/repositories/messaging_repository.dart';
import '../models/chat_model.dart';

class MessagingRepositoryImpl implements MessagingRepository {
  final ApiClient _api;
  final SecureStorageService _storage;
  MessagingRepositoryImpl({ApiClient? api, SecureStorageService? storage})
      : _api = api ?? ApiClient(),
        _storage = storage ?? SecureStorageService();

  @override
  Future<List<Chat>> listChats() async {
    final res = await _api.get(ApiEndpoints.chats);
    final data = res['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => ChatModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ChatMessage>> getMessages(String chatId, {String? cursor}) async {
    final res = await _api.get(
      ApiEndpoints.chatMessages(chatId),
      queryParams: {
        'limit': '50',
        if (cursor != null) 'cursor': cursor,
      },
    );
    final data = res['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ChatMessage> sendMessage(String chatId, String content) async {
    final res = await _api.post(
      ApiEndpoints.chatMessages(chatId),
      body: {'content': content},
    );
    return ChatMessageModel.fromJson(res);
  }

  @override
  Future<Chat> createDirectChat(String targetUserId) async {
    final res = await _api.post(
      ApiEndpoints.chats,
      body: {'type': 'direct', 'member_ids': [targetUserId]},
    );
    return ChatModel.fromJson(res);
  }

  @override
  Future<Chat> createGroupChat({
    required String name,
    required List<String> memberIds,
  }) async {
    final res = await _api.post(
      ApiEndpoints.chats,
      body: {'type': 'group', 'name': name, 'member_ids': memberIds},
    );
    return ChatModel.fromJson(res);
  }

  @override
  Future<ChatMessage> sendAttachment({
    required String chatId,
    required List<int> bytes,
    required String filename,
    required String mimeType,
  }) async {
    // RF-27 — Upload multipart vai pelo gateway (multipart proxy stream-friendly).
    final uri = Uri.parse(
        '${AppConfig.apiBaseUrl}${ApiEndpoints.chatMessages(chatId)}');
    final token = await _storage.getAccessToken();
    if (token == null) throw Exception('Sessão expirada — faça login.');

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
      return ChatMessageModel.fromJson(jsonDecode(body) as Map<String, dynamic>);
    }
    throw Exception('Upload falhou (${streamed.statusCode}): $body');
  }
}
