import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/features/chats/domain/repository/chat_repository.dart';
import 'package:fpdart/fpdart.dart';

class DeleteMessage implements UseCase<void, DeleteMessageParams>{
  final ChatRepository chatRepository;

  DeleteMessage({required this.chatRepository});
  @override
  Future<Either<Failure, void>> call(DeleteMessageParams params) async{
    try {
      await chatRepository.deleteMessage(
        msgId: params.msgId,
        userId: params.userId,
        receiverId: params.receiverId,
        deleteForEveryone: params.deleteForEveryone,
        type: params.type,
      );
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}

class DeleteMessageParams {
  final String msgId;
  final String userId;
  final String receiverId;
  final String type;
  final bool deleteForEveryone;

  DeleteMessageParams({
    required this.msgId, 
    required this.userId, 
    required this.receiverId,
    required this.type,
    required this.deleteForEveryone,
  });
}