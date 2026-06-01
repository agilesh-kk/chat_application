import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/errors/exceptions.dart';
import 'package:chat_application/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:chat_application/features/profile/domain/repository/profile_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fpdart/fpdart.dart';

class ProfileRepositoryImpl implements ProfileRepository{
  final ProfileRemoteDataSource profileRemoteDataSource;

  ProfileRepositoryImpl({required this.profileRemoteDataSource});

  @override
  Future<Either<Failure, void>> updateProfilePic({
    required String userId, 
    required String imageUrl
  }) async{
    try{
      profileRemoteDataSource.updateProfilePic(userId, imageUrl);
      return right(null);
    }
    on ServerExceptions catch(e){
      return left(Failure(e.message));
    }
  }
  
  @override
  Future<Either<Failure, void>> updateBio({required String userId, required String bio}) async{
    try{
      await profileRemoteDataSource.updateBio(userId, bio);
      return right(null);
    }
    on ServerExceptions catch(e){
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, String>> updateCustompfp({
    required String userId, 
    required XFile image, 
    required String oldPfpImage,
  }) async{
    try{
      final imageUrl = await profileRemoteDataSource.uploadCustomPfp(
        userId: userId,  
        image: image,
        oldPfpImage: oldPfpImage,
      );

      await profileRemoteDataSource.updateProfilePic(userId, imageUrl);
      return right(imageUrl);
    }
    on ServerExceptions catch(e){
      return left(Failure(e.message));
    }
    catch(e){
      return left(Failure(e.toString()));
    }
  }
}