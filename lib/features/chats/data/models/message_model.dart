import 'package:chat_application/features/chats/domain/entities/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel extends Message {

  MessageModel({
    required super.id,
    required super.senderId,
    required super.content,
    required super.createdAt,
    required super.deletedfor,
    required super.status,
    super.type,
    super.isLocal,
    super.sendAt,
    super.isScheduled,
  });

  factory MessageModel.fromJson(
    Map<String,dynamic> map,
    String id
  ){
    return MessageModel(
      id: id,
      senderId: map['senderId'],
      content: map['content'],
      status: map['status'] ?? "read",
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      type: map['type'] ?? "text",
      deletedfor: List<String>.from(map['deletedFor'] ?? []),
      sendAt: map['sendAt'] != null
        ? (map['sendAt'] as Timestamp).toDate()
        : null,
      isScheduled: map['isScheduled'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    final data = {
      "senderId": senderId,
      "content": content,
      "createdAt": Timestamp.fromDate(createdAt),
      "status": status,
      "deletedFor": deletedfor,
      "type": type,
      "isScheduled": sendAt != null,
    };

    if (sendAt != null) {
      data["sendAt"] = Timestamp.fromDate(sendAt!);
    }

    return data;
  }
}