import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/features/watch2gether/domain/repository/w2g_repository.dart';
import 'package:fpdart/fpdart.dart';

class CreateRoom implements UseCase<String, CreateRoomParams> {
  final W2GRepository repository;

  CreateRoom(this.repository);

  @override
  Future<Either<Failure, String>> call(CreateRoomParams params) async {
    try {
      final id = await repository.createRoom(params.name, params.createdBy);
      return right(id);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}

class CreateRoomParams {
  final String name;
  final String createdBy;

  CreateRoomParams({required this.name, required this.createdBy});
}
