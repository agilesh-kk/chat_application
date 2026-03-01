import 'package:chat_application/core/errors/exceptions.dart';
import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/features/status/data/datasources/status_remote_data_source.dart';
import 'package:chat_application/features/status/data/model/status_model.dart';
import 'package:chat_application/features/status/domain/entities/status.dart';
import 'package:chat_application/features/status/domain/repository/status_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:image_picker/image_picker.dart';

import 'package:uuid/uuid.dart';

class StatusRepositoryImpl implements StatusRepository {
  final StatusRemoteDataSource statusRemoteDataSource;

  StatusRepositoryImpl({required this.statusRemoteDataSource});
  @override
  Future<Either<Failure, Status>> uploadStatus({
    required XFile image,
    required String caption,
    required String userId,
  }) async {
    try {
      StatusModel statusModel = StatusModel(
        id: const Uuid().v1(),
        userId: userId,
        imageUrl: '',
        caption: caption,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      );

      //Upload Image
      final imageUrl = await statusRemoteDataSource.uploadImage(
        image: image,
        status: statusModel,
      );

      //Update Model with Image URL
      statusModel = statusModel.copyWith(imageUrl: imageUrl);

      //Insert into Supabase
      final uploadedStatus =
          await statusRemoteDataSource.uploadStatus(statusModel);

      return right(uploadedStatus);

    } on ServerExceptions catch (e) {
      return left(Failure(e.message));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}
