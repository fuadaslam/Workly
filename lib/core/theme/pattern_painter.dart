import 'package:flutter/material.dart';

/// A subtle dot-grid pattern — modern alternative to geometric shapes.
/// Renders tiny filled circles on a regular grid.
class GridDotPatternPainter extends CustomPainter {
  final Color color;
  final double spacing;
  final double radius;

  const GridDotPatternPainter({
    this.color = const Color(0x0DFFFFFF),
    this.spacing = 24.0,
    this.radius = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || size.width.isInfinite || size.height.isInfinite) return;
    final paint = Paint()..color = color;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(GridDotPatternPainter old) =>
      old.color != color || old.spacing != spacing || old.radius != radius;
}

/// Legacy alias so existing code importing [MashrabiyaPatternPainter] still compiles.
typedef MashrabiyaPatternPainter = GridDotPatternPainter;
