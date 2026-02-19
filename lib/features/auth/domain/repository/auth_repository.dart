import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/features/auth/domain/entities/user.dart';
import 'package:fpdart/fpdart.dart';

//creating the interface for the repository (it is independent)

abstract interface class AuthRepository {

  //interface for signing up with email and password.
  Future<Either<Failure, User>> signUpWithEmailPassword({
    required String name,
    required String email,
    required String password,
  });

  //interface for signing in with email and password.
  Future<Either<Failure, User>> signInWithEmailPassword({
    required String email,
    required String password,
  });

  //interface for getting the user details who is currently logged in.
  Future<Either<Failure, User?>> getCurrentUser();
}