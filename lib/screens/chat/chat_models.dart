// ============================================================
// MENTORA CHAT - DATA MODELS
// ============================================================

class ConversationModel {
  final String id;
  final List<String> participants; // [userId1, userId2]
  final String requestId; // linked skill exchange request
  final String lastMessage;
  final DateTime lastMessageTime;
  final Map<String, int> unreadCount; // {userId: count}
  final Map<String, String> participantNames;
  final Map<String, String> participantPhotos;

  ConversationModel({
    required this.id,
    required this.participants,
    required this.requestId,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    required this.participantNames,
    required this.participantPhotos,
  });

  factory ConversationModel.fromMap(Map<String, dynamic> map, String id) {
    return ConversationModel(
      id: id,
      participants: List<String>.from(map['participants'] ?? []),
      requestId: map['requestId'] ?? '',
      lastMessage: map['lastMessage'] ?? '',
      lastMessageTime: (map['lastMessageTime'] as dynamic)?.toDate() ?? DateTime.now(),
      unreadCount: Map<String, int>.from(map['unreadCount'] ?? {}),
      participantNames: Map<String, String>.from(map['participantNames'] ?? {}),
      participantPhotos: Map<String, String>.from(map['participantPhotos'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() => {
    'participants': participants,
    'requestId': requestId,
    'lastMessage': lastMessage,
    'lastMessageTime': lastMessageTime,
    'unreadCount': unreadCount,
    'participantNames': participantNames,
    'participantPhotos': participantPhotos,
  };
}

class MessageModel {
  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final DateTime timestamp;
  final bool isRead;
  final MessageType type;

  MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.timestamp,
    required this.isRead,
    this.type = MessageType.text,
  });

  factory MessageModel.fromMap(Map<String, dynamic> map, String id) {
    return MessageModel(
      id: id,
      conversationId: map['conversationId'] ?? '',
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      timestamp: (map['timestamp'] as dynamic)?.toDate() ?? DateTime.now(),
      isRead: map['isRead'] ?? false,
      type: MessageType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'text'),
        orElse: () => MessageType.text,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
    'conversationId': conversationId,
    'senderId': senderId,
    'text': text,
    'timestamp': timestamp,
    'isRead': isRead,
    'type': type.name,
  };
}

enum MessageType { text, image, skillOffer }
