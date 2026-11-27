class ChatMessage {
  final int id;
  final int conversationId;
  final int? senderId;
  final String? senderName;
  final String? senderRole; // "PROVIDER" | "SEEKER"
  final String messageType; // "TEXT" | "SYSTEM"
  final String content;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.conversationId,
    this.senderId,
    this.senderName,
    this.senderRole,
    required this.messageType,
    required this.content,
    required this.createdAt,
  });

  bool get isSystem => messageType == 'SYSTEM';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      conversationId: json['conversationId'] is int
          ? json['conversationId']
          : int.parse(json['conversationId'].toString()),
      senderId: json['senderId'] != null
          ? (json['senderId'] is int
              ? json['senderId']
              : int.parse(json['senderId'].toString()))
          : null,
      senderName: json['senderName'] as String?,
      senderRole: json['senderRole'] as String?,
      messageType: json['messageType'] as String? ?? 'TEXT',
      content: json['content'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'senderRole': senderRole,
      'messageType': messageType,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
