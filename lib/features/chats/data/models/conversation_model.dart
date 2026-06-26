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

  factory ConversationModel.fromSupabaseRow(Map<String, dynamic> row, String userId) {
    final userData = row['user_data'] is Map
        ? Map<String, dynamic>.from(row['user_data'] as Map)
        : <String, dynamic>{};
    final myData = userData[userId] is Map
        ? Map<String, dynamic>.from(userData[userId] as Map)
        : <String, dynamic>{};

    final participants = (row['participants_id'] as List?)?.cast<String>() ?? [];
    final receiverId = (myData['receiverId']?.toString() ?? '').isEmpty
        ? participants.firstWhere((id) => id != userId, orElse: () => '')
        : myData['receiverId']?.toString() ?? '';

    final lastUpdateRaw = row['last_update_time'];
    final lastUpdateStr = lastUpdateRaw is int
        ? DateTime.fromMillisecondsSinceEpoch(lastUpdateRaw).toIso8601String()
        : lastUpdateRaw?.toString() ?? '';

    return ConversationModel(
      convoId: row['id'] as String? ?? '',
      receiverId: receiverId,
      lastMessage: myData['lastMessage']?.toString() ?? '',
      lastupdateTime: lastUpdateStr,
      receiverName: myData['receiverName']?.toString() ?? 'unknown',
      profilepicLink: myData['receiverProfile']?.toString() ?? '',
      unread: (myData['unread'] as num?)?.toInt() ?? 0,
      lastSender: myData['lastSender']?.toString() ?? '',
      isFriend: myData['isFriend'] as bool? ?? true,
    );
  }

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

  static Map<String, dynamic> toSupabaseRow({
    required String convoId,
    required List<String> participantsId,
    required Map<String, dynamic> userData,
    String? lastUpdateTime,
  }) {
    return {
      'id': convoId,
      'participants_id': participantsId,
      'last_update_time': lastUpdateTime,
      'user_data': userData,
    };
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
      "lastSender": lastSender,
    };
  }
}