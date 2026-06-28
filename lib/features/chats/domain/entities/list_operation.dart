import 'package:chat_application/features/chats/domain/entities/message.dart';

abstract interface class ListOperation<T> {
  void performOperation(List<String> ids,Map<String, T> items);
}

class FirstFetch<T> implements ListOperation<Message> {
  final List<Message> items;
  FirstFetch(this.items);
  @override void performOperation(List<String> ids,Map<String, Message> m){
    for(final v in items){
      m[v.id] = v;
      ids.add(v.id);
    }
  }
}

class NewMessageOperation implements ListOperation<Message> {
  final Message message;
  NewMessageOperation(this.message);
  @override void performOperation(List<String> ids,Map<String, Message> items) {
    if(items.containsKey(message.id)) {
      return;
    }
      
    items[message.id] = message;
    ids.insert(0, message.id);
  }
}

class TimeLineOperation implements ListOperation<Message> {
  final String id;
  final bool added;

  TimeLineOperation(this.id,this.added);
  @override void performOperation(List<String> ids,Map<String, Message> items) {
    items[id] = items[id]!.copyWith(inTimeline: added);
  }
}

class DeleteMessageOperation implements ListOperation<Message> {
  final String msgId;
  final bool deleteForEveryone;
  final List<String> deletedfor;
  DeleteMessageOperation(this.msgId, this.deletedfor,
      {this.deleteForEveryone = false});
  @override performOperation(List<String> ids,Map<String, Message> items) {
    items[msgId] = items[msgId]!.copyWith(deletedForEveryone: deleteForEveryone,deletedfor: deletedfor);
  }
}

class SetReactionOperation implements ListOperation<Message> {
  final String messageId;
  final Map<String, String> reacts;

  SetReactionOperation(this.messageId, this.reacts);

  @override performOperation(List<String> ids,Map<String, Message> items) {
    items[messageId] = items[messageId]!.copyWith(reactions: reacts);
  }
}

class EditMessageOperation implements ListOperation<Message> {
  final String msgId;
  final String newContent;
  EditMessageOperation(this.msgId, this.newContent);
  @override void performOperation(List<String> ids,Map<String, Message> items) {
    items[msgId] = items[msgId]!.copyWith(content: newContent,isEdited: true);
  }
}

class MarkSeenOperation implements ListOperation<Message> {
  final List<String> ids;
  final String status;
  MarkSeenOperation(this.ids,this.status);
  @override void performOperation(List<String> idss,Map<String, Message> items) {
    for(String id in ids){
      items[id] = items[id]!.copyWith(status: status);
    }
  }
}

// class BatchOperation<T> implements ListOperation<T> {
//   final List<ListOperation<T>> operations;
//   BatchOperation(this.operations);
//   @override Map<String, T> performOperation(Map<String, T> items) {
//     for (final op in operations) {
//       items = op.performOperation(items);
//     }
//     return items;
//   }
// }
