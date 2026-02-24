import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/features/chats/domain/entities/conversation.dart';
import 'package:chat_application/features/chats/domain/repository/chat_repository.dart';
import 'package:fpdart/fpdart.dart';

//usecase to fetch conversations (will be used by bloc)
class GetConversations implements UseCase<Stream<List<Conversation>>,String>{

    final ChatRepository chatRepository;

    GetConversations({
      required this.chatRepository
    });
    
    @override
    Future<Either<Failure,Stream<List<Conversation>>>> call(String userId) async{
      return await chatRepository.getConversations(userId: userId);
    }

}