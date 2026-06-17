import 'package:chat_application/features/watch2gether/data/datasources/w2g_remote_data_source.dart';
import 'package:chat_application/features/watch2gether/data/model/w2g_chat_message_model.dart';
import 'package:chat_application/features/watch2gether/data/model/w2g_participant_model.dart';
import 'package:chat_application/features/watch2gether/data/model/w2g_video_item_model.dart';
import 'package:chat_application/features/watch2gether/domain/entity/w2g_chat_message.dart';
import 'package:chat_application/features/watch2gether/domain/entity/w2g_participant.dart';
import 'package:chat_application/features/watch2gether/domain/entity/w2g_room.dart';
import 'package:chat_application/features/watch2gether/domain/entity/w2g_video_item.dart';
import 'package:chat_application/features/watch2gether/domain/repository/w2g_repository.dart';

class W2GRepositoryImpl implements W2GRepository {
  final W2GRemoteDataSource _remoteDataSource;

  W2GRepositoryImpl(this._remoteDataSource);

  @override
  Future<String> createRoom(String name, String createdBy) {
    return _remoteDataSource.createRoom(name, createdBy);
  }

  @override
  Stream<W2GRoom> getRoomStream(String roomId) {
    return _remoteDataSource.getRoomStream(roomId);
  }

  @override
  Future<void> joinRoom(String roomId, W2GParticipant participant) async {
    final model = W2GParticipantModel(
      userId: participant.userId,
      name: participant.name,
      profilePic: participant.profilePic,
      joinedAt: participant.joinedAt,
    );
    await _remoteDataSource.joinRoom(roomId, model);
  }

  @override
  Future<void> leaveRoom(String roomId, String userId) {
    return _remoteDataSource.leaveRoom(roomId, userId);
  }

  @override
  Future<void> updatePlayerState(String roomId, W2GPlayerState state) {
    return _remoteDataSource.updatePlayerState(roomId, state);
  }

  @override
  Future<void> setCurrentVideo(String roomId, W2GVideoItem? video) async {
    final model = video != null
        ? W2GVideoItemModel(
            id: video.id,
            url: video.url,
            title: video.title,
            source: video.source,
            addedBy: video.addedBy,
            addedAt: video.addedAt,
          )
        : null;
    await _remoteDataSource.setCurrentVideo(roomId, model);
  }

  @override
  Future<void> addToQueue(String roomId, W2GVideoItem item) async {
    final model = W2GVideoItemModel(
      id: item.id,
      url: item.url,
      title: item.title,
      source: item.source,
      addedBy: item.addedBy,
      addedAt: item.addedAt,
    );
    await _remoteDataSource.addToQueue(roomId, model);
  }

  @override
  Future<void> removeFromQueue(String roomId, String itemId) {
    return _remoteDataSource.removeFromQueue(roomId, itemId);
  }

  @override
  Future<void> advanceQueue(String roomId) async {
    await _remoteDataSource.setCurrentVideo(roomId, null);
  }

  @override
  Future<void> sendMessage(String roomId, W2GChatMessage message) async {
    final model = W2GChatMessageModel(
      id: message.id,
      senderId: message.senderId,
      senderName: message.senderName,
      text: message.text,
      timestamp: message.timestamp,
    );
    await _remoteDataSource.sendMessage(roomId, model);
  }

  @override
  Stream<List<W2GChatMessage>> getMessagesStream(String roomId) {
    return _remoteDataSource.getMessagesStream(roomId).map(
      (models) => models.map((m) => m as W2GChatMessage).toList(),
    );
  }

  @override
  Stream<Map<String, W2GParticipant>> getParticipantsStream(String roomId) {
    return _remoteDataSource.getParticipantsStream(roomId).map((map) {
      return map.map((key, value) => MapEntry(key, value as W2GParticipant));
    });
  }

  @override
  Future<List<W2GRoom>> getActiveRooms() {
    return _remoteDataSource.getActiveRooms();
  }
}
