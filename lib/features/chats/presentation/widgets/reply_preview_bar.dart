import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:flutter/material.dart';

class ReplyPreviewBar extends StatelessWidget {
  final String replyingToName;
  final String replyContent;
  final String replyType;
  final VoidCallback onCancel;

  const ReplyPreviewBar({
    super.key,
    required this.replyingToName,
    required this.replyContent,
    required this.replyType,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final previewText = replyType == "image" ? "📷 Image" : replyContent;

    return Container(
      padding: const EdgeInsets.only(left: 16, right: 8, top: 8, bottom: 4),
      decoration: BoxDecoration(
        color: AppPallete.inputBg,
        border: Border(
          top: BorderSide(color: AppPallete.divider),
          bottom: BorderSide(color: AppPallete.divider),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: AppPallete.primaryOrange,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  replyingToName,
                  style: const TextStyle(
                    color: AppPallete.primaryOrange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  previewText,
                  style: const TextStyle(
                    color: AppPallete.greyText,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onCancel,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.close,
                size: 18,
                color: AppPallete.greyText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
