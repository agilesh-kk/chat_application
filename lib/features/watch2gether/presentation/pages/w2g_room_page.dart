import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/features/watch2gether/presentation/bloc/w2g_bloc.dart';
import 'package:chat_application/features/watch2gether/presentation/widgets/room_chat_overlay.dart';
import 'package:chat_application/features/watch2gether/presentation/widgets/video_player_widget.dart';
import 'package:chat_application/features/watch2gether/presentation/widgets/participant_avatars.dart';
import 'package:chat_application/features/watch2gether/presentation/widgets/queue_bottom_sheet.dart';
import 'package:chat_application/features/watch2gether/presentation/widgets/invite_friends_sheet.dart';
import 'package:chat_application/features/watch2gether/domain/entity/w2g_chat_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class W2GRoomPage extends StatefulWidget {
  final String roomId;
  final String userId;
  final String userName;
  final String userProfilePic;

  const W2GRoomPage({
    super.key,
    required this.roomId,
    required this.userId,
    this.userName = '',
    this.userProfilePic = '',
  });

  @override
  State<W2GRoomPage> createState() => _W2GRoomPageState();
}

class _W2GRoomPageState extends State<W2GRoomPage> {
  W2GChatMessage? _replyToMessage;
  bool _chatExpanded = false;

  @override
  void initState() {
    super.initState();
    context.read<W2GBloc>().add(W2GLoadRoom(
      roomId: widget.roomId,
      currentUserId: widget.userId,
      currentUserName: widget.userName,
      currentUserProfilePic: widget.userProfilePic,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.darkBg,
      appBar: _buildAppBar(),
      body: BlocBuilder<W2GBloc, W2GState>(
        builder: (context, state) {
          if (state is W2GLoading) {
            return const Center(child: CircularProgressIndicator(color: AppPallete.primaryOrange));
          }
          if (state is W2GError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: AppPallete.greyText, size: 48),
                  const SizedBox(height: 16),
                  Text(state.message, style: const TextStyle(color: AppPallete.greyText)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(backgroundColor: AppPallete.primaryOrange),
                    child: const Text('Go Back', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
          }
          if (state is W2GRoomLoaded) {
            return _buildRoomContent(state);
          }
          return const SizedBox();
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppPallete.darkTertiary,
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
          return const Text('Room', style: TextStyle(color: Colors.white));
        },
      ),
      actions: [
        BlocBuilder<W2GBloc, W2GState>(
          builder: (context, state) {
            if (state is! W2GRoomLoaded) return const SizedBox();
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ParticipantAvatars(
                  participants: state.room.participants.values.toList(),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  color: AppPallete.cardBg,
                  onSelected: (value) {
                    if (value == 'queue') {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => QueueBottomSheet(
                          queue: state.room.queue,
                          onAdd: (url) => context.read<W2GBloc>().add(W2GAddToQueue(
                            roomId: widget.roomId,
                            url: url,
                            title: url,
                            addedBy: widget.userId,
                          )),
                          onRemove: (itemId) => context.read<W2GBloc>().add(W2GRemoveFromQueue(
                            roomId: widget.roomId,
                            itemId: itemId,
                          )),
                        ),
                      );
                    }
                    if (value == 'invite') {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => InviteFriendsSheet(
                          roomId: widget.roomId,
                          roomName: state.room.name,
                          hostId: widget.userId,
                          hostName: widget.userName,
                        ),
                      );
                    }
                    if (value == 'leave') {
                      final isHost = state.room.hostId == widget.userId;
                      context.read<W2GBloc>().add(W2GLeaveRoom(
                        roomId: widget.roomId,
                        userId: widget.userId,
                        isHost: isHost,
                      ));
                      Navigator.pop(context);
                    }
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'queue', child: ListTile(
                      leading: Icon(Icons.queue_music, color: AppPallete.primaryOrange),
                      title: Text('Queue', style: TextStyle(color: Colors.white)),
                      dense: true,
                    )),
                    const PopupMenuItem(value: 'invite', child: ListTile(
                      leading: Icon(Icons.person_add_alt, color: AppPallete.primaryOrange),
                      title: Text('Invite Friends', style: TextStyle(color: Colors.white)),
                      dense: true,
                    )),
                    const PopupMenuItem(value: 'leave', child: ListTile(
                      leading: Icon(Icons.exit_to_app, color: Colors.redAccent),
                      title: Text('Leave Room', style: TextStyle(color: Colors.redAccent)),
                      dense: true,
                    )),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildRoomContent(W2GRoomLoaded state) {
    final room = state.room;
    final isHost = room.hostId == widget.userId;

    return Column(
      children: [
        Expanded(
          flex: _chatExpanded ? 3 : 5,
          child: GestureDetector(
            onTap: () => setState(() => _chatExpanded = false),
            child: VideoPlayerWidget(
              video: room.currentVideo,
              isPlaying: room.playerState.isPlaying,
              position: room.playerState.position,
              onPlayPause: (playing) {
                if (playing) {
                  context.read<W2GBloc>().add(W2GPlay(
                    roomId: widget.roomId,
                    userId: widget.userId,
                    position: room.playerState.position,
                  ));
                } else {
                  context.read<W2GBloc>().add(W2GPause(
                    roomId: widget.roomId,
                    userId: widget.userId,
                    position: room.playerState.position,
                  ));
                }
              },
              onSeek: (position) {
                context.read<W2GBloc>().add(W2GSeek(
                  roomId: widget.roomId,
                  userId: widget.userId,
                  position: position,
                ));
              },
              onPositionUpdate: (position) {
                context.read<W2GBloc>().add(W2GSyncPosition(
                  roomId: widget.roomId,
                  userId: widget.userId,
                  position: position,
                ));
              },
              onVideoEnded: () {
                context.read<W2GBloc>().add(W2GNext(
                  roomId: widget.roomId,
                  userId: widget.userId,
                ));
              },
              canControl: isHost || room.participants.length <= 1,
              backgroundPlayback: false,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => setState(() => _chatExpanded = !_chatExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppPallete.cardBg,
              border: Border(
                top: BorderSide(color: AppPallete.divider.withValues(alpha: 0.3)),
                bottom: BorderSide(color: AppPallete.divider.withValues(alpha: 0.3)),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _chatExpanded ? Icons.expand_more : Icons.expand_less,
                  color: AppPallete.primaryOrange,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Chat',
                  style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  '${room.participants.length} watching',
                  style: TextStyle(color: AppPallete.greyText.withValues(alpha: 0.7), fontSize: 12),
                ),
                const SizedBox(width: 8),
                ParticipantAvatars(
                  participants: room.participants.values.toList(),
                  maxDisplay: 3,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: _chatExpanded ? 5 : 3,
          child: RoomChatOverlay(
            messages: state.messages,
            typingUserIds: state.typingUserIds,
            currentUserId: widget.userId,
            currentUserName: widget.userName,
            replyToMessage: _replyToMessage,
            onSend: (text) {
              context.read<W2GBloc>().add(W2GSendMessage(
                roomId: widget.roomId,
                senderId: widget.userId,
                senderName: widget.userName,
                text: text,
                replyToId: _replyToMessage?.id,
                replyToContent: _replyToMessage?.text,
                replyToSenderId: _replyToMessage?.senderId,
                replyToType: _replyToMessage?.type,
              ));
              setState(() => _replyToMessage = null);
            },
            onSendImage: () {},
            onReply: (message) => setState(() => _replyToMessage = message),
            onCancelReply: () => setState(() => _replyToMessage = null),
            onReact: (messageId, emoji) {
              context.read<W2GBloc>().add(W2GToggleReaction(
                roomId: widget.roomId,
                messageId: messageId,
                userId: widget.userId,
                emoji: emoji,
              ));
            },
            onTyping: (isTyping) {
              context.read<W2GBloc>().add(W2GSetTyping(
                roomId: widget.roomId,
                userId: widget.userId,
                isTyping: isTyping,
              ));
            },
          ),
        ),
      ],
    );
  }
}
