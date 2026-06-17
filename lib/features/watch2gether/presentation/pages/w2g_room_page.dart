import 'package:chat_application/core/common/cubit/app_user_cubit.dart';
import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/core/utils/show_snackbar.dart';
import 'package:chat_application/init_dependencies.dart';
import 'package:chat_application/features/friends/data/friend_model.dart';
import 'package:chat_application/features/friends/presentation/friends_cubit.dart';
import 'package:chat_application/features/watch2gether/domain/entity/w2g_chat_message.dart';
import 'package:chat_application/features/watch2gether/domain/entity/w2g_room.dart';
import 'package:chat_application/features/watch2gether/presentation/bloc/w2g_bloc.dart';
import 'package:chat_application/features/watch2gether/presentation/widgets/participant_avatars.dart';
import 'package:chat_application/features/watch2gether/presentation/widgets/queue_bottom_sheet.dart';
import 'package:chat_application/features/watch2gether/presentation/widgets/room_chat_overlay.dart';
import 'package:chat_application/features/watch2gether/presentation/widgets/video_player_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

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
  String _currentUserProfilePic = '';
  W2GChatMessage? _replyToMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bloc = serviceLocator<W2GBloc>();

    final userState = serviceLocator<AppUserCubit>().state;
    if (userState is AppUserIsSignedin) {
      _currentUserId = userState.user.id;
      _currentUserName = userState.user.name;
      _currentUserProfilePic = userState.user.profilePic ?? '';
    }

    _bloc.add(W2GLoadRoom(
      roomId: widget.roomId,
      currentUserId: _currentUserId,
      currentUserName: _currentUserName,
      currentUserProfilePic: _currentUserProfilePic,
    ));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Just pop back — room keeps running in the background
  void _goBack() {
    Navigator.pop(context);
  }

  // Actually leave the room (remove from participants), room stays for others
  void _exitRoom() {
    _bloc.add(W2GLeaveRoom(
      roomId: widget.roomId,
      userId: _currentUserId,
    ));
    Navigator.pop(context);
  }

  // Host only: permanently delete the room for everyone
  void _closeRoom() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppPallete.cardBg,
        title: const Text('Close Room', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will permanently delete the room for everyone. Continue?',
          style: TextStyle(color: AppPallete.greyText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppPallete.greyText)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _bloc.add(W2GDeleteRoom(
                roomId: widget.roomId,
                userId: _currentUserId,
              ));
              Navigator.pop(context);
            },
            child: const Text('Close Room', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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

  void _setTyping(bool isTyping) {
    _bloc.add(W2GSetTyping(
      roomId: widget.roomId,
      userId: _currentUserId,
      isTyping: isTyping,
    ));
  }

  void _pickAndSendImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    _bloc.add(W2GSendImage(
      roomId: widget.roomId,
      senderId: _currentUserId,
      senderName: _currentUserName,
      imagePath: image.path,
      replyToId: _replyToMessage?.id,
      replyToContent: _replyToMessage?.text,
      replyToSenderId: _replyToMessage?.senderId,
      replyToType: _replyToMessage?.type,
    ));
    setState(() => _replyToMessage = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.darkBg,
      appBar: AppBar(
        backgroundColor: AppPallete.darkBg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _goBack,
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
                final isHost = state.room.hostId == _currentUserId;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.exit_to_app, color: AppPallete.greyText),
                      tooltip: 'Exit Room',
                      onPressed: _exitRoom,
                    ),
                    if (isHost)
                      IconButton(
                        icon: const Icon(Icons.delete_forever, color: Colors.red),
                        tooltip: 'Close Room',
                        onPressed: _closeRoom,
                      ),
                    if (isHost)
                      IconButton(
                        icon: const Icon(Icons.person_add_alt, color: AppPallete.primaryOrange),
                        onPressed: () => _showInviteFriends(widget.roomId, state.room.name),
                      ),
                    ParticipantAvatars(participants: participants),
                  ],
                );
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
            if (state.message.contains('permission_denied') ||
                state.message.contains('does not exist')) {
              Navigator.pop(context);
            }
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
            final isHost = room.hostId == _currentUserId;
            return Column(
              children: [
                _buildPlayerSection(room, isHost),
                Expanded(
                  child: RoomChatOverlay(
                    messages: state.messages,
                    typingUserIds: state.typingUserIds,
                    currentUserId: _currentUserId,
                    currentUserName: _currentUserName,
                    replyToMessage: _replyToMessage,
                    onSend: (text) {
                      _bloc.add(W2GSendMessage(
                        roomId: widget.roomId,
                        senderId: _currentUserId,
                        senderName: _currentUserName,
                        text: text,
                        replyToId: _replyToMessage?.id,
                        replyToContent: _replyToMessage?.text,
                        replyToSenderId: _replyToMessage?.senderId,
                        replyToType: _replyToMessage?.type,
                      ));
                      setState(() => _replyToMessage = null);
                    },
                    onSendImage: _pickAndSendImage,
                    onReply: (message) {
                      setState(() => _replyToMessage = message);
                    },
                    onCancelReply: () {
                      setState(() => _replyToMessage = null);
                    },
                    onReact: (messageId, emoji) {
                      _bloc.add(W2GToggleReaction(
                        roomId: widget.roomId,
                        messageId: messageId,
                        userId: _currentUserId,
                        emoji: emoji,
                      ));
                    },
                    onTyping: _setTyping,
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

  Widget _buildPlayerSection(W2GRoom room, bool isHost) {
    return Column(
      children: [
        VideoPlayerWidget(
          video: room.currentVideo,
          isPlaying: room.playerState.isPlaying,
          position: room.playerState.position,
          currentUserId: _currentUserId,
          canControl: isHost,
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
            if (room.playerState.isPlaying && isHost) {
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
                      size: 64, color: AppPallete.greyText),
                  const SizedBox(height: 16),
                  Text(
                    'No video playing',
                    style: TextStyle(
                        color: AppPallete.greyText.withValues(alpha: 0.7),
                        fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add a video from the queue',
                    style: TextStyle(
                        color: AppPallete.greyText.withValues(alpha: 0.5),
                        fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  void _showInviteFriends(String roomId, String roomName) {
    final friendsCubit = serviceLocator<FriendsCubit>();
    final friendsState = friendsCubit.state;
    final friends = friendsState is FriendsLoaded ? friendsState.friends.values.toList() : <FriendModel>[];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _InviteFriendsSheet(
        friends: friends,
        roomId: roomId,
        roomName: roomName,
        hostId: _currentUserId,
        hostName: _currentUserName,
        onInvite: (friendId) {
          _bloc.add(W2GInviteFriend(
            roomId: roomId,
            roomName: roomName,
            hostId: _currentUserId,
            hostName: _currentUserName,
            invitedUserId: friendId,
          ));
        },
      ),
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

class _InviteFriendsSheet extends StatelessWidget {
  final List<FriendModel> friends;
  final String roomId;
  final String roomName;
  final String hostId;
  final String hostName;
  final void Function(String friendId) onInvite;

  const _InviteFriendsSheet({
    required this.friends,
    required this.roomId,
    required this.roomName,
    required this.hostId,
    required this.hostName,
    required this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppPallete.cardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppPallete.greyText,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Invite Friends',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Invite friends to join "$roomName"',
            style: TextStyle(color: AppPallete.greyText, fontSize: 13),
          ),
          const SizedBox(height: 16),
          if (friends.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'No friends to invite',
                  style: TextStyle(color: AppPallete.greyText.withValues(alpha: 0.5)),
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: friends.length,
                separatorBuilder: (_, _) => const Divider(color: AppPallete.divider, height: 1),
                itemBuilder: (context, index) {
                  final friend = friends[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundImage: friend.profilePic.isNotEmpty
                          ? NetworkImage(friend.profilePic)
                          : null,
                      backgroundColor: AppPallete.darkTertiary,
                      child: friend.profilePic.isEmpty
                          ? Text(friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?',
                              style: const TextStyle(color: Colors.white))
                          : null,
                    ),
                    title: Text(friend.name, style: const TextStyle(color: Colors.white, fontSize: 14)),
                    subtitle: Text(friend.email, style: TextStyle(color: AppPallete.greyText, fontSize: 12)),
                    trailing: IconButton(
                      icon: const Icon(Icons.send, color: AppPallete.primaryOrange, size: 20),
                      onPressed: () {
                        onInvite(friend.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Invite sent to ${friend.name}'),
                            backgroundColor: AppPallete.primaryOrange,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
