import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import 'package:chat_application/features/watch2gether/domain/entity/w2g_room.dart';
import 'package:chat_application/features/watch2gether/domain/entity/w2g_video_item.dart';
import 'package:chat_application/features/watch2gether/presentation/bloc/w2g_bloc.dart';
import 'package:chat_application/init_dependencies.dart';

class StreamOption {
  final String label;
  final Uri url;
  const StreamOption({required this.label, required this.url});
}

class VideoControllerService {
  StreamSubscription<W2GState>? _blocSub;
  bool _subscribed = false;
  W2GVideoItem? latestVideoItem;

  yt.YoutubeExplode? _ytExplode;
  List<StreamOption> _availableStreams = [];
  StreamOption? _selectedStream;

  VideoPlayerController? _controller;
  String? _originalVideoUrl;
  bool isSyncing = false;
  bool backgroundPlayback = false;

  bool _isLoading = false;
  bool _isReady = false;
  bool _endedNotified = false;
  double? _seekTarget;

  final _videoChangedCtrl = StreamController<void>.broadcast();
  final _controllerReadyCtrl = StreamController<void>.broadcast();
  Stream<void> get onVideoChanged => _videoChangedCtrl.stream;
  Stream<void> get onControllerReady => _controllerReadyCtrl.stream;

  VideoPlayerController? get controller => _controller;
  bool get isLoading => _isLoading;
  bool get isReady => _isReady;
  List<StreamOption> get availableStreams => _availableStreams;
  StreamOption? get selectedStream => _selectedStream;

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
    _disposeCurrent();
    _isLoading = true;
    _isReady = false;
    _availableStreams = [];
    _selectedStream = null;
    _videoChangedCtrl.add(null);

    if (latestVideoItem!.source == W2GVideoSource.youtube ||
        _isYoutubeUrl(latestVideoItem!.url)) {
      await _resolveYoutube();
    } else {
      await _createAndInit(latestVideoItem!.url);
    }
  }

  Future<void> _resolveYoutube({StreamOption? preferred}) async {
    _ytExplode ??= yt.YoutubeExplode();
    try {
      final videoId = yt.VideoId.parseVideoId(latestVideoItem!.url);
      if (videoId == null) throw Exception('Invalid YouTube URL');
      final manifest = await _ytExplode!.videos.streams.getManifest(videoId);
      _availableStreams = manifest.muxed
          .map((s) => StreamOption(
                label: _qualityLabel(s.videoQuality),
                url: Uri.parse(s.url.toString()),
              ))
          .toList();
      _selectedStream = preferred ?? _availableStreams.last;
      await _createAndInit(_selectedStream!.url.toString(),
          originalUrl: latestVideoItem!.url);
    } catch (e) {
      debugPrint('YoutubeExplode error: $e');
      _availableStreams = [];
      _selectedStream = null;
      _isLoading = false;
    }
  }

  String _qualityLabel(yt.VideoQuality q) {
    if (q == yt.VideoQuality.low144) return '144p';
    if (q == yt.VideoQuality.low240) return '240p';
    if (q == yt.VideoQuality.medium360) return '360p';
    if (q == yt.VideoQuality.medium480) return '480p';
    if (q == yt.VideoQuality.high720) return '720p';
    if (q == yt.VideoQuality.high1080) return '1080p';
    if (q == yt.VideoQuality.high1440) return '1440p';
    if (q == yt.VideoQuality.high2160) return '2160p';
    if (q == yt.VideoQuality.high2880) return '2880p';
    if (q == yt.VideoQuality.high3072) return '3072p';
    if (q == yt.VideoQuality.high4320) return '4320p';
    return 'Auto';
  }

  bool _isYoutubeUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('youtube.com') || lower.contains('youtu.be');
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

  void changeQuality(StreamOption option) {
    if (latestVideoItem != null) _resolveYoutube(preferred: option);
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

  static Future<({String? title, String? thumbnailUrl})?> fetchYouTubeMeta(
      String url) async {
    final lower = url.toLowerCase();
    if (!lower.contains('youtube.com') && !lower.contains('youtu.be')) {
      return null;
    }
    final videoId = yt.VideoId.parseVideoId(url);
    if (videoId == null) return null;
    final client = yt.YoutubeExplode();
    try {
      final video = await client.videos.get(videoId);
      return (
        title: video.title,
        thumbnailUrl: video.thumbnails.mediumResUrl,
      );
    } catch (e) {
      debugPrint('fetchYouTubeMeta error: $e');
      return null;
    } finally {
      client.close();
    }
  }

  void dispose() {
    _blocSub?.cancel();
    _disposeCurrent();
    _ytExplode?.close();
    _ytExplode = null;
  }

  void _disposeCurrent() {
    _controller?.removeListener(_onPlayerUpdate);
    _controller?.dispose();
    _controller = null;
    _isReady = false;
    _endedNotified = false;
    _seekTarget = null;
  }
}
