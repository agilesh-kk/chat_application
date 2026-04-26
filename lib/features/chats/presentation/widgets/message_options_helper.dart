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

    // callback functions
    VoidCallback? onDelete,
    VoidCallback? onAddToTimeline,
  }) async {
    final selected = await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: [
        //copy
        if(msgType == "text")
        const PopupMenuItem(
          value: 'copy',
          child: Text('Copy'),
        ),

        //delete only if user's
        if (isMe)
          const PopupMenuItem(
            value: 'delete',
            child: Text('Delete'),
          ),

        //adding to timeline
        // ✅ ONLY show if callback exists
        PopupMenuItem(
          value: 'timeline',
          enabled: onAddToTimeline != null, // 🔥 key line
          child: Text(
            onAddToTimeline != null
                ? 'Add to Timeline'
                : 'Already in Timeline',
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
        // ScaffoldMessenger.of(context).showSnackBar(
        //   const SnackBar(content: Text('Copied')),
        // );
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