import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/features/status/domain/repository/status_repository.dart';
import 'package:fpdart/fpdart.dart';

class UpdateView implements UseCase<void, UpdateViewParams> {
  final StatusRepository statusRepository;
  UpdateView(this.statusRepository);

  @override
  Future<Either<Failure, dynamic>> call(UpdateViewParams params) async {
    return await statusRepository.updateView(
      statusId: params.statusId, 
      viewerId: params.viewerId, 
      viewerName: params.viewerName, 
      //viewedAt: params.viewedAt,
    );
  }
}

class UpdateViewParams {
  //final String id;
  final String statusId;
  final String viewerId;
  final String viewerName;
  //final DateTime viewedAt;

  UpdateViewParams({
    //required this.id,
    required this.statusId,
    required this.viewerId,
    required this.viewerName,
    //required this.viewedAt,
  });
}
