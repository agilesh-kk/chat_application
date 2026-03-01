import 'package:flutter/material.dart';

class UserStatusColumn extends StatelessWidget {
  final String name;
  final VoidCallback onPressed;
  const UserStatusColumn({
    super.key, 
    required this.name, 
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          children :
          [
            CircleAvatar(
              radius: 30,
            ),
            IconButton(
              onPressed: onPressed, 
              icon: Icon(Icons.add_a_photo)
            ),
          ]
        ),
        SizedBox(width: 20,),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: TextStyle(
                fontSize: 20
              ),
            ),
            Text("Disappears after 24 hours"), //add text style
            
          ],
        )
      ],
    );
  }
}