import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/features/auth/domain/repository/auth_repository.dart';
import 'package:chat_application/features/auth/domain/entities/user.dart';
import 'package:fpdart/fpdart.dart';

class CurrentUser implements UseCase <User?, NoParams>{
  final AuthRepository authRepository;
  CurrentUser(this.authRepository);
                          
  @override              
  Future<Either<Failure, User?>> call(NoParams params) async {
    return await authRepository.getCurrentUser();  
  }
}