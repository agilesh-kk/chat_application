import 'package:flutter/material.dart';

class TimelineOptionsTray {
  static Future<void> show({
    required BuildContext context,
    required Offset position,
    required VoidCallback onDelete,
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
        const PopupMenuItem(
          value: "delete",
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red),
              SizedBox(width: 10),
              Text("Delete from timeline"),
            ],
          ),
        ),
      ],
    );

    if (selected == "delete") {
      _confirmDelete(context, onDelete);
    }
  }

  // 🔥 confirmation dialog
  static void _confirmDelete(
    BuildContext context,
    VoidCallback onDelete,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Remove memory?"),
        content: const Text("This will remove it from timeline"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete();
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}