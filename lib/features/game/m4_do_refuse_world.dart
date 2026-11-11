import 'dart:math' as math;

import 'package:flutter/material.dart';

// The place for lesson 4.4 কাজ 2 "ফিউজ উড়েছে — কেন?" (m4_do_refuse.dart):
// a pole-mounted distribution transformer (DTR) by a village road. On the
// cross-arm three DO fuse units (R, Y, B) feed the transformer's HT bushings
// by droppers; the LT cable runs from the tank to the LT box on the pole. One
// barrel has dropped (blown: hanging on its hinge, the tail scorched). The
// trainee works from the ground with the hot stick. The link work is a
// close-up: the barrel on a tarpaulin ([M4DoRefuseBenchPainter]). Design
// space: 360 wide, [M4DoRefuseGeo.height] high. Static painters only (they
// repaint when the play changes, never on a clock).

/// A DO barrel's state on the cross-arm.
enum M4DoRefuseBarrel { closed, open, gone }

/// The scene's geometry (design px).
@immutable
class M4DoRefuseGeo {
  const M4DoRefuseGeo._(this.height, this.groundY, this.armY);

  factory M4DoRefuseGeo.forScene(double height, double inset) {
    final ground = height - 172 - inset * 0.4;
    final arm = math.max(150.0, ground - 400);
    return M4DoRefuseGeo._(height, ground, arm);
  }

  final double height;
  final double groundY;
  final double armY;

  static const poleX = 110.0;
  static const armLeft = 92.0;
  static const armRight = 300.0;

  /// The three phases, left to right (R, Y, B).
  static const phaseX = [170.0, 220.0, 270.0];

  /// The trainee's height on screen.
  double get man => 86;

  double get _span => groundY - armY;

  /// The transformer tank (body only).
  Rect get tank {
    final h = (_span * 0.2).clamp(50.0, 86.0);
    final top = armY + _span * 0.42;
    return Rect.fromLTWH(164, top, 112, h);
  }

  /// The HT bushing tops on the tank lid (R, Y, B).
  Offset bushingOf(int phase) => Offset(tank.left + 22 + phase * 34, tank.top - 16);

  /// A DO fuse's ring (the pull eye at the top of the barrel), closed.
  Offset ringOf(int phase) => Offset(phaseX[phase] + 6, armY + 30);

  /// The bottom hinge where a barrel is seated before it is pushed home.
  Offset hingeOf(int phase) => Offset(phaseX[phase] + 16, armY + 74);

  /// The ring when the barrel hangs open (swung down on its hinge).
  Offset ringOpenOf(int phase) => Offset(phaseX[phase] + 38, armY + 113);

  /// Where a tap counts as "this fuse" (the unit with its hanging barrel).
  Rect unitOf(int phase) => Rect.fromLTRB(phaseX[phase] - 14, armY + 8, phaseX[phase] + 40, armY + 124);

  @override
  bool operator ==(Object other) => other is M4DoRefuseGeo && other.height == height && other.groundY == groundY;

  @override
  int get hashCode => Object.hash(height, groundY);
}

/// The yard: sky, far trees, the verge, the DTR pole with its DO fuses.
class M4DoRefuseWorldPainter extends CustomPainter {
  const M4DoRefuseWorldPainter({required this.geo, required this.barrels, required this.blown});

  final M4DoRefuseGeo geo;

  /// Each phase's barrel (R, Y, B).
  final List<M4DoRefuseBarrel> barrels;

  /// The phase whose link blew (its hanging barrel shows the scorched tail).
  final int? blown;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    // Sky (late afternoon).
    c.drawRect(
      Rect.fromLTWH(0, 0, 360, g.groundY),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5E93C8), Color(0xFFB7D3EA), Color(0xFFF1E7D2)],
        ).createShader(Rect.fromLTWH(0, 0, 360, g.groundY)),
    );
    final cloud = Paint()..color = const Color(0xCCFFFFFF);
    for (final (x, y, r) in [
      (40.0, g.armY - 80, 18.0),
      (64.0, g.armY - 74, 24.0),
      (90.0, g.armY - 82, 16.0),
      (300.0, g.armY - 118, 15.0),
      (322.0, g.armY - 112, 20.0),
    ]) {
      c.drawCircle(Offset(x, y), r, cloud);
    }
    // Far trees and a village roof line.
    final far = Paint()..color = const Color(0xFF7A9C72);
    final farPath = Path()..moveTo(0, g.groundY - 44);
    for (var x = 0.0; x <= 360; x += 26) {
      farPath.quadraticBezierTo(x + 13, g.groundY - 66 - (x % 78 == 0 ? 16 : 0), x + 26, g.groundY - 44);
    }
    farPath
      ..lineTo(360, g.groundY)
      ..lineTo(0, g.groundY)
      ..close();
    c.drawPath(farPath, far);
    final roof = Paint()..color = const Color(0xFF9C6B4E);
    final wall = Paint()..color = const Color(0xFFD9C7A3);
    for (final x in [18.0, 316.0]) {
      c.drawRect(Rect.fromLTWH(x, g.groundY - 34, 34, 34), wall);
      c.drawPath(
        Path()
          ..moveTo(x - 5, g.groundY - 34)
          ..lineTo(x + 17, g.groundY - 52)
          ..lineTo(x + 39, g.groundY - 34)
          ..close(),
        roof,
      );
      // The houses are dark: no supply.
      c.drawRect(Rect.fromLTWH(x + 12, g.groundY - 24, 10, 10), Paint()..color = const Color(0xFF3B3A36));
    }
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
    c.drawRect(Rect.fromLTWH(0, g.groundY + 74, 360, 58), Paint()..color = const Color(0xFF5B5F66));
    final peb = Paint()..color = const Color(0x55302A1A);
    final rnd = math.Random(7);
    for (var i = 0; i < 26; i++) {
      c.drawCircle(Offset(rnd.nextDouble() * 360, g.groundY + 6 + rnd.nextDouble() * 60), 1.2 + rnd.nextDouble() * 1.4, peb);
    }

    // The pole (PCC, tapering).
    final pole = Path()
      ..moveTo(M4DoRefuseGeo.poleX - 7, g.armY - 40)
      ..lineTo(M4DoRefuseGeo.poleX + 7, g.armY - 40)
      ..lineTo(M4DoRefuseGeo.poleX + 11, g.groundY + 4)
      ..lineTo(M4DoRefuseGeo.poleX - 11, g.groundY + 4)
      ..close();
    c.drawPath(
      pole,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFB9B5AA), Color(0xFF8E8A80)],
        ).createShader(Rect.fromLTWH(M4DoRefuseGeo.poleX - 11, g.armY, 22, g.groundY - g.armY)),
    );
    // Danger plate.
    final plate = Rect.fromLTWH(M4DoRefuseGeo.poleX - 9, g.groundY - 150, 18, 22);
    c.drawRect(plate, Paint()..color = const Color(0xFFF2F2F2));
    c.drawRect(
      plate,
      Paint()
        ..color = const Color(0xFFC0392B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    // The cross-arm.
    c.drawRect(Rect.fromLTRB(M4DoRefuseGeo.armLeft, g.armY - 5, M4DoRefuseGeo.armRight, g.armY + 5), Paint()..color = const Color(0xFF4F555C));
    c.drawRect(Rect.fromLTRB(M4DoRefuseGeo.armLeft, g.armY - 5, M4DoRefuseGeo.armRight, g.armY - 2), Paint()..color = const Color(0xFF79808A));

    // The 11 kV line comes in on pin insulators and down to the fuses.
    final wire = Paint()
      ..color = const Color(0xFF2E3238)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    for (final (i, x) in M4DoRefuseGeo.phaseX.indexed) {
      _insulator(c, Offset(x, g.armY - 5), 16);
      final tag = Rect.fromCenter(center: Offset(x - 26, g.armY), width: 12, height: 12);
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
          ..moveTo(370, g.armY - 40 + i * 4)
          ..quadraticBezierTo(x + (370 - x) * 0.5, g.armY - 14, x, g.armY - 22),
        wire,
      );
      // The jumper from the line down to the fuse's top contact.
      c.drawLine(Offset(x, g.armY - 22), Offset(x + 2, g.armY + 22), wire);
    }

    // The platform and the transformer.
    final t = g.tank;
    final steel = Paint()..color = const Color(0xFF4F555C);
    c.drawRect(Rect.fromLTRB(M4DoRefuseGeo.poleX - 4, t.bottom + 2, t.right + 14, t.bottom + 9), steel);
    c.drawLine(
      Offset(M4DoRefuseGeo.poleX + 6, t.bottom + 30),
      Offset(t.left + 20, t.bottom + 8),
      steel..strokeWidth = 4,
    );
    // Radiator fins.
    final fin = Paint()..color = const Color(0xFF66745F);
    for (var k = 0; k < 6; k++) {
      c.drawRect(Rect.fromLTWH(t.left + 8 + k * 17, t.top + 8, 9, t.height - 12), fin);
    }
    c.drawRRect(
      RRect.fromRectAndRadius(t.deflate(10), const Radius.circular(4)),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF8C9A84), Color(0xFF6B7865)],
        ).createShader(t),
    );
    c.drawRect(Rect.fromLTWH(t.left + 4, t.top - 4, t.width - 8, 6), Paint()..color = const Color(0xFF5A6654));
    // HT bushings and the droppers from each fuse's bottom contact.
    final drop = Paint()
      ..color = const Color(0xFF2E3238)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 3; i++) {
      final b = g.bushingOf(i);
      _bushing(c, b, 14);
      final from = Offset(M4DoRefuseGeo.phaseX[i] + 14, g.armY + 76);
      c.drawPath(
        Path()
          ..moveTo(from.dx, from.dy)
          ..quadraticBezierTo(from.dx + 8, (from.dy + b.dy) / 2, b.dx, b.dy),
        drop,
      );
    }
    // LT side: the cable from the tank down to the LT box on the pole.
    final ltBox = Rect.fromLTWH(M4DoRefuseGeo.poleX + 12, t.bottom + 46, 30, 38);
    c.drawPath(
      Path()
        ..moveTo(t.left + 6, t.center.dy)
        ..quadraticBezierTo(t.left - 30, t.center.dy + 10, ltBox.center.dx, ltBox.top),
      Paint()
        ..color = const Color(0xFF1F1F1F)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke,
    );
    c.drawRRect(RRect.fromRectAndRadius(ltBox, const Radius.circular(3)), Paint()..color = const Color(0xFF8E9AA6));
    c.drawRect(Rect.fromLTWH(ltBox.left + 4, ltBox.top + 4, ltBox.width - 8, 6), Paint()..color = const Color(0xFF66727E));
    c.drawLine(
      Offset(ltBox.center.dx, ltBox.bottom),
      Offset(ltBox.center.dx - 4, g.groundY + 2),
      Paint()
        ..color = const Color(0xFF1F1F1F)
        ..strokeWidth = 3,
    );

    for (var i = 0; i < 3; i++) {
      _doFuse(c, i, barrels[i], i == blown);
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

  void _bushing(Canvas c, Offset top, double h) {
    final p = Paint()..color = const Color(0xFF8A4B2A);
    for (var k = 0; k < 3; k++) {
      c.drawOval(Rect.fromCenter(center: Offset(top.dx, top.dy + 4 + k * h / 3), width: 9 + k * 1.2, height: 4), p);
    }
    c.drawRect(Rect.fromLTWH(top.dx - 2, top.dy, 4, h), p);
  }

  /// A DO fuse unit: the porcelain body on its bracket, the top and bottom
  /// contacts, and the barrel (closed: up between the contacts; open: swung
  /// down on its hinge; gone: taken down — the hinge is empty).
  void _doFuse(Canvas c, int phase, M4DoRefuseBarrel state, bool blown) {
    final g = geo;
    final x = M4DoRefuseGeo.phaseX[phase];
    c.drawRect(Rect.fromLTWH(x - 3, g.armY + 5, 6, 14), Paint()..color = const Color(0xFF5E646B));
    c.save();
    c.translate(x - 8, g.armY + 18);
    c.rotate(-0.28);
    final body = Paint()..color = const Color(0xFF8A4B2A);
    for (var k = 0; k < 5; k++) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(0, 8 + k * 10), width: 15, height: 6), const Radius.circular(3)), body);
    }
    c.drawRect(const Rect.fromLTWH(-3, 4, 6, 48), body);
    c.restore();
    final metal = Paint()..color = const Color(0xFFB8BEC6);
    c.drawRect(Rect.fromLTWH(x - 1, g.armY + 22, 16, 5), metal);
    c.drawRect(Rect.fromLTWH(x + 6, g.armY + 70, 16, 5), metal);
    final barrel = Paint()
      ..color = const Color(0xFF3A3F45)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final ring = Paint()
      ..color = const Color(0xFFD9DEE4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    switch (state) {
      case M4DoRefuseBarrel.closed:
        c.drawLine(Offset(x + 6, g.armY + 30), Offset(x + 16, g.armY + 72), barrel);
        c.drawCircle(g.ringOf(phase) + const Offset(0, -4), 4.2, ring);
      case M4DoRefuseBarrel.open:
        // Swung out and down on its hinge; the top contact stands empty.
        final hinge = g.hingeOf(phase);
        final end = hinge + const Offset(20, 34);
        c.drawLine(hinge, end, barrel);
        c.drawCircle(g.ringOpenOf(phase), 4.2, ring);
        c.drawRect(Rect.fromLTWH(x + 4, g.armY + 27, 8, 2), Paint()..color = const Color(0xFF2B2F35));
        if (blown) {
          // The blown link: soot at the mouth, a scorched tail hanging out.
          c.drawCircle(hinge + const Offset(-1, 1), 7, Paint()..color = const Color(0x88201510));
          final tail = Paint()
            ..color = const Color(0xFF1E140E)
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke;
          c.drawPath(
            Path()
              ..moveTo(hinge.dx - 1, hinge.dy + 1)
              ..quadraticBezierTo(hinge.dx - 12, hinge.dy + 10, hinge.dx - 7, hinge.dy + 24),
            tail,
          );
        }
      case M4DoRefuseBarrel.gone:
        c.drawCircle(g.hingeOf(phase), 3, Paint()..color = const Color(0xFF8A8F96));
    }
  }

  @override
  bool shouldRepaint(M4DoRefuseWorldPainter old) => old.geo != geo || old.blown != blown || !_same(old.barrels, barrels);

  static bool _same(List<M4DoRefuseBarrel> a, List<M4DoRefuseBarrel> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// A DO barrel hanging from the rod's fuse puller (being taken down or put up).
class M4DoRefuseCarryPainter extends CustomPainter {
  const M4DoRefuseCarryPainter({required this.at, required this.fresh});

  /// The puller's hook (design px).
  final Offset at;

  /// The new link is in it (a cream tail), not the scorched one.
  final bool fresh;

  @override
  void paint(Canvas c, Size size) {
    final ring = Paint()
      ..color = const Color(0xFFD9DEE4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    c.drawCircle(at + const Offset(0, 4), 4.2, ring);
    final top = at + const Offset(0, 8);
    final bottom = top + const Offset(4, 40);
    c.drawLine(
      top,
      bottom,
      Paint()
        ..color = const Color(0xFF3A3F45)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );
    c.drawPath(
      Path()
        ..moveTo(bottom.dx, bottom.dy + 2)
        ..quadraticBezierTo(bottom.dx + 6, bottom.dy + 8, bottom.dx + 2, bottom.dy + 14),
      Paint()
        ..color = fresh ? const Color(0xFFC98A3A) : const Color(0xFF3B2A1E)
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(M4DoRefuseCarryPainter old) => old.at != at || old.fresh != fresh;
}

/// What lies on the tarpaulin in the link close-up.
@immutable
class M4DoRefuseBench {
  const M4DoRefuseBench({
    this.link,
    this.cleaned = false,
    this.buttonIn = false,
    this.wrapped = false,
    this.portChecked = false,
    this.portBlocked = false,
  });

  /// The chosen link's label (e.g. "10A"); null = none yet.
  final String? link;
  final bool cleaned;
  final bool buttonIn;
  final bool wrapped;
  final bool portChecked;

  /// The leader wire lies across the expulsion port until it is checked.
  final bool portBlocked;

  @override
  bool operator ==(Object other) =>
      other is M4DoRefuseBench &&
      other.link == link &&
      other.cleaned == cleaned &&
      other.buttonIn == buttonIn &&
      other.wrapped == wrapped &&
      other.portChecked == portChecked &&
      other.portBlocked == portBlocked;

  @override
  int get hashCode => Object.hash(link, cleaned, buttonIn, wrapped, portChecked, portBlocked);
}

/// The barrel close-up, [M4DoRefuseBenchPainter.size] (300 × 150): the tube
/// across, the top contact (button seat) at the left, the bottom contact with
/// its nut and the expulsion port at the right; the link below until it goes in.
class M4DoRefuseBenchPainter extends CustomPainter {
  const M4DoRefuseBenchPainter({required this.bench});
  final M4DoRefuseBench bench;

  static const size = Size(300, 150);

  /// Tap areas (in the painter's box).
  static const topContact = Rect.fromLTWH(4, 30, 62, 70);
  static const bottomNut = Rect.fromLTWH(200, 30, 52, 70);
  static const port = Rect.fromLTWH(252, 30, 46, 70);

  @override
  void paint(Canvas c, Size s) {
    final b = bench;
    // Tarpaulin.
    c.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(12)),
      Paint()..color = const Color(0xFF2F5D7C),
    );
    final weave = Paint()
      ..color = const Color(0x22FFFFFF)
      ..strokeWidth = 1;
    for (var x = 10.0; x < s.width; x += 14) {
      c.drawLine(Offset(x, 4), Offset(x, s.height - 4), weave);
    }
    const y = 64.0;
    // The tube.
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTRB(46, y - 11, 262, y + 11), const Radius.circular(6)), Paint()..color = const Color(0xFF3A3F45));
    c.drawRect(const Rect.fromLTRB(52, y - 9, 256, y - 6), Paint()..color = const Color(0x33FFFFFF));
    // Top contact (cap with the button seat) and bottom contact with the nut.
    final metal = Paint()..color = const Color(0xFFB8BEC6);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTRB(22, y - 18, 50, y + 18), const Radius.circular(4)), metal);
    c.drawCircle(const Offset(30, y), 6, Paint()..color = const Color(0xFF5E646B));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTRB(212, y - 18, 240, y + 18), const Radius.circular(4)), metal);
    c.drawCircle(const Offset(226, y + 4), 7, Paint()..color = const Color(0xFF8A8F96));
    c.drawCircle(const Offset(226, y + 4), 3, Paint()..color = const Color(0xFF4F555C));
    // The pull ring at the top end.
    c.drawCircle(
      const Offset(14, y - 18),
      6,
      Paint()
        ..color = const Color(0xFFD9DEE4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6,
    );
    // The expulsion port (the barrel's open mouth).
    c.drawOval(Rect.fromCenter(center: const Offset(264, y), width: 10, height: 20), Paint()..color = const Color(0xFF0E0F11));
    // Dirt on the contacts until wiped.
    if (!b.cleaned) {
      final dirt = Paint()..color = const Color(0xCC6B4A2B);
      for (final o in const [Offset(28, y - 10), Offset(42, y + 9), Offset(218, y - 11), Offset(234, y + 12), Offset(36, y + 2)]) {
        c.drawCircle(o, 4.2, dirt);
      }
    } else {
      final shine = Paint()..color = const Color(0x99FFFFFF);
      c.drawRect(const Rect.fromLTRB(24, y - 16, 48, y - 13), shine);
      c.drawRect(const Rect.fromLTRB(214, y - 16, 238, y - 13), shine);
    }
    final tail = Paint()
      ..color = const Color(0xFFC98A3A)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    if (b.link != null && !b.buttonIn) {
      // The link below the tube: button, element, the flexible tail; its tag.
      const ly = y + 52.0;
      c.drawCircle(const Offset(70, ly), 7, Paint()..color = const Color(0xFFB8BEC6));
      c.drawRect(const Rect.fromLTRB(76, ly - 3, 140, ly + 3), Paint()..color = const Color(0xFFD8C9A0));
      c.drawPath(
        Path()
          ..moveTo(140, ly)
          ..quadraticBezierTo(170, ly - 10, 200, ly)
          ..quadraticBezierTo(220, ly + 8, 236, ly),
        tail,
      );
      _tag(c, Offset(100, ly + 8), b.link!);
    }
    if (b.buttonIn) {
      // The link inside the tube (dashed), the button home in the cap.
      final inside = Paint()
        ..color = const Color(0xCCD8C9A0)
        ..strokeWidth = 2;
      for (var x = 54.0; x < 252; x += 10) {
        c.drawLine(Offset(x, y), Offset(x + 5, y), inside);
      }
      c.drawCircle(const Offset(30, y), 5, Paint()..color = const Color(0xFFE8E2C8));
      if (b.wrapped) {
        // Wound round the bottom contact, the nut tight.
        c.drawPath(
          Path()
            ..moveTo(212, y + 2)
            ..cubicTo(220, y - 14, 232, y - 14, 232, y + 4)
            ..cubicTo(232, y + 18, 218, y + 18, 220, y + 6),
          tail,
        );
      } else {
        // The tail hangs loose out of the port.
        c.drawPath(
          Path()
            ..moveTo(262, y + 2)
            ..quadraticBezierTo(284, y + 20, 270, y + 50),
          tail,
        );
      }
      if (b.wrapped && b.portBlocked && !b.portChecked) {
        // The leader wire lies across the port.
        c.drawPath(
          Path()
            ..moveTo(240, y - 4)
            ..quadraticBezierTo(276, y - 2, 262, y + 12)
            ..quadraticBezierTo(254, y + 20, 270, y + 22),
          tail..strokeWidth = 3,
        );
      }
      if (b.portChecked) {
        // The port is clear: the leader tucked aside.
        c.drawPath(
          Path()
            ..moveTo(240, y + 8)
            ..quadraticBezierTo(246, y + 26, 240, y + 34),
          tail..strokeWidth = 2.2,
        );
        final ok = Paint()
          ..color = const Color(0xFF7FE0A0)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        c.drawPath(
          Path()
            ..moveTo(272, y - 30)
            ..lineTo(278, y - 24)
            ..lineTo(290, y - 38),
          ok,
        );
      }
    }
  }

  void _tag(Canvas c, Offset at, String text) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFF2B2416)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final r = Rect.fromLTWH(at.dx, at.dy, tp.width + 10, tp.height + 4);
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), Paint()..color = const Color(0xFFF7F1E1));
    tp.paint(c, at + const Offset(5, 2));
  }

  @override
  bool shouldRepaint(M4DoRefuseBenchPainter old) => old.bench != bench;
}

/// A tray item: a fuse link with its rating tag, or a coil of thick wire.
class M4DoRefuseTrayPainter extends CustomPainter {
  const M4DoRefuseTrayPainter({required this.thick});
  final bool thick;

  @override
  void paint(Canvas c, Size s) {
    final mid = Offset(s.width / 2, s.height / 2 - 4);
    if (thick) {
      final p = Paint()
        ..color = const Color(0xFF9A6A40)
        ..strokeWidth = 4.5
        ..style = PaintingStyle.stroke;
      c.drawOval(Rect.fromCenter(center: mid, width: 40, height: 26), p);
      c.drawOval(Rect.fromCenter(center: mid, width: 28, height: 16), p..color = const Color(0xFF7A5230));
      c.drawLine(mid + const Offset(18, 4), mid + const Offset(26, 16), p..color = const Color(0xFF9A6A40));
      return;
    }
    c.drawCircle(mid + const Offset(-20, 0), 5, Paint()..color = const Color(0xFFB8BEC6));
    c.drawRect(Rect.fromLTRB(mid.dx - 15, mid.dy - 2.5, mid.dx + 8, mid.dy + 2.5), Paint()..color = const Color(0xFFD8C9A0));
    c.drawPath(
      Path()
        ..moveTo(mid.dx + 8, mid.dy)
        ..quadraticBezierTo(mid.dx + 16, mid.dy - 7, mid.dx + 22, mid.dy + 2),
      Paint()
        ..color = const Color(0xFFC98A3A)
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(M4DoRefuseTrayPainter old) => old.thick != thick;
}
