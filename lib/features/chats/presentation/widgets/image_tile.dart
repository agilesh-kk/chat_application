import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

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
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Uint8List? imageBytes;
  bool isLoading = true;
  double _displayW = 242;
  static final Map<String, double> _imageSizeCache = {};

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant ImageMessageTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.message.id != widget.message.id) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (!isLoading && imageBytes != null) return;

    final msg = widget.message;

    if (widget.cacheService.cache.containsKey(msg.id)) {
      imageBytes = widget.cacheService.cache[msg.id];
      isLoading = false;

      final cached = _imageSizeCache[msg.id];
      if (cached != null) {
        _displayW = cached;
      }

      if (mounted) setState(() {});

      if (cached == null) {
        _cacheImageSize(msg.id, imageBytes!);
      }
      return;
    }

    if (kIsWeb) {
      if (msg.localPath != null) {
        final response = await http.get(Uri.parse(msg.localPath!));
        if (response.statusCode == 200) {
          imageBytes = response.bodyBytes;
          widget.cacheService.cache[msg.id] = response.bodyBytes;
          isLoading = false;
          if (mounted) setState(() {});
          return;
        }
      }

      if (msg.content.isNotEmpty) {
        final response = await http.get(Uri.parse(msg.content));
        if (response.statusCode == 200) {
          imageBytes = response.bodyBytes;
          widget.cacheService.cache[msg.id] = response.bodyBytes;
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
      _cacheImageSize(msg.id, bytes);
      return;
    }

    if (msg.content.isNotEmpty) {
      await widget.cacheService.getOrDownload(msg.content, msg.id);
      imageBytes = widget.cacheService.cache[msg.id];
      isLoading = false;
      if (mounted) setState(() {});
      if (imageBytes != null) {
        _cacheImageSize(msg.id, imageBytes!);
      }
    }
  }

  Future<void> _cacheImageSize(String id, Uint8List bytes) async {
    if (_imageSizeCache.containsKey(id)) return;
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final rawW = frame.image.width.toDouble();
      final rawH = frame.image.height.toDouble();
      frame.image.dispose();
      codec.dispose();
      double w = rawW, h = rawH;
      if (w > 242) {
        h *= 242 / w;
        w = 242;
      }
      if (h > 292) {
        w *= 292 / h;
      }
      _imageSizeCache[id] = w;
      if (mounted && widget.message.id == id) {
        setState(() { _displayW = w; });
      }
    } catch (_) {}
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
      child: Align(
        alignment:
            widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: widget.isMe
              ? const EdgeInsets.only(left: 64, right: 8, top: 6,bottom: 6)
              : const EdgeInsets.only(left: 8, right: 64, top: 6,bottom: 6),
          padding: const EdgeInsets.all(4),
          constraints: const BoxConstraints(maxWidth: 250),
          decoration: BoxDecoration(
            color: widget.flash
                ? Colors.amberAccent.withValues(alpha: 0.25)
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

    if (isLoading) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: CircularProgressIndicator(color: AppPallete.primaryOrange),
        ),
      );
    }

    if (imageBytes != null) {
      final hasReply = widget.message.replyToId != null && !widget.message.deletedForEveryone;

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasReply) ...[
            SizedBox(width: _displayW, child: _buildReplyPreview()),
            const SizedBox(height: 4),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 242, maxHeight: 292),
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
                    child: Image.memory(
                      imageBytes!,
                      fit: BoxFit.scaleDown,
                      gaplessPlayback: true,
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
                          style: const TextStyle(
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
