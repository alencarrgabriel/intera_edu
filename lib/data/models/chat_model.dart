import '../../domain/entities/chat.dart';

class ChatModel extends Chat {
  const ChatModel({
    required super.id,
    required super.type,
    super.name,
    super.members,
    super.lastMessage,
    required super.updatedAt,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    final members = (json['members'] as List<dynamic>? ?? [])
        .map((m) {
          final member = m as Map<String, dynamic>;
          return ChatMember(
            userId: member['user_id'] as String? ?? '',
            fullName: member['full_name'] as String?,
            avatarUrl: member['avatar_url'] as String?,
            role: member['role'] as String? ?? 'member',
          );
        })
        .toList();

    final lastMessageJson = json['last_message'] as Map<String, dynamic>?;
    final lastMessage = lastMessageJson != null
        ? ChatMessageModel.fromJson(lastMessageJson)
        : null;

    return ChatModel(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'direct',
      name: json['name'] as String?,
      members: members,
      lastMessage: lastMessage,
      updatedAt: DateTime.parse(
          json['updated_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.chatId,
    required super.senderId,
    super.senderName,
    required super.content,
    required super.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      chatId: json['chat_id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      senderName: json['sender_name'] as String?,
      content: json['content'] as String? ?? '',
      createdAt: DateTime.parse(
          json['created_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }
}
