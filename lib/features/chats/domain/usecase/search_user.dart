import 'package:chat_application/core/common/entities/user.dart';
import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/features/chats/domain/repository/chat_repository.dart';
import 'package:fpdart/fpdart.dart';

class SearchUser implements UseCase<List<User>,SearchUserParams>{
  final ChatRepository chatRepository;
  SearchUser({required this.chatRepository});

  @override
  Future<Either<Failure,List<User>>> call(
    SearchUserParams params
  )async {
    return await chatRepository.searchUser(
      receiverName: params.receiverName,
      currentUserId: params.currentUserId
    );
  }
}

class SearchUserParams {
  final String receiverName;
  final String currentUserId;

  SearchUserParams({required this.receiverName, required this.currentUserId});
}
