import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/features/status/domain/entities/status.dart';
import 'package:fpdart/fpdart.dart';
import 'package:image_picker/image_picker.dart';

abstract interface class StatusRepository {
  Future<Either<Failure, Status>> uploadStatus({
    required XFile image,
    required String caption,
    required String userId,
  });
}