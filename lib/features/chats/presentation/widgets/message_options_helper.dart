import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const List<String> reactionEmojis = [
  '❤️', '😂', '🔥', '👍', '👎', '😮', '😢', '🎉', '💯', 
];

class MessageOptionsTray {
  static Future<void> show({
    required BuildContext context,
    required Offset position,
    required String messageId,
    required String content,
    required bool isMe,
    required String msgType,
    VoidCallback? onDelete,
    VoidCallback? onAddToTimeline,
    required void Function(String emoji) onReact,
    bool hasReacted = false,
    VoidCallback? onRemoveReaction,
    VoidCallback? onReply,
    VoidCallback? onEdit,
  }) async {
    final screenSize = MediaQuery.of(context).size;
    const popupWidth = 260.0;
    const emojiRowHeight = 64.0;
    const itemHeight = 48.0;

    int itemCount = (msgType == "text" ? 1 : 0) + (isMe ? 1 : 0) + (hasReacted ? 1 : 0) + (isMe && msgType == "text" ? 1 : 0) + 2;
    double popupHeight = emojiRowHeight + 1 + itemCount * itemHeight + 8;

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
                        children: reactionEmojis.map((emoji) => Padding(
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
                    _buildMenuItem(
                      context: ctx,
                      icon: Icons.reply,
                      label: 'Reply',
                      onTap: () {
                        Navigator.pop(ctx);
                        if (onReply != null) onReply();
                      },
                    ),
                    if (hasReacted)
                      _buildMenuItem(
                        context: ctx,
                        icon: Icons.remove_circle_outline,
                        label: 'Remove reaction',
                        isDestructive: true,
                        onTap: () {
                          Navigator.pop(ctx);
                          if (onRemoveReaction != null) onRemoveReaction();
                        },
                      ),
                    if (msgType == "text")
                      _buildMenuItem(
                        context: ctx,
                        icon: Icons.copy,
                        label: 'Copy',
                        onTap: () {
                          Navigator.pop(ctx);
                          Clipboard.setData(ClipboardData(text: content));
                        },
                      ),
                    if (isMe && msgType == "text")
                      _buildMenuItem(
                        context: ctx,
                        icon: Icons.edit,
                        label: 'Edit',
                        onTap: () {
                          Navigator.pop(ctx);
                          if (onEdit != null) onEdit();
                        },
                      ),
                      _buildMenuItem(
                        context: ctx,
                        icon: Icons.delete_outline,
                        label: 'Delete',
                        isDestructive: true,
                        onTap: () {
                          Navigator.pop(ctx);
                          if (onDelete != null) onDelete();
                        },
                      ),
                    _buildMenuItem(
                      context: ctx,
                      icon: Icons.favorite,
                      label: onAddToTimeline != null ? 'Add to Timeline' : 'Already in Timeline',
                      isDisabled: onAddToTimeline == null,
                      onTap: () {
                        Navigator.pop(ctx);
                        if (onAddToTimeline != null) onAddToTimeline();
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

  static Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    bool isDestructive = false,
    bool isDisabled = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: isDisabled ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDisabled
                  ? AppPallete.greyText.withValues(alpha: 0.5)
                  : (isDestructive ? AppPallete.errorColor : AppPallete.whiteColor),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isDisabled
                    ? AppPallete.greyText.withValues(alpha: 0.5)
                    : (isDestructive ? AppPallete.errorColor : AppPallete.whiteColor),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
