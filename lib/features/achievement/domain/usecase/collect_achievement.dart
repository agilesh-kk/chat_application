import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/features/achievement/domain/repository/achievement_repository.dart';
import 'package:fpdart/fpdart.dart';

class CollectAchievement implements UseCase<void, CollectAchievementParams>{
  final AchievementRepository achievementRepository;

  CollectAchievement({required this.achievementRepository});

  @override
  Future<Either<Failure, void>> call(CollectAchievementParams params) async {
    try {
      await achievementRepository.collectAchievement(
        params.userId,
        params.achievementId,
      );

      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}

class CollectAchievementParams {
  final String userId;
  final String achievementId;

  CollectAchievementParams({
    required this.userId,
    required this.achievementId,
  });
}