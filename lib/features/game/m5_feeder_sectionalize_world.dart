import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The drawn world of lesson 5.4 কাজ 1 "একে একে ফিডার" (m5_feeder_sectionalize.dart):
// a village crossroads at dusk. On the left a DP transformer structure: the
// 11 kV line over the top cross-arm, the DO-fuse cross-arm with three barrels
// (the blown one hangs dropped and sooty until it is closed again), the
// transformer on its platform, and the LT box on the right pole. When its
// door is opened the LT board shows big on the right: 3 or 4 fuse carriers
// (the 4th on a lower row), each under its road's name and a small lamp that
// is lit while the HT holds and that way is in. Village houses along the
// horizon light up road by road. The van stands at the roadside.
//
// Carriers are drawn alike whatever is behind them (no mark on the faulty
// way); soot shows on a base only after its way has blown the HT fuse.
// Code-drawn, gradients, no bitmaps; no text except the labels a worker reads
// (road names are widgets over the board).
//
// Design: 360 wide × the scene's height; the ground follows the bottom of the
// screen (a tall phone gets more sky, never a stretched picture).

/// Where things are (design px, 360 wide).
@immutable
class M5FeederGeo {
  const M5FeederGeo._(this.height, this.groundY, this.topY);

  factory M5FeederGeo.forScene(double height, double inset) {
    final g = height - floorUp - inset * 0.5;
    final h = math.min(420.0, g - 170);
    return M5FeederGeo._(height, g, g - h);
  }

  final double height;

  /// The ground line at the poles' feet.
  final double groundY;

  /// The top of the poles.
  final double topY;

  /// The ground sits this far above the bottom (the tool row stands on it).
  static const double floorUp = 112;

  /// The DP's two poles.
  static const double lp = 50;
  static const double rp = 140;

  /// The three phases (insulators, DO barrels).
  static const List<double> phaseX = [64, 95, 126];

  /// A carrier on the board: width, height, and how far it drops when pulled.
  static const double cw = 46;
  static const double ch = 66;
  static const double drop = 24;

  double get h => groundY - topY;
  double y(double f) => topY + f * h;

  double get armY => y(0.05);
  double get doArmY => y(0.20);

  /// The top of DO barrel [i] (where it hinges shut).
  Offset barrelTop(int i) => Offset(phaseX[i], doArmY + 3);

  Rect get tank => Rect.fromLTRB(70, y(0.33), 120, y(0.49));
  double get platformY => y(0.505);

  /// The LT box on the right pole, just under the platform (kept clear of
  /// the corner guide's speech bubble).
  Rect get ltBox => Rect.fromLTWH(rp - 4, y(0.53), 30, 34);

  /// Tap the LT box's door here.
  Rect get doorHit => ltBox.inflate(12);

  /// Hold the dropped DO barrel [phase] here (operating-rod close).
  Rect doRing(int phase) => Rect.fromCenter(center: Offset(phaseX[phase], doArmY + 20), width: 54, height: 60);

  /// The open LT board (a close view of the box).
  Rect get panel => Rect.fromLTWH(186, math.max(132.0, topY - 30), 166, 266);

  /// Carrier [i] seated in its base (3 on the top row, the 4th under the middle).
  Rect carrierIn(int i) {
    final col = i < 3 ? i : 1;
    final row = i < 3 ? 0 : 1;
    return Rect.fromLTWH(panel.left + 8 + col * (cw + 6), panel.top + 42 + row * (ch + drop + 34), cw, ch);
  }

  /// Carrier [i] pulled out (hanging below its base).
  Rect carrierOut(int i) => carrierIn(i).translate(0, drop);

  /// Swipe / drag carrier [i] here (its seat and where it hangs).
  Rect carrierHit(int i) {
    final r = carrierIn(i);
    return Rect.fromLTRB(r.left - 2, r.top - 4, r.right + 2, r.bottom + drop + 4);
  }

  /// The road name over carrier [i] (with its lamp at the left).
  Rect labelRect(int i) {
    final r = carrierIn(i);
    return Rect.fromLTWH(r.left - 3, r.top - 22, cw + 6, 17);
  }

  Offset lamp(int i) {
    final l = labelRect(i);
    return Offset(l.left + 6, l.center.dy);
  }

  /// Where the trainee stands (under the LT box, the operating rod to hand).
  Rect get trainee => Rect.fromLTWH(138, groundY - 104, 46, 104);

  /// The van at the roadside.
  Rect get van => Rect.fromLTWH(198, groundY - 64, 150, 58);

  /// The house groups on the horizon, one per road.
  double get horizon => groundY - h * 0.2;
  Offset house(int i) => Offset(22 + i * 88.0, horizon);

  @override
  bool operator ==(Object other) => other is M5FeederGeo && other.height == height && other.groundY == groundY && other.topY == topY;

  @override
  int get hashCode => Object.hash(height, groundY, topY);
}

/// What the scene shows now.
@immutable
class M5FeederRig {
  const M5FeederRig({
    required this.ways,
    required this.inWays,
    required this.held,
    required this.doorOpen,
    required this.phase,
    required this.dusk,
    this.tagged,
    this.soot,
  });

  /// 3 or 4 LT ways.
  final int ways;

  /// The carriers seated in their bases.
  final Set<int> inWays;

  /// The HT DO fuse is shut and holding.
  final bool held;
  final bool doorOpen;

  /// The DO barrel that blows (0..2).
  final int phase;

  /// 0 = early dusk, 1 = evening.
  final double dusk;

  /// The way the red tag hangs on.
  final int? tagged;

  /// The way that blew the HT fuse (soot on its base).
  final int? soot;

  bool lit(int i) => held && inWays.contains(i);

  @override
  bool operator ==(Object other) =>
      other is M5FeederRig &&
      other.ways == ways &&
      setEquals(other.inWays, inWays) &&
      other.held == held &&
      other.doorOpen == doorOpen &&
      other.phase == phase &&
      other.dusk == dusk &&
      other.tagged == tagged &&
      other.soot == soot;

  @override
  int get hashCode => Object.hash(ways, Object.hashAllUnordered(inWays), held, doorOpen, phase, dusk, tagged, soot);
}

const _wire = Color(0xFF2F353A);
const _steel = Color(0xFF6F7880);
const _porcelain = Color(0xFFE9EDF0);

class M5FeederPainter extends CustomPainter {
  const M5FeederPainter({required this.geo, required this.rig, required this.seed});

  final M5FeederGeo geo;
  final M5FeederRig rig;
  final int seed;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    final d = rig.dusk.clamp(0.0, 1.0);
    // Dusk sky: deep blue over a warm band at the horizon.
    final sky = Rect.fromLTWH(0, 0, w, g.horizon);
    c.drawRect(
        sky,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(const Color(0xFF1F2F5C), const Color(0xFF0E1630), d)!,
              Color.lerp(const Color(0xFF5C5A8A), const Color(0xFF2C2E5A), d)!,
              Color.lerp(const Color(0xFFF2A15C), const Color(0xFFB2564A), d)!,
            ],
            stops: const [0, 0.62, 1],
          ).createShader(sky));
    final rnd = math.Random(seed);
    final star = Paint()..color = Color.fromRGBO(255, 255, 255, 0.35 + 0.5 * d);
    for (var i = 0; i < 18; i++) {
      c.drawCircle(Offset(rnd.nextDouble() * w, 40 + rnd.nextDouble() * (g.horizon * 0.45)), 0.8 + rnd.nextDouble() * 0.7, star);
    }
    // Tree line and the village houses, one group per road.
    final tree = Paint()..color = const Color(0xFF1E2B22);
    for (var x = -10.0; x < w + 20; x += 18 + rnd.nextDouble() * 14) {
      final r = 8 + rnd.nextDouble() * 9;
      c.drawCircle(Offset(x, g.horizon - r * 0.4), r, tree);
    }
    for (var i = 0; i < 4; i++) {
      _houses(c, g.house(i), on: i < rig.ways && rig.lit(i));
    }
    // Fields and the crossroads.
    c.drawRect(Rect.fromLTRB(0, g.horizon, w, g.groundY), Paint()..color = Color.lerp(const Color(0xFF4F6B3A), const Color(0xFF2B3A24), d)!);
    final floor = Rect.fromLTRB(0, g.groundY, w, size.height);
    c.drawRect(floor, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF6E5A40), Color(0xFF4A3C2B)]).createShader(floor));
    final road = Paint()..color = const Color(0xFF3B3B40);
    c.drawPath(
        Path()
          ..moveTo(178, g.horizon)
          ..lineTo(196, g.horizon)
          ..lineTo(300, g.groundY)
          ..lineTo(232, g.groundY)
          ..close(),
        road);
    c.drawRect(Rect.fromLTRB(0, g.groundY + 6, w, g.groundY + 30), road);
    _van(c);
    _structure(c);
    if (rig.doorOpen) _board(c);
  }

  void _houses(Canvas c, Offset at, {required bool on}) {
    final wall = Paint()..color = const Color(0xFF3A3530);
    final roof = Paint()..color = const Color(0xFF2A2420);
    final win = Paint()..color = on ? const Color(0xFFFFD36A) : const Color(0xFF1A1A1E);
    for (var k = 0; k < 2; k++) {
      final x = at.dx + k * 30;
      final base = at.dy - (k == 1 ? 2 : 0);
      c.drawRect(Rect.fromLTWH(x, base - 16, 24, 16), wall);
      c.drawPath(
          Path()
            ..moveTo(x - 3, base - 16)
            ..lineTo(x + 12, base - 27)
            ..lineTo(x + 27, base - 16)
            ..close(),
          roof);
      c.drawRect(Rect.fromLTWH(x + 4, base - 12, 6, 5), win);
      c.drawRect(Rect.fromLTWH(x + 14, base - 12, 6, 5), win);
      if (on) c.drawCircle(Offset(x + 12, base - 9), 14, Paint()..color = const Color(0x22FFD36A));
    }
  }

  void _van(Canvas c) {
    final v = geo.van;
    final body = RRect.fromRectAndCorners(v, topLeft: const Radius.circular(6), topRight: const Radius.circular(14), bottomLeft: const Radius.circular(4), bottomRight: const Radius.circular(4));
    c.drawRRect(body.shift(const Offset(2, 3)), Paint()..color = const Color(0x55000000));
    c.drawRRect(body, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE8E4D8), Color(0xFFB7B2A4)]).createShader(v));
    c.drawRect(Rect.fromLTWH(v.left, v.top + v.height * 0.55, v.width, 6), Paint()..color = const Color(0xFF2F6FB0));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(v.right - 40, v.top + 8, 30, 18), const Radius.circular(3)), Paint()..color = const Color(0xFF2B3A4E));
    // The docket on the door (read it on its card).
    c.drawRect(Rect.fromLTWH(v.left + 44, v.top + 10, 22, 16), Paint()..color = const Color(0xFFFDF8EC));
    for (var k = 0; k < 3; k++) {
      c.drawLine(Offset(v.left + 47, v.top + 14 + k * 4.0), Offset(v.left + 63, v.top + 14 + k * 4.0), Paint()
        ..color = const Color(0xFF6E6A60)
        ..strokeWidth = 1);
    }
    final tyre = Paint()..color = const Color(0xFF1A1A1C);
    c.drawCircle(Offset(v.left + 30, v.bottom), 9, tyre);
    c.drawCircle(Offset(v.right - 28, v.bottom), 9, tyre);
    // The megger case on the ground by the van.
    final m = Rect.fromLTWH(v.left - 6, v.bottom - 14, 22, 15);
    c.drawRRect(RRect.fromRectAndRadius(m, const Radius.circular(3)), Paint()..color = const Color(0xFFB8432E));
    c.drawRect(Rect.fromLTWH(m.left + 7, m.top - 3, 8, 3), Paint()..color = const Color(0xFF3A3F45));
  }

  void _insulator(Canvas c, Offset base) {
    final body = Paint()..color = _porcelain;
    for (var i = 0; i < 3; i++) {
      c.drawOval(Rect.fromCenter(center: base.translate(0, -4 - i * 5.0), width: 15 - i * 2.5, height: 5), body);
    }
  }

  void _structure(Canvas c) {
    final g = geo;
    for (final x in [M5FeederGeo.lp, M5FeederGeo.rp]) {
      final r = Rect.fromLTRB(x - 5, g.topY, x + 5, g.groundY + 4);
      c.drawRect(r, Paint()..shader = const LinearGradient(colors: [Color(0xFF6C737A), Color(0xFFA9AEB2), Color(0xFF5E656B)]).createShader(r));
    }
    final arm = Paint()
      ..color = const Color(0xFF4E565D)
      ..strokeWidth = 7;
    c.drawLine(Offset(M5FeederGeo.lp - 20, g.armY), Offset(M5FeederGeo.rp + 20, g.armY), arm);
    c.drawLine(Offset(M5FeederGeo.lp - 14, g.doArmY), Offset(M5FeederGeo.rp + 14, g.doArmY), arm);
    c.drawLine(Offset(M5FeederGeo.lp - 8, g.platformY), Offset(M5FeederGeo.rp + 8, g.platformY), arm);
    // The 11 kV line coming in from the left, over the insulators.
    final line = Paint()
      ..color = _wire
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    for (final (i, x) in M5FeederGeo.phaseX.indexed) {
      _insulator(c, Offset(x, g.armY - 3));
      c.drawPath(
          Path()
            ..moveTo(0, g.armY - 30 + i * 4.0)
            ..quadraticBezierTo(x * 0.5, g.armY - 6 + i * 3.0, x, g.armY - 18),
          line);
      // Jumper down to the DO top.
      final t = g.barrelTop(i);
      c.drawPath(
          Path()
            ..moveTo(x, g.armY - 18)
            ..cubicTo(x - 10, g.armY + 8, t.dx - 10, t.dy - 18, t.dx, t.dy - 4),
          line);
      _barrel(c, i);
      // The lead on to the HT bushing.
      final b = Offset(g.tank.left + 8 + i * 17.0, g.tank.top - 8);
      c.drawPath(
          Path()
            ..moveTo(t.dx, t.dy + 34)
            ..cubicTo(t.dx, t.dy + 52, b.dx, b.dy - 20, b.dx, b.dy),
          line);
    }
    _tank(c);
    _ltBox(c);
  }

  void _barrel(Canvas c, int i) {
    final t = geo.barrelTop(i);
    final dropped = i == rig.phase && !rig.held;
    // The DO's insulator body.
    c.drawRect(Rect.fromLTWH(t.dx - 3, t.dy - 6, 6, 6), Paint()..color = _steel);
    c.drawRect(Rect.fromLTWH(t.dx - 3, t.dy + 30, 6, 6), Paint()..color = _steel);
    c.save();
    c.translate(t.dx, t.dy + 34);
    // A dropped barrel swings out about its bottom hinge.
    if (dropped) c.rotate(-0.75);
    final tube = Rect.fromLTWH(-3.5, -32, 7, 30);
    c.drawRRect(RRect.fromRectAndRadius(tube, const Radius.circular(2)),
        Paint()..shader = LinearGradient(colors: dropped ? const [Color(0xFF3A2A1E), Color(0xFF6A4A30)] : const [Color(0xFF7B5A3A), Color(0xFFA77E52)]).createShader(tube));
    if (dropped) {
      // Soot round the blown end.
      c.drawCircle(const Offset(0, -30), 6, Paint()..color = const Color(0x99202020));
    }
    c.restore();
  }

  void _tank(Canvas c) {
    final t = geo.tank;
    final body = RRect.fromRectAndRadius(t, const Radius.circular(4));
    c.drawRRect(body, Paint()..shader = const LinearGradient(colors: [Color(0xFF55655A), Color(0xFF7F9183), Color(0xFF4C5A50)]).createShader(t));
    final fin = Paint()
      ..color = const Color(0x55212B23)
      ..strokeWidth = 2;
    for (var x = t.left + 7; x < t.right - 3; x += 7) {
      c.drawLine(Offset(x, t.top + 8), Offset(x, t.bottom - 5), fin);
    }
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(t.left + 4, t.top - 18, 22, 10), const Radius.circular(5)), Paint()..color = const Color(0xFF6A7B6E));
    for (var i = 0; i < 3; i++) {
      _insulator(c, Offset(t.left + 8 + i * 17.0, t.top + 2));
    }
    // LT cable down to the box.
    final box = geo.ltBox;
    c.drawPath(
        Path()
          ..moveTo(t.right, t.top + 16)
          ..quadraticBezierTo(M5FeederGeo.rp + 4, t.top + 16, M5FeederGeo.rp + 6, t.top + 40)
          ..lineTo(M5FeederGeo.rp + 6, box.top),
        Paint()
          ..color = const Color(0xFF151618)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke);
  }

  void _ltBox(Canvas c) {
    final b = geo.ltBox;
    final rr = RRect.fromRectAndRadius(b, const Radius.circular(3));
    c.drawRRect(rr, Paint()..shader = const LinearGradient(colors: [Color(0xFF7C858C), Color(0xFFA2AAB0)]).createShader(b));
    c.drawRRect(
        rr,
        Paint()
          ..color = const Color(0xFF3E464C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4);
    if (rig.doorOpen) {
      // The door swung open to the left; the board shows big on the right.
      c.drawRect(Rect.fromLTWH(b.left - 16, b.top + 2, 15, b.height - 4), Paint()..color = const Color(0xFF8C959C));
      c.drawRect(b.deflate(3), Paint()..color = const Color(0xFF1D2226));
      c.drawLine(b.topRight, geo.panel.topLeft.translate(4, 18), Paint()
        ..color = const Color(0x66FFFFFF)
        ..strokeWidth = 1);
      c.drawLine(b.bottomRight, geo.panel.bottomLeft.translate(4, -18), Paint()
        ..color = const Color(0x66FFFFFF)
        ..strokeWidth = 1);
    } else {
      c.drawCircle(Offset(b.right - 6, b.center.dy), 2, Paint()..color = const Color(0xFF2B3036));
    }
  }

  void _board(Canvas c) {
    final g = geo;
    final p = g.panel;
    final rr = RRect.fromRectAndRadius(p, const Radius.circular(10));
    c.drawRRect(rr.shift(const Offset(2, 4)), Paint()..color = const Color(0x77000000));
    c.drawRRect(rr, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8E979E), Color(0xFF6A737A)]).createShader(p));
    final inner = RRect.fromRectAndRadius(p.deflate(5), const Radius.circular(7));
    c.drawRRect(inner, Paint()..color = const Color(0xFF23292E));
    // Busbars across the top.
    for (var k = 0; k < 3; k++) {
      c.drawRect(Rect.fromLTWH(p.left + 12, p.top + 12 + k * 5.0, p.width - 24, 2.4), Paint()..color = const Color(0xFFB87333));
    }
    for (var i = 0; i < rig.ways; i++) {
      _carrier(c, i);
    }
  }

  void _carrier(Canvas c, int i) {
    final g = geo;
    final seat = g.carrierIn(i);
    final isIn = rig.inWays.contains(i);
    // The base (fixed contacts).
    final base = RRect.fromRectAndRadius(seat.inflate(2), const Radius.circular(5));
    c.drawRRect(base, Paint()..color = const Color(0xFF3A4046));
    for (final yy in [seat.top + 6, seat.bottom - 8]) {
      c.drawRect(Rect.fromLTWH(seat.center.dx - 8, yy, 16, 3), Paint()..color = const Color(0xFFB87333));
    }
    if (rig.soot == i) c.drawOval(Rect.fromCenter(center: seat.center, width: seat.width * 0.9, height: seat.height * 0.7), Paint()..color = const Color(0xAA0E0E0E));
    // The lamp for the road.
    final lit = rig.lit(i);
    final lamp = g.lamp(i);
    if (lit) c.drawCircle(lamp, 7, Paint()..color = const Color(0x55FFD36A));
    c.drawCircle(lamp, 3.4, Paint()..color = lit ? const Color(0xFFFFD36A) : const Color(0xFF4A4F55));
    // The carrier: porcelain with a dark grip, seated or hanging out.
    final r = isIn ? seat : g.carrierOut(i);
    final body = RRect.fromRectAndRadius(r.deflate(3), const Radius.circular(6));
    c.drawRRect(body.shift(const Offset(1, 2)), Paint()..color = const Color(0x66000000));
    c.drawRRect(body, Paint()..shader = const LinearGradient(colors: [Color(0xFFD9DEE2), Color(0xFFFFFFFF), Color(0xFFC9CED2)]).createShader(r));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: r.center, width: r.width * 0.42, height: r.height * 0.46), const Radius.circular(4)), Paint()..color = const Color(0xFF2D3338));
    if (rig.tagged == i) {
      // The red tag on its string.
      final top = Offset(r.right - 8, r.top + 8);
      c.drawLine(top, top.translate(6, 14), Paint()
        ..color = const Color(0xFFEDE6D6)
        ..strokeWidth = 1);
      final tag = Path()
        ..moveTo(top.dx + 2, top.dy + 14)
        ..lineTo(top.dx + 14, top.dy + 14)
        ..lineTo(top.dx + 14, top.dy + 34)
        ..lineTo(top.dx + 2, top.dy + 34)
        ..close();
      c.drawPath(tag, Paint()..color = const Color(0xFFD92B2B));
      c.drawCircle(Offset(top.dx + 8, top.dy + 18), 1.6, Paint()..color = const Color(0xFFEDE6D6));
    }
  }

  @override
  bool shouldRepaint(M5FeederPainter old) => old.geo != geo || old.rig != rig || old.seed != seed;
}

/// The trainee's operating rod closing the dropped DO barrel, [t] 0 → 1.
class M5FeederRodPainter extends CustomPainter {
  const M5FeederRodPainter({required this.geo, required this.phase, required this.t});
  final M5FeederGeo geo;
  final int phase;
  final double t;

  @override
  void paint(Canvas c, Size size) {
    final hand = Offset(geo.trainee.left + 10, geo.trainee.top + 40);
    final top = geo.barrelTop(phase).translate(0, 4);
    final reach = Offset.lerp(hand.translate(-10, -60), top, Curves.easeOut.transform(t.clamp(0.0, 1.0)))!;
    c.drawLine(hand, reach, Paint()
      ..color = const Color(0xFFE0B23A)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round);
    c.drawCircle(reach, 3, Paint()..color = const Color(0xFF8A6A1E));
  }

  @override
  bool shouldRepaint(M5FeederRodPainter old) => old.t != t || old.phase != phase || old.geo != geo;
}

/// The HT DO fuse blowing: a flash and arc at the barrel, [v] 0 → 1. [fire]:
/// the deadly case — the flash runs on into the transformer and flames rise.
class M5FeederBlastPainter extends CustomPainter {
  const M5FeederBlastPainter({required this.geo, required this.phase, required this.v, this.fire = false});
  final M5FeederGeo geo;
  final int phase;
  final double v;
  final bool fire;

  @override
  void paint(Canvas c, Size size) {
    final at = geo.barrelTop(phase).translate(0, 8);
    final vv = v.clamp(0.0, 1.0);
    final flick = vv < 0.5 ? (0.65 + 0.35 * math.sin(vv * 60).abs()) : (1 - (vv - 0.5) * 1.4).clamp(0.0, 1.0);
    final r = 18 + (fire ? 80 : 46) * Curves.easeOut.transform(vv);
    c.drawCircle(
        at,
        r,
        Paint()
          ..shader = RadialGradient(colors: [Color.fromRGBO(255, 250, 220, 0.95 * flick), Color.fromRGBO(140, 170, 255, 0.55 * flick), const Color(0x00FFC24A)])
              .createShader(Rect.fromCircle(center: at, radius: r)));
    // The arc down the lead.
    final arc = Paint()
      ..color = Color.fromRGBO(200, 220, 255, flick)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final rnd = math.Random((vv * 20).floor());
    final path = Path()..moveTo(at.dx, at.dy);
    var p = at;
    final to = geo.tank.topCenter;
    for (var k = 1; k <= 6; k++) {
      final q = Offset.lerp(at, to, k / 6)!;
      p = q.translate(rnd.nextDouble() * 10 - 5, 0);
      path.lineTo(p.dx, p.dy);
    }
    if (vv < 0.7) c.drawPath(path, arc);
    final spark = Paint()
      ..color = Color.fromRGBO(255, 214, 90, (1 - vv).clamp(0.0, 1.0))
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 14; i++) {
      final a = i / 14 * math.pi * 2 + 0.3;
      final d0 = 8 + 40 * vv;
      c.drawLine(at + Offset(math.cos(a), math.sin(a)) * d0, at + Offset(math.cos(a), math.sin(a)) * (d0 + 10), spark);
    }
    if (fire) {
      final t = geo.tank;
      for (var k = 0; k < 5; k++) {
        final x = t.left + 6 + k * 10.0;
        final hgt = (22 + 18 * math.sin(k * 1.7 + vv * 6).abs()) * vv;
        c.drawPath(
            Path()
              ..moveTo(x - 6, t.top)
              ..quadraticBezierTo(x, t.top - hgt * 1.4, x + 6, t.top)
              ..close(),
            Paint()..color = Color.fromRGBO(255, 120 + k * 20, 40, 0.85 * vv));
      }
      final white = (1 - vv * 4).clamp(0.0, 1.0);
      if (white > 0) c.drawRect(Offset.zero & size, Paint()..color = Color.fromRGBO(255, 255, 255, 0.75 * white));
    }
  }

  @override
  bool shouldRepaint(M5FeederBlastPainter old) => old.v != v || old.phase != phase || old.fire != fire || old.geo != geo;
}

/// The hold ring round the dropped DO barrel: fills while it is held.
class M5FeederRingPainter extends CustomPainter {
  M5FeederRingPainter({required this.fill}) : super(repaint: fill);
  final Animation<double> fill;

  @override
  void paint(Canvas c, Size size) {
    final ctr = size.center(Offset.zero);
    final r = math.min(size.width, size.height) / 2 - 4;
    c.drawCircle(
        ctr,
        r,
        Paint()
          ..color = const Color(0x88FFE08A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    final v = fill.value;
    if (v > 0) {
      c.drawArc(
          Rect.fromCircle(center: ctr, radius: r),
          -math.pi / 2,
          math.pi * 2 * v,
          false,
          Paint()
            ..color = const Color(0xFFFFC94A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(M5FeederRingPainter old) => old.fill != fill;
}
