import 'package:chat_application/core/errors/failure.dart';
import 'package:fpdart/fpdart.dart';
import 'package:image_picker/image_picker.dart';

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

  //updating custom pfp
  Future<Either<Failure, String>> updateCustompfp({
    required String userId,
    required XFile image,
  });
}