import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/features/timeline/domain/entities/event.dart';
import 'package:chat_application/features/timeline/domain/repositories/timeline_repository.dart';

import 'package:fpdart/src/either.dart';

class LoadEvents implements UseCase<List<Event>,LoadEventsParams>{
  final TimelineRepository timelineRepository;

  LoadEvents({
    required this.timelineRepository
  });

  @override
  Future<Either<Failure, List<Event>>> call(LoadEventsParams params) async {
    return timelineRepository.getEvents(
      userId: params.userId,
      receiverId: params.receiverId
    );
  }
  
}



class LoadEventsParams{
  final String userId;
  final String receiverId;
  LoadEventsParams({required this.userId, required this.receiverId});
}