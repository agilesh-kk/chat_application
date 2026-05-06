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

  LevelInfo? get _nextBadge {
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

  LevelInfo get _levelInfo => AchievementDetailsMapper.getByPercentage(data.percentage);

  @override
  Widget build(BuildContext context) {
    final nextBadge = _nextBadge;
    final unlockedCount = data.unlocked.length;
    const totalCount = 7;
    final levelInfo = _levelInfo;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current Level Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  levelInfo.rarity.color.withValues(alpha: 0.15),
                  AppPallete.cardBg,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: levelInfo.rarity.color.withValues(alpha: 0.3),
              ),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: levelInfo.rarity.color.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: levelInfo.rarity.color),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.emoji_events_outlined,
                            size: 14,
                            color: levelInfo.rarity.color,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'CURRENT LEVEL',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: levelInfo.rarity.color,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
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
                const SizedBox(height: 12),
                Text(
                  levelInfo.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppPallete.whiteColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  levelInfo.description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppPallete.greyText,
                  ),
                ),
              ],
            ),
          ),

          // Next Badge Section (only if not all unlocked)
          if (nextBadge != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    nextBadge.rarity.color.withValues(alpha: 0.1),
                    AppPallete.cardBg,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: nextBadge.rarity.color.withValues(alpha: 0.3),
                ),
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
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color:
                              nextBadge.rarity.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: nextBadge.rarity.color),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              nextBadge.icon,
                              size: 14,
                              color: nextBadge.rarity.color,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'NEXT BADGE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: nextBadge.rarity.color,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    nextBadge.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppPallete.whiteColor,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
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
                      value: _nextBadgeProgress / 100,
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
                      '${_nextBadgeProgress.toStringAsFixed(1)}% to unlock',
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
          ] else ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppPallete.primaryOrange.withValues(alpha: 0.1),
                    AppPallete.cardBg,
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppPallete.primaryOrange.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                children: [
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
          ],
        ],
      ),
    );
  }
}
