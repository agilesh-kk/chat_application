import 'package:chat_application/core/common/entities/user.dart';
import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/features/chats/domain/repository/chat_repository.dart';
import 'package:fpdart/fpdart.dart';

class SearchUser implements UseCase<User?,String>{
  final ChatRepository chatRepository;
  SearchUser({required this.chatRepository});

  @override
  Future<Either<Failure,User?>> call(String receiverName)async {
    return await chatRepository.searchUser(receiverName: receiverName);
  }
}
