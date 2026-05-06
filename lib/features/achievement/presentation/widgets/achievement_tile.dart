import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:chat_application/core/theme/app_pallette.dart';
import '../../domain/entity/achievement.dart';
import '../../services/achievement_image_mapper.dart';
import '../../services/achievement_image_service.dart';
import '../../services/achievement_details_mapper.dart';

class AchievementTile extends StatefulWidget {
  final String id;
  final Achievement data;
  final AchievementImageService imageService;
  final VoidCallback? onCollect;

  const AchievementTile({
    super.key,
    required this.id,
    required this.data,
    required this.imageService,
    this.onCollect,
  });

  @override
  State<AchievementTile> createState() => _AchievementTileState();
}

class _AchievementTileState extends State<AchievementTile>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isUnlocked = widget.data.unlocked.contains(widget.id);
    final isCollected = widget.data.collected.contains(widget.id);

    final fileName = AchievementImageMapper.map(widget.id);
    final imageUrl = widget.imageService.getImageUrl(fileName);
    final detail = AchievementDetailsMapper.getById(widget.id);

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: isUnlocked && !isCollected ? widget.onCollect : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnlocked && !isCollected
                  ? AppPallete.primaryOrange.withValues(alpha: 0.6)
                  : AppPallete.divider,
              width: isUnlocked && !isCollected ? 2 : 1,
            ),
            boxShadow: isUnlocked && !isCollected
                ? [
                    BoxShadow(
                      color: AppPallete.primaryOrange.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                    color: isUnlocked ? null : AppPallete.darkSecondary,
                    colorBlendMode: isUnlocked ? null : BlendMode.darken,
                    errorWidget: (_, __, ___) => Container(
                      color: AppPallete.darkTertiary,
                      child: Center(
                        child: Icon(
                          detail.icon,
                          size: 32,
                          color: AppPallete.greyText.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ),
                if (!isUnlocked)
                  Positioned.fill(
                    child: Container(
                      color: AppPallete.darkBg.withValues(alpha: 0.6),
                    ),
                  ),
                if (!isUnlocked)
                  const Center(
                    child: Icon(
                      Icons.lock_outline,
                      size: 36,
                      color: AppPallete.greyText,
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppPallete.darkBg.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          detail.name,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppPallete.whiteColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: detail.rarity.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              detail.rarity.label,
                              style: TextStyle(
                                fontSize: 9,
                                color: detail.rarity.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (isCollected)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppPallete.statusGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppPallete.statusGreen
                                .withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 14,
                        color: AppPallete.whiteColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
