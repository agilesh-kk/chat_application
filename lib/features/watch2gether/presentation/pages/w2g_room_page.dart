import 'package:chat_application/core/common/cubit/app_user_cubit.dart';
import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/core/utils/show_snackbar.dart';
import 'package:chat_application/init_dependencies.dart';
import 'package:chat_application/features/watch2gether/domain/entity/w2g_room.dart';
import 'package:chat_application/features/watch2gether/presentation/bloc/w2g_bloc.dart';
import 'package:chat_application/features/watch2gether/presentation/widgets/participant_avatars.dart';
import 'package:chat_application/features/watch2gether/presentation/widgets/queue_bottom_sheet.dart';
import 'package:chat_application/features/watch2gether/presentation/widgets/room_chat_overlay.dart';
import 'package:chat_application/features/watch2gether/presentation/widgets/video_player_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class W2GRoomPage extends StatefulWidget {
  final String roomId;

  const W2GRoomPage({super.key, required this.roomId});

  @override
  State<W2GRoomPage> createState() => _W2GRoomPageState();
}

class _W2GRoomPageState extends State<W2GRoomPage>
    with WidgetsBindingObserver {
  late final W2GBloc _bloc;
  String _currentUserId = '';
  String _currentUserName = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bloc = serviceLocator<W2GBloc>();

    final userState = serviceLocator<AppUserCubit>().state;
    if (userState is AppUserIsSignedin) {
      _currentUserId = userState.user.id;
      _currentUserName = userState.user.name;
    }

    _bloc.add(W2GLoadRoom(
      roomId: widget.roomId,
      currentUserId: _currentUserId,
    ));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bloc.add(W2GLeaveRoom(
      roomId: widget.roomId,
      userId: _currentUserId,
    ));
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _bloc.add(W2GPause(
        roomId: widget.roomId,
        userId: _currentUserId,
        position: 0,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppPallete.darkBg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: BlocBuilder<W2GBloc, W2GState>(
          builder: (context, state) {
            if (state is W2GRoomLoaded) {
              return Text(
                state.room.name,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              );
            }
            return const Text('Loading...',
                style: TextStyle(color: Colors.white));
          },
        ),
        actions: [
          BlocBuilder<W2GBloc, W2GState>(
            builder: (context, state) {
              if (state is W2GRoomLoaded) {
                final participants =
                    state.room.participants.values.toList();
                return ParticipantAvatars(participants: participants);
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.queue_music, color: AppPallete.primaryOrange),
            onPressed: _showQueue,
          ),
        ],
      ),
      body: BlocConsumer<W2GBloc, W2GState>(
        listener: (context, state) {
          if (state is W2GError) {
            showSnackbar(context, state.message);
          }
        },
        builder: (context, state) {
          if (state is W2GLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppPallete.primaryOrange),
            );
          }

          if (state is W2GRoomLoaded) {
            final room = state.room;
            return Column(
              children: [
                _buildPlayerSection(room),
                Expanded(
                  child: RoomChatOverlay(
                    messages: state.messages,
                    onSend: (text) {
                      _bloc.add(W2GSendMessage(
                        roomId: widget.roomId,
                        senderId: _currentUserId,
                        senderName: _currentUserName,
                        text: text,
                      ));
                    },
                    currentUserId: _currentUserId,
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildPlayerSection(W2GRoom room) {
    return Column(
      children: [
        VideoPlayerWidget(
          video: room.currentVideo,
          isPlaying: room.playerState.isPlaying,
          position: room.playerState.position,
          currentUserId: _currentUserId,
          onPlayPause: (isPlaying) {
            if (isPlaying) {
              _bloc.add(W2GPlay(
                roomId: widget.roomId,
                userId: _currentUserId,
                position: room.playerState.position,
              ));
            } else {
              _bloc.add(W2GPause(
                roomId: widget.roomId,
                userId: _currentUserId,
                position: room.playerState.position,
              ));
            }
          },
          onSeek: (position) {
            _bloc.add(W2GSeek(
              roomId: widget.roomId,
              userId: _currentUserId,
              position: position,
            ));
          },
          onPositionUpdate: (position) {
            if (room.playerState.isPlaying &&
                room.playerState.updatedBy == _currentUserId) {
              _bloc.add(W2GSyncPosition(
                roomId: widget.roomId,
                userId: _currentUserId,
                position: position,
              ));
            }
          },
          onVideoEnded: () {
            _bloc.add(W2GNext(
              roomId: widget.roomId,
              userId: _currentUserId,
            ));
          },
        ),
        if (room.currentVideo == null)
          SizedBox(
            height: 180,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.movie_creation_outlined,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No video playing',
                    style: TextStyle(
                        color: Colors.grey.withValues(alpha: 0.7),
                        fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add a video from the queue',
                    style: TextStyle(
                        color: Colors.grey.withValues(alpha: 0.5),
                        fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showQueue() {
    final state = _bloc.state;
    if (state is! W2GRoomLoaded) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => QueueBottomSheet(
        queue: state.room.queue,
        onAdd: (url) {
          _bloc.add(W2GAddToQueue(
            roomId: widget.roomId,
            url: url,
            title: url,
            addedBy: _currentUserId,
          ));
        },
        onRemove: (itemId) {
          _bloc.add(W2GRemoveFromQueue(
            roomId: widget.roomId,
            itemId: itemId,
          ));
        },
      ),
    );
  }
}
