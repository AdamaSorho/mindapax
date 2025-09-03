class ChatMessage {
  final int id;
  final int conversationId;
  final int senderId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final bool delivered; // local-only indicator (true for server-provided messages)
  final String? clientTag; // to match WS echo

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.timestamp,
    required this.isRead,
    this.delivered = true,
    this.clientTag,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> j) {
    return ChatMessage(
      id: (j['id'] as num?)?.toInt() ?? 0,
      conversationId: (j['conversationId'] as num?)?.toInt() ?? 0,
      senderId: (j['senderId'] as num?)?.toInt() ?? 0,
      content: j['content']?.toString() ?? '',
      timestamp: DateTime.tryParse(j['timestamp']?.toString() ?? '') ?? DateTime.now(),
      isRead: (j['isRead'] as bool?) ?? false,
      delivered: true,
      clientTag: j['clientTag']?.toString(),
    );
  }
}

class ConversationSummary {
  final int id;
  final String otherName;
  final String? otherAvatar;
  final ChatMessage? lastMessage;
  final DateTime createdAt;

  ConversationSummary({
    required this.id,
    required this.otherName,
    required this.otherAvatar,
    required this.lastMessage,
    required this.createdAt,
  });

  factory ConversationSummary.fromJson(Map<String, dynamic> j, {required int currentUserId}) {
    final user = j['user'] as Map<String, dynamic>? ?? const {};
    final pro = j['professional'] as Map<String, dynamic>? ?? const {};
    final proUser = pro['user'] as Map<String, dynamic>? ?? const {};
    // Determine other participant's name
    // Backend packs both user and professional; current user may be either role.
    String userName = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
    String proName = '${proUser['firstName'] ?? ''} ${proUser['lastName'] ?? ''}'.trim();
    final userId = (user['id'] as num?)?.toInt();
    final otherName = (userId != null && userId == currentUserId) ? proName : userName;
    final otherAvatar = (userId != null && userId == currentUserId) ? proUser['avatar']?.toString() : user['avatar']?.toString();

    final lm = j['lastMessage'] as Map<String, dynamic>?;
    return ConversationSummary(
      id: (j['id'] as num?)?.toInt() ?? 0,
      otherName: otherName.isEmpty ? 'Conversation' : otherName,
      otherAvatar: otherAvatar,
      lastMessage: lm == null ? null : ChatMessage.fromJson(lm),
      createdAt: DateTime.tryParse(j['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
