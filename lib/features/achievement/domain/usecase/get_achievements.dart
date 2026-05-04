import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/features/achievement/domain/entity/achievement.dart';
import 'package:chat_application/features/achievement/domain/repository/achievement_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetAchievements implements UseCase<Stream<Achievement>, GetAchievementsParams> {
  final AchievementRepository achievementRepository;

  GetAchievements({required this.achievementRepository});

  @override
  Future<Either<Failure, Stream<Achievement>>> call(
      GetAchievementsParams params) async {
    try {
      final stream = achievementRepository.getAchievements(params.userId);
      return right(stream);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}

class GetAchievementsParams {
  final String userId;

  GetAchievementsParams({required this.userId});
}