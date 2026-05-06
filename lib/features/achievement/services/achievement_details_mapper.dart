import 'package:flutter/material.dart';
import 'package:chat_application/core/theme/app_pallette.dart';

class AchievementRarity {
  final String label;
  final Color color;

  const AchievementRarity({required this.label, required this.color});

  static const common = AchievementRarity(
    label: 'Common',
    color: AppPallete.greyText,
  );
  static const rare = AchievementRarity(
    label: 'Rare',
    color: Color(0xFF4FC3F7),
  );
  static const epic = AchievementRarity(
    label: 'Epic',
    color: Color(0xFFBA68C8),
  );
  static const legendary = AchievementRarity(
    label: 'Legendary',
    color: AppPallete.primaryOrange,
  );
}

class AchievementDetail {
  final String id;
  final String name;
  final String description;
  final AchievementRarity rarity;
  final IconData icon;

  const AchievementDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
    required this.icon,
  });
}

class AchievementDetailsMapper {
  static const Map<String, int> thresholds = {
    "ach_1": 0,
    "ach_2": 10,
    "ach_3": 25,
    "ach_4": 40,
    "ach_5": 60,
    "ach_6": 75,
    "ach_7": 90,
  };

  static const List<AchievementDetail> all = [
    AchievementDetail(
      id: 'ach_1',
      name: 'First Steps',
      description: 'Send your first message',
      rarity: AchievementRarity.common,
      icon: Icons.chat_bubble_outline,
    ),
    AchievementDetail(
      id: 'ach_2',
      name: 'Social Butterfly',
      description: 'Add 5 friends to your network',
      rarity: AchievementRarity.rare,
      icon: Icons.groups_outlined,
    ),
    AchievementDetail(
      id: 'ach_3',
      name: 'Night Owl',
      description: 'Send a message after midnight',
      rarity: AchievementRarity.epic,
      icon: Icons.nights_stay_outlined,
    ),
    AchievementDetail(
      id: 'ach_4',
      name: 'Streak Master',
      description: 'Maintain a 7-day chat streak',
      rarity: AchievementRarity.rare,
      icon: Icons.local_fire_department_outlined,
    ),
    AchievementDetail(
      id: 'ach_5',
      name: 'Status Star',
      description: 'Post 10 status updates',
      rarity: AchievementRarity.common,
      icon: Icons.auto_stories_outlined,
    ),
    AchievementDetail(
      id: 'ach_6',
      name: 'Timeline Keeper',
      description: 'Save 20 timeline moments',
      rarity: AchievementRarity.epic,
      icon: Icons.favorite_border,
    ),
    AchievementDetail(
      id: 'ach_7',
      name: 'Legend',
      description: 'Unlock all other achievements',
      rarity: AchievementRarity.legendary,
      icon: Icons.emoji_events_outlined,
    ),
  ];

  static AchievementDetail getById(String id) {
    return all.firstWhere(
      (a) => a.id == id,
      orElse: () => all.first,
    );
  }
}
