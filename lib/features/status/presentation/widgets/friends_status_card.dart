import 'package:chat_application/core/utils/moments_ago.dart';
import 'package:chat_application/features/status/domain/entities/status.dart';
import 'package:flutter/material.dart';

class FriendsStatusCard extends StatelessWidget {
  final Status status;
  final VoidCallback onstatusTap;
  final String displayPicUrl;
  final String latestStatusTime;
  const FriendsStatusCard({
    super.key, 
    required this.status,
    required this.onstatusTap,
    required this.displayPicUrl,
    required this.latestStatusTime,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onstatusTap,
      child: Container(
        height: 80,
        margin: EdgeInsets.all(5).copyWith(
          bottom: 5,
        ),
        padding: EdgeInsets.all(5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          //color: Colors.amberAccent
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(displayPicUrl),
              radius: 30,
            ),
            SizedBox(width:20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.userName,
                  style: TextStyle(
                    fontSize: 20,
                    //fontWeight: FontWeight.bold
                  ),
                ),
                SizedBox(height: 5,),
                Text(
                  MomentsAgo.calculateMomentsAgo(latestStatusTime),
                  style: TextStyle(
                    color: const Color.fromARGB(255, 105, 122, 131),
                    fontSize: 15
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}