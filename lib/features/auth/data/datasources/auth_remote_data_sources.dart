import 'package:chat_application/features/auth/data/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:firebase_core/firebase_core.dart';

abstract interface class AuthRemoteDataSources {
  Future<UserModel> signUpWithEmailPassword({
    required String name,
    required String email,
    required String password,
  });
}

class AuthRemoteDataSourcesImpl implements AuthRemoteDataSources {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firebaseFirestore;

  AuthRemoteDataSourcesImpl({
    required this.firebaseAuth,
    required this.firebaseFirestore,
  });

  @override
  Future<UserModel> signUpWithEmailPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      //Create user in Firebase Auth
      final userCredential =
          await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception("User creation failed");
      }

      //Creating UserModel using the existing structure
      final userModel = UserModel(
        id: firebaseUser.uid,
        name: name,
        email: email,
      );

      //Saving user to Firestore
      await firebaseFirestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set({
        'id': firebaseUser.uid,
        'name': name,
        'email': email,
      });

      return userModel;

    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? "Something went wrong");
    }
  }
}
