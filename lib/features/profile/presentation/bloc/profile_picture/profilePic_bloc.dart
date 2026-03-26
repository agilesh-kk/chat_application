import 'dart:async';

import 'package:chat_application/features/profile/domain/usecase/update_profile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'profilePic_event.dart';
part 'profilePic_state.dart';

class ProfilePicBloc extends Bloc<ProfilePicEvent, ProfilePicState> {
  final UpdateProfile _updateProfile;
  ProfilePicBloc({
    required UpdateProfile updateProfile,
  }) : 
  _updateProfile = updateProfile,
  super(ProfileInitial()) {
    //on<ProfilePicEvent>((_, emit)=> emit(()));
    on<profilePicUpdate>(_onProfilePicUpdate);
  }

  FutureOr<void> _onProfilePicUpdate(profilePicUpdate event, Emitter<ProfilePicState> emit) async{
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
}
