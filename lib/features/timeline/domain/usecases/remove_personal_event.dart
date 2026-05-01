import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/features/timeline/domain/repositories/timeline_repository.dart';
import 'package:fpdart/fpdart.dart';

class RemovePersonalEvent implements UseCase<void, RemovePersonalTimelineParams> {
  final TimelineRepository timelineRepository;

  RemovePersonalEvent({required this.timelineRepository});
  @override
  Future<Either<Failure, void>> call(RemovePersonalTimelineParams params) async {
    try {
      await timelineRepository.removePersonalEvent(
        eventId: params.eventId,
        userId: params.userId,
      );
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}

class RemovePersonalTimelineParams {
  final String eventId;
  final String userId;

  RemovePersonalTimelineParams({
    required this.eventId,
    required this.userId,
  });
}
