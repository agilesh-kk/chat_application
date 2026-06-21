import 'package:chat_application/features/friends/data/friend_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class FriendsRemoteDataSource {
  Future<Stream<Map<String, FriendModel>>> getFriends(String userId);

  Future<Stream<Map<String, FriendModel>>> getFriendRequests(String userId);

  Future<bool> isUserInRequests({
    required String userId,
    required String targetUserId,
  });

  Future<Stream<Set<String>>> getSentRequests(String userId);

  Future<bool> checkIfUserIsFriend({
    required String userId,
    required String targetUserId,
  });

  Future<void> addFriend(String userId, String friendId);

  Future<void> removeFriend(String userId, String friendId);

  Future<void> sendFriendReq({
    required String userId,
    required String friendId,
  });

  Future<void> acceptFriendReq({
    required String userId,
    required String requesterId,
  });

  Future<void> rejectFriendReq({
    required String userId,
    required String requesterId,
  });
}

class FriendsRemoteDataSourceImpl implements FriendsRemoteDataSource {
  final FirebaseFirestore firestore;

  FriendsRemoteDataSourceImpl(this.firestore);

  @override
  Future<Stream<Map<String, FriendModel>>> getFriends(String userId) async {
    return firestore
        .collection('users')
        .where('friends', arrayContains: userId)
        .snapshots()
        .map((snap) => Map.fromEntries(snap.docs
            .map((doc) => MapEntry(doc.id, FriendModel.fromJson(doc.data())))));
  }

  @override
  Future<Stream<Map<String, FriendModel>>> getFriendRequests(
      String userId) async {
    return firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .asyncMap((snapshot) async {
      final requestIds =
          List<String>.from(snapshot.data()?['Requests'] ?? []);
      if (requestIds.isEmpty) return <String, FriendModel>{};

      final docs = await Future.wait(
          requestIds.map((id) => firestore.collection('users').doc(id).get()));

      return {
        for (final doc in docs)
          if (doc.exists) doc.id: FriendModel.fromJson(doc.data()!)
      };
    });
  }

  @override
  Future<bool> isUserInRequests({
    required String userId,
    required String targetUserId,
  }) async {
    final doc = await firestore.collection('users').doc(targetUserId).get();
    if (!doc.exists) return false;
    final requests = List<String>.from(doc.data()?['Requests'] ?? []);
    return requests.contains(userId);
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
    final userRef = firestore.collection('users').doc(userId);
    final friendRef = firestore.collection('users').doc(friendId);

    batch.update(userRef, {
      'friends': FieldValue.arrayRemove([friendId]),
    });
    batch.update(friendRef, {
      'friends': FieldValue.arrayRemove([userId]),
    });

    await batch.commit();

    try {
      final convoId = _generateConvoId(userId, friendId);
      await firestore.collection('Conversations').doc(convoId).update({
        '$userId.isFriend': false,
        '$friendId.isFriend': false,
      });
    } catch (_) {}
  }

  String _generateConvoId(String user1, String user2) {
    final sorted = [user1, user2]..sort();
    return "${sorted[0]}_${sorted[1]}";
  }

  @override
  Future<void> sendFriendReq({
    required String userId,
    required String friendId,
  }) async {
    final batch = firestore.batch();
    final userRef = firestore.collection('users').doc(userId);
    final friendRef = firestore.collection('users').doc(friendId);
    batch.set(friendRef, {
      'Requests': FieldValue.arrayUnion([userId]),
    }, SetOptions(merge: true));
    batch.update(userRef, {
      'sentRequests': FieldValue.arrayUnion([friendId]),
    });
    await batch.commit();
  }

  @override
  Future<void> acceptFriendReq({
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
  Future<void> rejectFriendReq({
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
