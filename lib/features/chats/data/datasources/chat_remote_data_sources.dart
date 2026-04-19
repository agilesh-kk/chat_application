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
        .asyncMap((snapshot) async {
          final convoFutures = snapshot.docs.map((doc) async {
            final convoData = doc.data();
            final convoId = doc.id;

            // Find the correct last message for this user in parallel
            final lastMessageData = await _getLastVisibleMessageForUser(convoId, userId);
            final modifiedData = Map<String, dynamic>.from(convoData);

            if (lastMessageData != null) {
              modifiedData['lastMessage'] = (lastMessageData['type'] == 'text')
                  ? lastMessageData['content']
                  : '📷Image';
              modifiedData['lastupdateTime'] = lastMessageData['createdAt'];
              modifiedData['lastSender'] = lastMessageData['senderId'];
            }

            return ConversationModel.fromJson(modifiedData, convoId, userId);
          }).toList();

          return await Future.wait(convoFutures);
        });
  }

  Future<Map<String, dynamic>?> _getLastVisibleMessageForUser(String convoId, String userId) async {
    final convoRef = firestore.collection("Conversations").doc(convoId);

    final visibleMessage = await _findLastVisibleMessageInCollection(
      convoRef.collection("messages"),
      userId,
    );

    if (visibleMessage != null) {
      return visibleMessage;
    }

    return await _findLastVisibleMessageInCollection(
      convoRef.collection("scheduled_messages"),
      userId,
    );
  }

  Future<Map<String, dynamic>?> _findLastVisibleMessageInCollection(
    CollectionReference collection,
    String userId, {
    int batchSize = 20,
  }) async {
    Query query = collection.orderBy("createdAt", descending: true).limit(batchSize);
    while (true) {
      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) {
        return null;
      }

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final deletedFor = List<String>.from(data['deletedFor'] ?? []);
        if (!deletedFor.contains(userId)) {
          return data;
        }
      }

      if (snapshot.docs.length < batchSize) {
        return null;
      }

      final lastDoc = snapshot.docs.last;
      query = collection
          .orderBy("createdAt", descending: true)
          .startAfterDocument(lastDoc)
          .limit(batchSize);
    }
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
          //returns the messages which are not deleted for the user
          return snapshot.docs
              .where((doc) {
                final data = doc.data();
                final deletedFor = List<String>.from(data['deletedFor'] ?? []);
                return !deletedFor.contains(userId);
              })
              .map((doc) {
                return MessageModel.fromJson(doc.data(), doc.id);
              }).toList();
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
          markMessagesDelivered(userId, receiverId);
          //returns the messages which are not deleted for the user
          return snapshot.docs
              .where((doc) {
                final data = doc.data();
                final deletedFor = List<String>.from(data['deletedFor'] ?? []);
                return !deletedFor.contains(userId);
              })
              .map((doc) {
                return MessageModel.fromJson(doc.data(), doc.id);
              }).toList();
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
          "lastupdateTime": FieldValue.serverTimestamp(),
          "lastSender": userId, //updates which user sends the last message

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
  
  //deleting message
  @override
  Future<void> deleteMessage({
    required String msgId,
    required String userId,
    required String receiverId,
    bool deleteForEveryone = false,
  }) async {
    try {
      final convoId = generateConversationId(userId, receiverId);
      final convoRef = firestore.collection("Conversations").doc(convoId);

      // Try regular messages first
      final messageRef = convoRef.collection("messages").doc(msgId);
      final messageDoc = await messageRef.get();
      final scheduledRef = convoRef.collection("scheduled_messages").doc(msgId);
      final scheduledDoc = await scheduledRef.get();

      if (messageDoc.exists) {
        if (deleteForEveryone) {
          await messageRef.delete();
          await _updateLastMessageAfterDeletion(convoRef, userId, receiverId);
        } else {
          await messageRef.update({
            "deletedFor": FieldValue.arrayUnion([userId]),
          });
          // For soft delete, update counter to trigger conversation refresh without changing order
          await convoRef.update({
            "softDeleteCount": FieldValue.increment(1),
          });
        }
      } else if (scheduledDoc.exists) {
        if (deleteForEveryone) {
          await scheduledRef.delete();
          await _updateLastMessageAfterDeletion(convoRef, userId, receiverId);
        } else {
          await scheduledRef.update({
            "deletedFor": FieldValue.arrayUnion([userId]),
          });
          // For soft delete, update counter to trigger conversation refresh without changing order
          await convoRef.update({
            "softDeleteCount": FieldValue.increment(1),
          });
        }
      } else {
        throw ServerExceptions("Message not found");
      }
    } catch (e) {
      throw ServerExceptions(e.toString());
    }
  }

  Future<void> _updateLastMessageAfterDeletion(
    DocumentReference convoRef,
    String userId,
    String receiverId,
  ) async {
    try {
      // Get the most recent message from regular messages
      final messagesQuery = await convoRef
          .collection("messages")
          .orderBy("createdAt", descending: true)
          .limit(1)
          .get();

      MessageModel? lastMessage;

      if (messagesQuery.docs.isNotEmpty) {
        final doc = messagesQuery.docs.first;
        lastMessage = MessageModel.fromJson(doc.data(), doc.id);
      } else {
        // If no regular messages, check scheduled messages
        final scheduledQuery = await convoRef
            .collection("scheduled_messages")
            .orderBy("createdAt", descending: true)
            .limit(1)
            .get();

        if (scheduledQuery.docs.isNotEmpty) {
          final doc = scheduledQuery.docs.first;
          lastMessage = MessageModel.fromJson(doc.data(), doc.id);
        }
      }

      if (lastMessage != null) {
        // Update only the last message related fields
        await convoRef.update({
          "lastMessage": (lastMessage.type == "text") ? lastMessage.content : "📷Image",
          "lastupdateTime": Timestamp.fromDate(lastMessage.createdAt),
          "lastSender": lastMessage.senderId,
        });
      } else {
        // No messages left, we could clear the last message
        await convoRef.update({
          "lastMessage": "",
          "lastupdateTime": FieldValue.serverTimestamp(),
          "lastSender": "",
        });
      }
    } catch (e) {
      // Don't throw here, just log the error
      //print("Error updating last message: $e");
    }
  }
}
