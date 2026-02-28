import 'package:flutter/material.dart';

class PatternBackground extends StatelessWidget {
  final Widget child;
  const PatternBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: _PatternPainter())),
        child,
      ],
    );
  }
}

class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE5E7EB)
          .withAlpha(128) // Subtle light grey dots
      ..style = PaintingStyle.fill;

    const spacing = 20.0;
    const radius = 2.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        // Offset alternating rows for a diamond/zigzag pattern
        final xOffset = (y / spacing) % 2 == 0 ? 0.0 : spacing / 2.0;
        if (x + xOffset < size.width) {
          canvas.drawCircle(Offset(x + xOffset, y), radius, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
