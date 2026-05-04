import 'package:chat_application/features/achievement/domain/entity/achievement.dart';

class AchievementModel extends Achievement{
  AchievementModel({
    required super.percentage,
    required super.level,
    required super.unlocked,
    required super.collected,
    required super.seen,
  });

  /// 🔹 FROM FIRESTORE → MODEL
  factory AchievementModel.fromMap(Map<String, dynamic> map) {
    return AchievementModel(
      percentage: (map["percentage"] ?? 0).toDouble(),
      level: map["level"] ?? "Newcomer 🌱",
      unlocked: List<String>.from(map["unlocked"] ?? []),
      collected: List<String>.from(map["collected"] ?? []),
      seen: List<String>.from(map["seen"] ?? []),
    );
  }

  /// 🔹 TO FIRESTORE
  Map<String, dynamic> toMap() {
    return {
      "percentage": percentage,
      "level": level,
      "achievements": {
        "unlocked": unlocked,
        "collected": collected,
        "seen" : seen,
      },
    };
  }

  /// 🔹 OPTIONAL: copyWith (useful for local updates)
  AchievementModel copyWith({
    double? percentage,
    String? level,
    List<String>? unlocked,
    List<String>? collected,
  }) {
    return AchievementModel(
      percentage: percentage ?? this.percentage,
      level: level ?? this.level,
      unlocked: unlocked ?? this.unlocked,
      collected: collected ?? this.collected,
      seen: seen,
    );
  }
}