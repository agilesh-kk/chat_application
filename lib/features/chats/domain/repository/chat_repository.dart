
import 'package:chat_application/core/common/entities/user.dart';
import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/features/chats/domain/entities/conversation.dart';
import 'package:chat_application/features/chats/domain/entities/message.dart';
import 'package:fpdart/fpdart.dart';

// Contract for Repository (Independent)
abstract interface class ChatRepository{

  //contract to fetch Convos
  Future<Either<Failure,Stream<List<Conversation>>>> getConversations({
    required String userId
  });

  //contract to send Message
  Future<Either<Failure,void>> sendMessage({
    required String receiverId,
    required String userId,
    required String content,
    String? userName,
    String? userProfile
  });

  //Contract to fetch Messages of a Single Conversation
  Future<Either<Failure,Stream<List<Message>>>> getMessages({
    required String receiverId,
    required String userId,
  });

  //Contract to fetch receiverName
  Future<Either<Failure,User?>> searchUser({
    required String receiverName
  });

}