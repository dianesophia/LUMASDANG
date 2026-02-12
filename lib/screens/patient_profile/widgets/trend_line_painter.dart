import 'package:flutter/material.dart';

/// Custom painter for drawing trend line charts
class TrendLinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final double minValue;
  final double maxValue;

  TrendLinePainter({
    required this.data,
    required this.color,
    required this.minValue,
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final range = maxValue - minValue;
    // Ensure minimum range to avoid flat lines
    final effectiveRange = range > 0.1 ? range : 0.1;
    final step = size.width / (data.length - 1);

    // Draw shadow area
    final shadowPath = Path();
    shadowPath.moveTo(0, size.height);
    
    for (int i = 0; i < data.length; i++) {
      final x = i * step;
      final normalizedValue = (data[i] - minValue) / effectiveRange;
      final y = size.height - (normalizedValue * size.height);
      
      if (i == 0) {
        shadowPath.lineTo(x, y);
      } else {
        shadowPath.lineTo(x, y);
      }
    }
    shadowPath.lineTo(size.width, size.height);
    shadowPath.close();
    canvas.drawPath(shadowPath, shadowPaint);

    // Draw line
    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = i * step;
      final normalizedValue = (data[i] - minValue) / effectiveRange;
      final y = size.height - (normalizedValue * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);

    // Draw points
    for (int i = 0; i < data.length; i++) {
      final x = i * step;
      final normalizedValue = (data[i] - minValue) / effectiveRange;
      final y = size.height - (normalizedValue * size.height);

      // Draw white circle background
      canvas.drawCircle(
        Offset(x, y),
        5,
        Paint()..color = Colors.white,
      );
      
      // Draw colored point
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
