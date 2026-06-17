import 'dart:async';
import 'package:chat_application/features/watch2gether/data/model/w2g_chat_message_model.dart';
import 'package:chat_application/features/watch2gether/data/model/w2g_participant_model.dart';
import 'package:chat_application/features/watch2gether/data/model/w2g_room_model.dart';
import 'package:chat_application/features/watch2gether/data/model/w2g_video_item_model.dart';
import 'package:chat_application/features/watch2gether/domain/entity/w2g_room.dart';
import 'package:firebase_database/firebase_database.dart';

abstract interface class W2GRemoteDataSource {
  Future<String> createRoom(String name, String createdBy);
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
}

class W2GRemoteDataSourceImpl implements W2GRemoteDataSource {
  final FirebaseDatabase _database;

  W2GRemoteDataSourceImpl(this._database);

  DatabaseReference _roomRef(String roomId) =>
      _database.ref('watch2gether/rooms/$roomId');

  DatabaseReference _roomsRef() =>
      _database.ref('watch2gether/rooms');

  @override
  Future<String> createRoom(String name, String createdBy) async {
    final ref = _roomsRef().push();
    await ref.set({
      'name': name,
      'createdBy': createdBy,
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
    await ref.onDisconnect().remove();
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
}
