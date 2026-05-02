import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/features/chats/domain/entities/message.dart';
import 'package:chat_application/features/timeline/domain/repositories/timeline_repository.dart';
import 'package:fpdart/fpdart.dart';

class AddTimeLineEvent implements UseCase<void, AddEventParams>{
  final TimelineRepository timelineRepository;

  AddTimeLineEvent({required this.timelineRepository});
  
  @override
  Future<Either<Failure, void>> call(AddEventParams params) async {
    try{
      await timelineRepository.addEvent(
        message: params.message, 
        userId: params.userId, 
        receiverId: params.receiverId, 
        customTitle: params.customTitle, 
        addedByName: params.addedByName,
      );
      return right(null);
    }
    catch(e){
      return left(Failure(e.toString()));
    }
  }
}

class AddEventParams {
  final Message message;
  final String userId;
  final String receiverId;
  final String customTitle;
  final String addedByName;

  AddEventParams({
    required this.message, 
    required this.userId, 
    required this.receiverId, 
    required this.customTitle, 
    required this.addedByName
  }); 
}