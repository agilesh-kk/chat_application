import 'package:chat_application/features/auth/domain/entities/user.dart';
import 'package:chat_application/features/auth/domain/usecase/user_sign_up.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final UserSignUp _userSignUp;
  AuthBloc({required UserSignUp userSignUp})
    : _userSignUp = userSignUp,
      super(AuthInitial()) {
     on<AuthEvent>((_, emit)=> emit(AuthLoading()));
     on<AuthSignUp>(_onAuthSignUp);
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
      (user) => emit(AuthSuccess(user)),
    );
  }
}
