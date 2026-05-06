import 'package:flutter/material.dart';
import 'package:chat_application/core/theme/app_pallette.dart';
import '../../domain/entity/achievement.dart';
import '../../services/achievement_details_mapper.dart';

class AchievementProgress extends StatelessWidget {
  final Achievement data;

  const AchievementProgress({
    super.key,
    required this.data,
  });

  AchievementDetail? get _nextBadge {
    for (final detail in AchievementDetailsMapper.all) {
      if (!data.unlocked.contains(detail.id)) return detail;
    }
    return null;
  }

  double get _nextBadgeProgress {
    final next = _nextBadge;
    if (next == null) return 100;

    final currentThreshold = _currentThreshold;
    final nextThreshold = AchievementDetailsMapper.thresholds[next.id] ?? 100;

    if (nextThreshold == currentThreshold) return 100;

    final progress = ((data.percentage - currentThreshold) /
            (nextThreshold - currentThreshold)) *
        100;
    return progress.clamp(0, 100);
  }

  double get _currentThreshold {
    double maxThreshold = 0;
    for (final entry in AchievementDetailsMapper.thresholds.entries) {
      if (data.unlocked.contains(entry.key) && entry.value > maxThreshold) {
        maxThreshold = entry.value.toDouble();
      }
    }
    return maxThreshold;
  }

  @override
  Widget build(BuildContext context) {
    final nextBadge = _nextBadge;
    final unlockedCount = data.unlocked.length;
    const totalCount = 7;

    if (nextBadge == null) {
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
                    child: const Text(
                      '7/7',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppPallete.whiteColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Icon(
                Icons.emoji_events_outlined,
                size: 48,
                color: AppPallete.primaryOrange,
              ),
              const SizedBox(height: 12),
              const Text(
                'All badges unlocked! 🎉',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppPallete.whiteColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final nextProgress = _nextBadgeProgress;

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
                Row(
                  children: [
                    Icon(
                      nextBadge.icon,
                      size: 20,
                      color: nextBadge.rarity.color,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Next: ${nextBadge.name}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppPallete.whiteColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
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
            const SizedBox(height: 8),
            Text(
              nextBadge.description,
              style: const TextStyle(
                fontSize: 13,
                color: AppPallete.greyText,
              ),
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LinearProgressIndicator(
                value: nextProgress / 100,
                minHeight: 12,
                valueColor: AlwaysStoppedAnimation<Color>(
                  nextBadge.rarity.color,
                ),
                backgroundColor: AppPallete.darkSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${nextProgress.toStringAsFixed(1)}% to next badge',
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
