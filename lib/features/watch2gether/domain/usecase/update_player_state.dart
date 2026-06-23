import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/features/watch2gether/domain/entity/w2g_room.dart';
import 'package:chat_application/features/watch2gether/domain/repository/w2g_repository.dart';
import 'package:fpdart/fpdart.dart';

class UpdatePlayerState implements UseCase<void, UpdatePlayerStateParams> {
  final W2GRepository repository;

  UpdatePlayerState(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdatePlayerStateParams params) async {
    try {
      await repository.updatePlayerState(params.roomId, params.state);
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}

class UpdatePlayerStateParams {
  final String roomId;
  final W2GPlayerState state;

  UpdatePlayerStateParams({required this.roomId, required this.state});
}
