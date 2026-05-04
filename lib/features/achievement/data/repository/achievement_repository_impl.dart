import 'package:chat_application/features/achievement/data/datasources/achievement_remote_datasource.dart';
import 'package:chat_application/features/achievement/domain/entity/achievement.dart';
import 'package:chat_application/features/achievement/domain/repository/achievement_repository.dart';

class AchievementRepositoryImpl implements AchievementRepository{
  final AchievementRemoteDatasource achievementRemoteDatasource;

  AchievementRepositoryImpl({required this.achievementRemoteDatasource});

  @override
  Stream<Achievement> getAchievements(String userId) {
    return achievementRemoteDatasource.getAchievements(userId);
  }

  @override
  Future<void> collectAchievement(String userId, String achievementId) {
    return achievementRemoteDatasource.collectAchievement(
      userId: userId,
      achievementId: achievementId,
    );
  }

  @override
  Future<void> markAchievementSeen(
      String userId, String achievementId) {
      return achievementRemoteDatasource.markAchievementSeen(
      userId: userId,
      achievementId: achievementId,
    );
  }
}