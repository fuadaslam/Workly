import 'package:flutter/material.dart';
import 'package:service_manager_app/core/theme/app_theme.dart';

class MashrabiyaPatternPainter extends CustomPainter {
  final Color color;
  
  MashrabiyaPatternPainter({this.color = Colors.white10});
  
  @override
  void paint(Canvas canvas, Size size) {
    // Safety check for layout edge cases
    if (size.width.isInfinite || size.height.isInfinite || size.width <= 0 || size.height <= 0) return;

    var paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    double step = 30.0;
    
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        // Draw a simple 8-point star or geometric shape simulation
        canvas.drawRect(
             Rect.fromCenter(center: Offset(x, y), width: step * 0.4, height: step * 0.4),
             paint
        );
        canvas.drawCircle(Offset(x + step/2, y + step/2), step * 0.1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
