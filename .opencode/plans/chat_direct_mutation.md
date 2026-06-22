# Chat: Direct List Mutation for All User Actions

## Goal

For all user-initiated actions (send, delete, reaction, edit):
1. Update local DB (offline persistence)
2. **Directly mutate the in-memory list in BLoC and emit immediately** — no re-query
3. Send to remote in background

Only rely on the DB stream (`_messageSub`) for **incoming remote actions** from the other user.

## Problem to Solve

The current `_notify()` call inside every DB write triggers the stream, which re-emits the full list via `MessagesUpdatedEvent`. This means **every user action causes two emissions**: one from direct mutation, one from the stream. We need to prevent the stream from re-emitting for the user's own actions.

## Changes

### 1. `chat_local_data_sources.dart` — Add silent DB write methods

Add methods that write to the DB **without** calling `_notify()`, so the stream isn't triggered for the user's own actions:

```dart
/// Write to DB only — no stream notification (for optimistic local writes)
Future<void> upsertMessageLocally(Map<String, dynamic> firestoreData, String docId) async {
  if (_db == null || kIsWeb) return;
  final convoId = firestoreData['convoId'] as String? ?? '';
  if (convoId.isEmpty) return;
  final row = _firestoreToDb(firestoreData, docId, convoId);
  await _db!.insert('messages', row, conflictAlgorithm: ConflictAlgorithm.replace);
  // NO _notify(convoId) — caller will emit directly
}
```

Keep existing `upsertMessageFromFirestore` unchanged (it still calls `_notify` for incoming remote messages via the operation listener).

### 2. `chat_bloc.dart` — Direct mutation for ALL user actions

#### SendMessageEvent (already direct, but switch to silent DB write)

```dart
// Before:
await _chatLocalDataSource.upsertMessageFromFirestore({...}, msgId);  // triggers _notify → double-build
final updatedMessages = List<Message>.from(currentState.messages)..insert(0, tempMessage);
emit(ChatLoaded(updatedMessages));

// After:
await _chatLocalDataSource.upsertMessageLocally({...}, msgId);  // no _notify
final updatedMessages = List<Message>.from(currentState.messages)..insert(0, tempMessage);
emit(ChatLoaded(updatedMessages));
```

#### SendImageEvent (same change)

```dart
// Switch to upsertMessageLocally, same pattern as above
```

#### DeleteMessageEvent — new direct mutation

```dart
// Before: delegates to remote + relies on operation listener → stream → re-emit
FutureOr<void> _onDeleteMessageEvent(...) async {
  final res = await _deleteMessage(...);
  res.fold((failure) => emit(ChatError(failure.message)), (_) {});
}

// After: optimistic local + direct emit + remote call
FutureOr<void> _onDeleteMessageEvent(DeleteMessageEvent event, Emitter<ChatState> emit) async {
  final current = state;
  if (current is! ChatLoaded) return;

  // 1. Update local DB silently
  await _chatLocalDataSource.updateMessageDeletion(
    event.msgId, convoId, event.userId, event.receiverId, 
    deletedfor, event.deleteForEveryone,
  );

  // 2. Directly mutate in-memory list and emit
  final updated = current.messages.map((m) {
    if (m.id == event.msgId) {
      return m.copyWith(
        deletedfor: [...m.deletedfor, event.userId],
        deletedForEveryone: event.deleteForEveryone,
      );
    }
    return m;
  }).toList();
  emit(ChatLoaded(updated));

  // 3. Send to remote (async, don't await)
  _deleteMessage(DeleteMessageParams(...));
}
```

#### ToggleReactionEvent — new direct mutation

```dart
// After:
FutureOr<void> _onToggleReactionEvent(ToggleReactionEvent event, Emitter<ChatState> emit) async {
  final current = state;
  if (current is! ChatLoaded) return;

  // 1. Compute new reactions in memory
  final updatedMessages = current.messages.map((m) {
    if (m.id == event.messageId) {
      final newReactions = Map<String, String>.from(m.reactions);
      if (newReactions[event.userId] == event.emoji) {
        newReactions.remove(event.userId);
      } else {
        newReactions[event.userId] = event.emoji;
      }
      return m.copyWith(reactions: newReactions);
    }
    return m;
  }).toList();
  emit(ChatLoaded(updatedMessages));

  // 2. Update local DB silently
  await _chatLocalDataSource.updateMessageReaction(
    event.messageId, convoId, event.userId, event.receiverId,
    newReactions, event.emoji, event.userId,
  );

  // 3. Send to remote
  await _toggleReaction(ToggleReactionParams(...));
}
```

#### EditMessageEvent — new direct mutation

```dart
// After:
FutureOr<void> _onEditMessageEvent(EditMessageEvent event, Emitter<ChatState> emit) async {
  final current = state;
  if (current is! ChatLoaded) return;

  // 1. Directly mutate in-memory list
  final updated = current.messages.map((m) {
    if (m.id == event.msgId) return m.copyWith(content: event.newContent, isEdited: true);
    return m;
  }).toList();
  emit(ChatLoaded(updated));

  // 2. Update local DB silently
  await _chatLocalDataSource.updateMessageContent(event.msgId, event.newContent);

  // 3. Send to remote
  await _editMessage(EditMessageParams(...));
}
```

### 3. Handle `_updateMessages` — skip stale re-emissions

When the DB stream does fire (for incoming remote messages), `_updateMessages` still needs to work. But we should add a guard so it doesn't re-emit identical data:

```dart
void _updateMessages(List<Message> received, Emitter<ChatState> emit) {
  final current = state;
  if (current is! ChatLoaded) {
    emit(ChatLoaded(received));
    return;
  }

  // Skip if nothing changed (prevents double-build from _notify)
  final currentIds = current.messages.map((m) => m.id).toSet();
  final newIds = received.map((m) => m.id).toSet();
  if (currentIds.length == newIds.length && currentIds.containsAll(newIds)) {
    return; // no structural change, skip
  }

  received.removeWhere((e) => e.deletedfor.contains(_currentUserId) && !e.deletedForEveryone);
  emit(ChatLoaded(received));
}
```

## Summary

| Operation | Before | After |
|-----------|--------|-------|
| Send text/image | Direct emit + stream double-build (Pattern B + A) | Direct emit only (Pattern B) |
| Delete | Stream re-query only (Pattern A) | Direct emit (Pattern B) |
| Reaction | Stream re-query only (Pattern A) | Direct emit (Pattern B) |
| Edit | Stream re-query only (Pattern A) | Direct emit (Pattern B) |
| Receive (remote) | Stream re-query (Pattern A) | Stream re-query (Pattern A, unchanged) |
