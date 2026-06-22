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
    items[message.id] = message;
    ids.add(message.id);
  }
}

// class DeleteMessageOperation implements ListOperation<Message> {
//   final String msgId;
//   final bool deleteForEveryone;
//   final String deletedBy;
//   DeleteMessageOperation(this.msgId, this.deletedBy,
//       {this.deleteForEveryone = false});
//   @override Map<String, Message> performOperation(Map<String, Message> items) {
//     final m = items[msgId];
//     if (m == null) return items;
//     items[msgId] = deleteForEveryone
//         ? m.copyWith(deletedForEveryone: true)
//         : m.copyWith(deletedfor: [...m.deletedfor, deletedBy]);
//     return items;
//   }
// }

// class SetReactionOperation implements ListOperation<Message> {
//   final String messageId;
//   final String userId;
//   final String emoji;
//   SetReactionOperation(this.messageId, this.userId, this.emoji);
//   @override Map<String, Message> performOperation(Map<String, Message> items) {
//     final m = items[messageId];
//     if (m == null) return items;
//     final reactions = Map<String, String>.from(m.reactions);
//     if (reactions[userId] == emoji) {
//       reactions.remove(userId);
//     } else {
//       reactions[userId] = emoji;
//     }
//     items[messageId] = m.copyWith(reactions: reactions);
//     return items;
//   }
// }

// class EditMessageOperation implements ListOperation<Message> {
//   final String msgId;
//   final String newContent;
//   EditMessageOperation(this.msgId, this.newContent);
//   @override Map<String, Message> performOperation(Map<String, Message> items) {
//     final m = items[msgId];
//     if (m == null) return items;
//     items[msgId] = m.copyWith(content: newContent, isEdited: true);
//     return items;
//   }
// }

// class MarkSeenOperation implements ListOperation<Message> {
//   final List<String> ids;
//   MarkSeenOperation(this.ids);
//   @override Map<String, Message> performOperation(Map<String, Message> items) {
//     for (final id in ids) {
//       final m = items[id];
//       if (m != null) items[id] = m.copyWith(status: 'seen');
//     }
//     return items;
//   }
// }

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
