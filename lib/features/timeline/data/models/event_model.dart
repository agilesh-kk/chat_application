import 'package:chat_application/features/timeline/domain/entities/event.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel extends Event{
  EventModel({
    required super.id,
    required super.title, 
    required super.content, 
    required super.type, 
    required super.time, 
    required super.index,

    //manual adding
    required super.messageId,
    required super.addedBy,
    required super.addedByName,
    required super.isManual,

    //personal timeline images
    super.imageUrl,
    super.hasImage,
  });

  factory EventModel.fromJson(
    Map<String,dynamic> map,
    String id
  ){
    return EventModel(
      id: id,
      title: map["title"],
      index: (map["index"] ?? 0) as int,
      content: map["content"],
      type: map["type"],
      time: (map["time"] as Timestamp).toDate(),

      messageId: map["messageId"] ?? "",
      addedBy: map["addedBy"] ?? "",
      addedByName: map["addedByName"] ?? "",
      isManual: map["isManual"] ?? false,

      imageUrl: map["imageUrl"] ?? "",
      hasImage: map["hasImage"] ?? false,
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
      "time" : time,

      "messageId": messageId,
      "addedBy": addedBy,
      "addedByName": addedByName,
      "isManual": isManual,

      "imageUrl" : imageUrl,
      "hasImage" : hasImage,
    };
  }
  
}