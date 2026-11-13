import 'dart:math' as math;

import 'package:flutter/material.dart';

// The drawn places of the Module 5 rank gate (m5_gate_case.dart): the van's
// open back at the feeder's start — the feeder map pinned inside, the notes
// sheet under it, the tailgate with the phone, the radio (mate chips) and the
// PTW clipboard — and the one close view up the pole. All in design pixels
// (360 wide, [M5Geo.h] high). Nothing on these pictures names a fault: a
// damaged part and a sound one are drawn with the same weight.

/// The fault's section and the map's places, as the painters need them.
@immutable
class M5MapPlan {
  const M5MapPlan({
    required this.night,
    required this.hasFpi,
    required this.wooded,
    required this.dtrs,
    required this.ugAt,
  });
  final bool night;
  final bool hasFpi;
  final Set<int> wooded;
  final Set<int> dtrs;
  final int ugAt;
}

/// What the map shows now (the player's own moves on it).
@immutable
class M5MapView {
  const M5MapView({
    this.fpiSeen = const {},
    this.pins = const {},
    this.tokenFrom,
    this.tokenTo,
    this.tokenT = 0,
    this.cordonAt,
    this.earthed = const {},
    this.upAt,
    this.lit = 0,
  });

  /// FPIs read: index → bright (true) or dark (false).
  final Map<int, bool> fpiSeen;

  /// Report pins: spot id ('s2', 'f1') → its number.
  final Map<String, int> pins;

  /// A crew on its way (map px) and how far (0 → 1).
  final Offset? tokenFrom;
  final Offset? tokenTo;
  final double tokenT;

  /// The rope ring round a fallen wire (section).
  final int? cordonAt;
  final Set<int> earthed;
  final int? upAt;

  /// Villages lighting up after the charge (0 → 1).
  final double lit;
}

/// Layout of the gate's scene (design px).
@immutable
class M5Geo {
  const M5Geo(this.h, this.inset);
  final double h;
  final double inset;

  static const sections = 4;

  /// The tailgate's top edge (the tools stand on it).
  double get tailTop => h - inset - 146;
  double get mapTop => 120;
  double get mapH => ((tailTop - mapTop - 14) * 0.6).clamp(150.0, 250.0);
  Rect get map => Rect.fromLTWH(8, mapTop, 344, mapH);
  Rect get notes => Rect.fromLTRB(8, map.bottom + 8, 352, tailTop - 8);

  /// The line across the map and the section ends along it.
  double get lineY => map.top + map.height * 0.44;
  double get lineX0 => map.left + 50;
  double get lineX1 => map.right - 14;
  double nodeX(int i) => lineX0 + (lineX1 - lineX0) * i / sections;
  double sectionX(int i) => (nodeX(i) + nodeX(i + 1)) / 2;
  Rect section(int i) => Rect.fromLTRB(nodeX(i) + 1, map.top + 16, nodeX(i + 1) - 1, map.bottom - 4);

  /// FPI i stands between section i and section i + 1.
  Offset fpiAt(int i) => Offset(nodeX(i + 1), lineY);
  Rect fpi(int i) => Rect.fromCenter(center: fpiAt(i) + const Offset(0, -2), width: 30, height: 30);
  Offset get substation => Offset(map.left + 26, lineY);
  Offset villageAt(int i) => Offset(sectionX(i), lineY + (map.bottom - lineY) * 0.52);

  // --- the tailgate --------------------------------------------------------
  Rect get tailgate => Rect.fromLTRB(0, tailTop, 360, h);
  // The right of the tailgate is where the guide stands (his bubble rises
  // over the top edge there): the tools keep left and low.
  Rect get phone => Rect.fromLTWH(8, tailTop + 34, 54, 100);
  Rect get radio => Rect.fromLTWH(68, tailTop + 76, 116, 60);
  Rect chip(int i) => Rect.fromLTWH(70 + i * 38.0, tailTop + 34, 36, 38);
  Rect get clipboard => Rect.fromLTWH(190, tailTop + 34, 60, 100);
  Rect get slip => Rect.fromLTWH(68, tailTop + 4, 64, 26);

  /// The four tools (the idle hint sweeps over them, the same for all).
  List<Rect> get tools => [phone, radio, clipboard, map.deflate(30)];

  // --- the close view up the pole --------------------------------------------
  double get armY => h * 0.48;

  /// The three insulators' x on the cross-arm, and where their tops are.
  static const insulatorX = [64.0, 180.0, 296.0];
  double get insulatorTop => armY - 10 - 46 * 1.5;

  Rect part(int i) => switch (i) {
        0 => Rect.fromCenter(center: Offset(64, armY - 44), width: 62, height: 88), // insulator L
        1 => Rect.fromCenter(center: Offset(180, armY - 44), width: 62, height: 88), // insulator M
        2 => Rect.fromCenter(center: Offset(296, armY - 44), width: 52, height: 88), // insulator R
        3 => Rect.fromCenter(center: Offset(122, armY + 12), width: 50, height: 44), // cross-arm
        4 => Rect.fromLTRB(324, armY - 70, 360, armY + 40), // jumper
        5 => Rect.fromLTRB(0, armY - 150, 70, armY - 90), // span (left)
        _ => Rect.fromLTRB(300, armY - 150, 360, armY - 90), // lead (right)
      };

  @override
  bool operator ==(Object other) => other is M5Geo && other.h == h && other.inset == inset;
  @override
  int get hashCode => Object.hash(h, inset);
}

// ============================================================================
// The van's open back (backdrop)
// ============================================================================

class M5BackdropPainter extends CustomPainter {
  const M5BackdropPainter({required this.geo, required this.night});
  final M5Geo geo;
  final bool night;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final w = 360.0;
    // Sky (seen round the open hatch).
    c.drawRect(
      Rect.fromLTWH(0, 0, w, g.h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: night ? const [Color(0xFF050B1C), Color(0xFF14213D)] : const [Color(0xFF5E9FD8), Color(0xFFBFDDF2)],
        ).createShader(Rect.fromLTWH(0, 0, w, g.h)),
    );
    if (night) {
      final star = Paint()..color = const Color(0xCCFFFFFF);
      final r = math.Random(7);
      for (var i = 0; i < 26; i++) {
        c.drawCircle(Offset(r.nextDouble() * w, r.nextDouble() * 110), 0.6 + r.nextDouble() * 0.8, star);
      }
      c.drawCircle(const Offset(300, 52), 13, Paint()..color = const Color(0xFFF4F1DE));
      c.drawCircle(const Offset(306, 47), 12, Paint()..color = const Color(0xFF0A1428));
    } else {
      c.drawCircle(const Offset(52, 40), 40, Paint()..color = const Color(0x33FFF4C2));
    }
    // Far poles of the feeder along the horizon.
    final far = Paint()
      ..color = night ? const Color(0xFF26334F) : const Color(0xFF6C8296)
      ..strokeWidth = 2;
    for (var x = 18.0; x < w; x += 58) {
      c.drawLine(Offset(x, 70), Offset(x, 112), far);
      c.drawLine(Offset(x - 8, 76), Offset(x + 8, 76), far);
    }
    c.drawLine(const Offset(0, 78), Offset(w, 74), far..strokeWidth = 1);
    // The van's open back: a dark frame round the map and the notes.
    final inside = Rect.fromLTRB(0, 108, w, g.tailTop + 4);
    c.drawRRect(
      RRect.fromRectAndCorners(inside, topLeft: const Radius.circular(18), topRight: const Radius.circular(18)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: night ? const [Color(0xFF1E2532), Color(0xFF2B3342)] : const [Color(0xFF39424F), Color(0xFF4A5462)],
        ).createShader(inside),
    );
    if (night) {
      // The dome light over the map.
      c.drawCircle(Offset(180, g.map.top + 20), 150, Paint()..color = const Color(0x1AFFE7A8));
    }
    // The tailgate: a ribbed metal bed.
    final t = g.tailgate;
    c.drawRect(
      t,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8A939E), Color(0xFF5B636D)],
        ).createShader(t),
    );
    c.drawRect(Rect.fromLTWH(0, t.top, w, 6), Paint()..color = const Color(0xFFB7BEC6));
    final rib = Paint()
      ..color = const Color(0x33000000)
      ..strokeWidth = 1.2;
    for (var x = 14.0; x < w; x += 22) {
      c.drawLine(Offset(x, t.top + 10), Offset(x, t.bottom), rib);
    }
  }

  @override
  bool shouldRepaint(M5BackdropPainter old) => old.geo != geo || old.night != night;
}

// ============================================================================
// The feeder map
// ============================================================================

class M5MapPainter extends CustomPainter {
  const M5MapPainter({required this.geo, required this.plan, required this.view});
  final M5Geo geo;
  final M5MapPlan plan;
  final M5MapView view;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final m = g.map;
    // The paper.
    c.drawRRect(RRect.fromRectAndRadius(m.shift(const Offset(0, 3)), const Radius.circular(6)), Paint()..color = const Color(0x66000000));
    c.drawRRect(RRect.fromRectAndRadius(m, const Radius.circular(6)), Paint()..color = const Color(0xFFF4EBD6));
    final grid = Paint()
      ..color = const Color(0x1A7A5C2E)
      ..strokeWidth = 0.6;
    for (var x = m.left + 16; x < m.right; x += 16) {
      c.drawLine(Offset(x, m.top + 4), Offset(x, m.bottom - 4), grid);
    }
    for (var y = m.top + 16; y < m.bottom; y += 16) {
      c.drawLine(Offset(m.left + 4, y), Offset(m.right - 4, y), grid);
    }
    c.drawRRect(
      RRect.fromRectAndRadius(m, const Radius.circular(6)),
      Paint()
        ..color = const Color(0xFFB08A4A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    // Pins at the top corners.
    for (final p in [Offset(m.left + 10, m.top + 8), Offset(m.right - 10, m.top + 8)]) {
      c.drawCircle(p, 4, Paint()..color = const Color(0xFFB23A2E));
    }
    final y = g.lineY;
    // The UG crossing: a road across the line, the cable dashed under it.
    final ux = g.sectionX(plan.ugAt);
    final road = Rect.fromLTRB(ux - 13, m.top + 4, ux + 13, m.bottom - 4);
    c.drawRect(road, Paint()..color = const Color(0xFFCFC4AE));
    final lane = Paint()
      ..color = const Color(0xFFF9F5EA)
      ..strokeWidth = 1.4;
    for (var yy = road.top + 4; yy < road.bottom; yy += 12) {
      c.drawLine(Offset(ux, yy), Offset(ux, yy + 6), lane);
    }
    // Trees (near the wooded sections, above the line).
    for (final i in plan.wooded) {
      final cx = g.sectionX(i);
      for (var k = -1; k <= 1; k++) {
        final p = Offset(cx + k * 15 + (k == 0 ? 0 : 3), y - 26 - (k.abs() * 4));
        c.drawRect(Rect.fromCenter(center: p + const Offset(0, 8), width: 2.4, height: 8), Paint()..color = const Color(0xFF6B4A2B));
        c.drawCircle(p, 7, Paint()..color = const Color(0xFF3F7D3A));
        c.drawCircle(p + const Offset(-3, -2), 4, Paint()..color = const Color(0xFF5C9B4F));
      }
    }
    // The line: solid overhead, dashed where it goes under the road.
    final wire = Paint()
      ..color = const Color(0xFF2C2A28)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(g.lineX0, y), Offset(road.left, y), wire);
    c.drawLine(Offset(road.right, y), Offset(g.lineX1, y), wire);
    final ug = Paint()
      ..color = const Color(0xFF2C2A28)
      ..strokeWidth = 2.2;
    for (var x = road.left; x < road.right; x += 6) {
      c.drawLine(Offset(x, y), Offset(math.min(x + 3, road.right), y), ug);
    }
    c.drawCircle(Offset(road.left, y), 2.6, Paint()..color = const Color(0xFF2C2A28));
    c.drawCircle(Offset(road.right, y), 2.6, Paint()..color = const Color(0xFF2C2A28));
    // Poles along it.
    final pole = Paint()..color = const Color(0xFF55504A);
    for (var x = g.lineX0 + 10; x < g.lineX1; x += 20) {
      if (x > road.left - 3 && x < road.right + 3) continue;
      c.drawCircle(Offset(x, y), 2.2, pole);
    }
    // Section ends.
    final tick = Paint()
      ..color = const Color(0xFF7A5C2E)
      ..strokeWidth = 1.2;
    for (var i = 1; i < M5Geo.sections; i++) {
      c.drawLine(Offset(g.nodeX(i), y + 8), Offset(g.nodeX(i), y + 15), tick);
    }
    // The substation.
    final ss = Rect.fromCenter(center: g.substation, width: 34, height: 30);
    c.drawRRect(RRect.fromRectAndRadius(ss, const Radius.circular(3)), Paint()..color = const Color(0xFF8D99A6));
    c.drawRRect(
      RRect.fromRectAndRadius(ss, const Radius.circular(3)),
      Paint()
        ..color = const Color(0xFF3D4651)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    for (var k = 0; k < 3; k++) {
      c.drawLine(Offset(ss.left + 8 + k * 9, ss.top + 6), Offset(ss.left + 8 + k * 9, ss.bottom - 6), Paint()..color = const Color(0xFF3D4651)..strokeWidth = 1.4);
    }
    c.drawLine(Offset(ss.right, y), Offset(g.lineX0, y), wire);
    // DTRs hanging below.
    for (final i in plan.dtrs) {
      final x = g.sectionX(i) + (i == plan.ugAt ? 24 : 0);
      c.drawLine(Offset(x, y), Offset(x, y + 9), Paint()..color = const Color(0xFF55504A)..strokeWidth = 1.2);
      c.drawRect(Rect.fromCenter(center: Offset(x, y + 14), width: 12, height: 10), Paint()..color = const Color(0xFF6E7B86));
    }
    // Villages: little houses (lit windows after the charge).
    for (var i = 0; i < M5Geo.sections; i++) {
      final v = g.villageAt(i) + Offset(i == plan.ugAt ? 22 : 0, -10);
      for (var k = 0; k < 3; k++) {
        final hx = v.dx - 12 + k * 12;
        final body = Rect.fromLTWH(hx - 4.5, v.dy - 4, 9, 7);
        c.drawRect(body, Paint()..color = const Color(0xFFA48A66));
        final roof = Path()
          ..moveTo(hx - 6, v.dy - 4)
          ..lineTo(hx, v.dy - 9)
          ..lineTo(hx + 6, v.dy - 4)
          ..close();
        c.drawPath(roof, Paint()..color = const Color(0xFF8A4B32));
        final lit = view.lit;
        c.drawRect(
          Rect.fromLTWH(hx - 1.6, v.dy - 2, 3.2, 3),
          Paint()..color = Color.lerp(const Color(0xFF3B3326), const Color(0xFFFFD34E), lit)!,
        );
        if (lit > 0) c.drawCircle(Offset(hx, v.dy - 1), 7 * lit, Paint()..color = Color.fromRGBO(255, 211, 78, 0.22 * lit));
      }
    }
    // FPIs (where dealt): a box on the line; once read, lit red or dark.
    if (plan.hasFpi) {
      for (var i = 0; i < M5Geo.sections - 1; i++) {
        final p = g.fpiAt(i) + const Offset(0, -12);
        final box = Rect.fromCenter(center: p, width: 13, height: 11);
        c.drawLine(p + const Offset(0, 5), Offset(p.dx, y), Paint()..color = const Color(0xFF3D4651)..strokeWidth = 1.1);
        c.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(2)), Paint()..color = const Color(0xFF3D4651));
        final seen = view.fpiSeen[i];
        final lamp = seen == null ? const Color(0xFF9AA3AD) : (seen ? const Color(0xFFFF3B30) : const Color(0xFF1C1C1C));
        if (seen == true) c.drawCircle(p, 9, Paint()..color = const Color(0x55FF3B30));
        c.drawCircle(p, 3.2, Paint()..color = lamp);
      }
    }
    // The rope ring round a fallen wire, earths, the crew up a pole.
    final cord = view.cordonAt;
    if (cord != null) {
      final cp = Offset(g.sectionX(cord), y + 6);
      final rope = Paint()
        ..color = const Color(0xFFD9341F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;
      const n = 22;
      for (var k = 0; k < n; k += 2) {
        c.drawArc(Rect.fromCircle(center: cp, radius: 22), k * 2 * math.pi / n, 2 * math.pi / n, false, rope);
      }
    }
    for (final i in view.earthed) {
      final p = Offset(g.sectionX(i) - 10, y);
      final e = Paint()
        ..color = const Color(0xFF2E7D32)
        ..strokeWidth = 1.6;
      c.drawLine(p, p + const Offset(0, 10), e);
      for (var k = 0; k < 3; k++) {
        c.drawLine(p + Offset(-5 + k * 1.6, 11 + k * 2.5), p + Offset(5 - k * 1.6, 11 + k * 2.5), e);
      }
    }
    final up = view.upAt;
    if (up != null) _crew(c, Offset(g.sectionX(up) + 10, y - 9), const Color(0xFFF2B632));
    // Report pins.
    view.pins.forEach((id, n) {
      final i = int.parse(id.substring(1));
      final at = id.startsWith('f') ? g.fpiAt(i) + const Offset(10, -24) : Offset(g.sectionX(i) + 14, y - 30);
      c.drawLine(at, at + const Offset(0, 9), Paint()..color = const Color(0xFF55504A)..strokeWidth = 1.2);
      c.drawCircle(at, 6.5, Paint()..color = const Color(0xFFB23A2E));
      _num(c, '$n', at);
    });
    // A crew on its way.
    final from = view.tokenFrom;
    final to = view.tokenTo;
    if (from != null && to != null && view.tokenT < 1) {
      final t = Curves.easeInOut.transform(view.tokenT.clamp(0.0, 1.0));
      _crew(c, Offset.lerp(from, to, t)!, const Color(0xFF1E88E5));
    }
  }

  void _crew(Canvas c, Offset p, Color col) {
    c.drawCircle(p, 6.5, Paint()..color = col);
    c.drawCircle(p, 6.5, Paint()..color = const Color(0xFFFFFFFF)..style = PaintingStyle.stroke..strokeWidth = 1.4);
    c.drawCircle(p + const Offset(0, -1.5), 2.2, Paint()..color = const Color(0xFFFFFFFF));
  }

  void _num(Canvas c, String s, Offset at) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFFFFFFFF))),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, at - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(M5MapPainter old) => old.geo != geo || old.plan != plan || old.view != view;
}

// ============================================================================
// The close view: the pole top (the only hands-on of the gate)
// ============================================================================

/// What a close-view part shows. A sound part may look worn (a look-alike).
enum M5Look { sound, worn, branch, puncture, carbon, bird, melted, annealed, clash, broken }

class M5PoleTopPainter extends CustomPainter {
  const M5PoleTopPainter({required this.geo, required this.night, required this.looks, required this.tagged});
  final M5Geo geo;
  final bool night;

  /// Part index (0–6) → how it looks.
  final Map<int, M5Look> looks;
  final Set<int> tagged;

  /// The close view is drawn this much larger than the map's world.
  static const z = 1.5;

  M5Look _l(int i) => looks[i] ?? M5Look.sound;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final y = g.armY;
    c.drawRect(
      Rect.fromLTWH(0, 0, 360, g.h),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: night ? const [Color(0xFF0B1630), Color(0xFF22324F)] : const [Color(0xFF6FA8DC), Color(0xFFD7E9F5)],
        ).createShader(Rect.fromLTWH(0, 0, 360, g.h)),
    );
    if (night) {
      // A headlamp's pool of light on the pole top.
      c.drawCircle(Offset(180, y - 30), 230, Paint()..color = const Color(0x22FFF2C4));
    }
    // The pole.
    final pole = Rect.fromLTRB(158, y - 90, 202, g.h);
    c.drawRect(
      pole,
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFF8E9399), Color(0xFFC3C7CC), Color(0xFF7D8287)]).createShader(pole),
    );
    // The cross-arm (part 3).
    final arm = Rect.fromLTRB(16, y - 10, 344, y + 14);
    c.drawRect(arm, Paint()..color = _l(3) == M5Look.worn ? const Color(0xFF6D6A5F) : const Color(0xFF4F5359));
    c.drawRect(Rect.fromLTRB(16, y - 10, 344, y - 6), Paint()..color = const Color(0x33FFFFFF));
    // Conductors from the insulator tops.
    final xs = M5Geo.insulatorX;
    final top = g.insulatorTop;
    _conductor(c, Offset(0, top - 40), Offset(xs[0], top), _l(5));
    c.drawLine(Offset(xs[1], top), Offset(xs[1] - 60, top - 120), _wire(M5Look.sound));
    _conductor(c, Offset(xs[2], top), Offset(360, top - 36), _l(6));
    for (var i = 0; i < 3; i++) {
      _insulator(c, Offset(xs[i], y - 10), _l(i));
    }
    // The jumper loop at the right (part 4).
    _jumper(c, Offset(xs[2] + 14, top + 4), _l(4));
    // The branch on the span (part 5).
    if (_l(5) == M5Look.branch) _branch(c, Offset(6, top - 54));
    // The bird on the cross-arm (part 3).
    if (_l(3) == M5Look.bird) _bird(c, Offset(122, y - 14));
    // Tags the player hung (his own moves).
    for (final i in tagged) {
      final r = g.part(i);
      _tag(c, Offset(r.right - 10, r.top + 8));
    }
  }

  Paint _wire(M5Look l) => Paint()
    ..color = switch (l) {
      M5Look.worn => const Color(0xFF8C8F93),
      M5Look.annealed => const Color(0xFF9A6B3F),
      _ => const Color(0xFF3A3D42),
    }
    ..strokeWidth = 4.2
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  void _conductor(Canvas c, Offset a, Offset b, M5Look l) {
    if (l == M5Look.broken) {
      // Two frayed ends hanging down.
      final mid = Offset.lerp(a, b, 0.5)!;
      final p1 = Path()
        ..moveTo(b.dx, b.dy)
        ..quadraticBezierTo(mid.dx + 12, mid.dy + 8, mid.dx + 8, mid.dy + 64);
      c.drawPath(p1, _wire(M5Look.sound));
      final p2 = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(a.dx + 12, a.dy + 14, a.dx + 6, a.dy + 70);
      c.drawPath(p2, _wire(M5Look.sound));
      for (final e in [Offset(mid.dx + 8, mid.dy + 64), Offset(a.dx + 6, a.dy + 70)]) {
        for (var k = -1; k <= 1; k++) {
          c.drawLine(e, e + Offset(k * 4.0, 7), Paint()..color = const Color(0xFF3A3D42)..strokeWidth = 1.6);
        }
      }
      return;
    }
    final sag = l == M5Look.clash || l == M5Look.annealed ? 22.0 : 8.0;
    final mid = Offset.lerp(a, b, 0.5)! + Offset(0, sag);
    final p = Path()
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo(mid.dx, mid.dy, b.dx, b.dy);
    if (l == M5Look.annealed) {
      c.drawPath(p, Paint()..color = const Color(0x553C6EB4)..strokeWidth = 8..style = PaintingStyle.stroke);
    }
    c.drawPath(p, _wire(l));
    if (l == M5Look.clash) {
      final burn = Paint()..color = const Color(0xFF111111);
      for (final t in [0.3, 0.48, 0.64]) {
        final q = Offset.lerp(a, b, t)! + Offset(0, sag * 0.9);
        c.drawCircle(q, 4.6, burn);
      }
    }
  }

  void _insulator(Canvas c, Offset base, M5Look l) {
    final body = switch (l) {
      M5Look.worn => const Color(0xFF9C8E7A),
      _ => const Color(0xFF8E4A2A),
    };
    c.drawRect(Rect.fromCenter(center: base + const Offset(0, -24 * z), width: 10 * z, height: 34 * z), Paint()..color = body);
    for (var k = 0; k < 3; k++) {
      final r = Rect.fromCenter(center: base + Offset(0, (-10 - k * 11.0) * z), width: (30 - k * 4.0) * z, height: 9 * z);
      c.drawOval(r, Paint()..color = body);
      c.drawOval(Rect.fromLTWH(r.left + 4, r.top + 1.5, r.width * 0.5, 4), Paint()..color = const Color(0x40FFFFFF));
    }
    if (l == M5Look.carbon) {
      final p = Path()
        ..moveTo(base.dx + 6, base.dy - 62)
        ..lineTo(base.dx + 13, base.dy - 42)
        ..lineTo(base.dx + 7, base.dy - 24)
        ..lineTo(base.dx + 15, base.dy - 6);
      c.drawPath(p, Paint()..color = const Color(0xFF121212)..strokeWidth = 4.5..style = PaintingStyle.stroke);
    }
    if (l == M5Look.puncture) {
      final crack = Paint()
        ..color = const Color(0xFFF2E6D8)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      final p = Path()
        ..moveTo(base.dx - 12, base.dy - 50)
        ..lineTo(base.dx - 3, base.dy - 39)
        ..lineTo(base.dx - 9, base.dy - 27)
        ..lineTo(base.dx + 3, base.dy - 15);
      c.drawPath(p, crack);
      c.drawPath(
        Path()
          ..moveTo(base.dx + 13, base.dy - 34)
          ..lineTo(base.dx + 22, base.dy - 31)
          ..lineTo(base.dx + 16, base.dy - 22)
          ..close(),
        Paint()..color = const Color(0xFFE9DCC9),
      );
    }
  }

  void _jumper(Canvas c, Offset a, M5Look l) {
    final p = Path()
      ..moveTo(a.dx, a.dy)
      ..cubicTo(a.dx + 40, a.dy + 24, a.dx + 44, a.dy + 78, a.dx - 4, a.dy + 86);
    c.drawPath(p, _wire(l == M5Look.worn ? M5Look.worn : M5Look.sound));
    final clamp = Rect.fromCenter(center: a + const Offset(32, 32), width: 22, height: 16);
    final col = switch (l) {
      M5Look.melted => const Color(0xFF1C1A18),
      M5Look.worn => const Color(0xFF8D8A84),
      _ => const Color(0xFFB9BEC4),
    };
    c.drawRRect(RRect.fromRectAndRadius(clamp, const Radius.circular(3)), Paint()..color = col);
    if (l == M5Look.melted) {
      c.drawOval(Rect.fromCenter(center: clamp.bottomCenter + const Offset(0, 6), width: 11, height: 12), Paint()..color = const Color(0xFF2A2522));
      c.drawCircle(clamp.center, 17, Paint()..color = const Color(0x33000000));
    }
  }

  void _branch(Canvas c, Offset at) {
    final wood = Paint()
      ..color = const Color(0xFF6B4A2B)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    c.drawLine(at, at + const Offset(58, 38), wood);
    c.drawLine(at + const Offset(24, 15), at + const Offset(18, -9), wood..strokeWidth = 3.4);
    c.drawLine(at + const Offset(42, 27), at + const Offset(58, 12), wood);
    for (final o in [const Offset(15, -12), const Offset(60, 9), const Offset(6, 3), const Offset(44, 0), const Offset(28, -2)]) {
      c.drawOval(Rect.fromCenter(center: at + o, width: 15, height: 9), Paint()..color = const Color(0xFF4E7D3A));
    }
  }

  void _bird(Canvas c, Offset at) {
    c.drawOval(Rect.fromCenter(center: at, width: 38, height: 17), Paint()..color = const Color(0xFF231F1C));
    c.drawCircle(at + const Offset(18, -6), 6.5, Paint()..color = const Color(0xFF231F1C));
    c.drawLine(at + const Offset(-14, 3), at + const Offset(-29, 12), Paint()..color = const Color(0xFF231F1C)..strokeWidth = 4.5);
    c.drawCircle(at, 24, Paint()..color = const Color(0x22000000));
  }

  void _tag(Canvas c, Offset at) {
    final r = RRect.fromRectAndRadius(Rect.fromCenter(center: at, width: 18, height: 15), const Radius.circular(3));
    c.drawRRect(r, Paint()..color = const Color(0xFFFFFFFF));
    c.drawRRect(r, Paint()..color = const Color(0xFF2E7D32)..style = PaintingStyle.stroke..strokeWidth = 1.6);
    final tick = Path()
      ..moveTo(at.dx - 5, at.dy)
      ..lineTo(at.dx - 1, at.dy + 4)
      ..lineTo(at.dx + 5, at.dy - 4);
    c.drawPath(tick, Paint()..color = const Color(0xFF2E7D32)..strokeWidth = 2..style = PaintingStyle.stroke);
  }

  @override
  bool shouldRepaint(M5PoleTopPainter old) =>
      old.geo != geo || old.night != night || old.looks.length != looks.length || !old.looks.entries.every((e) => looks[e.key] == e.value) || old.tagged.length != tagged.length;
}

// ============================================================================
// A deadly move playing out, in colour over the frozen grey scene
// ============================================================================

class M5HarmPainter extends CustomPainter {
  const M5HarmPainter({required this.at, required this.k});
  final Offset at;

  /// 0 → 1 over the consequence.
  final double k;

  @override
  void paint(Canvas c, Size size) {
    final t = k.clamp(0.0, 1.0);
    final glow = 30 + 90 * Curves.easeOut.transform(t);
    c.drawCircle(at, glow, Paint()..color = Color.fromRGBO(255, 170, 40, 0.35 * (1 - t * 0.6)));
    c.drawCircle(at, glow * 0.45, Paint()..color = Color.fromRGBO(255, 246, 200, 0.9 * (1 - t * 0.5)));
    final arc = Paint()
      ..color = const Color(0xFFBFE6FF)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;
    final r = math.Random(3);
    for (var i = 0; i < 7; i++) {
      final a = i * 2 * math.pi / 7 + t * 0.8;
      final p = Path()..moveTo(at.dx, at.dy);
      var q = at;
      for (var s = 1; s <= 4; s++) {
        final d = glow * 0.25 * s;
        q = at + Offset(math.cos(a) * d + (r.nextDouble() - 0.5) * 12, math.sin(a) * d + (r.nextDouble() - 0.5) * 12);
        p.lineTo(q.dx, q.dy);
      }
      c.drawPath(p, arc);
    }
    // Smoke rising after the flash.
    if (t > 0.4) {
      final s = (t - 0.4) / 0.6;
      for (var i = 0; i < 3; i++) {
        c.drawCircle(at + Offset(-10.0 + i * 10, -20 - 50 * s - i * 8), 10 + 10 * s, Paint()..color = Color.fromRGBO(60, 60, 60, 0.35 * (1 - s * 0.5)));
      }
    }
  }

  @override
  bool shouldRepaint(M5HarmPainter old) => old.at != at || old.k != k;
}
