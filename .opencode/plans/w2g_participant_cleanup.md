# W2G: Keep participant profile on background/network disconnect

## Problem

`joinRoom()` calls `onDisconnect().remove()` on the participant's Firebase RTDB node, which removes the participant on **any** connection drop — including app backgrounding, phone lock, or network glitches. The same issue exists in `setUserActiveRoom()`.

The user wants the profile to persist unless: (1) user explicitly leaves, or (2) user terminates the app.

## Changes

### 1. `lib/features/watch2gether/data/datasources/w2g_remote_data_source.dart`

**joinRoom()** (lines 97-99): Remove `onDisconnect().remove()`

```dart
// Before:
await ref.set(participant.toMap());
await ref.onDisconnect().remove();

// After:
await ref.set(participant.toMap());
```

**setUserActiveRoom()** (lines 237-239): Remove `onDisconnect().remove()`

```dart
// Before:
await _userRoomRef(userId).set(roomId);
await _userRoomRef(userId).onDisconnect().remove();

// After:
await _userRoomRef(userId).set(roomId);
```

### 2. `lib/features/watch2gether/presentation/pages/w2g_room_page.dart`

Add lifecycle handler for app termination (around line 108-117):

```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.detached) {
    _bloc.add(W2GLeaveRoom(
      roomId: widget.roomId,
      userId: _currentUserId,
    ));
  }
}
```

This dispatches `W2GLeaveRoom` only when the app is truly terminated (`detached`), NOT when backgrounded (`paused`/`inactive`).

## Behavior summary

| Event | Before | After |
|-------|--------|-------|
| App backgrounded | Participant removed | Participant stays |
| Network glitch | Participant removed | Participant stays |
| User taps "Exit Room" | Participant removed | Participant removed (unchanged) |
| User force-quits app | Participant removed | Participant removed (via `detached` lifecycle) |
| App killed by OS (no lifecycle) | Participant removed | Stale entry remains (acceptable tradeoff) |
