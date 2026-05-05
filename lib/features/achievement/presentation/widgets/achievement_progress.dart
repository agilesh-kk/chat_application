import 'package:flutter/material.dart';
import 'package:chat_application/core/theme/app_pallette.dart';
import '../../domain/entity/achievement.dart';

class AchievementProgress extends StatelessWidget {
  final Achievement data;

  const AchievementProgress({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = data.percentage.clamp(0, 100);
    final unlockedCount = data.unlocked.length;
    const totalCount = 7;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
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
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  data.level,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppPallete.whiteColor,
                    letterSpacing: -0.5,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppPallete.primaryOrange,
                        AppPallete.lightOrange,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$unlockedCount/$totalCount',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppPallete.whiteColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: percentage / 100,
                minHeight: 12,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppPallete.primaryOrange,
                ),
                backgroundColor: AppPallete.darkSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${percentage.toStringAsFixed(1)}% Complete',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppPallete.greyText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
