import 'package:chat_application/core/errors/exceptions.dart';
import 'package:chat_application/core/utils/random_profile_image.dart';
import 'package:chat_application/features/auth/data/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
//import 'package:firebase_core/firebase_core.dart';

abstract interface class AuthRemoteDataSources {
  Future<UserModel> signUpWithEmailPassword({
    required String name,
    required String email,
    required String password,
    required DateTime birthDate,
    required String gender,
    required String eventId,
  });

  Future<UserModel> signInWithEmailPassword({
    required String email,
    required String password,
  });

  Future<UserModel?> getCurrentUser();

  Future<void> signout();

  Future<bool> isNameAvailable({
    required String name
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
    required DateTime birthDate,
    required String gender,
    required String eventId,
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
        birthDate: birthDate,
        gender: gender,
        profilePic: '',
        friends: [],
        bio: '',
      );

      //Saving user to Firestore
      await firebaseFirestore.collection('users').doc(firebaseUser.uid).set({
        'id': firebaseUser.uid,
        'name': name,
        'email': email,
        'profilePic': getRandomProfileImage(),
        'birthDate': birthDate,
        'friends': [],
        'Requests': [],
        'gender' : gender,
        'bio' : "",
        'convoList': [],
      });

      final timelineRef = firebaseFirestore
        .collection("users")
        .doc(firebaseUser.uid)
        .collection("timeline");
      
      await timelineRef.doc(eventId).set({
        "id": eventId,
        "title": "Account created!",
        "content": "Welcoming you to Memento",
        "type": "text",
        "time": DateTime.now(),
      });

      if(!firebaseUser.emailVerified){
        await firebaseUser.sendEmailVerification();
        await firebaseAuth.signOut();
      }
      return userModel;

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
  Future<bool> isNameAvailable({required String name}) async{
    final doc = await firebaseFirestore
      .collection('usernames')
      .doc(name.trim().toLowerCase())
      .get();

    return !doc.exists;
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
        await firebaseUser.sendEmailVerification();
        await firebaseAuth.signOut();
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
        throw ServerExceptions(_friendlyAuthError(e.message));
      }

    } catch (e) {
      throw ServerExceptions(_friendlyAuthError(e.toString()));
    }
  }

  String _friendlyAuthError(String? message) {
    if (message == null) return "Login failed";
    if (message.toLowerCase().contains('blocked') ||
        message.toLowerCase().contains('unusual activity')) {
      return "Too many attempts. Please try again later.";
    }
    return message;
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
