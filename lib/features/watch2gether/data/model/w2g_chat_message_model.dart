import 'package:chat_application/features/watch2gether/domain/entity/w2g_chat_message.dart';

class W2GChatMessageModel extends W2GChatMessage {
  W2GChatMessageModel({
    required super.id,
    required super.senderId,
    required super.senderName,
    required super.text,
    required super.timestamp,
  });

  factory W2GChatMessageModel.fromMap(String id, Map<String, dynamic> map) {
    return W2GChatMessageModel(
      id: id,
      senderId: map['senderId'] as String? ?? '',
      senderName: map['senderName'] as String? ?? '',
      text: map['text'] as String? ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (map['timestamp'] as num).toInt())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }
}
