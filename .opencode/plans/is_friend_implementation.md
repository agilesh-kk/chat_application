# isFriend Implementation Plan

## Overview
Add `isFriend` tracking at SQLite, Firestore, and Bloc layers so conversations with removed friends are hidden from UI but preserved. On re-add, conversations are restored.

---

## 1. Conversation Entity
**File:** `lib/features/chats/domain/entities/conversation.dart`

Add field:
```dart
final bool isFriend;

// In constructor:
this.isFriend = true,
```

---

## 2. ConversationModel
**File:** `lib/features/chats/data/models/conversation_model.dart`

**In `fromJson`:**
```dart
final isFriend = userData["isFriend"] ?? true;
return ConversationModel(
  ...existing fields...,
  isFriend: isFriend,
);
```

**In constructor:** Add `required super.isFriend`

**In `toMap`:**
```dart
userId: {
  ...existing fields...,
  "isFriend": isFriend,
},
```

---

## 3. ChatLocalDataSource (SQLite)
**File:** `lib/features/chats/data/datasources/chat_local_data_sources.dart`

### 3a. Bump DB version
Change `version: 1` → `version: 6`

### 3b. Migration in `onUpgrade`
Add after existing migrations:
```dart
if (oldVersion < 6) {
  try {
    await db.execute(
      'ALTER TABLE conversations ADD COLUMN isFriend INTEGER DEFAULT 1'
    );
  } catch (_) {}
}
```

### 3c. Update CREATE TABLE in `_createTables` & `convoUpgrade`
Add `isFriend INTEGER DEFAULT 1` to the `conversations` table schema.

### 3d. Update `_dbToConversation`
```dart
final isFriend = (row['isFriend'] ?? 1) == 1;
return Conversation(
  ...existing,
  isFriend: isFriend,
);
```

### 3e. Update `updateConvo`
On new insert (the `else` branch where `!exist`), add `"isFriend" : 1`.

On update (the `if (exist)` branch), no change needed — `isFriend` is managed separately.

### 3f. Add new method
```dart
Future<void> updateConversationFriendStatus(String convoId, bool isFriend) async {
  if (_db == null || kIsWeb) return;
  await _db!.update(
    'conversations',
    {'isFriend': isFriend ? 1 : 0},
    where: 'convoId = ?',
    whereArgs: [convoId],
  );
  _notifyConvo();
}

Future<List<Conversation>> queryAllConversations() async {
  if (_db == null) return [];
  final rows = await _db!.query('conversations', orderBy: 'lastUpdateTime DESC');
  return rows.map(_dbToConversation).toList();
}

Future<String?> getConvoIdByReceiverId(String receiverId) async {
  if (_db == null) return null;
  final rows = await _db!.query(
    'conversations',
    where: 'receiverId = ?',
    whereArgs: [receiverId],
    limit: 1,
  );
  return rows.isNotEmpty ? rows.first['convoId'] as String? : null;
}
```

Also expose `queryAllConversations` via the interface (add to `ChatLocalDataSource` abstract class).

---

## 4. ChatRemoteDataSources
**File:** `lib/features/chats/data/datasources/chat_remote_data_sources.dart`

### 4a. In `sendMessage` — add `isFriend: true` to per-user sub-maps
In the batch set for conversation (the block starting with `batch.set(convoRef, {`), add to both `userId` and `receiverId` sub-maps:
```dart
userId: {
  ...
  "isFriend": true,
},
receiverId: {
  ...
  "isFriend": true,
},
```

---

## 5. ChatRepository Interface
**File:** `lib/features/chats/domain/repository/chat_repository.dart`

Add:
```dart
Future<void> updateConversationFriendStatus(String convoId, bool isFriend);
Future<void> stopOperationListenerForReceiver(String userId, String receiverId);
Future<String?> getConvoIdByReceiverId(String receiverId);
Future<void> restoreFriendConversation(String userId, String friendId);
Future<void> markConversationNotFriend(String userId, String friendId);
Future<List<Conversation>> queryAllLocalConversations();
```

---

## 6. ChatRepositoryImpl
**File:** `lib/features/chats/data/repository/chat_repository_impl.dart`

### 6a. Store userId
Add field `String? _currentUserId;`. Set it in `startOperationListener`.

### 6b. Implement new methods
```dart
@override
Future<void> updateConversationFriendStatus(String convoId, bool isFriend) async {
  await chatLocalDataSource.updateConversationFriendStatus(convoId, isFriend);
}

@override
Future<void> stopOperationListenerForReceiver(String userId, String receiverId) async {
  final opCollection = _getOtherOpCollection(userId, receiverId);
  await _opSub[opCollection]?.cancel();
  _opSub.remove(opCollection);
}

@override
Future<String?> getConvoIdByReceiverId(String receiverId) async {
  return chatLocalDataSource.getConvoIdByReceiverId(receiverId);
}

@override
Future<void> restoreFriendConversation(String userId, String friendId) async {
  final convoId = generateConversationId(userId, friendId);
  await chatRemoteDataSources.updateConversationFriendStatus(
    convoId: convoId,
    userId: userId,
    friendId: friendId,
    isFriend: true,
  );
}

@override
Future<void> markConversationNotFriend(String userId, String friendId) async {
  final convoId = generateConversationId(userId, friendId);
  await chatRemoteDataSources.updateConversationFriendStatus(
    convoId: convoId,
    userId: userId,
    friendId: friendId,
    isFriend: false,
  );
}

@override
Future<List<Conversation>> queryAllLocalConversations() async {
  return chatLocalDataSource.queryAllConversations();
}
```

### 6c. Update stopOperationListener
Also clear `_currentUserId`.

---

## 7. ChatRemoteDataSources Interface & Impl — Add `updateConversationFriendStatus`

**File:** `lib/features/chats/data/datasources/chat_remote_data_sources.dart`

Add to interface:
```dart
Future<void> updateConversationFriendStatus({
  required String convoId,
  required String userId,
  required String friendId,
  required bool isFriend,
});
```

Implementation:
```dart
@override
Future<void> updateConversationFriendStatus({
  required String convoId,
  required String userId,
  required String friendId,
  required bool isFriend,
}) async {
  try {
    await firestore.collection("Conversations").doc(convoId).update({
      '$userId.isFriend': isFriend,
      '$friendId.isFriend': isFriend,
    });
  } catch (e) {
    // Conversation doc might not exist — that's OK
  }
}
```

---

## 8. FriendsRemoteDataSource — Update `removeFriend`

**File:** `lib/features/friends/data/friends_remote_data_sources.dart`

In `removeFriend`, add to the existing batch:
```dart
final convoId = _generateConvoId(userId, friendId);
final convoRef = firestore.collection('Conversations').doc(convoId);
batch.update(convoRef, {
  '$userId.isFriend': false,
  '$friendId.isFriend': false,
});
```

Add helper:
```dart
String _generateConvoId(String user1, String user2) {
  final sorted = [user1, user2]..sort();
  return "${sorted[0]}_${sorted[1]}";
}
```

Note: This can fail silently if the conversation doc doesn't exist yet. The batch commit will fail on the entire batch if the convo doc doesn't exist. So handle this with a try-catch or check if the doc exists first.

**Better approach:** Use `SetOptions(merge: true)` on the batch update:
```dart
batch.set(convoRef, {
  '$userId.isFriend': false,
  '$friendId.isFriend': false,
}, SetOptions(merge: true));
```

But `FieldValue.arrayRemove` doesn't work with `set`. Let me use a different approach — use `batch.update` but catch errors:

Actually, the simplest approach: keep the original batch for the friends array removal, then do the conversation update in a separate try-catch after the batch commit. Or use a second batch.

**Revised approach:**
```dart
@override
Future<void> removeFriend(String userId, String friendId) async {
  final batch = firestore.batch();
  final userRef = firestore.collection('users').doc(userId);
  final friendRef = firestore.collection('users').doc(friendId);

  batch.update(userRef, {
    'friends': FieldValue.arrayRemove([friendId]),
  });
  batch.update(friendRef, {
    'friends': FieldValue.arrayRemove([userId]),
  });

  await batch.commit();

  // Update conversation friend status
  try {
    final convoId = _generateConvoId(userId, friendId);
    await firestore.collection('Conversations').doc(convoId).update({
      '$userId.isFriend': false,
      '$friendId.isFriend': false,
    });
  } catch (_) {}
}
```

---

## 9. ConversationBloc — Core Logic

**File:** `lib/features/chats/presentation/bloc/conversation/conversation_bloc.dart`

### 9a. Import ChatRepository
Already imported via `chatRepositoryImpl`.

### 9b. Track previous friend IDs
Current `Set<String> friends` tracks active operation listener friend IDs. Rename to `_activeListenerFriends` and add `Set<String> _prevFriendIds = {}`.

### 9c. Update `_friendsub` listener

Replace the listener that calls `manageListeners` with enhanced logic:

```dart
_friendsub = friendsCubit.stream.listen((d) async {
  if (d is! FriendsLoaded) return;

  final currentFriendIds = d.friends.keys.toSet();

  // Detect removed friends
  final removedIds = _prevFriendIds.difference(currentFriendIds);
  for (final removedId in removedIds) {
    // Stop operation listener
    chatRepositoryImpl.stopOperationListenerForReceiver(userId!, removedId);
    _activeListenerFriends.remove(removedId);

    // Update local DB: isFriend = false
    final convoId = chatRepositoryImpl.generateConversationId(userId!, removedId);
    await chatRepositoryImpl.updateConversationFriendStatus(convoId, false);

    // Update Firestore: isFriend = false
    await chatRepositoryImpl.markConversationNotFriend(userId!, removedId);
  }

  // Detect added friends (re-add scenario)
  final addedIds = currentFriendIds.difference(_prevFriendIds);
  for (final addedId in addedIds) {
    // Start operation listener
    if (!_activeListenerFriends.contains(addedId)) {
      chatRepositoryImpl.startOperationListener(userId: userId!, receiverId: addedId);
      _activeListenerFriends.add(addedId);
    }

    // Check if a local conversation exists for this friend
    final localConvoId = await chatRepositoryImpl.getConvoIdByReceiverId(addedId);
    if (localConvoId != null) {
      // Restore: update local DB
      await chatRepositoryImpl.updateConversationFriendStatus(localConvoId, true);

      // Update Firestore
      await chatRepositoryImpl.restoreFriendConversation(userId!, addedId);
    }
  }

  _prevFriendIds = currentFriendIds;

  // Re-enrich existing loaded state
  final loadedState = state;
  if (loadedState is! ConversationLoaded) return;

  // Cross-reference: for each conversation, ensure isFriend matches friend status
  final enriched = <Conversation>[];
  for (final c in loadedState.conversations) {
    enriched.add(Conversation(
      ...existing field mappings...,
      isFriend: c.isFriend, // keep as-is — already filtered
    ));
  }
  add(_ConversationUpdated(enriched));
});
```

### 9d. Update `_ConversationUpdated` handler — filter by isFriend
```dart
on<_ConversationUpdated>((event, emit) {
  final filtered = event.convos.where((c) => c.isFriend).toList();
  emit(ConversationLoaded(conversations: List.from(filtered)));
});
```

### 9e. Update `manageListeners`
Rename `friends` set to `_activeListenerFriends`:
```dart
void manageListeners(List<FriendModel> f) {
  for (final i in f) {
    if (!_activeListenerFriends.contains(i.id)) {
      chatRepositoryImpl.startOperationListener(userId: userId!, receiverId: i.id);
      _activeListenerFriends.add(i.id);
    }
  }
}
```

### 9f. Reinstall cross-reference logic

When `FriendsLoaded` is emitted while `state` is `ConversationLoaded`, cross-reference:
```dart
// After the friends stream listener's existing logic:
// Cross-reference: check all local conversations against current friends
final allLocalConvos = await chatRepositoryImpl.queryAllLocalConversations();
for (final convo in allLocalConvos) {
  final isInFriends = currentFriendIds.contains(convo.receiverId);
  if (isInFriends != convo.isFriend) {
    await chatRepositoryImpl.updateConversationFriendStatus(convo.convoId, isInFriends);
  }
}
```

### 9g. Update close()
```dart
@override
Future<void> close() async {
  _convoSub?.cancel();
  await chatRepositoryImpl.stopOperationListener();
  _friendsub!.cancel();
  _activeListenerFriends.clear();
  _prevFriendIds.clear();
  return super.close();
}
```

---

## 10. Reinstall Flow (detailed)

When a user reinstalls and signs in:
1. `LoadConversationsEvent` fires → returns `left(Failure('user-changed'))`
2. `ConversationBloc` subscribes to `FriendsCubit` stream
3. `FriendsLoaded` fires with current friend list
4. `ConversationDownloadEvent` is added → downloads each friend's messages
5. `updateConvo` inserts conversations with `isFriend: 1` (default)
6. After all downloads, `LoadConversationsEvent` fires again
7. Local DB now has conversations — returns local stream
8. `_friendsub` listener fires → cross-reference runs:
   - For each conversation, if `receiverId` NOT in `currentFriendIds`, set `isFriend = false`
   - For each conversation with `receiverId` in `currentFriendIds`, ensure `isFriend = true`
9. `_ConversationUpdated` handler filters out `isFriend == false` conversations
10. UI shows only active friend conversations

---

## 11. Summary of All File Changes

| # | File | Change |
|---|------|--------|
| 1 | `lib/features/chats/domain/entities/conversation.dart` | Add `isFriend` field |
| 2 | `lib/features/chats/data/models/conversation_model.dart` | Parse `isFriend` in fromJson, add to toMap |
| 3 | `lib/features/chats/data/datasources/chat_local_data_sources.dart` | DB schema + migration + new methods |
| 4 | `lib/features/chats/data/datasources/chat_remote_data_sources.dart` | Add `isFriend: true` to sendMessage convo set |
| 5 | `lib/features/chats/data/datasources/chat_remote_data_sources.dart` | Add `updateConversationFriendStatus` method |
| 6 | `lib/features/chats/domain/repository/chat_repository.dart` | Add 6 new methods to interface |
| 7 | `lib/features/chats/data/repository/chat_repository_impl.dart` | Implement all new methods |
| 8 | `lib/features/friends/data/friends_remote_data_sources.dart` | Add isFriend=false to removeFriend |
| 9 | `lib/features/chats/presentation/bloc/conversation/conversation_bloc.dart` | Detect removed/added friends, cross-reference, filter |
