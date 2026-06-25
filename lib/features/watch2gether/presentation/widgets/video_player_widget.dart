import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/features/watch2gether/data/services/video_controller_service.dart';
import 'package:chat_application/features/watch2gether/domain/entity/w2g_video_item.dart';
import 'package:chat_application/features/watch2gether/presentation/widgets/youtube_player_widget.dart';
import 'package:chat_application/init_dependencies.dart';

class VideoPlayerWidget extends StatefulWidget {
  final W2GVideoItem? video;
  final bool isPlaying;
  final double position;
  final void Function(bool isPlaying)? onPlayPause;
  final void Function(double position)? onSeek;
  final void Function(double position)? onPositionUpdate;
  final VoidCallback? onVideoEnded;
  final String? currentUserId;
  final bool canControl;
  final bool backgroundPlayback;

  const VideoPlayerWidget({
    super.key,
    this.video,
    this.isPlaying = false,
    this.position = 0.0,
    this.onPlayPause,
    this.onSeek,
    this.onPositionUpdate,
    this.onVideoEnded,
    this.currentUserId,
    this.canControl = true,
    this.backgroundPlayback = false,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  final VideoControllerService _videoService =
      serviceLocator<VideoControllerService>();
  VideoPlayerController? get _controller => _videoService.controller;

  StreamSubscription<void>? _videoChangedSub;
  StreamSubscription<void>? _controllerReadySub;

  bool _isLocalPlaying = false;
  bool _controlsVisible = false;
  double? _dragPosition;
  Timer? _hideTimer;
  bool _isHovering = false;

  @override
  void initState() {
    super.initState();
    _videoService.backgroundPlayback = widget.backgroundPlayback;
    _videoService.onVideoEnded = () => widget.onVideoEnded?.call();
    _videoService.onPositionUpdate = (pos) {
      widget.onPositionUpdate?.call(pos);
    };
    _videoService.startListening();

    _videoChangedSub =
        _videoService.onVideoChanged.listen((_) => setState(() {}));
    _controllerReadySub =
        _videoService.onControllerReady.listen((_) => setState(() {}));

    if (_videoService.isReady) setState(() {});
  }

  @override
  void dispose() {
    _videoChangedSub?.cancel();
    _controllerReadySub?.cancel();
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_videoService.isReady) {
      _syncFromRemote();
    }
  }

  void _syncFromRemote() {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;

    _videoService.isSyncing = true;

    final remotePlaying = widget.isPlaying;
    final remotePos = widget.position;
    final actualPos = ctrl.value.position.inMilliseconds / 1000.0;
    final diff = (actualPos - remotePos).abs();

    if (ctrl.value.isPlaying != remotePlaying) {
      remotePlaying ? ctrl.play() : ctrl.pause();
    }

    if (diff > 2.0) {
      ctrl.seekTo(Duration(milliseconds: (remotePos * 1000).toInt()));
    }

    _isLocalPlaying = remotePlaying;
    _videoService.isSyncing = false;
  }

  void _toggleControls() {
    if (_controlsVisible) {
      _hideTimer?.cancel();
      _controlsVisible = false;
      if (mounted) setState(() {});
    } else {
      _showControls();
    }
  }

  void _showControls() {
    _controlsVisible = true;
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _controlsVisible = false);
      }
    });
    if (mounted) setState(() {});
  }

  void _onPlayPauseTap() {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    final willPlay = !ctrl.value.isPlaying;
    willPlay ? ctrl.play() : ctrl.pause();
    _isLocalPlaying = willPlay;
    widget.onPlayPause?.call(willPlay);
    _showControls();
  }

  void _enterFullscreen() {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullscreenVideoPage(controller: ctrl),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    if (h > 0) return '$h:$m:$s';
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.video == null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: AppPallete.darkBg,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.movie_outlined,
                    size: 64,
                    color: AppPallete.greyText.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text('No video selected',
                    style: TextStyle(
                        color: AppPallete.greyText.withValues(alpha: 0.7),
                        fontSize: 16)),
              ],
            ),
          ),
        ),
      );
    }

    if (widget.video?.source == W2GVideoSource.youtube) {
      return YouTubePlayerWidget(
        video: widget.video,
        isPlaying: widget.isPlaying,
        position: widget.position,
        onPlayPause: widget.onPlayPause,
        onSeek: widget.onSeek,
        onPositionUpdate: widget.onPositionUpdate,
        onVideoEnded: widget.onVideoEnded,
        canControl: widget.canControl,
      );
    }

    if (widget.video?.source == W2GVideoSource.direct) {
      // fall through to existing player
    } else if (widget.video != null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: AppPallete.darkBg,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    size: 48, color: AppPallete.greyText.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                const Text('Unsupported video source',
                    style: TextStyle(color: AppPallete.greyText, fontSize: 14)),
              ],
            ),
          ),
        ),
      );
    }

    if (_videoService.isLoading) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(
            child:
                CircularProgressIndicator(color: AppPallete.primaryOrange)),
      );
    }

    final ctrl = _controller;
    final isInitialized = ctrl != null && ctrl.value.isInitialized;
    final pos = isInitialized ? ctrl.value.position : Duration.zero;
    final duration = isInitialized ? ctrl.value.duration : Duration.zero;
    final sliderMax = duration.inMilliseconds > 0
        ? duration.inMilliseconds / 1000.0
        : 1.0;
    final currentSeconds = pos.inMilliseconds / 1000.0;
    final sliderValue =
        (_dragPosition ?? currentSeconds).clamp(0.0, sliderMax);

    return MouseRegion(
      onEnter: (_) {
        _isHovering = true;
        if (mounted) setState(() {});
      },
      onExit: (_) {
        _isHovering = false;
        if (!_controlsVisible && mounted) setState(() {});
      },
      child: GestureDetector(
        onTap: _toggleControls,
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            color: Colors.black,
            child: Stack(
              children: [
                if (isInitialized) VideoPlayer(ctrl)
                else
                  const Center(
                      child: CircularProgressIndicator(
                          color: AppPallete.primaryOrange)),
                AnimatedOpacity(
                  opacity: _controlsVisible || _isHovering ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    color: Colors.black54,
                    child: Stack(
                      children: [
                        Center(
                          child: IconButton(
                            icon: Icon(
                              ctrl?.value.isPlaying ?? _isLocalPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled,
                              size: 56,
                              color: Colors.white,
                            ),
                            onPressed:
                                widget.canControl ? _onPlayPauseTap : null,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: _enterFullscreen,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppPallete.darkTertiary,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(Icons.fullscreen,
                                      color: AppPallete.primaryOrange,
                                      size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.only(
                                left: 12, right: 12, bottom: 4),
                            child: Row(
                              children: [
                                Text(
                                    _formatDuration(Duration(
                                        milliseconds:
                                            (sliderValue * 1000).toInt())),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500)),
                                Expanded(
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 3,
                                      thumbShape:
                                          const RoundSliderThumbShape(
                                              enabledThumbRadius: 6),
                                      overlayShape:
                                          const RoundSliderOverlayShape(
                                              overlayRadius: 14),
                                      activeTrackColor:
                                          AppPallete.primaryOrange,
                                      inactiveTrackColor: Colors.white24,
                                      thumbColor: AppPallete.primaryOrange,
                                      overlayColor:
                                          AppPallete.primaryOrange
                                              .withValues(alpha: 0.2),
                                    ),
                                    child: Slider(
                                      value: sliderValue,
                                      min: 0,
                                      max: sliderMax,
                                      onChanged: widget.canControl
                                          ? (v) {
                                              _dragPosition = v;
                                              _showControls();
                                            }
                                          : null,
                                      onChangeEnd: widget.canControl
                                          ? (v) {
                                              _dragPosition = null;
                                              _videoService.seekTo(Duration(
                                                  milliseconds:
                                                      (v * 1000).toInt()));
                                              widget.onSeek?.call(v);
                                              _showControls();
                                            }
                                          : null,
                                    ),
                                  ),
                                ),
                                Text(_formatDuration(duration),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FullscreenVideoPage extends StatefulWidget {
  final VideoPlayerController controller;

  const _FullscreenVideoPage({required this.controller});

  @override
  State<_FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<_FullscreenVideoPage> {
  bool _isPlaying = false;
  bool _controlsVisible = true;
  Timer? _hideTimer;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _isPlaying = widget.controller.value.isPlaying;
    if (!kIsWeb) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    widget.controller.addListener(_onPlayerUpdate);
    _showControls();
  }

  void _onPlayerUpdate() {
    if (!_disposed && mounted) setState(() {});
  }

  void _showControls() {
    _controlsVisible = true;
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_disposed) setState(() => _controlsVisible = false);
    });
    if (mounted) setState(() {});
  }

  void _toggleControls() {
    if (_controlsVisible) {
      _hideTimer?.cancel();
      _controlsVisible = false;
      if (mounted) setState(() {});
    } else {
      _showControls();
    }
  }

  void _onBackPressed() {
    _hideTimer?.cancel();
    _disposed = true;
    widget.controller.removeListener(_onPlayerUpdate);
    if (!kIsWeb) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _disposed = true;
    widget.controller.removeListener(_onPlayerUpdate);
    if (!kIsWeb) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    if (h > 0) return '$h:$m:$s';
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    final isInit = ctrl.value.isInitialized;
    final pos = isInit ? ctrl.value.position : Duration.zero;
    final duration = isInit ? ctrl.value.duration : Duration.zero;
    final sliderMax =
        duration.inMilliseconds > 0 ? duration.inMilliseconds / 1000.0 : 1.0;
    final currentSeconds = pos.inMilliseconds / 1000.0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            Center(
              child: isInit
                  ? VideoPlayer(ctrl)
                  : const CircularProgressIndicator(
                      color: AppPallete.primaryOrange),
            ),
            AnimatedOpacity(
              opacity: _controlsVisible ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                color: Colors.black54,
                child: Stack(
                  children: [
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 8,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back,
                            color: Colors.white, size: 28),
                        onPressed: _onBackPressed,
                      ),
                    ),
                    Center(
                      child: IconButton(
                        icon: Icon(
                          _isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                          size: 64,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          if (!ctrl.value.isInitialized) return;
                          ctrl.value.isPlaying ? ctrl.pause() : ctrl.play();
                          _isPlaying = ctrl.value.isPlaying;
                          _showControls();
                        },
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: MediaQuery.of(context).padding.bottom + 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Text(_formatDuration(pos),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500)),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3,
                                  thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 6),
                                  overlayShape:
                                      const RoundSliderOverlayShape(
                                          overlayRadius: 14),
                                  activeTrackColor:
                                      AppPallete.primaryOrange,
                                  inactiveTrackColor: Colors.white24,
                                  thumbColor: AppPallete.primaryOrange,
                                  overlayColor: AppPallete.primaryOrange
                                      .withValues(alpha: 0.2),
                                ),
                                child: Slider(
                                  value:
                                      currentSeconds.clamp(0.0, sliderMax),
                                  min: 0,
                                  max: sliderMax,
                                  onChanged: (v) => _showControls(),
                                  onChangeEnd: (v) {
                                    ctrl.seekTo(Duration(
                                        milliseconds:
                                            (v * 1000).toInt()));
                                    _showControls();
                                  },
                                ),
                              ),
                            ),
                            Text(_formatDuration(duration),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
