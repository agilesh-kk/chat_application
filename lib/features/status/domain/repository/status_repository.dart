import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/features/status/domain/entities/status.dart';
import 'package:chat_application/features/status/domain/entities/status_view.dart';
import 'package:fpdart/fpdart.dart';
import 'package:image_picker/image_picker.dart';

abstract interface class StatusRepository {

  Future<Either<Failure, Status>> uploadStatus({
    required XFile image,
    required String caption,
    required String userId,
    required String userName,
    required String profilepic
  });

  Future<Either<Failure, List<Status>>> getAllStatus();

  Future<Either<Failure, void>> updateView({
    required String statusId,
    required String viewerId,
    required String viewerName,
    //required DateTime viewedAt,
  });

  Future<Either<Failure, List<StatusView>>> getViews({
    required String statusId,
  });

  Future<Either<Failure, void>> deleteStatus({
    required String statusId,
  });

  Future<Either<Failure, void>> addLike({
    required String statusId,
    required String userId,
  });
}