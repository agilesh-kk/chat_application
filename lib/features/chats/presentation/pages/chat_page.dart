import 'package:chat_application/core/common/cubit/app_user_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:chat_application/features/chats/presentation/bloc/chat/chat_bloc.dart';
import 'package:chat_application/features/chats/domain/entities/message.dart';

class ChatPage extends StatefulWidget {
  final String? convoId;       // nullable
  final String currentUserId;
  final String receiverId;
  final String receiverName;

  const ChatPage({
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

  @override
  void initState() {
    super.initState();
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
        userName:(user is AppUserIsSignedin) ? user.user.name : "Unknown"
      )
    );

    controller.clear();
  }

  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    context.read<ChatBloc>()
        .add(LoadMessagesEvent(userId: widget.currentUserId,receiverId: widget.receiverId));

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
                    reverse: true,
                    controller: _scrollController,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];

                      final isMe =
                          message.senderId == widget.currentUserId;

                      return  TweenAnimationBuilder(
  key: ValueKey(message.id),
  tween: Tween<double>(begin: 0, end: 1),
  duration: const Duration(milliseconds: 250),
  curve: Curves.easeOut,
  builder: (context, value, child) {
    return Opacity(
      opacity: value,
      child: Transform.translate(
        offset: Offset(0, 20 * (1 - value)),
        child: child,
      ),
    );
  },
  child: Align(
    alignment: isMe
        ? Alignment.centerRight
        : Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe ? Colors.blue : Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message.content,
        style: TextStyle(
          color: isMe ? Colors.white : Colors.black,
        ),
      ),
    ),
  ),
);
                    },
                  );
                }

                return const SizedBox();
              },
            ),
          ),

          /// INPUT FIELD
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: "Type message...",
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _send,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}