import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/typing_remote_data_source.dart';

class InChatCubit extends Cubit<Map<String, bool>> {
  final TypingRemoteDataSource _dataSource;

  final Map<String, StreamSubscription<bool>> _subscriptions = {};
  final Map<String, Timer?> _recheckTimers = {};

  InChatCubit({required TypingRemoteDataSource dataSource})
      : _dataSource = dataSource,
        super(const {});

  void subscribeToInChat(String convoId, String otherUserId) {
    if (_subscriptions.containsKey(convoId)) return;
    _subscriptions[convoId] = _dataSource.watchInChat(convoId, otherUserId).listen((isInChat) {
      _applyStatus(convoId, isInChat);
    });

    _recheckTimers[convoId] = Timer.periodic(const Duration(seconds: 10), (_) async {
      if (isClosed) return;
      final data = await _dataSource.getInChat(convoId, otherUserId);
      final isInChat = _evaluateRawData(data);
      _applyStatus(convoId, isInChat);
    });
  }

  void _applyStatus(String convoId, bool isInChat) {
    if (isClosed) return;
    final current = state[convoId] ?? false;
    if (isInChat == current) return;
    final updated = Map<String, bool>.from(state);
    if (isInChat) {
      updated[convoId] = true;
    } else {
      updated.remove(convoId);
    }
    if (!isClosed) emit(updated);
  }

  bool _evaluateRawData(Map<String, dynamic>? data) {
    if (data == null) return false;
    final isInChat = data['isInChat'] as bool? ?? false;
    if (!isInChat) return false;
    final ts = data['timestamp'] ?? data['lastSeen'];
    if (ts == null) return true;
    final tsNum = (ts as num?)?.toInt();
    if (tsNum == null) return true;
    return DateTime.now().millisecondsSinceEpoch - tsNum < 25000;
  }

  void unsubscribeFromInChat(String convoId) {
    _subscriptions[convoId]?.cancel();
    _subscriptions.remove(convoId);
    _recheckTimers[convoId]?.cancel();
    _recheckTimers.remove(convoId);
    final updated = Map<String, bool>.from(state);
    updated.remove(convoId);
    if (!isClosed) emit(updated);
  }

  Future<void> heartbeat(String convoId, String userId) async {
    await _dataSource.setInChat(convoId, userId, true);
    await _dataSource.onDisconnectRemoveInChat(convoId, userId);
  }

  Future<void> setInChat(String convoId, String userId, bool isInChat) async {
    if (isInChat) {
      await _dataSource.setInChat(convoId, userId, true);
      await _dataSource.onDisconnectRemoveInChat(convoId, userId);
    } else {
      await _dataSource.cancelOnDisconnectInChat(convoId, userId);
      await _dataSource.setInChat(convoId, userId, false);
    }
  }

  bool isInChat(String convoId) => state[convoId] ?? false;

  @override
  Future<void> close() {
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    _subscriptions.clear();
    for (final timer in _recheckTimers.values) {
      timer?.cancel();
    }
    _recheckTimers.clear();
    return super.close();
  }
}
