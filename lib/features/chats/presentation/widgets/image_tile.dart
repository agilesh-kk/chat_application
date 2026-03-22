import 'dart:io';
import 'dart:typed_data';

import 'package:chat_application/features/chats/domain/entities/message.dart';
import 'package:chat_application/features/chats/presentation/helper/cacheservice.dart';
import 'package:chat_application/features/chats/presentation/pages/image_page.dart';
import 'package:flutter/material.dart';

class ImageMessageTile extends StatefulWidget {
  final Message message;
  final CacheService cacheService;
  final bool isMe;

  const ImageMessageTile({
    super.key,
    required this.message,
    required this.cacheService,
    required this.isMe,
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

  @override
  void initState() {
    super.initState();
    _loadImage(); // ✅ ONLY HERE
  }

  @override
  void didUpdateWidget(covariant ImageMessageTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.message.id != widget.message.id) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    final msg = widget.message;

    // 🧠 MEMORY CACHE
    if (widget.cacheService.cache.containsKey(msg.id)) {
      imageBytes = widget.cacheService.cache[msg.id];
      isLoading = false;
      if (mounted) setState(() {});
      return;
    }

    // 🟢 LOCAL
    if (msg.localPath != null) {
      final bytes = await File(msg.localPath!).readAsBytes();
      widget.cacheService.cache[msg.id] = bytes;
      imageBytes = bytes;
      isLoading = false;
      if (mounted) setState(() {});
      return;
    }

    // 🔵 NETWORK
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

    return Align(
      alignment:
          widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(
          maxWidth: 250,
          maxHeight: 300,
        ),
        decoration: BoxDecoration(
          color: widget.isMe
              ? const Color.fromARGB(255, 246, 152, 11)
              : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
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
            child: _buildStatus(msg.status,widget.isMe),
          ),
        ],
      );
    }

    return const SizedBox();
  }

  Widget _buildStatus(String status, bool isMe) {
    if(!isMe){
      return SizedBox();
    }

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
        color = Colors.blue; // 🔥 like WhatsApp
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
}