import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

// TODO(asset): Replace with actual mascot asset when provided.
// Drawing a simple ghost-like mascot using CustomPainter as a placeholder.
class MascotWidget extends StatelessWidget {
  const MascotWidget({super.key, this.size = 80});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.1,
      child: CustomPaint(painter: _GhostPainter()),
    );
  }
}

class _GhostPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()
      ..color = AppTheme.primaryLight.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    final eyePaint = Paint()
      ..color = AppTheme.primary
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;

    // Ghost body path
    final path = Path();
    final bodyTop = h * 0.1;
    final bodyBottom = h * 0.8;
    final cx = w / 2;

    // Top semicircle
    path.addArc(
      Rect.fromLTWH(w * 0.1, bodyTop, w * 0.8, w * 0.8),
      math.pi,
      math.pi,
    );

    // Sides going down
    path.lineTo(w * 0.9, bodyBottom);

    // Wavy bottom
    final waveCount = 3;
    final waveWidth = (w * 0.8) / waveCount;
    for (int i = 0; i < waveCount; i++) {
      final x1 = w * 0.9 - waveWidth * i;
      final x2 = x1 - waveWidth / 2;
      final x3 = x1 - waveWidth;
      path.cubicTo(
        x1, bodyBottom + h * 0.05,
        x2, bodyBottom - h * 0.05,
        x3, bodyBottom,
      );
    }

    path.lineTo(w * 0.1, bodyTop + w * 0.4); // left side
    path.close();

    canvas.drawPath(path, bodyPaint);

    // Eyes
    final eyeY = bodyTop + w * 0.38;
    final eyeRadius = w * 0.07;
    canvas.drawCircle(Offset(cx - w * 0.14, eyeY), eyeRadius, eyePaint);
    canvas.drawCircle(Offset(cx + w * 0.14, eyeY), eyeRadius, eyePaint);

    // White eye highlights
    final hlPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(cx - w * 0.11, eyeY - eyeRadius * 0.3),
      eyeRadius * 0.4,
      hlPaint,
    );
    canvas.drawCircle(
      Offset(cx + w * 0.17, eyeY - eyeRadius * 0.3),
      eyeRadius * 0.4,
      hlPaint,
    );
  }

  @override
  bool shouldRepaint(_GhostPainter old) => false;
}
