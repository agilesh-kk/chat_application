import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:flutter/material.dart';

class StatusRingPainter extends CustomPainter {
  final int totalStatuses;
  final int viewedStatuses;

  StatusRingPainter({
    required this.totalStatuses,
    required this.viewedStatuses,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 3.0;
    final adjustedRadius = radius - strokeWidth / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    if (totalStatuses == 0) return;

    final arcAngle = (2 * 3.14159265) / totalStatuses;
    const startAngle = -3.14159265 / 2;

    for (int i = 0; i < totalStatuses; i++) {
      final segmentStart = startAngle + i * arcAngle;
      final segmentEnd = arcAngle * 0.85;

      paint.color = i < viewedStatuses
          ? AppPallete.greyText.withValues(alpha: 0.3)
          : AppPallete.primaryOrange;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: adjustedRadius),
        segmentStart,
        segmentEnd,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant StatusRingPainter oldDelegate) {
    return oldDelegate.totalStatuses != totalStatuses ||
        oldDelegate.viewedStatuses != viewedStatuses;
  }
}
