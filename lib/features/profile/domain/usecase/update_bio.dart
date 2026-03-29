import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/features/profile/domain/repository/profile_repository.dart';
import 'package:fpdart/fpdart.dart';

class UpdateBio implements UseCase<void, UpdateBioParams>{
  final ProfileRepository profileRepository;

  UpdateBio({required this.profileRepository});
  @override
  Future<Either<Failure, void>> call(UpdateBioParams params) async{
    return profileRepository.updateBio(
      userId: params.userId, 
      bio: params.bio,
    );
  }

}

class UpdateBioParams {
  final String userId;
  final String bio;

  UpdateBioParams({
    required this.bio,
    required this.userId,
  });
}