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
    super.isLocal
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
      createdAt: parseCreatedAt(map["createdAt"]),
      type: map['type'] ?? "text",
      deletedfor:
        List<String>.from(map['deletedFor'] ?? []),
    );
  }

static String parseCreatedAt(dynamic value) {
  if (value == null) return DateTime.now().toString();

  if (value is Timestamp) {
    return value.toDate().toString();
  }

  if (value is String) {
    return DateTime.tryParse(value).toString();
  }

  if (value is DateTime) {
    return value.toString();
  }

  return "Time Error";
}

  Map<String,dynamic> toMap(){
    return {
      "senderId": senderId,
      "content": content,
      "createdAt": createdAt,
      "status": status,
      "deletedFor": deletedfor,
      "type":type
    };
  }
}