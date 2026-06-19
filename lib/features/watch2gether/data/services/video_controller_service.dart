import 'package:video_player/video_player.dart';
import 'package:chat_application/features/watch2gether/domain/entity/w2g_room.dart';

class VideoControllerService {
  VideoPlayerController? _controller;
  String? _streamUrl;
  String? _originalVideoUrl;
  bool isSyncing = false;

  VideoPlayerController? get controller => _controller;

  /// Returns the existing controller if it matches [url], otherwise creates a new one.
  /// The caller should await [initialize] on the returned controller.
  /// [originalUrl] is the user-facing video URL (not the stream URL).
  VideoPlayerController getOrCreate(String url, {String? originalUrl, bool backgroundPlayback = false}) {
    if (_controller != null && _streamUrl == url) {
      return _controller!;
    }
    _disposeCurrent();
    _streamUrl = url;
    _originalVideoUrl = originalUrl ?? url;
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(url),
      videoPlayerOptions: VideoPlayerOptions(allowBackgroundPlayback: backgroundPlayback),
    );
    return _controller!;
  }

  void syncFromRoom(W2GRoom room, String? myUserId) {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    if (myUserId == null) return;

    final player = room.playerState;
    if (player.updatedBy == myUserId) return; // self change, ignore

    // Video URL changed ΓÇö handled on re-entry (skip background sync)
    if (_originalVideoUrl == null) return;
    if (room.currentVideo != null && room.currentVideo!.url != _originalVideoUrl) {
      return;
    }

    isSyncing = true;

    // Sync position
    final remotePos = player.position;
    final actualPos = ctrl.value.position.inMilliseconds / 1000.0;
    final diff = (actualPos - remotePos).abs();
    if (diff > 2.0) {
      ctrl.seekTo(Duration(milliseconds: (remotePos * 1000).toInt()));
    }

    // Sync play/pause
    if (ctrl.value.isPlaying != player.isPlaying) {
      player.isPlaying ? ctrl.play() : ctrl.pause();
    }

    isSyncing = false;
  }

  void dispose() {
    _disposeCurrent();
    _streamUrl = null;
    _originalVideoUrl = null;
  }

  void _disposeCurrent() {
    _controller?.dispose();
    _controller = null;
  }
}
