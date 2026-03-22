import 'dart:io';

import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/features/chats/domain/repository/chat_repository.dart';
import 'package:fpdart/fpdart.dart';

class SendImage implements UseCase<void,SendImageParams>{
  final ChatRepository chatRepository;
  SendImage({required this.chatRepository});

  @override
  Future<Either<Failure,void>> call(SendImageParams params)async {
    return await chatRepository.sendImage(
      receiverId : params.receiverId,
      userId: params.userId,
      file: params.file,
      msgId: params.msgId,
      userName: params.userName,
      userProfile: params.userProfile
    );
  }
}

class SendImageParams{
  final String receiverId;
  final String userId;
  final File file;
  final String msgId;
  String? userName;
  String? userProfile;

  SendImageParams({
    required this.receiverId,
    required this.userId,
    required this.file,
    required this.msgId,
    this.userName,
    this.userProfile
  });
}