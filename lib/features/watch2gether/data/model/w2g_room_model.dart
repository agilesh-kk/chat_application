import 'package:chat_application/features/watch2gether/data/model/w2g_participant_model.dart';
import 'package:chat_application/features/watch2gether/data/model/w2g_video_item_model.dart';
import 'package:chat_application/features/watch2gether/domain/entity/w2g_room.dart';

class W2GRoomModel extends W2GRoom {
  W2GRoomModel({
    required super.id,
    required super.name,
    required super.createdBy,
    required super.hostId,
    required super.createdAt,
    super.currentVideo,
    super.queue,
    super.participants,
    super.playerState,
  });

  factory W2GRoomModel.fromMap(String id, Map<String, dynamic> map) {
    final currentVideoData =
        (map['currentVideo'] as Map?)?.cast<String, dynamic>();
    final queueData =
        (map['queue'] as Map?)?.cast<String, dynamic>() ?? {};
    final participantsData =
        (map['participants'] as Map?)?.cast<String, dynamic>() ?? {};

    final playerData =
        (map['playerState'] as Map?)?.cast<String, dynamic>() ?? {};

    return W2GRoomModel(
      id: id,
      name: map['name'] as String? ?? '',
      createdBy: map['createdBy'] as String? ?? '',
      hostId: map['hostId'] as String? ?? map['createdBy'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (map['createdAt'] as num).toInt())
          : DateTime.now(),
      currentVideo: currentVideoData != null
          ? W2GVideoItemModel.fromMap(
              'current', currentVideoData)
          : null,
      queue: queueData.entries.map((e) {
        return W2GVideoItemModel.fromMap(e.key, (e.value as Map).cast<String, dynamic>());
      }).toList(),
      participants: participantsData.map((key, value) {
        return MapEntry(
          key,
          W2GParticipantModel.fromMap(
              key, (value as Map).cast<String, dynamic>()),
        );
      }),
      playerState: W2GPlayerState(
        isPlaying: playerData['isPlaying'] as bool? ?? false,
        position: (playerData['position'] as num?)?.toDouble() ?? 0.0,
        updatedBy: playerData['updatedBy'] as String? ?? '',
        lastUpdated: playerData['lastUpdated'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                (playerData['lastUpdated'] as num).toInt())
            : null,
      ),
    );
  }
}
