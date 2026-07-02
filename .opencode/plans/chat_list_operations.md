# Chat: Command Pattern for List Mutations

## Concept

Instead of re-querying the entire message list from SQLite on every change, each mutation is encapsulated as an `Operation` object that knows how to update the in-memory list via `performOperation()`.

```
DB write ──► emitOperation(SetReactionOperation) ──► stream ──► BLoC applies to list ──► emit
User tap  ──► BLoC creates SetReactionOperation ──► apply + emit + DB write + remote
```

## 1. Add `copyWith` to `Message`

`lib/features/chats/domain/entities/message.dart` — add:

```dart
Message copyWith({
  String? id, String? senderId, String? content, DateTime? createdAt,
  String? type, List<String>? deletedfor, bool? deletedForEveryone,
  bool? isLocal, String? status, String? localPath, DateTime? sendAt,
  bool? isScheduled, bool? inTimeline, bool? isEdited,
  Map<String, String>? reactions, String? replyToId, String? replyToContent,
  String? replyToSenderId, String? replyToType,
}) => Message(
  id: id ?? this.id, senderId: senderId ?? this.senderId,
  content: content ?? this.content, createdAt: createdAt ?? this.createdAt,
  type: type ?? this.type, deletedfor: deletedfor ?? this.deletedfor,
  deletedForEveryone: deletedForEveryone ?? this.deletedForEveryone,
  isLocal: isLocal ?? this.isLocal, status: status ?? this.status,
  localPath: localPath ?? this.localPath, sendAt: sendAt ?? this.sendAt,
  isScheduled: isScheduled ?? this.isScheduled,
  inTimeline: inTimeline ?? this.inTimeline,
  isEdited: isEdited ?? this.isEdited,
  reactions: reactions ?? this.reactions,
  replyToId: replyToId ?? this.replyToId,
  replyToContent: replyToContent ?? this.replyToContent,
  replyToSenderId: replyToSenderId ?? this.replyToSenderId,
  replyToType: replyToType ?? this.replyToType,
);
```

## 2. Create `ListOperation<T>` abstraction

`lib/features/chats/domain/entities/list_operation.dart`:

```dart
/// Applies a typed mutation to an in-memory list.
abstract interface class ListOperation<T> {
  List<T> performOperation(List<T> items);
}
```

## 3. Concrete operation classes (same file or domain/operations/)

```dart
class SnapshotOperation<T> implements ListOperation<T> {
  final List<T> items;
  SnapshotOperation(this.items);
  @override List<T> performOperation(List<T> _) => items;
}

class NewMessageOperation implements ListOperation<Message> {
  final Message message;
  NewMessageOperation(this.message);
  @override List<Message> performOperation(List<Message> items) =>
      [message, ...items];
}

class DeleteMessageOperation implements ListOperation<Message> {
  final String msgId;
  final bool deleteForEveryone;
  final String deletedBy;
  DeleteMessageOperation(this.msgId, this.deletedBy, {this.deleteForEveryone = false});
  @override List<Message> performOperation(List<Message> items) => items.map((m) {
    if (m.id != msgId) return m;
    if (deleteForEveryone) return m.copyWith(deletedForEveryone: true);
    return m.copyWith(deletedfor: [...m.deletedfor, deletedBy]);
  }).toList();
}

class SetReactionOperation implements ListOperation<Message> {
  final String messageId;
  final String userId;
  final String emoji;
  SetReactionOperation(this.messageId, this.userId, this.emoji);
  @override List<Message> performOperation(List<Message> items) => items.map((m) {
    if (m.id != messageId) return m;
    final reactions = Map<String, String>.from(m.reactions);
    if (reactions[userId] == emoji) { reactions.remove(userId); }
    else { reactions[userId] = emoji; }
    return m.copyWith(reactions: reactions);
  }).toList();
}

class EditMessageOperation implements ListOperation<Message> {
  final String msgId;
  final String newContent;
  EditMessageOperation(this.msgId, this.newContent);
  @override List<Message> performOperation(List<Message> items) => items.map((m) {
    if (m.id != msgId) return m;
    return m.copyWith(content: newContent, isEdited: true);
  }).toList();
}

class MarkSeenOperation implements ListOperation<Message> {
  final List<String> ids;
  MarkSeenOperation(this.ids);
  @override List<Message> performOperation(List<Message> items) {
    final idSet = ids.toSet();
    return items.map((m) => idSet.contains(m.id) ? m.copyWith(status: 'seen') : m).toList();
  }
}

class BatchOperation implements ListOperation<Message> {
  final List<ListOperation<Message>> operations;
  BatchOperation(this.operations);
  @override List<Message> performOperation(List<Message> items) {
    for (final op in operations) { items = op.performOperation(items); }
    return items;
  }
}
```

## 4. Add operation stream to `ChatLocalDataSource`

```dart
// In abstract interface:
Stream<ListOperation<Message>> getOperationStream(String conversationId);
void emitOperation(String conversationId, ListOperation<Message> operation);
```

Implementation in `ChatLocalDataSourceImpl`:

```dart
final Map<String, StreamController<ListOperation<Message>>> _opControllers = {};

@override
Stream<ListOperation<Message>> getOperationStream(String conversationId) {
  _opControllers[conversationId] ??= StreamController<ListOperation<Message>>.broadcast();
  return _opControllers[conversationId]!.stream;
}

@override
void emitOperation(String conversationId, ListOperation<Message> operation) {
  final ctrl = _opControllers[conversationId];
  if (ctrl != null && !ctrl.isClosed) ctrl.add(operation);
}
```

## 5. Wire operations in `ChatRepositoryImpl._processOperation`

After each `case` in the operation listener, call `emitOperation`:

```dart
case 'new_message':
  final msgId = opData['messageId'] as String? ?? docId;
  final msg = Message(id: msgId, senderId: ..., content: ..., ...);  // build from opData
  await chatLocalDataSource.upsertMessageFromFirestore(opData, msgId);
  chatLocalDataSource.emitOperation(convoId, NewMessageOperation(msg));
  // ... updateConvo ...
  break;

case 'delete_message':
  await chatLocalDataSource.updateMessageDeletion(...);
  chatLocalDataSource.emitOperation(convoId, DeleteMessageOperation(msgId, userId, deleteForEveryone: deletedForEveryone));
  break;

case 'reaction':
  await chatLocalDataSource.updateMessageReaction(...);
  chatLocalDataSource.emitOperation(convoId, SetReactionOperation(msgId, userId, emoji));
  break;

case 'seen':
  await chatLocalDataSource.markMessagesSeen(msgIds, seenByUserId, convoId);
  chatLocalDataSource.emitOperation(convoId, MarkSeenOperation(msgIds));
  break;

case 'edit_message':
  await chatLocalDataSource.updateMessageContent(msgId, newContent);
  chatLocalDataSource.emitOperation(convoId, EditMessageOperation(msgId, newContent));
  break;
```

## 6. Refactor `ChatBloc` to use operations

### 6a. Subscribe to operation stream

In `LoadMessagesEvent`, after subscribing to `getMessagesStream` for initial load:

```dart
StreamSubscription<ListOperation<Message>>? _operationSub;

// In _onLoadMessages:
final convoId = _generateConversationId(event.userId, event.receiverId);

// Subscribe to incremental operations
_operationSub = _chatLocalDataSource.getOperationStream(convoId).listen((op) {
  final current = state;
  if (current is ChatLoaded) {
    final updated = op.performOperation(current.messages);
    if (!isClosed) emit(ChatLoaded(updated));
  }
});
```

### 6b. User actions create and apply operations directly

```dart
on<SendMessageEvent>((event, emit) async {
  final currentState = state as ChatLoaded;
  final msgId = const Uuid().v1();
  final tempMessage = Message(id: msgId, ...);
  
  // Apply operation directly (no DB read needed)
  final op = NewMessageOperation(tempMessage);
  emit(ChatLoaded(op.performOperation(currentState.messages)));
  
  // Silent DB write + remote
  await chatLocalDataSource.upsertMessageLocally({...}, msgId);
  await _sendMessage(...);
});

on<ToggleReactionEvent>((event, emit) async {
  final current = state;
  if (current is! ChatLoaded) return;
  
  // Apply in memory
  final op = SetReactionOperation(event.messageId, event.userId, event.emoji);
  emit(ChatLoaded(op.performOperation(current.messages)));
  
  // Remote call (DB updated via operation listener + emitOperation)
  await _toggleReaction(...);
});
```

Same pattern for `DeleteMessageEvent`, `EditMessageEvent`, `MarkMessagesDeliveredEvent`.

### 6c. Remove double-emission from `_updateMessages`

```dart
void _updateMessages(List<Message> received, Emitter<ChatState> emit) {
  received.removeWhere((e) => e.deletedfor.contains(_currentUserId) && !e.deletedForEveryone);
  emit(ChatLoaded(received));
}
```
Keep as fallback for the initial `getMessagesStream` emission. The operation stream handles all subsequent updates.

## 7. Add `upsertMessageLocally` to `ChatLocalDataSource`

Same as `upsertMessageFromFirestore` but without `_notify()` call, for user-initiated optimistic writes:

```dart
Future<void> upsertMessageLocally(Map<String, dynamic> firestoreData, String docId) async {
  if (_db == null || kIsWeb) return;
  final convoId = firestoreData['convoId'] as String? ?? '';
  if (convoId.isEmpty) return;
  await _db!.insert('messages', _firestoreToDb(firestoreData, docId, convoId),
      conflictAlgorithm: ConflictAlgorithm.replace);
}
```

## 8. Cancel operation subscription in `close()`

```dart
@override
Future<void> close() async {
  await _messageSub?.cancel();
  await _operationSub?.cancel();  // NEW
  await _chatRepository.stopOperationListener();
  return super.close();
}
```

## Summary of changes

| File | Change |
|------|--------|
| `message.dart` | Add `copyWith()` |
| `list_operation.dart` | **NEW** — `ListOperation<T>` interface + all concrete classes |
| `chat_local_data_sources.dart` | Add `getOperationStream()` + `emitOperation()` + `upsertMessageLocally()` |
| `chat_repository_impl.dart` | After `_processOperation` case, call `emitOperation()` |
| `chat_bloc.dart` | Subscribe to operation stream; actions create + apply operations directly |
| `chat_events.dart` | No change needed |
| `chat_states.dart` | No change needed |
