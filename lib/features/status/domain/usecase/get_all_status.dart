import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/features/status/domain/entities/status.dart';
import 'package:chat_application/features/status/domain/repository/status_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetAllStatus implements UseCase<List<Status>, NoParams>{
  final StatusRepository statusRepository;
  GetAllStatus(this.statusRepository);

  @override
  Future<Either<Failure, List<Status>>> call(NoParams params) async{
    return await statusRepository.getAllStatus();
  }
}