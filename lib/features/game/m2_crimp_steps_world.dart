import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'm2_crimp_steps.dart';

// The crimping bench (lesson 2.3, কাজ 2): a substation workshop wall with a
// pegboard (the hand crimper, the wire brush, the paste tube), the bench in
// front with the cable, its lug and the die rack; on the tray round, four
// crimped lugs to inspect. All drawn in code (design px, 360 wide).

/// Where things are (design px).
@immutable
class CrimpGeo {
  const CrimpGeo._(this.h);
  factory CrimpGeo.forScene(double h) => CrimpGeo._(h);
  final double h;

  double get wallBottom => h * 0.40;
  double get benchFront => h * 0.67;
  double get cableY => h * 0.50;

  /// The conductor's tip (the cable's cut end).
  static const tipX = 196.0;

  /// The barrel's depth.
  static const barrel = 64.0;
  static const palm = 48.0;

  /// The barrel's mouth when the lug lies ready (off the conductor).
  static const restMouth = tipX + 26;
  double mouthAt(double inserted) => restMouth + (tipX - barrel - restMouth) * inserted;

  double barrelR(int size) => switch (size) { <= 10 => 9.0, <= 16 => 10.5, _ => 12.0 };
  double cableR(int size) => barrelR(size) + 1.5;

  /// A strip mark's x on the insulation (× the barrel's depth).
  double markX(double factor) => tipX - barrel * factor;

  /// The die rack: three dies on the bench, left of centre.
  Offset dieAt(int i) => Offset(70 + 62.0 * i, h * 0.605);

  /// Where the tool can go: the barrel's centre and the palm's centre
  /// (the lug fully in).
  Offset get barrelSpot => Offset(mouthAt(1) + barrel / 2, cableY);
  Offset get palmSpot => Offset(mouthAt(1) + barrel + palm / 2, cableY);

  /// The inspection tray: four lugs, two rows.
  Offset trayAt(int i) => Offset(i.isEven ? 98 : 262, h * (i < 2 ? 0.465 : 0.585));
  static const traySize = Size(150, 56);

  /// The pegboard on the wall (right).
  Rect get pegboard => Rect.fromLTWH(196, h * 0.17, 150, h * 0.19);
  Offset get pegCrimper => Offset(pegboard.left + 44, pegboard.top + pegboard.height * 0.55);

  @override
  bool operator ==(Object other) => other is CrimpGeo && other.h == h;
  @override
  int get hashCode => h.hashCode;
}

/// What the bench shows now.
@immutable
class CrimpView {
  const CrimpView({
    this.job,
    this.lugs = const [],
    this.stripped = false,
    this.cleaned = false,
    this.pasted = false,
    this.inserted = 0,
    this.die,
    this.crimped = false,
    this.onBarrel = false,
    this.press = 0,
    this.pull = 0,
    this.brush = 0,
    this.showMarks = false,
    this.showDies = false,
    this.toolOut = false,
    this.heat = 0,
    this.heatAt,
    this.pliers = false,
    this.bad,
  });
  final CrimpJob? job;
  final List<LugKind> lugs;
  final bool stripped;
  final bool cleaned;
  final bool pasted;
  final double inserted;
  final int? die;
  final bool crimped;
  final bool onBarrel;

  /// The tool's jaws closing (0–1).
  final double press;

  /// The pull test's tug (0–1–0).
  final double pull;

  /// The brush's sweep (0–1).
  final double brush;
  final bool showMarks;
  final bool showDies;

  /// The crimper is off the pegboard (in the hand, over the lug).
  final bool toolOut;

  /// The joint glowing under load (0–1).
  final double heat;
  final Offset? heatAt;

  /// The lug was squeezed flat with pliers.
  final bool pliers;

  /// How the made crimp went wrong (drawn on the barrel), if it did.
  final LugKind? bad;
}

/// The wall, the pegboard and the bench's back edge (behind the trainee).
class CrimpWallPainter extends CustomPainter {
  const CrimpWallPainter({required this.geo, required this.toolOut, this.brushOut = false});
  final CrimpGeo geo;
  final bool toolOut;
  final bool brushOut;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final wb = geo.wallBottom;
    c.drawRect(
        Rect.fromLTWH(0, 0, w, wb + 4),
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF51606E), Color(0xFF3C4854)])
              .createShader(Rect.fromLTWH(0, 0, w, wb)));
    // Wall panels and a high window with the yard's light.
    final seam = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 1.2;
    for (var x = 60.0; x < w; x += 90) {
      c.drawLine(Offset(x, 0), Offset(x, wb), seam);
    }
    final win = Rect.fromLTWH(30, geo.h * 0.13, 110, geo.h * 0.11);
    c.drawRRect(RRect.fromRectAndRadius(win.inflate(4), const Radius.circular(4)), Paint()..color = const Color(0xFF2A333C));
    c.drawRect(win, Paint()..shader = const LinearGradient(colors: [Color(0xFF9CC7E6), Color(0xFFD6ECF7)]).createShader(win));
    c.drawLine(win.topCenter, win.bottomCenter, Paint()..color = const Color(0xFF2A333C)..strokeWidth = 3);
    // The pegboard.
    final pb = geo.pegboard;
    c.drawRRect(RRect.fromRectAndRadius(pb, const Radius.circular(5)), Paint()..color = const Color(0xFFB98F5E));
    final hole = Paint()..color = const Color(0x553A2410);
    for (var y = pb.top + 10; y < pb.bottom - 4; y += 14) {
      for (var x = pb.left + 10; x < pb.right - 4; x += 14) {
        c.drawCircle(Offset(x, y), 1.6, hole);
      }
    }
    // The crimper on its hook (unless in the hand).
    if (!toolOut) paintCrimper(c, geo.pegCrimper, angle: math.pi / 2 - 0.25, scale: 0.62, press: 0);
    // The wire brush and the paste tube on hooks.
    if (!brushOut) _brush(c, Offset(pb.left + 96, pb.top + pb.height * 0.42), 0.9);
    _tube(c, Offset(pb.left + 126, pb.top + pb.height * 0.62));
    // The bench's back edge.
    c.drawRect(Rect.fromLTWH(0, wb, w, 6), Paint()..color = const Color(0xFF6A4A2C));
  }

  @override
  bool shouldRepaint(CrimpWallPainter old) => old.geo != geo || old.toolOut != toolOut || old.brushOut != brushOut;
}

void _brush(Canvas c, Offset at, double s) {
  c.save();
  c.translate(at.dx, at.dy);
  c.scale(s);
  c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-4, -30, 8, 34), const Radius.circular(3)), Paint()..color = const Color(0xFF8A4B22));
  c.drawRect(const Rect.fromLTWH(-7, 4, 14, 14), Paint()..color = const Color(0xFF6E6E6E));
  final bristle = Paint()
    ..color = const Color(0xFFD9D2C3)
    ..strokeWidth = 1;
  for (var x = -6.0; x <= 6; x += 2) {
    c.drawLine(Offset(x, 18), Offset(x, 25), bristle);
  }
  c.restore();
}

void _tube(Canvas c, Offset at) {
  final body = Rect.fromCenter(center: at, width: 12, height: 34);
  c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(3)), Paint()..color = const Color(0xFFE2E6EA));
  c.drawRect(Rect.fromLTWH(body.left, body.top + 10, 12, 10), Paint()..color = const Color(0xFF2B6CB0));
  c.drawRect(Rect.fromCenter(center: body.bottomCenter + const Offset(0, 4), width: 6, height: 8), Paint()..color = const Color(0xFF333B44));
}

/// A hand crimper (ratchet type): the die head round [head], the two long
/// handles behind it along [angle]; [press] closes the jaws.
void paintCrimper(Canvas c, Offset head, {required double angle, required double scale, required double press, int? die}) {
  c.save();
  c.translate(head.dx, head.dy);
  c.rotate(angle);
  c.scale(scale);
  final steel = Paint()..shader = const LinearGradient(colors: [Color(0xFF8E99A4), Color(0xFF4D5863)]).createShader(const Rect.fromLTWH(-30, -30, 60, 60));
  final grip = Paint()..color = const Color(0xFFC0392B);
  final open = 1 - press.clamp(0.0, 1.0);
  // The handles (red grips), opening as the jaws open.
  for (final side in [-1.0, 1.0]) {
    final spread = side * (10 + 18 * open);
    final p = Path()
      ..moveTo(18, side * 8)
      ..lineTo(120, spread)
      ..lineTo(120, spread + side * 9)
      ..lineTo(18, side * 17);
    c.drawPath(p, steel);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(70, math.min(spread, spread + side * 9) - 1, 124, math.max(spread, spread + side * 9) + 1), const Radius.circular(4)), grip);
  }
  // The head: two jaws (the die halves) round the barrel.
  final gap = 6 + 10 * open;
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(-26, -30 - gap / 2, 26, -gap / 2), const Radius.circular(6)), steel);
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(-26, gap / 2, 26, 30 + gap / 2), const Radius.circular(6)), steel);
  c.drawCircle(const Offset(20, 0), 5, Paint()..color = const Color(0xFF2E353C));
  if (die != null) {
    // The die halves (brass) seated in the jaws.
    final brass = Paint()..color = const Color(0xFFD9A441);
    c.drawRect(Rect.fromLTRB(-14, -10 - gap / 2, 14, -gap / 2), brass);
    c.drawRect(Rect.fromLTRB(-14, gap / 2, 14, 10 + gap / 2), brass);
  }
  c.restore();
}

/// The bench in front: its top, the cable and lug (a make-round) or the four
/// crimped lugs (the tray), the die rack, the tool in the hand, the glow.
class CrimpBenchPainter extends CustomPainter {
  const CrimpBenchPainter({required this.geo, required this.view});
  final CrimpGeo geo;
  final CrimpView view;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final top = geo.wallBottom + 6;
    final front = geo.benchFront;
    // The bench top (wood) and its front, then the workshop floor.
    c.drawRect(
        Rect.fromLTRB(0, top, w, front),
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFA9794A), Color(0xFF8C5F35)])
              .createShader(Rect.fromLTRB(0, top, w, front)));
    final grain = Paint()
      ..color = const Color(0x1F3A2410)
      ..strokeWidth = 1;
    for (var y = top + 12; y < front; y += 17) {
      c.drawLine(Offset(0, y), Offset(w, y + 3), grain);
    }
    c.drawRect(Rect.fromLTRB(0, front, w, front + 26), Paint()..color = const Color(0xFF5E3D20));
    c.drawRect(
        Rect.fromLTRB(0, front + 26, w, size.height),
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2F3740), Color(0xFF1C2228)])
              .createShader(Rect.fromLTRB(0, front + 26, w, size.height)));
    final job = view.job;
    if (job != null) {
      _make(c, job);
    } else {
      for (final (i, k) in view.lugs.indexed) {
        paintTrayLug(c, geo.trayAt(i), k);
      }
      final at = view.heatAt;
      if (view.heat > 0 && at != null) paintHeat(c, at, view.heat);
    }
  }

  void _make(Canvas c, CrimpJob job) {
    final y = geo.cableY;
    final cr = geo.cableR(job.size);
    final br = geo.barrelR(job.size);
    final metal = job.al ? const [Color(0xFFE4E8EC), Color(0xFF9AA4AD)] : const [Color(0xFFF0A86A), Color(0xFFB0602C)];
    final tug = math.sin(view.pull * math.pi) * 8;
    // The insulation (black), printed with its size; cut back at the mark.
    final stripAt = view.stripped ? geo.markX(1) : CrimpGeo.tipX;
    final ins = Rect.fromLTRB(-4, y - cr, stripAt, y + cr);
    c.drawRRect(
        RRect.fromRectAndCorners(ins, topRight: const Radius.circular(3), bottomRight: const Radius.circular(3)),
        Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3A3F45), Color(0xFF0E1013)]).createShader(ins));
    _text(c, CrimpLines.cablePrint(job), Offset(72, y), 9.5, const Color(0xFFE8E8E8));
    // The bare conductor (strands), dull until brushed, a grey film of paste.
    if (view.stripped) {
      final cond = Rect.fromLTRB(stripAt, y - br + 2.5, CrimpGeo.tipX, y + br - 2.5);
      c.drawRect(cond, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: metal).createShader(cond));
      final strand = Paint()
        ..color = const Color(0x55000000)
        ..strokeWidth = 0.8;
      for (var k = -2; k <= 2; k++) {
        c.drawLine(Offset(cond.left, y + k * (br - 3) / 2.5), Offset(cond.right, y + k * (br - 3) / 2.5 + 1), strand);
      }
      final clean = view.cleaned ? 1.0 : view.brush;
      if (clean < 1) {
        // Oxide and grime, wiped off left to right by the brush.
        final dirtFrom = cond.left + cond.width * clean;
        c.drawRect(Rect.fromLTRB(dirtFrom, cond.top, cond.right, cond.bottom), Paint()..color = const Color(0x99544B3A));
      }
      if (view.pasted) c.drawRect(cond, Paint()..color = const Color(0x5578828C));
      if (view.brush > 0 && view.brush < 1) _brush(c, Offset(cond.left + cond.width * view.brush, y - 26), 0.9);
    }
    // The strip marks. No measuring lug is laid against them (it would sit on
    // the right mark): the real lug rests past the tip, and the player
    // compares its barrel with the marks by eye.
    if (view.showMarks && !view.stripped) {
      for (final m in job.marks) {
        final x = geo.markX(m);
        c.drawLine(Offset(x, y - cr - 3), Offset(x, y + cr + 3), Paint()..color = const Color(0xFFFFFFFF)..strokeWidth = 2.2);
      }
    }
    // The lug: on the conductor as far as it is in; pulled with the tug.
    final mouth = geo.mouthAt(view.inserted) + tug;
    _lug(c, mouth, y, br, job, crimped: view.crimped || view.bad != null, bad: view.bad, flat: view.pliers);
    // The die rack.
    if (view.showDies) {
      for (final (i, d) in job.dies.indexed) {
        final at = geo.dieAt(i);
        final r = Rect.fromCenter(center: at, width: 46, height: 30);
        c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(5)),
            Paint()..shader = const LinearGradient(colors: [Color(0xFFE7C066), Color(0xFFB8862C)]).createShader(r));
        c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(5)), Paint()..color = const Color(0xFF6E4E14)..style = PaintingStyle.stroke..strokeWidth = 1.4);
        c.drawCircle(at + const Offset(0, -6), 4.5, Paint()..color = const Color(0xFF6E4E14));
        _text(c, CrimpLines.dieBn(d), at + const Offset(0, 7), 10, const Color(0xFF2A1C05));
        if (view.die == d) {
          c.drawRRect(RRect.fromRectAndRadius(r.inflate(4), const Radius.circular(7)), Paint()..color = const Color(0xFFFFF3C4)..style = PaintingStyle.stroke..strokeWidth = 2.2);
        }
      }
    }
    // The crimper in the hand: over the barrel, handles down to the right.
    if (view.toolOut) {
      final head = view.onBarrel ? geo.barrelSpot : Offset(geo.barrelSpot.dx + 40, y - 70);
      paintCrimper(c, head, angle: 0.95, scale: 0.78, press: view.press, die: view.die);
    }
    if (view.heat > 0) paintHeat(c, view.heatAt ?? Offset(mouth + CrimpGeo.barrel / 2, y), view.heat);
  }

  void _lug(Canvas c, double mouth, double y, double br, CrimpJob job, {bool crimped = false, LugKind? bad, bool flat = false}) {
    final metal = job.al ? [const Color(0xFFDDE2E6), const Color(0xFF8D979F)] : [const Color(0xFFE8ECEF), const Color(0xFFA9B0B6)];
    paintLug(c, Rect.fromLTWH(mouth, y - br, CrimpGeo.barrel + CrimpGeo.palm, br * 2), metal, kind: crimped ? (bad ?? LugKind.good) : null, flat: flat, label: CrimpLines.mm(job.size));
  }

  @override
  bool shouldRepaint(CrimpBenchPainter old) => old.geo != geo || old.view != view;
}

/// A lug in [r] (barrel left, palm right with its bolt hole). [kind]: how it
/// was crimped (null = not yet).
void paintLug(Canvas c, Rect r, List<Color> metal, {double opacity = 1, LugKind? kind, bool flat = false, String? label}) {
  final bw = r.width * CrimpGeo.barrel / (CrimpGeo.barrel + CrimpGeo.palm);
  final y = r.center.dy;
  final h = r.height;
  final layer = opacity < 1;
  if (layer) c.saveLayer(r.inflate(20), Paint()..color = Color.fromRGBO(0, 0, 0, opacity));
  final shade = Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: metal).createShader(r);
  final edge = Paint()
    ..color = const Color(0xFF4A535B)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;
  final squash = flat || kind == LugKind.pliers;
  // The barrel (a tube; squashed flat by pliers).
  final barrel = squash
      ? (Path()
          ..moveTo(r.left, y - h / 2)
          ..lineTo(r.left + bw * 0.3, y - h * 0.32)
          ..lineTo(r.left + bw * 0.55, y - h * 0.22)
          ..lineTo(r.left + bw * 0.8, y - h * 0.36)
          ..lineTo(r.left + bw, y - h * 0.3)
          ..lineTo(r.left + bw, y + h * 0.3)
          ..lineTo(r.left + bw * 0.7, y + h * 0.18)
          ..lineTo(r.left + bw * 0.4, y + h * 0.34)
          ..lineTo(r.left, y + h / 2)
          ..close())
      : (Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.left, y - h / 2, bw, h), const Radius.circular(3))));
  c.drawPath(barrel, shade);
  c.drawPath(barrel, edge);
  // The palm: flat, with the bolt hole.
  final palm = RRect.fromRectAndCorners(Rect.fromLTWH(r.left + bw, y - h * 0.3, r.width - bw, h * 0.6),
      topRight: Radius.circular(h * 0.3), bottomRight: Radius.circular(h * 0.3));
  c.drawRRect(palm, shade);
  c.drawRRect(palm, edge);
  c.drawCircle(Offset(r.right - h * 0.3, y), h * 0.15, Paint()..color = const Color(0xFF3A2410));
  if (label != null && kind == null) _text(c, label, Offset(r.left + bw * 0.5, y), 9, const Color(0xFF2B3036));
  // The crimp marks.
  final dent = Paint()..color = const Color(0x664A535B);
  final mark = Paint()
    ..color = const Color(0xFF59636C)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;
  switch (kind) {
    case null:
      break;
    case LugKind.good || LugKind.strands || LugKind.cracked:
      // Hexagonal: a smooth even band, the die's flats clear.
      final band = Rect.fromLTWH(r.left + bw * 0.22, y - h / 2, bw * 0.56, h);
      c.drawRect(band, dent);
      for (final k in [-0.33, 0.0, 0.33]) {
        c.drawLine(Offset(band.left, y + k * h), Offset(band.right, y + k * h), mark);
      }
      c.drawRect(band, mark);
      if (kind == LugKind.cracked) {
        final crack = Paint()
          ..color = const Color(0xFF1A1E22)
          ..strokeWidth = 1.6
          ..style = PaintingStyle.stroke;
        c.drawPath(
            Path()
              ..moveTo(band.left + 6, y - h / 2)
              ..lineTo(band.left + 12, y - h * 0.15)
              ..lineTo(band.left + 7, y + h * 0.05)
              ..lineTo(band.left + 15, y + h * 0.4),
            crack);
      }
      if (kind == LugKind.strands) {
        final s = Paint()
          ..color = const Color(0xFFB0602C)
          ..strokeWidth = 1.3
          ..strokeCap = StrokeCap.round;
        for (final (dx, dy) in [(-9.0, -h * 0.62), (-12.0, -h * 0.4), (-8.0, h * 0.55), (-13.0, h * 0.25)]) {
          c.drawLine(Offset(r.left + 1, y + dy * 0.5), Offset(r.left + dx, y + dy), s);
        }
      }
    case LugKind.under:
      // A shallow, lopsided dent: the die's marks hardly show.
      c.drawPath(
          Path()
            ..moveTo(r.left + bw * 0.25, y - h / 2)
            ..quadraticBezierTo(r.left + bw * 0.5, y - h * 0.38, r.left + bw * 0.72, y - h / 2),
          mark);
      c.drawLine(Offset(r.left + bw * 0.35, y + h / 2), Offset(r.left + bw * 0.6, y + h * 0.44), mark);
    case LugKind.pliers:
      // Jagged bite marks.
      for (final x in [0.3, 0.5, 0.7]) {
        c.drawLine(Offset(r.left + bw * x, y - h * 0.3), Offset(r.left + bw * x + 3, y - h * 0.12), mark);
        c.drawLine(Offset(r.left + bw * x + 2, y + h * 0.3), Offset(r.left + bw * x - 1, y + h * 0.12), mark);
      }
  }
  if (layer) c.restore();
}

/// One crimped lug on the inspection tray, with a short cable tail.
void paintTrayLug(Canvas c, Offset at, LugKind k) {
  const s = CrimpGeo.traySize;
  final r = Rect.fromCenter(center: at, width: s.width, height: s.height);
  const h = 20.0;
  final tail = Rect.fromLTRB(r.left, at.dy - h / 2 - 1.5, r.left + 44, at.dy + h / 2 + 1.5);
  c.drawRRect(RRect.fromRectAndCorners(tail, topRight: const Radius.circular(3), bottomRight: const Radius.circular(3)), Paint()..color = const Color(0xFF16191C));
  // A paper card under each lug.
  c.drawRRect(RRect.fromRectAndRadius(r.inflate(2), const Radius.circular(6)), Paint()..color = const Color(0x22FFFFFF));
  paintLug(c, Rect.fromLTWH(tail.right, at.dy - h / 2, r.width - 46, h), const [Color(0xFFE8ECEF), Color(0xFFA9B0B6)], kind: k);
}

/// The joint glowing hot under load: a red-orange core, a heat haze and a
/// thin curl of smoke.
void paintHeat(Canvas c, Offset at, double v) {
  final k = Curves.easeOut.transform(v.clamp(0.0, 1.0));
  final r = 16 + 30 * k;
  c.drawCircle(
      at,
      r,
      Paint()
        ..shader = RadialGradient(colors: [
          Color.fromRGBO(255, 240, 170, 0.95 * k),
          Color.fromRGBO(255, 120, 30, 0.75 * k),
          const Color(0x00FF3B1F),
        ], stops: const [0.0, 0.45, 1.0])
            .createShader(Rect.fromCircle(center: at, radius: r)));
  final haze = Paint()
    ..color = Color.fromRGBO(255, 170, 90, 0.5 * k)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6
    ..strokeCap = StrokeCap.round;
  for (var i = -1; i <= 1; i++) {
    final x = at.dx + i * 10;
    final p = Path()..moveTo(x, at.dy - 14);
    for (var j = 1; j <= 4; j++) {
      p.quadraticBezierTo(x + (j.isEven ? 5 : -5), at.dy - 14 - j * 7 + 3, x, at.dy - 14 - j * 7);
    }
    c.drawPath(p, haze);
  }
  final smoke = Paint()..color = Color.fromRGBO(120, 120, 120, 0.35 * k);
  for (var i = 0; i < 4; i++) {
    c.drawCircle(at + Offset(4.0 * math.sin(i + v * 4), -30 - i * 11 - 14 * k), 5 + i * 2.2, smoke);
  }
}

void _text(Canvas c, String s, Offset centre, double size, Color color) {
  final tp = TextPainter(
    text: TextSpan(text: s, style: TextStyle(fontFamily: 'Roboto', fontSize: size, fontWeight: FontWeight.w800, color: color)),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
}
