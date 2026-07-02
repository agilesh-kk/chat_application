import 'dart:async';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class FullScreenImagePage extends StatefulWidget {
  final Uint8List bytes;
  final String tag;
  final String senderName;
  final DateTime time;
  final bool isMe;
  final VoidCallback? onDelete;

  const FullScreenImagePage({
    super.key,
    required this.bytes,
    required this.tag,
    required this.senderName,
    required this.time,
    this.isMe = false,
    this.onDelete,
  });

  @override
  State<FullScreenImagePage> createState() => _FullScreenImagePageState();
}

class _FullScreenImagePageState extends State<FullScreenImagePage>
    with SingleTickerProviderStateMixin {
  bool _showUI = true;
  final _transformationController = TransformationController();
  final _focusNode = FocusNode();
  Timer? _autoHideTimer;

  double _dragOffset = 0;
  bool _isDismissing = false;
  bool _dragActive = false;
  Offset? _dragStartPos;
  late AnimationController _dismissAnimController;

  static const _minScale = 1.0;
  static const _maxScale = 5.0;

  @override
  void initState() {
    super.initState();
    _hideSystemUI();
    _focusNode.requestFocus();
    _dismissAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _dismissAnimController.addListener(_onDismissProgress);
    _dismissAnimController.addStatusListener(_onDismissStatus);
    _startAutoHideTimer();
  }

  void _onDismissProgress() {
    if (_isDismissing) setState(() {});
  }

  void _onDismissStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _isDismissing) {
      _handleDismiss();
    }
  }

  void _startAutoHideTimer() {
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _showUI) setState(() => _showUI = false);
    });
  }

  void _hideSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  void _showSystemUI() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  void _toggleUI() {
    setState(() {
      _showUI = !_showUI;
    });
    if (_showUI) _startAutoHideTimer();
  }

  Future<void> _handleDismiss() async {
    _dismissAnimController.removeListener(_onDismissProgress);
    _dismissAnimController.removeStatusListener(_onDismissStatus);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (mounted) Navigator.of(context).pop();
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    final matrix = _transformationController.value;
    final currentScale = matrix.getMaxScaleOnAxis();

    if (currentScale > _minScale + 0.1) {
      _transformationController.value = Matrix4.identity();
    } else {
      final tapPosition = details.localPosition;
      final newScale = 3.0;
      final x = -tapPosition.dx * (newScale - 1);
      final y = -tapPosition.dy * (newScale - 1);
      _transformationController.value = Matrix4.identity()
        ..translate(x, y)
        ..scale(newScale);
    }
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_isDismissing) return;
    if (_transformationController.value.getMaxScaleOnAxis() > 1.05) return;
    _dragStartPos = event.position;
    _dragActive = false;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_isDismissing) return;
    if (_dragStartPos == null) return;
    if (_transformationController.value.getMaxScaleOnAxis() > 1.05) {
      _dragStartPos = null;
      return;
    }

    final dy = event.position.dy - _dragStartPos!.dy;

    if (!_dragActive && dy.abs() > 10) {
      _dragActive = true;
    }

    if (_dragActive) {
      setState(() {
        _dragOffset = dy;
        if (_dragOffset < 0) _dragOffset *= 0.3;
      });
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (_isDismissing) return;
    _dragStartPos = null;
    if (!_dragActive) return;
    _dragActive = false;

    if (_dragOffset > 150) {
      _isDismissing = true;
      _dismissAnimController.forward();
    } else {
      setState(() => _dragOffset = 0);
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _dragStartPos = null;
    _dragActive = false;
    setState(() => _dragOffset = 0);
  }

  double get _dismissProgress =>
      _isDismissing ? _dismissAnimController.value : 0.0;

  double get _displayOffset {
    if (!_isDismissing) return _dragOffset;
    final screenH = MediaQuery.of(context).size.height;
    return lerpDouble(_dragOffset, screenH, _dismissProgress)!;
  }

  double get _displayOpacity {
    final base = _dragOffset == 0
        ? 1.0
        : 1.0 - (_dragOffset.abs() / 400).clamp(0.0, 0.4);
    if (!_isDismissing) return base;
    return base * (1.0 - _dismissProgress);
  }

  double get _displayScale {
    final shrink = _dragOffset == 0
        ? 1.0
        : 1.0 - (_dragOffset.abs() / 600).clamp(0.0, 0.15);
    if (!_isDismissing) return shrink;
    return shrink * (1.0 - _dismissProgress * 0.5);
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _focusNode.dispose();
    _autoHideTimer?.cancel();
    _dismissAnimController.removeListener(_onDismissProgress);
    _dismissAnimController.removeStatusListener(_onDismissStatus);
    _dismissAnimController.dispose();
    _showSystemUI();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: _displayOpacity),
      body: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        removeBottom: true,
        child: Listener(
          onPointerDown: _onPointerDown,
          onPointerMove: _onPointerMove,
          onPointerUp: _onPointerUp,
          onPointerCancel: _onPointerCancel,
          child: KeyboardListener(
            focusNode: _focusNode,
            onKeyEvent: (event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.escape) {
                _handleDismiss();
              }
            },
            child: GestureDetector(
              onTap: _toggleUI,
              onDoubleTapDown: _handleDoubleTapDown,
              behavior: HitTestBehavior.opaque,
              child: Stack(
            children: [
              Center(
                child: Transform.translate(
                  offset: Offset(0, _displayOffset),
                  child: Transform.scale(
                    scale: _displayScale,
                    child: Hero(
                      tag: widget.tag,
                      child: InteractiveViewer(
                        transformationController:
                            _transformationController,
                        minScale: _minScale,
                        maxScale: _maxScale,
                        child: Image.memory(
                          widget.bytes,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              if (_showUI) ...[
                _buildTopBar(),
                _buildBottomBar(),
            ],
            ]
          ),
        ),
        ),
      ),
      ),
    );
  }

  Widget _buildTopBar() {
    final top = MediaQuery.of(context).padding.top;
    final formatted = DateFormat('h:mm a').format(widget.time);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: _showUI ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: EdgeInsets.fromLTRB(4, top + 4, 4, 16),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black87, Colors.transparent],
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: _handleDismiss,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.senderName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      formatted,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                color: const Color(0xFF2A2A2A),
                onSelected: (value) {
                  if (value == 'save') _saveImage();
                  if (value == 'share') _shareImage();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'save',
                    child: ListTile(
                      leading: Icon(Icons.download, color: Colors.white),
                      title: Text('Save to gallery',
                          style: TextStyle(color: Colors.white)),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'share',
                    child: ListTile(
                      leading: Icon(Icons.share, color: Colors.white),
                      title: Text('Share',
                          style: TextStyle(color: Colors.white)),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedOpacity(
        opacity: _showUI ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            4,
            16,
            4,
            MediaQuery.of(context).padding.bottom + 4,
          ),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black87],
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (widget.isMe && widget.onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.white),
                  onPressed: () {
                    widget.onDelete!();
                    _handleDismiss();
                  },
                ),
              IconButton(
                icon: const Icon(Icons.share_outlined,
                    color: Colors.white),
                onPressed: _shareImage,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveImage() {
    // TODO: implement save to gallery
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Save to gallery coming soon'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _shareImage() {
    // TODO: implement share
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Share coming soon'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }
}
