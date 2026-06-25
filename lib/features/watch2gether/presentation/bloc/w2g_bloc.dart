import 'dart:async';
import 'package:chat_application/features/watch2gether/data/services/video_controller_service.dart';
import 'package:chat_application/features/watch2gether/domain/entity/w2g_chat_message.dart';
import 'package:chat_application/features/watch2gether/domain/entity/w2g_participant.dart';
import 'package:chat_application/features/watch2gether/domain/entity/w2g_room.dart';
import 'package:chat_application/features/watch2gether/domain/entity/w2g_video_item.dart';
import 'package:chat_application/features/watch2gether/domain/usecase/add_to_queue.dart';
import 'package:chat_application/features/watch2gether/domain/usecase/create_room.dart';
import 'package:chat_application/features/watch2gether/domain/usecase/get_room_stream.dart';
import 'package:chat_application/features/watch2gether/domain/usecase/join_room.dart';
import 'package:chat_application/features/watch2gether/domain/usecase/leave_room.dart';
import 'package:chat_application/features/watch2gether/domain/usecase/remove_from_queue.dart';
import 'package:chat_application/features/watch2gether/domain/usecase/send_chat_message.dart';
import 'package:chat_application/features/watch2gether/domain/repository/w2g_repository.dart';
import 'package:chat_application/features/watch2gether/domain/usecase/update_player_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_database/firebase_database.dart';

part 'w2g_event.dart';
part 'w2g_state.dart';

class W2GBloc extends Bloc<W2GEvent, W2GState> {
  final CreateRoom createRoom;
  final GetRoomStream getRoomStream;
  final JoinRoom joinRoom;
  final LeaveRoom leaveRoom;
  final UpdatePlayerState updatePlayerState;
  final AddToQueue addToQueue;
  final RemoveFromQueue removeFromQueue;
  final SendChatMessage sendChatMessage;
  final W2GRepository repository;
  final FirebaseDatabase _database;
  final VideoControllerService videoService;
  String? _currentUserId;

  StreamSubscription<W2GRoom>? _roomSub;
  StreamSubscription<List<W2GChatMessage>>? _messagesSub;
  StreamSubscription<Map<String, W2GParticipant>>? _participantsSub;
  StreamSubscription<DatabaseEvent>? _typingSub;

  W2GBloc({
    required this.createRoom,
    required this.getRoomStream,
    required this.joinRoom,
    required this.leaveRoom,
    required this.updatePlayerState,
    required this.addToQueue,
    required this.removeFromQueue,
    required this.sendChatMessage,
    required this.repository,
    required FirebaseDatabase database,
    required this.videoService,
  })  : _database = database,
       super(W2GInitial()) {
    on<W2GLoadRoom>(_onLoadRoom);
    on<W2GJoinRoom>(_onJoinRoom);
    on<W2GLeaveRoom>(_onLeaveRoom);
    on<W2GDeleteRoom>(_onDeleteRoom);
    on<W2GPlay>(_onPlay);
    on<W2GPause>(_onPause);
    on<W2GSeek>(_onSeek);
    on<W2GSyncPosition>(_onSyncPosition);
    on<W2GNext>(_onNext);
    on<W2GAddToQueue>(_onAddToQueue);
    on<W2GRemoveFromQueue>(_onRemoveFromQueue);
    on<W2GSendMessage>(_onSendMessage);
    on<W2GSendImage>(_onSendImage);
    on<W2GCreateRoom>(_onCreateRoom);
    on<W2GLoadRooms>(_onLoadRooms);
    on<W2GJoinRoomByCode>(_onJoinRoomByCode);
    on<W2GInviteFriend>(_onInviteFriend);
    on<W2GToggleReaction>(_onToggleReaction);
    on<W2GSetTyping>(_onSetTyping);
    on<_W2GRoomStreamError>(_onRoomStreamError);
    on<_W2GRoomUpdated>(_onRoomUpdated);
    on<_W2GMessagesUpdated>(_onMessagesUpdated);
    on<_W2GTypingUpdated>(_onTypingUpdated);
  }

  Future<void> _onLoadRoom(W2GLoadRoom event, Emitter<W2GState> emit) async {
    _currentUserId = event.currentUserId;
    emit(W2GLoading());
    _roomSub?.cancel();
    _messagesSub?.cancel();
    _participantsSub?.cancel();
    _typingSub?.cancel();

    final result = await getRoomStream(event.roomId);
    result.fold(
      (failure) => emit(W2GError(failure.message)),
      (stream) {
        _roomSub = stream.listen((room) {
          if (!isClosed) {
            add(_W2GRoomUpdated(room));
          }
        }, onError: (e) {
          if (!isClosed) add(_W2GRoomStreamError(e.toString()));
        });
      },
    );

    _messagesSub = repository.getMessagesStream(event.roomId).listen((messages) {
      if (!isClosed) {
        add(_W2GMessagesUpdated(messages));
      }
    });

    _setupTypingListener(event.roomId);

    await repository.setUserActiveRoom(event.currentUserId, event.roomId);

    final joinResult = await joinRoom(
      JoinRoomParams(
        roomId: event.roomId,
        participant: W2GParticipant(
          userId: event.currentUserId,
          name: event.currentUserName,
          profilePic: event.currentUserProfilePic,
          joinedAt: DateTime.now(),
        ),
      ),
    );
    joinResult.fold(
      (failure) => emit(W2GError(failure.message)),
      (_) {},
    );
  }

  void _setupTypingListener(String roomId) {
    _typingSub = _database
        .ref('watch2gether/rooms/$roomId/typing')
        .onValue
        .listen((event) {
      if (isClosed) return;
      final map = (event.snapshot.value as Map?)?.cast<String, dynamic>() ?? {};
      final typingIds = <String>{};
      map.forEach((key, value) {
        if (value is Map && value['isTyping'] == true) {
          typingIds.add(key);
        }
      });
      add(_W2GTypingUpdated(typingIds));
    });
  }

  Future<void> _onJoinRoom(W2GJoinRoom event, Emitter<W2GState> emit) async {
    await joinRoom(
      JoinRoomParams(
        roomId: event.roomId,
        participant: W2GParticipant(
          userId: event.userId,
          name: event.userName,
          profilePic: event.userProfilePic,
          joinedAt: DateTime.now(),
        ),
      ),
    );
  }

  Future<void> _onLeaveRoom(
      W2GLeaveRoom event, Emitter<W2GState> emit) async {
    _roomSub?.cancel();
    _messagesSub?.cancel();
    _participantsSub?.cancel();
    _typingSub?.cancel();
    videoService.dispose();
    if (event.isHost) {
      await repository.deleteRoom(event.roomId);
    } else {
      await leaveRoom(LeaveRoomParams(roomId: event.roomId, userId: event.userId));
    }
    await repository.removeUserActiveRoom(event.userId);

    try {
      final activeRoomId = await repository.getUserActiveRoom(event.userId);
      W2GRoom? activeRoom;
      if (activeRoomId != null) {
        final rooms = await repository.getActiveRooms();
        activeRoom = rooms.where((r) => r.id == activeRoomId).firstOrNull;
      }
      emit(W2GHomeLoaded(activeRoom: activeRoom));
    } catch (e) {
      emit(W2GError(e.toString()));
    }
  }

  Future<void> _onDeleteRoom(W2GDeleteRoom event, Emitter<W2GState> emit) async {
    _roomSub?.cancel();
    _messagesSub?.cancel();
    _participantsSub?.cancel();
    _typingSub?.cancel();
    videoService.dispose();
    await repository.deleteRoom(event.roomId);
    await repository.removeUserActiveRoom(event.userId);
  }

  Future<void> _onPlay(W2GPlay event, Emitter<W2GState> emit) async {
    await updatePlayerState(
      UpdatePlayerStateParams(
        roomId: event.roomId,
        state: W2GPlayerState(
          isPlaying: true,
          position: event.position,
          updatedBy: event.userId,
          lastUpdated: DateTime.now(),
        ),
      ),
    );
  }

  Future<void> _onPause(W2GPause event, Emitter<W2GState> emit) async {
    await updatePlayerState(
      UpdatePlayerStateParams(
        roomId: event.roomId,
        state: W2GPlayerState(
          isPlaying: false,
          position: event.position,
          updatedBy: event.userId,
          lastUpdated: DateTime.now(),
        ),
      ),
    );
  }

  Future<void> _onSeek(W2GSeek event, Emitter<W2GState> emit) async {
    final currentPlaying = state is W2GRoomLoaded
        ? (state as W2GRoomLoaded).room.playerState.isPlaying
        : false;
    await updatePlayerState(
      UpdatePlayerStateParams(
        roomId: event.roomId,
        state: W2GPlayerState(
          isPlaying: currentPlaying,
          position: event.position,
          updatedBy: event.userId,
          lastUpdated: DateTime.now(),
        ),
      ),
    );
  }

  Future<void> _onNext(W2GNext event, Emitter<W2GState> emit) async {
    final current = state;
    if (current is! W2GRoomLoaded) return;

    final queue = List<W2GVideoItem>.from(current.room.queue)
      ..sort((a, b) => a.addedAt.compareTo(b.addedAt));

    if (queue.isEmpty) {
      await repository.setCurrentVideo(event.roomId, null);
      await updatePlayerState(
        UpdatePlayerStateParams(
          roomId: event.roomId,
          state: W2GPlayerState(
            isPlaying: false,
            position: 0,
            updatedBy: event.userId,
            lastUpdated: DateTime.now(),
          ),
        ),
      );
      return;
    }

    final next = queue.first;
    await repository.setCurrentVideo(event.roomId, next);
    await repository.removeFromQueue(event.roomId, next.id);
    await updatePlayerState(
      UpdatePlayerStateParams(
        roomId: event.roomId,
        state: W2GPlayerState(
          isPlaying: true,
          position: 0,
          updatedBy: event.userId,
          lastUpdated: DateTime.now(),
        ),
      ),
    );
  }

  Future<void> _onSyncPosition(
      W2GSyncPosition event, Emitter<W2GState> emit) async {
    if (state is W2GRoomLoaded) {
      final current = (state as W2GRoomLoaded).room.playerState;
      if (current.isPlaying && current.updatedBy == event.userId) {
        await updatePlayerState(
          UpdatePlayerStateParams(
            roomId: event.roomId,
            state: current.copyWith(
              position: event.position,
              updatedBy: event.userId,
              lastUpdated: DateTime.now(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _onAddToQueue(
      W2GAddToQueue event, Emitter<W2GState> emit) async {
    String videoTitle = event.title;
    String? videoThumbnail = event.thumbnailUrl;
    if (W2GVideoItem.detectSource(event.url) == W2GVideoSource.youtube) {
      final videoId = _parseYoutubeVideoId(event.url);
      if (videoId != null) {
        videoThumbnail ??= 'https://img.youtube.com/vi/$videoId/mqdefault.jpg';
      }
    }
    final item = W2GVideoItem(
      id: const Uuid().v4(),
      url: event.url,
      title: videoTitle,
      thumbnailUrl: videoThumbnail,
      source: W2GVideoItem.detectSource(event.url),
      addedBy: event.addedBy,
      addedAt: DateTime.now(),
    );
    await addToQueue(
      AddToQueueParams(roomId: event.roomId, item: item),
    );

    final current = state;
    if (current is W2GRoomLoaded && current.room.currentVideo == null) {
      await repository.setCurrentVideo(event.roomId, item);
      await repository.removeFromQueue(event.roomId, item.id);
      await updatePlayerState(
        UpdatePlayerStateParams(
          roomId: event.roomId,
          state: W2GPlayerState(
            isPlaying: true,
            position: 0,
            updatedBy: event.addedBy,
            lastUpdated: DateTime.now(),
          ),
        ),
      );
    }
  }

  Future<void> _onRemoveFromQueue(
      W2GRemoveFromQueue event, Emitter<W2GState> emit) async {
    await removeFromQueue(
      RemoveFromQueueParams(roomId: event.roomId, itemId: event.itemId),
    );
  }

  Future<void> _onSendMessage(
      W2GSendMessage event, Emitter<W2GState> emit) async {
    await sendChatMessage(
      SendChatMessageParams(
        roomId: event.roomId,
        message: W2GChatMessage(
          id: const Uuid().v4(),
          senderId: event.senderId,
          senderName: event.senderName,
          text: event.text,
          timestamp: DateTime.now(),
          type: 'text',
          replyToId: event.replyToId,
          replyToContent: event.replyToContent,
          replyToSenderId: event.replyToSenderId,
          replyToType: event.replyToType,
        ),
      ),
    );
  }

  Future<void> _onSendImage(
      W2GSendImage event, Emitter<W2GState> emit) async {
    final msgId = const Uuid().v4();
    String? imageUrl;
    try {
      imageUrl = await repository.uploadImage(event.imagePath, msgId);
    } catch (_) {}

    await sendChatMessage(
      SendChatMessageParams(
        roomId: event.roomId,
        message: W2GChatMessage(
          id: msgId,
          senderId: event.senderId,
          senderName: event.senderName,
          text: '',
          timestamp: DateTime.now(),
          type: 'image',
          imageUrl: imageUrl,
          localPath: event.imagePath,
          replyToId: event.replyToId,
          replyToContent: event.replyToContent,
          replyToSenderId: event.replyToSenderId,
          replyToType: event.replyToType,
        ),
      ),
    );
  }

  Future<void> _onCreateRoom(
      W2GCreateRoom event, Emitter<W2GState> emit) async {
    emit(W2GLoading());
    final existing = await repository.getUserActiveRoom(event.createdBy);
    if (existing != null) {
      emit(W2GError('You already have an active room'));
      return;
    }
    final result = await createRoom(
      CreateRoomParams(name: event.name, createdBy: event.createdBy),
    );
    await result.fold(
      (failure) async => emit(W2GError(failure.message)),
      (roomId) async {
        await repository.setUserActiveRoom(event.createdBy, roomId);
        emit(W2GRoomCreated(roomId: roomId, roomName: event.name, createdBy: event.createdBy));
      },
    );
  }

  void _onRoomUpdated(_W2GRoomUpdated event, Emitter<W2GState> emit) {
    videoService.syncFromRoom(event.room, _currentUserId);
    final current = state;
    if (current is W2GRoomLoaded) {
      emit(W2GRoomLoaded(
        room: event.room,
        messages: current.messages,
        typingUserIds: current.typingUserIds,
      ));
    } else {
      emit(W2GRoomLoaded(room: event.room));
    }
  }

  void _onMessagesUpdated(_W2GMessagesUpdated event, Emitter<W2GState> emit) {
    final current = state;
    if (current is W2GRoomLoaded) {
      emit(W2GRoomLoaded(
        room: current.room,
        messages: event.messages,
        typingUserIds: current.typingUserIds,
      ));
    }
  }

  void _onRoomStreamError(_W2GRoomStreamError event, Emitter<W2GState> emit) {
    emit(W2GError(event.message));
  }

  Future<void> _onLoadRooms(W2GLoadRooms event, Emitter<W2GState> emit) async {
    final previousRoom = state is W2GRoomLoaded ? (state as W2GRoomLoaded).room : null;
    emit(W2GLoading());
    try {
      final activeRoomId = await repository.getUserActiveRoom(event.userId);
      W2GRoom? activeRoom;
      if (activeRoomId != null) {
        final rooms = await repository.getActiveRooms();
        activeRoom = rooms.where((r) => r.id == activeRoomId).firstOrNull;
      }
      emit(W2GHomeLoaded(activeRoom: activeRoom ?? (activeRoomId == null ? previousRoom : null)));
    } catch (e) {
      emit(W2GError(e.toString()));
    }
  }

  Future<void> _onJoinRoomByCode(W2GJoinRoomByCode event, Emitter<W2GState> emit) async {
    final existing = await repository.getUserActiveRoom(event.userId);
    if (existing != null) {
      emit(W2GError('You are already in a room. Leave it first to join another.'));
      return;
    }
    final rooms = await repository.getActiveRooms();
    final room = rooms.where((r) => r.id == event.roomId).firstOrNull;
    if (room == null) {
      emit(W2GError('Room not found'));
      return;
    }
    await repository.setUserActiveRoom(event.userId, event.roomId);
    await joinRoom(
      JoinRoomParams(
        roomId: event.roomId,
        participant: W2GParticipant(
          userId: event.userId,
          name: event.userName,
          profilePic: event.userProfilePic,
          joinedAt: DateTime.now(),
        ),
      ),
    );
    emit(W2GRoomCreated(roomId: event.roomId, roomName: room.name, createdBy: event.userId));
  }

  Future<void> _onInviteFriend(W2GInviteFriend event, Emitter<W2GState> emit) async {
    await repository.sendInvite(
      event.roomId,
      event.roomName,
      event.hostId,
      event.hostName,
      event.invitedUserId,
    );
  }

  Future<void> _onToggleReaction(W2GToggleReaction event, Emitter<W2GState> emit) async {
    await repository.toggleReaction(
      event.roomId,
      event.messageId,
      event.userId,
      event.emoji,
    );
  }

  Future<void> _onSetTyping(W2GSetTyping event, Emitter<W2GState> emit) async {
    await _database
        .ref('watch2gether/rooms/${event.roomId}/typing/${event.userId}')
        .set({
      'isTyping': event.isTyping,
      'timestamp': ServerValue.timestamp,
    });
    if (event.isTyping) {
      await _database
          .ref('watch2gether/rooms/${event.roomId}/typing/${event.userId}')
          .onDisconnect()
          .remove();
    }
  }

  void _onTypingUpdated(_W2GTypingUpdated event, Emitter<W2GState> emit) {
    final current = state;
    if (current is W2GRoomLoaded) {
      emit(W2GRoomLoaded(
        room: current.room,
        messages: current.messages,
        typingUserIds: event.typingUserIds,
      ));
    }
  }

  String? _parseYoutubeVideoId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final host = uri.host.toLowerCase();
    if (host.contains('youtu.be')) {
      final segs = uri.pathSegments;
      if (segs.isNotEmpty) return segs.first;
    }
    if (host.contains('youtube.com')) {
      if (uri.path.contains('/embed/') || uri.path.contains('/shorts/')) {
        final segs = uri.pathSegments;
        if (segs.length >= 2) return segs[1];
      }
      final v = uri.queryParameters['v'];
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  @override
  Future<void> close() {
    _roomSub?.cancel();
    _messagesSub?.cancel();
    _participantsSub?.cancel();
    _typingSub?.cancel();
    return super.close();
  }
}
