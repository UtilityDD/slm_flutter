import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The drawn world of lesson 4.1 কাজ 1 "বদলের আগে" (m4_insulator_prep.dart):
// an 11 kV line across village fields — the PCC pole in front with its
// insulators (three pin insulators on the crossarm and the pole top, or a
// vertical tension pole with a pair of disc strings for each phase), the three
// conductors running across the scene, the trainee at the pole foot, the kit
// laid out on a tarp, and the earthing sets clamped on the line on both sides
// of the pole. Code-drawn, gradients, no bitmaps. Design space 360 wide; the
// ground sits [M4InsulatorPrepGeo.floorUp] above the bottom so the tool row
// sits on it.

/// What kind of insulator the pole carries.
enum M4InsulatorPrepKind { pin, disc }

/// What is wrong with the faulty insulator (lesson 4.1: electrical puncture /
/// flashover, or a mechanical crack — check for both).
enum M4InsulatorPrepFault { crack, burn }

/// The things on the van's shelf.
enum M4InsulatorPrepItem { pinNew, pinBad, discNew, discBad, binding, rope, comeAlong, turnbuckle }

/// Where things are in the scene (design px, 360 wide).
@immutable
class M4InsulatorPrepGeo {
  const M4InsulatorPrepGeo._(this.height, this.groundY);

  factory M4InsulatorPrepGeo.forScene(double height, double inset) => M4InsulatorPrepGeo._(height, height - floorUp - inset * 0.5);

  final double height;

  /// The ground line at the pole foot.
  final double groundY;

  static const double floorUp = 104;

  /// The conductors fall gently to the right (the line seen a little from the side).
  static const double slope = 0.15;

  static const double poleX = 180;

  /// The crossarm (pin pole) / the middle bracket (tension pole).
  double get crossY => groundY - math.min(350.0, groundY - 200);
  double get poleTop => crossY - 58;
  Rect get pole => Rect.fromLTRB(poleX - 9, poleTop, poleX + 9, groundY + 6);

  /// Tap the pole (not its top) to climb.
  Rect get poleHit => Rect.fromLTRB(poleX - 30, crossY + 40, poleX + 30, groundY);

  // --- the pin pole: crossarm left end, the pole top, crossarm right end ---
  List<Offset> get pinBases => [Offset(84, crossY - 5), Offset(poleX, poleTop), Offset(276, crossY - 5)];

  /// The groove on top of pin insulator [i] (the conductor rests there).
  Offset pinTop(int i) => pinBases[i] - const Offset(0, 30);
  Rect pinHit(int i) => Rect.fromCenter(center: pinBases[i] - const Offset(0, 15), width: 50, height: 56);

  // --- the tension pole: three brackets, a string to each side ---
  List<double> get discYs => [crossY - 50, crossY - 6, crossY + 38];

  /// String [j] = phase j ~/ 2, side j % 2 (0 left, 1 right): pole end → line end.
  (Offset, Offset) discString(int j) {
    final y = discYs[j ~/ 2];
    final left = j.isEven;
    final a = Offset(poleX + (left ? -12 : 12), y);
    final b = Offset(poleX + (left ? -56 : 56), y + (left ? -44 : 44) * slope);
    return (a, b);
  }

  Rect discHit(int j) {
    final (a, b) = discString(j);
    return Rect.fromPoints(a, b).inflate(13);
  }

  /// The insulator spots for this kind (3 pins or 6 strings).
  int spots(M4InsulatorPrepKind k) => k == M4InsulatorPrepKind.pin ? 3 : 6;
  Rect spotHit(M4InsulatorPrepKind k, int i) => k == M4InsulatorPrepKind.pin ? pinHit(i) : discHit(i);
  Offset spotCentre(M4InsulatorPrepKind k, int i) => spotHit(k, i).center;

  /// A point of conductor [i] (its height at x).
  double wireY(M4InsulatorPrepKind k, int i, double x) {
    if (k == M4InsulatorPrepKind.pin) {
      final p = pinTop(i);
      return p.dy + (x - p.dx) * slope;
    }
    return discYs[i] + (x - poleX) * slope;
  }

  /// The earthing sets: left and right of the pole.
  static const earthX = [32.0, 342.0];
  Rect earthHit(int side) => Rect.fromLTRB(earthX[side] - 30, crossY - 110, earthX[side] + 30, groundY + 24);
  Offset earthRod(int side) => Offset(earthX[side], groundY + 4);

  /// Where the lineman stands on the ground, and on the pole once he has climbed.
  Rect get trainee => Rect.fromLTWH(198, groundY - 140, 70, 140);
  Rect get traineeUp => Rect.fromLTWH(poleX - 8, crossY + 50, 70, 140);

  /// The kit on its tarp at the pole foot.
  Rect get tarp => Rect.fromLTRB(262, groundY - 4, 336, groundY + 14);

  @override
  bool operator ==(Object other) => other is M4InsulatorPrepGeo && other.height == height && other.groundY == groundY;

  @override
  int get hashCode => Object.hash(height, groundY);
}

/// What the scene shows now.
@immutable
class M4InsulatorPrepView {
  const M4InsulatorPrepView({
    required this.kind,
    required this.fault,
    required this.faulty,
    required this.spotted,
    required this.earths,
    required this.bag,
    required this.climbed,
    required this.poleNo,
  });

  final M4InsulatorPrepKind kind;
  final M4InsulatorPrepFault fault;
  final int faulty;
  final bool spotted;
  final Set<int> earths;
  final Set<M4InsulatorPrepItem> bag;
  final bool climbed;
  final int poleNo;

  @override
  bool operator ==(Object other) =>
      other is M4InsulatorPrepView &&
      other.kind == kind &&
      other.fault == fault &&
      other.faulty == faulty &&
      other.spotted == spotted &&
      setEquals(other.earths, earths) &&
      setEquals(other.bag, bag) &&
      other.climbed == climbed &&
      other.poleNo == poleNo;

  @override
  int get hashCode => Object.hash(kind, fault, faulty, spotted, Object.hashAllUnordered(earths), Object.hashAllUnordered(bag), climbed, poleNo);
}

const _porcelain = [Color(0xFFB0643A), Color(0xFF7A3A1C)];
const _wire = Color(0xFF59616A);

/// The line, the pole, the insulators, the earthing sets and the kit.
class M4InsulatorPrepPainter extends CustomPainter {
  const M4InsulatorPrepPainter({required this.geo, required this.view, required this.seed});

  final M4InsulatorPrepGeo geo;
  final M4InsulatorPrepView view;
  final int seed;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    // Sky and the far fields.
    c.drawRect(
        Rect.fromLTWH(0, 0, w, g.groundY),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4F86C6), Color(0xFFBFDDF0)],
          ).createShader(Rect.fromLTWH(0, 0, w, g.groundY)));
    final rnd = math.Random(seed);
    final cloud = Paint()..color = const Color(0xCCFFFFFF);
    for (var i = 0; i < 3; i++) {
      final at = Offset(40 + rnd.nextDouble() * 280, 60 + rnd.nextDouble() * (g.crossY - 160).clamp(20, 400));
      c.drawOval(Rect.fromCenter(center: at, width: 70, height: 18), cloud);
      c.drawOval(Rect.fromCenter(center: at + const Offset(14, -8), width: 40, height: 20), cloud);
    }
    final horizon = g.groundY - 120;
    final tree = Paint()..color = const Color(0xFF4C7A3E);
    for (var x = -10.0; x < w + 20; x += 20 + rnd.nextDouble() * 22) {
      final r = 8 + rnd.nextDouble() * 9;
      c.drawCircle(Offset(x, horizon - r * 0.5), r, tree);
    }
    final field = Rect.fromLTWH(0, horizon - 2, w, g.groundY - horizon + 2);
    c.drawRect(field, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8DB860), Color(0xFF6E9A45)]).createShader(field));
    // A far pole of the same line, small, in the field.
    final fp = Paint()..color = const Color(0xFF9AA0A6);
    c.drawRect(Rect.fromLTWH(332, horizon - 70, 3, 72), fp);
    c.drawRect(Rect.fromLTWH(322, horizon - 66, 23, 2.5), fp);
    // The ground: a dirt verge along the road.
    final ground = Rect.fromLTRB(0, g.groundY, w, size.height);
    c.drawRect(ground, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFB08B5E), Color(0xFF7F6243)]).createShader(ground));
    c.drawLine(Offset(0, g.groundY), Offset(w, g.groundY), Paint()
      ..color = const Color(0xFF6B5236)
      ..strokeWidth = 2);
    final tuft = Paint()
      ..color = const Color(0xFF5D8A3A)
      ..strokeWidth = 1.6;
    for (var x = 6.0; x < w; x += 26 + rnd.nextDouble() * 20) {
      c.drawLine(Offset(x, g.groundY + 1), Offset(x - 3, g.groundY - 6), tuft);
      c.drawLine(Offset(x, g.groundY + 1), Offset(x + 3, g.groundY - 7), tuft);
    }

    _pole(c);
    _wires(c, w);
    if (view.kind == M4InsulatorPrepKind.pin) {
      _pinHardware(c);
    } else {
      _discHardware(c);
    }
    for (final s in view.earths) {
      _earthSet(c, s);
    }
    _tarp(c);
    if (view.climbed) _strap(c);
  }

  void _pole(Canvas c) {
    final g = geo;
    final x = M4InsulatorPrepGeo.poleX;
    final path = Path()
      ..moveTo(x - 6, g.poleTop)
      ..lineTo(x + 6, g.poleTop)
      ..lineTo(x + 10, g.groundY + 6)
      ..lineTo(x - 10, g.groundY + 6)
      ..close();
    c.drawPath(path, Paint()..shader = const LinearGradient(colors: [Color(0xFF8D9399), Color(0xFFCDD2D6), Color(0xFF7A8086)]).createShader(g.pole));
    // The danger plate and the pole number.
    final plate = Rect.fromCenter(center: Offset(x, g.groundY - 118), width: 22, height: 28);
    c.drawRRect(RRect.fromRectAndRadius(plate, const Radius.circular(2)), Paint()..color = Colors.white);
    c.drawPath(
        Path()
          ..moveTo(plate.center.dx + 2, plate.top + 4)
          ..lineTo(plate.center.dx - 4, plate.center.dy + 1)
          ..lineTo(plate.center.dx + 1, plate.center.dy + 1)
          ..lineTo(plate.center.dx - 2, plate.bottom - 4)
          ..lineTo(plate.center.dx + 5, plate.center.dy - 2)
          ..lineTo(plate.center.dx, plate.center.dy - 2)
          ..close(),
        Paint()..color = const Color(0xFFD7261E));
    final no = Rect.fromCenter(center: Offset(x, g.groundY - 88), width: 24, height: 13);
    c.drawRect(no, Paint()..color = const Color(0xFF1F2A36));
    _label(c, '${view.poleNo}', no.center, 8.5, Colors.white);
  }

  void _wires(Canvas c, double w) {
    final g = geo;
    final k = view.kind;
    final p = Paint()
      ..color = _wire
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 3; i++) {
      if (k == M4InsulatorPrepKind.pin) {
        c.drawLine(Offset(-10, g.wireY(k, i, -10)), Offset(w + 10, g.wireY(k, i, w + 10)), p);
      } else {
        // Each side ends at its string; the jumper loops round in front of the pole.
        final (_, lb) = g.discString(i * 2);
        final (_, rb) = g.discString(i * 2 + 1);
        c.drawLine(Offset(-10, g.wireY(k, i, -10)), lb, p);
        c.drawLine(rb, Offset(w + 10, g.wireY(k, i, w + 10)), p);
        c.drawPath(
            Path()
              ..moveTo(lb.dx, lb.dy)
              ..cubicTo(lb.dx + 8, lb.dy + 26, rb.dx - 8, rb.dy + 22, rb.dx, rb.dy),
            p..strokeWidth = 1.8);
        p.strokeWidth = 2.2;
      }
    }
  }

  void _pinHardware(Canvas c) {
    final g = geo;
    // The crossarm (steel channel) and its braces; the pole-top bracket.
    final arm = Rect.fromLTRB(62, g.crossY, 298, g.crossY + 9);
    c.drawRect(arm, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF5A6068), Color(0xFF30353B)]).createShader(arm));
    final brace = Paint()
      ..color = const Color(0xFF3C4248)
      ..strokeWidth = 3;
    c.drawLine(Offset(110, g.crossY + 8), Offset(M4InsulatorPrepGeo.poleX - 6, g.crossY + 46), brace);
    c.drawLine(Offset(250, g.crossY + 8), Offset(M4InsulatorPrepGeo.poleX + 6, g.crossY + 46), brace);
    for (var i = 0; i < 3; i++) {
      final bad = view.faulty == i ? view.fault : null;
      _pinInsulator(c, g.pinBases[i], bad);
      if (view.spotted && view.faulty == i) _ring(c, g.pinHit(i).center, 30);
    }
  }

  void _pinInsulator(Canvas c, Offset base, M4InsulatorPrepFault? bad) {
    // The steel pin, then three porcelain sheds and the head with its groove.
    c.drawRect(Rect.fromCenter(center: base + const Offset(0, -2), width: 5, height: 8), Paint()..color = const Color(0xFF8A9096));
    final body = Path()
      ..moveTo(base.dx - 15, base.dy - 6)
      ..lineTo(base.dx + 15, base.dy - 6)
      ..lineTo(base.dx + 9, base.dy - 12)
      ..lineTo(base.dx + 12, base.dy - 15)
      ..lineTo(base.dx + 7, base.dy - 21)
      ..lineTo(base.dx + 9, base.dy - 23)
      ..lineTo(base.dx + 6, base.dy - 30)
      ..lineTo(base.dx - 6, base.dy - 30)
      ..lineTo(base.dx - 9, base.dy - 23)
      ..lineTo(base.dx - 7, base.dy - 21)
      ..lineTo(base.dx - 12, base.dy - 15)
      ..lineTo(base.dx - 9, base.dy - 12)
      ..close();
    final r = Rect.fromLTRB(base.dx - 15, base.dy - 30, base.dx + 15, base.dy - 6);
    c.drawPath(body, Paint()..shader = const LinearGradient(colors: [Color(0xFFC77A4C), Color(0xFF8E4522), Color(0xFF6A2E14)], stops: [0, 0.55, 1]).createShader(r));
    c.drawLine(Offset(base.dx - 6, base.dy - 27), Offset(base.dx + 6, base.dy - 27), Paint()
      ..color = const Color(0x55FFFFFF)
      ..strokeWidth = 1.2);
    // The binding at the head.
    c.drawRect(Rect.fromCenter(center: base + const Offset(0, -30), width: 12, height: 3), Paint()..color = const Color(0xFFB9C0C6));
    if (bad != null) _damage(c, base + const Offset(0, -17), bad, 12);
  }

  void _discHardware(Canvas c) {
    final g = geo;
    for (var phase = 0; phase < 3; phase++) {
      final y = g.discYs[phase];
      // The bracket through the pole.
      c.drawRect(Rect.fromLTRB(M4InsulatorPrepGeo.poleX - 14, y - 3, M4InsulatorPrepGeo.poleX + 14, y + 3), Paint()..color = const Color(0xFF3C4248));
    }
    for (var j = 0; j < 6; j++) {
      final (a, b) = g.discString(j);
      c.drawLine(a, b, Paint()
        ..color = const Color(0xFF7D848B)
        ..strokeWidth = 2);
      final d = b - a;
      final ang = math.atan2(d.dy, d.dx);
      for (var k = 0; k < 3; k++) {
        final at = a + d * (0.25 + 0.25 * k);
        final bad = view.faulty == j && k == 1 ? view.fault : null;
        _disc(c, at, ang, bad);
      }
      if (view.spotted && view.faulty == j) _ring(c, g.discHit(j).center, 32);
    }
  }

  void _disc(Canvas c, Offset at, double ang, M4InsulatorPrepFault? bad) {
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(ang);
    final r = Rect.fromCenter(center: Offset.zero, width: 9, height: 26);
    c.drawOval(r, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: _porcelain).createShader(r));
    c.drawOval(r, Paint()
      ..color = const Color(0xFF4E220E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8);
    c.drawRect(Rect.fromCenter(center: const Offset(-4, 0), width: 3, height: 5), Paint()..color = const Color(0xFF9AA1A7));
    c.restore();
    if (bad != null) _damage(c, at, bad, 12);
  }

  /// A crack (dark zigzag and a chipped edge) or a flashover burn (soot and a puncture).
  void _damage(Canvas c, Offset at, M4InsulatorPrepFault f, double s) {
    if (f == M4InsulatorPrepFault.crack) {
      c.drawPath(
          Path()
            ..moveTo(at.dx - s * 0.7, at.dy - s * 0.8)
            ..lineTo(at.dx - s * 0.1, at.dy - s * 0.2)
            ..lineTo(at.dx - s * 0.5, at.dy + s * 0.15)
            ..lineTo(at.dx + s * 0.25, at.dy + s * 0.6)
            ..lineTo(at.dx + s * 0.05, at.dy + s * 0.95),
          Paint()
            ..color = const Color(0xFF1A0E08)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8);
      c.drawPath(
          Path()
            ..moveTo(at.dx + s * 0.55, at.dy - s * 0.9)
            ..lineTo(at.dx + s * 1.05, at.dy - s * 0.55)
            ..lineTo(at.dx + s * 0.6, at.dy - s * 0.35)
            ..close(),
          Paint()..color = const Color(0xFFE9DCCB));
    } else {
      c.drawCircle(at, s * 0.95, Paint()..shader = RadialGradient(colors: const [Color(0xEE0C0C0C), Color(0x880C0C0C), Color(0x000C0C0C)]).createShader(Rect.fromCircle(center: at, radius: s * 0.95)));
      c.drawCircle(at + Offset(s * 0.15, 0), s * 0.22, Paint()..color = const Color(0xFFEFE6D8));
      // The flashover track: a pale tracking line burnt across the glaze.
      c.drawPath(
          Path()
            ..moveTo(at.dx - s * 1.0, at.dy - s * 1.1)
            ..lineTo(at.dx - s * 0.35, at.dy - s * 0.45)
            ..lineTo(at.dx - s * 0.6, at.dy - s * 0.1)
            ..lineTo(at.dx + s * 0.05, at.dy),
          Paint()
            ..color = const Color(0xFFF2E9D8)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6);
    }
  }

  void _ring(Canvas c, Offset at, double r) {
    c.drawCircle(at, r, Paint()
      ..color = const Color(0xFFFFE08A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4);
  }

  void _earthSet(Canvas c, int side) {
    final g = geo;
    final x = M4InsulatorPrepGeo.earthX[side];
    final braid = Paint()
      ..color = const Color(0xFFB8733A)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    final ys = [for (var i = 0; i < 3; i++) g.wireY(view.kind, i, x)]..sort();
    // The clamps on the three conductors, shorted together, down to the rod.
    for (final y in ys) {
      c.drawRect(Rect.fromCenter(center: Offset(x, y + 3), width: 7, height: 8), Paint()..color = const Color(0xFFE2B33A));
    }
    c.drawLine(Offset(x, ys.first + 6), Offset(x, ys.last + 6), braid);
    final rod = g.earthRod(side);
    c.drawPath(
        Path()
          ..moveTo(x, ys.last + 6)
          ..quadraticBezierTo(x + (side == 0 ? 16 : -16), (ys.last + rod.dy) / 2, rod.dx, rod.dy - 8),
        braid);
    c.drawRect(Rect.fromLTRB(rod.dx - 2, rod.dy - 10, rod.dx + 2, rod.dy + 10), Paint()..color = const Color(0xFF8A9096));
    for (var k = 0; k < 3; k++) {
      c.drawRect(Rect.fromLTWH(rod.dx - 2, rod.dy - 9 + k * 6, 4, 3), Paint()..color = k.isEven ? const Color(0xFF3E9A3E) : const Color(0xFFE5C33A));
    }
  }

  void _tarp(Canvas c) {
    final g = geo;
    if (view.bag.isEmpty) return;
    final t = g.tarp;
    c.drawRRect(RRect.fromRectAndRadius(t, const Radius.circular(3)), Paint()..color = const Color(0xFF2F6FA8));
    final items = view.bag.toList()..sort((a, b) => a.index.compareTo(b.index));
    for (final (i, it) in items.indexed) {
      final box = Rect.fromLTWH(t.left + 2 + i * 18.0, t.top - 20, 18, 22);
      m4InsulatorPrepPaintItem(c, box, it);
    }
  }

  /// The pole strap round the pole while he works up there (helmet + harness on).
  void _strap(Canvas c) {
    final g = geo;
    final y = g.traineeUp.top + 64;
    c.drawArc(Rect.fromCenter(center: Offset(M4InsulatorPrepGeo.poleX + 6, y), width: 44, height: 14), -0.2, math.pi + 0.4, false, Paint()
      ..color = const Color(0xFFE08A1E)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke);
  }

  void _label(Canvas c, String s, Offset centre, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontFamily: 'Roboto', fontSize: size, fontWeight: FontWeight.w800, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(M4InsulatorPrepPainter old) => old.geo != geo || old.view != view || old.seed != seed;
}

/// One shelf item drawn in [box] (also on the tarp).
void m4InsulatorPrepPaintItem(Canvas c, Rect box, M4InsulatorPrepItem it) {
  final cx = box.center.dx;
  final s = math.min(box.width, box.height);
  switch (it) {
    case M4InsulatorPrepItem.pinNew:
    case M4InsulatorPrepItem.pinBad:
      final base = Offset(cx, box.bottom - s * 0.08);
      final k = s / 34;
      final body = Path()
        ..moveTo(cx - 15 * k, base.dy - 4 * k)
        ..lineTo(cx + 15 * k, base.dy - 4 * k)
        ..lineTo(cx + 9 * k, base.dy - 11 * k)
        ..lineTo(cx + 12 * k, base.dy - 14 * k)
        ..lineTo(cx + 7 * k, base.dy - 21 * k)
        ..lineTo(cx + 9 * k, base.dy - 23 * k)
        ..lineTo(cx + 6 * k, base.dy - 30 * k)
        ..lineTo(cx - 6 * k, base.dy - 30 * k)
        ..lineTo(cx - 9 * k, base.dy - 23 * k)
        ..lineTo(cx - 7 * k, base.dy - 21 * k)
        ..lineTo(cx - 12 * k, base.dy - 14 * k)
        ..lineTo(cx - 9 * k, base.dy - 11 * k)
        ..close();
      final r = Rect.fromLTRB(cx - 15 * k, base.dy - 30 * k, cx + 15 * k, base.dy - 4 * k);
      c.drawPath(body, Paint()..shader = const LinearGradient(colors: [Color(0xFFC77A4C), Color(0xFF8E4522), Color(0xFF6A2E14)], stops: [0, 0.55, 1]).createShader(r));
      if (it == M4InsulatorPrepItem.pinBad) {
        final at = Offset(cx, base.dy - 16 * k);
        c.drawPath(
            Path()
              ..moveTo(at.dx - 8 * k, at.dy - 12 * k)
              ..lineTo(at.dx - 1 * k, at.dy - 3 * k)
              ..lineTo(at.dx - 6 * k, at.dy + 2 * k)
              ..lineTo(at.dx + 3 * k, at.dy + 10 * k),
            Paint()
              ..color = const Color(0xFF140A05)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2 * k);
        c.drawPath(
            Path()
              ..moveTo(cx + 9 * k, base.dy - 11 * k)
              ..lineTo(cx + 15 * k, base.dy - 4 * k)
              ..lineTo(cx + 6 * k, base.dy - 4 * k)
              ..close(),
            Paint()..color = const Color(0xFFEDE2D2));
      }
    case M4InsulatorPrepItem.discNew:
    case M4InsulatorPrepItem.discBad:
      final r = Rect.fromCenter(center: box.center, width: s * 0.86, height: s * 0.5);
      c.drawOval(r.shift(Offset(0, s * 0.08)), Paint()..color = const Color(0xFF5A2810));
      c.drawOval(r, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: _porcelain).createShader(r));
      c.drawCircle(box.center - Offset(0, s * 0.05), s * 0.09, Paint()..color = const Color(0xFF9AA1A7));
      if (it == M4InsulatorPrepItem.discBad) {
        c.drawPath(
            Path()
              ..moveTo(r.left + r.width * 0.18, r.top + r.height * 0.3)
              ..lineTo(r.left + r.width * 0.4, r.center.dy)
              ..lineTo(r.left + r.width * 0.32, r.bottom - r.height * 0.25)
              ..lineTo(r.left + r.width * 0.55, r.bottom - r.height * 0.05),
            Paint()
              ..color = const Color(0xFF140A05)
              ..style = PaintingStyle.stroke
              ..strokeWidth = s * 0.05);
        c.drawPath(
            Path()
              ..moveTo(r.right - r.width * 0.2, r.top + r.height * 0.06)
              ..lineTo(r.right, r.center.dy - r.height * 0.1)
              ..lineTo(r.right - r.width * 0.12, r.center.dy + r.height * 0.05)
              ..close(),
            Paint()..color = const Color(0xFFEDE2D2));
      }
    case M4InsulatorPrepItem.binding:
      final p = Paint()
        ..color = const Color(0xFFC3CAD0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.05;
      for (var i = 0; i < 4; i++) {
        c.drawOval(Rect.fromCenter(center: box.center + Offset(-s * 0.12 + i * s * 0.08, 0), width: s * 0.36, height: s * 0.62), p);
      }
    case M4InsulatorPrepItem.rope:
      final p = Paint()
        ..color = const Color(0xFFD9B26A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.08;
      for (var i = 0; i < 3; i++) {
        c.drawOval(Rect.fromCenter(center: box.center, width: s * (0.8 - i * 0.2), height: s * (0.56 - i * 0.14)), p);
      }
    case M4InsulatorPrepItem.comeAlong:
      final body = Rect.fromCenter(center: box.center, width: s * 0.36, height: s * 0.7);
      c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(s * 0.06)), Paint()..color = const Color(0xFFE0A21E));
      c.drawRect(Rect.fromLTWH(body.left - s * 0.12, body.top + s * 0.08, s * 0.14, s * 0.12), Paint()..color = const Color(0xFF5A6068));
      c.drawLine(Offset(body.right, body.center.dy), Offset(body.right + s * 0.2, body.bottom), Paint()
        ..color = const Color(0xFF3C4248)
        ..strokeWidth = s * 0.07);
      c.drawCircle(Offset(box.center.dx, body.top), s * 0.08, Paint()
        ..color = const Color(0xFF5A6068)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.04);
    case M4InsulatorPrepItem.turnbuckle:
      final p = Paint()
        ..color = const Color(0xFF8A9096)
        ..strokeWidth = s * 0.07
        ..strokeCap = StrokeCap.round;
      final a = Offset(box.left + s * 0.12, box.center.dy + s * 0.18);
      final b = Offset(box.right - s * 0.12, box.center.dy - s * 0.18);
      c.drawLine(a, b, p);
      final mid = Rect.fromCenter(center: box.center, width: s * 0.36, height: s * 0.18);
      c.save();
      c.translate(box.center.dx, box.center.dy);
      c.rotate(math.atan2(b.dy - a.dy, b.dx - a.dx));
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: mid.width, height: mid.height), Radius.circular(s * 0.04)), Paint()..color = const Color(0xFF5A6068));
      c.restore();
      for (final e in [a, b]) {
        c.drawCircle(e, s * 0.07, Paint()
          ..color = const Color(0xFF5A6068)
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.04);
      }
  }
}

/// A shelf item drawn to fit its tile.
class M4InsulatorPrepItemPainter extends CustomPainter {
  const M4InsulatorPrepItemPainter(this.item);
  final M4InsulatorPrepItem item;

  @override
  void paint(Canvas c, Size size) => m4InsulatorPrepPaintItem(c, Offset.zero & size, item);

  @override
  bool shouldRepaint(M4InsulatorPrepItemPainter old) => old.item != item;
}

/// The flash at the work point when he is up on a line that is not dead and
/// earthed on both sides (the deadly moment, in colour over the frozen scene).
class M4InsulatorPrepFlashPainter extends CustomPainter {
  const M4InsulatorPrepFlashPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final flick = v < 0.5 ? (0.65 + 0.35 * math.sin(v * 60).abs()) : (1 - (v - 0.5) * 1.2).clamp(0.4, 1.0);
    final r = 26 + 70 * Curves.easeOut.transform(v.clamp(0.0, 1.0));
    c.drawCircle(at, r, Paint()..shader = RadialGradient(colors: [Color.fromRGBO(255, 250, 220, 0.95 * flick), Color.fromRGBO(140, 170, 255, 0.5 * flick), const Color(0x00FFC24A)]).createShader(Rect.fromCircle(center: at, radius: r)));
    final spark = Paint()
      ..color = Color.fromRGBO(255, 214, 90, (1 - v).clamp(0.0, 1.0))
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 16; i++) {
      final a = i / 16 * math.pi * 2 + 0.2;
      final d0 = 10 + 50 * v;
      c.drawLine(at + Offset(math.cos(a), math.sin(a)) * d0, at + Offset(math.cos(a), math.sin(a)) * (d0 + 14), spark);
    }
    final white = (1 - v * 4).clamp(0.0, 1.0);
    if (white > 0) c.drawRect(Offset.zero & size, Paint()..color = Color.fromRGBO(255, 255, 255, 0.8 * white));
  }

  @override
  bool shouldRepaint(M4InsulatorPrepFlashPainter old) => old.v != v || old.at != at;
}
