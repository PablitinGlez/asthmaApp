/// Modelos de dominio para el chat paciente-médico.
///
/// Los endpoints serán consumidos una vez que estén disponibles en el
/// backend; la UI y la navegación ya quedan preparadas en esta feature.

class ChatConversation {
  final String id;
  final String participantId;
  final String participantName;
  final String participantRole;
  final String? avatarSeed;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool isDoctor;

  const ChatConversation({
    required this.id,
    required this.participantId,
    required this.participantName,
    required this.participantRole,
    this.avatarSeed,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
    this.isDoctor = true,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: (json['id'] ?? json['conversation_id'] ?? '').toString(),
      participantId: (json['participant_id'] ?? '').toString(),
      participantName: json['participant_name'] ?? 'Médico',
      participantRole: json['participant_role'] ?? 'doctor',
      avatarSeed: json['avatar_seed']?.toString(),
      lastMessage: json['last_message']?.toString(),
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.tryParse(json['last_message_at'].toString())
          : null,
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      isDoctor: (json['is_doctor'] ?? true) == true,
    );
  }
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final bool isMine;
  final bool isRead;

  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.createdAt,
    required this.isMine,
    this.isRead = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json,
      {required String currentUserId}) {
    final sender = (json['sender_id'] ?? json['from_user_id'] ?? '').toString();
    return ChatMessage(
      id: (json['id'] ?? '').toString(),
      conversationId: (json['conversation_id'] ?? '').toString(),
      senderId: sender,
      text: json['content'] ?? json['message'] ?? '',
      createdAt: DateTime.tryParse(
            json['created_at']?.toString() ?? '',
          ) ??
          DateTime.now(),
      isMine: sender == currentUserId,
      isRead: (json['is_read'] ?? false) == true,
    );
  }
}
