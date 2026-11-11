import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The place of the line patrol (lesson 3.2 "ইনসুলেটর পরিচিতি", কাজ 2): a
// drawn, layered scene — the day sky, a far tree line and the line of poles
// going away over the fields, the lane, the pole of this round rising from
// the lane, and the trainee on the ground with his binoculars. Over the top:
// the binocular view (two lenses), the pole's head close up — an 11 kV
// cross-arm with three pin insulators, a 33 kV cross-arm with three strings of
// three discs (lesson pro tip 1: three discs = 33 kV), or an LT pole with four
// shackle insulators on D-irons. No words in the art.
//
// Design: 360 wide × the scene's height; the lens sits under the header, the
// ground row follows the bottom of the screen (a tall phone gets more sky).

/// Which pole the round is at.
enum M3InsulatorPatrolKind { pin, disc, shackle }

/// What an insulator is made of (lesson point 1 and pro tip 3).
enum M3InsulatorPatrolBody { porcelain, glass, polymer }

/// What can be wrong with one (lesson 3.2: daily checks, myths, pro tips).
enum M3InsulatorPatrolFault {
  /// A hairline crack (point 4's daily check).
  crack,

  /// A corner / shed broken off (myth 1).
  chipped,

  /// Black marks (point 1's daily check: "কালচে দাগ").
  burnt,

  /// A bird's nest and droppings (pro tip 4).
  bird,

  /// A salt / dust layer (pro tip 2).
  salt,

  /// A toughened glass disc gone to pieces (myth 2).
  shattered,

  /// A shackle worn sharp (point 3's daily check).
  sharp,
}

/// One insulator on the pole's head.
@immutable
class M3InsulatorPatrolUnit {
  const M3InsulatorPatrolUnit(this.body, [this.fault]);
  final M3InsulatorPatrolBody body;
  final M3InsulatorPatrolFault? fault;

  bool get bad => fault != null;

  @override
  bool operator ==(Object other) => other is M3InsulatorPatrolUnit && other.body == body && other.fault == fault;

  @override
  int get hashCode => Object.hash(body, fault);
}

/// Where things stand (design px, 360 wide).
@immutable
class M3InsulatorPatrolGeo {
  const M3InsulatorPatrolGeo({required this.height, required this.groundY});

  factory M3InsulatorPatrolGeo.forScene(double h, double inset) =>
      M3InsulatorPatrolGeo(height: h, groundY: (h - 210 - inset).clamp(470.0, 760.0));

  final double height;
  final double groundY;

  double get horizonY => groundY - 96;

  /// The binocular view: two lenses.
  static const lensCy = 228.0;
  static const lensR = 118.0;
  static const lensL = Offset(124, lensCy);
  static const lensRt = Offset(236, lensCy);

  /// The view's outline (both lenses).
  static Path lensPath() => Path.combine(
        PathOperation.union,
        Path()..addOval(Rect.fromCircle(center: lensL, radius: lensR)),
        Path()..addOval(Rect.fromCircle(center: lensRt, radius: lensR)),
      );

  static bool inLens(Offset p) => (p - lensL).distance <= lensR || (p - lensRt).distance <= lensR;

  static int count(M3InsulatorPatrolKind k) => switch (k) {
        M3InsulatorPatrolKind.pin => 3,
        M3InsulatorPatrolKind.disc => 9,
        M3InsulatorPatrolKind.shackle => 4,
      };

  /// The centre of insulator [i] in the lens.
  static Offset unitCentre(M3InsulatorPatrolKind k, int i) => switch (k) {
        M3InsulatorPatrolKind.pin => Offset(const [92.0, 180.0, 268.0][i], lensCy + 6),
        M3InsulatorPatrolKind.disc => Offset(const [84.0, 180.0, 276.0][i ~/ 3], lensCy - 66 + (i % 3) * 48),
        M3InsulatorPatrolKind.shackle => Offset(204, lensCy - 72 + i * 48),
      };

  /// The insulator's drawn body.
  static Rect unitBody(M3InsulatorPatrolKind k, int i) => Rect.fromCenter(
        center: unitCentre(k, i),
        width: switch (k) {
          M3InsulatorPatrolKind.pin => 50,
          M3InsulatorPatrolKind.disc => 60,
          M3InsulatorPatrolKind.shackle => 40,
        },
        height: switch (k) {
          M3InsulatorPatrolKind.pin => 58,
          M3InsulatorPatrolKind.disc => 22,
          M3InsulatorPatrolKind.shackle => 30,
        },
      );

  /// Where a tap reaches insulator [i] (≥ 48 design px each way).
  static Rect unitHit(M3InsulatorPatrolKind k, int i) => Rect.fromCenter(
        center: unitCentre(k, i),
        width: switch (k) {
          M3InsulatorPatrolKind.pin => 78,
          M3InsulatorPatrolKind.disc => 78,
          M3InsulatorPatrolKind.shackle => 92,
        },
        height: switch (k) {
          M3InsulatorPatrolKind.pin => 84,
          M3InsulatorPatrolKind.disc => 48,
          M3InsulatorPatrolKind.shackle => 48,
        },
      );

  /// The pole of this round (its foot in the lane; it rises into the view).
  double get poleX => 236;

  /// The trainee's box (feet on the ground, left of the pole).
  Rect get trainee => Rect.fromLTWH(26, groundY - 196, 98, 196);

  @override
  bool operator ==(Object other) => other is M3InsulatorPatrolGeo && other.height == height && other.groundY == groundY;

  @override
  int get hashCode => Object.hash(height, groundY);
}

// ============================================================================
// The land (static per round)
// ============================================================================

class M3InsulatorPatrolWorldPainter extends CustomPainter {
  const M3InsulatorPatrolWorldPainter({required this.geo, required this.kind});

  final M3InsulatorPatrolGeo geo;
  final M3InsulatorPatrolKind kind;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final g = geo.groundY;
    final hz = geo.horizonY;
    // Sky (clear day).
    final sky = Rect.fromLTWH(0, 0, w, hz + 4);
    c.drawRect(sky, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3F79B5), Color(0xFF8EBEE3), Color(0xFFE7F1F2)]).createShader(sky));
    final cloud = Paint()..color = const Color(0x66FFFFFF);
    for (final (x, y, r) in [(40.0, hz - 120, 18.0), (64.0, hz - 128, 24.0), (92.0, hz - 118, 16.0), (300.0, hz - 150, 16.0), (322.0, hz - 158, 22.0)]) {
      c.drawCircle(Offset(x, y), r, cloud);
    }
    // Far tree line.
    final far = Path()..moveTo(0, hz);
    for (var x = 0.0; x <= w; x += 16) {
      far.lineTo(x, hz - 14 - 9 * math.sin(x * 0.06) - 5 * math.cos(x * 0.21));
    }
    far
      ..lineTo(w, hz + 2)
      ..lineTo(0, hz + 2)
      ..close();
    c.drawPath(far, Paint()..color = const Color(0xFF4C7A52));
    // Fields.
    final field = Rect.fromLTWH(0, hz, w, g - hz);
    c.drawRect(field, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF86A85C), Color(0xFF5F8444)]).createShader(field));
    // The line going away: smaller poles towards the horizon, wires between.
    final wire = Paint()
      ..color = const Color(0xFF2A2F36)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final poles = <(double, double, double)>[]; // x, foot y, height
    for (var i = 0; i < 4; i++) {
      final t = i / 4;
      poles.add((geo.poleX - 64 - 150 * t * (1.4 - t * 0.6), g - 10 - (g - hz - 10) * (0.55 + 0.45 * t) * 0.5 - 6, 150 * (1 - t * 0.78)));
    }
    final far2 = Paint()..color = const Color(0xFF9A9A92);
    double? lx, ly;
    for (final (x, fy, ph) in poles) {
      c.drawRect(Rect.fromLTRB(x - ph * 0.025, fy - ph, x + ph * 0.025, fy), far2);
      c.drawRect(Rect.fromLTRB(x - ph * 0.14, fy - ph * 0.94, x + ph * 0.14, fy - ph * 0.94 + math.max(1.5, ph * 0.02)), Paint()..color = const Color(0xFF4A4F57));
      if (lx != null) c.drawLine(Offset(lx, ly!), Offset(x, fy - ph * 0.95), wire);
      lx = x;
      ly = fy - ph * 0.95;
    }
    // The lane to the bottom.
    final lane = Rect.fromLTWH(0, g, w, size.height - g);
    c.drawRect(lane, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFB79D74), Color(0xFF8C7556)]).createShader(lane));
    final pebble = Paint()..color = const Color(0x33000000);
    final rnd = math.Random(5);
    for (var i = 0; i < 24; i++) {
      c.drawCircle(Offset(rnd.nextDouble() * w, g + 6 + rnd.nextDouble() * (size.height - g - 10)), 1.2 + rnd.nextDouble() * 1.6, pebble);
    }
    // This round's pole: from the lane up into the view (PCC grey; an LT pole
    // is a little thinner).
    final px = geo.poleX;
    final half = kind == M3InsulatorPatrolKind.shackle ? 8.0 : 10.0;
    const top = M3InsulatorPatrolGeo.lensCy + 60;
    final pole = Path()
      ..moveTo(px - half + 3, top)
      ..lineTo(px + half - 3, top)
      ..lineTo(px + half, g + 4)
      ..lineTo(px - half, g + 4)
      ..close();
    c.drawPath(pole, Paint()..shader = const LinearGradient(colors: [Color(0xFFC4C4BC), Color(0xFF8D8D86)]).createShader(Rect.fromLTRB(px - half, top, px + half, g)));
    // Its wires leaving (towards the far poles).
    final (fx, fy, fh) = poles.first;
    for (var i = 0; i < 3; i++) {
      c.drawLine(Offset(px - 30 + i * 30, top + 6), Offset(fx - fh * 0.12 + i * fh * 0.12, fy - fh * 0.94), wire);
    }
    c.drawOval(Rect.fromCenter(center: Offset(px, g + 4), width: 44, height: 8), Paint()..color = const Color(0x33000000));
  }

  @override
  bool shouldRepaint(M3InsulatorPatrolWorldPainter old) => old.geo != geo || old.kind != kind;
}

// ============================================================================
// The binocular view (the pole's head close up)
// ============================================================================

class M3InsulatorPatrolLensPainter extends CustomPainter {
  const M3InsulatorPatrolLensPainter({required this.kind, required this.units, this.marks = const {}, this.reveal = false});

  final M3InsulatorPatrolKind kind;
  final List<M3InsulatorPatrolUnit> units;

  /// Insulators the trainee has marked (a red ring).
  final Set<int> marks;

  /// After the round: the faults he missed get a dashed amber ring.
  final bool reveal;

  static const _glazeTop = Color(0xFFA35A35);
  static const _glazeBot = Color(0xFF5E2D18);

  @override
  void paint(Canvas c, Size size) {
    final lens = M3InsulatorPatrolGeo.lensPath();
    final bounds = lens.getBounds();
    // The rim's shadow.
    c.drawPath(lens.shift(const Offset(0, 5)), Paint()..color = const Color(0x55000000));
    c.save();
    c.clipPath(lens);
    // The magnified sky.
    c.drawRect(bounds, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF6FA6D8), Color(0xFFBFDDF2)]).createShader(bounds));
    switch (kind) {
      case M3InsulatorPatrolKind.pin:
        _pinHead(c);
      case M3InsulatorPatrolKind.disc:
        _discHead(c);
      case M3InsulatorPatrolKind.shackle:
        _shackleHead(c);
    }
    // The faults that sit beside an insulator (a nest).
    for (final (i, u) in units.indexed) {
      if (u.fault == M3InsulatorPatrolFault.bird) _nest(c, i);
    }
    // Marks.
    for (final (i, u) in units.indexed) {
      final hit = M3InsulatorPatrolGeo.unitHit(kind, i);
      final r = math.min(hit.width, hit.height) / 2 + (kind == M3InsulatorPatrolKind.pin ? 0 : 4);
      if (marks.contains(i)) {
        c.drawCircle(hit.center, r, Paint()
          ..color = const Color(0xFFE5322B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.4);
      } else if (reveal && u.bad) {
        _dashedCircle(c, hit.center, r, const Color(0xFFFFB020));
      }
    }
    // Lens glare and a soft dark edge.
    c.drawCircle(M3InsulatorPatrolGeo.lensL + const Offset(-40, -54), 34, Paint()..color = const Color(0x18FFFFFF));
    for (final o in [M3InsulatorPatrolGeo.lensL, M3InsulatorPatrolGeo.lensRt]) {
      c.drawCircle(
          o,
          M3InsulatorPatrolGeo.lensR,
          Paint()
            ..shader = const RadialGradient(colors: [Color(0x00000000), Color(0x00000000), Color(0x66000000)], stops: [0, 0.82, 1])
                .createShader(Rect.fromCircle(center: o, radius: M3InsulatorPatrolGeo.lensR)));
    }
    c.restore();
    // The rim.
    c.drawPath(lens, Paint()
      ..color = const Color(0xFF15191F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7);
    c.drawPath(lens, Paint()
      ..color = const Color(0xFF4A525E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6);
  }

  // --- the three heads -------------------------------------------------------
  void _concrete(Canvas c, double x, double top, double half) {
    final r = Rect.fromLTRB(x - half, top, x + half, 400);
    c.drawRect(r, Paint()..shader = const LinearGradient(colors: [Color(0xFFCFCFC7), Color(0xFF94948C)]).createShader(r));
    // Its holes (PCC pole).
    for (var y = top + 30; y < 380; y += 46) {
      c.drawCircle(Offset(x, y), 3, Paint()..color = const Color(0xFF6E6E68));
    }
  }

  void _arm(Canvas c, Rect r) {
    c.drawRect(r, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF5A616B), Color(0xFF30353C)]).createShader(r));
  }

  Paint _wire() => Paint()
    ..color = const Color(0xFF3A3F46)
    ..strokeWidth = 3
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  void _pinHead(Canvas c) {
    const cy = M3InsulatorPatrolGeo.lensCy;
    _concrete(c, 180, cy + 44, 13);
    _arm(c, const Rect.fromLTRB(46, cy + 38, 314, cy + 50));
    // The clamp holding the arm.
    c.drawRect(const Rect.fromLTRB(164, cy + 34, 196, cy + 56), Paint()..color = const Color(0xFF41464E));
    for (var i = 0; i < 3; i++) {
      final b = M3InsulatorPatrolGeo.unitBody(M3InsulatorPatrolKind.pin, i);
      // The steel pin into the arm.
      c.drawRect(Rect.fromLTRB(b.center.dx - 4, b.bottom - 6, b.center.dx + 4, cy + 40), Paint()..color = const Color(0xFF8A9099));
      _pinInsulator(c, b, units[i]);
      // The conductor in the top groove (running towards the viewer).
      c.drawLine(Offset(b.center.dx - 36, b.top + 2), Offset(b.center.dx + 36, b.top + 10), _wire());
    }
  }

  void _pinInsulator(Canvas c, Rect b, M3InsulatorPatrolUnit u) {
    final poly = u.body == M3InsulatorPatrolBody.polymer;
    final shader = poly
        ? const LinearGradient(colors: [Color(0xFF8C939B), Color(0xFF555B62)]).createShader(b)
        : const LinearGradient(colors: [_glazeTop, _glazeBot]).createShader(b);
    final p = Paint()..shader = shader;
    final x = b.center.dx;
    if (poly) {
      // A polymer pin: a slim core with many thin sheds.
      c.drawRect(Rect.fromLTRB(x - 6, b.top + 4, x + 6, b.bottom), p);
      for (var k = 0; k < 6; k++) {
        final y = b.top + 10 + k * 8.0;
        final hw = k.isEven ? 22.0 : 16.0;
        c.drawOval(Rect.fromCenter(center: Offset(x, y), width: hw * 2, height: 6), p);
      }
      c.drawRect(Rect.fromLTRB(x - 9, b.top, x + 9, b.top + 8), Paint()..color = const Color(0xFF9AA0A8));
    } else {
      // Porcelain: the head with its groove, then the sheds ("petticoat").
      final head = Path()
        ..moveTo(x - 12, b.top)
        ..lineTo(x + 12, b.top)
        ..lineTo(x + 16, b.top + 16)
        ..lineTo(x - 16, b.top + 16)
        ..close();
      c.drawPath(head, p);
      final shed1 = Path()
        ..moveTo(x - 16, b.top + 14)
        ..lineTo(x + 16, b.top + 14)
        ..lineTo(x + 25, b.top + 32)
        ..lineTo(x - 25, b.top + 32)
        ..close();
      c.drawPath(shed1, p);
      final shed2 = Path()
        ..moveTo(x - 12, b.top + 32)
        ..lineTo(x + 12, b.top + 32)
        ..lineTo(x + 20, b.bottom - 6)
        ..lineTo(x - 20, b.bottom - 6)
        ..close();
      c.drawPath(shed2, p);
      // Glaze highlight.
      c.drawLine(Offset(x - 8, b.top + 3), Offset(x - 19, b.top + 30), Paint()
        ..color = const Color(0x55FFFFFF)
        ..strokeWidth = 2.4);
    }
    _fault(c, b, u, rimY: b.top + 32, rimHalf: 25);
  }

  void _discHead(Canvas c) {
    const cy = M3InsulatorPatrolGeo.lensCy;
    _concrete(c, 180, cy - 112, 14);
    _arm(c, const Rect.fromLTRB(40, cy - 104, 320, cy - 90));
    for (var s = 0; s < 3; s++) {
      final x = const [84.0, 180.0, 276.0][s];
      // The hanger, the links between discs and the clamp at the bottom.
      final link = Paint()
        ..color = const Color(0xFF7D848D)
        ..strokeWidth = 4;
      c.drawLine(Offset(x, cy - 90), Offset(x, cy + 50), link);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, cy + 56), width: 30, height: 14), const Radius.circular(4)), Paint()..color = const Color(0xFF5E656E));
      // The conductor through the clamp.
      c.drawPath(
          Path()
            ..moveTo(x - 60, cy + 70)
            ..quadraticBezierTo(x, cy + 50, x + 60, cy + 70),
          _wire());
      for (var j = 0; j < 3; j++) {
        final i = s * 3 + j;
        _disc(c, M3InsulatorPatrolGeo.unitBody(M3InsulatorPatrolKind.disc, i), units[i]);
      }
    }
  }

  void _disc(Canvas c, Rect b, M3InsulatorPatrolUnit u) {
    final x = b.center.dx;
    // The cap on top.
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, b.top - 1), width: 18, height: 10), const Radius.circular(3)), Paint()..color = const Color(0xFF8E959E));
    if (u.fault == M3InsulatorPatrolFault.shattered) {
      // Toughened glass gone: only the cap and the pin, a few shards.
      c.drawLine(Offset(x, b.top), Offset(x, b.bottom + 4), Paint()
        ..color = const Color(0xFF6B727B)
        ..strokeWidth = 4);
      final shard = Paint()..color = const Color(0xAA7CC4B4);
      c.drawPath(
          Path()
            ..moveTo(x - 9, b.top + 3)
            ..lineTo(x - 15, b.top + 9)
            ..lineTo(x - 7, b.top + 8)
            ..close(),
          shard);
      c.drawPath(
          Path()
            ..moveTo(x + 8, b.top + 4)
            ..lineTo(x + 13, b.top + 11)
            ..lineTo(x + 5, b.top + 9)
            ..close(),
          shard);
      return;
    }
    final glass = u.body == M3InsulatorPatrolBody.glass;
    final dome = Path()
      ..moveTo(b.left, b.bottom - 4)
      ..quadraticBezierTo(b.left + 6, b.top + 2, x, b.top + 1)
      ..quadraticBezierTo(b.right - 6, b.top + 2, b.right, b.bottom - 4)
      ..quadraticBezierTo(x, b.bottom + 2, b.left, b.bottom - 4)
      ..close();
    c.drawPath(
        dome,
        Paint()
          ..shader = (glass
                  ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xDD9ADCCB), Color(0xDD3E8E80)])
                  : const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_glazeTop, _glazeBot]))
              .createShader(b));
    // The ribs underneath.
    c.drawArc(Rect.fromCenter(center: Offset(x, b.bottom - 3), width: b.width * 0.62, height: 8), 0, math.pi, false, Paint()
      ..color = glass ? const Color(0x88245C52) : const Color(0x88301608)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
    c.drawLine(Offset(x - 14, b.top + 6), Offset(x - 24, b.top + 12), Paint()
      ..color = const Color(0x66FFFFFF)
      ..strokeWidth = 2);
    _fault(c, b, u, rimY: b.bottom - 4, rimHalf: b.width / 2);
  }

  void _shackleHead(Canvas c) {
    const cy = M3InsulatorPatrolGeo.lensCy;
    _concrete(c, 160, cy - 118, 11);
    for (var i = 0; i < 4; i++) {
      final b = M3InsulatorPatrolGeo.unitBody(M3InsulatorPatrolKind.shackle, i);
      // The D-iron: two straps from the pole round the reel, a bolt through.
      final strap = Paint()
        ..color = const Color(0xFF5B626B)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      c.drawLine(Offset(166, b.top - 3), Offset(b.right + 5, b.top - 3), strap);
      c.drawLine(Offset(166, b.bottom + 3), Offset(b.right + 5, b.bottom + 3), strap);
      c.drawLine(Offset(b.right + 5, b.top - 4), Offset(b.right + 5, b.bottom + 4), strap);
      // The bolt through the reel.
      c.drawLine(Offset(b.center.dx, b.top - 4), Offset(b.center.dx, b.bottom + 4), Paint()
        ..color = const Color(0xFF8A9099)
        ..strokeWidth = 2);
      _shackle(c, b, units[i]);
      // The conductor: round the reel and away to the right (a dead end).
      c.drawPath(
          Path()
            ..moveTo(b.center.dx - 6, b.center.dy + 2)
            ..quadraticBezierTo(b.center.dx + 30, b.center.dy + 6, 360, b.center.dy - 8 + i * 3),
          _wire());
    }
  }

  void _shackle(Canvas c, Rect b, M3InsulatorPatrolUnit u) {
    final p = Paint()..shader = const LinearGradient(colors: [_glazeTop, _glazeBot]).createShader(b);
    // A reel: wide ends, a waist in the middle (the groove).
    final reel = Path()
      ..moveTo(b.left, b.top)
      ..lineTo(b.right, b.top)
      ..lineTo(b.right, b.top + 7)
      ..lineTo(b.right - 9, b.center.dy)
      ..lineTo(b.right, b.bottom - 7)
      ..lineTo(b.right, b.bottom)
      ..lineTo(b.left, b.bottom)
      ..lineTo(b.left, b.bottom - 7)
      ..lineTo(b.left + 9, b.center.dy)
      ..lineTo(b.left, b.top + 7)
      ..close();
    c.drawPath(reel, p);
    c.drawLine(Offset(b.left + 5, b.top + 3), Offset(b.left + 5, b.bottom - 3), Paint()
      ..color = const Color(0x55FFFFFF)
      ..strokeWidth = 2);
    _fault(c, b, u, rimY: b.top + 4, rimHalf: b.width / 2);
  }

  // --- faults -------------------------------------------------------------------
  void _fault(Canvas c, Rect b, M3InsulatorPatrolUnit u, {required double rimY, required double rimHalf}) {
    final f = u.fault;
    if (f == null) return;
    final x = b.center.dx;
    switch (f) {
      case M3InsulatorPatrolFault.crack:
        // A thin dark line with a light edge, across the body.
        final path = Path()
          ..moveTo(x - b.width * 0.30, b.top + b.height * 0.22)
          ..lineTo(x - b.width * 0.12, b.top + b.height * 0.42)
          ..lineTo(x - b.width * 0.18, b.top + b.height * 0.55)
          ..lineTo(x + b.width * 0.06, b.top + b.height * 0.74)
          ..lineTo(x + b.width * 0.02, b.top + b.height * 0.88);
        c.drawPath(path, Paint()
          ..color = const Color(0xCCF6E7D2)
          ..strokeWidth = 2.6
          ..style = PaintingStyle.stroke);
        c.drawPath(path, Paint()
          ..color = const Color(0xFF140A05)
          ..strokeWidth = 1.4
          ..style = PaintingStyle.stroke);
      case M3InsulatorPatrolFault.chipped:
        // A piece of the rim gone: sky shows through, the white body inside.
        final notch = Path()
          ..moveTo(x + rimHalf + 2, rimY + 2)
          ..lineTo(x + rimHalf * 0.35, rimY + 2)
          ..lineTo(x + rimHalf * 0.55, rimY - 6)
          ..lineTo(x + rimHalf * 0.70, rimY - 3)
          ..lineTo(x + rimHalf * 0.86, rimY - 11)
          ..lineTo(x + rimHalf + 2, rimY - 8)
          ..close();
        c.drawPath(notch, Paint()..color = const Color(0xFF9CC8E8));
        c.drawPath(
            Path()
              ..moveTo(x + rimHalf * 0.35, rimY + 1)
              ..lineTo(x + rimHalf * 0.55, rimY - 6)
              ..lineTo(x + rimHalf * 0.70, rimY - 3)
              ..lineTo(x + rimHalf * 0.86, rimY - 11),
            Paint()
              ..color = const Color(0xFFF1E9DC)
              ..strokeWidth = 2.4
              ..style = PaintingStyle.stroke);
      case M3InsulatorPatrolFault.burnt:
        // Black marks: soot across the body, a streak down it.
        c.save();
        c.clipRect(b.inflate(4));
        c.drawOval(
            Rect.fromCenter(center: Offset(x + b.width * 0.08, b.center.dy + b.height * 0.1), width: b.width * 0.9, height: b.height * 0.7),
            Paint()..shader = RadialGradient(colors: const [Color(0xEE0B0806), Color(0x880B0806), Color(0x000B0806)], stops: const [0, 0.55, 1]).createShader(b));
        c.restore();
        c.drawLine(Offset(x + b.width * 0.12, b.top + 2), Offset(x + b.width * 0.2, b.bottom - 2), Paint()
          ..color = const Color(0xCC0B0806)
          ..strokeWidth = 3);
      case M3InsulatorPatrolFault.bird:
        // Droppings: chalky white streaks down the body (the nest is drawn
        // beside it, see _nest).
        final drop = Paint()
          ..color = const Color(0xF2F7F5EC)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
        for (final (dx, len) in [(-0.22, 0.55), (0.04, 0.8), (0.24, 0.4)]) {
          c.drawLine(Offset(x + b.width * dx, b.top + 3), Offset(x + b.width * dx + 1, b.top + 3 + b.height * len), drop);
        }
        c.drawCircle(Offset(x + b.width * 0.04, b.top + 3 + b.height * 0.8), 2.6, Paint()..color = const Color(0xFF3C3A30));
      case M3InsulatorPatrolFault.salt:
        // A grey-white crust: the glaze gone dull, speckled.
        c.save();
        c.clipRect(b.inflate(1));
        c.drawRect(b, Paint()..color = const Color(0x99D9D3C4));
        final rnd = math.Random(b.center.dx.round() * 31 + b.center.dy.round());
        final dot = Paint()..color = const Color(0xDDF4F1E8);
        for (var k = 0; k < 26; k++) {
          c.drawCircle(Offset(b.left + rnd.nextDouble() * b.width, b.top + rnd.nextDouble() * b.height), 0.9 + rnd.nextDouble() * 1.3, dot);
        }
        c.restore();
      case M3InsulatorPatrolFault.shattered:
        break; // drawn by _disc
      case M3InsulatorPatrolFault.sharp:
        // The porcelain worn away to a sharp edge (white), the wire frayed.
        c.drawPath(
            Path()
              ..moveTo(b.left - 1, b.top + 6)
              ..lineTo(b.left + 7, b.top + 10)
              ..lineTo(b.left + 2, b.top + 14)
              ..lineTo(b.left + 9, b.center.dy)
              ..lineTo(b.left + 2, b.bottom - 12)
              ..lineTo(b.left + 7, b.bottom - 8)
              ..lineTo(b.left - 1, b.bottom - 5)
              ..close(),
            Paint()..color = const Color(0xFFF1E9DC));
        final fray = Paint()
          ..color = const Color(0xFFB9C0C8)
          ..strokeWidth = 1.3;
        for (var k = 0; k < 4; k++) {
          c.drawLine(Offset(b.center.dx - 4, b.center.dy + 2), Offset(b.center.dx - 14 - k * 3, b.center.dy - 8 + k * 6), fray);
        }
    }
  }

  /// A bird's nest of twigs, beside the insulator, on its arm or iron.
  void _nest(Canvas c, int i) {
    final b = M3InsulatorPatrolGeo.unitBody(kind, i);
    final at = switch (kind) {
      M3InsulatorPatrolKind.pin => Offset(b.center.dx + 24, M3InsulatorPatrolGeo.lensCy + 34),
      M3InsulatorPatrolKind.disc => Offset(b.center.dx + 24, M3InsulatorPatrolGeo.lensCy - 108),
      M3InsulatorPatrolKind.shackle => Offset(b.right + 12, b.top - 8),
    };
    final r = Rect.fromCenter(center: at, width: 34, height: 14);
    c.drawOval(r, Paint()..color = const Color(0xFF6B4A26));
    final twig = Paint()
      ..color = const Color(0xFFA67C45)
      ..strokeWidth = 1.4;
    for (var k = 0; k < 8; k++) {
      final a = k / 8 * math.pi;
      c.drawLine(at + Offset(-17 * math.cos(a), -3), at + Offset(17 * math.cos(a + 0.6), 5 * math.sin(a)), twig);
    }
    c.drawCircle(at + const Offset(-4, -3), 2.4, Paint()..color = const Color(0xFFE8E2D2));
    c.drawCircle(at + const Offset(3, -3), 2.4, Paint()..color = const Color(0xFFE8E2D2));
  }

  static void _dashedCircle(Canvas c, Offset o, double r, Color col) {
    final p = Paint()
      ..color = col
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    for (var k = 0; k < 14; k++) {
      final a = k / 14 * math.pi * 2;
      c.drawArc(Rect.fromCircle(center: o, radius: r), a, math.pi / 14, false, p);
    }
  }

  @override
  bool shouldRepaint(M3InsulatorPatrolLensPainter old) =>
      old.kind != kind || !listEquals(old.units, units) || !setEquals(old.marks, marks) || old.reveal != reveal;
}

/// The binoculars in the trainee's hands.
class M3InsulatorPatrolBinocularsPainter extends CustomPainter {
  const M3InsulatorPatrolBinocularsPainter({required this.at});
  final Offset at;

  @override
  void paint(Canvas c, Size size) {
    final body = Paint()..color = const Color(0xFF1F242B);
    final ring = Paint()..color = const Color(0xFF4A525E);
    for (final dx in [-8.0, 8.0]) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: at + Offset(dx, -4), width: 12, height: 20), const Radius.circular(4)), body);
      c.drawOval(Rect.fromCenter(center: at + Offset(dx, -14), width: 12, height: 5), ring);
    }
    c.drawRect(Rect.fromCenter(center: at + const Offset(0, -6), width: 6, height: 6), ring);
  }

  @override
  bool shouldRepaint(M3InsulatorPatrolBinocularsPainter old) => old.at != at;
}

/// The deadly consequence (in colour over the grey scene): a flash at the
/// pole where his hand went, an arc, sparks. Non-graphic.
class M3InsulatorPatrolZapPainter extends CustomPainter {
  const M3InsulatorPatrolZapPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final flick = v < 0.5 ? (0.65 + 0.35 * math.sin(v * 60).abs()) : (1 - (v - 0.5) * 1.2).clamp(0.4, 1.0);
    final r = 26 + 46 * Curves.easeOut.transform(v.clamp(0.0, 1.0));
    c.drawCircle(at, r, Paint()..shader = RadialGradient(colors: [Color.fromRGBO(220, 235, 255, 0.95 * flick), const Color(0x002F6FD0)]).createShader(Rect.fromCircle(center: at, radius: r)));
    final rnd = math.Random(11);
    final arc = Path()..moveTo(at.dx, at.dy - 34);
    for (var i = 1; i <= 6; i++) {
      arc.lineTo(at.dx + (rnd.nextDouble() - 0.5) * 18, at.dy - 34 + i * 11);
    }
    c.drawPath(arc, Paint()
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
  bool shouldRepaint(M3InsulatorPatrolZapPainter old) => old.v != v || old.at != at;
}
