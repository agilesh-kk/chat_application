import 'package:chat_application/features/watch2gether/domain/entity/w2g_chat_message.dart';
import 'package:chat_application/features/watch2gether/domain/entity/w2g_participant.dart';
import 'package:chat_application/features/watch2gether/domain/entity/w2g_room.dart';
import 'package:chat_application/features/watch2gether/domain/entity/w2g_video_item.dart';

abstract interface class W2GRepository {
  Future<String> createRoom(String name, String createdBy);
  Stream<W2GRoom> getRoomStream(String roomId);
  Future<void> joinRoom(String roomId, W2GParticipant participant);
  Future<void> leaveRoom(String roomId, String userId);
  Future<void> updatePlayerState(String roomId, W2GPlayerState state);
  Future<void> setCurrentVideo(String roomId, W2GVideoItem? video);
  Future<void> addToQueue(String roomId, W2GVideoItem item);
  Future<void> removeFromQueue(String roomId, String itemId);
  Future<void> advanceQueue(String roomId);
  Future<void> sendMessage(String roomId, W2GChatMessage message);
  Stream<List<W2GChatMessage>> getMessagesStream(String roomId);
  Stream<Map<String, W2GParticipant>> getParticipantsStream(String roomId);
  Future<List<W2GRoom>> getActiveRooms();
}
