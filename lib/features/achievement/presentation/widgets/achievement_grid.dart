import 'package:flutter/material.dart';
import 'package:chat_application/core/theme/app_pallette.dart';
import '../../domain/entity/achievement.dart';
import '../../services/achievement_image_service.dart';
import '../../services/achievement_details_mapper.dart';
import 'achievement_tile.dart';

class AchievementGrid extends StatelessWidget {
  final Achievement data;
  final AchievementImageService imageService;
  final Function(String achievementId) onCollect;

  const AchievementGrid({
    super.key,
    required this.data,
    required this.imageService,
    required this.onCollect,
  });

  @override
  Widget build(BuildContext context) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: AppPallete.primaryOrange,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: AppPallete.primaryOrange.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'All Achievements',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppPallete.whiteColor,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: AchievementDetailsMapper.all.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 14,
            crossAxisSpacing: 14,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (_, index) {
            final detail = AchievementDetailsMapper.all[index];

            return AchievementTile(
              id: detail.id,
              data: data,
              imageService: imageService,
              onCollect: () => onCollect(detail.id),
            );
          },
        ),
      ],
    );
  }
}
