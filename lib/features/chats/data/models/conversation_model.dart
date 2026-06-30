import 'package:chat_application/features/chats/domain/entities/conversation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationModel extends Conversation {

  ConversationModel({
    required super.unread,
    required super.convoId,
    required super.receiverId,
    required super.lastMessage,
    required super.lastupdateTime,
    required super.receiverName,
    required super.profilepicLink,
    required super.lastSender,
    super.isFriend,
  });

  factory ConversationModel.fromJson(
    Map<String, dynamic> map,
    String id,
    String userId,
  ) {
    final userData = map[userId] ?? {};

    return ConversationModel(
      convoId: id,
      receiverId: userData["receiverId"] ?? "",
      lastMessage: userData["lastMessage"] ?? "",
      lastupdateTime:
          _parseLastUpdateTime(userData["lastupdateTime"]),
      receiverName: userData["receiverName"] ?? "unknown",
      profilepicLink: userData["receiverProfile"] ?? "",
      unread: userData["unread"] ?? 0,
      lastSender: userData["lastSender"] ?? "",
      isFriend: userData["isFriend"] ?? true,
    );
  }

  static String _parseLastUpdateTime(dynamic raw) {
    if (raw == null) {
      return "";
    }

    if (raw is String && raw.isNotEmpty) {
      return raw;
    }

    if (raw is Timestamp) {
      return raw.toDate().toString();
    }

    try {
      return raw.toString();
    } catch (_) {
      return "";
    }
  }

  Map<String,dynamic> toMap(String userId){
    return {
      userId: {
        "receiverId" : receiverId,
        "receiverName" : receiverName,
        "receiverProfile" : profilepicLink,
        "unread" : unread,
        "isFriend" : isFriend,
      },
      "lastMessage": lastMessage,
      "lastupdateTime": lastupdateTime,
      "lastSender": lastSender,
    };
  }
}