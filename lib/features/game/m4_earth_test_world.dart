import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

// The DTR yard for lesson 4.6 কাজ 1 "মাটির পরীক্ষা" (m4_earth_test): a drawn,
// layered place — the afternoon sky, a far tree line and village, paddy, and
// close up the pole-mounted distribution transformer on its H-pole, with its
// double earthing as the lesson and the film give it: the neutral and the
// body, each to two separate earth pits (N-1, N-2, B-1, B-2 — the markings a
// worker reads on the pits). The earth strips run down the poles to the pits.
// In front, on the soil: the two places for the tester's temporary spikes, the
// earth tester on the ground and its leads.
// The only text: the pit markings and a pit's recorded reading (Ω).
//
// Design: 360 wide × the scene's height; the ground follows the bottom of the
// screen (a tall phone gets more sky).

/// What is wrong with an earth point (seen by eye — lesson point 2).
enum M4EarthTestFault { cut, rust, cover }

/// The four earth pits (the transformer's double earthing).
const m4EarthTestPitNames = ['N-1', 'N-2', 'B-1', 'B-2'];

/// Where things stand (design px, 360 wide).
@immutable
class M4EarthTestGeo {
  const M4EarthTestGeo({required this.height, required this.groundY});

  factory M4EarthTestGeo.forScene(double h, double inset) => M4EarthTestGeo(height: h, groundY: h - 250 - inset);

  final double height;

  /// The line the pits sit on.
  final double groundY;

  double get horizonY => groundY - (groundY - 120) * 0.38;

  /// The H-pole's two poles.
  static const poleL = 112.0;
  static const poleR = 168.0;

  double get poleTop => math.max(150.0, groundY - 360);

  /// The transformer tank on its platform.
  Rect get tank {
    final top = poleTop + (groundY - poleTop) * 0.3;
    return Rect.fromLTRB(poleL + 8, top, poleR - 8, top + 66);
  }
  double get platformY => tank.bottom + 4;

  /// The pits' centres (N-1, N-2, B-1, B-2).
  static const pitX = [34.0, 80.0, 200.0, 246.0];
  Offset pit(int i) => Offset(pitX[i], groundY);

  /// Where each earth strip leaves the transformer (neutral bushing / tank).
  Offset strapTop(int i) => switch (i) {
        0 => Offset(tank.left + 10, tank.top - 4),
        1 => Offset(tank.left + 18, tank.top - 4),
        2 => Offset(tank.right - 4, tank.bottom - 14),
        _ => Offset(tank.right - 4, tank.bottom - 6),
      };

  /// The strip's path: off the transformer, down the pole, out to its pit.
  List<Offset> strap(int i) {
    final a = strapTop(i);
    final down = i < 2 ? poleL - 5 - 4 * i : poleR + 5 + 4 * (i - 2);
    final bend = groundY - 46 - (i.isEven ? 0 : 10);
    return [a, Offset(down, a.dy + (i < 2 ? -6 : 0)), Offset(down, bend), Offset(pitX[i], bend + 14), Offset(pitX[i], groundY - 4)];
  }

  /// Where a cut shows on strip [i] (its last, vertical run).
  Offset cutAt(int i) => Offset(pitX[i], groundY - 22);

  /// The tap area of earth point [i]: its strip's run down to the pit and the pit.
  Rect earthRect(int i) => Rect.fromLTRB(pitX[i] - 22, groundY - 64, pitX[i] + 22, groundY + 30);

  /// The two places for the temporary spikes (the soil in front, to the right).
  static const spikeX = [292.0, 336.0];
  Offset spike(int k) => Offset(spikeX[k], groundY + 6);
  Rect spikeRect(int k) => Rect.fromCenter(center: spike(k), width: 46, height: 46);

  /// The earth tester on the ground (its leads start here).
  Offset get tester => Offset(130, groundY + 84);

  /// The trainee's box (beside the tester).
  static const figH = 128.0;
  static const figW = 64.0;
  Rect get trainee => Rect.fromLTWH(26, groundY + 150 - figH, figW, figH);

  @override
  bool operator ==(Object other) => other is M4EarthTestGeo && other.height == height && other.groundY == groundY;

  @override
  int get hashCode => Object.hash(height, groundY);
}

/// A pit's recorded result.
@immutable
class M4EarthTestMark {
  const M4EarthTestMark(this.ohms, {required this.high});
  final double ohms;
  final bool high;

  @override
  bool operator ==(Object other) => other is M4EarthTestMark && other.ohms == ohms && other.high == high;

  @override
  int get hashCode => Object.hash(ohms, high);
}

/// What the yard shows.
@immutable
class M4EarthTestView {
  const M4EarthTestView({
    this.faults = const {},
    this.spotted = const {},
    this.testPit,
    this.spikeAt = const {},
    this.leads = false,
    this.marks = const {},
  });

  final Map<int, M4EarthTestFault> faults;

  /// Points he has tagged (a red tag hangs there, fault or not).
  final Set<int> spotted;

  /// The pit under test (the leads go to it).
  final int? testPit;

  /// The spike places (0, 1) driven.
  final Set<int> spikeAt;
  final bool leads;
  final Map<int, M4EarthTestMark> marks;

  @override
  bool operator ==(Object other) =>
      other is M4EarthTestView &&
      _mapEq(other.faults, faults) &&
      other.spotted.length == spotted.length &&
      other.spotted.containsAll(spotted) &&
      other.testPit == testPit &&
      other.spikeAt.length == spikeAt.length &&
      other.spikeAt.containsAll(spikeAt) &&
      other.leads == leads &&
      _mapEq(other.marks, marks);

  static bool _mapEq<K, V>(Map<K, V> a, Map<K, V> b) => a.length == b.length && a.entries.every((e) => b[e.key] == e.value);

  @override
  int get hashCode => Object.hash(faults.length, spotted.length, testPit, spikeAt.length, leads, marks.length);
}

/// "18.0" → "18", "2.5" → "2.5" (English digits).
String m4EarthTestOhms(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

/// The place: sky, land, the DTR on its H-pole, the earth strips and pits,
/// the spikes and the leads.
class M4EarthTestWorldPainter extends CustomPainter {
  const M4EarthTestWorldPainter({required this.geo, required this.view});
  final M4EarthTestGeo geo;
  final M4EarthTestView view;

  @override
  void paint(Canvas c, Size size) {
    _land(c, size);
    _structure(c);
    for (var i = 0; i < 4; i++) {
      _earth(c, i);
    }
    _kit(c);
  }

  void _land(Canvas c, Size size) {
    final w = size.width;
    final hz = geo.horizonY;
    final g = geo.groundY;
    final sky = Rect.fromLTWH(0, 0, w, hz + 6);
    c.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4F8FC9), Color(0xFF9CC6E5), Color(0xFFF1E2C2)],
          stops: [0, 0.62, 1],
        ).createShader(sky),
    );
    final sun = Offset(w * 0.8, hz * 0.42);
    c.drawCircle(sun, 90, Paint()..shader = const RadialGradient(colors: [Color(0x80FFF1C8), Color(0x00FFF1C8)]).createShader(Rect.fromCircle(center: sun, radius: 90)));
    c.drawCircle(sun, 13, Paint()..color = const Color(0xFFFFF4D6));
    final cloud = Paint()..color = const Color(0xCCFFFFFF);
    for (final (x, y, r) in [(60.0, hz * 0.36, 15.0), (250.0, hz * 0.2, 19.0), (330.0, hz * 0.62, 11.0)]) {
      c.drawCircle(Offset(x, y), r, cloud);
      c.drawCircle(Offset(x + r, y + 4), r * 0.8, cloud);
      c.drawCircle(Offset(x - r, y + 5), r * 0.7, cloud);
    }
    // Far tree line and village.
    final tree = Path()..moveTo(0, hz);
    for (var x = 0.0; x <= w + 16; x += 16) {
      final bump = 12 + 7 * math.sin(x * 0.06) + 5 * math.sin(x * 0.19 + 0.7);
      tree.quadraticBezierTo(x + 8, hz - bump - 8, x + 16, hz - bump * 0.6);
    }
    tree
      ..lineTo(w, hz + 4)
      ..lineTo(0, hz + 4)
      ..close();
    c.drawPath(tree, Paint()..color = const Color(0xFF4B7652));
    for (final (x, sz) in const [(20.0, 0.9), (232.0, 1.0), (300.0, 0.8)]) {
      c.drawRect(Rect.fromLTWH(x, hz - 12 * sz, 24 * sz, 12 * sz), Paint()..color = const Color(0xFFB8A07A));
      c.drawPath(
          Path()
            ..moveTo(x - 3 * sz, hz - 11 * sz)
            ..lineTo(x + 12 * sz, hz - 20 * sz)
            ..lineTo(x + 27 * sz, hz - 11 * sz)
            ..close(),
          Paint()..color = const Color(0xFF8A6D4E));
    }
    // Paddy, then the yard's soil.
    final field = Rect.fromLTRB(0, hz, w, g - 20);
    c.drawRect(field, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF93BC63), Color(0xFF6F9F47)]).createShader(field));
    final row = Paint()
      ..color = const Color(0x335A7F2E)
      ..strokeWidth = 1.2;
    for (var i = 1; i < 6; i++) {
      final y = hz + (g - 20 - hz) * (i / 6) * (i / 6);
      c.drawLine(Offset(0, y), Offset(w, y), row);
    }
    final yard = Rect.fromLTRB(0, g - 20, w, size.height);
    c.drawRect(yard, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF9A7E58), Color(0xFF7C6446), Color(0xFF6A563D)], stops: [0, 0.4, 1]).createShader(yard));
    final grit = Paint()..color = const Color(0x22000000);
    final rnd = math.Random(46);
    for (var i = 0; i < 70; i++) {
      c.drawCircle(Offset(rnd.nextDouble() * w, g - 14 + rnd.nextDouble() * (size.height - g)), 0.8 + rnd.nextDouble() * 1.4, grit);
    }
    final tuft = Paint()
      ..color = const Color(0xFF5B7F32)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    for (var x = 8.0; x < w; x += 23) {
      for (final k in const [-3.0, 0.0, 3.0]) {
        c.drawLine(Offset(x + k, g - 16), Offset(x + k + 3, g - 26 - (k == 0 ? 3 : 0)), tuft);
      }
    }
  }

  void _structure(Canvas c) {
    final g = geo.groundY;
    final top = geo.poleTop;
    const l = M4EarthTestGeo.poleL;
    const r = M4EarthTestGeo.poleR;
    // HT line overhead, to the far poles.
    final wire = Paint()
      ..color = const Color(0xFF2A2F36)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;
    for (var k = 0; k < 3; k++) {
      final y = top + 6 + k * 2.0;
      final x = l - 12 + k * 40.0;
      c.drawPath(Path()..moveTo(0, y + 30)..quadraticBezierTo(x / 2, y + 40, x, y), wire);
      c.drawPath(Path()..moveTo(x, y)..quadraticBezierTo((x + 360) / 2, y + 36, 360, y + 22), wire);
    }
    // The two PCC poles.
    for (final x in const [l, r]) {
      final pole = Path()
        ..moveTo(x - 5, top)
        ..lineTo(x + 5, top)
        ..lineTo(x + 8, g + 2)
        ..lineTo(x - 8, g + 2)
        ..close();
      c.drawPath(pole, Paint()..shader = const LinearGradient(colors: [Color(0xFFC2C1B9), Color(0xFF8E8D86)]).createShader(Rect.fromLTRB(x - 8, top, x + 8, g)));
      c.drawOval(Rect.fromCenter(center: Offset(x, g + 2), width: 34, height: 7), Paint()..color = const Color(0x33000000));
    }
    final steel = Paint()..color = const Color(0xFF4A4F57);
    // Top cross-arm with the HT pin insulators; the AB switch arm; the platform.
    c.drawRect(Rect.fromLTRB(l - 22, top + 10, r + 22, top + 15), steel);
    for (var k = 0; k < 3; k++) {
      final x = l - 12 + k * 40.0;
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 4, top - 2, 8, 12), const Radius.circular(3)), Paint()..color = const Color(0xFFEDEBE2));
      // Drop to the HT bushings.
      c.drawLine(Offset(x, top + 2), Offset(geo.tank.left + 12 + k * 16, geo.tank.top - 18), Paint()
        ..color = const Color(0xFF2A2F36)
        ..strokeWidth = 1.4);
    }
    c.drawRect(Rect.fromLTRB(l - 8, geo.platformY, r + 8, geo.platformY + 6), steel);
    c.drawRect(Rect.fromLTRB(l - 6, geo.platformY + 6, l - 2, geo.platformY + 40), steel);
    // The tank: grey, cooling fins, HT bushings on top, LT box to the side.
    final t = geo.tank;
    c.drawRRect(RRect.fromRectAndRadius(t.shift(const Offset(3, 3)), const Radius.circular(5)), Paint()..color = const Color(0x44000000));
    c.drawRRect(RRect.fromRectAndRadius(t, const Radius.circular(5)), Paint()..shader = const LinearGradient(colors: [Color(0xFF9AA5AC), Color(0xFF6E7980)]).createShader(t));
    final fin = Paint()
      ..color = const Color(0xFF5E686F)
      ..strokeWidth = 2;
    for (var x = t.left + 8; x < t.right - 4; x += 6) {
      c.drawLine(Offset(x, t.top + 14), Offset(x, t.bottom - 6), fin);
    }
    c.drawRect(Rect.fromLTRB(t.left - 2, t.top, t.right + 2, t.top + 8), Paint()..color = const Color(0xFF7F8A91));
    for (var k = 0; k < 3; k++) {
      final b = Rect.fromLTWH(t.left + 8 + k * 16, t.top - 18, 8, 18);
      c.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(3)), Paint()..color = const Color(0xFF8B5A3C));
    }
    // LT bushings on the near side (the neutral one is the first).
    for (var k = 0; k < 4; k++) {
      c.drawRect(Rect.fromLTWH(t.left + 6 + k * 7, t.top - 7, 4, 7), Paint()..color = const Color(0xFFE3DFD3));
    }
    // The red danger plate on the pole.
    final plate = Rect.fromLTWH(r - 6, geo.platformY + 30, 12, 14);
    c.drawRect(plate, Paint()..color = const Color(0xFFF2F0E8));
    c.drawPath(
        Path()
          ..moveTo(plate.center.dx + 1.5, plate.top + 2)
          ..lineTo(plate.center.dx - 2.5, plate.center.dy + 1)
          ..lineTo(plate.center.dx + 0.5, plate.center.dy + 1)
          ..lineTo(plate.center.dx - 1.5, plate.bottom - 2),
        Paint()
          ..color = const Color(0xFFC62828)
          ..strokeWidth = 1.6
          ..style = PaintingStyle.stroke);
  }

  void _earth(Canvas c, int i) {
    final g = geo.groundY;
    final pts = geo.strap(i);
    final fault = view.faults[i];
    final px = M4EarthTestGeo.pitX[i];
    // The earth strip (GI flat, grey; rust-brown where it rusted).
    final strip = Paint()
      ..color = const Color(0xFF8C969C)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    if (fault == M4EarthTestFault.cut) {
      // The strip cut and its lower run gone (stolen): two ragged ends.
      final cut = geo.cutAt(i);
      final upper = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final p in pts.skip(1).take(3)) {
        upper.lineTo(p.dx, p.dy);
      }
      upper.lineTo(px, cut.dy - 12);
      c.drawPath(upper, strip);
      c.drawLine(Offset(px, cut.dy - 12), Offset(px - 3, cut.dy - 8), strip);
      c.drawLine(Offset(px, g - 4), Offset(px, g - 9), strip);
      c.drawLine(Offset(px, g - 9), Offset(px + 3, g - 12), strip);
    } else {
      c.drawPath(path, strip);
    }
    // Clamps on the pole.
    final clamp = Paint()..color = const Color(0xFF5A6268);
    c.drawRect(Rect.fromCenter(center: pts[2].translate(0, -40), width: 7, height: 4), clamp);
    // The pit: a concrete chamber with its cover (or open, the cover beside it).
    final rim = Rect.fromCenter(center: Offset(px, g + 2), width: 34, height: 12);
    c.drawRRect(RRect.fromRectAndRadius(rim.inflate(3), const Radius.circular(3)), Paint()..color = const Color(0xFFA7A49B));
    if (fault == M4EarthTestFault.cover) {
      c.drawRRect(RRect.fromRectAndRadius(rim, const Radius.circular(2)), Paint()..color = const Color(0xFF2B2219));
      // The pipe electrode's top, seen inside; dry leaves and soil round it.
      c.drawRect(Rect.fromCenter(center: Offset(px, g + 1), width: 6, height: 6), Paint()..color = const Color(0xFF6E767B));
      final cover = Rect.fromCenter(center: Offset(px + 26, g + 16), width: 30, height: 8);
      c.save();
      c.translate(cover.center.dx, cover.center.dy);
      c.rotate(0.22);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: cover.width, height: cover.height), const Radius.circular(2)), Paint()..color = const Color(0xFF7D7A72));
      c.restore();
      final leaf = Paint()..color = const Color(0xFF8E6B2E);
      for (final (dx, dy) in const [(-12.0, -6.0), (10.0, -5.0), (-4.0, -9.0)]) {
        c.drawOval(Rect.fromCenter(center: Offset(px + dx, g + dy), width: 7, height: 3), leaf);
      }
    } else {
      c.drawRRect(RRect.fromRectAndRadius(rim, const Radius.circular(2)), Paint()..shader = const LinearGradient(colors: [Color(0xFF8D8B84), Color(0xFF6F6D66)]).createShader(rim));
      c.drawLine(Offset(rim.left + 6, rim.center.dy), Offset(rim.right - 6, rim.center.dy), Paint()
        ..color = const Color(0xFF5A5852)
        ..strokeWidth = 1.2);
    }
    // The joint where the strip meets the electrode: a bolt (rusty or clean).
    final joint = Offset(px, g - 6);
    if (fault == M4EarthTestFault.rust) {
      c.drawCircle(joint, 6.5, Paint()..color = const Color(0xFF9A4A1C));
      c.drawCircle(joint.translate(-2, -1), 3, Paint()..color = const Color(0xFFC0642A));
      final flake = Paint()..color = const Color(0xFFB05A22);
      for (final (dx, dy) in const [(-6.0, 6.0), (5.0, 8.0), (1.0, 11.0)]) {
        c.drawCircle(joint.translate(dx, dy), 1.4, flake);
      }
      // A gap: the strip no longer sits tight on the bolt.
      c.drawLine(joint.translate(-1, -12), joint.translate(3, -7), Paint()
        ..color = const Color(0xFF8A4A20)
        ..strokeWidth = 3);
    } else {
      c.drawCircle(joint, 5, Paint()..color = const Color(0xFFC9A44A));
      c.drawCircle(joint, 2, Paint()..color = const Color(0xFF8C7130));
    }
    // The pit's marking.
    _text(c, m4EarthTestPitNames[i], Offset(px, g + 20), 10.5, const Color(0xFFF7F1E1), bold: true, shadow: true);
    // A red tag where he hung one (the same on a fault and a sound point).
    if (view.spotted.contains(i)) {
      final at = Offset(px + 12, g - 40);
      c.drawLine(at.translate(-12, 2), at.translate(-3, 0), Paint()
        ..color = const Color(0xFF3A3A3A)
        ..strokeWidth = 1);
      final tag = Path()
        ..moveTo(at.dx - 3, at.dy - 6)
        ..lineTo(at.dx + 11, at.dy - 6)
        ..lineTo(at.dx + 11, at.dy + 8)
        ..lineTo(at.dx - 3, at.dy + 8)
        ..lineTo(at.dx - 7, at.dy + 1)
        ..close();
      c.drawPath(tag, Paint()..color = const Color(0xFFE53935));
      c.drawCircle(at.translate(-2.5, 1), 1.4, Paint()..color = const Color(0xFFFFFFFF));
      c.drawLine(at.translate(2, -2), at.translate(8, 4), Paint()
        ..color = const Color(0xFFFFFFFF)
        ..strokeWidth = 1.6);
      c.drawLine(at.translate(8, -2), at.translate(2, 4), Paint()
        ..color = const Color(0xFFFFFFFF)
        ..strokeWidth = 1.6);
    }
    // His recorded reading for the pit.
    final mark = view.marks[i];
    if (mark != null) {
      final col = mark.high ? const Color(0xFFE53935) : const Color(0xFF2E9D57);
      final chip = Rect.fromCenter(center: Offset(px, g + 40), width: 40, height: 16);
      c.drawRRect(RRect.fromRectAndRadius(chip, const Radius.circular(8)), Paint()..color = const Color(0xF2FFF8E7));
      c.drawRRect(RRect.fromRectAndRadius(chip, const Radius.circular(8)), Paint()
        ..color = col
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6);
      _text(c, '${m4EarthTestOhms(mark.ohms)} Ω', chip.center, 10, col, bold: true);
    }
  }

  void _kit(Canvas c) {
    final g = geo.groundY;
    // The two spike places (bare, loosened soil) and the spikes once driven.
    for (var k = 0; k < 2; k++) {
      final s = geo.spike(k);
      c.drawOval(Rect.fromCenter(center: s.translate(0, 4), width: 26, height: 9), Paint()..color = const Color(0x55311F0E));
      if (view.spikeAt.contains(k)) {
        c.drawRect(Rect.fromLTRB(s.dx - 2, s.dy - 26, s.dx + 2, s.dy + 4), Paint()..color = const Color(0xFFB9C0C4));
        c.drawRect(Rect.fromLTRB(s.dx - 5, s.dy - 30, s.dx + 5, s.dy - 25), Paint()..color = const Color(0xFF8C9398));
        c.drawCircle(s.translate(0, -18), 3, Paint()..color = k == 0 ? const Color(0xFFF2C230) : const Color(0xFFE53935));
      }
    }
    // The tester on the ground: a yellow case, a dark display.
    final t = geo.tester;
    final body = Rect.fromCenter(center: t, width: 40, height: 24);
    c.drawRRect(RRect.fromRectAndRadius(body.shift(const Offset(2, 3)), const Radius.circular(4)), Paint()..color = const Color(0x44000000));
    c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(4)), Paint()..color = const Color(0xFFF2B705));
    c.drawRect(Rect.fromLTWH(body.left + 5, body.top + 4, 20, 9), Paint()..color = const Color(0xFF26352B));
    for (var k = 0; k < 3; k++) {
      c.drawCircle(Offset(body.left + 9 + k * 11, body.bottom - 5), 2.4, Paint()..color = [const Color(0xFF2B2B2B), const Color(0xFFF2C230), const Color(0xFFE53935)][k]);
    }
    if (!view.leads || view.testPit == null) return;
    // Three leads: to the pit's electrode and to the two spikes.
    final pit = Offset(M4EarthTestGeo.pitX[view.testPit!], g - 4);
    final ends = [pit, geo.spike(0).translate(0, -18), geo.spike(1).translate(0, -18)];
    const cols = [Color(0xFF2B2B2B), Color(0xFFF2C230), Color(0xFFE53935)];
    for (var k = 0; k < 3; k++) {
      final a = Offset(body.left + 9 + k * 11, body.bottom - 5);
      final b = ends[k];
      final mid = Offset((a.dx + b.dx) / 2, math.max(a.dy, b.dy) + 18);
      c.drawPath(
          Path()
            ..moveTo(a.dx, a.dy)
            ..quadraticBezierTo(mid.dx, mid.dy, b.dx, b.dy),
          Paint()
            ..color = cols[k]
            ..strokeWidth = 2
            ..style = PaintingStyle.stroke);
      c.drawCircle(b, 3, Paint()..color = cols[k]);
    }
  }

  void _text(Canvas c, String s, Offset centre, double size, Color color, {bool bold = false, bool shadow = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: bangla(fontSize: size, fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: color, height: 1.1).copyWith(
          shadows: shadow ? const [Shadow(color: Color(0xAA000000), blurRadius: 2)] : null,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(M4EarthTestWorldPainter old) => old.geo != geo || old.view != view;
}
