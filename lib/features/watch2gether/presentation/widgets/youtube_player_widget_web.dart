import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/features/watch2gether/domain/entity/w2g_video_item.dart';

class YouTubePlayerWidgetWeb extends StatefulWidget {
  final W2GVideoItem? video;
  final bool isPlaying;
  final double position;
  final void Function(bool isPlaying)? onPlayPause;
  final void Function(double position)? onSeek;
  final void Function(double position)? onPositionUpdate;
  final VoidCallback? onVideoEnded;
  final bool canControl;

  const YouTubePlayerWidgetWeb({
    super.key,
    this.video,
    this.isPlaying = false,
    this.position = 0.0,
    this.onPlayPause,
    this.onSeek,
    this.onPositionUpdate,
    this.onVideoEnded,
    this.canControl = true,
  });

  @override
  State<YouTubePlayerWidgetWeb> createState() => _YouTubePlayerWidgetWebState();
}

class _YouTubePlayerWidgetWebState extends State<YouTubePlayerWidgetWeb> {
  static int _nextId = 0;
  static bool _apiLoaded = false;
  static bool _apiReady = false;
  static final List<_YouTubePlayerWidgetWebState> _pendingPlayers = [];

  late final int _instanceId = _nextId++;
  late final String _playerDivId = 'yt-player-$_instanceId';
  late final String _containerDivId = 'yt-container-$_instanceId';

  bool _playerReady = false;
  bool _isBuffering = true;
  double _position = 0;
  double _duration = 0;
  bool _controlsVisible = false;
  Timer? _hideTimer;
  bool _isHovering = false;
  bool _hasError = false;
  double? _dragPosition;

  String? get _videoId {
    if (widget.video == null) return null;
    return _parseVideoId(widget.video!.url);
  }

  String? _parseVideoId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;
    final host = uri.host.toLowerCase();
    if (host.contains('youtu.be')) {
      final segs = uri.pathSegments;
      if (segs.isNotEmpty) return segs.first;
    }
    if (host.contains('youtube.com')) {
      if (uri.path.contains('/embed/') || uri.path.contains('/shorts/')) {
        final segs = uri.pathSegments;
        if (segs.length >= 2) return segs[1];
      }
      final v = uri.queryParameters['v'];
      if (v != null && v.isNotEmpty) return v;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _registerView();
    _initApi();
    _listenMessages();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startPlayer());
  }

  void _registerView() {
    ui_web.platformViewRegistry.registerViewFactory(_containerDivId, (int viewId) {
      final div = html.DivElement()
        ..id = _containerDivId
        ..style.width = '100%'
        ..style.height = '100%';
      final playerDiv = html.DivElement()
        ..id = _playerDivId
        ..style.width = '100%'
        ..style.height = '100%';
      div.nodes.add(playerDiv);
      return div;
    });
  }

  void _initApi() {
    if (_apiLoaded) return;
    _apiLoaded = true;

    js.context['onYouTubeIframeAPIReady'] = () {
      _apiReady = true;
      for (final p in _pendingPlayers) {
        if (p.mounted) p._createPlayer();
      }
    };

    final script = html.ScriptElement()
      ..src = 'https://www.youtube.com/iframe_api'
      ..async = true;
    html.document.body!.append(script);
  }

  void _listenMessages() {
    html.window.onMessage.listen((event) {
      if (event.origin != html.window.location.origin) return;
      final data = event.data;
      if (data is! js.JsObject) return;
      final type = data['type'];
      if (type == null) return;
      final instanceId = data['instanceId'];
      if (instanceId != _instanceId) return;

      switch (type) {
        case 'ready':
          setState(() {
            _playerReady = true;
            _isBuffering = false;
          });
          _syncFromRemote();
        case 'stateChange':
          _onJsStateChange(data['state']);
        case 'position':
          _position = (data['value'] as num?)?.toDouble() ?? 0;
          widget.onPositionUpdate?.call(_position);
        case 'duration':
          _duration = (data['value'] as num?)?.toDouble() ?? 0;
        case 'ended':
          widget.onVideoEnded?.call();
        case 'error':
          setState(() {
            _isBuffering = false;
            _hasError = true;
          });
      }
    });
  }

  void _onJsStateChange(int? state) {
    if (!mounted) return;
    switch (state) {
      case -1:
      case 3:
        setState(() => _isBuffering = true);
      case 1:
        setState(() => _isBuffering = false);
      case 2:
        setState(() => _isBuffering = false);
    }
  }

  void _startPlayer() {
    _pendingPlayers.add(this);

    final jsCode = '''
(function(){
  var container = document.getElementById('$_playerDivId');
  if (!container) return;

  var tag = document.createElement('script');
  tag.src = 'https://www.youtube.com/iframe_api';
  var first = document.getElementsByTagName('script')[0];
  first.parentNode.insertBefore(tag, first);
})();
''';
    js.context.callMethod('eval', [jsCode]);

    if (_apiReady) _createPlayer();
  }

  void _createPlayer() {
    if (!mounted) return;
    final vid = _videoId ?? '';
    if (vid.isEmpty) return;

    final exists = js.context.callMethod('eval', ['!!document.getElementById("$_playerDivId")']);
    if (exists != true) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _createPlayer();
      });
      return;
    }

    js.context.callMethod('eval', [
      '''
(function(){
  var player = new YT.Player('$_playerDivId', {
    height: '100%',
    width: '100%',
    videoId: '$vid',
    playerVars: {
      controls: 0, autoplay: 1, mute: 1, disablekb: 1, fs: 0,
      modestbranding: 1, rel: 0, iv_load_policy: 3,
      cc_load_policy: 0, playsinline: 1
    },
    events: {
      onReady: function(e) {
        window.postMessage({
          type: 'ready', instanceId: $_instanceId
        }, window.location.origin);
        setInterval(function() {
          if (player && player.getCurrentTime) {
            window.postMessage({
              type: 'position', instanceId: $_instanceId,
              value: player.getCurrentTime()
            }, window.location.origin);
          }
        }, 1000);
      },
      onStateChange: function(e) {
        window.postMessage({
          type: 'stateChange', instanceId: $_instanceId,
          state: e.data
        }, window.location.origin);
        if (e.data === 0) {
          window.postMessage({
            type: 'ended', instanceId: $_instanceId
          }, window.location.origin);
        }
        if (e.data === 1 && player && player.getDuration) {
          window.postMessage({
            type: 'duration', instanceId: $_instanceId,
            value: player.getDuration()
          }, window.location.origin);
        }
      },
      onError: function(e) {
        window.postMessage({
          type: 'error', instanceId: $_instanceId, code: e.data
        }, window.location.origin);
      }
    }
  });
  window.ytPlayer_$_instanceId = player;
})();
'''
    ]);
  }

  Future<void> _playVideo() async {
    js.context.callMethod('eval', ['if(window.ytPlayer_$_instanceId) window.ytPlayer_$_instanceId.playVideo();']);
  }

  Future<void> _pauseVideo() async {
    js.context.callMethod('eval', ['if(window.ytPlayer_$_instanceId) window.ytPlayer_$_instanceId.pauseVideo();']);
  }

  Future<void> _seekTo(double seconds) async {
    js.context.callMethod('eval', ['if(window.ytPlayer_$_instanceId) window.ytPlayer_$_instanceId.seekTo($seconds, true);']);
  }

  Future<void> _loadVideo(String videoId) async {
    js.context.callMethod('eval', ['if(window.ytPlayer_$_instanceId) window.ytPlayer_$_instanceId.loadVideoById("$videoId");']);
  }

  void _syncFromRemote() {
    if (!_playerReady) return;
    final remotePos = widget.position;
    final diff = (_position - remotePos).abs();

    if (widget.video != null) {
      if (diff > 2.0) {
        _seekTo(remotePos);
      }
      widget.isPlaying ? _playVideo() : _pauseVideo();
    }
  }

  @override
  void didUpdateWidget(YouTubePlayerWidgetWeb oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldId = _parseVideoId(oldWidget.video?.url ?? '');
    final newId = _videoId;
    if (newId != null && newId != oldId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadVideo(newId);
      });
    }
    if (_playerReady) {
      _syncFromRemote();
    }
  }

  void _onPlayPauseTap() {
    if (!widget.canControl || !_playerReady) return;
    final willPlay = !widget.isPlaying;
    if (willPlay) {
      _playVideo();
    } else {
      _pauseVideo();
    }
    widget.onPlayPause?.call(willPlay);
    _showControls();
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
      if (mounted) setState(() => _controlsVisible = false);
    });
    if (mounted) setState(() {});
  }

  void _enterFullscreen() {
    if (!_playerReady) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _YouTubeFullscreenPageWeb(
          videoId: _videoId ?? '',
          initialPosition: _position,
          isPlaying: widget.isPlaying,
        ),
      ),
    );
  }

  String _formatDuration(double seconds) {
    final d = Duration(milliseconds: (seconds * 1000).toInt());
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    if (h > 0) return '$h:$m:$s';
    return '$m:$s';
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _pendingPlayers.remove(this);
    js.context.callMethod('eval', [
      'if(window.ytPlayer_$_instanceId){window.ytPlayer_$_instanceId.destroy();delete window.ytPlayer_$_instanceId;}'
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.video == null || _videoId == null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: AppPallete.darkBg,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.movie_outlined,
                    size: 64, color: AppPallete.greyText.withValues(alpha: 0.5)),
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

    if (_isBuffering && !_playerReady) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          child: const Center(
              child: CircularProgressIndicator(color: AppPallete.primaryOrange)),
        ),
      );
    }

    final sliderMax = _duration > 0 ? _duration : 1.0;
    final currentSeconds = _position;
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
                HtmlElementView(viewType: _containerDivId),
                if (_isBuffering && _playerReady)
                  const Center(
                    child: CircularProgressIndicator(
                        color: AppPallete.primaryOrange),
                  ),
                if (_hasError)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: const Text(
                        'YouTube playback error',
                        style: TextStyle(color: Colors.redAccent, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
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
                              widget.isPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_filled,
                              size: 56,
                              color: Colors.white,
                            ),
                            onPressed: widget.canControl ? _onPlayPauseTap : null,
                          ),
                        ),
                        if (_playerReady)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
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
                                    _formatDuration(sliderValue),
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
                                              _seekTo(v);
                                              widget.onSeek?.call(v);
                                              _showControls();
                                            }
                                          : null,
                                    ),
                                  ),
                                ),
                                Text(_formatDuration(_duration),
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

class _YouTubeFullscreenPageWeb extends StatefulWidget {
  final String videoId;
  final double initialPosition;
  final bool isPlaying;

  const _YouTubeFullscreenPageWeb({
    required this.videoId,
    required this.initialPosition,
    required this.isPlaying,
  });

  @override
  State<_YouTubeFullscreenPageWeb> createState() =>
      _YouTubeFullscreenPageWebState();
}

class _YouTubeFullscreenPageWebState extends State<_YouTubeFullscreenPageWeb> {
  static int _nextFsId = 0;

  late final int _instanceId = _nextFsId++;
  late final String _playerDivId = 'yt-fs-player-$_instanceId';
  late final String _containerDivId = 'yt-fs-container-$_instanceId';

  bool _playerReady = false;
  double _position = 0;
  double _duration = 0;
  bool _controlsVisible = true;
  Timer? _hideTimer;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _registerView();
    _listenMessages();
    WidgetsBinding.instance.addPostFrameCallback((_) => _createPlayer());
  }

  void _registerView() {
    ui_web.platformViewRegistry.registerViewFactory(_containerDivId, (int viewId) {
      final div = html.DivElement()
        ..id = _containerDivId
        ..style.width = '100%'
        ..style.height = '100%';
      final playerDiv = html.DivElement()
        ..id = _playerDivId
        ..style.width = '100%'
        ..style.height = '100%';
      div.nodes.add(playerDiv);
      return div;
    });
  }

  void _listenMessages() {
    html.window.onMessage.listen((event) {
      if (event.origin != html.window.location.origin) return;
      final data = event.data;
      if (data is! js.JsObject) return;
      if (data['instanceId'] != _instanceId) return;

      switch (data['type'] as String?) {
        case 'ready':
          if (!_disposed && mounted) setState(() => _playerReady = true);
        case 'stateChange':
          final state = (data['state'] as num?)?.toInt();
          if (!_disposed && mounted) {
            if (state == 1) setState(() {});
            if (state == 2) setState(() {});
          }
        case 'position':
          _position = (data['value'] as num?)?.toDouble() ?? 0;
        case 'duration':
          _duration = (data['value'] as num?)?.toDouble() ?? 0;
      }
    });
  }

  void _createPlayer() {
    if (widget.videoId.isEmpty) return;
    final vid = widget.videoId;

    js.context.callMethod('eval', [
      '''
(function(){
  var player = new YT.Player('$_playerDivId', {
    height: '100%',
    width: '100%',
    videoId: '$vid',
    playerVars: {
      controls: 0, autoplay: ${widget.isPlaying ? 1 : 0}, disablekb: 1, fs: 0,
      modestbranding: 1, rel: 0, iv_load_policy: 3,
      cc_load_policy: 0, playsinline: 1
    },
    events: {
      onReady: function(e) {
        window.postMessage({type: 'ready', instanceId: $_instanceId}, window.location.origin);
        if(${widget.initialPosition > 0}) player.seekTo(${widget.initialPosition}, true);
        setInterval(function() {
          if(player && player.getCurrentTime) {
            window.postMessage({type: 'position', instanceId: $_instanceId, value: player.getCurrentTime()}, window.location.origin);
          }
        }, 1000);
      },
      onStateChange: function(e) {
        window.postMessage({type: 'stateChange', instanceId: $_instanceId, state: e.data}, window.location.origin);
      }
    }
  });
  window.ytFsPlayer_$_instanceId = player;
})();
'''
    ]);
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
    if (mounted) Navigator.pop(context);
  }

  void _onPlayPauseTap() {
    if (!_playerReady) return;
    js.context.callMethod('eval', [
      'if(window.ytFsPlayer_$_instanceId){var p=window.ytFsPlayer_$_instanceId;p.getPlayerState()==1?p.pauseVideo():p.playVideo();}'
    ]);
    _showControls();
  }

  String _formatDuration(double seconds) {
    final d = Duration(milliseconds: (seconds * 1000).toInt());
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    if (h > 0) return '$h:$m:$s';
    return '$m:$s';
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _disposed = true;
    js.context.callMethod('eval', [
      'if(window.ytFsPlayer_$_instanceId){window.ytFsPlayer_$_instanceId.destroy();delete window.ytFsPlayer_$_instanceId;}'
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sliderMax = _duration > 0 ? _duration : 1.0;
    final currentSeconds = _position;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            HtmlElementView(viewType: _containerDivId),
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
                        icon: const Icon(
                          Icons.play_circle_filled,
                          size: 64,
                          color: Colors.white,
                        ),
                        onPressed: _onPlayPauseTap,
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
                            Text(_formatDuration(currentSeconds),
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
                                  overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 14),
                                  activeTrackColor: AppPallete.primaryOrange,
                                  inactiveTrackColor: Colors.white24,
                                  thumbColor: AppPallete.primaryOrange,
                                  overlayColor: AppPallete.primaryOrange
                                      .withValues(alpha: 0.2),
                                ),
                                child: Slider(
                                  value: currentSeconds.clamp(0.0, sliderMax),
                                  min: 0,
                                  max: sliderMax,
                                  onChanged: (v) => _showControls(),
                                  onChangeEnd: (v) {
                                    js.context.callMethod('eval', [
                                      'if(window.ytFsPlayer_$_instanceId)window.ytFsPlayer_$_instanceId.seekTo($v,true);'
                                    ]);
                                    _showControls();
                                  },
                                ),
                              ),
                            ),
                            Text(_formatDuration(_duration),
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
