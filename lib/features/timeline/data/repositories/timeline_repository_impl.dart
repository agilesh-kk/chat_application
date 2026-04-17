import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/features/timeline/data/datasources/timeline_remote_data_sources.dart';
import 'package:chat_application/features/timeline/domain/entities/event.dart';
import 'package:chat_application/features/timeline/domain/repositories/timeline_repository.dart';

import 'package:fpdart/src/either.dart';

class TimelineRepositoryImpl implements TimelineRepository{
  final TimelineRemoteDataSources timelineRemoteDataSources;

  TimelineRepositoryImpl({required this.timelineRemoteDataSources});
  
  @override
  Future<Either<Failure, List<Event>>> getEvents({required String userId, required String receiverId}) async{
    try{
      final res = await timelineRemoteDataSources.getEvents(userId: userId, receiverId: receiverId);
      return right(res);
    }catch(e){
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Event>>> refreshAndfetchEvents({required String userId, required String receiverId}) async {
    try{
      final res = await timelineRemoteDataSources.refreshAndfetchEvents(userId: userId, receiverId: receiverId);
      return right(res);
    }catch(e){
      return left(Failure(e.toString()));
    }
  }
}