import 'dart:io';
import 'dart:typed_data';

import 'package:chat_application/core/common/cubit/app_user_cubit.dart';
import 'package:chat_application/features/chats/domain/entities/message.dart';
import 'package:chat_application/features/chats/presentation/helper/cacheservice.dart';
import 'package:chat_application/features/chats/presentation/widgets/message_options_helper.dart';
import 'package:chat_application/features/chats/presentation/pages/image_page.dart';
import 'package:chat_application/features/timeline/presentation/bloc/timeline_bloc.dart';
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
                  ? Colors.yellow.withOpacity(0.3) // 🔥 highlight glow
                  : (widget.isMe
                      ? const Color.fromARGB(255, 246, 152, 11)
                      : Colors.grey[300]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
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
              //print("add event triggred");
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

  Widget _buildContent(BuildContext context) {
    if (widget.message.deletedForEveryone == true) {
      return _buildDeletedMessage();
    }
    final msg = widget.message;

    if (isLoading) {
      return const SizedBox(
        height: 150,
        width: 150,
        child: Center(child: CircularProgressIndicator()),
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
          Positioned(
            bottom: 7,
            right:20,
            child: (widget.message.inTimeline) ?
              Icon(Icons.favorite, size: 12, color: Colors.red) :
              SizedBox(width: 4),
              
          )
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
        color = Colors.white;
        break;
      case "sent":
        icon = Icons.check;
        color = Colors.white;
        break;
      case "seen":
        icon = Icons.done_all;
        color = Colors.blue;
        break;
      case "failed":
        icon = Icons.error;
        color = Colors.red;
        break;
      default:
        icon = Icons.check;
        color = Colors.white;
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
          Icon(Icons.block, size: 14, color: Colors.grey),
          SizedBox(width: 4),
          Text(
            "This message was deleted",
            style: TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}