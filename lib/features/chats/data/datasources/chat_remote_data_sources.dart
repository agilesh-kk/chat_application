import 'dart:io';

import 'package:chat_application/core/common/entities/user.dart';
import 'package:chat_application/features/achievement/services/achievement_details_mapper.dart';
import 'package:chat_application/features/chats/data/datasources/timeline_service.dart';
import 'package:chat_application/features/chats/data/models/conversation_model.dart';
import 'package:chat_application/features/chats/data/models/message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    final snapshot = await firestore
        .collection("Conversations")
        .doc(conversationId)
        .collection("messages")
        .orderBy("createdAt", descending: true)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['_docId'] = doc.id;
      return data;
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

      await firestore.runTransaction((tx) async {
        final doc = await tx.get(msgRef);
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

        // Only update receiver's conversation preview
        // and only if the reacted message is their current lastMessageId
        final convoDoc = await tx.get(convoRef);
        if (convoDoc.exists) {
          final convoData = convoDoc.data()!;
          if (convoData[receiverId]?["lastMessageId"] == messageId) {
            if (isAddOrChange) {
              tx.update(convoRef, {
                "$receiverId.lastMessage": "Reacted $emoji to a message",
                "$receiverId.lastSender": userId,
              });
            } else {
              // Removal: restore receiver's fields from reactor's (userId) fields
              final lastMessage = convoData[userId]?["lastMessage"] ?? "";
              final lastMessageId = convoData[userId]?["lastMessageId"] ?? "";
              final lastSender = convoData[userId]?["lastSender"] ?? "";
              tx.update(convoRef, {
                "$receiverId.lastMessage": lastMessage,
                "$receiverId.lastMessageId": lastMessageId,
                "$receiverId.lastSender": lastSender,
              });
            }
          }
        }

        // Write operation doc in same transaction with full reactions map
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

        final convoDoc = await tx.get(convoRef);

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

        if (convoDoc.exists) {
          final convoData = convoDoc.data()!;
          final isLastMessage =
              convoData[userId]?["lastMessageId"] == msgId ||
              convoData[receiverId]?["lastMessageId"] == msgId;

          if (isLastMessage) {
            tx.update(convoRef, {
              "$userId.lastMessage": newContent,
              "$receiverId.lastMessage": newContent,
              "lastupdateTime": FieldValue.serverTimestamp(),
            });
          }
        }
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
            //"receiverName": receiverData["name"],
            //"receiverProfile": receiverData["profilePic"],
            "unread": 0,

            // ✅ per-user last message
            "lastMessage": type == "text" ? content : "📷 Image",
            "lastMessageId": msgId,
            "lastSender": userId,
            "lastupdateTime": FieldValue.serverTimestamp(),
          },

          receiverId: {
            "receiverId": userId,
            //"receiverName": userName,
            //"receiverProfile": userProfile,
            "unread": FieldValue.increment(1),

            "lastMessage": type == "text" ? content : "📷 Image",
            "lastMessageId": msgId,
            "lastSender": userId,
            "lastupdateTime": FieldValue.serverTimestamp(),
          },
        }, SetOptions(merge: true));
      }

      final userRef = firestore.collection("users").doc(userId);
      final receiverRef = firestore.collection("users").doc(receiverId);

      batch.set(userRef, {
        "friends": FieldValue.arrayUnion([receiverId]),
      }, SetOptions(merge: true));

      batch.set(receiverRef, {
        "friends": FieldValue.arrayUnion([userId]),
      }, SetOptions(merge: true));

      await batch.commit();

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
        // await processTimelineEvent(
        //   messageId: msgId,
        //   senderId: userId,
        //   receiverId: receiverId,
        //   type: type,
        //   content: content,
        //   createdAt: Timestamp.now(),
        // );

        final timelineService = TimelineService(firestore,opCollection!);

        await timelineService.handleMessage(
          messageId: msgId,
          senderId: userId,
          receiverId: receiverId,
          type: type,
          content: content,
          createdAt: Timestamp.now(),
        );
      }

      // if (!isScheduled) {
      //   await _updateAchievementStats(
      //     userId: userId,
      //     receiverId: receiverId,
      //   );
      // }
    } catch (e) {
      //print("Send message error: $e");
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
        if (isMessage) {
          final convoSnap = await convoRef.get();
          if (!convoSnap.exists) {
            await batch.commit();
            return;
          }

          final convoData = convoSnap.data()!;

          final isLastMessage =
              convoData[userId]?["lastMessageId"] == msgId;

          if (isLastMessage) {
            final messages = await convoRef
                .collection("messages")
                .orderBy("createdAt", descending: true)
                .get();

            MessageModel? newLast;

            for (final doc in messages.docs) {
              final msg =
                  MessageModel.fromJson(doc.data(), doc.id);

              if (!msg.deletedfor.contains(userId) &&
                  msg.id != msgId) {
                newLast = msg;
                break;
              }
            }

            if (newLast != null) {
              batch.update(convoRef, {
                "lastupdateTime": FieldValue.serverTimestamp(),
                "$userId.lastMessage":
                    newLast.type == "text"
                        ? newLast.content
                        : "📷Image",
                "$userId.lastMessageId": newLast.id,
                "$userId.lastSender": newLast.senderId,
                "$userId.lastupdateTime":
                    Timestamp.fromDate(newLast.createdAt),
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
          "deletedfor": [userId, receiverId],
          "deletedForEveryone": true,
          "performedBy": userId,
        });
      }

      if (isMessage) {
        final convoSnap = await convoRef.get();
        if (!convoSnap.exists) {
          await batch.commit();
          return;
        }

        final convoData = convoSnap.data()!;
        final messageData = messageSnap.data()!;

        final isLastMessage =
            convoData[userId]?["lastMessageId"] == msgId ||
            convoData[receiverId]?["lastMessageId"] == msgId;

        // ✅ Update last message for BOTH users
        if (isLastMessage) {
          final messages = await convoRef
              .collection("messages")
              .orderBy("createdAt", descending: true)
              .get();

          MessageModel? lastForUser;
          MessageModel? lastForReceiver;

          for (final doc in messages.docs) {
            final msg = MessageModel.fromJson(doc.data(), doc.id);

            // 🔵 For current user
            if (lastForUser == null &&
                !msg.deletedfor.contains(userId) &&
                msg.id != msgId) {
              lastForUser = msg;
            }

            // 🔴 For receiver
            if (lastForReceiver == null &&
                !msg.deletedfor.contains(receiverId) &&
                msg.id != msgId) {
              lastForReceiver = msg;
            }

            if (lastForUser != null && lastForReceiver != null) break;
          }

          // 🔥 Update conversation correctly
          batch.update(convoRef, {
            "lastupdateTime": FieldValue.serverTimestamp(),

            //these codes are before adding deletedForEveryone field
            // // 🔵 USER VIEW
            // "$userId.lastMessage":
            //     lastForUser != null
            //         ? (lastForUser.type == "text"
            //             ? lastForUser.content
            //             : "📷Image")
            //         : "",
            // "$userId.lastMessageId": lastForUser?.id ?? "",
            // "$userId.lastSender": lastForUser?.senderId ?? "",
            // "$userId.lastupdateTime":
            //     lastForUser != null
            //         ? Timestamp.fromDate(lastForUser.createdAt)
            //         : FieldValue.serverTimestamp(),

            // // 🔴 RECEIVER VIEW
            // "$receiverId.lastMessage":
            //     lastForReceiver != null
            //         ? (lastForReceiver.type == "text"
            //             ? lastForReceiver.content
            //             : "📷Image")
            //         : "",
            // "$receiverId.lastMessageId": lastForReceiver?.id ?? "",
            // "$receiverId.lastSender": lastForReceiver?.senderId ?? "",
            // "$receiverId.lastupdateTime":
            //     lastForReceiver != null
            //         ? Timestamp.fromDate(lastForReceiver.createdAt)
            //         : FieldValue.serverTimestamp(),

            //after adding deletedForEveryone field
            "$userId.lastMessage": "This message was deleted",
            "$userId.lastSender": messageData["senderId"],

            "$receiverId.lastMessage": "This message was deleted",
            "$receiverId.lastSender": messageData["senderId"],
          });
        }

        // 🔥 ADD THIS BLOCK HERE
        batch.update(convoRef, {
          "lastupdateTime": FieldValue.serverTimestamp(),
        });

        // ✅ Fix unread count safely
        final isSender = messageData["senderId"] == userId;
        final receiverUnread =
            (convoData[receiverId]?["unread"] ?? 0);

        if (isSender && receiverUnread > 0) {
          batch.update(convoRef, {
            "$receiverId.unread":
                FieldValue.increment(-1),
          });
        }
      }

      await batch.commit();
    } catch (e) {
      //print("Delete message error: $e");
    }
  }

  @override
  Future<Stream<Map<String, dynamic>>> listenToOperations({
    required String conversationId,
    required String opCollection,
  }) async {
    try{
    return firestore
        .collection("Conversations")
        .doc(conversationId)
        .collection(opCollection)
        .orderBy("timestamp", descending: true)
        .snapshots()
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
      print(e);
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
}