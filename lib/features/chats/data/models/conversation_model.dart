import 'package:chat_application/features/chats/domain/entities/conversation.dart';

class ConversationModel extends Conversation{
  

  ConversationModel({
    required super.unread,
    required super.convoId,
    required super.receiverId,
    required super.lastMessage,
    required super.lastupdateTime,
    required super.receiverName,
    required super.profilepicLink
  });

  factory ConversationModel.fromJson(
    Map<String,dynamic> map,
    String id,
    String userId
  ){
    final receiverDetails = map[userId];

    return ConversationModel(
      convoId: id,
      receiverId: receiverDetails["receiverId"],
      lastMessage: map['lastMessage'],
      lastupdateTime: map['lastupdateTime'].toDate().toString(),
      receiverName: receiverDetails["receiverName"] ?? "unknown",
      profilepicLink: receiverDetails["receiverProfile"] ?? "not found",
      unread: receiverDetails["unread"] ?? 0
    );
  }

  Map<String,dynamic> toMap(String userId){
    return {
      userId: {
        "receiverId" : receiverId,
        "receiverName" : receiverName,
        "receiverProfile" : profilepicLink,
        "unread" : unread
      },
      "lastMessage": lastMessage,
      "lastupdateTime": lastupdateTime,
    };
  }
}