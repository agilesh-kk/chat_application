import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/features/chats/domain/repository/chat_repository.dart';
import 'package:fpdart/fpdart.dart';

class MarkMessagesDelivered implements UseCase<void, MarkMessagesDeliveredParams>{
  final ChatRepository chatRepository;

  MarkMessagesDelivered({required this.chatRepository});

  @override
  Future<Either<Failure, void>> call(params) async{
    try{
      await chatRepository.markMessagesDelivered(
        userId: params.userId, 
        receiverId: params.receiverId
      );
      return right(null);
    }
    catch(e){
      return left(Failure(e.toString()));
    }
  }
}

class MarkMessagesDeliveredParams {
  final String userId;
  final String receiverId;

  MarkMessagesDeliveredParams({required this.userId, required this.receiverId});

}