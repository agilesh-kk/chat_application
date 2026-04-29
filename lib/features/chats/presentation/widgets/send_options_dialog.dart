import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:flutter/material.dart';

class SendOptionsDialog extends StatelessWidget {
  final VoidCallback onSendNormally;
  final VoidCallback onTimeCapsule;
  const SendOptionsDialog({
    super.key,
    required this.onSendNormally,
    required this.onTimeCapsule,
  });

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
            Text(
              "Send options",
              style: TextStyle(
                color: AppPallete.whiteColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildOption(
              icon: Icons.send,
              label: "Send normally",
              subtitle: "Message will be sent immediately",
              onTap: () {
                Navigator.pop(context);
                onSendNormally();
              },
            ),
            const SizedBox(height: 12),
            _buildOption(
              icon: Icons.lock_clock,
              label: "Create Timecapsule",
              subtitle: "Schedule message for later",
              onTap: () {
                Navigator.pop(context);
                onTimeCapsule();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppPallete.darkTertiary,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppPallete.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppPallete.primaryOrange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppPallete.primaryOrange,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: AppPallete.whiteColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppPallete.greyText,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppPallete.greyText,
            ),
          ],
        ),
      ),
    );
  }
}