import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:chat_application/features/watch2gether/domain/entity/w2g_video_item.dart';
import 'package:chat_application/features/watch2gether/presentation/widgets/youtube_player_widget_web.dart';

class YouTubePlayerWidget extends StatefulWidget {
  final W2GVideoItem? video;
  final bool isPlaying;
  final double position;
  final void Function(bool isPlaying)? onPlayPause;
  final void Function(double position)? onSeek;
  final void Function(double position)? onPositionUpdate;
  final VoidCallback? onVideoEnded;
  final bool canControl;

  const YouTubePlayerWidget({
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
  State<YouTubePlayerWidget> createState() => _YouTubePlayerWidgetState();
}

class _YouTubePlayerWidgetState extends State<YouTubePlayerWidget> {
  WebViewController? _webController;
  bool _isReady = false;
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
    if (kIsWeb) return;
    _initWebView();
  }

  @override
  void didUpdateWidget(YouTubePlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (kIsWeb) return;
    if (_isReady) {
      final oldId = _parseVideoId(oldWidget.video?.url ?? '');
      final newId = _videoId;
      if (newId != null && newId != oldId) {
        _loadVideo(newId);
      }
      _syncFromRemote();
    }
  }

  void _initWebView() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('PlayerReady',
          onMessageReceived: (_) => _onPlayerReady())
      ..addJavaScriptChannel('StateChange',
          onMessageReceived: (msg) => _onStateChange(int.tryParse(msg.message) ?? -1))
      ..addJavaScriptChannel('Position',
          onMessageReceived: (msg) {
            _position = double.tryParse(msg.message) ?? 0;
            widget.onPositionUpdate?.call(_position);
          })
      ..addJavaScriptChannel('Duration',
          onMessageReceived: (msg) {
            _duration = double.tryParse(msg.message) ?? 0;
          })
      ..addJavaScriptChannel('Ended',
          onMessageReceived: (_) => widget.onVideoEnded?.call())
      ..loadHtmlString(_buildHtml());

    _webController = controller;
  }

  String _buildHtml() {
    final vid = _videoId ?? '';
    return '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
<style>
*{margin:0;padding:0;}
html,body{width:100%;height:100%;background:#000;overflow:hidden;}
#player{width:100%;height:100%;pointer-events:none;}
</style>
</head>
<body>
<div id="player"></div>
<script>
var player;
var tag=document.createElement('script');
tag.src="https://www.youtube.com/iframe_api";
var first=document.getElementsByTagName('script')[0];
first.parentNode.insertBefore(tag,first);

function onYouTubeIframeAPIReady(){
  player=new YT.Player('player',{
    height:'100%',
    width:'100%',
    videoId:'$vid',
    playerVars:{
      'controls':0,
      'autoplay':0,
      'disablekb':1,
      'fs':0,
      'modestbranding':1,
      'rel':0,
      'iv_load_policy':3,
      'cc_load_policy':0,
      'playsinline':1
    },
    events:{
      'onReady':onPlayerReady,
      'onStateChange':onPlayerStateChange,
      'onError':onPlayerError
    }
  });
}

function onPlayerReady(e){
  PlayerReady.postMessage('ready');
  Duration.postMessage(player.getDuration().toString());
  setInterval(function(){
    if(player&&player.getCurrentTime)Position.postMessage(player.getCurrentTime().toString());
  },1000);
}

function onPlayerStateChange(e){
  StateChange.postMessage(e.data.toString());
  if(e.data===0)Ended.postMessage('ended');
  if(e.data===1&&player.getDuration)Duration.postMessage(player.getDuration().toString());
}

function onPlayerError(e){
  StateChange.postMessage('-2');
}

function playVideo(){if(player)player.playVideo();}
function pauseVideo(){if(player)player.pauseVideo();}
function seekTo(s){if(player)player.seekTo(s,true);}
function loadVideo(id){if(player)player.loadVideoById(id);}
function mute(){if(player)player.mute();}
function unmute(){if(player)player.unMute();}
</script>
</body>
</html>
''';
  }

  void _onPlayerReady() {
    if (!mounted) return;
    setState(() {
      _isReady = true;
      _isBuffering = false;
      _hasError = false;
    });
    _syncFromRemote();
  }

  void _onStateChange(int state) {
    if (!mounted) return;
    switch (state) {
      case -1:
      case 3:
        setState(() => _isBuffering = true);
        break;
      case 1:
        setState(() {
          _isBuffering = false;
          _hasError = false;
        });
        break;
      case 2:
        setState(() => _isBuffering = false);
        break;
      case -2:
        setState(() {
          _isBuffering = false;
          _hasError = true;
        });
        break;
    }
  }

  Future<void> _playVideo() async {
    await _webController?.runJavaScript('playVideo()');
  }

  Future<void> _pauseVideo() async {
    await _webController?.runJavaScript('pauseVideo()');
  }

  Future<void> _seekTo(double seconds) async {
    await _webController?.runJavaScript('seekTo($seconds)');
  }

  Future<void> _loadVideo(String videoId) async {
    await _webController?.runJavaScript('loadVideo("$videoId")');
  }

  void _syncFromRemote() {
    if (!_isReady) return;
    final remotePlaying = widget.isPlaying;
    final remotePos = widget.position;
    final diff = (_position - remotePos).abs();

    if (widget.video != null) {
      if (diff > 2.0) {
        _seekTo(remotePos);
      }
      remotePlaying ? _playVideo() : _pauseVideo();
    }
  }

  void _onPlayPauseTap() {
    if (!widget.canControl || !_isReady) return;
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
    if (!_isReady) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _YouTubeFullscreenPage(
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return YouTubePlayerWidgetWeb(
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

    if (_isBuffering && !_isReady) {
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
                if (_webController != null)
                  WebViewWidget(controller: _webController!)
                else
                  const Center(
                      child: CircularProgressIndicator(
                          color: AppPallete.primaryOrange)),
                if (_isBuffering && _isReady)
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
                        if (_isReady)
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

class _YouTubeFullscreenPage extends StatefulWidget {
  final String videoId;
  final double initialPosition;
  final bool isPlaying;

  const _YouTubeFullscreenPage({
    required this.videoId,
    required this.initialPosition,
    required this.isPlaying,
  });

  @override
  State<_YouTubeFullscreenPage> createState() => _YouTubeFullscreenPageState();
}

class _YouTubeFullscreenPageState extends State<_YouTubeFullscreenPage> {
  WebViewController? _webController;
  bool _isReady = false;
  bool _isPlaying = false;
  double _position = 0;
  double _duration = 0;
  bool _controlsVisible = true;
  Timer? _hideTimer;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _isPlaying = widget.isPlaying;
    _initWebView();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _showControls();
  }

  void _initWebView() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('PlayerReady',
          onMessageReceived: (_) => _onPlayerReady())
      ..addJavaScriptChannel('StateChange',
          onMessageReceived: (msg) {
            final state = int.tryParse(msg.message) ?? -1;
            if (!_disposed && mounted) {
              if (state == 1) setState(() => _isPlaying = true);
              if (state == 2) setState(() => _isPlaying = false);
              if (state == 3) setState(() {});
            }
          })
      ..addJavaScriptChannel('Position',
          onMessageReceived: (msg) {
            _position = double.tryParse(msg.message) ?? 0;
          })
      ..addJavaScriptChannel('Duration',
          onMessageReceived: (msg) {
            _duration = double.tryParse(msg.message) ?? 0;
          })
      ..addJavaScriptChannel('Ended',
          onMessageReceived: (_) {})
      ..loadHtmlString(_buildHtml());

    _webController = controller;
  }

  String _buildHtml() {
    final vid = widget.videoId;
    return '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
<style>
*{margin:0;padding:0;}
html,body{width:100%;height:100%;background:#000;overflow:hidden;}
#player{width:100%;height:100%;pointer-events:none;}
</style>
</head>
<body>
<div id="player"></div>
<script>
var player;
var tag=document.createElement('script');
tag.src="https://www.youtube.com/iframe_api";
var first=document.getElementsByTagName('script')[0];
first.parentNode.insertBefore(tag,first);

function onYouTubeIframeAPIReady(){
  player=new YT.Player('player',{
    height:'100%',
    width:'100%',
    videoId:'$vid',
    playerVars:{
      'controls':0,
      'autoplay':${widget.isPlaying ? 1 : 0},
      'disablekb':1,
      'fs':0,
      'modestbranding':1,
      'rel':0,
      'iv_load_policy':3,
      'cc_load_policy':0,
      'playsinline':1
    },
    events:{
      'onReady':onPlayerReady,
      'onStateChange':onPlayerStateChange
    }
  });
}

function onPlayerReady(e){
  PlayerReady.postMessage('ready');
  Duration.postMessage(player.getDuration().toString());
  if(${widget.initialPosition > 0}) player.seekTo(${widget.initialPosition},true);
  setInterval(function(){
    if(player&&player.getCurrentTime)Position.postMessage(player.getCurrentTime().toString());
  },1000);
}

function onPlayerStateChange(e){
  StateChange.postMessage(e.data.toString());
  if(e.data===0)Ended.postMessage('ended');
}
</script>
</body>
</html>
''';
  }

  void _onPlayerReady() {
    if (!_disposed && mounted) {
      setState(() => _isReady = true);
    }
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
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    if (mounted) Navigator.pop(context);
  }

  void _onPlayPauseTap() {
    if (!_isReady) return;
    if (_isPlaying) {
      _webController?.runJavaScript('pauseVideo()');
    } else {
      _webController?.runJavaScript('playVideo()');
    }
    setState(() => _isPlaying = !_isPlaying);
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
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
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
            if (_webController != null)
              WebViewWidget(controller: _webController!)
            else
              const Center(
                  child: CircularProgressIndicator(
                      color: AppPallete.primaryOrange)),
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
                                    _webController?.runJavaScript('seekTo($v)');
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
