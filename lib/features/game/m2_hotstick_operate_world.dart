import 'dart:math' as math;

import 'package:flutter/material.dart';

// The place for lesson 2.5 কাজ 2 "দূর থেকে চালাও" (m2_hotstick_operate.dart):
// a roadside 11 kV pole with a cross-arm; on it either three DO fuse units
// (R, Y, B) or a three-pole AB switch with its operating handle. The trainee
// stands on the ground with the hot stick; the rod is drawn from his hands to
// its tip. Design space: 360 wide, [HsGeo.height] high. Static painters only
// (they repaint when the play changes, never on a clock).

/// What hangs on the cross-arm.
enum HsGear { doFuse, abSwitch }

/// The scene's geometry (design px).
@immutable
class HsGeo {
  const HsGeo._(this.height, this.groundY, this.armY);

  factory HsGeo.forScene(double height, double inset) {
    final ground = height - 172 - inset * 0.4;
    final arm = math.max(150.0, ground - 400);
    return HsGeo._(height, ground, arm);
  }

  final double height;
  final double groundY;
  final double armY;

  static const poleX = 150.0;
  static const armLeft = 128.0;
  static const armRight = 326.0;

  /// The three phases, left to right (R, Y, B).
  static const phaseX = [204.0, 254.0, 304.0];

  /// The trainee's height on screen.
  double get man => 86;

  /// A DO fuse's ring (the pull eye at the top of the barrel), closed.
  Offset ringOf(int phase) => Offset(phaseX[phase] + 6, armY + 30);

  /// The ring when the barrel hangs open (swung down).
  Offset ringOpenOf(int phase) => Offset(phaseX[phase] + 32, armY + 119);

  /// The AB switch's operating handle eye (where the socket goes).
  Offset get handle => Offset(poleX + 18, armY + 66);

  @override
  bool operator ==(Object other) => other is HsGeo && other.height == height && other.groundY == groundY;

  @override
  int get hashCode => Object.hash(height, groundY);
}

/// The yard: sky, far trees, road verge, the pole and what is on its arm.
class HsWorldPainter extends CustomPainter {
  const HsWorldPainter({required this.geo, required this.gear, required this.open, required this.abOff});

  final HsGeo geo;
  final HsGear gear;

  /// Which DO fuses hang open (by phase).
  final List<bool> open;

  /// The AB switch's blades are out (OFF).
  final bool abOff;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    // Sky.
    c.drawRect(
      Rect.fromLTWH(0, 0, 360, g.groundY),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6FA7D8), Color(0xFFBFDCEF), Color(0xFFE9F1EC)],
        ).createShader(Rect.fromLTWH(0, 0, 360, g.groundY)),
    );
    // Clouds.
    final cloud = Paint()..color = const Color(0xCCFFFFFF);
    for (final (x, y, r) in [
      (60.0, g.armY - 70, 20.0),
      (86.0, g.armY - 64, 26.0),
      (112.0, g.armY - 72, 18.0),
      (282.0, g.armY - 110, 16.0),
      (304.0, g.armY - 104, 22.0),
    ]) {
      c.drawCircle(Offset(x, y), r, cloud);
    }
    // Far trees and fields.
    final far = Paint()..color = const Color(0xFF7FA37A);
    final farPath = Path()..moveTo(0, g.groundY - 40);
    for (var x = 0.0; x <= 360; x += 24) {
      farPath.quadraticBezierTo(x + 12, g.groundY - 62 - (x % 72 == 0 ? 14 : 0), x + 24, g.groundY - 40);
    }
    farPath
      ..lineTo(360, g.groundY)
      ..lineTo(0, g.groundY)
      ..close();
    c.drawPath(farPath, far);
    // Ground: the verge and the road.
    c.drawRect(
      Rect.fromLTWH(0, g.groundY, 360, size.height - g.groundY),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8C9A5B), Color(0xFF6E7B45)],
        ).createShader(Rect.fromLTWH(0, g.groundY, 360, size.height - g.groundY)),
    );
    c.drawRect(Rect.fromLTWH(0, g.groundY + 70, 360, 60), Paint()..color = const Color(0xFF5B5F66));
    final dash = Paint()
      ..color = const Color(0xFFE8E2C8)
      ..strokeWidth = 3;
    for (var x = 8.0; x < 360; x += 44) {
      c.drawLine(Offset(x, g.groundY + 100), Offset(x + 22, g.groundY + 100), dash);
    }
    // Pebbles on the verge.
    final peb = Paint()..color = const Color(0x55302A1A);
    final rnd = math.Random(3);
    for (var i = 0; i < 26; i++) {
      c.drawCircle(Offset(rnd.nextDouble() * 360, g.groundY + 6 + rnd.nextDouble() * 58), 1.2 + rnd.nextDouble() * 1.4, peb);
    }

    // The pole (PCC, tapering).
    final pole = Path()
      ..moveTo(HsGeo.poleX - 7, g.armY - 40)
      ..lineTo(HsGeo.poleX + 7, g.armY - 40)
      ..lineTo(HsGeo.poleX + 11, g.groundY + 4)
      ..lineTo(HsGeo.poleX - 11, g.groundY + 4)
      ..close();
    c.drawPath(
      pole,
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFFB9B5AA), Color(0xFF8E8A80)])
            .createShader(Rect.fromLTWH(HsGeo.poleX - 11, g.armY, 22, g.groundY - g.armY)),
    );
    // Danger plate on the pole.
    final plate = Rect.fromLTWH(HsGeo.poleX - 9, g.groundY - 150, 18, 22);
    c.drawRect(plate, Paint()..color = const Color(0xFFF2F2F2));
    c.drawRect(
      plate,
      Paint()
        ..color = const Color(0xFFC0392B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    // The cross-arm (channel).
    c.drawRect(Rect.fromLTRB(HsGeo.armLeft, g.armY - 5, HsGeo.armRight, g.armY + 5), Paint()..color = const Color(0xFF4F555C));
    c.drawRect(Rect.fromLTRB(HsGeo.armLeft, g.armY - 5, HsGeo.armRight, g.armY - 2), Paint()..color = const Color(0xFF79808A));

    // The line: three conductors going off to the right and the left.
    final wire = Paint()
      ..color = const Color(0xFF2E3238)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    for (final (i, x) in HsGeo.phaseX.indexed) {
      final top = Offset(x, g.armY - 22);
      // The pin insulator on the arm (the AB switch has its own posts).
      if (gear == HsGear.doFuse) _insulator(c, Offset(x, g.armY - 5), 16);
      // The phase tag on the arm (R red, Y yellow, B blue).
      final tag = Rect.fromCenter(center: Offset(x - 30, g.armY), width: 12, height: 12);
      c.drawRect(tag, Paint()..color = const [Color(0xFFC0392B), Color(0xFFF1C40F), Color(0xFF2E6FD8)][i]);
      final letter = TextPainter(
        text: TextSpan(
          text: const ['R', 'Y', 'B'][i],
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Color(0xFF111111)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      letter.paint(c, tag.center - Offset(letter.width / 2, letter.height / 2));
      c.drawPath(
        Path()
          ..moveTo(-10, g.armY - 30 - i * 3)
          ..quadraticBezierTo(x * 0.5, g.armY - 12 - i * 3, top.dx, top.dy)
          ..quadraticBezierTo(x + (370 - x) * 0.5, g.armY - 10, 370, g.armY - 34 + i * 3),
        wire,
      );
    }

    if (gear == HsGear.doFuse) {
      for (var i = 0; i < 3; i++) {
        _doFuse(c, i, open[i]);
      }
    } else {
      _abSwitch(c);
    }
  }

  void _insulator(Canvas c, Offset base, double h) {
    final p = Paint()..color = const Color(0xFF8A4B2A);
    for (var k = 0; k < 3; k++) {
      final y = base.dy - k * h / 3;
      c.drawOval(Rect.fromCenter(center: Offset(base.dx, y - 3), width: 13 - k * 1.5, height: 5), p);
    }
    c.drawRect(Rect.fromLTWH(base.dx - 2.2, base.dy - h, 4.4, h), p);
  }

  /// A DO fuse unit: the porcelain body on its bracket, the top and bottom
  /// contacts, and the fuse barrel with its ring (closed: up between the
  /// contacts; open: swung down on its hinge).
  void _doFuse(Canvas c, int phase, bool isOpen) {
    final g = geo;
    final x = HsGeo.phaseX[phase];
    final bracket = Paint()..color = const Color(0xFF5E646B);
    // Bracket from the arm.
    c.drawRect(Rect.fromLTWH(x - 3, g.armY + 5, 6, 14), bracket);
    // The porcelain body (behind the barrel), slanted.
    c.save();
    c.translate(x - 8, g.armY + 18);
    c.rotate(-0.28);
    final body = Paint()..color = const Color(0xFF8A4B2A);
    for (var k = 0; k < 5; k++) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(0, 8 + k * 10), width: 15, height: 6), const Radius.circular(3)), body);
    }
    c.drawRect(const Rect.fromLTWH(-3, 4, 6, 48), body);
    c.restore();
    // Top and bottom contacts.
    final metal = Paint()..color = const Color(0xFFB8BEC6);
    c.drawRect(Rect.fromLTWH(x - 1, g.armY + 22, 16, 5), metal);
    c.drawRect(Rect.fromLTWH(x + 6, g.armY + 70, 16, 5), metal);
    // The barrel.
    final barrel = Paint()..color = const Color(0xFF3A3F45);
    final ring = Paint()
      ..color = const Color(0xFFD9DEE4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    if (!isOpen) {
      final a = Offset(x + 6, g.armY + 30);
      final b = Offset(x + 16, g.armY + 72);
      c.drawLine(
        a,
        b,
        barrel
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round,
      );
      c.drawCircle(g.ringOf(phase) + const Offset(0, -4), 4.2, ring);
    } else {
      final hinge = Offset(x + 16, g.armY + 74);
      final end = hinge + const Offset(14, 40);
      c.drawLine(
        hinge,
        end,
        barrel
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round,
      );
      c.drawCircle(end + const Offset(2, 5), 4.2, ring);
    }
  }

  /// A three-pole AB switch on the arm (blades in = ON) and its operating
  /// handle near the pole, with the spline eye for the rod's socket.
  void _abSwitch(Canvas c) {
    final g = geo;
    final blade = Paint()
      ..color = const Color(0xFFC9CFD6)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (final x in HsGeo.phaseX) {
      // Two post insulators on the arm; the blade across their tops (ON) or
      // swung up off the far contact (OFF).
      _insulator(c, Offset(x - 16, g.armY - 5), 18);
      _insulator(c, Offset(x + 16, g.armY - 5), 18);
      final top = g.armY - 25;
      if (abOff) {
        c.drawLine(Offset(x - 16, top), Offset(x - 2, top - 26), blade);
      } else {
        c.drawLine(Offset(x - 16, top), Offset(x + 16, top), blade);
      }
    }
    // The shaft from the blades to the handle.
    c.drawLine(
      Offset(HsGeo.phaseX.first - 16, g.armY + 30),
      Offset(HsGeo.poleX + 14, g.armY + 30),
      Paint()
        ..color = const Color(0xFF5E646B)
        ..strokeWidth = 3,
    );
    final h = g.handle;
    c.drawLine(
      Offset(HsGeo.poleX + 14, g.armY + 30),
      h,
      Paint()
        ..color = const Color(0xFF5E646B)
        ..strokeWidth = 4,
    );
    c.drawCircle(h, 5.5, Paint()..color = const Color(0xFF3A3F45));
    c.drawCircle(h, 2.6, Paint()..color = const Color(0xFFD9DEE4));
    // ON / OFF on the switch (a label a worker reads).
    final tp = TextPainter(
      text: TextSpan(
        text: abOff ? 'OFF' : 'ON',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: abOff ? const Color(0xFF1E8449) : const Color(0xFFC0392B)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final at = Offset(HsGeo.poleX + 26, g.armY + 54);
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(at.dx - 3, at.dy - 1, tp.width + 6, tp.height + 2), const Radius.circular(3)),
      Paint()..color = const Color(0xFFF7F4EA),
    );
    tp.paint(c, at);
  }

  @override
  bool shouldRepaint(HsWorldPainter old) => old.geo != geo || old.gear != gear || old.abOff != abOff || !_same(old.open, open);

  static bool _same(List<bool> a, List<bool> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// What is on the rod's head.
enum HsHead { none, puller, socket }

/// The hot stick from the trainee's hands to its tip: fibreglass sections
/// (the joints of the telescopic rod), the red hand guard, the attachment.
class HsRodPainter extends CustomPainter {
  const HsRodPainter({required this.butt, required this.tip, required this.head, required this.locked});

  final Offset butt;
  final Offset tip;
  final HsHead head;
  final bool locked;

  /// Where the hand guard sits along the rod, from the butt (fraction).
  static const guardAt = 0.16;

  @override
  void paint(Canvas c, Size size) {
    final d = tip - butt;
    final len = d.distance;
    if (len < 4) return;
    final u = d / len;
    final n = Offset(-u.dy, u.dx);
    final rod = Paint()
      ..color = const Color(0xFFF2B33D)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    c.drawLine(butt, tip, rod);
    c.drawLine(
      butt + n * 1.2,
      tip + n * 1.2,
      Paint()
        ..color = const Color(0x66FFFFFF)
        ..strokeWidth = 1.1,
    );
    // Section joints (green collars when locked, grey when not).
    final joint = Paint()
      ..color = locked ? const Color(0xFF2E7D4F) : const Color(0xFF8A8F96)
      ..strokeWidth = 6;
    for (final f in const [0.38, 0.62, 0.84]) {
      final p = butt + d * f;
      c.drawLine(p - u * 2.5, p + u * 2.5, joint);
    }
    // The hand guard (a red disc across the rod).
    final g = butt + d * guardAt;
    c.drawLine(
      g - n * 6,
      g + n * 6,
      Paint()
        ..color = const Color(0xFFC0392B)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    // The head.
    final hp = Paint()
      ..color = const Color(0xFF5E646B)
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    switch (head) {
      case HsHead.none:
        break;
      case HsHead.puller:
        // A prong and a hook (the fuse puller).
        c.drawLine(tip, tip + u * 8, hp);
        c.drawArc(Rect.fromCircle(center: tip + u * 8 + n * 3, radius: 3.4), math.atan2(n.dy, n.dx) + math.pi, math.pi * 1.2, false, hp);
      case HsHead.socket:
        c.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: tip + u * 4, width: 9, height: 9), const Radius.circular(2)),
          Paint()..color = const Color(0xFF5E646B),
        );
    }
  }

  @override
  bool shouldRepaint(HsRodPainter old) => old.butt != butt || old.tip != tip || old.head != head || old.locked != locked;
}

/// A face shield over the trainee's face (clear visor, grey brow band).
class HsShieldPainter extends CustomPainter {
  const HsShieldPainter();

  @override
  void paint(Canvas c, Size size) {
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(0, size.height * 0.18, size.width, size.height * 0.82), Radius.circular(size.width * 0.3));
    c.drawRRect(r, Paint()..color = const Color(0x6688CCEE));
    c.drawRRect(
      r,
      Paint()
        ..color = const Color(0xCCE6F4FB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    c.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.2), Paint()..color = const Color(0xFF4F555C));
  }

  @override
  bool shouldRepaint(HsShieldPainter old) => false;
}

/// A flash at a contact: the arc's white-blue core and sparks ([v] 0 → 1).
/// [big]: the on-load arc (the deadly one).
class HsArcPainter extends CustomPainter {
  const HsArcPainter({required this.at, required this.v, this.big = false});
  final Offset at;
  final double v;
  final bool big;

  @override
  void paint(Canvas c, Size size) {
    final k = big ? 2.4 : 1.0;
    final fade = (1 - v).clamp(0.0, 1.0);
    final r = (14 + 30 * v) * k;
    c.drawCircle(
      at,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [Color.fromRGBO(255, 255, 240, 0.95 * fade + (big ? 0.05 : 0)), Color.fromRGBO(140, 190, 255, 0.5 * fade), const Color(0x0088BBFF)],
        ).createShader(Rect.fromCircle(center: at, radius: r)),
    );
    final spark = Paint()
      ..color = Color.fromRGBO(255, 210, 90, fade)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 12; i++) {
      final a = i / 12 * math.pi * 2 + 0.4;
      final d0 = (8 + 34 * v) * k;
      final d1 = d0 + 9 * k;
      // Hot metal falls: the sparks drift down.
      final drop = Offset(0, 30 * v * v * k);
      c.drawLine(at + Offset(math.cos(a) * d0, math.sin(a) * d0) + drop, at + Offset(math.cos(a) * d1, math.sin(a) * d1) + drop, spark);
    }
    if (big) {
      final white = (1 - v * 3).clamp(0.0, 1.0);
      if (white > 0) c.drawRect(Offset.zero & size, Paint()..color = Color.fromRGBO(255, 255, 255, 0.8 * white));
    }
  }

  @override
  bool shouldRepaint(HsArcPainter old) => old.v != v || old.at != at || old.big != big;
}

/// The rod close-up for the grip: a vertical rod (butt at the bottom), its
/// red hand guard at [guardFrac] from the butt, and the hands placed so far.
class HsGripPainter extends CustomPainter {
  const HsGripPainter({required this.hands, required this.locked});

  /// Hand positions as fractions from the butt (0) to the top (1).
  final List<double> hands;
  final bool locked;

  static const guardFrac = 0.42;

  @override
  void paint(Canvas c, Size size) {
    final x = size.width / 2;
    final y0 = size.height - 6;
    const y1 = 6.0;
    double yOf(double f) => y0 + (y1 - y0) * f;
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTRB(x - 9, y1, x + 9, y0), const Radius.circular(8)),
      Paint()..shader = const LinearGradient(colors: [Color(0xFFF7C65A), Color(0xFFD99520)]).createShader(Rect.fromLTRB(x - 9, y1, x + 9, y0)),
    );
    // A section joint above the guard.
    c.drawRect(Rect.fromLTRB(x - 11, yOf(0.74) - 4, x + 11, yOf(0.74) + 4), Paint()..color = locked ? const Color(0xFF2E7D4F) : const Color(0xFF8A8F96));
    // The butt cap.
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(x - 10, y0 - 14, x + 10, y0), const Radius.circular(4)), Paint()..color = const Color(0xFF3A3F45));
    // The hand guard.
    final gy = yOf(guardFrac);
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, gy), width: 58, height: 9), const Radius.circular(4)),
      Paint()..color = const Color(0xFFC0392B),
    );
    // The hands: insulated gloves gripping the rod.
    for (final f in hands) {
      final hy = yOf(f);
      final r = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, hy), width: 40, height: 22), const Radius.circular(10));
      c.drawRRect(r, Paint()..color = const Color(0xFFE0B21C));
      c.drawRRect(
        r,
        Paint()
          ..color = const Color(0xFF6B5200)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }
  }

  @override
  bool shouldRepaint(HsGripPainter old) => old.hands.length != hands.length || old.locked != locked || !_eq(old.hands, hands);

  static bool _eq(List<double> a, List<double> b) {
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
