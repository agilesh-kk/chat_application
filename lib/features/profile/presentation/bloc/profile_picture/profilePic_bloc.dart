import 'dart:async';

import 'package:chat_application/features/profile/domain/usecase/update_custom_pfp.dart';
import 'package:chat_application/features/profile/domain/usecase/update_profile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

part 'profilePic_event.dart';
part 'profilePic_state.dart';

class ProfilePicBloc extends Bloc<ProfilePicEvent, ProfilePicState> {
  final UpdateProfile _updateProfile;
  final UpdateCustomPfp _updateCustomPfp;
  ProfilePicBloc({
    required UpdateProfile updateProfile,
    required UpdateCustomPfp updateCustomPfp,
  }) : 
  _updateProfile = updateProfile,
  _updateCustomPfp = updateCustomPfp,
  super(ProfileInitial()) {
    on<ProfilePicUpdate>(_onProfilePicUpdate);
    on<ProfilePicCustomUpload>(_onProfilePicCustomUpload);
  }

  FutureOr<void> _onProfilePicUpdate(ProfilePicUpdate event, Emitter<ProfilePicState> emit) async{
    final res = await _updateProfile(
      UpdateProfileParams(
        userId: event.userId, 
        imageUrl: event.imageUrl
      )
    );

    return res.fold(
      (failure) => emit(ProfilePicUpdateFailure(failure.message)),
      (_) => emit(ProfilePicUpdateScuccess(imageUrl: event.imageUrl))
    );
  }

  FutureOr<void> _onProfilePicCustomUpload(ProfilePicCustomUpload event, Emitter<ProfilePicState> emit) async{
    emit(ProfilePicLoading());
    final res = await _updateCustomPfp(
      UpdateCustomPfpParams(
        userId: event.userId, 
        image: event.image,
        oldPfpImage: event.oldPfpImage,
      )
    );

    return res.fold(
      (failure) => emit(ProfilePicUpdateFailure(failure.message)),
      (imageUrl) => emit(ProfilePicUpdateScuccess(imageUrl: imageUrl))
    );
  }
}
