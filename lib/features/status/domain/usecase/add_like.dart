import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/features/status/domain/repository/status_repository.dart';
import 'package:fpdart/fpdart.dart';

class AddLike implements UseCase<void, AddLikeParams>{
  final StatusRepository statusRepository;

  AddLike({required this.statusRepository});
  
  @override
  Future<Either<Failure, void>> call(AddLikeParams params) async {
    return await statusRepository.addLike(
      statusId: params.statusId, 
      userId: params.userId
    );
  }
}

class AddLikeParams {
  final String userId;
  final String statusId;

  AddLikeParams({required this.userId, required this.statusId});
}