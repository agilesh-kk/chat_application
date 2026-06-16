import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/typing_remote_data_source.dart';

class ConvoTypingCubit extends Cubit<Map<String, bool>> {
  final TypingRemoteDataSource _dataSource;

  final Map<String, StreamSubscription<bool>> _subscriptions = {};
  final Map<String, Timer> _throttleTimers = {};
  final Map<String, Timer> _debounceTimers = {};
  final Set<String> _currentlyTyping = {};

  ConvoTypingCubit({required TypingRemoteDataSource dataSource})
      : _dataSource = dataSource,
        super(const {});

  void subscribeToTyping(String convoId, String otherUserId) {
    if (_subscriptions.containsKey(convoId)) return;
    _subscriptions[convoId] = _dataSource.watchTyping(convoId, otherUserId).listen((isTyping) {
      final updated = Map<String, bool>.from(state);
      if (isTyping) {
        updated[convoId] = true;
      } else {
        updated[convoId] = false;
      }
      if (!isClosed) emit(updated);
    });
  }

  void unsubscribeFromTyping(String convoId) {
    _subscriptions[convoId]?.cancel();
    _subscriptions.remove(convoId);
    final updated = Map<String, bool>.from(state);
    updated[convoId] = false;
    if (!isClosed) emit(updated);
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
    _currentlyTyping.clear();
    return super.close();
  }
}
