import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/features/watch2gether/domain/entity/w2g_chat_message.dart';
import 'package:chat_application/features/watch2gether/domain/repository/w2g_repository.dart';
import 'package:fpdart/fpdart.dart';

class SendChatMessage implements UseCase<void, SendChatMessageParams> {
  final W2GRepository repository;

  SendChatMessage(this.repository);

  @override
  Future<Either<Failure, void>> call(SendChatMessageParams params) async {
    try {
      await repository.sendMessage(params.roomId, params.message);
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}

class SendChatMessageParams {
  final String roomId;
  final W2GChatMessage message;

  SendChatMessageParams({required this.roomId, required this.message});
}
