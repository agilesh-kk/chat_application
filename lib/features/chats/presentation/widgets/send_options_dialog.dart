import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class SendOptionsDialog extends StatelessWidget {
  final VoidCallback onSendNormally;
  final VoidCallback onTimeCapsule;
  const SendOptionsDialog({
    super.key,
    required this.onSendNormally,
    required this.onTimeCapsule,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Send options"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.send),
            title: const Text("Send normally"),
            onTap: () {
              Navigator.pop(context);
              onSendNormally();
            },
          ),
          ListTile(
            leading: const Icon(Icons.lock_clock),
            title: const Text("Create Timecapsule"),
            onTap: () {
              Navigator.pop(context);
              onTimeCapsule();
            },
          )
        ],
      ),
    );
  }
}