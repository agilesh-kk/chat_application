import 'package:chat_application/features/watch2gether/domain/entity/w2g_participant.dart';
import 'package:chat_application/features/watch2gether/domain/entity/w2g_video_item.dart';

class W2GRoom {
  final String id;
  final String name;
  final String createdBy;
  final DateTime createdAt;
  final W2GVideoItem? currentVideo;
  final List<W2GVideoItem> queue;
  final Map<String, W2GParticipant> participants;
  final W2GPlayerState playerState;

  W2GRoom({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.createdAt,
    this.currentVideo,
    this.queue = const [],
    this.participants = const {},
    this.playerState = const W2GPlayerState(),
  });

  W2GRoom copyWith({
    String? id,
    String? name,
    String? createdBy,
    DateTime? createdAt,
    W2GVideoItem? currentVideo,
    List<W2GVideoItem>? queue,
    Map<String, W2GParticipant>? participants,
    W2GPlayerState? playerState,
  }) {
    return W2GRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      currentVideo: currentVideo ?? this.currentVideo,
      queue: queue ?? this.queue,
      participants: participants ?? this.participants,
      playerState: playerState ?? this.playerState,
    );
  }
}

class W2GPlayerState {
  final bool isPlaying;
  final double position;
  final String updatedBy;
  final DateTime? lastUpdated;

  const W2GPlayerState({
    this.isPlaying = false,
    this.position = 0.0,
    this.updatedBy = '',
    this.lastUpdated,
  });

  W2GPlayerState copyWith({
    bool? isPlaying,
    double? position,
    String? updatedBy,
    DateTime? lastUpdated,
  }) {
    return W2GPlayerState(
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      updatedBy: updatedBy ?? this.updatedBy,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
