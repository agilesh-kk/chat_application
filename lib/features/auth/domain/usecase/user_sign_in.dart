import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/features/auth/domain/entities/user.dart';
import 'package:chat_application/features/auth/domain/repository/auth_repository.dart';
import 'package:fpdart/fpdart.dart';


class UserSignIn implements UseCase <User, UserSignInParams> {
  final AuthRepository authRepository;

  UserSignIn(this.authRepository);
  @override
  Future<Either<Failure, User>> call(UserSignInParams params) async{
    return await authRepository.signInWithEmailPassword(
      email: params.email, 
      password: params.password
    );
  }
}

class UserSignInParams {
  final String email;
  final String password;

  UserSignInParams({
    required this.email, 
    required this.password,
  });
}