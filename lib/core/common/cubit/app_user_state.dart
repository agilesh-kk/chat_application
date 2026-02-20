part of 'app_user_cubit.dart';

@immutable
sealed class AppUserState {}

final class AppUserInitial extends AppUserState {}

final class AppUserIsSignedin extends AppUserState{
  final User user;
  AppUserIsSignedin(this.user);
}