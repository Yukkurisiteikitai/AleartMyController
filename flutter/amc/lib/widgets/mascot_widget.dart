import 'package:flutter/material.dart';

// TODO(asset): Replace with a proper character asset when provided.
// Using a Material icon as a visible placeholder on gradient backgrounds.
class MascotWidget extends StatelessWidget {
  const MascotWidget({super.key, this.size = 80, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
          ),
          Icon(
            Icons.sentiment_satisfied_alt_rounded,
            size: size * 0.65,
            color: c.withValues(alpha: 0.9),
          ),
        ],
      ),
    );
  }
}
