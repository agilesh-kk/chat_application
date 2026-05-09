import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/core/utils/moments_ago.dart';
import 'package:flutter/material.dart';

class ConvoTile extends StatelessWidget {
  final String name;
  final String profilePic;
  final String lastUpdateTime;
  final String lastMessage;
  final int unread;
  final String lastSender;
  final bool isOnline;
  final GestureTapCallback onTap;

  const ConvoTile({
    super.key,
    required this.unread,
    required this.name,
    required this.lastMessage,
    required this.profilePic,
    required this.lastUpdateTime,
    required this.lastSender,
    required this.isOnline,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppPallete.cardBg.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppPallete.divider.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            AppPallete.primaryOrange.withValues(alpha: 0.6),
                            AppPallete.lightOrange.withValues(alpha: 0.3),
                            AppPallete.primaryOrange.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundImage: (profilePic.toLowerCase() != "not found")
                            ? AssetImage(profilePic)
                            : null,
                        backgroundColor: AppPallete.darkTertiary,
                        child: (profilePic.toLowerCase() == "not found")
                            ? Icon(
                                Icons.person,
                                color: AppPallete.greyText,
                                size: 28,
                              )
                            : null,
                      ),
                    ),
                    if (isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppPallete.statusGreen,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppPallete.cardBg,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontWeight: unread > 0
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                fontSize: 16,
                                color: AppPallete.whiteColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            MomentsAgo.calculateMomentsAgo(lastUpdateTime),
                            style: TextStyle(
                              color: unread > 0
                                  ? AppPallete.primaryOrange
                                  : AppPallete.greyText,
                              fontSize: 12,
                              fontWeight: unread > 0
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (unread > 0) ...[
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: AppPallete.primaryOrange,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(
                              lastSender.isEmpty
                                  ? lastMessage
                                  : "you: $lastMessage",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: unread > 0
                                    ? AppPallete.whiteColor
                                    : AppPallete.greyText,
                                fontSize: 14,
                                fontWeight: unread > 0
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (unread > 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppPallete.primaryOrange,
                                    AppPallete.lightOrange,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                unread > 99 ? "99+" : unread.toString(),
                                style: TextStyle(
                                  color: AppPallete.whiteColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}