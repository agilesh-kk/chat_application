import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/features/chats/domain/entities/list_operation.dart';
import 'package:chat_application/features/chats/domain/entities/message.dart';
import 'package:chat_application/features/chats/domain/repository/chat_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetMessages implements UseCase<Stream<ListOperation<Message>>,GetMessageParams>{
  final ChatRepository chatRepository;
  GetMessages({required this.chatRepository});

  @override
  Future<Either<Failure, Stream<ListOperation<Message>>>> call(GetMessageParams params)async {
    return await chatRepository.getMessages(
      receiverId: params.receiverId,
      userId: params.userId
    );
  }
}

class GetMessageParams{
  final String receiverId;
  final String userId;

  GetMessageParams({
    required this.receiverId,
    required this.userId,
  });
}