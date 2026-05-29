import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SwipeToReply extends StatefulWidget {
  final Widget child;
  final VoidCallback? onReply;
  final bool isMe;

  const SwipeToReply({
    super.key,
    required this.child,
    this.onReply,
    required this.isMe,
  });

  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<SwipeToReply>
    with SingleTickerProviderStateMixin {
  double _swipeDistance = 0;
  bool _hapticFired = false;
  late AnimationController _ctrl;
  bool _isAnimating = false;
  double _animStart = 0;
  double _animTarget = 0;

  static const double _maxSwipe = 120;
  static const double _threshold = 80;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _ctrl.addListener(_updateFromAnimation);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_updateFromAnimation);
    _ctrl.dispose();
    super.dispose();
  }

  void _updateFromAnimation() {
    if (!_isAnimating) return;
    final t = _ctrl.value;
    _swipeDistance = _animStart + (_animTarget - _animStart) * t;
    if (t >= 1) {
      _swipeDistance = _animTarget;
      _isAnimating = false;
    }
    setState(() {});
  }

  void _startSwipeAnim(double target) {
    if (target == _swipeDistance) return;
    _animStart = _swipeDistance;
    _animTarget = target;
    _isAnimating = true;
    _ctrl.forward(from: 0.0);
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (widget.onReply == null) return;
    if (_isAnimating) {
      _ctrl.stop();
      _isAnimating = false;
    }
    final prev = _swipeDistance;
    if (widget.isMe) {
      _swipeDistance = (_swipeDistance - details.delta.dx).clamp(0.0, _maxSwipe);
    } else {
      _swipeDistance = (_swipeDistance + details.delta.dx).clamp(0.0, _maxSwipe);
    }

    if (prev < _threshold && _swipeDistance >= _threshold && !_hapticFired) {
      _hapticFired = true;
      HapticFeedback.mediumImpact();
    } else if (_swipeDistance < _threshold) {
      _hapticFired = false;
    }

    setState(() {});
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (widget.onReply == null) return;
    if (_swipeDistance >= _threshold) {
      widget.onReply?.call();
    }
    _hapticFired = false;
    _startSwipeAnim(0.0);
  }

  void _onHorizontalDragCancel() {
    _hapticFired = false;
    _startSwipeAnim(0.0);
  }

  @override
  Widget build(BuildContext context) {
    final dist = _swipeDistance;
    final dx = widget.isMe ? -dist : dist;

    return GestureDetector(
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      onHorizontalDragCancel: _onHorizontalDragCancel,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (dist > 3)
            Positioned.fill(
              child: Align(
                alignment: widget.isMe ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: widget.isMe
                      ? const EdgeInsets.only(right: 8, top: 4, bottom: 4)
                      : const EdgeInsets.only(left: 8, top: 4, bottom: 4),
                  child: Icon(Icons.reply_outlined, color: AppPallete.primaryOrange, size: 22),
                ),
              ),
            ),
          Transform.translate(
            offset: Offset(dx, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}
