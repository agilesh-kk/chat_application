
import 'package:chat_application/features/timeline/domain/entities/event.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel extends Event{
  EventModel(
    {
    required super.id,
    required super.title, 
    required super.content, 
    required super.type, 
    required super.time, 
    required super.index
    });

  factory EventModel.fromJson(
    Map<String,dynamic> map,
    String id
  ){
    return EventModel(
      id: id,
      title: map["title"],
      index: map["index"],
      content: map["content"],
      type: map["type"],
      time: (map["time"] as Timestamp).toDate()
    );
  }

  Map<String,dynamic> toJson(){
    return 
    {
      "id" : id,
      "title" : title,
      "index" : index,
      "content" : content,
      "type" : type,
      "time" : time
    };
  }
  
}