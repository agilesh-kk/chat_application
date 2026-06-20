# Fix: Incoming Messages Not Received

## Root Cause Analysis

### PRIMARY: Race condition in `FriendsCubit` stream subscription

**File:** `lib/features/chats/presentation/bloc/conversation/conversation_bloc.dart`

`_friendsub` is set up inside `LoadConversationsEvent`'s success callback. `FriendsCubit.loadFriends()` is called in `auth_bloc.dart:114` **before** `emit(AuthSuccess(user))`. If friends data loads from Firestore cache before `_friendsub` subscribes, the initial `FriendsLoaded` emission is **missed** (Cubit.stream is broadcast — no replay). `manageListeners` is never called → operation listeners never start → incoming messages never reach the local DB.

The `_reEvaluateOnline` timer eventually re-emits `FriendsLoaded` after 10s, but that's unreliable.

### SECONDARY: `_opSub` map key collision

**File:** `lib/features/chats/data/repository/chat_repository_impl.dart:19`

Map keyed by `opCollection` (either `"operation_1"` or `"operation_2"`). All friends of the same user share the same value, so each `startOperationListener` call overwrites the previous subscription. Only the last friend's listener survives.

### TERTIARY: `isRecentlyDownloaded` never reset

**File:** `lib/features/chats/data/repository/chat_repository_impl.dart:17`

Global `bool` set to `true` after download, never reset. All subsequent listeners skip their first snapshot, missing existing operations for new friends.

---

## Fixes Applied So Far

### Fix 1 (chat_repository_impl.dart): Changed `_opSub` key to `convoId`

- `startOperationListener`: `_opSub[convoId]?.cancel()` / `_opSub[convoId] = stream.listen(...)`
- `stopOperationListenerForReceiver`: `convoId` key instead of `opCollection`

### Fix 2 (chat_repository_impl.dart): `Set<String> _recentlyDownloadedConvos`

Replaced `bool isRecentlyDownloaded` with `Set<String> _recentlyDownloadedConvos`. Added after download, used for `skipFirst`, removed on first received operation. This is per-conversation instead of global.

---

## Fixes Still Needed

### Fix A (conversation_bloc.dart) — PRIMARY: Handle initial friends state immediately

Extract friend-processing logic into `_onFriendsLoaded(FriendsLoaded d)`, call it from both the stream listener AND immediately after subscription if state is already loaded.

### Fix D (chat_repository_impl.dart) — CORRECTION: Use `receiverId` not `userId` in `updateConvo`

Line 227 currently has `userId` (wrong), should be `receiverId` (equivalent to original `opData['senderId']`).

---

## Detailed Changes

### Fix A: conversation_bloc.dart

Replace lines 109-177 (the `_friendsub` setup + listener) with:

```dart
_friendsub?.cancel();

_friendsub = friendsCubit.stream.listen(
  (d) async {
    if (d is! FriendsLoaded) return;
    await _onFriendsLoaded(d);
  },
);

// Process initial friends state immediately if already loaded
if (friendsCubit.state is FriendsLoaded) {
  _onFriendsLoaded(friendsCubit.state as FriendsLoaded);
}
```

Add this method to the class (extracted from the stream listener body):

```dart
Future<void> _onFriendsLoaded(FriendsLoaded d) async {
  final currentFriendIds = d.friends.keys.toSet();

  final removedIds = _prevFriendIds.difference(currentFriendIds);
  for (final removedId in removedIds) {
    await chatRepositoryImpl.stopOperationListenerForReceiver(userId!, removedId);
    _activeListenerFriends.remove(removedId);
    final convoId = chatRepositoryImpl.generateConversationId(userId!, removedId);
    await chatRepositoryImpl.updateConversationFriendStatus(convoId, false);
    await chatRepositoryImpl.markConversationNotFriend(userId!, removedId);
  }

  final addedIds = currentFriendIds.difference(_prevFriendIds);
  for (final addedId in addedIds) {
    if (!_activeListenerFriends.contains(addedId)) {
      chatRepositoryImpl.startOperationListener(userId: userId!, receiverId: addedId);
      _activeListenerFriends.add(addedId);
    }
    final localConvoId = await chatRepositoryImpl.getConvoIdByReceiverId(addedId);
    if (localConvoId != null) {
      await chatRepositoryImpl.updateConversationFriendStatus(localConvoId, true);
      await chatRepositoryImpl.restoreFriendConversation(userId!, addedId);
    }
  }

  final allConvos = await chatRepositoryImpl.queryAllLocalConversations();
  for (final convo in allConvos) {
    final isInFriends = currentFriendIds.contains(convo.receiverId);
    if (isInFriends != convo.isFriend) {
      await chatRepositoryImpl.updateConversationFriendStatus(convo.convoId, isInFriends);
    }
  }

  _prevFriendIds
    ..clear()
    ..addAll(currentFriendIds);

  manageListeners(d.friends.values.toList());

  final loadedState = state;
  if (loadedState is! ConversationLoaded) return;

  final List<Conversation> updated = <Conversation>[];
  for (final c in loadedState.conversations) {
    updated.add(
      Conversation(
        convoId: c.convoId,
        receiverId: c.receiverId,
        lastMessage: c.lastMessage,
        lastupdateTime: c.lastupdateTime,
        profilepicLink: d.friends[c.receiverId]?.profilePic ?? "loading",
        receiverName: d.friends[c.receiverId]?.name ?? "loading",
        unread: c.unread,
        lastSender: c.lastSender,
        receiverIsOnline: d.friends[c.receiverId]?.isEffectivelyOnline ?? false,
        isFriend: c.isFriend,
      ),
    );
  }
  _enrichWithDrafts(updated).then((withDrafts) {
    add(_ConversationUpdated(withDrafts));
  });
}
```

### Fix D: chat_repository_impl.dart line 227

```dart
// Change from:
await chatLocalDataSource.updateConvo(convoId, msgId, content, opData['createdAt'], userId, opData['senderId']);
// Change to:
await chatLocalDataSource.updateConvo(convoId, msgId, content, opData['createdAt'], receiverId, opData['senderId']);
```

---

## Verification

After applying all fixes, messages sent by friend B should appear in real-time in user A's chat UI and conversation list.
