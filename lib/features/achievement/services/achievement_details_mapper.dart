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
  static const uncommon = AchievementRarity(
    label: 'Uncommon',
    color: Color(0xFF4CAF50),
  );
  static const rare = AchievementRarity(
    label: 'Rare',
    color: Color(0xFF4FC3F7),
  );
  static const mythic = AchievementRarity(
    label: 'Mythic',
    color: Color(0xFFFF9800),
  );
  static const epic = AchievementRarity(
    label: 'Epic',
    color: Color(0xFFBA68C8),
  );
  static const legendary = AchievementRarity(
    label: 'Legendary',
    color: AppPallete.primaryOrange,
  );
  static const exotic = AchievementRarity(
    label: 'Exotic',
    color: Color(0xFFFFD700),
  );
  static const transcendent = AchievementRarity(
    label: 'Transcendent',
    color: Color(0xFFFFEB3B),
  );
}

class LevelInfo {
  final String id;
  final String name;
  final String description;
  final AchievementRarity rarity;
  final IconData icon;
  final int minPercentage;

  const LevelInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
    required this.icon,
    required this.minPercentage,
  });
}

class AchievementDetailsMapper {
  static const List<LevelInfo> all = [
    LevelInfo(
      id: 'ach_1',
      name: 'Newcomer 🌱',
      description: 'You\'re just starting your chat journey. Send your first message to begin!',
      rarity: AchievementRarity.common,
      icon: Icons.chat_bubble_outline,
      minPercentage: 0,
    ),
    LevelInfo(
      id: 'ach_2',
      name: 'Starter 💬',
      description: 'You\'re getting comfortable with chatting. Keep the conversations going!',
      rarity: AchievementRarity.uncommon,
      icon: Icons.groups_outlined,
      minPercentage: 10,
    ),
    LevelInfo(
      id: 'ach_3',
      name: 'Socializing 🤝',
      description: 'You\'re becoming social. Add more friends and chat regularly!',
      rarity: AchievementRarity.rare,
      icon: Icons.nights_stay_outlined,
      minPercentage: 25,
    ),
    LevelInfo(
      id: 'ach_4',
      name: 'Active User 🔥',
      description: 'You\'re an active chatter now. Your engagement is impressive!',
      rarity: AchievementRarity.mythic,
      icon: Icons.local_fire_department_outlined,
      minPercentage: 40,
    ),
    LevelInfo(
      id: 'ach_5',
      name: 'Connector 🔗',
      description: 'You\'re connecting people together. You\'re building a network!',
      rarity: AchievementRarity.epic,
      icon: Icons.favorite_border,
      minPercentage: 60,
    ),
    LevelInfo(
      id: 'ach_6',
      name: 'Influencer 🌟',
      description: 'You\'re an influencer now. People love chatting with you!',
      rarity: AchievementRarity.legendary,
      icon: Icons.auto_stories_outlined,
      minPercentage: 75,
    ),
    LevelInfo(
      id: 'ach_7',
      name: 'Legend 🏆',
      description: 'You\'re a legend! You\'ve mastered the art of conversation!',
      rarity: AchievementRarity.transcendent,
      icon: Icons.emoji_events_outlined,
      minPercentage: 90,
    ),
  ];

  static const Map<String, int> thresholds = {
    "ach_1": 0,
    "ach_2": 10,
    "ach_3": 25,
    "ach_4": 40,
    "ach_5": 60,
    "ach_6": 75,
    "ach_7": 90,
  };

  static LevelInfo getByPercentage(double percentage) {
    LevelInfo current = all.first;
    for (final level in all) {
      if (percentage >= level.minPercentage) {
        current = level;
      }
    }
    return current;
  }

  static LevelInfo getById(String id) {
    return all.firstWhere(
      (a) => a.id == id,
      orElse: () => all.first,
    );
  }
}
