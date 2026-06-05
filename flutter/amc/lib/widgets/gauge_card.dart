import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'section_card.dart';

class GaugeCard extends StatelessWidget {
  const GaugeCard({
    super.key,
    required this.value,
    this.title,
    this.subtitle,
    this.color,
    this.size = 140,
  }) : assert(value >= 0.0 && value <= 1.0);

  final double value;
  final String? title;
  final String? subtitle;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final gaugeColor = color ?? AppTheme.primary;
    final percent = (value * 100).round();

    return SectionCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
              child: Text(title!, style: AppTheme.titleMedium),
            ),
          SizedBox(
            width: size,
            height: size * 0.6,
            child: CustomPaint(
              painter: _GaugePainter(
                value: value,
                color: gaugeColor,
                backgroundColor: AppTheme.divider,
              ),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(top: size * 0.25),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$percent%',
                        style: TextStyle(
                          fontSize: size * 0.2,
                          fontWeight: FontWeight.w700,
                          color: gaugeColor,
                        ),
                      ),
                      if (subtitle != null)
                        Text(subtitle!, style: AppTheme.bodySmall),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({
    required this.value,
    required this.color,
    required this.backgroundColor,
  });

  final double value;
  final Color color;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = size.width * 0.1;
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2 - strokeWidth / 2;

    final bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi,
      math.pi,
      false,
      bgPaint,
    );

    if (value > 0) {
      final fgPaint = Paint()
        ..color = color
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        math.pi,
        math.pi * value,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_GaugePainter old) =>
      old.value != value || old.color != color;
}
