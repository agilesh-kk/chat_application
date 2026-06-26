import 'package:chat_application/core/errors/exceptions.dart';
import 'package:chat_application/features/chats/domain/entities/message.dart';
import 'package:chat_application/features/timeline/data/models/event_model.dart';
import 'package:chat_application/features/timeline/domain/entities/event.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class TimelineRemoteDataSources {
  Future<List<Event>> getEvents({
    required String userId,
    required String receiverId,
  });

  Future<void> addEvent({
    required Message message,
    required String userId,
    required String receiverId,
    required String customTitle,
    required String addedByName,
  });

  Future<void> removeEvent({
    required String eventId,
    required String messageId,
    required String userId,
    required String receiverId,
  });

  Future<List<Event>> getPersonalEvents({
    required String userId
  });

  Future<void> addPersonalEvent({
    required String userId,
    required String id,
    required String title,
    required String content,
    required String type,
    required DateTime time,
    String imageUrl = "",
  });

  Future<void> removePersonalEvent({
    required String userId,
    required String eventId,
  });

  Future<String> uploadImage({
    required XFile image,
    required String eventId,
  });
}

class TimelineRemoteDataSourcesImpl implements TimelineRemoteDataSources {
  final FirebaseFirestore firebaseFirestore;
  final SupabaseClient supabaseClient;

  TimelineRemoteDataSourcesImpl({
    required this.firebaseFirestore,
    required this.supabaseClient,
  });

  @override
  Future<List<Event>> getEvents({
    required String userId,
    required String receiverId,
  }) async {
    try{
      String convoId = generateConversationId(userId, receiverId);

      final timelineEvents =
          (await firebaseFirestore
                  .collection("Conversations")
                  .doc(convoId)
                  .collection("timeline")
                  .orderBy("time")
                  .get())
              .docs;

      return timelineEvents.map((e) {
        return EventModel.fromJson(e.data(), e.id);
      }).toList();
    }
    catch(e){
      throw ServerExceptions(e.toString());
    }
  }

  String generateConversationId(String user1, String user2) {
    final sorted = [user1, user2]..sort();
    return "${sorted[0]}_${sorted[1]}";
  }

  @override
  Future<void> addEvent({
    required Message message,
    required String userId,
    required String receiverId,
    required String customTitle,
    required String addedByName,
  }) async {
    final convoId = generateConversationId(userId, receiverId);

    final timelineRef = firebaseFirestore
        .collection("Conversations")
        .doc(convoId)
        .collection("timeline");

    final eventId = "${message.id}_manual";

    await timelineRef.doc(eventId).set({
      "id": eventId,
      "messageId": message.id,

      // 🔥 USER INPUT
      "title": customTitle.isEmpty ? "Saved a memory ❤️" : customTitle,

      "content": message.content,
      "type": message.type,
      "time": message.createdAt,

      // 🔥 NEW FIELDS
      "addedBy": userId,
      "addedByName": addedByName,
      "isManual": true,
    });

    final messageRef = firebaseFirestore
        .collection("Conversations")
        .doc(convoId)
        .collection("messages")
        .doc(message.id);

    try {
      await messageRef.update({
        "inTimeline": true,
      });
    } catch (_) {
      // On web, messages live in Supabase — the Firestore doc may not exist
    }

    await supabaseClient.rpc('update_message_timeline', params: {
      'p_convo_id': convoId,
      'p_message_id': message.id,
      'p_in_timeline': true,
    });
  }

  @override
  Future<void> removeEvent({
    required String eventId,
    required String messageId,
    required String userId,
    required String receiverId,
  }) async {
    try {
      final convoId = generateConversationId(userId, receiverId);

      final convoRef = firebaseFirestore
          .collection("Conversations")
          .doc(convoId);

      final timelineRef = convoRef.collection("timeline").doc(eventId);

      final messageRef = convoRef.collection("messages").doc(messageId);

      bool shouldSetInTimelineFalse = false;

      await firebaseFirestore.runTransaction((transaction) async {
        final eventSnap = await transaction.get(timelineRef);
        if (!eventSnap.exists) return;

        transaction.delete(timelineRef);

        final timelineQuery =
            await convoRef
                .collection("timeline")
                .where("messageId", isEqualTo: messageId)
                .get();

        if (timelineQuery.docs.length <= 1) {
          transaction.set(messageRef, {
            "inTimeline": false,
          }, SetOptions(merge: true));
          shouldSetInTimelineFalse = true;
        }
      });

      if (shouldSetInTimelineFalse) {
        await supabaseClient.rpc('update_message_timeline', params: {
          'p_convo_id': convoId,
          'p_message_id': messageId,
          'p_in_timeline': false,
        });
      }
    } catch (e) {
      throw ServerExceptions(e.toString());
    }
  }

  @override
  Future<List<Event>> getPersonalEvents({required String userId}) async {
    try {
      final timelineEvents =
          (await firebaseFirestore
                  .collection("users")
                  .doc(userId)
                  .collection("timeline")
                  .orderBy("time")
                  .get())
              .docs;

      return timelineEvents.map((e) {
        return EventModel.fromJson(e.data(), e.id);
      }).toList();
    } catch (e) {
      throw ServerExceptions(e.toString());
    }
  }

  @override
  Future<void> addPersonalEvent({
    required String userId,
    required String id,
    required String title,
    required String content,
    required String type,
    required DateTime time,
    String imageUrl = "",
  }) async{
    try {
      final timelineRef = firebaseFirestore
        .collection("users")
        .doc(userId)
        .collection("timeline");

      await timelineRef.doc(id).set({
        "id": id,
        "title": title.isEmpty ? "Saved a memory ❤️" : title,
        "content": content,
        "type": type,
        "time": time,

        "imageUrl": imageUrl,
        "hasImage": imageUrl.isNotEmpty,
      });
    } catch (e) {
      throw ServerExceptions(e.toString());
    }
  }
  
  @override
  @override
  Future<String> uploadImage({
    required XFile image,
    required String eventId,
  }) async {
    try {
      final bytes = await image.readAsBytes();
      await supabaseClient.storage.from('personal_timeline_images').uploadBinary(
        'events/$eventId',
        bytes,
      );
      return supabaseClient.storage.from('personal_timeline_images').getPublicUrl('events/$eventId');
    } catch (e) {
      throw ServerExceptions(e.toString());
    }
  }

  @override
  Future<void> removePersonalEvent({required String userId, required String eventId}) async {
    try{
      await firebaseFirestore
        .collection("users")
        .doc(userId)
        .collection("timeline")
        .doc(eventId)
        .delete();
    }
    catch(e){
      throw ServerExceptions(e.toString());
    }
  }
}
