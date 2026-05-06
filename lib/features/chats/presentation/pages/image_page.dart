import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FullScreenImagePage extends StatefulWidget {
  final Uint8List bytes;
  final String tag;

  const FullScreenImagePage({
    super.key,
    required this.bytes,
    required this.tag,
  });

  @override
  State<FullScreenImagePage> createState() => _FullScreenImagePageState();
}

class _FullScreenImagePageState extends State<FullScreenImagePage> {
  bool _showUI = true;
  final _transformationController = TransformationController();
  final _focusNode = FocusNode();

  static const _minScale = 1.0;
  static const _maxScale = 5.0;

  @override
  void initState() {
    super.initState();
    _hideSystemUI();
    _focusNode.requestFocus();
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
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    final matrix = _transformationController.value;
    final currentScale = matrix.storage[0];

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

  Future<void> _handleDismiss() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _focusNode.dispose();
    _showSystemUI();
    super.dispose();
  }

  double _dragStartY = 0;
  double _dragAccumulated = 0;

  void _handleVerticalDragStart(DragStartDetails details) {
    _dragStartY = details.globalPosition.dy;
    _dragAccumulated = 0;
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    _dragAccumulated = details.globalPosition.dy - _dragStartY;
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity > 500 || _dragAccumulated > 150) {
      _handleDismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: _showUI
          ? AppBar(
              backgroundColor: Colors.black.withValues(alpha: 0.7),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: _handleDismiss,
              ),
              title: const Text(
                "Image",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            )
          : null,
      body: KeyboardListener(
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
          onVerticalDragStart: _handleVerticalDragStart,
          onVerticalDragUpdate: _handleVerticalDragUpdate,
          onVerticalDragEnd: _handleVerticalDragEnd,
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: Hero(
              tag: widget.tag,
              child: InteractiveViewer(
                transformationController: _transformationController,
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
    );
  }
}
