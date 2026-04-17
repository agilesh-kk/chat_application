import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/features/chats/domain/entities/message.dart';
import 'package:chat_application/features/chats/domain/repository/chat_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetScheduledMessages implements UseCase<Stream<List<Message>>,GetScheduledMessageParams>{
  final ChatRepository chatRepository;
  GetScheduledMessages({required this.chatRepository});

  @override
  Future<Either<Failure, Stream<List<Message>>>> call(GetScheduledMessageParams params)async {
    return await chatRepository.getScheduledMessages(
      receiverId: params.receiverId,
      userId: params.userId
    );
  }
}

class GetScheduledMessageParams{
  final String receiverId;
  final String userId;

  GetScheduledMessageParams({
    required this.receiverId,
    required this.userId,
  });
}