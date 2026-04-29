import 'package:chat_application/features/friends/data/friend_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class FriendsRemoteDataSource {
  Future<Stream<List<FriendModel>>> getFriends(String userId);

  Future<void> addFriend(String userId, String friendId);

  Future<void> removeFriend(String userId, String friendId);
}

class FriendsRemoteDataSourceImpl implements FriendsRemoteDataSource {
  final FirebaseFirestore firestore;

  FriendsRemoteDataSourceImpl(this.firestore);

  @override
  Future<Stream<List<FriendModel>>> getFriends(String userId) async {
    return firestore
        .collection('users')
        .where('friends',arrayContains: userId)
        .snapshots()
        .map((snap)=>snap.docs.map((doc)=>FriendModel.fromJson(doc.data())).toList());
  }

  @override
  Future<void> addFriend(String userId, String friendId) async {
    final friendDoc = firestore.collection('users').doc(friendId);

    final friendSnapshot = await friendDoc.get();
    final data = friendSnapshot.data();

    if (data == null) return;

    await firestore
        .collection('users')
        .doc(userId)
        .collection('friends')
        .doc(friendId)
        .set({
      'id': friendId,
      'name': data['name'],
      'avatar': data['avatar'],
      'addedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> removeFriend(String userId, String friendId) async {
    await firestore
        .collection('users')
        .doc(userId)
        .collection('friends')
        .doc(friendId)
        .delete();
  }
}