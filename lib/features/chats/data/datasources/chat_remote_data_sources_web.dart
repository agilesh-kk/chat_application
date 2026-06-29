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
    final controller = StreamController<List<ConversationModel>>();

    Future<void> fetchAndEmit() async {
      try {
        final raw = await supabase.rpc('get_conversations_for_user', params: {
          'p_user_id': userId,
        });
        final rows = (raw as List).cast<Map<String, dynamic>>();
        final convos = rows
            .map((r) => ConversationModel.fromSupabaseRow(r, userId))
            .toList();
        if (!controller.isClosed) controller.add(convos);
      } catch (e) {
        print("getConversations error: $e");
        if (!controller.isClosed) controller.add([]);
      }
    }

    await fetchAndEmit();

    final channel = supabase.channel('conversations');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'conversations',
      callback: (_) => fetchAndEmit(),
    ).subscribe((status, error) {
      if (error != null) print("Realtime error (conversations): $error");
    });

    controller.onCancel = () => channel.unsubscribe();

    return controller.stream;
  }

  @override
  Future<Stream<List<MessageModel>>> getMessages({
    required String receiverId,
    required String userId,
    int? limit,
  }) async {
    print("fetching messages");
    final convoId = generateConversationId(userId, receiverId);
    final controller = StreamController<List<MessageModel>>();

    Future<void> fetchAndEmit() async {
      try {
        final raw = await supabase.rpc('fetch_conversation_messages', params: {
          'p_convo_id': convoId,
        });
        final rows = (raw as List).cast<Map<String, dynamic>>();
        final msgs = <MessageModel>[];
        for (final m in rows) {
          try {
            final msg = MessageModel.fromJson(
                _transformMessageRow(m), m['id'] as String);
            if (!msg.deletedfor.contains(userId)) {
              msgs.add(msg);
            }
          } catch (e) {
            print("Skipping bad message row: $e");
          }
        }
        if (limit != null && msgs.length > limit) {
          msgs.removeRange(limit, msgs.length);
        }
        if (!controller.isClosed) controller.add(msgs);
      } catch (e) {
        print("getMessages error: $e");
        if (!controller.isClosed) controller.add([]);
      }
    }

    await fetchAndEmit();

    final channel = supabase.channel('messages_$convoId');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'conversations',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'id',
        value: convoId,
      ),
      callback: (_) => fetchAndEmit(),
    ).subscribe((status, error) {
      if (error != null) print("Realtime error (messages): $error");
    });

    controller.onCancel = () => channel.unsubscribe();

    return controller.stream;
  }

  @override
  Future<List<MessageModel>> getOlderMessages({
    required String receiverId,
    required String userId,
    required DateTime oldestTimestamp,
    int limit = 50,
  }) async {
    print("get older messages");
    final convoId = generateConversationId(userId, receiverId);
    try {
      final raw = await supabase.rpc('fetch_conversation_messages', params: {
        'p_convo_id': convoId,
      });
      final rows = (raw as List).cast<Map<String, dynamic>>();
      return rows
          .map((m) => MessageModel.fromJson(
              _transformMessageRow(m), m['id'] as String))
          .where((msg) => !msg.deletedfor.contains(userId))
          .where((msg) => msg.createdAt.isBefore(oldestTimestamp))
          .take(limit)
          .toList();
    } catch (e) {
      print("getOlderMessages error: $e");
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchAllMessages({
    required String conversationId,
  }) async {
    try {
      final response = await supabase.rpc('fetch_conversation_messages', params: {
        'p_convo_id': conversationId,
      });

      print("fetching all messages");

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

  Map<String, dynamic> _transformMessageRow(Map<String, dynamic> m) {
    return {
      'senderId': m['sender_id'],
      'content': m['content'],
      'type': m['type'],
      'status': m['status'],
      'isEdited': m['is_edited'] ?? false,
      'reactions': m['reactions'] is Map
          ? Map<String, dynamic>.from(m['reactions'] as Map)
          : <String, dynamic>{},
      'createdAt': m['created_at'] != null
          ? Timestamp.fromMillisecondsSinceEpoch(_parseMillis(m['created_at']))
          : Timestamp.now(),
      'replyToId': m['reply_to_id'],
      'replyToContent': m['reply_to_content'],
      'replyToSenderId': m['reply_to_sender_id'],
      'replyToType': m['reply_to_type'],
      'deletedfor': (m['deleted_for'] as List?)?.cast<String>() ?? <String>[],
      'deletedForEveryone': m['deleted_for_everyone'] ?? false,
      'isScheduled': m['is_scheduled'] ?? false,
      'sendAt': m['send_at'] != null
          ? Timestamp.fromMillisecondsSinceEpoch(_parseMillis(m['send_at']))
          : null,
      'inTimeline': m['in_timeline'] ?? false,
    };
  }

  @override
  Future<void> markMessagesDelivered({
    required String userId, 
    required String receiverId
  }) async {
    final convoId = generateConversationId(userId, receiverId);
    final convoRef = firestore.collection("Conversations").doc(convoId);

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

      final opCollection = _getMyOpCollection(userId, receiverId);
      final opRef = convoRef.collection(opCollection).doc();
      await opRef.set({
        "type": "seen",
        "messageIds": msgIds is List
            ? List<String>.from(msgIds.map((e) => e.toString()))
            : <String>[],
        "seenByUserId": userId,
        "timestamp": FieldValue.serverTimestamp(),
      });
    } catch (_) {
    }
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

      await opRef.set({
        "type": "reaction",
        "messageId": messageId,
        "userId": userId,
        "emoji": emoji,
        "reactions": updatedReactions ?? {},
        "timestamp": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Toggle reaction error: $e");
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
      final opRef = convoRef.collection(opCol).doc();
      await opRef.set({
        "type": "edit_message",
        "messageId": msgId,
        "senderId": userId,
        "new_content": newContent,
        "editedAt": FieldValue.serverTimestamp(),
        "timestamp": FieldValue.serverTimestamp(),
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
      print("Edit message error: $e");
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
        print("sending notif");
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

          final tlOpRef = convoRef.collection(opColToUse).doc(msgId);
          await tlOpRef.set({
            "type": "timeline_update",
            "messageId": msgId,
            "inTimeline": true,
            "timestamp": FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      print("Web send message error: $e");
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
      final convoRef = firestore.collection("Conversations").doc(convoId);

      final opCol = opCollection ?? _getMyOpCollection(userId, receiverId);
      final opRef = convoRef.collection(opCol).doc(msgId);
      await opRef.set({
        "type": "delete_message",
        "messageId": msgId,
        "timestamp": FieldValue.serverTimestamp(),
        "deletedfor": deleteForEveryone ? [] : [userId],
        "deletedForEveryone": deleteForEveryone,
        "performedBy": userId,
      });

      await supabase.rpc('delete_message_and_update_conversation', params: {
        'p_convo_id': convoId,
        'p_user_id': userId,
        'p_receiver_id': receiverId,
        'p_deleted_message_id': msgId,
        'p_delete_for_everyone': deleteForEveryone,
      });
    } catch (e) {
      print("Web delete message error: $e");
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
    return 'msg_${hash.substring(0, 16)}';
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
