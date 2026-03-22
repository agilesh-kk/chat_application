import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:chat_application/features/chats/domain/entities/message.dart';

class MessageBubble extends StatefulWidget {
  final Message message;
  final bool isMe;
  final bool animate;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.animate,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> fade;
  late final Animation<Offset> slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn,
    );

    final offset =
        widget.isMe ? const Offset(.05, 0) : const Offset(-.05,0);

    slide = Tween<Offset>(
      begin: offset,
      end: Offset.zero,
    ).animate(_controller);

    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final time =
        DateFormat('h:mm a').format(DateTime.parse(widget.message.createdAt));

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: Align(
          alignment:
              widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              color: widget.isMe ? const Color.fromARGB(255, 246, 152, 11) : Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 6,
              children: [
                /// MESSAGE TEXT
                Text(
                  widget.message.content,
                  style: TextStyle(
                    fontSize: 15,
                    color: widget.isMe ? Colors.white : Colors.black,
                  ),
                ),

                /// MESSAGE TIME
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 10,
                        color:
                            widget.isMe ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    SizedBox(width: 5,),
                    buildReceipt(widget.message.status,widget.isMe)
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

    Widget buildReceipt(String status, bool isMe) {
      if(!isMe){
        return SizedBox();
      }

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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}