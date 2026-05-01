import 'package:chat_application/core/common/cubit/app_user_cubit.dart';
import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/features/chats/presentation/widgets/message_options_helper.dart';
import 'package:chat_application/features/timeline/presentation/bloc/time_line/timeline_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:chat_application/features/chats/domain/entities/message.dart';

class MessageBubble extends StatefulWidget {
  final Message message;
  final bool isMe;
  final bool animate;
  final bool highlight;
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

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    // Slide animation - only for initial animate, not for highlight
    final slideX = widget.isMe ? 0.5 : -0.5;
    slide = Tween<Offset>(
      begin: Offset(slideX, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1;
    }
    
    if (widget.highlight) {
      _scaleController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant MessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.highlight && !oldWidget.highlight) {
      _scaleController.repeat(reverse: true);
    } else if (!widget.highlight && oldWidget.highlight) {
      _scaleController.stop();
      _scaleController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('h:mm a').format(widget.message.createdAt);

    final bubble = _buildMessageContainer(time, false);

    return GestureDetector(
      onLongPressStart: (details) {
        if (widget.message.deletedForEveryone == true) return;
        MessageOptionsTray.show(
          context: context,
          position: details.globalPosition,
          messageId: widget.message.id,
          content: widget.message.content,
          isMe: widget.isMe,
          msgType: "text",
          onDelete: widget.onDelete,
          onAddToTimeline: !widget.message.inTimeline ? () => _showAddToTimelineDialog(widget.message) : null,
        );
      },
      child: widget.highlight 
        ? Align(
            alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: AnimatedBuilder(
              animation: _scaleController,
              builder: (context, child) {
                final scale = 1.0 + (_scaleController.value * 0.15);
                return Transform.scale(
                  scale: scale,
                  alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: child,
                );
              },
              child: bubble,
            ),
          )
        : widget.animate
          ? FadeTransition(
              opacity: fade,
              child: SlideTransition(
                position: slide,
                child: bubble,
              ),
            )
          : bubble,
    );
  }

  Widget _buildMessageContainer(String time, bool normal) {
return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: widget.highlight
            ? AppPallete.primaryOrange.withValues(alpha: 0.3)
            : (widget.isMe ? AppPallete.primaryOrange : AppPallete.cardBg),
          borderRadius: BorderRadius.circular(16),
          border: widget.isMe ? null : Border.all(color: AppPallete.divider),
        ),
        child: Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.end,
          spacing: 6,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.message.deletedForEveryone == true) ...[
                  Icon(Icons.block, size: 14, color: AppPallete.greyText),
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
                      ? AppPallete.greyText
                      : (widget.isMe ? AppPallete.whiteColor : AppPallete.whiteColor),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 10,
                    color: widget.isMe ? AppPallete.whiteColor.withValues(alpha: 0.7) : AppPallete.greyText,
                  ),
                ),
                const SizedBox(width: 5),
                if (!widget.message.deletedForEveryone) _buildReceiptStatus(widget.message.status, widget.isMe),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptStatus(String status, bool isMe) {
    if (!isMe) return const SizedBox();
    switch (status) {
      case "sent":
        return Icon(Icons.check, size: 14, color: AppPallete.whiteColor.withValues(alpha: 0.7));
      case "delivered":
        return Icon(Icons.done_all, size: 14, color: AppPallete.whiteColor.withValues(alpha: 0.7));
      case "seen":
        return Icon(Icons.done_all, size: 14, color: AppPallete.statusGreen);
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
      builder: (dialogContext) => Dialog(
        backgroundColor: AppPallete.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppPallete.divider),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Add to Timeline",
                style: TextStyle(
                  color: AppPallete.whiteColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AppPallete.inputBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppPallete.divider),
                ),
                child: TextField(
                  controller: controller,
                  style: TextStyle(color: AppPallete.whiteColor),
                  decoration: InputDecoration(
                    hintText: "Add a note (optional)",
                    hintStyle: TextStyle(color: AppPallete.greyText),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppPallete.darkTertiary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppPallete.divider),
                      ),
                      child: Text(
                        "Cancel",
                        style: TextStyle(color: AppPallete.greyText, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
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
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppPallete.primaryOrange, AppPallete.lightOrange],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "Save",
                        style: TextStyle(color: AppPallete.whiteColor, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scaleController.dispose();
    super.dispose();
  }
}