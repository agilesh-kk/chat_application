import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/features/status/domain/repository/status_repository.dart';
import 'package:fpdart/fpdart.dart';

class DeleteStatus implements UseCase<void, DeleteStatusParams>{
  final StatusRepository statusRepository;

  DeleteStatus(this.statusRepository);
  @override
  Future<Either<Failure, void>> call(params) async{
    return await statusRepository.deleteStatus(
      statusId: params.statusId
    );
  }
}

class DeleteStatusParams {
  final String statusId;

  DeleteStatusParams({
    required this.statusId
  });
}