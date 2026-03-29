import 'package:chat_application/core/errors/failure.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class ProfileRepository {
  //updating profile pic
  Future<Either<Failure, void>> updateProfilePic({
    required String userId,
    required String imageUrl,
  });

  //updating bio
  Future<Either<Failure, void>> updateBio({
    required String userId,
    required String bio,
  });
}