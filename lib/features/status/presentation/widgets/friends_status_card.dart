import 'package:chat_application/features/status/domain/entities/status.dart';
import 'package:flutter/material.dart';

class FriendsStatusCard extends StatelessWidget {
  final Status status;
  final VoidCallback onstatusTap;
  const FriendsStatusCard({
    super.key, 
    required this.status,
    required this.onstatusTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onstatusTap,
      child: Container(
        height: 80,
        margin: EdgeInsets.all(16).copyWith(
          bottom: 5,
        ),
        padding: EdgeInsets.all(5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.amberAccent
        ),
        child: Row(
          children: [
            CircleAvatar(
              //backgroundImage: ,
              radius: 30,
            ),
            Column(
              children: [
                Text(status.userName),
                Text(status.createdAt.toString()),
              ],
            )
          ],
        ),
      ),
    );
  }
}