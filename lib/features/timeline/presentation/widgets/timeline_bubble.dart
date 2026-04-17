import 'package:chat_application/core/utils/moments_ago.dart';
import 'package:chat_application/features/timeline/domain/entities/event.dart';

import 'package:flutter/material.dart';

class TimelineBubble extends StatefulWidget {
  final Event event;
  final bool isMe;

  const TimelineBubble({
    super.key,
    required this.event,
    required this.isMe,
  });

  @override
  State<TimelineBubble> createState() => _TimelineBubbleState();
}

class _TimelineBubbleState extends State<TimelineBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutBack, // nice zoom bounce
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          padding: const EdgeInsets.all(10),
          constraints: const BoxConstraints(
            maxWidth: 220,
          ),
          decoration: BoxDecoration(
            color: widget.isMe
                ? Colors.green.shade300
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: widget.isMe
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.end,
            children: [
              /// TITLE
              Text(
                widget.event.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 4),

              /// TIME
              Text(
                MomentsAgo.calculateMomentsAgo(
                  widget.event.time.toString(),
                ),
                style: const TextStyle(fontSize: 10),
              ),

              const SizedBox(height: 6),

              /// CONTENT
              if (widget.event.type == "image")
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.event.content,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Text(
                  widget.event.content,
                  softWrap: true,
                ),
            ],
          ),
        ),
      ),
    );
  }
}