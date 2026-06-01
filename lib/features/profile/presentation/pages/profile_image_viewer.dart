import 'package:flutter/material.dart';

class ProfileImageViewer extends StatefulWidget {
  final ImageProvider imageProvider;
  final String heroTag;

  const ProfileImageViewer({
    super.key,
    required this.imageProvider,
    required this.heroTag,
  });

  @override
  State<ProfileImageViewer> createState() => _ProfileImageViewerState();
}

class _ProfileImageViewerState extends State<ProfileImageViewer> {
  bool _showUI = true;
  final _transformationController = TransformationController();

  static const _minScale = 1.0;
  static const _maxScale = 5.0;

  void _toggleUI() {
    setState(() => _showUI = !_showUI);
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    final matrix = _transformationController.value;
    final currentScale = matrix.storage[0];

    if (currentScale > _minScale + 0.1) {
      _transformationController.value = Matrix4.identity();
    } else {
      final tapPosition = details.localPosition;
      const newScale = 3.0;
      final x = -tapPosition.dx * (newScale - 1);
      final y = -tapPosition.dy * (newScale - 1);
      _transformationController.value = Matrix4.identity()
        ..translate(x, y)
        ..scale(newScale);
    }
  }

  Future<void> _handleDismiss() async {
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _transformationController.dispose();
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
            )
          : null,
      body: GestureDetector(
        onTap: _toggleUI,
        onDoubleTapDown: _handleDoubleTapDown,
        onVerticalDragStart: _handleVerticalDragStart,
        onVerticalDragUpdate: _handleVerticalDragUpdate,
        onVerticalDragEnd: _handleVerticalDragEnd,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Hero(
            tag: widget.heroTag,
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: _minScale,
              maxScale: _maxScale,
              child: Image(
                image: widget.imageProvider,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
