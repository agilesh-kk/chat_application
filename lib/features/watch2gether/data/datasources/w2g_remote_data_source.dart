import 'dart:async';
import 'dart:io';
import 'package:chat_application/features/watch2gether/data/model/w2g_chat_message_model.dart';
import 'package:chat_application/features/watch2gether/data/model/w2g_participant_model.dart';
import 'package:chat_application/features/watch2gether/data/model/w2g_room_model.dart';
import 'package:chat_application/features/watch2gether/data/model/w2g_video_item_model.dart';
import 'package:chat_application/features/watch2gether/domain/entity/w2g_room.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

abstract interface class W2GRemoteDataSource {
  Future<String> createRoom(String name, String createdBy);
  Future<void> deleteRoom(String roomId);
  Stream<W2GRoom> getRoomStream(String roomId);
  Future<void> joinRoom(String roomId, W2GParticipantModel participant);
  Future<void> leaveRoom(String roomId, String userId);
  Future<void> updatePlayerState(String roomId, W2GPlayerState state);
  Future<void> setCurrentVideo(String roomId, W2GVideoItemModel? video);
  Future<void> addToQueue(String roomId, W2GVideoItemModel item);
  Future<void> removeFromQueue(String roomId, String itemId);
  Future<void> sendMessage(String roomId, W2GChatMessageModel message);
  Stream<List<W2GChatMessageModel>> getMessagesStream(String roomId);
  Stream<Map<String, W2GParticipantModel>> getParticipantsStream(
      String roomId);
  Future<List<W2GRoom>> getActiveRooms();

  Future<void> sendInvite(String roomId, String roomName, String hostId, String hostName, String invitedUserId);
  Future<void> deleteInvite(String invitedUserId, String roomId);
  Stream<Map<String, dynamic>> getInvitesStream(String userId);

  Future<void> toggleReaction(String roomId, String messageId, String userId, String emoji);

  Future<String> uploadImage(String imagePath, String msgId);

  Future<String?> getUserActiveRoom(String userId);
  Future<void> setUserActiveRoom(String userId, String roomId);
  Future<void> removeUserActiveRoom(String userId);
}

class W2GRemoteDataSourceImpl implements W2GRemoteDataSource {
  final FirebaseDatabase _database;
  final SupabaseClient _supabase;

  W2GRemoteDataSourceImpl(this._database, this._supabase);

  DatabaseReference _roomRef(String roomId) =>
      _database.ref('watch2gether/rooms/$roomId');

  DatabaseReference _roomsRef() =>
      _database.ref('watch2gether/rooms');

  DatabaseReference _inviteRef(String userId) =>
      _database.ref('watch2gether/invites/$userId');

  DatabaseReference _userRoomRef(String userId) =>
      _database.ref('watch2gether/userRooms/$userId');

  @override
  Future<String> createRoom(String name, String createdBy) async {
    final ref = _roomsRef().push();
    await ref.set({
      'name': name,
      'createdBy': createdBy,
      'hostId': createdBy,
      'createdAt': ServerValue.timestamp,
      'currentVideo': null,
      'playerState': {
        'isPlaying': false,
        'position': 0.0,
        'updatedBy': '',
        'lastUpdated': ServerValue.timestamp,
      },
      'queue': {},
      'participants': {},
      'messages': {},
    });
    return ref.key!;
  }

  @override
  Stream<W2GRoom> getRoomStream(String roomId) {
    return _roomRef(roomId).onValue.map((event) {
      final map = (event.snapshot.value as Map?)?.cast<String, dynamic>() ?? {};
      return W2GRoomModel.fromMap(roomId, map);
    });
  }

  @override
  Future<void> joinRoom(
      String roomId, W2GParticipantModel participant) async {
    final ref = _roomRef(roomId).child('participants/${participant.userId}');
    await ref.set(participant.toMap());
  }

  @override
  Future<void> leaveRoom(String roomId, String userId) async {
    await _roomRef(roomId).child('participants/$userId').remove();
  }

  @override
  Future<void> updatePlayerState(
      String roomId, W2GPlayerState state) async {
    await _roomRef(roomId).child('playerState').set({
      'isPlaying': state.isPlaying,
      'position': state.position,
      'updatedBy': state.updatedBy,
      'lastUpdated': ServerValue.timestamp,
    });
  }

  @override
  Future<void> setCurrentVideo(
      String roomId, W2GVideoItemModel? video) async {
    if (video != null) {
      await _roomRef(roomId).child('currentVideo').set(video.toMap());
    } else {
      await _roomRef(roomId).child('currentVideo').remove();
    }
  }

  @override
  Future<void> addToQueue(String roomId, W2GVideoItemModel item) async {
    await _roomRef(roomId).child('queue/${item.id}').set(item.toMap());
  }

  @override
  Future<void> removeFromQueue(String roomId, String itemId) async {
    await _roomRef(roomId).child('queue/$itemId').remove();
  }

  @override
  Future<void> sendMessage(String roomId, W2GChatMessageModel message) async {
    await _roomRef(roomId)
        .child('messages/${message.id}')
        .set(message.toMap());
  }

  @override
  Stream<List<W2GChatMessageModel>> getMessagesStream(String roomId) {
    return _roomRef(roomId).child('messages').onValue.map((event) {
      final map = (event.snapshot.value as Map?)?.cast<String, dynamic>() ?? {};
      final entries = map.entries.toList();
      entries.sort((a, b) {
        final aTime =
            (a.value as Map)['timestamp'] as num? ?? 0;
        final bTime =
            (b.value as Map)['timestamp'] as num? ?? 0;
        return aTime.compareTo(bTime);
      });
      return entries.map((e) {
        return W2GChatMessageModel.fromMap(
            e.key, (e.value as Map).cast<String, dynamic>());
      }).toList();
    });
  }

  @override
  Stream<Map<String, W2GParticipantModel>> getParticipantsStream(
      String roomId) {
    return _roomRef(roomId).child('participants').onValue.map((event) {
      final map = (event.snapshot.value as Map?)?.cast<String, dynamic>() ?? {};
      return map.map((key, value) {
        return MapEntry(
          key,
          W2GParticipantModel.fromMap(
              key, (value as Map).cast<String, dynamic>()),
        );
      });
    });
  }

  @override
  Future<List<W2GRoom>> getActiveRooms() async {
    final snapshot = await _roomsRef().once();
    final map = (snapshot.snapshot.value as Map?)?.cast<String, dynamic>() ?? {};
    return map.entries.map((e) {
      return W2GRoomModel.fromMap(
          e.key, (e.value as Map).cast<String, dynamic>());
    }).toList();
  }

  @override
  Future<void> deleteRoom(String roomId) async {
    await _roomRef(roomId).remove();
  }

  @override
  Future<void> sendInvite(String roomId, String roomName, String hostId, String hostName, String invitedUserId) async {
    await _inviteRef(invitedUserId).child(roomId).set({
      'roomId': roomId,
      'roomName': roomName,
      'hostId': hostId,
      'hostName': hostName,
      'timestamp': ServerValue.timestamp,
    });
  }

  @override
  Future<void> deleteInvite(String invitedUserId, String roomId) async {
    await _inviteRef(invitedUserId).child(roomId).remove();
  }

  @override
  Stream<Map<String, dynamic>> getInvitesStream(String userId) {
    return _inviteRef(userId).onValue.map((event) {
      final map = (event.snapshot.value as Map?)?.cast<String, dynamic>() ?? {};
      return map;
    });
  }

  @override
  Future<void> toggleReaction(String roomId, String messageId, String userId, String emoji) async {
    final ref = _roomRef(roomId).child('messages/$messageId/reactions/$userId');
    final snapshot = await ref.get();
    if (snapshot.value == emoji) {
      await ref.remove();
    } else {
      await ref.set(emoji);
    }
  }

  @override
  Future<String?> getUserActiveRoom(String userId) async {
    final snapshot = await _userRoomRef(userId).get();
    return snapshot.value as String?;
  }

  @override
  Future<void> setUserActiveRoom(String userId, String roomId) async {
    await _userRoomRef(userId).set(roomId);
  }

  @override
  Future<void> removeUserActiveRoom(String userId) async {
    await _userRoomRef(userId).remove();
  }

  @override
  Future<String> uploadImage(String imagePath, String msgId) async {
    final path = 'w2g_images/$msgId.jpg';
    if (kIsWeb) {
      final file = await XFile(imagePath).readAsBytes();
      await _supabase.storage.from('images').uploadBinary(path, file);
    } else {
      await _supabase.storage.from('images').upload(path, File(imagePath));
    }
    return _supabase.storage.from('images').getPublicUrl(path);
  }
}
