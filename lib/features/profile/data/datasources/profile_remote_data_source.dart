import 'dart:io';

import 'package:chat_application/core/errors/exceptions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class ProfileRemoteDataSource {
  //updating profile pic
  Future<void> updateProfilePic(String userId, String imageUrl);

  Future<void> updateBio(String userId, String bio);

  //uploading custom pfp
  Future<String> uploadCustomPfp({
    required String userId,
    required XFile image,
    required String oldPfpImage,
  });
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource{
  final FirebaseFirestore firebaseFirestore;
  final SupabaseClient supabaseClient;

  ProfileRemoteDataSourceImpl({
    required this.firebaseFirestore,
    required this.supabaseClient,
  });

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

  @override
  Future<String> uploadCustomPfp({
    required String userId,
    required XFile image,
    required String oldPfpImage,
  }) async {
    try {
      // Delete old profile picture
      if (oldPfpImage.isNotEmpty) {
        final oldFileName = oldPfpImage.split('/').last;

        await supabaseClient.storage
            .from('custom_pfp')
            .remove([oldFileName]);
      }

      final fileName =
          "${userId}_${DateTime.now().millisecondsSinceEpoch}";

      if (kIsWeb) {
        final bytes = await image.readAsBytes();

        await supabaseClient.storage
            .from('custom_pfp')
            .uploadBinary(
              fileName,
              bytes,
            );
      } else {
        final file = File(image.path);

        await supabaseClient.storage
            .from('custom_pfp')
            .upload(
              fileName,
              file,
            );
      }

      return supabaseClient.storage
          .from('custom_pfp')
          .getPublicUrl(fileName);
    } catch (e) {
      throw ServerExceptions(e.toString());
    }
  }
}