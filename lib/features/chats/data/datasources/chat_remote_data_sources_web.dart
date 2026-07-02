import 'package:chat_application/core/common/entities/user.dart';
import 'package:chat_application/core/errors/exceptions.dart';
import 'package:chat_application/features/chats/data/datasources/timeline_service.dart';
import 'package:chat_application/features/chats/data/models/conversation_model.dart';
import 'package:chat_application/features/chats/data/models/message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import 'chat_remote_data_sources.dart';

class ChatRemoteDataSourcesWebImpl implements ChatRemoteDataSources {
  final FirebaseFirestore firestore;
  final SupabaseClient supabase;
  ChatRemoteDataSourcesWebImpl({required this.firestore, required this.supabase});

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
    int? limit,
  }) async {
    var query = firestore
        .collection("Conversations")
        .doc(generateConversationId(userId, receiverId))
        .collection("messages")
        .orderBy("createdAt", descending: true);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
        .map((doc) => MessageModel.fromJson(doc.data(), doc.id))
        .where((msg) => !msg.deletedfor.contains(userId))
        .toList();
    });
  }

  @override
  Future<List<MessageModel>> getOlderMessages({
    required String receiverId,
    required String userId,
    required DateTime oldestTimestamp,
    int limit = 50,
  }) async {
    final snapshot = await firestore
        .collection("Conversations")
        .doc(generateConversationId(userId, receiverId))
        .collection("messages")
        .orderBy("createdAt", descending: true)
        .startAfter([Timestamp.fromDate(oldestTimestamp)])
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => MessageModel.fromJson(doc.data(), doc.id))
        .where((msg) => !msg.deletedfor.contains(userId))
        .toList();
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
    required String receiverId,
    String? opCollection,
  }) async {
    final convoId = generateConversationId(userId, receiverId);
    final convoRef = firestore
        .collection("Conversations")
        .doc(convoId);

    final snapshot =
        await convoRef
            .collection("messages")
            .where("senderId", isEqualTo: receiverId)
            .where("status", isEqualTo: "sent")
            .get();

    if (snapshot.docs.isEmpty) {
      await convoRef.set({"$userId.unread": 0}, SetOptions(merge: true));
      return;
    }

    final batch = firestore.batch();

    batch.set(convoRef, {"$userId.unread": 0}, SetOptions(merge: true));

    final seenMsgIds = <String>[];
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {"status": "seen"});
      seenMsgIds.add(doc.id);
    }

    final opCol = opCollection ?? _getMyOpCollection(userId, receiverId);
    final opRef = convoRef.collection(opCol).doc();
    batch.set(opRef, {
      "type": "seen",
      "seenMsgIds": seenMsgIds,
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
              tx.update(convoRef, {
                "$receiverId.lastMessage": "Reacted $emoji to a message",
                "$receiverId.lastSender": userId,
              });
            } else {
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
    String? opCollection,
  }) async {
    try {
      final convoId = generateConversationId(userId, receiverId);
      final msgRef = firestore
          .collection("Conversations")
          .doc(convoId)
          .collection("messages")
          .doc(msgId);

      final convoRef = firestore.collection("Conversations").doc(convoId);

      final opCol = opCollection ?? _getMyOpCollection(userId, receiverId);
      final opRef = convoRef
      .collection(opCol)
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
    final bytes = await image.readAsBytes();
    await supabase.storage.from('images').uploadBinary(path, bytes);
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
    String? opCollection,
    bool isNewConvo = false,
  }) async {
    try {
      final convoId = generateConversationId(userId, receiverId);
      final convoRef = firestore
          .collection("Conversations")
          .doc(convoId);

      final collectionName = sendAt != null ? "scheduled_messages" : "messages";
      final messageRef = convoRef.collection(collectionName).doc(msgId);
      final isScheduled = sendAt != null;

      // Web always writes operation doc for non-scheduled messages (generate internally)
      final opColToUse = opCollection ?? _getMyOpCollection(userId, receiverId);
      final shouldWriteOp = !isScheduled;

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

      batch.set(messageRef, {
        ...message.toMap(),
        "name": userName ?? "Unknown",
        "receiverId": receiverId,
        "convoId": convoId,
        "profile": userProfile ?? "assets/profile_images/pfp1.png",
        "createdAt": isScheduled
          ? Timestamp.fromDate(sendAt)
          : FieldValue.serverTimestamp(),
        "index": null,
      });

      if (shouldWriteOp) {
        final opRef = convoRef.collection(opColToUse).doc(msgId);
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

      if (!isScheduled) {
        batch.set(convoRef, {
          "participantsId": [userId, receiverId],
          "lastupdateTime": FieldValue.serverTimestamp(),

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
      }

      if (isNewConvo) {
        final userRef = firestore.collection("users").doc(userId);
        final receiverRef = firestore.collection("users").doc(receiverId);

        batch.set(userRef, {
          "convoList": FieldValue.arrayUnion([convoId]),
        }, SetOptions(merge: true));

        batch.set(receiverRef, {
          "convoList": FieldValue.arrayUnion([convoId]),
        }, SetOptions(merge: true));
      }

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
        final timelineService = TimelineService(firestore, opCollection ?? _getMyOpCollection(userId, receiverId));

        await timelineService.handleMessage(
          messageId: msgId,
          senderId: userId,
          receiverId: receiverId,
          type: type,
          content: content,
          createdAt: Timestamp.now(),
        );
      }
    } catch (e) {
      //print("Web send message error: $e");
    }
  }

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

        // Write op doc for delete-for-me
        final opCol = opCollection ?? _getMyOpCollection(userId, receiverId);
        final opRef = convoRef.collection(opCol).doc(msgId);
        batch.set(opRef, {
          "type": "delete_message",
          "messageId": msgId,
          "timestamp": FieldValue.serverTimestamp(),
          "deletedfor": [userId],
          "deletedForEveryone": false,
          "performedBy": userId,
        });

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
      final opCol = opCollection ?? _getMyOpCollection(userId, receiverId);
      final opRef = convoRef.collection(opCol).doc(msgId);
      batch.set(opRef, {
        "type": "delete_message",
        "messageId": msgId,
        "timestamp": FieldValue.serverTimestamp(),
        "deletedfor": [],
        "deletedForEveryone": true,
        "performedBy": userId,
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

        if (isLastMessage) {
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
      //print("Web delete message error: $e");
    }
  }

  @override
  Future<Stream<Map<String, dynamic>>> listenToOperations({
    required String conversationId,
    required String opCollection,
    bool skipFirst = false,
  }) async {
    try{
    var query = firestore
        .collection("Conversations")
        .doc(conversationId)
        .collection(opCollection)
        .orderBy("timestamp", descending: true);

    return query.snapshots().map((snapshot) {
          final results = <Map<String, dynamic>>[];
          for (final change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data()!;
              data['_docId'] = change.doc.id;
              results.add(data);
            }
          }
          if (skipFirst && snapshot.docChanges.length == snapshot.docs.length) {
            return <Map<String, dynamic>>[];
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
      //print("Web delete operation error: $e");
    }
  }

  String generateConversationId(String user1, String user2) {
    final sorted = [user1, user2]..sort();
    return "${sorted[0]}_${sorted[1]}";
  }

  String _getMyOpCollection(String userId, String receiverId) {
    final sorted = [userId, receiverId]..sort();
    return sorted[0] == userId ? "operation_1" : "operation_2";
  }

  @override
  Future<List<String>> getUserConvoList(String userId) async {
    final doc = await firestore.collection('users').doc(userId).get();
    final data = doc.data();
    return List<String>.from(data?['convoList'] ?? []);
  }
}
