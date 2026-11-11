import 'dart:math' as math;

import 'package:flutter/material.dart';

// The site of the DTR check-up (lesson 3.6 "ডিস্ট্রিবিউশন ট্রান্সফরমার (DTR)",
// কাজ 1): a drawn, layered place — the day sky, a far tree line and village
// roofs, the fields, and the hero: a pole-mounted DTR on a two-pole (H)
// structure. On the platform: the main tank with its radiator fins, the three
// tall HT bushings and the four short LT bushings (lesson point 2: HT bigger),
// the conservator drum on top with its oil level gauge (MIN / MAX), the
// silica-gel breather hanging from it, the nameplate and the drain valve. DO
// fuses and the LA on the cross-arm above, a danger plate on the pole. The
// trainee stands on the ground to the left — the check-up is done from the
// ground (lesson point 1: "দূর থেকে দেখুন").
//
// The only words in the art are the ones a worker reads: the gauge marks, the
// nameplate, the danger plate.
//
// Design: 360 wide × the scene's height; the ground row follows the bottom of
// the screen (a tall phone gets more sky).

/// The silica gel's colour: blue / orange = dry and good; pink (from blue) /
/// green (from orange) = it has soaked up moisture — change it (film 3.6).
enum M3DtrCheckupGel { blue, orange, pink, green }

/// Where the oil leaks from (lesson point 3: bushing gasket, weld joint,
/// drain valve).
enum M3DtrCheckupLeak { none, gasket, weld, drain }

/// What the trainee looks at (from the ground) — or listens to.
enum M3DtrCheckupSpot { breather, gauge, tank, nameplate, sound }

bool m3DtrCheckupGelSpent(M3DtrCheckupGel g) => g == M3DtrCheckupGel.pink || g == M3DtrCheckupGel.green;

Color m3DtrCheckupGelColor(M3DtrCheckupGel g) => switch (g) {
      M3DtrCheckupGel.blue => const Color(0xFF2F6FD8),
      M3DtrCheckupGel.orange => const Color(0xFFF08A1C),
      M3DtrCheckupGel.pink => const Color(0xFFF08DB4),
      M3DtrCheckupGel.green => const Color(0xFF3FA34D),
    };

/// The fresh colour a spent gel started from (the band still left on top).
M3DtrCheckupGel m3DtrCheckupGelFresh(M3DtrCheckupGel g) => switch (g) {
      M3DtrCheckupGel.pink => M3DtrCheckupGel.blue,
      M3DtrCheckupGel.green => M3DtrCheckupGel.orange,
      _ => g,
    };

/// What the DTR shows this round (the painter and the close-ups draw it).
@immutable
class M3DtrCheckupLook {
  const M3DtrCheckupLook({required this.gel, required this.oilLow, required this.leak, required this.rattle, required this.kva});
  final M3DtrCheckupGel gel;
  final bool oilLow;
  final M3DtrCheckupLeak leak;
  final bool rattle;
  final int kva;

  @override
  bool operator ==(Object other) =>
      other is M3DtrCheckupLook && other.gel == gel && other.oilLow == oilLow && other.leak == leak && other.rattle == rattle && other.kva == kva;

  @override
  int get hashCode => Object.hash(gel, oilLow, leak, rattle, kva);
}

/// Where things stand (design px, 360 wide).
@immutable
class M3DtrCheckupGeo {
  const M3DtrCheckupGeo({required this.height, required this.groundY});

  factory M3DtrCheckupGeo.forScene(double h, double inset) => M3DtrCheckupGeo(height: h, groundY: (h - 270 - inset).clamp(450.0, 700.0));

  final double height;
  final double groundY;

  double get horizonY => groundY - 120;
  double get poleTop => math.max(64.0, groundY - 440);

  static const leftPole = 132.0;
  static const rightPole = 350.0;

  /// The channel-iron platform the DTR sits on.
  double get platformY => groundY - 150;

  /// The main tank.
  Rect get tank => Rect.fromLTRB(186, groundY - 262, 300, platformY);

  /// The conservator drum on top.
  Rect get conservator => Rect.fromLTRB(194, groundY - 338, 296, groundY - 314);

  /// The oil level gauge on the conservator's right end.
  Offset get gauge => Offset(300, conservator.center.dy);

  /// The breather (glass cylinder of silica gel) hanging on the left.
  Rect get breather => Rect.fromLTWH(150, groundY - 306, 18, 44);

  /// The nameplate on the tank's front.
  Rect get nameplate => Rect.fromLTWH(198, groundY - 240, 48, 30);

  /// The drain valve at the bottom of the tank.
  Offset get drain => Offset(284, platformY - 12);

  /// The HT bushings (tall) on the top cover.
  List<double> get htX => const [212.0, 243.0, 274.0];
  double get coverY => groundY - 268;

  // Where a tap reaches each spot (≥ 48 design px).
  Rect get breatherHit => Rect.fromCenter(center: breather.center, width: 50, height: 70);
  Rect get gaugeHit => Rect.fromCenter(center: gauge, width: 52, height: 52);
  Rect get nameplateHit => Rect.fromCenter(center: nameplate.center, width: 60, height: 48);
  Rect get tankHit => Rect.fromLTRB(172, coverY - 6, 320, platformY + 10);

  /// The spot under a tap, if any (the small spots first).
  M3DtrCheckupSpot? hit(Offset p) {
    if (nameplateHit.contains(p)) return M3DtrCheckupSpot.nameplate;
    if (gaugeHit.contains(p)) return M3DtrCheckupSpot.gauge;
    if (breatherHit.contains(p)) return M3DtrCheckupSpot.breather;
    if (tankHit.contains(p)) return M3DtrCheckupSpot.tank;
    return null;
  }

  /// The centre of a spot (for tests and the ring).
  Offset spotAt(M3DtrCheckupSpot s) => switch (s) {
        M3DtrCheckupSpot.breather => breather.center,
        M3DtrCheckupSpot.gauge => gauge,
        M3DtrCheckupSpot.nameplate => nameplate.center,
        M3DtrCheckupSpot.tank => Offset(tank.center.dx + 20, tank.bottom - 22),
        M3DtrCheckupSpot.sound => tank.center,
      };

  /// The trainee on the ground, left of the structure.
  Rect get trainee => Rect.fromLTWH(8, groundY - 208, 104, 208);

  /// Where he would be on the platform (the deadly climb).
  Rect get traineeUp => Rect.fromLTWH(150, platformY - 150, 75, 150);

  /// Where the flash is when he is up there (by the HT bushing).
  Offset get zapAt => Offset(htX.first, coverY - 30);

  @override
  bool operator ==(Object other) => other is M3DtrCheckupGeo && other.height == height && other.groundY == groundY;

  @override
  int get hashCode => Object.hash(height, groundY);
}

/// The sky, the land, the H-structure and the DTR. [lit]: the spot being
/// looked at (a soft ring).
class M3DtrCheckupWorldPainter extends CustomPainter {
  const M3DtrCheckupWorldPainter({required this.geo, required this.look, this.lit});

  final M3DtrCheckupGeo geo;
  final M3DtrCheckupLook look;
  final M3DtrCheckupSpot? lit;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final g = geo.groundY;
    final hz = geo.horizonY;
    // Sky (late morning).
    c.drawRect(
        Rect.fromLTWH(0, 0, w, hz + 4),
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3A79B8), Color(0xFF8EC0E3), Color(0xFFE6F0E6)])
              .createShader(Rect.fromLTWH(0, 0, w, hz + 4)));
    c.drawCircle(Offset(64, hz - 250), 22, Paint()..color = const Color(0x88FFF6D0));
    final cloud = Paint()..color = const Color(0x66FFFFFF);
    for (final (x, y, r) in [(40.0, 130.0, 20.0), (70.0, 122.0, 26.0), (100.0, 132.0, 18.0), (240.0, 96.0, 16.0), (262.0, 90.0, 22.0), (288.0, 98.0, 15.0)]) {
      c.drawCircle(Offset(x, y), r, cloud);
    }
    // Far tree line and village roofs.
    final far = Path()..moveTo(0, hz);
    for (var x = 0.0; x <= w; x += 18) {
      far.lineTo(x, hz - 18 - 10 * math.sin(x * 0.07) - 6 * math.cos(x * 0.19));
    }
    far
      ..lineTo(w, hz + 2)
      ..lineTo(0, hz + 2)
      ..close();
    c.drawPath(far, Paint()..color = const Color(0xFF4F7A55));
    final roof = Paint()..color = const Color(0xFF8A4B36);
    final wall = Paint()..color = const Color(0xFFD9C7A3);
    for (final x in [22.0, 78.0]) {
      c.drawRect(Rect.fromLTWH(x, hz - 16, 30, 16), wall);
      c.drawPath(
          Path()
            ..moveTo(x - 4, hz - 16)
            ..lineTo(x + 15, hz - 30)
            ..lineTo(x + 34, hz - 16)
            ..close(),
          roof);
    }
    // Fields, then the dusty ground to the bottom.
    c.drawRect(Rect.fromLTWH(0, hz, w, g - hz),
        Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF86A85E), Color(0xFF627F45)]).createShader(Rect.fromLTWH(0, hz, w, g - hz)));
    c.drawRect(Rect.fromLTWH(0, g, w, size.height - g),
        Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFB59B74), Color(0xFF8C7556)]).createShader(Rect.fromLTWH(0, g, w, size.height - g)));
    final pebble = Paint()..color = const Color(0x33000000);
    final rnd = math.Random(5);
    for (var i = 0; i < 26; i++) {
      c.drawCircle(Offset(rnd.nextDouble() * w, g + 6 + rnd.nextDouble() * (size.height - g - 10)), 1.2 + rnd.nextDouble() * 1.6, pebble);
    }
    _structure(c);
    _dtr(c);
    if (lit != null && lit != M3DtrCheckupSpot.sound) {
      final r = switch (lit!) {
        M3DtrCheckupSpot.breather => geo.breather.inflate(6),
        M3DtrCheckupSpot.gauge => Rect.fromCircle(center: geo.gauge, radius: 14),
        M3DtrCheckupSpot.nameplate => geo.nameplate.inflate(5),
        _ => geo.tank.inflate(8),
      };
      c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(10)), Paint()
        ..color = const Color(0xDDFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4);
    }
  }

  void _structure(Canvas c) {
    final g = geo.groundY;
    final top = geo.poleTop;
    // Overhead 11 kV line to the far pole.
    final wire = Paint()
      ..color = const Color(0xFF2A2F36)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 3; i++) {
      final y = top + 6 + i * 2.0;
      c.drawPath(
          Path()
            ..moveTo(0, y + 40)
            ..quadraticBezierTo(80, y + 58, M3DtrCheckupGeo.leftPole + 20.0 + i * 70, y),
          wire);
    }
    // Two PCC poles.
    for (final px in [M3DtrCheckupGeo.leftPole, M3DtrCheckupGeo.rightPole]) {
      final pole = Path()
        ..moveTo(px - 6, top)
        ..lineTo(px + 6, top)
        ..lineTo(px + 10, g + 4)
        ..lineTo(px - 10, g + 4)
        ..close();
      c.drawPath(pole, Paint()..shader = const LinearGradient(colors: [Color(0xFFBDBDB6), Color(0xFF8D8D86)]).createShader(Rect.fromLTRB(px - 10, top, px + 10, g)));
      c.drawOval(Rect.fromCenter(center: Offset(px, g + 4), width: 44, height: 8), Paint()..color = const Color(0x33000000));
    }
    // The top cross-arm: three DO fuses and the LA.
    final arm = Paint()..color = const Color(0xFF4A4F57);
    c.drawRect(Rect.fromLTRB(M3DtrCheckupGeo.leftPole - 8, top + 14, M3DtrCheckupGeo.rightPole + 8, top + 20), arm);
    for (final (i, x) in geo.htX.indexed) {
      final dx = M3DtrCheckupGeo.leftPole + 20.0 + i * 70;
      // DO fuse barrel on its insulator.
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(dx - 4, top + 20, 8, 14), const Radius.circular(2)), Paint()..color = const Color(0xFFF2F0E8));
      c.drawLine(Offset(dx, top + 34), Offset(dx + 4, top + 62), Paint()
        ..color = const Color(0xFF6E5A44)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round);
      // The HT jumper down to its bushing.
      c.drawPath(
          Path()
            ..moveTo(dx + 4, top + 62)
            ..quadraticBezierTo((dx + x) / 2, top + 110, x, geo.coverY - 44),
          Paint()
            ..color = const Color(0xFF2A2F36)
            ..strokeWidth = 1.6
            ..style = PaintingStyle.stroke);
    }
    // The LA (on the right).
    final la = Rect.fromLTWH(M3DtrCheckupGeo.rightPole - 26, top + 22, 9, 26);
    c.drawRRect(RRect.fromRectAndRadius(la, const Radius.circular(3)), Paint()..color = const Color(0xFF8B5E3C));
    // The platform (channel iron) across both poles.
    final py = geo.platformY;
    c.drawRect(Rect.fromLTRB(M3DtrCheckupGeo.leftPole - 14, py, M3DtrCheckupGeo.rightPole + 12, py + 9), Paint()..color = const Color(0xFF3E444C));
    c.drawRect(Rect.fromLTRB(M3DtrCheckupGeo.leftPole - 14, py, M3DtrCheckupGeo.rightPole + 12, py + 2), Paint()..color = const Color(0xFF6B737D));
    // Diagonal braces.
    final brace = Paint()
      ..color = const Color(0xFF4A4F57)
      ..strokeWidth = 3;
    c.drawLine(Offset(M3DtrCheckupGeo.leftPole, py + 50), Offset(M3DtrCheckupGeo.leftPole + 40, py + 9), brace);
    c.drawLine(Offset(M3DtrCheckupGeo.rightPole, py + 50), Offset(M3DtrCheckupGeo.rightPole - 40, py + 9), brace);
    // The LT cable down the right pole.
    c.drawPath(
        Path()
          ..moveTo(316, geo.tank.top + 22)
          ..quadraticBezierTo(338, geo.tank.top + 30, M3DtrCheckupGeo.rightPole - 6, geo.tank.top + 60)
          ..lineTo(M3DtrCheckupGeo.rightPole - 6, g - 40),
        Paint()
          ..color = const Color(0xFF1A1D22)
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke);
    // The danger plate on the left pole.
    final plate = Rect.fromLTWH(M3DtrCheckupGeo.leftPole - 15, g - 120, 30, 34);
    c.drawRRect(RRect.fromRectAndRadius(plate, const Radius.circular(3)), Paint()..color = const Color(0xFFF2F0E8));
    c.drawRRect(RRect.fromRectAndRadius(plate.deflate(2), const Radius.circular(2)), Paint()
      ..color = const Color(0xFFD23A2E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6);
    _label(c, 'DANGER', Offset(plate.center.dx, plate.top + 9), 6.5, const Color(0xFFD23A2E));
    _label(c, '11kV', Offset(plate.center.dx, plate.bottom - 9), 8, const Color(0xFF1A1D22));
  }

  void _dtr(Canvas c) {
    final t = geo.tank;
    final g = geo.groundY;
    final tankPaint = Paint()..shader = const LinearGradient(colors: [Color(0xFF7E8E86), Color(0xFF5D6C65)]).createShader(t);
    // Radiator fins (left).
    for (var i = 0; i < 4; i++) {
      c.drawRect(Rect.fromLTWH(172 + i * 3.5, t.top + 10, 2.4, t.height - 20), Paint()..color = const Color(0xFF66766F));
    }
    // The tank and its top cover.
    c.drawRect(t.shift(const Offset(3, 3)), Paint()..color = const Color(0x33000000));
    c.drawRect(t, tankPaint);
    c.drawRect(Rect.fromLTRB(t.left - 6, geo.coverY, t.right + 6, t.top), Paint()..color = const Color(0xFF4F5D57));
    // Weld seams.
    final seam = Paint()
      ..color = const Color(0x55222A26)
      ..strokeWidth = 1.2;
    c.drawLine(Offset(t.right - 4, t.top + 4), Offset(t.right - 4, t.bottom - 2), seam);
    c.drawLine(Offset(t.left + 4, t.top + 4), Offset(t.left + 4, t.bottom - 2), seam);
    // LT bushings (short) on the right side.
    for (var i = 0; i < 4; i++) {
      final y = t.top + 14 + i * 12.0;
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(t.right, y - 3, 16, 7), const Radius.circular(3)), Paint()..color = const Color(0xFFE9E6DC));
    }
    // The conservator on its brackets.
    final cons = geo.conservator;
    final bracket = Paint()
      ..color = const Color(0xFF4A4F57)
      ..strokeWidth = 4;
    c.drawLine(Offset(cons.left + 10, cons.bottom), Offset(cons.left + 10, geo.coverY), bracket);
    c.drawLine(Offset(cons.right - 10, cons.bottom), Offset(cons.right - 10, geo.coverY), bracket);
    c.drawRRect(RRect.fromRectAndRadius(cons, const Radius.circular(12)),
        Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8C9C94), Color(0xFF56645E)]).createShader(cons));
    // The gauge (small dial window on the end).
    c.drawCircle(geo.gauge, 8.5, Paint()..color = const Color(0xFF2B2F33));
    c.drawCircle(geo.gauge, 6.5, Paint()..color = const Color(0xFFEDEDE6));
    final ang = look.oilLow ? math.pi * 0.85 : math.pi * 1.5;
    c.drawLine(geo.gauge, geo.gauge + Offset(math.cos(ang), math.sin(ang)) * 5.5, Paint()
      ..color = const Color(0xFFD23A2E)
      ..strokeWidth = 1.4);
    // The breather: a pipe from the conservator, the glass with the gel.
    final b = geo.breather;
    c.drawPath(
        Path()
          ..moveTo(cons.left + 2, cons.center.dy)
          ..lineTo(b.center.dx, cons.center.dy)
          ..lineTo(b.center.dx, b.top),
        Paint()
          ..color = const Color(0xFF4A4F57)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke);
    _gel(c, b, look.gel);
    // HT bushings (tall, with sheds).
    for (final x in geo.htX) {
      for (var k = 0; k < 4; k++) {
        final y = geo.coverY - 7 - k * 10.0;
        c.drawOval(Rect.fromCenter(center: Offset(x, y), width: 16 - k.toDouble(), height: 6), Paint()..color = const Color(0xFF8B5E3C));
      }
      c.drawRect(Rect.fromLTWH(x - 3, geo.coverY - 44, 6, 44), Paint()..color = const Color(0xFF9A6A45));
      c.drawCircle(Offset(x, geo.coverY - 44), 3, Paint()..color = const Color(0xFFB7BCC2));
    }
    // The nameplate.
    final np = geo.nameplate;
    c.drawRRect(RRect.fromRectAndRadius(np, const Radius.circular(2)), Paint()..color = const Color(0xFFD9DCDF));
    for (var i = 0; i < 4; i++) {
      c.drawRect(Rect.fromLTWH(np.left + 5, np.top + 5 + i * 6.0, np.width - 10 - (i.isOdd ? 12 : 0), 2), Paint()..color = const Color(0xFF6B737D));
    }
    // The drain valve.
    c.drawRect(Rect.fromCenter(center: geo.drain, width: 14, height: 8), Paint()..color = const Color(0xFF3A3F45));
    c.drawCircle(geo.drain + const Offset(0, -7), 4, Paint()..color = const Color(0xFFD23A2E));
    // The oil leak: a dark wet streak from its source, drips, the stain below.
    if (look.leak != M3DtrCheckupLeak.none) {
      final oil = Paint()
        ..color = const Color(0xCC2A1E0E)
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final Offset from;
      switch (look.leak) {
        case M3DtrCheckupLeak.gasket:
          from = Offset(geo.htX[1] + 6, geo.coverY + 1);
        case M3DtrCheckupLeak.weld:
          from = Offset(t.right - 4, t.top + 30);
        default:
          from = geo.drain + const Offset(0, 4);
      }
      final streak = Path()
        ..moveTo(from.dx, from.dy)
        ..cubicTo(from.dx + 3, from.dy + 20, from.dx - 3, t.bottom - 30, from.dx + 1, t.bottom);
      c.drawPath(streak, oil..strokeWidth = 5);
      c.drawPath(streak, Paint()
        ..color = const Color(0x55FFE9B0)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke);
      c.drawOval(Rect.fromCenter(center: Offset(from.dx, t.bottom + 3), width: 30, height: 6), Paint()..color = const Color(0xAA2A1E0E));
      for (var i = 0; i < 3; i++) {
        c.drawCircle(Offset(from.dx + 1, t.bottom + 30 + i * 28.0), 2.2, Paint()..color = const Color(0xAA2A1E0E));
      }
      c.drawOval(Rect.fromCenter(center: Offset(from.dx, g + 8), width: 64, height: 12), Paint()..color = const Color(0x882A1E0E));
    }
  }

  static void _gel(Canvas c, Rect b, M3DtrCheckupGel gel) {
    c.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(4)), Paint()..color = const Color(0xFFE8F1F4));
    final inner = b.deflate(2.5);
    final spent = m3DtrCheckupGelSpent(gel);
    // A spent gel changes from the bottom up; a band of fresh is left on top.
    final split = spent ? inner.top + inner.height * 0.28 : inner.bottom;
    c.drawRect(Rect.fromLTRB(inner.left, inner.top, inner.right, split), Paint()..color = m3DtrCheckupGelColor(m3DtrCheckupGelFresh(gel)));
    if (spent) c.drawRect(Rect.fromLTRB(inner.left, split, inner.right, inner.bottom), Paint()..color = m3DtrCheckupGelColor(gel));
    c.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(4)), Paint()
      ..color = const Color(0xFF4A4F57)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6);
    // The oil cup under it.
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(b.left - 2, b.bottom, b.width + 4, 8), const Radius.circular(3)), Paint()..color = const Color(0xFF4A4F57));
  }

  static void _label(Canvas c, String t, Offset centre, double size, Color col) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: TextStyle(fontFamily: 'Roboto', fontSize: size, fontWeight: FontWeight.w900, color: col, letterSpacing: 0.5)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(M3DtrCheckupWorldPainter old) => old.geo != geo || old.look != look || old.lit != lit;
}

/// A close-up of what the trainee looks at (or hears), drawn into the lens
/// card: 180 × 110.
class M3DtrCheckupLensPainter extends CustomPainter {
  const M3DtrCheckupLensPainter({required this.spot, required this.look});
  final M3DtrCheckupSpot spot;
  final M3DtrCheckupLook look;

  @override
  void paint(Canvas c, Size s) {
    c.drawRRect(RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(10)), Paint()..color = const Color(0xFFDDE6EA));
    switch (spot) {
      case M3DtrCheckupSpot.breather:
        _breather(c, s);
      case M3DtrCheckupSpot.gauge:
        _gauge(c, s);
      case M3DtrCheckupSpot.tank:
        _tank(c, s);
      case M3DtrCheckupSpot.nameplate:
        _plate(c, s);
      case M3DtrCheckupSpot.sound:
        _sound(c, s);
    }
  }

  void _breather(Canvas c, Size s) {
    final glass = Rect.fromLTWH(s.width / 2 - 26, 8, 52, s.height - 28);
    c.drawRect(Rect.fromLTWH(s.width / 2 - 4, 0, 8, 8), Paint()..color = const Color(0xFF4A4F57));
    c.drawRRect(RRect.fromRectAndRadius(glass, const Radius.circular(8)), Paint()..color = const Color(0xFFF4FAFC));
    final inner = glass.deflate(5);
    final spent = m3DtrCheckupGelSpent(look.gel);
    final split = spent ? inner.top + inner.height * 0.28 : inner.bottom;
    final rnd = math.Random(11);
    void beads(Rect r, Color col) {
      c.drawRect(r, Paint()..color = col.withValues(alpha: 0.85));
      for (var i = 0; i < (r.height * 1.2).round(); i++) {
        final o = Offset(r.left + rnd.nextDouble() * r.width, r.top + rnd.nextDouble() * r.height);
        c.drawCircle(o, 2.6, Paint()..color = Color.lerp(col, Colors.white, 0.35)!);
      }
    }

    beads(Rect.fromLTRB(inner.left, inner.top, inner.right, split), m3DtrCheckupGelColor(m3DtrCheckupGelFresh(look.gel)));
    if (spent) beads(Rect.fromLTRB(inner.left, split, inner.right, inner.bottom), m3DtrCheckupGelColor(look.gel));
    c.drawRRect(RRect.fromRectAndRadius(glass, const Radius.circular(8)), Paint()
      ..color = const Color(0xFF4A4F57)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(glass.left - 4, glass.bottom, glass.width + 8, 14), const Radius.circular(4)), Paint()..color = const Color(0xFF4A4F57));
  }

  void _gauge(Canvas c, Size s) {
    final ctr = Offset(s.width / 2, s.height / 2 + 4);
    const r = 46.0;
    c.drawCircle(ctr, r + 6, Paint()..color = const Color(0xFF2B2F33));
    c.drawCircle(ctr, r, Paint()..color = const Color(0xFFF4F4EE));
    // The scale: MIN on the left, MAX on the right (an arc over the top).
    final arc = Paint()
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;
    c.drawArc(Rect.fromCircle(center: ctr, radius: r - 10), math.pi * 0.8, math.pi * 0.35, false, arc..color = const Color(0xFFD23A2E));
    c.drawArc(Rect.fromCircle(center: ctr, radius: r - 10), math.pi * 1.15, math.pi * 1.05, false, arc..color = const Color(0xFF3C8C55));
    _label(c, 'MIN', ctr + const Offset(-24, 18), 10, const Color(0xFF1A1D22));
    _label(c, 'MAX', ctr + const Offset(24, 18), 10, const Color(0xFF1A1D22));
    _label(c, 'OIL', ctr + const Offset(0, 26), 9, const Color(0xFF6B737D));
    final ang = look.oilLow ? math.pi * 0.86 : math.pi * 1.62;
    c.drawLine(ctr, ctr + Offset(math.cos(ang), math.sin(ang)) * (r - 8), Paint()
      ..color = const Color(0xFF1A1D22)
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round);
    c.drawCircle(ctr, 5, Paint()..color = const Color(0xFF1A1D22));
  }

  void _tank(Canvas c, Size s) {
    // A slice of the tank: the top cover with a bushing base and its gasket,
    // the side weld seam, the drain valve at the bottom.
    final t = Rect.fromLTWH(18, 18, s.width - 36, s.height - 26);
    c.drawRect(t, Paint()..shader = const LinearGradient(colors: [Color(0xFF7E8E86), Color(0xFF5D6C65)]).createShader(t));
    c.drawRect(Rect.fromLTRB(t.left - 8, t.top - 8, t.right + 8, t.top), Paint()..color = const Color(0xFF4F5D57));
    final bx = t.left + 50;
    c.drawRect(Rect.fromLTWH(bx - 12, t.top - 14, 24, 6), Paint()..color = const Color(0xFF1A1D22)); // gasket
    c.drawRect(Rect.fromLTWH(bx - 7, 0, 14, t.top - 14), Paint()..color = const Color(0xFF9A6A45));
    final seamX = t.right - 10;
    c.drawLine(Offset(seamX, t.top + 2), Offset(seamX, t.bottom), Paint()
      ..color = const Color(0x66222A26)
      ..strokeWidth = 2.2);
    final valve = Offset(t.left + 100, t.bottom - 16);
    c.drawRect(Rect.fromCenter(center: valve, width: 26, height: 14), Paint()..color = const Color(0xFF3A3F45));
    c.drawCircle(valve + const Offset(0, -12), 7, Paint()..color = const Color(0xFFD23A2E));
    if (look.leak == M3DtrCheckupLeak.none) return;
    final from = switch (look.leak) {
      M3DtrCheckupLeak.gasket => Offset(bx + 10, t.top - 8),
      M3DtrCheckupLeak.weld => Offset(seamX, t.top + 14),
      _ => valve + const Offset(4, 8),
    };
    final streak = Path()
      ..moveTo(from.dx, from.dy)
      ..cubicTo(from.dx + 6, from.dy + 20, from.dx - 6, s.height - 30, from.dx + 2, s.height);
    c.drawPath(streak, Paint()
      ..color = const Color(0xDD2A1E0E)
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke);
    c.drawPath(streak, Paint()
      ..color = const Color(0x77FFE9B0)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke);
    c.drawCircle(from, 7, Paint()..color = const Color(0xDD2A1E0E));
  }

  void _plate(Canvas c, Size s) {
    final p = Rect.fromLTWH(10, 8, s.width - 20, s.height - 16);
    c.drawRRect(RRect.fromRectAndRadius(p, const Radius.circular(4)), Paint()..color = const Color(0xFFE4E7EA));
    c.drawRRect(RRect.fromRectAndRadius(p, const Radius.circular(4)), Paint()
      ..color = const Color(0xFF6B737D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
    for (final o in [p.topLeft + const Offset(6, 6), p.topRight + const Offset(-6, 6), p.bottomLeft + const Offset(6, -6), p.bottomRight + const Offset(-6, -6)]) {
      c.drawCircle(o, 2.4, Paint()..color = const Color(0xFF6B737D));
    }
    _label(c, 'DISTRIBUTION TRANSFORMER', Offset(p.center.dx, p.top + 14), 9, const Color(0xFF1A1D22));
    _label(c, 'kVA  ${look.kva}', Offset(p.center.dx, p.top + 36), 17, const Color(0xFF1A1D22));
    _label(c, 'HV 11000 V   LV 415 V', Offset(p.center.dx, p.top + 60), 10, const Color(0xFF1A1D22));
    _label(c, 'VECTOR GROUP  Dyn11', Offset(p.center.dx, p.top + 78), 10, const Color(0xFF1A1D22));
  }

  void _sound(Canvas c, Size s) {
    // What the ear hears: a soft steady hum, or rattling bursts.
    final mid = s.height / 2 - 6;
    final wave = Path()..moveTo(8, mid);
    final rnd = math.Random(4);
    for (var x = 8.0; x <= s.width - 8; x += 2) {
      final y = look.rattle
          ? mid + ((x ~/ 22).isEven ? (rnd.nextDouble() - 0.5) * 70 : (rnd.nextDouble() - 0.5) * 10)
          : mid + 9 * math.sin(x * 0.35);
      wave.lineTo(x, y);
    }
    c.drawPath(wave, Paint()
      ..color = look.rattle ? const Color(0xFFD23A2E) : const Color(0xFF2F6FD8)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke);
  }

  static void _label(Canvas c, String t, Offset centre, double size, Color col) => M3DtrCheckupWorldPainter._label(c, t, centre, size, col);

  @override
  bool shouldRepaint(M3DtrCheckupLensPainter old) => old.spot != spot || old.look != look;
}

/// The flash by the HT bushing when he is up on a live DTR (the deadly
/// consequence, in colour over the grey scene). Non-graphic.
class M3DtrCheckupZapPainter extends CustomPainter {
  const M3DtrCheckupZapPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final flick = v < 0.5 ? (0.65 + 0.35 * math.sin(v * 60).abs()) : (1 - (v - 0.5) * 1.2).clamp(0.4, 1.0);
    final r = 26 + 46 * Curves.easeOut.transform(v.clamp(0.0, 1.0));
    c.drawCircle(at, r, Paint()..shader = RadialGradient(colors: [Color.fromRGBO(220, 235, 255, 0.95 * flick), const Color(0x002F6FD0)]).createShader(Rect.fromCircle(center: at, radius: r)));
    final rnd = math.Random(9);
    final arc = Path()..moveTo(at.dx, at.dy - 20);
    for (var i = 1; i <= 6; i++) {
      arc.lineTo(at.dx + (rnd.nextDouble() - 0.5) * 18, at.dy - 20 + i * 9);
    }
    c.drawPath(
        arc,
        Paint()
          ..color = Color.fromRGBO(255, 255, 255, flick)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke);
    final spark = Paint()
      ..color = Color.fromRGBO(255, 214, 90, (1 - v).clamp(0.0, 1.0))
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 14; i++) {
      final a = i / 14 * math.pi * 2 + 0.3;
      final d0 = 10 + 38 * v;
      c.drawLine(at + Offset(math.cos(a) * d0, math.sin(a) * d0), at + Offset(math.cos(a) * (d0 + 12), math.sin(a) * (d0 + 12)), spark);
    }
    final white = (1 - v * 4).clamp(0.0, 1.0);
    if (white > 0) c.drawRect(Offset.zero & size, Paint()..color = Color.fromRGBO(255, 255, 255, 0.8 * white));
  }

  @override
  bool shouldRepaint(M3DtrCheckupZapPainter old) => old.v != v || old.at != at;
}
