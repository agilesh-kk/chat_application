import 'dart:io';

import 'package:chat_application/core/common/cubit/app_user_cubit.dart';
import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/features/chats/presentation/bloc/conversation/conversation_bloc.dart';
import 'package:chat_application/features/chats/presentation/helper/cacheservice.dart';
import 'package:chat_application/features/chats/presentation/pages/time_capsule_messages.dart';
import 'package:chat_application/features/chats/presentation/widgets/image_tile.dart';
import 'package:chat_application/features/chats/presentation/widgets/message_bubble.dart';
import 'package:chat_application/features/chats/presentation/widgets/delete_message_confirmation_dialog.dart';
import 'package:chat_application/features/chats/presentation/widgets/send_options_dialog.dart';
import 'package:chat_application/features/chats/presentation/widgets/time_capsule_picker.dart';
import 'package:chat_application/features/timeline/presentation/pages/timeline_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:chat_application/features/chats/presentation/bloc/chat/chat_bloc.dart';
import 'package:chat_application/features/chats/domain/entities/message.dart';
import 'package:image_picker/image_picker.dart';

class ChatPage extends StatefulWidget {
  final String? convoId;
  final String currentUserId;
  final String receiverId;
  final String receiverName;
  int? scrolltoIndex;
  CacheService? cacheService;

  ChatPage({
    super.key,
    this.convoId,
    required this.currentUserId,
    required this.receiverId,
    required this.receiverName,
    this.scrolltoIndex,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController controller = TextEditingController();

  late final ChatBloc cb;
  int ?highlightedIndex;

  String lastAnimated = "";
  bool firstTime = true;

  /// 🔥 ScrollablePositionedList controllers
  final ItemScrollController _scrollController = ItemScrollController();
  final ItemPositionsListener _positionsListener =
      ItemPositionsListener.create();

  @override
  void initState() {
    super.initState();
    widget.cacheService = CacheService();

    cb = context.read<ChatBloc>()
      ..add(
        LoadMessagesEvent(
          userId: widget.currentUserId,
          receiverId: widget.receiverId,
        ),
      );
  }

  @override
  void dispose() {
    cb.add(Closechat());
    super.dispose();
  }

  /// 🔥 Scroll helper
  void _scrollToIndex(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.isAttached) {
        _scrollController.scrollTo(
          index: index,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _send() {
    final text = controller.text.trim();
    if (text.isEmpty) return;

    final user = context.read<AppUserCubit>().state;

    context.read<ChatBloc>().add(
          SendMessageEvent(
            userId: widget.currentUserId,
            receiverId: widget.receiverId,
            content: text,
            userName:
                (user is AppUserIsSignedin) ? user.user.name : "Unknown",
            userProfile:
                (user is AppUserIsSignedin) ? user.user.profilePic : "Unknown",
          ),
        );

    controller.clear();
  }

  Future<void> _handleTimeCapsule() async {
    final selectedTime = await TimeCapsulePicker.pick(context);

    if (selectedTime == null) return;

    _sendTimeCapsule(selectedTime);
  }

  void _sendTimeCapsule(DateTime scheduledTime) {
    final text = controller.text.trim();
    //print("printing......"+scheduledTime.toIso8601String());
    if (text.isEmpty) return;

    final user = context.read<AppUserCubit>().state;

    context.read<ChatBloc>().add(
          SendMessageEvent(
            userId: widget.currentUserId,
            receiverId: widget.receiverId,
            content: text,
            userName:
                (user is AppUserIsSignedin) ? user.user.name : "Unknown",
            userProfile:
                (user is AppUserIsSignedin) ? user.user.profilePic : "Unknown",

            /// 🔥 NEW FIELD
            sendAt: scheduledTime,
            isScheduled: true,
          ),
        );

    controller.clear();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked =
        await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    final file = File(picked.path);

    final user = context.read<AppUserCubit>().state;

    if (user is AppUserIsSignedin) {
      cb.add(
        SendImageEvent(
          userName: user.user.name,
          userProfile: user.user.profilePic,
          userId: user.user.id,
          file: file,
          receiverId: widget.receiverId,
        ),
      );
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
            colors: [
              AppPallete.darkBg,
              AppPallete.darkSecondary,
              AppPallete.darkBg,
            ],
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
              child: Icon(
                Icons.arrow_back,
                color: AppPallete.whiteColor,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.receiverName,
              style: TextStyle(
                color: AppPallete.whiteColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
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
                final index = cl.messages.indexWhere((m) => m.id == messageId);

                if (index == -1) return;

                final reversedIndex = index;

                setState(() {
                  highlightedIndex = reversedIndex;
                });

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToIndex(reversedIndex);
                });

                Future.delayed(const Duration(milliseconds: 800), () {
                  if (mounted) {
                    setState(() {
                      highlightedIndex = null;
                    });
                  }
                });
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

  Widget _buildHeaderButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppPallete.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppPallete.divider),
        ),
        child: Icon(
          icon,
          color: color,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildMessages() {
    return Expanded(
      child: BlocBuilder<ChatBloc, ChatState>(
        builder: (context, state) {
          if (state is ChatError) {
            return Center(
              child: Text(
                state.message,
                style: TextStyle(color: AppPallete.errorColor),
              ),
            );
          }

          if (state is ChatLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppPallete.primaryOrange,
              ),
            );
          }

          if (state is ChatLoaded) {
            final List<Message> messages = state.messages;

            if (widget.scrolltoIndex != null) {
              _scrollToIndex(widget.scrolltoIndex!);
              widget.scrolltoIndex = null;
            }

            return ScrollablePositionedList.builder(
              reverse: true,
              itemCount: messages.length,
              itemScrollController: _scrollController,
              itemPositionsListener: _positionsListener,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemBuilder: (context, index) {
                final message = messages[index];
                final isMe = message.senderId == widget.currentUserId;

                bool isAnimate = false;

                if ((index == messages.length - 1 && message.id != lastAnimated) &&
                    !firstTime) {
                  isAnimate = true;
                }

                if (index == messages.length - 1) {
                  lastAnimated = message.id;
                }

                firstTime = false;

                return buildBubble(message, isMe, isAnimate, highlightedIndex == index);
              },
            );
          }

          return const SizedBox();
        },
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
              child: Icon(
                Icons.image,
                color: AppPallete.greyText,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppPallete.inputBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppPallete.divider),
              ),
              child: TextField(
                controller: controller,
                style: TextStyle(color: AppPallete.whiteColor),
                decoration: InputDecoration(
                  hintText: "Type message...",
                  hintStyle: TextStyle(color: AppPallete.greyText),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
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
                builder: (_) => SendOptionsDialog(
                  onSendNormally: _send,
                  onTimeCapsule: _handleTimeCapsule,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppPallete.primaryOrange,
                    AppPallete.lightOrange,
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppPallete.primaryOrange.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.send,
                color: AppPallete.whiteColor,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// =======================
  /// MESSAGE BUILDER
  /// =======================
  Widget buildBubble(Message msg, bool isMe, bool? isAnimate, bool flash) {
    switch (msg.type) {
      case "text":
        return MessageBubble(
          currentUserId: widget.currentUserId,
          receiverId: widget.receiverId,
          key: ValueKey(msg.id),
          message: msg,
          isMe: isMe,
          animate: isAnimate!,
          highlight: flash,
          onDelete: () { 
            DeleteMessageConfirmationDialog.show(
              context,
              messageContent: msg.content,
              onDeleteForMe: () {
                context.read<ChatBloc>().add(
                      DeleteMessageEvent(
                        msgId: msg.id,
                        userId: widget.currentUserId,
                        type: msg.type,
                        receiverId: widget.receiverId,
                        deleteForEveryone: false,
                      ),
                    );
              },
              onDeleteForEveryone: () {
                context.read<ChatBloc>().add(
                      DeleteMessageEvent(
                        msgId: msg.id,
                        userId: widget.currentUserId,
                        type: msg.type,
                        receiverId: widget.receiverId,
                        deleteForEveryone: true,
                      ),
                    );
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
              messageContent: "📷 Image", // Since images don't have text content
              onDeleteForMe: () {
                context.read<ChatBloc>().add(
                      DeleteMessageEvent(
                        msgId: msg.id,
                        userId: widget.currentUserId,
                        type: msg.type,
                        receiverId: widget.receiverId,
                        deleteForEveryone: false,
                      ),
                    );
              },
              onDeleteForEveryone: () {
                context.read<ChatBloc>().add(
                      DeleteMessageEvent(
                        msgId: msg.id,
                        userId: widget.currentUserId,
                        receiverId: widget.receiverId,
                        type: msg.type,
                        deleteForEveryone: true,
                      ),
                    );
              },
            );
          },
        );
      default:
        return const SizedBox();
    }
  }
}