import '../entities/chat.dart';

abstract class MessagingRepository {
  Future<List<Chat>> listChats();
  Future<List<ChatMessage>> getMessages(String chatId, {String? cursor});
  Future<ChatMessage> sendMessage(String chatId, String content);
  Future<Chat> createDirectChat(String targetUserId);
}
