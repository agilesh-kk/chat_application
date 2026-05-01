import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/features/timeline/domain/entities/event.dart';
import 'package:chat_application/features/timeline/domain/repositories/timeline_repository.dart';
import 'package:fpdart/fpdart.dart';


class LoadPersonalEvents implements UseCase<List<Event>,LoadPersonalEventsParams>{
  final TimelineRepository timelineRepository;

  LoadPersonalEvents({
    required this.timelineRepository
  });

  @override
  Future<Either<Failure, List<Event>>> call(LoadPersonalEventsParams params) async {
    return timelineRepository.getPersonalEvents(
      userId: params.userId,
    );
  }
}


class LoadPersonalEventsParams{
  final String userId;

  LoadPersonalEventsParams({required this.userId});
}