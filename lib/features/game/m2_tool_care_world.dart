import 'dart:math' as math;

import 'package:flutter/material.dart';

// Lesson 2.10, কাজ: "দিনের শেষে" — the store's tool bench at dusk, drawn in
// code: the back wall with the window's last light, a pegboard (shadow board)
// where every tool has its own outlined place, a hanging lamp, the wooden
// bench in front with the বাতিল crate at its right end. The tools are drawn
// too (insulated pliers, insulated screwdriver, spanner, multimeter, hydraulic
// crimper), each with its dirt, water, rust, oil drops and faults as layers,
// so every play can deal a different pile. No text in the art except what a
// worker reads (OFF / V on the meter's dial).
// Design: 360 wide × any height; the bench stands on the bottom rows, so a
// tall phone gets more wall, never a stretched bench.

enum CareKind { pliers, screwdriver, spanner, meter, crimper }

enum CareFlaw { none, crack, bent, widened, leak }

/// The tool's own drawing space (every tool is drawn in 300 × 120).
const Size kCareToolSpace = Size(300, 120);

/// Where things are, in design pixels (360 × [h]).
@immutable
class CareGeo {
  const CareGeo(this.h);
  final double h;

  /// The bench's top edge (the tool lies on it).
  double get benchTop => h - 290;

  /// The tool on the bench (its close look is right there).
  Rect get tool => Rect.fromLTWH(10, benchTop - 98, 276, 124);

  /// The বাতিল crate at the bench's right end.
  Rect get crate => Rect.fromLTWH(290, benchTop - 46, 64, 50);

  /// The pegboard (shadow board) on the back wall.
  Rect get board {
    final top = math.max(112.0, benchTop - 330);
    return Rect.fromLTRB(112, top, 352, benchTop - 130);
  }

  /// The place of [k] on the pegboard.
  Rect slot(CareKind k) {
    final b = board.deflate(8);
    final rowH = b.height / 2;
    final i = k.index;
    if (i < 3) {
      final w = b.width / 3;
      return Rect.fromLTWH(b.left + w * i + 3, b.top + 4, w - 6, rowH - 8);
    }
    final w = b.width / 2;
    return Rect.fromLTWH(b.left + w * (i - 3) + 10, b.top + rowH + 4, w - 20, rowH - 8);
  }

  /// The trainee, behind the bench on the left.
  Rect get trainee => Rect.fromLTWH(-36, benchTop - 196, 104, 208);

  Rect get window => Rect.fromLTWH(14, math.max(110.0, benchTop - 330), 84, 70);
}

/// The back of the room: wall, window at dusk, the pegboard with its
/// outlines (only the dealt tools' places), the lamp.
class CareRoomPainter extends CustomPainter {
  const CareRoomPainter(this.geo, {required this.kinds});
  final CareGeo geo;
  final List<CareKind> kinds;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final top = geo.benchTop;
    final wall = Rect.fromLTWH(0, 0, w, top + 10);
    c.drawRect(
      wall,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2D3646), Color(0xFF55606A), Color(0xFF8C8577)],
          stops: [0, 0.5, 1],
        ).createShader(wall),
    );
    // Lamp light pooling on the wall.
    final lamp = Offset(w * 0.6, geo.board.top - 26);
    c.drawCircle(lamp, 260, Paint()..shader = const RadialGradient(colors: [Color(0x66FFD99A), Color(0x00FFD99A)]).createShader(Rect.fromCircle(center: lamp, radius: 260)));

    // Window: the last light of the day.
    final win = geo.window;
    c.drawRRect(RRect.fromRectAndRadius(win.inflate(5), const Radius.circular(3)), Paint()..color = const Color(0xFF3E444B));
    c.drawRect(
      win,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3B3F7A), Color(0xFFB0567A), Color(0xFFF2A65A)],
          stops: [0, 0.55, 1],
        ).createShader(win),
    );
    // A pole and wires outside.
    final pole = Paint()
      ..color = const Color(0xFF1E2230)
      ..strokeWidth = 3;
    c.drawLine(Offset(win.left + win.width * 0.66, win.top + 12), Offset(win.left + win.width * 0.66, win.bottom), pole);
    c.drawLine(Offset(win.left + win.width * 0.48, win.top + 18), Offset(win.left + win.width * 0.84, win.top + 18), pole..strokeWidth = 2);
    c.drawLine(Offset(win.left, win.top + 26), Offset(win.right, win.top + 22), Paint()
      ..color = const Color(0xAA1E2230)
      ..strokeWidth = 1);
    final bar = Paint()
      ..color = const Color(0xFF3E444B)
      ..strokeWidth = 3;
    c.drawLine(Offset(win.center.dx, win.top), Offset(win.center.dx, win.bottom), bar);
    c.drawLine(Offset(win.left, win.center.dy), Offset(win.right, win.center.dy), bar);
    // Warm light from the window on the wall below it.
    final fall = Path()
      ..moveTo(win.left, win.bottom)
      ..lineTo(win.right, win.bottom)
      ..lineTo(win.right + 30, top)
      ..lineTo(win.left - 10, top)
      ..close();
    c.drawPath(fall, Paint()..color = const Color(0x18F2A65A));

    // The pegboard: holes, a frame, the outlines.
    final b = geo.board;
    c.drawRRect(RRect.fromRectAndRadius(b.inflate(4), const Radius.circular(4)), Paint()..color = const Color(0xFF5B4630));
    c.drawRect(
      b,
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFFC9A877), Color(0xFFB08F5F)], begin: Alignment.topLeft, end: Alignment.bottomRight).createShader(b),
    );
    final hole = Paint()..color = const Color(0x553A2A18);
    for (var y = b.top + 8; y < b.bottom - 4; y += 12) {
      for (var x = b.left + 8; x < b.right - 4; x += 12) {
        c.drawCircle(Offset(x, y), 1.3, hole);
      }
    }
    for (final k in kinds) {
      final r = geo.slot(k);
      // The painted outline: where this tool lives.
      c.save();
      c.translate(r.left, r.top);
      CareToolPainter.outline(c, k, r.size);
      c.restore();
      // Two pegs.
      final peg = Paint()..color = const Color(0xFF7A7F86);
      c.drawCircle(Offset(r.left + r.width * 0.3, r.top + 3), 2.4, peg);
      c.drawCircle(Offset(r.left + r.width * 0.7, r.top + 3), 2.4, peg);
    }

    // The lamp: cord and shade.
    c.drawLine(Offset(lamp.dx, 0), Offset(lamp.dx, lamp.dy - 10), Paint()
      ..color = const Color(0xFF1A1D22)
      ..strokeWidth = 1.5);
    final shade = Path()
      ..moveTo(lamp.dx - 7, lamp.dy - 12)
      ..lineTo(lamp.dx + 7, lamp.dy - 12)
      ..lineTo(lamp.dx + 20, lamp.dy + 2)
      ..lineTo(lamp.dx - 20, lamp.dy + 2)
      ..close();
    c.drawPath(shade, Paint()..color = const Color(0xFF2F5D4A));
    c.drawOval(Rect.fromCenter(center: Offset(lamp.dx, lamp.dy + 3), width: 22, height: 7), Paint()..color = const Color(0xFFFFF0C8));
  }

  @override
  bool shouldRepaint(CareRoomPainter old) => old.geo.h != geo.h || old.kinds != kinds;
}

/// The bench in front (over the trainee's legs), the cloth, the বাতিল crate.
class CareBenchPainter extends CustomPainter {
  const CareBenchPainter(this.geo, {required this.tagged});
  final CareGeo geo;

  /// Tools in the crate so far (their tags hang over the rim).
  final int tagged;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final h = s.height;
    final top = geo.benchTop;
    // The top: worn wood, a front edge.
    final slab = Rect.fromLTWH(0, top - 4, w, 34);
    c.drawRect(
      slab,
      Paint()
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFA0754A), Color(0xFF7B5532)]).createShader(slab),
    );
    final grain = Paint()
      ..color = const Color(0x225A3A1C)
      ..strokeWidth = 1;
    for (var i = 0; i < 5; i++) {
      final y = top + 2 + i * 5.5;
      c.drawLine(Offset(0, y), Offset(w, y + (i.isEven ? 1.5 : -1.5)), grain);
    }
    c.drawRect(Rect.fromLTWH(0, top + 30, w, 6), Paint()..color = const Color(0xFF5A3C22));
    // The front: drawers and the dark under-bench.
    final front = Rect.fromLTWH(0, top + 36, w, h - top - 36);
    c.drawRect(front, Paint()..color = const Color(0xFF3A2A1D));
    final drawer = Paint()..color = const Color(0xFF5E4430);
    final edge = Paint()
      ..color = const Color(0xFF2A1E14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 0; i < 3; i++) {
      final r = Rect.fromLTWH(12 + i * 116.0, top + 48, 104, 56);
      c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), drawer);
      c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), edge);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: r.center, width: 30, height: 6), const Radius.circular(3)), Paint()..color = const Color(0xFFB9A27A));
    }
    // Floor shadow under the bench.
    c.drawRect(Rect.fromLTWH(0, top + 116, w, h - top - 116), Paint()..color = const Color(0xFF221810));

    // The বাতিল crate: red-banded, tags over its rim.
    final cr = geo.crate;
    c.drawRect(cr, Paint()..color = const Color(0xFF6B4A2B));
    final slat = Paint()
      ..color = const Color(0xFF4A321C)
      ..strokeWidth = 2;
    for (var i = 1; i < 3; i++) {
      c.drawLine(Offset(cr.left, cr.top + cr.height * i / 3), Offset(cr.right, cr.top + cr.height * i / 3), slat);
    }
    c.drawRect(Rect.fromLTWH(cr.left, cr.top + cr.height * 0.42, cr.width, 9), Paint()..color = const Color(0xFFC0392B));
    for (var i = 0; i < tagged && i < 4; i++) {
      final x = cr.left + 10 + i * 13.0;
      c.drawLine(Offset(x, cr.top - 2), Offset(x + 2, cr.top + 12), Paint()
        ..color = const Color(0xFFEDE4CF)
        ..strokeWidth = 1);
      c.drawRect(Rect.fromLTWH(x - 3, cr.top + 12, 11, 15), Paint()..color = const Color(0xFFE74C3C));
    }
  }

  @override
  bool shouldRepaint(CareBenchPainter old) => old.geo.h != geo.h || old.tagged != tagged;
}

/// Areas of a tool, in its 300 × 120 space (oil zones, the meter's dial and leads).
abstract final class CareZones {
  /// The insulated grip (oil must never touch it).
  static bool onInsulation(CareKind k, Offset p) => switch (k) {
        CareKind.pliers => p.dx > 140,
        CareKind.screwdriver => p.dx > 92,
        _ => false,
      };

  static const dial = Offset(84, 82);
  static const double dialR = 22;
  static bool onDial(Offset p) => (p - dial).distance <= dialR + 6;
  static bool onLeads(Offset p) => p.dx > 150;

  /// A metal spot to oil (tests and the spanner's shaft).
  static Offset metalSpot(CareKind k) => switch (k) {
        CareKind.pliers => const Offset(128, 60),
        CareKind.screwdriver => const Offset(50, 60),
        CareKind.spanner => const Offset(150, 60),
        CareKind.crimper => const Offset(140, 60),
        CareKind.meter => const Offset(84, 40),
      };

  /// A spot on the insulated grip (tests).
  static const insulationSpot = Offset(240, 60);
  static const leadsSpot = Offset(230, 60);
}

/// Maps a point in a [size] box to the tool's 300 × 120 space (the tool is
/// drawn fitted and centred).
Offset careToolPoint(Size size, Offset local) {
  final k = math.min(size.width / kCareToolSpace.width, size.height / kCareToolSpace.height);
  final dx = (size.width - kCareToolSpace.width * k) / 2;
  final dy = (size.height - kCareToolSpace.height * k) / 2;
  return Offset((local.dx - dx) / k, (local.dy - dy) / k);
}

/// The inverse of [careToolPoint].
Offset careLocalPoint(Size size, Offset p) {
  final k = math.min(size.width / kCareToolSpace.width, size.height / kCareToolSpace.height);
  final dx = (size.width - kCareToolSpace.width * k) / 2;
  final dy = (size.height - kCareToolSpace.height * k) / 2;
  return Offset(dx + p.dx * k, dy + p.dy * k);
}

/// One tool, with its state as layers.
class CareToolPainter extends CustomPainter {
  const CareToolPainter({
    required this.kind,
    this.flaw = CareFlaw.none,
    this.dirt = 0,
    this.wet = 0,
    this.rust = 0,
    this.oil = const [],
    this.meterOn = false,
    this.coiled = true,
    this.flawShown = true,
  });

  final CareKind kind;
  final CareFlaw flaw;

  /// 0 clean … 1 caked (fades as the cloth goes over it).
  final double dirt;
  final double wet;
  final double rust;

  /// Oil drops, in the tool's space.
  final List<Offset> oil;
  final bool meterOn;
  final bool coiled;

  /// The fault shows (the dirt is off).
  final bool flawShown;

  static const _steel = [Color(0xFFE3E7EA), Color(0xFF8F98A1)];
  static const _red = Color(0xFFD23A2C);
  static const _yellow = Color(0xFFF2C230);

  @override
  void paint(Canvas c, Size s) {
    final k = math.min(s.width / kCareToolSpace.width, s.height / kCareToolSpace.height);
    c.save();
    c.translate((s.width - kCareToolSpace.width * k) / 2, (s.height - kCareToolSpace.height * k) / 2);
    c.scale(k);
    // A soft shadow on the bench.
    c.drawOval(const Rect.fromLTWH(20, 96, 270, 18), Paint()..color = const Color(0x44000000));
    c.saveLayer(const Rect.fromLTWH(-10, -10, 320, 140), Paint());
    _body(c);
    _grime(c);
    c.restore();
    if (flawShown && flaw == CareFlaw.leak) _leak(c);
    for (final p in oil) {
      c.drawCircle(p, 4.2, Paint()..color = const Color(0xCCB7791F));
      c.drawCircle(p + const Offset(-1.2, -1.4), 1.3, Paint()..color = const Color(0xDDFFF3C4));
    }
    c.restore();
  }

  void _body(Canvas c) {
    switch (kind) {
      case CareKind.pliers:
        _pliers(c);
      case CareKind.screwdriver:
        _screwdriver(c);
      case CareKind.spanner:
        _spanner(c);
      case CareKind.meter:
        _meter(c);
      case CareKind.crimper:
        _crimper(c);
    }
  }

  static Paint _metal(Rect r) => Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: _steel).createShader(r);

  static void _grip(Canvas c, Offset a, Offset b, double width) {
    // Two-colour insulation: yellow under red (the yellow shows only where it is damaged).
    c.drawLine(a, b, Paint()
      ..color = _yellow
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round);
    c.drawLine(a, b, Paint()
      ..color = _red
      ..strokeWidth = width - 3
      ..strokeCap = StrokeCap.round);
    final d = b - a;
    final n = Offset(-d.dy, d.dx) / d.distance;
    c.drawLine(a + n * (width * 0.22), b + n * (width * 0.22), Paint()
      ..color = const Color(0x55FFFFFF)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round);
    // The guard at the metal end.
    c.drawLine(a - n * (width * 0.75), a + n * (width * 0.75), Paint()
      ..color = _red
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round);
  }

  static void _crackOn(Canvas c, Offset at) {
    final p = Path()
      ..moveTo(at.dx - 14, at.dy - 9)
      ..lineTo(at.dx - 4, at.dy - 2)
      ..lineTo(at.dx - 10, at.dy + 3)
      ..lineTo(at.dx + 4, at.dy + 10)
      ..moveTo(at.dx - 4, at.dy - 2)
      ..lineTo(at.dx + 8, at.dy - 6);
    c.drawPath(p, Paint()
      ..color = _yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.5
      ..strokeJoin = StrokeJoin.round);
    c.drawPath(p, Paint()
      ..color = const Color(0xFF1B1B1B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round);
  }

  void _pliers(Canvas c) {
    _grip(c, const Offset(146, 52), const Offset(288, 26), 17);
    _grip(c, const Offset(146, 68), const Offset(288, 94), 17);
    final jaw = Path()
      ..moveTo(16, 57)
      ..lineTo(70, 46)
      ..lineTo(134, 50)
      ..lineTo(134, 70)
      ..lineTo(70, 74)
      ..lineTo(16, 63)
      ..close();
    c.drawPath(jaw, _metal(const Rect.fromLTWH(16, 46, 120, 28)));
    c.drawLine(const Offset(18, 60), const Offset(96, 60), Paint()
      ..color = const Color(0xFF59616A)
      ..strokeWidth = 1.4);
    for (var x = 30.0; x < 92; x += 6) {
      c.drawLine(Offset(x, 56), Offset(x, 64), Paint()
        ..color = const Color(0x66323840)
        ..strokeWidth = 1);
    }
    c.drawCircle(const Offset(128, 60), 13, _metal(Rect.fromCircle(center: const Offset(128, 60), radius: 13)));
    c.drawCircle(const Offset(128, 60), 4, Paint()..color = const Color(0xFF59616A));
    if (flawShown && flaw == CareFlaw.crack) _crackOn(c, const Offset(214, 40));
  }

  void _screwdriver(Canvas c) {
    // The blade: steel; its tip flat — or bent.
    final blade = Paint()
      ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: _steel).createShader(const Rect.fromLTWH(20, 55, 160, 10))
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.butt;
    final bent = flawShown && flaw == CareFlaw.bent;
    if (bent) {
      c.drawLine(const Offset(60, 60), const Offset(176, 60), blade);
      c.drawLine(const Offset(62, 60), const Offset(30, 42), blade);
      final tip = Path()
        ..moveTo(32, 37)
        ..lineTo(18, 30)
        ..lineTo(14, 36)
        ..lineTo(28, 46)
        ..close();
      c.drawPath(tip, Paint()..color = const Color(0xFF9AA2AA));
    } else {
      c.drawLine(const Offset(30, 60), const Offset(176, 60), blade);
      final tip = Path()
        ..moveTo(32, 55)
        ..lineTo(14, 57)
        ..lineTo(14, 63)
        ..lineTo(32, 65)
        ..close();
      c.drawPath(tip, Paint()..color = const Color(0xFF9AA2AA));
    }
    // The insulated sleeve along the blade.
    c.drawLine(const Offset(96, 60), const Offset(176, 60), Paint()
      ..color = _red
      ..strokeWidth = 12);
    // The handle.
    const h = Rect.fromLTWH(174, 40, 116, 40);
    c.drawRRect(RRect.fromRectAndRadius(h, const Radius.circular(16)), Paint()..color = _yellow);
    c.drawRRect(RRect.fromRectAndRadius(h.deflate(2.5), const Radius.circular(14)), Paint()..color = _red);
    for (var x = 196.0; x < 280; x += 12) {
      c.drawLine(Offset(x, 46), Offset(x, 74), Paint()
        ..color = const Color(0x44000000)
        ..strokeWidth = 3);
    }
    c.drawLine(const Offset(180, 48), const Offset(284, 48), Paint()
      ..color = const Color(0x44FFFFFF)
      ..strokeWidth = 2.5);
    if (flawShown && flaw == CareFlaw.crack) _crackOn(c, const Offset(236, 58));
  }

  void _spanner(Canvas c) {
    final steel = _metal(const Rect.fromLTWH(20, 30, 270, 60));
    // The shaft.
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(64, 50, 180, 20), const Radius.circular(8)), steel);
    // The ring end.
    c.drawCircle(const Offset(258, 60), 26, steel);
    c.drawCircle(const Offset(258, 60), 12, Paint()..color = const Color(0xFF5F5141));
    // The open jaw (wider, splayed when worn out).
    final wide = flawShown && flaw == CareFlaw.widened;
    final gap = wide ? 19.0 : 12.0;
    final head = Path()
      ..addOval(Rect.fromCircle(center: const Offset(52, 60), radius: 30));
    final mouth = Path()
      ..moveTo(10, 60 - gap - (wide ? 6 : 0))
      ..lineTo(52, 60 - gap)
      ..lineTo(52, 60 + gap)
      ..lineTo(10, 60 + gap + (wide ? 6 : 0))
      ..close();
    c.drawPath(Path.combine(PathOperation.difference, head, mouth), steel);
    c.drawLine(const Offset(84, 60), const Offset(232, 60), Paint()
      ..color = const Color(0x33FFFFFF)
      ..strokeWidth = 4);
  }

  void _meter(Canvas c) {
    // The leads first (they run under the body).
    final red = Paint()
      ..color = const Color(0xFFC62828)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final black = Paint()
      ..color = const Color(0xFF1B1D20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const jackR = Offset(108, 104);
    const jackB = Offset(64, 104);
    if (coiled) {
      // Loosely coiled: soft loops, probes laid side by side.
      for (var i = 0; i < 3; i++) {
        c.drawOval(Rect.fromCenter(center: Offset(212 + i * 3.0, 60), width: 70 - i * 6.0, height: 54 - i * 6.0), i.isEven ? red : black);
      }
      c.drawPath(Path()..moveTo(jackR.dx, jackR.dy)..quadraticBezierTo(150, 112, 178, 80), red);
      c.drawPath(Path()..moveTo(jackB.dx, jackB.dy)..quadraticBezierTo(140, 118, 180, 86), black);
      _probe(c, const Offset(262, 30), const Offset(292, 30), const Color(0xFFC62828));
      _probe(c, const Offset(262, 42), const Offset(292, 42), const Color(0xFF1B1D20));
    } else {
      // Twisted and folded tight.
      final p = Path()..moveTo(jackR.dx, jackR.dy);
      final q = Path()..moveTo(jackB.dx, jackB.dy);
      for (var i = 0; i <= 14; i++) {
        final x = 130 + i * 10.0;
        p.lineTo(x, 60 + (i.isEven ? -22 : 20));
        q.lineTo(x + 4, 60 + (i.isEven ? 20 : -22));
      }
      c.drawPath(p, red);
      c.drawPath(q, black);
      c.drawPath(Path()..moveTo(150, 30)..lineTo(200, 96)..lineTo(236, 28)..lineTo(270, 90), red..strokeWidth = 3.5);
      _probe(c, const Offset(270, 90), const Offset(292, 104), const Color(0xFFC62828));
      _probe(c, const Offset(274, 30), const Offset(294, 14), const Color(0xFF1B1D20));
    }
    // The body.
    const body = Rect.fromLTWH(24, 6, 122, 108);
    c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(12)), Paint()..color = const Color(0xFFF2B705));
    c.drawRRect(RRect.fromRectAndRadius(body.deflate(6), const Radius.circular(8)), Paint()..color = const Color(0xFF2A2E33));
    const disp = Rect.fromLTWH(40, 16, 90, 34);
    c.drawRRect(RRect.fromRectAndRadius(disp, const Radius.circular(3)), Paint()..color = meterOn ? const Color(0xFFB9E3A1) : const Color(0xFF6D7A6A));
    if (meterOn) {
      final tp = TextPainter(
        text: const TextSpan(text: '0.00', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1E2A1A), fontFamily: 'monospace')),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(c, Offset(disp.right - tp.width - 6, disp.center.dy - tp.height / 2));
    }
    // The dial and its markings.
    c.drawCircle(CareZones.dial, CareZones.dialR, Paint()..color = const Color(0xFF15181B));
    c.drawCircle(CareZones.dial, CareZones.dialR - 5, Paint()..color = const Color(0xFF3B4046));
    final ang = meterOn ? -math.pi / 4 : -math.pi / 2;
    c.drawLine(CareZones.dial, CareZones.dial + Offset(math.cos(ang), math.sin(ang)) * (CareZones.dialR - 4), Paint()
      ..color = const Color(0xFFF2B705)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round);
    _label(c, 'OFF', CareZones.dial + const Offset(-10, -38), 8);
    _label(c, 'V', CareZones.dial + const Offset(22, -30), 9);
    _label(c, 'Ω', CareZones.dial + const Offset(26, -2), 9);
    for (final j in [jackB, jackR]) {
      c.drawCircle(j + const Offset(0, -6), 4, Paint()..color = const Color(0xFF0E0F11));
    }
  }

  static void _label(Canvas c, String t, Offset at, double size) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, color: const Color(0xFFE8E8E8))),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, at);
  }

  static void _probe(Canvas c, Offset a, Offset b, Color col) {
    c.drawLine(a, b, Paint()
      ..color = col
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round);
    final d = (b - a) / (b - a).distance;
    c.drawLine(b, b + d * 9, Paint()
      ..color = const Color(0xFFC9CED3)
      ..strokeWidth = 2);
  }

  void _crimper(Canvas c) {
    // The C-head with its die.
    final head = Paint()..shader = const LinearGradient(colors: [Color(0xFF9FB3C4), Color(0xFF4E6273)], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(const Rect.fromLTWH(14, 20, 90, 80));
    final outer = Path()..addOval(Rect.fromCircle(center: const Offset(58, 60), radius: 38));
    final inner = Path()..addOval(Rect.fromCircle(center: const Offset(52, 60), radius: 18));
    final cut = Path()..addRect(const Rect.fromLTWH(8, 52, 40, 16));
    c.drawPath(Path.combine(PathOperation.difference, Path.combine(PathOperation.difference, outer, inner), cut), head);
    // The cylinder.
    const cyl = Rect.fromLTWH(92, 44, 108, 32);
    c.drawRRect(RRect.fromRectAndRadius(cyl, const Radius.circular(6)), _metal(cyl));
    c.drawRect(const Rect.fromLTWH(118, 44, 4, 32), Paint()..color = const Color(0x55222A33));
    c.drawCircle(const Offset(184, 42), 6, Paint()..color = const Color(0xFFB0352B));
    // Handles: rubber grips.
    final grip = Paint()
      ..color = const Color(0xFF26292D)
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    c.drawLine(const Offset(204, 60), const Offset(290, 60), grip);
    c.drawLine(const Offset(200, 66), const Offset(282, 100), grip);
  }

  void _leak(Canvas c) {
    final oil = Paint()..color = const Color(0xE08A5A12);
    c.drawPath(
      Path()
        ..moveTo(146, 74)
        ..quadraticBezierTo(150, 86, 148, 92)
        ..quadraticBezierTo(146, 98, 142, 92)
        ..quadraticBezierTo(140, 84, 146, 74),
      oil,
    );
    c.drawOval(const Rect.fromLTWH(118, 104, 62, 10), oil);
    c.drawCircle(const Offset(146, 80), 1.6, Paint()..color = const Color(0xCCFFE7A8));
  }

  void _grime(Canvas c) {
    final src = BlendMode.srcATop;
    if (rust > 0.01) {
      final rng = math.Random(7);
      final p = Paint()
        ..blendMode = src
        ..color = Color.fromRGBO(150, 72, 24, 0.85 * rust);
      for (var i = 0; i < 46; i++) {
        final x = 24 + rng.nextDouble() * 262;
        final y = 34 + rng.nextDouble() * 52;
        c.drawCircle(Offset(x, y), 2 + rng.nextDouble() * 5, p);
      }
    }
    if (dirt > 0.01) {
      final rng = math.Random(kind.index + 3);
      final p = Paint()
        ..blendMode = src
        ..color = Color.fromRGBO(74, 66, 56, 0.85 * dirt);
      for (var i = 0; i < 26; i++) {
        final x = 10 + rng.nextDouble() * 280;
        final y = 20 + rng.nextDouble() * 80;
        c.drawOval(Rect.fromCenter(center: Offset(x, y), width: 24 + rng.nextDouble() * 40, height: 10 + rng.nextDouble() * 16), p);
      }
      c.drawRect(const Rect.fromLTWH(-10, -10, 320, 140), Paint()
        ..blendMode = src
        ..color = Color.fromRGBO(60, 54, 46, 0.45 * dirt));
    }
    if (wet > 0.01) {
      final rng = math.Random(11);
      final drop = Paint()
        ..blendMode = src
        ..color = Color.fromRGBO(120, 190, 235, 0.85 * wet);
      final shine = Paint()
        ..blendMode = src
        ..color = Color.fromRGBO(255, 255, 255, 0.9 * wet);
      for (var i = 0; i < 16; i++) {
        final o = Offset(20 + rng.nextDouble() * 270, 30 + rng.nextDouble() * 60);
        final r = 2.5 + rng.nextDouble() * 3;
        c.drawCircle(o, r, drop);
        c.drawCircle(o + Offset(-r * 0.35, -r * 0.35), r * 0.3, shine);
      }
    }
  }

  /// The painted outline of [k]'s place on the pegboard, in a box of [size].
  static void outline(Canvas c, CareKind k, Size size) {
    final sc = math.min(size.width / kCareToolSpace.width, size.height / kCareToolSpace.height);
    c.save();
    c.translate((size.width - kCareToolSpace.width * sc) / 2, (size.height - kCareToolSpace.height * sc) / 2);
    c.scale(sc);
    final p = Paint()
      ..color = const Color(0x88FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5 / sc.clamp(0.2, 1.0);
    switch (k) {
      case CareKind.pliers:
        c.drawPath(Path()..moveTo(16, 60)..lineTo(130, 52)..lineTo(288, 26)..moveTo(130, 68)..lineTo(288, 94)..moveTo(16, 60)..lineTo(130, 68), p);
      case CareKind.screwdriver:
        c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(14, 54, 290, 12), const Radius.circular(6)), p);
        c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(174, 40, 116, 40), const Radius.circular(16)), p);
      case CareKind.spanner:
        c.drawCircle(const Offset(52, 60), 30, p);
        c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(64, 50, 180, 20), const Radius.circular(8)), p);
        c.drawCircle(const Offset(258, 60), 26, p);
      case CareKind.meter:
        c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(24, 6, 122, 108), const Radius.circular(12)), p);
        c.drawOval(Rect.fromCenter(center: const Offset(214, 60), width: 70, height: 54), p);
      case CareKind.crimper:
        c.drawCircle(const Offset(58, 60), 38, p);
        c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(92, 44, 108, 32), const Radius.circular(6)), p);
        c.drawLine(const Offset(204, 60), const Offset(290, 60), p);
    }
    c.restore();
  }

  @override
  bool shouldRepaint(CareToolPainter old) =>
      old.kind != kind ||
      old.flaw != flaw ||
      old.dirt != dirt ||
      old.wet != wet ||
      old.rust != rust ||
      old.oil.length != oil.length ||
      old.meterOn != meterOn ||
      old.coiled != coiled ||
      old.flawShown != flawShown;
}

/// The hand tool under the finger while wiping or scrubbing.
class CareHandPainter extends CustomPainter {
  const CareHandPainter({required this.brush});
  final bool brush;

  @override
  void paint(Canvas c, Size s) {
    final r = Offset.zero & s;
    if (brush) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, s.width, s.height * 0.45), const Radius.circular(4)), Paint()..color = const Color(0xFF8A5A2B));
      final wire = Paint()
        ..color = const Color(0xFFB8BEC4)
        ..strokeWidth = 1.4;
      for (var x = 3.0; x < s.width - 2; x += 3) {
        c.drawLine(Offset(x, s.height * 0.45), Offset(x, s.height), wire);
      }
    } else {
      final p = Path()
        ..moveTo(4, s.height * 0.3)
        ..quadraticBezierTo(s.width * 0.3, 0, s.width * 0.7, s.height * 0.12)
        ..quadraticBezierTo(s.width, s.height * 0.3, s.width * 0.9, s.height * 0.75)
        ..quadraticBezierTo(s.width * 0.5, s.height, s.width * 0.15, s.height * 0.85)
        ..close();
      c.drawPath(p, Paint()..color = const Color(0xFFDCD4C0));
      c.drawPath(p, Paint()
        ..color = const Color(0xFF9C927C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2);
      c.drawLine(r.topLeft + Offset(s.width * 0.3, s.height * 0.4), r.topLeft + Offset(s.width * 0.75, s.height * 0.5), Paint()
        ..color = const Color(0x55786E58)
        ..strokeWidth = 1);
    }
  }

  @override
  bool shouldRepaint(CareHandPainter old) => old.brush != brush;
}

/// A small icon of a bench item (cloth, brush, oil can, tag) for the tray.
class CareKitIconPainter extends CustomPainter {
  const CareKitIconPainter(this.item);

  /// 0 cloth · 1 steel brush · 2 oil can · 3 tag.
  final int item;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final h = s.height;
    switch (item) {
      case 0:
        const CareHandPainter(brush: false).paint(c, s);
      case 1:
        c.save();
        c.translate(w * 0.1, h * 0.15);
        const CareHandPainter(brush: true).paint(c, Size(w * 0.8, h * 0.7));
        c.restore();
      case 2:
        final can = Rect.fromLTWH(w * 0.12, h * 0.42, w * 0.5, h * 0.5);
        c.drawRRect(RRect.fromRectAndRadius(can, const Radius.circular(4)), Paint()..color = const Color(0xFF2E7D4F));
        c.drawRect(Rect.fromLTWH(can.left, can.top + can.height * 0.35, can.width, can.height * 0.2), Paint()..color = const Color(0xFFF2C230));
        c.drawLine(Offset(can.right - 4, can.top + 4), Offset(w * 0.92, h * 0.08), Paint()
          ..color = const Color(0xFF8F98A1)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round);
        c.drawCircle(Offset(w * 0.92, h * 0.2), 2.6, Paint()..color = const Color(0xFFB7791F));
      default:
        final tag = Path()
          ..moveTo(w * 0.3, h * 0.12)
          ..lineTo(w * 0.7, h * 0.12)
          ..lineTo(w * 0.86, h * 0.3)
          ..lineTo(w * 0.86, h * 0.9)
          ..lineTo(w * 0.14, h * 0.9)
          ..lineTo(w * 0.14, h * 0.3)
          ..close();
        c.drawPath(tag, Paint()..color = const Color(0xFFE74C3C));
        c.drawCircle(Offset(w * 0.5, h * 0.26), 3, Paint()..color = const Color(0xFFF7F1E1));
        final line = Paint()
          ..color = const Color(0xCCFFFFFF)
          ..strokeWidth = 2;
        for (var i = 0; i < 3; i++) {
          c.drawLine(Offset(w * 0.26, h * (0.48 + i * 0.13)), Offset(w * 0.74, h * (0.48 + i * 0.13)), line);
        }
    }
  }

  @override
  bool shouldRepaint(CareKitIconPainter old) => old.item != item;
}

/// The deadly moment's "what would happen": tomorrow, on the line — the hand
/// on the cracked grip, the current through the crack.
class CareShockPainter extends CustomPainter {
  const CareShockPainter(this.t);
  final double t;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final h = s.height;
    final box = Rect.fromCenter(center: Offset(w / 2, h * 0.42), width: math.min(300, w - 40), height: 200);
    c.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(18)), Paint()..color = const Color(0xFF0E1830));
    c.save();
    c.clipRRect(RRect.fromRectAndRadius(box, const Radius.circular(18)));
    // A live wire across the top.
    c.drawLine(Offset(box.left, box.top + 46), Offset(box.right, box.top + 40), Paint()
      ..color = const Color(0xFF9AA4B0)
      ..strokeWidth = 4);
    // The pliers on the wire, the hand on the grip.
    c.save();
    c.translate(box.left + 20, box.top + 36);
    c.rotate(0.5);
    c.scale(0.8);
    const CareToolPainter(kind: CareKind.pliers, flaw: CareFlaw.crack).paint(c, kCareToolSpace);
    c.restore();
    final hand = Paint()..color = const Color(0xFFC68A5E);
    c.drawOval(Rect.fromCenter(center: Offset(box.left + 196, box.top + 148), width: 64, height: 40), hand);
    // The current: from the wire, through the crack, into the hand.
    final glow = 0.5 + 0.5 * math.sin(t * math.pi * 10).abs();
    final bolt = Path()
      ..moveTo(box.left + 46, box.top + 46)
      ..lineTo(box.left + 120, box.top + 92)
      ..lineTo(box.left + 110, box.top + 104)
      ..lineTo(box.left + 168, box.top + 120)
      ..lineTo(box.left + 160, box.top + 132)
      ..lineTo(box.left + 196, box.top + 148);
    c.drawPath(bolt, Paint()
      ..color = Color.fromRGBO(120, 200, 255, 0.35 * glow)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12);
    c.drawPath(bolt, Paint()
      ..color = Color.fromRGBO(240, 250, 255, glow)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
    c.restore();
  }

  @override
  bool shouldRepaint(CareShockPainter old) => old.t != t;
}
