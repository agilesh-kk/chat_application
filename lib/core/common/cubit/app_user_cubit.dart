import 'dart:async';

import 'package:chat_application/core/common/data/presence_remote_data_source.dart';
import 'package:chat_application/core/common/entities/user.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'app_user_state.dart';

//This handles the app user's persistent
class AppUserCubit extends Cubit<AppUserState> {
  final PresenceRemoteDataSource _presenceDataSource;
  Timer? _heartbeat;

  AppUserCubit(this._presenceDataSource) : super(AppUserInitial());

  void updateUser(User? user){
    if(user == null){
      _stopHeartbeat();
      emit(AppUserInitial());
    }
    else{
      emit(AppUserIsSignedin(user));
      _startHeartbeat();
    }
  }

  Future<void> setOnline(bool isOnline) async {
    if (state is! AppUserIsSignedin) return;
    final userId = (state as AppUserIsSignedin).user.id;

    try {
      await _presenceDataSource.setOnline(userId, isOnline);
      if (isOnline) {
        _startHeartbeat();
      } else {
        _stopHeartbeat();
      }
    } catch (_) {}
  }

  void _startHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _heartbeatTick(),
    );
  }

  void _stopHeartbeat() {
    _heartbeat?.cancel();
    _heartbeat = null;
  }

  Future<void> _heartbeatTick() async {
    if (state is! AppUserIsSignedin) return;
    final userId = (state as AppUserIsSignedin).user.id;
    try {
      await _presenceDataSource.updateLastSeen(userId);
    } catch (_) {}
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

  @override
  Future<void> close() {
    _stopHeartbeat();
    return super.close();
  }
}
