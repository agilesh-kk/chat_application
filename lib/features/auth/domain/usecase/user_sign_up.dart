import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/core/common/entities/user.dart';
import 'package:chat_application/features/auth/domain/repository/auth_repository.dart';
import 'package:fpdart/fpdart.dart';

//this usecase deals the sign up feature and passes the receieved datas to the bloc layer
class UserSignUp implements UseCase<User, UserSignUpParams>{
  final AuthRepository authRepository;

  UserSignUp(this.authRepository);

  @override
  Future<Either<Failure, User>> call(UserSignUpParams params) async{
    return await authRepository.signUpWithEmailPassword(
      name: params.name,
      email: params.email,
      password: params.password,
    );
  }
}

class UserSignUpParams {
  final String name;
  final String email;
  final String password;
  UserSignUpParams({
    required this.name,
    required this.email,
    required this.password,
  });
}