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
      await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({
          'profilePic' : imageUrl,
        });
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