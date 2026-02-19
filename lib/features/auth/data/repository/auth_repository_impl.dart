import 'package:chat_application/core/errors/exceptions.dart';
import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/features/auth/data/datasources/auth_remote_data_sources.dart';
import 'package:chat_application/features/auth/domain/entities/user.dart';
import 'package:chat_application/features/auth/domain/repository/auth_repository.dart';
import 'package:fpdart/fpdart.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSources remoteDataSources;

  AuthRepositoryImpl(this.remoteDataSources);
  @override
  Future<Either<Failure, User>> signUpWithEmailPassword({
    required String name,
    required String email,
    required String password,
  }) async {
    return _getuser(
      () async => await remoteDataSources.signUpWithEmailPassword(
        name: name,
        email: email,
        password: password,
      ),
    );
  }

  @override
  Future<Either<Failure, User>> signInWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _getuser(
      () async => await remoteDataSources.signInWithEmailPassword(
        email: email, 
        password: password,
      )
    );
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    return _getNullableUser(
      () async => await remoteDataSources.getCurrentUser()
    );
  }

  //created a function for try and catch, since it is repeatedly used in the codes, also making it easier to add any othre exceptions and other validations.
  Future<Either<Failure, User>> _getuser(Future<User> Function() fn) async {
    try {
      final user = await fn();
      return right(
        user,
      ); //right function gives success message, the argument passed inside the right() is received as success
    } on ServerExceptions catch (e) {
      return left(Failure(e.message)); //returns a Failure class message
    }
  }

  //the receieved usermodel may be null depending on the state of user persistance in the app
  Future<Either<Failure, User?>> _getNullableUser(
    Future<User?> Function() fn,
  ) async {
    try {
      final user = await fn();
      return right(user);
    } on ServerExceptions catch (e) {
      return left(Failure(e.message));
    }
  }
}
