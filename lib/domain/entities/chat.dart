class Chat {
  final String id;
  final String type; // 'direct' | 'group'
  final String? name;
  final List<ChatMember> members;
  final ChatMessage? lastMessage;
  final DateTime updatedAt;

  const Chat({
    required this.id,
    required this.type,
    this.name,
    this.members = const [],
    this.lastMessage,
    required this.updatedAt,
  });

  String displayName(String currentUserId) {
    if (name != null && name!.isNotEmpty) return name!;
    if (type == 'direct') {
      final other = members.firstWhere(
        (m) => m.userId != currentUserId,
        orElse: () => members.isNotEmpty ? members.first : const ChatMember(userId: '', role: 'member'),
      );
      return other.fullName ?? 'Usuário';
    }
    return 'Grupo';
  }
}

class ChatMember {
  final String userId;
  final String? fullName;
  final String? avatarUrl;
  final String role;

  const ChatMember({
    required this.userId,
    this.fullName,
    this.avatarUrl,
    this.role = 'member',
  });
}

class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String? senderName;
  final String content;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.senderName,
    required this.content,
    required this.createdAt,
  });
}
