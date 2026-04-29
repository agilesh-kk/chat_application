import 'package:chat_application/core/errors/exceptions.dart';
import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/features/chats/domain/entities/message.dart';
import 'package:chat_application/features/timeline/data/datasources/timeline_remote_data_sources.dart';
import 'package:chat_application/features/timeline/domain/entities/event.dart';
import 'package:chat_application/features/timeline/domain/repositories/timeline_repository.dart';
import 'package:chat_application/init_dependencies.dart';
import 'package:fpdart/fpdart.dart';
import 'package:uuid/uuid.dart';

class TimelineRepositoryImpl implements TimelineRepository {
  final TimelineRemoteDataSources timelineRemoteDataSources;

  TimelineRepositoryImpl({required this.timelineRemoteDataSources});

  @override
  Future<Either<Failure, List<Event>>> getEvents({
    required String userId,
    required String receiverId,
  }) async {
    try {
      final res = await timelineRemoteDataSources.getEvents(
        userId: userId,
        receiverId: receiverId,
      );
      return right(res);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<void> addEvent({
    required Message message,
    required String userId,
    required String receiverId,
    required String customTitle,
    required String addedByName,
  }) async {
    try {
      await timelineRemoteDataSources.addEvent(
        message: message,
        userId: userId,
        receiverId: receiverId,
        customTitle: customTitle,
        addedByName: addedByName,
      );
    } catch (e) {
      throw ServerExceptions(e.toString());
    }
  }

  @override
  Future<void> removeEvent({
    required String eventId,
    required String messageId,
    required String userId,
    required String receiverId,
  }) async {
    try {
      await timelineRemoteDataSources.removeEvent(
        eventId: eventId,
        messageId: messageId,
        userId: userId,
        receiverId: receiverId,
      );
    } catch (e) {
      throw ServerExceptions(e.toString());
    }
  }

  @override
  Future<Either<Failure, List<Event>>> getPersonalEvents({required String userId}) async{
    try{
      final res = await timelineRemoteDataSources.getPersonalEvents(
        userId: userId
      );

      return right(res);
    }
    catch(e){
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<void> addPersonalEvent({
    required String userId,
    required String title,
    required String content,
    required String type,
    required DateTime time,
  }) async{
    try{
      var uuid = Uuid();
      String id = uuid.v4();
      
      await timelineRemoteDataSources.addPersonalEvent(
        userId: userId, 
        id: id, 
        title: title, 
        content: content, 
        type: type, 
        time: time
      );
    }
    catch(e){
      throw ServerExceptions(e.toString());
    }
  }
}
