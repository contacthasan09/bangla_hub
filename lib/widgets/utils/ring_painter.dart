// Custom painter for animated ring
import 'package:flutter/material.dart';

class RingPainter extends CustomPainter {
  final double value;
  
  RingPainter(this.value);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    
    final radius = size.width / 2;
    final center = Offset(size.width / 2, size.height / 2);
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 2),
      value,
      0.5,
      false,
      paint,
    );
  }
  
  @override
  bool shouldRepaint(covariant RingPainter oldDelegate) => oldDelegate.value != value;
}