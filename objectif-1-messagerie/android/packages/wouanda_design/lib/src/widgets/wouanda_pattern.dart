import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Discreet geometric pattern inspired by woven textiles (rows of diamonds
/// and chevrons). Used only on brand hero headers, white at low opacity.
class WouandaPattern extends StatelessWidget {
  final Color color;
  final double opacity;

  const WouandaPattern({
    super.key,
    this.color = Colors.white,
    this.opacity = 0.08,
  });

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(
      painter: _WovenPainter(color.withValues(alpha: opacity)),
      size: Size.infinite,
    ),
  );
}

class _WovenPainter extends CustomPainter {
  final Color color;

  _WovenPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final fill = Paint()..color = color;
    const cell = 28.0;
    final rows = (size.height / cell).ceil() + 1;
    final cols = (size.width / cell).ceil() + 1;

    for (var row = 0; row < rows; row++) {
      final y = row * cell;
      for (var col = 0; col < cols; col++) {
        final x = col * cell + (row.isOdd ? cell / 2 : 0);
        if (row % 3 == 0) {
          // Chevron band.
          final path = Path()
            ..moveTo(x - cell / 2, y + cell / 4)
            ..lineTo(x, y - cell / 4)
            ..lineTo(x + cell / 2, y + cell / 4);
          canvas.drawPath(path, stroke);
        } else {
          // Diamonds with a dot in the middle.
          final r = cell * 0.22;
          final diamond = Path()
            ..moveTo(x, y - r)
            ..lineTo(x + r, y)
            ..lineTo(x, y + r)
            ..lineTo(x - r, y)
            ..close();
          canvas.drawPath(diamond, stroke);
          canvas.drawCircle(Offset(x, y), math.max(1.2, r * 0.18), fill);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_WovenPainter oldDelegate) => oldDelegate.color != color;
}
