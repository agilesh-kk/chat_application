import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:flutter/material.dart';

class DeleteMessageConfirmationDialog extends StatelessWidget {
  final String messageContent;
  final VoidCallback onDeleteForMe;
  final VoidCallback? onDeleteForEveryone;
  final bool isMe;

  const DeleteMessageConfirmationDialog({
    super.key,
    required this.messageContent,
    required this.onDeleteForMe,
    this.onDeleteForEveryone,
    this.isMe = true,
  });

  static Future<void> show(
    BuildContext context, {
    required String messageContent,
    required VoidCallback onDeleteForMe,
    VoidCallback? onDeleteForEveryone,
    bool isMe = true,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (_) => DeleteMessageConfirmationDialog(
        messageContent: messageContent,
        onDeleteForMe: onDeleteForMe,
        onDeleteForEveryone: onDeleteForEveryone,
        isMe: isMe,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppPallete.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppPallete.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppPallete.errorColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: AppPallete.errorColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Delete Message',
                  style: TextStyle(
                    color: AppPallete.whiteColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Do you want to delete this message?',
              style: TextStyle(
                color: AppPallete.greyText,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppPallete.darkTertiary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                messageContent,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppPallete.greyText,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildButton(
              label: 'Cancel',
              onTap: () => Navigator.of(context).pop(),
              isPrimary: false,
              fullWidth: true,
            ),
            const SizedBox(height: 12),
            _buildButton(
              label: 'Delete for me',
              onTap: () {
                Navigator.of(context).pop();
                onDeleteForMe();
              },
              isPrimary: false,
              isDestructive: true,
              fullWidth: true,
            ),
            if (isMe)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _buildButton(
                  label: 'Delete for everyone',
                  onTap: () {
                    Navigator.of(context).pop();
                    onDeleteForEveryone?.call();
                  },
                  isPrimary: true,
                  isDestructive: true,
                  fullWidth: true,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
    bool isDestructive = false,
    bool fullWidth = false,
  }) {
    return SizedBox(
      width: fullWidth ? double.maxFinite : null,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isPrimary
                ? (isDestructive
                    ? AppPallete.errorColor
                    : AppPallete.primaryOrange)
                : AppPallete.darkTertiary,
            borderRadius: BorderRadius.circular(12),
            border: isPrimary
                ? null
                : Border.all(color: AppPallete.divider),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isPrimary
                  ? AppPallete.whiteColor
                  : (isDestructive
                      ? AppPallete.errorColor
                      : AppPallete.greyText),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}