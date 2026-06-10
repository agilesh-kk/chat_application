import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/features/chats/domain/entities/message.dart';
import 'package:chat_application/features/chats/domain/repository/chat_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetMessages implements UseCase<Stream<List<Message>>,GetMessageParams>{
  final ChatRepository chatRepository;
  GetMessages({required this.chatRepository});

  @override
  Future<Either<Failure, Stream<List<Message>>>> call(GetMessageParams params)async {
    return await chatRepository.getMessages(
      receiverId: params.receiverId,
      userId: params.userId,
      limit: params.limit,
    );
  }
}

class GetMessageParams{
  final String receiverId;
  final String userId;
  final int? limit;

  GetMessageParams({
    required this.receiverId,
    required this.userId,
    this.limit,
  });
}

class GetOlderMessages implements UseCase<List<Message>, GetOlderMessageParams> {
  final ChatRepository chatRepository;
  GetOlderMessages({required this.chatRepository});

  @override
  Future<Either<Failure, List<Message>>> call(GetOlderMessageParams params) async {
    return await chatRepository.getOlderMessages(
      receiverId: params.receiverId,
      userId: params.userId,
      oldestTimestamp: params.oldestTimestamp,
      limit: params.limit,
    );
  }
}

class GetOlderMessageParams {
  final String receiverId;
  final String userId;
  final DateTime oldestTimestamp;
  final int limit;

  GetOlderMessageParams({
    required this.receiverId,
    required this.userId,
    required this.oldestTimestamp,
    this.limit = 50,
  });
}