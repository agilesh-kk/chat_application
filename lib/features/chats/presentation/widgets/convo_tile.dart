import 'package:chat_application/core/utils/moments_ago.dart';
import 'package:flutter/material.dart';

class ConvoTile extends StatelessWidget {
  final String name;
  final String profilePic;
  final String lastUpdateTime;
  final String lastMessage;
  final int unread;
  final GestureTapCallback onTap;

  const ConvoTile({
    super.key,
    required this.unread,
    required this.name,
    required this.lastMessage,
    required this.profilePic,
    required this.lastUpdateTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    //print(profilePic);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Profile Picture
            CircleAvatar(
              radius: 26,
              backgroundImage: (profilePic.toLowerCase() != "not found")
                  ? AssetImage(profilePic)
                  : null,
              child: (profilePic.toLowerCase() == "not found")
                  ? const Icon(Icons.person)
                  : null,
            ),

            const SizedBox(width: 12),

            // Name + Message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Time
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                buildUnread(unread),
                Text(
                  MomentsAgo.calculateMomentsAgo(lastUpdateTime),
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildUnread(int unread){
    if(unread < 1)return SizedBox();

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: const BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
        constraints: const BoxConstraints(
          minWidth: 20,
          minHeight: 20,
        ),
        child: Center(
          child: Text(
            unread > 99 ? "99+" : unread.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
  }
}