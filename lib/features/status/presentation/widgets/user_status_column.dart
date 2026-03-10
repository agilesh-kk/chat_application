import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:flutter/material.dart';

class UserStatusColumn extends StatelessWidget {
  final String name;
  final VoidCallback onAddStatus;
  final VoidCallback? onViewStatus;
  final bool hasStatus;
  final String? image;

  const UserStatusColumn({
    super.key,
    required this.name,
    required this.onAddStatus,
    required this.onViewStatus,
    required this.image, 
    required this.hasStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          children: [
            GestureDetector(
              onTap: onViewStatus,
              child: CircleAvatar(
                radius: 30,
                backgroundImage: image != null ? NetworkImage(image!) : null,
                backgroundColor: AppPallete.transparentColor,
                child: image == null ? const Icon(Icons.person) : null,
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
        if(!hasStatus)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(fontSize: 20),
              ),
              const Text("Disappears after 24 hours"),
            ],
          )
        
        else
        GestureDetector(
          onTap: onViewStatus,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "My status",
                style: const TextStyle(fontSize: 20),
              ),
              //const Text("Disappears after 24 hours"),
            ],
          ),
        )
        
      ],
    );
  }
}