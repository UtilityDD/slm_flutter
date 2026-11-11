import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The drawn world of lesson 4.2 কাজ 2 "ঢিলে জাম্পার ধরো" (m4_jumper_tight.dart):
// an angle / dead-end PCC pole on the village road, seen from the side — three
// phases stacked on three cross-arm brackets, each with its strain insulator
// strings to the left and right spans and its jumper (a smooth U loop) joining
// the two sides with a PG clamp at each end. At night: the moon, the stars, the
// village's lit windows (dark while the line is shut down), and on the bad
// jumper a red-hot glow or sparking; by day: a melted, blackened clamp. On a
// shutdown: the portable earth set on the three phases with its lead down to
// the earth rod, the trainee up the pole (helmet, harness strap round the pole).
// Code-drawn, gradients, no bitmaps, no words. Design space 360 wide; the floor
// sits [M4JumperTightGeo.floorUp] above the bottom so the controls sit on it.

/// Where things are in the scene (design px, 360 wide).
@immutable
class M4JumperTightGeo {
  const M4JumperTightGeo._(this.height, this.groundY);

  factory M4JumperTightGeo.forScene(double height, double inset) => M4JumperTightGeo._(height, height - floorUp - inset * 0.5);

  final double height;

  /// The ground line at the pole's foot.
  final double groundY;

  static const double floorUp = 104;

  /// The pole's axis.
  static const double px = 180;

  /// How far the PG clamps sit out from the pole.
  static const double reach = 70;

  /// The top phase's cross-arm (kept clear of the header on a short phone).
  double get topArm => math.max(120, groundY - 440);
  double get spacing => ((groundY - 250 - topArm) / 2).clamp(64.0, 80.0);

  /// The cross-arm bracket of phase [i] (0 top → 2 bottom).
  double armY(int i) => topArm + spacing * i;

  double get poleTop => topArm - 30;
  double get horizonY => groundY - 150;

  /// The PG clamp of phase [i] at end [end] (0 left, 1 right).
  Offset clamp(int i, int end) => Offset(px + (end == 0 ? -reach : reach), armY(i) + 12);
  Rect clampHit(int i, int end) => Rect.fromCenter(center: clamp(i, end), width: 46, height: 40);

  /// The strain clamp at the string's outer end.
  Offset strain(int i, int end) => Offset(px + (end == 0 ? -58 : 58), armY(i) + 8);

  /// The far poles' pins (the spans run off to them).
  Offset farPin(int i, int end) => Offset(end == 0 ? 10 : 350, horizonY - 104 + 12.0 * i);

  /// Where the portable earth set clamps on (the right span, out from the jumper).
  Offset earthClamp(int i) => Offset(px + 104, armY(i) + 12 + 4.0 * i);
  Offset get earthRod => Offset(px + 54, groundY + 10);

  /// The lineman: on the ground by the pole, or up at phase [i] on the side of [end].
  Rect get groundBox => Rect.fromLTWH(px - 128, groundY - 140, 70, 140);
  Rect upBox(int i, int end) => end == 0 ? Rect.fromLTWH(px - 60, armY(i) - 6, 50, 100) : Rect.fromLTWH(px + 10, armY(i) - 6, 50, 100);

  @override
  bool operator ==(Object other) => other is M4JumperTightGeo && other.height == height && other.groundY == groundY;

  @override
  int get hashCode => Object.hash(height, groundY);
}

/// What is wrong with the bad jumper.
enum M4JumperTightKind { glow, spark, melted }

/// What the structure shows now.
@immutable
class M4JumperTightRig {
  const M4JumperTightRig({
    required this.kind,
    required this.phase,
    required this.end,
    required this.live,
    required this.earthed,
    required this.cleaned,
    required this.replaced,
    required this.fixed,
    required this.wrenchOn,
  });

  final M4JumperTightKind kind;

  /// The bad clamp: phase (0 top) and end (0 left).
  final int phase;
  final int end;
  final bool live;
  final bool earthed;
  final bool cleaned;
  final bool replaced;

  /// Tight at the right torque (and replaced, where it had melted).
  final bool fixed;

  /// The two wrenches are on the clamp.
  final bool wrenchOn;

  bool get night => kind != M4JumperTightKind.melted;

  @override
  bool operator ==(Object other) =>
      other is M4JumperTightRig &&
      other.kind == kind &&
      other.phase == phase &&
      other.end == end &&
      other.live == live &&
      other.earthed == earthed &&
      other.cleaned == cleaned &&
      other.replaced == replaced &&
      other.fixed == fixed &&
      other.wrenchOn == wrenchOn;

  @override
  int get hashCode => Object.hash(kind, phase, end, live, earthed, cleaned, replaced, fixed, wrenchOn);
}

/// The place: sky, land, village, the pole with its three phases, the earth
/// set. [t] (seconds) flickers the glow and the sparks while awake.
class M4JumperTightWorldPainter extends CustomPainter {
  M4JumperTightWorldPainter({required this.geo, required this.rig, required this.t, required this.seed}) : super(repaint: t);

  final M4JumperTightGeo geo;
  final M4JumperTightRig rig;
  final ValueListenable<double> t;
  final int seed;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    final night = rig.night;
    final hz = g.horizonY;

    // --- sky -----------------------------------------------------------------
    final sky = Rect.fromLTWH(0, 0, w, hz + 6);
    c.drawRect(
      sky,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: night ? const [Color(0xFF070E22), Color(0xFF1A2A4E), Color(0xFF2E3D5E)] : const [Color(0xFF5C9BD1), Color(0xFF9FC7E6), Color(0xFFEFE6CC)],
          stops: const [0, 0.65, 1],
        ).createShader(sky),
    );
    final rnd = math.Random(seed);
    if (night) {
      final star = Paint()..color = const Color(0xCCFFFFFF);
      for (var i = 0; i < 40; i++) {
        c.drawCircle(Offset(rnd.nextDouble() * w, rnd.nextDouble() * hz * 0.8), 0.6 + rnd.nextDouble() * 0.9, star);
      }
      final moon = Offset(w * 0.82, g.topArm - 60);
      c.drawCircle(moon, 40, Paint()..shader = const RadialGradient(colors: [Color(0x55E8EEFF), Color(0x00E8EEFF)]).createShader(Rect.fromCircle(center: moon, radius: 40)));
      c.drawCircle(moon, 13, Paint()..color = const Color(0xFFF1F3E6));
      c.drawCircle(moon + const Offset(5, -3), 11, Paint()..color = const Color(0xFF0F1A36));
    } else {
      final sun = Offset(w * 0.16, g.topArm - 50);
      c.drawCircle(sun, 90, Paint()..shader = const RadialGradient(colors: [Color(0x80FFF4D2), Color(0x00FFF4D2)]).createShader(Rect.fromCircle(center: sun, radius: 90)));
      c.drawCircle(sun, 14, Paint()..color = const Color(0xFFFFF6DC));
      final cloud = Paint()..color = const Color(0xCCFFFFFF);
      for (final (x, y, r) in [(92.0, g.topArm - 96, 15.0), (292.0, g.topArm - 74, 19.0)]) {
        c.drawCircle(Offset(x, y), r, cloud);
        c.drawCircle(Offset(x + r, y + 4), r * 0.8, cloud);
        c.drawCircle(Offset(x - r, y + 5), r * 0.7, cloud);
      }
    }

    // --- far land and the village ------------------------------------------------
    final tree = Path()..moveTo(0, hz);
    for (var x = 0.0; x <= w + 16; x += 16) {
      final bump = 12 + 8 * math.sin(x * 0.05 + seed) + 5 * math.sin(x * 0.17 + 1.1);
      tree.quadraticBezierTo(x + 8, hz - bump - 9, x + 16, hz - bump * 0.6);
    }
    tree
      ..lineTo(w, hz + 4)
      ..lineTo(0, hz + 4)
      ..close();
    c.drawPath(tree, Paint()..color = night ? const Color(0xFF14261E) : const Color(0xFF4F7A55));
    for (final (x, sz) in const [(54.0, 1.0), (88.0, 0.8), (262.0, 0.9), (300.0, 1.1)]) {
      final b = Rect.fromLTWH(x, hz - 13 * sz, 26 * sz, 13 * sz);
      c.drawRect(b, Paint()..color = night ? const Color(0xFF3A3A44) : const Color(0xFFB59A74));
      c.drawPath(
          Path()
            ..moveTo(x - 3 * sz, hz - 12 * sz)
            ..lineTo(x + 13 * sz, hz - 21 * sz)
            ..lineTo(x + 29 * sz, hz - 12 * sz)
            ..close(),
          Paint()..color = night ? const Color(0xFF2A2D35) : const Color(0xFF8E979E));
      // A window: lit at night while the line is live.
      final win = Rect.fromLTWH(x + 9 * sz, hz - 9 * sz, 6 * sz, 5 * sz);
      final lit = night && rig.live;
      if (lit) c.drawCircle(win.center, 7 * sz, Paint()..color = const Color(0x55FFD27A));
      c.drawRect(win, Paint()..color = lit ? const Color(0xFFFFD27A) : (night ? const Color(0xFF1C1F26) : const Color(0xFF5A4A36)));
    }
    final field = Rect.fromLTRB(0, hz, w, g.groundY + 8);
    c.drawRect(
      field,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: night ? const [Color(0xFF1C3324), Color(0xFF243A26)] : const [Color(0xFF8DB860), Color(0xFF6E9E45)],
        ).createShader(field),
    );
    final road = Rect.fromLTRB(0, g.groundY + 8, w, size.height);
    c.drawRect(
      road,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: night ? const [Color(0xFF2E2A26), Color(0xFF1E1B18)] : const [Color(0xFF8A7B62), Color(0xFF6E624E)],
        ).createShader(road),
    );

    // --- far poles and the spans ----------------------------------------------
    for (final x in const [10.0, 350.0]) {
      c.drawPath(
          Path()
            ..moveTo(x - 3, hz + 20)
            ..lineTo(x - 2, hz - 116)
            ..lineTo(x + 2, hz - 116)
            ..lineTo(x + 3, hz + 20)
            ..close(),
          Paint()..color = night ? const Color(0xFF4A4E58) : const Color(0xFF9B9890));
    }
    final span = Paint()
      ..color = night ? const Color(0xFF8A93A6) : const Color(0xFF2E3338)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 3; i++) {
      for (var e = 0; e < 2; e++) {
        final a = g.strain(i, e);
        final b = g.farPin(i, e);
        final mid = Offset.lerp(a, b, 0.5)! + const Offset(0, 16);
        c.drawPath(
            Path()
              ..moveTo(a.dx, a.dy)
              ..quadraticBezierTo(mid.dx, mid.dy, b.dx, b.dy),
            span);
      }
    }

    _pole(c);
    for (var i = 0; i < 3; i++) {
      _phase(c, i);
    }
    if (rig.earthed) _earth(c);
  }

  void _pole(Canvas c) {
    final g = geo;
    const px = M4JumperTightGeo.px;
    const half0 = 13.0;
    const half1 = 8.0;
    final top = g.poleTop;
    final body = Path()
      ..moveTo(px - half0, g.groundY + 8)
      ..lineTo(px - half1, top)
      ..lineTo(px + half1, top)
      ..lineTo(px + half0, g.groundY + 8)
      ..close();
    c.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          colors: rig.night ? const [Color(0xFF5E6168), Color(0xFF8A8D94), Color(0xFF55585E)] : const [Color(0xFF9C988E), Color(0xFFCBC7BC), Color(0xFF8E8A80)],
          stops: const [0, 0.45, 1],
        ).createShader(Rect.fromLTRB(px - half0, top, px + half0, g.groundY)),
    );
    // Step bolts.
    final bolt = Paint()..color = const Color(0xFF6B7076);
    var left = true;
    for (var y = g.groundY - 60; y > g.armY(2) + 70; y -= 34) {
      final k = (y - top) / (g.groundY - top);
      final half = half1 + (half0 - half1) * k;
      c.drawRect(Rect.fromLTWH(left ? px - half - 8 : px + half, y, 9, 2.6), bolt);
      left = !left;
    }
    // The danger plate.
    final plate = Rect.fromLTWH(px - 9, g.groundY - 130, 18, 22);
    c.drawRRect(RRect.fromRectAndRadius(plate, const Radius.circular(2)), Paint()..color = const Color(0xFFE9E4D6));
    c.drawPath(
        Path()
          ..moveTo(plate.center.dx + 2, plate.top + 4)
          ..lineTo(plate.center.dx - 3, plate.center.dy + 1)
          ..lineTo(plate.center.dx + 1, plate.center.dy + 1)
          ..lineTo(plate.center.dx - 2, plate.bottom - 4),
        Paint()
          ..color = const Color(0xFFC0392B)
          ..strokeWidth = 1.6
          ..style = PaintingStyle.stroke);
  }

  void _phase(Canvas c, int i) {
    final g = geo;
    const px = M4JumperTightGeo.px;
    final y = g.armY(i);
    final bad = rig.phase == i;
    // The cross-arm bracket, end on (a short steel channel with its brace).
    final arm = Rect.fromLTRB(px - 22, y - 4, px + 22, y + 4);
    c.drawRect(arm, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8A9096), Color(0xFF4E5459)]).createShader(arm));
    final brace = Paint()
      ..color = const Color(0xFF5A6066)
      ..strokeWidth = 2.2;
    c.drawLine(Offset(px - 18, y + 4), Offset(px - 6, y + 22), brace);
    c.drawLine(Offset(px + 18, y + 4), Offset(px + 6, y + 22), brace);
    // The strain strings both ways.
    for (var e = 0; e < 2; e++) {
      _strain(c, Offset(px + (e == 0 ? -20 : 20), y + 3), g.strain(i, e), e == 0 ? -1 : 1);
    }
    // The conductor tails from the strain clamps out to the PG clamps.
    final tail = Paint()
      ..color = const Color(0xFF3A4046)
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke;
    for (var e = 0; e < 2; e++) {
      final s = g.strain(i, e);
      final k = g.clamp(i, e);
      final out = e == 0 ? -1.0 : 1.0;
      c.drawPath(
          Path()
            ..moveTo(s.dx, s.dy)
            ..quadraticBezierTo(k.dx + out * 6, s.dy, k.dx, k.dy),
          tail);
    }
    // The jumper: a smooth U from clamp to clamp, in front of the pole.
    final a = g.clamp(i, 0);
    final b = g.clamp(i, 1);
    final melted = bad && rig.kind == M4JumperTightKind.melted && !rig.replaced;
    final jumper = Path()
      ..moveTo(a.dx, a.dy)
      ..cubicTo(a.dx - 4, y + 66, b.dx + 4, y + 66, b.dx, b.dy);
    c.drawPath(
        jumper,
        Paint()
          ..color = const Color(0xFF2B3036)
          ..strokeWidth = 5.4
          ..style = PaintingStyle.stroke);
    c.drawPath(
        jumper,
        Paint()
          ..color = rig.night ? const Color(0xFFAEB7C2) : const Color(0xFFC9D0D6)
          ..strokeWidth = 3.4
          ..style = PaintingStyle.stroke);
    for (var e = 0; e < 2; e++) {
      final here = bad && rig.end == e;
      _pg(c, g.clamp(i, e), here: here, melted: here && melted);
    }
  }

  void _strain(Canvas c, Offset from, Offset to, int dir) {
    final metal = Paint()
      ..color = const Color(0xFF5A6066)
      ..strokeWidth = 2;
    c.drawLine(from, from + Offset(4.0 * dir, 2), metal);
    final disc = Paint()..color = const Color(0xFF7B4526);
    final shine = Paint()..color = const Color(0xFFA8714A);
    for (var k = 0; k < 5; k++) {
      final p = Offset.lerp(from + Offset(8.0 * dir, 2), to - Offset(5.0 * dir, 0), k / 4)!;
      c.drawOval(Rect.fromCenter(center: p, width: 4.4, height: 12), disc);
      c.drawOval(Rect.fromCenter(center: p + const Offset(0.8, -2), width: 1.4, height: 5), shine);
    }
    // The strain clamp.
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: to, width: 9, height: 7), const Radius.circular(2)), Paint()..color = const Color(0xFF7D868E));
  }

  void _pg(Canvas c, Offset at, {required bool here, required bool melted}) {
    final time = t.value;
    final live = rig.live;
    final hot = here && !rig.fixed && live && rig.kind == M4JumperTightKind.glow;
    final sparking = here && !rig.fixed && live && rig.kind == M4JumperTightKind.spark;
    if (hot) {
      final pulse = 0.85 + 0.15 * math.sin(time * 3.2);
      c.drawCircle(at, 34, Paint()..shader = RadialGradient(colors: [Color.fromRGBO(255, 90, 40, 0.55 * pulse), const Color(0x00FF5A28)]).createShader(Rect.fromCircle(center: at, radius: 34)));
    }
    if (melted) {
      // A melted, blackened lump; the strands splayed and burnt.
      c.drawPath(
          Path()
            ..moveTo(at.dx - 10, at.dy - 5)
            ..quadraticBezierTo(at.dx - 3, at.dy - 10, at.dx + 3, at.dy - 6)
            ..quadraticBezierTo(at.dx + 11, at.dy - 8, at.dx + 10, at.dy + 2)
            ..lineTo(at.dx + 6, at.dy + 10)
            ..quadraticBezierTo(at.dx + 3, at.dy + 14, at.dx + 1, at.dy + 9)
            ..quadraticBezierTo(at.dx - 3, at.dy + 15, at.dx - 5, at.dy + 8)
            ..quadraticBezierTo(at.dx - 12, at.dy + 6, at.dx - 10, at.dy - 5)
            ..close(),
          Paint()..color = const Color(0xFF2A221D));
      final strand = Paint()
        ..color = const Color(0xFF4A3424)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;
      for (final o in const [Offset(-6, 16), Offset(-1, 19), Offset(5, 17), Offset(9, 13)]) {
        c.drawLine(at + const Offset(0, 8), at + o, strand);
      }
      c.drawCircle(at + const Offset(-14, 2), 9, Paint()..color = const Color(0x33201810));
      return;
    }
    final fresh = here && rig.replaced;
    final body = RRect.fromRectAndRadius(Rect.fromCenter(center: at, width: 18, height: 14), const Radius.circular(3));
    final Color col;
    if (hot) {
      col = Color.lerp(const Color(0xFFE2421E), const Color(0xFFFF8A3A), 0.5 + 0.5 * math.sin(time * 3.2))!;
    } else if (here && !rig.fixed && rig.kind == M4JumperTightKind.glow) {
      col = const Color(0xFF7A5A50); // dull, cooling, heat-marked
    } else if (fresh) {
      col = const Color(0xFFE9EEF1);
    } else {
      col = rig.night ? const Color(0xFF9AA3AC) : const Color(0xFFB9C1C7);
    }
    c.drawRRect(body, Paint()..color = col);
    c.drawRRect(
        body,
        Paint()
          ..color = const Color(0xFF3E454B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
    final nut = Paint()..color = const Color(0xFF4E565E);
    c.drawCircle(at + const Offset(-4.5, 0), 2.4, nut);
    c.drawCircle(at + const Offset(4.5, 0), 2.4, nut);
    if (here && rig.cleaned && !rig.fixed) {
      // The brushed, pasted conductor: a bright band.
      c.drawLine(at + const Offset(-12, -6), at + const Offset(12, -6), Paint()
        ..color = const Color(0xAAFFFFFF)
        ..strokeWidth = 1.4);
    }
    if (sparking) {
      final rr = math.Random((time * 12).floor());
      c.drawCircle(at, 16, Paint()..color = const Color(0x55FFE08A));
      final spark = Paint()
        ..color = const Color(0xFFFFE27A)
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round;
      for (var k = 0; k < 7; k++) {
        final a = rr.nextDouble() * math.pi * 2;
        final d0 = 8 + rr.nextDouble() * 4;
        final d1 = d0 + 6 + rr.nextDouble() * 12;
        final dir = Offset(math.cos(a), math.sin(a));
        c.drawLine(at + dir * d0, at + dir * d1 + Offset(rr.nextDouble() * 3 - 1.5, 2), spark);
      }
      c.drawCircle(at, 4, Paint()..color = const Color(0xFFFFFFFF));
    }
    if (here && rig.wrenchOn) {
      // Two wrenches: one holds the bolt head, the other turns the nut.
      _wrench(c, at + const Offset(-4.5, 0), -2.3);
      _wrench(c, at + const Offset(4.5, 0), 0.8);
    }
  }

  void _wrench(Canvas c, Offset at, double angle) {
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(angle);
    final steel = Paint()..color = const Color(0xFF8C969F);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(4, -2.2, 30, 4.4), const Radius.circular(2)), steel);
    c.drawCircle(Offset.zero, 5.5, Paint()
      ..color = const Color(0xFF8C969F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
    c.restore();
  }

  void _earth(Canvas c) {
    final g = geo;
    final lead = Paint()
      ..color = const Color(0xFFC98B3A)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    final rod = g.earthRod;
    for (var i = 0; i < 3; i++) {
      final k = g.earthClamp(i);
      c.drawPath(
          Path()
            ..moveTo(k.dx, k.dy + 4)
            ..cubicTo(k.dx + 10, k.dy + 60, rod.dx + 30, rod.dy - 120, rod.dx, rod.dy - 6),
          lead);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: k, width: 10, height: 9), const Radius.circular(2)), Paint()..color = const Color(0xFF5A6066));
    }
    // The earth rod driven into the ground, its clamp on top.
    c.drawLine(rod + const Offset(0, -8), rod + const Offset(0, 10), Paint()
      ..color = const Color(0xFF7D868E)
      ..strokeWidth = 3);
    c.drawRect(Rect.fromCenter(center: rod + const Offset(0, -8), width: 10, height: 6), Paint()..color = const Color(0xFF5A6066));
  }

  @override
  bool shouldRepaint(M4JumperTightWorldPainter old) => old.geo != geo || old.rig != rig || old.seed != seed;
}

/// The harness strap round the pole while he works up there (drawn over him).
class M4JumperTightStrapPainter extends CustomPainter {
  const M4JumperTightStrapPainter({required this.box});
  final Rect box;

  @override
  void paint(Canvas c, Size size) {
    const px = M4JumperTightGeo.px;
    final waist = box.top + box.height * 0.52;
    final l = math.min(box.center.dx, px - 12);
    final r = math.max(box.center.dx, px + 12);
    c.drawArc(Rect.fromLTRB(l, waist - 5, r, waist + 7), 0, math.pi, false, Paint()
      ..color = const Color(0xFF1F2A36)
      ..strokeWidth = 3.4
      ..style = PaintingStyle.stroke);
    c.drawArc(Rect.fromLTRB(l, waist - 5, r, waist + 7), 0, math.pi, false, Paint()
      ..color = const Color(0xFFE0A21E)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(M4JumperTightStrapPainter old) => old.box != box;
}

/// The torque dial: the needle at [v] (0 → 1), the band where it is right.
class M4JumperTightDialPainter extends CustomPainter {
  M4JumperTightDialPainter({required this.v, required this.lo, required this.hi}) : super(repaint: v);
  final ValueListenable<double> v;
  final double lo;
  final double hi;

  @override
  void paint(Canvas c, Size size) {
    final r = Offset.zero & size;
    final body = RRect.fromRectAndRadius(r.deflate(2), const Radius.circular(16));
    c.drawRRect(body, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2A3442), Color(0xFF111821)]).createShader(r));
    c.drawRRect(
        body,
        Paint()
          ..color = const Color(0xFF8C969F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    final centre = Offset(size.width / 2, size.height * 0.72);
    final rad = size.width * 0.36;
    final arc = Rect.fromCircle(center: centre, radius: rad);
    c.drawArc(arc, math.pi, math.pi, false, Paint()
      ..color = const Color(0xFF3A3F45)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke);
    c.drawArc(arc, math.pi + math.pi * lo, math.pi * (hi - lo), false, Paint()
      ..color = const Color(0xFF39D353)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke);
    c.drawArc(arc, math.pi + math.pi * hi, math.pi * (1 - hi), false, Paint()
      ..color = const Color(0xFFB8332A)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke);
    final a = math.pi + math.pi * v.value.clamp(0.0, 1.0);
    final tip = centre + Offset(math.cos(a), math.sin(a)) * (rad - 4);
    c.drawLine(centre, tip, Paint()
      ..color = Colors.white
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round);
    c.drawCircle(centre, 5, Paint()..color = const Color(0xFFE7ECEF));
  }

  @override
  bool shouldRepaint(M4JumperTightDialPainter old) => old.lo != lo || old.hi != hi;
}

/// The flash when a tool goes on a live jumper (the deadly moment, in colour
/// over the frozen scene).
class M4JumperTightArcPainter extends CustomPainter {
  const M4JumperTightArcPainter({required this.at, required this.v});
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
  bool shouldRepaint(M4JumperTightArcPainter old) => old.v != v || old.at != at;
}
