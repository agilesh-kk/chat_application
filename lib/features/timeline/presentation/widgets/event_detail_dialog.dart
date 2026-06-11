import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/core/utils/moments_ago.dart';
import 'package:chat_application/features/profile/presentation/pages/profile_image_viewer.dart';
import 'package:chat_application/features/timeline/domain/entities/event.dart';
import 'package:flutter/material.dart';

class EventDetailDialog {
  static void show(BuildContext context, Event event) {
    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: AppPallete.transparentColor,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppPallete.cardBg,
                  AppPallete.darkTertiary,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppPallete.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppPallete.primaryOrange,
                            AppPallete.lightOrange,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _icon(event.type),
                        color: AppPallete.whiteColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppPallete.whiteColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            MomentsAgo.calculateMomentsAgo(
                              event.time.toString(),
                            ),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppPallete.greyText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (event.hasImage) ...[
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileImageViewer(
                            imageProvider: NetworkImage(event.imageUrl),
                            heroTag: '${event.id}_detail',
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        event.imageUrl,
                        height: 240,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox(),
                      ),
                    ),
                  ),
                ],
                if (event.type == "image" && !event.hasImage) ...[
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProfileImageViewer(
                            imageProvider: NetworkImage(event.content),
                            heroTag: '${event.id}_detail',
                          ),
                        ),
                      );
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        event.content,
                        height: 240,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const SizedBox(),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(
                      event.content,
                      softWrap: true,
                      style: TextStyle(
                        color: AppPallete.whiteColor.withValues(alpha: 0.85),
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
                if (event.isManual) ...[
                  const SizedBox(height: 12),
                  Text(
                    "Added by ${event.addedByName}",
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppPallete.greyText,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppPallete.divider),
                      ),
                    ),
                    child: const Text(
                      "Close",
                      style: TextStyle(
                        color: AppPallete.greyText,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static IconData _icon(String type) {
    switch (type) {
      case "image":
        return Icons.image;
      case "milestone":
        return Icons.star;
      default:
        return Icons.message;
    }
  }
}
