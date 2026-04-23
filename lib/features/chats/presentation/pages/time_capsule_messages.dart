import 'package:chat_application/features/chats/domain/entities/message.dart';
import 'package:chat_application/features/chats/presentation/bloc/chat/chat_bloc.dart';
import 'package:chat_application/features/chats/presentation/bloc/time_capsule/time_capsule_bloc.dart';
import 'package:chat_application/features/chats/presentation/widgets/delete_message_confirmation_dialog.dart';
import 'package:chat_application/features/chats/presentation/widgets/message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class TimeCapsuleMessages extends StatefulWidget {
  final String currentUserId;
  final String receiverId;
  final String? receiverName;

  const TimeCapsuleMessages({
    super.key,
    required this.currentUserId,
    required this.receiverId,
    this.receiverName,
  });

  @override
  State<TimeCapsuleMessages> createState() => _TimeCapsuleMessagesState();
}

class _TimeCapsuleMessagesState extends State<TimeCapsuleMessages> {
  final ItemScrollController _scrollController = ItemScrollController();
  final ItemPositionsListener _positionsListener =
      ItemPositionsListener.create();

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  void _loadMessages() {
    context.read<TimeCapsuleBloc>().add(
      LoadScheduledMessagesEvent(
        userId: widget.currentUserId,
        receiverId: widget.receiverId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Time capsules'),
      ),
      body: BlocBuilder<TimeCapsuleBloc, TimeCapsuleState>(
        builder: (context, state) {
          if (state is TimeCapsuleLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state is TimeCapsuleError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadMessages,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is TimeCapsuleLoaded) {
            final messages = state.messages;

            if (messages.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(right: 10, bottom: 30),
                child: Center(
                  child: Text(
                    'No scheduled messages\nLong press send button to create time capsule',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              );
            }

            return ScrollablePositionedList.builder(
              padding: EdgeInsets.only(
                right: 10,
                bottom: 30,
              ),
              reverse: true,
              itemCount: messages.length,
              itemScrollController: _scrollController,
              itemPositionsListener: _positionsListener,
              itemBuilder: (context, index) {
                final message = messages[index];
                final isMe = message.senderId == widget.currentUserId;

                return _buildMessageBubble(message, isMe);
              },
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    switch (message.type) {
      case 'text':
        return MessageBubble(
          key: ValueKey(message.id),
          message: message,
          isMe: isMe,
          animate: false,
          highlight: false,
          onDelete: () {
            DeleteMessageConfirmationDialog.show(
              context,
              messageContent: message.content,
              onDeleteForMe: () {
                context.read<ChatBloc>().add(
                      DeleteMessageEvent(
                        msgId: message.id,
                        userId: widget.currentUserId,
                        type: message.type,
                        receiverId: widget.receiverId,
                        deleteForEveryone: false,
                      ),
                    );
              },
              onDeleteForEveryone: () {
                context.read<ChatBloc>().add(
                      DeleteMessageEvent(
                        msgId: message.id,
                        userId: widget.currentUserId,
                        type: message.type,
                        receiverId: widget.receiverId,
                        deleteForEveryone: true,
                      ),
                    );
              },
            );
          },
       
        );
      // case 'image':
      //   return ImageMessageTile(
      //     key: ValueKey(message.id),
      //     message: message,
      //     isMe: isMe,
      //     flash: false,
      //   );
      default:
        return const SizedBox();
    }
  }
}