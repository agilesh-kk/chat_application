import 'dart:convert';

import 'package:chat_application/core/common/cubit/app_user_cubit.dart';
import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/features/chats/presentation/bloc/chat/chat_bloc.dart';
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
  final VoidCallback? onReply;
  final VoidCallback? onReplyTap;
  final VoidCallback? onEdit;

  final String currentUserId;
  final String receiverId;
  final String? receiverName;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.animate,
    this.highlight = false,
    this.onDelete,
    this.onReply,
    this.onReplyTap,
    this.onEdit,

    required this.currentUserId,
    required this.receiverId,
    this.receiverName,
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

    fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

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
  }

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('h:mm a').format(widget.message.createdAt);

    final bubble = _buildMessageContainer(time, false);

    return GestureDetector(
      onLongPressStart: (details) {
        if (widget.message.deletedForEveryone == true) return;
        final currentEmoji = widget.message.reactions[widget.currentUserId];
        MessageOptionsTray.show(
          context: context,
          position: details.globalPosition,
          messageId: widget.message.id,
          content: widget.message.content,
          isMe: widget.isMe,
          msgType: "text",
          onDelete: widget.onDelete,
          onAddToTimeline: !widget.message.inTimeline ? () => _showAddToTimelineDialog(widget.message) : null,
          onReact: (emoji) {
            context.read<ChatBloc>().add(
              ToggleReactionEvent(
                userId: widget.currentUserId,
                receiverId: widget.receiverId,
                messageId: widget.message.id,
                emoji: emoji,
              ),
            );
          },
          hasReacted: currentEmoji != null,
          onRemoveReaction: currentEmoji != null
              ? () {
                  context.read<ChatBloc>().add(
                    ToggleReactionEvent(
                      userId: widget.currentUserId,
                      receiverId: widget.receiverId,
                      messageId: widget.message.id,
                      emoji: currentEmoji,
                    ),
                  );
                }
              : null,
          onReply: widget.onReply,
          onEdit: widget.onEdit,
        );
      },
      child: widget.animate
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

  Widget _buildReplyPreview() {
    if (widget.message.replyToId == null) return const SizedBox();

    final isOwnReply = widget.message.replyToSenderId == widget.currentUserId;
    final senderName = isOwnReply ? "You" : (widget.receiverName ?? "Unknown");
    String previewText;
    if (widget.message.replyToType == "image") {
      previewText = "📷 Image";
    } else if (widget.message.replyToType == "status") {
      try {
        final data = jsonDecode(widget.message.replyToContent ?? '{}') as Map;
        final caption = data['caption'] as String? ?? '';
        previewText = caption.isNotEmpty ? "📸 $caption" : "📸 Status";
      } catch (_) {
        previewText = "📸 Status";
      }
    } else {
      previewText = widget.message.replyToContent ?? "";
    }

    return GestureDetector(
      onTap: widget.onReplyTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: widget.isMe
              ? AppPallete.primaryOrange.withValues(alpha: 0.2)
              : AppPallete.darkBg.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: widget.isMe
                  ? AppPallete.lightOrange
                  : AppPallete.primaryOrange,
              width: 3,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              senderName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: widget.isMe
                    ? AppPallete.lightOrange
                    : AppPallete.primaryOrange,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              previewText,
              style: TextStyle(
                fontSize: 13,
                color: widget.isMe
                    ? AppPallete.whiteColor.withValues(alpha: 0.8)
                    : AppPallete.greyText,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContainer(String time, bool normal) {
return Align(
      alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: widget.isMe
            ? const EdgeInsets.only(left: 64, right: 8, top: 4, bottom: 4)
            : const EdgeInsets.only(left: 8, right: 64, top: 4, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: widget.highlight
            ? Colors.amberAccent.withValues(alpha: 0.25)
            : (widget.isMe ? const Color(0xFFB84A1A) : AppPallete.cardBg),
          borderRadius: BorderRadius.circular(16),
          border: widget.isMe ? null : Border.all(color: AppPallete.divider),
        ),
        child: widget.message.replyToId != null && !widget.message.deletedForEveryone
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: double.infinity, child: _buildReplyPreview()),
                _buildContentRow(),
                Align(alignment: Alignment.centerRight, child: _buildTimeRow(time)),
              ],
            )
          : Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 6,
              children: [
                _buildContentRow(),
                _buildTimeRow(time),
              ],
            ),
      ),
    );
  }

  Widget _buildContentRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.message.deletedForEveryone == true) ...[
          Icon(Icons.block, size: 14, color: AppPallete.greyText),
          SizedBox(width: 4),
        ],
        Flexible(
          child: Text(
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
        ),
      ],
    );
  }

  Widget _buildTimeRow(String time) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.message.inTimeline)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(Icons.favorite, size: 12, color: Colors.red),
          ),
        if (widget.message.isEdited && !widget.message.deletedForEveryone)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(Icons.edit, size: 12, color: widget.isMe
                ? AppPallete.whiteColor.withValues(alpha: 0.7)
                : AppPallete.greyText),
          ),
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
    super.dispose();
  }
}