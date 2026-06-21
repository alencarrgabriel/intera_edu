import '../entities/chat.dart';

abstract class MessagingRepository {
  Future<List<Chat>> listChats();
  Future<List<ChatMessage>> getMessages(String chatId, {String? cursor});
  Future<ChatMessage> sendMessage(String chatId, String content);
  Future<Chat> createDirectChat(String targetUserId);

  /// RF-24 — Cria um chat em grupo com os membros indicados.
  Future<Chat> createGroupChat({
    required String name,
    required List<String> memberIds,
  });

  /// RF-27 — Anexa um arquivo (PDF/imagem ≤10MB) à conversa.
  /// Retorna a mensagem com `mediaUrls` preenchido.
  Future<ChatMessage> sendAttachment({
    required String chatId,
    required List<int> bytes,
    required String filename,
    required String mimeType,
  });
}
