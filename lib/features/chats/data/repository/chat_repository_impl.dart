import 'dart:io';

import 'package:chat_application/core/common/entities/user.dart';
import 'package:chat_application/core/errors/exceptions.dart';
import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/features/chats/data/datasources/chat_local_data_sources.dart';
import 'package:chat_application/features/chats/data/datasources/chat_remote_data_sources.dart';
import 'package:chat_application/features/chats/domain/entities/conversation.dart';
import 'package:chat_application/features/chats/domain/entities/message.dart';
import 'package:chat_application/features/chats/domain/repository/chat_repository.dart';
import 'package:fpdart/fpdart.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSources chatRemoteDataSources;
  final ChatLocalDataSource chatLocalDataSource;

  ChatRepositoryImpl({
    required this.chatRemoteDataSources,
    required this.chatLocalDataSource,
  });

  @override
  Future<Either<Failure, Stream<List<Conversation>>>> getConversations({
    required String userId,
  }) async {
    try {
      Stream<List<Conversation>> res = await chatRemoteDataSources
          .getConversations(userId: userId);
      return right(res);
    } on ServerExceptions catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, Stream<List<Message>>>> getMessages({
    required String receiverId,
    required String userId,
  }) async {
    try {
      Stream<List<Message>> res = await chatRemoteDataSources.getMessages(
        receiverId: receiverId,
        userId: userId,
      );
      return right(res);
    } on ServerExceptions catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> sendImage({
    required String receiverId,
    required String userId,
    required File file,
    required String msgId,
    String? userName,
    String? userProfile,
  }) async {
    try {
      //final localPath = chatLocalDataSource.saveImage(file, msgId);

      final imageUrl = await chatRemoteDataSources.uploadImage(
        file: file,
        msgId: msgId,
      );

      await chatRemoteDataSources.sendMessage(
        type: "image",
        receiverId: receiverId,
        userId: userId,
        msgId: msgId,
        content: imageUrl,
        userName: userName,
        userProfile: userProfile,
      );

      return right(null);
    } catch (e) {
      print(e.toString());
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendMessage({
    required String receiverId,
    required String userId,
    required String content,
    required String msgId,
    String? userName,
    String? userProfile,

    //time capsule
    DateTime? sendAt,
    bool isScheduled = false,
  }) async {
    try {
      await chatRemoteDataSources.sendMessage(
        receiverId: receiverId,
        userId: userId,
        content: content,
        userName: userName,
        userProfile: userProfile,
        msgId: msgId,
        sendAt: sendAt,
        //isScheduled: isScheduled,
      );
      return right(null);
    } on ServerExceptions catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, User?>> searchUser({
    required String receiverName,
  }) async {
    try {
      final res = await chatRemoteDataSources.searchUser(
        receiverName: receiverName,
      );
      return right(res);
    } on ServerExceptions catch (e) {
      return left(Failure(e.message));
    }
  }
  
  @override
  Future<Either<Failure, Stream<List<Message>>>> getScheduledMessages({required String receiverId, required String userId}) async{
    try {
      Stream<List<Message>> res = await chatRemoteDataSources.getScheduledMessages(
        receiverId: receiverId,
        userId: userId,
      );
      return right(res);
    } on ServerExceptions catch (e) {
      return left(Failure(e.message));
    }
  }
  
  @override
  Future<void> deleteMessage({
    required String msgId,
    required String userId,
    required String receiverId,
    bool deleteForEveryone = false,
  }) async {
    try {
      await chatRemoteDataSources.deleteMessage(
        msgId: msgId,
        userId: userId,
        receiverId: receiverId,
        deleteForEveryone: deleteForEveryone,
      );
    } catch (e) {
      throw ServerExceptions(e.toString());
    }
  }
}
