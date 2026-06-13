import 'package:chat_application/core/errors/exceptions.dart';
import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/features/status/data/datasources/status_remote_data_source.dart';
import 'package:chat_application/features/status/data/model/status_model.dart';
import 'package:chat_application/features/status/data/model/status_view_model.dart';
import 'package:chat_application/features/status/domain/entities/status.dart';
import 'package:chat_application/features/status/domain/entities/status_view.dart';
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
    required String profilepic
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
        profilepic: profilepic,
        likedBy: [],
        viewedBy: [],
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
  Future<Either<Failure, List<Status>>> getAllStatus({required String currentUserId}) async {
    try {
      final models = await statusRemoteDataSource.getAllStatus();
      final statuses = models.map((m) => Status(
        id: m.id,
        userId: m.userId,
        imageUrl: m.imageUrl,
        caption: m.caption,
        createdAt: m.createdAt,
        expiresAt: m.expiresAt,
        userName: m.userName,
        profilepic: m.profilepic,
        likedBy: m.likedBy,
        isViewed: m.viewedBy.contains(currentUserId),
      )).toList();

      return right(statuses);

    } on ServerExceptions catch (e) {
      return left(Failure(e.message));
    } catch (e) {
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
  
  @override
  Future<Either<Failure, List<StatusView>>> getViews({required String statusId}) async{
    try {
      final views = await statusRemoteDataSource.getViews(statusId);
      return right(views);
    } on ServerExceptions catch (e) {
      return left(Failure(e.toString()));
    }
  }
  
  @override
  Future<Either<Failure, void>> deleteStatus({required String statusId}) async {
    try{
      await statusRemoteDataSource.deleteStatus(statusId);
      return right(null);
    }
    on ServerExceptions catch(e){
      return left(Failure(e.message));
    }
    catch(e){
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addLike({
    required String statusId,
    required String userId,
  }) async {
    try {
      await statusRemoteDataSource.addLike(
        statusId: statusId,
        userId: userId,
      );

      return right(null);
    } on ServerExceptions catch (e) {
      return left(Failure(e.message));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}
