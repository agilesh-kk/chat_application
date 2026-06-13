import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/features/profile/domain/repository/profile_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:image_picker/image_picker.dart';

class UpdateCustomPfp implements UseCase<String, UpdateCustomPfpParams>{
  final ProfileRepository profileRepository;

  UpdateCustomPfp({required this.profileRepository});

  @override
  Future<Either<Failure, String>> call(params) {
    return profileRepository.updateCustompfp(
      userId: params.userId, 
      image: params.image,
      oldPfpImage: params.oldPfpImage,
    );
  }
}

class UpdateCustomPfpParams {
  final String userId;
  final XFile image;
  final String oldPfpImage;

  UpdateCustomPfpParams({
    required this.userId, 
    required this.image,
    required this.oldPfpImage,
  });
}
