import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/features/timeline/features/timeline/domain/entities/event.dart';
import 'package:chat_application/features/timeline/features/timeline/domain/repositories/timeline_repository.dart';
import 'package:fpdart/src/either.dart';

class RefreshEvents implements UseCase<List<Event>,RefreshEventsParams>{
  final TimelineRepository timelineRepository;

  RefreshEvents({
    required this.timelineRepository
  });

  @override
  Future<Either<Failure, List<Event>>> call(RefreshEventsParams params) async {
    return timelineRepository.refreshAndfetchEvents(
      userId: params.userId,
      receiverId: params.receiverId
    );
  }
  
}



class RefreshEventsParams{
  final String userId;
  final String receiverId;
  RefreshEventsParams({required this.userId, required this.receiverId});
}