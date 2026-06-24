import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:chat_application/features/watch2gether/domain/entity/w2g_room.dart';
import 'package:chat_application/features/watch2gether/domain/entity/w2g_video_item.dart';
import 'package:chat_application/features/watch2gether/presentation/bloc/w2g_bloc.dart';
import 'package:chat_application/init_dependencies.dart';

class VideoControllerService {
  StreamSubscription<W2GState>? _blocSub;
  bool _subscribed = false;
  W2GVideoItem? latestVideoItem;

  VideoPlayerController? _controller;
  String? _originalVideoUrl;
  bool isSyncing = false;
  bool backgroundPlayback = false;

  bool _isLoading = false;
  bool _isReady = false;
  bool _endedNotified = false;
  double? _seekTarget;
  bool _changingVideo = false;

  final _videoChangedCtrl = StreamController<void>.broadcast();
  final _controllerReadyCtrl = StreamController<void>.broadcast();
  final _errorCtrl = StreamController<String>.broadcast();
  Stream<void> get onVideoChanged => _videoChangedCtrl.stream;
  Stream<void> get onControllerReady => _controllerReadyCtrl.stream;
  Stream<String> get onError => _errorCtrl.stream;

  VideoPlayerController? get controller => _controller;
  bool get isLoading => _isLoading;
  bool get isReady => _isReady;

  VoidCallback? onVideoEnded;
  void Function(double position)? onPositionUpdate;

  void startListening() {
    if (_subscribed) return;
    _subscribed = true;
    _blocSub = serviceLocator<W2GBloc>().stream.listen((state) {
      if (state is W2GRoomLoaded) {
        final newItem = state.room.currentVideo;
        if (newItem?.id != null &&
          (newItem!.id != latestVideoItem?.id ||
           newItem.url != latestVideoItem?.url)) {
          latestVideoItem = newItem;
          _onVideoChanged();
        }
      }
    });
    _checkCurrentState();
  }

  void _checkCurrentState() {
    final state = serviceLocator<W2GBloc>().state;
    if (state is W2GRoomLoaded) {
      final item = state.room.currentVideo;
      if (item != null && (item.id != latestVideoItem?.id ||
          item.url != latestVideoItem?.url)) {
        latestVideoItem = item;
        _onVideoChanged();
      }
    }
  }

  Future<void> _onVideoChanged() async {
    if (_changingVideo) return;
    _changingVideo = true;
    try {
      _disposeCurrent();
      _isLoading = true;
      _isReady = false;
      _videoChangedCtrl.add(null);

      if (latestVideoItem?.source == W2GVideoSource.youtube) {
        _isLoading = false;
        return;
      }

      await _createAndInit(latestVideoItem!.url);
    } finally {
      _changingVideo = false;
    }
  }

  Future<void> _createAndInit(String url, {String? originalUrl}) async {
    _originalVideoUrl = originalUrl ?? url;
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
      videoPlayerOptions:
          VideoPlayerOptions(allowBackgroundPlayback: backgroundPlayback),
    );
    try {
      await _controller!.initialize().timeout(const Duration(seconds: 15));
      _isLoading = false;
      _isReady = true;
      _endedNotified = false;
      _controller!.addListener(_onPlayerUpdate);
      _applyInitialPlayback();
      _controllerReadyCtrl.add(null);
    } catch (e) {
      debugPrint('VideoControllerService init error: $e');
      _isLoading = false;
      _errorCtrl.add('Failed to load video: ${e.toString()}');
    }
  }

  void _onPlayerUpdate() {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;

    if (ctrl.value.isCompleted && !_endedNotified) {
      _endedNotified = true;
      onVideoEnded?.call();
      return;
    }
    if (_endedNotified) return;
    if (isSyncing) return;

    final pos = ctrl.value.position.inMilliseconds / 1000.0;

    if (_seekTarget != null) {
      if ((pos - _seekTarget!).abs() < 0.5) {
        _seekTarget = null;
      } else {
        return;
      }
    }

    onPositionUpdate?.call(pos);
  }

  void _applyInitialPlayback() {
    final state = serviceLocator<W2GBloc>().state;
    if (state is W2GRoomLoaded) {
      final pos = state.room.playerState.position;
      final playing = state.room.playerState.isPlaying;
      if (pos > 0) {
        _seekTarget = pos;
        _controller!.seekTo(Duration(milliseconds: (pos * 1000).toInt()));
      }
      if (playing) { _controller!.play(); }
    }
  }

  void seekTo(Duration d) {
    _endedNotified = false;
    _seekTarget = d.inMilliseconds / 1000.0;
    _controller?.seekTo(d);
  }

  void syncFromRoom(W2GRoom room, String? myUserId) {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (myUserId == null) return;

    final player = room.playerState;
    if (player.updatedBy == myUserId) return;

    if (_originalVideoUrl == null) return;
    if (room.currentVideo != null &&
        room.currentVideo!.url != _originalVideoUrl) { return; }

    isSyncing = true;

    final remotePos = player.position;
    final actualPos = ctrl.value.position.inMilliseconds / 1000.0;
    final diff = (actualPos - remotePos).abs();
    if (diff > 2.0) {
      ctrl.seekTo(Duration(milliseconds: (remotePos * 1000).toInt()));
    }

    if (ctrl.value.isPlaying != player.isPlaying) {
      player.isPlaying ? ctrl.play() : ctrl.pause();
    }

    isSyncing = false;
  }

  void dispose() {
    _blocSub?.cancel();
    _subscribed = false;
    latestVideoItem = null;
    _disposeCurrent();
  }

  void _disposeCurrent() {
    _controller?.removeListener(_onPlayerUpdate);
    _controller?.dispose();
    _controller = null;
    _isReady = false;
    _endedNotified = false;
    _seekTarget = null;
    _originalVideoUrl = null;
  }
}
