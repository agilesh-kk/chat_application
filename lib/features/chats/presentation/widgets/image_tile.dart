import 'dart:io';
import 'dart:typed_data';

import 'package:chat_application/core/common/cubit/app_user_cubit.dart';
import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/features/chats/domain/entities/message.dart';
import 'package:chat_application/features/chats/presentation/helper/cacheservice.dart';
import 'package:chat_application/features/chats/presentation/widgets/message_options_helper.dart';
import 'package:chat_application/features/chats/presentation/pages/image_page.dart';
import 'package:chat_application/features/timeline/presentation/bloc/time_line/timeline_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ImageMessageTile extends StatefulWidget {
  final Message message;
  final CacheService cacheService;
  final bool isMe;
  final bool flash;
  final VoidCallback? onDelete;

  final String currentUserId;
  final String receiverId;

  const ImageMessageTile({
    super.key,
    required this.message,
    required this.cacheService,
    required this.isMe,
    this.flash = false,
    this.onDelete,

    required this.currentUserId,
    required this.receiverId,
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
      duration: const Duration(milliseconds: 400),
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

    /// 🟢 LOCAL FILE
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
        );
      },
      child: ScaleTransition(
        scale: _scale,
        child: Align(
          alignment:
              widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin:
                const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(
              maxWidth: 250,
              maxHeight: 300,
            ),
            decoration: BoxDecoration(
              color: widget.flash
                  ? AppPallete.primaryOrange.withValues(alpha: 0.3)
                  : (widget.isMe
                      ? AppPallete.primaryOrange
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

  Widget _buildContent(BuildContext context) {
    if (widget.message.deletedForEveryone == true) {
      return _buildDeletedMessage();
    }
    final msg = widget.message;

    if (isLoading) {
      return SizedBox(
        height: 150,
        width: 150,
        child: Center(
          child: CircularProgressIndicator(
            color: AppPallete.primaryOrange,
          ),
        ),
      );
    }

    if (imageBytes != null) {
      return Stack(
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
              child: Image.memory(
                imageBytes!,
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            ),
          ),

          Positioned(
            bottom: 5,
            right: 5,
            child: _buildStatus(msg.status, widget.isMe),
          ),
        ],
      );
    }

    return const SizedBox();
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