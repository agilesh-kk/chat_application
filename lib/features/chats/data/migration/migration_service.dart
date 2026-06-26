import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

class MigrationService {
  final FirebaseFirestore firestore;
  final SupabaseClient supabase;

  MigrationService({required this.firestore, required this.supabase});

  Future<void> migrateAllData() async {
    final convoSnapshots = await firestore.collection("Conversations").get();

    int totalConvos = 0;
    int totalMessages = 0;

    for (final convoDoc in convoSnapshots.docs) {
      try {
        await _migrateConversation(convoDoc);
        totalConvos++;
        print("Migrated conversation: ${convoDoc.id}");
      } catch (e) {
        print("Error migrating conversation ${convoDoc.id}: $e");
      }

      try {
        final msgSnapshot = await convoDoc.reference
            .collection("messages")
            .orderBy("createdAt", descending: false)
            .get();

        for (final msgDoc in msgSnapshot.docs) {
          try {
            await _migrateMessage(convoDoc.id, msgDoc);
            totalMessages++;
          } catch (e) {
            print("Error migrating message ${msgDoc.id}: $e");
          }
        }
      } catch (e) {
        print("Error reading messages for ${convoDoc.id}: $e");
      }
    }

    print(
        "Migration complete: $totalConvos conversations, $totalMessages messages migrated.");
  }

  Future<void> _migrateConversation(
      DocumentSnapshot<Map<String, dynamic>> convoDoc) async {
    final data = convoDoc.data();
    if (data == null) return;

    final participantsId =
        (data['participants_id'] as List?)?.cast<String>() ??
            (data['participants'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
            [];

    if (participantsId.isEmpty) return;

    final userData = <String, dynamic>{};
    const metadataKeys = [
      'participants_id',
      'participants',
      'lastupdateTime',
      'lastMessage',
      'lastSender',
      'lastMessageId',
      'user_data'
    ];

    for (final key in data.keys) {
      if (!metadataKeys.contains(key)) {
        userData[key] = data[key];
      }
    }

    if (data['user_data'] is Map) {
      final existingUserData =
          Map<String, dynamic>.from(data['user_data'] as Map);
      existingUserData.forEach((key, value) {
        userData[key] = value;
      });
    }

    final lastUpdateTime = data['lastupdateTime'];
    String? lastUpdateTimeStr;
    if (lastUpdateTime is Timestamp) {
      lastUpdateTimeStr =
          lastUpdateTime.toDate().toUtc().toIso8601String();
    } else if (lastUpdateTime is String) {
      lastUpdateTimeStr = lastUpdateTime;
    }

    await supabase.rpc('migrate_conversation', params: {
      'p_id': convoDoc.id,
      'p_participants_id': participantsId,
      'p_last_update_time':
          lastUpdateTimeStr ?? DateTime.now().toUtc().toIso8601String(),
      'p_user_data': userData,
    });
  }

  Future<void> _migrateMessage(
      String convoId,
      DocumentSnapshot<Map<String, dynamic>> msgDoc) async {
    final data = msgDoc.data();
    if (data == null) return;

    final createdAt = data['createdAt'] as Timestamp?;
    final sendAt = data['sendAt'] as Timestamp?;

    await supabase.rpc('migrate_message', params: {
      'p_convo_id': convoId,
      'p_id': msgDoc.id,
      'p_sender_id': data['senderId'] ?? '',
      'p_content': data['content'],
      'p_type': data['type'] ?? 'text',
      'p_status': data['status'] ?? 'sent',
      'p_created_at': createdAt?.millisecondsSinceEpoch,
      'p_deleted_for': data['deletedfor'] ?? [],
      'p_deleted_for_everyone': data['deletedForEveryone'] ?? false,
      'p_is_edited': data['isEdited'] ?? false,
      'p_reactions': data['reactions'] is Map ? data['reactions'] : <String, dynamic>{},
      'p_reply_to_id': data['replyToId'],
      'p_reply_to_content': data['replyToContent'],
      'p_reply_to_sender_id': data['replyToSenderId'],
      'p_reply_to_type': data['replyToType'],
      'p_is_scheduled': data['isScheduled'] ?? false,
      'p_send_at': sendAt?.millisecondsSinceEpoch,
      'p_in_timeline': data['inTimeline'] ?? false,
      'p_name': data['name'],
      'p_receiver_id': data['receiverId'],
      'p_profile': data['profile'],
    });
  }
}
