import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chat_application/core/common/entities/user.dart';
import 'package:chat_application/core/errors/exceptions.dart';
import 'package:chat_application/features/achievement/services/achievement_details_mapper.dart';
import 'package:chat_application/features/chats/data/datasources/timeline_service.dart';
import 'package:chat_application/features/chats/data/models/conversation_model.dart';
import 'package:chat_application/features/chats/data/models/message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'dart:math';

// Re-export for backward compatibility
typedef LevelInfoMapper = AchievementDetailsMapper;

abstract interface class ChatRemoteDataSources {
  Future<Stream<List<ConversationModel>>> getConversations({
    required String userId,
  });

  Future<void> sendMessage({
    required String receiverId,
    required String userId,
    required String content,
    required String msgId,
    String type = "text",
    String? userName,
    String? userProfile,

    //time capsule features
    DateTime? sendAt, 

    //for reply
    String? replyToId,
    String? replyToContent,
    String? replyToSenderId,
    String? replyToType,

    //operation sync
    String? opCollection,

    bool isNewConvo = false,
  });

  Future<String> uploadImage({required XFile image, required String msgId});

  Future<List<Map<String, dynamic>>> fetchAllMessages({
    required String conversationId,
  });

  Future<Stream<List<MessageModel>>> getScheduledMessages({
    required String receiverId,
    required String userId,
  });

  Future<List<User>> searchUser({
    required String receiverName,
    required String currentUserId,
  });

  Future<void> deleteMessage({
    required String msgId,
    required String userId,
    required String receiverId,
    bool deleteForEveryone = false,
    String? opCollection,
  });

  Future markMessagesDelivered({
    required String userId, 
    required String receiverId
  });

  Future<void> toggleReaction({
    required String userId,
    required String receiverId,
    required String messageId,
    required String emoji,
    String? opCollection,
  });

  // Operation sync methods
  Future<Stream<Map<String, dynamic>>> listenToOperations({
    required String conversationId,
    required String opCollection,
    bool skipFirst = false
  });

  Future<void> deleteOperation({
    required String conversationId,
    required String opCollection,
    required String opId,
  });

  Future<void> editMessage({
    required String userId,
    required String receiverId,
    required String msgId,
    required String newContent,
    required String opCollection
  });

  Future<void> updateConversationFriendStatus({
    required String convoId,
    required String userId,
    required String friendId,
    required bool isFriend,
  });

  Future<List<String>> getUserConvoList(String userId);
}

class ChatRemoteDataSourcesImpl implements ChatRemoteDataSources {
  final FirebaseFirestore firestore;
  final SupabaseClient supabase;
  ChatRemoteDataSourcesImpl({required this.firestore, required this.supabase});

  @override
  Future<Stream<List<ConversationModel>>> getConversations({
    required String userId,
  }) async {
    return firestore
        .collection("Conversations")
        .where("participantsId", arrayContains: userId)
        .orderBy("lastupdateTime", descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            //print("🔥 SNAPSHOT TRIGGERED: ${snapshot.docs.length}");
            return ConversationModel.fromJson(doc.data(), doc.id, userId);
          }).toList();
        });
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAllMessages({
    required String conversationId,
  }) async {
    final result = await supabase.rpc('fetch_conversation_messages', params: {
      'p_convo_id': conversationId,
    });

    final messages = result as List<dynamic>;
    return messages.map((msg) {
      final m = msg as Map<String, dynamic>;
      return {
        'id': m['id'],
        'senderId': m['sender_id'],
        'content': m['content'],
        'type': m['type'],
        'status': m['status'],
        'createdAt': m['created_at'],
        'isEdited': m['is_edited'],
        'deletedfor': (m['deleted_for'] as List?)?.cast<String>() ?? <String>[],
        'deletedForEveryone': m['deleted_for_everyone'] ?? false,
        'reactions': (m['reactions'] as Map?)?.cast<String, dynamic>() ?? <String, dynamic>{},
        'replyToId': m['reply_to_id'],
        'replyToContent': m['reply_to_content'],
        'replyToSenderId': m['reply_to_sender_id'],
        'replyToType': m['reply_to_type'],
        'isScheduled': m['is_scheduled'] ?? false,
        'sendAt': m['send_at'],
        'inTimeline': m['in_timeline'] ?? false,
        'name': m['name'],
        'receiverId': m['receiver_id'],
        'profile': m['profile'],
        'convoId': conversationId,
        '_docId': m['id'],
      };
    }).toList();
  }

  @override
  Future<void> markMessagesDelivered({
    required String userId, 
    required String receiverId
  }) async {
    final convoId = generateConversationId(userId, receiverId);
    final convoRef = firestore
        .collection("Conversations")
        .doc(convoId)
      ..update({"$userId.unread": 0});

    final snapshot = 
        await convoRef
            .collection("messages")
            .where("senderId", isEqualTo: receiverId)
            .where("status", isEqualTo: "sent")
            .get();

    if (snapshot.docs.isEmpty) return;

    final batch = firestore.batch();

    final seenMsgIds = <String>[];
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {"status": "seen"});
      seenMsgIds.add(doc.id);
    }

    // Write seen operation
    final opCollection = _getMyOpCollection(userId, receiverId);
    final opRef = convoRef.collection(opCollection).doc();
    batch.set(opRef, {
      "type": "seen",
      "messageIds": seenMsgIds,
      "seenByUserId": userId,
      "timestamp": FieldValue.serverTimestamp(),
    });

    await batch.commit();

    await supabase.rpc('mark_messages_seen', params: {
      'p_convo_id': convoId,
      'p_user_id': userId,
      'p_receiver_id': receiverId,
    });
  }

  @override
  Future<void> toggleReaction({
    required String userId,
    required String receiverId,
    required String messageId,
    required String emoji,
    String? opCollection,
  }) async {
    try {
      final convoId = generateConversationId(userId, receiverId);
      final convoRef = firestore.collection("Conversations").doc(convoId);
      final msgRef = convoRef.collection("messages").doc(messageId);

      String? reactionPreview;
      String? reactionSender;

      await firestore.runTransaction((tx) async {
        try{
        final doc = await tx.get(msgRef);
        final convoDoc = await tx.get(convoRef);
        if (!doc.exists) return;

        final data = doc.data()!;
        final reactions = Map<String, dynamic>.from(data['reactions'] as Map? ?? {});
        final currentReaction = reactions[userId];
        final isAddOrChange = currentReaction != emoji;

        if (currentReaction == emoji) {
          reactions.remove(userId);
        } else {
          reactions[userId] = emoji;
        }
        tx.update(msgRef, {'reactions': reactions});

        if (convoDoc.exists) {
          final convoData = convoDoc.data()!;
          if (convoData[receiverId]?["lastMessageId"] == messageId) {
            if (isAddOrChange) {
              reactionPreview = "Reacted $emoji to a message";
              reactionSender = userId;
              tx.update(convoRef, {
                "$receiverId.lastMessage": reactionPreview,
                "$receiverId.lastSender": reactionSender,
              });
            } else {
              reactionPreview = convoData[userId]?["lastMessage"] ?? "";
              reactionSender = convoData[userId]?["lastSender"] ?? "";
              tx.update(convoRef, {
                "$receiverId.lastMessage": reactionPreview,
                "$receiverId.lastMessageId": convoData[userId]?["lastMessageId"] ?? "",
                "$receiverId.lastSender": reactionSender,
              });
            }
          }
        }

        if (opCollection != null) {
          final opRef = convoRef.collection(opCollection).doc(messageId);
          tx.set(opRef, {
            "type": "reaction",
            "messageId": messageId,
            "userId": userId,
            "emoji": emoji,
            "reactions": reactions,
            "timestamp": FieldValue.serverTimestamp(),
          });
        }
        }catch(e){
          //print(e);
        }
      });

      await supabase.rpc('toggle_message_reaction', params: {
        'p_convo_id': convoId,
        'p_message_id': messageId,
        'p_user_id': userId,
        'p_emoji': emoji,
        'p_receiver_id': receiverId,
      });
    } catch (e) {
      //print("Toggle reaction error: $e");
    }
  }

  @override
  Future<void> editMessage({
    required String userId,
    required String receiverId,
    required String msgId,
    required String newContent,
    required String opCollection
  }) async {
    try {
      final convoId = generateConversationId(userId, receiverId);
      final msgRef = firestore
          .collection("Conversations")
          .doc(convoId)
          .collection("messages")
          .doc(msgId);

      final convoRef = firestore.collection("Conversations").doc(convoId);

      final opRef = convoRef
      .collection(opCollection)
      .doc();

      await firestore.runTransaction((tx) async {
        final doc = await tx.get(msgRef);
        if (!doc.exists) return;

        tx.set(opRef, {
          "type" : "edit_message",
          "messageId" : msgId,
          "senderId" : userId,
          "new_content" : newContent,
          "editedAt": FieldValue.serverTimestamp(),
          "timestamp": FieldValue.serverTimestamp(),
        });

        tx.update(msgRef, {
          "content": newContent,
          "isEdited": true,
          "editedAt": FieldValue.serverTimestamp(),
        });
      });

      await supabase.from(_getMessagesTableName(convoId))
        .update({'content': newContent, 'is_edited': true})
        .eq('id', msgId);

      await supabase.rpc('edit_conversation_last_message', params: {
        'p_convo_id': convoId,
        'p_user_id': userId,
        'p_receiver_id': receiverId,
        'p_message_id': msgId,
        'p_new_content': newContent,
      });
    } catch (e) {
      //print("Edit message error: $e");
    }
    }

  @override
  Future<Stream<List<MessageModel>>> getScheduledMessages({
    required String receiverId,
    required String userId,
  }) async {
    return firestore
        .collection("Conversations")
        .doc(generateConversationId(userId, receiverId))
        .collection("scheduled_messages")
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snapshot) {
          //shows only the messages scheduled by the user.
          return snapshot.docs
            .map((doc) => MessageModel.fromJson(doc.data(), doc.id))
            .where((msg) => msg.senderId == userId && (!msg.deletedfor.contains(userId) && !msg.deletedForEveryone))
            .toList();
        });
  }

  @override
  Future<String> uploadImage({
    required XFile image,
    required String msgId,
  }) async {
    final path = "$msgId.jpg";
    if (kIsWeb) {
        final bytes = await image.readAsBytes();
        await supabase.storage.from('images').uploadBinary(path, bytes);
    }else{
        final file = File(image.path);
        await supabase.storage.from("images").upload(path, file);
    }
    return supabase.storage.from("images").getPublicUrl(path);
  }

  @override
  Future<void> sendMessage({
    required String userId,
    required String receiverId,
    required String msgId,
    String type = "text",
    required String content,
    String? userName,
    String? userProfile,
    DateTime? sendAt,
    String? replyToId,
    String? replyToContent,
    String? replyToSenderId,
    String? replyToType,

    //operation sync
    String? opCollection,

    bool isNewConvo = false,
  }) async {
    try {
      final convoId = generateConversationId(userId, receiverId);
      final convoRef = firestore
          .collection("Conversations")
          .doc(convoId);

      //time capsule refactorings
      final collectionName = sendAt != null ? "scheduled_messages" : "messages";

      final messageRef = convoRef.collection(collectionName).doc(msgId);      
      
      //this can't be null
      final isScheduled = sendAt != null;

      //skip operation for scheduled messages and when opCollection is not provided
      final shouldWriteOp = opCollection != null && !isScheduled;

      if (!isScheduled) {
        final senderDoc = await firestore.collection('users').doc(userId).get();
        final senderFriends = List<String>.from(senderDoc.data()?['friends'] ?? []);
        if (!senderFriends.contains(receiverId)) {
          throw ServerExceptions("You must be friends with this user to send messages");
        }
      }

      final message = MessageModel(
        id: msgId,
        type: type,
        status: isScheduled ? "scheduled" : "sent",
        senderId: userId,
        content: content,
        createdAt: isScheduled ? sendAt : DateTime.now(),
        deletedfor: [],
        sendAt: sendAt,
        isScheduled: isScheduled,
        replyToId: replyToId,
        replyToContent: replyToContent,
        replyToSenderId: replyToSenderId,
        replyToType: replyToType,
      );

      WriteBatch batch = firestore.batch();

      //saving message, refactored for time capsule
      batch.set(messageRef, {
        ...message.toMap(),
        "name": userName ?? "Unknown",
        "receiverId": receiverId,
        "convoId": convoId,
        "profile": userProfile ?? "assets/profile_images/pfp1.png",
        "createdAt": isScheduled
          ? Timestamp.fromDate(sendAt)
          : FieldValue.serverTimestamp(), // server sync later
        "index": null,
      });

      // Write operation doc in same batch (only for non-scheduled messages)
      if (shouldWriteOp) {
        final opRef = convoRef.collection(opCollection).doc(msgId);
        batch.set(opRef, {
          "type": "new_message",
          "messageId": msgId,
          "senderId": userId,
          "content": content,
          "messageType": type,
          "status": "sent",
          "receiverId": receiverId,
          "convoId": convoId,
          "name": userName ?? "Unknown",
          "profile": userProfile ?? "assets/profile_images/pfp1.png",
          "deletedfor": [],
          "deletedForEveryone": false,
          "reactions": {},
          "replyToId": replyToId,
          "replyToContent": replyToContent,
          "replyToSenderId": replyToSenderId,
          "replyToType": replyToType,
          "isScheduled": false,
          "inTimeline": false,
          "createdAt": FieldValue.serverTimestamp(),
          "timestamp": FieldValue.serverTimestamp(),
        });
      }

      // Updating conversation only if not scheduled
      if (!isScheduled) {
        batch.set(convoRef, {
          "participantsId": [userId, receiverId],

          // 🔥 ROOT (for sorting)
          "lastupdateTime": FieldValue.serverTimestamp(),

          //per-user conversation model
          userId: {
            "receiverId": receiverId,
            "unread": 0,

            "lastMessage": type == "text" ? content : "📷 Image",
            "lastMessageId": msgId,
            "lastSender": userId,
            "lastupdateTime": FieldValue.serverTimestamp(),
            "isFriend": true,
          },

          receiverId: {
            "receiverId": userId,
            "unread": FieldValue.increment(1),

            "lastMessage": type == "text" ? content : "📷 Image",
            "lastMessageId": msgId,
            "lastSender": userId,
            "lastupdateTime": FieldValue.serverTimestamp(),
            "isFriend": true,
          },
        }, SetOptions(merge: true));

        if (isNewConvo) {
          batch.set(firestore.collection('users').doc(userId), {
            'convoList': FieldValue.arrayUnion([convoId]),
          }, SetOptions(merge: true));
          batch.set(firestore.collection('users').doc(receiverId), {
            'convoList': FieldValue.arrayUnion([convoId]),
          }, SetOptions(merge: true));
        }
      }

      await batch.commit();

      if (!isScheduled) {
        final msgSupabase = message.toSupabaseMap();
        msgSupabase['name'] = userName ?? 'Unknown';
        msgSupabase['receiver_id'] = receiverId;
        msgSupabase['profile'] = userProfile ?? 'assets/profile_images/pfp1.png';

        final preview = type == 'text' ? content : '📷 Image';

        final sendParams = <String, dynamic>{
          'p_convo_id': convoId,
          'p_participants_id': [userId, receiverId],
          'p_user_id': userId,
          'p_last_message': preview,
          'p_last_message_id': msgId,
          'p_last_sender': userId,
          'p_is_friend': true,
        };
        for (final entry in msgSupabase.entries) {
          sendParams['p_${entry.key}'] = entry.value;
        }
        await supabase.rpc('send_message_and_update_conversation', params: sendParams);
      }

      if (!isScheduled) {
        try {
           await supabase.from('messages').insert({
            'chat_id': generateConversationId(userId, receiverId),
            'sender_id': userId,
            'receiver_id': receiverId,
            'name': userName ?? 'Unknown',
            'text': type == 'text' ? content : '📷 Photo',
            'sender_profile': userProfile
          }).select();
        } catch (_) {
        }
      }

      if (!isScheduled) {
        final timelineService = TimelineService(firestore,opCollection!);

        final inTimeline = await timelineService.handleMessage(
          messageId: msgId,
          senderId: userId,
          receiverId: receiverId,
          type: type,
          content: content,
          createdAt: Timestamp.now(),
        );

        if (inTimeline) {
          await supabase.rpc('update_message_timeline', params: {
            'p_convo_id': convoId,
            'p_message_id': msgId,
            'p_in_timeline': true,
          });
        }
      }

      // if (!isScheduled) {
      //   await _updateAchievementStats(
      //     userId: userId,
      //     receiverId: receiverId,
      //   );
      // }
    } catch (e) {
      rethrow;
    }
  }

  // Future<void> _updateAchievementStats({
  //   required String userId,
  //   required String receiverId,
  // }) async {
  //   final firestore = FirebaseFirestore.instance;

  //   final userRef = firestore
  //       .collection("users")
  //       .doc(userId)
  //       .collection("achievement")
  //       .doc("stats");

  //   final friendRef = firestore
  //       .collection("user_stats")
  //       .doc(userId)
  //       .collection("friends")
  //       .doc(receiverId);

  //   // =========================
  //   // 🔥 STEP 1: LIGHTWEIGHT INCREMENTS (NO READS)
  //   // =========================

  //   await Future.wait([
  //     userRef.set({
  //       "totalMessages": FieldValue.increment(1),
  //     }, SetOptions(merge: true)),

  //     friendRef.set({
  //       "messageCount": FieldValue.increment(1),
  //     }, SetOptions(merge: true)),
  //   ]);

  //   // =========================
  //   // 🔥 STEP 2: READ UPDATED VALUES (MINIMAL READ)
  //   // =========================

  //   final userSnap = await userRef.get();
  //   final friendSnap = await friendRef.get();

  //   final userData = userSnap.data() ?? {};
  //   final friendData = friendSnap.data() ?? {};

  //   final totalMessages = userData['totalMessages'] ?? 0;
  //   final messageCount = friendData['messageCount'] ?? 0;
  //   final wasQualified = friendData['isQualified'] ?? false;

  //   final isNowQualified = messageCount >= 5;
  //   final justQualified = !wasQualified && isNowQualified;

  //   // =========================
  //   // 🚫 LIMITER (VERY IMPORTANT)
  //   // =========================

  //   if (totalMessages % 5 != 0 && !justQualified) {
  //     // only update qualification flag if needed
  //     if (justQualified) {
  //       await friendRef.set({
  //         "isQualified": true,
  //       }, SetOptions(merge: true));
  //     }
  //     return;
  //   }

  //   // =========================
  //   // 🔥 STEP 3: HEAVY LOGIC (TRANSACTION)
  //   // =========================

  //   await firestore.runTransaction((tx) async {
  //     final userSnapTx = await tx.get(userRef);
  //     final friendSnapTx = await tx.get(friendRef);

  //     final userDataTx = userSnapTx.data() ?? {};
  //     final friendDataTx = friendSnapTx.data() ?? {};

  //     int totalMessages = userDataTx['totalMessages'] ?? 0;
  //     int qualifiedFriends = userDataTx['qualifiedFriends'] ?? 0;

  //     int messageCount = friendDataTx['messageCount'] ?? 0;
  //     bool wasQualified = friendDataTx['isQualified'] ?? false;

  //     bool isNowQualified = messageCount >= 5;

  //     // =========================
  //     // 📊 UPDATE FRIEND QUALIFICATION
  //     // =========================
  //     tx.set(friendRef, {
  //       "isQualified": isNowQualified,
  //     }, SetOptions(merge: true));

  //     if (!wasQualified && isNowQualified) {
  //       qualifiedFriends += 1;
  //     }

  //     // =========================
  //     // ⚙️ SCORE CALCULATION
  //     // =========================
  //     const mMax = 10000;
  //     const fMax = 100;

  //     final mNorm = log(1 + totalMessages) / log(1 + mMax);
  //     final fNorm = log(1 + qualifiedFriends) / log(1 + fMax);

  //     const wM = 0.75;
  //     const wF = 0.25;

  //     const targetPerFriend = 20;

  //     double engagement = 1.0;
  //     if (qualifiedFriends > 0) {
  //       engagement = totalMessages / (qualifiedFriends * targetPerFriend);
  //       if (engagement > 1) engagement = 1;
  //     }

  //     double score = (wM * mNorm) + (wF * fNorm * engagement);
  //     score = pow(score, 1.2).toDouble();

  //     final percentage = score * 100;

  //     // =========================
  //     // 🏆 LEVEL SYSTEM
  //     // =========================
  //     final levelInfo = LevelInfoMapper.getByPercentage(percentage);
  //     final level = levelInfo.name;

  //     // =========================
  //     // 🎯 UNLOCK SYSTEM
  //     // =========================
  //     final thresholds = {
  //       "ach_1": 0,
  //       "ach_2": 10,
  //       "ach_3": 25,
  //       "ach_4": 40,
  //       "ach_5": 60,
  //       "ach_6": 75,
  //       "ach_7": 90,
  //     };

  //     final unlocked = thresholds.entries
  //         .where((e) => percentage >= e.value)
  //         .map((e) => e.key)
  //         .toList();

  //     // =========================
  //     // 📝 FINAL UPDATE
  //     // =========================
  //     tx.set(userRef, {
  //       "qualifiedFriends": qualifiedFriends,
  //       "score": score,
  //       "percentage": percentage,
  //       "level": level,
  //       "unlocked": unlocked,
  //       "collected": userDataTx["collected"] ?? [],
  //       "seen": userDataTx["seen"] ?? [],
  //     }, SetOptions(merge: true));
  //   });
  // }

  String generateConversationId(String user1, String user2) {
    final sorted = [user1, user2]..sort();
    return "${sorted[0]}_${sorted[1]}";
  }

  String _getMyOpCollection(String userId, String receiverId) {
    final sorted = [userId, receiverId]..sort();
    return sorted[0] == userId ? "operation_1" : "operation_2";
  }

  String _getMessagesTableName(String convoId) {
    final hash = md5.convert(utf8.encode(convoId)).toString().substring(0, 16);
    return 'msg_$hash';
  }

  //refactored search user
  @override
  Future<List<User>> searchUser({
    required String receiverName,
    required String currentUserId,
  }) async {
    final result = await firestore
      .collection("users")
      .where("name", isGreaterThanOrEqualTo: receiverName)
      .where("name", isLessThanOrEqualTo: '$receiverName\uf8ff')
      .limit(10)
      //.where("id", isNotEqualTo: currentUserId)
      .get();

    return result.docs.map((doc) {
      final user = doc.data();

      return User(
        email: user["email"],
        name: user["name"],
        id: user["id"],
        birthDate: user["birthDate"] != null
            ? (user["birthDate"] as Timestamp).toDate()
            : DateTime.now(),
        profilePic: user['profilePic'],
        bio: user['bio'],
        gender: user['gender'],
      );
    })
    .where((user) => user.id != currentUserId)
    .toList();
  }

  
  @override
  Future<void> deleteMessage({
    required String msgId,
    required String userId,
    required String receiverId,
    bool deleteForEveryone = false,
    String? opCollection,
  }) async {
    try {
      final convoId = generateConversationId(userId, receiverId);

      final convoRef =
          firestore.collection("Conversations").doc(convoId);

      final messageRef =
          convoRef.collection("messages").doc(msgId);

      final scheduledRef =
          convoRef.collection("scheduled_messages").doc(msgId);

      final messageSnap = await messageRef.get();
      final scheduledSnap = await scheduledRef.get();

      final isMessage = messageSnap.exists;
      final isScheduled = scheduledSnap.exists;

      if (!isMessage && !isScheduled) return;

      final docRef = isMessage ? messageRef : scheduledRef;

      final batch = firestore.batch();

      // =========================================================
      // 🔵 DELETE FOR ME
      // =========================================================
      if (!deleteForEveryone) {
        batch.update(docRef, {
          "deletedfor": FieldValue.arrayUnion([userId]),
        });

        // Only normal messages affect conversation UI
        var isLastMessageD4Me = false;
        MessageModel? newLastD4Me;

        if (isMessage) {
          final convoSnap = await convoRef.get();
          if (!convoSnap.exists) {
            await batch.commit();
            return;
          }

          final convoData = convoSnap.data()!;

          isLastMessageD4Me =
              convoData[userId]?["lastMessageId"] == msgId;

          if (isLastMessageD4Me) {
            final messages = await convoRef
                .collection("messages")
                .orderBy("createdAt", descending: true)
                .get();

            for (final doc in messages.docs) {
              final msg =
                  MessageModel.fromJson(doc.data(), doc.id);

              if (!msg.deletedfor.contains(userId) &&
                  msg.id != msgId) {
                newLastD4Me = msg;
                break;
              }
            }

            if (newLastD4Me != null) {
              batch.update(convoRef, {
                "lastupdateTime": FieldValue.serverTimestamp(),
                "$userId.lastMessage":
                    newLastD4Me.type == "text"
                        ? newLastD4Me.content
                        : "📷Image",
                "$userId.lastMessageId": newLastD4Me.id,
                "$userId.lastSender": newLastD4Me.senderId,
                "$userId.lastupdateTime":
                    Timestamp.fromDate(newLastD4Me.createdAt),
              });
            } else {
              batch.update(convoRef, {
                "lastupdateTime": FieldValue.serverTimestamp(),
                "$userId.lastMessage": "",
                "$userId.lastMessageId": "",
                "$userId.lastSender": "",
                "$userId.lastupdateTime":
                    FieldValue.serverTimestamp(),
              });
            }
          }
        }

        await batch.commit();

        await supabase.rpc('delete_message_and_update_conversation', params: {
          'p_convo_id': convoId,
          'p_user_id': userId,
          'p_receiver_id': receiverId,
          'p_deleted_message_id': msgId,
          'p_delete_for_everyone': false,
        });
        return;
      }

      // =========================================================
      // 🔴 DELETE FOR EVERYONE
      // =========================================================
      batch.update(docRef, {
        "deletedForEveryone": true,
      });

      // Write operation doc
      if (opCollection != null) {
        final opRef = convoRef.collection(opCollection).doc(msgId);
        batch.set(opRef, {
          "type": "delete_message",
          "messageId": msgId,
          "timestamp": FieldValue.serverTimestamp(),
          "deletedfor": [],
          "deletedForEveryone": true,
          "performedBy": userId,
        });
      }

      var isLastMessageD4E = false;
      var isSenderD4E = false;
      var receiverUnreadD4E = 0;

      if (isMessage) {
        final convoSnap = await convoRef.get();
        if (!convoSnap.exists) {
          await batch.commit();
          return;
        }

        final convoData = convoSnap.data()!;
        final messageData = messageSnap.data()!;

        isLastMessageD4E =
            convoData[userId]?["lastMessageId"] == msgId ||
            convoData[receiverId]?["lastMessageId"] == msgId;

        if (isLastMessageD4E) {
          final messages = await convoRef
              .collection("messages")
              .orderBy("createdAt", descending: true)
              .get();

          MessageModel? lastForUser;
          MessageModel? lastForReceiver;

          for (final doc in messages.docs) {
            final msg = MessageModel.fromJson(doc.data(), doc.id);

            if (lastForUser == null &&
                !msg.deletedfor.contains(userId) &&
                msg.id != msgId) {
              lastForUser = msg;
            }

            if (lastForReceiver == null &&
                !msg.deletedfor.contains(receiverId) &&
                msg.id != msgId) {
              lastForReceiver = msg;
            }

            if (lastForUser != null && lastForReceiver != null) break;
          }

          batch.update(convoRef, {
            "lastupdateTime": FieldValue.serverTimestamp(),
            "$userId.lastMessage": "This message was deleted",
            "$userId.lastSender": messageData["senderId"],
            "$receiverId.lastMessage": "This message was deleted",
            "$receiverId.lastSender": messageData["senderId"],
          });
        }

        batch.update(convoRef, {
          "lastupdateTime": FieldValue.serverTimestamp(),
        });

        isSenderD4E = messageData["senderId"] == userId;
        receiverUnreadD4E =
            (convoData[receiverId]?["unread"] ?? 0);

        if (isSenderD4E && receiverUnreadD4E > 0) {
          batch.update(convoRef, {
            "$receiverId.unread":
                FieldValue.increment(-1),
          });
        }
      }

      await batch.commit();

      await supabase.rpc('delete_message_and_update_conversation', params: {
        'p_convo_id': convoId,
        'p_user_id': userId,
        'p_receiver_id': receiverId,
        'p_deleted_message_id': msgId,
        'p_delete_for_everyone': true,
      });
    } catch (e) {
      //print("Delete message error: $e");
    }
  }

  @override
  Future<Stream<Map<String, dynamic>>> listenToOperations({
    required String conversationId,
    required String opCollection,
    bool skipFirst = false
  }) async {
    try{
    return firestore
        .collection("Conversations")
        .doc(conversationId)
        .collection(opCollection)
        .orderBy("timestamp")
        .snapshots()
        .skip((skipFirst)?1:0)
        .map((snapshot) {
          final results = <Map<String, dynamic>>[];
          for (final change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data()!;
              data['_docId'] = change.doc.id;
              results.add(data);
            }
          }
          return results;
        })
        .where((ops) => ops.isNotEmpty)
        .expand((ops) => ops);
    }catch(e){
      //print(e);
      return Stream.empty();
    }
  }

  @override
  Future<void> deleteOperation({
    required String conversationId,
    required String opCollection,
    required String opId,
  }) async {
    try {
      await firestore
          .collection("Conversations")
          .doc(conversationId)
          .collection(opCollection)
          .doc(opId)
          .delete();
    } catch (e) {
      //print("Delete operation error: $e");
    }
  }

  @override
  Future<void> updateConversationFriendStatus({
    required String convoId,
    required String userId,
    required String friendId,
    required bool isFriend,
  }) async {
    try {
      await firestore.collection("Conversations").doc(convoId).update({
        '$userId.isFriend': isFriend,
        '$friendId.isFriend': isFriend,
      });
      await supabase.rpc('update_conversation_friend_status', params: {
        'p_convo_id': convoId,
        'p_user_id': userId,
        'p_friend_id': friendId,
        'p_is_friend': isFriend,
      });
    } catch (_) {}
  }

  @override
  Future<List<String>> getUserConvoList(String userId) async {
    final doc = await firestore.collection('users').doc(userId).get();
    final data = doc.data();
    return List<String>.from(data?['convoList'] ?? []);
  }
}