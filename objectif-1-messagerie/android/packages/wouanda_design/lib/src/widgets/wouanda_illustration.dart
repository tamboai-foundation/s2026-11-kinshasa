import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../foundations/wouanda_colors.dart';

/// Subjects of the Wouanda illustration family.
enum WouandaArt {
  mobility,
  shop,
  events,
  stay,
  love,
  pay,
  messages,
  activity,
  search,
  success,
  location,
  allServices,

  /// A shield with a check: safety measures, protection.
  safety,

  /// A calendar with a clock: planned rides, schedules.
  schedule,
}

/// The Wouanda illustration family (charter §12, « Apple moderne »).
///
/// One recipe for every picture, so they read as a set:
/// - a soft halo in the subject's hue, two small sparkles;
/// - one object built from rounded shapes, lit from the top (the same light
///   as [WouandaIconTile]), with a soft contact shadow;
/// - white and ink details only.
///
/// Vector, so it stays sharp at any size and follows light and dark mode.
class WouandaIllustration extends StatelessWidget {
  const WouandaIllustration(
    this.art, {
    super.key,
    this.size = 120,
    this.icon,
    this.bare = false,
  });

  /// Generic version: any icon on the family's glossy disc. Used where no
  /// dedicated subject exists (empty states of every service).
  const WouandaIllustration.icon(
    IconData this.icon, {
    super.key,
    this.size = 120,
  }) : art = null,
       bare = false;

  final WouandaArt? art;
  final IconData? icon;
  final double size;

  /// Object only, without halo nor sparkles: for small sizes (home tiles).
  final bool bare;

  static Color hueOf(WouandaArt art) => switch (art) {
    WouandaArt.mobility || WouandaArt.schedule => WouandaColors.go,
    WouandaArt.shop => WouandaColors.shop,
    WouandaArt.events => WouandaColors.events,
    WouandaArt.stay => WouandaColors.stay,
    WouandaArt.love => WouandaColors.love,
    WouandaArt.pay => WouandaColors.pay,
    WouandaArt.success => WouandaColors.pay,
    _ => WouandaColors.brand,
  };

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final hue = art == null ? WouandaColors.brand : hueOf(art!);
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _ArtPainter(art: art, hue: hue, dark: dark, bare: bare),
        child: icon == null
            ? null
            : Center(
                child: Padding(
                  padding: EdgeInsets.only(bottom: size * 0.04),
                  child: Icon(icon, size: size * 0.26, color: Colors.white),
                ),
              ),
      ),
    );
  }
}

class _ArtPainter extends CustomPainter {
  _ArtPainter({
    required this.art,
    required this.hue,
    required this.dark,
    this.bare = false,
  });

  final WouandaArt? art;
  final Color hue;
  final bool dark;
  final bool bare;

  static const _ink = WouandaColors.paletteInk;
  static const _gold = Color(0xFFFFCC00);

  late Canvas _c;
  late double _k;

  Offset _p(double x, double y) => Offset(x * _k, y * _k);
  Rect _r(double l, double t, double r, double b) =>
      Rect.fromLTRB(l * _k, t * _k, r * _k, b * _k);
  RRect _rr(double l, double t, double r, double b, double radius) =>
      RRect.fromRectAndRadius(_r(l, t, r, b), Radius.circular(radius * _k));

  /// Top-lit fill: the family's single light source.
  Paint _lit(Color color, Rect bounds) => Paint()
    ..shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color.lerp(color, Colors.white, 0.28)!, color],
    ).createShader(bounds);

  Paint _fill(Color color) => Paint()..color = color;

  void _shadow(double cx, double cy, double w) {
    _c.drawOval(
      Rect.fromCenter(center: _p(cx, cy), width: w * _k, height: 7 * _k),
      Paint()
        ..color = Colors.black.withValues(alpha: dark ? 0.35 : 0.12)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 3 * _k),
    );
  }

  void _halo() {
    _c.drawCircle(
      _p(50, 50),
      46 * _k,
      _fill(hue.withValues(alpha: dark ? 0.18 : 0.10)),
    );
    _c.drawCircle(
      _p(50, 50),
      34 * _k,
      _fill(hue.withValues(alpha: dark ? 0.12 : 0.07)),
    );
  }

  void _sparkle(double x, double y, double r, Color color) {
    final path = Path()
      ..moveTo(x * _k, (y - r) * _k)
      ..quadraticBezierTo(x * _k, y * _k, (x + r) * _k, y * _k)
      ..quadraticBezierTo(x * _k, y * _k, x * _k, (y + r) * _k)
      ..quadraticBezierTo(x * _k, y * _k, (x - r) * _k, y * _k)
      ..quadraticBezierTo(x * _k, y * _k, x * _k, (y - r) * _k)
      ..close();
    _c.drawPath(path, _fill(color));
  }

  void _gloss(RRect shape) {
    // A soft highlight on the upper-left of an object.
    final g = Rect.fromLTWH(
      shape.left + shape.width * 0.08,
      shape.top + shape.height * 0.08,
      shape.width * 0.42,
      shape.height * 0.22,
    );
    _c.drawRRect(
      RRect.fromRectAndRadius(g, Radius.circular(g.height / 2)),
      _fill(Colors.white.withValues(alpha: 0.22)),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    _c = canvas;
    _k = size.shortestSide / 100;
    if (bare) {
      // Zoom on the object so it fills a small tile.
      canvas.translate(-size.width * 0.12, -size.height * 0.12);
      canvas.scale(1.24);
    } else {
      _halo();
      _sparkle(16, 26, 4, hue.withValues(alpha: 0.55));
      _sparkle(84, 20, 3, _gold);
    }
    switch (art) {
      case null:
        _disc();
      case WouandaArt.mobility:
        _car();
      case WouandaArt.shop:
        _bag();
      case WouandaArt.events:
        _tickets();
      case WouandaArt.stay:
        _house();
      case WouandaArt.love:
        _bubblesLove();
      case WouandaArt.pay:
        _card();
      case WouandaArt.messages:
        _bubbles();
      case WouandaArt.activity:
        _receipt();
      case WouandaArt.search:
        _magnifier();
      case WouandaArt.success:
        _check();
      case WouandaArt.location:
        _pin();
      case WouandaArt.allServices:
        _grid();
      case WouandaArt.safety:
        _shield();
      case WouandaArt.schedule:
        _calendar();
    }
  }

  void _disc() {
    _shadow(50, 80, 44);
    final disc = Rect.fromCircle(center: _p(50, 48), radius: 26 * _k);
    _c.drawCircle(disc.center, disc.width / 2, _lit(hue, disc));
    _c.drawCircle(
      _p(42, 38),
      9 * _k,
      _fill(Colors.white.withValues(alpha: 0.18)),
    );
  }

  void _car() {
    _shadow(50, 80, 70);
    // Cabin.
    final cabin = Path()
      ..moveTo(28 * _k, 50 * _k)
      ..lineTo(36 * _k, 33 * _k)
      ..quadraticBezierTo(38 * _k, 30 * _k, 42 * _k, 30 * _k)
      ..lineTo(60 * _k, 30 * _k)
      ..quadraticBezierTo(64 * _k, 30 * _k, 66 * _k, 33 * _k)
      ..lineTo(74 * _k, 50 * _k)
      ..close();
    _c.drawPath(cabin, _lit(Color.lerp(hue, _ink, 0.25)!, _r(28, 30, 74, 50)));
    _c.drawRRect(
      _rr(39, 34, 49, 48, 2),
      _fill(Colors.white.withValues(alpha: 0.85)),
    );
    _c.drawRRect(
      _rr(52, 34, 63, 48, 2),
      _fill(Colors.white.withValues(alpha: 0.85)),
    );
    // Body.
    final body = _rr(16, 46, 86, 70, 10);
    _c.drawRRect(body, _lit(hue, body.outerRect));
    _gloss(body);
    _c.drawRRect(_rr(78, 52, 85, 57, 2.5), _fill(_gold));
    _c.drawRRect(_rr(17, 52, 23, 57, 2.5), _fill(const Color(0xFFFF6B5E)));
    // Wheels.
    for (final x in [32.0, 70.0]) {
      _c.drawCircle(_p(x, 70), 8 * _k, _fill(_ink));
      _c.drawCircle(_p(x, 70), 3.4 * _k, _fill(const Color(0xFFD1D1D6)));
    }
  }

  void _bag() {
    _shadow(50, 84, 56);
    final handle = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5 * _k
      ..strokeCap = StrokeCap.round
      ..color = Color.lerp(hue, _ink, 0.35)!;
    _c.drawArc(_r(36, 20, 64, 50), math.pi, math.pi, false, handle);
    // A folded wax fabric peeking out.
    final cloth = _rr(52, 26, 66, 46, 3);
    _c.save();
    _c.translate(59 * _k, 36 * _k);
    _c.rotate(0.35);
    _c.translate(-59 * _k, -36 * _k);
    _c.drawRRect(cloth, _lit(WouandaColors.events, cloth.outerRect));
    for (var y = 30.0; y < 44; y += 5) {
      _c.drawRect(_r(52, y, 66, y + 1.6), _fill(_gold));
    }
    _c.restore();
    final body = _rr(24, 36, 76, 82, 9);
    _c.drawRRect(body, _lit(hue, body.outerRect));
    _gloss(body);
    // Diamond motif.
    for (final x in [38.0, 50.0, 62.0]) {
      final d = Path()
        ..moveTo(x * _k, 56 * _k)
        ..lineTo((x + 4) * _k, 60 * _k)
        ..lineTo(x * _k, 64 * _k)
        ..lineTo((x - 4) * _k, 60 * _k)
        ..close();
      _c.drawPath(d, _fill(Colors.white.withValues(alpha: 0.75)));
    }
  }

  Path _ticketPath(Rect rect, double notch) {
    final ticket = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(7 * _k)));
    final holes = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(rect.left, rect.center.dy),
          radius: notch,
        ),
      )
      ..addOval(
        Rect.fromCircle(
          center: Offset(rect.right, rect.center.dy),
          radius: notch,
        ),
      );
    return Path.combine(PathOperation.difference, ticket, holes);
  }

  void _tickets() {
    _shadow(50, 80, 64);
    // Back ticket.
    _c.save();
    _c.translate(50 * _k, 50 * _k);
    _c.rotate(0.22);
    _c.translate(-50 * _k, -50 * _k);
    final back = _r(22, 32, 80, 64);
    _c.drawPath(
      _ticketPath(back, 5 * _k),
      _fill(Color.lerp(hue, Colors.white, 0.55)!),
    );
    _c.restore();
    // Front ticket.
    _c.save();
    _c.translate(50 * _k, 52 * _k);
    _c.rotate(-0.14);
    _c.translate(-50 * _k, -52 * _k);
    final front = _r(18, 36, 80, 70);
    _c.drawPath(_ticketPath(front, 5.5 * _k), _lit(hue, front));
    final dash = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 1.6 * _k
      ..strokeCap = StrokeCap.round;
    for (var y = 40.0; y < 68; y += 5) {
      _c.drawLine(_p(62, y), _p(62, y + 2.4), dash);
    }
    _sparkle(38, 53, 8, Colors.white);
    _sparkle(50, 46, 3.5, _gold);
    _c.restore();
  }

  void _house() {
    _shadow(50, 84, 62);
    final roof = Path()
      ..moveTo(20 * _k, 48 * _k)
      ..lineTo(50 * _k, 22 * _k)
      ..lineTo(80 * _k, 48 * _k)
      ..close();
    final body = _rr(27, 44, 73, 82, 5);
    _c.drawRRect(body, _lit(hue, body.outerRect));
    _c.drawPath(roof, _lit(Color.lerp(hue, _ink, 0.3)!, _r(20, 22, 80, 48)));
    _c.drawRRect(
      _rr(44, 60, 56, 82, 3),
      _fill(Colors.white.withValues(alpha: 0.9)),
    );
    _c.drawRRect(
      _rr(32, 52, 40, 60, 2),
      _fill(Colors.white.withValues(alpha: 0.8)),
    );
    _c.drawRRect(
      _rr(60, 52, 68, 60, 2),
      _fill(Colors.white.withValues(alpha: 0.8)),
    );
    // Key.
    final key = Paint()
      ..color = _gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * _k
      ..strokeCap = StrokeCap.round;
    _c.drawCircle(_p(76, 66), 6 * _k, key);
    _c.drawLine(_p(80, 71), _p(88, 80), key);
    _c.drawLine(_p(85, 77), _p(82, 80), key);
  }

  Path _bubble(Rect rect, {required bool tailLeft}) {
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(12 * _k)));
    final tail = Path();
    if (tailLeft) {
      tail
        ..moveTo(rect.left + 8 * _k, rect.bottom - 6 * _k)
        ..lineTo(rect.left + 2 * _k, rect.bottom + 7 * _k)
        ..lineTo(rect.left + 18 * _k, rect.bottom - 2 * _k)
        ..close();
    } else {
      tail
        ..moveTo(rect.right - 8 * _k, rect.bottom - 6 * _k)
        ..lineTo(rect.right - 2 * _k, rect.bottom + 7 * _k)
        ..lineTo(rect.right - 18 * _k, rect.bottom - 2 * _k)
        ..close();
    }
    return Path.combine(PathOperation.union, path, tail);
  }

  void _heart(double cx, double cy, double s, Paint paint) {
    final path = Path()
      ..moveTo(cx * _k, (cy + s * 0.9) * _k)
      ..cubicTo(
        (cx - s * 1.6) * _k,
        (cy - s * 0.2) * _k,
        (cx - s * 0.7) * _k,
        (cy - s * 1.4) * _k,
        cx * _k,
        (cy - s * 0.5) * _k,
      )
      ..cubicTo(
        (cx + s * 0.7) * _k,
        (cy - s * 1.4) * _k,
        (cx + s * 1.6) * _k,
        (cy - s * 0.2) * _k,
        cx * _k,
        (cy + s * 0.9) * _k,
      )
      ..close();
    _c.drawPath(path, paint);
  }

  void _bubblesLove() {
    _shadow(50, 84, 58);
    final back = _r(44, 40, 84, 70);
    _c.drawPath(
      _bubble(back, tailLeft: false),
      _lit(WouandaColors.brand400, back),
    );
    final front = _r(16, 26, 62, 60);
    _c.drawPath(_bubble(front, tailLeft: true), _lit(hue, front));
    _heart(39, 44, 9, _fill(Colors.white));
    for (final x in [56.0, 64.0, 72.0]) {
      _c.drawCircle(_p(x, 57), 2.4 * _k, _fill(Colors.white));
    }
  }

  void _card() {
    _shadow(50, 82, 66);
    _c.save();
    _c.translate(48 * _k, 50 * _k);
    _c.rotate(-0.16);
    _c.translate(-48 * _k, -50 * _k);
    final card = _rr(16, 30, 80, 70, 8);
    _c.drawRRect(card, _lit(hue, card.outerRect));
    _gloss(card);
    _c.drawRect(_r(16, 40, 80, 47), _fill(_ink.withValues(alpha: 0.55)));
    _c.drawRRect(_rr(24, 54, 34, 62, 2), _fill(_gold));
    _c.drawRRect(
      _rr(40, 56, 64, 60, 2),
      _fill(Colors.white.withValues(alpha: 0.7)),
    );
    _c.restore();
    // Coin.
    final coin = Rect.fromCircle(center: _p(72, 68), radius: 13 * _k);
    _c.drawCircle(coin.center, coin.width / 2, _lit(_gold, coin));
    _c.drawCircle(
      coin.center,
      8 * _k,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2 * _k
        ..color = Colors.white.withValues(alpha: 0.7),
    );
  }

  void _bubbles() {
    _shadow(50, 84, 58);
    final back = _r(40, 42, 84, 72);
    _c.drawPath(
      _bubble(back, tailLeft: false),
      _fill(dark ? WouandaColors.elevatedDark : Colors.white),
    );
    for (final x in [52.0, 62.0, 72.0]) {
      _c.drawCircle(_p(x, 57), 2.6 * _k, _fill(WouandaColors.paletteGrey));
    }
    final front = _r(16, 24, 62, 56);
    _c.drawPath(_bubble(front, tailLeft: true), _lit(hue, front));
    _c.drawRRect(_rr(24, 34, 52, 38, 2), _fill(Colors.white));
    _c.drawRRect(
      _rr(24, 43, 44, 47, 2),
      _fill(Colors.white.withValues(alpha: 0.75)),
    );
  }

  void _receipt() {
    _shadow(46, 86, 50);
    final paper = Path()
      ..moveTo(26 * _k, 22 * _k)
      ..lineTo(66 * _k, 22 * _k)
      ..lineTo(66 * _k, 82 * _k);
    for (var x = 66.0; x > 26; x -= 8) {
      paper
        ..lineTo((x - 4) * _k, 78 * _k)
        ..lineTo((x - 8) * _k, 82 * _k);
    }
    paper.close();
    _c.drawPath(paper, _fill(dark ? WouandaColors.elevatedDark : Colors.white));
    final line = _fill(WouandaColors.paletteGrey.withValues(alpha: 0.55));
    for (final (y, w) in [(32.0, 30.0), (41.0, 22.0), (50.0, 26.0)]) {
      _c.drawRRect(_rr(33, y, 33 + w, y + 4, 2), line);
    }
    _c.drawRRect(_rr(33, 62, 50, 67, 2), _fill(_ink.withValues(alpha: 0.8)));
    // Clock badge.
    final badge = Rect.fromCircle(center: _p(70, 66), radius: 14 * _k);
    _c.drawCircle(badge.center, badge.width / 2, _lit(hue, badge));
    final hand = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.6 * _k
      ..strokeCap = StrokeCap.round;
    _c.drawLine(_p(70, 66), _p(70, 58), hand);
    _c.drawLine(_p(70, 66), _p(76, 69), hand);
  }

  void _magnifier() {
    _shadow(46, 84, 50);
    final handle = Paint()
      ..color = _ink
      ..strokeWidth = 8 * _k
      ..strokeCap = StrokeCap.round;
    _c.drawLine(_p(60, 62), _p(76, 78), handle);
    final lens = Rect.fromCircle(center: _p(44, 44), radius: 22 * _k);
    _c.drawCircle(lens.center, lens.width / 2, _lit(hue, lens));
    _c.drawCircle(
      lens.center,
      15 * _k,
      _fill(dark ? WouandaColors.elevatedDark : Colors.white),
    );
    _c.drawCircle(_p(38, 38), 4 * _k, _fill(hue.withValues(alpha: 0.25)));
  }

  void _check() {
    _shadow(50, 84, 50);
    final disc = Rect.fromCircle(center: _p(50, 48), radius: 26 * _k);
    _c.drawCircle(disc.center, disc.width / 2, _lit(hue, disc));
    final tick = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6 * _k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    _c.drawPath(
      Path()
        ..moveTo(38 * _k, 49 * _k)
        ..lineTo(47 * _k, 58 * _k)
        ..lineTo(63 * _k, 40 * _k),
      tick,
    );
    // Confetti in the service hues.
    for (final (x, y, color) in [
      (22.0, 58.0, WouandaColors.shop),
      (80.0, 50.0, WouandaColors.events),
      (72.0, 80.0, WouandaColors.go),
      (28.0, 80.0, WouandaColors.love),
    ]) {
      _c.drawRRect(_rr(x - 2.5, y - 2.5, x + 2.5, y + 2.5, 1.2), _fill(color));
    }
  }

  void _grid() {
    _shadow(50, 82, 56);
    const hues = [
      WouandaColors.go,
      WouandaColors.shop,
      WouandaColors.events,
      WouandaColors.love,
    ];
    for (final (i, color) in hues.indexed) {
      final x = 24.0 + (i % 2) * 28;
      final y = 24.0 + (i ~/ 2) * 28;
      final tile = _rr(x, y, x + 24, y + 24, 7);
      _c.drawRRect(tile, _lit(color, tile.outerRect));
      _gloss(tile);
    }
  }

  /// A shield: top-lit, a lighter inner plate, a white check.
  void _shield() {
    _shadow(50, 86, 46);
    Path outline(double inset) {
      final i = inset;
      return Path()
        ..moveTo(50 * _k, (16 + i) * _k)
        ..cubicTo(
          62 * _k,
          (22 + i) * _k,
          (74 - i) * _k,
          (24 + i) * _k,
          (78 - i) * _k,
          (26 + i) * _k,
        )
        ..lineTo((78 - i) * _k, (50 + i) * _k)
        ..cubicTo(
          (78 - i) * _k,
          (68 - i) * _k,
          64 * _k,
          (80 - i) * _k,
          50 * _k,
          (86 - i) * _k,
        )
        ..cubicTo(
          36 * _k,
          (80 - i) * _k,
          (22 + i) * _k,
          (68 - i) * _k,
          (22 + i) * _k,
          (50 + i) * _k,
        )
        ..lineTo((22 + i) * _k, (26 + i) * _k)
        ..cubicTo(
          (26 + i) * _k,
          (24 + i) * _k,
          38 * _k,
          (22 + i) * _k,
          50 * _k,
          (16 + i) * _k,
        )
        ..close();
    }

    _c.drawPath(outline(0), _lit(hue, _r(22, 16, 78, 86)));
    _c.drawPath(outline(5), _fill(Colors.white.withValues(alpha: 0.16)));
    final tick = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6 * _k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    _c.drawPath(
      Path()
        ..moveTo(38 * _k, 50 * _k)
        ..lineTo(47 * _k, 59 * _k)
        ..lineTo(63 * _k, 40 * _k),
      tick,
    );
  }

  /// A calendar page with its rings, a grid of days and a small clock.
  void _calendar() {
    _shadow(50, 84, 54);
    final page = _rr(22, 26, 78, 76, 8);
    _c.drawRRect(page, _fill(Colors.white));
    _c.drawRRect(
      page,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 * _k
        ..color = hue.withValues(alpha: 0.25),
    );
    final head = RRect.fromRectAndCorners(
      _r(22, 26, 78, 42),
      topLeft: Radius.circular(8 * _k),
      topRight: Radius.circular(8 * _k),
    );
    _c.drawRRect(head, _lit(hue, head.outerRect));
    for (final x in [36.0, 64.0]) {
      _c.drawRRect(_rr(x - 2, 20, x + 2, 32, 2), _fill(_ink));
    }
    for (var row = 0; row < 2; row++) {
      for (var col = 0; col < 4; col++) {
        _c.drawCircle(
          _p(31 + col * 12.0, 50 + row * 10.0),
          2.2 * _k,
          _fill(hue.withValues(alpha: row == 0 && col == 1 ? 0.9 : 0.28)),
        );
      }
    }
    // The clock.
    final clock = _p(70, 70);
    _c.drawCircle(clock, 13 * _k, _fill(Colors.white));
    _c.drawCircle(clock, 11 * _k, _fill(_gold));
    final hands = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2 * _k
      ..strokeCap = StrokeCap.round;
    _c.drawLine(clock, clock + Offset(0, -6.5 * _k), hands);
    _c.drawLine(clock, clock + Offset(5 * _k, 2.5 * _k), hands);
  }

  void _pin() {
    _c.drawOval(
      Rect.fromCenter(center: _p(50, 80), width: 34 * _k, height: 10 * _k),
      _fill(hue.withValues(alpha: 0.25)),
    );
    final pin = Path()
      ..moveTo(50 * _k, 80 * _k)
      ..cubicTo(34 * _k, 60 * _k, 28 * _k, 50 * _k, 28 * _k, 40 * _k)
      ..arcToPoint(
        _p(72, 40),
        radius: Radius.circular(22 * _k),
        clockwise: true,
      )
      ..cubicTo(72 * _k, 50 * _k, 66 * _k, 60 * _k, 50 * _k, 80 * _k)
      ..close();
    _c.drawPath(pin, _lit(hue, _r(28, 18, 72, 80)));
    _c.drawCircle(_p(50, 40), 8 * _k, _fill(Colors.white));
  }

  @override
  bool shouldRepaint(_ArtPainter old) =>
      old.art != art || old.hue != hue || old.dark != dark || old.bare != bare;
}
