import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/features/chats/domain/repository/chat_repository.dart';
import 'package:fpdart/fpdart.dart';

class EditMessage implements UseCase<void, EditMessageParams> {
  final ChatRepository chatRepository;

  EditMessage({required this.chatRepository});

  @override
  Future<Either<Failure, void>> call(EditMessageParams params) async {
    try {
      await chatRepository.editMessage(
        userId: params.userId,
        receiverId: params.receiverId,
        msgId: params.msgId,
        newContent: params.newContent,
      );
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}

class EditMessageParams {
  final String userId;
  final String receiverId;
  final String msgId;
  final String newContent;

  EditMessageParams({
    required this.userId,
    required this.receiverId,
    required this.msgId,
    required this.newContent,
  });
}
