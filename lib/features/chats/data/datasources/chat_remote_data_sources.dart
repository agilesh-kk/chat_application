import 'package:chat_application/core/common/cubit/app_user_cubit.dart';
import 'package:chat_application/core/common/entities/user.dart';
import 'package:chat_application/core/errors/exceptions.dart';
import 'package:chat_application/features/chats/data/models/conversation_model.dart';
import 'package:chat_application/features/chats/data/models/message_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract interface class ChatRemoteDataSources {
  Future<Stream<List<ConversationModel>>> getConversations({
    required String userId
  });

  Future<void> sendMessage({
    required String receiverId,
    required String userId,
    required String content,
    String? userName,
    String? userProfile
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
  ChatRemoteDataSourcesImpl({required this.firestore});

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
             return snapshot.docs.map((doc) {
               return MessageModel.fromJson(doc.data(),doc.id);
             }).toList();
           });
  }

  @override
  Future<void> sendMessage({required String receiverId, required String userId, required String content, String? userName, String? userProfile}) async {
    final convoRef =
      firestore
      .collection("Conversations")
      .doc(generateConversationId(userId, receiverId));

    final messageRef = convoRef
      .collection("messages")
      .doc();  // generates id

    final message = MessageModel(
      id: messageRef.id,
      senderId: userId,
      content: content,
      createdAt: DateTime.now().toString(),
      deletedfor: [],
    );

    
    await firestore.runTransaction((transaction) async {

      final convoSnapshot =
      await transaction.get(convoRef);

      // If conversation doesn't exist -> create
      if (!convoSnapshot.exists) {
        final receiverDoc = await transaction.get(
                            firestore.collection("users").doc(receiverId),
                            );

        final receiverData = receiverDoc.data()!;

        transaction.set(convoRef, {
          "participantsId": {userId,receiverId},
          "lastMessage": content,
          "lastupdateTime":
              FieldValue.serverTimestamp(),
          userId : {
            "receiverId" : receiverId,
            "receiverName" : receiverData["name"],
            "receiverProfile" : receiverData["profileLink"]
          },
          receiverId : {
            "receiverId" : userId,
            "receiverName" : userName ?? "Unknown",
            "receiverProfile" : userProfile ?? "Not Found"
          }
        });
      }

      // add message
      transaction.set(
        messageRef,
        message.toMap(),
      );

      transaction.update(
        messageRef,
        {
          "createdAt" : FieldValue.serverTimestamp()
        }
      );

      // update parent convo
      transaction.update(
        convoRef,
        {
          "lastMessage" : message.content,
          "lastupdateTime" :
            FieldValue.serverTimestamp()
        }
      );

    });
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
          id: user["id"]
          );
      }
    }

    throw ServerExceptions("User Not Found");
  }
}