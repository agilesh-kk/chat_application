import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/features/status/domain/entities/status_view.dart';
import 'package:chat_application/features/status/domain/repository/status_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetViews implements UseCase<List<StatusView>, GetViewParms>{
  final StatusRepository statusRepository;
  GetViews(this.statusRepository);

  @override
  Future<Either<Failure, List<StatusView>>> call(GetViewParms params) async{
    return await statusRepository.getViews(
      statusId: params.statusId
    );
  }
}

class GetViewParms {
  final String statusId;

  GetViewParms({
    required this.statusId,
  });
}