import 'dart:math' as math;

import 'package:flutter/material.dart';

// The drawn world of lesson 4.1 কাজ 2 "পোলের ওপর বদল" (m4_insulator_swap.dart):
// the top of a PCC pole seen from the trainee's height — the morning sky, the
// line running away over the paddy to the next pole, our steel cross-arm with
// three phases on it: brown porcelain pin insulators (a line pole) or strain
// strings of brown discs (a tension pole). The line is dead: an earth set is
// clamped on all three conductors with its lead down the pole (shutdown, PTW
// and earth come before the work — কাজ 1). The trainee is strapped to the
// pole in his helmet and full-body harness, the lanyard anchored above the
// arm. The tools show on the faulty phase as he works: the rope sling, the
// spanner's work (insulator off, the bare pin — rusty or new), the new
// insulator and its binding; on a tension pole the come-along and the
// turnbuckle, the slack string, the gap, the new disc and its split pin.
// Code-drawn, gradients, no bitmaps, no text. Design space 360 wide.

/// Pin insulators on a line pole, or strain (disc) strings on a tension pole.
enum M4InsulatorSwapKind { pin, disc }

/// What is wrong with an insulator (the lesson: mechanical crack or
/// electrical puncture — check both).
enum M4InsulatorSwapDamage { crack, puncture }

/// Where things are (design px, 360 wide).
@immutable
class M4InsulatorSwapGeo {
  const M4InsulatorSwapGeo._(this.height, this.topY);

  factory M4InsulatorSwapGeo.forScene(double height, double inset) =>
      M4InsulatorSwapGeo._(height, (height * 0.27 + inset * 0.2).clamp(170.0, 260.0));

  final double height;

  /// The pole's top.
  final double topY;

  /// The pole's axis.
  static const px = 204.0;

  double get armY => topY + 46;
  double get horizonY => armY + 150;

  /// The three phases along the arm (left → right).
  static const phaseX = [62.0, 136.0, 300.0];

  double get armLeft => 30;
  double get armRight => 336;

  /// The next pole down the line: the conductors run to it.
  Offset get vanish => Offset(22, horizonY - 26);

  /// The pin insulator's base on the arm and its head (the conductor's groove).
  Offset pinBase(int i) => Offset(phaseX[i], armY - 4);
  Offset pinHead(int i) => Offset(phaseX[i], armY - 52);

  /// A strain string: from its shackle under the arm towards the next pole.
  Offset strainFrom(int i) => Offset(phaseX[i], armY + 6);
  Offset strainDir(int i) {
    final d = vanish - strainFrom(i);
    return d / d.distance;
  }

  static const strainLen = 92.0;
  Offset strainTo(int i) => strainFrom(i) + strainDir(i) * strainLen;

  /// How far along its string disc [k] (0 at the arm) sits.
  static double discT(int k) => (20 + 25.0 * k) / strainLen;

  /// The centre of disc [k] in string [i].
  Offset discAt(int i, int k) => Offset.lerp(strainFrom(i), strainTo(i), discT(k))!;

  /// Where the conductor leaves phase [i] (head or strain clamp).
  Offset wireAt(M4InsulatorSwapKind kind, int i) => kind == M4InsulatorSwapKind.pin ? pinHead(i) : strainTo(i);

  /// The tap area of phase [i] (the insulator with its conductor).
  Rect phaseHit(M4InsulatorSwapKind kind, int i) => kind == M4InsulatorSwapKind.pin
      ? Rect.fromCenter(center: Offset(phaseX[i], armY - 30), width: 60, height: 76)
      : Rect.fromPoints(strainFrom(i), strainTo(i)).inflate(14);

  /// A point to tap on phase [i] (tests, rings).
  Offset phaseTap(M4InsulatorSwapKind kind, int i) => phaseHit(kind, i).center;

  /// The trainee on the pole: left of the axis, his chest at the arm.
  Rect get trainee => Rect.fromLTWH(px - 64, armY + 8, 62, 124);

  /// Where the lanyard is anchored (the pole above the arm).
  Offset get anchor => Offset(px, armY - 30);

  @override
  bool operator ==(Object other) => other is M4InsulatorSwapGeo && other.height == height && other.topY == topY;

  @override
  int get hashCode => Object.hash(height, topY);
}

/// What the pole top shows now.
@immutable
class M4InsulatorSwapView {
  const M4InsulatorSwapView({
    required this.kind,
    required this.bad,
    required this.damage,
    this.discBad = 1,
    this.bound = true,
    this.roped = false,
    this.oldOff = false,
    this.rusty = false,
    this.pinNew = false,
    this.newOn = false,
    this.newBound = false,
    this.rigOn = false,
    this.takenUp = false,
    this.discOut = false,
    this.newDisc = false,
    this.pinned = false,
    this.released = false,
  });

  final M4InsulatorSwapKind kind;

  /// The faulty phase and what is wrong with it.
  final int bad;
  final M4InsulatorSwapDamage damage;

  /// The faulty disc in its string (tension pole).
  final int discBad;

  // Pin pole.
  final bool bound;
  final bool roped;
  final bool oldOff;
  final bool rusty;
  final bool pinNew;
  final bool newOn;
  final bool newBound;

  // Tension pole.
  final bool rigOn;
  final bool takenUp;
  final bool discOut;
  final bool newDisc;
  final bool pinned;
  final bool released;

  @override
  bool operator ==(Object other) =>
      other is M4InsulatorSwapView &&
      other.kind == kind &&
      other.bad == bad &&
      other.damage == damage &&
      other.discBad == discBad &&
      other.bound == bound &&
      other.roped == roped &&
      other.oldOff == oldOff &&
      other.rusty == rusty &&
      other.pinNew == pinNew &&
      other.newOn == newOn &&
      other.newBound == newBound &&
      other.rigOn == rigOn &&
      other.takenUp == takenUp &&
      other.discOut == discOut &&
      other.newDisc == newDisc &&
      other.pinned == pinned &&
      other.released == released;

  @override
  int get hashCode => Object.hash(kind, bad, damage, discBad, bound, roped, oldOff, rusty, pinNew, newOn, newBound, rigOn, takenUp, discOut,
      newDisc, pinned, released);
}

const _porcelain = Color(0xFF8A4B2A);
const _porcelainLit = Color(0xFFB97A50);
const _porcelainDark = Color(0xFF5E301A);
const _steel = Color(0xFF6E757B);
const _wire = Color(0xFF2B3036);

/// Draws a porcelain pin insulator standing at [base], [s] times the scene
/// size (the scene 1, the spare tray larger), with [damage] if any.
void m4InsulatorSwapPaintPin(Canvas c, Offset base, double s, {M4InsulatorSwapDamage? damage, bool binding = false}) {
  // Three sheds, wide at the bottom, then the neck and the grooved head.
  final sheds = [(0.0, 34.0), (14.0, 28.0), (26.0, 22.0)];
  for (final (dy, w) in sheds) {
    final y = base.dy - (6 + dy) * s;
    final r = Rect.fromCenter(center: Offset(base.dx, y), width: w * s, height: 10 * s);
    c.drawOval(
        r,
        Paint()
          ..shader = const LinearGradient(colors: [_porcelainDark, _porcelainLit, _porcelain], stops: [0, 0.4, 1]).createShader(r));
    c.drawOval(r.deflate(0.8 * s).translate(0, -1.4 * s), Paint()..color = _porcelain.withValues(alpha: 0.85));
  }
  final neck = Rect.fromLTRB(base.dx - 7 * s, base.dy - 48 * s, base.dx + 7 * s, base.dy - 8 * s);
  c.drawRRect(
      RRect.fromRectAndRadius(neck, Radius.circular(3 * s)),
      Paint()..shader = const LinearGradient(colors: [_porcelainDark, _porcelainLit, _porcelain], stops: [0, 0.45, 1]).createShader(neck));
  // The head with its groove.
  final head = Rect.fromCenter(center: Offset(base.dx, base.dy - 48 * s), width: 18 * s, height: 9 * s);
  c.drawOval(head, Paint()..color = _porcelain);
  c.drawOval(Rect.fromCenter(center: head.center.translate(-2 * s, -1.5 * s), width: 6 * s, height: 2.4 * s), Paint()..color = const Color(0x66FFE2C4));
  c.drawLine(Offset(base.dx - 8 * s, base.dy - 46 * s), Offset(base.dx + 8 * s, base.dy - 46 * s),
      Paint()
        ..color = _porcelainDark
        ..strokeWidth = 1.2 * s);
  switch (damage) {
    case null:
      break;
    case M4InsulatorSwapDamage.crack:
      final p = Path()
        ..moveTo(base.dx - 4 * s, base.dy - 50 * s)
        ..lineTo(base.dx + 1 * s, base.dy - 40 * s)
        ..lineTo(base.dx - 3 * s, base.dy - 31 * s)
        ..lineTo(base.dx + 5 * s, base.dy - 22 * s)
        ..lineTo(base.dx + 1 * s, base.dy - 14 * s)
        ..lineTo(base.dx + 9 * s, base.dy - 6 * s);
      c.drawPath(
          p,
          Paint()
            ..color = const Color(0xFF1A0E08)
            ..strokeWidth = 1.9 * s
            ..style = PaintingStyle.stroke
            ..strokeJoin = StrokeJoin.miter);
      // A chip off the bottom shed.
      c.drawPath(
          Path()
            ..moveTo(base.dx + 10 * s, base.dy - 10 * s)
            ..lineTo(base.dx + 17 * s, base.dy - 7 * s)
            ..lineTo(base.dx + 12 * s, base.dy - 3 * s)
            ..close(),
          Paint()..color = const Color(0xFFE9DCCB));
    case M4InsulatorSwapDamage.puncture:
      // A burnt puncture hole with scorch tracks down the sheds.
      final at = Offset(base.dx + 2 * s, base.dy - 33 * s);
      c.drawCircle(at, 6.5 * s, Paint()..color = const Color(0x99151515));
      c.drawCircle(at, 3 * s, Paint()..color = const Color(0xFF050505));
      final track = Paint()
        ..color = const Color(0xCC1B1B1B)
        ..strokeWidth = 1.4 * s
        ..style = PaintingStyle.stroke;
      c.drawPath(
          Path()
            ..moveTo(at.dx, at.dy + 3 * s)
            ..quadraticBezierTo(at.dx - 6 * s, at.dy + 12 * s, at.dx - 2 * s, at.dy + 22 * s)
            ..moveTo(at.dx + 2 * s, at.dy + 3 * s)
            ..quadraticBezierTo(at.dx + 9 * s, at.dy + 13 * s, at.dx + 6 * s, at.dy + 25 * s),
          track);
  }
  if (binding) {
    // The binding wire wrapped round the head and along the conductor.
    final bw = Paint()
      ..color = const Color(0xFFC9CED3)
      ..strokeWidth = 1.5 * s
      ..style = PaintingStyle.stroke;
    for (var k = -3; k <= 3; k++) {
      final x = base.dx + k * 3.4 * s;
      c.drawLine(Offset(x - 1.5 * s, base.dy - 53 * s), Offset(x + 1.5 * s, base.dy - 44 * s), bw);
    }
    for (final dir in const [-1.0, 1.0]) {
      for (var k = 0; k < 4; k++) {
        final x = base.dx + dir * (13 + k * 3.2) * s;
        c.drawLine(Offset(x, base.dy - 54 * s), Offset(x + dir * 1.6 * s, base.dy - 47 * s), bw);
      }
    }
  }
}

/// Draws one brown disc (cap and pin) at [at], its face turned by [angle].
void m4InsulatorSwapPaintDisc(Canvas c, Offset at, double angle, double s, {M4InsulatorSwapDamage? damage, bool pin = false}) {
  c.save();
  c.translate(at.dx, at.dy);
  c.rotate(angle);
  final face = Rect.fromCenter(center: Offset.zero, width: 9 * s, height: 30 * s);
  c.drawOval(face, Paint()..shader = const LinearGradient(colors: [_porcelainDark, _porcelainLit, _porcelain], stops: [0, 0.35, 1]).createShader(face));
  c.drawOval(Rect.fromCenter(center: Offset(-1.2 * s, -4 * s), width: 2.4 * s, height: 12 * s), Paint()..color = const Color(0x66FFE2C4));
  // The steel cap and the pin out the other side.
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(4.5 * s, 0), width: 5 * s, height: 9 * s), Radius.circular(1.5 * s)),
      Paint()..color = const Color(0xFF8B9298));
  c.drawLine(Offset(-6 * s, 0), Offset(-3 * s, 0), Paint()
    ..color = const Color(0xFF5A6066)
    ..strokeWidth = 2.2 * s);
  switch (damage) {
    case null:
      break;
    case M4InsulatorSwapDamage.crack:
      c.drawPath(
          Path()
            ..moveTo(-1 * s, -14 * s)
            ..lineTo(1.5 * s, -6 * s)
            ..lineTo(-1.5 * s, 1 * s)
            ..lineTo(1.5 * s, 8 * s)
            ..lineTo(-0.5 * s, 14 * s),
          Paint()
            ..color = const Color(0xFF1A0E08)
            ..strokeWidth = 1.6 * s
            ..style = PaintingStyle.stroke);
    case M4InsulatorSwapDamage.puncture:
      c.drawCircle(Offset(0, -6 * s), 4 * s, Paint()..color = const Color(0x99151515));
      c.drawCircle(Offset(0, -6 * s), 1.8 * s, Paint()..color = const Color(0xFF050505));
      c.drawLine(Offset(0, -3 * s), Offset(1 * s, 9 * s), Paint()
        ..color = const Color(0xCC1B1B1B)
        ..strokeWidth = 1.2 * s);
  }
  if (pin) {
    // The split pin through the cap, its legs bent (secured).
    final sp = Paint()
      ..color = const Color(0xFFE2B33C)
      ..strokeWidth = 1.4 * s
      ..style = PaintingStyle.stroke;
    c.drawLine(Offset(4.5 * s, -7 * s), Offset(4.5 * s, 7 * s), sp);
    c.drawLine(Offset(4.5 * s, 7 * s), Offset(7.5 * s, 9.5 * s), sp);
    c.drawLine(Offset(4.5 * s, 7 * s), Offset(1.5 * s, 9.5 * s), sp);
  }
  c.restore();
}

/// The place: sky, land, the next pole, our pole and its cross-arm, the
/// conductors, the earth set, the three phases and the work on the faulty one.
class M4InsulatorSwapPainter extends CustomPainter {
  const M4InsulatorSwapPainter({required this.geo, required this.view, required this.seed});
  final M4InsulatorSwapGeo geo;
  final M4InsulatorSwapView view;
  final int seed;

  bool get _pin => view.kind == M4InsulatorSwapKind.pin;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final hz = geo.horizonY;
    // --- sky ---------------------------------------------------------------------
    final sky = Rect.fromLTWH(0, 0, w, hz + 4);
    c.drawRect(
        sky,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4F8FCB), Color(0xFF9CC6E8), Color(0xFFF1E7CC)],
            stops: [0, 0.62, 1],
          ).createShader(sky));
    final sun = Offset(w * 0.8, hz * 0.32);
    c.drawCircle(sun, 90, Paint()..shader = const RadialGradient(colors: [Color(0x80FFF4D2), Color(0x00FFF4D2)]).createShader(Rect.fromCircle(center: sun, radius: 90)));
    c.drawCircle(sun, 13, Paint()..color = const Color(0xFFFFF6DC));
    final rnd = math.Random(seed);
    final cloud = Paint()..color = const Color(0xCCFFFFFF);
    for (var i = 0; i < 3; i++) {
      final x = 40 + rnd.nextDouble() * 280;
      final y = 40 + rnd.nextDouble() * (hz * 0.4);
      final r = 10 + rnd.nextDouble() * 10;
      c.drawCircle(Offset(x, y), r, cloud);
      c.drawCircle(Offset(x + r, y + 4), r * 0.8, cloud);
      c.drawCircle(Offset(x - r, y + 5), r * 0.7, cloud);
    }
    // --- far land: tree line, village, paddy ----------------------------------------
    final trees = Path()..moveTo(0, hz);
    for (var x = 0.0; x <= w + 14; x += 14) {
      final bump = 9 + 5 * math.sin(x * 0.06 + seed) + 3 * math.sin(x * 0.19 + 1.3);
      trees.quadraticBezierTo(x + 7, hz - bump - 6, x + 14, hz - bump * 0.5);
    }
    trees
      ..lineTo(w, hz + 3)
      ..lineTo(0, hz + 3)
      ..close();
    c.drawPath(trees, Paint()..color = const Color(0xFF4C7752));
    for (final (x, sz) in const [(120.0, 0.8), (250.0, 1.0), (320.0, 0.7)]) {
      final b = Rect.fromLTWH(x, hz - 10 * sz, 20 * sz, 10 * sz);
      c.drawRect(b, Paint()..color = const Color(0xFFB59A74));
      c.drawPath(
          Path()
            ..moveTo(x - 3 * sz, hz - 9 * sz)
            ..lineTo(x + 10 * sz, hz - 17 * sz)
            ..lineTo(x + 23 * sz, hz - 9 * sz)
            ..close(),
          Paint()..color = const Color(0xFF8E979E));
    }
    final field = Rect.fromLTRB(0, hz, w, size.height);
    c.drawRect(
        field,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF93BD63), Color(0xFF6A9A43), Color(0xFF557F35)],
          ).createShader(field));
    final bund = Paint()
      ..color = const Color(0x40765A30)
      ..strokeWidth = 1.4;
    for (var i = 1; i < 8; i++) {
      final y = hz + (size.height - hz) * (i / 8) * (i / 8);
      c.drawLine(Offset(0, y), Offset(w, y + 6), bund);
    }
    // A village road far below.
    c.drawPath(
        Path()
          ..moveTo(w * 0.62, hz)
          ..lineTo(w * 0.66, hz)
          ..lineTo(w * 0.98, size.height)
          ..lineTo(w * 0.78, size.height)
          ..close(),
        Paint()..color = const Color(0xFFB39C76));

    // --- the next pole down the line -----------------------------------------------
    _nextPole(c);

    // --- our pole -----------------------------------------------------------------------
    _pole(c, size);

    // --- conductors -----------------------------------------------------------------
    final v = geo.vanish;
    for (var i = 0; i < 3; i++) {
      final from = _wireEnd(i);
      // Away to the next pole (thin, sagging a little).
      c.drawPath(
          Path()
            ..moveTo(from.dx, from.dy)
            ..quadraticBezierTo((from.dx + v.dx) / 2, (from.dy + v.dy) / 2 + 10, v.dx + (i - 1) * 5, v.dy),
          Paint()
            ..color = _wire
            ..strokeWidth = 1.6
            ..style = PaintingStyle.stroke);
      // Towards us, off the top right (thick: close).
      final d = from - v;
      final back = from + d / d.distance * 260;
      c.drawLine(from, back, Paint()
        ..color = _wire
        ..strokeWidth = 2.8);
    }

    // --- the earth set on the three conductors ------------------------------------------
    _earth(c);

    // --- the phases ---------------------------------------------------------------------
    for (var i = 0; i < 3; i++) {
      if (_pin) {
        _pinPhase(c, i);
      } else {
        _discPhase(c, i);
      }
    }
  }

  /// Where the conductor of phase [i] sits now (lifted on the rope while the
  /// insulator is off).
  Offset _wireEnd(int i) {
    final p = geo.wireAt(view.kind, i);
    if (_pin && i == view.bad && view.oldOff && !view.newOn) return p.translate(0, -8);
    if (!_pin && i == view.bad && view.takenUp && !view.released) return p.translate(2, -2);
    return p;
  }

  void _nextPole(Canvas c) {
    final v = geo.vanish;
    final base = Offset(v.dx + 4, geo.horizonY + 30);
    c.drawPath(
        Path()
          ..moveTo(base.dx - 2.4, base.dy)
          ..lineTo(v.dx - 1.2, v.dy - 4)
          ..lineTo(v.dx + 1.2, v.dy - 4)
          ..lineTo(base.dx + 2.4, base.dy)
          ..close(),
        Paint()..color = const Color(0xFF9B9890));
    c.drawRect(Rect.fromLTWH(v.dx - 9, v.dy + 1, 18, 2), Paint()..color = const Color(0xFF70757A));
    for (var i = 0; i < 3; i++) {
      c.drawRect(Rect.fromCenter(center: Offset(v.dx + (i - 1) * 5, v.dy - 1), width: 2.2, height: 3.5), Paint()..color = _porcelain);
    }
  }

  void _pole(Canvas c, Size size) {
    const px = M4InsulatorSwapGeo.px;
    final top = geo.topY;
    final bottom = size.height + 4;
    const half0 = 12.0;
    final half1 = 8.0 + (bottom - top) * 0.012;
    final body = Path()
      ..moveTo(px - half0 - (half1 - 8), bottom)
      ..lineTo(px - 8, top)
      ..lineTo(px + 8, top)
      ..lineTo(px + half0 + (half1 - 8), bottom)
      ..close();
    c.drawPath(
        body,
        Paint()
          ..shader = const LinearGradient(colors: [Color(0xFF9C988E), Color(0xFFD0CCC1), Color(0xFF8E8A80)], stops: [0, 0.45, 1])
              .createShader(Rect.fromLTRB(px - half1 - 6, top, px + half1 + 6, bottom)));
    // PCC texture: a few form lines.
    final form = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 1;
    for (var y = top + 40; y < bottom; y += 46) {
      c.drawLine(Offset(px - 6, y), Offset(px + 6, y + 2), form);
    }
    // The pole cap.
    c.drawRect(Rect.fromLTWH(px - 9, top - 4, 18, 5), Paint()..color = const Color(0xFF7D7A72));
    // The steel cross-arm (channel) with its clamp and braces.
    final ay = geo.armY;
    c.drawRect(Rect.fromLTRB(geo.armLeft, ay - 5, geo.armRight, ay + 5), Paint()..color = _steel);
    c.drawRect(Rect.fromLTRB(geo.armLeft, ay - 5, geo.armRight, ay - 3), Paint()..color = const Color(0xFF9AA1A7));
    c.drawRect(Rect.fromLTRB(geo.armLeft, ay + 3, geo.armRight, ay + 5), Paint()..color = const Color(0xFF51575C));
    final brace = Paint()
      ..color = _steel
      ..strokeWidth = 3.2;
    c.drawLine(Offset(px - 72, ay + 4), Offset(px - 7, ay + 50), brace);
    c.drawLine(Offset(px + 72, ay + 4), Offset(px + 7, ay + 50), brace);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(px, ay), width: 26, height: 16), const Radius.circular(2)),
        Paint()..color = const Color(0xFF555C62));
    for (final dx in const [-8.0, 8.0]) {
      c.drawCircle(Offset(px + dx, ay), 2, Paint()..color = const Color(0xFFB8BEC4));
    }
    // The danger plate lower down.
    final dp = Rect.fromLTWH(px - 9, ay + 150, 18, 16);
    c.drawRect(dp, Paint()..color = const Color(0xFFF2EEE2));
    c.drawRect(Rect.fromLTWH(dp.left + 2, dp.top + 2, 14, 3), Paint()..color = const Color(0xFFC0392B));
  }

  void _earth(Canvas c) {
    // A clamp on each conductor (towards us), the leads joining and running
    // down the pole to the earth spike far below.
    final lead = Paint()
      ..color = const Color(0xFFB87333)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final join = Offset(M4InsulatorSwapGeo.px + 14, geo.armY + 64);
    final v = geo.vanish;
    for (var i = 0; i < 3; i++) {
      final from = geo.wireAt(view.kind, i);
      final d = from - v;
      final at = from + d / d.distance * 34;
      c.drawPath(
          Path()
            ..moveTo(at.dx, at.dy)
            ..quadraticBezierTo((at.dx + join.dx) / 2, math.max(at.dy, join.dy) + 16, join.dx, join.dy),
          lead);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: at, width: 9, height: 8), const Radius.circular(2)), Paint()..color = const Color(0xFF2E9A44));
      c.drawRect(Rect.fromCenter(center: at.translate(0, 1), width: 9, height: 2.2), Paint()..color = const Color(0xFFF4D03F));
    }
    c.drawLine(join, Offset(join.dx + 4, geo.height + 10), lead..strokeWidth = 2.2);
  }

  void _pinPhase(Canvas c, int i) {
    final base = geo.pinBase(i);
    final faulty = i == view.bad;
    final steel = Paint()
      ..shader = const LinearGradient(colors: [Color(0xFF7D848A), Color(0xFFC4CACF), Color(0xFF6E757B)]).createShader(Rect.fromLTRB(base.dx - 4, base.dy - 30, base.dx + 4, base.dy));
    if (faulty && view.oldOff && !view.newOn) {
      // The bare pin: rusty, or a new one.
      final rust = view.rusty && !view.pinNew;
      final pin = Rect.fromLTRB(base.dx - 3.5, base.dy - 30, base.dx + 3.5, base.dy + 2);
      c.drawRRect(RRect.fromRectAndRadius(pin, const Radius.circular(2)), rust ? (Paint()..color = const Color(0xFF8B4A22)) : steel);
      if (rust) {
        final flake = Paint()..color = const Color(0xFFC76B2C);
        for (final (dx, dy) in const [(-2.0, -24.0), (1.5, -17.0), (-1.0, -9.0), (2.0, -4.0)]) {
          c.drawCircle(Offset(base.dx + dx, base.dy + dy), 1.6, flake);
        }
      }
      // The thread at the pin's top.
      for (var k = 0; k < 4; k++) {
        c.drawLine(Offset(base.dx - 3.5, base.dy - 28 + k * 2.2), Offset(base.dx + 3.5, base.dy - 27 + k * 2.2),
            Paint()
              ..color = const Color(0x55000000)
              ..strokeWidth = 0.8);
      }
    } else {
      // The pin's foot under the insulator.
      c.drawRect(Rect.fromLTRB(base.dx - 4, base.dy - 4, base.dx + 4, base.dy + 2), steel);
      final damage = faulty && !view.newOn ? view.damage : null;
      final bound = faulty ? (view.newOn ? view.newBound : view.bound) : true;
      m4InsulatorSwapPaintPin(c, base, 1, damage: damage, binding: bound);
    }
    if (faulty && view.roped) {
      // The rope sling: round the conductor by the head, up over the pole top.
      final w = _wireEnd(i).translate(i < 2 ? 12 : -12, 0);
      final top = Offset(M4InsulatorSwapGeo.px + (i < 2 ? -6 : 6), geo.topY + 2);
      final rope = Paint()
        ..color = const Color(0xFFD8B26A)
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke;
      c.drawPath(
          Path()
            ..moveTo(w.dx, w.dy)
            ..quadraticBezierTo((w.dx + top.dx) / 2, math.min(w.dy, top.dy) - 18, top.dx, top.dy),
          rope);
      c.drawCircle(w, 3.2, Paint()..color = const Color(0xFFB58F4A));
    }
  }

  void _discPhase(Canvas c, int i) {
    final from = geo.strainFrom(i);
    final to = geo.strainTo(i);
    final faulty = i == view.bad;
    final slack = faulty && view.takenUp && !view.released;
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    // The shackle under the arm.
    c.drawLine(Offset(from.dx, from.dy - 6), from, Paint()
      ..color = const Color(0xFF5A6066)
      ..strokeWidth = 2.4);
    // The string (sagging when the load is on the tool).
    final droop = slack ? 7.0 : 0.0;
    Offset along(double t) => Offset.lerp(from, to, t)!.translate(0, droop * 4 * t * (1 - t));
    c.drawPath(
        Path()
          ..moveTo(from.dx, from.dy)
          ..quadraticBezierTo((from.dx + to.dx) / 2, (from.dy + to.dy) / 2 + droop * 2, to.dx, to.dy),
        Paint()
          ..color = const Color(0xFF5A6066)
          ..strokeWidth = 1.6
          ..style = PaintingStyle.stroke);
    const ds = 1.45;
    for (var k = 0; k < 3; k++) {
      final at = along(M4InsulatorSwapGeo.discT(k));
      if (faulty && k == view.discBad) {
        if (view.discOut && !view.newDisc) {
          // The gap: the empty socket of the disc above and the bare ball
          // pin of the one below, nothing between them.
          final u = Offset(math.cos(angle), math.sin(angle));
          final up = at - u * 9;
          final down = at + u * 9;
          c.drawCircle(up, 4.2, Paint()
            ..color = const Color(0xFF8B9298)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2);
          c.drawLine(down, down + u * 6, Paint()
            ..color = const Color(0xFF5A6066)
            ..strokeWidth = 2.6);
          c.drawCircle(down, 3, Paint()..color = const Color(0xFF8B9298));
          continue;
        }
        if (view.newDisc) {
          m4InsulatorSwapPaintDisc(c, at, angle, ds, pin: view.pinned);
          continue;
        }
        m4InsulatorSwapPaintDisc(c, at, angle, ds, damage: view.damage);
        continue;
      }
      m4InsulatorSwapPaintDisc(c, at, angle, ds);
    }
    // The strain clamp.
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: to, width: 11, height: 7), const Radius.circular(2)), Paint()..color = const Color(0xFF8A9096));
    if (faulty && view.rigOn && !view.released) {
      // The come-along clamp on the conductor past the string, the
      // turnbuckle back to the arm: the bypass.
      final grip = geo.vanish == Offset.zero ? to : Offset.lerp(to, geo.vanish, 0.12)!;
      final arm = Offset(from.dx + 10, from.dy - 3);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: grip, width: 14, height: 7), const Radius.circular(2)), Paint()..color = const Color(0xFF2E6FB0));
      final mid = Offset.lerp(grip, arm, 0.5)!.translate(0, -12);
      final chain = Paint()
        ..color = const Color(0xFF8D949B)
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke;
      c.drawLine(grip, mid, chain);
      c.drawLine(mid, arm, chain);
      // The turnbuckle body (yellow) at the middle.
      c.save();
      c.translate(mid.dx, mid.dy);
      c.rotate(math.atan2(arm.dy - grip.dy, arm.dx - grip.dx));
      final tb = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 22, height: 8), const Radius.circular(3));
      c.drawRRect(tb, Paint()..color = view.takenUp ? const Color(0xFFE0B419) : const Color(0xFFC79E14));
      c.drawRRect(
          tb,
          Paint()
            ..color = const Color(0xFF6B5208)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1);
      c.restore();
    }
  }

  @override
  bool shouldRepaint(M4InsulatorSwapPainter old) => old.geo != geo || old.view != view || old.seed != seed;
}

/// The trainee's harness on the pole: the pole strap round the pole at his
/// waist and the lanyard up to its anchor above the arm, both clipped on.
class M4InsulatorSwapStrapPainter extends CustomPainter {
  const M4InsulatorSwapStrapPainter({required this.box, required this.anchor});
  final Rect box;
  final Offset anchor;

  @override
  void paint(Canvas c, Size size) {
    const px = M4InsulatorSwapGeo.px;
    final hip = Offset(box.left + box.width * 0.55, box.top + box.height * 0.52);
    final back = Offset(box.left + box.width * 0.5, box.top + box.height * 0.3);
    final strap = Paint()
      ..color = const Color(0xFF3A2A16)
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke;
    c.drawPath(
        Path()
          ..moveTo(hip.dx, hip.dy)
          ..quadraticBezierTo(px, hip.dy - 9, px + 11, hip.dy - 5)
          ..moveTo(hip.dx, hip.dy + 2)
          ..quadraticBezierTo(px, hip.dy + 5, px + 11, hip.dy - 5),
        strap);
    // The lanyard (orange webbing) from his back to the anchor sling.
    final lanyard = Paint()
      ..color = const Color(0xFFE8731E)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;
    c.drawPath(
        Path()
          ..moveTo(back.dx, back.dy)
          ..quadraticBezierTo(back.dx + 4, (back.dy + anchor.dy) / 2, anchor.dx - 4, anchor.dy),
        lanyard);
    c.drawLine(Offset(anchor.dx - 9, anchor.dy - 2), Offset(anchor.dx + 9, anchor.dy + 2), Paint()
      ..color = const Color(0xFF2B5FA8)
      ..strokeWidth = 3.4);
    c.drawCircle(Offset(anchor.dx - 4, anchor.dy), 2.8, Paint()
      ..color = const Color(0xFF3C4248)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6);
    // The step bolt under his boots.
    c.drawRect(Rect.fromLTRB(box.left + box.width * 0.35, box.bottom - 3, px - 6, box.bottom), Paint()..color = const Color(0xFF5A6066));
  }

  @override
  bool shouldRepaint(M4InsulatorSwapStrapPainter old) => old.box != box || old.anchor != anchor;
}

/// A spare on the tray, drawn big for inspection.
class M4InsulatorSwapSparePainter extends CustomPainter {
  const M4InsulatorSwapSparePainter({required this.kind, required this.damage});
  final M4InsulatorSwapKind kind;
  final M4InsulatorSwapDamage? damage;

  @override
  void paint(Canvas c, Size size) {
    if (kind == M4InsulatorSwapKind.pin) {
      final s = size.height / 64;
      m4InsulatorSwapPaintPin(c, Offset(size.width / 2, size.height - 4 * s), s, damage: damage);
    } else {
      final s = size.height / 36;
      m4InsulatorSwapPaintDisc(c, Offset(size.width / 2, size.height / 2), math.pi / 2 - 0.5, s, damage: damage);
    }
  }

  @override
  bool shouldRepaint(M4InsulatorSwapSparePainter old) => old.kind != kind || old.damage != damage;
}

/// The deadly moment on a tension pole: the string opened under load — the
/// conductor whips free off the arm (drawn in colour over the grey scene).
class M4InsulatorSwapSnapPainter extends CustomPainter {
  const M4InsulatorSwapSnapPainter({required this.geo, required this.bad, required this.v});
  final M4InsulatorSwapGeo geo;
  final int bad;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final from = geo.strainFrom(bad);
    final at = geo.discAt(bad, 1);
    final burst = Paint()..color = Color.fromRGBO(255, 214, 90, (1 - v * 0.6).clamp(0.0, 1.0));
    c.drawCircle(at, 10 + 26 * v, Paint()..color = Color.fromRGBO(255, 160, 40, 0.35 * (1 - v)));
    for (var k = 0; k < 10; k++) {
      final a = k * math.pi / 5;
      final r0 = 6 + 10 * v;
      final r1 = r0 + 18;
      c.drawLine(at + Offset(math.cos(a), math.sin(a)) * r0, at + Offset(math.cos(a), math.sin(a)) * r1, burst..strokeWidth = 2.4);
    }
    // The freed conductor whipping down and away (red: the danger).
    final whip = Paint()
      ..color = const Color(0xFFE5402A)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final end = Offset.lerp(at, Offset(at.dx - 40, at.dy + 160), v)!;
    c.drawPath(
        Path()
          ..moveTo(at.dx, at.dy)
          ..quadraticBezierTo(at.dx + 30 * (1 - v), (at.dy + end.dy) / 2, end.dx, end.dy),
        whip);
    // The broken shackle end swinging.
    c.drawLine(from, from + Offset(-10 + 18 * v, 18), Paint()
      ..color = const Color(0xFFE5402A)
      ..strokeWidth = 2.4);
  }

  @override
  bool shouldRepaint(M4InsulatorSwapSnapPainter old) => old.v != v || old.geo != geo || old.bad != bad;
}
