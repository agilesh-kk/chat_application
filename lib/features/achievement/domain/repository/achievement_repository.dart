import 'package:chat_application/features/achievement/domain/entity/achievement.dart';

abstract interface class AchievementRepository {
  Stream<Achievement> getAchievements(String userId);
  Future<void> collectAchievement(String userId, String achievementId);
   Future<void> markAchievementSeen(String userId, String achievementId);
}