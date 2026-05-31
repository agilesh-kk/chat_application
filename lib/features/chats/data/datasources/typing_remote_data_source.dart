import 'package:firebase_database/firebase_database.dart';

class TypingRemoteDataSource {
  final FirebaseDatabase _database;

  TypingRemoteDataSource(this._database);

  DatabaseReference _typingRef(String convoId, String userId) {
    return _database.ref('typing/$convoId/$userId');
  }

  Future<void> setTyping(String convoId, String userId, bool isTyping) async {
    await _typingRef(convoId, userId).set({
      'isTyping': isTyping,
      'timestamp': ServerValue.timestamp,
    });
  }

  Stream<bool> watchTyping(String convoId, String otherUserId) {
    return _database
        .ref('typing/$convoId/$otherUserId/isTyping')
        .onValue
        .map((event) => event.snapshot.value as bool? ?? false);
  }

  Future<void> onDisconnectRemove(String convoId, String userId) async {
    await _typingRef(convoId, userId).onDisconnect().remove();
  }

  Future<void> cancelOnDisconnect(String convoId, String userId) async {
    await _typingRef(convoId, userId).onDisconnect().cancel();
  }
}
