import '../../core/network/api_client.dart';
import '../../core/network/api_endpoints.dart';
import '../../domain/entities/chat.dart';
import '../../domain/repositories/messaging_repository.dart';
import '../models/chat_model.dart';

class MessagingRepositoryImpl implements MessagingRepository {
  final ApiClient _api;
  MessagingRepositoryImpl({ApiClient? api}) : _api = api ?? ApiClient();

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
}
