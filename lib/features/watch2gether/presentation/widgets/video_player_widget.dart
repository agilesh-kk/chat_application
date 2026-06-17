import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import 'package:chat_application/features/watch2gether/domain/entity/w2g_video_item.dart';

class _StreamOption {
  final String label;
  final Uri url;
  final bool isVideoOnly;
  const _StreamOption({required this.label, required this.url, this.isVideoOnly = false});
}

class VideoPlayerWidget extends StatefulWidget {
  final W2GVideoItem? video;
  final bool isPlaying;
  final double position;
  final void Function(bool isPlaying)? onPlayPause;
  final void Function(double position)? onSeek;
  final void Function(double position)? onPositionUpdate;
  final VoidCallback? onVideoEnded;
  final String? currentUserId;

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
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  yt.YoutubeExplode? _ytExplode;
  List<_StreamOption> _availableStreams = [];
  _StreamOption? _selectedStream;
  bool _isLocalPlaying = false;
  bool _initialized = false;
  bool _disposed = false;
  bool _isSyncing = false;
  bool _endedNotified = false;
  bool _isLoadingYoutubeUrl = false;
  bool _controlsVisible = false;
  double? _dragPosition;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  @override
  void didUpdateWidget(VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.video?.url != oldWidget.video?.url) {
      _onVideoChanged();
    } else if (_initialized) {
      _syncFromRemote();
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _disposeController();
    _ytExplode?.close();
    super.dispose();
  }

  bool get _isYoutube =>
      widget.video != null && widget.video!.source == W2GVideoSource.youtube;

  void _onVideoChanged() {
    _hideTimer?.cancel();
    _controlsVisible = false;
    _availableStreams = [];
    _selectedStream = null;
    _resetState();
    if (widget.video == null) return;
    _initPlayer();
  }

  void _resetState() {
    _initialized = false;
    _isSyncing = false;
    _endedNotified = false;
    _isLoadingYoutubeUrl = false;
  }

  void _initPlayer() {
    _disposeController();
    _disposed = false;
    if (widget.video == null) return;

    if (_isYoutube) {
      _initYoutubePlayer();
    } else {
      _initDirectPlayer(Uri.parse(widget.video!.url));
    }
  }

  Future<void> _initYoutubePlayer({_StreamOption? preferred}) async {
    _isLoadingYoutubeUrl = true;
    if (mounted) setState(() {});

    _ytExplode ??= yt.YoutubeExplode();

    try {
      final videoId = yt.VideoId.parseVideoId(widget.video!.url);
      if (videoId == null) throw Exception('Invalid YouTube URL');
      final manifest =
          await _ytExplode!.videos.streams.getManifest(videoId);

      final streams = <_StreamOption>[];

      for (final s in manifest.muxed) {
        streams.add(_StreamOption(
          label: _qualityLabel(s.videoQuality),
          url: Uri.parse(s.url.toString()),
        ));
      }

      for (final s in manifest.videoOnly) {
        streams.add(_StreamOption(
          label: '${_qualityLabel(s.videoQuality)} (video only)',
          url: Uri.parse(s.url.toString()),
          isVideoOnly: true,
        ));
      }

      streams.sort((a, b) => _parseHeight(a.label).compareTo(_parseHeight(b.label)));

      _availableStreams = streams;

      final selected = preferred ??
          _availableStreams.firstWhere(
            (s) => s.url == _selectedStream?.url,
            orElse: () => _availableStreams.last,
          );

      _selectedStream = selected;
      _isLoadingYoutubeUrl = false;
      _initDirectPlayer(selected.url);
    } catch (e) {
      debugPrint('YoutubeExplode error: $e');
      _availableStreams = [];
      _selectedStream = null;
      _isLoadingYoutubeUrl = false;
      if (mounted) setState(() {});
    }
  }

  int _parseHeight(String label) {
    final match = RegExp(r'(\d+)p').firstMatch(label);
    if (match != null) return int.parse(match.group(1)!);
    return 0;
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

  void _initDirectPlayer(Uri uri) {
    _controller = VideoPlayerController.networkUrl(uri);
    _controller!.initialize().then((_) {
      if (!mounted || _disposed) return;
      setState(() {});
      _controller!.addListener(_onPlayerUpdate);
      _onControllerReady();
    });
  }

  void _onControllerReady() {
    if (_disposed) return;
    _initialized = true;
    if (widget.position > 0) {
      _controller!.seekTo(
        Duration(milliseconds: (widget.position * 1000).toInt()),
      );
    }
    if (widget.isPlaying) {
      _controller!.play();
      _isLocalPlaying = true;
    }
  }

  void _onPlayerUpdate() {
    if (!mounted || _disposed) return;
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;

    if (_isSyncing) return;

    final pos = ctrl.value.position.inMilliseconds / 1000.0;
    final duration = ctrl.value.duration.inMilliseconds / 1000.0;

    widget.onPositionUpdate?.call(pos);

    if (duration > 0 && (pos - duration).abs() < 1.0 && !_endedNotified) {
      _endedNotified = true;
      widget.onVideoEnded?.call();
    } else if (_endedNotified && duration > 0 && (pos - duration).abs() > 2.0) {
      _endedNotified = false;
    }
  }

  void _syncFromRemote() {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;

    _isSyncing = true;

    final remotePlaying = widget.isPlaying;
    final remotePos = widget.position;

    if (ctrl.value.isPlaying != remotePlaying) {
      remotePlaying ? ctrl.play() : ctrl.pause();
    }

    final diff =
        (ctrl.value.position.inMilliseconds / 1000.0 - remotePos).abs();
    if (diff > 2.0) {
      ctrl.seekTo(Duration(milliseconds: (remotePos * 1000).toInt()));
    }

    _isLocalPlaying = remotePlaying;
    _isSyncing = false;
  }

  void _disposeController() {
    _disposed = true;
    _controller?.removeListener(_onPlayerUpdate);
    _controller?.dispose();
    _controller = null;
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
      if (mounted && !_disposed) {
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

  Future<void> _showQualitySelector() async {
    if (_availableStreams.isEmpty) return;

    final selected = await showModalBottomSheet<_StreamOption>(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Video Quality',
                style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
          ..._availableStreams.map((s) => ListTile(
                leading: Icon(
                  s.url == _selectedStream?.url
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: Colors.white,
                ),
                title: Text(s.label,
                    style: const TextStyle(color: Colors.white)),
                onTap: () => Navigator.pop(ctx, s),
              )),
          const SizedBox(height: 8),
        ],
      ),
    );

    if (selected != null && selected.url != _selectedStream?.url) {
      _selectedStream = selected;
      _initYoutubePlayer(preferred: selected);
    }
  }

  void _enterFullscreen() {
    final ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) return;
    final pos = ctrl.value.position.inMilliseconds / 1000.0;
    final isPlaying = ctrl.value.isPlaying;

    ctrl.pause();
    widget.onPlayPause?.call(false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _FullscreenVideoPage(
          url: _selectedStream?.url ?? Uri.parse(widget.video!.url),
          position: pos,
          isPlaying: isPlaying,
          onExited: (newPos, wasPlaying) {
            widget.onSeek?.call(newPos);
            if (wasPlaying) {
              widget.onPlayPause?.call(true);
            }
          },
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    if (h > 0) {
      return '$h:$m:$s';
    }
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.video == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.movie_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No video selected',
                style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    if (_isLoadingYoutubeUrl) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(child: CircularProgressIndicator()),
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
    final sliderValue = (_dragPosition ?? currentSeconds).clamp(0.0, sliderMax);

    return GestureDetector(
      onTap: _toggleControls,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          child: Stack(
            children: [
              if (isInitialized)
                VideoPlayer(ctrl)
              else
                const Center(child: CircularProgressIndicator()),
              if (_controlsVisible)
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    color: Colors.black38,
                    child: Stack(
                      children: [
                        Center(
                          child: IconButton(
                            icon: Icon(
                              _isLocalPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled,
                              size: 56,
                              color: Colors.white,
                            ),
                            onPressed: _onPlayPauseTap,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_selectedStream != null)
                                GestureDetector(
                                  onTap: _showQualitySelector,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      _selectedStream!.label,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: _enterFullscreen,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Icon(
                                    Icons.fullscreen,
                                    color: Colors.white,
                                    size: 20,
                                  ),
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
                                  _formatDuration(
                                    Duration(
                                        milliseconds:
                                            (sliderValue * 1000).toInt()),
                                  ),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
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
                                          const Color(0xFFFF4444),
                                      inactiveTrackColor:
                                          Colors.white24,
                                      thumbColor: Colors.white,
                                      overlayColor:
                                          Colors.white24,
                                    ),
                                    child: Slider(
                                      value: sliderValue,
                                      min: 0,
                                      max: sliderMax,
                                      onChanged: (v) {
                                        _dragPosition = v;
                                        _showControls();
                                      },
                                      onChangeEnd: (v) {
                                        _dragPosition = null;
                                        final seekMs =
                                            (v * 1000).toInt();
                                        ctrl?.seekTo(
                                            Duration(
                                                milliseconds: seekMs));
                                        widget.onSeek?.call(v);
                                        _showControls();
                                      },
                                    ),
                                  ),
                                ),
                                Text(
                                  _formatDuration(duration),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
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
            ],
          ),
        ),
      ),
    );
  }
}

class _FullscreenVideoPage extends StatefulWidget {
  final Uri url;
  final double position;
  final bool isPlaying;
  final void Function(double position, bool wasPlaying) onExited;

  const _FullscreenVideoPage({
    required this.url,
    required this.position,
    required this.isPlaying,
    required this.onExited,
  });

  @override
  State<_FullscreenVideoPage> createState() => _FullscreenVideoPageState();
}

class _FullscreenVideoPageState extends State<_FullscreenVideoPage> {
  VideoPlayerController? _controller;
  bool _isPlaying = false;
  bool _controlsVisible = true;
  Timer? _hideTimer;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _isPlaying = widget.isPlaying;
    _initPlayer();
  }

  void _initPlayer() {
    _controller = VideoPlayerController.networkUrl(widget.url);
    _controller!.initialize().then((_) {
      if (!mounted || _disposed) return;
      setState(() {});
      if (widget.position > 0) {
        _controller!.seekTo(
          Duration(milliseconds: (widget.position * 1000).toInt()),
        );
      }
      if (_isPlaying) {
        _controller!.play();
      }
      _showControls();
    });
  }

  void _showControls() {
    _controlsVisible = true;
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && !_disposed) {
        setState(() => _controlsVisible = false);
      }
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
    final pos = _controller != null && _controller!.value.isInitialized
        ? _controller!.value.position.inMilliseconds / 1000.0
        : widget.position;
    final wasPlaying = _isPlaying;
    _disposed = true;
    _controller?.dispose();
    widget.onExited(pos, wasPlaying);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _disposed = true;
    _controller?.dispose();
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
    final ctrl = _controller;
    final isInit = ctrl != null && ctrl.value.isInitialized;
    final pos = isInit ? ctrl.value.position : Duration.zero;
    final duration = isInit ? ctrl.value.duration : Duration.zero;
    final sliderMax = duration.inMilliseconds > 0
        ? duration.inMilliseconds / 1000.0
        : 1.0;
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
                  : const CircularProgressIndicator(color: Colors.white),
            ),
            if (_controlsVisible)
              GestureDetector(
                onTap: () {},
                child: Container(
                  color: Colors.black38,
                  child: Stack(
                    children: [
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        left: 8,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
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
                            if (ctrl == null || !ctrl.value.isInitialized) return;
                            setState(() => _isPlaying = !ctrl.value.isPlaying);
                            _isPlaying ? ctrl.play() : ctrl.pause();
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
                              Text(
                                _formatDuration(pos),
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 3,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                    activeTrackColor: const Color(0xFFFF4444),
                                    inactiveTrackColor: Colors.white24,
                                    thumbColor: Colors.white,
                                    overlayColor: Colors.white24,
                                  ),
                                  child: Slider(
                                    value: currentSeconds.clamp(0.0, sliderMax),
                                    min: 0,
                                    max: sliderMax,
                                    onChanged: (v) => _showControls(),
                                    onChangeEnd: (v) {
                                      if (ctrl == null) return;
                                      ctrl.seekTo(Duration(milliseconds: (v * 1000).toInt()));
                                      _showControls();
                                    },
                                  ),
                                ),
                              ),
                              Text(
                                _formatDuration(duration),
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
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
