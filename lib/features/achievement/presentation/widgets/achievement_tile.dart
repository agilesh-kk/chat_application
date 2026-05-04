import 'package:flutter/material.dart';
import '../../domain/entity/achievement.dart';
import '../../services/achievement_image_mapper.dart';
import '../../services/achievement_image_service.dart';

class AchievementTile extends StatelessWidget {
  final String id;
  final Achievement data;
  final AchievementImageService imageService;

  // 🔥 Callback from Page
  final VoidCallback? onCollect;

  const AchievementTile({
    super.key,
    required this.id,
    required this.data,
    required this.imageService,
    this.onCollect,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlocked = data.unlocked.contains(id);
    final isCollected = data.collected.contains(id);

    final fileName = AchievementImageMapper.map(id);
    final imageUrl = imageService.getImageUrl(fileName);

    return GestureDetector(
      onTap: isUnlocked && !isCollected ? onCollect : null,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            // 🖼 IMAGE
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Opacity(
                  opacity: isUnlocked ? 1 : 0.3,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            // 🔒 LOCK
            if (!isUnlocked)
              const Center(
                child: Icon(Icons.lock, size: 40, color: Colors.white),
              ),

            // ✨ UNLOCKED (not collected)
            if (isUnlocked && !isCollected)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.amber, width: 3),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),

            // ✅ COLLECTED
            if (isCollected)
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(Icons.check_circle, color: Colors.green),
              ),
          ],
        ),
      ),
    );
  }
}