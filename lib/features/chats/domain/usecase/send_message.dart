import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/features/chats/domain/repository/chat_repository.dart';
import 'package:fpdart/fpdart.dart';

class SendMessage implements UseCase<void,SendMessageParams>{
  final ChatRepository chatRepository;
  SendMessage({required this.chatRepository});

  @override
  Future<Either<Failure,void>> call(SendMessageParams params)async {
    return await chatRepository.sendMessage(
      receiverId : params.receiverId,
      userId: params.userId,
      content: params.content
    );
  }
}

class SendMessageParams{
  final String receiverId;
  final String userId;
  final String content;

  SendMessageParams({
    required this.receiverId,
    required this.userId,
    required this.content
  });
}