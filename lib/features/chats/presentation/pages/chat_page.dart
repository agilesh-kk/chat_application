import 'dart:io';

import 'package:chat_application/core/common/cubit/app_user_cubit.dart';
import 'package:chat_application/features/chats/presentation/helper/cacheservice.dart';
import 'package:chat_application/features/chats/presentation/widgets/image_tile.dart';
import 'package:chat_application/features/chats/presentation/widgets/message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:chat_application/features/chats/presentation/bloc/chat/chat_bloc.dart';
import 'package:chat_application/features/chats/domain/entities/message.dart';
import 'package:image_picker/image_picker.dart';

class ChatPage extends StatefulWidget {
  final String? convoId;       // nullable
  final String currentUserId;
  final String receiverId;
  final String receiverName;
  CacheService? cacheService;

  ChatPage({
    super.key,
    this.convoId,
    required this.currentUserId,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {

  final TextEditingController controller = TextEditingController();
  String lastAnimated = "";
  bool firstTime = true;
  late final ChatBloc cb;

  @override
  void dispose() {
    // TODO: implement dispose
    cb.add(Closechat());
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    widget.cacheService = CacheService();

    cb = context.read<ChatBloc>()
        ..add(LoadMessagesEvent(userId: widget.currentUserId,receiverId: widget.receiverId));
  }

  // Call this whenever you want to scroll to the bottom, 
// for instance, after adding a new message to the list
    void _scrollToBottom() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.minScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
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
        userName:(user is AppUserIsSignedin) ? user.user.name : "Unknown",
        userProfile:(user is AppUserIsSignedin) ? user.user.profilePic : "Unknown"
      )
    );

    controller.clear();
  }

  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.receiverName),
      ),
      body: Column(
        children: [

          /// MESSAGES
          Expanded(
            child: BlocBuilder<ChatBloc, ChatState>(
              builder: (context, state) {

                if(state is ChatError){
                  return Center(child: Text(state.message),);
                }

                if (state is ChatLoading) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                if (state is ChatLoaded) {
                  final List<Message> messages = state.messages;

                  _scrollToBottom();

                  return ListView.builder(
                    addAutomaticKeepAlives: true,
                    cacheExtent: 2000,
                    addRepaintBoundaries: true,
                    reverse: true,
                    controller: _scrollController,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];

                      final isMe =
                          message.senderId == widget.currentUserId;
                      bool isAnimate = false;

                      if((index==0 && message.id != lastAnimated) && !firstTime){
                        isAnimate = true;
                      }
                      if(index == 0){
                        lastAnimated = message.id;
                      }
                      firstTime = false;
                      return buildBubble(message, isMe, isAnimate);
                    },
                  );
                }

                return const SizedBox();
              },
            ),
          ),

         Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                // 📸 IMAGE BUTTON
                IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: _pickImage,
                ),

                // ✏️ TEXT FIELD
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

                // 📤 SEND BUTTON
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _send,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
      final picker = ImagePicker();

      final picked =
          await picker.pickImage(source: ImageSource.gallery);

      if (picked == null) return;

      final file = File(picked.path);

      final user = context.read<AppUserCubit>().state;

      if(user is AppUserIsSignedin){
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

  Widget buildBubble(Message msg, bool isMe, bool? isAnimate){
    switch(msg.type){
      case "text":
        return MessageBubble(key: ValueKey(msg.id),message: msg, isMe: isMe, animate: isAnimate!);
      case "image":
        return ImageMessageTile(key: ValueKey(msg.id),message: msg, cacheService: widget.cacheService!, isMe: isMe);
      default :
        return SizedBox();
    }
  }
}