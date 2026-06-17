import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/features/watch2gether/domain/repository/w2g_repository.dart';
import 'package:fpdart/fpdart.dart';

class LeaveRoom implements UseCase<void, LeaveRoomParams> {
  final W2GRepository repository;

  LeaveRoom(this.repository);

  @override
  Future<Either<Failure, void>> call(LeaveRoomParams params) async {
    try {
      await repository.leaveRoom(params.roomId, params.userId);
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}

class LeaveRoomParams {
  final String roomId;
  final String userId;

  LeaveRoomParams({required this.roomId, required this.userId});
}
