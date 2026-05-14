
import 'package:chat_application/core/common/entities/user.dart';
import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/features/chats/domain/entities/conversation.dart';
import 'package:chat_application/features/chats/domain/entities/message.dart';
import 'package:fpdart/fpdart.dart';
import 'package:image_picker/image_picker.dart';

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
    required String msgId,
    String? userName,
    String? userProfile,

    //for time capsule
    DateTime? sendAt,
    bool isScheduled = false,

    //for reply
    String? replyToId,
    String? replyToContent,
    String? replyToSenderId,
    String? replyToType,
  });

  Future<Either<Failure, void>> sendImage({
    required String receiverId,
    required String userId,
    required XFile image,
    required String msgId,
    String? userName,
    String? userProfile,
    String? replyToId,
    String? replyToContent,
    String? replyToSenderId,
    String? replyToType,
  });

  //Contract to fetch Messages of a Single Conversation
  Future<Either<Failure,Stream<List<Message>>>> getMessages({
    required String receiverId,
    required String userId,
  });

  //marking the messages has viewed
  Future<void> markMessagesDelivered({
    required String userId,
    required String receiverId,
  });

  //Contract to fetch receiverName
  Future<Either<Failure,List<User>>> searchUser({
    required String receiverName,
    required String currentUserId,
  });

  Future<Either<Failure,Stream<List<Message>>>> getScheduledMessages({
    required String receiverId,
    required String userId,
  });

  Future<void> deleteMessage({
    required String msgId,
    required String userId,
    required String receiverId,
    required String type,
    bool deleteForEveryone = false,
  });

  Future<void> toggleReaction({
    required String userId,
    required String receiverId,
    required String messageId,
    required String emoji,
  });
  
}