import 'package:flutter/material.dart';

class UserStatusColumn extends StatelessWidget {
  final String name;
  final VoidCallback onAddStatus;
  final VoidCallback onViewStatus;

  const UserStatusColumn({
    super.key,
    required this.name,
    required this.onAddStatus,
    required this.onViewStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          children: [
            GestureDetector(
              onTap: onViewStatus,
              child: const CircleAvatar(
                radius: 30,
              ),
            ),

            Positioned(
              bottom: -5,
              right: -5,
              child: IconButton(
                onPressed: onAddStatus,
                icon: const Icon(Icons.add_a_photo),
              ),
            ),
          ],
        ),

        const SizedBox(width: 20),

        GestureDetector(
          onTap: onViewStatus,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(fontSize: 20),
              ),
              const Text("Disappears after 24 hours"),
            ],
          ),
        )
      ],
    );
  }
}