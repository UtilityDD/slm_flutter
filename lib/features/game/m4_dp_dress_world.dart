import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The drawn world of lesson 4.7 কাজ 2 "পরিচ্ছন্নতার শিল্প" (m4_dp_dress.dart):
// a village DP (double pole) transformer structure in the late-morning light,
// seen from the front. The 11 kV line comes in from a far pole on the left,
// over the top cross-arm's three pin insulators, and runs on to a far pole on
// the right; jumpers drop from the line to the DO-fuse cross-arm, leads go on
// to the transformer's HT bushings; the transformer sits on its platform
// between the poles, its LT cables run down the right pole to the LT box.
// An earth set can hang on each side span (left / right), its lead down to an
// earth spike at the foot of the span.
//
// Six places can be untidy (the lesson's mistakes): the left jumper tangled,
// the right jumper bowed onto the pole (no clearance), a long binding-wire
// tail at the middle insulator, the DO cross-arm out of level, a loose LT
// lug, the LT cables hanging loose. Untidy and tidy are drawn differently;
// there is no text in the art. Code-drawn, gradients, no bitmaps.
//
// Design: 360 wide × the scene's height; the ground follows the bottom of the
// screen (a tall phone gets a taller structure and more sky, never stretched).

/// The places on the structure (index = slot).
enum M4DpDressSlot { tangle, clearance, tail, tilt, loose, ltCable }

/// Where things are (design px, 360 wide).
@immutable
class M4DpDressGeo {
  const M4DpDressGeo._(this.height, this.groundY, this.topY);

  factory M4DpDressGeo.forScene(double height, double inset) {
    final g = height - floorUp - inset * 0.5;
    return M4DpDressGeo._(height, g, math.max(150.0, g - 470));
  }

  final double height;

  /// The ground line at the poles' feet.
  final double groundY;

  /// The top of the poles.
  final double topY;

  /// The ground sits this far above the bottom (the tool row stands on it).
  static const double floorUp = 112;

  /// The two poles' axes.
  static const double lp = 118;
  static const double rp = 242;

  /// The structure's height.
  double get h => groundY - topY;

  /// A height on the structure (0 = the pole tops, 1 = the ground).
  double y(double f) => topY + f * h;

  /// The top cross-arm and its three pin insulators (their tops carry the line).
  double get armY => y(0.06);
  static const List<double> phaseX = [134, 180, 226];
  List<Offset> get insulatorTops => [for (final x in phaseX) Offset(x, armY - 18)];

  /// The DO-fuse cross-arm (level when tidy).
  double get doArmY => y(0.29);

  /// The transformer between the poles, on its platform.
  Rect get tank => Rect.fromLTRB(146, y(0.50), 214, y(0.72));
  double get platformY => y(0.73);
  List<Offset> get htBushings => [for (final x in [156.0, 180.0, 204.0]) Offset(x, tank.top - 12)];

  /// The LT bushing lug on the tank's right side.
  Offset get ltLug => Offset(tank.right + 8, tank.top + 18);

  /// The LT box on the right pole.
  Rect get ltBox => Rect.fromLTWH(rp - 16, y(0.84), 36, 28);

  /// The far poles, and where the side spans' earth sets clamp on.
  Offset get farLeft => Offset(14, armY + 26);
  Offset get farRight => Offset(346, armY + 26);
  Offset get earthClampL => Offset(58, armY + 2);
  Offset get earthClampR => Offset(302, armY + 2);
  Offset get spikeL => Offset(46, groundY - 4);
  Offset get spikeR => Offset(314, groundY - 4);

  /// The earth set goes on (and comes off) at the side span's clamp point —
  /// tap there (well clear of the corner guide and the tool row).
  Rect earthHit(bool left) => Rect.fromCenter(center: (left ? earthClampL : earthClampR).translate(0, 14), width: 64, height: 76);

  Rect slotHit(M4DpDressSlot s) => switch (s) {
        M4DpDressSlot.tangle => Rect.fromLTRB(phaseX[0] - 26, armY - 4, phaseX[0] + 22, doArmY - 16),
        M4DpDressSlot.clearance => Rect.fromLTRB(phaseX[2] - 22, armY - 4, rp + 18, doArmY - 16),
        M4DpDressSlot.tail => Rect.fromCenter(center: insulatorTops[1], width: 48, height: 48),
        M4DpDressSlot.tilt => Rect.fromLTRB(lp - 22, doArmY - 16, rp + 22, doArmY + 22),
        M4DpDressSlot.loose => Rect.fromCenter(center: ltLug, width: 48, height: 48),
        M4DpDressSlot.ltCable => Rect.fromLTRB(rp - 22, tank.bottom - 6, rp + 34, ltBox.top - 2),
      };

  /// Where the lineman stands on the ground (right of the structure, clear of
  /// the corner guide on the left), and where he works aloft (on
  /// the left pole, strapped on, by the jumpers).
  Rect get ground => Rect.fromLTWH(272, groundY - 112, 56, 112);
  Rect get aloft => Rect.fromLTWH(lp - 52, y(0.11), 50, 100);

  /// Where the flash goes on a deadly move (the line by his hands).
  Offset get flashAt => Offset(phaseX[0], armY - 10);

  @override
  bool operator ==(Object other) => other is M4DpDressGeo && other.height == height && other.groundY == groundY && other.topY == topY;

  @override
  int get hashCode => Object.hash(height, groundY, topY);
}

/// What the structure shows now.
@immutable
class M4DpDressRig {
  const M4DpDressRig({required this.untidy, required this.earthL, required this.earthR, required this.aloft});

  /// The places still untidy.
  final Set<M4DpDressSlot> untidy;
  final bool earthL;
  final bool earthR;

  /// The lineman is up the pole (his strap is drawn).
  final bool aloft;

  @override
  bool operator ==(Object other) =>
      other is M4DpDressRig && setEquals(other.untidy, untidy) && other.earthL == earthL && other.earthR == earthR && other.aloft == aloft;

  @override
  int get hashCode => Object.hash(Object.hashAllUnordered(untidy), earthL, earthR, aloft);
}

const _steel = Color(0xFF6F7880);
const _wire = Color(0xFF3C4248);
const _porcelain = Color(0xFFE9EDF0);

class M4DpDressPainter extends CustomPainter {
  const M4DpDressPainter({required this.geo, required this.rig, required this.seed});

  final M4DpDressGeo geo;
  final M4DpDressRig rig;
  final int seed;

  bool _bad(M4DpDressSlot s) => rig.untidy.contains(s);

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    // Sky.
    c.drawRect(
        Rect.fromLTWH(0, 0, w, g.groundY),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3F79B8), Color(0xFF9CC6E6), Color(0xFFDDEBD6)],
          ).createShader(Rect.fromLTWH(0, 0, w, g.groundY)));
    final rnd = math.Random(seed);
    final cloud = Paint()..color = const Color(0xCCFFFFFF);
    for (var i = 0; i < 3; i++) {
      final cx = 40 + rnd.nextDouble() * 280;
      final cy = 70 + rnd.nextDouble() * (g.topY - 40).clamp(20.0, 200.0);
      for (var k = 0; k < 4; k++) {
        c.drawOval(Rect.fromCenter(center: Offset(cx + k * 14 - 20, cy - (k.isOdd ? 6 : 0)), width: 34, height: 18), cloud);
      }
    }
    // Far tree line and village roofs.
    final horizon = g.groundY - g.h * 0.22;
    final tree = Paint()..color = const Color(0xFF4F7F45);
    for (var x = -10.0; x < w + 20; x += 20 + rnd.nextDouble() * 16) {
      final r = 9 + rnd.nextDouble() * 9;
      c.drawCircle(Offset(x, horizon - r * 0.5), r, tree);
    }
    for (var i = 0; i < 4; i++) {
      final x = 20 + i * 92 + rnd.nextDouble() * 30;
      c.drawPath(
          Path()
            ..moveTo(x, horizon)
            ..lineTo(x + 14, horizon - 14)
            ..lineTo(x + 28, horizon)
            ..close(),
          Paint()..color = const Color(0xFF8D5A3A));
    }
    // Paddy fields to the ground line.
    c.drawRect(Rect.fromLTRB(0, horizon, w, g.groundY), Paint()..color = const Color(0xFF8DB55A));
    final row = Paint()
      ..color = const Color(0x334A6B2A)
      ..strokeWidth = 1;
    for (var y = horizon + 6; y < g.groundY; y += 7) {
      c.drawLine(Offset(0, y), Offset(w, y), row);
    }
    // The ground: a dirt verge.
    final floor = Rect.fromLTRB(0, g.groundY, w, size.height);
    c.drawRect(floor, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFA88B62), Color(0xFF7A6345)]).createShader(floor));

    _farPoles(c);
    _poles(c);
    _line(c);
    _jumpers(c);
    _doArm(c);
    _transformer(c);
    _ltCables(c);
    _earth(c, true);
    _earth(c, false);
  }

  void _farPoles(Canvas c) {
    final g = geo;
    final p = Paint()
      ..color = const Color(0xFF8E959B)
      ..strokeWidth = 4;
    for (final f in [g.farLeft, g.farRight]) {
      c.drawLine(Offset(f.dx, f.dy - 8), Offset(f.dx, g.groundY - g.h * 0.22 + 4), p);
      c.drawLine(Offset(f.dx - 12, f.dy - 4), Offset(f.dx + 12, f.dy - 4), p..strokeWidth = 3);
      p.strokeWidth = 4;
    }
  }

  void _poles(Canvas c) {
    final g = geo;
    for (final x in [M4DpDressGeo.lp, M4DpDressGeo.rp]) {
      final r = Rect.fromLTRB(x - 6, g.topY, x + 6, g.groundY + 4);
      c.drawRect(r, Paint()..shader = const LinearGradient(colors: [Color(0xFF8C939A), Color(0xFFC9CED2), Color(0xFF7A8187)]).createShader(r));
    }
    // The top cross-arm (a steel channel across both poles).
    _channel(c, Offset(M4DpDressGeo.lp - 24, g.armY), Offset(M4DpDressGeo.rp + 24, g.armY));
    // The platform channel under the transformer.
    _channel(c, Offset(M4DpDressGeo.lp - 10, g.platformY), Offset(M4DpDressGeo.rp + 10, g.platformY));
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

  void _insulator(Canvas c, Offset base, {double angle = 0}) {
    c.save();
    c.translate(base.dx, base.dy);
    c.rotate(angle);
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

  void _line(Canvas c) {
    final g = geo;
    final wire = Paint()
      ..color = _wire
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    for (final (i, top) in g.insulatorTops.indexed) {
      _insulator(c, Offset(top.dx, g.armY - 4));
      // The spans to the far poles (a little sag).
      final fl = g.farLeft.translate(-8 + i * 8.0, 0);
      final fr = g.farRight.translate(-8 + i * 8.0, 0);
      c.drawPath(Path()
        ..moveTo(top.dx, top.dy)
        ..quadraticBezierTo((top.dx + fl.dx) / 2, top.dy + 16, fl.dx, fl.dy), wire);
      c.drawPath(Path()
        ..moveTo(top.dx, top.dy)
        ..quadraticBezierTo((top.dx + fr.dx) / 2, top.dy + 16, fr.dx, fr.dy), wire);
      // The binding at the insulator top.
      final bind = Paint()
        ..color = const Color(0xFFB8BEC3)
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke;
      c.drawOval(Rect.fromCenter(center: top, width: 10, height: 5), bind);
      if (i == 1 && _bad(M4DpDressSlot.tail)) {
        // A long binding-wire tail sticking out into the air.
        c.drawPath(
            Path()
              ..moveTo(top.dx + 4, top.dy)
              ..cubicTo(top.dx + 14, top.dy - 16, top.dx + 2, top.dy - 20, top.dx + 18, top.dy - 30),
            bind..strokeWidth = 1.8);
      }
    }
  }

  void _jumpers(Canvas c) {
    final g = geo;
    final jp = Paint()
      ..color = const Color(0xFF2F353A)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 3; i++) {
      final a = g.insulatorTops[i].translate(i == 1 ? 0 : (i == 0 ? -4 : 4), 2);
      final b = _fuseTop(i);
      final path = Path()..moveTo(a.dx, a.dy);
      if (i == 0 && _bad(M4DpDressSlot.tangle)) {
        // Tangled: loops and kinks.
        final mid = Offset(a.dx - 12, (a.dy + b.dy) / 2);
        path
          ..cubicTo(a.dx - 22, a.dy + 10, a.dx + 14, mid.dy - 18, mid.dx, mid.dy - 6)
          ..cubicTo(mid.dx - 18, mid.dy + 4, mid.dx + 10, mid.dy + 18, mid.dx + 4, mid.dy + 6)
          ..cubicTo(mid.dx - 6, mid.dy - 4, mid.dx - 20, mid.dy + 22, b.dx, b.dy);
      } else if (i == 2 && _bad(M4DpDressSlot.clearance)) {
        // Bowed out onto the right pole: no clearance from the body.
        path.cubicTo(a.dx + 30, a.dy + 6, M4DpDressGeo.rp + 4, (a.dy + b.dy) / 2, b.dx, b.dy);
      } else {
        // A smooth, even "C" curve.
        final side = i == 0 ? -1.0 : (i == 2 ? 1.0 : -0.6);
        path.cubicTo(a.dx + 14 * side, a.dy + 12, b.dx + 14 * side, b.dy - 18, b.dx, b.dy);
      }
      c.drawPath(path, jp);
    }
  }

  Offset _fuseTop(int i) {
    final g = geo;
    final tilt = _bad(M4DpDressSlot.tilt) ? (i / 2 - 0.5) * 18 : 0.0;
    return Offset(M4DpDressGeo.phaseX[i], g.doArmY - 4 + tilt);
  }

  void _doArm(Canvas c) {
    final g = geo;
    final tilt = _bad(M4DpDressSlot.tilt) ? 9.0 : 0.0;
    _channel(c, Offset(M4DpDressGeo.lp - 18, g.doArmY - tilt * 1.4), Offset(M4DpDressGeo.rp + 18, g.doArmY + tilt * 1.4));
    final lead = Paint()
      ..color = const Color(0xFF2F353A)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 3; i++) {
      final t = _fuseTop(i);
      final ang = _bad(M4DpDressSlot.tilt) ? 0.2 : 0.0;
      // The DO fuse: an insulator and the fuse tube under it.
      c.save();
      c.translate(t.dx, t.dy + 4);
      c.rotate(ang);
      c.drawRect(const Rect.fromLTWH(-3, 0, 6, 26), Paint()..color = const Color(0xFF7B5A3A));
      c.drawRect(const Rect.fromLTWH(-4, -2, 8, 4), Paint()..color = _steel);
      c.drawRect(const Rect.fromLTWH(-4, 24, 8, 4), Paint()..color = _steel);
      c.restore();
      // The lead on to the HT bushing.
      final from = Offset(t.dx, t.dy + 32);
      final to = g.htBushings[i].translate(0, -6);
      c.drawPath(Path()
        ..moveTo(from.dx, from.dy)
        ..cubicTo(from.dx, from.dy + 20, to.dx, to.dy - 20, to.dx, to.dy), lead);
    }
  }

  void _transformer(Canvas c) {
    final g = geo;
    final t = g.tank;
    final body = RRect.fromRectAndRadius(t, const Radius.circular(4));
    c.drawRRect(body.shift(const Offset(3, 3)), Paint()..color = const Color(0x44000000));
    c.drawRRect(body, Paint()..shader = const LinearGradient(colors: [Color(0xFF6E7F72), Color(0xFF9DB0A1), Color(0xFF627266)]).createShader(t));
    // Cooling fins.
    final fin = Paint()
      ..color = const Color(0x55313D33)
      ..strokeWidth = 2;
    for (var x = t.left + 8; x < t.right - 4; x += 8) {
      c.drawLine(Offset(x, t.top + 10), Offset(x, t.bottom - 6), fin);
    }
    // The conservator on top.
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(t.left + 6, t.top - 22, 26, 12), const Radius.circular(6)), Paint()..color = const Color(0xFF7E8F82));
    for (final b in g.htBushings) {
      _insulator(c, b.translate(0, 12));
    }
    // The LT bushings on the right side and the lug.
    final lt = Paint()..color = const Color(0xFF5B4632);
    for (var k = 0; k < 3; k++) {
      c.drawRect(Rect.fromLTWH(t.right - 2, t.top + 12 + k * 10, 8, 5), lt);
    }
    final lug = g.ltLug;
    if (_bad(M4DpDressSlot.loose)) {
      // The lug hangs at an angle, its nut backed off the stud.
      c.save();
      c.translate(lug.dx, lug.dy);
      c.rotate(0.6);
      c.drawRect(const Rect.fromLTWH(-2, -3, 14, 6), Paint()..color = const Color(0xFFC18A3A));
      c.restore();
      c.drawRect(Rect.fromLTWH(lug.dx + 8, lug.dy - 10, 6, 6), Paint()..color = _steel);
    } else {
      c.drawRect(Rect.fromLTWH(lug.dx - 2, lug.dy - 3, 14, 6), Paint()..color = const Color(0xFFC18A3A));
      c.drawRect(Rect.fromLTWH(lug.dx - 3, lug.dy - 4, 6, 8), Paint()..color = _steel);
    }
  }

  void _ltCables(Canvas c) {
    final g = geo;
    final cable = Paint()
      ..color = const Color(0xFF1A1C1E)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final box = g.ltBox;
    c.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(3)), Paint()..color = const Color(0xFF8A939A));
    c.drawRRect(
        RRect.fromRectAndRadius(box, const Radius.circular(3)),
        Paint()
          ..color = const Color(0xFF4E565D)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4);
    final from = Offset(g.tank.right + 10, g.tank.top + 22);
    final down = Offset(M4DpDressGeo.rp + 10, box.top);
    if (_bad(M4DpDressSlot.ltCable)) {
      // Loose loops hanging off the platform, crossing each other.
      for (var k = 0; k < 3; k++) {
        final o = k * 5.0;
        c.drawPath(
            Path()
              ..moveTo(from.dx, from.dy + o)
              ..cubicTo(from.dx + 40 + o * 2, from.dy + 50, down.dx - 34 + o * 3, down.dy - 40 - o * 4, down.dx - 4 + o, down.dy),
            cable);
      }
    } else {
      // Bunched together and clamped down the pole.
      for (var k = 0; k < 3; k++) {
        final o = k * 2.4;
        c.drawPath(
            Path()
              ..moveTo(from.dx, from.dy + o)
              ..quadraticBezierTo(down.dx + o, from.dy + o, down.dx + o - 2, from.dy + 26)
              ..lineTo(down.dx + o - 2, down.dy),
            cable..strokeWidth = 2.6);
      }
      final clamp = Paint()..color = const Color(0xFFD9DDE0);
      for (var y = from.dy + 40; y < down.dy - 6; y += 26) {
        c.drawRect(Rect.fromLTWH(M4DpDressGeo.rp + 4, y, 14, 4), clamp);
      }
    }
  }

  void _earth(Canvas c, bool left) {
    final g = geo;
    final spike = left ? g.spikeL : g.spikeR;
    // The spike, always there.
    c.drawLine(spike, spike.translate(0, 10), Paint()
      ..color = const Color(0xFF5A6066)
      ..strokeWidth = 4);
    c.drawCircle(spike, 4, Paint()..color = const Color(0xFF8C939A));
    final on = left ? rig.earthL : rig.earthR;
    final copper = Paint()
      ..color = const Color(0xFFC87533)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    if (on) {
      final clamp = left ? g.earthClampL : g.earthClampR;
      // The shorting bar across the three conductors, its lead to the spike.
      c.drawLine(clamp.translate(-6, -6), clamp.translate(6, 14), Paint()
        ..color = const Color(0xFF3A3F45)
        ..strokeWidth = 3.4);
      c.drawPath(
          Path()
            ..moveTo(clamp.dx, clamp.dy + 10)
            ..quadraticBezierTo(clamp.dx + (left ? 14 : -14), (clamp.dy + spike.dy) / 2, spike.dx, spike.dy),
          copper);
      c.drawCircle(spike, 5, Paint()..color = const Color(0xFFC87533));
    } else {
      // The earth set coiled on the ground by the spike.
      c.drawOval(Rect.fromCenter(center: spike.translate(left ? 14 : -14, 2), width: 22, height: 8), copper);
      c.drawOval(Rect.fromCenter(center: spike.translate(left ? 14 : -14, 1), width: 16, height: 6), copper);
    }
  }

  @override
  bool shouldRepaint(M4DpDressPainter old) => old.geo != geo || old.rig != rig || old.seed != seed;
}

/// His pole strap (the harness lanyard round the pole) while he is aloft.
class M4DpDressStrapPainter extends CustomPainter {
  const M4DpDressStrapPainter({required this.box});
  final Rect box;

  @override
  void paint(Canvas c, Size size) {
    final hip = Offset(box.left + box.width * 0.55, box.top + box.height * 0.52);
    const px = M4DpDressGeo.lp;
    final strap = Paint()
      ..color = const Color(0xFF3A2A16)
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke;
    c.drawPath(
        Path()
          ..moveTo(hip.dx, hip.dy)
          ..quadraticBezierTo(px, hip.dy - 10, px + 9, hip.dy - 6)
          ..moveTo(hip.dx, hip.dy + 2)
          ..quadraticBezierTo(px, hip.dy + 4, px + 9, hip.dy - 6),
        strap);
    // The step bolt under his boots.
    c.drawRect(Rect.fromLTRB(box.left + box.width * 0.3, box.bottom - 3, px, box.bottom + 0.4), Paint()..color = const Color(0xFF5A6066));
  }

  @override
  bool shouldRepaint(M4DpDressStrapPainter old) => old.box != box;
}

/// The flash on the line by his hands (a deadly move), [v] 0 → 1.
class M4DpDressFlashPainter extends CustomPainter {
  const M4DpDressFlashPainter({required this.geo, required this.v});
  final M4DpDressGeo geo;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final at = geo.flashAt;
    final flick = v < 0.5 ? (0.65 + 0.35 * math.sin(v * 60).abs()) : (1 - (v - 0.5) * 1.2).clamp(0.4, 1.0);
    final r = 26 + 70 * Curves.easeOut.transform(v.clamp(0.0, 1.0));
    c.drawCircle(
        at,
        r,
        Paint()
          ..shader = RadialGradient(colors: [Color.fromRGBO(255, 250, 220, 0.95 * flick), Color.fromRGBO(140, 170, 255, 0.5 * flick), const Color(0x00FFC24A)])
              .createShader(Rect.fromCircle(center: at, radius: r)));
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
  bool shouldRepaint(M4DpDressFlashPainter old) => old.v != v || old.geo != geo;
}
