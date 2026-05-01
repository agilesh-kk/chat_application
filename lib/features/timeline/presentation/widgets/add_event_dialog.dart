import 'package:flutter/material.dart';

class AddEventDialog {
  static Future<Map<String, String>?> show(BuildContext context) async {
    final titleController = TextEditingController(text: "New Note");
    final contentController = TextEditingController();

    return await showDialog<Map<String, String>>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Add Note"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Title"),
              ),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(labelText: "Content"),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final title = titleController.text.trim().isEmpty
                    ? "New Note"
                    : titleController.text.trim();

                final content = contentController.text.trim();

                if (content.isEmpty) return;

                Navigator.pop(context, {
                  "title": title,
                  "content": content,
                });
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }
}