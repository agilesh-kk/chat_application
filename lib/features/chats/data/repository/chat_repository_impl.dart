import 'package:chat_application/core/common/entities/user.dart';
import 'package:chat_application/core/errors/exceptions.dart';
import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/features/chats/data/datasources/chat_remote_data_sources.dart';
import 'package:chat_application/features/chats/domain/entities/conversation.dart';
import 'package:chat_application/features/chats/domain/entities/message.dart';
import 'package:chat_application/features/chats/domain/repository/chat_repository.dart';
import 'package:fpdart/src/either.dart';

class ChatRepositoryImpl implements ChatRepository{
  final ChatRemoteDataSources chatRemoteDataSources;

  ChatRepositoryImpl({required this.chatRemoteDataSources});

  @override
  Future<Either<Failure, Stream<List<Conversation>>>> getConversations({required String userId}) async{
    try{
      Stream<List<Conversation>> res = await chatRemoteDataSources.getConversations(userId: userId);
      return right(res);
    }on ServerExceptions catch(e){
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, Stream<List<Message>>>> getMessages({required String receiverId, required String userId}) async {
    try{
      Stream<List<Message>> res = await chatRemoteDataSources.getMessages(receiverId: receiverId, userId: userId);
      return right(res);
    }on ServerExceptions catch(e){
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> sendMessage({required String receiverId, required String userId, required String content, String? userName, String? userProfile}) async{
    try{
      await chatRemoteDataSources.sendMessage(receiverId: receiverId, userId: userId, content: content,userName: userName,userProfile: userProfile);
      return right(null);
    }on ServerExceptions catch(e){
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, User?>> searchUser({required String receiverName})async {
    try{
      final res =  await chatRemoteDataSources.searchUser(receiverName: receiverName);
      return right(res);
    } on ServerExceptions catch(e){
      return left(Failure(e.message));
    }
  }

  
}