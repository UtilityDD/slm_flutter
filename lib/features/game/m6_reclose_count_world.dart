import 'dart:math' as math;

import 'package:flutter/material.dart';

// The drawn world of lesson 6.8 কাজ 1 "চেষ্টা গুনুন" (m6_reclose_count.dart):
// storm dusk over farmland. A junction pole stands on the right with
// sectionalizer S-A on its crossarm; the feed comes in from the recloser R
// off the right edge (out of sight: no lamp, no sound, no count of its own).
// Village A lies behind the pole, village B across the paddy (the dealt
// mirror swaps their sides). Their windows and street lamps are the live
// cue: lit = the branch has supply, dark = it has none. The crew van stands
// in front, its rear door open: a magnet board with the crew's sketch
// R → S-A / S-B (painted here) and three magnets (widgets on the page).
//
// No text in the art except labels a worker reads (S-A, R, S-A/S-B on the
// sketch, A/B). Code-drawn, gradients, no bitmaps.
//
// Design: 360 wide × the scene's height; everything at the bottom follows
// the bottom of the screen (a tall phone gets more sky, never stretched).

/// What the storm did on the feeder this round (the dealt fault).
enum M6RcOutcome {
  /// A passing touch: a reclose holds (lesson 6.8 point 1).
  transient,

  /// A lasting fault on the main line: every try trips, then lock-out.
  main,

  /// A lasting fault on branch A: S-A opens in the dead pause before the
  /// last try, which lights branch B (lesson 6.8 point 2).
  branchA,

  /// A lasting fault on branch B: S-B opens, the last try lights branch A.
  branchB,
}

/// A branch line on the sketch.
enum M6RcBranch { a, b }

/// Where things are (design px, 360 wide).
@immutable
class M6RcGeo {
  const M6RcGeo._(this.height, this.bottom);

  factory M6RcGeo.forScene(double height, double inset) => M6RcGeo._(height, height - inset * 0.5);

  /// The design height.
  final double height;

  /// The usable bottom (above the system inset).
  final double bottom;

  /// The top of the working scene (under the header).
  static const double top = 128;

  /// The van's open door: the magnet board (sketch on top, magnet tray under).
  Rect get board => Rect.fromLTWH(12, bottom - 340, 226, 160);

  /// The sketch area (a magnet dropped here makes the call).
  Rect get sketch => Rect.fromLTRB(board.left + 4, board.top + 4, board.right - 4, board.top + 110);

  /// Points on the sketch (0–1 across and down the sketch area).
  Offset sk(double fx, double fy) => Offset(sketch.left + fx * sketch.width, sketch.top + fy * sketch.height);

  Offset get skR => sk(0.09, 0.50);
  Offset get skJ => sk(0.40, 0.50);
  Offset skEnd(M6RcBranch b) => sk(0.90, b == M6RcBranch.a ? 0.20 : 0.80);
  Offset skBox(M6RcBranch b) => sk(0.58, b == M6RcBranch.a ? 0.30 : 0.70);

  /// Where a "শাখা বন্ধ" magnet must land: on a branch line.
  Rect branchZone(M6RcBranch b) => b == M6RcBranch.a
      ? Rect.fromLTRB(sk(0.44, 0).dx, sketch.top, sketch.right, sk(0, 0.47).dy)
      : Rect.fromLTRB(sk(0.44, 0).dx, sk(0, 0.53).dy, sketch.right, sketch.bottom);

  /// The three magnets in their tray (fixed places, all alike).
  Rect magnet(int i) => Rect.fromLTWH(board.left + 8 + i * 72.0, board.top + 118, 66, 34);

  /// The docket (slides up over the board; tapped away before the cycle).
  Rect get docket => Rect.fromLTWH(58, bottom - 332, 146, 132);

  /// The docket once tucked away: a tag on the board's top edge.
  Rect get docketTag => Rect.fromLTWH(board.right - 86, board.top - 24, 86, 22);

  /// The radio read-back after the call (right beside the tally clicker).
  Rect get radio => Rect.fromLTWH(clicker.right + 8, clicker.center.dy - 11, 128, 22);

  /// The tally clicker in the player's hand.
  Rect get clicker => Rect.fromLTWH(18, bottom - 166, 80, 80);

  /// The horizon (the villages stand on it).
  double get horizon => math.max(196.0, bottom - 372);

  /// The junction pole (always on the right, beside the van).
  double get poleX => 300;
  double get poleTop => math.max(150.0, horizon - 196);
  double get poleFoot => bottom - 182;
  Offset get crossarm => Offset(poleX, poleTop + 14);

  /// Sectionalizer S-A on the pole.
  Offset get saBox => Offset(poleX - 22, poleTop + 44);

  /// Where the trainee stands (by the pole's foot); up the pole if he climbs.
  Rect get trainee => Rect.fromLTWH(poleX - 60, poleFoot - 104, 44, 104);
  Rect get traineeUp => Rect.fromLTWH(poleX - 30, poleTop + 52, 40, 92);

  /// Where the deadly flash comes off (the pole top).
  Offset get zapAt => Offset(poleX, poleTop + 20);

  /// The villages (rects on the horizon): A behind the pole, B across the
  /// paddy; mirrored, they swap sides.
  Rect village(M6RcBranch b, bool mirror) {
    final left = (b == M6RcBranch.b) != mirror;
    final w = b == M6RcBranch.a ? 132.0 : 118.0;
    final h = b == M6RcBranch.a ? 46.0 : 34.0;
    return left ? Rect.fromLTWH(14, horizon - h, w, h) : Rect.fromLTWH(214, horizon - h, w, h);
  }

  /// Where a branch wire lands in its village (a house pole).
  Offset wireEnd(M6RcBranch b, bool mirror) {
    final v = village(b, mirror);
    return Offset(v.center.dx, v.top - 10);
  }

  /// The village's letter sign (A / B, as on the crew sketch), on its pole
  /// on the side away from the lamp; it follows the mirror.
  Offset villageSign(M6RcBranch b, bool mirror) => wireEnd(b, mirror).translate(-11, 12);

  @override
  bool operator ==(Object other) => other is M6RcGeo && other.height == height && other.bottom == bottom;

  @override
  int get hashCode => Object.hash(height, bottom);
}

/// What the world shows now.
@immutable
class M6RcRig {
  const M6RcRig({
    required this.mirror,
    required this.dusk,
    this.lightsA = true,
    this.lightsB = true,
    this.saOpen = false,
    this.climbed = false,
  });

  final bool mirror;

  /// The dusk tint (0 = blue dusk, 1 = copper, 2 = slate).
  final int dusk;
  final bool lightsA;
  final bool lightsB;

  /// S-A on the pole has opened (its blade hangs down).
  final bool saOpen;

  /// The trainee went up the pole (the deadly listen).
  final bool climbed;

  @override
  bool operator ==(Object other) =>
      other is M6RcRig &&
      other.mirror == mirror &&
      other.dusk == dusk &&
      other.lightsA == lightsA &&
      other.lightsB == lightsB &&
      other.saOpen == saOpen &&
      other.climbed == climbed;

  @override
  int get hashCode => Object.hash(mirror, dusk, lightsA, lightsB, saOpen, climbed);
}

void _label(Canvas c, String text, Offset centre, {double size = 7, Color color = const Color(0xFF1E2833), FontWeight weight = FontWeight.w800}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: weight, color: color, height: 1)),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
}

const _skies = [
  [Color(0xFF141B33), Color(0xFF34375A), Color(0xFF6A5A78)],
  [Color(0xFF1A1626), Color(0xFF4A3346), Color(0xFF9A6250)],
  [Color(0xFF12181F), Color(0xFF2E3A46), Color(0xFF59646E)],
];

const _lit = Color(0xFFFFD36B);
const _dark = Color(0xFF262C38);

/// The storm-dusk farmland, the villages, the pole, S-A, the wires and the van.
class M6RcWorldPainter extends CustomPainter {
  const M6RcWorldPainter({required this.geo, required this.rig});
  final M6RcGeo geo;
  final M6RcRig rig;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    final hz = geo.horizon;
    // Sky.
    final sky = _skies[rig.dusk.clamp(0, 2)];
    c.drawRect(
      Rect.fromLTWH(0, 0, w, hz + 2),
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: sky).createShader(Rect.fromLTWH(0, 0, w, hz)),
    );
    // Storm clouds.
    final cloud = Paint()..color = const Color(0xCC1A1E2A);
    for (final (x, y, rx, ry) in const [(40.0, 0.30, 70.0, 22.0), (150.0, 0.22, 90.0, 26.0), (290.0, 0.32, 80.0, 24.0), (220.0, 0.48, 60.0, 16.0), (80.0, 0.55, 54.0, 14.0)]) {
      c.drawOval(Rect.fromCenter(center: Offset(x, hz * y), width: rx * 2, height: ry * 2), cloud);
    }
    // Rain streaks (still: no motion while idle).
    final rain = Paint()
      ..color = const Color(0x22C8D4E6)
      ..strokeWidth = 1;
    for (var i = 0; i < 46; i++) {
      final x = (i * 37.0) % w;
      final y = 120 + (i * 53.0) % (hz - 100).clamp(40.0, 600.0);
      c.drawLine(Offset(x, y), Offset(x - 5, y + 14), rain);
    }
    // Paddy and ground.
    final field = Rect.fromLTWH(0, hz, w, h - hz);
    c.drawRect(field, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF26402C), Color(0xFF1A2C1E), Color(0xFF14201A)]).createShader(field));
    final rows = Paint()
      ..color = const Color(0x3348704C)
      ..strokeWidth = 1.2;
    for (var i = -6; i <= 12; i++) {
      c.drawLine(Offset(w / 2 + i * 8, hz + 2), Offset(w / 2 + i * 60, h), rows);
    }
    // Bunds (paddy dykes).
    final bund = Paint()
      ..color = const Color(0x55593F2A)
      ..strokeWidth = 2;
    for (final f in const [0.18, 0.42, 0.72]) {
      final y = hz + (h - hz) * f;
      c.drawLine(Offset(0, y), Offset(w, y + 6), bund);
    }
    // Villages.
    for (final b in M6RcBranch.values) {
      _village(c, geo.village(b, rig.mirror), b == M6RcBranch.a ? rig.lightsA : rig.lightsB, big: b == M6RcBranch.a);
      _sign(c, geo.villageSign(b, rig.mirror), b == M6RcBranch.a ? 'A' : 'B');
    }
    // Wires: feed from R (off the right edge) to the crossarm; branches out.
    final wire = Paint()
      ..color = const Color(0xFF0C0F14)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final arm = geo.crossarm;
    for (final dy in const [-3.0, 3.0]) {
      c.drawPath(_sag(Offset(w + 4, arm.dy - 18 + dy), arm.translate(14, dy), 8), wire);
    }
    for (final b in M6RcBranch.values) {
      final end = geo.wireEnd(b, rig.mirror);
      final from = b == M6RcBranch.a ? geo.saBox.translate(-4, 18) : arm.translate(-14, 0);
      for (final dy in const [-2.0, 2.0]) {
        c.drawPath(_sag(from.translate(0, dy), end.translate(0, dy), 10), wire);
      }
    }
    _pole(c);
    _sectionalizer(c, geo.saBox, rig.saOpen);
    _van(c);
  }

  Path _sag(Offset a, Offset b, double sag) {
    final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2 + sag);
    return Path()
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo(mid.dx, mid.dy, b.dx, b.dy);
  }

  void _village(Canvas c, Rect v, bool lit, {required bool big}) {
    final n = big ? 4 : 3;
    final hw = v.width / n;
    final glow = Paint()
      ..color = const Color(0x44FFC85A)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    for (var i = 0; i < n; i++) {
      final hh = v.height * (0.62 + 0.12 * ((i * 7) % 3));
      final r = Rect.fromLTWH(v.left + i * hw + 2, v.bottom - hh, hw - 4, hh);
      c.drawRect(r, Paint()..color = Color.lerp(const Color(0xFF39343A), const Color(0xFF4A4038), (i % 2) * 0.6)!);
      final roof = Path()
        ..moveTo(r.left - 2, r.top)
        ..lineTo(r.center.dx, r.top - hh * 0.45)
        ..lineTo(r.right + 2, r.top)
        ..close();
      c.drawPath(roof, Paint()..color = const Color(0xFF2A2226));
      final win = Rect.fromCenter(center: r.center.translate(0, hh * 0.08), width: math.min(8.0, r.width * 0.32), height: math.min(8.0, hh * 0.3));
      if (lit) c.drawRect(win.inflate(3), glow);
      c.drawRect(win, Paint()..color = lit ? _lit : _dark);
    }
    // The village's own pole with a street lamp (where the branch wire ends).
    final px = v.center.dx;
    final top = v.top - 10;
    c.drawLine(Offset(px, top - 4), Offset(px, v.bottom), Paint()
      ..color = const Color(0xFF5A5C60)
      ..strokeWidth = 2.2);
    final lamp = Offset(px + 7, top + 2);
    c.drawLine(Offset(px, top + 2), lamp, Paint()
      ..color = const Color(0xFF5A5C60)
      ..strokeWidth = 1.6);
    if (lit) c.drawCircle(lamp.translate(0, 3), 9, glow);
    c.drawCircle(lamp.translate(0, 3), 2.6, Paint()..color = lit ? const Color(0xFFFFF0B8) : _dark);
  }

  /// A small enamel plate with the village's letter (Latin, as on the sketch).
  void _sign(Canvas c, Offset at, String letter) {
    final plate = RRect.fromRectAndRadius(Rect.fromCenter(center: at, width: 13, height: 13), const Radius.circular(2));
    c.drawRRect(plate, Paint()..color = const Color(0xFFF2EEE2));
    c.drawRRect(plate, Paint()
      ..color = const Color(0xFF1F3A68)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2);
    _label(c, letter, at, size: 9, color: const Color(0xFF1F3A68));
  }

  void _pole(Canvas c) {
    final x = geo.poleX;
    final r = Rect.fromLTRB(x - 5, geo.poleTop, x + 5, geo.poleFoot);
    c.drawRect(r, Paint()..shader = const LinearGradient(colors: [Color(0xFF8E9296), Color(0xFFB8BCC0), Color(0xFF7A7E82)]).createShader(r));
    final arm = Rect.fromCenter(center: geo.crossarm, width: 60, height: 6);
    c.drawRect(arm, Paint()..color = const Color(0xFF5E6268));
    for (final dx in const [-26.0, 0.0, 26.0]) {
      final p = geo.crossarm.translate(dx, -7);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: p, width: 6, height: 10), const Radius.circular(2)), Paint()..color = const Color(0xFFB9D3DC));
    }
    // The pole's number plate.
    final plate = Rect.fromCenter(center: Offset(x, geo.poleFoot - 70), width: 18, height: 10);
    c.drawRect(plate, Paint()..color = const Color(0xFFE8E2C8));
  }

  void _sectionalizer(Canvas c, Offset at, bool open) {
    final body = Rect.fromCenter(center: at, width: 26, height: 30);
    c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(3)), Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFA8B0B8), Color(0xFF6E767E)]).createShader(body));
    c.drawLine(body.topCenter.translate(0, -8), body.topCenter, Paint()
      ..color = const Color(0xFF0C0F14)
      ..strokeWidth = 1.6);
    // The blade: closed = up across the gap; open = hanging down.
    final hinge = body.bottomCenter.translate(0, 2);
    final blade = Paint()
      ..color = const Color(0xFFD9DDE2)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final tip = open ? hinge + Offset(math.cos(1.25), math.sin(1.25)) * 18 : hinge.translate(0, 16);
    c.drawLine(hinge, tip, blade);
    c.drawCircle(hinge, 2.4, Paint()..color = const Color(0xFF2E3238));
    if (!open) c.drawCircle(hinge.translate(0, 18), 2.4, Paint()..color = const Color(0xFF2E3238));
    // Its plate.
    final plate = Rect.fromCenter(center: body.center.translate(0, -3), width: 22, height: 10);
    c.drawRect(plate, Paint()..color = const Color(0xFFF2EDD8));
    _label(c, 'S-A', plate.center, size: 6.5);
  }

  void _van(Canvas c) {
    final b = geo.board;
    final body = Rect.fromLTRB(0, b.top - 16, b.right + 16, b.bottom + 22);
    c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(10)), Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE8E4D6), Color(0xFFB7B2A2)]).createShader(body));
    // The stripe and the open door's frame.
    c.drawRect(Rect.fromLTWH(body.left, body.bottom - 30, body.width, 6), Paint()..color = const Color(0xFFD07A22));
    c.drawRRect(RRect.fromRectAndRadius(b.inflate(6), const Radius.circular(6)), Paint()..color = const Color(0xFF3A3E44));
    for (final x in [body.left + 130, body.right - 46]) {
      c.drawCircle(Offset(x, body.bottom + 4), 17, Paint()..color = const Color(0xFF15181C));
      c.drawCircle(Offset(x, body.bottom + 4), 7, Paint()..color = const Color(0xFF7A7E84));
    }
  }

  @override
  bool shouldRepaint(M6RcWorldPainter old) => old.geo != geo || old.rig != rig;
}

/// The crew's sketch on the magnet board: R → J → S-A / S-B (no state shown:
/// the board never lights or marks a branch).
class M6RcBoardPainter extends CustomPainter {
  const M6RcBoardPainter({required this.geo});
  final M6RcGeo geo;

  @override
  void paint(Canvas c, Size size) {
    final b = geo.board;
    c.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(5)), Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFF4F6F2), Color(0xFFDCE0DA)]).createShader(b));
    // The magnet tray.
    final tray = Rect.fromLTRB(b.left + 3, b.top + 114, b.right - 3, b.bottom - 3);
    c.drawRRect(RRect.fromRectAndRadius(tray, const Radius.circular(4)), Paint()..color = const Color(0x1F2A3440));
    final ink = Paint()
      ..color = const Color(0xFF1F3A68)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    c.drawLine(geo.skR, geo.skJ, ink);
    for (final br in M6RcBranch.values) {
      c.drawLine(geo.skJ, geo.skEnd(br), ink);
      final box = Rect.fromCenter(center: geo.skBox(br), width: 24, height: 13);
      c.drawRect(box, Paint()..color = const Color(0xFFF4F6F2));
      c.drawRect(box, ink..strokeWidth = 1.6);
      ink.strokeWidth = 2.4;
      _label(c, br == M6RcBranch.a ? 'S-A' : 'S-B', box.center, size: 7, color: const Color(0xFF1F3A68));
      // The village at the end: a little house and its letter.
      final e = geo.skEnd(br);
      final house = Path()
        ..moveTo(e.dx - 7, e.dy + 6)
        ..lineTo(e.dx - 7, e.dy - 1)
        ..lineTo(e.dx, e.dy - 7)
        ..lineTo(e.dx + 7, e.dy - 1)
        ..lineTo(e.dx + 7, e.dy + 6)
        ..close();
      c.drawPath(house, ink..strokeWidth = 1.6);
      ink.strokeWidth = 2.4;
      _label(c, br == M6RcBranch.a ? 'A' : 'B', e.translate(0, br == M6RcBranch.a ? 13 : -14), size: 9, color: const Color(0xFF1F3A68));
    }
    final rBox = Rect.fromCenter(center: geo.skR, width: 18, height: 18);
    c.drawRect(rBox, Paint()..color = const Color(0xFFF4F6F2));
    c.drawRect(rBox, ink..strokeWidth = 1.8);
    _label(c, 'R', geo.skR, size: 9, color: const Color(0xFF1F3A68));
    c.drawCircle(geo.skJ, 3, Paint()..color = const Color(0xFF1F3A68));
  }

  @override
  bool shouldRepaint(M6RcBoardPainter old) => old.geo != geo;
}

/// The storm's flash across the sky (the same cue for every fault).
class M6RcFlashPainter extends CustomPainter {
  const M6RcFlashPainter({required this.geo, required this.at, required this.v});
  final M6RcGeo geo;

  /// Where in the sky the bolt strikes (0–1 across).
  final double at;

  /// 0 → 1 over the flash.
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final a = (1 - v).clamp(0.0, 1.0);
    if (a <= 0.01) return;
    c.drawRect(Rect.fromLTWH(0, 0, size.width, geo.horizon), Paint()..color = Color.fromRGBO(235, 240, 255, 0.45 * a));
    final x = 30 + at * (size.width - 60);
    final bolt = Path()..moveTo(x, 90);
    var p = Offset(x, 90);
    for (var i = 0; i < 6; i++) {
      p = p.translate((i.isEven ? 10 : -8), (geo.horizon - 110) / 6);
      bolt.lineTo(p.dx, p.dy);
    }
    c.drawPath(
      bolt,
      Paint()
        ..color = Color.fromRGBO(255, 255, 255, a)
        ..strokeWidth = 2.6
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(M6RcFlashPainter old) => old.v != v || old.at != at || old.geo != geo;
}

/// The deadly moment: the line comes back while he is up the pole.
class M6RcZapPainter extends CustomPainter {
  const M6RcZapPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final r = 12 + 60 * v;
    c.drawCircle(at, r, Paint()..shader = RadialGradient(colors: [const Color(0xFFFFFFFF), const Color(0xFFFFE07A), const Color(0xFF6AB8FF).withValues(alpha: 0)]).createShader(Rect.fromCircle(center: at, radius: r)));
    final p = Paint()
      ..color = const Color(0xFFFFF2B0)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final th = i * math.pi / 4 + v;
      c.drawLine(at + Offset(math.cos(th), math.sin(th)) * r * 0.5, at + Offset(math.cos(th), math.sin(th)) * r * 1.1, p);
    }
  }

  @override
  bool shouldRepaint(M6RcZapPainter old) => old.v != v || old.at != at;
}
