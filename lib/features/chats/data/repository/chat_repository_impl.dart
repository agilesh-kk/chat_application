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
  Future<Either<Failure, Stream<List<Message>>>> getMessages({required String convoId, required String userId}) async {
    try{
      Stream<List<Message>> res = await chatRemoteDataSources.getMessages(convoId: convoId, userId: userId);
      return right(res);
    }on ServerExceptions catch(e){
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> sendMessage({required String receiverId, required String userId, required String content}) async{
    try{
      await chatRemoteDataSources.sendMessage(receiverId: receiverId, userId: userId, content: content);
      return right(null);
    }on ServerExceptions catch(e){
      return left(Failure(e.message));
    }
  }
}