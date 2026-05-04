import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/features/achievement/domain/repository/achievement_repository.dart';
import 'package:fpdart/fpdart.dart';

class MarkAchievementSeen implements UseCase<void, MarkAchievementSeenParams> {
  final AchievementRepository achievementRepository;

  MarkAchievementSeen(this.achievementRepository);

  @override
  Future<Either<Failure, void>> call(MarkAchievementSeenParams params) async {
    try {
      await achievementRepository.markAchievementSeen(
        params.userId,
        params.achievementId,
      );
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}

class MarkAchievementSeenParams {
  final String userId;
  final String achievementId;

  MarkAchievementSeenParams({
    required this.userId,
    required this.achievementId,
  });
}