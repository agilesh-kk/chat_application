import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/features/status/domain/entities/status.dart';
import 'package:chat_application/features/status/domain/repository/status_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:image_picker/image_picker.dart';

class UploadStatus implements UseCase<Status, UploadStatusParams>{
  final StatusRepository statusRepository;
  UploadStatus(this.statusRepository);

  @override
  Future<Either<Failure, Status>> call(UploadStatusParams params) async {
    return await statusRepository.uploadStatus(
      image: params.image,
      caption: params.caption,
      userId: params.userId,
    );
  }
}

class UploadStatusParams {
  final XFile image;
  final String caption;
  final String userId;

  UploadStatusParams({
    required this.image,
    required this.caption,
    required this.userId,
  });
}
