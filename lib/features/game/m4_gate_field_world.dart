import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

// The drawn world of the Module 4 rank gate (m4_gate_field.dart): one feeder
// on one maintenance day — the transformer yard (DO fuses, conservator gauge,
// earth pit), an 11 kV pin-insulator pole, a dead-end pole's jumper, the DP
// structure, a tree by the line, a street light and the LT feeder pillar.
// Everything is painted (no new picture assets), in design pixels (360 wide).

// ============================================================================
// Shared bits
// ============================================================================

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

/// Sky, far tree line and the field, down from [groundY].
void _backdrop(Canvas canvas, Size size, double groundY, {bool dusk = false}) {
  final w = size.width;
  canvas.drawRect(
    Rect.fromLTWH(0, 0, w, groundY),
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: dusk ? const [Color(0xFF1F2B4F), Color(0xFFD98A5A)] : const [Color(0xFF6FA8DC), Color(0xFFCFE6F5)],
      ).createShader(Rect.fromLTWH(0, 0, w, groundY)),
  );
  final far = Paint()..color = dusk ? const Color(0xFF34503F) : const Color(0xFF7FA77A);
  final hills = Path()..moveTo(0, groundY);
  for (var x = 0.0; x <= w; x += 24) {
    hills.lineTo(x, groundY - 26 - 12 * math.sin(x / 31) - 8 * math.cos(x / 13));
  }
  canvas.drawPath(hills..lineTo(w, groundY)..close(), far);
  canvas.drawRect(
    Rect.fromLTWH(0, groundY, w, size.height - groundY),
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: dusk ? const [Color(0xFF5D6E3A), Color(0xFF3D4F26)] : const [Color(0xFF8DA65A), Color(0xFF5E7A38)],
      ).createShader(Rect.fromLTWH(0, groundY, w, size.height - groundY)),
  );
  canvas.drawPath(
    Path()
      ..moveTo(0, groundY + 40)
      ..quadraticBezierTo(150, groundY + 18, w, groundY + 30)
      ..lineTo(w, groundY + 52)
      ..quadraticBezierTo(150, groundY + 42, 0, groundY + 70)
      ..close(),
    Paint()..color = dusk ? const Color(0xFF8A7650) : const Color(0xFFB59B6A),
  );
}

final _wire = Paint()
  ..color = const Color(0xFF2F343A)
  ..strokeWidth = 1.6
  ..style = PaintingStyle.stroke;

void _pole(Canvas c, double x, double top, double bottom, {double w = 12}) {
  c.drawRect(
    Rect.fromLTWH(x - w / 2, top, w, bottom - top),
    Paint()
      ..shader = const LinearGradient(colors: [Color(0xFF8E9399), Color(0xFFC9CDD2), Color(0xFF8E9399)])
          .createShader(Rect.fromLTWH(x - w / 2, top, w, bottom - top)),
  );
}

void _arm(Canvas c, double l, double r, double y) =>
    c.drawRect(Rect.fromLTWH(l, y - 3.5, r - l, 7), Paint()..color = const Color(0xFF4A5058));

/// A pin insulator standing on [base] (its top groove at base.dy - 22).
void _pinInsulator(Canvas c, Offset base, {bool broken = false, bool fresh = false}) {
  final por = Paint()..color = fresh ? const Color(0xFFE9E4D8) : const Color(0xFFD9CFC0);
  final shed = Paint()..color = fresh ? const Color(0xFFF7F3EA) : const Color(0xFFC8BCA8);
  c.drawRect(Rect.fromLTWH(base.dx - 2, base.dy - 6, 4, 6), Paint()..color = const Color(0xFF70777F));
  c.drawOval(Rect.fromCenter(center: base.translate(0, -8), width: 22, height: 7), shed);
  c.drawRect(Rect.fromLTWH(base.dx - 6, base.dy - 20, 12, 13), por);
  c.drawOval(Rect.fromCenter(center: base.translate(0, -16), width: 18, height: 6), shed);
  c.drawOval(Rect.fromCenter(center: base.translate(0, -22), width: 12, height: 5), por);
  if (broken) {
    final crack = Paint()
      ..color = const Color(0xFF3A2A20)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    c.drawPath(
      Path()
        ..moveTo(base.dx - 4, base.dy - 22)
        ..lineTo(base.dx + 1, base.dy - 15)
        ..lineTo(base.dx - 2, base.dy - 11)
        ..lineTo(base.dx + 4, base.dy - 5),
      crack,
    );
    // A chipped shed.
    c.drawPath(
      Path()
        ..moveTo(base.dx + 5, base.dy - 10)
        ..lineTo(base.dx + 11, base.dy - 9)
        ..lineTo(base.dx + 8, base.dy - 5)
        ..close(),
      Paint()..color = const Color(0xFF8E9399),
    );
  }
}

/// A spark or arc flash at [at].
class M4GateSparkPainter extends CustomPainter {
  const M4GateSparkPainter({required this.at, this.big = false});
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
  bool shouldRepaint(M4GateSparkPainter old) => old.at != at || old.big != big;
}

/// The hot stick in the worker's hands, reaching from [from] to [to].
class M4GateStickPainter extends CustomPainter {
  const M4GateStickPainter({required this.from, required this.to});
  final Offset from;
  final Offset to;

  @override
  void paint(Canvas canvas, Size size) {
    final grip = from + (to - from) * 0.12;
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
  bool shouldRepaint(M4GateStickPainter old) => old.from != from || old.to != to;
}

/// What a handheld meter is.
enum M4GateMeterKind { irGun, earthTester, tong, tester }

/// A handheld meter with its display: the IR thermometer, the earth
/// resistance tester, the tong tester or the voltage tester.
class M4GateMeterPainter extends CustomPainter {
  const M4GateMeterPainter({required this.kind, required this.reading});
  final M4GateMeterKind kind;
  final String reading;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final body = switch (kind) {
      M4GateMeterKind.irGun => const Color(0xFFE5A21A),
      M4GateMeterKind.earthTester => const Color(0xFF2E6B3A),
      M4GateMeterKind.tong => const Color(0xFFD9542B),
      M4GateMeterKind.tester => const Color(0xFF2F5FA8),
    };
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(10));
    canvas.drawRRect(r, Paint()..color = body);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(3, 3, w - 6, h - 6), const Radius.circular(8)),
      Paint()
        ..color = const Color(0x55000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    if (kind == M4GateMeterKind.tong) {
      // The jaw on top.
      canvas.drawArc(
        Rect.fromCenter(center: Offset(w / 2, 4), width: w * 0.62, height: 30),
        math.pi,
        math.pi,
        false,
        Paint()
          ..color = const Color(0xFF222428)
          ..strokeWidth = 7
          ..style = PaintingStyle.stroke,
      );
    }
    final disp = Rect.fromLTWH(8, h * 0.14, w - 16, h * 0.38);
    canvas.drawRRect(RRect.fromRectAndRadius(disp, const Radius.circular(4)), Paint()..color = const Color(0xFFBFD8A8));
    final tp = TextPainter(
      text: TextSpan(
        text: reading,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF1B2A12)),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout(maxWidth: disp.width - 4);
    tp.paint(canvas, disp.center - Offset(tp.width / 2, tp.height / 2));
    final name = switch (kind) {
      M4GateMeterKind.irGun => 'IR °C',
      M4GateMeterKind.earthTester => 'EARTH Ω',
      M4GateMeterKind.tong => 'CLAMP A',
      M4GateMeterKind.tester => 'TESTER V',
    };
    _label(canvas, name, Offset(w / 2, h * 0.66), 10, Colors.white);
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(Offset(w * (0.28 + i * 0.22), h * 0.84), 5, Paint()..color = const Color(0xFF1B1E22));
    }
  }

  @override
  bool shouldRepaint(M4GateMeterPainter old) => old.kind != kind || old.reading != reading;
}

// ============================================================================
// 1–3 The transformer yard
// ============================================================================

/// Where things stand in the yard, for a scene [h] design pixels high.
@immutable
class M4DtrGeo {
  const M4DtrGeo(this.h);
  final double h;

  double get groundY => h - 230;
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

  /// The conservator on the tank and its glass oil gauge.
  Rect get conservator => Rect.fromLTWH(tank.left - 4, tank.top - 22, 54, 15);
  Rect get gauge => Rect.fromLTWH(conservator.left - 9, conservator.top - 10, 9, 34);

  Offset get underSpot => Offset(doX(1), groundY);
  Offset get sideSpot => Offset(doX(0) - 104, groundY);

  /// The earth pit, its clamp on the earth strip, and the two test spikes.
  Offset get pit => Offset(140, groundY + 26);
  Rect get pitHit => Rect.fromCenter(center: pit, width: 64, height: 40);
  Offset get clamp => Offset(poleL - 8, groundY - 40);
  Rect get clampHit => Rect.fromCenter(center: clamp, width: 48, height: 44);
  Offset spike(int i) => Offset(i == 0 ? 84 : 30, groundY + 64 + i * 10);

  /// Where the earth tester's leads end (the tester on the left).
  Offset get testerAt => Offset(54, groundY - 66);
  Rect spikeHit(int i) => Rect.fromCenter(center: spike(i).translate(0, -6), width: 56, height: 44);

  Rect figureAt(Offset foot) => Rect.fromLTWH(foot.dx - 30, foot.dy - 118, 59, 118);
  Offset handsAt(Offset foot) => foot + const Offset(14, -74);
}

/// The yard: the double-pole transformer with three DO fuses, the LT box,
/// the conservator with its oil gauge, the earth strip and pit, the test
/// spikes and leads.
class M4DtrPainter extends CustomPainter {
  const M4DtrPainter({
    required this.geo,
    required this.doOpen,
    required this.ltOn,
    this.oilLow = false,
    this.spikes = const {},
    this.wet = false,
    this.tight = false,
    this.tester = false,
  });

  final M4DtrGeo geo;
  final List<bool> doOpen;
  final bool ltOn;
  final bool oilLow;
  final Set<int> spikes;
  final bool wet;
  final bool tight;
  final bool tester;

  @override
  void paint(Canvas canvas, Size size) {
    final g = geo;
    _backdrop(canvas, size, g.groundY);
    for (var i = 0; i < 3; i++) {
      final y = g.top - 28 + i * 2.0;
      canvas.drawPath(Path()..moveTo(0, y - 18)..quadraticBezierTo(110, y + 14, g.doX(i), g.doTopY - 2), _wire);
    }
    for (final x in const [M4DtrGeo.poleL, M4DtrGeo.poleR]) {
      _pole(canvas, x, g.top - 40, g.groundY + 6);
    }
    _arm(canvas, M4DtrGeo.poleL - 10, M4DtrGeo.poleR + 10, g.armY);
    for (var i = 0; i < 3; i++) {
      _doFuse(canvas, i, doOpen.length > i && doOpen[i]);
    }
    final t = g.tank;
    _arm(canvas, M4DtrGeo.poleL - 8, M4DtrGeo.poleR + 8, t.bottom + 3);
    // Conservator and its gauge.
    final cons = g.conservator;
    canvas.drawRRect(RRect.fromRectAndRadius(cons, const Radius.circular(7)), Paint()..color = const Color(0xFF7E8E78));
    canvas.drawLine(Offset(cons.center.dx, cons.bottom), Offset(cons.center.dx, t.top), Paint()..color = const Color(0xFF55634F)..strokeWidth = 3);
    final gg = g.gauge;
    canvas.drawRRect(RRect.fromRectAndRadius(gg.inflate(2), const Radius.circular(3)), Paint()..color = const Color(0xFF3E4A3A));
    canvas.drawRRect(RRect.fromRectAndRadius(gg, const Radius.circular(2)), Paint()..color = const Color(0xFFE8F1F4));
    final minY = gg.bottom - gg.height * 0.25;
    final maxY = gg.top + gg.height * 0.18;
    final level = oilLow ? gg.bottom - gg.height * 0.1 : gg.top + gg.height * 0.48;
    canvas.drawRect(Rect.fromLTRB(gg.left, level, gg.right, gg.bottom), Paint()..color = const Color(0xFFC9962B));
    final mark = Paint()
      ..color = const Color(0xFFB71C1C)
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(gg.left - 3, minY), Offset(gg.right + 3, minY), mark);
    canvas.drawLine(Offset(gg.left - 3, maxY), Offset(gg.right + 3, maxY), mark);
    _label(canvas, 'MAX', Offset(gg.left - 14, maxY), 6, const Color(0xFF26303D));
    _label(canvas, 'MIN', Offset(gg.left - 14, minY), 6, const Color(0xFF26303D));
    // Tank and fins.
    canvas.drawRRect(
      RRect.fromRectAndRadius(t, const Radius.circular(4)),
      Paint()..shader = const LinearGradient(colors: [Color(0xFF6C7B66), Color(0xFF9AAB92), Color(0xFF6C7B66)]).createShader(t),
    );
    final fin = Paint()
      ..color = const Color(0xFF55634F)
      ..strokeWidth = 2;
    for (var x = t.left + 8; x < t.right - 4; x += 8) {
      canvas.drawLine(Offset(x, t.top + 10), Offset(x, t.bottom - 6), fin);
    }
    if (oilLow) {
      // An oil streak down from the drain valve.
      canvas.drawPath(
        Path()
          ..moveTo(t.right - 10, t.bottom - 6)
          ..quadraticBezierTo(t.right - 6, t.bottom + 10, t.right - 9, t.bottom + 18),
        Paint()
          ..color = const Color(0xCC5A3A12)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke,
      );
    }
    for (var i = 0; i < 3; i++) {
      final bx = g.doX(i);
      canvas.drawRect(Rect.fromLTWH(bx - 3, t.top - 16, 6, 16), Paint()..color = const Color(0xFF8C5A3C));
      canvas.drawLine(Offset(bx, g.doTopY + g.doLen + 6), Offset(bx, t.top - 16), _wire);
    }
    // LT cable and box.
    canvas.drawPath(
      Path()
        ..moveTo(t.left + 4, t.top + 20)
        ..quadraticBezierTo(M4DtrGeo.poleL - 30, t.top + 30, g.ltBox.center.dx, g.ltBox.top),
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
    // Earth strip down pole L, through the clamp, to the pit.
    final strip = Paint()
      ..color = const Color(0xFF9A6B3A)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawPath(
      Path()
        ..moveTo(M4DtrGeo.poleL - 6, t.bottom + 6)
        ..lineTo(g.clamp.dx, g.clamp.dy)
        ..lineTo(g.clamp.dx, g.groundY + 10)
        ..lineTo(g.pit.dx, g.pit.dy - 4),
      strip,
    );
    // The clamp (rusty until tightened with a brass nut).
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: g.clamp, width: 14, height: 12), const Radius.circular(2)),
      Paint()..color = tight ? const Color(0xFFD4AF37) : const Color(0xFF8B4A24),
    );
    if (!tight) {
      for (final d in const [Offset(-6, 5), Offset(5, -5), Offset(7, 4)]) {
        canvas.drawCircle(g.clamp + d, 2, Paint()..color = const Color(0xFFB4632E));
      }
    }
    // The pit cover.
    final pr = Rect.fromCenter(center: g.pit, width: 50, height: 22);
    canvas.drawOval(pr.inflate(4), Paint()..color = wet ? const Color(0xFF4A3A26) : const Color(0xFFA08A62));
    canvas.drawOval(pr, Paint()..color = const Color(0xFF6B6F74));
    _label(canvas, 'E', g.pit, 9, Colors.white);
    if (wet) {
      canvas.drawOval(pr.inflate(9), Paint()..color = const Color(0x553F8FD8));
    }
    // Test spikes and leads.
    for (var i = 0; i < 2; i++) {
      final s = g.spike(i);
      if (spikes.contains(i)) {
        canvas.drawLine(s.translate(0, -18), s, Paint()..color = const Color(0xFF9AA4AE)..strokeWidth = 3);
        canvas.drawCircle(s.translate(0, -18), 3, Paint()..color = i == 0 ? const Color(0xFFF2C40F) : const Color(0xFFD7312B));
        if (tester) {
          canvas.drawPath(
            Path()
              ..moveTo(s.dx, s.dy - 18)
              ..quadraticBezierTo((s.dx + g.testerAt.dx) / 2, s.dy + 10, g.testerAt.dx, g.testerAt.dy),
            Paint()
              ..color = i == 0 ? const Color(0xFFF2C40F) : const Color(0xFFD7312B)
              ..strokeWidth = 1.6
              ..style = PaintingStyle.stroke,
          );
        }
      } else {
        canvas.drawOval(Rect.fromCenter(center: s, width: 26, height: 9), Paint()..color = const Color(0x55FFFFFF));
      }
    }
    if (tester && spikes.isNotEmpty) {
      canvas.drawPath(
        Path()
          ..moveTo(g.clamp.dx, g.clamp.dy)
          ..quadraticBezierTo(120, g.groundY + 30, g.testerAt.dx, g.testerAt.dy),
        Paint()
          ..color = const Color(0xFF2A62C9)
          ..strokeWidth = 1.6
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _doFuse(Canvas c, int i, bool open) {
    final g = geo;
    final x = g.doX(i);
    final por = Paint()..color = const Color(0xFF8C5A3C);
    c.drawRect(Rect.fromLTWH(x - 3.5, g.doTopY - 8, 7, 10), por);
    c.drawRect(Rect.fromLTWH(x - 3.5, g.doTopY + g.doLen - 2, 7, 10), por);
    final tube = Paint()
      ..color = const Color(0xFF3B3F45)
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    final bottom = Offset(x, g.doTopY + g.doLen);
    if (open) {
      c.drawLine(bottom, bottom + Offset(16, g.doLen * 0.82), tube);
      c.drawCircle(bottom + Offset(18, g.doLen * 0.86), 3.5, Paint()..color = const Color(0xFF9AA4AE));
    } else {
      c.drawLine(Offset(x, g.doTopY + 2), bottom, tube);
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

  @override
  bool shouldRepaint(M4DtrPainter old) =>
      old.geo.h != geo.h ||
      old.ltOn != ltOn ||
      old.oilLow != oilLow ||
      old.wet != wet ||
      old.tight != tight ||
      old.tester != tester ||
      old.spikes.length != spikes.length ||
      old.doOpen.where((o) => o).length != doOpen.where((o) => o).length;
}

// ============================================================================
// 4 The pin-insulator pole · 5 the dead-end jumper
// ============================================================================

@immutable
class M4PoleGeo {
  const M4PoleGeo(this.h);
  final double h;

  double get groundY => h - 230;
  static const poleX = 180.0;
  double get armY => 210;
  Offset ins(int i) => switch (i) {
        0 => Offset(118, armY - 4),
        1 => Offset(poleX, armY - 30),
        _ => Offset(242, armY - 4),
      };
  double wireY(int i) => ins(i).dy - 22;

  Rect earthHit(int side) => Rect.fromCenter(center: Offset(side == 0 ? 34 : 326, armY + 70), width: 64, height: 150);

  Rect groundFigure() => Rect.fromLTWH(poleX - 92, groundY - 118, 59, 118);
  Rect poleFigure() => Rect.fromLTWH(poleX - 54, armY + 6, 59, 118);

  // Dead-end jumper (station 5).
  Offset clamp(int side) => Offset(side == 0 ? 132 : 228, armY + 40);
  Rect clampHit(int side) => Rect.fromCenter(center: clamp(side), width: 56, height: 50);
}

/// The 11 kV pole: three pin insulators (one dealt broken), the line, and
/// the portable earths clamped on both sides; or (jumper) a dead-end pole
/// with disc strings and the jumper loop under the cross-arm.
class M4PolePainter extends CustomPainter {
  const M4PolePainter({
    required this.geo,
    this.broken,
    this.replaced = false,
    this.earths = const {},
    this.jumper = false,
    this.hotSide,
    this.clean = false,
    this.tight = false,
    this.roped = false,
  });

  final M4PoleGeo geo;
  final int? broken;
  final bool replaced;
  final Set<int> earths;
  final bool jumper;
  final int? hotSide;
  final bool clean;
  final bool tight;
  final bool roped;

  @override
  void paint(Canvas canvas, Size size) {
    final g = geo;
    _backdrop(canvas, size, g.groundY);
    _pole(canvas, M4PoleGeo.poleX, g.armY - 60, g.groundY + 6, w: 14);
    _arm(canvas, 96, 264, g.armY);
    // Danger plate.
    canvas.drawRect(Rect.fromLTWH(M4PoleGeo.poleX - 10, g.groundY - 150, 20, 14), Paint()..color = const Color(0xFFFFE04A));
    _label(canvas, '11kV', Offset(M4PoleGeo.poleX, g.groundY - 143), 6, const Color(0xFFB71C1C));
    if (jumper) {
      _jumper(canvas);
    } else {
      for (var i = 0; i < 3; i++) {
        _pinInsulator(canvas, g.ins(i), broken: broken == i && !replaced, fresh: broken == i && replaced);
        final y = g.wireY(i);
        canvas.drawPath(Path()..moveTo(0, y + 10)..quadraticBezierTo(g.ins(i).dx / 2, y + 4, g.ins(i).dx, y), _wire);
        canvas.drawPath(Path()..moveTo(g.ins(i).dx, y)..quadraticBezierTo((g.ins(i).dx + 360) / 2, y + 4, 360, y + 10), _wire);
      }
      if (roped && broken != null) {
        final p = g.ins(broken!).translate(0, -24);
        canvas.drawLine(p, Offset(M4PoleGeo.poleX + 4, g.armY - 48), Paint()..color = const Color(0xFFD9B26A)..strokeWidth = 2);
      }
    }
    for (final side in earths) {
      _earthSet(canvas, side);
    }
    // Earth set spots (on the ground) not yet used.
    for (var side = 0; side < 2; side++) {
      if (earths.contains(side) || jumper) continue;
      final x = side == 0 ? 34.0 : 326.0;
      canvas.drawOval(Rect.fromCenter(center: Offset(x, g.groundY + 30), width: 34, height: 10), Paint()..color = const Color(0x66FFFFFF));
    }
  }

  void _earthSet(Canvas c, int side) {
    final g = geo;
    final x = side == 0 ? 34.0 : 326.0;
    final rod = Offset(x, g.groundY + 30);
    final lead = Paint()
      ..color = const Color(0xFF2E7D32)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 3; i++) {
      final y = g.wireY(i) + 8;
      c.drawLine(Offset(x - 6 + i * 6, y), Offset(x, g.armY + 40), lead);
      c.drawCircle(Offset(x - 6 + i * 6, y), 2.6, Paint()..color = const Color(0xFF9AA4AE));
    }
    c.drawLine(Offset(x, g.armY + 40), rod, lead..strokeWidth = 2.6);
    c.drawLine(rod, rod.translate(0, 14), Paint()..color = const Color(0xFF6E757C)..strokeWidth = 4);
  }

  void _jumper(Canvas c) {
    final g = geo;
    final y = g.armY;
    final disc = Paint()..color = const Color(0xFF8C5A3C);
    for (final side in const [0, 1]) {
      final dir = side == 0 ? -1.0 : 1.0;
      final start = Offset(M4PoleGeo.poleX + dir * 40, y);
      for (var k = 0; k < 3; k++) {
        c.drawOval(Rect.fromCenter(center: start + Offset(dir * (10 + k * 9), 0), width: 6, height: 18), disc);
      }
      final dead = start + Offset(dir * 40, 0);
      c.drawLine(start, dead, Paint()..color = const Color(0xFF6E757C)..strokeWidth = 2);
      c.drawPath(Path()..moveTo(dead.dx, dead.dy)..quadraticBezierTo(dead.dx + dir * 60, dead.dy + 10, dead.dx + dir * 140, dead.dy + 12), _wire);
      // Down to the clamp.
      c.drawLine(dead, g.clamp(side), _wire);
    }
    // The jumper's U under the arm.
    final l = g.clamp(0);
    final r = g.clamp(1);
    c.drawPath(
      Path()
        ..moveTo(l.dx, l.dy)
        ..cubicTo(l.dx + 10, l.dy + 70, r.dx - 10, r.dy + 70, r.dx, r.dy),
      Paint()
        ..color = const Color(0xFF2F343A)
        ..strokeWidth = 2.6
        ..style = PaintingStyle.stroke,
    );
    for (final side in const [0, 1]) {
      final p = g.clamp(side);
      final hot = side == hotSide && !tight;
      if (hot) {
        c.drawCircle(
          p,
          22,
          Paint()
            ..shader = const RadialGradient(colors: [Color(0xCCFF5A1F), Color(0x00FF5A1F)]).createShader(Rect.fromCircle(center: p, radius: 22)),
        );
      }
      final body = Rect.fromCenter(center: p, width: 18, height: 12);
      c.drawRRect(
        RRect.fromRectAndRadius(body, const Radius.circular(2)),
        Paint()..color = hot ? (clean ? const Color(0xFFB0A090) : const Color(0xFF5B3A26)) : const Color(0xFFA7AFB7),
      );
      c.drawCircle(p.translate(-4, 0), 2.2, Paint()..color = const Color(0xFF3B3F45));
      c.drawCircle(p.translate(4, 0), 2.2, Paint()..color = const Color(0xFF3B3F45));
    }
  }

  @override
  bool shouldRepaint(M4PolePainter old) =>
      old.geo.h != geo.h ||
      old.broken != broken ||
      old.replaced != replaced ||
      old.earths.length != earths.length ||
      old.jumper != jumper ||
      old.hotSide != hotSide ||
      old.clean != clean ||
      old.tight != tight ||
      old.roped != roped;
}

// ============================================================================
// 6 The DP structure
// ============================================================================

/// The three dressing faults, top (HT) to bottom (LT).
enum M4DpFault { jumper, tail, ltCables }

@immutable
class M4DpGeo {
  const M4DpGeo(this.h);
  final double h;

  double get groundY => h - 230;
  static const poleL = 120.0;
  static const poleR = 252.0;
  double get armY => 176;
  double get tankY => 330;
  Rect get tank => Rect.fromLTWH(146, tankY, 82, 70);
  Offset faultAt(M4DpFault f) => switch (f) {
        M4DpFault.jumper => const Offset(214, 206),
        M4DpFault.tail => const Offset(150, 168),
        M4DpFault.ltCables => Offset(164, tankY + 120),
      };
  Rect faultHit(M4DpFault f) => Rect.fromCenter(center: faultAt(f), width: 60, height: f == M4DpFault.ltCables ? 90 : 50);
}

class M4DpPainter extends CustomPainter {
  const M4DpPainter({required this.geo, required this.fixed, this.nutsTight = false});
  final M4DpGeo geo;
  final Set<M4DpFault> fixed;
  final bool nutsTight;

  @override
  void paint(Canvas canvas, Size size) {
    final g = geo;
    _backdrop(canvas, size, g.groundY);
    _pole(canvas, M4DpGeo.poleL, g.armY - 50, g.groundY + 6);
    _pole(canvas, M4DpGeo.poleR, g.armY - 50, g.groundY + 6);
    _arm(canvas, M4DpGeo.poleL - 14, M4DpGeo.poleR + 14, g.armY);
    _arm(canvas, M4DpGeo.poleL - 8, M4DpGeo.poleR + 8, g.armY + 60);
    for (var i = 0; i < 3; i++) {
      final x = 150.0 + i * 36;
      _pinInsulator(canvas, Offset(x, g.armY - 4));
      canvas.drawPath(Path()..moveTo(0, g.armY - 40 + i * 3)..quadraticBezierTo(80, g.armY - 20, x, g.armY - 26), _wire);
      // Jumper from the HT line down to the DO on the lower arm.
      final top = Offset(x, g.armY - 26);
      final dn = Offset(x, g.armY + 50);
      final sloppy = i == 2 && !fixed.contains(M4DpFault.jumper);
      if (sloppy) {
        // Sags out and lies on the lower cross-arm.
        canvas.drawPath(
          Path()
            ..moveTo(top.dx, top.dy)
            ..cubicTo(top.dx + 44, top.dy + 20, top.dx + 40, g.armY + 54, top.dx + 26, g.armY + 57)
            ..quadraticBezierTo(top.dx + 6, g.armY + 60, dn.dx, dn.dy),
          _wire..strokeWidth = 2,
        );
      } else {
        canvas.drawPath(Path()..moveTo(top.dx, top.dy)..cubicTo(top.dx + 12, top.dy + 18, top.dx + 12, dn.dy - 26, dn.dx, dn.dy), _wire..strokeWidth = 2);
      }
      _wire.strokeWidth = 1.6;
      canvas.drawRect(Rect.fromLTWH(x - 3, g.armY + 50, 6, 26), Paint()..color = const Color(0xFF3B3F45));
      canvas.drawLine(Offset(x, g.armY + 76), Offset(x, g.tankY - 10), _wire);
    }
    // Binding wire tail on the left insulator.
    if (!fixed.contains(M4DpFault.tail)) {
      canvas.drawPath(
        Path()
          ..moveTo(150, g.armY - 26)
          ..quadraticBezierTo(136, g.armY - 30, 126, g.armY - 46),
        Paint()
          ..color = const Color(0xFFB8BEC4)
          ..strokeWidth = 1.6
          ..style = PaintingStyle.stroke,
      );
    }
    // Transformer.
    _arm(canvas, M4DpGeo.poleL - 6, M4DpGeo.poleR + 6, g.tank.bottom + 3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(g.tank, const Radius.circular(4)),
      Paint()..shader = const LinearGradient(colors: [Color(0xFF6C7B66), Color(0xFF9AAB92), Color(0xFF6C7B66)]).createShader(g.tank),
    );
    for (var x = g.tank.left + 8; x < g.tank.right - 4; x += 8) {
      canvas.drawLine(Offset(x, g.tank.top + 10), Offset(x, g.tank.bottom - 6), Paint()..color = const Color(0xFF55634F)..strokeWidth = 2);
    }
    // LT cables down to the box.
    final box = Rect.fromLTWH(M4DpGeo.poleL - 44, g.groundY - 110, 36, 46);
    final cable = Paint()
      ..color = const Color(0xFF1B1E22)
      ..strokeWidth = 3.4
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 4; i++) {
      final from = Offset(g.tank.left + 10 + i * 8, g.tank.bottom - 4);
      final to = Offset(box.left + 6 + i * 8, box.top);
      if (fixed.contains(M4DpFault.ltCables)) {
        canvas.drawPath(Path()..moveTo(from.dx, from.dy)..lineTo(M4DpGeo.poleL + 4 + i * 3, from.dy + 30)..lineTo(M4DpGeo.poleL + 4 + i * 3, box.top - 20)..lineTo(to.dx, to.dy), cable);
      } else {
        canvas.drawPath(
          Path()
            ..moveTo(from.dx, from.dy)
            ..cubicTo(from.dx + 30 - i * 14, from.dy + 90 + i * 12, to.dx + 60 - i * 20, to.dy - 70 + i * 6, to.dx, to.dy),
          cable,
        );
      }
    }
    if (fixed.contains(M4DpFault.ltCables)) {
      for (var y = g.tank.bottom + 40; y < box.top - 20; y += 34) {
        canvas.drawRect(Rect.fromLTWH(M4DpGeo.poleL + 1, y, 16, 4), Paint()..color = const Color(0xFFE6E6E6));
      }
    }
    canvas.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(3)), Paint()..color = const Color(0xFF8B969F));
    _label(canvas, 'LT', box.center, 8, const Color(0xFF26303D));
    if (nutsTight) {
      for (final p in [Offset(M4DpGeo.poleL, g.armY), Offset(M4DpGeo.poleR, g.armY), Offset(M4DpGeo.poleL, g.armY + 60), Offset(M4DpGeo.poleR, g.armY + 60)]) {
        canvas.drawCircle(p, 4, Paint()..color = const Color(0xFF41C463));
      }
    }
  }

  @override
  bool shouldRepaint(M4DpPainter old) => old.geo.h != geo.h || old.fixed.length != fixed.length || old.nutsTight != nutsTight;
}

// ============================================================================
// 7 The tree by the line
// ============================================================================

@immutable
class M4TreeGeo {
  const M4TreeGeo(this.h);
  final double h;

  double get groundY => h - 230;
  double get lineY => 200;
  static const trunkX = 286.0;
  Offset get branchBase => Offset(trunkX - 6, lineY + 70);
  Offset get branchTip => Offset(150, lineY + 16);
  Offset get cutAt => Offset(trunkX - 40, lineY + 62);
}

class M4TreePainter extends CustomPainter {
  const M4TreePainter({required this.geo, this.cordon = false, this.rope = false, this.cuts = 0});
  final M4TreeGeo geo;
  final bool cordon;
  final bool rope;
  final int cuts;

  @override
  void paint(Canvas canvas, Size size) {
    final g = geo;
    _backdrop(canvas, size, g.groundY);
    _pole(canvas, 54, g.lineY - 40, g.groundY + 6);
    _arm(canvas, 20, 90, g.lineY);
    for (var i = 0; i < 3; i++) {
      final y = g.lineY - 22 + i * 1.0;
      final x = 26.0 + i * 28;
      _pinInsulator(canvas, Offset(x, g.lineY - 4));
      canvas.drawPath(Path()..moveTo(x, y)..quadraticBezierTo(220, y + 18, 360, y + 6), _wire);
    }
    // The tree.
    final bark = Paint()..color = const Color(0xFF6B4A2E);
    canvas.drawPath(
      Path()
        ..moveTo(M4TreeGeo.trunkX - 16, g.groundY + 8)
        ..lineTo(M4TreeGeo.trunkX - 9, g.lineY - 40)
        ..lineTo(M4TreeGeo.trunkX + 9, g.lineY - 40)
        ..lineTo(M4TreeGeo.trunkX + 16, g.groundY + 8)
        ..close(),
      bark,
    );
    final leaf = Paint()..color = const Color(0xFF3E7D3A);
    final leaf2 = Paint()..color = const Color(0xFF5C9A4C);
    canvas.drawCircle(Offset(M4TreeGeo.trunkX + 10, g.lineY - 60), 50, leaf);
    canvas.drawCircle(Offset(M4TreeGeo.trunkX + 36, g.lineY - 20), 36, leaf2);
    // The branch that leans to the line — gone after the second cut.
    if (cuts < 2) {
      canvas.drawLine(g.branchBase, g.branchTip, bark..strokeWidth = 7);
      canvas.drawCircle(g.branchTip.translate(10, 4), 20, leaf2);
      canvas.drawCircle(g.branchTip.translate(34, 14), 16, leaf);
    } else {
      // The branch on the ground, lowered on the rope.
      canvas.drawLine(Offset(150, g.groundY + 46), Offset(250, g.groundY + 40), bark..strokeWidth = 6);
      canvas.drawCircle(Offset(156, g.groundY + 38), 14, leaf2);
      // The stub, finished at the collar after the third cut.
      final stubEnd = cuts >= 3 ? g.branchBase.translate(-6, -1) : g.cutAt.translate(-12, -2);
      canvas.drawLine(g.branchBase, stubEnd, bark..strokeWidth = 7);
    }
    if (cuts >= 1 && cuts < 2) {
      canvas.drawLine(g.cutAt.translate(-2, 4), g.cutAt.translate(2, 0), Paint()..color = const Color(0xFFF3E1B8)..strokeWidth = 2);
    }
    if (rope) {
      final over = Offset(M4TreeGeo.trunkX + 2, g.lineY - 34);
      final tie = cuts < 2 ? Offset.lerp(g.branchBase, g.branchTip, 0.45)! : Offset(200, g.groundY + 42);
      final rp = Paint()
        ..color = const Color(0xFFE2C27A)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(tie, over, rp);
      canvas.drawLine(over, Offset(M4TreeGeo.trunkX - 40, g.groundY + 10), rp);
    }
    if (cordon) {
      for (final x in const [104.0, 168.0, 232.0, 330.0]) {
        canvas.drawPath(
          Path()
            ..moveTo(x - 8, g.groundY + 70)
            ..lineTo(x, g.groundY + 46)
            ..lineTo(x + 8, g.groundY + 70)
            ..close(),
          Paint()..color = const Color(0xFFFF7A1A),
        );
      }
      canvas.drawLine(Offset(104, g.groundY + 52), Offset(330, g.groundY + 52), Paint()..color = const Color(0xFFFFD54F)..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(M4TreePainter old) => old.geo.h != geo.h || old.cordon != cordon || old.rope != rope || old.cuts != cuts;
}

// ============================================================================
// 8 The street light
// ============================================================================

@immutable
class M4StreetGeo {
  const M4StreetGeo(this.h);
  final double h;

  double get groundY => h - 230;
  static const postX = 262.0;
  double get headY => 196;
  Offset get head => const Offset(170, 0).translate(0, headY);
  Rect get mcb => Rect.fromLTWH(postX - 16, groundY - 132, 32, 40);
  Rect get mcbHit => mcb.inflate(12);
}

class M4StreetPainter extends CustomPainter {
  const M4StreetPainter({required this.geo, required this.mcbOn, required this.lit, required this.newLamp});
  final M4StreetGeo geo;
  final bool mcbOn;
  final bool lit;
  final bool newLamp;

  @override
  void paint(Canvas canvas, Size size) {
    final g = geo;
    _backdrop(canvas, size, g.groundY, dusk: true);
    // Road.
    canvas.drawRect(Rect.fromLTWH(0, g.groundY + 70, size.width, 60), Paint()..color = const Color(0xFF3A3F45));
    for (var x = 10.0; x < size.width; x += 50) {
      canvas.drawRect(Rect.fromLTWH(x, g.groundY + 98, 26, 3), Paint()..color = const Color(0xFFE8E2C8));
    }
    _pole(canvas, M4StreetGeo.postX, g.headY - 20, g.groundY + 8, w: 10);
    canvas.drawPath(
      Path()
        ..moveTo(M4StreetGeo.postX, g.headY - 14)
        ..quadraticBezierTo(M4StreetGeo.postX - 40, g.headY - 30, g.head.dx + 18, g.headY - 6),
      Paint()
        ..color = const Color(0xFF8E9399)
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke,
    );
    if (lit) {
      canvas.drawPath(
        Path()
          ..moveTo(g.head.dx - 14, g.headY + 6)
          ..lineTo(g.head.dx - 90, g.groundY + 70)
          ..lineTo(g.head.dx + 90, g.groundY + 70)
          ..lineTo(g.head.dx + 14, g.headY + 6)
          ..close(),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x99FFE8A0), Color(0x00FFE8A0)],
          ).createShader(Rect.fromLTWH(g.head.dx - 90, g.headY, 180, g.groundY - g.headY + 70)),
      );
    }
    final head = RRect.fromRectAndRadius(Rect.fromCenter(center: g.head, width: 54, height: 16), const Radius.circular(8));
    canvas.drawRRect(head, Paint()..color = const Color(0xFF5A6068));
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: g.head.translate(0, 7), width: 40, height: 6), const Radius.circular(3)),
      Paint()..color = lit ? const Color(0xFFFFF4C2) : (newLamp ? const Color(0xFFD8D8D0) : const Color(0xFF3E3A33)),
    );
    // Photocell on top.
    canvas.drawCircle(g.head.translate(10, -10), 4, Paint()..color = const Color(0xFF8E9399));
    // MCB box on the post.
    final b = g.mcb;
    canvas.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(3)), Paint()..color = const Color(0xFF9AA4AE));
    final lever = Rect.fromLTWH(b.left + 9, b.top + 10, 14, 18);
    canvas.drawRRect(RRect.fromRectAndRadius(lever, const Radius.circular(2)), Paint()..color = const Color(0xFF26303D));
    canvas.drawRect(
      Rect.fromLTWH(lever.left + 2, mcbOn ? lever.top + 2 : lever.bottom - 9, lever.width - 4, 7),
      Paint()..color = mcbOn ? const Color(0xFFC62828) : const Color(0xFF2E7D32),
    );
    _label(canvas, 'MCB', Offset(b.center.dx, b.top + 5), 6, const Color(0xFF26303D));
    _label(canvas, mcbOn ? 'ON' : 'OFF', Offset(b.center.dx, b.bottom - 5), 6, mcbOn ? const Color(0xFFC62828) : const Color(0xFF1B5E20));
    // Ladder against the post.
    final lad = Paint()
      ..color = const Color(0xFFB0B6BC)
      ..strokeWidth = 3;
    canvas.drawLine(Offset(M4StreetGeo.postX - 52, g.groundY + 6), Offset(M4StreetGeo.postX - 14, g.headY + 20), lad);
    canvas.drawLine(Offset(M4StreetGeo.postX - 36, g.groundY + 6), Offset(M4StreetGeo.postX + 2, g.headY + 20), lad);
    for (var k = 1; k < 12; k++) {
      final t = k / 12;
      final a = Offset.lerp(Offset(M4StreetGeo.postX - 52, g.groundY + 6), Offset(M4StreetGeo.postX - 14, g.headY + 20), t)!;
      canvas.drawLine(a, a.translate(16, 0), lad..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(M4StreetPainter old) => old.geo.h != geo.h || old.mcbOn != mcbOn || old.lit != lit || old.newLamp != newLamp;
}

// ============================================================================
// 9 The LT feeder pillar
// ============================================================================

@immutable
class M4PillarGeo {
  const M4PillarGeo(this.h);
  final double h;

  double get groundY => h - 230;
  Rect get box => Rect.fromLTWH(56, 170, 248, math.max(220, groundY - 250));
  static const names = ['R', 'Y', 'B', 'N'];
  double cableX(int i) => box.left + 44 + i * 54;
  Offset clampAt(int i) => Offset(cableX(i), box.top + box.height * 0.62);
  Rect cableHit(int i) => Rect.fromCenter(center: clampAt(i), width: 50, height: 110);
}

class M4PillarPainter extends CustomPainter {
  const M4PillarPainter({required this.geo, this.clampOn});
  final M4PillarGeo geo;
  final int? clampOn;

  @override
  void paint(Canvas canvas, Size size) {
    final g = geo;
    _backdrop(canvas, size, g.groundY);
    final b = g.box;
    canvas.drawRect(Rect.fromLTWH(b.left - 10, b.bottom, b.width + 20, 14), Paint()..color = const Color(0xFF9E9E9E));
    canvas.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(6)), Paint()..color = const Color(0xFF6E7F8C));
    final inner = b.deflate(10);
    canvas.drawRRect(RRect.fromRectAndRadius(inner, const Radius.circular(4)), Paint()..color = const Color(0xFF243140));
    // Open door.
    canvas.drawPath(
      Path()
        ..moveTo(b.right, b.top)
        ..lineTo(b.right + 40, b.top + 18)
        ..lineTo(b.right + 40, b.bottom - 18)
        ..lineTo(b.right, b.bottom)
        ..close(),
      Paint()..color = const Color(0xFF5B6B77),
    );
    _bnLabel(canvas, 'ফিডার পিলার', Offset(b.center.dx, b.top - 12), 11, const Color(0xFFF7F3EA));
    const cols = [Color(0xFFD7312B), Color(0xFFF2C40F), Color(0xFF2A62C9), Color(0xFF1B1E22)];
    for (var i = 0; i < 4; i++) {
      final x = g.cableX(i);
      // Busbar stub and the outgoing cable.
      canvas.drawRect(Rect.fromLTWH(x - 18, inner.top + 18, 36, 8), Paint()..color = const Color(0xFFC08A3E));
      canvas.drawLine(
        Offset(x, inner.top + 26),
        Offset(x, inner.bottom + 20),
        Paint()
          ..color = cols[i]
          ..strokeWidth = 9,
      );
      _label(canvas, M4PillarGeo.names[i], Offset(x, inner.top + 40), 12, Colors.white);
    }
    final on = clampOn;
    if (on != null) {
      final p = g.clampAt(on);
      canvas.drawOval(
        Rect.fromCenter(center: p, width: 30, height: 26),
        Paint()
          ..color = const Color(0xFF222428)
          ..strokeWidth = 5
          ..style = PaintingStyle.stroke,
      );
      canvas.drawLine(p.translate(0, 13), p.translate(0, 40), Paint()..color = const Color(0xFFD9542B)..strokeWidth = 8);
    }
  }

  @override
  bool shouldRepaint(M4PillarPainter old) => old.geo.h != geo.h || old.clampOn != clampOn;
}
