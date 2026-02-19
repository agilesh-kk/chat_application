import 'package:chat_application/core/errors/failure.dart';
import 'package:fpdart/fpdart.dart';

//creating interface for usecases in domain layer 
//this class will be used in authentication as well as chat features
abstract interface class UseCase<SuccessType, Params>{
  Future<Either<Failure, SuccessType>> call(Params params);
}

class NoParams{}