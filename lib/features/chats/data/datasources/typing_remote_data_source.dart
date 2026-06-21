import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class TypingRemoteDataSource {
  final FirebaseDatabase _database;

  TypingRemoteDataSource(this._database);

  DatabaseReference _typingRef(String convoId, String userId) {
    return _database.ref('typing/$convoId/$userId');
  }

  Future<void> setTyping(String convoId, String userId, bool isTyping) async {
    try {
      await _typingRef(convoId, userId).set({
        'isTyping': isTyping,
        'timestamp': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('TypingRemoteDataSource.setTyping error: $e');
    }
  }

  Stream<bool> watchTyping(String convoId, String otherUserId) {
    return _database
        .ref('typing/$convoId/$otherUserId/isTyping')
        .onValue
        .map((event) => event.snapshot.value as bool? ?? false)
        .handleError((e) {
      debugPrint('TypingRemoteDataSource.watchTyping error: $e');
      return false;
    });
  }

  Future<void> onDisconnectRemove(String convoId, String userId) async {
    try {
      await _typingRef(convoId, userId).onDisconnect().remove();
    } catch (e) {
      debugPrint('TypingRemoteDataSource.onDisconnectRemove error: $e');
    }
  }

  DatabaseReference _inChatRef(String convoId, String userId) {
    return _database.ref('inChat/$convoId/$userId');
  }

  Future<void> setInChat(String convoId, String userId, bool isInChat) async {
    try {
      await _inChatRef(convoId, userId).set({
        'isInChat': isInChat,
        'timestamp': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('TypingRemoteDataSource.setInChat error: $e');
    }
  }

  Stream<bool> watchInChat(String convoId, String otherUserId) {
    return _database
        .ref('inChat/$convoId/$otherUserId/isInChat')
        .onValue
        .map((event) => event.snapshot.value as bool? ?? false)
        .handleError((e) {
      debugPrint('TypingRemoteDataSource.watchInChat error: $e');
      return false;
    });
  }

  Future<void> onDisconnectRemoveInChat(String convoId, String userId) async {
    try {
      await _inChatRef(convoId, userId).onDisconnect().remove();
    } catch (e) {
      debugPrint('TypingRemoteDataSource.onDisconnectRemoveInChat error: $e');
    }
  }

  Future<void> cancelOnDisconnect(String convoId, String userId) async {
    try {
      await _typingRef(convoId, userId).onDisconnect().cancel();
    } catch (e) {
      debugPrint('TypingRemoteDataSource.cancelOnDisconnect error: $e');
    }
  }
}
