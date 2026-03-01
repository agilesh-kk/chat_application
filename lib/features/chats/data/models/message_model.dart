import 'package:chat_application/features/chats/domain/entities/message.dart';

class MessageModel extends Message {

  MessageModel({
    required super.id,
    required super.senderId,
    required super.content,
    required super.createdAt,
    required super.deletedfor,
  });

  factory MessageModel.fromJson(
    Map<String,dynamic> map,
    String id
  ){
    return MessageModel(
      id: id,
      senderId: map['senderId'],
      content: map['content'],
      createdAt: (map['createdAt']).toDate().toString(),
      deletedfor:
        List<String>.from(map['deletedFor'] ?? []),
    );
  }

  Map<String,dynamic> toMap(){
    return {
      "senderId": senderId,
      "content": content,
      "createdAt": createdAt,
      "deletedFor": deletedfor,
    };
  }
}