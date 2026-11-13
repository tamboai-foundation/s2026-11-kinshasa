import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The only glyphs that may be drawn filled.
enum WouandaStateGlyph { star, bookmark, heart }

/// A Lucide-style glyph (2 px stroke on a 24 grid, round joins) that fills
/// when `active`.
///
/// Lucide has no filled variant, and the app uses no other icon set. A state
/// that must be read at a glance (rated, saved, liked) is therefore drawn
/// here: outline when off, same shape filled when on. Never decorative: every
/// other icon stays `LucideIcons`. The caller gives the colour of the current
/// state, as with `Icon`.
class WouandaStateIcon extends StatelessWidget {
  const WouandaStateIcon(
    this.glyph, {
    super.key,
    required this.active,
    this.size = 24,
    this.color,
  });

  final WouandaStateGlyph glyph;
  final bool active;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? IconTheme.of(context).color ?? Colors.black;
    return ExcludeSemantics(
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: SizedBox.square(
          dimension: size,
          child: CustomPaint(
            painter: _StatePainter(glyph, active: active, color: resolved),
          ),
        ),
      ),
    );
  }
}

class _StatePainter extends CustomPainter {
  const _StatePainter(this.glyph, {required this.active, required this.color});

  final WouandaStateGlyph glyph;
  final bool active;
  final Color color;

  Path _path() {
    switch (glyph) {
      case WouandaStateGlyph.star:
        const outer = 10.0, inner = 4.5;
        final path = Path();
        for (var i = 0; i < 10; i++) {
          final r = i.isEven ? outer : inner;
          final a = -1.5707963 + i * 0.6283185;
          final x = 12 + r * math.cos(a), y = 12.6 + r * math.sin(a);
          i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
        }
        return path..close();
      case WouandaStateGlyph.bookmark:
        return Path()
          ..moveTo(19, 21)
          ..lineTo(12, 17)
          ..lineTo(5, 21)
          ..lineTo(5, 5)
          ..quadraticBezierTo(5, 3, 7, 3)
          ..lineTo(17, 3)
          ..quadraticBezierTo(19, 3, 19, 5)
          ..close();
      case WouandaStateGlyph.heart:
        return Path()
          ..moveTo(2, 9.5)
          ..arcToPoint(
            const Offset(11.591, 5.824),
            radius: const Radius.circular(5.5),
          )
          ..quadraticBezierTo(12, 6.3, 12.409, 5.824)
          ..arcToPoint(
            const Offset(22, 9.5),
            radius: const Radius.circular(5.49),
          )
          ..cubicTo(22, 11.79, 20.5, 13.5, 19, 15)
          ..lineTo(13.508, 20.313)
          ..arcToPoint(
            const Offset(10.508, 20.332),
            radius: const Radius.circular(2),
          )
          ..lineTo(5, 15)
          ..cubicTo(3.5, 13.5, 2, 11.8, 2, 9.5)
          ..close();
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final path = _path();
    if (active) {
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_StatePainter old) =>
      old.glyph != glyph || old.active != active || old.color != color;
}
