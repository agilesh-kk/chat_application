import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/features/watch2gether/domain/entity/w2g_participant.dart';
import 'package:chat_application/features/watch2gether/domain/repository/w2g_repository.dart';
import 'package:fpdart/fpdart.dart';

class JoinRoom implements UseCase<void, JoinRoomParams> {
  final W2GRepository repository;

  JoinRoom(this.repository);

  @override
  Future<Either<Failure, void>> call(JoinRoomParams params) async {
    try {
      await repository.joinRoom(params.roomId, params.participant);
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}

class JoinRoomParams {
  final String roomId;
  final W2GParticipant participant;

  JoinRoomParams({required this.roomId, required this.participant});
}
