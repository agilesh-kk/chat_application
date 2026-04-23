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

  Future<User?> searchUser({required String receiverName});

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
            "receiverName": receiverData["name"],
            "receiverProfile": receiverData["profilePic"],
            "unread": 0,

            // ✅ per-user last message
            "lastMessage": type == "text" ? content : "📷 Image",
            "lastMessageId": msgId,
            "lastSender": userId,
            "lastupdateTime": FieldValue.serverTimestamp(),
          },

          receiverId: {
            "receiverId": userId,
            "receiverName": userName,
            "receiverProfile": userProfile,
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
    } catch (e) {
      //print("Send message error: $e");
    }
  }

  String generateConversationId(String user1, String user2) {
    final sorted = [user1, user2]..sort();
    return "${sorted[0]}_${sorted[1]}";
  }

  @override
  Future<User?> searchUser({required String receiverName}) async {
    final result =
        await firestore
            .collection("users")
            .where("name", isEqualTo: receiverName)
            .get();

    if (result.size > 0) {
      final user = result.docs[0].data();
      if (user.isNotEmpty) {
        return User(
          email: user["email"],
          name: user["name"],
          id: user["id"],
          birthDate:
              user["birthDate"] != null
                  ? (user["birthDate"] as Timestamp).toDate()
                  : DateTime.now(),
          profilePic: user['profilePic'],
          bio: user['bio'],
          gender: user['gender'],
        );
      }
    }

    throw ServerExceptions("User Not Found");
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
}