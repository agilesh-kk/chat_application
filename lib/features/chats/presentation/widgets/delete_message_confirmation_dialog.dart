import 'package:flutter/material.dart';

class DeleteMessageConfirmationDialog extends StatelessWidget {
  final String messageContent;
  final VoidCallback onDeleteForMe;
  final VoidCallback onDeleteForEveryone;

  const DeleteMessageConfirmationDialog({
    super.key,
    required this.messageContent,
    required this.onDeleteForMe,
    required this.onDeleteForEveryone,
  });

  static Future<void> show(
    BuildContext context, {
    required String messageContent,
    required VoidCallback onDeleteForMe,
    required VoidCallback onDeleteForEveryone,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (_) => DeleteMessageConfirmationDialog(
        messageContent: messageContent,
        onDeleteForMe: onDeleteForMe,
        onDeleteForEveryone: onDeleteForEveryone,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Message'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Do you want to delete this message?'),
          const SizedBox(height: 12),
          Text(
            messageContent,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onDeleteForMe();
          },
          child: const Text('Delete for me'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            onDeleteForEveryone();
          },
          child: const Text('Delete for everyone'),
        ),
      ],
    );
  }
}
