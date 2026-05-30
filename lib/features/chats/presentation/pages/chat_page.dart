// ignore_for_file: must_be_immutable
import 'dart:async';
import 'dart:io';
import 'package:chat_application/core/common/cubit/app_user_cubit.dart';
import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/core/utils/moments_ago.dart';
import 'package:chat_application/features/chats/presentation/helper/cacheservice.dart';
import 'package:chat_application/features/chats/presentation/pages/time_capsule_messages.dart';
import 'package:chat_application/features/chats/presentation/widgets/image_tile.dart';
import 'package:chat_application/features/chats/presentation/widgets/message_bubble.dart';
import 'package:chat_application/features/chats/presentation/widgets/reply_preview_bar.dart';
import 'package:chat_application/features/chats/presentation/widgets/swipe_to_reply.dart';
import 'package:chat_application/features/chats/presentation/widgets/delete_message_confirmation_dialog.dart';
import 'package:chat_application/features/chats/presentation/widgets/send_options_dialog.dart';
import 'package:chat_application/features/chats/presentation/widgets/time_capsule_picker.dart';
import 'package:chat_application/features/timeline/presentation/pages/timeline_page.dart';
import 'package:chat_application/features/friends/data/friend_model.dart';
import 'package:chat_application/features/friends/presentation/friends_cubit.dart';
import 'package:chat_application/features/profile/presentation/pages/profile_page.dart';
import 'package:chat_application/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' as fp;
import 'package:path_provider/path_provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:intl/intl.dart';

import 'package:chat_application/features/chats/presentation/bloc/chat/chat_bloc.dart';
import 'package:chat_application/features/chats/domain/entities/message.dart';
import 'package:image_picker/image_picker.dart';
import 'package:chat_application/features/chats/presentation/cubit/sticky_header_cubit.dart';
import 'package:chat_application/notification_storage.dart';

class ChatPage extends StatefulWidget {
  static String? activeConvoId;

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
  final FocusNode _messageFocusNode = FocusNode();
  late final ChatBloc cb;
  int? highlightedIndex;
  String lastAnimated = "";
  bool firstTime = true;
  Message? _replyToMessage;
  String? _editingMessageId;
  String? lastMessageId;

  bool get _isEditing => _editingMessageId != null;

  final ItemScrollController _scrollController = ItemScrollController();
  final ItemPositionsListener _positionsListener = ItemPositionsListener.create();
  late final StickyHeaderCubit _stickyHeaderCubit;
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    ChatPage.activeConvoId = widget.convoId;
    if (widget.convoId != null) {
      removeChatMessages(widget.convoId!);
      flutterLocalNotificationsPlugin.cancel(widget.convoId.hashCode,tag: widget.convoId);
    }
    _stickyHeaderCubit = StickyHeaderCubit();
    widget.cacheService = CacheService();
    cb = context.read<ChatBloc>()
      ..add(LoadMessagesEvent(userId: widget.currentUserId, receiverId: widget.receiverId));
  }

  @override
  void dispose() {
    ChatPage.activeConvoId = null;
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

    final isIndexZeroVisible = positions.any(
      (p) => p.index == 0 && p.itemTrailingEdge >= 0 && p.itemTrailingEdge <= 1.0,
    );
    final shouldShow = !isIndexZeroVisible;
    if (shouldShow != _showScrollToBottom) {
      setState(() => _showScrollToBottom = shouldShow);
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
        _scrollController.jumpTo(
            index: index);
      }
    });
  }

  void _onReplyTap(String replyToId) {
    final state = cb.state;
    if (state is ChatLoaded) {
      final index = state.messages.indexWhere((m) => m.id == replyToId);
      if (index != -1) {
        _scrollToIndex(index);
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() => highlightedIndex = index);
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted) setState(() => highlightedIndex = null);
            });
          }
        });
      }
    }
  }

  void _send() {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    if (_isEditing) {
      context.read<ChatBloc>().add(EditMessageEvent(
        userId: widget.currentUserId,
        receiverId: widget.receiverId,
        msgId: _editingMessageId!,
        newContent: text,
      ));
      controller.clear();
      _clearEdit();
      return;
    }

    final user = context.read<AppUserCubit>().state;
    context.read<ChatBloc>().add(SendMessageEvent(
          userId: widget.currentUserId,
          receiverId: widget.receiverId,
          content: text,
          userName: (user is AppUserIsSignedin) ? user.user.name : "Unknown",
          userProfile: (user is AppUserIsSignedin) ? user.user.profilePic : "Unknown",
          replyToId: _replyToMessage?.id,
          replyToContent: _replyToMessage?.content,
          replyToSenderId: _replyToMessage?.senderId,
          replyToType: _replyToMessage?.type,
        ));
    controller.clear();
    _clearReply();
  }

  void _clearReply() {
    setState(() => _replyToMessage = null);
  }

  void _onEditMessage(Message msg) {
    setState(() {
      _editingMessageId = msg.id;
      controller.text = msg.content;
      _replyToMessage = null;
    });
    _messageFocusNode.requestFocus();
  }

  void _clearEdit() {
    setState(() => _editingMessageId = null);
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
          replyToId: _replyToMessage?.id,
          replyToContent: _replyToMessage?.content,
          replyToSenderId: _replyToMessage?.senderId,
          replyToType: _replyToMessage?.type,
        ));
    controller.clear();
    _clearReply();
  }

  static const _contentChannel = MethodChannel('com.axisstudio.memento/content_reader');

  Future<void> _sendGifFromKeyboard(KeyboardInsertedContent inserted) async {
    Uint8List bytes;
    if (inserted.hasData) {
      bytes = inserted.data!;
    } else {
      try {
        final result = await _contentChannel.invokeMethod('readContentUri', {'uri': inserted.uri});
        bytes = Uint8List.fromList(List<int>.from(result as List));
      } catch (e) {
        return;
      }
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/gif_${DateTime.now().millisecondsSinceEpoch}.gif');
    await file.writeAsBytes(bytes);

    if (!mounted) return;
    final user = context.read<AppUserCubit>().state;
    if (user is AppUserIsSignedin) {
      cb.add(SendImageEvent(
        userName: user.user.name,
        userProfile: user.user.profilePic,
        userId: user.user.id,
        image: XFile(file.path),
        receiverId: widget.receiverId,
        replyToId: _replyToMessage?.id,
        replyToContent: _replyToMessage?.content,
        replyToSenderId: _replyToMessage?.senderId,
        replyToType: _replyToMessage?.type,
      ));
    }
    _clearReply();
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
        replyToId: _replyToMessage?.id,
        replyToContent: _replyToMessage?.content,
        replyToSenderId: _replyToMessage?.senderId,
        replyToType: _replyToMessage?.type,
      ));
    }
    _clearReply();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _messageFocusNode.unfocus();
      },
      child: Scaffold(
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
              if (_isEditing) _buildEditBar()
              else if (_replyToMessage != null) _buildReplyBar(),
              _buildInput(),
            ],
          ),
        ),
      ),
      )
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
            onTap: () {
              _messageFocusNode.unfocus();
              Navigator.pop(context);
            },
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
                    Stack(
                      children: [
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
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: friend.isEffectivelyOnline
                                  ? AppPallete.statusGreen
                                  : AppPallete.greyText,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppPallete.cardBg,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
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
                        if (friend != null)
                          Text(
                            friend.isEffectivelyOnline
                                ? "Online"
                                : friend.lastSeen != null
                                    ? "Last seen ${MomentsAgo.calculateMomentsAgo(friend.lastSeen!.toIso8601String())}"
                                    : "",
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
              _messageFocusNode.unfocus();
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
              _messageFocusNode.unfocus();
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
    _messageFocusNode.unfocus();
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

            if(lastMessageId==null){
              lastMessageId = messages[0].id;
            }
            else if(lastMessageId != messages[0].id && _scrollController.isAttached){
              _scrollController.scrollTo(index: 0, duration: Duration(milliseconds: 350),curve: Curves.easeIn);
              lastMessageId = messages[0].id;
            }

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
                        padding: EdgeInsets.only(
                          bottom: message.type == "image" ? 8 : (message.inTimeline && index == 0 ? 12 : 0),
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            if (_shouldShowDateHeader(messages, index))
                              _buildDateHeader(message.createdAt),
                            SwipeToReply(
                              isMe: isMe,
                              onReply: message.deletedForEveryone ? null : () {
                                setState(() => _replyToMessage = message);
                                _messageFocusNode.requestFocus();
                              },
                              child: Stack(
                                clipBehavior: Clip.none,
                                alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                                children: [
                                  buildBubble(message, isMe, isAnimate, highlightedIndex == index),
                                  if (!message.deletedForEveryone && message.reactions.isNotEmpty)
                                    Positioned(
                                      left: isMe ? null : -2,
                                      right: isMe ? -2 : null,
                                      bottom: -2,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppPallete.cardBg,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: AppPallete.divider),
                                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4)],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: message.reactions.values.toSet().map((emoji) => Padding(
                                            padding: const EdgeInsets.only(right: 1),
                                            child: Text(emoji, style: const TextStyle(fontSize: 11)),
                                          )).toList(),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
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
                        child: _buildStickyDateHeader(state.dateLabel!,messages),
                      ),
                    );
                  },
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: AnimatedOpacity(
                    opacity: _showScrollToBottom ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: IgnorePointer(
                      ignoring: !_showScrollToBottom,
                      child: GestureDetector(
                        onTap: () => _scrollToIndex(0),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppPallete.cardBg,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppPallete.divider),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_downward,
                            color: AppPallete.primaryOrange,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildStickyDateHeader(String label,List<Message> messages) {
    return GestureDetector(
      onLongPress: ()async{
        print(messages[0].createdAt);
        DateTime? picked = await showDatePicker(context: context, firstDate: messages[messages.length-1].createdAt, lastDate: DateTime.now());

        if(picked != null){
          final index = messages.lastIndexWhere((element) => element.createdAt.eqvYearMonthDay(picked),);
          if(index != null) {
            _scrollToIndex(index);
          }
        }
      },
      child: Container(
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

  Widget _buildEditBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppPallete.primaryOrange.withValues(alpha: 0.15),
        border: Border(
          top: BorderSide(color: AppPallete.divider.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit, color: AppPallete.primaryOrange, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Editing message",
              style: const TextStyle(
                color: AppPallete.primaryOrange,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: _clearEdit,
            child: const Icon(Icons.close, color: AppPallete.greyText, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyBar() {
    if (_replyToMessage == null) return const SizedBox();
    final isOwnReply = _replyToMessage!.senderId == widget.currentUserId;
    final name = isOwnReply ? "You" : widget.receiverName;
    return ReplyPreviewBar(
      replyingToName: name,
      replyContent: _replyToMessage!.content,
      replyType: _replyToMessage!.type,
      onCancel: _clearReply,
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (!_isEditing)
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
          if (!_isEditing) const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppPallete.inputBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppPallete.divider),
              ),
              child: TextField(
                controller: controller,
                focusNode: _messageFocusNode,
                contentInsertionConfiguration: ContentInsertionConfiguration(
                  allowedMimeTypes: const ['image/gif', 'image/*'],
                  onContentInserted: (inserted) => _sendGifFromKeyboard(inserted),
                ),
                minLines: 1,
                maxLines: 5,
                style: const TextStyle(color: AppPallete.whiteColor),
                decoration: InputDecoration(
                  hintText: _isEditing ? "Edit message..." : "Type message...",
                  hintStyle: const TextStyle(color: AppPallete.greyText),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _send,
            onLongPress: _isEditing ? null : () {
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
              child: Icon(_isEditing ? Icons.check : Icons.send, color: AppPallete.whiteColor, size: 22),
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
          receiverName: widget.receiverName,
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
          onReply: () {
            setState(() => _replyToMessage = msg);
            _messageFocusNode.requestFocus();
          },
          onReplyTap: () => _onReplyTap(msg.replyToId!),
          onEdit: isMe ? () => _onEditMessage(msg) : null,
        );
      case "image":
        return ImageMessageTile(
          currentUserId: widget.currentUserId,
          receiverId: widget.receiverId,
          receiverName: widget.receiverName,
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
          onReply: () {
            setState(() => _replyToMessage = msg);
            _messageFocusNode.requestFocus();
          },
          onReplyTap: () => _onReplyTap(msg.replyToId!),
          onEdit: null,
        );
      default:
        return const SizedBox();
    }
  }
}
