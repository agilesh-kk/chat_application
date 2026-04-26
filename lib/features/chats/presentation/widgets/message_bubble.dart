import 'package:chat_application/core/common/cubit/app_user_cubit.dart';
import 'package:chat_application/features/chats/presentation/widgets/message_options_helper.dart';
import 'package:chat_application/features/timeline/presentation/bloc/timeline_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:chat_application/features/chats/domain/entities/message.dart';

class MessageBubble extends StatefulWidget {
  final Message message;
  final bool isMe;
  final bool animate;
  final bool highlight; // 🔥 NEW
  final VoidCallback? onDelete;

  final String currentUserId;
  final String receiverId;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.animate,
    this.highlight = false,
    this.onDelete,

    required this.currentUserId,
    required this.receiverId,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _scaleController;

  late final Animation<double> fade;
  late final Animation<Offset> slide;
  late final Animation<double> scale; // 🔥 NEW

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    /// FADE
    fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn,
    );

    /// SLIDE
    final offset =
        widget.isMe ? const Offset(.05, 0) : const Offset(-.05, 0);

    slide = Tween<Offset>(
      begin: offset,
      end: Offset.zero,
    ).animate(_controller);

    scale = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 3.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 3.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_scaleController);

    /// INITIAL LOAD ANIMATION
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);

    /// 🔥 TRIGGER HIGHLIGHT ZOOM
    if (widget.highlight && !oldWidget.highlight) {
      _scaleController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final time =
        DateFormat('h:mm a').format(widget.message.createdAt); //createdAt is changed to DateTime

    return GestureDetector(
      onLongPressStart: (details) {
        if (widget.message.deletedForEveryone == true) return ;
        MessageOptionsTray.show(
          context: context,
          position: details.globalPosition,
          messageId: widget.message.id,
          content: widget.message.content,
          isMe: widget.isMe,
          msgType: "text",

          onDelete: widget.onDelete,

          onAddToTimeline: !widget.message.inTimeline ? (){
            _showAddToTimelineDialog(widget.message);
          }: null,
            //print("Timeline: ${widget.message.id}");    
        );  
      },
      child: ScaleTransition(
        scale: scale,
        child: FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: slide,
            child: Align(
              alignment:
                  widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                constraints: const BoxConstraints(maxWidth: 500),
                decoration: BoxDecoration(
                  color: widget.highlight
                      ? Colors.yellow.withValues(alpha: 0.3) // 🔥 glow
                      : (widget.isMe
                          ? const Color.fromARGB(255, 246, 152, 11)
                          : Colors.grey[300]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.end,
                  spacing: 6,
                  children: [
                    /// MESSAGE TEXT
                    //before deletedForEveryone Field
                    // Text(
                    //   widget.message.content,
                    //   style: TextStyle(
                    //     fontSize: 15,
                    //     color:
                    //         widget.isMe ? Colors.white : Colors.black,
                    //   ),
                    // ),

                    //after deletedForEveryone Field
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.message.deletedForEveryone == true) ...[
                          Icon(Icons.block, size: 14, color: Colors.grey),
                          SizedBox(width: 4),
                        ],
                        Text(
                          widget.message.deletedForEveryone
                              ? "This message was deleted "
                              : widget.message.content,
                          style: TextStyle(
                            fontSize: 15,
                            fontStyle: widget.message.deletedForEveryone ? FontStyle.italic : FontStyle.normal,
                            color: widget.message.deletedForEveryone
                                ? Colors.grey
                                : (widget.isMe ? Colors.white : Colors.black),
                          ),
                        ),
                      ],
                    ),
            
                    /// TIME + STATUS
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 10,
                            color: widget.isMe
                                ? Colors.white70
                                : Colors.black54,
                          ),
                        ),
                        const SizedBox(width: 5),
                        if (widget.message.inTimeline) ...[
                          Icon(Icons.favorite, size: 12, color: Colors.red),
                          SizedBox(width: 4),
                        ],
                        if(!widget.message.deletedForEveryone)
                        buildReceipt(widget.message.status, widget.isMe),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildReceipt(String status, bool isMe) {
    if (!isMe) return const SizedBox();

    switch (status) {
      case "sent":
        return const Icon(Icons.check, size: 14, color: Colors.white70);

      case "delivered":
        return const Icon(Icons.done_all, size: 14, color: Colors.white70);

      case "seen":
        return const Icon(Icons.done_all, size: 14, color: Colors.blue);

      default:
        return const SizedBox();
    }
  }

  Future<void> _showAddToTimelineDialog(Message msg) async {
    final controller = TextEditingController();

    final user = context.read<AppUserCubit>().state;

    String userName = "Unknown";

    if (user is AppUserIsSignedin) {
      userName = user.user.name;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text("Add to Timeline"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "Add a note (optional)",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              print("add event triggred");
              Navigator.pop(context);

              dialogContext.read<TimelineBloc>().add(
                AddEvent(
                  message: msg,
                  userId: widget.currentUserId,
                  receiverId: widget.receiverId,
                  customTitle: controller.text.trim(),
                  addedByName: userName,
                ),
              );
            },
            child: Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}