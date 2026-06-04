import 'dart:math';
import 'package:chat_application/core/theme/app_pallette.dart';
import 'package:flutter/material.dart';

class StatusRingPainter extends CustomPainter {
  final int totalStatuses;
  final int viewedStatuses;
  final Color viewedColor;
  final Color unviewedColor;

  StatusRingPainter({
    required this.totalStatuses,
    required this.viewedStatuses,
    this.viewedColor = AppPallete.divider,
    this.unviewedColor = AppPallete.primaryOrange,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (totalStatuses == 0) return;

    final double ringWidth = 2.5;
    final double gapAngle = 0.06;
    final double anglePerSegment = (2 * pi - gapAngle * totalStatuses) / totalStatuses;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (min(size.width, size.height) - ringWidth) / 2;

    for (int i = 0; i < totalStatuses; i++) {
      final Paint paint = Paint()
        ..color = i < viewedStatuses ? viewedColor : unviewedColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = ringWidth
        ..strokeCap = StrokeCap.round;

      final double startAngle = -pi / 2 + i * (anglePerSegment + gapAngle);
      final double sweepAngle = anglePerSegment;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
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
