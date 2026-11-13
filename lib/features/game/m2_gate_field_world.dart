import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

// The drawn world of the Module 2 rank gate (m2_gate_field.dart): the
// transformer yard (double pole, three DO fuses, the LT box), the van's
// tailgate bench for the close-up jobs, and the tools themselves. Everything
// is painted (no new picture assets), in design pixels (360 wide).

// ============================================================================
// Tools
// ============================================================================

/// What lies on the van's shelf at station 1.
enum M2Tool { pliers, multimeter, hotStick, skinKnife, crimper, megger, phaseMeter, bamboo, flawed }

/// The bad twin dealt on the shelf: it looks like a docket tool until it is
/// picked up and looked at.
enum M2Flaw { pliersCrack, stickCrack, leadCut, catTwo }

extension M2FlawTwin on M2Flaw {
  /// The docket tool it pretends to be.
  M2Tool get twin => switch (this) {
        M2Flaw.pliersCrack => M2Tool.pliers,
        M2Flaw.stickCrack => M2Tool.hotStick,
        M2Flaw.leadCut => M2Tool.multimeter,
        M2Flaw.catTwo => M2Tool.multimeter,
      };
}

/// Draws one tool lying flat, fitted into the canvas. [flaw] draws the defect
/// (only meaningful for the flaw's twin kind).
class M2ToolPainter extends CustomPainter {
  const M2ToolPainter(this.tool, {this.flaw, this.dirty = false});

  final M2Tool tool;
  final M2Flaw? flaw;

  /// Mud and grease after the day's work (station 7).
  final bool dirty;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    final s = math.min(size.width / 100, size.height / 60);
    canvas.translate((size.width - 100 * s) / 2, (size.height - 60 * s) / 2);
    canvas.scale(s);
    final kind = tool == M2Tool.flawed ? (flaw?.twin ?? M2Tool.pliers) : tool;
    final bad = tool == M2Tool.flawed ? flaw : null;
    switch (kind) {
      case M2Tool.pliers:
        _pliers(canvas, bad == M2Flaw.pliersCrack);
      case M2Tool.multimeter:
        _multimeter(canvas, cut: bad == M2Flaw.leadCut, catTwo: bad == M2Flaw.catTwo);
      case M2Tool.hotStick:
        _hotStick(canvas, bad == M2Flaw.stickCrack);
      case M2Tool.skinKnife:
        _knife(canvas);
      case M2Tool.crimper:
        _crimper(canvas);
      case M2Tool.megger:
        _megger(canvas);
      case M2Tool.phaseMeter:
        _phaseMeter(canvas);
      case M2Tool.bamboo:
        _bamboo(canvas);
      case M2Tool.flawed:
        break;
    }
    if (dirty) {
      final mud = Paint()..color = const Color(0x995A3E22);
      for (final o in const [Offset(30, 34), Offset(56, 26), Offset(72, 38), Offset(44, 44)]) {
        canvas.drawOval(Rect.fromCenter(center: o, width: 9, height: 5), mud);
      }
    }
    canvas.restore();
  }

  void _pliers(Canvas c, bool crack) {
    final steel = Paint()..color = const Color(0xFF9AA4AE);
    final dark = Paint()..color = const Color(0xFF5E6873);
    // Jaws.
    c.drawPath(Path()..moveTo(8, 27)..lineTo(36, 24)..lineTo(40, 30)..lineTo(36, 36)..lineTo(8, 33)..close(), steel);
    c.drawLine(const Offset(10, 30), const Offset(36, 30), dark..strokeWidth = 1.2);
    c.drawCircle(const Offset(42, 30), 5, dark);
    // Insulated handles (red with yellow collar), 1000V marking.
    final red = Paint()..color = const Color(0xFFD7312B);
    final yel = Paint()..color = const Color(0xFFFFC928);
    c.drawPath(Path()..moveTo(46, 26)..quadraticBezierTo(70, 14, 94, 16)..lineTo(95, 22)..quadraticBezierTo(72, 22, 48, 30)..close(), red);
    c.drawPath(Path()..moveTo(46, 34)..quadraticBezierTo(70, 46, 94, 44)..lineTo(95, 38)..quadraticBezierTo(72, 38, 48, 30)..close(), red);
    c.drawRect(const Rect.fromLTWH(48, 23, 4, 14), yel);
    _label(c, '1000V', const Offset(72, 30), 6.5, Colors.white);
    if (crack) {
      final k = Paint()
        ..color = const Color(0xFF2A1A12)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke;
      c.drawPath(Path()..moveTo(62, 17)..lineTo(65, 21)..lineTo(63, 24)..lineTo(67, 27), k);
      c.drawCircle(const Offset(65, 21), 1.2, Paint()..color = const Color(0xFF9AA4AE));
    }
  }

  void _multimeter(Canvas c, {required bool cut, required bool catTwo}) {
    final body = RRect.fromRectAndRadius(const Rect.fromLTWH(30, 4, 40, 54), const Radius.circular(6));
    c.drawRRect(body, Paint()..color = const Color(0xFFF2B705));
    c.drawRRect(body.deflate(3), Paint()..color = const Color(0xFF2B2F36));
    c.drawRect(const Rect.fromLTWH(36, 10, 28, 12), Paint()..color = const Color(0xFFB9D8B0));
    c.drawCircle(const Offset(50, 36), 8, Paint()..color = const Color(0xFF4A4F57));
    c.drawLine(const Offset(50, 36), const Offset(50, 29), Paint()..color = Colors.white..strokeWidth = 1.6);
    _label(c, catTwo ? 'CAT II 300V' : 'CAT IV 600V', const Offset(50, 51), 5, catTwo ? const Color(0xFFFFD0C8) : Colors.white);
    // Leads.
    final red = Paint()
      ..color = const Color(0xFFD7312B)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    final blk = Paint()
      ..color = const Color(0xFF111111)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    c.drawPath(Path()..moveTo(44, 57)..quadraticBezierTo(30, 66, 12, 46)..lineTo(6, 40), blk);
    if (cut) {
      c.drawPath(Path()..moveTo(56, 57)..quadraticBezierTo(70, 64, 80, 54), red);
      c.drawLine(const Offset(80, 54), const Offset(84, 50), Paint()..color = const Color(0xFFD08A3A)..strokeWidth = 2);
      c.drawPath(Path()..moveTo(85, 49)..lineTo(92, 40)..lineTo(96, 36), red);
    } else {
      c.drawPath(Path()..moveTo(56, 57)..quadraticBezierTo(70, 66, 88, 46)..lineTo(94, 40), red);
    }
  }

  void _hotStick(Canvas c, bool crack) {
    final glass = Paint()..color = const Color(0xFFF1C232);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(4, 26, 84, 8), const Radius.circular(4)), glass);
    c.drawRect(const Rect.fromLTWH(18, 26, 4, 8), Paint()..color = const Color(0xFFD7312B));
    c.drawRect(const Rect.fromLTWH(4, 26, 12, 8), Paint()..color = const Color(0xFF3B3F45));
    // Fuse-puller head (hook).
    final head = Paint()
      ..color = const Color(0xFF7D8791)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    c.drawLine(const Offset(88, 30), const Offset(94, 30), head);
    c.drawArc(Rect.fromCircle(center: const Offset(94, 24), radius: 6), -math.pi / 2, math.pi * 1.4, false, head);
    if (crack) {
      final k = Paint()
        ..color = const Color(0xFF3A2410)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      c.drawPath(Path()..moveTo(52, 26)..lineTo(55, 29)..lineTo(53, 31)..lineTo(57, 34), k);
      c.drawPath(Path()..moveTo(60, 26)..lineTo(62, 30), k..strokeWidth = 1);
    }
  }

  void _knife(Canvas c) {
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8, 24, 44, 12), const Radius.circular(5)), Paint()..color = const Color(0xFF1F5F8F));
    c.drawRect(const Rect.fromLTWH(14, 24, 3, 12), Paint()..color = const Color(0xFFFFC928));
    c.drawPath(
      Path()
        ..moveTo(52, 25)
        ..lineTo(84, 22)
        ..quadraticBezierTo(94, 24, 90, 32)
        ..lineTo(84, 30)
        ..lineTo(52, 35)
        ..close(),
      Paint()..color = const Color(0xFFC9D1D9),
    );
    c.drawLine(const Offset(54, 34), const Offset(84, 30), Paint()..color = const Color(0xFF8C969F)..strokeWidth = 1);
  }

  void _crimper(Canvas c) {
    final red = Paint()..color = const Color(0xFFC62828);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(36, 26, 60, 8), const Radius.circular(4)), red);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(40, 40, 52, 7), const Radius.circular(3.5)), red);
    c.drawLine(const Offset(40, 44), const Offset(32, 34), Paint()..color = const Color(0xFF6B7480)..strokeWidth = 4);
    // C-head with hex die.
    final head = Paint()
      ..color = const Color(0xFF6B7480)
      ..strokeWidth = 7
      ..style = PaintingStyle.stroke;
    c.drawArc(Rect.fromCircle(center: const Offset(20, 30), radius: 13), 0.6, math.pi * 1.7, false, head);
    final hex = Path();
    for (var i = 0; i < 6; i++) {
      final a = math.pi / 3 * i;
      final p = Offset(20 + 6 * math.cos(a), 30 + 6 * math.sin(a));
      i == 0 ? hex.moveTo(p.dx, p.dy) : hex.lineTo(p.dx, p.dy);
    }
    c.drawPath(hex..close(), Paint()..color = const Color(0xFFB0B8C0));
  }

  void _megger(Canvas c) {
    final body = RRect.fromRectAndRadius(const Rect.fromLTWH(22, 8, 56, 46), const Radius.circular(6));
    c.drawRRect(body, Paint()..color = const Color(0xFFE8711C));
    c.drawRRect(body.deflate(4), Paint()..color = const Color(0xFF2B2F36));
    c.drawRect(const Rect.fromLTWH(30, 14, 26, 12), Paint()..color = const Color(0xFFB9D8B0));
    c.drawCircle(const Offset(66, 34), 7, Paint()..color = const Color(0xFF4A4F57));
    c.drawCircle(const Offset(40, 42), 5, Paint()..color = const Color(0xFFD7312B));
    _label(c, 'MΩ', const Offset(43, 20), 6, const Color(0xFF203020));
  }

  void _phaseMeter(Canvas c) {
    final body = RRect.fromRectAndRadius(const Rect.fromLTWH(38, 14, 30, 34), const Radius.circular(5));
    c.drawRRect(body, Paint()..color = const Color(0xFF5B6570));
    c.drawCircle(const Offset(47, 24), 3, Paint()..color = const Color(0xFF41C463));
    c.drawCircle(const Offset(59, 24), 3, Paint()..color = const Color(0xFFE04B3A));
    _label(c, 'R-Y-B', const Offset(53, 38), 5.5, Colors.white);
    final cols = [const Color(0xFFD7312B), const Color(0xFFF2C40F), const Color(0xFF2A62C9)];
    for (var i = 0; i < 3; i++) {
      c.drawPath(
        Path()
          ..moveTo(42 + i * 6.0, 48)
          ..quadraticBezierTo(30 - i * 6.0, 58, 10 + i * 4.0, 46 - i * 3.0),
        Paint()
          ..color = cols[i]
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _bamboo(Canvas c) {
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(4, 26, 92, 8), const Radius.circular(4)), Paint()..color = const Color(0xFFC6A85A));
    final node = Paint()
      ..color = const Color(0xFF8A7536)
      ..strokeWidth = 2;
    for (final x in const [22.0, 42.0, 62.0, 82.0]) {
      c.drawLine(Offset(x, 26), Offset(x, 34), node);
    }
    c.drawCircle(const Offset(52, 30), 1.5, Paint()..color = const Color(0xFF5AA0D8));
  }

  @override
  bool shouldRepaint(M2ToolPainter old) => old.tool != tool || old.flaw != flaw || old.dirty != dirty;
}

void _label(Canvas c, String text, Offset centre, double size, Color color) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, color: color)),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
}

void _bnLabel(Canvas c, String text, Offset centre, double size, Color color) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: bangla(fontSize: size, fontWeight: FontWeight.w800, color: color)),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
}

// ============================================================================
// The transformer yard (stations 2 and 6)
// ============================================================================

/// Where things stand in the yard, for a scene [h] design pixels high.
@immutable
class M2YardGeo {
  const M2YardGeo(this.h);
  final double h;

  double get groundY => h - 220;
  double get top => 150;
  double get span => groundY - top;
  static const poleL = 206.0;
  static const poleR = 314.0;
  double get armY => top + 14;
  double doX(int i) => 222.0 + i * 38;
  double get doTopY => armY + 6;
  double get doLen => 38;
  Offset doRing(int i) => Offset(doX(i), doTopY + doLen);
  double get tankY => top + span * 0.36;
  Rect get tank => Rect.fromLTWH(222, tankY, 76, math.max(56, span * 0.2));
  Rect get ltBox => Rect.fromLTWH(poleL - 40, groundY - span * 0.36, 34, 44);
  Rect get ltSwitch => Rect.fromLTWH(ltBox.left + 6, ltBox.top + 14, 22, 16);

  /// The two places to stand under the DO fuses.
  Offset get underSpot => Offset(doX(1), groundY);
  Offset get sideSpot => Offset(doX(0) - 104, groundY);

  /// The worker standing at [foot] (feet at the bottom centre).
  Rect figureAt(Offset foot) => Rect.fromLTWH(foot.dx - 30, foot.dy - 118, 59, 118);

  /// The worker's hands (where the hot stick starts) when standing at [foot].
  Offset handsAt(Offset foot) => foot + const Offset(14, -74);
}

/// The yard: sky, field, van, the double-pole transformer with its three DO
/// fuses and the LT box. [doOpen]: which DO tubes hang open; [ltOn]: the LT
/// switch; [live]: the line is fed (a faint glow on the DO tops).
class M2YardPainter extends CustomPainter {
  const M2YardPainter({required this.geo, required this.doOpen, required this.ltOn, this.dusk = false});

  final M2YardGeo geo;
  final List<bool> doOpen;
  final bool ltOn;
  final bool dusk;

  @override
  void paint(Canvas canvas, Size size) {
    final g = geo;
    final w = size.width;
    // Sky.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, g.groundY),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dusk ? const [Color(0xFF2C3E6B), Color(0xFFE9A06A)] : const [Color(0xFF6FA8DC), Color(0xFFCFE6F5)],
        ).createShader(Rect.fromLTWH(0, 0, w, g.groundY)),
    );
    // Far tree line.
    final far = Paint()..color = dusk ? const Color(0xFF3E5A48) : const Color(0xFF7FA77A);
    final hills = Path()..moveTo(0, g.groundY);
    for (var x = 0.0; x <= w; x += 24) {
      hills.lineTo(x, g.groundY - 26 - 12 * math.sin(x / 31) - 8 * math.cos(x / 13));
    }
    canvas.drawPath(hills..lineTo(w, g.groundY)..close(), far);
    // Ground.
    canvas.drawRect(
      Rect.fromLTWH(0, g.groundY, w, size.height - g.groundY),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8DA65A), Color(0xFF5E7A38)],
        ).createShader(Rect.fromLTWH(0, g.groundY, w, size.height - g.groundY)),
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, g.groundY + 40)
        ..quadraticBezierTo(150, g.groundY + 18, 360, g.groundY + 30)
        ..lineTo(360, g.groundY + 52)
        ..quadraticBezierTo(150, g.groundY + 42, 0, g.groundY + 70)
        ..close(),
      Paint()..color = const Color(0xFFB59B6A),
    );
    _van(canvas, Offset(-44, g.groundY));
    // HT line coming in from the left at the top.
    final wire = Paint()
      ..color = const Color(0xFF2F343A)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 3; i++) {
      final y = g.top - 28 + i * 2.0;
      canvas.drawPath(Path()..moveTo(0, y - 18)..quadraticBezierTo(110, y + 14, g.doX(i), g.doTopY - 2), wire);
    }
    // Poles.
    final pole = Paint()
      ..shader = const LinearGradient(colors: [Color(0xFF8E9399), Color(0xFFC9CDD2), Color(0xFF8E9399)])
          .createShader(Rect.fromLTWH(M2YardGeo.poleL - 6, g.top - 40, 12, g.span + 40));
    for (final x in const [M2YardGeo.poleL, M2YardGeo.poleR]) {
      canvas.drawRect(Rect.fromLTWH(x - 6, g.top - 40, 12, g.span + 46), pole);
    }
    // Cross-arm and DO fuses.
    final arm = Paint()..color = const Color(0xFF4A5058);
    canvas.drawRect(Rect.fromLTWH(M2YardGeo.poleL - 10, g.armY - 4, M2YardGeo.poleR - M2YardGeo.poleL + 20, 7), arm);
    for (var i = 0; i < 3; i++) {
      _doFuse(canvas, i, doOpen.length > i && doOpen[i]);
    }
    // Transformer.
    final t = g.tank;
    canvas.drawRect(Rect.fromLTWH(M2YardGeo.poleL - 8, t.bottom, M2YardGeo.poleR - M2YardGeo.poleL + 16, 6), arm);
    canvas.drawRRect(
      RRect.fromRectAndRadius(t, const Radius.circular(4)),
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFF6C7B66), Color(0xFF9AAB92), Color(0xFF6C7B66)]).createShader(t),
    );
    final fin = Paint()
      ..color = const Color(0xFF55634F)
      ..strokeWidth = 2;
    for (var x = t.left + 8; x < t.right - 4; x += 8) {
      canvas.drawLine(Offset(x, t.top + 10), Offset(x, t.bottom - 6), fin);
    }
    for (var i = 0; i < 3; i++) {
      final bx = g.doX(i);
      canvas.drawRect(Rect.fromLTWH(bx - 3, t.top - 16, 6, 16), Paint()..color = const Color(0xFF8C5A3C));
      canvas.drawLine(Offset(bx, g.doTopY + g.doLen + 6), Offset(bx, t.top - 16), wire);
    }
    _plate(canvas, Rect.fromLTWH(t.left + 22, t.top + t.height * 0.45, 32, 16), '11 kV');
    // LT cable down to the LT box.
    canvas.drawPath(
      Path()
        ..moveTo(t.left + 4, t.top + 20)
        ..quadraticBezierTo(M2YardGeo.poleL - 30, t.top + 30, g.ltBox.center.dx, g.ltBox.top),
      Paint()
        ..color = const Color(0xFF1B1E22)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke,
    );
    final box = g.ltBox;
    canvas.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(3)), Paint()..color = const Color(0xFF8B969F));
    canvas.drawRRect(RRect.fromRectAndRadius(box.deflate(2), const Radius.circular(2)), Paint()..color = const Color(0xFFA9B4BC));
    _label(canvas, 'LT', Offset(box.center.dx, box.top + 7), 7, const Color(0xFF26303D));
    final sw = g.ltSwitch;
    canvas.drawRRect(RRect.fromRectAndRadius(sw, const Radius.circular(3)), Paint()..color = ltOn ? const Color(0xFFC62828) : const Color(0xFF2E7D32));
    _label(canvas, ltOn ? 'ON' : 'OFF', sw.center, 7, Colors.white);
    // Earth-side danger plate on the pole.
    _plate(canvas, Rect.fromLTWH(M2YardGeo.poleR - 12, g.groundY - g.span * 0.5, 24, 16), '⚡');
  }

  void _doFuse(Canvas c, int i, bool open) {
    final g = geo;
    final x = g.doX(i);
    final por = Paint()..color = const Color(0xFF8C5A3C);
    // Top and bottom porcelain.
    c.drawRect(Rect.fromLTWH(x - 3.5, g.doTopY - 8, 7, 10), por);
    c.drawRect(Rect.fromLTWH(x - 3.5, g.doTopY + g.doLen - 2, 7, 10), por);
    final tube = Paint()
      ..color = const Color(0xFF3B3F45)
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    final bottom = Offset(x, g.doTopY + g.doLen);
    if (open) {
      // Dropped out: the tube hangs from its bottom hinge.
      c.drawLine(bottom, bottom + Offset(16, g.doLen * 0.82), tube);
      c.drawCircle(bottom + Offset(18, g.doLen * 0.86), 3.5, Paint()..color = const Color(0xFF9AA4AE));
    } else {
      c.drawLine(Offset(x, g.doTopY + 2), bottom, tube);
      // The pull ring.
      c.drawCircle(
        Offset(x + 4, g.doTopY + 6),
        3.4,
        Paint()
          ..color = const Color(0xFF9AA4AE)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
    }
  }

  void _van(Canvas c, Offset ground) {
    final body = Rect.fromLTWH(ground.dx, ground.dy - 58, 104, 46);
    c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(6)), Paint()..color = const Color(0xFFF4F1E8));
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(body.right - 30, body.top - 14, 30, 30), const Radius.circular(6)),
      Paint()..color = const Color(0xFFF4F1E8),
    );
    c.drawRect(Rect.fromLTWH(body.right - 24, body.top - 8, 20, 14), Paint()..color = const Color(0xFF6FA0C8));
    c.drawRect(Rect.fromLTWH(body.left, body.top + 18, 74, 6), Paint()..color = const Color(0xFF1F5F8F));
    final tyre = Paint()..color = const Color(0xFF1B1E22);
    c.drawCircle(Offset(body.left + 22, ground.dy - 10), 10, tyre);
    c.drawCircle(Offset(body.right - 18, ground.dy - 10), 10, tyre);
  }

  void _plate(Canvas c, Rect r, String text) {
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), Paint()..color = const Color(0xFFFFE04A));
    c.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(2)),
      Paint()
        ..color = const Color(0xFFB71C1C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    _label(c, text, r.center, 7, const Color(0xFFB71C1C));
  }

  @override
  bool shouldRepaint(M2YardPainter old) =>
      old.geo.h != geo.h || old.ltOn != ltOn || old.dusk != dusk || !_same(old.doOpen, doOpen);

  static bool _same(List<bool> a, List<bool> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// The hot stick in the worker's hands, reaching from [from] to [to].
class M2StickPainter extends CustomPainter {
  const M2StickPainter({required this.from, required this.to});
  final Offset from;
  final Offset to;

  @override
  void paint(Canvas canvas, Size size) {
    final d = to - from;
    final grip = from + d * 0.12;
    canvas.drawLine(
      from,
      to,
      Paint()
        ..color = const Color(0xFFF1C232)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      from,
      grip,
      Paint()
        ..color = const Color(0xFF3B3F45)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(to, 3, Paint()..color = const Color(0xFF7D8791));
  }

  @override
  bool shouldRepaint(M2StickPainter old) => old.from != from || old.to != to;
}

/// A short flash or spark at [at] (DO opening, a discharge, an arc).
class M2SparkPainter extends CustomPainter {
  const M2SparkPainter({required this.at, this.big = false});
  final Offset at;
  final bool big;

  @override
  void paint(Canvas canvas, Size size) {
    final r = big ? 46.0 : 16.0;
    canvas.drawCircle(
      at,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: big
              ? const [Color(0xFFFFFFFF), Color(0xFFFFE070), Color(0x00FF7A00)]
              : const [Color(0xFFFFFFFF), Color(0xFF9FD8FF), Color(0x002A7FFF)],
        ).createShader(Rect.fromCircle(center: at, radius: r)),
    );
    final ray = Paint()
      ..color = big ? const Color(0xFFFFF3B0) : const Color(0xFFDDF2FF)
      ..strokeWidth = big ? 2.4 : 1.4;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + 0.3;
      canvas.drawLine(at + Offset(math.cos(a), math.sin(a)) * r * 0.4, at + Offset(math.cos(a), math.sin(a)) * r * 1.15, ray);
    }
  }

  @override
  bool shouldRepaint(M2SparkPainter old) => old.at != at || old.big != big;
}

// ============================================================================
// The tailgate bench (stations 1, 4, 5, 7)
// ============================================================================

/// The van's open back: a pegboard wall, a shelf and the wooden bench top
/// from [benchY] down.
class M2BenchPainter extends CustomPainter {
  const M2BenchPainter({required this.benchY});
  final double benchY;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, benchY),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF233041), Color(0xFF34465C)],
        ).createShader(Rect.fromLTWH(0, 0, w, benchY)),
    );
    final hole = Paint()..color = const Color(0xFF1A2431);
    for (var y = 110.0; y < benchY - 10; y += 18) {
      for (var x = 12.0; x < w; x += 18) {
        canvas.drawCircle(Offset(x, y), 1.6, hole);
      }
    }
    canvas.drawRect(
      Rect.fromLTWH(0, benchY, w, size.height - benchY),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB07A48), Color(0xFF7A4E2A)],
        ).createShader(Rect.fromLTWH(0, benchY, w, size.height - benchY)),
    );
    canvas.drawRect(Rect.fromLTWH(0, benchY, w, 5), Paint()..color = const Color(0xFFD39A62));
    final grain = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 1;
    for (var y = benchY + 18; y < size.height; y += 22) {
      canvas.drawLine(Offset(0, y), Offset(w, y + 4), grain);
    }
  }

  @override
  bool shouldRepaint(M2BenchPainter old) => old.benchY != benchY;
}

// ============================================================================
// The LT terminals close-up (stations 3 and 6)
// ============================================================================

/// Where the terminals sit in the LT close-up, for a scene [h] high.
@immutable
class M2TermGeo {
  const M2TermGeo(this.h);
  final double h;

  Rect get box => Rect.fromLTWH(70, 150, 270, math.min(300, h - 300));
  static const phases = ['R', 'Y', 'B', 'N'];
  Offset term(int i) => Offset(box.left + 46 + i * 58, box.top + box.height * 0.52);
  Rect termHit(int i) => Rect.fromCircle(center: term(i), radius: 26);

  /// The HT bushings showing above the box (the trap at station 3).
  Rect get htHit => Rect.fromLTWH(box.left + 30, 104, 210, 40);

  /// The known live point (another fed board on the van side).
  Rect get liveHit => Rect.fromLTWH(10, box.top + 40, 54, 70);
}

/// The open LT box: bus terminals R-Y-B-N, the transformer's HT bushings
/// above it, and the known-live point beside it. [clips]: phase-meter clips
/// (station 6) by terminal index; [live]: the line is fed again.
class M2TerminalPainter extends CustomPainter {
  const M2TerminalPainter({required this.geo, this.clips = const {}, this.live = false});

  final M2TermGeo geo;
  final Set<int> clips;
  final bool live;

  static const colors = [Color(0xFFD7312B), Color(0xFFF2C40F), Color(0xFF2A62C9), Color(0xFF16181C)];

  @override
  void paint(Canvas canvas, Size size) {
    final g = geo;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7FA9CC), Color(0xFF5F7A59)],
        ).createShader(Offset.zero & size),
    );
    // Transformer tank top with HT bushings.
    final tank = Rect.fromLTWH(g.box.left + 10, 60, 250, 90);
    canvas.drawRect(tank, Paint()..color = const Color(0xFF7E8E77));
    for (var i = 0; i < 3; i++) {
      final x = g.htHit.left + 30 + i * 75.0;
      final r = Rect.fromLTWH(x - 8, 96, 16, 46);
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)), Paint()..color = const Color(0xFF8C5A3C));
      for (var k = 0; k < 4; k++) {
        canvas.drawRect(Rect.fromLTWH(x - 11, 100 + k * 10.0, 22, 4), Paint()..color = const Color(0xFF6F4329));
      }
      canvas.drawLine(Offset(x, 96), Offset(x, 40), Paint()..color = const Color(0xFF2F343A)..strokeWidth = 2);
    }
    _bnLabel(canvas, '11 kV', Offset(tank.right - 30, 74), 10, const Color(0xFFFFE04A));
    // The LT box, door open.
    final b = g.box;
    canvas.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(6)), Paint()..color = const Color(0xFF8B969F));
    canvas.drawRRect(RRect.fromRectAndRadius(b.deflate(8), const Radius.circular(4)), Paint()..color = const Color(0xFF2E353D));
    canvas.drawRect(Rect.fromLTWH(b.right - 4, b.top + 6, 18, b.height - 12), Paint()..color = const Color(0xFF7A858E));
    _label(canvas, 'LT 415V', Offset(b.center.dx, b.top + 22), 11, const Color(0xFFFFE04A));
    // Bus bars and terminals.
    for (var i = 0; i < 4; i++) {
      final p = g.term(i);
      canvas.drawRect(Rect.fromCenter(center: p.translate(0, -34), width: 14, height: 60), Paint()..color = const Color(0xFFC08A3E));
      canvas.drawCircle(p, 14, Paint()..color = const Color(0xFFD0D5DA));
      canvas.drawCircle(p, 8, Paint()..color = const Color(0xFF8A939C));
      canvas.drawCircle(p.translate(0, 34), 10, Paint()..color = colors[i]);
      _label(canvas, M2TermGeo.phases[i], p.translate(0, 34), 10, i == 1 ? Colors.black : Colors.white);
      if (clips.contains(i)) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: p.translate(0, -6), width: 18, height: 12), const Radius.circular(3)),
          Paint()..color = colors[i],
        );
      }
    }
    // The cable from below.
    canvas.drawRect(Rect.fromLTWH(b.center.dx - 20, b.bottom - 4, 40, size.height - b.bottom), Paint()..color = const Color(0xFF1B1E22));
    // Known-live point: a fed board at the side.
    final lp = g.liveHit;
    canvas.drawRRect(RRect.fromRectAndRadius(lp, const Radius.circular(5)), Paint()..color = const Color(0xFFE6E0D0));
    canvas.drawCircle(lp.center.translate(0, 8), 9, Paint()..color = const Color(0xFF3B3F45));
    canvas.drawCircle(lp.center.translate(-3, 8), 2, Paint()..color = Colors.black);
    canvas.drawCircle(lp.center.translate(3, 8), 2, Paint()..color = Colors.black);
    canvas.drawCircle(lp.center.translate(0, -18), 4, Paint()..color = const Color(0xFFE53935));
    if (live) {
      canvas.drawCircle(b.topLeft.translate(22, 22), 5, Paint()..color = const Color(0xFFE53935));
    }
  }

  @override
  bool shouldRepaint(M2TerminalPainter old) => old.geo.h != geo.h || old.live != live || old.clips.length != clips.length;
}

// ============================================================================
// Meters
// ============================================================================

/// Multimeter dial positions.
enum M2Dial { acV, dcV, ohm, beep }

extension M2DialMark on M2Dial {
  String get mark => switch (this) {
        M2Dial.acV => 'V~',
        M2Dial.dcV => 'V⎓',
        M2Dial.ohm => 'Ω',
        M2Dial.beep => '•)))',
      };
}

/// The big multimeter face: display [reading] and the rotary dial on [dial].
class M2MultimeterPainter extends CustomPainter {
  const M2MultimeterPainter({required this.dial, required this.reading});
  final M2Dial? dial;
  final String reading;

  /// Dial mark centres, in a 120 × 170 face.
  static Offset markAt(int i) {
    final a = -math.pi * 0.85 + i * math.pi * 0.56;
    return const Offset(60, 112) + Offset(math.cos(a), math.sin(a)) * 40;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 120, size.height / 170);
    final body = RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 120, 170), const Radius.circular(14));
    canvas.drawRRect(body, Paint()..color = const Color(0xFFF2B705));
    canvas.drawRRect(body.deflate(6), Paint()..color = const Color(0xFF2B2F36));
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(16, 14, 88, 40), const Radius.circular(4)),
      Paint()..color = const Color(0xFFB9D8B0),
    );
    _label(canvas, reading, const Offset(60, 34), 20, const Color(0xFF1B2A1B));
    canvas.drawCircle(const Offset(60, 112), 24, Paint()..color = const Color(0xFF4A4F57));
    for (var i = 0; i < M2Dial.values.length; i++) {
      final on = dial == M2Dial.values[i];
      _label(canvas, M2Dial.values[i].mark, markAt(i), 12, on ? const Color(0xFFFFD34E) : const Color(0xFFE0E4E8));
    }
    final d = dial;
    if (d != null) {
      final m = markAt(d.index);
      final dir = (m - const Offset(60, 112)) / 40;
      canvas.drawLine(const Offset(60, 112), const Offset(60, 112) + dir * 20, Paint()..color = Colors.white..strokeWidth = 4..strokeCap = StrokeCap.round);
    }
    _label(canvas, 'CAT IV 600V', const Offset(60, 158), 8, Colors.white);
    canvas.restore();
  }

  @override
  bool shouldRepaint(M2MultimeterPainter old) => old.dial != dial || old.reading != reading;
}

/// Megger test voltages on its selector.
enum M2MegV { v500, v1000, v2500, v5000 }

extension M2MegVLabel on M2MegV {
  String get label => switch (this) {
        M2MegV.v500 => '500V',
        M2MegV.v1000 => '1000V',
        M2MegV.v2500 => '2500V',
        M2MegV.v5000 => '5000V',
      };
}

/// The megger face: [volt] on the selector, [reading] on the display and the
/// test [progress] (0–1 of the minute) as a ring.
class M2MeggerPainter extends CustomPainter {
  const M2MeggerPainter({required this.volt, required this.reading, required this.progress});
  final M2MegV? volt;
  final String reading;
  final double progress;

  /// Selector mark centres in a 150 × 120 face.
  static Offset markAt(int i) => Offset(24 + i * 34.0, 100);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 150, size.height / 120);
    final body = RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 150, 120), const Radius.circular(12));
    canvas.drawRRect(body, Paint()..color = const Color(0xFFE8711C));
    canvas.drawRRect(body.deflate(5), Paint()..color = const Color(0xFF2B2F36));
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(14, 12, 86, 40), const Radius.circular(4)),
      Paint()..color = const Color(0xFFB9D8B0),
    );
    _label(canvas, reading, const Offset(57, 32), 16, const Color(0xFF1B2A1B));
    // The minute ring.
    final c = const Offset(124, 32);
    canvas.drawCircle(c, 15, Paint()..color = const Color(0xFF4A4F57));
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: 15),
        -math.pi / 2,
        2 * math.pi * progress.clamp(0.0, 1.0),
        false,
        Paint()
          ..color = const Color(0xFF41C463)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
    }
    _label(canvas, 'MΩ', const Offset(124, 32), 8, Colors.white);
    _label(canvas, 'LINE', const Offset(30, 66), 8, const Color(0xFFFF8A80));
    _label(canvas, 'EARTH', const Offset(120, 66), 8, const Color(0xFFE0E4E8));
    for (var i = 0; i < M2MegV.values.length; i++) {
      final on = volt == M2MegV.values[i];
      final r = Rect.fromCenter(center: markAt(i), width: 32, height: 18);
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)), Paint()..color = on ? const Color(0xFFFFD34E) : const Color(0xFF4A4F57));
      _label(canvas, M2MegV.values[i].label, r.center, 7.5, on ? Colors.black : Colors.white);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(M2MeggerPainter old) => old.volt != volt || old.reading != reading || old.progress != progress;
}

/// The phase-sequence meter: [fwd] null = no reading yet; true = R-Y-B
/// clockwise (green); false = R-B-Y reversed (red).
class M2PhaseMeterPainter extends CustomPainter {
  const M2PhaseMeterPainter({required this.fwd});
  final bool? fwd;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 120, size.height / 110);
    final body = RRect.fromRectAndRadius(const Rect.fromLTWH(0, 0, 120, 110), const Radius.circular(12));
    canvas.drawRRect(body, Paint()..color = const Color(0xFF5B6570));
    canvas.drawRRect(body.deflate(5), Paint()..color = const Color(0xFF2B2F36));
    final f = fwd;
    canvas.drawCircle(const Offset(36, 34), 11, Paint()..color = f == true ? const Color(0xFF41C463) : const Color(0xFF24402C));
    canvas.drawCircle(const Offset(84, 34), 11, Paint()..color = f == false ? const Color(0xFFE04B3A) : const Color(0xFF4A2522));
    _label(canvas, 'FWD', const Offset(36, 56), 9, Colors.white);
    _label(canvas, 'REV', const Offset(84, 56), 9, Colors.white);
    _label(canvas, f == null ? '- - -' : (f ? 'R-Y-B ↻' : 'R-B-Y ↺'), const Offset(60, 84), 13, f == null ? Colors.white54 : Colors.white);
    canvas.restore();
  }

  @override
  bool shouldRepaint(M2PhaseMeterPainter old) => old.fwd != fwd;
}

// ============================================================================
// The cable end (stations 4 and 5)
// ============================================================================

/// Lugs in the tray (the stamp a worker reads on the barrel).
enum M2Lug { al95, cu95, al70, al120 }

extension M2LugStamp on M2Lug {
  String get stamp => switch (this) {
        M2Lug.al95 => 'AL 95',
        M2Lug.cu95 => 'CU 95',
        M2Lug.al70 => 'AL 70',
        M2Lug.al120 => 'AL 120',
      };
  bool get copper => this == M2Lug.cu95;
}

/// Where the cable lies on the bench, for a bench top at [benchY].
@immutable
class M2CableGeo {
  const M2CableGeo(this.benchY);
  final double benchY;

  double get y => benchY + 44;
  double get endX => 300;
  double get skinFrom => 214;
  Rect get insulationHit => Rect.fromLTWH(140, y - 26, 176, 52);
  Rect get conductorHit => Rect.fromLTWH(232, y - 30, 96, 60);
  Rect get armourHit => Rect.fromLTWH(30, y - 30, 90, 60);
}

/// The 95 sq mm aluminium cable end: outer sheath and armour on the left,
/// the core insulation, and — once [skinned] — the bright conductor with the
/// [lug] on it ([crimped]: hex marks). [line]/[earth]: megger leads clipped.
class M2CablePainter extends CustomPainter {
  const M2CablePainter({
    required this.geo,
    this.skin = 0,
    this.lug,
    this.crimped = false,
    this.line = false,
    this.earth = false,
  });

  final M2CableGeo geo;

  /// 0 = whole insulation; 1 = skinned to the barrel length.
  final double skin;
  final M2Lug? lug;
  final bool crimped;
  final bool line;
  final bool earth;

  @override
  void paint(Canvas canvas, Size size) {
    final y = geo.y;
    // Sheath with armour band.
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-10, y - 18, 140, 36), const Radius.circular(8)), Paint()..color = const Color(0xFF1B1E22));
    canvas.drawRect(Rect.fromLTWH(110, y - 18, 20, 36), Paint()..color = const Color(0xFF8A939C));
    _label(canvas, '95 sq mm AL', Offset(56, y), 10, const Color(0xFFB0B8C0));
    // Core insulation (red phase core).
    final cut = geo.skinFrom + (geo.endX - geo.skinFrom) * (1 - skin.clamp(0.0, 1.0));
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTRB(128, y - 12, cut, y + 12), const Radius.circular(5)),
      Paint()..color = const Color(0xFFC62828),
    );
    if (skin > 0) {
      // Bright aluminium strands.
      final cond = Rect.fromLTRB(cut, y - 8, geo.endX, y + 8);
      canvas.drawRect(cond, Paint()..color = const Color(0xFFD9DEE3));
      final strand = Paint()
        ..color = const Color(0xFFA9B1B9)
        ..strokeWidth = 1;
      for (var x = cut; x < geo.endX; x += 5) {
        canvas.drawLine(Offset(x, y - 8), Offset(x + 4, y + 8), strand);
      }
      // A pencil-shaped taper at the insulation's edge.
      canvas.drawPath(
        Path()..moveTo(cut, y - 12)..lineTo(cut + 8, y - 8)..lineTo(cut + 8, y + 8)..lineTo(cut, y + 12)..close(),
        Paint()..color = const Color(0xFF9E2020),
      );
    }
    final l = lug;
    if (l != null) {
      final barrel = Rect.fromLTWH(geo.skinFrom + 10, y - 12, geo.endX - geo.skinFrom - 6, 24);
      final metal = l.copper ? const Color(0xFFC77B3B) : const Color(0xFFC8CED4);
      canvas.drawRRect(RRect.fromRectAndRadius(barrel, const Radius.circular(6)), Paint()..color = metal);
      final palm = Rect.fromLTWH(barrel.right - 2, y - 16, 34, 32);
      canvas.drawRRect(RRect.fromRectAndRadius(palm, const Radius.circular(14)), Paint()..color = metal);
      canvas.drawCircle(palm.center.translate(4, 0), 6, Paint()..color = const Color(0xFF2E353D));
      _label(canvas, l.stamp, barrel.center.translate(-10, 0), 8, const Color(0xFF26303D));
      if (crimped) {
        final hex = Paint()
          ..color = const Color(0x88404850)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        for (final dx in const [22.0, 42.0]) {
          canvas.drawLine(Offset(barrel.left + dx, barrel.top + 2), Offset(barrel.left + dx, barrel.bottom - 2), hex);
          canvas.drawLine(Offset(barrel.left + dx + 4, barrel.top + 2), Offset(barrel.left + dx + 4, barrel.bottom - 2), hex);
        }
      }
    }
    if (line) {
      _clip(canvas, Offset(geo.endX + 10, y - 20), const Color(0xFFD7312B));
    }
    if (earth) {
      _clip(canvas, Offset(120, y - 22), const Color(0xFF16181C));
    }
  }

  void _clip(Canvas c, Offset at, Color colour) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: at, width: 22, height: 14), const Radius.circular(4)), Paint()..color = colour);
    c.drawPath(
      Path()..moveTo(at.dx, at.dy - 7)..quadraticBezierTo(at.dx - 20, at.dy - 70, at.dx - 80, at.dy - 110),
      Paint()
        ..color = colour
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(M2CablePainter old) =>
      old.geo.benchY != geo.benchY ||
      old.skin != skin ||
      old.lug != lug ||
      old.crimped != crimped ||
      old.line != line ||
      old.earth != earth;
}

/// The hydraulic crimper's pressure gauge: [p] 0–1; at 1 the release valve
/// has clicked.
class M2GaugePainter extends CustomPainter {
  const M2GaugePainter({required this.p});
  final double p;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = math.min(size.width, size.height) / 2 - 3;
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFFF4F1E8));
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = const Color(0xFF3B3F45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r - 6),
      math.pi * 0.75 + math.pi * 1.2,
      math.pi * 0.3,
      false,
      Paint()
        ..color = const Color(0xFF2E7D32)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    final a = math.pi * 0.75 + math.pi * 1.5 * p.clamp(0.0, 1.0);
    canvas.drawLine(
      c,
      c + Offset(math.cos(a), math.sin(a)) * (r - 8),
      Paint()
        ..color = const Color(0xFFC62828)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(c, 3.5, Paint()..color = const Color(0xFF3B3F45));
  }

  @override
  bool shouldRepaint(M2GaugePainter old) => old.p != p;
}

// ============================================================================
// The van's side bay at day's end (station 7)
// ============================================================================

/// Where things sit in the tool-care bay, for a scene [h] high: the wall
/// hooks and the waterproof bag up on the wall, the tool in hand, the
/// toolbox and the bench, and the van's floor.
class M2CareGeo {
  const M2CareGeo(this.h);
  final double h;

  Rect get hooks => Rect.fromLTWH(14, h * 0.19, 160, h * 0.115);
  Rect get bag => Rect.fromLTWH(188, h * 0.19, 158, h * 0.115);
  Rect get hand => Rect.fromLTWH(40, h * 0.33, 280, h * 0.135);
  double get benchY => h * 0.59;
  Rect get toolbox => Rect.fromLTWH(206, benchY - h * 0.11, 140, h * 0.11);
  Rect slot(int i) => Rect.fromLTWH(14 + i * 112.0, benchY + h * 0.018, 106, h * 0.11);
  Rect get floor => Rect.fromLTWH(0, benchY + h * 0.15, 360, h * 0.14);

  /// Where the [n]th tool put away at a spot is drawn.
  Rect storedAt(Rect spot, int n) => Rect.fromLTWH(spot.left + 10 + n * 14, spot.top + spot.height * 0.28 + n * 6, spot.width * 0.62, spot.height * 0.5);
}

class M2CareBayPainter extends CustomPainter {
  const M2CareBayPainter({required this.geo});
  final M2CareGeo geo;

  @override
  void paint(Canvas canvas, Size size) {
    final g = geo;
    final w = size.width;
    // Van wall (perforated panel).
    final wall = Rect.fromLTWH(0, 0, w, g.benchY);
    canvas.drawRect(
      wall,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF233041), Color(0xFF34465C)],
        ).createShader(wall),
    );
    final hole = Paint()..color = const Color(0xFF1A2431);
    for (var y = 110.0; y < g.benchY - 10; y += 18) {
      for (var x = 12.0; x < w; x += 18) {
        canvas.drawCircle(Offset(x, y), 1.6, hole);
      }
    }
    // Hook rail.
    final hr = g.hooks;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(hr.left, hr.top + 6, hr.width, 8), const Radius.circular(3)), Paint()..color = const Color(0xFF9AA4AE));
    final hook = Paint()
      ..color = const Color(0xFFC9D1D9)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final x = hr.left + 22 + i * (hr.width - 44) / 3;
      canvas.drawPath(
        Path()
          ..moveTo(x, hr.top + 14)
          ..lineTo(x, hr.top + 26)
          ..quadraticBezierTo(x, hr.top + 34, x + 7, hr.top + 30),
        hook,
      );
    }
    // Waterproof bag hanging on the wall.
    final b = g.bag;
    final body = RRect.fromRectAndRadius(Rect.fromLTWH(b.left + 6, b.top + 14, b.width - 12, b.height - 16), const Radius.circular(12));
    canvas.drawRRect(body, Paint()..color = const Color(0xFF1F5F8F));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(b.left + 6, b.top + 14, b.width - 12, 12), const Radius.circular(6)), Paint()..color = const Color(0xFF184C73));
    canvas.drawLine(Offset(b.left + 20, b.top + 4), Offset(b.left + 20, b.top + 16), hook);
    canvas.drawLine(Offset(b.right - 20, b.top + 4), Offset(b.right - 20, b.top + 16), hook);
    canvas.drawLine(Offset(b.left + 20, b.top + 4), Offset(b.right - 20, b.top + 4), hook..strokeWidth = 2);
    hook.strokeWidth = 3;
    // Bench.
    final bench = Rect.fromLTWH(0, g.benchY, w, g.floor.top - g.benchY);
    canvas.drawRect(
      bench,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB07A48), Color(0xFF7A4E2A)],
        ).createShader(bench),
    );
    canvas.drawRect(Rect.fromLTWH(0, g.benchY, w, 5), Paint()..color = const Color(0xFFD39A62));
    // Toolbox on the bench.
    final t = g.toolbox;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(t.left, t.top + 16, t.width, t.height - 16), const Radius.circular(6)), Paint()..color = const Color(0xFFC62828));
    canvas.drawRect(Rect.fromLTWH(t.left, t.top + 30, t.width, 4), Paint()..color = const Color(0xFF8E1B1B));
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(t.center.dx - 26, t.top + 4, 52, 14), const Radius.circular(6)),
      Paint()
        ..color = const Color(0xFF3B3F45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    canvas.drawRect(Rect.fromCenter(center: Offset(t.center.dx, t.top + 32), width: 18, height: 8), Paint()..color = const Color(0xFFB0B8C0));
    // Van floor (ribbed metal) down to the bottom edge.
    final f = Rect.fromLTWH(0, g.floor.top, w, size.height - g.floor.top);
    canvas.drawRect(f, Paint()..color = const Color(0xFF3A4048));
    final rib = Paint()
      ..color = const Color(0xFF4F5761)
      ..strokeWidth = 3;
    for (var y = f.top + 10; y < size.height; y += 16) {
      canvas.drawLine(Offset(0, y), Offset(w, y), rib);
    }
    canvas.drawRect(Rect.fromLTWH(0, f.top, w, 6), Paint()..color = const Color(0xFF262B31));
  }

  @override
  bool shouldRepaint(M2CareBayPainter old) => old.geo.h != geo.h;
}
