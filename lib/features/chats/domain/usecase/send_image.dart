import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/features/chats/domain/repository/chat_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:image_picker/image_picker.dart';

class SendImage implements UseCase<void,SendImageParams>{
  final ChatRepository chatRepository;
  SendImage({required this.chatRepository});

  @override
  Future<Either<Failure,void>> call(SendImageParams params)async {
    return await chatRepository.sendImage(
      receiverId : params.receiverId,
      userId: params.userId,
      image: params.image,
      msgId: params.msgId,
      userName: params.userName,
      userProfile: params.userProfile,
      replyToId: params.replyToId,
      replyToContent: params.replyToContent,
      replyToSenderId: params.replyToSenderId,
      replyToType: params.replyToType,
      isNewConvo: params.isNewConvo,
    );
  }
}

class SendImageParams{
  final String receiverId;
  final String userId;
  final XFile image;
  final String msgId;
  String? userName;
  String? userProfile;
  final String? replyToId;
  final String? replyToContent;
  final String? replyToSenderId;
  final String? replyToType;
  final bool isNewConvo;

  SendImageParams({
    required this.receiverId,
    required this.userId,
    required this.image,
    required this.msgId,
    this.userName,
    this.userProfile,
    this.replyToId,
    this.replyToContent,
    this.replyToSenderId,
    this.replyToType,
    this.isNewConvo = false,
  });
}