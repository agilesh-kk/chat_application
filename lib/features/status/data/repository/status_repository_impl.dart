import 'package:chat_application/core/errors/exceptions.dart';
import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/features/status/data/datasources/status_remote_data_source.dart';
import 'package:chat_application/features/status/data/model/status_model.dart';
import 'package:chat_application/features/status/data/model/status_view_model.dart';
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
    required String userName,
  }) async {
    try {
      final now = DateTime.now().toUtc();
      StatusModel statusModel = StatusModel(
        id: const Uuid().v1(),
        userId: userId,
        imageUrl: '',
        caption: caption,
        createdAt: now,
        expiresAt: now.add(const Duration(hours: 24)),
        userName: userName,
      );

      //Upload Image
      final imageUrl = await statusRemoteDataSource.uploadImage(
        image: image,
        status: statusModel,
      );

      //Update Model with Image URL
      statusModel = statusModel.copyWith(imageUrl: imageUrl);

      //Insert into Supabase
      final uploadedStatus = await statusRemoteDataSource.uploadStatus(
        statusModel,
      );

      return right(uploadedStatus);
    } on ServerExceptions catch (e) {
      return left(Failure(e.message));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  //fetches all status from the db.
  @override
  Future<Either<Failure, List<Status>>> getAllStatus() async {
    try {
      final status = await statusRemoteDataSource.getAllStatus();
      return right(status);
    } on ServerExceptions catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateView({
    required String statusId,
    required String viewerId,
    required String viewerName,
    //required DateTime viewedAt,
  }) async{
    try{
      StatusViewModel statusViewModel = StatusViewModel(
        id: const Uuid().v1(), 
        statusId: statusId, 
        viewerId: viewerId, 
        viewerName: viewerName, 
        viewedAt: DateTime.now().toUtc(),
      );

      await statusRemoteDataSource.updateView(statusViewModel);

      return right(null);
    }on ServerExceptions catch (e) {
      return left(Failure(e.message));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}
