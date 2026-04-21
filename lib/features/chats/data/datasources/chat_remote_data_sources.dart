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
            .where((msg) => msg.senderId == userId)
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
          "lastMessage": (type == "text") ? content : "📷Image", 
          "lastMessageId": msgId, //adding the last message ID
          "lastupdateTime": FieldValue.serverTimestamp(),
          "lastSender": userId,

          // sender view
          userId: {
            "receiverId": receiverId,
            "receiverName": receiverData["name"] ?? "Unknown",
            "receiverProfile": receiverData["profilePic"] ?? "Not Found",
            "unread": 0,
          },

          // receiver view
          receiverId: {
            "receiverId": userId,
            "receiverName": userName ?? "Unknown",
            "receiverProfile": userProfile ?? "Not Found",
            "unread": FieldValue.increment(1),
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

      WriteBatch batch = firestore.batch();

      // 🔵 DELETE FOR ME (ONLY UPDATE THIS USER VIEW)
      if (!deleteForEveryone) {
        batch.update(docRef, {
          "deletedfor": FieldValue.arrayUnion([userId]),
        });

        await batch.commit();
        return; // 🚀 EXIT EARLY → no convo updates
      }

      // 🔴 DELETE FOR EVERYONE
      batch.delete(docRef);

      // ❗ Only handle conversation for NORMAL messages
      if (isMessage) {
        final convoSnap = await convoRef.get();

        if (!convoSnap.exists) {
          await batch.commit();
          return;
        }

        final convoData = convoSnap.data()!;
        final messageData = messageSnap.data()!;

        final isLastMessage =
            convoData["lastMessageId"] == msgId;

        // ✅ 1. Update conversation ONLY if latest message
        if (isLastMessage) {
          final prevMessages = await convoRef
              .collection("messages")
              .orderBy("createdAt", descending: true)
              .limit(2)
              .get();

          if (prevMessages.docs.length > 1) {
            final newLast = prevMessages.docs[1];

            batch.update(convoRef, {
              "lastMessage":
                  newLast["type"] == "text"
                      ? newLast["content"]
                      : "📷Image",
              "lastMessageId": newLast.id,
              "lastSender": newLast["senderId"],
              "lastupdateTime": newLast["createdAt"],
            });
          } else {
            // ❌ No messages left
            batch.update(convoRef, {
              "lastMessage": "",
              "lastMessageId": "",
              "lastSender": "",
              "lastupdateTime": FieldValue.serverTimestamp(),
            });
          }
        }

        // ✅ 2. FIX unread count (ONLY if needed)
        final isSender = messageData["senderId"] == userId;
        final receiverUnread =
            (convoData[receiverId]?["unread"] ?? 0);

        final isUnread = messageData["status"] != "seen";

        if (isSender && isUnread && receiverUnread > 0) {
          batch.update(convoRef, {
            "$receiverId.unread": FieldValue.increment(-1),
          });
        }
      }

      await batch.commit();
    } catch (e) {
      //print("Delete message error: $e");
    }
  }
}