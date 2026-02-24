import 'package:chat_application/features/chats/domain/entities/conversation.dart';

class ConversationModel extends Conversation{
  

  ConversationModel({
    required super.convoId,
    required super.participantsId,
    required super.lastMessage,
    required super.lastupdateTime,
  });

  factory ConversationModel.fromJson(
    Map<String,dynamic> map,
    String id
  ){
    return ConversationModel(
      convoId: id,
      participantsId:
        List<String>.from(map['participantsId']),
      lastMessage: map['lastMessage'],
      lastupdateTime: map['lastupdateTime'].toDate().toString(),
    );
  }

  Map<String,dynamic> toMap(){
    return {
      "participantsId": participantsId,
      "lastMessage": lastMessage,
      "lastupdateTime": lastupdateTime,
    };
  }
}