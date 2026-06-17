import 'package:chat_application/features/watch2gether/domain/entity/w2g_chat_message.dart';

class W2GChatMessageModel extends W2GChatMessage {
  W2GChatMessageModel({
    required super.id,
    required super.senderId,
    required super.senderName,
    required super.text,
    required super.timestamp,
    super.type,
    super.imageUrl,
    super.localPath,
    super.reactions,
    super.replyToId,
    super.replyToContent,
    super.replyToSenderId,
    super.replyToType,
  });

  factory W2GChatMessageModel.fromMap(String id, Map<String, dynamic> map) {
    final reactionsMap = (map['reactions'] as Map?)?.cast<String, dynamic>() ?? {};
    final reactions = reactionsMap.map((k, v) => MapEntry(k, v.toString()));

    return W2GChatMessageModel(
      id: id,
      senderId: map['senderId'] as String? ?? '',
      senderName: map['senderName'] as String? ?? '',
      text: map['text'] as String? ?? '',
      type: map['type'] as String? ?? 'text',
      imageUrl: map['imageUrl'] as String?,
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (map['timestamp'] as num).toInt())
          : DateTime.now(),
      reactions: reactions,
      replyToId: map['replyToId'] as String?,
      replyToContent: map['replyToContent'] as String?,
      replyToSenderId: map['replyToSenderId'] as String?,
      replyToType: map['replyToType'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'type': type,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'timestamp': timestamp.millisecondsSinceEpoch,
      if (reactions.isNotEmpty) 'reactions': reactions,
      if (replyToId != null) 'replyToId': replyToId,
      if (replyToContent != null) 'replyToContent': replyToContent,
      if (replyToSenderId != null) 'replyToSenderId': replyToSenderId,
      if (replyToType != null) 'replyToType': replyToType,
    };
  }
}
