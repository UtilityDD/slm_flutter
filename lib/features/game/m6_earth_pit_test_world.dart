import 'dart:math' as math;

import 'package:flutter/material.dart';

// The drawn world of lesson 6.11 কাজ "মাটির ভেতরে রক্ষক" (m6_earth_pit_test.dart):
// a new DTR on its plinth, not yet charged, in a field; the ground in front
// is cut away as a slab so the two earth pits show in section — one at each
// side of the plinth (lesson pro tip 1: double earthing from two separate
// pits). Each pit: a concrete chamber ring with its lid (or a bare hole when
// the contractor left none), the electrode standing in the soil with its
// record tag (a widget), the bottom joint (strip to electrode clamp) inside
// the chamber, the strip running under the ground to the top joint on the
// plinth's earth terminal. The soil shows its kind only by its look: moist
// dark loam, dry cracked loam under a pale sky, rocky with stones, or sandy
// (never named). Remedies show in the pit (wet soil, a grey bentonite ring, a
// second electrode). The earth tester stands on its case at the top right;
// the spare chamber ring and lid lie on a pallet at the top left.
//
// No text in the art except labels a worker reads (TEST on the tester, the
// terminal marks). Code-drawn, gradients, no bitmaps. Design: 360 wide × the
// scene's height; the floor follows the bottom of the screen.

/// The site's soil and weather (dealt; never named on screen).
enum M6Soil { loamWet, loamDry, rocky, sandy }

/// The soil gives a high earth resistance (lesson pro tip 3; dry weather,
/// section point 4) — a remedy is needed.
bool m6SoilHigh(M6Soil s) => s != M6Soil.loamWet;

/// The electrode in a pit (its record tag tells what it is).
enum M6Electrode { gi27, gi25, gi30, rod, short, bar }

/// Lesson 6.11 point 2: GI perforated pipe, usually 2.5–3 m, vertical.
bool m6ElectrodeGood(M6Electrode e) => e == M6Electrode.gi27 || e == M6Electrode.gi25 || e == M6Electrode.gi30;

/// The nut on a joint ([none]: the strip end is off its bolt).
enum M6Nut { brass, steel, iron, none }

/// The pit's chamber lid.
enum M6Lid { on, off, missing }

/// A remedy for a high reading (the tray always holds all four).
enum M6Remedy { water, bentonite, extra, gravel }

/// Where things are (design px, 360 wide).
@immutable
class M6PitGeo {
  const M6PitGeo._(this.height, this.floorY);

  factory M6PitGeo.forScene(double height, double inset) => M6PitGeo._(height, height - floorUp - inset * 0.5);

  final double height;

  /// The floor line (the action row stands below it).
  final double floorY;

  static const double floorUp = 96;

  /// The top of the working area (under the header).
  static const double top = 132;

  double get a => floorY - top;
  double y(double f) => top + f * a;

  /// The ground surface (the slab's top edge).
  double get gy => y(0.40);

  /// The two pits' centres (pit 0 left of the plinth, pit 1 right).
  static const List<double> pitX = [76, 284];

  /// The chamber in section (its inside).
  Rect chamber(int i) => Rect.fromLTRB(pitX[i] - 38, gy - 2, pitX[i] + 38, y(0.64));

  /// The lid on the chamber, and where it is grabbed.
  Rect lidOn(int i) => Rect.fromCenter(center: Offset(pitX[i], gy - 5), width: 92, height: 13);
  Rect lidOnHit(int i) => Rect.fromCenter(center: Offset(pitX[i], gy - 8), width: 100, height: 40);

  /// The lifted lid, standing on its edge behind the chamber's outer half.
  Rect lidOff(int i) => Rect.fromCenter(center: Offset(pitX[i] + (i == 0 ? -10 : 10), gy - 34), width: 66, height: 40);
  Rect lidOffHit(int i) => lidOff(i).inflate(4);

  /// The electrode's head (its top) and the bottom joint's clamp on it.
  double get headY => y(0.47);
  Offset joint1(int i) => Offset(pitX[i], y(0.53));

  /// The top joints: lead 0's and lead 1's earth terminals on the plinth.
  static const List<double> terminalX = [154, 206];
  Offset joint2(int lead) => Offset(terminalX[lead], y(0.31));

  static const double jointR = 22;
  Rect jointHit(Offset c) => Rect.fromCircle(center: c, radius: jointR);

  /// The circle swipe of the spanner: within this distance of the joint.
  static const double spannerReach = 50;

  /// The DTR on its plinth.
  Rect get plinth => Rect.fromLTRB(138, y(0.24), 222, gy);
  Rect get tank => Rect.fromLTRB(146, y(0.03), 214, y(0.24));

  /// The earth tester on its case, its display and its TEST button.
  Rect get tester => Rect.fromLTRB(262, y(0.02), 352, y(0.22));
  Rect get display => Rect.fromLTRB(270, y(0.06), 344, y(0.12));
  Offset get testBtn => Offset(307, y(0.17));
  Rect get testHit => Rect.fromCenter(center: testBtn, width: 60, height: (0.08 * a).clamp(30.0, 44.0));

  /// The spare chamber ring and lid on their pallet.
  Rect get spare => Rect.fromLTRB(6, y(0.03), 92, y(0.21));

  /// Where the trainee stands at pit [i] (between the pit and the plinth).
  Rect trainee(int i) => i == 0 ? Rect.fromLTWH(100, gy - 92, 38, 92) : Rect.fromLTWH(222, gy - 92, 38, 92);

  /// Where a deadly fault shows (the DTR's tank).
  Offset get flashAt => Offset(tank.center.dx, tank.top + tank.height * 0.6);

  @override
  bool operator ==(Object other) => other is M6PitGeo && other.height == height && other.floorY == floorY;

  @override
  int get hashCode => Object.hash(height, floorY);
}

/// One pit as drawn now.
@immutable
class M6PitLook {
  const M6PitLook({
    required this.exists,
    required this.lid,
    required this.electrode,
    required this.joint1,
    this.tight1 = true,
    this.wet = false,
    this.bentonite = false,
    this.extra = false,
    this.secondLead = false,
  });

  /// A pit has been dug here (false: bare ground with a peg).
  final bool exists;
  final M6Lid lid;
  final M6Electrode electrode;
  final M6Nut joint1;
  final bool tight1;
  final bool wet;
  final bool bentonite;
  final bool extra;

  /// The other lead is bolted in this pit too (both DTR earths in one pit).
  final bool secondLead;

  @override
  bool operator ==(Object other) =>
      other is M6PitLook &&
      other.exists == exists &&
      other.lid == lid &&
      other.electrode == electrode &&
      other.joint1 == joint1 &&
      other.tight1 == tight1 &&
      other.wet == wet &&
      other.bentonite == bentonite &&
      other.extra == extra &&
      other.secondLead == secondLead;

  @override
  int get hashCode => Object.hash(exists, lid, electrode, joint1, tight1, wet, bentonite, extra, secondLead);
}

/// What the scene shows now (everything but the spanner's turn).
@immutable
class M6PitRig {
  const M6PitRig({
    required this.soil,
    required this.pits,
    required this.joint2,
    required this.tight2,
    required this.current,
    required this.lead,
    this.spareUsed = false,
    this.leadsOn = false,
  });

  final M6Soil soil;
  final List<M6PitLook> pits;

  /// The top joints of lead 0 and lead 1.
  final List<M6Nut> joint2;
  final List<bool> tight2;

  /// The pit being looked at, and the lead whose earth it is.
  final int current;
  final int lead;
  final bool spareUsed;

  /// The tester's leads are clipped on the current pit's electrode.
  final bool leadsOn;

  @override
  bool operator ==(Object other) =>
      other is M6PitRig &&
      other.soil == soil &&
      _listEq(other.pits, pits) &&
      _listEq(other.joint2, joint2) &&
      _listEq(other.tight2, tight2) &&
      other.current == current &&
      other.lead == lead &&
      other.spareUsed == spareUsed &&
      other.leadsOn == leadsOn;

  @override
  int get hashCode => Object.hash(soil, Object.hashAll(pits), Object.hashAll(joint2), Object.hashAll(tight2), current, lead, spareUsed, leadsOn);
}

bool _listEq<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

void _label(Canvas c, String text, Offset centre, {double size = 6.5, Color color = const Color(0xFF26303D), FontWeight weight = FontWeight.w800}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: weight, color: color, letterSpacing: 0.3, height: 1.05)),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  )..layout(maxWidth: 120);
  tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
}

const _nutFill = {
  M6Nut.brass: [Color(0xFFF4D27A), Color(0xFFB8862E)],
  M6Nut.steel: [Color(0xFFF2F5F8), Color(0xFF9AA4AE)],
  M6Nut.iron: [Color(0xFF8A5A3A), Color(0xFF4A2A18)],
};

/// A hex nut at [o] (nothing for [M6Nut.none]); a loose one sits askew.
void m6PaintNut(Canvas c, Offset o, M6Nut nut, {double r = 7, bool tight = true}) {
  if (nut == M6Nut.none) return;
  final cols = _nutFill[nut]!;
  final hex = Path();
  final tilt = tight ? 0.0 : 0.35;
  for (var i = 0; i < 6; i++) {
    final a = math.pi / 6 + i * math.pi / 3 + tilt;
    final p = o + Offset(math.cos(a), math.sin(a)) * r;
    i == 0 ? hex.moveTo(p.dx, p.dy) : hex.lineTo(p.dx, p.dy);
  }
  hex.close();
  c.drawPath(hex, Paint()..shader = RadialGradient(center: const Alignment(-0.3, -0.3), colors: cols).createShader(Rect.fromCircle(center: o, radius: r)));
  c.drawPath(
      hex,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x88000000));
  c.drawCircle(o, r * 0.38, Paint()..color = const Color(0xFF3A3F45));
  if (nut == M6Nut.iron) {
    // Rust flecks.
    for (var i = 0; i < 4; i++) {
      final a = i * 1.7 + 0.4;
      c.drawCircle(o + Offset(math.cos(a), math.sin(a)) * r * 0.7, 1.4, Paint()..color = const Color(0xFFC0682C));
    }
  }
}

/// The site: sky, field, DTR, the cut-away ground with both pits, the
/// leads, the tester and the spare chamber set.
class M6PitWorldPainter extends CustomPainter {
  const M6PitWorldPainter({required this.geo, required this.rig});

  final M6PitGeo geo;
  final M6PitRig rig;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    final dry = rig.soil == M6Soil.loamDry;
    // Sky (paler and hazier in the dry season).
    final sky = Rect.fromLTWH(0, 0, w, g.gy);
    c.drawRect(
        sky,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: dry ? const [Color(0xFFE9D8B4), Color(0xFFF6EBD2)] : const [Color(0xFF7FB6E6), Color(0xFFCDE6F5)],
          ).createShader(sky));
    if (dry) c.drawCircle(Offset(w - 40, g.y(0.0) - 40), 22, Paint()..color = const Color(0x88FFF3C8));
    // Far trees and fields.
    final far = Path()..moveTo(0, g.gy - 30);
    for (var x = 0.0; x <= w + 20; x += 20) {
      far.quadraticBezierTo(x + 10, g.gy - 46 - (x % 60 == 0 ? 8 : 0), x + 20, g.gy - 30);
    }
    far
      ..lineTo(w, g.gy)
      ..lineTo(0, g.gy)
      ..close();
    c.drawPath(far, Paint()..color = dry ? const Color(0xFFA8A070) : const Color(0xFF6E9A5A));
    c.drawRect(Rect.fromLTRB(0, g.gy - 12, w, g.gy), Paint()..color = dry ? const Color(0xFFC9B07E) : const Color(0xFF7FA35E));
    _slab(c, size);
    _dtr(c);
    for (var i = 0; i < 2; i++) {
      _pit(c, i);
    }
    _leads(c);
    _tester(c);
    if (!rig.spareUsed) _spare(c);
  }

  void _slab(Canvas c, Size size) {
    final g = geo;
    final r = Rect.fromLTRB(0, g.gy, size.width, size.height);
    final cols = switch (rig.soil) {
      M6Soil.loamWet => const [Color(0xFF5A3E2A), Color(0xFF3E2A1C)],
      M6Soil.loamDry => const [Color(0xFFB08A5E), Color(0xFF8A6844)],
      M6Soil.rocky => const [Color(0xFF7A6450), Color(0xFF5A4838)],
      M6Soil.sandy => const [Color(0xFFD9BE86), Color(0xFFB89C64)],
    };
    c.drawRect(r, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: cols).createShader(r));
    // The cut face's top edge.
    c.drawLine(Offset(0, g.gy), Offset(size.width, g.gy), Paint()
      ..color = const Color(0x55000000)
      ..strokeWidth = 2);
    final rnd = math.Random(7);
    switch (rig.soil) {
      case M6Soil.loamWet:
        for (var i = 0; i < 40; i++) {
          final p = Offset(rnd.nextDouble() * size.width, g.gy + 6 + rnd.nextDouble() * (g.floorY - g.gy));
          c.drawCircle(p, 1.2 + rnd.nextDouble(), Paint()..color = const Color(0x332A1A10));
        }
      case M6Soil.loamDry:
        final crack = Paint()
          ..color = const Color(0xAA5A3E22)
          ..strokeWidth = 1.4
          ..style = PaintingStyle.stroke;
        for (var i = 0; i < 9; i++) {
          final x = 12 + i * 40.0 + rnd.nextDouble() * 14;
          final p = Path()..moveTo(x, g.gy);
          var yy = g.gy;
          var xx = x;
          for (var k = 0; k < 4; k++) {
            xx += (rnd.nextDouble() - 0.5) * 10;
            yy += 8 + rnd.nextDouble() * 8;
            p.lineTo(xx, yy);
          }
          c.drawPath(p, crack);
        }
      case M6Soil.rocky:
        for (var i = 0; i < 26; i++) {
          final p = Offset(rnd.nextDouble() * size.width, g.gy + 10 + rnd.nextDouble() * (g.floorY - g.gy));
          final rr = 5 + rnd.nextDouble() * 9;
          c.drawOval(Rect.fromCenter(center: p, width: rr * 1.6, height: rr), Paint()..color = const Color(0xFF8E8A84));
          c.drawOval(Rect.fromCenter(center: p.translate(-1, -1), width: rr * 1.1, height: rr * 0.6), Paint()..color = const Color(0x55FFFFFF));
        }
      case M6Soil.sandy:
        for (var i = 0; i < 160; i++) {
          final p = Offset(rnd.nextDouble() * size.width, g.gy + 4 + rnd.nextDouble() * (g.floorY - g.gy));
          c.drawCircle(p, 0.9, Paint()..color = (i.isEven ? const Color(0x66FFF4D0) : const Color(0x557A5A2A)));
        }
    }
  }

  void _dtr(Canvas c) {
    final g = geo;
    final p = g.plinth;
    c.drawRect(p, Paint()..shader = const LinearGradient(colors: [Color(0xFFC9C4BA), Color(0xFFA8A398)]).createShader(p));
    c.drawRect(p, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = const Color(0xFF7E7A70));
    final t = g.tank;
    // Fins.
    for (var x = t.left - 6; x <= t.right + 2; x += 8) {
      c.drawRect(Rect.fromLTWH(x, t.top + 10, 4, t.height - 16), Paint()..color = const Color(0xFF6E8A7A));
    }
    c.drawRRect(RRect.fromRectAndRadius(t, const Radius.circular(4)),
        Paint()..shader = const LinearGradient(colors: [Color(0xFF8FAA98), Color(0xFF6A8574)]).createShader(t));
    // HT bushings on top, LT on the side.
    for (var i = 0; i < 3; i++) {
      final x = t.left + 14 + i * 20.0;
      final b = Rect.fromLTWH(x - 4, t.top - 22, 8, 22);
      c.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(3)), Paint()..color = const Color(0xFF8A4A2A));
      for (var k = 0; k < 3; k++) {
        c.drawLine(Offset(x - 6, b.top + 5 + k * 6.0), Offset(x + 6, b.top + 5 + k * 6.0), Paint()
          ..color = const Color(0xFF6A3418)
          ..strokeWidth = 2);
      }
    }
    for (var i = 0; i < 2; i++) {
      final y = t.top + 18 + i * 14.0;
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(t.right, y - 3, 12, 6), const Radius.circular(2)), Paint()..color = const Color(0xFF3A3A3A));
    }
    // The earth terminals on the plinth (their joints come later).
    for (var lead = 0; lead < 2; lead++) {
      final o = g.joint2(lead);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: 22, height: 16), const Radius.circular(2)), Paint()..color = const Color(0xFF6A6A6A));
      // The earth mark, drawn (a glyph may be missing from the phone's fonts).
      final mark = Paint()
        ..color = const Color(0xFF2A2A2A)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;
      final top = o.translate(0, -22);
      c.drawLine(top, top.translate(0, 5), mark);
      for (var k = 0; k < 3; k++) {
        final w = 6.0 - k * 2;
        c.drawLine(top.translate(-w, 5 + k * 2.2), top.translate(w, 5 + k * 2.2), mark);
      }
    }
  }

  void _electrode(Canvas c, int i, M6PitLook p) {
    final g = geo;
    final x = M6PitGeo.pitX[i];
    final bottom = g.floorY - 6;
    final full = bottom - g.headY;
    switch (p.electrode) {
      case M6Electrode.gi27 || M6Electrode.gi25 || M6Electrode.gi30:
        final r = Rect.fromLTRB(x - 5, g.headY, x + 5, bottom);
        c.drawRect(r, Paint()..shader = const LinearGradient(colors: [Color(0xFFD7DCE0), Color(0xFF9AA2A8)]).createShader(r));
        for (var y = g.headY + 30; y < bottom - 6; y += 16) {
          c.drawCircle(Offset(x, y), 1.6, Paint()..color = const Color(0xFF3A3F45));
        }
      case M6Electrode.short:
        final r = Rect.fromLTRB(x - 5, g.headY, x + 5, g.headY + full * 0.44);
        c.drawRect(r, Paint()..shader = const LinearGradient(colors: [Color(0xFFD7DCE0), Color(0xFF9AA2A8)]).createShader(r));
        for (var y = g.headY + 30; y < r.bottom - 6; y += 16) {
          c.drawCircle(Offset(x, y), 1.6, Paint()..color = const Color(0xFF3A3F45));
        }
      case M6Electrode.rod:
        final r = Rect.fromLTRB(x - 2.5, g.headY, x + 2.5, bottom);
        c.drawRect(r, Paint()..color = const Color(0xFF7A4A2A));
        for (var y = g.headY + 14; y < bottom; y += 22) {
          c.drawCircle(Offset(x + 1, y), 2, Paint()..color = const Color(0xFFB0602A));
        }
      case M6Electrode.bar:
        final path = Path()
          ..moveTo(x, g.headY)
          ..lineTo(x, g.headY + full * 0.5)
          ..quadraticBezierTo(x + 4, g.headY + full * 0.7, x + 16, bottom);
        c.drawPath(
            path,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 6
              ..color = const Color(0xFF6E4A30));
    }
    if (p.bentonite) {
      final r = Rect.fromLTRB(x - 16, g.y(0.66), x + 16, bottom);
      c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(6)), Paint()..color = const Color(0x667E8C9C));
    }
  }

  void _pit(Canvas c, int i) {
    final g = geo;
    final p = rig.pits[i];
    final x = M6PitGeo.pitX[i];
    if (!p.exists) {
      // A peg and string where the pit was meant to go.
      final peg = Rect.fromLTWH(x - 3, g.gy - 30, 6, 32);
      c.drawRect(peg, Paint()..color = const Color(0xFF9A6A3A));
      c.drawLine(Offset(x - 30, g.gy - 1), Offset(x + 30, g.gy - 1), Paint()
        ..color = const Color(0xFFF2EBD8)
        ..strokeWidth = 1.4);
      return;
    }
    final ch = g.chamber(i);
    if (p.wet) {
      c.drawOval(Rect.fromCenter(center: Offset(x, g.y(0.72)), width: 120, height: (g.floorY - g.gy) * 0.8), Paint()..color = const Color(0x553A2414));
    }
    // The hole (always), then the chamber walls if there is a chamber.
    c.drawRect(ch, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2A1E16), Color(0xFF3E2C20)]).createShader(ch));
    if (p.lid != M6Lid.missing) {
      final wall = Paint()..shader = const LinearGradient(colors: [Color(0xFFB8B2A6), Color(0xFF8E897E)]).createShader(ch);
      c.drawRect(Rect.fromLTRB(ch.left - 6, ch.top - 4, ch.left, ch.bottom), wall);
      c.drawRect(Rect.fromLTRB(ch.right, ch.top - 4, ch.right + 6, ch.bottom), wall);
      c.drawRect(Rect.fromLTRB(ch.left - 6, ch.bottom, ch.right + 6, ch.bottom + 5), wall);
    } else {
      // Ragged soil edges: no chamber.
      final edge = Paint()..color = const Color(0xFF4A3424);
      for (var k = 0; k < 6; k++) {
        c.drawCircle(Offset(ch.left + 1, ch.top + 8 + k * (ch.height / 6)), 3, edge);
        c.drawCircle(Offset(ch.right - 1, ch.top + 14 + k * (ch.height / 6)), 3, edge);
      }
    }
    _electrode(c, i, p);
    if (p.extra) {
      final ex = x + (i == 0 ? 50 : -50);
      final r = Rect.fromLTRB(ex - 4, g.gy + 6, ex + 4, g.floorY - 10);
      c.drawRect(r, Paint()..shader = const LinearGradient(colors: [Color(0xFFD7DCE0), Color(0xFF9AA2A8)]).createShader(r));
      c.drawLine(Offset(ex, g.gy + 8), Offset(x, g.joint1(i).dy), Paint()
        ..color = const Color(0xFF8A939C)
        ..strokeWidth = 3);
    }
    // The bottom joint: a clamp on the electrode head, the strip's end on it.
    final j = g.joint1(i);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: j, width: 22, height: 12), const Radius.circular(3)), Paint()..color = const Color(0xFF8A939C));
    c.drawCircle(j, 3, Paint()..color = const Color(0xFF3A3F45));
    m6PaintNut(c, j, p.joint1, tight: p.tight1);
    // Lid.
    switch (p.lid) {
      case M6Lid.on:
        final l = g.lidOn(i);
        c.drawRRect(RRect.fromRectAndRadius(l, const Radius.circular(3)), Paint()..shader = const LinearGradient(colors: [Color(0xFFC8C2B6), Color(0xFF9C968A)]).createShader(l));
        c.drawCircle(l.center, 3, Paint()..color = const Color(0xFF5A564E));
      case M6Lid.off:
        final l = g.lidOff(i);
        c.drawOval(l, Paint()..shader = const RadialGradient(colors: [Color(0xFFCCC6BA), Color(0xFF948E82)]).createShader(l));
        c.drawOval(l, Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const Color(0xFF6E6A60));
        c.drawCircle(l.center, 3, Paint()..color = const Color(0xFF5A564E));
      case M6Lid.missing:
        break;
    }
  }

  void _leads(Canvas c) {
    final g = geo;
    // Each lead: its top joint on the terminal, down the plinth, under the
    // ground to the pit it is bolted in.
    for (var lead = 0; lead < 2; lead++) {
      final into = _pitOfLead(lead);
      final t = g.joint2(lead);
      final j = g.joint1(into);
      final strip = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF9AA2A8);
      final yUnder = g.gy + 10 + lead * 6.0;
      final path = Path()
        ..moveTo(t.dx, t.dy + 8)
        ..lineTo(t.dx, yUnder)
        ..lineTo(j.dx + (into == 0 ? 14 : -14), yUnder)
        ..lineTo(j.dx + (into == 0 ? 8 : -8), j.dy);
      c.drawPath(path, strip);
      m6PaintNut(c, t, rig.joint2[lead], r: 6.5, tight: rig.tight2[lead]);
      if (rig.joint2[lead] == M6Nut.none) {
        // The strip's end hangs off the bolt.
        c.drawLine(t.translate(0, 8), t.translate(6, 14), Paint()
          ..color = const Color(0xFFF2F2F2)
          ..strokeWidth = 3);
      }
    }
    // A bottom joint with its nut off: the strip's end hangs free.
    for (var i = 0; i < 2; i++) {
      final p = rig.pits[i];
      if (!p.exists || p.joint1 != M6Nut.none) continue;
      final j = g.joint1(i);
      c.drawLine(j.translate(i == 0 ? 10 : -10, 2), j.translate(i == 0 ? 14 : -14, 12), Paint()
        ..color = const Color(0xFFF2F2F2)
        ..strokeWidth = 3);
    }
    if (rig.leadsOn) {
      final from = g.tester.bottomLeft.translate(14, -4);
      final j = g.joint1(rig.current);
      for (final (k, col) in [(0, const Color(0xFFD7332A)), (1, const Color(0xFF15191E))]) {
        c.drawPath(
            Path()
              ..moveTo(from.dx + k * 8, from.dy)
              ..quadraticBezierTo((from.dx + j.dx) / 2, g.gy - 30 + k * 10, j.dx + (k == 0 ? -6 : 6), j.dy - 8),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.6
              ..color = col);
      }
    }
  }

  int _pitOfLead(int lead) => lead == 1 && rig.pits[1].exists == false ? 0 : lead;

  void _tester(Canvas c) {
    final g = geo;
    final t = g.tester;
    c.drawRRect(RRect.fromRectAndRadius(t.inflate(2), const Radius.circular(8)), Paint()..color = const Color(0x55000000));
    c.drawRRect(RRect.fromRectAndRadius(t, const Radius.circular(7)), Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF2C230), Color(0xFFC9961A)]).createShader(t));
    final d = g.display;
    c.drawRRect(RRect.fromRectAndRadius(d.inflate(2), const Radius.circular(3)), Paint()..color = const Color(0xFF2B3138));
    c.drawRect(d, Paint()..color = const Color(0xFFB9C9A6));
    final b = g.testBtn;
    c.drawCircle(b, 13, Paint()..color = const Color(0xFF2E343B));
    c.drawCircle(b, 10, Paint()..shader = const RadialGradient(center: Alignment(-0.35, -0.35), colors: [Color(0xFFFF8A80), Color(0xFFD7332A)]).createShader(Rect.fromCircle(center: b, radius: 10)));
    _label(c, 'TEST', b.translate(28, 0), size: 7, color: const Color(0xFF2A2018));
  }

  void _spare(Canvas c) {
    final s = geo.spare;
    // Pallet.
    c.drawRect(Rect.fromLTRB(s.left, s.bottom - 7, s.right, s.bottom), Paint()..color = const Color(0xFF9A6A3A));
    // The ring standing, the lid leaning on it.
    final ring = Rect.fromLTRB(s.left + 6, s.top + s.height * 0.3, s.right - 22, s.bottom - 7);
    c.drawRect(ring, Paint()..shader = const LinearGradient(colors: [Color(0xFFC8C2B6), Color(0xFF8E897E)]).createShader(ring));
    c.drawOval(Rect.fromLTRB(ring.left, ring.top - 6, ring.right, ring.top + 6), Paint()..color = const Color(0xFF5A564E));
    final lid = Rect.fromLTRB(s.right - 34, s.top + 4, s.right - 2, s.bottom - 8);
    c.drawOval(lid, Paint()..shader = const RadialGradient(colors: [Color(0xFFCCC6BA), Color(0xFF948E82)]).createShader(lid));
  }

  @override
  bool shouldRepaint(M6PitWorldPainter old) => old.geo != geo || old.rig != rig;
}

/// The spanner on a joint being tightened (repaints while it turns).
class M6PitSpannerPainter extends CustomPainter {
  const M6PitSpannerPainter({required this.at, required this.angle});
  final Offset at;
  final double angle;

  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(angle);
    final body = Paint()..color = const Color(0xFF5A626B);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(6, -4, 40, 8), const Radius.circular(3)), body);
    c.drawCircle(Offset.zero, 10, body);
    c.drawCircle(Offset.zero, 5, Paint()..color = const Color(0xFF2B3138));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(38, -5, 14, 10), const Radius.circular(4)), Paint()..color = const Color(0xFFD0352B));
    c.restore();
  }

  @override
  bool shouldRepaint(M6PitSpannerPainter old) => old.at != at || old.angle != angle;
}

/// A fault on the un-earthed DTR body (a deadly mistake), in colour over
/// the grey scene: the tank glows and the current finds a way down.
class M6PitFlashPainter extends CustomPainter {
  const M6PitFlashPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final flick = v < 0.5 ? (0.65 + 0.35 * math.sin(v * 60).abs()) : (1 - (v - 0.5) * 1.2).clamp(0.4, 1.0);
    final r = 30 + 80 * Curves.easeOut.transform(v.clamp(0.0, 1.0));
    c.drawCircle(
        at,
        r,
        Paint()
          ..shader = RadialGradient(colors: [Color.fromRGBO(255, 250, 225, 0.95 * flick), Color.fromRGBO(130, 165, 255, 0.5 * flick), const Color(0x00FFC24A)])
              .createShader(Rect.fromCircle(center: at, radius: r)));
    final spark = Paint()
      ..color = Color.fromRGBO(255, 214, 90, (1 - v).clamp(0.0, 1.0))
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 16; i++) {
      final a = i / 16 * math.pi * 2 + 0.2;
      final d0 = 10 + 56 * v;
      c.drawLine(at + Offset(math.cos(a), math.sin(a)) * d0, at + Offset(math.cos(a), math.sin(a)) * (d0 + 14), spark);
    }
    final white = (1 - v * 4).clamp(0.0, 1.0);
    if (white > 0) c.drawRect(Offset.zero & size, Paint()..color = Color.fromRGBO(255, 255, 255, 0.8 * white));
  }

  @override
  bool shouldRepaint(M6PitFlashPainter old) => old.v != v || old.at != at;
}

/// "ফল্ট হলে" (spec flow 8): with both earths signed, a fault on the DTR
/// body runs down lead [lead]'s strip into its pit and the earth, and the LT
/// breaker trips (ON → OFF). [v] runs 0 → 1 (1 at once in reduced motion).
class M6PitTripPainter extends CustomPainter {
  const M6PitTripPainter({required this.geo, required this.v, this.lead = 1});
  final M6PitGeo geo;
  final double v;
  final int lead;

  /// The breaker trips from here on.
  static const double tripAt = 0.8;

  Rect get breaker => Rect.fromLTWH(geo.tank.left - 40, geo.tank.top + 4, 28, 38);

  Path _route() {
    final g = geo;
    final t = g.joint2(lead);
    final j = g.joint1(lead);
    final yUnder = g.gy + 10 + lead * 6.0;
    final side = lead == 0 ? 14.0 : -14.0;
    return Path()
      ..moveTo(g.flashAt.dx, g.flashAt.dy)
      ..lineTo(t.dx, t.dy)
      ..lineTo(t.dx, yUnder)
      ..lineTo(j.dx + side, yUnder)
      ..lineTo(j.dx + side * 0.6, j.dy)
      ..lineTo(j.dx, j.dy)
      ..lineTo(j.dx, g.floorY - 10);
  }

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final x = v.clamp(0.0, 1.0);
    // The fault: a short spark on the tank.
    final spark = (1 - x / 0.3).clamp(0.0, 1.0);
    if (spark > 0) {
      final r = 18 + 30 * (1 - spark);
      c.drawCircle(
          g.flashAt,
          r,
          Paint()
            ..shader = RadialGradient(colors: [Color.fromRGBO(255, 248, 210, 0.95 * spark), Color.fromRGBO(255, 190, 70, 0.5 * spark), const Color(0x00FFC24A)])
                .createShader(Rect.fromCircle(center: g.flashAt, radius: r)));
    }
    // The current down the strip into the earth.
    final run = ((x - 0.1) / 0.6).clamp(0.0, 1.0);
    if (run > 0) {
      for (final m in _route().computeMetrics()) {
        final part = m.extractPath(0, m.length * run);
        c.drawPath(
            part,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 7
              ..strokeCap = StrokeCap.round
              ..color = const Color(0x66FFD24A));
        c.drawPath(
            part,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.6
              ..strokeCap = StrokeCap.round
              ..color = const Color(0xFFFFE27A));
        final head = m.getTangentForOffset(m.length * run)?.position;
        if (head != null && run < 1) c.drawCircle(head, 5, Paint()..color = const Color(0xFFFFF6C8));
      }
    }
    // Into the earth: rings round the electrode's foot.
    final soak = ((x - 0.62) / 0.38).clamp(0.0, 1.0);
    if (soak > 0) {
      final foot = Offset(g.joint1(lead).dx, g.floorY - 10);
      for (var k = 0; k < 3; k++) {
        final f = ((soak * 1.4) - k * 0.2).clamp(0.0, 1.0);
        if (f <= 0) continue;
        c.drawCircle(
            foot,
            6 + 26 * f,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = Color.fromRGBO(120, 220, 140, 0.8 * (1 - f * 0.6)));
      }
    }
    // The LT breaker: ON until the fault current trips it, then OFF.
    final b = breaker;
    final off = x >= tripAt;
    c.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(3)), Paint()..color = const Color(0xFF2E3640));
    c.drawRRect(
        RRect.fromRectAndRadius(b, const Radius.circular(3)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = off ? const Color(0xFFE5533D) : const Color(0xFF6FCF7F));
    final slot = Rect.fromCenter(center: b.center.translate(0, -3), width: 8, height: 18);
    c.drawRRect(RRect.fromRectAndRadius(slot, const Radius.circular(2)), Paint()..color = const Color(0xFF161B21));
    final knob = Rect.fromCenter(center: Offset(slot.center.dx, off ? slot.bottom - 4 : slot.top + 4), width: 10, height: 8);
    c.drawRRect(RRect.fromRectAndRadius(knob, const Radius.circular(2)), Paint()..color = off ? const Color(0xFFE5533D) : const Color(0xFF6FCF7F));
    _label(c, off ? 'OFF' : 'ON', Offset(b.center.dx, b.bottom - 6), size: 7, color: const Color(0xFFF2F2F2), weight: FontWeight.w900);
    _label(c, 'LT', Offset(b.center.dx, b.top - 6), size: 7, color: const Color(0xFF26303D), weight: FontWeight.w900);
  }

  @override
  bool shouldRepaint(M6PitTripPainter old) => old.v != v || old.geo != geo || old.lead != lead;
}
