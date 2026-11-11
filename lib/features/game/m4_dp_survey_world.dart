import 'dart:math' as math;

import 'package:flutter/material.dart';

// The place for lesson 4.7 কাজ 1 "এলোমেলো স্ট্রাকচার" (m4_dp_survey.dart): a
// double-pole (DP) transformer structure seen from the ground. Top to bottom:
// the HT cross-arm with three pin insulators (the line's bindings), the upper
// jumpers down to the DO fuse arm, the lower jumpers to the transformer's HT
// bushings, the transformer on its platform, the LT cables down to the LT box,
// and on the left pole the LT cross-arm with the outgoing LT wires.
// Each part is drawn tidy or with the fault the deal gives it (the lesson's
// list: tangled jumper, clearance, untidy LT cable, binding wire tail, the
// arms out of level; the myth of insulated wires touching).
// Design space: 360 wide, [M4DpSurveyGeo.height] high. Static painters only.

/// What can be wrong on a DP, top to bottom. The first four are on the HT
/// side, the last two on the LT side (pro tip 1: dress from HT down to LT).
enum M4DpSurveyFault { tail, jumper, tilt, clearance, ltCables, touch }

extension M4DpSurveyFaultSide on M4DpSurveyFault {
  bool get isHt => index <= M4DpSurveyFault.clearance.index;
}

/// The scene's geometry (design px).
@immutable
class M4DpSurveyGeo {
  const M4DpSurveyGeo._(this.height, this.groundY, this.armY);

  factory M4DpSurveyGeo.forScene(double height, double inset) {
    final ground = height - 172 - inset * 0.4;
    final arm = math.max(140.0, ground - _floorGap - 400);
    return M4DpSurveyGeo._(height, ground, arm);
  }

  final double height;
  final double groundY;

  /// The structure's working parts end this far above the ground (the poles
  /// go on down); the corner guide's bubble sits over that strip.
  static const _floorGap = 92.0;

  /// The HT cross-arm.
  final double armY;

  static const poleL = 136.0;
  static const poleR = 264.0;
  static const armLeft = 100.0;
  static const armRight = 300.0;

  /// The three phases on the arms (R, Y, B).
  static const phaseX = [150.0, 200.0, 250.0];

  /// The transformer's HT bushings.
  static const bushX = [178.0, 200.0, 222.0];

  /// The four LT wires on the LT arm.
  static const ltX = [30.0, 58.0, 86.0, 114.0];

  double get span => groundY - _floorGap - armY;
  double y(double f) => armY + span * f;

  /// The DO fuse arm.
  double get doY => y(0.19);

  /// The DO fuse's bottom contact (below the arm).
  double get doDrop => span * 0.11;

  /// The transformer platform (top of the channel the tank stands on).
  double get platY => y(0.72);
  double get tankH => span * 0.17;
  double get bushTopY => platY - tankH - 14;

  /// The LT cross-arm on the left pole.
  double get ltArmY => y(0.56);

  /// The LT box between the poles.
  Rect get ltBox => Rect.fromLTRB(172, y(0.87), 228, y(1.0));

  /// The tilt of the DO arm (radians) when it is out of level.
  static const tiltRad = 0.09;

  /// Where a point on the DO arm at [x] is when the arm tilts.
  double doYAt(double x, {required bool tilt}) => doY + (tilt ? (x - 200) * math.tan(tiltRad) : 0);

  /// The tap zone of each part (no two overlap).
  Rect zoneOf(M4DpSurveyFault f) => switch (f) {
    M4DpSurveyFault.tail => Rect.fromLTRB(104, armY - 44, 290, armY - 7),
    M4DpSurveyFault.jumper => Rect.fromLTRB(104, armY - 6, 290, doY - 14),
    M4DpSurveyFault.tilt => Rect.fromLTRB(118, doY - 13, 300, doY + doDrop + 8),
    M4DpSurveyFault.clearance => Rect.fromLTRB(118, doY + doDrop + 9, 282, bushTopY + 6),
    M4DpSurveyFault.ltCables => Rect.fromLTRB(142, platY + 8, 258, ltBox.bottom + 4),
    M4DpSurveyFault.touch => Rect.fromLTRB(0, ltArmY - 34, 116, ltArmY + 44),
  };

  /// The part tapped at [p], if any.
  M4DpSurveyFault? zoneAt(Offset p) {
    for (final f in M4DpSurveyFault.values) {
      if (zoneOf(f).contains(p)) return f;
    }
    return null;
  }

  /// The trainee's box (on the ground, left of the structure).
  Rect get trainee => Rect.fromLTWH(10, groundY - 82, 41, 86);

  @override
  bool operator ==(Object other) => other is M4DpSurveyGeo && other.height == height && other.groundY == groundY;

  @override
  int get hashCode => Object.hash(height, groundY);
}

/// One structure as dealt: its faults and how they look.
@immutable
class M4DpSurveyLook {
  const M4DpSurveyLook({
    required this.faults,
    this.tailAt = 0,
    this.jumperAt = 1,
    this.bodyClear = false,
    this.plate = 14,
  });

  final Set<M4DpSurveyFault> faults;

  /// The insulator with the binding wire's tail (0..2).
  final int tailAt;

  /// The tangled upper jumper (0..2).
  final int jumperAt;

  /// Clearance: a jumper on the pole (phase to body) instead of two jumpers
  /// close together (phase to phase).
  final bool bodyClear;

  /// The structure number on the pole plate.
  final int plate;

  bool has(M4DpSurveyFault f) => faults.contains(f);

  @override
  bool operator ==(Object other) =>
      other is M4DpSurveyLook &&
      other.tailAt == tailAt &&
      other.jumperAt == jumperAt &&
      other.bodyClear == bodyClear &&
      other.plate == plate &&
      other.faults.length == faults.length &&
      other.faults.containsAll(faults);

  @override
  int get hashCode => Object.hash(tailAt, jumperAt, bodyClear, plate, Object.hashAllUnordered(faults));
}

/// The yard and the structure.
class M4DpSurveyWorldPainter extends CustomPainter {
  const M4DpSurveyWorldPainter({required this.geo, required this.look});

  final M4DpSurveyGeo geo;
  final M4DpSurveyLook look;

  static final _wire = Paint()
    ..color = const Color(0xFF2B2F35)
    ..strokeWidth = 1.6
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  static final _jumper = Paint()
    ..color = const Color(0xFF3A3530)
    ..strokeWidth = 2.2
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    _yard(c, size);
    _pole(c, M4DpSurveyGeo.poleL);
    _pole(c, M4DpSurveyGeo.poleR);
    _plates(c);
    _htArm(c);
    _upperJumpers(c);
    _doArm(c);
    _platform(c);
    _lowerJumpers(c);
    _transformer(c);
    _ltCables(c);
    _ltArm(c);
    // The earth wire down the right pole (static detail).
    c.drawLine(
      Offset(M4DpSurveyGeo.poleR + 9, g.platY + 4),
      Offset(M4DpSurveyGeo.poleR + 10, g.groundY + 2),
      Paint()
        ..color = const Color(0xFF6E5A3A)
        ..strokeWidth = 1.4,
    );
  }

  void _yard(Canvas c, Size size) {
    final g = geo;
    final sky = Rect.fromLTWH(0, 0, 360, g.groundY);
    c.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF79AEDC), Color(0xFFC3DEEF), Color(0xFFEAF1E6)],
        ).createShader(sky),
    );
    final cloud = Paint()..color = const Color(0xBBFFFFFF);
    for (final (x, y, r) in [
      (40.0, g.armY - 90, 16.0),
      (62.0, g.armY - 84, 22.0),
      (86.0, g.armY - 92, 15.0),
      (300.0, g.armY - 60, 14.0),
      (320.0, g.armY - 54, 20.0),
    ]) {
      c.drawCircle(Offset(x, y), r, cloud);
    }
    // Far village: trees and a roof line.
    final far = Path()..moveTo(0, g.groundY - 34);
    for (var x = 0.0; x <= 360; x += 30) {
      far.quadraticBezierTo(x + 15, g.groundY - 58 - (x % 90 == 0 ? 12 : 0), x + 30, g.groundY - 34);
    }
    far
      ..lineTo(360, g.groundY)
      ..lineTo(0, g.groundY)
      ..close();
    c.drawPath(far, Paint()..color = const Color(0xFF86A87E));
    c.drawRect(Rect.fromLTWH(292, g.groundY - 46, 40, 20), Paint()..color = const Color(0xFFB98B5E));
    c.drawPath(
      Path()
        ..moveTo(286, g.groundY - 46)
        ..lineTo(312, g.groundY - 62)
        ..lineTo(338, g.groundY - 46)
        ..close(),
      Paint()..color = const Color(0xFF8E5B3C),
    );
    // Ground and a dirt path.
    final ground = Rect.fromLTWH(0, g.groundY, 360, size.height - g.groundY);
    c.drawRect(
      ground,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF93A060), Color(0xFF707D47)],
        ).createShader(ground),
    );
    c.drawRect(Rect.fromLTWH(0, g.groundY + 64, 360, 46), Paint()..color = const Color(0xFFB59A6E));
    final peb = Paint()..color = const Color(0x55302A1A);
    final rnd = math.Random(7);
    for (var i = 0; i < 24; i++) {
      c.drawCircle(Offset(rnd.nextDouble() * 360, g.groundY + 6 + rnd.nextDouble() * 54), 1.2 + rnd.nextDouble() * 1.3, peb);
    }
    // The DP's fenced plinth.
    c.drawRect(
      Rect.fromLTRB(M4DpSurveyGeo.poleL - 22, g.groundY - 4, M4DpSurveyGeo.poleR + 22, g.groundY + 8),
      Paint()..color = const Color(0xFFA9A49A),
    );
  }

  void _pole(Canvas c, double x) {
    final g = geo;
    final p = Path()
      ..moveTo(x - 6, g.armY - 30)
      ..lineTo(x + 6, g.armY - 30)
      ..lineTo(x + 10, g.groundY + 2)
      ..lineTo(x - 10, g.groundY + 2)
      ..close();
    c.drawPath(
      p,
      Paint()..shader = const LinearGradient(colors: [Color(0xFFBDB8AD), Color(0xFF8C887E)]).createShader(Rect.fromLTWH(x - 10, g.armY, 20, g.span)),
    );
  }

  void _plates(Canvas c) {
    final g = geo;
    // Danger plate (red border) and the structure's number plate.
    final danger = Rect.fromLTWH(M4DpSurveyGeo.poleL - 9, g.y(0.76), 18, 20);
    c.drawRect(danger, Paint()..color = const Color(0xFFF4F4F4));
    c.drawRect(
      danger,
      Paint()
        ..color = const Color(0xFFC0392B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    c.drawPath(
      Path()
        ..moveTo(danger.center.dx + 2, danger.top + 3)
        ..lineTo(danger.center.dx - 3, danger.center.dy + 1)
        ..lineTo(danger.center.dx + 1, danger.center.dy + 1)
        ..lineTo(danger.center.dx - 2, danger.bottom - 3),
      Paint()
        ..color = const Color(0xFFC0392B)
        ..strokeWidth = 1.3
        ..style = PaintingStyle.stroke,
    );
    final plate = Rect.fromLTWH(M4DpSurveyGeo.poleR - 15, g.y(0.78), 30, 13);
    c.drawRRect(RRect.fromRectAndRadius(plate, const Radius.circular(2)), Paint()..color = const Color(0xFFF6E7A1));
    final tp = TextPainter(
      text: TextSpan(
        text: 'DP ${look.plate}',
        style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFF2B2416)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, plate.center - Offset(tp.width / 2, tp.height / 2));
  }

  void _arm(Canvas c, double left, double right, double y, {double tilt = 0}) {
    c.save();
    c.translate((left + right) / 2, y);
    c.rotate(tilt);
    final w = right - left;
    c.drawRect(Rect.fromLTWH(-w / 2, -4.5, w, 9), Paint()..color = const Color(0xFF4F555C));
    c.drawRect(Rect.fromLTWH(-w / 2, -4.5, w, 3), Paint()..color = const Color(0xFF7B828C));
    c.restore();
  }

  void _pinInsulator(Canvas c, Offset base, double h) {
    final p = Paint()..color = const Color(0xFF8A4B2A);
    c.drawRect(Rect.fromLTWH(base.dx - 2.4, base.dy - h, 4.8, h), p);
    for (var k = 0; k < 3; k++) {
      c.drawOval(Rect.fromCenter(center: Offset(base.dx, base.dy - 3 - k * h / 3.4), width: 15 - k * 2, height: 5), p);
    }
  }

  void _htArm(Canvas c) {
    final g = geo;
    _arm(c, M4DpSurveyGeo.armLeft, M4DpSurveyGeo.armRight, g.armY);
    for (final (i, x) in M4DpSurveyGeo.phaseX.indexed) {
      final top = Offset(x, g.armY - 20);
      _pinInsulator(c, Offset(x, g.armY - 4), 16);
      // The line conductor through the insulator's top groove, off both ways.
      c.drawPath(
        Path()
          ..moveTo(-10, g.armY - 40 - i * 4)
          ..quadraticBezierTo(x * 0.5, g.armY - 24 - i * 2, top.dx, top.dy)
          ..quadraticBezierTo(x + (370 - x) * 0.5, g.armY - 22 - i * 2, 370, g.armY - 46 + i * 4),
        _wire,
      );
      // The binding: a neat few turns, or one with a long tail.
      final bind = Paint()
        ..color = const Color(0xFFB9BEC4)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke;
      for (var k = -1; k <= 1; k++) {
        c.drawLine(top + Offset(k * 2.6 - 1.5, -2.5), top + Offset(k * 2.6 + 1.5, 2.5), bind);
      }
      if (look.has(M4DpSurveyFault.tail) && look.tailAt == i) {
        final tail = Path()
          ..moveTo(top.dx + 3, top.dy - 1)
          ..cubicTo(top.dx + 14, top.dy - 16, top.dx + 4, top.dy - 22, top.dx + 18, top.dy - 30)
          ..cubicTo(top.dx + 26, top.dy - 34, top.dx + 24, top.dy - 24, top.dx + 30, top.dy - 28);
        c.drawPath(
          tail,
          Paint()
            ..color = const Color(0xFFD5DADF)
            ..strokeWidth = 1.8
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  void _upperJumpers(Canvas c) {
    final g = geo;
    final tilt = look.has(M4DpSurveyFault.tilt);
    for (final (i, x) in M4DpSurveyGeo.phaseX.indexed) {
      final a = Offset(x - 4, g.armY - 19);
      final b = Offset(x + 6, g.doYAt(x + 6, tilt: tilt) + 9);
      final p = Path()..moveTo(a.dx, a.dy);
      if (look.has(M4DpSurveyFault.jumper) && look.jumperAt == i) {
        // Tangled: kinks, a loop, a twist.
        final h = b.dy - a.dy;
        p
          ..lineTo(a.dx - 14, a.dy + h * 0.16)
          ..lineTo(a.dx + 6, a.dy + h * 0.28)
          ..cubicTo(a.dx + 24, a.dy + h * 0.30, a.dx + 22, a.dy + h * 0.58, a.dx + 8, a.dy + h * 0.50)
          ..cubicTo(a.dx - 4, a.dy + h * 0.44, a.dx + 2, a.dy + h * 0.30, a.dx + 14, a.dy + h * 0.40)
          ..lineTo(a.dx - 16, a.dy + h * 0.66)
          ..lineTo(a.dx + 2, a.dy + h * 0.80)
          ..lineTo(b.dx, b.dy);
      } else {
        // A smooth 'C'.
        p.cubicTo(a.dx - 22, a.dy + 14, b.dx - 26, b.dy - 12, b.dx, b.dy);
      }
      c.drawPath(p, _jumper);
    }
  }

  /// The DO fuse arm with three DO fuses (body, contacts, barrel closed).
  void _doArm(Canvas c) {
    final g = geo;
    final tilt = look.has(M4DpSurveyFault.tilt);
    _arm(c, M4DpSurveyGeo.armLeft + 6, M4DpSurveyGeo.armRight - 6, g.doY, tilt: tilt ? M4DpSurveyGeo.tiltRad : 0);
    final body = Paint()..color = const Color(0xFF8A4B2A);
    final metal = Paint()..color = const Color(0xFFB8BEC6);
    final barrel = Paint()
      ..color = const Color(0xFF3A3F45)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    for (final x in M4DpSurveyGeo.phaseX) {
      final y0 = g.doYAt(x, tilt: tilt);
      c.save();
      c.translate(x, y0);
      if (tilt) c.rotate(M4DpSurveyGeo.tiltRad);
      final d = g.doDrop;
      c.drawRect(Rect.fromLTWH(-2.5, 4, 5, 6), metal);
      for (var k = 0; k < 4; k++) {
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(-6, 14 + k * (d - 18) / 3), width: 12, height: 5), const Radius.circular(2.5)), body);
      }
      c.drawRect(Rect.fromLTWH(-8.5, 12, 5, d - 12), body);
      c.drawRect(Rect.fromLTWH(0, 7, 12, 4), metal);
      c.drawRect(Rect.fromLTWH(2, d - 2, 12, 4), metal);
      c.drawLine(const Offset(5, 12), Offset(9, d - 3), barrel);
      c.restore();
    }
  }

  void _platform(Canvas c) {
    final g = geo;
    c.drawRect(Rect.fromLTRB(M4DpSurveyGeo.poleL - 8, g.platY, M4DpSurveyGeo.poleR + 8, g.platY + 9), Paint()..color = const Color(0xFF555B62));
    c.drawRect(Rect.fromLTRB(M4DpSurveyGeo.poleL - 8, g.platY, M4DpSurveyGeo.poleR + 8, g.platY + 3), Paint()..color = const Color(0xFF7B828C));
  }

  void _lowerJumpers(Canvas c) {
    final g = geo;
    final tilt = look.has(M4DpSurveyFault.tilt);
    final clear = look.has(M4DpSurveyFault.clearance);
    for (final (i, x) in M4DpSurveyGeo.phaseX.indexed) {
      final ax = x + 8;
      final a = Offset(ax, g.doYAt(ax, tilt: tilt) + g.doDrop + 1);
      final b = Offset(M4DpSurveyGeo.bushX[i], g.bushTopY);
      final mid = (a + b) / 2;
      var bend = Offset(i == 1 ? 0 : (i == 0 ? -8 : 8), 0);
      if (clear && !look.bodyClear && i < 2) {
        // Phase to phase: R and Y bow towards each other, almost touching.
        bend = Offset(i == 0 ? 40 : -30, 4);
      }
      if (clear && look.bodyClear && i == 2) {
        // Phase to body: B bows out onto the pole.
        bend = Offset(M4DpSurveyGeo.poleR - 7 - mid.dx, 0) * 2;
      }
      c.drawPath(
        Path()
          ..moveTo(a.dx, a.dy)
          ..quadraticBezierTo(mid.dx + bend.dx, mid.dy + bend.dy, b.dx, b.dy),
        _jumper,
      );
    }
  }

  void _transformer(Canvas c) {
    final g = geo;
    final body = Rect.fromLTRB(160, g.platY - g.tankH, 240, g.platY);
    // Radiator fins at the sides.
    final fin = Paint()..color = const Color(0xFF6F8679);
    for (var k = 0; k < 4; k++) {
      c.drawRect(Rect.fromLTWH(body.left - 9 + k * 2, body.top + 8, 1.4, body.height - 14), fin);
      c.drawRect(Rect.fromLTWH(body.right + 2 + k * 2, body.top + 8, 1.4, body.height - 14), fin);
    }
    c.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(3)),
      Paint()..shader = const LinearGradient(colors: [Color(0xFF8FA597), Color(0xFF6C8374)]).createShader(body),
    );
    c.drawRect(Rect.fromLTWH(body.left - 2, body.top - 3, body.width + 4, 5), Paint()..color = const Color(0xFF5E7466));
    // HT bushings on top.
    final porcelain = Paint()..color = const Color(0xFF8A4B2A);
    for (final x in M4DpSurveyGeo.bushX) {
      c.drawRect(Rect.fromLTWH(x - 2.5, g.bushTopY, 5, body.top - g.bushTopY), porcelain);
      for (var k = 0; k < 2; k++) {
        c.drawOval(Rect.fromCenter(center: Offset(x, g.bushTopY + 4 + k * 5), width: 10, height: 4), porcelain);
      }
    }
    // LT bushings (small, white) on the front, low.
    final lt = Paint()..color = const Color(0xFFE9E4D8);
    for (var k = 0; k < 4; k++) {
      c.drawRect(Rect.fromLTWH(180 + k * 13 - 2, g.platY - 12, 4, 7), lt);
    }
    // Rating plate (what a worker reads).
    final plate = Rect.fromCenter(center: Offset(body.center.dx, body.top + body.height * 0.38), width: 26, height: 12);
    c.drawRect(plate, Paint()..color = const Color(0xFFE6E2D6));
    final tp = TextPainter(
      text: const TextSpan(
        text: 'DTR',
        style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w900, color: Color(0xFF2B2416)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, plate.center - Offset(tp.width / 2, tp.height / 2));
  }

  /// The LT cables from the LT bushings down to the LT box, and on from the
  /// box to the left pole and up to the LT arm.
  void _ltCables(Canvas c) {
    final g = geo;
    final box = g.ltBox;
    c.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(3)), Paint()..color = const Color(0xFF8E959D));
    c.drawRect(Rect.fromLTWH(box.left + 4, box.top + 4, box.width - 8, box.height - 8), Paint()..color = const Color(0xFFA4ABB3));
    c.drawCircle(Offset(box.right - 8, box.center.dy), 1.8, Paint()..color = const Color(0xFF3A3F45));
    final cable = Paint()
      ..color = const Color(0xFF1C1D20)
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final loose = look.has(M4DpSurveyFault.ltCables);
    for (var k = 0; k < 4; k++) {
      final a = Offset(180.0 + k * 13, g.platY - 5);
      final b = Offset(box.left + 10 + k * 12, box.top);
      final p = Path()..moveTo(a.dx, a.dy);
      if (loose) {
        // Hanging in loose loops, every which way.
        final side = k.isEven ? -1.0 : 1.0;
        final wide = 28.0 + k * 9;
        p.cubicTo(a.dx + side * wide, a.dy + (b.dy - a.dy) * 0.55, b.dx - side * wide * 0.7, b.dy + 14, b.dx, b.dy);
      } else {
        // Bunched: side by side, straight down.
        final x = 196.0 + k * 3;
        p
          ..quadraticBezierTo(a.dx, a.dy + 10, x, a.dy + 18)
          ..lineTo(x, b.dy - 12)
          ..quadraticBezierTo(x, b.dy - 4, b.dx, b.dy);
      }
      c.drawPath(p, cable);
    }
    if (!loose) {
      // Cable ties on the bunch.
      final tie = Paint()
        ..color = const Color(0xFFE7E2D2)
        ..strokeWidth = 2.4;
      for (final f in [0.3, 0.7]) {
        final yy = g.platY + 13 + (box.top - g.platY - 25) * f;
        c.drawLine(Offset(193, yy), Offset(210, yy), tie);
      }
    }
    // The outgoing cable: box → left pole → up to the LT arm (tidy, clamped).
    final out = Path()
      ..moveTo(box.left, box.center.dy)
      ..lineTo(M4DpSurveyGeo.poleL + 9, box.center.dy)
      ..lineTo(M4DpSurveyGeo.poleL + 9, g.ltArmY + 8);
    c.drawPath(out, cable..strokeWidth = 3.2);
    final clamp = Paint()..color = const Color(0xFF9AA1A9);
    for (final f in [0.25, 0.6]) {
      c.drawRect(Rect.fromCenter(center: Offset(M4DpSurveyGeo.poleL + 9, g.ltArmY + 8 + (box.center.dy - g.ltArmY - 8) * f), width: 9, height: 3), clamp);
    }
  }

  /// The LT cross-arm on the left pole, four LT insulators, the wires going
  /// off to the left (apart, or two of them touching).
  void _ltArm(Canvas c) {
    final g = geo;
    final y = g.ltArmY;
    c.drawRect(Rect.fromLTRB(16, y - 3.5, M4DpSurveyGeo.poleL + 6, y + 3.5), Paint()..color = const Color(0xFF4F555C));
    final ins = Paint()..color = const Color(0xFFE8E2D4);
    final w = Paint()
      ..color = const Color(0xFF26282C)
      ..strokeWidth = 1.7
      ..style = PaintingStyle.stroke;
    final touch = look.has(M4DpSurveyFault.touch);
    // The wires run off to the left, a little up, side by side.
    const dir = Offset(-1, -0.22);
    final meet = Offset(30, y - 14);
    for (final (k, x) in M4DpSurveyGeo.ltX.indexed) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 3, y - 12, 6, 9), const Radius.circular(2)), ins);
      final top = Offset(x, y - 12);
      final far = top + dir * 150;
      final p = Path()..moveTo(top.dx, top.dy);
      if (touch && (k == 1 || k == 2)) {
        // Wires 2 and 3 sag into each other and rub.
        final mid = top + dir * 38;
        p
          ..quadraticBezierTo((top.dx + meet.dx) / 2, (top.dy + mid.dy) / 2 + 6, meet.dx, meet.dy)
          ..quadraticBezierTo((meet.dx + far.dx) / 2, (meet.dy + far.dy) / 2 + 2, far.dx, far.dy);
      } else {
        final mid = top + dir * 75 + const Offset(0, 5);
        p.quadraticBezierTo(mid.dx, mid.dy, far.dx, far.dy);
      }
      c.drawPath(p, w);
    }
    if (touch) {
      // The rubbed spot: the insulation worn pale.
      c.drawCircle(meet, 3.4, Paint()..color = const Color(0x99D9C9A0));
    }
    // The cable rises to the arm and fans to the four insulators.
    final fan = Paint()
      ..color = const Color(0xFF1C1D20)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    for (final x in M4DpSurveyGeo.ltX) {
      c.drawPath(
        Path()
          ..moveTo(M4DpSurveyGeo.poleL + 9, y + 8)
          ..quadraticBezierTo((x + M4DpSurveyGeo.poleL) / 2, y + 16, x, y + 3.5),
        fan,
      );
    }
  }

  @override
  bool shouldRepaint(M4DpSurveyWorldPainter old) => old.geo != geo || old.look != look;
}

/// The player's marks on the structure: a red ring on each part listed and,
/// after the list, an orange dashed ring on what was missed.
class M4DpSurveyMarksPainter extends CustomPainter {
  const M4DpSurveyMarksPainter({required this.geo, required this.marked, required this.missed});

  final M4DpSurveyGeo geo;
  final List<M4DpSurveyFault> marked;
  final Set<M4DpSurveyFault> missed;

  @override
  void paint(Canvas c, Size size) {
    for (final (i, f) in marked.indexed) {
      final r = geo.zoneOf(f).deflate(2);
      final miss = missed.contains(f);
      final ring = Paint()
        ..color = miss ? const Color(0xFFFF9F1A) : const Color(0xFFE53935)
        ..strokeWidth = 2.6
        ..style = PaintingStyle.stroke;
      final rr = RRect.fromRectAndRadius(r, const Radius.circular(14));
      if (miss) {
        // Dashed: the guide showed it.
        final path = Path()..addRRect(rr);
        for (final m in path.computeMetrics()) {
          for (var d = 0.0; d < m.length; d += 12) {
            c.drawPath(m.extractPath(d, d + 7), ring);
          }
        }
      } else {
        c.drawRRect(rr, ring);
      }
      // The number on the list.
      final badge = Offset(r.left + 10, r.top + 10);
      c.drawCircle(badge, 9, Paint()..color = miss ? const Color(0xFFFF9F1A) : const Color(0xFFE53935));
      final tp = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(c, badge - Offset(tp.width / 2, tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(M4DpSurveyMarksPainter old) =>
      old.geo != geo || old.marked.length != marked.length || old.missed.length != missed.length || !_eq(old.marked, marked);

  static bool _eq(List<M4DpSurveyFault> a, List<M4DpSurveyFault> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// A flash at a live part ([v] 0 → 1): the arc's white-blue core and sparks,
/// with a white-out at the start.
class M4DpSurveyArcPainter extends CustomPainter {
  const M4DpSurveyArcPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final fade = (1 - v * 0.6).clamp(0.0, 1.0);
    final r = 30 + 60 * v;
    c.drawCircle(
      at,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [Color.fromRGBO(255, 255, 240, 0.95 * fade), Color.fromRGBO(140, 190, 255, 0.5 * fade), const Color(0x0088BBFF)],
        ).createShader(Rect.fromCircle(center: at, radius: r)),
    );
    final spark = Paint()
      ..color = Color.fromRGBO(255, 210, 90, fade)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 14; i++) {
      final a = i / 14 * math.pi * 2 + 0.3;
      final d0 = 18 + 70 * v;
      final drop = Offset(0, 60 * v * v);
      c.drawLine(at + Offset(math.cos(a) * d0, math.sin(a) * d0) + drop, at + Offset(math.cos(a) * (d0 + 18), math.sin(a) * (d0 + 18)) + drop, spark);
    }
    final white = (1 - v * 3).clamp(0.0, 1.0);
    if (white > 0) c.drawRect(Offset.zero & size, Paint()..color = Color.fromRGBO(255, 255, 255, 0.8 * white));
  }

  @override
  bool shouldRepaint(M4DpSurveyArcPainter old) => old.v != v || old.at != at;
}
