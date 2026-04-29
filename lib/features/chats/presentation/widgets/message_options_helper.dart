import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  }) async {
    final selected = await showMenu(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: AppPallete.cardBg,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        if(msgType == "text")
        PopupMenuItem(
          value: 'copy',
          child: _buildMenuItem(
            icon: Icons.copy,
            label: 'Copy',
          ),
        ),
        if (isMe)
          PopupMenuItem(
            value: 'delete',
            child: _buildMenuItem(
              icon: Icons.delete_outline,
              label: 'Delete',
              isDestructive: true,
            ),
          ),
        PopupMenuItem(
          value: 'timeline',
          enabled: onAddToTimeline != null,
          child: _buildMenuItem(
            icon: Icons.favorite,
            label: onAddToTimeline != null
                ? 'Add to Timeline'
                : 'Already in Timeline',
            isDisabled: onAddToTimeline == null,
          ),
        ),
      ],
    );

    _handleAction(
      context: context,
      action: selected,
      content: content,
      onDelete: onDelete,
      onAddToTimeline: onAddToTimeline,
    );
  }

  static Widget _buildMenuItem({
    required IconData icon,
    required String label,
    bool isDestructive = false,
    bool isDisabled = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
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
    );
  }

  static void _handleAction({
    required BuildContext context,
    required String? action,
    required String content,
    VoidCallback? onDelete,
    VoidCallback? onAddToTimeline,
  }) {
    if (action == null) return;

    switch (action) {
      case 'copy':
        Clipboard.setData(ClipboardData(text: content));
        break;

      case 'delete':
        if (onDelete != null) onDelete();
        break;

      case 'timeline':
        if (onAddToTimeline != null) onAddToTimeline();
        break;
    }
  }
}