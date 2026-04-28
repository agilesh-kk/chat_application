import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:flutter/material.dart';

class UserOptionsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const UserOptionsRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          splashColor: AppPallete.primaryOrange.withValues(alpha: 0.1),
          highlightColor: AppPallete.primaryOrange.withValues(alpha: 0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: AppPallete.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppPallete.divider,
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 26, color: AppPallete.primaryOrange),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppPallete.whiteColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
