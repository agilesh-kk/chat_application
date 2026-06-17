import 'dart:async';
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

  StreamSubscription<W2GRoom>? _roomSub;
  StreamSubscription<List<W2GChatMessage>>? _messagesSub;
  StreamSubscription<Map<String, W2GParticipant>>? _participantsSub;

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
  }) : super(W2GInitial()) {
    on<W2GLoadRoom>(_onLoadRoom);
    on<W2GJoinRoom>(_onJoinRoom);
    on<W2GLeaveRoom>(_onLeaveRoom);
    on<W2GPlay>(_onPlay);
    on<W2GPause>(_onPause);
    on<W2GSeek>(_onSeek);
    on<W2GSyncPosition>(_onSyncPosition);
    on<W2GNext>(_onNext);
    on<W2GAddToQueue>(_onAddToQueue);
    on<W2GRemoveFromQueue>(_onRemoveFromQueue);
    on<W2GSendMessage>(_onSendMessage);
    on<W2GCreateRoom>(_onCreateRoom);
    on<W2GLoadRooms>(_onLoadRooms);
    on<_W2GRoomStreamError>(_onRoomStreamError);
    on<_W2GRoomUpdated>(_onRoomUpdated);
    on<_W2GMessagesUpdated>(_onMessagesUpdated);
  }

  Future<void> _onLoadRoom(W2GLoadRoom event, Emitter<W2GState> emit) async {
    emit(W2GLoading());
    _roomSub?.cancel();
    _messagesSub?.cancel();
    _participantsSub?.cancel();

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

    final joinResult = await joinRoom(
      JoinRoomParams(
        roomId: event.roomId,
        participant: W2GParticipant(
          userId: event.currentUserId,
          name: '',
          profilePic: '',
          joinedAt: DateTime.now(),
        ),
      ),
    );
    joinResult.fold(
      (failure) => emit(W2GError(failure.message)),
      (_) {},
    );
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
    await leaveRoom(LeaveRoomParams(roomId: event.roomId, userId: event.userId));
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
      if (current.isPlaying) {
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
    final item = W2GVideoItem(
      id: const Uuid().v4(),
      url: event.url,
      title: event.title,
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
        ),
      ),
    );
  }

  Future<void> _onCreateRoom(
      W2GCreateRoom event, Emitter<W2GState> emit) async {
    emit(W2GLoading());
    final result = await createRoom(
      CreateRoomParams(name: event.name, createdBy: event.createdBy),
    );
    result.fold(
      (failure) => emit(W2GError(failure.message)),
      (roomId) => emit(W2GRoomCreated(roomId)),
    );
  }

  void _onRoomUpdated(_W2GRoomUpdated event, Emitter<W2GState> emit) {
    final current = state;
    if (current is W2GRoomLoaded) {
      emit(W2GRoomLoaded(room: event.room, messages: current.messages));
    } else {
      emit(W2GRoomLoaded(room: event.room));
    }
  }

  void _onMessagesUpdated(_W2GMessagesUpdated event, Emitter<W2GState> emit) {
    final current = state;
    if (current is W2GRoomLoaded) {
      emit(W2GRoomLoaded(room: current.room, messages: event.messages));
    }
  }

  void _onRoomStreamError(_W2GRoomStreamError event, Emitter<W2GState> emit) {
    emit(W2GError(event.message));
  }

  Future<void> _onLoadRooms(W2GLoadRooms event, Emitter<W2GState> emit) async {
    emit(W2GLoading());
    try {
      final rooms = await repository.getActiveRooms();
      emit(W2GRoomsLoaded(rooms));
    } catch (e) {
      emit(W2GError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _roomSub?.cancel();
    _messagesSub?.cancel();
    _participantsSub?.cancel();
    return super.close();
  }
}
