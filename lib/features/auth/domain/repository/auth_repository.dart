import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/features/auth/domain/entities/user.dart';
import 'package:fpdart/fpdart.dart';

//creating the interface for the repository (it is independent)

abstract interface class AuthRepository {

  //interface for signing up with email and password
  Future<Either<Failure, User>> signUpWithEmailPassword({
    required String name,
    required String email,
    required String password,
  });
}