class W2GChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final String type;
  final String? imageUrl;
  final String? localPath;
  final Map<String, String> reactions;
  final String? replyToId;
  final String? replyToContent;
  final String? replyToSenderId;
  final String? replyToType;

  W2GChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.type = 'text',
    this.imageUrl,
    this.localPath,
    this.reactions = const {},
    this.replyToId,
    this.replyToContent,
    this.replyToSenderId,
    this.replyToType,
  });

  W2GChatMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? text,
    DateTime? timestamp,
    String? type,
    String? imageUrl,
    String? localPath,
    Map<String, String>? reactions,
    String? replyToId,
    String? replyToContent,
    String? replyToSenderId,
    String? replyToType,
  }) {
    return W2GChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      localPath: localPath ?? this.localPath,
      reactions: reactions ?? this.reactions,
      replyToId: replyToId ?? this.replyToId,
      replyToContent: replyToContent ?? this.replyToContent,
      replyToSenderId: replyToSenderId ?? this.replyToSenderId,
      replyToType: replyToType ?? this.replyToType,
    );
  }
}
