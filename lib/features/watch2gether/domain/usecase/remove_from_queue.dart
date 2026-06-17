import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/features/watch2gether/domain/repository/w2g_repository.dart';
import 'package:fpdart/fpdart.dart';

class RemoveFromQueue implements UseCase<void, RemoveFromQueueParams> {
  final W2GRepository repository;

  RemoveFromQueue(this.repository);

  @override
  Future<Either<Failure, void>> call(RemoveFromQueueParams params) async {
    try {
      await repository.removeFromQueue(params.roomId, params.itemId);
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}

class RemoveFromQueueParams {
  final String roomId;
  final String itemId;

  RemoveFromQueueParams({required this.roomId, required this.itemId});
}
