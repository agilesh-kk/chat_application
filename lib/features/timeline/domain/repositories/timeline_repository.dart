import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/features/chats/domain/entities/message.dart';
import 'package:chat_application/features/timeline/domain/entities/event.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class TimelineRepository {
  Future<Either<Failure,List<Event>>> getEvents({
    required String userId,
    required String receiverId,
  });

  Future<void> addEvent({
    required Message message,
    required String userId,
    required String receiverId,
    required String customTitle,
    required String addedByName,
  });

  Future<void> removeEvent({
    required String eventId, 
    required String messageId, 
    required String userId, 
    required String receiverId,
  });

  Future<Either<Failure, List<Event>>> getPersonalEvents({
    required String userId
  });

  Future<void> addPersonalEvent({
    required String userId,
    required String title,
    required String content,
    required String type,
    required DateTime time,
  });
}