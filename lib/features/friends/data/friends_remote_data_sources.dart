import 'dart:async';

import 'package:chat_application/features/friends/data/friend_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class FriendsRemoteDataSource {
  Future<Stream<Map<String,FriendModel>>> getFriends(String userId);

  Future<void> addFriend(String userId, String friendId);

  Future<void> removeFriend(String userId, String friendId);

  Future<void> sendFriendReq({
    required String userId,
    required String friendId,
  });

  Future<Stream<Map<String, FriendModel>>> getFriendRequests(String userId);

  Future<bool> isUserInRequests({
    required String userId,
    required String targetUserId,
  });

  Future<void> acceptFriendRequest({
    required String userId,
    required String requesterId,
  });

  Future<void> rejectFriendRequest({
    required String userId,
    required String requesterId,
  });

  Future<void> cancelFriendRequest({
    required String userId,
    required String friendId,
  });

  Future<Stream<Set<String>>> getSentRequests(String userId);

  Future<bool> checkIfUserIsFriend({
    required String userId,
    required String targetUserId,
  });
}

class FriendsRemoteDataSourceImpl implements FriendsRemoteDataSource {
  final FirebaseFirestore firestore;

  FriendsRemoteDataSourceImpl(this.firestore);

  @override
  Future<Stream<Map<String,FriendModel>>> getFriends(String userId) async {
    return firestore
        .collection('users')
        .where('friends',arrayContains: userId)
        .snapshots()
        .map((snap)=>Map.fromEntries(snap.docs.map((doc)=>MapEntry(doc.id,FriendModel.fromJson(doc.data())))));
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
    final batch = firestore.batch();
    batch.update(firestore.collection('users').doc(userId), {
      'friends': FieldValue.arrayRemove([friendId]),
    });
    batch.update(firestore.collection('users').doc(friendId), {
      'friends': FieldValue.arrayRemove([userId]),
    });
    await batch.commit();
  }

  @override
  Future<void> sendFriendReq({
    required String userId,
    required String friendId,
  }) async {
    final batch = firestore.batch();
    final friendRef = firestore.collection('users').doc(friendId);
    batch.set(friendRef, {
      'Requests': FieldValue.arrayUnion([userId]),
    }, SetOptions(merge: true));
    final userRef = firestore.collection('users').doc(userId);
    batch.update(userRef, {
      'sentRequests': FieldValue.arrayUnion([friendId]),
    });
    await batch.commit();
  }

  @override
  Future<Stream<Map<String, FriendModel>>> getFriendRequests(
    String userId,
  ) async {
    final userDoc = firestore.collection('users').doc(userId);
    return userDoc.snapshots().asyncMap((snapshot) async {
      final requestIds = List<String>.from(snapshot.data()?['Requests'] ?? []);
      if (requestIds.isEmpty) return {};

      final usersSnap = await firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: requestIds)
          .get();

      final map = <String, FriendModel>{};
      for (final doc in usersSnap.docs) {
        final data = doc.data();
        map[doc.id] = FriendModel(
          id: doc.id,
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          profilePic: data['profilePic'],
          isOnline: data['isOnline'] ?? false,
          lastSeen: data['lastSeen'] != null
              ? (data['lastSeen'] as Timestamp).toDate()
              : null,
        );
      }
      return map;
    });
  }

  @override
  Future<bool> isUserInRequests({
    required String userId,
    required String targetUserId,
  }) async {
    final doc = await firestore.collection('users').doc(userId).get();
    if (!doc.exists) return false;
    final requests = List<String>.from(doc.data()?['Requests'] ?? []);
    return requests.contains(targetUserId);
  }

  @override
  Future<void> acceptFriendRequest({
    required String userId,
    required String requesterId,
  }) async {
    final batch = firestore.batch();
    final userRef = firestore.collection('users').doc(userId);
    final requesterRef = firestore.collection('users').doc(requesterId);
    batch.update(userRef, {
      'Requests': FieldValue.arrayRemove([requesterId]),
      'friends': FieldValue.arrayUnion([requesterId]),
    });
    batch.update(requesterRef, {
      'friends': FieldValue.arrayUnion([userId]),
      'sentRequests': FieldValue.arrayRemove([userId]),
    });
    await batch.commit();
  }

  @override
  Future<void> rejectFriendRequest({
    required String userId,
    required String requesterId,
  }) async {
    final batch = firestore.batch();
    final userRef = firestore.collection('users').doc(userId);
    final requesterRef = firestore.collection('users').doc(requesterId);
    batch.update(userRef, {
      'Requests': FieldValue.arrayRemove([requesterId]),
    });
    batch.update(requesterRef, {
      'sentRequests': FieldValue.arrayRemove([userId]),
    });
    await batch.commit();
  }

  @override
  Future<void> cancelFriendRequest({
    required String userId,
    required String friendId,
  }) async {
    final batch = firestore.batch();
    batch.update(firestore.collection('users').doc(friendId), {
      'Requests': FieldValue.arrayRemove([userId]),
    });
    batch.update(firestore.collection('users').doc(userId), {
      'sentRequests': FieldValue.arrayRemove([friendId]),
    });
    await batch.commit();
  }

  @override
  Future<Stream<Set<String>>> getSentRequests(String userId) async {
    return firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      final sentRequests =
          List<String>.from(snapshot.data()?['sentRequests'] ?? []);
      return sentRequests.toSet();
    });
  }

  @override
  Future<bool> checkIfUserIsFriend({
    required String userId,
    required String targetUserId,
  }) async {
    final doc = await firestore.collection('users').doc(userId).get();
    if (!doc.exists) return false;
    final friends = List<String>.from(doc.data()?['friends'] ?? []);
    return friends.contains(targetUserId);
  }
}
