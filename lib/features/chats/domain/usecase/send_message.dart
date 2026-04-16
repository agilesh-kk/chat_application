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
      content: params.content,
      msgId: params.msgId,
      userName: params.userName,
      userProfile: params.userProfile,
      sendAt: params.sendAt,
      isScheduled: params.isScheduled,
    );
  }
}

class SendMessageParams{
  final String receiverId;
  final String userId;
  final String content;
  final String msgId;
  String? userName;
  String? userProfile;

  //for time capsule
  final DateTime? sendAt;
  final bool isScheduled;

  SendMessageParams({
    required this.receiverId,
    required this.userId,
    required this.content,
    required this.msgId,
    this.userName,
    this.userProfile,
    this.sendAt,
    this.isScheduled = false,
  });
}