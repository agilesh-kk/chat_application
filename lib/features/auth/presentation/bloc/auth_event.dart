part of 'auth_bloc.dart';

@immutable
sealed class AuthEvent {}

final class AuthSignUp extends AuthEvent {
  final String name;
  final String email;
  final String password;
  final DateTime birthDate;

  AuthSignUp({
    required this.name, 
    required this.email, 
    required this.password,
    required this.birthDate,
  });
}

final class AuthSignIn extends AuthEvent {
  final String email;
  final String password;

  AuthSignIn({
    required this.email, 
    required this.password
  });
}

class AuthCheckRequested extends AuthEvent {}

final class AuthSignOut extends AuthEvent{}