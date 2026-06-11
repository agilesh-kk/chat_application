import 'package:chat_application/core/errors/failure.dart';
import 'package:chat_application/core/usecase/usecase.dart';
import 'package:chat_application/features/timeline/domain/repositories/timeline_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:image_picker/image_picker.dart';

class AddPersonalEvent implements UseCase<void, AddPersonalEventParams>{
  final TimelineRepository timelineRepository;

  AddPersonalEvent({required this.timelineRepository});
  
  @override
  Future<Either<Failure, void>> call(AddPersonalEventParams params) async {
    try{
      await timelineRepository.addPersonalEvent(
        userId: params.userId,
        title: params.title,
        content: params.content,
        time: params.time,
        type: params.type,
        image: params.image,
      );
      return right(null);
    }
    catch(e){
      return left(Failure(e.toString()));
    }
  }
}

class AddPersonalEventParams {
  final String title;
  final String userId;
  final String content;
  final DateTime time;
  final String type;
  final XFile? image;

  AddPersonalEventParams({
    required this.title, 
    required this.userId, 
    required this.content, 
    required this.time, 
    required this.type,
    this.image,
  }); 
}