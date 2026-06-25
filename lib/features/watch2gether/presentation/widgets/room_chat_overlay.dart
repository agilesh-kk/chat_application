import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/features/chats/presentation/helper/emoji_lottie_map.dart';
import 'package:chat_application/features/chats/presentation/widgets/reply_preview_bar.dart';
import 'package:chat_application/features/watch2gether/domain/entity/w2g_chat_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:emoji_regex/emoji_regex.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';

const List<String> _reactionEmojis = [
  '❤️', '😂', '🔥', '👍', '👎', '😮', '😢', '🎉', '💯',
];

class RoomChatOverlay extends StatefulWidget {
  final List<W2GChatMessage> messages;
  final Set<String> typingUserIds;
  final String currentUserId;
  final String currentUserName;
  final W2GChatMessage? replyToMessage;
  final Function(String text) onSend;
  final VoidCallback onSendImage;
  final Function(W2GChatMessage message) onReply;
  final VoidCallback onCancelReply;
  final Function(String messageId, String emoji) onReact;
  final Function(bool isTyping) onTyping;

  const RoomChatOverlay({
    super.key,
    required this.messages,
    this.typingUserIds = const {},
    required this.currentUserId,
    required this.currentUserName,
    this.replyToMessage,
    required this.onSend,
    required this.onSendImage,
    required this.onReply,
    required this.onCancelReply,
    required this.onReact,
    required this.onTyping,
  });

  @override
  State<RoomChatOverlay> createState() => _RoomChatOverlayState();
}

class _RoomChatOverlayState extends State<RoomChatOverlay> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isScrolledUp = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final isUp = currentScroll < maxScroll - 100;
    if (isUp != _isScrolledUp) setState(() => _isScrolledUp = isUp);
  }

  @override
  void didUpdateWidget(RoomChatOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messages.length > oldWidget.messages.length) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final otherTyping = widget.typingUserIds
        .where((id) => id != widget.currentUserId)
        .toSet();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
          color: AppPallete.cardBg.withValues(alpha: 0.85),
          child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  itemCount: widget.messages.length,
                  itemBuilder: (context, index) {
                    final msg = widget.messages[index];
                    final isMe = msg.senderId == widget.currentUserId;
                    return _MessageBubble(
                      message: msg,
                      isMe: isMe,
                      currentUserId: widget.currentUserId,
                      currentUserName: widget.currentUserName,
                      onReply: () => widget.onReply(msg),
                      onReact: (emoji) => widget.onReact(msg.id, emoji),
                    );
                  },
                ),
                if (_isScrolledUp)
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: GestureDetector(
                        onTap: _scrollToBottom,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppPallete.cardBg,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                          ),
                          child: const Icon(Icons.arrow_downward, color: AppPallete.primaryOrange, size: 20),
                        ),
                      ),
                    ),
                  ),
                if (otherTyping.isNotEmpty)
                  Positioned(
                    bottom: 4,
                    left: 12,
                    child: _TypingIndicator(
                      typingUserIds: otherTyping,
                      messages: widget.messages,
                    ),
                  ),
              ],
            ),
          ),
          if (widget.replyToMessage != null)
            ReplyPreviewBar(
              replyingToName: widget.replyToMessage!.senderId == widget.currentUserId
                  ? 'You'
                  : widget.replyToMessage!.senderName,
              replyContent: widget.replyToMessage!.text,
              replyType: widget.replyToMessage!.type,
              onCancel: widget.onCancelReply,
            ),
          _buildInputBar(),
        ],
      ),
      ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppPallete.darkBg.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(color: AppPallete.divider.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.image_outlined, color: AppPallete.primaryOrange, size: 24),
            onPressed: widget.onSendImage,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Chat...',
                hintStyle: TextStyle(color: AppPallete.greyText.withValues(alpha: 0.5)),
                filled: true,
                fillColor: AppPallete.inputBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onChanged: (_) => widget.onTyping(_controller.text.isNotEmpty),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.send, color: AppPallete.primaryOrange),
            onPressed: _send,
          ),
        ],
      ),
    );
  }

  void _send() {
    widget.onTyping(false);
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
  }
}

class _MessageBubble extends StatelessWidget {
  final W2GChatMessage message;
  final bool isMe;
  final String currentUserId;
  final String currentUserName;
  final VoidCallback onReply;
  final Function(String emoji) onReact;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.currentUserId,
    required this.currentUserName,
    required this.onReply,
    required this.onReact,
  });

  bool get _isEmojiOnly {
    final regex = emojiRegex();
    final emojiCount = regex.allMatches(message.text).length;
    final onlyEmojis = message.text.replaceAll(regex, '').trim().isEmpty;
    return message.type == 'text' && onlyEmojis && emojiCount > 0;
  }

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('h:mm a').format(message.timestamp);
    final hasReactions = message.reactions.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (message.replyToId != null) _buildReplyPreview(context),
          Stack(
            clipBehavior: Clip.none,
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            children: [
              _buildBubble(context, time),
              if (hasReactions)
                Positioned(
                  left: isMe ? null : 8,
                  right: isMe ? 8 : null,
                  bottom: -10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppPallete.cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppPallete.divider),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: message.reactions.values.toSet().map((emoji) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 1),
                          child: Text(emoji, style: const TextStyle(fontSize: 11)),
                        );
                      }).toList(),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(BuildContext context, String time) {
    if (message.type == 'image') {
      return _buildImageBubble(context, time);
    }

    final regex = emojiRegex();
    final emojiCount = regex.allMatches(message.text).length;
    final onlyEmojis = message.text.replaceAll(regex, '').trim().isEmpty;

    double fontSize = 15;
    if (onlyEmojis && emojiCount > 0) {
      if (emojiCount == 1) {
        fontSize = 60;
      } else if (emojiCount == 2) {
        fontSize = 44;
      }
    }

    final lottie = _isEmojiOnly ? getLottieForEmoji(message.text) : null;

    return GestureDetector(
      onLongPressStart: (details) => _showOptions(context, details.globalPosition),
      child: Container(
        margin: isMe
            ? EdgeInsets.only(left: 64, right: 8, top: 4, bottom: hasReactions ? 15 : 4)
            : EdgeInsets.only(left: 8, right: 64, top: 4, bottom: hasReactions ? 15 : 4),
        padding: _isEmojiOnly
            ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: _isEmojiOnly
              ? Colors.transparent
              : (isMe ? const Color(0xFFB84A1A) : AppPallete.cardBg),
          borderRadius: BorderRadius.circular(16),
          border: _isEmojiOnly ? null : (isMe ? null : Border.all(color: AppPallete.divider)),
        ),
        child: lottie != null
            ? Lottie.asset(lottie.bundledAsset, width: 120, height: 120, fit: BoxFit.contain)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      message.text,
                      style: TextStyle(
                        fontSize: fontSize,
                        color: isMe ? AppPallete.whiteColor : AppPallete.whiteColor,
                      ),
                    ),
                  ),
                  if (!_isEmojiOnly) ...[
                    const SizedBox(width: 6),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 10,
                        color: isMe
                            ? AppPallete.whiteColor.withValues(alpha: 0.7)
                            : AppPallete.greyText,
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildImageBubble(BuildContext context, String time) {
    return GestureDetector(
      onLongPressStart: (details) => _showOptions(context, details.globalPosition),
      child: Container(
        margin: isMe
            ? EdgeInsets.only(left: 64, right: 8, top: 4, bottom: hasReactions ? 15 : 4)
            : EdgeInsets.only(left: 8, right: 64, top: 4, bottom: hasReactions ? 15 : 4),
        padding: const EdgeInsets.all(4),
        constraints: const BoxConstraints(maxWidth: 250),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xFFB84A1A) : AppPallete.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: isMe ? null : Border.all(color: AppPallete.divider),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: message.imageUrl != null && message.imageUrl!.isNotEmpty
                  ? GestureDetector(
                      onTap: () => _openFullImage(context, message.imageUrl!),
                      child: Image.network(
                        message.imageUrl!,
                        width: 242,
                        fit: BoxFit.scaleDown,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 200,
                            color: AppPallete.darkTertiary,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppPallete.primaryOrange,
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: AppPallete.darkTertiary,
                            child: const Center(
                              child: Icon(Icons.broken_image, color: AppPallete.greyText),
                            ),
                          );
                        },
                      ),
                    )
                  : Container(
                      height: 200,
                      color: AppPallete.darkTertiary,
                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppPallete.primaryOrange)),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4, right: 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  time,
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe
                        ? AppPallete.whiteColor.withValues(alpha: 0.7)
                        : AppPallete.greyText,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview(BuildContext context) {
    final isOwnReply = message.replyToSenderId == currentUserId;
    final senderName = isOwnReply ? 'You' : message.senderName;
    String previewText;
    if (message.replyToType == 'image') {
      previewText = '📷 Image';
    } else {
      previewText = message.replyToContent ?? '';
    }

    return Container(
      margin: EdgeInsets.only(
        left: isMe ? 64 : 0,
        right: isMe ? 0 : 64,
        bottom: 2,
      ),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isMe
            ? AppPallete.primaryOrange.withValues(alpha: 0.2)
            : AppPallete.darkBg.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border(
          left: BorderSide(
            color: isMe ? AppPallete.lightOrange : AppPallete.primaryOrange,
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
              color: isMe ? AppPallete.lightOrange : AppPallete.primaryOrange,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            previewText,
            style: TextStyle(
              fontSize: 13,
              color: isMe
                  ? AppPallete.whiteColor.withValues(alpha: 0.8)
                  : AppPallete.greyText,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  bool get hasReactions => message.reactions.isNotEmpty;

  void _showOptions(BuildContext context, Offset position) {
    final screenSize = MediaQuery.of(context).size;
    const popupWidth = 260.0;
    const emojiRowHeight = 64.0;
    const itemHeight = 48.0;

    final itemCount = 2;
    final popupHeight = emojiRowHeight + 1 + itemCount * itemHeight + 8;

    double left = position.dx;
    double top = position.dy + 8;

    if (left + popupWidth > screenSize.width - 16) {
      left = screenSize.width - popupWidth - 16;
    }
    if (top + popupHeight > screenSize.height - 16) {
      top = position.dy - popupHeight - 8;
    }
    left = left.clamp(8, screenSize.width - popupWidth - 8);
    top = top.clamp(8, screenSize.height - popupHeight - 8);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Stack(
        children: [
          Positioned(
            left: left,
            top: top,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: popupWidth,
                decoration: BoxDecoration(
                  color: AppPallete.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppPallete.divider),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                      child: Row(
                        children: _reactionEmojis.map((emoji) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(ctx);
                              onReact(emoji);
                            },
                            child: Text(emoji, style: const TextStyle(fontSize: 24)),
                          ),
                        )).toList(),
                      ),
                    ),
                    Divider(height: 1, color: AppPallete.divider.withValues(alpha: 0.5)),
                    _menuItem(
                      icon: Icons.reply,
                      label: 'Reply',
                      onTap: () {
                        Navigator.pop(ctx);
                        onReply();
                      },
                    ),
                    _menuItem(
                      icon: Icons.content_copy,
                      label: 'Copy text',
                      onTap: () {
                        Navigator.pop(ctx);
                        Clipboard.setData(ClipboardData(text: message.text));
                      },
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _menuItem({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppPallete.whiteColor),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(color: AppPallete.whiteColor, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  void _openFullImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: InteractiveViewer(
            minScale: 1,
            maxScale: 5,
            child: Center(
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  final Set<String> typingUserIds;
  final List<W2GChatMessage> messages;

  const _TypingIndicator({required this.typingUserIds, required this.messages});

  @override
  Widget build(BuildContext context) {
    final names = <String>{};
    for (final msg in messages) {
      if (typingUserIds.contains(msg.senderId)) {
        names.add(msg.senderName);
      }
    }
    if (names.isEmpty) return const SizedBox();

    final text = names.length == 1
        ? '${names.first} is typing...'
        : '${names.first} and ${names.length - 1} more typing...';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12, height: 12,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppPallete.primaryOrange.withValues(alpha: 0.7)),
          ),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: AppPallete.greyText.withValues(alpha: 0.7), fontSize: 11, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}
