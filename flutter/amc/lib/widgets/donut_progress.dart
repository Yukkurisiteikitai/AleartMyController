import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class DonutProgress extends StatelessWidget {
  const DonutProgress({
    super.key,
    required this.value,
    this.size = 120,
    this.strokeWidth = 14,
    this.color,
    this.backgroundColor,
    this.label,
    this.centerTextStyle,
  }) : assert(value >= 0.0 && value <= 1.0);

  final double value;
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? backgroundColor;
  final String? label;
  final TextStyle? centerTextStyle;

  @override
  Widget build(BuildContext context) {
    final fillColor = color ?? AppTheme.primary;
    final bgColor = backgroundColor ?? AppTheme.divider;
    final percent = (value * 100).round();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              startDegreeOffset: -90,
              sectionsSpace: 0,
              centerSpaceRadius: (size / 2) - strokeWidth,
              sections: [
                PieChartSectionData(
                  value: value * 100,
                  color: fillColor,
                  radius: strokeWidth,
                  showTitle: false,
                ),
                PieChartSectionData(
                  value: (1 - value) * 100,
                  color: bgColor,
                  radius: strokeWidth,
                  showTitle: false,
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percent%',
                style: centerTextStyle ??
                    TextStyle(
                      fontSize: size * 0.22,
                      fontWeight: FontWeight.w700,
                      color: fillColor,
                    ),
              ),
              if (label != null)
                Text(
                  label!,
                  style: AppTheme.bodySmall.copyWith(fontSize: size * 0.1),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
