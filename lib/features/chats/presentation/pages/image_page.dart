import 'dart:async';
import 'dart:io';
import 'dart:ui' show lerpDouble;

import 'package:chat_application/features/chats/domain/entities/message.dart';
import 'package:chat_application/features/chats/presentation/helper/cacheservice.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class FullScreenImagePage extends StatefulWidget {
  final List<Message> messages;
  final int initialIndex;
  final CacheService cacheService;
  final String currentUserId;
  final String receiverId;
  final String receiverName;
  const FullScreenImagePage({
    super.key,
    required this.messages,
    required this.initialIndex,
    required this.cacheService,
    required this.currentUserId,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<FullScreenImagePage> createState() => _FullScreenImagePageState();
}

class _FullScreenImagePageState extends State<FullScreenImagePage>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late TransformationController _transformationController;
  late int _currentIndex;

  bool _showUI = true;
  bool _isZoomed = false;
  final _focusNode = FocusNode();
  Timer? _autoHideTimer;

  final Set<int> _activePointers = {};
  double _dragOffset = 0;
  bool _isDismissing = false;
  bool _dragActive = false;
  Offset? _dragStartPos;
  late AnimationController _dismissAnimController;

  final Map<String, Uint8List> _loadedBytes = {};

  static const _minScale = 1.0;
  static const _maxScale = 5.0;

  Message get _currentMessage => widget.messages[_currentIndex];
  String get _currentSenderName =>
      _currentMessage.senderId == widget.currentUserId
          ? 'You'
          : widget.receiverName;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.messages.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
    _transformationController = TransformationController();
    _transformationController.addListener(_onTransformationChanged);
    _hideSystemUI();
    _focusNode.requestFocus();
    _dismissAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _dismissAnimController.addListener(_onDismissProgress);
    _dismissAnimController.addStatusListener(_onDismissStatus);
    _startAutoHideTimer();
    _loadImageForIndex(_currentIndex);
  }

  void _onTransformationChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    final zoomed = scale > 1.05;
    if (zoomed != _isZoomed) {
      setState(() => _isZoomed = zoomed);
    }
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
    setState(() => _showUI = !_showUI);
    if (_showUI) _startAutoHideTimer();
  }

  Future<void> _handleDismiss() async {
    _dismissAnimController.removeListener(_onDismissProgress);
    _dismissAnimController.removeStatusListener(_onDismissStatus);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (mounted) Navigator.of(context).pop();
  }

  void _onPageChanged(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    _transformationController.value = Matrix4.identity();
    _isZoomed = false;
    _loadImageForIndex(index);
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
    _activePointers.add(event.pointer);
    if (_activePointers.length > 1) {
      _dragStartPos = null;
      _dragActive = false;
      _dragOffset = 0;
      return;
    }
    if (_isDismissing) return;
    if (_isZoomed) return;
    _dragStartPos = event.position;
    _dragActive = false;
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_isDismissing) return;
    if (_activePointers.length > 1 || _isZoomed) {
      _dragStartPos = null;
      _dragActive = false;
      _dragOffset = 0;
      return;
    }
    if (_dragStartPos == null) return;

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
    _activePointers.remove(event.pointer);
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
    _activePointers.remove(event.pointer);
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

  Future<void> _loadImageForIndex(int index) async {
    final msg = widget.messages[index];
    if (_loadedBytes.containsKey(msg.id)) return;

    if (!mounted) return;
    setState(() {});

    if (widget.cacheService.cache.containsKey(msg.id)) {
      _loadedBytes[msg.id] = widget.cacheService.cache[msg.id]!;
      if (mounted) setState(() {});
      return;
    }

    if (!kIsWeb && msg.localPath != null) {
      try {
        final bytes = await File(msg.localPath!).readAsBytes();
        widget.cacheService.cache[msg.id] = bytes;
        _loadedBytes[msg.id] = bytes;
        if (mounted) setState(() {});
        return;
      } catch (_) {}
    }

    if (msg.content.isNotEmpty) {
      try {
        await widget.cacheService.getOrDownload(msg.content, msg.id);
        if (widget.cacheService.cache.containsKey(msg.id)) {
          _loadedBytes[msg.id] = widget.cacheService.cache[msg.id]!;
        }
      } catch (_) {}
    }

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformationController.removeListener(_onTransformationChanged);
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
                  _buildGallery(),

                  if (_showUI) ...[
                    _buildTopBar(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGallery() {
    return Transform.translate(
      offset: Offset(0, _displayOffset),
      child: Transform.scale(
        scale: _displayScale,
        child: PageView.builder(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          physics: _isZoomed
              ? const NeverScrollableScrollPhysics()
              : const PageScrollPhysics(),
          itemCount: widget.messages.length,
          itemBuilder: (context, index) {
            final msg = widget.messages[index];
            final bytes = _loadedBytes[msg.id];

            if (bytes == null) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            final isInitialImage = index == widget.initialIndex;

            return Center(
              child: Hero(
                tag: isInitialImage ? msg.id : '${msg.id}_${index}',
                child: InteractiveViewer(
                  transformationController:
                      index == _currentIndex
                          ? _transformationController
                          : TransformationController(),
                  minScale: _minScale,
                  maxScale: _maxScale,
                  child: Image.memory(
                    bytes,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final top = MediaQuery.of(context).padding.top;
    final formatted = DateFormat('h:mm a').format(_currentMessage.createdAt);
    final count = widget.messages.length;
    final label = count > 1
        ?         '${_currentIndex + 1} of $count \u00b7 ${_currentSenderName}'
        : _currentSenderName;

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
                      label,
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

            ],
          ),
        ),
      ),
    );
  }


}
