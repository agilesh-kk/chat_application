import 'package:chat_application/features/chats/domain/entities/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MessageModel extends Message {

  MessageModel({
    required super.id,
    required super.senderId,
    required super.content,
    required super.createdAt,
    required super.deletedfor,
    super.deletedForEveryone,
    required super.status,
    super.type,
    super.isLocal,
    super.sendAt,
    super.isScheduled,
    super.inTimeline,
    super.isEdited,
    super.reactions,
    super.replyToId,
    super.replyToContent,
    super.replyToSenderId,
    super.replyToType,
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
      createdAt: map['createdAt'] != null
        ? (map['createdAt'] as Timestamp).toDate()
        : DateTime.now(),
      deletedForEveryone: map['deletedForEveryone'] ?? false,
      type: map['type'] ?? "text",
      deletedfor: List<String>.from(map['deletedfor'] ?? []),
      sendAt: map['sendAt'] != null
        ? (map['sendAt'] as Timestamp).toDate()
        : null,
      isScheduled: map['isScheduled'] ?? false,
      inTimeline: map["inTimeline"] ?? false,
      isEdited: map['isEdited'] ?? false,
      reactions: map["reactions"] is Map
          ? Map<String, String>.from(map["reactions"] as Map)
          : {},
      replyToId: map['replyToId'],
      replyToContent: map['replyToContent'],
      replyToSenderId: map['replyToSenderId'],
      replyToType: map['replyToType'],
    );
  }

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> data = {
      "senderId": senderId,
      "content": content,
      "createdAt": Timestamp.fromDate(createdAt),
      "status": status,
      "deletedfor": deletedfor,
      "deletedForEveryone": deletedForEveryone ?? false,
      "type": type,
      "isScheduled": sendAt != null,
      "inTimeline": inTimeline,
      "isEdited": isEdited,
      "reactions": reactions,
    };

    if (sendAt != null) {
      data["sendAt"] = Timestamp.fromDate(sendAt!);
    }

    if (replyToId != null) {
      data["replyToId"] = replyToId;
      data["replyToContent"] = replyToContent;
      data["replyToSenderId"] = replyToSenderId;
      data["replyToType"] = replyToType;
    }

    return data;
  }
}