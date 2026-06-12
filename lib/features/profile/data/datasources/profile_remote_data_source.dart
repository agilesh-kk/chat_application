import 'package:chat_application/core/errors/exceptions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract interface class ProfileRemoteDataSource {
  Future<void> updateProfilePic(String userId, String imageUrl);

  Future<void> updateBio(String userId, String bio);
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource{
  final FirebaseFirestore firebaseFirestore;

  ProfileRemoteDataSourceImpl({required this.firebaseFirestore});

  //for updating profilepic
  @override
  Future<void> updateProfilePic(String userId,String imageUrl) async{
    try{
      await firebaseFirestore
        .collection('users')
        .doc(userId)
        .update({
          'profilePic' : imageUrl,
        });


      final docs = (await firebaseFirestore
        .collection('Conversations')
        .where("participantsId",arrayContains: userId)
        .get())
        .docs;

      WriteBatch batch = FirebaseFirestore.instance.batch();

      for(final doc in docs){
        final data = doc.data();
        final receiverId = (data["participantsId"] as List).firstWhere((e)=>e!=userId, orElse: ()=>"").toString();

        if(receiverId.isEmpty)continue;

        batch.set(
          doc.reference, 
          {
            receiverId:{
              "receiverProfile" : imageUrl
            }
          },
          SetOptions(merge: true)
        );
      }

      await batch.commit();
    }
    catch(e){
      throw ServerExceptions(e.toString());
    }
  }
  
  @override
  Future<void> updateBio(String userId, String bio) async{
    try{
      await firebaseFirestore.
        collection('users')
        .doc(userId)
        .update({
          'bio' : bio,
        });
    }
    catch(e){
      throw ServerExceptions(e.toString());
    }
  } 
}