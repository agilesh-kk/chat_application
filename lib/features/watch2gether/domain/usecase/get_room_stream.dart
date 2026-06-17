import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/features/watch2gether/domain/entity/w2g_room.dart';
import 'package:chat_application/features/watch2gether/domain/repository/w2g_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetRoomStream implements UseCase<Stream<W2GRoom>, String> {
  final W2GRepository repository;

  GetRoomStream(this.repository);

  @override
  Future<Either<Failure, Stream<W2GRoom>>> call(String roomId) async {
    try {
      return right(repository.getRoomStream(roomId));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}
