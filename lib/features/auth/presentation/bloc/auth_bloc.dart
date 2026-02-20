import 'dart:async';

import 'package:chat_application/core/common/cubit/app_user_cubit.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/core/common/entities/user.dart';
import 'package:chat_application/features/auth/domain/usecase/current_user.dart';
import 'package:chat_application/features/auth/domain/usecase/user_sign_in.dart';
import 'package:chat_application/features/auth/domain/usecase/user_sign_out.dart';
import 'package:chat_application/features/auth/domain/usecase/user_sign_up.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final UserSignUp _userSignUp;
  final UserSignIn _userSignIn;
  final CurrentUser _currentUser;
  final UserSignOut _userSignOut;
  final AppUserCubit _appUserCubit;
  AuthBloc({
    required UserSignUp userSignUp,
    required UserSignIn userSignIn,
    required CurrentUser currentUser,
    required UserSignOut userSignOut,
    required AppUserCubit appUserCubit,
  })
    : _userSignUp = userSignUp,
    _userSignIn = userSignIn,
    _currentUser = currentUser,
    _userSignOut = userSignOut,
    _appUserCubit = appUserCubit,
      super(AuthInitial()) {
     on<AuthEvent>((_, emit)=> emit(AuthLoading()));
     on<AuthSignUp>(_onAuthSignUp);
     on<AuthSignIn>(_onAuthSignIn);
     on<AuthCheckRequested>(_onAuthCheckRequested);
     on<AuthSignOut>(_onAuthSignOut);
  }

  void _onAuthSignUp(AuthSignUp event, Emitter<AuthState> emit) async {
    //emit(AuthLoading());
    final res = await _userSignUp(
      UserSignUpParams(
        name: event.name,
        email: event.email,
        password: event.password,
      ),
    );

    res.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (user) => _emitAuthSuccess(user, emit),
    );
  }

  void _onAuthSignIn(AuthSignIn event, Emitter<AuthState> emit) async {
    final res = await _userSignIn(
      UserSignInParams(
        email: event.email, 
        password: event.password,
      )
    );

    res.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (user) => _emitAuthSuccess(user, emit),
    );
  }

  void _onAuthCheckRequested(AuthCheckRequested event, Emitter<AuthState> emit) async{
    //print("Checking current user...");
    final result = await _currentUser(NoParams());

    result.fold(
      (failure) => emit(AuthUnauthenticated()),
      (user) {
        if (user != null) {
          _emitAuthSuccess(user, emit);
        } else {
          emit(AuthUnauthenticated());
        }
      },
    );
  }

  FutureOr<void> _onAuthSignOut(AuthSignOut event, Emitter<AuthState> emit) async{
    final result = await _userSignOut(NoParams());

    result.fold(
      (failure) => emit(AuthFailure(failure.message)),
      (_) { // Use '_' because the success value is void/null
         _appUserCubit.updateUser(null); // Ensure AppUserCubit handles null
         emit(AuthUnauthenticated()); // Reset state to unauthenticated
      },
    );
  }

  void _emitAuthSuccess(User user, Emitter<AuthState> emit){
    _appUserCubit.updateUser(user);
    emit(AuthSuccess(user));
  }
}
