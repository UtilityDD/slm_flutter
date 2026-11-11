import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The place for lesson 3.4 কাজ 2 "হর্ন গ্যাপ ঠিক করো" (m3_horngap_set.dart):
// a village transformer pole. On its cross-arm stand three horn gap fuse
// sets (R Y B): two post insulators each, a metal horn on each, the fuse wire
// tied across the small gap low between the horns (lesson point 3: the gap
// widens upward, so a rising arc stretches and goes out by itself). The line
// comes in to one horn's terminal; the other terminal goes down to the
// transformer below.
//
// Two views: the ground (the trainee on the lane, the whole pole, the
// earthing set once it is on, the village whose windows light when the line
// is on) and the top (up the pole, beside the cross-arm: the three sets big).
// Design space: 360 wide; static painters only (they repaint when the play
// changes, never on a clock).

/// A part of one horn gap set the trainee can tap.
enum M3HorngapSetPart { wire, horns, terminal }

/// How the fuse wire across a set looks.
enum M3HorngapSetWire { ok, blown, thick, slack, gone }

/// What one set shows (its faults until they are fixed).
@immutable
class M3HorngapSetLook {
  const M3HorngapSetLook({this.wire = M3HorngapSetWire.ok, this.slack = 0, this.bent = false, this.carbon = false, this.carbonRight = false});
  final M3HorngapSetWire wire;

  /// [M3HorngapSetWire.slack]: how far it still sags (3 → 1).
  final int slack;
  final bool bent;
  final bool carbon;
  final bool carbonRight;

  @override
  bool operator ==(Object other) =>
      other is M3HorngapSetLook && other.wire == wire && other.slack == slack && other.bent == bent && other.carbon == carbon && other.carbonRight == carbonRight;

  @override
  int get hashCode => Object.hash(wire, slack, bent, carbon, carbonRight);
}

/// Where things stand (design px, 360 wide).
@immutable
class M3HorngapSetGeo {
  const M3HorngapSetGeo._(this.height, this.groundY, this.armY);

  factory M3HorngapSetGeo.forScene(double h, double inset) {
    final ground = (h - 300 - inset).clamp(360.0, 700.0);
    final arm = (h * 0.52).clamp(300.0, 520.0);
    return M3HorngapSetGeo._(h, ground, arm);
  }

  final double height;

  /// Ground view: where the lane starts.
  final double groundY;

  /// Top view: the cross-arm's top edge.
  final double armY;

  // --- the top view --------------------------------------------------------
  static const topPoleX = 34.0;
  static const phaseX = [128.0, 218.0, 308.0];

  /// The terminals' height (the base of the horns).
  double get termY => armY - 52;

  /// The fuse wire's height (low between the horns, where the gap is small).
  double get wireY => termY - 28;

  /// Where a tap reaches [part] of set [phase] (≥ 36 design px tall, 88 wide).
  Rect partHit(int phase, M3HorngapSetPart part) {
    final x = phaseX[phase];
    final t = termY;
    return switch (part) {
      M3HorngapSetPart.horns => Rect.fromLTRB(x - 44, t - 132, x + 44, t - 46),
      M3HorngapSetPart.wire => Rect.fromLTRB(x - 44, t - 46, x + 44, t - 10),
      M3HorngapSetPart.terminal => Rect.fromLTRB(x - 44, t - 10, x + 44, t + 30),
    };
  }

  /// The ring's centre on [part] of [phase].
  Offset partAt(int phase, M3HorngapSetPart part) {
    final x = phaseX[phase];
    return switch (part) {
      M3HorngapSetPart.horns => Offset(x, termY - 96),
      M3HorngapSetPart.wire => Offset(x, wireY),
      M3HorngapSetPart.terminal => Offset(x, termY + 4),
    };
  }

  /// The trainee up the pole (top view), beside the cross-arm.
  Rect get topTrainee => Rect.fromLTWH(-8, armY - 120, 92, 184);

  /// The rating plate on the pole (top view).
  Rect get plate => Rect.fromLTWH(8, armY + 70, 62, 34);

  // --- the ground view -----------------------------------------------------
  static const groundPoleX = 250.0;
  static const groundPhaseX = [196.0, 250.0, 304.0];
  double get poleTop => math.max(70.0, groundY - 470);
  double get groundArmY => poleTop + 30;

  /// The small sets' terminals (ground view).
  double get groundTermY => groundArmY - 14;

  /// The fuse sets on the pole (ground view): a tap here = climb to work.
  Rect get groundFuseHit => Rect.fromLTRB(168, groundArmY - 64, 340, groundArmY + 24);

  /// The arc's foot on set [phase] (ground view).
  Offset groundArcAt(int phase) => Offset(groundPhaseX[phase], groundTermY - 8);

  /// The trainee on the lane (ground view).
  Rect get groundTrainee => Rect.fromLTWH(18, groundY - 208, 104, 208);

  @override
  bool operator ==(Object other) => other is M3HorngapSetGeo && other.height == height && other.groundY == groundY && other.armY == armY;

  @override
  int get hashCode => Object.hash(height, groundY, armY);
}

// ============================================================================
// Shared drawing
// ============================================================================

void _sky(Canvas c, Size size, double to) {
  c.drawRect(
      Rect.fromLTWH(0, 0, size.width, to),
      Paint()
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3B6E9E), Color(0xFF8DB6D6), Color(0xFFEBDDB4)])
            .createShader(Rect.fromLTWH(0, 0, size.width, to)));
  final cloud = Paint()..color = const Color(0x55FFFFFF);
  for (final (x, y, r) in [(58.0, 96.0, 20.0), (86.0, 88.0, 27.0), (118.0, 98.0, 19.0), (236.0, 150.0, 17.0), (262.0, 142.0, 23.0), (290.0, 151.0, 16.0)]) {
    c.drawCircle(Offset(x, y), r, cloud);
  }
}

/// One horn gap set: two post insulators, a horn on each, the terminals and
/// the fuse wire. [s] scales it (1 = top view).
void _hornSet(Canvas c, Offset base, double s, M3HorngapSetLook look, {required double armTop}) {
  final x = base.dx;
  final t = base.dy;
  // Post insulators (porcelain, three sheds) from the arm to the cap.
  final porcelain = Paint()..shader = const LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFFC9C6BC)]).createShader(Rect.fromLTRB(x - 20 * s, t, x + 20 * s, armTop));
  for (final dx in [-11.0, 11.0]) {
    final cx = x + dx * s;
    c.drawRect(Rect.fromLTRB(cx - 4 * s, t + 6 * s, cx + 4 * s, armTop), porcelain);
    final shedGap = (armTop - t - 10 * s) / 3;
    for (var i = 0; i < 3; i++) {
      final y = t + 10 * s + shedGap * (i + 0.5);
      c.drawOval(Rect.fromCenter(center: Offset(cx, y), width: 16 * s, height: 5 * s), porcelain);
    }
    // The metal cap and the terminal clamp.
    c.drawRect(Rect.fromLTRB(cx - 6 * s, t - 2 * s, cx + 6 * s, t + 7 * s), Paint()..color = const Color(0xFF7D848C));
  }
  // Carbon on a terminal.
  if (look.carbon) {
    final cx = x + (look.carbonRight ? 11 : -11) * s;
    final soot = Paint()..color = const Color(0xE0141414);
    c.drawCircle(Offset(cx, t + 1 * s), 6.5 * s, soot);
    c.drawCircle(Offset(cx + 4 * s, t - 3 * s), 3.5 * s, soot);
    c.drawCircle(Offset(cx - 3 * s, t + 5 * s), 3 * s, soot);
  }
  // The horns: straight up a little, then curving out (the gap widens up).
  final horn = Paint()
    ..color = const Color(0xFF9AA3AC)
    ..strokeWidth = 3.4 * s
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final hornDark = Paint()
    ..color = const Color(0xFF4E565E)
    ..strokeWidth = 1.2 * s
    ..style = PaintingStyle.stroke;
  for (final side in [-1.0, 1.0]) {
    final bx = x + side * 11 * s;
    final bentIn = look.bent && side > 0;
    final top = bentIn ? Offset(x - 2 * s, t - 116 * s) : Offset(x + side * 40 * s, t - 120 * s);
    final p = Path()
      ..moveTo(bx, t)
      ..lineTo(bx, t - 40 * s)
      ..quadraticBezierTo(bentIn ? bx + 2 * s : bx, t - 84 * s, top.dx, top.dy);
    c.drawPath(p, horn);
    c.drawPath(p.shift(Offset(1.4 * s, 0)), hornDark);
  }
  // The fuse wire low across the gap.
  final w = look.wire;
  final wy = t - 28 * s;
  final l = Offset(x - 11 * s, wy);
  final r = Offset(x + 11 * s, wy);
  switch (w) {
    case M3HorngapSetWire.ok:
      c.drawLine(l, r, Paint()
        ..color = const Color(0xFFD9DDE0)
        ..strokeWidth = 1.6 * s);
    case M3HorngapSetWire.thick:
      c.drawLine(l, r, Paint()
        ..color = const Color(0xFFB86A2C)
        ..strokeWidth = 4.2 * s
        ..strokeCap = StrokeCap.round);
    case M3HorngapSetWire.slack:
      c.drawPath(
          Path()
            ..moveTo(l.dx, l.dy)
            ..quadraticBezierTo(x, wy + look.slack * 7 * s, r.dx, r.dy),
          Paint()
            ..color = const Color(0xFFD9DDE0)
            ..strokeWidth = 1.6 * s
            ..style = PaintingStyle.stroke);
    case M3HorngapSetWire.blown:
      // Melted: two short stubs with beads; the horns scorched above.
      final stub = Paint()
        ..color = const Color(0xFFB8BEC4)
        ..strokeWidth = 1.6 * s;
      c.drawLine(l, l + Offset(4 * s, 3 * s), stub);
      c.drawLine(r, r + Offset(-4 * s, 4 * s), stub);
      final bead = Paint()..color = const Color(0xFF8E959C);
      c.drawCircle(l + Offset(4.5 * s, 3.5 * s), 1.8 * s, bead);
      c.drawCircle(r + Offset(-4.5 * s, 4.5 * s), 1.8 * s, bead);
      final scorch = Paint()..color = const Color(0x66231A12);
      for (final side in [-1.0, 1.0]) {
        c.drawOval(Rect.fromCenter(center: Offset(x + side * 14 * s, t - 62 * s), width: 9 * s, height: 30 * s), scorch);
      }
    case M3HorngapSetWire.gone:
      break;
  }
}

// ============================================================================
// The ground view
// ============================================================================

/// The lane, the village, the pole with its transformer and the three sets;
/// the earthing set when [earthed]; windows lit when [lit].
class M3HorngapSetGroundPainter extends CustomPainter {
  const M3HorngapSetGroundPainter({required this.geo, required this.looks, required this.earthed, required this.lit});

  final M3HorngapSetGeo geo;
  final List<M3HorngapSetLook> looks;
  final bool earthed;
  final bool lit;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final g = geo.groundY;
    final hz = g - 120;
    _sky(c, size, hz + 4);
    // Far trees.
    final far = Path()..moveTo(0, hz);
    for (var x = 0.0; x <= w; x += 18) {
      far.lineTo(x, hz - 18 - 10 * math.sin(x * 0.07) - 6 * math.cos(x * 0.19));
    }
    far
      ..lineTo(w, hz + 2)
      ..lineTo(0, hz + 2)
      ..close();
    c.drawPath(far, Paint()..color = const Color(0xFF4F7A55));
    // Fields.
    c.drawRect(Rect.fromLTWH(0, hz, w, g - hz),
        Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF85A65E), Color(0xFF5E7F43)]).createShader(Rect.fromLTWH(0, hz, w, g - hz)));
    // The village houses (their windows light when the line is on).
    final roof = Paint()..color = const Color(0xFF8A4B36);
    final wall = Paint()..color = const Color(0xFFD9C7A3);
    final win = Paint()..color = lit ? const Color(0xFFFFD36B) : const Color(0xFF3F4650);
    for (final (x, y, s) in [(20.0, hz + 22, 1.0), (88.0, hz + 10, 0.8), (140.0, hz + 30, 0.9)]) {
      final r = Rect.fromLTWH(x, y, 44 * s, 26 * s);
      c.drawRect(r, wall);
      c.drawPath(
          Path()
            ..moveTo(x - 5 * s, y)
            ..lineTo(x + 22 * s, y - 18 * s)
            ..lineTo(x + 49 * s, y)
            ..close(),
          roof);
      c.drawRect(Rect.fromLTWH(x + 8 * s, y + 8 * s, 9 * s, 9 * s), win);
      c.drawRect(Rect.fromLTWH(x + 26 * s, y + 8 * s, 9 * s, 9 * s), win);
    }
    // The lane.
    c.drawRect(Rect.fromLTWH(0, g, w, size.height - g),
        Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFB59B74), Color(0xFF8C7556)]).createShader(Rect.fromLTWH(0, g, w, size.height - g)));
    final pebble = Paint()..color = const Color(0x33000000);
    final rnd = math.Random(5);
    for (var i = 0; i < 24; i++) {
      c.drawCircle(Offset(rnd.nextDouble() * w, g + 6 + rnd.nextDouble() * (size.height - g - 10)), 1.2 + rnd.nextDouble() * 1.6, pebble);
    }
    _pole(c);
  }

  void _pole(Canvas c) {
    final g = geo.groundY;
    const px = M3HorngapSetGeo.groundPoleX;
    final top = geo.poleTop;
    final arm = geo.groundArmY;
    // The incoming line from the left, to the sets' supply horns.
    final wire = Paint()
      ..color = const Color(0xFF2A2F36)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 3; i++) {
      final fx = M3HorngapSetGeo.groundPhaseX[i];
      c.drawPath(
          Path()
            ..moveTo(0, top + 6 + i * 8)
            ..quadraticBezierTo(fx * 0.5, top + 30 + i * 8, fx - 4, geo.groundTermY - 30),
          wire);
      c.drawLine(Offset(fx - 4, geo.groundTermY - 30), Offset(fx - 4, geo.groundTermY), wire);
    }
    // The pole.
    final pole = Path()
      ..moveTo(px - 7, top)
      ..lineTo(px + 7, top)
      ..lineTo(px + 11, g + 4)
      ..lineTo(px - 11, g + 4)
      ..close();
    c.drawPath(pole, Paint()..shader = const LinearGradient(colors: [Color(0xFFB9B9B2), Color(0xFF8D8D86)]).createShader(Rect.fromLTRB(px - 11, top, px + 11, g)));
    // Cross-arm.
    c.drawRect(Rect.fromLTRB(172, arm, 330, arm + 5), Paint()..color = const Color(0xFF4A4F57));
    // The transformer on the pole.
    final tank = Rect.fromLTRB(px - 40, arm + 110, px + 40, arm + 190);
    c.drawRRect(RRect.fromRectAndRadius(tank, const Radius.circular(4)),
        Paint()..shader = const LinearGradient(colors: [Color(0xFF8C9AA6), Color(0xFF5E6B76)]).createShader(tank));
    final fin = Paint()..color = const Color(0xFF4C5761);
    for (var i = 0; i < 6; i++) {
      c.drawRect(Rect.fromLTWH(tank.left + 6 + i * 12, tank.top + 10, 4, tank.height - 18), fin);
    }
    c.drawRect(Rect.fromLTRB(px - 46, arm + 190, px + 46, arm + 196), Paint()..color = const Color(0xFF3A3F46));
    // Fuse outputs down to the HT bushings.
    for (var i = 0; i < 3; i++) {
      final fx = M3HorngapSetGeo.groundPhaseX[i];
      final bx = px - 24 + i * 24;
      c.drawPath(
          Path()
            ..moveTo(fx + 4, geo.groundTermY)
            ..quadraticBezierTo(fx + 4, arm + 60, bx, tank.top - 10),
          wire);
      c.drawRect(Rect.fromLTWH(bx - 3, tank.top - 12, 6, 12), Paint()..color = const Color(0xFFE8E4DA));
    }
    // The three small sets.
    for (var i = 0; i < 3; i++) {
      _hornSet(c, Offset(M3HorngapSetGeo.groundPhaseX[i], geo.groundTermY), 0.3, looks[i], armTop: arm);
    }
    // The earthing set: clamps on the incoming line, the lead down to its rod.
    if (earthed) {
      final lead = Paint()
        ..color = const Color(0xFF2F8F4E)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      final clamp = Paint()..color = const Color(0xFFE0A526);
      final rodX = px + 34;
      for (var i = 0; i < 3; i++) {
        final at = Offset(M3HorngapSetGeo.groundPhaseX[i] - 4, geo.groundTermY - 26);
        c.drawRect(Rect.fromCenter(center: at, width: 7, height: 6), clamp);
        c.drawPath(
            Path()
              ..moveTo(at.dx, at.dy + 3)
              ..quadraticBezierTo(at.dx + 10, arm + 40, px + 14, arm + 80)
              ..lineTo(rodX, g + 2),
            lead);
      }
      c.drawRect(Rect.fromLTWH(rodX - 2, g - 2, 4, 14), Paint()..color = const Color(0xFF6A5A46));
    }
    c.drawOval(Rect.fromCenter(center: Offset(px, g + 4), width: 46, height: 8), Paint()..color = const Color(0x33000000));
  }

  @override
  bool shouldRepaint(M3HorngapSetGroundPainter old) => old.geo != geo || !listEquals(old.looks, looks) || old.earthed != earthed || old.lit != lit;
}

// ============================================================================
// The top view
// ============================================================================

/// Up the pole: the sky, the cross-arm, the three sets big, the incoming
/// line with the earthing clamps on, and the pole the trainee is strapped to.
class M3HorngapSetTopPainter extends CustomPainter {
  const M3HorngapSetTopPainter({required this.geo, required this.looks});

  final M3HorngapSetGeo geo;
  final List<M3HorngapSetLook> looks;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    final arm = geo.armY;
    _sky(c, size, h);
    // Far fields low in the view (we are high up).
    final fy = math.min(h - 40, arm + 210);
    c.drawRect(Rect.fromLTWH(0, fy, w, h - fy),
        Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF6F9350), Color(0xFF4F6E3A)]).createShader(Rect.fromLTWH(0, fy, w, h - fy)));
    final far = Path()..moveTo(0, fy);
    for (var x = 0.0; x <= w; x += 16) {
      far.lineTo(x, fy - 10 - 6 * math.sin(x * 0.09));
    }
    far
      ..lineTo(w, fy + 1)
      ..lineTo(0, fy + 1)
      ..close();
    c.drawPath(far, Paint()..color = const Color(0xFF4A7350));
    // The pole.
    const px = M3HorngapSetGeo.topPoleX;
    c.drawRect(Rect.fromLTRB(px - 14, 0, px + 14, h),
        Paint()..shader = const LinearGradient(colors: [Color(0xFFC2C2BA), Color(0xFF8D8D86)]).createShader(Rect.fromLTRB(px - 14, 0, px + 14, h)));
    // The cross-arm (channel iron).
    c.drawRect(Rect.fromLTRB(px - 16, arm, w - 6, arm + 14), Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF5A6068), Color(0xFF33383E)]).createShader(Rect.fromLTRB(0, arm, w, arm + 14)));
    final wire = Paint()
      ..color = const Color(0xFF23272D)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final lead = Paint()
      ..color = const Color(0xFF2F8F4E)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final clamp = Paint()..color = const Color(0xFFE0A526);
    for (var i = 0; i < 3; i++) {
      final x = M3HorngapSetGeo.phaseX[i];
      final inX = x - 11;
      // The incoming line drops onto the supply horn's terminal.
      c.drawPath(
          Path()
            ..moveTo(inX - 40, -4)
            ..quadraticBezierTo(inX - 6, geo.termY - 150, inX, geo.termY - 62)
            ..lineTo(inX - 6, geo.termY - 4),
          wire);
      // The earthing clamp on it (the line is earthed before work).
      final at = Offset(inX - 4, geo.termY - 140);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: at, width: 14, height: 12), const Radius.circular(2)), clamp);
      // Its lead runs up and back to the pole, clear of the sets.
      c.drawPath(
          Path()
            ..moveTo(at.dx - 7, at.dy)
            ..quadraticBezierTo(at.dx - 30, at.dy - 40 - i * 6, px + 14, geo.termY - 200 - i * 10),
          lead);
      // The outgoing lead down to the transformer.
      c.drawPath(
          Path()
            ..moveTo(x + 17, geo.termY + 2)
            ..quadraticBezierTo(x + 30, arm + 40, x + 26, h + 4),
          wire);
    }
    for (var i = 0; i < 3; i++) {
      _hornSet(c, Offset(M3HorngapSetGeo.phaseX[i], geo.termY), 1, looks[i], armTop: arm);
    }
    // Phase letters on the arm (as painted in the field).
    for (var i = 0; i < 3; i++) {
      final tp = TextPainter(
        text: TextSpan(text: const ['R', 'Y', 'B'][i], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFFF2F0E8))),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(c, Offset(M3HorngapSetGeo.phaseX[i] - tp.width / 2, arm + 1));
    }
  }

  @override
  bool shouldRepaint(M3HorngapSetTopPainter old) => old.geo != geo || !listEquals(old.looks, looks);
}

/// The close-up bubble (ground view, back on): one set big, as he sees it
/// from the lane. The arc (if it blows) is drawn over it at [zoomFoot].
class M3HorngapSetZoomPainter extends CustomPainter {
  const M3HorngapSetZoomPainter({required this.look});
  final M3HorngapSetLook look;

  /// The set's terminal height inside a bubble of [size].
  static Offset zoomBase(Size size) => Offset(size.width / 2, size.height * 0.80);
  static double zoomScale(Size size) => size.height / 165;

  /// The arc's foot inside a bubble of [size].
  static Offset zoomFoot(Size size) => zoomBase(size) - Offset(0, 28 * zoomScale(size));

  @override
  void paint(Canvas c, Size size) {
    c.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF6E9CC4), Color(0xFFB9D2E6)])
              .createShader(Offset.zero & size));
    final s = zoomScale(size);
    final base = zoomBase(size);
    c.drawRect(Rect.fromLTRB(0, base.dy + 40 * s, size.width, base.dy + 50 * s), Paint()..color = const Color(0xFF4A4F57));
    _hornSet(c, base, s, look, armTop: base.dy + 40 * s);
  }

  @override
  bool shouldRepaint(M3HorngapSetZoomPainter old) => old.look != look;
}

/// His pole strap (top view): from his waist round the pole.
class M3HorngapSetStrapPainter extends CustomPainter {
  const M3HorngapSetStrapPainter({required this.box});
  final Rect box;

  @override
  void paint(Canvas c, Size size) {
    final waist = Offset(box.left + box.width * 0.5, box.top + box.height * 0.52);
    const px = M3HorngapSetGeo.topPoleX;
    final strap = Paint()
      ..color = const Color(0xFFE8731C)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    c.drawPath(
        Path()
          ..moveTo(waist.dx - 14, waist.dy)
          ..quadraticBezierTo(px - 30, waist.dy - 16, px + 16, waist.dy - 10)
          ..quadraticBezierTo(px + 30, waist.dy - 4, waist.dx + 14, waist.dy + 2),
        strap);
    c.drawLine(Offset(waist.dx - 16, waist.dy + 1), Offset(waist.dx + 16, waist.dy + 3), Paint()
      ..color = const Color(0xFF6B3A12)
      ..strokeWidth = 5);
  }

  @override
  bool shouldRepaint(M3HorngapSetStrapPainter old) => old.box != box;
}

/// The fuse blowing (lesson point 3): a flash between the horns, then the
/// arc climbs up the widening gap, stretches thin and goes out. [v] 0 → 1.
class M3HorngapSetArcPainter extends CustomPainter {
  const M3HorngapSetArcPainter({required this.foot, required this.scale, required this.v});
  final Offset foot;
  final double scale;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final s = scale;
    final flash = (1 - v * 3).clamp(0.0, 1.0);
    if (flash > 0) {
      final r = (18 + 60 * (1 - flash)) * s;
      c.drawCircle(foot, r, Paint()..shader = RadialGradient(colors: [Color.fromRGBO(255, 250, 220, 0.95 * flash), const Color(0x00FFB040)]).createShader(Rect.fromCircle(center: foot, radius: r)));
    }
    // The arc rises; its ends ride up the horns as the gap widens.
    if (v < 0.85) {
      final rise = Curves.easeOut.transform((v / 0.85).clamp(0.0, 1.0));
      final y = foot.dy - rise * 82 * s;
      final half = (10 + rise * 26) * s;
      final a = (1 - rise * 0.9).clamp(0.0, 1.0);
      final rnd = math.Random((v * 40).floor());
      final p = Path()..moveTo(foot.dx - half, y);
      for (var i = 1; i < 6; i++) {
        p.lineTo(foot.dx - half + i * half * 2 / 6, y - (6 + rnd.nextDouble() * 10) * s * (1 - rise * 0.4));
      }
      p.lineTo(foot.dx + half, y);
      c.drawPath(
          p,
          Paint()
            ..color = Color.fromRGBO(190, 220, 255, 0.5 * a)
            ..strokeWidth = 7 * s
            ..style = PaintingStyle.stroke
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      c.drawPath(
          p,
          Paint()
            ..color = Color.fromRGBO(255, 255, 255, a)
            ..strokeWidth = 2.4 * s
            ..style = PaintingStyle.stroke);
    }
    // Sparks.
    final spark = Paint()
      ..color = Color.fromRGBO(255, 210, 90, (1 - v).clamp(0.0, 1.0))
      ..strokeWidth = 2 * s
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 10; i++) {
      final a = i / 10 * math.pi * 2 + 0.4;
      final d0 = (8 + 40 * v) * s;
      c.drawLine(foot + Offset(math.cos(a) * d0, math.sin(a) * d0), foot + Offset(math.cos(a) * (d0 + 9 * s), math.sin(a) * (d0 + 9 * s)), spark);
    }
  }

  @override
  bool shouldRepaint(M3HorngapSetArcPainter old) => old.v != v || old.foot != foot || old.scale != scale;
}

/// A hand on a live set: the flash at the sets, white-out at first.
class M3HorngapSetZapPainter extends CustomPainter {
  const M3HorngapSetZapPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final flick = v < 0.5 ? (0.65 + 0.35 * math.sin(v * 60).abs()) : (1 - (v - 0.5) * 1.2).clamp(0.4, 1.0);
    final r = 30 + 50 * Curves.easeOut.transform(v.clamp(0.0, 1.0));
    c.drawCircle(at, r, Paint()..shader = RadialGradient(colors: [Color.fromRGBO(220, 235, 255, 0.95 * flick), const Color(0x002F6FD0)]).createShader(Rect.fromCircle(center: at, radius: r)));
    final rnd = math.Random(7);
    final arc = Path()..moveTo(at.dx - 34, at.dy);
    for (var i = 1; i <= 7; i++) {
      arc.lineTo(at.dx - 34 + i * 10, at.dy + (rnd.nextDouble() - 0.5) * 20);
    }
    c.drawPath(
        arc,
        Paint()
          ..color = Color.fromRGBO(255, 255, 255, flick)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke);
    final white = (1 - v * 4).clamp(0.0, 1.0);
    if (white > 0) c.drawRect(Offset.zero & size, Paint()..color = Color.fromRGBO(255, 255, 255, 0.8 * white));
  }

  @override
  bool shouldRepaint(M3HorngapSetZapPainter old) => old.v != v || old.at != at;
}
