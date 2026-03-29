import 'package:chat_application/core/common/entities/user.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'app_user_state.dart';

//This handles the app user's persistent
class AppUserCubit extends Cubit<AppUserState> {
  AppUserCubit() : super(AppUserInitial());

  void updateUser(User? user){
    if(user == null){
      emit(AppUserInitial());
    }
    else{
      emit(AppUserIsSignedin(user));
    }
  }

  //updating the profile picture of the current user (the user signed-in to the app)
  void updateUserProfilePic(String newPic) {
    if (state is AppUserIsSignedin) {
      final current = state as AppUserIsSignedin;

      emit(
        AppUserIsSignedin(
          current.user.copyWith(profilePic: newPic),
        ),
      );
    }
  }
}
