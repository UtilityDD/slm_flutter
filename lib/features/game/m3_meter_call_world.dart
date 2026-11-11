import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The site of "গ্রাহকের ডাক" (lesson 3.8 সার্ভিস কেবিল ও এনার্জি মিটার, কাজ 2):
// a drawn, layered village lane — the sky, a far tree line, the LT line on a
// PCC pole (R Y B N), the service (drop) cable from the pole to the house,
// tied along its bearer wire, with a U drip loop before it enters the meter
// box (lesson point 1, pro tips 1–2); on the wall the meter box: the static
// energy meter (LCD, kWh) with the company seal, and under it the terminal
// block (P N in, P N out); a window into the house (the load) and the
// customer at the door. The only words in the art are the ones a worker
// reads: the terminal letters, IN/OUT, kWh.
//
// Design: 360 wide × the scene's height; the ground row follows the bottom of
// the screen (a tall phone gets more sky).

/// The places the trainee can look at on a call.
enum M3MeterCallSpot { line, cable, meter, house }

/// The meter's terminals (phase and neutral, in and out).
enum M3MeterCallTerm { pIn, nIn, pOut, nOut }

/// What the window shows (the house's load).
enum M3MeterCallRoom { lamp, fridge, leak, burnt }

String m3MeterCallTermLabel(M3MeterCallTerm t) => switch (t) {
      M3MeterCallTerm.pIn || M3MeterCallTerm.pOut => 'P',
      M3MeterCallTerm.nIn || M3MeterCallTerm.nOut => 'N',
    };

/// Where things stand (design px, 360 wide).
@immutable
class M3MeterCallGeo {
  const M3MeterCallGeo({required this.height, required this.groundY});

  factory M3MeterCallGeo.forScene(double h, double inset) => M3MeterCallGeo(height: h, groundY: (h - 300 - inset).clamp(360.0, 700.0));

  final double height;
  final double groundY;

  /// The pole top and the LT line.
  double get top => math.max(40, groundY - 420);
  double wireY(int i) => top + 14 + i * 12;

  /// The neutral is the lowest wire.
  double get neutralY => wireY(3);
  static const poleX = 28.0;

  /// The house's parapet (flat roof).
  double get roofY => top + 72;
  Rect get wall => Rect.fromLTRB(166, roofY, 372, groundY + 2);

  /// The window into the house (the load).
  Rect get window => Rect.fromLTWH(228, roofY + 18, 114, 62);

  /// The meter box on the wall.
  Rect get box => Rect.fromLTWH(178, math.max(groundY - 250, roofY + 92), 176, 128);

  /// The meter in the box (upper part).
  Rect get meter => Rect.fromLTWH(box.left + 30, box.top + 8, 116, 66);

  /// The company seal (on the meter cover's right edge).
  Offset get seal => Offset(meter.right - 6, meter.bottom - 10);

  /// The terminal row in the box.
  double get termY => box.top + 102;
  static const _tx = {M3MeterCallTerm.pIn: 200.0, M3MeterCallTerm.nIn: 244.0, M3MeterCallTerm.pOut: 288.0, M3MeterCallTerm.nOut: 332.0};
  Offset terminal(M3MeterCallTerm t) => Offset(_tx[t]!, termY);

  /// Where a tap reaches a terminal (44 × 60 design px ≈ 48 × 65 dp).
  Rect terminalHit(M3MeterCallTerm t) => Rect.fromCenter(center: terminal(t), width: 44, height: 60);

  /// The bearer hook on the wall and the drop's entry under the box.
  Offset get hook => Offset(172, roofY + 14);
  Offset get poleEnd => Offset(poleX + 6, neutralY + 10);
  Offset get entry => Offset(box.left + 18, box.bottom);

  /// The door and the customer.
  Rect get door => Rect.fromLTWH(296, box.bottom + 16, 52, groundY - box.bottom - 16);

  /// Tap zones for the four spots.
  Rect spotHit(M3MeterCallSpot s) => switch (s) {
        M3MeterCallSpot.line => Rect.fromLTRB(0, top - 10, 360, neutralY + 8),
        M3MeterCallSpot.cable => Rect.fromLTRB(44, neutralY + 10, 166, roofY + 50),
        M3MeterCallSpot.meter => box.inflate(4),
        M3MeterCallSpot.house => window.inflate(6),
      };

  /// Where each spot's finding tag hangs (its top-left).
  /// The line's tag goes left of a cut over the house.
  Offset tagAt(M3MeterCallSpot s, {bool breakRight = false}) => switch (s) {
        M3MeterCallSpot.line => Offset(breakRight ? 40 : 150, neutralY + 8),
        M3MeterCallSpot.cable => Offset(40, roofY + 46),
        M3MeterCallSpot.meter => Offset(box.left - 6, box.bottom + 4),
        M3MeterCallSpot.house => Offset(window.left - 4, window.bottom + 2),
      };

  /// Where the broken neutral's ends hang ([right]: the span over the house).
  double breakX(bool right) => right ? 262 : 104;

  /// The trainee's box (feet on the ground, left of the house).
  Rect get trainee => Rect.fromLTWH(54, groundY - 200, 100, 200);

  @override
  bool operator ==(Object other) => other is M3MeterCallGeo && other.height == height && other.groundY == groundY;

  @override
  int get hashCode => Object.hash(height, groundY);
}

/// The lane, the LT line and pole, the drop cable, the house with its meter
/// box, window and customer. [looked]: spots inspected (a soft ring, red when
/// that is where the fault is); [hot]: a loose terminal shown hot (after the
/// meter was looked at); [fixed]: it was tightened; [neutralBreak]: the LT
/// neutral is broken there (null = whole).
class M3MeterCallWorldPainter extends CustomPainter {
  const M3MeterCallWorldPainter({
    required this.geo,
    required this.room,
    required this.look,
    this.looked = const {},
    this.fault,
    this.hot,
    this.fixed = false,
    this.neutralBreak,
    this.selected,
  });

  final M3MeterCallGeo geo;
  final M3MeterCallRoom room;

  /// The house's colours (0–2).
  final int look;
  final Set<M3MeterCallSpot> looked;
  final M3MeterCallSpot? fault;
  final M3MeterCallTerm? hot;
  final bool fixed;
  final double? neutralBreak;

  /// A terminal the tool is on now.
  final M3MeterCallTerm? selected;

  static const _walls = [
    [Color(0xFFE8D9B8), Color(0xFFCDB991)],
    [Color(0xFFD7E2D0), Color(0xFFB4C4A9)],
    [Color(0xFFEBD3C4), Color(0xFFCFAE98)],
  ];

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final g = geo.groundY;
    final hz = g - 110;
    // Sky (morning).
    c.drawRect(
        Rect.fromLTWH(0, 0, w, hz + 4),
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3F79AE), Color(0xFF8DB9D9), Color(0xFFE9E6CF)])
              .createShader(Rect.fromLTWH(0, 0, w, hz + 4)));
    final cloud = Paint()..color = const Color(0x55FFFFFF);
    for (final (x, y, r) in [(90.0, geo.top + 130, 20.0), (116.0, geo.top + 124, 26.0), (146.0, geo.top + 134, 18.0)]) {
      c.drawCircle(Offset(x, y), r, cloud);
    }
    // Far tree line.
    final far = Path()..moveTo(0, hz);
    for (var x = 0.0; x <= w; x += 18) {
      far.lineTo(x, hz - 16 - 10 * math.sin(x * 0.06) - 5 * math.cos(x * 0.21));
    }
    far
      ..lineTo(w, hz + 2)
      ..lineTo(0, hz + 2)
      ..close();
    c.drawPath(far, Paint()..color = const Color(0xFF4F7A55));
    c.drawRect(Rect.fromLTWH(0, hz, w, g - hz),
        Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF86A75E), Color(0xFF5E7F43)]).createShader(Rect.fromLTWH(0, hz, w, g - hz)));
    // The lane to the bottom.
    c.drawRect(Rect.fromLTWH(0, g, w, size.height - g),
        Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFB59B74), Color(0xFF8C7556)]).createShader(Rect.fromLTWH(0, g, w, size.height - g)));
    final pebble = Paint()..color = const Color(0x33000000);
    final rnd = math.Random(5);
    for (var i = 0; i < 24; i++) {
      c.drawCircle(Offset(rnd.nextDouble() * w, g + 6 + rnd.nextDouble() * (size.height - g - 10)), 1.2 + rnd.nextDouble() * 1.6, pebble);
    }

    _house(c);
    _pole(c);
    _drop(c);
    _box(c);
    _rings(c);
  }

  void _pole(Canvas c) {
    final g = geo.groundY;
    final top = geo.top;
    const px = M3MeterCallGeo.poleX;
    // The PCC pole.
    final pole = Path()
      ..moveTo(px - 6, top - 8)
      ..lineTo(px + 6, top - 8)
      ..lineTo(px + 10, g + 4)
      ..lineTo(px - 10, g + 4)
      ..close();
    c.drawPath(pole, Paint()..shader = const LinearGradient(colors: [Color(0xFFB9B9B2), Color(0xFF8D8D86)]).createShader(Rect.fromLTRB(px - 10, top, px + 10, g)));
    c.drawOval(Rect.fromCenter(center: Offset(px, g + 4), width: 42, height: 8), Paint()..color = const Color(0x33000000));
    // The LT line: R Y B, then N lowest, on shackles.
    const cols = [Color(0xFF2A2F36), Color(0xFF2A2F36), Color(0xFF2A2F36), Color(0xFF1A1D22)];
    for (var i = 0; i < 4; i++) {
      final y = geo.wireY(i);
      final p = Paint()
        ..color = cols[i]
        ..strokeWidth = i == 3 ? 1.8 : 1.4
        ..style = PaintingStyle.stroke;
      final nb = neutralBreak;
      if (i == 3 && nb != null) {
        // Broken: two ends hang down from the gap.
        c.drawPath(
            Path()
              ..moveTo(0, y + 8)
              ..quadraticBezierTo(px / 2, y + 10, px, y)
              ..quadraticBezierTo((px + nb - 8) / 2, y + 12, nb - 8, y + 6)
              ..quadraticBezierTo(nb - 6, y + 20, nb - 12, y + 34),
            p);
        c.drawPath(
            Path()
              ..moveTo(360, y + 10)
              ..quadraticBezierTo((360 + nb + 8) / 2, y + 16, nb + 8, y + 6)
              ..quadraticBezierTo(nb + 6, y + 22, nb + 14, y + 38),
            p);
      } else {
        c.drawPath(
            Path()
              ..moveTo(0, y + 8)
              ..quadraticBezierTo(px / 2, y + 10, px, y)
              ..quadraticBezierTo(190, y + 16, 360, y + 10),
            p);
      }
    }
    // Cross-arm and shackles.
    c.drawRect(Rect.fromLTWH(px - 14, top + 6, 30, 5), Paint()..color = const Color(0xFF4A4F57));
    final shackle = Paint()..color = const Color(0xFFF2F0E8);
    for (var i = 0; i < 4; i++) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(px + 7, geo.wireY(i) - 5, 7, 10), const Radius.circular(3)), shackle);
    }
  }

  void _drop(Canvas c) {
    // The bearer wire (GI) from the pole to the hook on the wall: it takes
    // the pull; the twin-core drop is tied along it.
    final a = geo.poleEnd;
    final h = geo.hook;
    final mid = Offset((a.dx + h.dx) / 2, math.max(a.dy, h.dy) + 22);
    c.drawPath(
        Path()
          ..moveTo(a.dx, a.dy)
          ..quadraticBezierTo(mid.dx, mid.dy, h.dx, h.dy),
        Paint()
          ..color = const Color(0xFF8F969E)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke);
    final cable = Paint()
      ..color = const Color(0xFF15181C)
      ..strokeWidth = 3.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final e = geo.entry;
    final loopBottom = e.dy + 26;
    c.drawPath(
        Path()
          ..moveTo(a.dx, a.dy + 3)
          ..quadraticBezierTo(mid.dx, mid.dy + 3, h.dx, h.dy + 3)
          // Down the wall, the U drip loop, up into the box.
          ..lineTo(h.dx - 2, loopBottom - 14)
          ..quadraticBezierTo(h.dx - 2, loopBottom, (h.dx + e.dx) / 2, loopBottom)
          ..quadraticBezierTo(e.dx, loopBottom, e.dx, e.dy),
        cable);
    // Ties along the bearer.
    final tie = Paint()
      ..color = const Color(0xFFD9D4C7)
      ..strokeWidth = 1.4;
    for (final t in [0.25, 0.5, 0.75]) {
      final p = _quad(a, mid, h, t);
      c.drawLine(p + const Offset(0, -2), p + const Offset(0, 5), tie);
    }
    // The hook.
    c.drawCircle(h, 3, Paint()..color = const Color(0xFF5A5F66));
  }

  static Offset _quad(Offset a, Offset b, Offset c, double t) => a * ((1 - t) * (1 - t)) + b * (2 * (1 - t) * t) + c * (t * t);

  void _house(Canvas c) {
    final wall = geo.wall;
    final cols = _walls[look % _walls.length];
    c.drawRect(wall, Paint()..shader = LinearGradient(colors: cols).createShader(wall));
    // Parapet.
    c.drawRect(Rect.fromLTRB(wall.left - 6, wall.top - 10, 372, wall.top + 4), Paint()..color = const Color(0xFF8E7F68));
    // Plinth.
    c.drawRect(Rect.fromLTRB(wall.left, geo.groundY - 10, 372, geo.groundY + 2), Paint()..color = const Color(0xFF9C8A6A));
    _window(c);
    _door(c);
  }

  void _window(Canvas c) {
    final r = geo.window;
    // Inside the room: dim.
    c.drawRect(r, Paint()..color = const Color(0xFF3B4650));
    final floor = r.bottom - 10;
    switch (room) {
      case M3MeterCallRoom.lamp:
        // A ceiling lamp with flicker marks.
        final b = Offset(r.center.dx, r.top + 22);
        c.drawLine(Offset(b.dx, r.top), Offset(b.dx, b.dy - 7), Paint()
          ..color = const Color(0xFF1A1D22)
          ..strokeWidth = 1.5);
        c.drawCircle(b, 9, Paint()..color = const Color(0xFFFFE89A));
        final ray = Paint()
          ..color = const Color(0xCCFFE89A)
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round;
        for (final a in [-2.6, -2.0, -1.1, -0.5, 0.0, 3.14]) {
          final d = Offset(math.cos(a), math.sin(a) + 0.6);
          c.drawLine(b + d * 13, b + d * 19, ray);
        }
        c.drawRect(Rect.fromLTWH(r.left + 8, floor - 18, 30, 18), Paint()..color = const Color(0xFF7A5A3C)); // a table
      case M3MeterCallRoom.fridge:
        // An old fridge, rusty at the base.
        final f = Rect.fromLTWH(r.left + 14, r.top + 8, 30, r.height - 10);
        c.drawRRect(RRect.fromRectAndRadius(f, const Radius.circular(4)), Paint()..color = const Color(0xFFE6E2D6));
        c.drawLine(Offset(f.left, f.top + 18), Offset(f.right, f.top + 18), Paint()
          ..color = const Color(0xFF9A9486)
          ..strokeWidth = 1);
        c.drawRect(Rect.fromLTWH(f.left, f.bottom - 8, f.width, 8), Paint()..color = const Color(0xFF9A5B2E));
        c.drawRect(Rect.fromLTWH(f.right - 6, f.top + 22, 2, 10), Paint()..color = const Color(0xFF6E6A60));
        c.drawRect(Rect.fromLTWH(r.left + 60, floor - 16, 40, 16), Paint()..color = const Color(0xFF7A5A3C));
      case M3MeterCallRoom.leak:
        // A damp patch round a switchboard on the inside wall.
        final sb = Rect.fromLTWH(r.center.dx - 12, r.top + 16, 24, 18);
        c.drawOval(sb.inflate(14), Paint()..color = const Color(0x553A6B8C));
        c.drawRRect(RRect.fromRectAndRadius(sb, const Radius.circular(2)), Paint()..color = const Color(0xFFEDEDE6));
        for (final dx in [-6.0, 0.0, 6.0]) {
          c.drawRect(Rect.fromLTWH(sb.center.dx + dx - 1.5, sb.top + 5, 3, 6), Paint()..color = const Color(0xFF6E6A60));
        }
        final drip = Paint()..color = const Color(0x993A6B8C);
        for (final dx in [-16.0, 14.0]) {
          c.drawOval(Rect.fromCenter(center: Offset(sb.center.dx + dx, sb.bottom + 10), width: 4, height: 6), drip);
        }
        c.drawRect(Rect.fromLTWH(r.left + 8, floor - 16, 34, 16), Paint()..color = const Color(0xFF7A5A3C));
      case M3MeterCallRoom.burnt:
        // A TV with a scorch and smoke, a fan blade blackened.
        final tv = Rect.fromLTWH(r.left + 12, r.top + 18, 40, 28);
        c.drawRect(tv, Paint()..color = const Color(0xFF1C1F24));
        c.drawOval(Rect.fromLTWH(tv.left + 12, tv.top + 2, 22, 18), Paint()..color = const Color(0xFF3A2A1E));
        final smoke = Paint()..color = const Color(0x66C9C9C9);
        c.drawCircle(Offset(tv.center.dx + 4, tv.top - 4), 6, smoke);
        c.drawCircle(Offset(tv.center.dx + 10, tv.top - 12), 5, smoke);
        c.drawRect(Rect.fromLTWH(tv.left - 2, tv.bottom, tv.width + 4, floor - tv.bottom), Paint()..color = const Color(0xFF7A5A3C));
        final fan = Offset(r.right - 28, r.top + 14);
        final blade = Paint()
          ..color = const Color(0xFF2B2B2B)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round;
        c.drawLine(fan - const Offset(16, -2), fan + const Offset(16, 2), blade);
        c.drawCircle(fan, 4, Paint()..color = const Color(0xFF4A4A4A));
    }
    // Frame and bars.
    final frame = Paint()
      ..color = const Color(0xFF5A4636)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    c.drawRect(r, frame);
    final bar = Paint()
      ..color = const Color(0xFF5A4636)
      ..strokeWidth = 1.6;
    for (var i = 1; i < 5; i++) {
      final x = r.left + r.width * i / 5;
      c.drawLine(Offset(x, r.top), Offset(x, r.bottom), bar);
    }
  }

  void _door(Canvas c) {
    final d = geo.door;
    if (d.height < 40) return;
    c.drawRect(d, Paint()..color = const Color(0xFF2E2620));
    // The customer in the doorway (a simple figure: kurta, head).
    final cx = d.center.dx;
    final feet = d.bottom - 2;
    final h = math.min(96.0, d.height - 6);
    final body = Paint()..color = look.isEven ? const Color(0xFF6E8FB5) : const Color(0xFFB56E6E);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 12, feet - h * 0.74, 24, h * 0.5), const Radius.circular(8)), body);
    c.drawRect(Rect.fromLTWH(cx - 9, feet - h * 0.26, 7, h * 0.26), Paint()..color = const Color(0xFFEDE6D6));
    c.drawRect(Rect.fromLTWH(cx + 2, feet - h * 0.26, 7, h * 0.26), Paint()..color = const Color(0xFFEDE6D6));
    c.drawCircle(Offset(cx, feet - h * 0.84), h * 0.11, Paint()..color = const Color(0xFF9B6B4A));
    c.drawArc(Rect.fromCircle(center: Offset(cx, feet - h * 0.86), radius: h * 0.11), math.pi, math.pi, true, Paint()..color = const Color(0xFF1E1A16));
    // The door leaf, open.
    c.drawPath(
        Path()
          ..moveTo(d.right, d.top)
          ..lineTo(d.right + 8, d.top + 6)
          ..lineTo(d.right + 8, d.bottom - 2)
          ..lineTo(d.right, d.bottom)
          ..close(),
        Paint()..color = const Color(0xFF7D5A3C));
    c.drawRect(d, Paint()
      ..color = const Color(0xFF5A4636)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
  }

  void _box(Canvas c) {
    final r = geo.box;
    c.drawRRect(RRect.fromRectAndRadius(r.shift(const Offset(3, 4)), const Radius.circular(6)), Paint()..color = const Color(0x44000000));
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(6)), Paint()..shader = const LinearGradient(colors: [Color(0xFF8E9AA3), Color(0xFF6D7880)]).createShader(r));
    final inner = r.deflate(6);
    c.drawRRect(RRect.fromRectAndRadius(inner, const Radius.circular(4)), Paint()..color = const Color(0xFF2F363C));
    // The meter: white case, LCD with kWh, the pulse LED, the seal.
    final m = geo.meter;
    c.drawRRect(RRect.fromRectAndRadius(m, const Radius.circular(6)), Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF4F4EE), Color(0xFFD9D9D0)]).createShader(m));
    final lcd = Rect.fromLTWH(m.left + 12, m.top + 10, m.width - 24, 24);
    c.drawRRect(RRect.fromRectAndRadius(lcd, const Radius.circular(3)), Paint()..color = const Color(0xFF9FB58A));
    _label(c, '04217.6', Offset(lcd.center.dx - 8, lcd.center.dy), 13, const Color(0xFF1E2A1A));
    _label(c, 'kWh', Offset(lcd.right - 14, lcd.center.dy + 4), 7, const Color(0xFF1E2A1A));
    c.drawCircle(Offset(m.left + 16, m.bottom - 14), 3, Paint()..color = const Color(0xFFD83A2E));
    _label(c, 'imp/kWh', Offset(m.left + 40, m.bottom - 14), 6, const Color(0xFF5A5F66));
    // The company seal: a wire through the cover screw, a red lead seal.
    final s = geo.seal;
    c.drawLine(s + const Offset(-10, -14), s, Paint()
      ..color = const Color(0xFF8F969E)
      ..strokeWidth = 1);
    c.drawCircle(s, 5.5, Paint()..color = const Color(0xFFB0302A));
    c.drawCircle(s, 2, Paint()..color = const Color(0xFF7A1E19));
    // The terminal block.
    final tb = Rect.fromLTRB(inner.left + 4, geo.termY - 16, inner.right - 4, geo.termY + 16);
    c.drawRRect(RRect.fromRectAndRadius(tb, const Radius.circular(4)), Paint()..color = const Color(0xFF15191D));
    _label(c, 'IN', Offset((geo.terminal(M3MeterCallTerm.pIn).dx + geo.terminal(M3MeterCallTerm.nIn).dx) / 2, tb.top - 6), 8, const Color(0xFFC9D1D8));
    _label(c, 'OUT', Offset((geo.terminal(M3MeterCallTerm.pOut).dx + geo.terminal(M3MeterCallTerm.nOut).dx) / 2, tb.top - 6), 8, const Color(0xFFC9D1D8));
    for (final t in M3MeterCallTerm.values) {
      final o = geo.terminal(t);
      final phase = t == M3MeterCallTerm.pIn || t == M3MeterCallTerm.pOut;
      // Its wire up into the meter.
      c.drawLine(Offset(o.dx, m.bottom), Offset(o.dx, o.dy - 8), Paint()
        ..color = phase ? const Color(0xFFD83A2E) : const Color(0xFF3A3F45)
        ..strokeWidth = 4);
      final isHot = hot == t && !fixed;
      if (isHot) {
        c.drawCircle(o, 15, Paint()..shader = const RadialGradient(colors: [Color(0xCCFF8A2A), Color(0x00FF5A1A)]).createShader(Rect.fromCircle(center: o, radius: 15)));
      }
      c.drawCircle(o, 9, Paint()..shader = RadialGradient(colors: isHot ? const [Color(0xFF8A5A2A), Color(0xFF4A2A12)] : const [Color(0xFFF6D98A), Color(0xFFB08A3A)]).createShader(Rect.fromCircle(center: o, radius: 9)));
      // The screw slot: a loose one sits crooked.
      final slot = Paint()
        ..color = const Color(0xFF3A2A10)
        ..strokeWidth = 2;
      final a = isHot ? 0.7 : 0.0;
      c.drawLine(o + Offset(-5 * math.cos(a), -5 * math.sin(a)), o + Offset(5 * math.cos(a), 5 * math.sin(a)), slot);
      if (selected == t) {
        c.drawCircle(o, 15, Paint()
          ..color = const Color(0xCCFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2);
      }
      _label(c, m3MeterCallTermLabel(t), Offset(o.dx, tb.bottom + 7), 9, const Color(0xFFF2F0E8));
    }
  }

  void _rings(Canvas c) {
    for (final s in looked) {
      final bad = s == fault;
      final r = switch (s) {
        M3MeterCallSpot.line => Rect.fromCircle(center: Offset(neutralBreak ?? 90, geo.neutralY), radius: 26),
        M3MeterCallSpot.cable => Rect.fromCircle(center: _quad(geo.poleEnd, Offset((geo.poleEnd.dx + geo.hook.dx) / 2, math.max(geo.poleEnd.dy, geo.hook.dy) + 22), geo.hook, 0.5), radius: 24),
        M3MeterCallSpot.meter => geo.box.inflate(3),
        M3MeterCallSpot.house => geo.window.inflate(4),
      };
      final p = Paint()
        ..color = bad ? const Color(0xE6FF5A4A) : const Color(0xCC7DE3A8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4;
      if (s == M3MeterCallSpot.line || s == M3MeterCallSpot.cable) {
        c.drawOval(r, p);
      } else {
        c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(8)), p);
      }
    }
  }

  static void _label(Canvas c, String t, Offset centre, double size, Color col) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: TextStyle(fontFamily: 'Roboto', fontSize: size, fontWeight: FontWeight.w900, color: col, letterSpacing: 0.5)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(M3MeterCallWorldPainter old) =>
      old.geo != geo ||
      old.room != room ||
      old.look != look ||
      !setEquals(old.looked, looked) ||
      old.fault != fault ||
      old.hot != hot ||
      old.fixed != fixed ||
      old.neutralBreak != neutralBreak ||
      old.selected != selected;
}

/// The tool in his hand at a terminal: an insulated screwdriver (orange
/// sleeve to the tip) or a plain one (bare metal shank).
class M3MeterCallToolPainter extends CustomPainter {
  const M3MeterCallToolPainter({required this.hand, required this.tip, required this.insulated});
  final Offset hand;
  final Offset tip;
  final bool insulated;

  @override
  void paint(Canvas c, Size size) {
    final d = tip - hand;
    final len = d.distance;
    if (len < 4) return;
    final u = d / len;
    final handleEnd = tip - u * 26;
    c.drawLine(handleEnd - u * 26, handleEnd, Paint()
      ..color = insulated ? const Color(0xFFE2631B) : const Color(0xFF6B4A2B)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round);
    c.drawLine(handleEnd, tip, Paint()
      ..color = insulated ? const Color(0xFFE2631B) : const Color(0xFFC9CED3)
      ..strokeWidth = insulated ? 4 : 3);
    c.drawLine(tip - u * 4, tip, Paint()
      ..color = const Color(0xFFD7DCE0)
      ..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(M3MeterCallToolPainter old) => old.hand != hand || old.tip != tip || old.insulated != insulated;
}

/// The flash (the deadly consequence, in colour over the grey scene): a
/// white flash, a blue-white arc, sparks. Non-graphic.
class M3MeterCallZapPainter extends CustomPainter {
  const M3MeterCallZapPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final flick = v < 0.5 ? (0.65 + 0.35 * math.sin(v * 60).abs()) : (1 - (v - 0.5) * 1.2).clamp(0.4, 1.0);
    final r = 24 + 44 * Curves.easeOut.transform(v.clamp(0.0, 1.0));
    c.drawCircle(at, r, Paint()..shader = RadialGradient(colors: [Color.fromRGBO(220, 235, 255, 0.95 * flick), const Color(0x002F6FD0)]).createShader(Rect.fromCircle(center: at, radius: r)));
    final rnd = math.Random(11);
    final arc = Path()..moveTo(at.dx - 26, at.dy);
    for (var i = 1; i <= 6; i++) {
      arc.lineTo(at.dx - 26 + i * 9, at.dy + (rnd.nextDouble() - 0.5) * 18);
    }
    c.drawPath(
        arc,
        Paint()
          ..color = Color.fromRGBO(255, 255, 255, flick)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke);
    final spark = Paint()
      ..color = Color.fromRGBO(255, 214, 90, (1 - v).clamp(0.0, 1.0))
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 14; i++) {
      final a = i / 14 * math.pi * 2 + 0.3;
      final d0 = 10 + 36 * v;
      c.drawLine(at + Offset(math.cos(a) * d0, math.sin(a) * d0), at + Offset(math.cos(a) * (d0 + 12), math.sin(a) * (d0 + 12)), spark);
    }
    final white = (1 - v * 4).clamp(0.0, 1.0);
    if (white > 0) c.drawRect(Offset.zero & size, Paint()..color = Color.fromRGBO(255, 255, 255, 0.8 * white));
  }

  @override
  bool shouldRepaint(M3MeterCallZapPainter old) => old.v != v || old.at != at;
}
