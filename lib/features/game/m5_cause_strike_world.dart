import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The drawn world of lesson 5.8 কাজ 1 "লক্ষণ থেকে কারণ" (m5_cause_strike.dart):
// a DP (double pole) distribution transformer seen from the front, in the
// daytime, at one of three places (a field edge, a market, a school road).
// The 11 kV line comes over the top cross-arm, drops through the three DO
// fuses to the tank's HT bushings; the tank (conservator and oil gauge on its
// left, a weld seam on its right side, the lid gasket along its top, an old
// dent on its face — every tank has all three) stands on its platform between
// the poles; its three LT bushings (R, Y, B) sit along the bottom of its face,
// their cables run down the left pole to the LT box (an ON/OFF lever, three
// terminals) and on into the ground. Behind on the right stands the van; the
// suspects clipboard hangs on its door (a widget, not painted here).
//
// A leak case shows three oil stains under the platform (one fresh, two old
// and dry); once traced, the fresh streak shows from its source down to its
// stain. No text in the art except labels a worker reads (R/Y/B, ON/OFF,
// MIN). Code-drawn, gradients, no bitmaps.
//
// Design: 360 wide × the scene's height; the ground follows the bottom of the
// screen (a tall phone gets a taller structure and more sky, never stretched).

/// Where the patient stands.
enum M5Place { field, market, school }

/// Where the oil comes out (the lesson's three causes, 5.8 point 3).
enum M5LeakSource { gasket, weld, dent }

/// Where things are (design px, 360 wide).
@immutable
class M5CauseGeo {
  const M5CauseGeo._(this.height, this.groundY, this.topY);

  factory M5CauseGeo.forScene(double height, double inset) {
    final g = height - floorUp - inset * 0.5;
    return M5CauseGeo._(height, g, math.max(130.0, g - 460));
  }

  final double height;

  /// The ground line at the poles' feet.
  final double groundY;

  /// The top of the poles.
  final double topY;

  /// The ground sits this far above the bottom (the tool row stands on it).
  static const double floorUp = 112;

  /// The two poles' axes.
  static const double lp = 46;
  static const double rp = 192;

  /// The three phases (line insulators, DO fuses).
  static const List<double> phaseX = [74, 119, 164];

  /// The structure's height.
  double get h => groundY - topY;

  /// A height on the structure (0 = the pole tops, 1 = the ground).
  double y(double f) => topY + f * h;

  double get armY => y(0.03);
  double get doArmY => y(0.14);

  /// A DO fuse (hot stick target).
  Rect doHit(int i) => Rect.fromCenter(center: Offset(phaseX[i], doArmY + 18), width: 42, height: 50);

  /// The transformer tank on its platform.
  Rect get tank => Rect.fromLTRB(64, y(0.42), 174, y(0.60));
  double get platformY => y(0.62);
  List<Offset> get htBushings => [for (final x in [92.0, 119.0, 146.0]) Offset(x, tank.top - 10)];

  /// The conservator's oil gauge (tap to read).
  Offset get gauge => Offset(tank.left - 2, tank.top - 21);
  Rect get gaugeHit => Rect.fromCenter(center: gauge, width: 40, height: 40);

  /// The LT bushings R, Y, B along the bottom of the tank's face.
  Offset bushing(int i) => Offset(82 + 37.0 * i, tank.bottom - 14);
  Rect bushingHit(int i) => Rect.fromCenter(center: bushing(i), width: 36, height: 36);

  /// The LT box on the left pole (clear of the guide's bubble on the
  /// right), its lever on its right side and its three terminals.
  Rect get ltBox => Rect.fromLTWH(8, y(0.68), 96, 52);
  Offset terminal(int i) => Offset(ltBox.left + 16 + 32.0 * i, ltBox.top + 32);
  Rect terminalHit(int i) => Rect.fromCenter(center: terminal(i), width: 30, height: 34);
  Rect get leverHit => Rect.fromLTWH(ltBox.right + 4, ltBox.top, 34, 50);

  /// The outgoing LT cable under the box (the tong tester's place).
  Rect get cableHit => Rect.fromLTWH(ltBox.center.dx - 18, ltBox.bottom + 4, 36, groundY - ltBox.bottom - 10);

  /// The three oil stains under the platform (a leak case).
  Offset stain(int i) => Offset(const [104.0, 140.0, 176.0][i], groundY - 14);
  Rect stainHit(int i) => Rect.fromCenter(center: stain(i), width: 34, height: 30);

  /// Where each leak source is on the tank.
  Offset source(M5LeakSource s) => switch (s) {
        M5LeakSource.gasket => Offset(tank.left + 34, tank.top + 2),
        M5LeakSource.weld => Offset(tank.right - 5, tank.top + tank.height * 0.42),
        M5LeakSource.dent => Offset(tank.left + 62, tank.top + tank.height * 0.40),
      };

  /// The suspects clipboard on the van door.
  static const Rect clipboard = Rect.fromLTWH(204, 120, 150, 222);

  /// The reading card (the last test's picture).
  static const Rect card = Rect.fromLTWH(6, 122, 134, 90);

  /// Where the lineman stands (right of the structure, by the van).
  Rect get ground => Rect.fromLTWH(204, groundY - 104, 44, 104);

  /// A swipe up the structure starts here (the DO look).
  Offset get swipeFrom => Offset(119, y(0.52));

  @override
  bool operator ==(Object other) => other is M5CauseGeo && other.height == height && other.groundY == groundY && other.topY == topY;

  @override
  int get hashCode => Object.hash(height, groundY, topY);
}

/// What the structure shows now.
@immutable
class M5CauseRig {
  const M5CauseRig({
    required this.place,
    this.doOpen = const [false, false, false],
    this.ltOn = true,
    this.meter = const {},
    this.deadPhase = -1,
    this.leak = false,
    this.freshStain = 0,
    this.large = false,
    this.source = M5LeakSource.gasket,
    this.traced = false,
  });

  final M5Place place;
  final List<bool> doOpen;
  final bool ltOn;

  /// The phases the meter has read (their dials show), and the dead one.
  final Set<int> meter;
  final int deadPhase;

  /// A leak case: the stains (one fresh), how much, where from, traced yet.
  final bool leak;
  final int freshStain;
  final bool large;
  final M5LeakSource source;
  final bool traced;

  @override
  bool operator ==(Object other) =>
      other is M5CauseRig &&
      other.place == place &&
      listEquals(other.doOpen, doOpen) &&
      other.ltOn == ltOn &&
      setEquals(other.meter, meter) &&
      other.deadPhase == deadPhase &&
      other.leak == leak &&
      other.freshStain == freshStain &&
      other.large == large &&
      other.source == source &&
      other.traced == traced;

  @override
  int get hashCode => Object.hash(place, Object.hashAll(doOpen), ltOn, Object.hashAllUnordered(meter), deadPhase, leak, freshStain, large, source, traced);
}

const _steel = Color(0xFF6F7880);
const _wire = Color(0xFF3C4248);
const _porcelain = Color(0xFFE9EDF0);
const _oil = Color(0xFF2A1A08);

class M5CausePainter extends CustomPainter {
  const M5CausePainter({required this.geo, required this.rig, required this.seed});

  final M5CauseGeo geo;
  final M5CauseRig rig;
  final int seed;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    final rnd = math.Random(seed);
    // Sky.
    final sky = Rect.fromLTWH(0, 0, w, g.groundY);
    c.drawRect(
        sky,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4A86C4), Color(0xFFA5CDEB), Color(0xFFE6EFD9)],
          ).createShader(sky));
    final cloud = Paint()..color = const Color(0xCCFFFFFF);
    for (var i = 0; i < 3; i++) {
      final cx = 30 + rnd.nextDouble() * 170;
      final cy = 80 + rnd.nextDouble() * (g.topY - 50).clamp(20.0, 220.0);
      for (var k = 0; k < 4; k++) {
        c.drawOval(Rect.fromCenter(center: Offset(cx + k * 13 - 20, cy - (k.isOdd ? 5 : 0)), width: 32, height: 16), cloud);
      }
    }
    final horizon = g.groundY - g.h * 0.24;
    _backdrop(c, w, horizon, rnd);
    // The ground: a dirt verge from a little above the poles' feet.
    final floor = Rect.fromLTRB(0, g.groundY - 34, w, size.height);
    c.drawRect(floor, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFB0946A), Color(0xFF7A6345)]).createShader(floor));
    final pebble = Paint()..color = const Color(0x33402E1A);
    for (var i = 0; i < 26; i++) {
      c.drawCircle(Offset(rnd.nextDouble() * w, g.groundY - 30 + rnd.nextDouble() * (size.height - g.groundY + 26)), 1 + rnd.nextDouble() * 1.6, pebble);
    }

    _van(c, w);
    _farPoles(c, horizon);
    _poles(c);
    _line(c);
    _doArm(c);
    _tank(c);
    _ltCables(c);
    _ltBox(c);
    if (rig.leak) _stains(c);
  }

  void _backdrop(Canvas c, double w, double horizon, math.Random rnd) {
    switch (rig.place) {
      case M5Place.field:
        final tree = Paint()..color = const Color(0xFF4F7F45);
        for (var x = -10.0; x < w + 20; x += 18 + rnd.nextDouble() * 16) {
          final r = 9 + rnd.nextDouble() * 9;
          c.drawCircle(Offset(x, horizon - r * 0.5), r, tree);
        }
        c.drawRect(Rect.fromLTRB(0, horizon, w, geo.groundY), Paint()..color = const Color(0xFF8DB55A));
        final row = Paint()
          ..color = const Color(0x334A6B2A)
          ..strokeWidth = 1;
        for (var y = horizon + 6; y < geo.groundY; y += 7) {
          c.drawLine(Offset(0, y), Offset(w, y), row);
        }
      case M5Place.market:
        c.drawRect(Rect.fromLTRB(0, horizon, w, geo.groundY), Paint()..color = const Color(0xFFC9B38C));
        const awnings = [Color(0xFFD9534F), Color(0xFF3F8FD2), Color(0xFFE8B23A), Color(0xFF4FA36B)];
        for (var i = 0; i < 6; i++) {
          final x = -6 + i * 64 + rnd.nextDouble() * 10;
          final top = horizon - 34 - rnd.nextDouble() * 8;
          c.drawRect(Rect.fromLTWH(x + 4, top + 10, 48, horizon - top - 10), Paint()..color = const Color(0xFF9C7B57));
          final aw = Path()
            ..moveTo(x, top + 12)
            ..lineTo(x + 8, top)
            ..lineTo(x + 48, top)
            ..lineTo(x + 56, top + 12)
            ..close();
          c.drawPath(aw, Paint()..color = awnings[i % awnings.length]);
          for (var k = 0; k < 3; k++) {
            c.drawCircle(Offset(x + 14 + k * 12, horizon - 6), 4, Paint()..color = const Color(0xFF6B4A2E));
          }
        }
      case M5Place.school:
        c.drawRect(Rect.fromLTRB(0, horizon, w, geo.groundY), Paint()..color = const Color(0xFF9CC07A));
        final b = Rect.fromLTWH(14, horizon - 46, 150, 46);
        c.drawRect(b, Paint()..color = const Color(0xFFE7D7B5));
        c.drawRect(Rect.fromLTWH(b.left - 4, b.top - 6, b.width + 8, 8), Paint()..color = const Color(0xFFB0473A));
        for (var i = 0; i < 6; i++) {
          c.drawRect(Rect.fromLTWH(b.left + 10 + i * 23, b.top + 12, 12, 14), Paint()..color = const Color(0xFF4F6D8A));
        }
        c.drawLine(Offset(b.right + 18, horizon), Offset(b.right + 18, horizon - 70), Paint()
          ..color = const Color(0xFF8E959B)
          ..strokeWidth = 2);
        c.drawRect(Rect.fromLTWH(b.right + 19, horizon - 70, 22, 13), Paint()..color = const Color(0xFF2E7D4F));
        c.drawCircle(Offset(b.right + 28, horizon - 63.5), 3.6, Paint()..color = const Color(0xFFD9363E));
        // The road in front of the school.
        c.drawRect(Rect.fromLTRB(0, horizon + 8, w, horizon + 22), Paint()..color = const Color(0xFF6E6A66));
        final dash = Paint()
          ..color = const Color(0xFFEDE6D6)
          ..strokeWidth = 1.6;
        for (var x = 6.0; x < w; x += 24) {
          c.drawLine(Offset(x, horizon + 15), Offset(x + 12, horizon + 15), dash);
        }
    }
  }

  void _van(Canvas c, double w) {
    final g = geo;
    final top = math.max(104.0, M5CauseGeo.clipboard.top - 16);
    final body = Rect.fromLTRB(198, top, w + 30, g.groundY - 14);
    c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(14)),
        Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF4F1E8), Color(0xFFC9C3B2)]).createShader(body));
    // The utility's stripe and the open door's edge around the clipboard.
    c.drawRect(Rect.fromLTWH(body.left, body.top + body.height * 0.62, body.width, 10), Paint()..color = const Color(0xFF2F6FB0));
    final door = M5CauseGeo.clipboard.inflate(8);
    c.drawRRect(
        RRect.fromRectAndRadius(door, const Radius.circular(8)),
        Paint()
          ..color = const Color(0xFF9A9384)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    // Wheels.
    for (final x in [236.0, 326.0]) {
      c.drawCircle(Offset(x, g.groundY - 12), 16, Paint()..color = const Color(0xFF22262A));
      c.drawCircle(Offset(x, g.groundY - 12), 7, Paint()..color = const Color(0xFF8C939A));
    }
  }

  void _farPoles(Canvas c, double horizon) {
    final p = Paint()
      ..color = const Color(0xFF8E959B)
      ..strokeWidth = 3;
    final f = Offset(10, geo.armY + 30);
    c.drawLine(Offset(f.dx, f.dy - 8), Offset(f.dx, horizon + 4), p);
    c.drawLine(Offset(f.dx - 10, f.dy - 4), Offset(f.dx + 10, f.dy - 4), p);
  }

  void _poles(Canvas c) {
    final g = geo;
    for (final x in [M5CauseGeo.lp, M5CauseGeo.rp]) {
      final r = Rect.fromLTRB(x - 6, g.topY, x + 6, g.groundY + 4);
      c.drawRect(r, Paint()..shader = const LinearGradient(colors: [Color(0xFF8C939A), Color(0xFFC9CED2), Color(0xFF7A8187)]).createShader(r));
    }
    _channel(c, Offset(M5CauseGeo.lp - 18, g.armY), Offset(M5CauseGeo.rp + 18, g.armY));
    _channel(c, Offset(M5CauseGeo.lp - 14, g.doArmY), Offset(M5CauseGeo.rp + 14, g.doArmY));
    _channel(c, Offset(M5CauseGeo.lp - 8, g.platformY), Offset(M5CauseGeo.rp + 8, g.platformY));
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

  void _insulator(Canvas c, Offset base, {double scale = 1}) {
    final body = Paint()..color = _porcelain;
    final rim = Paint()
      ..color = const Color(0xFF9AA3AA)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final r = Rect.fromCenter(center: base.translate(0, (-4 - i * 5.0) * scale), width: (16 - i * 2.5) * scale, height: 5 * scale);
      c.drawOval(r, body);
      c.drawOval(r, rim);
    }
  }

  void _line(Canvas c) {
    final g = geo;
    final wire = Paint()
      ..color = _wire
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    for (final (i, x) in M5CauseGeo.phaseX.indexed) {
      final top = Offset(x, g.armY - 18);
      _insulator(c, Offset(x, g.armY - 4));
      final fl = Offset(10, g.armY + 26 - 6 + i * 4.0);
      c.drawPath(Path()
        ..moveTo(top.dx, top.dy)
        ..quadraticBezierTo((top.dx + fl.dx) / 2, top.dy + 16, fl.dx, fl.dy), wire);
      c.drawPath(Path()
        ..moveTo(top.dx, top.dy)
        ..quadraticBezierTo((top.dx + 380) / 2, top.dy + 14, 380, top.dy + 18), wire);
      // The jumper down to the DO's top contact.
      c.drawPath(
          Path()
            ..moveTo(top.dx, top.dy + 2)
            ..cubicTo(top.dx - 12, top.dy + 18, x - 12, g.doArmY - 24, x, g.doArmY - 6),
          Paint()
            ..color = const Color(0xFF2F353A)
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke);
    }
  }

  void _doArm(Canvas c) {
    final g = geo;
    final lead = Paint()
      ..color = const Color(0xFF2F353A)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 3; i++) {
      final x = M5CauseGeo.phaseX[i];
      final open = rig.doOpen[i];
      // The DO's insulator body and its two contacts.
      c.drawRect(Rect.fromLTWH(x + 7, g.doArmY - 6, 5, 40), Paint()..color = const Color(0xFF8D6E4C));
      c.drawRect(Rect.fromLTWH(x - 5, g.doArmY - 8, 12, 4), Paint()..color = _steel);
      c.drawRect(Rect.fromLTWH(x - 5, g.doArmY + 34, 12, 4), Paint()..color = _steel);
      // The barrel: in (closed, straight up between the contacts) or out
      // (swung down on its hinge, hanging open).
      c.save();
      c.translate(x, g.doArmY + 36);
      c.rotate(open ? 2.5 : 0);
      final barrel = Rect.fromLTWH(-3.5, -40, 7, 38);
      c.drawRRect(RRect.fromRectAndRadius(barrel, const Radius.circular(2)), Paint()..shader = const LinearGradient(colors: [Color(0xFF3B3F44), Color(0xFF6A7178)]).createShader(barrel));
      c.drawCircle(const Offset(0, -40), 3, Paint()..color = const Color(0xFFB8BEC3));
      c.restore();
      // The lead on to the HT bushing.
      final from = Offset(x, g.doArmY + 40);
      final to = g.htBushings[i].translate(0, -10);
      c.drawPath(Path()
        ..moveTo(from.dx, from.dy)
        ..cubicTo(from.dx, from.dy + 24, to.dx, to.dy - 24, to.dx, to.dy), lead);
    }
  }

  void _tank(Canvas c) {
    final g = geo;
    final t = g.tank;
    final body = RRect.fromRectAndRadius(t, const Radius.circular(4));
    c.drawRRect(body.shift(const Offset(3, 3)), Paint()..color = const Color(0x44000000));
    c.drawRRect(body, Paint()..shader = const LinearGradient(colors: [Color(0xFF6E7F72), Color(0xFF9DB0A1), Color(0xFF627266)]).createShader(t));
    final fin = Paint()
      ..color = const Color(0x55313D33)
      ..strokeWidth = 2;
    for (var x = t.left + 8; x < t.right - 12; x += 9) {
      c.drawLine(Offset(x, t.top + 10), Offset(x, t.bottom - 30), fin);
    }
    // The lid and its gasket line (every tank).
    c.drawRect(Rect.fromLTWH(t.left - 3, t.top - 3, t.width + 6, 5), Paint()..color = const Color(0xFF55645A));
    c.drawLine(Offset(t.left - 2, t.top + 2.5), Offset(t.right + 2, t.top + 2.5), Paint()
      ..color = const Color(0xFF2B2B2B)
      ..strokeWidth = 1.2);
    // The weld seam down the right side (every tank).
    final seam = Paint()
      ..color = const Color(0xFF4D5A50)
      ..strokeWidth = 1.4;
    for (var y = t.top + 6; y < t.bottom - 4; y += 5) {
      c.drawLine(Offset(t.right - 5, y), Offset(t.right - 5, y + 2.6), seam);
    }
    // An old dent on the face (every tank).
    final d = g.source(M5LeakSource.dent);
    c.drawOval(Rect.fromCenter(center: d, width: 16, height: 10), Paint()..color = const Color(0x44202A22));
    c.drawArc(Rect.fromCenter(center: d, width: 16, height: 10), 3.4, 2.4, false, Paint()
      ..color = const Color(0x66FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);
    // The conservator and its oil gauge (a round window facing front).
    final cons = Rect.fromLTWH(t.left - 6, t.top - 30, 42, 15);
    c.drawRRect(RRect.fromRectAndRadius(cons, const Radius.circular(7)), Paint()..color = const Color(0xFF7E8F82));
    c.drawLine(Offset(cons.left + 20, cons.bottom), Offset(cons.left + 20, t.top - 2), Paint()
      ..color = const Color(0xFF55645A)
      ..strokeWidth = 3);
    c.drawCircle(g.gauge, 7, Paint()..color = const Color(0xFFDDE3E6));
    c.drawCircle(g.gauge, 7, Paint()
      ..color = const Color(0xFF4E565D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6);
    c.drawLine(g.gauge, g.gauge.translate(3, -4), Paint()
      ..color = const Color(0xFF22262A)
      ..strokeWidth = 1.4);
    for (final b in g.htBushings) {
      _insulator(c, b.translate(0, 10));
    }
    // The LT bushings R, Y, B: brown stubs with a stud, a nut and the lug.
    for (var i = 0; i < 3; i++) {
      final b = g.bushing(i);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: b.translate(0, -4), width: 12, height: 16), const Radius.circular(3)), Paint()..color = const Color(0xFF6B4A2E));
      c.drawRect(Rect.fromCenter(center: b.translate(0, 6), width: 4, height: 8), Paint()..color = const Color(0xFFC18A3A));
      c.drawRect(Rect.fromCenter(center: b.translate(0, 4), width: 9, height: 5), Paint()..color = _steel);
    }
    // A fresh streak from the source (a leak case, once traced).
    if (rig.leak && rig.traced) {
      final s = g.source(rig.source);
      final st = g.stain(rig.freshStain);
      final streak = Paint()
        ..color = const Color(0xCC2A1A08)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      c.drawPath(
          Path()
            ..moveTo(s.dx, s.dy)
            ..quadraticBezierTo(s.dx, (s.dy + t.bottom) / 2, (s.dx + st.dx) / 2, t.bottom)
            ..lineTo(st.dx, g.platformY),
          streak);
      final drop = Paint()..color = const Color(0xCC2A1A08);
      for (var y = g.platformY + 10; y < st.dy - 8; y += 16) {
        c.drawOval(Rect.fromCenter(center: Offset(st.dx, y), width: 3, height: 6), drop);
      }
      c.drawCircle(s, 4, Paint()..color = const Color(0xFF3A2410));
    }
  }

  void _ltCables(Canvas c) {
    final g = geo;
    final cable = Paint()
      ..color = const Color(0xFF1A1C1E)
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final box = g.ltBox;
    for (var i = 0; i < 3; i++) {
      final b = g.bushing(i).translate(0, 10);
      final pole = M5CauseGeo.lp - 6.0 - i * 3;
      c.drawPath(
          Path()
            ..moveTo(b.dx, b.dy)
            ..quadraticBezierTo(b.dx, g.platformY + 6, (b.dx + pole) / 2, g.platformY + 8)
            ..lineTo(pole, g.platformY + 10)
            ..lineTo(pole, box.top),
          cable);
    }
    // The outgoing cable into the ground under the box.
    final out = Rect.fromLTWH(box.center.dx - 5, box.bottom, 10, g.groundY - box.bottom - 2);
    c.drawRRect(RRect.fromRectAndRadius(out, const Radius.circular(4)), Paint()..color = const Color(0xFF1A1C1E));
  }

  void _ltBox(Canvas c) {
    final g = geo;
    final box = g.ltBox;
    c.drawRRect(RRect.fromRectAndRadius(box.shift(const Offset(2, 2)), const Radius.circular(4)), Paint()..color = const Color(0x44000000));
    c.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(4)),
        Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF9AA3AA), Color(0xFF6F7880)]).createShader(box));
    c.drawRRect(
        RRect.fromRectAndRadius(box.deflate(4), const Radius.circular(3)),
        Paint()
          ..color = const Color(0xFF2E3338)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
    const labels = ['R', 'Y', 'B'];
    const tints = [Color(0xFFD9363E), Color(0xFFE8B23A), Color(0xFF3F6FD2)];
    for (var i = 0; i < 3; i++) {
      final t = g.terminal(i);
      c.drawRect(Rect.fromCenter(center: t, width: 12, height: 10), Paint()..color = const Color(0xFFC18A3A));
      c.drawCircle(t, 2.4, Paint()..color = _steel);
      _label(c, labels[i], t.translate(0, -16), tints[i], 9);
      // A meter dial over the terminal once read: the needle up (voltage) or
      // at rest on the left (none; every phase once the HT side is open).
      if (rig.meter.contains(i)) {
        final o = t.translate(0, 13);
        c.drawArc(Rect.fromCircle(center: o, radius: 7), math.pi, math.pi, true, Paint()..color = const Color(0xFFF7F3E6));
        final dead = !m5DialLive(rig, i);
        final a = math.pi + (dead ? 0.15 : 1.75);
        c.drawLine(o, o + Offset(math.cos(a), math.sin(a)) * 6.5, Paint()
          ..color = dead ? const Color(0xFF22262A) : const Color(0xFFD9363E)
          ..strokeWidth = 1.4);
      }
    }
    // The lever on the box's right: up = ON, down = OFF.
    final lv = g.leverHit;
    final pivot = Offset(lv.left + 4, lv.center.dy);
    c.drawCircle(pivot, 4, Paint()..color = const Color(0xFF3A3F45));
    final end = pivot + Offset(16, rig.ltOn ? -14 : 14);
    c.drawLine(pivot, end, Paint()
      ..color = const Color(0xFF22262A)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round);
    c.drawCircle(end, 4.5, Paint()..color = const Color(0xFFD9363E));
    _label(c, rig.ltOn ? 'ON' : 'OFF', Offset(lv.right - 10, rig.ltOn ? lv.bottom - 6 : lv.top + 6), const Color(0xFF22262A), 8);
  }

  void _stains(Canvas c) {
    final g = geo;
    for (var i = 0; i < 3; i++) {
      final s = g.stain(i);
      if (i == rig.freshStain) {
        // The same size for a large and a small leak: how much shows only in
        // the drip watch and the gauge.
        final r = Rect.fromCenter(center: s, width: 24, height: 10);
        c.drawOval(r, Paint()..color = _oil);
        c.drawOval(r.deflate(3).shift(const Offset(-2, -1)), Paint()..color = const Color(0x557A6A55));
      } else {
        // Old and dry: dull, cracked, soaked into the dirt.
        final r = Rect.fromCenter(center: s.translate(i.isEven ? -2 : 2, 1), width: 24, height: 10);
        c.drawOval(r, Paint()..color = const Color(0xFF6E5A40));
        c.drawLine(r.centerLeft.translate(4, 0), r.center.translate(2, 2), Paint()
          ..color = const Color(0xFF8E7B5F)
          ..strokeWidth = 1);
      }
    }
  }

  void _label(Canvas c, String text, Offset at, Color color, double size) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: size, fontWeight: FontWeight.w900)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, at - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(M5CausePainter old) => old.geo != geo || old.rig != rig || old.seed != seed;
}

/// A metered phase's dial at the LT box (the incoming side, straight from
/// the LT bushing): voltage on every healthy phase until all three DOs are
/// open — the LT lever alone does not kill it, just as the tester on the
/// bushing reads live until then.
bool m5DialLive(M5CauseRig rig, int phase) => phase != rig.deadPhase && !rig.doOpen.every((o) => o);

/// What the reading card shows (the last test).
enum M5Reading { hum, loud, tong, gaugeOk, gaugeLow, doLook, source, drip }

/// The reading card's picture. [v] runs 0 → 1 over the drip watch.
class M5ReadingPainter extends CustomPainter {
  const M5ReadingPainter({
    required this.reading,
    this.source = M5LeakSource.gasket,
    this.large = false,
    this.doOpen = const [false, false, false],
    this.v = 1,
    this.seed = 0,
  });

  final M5Reading reading;
  final M5LeakSource source;
  final bool large;

  /// The DO look: which barrels the hot stick has opened (they hang down).
  final List<bool> doOpen;
  final double v;
  final int seed;

  @override
  void paint(Canvas c, Size size) {
    final r = Offset.zero & size;
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(12)), Paint()..color = const Color(0xF2F7F3E6));
    c.drawRRect(
        RRect.fromRectAndRadius(r.deflate(1), const Radius.circular(12)),
        Paint()
          ..color = const Color(0xFF8A7A5C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    final inner = r.deflate(10);
    switch (reading) {
      case M5Reading.hum:
      case M5Reading.loud:
        _wave(c, inner, reading == M5Reading.loud);
      case M5Reading.tong:
        _dial(c, inner);
      case M5Reading.gaugeOk:
      case M5Reading.gaugeLow:
        _gauge(c, inner, reading == M5Reading.gaugeLow);
      case M5Reading.doLook:
        _dos(c, inner);
      case M5Reading.source:
        _source(c, inner);
      case M5Reading.drip:
        _drip(c, inner);
    }
  }

  /// The sound as a wave: steady and small (hum) or big and broken (loud).
  void _wave(Canvas c, Rect r, bool loud) {
    final mid = r.center.dy;
    c.drawLine(Offset(r.left, mid), Offset(r.right, mid), Paint()
      ..color = const Color(0x338A7A5C)
      ..strokeWidth = 1);
    final p = Path()..moveTo(r.left, mid);
    final rnd = math.Random(seed);
    for (var x = 0.0; x <= r.width; x += 1.5) {
      double a;
      if (loud) {
        final burst = (x ~/ 18).isEven ? 1.0 : 0.45;
        a = math.sin(x / 2.6) * r.height * 0.36 * burst + (rnd.nextDouble() - 0.5) * r.height * 0.42 * burst;
      } else {
        a = math.sin(x / 3.2) * r.height * 0.13;
      }
      p.lineTo(r.left + x, mid + a);
    }
    c.drawPath(p, Paint()
      ..color = loud ? const Color(0xFFC0392B) : const Color(0xFF2E7D4F)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke);
  }

  /// The tong tester's dial: the needle against the nameplate mark (red).
  void _dial(Canvas c, Rect r) {
    final o = Offset(r.center.dx, r.bottom - 6);
    final rad = math.min(r.width / 2, r.height - 8);
    final arc = Rect.fromCircle(center: o, radius: rad);
    c.drawArc(arc, math.pi, math.pi, false, Paint()
      ..color = const Color(0xFF4E565D)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke);
    for (var k = 0; k <= 10; k++) {
      final a = math.pi + k / 10 * math.pi;
      c.drawLine(o + Offset(math.cos(a), math.sin(a)) * (rad - 6), o + Offset(math.cos(a), math.sin(a)) * rad, Paint()
        ..color = const Color(0xFF4E565D)
        ..strokeWidth = 1.2);
    }
    // The nameplate mark.
    const mark = math.pi + 0.78 * math.pi;
    c.drawLine(o + Offset(math.cos(mark), math.sin(mark)) * (rad - 12), o + Offset(math.cos(mark), math.sin(mark)) * (rad + 2), Paint()
      ..color = const Color(0xFFD9363E)
      ..strokeWidth = 3);
    // The needle, well inside the mark.
    final a = math.pi + (0.42 + (seed % 5) * 0.04) * math.pi;
    c.drawLine(o, o + Offset(math.cos(a), math.sin(a)) * (rad - 8), Paint()
      ..color = const Color(0xFF22262A)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round);
    c.drawCircle(o, 4, Paint()..color = const Color(0xFF22262A));
    _text(c, 'A', Offset(r.left + 8, r.bottom - 10), 10);
  }

  /// The oil gauge, close up: the float against the MIN line.
  void _gauge(Canvas c, Rect r, bool low) {
    final glass = Rect.fromCenter(center: r.center, width: 34, height: r.height);
    c.drawRRect(RRect.fromRectAndRadius(glass, const Radius.circular(8)), Paint()..color = const Color(0xFFDDE3E6));
    final level = low ? glass.bottom - glass.height * 0.16 : glass.top + glass.height * 0.38;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(glass.left, level, glass.right, glass.bottom), const Radius.circular(8)), Paint()..color = const Color(0xFFC9A54A));
    c.drawCircle(Offset(glass.center.dx, level), 6, Paint()..color = const Color(0xFF8C5A1E));
    final minY = glass.bottom - glass.height * 0.3;
    c.drawLine(Offset(glass.left - 8, minY), Offset(glass.right + 8, minY), Paint()
      ..color = const Color(0xFFD9363E)
      ..strokeWidth = 2);
    _text(c, 'MIN', Offset(glass.right + 26, minY), 10);
    c.drawRRect(
        RRect.fromRectAndRadius(glass, const Radius.circular(8)),
        Paint()
          ..color = const Color(0xFF4E565D)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }

  /// The three DO fuses close up: every barrel in its clamps, or swung down
  /// on its lower hinge where the hot stick has opened it.
  void _dos(Canvas c, Rect r) {
    for (var i = 0; i < 3; i++) {
      final x = r.left + r.width * (0.2 + i * 0.3);
      c.drawRect(Rect.fromLTWH(x - 8, r.top, 16, 5), Paint()..color = const Color(0xFF6F7880));
      c.drawRect(Rect.fromLTWH(x - 8, r.bottom - 5, 16, 5), Paint()..color = const Color(0xFF6F7880));
      final barrel = Rect.fromLTWH(x - 5, r.top + 5, 10, r.height - 10);
      final paint = Paint()..shader = const LinearGradient(colors: [Color(0xFF3B3F44), Color(0xFF6A7178)]).createShader(barrel);
      if (i < doOpen.length && doOpen[i]) {
        final hinge = Offset(x, r.bottom - 5);
        c.save();
        c.translate(hinge.dx, hinge.dy);
        c.rotate(-0.75);
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-5, -barrel.height, 10, barrel.height), const Radius.circular(3)), paint);
        c.restore();
      } else {
        c.drawRRect(RRect.fromRectAndRadius(barrel, const Radius.circular(3)), paint);
      }
      c.drawRect(Rect.fromLTWH(x + 9, r.top + 2, 6, r.height - 4), Paint()..color = const Color(0xFF8D6E4C));
    }
  }

  /// The leak's source close up: the lid gasket weeping, the weld seam
  /// cracked, or the dent split — oil running from it.
  void _source(Canvas c, Rect r) {
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(6)), Paint()..shader = const LinearGradient(colors: [Color(0xFF6E7F72), Color(0xFF9DB0A1)]).createShader(r));
    final oil = Paint()
      ..color = const Color(0xDD2A1A08)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    switch (source) {
      case M5LeakSource.gasket:
        c.drawRect(Rect.fromLTWH(r.left, r.top + 8, r.width, 9), Paint()..color = const Color(0xFF55645A));
        c.drawLine(Offset(r.left, r.top + 17), Offset(r.right, r.top + 17), Paint()
          ..color = const Color(0xFF1C1C1C)
          ..strokeWidth = 2.4);
        c.drawLine(Offset(r.center.dx - 6, r.top + 18), Offset(r.center.dx - 4, r.bottom - 6), oil);
        c.drawLine(Offset(r.center.dx + 14, r.top + 18), Offset(r.center.dx + 15, r.top + 40), oil);
      case M5LeakSource.weld:
        final seam = Paint()
          ..color = const Color(0xFF4D5A50)
          ..strokeWidth = 3;
        for (var y = r.top + 4; y < r.bottom - 4; y += 8) {
          c.drawLine(Offset(r.center.dx, y), Offset(r.center.dx, y + 4), seam);
        }
        c.drawPath(
            Path()
              ..moveTo(r.center.dx - 2, r.top + 18)
              ..lineTo(r.center.dx + 4, r.top + 26)
              ..lineTo(r.center.dx - 3, r.top + 34),
            Paint()
              ..color = const Color(0xFF1C1C1C)
              ..strokeWidth = 1.6
              ..style = PaintingStyle.stroke);
        c.drawLine(Offset(r.center.dx + 2, r.top + 30), Offset(r.center.dx + 3, r.bottom - 4), oil);
      case M5LeakSource.dent:
        final d = Rect.fromCenter(center: r.center.translate(0, -8), width: 54, height: 30);
        c.drawOval(d, Paint()..color = const Color(0x55202A22));
        c.drawArc(d, 3.4, 2.4, false, Paint()
          ..color = const Color(0x88FFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6);
        c.drawLine(d.center.translate(-8, 2), d.center.translate(6, -2), Paint()
          ..color = const Color(0xFF1C1C1C)
          ..strokeWidth = 1.6);
        c.drawLine(d.center.translate(0, 2), Offset(d.center.dx + 1, r.bottom - 4), oil);
    }
  }

  /// Five seconds of the drip: drops fall from the leak; afterwards they lie
  /// counted along the bottom (a slow drip, or many).
  void _drip(Canvas c, Rect r) {
    final from = Offset(r.center.dx, r.top + 4);
    c.drawRect(Rect.fromLTWH(r.left, r.top, r.width, 6), Paint()..color = const Color(0xFF7E8F82));
    final n = large ? 8 : 1;
    final drop = Paint()..color = const Color(0xFF2A1A08);
    final landed = (v * n).floor().clamp(0, n);
    for (var k = 0; k < landed; k++) {
      final x = r.left + 10 + k * ((r.width - 20) / math.max(1, n - 1));
      c.drawOval(Rect.fromCenter(center: Offset(n == 1 ? r.center.dx : x, r.bottom - 5), width: 7, height: 9), drop);
    }
    if (v < 1) {
      final phase = (v * n) - (v * n).floor();
      c.drawOval(Rect.fromCenter(center: Offset(from.dx, from.dy + 6 + phase * (r.height - 20)), width: 6, height: 9), drop);
    }
    _text(c, '5 s', Offset(r.right - 14, r.top + 16), 10);
  }

  void _text(Canvas c, String t, Offset at, double size) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: TextStyle(color: const Color(0xFF3A3F45), fontSize: size, fontWeight: FontWeight.w900)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, at - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(M5ReadingPainter old) =>
      old.reading != reading || old.source != source || old.large != large || !listEquals(old.doOpen, doOpen) || old.v != v || old.seed != seed;
}

/// The flash of a deadly move at [at], [v] 0 → 1.
class M5CauseFlashPainter extends CustomPainter {
  const M5CauseFlashPainter({required this.at, required this.v});
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
  bool shouldRepaint(M5CauseFlashPainter old) => old.v != v || old.at != at;
}
