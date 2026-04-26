import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/features/timeline/domain/repositories/timeline_repository.dart';
import 'package:fpdart/fpdart.dart';

class RemoveTimelineEvent implements UseCase<void, RemoveTimelineParams> {
  final TimelineRepository timelineRepository;

  RemoveTimelineEvent({required this.timelineRepository});
  @override
  Future<Either<Failure, void>> call(RemoveTimelineParams params) async {
    try {
      await timelineRepository.removeEvent(
        eventId: params.eventId,
        messageId: params.messageId,
        userId: params.userId,
        receiverId: params.receiverId,
      );
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}

class RemoveTimelineParams {
  final String eventId;
  final String messageId;
  final String userId;
  final String receiverId;

  RemoveTimelineParams({
    required this.eventId,
    required this.messageId,
    required this.userId,
    required this.receiverId,
  });
}
