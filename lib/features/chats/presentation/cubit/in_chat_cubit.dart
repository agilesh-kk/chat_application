import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/typing_remote_data_source.dart';

class InChatCubit extends Cubit<Map<String, bool>> {
  final TypingRemoteDataSource _dataSource;

  final Map<String, StreamSubscription<bool>> _subscriptions = {};

  InChatCubit({required TypingRemoteDataSource dataSource})
      : _dataSource = dataSource,
        super(const {});

  void subscribeToInChat(String convoId, String otherUserId) {
    if (_subscriptions.containsKey(convoId)) return;
    _subscriptions[convoId] = _dataSource.watchInChat(convoId, otherUserId).listen((isInChat) {
      final updated = Map<String, bool>.from(state);
      if (isInChat) {
        updated[convoId] = true;
      } else {
        updated.remove(convoId);
      }
      if (!isClosed) emit(updated);
    });
  }

  void unsubscribeFromInChat(String convoId) {
    _subscriptions[convoId]?.cancel();
    _subscriptions.remove(convoId);
    final updated = Map<String, bool>.from(state);
    updated.remove(convoId);
    if (!isClosed) emit(updated);
  }

  Future<void> setInChat(String convoId, String userId, bool isInChat) async {
    await _dataSource.setInChat(convoId, userId, isInChat);
    if (isInChat) {
      await _dataSource.onDisconnectRemoveInChat(convoId, userId);
    }
  }

  bool isInChat(String convoId) => state[convoId] ?? false;

  @override
  Future<void> close() {
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    _subscriptions.clear();
    return super.close();
  }
}
