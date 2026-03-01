import 'package:chat_application/core/errors/exceptions.dart';
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

  Future<UserModel> signInWithEmailPassword({
    required String email,
    required String password,
  });

  Future<UserModel?> getCurrentUser();

  Future<void> signout();

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
      final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
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
        profilePic: '',
        friends: [],
      );

      //Saving user to Firestore
      await firebaseFirestore.collection('users').doc(firebaseUser.uid).set({
        'id': firebaseUser.uid,
        'name': name,
        'email': email,
        'profilePic': '',
        'friends': [],
      });

      if(firebaseUser.emailVerified){
        return userModel;
      }else{
        await firebaseUser.sendEmailVerification();
        throw ServerExceptions("Verify your email");
      }

    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw ServerExceptions("Email already exists");
      } else if (e.code == 'invalid-email') {
        throw ServerExceptions("Invalid email address");
      } else if (e.code == 'weak-password') {
        throw ServerExceptions("Password is too weak");
      } else {
        throw ServerExceptions(e.message ?? "Authentication failed");
      }
    }
  }

  @override
  Future<UserModel> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      //Sign in user
      final userCredential =
          await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw ServerExceptions("Login failed");
      }

      //Fetch user data from Firestore
      final userDoc = await firebaseFirestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (!userDoc.exists) {
        throw ServerExceptions("User data not found");
      }
      
      if(firebaseUser.emailVerified){
        return UserModel.fromJson(userDoc.data()!);
      }else{
        throw ServerExceptions("Email not verified");
      }
      

    } on FirebaseAuthException catch (e) {

      if (e.code == 'user-not-found') {
        throw ServerExceptions("User not found");
      } else if (e.code == 'wrong-password') {
        throw ServerExceptions("Incorrect password");
      } else if (e.code == 'invalid-email') {
        throw ServerExceptions("Invalid email address");
      } else {
        throw ServerExceptions(e.message ?? "Login failed");
      }

    } catch (e) {
      throw ServerExceptions(e.toString());
    }
  }
  
  @override
  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = firebaseAuth.currentUser;

    if(firebaseUser == null) return null;

    final userDoc = await firebaseFirestore
      .collection('users')
      .doc(firebaseUser.uid)
      .get();
    
    if(!userDoc.exists) return null;

    return UserModel.fromJson(userDoc.data()!);
  }
  
  @override
  Future<void> signout() async{
    try{
      await firebaseAuth.signOut();
    }
    catch(e){
      throw ServerExceptions("Failed to logout");
    }
  }
}
