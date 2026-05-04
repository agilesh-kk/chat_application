import 'package:flutter/material.dart';
import '../../domain/entity/achievement.dart';
import '../../services/achievement_image_service.dart';
import 'achievement_tile.dart';

class AchievementGrid extends StatelessWidget {
  final Achievement data;
  final AchievementImageService imageService;

  // 🔥 ADD THIS
  final Function(String achievementId) onCollect;

  const AchievementGrid({
    super.key,
    required this.data,
    required this.imageService,
    required this.onCollect,
  });

  @override
  Widget build(BuildContext context) {
    final allAchievements = [
      "ach_1",
      "ach_2",
      "ach_3",
      "ach_4",
      "ach_5",
      "ach_6",
      "ach_7",
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: allAchievements.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemBuilder: (_, index) {
        final id = allAchievements[index];

        return AchievementTile(
          id: id,
          data: data,
          imageService: imageService,

          // 🔥 PASS CALLBACK DOWN
          onCollect: () => onCollect(id),
        );
      },
    );
  }
}