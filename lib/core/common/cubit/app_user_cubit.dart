import 'dart:async';

import 'package:chat_application/core/common/data/presence_remote_data_source.dart';
import 'package:chat_application/core/common/entities/user.dart';
import 'package:chat_application/core/data/user_device_data_source.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'app_user_state.dart';

//This handles the app user's persistent
class AppUserCubit extends Cubit<AppUserState> {
  final PresenceRemoteDataSource _presenceDataSource;
  final UserDeviceDataSource _deviceDataSource;
  Timer? _heartbeat;
  StreamSubscription? _tokenSub;
  String? _currentToken;

  AppUserCubit(this._presenceDataSource, this._deviceDataSource) : super(AppUserInitial());

  void updateUser(User? user){
    if(user == null){
      _clearUserFromPrefs();
      _stopHeartbeat();
      _deleteToken();
      emit(AppUserInitial());
    }
    else{
      emit(AppUserIsSignedin(user));
      _saveUserToPrefs(user);
      _startHeartbeat();
      _initToken(user.id);
    }
  }

  Future<void> _saveUserToPrefs(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_id', user.id);
    await prefs.setString('current_user_name', user.name);
    await prefs.setString('current_user_profile', user.profilePic ?? '');
  }

  Future<void> _clearUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
    await prefs.remove('current_user_name');
    await prefs.remove('current_user_profile');
  }

  Future<void> _initToken(String userId) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      _currentToken = token;
      await _deviceDataSource.upsertToken(userId, token, defaultTargetPlatform.name);
    }
    _tokenSub?.cancel();
    _tokenSub = FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      if (_currentToken != null) {
        await _deviceDataSource.deleteToken(_currentToken!);
      }
      await _deviceDataSource.upsertToken(userId, newToken, defaultTargetPlatform.name);
      _currentToken = newToken;
    });
  }

  Future<void> _deleteToken() async {
    _tokenSub?.cancel();
    _tokenSub = null;
    if (_currentToken != null) {
      await _deviceDataSource.deleteToken(_currentToken!);
      _currentToken = null;
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
