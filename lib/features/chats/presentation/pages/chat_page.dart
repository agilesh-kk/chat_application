import 'dart:io';

import 'package:chat_application/core/common/cubit/app_user_cubit.dart';
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
      appBar: AppBar(
        title: Text(widget.receiverName),
        actions: [
          IconButton(
            onPressed: () async {
              int index = await Navigator.push(
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

                final reversedIndex = cl.messages.length - 1 - index;

                setState(() {
                  highlightedIndex = reversedIndex;
                });

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToIndex(reversedIndex);
                });

                /// remove highlight after animation
                Future.delayed(const Duration(milliseconds: 800), () {
                  if (mounted) {
                    setState(() {
                      highlightedIndex = null;
                    });
                  }
                });
              }
            },
            icon: const Icon(
              Icons.favorite,
              color: Color.fromARGB(255, 255, 102, 0),
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>  TimeCapsuleMessages(
                      currentUserId: widget.currentUserId,
                      receiverId: widget.receiverId,
                      receiverName: widget.receiverName,
                    ),
                ),
              );
            },
            icon: const Icon(
              Icons.lock_clock,
              color: Color.fromARGB(255, 255, 102, 0),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          /// =======================
          /// MESSAGES
          /// =======================
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {
                if (state is ChatError) {
                  return Center(child: Text(state.message));
                }

                if (state is ChatLoading) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                if (state is ChatLoaded) {
                  final List<Message> messages = state.messages;

                  /// 🔥 Handle scrolling
                  if (widget.scrolltoIndex != null) {
                    //print(widget.scrolltoIndex);
                    _scrollToIndex(widget.scrolltoIndex!);
                    widget.scrolltoIndex = null;
                  }

                  return ScrollablePositionedList.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemScrollController: _scrollController,
                    itemPositionsListener: _positionsListener,

                    itemBuilder: (context, index) {
                      final message = messages[index];

                      final isMe = message.senderId ==
                          widget.currentUserId;

                      bool isAnimate = false;

                      /// Animate last message
                      if ((index == messages.length - 1 &&
                              message.id != lastAnimated) &&
                          !firstTime) {
                        isAnimate = true;
                      }

                      if (index == messages.length - 1) {
                        lastAnimated = message.id;
                      }

                      firstTime = false;

                      return buildBubble(
                          message, isMe, isAnimate, highlightedIndex==index);
                    },
                  );
                }

                return const SizedBox();
              },
            ),
          ),

          /// INPUT
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: _pickImage,
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: "Type message...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 5),

                //long press to acces time capsule
                GestureDetector(
                  onTap: _send,
                  onLongPress: () {
                    showDialog(
                      context: context, 
                      builder: (_) => SendOptionsDialog(
                        onSendNormally: _send, 
                        onTimeCapsule: _handleTimeCapsule,
                      )
                    );
                  },
                  child: Icon(Icons.send),
                ),

              ],
            ),
          )
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
                        deleteForEveryone: true,
                      ),
                    );
              },
            );
          },
        );
      case "image":
        return ImageMessageTile(
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