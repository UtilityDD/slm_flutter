import 'dart:math' as math;

import 'package:flutter/material.dart';

// The place for lesson 4.4 কাজ 1 "ডিও খোলো নিয়মে" (m4_do_open.dart): a
// distribution transformer (DTR) on an H-pole structure. On the top cross-arm
// hang three DO fuse units (R, Y, B); their leads drop to the DTR's HT
// bushings on the platform below. On the ground: the verge, and a puddle on
// one side (the lesson: stand on dry, level ground). The trainee stands with
// the hot stick; the rod is drawn from his hands to its tip. Design space:
// 360 wide, [M4DoOpenGeo.height] high. Static painters only (they repaint
// when the play changes, never on a clock).

/// The scene's geometry (design px).
@immutable
class M4DoOpenGeo {
  const M4DoOpenGeo._(this.height, this.groundY, this.armY);

  factory M4DoOpenGeo.forScene(double height, double inset) {
    final ground = height - 172 - inset * 0.4;
    final arm = math.max(150.0, ground - 400);
    return M4DoOpenGeo._(height, ground, arm);
  }

  final double height;
  final double groundY;
  final double armY;

  static const poleL = 140.0;
  static const poleR = 320.0;
  static const armLeft = 126.0;
  static const armRight = 334.0;

  /// The three phases, left to right (R, Y, B).
  static const phaseX = [190.0, 230.0, 270.0];

  /// The middle of the DO set (and of the DTR under it).
  static const midX = 230.0;

  /// Ground under the DO set and the DTR: |x − midX| < this.
  static const underHalf = 66.0;

  /// Nearer than this to the left edge: too far to work the rod.
  static const farX = 60.0;

  /// The puddle on the left (x range) or on the right.
  static const wetLeft = (104.0, 164.0);
  static const wetRight = (296.0, 360.0);

  /// The trainee's height on screen.
  double get man => 86;

  /// The platform the DTR stands on.
  double get platformY => armY + 250;

  /// A DO fuse's ring (the pull eye at the top of the barrel), closed.
  Offset ringOf(int phase) => Offset(phaseX[phase] + 6, armY + 30);

  /// The ring when the barrel hangs open (swung down).
  Offset ringOpenOf(int phase) => Offset(phaseX[phase] + 32, armY + 119);

  @override
  bool operator ==(Object other) => other is M4DoOpenGeo && other.height == height && other.groundY == groundY;

  @override
  int get hashCode => Object.hash(height, groundY);
}

/// The yard: sky, far trees, the verge with its puddle, the H-pole, the DO
/// set and the DTR.
class M4DoOpenWorldPainter extends CustomPainter {
  const M4DoOpenWorldPainter({required this.geo, required this.open, required this.blown, required this.puddleLeft});

  final M4DoOpenGeo geo;

  /// Which DO fuses hang open (by phase).
  final List<bool> open;

  /// The phase whose link a fault blew (-1: none).
  final int blown;

  /// The puddle lies on the left of the structure (else on the right).
  final bool puddleLeft;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    // Sky.
    final skyRect = Rect.fromLTWH(0, 0, 360, g.groundY);
    c.drawRect(
      skyRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7FA9CF), Color(0xFFC4D9E6), Color(0xFFE6EEE6)],
        ).createShader(skyRect),
    );
    final cloud = Paint()..color = const Color(0xCCFFFFFF);
    for (final (x, y, r) in [
      (40.0, g.armY - 80, 18.0),
      (64.0, g.armY - 74, 24.0),
      (90.0, g.armY - 82, 16.0),
      (250.0, g.armY - 120, 15.0),
      (272.0, g.armY - 114, 21.0),
    ]) {
      c.drawCircle(Offset(x, y), r, cloud);
    }
    // Far trees and village roofs.
    final far = Paint()..color = const Color(0xFF7C9F76);
    final farPath = Path()..moveTo(0, g.groundY - 40);
    for (var x = 0.0; x <= 360; x += 24) {
      farPath.quadraticBezierTo(x + 12, g.groundY - 64 - (x % 72 == 0 ? 16 : 0), x + 24, g.groundY - 40);
    }
    farPath
      ..lineTo(360, g.groundY)
      ..lineTo(0, g.groundY)
      ..close();
    c.drawPath(farPath, far);
    final roof = Paint()..color = const Color(0xFF9A6B4F);
    for (final x in [24.0, 300.0]) {
      c.drawRect(Rect.fromLTWH(x, g.groundY - 34, 30, 20), Paint()..color = const Color(0xFFD8CBB2));
      c.drawPath(
        Path()
          ..moveTo(x - 4, g.groundY - 34)
          ..lineTo(x + 15, g.groundY - 48)
          ..lineTo(x + 34, g.groundY - 34)
          ..close(),
        roof,
      );
    }
    // The ground.
    final groundRect = Rect.fromLTWH(0, g.groundY, 360, size.height - g.groundY);
    c.drawRect(
      groundRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8E9A5C), Color(0xFF6C7944)],
        ).createShader(groundRect),
    );
    final peb = Paint()..color = const Color(0x55302A1A);
    final rnd = math.Random(5);
    for (var i = 0; i < 26; i++) {
      c.drawCircle(Offset(rnd.nextDouble() * 360, g.groundY + 6 + rnd.nextDouble() * 70), 1.2 + rnd.nextDouble() * 1.4, peb);
    }
    // The puddle (wet, slippery ground).
    final (wl, wr) = puddleLeft ? M4DoOpenGeo.wetLeft : M4DoOpenGeo.wetRight;
    final pud = Rect.fromLTRB(wl, g.groundY + 4, math.min(wr, 356), g.groundY + 40);
    c.drawOval(pud, Paint()..color = const Color(0xFF5E7C8E));
    c.drawOval(pud.deflate(5), Paint()..color = const Color(0xFF7FA0B3));
    final glint = Paint()
      ..color = const Color(0xAAE8F4FA)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(pud.left + 12, pud.top + 12), Offset(pud.left + 30, pud.top + 12), glint);
    c.drawLine(Offset(pud.center.dx, pud.center.dy + 4), Offset(pud.center.dx + 16, pud.center.dy + 4), glint);

    // The two poles (PCC, tapering).
    for (final x in [M4DoOpenGeo.poleL, M4DoOpenGeo.poleR]) {
      final pole = Path()
        ..moveTo(x - 6, g.armY - 34)
        ..lineTo(x + 6, g.armY - 34)
        ..lineTo(x + 10, g.groundY + 4)
        ..lineTo(x - 10, g.groundY + 4)
        ..close();
      c.drawPath(
        pole,
        Paint()..shader = const LinearGradient(colors: [Color(0xFFB9B5AA), Color(0xFF8E8A80)]).createShader(Rect.fromLTWH(x - 10, g.armY, 20, g.groundY - g.armY)),
      );
    }
    // Danger plate on the left pole.
    final plate = Rect.fromLTWH(M4DoOpenGeo.poleL - 8, g.groundY - 120, 16, 20);
    c.drawRect(plate, Paint()..color = const Color(0xFFF2F2F2));
    c.drawRect(
      plate,
      Paint()
        ..color = const Color(0xFFC0392B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    // The top cross-arm.
    c.drawRect(Rect.fromLTRB(M4DoOpenGeo.armLeft, g.armY - 5, M4DoOpenGeo.armRight, g.armY + 5), Paint()..color = const Color(0xFF4F555C));
    c.drawRect(Rect.fromLTRB(M4DoOpenGeo.armLeft, g.armY - 5, M4DoOpenGeo.armRight, g.armY - 2), Paint()..color = const Color(0xFF79808A));

    // The 11 kV line coming in to the tops of the fuses.
    final wire = Paint()
      ..color = const Color(0xFF2E3238)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    for (final (i, x) in M4DoOpenGeo.phaseX.indexed) {
      _insulator(c, Offset(x, g.armY - 5), 16);
      c.drawPath(
        Path()
          ..moveTo(-10, g.armY - 34 - i * 3)
          ..quadraticBezierTo(x * 0.5, g.armY - 14 - i * 3, x, g.armY - 22)
          ..lineTo(g.ringOf(i).dx + 2, g.armY + 22),
        wire,
      );
      // The phase tag on the arm (R red, Y yellow, B blue).
      final tag = Rect.fromCenter(center: Offset(x - 16, g.armY + 13), width: 11, height: 11);
      c.drawRect(tag, Paint()..color = const [Color(0xFFC0392B), Color(0xFFF1C40F), Color(0xFF2E6FD8)][i]);
      final letter = TextPainter(
        text: TextSpan(
          text: const ['R', 'Y', 'B'][i],
          style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFF111111)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      letter.paint(c, tag.center - Offset(letter.width / 2, letter.height / 2));
    }

    // The DTR platform (two channels) and the tank.
    final py = g.platformY;
    final steel = Paint()..color = const Color(0xFF4F555C);
    c.drawRect(Rect.fromLTRB(M4DoOpenGeo.poleL - 8, py, M4DoOpenGeo.poleR + 8, py + 8), steel);
    final tank = Rect.fromLTRB(182, py - 78, 278, py);
    c.drawRRect(
      RRect.fromRectAndRadius(tank, const Radius.circular(4)),
      Paint()..shader = const LinearGradient(colors: [Color(0xFF9AA39A), Color(0xFF6F786F)]).createShader(tank),
    );
    final fin = Paint()
      ..color = const Color(0xFF5E665E)
      ..strokeWidth = 2.2;
    for (var x = tank.left + 8; x < tank.right - 4; x += 9) {
      c.drawLine(Offset(x, tank.top + 10), Offset(x, tank.bottom - 6), fin);
    }
    // The conservator on top.
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(184, py - 98, 230, py - 84), const Radius.circular(7)), Paint()..color = const Color(0xFF7D867D));
    c.drawRect(Rect.fromLTWH(204, py - 85, 5, 8), Paint()..color = const Color(0xFF6F786F));
    // The name plate.
    c.drawRect(Rect.fromLTWH(212, py - 50, 34, 20), Paint()..color = const Color(0xFFE9E4D2));
    final dtr = TextPainter(
      text: const TextSpan(
        text: 'DTR',
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF2B2416)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    dtr.paint(c, Offset(229 - dtr.width / 2, py - 46));
    // HT bushings and the leads up to the bottoms of the fuses.
    final lead = Paint()
      ..color = const Color(0xFF2E3238)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;
    for (final (i, x) in M4DoOpenGeo.phaseX.indexed) {
      final bx = 200.0 + i * 30;
      _insulator(c, Offset(bx, py - 78), 18);
      c.drawPath(
        Path()
          ..moveTo(x + 20, g.armY + 74)
          ..quadraticBezierTo(x + 18, g.armY + 170, bx, py - 96),
        lead,
      );
    }
    // The LT side: a cable down the right pole to the LT box.
    c.drawPath(
      Path()
        ..moveTo(278, py - 30)
        ..quadraticBezierTo(300, py - 30, M4DoOpenGeo.poleR - 6, py + 20)
        ..lineTo(M4DoOpenGeo.poleR - 6, g.groundY - 46),
      Paint()
        ..color = const Color(0xFF1C1F24)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(M4DoOpenGeo.poleR - 22, g.groundY - 72, 30, 30), const Radius.circular(3)),
      Paint()..color = const Color(0xFF8C969E),
    );

    for (var i = 0; i < 3; i++) {
      _doFuse(c, i, open[i], blown: i == blown);
    }
  }

  void _insulator(Canvas c, Offset base, double h) {
    final p = Paint()..color = const Color(0xFF8A4B2A);
    for (var k = 0; k < 3; k++) {
      final y = base.dy - k * h / 3;
      c.drawOval(Rect.fromCenter(center: Offset(base.dx, y - 3), width: 12 - k * 1.5, height: 5), p);
    }
    c.drawRect(Rect.fromLTWH(base.dx - 2.2, base.dy - h, 4.4, h), p);
  }

  /// A DO fuse unit: the porcelain body on its bracket, the top and bottom
  /// contacts, and the barrel with its ring (closed: up between the contacts;
  /// open: swung down on its hinge). A blown link hangs from its barrel.
  void _doFuse(Canvas c, int phase, bool isOpen, {required bool blown}) {
    final g = geo;
    final x = M4DoOpenGeo.phaseX[phase];
    c.drawRect(Rect.fromLTWH(x - 3, g.armY + 5, 6, 14), Paint()..color = const Color(0xFF5E646B));
    c.save();
    c.translate(x - 8, g.armY + 18);
    c.rotate(-0.28);
    final body = Paint()..color = const Color(0xFF8A4B2A);
    for (var k = 0; k < 5; k++) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(0, 8 + k * 10), width: 14, height: 6), const Radius.circular(3)), body);
    }
    c.drawRect(const Rect.fromLTWH(-3, 4, 6, 48), body);
    c.restore();
    final metal = Paint()..color = const Color(0xFFB8BEC6);
    c.drawRect(Rect.fromLTWH(x - 1, g.armY + 22, 15, 5), metal);
    c.drawRect(Rect.fromLTWH(x + 6, g.armY + 70, 15, 5), metal);
    final barrel = Paint()
      ..color = const Color(0xFF3A3F45)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final ring = Paint()
      ..color = const Color(0xFFD9DEE4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    if (!isOpen) {
      c.drawLine(Offset(x + 6, g.armY + 30), Offset(x + 16, g.armY + 72), barrel);
      c.drawCircle(g.ringOf(phase) + const Offset(0, -4), 4.2, ring);
    } else {
      final hinge = Offset(x + 16, g.armY + 74);
      final end = hinge + const Offset(14, 40);
      c.drawLine(hinge, end, barrel);
      c.drawCircle(end + const Offset(2, 5), 4.2, ring);
      if (blown) {
        // The blown link's leader hangs out, scorched.
        c.drawPath(
          Path()
            ..moveTo(end.dx - 2, end.dy - 4)
            ..quadraticBezierTo(end.dx - 10, end.dy + 8, end.dx - 4, end.dy + 18),
          Paint()
            ..color = const Color(0xFF2A1A10)
            ..strokeWidth = 1.6
            ..style = PaintingStyle.stroke,
        );
        c.drawCircle(hinge + const Offset(7, 18), 5, Paint()..color = const Color(0x66201008));
      }
    }
  }

  @override
  bool shouldRepaint(M4DoOpenWorldPainter old) =>
      old.geo != geo || old.blown != blown || old.puddleLeft != puddleLeft || !_same(old.open, open);

  static bool _same(List<bool> a, List<bool> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// What is on the rod's head.
enum M4DoOpenHead { none, puller, loadBreak }

/// The hot stick from the trainee's hands to its tip: fibreglass sections,
/// the red hand guard, the attachment (a fuse puller hook, or the load-break
/// tool: a chamber with its hook).
class M4DoOpenRodPainter extends CustomPainter {
  const M4DoOpenRodPainter({required this.butt, required this.tip, required this.head});

  final Offset butt;
  final Offset tip;
  final M4DoOpenHead head;

  @override
  void paint(Canvas c, Size size) {
    final d = tip - butt;
    final len = d.distance;
    if (len < 4) return;
    final u = d / len;
    final n = Offset(-u.dy, u.dx);
    c.drawLine(
      butt,
      tip,
      Paint()
        ..color = const Color(0xFFF2B33D)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    c.drawLine(
      butt + n * 1.2,
      tip + n * 1.2,
      Paint()
        ..color = const Color(0x66FFFFFF)
        ..strokeWidth = 1.1,
    );
    final joint = Paint()
      ..color = const Color(0xFF2E7D4F)
      ..strokeWidth = 6;
    for (final f in const [0.38, 0.62, 0.84]) {
      final p = butt + d * f;
      c.drawLine(p - u * 2.5, p + u * 2.5, joint);
    }
    final gp = butt + d * 0.16;
    c.drawLine(
      gp - n * 6,
      gp + n * 6,
      Paint()
        ..color = const Color(0xFFC0392B)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    final hp = Paint()
      ..color = const Color(0xFF5E646B)
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    switch (head) {
      case M4DoOpenHead.none:
        break;
      case M4DoOpenHead.puller:
        c.drawLine(tip - u * 8, tip, hp);
        c.drawArc(Rect.fromCircle(center: tip + n * 3, radius: 3.4), math.atan2(n.dy, n.dx) + math.pi, math.pi * 1.2, false, hp);
      case M4DoOpenHead.loadBreak:
        // The chamber (a grey cylinder along the rod) and its hook.
        final a = tip - u * 22;
        final b = tip - u * 6;
        c.drawLine(
          a,
          b,
          Paint()
            ..color = const Color(0xFF6A7380)
            ..strokeWidth = 9
            ..strokeCap = StrokeCap.round,
        );
        c.drawLine(
          a + n * 2,
          b + n * 2,
          Paint()
            ..color = const Color(0x55FFFFFF)
            ..strokeWidth = 2,
        );
        c.drawLine(b, tip, hp);
        c.drawArc(Rect.fromCircle(center: tip + n * 3, radius: 3.4), math.atan2(n.dy, n.dx) + math.pi, math.pi * 1.2, false, hp);
    }
  }

  @override
  bool shouldRepaint(M4DoOpenRodPainter old) => old.butt != butt || old.tip != tip || old.head != head;
}

/// The rods at the van: what each one is.
enum M4DoOpenRod { good, cracked, short }

/// Three operating rods stood in the van's rack, side by side ([rods] left
/// to right): a whole one, one with a crack and a splinter, one too short.
class M4DoOpenRackPainter extends CustomPainter {
  const M4DoOpenRackPainter({required this.rods, this.picked});
  final List<M4DoOpenRod> rods;
  final int? picked;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width / rods.length;
    final base = size.height - 14;
    // The rack bar.
    c.drawRect(Rect.fromLTWH(6, base, size.width - 12, 8), Paint()..color = const Color(0xFF4F555C));
    c.drawRect(Rect.fromLTWH(6, 24, size.width - 12, 5), Paint()..color = const Color(0xFF4F555C));
    for (var i = 0; i < rods.length; i++) {
      final x = w * i + w / 2;
      final r = rods[i];
      final top = r == M4DoOpenRod.short ? base - (base - 30) * 0.5 : 34.0;
      if (picked == i) {
        c.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTRB(x - 26, top - 10, x + 26, base + 4), const Radius.circular(10)),
          Paint()..color = const Color(0x3348C774),
        );
      }
      final rod = Rect.fromLTRB(x - 6, top, x + 6, base);
      c.drawRRect(
        RRect.fromRectAndRadius(rod, const Radius.circular(5)),
        Paint()..shader = const LinearGradient(colors: [Color(0xFFF7C65A), Color(0xFFD99520)]).createShader(rod),
      );
      // Section joints, hand guard, butt cap, head hook.
      for (final f in const [0.3, 0.6]) {
        final y = top + (base - top) * f;
        c.drawRect(Rect.fromLTRB(x - 8, y - 3, x + 8, y + 3), Paint()..color = const Color(0xFF2E7D4F));
      }
      final gy = top + (base - top) * 0.78;
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, gy), width: 30, height: 6), const Radius.circular(3)), Paint()..color = const Color(0xFFC0392B));
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(x - 7, base - 12, x + 7, base), const Radius.circular(3)), Paint()..color = const Color(0xFF3A3F45));
      c.drawArc(
        Rect.fromCircle(center: Offset(x + 3, top - 4), radius: 4),
        math.pi * 0.9,
        math.pi * 1.3,
        false,
        Paint()
          ..color = const Color(0xFF5E646B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4,
      );
      // The rating sticker (white band).
      final sy = top + (base - top) * 0.88;
      c.drawRect(Rect.fromLTRB(x - 6, sy - 4, x + 6, sy + 4), Paint()..color = const Color(0xFFF4F1E6));
      if (r == M4DoOpenRod.cracked) {
        final cy = top + (base - top) * 0.45;
        final crack = Paint()
          ..color = const Color(0xFF3A2410)
          ..strokeWidth = 1.8
          ..style = PaintingStyle.stroke;
        c.drawPath(
          Path()
            ..moveTo(x - 6, cy - 16)
            ..lineTo(x + 1, cy - 6)
            ..lineTo(x - 3, cy + 2)
            ..lineTo(x + 6, cy + 14),
          crack,
        );
        // A splinter of fibre sticking out.
        c.drawLine(Offset(x + 6, cy + 4), Offset(x + 14, cy - 2), crack);
        c.drawLine(Offset(x + 6, cy + 8), Offset(x + 13, cy + 8), crack);
      }
    }
  }

  @override
  bool shouldRepaint(M4DoOpenRackPainter old) => old.picked != picked || old.rods != rods;
}
