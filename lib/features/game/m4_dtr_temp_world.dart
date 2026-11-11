import 'dart:math' as math;

import 'package:flutter/material.dart';

// The place for lesson 4.5 কাজ 2 "গরম কতটা?" (m4_dtr_temp.dart): a
// plinth-mounted distribution transformer in a fenced yard on a hot day — the
// main tank with its cooling fins on the right, the conservator with its glass
// oil gauge on top, three HT bushings (the 11 kV jumpers go up to the pole on
// the right) and the LT bushings with the LT cables going down on the left.
// The trainee stands outside the fence. Design space: 360 wide,
// [M4DtrTempGeo.height] high. Static painters only (they repaint when the play
// changes, never on a clock).

/// What is wrong with the transformer on this job.
enum M4DtrTempCase { normal, overload, fins, lowOil }

/// A close-up the player has opened.
enum M4DtrTempLook { ir, gauge, fins, load }

/// The scene's geometry (design px).
@immutable
class M4DtrTempGeo {
  const M4DtrTempGeo._(this.height, this.groundY);

  factory M4DtrTempGeo.forScene(double height, double inset) => M4DtrTempGeo._(height, height - 172 - inset * 0.4);

  final double height;
  final double groundY;

  static const fenceLeft = 134.0;
  static const fenceRight = 346.0;
  static const poleX = 338.0;

  /// The trainee's height on screen and where he stands (outside the fence).
  double get man => 86;
  static const standX = 84.0;

  Rect get plinth => Rect.fromLTRB(160, groundY - 40, 320, groundY + 2);
  Rect get tank => Rect.fromLTRB(178, groundY - 150, 284, groundY - 40);
  Rect get fins => Rect.fromLTRB(284, groundY - 140, 314, groundY - 50);
  Rect get conservator => Rect.fromLTRB(188, tank.top - 46, 270, tank.top - 20);

  /// The glass oil gauge at the conservator's left end.
  Offset get gauge => Offset(conservator.left + 2, conservator.center.dy);

  /// Where the clamp meter goes on the LT cables (the load check).
  Offset get load => Offset(166, groundY - 84);

  /// The LT bushings (left, on the tank top) and the HT bushings (right).
  List<double> get ltX => const [190, 202, 214, 226];
  List<double> get htX => const [240, 256, 272];

  /// What a tap at [p] lands on (spots first, then the tank).
  M4DtrTempLook? spotAt(Offset p) {
    if ((p - gauge).distance < 26) return M4DtrTempLook.gauge;
    if (fins.inflate(10).contains(p)) return M4DtrTempLook.fins;
    if ((p - load).distance < 26) return M4DtrTempLook.load;
    return null;
  }

  bool onTank(Offset p) => tank.inflate(6).contains(p) || fins.contains(p);

  @override
  bool operator ==(Object other) => other is M4DtrTempGeo && other.height == height && other.groundY == groundY;

  @override
  int get hashCode => Object.hash(height, groundY);
}

/// The yard: sky with a hard sun, far houses, the fenced plinth and the DTR.
class M4DtrTempWorldPainter extends CustomPainter {
  const M4DtrTempWorldPainter({required this.geo, required this.kase});

  final M4DtrTempGeo geo;
  final M4DtrTempCase kase;

  bool get _hot => kase != M4DtrTempCase.normal;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final sky = Rect.fromLTWH(0, 0, 360, g.groundY);
    c.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5E9BD6), Color(0xFFB7D6EE), Color(0xFFF3EBD3)],
        ).createShader(sky),
    );
    // A hard summer sun.
    final sun = Offset(64, math.max(110.0, g.groundY - 360));
    c.drawCircle(sun, 46, Paint()..color = const Color(0x33FFE9A0));
    c.drawCircle(sun, 30, Paint()..color = const Color(0x66FFE08A));
    c.drawCircle(sun, 18, Paint()..color = const Color(0xFFFFF1B8));
    // Far houses and trees.
    final far = Paint()..color = const Color(0xFF9DB08A);
    final farPath = Path()..moveTo(0, g.groundY - 44);
    for (var x = 0.0; x <= 360; x += 30) {
      farPath.quadraticBezierTo(x + 15, g.groundY - 70 - (x % 90 == 0 ? 12 : 0), x + 30, g.groundY - 44);
    }
    farPath
      ..lineTo(360, g.groundY)
      ..lineTo(0, g.groundY)
      ..close();
    c.drawPath(farPath, far);
    final house = Paint()..color = const Color(0xFFD8C7A6);
    for (final (x, w, h) in [(8.0, 40.0, 34.0), (52.0, 30.0, 26.0), (98.0, 34.0, 30.0)]) {
      c.drawRect(Rect.fromLTWH(x, g.groundY - 30 - h, w, h), house);
      c.drawRect(Rect.fromLTWH(x + w * 0.35, g.groundY - 30 - h * 0.55, w * 0.25, h * 0.3), Paint()..color = const Color(0xFF6F5B3E));
    }
    // Ground and the gravel yard.
    final ground = Rect.fromLTWH(0, g.groundY - 30, 360, size.height - g.groundY + 30);
    c.drawRect(
      ground,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFA9A27A), Color(0xFF7D7650)],
        ).createShader(ground),
    );
    c.drawRect(Rect.fromLTRB(M4DtrTempGeo.fenceLeft, g.groundY - 6, M4DtrTempGeo.fenceRight, g.groundY + 30), Paint()..color = const Color(0xFF9C978C));
    final peb = Paint()..color = const Color(0x553A3428);
    final rnd = math.Random(5);
    for (var i = 0; i < 40; i++) {
      c.drawCircle(Offset(M4DtrTempGeo.fenceLeft + rnd.nextDouble() * 212, g.groundY - 4 + rnd.nextDouble() * 32), 1.1 + rnd.nextDouble() * 1.3, peb);
    }

    // The pole on the right that feeds it.
    c.drawRect(Rect.fromLTRB(M4DtrTempGeo.poleX - 6, g.groundY - 330, M4DtrTempGeo.poleX + 6, g.groundY), Paint()..color = const Color(0xFFA9A59B));
    c.drawRect(Rect.fromLTRB(296, g.groundY - 322, 360, g.groundY - 314), Paint()..color = const Color(0xFF4F555C));

    _plinthAndTank(c);
    _fence(c);
  }

  void _plinthAndTank(Canvas c) {
    final g = geo;
    // Plinth.
    c.drawRect(g.plinth, Paint()..color = const Color(0xFFBDB7A8));
    c.drawRect(Rect.fromLTRB(g.plinth.left, g.plinth.top, g.plinth.right, g.plinth.top + 4), Paint()..color = const Color(0xFFD9D4C6));
    // Tank.
    final tank = RRect.fromRectAndRadius(g.tank, const Radius.circular(4));
    c.drawRRect(
      tank,
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFF8C9A8E), Color(0xFF6C7A6E), Color(0xFF55615A)]).createShader(g.tank),
    );
    c.drawRect(Rect.fromLTRB(g.tank.left - 3, g.tank.top - 4, g.tank.right + 3, g.tank.top + 3), Paint()..color = const Color(0xFF4D5852));
    // Nameplate.
    final plate = Rect.fromLTWH(g.tank.left + 14, g.tank.top + 26, 30, 20);
    c.drawRect(plate, Paint()..color = const Color(0xFFE6E2D6));
    final ink = Paint()..color = const Color(0xFF6B675C);
    for (var k = 0; k < 4; k++) {
      c.drawRect(Rect.fromLTWH(plate.left + 3, plate.top + 3 + k * 4.2, 24 - k * 3.0, 1.4), ink);
    }
    // Drain valve and the earth strip.
    c.drawRect(Rect.fromLTWH(g.tank.left + 60, g.tank.bottom - 14, 12, 8), Paint()..color = const Color(0xFF3E4642));
    c.drawLine(
      Offset(g.tank.left + 4, g.tank.bottom - 6),
      Offset(g.tank.left - 8, g.groundY + 2),
      Paint()
        ..color = const Color(0xFF6E5A2A)
        ..strokeWidth = 2.4,
    );
    // Cooling fins (the radiator).
    final fin = Paint()..color = const Color(0xFF6E7C70);
    final edge = Paint()..color = const Color(0xFF4A5650);
    for (var x = g.fins.left; x < g.fins.right - 1; x += 6) {
      c.drawRect(Rect.fromLTRB(x, g.fins.top, x + 4, g.fins.bottom), fin);
      c.drawRect(Rect.fromLTRB(x + 3.2, g.fins.top, x + 4, g.fins.bottom), edge);
    }
    c.drawRect(Rect.fromLTRB(g.fins.left, g.fins.top - 4, g.fins.right, g.fins.top), edge);
    c.drawRect(Rect.fromLTRB(g.fins.left, g.fins.bottom, g.fins.right, g.fins.bottom + 4), edge);
    if (kase == M4DtrTempCase.fins) _creepers(c, g.fins);

    // Conservator and its pipe; the glass oil gauge at its left end.
    c.drawRect(Rect.fromLTRB(g.conservator.right - 18, g.conservator.bottom, g.conservator.right - 12, g.tank.top - 4), Paint()..color = const Color(0xFF4D5852));
    c.drawRect(Rect.fromLTRB(g.conservator.left + 10, g.conservator.bottom, g.conservator.left + 14, g.tank.top - 4), Paint()..color = const Color(0xFF4D5852));
    final cons = RRect.fromRectAndRadius(g.conservator, const Radius.circular(13));
    c.drawRRect(
      cons,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF9AA89C), Color(0xFF5F6D63)],
        ).createShader(g.conservator),
    );
    final glass = Rect.fromCenter(center: g.gauge, width: 7, height: 20);
    c.drawRect(glass.inflate(1.6), Paint()..color = const Color(0xFF2F3632));
    c.drawRect(glass, Paint()..color = const Color(0xFFE9F0EE));
    final level = kase == M4DtrTempCase.lowOil ? 0.12 : 0.55;
    c.drawRect(Rect.fromLTRB(glass.left, glass.bottom - glass.height * level, glass.right, glass.bottom), Paint()..color = const Color(0xFFB8862B));
    // Breather.
    c.drawRect(Rect.fromLTWH(g.conservator.right - 4, g.conservator.center.dy - 2, 8, 4), Paint()..color = const Color(0xFF4D5852));

    // HT bushings and jumpers to the pole.
    final por = Paint()..color = const Color(0xFF8A4B2A);
    final wire = Paint()
      ..color = const Color(0xFF2E3238)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    for (final (i, x) in g.htX.indexed) {
      final base = g.tank.top - 4;
      for (var k = 0; k < 4; k++) {
        c.drawOval(Rect.fromCenter(center: Offset(x, base - 6 - k * 8), width: 12 - k * 1.2, height: 5), por);
      }
      c.drawRect(Rect.fromLTWH(x - 2, base - 36, 4, 36), por);
      c.drawPath(
        Path()
          ..moveTo(x, base - 38)
          ..quadraticBezierTo(x + 30, base - 120 - i * 10, M4DtrTempGeo.poleX - 30 + i * 14, g.groundY - 316),
        wire,
      );
    }
    // LT bushings and the LT cables going down on the left.
    final cable = Paint()
      ..color = const Color(0xFF1C1F24)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    for (final (i, x) in g.ltX.indexed) {
      final base = g.tank.top - 4;
      c.drawRect(Rect.fromLTWH(x - 3, base - 14, 6, 14), por);
      c.drawCircle(Offset(x, base - 15), 2.4, Paint()..color = const Color(0xFFB08D57));
      c.drawPath(
        Path()
          ..moveTo(x, base - 16)
          ..quadraticBezierTo(x - 6, base - 18, 168 - i * 3, base + 10)
          ..lineTo(164 - i * 3, g.groundY + 2),
        cable,
      );
    }

    if (_hot) {
      // Heat shimmer over the top (a static sign of a very hot tank).
      final heat = Paint()
        ..color = const Color(0x55FF8A3D)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      for (var k = 0; k < 4; k++) {
        final x = g.tank.left + 16 + k * 24.0;
        final p = Path()..moveTo(x, g.tank.top - 8);
        for (var s = 0; s < 3; s++) {
          final y = g.tank.top - 8 - s * 12.0;
          p.quadraticBezierTo(x + (s.isEven ? 6 : -6), y - 6, x, y - 12);
        }
        c.drawPath(p, heat);
      }
      c.drawRRect(tank, Paint()..color = const Color(0x18FF5A1F));
    }
  }

  void _creepers(Canvas c, Rect r) {
    final vine = Paint()
      ..color = const Color(0xFF2F6B2A)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final leaf = Paint()..color = const Color(0xFF3F8A34);
    final leaf2 = Paint()..color = const Color(0xFF2C6E28);
    final rnd = math.Random(11);
    for (var k = 0; k < 5; k++) {
      final x0 = r.left + 2 + k * 6.5;
      final p = Path()..moveTo(x0, r.bottom + 6);
      for (var y = r.bottom; y > r.top - 6; y -= 14) {
        p.quadraticBezierTo(x0 + (rnd.nextBool() ? 6 : -6), y - 7, x0 + rnd.nextDouble() * 4 - 2, y - 14);
      }
      c.drawPath(p, vine);
    }
    for (var i = 0; i < 46; i++) {
      final o = Offset(r.left - 4 + rnd.nextDouble() * (r.width + 8), r.top - 4 + rnd.nextDouble() * (r.height + 10));
      c.drawOval(Rect.fromCenter(center: o, width: 8, height: 5), i.isEven ? leaf : leaf2);
    }
  }

  void _fence(Canvas c) {
    final g = geo;
    final top = g.groundY - 96;
    final post = Paint()..color = const Color(0xFF5C6168);
    for (final x in [M4DtrTempGeo.fenceLeft, 240.0, M4DtrTempGeo.fenceRight]) {
      c.drawRect(Rect.fromLTRB(x - 2.5, top, x + 2.5, g.groundY + 4), post);
    }
    final mesh = Paint()
      ..color = const Color(0x667D838A)
      ..strokeWidth = 0.9;
    for (var x = M4DtrTempGeo.fenceLeft; x < M4DtrTempGeo.fenceRight; x += 9) {
      c.drawLine(Offset(x, top), Offset(x + 9, top + 9), mesh);
    }
    c.drawLine(Offset(M4DtrTempGeo.fenceLeft, top), Offset(M4DtrTempGeo.fenceRight, top), post..strokeWidth = 2);
    // The fence's front run, low and see-through, so the DTR stays in view.
    final front = Paint()
      ..color = const Color(0x557D838A)
      ..strokeWidth = 1;
    for (var x = M4DtrTempGeo.fenceLeft; x < M4DtrTempGeo.fenceRight; x += 12) {
      c.drawLine(Offset(x, g.groundY - 20), Offset(x + 12, g.groundY + 2), front);
      c.drawLine(Offset(x + 12, g.groundY - 20), Offset(x, g.groundY + 2), front);
    }
    c.drawLine(Offset(M4DtrTempGeo.fenceLeft, g.groundY - 20), Offset(M4DtrTempGeo.fenceRight, g.groundY - 20), Paint()
      ..color = const Color(0xFF5C6168)
      ..strokeWidth = 1.6);
    // Danger board on the left post.
    final board = Rect.fromLTWH(M4DtrTempGeo.fenceLeft - 14, top + 14, 28, 22);
    c.drawRect(board, Paint()..color = const Color(0xFFF4F1E8));
    c.drawRect(
      board,
      Paint()
        ..color = const Color(0xFFC0392B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
    final bolt = Path()
      ..moveTo(board.center.dx + 2, board.top + 3)
      ..lineTo(board.center.dx - 4, board.center.dy + 1)
      ..lineTo(board.center.dx + 1, board.center.dy + 1)
      ..lineTo(board.center.dx - 2, board.bottom - 3)
      ..lineTo(board.center.dx + 5, board.center.dy - 2)
      ..lineTo(board.center.dx, board.center.dy - 2)
      ..close();
    c.drawPath(bolt, Paint()..color = const Color(0xFFC0392B));
  }

  @override
  bool shouldRepaint(M4DtrTempWorldPainter old) => old.geo != geo || old.kase != kase;
}

/// The IR thermometer in the trainee's hand and its red aiming dot on [aim].
class M4DtrTempGunPainter extends CustomPainter {
  const M4DtrTempGunPainter({required this.hand, this.aim});
  final Offset hand;
  final Offset? aim;

  @override
  void paint(Canvas c, Size size) {
    final a = aim;
    if (a != null) {
      final d = a - hand;
      final n = (d.distance / 7).floor();
      final dot = Paint()..color = const Color(0x99FF2A2A);
      for (var i = 2; i < n; i += 2) {
        c.drawCircle(hand + d * (i / n), 0.9, dot);
      }
      c.drawCircle(a, 4, Paint()..color = const Color(0x66FF2A2A));
      c.drawCircle(a, 2, Paint()..color = const Color(0xFFFF2A2A));
    }
    final body = Paint()..color = const Color(0xFFF2B233);
    final dark = Paint()..color = const Color(0xFF2B2F36);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(hand.dx - 4, hand.dy - 6, 16, 7), const Radius.circular(2)), body);
    c.drawRect(Rect.fromLTWH(hand.dx - 3, hand.dy, 5, 8), dark);
    c.drawRect(Rect.fromLTWH(hand.dx + 11, hand.dy - 5, 2, 5), dark);
  }

  @override
  bool shouldRepaint(M4DtrTempGunPainter old) => old.hand != hand || old.aim != aim;
}

/// A close-up card: the IR thermometer's screen, the oil gauge, the fins, or
/// the clamp meter on the LT cables with the nameplate.
class M4DtrTempLookPainter extends CustomPainter {
  const M4DtrTempLookPainter({required this.look, required this.kase});
  final M4DtrTempLook look;
  final M4DtrTempCase kase;

  bool get _hot => kase != M4DtrTempCase.normal;

  void _text(Canvas c, String s, Offset at, {double size = 11, Color color = const Color(0xFF1B1F24), bool centre = false, FontWeight w = FontWeight.w800}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(fontSize: size, fontWeight: w, color: color),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, centre ? at - Offset(tp.width / 2, tp.height / 2) : at);
  }

  @override
  void paint(Canvas c, Size s) {
    switch (look) {
      case M4DtrTempLook.ir:
        _ir(c, s);
      case M4DtrTempLook.gauge:
        _gauge(c, s);
      case M4DtrTempLook.fins:
        _fins(c, s);
      case M4DtrTempLook.load:
        _load(c, s);
    }
  }

  void _ir(Canvas c, Size s) {
    // The gun's body and screen; the screen shows a heat bar with a pointer.
    final body = RRect.fromRectAndRadius(Rect.fromLTWH(10, 10, s.width - 20, s.height - 20), const Radius.circular(14));
    c.drawRRect(body, Paint()..color = const Color(0xFFF2B233));
    final screen = Rect.fromLTWH(24, 22, s.width - 48, s.height - 44);
    c.drawRRect(RRect.fromRectAndRadius(screen, const Radius.circular(6)), Paint()..color = const Color(0xFF14202B));
    final bar = Rect.fromLTWH(screen.left + 12, screen.center.dy - 8, screen.width - 24, 16);
    c.drawRRect(
      RRect.fromRectAndRadius(bar, const Radius.circular(4)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF2E6FD8), Color(0xFF2FB36A), Color(0xFFF1C40F), Color(0xFFF2853A), Color(0xFFD62B1F)],
        ).createShader(bar),
    );
    final f = _hot ? 0.9 : 0.5;
    final x = bar.left + bar.width * f;
    final tri = Path()
      ..moveTo(x, bar.top - 2)
      ..lineTo(x - 7, bar.top - 14)
      ..lineTo(x + 7, bar.top - 14)
      ..close();
    c.drawPath(tri, Paint()..color = const Color(0xFFFFFFFF));
    c.drawRect(Rect.fromLTWH(x - 1.5, bar.top - 2, 3, bar.height + 4), Paint()..color = const Color(0xFFFFFFFF));
    _text(c, 'IR', Offset(screen.left + 8, screen.top + 6), size: 10, color: const Color(0xFF9FB4C8));
    _text(c, '°C', Offset(screen.right - 22, screen.top + 6), size: 10, color: const Color(0xFF9FB4C8));
  }

  void _gauge(Canvas c, Size s) {
    // The conservator end with its glass gauge: Max, 30°C and Min marks.
    final cons = RRect.fromRectAndRadius(Rect.fromLTWH(8, 14, s.width - 16, s.height - 28), const Radius.circular(40));
    c.drawRRect(cons, Paint()..color = const Color(0xFF7E8C80));
    final glass = Rect.fromLTWH(s.width * 0.42, 24, 20, s.height - 48);
    c.drawRect(glass.inflate(4), Paint()..color = const Color(0xFF2F3632));
    c.drawRect(glass, Paint()..color = const Color(0xFFEFF5F3));
    final low = kase == M4DtrTempCase.lowOil;
    final level = low ? 0.1 : 0.52;
    c.drawRect(Rect.fromLTRB(glass.left, glass.bottom - glass.height * level, glass.right, glass.bottom), Paint()..color = const Color(0xFFB8862B));
    final mark = Paint()
      ..color = const Color(0xFF111111)
      ..strokeWidth = 2;
    for (final (label, f) in [('Max', 0.85), ('30°C', 0.5), ('Min', 0.2)]) {
      final y = glass.bottom - glass.height * f;
      c.drawLine(Offset(glass.right + 4, y), Offset(glass.right + 14, y), mark);
      _text(c, label, Offset(glass.right + 18, y - 7), size: 11, color: const Color(0xFFF4F1E8));
    }
    if (low) {
      // An oil stain running down from the drain end.
      c.drawOval(Rect.fromLTWH(18, s.height - 30, 40, 10), Paint()..color = const Color(0x88553A10));
    }
  }

  void _fins(Canvas c, Size s) {
    c.drawRect(Rect.fromLTWH(8, 8, s.width - 16, s.height - 16), Paint()..color = const Color(0xFFDCE6EA));
    final fin = Paint()..color = const Color(0xFF6E7C70);
    final edge = Paint()..color = const Color(0xFF46524B);
    for (var x = 18.0; x < s.width - 22; x += 14) {
      c.drawRect(Rect.fromLTWH(x, 16, 10, s.height - 32), fin);
      c.drawRect(Rect.fromLTWH(x + 8, 16, 2, s.height - 32), edge);
    }
    if (kase == M4DtrTempCase.fins) {
      final rnd = math.Random(4);
      final vine = Paint()
        ..color = const Color(0xFF2F6B2A)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      for (var k = 0; k < 6; k++) {
        final x0 = 22.0 + k * 28;
        final p = Path()..moveTo(x0, s.height - 8);
        for (var y = s.height - 8; y > 10; y -= 20) {
          p.quadraticBezierTo(x0 + (rnd.nextBool() ? 12 : -12), y - 10, x0 + rnd.nextDouble() * 6 - 3, y - 20);
        }
        c.drawPath(p, vine);
      }
      for (var i = 0; i < 70; i++) {
        final o = Offset(10 + rnd.nextDouble() * (s.width - 20), 10 + rnd.nextDouble() * (s.height - 20));
        c.drawOval(Rect.fromCenter(center: o, width: 16, height: 9), Paint()..color = i.isEven ? const Color(0xFF3F8A34) : const Color(0xFF2C6E28));
      }
    }
  }

  void _load(Canvas c, Size s) {
    // Left: the nameplate. Right: the clamp meter's reading on each phase.
    final plate = Rect.fromLTWH(8, 12, s.width * 0.42, s.height - 24);
    c.drawRRect(RRect.fromRectAndRadius(plate, const Radius.circular(6)), Paint()..color = const Color(0xFFE6E2D6));
    _text(c, 'DTR', Offset(plate.left + 8, plate.top + 6), size: 10, color: const Color(0xFF5A564C));
    _text(c, kM4DtrTempKva, Offset(plate.left + 8, plate.top + 22), size: 14, w: FontWeight.w900);
    _text(c, 'LV $kM4DtrTempLv', Offset(plate.left + 8, plate.top + 44), size: 11);
    _text(c, 'I  $kM4DtrTempRatedA A', Offset(plate.left + 8, plate.top + 62), size: 12, w: FontWeight.w900);
    final meter = Rect.fromLTWH(s.width * 0.48, 8, s.width * 0.5, s.height - 16);
    c.drawRRect(RRect.fromRectAndRadius(meter, const Radius.circular(10)), Paint()..color = const Color(0xFFE2B42A));
    final screen = Rect.fromLTWH(meter.left + 8, meter.top + 10, meter.width - 16, meter.height - 20);
    c.drawRRect(RRect.fromRectAndRadius(screen, const Radius.circular(5)), Paint()..color = const Color(0xFFBFD3B6));
    final amps = kase == M4DtrTempCase.overload ? kM4DtrTempOverA : kM4DtrTempNormalA;
    for (final (i, ph) in const ['R', 'Y', 'B'].indexed) {
      final y = screen.top + 8 + i * (screen.height - 16) / 3;
      _text(c, ph, Offset(screen.left + 6, y), size: 12, color: const Color(0xFF1F2A1C));
      _text(c, '${amps[i]} A', Offset(screen.left + 26, y), size: 15, w: FontWeight.w900, color: const Color(0xFF1F2A1C));
    }
  }

  @override
  bool shouldRepaint(M4DtrTempLookPainter old) => old.look != look || old.kase != kase;
}

/// The nameplate and the clamp readings (flagged: the lesson says only
/// "লোড পরীক্ষা করুন" — a 100 kVA DTR at the LV 415 V that lesson 3.6's
/// nameplate shows: 100 000 / (√3 × 415) ≈ 139 A full load).
const kM4DtrTempKva = '100 kVA';
const kM4DtrTempLv = '415 V';
const kM4DtrTempRatedA = 139;
const kM4DtrTempOverA = [168, 174, 161];
const kM4DtrTempNormalA = [96, 104, 99];

/// The flash when a hand meets the tank (deadly), drawn at [at].
class M4DtrTempZapPainter extends CustomPainter {
  const M4DtrTempZapPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final r = 10 + 46 * v;
    c.drawCircle(at, r * 1.6, Paint()..color = Color.fromRGBO(255, 120, 40, 0.22 * (1 - v * 0.5)));
    c.drawCircle(at, r, Paint()..color = Color.fromRGBO(255, 210, 120, 0.5 * (1 - v * 0.4)));
    final bolt = Paint()
      ..color = const Color(0xFFFFF4C2)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;
    final rnd = math.Random(7);
    for (var k = 0; k < 6; k++) {
      final a = k * math.pi / 3 + 0.3;
      var p = at;
      final path = Path()..moveTo(p.dx, p.dy);
      for (var s = 0; s < 3; s++) {
        p += Offset(math.cos(a + rnd.nextDouble() * 0.6 - 0.3), math.sin(a + rnd.nextDouble() * 0.6 - 0.3)) * (r / 3);
        path.lineTo(p.dx, p.dy);
      }
      c.drawPath(path, bolt);
    }
  }

  @override
  bool shouldRepaint(M4DtrTempZapPainter old) => old.at != at || old.v != v;
}
