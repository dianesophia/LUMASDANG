import 'package:flutter/material.dart';

/// Custom painter for drawing trend line charts with smooth curves,
/// area fill, and optional horizontal grid lines.
class TrendLinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final double minValue;
  final double maxValue;
  final Color? gridLineColor;

  TrendLinePainter({
    required this.data,
    required this.color,
    required this.minValue,
    required this.maxValue,
    this.gridLineColor,
  });

  /// Build smooth path through points using cubic Bezier (Catmull-Rom style).
  static Path _smoothPathThroughPoints(List<Offset> points) {
    final path = Path();
    if (points.isEmpty) return path;
    if (points.length == 1) {
      path.moveTo(points[0].dx, points[0].dy);
      return path;
    }
    if (points.length == 2) {
      path.moveTo(points[0].dx, points[0].dy);
      path.lineTo(points[1].dx, points[1].dy);
      return path;
    }

    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i > 0 ? i - 1 : 0];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = points[i + 1 < points.length - 1 ? i + 2 : i + 1];

      final cp1 = Offset(
        p1.dx + (p2.dx - p0.dx) / 6,
        p1.dy + (p2.dy - p0.dy) / 6,
      );
      final cp2 = Offset(
        p2.dx - (p3.dx - p1.dx) / 6,
        p2.dy - (p3.dy - p1.dy) / 6,
      );
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final w = size.width.isFinite && size.width > 0 ? size.width : 200.0;
    final h = size.height.isFinite && size.height > 0 ? size.height : 80.0;

    final range = maxValue - minValue;
    final effectiveRange = range > 0.1 ? range : 0.1;
    final step = w / (data.length - 1);

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = i * step;
      final normalizedValue = (data[i] - minValue) / effectiveRange;
      final y = h - (normalizedValue * h);
      points.add(Offset(x, y));
    }

    // 1) Faint horizontal grid lines (at major Y ticks)
    if (gridLineColor != null) {
      const gridCount = 4;
      final gridPaint = Paint()
        ..color = gridLineColor!.withOpacity(0.35)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      for (int g = 0; g <= gridCount; g++) {
        final t = g / gridCount;
        final y = h * (1 - t);
        canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
      }
    }

    // 2) Area fill (smooth curve down to baseline)
    final fillPath = Path();
    fillPath.moveTo(0, h);
    fillPath.lineTo(points[0].dx, points[0].dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i > 0 ? i - 1 : 0];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = points[i + 1 < points.length - 1 ? i + 2 : i + 1];
      final cp1 = Offset(p1.dx + (p2.dx - p0.dx) / 6, p1.dy + (p2.dy - p0.dy) / 6);
      final cp2 = Offset(p2.dx - (p3.dx - p1.dx) / 6, p2.dy - (p3.dy - p1.dy) / 6);
      fillPath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p2.dx, p2.dy);
    }
    fillPath.lineTo(w, h);
    fillPath.close();
    canvas.drawPath(
      fillPath,
      Paint()
        ..color = color.withOpacity(0.18)
        ..style = PaintingStyle.fill,
    );

    // 3) Smooth line
    final linePath = _smoothPathThroughPoints(points);
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    // 4) Data point circles (filled, no white ring for cleaner look like reference)
    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (final p in points) {
      canvas.drawCircle(p, 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant TrendLinePainter oldDelegate) {
    return oldDelegate.data.length != data.length ||
        oldDelegate.color != color ||
        oldDelegate.minValue != minValue ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.gridLineColor != gridLineColor;
  }
}
