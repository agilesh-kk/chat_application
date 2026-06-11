import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/typing_remote_data_source.dart';

class ConvoTypingCubit extends Cubit<Map<String, bool>> {
  final TypingRemoteDataSource _dataSource;

  final Map<String, StreamSubscription<bool>> _subscriptions = {};
  final Map<String, Timer> _throttleTimers = {};
  final Map<String, Timer> _debounceTimers = {};
  final Set<String> _currentlyTyping = {};
  final Map<String, Timer> _receiveTimeouts = {};
  final Map<String, int> _subscriptionRefCounts = {};

  static const _receiveTimeoutDuration = Duration(seconds: 8);

  ConvoTypingCubit({required TypingRemoteDataSource dataSource})
      : _dataSource = dataSource,
        super(const {});

  void subscribeToTyping(String convoId, String otherUserId) {
    if (_subscriptions.containsKey(convoId)) {
      _subscriptionRefCounts[convoId] = (_subscriptionRefCounts[convoId] ?? 1) + 1;
      return;
    }
    _subscriptionRefCounts[convoId] = 1;
    _subscriptions[convoId] = _dataSource.watchTyping(convoId, otherUserId).listen((isTyping) {
      _receiveTimeouts[convoId]?.cancel();
      if (isTyping) {
        _receiveTimeouts[convoId] = Timer(_receiveTimeoutDuration, () {
          final updated = Map<String, bool>.from(state);
          updated.remove(convoId);
          if (!isClosed) emit(updated);
        });
      }
      final updated = Map<String, bool>.from(state);
      if (isTyping) {
        updated[convoId] = true;
      } else {
        updated.remove(convoId);
      }
      if (!isClosed) emit(updated);
    });
  }

  void unsubscribeFromTyping(String convoId) {
    final refCount = _subscriptionRefCounts[convoId] ?? 0;
    if (refCount <= 1) {
      _subscriptions[convoId]?.cancel();
      _subscriptions.remove(convoId);
      _receiveTimeouts[convoId]?.cancel();
      _receiveTimeouts.remove(convoId);
      _throttleTimers[convoId]?.cancel();
      _throttleTimers.remove(convoId);
      _debounceTimers[convoId]?.cancel();
      _debounceTimers.remove(convoId);
      _subscriptionRefCounts.remove(convoId);
      final updated = Map<String, bool>.from(state);
      updated.remove(convoId);
      if (!isClosed) emit(updated);
    } else {
      _subscriptionRefCounts[convoId] = refCount - 1;
    }
  }

  void onTextChanged(String convoId, String userId, String text) {
    if (text.isNotEmpty) {
      if (!_currentlyTyping.contains(convoId)) {
        _currentlyTyping.add(convoId);
        _dataSource.setTyping(convoId, userId, true);
        _dataSource.onDisconnectRemove(convoId, userId);
        _throttleTimers[convoId]?.cancel();
        _throttleTimers[convoId] = Timer.periodic(
          const Duration(seconds: 2),
          (_) => _dataSource.setTyping(convoId, userId, true),
        );
      }
      _debounceTimers[convoId]?.cancel();
      _debounceTimers[convoId] = Timer(const Duration(seconds: 3), () {
        _stopTyping(convoId, userId);
      });
    } else {
      _stopTyping(convoId, userId);
    }
  }

  void stopTyping(String convoId, String userId) {
    _stopTyping(convoId, userId);
  }

  void _stopTyping(String convoId, String userId) {
    _throttleTimers[convoId]?.cancel();
    _throttleTimers.remove(convoId);
    _debounceTimers[convoId]?.cancel();
    _debounceTimers.remove(convoId);
    if (!_currentlyTyping.contains(convoId)) return;
    _currentlyTyping.remove(convoId);
    _dataSource.setTyping(convoId, userId, false);
    _dataSource.cancelOnDisconnect(convoId, userId);
  }

  bool isTyping(String convoId) => state[convoId] ?? false;

  @override
  Future<void> close() {
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    _subscriptions.clear();
    for (final t in _throttleTimers.values) {
      t.cancel();
    }
    _throttleTimers.clear();
    for (final t in _debounceTimers.values) {
      t.cancel();
    }
    _debounceTimers.clear();
    for (final t in _receiveTimeouts.values) {
      t.cancel();
    }
    _receiveTimeouts.clear();
    _currentlyTyping.clear();
    return super.close();
  }
}
