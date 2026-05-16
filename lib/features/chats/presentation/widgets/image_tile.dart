import 'dart:io';

import 'package:chat_application/core/common/cubit/app_user_cubit.dart';
import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/features/chats/domain/entities/message.dart';
import 'package:chat_application/features/chats/presentation/helper/cacheservice.dart';
import 'package:chat_application/features/chats/presentation/bloc/chat/chat_bloc.dart';
import 'package:chat_application/features/chats/presentation/widgets/message_options_helper.dart';
import 'package:intl/intl.dart';
import 'package:chat_application/features/chats/presentation/pages/image_page.dart';
import 'package:chat_application/features/timeline/presentation/bloc/time_line/timeline_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

class ImageMessageTile extends StatefulWidget {
  final Message message;
  final CacheService cacheService;
  final bool isMe;
  final bool flash;
  final VoidCallback? onDelete;
  final VoidCallback? onReply;
  final VoidCallback? onReplyTap;

  final String currentUserId;
  final String receiverId;
  final String? receiverName;

  const ImageMessageTile({
    super.key,
    required this.message,
    required this.cacheService,
    required this.isMe,
    this.flash = false,
    this.onDelete,
    this.onReply,
    this.onReplyTap,

    required this.currentUserId,
    required this.receiverId,
    this.receiverName,
  });

  @override
  State<ImageMessageTile> createState() => _ImageMessageTileState();
}

class _ImageMessageTileState extends State<ImageMessageTile>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  Uint8List? imageBytes;
  bool isLoading = true;

  /// 🔥 Animation
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scale = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_controller);

    _loadImage();
  }

  @override
  void didUpdateWidget(covariant ImageMessageTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.message.id != widget.message.id) {
      _loadImage();
    }

    /// 🔥 Trigger zoom animation
    if (widget.flash && !oldWidget.flash) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadImage() async {
    final msg = widget.message;

    /// 🧠 MEMORY CACHE
    if (widget.cacheService.cache.containsKey(msg.id)) {
      imageBytes = widget.cacheService.cache[msg.id];
      isLoading = false;
      if (mounted) setState(() {});
      return;
    }

    if (kIsWeb) {
      if (msg.localPath != null) {
        final response = await http.get(Uri.parse(msg.localPath!));
        if (response.statusCode == 200) {
          imageBytes = response.bodyBytes;
          widget.cacheService.cache[msg.id] = imageBytes!;
          isLoading = false;
          if (mounted) setState(() {});
          return;
        }
      }

      if (msg.content.isNotEmpty) {
        final response = await http.get(Uri.parse(msg.content));
        if (response.statusCode == 200) {
          imageBytes = response.bodyBytes;
          widget.cacheService.cache[msg.id] = imageBytes!;
          isLoading = false;
          if (mounted) setState(() {});
          return;
        }
      }

      isLoading = false;
      if (mounted) setState(() {});
      return;
    }

    if (msg.localPath != null) {
      final bytes = await File(msg.localPath!).readAsBytes();
      widget.cacheService.cache[msg.id] = bytes;
      imageBytes = bytes;
      isLoading = false;
      if (mounted) setState(() {});
      return;
    }

    /// 🔵 NETWORK
    if (msg.content.isNotEmpty) {
      await widget.cacheService.getOrDownload(msg.content, msg.id);

      imageBytes = widget.cacheService.cache[msg.id];
      isLoading = false;

      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return GestureDetector(
      onLongPressStart: (details) {
        final currentEmoji = widget.message.reactions[widget.currentUserId];
        MessageOptionsTray.show(
          context: context,
          position: details.globalPosition,
          messageId: widget.message.id,
          content: widget.message.content,
          isMe: widget.isMe,
          msgType: "image",

          onDelete: widget.onDelete,

          onAddToTimeline: !widget.message.inTimeline
            ? () {
                _showAddToTimelineDialog(widget.message);
              }
            : null,
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
        );
      },
      child: ScaleTransition(
        scale: _scale,
        child: Align(
          alignment:
              widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: widget.isMe
                ? const EdgeInsets.only(left: 64, right: 8, top: 6,bottom: 6)
                : const EdgeInsets.only(left: 8, right: 64, top: 6,bottom: 6),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(
              maxWidth: 250,
              maxHeight: 300,
            ),
            decoration: BoxDecoration(
              color: widget.flash
                  ? AppPallete.primaryOrange.withValues(alpha: 0.3)
                  : (widget.isMe
                      ? const Color(0xFFB84A1A)
                      : AppPallete.cardBg),
              borderRadius: BorderRadius.circular(16),
              border: widget.isMe
                  ? null
                  : Border.all(color: AppPallete.divider),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildContent(context),
            ),
          ),
        ),
      ),
    );
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
                        style: TextStyle(
                          color: AppPallete.greyText,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
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
                          colors: [
                            AppPallete.primaryOrange,
                            AppPallete.lightOrange,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "Save",
                        style: TextStyle(
                          color: AppPallete.whiteColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
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

  Widget _buildReplyPreview() {
    if (widget.message.replyToId == null) return const SizedBox();

    final isOwnReply = widget.message.replyToSenderId == widget.currentUserId;
    final senderName = isOwnReply ? "You" : (widget.receiverName ?? "Unknown");
    final previewText = widget.message.replyToType == "image"
        ? "📷 Image"
        : (widget.message.replyToContent ?? "");

    return GestureDetector(
      onTap: widget.onReplyTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
          border: Border(
            left: BorderSide(
              color: AppPallete.primaryOrange,
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
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppPallete.primaryOrange,
              ),
            ),
            Text(
              previewText,
              style: const TextStyle(
                fontSize: 12,
                color: AppPallete.whiteColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (widget.message.deletedForEveryone == true) {
      return _buildDeletedMessage();
    }
    final msg = widget.message;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        if (isLoading) {
          return SizedBox(
            width: width,
            height: height,
            child: Center(
              child: CircularProgressIndicator(
                color: AppPallete.primaryOrange,
              ),
            ),
          );
        }

        if (imageBytes != null) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.message.replyToId != null && !widget.message.deletedForEveryone)
                _buildReplyPreview(),
              Expanded(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FullScreenImagePage(
                              bytes: imageBytes!,
                              tag: msg.id,
                            ),
                          ),
                        );
                      },
                      child: Hero(
                        tag: msg.id,
                        child: SizedBox(
                          width: width,
                          child: Image.memory(
                            imageBytes!,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          ),
                        ),
                      ),
                    ),

                    Positioned(
                      bottom: 5,
                      right: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.message.inTimeline)
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Icon(Icons.favorite, size: 12, color: Colors.red),
                              ),
                            Text(
                              DateFormat('h:mm a').format(msg.createdAt),
                              style: TextStyle(
                                fontSize: 10,
                                color: AppPallete.whiteColor,
                              ),
                            ),
                            const SizedBox(width: 5),
                            _buildStatus(msg.status, widget.isMe),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        return const SizedBox();
      },
    );
  }

  Widget _buildStatus(String status, bool isMe) {
    if (!isMe) return const SizedBox();

    IconData icon;
    Color color;

    switch (status) {
      case "sending":
        icon = Icons.access_time;
        color = AppPallete.whiteColor;
        break;
      case "sent":
        icon = Icons.check;
        color = AppPallete.whiteColor;
        break;
      case "seen":
        icon = Icons.done_all;
        color = AppPallete.statusGreen;
        break;
      case "failed":
        icon = Icons.error;
        color = AppPallete.errorColor;
        break;
      default:
        icon = Icons.check;
        color = AppPallete.whiteColor;
    }

    return Icon(icon, size: 16, color: color);
  }
  
  Widget _buildDeletedMessage() {
    return Container(
      height: 40,
      width: 250,
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.block, size: 14, color: AppPallete.greyText),
          SizedBox(width: 4),
          Text(
            "This message was deleted",
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: AppPallete.greyText,
            ),
          ),
        ],
      ),
    );
  }
}