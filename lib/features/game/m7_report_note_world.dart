import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The drawn world of lesson 7.7 কাজ 2 "সৎ রিপোর্ট" (m7_report_note.dart): a
// village street, morning light.
//
//  * Three LT poles in a row, each with a small number plate that is only a
//    blur from here (the number is read under the lens, one digit apart); a
//    tea stall on the right with a wall clock; the crew van far left.
//  * The accident plays once (9 s), three beats on the accident pole: T1 a
//    shock on the pole (one hand), T2 a flash at the pillar box beside it (one
//    forearm), T3 a shock on the ladder and a slip off it (one ankle). The tea
//    man and the cyclist turn to watch — or do not. Then the scene is kept as
//    it fell: the ladder on the ground, the pillar open, the hurt man sitting.
//  * Body outline, clock dial, lens and the three stills are drawn here too.
//
// Left / right on the body outline and in the scene are screen sides. No
// captions in the art; only what a worker reads (the vest name patch, plates
// under the lens, the clock). Code-drawn, gradients, no bitmaps. Design: 360
// wide x the scene's height (560-900); the report sheet (a widget) covers the
// bottom [sheetDp] dp.

/// The body zones the player marks (screen sides).
enum M7Zone { head, chest, forearmL, forearmR, handL, handR, ankleL, ankleR }

/// The kind of hurt a zone took.
enum M7Kind { shock, burn, sprain }

/// A figure that may have seen the accident.
enum M7Wit { tea, cyclist }

/// The replay's length. The three beats end at [m7BeatEnds].
const m7ReplayMs = 9000;

/// Where each beat is on the replay clock (0..1): T1 shock, T2 flash, T3 fall.
const m7BeatMid = [0.17, 0.51, 0.89];

/// The replay's last value: everything has happened.
const m7ReplayEnd = 1.0;

/// What the lens and the pole plates read.
@immutable
class M7Look {
  const M7Look({
    required this.acc,
    required this.handR,
    required this.foreR,
    required this.ankleR,
    required this.tea,
    required this.cyclist,
    required this.patch,
    required this.poleNos,
  });

  /// The accident pole (0..2, left to right).
  final int acc;

  /// Which side was hurt (true = screen-right).
  final bool handR;
  final bool foreR;
  final bool ankleR;

  /// Who turned to watch.
  final bool tea;
  final bool cyclist;

  /// The injured man's name on his vest.
  final String patch;

  /// The three plates, left to right.
  final List<int> poleNos;

  @override
  bool operator ==(Object other) =>
      other is M7Look &&
      other.acc == acc &&
      other.handR == handR &&
      other.foreR == foreR &&
      other.ankleR == ankleR &&
      other.tea == tea &&
      other.cyclist == cyclist &&
      other.patch == patch &&
      listEquals(other.poleNos, poleNos);

  @override
  int get hashCode => Object.hash(acc, handR, foreR, ankleR, tea, cyclist, patch, Object.hashAll(poleNos));
}

/// Where things are (design px, 360 wide).
@immutable
class M7ReportGeo {
  const M7ReportGeo._(this.height, this.ground, this.sheetTop);

  /// The sheet's height in dp (the widget covers the bottom of the screen).
  static const sheetDp = 312.0;

  /// For a [screen] (dp): the design height, where the ground sits and where
  /// the report sheet starts, all in design px.
  factory M7ReportGeo.forScreen(Size screen, {double bottomInset = 0}) {
    final w = math.max(1.0, screen.width);
    final sh = (360 * screen.height / w).clamp(560.0, 900.0);
    final scale = math.max(screen.width / 360, screen.height / sh);
    final sheetTop = sh - (sheetDp + bottomInset) / scale;
    final ground = (sheetTop - 14).clamp(290.0, 336.0);
    return M7ReportGeo._(sh, ground, sheetTop);
  }

  final double height;
  final double ground;

  /// The y where the report sheet's top edge is (design px).
  final double sheetTop;

  /// The pole tops (clear of the header).
  double get top => math.max(128.0, ground - 204);

  static double poleX(int i) => 80.0 + i * 70;

  /// The tap area of pole [i].
  Rect pole(int i) => Rect.fromLTWH(poleX(i) - 20, top + 24, 40, ground - top - 24);

  /// The plate's centre on pole [i].
  Offset plate(int i) => Offset(poleX(i), ground - 96);

  Rect get stall => Rect.fromLTWH(262, ground - 112, 94, 112);
  Offset get wallClock => Offset(309, ground - 86);
  Rect get van => Rect.fromLTWH(4, ground - 46, 58, 46);

  /// The pillar box beside the accident pole, toward the middle.
  static double pillarX(int acc) => poleX(acc) + (acc == 2 ? -42 : 42);

  /// The road's top edge (the cyclist rides on it).
  double get road => ground + 6;

  @override
  bool operator ==(Object other) => other is M7ReportGeo && other.height == height && other.ground == ground && other.sheetTop == sheetTop;

  @override
  int get hashCode => Object.hash(height, ground, sheetTop);
}

/// What the static street shows: the wall clock's minute of day.
@immutable
class M7StreetRig {
  const M7StreetRig({required this.clockMin});
  final int clockMin;

  @override
  bool operator ==(Object other) => other is M7StreetRig && other.clockMin == clockMin;

  @override
  int get hashCode => clockMin.hashCode;
}

// ============================================================================
// Small drawing helpers
// ============================================================================

void _text(Canvas c, String t, Offset at, double size, Color color, {FontWeight weight = FontWeight.w900, double? maxWidth}) {
  final tp = TextPainter(
    text: TextSpan(text: t, style: TextStyle(color: color, fontSize: size, fontWeight: weight, height: 1.1)),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  if (maxWidth != null && tp.width > maxWidth) {
    c.save();
    c.translate(at.dx, at.dy);
    final s = maxWidth / tp.width;
    c.scale(s, s);
    tp.paint(c, Offset(-tp.width / 2, -tp.height / 2));
    c.restore();
    return;
  }
  tp.paint(c, at - Offset(tp.width / 2, tp.height / 2));
}

double _seg(double t, double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);
double _lerp(double a, double b, double t) => a + (b - a) * t;
Offset _lerpO(Offset a, Offset b, double t) => Offset(_lerp(a.dx, b.dx, t), _lerp(a.dy, b.dy, t));

/// A clock face: hour and minute hands for [minutes] (of the day).
void paintM7Clock(Canvas c, Offset ctr, double r, int minutes, {bool plain = false}) {
  c.drawCircle(ctr, r + 2.5, Paint()..color = const Color(0xFF3A2A16));
  c.drawCircle(ctr, r, Paint()..color = const Color(0xFFFFFBEF));
  final tick = Paint()
    ..color = const Color(0xFF3A2A16)
    ..strokeCap = StrokeCap.round;
  for (var i = 0; i < 12; i++) {
    final a = i * math.pi / 6;
    final big = i % 3 == 0;
    tick.strokeWidth = big ? math.max(1.6, r * 0.06) : math.max(1.0, r * 0.035);
    final o = ctr + Offset(math.sin(a), -math.cos(a)) * (r - 1.5);
    final inn = ctr + Offset(math.sin(a), -math.cos(a)) * (r * (big ? 0.78 : 0.86));
    c.drawLine(o, inn, tick);
  }
  final h = (minutes ~/ 60) % 12 + (minutes % 60) / 60;
  final m = (minutes % 60).toDouble();
  final ha = h / 12 * 2 * math.pi;
  final ma = m / 60 * 2 * math.pi;
  c.drawLine(ctr, ctr + Offset(math.sin(ha), -math.cos(ha)) * (r * 0.5), Paint()
    ..color = const Color(0xFF1B1B1B)
    ..strokeWidth = math.max(2.0, r * 0.1)
    ..strokeCap = StrokeCap.round);
  c.drawLine(ctr, ctr + Offset(math.sin(ma), -math.cos(ma)) * (r * 0.78), Paint()
    ..color = plain ? const Color(0xFF1B1B1B) : const Color(0xFFB02A1E)
    ..strokeWidth = math.max(1.6, r * 0.07)
    ..strokeCap = StrokeCap.round);
  c.drawCircle(ctr, math.max(2.0, r * 0.07), Paint()..color = const Color(0xFF1B1B1B));
}

/// A zigzag electric spark at [o], size [s], flickering with [phase].
void _spark(Canvas c, Offset o, double s, double phase) {
  final k = (phase * 23).floor() % 3;
  final p = Path()..moveTo(o.dx - s * 0.6, o.dy - s);
  final pts = [
    [0.3, -0.45],
    [-0.35, -0.2],
    [0.4, 0.3],
    [-0.1, 0.5],
    [0.5, 1.0],
  ];
  for (final q in pts) {
    p.lineTo(o.dx + (q[0] + (k - 1) * 0.08) * s, o.dy + q[1] * s);
  }
  c.drawPath(p, Paint()
    ..color = const Color(0xFFFFF27A)
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(2.0, s * 0.18)
    ..strokeJoin = StrokeJoin.round);
  c.drawPath(p, Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(1.0, s * 0.07));
  c.drawCircle(o, s * 0.9, Paint()..shader = const RadialGradient(colors: [Color(0x55FFF27A), Color(0x00FFF27A)]).createShader(Rect.fromCircle(center: o, radius: s * 0.9)));
}

/// A white-orange arc flash burst.
void _burst(Canvas c, Offset o, double r, double amount) {
  if (amount <= 0) return;
  final rr = r * (0.6 + 0.4 * amount);
  c.drawCircle(
      o,
      rr,
      Paint()
        ..shader = RadialGradient(colors: [
          Color.fromRGBO(255, 255, 255, 0.95 * amount),
          Color.fromRGBO(255, 200, 70, 0.8 * amount),
          const Color(0x00FF7A1E),
        ], stops: const [0.0, 0.45, 1.0])
            .createShader(Rect.fromCircle(center: o, radius: rr)));
}

/// Joints of a drawn person (for sparks and glows).
class _Joints {
  _Joints({required this.head, required this.handL, required this.handR, required this.midL, required this.midR, required this.ankleL, required this.ankleR});
  final Offset head;
  final Offset handL;
  final Offset handR;
  final Offset midL;
  final Offset midR;
  final Offset ankleL;
  final Offset ankleR;
}

/// A person, [foot] on the ground, [h] tall. [angL]/[angR]: the arms' angle
/// from hanging straight down (+ is outward on that side's own screen side is
/// handled by the sign: left arm swings by -ang, right by +ang; pi = straight
/// up). [face]: -1 looks left, +1 right, 0 front; [away]: back of the head.
_Joints _person(
  Canvas c, {
  required Offset foot,
  required double h,
  required Color vest,
  double angL = 0.12,
  double angR = 0.12,
  bool sit = false,
  double face = 0,
  bool away = false,
  String? patch,
  Color helmet = const Color(0xFFFFD21E),
  double tilt = 0,
  Color pants = const Color(0xFF2F3E5C),
}) {
  c.save();
  if (tilt != 0) {
    c.translate(foot.dx, foot.dy);
    c.rotate(tilt);
    c.translate(-foot.dx, -foot.dy);
  }
  final x = foot.dx;
  final hipY = sit ? foot.dy - 0.10 * h : foot.dy - 0.42 * h;
  final shY = sit ? foot.dy - 0.44 * h : foot.dy - 0.74 * h;
  final headC = Offset(x, shY - 0.13 * h);
  final aL = Offset(x - (sit ? 0.40 : 0.07) * h, sit ? foot.dy - 0.02 * h : foot.dy);
  final aR = Offset(x + (sit ? 0.40 : 0.07) * h, sit ? foot.dy - 0.02 * h : foot.dy);
  final leg = Paint()
    ..color = pants
    ..strokeWidth = 0.13 * h
    ..strokeCap = StrokeCap.round;
  c.drawLine(Offset(x - 0.05 * h, hipY), aL, leg);
  c.drawLine(Offset(x + 0.05 * h, hipY), aR, leg);
  c.drawRect(Rect.fromLTWH(aL.dx - 0.07 * h, aL.dy - 0.01 * h, 0.14 * h, 0.05 * h), Paint()..color = const Color(0xFF1E1E1E));
  c.drawRect(Rect.fromLTWH(aR.dx - 0.07 * h, aR.dy - 0.01 * h, 0.14 * h, 0.05 * h), Paint()..color = const Color(0xFF1E1E1E));
  // Torso.
  final torso = RRect.fromRectAndRadius(Rect.fromLTRB(x - 0.15 * h, shY, x + 0.15 * h, hipY + 0.04 * h), Radius.circular(0.06 * h));
  c.drawRRect(torso, Paint()..color = vest);
  c.drawRect(Rect.fromLTRB(x - 0.15 * h, shY + 0.16 * h, x + 0.15 * h, shY + 0.20 * h), Paint()..color = const Color(0xCCF4F4F4));
  if (patch != null && !away) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, shY + 0.07 * h), width: 0.26 * h, height: 0.08 * h), const Radius.circular(1)), Paint()..color = const Color(0xFFFDF8EC));
    _text(c, patch, Offset(x, shY + 0.07 * h), math.max(4.0, 0.06 * h), const Color(0xFF1B1B1B), weight: FontWeight.w800, maxWidth: 0.24 * h);
  }
  // Arms (sleeves, hands).
  final sh = [Offset(x - 0.16 * h, shY + 0.04 * h), Offset(x + 0.16 * h, shY + 0.04 * h)];
  final ang = [-angL, angR];
  final hands = <Offset>[];
  final mids = <Offset>[];
  for (var i = 0; i < 2; i++) {
    final len = 0.32 * h;
    final a = ang[i];
    final hand = sh[i] + Offset(math.sin(a), math.cos(a)) * len;
    c.drawLine(sh[i], hand, Paint()
      ..color = vest
      ..strokeWidth = 0.09 * h
      ..strokeCap = StrokeCap.round);
    c.drawCircle(hand, 0.055 * h, Paint()..color = const Color(0xFFE0A87C));
    hands.add(hand);
    mids.add(_lerpO(sh[i], hand, 0.55));
  }
  // Head.
  c.drawCircle(headC, 0.115 * h, Paint()..color = const Color(0xFFE0A87C));
  if (away) {
    c.drawCircle(headC, 0.115 * h, Paint()..color = const Color(0xFF3A2A1E));
  } else {
    final ex = face * 0.045 * h;
    c.drawCircle(headC + Offset(ex - 0.03 * h, -0.01 * h), 0.014 * h, Paint()..color = const Color(0xFF1B1B1B));
    c.drawCircle(headC + Offset(ex + 0.03 * h, -0.01 * h), 0.014 * h, Paint()..color = const Color(0xFF1B1B1B));
  }
  final cap = Path()
    ..addArc(Rect.fromCircle(center: headC, radius: 0.125 * h), math.pi, math.pi)
    ..close();
  c.drawPath(cap, Paint()..color = helmet);
  c.drawRect(Rect.fromLTRB(headC.dx - 0.15 * h, headC.dy - 0.006 * h, headC.dx + 0.15 * h, headC.dy + 0.012 * h), Paint()..color = helmet);
  c.restore();
  return _Joints(head: headC, handL: hands[0], handR: hands[1], midL: mids[0], midR: mids[1], ankleL: aL, ankleR: aR);
}

// ============================================================================
// The street (static)
// ============================================================================

class M7StreetPainter extends CustomPainter {
  const M7StreetPainter({required this.geo, required this.rig});

  final M7ReportGeo geo;
  final M7StreetRig rig;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final g = geo.ground;
    // Sky.
    final sky = Rect.fromLTWH(0, 0, w, g);
    c.drawRect(sky, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8EC3E8), Color(0xFFD9ECF4), Color(0xFFF3E6C4)]).createShader(sky));
    c.drawCircle(Offset(w - 52, geo.top - 6), 22, Paint()..shader = const RadialGradient(colors: [Color(0xFFFFF6C8), Color(0x00FFF6C8)]).createShader(Rect.fromCircle(center: Offset(w - 52, geo.top - 6), radius: 36)));
    // Far houses.
    final far = Paint()..color = const Color(0xFFB9C6C6);
    for (final r in [
      Rect.fromLTWH(0, g - 70, 52, 70),
      Rect.fromLTWH(104, g - 56, 60, 56),
      Rect.fromLTWH(188, g - 78, 48, 78),
      Rect.fromLTWH(300, g - 62, 60, 62),
    ]) {
      c.drawRect(r, far);
      c.drawRect(Rect.fromLTWH(r.left + 8, r.top + 12, 10, 12), Paint()..color = const Color(0xFF8FA0A0));
      c.drawRect(Rect.fromLTWH(r.right - 20, r.top + 12, 10, 12), Paint()..color = const Color(0xFF8FA0A0));
    }
    // Ground: verge, road, foreground.
    c.drawRect(Rect.fromLTWH(0, g - 2, w, 8), Paint()..color = const Color(0xFF8DA06A));
    final road = Rect.fromLTRB(0, geo.road, w, size.height);
    c.drawRect(road, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF6A6F73), Color(0xFF4C5155)]).createShader(road));
    for (var x = 10.0; x < w; x += 54) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, geo.road + 20, 26, 3), const Radius.circular(1.5)), Paint()..color = const Color(0xCCF2EBC8));
    }
    _van(c);
    _stall(c);
    // Wires first, then poles.
    final wire = Paint()
      ..color = const Color(0xFF1B2024)
      ..strokeWidth = 1.4;
    for (var k = 0; k < 3; k++) {
      final y = geo.top + 28 + k * 6.0;
      final p = Path()..moveTo(M7ReportGeo.poleX(0) - 70, y + 4);
      for (var i = 0; i < 3; i++) {
        p.lineTo(M7ReportGeo.poleX(i), y);
        if (i < 2) p.quadraticBezierTo((M7ReportGeo.poleX(i) + M7ReportGeo.poleX(i + 1)) / 2, y + 7, M7ReportGeo.poleX(i + 1), y);
      }
      p.lineTo(M7ReportGeo.poleX(2) + 80, y + 4);
      c.drawPath(p, wire..style = PaintingStyle.stroke);
    }
    for (var i = 0; i < 3; i++) {
      _pole(c, i);
    }
  }

  void _pole(Canvas c, int i) {
    final x = M7ReportGeo.poleX(i);
    final g = geo.ground;
    final body = Rect.fromLTRB(x - 4, geo.top + 18, x + 4, g);
    c.drawRect(body, Paint()..shader = const LinearGradient(colors: [Color(0xFF8B8F93), Color(0xFFC9CCCF), Color(0xFF7A7E82)]).createShader(body));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 24, geo.top + 24, 48, 5), const Radius.circular(2)), Paint()..color = const Color(0xFF5A5F63));
    for (final dx in [-20.0, -4.0, 14.0]) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x + dx, geo.top + 16, 6, 9), const Radius.circular(2)), Paint()..color = const Color(0xFF7B5B3A));
    }
    // A plate: a blur from here (no digits), a dark teal face with two smudges.
    final p = geo.plate(i);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: p, width: 22, height: 13), const Radius.circular(2)), Paint()..color = const Color(0xFF2D6A74));
    final smudge = Paint()
      ..color = const Color(0x99F4F4F4)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    c.drawLine(p + const Offset(-7, -2), p + const Offset(7, -2), smudge);
    c.drawLine(p + const Offset(-6, 3), p + const Offset(4, 3), smudge);
  }

  void _van(Canvas c) {
    final v = geo.van;
    c.drawRRect(RRect.fromRectAndRadius(v, const Radius.circular(5)), Paint()..color = const Color(0xFFF2F2F2));
    c.drawRect(Rect.fromLTWH(v.left, v.top + 14, v.width, 6), Paint()..color = const Color(0xFFD93A2B));
    c.drawRect(Rect.fromLTWH(v.right - 18, v.top + 5, 14, 10), Paint()..color = const Color(0xFF7FB6D6));
    for (final dx in [14.0, v.width - 14]) {
      c.drawCircle(Offset(v.left + dx, v.bottom), 6, Paint()..color = const Color(0xFF222222));
      c.drawCircle(Offset(v.left + dx, v.bottom), 2.4, Paint()..color = const Color(0xFFBBBBBB));
    }
  }

  void _stall(Canvas c) {
    final s = geo.stall;
    c.drawRect(Rect.fromLTWH(s.left + 6, s.top + 22, s.width - 12, s.height - 22), Paint()..color = const Color(0xFFC79B63));
    c.drawRect(Rect.fromLTWH(s.left + 6, s.top + 22, s.width - 12, s.height - 22), Paint()
      ..color = const Color(0xFF6E4C26)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
    // Awning stripes.
    final aw = Path()
      ..moveTo(s.left, s.top + 24)
      ..lineTo(s.left + 10, s.top)
      ..lineTo(s.right - 10, s.top)
      ..lineTo(s.right, s.top + 24)
      ..close();
    c.drawPath(aw, Paint()..color = const Color(0xFFE8E0D0));
    for (var i = 0; i < 6; i += 2) {
      final x0 = s.left + i * (s.width / 6);
      c.drawPath(
          Path()
            ..moveTo(x0 + 1, s.top + 24)
            ..lineTo(x0 + 3 + 6, s.top)
            ..lineTo(x0 + 3 + 6 + s.width / 6, s.top)
            ..lineTo(x0 + 1 + s.width / 6, s.top + 24)
            ..close(),
          Paint()..color = const Color(0xFFD9503A));
    }
    // The wall clock.
    paintM7Clock(c, geo.wallClock, 15, rig.clockMin);
    // Counter with a kettle.
    c.drawRect(Rect.fromLTWH(s.left + 2, s.bottom - 26, s.width - 4, 6), Paint()..color = const Color(0xFF5A3A1A));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(s.left + 12, s.bottom - 40, 18, 14), const Radius.circular(3)), Paint()..color = const Color(0xFFB8BCC0));
    c.drawRect(Rect.fromLTWH(s.left + 30, s.bottom - 36, 8, 3), Paint()..color = const Color(0xFFB8BCC0));
  }

  @override
  bool shouldRepaint(M7StreetPainter old) => old.geo != geo || old.rig != rig;
}

// ============================================================================
// The accident (animated once, then kept)
// ============================================================================

class M7ActionPainter extends CustomPainter {
  M7ActionPainter({required this.geo, required this.look, required Animation<double> t, this.afterwards = false}) : _t = t, super(repaint: t);

  final M7ReportGeo geo;
  final M7Look look;
  final Animation<double> _t;

  /// Painted as the kept scene only (used by the stills' own painter too).
  final bool afterwards;

  @override
  void paint(Canvas c, Size size) {
    final t = afterwards ? m7ReplayEnd : _t.value;
    final g = geo.ground;
    final acc = look.acc;
    final px = M7ReportGeo.poleX(acc);
    final pillar = M7ReportGeo.pillarX(acc);
    final side = acc == 2 ? -1.0 : 1.0; // the pillar's side of the pole
    final h = 64.0;
    final footY = g - 2;

    // --- the pillar box and its door --------------------------------------------
    final doorOpen = _seg(t, 0.38, 0.46);
    _pillar(c, Offset(pillar, g), doorOpen, scorch: t >= 0.5);

    // --- the ladder -----------------------------------------------------------------
    final lx = px - side * 28;
    final ladderIn = _seg(t, 0.56, 0.62);
    final fall = _seg(t, 0.90, 0.97);
    if (ladderIn > 0) {
      c.save();
      c.translate(lx, g);
      // Leans on the pole; at the slip it swings away from the pole and lies down.
      final lean = _lerp(0.0, -side * 1.35, Curves.easeIn.transform(fall));
      c.rotate(lean);
      final topY = -(g - (geo.top + 40)) * 0.72;
      final topX = side * 22.0 * ladderIn;
      final rail = Paint()
        ..color = const Color(0xFFC98A33)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      c.drawLine(Offset(-4, 0), Offset(topX - 4, topY), rail);
      c.drawLine(Offset(4, 0), Offset(topX + 4, topY), rail);
      for (var k = 1; k < 8; k++) {
        final f = k / 8;
        c.drawLine(Offset(_lerp(-4, topX - 4, f), topY * f), Offset(_lerp(4, topX + 4, f), topY * f), Paint()
          ..color = const Color(0xFF8A5A1E)
          ..strokeWidth = 2);
      }
      c.restore();
    }

    // --- the worker ------------------------------------------------------------------
    final handX = px + (look.handR ? -14.0 : 14.0);
    final foreX = pillar + (look.foreR ? -20.0 : 20.0);
    final climb = _seg(t, 0.66, 0.84);
    Offset pos;
    var angL = 0.12, angR = 0.12, sit = false, face = 0.0;
    var tilt = 0.0;
    if (t < 0.30) {
      pos = Offset(handX, footY);
      final up = _seg(t, 0.04, 0.12);
      final a = _lerp(0.12, 2.35, up);
      if (look.handR) {
        angR = a;
      } else {
        angL = a;
      }
      face = look.handR ? 1 : -1;
    } else if (t < 0.40) {
      pos = Offset(_lerp(handX, foreX, Curves.easeInOut.transform(_seg(t, 0.30, 0.40))), footY);
      face = foreX > handX ? 1 : -1;
    } else if (t < 0.58) {
      pos = Offset(foreX, footY);
      final out = _seg(t, 0.40, 0.46);
      final a = _lerp(0.12, 1.7, out);
      if (look.foreR) {
        angR = a;
      } else {
        angL = a;
      }
      face = look.foreR ? 1 : -1;
    } else if (t < 0.66) {
      final lxw = lx + side * 3;
      pos = Offset(_lerp(foreX, lxw, Curves.easeInOut.transform(_seg(t, 0.58, 0.66))), footY);
      face = -side;
    } else if (t < 0.90) {
      final f = climb;
      final topY = -(g - (geo.top + 40)) * 0.72;
      pos = Offset(lx + side * 22 * 0.62 * f, footY + topY * 0.62 * f);
      angL = 2.2;
      angR = 2.2;
      face = side;
      if (t >= 0.84) {
        angL = 2.9;
        angR = 2.9;
      }
    } else if (t < 0.97) {
      final f = _seg(t, 0.90, 0.97);
      final topY = -(g - (geo.top + 40)) * 0.72;
      final start = Offset(lx + side * 22 * 0.62, footY + topY * 0.62);
      final end = Offset(lx - side * 34, footY);
      pos = Offset(_lerp(start.dx, end.dx, f), _lerp(start.dy, end.dy, Curves.easeIn.transform(f)));
      angL = 2.6 - 2.0 * f;
      angR = 2.6 - 2.0 * f;
      tilt = side * 0.9 * (1 - f);
      face = side;
    } else {
      pos = Offset(lx - side * 34, footY);
      sit = true;
      angL = 0.5;
      angR = 0.5;
      face = side;
    }
    final j = _person(c, foot: pos, h: h, vest: const Color(0xFFFF7A1A), angL: angL, angR: angR, sit: sit, face: face, patch: look.patch, tilt: tilt);
    // The hurt parts: the spark on the hand, the flash on the forearm, the ankle.
    if (t >= 0.08 && t < 0.28) {
      _spark(c, look.handR ? j.handR : j.handL, 13, t);
    }
    if (t >= 0.46 && t < 0.58) {
      final a = Curves.easeOut.transform(_seg(t, 0.46, 0.50)) * (1 - _seg(t, 0.54, 0.58));
      _burst(c, look.foreR ? j.midR + const Offset(6, 0) : j.midL - const Offset(6, 0), 30, a);
    }
    if (t >= 0.84 && t < 0.90) {
      _spark(c, j.handL, 12, t);
      _spark(c, j.handR, 12, t + 0.02);
    }
    if (t >= 0.97) {
      final a = look.ankleR ? j.ankleR : j.ankleL;
      c.drawCircle(a, 7, Paint()..shader = const RadialGradient(colors: [Color(0xCCFF3B30), Color(0x00FF3B30)]).createShader(Rect.fromCircle(center: a, radius: 7)));
      // He holds the ankle.
      c.drawLine(look.ankleR ? j.handR : j.handL, a, Paint()
        ..color = const Color(0xFFFF7A1A)
        ..strokeWidth = 3);
    }

    // --- the coworker (foreground) ----------------------------------------------------
    final cwX = (px + 66).clamp(30.0, 200.0);
    final crouch = t >= 0.97;
    _person(c, foot: Offset(cwX, geo.road + 36), h: 72, vest: const Color(0xFF2E7BD6), angL: crouch ? 0.9 : 0.15, angR: crouch ? 0.9 : 0.15, sit: crouch, face: -1, helmet: const Color(0xFFF2F2F2));

    // --- the tea man behind his counter ------------------------------------------------
    final tx = geo.stall.left + 62;
    final watchTea = look.tea;
    final turn = _seg(t, 0.06, 0.12);
    final teaFace = watchTea ? -turn : 0.0;
    _person(c, foot: Offset(tx, g - 22), h: 58, vest: const Color(0xFFE9E1CF), face: teaFace, away: !watchTea && turn > 0.5, angL: watchTea ? 0.1 : 0.5, angR: watchTea ? 0.1 : 0.5, helmet: const Color(0xFFF1EFE8), pants: const Color(0xFF6B5A44));
    c.drawRect(Rect.fromLTWH(geo.stall.left + 40, g - 30, 46, 8), Paint()..color = const Color(0xFF5A3A1A));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(geo.stall.left + 46, g - 40, 14, 11), const Radius.circular(2)), Paint()..color = const Color(0xFFB8BCC0));

    // --- the cyclist ---------------------------------------------------------------------
    final wy = geo.road + 20;
    final double cx;
    if (look.cyclist) {
      cx = _lerp(352, 196, Curves.easeOut.transform(_seg(t, 0.0, 0.14)));
    } else {
      cx = 352 - 400 * t;
    }
    _bike(c, Offset(cx, wy), watching: look.cyclist && t >= 0.12, t: t);
  }

  void _pillar(Canvas c, Offset base, double open, {required bool scorch}) {
    final body = Rect.fromLTWH(base.dx - 12, base.dy - 36, 24, 36);
    c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(2)), Paint()..color = const Color(0xFF5E7C5A));
    c.drawRRect(
        RRect.fromRectAndRadius(body, const Radius.circular(2)),
        Paint()
          ..color = const Color(0xFF2E3D2C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6);
    if (open > 0) {
      c.drawRect(Rect.fromLTWH(base.dx - 9, base.dy - 33, 18, 30), Paint()..color = const Color(0xFF1B1F1B));
      for (var i = 0; i < 3; i++) {
        c.drawRect(Rect.fromLTWH(base.dx - 7 + i * 6, base.dy - 28, 3, 20), Paint()..color = const Color(0xFFB87333));
      }
      // The door swung out.
      c.drawRect(Rect.fromLTWH(base.dx + 12, base.dy - 36, 9 * open, 36), Paint()..color = const Color(0xFF4B6648));
    }
    if (scorch) {
      c.drawCircle(Offset(base.dx, base.dy - 20), 11, Paint()..shader = const RadialGradient(colors: [Color(0xAA000000), Color(0x00000000)]).createShader(Rect.fromCircle(center: Offset(base.dx, base.dy - 20), radius: 11)));
    }
  }

  void _bike(Canvas c, Offset base, {required bool watching, required double t}) {
    final wheel = Paint()
      ..color = const Color(0xFF1E1E1E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    c.drawCircle(base + const Offset(-16, 0), 11, wheel);
    c.drawCircle(base + const Offset(16, 0), 11, wheel);
    final frame = Paint()
      ..color = const Color(0xFFB0302A)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    c.drawLine(base + const Offset(-16, 0), base + const Offset(-2, -16), frame);
    c.drawLine(base + const Offset(-2, -16), base + const Offset(16, 0), frame);
    c.drawLine(base + const Offset(-2, -16), base + const Offset(-6, -3), frame);
    c.drawLine(base + const Offset(-6, -3), base + const Offset(-16, 0), frame);
    c.drawLine(base + const Offset(10, -14), base + const Offset(16, 0), frame);
    _person(c, foot: base + Offset(-4, 4 + (watching ? 6 : 0)), h: 58, vest: const Color(0xFF3F8F5A), angL: 1.0, angR: 1.0, face: watching ? -1 : -0.2, away: false, helmet: const Color(0xFFFFFFFF), tilt: 0);
  }

  @override
  bool shouldRepaint(M7ActionPainter old) => old.geo != geo || old.look != look || old.afterwards != afterwards;
}

// ============================================================================
// Stills, lens, clock close-up
// ============================================================================

/// One still of the replay (beat 0 shock, 1 flash, 2 fall) in a small frame.
class M7StillPainter extends CustomPainter {
  const M7StillPainter({required this.beat, required this.look});

  final int beat;
  final M7Look look;

  @override
  void paint(Canvas c, Size size) {
    final r = Offset.zero & size;
    c.drawRect(r, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFAFD5EA), Color(0xFFEFE3C4)]).createShader(r));
    final g = size.height - 12;
    c.drawRect(Rect.fromLTWH(0, g, size.width, 12), Paint()..color = const Color(0xFF7C8B5C));
    final px = size.width * 0.62;
    // The pole.
    c.drawRect(Rect.fromLTRB(px - 3, 4, px + 3, g), Paint()..color = const Color(0xFF9DA1A5));
    final h = size.height * 0.62;
    final foot = Offset(size.width * 0.34, g);
    switch (beat) {
      case 0:
        final j = _person(c, foot: foot, h: h, vest: const Color(0xFFFF7A1A), angR: look.handR ? 2.2 : 0.12, angL: look.handR ? 0.12 : -0.0 + 2.2, face: 1);
        _spark(c, look.handR ? j.handR : j.handL, 8, 0.3);
      case 1:
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.66, g - 26, 16, 26), const Radius.circular(2)), Paint()..color = const Color(0xFF5E7C5A));
        c.drawRect(Rect.fromLTWH(size.width * 0.66 + 3, g - 23, 10, 20), Paint()..color = const Color(0xFF1B1F1B));
        final j = _person(c, foot: foot, h: h, vest: const Color(0xFFFF7A1A), angR: look.foreR ? 1.6 : 0.12, angL: look.foreR ? 0.12 : 1.6, face: 1);
        _burst(c, look.foreR ? j.midR + const Offset(5, 0) : j.midL, 17, 0.95);
      default:
        c.save();
        c.translate(size.width * 0.5, g);
        c.rotate(-0.9);
        c.drawLine(const Offset(-3, 0), Offset(-3, -h * 1.05), Paint()
          ..color = const Color(0xFFC98A33)
          ..strokeWidth = 2.4);
        c.drawLine(const Offset(3, 0), Offset(3, -h * 1.05), Paint()
          ..color = const Color(0xFFC98A33)
          ..strokeWidth = 2.4);
        c.restore();
        _person(c, foot: Offset(size.width * 0.3, g - 10), h: h * 0.9, vest: const Color(0xFFFF7A1A), angR: 2.3, angL: 2.3, face: 1, tilt: 1.0);
        _spark(c, Offset(size.width * 0.5, g - h * 0.7), 8, 0.6);
    }
    c.drawRect(r.deflate(0.8), Paint()
      ..color = const Color(0xFF3A2A16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6);
  }

  @override
  bool shouldRepaint(M7StillPainter old) => old.beat != beat || old.look != look;
}

/// The lens over a number plate: the number, readable.
class M7LensPainter extends CustomPainter {
  const M7LensPainter({required this.number});
  final int number;

  @override
  void paint(Canvas c, Size size) {
    final ctr = size.center(Offset.zero);
    final r = math.min(size.width, size.height) / 2 - 3;
    c.drawCircle(ctr, r, Paint()..color = const Color(0xFFE8F4F8));
    final plate = Rect.fromCenter(center: ctr, width: r * 1.7, height: r * 0.95);
    c.drawRRect(RRect.fromRectAndRadius(plate, const Radius.circular(4)), Paint()..color = const Color(0xFF2D6A74));
    c.drawRRect(
        RRect.fromRectAndRadius(plate.deflate(2), const Radius.circular(3)),
        Paint()
          ..color = const Color(0xFFF4F4F4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
    _text(c, '$number', ctr, r * 0.46, const Color(0xFFF7F7F7), maxWidth: plate.width - 12);
    c.drawCircle(
        ctr,
        r,
        Paint()
          ..color = const Color(0xFF3A2A16)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4);
    c.drawCircle(ctr - Offset(r * 0.45, r * 0.5), r * 0.16, Paint()..color = const Color(0x66FFFFFF));
  }

  @override
  bool shouldRepaint(M7LensPainter old) => old.number != number;
}

/// A clock for the dial and for the replay's wall-clock close-up.
class M7ClockPainter extends CustomPainter {
  const M7ClockPainter({required this.minutes, this.plain = false});
  final int minutes;
  final bool plain;

  @override
  void paint(Canvas c, Size size) => paintM7Clock(c, size.center(Offset.zero), math.min(size.width, size.height) / 2 - 3, minutes, plain: plain);

  @override
  bool shouldRepaint(M7ClockPainter old) => old.minutes != minutes || old.plain != plain;
}

// ============================================================================
// The body outline
// ============================================================================

/// The zones on a 150 x 210 outline (screen sides).
abstract final class M7BodyGeo {
  static const size = Size(150, 210);

  static const Map<M7Zone, Rect> zones = {
    M7Zone.head: Rect.fromLTWH(54, 4, 42, 44),
    M7Zone.chest: Rect.fromLTWH(47, 54, 56, 70),
    M7Zone.forearmL: Rect.fromLTWH(4, 84, 38, 50),
    M7Zone.forearmR: Rect.fromLTWH(108, 84, 38, 50),
    M7Zone.handL: Rect.fromLTWH(0, 136, 38, 38),
    M7Zone.handR: Rect.fromLTWH(112, 136, 38, 38),
    M7Zone.ankleL: Rect.fromLTWH(38, 168, 36, 38),
    M7Zone.ankleR: Rect.fromLTWH(76, 168, 36, 38),
  };
}

class M7BodyPainter extends CustomPainter {
  const M7BodyPainter({required this.marks, required this.selected});

  final Map<M7Zone, M7Kind> marks;
  final M7Zone? selected;

  static Color kindColor(M7Kind k) => switch (k) {
        M7Kind.shock => const Color(0xFFF2C21E),
        M7Kind.burn => const Color(0xFFE5502A),
        M7Kind.sprain => const Color(0xFF3E7BD6),
      };

  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.scale(size.width / 150, size.height / 210);
    final skin = Paint()..color = const Color(0xFFE6B891);
    final line = Paint()
      ..color = const Color(0xFF6A4A2A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final vest = Paint()..color = const Color(0xFFFF9A3C);
    // Legs.
    for (final dx in [-1.0, 1.0]) {
      c.drawLine(Offset(75 + dx * 12, 124), Offset(75 + dx * 22, 190), Paint()
        ..color = const Color(0xFF3B4C6E)
        ..strokeWidth = 17
        ..strokeCap = StrokeCap.round);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(75 + dx * 24, 198), width: 24, height: 10), const Radius.circular(4)), Paint()..color = const Color(0xFF2A2A2A));
    }
    // Arms out and down.
    for (final dx in [-1.0, 1.0]) {
      c.drawLine(Offset(75 + dx * 28, 62), Offset(75 + dx * 59, 128), Paint()
        ..color = const Color(0xFFFF9A3C)
        ..strokeWidth = 13
        ..strokeCap = StrokeCap.round);
      c.drawCircle(Offset(75 + dx * 62, 148), 10, skin);
      c.drawLine(Offset(75 + dx * 59, 128), Offset(75 + dx * 62, 148), Paint()
        ..color = const Color(0xFFE6B891)
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round);
    }
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(48, 54, 54, 76), const Radius.circular(10)), vest);
    c.drawRect(const Rect.fromLTWH(48, 90, 54, 6), Paint()..color = const Color(0xDDF4F4F4));
    c.drawCircle(const Offset(75, 28), 18, skin);
    c.drawArc(Rect.fromCircle(center: const Offset(75, 26), radius: 20), math.pi, math.pi, true, Paint()..color = const Color(0xFFFFD21E));
    c.drawCircle(const Offset(69, 30), 1.8, Paint()..color = const Color(0xFF1B1B1B));
    c.drawCircle(const Offset(81, 30), 1.8, Paint()..color = const Color(0xFF1B1B1B));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(48, 54, 54, 76), const Radius.circular(10)), line);
    // The marks the player made.
    for (final e in marks.entries) {
      final z = M7BodyGeo.zones[e.key]!.deflate(3);
      final col = kindColor(e.value);
      c.drawOval(z, Paint()..color = col.withValues(alpha: 0.35));
      c.drawOval(
          z,
          Paint()
            ..color = col
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.6);
      final cc = z.center;
      switch (e.value) {
        case M7Kind.shock:
          c.drawPath(
              Path()
                ..moveTo(cc.dx + 2, cc.dy - 9)
                ..lineTo(cc.dx - 4, cc.dy + 1)
                ..lineTo(cc.dx + 1, cc.dy + 1)
                ..lineTo(cc.dx - 2, cc.dy + 9)
                ..lineTo(cc.dx + 5, cc.dy - 2)
                ..lineTo(cc.dx, cc.dy - 2)
                ..close(),
              Paint()..color = const Color(0xFF3A2A16));
        case M7Kind.burn:
          c.drawCircle(cc, 5, Paint()..color = const Color(0xFF7A1F10));
        case M7Kind.sprain:
          c.drawCircle(
              cc,
              6,
              Paint()
                ..color = const Color(0xFF1F3F8F)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2.6);
      }
    }
    final s = selected;
    if (s != null) {
      final z = M7BodyGeo.zones[s]!;
      c.drawRRect(
          RRect.fromRectAndRadius(z, const Radius.circular(8)),
          Paint()
            ..color = const Color(0xFF1F3F8F)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4);
    }
    c.restore();
  }

  @override
  bool shouldRepaint(M7BodyPainter old) => !mapEquals(old.marks, marks) || old.selected != selected;
}
