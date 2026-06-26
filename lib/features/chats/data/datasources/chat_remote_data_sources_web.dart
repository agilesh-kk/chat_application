import 'dart:async';
import 'dart:convert';

import 'package:chat_application/core/common/entities/user.dart';
import 'package:chat_application/features/chats/data/datasources/timeline_service.dart';
import 'package:chat_application/features/chats/data/models/conversation_model.dart';
import 'package:chat_application/features/chats/data/models/message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
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
    try {
      final response = await supabase.rpc('fetch_conversation_messages', params: {
        'p_conversation_id': conversationId,
      });

      final List<dynamic> data = response as List<dynamic>;
      return data.map((msg) {
        final map = msg as Map<String, dynamic>;
        return {
          '_docId': map['id'],
          'senderId': map['sender_id'],
          'receiver_id': map['receiver_id'],
          'content': map['content'],
          'type': map['type'],
          'status': map['status'],
          'isEdited': map['is_edited'] ?? false,
          'reactions': map['reactions'] ?? {},
          'createdAt': map['created_at'] != null
              ? Timestamp.fromMillisecondsSinceEpoch(
                  _parseMillis(map['created_at']))
              : Timestamp.now(),
          'replyToId': map['reply_to_id'],
          'replyToContent': map['reply_to_content'],
          'replyToSenderId': map['reply_to_sender_id'],
          'replyToType': map['reply_to_type'],
          'deletedfor': map['deleted_for'] ?? [],
          'deletedForEveryone': map['deleted_for_everyone'] ?? false,
          'name': map['name'],
          'convoId': map['convo_id'],
          'profile': map['profile'],
          'isScheduled': map['is_scheduled'] ?? false,
          'sendAt': map['send_at'],
        };
      }).toList();
    } catch (e) {
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
  }

  int _parseMillis(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
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

    try {
      final msgIds = await supabase.rpc('get_sent_unseen_message_ids', params: {
        'p_convo_id': convoId,
        'p_sender_id': receiverId,
        'p_receiver_id': userId,
      });

      if (msgIds is List && msgIds.isNotEmpty) {
        await supabase.rpc('mark_messages_seen', params: {
          'p_convo_id': convoId,
          'p_user_id': userId,
          'p_receiver_id': receiverId,
        });
      }
    } catch (_) {
    }

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

      final updatedReactions = await supabase.rpc('toggle_message_reaction', params: {
        'p_convo_id': convoId,
        'p_message_id': messageId,
        'p_user_id': userId,
        'p_emoji': emoji,
        'p_receiver_id': receiverId,
      });

      final opCol = opCollection ?? _getMyOpCollection(userId, receiverId);
      final opRef = convoRef.collection(opCol).doc(messageId);

      await firestore.runTransaction((tx) async {
        final doc = await tx.get(convoRef.collection("messages").doc(messageId));
        if (!doc.exists) return;

        tx.set(opRef, {
          "type": "reaction",
          "messageId": messageId,
          "userId": userId,
          "emoji": emoji,
          "reactions": updatedReactions ?? {},
          "timestamp": FieldValue.serverTimestamp(),
        });
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
      final convoRef = firestore.collection("Conversations").doc(convoId);

      final opCol = opCollection ?? _getMyOpCollection(userId, receiverId);
      final opRef = convoRef
      .collection(opCol)
      .doc();

      await firestore.runTransaction((tx) async {
        final doc = await tx.get(convoRef.collection("messages").doc(msgId));
        if (!doc.exists) return;

        tx.set(opRef, {
          "type" : "edit_message",
          "messageId" : msgId,
          "senderId" : userId,
          "new_content" : newContent,
          "editedAt": FieldValue.serverTimestamp(),
          "timestamp": FieldValue.serverTimestamp(),
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
  }) async {
    try {
      final convoId = generateConversationId(userId, receiverId);
      final convoRef = firestore
          .collection("Conversations")
          .doc(convoId);

      final collectionName = sendAt != null ? "scheduled_messages" : "messages";
      final messageRef = convoRef.collection(collectionName).doc(msgId);
      final isScheduled = sendAt != null;
      final opColToUse = opCollection ?? _getMyOpCollection(userId, receiverId);
      final shouldWriteOp = !isScheduled;

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

      if (isScheduled) {
        batch.set(messageRef, {
          ...message.toMap(),
          "name": userName ?? "Unknown",
          "receiverId": receiverId,
          "convoId": convoId,
          "profile": userProfile ?? "assets/profile_images/pfp1.png",
          "createdAt": Timestamp.fromDate(sendAt),
          "index": null,
        });
      }

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
        final timelineService = TimelineService(firestore);

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

      await supabase.rpc('delete_message_and_update_conversation', params: {
        'p_convo_id': convoId,
        'p_user_id': userId,
        'p_receiver_id': receiverId,
        'p_deleted_message_id': msgId,
        'p_delete_for_everyone': true,
      });
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

  String _getMessagesTableName(String convoId) {
    final hash = md5.convert(utf8.encode(convoId)).toString();
    return 'msg_$hash';
  }

  @override
  Future<void> updateFriendStatus({
    required String convoId,
    required String userId,
    required String friendId,
    required bool isFriend,
  }) async {
    try {
      await supabase.rpc('update_conversation_friend_status', params: {
        'p_convo_id': convoId,
        'p_user_id': userId,
        'p_friend_id': friendId,
        'p_is_friend': isFriend,
      });
    } catch (e) {
      //print("Update friend status error: $e");
    }
  }
}
