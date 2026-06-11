import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/core/utils/moments_ago.dart';
import 'package:chat_application/features/timeline/domain/entities/event.dart';

import 'package:flutter/material.dart';

class TimelineBubble extends StatefulWidget {
  final Event event;
  final bool isMe;

  final String userId;
  final String? receiverId;
  final VoidCallback? onTap;

  const TimelineBubble({
    super.key,
    required this.event,
    required this.isMe,
    
    required this.userId,
    this.receiverId,
    this.onTap,
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
        curve: Curves.easeOutBack,
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
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(
              maxWidth: 220,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.isMe
                    ? [AppPallete.primaryOrange.withValues(alpha: 0.3), AppPallete.lightOrange.withValues(alpha: 0.1)]
                    : [AppPallete.cardBg, AppPallete.darkTertiary],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppPallete.primaryOrange.withValues(alpha: 0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppPallete.primaryOrange.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: widget.isMe
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _icon(widget.event.type),
                      size: 14,
                      color: AppPallete.primaryOrange,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        widget.event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppPallete.whiteColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  MomentsAgo.calculateMomentsAgo(
                    widget.event.time.toString(),
                  ),
                  style: TextStyle(
                    fontSize: 10,
                    color: AppPallete.greyText,
                  ),
                ),
                const SizedBox(height: 8),
                if (widget.event.hasImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.event.imageUrl,
                      height: 120,
                      width: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    ),
                  ),
                if (widget.event.type == "image" && !widget.event.hasImage)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.event.content,
                      height: 120,
                      width: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox(),
                    ),
                  ),
                if (widget.event.type != "image" || widget.event.hasImage)
                  Text(
                    widget.event.content,
                    softWrap: true,
                    maxLines: 10,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppPallete.whiteColor.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                if (widget.event.isManual)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      "Added by ${widget.event.addedByName}",
                      style: TextStyle(
                        fontSize: 10,
                        color: AppPallete.greyText,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _icon(String type) {
    switch (type) {
      case "image":
        return Icons.image;
      case "milestone":
        return Icons.star;
      default:
        return Icons.message;
    }
  }
}