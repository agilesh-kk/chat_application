// ignore_for_file: must_be_immutable
import 'dart:async';
import 'package:chat_application/core/common/cubit/app_user_cubit.dart';
import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/features/chats/presentation/helper/cacheservice.dart';
import 'package:chat_application/features/chats/presentation/pages/time_capsule_messages.dart';
import 'package:chat_application/features/chats/presentation/widgets/image_tile.dart';
import 'package:chat_application/features/chats/presentation/widgets/message_bubble.dart';
import 'package:chat_application/features/chats/presentation/widgets/delete_message_confirmation_dialog.dart';
import 'package:chat_application/features/chats/presentation/widgets/send_options_dialog.dart';
import 'package:chat_application/features/chats/presentation/widgets/time_capsule_picker.dart';
import 'package:chat_application/features/timeline/presentation/pages/timeline_page.dart';
import 'package:chat_application/features/friends/data/friend_model.dart';
import 'package:chat_application/features/friends/presentation/friends_cubit.dart';
import 'package:chat_application/features/profile/presentation/pages/profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:intl/intl.dart';

import 'package:chat_application/features/chats/presentation/bloc/chat/chat_bloc.dart';
import 'package:chat_application/features/chats/domain/entities/message.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chat_application/features/chats/presentation/cubit/sticky_header_cubit.dart';

class ChatPage extends StatefulWidget {
  final String? convoId;
  final String currentUserId;
  final String receiverId;
  final String receiverName;
  int? scrolltoIndex;
  CacheService? cacheService;
  String? highlightMessageId;

  ChatPage({
    super.key,
    this.convoId,
    required this.currentUserId,
    required this.receiverId,
    required this.receiverName,
    this.scrolltoIndex,
    this.highlightMessageId,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController controller = TextEditingController();
  late final ChatBloc cb;
  int? highlightedIndex;
  String lastAnimated = "";
  bool firstTime = true;

  final ItemScrollController _scrollController = ItemScrollController();
  final ItemPositionsListener _positionsListener = ItemPositionsListener.create();
  late final StickyHeaderCubit _stickyHeaderCubit;

  @override
  void initState() {
    super.initState();
    _stickyHeaderCubit = StickyHeaderCubit();
    widget.cacheService = CacheService();
    cb = context.read<ChatBloc>()
      ..add(LoadMessagesEvent(userId: widget.currentUserId, receiverId: widget.receiverId));
    context.read<ChatBloc>().add(
        MarkMessagesDeliveredEvent(userId: widget.currentUserId, receiverId: widget.receiverId));
  }

  @override
  void dispose() {
    _stickyHeaderCubit.close();
    cb.add(Closechat());
    super.dispose();
  }

  void _onScrollPositionChanged() {
    final positions = _positionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    // With reverse: true, itemTrailingEdge=top of item (0=bottom, 1=top of viewport)
    final visibleItems = positions
        .where((p) => p.itemTrailingEdge >= 0 && p.itemTrailingEdge <= 1.0)
        .toList()
      ..sort((a, b) => (a.itemTrailingEdge - 1.0).abs().compareTo((b.itemTrailingEdge - 1.0).abs()));

    if (visibleItems.isEmpty) return;

    final topIndex = visibleItems.first.index;
    final state = cb.state;
    if (state is ChatLoaded && topIndex < state.messages.length) {
      final message = state.messages[topIndex];
      final newLabel = _getDateLabel(message.createdAt);
      _stickyHeaderCubit.updateDateLabel(newLabel);
    }
  }

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(date.year, date.month, date.day);
    if (msgDate == today) return "Today";
    if (msgDate == yesterday) return "Yesterday";
    return DateFormat('MMMM d, y').format(date);
  }

  void _scrollToIndex(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.isAttached) {
        _scrollController.scrollTo(
            index: index, duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
      }
    });
  }

  void _send() {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    final user = context.read<AppUserCubit>().state;
    context.read<ChatBloc>().add(SendMessageEvent(
          userId: widget.currentUserId,
          receiverId: widget.receiverId,
          content: text,
          userName: (user is AppUserIsSignedin) ? user.user.name : "Unknown",
          userProfile: (user is AppUserIsSignedin) ? user.user.profilePic : "Unknown",
        ));
    controller.clear();
  }

  Future<void> _handleTimeCapsule() async {
    final selectedTime = await TimeCapsulePicker.pick(context);
    if (selectedTime == null) return;
    _sendTimeCapsule(selectedTime);
  }

  void _sendTimeCapsule(DateTime scheduledTime) {
    final text = controller.text.trim();
    if (text.isEmpty) return;
    final user = context.read<AppUserCubit>().state;
    context.read<ChatBloc>().add(SendMessageEvent(
          userId: widget.currentUserId,
          receiverId: widget.receiverId,
          content: text,
          userName: (user is AppUserIsSignedin) ? user.user.name : "Unknown",
          userProfile: (user is AppUserIsSignedin) ? user.user.profilePic : "Unknown",
          sendAt: scheduledTime,
          isScheduled: true,
        ));
    controller.clear();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    if (!mounted) return;
    final user = context.read<AppUserCubit>().state;
    if (user is AppUserIsSignedin) {
      cb.add(SendImageEvent(
        userName: user.user.name,
        userProfile: user.user.profilePic,
        userId: user.user.id,
        image: picked,
        receiverId: widget.receiverId,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.darkBg,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppPallete.darkBg, AppPallete.darkSecondary, AppPallete.darkBg],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildMessages(),
              _buildInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final friendsState = context.watch<FriendsCubit>().state;
    FriendModel? friend;
    if (friendsState is FriendsLoaded) {
      friend = friendsState.friends[widget.receiverId];
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppPallete.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppPallete.divider),
              ),
              child: const Icon(Icons.arrow_back, color: AppPallete.whiteColor, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: friend != null ? () => _showFriendProfile(context, friend) : null,
              child: Row(
                children: [
                  if (friend != null) ...[
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppPallete.cardBg,
                        border: Border.all(color: AppPallete.primaryOrange),
                      ),
                      child: friend.profilePic.isNotEmpty
                          ? CircleAvatar(
                              radius: 18,
                              backgroundImage: AssetImage(friend.profilePic),
                              backgroundColor: AppPallete.cardBg,
                            )
                          : const Icon(Icons.person, color: AppPallete.greyText, size: 20),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.receiverName,
                          style: const TextStyle(color: AppPallete.whiteColor, fontSize: 18, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (friend != null && friend.email.isNotEmpty)
                          Text(
                            friend.email,
                            style: const TextStyle(color: AppPallete.greyText, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildHeaderButton(
            icon: Icons.favorite,
            color: AppPallete.primaryOrange,
            onTap: () async {
              String? messageId = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TimelinePage(
                    receiverName: widget.receiverName,
                    userId: widget.currentUserId,
                    receiverId: widget.receiverId,
                  ),
                ),
              );
              if (cb.state is ChatLoaded) {
                final cl = cb.state as ChatLoaded;
                if (messageId != null && cl.messages.any((m) => m.id == messageId)) {
                  setState(() => widget.highlightMessageId = messageId);
                }
              }
            },
          ),
          const SizedBox(width: 8),
          _buildHeaderButton(
            icon: Icons.lock_clock,
            color: AppPallete.primaryOrange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TimeCapsuleMessages(
                    currentUserId: widget.currentUserId,
                    receiverId: widget.receiverId,
                    receiverName: widget.receiverName,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppPallete.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppPallete.divider),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  void _showFriendProfile(BuildContext context, FriendModel? friend) {
    if (friend == null) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(isUser: false, user: friend)));
  }

  Widget _buildMessages() {
    return Expanded(
      child: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          if (state is ChatError) {
            return Center(child: Text(state.message, style: const TextStyle(color: AppPallete.errorColor)));
          }
          if (state is ChatLoading) {
            return const Center(child: CircularProgressIndicator(color: AppPallete.primaryOrange));
          }
          if (state is ChatLoaded) {
            final messages = state.messages;

            if (widget.scrolltoIndex != null) {
              _scrollToIndex(widget.scrolltoIndex!);
              widget.scrolltoIndex = null;
            }

            if (widget.highlightMessageId != null) {
              final highlightIndex = messages.indexWhere((m) => m.id == widget.highlightMessageId);
              if (highlightIndex != -1) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToIndex(highlightIndex);
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (mounted) {
                      setState(() => highlightedIndex = highlightIndex);
                      Future.delayed(const Duration(milliseconds: 1500), () {
                        if (mounted) setState(() => highlightedIndex = null);
                      });
                    }
                  });
                });
                widget.highlightMessageId = null;
              }
            }

            // Initialize sticky header date label
            if (messages.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  context.read<StickyHeaderCubit>().updateDateLabel(
                    _getDateLabel(messages.last.createdAt),
                  );
                }
              });
            }

            return Stack(
              children: [
                NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    _onScrollPositionChanged();
                    return true;
                  },
                  child: ScrollablePositionedList.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemScrollController: _scrollController,
                    itemPositionsListener: _positionsListener,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == widget.currentUserId;
                      bool isAnimate = false;
                  
                      if ((index == messages.length - 1 && message.id != lastAnimated) && !firstTime) {
                        isAnimate = true;
                      }
                      if (index == messages.length - 1) lastAnimated = message.id;
                      firstTime = false;
                  
                      return Padding(
                        padding: EdgeInsets.only(bottom: message.inTimeline && index == 0 ? 12 : 0),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            if (_shouldShowDateHeader(messages, index))
                              _buildDateHeader(message.createdAt),
                            Stack(
                              clipBehavior: Clip.none,
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              children: [
                                buildBubble(message, isMe, isAnimate, highlightedIndex == index),
                                if (message.inTimeline)
                                  Positioned(
                                    left: isMe ? null : -2,
                                    right: isMe ? -2 : null,
                                    bottom: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4)],
                                      ),
                                      child: const Icon(Icons.favorite, size: 10, color: AppPallete.whiteColor),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                BlocBuilder<StickyHeaderCubit, StickyHeaderState>(
                  bloc: _stickyHeaderCubit,
                  builder: (context, state) {
                    if (state.dateLabel == null) return const SizedBox();
                    return Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: AnimatedOpacity(
                        opacity: state.showHeader ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: _buildStickyDateHeader(state.dateLabel!),
                      ),
                    );
                  },
                ),
              ],
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildStickyDateHeader(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: AppPallete.darkBg.withValues(alpha: 0)),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppPallete.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppPallete.divider),
          ),
          child: Text(label, style: const TextStyle(color: AppPallete.greyText, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  bool _shouldShowDateHeader(List<Message> messages, int index) {
    if (index == messages.length - 1) return true;
    final currentDate = DateTime(messages[index].createdAt.year, messages[index].createdAt.month, messages[index].createdAt.day);
    final nextDate = DateTime(messages[index + 1].createdAt.year, messages[index + 1].createdAt.month, messages[index + 1].createdAt.day);
    return currentDate != nextDate;
  }

  Widget _buildDateHeader(DateTime date) {
    final label = _getDateLabel(date);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppPallete.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppPallete.divider),
          ),
          child: Text(label, style: const TextStyle(color: AppPallete.greyText, fontSize: 12, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppPallete.cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppPallete.divider),
              ),
              child: const Icon(Icons.image, color: AppPallete.greyText, size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppPallete.inputBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppPallete.divider),
              ),
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                style: const TextStyle(color: AppPallete.whiteColor),
                decoration: const InputDecoration(
                  hintText: "Type message...",
                  hintStyle: TextStyle(color: AppPallete.greyText),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _send,
            onLongPress: () {
              showDialog(
                context: context,
                builder: (_) => SendOptionsDialog(onSendNormally: _send, onTimeCapsule: _handleTimeCapsule),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppPallete.primaryOrange, AppPallete.lightOrange]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: AppPallete.primaryOrange.withValues(alpha: 0.3), blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: const Icon(Icons.send, color: AppPallete.whiteColor, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBubble(Message msg, bool isMe, bool isAnimate, bool flash) {
    switch (msg.type) {
      case "text":
        return MessageBubble(
          currentUserId: widget.currentUserId,
          receiverId: widget.receiverId,
          key: ValueKey(msg.id),
          message: msg,
          isMe: isMe,
          animate: isAnimate,
          highlight: flash,
          onDelete: () {
            DeleteMessageConfirmationDialog.show(
              context,
              messageContent: msg.content,
              onDeleteForMe: () {
                context.read<ChatBloc>().add(DeleteMessageEvent(
                    msgId: msg.id, userId: widget.currentUserId, type: msg.type, receiverId: widget.receiverId, deleteForEveryone: false));
              },
              onDeleteForEveryone: () {
                context.read<ChatBloc>().add(DeleteMessageEvent(
                    msgId: msg.id, userId: widget.currentUserId, type: msg.type, receiverId: widget.receiverId, deleteForEveryone: true));
              },
            );
          },
        );
      case "image":
        return ImageMessageTile(
          currentUserId: widget.currentUserId,
          receiverId: widget.receiverId,
          key: ValueKey(msg.id),
          message: msg,
          cacheService: widget.cacheService!,
          isMe: isMe,
          flash: flash,
          onDelete: () {
            DeleteMessageConfirmationDialog.show(
              context,
              messageContent: "Image",
              onDeleteForMe: () {
                context.read<ChatBloc>().add(DeleteMessageEvent(
                    msgId: msg.id, userId: widget.currentUserId, type: msg.type, receiverId: widget.receiverId, deleteForEveryone: false));
              },
              onDeleteForEveryone: () {
                context.read<ChatBloc>().add(DeleteMessageEvent(
                    msgId: msg.id, userId: widget.currentUserId, type: msg.type, receiverId: widget.receiverId, deleteForEveryone: true));
              },
            );
          },
        );
      default:
        return const SizedBox();
    }
  }
}
