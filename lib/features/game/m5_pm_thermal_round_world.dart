import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The drawn world of lesson 5.10 কাজ "লুকানো গরম: PM রাউন্ড"
// (m5_pm_thermal_round.dart): a roadside DP (double pole) transformer
// structure on a PM morning, seen from the front. The 11 kV line comes over
// the top cross-arm's three pin insulators; jumpers drop to the DO set on the
// DO cross-arm; leads go on to the transformer's HT bushings; the LT side has
// three bushing lugs and the cables run down the right pole to the LT box. An
// earth set can hang on each side span. The PM van stands at the far right
// (the schedule card on its windscreen, the logbook on its bonnet), the crew
// mate under the platform, the trainee by the van with the thermal camera.
//
// Six places carry three phase joints each (R, Y, B): the jumper clamps on
// the line insulators, the DO top and bottom contacts, the HT bushing
// connectors, the LT bushing lugs and the LT box lugs. In daylight every
// joint looks the same; only the thermal camera's small window shows how warm
// each one is (M5-15: judged against the same joint on the other two phases).
// Code-drawn, gradients, no bitmaps, no text in the art.
//
// Design: 360 wide × the scene's height; the ground follows the bottom of the
// screen (a tall phone gets a taller structure and more sky, never stretched).

/// The six places with three phase joints each.
enum M5PmPlace { lineClamp, doTop, doBottom, htBushing, ltLug, ltBox }

/// The hardware nuts that can be checked with the torque wrench.
enum M5PmNut { armL, armR, doArmL, doArmR, platL, platR }

/// One joint: a place and its phase (0 = R, 1 = Y, 2 = B).
typedef M5PmJoint = ({M5PmPlace place, int phase});

/// Every joint on the structure (6 places × 3 phases).
final List<M5PmJoint> m5PmAllJoints = [
  for (final p in M5PmPlace.values)
    for (var i = 0; i < 3; i++) (place: p, phase: i),
];

/// Where things are (design px, 360 wide).
@immutable
class M5PmGeo {
  const M5PmGeo._(this.height, this.groundY, this.topY);

  factory M5PmGeo.forScene(double height, double inset) {
    final g = height - floorUp - inset * 0.5;
    return M5PmGeo._(height, g, math.max(150.0, g - 470));
  }

  final double height;

  /// The ground line at the poles' feet.
  final double groundY;

  /// The top of the poles.
  final double topY;

  /// The ground sits this far above the bottom (the tool row stands on it).
  static const double floorUp = 112;

  /// The two poles' axes.
  static const double lp = 94;
  static const double rp = 266;

  /// The three phases across the structure.
  static const List<double> phaseX = [132, 180, 228];

  /// A joint counts as "under the crosshair" this close (design px).
  static const double jointHit = 11;

  /// A torque-wrench target is grabbed this close (design px).
  static const double targetHit = 18;

  /// The thermal camera's window.
  static const Size finder = Size(88, 72);

  double get h => groundY - topY;
  double y(double f) => topY + f * h;

  double get armY => y(0.06);
  double get doY => y(0.22);
  double get doArmY => doY + 13;
  Rect get tank {
    final top = y(0.45);
    return Rect.fromLTRB(146, top, 214, top + math.max(72.0, h * 0.2));
  }

  double get platformY => tank.bottom + 4;
  Rect get ltBoxRect => Rect.fromLTWH(234, y(0.86), 70, 30);

  Offset get farLeft => Offset(10, armY + 26);
  Offset get farRight => Offset(350, armY + 26);
  Offset get earthClampL => Offset(46, armY + 6);
  Offset get earthClampR => Offset(316, armY + 6);
  Offset get spikeL => Offset(36, groundY - 4);
  Offset get spikeR => Offset(326, groundY - 4);

  /// The oil gauge glass on the conservator.
  Rect get gauge => Rect.fromLTWH(tank.left + 30, tank.top - 21, 7, 10);

  /// A joint's centre.
  Offset joint(M5PmJoint j) {
    final i = j.phase;
    return switch (j.place) {
      M5PmPlace.lineClamp => Offset(phaseX[i], armY - 18),
      M5PmPlace.doTop => Offset(phaseX[i], doY),
      M5PmPlace.doBottom => Offset(phaseX[i], doY + 26),
      M5PmPlace.htBushing => Offset(156.0 + 24 * i, tank.top - 12),
      M5PmPlace.ltLug => Offset(tank.right + 8, tank.top + 12 + 24.0 * i),
      M5PmPlace.ltBox => Offset(248.0 + 22 * i, ltBoxRect.center.dy),
    };
  }

  /// A hardware nut's centre.
  Offset nut(M5PmNut n) => switch (n) {
        M5PmNut.armL => Offset(lp, armY + 12),
        M5PmNut.armR => Offset(rp, armY + 12),
        M5PmNut.doArmL => Offset(lp, doArmY),
        M5PmNut.doArmR => Offset(rp, doArmY),
        M5PmNut.platL => Offset(lp, platformY),
        M5PmNut.platR => Offset(rp, platformY),
      };

  /// The joint under [p] (within [jointHit]), or null.
  M5PmJoint? jointAt(Offset p, {double within = jointHit}) {
    M5PmJoint? best;
    var bestD = within;
    for (final j in m5PmAllJoints) {
      final d = (joint(j) - p).distance;
      if (d <= bestD) {
        bestD = d;
        best = j;
      }
    }
    return best;
  }

  /// Where the thermal camera's window starts (the empty sky to the right).
  Offset get finderHome => Offset(312, y(0.15));

  /// The window's rect around its centre [c].
  static Rect finderRect(Offset c) => Rect.fromCenter(center: c, width: finder.width, height: finder.height);

  /// Keeps the window's centre on the scene.
  Offset clampFinder(Offset c) => Offset(
        c.dx.clamp(finder.width / 2 - 20, 360 - finder.width / 2 + 20),
        c.dy.clamp(120 + finder.height / 2 - 30, groundY + 10),
      );

  /// Where the trainee stands on the ground (right, by the van), and where he
  /// works aloft (on the left pole, strapped on, by the DO set).
  Rect get ground => Rect.fromLTWH(282, groundY - 108, 54, 108);
  Rect get aloft => Rect.fromLTWH(lp - 52, y(0.12), 50, 100);

  /// The crew mate (under the platform).
  Rect get mate {
    final hh = math.min(100.0, groundY - platformY - 10);
    return Rect.fromLTWH(156, groundY - hh, hh * 0.5, hh);
  }

  /// The PM van (midground, far right) and the schedule card on its glass.
  Rect get van => Rect.fromLTWH(296, groundY - 46, 74, 40);
  Rect get scheduleCard => Rect.fromLTWH(van.left + 6, van.top + 6, 30, 12);

  /// The empty sky band (the camera's gesture hint drags across it).
  Rect get skyBand => Rect.fromLTRB(250, 124, 356, math.max(160.0, armY - 30));

  @override
  bool operator ==(Object other) => other is M5PmGeo && other.height == height && other.groundY == groundY && other.topY == topY;

  @override
  int get hashCode => Object.hash(height, groundY, topY);
}

/// What the structure shows now.
@immutable
class M5PmRig {
  const M5PmRig({
    required this.earthOn,
    required this.snapped,
    required this.light,
    required this.oil,
  });

  /// Both earth sets hang on the side spans.
  final bool earthOn;

  /// The joints the trainee has photographed (a small pin each).
  final Set<M5PmJoint> snapped;

  /// The morning's light (0 clear, 1 hazy, 2 overcast).
  final int light;

  /// Today's oil colour in the gauge glass.
  final Color oil;

  @override
  bool operator ==(Object other) =>
      other is M5PmRig &&
      other.earthOn == earthOn &&
      setEquals(other.snapped, snapped) &&
      other.light == light &&
      other.oil == oil;

  @override
  int get hashCode => Object.hash(earthOn, Object.hashAllUnordered(snapped), light, oil);
}

const _steel = Color(0xFF6F7880);
const _wire = Color(0xFF3C4248);
const _porcelain = Color(0xFFE9EDF0);

/// The oil colours in the gauge glass: clear amber, a deeper amber, darkened.
const m5PmOils = [Color(0xFFE0B04A), Color(0xFFC08A32), Color(0xFF5E3212)];

class M5PmPainter extends CustomPainter {
  const M5PmPainter({required this.geo, required this.rig, required this.seed});

  final M5PmGeo geo;
  final M5PmRig rig;
  final int seed;

  static const _skies = [
    [Color(0xFF3F79B8), Color(0xFF9CC6E6), Color(0xFFE6EED8)],
    [Color(0xFF7D97B3), Color(0xFFC3D2DE), Color(0xFFEDE6D2)],
    [Color(0xFF6E7884), Color(0xFFA9B1B9), Color(0xFFD6D8D2)],
  ];

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    final sky = Rect.fromLTWH(0, 0, w, g.groundY);
    c.drawRect(
        sky,
        Paint()
          ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: _skies[rig.light.clamp(0, 2)])
              .createShader(sky));
    final rnd = math.Random(seed);
    final cloud = Paint()..color = Color(rig.light == 2 ? 0xBBE4E7EA : 0xCCFFFFFF);
    for (var i = 0; i < 3 + rig.light; i++) {
      final cx = 30 + rnd.nextDouble() * 300;
      final cy = 70 + rnd.nextDouble() * (g.topY - 30).clamp(20.0, 200.0);
      for (var k = 0; k < 4; k++) {
        c.drawOval(Rect.fromCenter(center: Offset(cx + k * 14 - 20, cy - (k.isOdd ? 6 : 0)), width: 34, height: 18), cloud);
      }
    }
    // Far tree line and roofs, then the roadside verge.
    final horizon = g.groundY - g.h * 0.2;
    final tree = Paint()..color = const Color(0xFF4F7F45);
    for (var x = -10.0; x < w + 20; x += 20 + rnd.nextDouble() * 16) {
      final r = 9 + rnd.nextDouble() * 9;
      c.drawCircle(Offset(x, horizon - r * 0.5), r, tree);
    }
    for (var i = 0; i < 3; i++) {
      final x = 30 + i * 110 + rnd.nextDouble() * 30;
      c.drawPath(
          Path()
            ..moveTo(x, horizon)
            ..lineTo(x + 14, horizon - 14)
            ..lineTo(x + 28, horizon)
            ..close(),
          Paint()..color = const Color(0xFF8D5A3A));
    }
    c.drawRect(Rect.fromLTRB(0, horizon, w, g.groundY), Paint()..color = const Color(0xFF93B062));
    // The road along the bottom.
    final floor = Rect.fromLTRB(0, g.groundY, w, size.height);
    c.drawRect(floor, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFA88B62), Color(0xFF6E5A40)]).createShader(floor));
    final road = Rect.fromLTRB(0, g.groundY + 34, w, size.height);
    c.drawRect(road, Paint()..color = const Color(0xFF4A4D52));
    final dash = Paint()
      ..color = const Color(0xCCF2F2F2)
      ..strokeWidth = 3;
    for (var x = 8.0; x < w; x += 46) {
      c.drawLine(Offset(x, road.top + 30), Offset(x + 22, road.top + 30), dash);
    }

    _farPoles(c);
    _van(c);
    _poles(c);
    _line(c);
    _jumpers(c);
    _doSet(c);
    _transformer(c);
    _ltSide(c);
    _earth(c, true);
    _earth(c, false);
    _pins(c);
  }

  void _farPoles(Canvas c) {
    final g = geo;
    final p = Paint()
      ..color = const Color(0xFF8E959B)
      ..strokeWidth = 4;
    for (final f in [g.farLeft, g.farRight]) {
      c.drawLine(Offset(f.dx, f.dy - 8), Offset(f.dx, g.groundY - g.h * 0.2 + 4), p);
      c.drawLine(Offset(f.dx - 10, f.dy - 4), Offset(f.dx + 10, f.dy - 4), p..strokeWidth = 3);
      p.strokeWidth = 4;
    }
  }

  void _van(Canvas c) {
    final v = geo.van;
    final body = RRect.fromRectAndCorners(v, topLeft: const Radius.circular(8), topRight: const Radius.circular(3));
    c.drawRRect(body.shift(const Offset(2, 3)), Paint()..color = const Color(0x33000000));
    c.drawRRect(body, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF2F4F6), Color(0xFFC9CED3)]).createShader(v));
    // Windscreen (the schedule card is a widget label on it), the stripe.
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(v.left + 4, v.top + 4, 34, 16), const Radius.circular(3)), Paint()..color = const Color(0xFF6B8DAA));
    c.drawRect(Rect.fromLTWH(v.left, v.top + 24, v.width, 4), Paint()..color = const Color(0xFF1F5F8F));
    // The logbook on the bonnet (a blue cover).
    c.drawRect(Rect.fromLTWH(v.left - 10, v.top + 14, 14, 4), Paint()..color = const Color(0xFF243F7A));
    for (final x in [v.left + 12, v.right - 14]) {
      c.drawCircle(Offset(x, v.bottom), 7, Paint()..color = const Color(0xFF22252A));
      c.drawCircle(Offset(x, v.bottom), 3, Paint()..color = const Color(0xFF9AA2A8));
    }
  }

  void _poles(Canvas c) {
    final g = geo;
    for (final x in [M5PmGeo.lp, M5PmGeo.rp]) {
      final r = Rect.fromLTRB(x - 6, g.topY, x + 6, g.groundY + 4);
      c.drawRect(r, Paint()..shader = const LinearGradient(colors: [Color(0xFF8C939A), Color(0xFFC9CED2), Color(0xFF7A8187)]).createShader(r));
    }
    _channel(c, Offset(M5PmGeo.lp - 22, g.armY), Offset(M5PmGeo.rp + 22, g.armY));
    _channel(c, Offset(M5PmGeo.lp - 12, g.doArmY), Offset(M5PmGeo.rp + 12, g.doArmY));
    _channel(c, Offset(M5PmGeo.lp - 10, g.platformY), Offset(M5PmGeo.rp + 10, g.platformY));
    // The hardware nuts (all alike).
    for (final n in M5PmNut.values) {
      m5PmDrawNut(c, g.nut(n), 6);
    }
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

  void _insulator(Canvas c, Offset base) {
    final body = Paint()..color = _porcelain;
    final rim = Paint()
      ..color = const Color(0xFF9AA3AA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final r = Rect.fromCenter(center: base.translate(0, -4 - i * 5.0), width: 16 - i * 2.5, height: 5);
      c.drawOval(r, body);
      c.drawOval(r, rim);
    }
  }

  void _clampAt(Canvas c, Offset p) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: p, width: 9, height: 6), const Radius.circular(2)), Paint()..color = const Color(0xFFB8BEC3));
    c.drawCircle(p, 1.6, Paint()..color = _steel);
  }

  void _line(Canvas c) {
    final g = geo;
    final wire = Paint()
      ..color = _wire
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 3; i++) {
      final top = g.joint((place: M5PmPlace.lineClamp, phase: i));
      _insulator(c, Offset(top.dx, g.armY - 4));
      final fl = g.farLeft.translate(-8 + i * 8.0, 0);
      final fr = g.farRight.translate(-8 + i * 8.0, 0);
      c.drawPath(Path()
        ..moveTo(top.dx, top.dy)
        ..quadraticBezierTo((top.dx + fl.dx) / 2, top.dy + 16, fl.dx, fl.dy), wire);
      c.drawPath(Path()
        ..moveTo(top.dx, top.dy)
        ..quadraticBezierTo((top.dx + fr.dx) / 2, top.dy + 16, fr.dx, fr.dy), wire);
      _clampAt(c, top);
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
      final a = g.joint((place: M5PmPlace.lineClamp, phase: i)).translate(0, 3);
      final b = g.joint((place: M5PmPlace.doTop, phase: i)).translate(0, -3);
      final side = i == 0 ? -1.0 : (i == 2 ? 1.0 : -0.6);
      c.drawPath(
          Path()
            ..moveTo(a.dx, a.dy)
            ..cubicTo(a.dx + 14 * side, a.dy + 12, b.dx + 14 * side, b.dy - 16, b.dx, b.dy),
          jp);
    }
  }

  void _doSet(Canvas c) {
    final g = geo;
    final lead = Paint()
      ..color = const Color(0xFF2F353A)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 3; i++) {
      final t = g.joint((place: M5PmPlace.doTop, phase: i));
      final b = g.joint((place: M5PmPlace.doBottom, phase: i));
      // The DO fuse tube between its contacts.
      c.drawRect(Rect.fromLTRB(t.dx - 3, t.dy + 3, t.dx + 3, b.dy - 3), Paint()..color = const Color(0xFF7B5A3A));
      c.drawRect(Rect.fromCenter(center: t, width: 10, height: 5), Paint()..color = _steel);
      c.drawRect(Rect.fromCenter(center: b, width: 10, height: 5), Paint()..color = _steel);
      final to = g.joint((place: M5PmPlace.htBushing, phase: i)).translate(0, -4);
      c.drawPath(Path()
        ..moveTo(b.dx, b.dy + 3)
        ..cubicTo(b.dx, b.dy + 24, to.dx, to.dy - 24, to.dx, to.dy), lead);
    }
  }

  void _transformer(Canvas c) {
    final g = geo;
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
    // The conservator with its oil gauge glass.
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(t.left + 4, t.top - 24, 40, 14), const Radius.circular(7)), Paint()..color = const Color(0xFF7E8F82));
    final gg = g.gauge;
    c.drawRect(gg.inflate(1.5), Paint()..color = const Color(0xFF2E3530));
    c.drawRect(gg, Paint()..color = rig.oil);
    for (var i = 0; i < 3; i++) {
      final b = g.joint((place: M5PmPlace.htBushing, phase: i));
      _insulator(c, b.translate(0, 12));
      _clampAt(c, b);
    }
  }

  void _ltSide(Canvas c) {
    final g = geo;
    final t = g.tank;
    final cable = Paint()
      ..color = const Color(0xFF1A1C1E)
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final box = g.ltBoxRect;
    c.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(3)), Paint()..color = const Color(0xFF8A939A));
    c.drawRRect(
        RRect.fromRectAndRadius(box, const Radius.circular(3)),
        Paint()
          ..color = const Color(0xFF4E565D)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4);
    for (var i = 0; i < 3; i++) {
      final lug = g.joint((place: M5PmPlace.ltLug, phase: i));
      final dest = g.joint((place: M5PmPlace.ltBox, phase: i));
      c.drawRect(Rect.fromLTWH(t.right - 2, lug.dy - 3, 6, 6), Paint()..color = const Color(0xFF5B4632));
      // The cable: out to the right pole, clamped down to the box.
      c.drawPath(
          Path()
            ..moveTo(lug.dx + 4, lug.dy)
            ..quadraticBezierTo(M5PmGeo.rp - 10 + i * 3, lug.dy, M5PmGeo.rp - 10 + i * 3, lug.dy + 18)
            ..lineTo(M5PmGeo.rp - 10 + i * 3, box.top - 6)
            ..quadraticBezierTo(M5PmGeo.rp - 10 + i * 3, box.top, dest.dx, dest.dy - 6),
          cable);
      c.drawRect(Rect.fromCenter(center: lug, width: 10, height: 6), Paint()..color = const Color(0xFFC18A3A));
      c.drawCircle(lug, 2, Paint()..color = _steel);
      c.drawRect(Rect.fromCenter(center: dest, width: 9, height: 7), Paint()..color = const Color(0xFFC18A3A));
      c.drawCircle(dest, 2, Paint()..color = _steel);
    }
    final clamp = Paint()..color = const Color(0xFFD9DDE0);
    for (var y = t.top + 40; y < box.top - 10; y += 30) {
      c.drawRect(Rect.fromLTWH(M5PmGeo.rp - 14, y, 14, 4), clamp);
    }
  }

  void _earth(Canvas c, bool left) {
    final g = geo;
    final spike = left ? g.spikeL : g.spikeR;
    c.drawLine(spike, spike.translate(0, 10), Paint()
      ..color = const Color(0xFF5A6066)
      ..strokeWidth = 4);
    c.drawCircle(spike, 4, Paint()..color = const Color(0xFF8C939A));
    final copper = Paint()
      ..color = const Color(0xFFC87533)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    if (rig.earthOn) {
      final clamp = left ? g.earthClampL : g.earthClampR;
      c.drawLine(clamp.translate(-6, -6), clamp.translate(6, 14), Paint()
        ..color = const Color(0xFF3A3F45)
        ..strokeWidth = 3.4);
      c.drawPath(
          Path()
            ..moveTo(clamp.dx, clamp.dy + 10)
            ..quadraticBezierTo(clamp.dx + (left ? 12 : -12), (clamp.dy + spike.dy) / 2, spike.dx, spike.dy),
          copper);
      c.drawCircle(spike, 5, Paint()..color = const Color(0xFFC87533));
    } else {
      c.drawOval(Rect.fromCenter(center: spike.translate(left ? 14 : -14, 2), width: 22, height: 8), copper);
      c.drawOval(Rect.fromCenter(center: spike.translate(left ? 14 : -14, 1), width: 16, height: 6), copper);
    }
  }

  /// A small camera pin by each joint the trainee photographed.
  void _pins(Canvas c) {
    for (final j in rig.snapped) {
      final p = geo.joint(j).translate(9, -10);
      c.drawCircle(p, 5.5, Paint()..color = const Color(0xFF1C2E4A));
      c.drawCircle(p, 5.5, Paint()
        ..color = const Color(0xFFFFE08A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4);
      c.drawCircle(p, 2, Paint()..color = const Color(0xFFFFE08A));
    }
  }

  @override
  bool shouldRepaint(M5PmPainter old) => old.geo != geo || old.rig != rig || old.seed != seed;
}

/// A hex nut at [c] (radius [r]), turned by [angle].
void m5PmDrawNut(Canvas c, Offset at, double r, {double angle = 0}) {
  final path = Path();
  for (var k = 0; k < 6; k++) {
    final a = angle + k * math.pi / 3;
    final p = at + Offset(math.cos(a), math.sin(a)) * r;
    if (k == 0) {
      path.moveTo(p.dx, p.dy);
    } else {
      path.lineTo(p.dx, p.dy);
    }
  }
  path.close();
  c.drawPath(path, Paint()..color = const Color(0xFF8C949B));
  c.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF3E454B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2);
  c.drawCircle(at, r * 0.42, Paint()..color = const Color(0xFF5A6168));
  // A mark on the nut's face, so a turn shows.
  final m = at + Offset(math.cos(angle), math.sin(angle)) * r * 0.7;
  c.drawLine(at, m, Paint()
    ..color = const Color(0xFFE9EDF0)
    ..strokeWidth = 1.4);
}

/// The thermal camera's window: inside it the structure in false colour, each
/// joint glowing by its temperature, a crosshair, the spot reading and the
/// hold ring. Repaints only when the window moves or the ring fills.
class M5PmFinderPainter extends CustomPainter {
  M5PmFinderPainter({
    required this.geo,
    required this.at,
    required this.ring,
    required this.temps,
    required this.cooled,
  }) : super(repaint: Listenable.merge([at, ring]));

  final M5PmGeo geo;
  final ValueListenable<Offset> at;
  final ValueListenable<double> ring;

  /// Each joint's temperature now (°C).
  final Map<M5PmJoint, int> temps;

  /// Joints already put right (they read like their neighbours again).
  final Map<M5PmJoint, int> cooled;

  int _temp(M5PmJoint j) => cooled[j] ?? temps[j] ?? 0;

  @override
  void paint(Canvas c, Size size) {
    final centre = at.value;
    final r = M5PmGeo.finderRect(centre);
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(10));
    c.drawRRect(rr.shift(const Offset(0, 3)), Paint()..color = const Color(0x55000000));
    c.save();
    c.clipRRect(rr);
    c.drawRect(r, Paint()..color = const Color(0xFF120A2E));
    final g = geo;
    final cold = Paint()
      ..color = const Color(0xFF3B2470)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    // Poles, arms and the tank in cool tones.
    for (final x in [M5PmGeo.lp, M5PmGeo.rp]) {
      c.drawLine(Offset(x, g.topY), Offset(x, g.groundY), cold..strokeWidth = 8);
    }
    cold.strokeWidth = 4;
    for (final y in [g.armY, g.doArmY, g.platformY]) {
      c.drawLine(Offset(M5PmGeo.lp - 22, y), Offset(M5PmGeo.rp + 22, y), cold);
    }
    c.drawRRect(RRect.fromRectAndRadius(g.tank, const Radius.circular(4)), Paint()..color = const Color(0xFF5A1F72));
    c.drawRect(g.ltBoxRect, Paint()..color = const Color(0xFF4A1E66));
    final wire = Paint()
      ..color = const Color(0xFF7A2A7E)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 3; i++) {
      final a = g.joint((place: M5PmPlace.lineClamp, phase: i));
      final b = g.joint((place: M5PmPlace.doTop, phase: i));
      final d = g.joint((place: M5PmPlace.doBottom, phase: i));
      final e = g.joint((place: M5PmPlace.htBushing, phase: i));
      c.drawLine(a, b, wire);
      c.drawLine(b, d, wire);
      c.drawLine(d, e, wire);
      final l = g.joint((place: M5PmPlace.ltLug, phase: i));
      final m = g.joint((place: M5PmPlace.ltBox, phase: i));
      c.drawLine(l, Offset(M5PmGeo.rp - 10 + i * 3, l.dy), wire);
      c.drawLine(Offset(M5PmGeo.rp - 10 + i * 3, l.dy), Offset(M5PmGeo.rp - 10 + i * 3, m.dy), wire);
    }
    // The joints, by temperature.
    for (final j in m5PmAllJoints) {
      final p = g.joint(j);
      if (!r.inflate(16).contains(p)) continue;
      final t = _temp(j);
      final heat = ((t - 25) / 50).clamp(0.0, 1.0);
      final colour = Color.lerp(const Color(0xFFB0306A), const Color(0xFFFFF4C2), heat)!;
      final glow = 7 + 12 * heat;
      c.drawCircle(
          p,
          glow,
          Paint()
            ..shader = RadialGradient(colors: [colour, colour.withValues(alpha: 0.35), colour.withValues(alpha: 0)])
                .createShader(Rect.fromCircle(center: p, radius: glow)));
      c.drawCircle(p, 3 + 2 * heat, Paint()..color = colour);
    }
    // The crosshair and the spot reading.
    final cross = Paint()
      ..color = const Color(0xE6FFFFFF)
      ..strokeWidth = 1.3;
    c.drawLine(centre.translate(-9, 0), centre.translate(-3, 0), cross);
    c.drawLine(centre.translate(3, 0), centre.translate(9, 0), cross);
    c.drawLine(centre.translate(0, -9), centre.translate(0, -3), cross);
    c.drawLine(centre.translate(0, 3), centre.translate(0, 9), cross);
    final under = g.jointAt(centre);
    final reading = under == null ? '-- °C' : '${_temp(under)} °C';
    final tp = TextPainter(
      text: TextSpan(text: reading, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white, height: 1)),
      textDirection: TextDirection.ltr,
    )..layout();
    final chip = Rect.fromLTWH(r.left + 4, r.bottom - tp.height - 8, tp.width + 8, tp.height + 4);
    c.drawRRect(RRect.fromRectAndRadius(chip, const Radius.circular(4)), Paint()..color = const Color(0xAA000000));
    tp.paint(c, Offset(chip.left + 4, chip.top + 2));
    // The hold ring (fills while the camera is held still on a joint).
    final v = ring.value;
    if (v > 0) {
      c.drawArc(
          Rect.fromCircle(center: centre, radius: 14),
          -math.pi / 2,
          math.pi * 2 * v.clamp(0.0, 1.0),
          false,
          Paint()
            ..color = const Color(0xFFFFE08A)
            ..strokeWidth = 2.6
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round);
    }
    c.restore();
    // The camera's frame.
    c.drawRRect(
        rr,
        Paint()
          ..color = const Color(0xFF1C2E4A)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(M5PmFinderPainter old) => old.geo != geo || old.temps != temps || !mapEquals(old.cooled, cooled);
}

/// The torque-wrench targets aloft: every target's nut drawn large, the one
/// being turned rotated by the wrench, the wrench's sweep as a ring.
class M5PmWrenchPainter extends CustomPainter {
  M5PmWrenchPainter({required this.targets, required this.done, required this.turn}) : super(repaint: turn);

  /// The targets' centres (design px).
  final List<Offset> targets;

  /// Which of [targets] are done (a green rim).
  final List<bool> done;

  /// (the target being turned, its nut angle, the wrench sweep 0..1).
  final ValueListenable<(int, double, double)> turn;

  @override
  void paint(Canvas c, Size size) {
    final (active, angle, sweep) = turn.value;
    for (final (i, p) in targets.indexed) {
      c.drawCircle(p, M5PmGeo.targetHit, Paint()..color = const Color(0x661C2E4A));
      m5PmDrawNut(c, p, 10, angle: i == active ? angle : 0);
      if (done[i]) {
        c.drawCircle(
            p,
            M5PmGeo.targetHit - 2,
            Paint()
              ..color = const Color(0xFF3CC47C)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.2);
      }
      if (i == active && sweep > 0) {
        c.drawArc(
            Rect.fromCircle(center: p, radius: M5PmGeo.targetHit + 3),
            -math.pi / 2,
            math.pi * 2 * sweep.clamp(0.0, 1.0),
            false,
            Paint()
              ..color = const Color(0xFFFFE08A)
              ..strokeWidth = 3
              ..style = PaintingStyle.stroke
              ..strokeCap = StrokeCap.round);
      }
    }
  }

  @override
  bool shouldRepaint(M5PmWrenchPainter old) => !listEquals(old.targets, targets) || !listEquals(old.done, done);
}

/// His pole strap while he is aloft.
class M5PmStrapPainter extends CustomPainter {
  const M5PmStrapPainter({required this.box});
  final Rect box;

  @override
  void paint(Canvas c, Size size) {
    final hip = Offset(box.left + box.width * 0.55, box.top + box.height * 0.52);
    const px = M5PmGeo.lp;
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
    c.drawRect(Rect.fromLTRB(box.left + box.width * 0.3, box.bottom - 3, px, box.bottom + 0.4), Paint()..color = const Color(0xFF5A6066));
  }

  @override
  bool shouldRepaint(M5PmStrapPainter old) => old.box != box;
}

/// The thermal camera in the trainee's hands (on the ground).
class M5PmCameraPainter extends CustomPainter {
  const M5PmCameraPainter({required this.box});
  final Rect box;

  @override
  void paint(Canvas c, Size size) {
    final at = Offset(box.left + box.width * 0.18, box.top + box.height * 0.42);
    final body = Rect.fromCenter(center: at, width: 16, height: 12);
    c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(3)), Paint()..color = const Color(0xFF2A2F36));
    c.drawRect(Rect.fromLTWH(body.left + 2, body.top + 2, 8, 6), Paint()..color = const Color(0xFFB0306A));
    c.drawRect(Rect.fromLTWH(body.left + 6, body.bottom, 4, 6), Paint()..color = const Color(0xFF2A2F36));
  }

  @override
  bool shouldRepaint(M5PmCameraPainter old) => old.box != box;
}

/// The flash at a joint by his hands (a deadly move), [v] 0 → 1.
class M5PmFlashPainter extends CustomPainter {
  const M5PmFlashPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas c, Size size) {
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
  bool shouldRepaint(M5PmFlashPainter old) => old.v != v || old.at != at;
}

/// The oil gauge glass as photographed (the logbook's "গত PM" / "আজ").
class M5PmGaugePhotoPainter extends CustomPainter {
  const M5PmGaugePhotoPainter({required this.oil});
  final Color oil;

  @override
  void paint(Canvas c, Size size) {
    final r = Offset.zero & size;
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(6)), Paint()..color = const Color(0xFF7E8F82));
    final glass = Rect.fromCenter(center: r.center, width: size.width * 0.34, height: size.height * 0.7);
    c.drawRect(glass.inflate(2), Paint()..color = const Color(0xFF2E3530));
    c.drawRect(glass, Paint()..color = oil);
    c.drawLine(glass.topLeft.translate(2, 3), glass.bottomLeft.translate(2, -3), Paint()
      ..color = const Color(0x55FFFFFF)
      ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(M5PmGaugePhotoPainter old) => old.oil != oil;
}
