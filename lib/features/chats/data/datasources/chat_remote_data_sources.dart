import 'dart:io';

import 'package:chat_application/core/common/entities/user.dart';
import 'package:chat_application/core/errors/exceptions.dart';
import 'package:chat_application/features/chats/data/models/conversation_model.dart';
import 'package:chat_application/features/chats/data/models/message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

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
    //bool? isScheduled,
  });

  Future<String> uploadImage({required File file, required String msgId});

  Future<Stream<List<MessageModel>>> getMessages({
    required String receiverId,
    required String userId,
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
  Future<Stream<List<MessageModel>>> getMessages({
    required String receiverId,
    required String userId,
  }) async {
    return firestore
        .collection("Conversations")
        .doc(generateConversationId(userId, receiverId))
        .collection("messages")
        .orderBy("createdAt", descending: true)
        .snapshots()
        .map((snapshot) {
          markMessagesDelivered(userId, receiverId);

          //filtering out the deleted for messages.
          return snapshot.docs
            .map((doc) => MessageModel.fromJson(doc.data(), doc.id))
            .where((msg) => !msg.deletedfor.contains(userId))
            .toList();
        });
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
    required File file,
    required String msgId,
  }) async {
    final path = "$msgId.jpg";

    await supabase.storage.from("images").upload(path, file);

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
    //bool? isScheduled,
  }) async {
    try {
      final convoRef = firestore
          .collection("Conversations")
          .doc(generateConversationId(userId, receiverId));

      //time capsule refactorings
      final collectionName = sendAt != null ? "scheduled_messages" : "messages";

      final messageRef = convoRef.collection(collectionName).doc(msgId);      

      final receiverDoc = firestore.collection("users").doc(receiverId);

      final receiverData = (await receiverDoc.get()).data()!;
      
      //this can't be null
      final isScheduled = sendAt != null;

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
        
      );

      WriteBatch batch = firestore.batch();

      //saving message, refactored for time capsule
      batch.set(messageRef, {
        ...message.toMap(),
        "createdAt": isScheduled
          ? Timestamp.fromDate(sendAt)
          : FieldValue.serverTimestamp(), // server sync later
        "index": null,
      });

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
        await processTimelineEvent(
          messageId: msgId,
          senderId: userId,
          receiverId: receiverId,
          type: type,
          content: content,
          createdAt: Timestamp.now(),
        );
      }
    } catch (e) {
      //print("Send message error: $e");
    }
  }

  String generateConversationId(String user1, String user2) {
    final sorted = [user1, user2]..sort();
    return "${sorted[0]}_${sorted[1]}";
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
      .where("name", isLessThanOrEqualTo: receiverName + '\uf8ff')
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

  Future<void> markMessagesDelivered(String userId, String receiverId) async {
    final convoRef = firestore
        .collection("Conversations")
        .doc(generateConversationId(userId, receiverId))
      ..update({"$userId.unread": 0});

    final snapshot = 
        await convoRef
            .collection("messages")
            .where("senderId", isEqualTo: receiverId)
            .where("status", isEqualTo: "sent")
            .get();

    final batch = firestore.batch();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {"status": "seen"});
    }
    await batch.commit();
  }
  
  @override
  Future<void> deleteMessage({
    required String msgId,
    required String userId,
    required String receiverId,
    bool deleteForEveryone = false,
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
      //batch.delete(docRef);
      batch.update(docRef, {
        //"isDeleted": true,
        "deletedForEveryone": true,
        //"content": "This message was deleted",
      });

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

  Future<void> processTimelineEvent({
    required String messageId,
    required String senderId,
    required String receiverId,
    required String type,
    required String content,
    required Timestamp createdAt,
  }) async {
    final convoId = generateConversationId(senderId, receiverId);

    final convoRef =
        firestore.collection("Conversations").doc(convoId);

    final rulesSnapshot = await firestore
        .collection("timeline_rules")
        .where("enabled", isEqualTo: true)
        .get();

    bool created = false;

    await firestore.runTransaction((transaction) async {

      // 🔥 PHASE 1: READ + CALCULATE COUNTS
      Map<String, int> counts = {};

      for (var ruleDoc in rulesSnapshot.docs) {
        final rule = ruleDoc.data();
        final ruleId = ruleDoc.id;
        final conditions = rule["conditions"] ?? {};

        final counterRef =
            convoRef.collection("rule_counters").doc(ruleId);

        final counterSnap = await transaction.get(counterRef);

        int count = 0;
        if (counterSnap.exists) {
          count = (counterSnap.data() as Map<String, dynamic>)["count"] ?? 0;
        }

        bool matches = true;

        // ✅ messageType filter BEFORE increment
        if (conditions.containsKey("messageType")) {
          if (type != conditions["messageType"]) {
            matches = false;
          }
        }

        // ✅ increment ONLY if matches
        if (matches) {
          count++;
        }

        counts[ruleId] = count;
      }

      // 🔥 PHASE 2: APPLY RULES + WRITE
      for (var ruleDoc in rulesSnapshot.docs) {
        final rule = ruleDoc.data();
        final ruleId = ruleDoc.id;
        final conditions = rule["conditions"] ?? {};

        int count = counts[ruleId]!;

        bool shouldCreate = true;

        // 🔹 messageType filter
        if (conditions.containsKey("messageType")) {
          if (type != conditions["messageType"]) {
            shouldCreate = false;
          }
        }

        // // 🔹 interval
        // if (conditions.containsKey("interval")) {
        //   final interval = conditions["interval"];
        //   if (count % interval != 0) {
        //     shouldCreate = false;
        //   }
        // }

        //adding milestones
        if (conditions.containsKey("milestones")) {
          final List milestones = conditions["milestones"];

          if (!milestones.contains(count)) {
            shouldCreate = false;
          }
        }

        // 🔹 occurrence
        if (conditions.containsKey("occurrence")) {
          final occurrence = conditions["occurrence"];
          if (count != occurrence) {
            shouldCreate = false;
          }
        }

        final counterRef =
            convoRef.collection("rule_counters").doc(ruleId);

        // ✅ ALWAYS update counter
        transaction.set(counterRef, {"count": count});

        if (!shouldCreate) continue;

        created = true;

        // 🔥 Create timeline event
        String title = rule["title"] ?? "";
        String eventContent = rule["content"] ?? content;

        title = title.replaceAll("{index}", count.toString());
        eventContent =
            eventContent.replaceAll("{index}", count.toString());

        final eventId = "${messageId}_$ruleId";

        final timelineRef =
            convoRef.collection("timeline").doc(eventId);

        transaction.set(timelineRef, {
          "id": eventId,
          "title": title,
          "content": eventContent,
          "type": type,
          "time": createdAt,
          "index": count,
          "messageId": messageId,
        });
      }
    });

    if (created) { // ✅ ADD
      final messageRef = firestore
          .collection("Conversations")
          .doc(convoId)
          .collection("messages")
          .doc(messageId);

      await messageRef.set(
        {"inTimeline": true},
        SetOptions(merge: true),
      );
    }
  }
}