import 'dart:io';

import 'package:chat_application/core/common/entities/user.dart';
import 'package:chat_application/core/errors/exceptions.dart';
import 'package:chat_application/features/chats/data/models/conversation_model.dart';
import 'package:chat_application/features/chats/data/models/message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

abstract interface class ChatRemoteDataSources {
  Future<Stream<List<ConversationModel>>> getConversations({
    required String userId
  });

  Future<void> sendMessage({
    required String receiverId,
    required String userId,
    required String content,
    required String msgId,
    String type = "text",
    String? userName,
    String? userProfile
  });

  Future<String> uploadImage({
    required File file,
    required String msgId,
  });

  Future<Stream<List<MessageModel>>> getMessages({
    required String receiverId,
    required String userId
  });

  Future<User?> searchUser({
    required String receiverName
  });

}

class ChatRemoteDataSourcesImpl implements ChatRemoteDataSources{
  final FirebaseFirestore firestore;
  final SupabaseClient supabase;
  ChatRemoteDataSourcesImpl({required this.firestore, required this.supabase});

  @override
  Future<Stream<List<ConversationModel>>> getConversations({required String userId}) async{
    return firestore
    .collection("Conversations")
    .where("participantsId",arrayContains: userId)
    .orderBy("lastupdateTime",descending: true)
    .snapshots()
    .map((snapshot){
      return snapshot.docs.map(
        (doc){
          return ConversationModel.fromJson(doc.data(),doc.id,userId);
        }
      ).toList();
    });
  }

  @override
  Future<Stream<List<MessageModel>>> getMessages({required String receiverId, required String userId}) async{
    return firestore
           .collection("Conversations")
           .doc(generateConversationId(userId, receiverId))
           .collection("messages")
           .orderBy("createdAt", descending: true)
           .snapshots()
           .map((snapshot) {
            markMessagesDelivered(userId, receiverId);
             return snapshot.docs.map((doc) {
               return MessageModel.fromJson(doc.data(),doc.id);
             }).toList();
           });
  }

  @override
  Future<String> uploadImage({required File file, required String msgId}) async {
    final path = "$msgId.jpg";

    await supabase.storage.from("images").upload(path, file);

    return supabase.storage.from("images").getPublicUrl(path);
  }

  @override
  Future<void> sendMessage({required String userId, required String receiverId, required String msgId, String type = "text", required String content, String? userName, String? userProfile,}) async {
  try {
    final convoRef = firestore
        .collection("Conversations")
        .doc(generateConversationId(userId, receiverId));

    final messageRef =
        convoRef.collection("messages").doc(msgId);
    
    final receiverDoc = firestore.collection("users").doc(receiverId); 
    
    final receiverData = (await receiverDoc.get()).data()!;

    final message = MessageModel(
      id: msgId,
      type: type,
      status: "sent",
      senderId: userId,
      content: content,
      createdAt: DateTime.now().toString(),
      deletedfor: [],
    );

    WriteBatch batch = firestore.batch();

    batch.set(messageRef, {
      ...message.toMap(),
      "createdAt": FieldValue.serverTimestamp(), // server sync later
      "index": null
    });

    batch.set(
      convoRef,
      {
        "participantsId": [userId, receiverId],
        "lastMessage": (type=="text")?content:"📷Image",
        "lastupdateTime": FieldValue.serverTimestamp(),

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
        }
      },
      SetOptions(merge: true),
    );

    final userRef = firestore.collection("users").doc(userId);
    final receiverRef = firestore.collection("users").doc(receiverId);

    batch.set(userRef, {
      "friends": FieldValue.arrayUnion([receiverId])
    }, SetOptions(merge: true));

    batch.set(receiverRef, {
      "friends": FieldValue.arrayUnion([userId])
    }, SetOptions(merge: true));

    await batch.commit();

  } catch (e) {
    print("Send message error: $e");
  }
}

  String generateConversationId(String user1,String user2){
    final sorted = [user1, user2]..sort();
    return "${sorted[0]}_${sorted[1]}";
  }
  
  @override
  Future<User?> searchUser({required String receiverName})async {
    final result = await firestore
                   .collection("users")
                   .where("name",isEqualTo: receiverName)
                   .get();

    if(result.size > 0){
      final user = result.docs[0].data();
      if(user.isNotEmpty){
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
      }
    }

    throw ServerExceptions("User Not Found");
  }

      Future<void> markMessagesDelivered(
        String userId,
        String receiverId,
      ) async {

        final convoRef = firestore
            .collection("Conversations")
            .doc(generateConversationId(userId, receiverId))
            ..update({
              "$userId.unread" : 0
            });

        final snapshot = await convoRef
            .collection("messages")
            .where("senderId", isEqualTo: receiverId)
            .where("status", isEqualTo: "sent")
            .get();

        final batch = firestore.batch();

        for (final doc in snapshot.docs) {
          batch.update(doc.reference, {
            "status": "seen",
          });
        }
        await batch.commit();
      }
}