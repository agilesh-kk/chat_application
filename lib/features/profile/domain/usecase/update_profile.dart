import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/features/profile/domain/repository/profile_repository.dart';
import 'package:fpdart/fpdart.dart';

class UpdateProfile implements UseCase<void, UpdateProfileParams>{
  final ProfileRepository profileRepository;

  UpdateProfile({required this.profileRepository});

  @override
  Future<Either<Failure, void>> call(params) {
    return profileRepository.updateProfilePic(
      userId: params.userId, 
      imageUrl: params.imageUrl
    );
  }
}

class UpdateProfileParams {
  final String userId;
  final String imageUrl;

  UpdateProfileParams({
    required this.userId, 
    required this.imageUrl
  });
}