import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The drawn world of lesson 3.9 কাজ 2 "জাল মেরামত" (m3_guard_repair.dart): an
// 11 kV line crossing a village road between two PCC poles, the three
// conductors on their cross-arms, and under them the cradle guarding — two
// longitudinal GI guard wires on the guard arms with GI lacings woven across
// like a cradle, earthed at each pole (an earth lead down the pole to an earth
// pit). Layered: the afternoon sky, the far fields and trees, the road running
// away under the span (a lorry on it, or cones across it once the traffic is
// held), the poles, the wires; then what the work brings — the portable earth
// set on the conductors, the red tags on what he found, the green ones on what
// he put right, a GI pipe up the pole for the new earth lead, the clearance
// check. Code-drawn, gradients, no bitmaps, no text except the cones' STOP
// board. Design space 360 wide; a tall phone gets more sky.

/// What can be wrong with the cradle.
enum M3GuardFaultKind { sag, lacing, clamp, earth }

/// One fault on the cradle: [side] 0 = the left pole's half, 1 = the right
/// one's; [lacing] = which lacing (0–5) for a snapped one.
@immutable
class M3GuardFault {
  const M3GuardFault(this.kind, {this.side = 0, this.lacing = 0});
  final M3GuardFaultKind kind;
  final int side;
  final int lacing;

  @override
  bool operator ==(Object other) => other is M3GuardFault && other.kind == kind && other.side == side && other.lacing == lacing;

  @override
  int get hashCode => Object.hash(kind, side, lacing);
}

/// Where things are (design px, 360 wide).
@immutable
class M3GuardGeo {
  const M3GuardGeo._(this.height, this.groundY, this.poleH);

  factory M3GuardGeo.forScene(double height, double inset) {
    final g = height - 128 - inset * 0.5;
    return M3GuardGeo._(height, g, math.min(420.0, g - 160));
  }

  final double height;

  /// Where the poles stand.
  final double groundY;

  /// The poles' height above the ground.
  final double poleH;

  static const leftX = 44.0;
  static const rightX = 316.0;
  static double poleX(int side) => side == 0 ? leftX : rightX;

  double get poleTop => groundY - poleH;
  double get armY => poleTop + 16;
  double get guardY => armY + poleH * 0.2;
  double get horizonY => groundY - poleH * 0.35;

  /// A conductor's height at [x] (phase 0 = the lowest).
  double conductorY(int phase, double x) => armY - 6 - phase * 8 + _dip(x, leftX, rightX, 14);

  /// The guard wires' ends (the clamps on the guard arms).
  static const frontL = leftX + 18;
  static const frontR = rightX - 18;
  static const backL = leftX + 26;
  static const backR = rightX - 10;

  /// The lacings' x on the front wire.
  static const lacingX = [96.0, 130.0, 164.0, 198.0, 232.0, 266.0];

  /// The two halves of the front wire (the sag lives in one).
  static const midX = 180.0;
  static (double, double) half(int side) => side == 0 ? (frontL, midX) : (midX, frontR);

  /// Which half lacing [i] is in.
  static int lacingSide(int i) => lacingX[i] < midX ? 0 : 1;

  /// The extra sag of a slack guard wire at mid-half (tension 0).
  double get slackExtra => poleH * 0.09;

  static double _dip(double x, double a, double b, double d) {
    if (x <= a || x >= b) return 0;
    return d * math.sin(math.pi * (x - a) / (b - a));
  }

  /// The front guard wire's height at [x] ([slack] = the slack half or null;
  /// [t] its tension 0 → 1, a little past 1 = pulled too tight).
  double frontY(double x, {int? slack, double t = 1}) {
    var y = guardY + _dip(x, frontL, frontR, 10);
    if (slack != null) {
      final (a, b) = half(slack);
      y += _dip(x, a, b, slackExtra * (1 - t));
    }
    return y;
  }

  double backY(double x) => guardY - 12 + _dip(x, backL, backR, 10);

  /// Where a fault is (its tag hangs here).
  Offset anchor(M3GuardFault f, {double t = 0}) => switch (f.kind) {
        M3GuardFaultKind.sag => () {
            final (a, b) = half(f.side);
            final x = (a + b) / 2;
            return Offset(x, frontY(x, slack: f.side, t: t));
          }(),
        M3GuardFaultKind.lacing => Offset(lacingX[f.lacing] + 4, frontY(lacingX[f.lacing]) + 14),
        M3GuardFaultKind.clamp => Offset(f.side == 0 ? frontL : frontR, guardY),
        M3GuardFaultKind.earth => Offset(poleX(f.side) + (f.side == 0 ? 6 : -6), guardY + poleH * 0.17),
      };

  /// Every place a fault can be dealt (the page treats a tap on a sound
  /// lacing, clamp or earth spot, well clear of the dealt faults, as a wrong
  /// flag).
  static const spots = [
    M3GuardFault(M3GuardFaultKind.sag),
    M3GuardFault(M3GuardFaultKind.sag, side: 1),
    M3GuardFault(M3GuardFaultKind.lacing),
    M3GuardFault(M3GuardFaultKind.lacing, lacing: 1),
    M3GuardFault(M3GuardFaultKind.lacing, lacing: 2),
    M3GuardFault(M3GuardFaultKind.lacing, lacing: 3),
    M3GuardFault(M3GuardFaultKind.lacing, lacing: 4),
    M3GuardFault(M3GuardFaultKind.lacing, lacing: 5),
    M3GuardFault(M3GuardFaultKind.clamp),
    M3GuardFault(M3GuardFaultKind.clamp, side: 1),
    M3GuardFault(M3GuardFaultKind.earth),
    M3GuardFault(M3GuardFaultKind.earth, side: 1),
  ];

  /// A generic sweep along the whole cradle (both poles' ends, both halves):
  /// the gesture hint's "tap on the net", never pointing at a fault.
  List<Rect> get cradleSweep => [
        for (final x in const [frontL + 6, 124.0, 236.0, frontR - 6]) Rect.fromCenter(center: Offset(x, guardY + 8), width: 44, height: 40),
      ];

  /// The tap area of a fault.
  Rect hit(M3GuardFault f, {double t = 0}) {
    final a = anchor(f, t: t);
    return switch (f.kind) {
      M3GuardFaultKind.sag => Rect.fromCenter(center: a.translate(0, -slackExtra * 0.3), width: 84, height: 58 + slackExtra * 0.6),
      M3GuardFaultKind.lacing => Rect.fromCenter(center: a.translate(0, -4), width: 28, height: 46),
      M3GuardFaultKind.clamp => Rect.fromCenter(center: a, width: 28, height: 40),
      M3GuardFaultKind.earth => Rect.fromCenter(center: a, width: 40, height: poleH * 0.24),
    };
  }

  /// The trainee on the road side by the left pole, or up on it at the guard arm.
  Rect traineeGround() => Rect.fromLTWH(60, groundY - 116, 58, 116);
  Rect traineeUp() => Rect.fromLTWH(12, guardY + poleH * 0.12 - 96, 48, 96);

  /// Where the tester lamp and the earth clamps go (the left pole's span end).
  Offset get testAt => Offset(leftX + 30, conductorY(1, leftX + 30));
  Offset get earthRod => Offset(leftX + 40, groundY + 10);

  @override
  bool operator ==(Object other) => other is M3GuardGeo && other.height == height && other.groundY == groundY && other.poleH == poleH;

  @override
  int get hashCode => Object.hash(height, groundY, poleH);
}

/// What the scene shows now.
@immutable
class M3GuardState {
  const M3GuardState({
    required this.faults,
    required this.tagged,
    required this.fixed,
    required this.tension,
    required this.pipeOn,
    required this.earthSet,
    required this.traffic,
    required this.measured,
    required this.seed,
  });

  final List<M3GuardFault> faults;

  /// Faults found (a red tag).
  final Set<int> tagged;

  /// Faults put right (a green tag; the cradle drawn whole there).
  final Set<int> fixed;

  /// The slack wire's tension (0 → 1; past 1 = too tight).
  final double tension;

  /// The pole (side) has its new GI pipe for the earth lead.
  final Set<int> pipeOn;

  /// The portable earth set is on the conductors.
  final bool earthSet;

  /// The traffic is held (cones across the road).
  final bool traffic;

  /// The clearance check shows.
  final bool measured;
  final int seed;

  M3GuardFault? _open(M3GuardFaultKind k) {
    for (final (i, f) in faults.indexed) {
      if (f.kind == k && !fixed.contains(i)) return f;
    }
    return null;
  }

  int? get slackSide => _open(M3GuardFaultKind.sag)?.side;
  int? get brokenLacing => _open(M3GuardFaultKind.lacing)?.lacing;
  int? get looseClamp => _open(M3GuardFaultKind.clamp)?.side;
  int? get stolenEarth => _open(M3GuardFaultKind.earth)?.side;

  @override
  bool operator ==(Object other) =>
      other is M3GuardState &&
      listEquals(other.faults, faults) &&
      setEquals(other.tagged, tagged) &&
      setEquals(other.fixed, fixed) &&
      other.tension == tension &&
      setEquals(other.pipeOn, pipeOn) &&
      other.earthSet == earthSet &&
      other.traffic == traffic &&
      other.measured == measured &&
      other.seed == seed;

  @override
  int get hashCode => Object.hash(Object.hashAll(faults), Object.hashAllUnordered(tagged), Object.hashAllUnordered(fixed), tension, Object.hashAllUnordered(pipeOn), earthSet, traffic, measured, seed);
}

/// The road crossing: sky, fields, road, poles, line, cradle and what is on it.
class M3GuardWorldPainter extends CustomPainter {
  const M3GuardWorldPainter({required this.geo, required this.s});

  final M3GuardGeo geo;
  final M3GuardState s;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    // Sky and sun.
    c.drawRect(
        Rect.fromLTWH(0, 0, w, g.horizonY + 2),
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF6FA2D6), Color(0xFFCFE3EE)])
              .createShader(Rect.fromLTWH(0, 0, w, g.horizonY + 2)));
    final sun = Offset(70, g.poleTop - 30);
    c.drawCircle(sun, 40, Paint()..shader = const RadialGradient(colors: [Color(0x66FFF3C4), Color(0x00FFF3C4)]).createShader(Rect.fromCircle(center: sun, radius: 40)));
    c.drawCircle(sun, 13, Paint()..color = const Color(0xFFFFF0B8));
    // Clouds.
    final cloud = Paint()..color = const Color(0xCCFFFFFF);
    for (final (x, y) in [(220.0, g.poleTop - 50), (300.0, g.poleTop + 30)]) {
      c.drawOval(Rect.fromCenter(center: Offset(x, y), width: 70, height: 16), cloud);
      c.drawOval(Rect.fromCenter(center: Offset(x - 12, y - 7), width: 34, height: 16), cloud);
    }
    // The far tree line and fields.
    final rnd = math.Random(s.seed);
    final tree = Paint()..color = const Color(0xFF4F7D45);
    for (var x = -10.0; x < w + 20; x += 18 + rnd.nextDouble() * 16) {
      final r = 7 + rnd.nextDouble() * 7;
      c.drawCircle(Offset(x, g.horizonY - r * 0.5), r, tree);
    }
    final field = Rect.fromLTRB(0, g.horizonY, w, size.height);
    c.drawRect(field, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8DB25C), Color(0xFF5E8A3C)]).createShader(field));
    _road(c, size);
    _traffic(c);
    _pole(c, M3GuardGeo.leftX, 0);
    _pole(c, M3GuardGeo.rightX, 1);
    _earthLeads(c);
    _conductors(c);
    _cradle(c);
    if (s.earthSet) _portableEarth(c);
    if (s.measured) _clearance(c);
    _tags(c);
  }

  void _road(Canvas c, Size size) {
    final g = geo;
    final road = Path()
      ..moveTo(166, g.horizonY)
      ..lineTo(194, g.horizonY)
      ..lineTo(300, size.height)
      ..lineTo(60, size.height)
      ..close();
    c.drawPath(road, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8C8C88), Color(0xFF55575A)]).createShader(Rect.fromLTRB(60, g.horizonY, 300, size.height)));
    // The centre line, dashes growing toward us.
    final dash = Paint()..color = const Color(0xCCF2F2E6);
    var y = g.horizonY + 6;
    var len = 4.0;
    while (y < size.height) {
      final k = (y - g.horizonY) / (size.height - g.horizonY);
      c.drawRect(Rect.fromCenter(center: Offset(180, y + len / 2), width: 1 + 3 * k, height: len), dash);
      y += len * 2.2;
      len *= 1.18;
    }
  }

  /// A lorry on the road; held behind cones (with a STOP board) once the traffic is controlled.
  void _traffic(Canvas c) {
    final g = geo;
    final held = s.traffic;
    final ly = held ? g.horizonY + (g.groundY - g.horizonY) * 0.35 : g.groundY + 22;
    final k = 0.45 + 0.55 * ((ly - g.horizonY) / (g.groundY + 40 - g.horizonY)).clamp(0.0, 1.0);
    final body = Rect.fromCenter(center: Offset(186, ly - 22 * k), width: 46 * k, height: 40 * k);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(4 * k)), Paint()..color = const Color(0xFF2F6F9E));
    final cab = Rect.fromLTWH(body.left + 6 * k, body.top - 14 * k, body.width - 12 * k, 16 * k);
    c.drawRRect(RRect.fromRectAndRadius(cab, Radius.circular(3 * k)), Paint()..color = const Color(0xFFD9483B));
    c.drawRect(cab.deflate(3 * k), Paint()..color = const Color(0xFF9FD0F0));
    c.drawCircle(Offset(body.left + 8 * k, body.bottom + 2), 5 * k, Paint()..color = const Color(0xFF1A1A1A));
    c.drawCircle(Offset(body.right - 8 * k, body.bottom + 2), 5 * k, Paint()..color = const Color(0xFF1A1A1A));
    if (!held) return;
    final cy = g.groundY + 18;
    for (var i = 0; i < 5; i++) {
      final x = 98 + i * 41.0;
      final cone = Path()
        ..moveTo(x, cy - 22)
        ..lineTo(x + 8, cy)
        ..lineTo(x - 8, cy)
        ..close();
      c.drawPath(cone, Paint()..color = const Color(0xFFFF7A1A));
      c.drawRect(Rect.fromLTRB(x - 5, cy - 12, x + 5, cy - 8), Paint()..color = Colors.white);
      c.drawRect(Rect.fromLTRB(x - 10, cy, x + 10, cy + 3), Paint()..color = const Color(0xFF3A3A3A));
    }
    // The STOP board on its stand by the left cones.
    final b = Offset(82, cy - 40);
    c.drawLine(b, Offset(b.dx, cy + 2), Paint()
      ..color = const Color(0xFF444444)
      ..strokeWidth = 2.5);
    c.drawCircle(b, 13, Paint()..color = const Color(0xFFD7261E));
    c.drawCircle(b, 13, Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6);
    _label(c, 'STOP', b, 7.5, Colors.white);
  }

  void _pole(Canvas c, double x, int side) {
    final g = geo;
    final pole = Rect.fromLTRB(x - 6, g.poleTop, x + 6, g.groundY + 4);
    c.drawRect(pole, Paint()..shader = const LinearGradient(colors: [Color(0xFF9C9A94), Color(0xFFD8D5CC), Color(0xFF8E8C86)]).createShader(pole));
    c.drawOval(Rect.fromCenter(center: Offset(x, g.groundY + 4), width: 22, height: 6), Paint()..color = const Color(0x55000000));
    // Step bolts.
    final bolt = Paint()
      ..color = const Color(0xFF55585C)
      ..strokeWidth = 2;
    for (var y = g.guardY + 30; y < g.groundY - 40; y += 26) {
      c.drawLine(Offset(x - 9, y), Offset(x + 9, y), bolt);
    }
    // The line cross-arm and its three pin insulators.
    final arm = Paint()
      ..color = const Color(0xFF4A4F55)
      ..strokeWidth = 5;
    c.drawLine(Offset(x - 26, g.armY), Offset(x + 26, g.armY), arm);
    for (var i = 0; i < 3; i++) {
      final at = Offset(x, g.conductorY(i, x));
      final ins = Rect.fromCenter(center: at.translate(0, 5), width: 9, height: 12);
      c.drawRRect(RRect.fromRectAndRadius(ins, const Radius.circular(3)), Paint()..color = const Color(0xFFF2EEE4));
      for (var k = 0; k < 3; k++) {
        c.drawLine(Offset(ins.left - 1, ins.top + 3 + k * 3.2), Offset(ins.right + 1, ins.top + 3 + k * 3.2), Paint()
          ..color = const Color(0xFFBDB6A6)
          ..strokeWidth = 1);
      }
      c.drawLine(at.translate(0, 11), Offset(x + (i - 1) * 12.0, g.armY), Paint()
        ..color = const Color(0xFF6A6F75)
        ..strokeWidth = 1.6);
    }
    // The guard arm.
    c.drawLine(Offset(x - 22, g.guardY - 6), Offset(x + 22, g.guardY - 6), Paint()
      ..color = const Color(0xFF5B6067)
      ..strokeWidth = 4.5);
  }

  void _earthLeads(Canvas c) {
    final g = geo;
    for (final side in [0, 1]) {
      final x = M3GuardGeo.poleX(side) + (side == 0 ? 7.5 : -7.5);
      final pitAt = Offset(x + (side == 0 ? 8 : -8), g.groundY + 8);
      // The earth pit's cover.
      c.drawRect(Rect.fromCenter(center: pitAt, width: 18, height: 8), Paint()..color = const Color(0xFF9E9A90));
      c.drawRect(Rect.fromCenter(center: pitAt, width: 18, height: 8), Paint()
        ..color = const Color(0xFF6E6A60)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);
      final lead = Paint()
        ..color = const Color(0xFF8A9096)
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke;
      final top = Offset(x, g.guardY - 6);
      final stolen = s.stolenEarth == side;
      final piped = s.pipeOn.contains(side);
      final pipeTop = g.groundY - g.poleH * 0.26;
      if (piped) {
        final pipe = Rect.fromLTRB(x - 3, pipeTop, x + 3, g.groundY + 2);
        c.drawRect(pipe, Paint()..shader = const LinearGradient(colors: [Color(0xFF7D8388), Color(0xFFC9CED2), Color(0xFF6E7378)]).createShader(pipe));
        for (final y in [pipeTop + 20, g.groundY - 30]) {
          c.drawRect(Rect.fromLTRB(x - 5, y, x + 5, y + 3), Paint()..color = const Color(0xFF4A4F55));
        }
      }
      if (stolen) {
        // Cut: a frayed stub under the guard arm and one at the pit.
        c.drawLine(top, top.translate(0, 14), lead);
        _fray(c, top.translate(0, 14));
        if (!piped) {
          c.drawLine(Offset(x, g.groundY - 10), Offset(x, g.groundY + 4), lead);
          _fray(c, Offset(x, g.groundY - 10));
        }
        continue;
      }
      c.drawLine(top, Offset(x, piped ? pipeTop : g.groundY + 4), lead);
      c.drawLine(Offset(x, g.groundY + 4), pitAt, lead);
    }
  }

  void _fray(Canvas c, Offset at) {
    final p = Paint()
      ..color = const Color(0xFFB8BEC4)
      ..strokeWidth = 1.2;
    for (final dx in [-3.0, 0.0, 3.0]) {
      c.drawLine(at, at.translate(dx, 4), p);
    }
  }

  void _conductors(Canvas c) {
    final g = geo;
    final p = Paint()
      ..color = const Color(0xFF3B3F44)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 3; i++) {
      final path = Path()..moveTo(-4, g.conductorY(i, M3GuardGeo.leftX) - 4);
      path.lineTo(M3GuardGeo.leftX, g.conductorY(i, M3GuardGeo.leftX));
      for (var x = M3GuardGeo.leftX; x <= M3GuardGeo.rightX; x += 6) {
        path.lineTo(x, g.conductorY(i, x));
      }
      path.lineTo(364, g.conductorY(i, M3GuardGeo.rightX) - 4);
      c.drawPath(path, p);
    }
  }

  void _cradle(Canvas c) {
    final g = geo;
    final slack = s.slackSide;
    final t = s.tension;
    final gi = Paint()
      ..color = const Color(0xFF9AA2A9)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final giBack = Paint()
      ..color = const Color(0xFF7D858C)
      ..strokeWidth = 1.7
      ..style = PaintingStyle.stroke;
    double fy(double x) => g.frontY(x, slack: slack, t: t);
    // The back guard wire.
    final back = Path()..moveTo(M3GuardGeo.backL, g.backY(M3GuardGeo.backL));
    for (var x = M3GuardGeo.backL; x <= M3GuardGeo.backR; x += 6) {
      back.lineTo(x, g.backY(x));
    }
    c.drawPath(back, giBack);
    // The lacings: a U from the front wire under the line to the back wire.
    final broken = s.brokenLacing;
    for (var k = 0; k < M3GuardGeo.lacingX.length; k++) {
      final x = M3GuardGeo.lacingX[k];
      final a = Offset(x, fy(x));
      final b = Offset(x + 8, g.backY(x + 8));
      final low = math.max(a.dy, b.dy) + 12;
      if (broken == k) {
        // Snapped: two ends hang loose.
        c.drawPath(Path()
          ..moveTo(a.dx, a.dy)
          ..quadraticBezierTo(a.dx - 1, a.dy + 10, a.dx - 4, a.dy + 15), gi);
        c.drawPath(Path()
          ..moveTo(b.dx, b.dy)
          ..quadraticBezierTo(b.dx + 2, b.dy + 9, b.dx + 5, b.dy + 13), giBack);
        continue;
      }
      c.drawPath(
          Path()
            ..moveTo(a.dx, a.dy)
            ..cubicTo(a.dx, low, b.dx, low, b.dx, b.dy),
          gi);
    }
    // The front guard wire (the slack half dips; a loose clamp lets its end slip).
    final loose = s.looseClamp;
    final front = Path();
    var first = true;
    for (var x = M3GuardGeo.frontL; x <= M3GuardGeo.frontR + 0.1; x += 4) {
      var y = fy(x);
      if (loose != null) {
        final end = loose == 0 ? M3GuardGeo.frontL : M3GuardGeo.frontR;
        final d = (x - end).abs();
        if (d < 40) y += 7 * (1 - d / 40);
      }
      if (first) {
        front.moveTo(x, y);
        first = false;
      } else {
        front.lineTo(x, y);
      }
    }
    c.drawPath(
        front,
        Paint()
          ..color = const Color(0xFFB4BBC1)
          ..strokeWidth = 2.4
          ..style = PaintingStyle.stroke);
    // The clamps at the guard arms (a loose one: plates apart, bolt out).
    for (final side in [0, 1]) {
      final at = Offset(side == 0 ? M3GuardGeo.frontL : M3GuardGeo.frontR, g.guardY);
      final isLoose = loose == side;
      final plate = Paint()..color = const Color(0xFF4D5359);
      c.drawRect(Rect.fromCenter(center: at.translate(0, isLoose ? -4 : -2), width: 10, height: 4), plate);
      c.drawRect(Rect.fromCenter(center: at.translate(0, isLoose ? 6 : 2), width: 10, height: 4), plate);
      c.drawLine(at.translate(-3, isLoose ? -7 : -4), at.translate(-3, isLoose ? 2 : 4), Paint()
        ..color = const Color(0xFF2B2F33)
        ..strokeWidth = 1.6);
      c.drawLine(Offset(at.dx, g.guardY - 6), at.translate(0, -3), Paint()
        ..color = const Color(0xFF4D5359)
        ..strokeWidth = 2);
    }
  }

  void _portableEarth(Canvas c) {
    final g = geo;
    final rod = g.earthRod;
    final lead = Paint()
      ..color = const Color(0xFFC9892E)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    c.drawLine(rod.translate(0, -16), rod.translate(0, 6), Paint()
      ..color = const Color(0xFF6E7378)
      ..strokeWidth = 3);
    for (var i = 0; i < 3; i++) {
      final x = M3GuardGeo.leftX + 24 + i * 6.0;
      final at = Offset(x, g.conductorY(i, x));
      c.drawRect(Rect.fromCenter(center: at.translate(0, 3), width: 7, height: 7), Paint()..color = const Color(0xFFE0B04A));
      c.drawPath(
          Path()
            ..moveTo(at.dx, at.dy + 6)
            ..quadraticBezierTo(at.dx + 26, (at.dy + rod.dy) / 2, rod.dx, rod.dy - 14),
          lead);
    }
  }

  void _clearance(Canvas c) {
    final g = geo;
    const x = M3GuardGeo.midX + 24;
    final top = g.conductorY(0, x) + 3;
    final bottom = g.frontY(x) - 3;
    final p = Paint()
      ..color = const Color(0xFF2EBD5A)
      ..strokeWidth = 2.2;
    c.drawLine(Offset(x, top), Offset(x, bottom), p);
    for (final (y, d) in [(top, 1.0), (bottom, -1.0)]) {
      c.drawPath(
          Path()
            ..moveTo(x, y)
            ..lineTo(x - 5, y + 7 * d)
            ..lineTo(x + 5, y + 7 * d)
            ..close(),
          Paint()..color = const Color(0xFF2EBD5A));
    }
    final mid = Offset(x + 16, (top + bottom) / 2);
    c.drawCircle(mid, 9, Paint()..color = const Color(0xFF2EBD5A));
    c.drawPath(
        Path()
          ..moveTo(mid.dx - 4, mid.dy)
          ..lineTo(mid.dx - 1, mid.dy + 3.5)
          ..lineTo(mid.dx + 4.5, mid.dy - 3.5),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke);
  }

  /// A red tag on what he found; a green tick on what he put right.
  void _tags(Canvas c) {
    for (final (i, f) in s.faults.indexed) {
      final ok = s.fixed.contains(i);
      if (!ok && !s.tagged.contains(i)) continue;
      final a = geo.anchor(f, t: s.tension);
      final at = Offset(a.dx + (f.kind == M3GuardFaultKind.earth ? (f.side == 0 ? 14 : -26) : 6), a.dy + 6);
      c.drawLine(a, at, Paint()
        ..color = const Color(0xFF333333)
        ..strokeWidth = 1);
      final tag = RRect.fromRectAndRadius(Rect.fromLTWH(at.dx, at.dy, 13, 17), const Radius.circular(2.5));
      c.drawRRect(tag, Paint()..color = ok ? const Color(0xFF2EBD5A) : const Color(0xFFD7261E));
      c.drawRRect(tag, Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);
      if (ok) {
        c.drawPath(
            Path()
              ..moveTo(at.dx + 3, at.dy + 9)
              ..lineTo(at.dx + 5.5, at.dy + 12)
              ..lineTo(at.dx + 10, at.dy + 5),
            Paint()
              ..color = Colors.white
              ..strokeWidth = 1.8
              ..style = PaintingStyle.stroke);
      } else {
        c.drawLine(at.translate(6.5, 4), at.translate(6.5, 10), Paint()
          ..color = Colors.white
          ..strokeWidth = 2);
        c.drawCircle(at.translate(6.5, 13), 1.2, Paint()..color = Colors.white);
      }
    }
  }

  void _label(Canvas c, String text, Offset centre, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontFamily: 'Roboto', fontSize: size, fontWeight: FontWeight.w900, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(M3GuardWorldPainter old) => old.geo != geo || old.s != s;
}

/// His pole strap round the left pole (the harness) while he is up.
class M3GuardStrapPainter extends CustomPainter {
  const M3GuardStrapPainter({required this.box});
  final Rect box;

  @override
  void paint(Canvas c, Size size) {
    final hip = Offset(box.left + box.width * 0.5, box.top + box.height * 0.5);
    const px = M3GuardGeo.leftX;
    final strap = Paint()
      ..color = const Color(0xFF3A2A16)
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke;
    c.drawPath(
        Path()
          ..moveTo(hip.dx, hip.dy)
          ..quadraticBezierTo(px, hip.dy - 10, px + 8, hip.dy - 6)
          ..moveTo(hip.dx, hip.dy + 2)
          ..quadraticBezierTo(px, hip.dy + 4, px + 8, hip.dy - 6),
        strap);
  }

  @override
  bool shouldRepaint(M3GuardStrapPainter old) => old.box != box;
}

/// The flash where a hand or the earth set met the live line (the deadly
/// moment, in colour over the frozen scene).
class M3GuardArcPainter extends CustomPainter {
  const M3GuardArcPainter({required this.at, required this.v});
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
  bool shouldRepaint(M3GuardArcPainter old) => old.v != v || old.at != at;
}
