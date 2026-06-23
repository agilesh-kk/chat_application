import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/features/watch2gether/domain/entity/w2g_video_item.dart';
import 'package:chat_application/features/watch2gether/domain/repository/w2g_repository.dart';
import 'package:fpdart/fpdart.dart';

class AddToQueue implements UseCase<void, AddToQueueParams> {
  final W2GRepository repository;

  AddToQueue(this.repository);

  @override
  Future<Either<Failure, void>> call(AddToQueueParams params) async {
    try {
      await repository.addToQueue(params.roomId, params.item);
      return right(null);
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}

class AddToQueueParams {
  final String roomId;
  final W2GVideoItem item;

  AddToQueueParams({required this.roomId, required this.item});
}
