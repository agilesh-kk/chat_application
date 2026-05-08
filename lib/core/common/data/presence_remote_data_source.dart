import 'package:cloud_firestore/cloud_firestore.dart';

abstract class PresenceRemoteDataSource {
  Future<void> setOnline(String userId, bool isOnline);
  Future<void> updateLastSeen(String userId);
}

class PresenceRemoteDataSourceImpl implements PresenceRemoteDataSource {
  final FirebaseFirestore firestore;

  PresenceRemoteDataSourceImpl(this.firestore);

  @override
  Future<void> setOnline(String userId, bool isOnline) async {
    await firestore.collection('users').doc(userId).update({
      'isOnline': isOnline,
      if(isOnline)'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateLastSeen(String userId) async {
    await firestore.collection('users').doc(userId).update({
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }
}
