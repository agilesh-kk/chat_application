import 'package:flutter/material.dart';
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

    final Ofs = (widget.isMe)?Offset(.05,0):Offset(0,.05);

    slide = Tween<Offset>(
      begin: Ofs,
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
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: Align(
          alignment:
              widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.isMe ? Colors.blue : Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.message.content,
              style: TextStyle(
                color: widget.isMe ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}