import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The drawn world of lesson 5.8 কাজ 2 "হাসপাতালের কাগজ"
// (m5_workshop_referral.dart): a village DP (double pole) transformer whose HT
// fuse keeps blowing. The team has already isolated it: the three DO barrels
// hang open with a red tag, an HT earth set runs from the HT leads to a spike,
// and their sectionalizing log is clipped to the right pole (the LT box's plate
// reads only "LT": the log alone says which ways are in, so an LT site with
// its blowing feeder still in looks the same from the road). The props wait
// clear of the corner guide: the HT tester on a hot stick leaning on the left
// pole, an oil sample jar on a crate at the far left, and by the workshop van
// (with its crane, at the right edge) the testing crew's IR card on a stand and
// the old record book on a stool.
//
// Every site looks alike from the road (no giveaway: the transformer and the
// LT sites are drawn the same; only the log, read by the player, tells them
// apart). The village behind changes with the site's seed.
//
// The close-ups ("lens") are drawn here too: the bushings (dusty until the
// cloth pass; a crack or a flashover track may show), the IR card's three rows
// (a needle near 0 or near ∞; no numbers), the oil jar (in shade until held to
// the sun; beads at the bottom only after the swirl; the smell only after the
// sniff), and the record book's ruled page (its entries are text widgets).
//
// Design: 360 wide × the scene's height; the ground follows the bottom of the
// screen (a tall phone gets more sky, never stretched). Code-drawn, gradients,
// no bitmaps.

/// The proof stations at a transformer site.
enum M5WrStation { bushing, ir, oil, record }

/// The three regions of the oil jar a finding can be pinned on.
enum M5WrOilPart { colour, water, smell }

/// Where things are on the scene (design px, 360 wide).
@immutable
class M5WrGeo {
  const M5WrGeo._(this.height, this.groundY, this.topY);

  factory M5WrGeo.forScene(double height, double inset) {
    final g = height - floorUp - inset * 0.5;
    return M5WrGeo._(height, g, math.max(150.0, g - 430));
  }

  final double height;

  /// The ground line at the poles' feet.
  final double groundY;

  /// The top of the poles.
  final double topY;

  /// The ground sits this far above the bottom (the button row / slip stand on it).
  static const double floorUp = 112;

  /// The two poles' axes.
  static const double lp = 112;
  static const double rp = 224;

  double get h => groundY - topY;
  double y(double f) => topY + f * h;

  /// The top cross-arm and its insulators (the 11 kV line).
  double get armY => y(0.05);
  static const List<double> phaseX = [130, 168, 206];

  /// The DO cross-arm; the barrels hang open below it.
  double get doArmY => y(0.24);

  /// The transformer on its platform.
  Rect get tank => Rect.fromLTRB(136, y(0.47), 200, y(0.68));
  double get platformY => y(0.69);
  List<Offset> get htBushings => [for (final x in const [146.0, 168.0, 190.0]) Offset(x, tank.top - 12)];

  /// The LT box on the right pole (its plate reads "LT"; the log says which ways are in).
  Rect get ltBox => Rect.fromLTWH(rp + 6, y(0.74), 34, 26);

  /// The sectionalizing log clipped to the right pole.
  Rect get logHit => Rect.fromCenter(center: Offset(rp + 26, y(0.52)), width: 48, height: 56);

  /// The HT tester on its hot stick, leaning on the left pole (head up).
  Offset get testerHead => Offset(lp - 26, y(0.30));
  Offset get testerFoot => Offset(lp - 34, groundY - 2);
  Rect get testerHit {
    final a = testerHead;
    return Rect.fromLTWH(a.dx - 22, a.dy - 18, 44, math.min(110, (groundY - 92) - (a.dy - 18)));
  }

  /// The proof stations' props (tap one to open its close-up).
  Rect stationHit(M5WrStation s) => switch (s) {
        M5WrStation.bushing => Rect.fromLTRB(134, tank.top - 40, 202, tank.top + 6),
        M5WrStation.oil => Rect.fromLTWH(16, groundY - 62, 46, 56),
        M5WrStation.record => Rect.fromLTWH(302, groundY - 56, 50, 50),
        M5WrStation.ir => Rect.fromLTWH(298, groundY - 132, 54, 62),
      };

  Offset get jarAt => Offset(39, groundY - 38);
  Offset get bookAt => Offset(327, groundY - 40);
  Offset get irAt => Offset(325, groundY - 104);

  /// The van with its crane at the right edge.
  Rect get van => Rect.fromLTWH(292, groundY - 54, 86, 52);

  /// Where the lineman stands on the ground (right of the structure, clear of
  /// the corner guide, whose touch square covers x ≈ 100–236 near the ground).
  Rect get ground => Rect.fromLTWH(234, groundY - 108, 50, 108);

  /// The flash on a deadly move: at the bushings (no test) or the tank (charge).
  Offset get flashBushing => htBushings[1].translate(0, -10);
  Offset get flashTank => tank.center;

  @override
  bool operator ==(Object other) => other is M5WrGeo && other.height == height && other.groundY == groundY && other.topY == topY;

  @override
  int get hashCode => Object.hash(height, groundY, topY);
}

/// What the site shows now.
@immutable
class M5WrRig {
  const M5WrRig({required this.tested, required this.sent, required this.lift});

  /// The tester has shown 0 V (it now rests by the transformer).
  final bool tested;

  /// The transformer has gone to the workshop.
  final bool sent;

  /// The crane's lift, 0 → 1 (the tank rises off the platform).
  final double lift;

  @override
  bool operator ==(Object other) => other is M5WrRig && other.tested == tested && other.sent == sent && other.lift == lift;

  @override
  int get hashCode => Object.hash(tested, sent, lift);
}

const _steel = Color(0xFF6F7880);
const _wire = Color(0xFF3C4248);
const _porcelain = Color(0xFFE9EDF0);
const _copper = Color(0xFFC87533);

void _insulator(Canvas c, Offset base, {double scale = 1}) {
  c.save();
  c.translate(base.dx, base.dy);
  c.scale(scale);
  final body = Paint()..color = _porcelain;
  final rim = Paint()
    ..color = const Color(0xFF9AA3AA)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  for (var i = 0; i < 3; i++) {
    final r = Rect.fromCenter(center: Offset(0, -4 - i * 5.0), width: 16 - i * 2.5, height: 5);
    c.drawOval(r, body);
    c.drawOval(r, rim);
  }
  c.drawRect(const Rect.fromLTWH(-2, -2, 4, 4), Paint()..color = _steel);
  c.restore();
}

void _label(Canvas c, String text, Offset centre, {double size = 9, Color color = Colors.white, FontWeight weight = FontWeight.w800}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: weight, color: color, height: 1)),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
}

class M5WrPainter extends CustomPainter {
  const M5WrPainter({required this.geo, required this.rig, required this.seed});

  final M5WrGeo geo;
  final M5WrRig rig;

  /// The site (the village behind differs).
  final int seed;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    final rnd = math.Random(seed);
    // Sky: late afternoon, a little different per site.
    final warm = rnd.nextDouble();
    c.drawRect(
        Rect.fromLTWH(0, 0, w, g.groundY),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(const Color(0xFF3B6FA8), const Color(0xFF4A6E9C), warm)!,
              Color.lerp(const Color(0xFF9CC3E2), const Color(0xFFE8C9A0), warm)!,
              const Color(0xFFE6E2CC),
            ],
          ).createShader(Rect.fromLTWH(0, 0, w, g.groundY)));
    final cloud = Paint()..color = const Color(0xBBFFFFFF);
    for (var i = 0; i < 3; i++) {
      final cx = 30 + rnd.nextDouble() * 300;
      final cy = 70 + rnd.nextDouble() * (g.topY - 30).clamp(20.0, 220.0);
      for (var k = 0; k < 4; k++) {
        c.drawOval(Rect.fromCenter(center: Offset(cx + k * 13 - 20, cy - (k.isOdd ? 5 : 0)), width: 32, height: 16), cloud);
      }
    }
    // Far tree line, village roofs, paddy.
    final horizon = g.groundY - g.h * 0.2;
    final tree = Paint()..color = const Color(0xFF4A7A42);
    for (var x = -10.0; x < w + 20; x += 18 + rnd.nextDouble() * 18) {
      final r = 8 + rnd.nextDouble() * 10;
      c.drawCircle(Offset(x, horizon - r * 0.5), r, tree);
    }
    final roofs = 2 + rnd.nextInt(3);
    for (var i = 0; i < roofs; i++) {
      final x = 10 + rnd.nextDouble() * 320;
      c.drawRect(Rect.fromLTWH(x + 3, horizon - 9, 22, 9), Paint()..color = const Color(0xFFD8C7A2));
      c.drawPath(
          Path()
            ..moveTo(x, horizon - 8)
            ..lineTo(x + 14, horizon - 20)
            ..lineTo(x + 28, horizon - 8)
            ..close(),
          Paint()..color = rnd.nextBool() ? const Color(0xFF8D5A3A) : const Color(0xFF7D8890));
    }
    c.drawRect(Rect.fromLTRB(0, horizon, w, g.groundY), Paint()..color = const Color(0xFF8DB55A));
    final row = Paint()
      ..color = const Color(0x334A6B2A)
      ..strokeWidth = 1;
    for (var y = horizon + 6; y < g.groundY; y += 7) {
      c.drawLine(Offset(0, y), Offset(w, y), row);
    }
    final floor = Rect.fromLTRB(0, g.groundY, w, size.height);
    c.drawRect(floor, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFA88B62), Color(0xFF7A6345)]).createShader(floor));

    _van(c);
    _poles(c);
    _line(c);
    _doArm(c);
    _earth(c);
    _transformer(c);
    _ltBox(c);
    _log(c);
    _tester(c);
    _props(c);
  }

  void _poles(Canvas c) {
    final g = geo;
    for (final x in const [M5WrGeo.lp, M5WrGeo.rp]) {
      final r = Rect.fromLTRB(x - 6, g.topY, x + 6, g.groundY + 4);
      c.drawRect(r, Paint()..shader = const LinearGradient(colors: [Color(0xFF8C939A), Color(0xFFC9CED2), Color(0xFF7A8187)]).createShader(r));
    }
    _channel(c, Offset(M5WrGeo.lp - 22, g.armY), Offset(M5WrGeo.rp + 22, g.armY));
    _channel(c, Offset(M5WrGeo.lp - 10, g.platformY), Offset(M5WrGeo.rp + 10, g.platformY));
  }

  void _channel(Canvas c, Offset a, Offset b) {
    c.drawLine(a, b, Paint()
      ..color = const Color(0xFF4E565D)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.square);
    c.drawLine(a.translate(0, -2), b.translate(0, -2), Paint()
      ..color = const Color(0xFF9AA2A8)
      ..strokeWidth = 2);
  }

  void _line(Canvas c) {
    final g = geo;
    final wire = Paint()
      ..color = _wire
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    for (final (i, x) in M5WrGeo.phaseX.indexed) {
      final top = Offset(x, g.armY - 18);
      _insulator(c, Offset(x, g.armY - 4));
      c.drawPath(Path()
        ..moveTo(top.dx, top.dy)
        ..quadraticBezierTo(top.dx / 2, top.dy + 16, -10, top.dy + 24 + i * 3.0), wire);
      c.drawPath(Path()
        ..moveTo(top.dx, top.dy)
        ..quadraticBezierTo((top.dx + 370) / 2, top.dy + 16, 370, top.dy + 24 + i * 3.0), wire);
      // The jumper down to the DO's top contact.
      c.drawPath(Path()
        ..moveTo(top.dx, top.dy + 2)
        ..cubicTo(top.dx - 12, top.dy + 16, top.dx - 12, g.doArmY - 22, top.dx, g.doArmY - 6), wire..strokeWidth = 2);
      wire.strokeWidth = 1.8;
    }
  }

  void _doArm(Canvas c) {
    final g = geo;
    _channel(c, Offset(M5WrGeo.lp - 16, g.doArmY), Offset(M5WrGeo.rp + 16, g.doArmY));
    final lead = Paint()
      ..color = const Color(0xFF2F353A)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 3; i++) {
      final x = M5WrGeo.phaseX[i];
      // The DO base insulator and its contacts; the barrel hangs open (dropped
      // out, swung down from the bottom hinge).
      c.drawRect(Rect.fromLTWH(x - 4, g.doArmY - 8, 8, 4), Paint()..color = _steel);
      c.drawRect(Rect.fromLTWH(x - 4, g.doArmY + 26, 8, 4), Paint()..color = _steel);
      c.save();
      c.translate(x + 2, g.doArmY + 28);
      c.rotate(2.6);
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-3, 0, 6, 26), const Radius.circular(2)), Paint()..color = const Color(0xFF7B5A3A));
      c.restore();
      // The HT lead on to the bushing.
      final from = Offset(x, g.doArmY + 30);
      final to = g.htBushings[i].translate(0, -6);
      if (!rig.sent) {
        final lift = rig.lift;
        final t = to.translate(0, -lift * (to.dy - g.topY + 80));
        c.drawPath(Path()
          ..moveTo(from.dx, from.dy)
          ..cubicTo(from.dx, from.dy + 18, t.dx, t.dy - 18, t.dx, t.dy), lead);
      }
    }
    // The red "do not close" tag on the DO arm.
    final tagAt = Offset(M5WrGeo.phaseX[0] - 18, g.doArmY + 4);
    c.drawLine(tagAt, tagAt.translate(0, 8), Paint()
      ..color = const Color(0xFF3A3F45)
      ..strokeWidth = 1.2);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(tagAt.dx - 7, tagAt.dy + 8, 14, 18), const Radius.circular(2)), Paint()..color = const Color(0xFFD23A2E));
    c.drawRect(Rect.fromLTWH(tagAt.dx - 5, tagAt.dy + 13, 10, 2), Paint()..color = Colors.white);
    c.drawRect(Rect.fromLTWH(tagAt.dx - 5, tagAt.dy + 18, 10, 2), Paint()..color = Colors.white);
  }

  void _earth(Canvas c) {
    final g = geo;
    // The HT earth set: a shorting bar across the three HT leads, its lead to
    // a spike at the left pole's foot.
    final barY = g.doArmY + 44;
    c.drawLine(Offset(M5WrGeo.phaseX[0] - 4, barY), Offset(M5WrGeo.phaseX[2] + 4, barY), Paint()
      ..color = const Color(0xFF3A3F45)
      ..strokeWidth = 3);
    final spike = Offset(M5WrGeo.lp + 14, g.groundY - 4);
    c.drawPath(
        Path()
          ..moveTo(M5WrGeo.phaseX[0] - 4, barY)
          ..quadraticBezierTo(M5WrGeo.lp - 6, (barY + spike.dy) / 2, spike.dx, spike.dy),
        Paint()
          ..color = _copper
          ..strokeWidth = 2.2
          ..style = PaintingStyle.stroke);
    c.drawLine(spike, spike.translate(0, 10), Paint()
      ..color = const Color(0xFF5A6066)
      ..strokeWidth = 4);
    c.drawCircle(spike, 5, Paint()..color = _copper);
  }

  void _transformer(Canvas c) {
    if (rig.sent) return;
    final g = geo;
    final dy = -rig.lift * (g.tank.bottom - g.topY + 60);
    c.save();
    c.translate(0, dy);
    final t = g.tank;
    final body = RRect.fromRectAndRadius(t, const Radius.circular(4));
    c.drawRRect(body.shift(const Offset(3, 3)), Paint()..color = const Color(0x44000000));
    c.drawRRect(body, Paint()..shader = const LinearGradient(colors: [Color(0xFF6E7F72), Color(0xFF9DB0A1), Color(0xFF627266)]).createShader(t));
    final fin = Paint()
      ..color = const Color(0x55313D33)
      ..strokeWidth = 2;
    for (var x = t.left + 8; x < t.right - 4; x += 8) {
      c.drawLine(Offset(x, t.top + 10), Offset(x, t.bottom - 6), fin);
    }
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(t.left + 4, t.top - 22, 24, 11), const Radius.circular(6)), Paint()..color = const Color(0xFF7E8F82));
    for (final b in g.htBushings) {
      _insulator(c, b.translate(0, 12));
    }
    final lt = Paint()..color = const Color(0xFF5B4632);
    for (var k = 0; k < 3; k++) {
      c.drawRect(Rect.fromLTWH(t.right - 2, t.top + 12 + k * 10, 8, 5), lt);
    }
    if (rig.lift > 0) {
      // The crane's sling and hook.
      final hook = Offset(t.center.dx, t.top - 30);
      final sling = Paint()
        ..color = const Color(0xFF2B2F33)
        ..strokeWidth = 1.6;
      c.drawLine(hook, Offset(t.left + 4, t.top), sling);
      c.drawLine(hook, Offset(t.right - 4, t.top), sling);
      c.drawLine(hook, Offset(hook.dx, -400), sling..strokeWidth = 2.2);
    }
    c.restore();
  }

  void _ltBox(Canvas c) {
    final g = geo;
    final box = g.ltBox;
    c.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(3)), Paint()..color = const Color(0xFF8A939A));
    c.drawRRect(
        RRect.fromRectAndRadius(box, const Radius.circular(3)),
        Paint()
          ..color = const Color(0xFF4E565D)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4);
    final plate = Rect.fromCenter(center: box.center, width: 24, height: 12);
    c.drawRect(plate, Paint()..color = const Color(0xFF2B2F33));
    _label(c, 'LT', plate.center, size: 8, color: const Color(0xFFE6EEF3));
    // LT cables down into the box.
    final cable = Paint()
      ..color = const Color(0xFF1A1C1E)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;
    for (var k = 0; k < 3; k++) {
      c.drawLine(Offset(M5WrGeo.rp + 8 + k * 3.0, g.platformY), Offset(M5WrGeo.rp + 8 + k * 3.0, box.top), cable);
    }
  }

  void _log(Canvas c) {
    final r = geo.logHit.deflate(6);
    c.drawRRect(RRect.fromRectAndRadius(r.shift(const Offset(2, 2)), const Radius.circular(3)), Paint()..color = const Color(0x44000000));
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), Paint()..color = const Color(0xFF8A5A2E));
    final paper = r.deflate(3).translate(0, 3);
    c.drawRect(paper, Paint()..color = const Color(0xFFF7F3E6));
    c.drawRect(Rect.fromCenter(center: Offset(r.center.dx, r.top + 2), width: 16, height: 6), Paint()..color = const Color(0xFFB8BEC3));
    final ink = Paint()
      ..color = const Color(0xFF5C6B80)
      ..strokeWidth = 1;
    for (var y = paper.top + 8; y < paper.bottom - 4; y += 6) {
      c.drawLine(Offset(paper.left + 4, y), Offset(paper.right - 4, y), ink);
    }
    // The strap round the pole.
    c.drawLine(Offset(M5WrGeo.rp - 7, r.top + 6), Offset(r.left, r.top + 6), Paint()
      ..color = const Color(0xFF3A2A16)
      ..strokeWidth = 2);
  }

  void _tester(Canvas c) {
    final g = geo;
    if (rig.tested && !rig.sent) {
      // Tested: the stick rests by the transformer, its head by the bushings.
      final head = g.htBushings[0].translate(-14, -6);
      final foot = Offset(g.tank.left - 20, g.groundY - 2);
      _stick(c, head, foot);
      return;
    }
    _stick(c, g.testerHead, g.testerFoot);
  }

  void _stick(Canvas c, Offset head, Offset foot) {
    c.drawLine(foot, head, Paint()
      ..color = const Color(0xFFE2B33A)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round);
    // Grip bands near the foot.
    final dir = (head - foot) / (head - foot).distance;
    for (var k = 0; k < 2; k++) {
      final p = foot + dir * (18.0 + k * 10);
      c.drawCircle(p, 3, Paint()..color = const Color(0xFFB0302A));
    }
    // The tester head.
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: head, width: 14, height: 20), const Radius.circular(4)), Paint()..color = const Color(0xFFFFD84A));
    c.drawCircle(head.translate(0, -4), 3, Paint()..color = const Color(0xFF3A3F45));
    c.drawLine(head.translate(0, -10), head.translate(0, -16), Paint()
      ..color = const Color(0xFF8C939A)
      ..strokeWidth = 2);
  }

  void _props(Canvas c) {
    final g = geo;
    // The oil jar on a crate.
    final crate = Rect.fromLTWH(g.jarAt.dx - 18, g.groundY - 20, 36, 20);
    c.drawRect(crate, Paint()..color = const Color(0xFF9A7448));
    c.drawLine(crate.topLeft.translate(0, 7), crate.topRight.translate(0, 7), Paint()
      ..color = const Color(0xFF6E5232)
      ..strokeWidth = 1.4);
    final jar = Rect.fromCenter(center: g.jarAt.translate(0, -8), width: 18, height: 26);
    c.drawRRect(RRect.fromRectAndRadius(jar, const Radius.circular(4)), Paint()..color = const Color(0xCC6E6A5A));
    c.drawRect(Rect.fromLTWH(jar.left + 2, jar.top - 5, jar.width - 4, 6), Paint()..color = const Color(0xFF3A3F45));
    c.drawLine(jar.topLeft.translate(4, 4), jar.bottomLeft.translate(4, -4), Paint()
      ..color = const Color(0x66FFFFFF)
      ..strokeWidth = 1.6);
    // The record book on a stool.
    final b = g.bookAt;
    c.drawLine(b.translate(-14, 10), b.translate(-16, 38), Paint()
      ..color = const Color(0xFF6E5232)
      ..strokeWidth = 3);
    c.drawLine(b.translate(14, 10), b.translate(16, 38), Paint()
      ..color = const Color(0xFF6E5232)
      ..strokeWidth = 3);
    c.drawRect(Rect.fromCenter(center: b.translate(0, 8), width: 40, height: 6), Paint()..color = const Color(0xFF8A6A44));
    c.drawRect(Rect.fromCenter(center: b.translate(0, -1), width: 30, height: 10), Paint()..color = const Color(0xFF7A2E2A));
    c.drawRect(Rect.fromCenter(center: b.translate(0, -1), width: 26, height: 2), Paint()..color = const Color(0xFFF2E6C8));
    // The IR card on its stand.
    final ir = g.irAt;
    c.drawLine(ir.translate(0, 20), Offset(ir.dx, g.groundY), Paint()
      ..color = const Color(0xFF4E565D)
      ..strokeWidth = 3);
    final card = Rect.fromCenter(center: ir, width: 34, height: 42);
    c.drawRRect(RRect.fromRectAndRadius(card, const Radius.circular(3)), Paint()..color = const Color(0xFF3E5A7A));
    final sheet = card.deflate(4).translate(0, 2);
    c.drawRect(sheet, Paint()..color = const Color(0xFFF7F3E6));
    for (var k = 0; k < 3; k++) {
      final y = sheet.top + 7 + k * 10.0;
      c.drawLine(Offset(sheet.left + 3, y), Offset(sheet.right - 3, y), Paint()
        ..color = const Color(0xFF8C939A)
        ..strokeWidth = 2);
    }
  }

  void _van(Canvas c) {
    final g = geo;
    final v = g.van;
    // The crane boom over the cab.
    final pivot = Offset(v.left + 30, v.top + 4);
    c.drawLine(pivot, Offset(v.left - 30, v.top - 110), Paint()
      ..color = const Color(0xFFE8A41E)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round);
    c.drawRRect(RRect.fromRectAndRadius(v, const Radius.circular(6)), Paint()..color = const Color(0xFFDDE3E8));
    c.drawRect(Rect.fromLTWH(v.left, v.top + 30, v.width, 8), Paint()..color = const Color(0xFF2E6FB0));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(v.left + 6, v.top + 6, 22, 18), const Radius.circular(3)), Paint()..color = const Color(0xFF8FB7D6));
    for (final x in [v.left + 16, v.left + 62]) {
      c.drawCircle(Offset(x, v.bottom), 9, Paint()..color = const Color(0xFF22262A));
      c.drawCircle(Offset(x, v.bottom), 4, Paint()..color = const Color(0xFF8C939A));
    }
  }

  @override
  bool shouldRepaint(M5WrPainter old) => old.geo != geo || old.rig != rig || old.seed != seed;
}

/// The flash of a deadly move at [at], [v] 0 → 1 (an arc or a blast).
class M5WrFlashPainter extends CustomPainter {
  const M5WrFlashPainter({required this.at, required this.v, this.blast = false});
  final Offset at;
  final double v;

  /// A tank blast (bigger, with smoke) instead of an arc.
  final bool blast;

  @override
  void paint(Canvas c, Size size) {
    final flick = v < 0.5 ? (0.65 + 0.35 * math.sin(v * 60).abs()) : (1 - (v - 0.5) * 1.2).clamp(0.4, 1.0);
    final r = (blast ? 40 : 24) + (blast ? 110 : 70) * Curves.easeOut.transform(v.clamp(0.0, 1.0));
    c.drawCircle(
        at,
        r,
        Paint()
          ..shader = RadialGradient(colors: [
            Color.fromRGBO(255, 250, 220, 0.95 * flick),
            blast ? Color.fromRGBO(255, 140, 40, 0.6 * flick) : Color.fromRGBO(140, 170, 255, 0.5 * flick),
            const Color(0x00FFC24A),
          ]).createShader(Rect.fromCircle(center: at, radius: r)));
    final spark = Paint()
      ..color = Color.fromRGBO(255, 214, 90, (1 - v).clamp(0.0, 1.0))
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 16; i++) {
      final a = i / 16 * math.pi * 2 + 0.2;
      final d0 = 10 + (blast ? 80 : 50) * v;
      c.drawLine(at + Offset(math.cos(a), math.sin(a)) * d0, at + Offset(math.cos(a), math.sin(a)) * (d0 + 14), spark);
    }
    if (blast && v > 0.3) {
      final smoke = Paint()..color = Color.fromRGBO(40, 40, 44, (0.55 * (v - 0.3) / 0.7).clamp(0.0, 0.55));
      for (var k = 0; k < 5; k++) {
        c.drawCircle(at.translate(-30 + k * 15.0, -30 - 50 * v - (k.isOdd ? 12 : 0)), 18 + 10 * v, smoke);
      }
    }
    final white = (1 - v * 4).clamp(0.0, 1.0);
    if (white > 0) c.drawRect(Offset.zero & size, Paint()..color = Color.fromRGBO(255, 255, 255, 0.8 * white));
  }

  @override
  bool shouldRepaint(M5WrFlashPainter old) => old.v != v || old.at != at || old.blast != blast;
}

// ============================================================================
// The close-ups (lens): local coordinates in a 300 × 210 box.
// ============================================================================

abstract final class M5WrLens {
  static const Size size = Size(300, 210);

  /// The three HT bushings, left to right.
  static Rect bushing(int i) => Rect.fromLTWH(60.0 + i * 90 - 32, 22, 64, 166);

  /// The IR card's three rows (HT–E, LT–E, HT–LT).
  static Rect irRow(int i) => Rect.fromLTWH(10, 10 + i * 66.0, 280, 58);

  /// The oil jar: its body (hold it to the sun, swipe to swirl), its mouth
  /// (sniff), and the three regions a finding is pinned on.
  static const Rect jar = Rect.fromLTWH(100, 46, 100, 150);
  static const Rect mouth = Rect.fromLTWH(108, 6, 84, 40);
  static Rect oilPart(M5WrOilPart p) => switch (p) {
        M5WrOilPart.colour => const Rect.fromLTWH(100, 56, 100, 92),
        M5WrOilPart.water => const Rect.fromLTWH(100, 150, 100, 46),
        M5WrOilPart.smell => const Rect.fromLTWH(208, 4, 86, 70),
      };

  /// The record book's entries, top to bottom.
  static Rect entry(int i) => Rect.fromLTWH(10, 8 + i * 50.0, 280, 46);
}

/// The bushings close-up. [mark]: per bushing, 0 clean, 1 crack, 2 flashover
/// track. [dust] 1 → 0 as the cloth passes.
class M5WrBushingPainter extends CustomPainter {
  const M5WrBushingPainter({required this.mark, required this.dust, required this.pinned});
  final List<int> mark;
  final double dust;
  final Set<int> pinned;

  @override
  void paint(Canvas c, Size size) {
    c.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
        Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF6E8FB0), Color(0xFF9DB0A1)]).createShader(Offset.zero & size));
    // The tank lid.
    c.drawRect(Rect.fromLTWH(0, size.height - 26, size.width, 26), Paint()..color = const Color(0xFF627266));
    for (var i = 0; i < 3; i++) {
      final r = M5WrLens.bushing(i);
      final cx = r.center.dx;
      // Sheds, top to bottom.
      for (var k = 0; k < 6; k++) {
        final y = r.top + 14 + k * 24.0;
        final sw = 40.0 + (k.isEven ? 16 : 6);
        final shed = Rect.fromCenter(center: Offset(cx, y), width: sw, height: 12);
        c.drawOval(shed, Paint()..shader = const LinearGradient(colors: [Color(0xFFCBD2D8), Color(0xFFF4F6F8), Color(0xFFB9C1C8)]).createShader(shed));
        c.drawOval(
            shed,
            Paint()
              ..color = const Color(0xFF8E979F)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1);
      }
      c.drawRect(Rect.fromLTWH(cx - 9, r.top + 14, 18, r.height - 30), Paint()..color = const Color(0x55DCE2E7));
      // The terminal stud.
      c.drawRect(Rect.fromLTWH(cx - 3, r.top, 6, 12), Paint()..color = const Color(0xFF8C939A));
      // The marks show only as the cloth clears the dust (none through it).
      final show = (1 - dust).clamp(0.0, 1.0);
      final m = show < 0.001 ? 0 : mark[i];
      if (m == 1) {
        // A crack across two sheds.
        c.drawPath(
            Path()
              ..moveTo(cx - 18, r.top + 58)
              ..lineTo(cx - 6, r.top + 66)
              ..lineTo(cx - 10, r.top + 76)
              ..lineTo(cx + 4, r.top + 84)
              ..lineTo(cx + 2, r.top + 94)
              ..lineTo(cx + 16, r.top + 102),
            Paint()
              ..color = const Color(0xFF2A2420).withValues(alpha: show)
              ..strokeWidth = 2
              ..style = PaintingStyle.stroke);
      } else if (m == 2) {
        // A flashover track: a burnt streak down the surface.
        final track = Path()
          ..moveTo(cx + 12, r.top + 16)
          ..cubicTo(cx + 22, r.top + 60, cx - 4, r.top + 90, cx + 10, r.bottom - 22);
        c.drawPath(
            track,
            Paint()
              ..color = const Color(0xCC2B1E14).withValues(alpha: 0.8 * show)
              ..strokeWidth = 7
              ..strokeCap = StrokeCap.round
              ..style = PaintingStyle.stroke);
        c.drawPath(
            track,
            Paint()
              ..color = const Color(0x88704A2A).withValues(alpha: 0.533 * show)
              ..strokeWidth = 13
              ..strokeCap = StrokeCap.round
              ..style = PaintingStyle.stroke);
      }
      if (pinned.contains(i)) _pin(c, Offset(r.right - 8, r.top + 8));
    }
    if (dust > 0.001) {
      // Road dust over every bushing alike (it hides the surface until the cloth pass).
      final d = Paint()..color = Color.fromRGBO(150, 120, 80, 0.86 * dust);
      for (var i = 0; i < 3; i++) {
        final r = M5WrLens.bushing(i);
        c.drawRRect(RRect.fromRectAndRadius(r.deflate(2), const Radius.circular(14)), d);
        final speck = Paint()..color = Color.fromRGBO(110, 86, 56, 0.7 * dust);
        for (var k = 0; k < 14; k++) {
          c.drawCircle(Offset(r.left + 8 + (k * 37 % 48), r.top + 10 + (k * 53 % 150)), 2.2, speck);
        }
      }
    }
  }

  @override
  bool shouldRepaint(M5WrBushingPainter old) => old.dust != dust || !listEquals(old.mark, mark) || !setEquals(old.pinned, pinned);
}

/// A red map pin (a finding on the slip).
void _pin(Canvas c, Offset at) {
  c.drawLine(at, at.translate(0, 10), Paint()
    ..color = const Color(0xFF3A3F45)
    ..strokeWidth = 2);
  c.drawCircle(at, 6, Paint()..color = const Color(0xFFD23A2E));
  c.drawCircle(at.translate(-2, -2), 2, Paint()..color = const Color(0xAAFFFFFF));
}

/// One IR card row's scale: a needle at [low] ? near 0 : near ∞.
class M5WrIrScalePainter extends CustomPainter {
  const M5WrIrScalePainter({required this.low, required this.pinned});
  final bool low;
  final bool pinned;

  @override
  void paint(Canvas c, Size size) {
    final y = size.height * 0.62;
    final l = 14.0;
    final r = size.width - 14;
    c.drawLine(Offset(l, y), Offset(r, y), Paint()
      ..color = const Color(0xFF3A4660)
      ..strokeWidth = 2);
    for (var k = 0; k <= 10; k++) {
      final x = l + (r - l) * k / 10;
      c.drawLine(Offset(x, y), Offset(x, y - (k % 5 == 0 ? 9 : 5)), Paint()
        ..color = const Color(0xFF3A4660)
        ..strokeWidth = 1.2);
    }
    final nx = low ? l + (r - l) * 0.03 : l + (r - l) * 0.94;
    c.drawPath(
        Path()
          ..moveTo(nx, y - 16)
          ..lineTo(nx - 5, y - 26)
          ..lineTo(nx + 5, y - 26)
          ..close(),
        Paint()..color = const Color(0xFFB0302A));
    c.drawLine(Offset(nx, y - 16), Offset(nx, y + 2), Paint()
      ..color = const Color(0xFFB0302A)
      ..strokeWidth = 2);
    if (pinned) _pin(c, Offset(size.width - 8, 8));
  }

  @override
  bool shouldRepaint(M5WrIrScalePainter old) => old.low != low || old.pinned != pinned;
}

/// The oil jar close-up. [step]: 0 in shade, 1 held to the sun (the colour
/// shows), 2 swirled (the bottom shows), 3 sniffed (the smell shows).
class M5WrOilPainter extends CustomPainter {
  const M5WrOilPainter({required this.step, required this.dark, required this.water, required this.burnt, required this.pinned, required this.swirl});
  final int step;
  final bool dark;
  final bool water;
  final bool burnt;
  final Set<M5WrOilPart> pinned;

  /// The swirl's ripple, 0 → 1 (only right after the swirl).
  final double swirl;

  @override
  void paint(Canvas c, Size size) {
    final sun = step >= 1;
    c.drawRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: sun ? const [Color(0xFFFFE9A8), Color(0xFF9CC3E2)] : const [Color(0xFF5C6B80), Color(0xFF3A4660)],
          ).createShader(Offset.zero & size));
    if (sun) {
      c.drawCircle(const Offset(270, 30), 22, Paint()..color = const Color(0xFFFFF4C2));
    }
    const jar = M5WrLens.jar;
    final glass = RRect.fromRectAndRadius(jar, const Radius.circular(14));
    // The oil: in shade every jar looks the same murky grey.
    final Color top;
    final Color bottom;
    if (!sun) {
      top = const Color(0xFF6A6658);
      bottom = const Color(0xFF55513F);
    } else if (dark) {
      top = const Color(0xFF2A2218);
      bottom = const Color(0xFF14100B);
    } else {
      top = const Color(0xFFE2B85A);
      bottom = const Color(0xFFC9973A);
    }
    final oil = Rect.fromLTRB(jar.left, jar.top + 14, jar.right, jar.bottom);
    c.save();
    c.clipRRect(glass);
    c.drawRect(oil, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, bottom]).createShader(oil));
    if (swirl > 0.001) {
      final ring = Paint()
        ..color = Color.fromRGBO(255, 255, 255, 0.35 * swirl)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      for (var k = 0; k < 3; k++) {
        c.drawOval(Rect.fromCenter(center: Offset(jar.center.dx, jar.top + 40 + k * 30), width: 70 * (1 - swirl * 0.3), height: 10), ring);
      }
    }
    if (sun && dark) {
      // Carbon specks floating.
      final speck = Paint()..color = const Color(0xFF050403);
      for (var k = 0; k < 18; k++) {
        c.drawCircle(Offset(jar.left + 10 + (k * 41 % 80), jar.top + 24 + (k * 29 % 100)), 1.8, speck);
      }
    }
    if (step >= 2 && water) {
      // Water beads settled at the bottom.
      final bead = Paint()..color = const Color(0xDDBFE3F5);
      final rim = Paint()
        ..color = const Color(0xFF6FA8C8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      for (var k = 0; k < 7; k++) {
        final p = Offset(jar.left + 16 + k * 11.0, jar.bottom - 10 - (k.isOdd ? 6 : 0));
        c.drawCircle(p, 5, bead);
        c.drawCircle(p, 5, rim);
      }
    }
    c.restore();
    // The glass and its lid (off: open for the sniff).
    c.drawRRect(
        glass,
        Paint()
          ..color = const Color(0xCCE6EEF3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    c.drawLine(jar.topLeft.translate(12, 20), jar.bottomLeft.translate(12, -20), Paint()
      ..color = const Color(0x77FFFFFF)
      ..strokeWidth = 4);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(jar.left + 10, jar.top - 8, jar.width - 20, 12), const Radius.circular(3)), Paint()..color = const Color(0xFF8C939A));
    if (step >= 3) {
      // The smell, drawn as what rises from the open jar.
      final p = M5WrLens.oilPart(M5WrOilPart.smell);
      c.drawRRect(RRect.fromRectAndRadius(p.deflate(4), const Radius.circular(20)), Paint()..color = const Color(0xEEF7F3E6));
      final curl = Paint()
        ..color = burnt ? const Color(0xFF2B2420) : const Color(0xFFB9C1C8)
        ..strokeWidth = burnt ? 4 : 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      for (var k = 0; k < 3; k++) {
        final x = p.left + 22 + k * 20.0;
        c.drawPath(
            Path()
              ..moveTo(x, p.bottom - 14)
              ..cubicTo(x - 10, p.bottom - 26, x + 10, p.top + 28, x, p.top + 14),
            curl);
      }
      if (burnt) {
        c.drawCircle(p.center.translate(-18, 10), 8, Paint()..color = const Color(0x55302824));
        c.drawCircle(p.center.translate(16, 4), 10, Paint()..color = const Color(0x55302824));
      }
      c.drawLine(Offset(jar.center.dx + 20, jar.top - 10), Offset(p.left + 8, p.bottom - 8), Paint()
        ..color = const Color(0x88B9C1C8)
        ..strokeWidth = 1.4);
    }
    for (final part in pinned) {
      final r = M5WrLens.oilPart(part);
      _pin(c, Offset(r.right - 10, r.top + 10));
    }
  }

  @override
  bool shouldRepaint(M5WrOilPainter old) =>
      old.step != step || old.dark != dark || old.water != water || old.burnt != burnt || old.swirl != swirl || !setEquals(old.pinned, pinned);
}

/// The record book's ruled page (the entries are text on top).
class M5WrPagePainter extends CustomPainter {
  const M5WrPagePainter({required this.pinned});
  final Set<int> pinned;

  @override
  void paint(Canvas c, Size size) {
    c.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10)), Paint()..color = const Color(0xFFF7F3E6));
    c.drawLine(const Offset(34, 0), Offset(34, size.height), Paint()
      ..color = const Color(0x66D23A2E)
      ..strokeWidth = 1.4);
    for (var i = 0; i < 4; i++) {
      final r = M5WrLens.entry(i);
      c.drawLine(Offset(6, r.bottom + 2), Offset(size.width - 6, r.bottom + 2), Paint()
        ..color = const Color(0x445C6B80)
        ..strokeWidth = 1);
      if (pinned.contains(i)) _pin(c, Offset(r.right - 8, r.top + 10));
    }
  }

  @override
  bool shouldRepaint(M5WrPagePainter old) => !setEquals(old.pinned, pinned);
}
