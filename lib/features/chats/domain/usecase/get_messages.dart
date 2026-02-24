import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/features/chats/domain/entities/message.dart';
import 'package:chat_application/features/chats/domain/repository/chat_repository.dart';
import 'package:fpdart/src/either.dart';

class GetMessages implements UseCase<Stream<List<Message>>,GetMessageParams>{
  final ChatRepository chatRepository;
  GetMessages({required this.chatRepository});

  @override
  Future<Either<Failure, Stream<List<Message>>>> call(GetMessageParams params)async {
    return await chatRepository.getMessages(
      convoId: params.convoId,
      userId: params.userId
    );
  }
}

class GetMessageParams{
  final String convoId;
  final String userId;

  GetMessageParams({
    required this.convoId,
    required this.userId,
  });
}