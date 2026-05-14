import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/features/chats/domain/repository/chat_repository.dart';
import 'package:fpdart/fpdart.dart';

class ToggleReaction implements UseCase<void, ToggleReactionParams> {
  final ChatRepository chatRepository;

  ToggleReaction({required this.chatRepository});

  @override
  Future<Either<Failure, void>> call(ToggleReactionParams params) async {
    try {
      await chatRepository.toggleReaction(
        userId: params.userId,
        receiverId: params.receiverId,
        messageId: params.messageId,
        emoji: params.emoji,
      );
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}

class ToggleReactionParams {
  final String userId;
  final String receiverId;
  final String messageId;
  final String emoji;

  ToggleReactionParams({
    required this.userId,
    required this.receiverId,
    required this.messageId,
    required this.emoji,
  });
}
