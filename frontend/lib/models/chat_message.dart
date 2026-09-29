class ChatMessage {
  final int id;
  final int senderId;
  final String senderName;
  final String? senderAvatar;
  final int receiverId;
  final String receiverName;
  final String? receiverAvatar;
  final String content;
  final String? imageUrl;
  final bool isRead;
  final DateTime createdAt;
  final bool fromMe;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderAvatar,
    required this.receiverId,
    required this.receiverName,
    this.receiverAvatar,
    required this.content,
    this.imageUrl,
    required this.isRead,
    required this.createdAt,
    required this.fromMe,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: (json['id'] as num).toInt(),
      senderId: (json['senderId'] as num).toInt(),
      senderName: (json['senderName'] as String?) ?? 'Người dùng',
      senderAvatar: json['senderAvatar'] as String?,
      receiverId: (json['receiverId'] as num).toInt(),
      receiverName: (json['receiverName'] as String?) ?? 'Người dùng',
      receiverAvatar: json['receiverAvatar'] as String?,
      content: (json['content'] as String?) ?? '',
      imageUrl: json['imageUrl'] as String?,
      isRead: (json['isRead'] as bool?) ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      fromMe: (json['fromMe'] as bool?) ?? false,
    );
  }
}
