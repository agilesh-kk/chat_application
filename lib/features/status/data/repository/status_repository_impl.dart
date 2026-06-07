import 'package:chat_application/core/errors/exceptions.dart';
import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/network/connection_checker.dart';
import 'package:chat_application/features/status/data/datasources/status_local_data_source.dart';
import 'package:chat_application/features/status/data/datasources/status_remote_data_source.dart';
import 'package:chat_application/features/status/data/model/status_hive_model.dart';
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
  final StatusLocalDataSource statusLocalDataSource;
  final ConnectionChecker connectionChecker;

  StatusRepositoryImpl({required this.statusRemoteDataSource, required this.statusLocalDataSource, required this.connectionChecker});
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
  Future<Either<Failure, List<Status>>> getAllStatus({required String currentUserId, bool forceRefresh = false}) async {
    try {
      // 1. Always read from Hive first
      final cachedStatuses = await statusLocalDataSource.getAllStatuses();

      // 2. If cache has data and not forcing refresh, return immediately
      if (cachedStatuses.isNotEmpty && !forceRefresh) {
        return right(cachedStatuses);
      }

      // 3. Cache empty or force refresh — check connectivity before fetching remote
      final isConnected = await connectionChecker.isConnected;
      if (!isConnected) {
        if (cachedStatuses.isNotEmpty) {
          return right(cachedStatuses);
        }
        return right([]);
      }

      // 4. Fetch from remote
      final models = await statusRemoteDataSource.getAllStatus();

      // Preserve local paths from cache so UI can use cached images immediately
      final existingLocalPaths = await statusLocalDataSource.getLocalPaths();

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
        localPath: existingLocalPaths[m.id],
      )).toList();

      // 5. Update local cache (fire-and-forget to not block response)
      statusLocalDataSource.updateStatuses(models.map((e) => StatusHiveModel(
        id: e.id,
        userId: e.userId,
        imageUrl: e.imageUrl,
        caption: e.caption,
        createdAt: e.createdAt,
        expiresAt: e.expiresAt,
        userName: e.userName,
        localPath: "",
        profilepic: e.profilepic,
        likedBy: e.likedBy,
        isViewed: e.viewedBy.contains(currentUserId),
      )).toList());
      statusLocalDataSource.setLastFetchTime(DateTime.now());

      return right(statuses);

    } on ServerExceptions catch (_) {
      try{
        final status = await statusLocalDataSource.getAllStatuses();
        return right(status);
      }catch(e){
        return left(Failure(e.toString()));
      }
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
      await statusLocalDataSource.markAsViewed(statusId);

      final isConnected = await connectionChecker.isConnected;
      if (isConnected) {
        StatusViewModel statusViewModel = StatusViewModel(
          id: const Uuid().v1(), 
          statusId: statusId, 
          viewerId: viewerId, 
          viewerName: viewerName, 
          viewedAt: DateTime.now().toUtc(),
        );

        try {
          await statusRemoteDataSource.updateView(statusViewModel);
        } on StatusNotFoundException {
          await statusLocalDataSource.deleteById(statusId);
        }
      }

      return right(null);
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
      await statusLocalDataSource.deleteById(statusId);
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
    } on StatusNotFoundException {
      await statusLocalDataSource.deleteById(statusId);
      return right(null);
    } on ServerExceptions catch (e) {
      return left(Failure(e.message));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}
