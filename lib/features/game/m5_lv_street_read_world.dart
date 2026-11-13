import 'dart:math' as math;

import 'package:flutter/material.dart';

// The drawn world of lesson 5.5 কাজ 1 "ড্রপ কোথায়?" (m5_lv_street_read.dart):
// an evening street. A pole-mounted distribution transformer stands at the
// left end with its LTDB box at ground level; the LT line (R, Y, B and the
// neutral) runs to the right on six poles, numbered P1–P6 on their plates and
// with R/Y/B tags at the cross-arm. Ten houses with veranda meter boards take
// their service drops off the line: five behind the line (each fed by the pole
// on its left), five in front of it (each fed by the pole above it). Every
// house is shuttered alike and every meter board looks the same — nothing in
// the picture says which house has low voltage (the player has to ask and
// measure). No text in the art except the pole plates and the tags a worker
// reads. Code-drawn, gradients, no bitmaps.
//
// Design: 360 wide × the scene's height; the street follows the bottom of the
// screen (a tall phone gets more evening sky, never a stretched street).

/// Where things are (design px, 360 wide).
@immutable
class M5LvGeo {
  const M5LvGeo._(this.height, this.groundY);

  factory M5LvGeo.forScene(double height, double inset) => M5LvGeo._(height, height - floorFor(height) - inset * 0.5);

  final double height;

  /// The front edge of the near row of houses (the street's bottom line).
  final double groundY;

  /// The street ends this far above the bottom: the controls, the corner
  /// guide and his bubble stand on the verge under it, clear of the houses
  /// (a short phone gives the verge a little less).
  static double floorFor(double height) => (height * 0.36).clamp(210.0, 280.0);

  static const int houses = 10;
  static const int poles = 6;

  /// Pole [p] (1–6) stands at this x.
  static double poleX(int p) => 40 + 58.0 * (p - 1);

  /// The pole that feeds house [h] (0–4 behind the line, 5–9 in front).
  static int poleOf(int h) => h < 5 ? h + 1 : h - 3;

  /// Behind the line (the far row).
  static bool farRow(int h) => h < 5;

  double get roadTop => groundY - 120;
  double get roadBottom => groundY - 74;
  double get poleBase => groundY - 116;
  double get poleTop => groundY - 268;
  double get armY => poleTop + 10;

  /// The four wires (R, Y, B, N) between the poles.
  List<double> get wireY => [armY - 3, armY + 3, armY + 9, armY + 17];

  /// House [h]'s outline (its whole front is the tap area).
  Rect house(int h) {
    if (farRow(h)) {
      final cx = poleX(h + 1) + 29;
      return Rect.fromLTRB(cx - 23, groundY - 190, cx + 23, groundY - 126);
    }
    final cx = poleX(h - 3);
    return Rect.fromLTRB(cx - 25, groundY - 66, cx + 25, groundY);
  }

  /// The meter board on house [h]'s veranda.
  Rect meter(int h) {
    final r = house(h);
    return Rect.fromLTWH(r.left + 6, r.bottom - 26, 11, 14);
  }

  /// The transformer at the street's left end and its LTDB at ground level.
  Rect get dtr => Rect.fromLTWH(4, poleTop + 34, 26, 30);
  Rect get ltdb => Rect.fromLTWH(5, groundY - 156, 24, 30);

  /// Where the trainee stands (a 26 × 52 box): by the LTDB, by house [h], or
  /// on the road in the middle of the street.
  Rect get atLtdb => Rect.fromLTWH(26, roadTop - 6, 26, 52);
  Rect get onRoad => Rect.fromLTWH(167, roadTop - 4, 26, 52);
  Rect byHouse(int h) {
    final r = house(h);
    final x = (r.left + 18).clamp(4.0, 330.0);
    return farRow(h) ? Rect.fromLTWH(x, roadTop - 8, 26, 52) : Rect.fromLTWH(x, roadBottom - 44, 26, 52);
  }

  /// An empty spot on the road (the "tap" hint goes there, never on a house).
  Offset get roadSpot => Offset(184, (roadTop + roadBottom) / 2);

  /// The flash of a live tap change (at the transformer).
  Offset get flashAt => dtr.center;

  @override
  bool operator ==(Object other) => other is M5LvGeo && other.height == height && other.groundY == groundY;

  @override
  int get hashCode => Object.hash(height, groundY);
}

const _wire = Color(0xFF2B3036);
const _poleCol = Color(0xFF8A8F96);
const _phaseCols = [Color(0xFFD9443A), Color(0xFFE8C23A), Color(0xFF3A6FD9)];

/// The static street (sky, houses, line, transformer). Repaints only when the
/// scene's size changes.
class M5LvStreetPainter extends CustomPainter {
  const M5LvStreetPainter({required this.geo, required this.seed});

  final M5LvGeo geo;
  final int seed;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    final rnd = math.Random(seed);
    // Evening sky.
    final sky = Rect.fromLTWH(0, 0, w, g.roadTop);
    c.drawRect(
        sky,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF16213F), Color(0xFF3B3F6B), Color(0xFFB0626A), Color(0xFFE59A62)],
            stops: [0, 0.45, 0.8, 1],
          ).createShader(sky));
    final star = Paint()..color = const Color(0x99FFFFFF);
    for (var i = 0; i < 14; i++) {
      c.drawCircle(Offset(rnd.nextDouble() * w, 20 + rnd.nextDouble() * (g.poleTop - 60).clamp(40.0, 400.0)), 0.9 + rnd.nextDouble() * 0.6, star);
    }
    // Far roofs and trees (a silhouette).
    final far = Paint()..color = const Color(0xFF2A2C45);
    final horizon = g.groundY - 196;
    final skyline = Path()..moveTo(0, horizon);
    for (var x = 0.0; x < w + 30; x += 24 + rnd.nextDouble() * 18) {
      final hgt = 10 + rnd.nextDouble() * 22;
      skyline
        ..lineTo(x, horizon - hgt)
        ..lineTo(x + 12, horizon - hgt - 8)
        ..lineTo(x + 24, horizon - hgt);
    }
    skyline
      ..lineTo(w, horizon)
      ..close();
    c.drawPath(skyline, far);
    c.drawRect(Rect.fromLTRB(0, horizon, w, g.roadTop), Paint()..color = const Color(0xFF3A3A4E));
    // The far row of houses (behind the line).
    for (var h = 0; h < 5; h++) {
      _house(c, g.house(h), h);
    }
    // The road.
    final road = Rect.fromLTRB(0, g.roadTop, w, g.roadBottom);
    c.drawRect(road, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF4A4A55), Color(0xFF34343D)]).createShader(road));
    final dash = Paint()
      ..color = const Color(0x66E8E2D0)
      ..strokeWidth = 2;
    for (var x = 8.0; x < w; x += 30) {
      c.drawLine(Offset(x, (g.roadTop + g.roadBottom) / 2), Offset(x + 14, (g.roadTop + g.roadBottom) / 2), dash);
    }
    // The near verge and the near row's yards.
    final verge = Rect.fromLTRB(0, g.roadBottom, w, size.height);
    c.drawRect(verge, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF4E5A3A), Color(0xFF2E3524)]).createShader(verge));
    // The transformer, its two poles and the LTDB box at its foot.
    _transformer(c, g);
    // Poles and the line.
    _line(c, g, w);
    // Service drops (no phase colour: the drop does not say its phase).
    final drop = Paint()
      ..color = const Color(0xCC1E2226)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (var h = 0; h < M5LvGeo.houses; h++) {
      final px = M5LvGeo.poleX(M5LvGeo.poleOf(h));
      final r = g.house(h);
      final to = M5LvGeo.farRow(h) ? Offset(r.left + 6, r.top + 14) : Offset(r.center.dx, r.top + 6);
      final from = Offset(px, g.armY + 6);
      c.drawPath(
          Path()
            ..moveTo(from.dx, from.dy)
            ..quadraticBezierTo((from.dx + to.dx) / 2, math.max(from.dy, to.dy) + 8, to.dx, to.dy),
          drop);
    }
    // The near row (in front of the line).
    for (var h = 5; h < 10; h++) {
      _house(c, g.house(h), h);
    }
  }

  void _house(Canvas c, Rect r, int h) {
    const walls = [Color(0xFFB98F6A), Color(0xFFA6A08A), Color(0xFFB7A27A), Color(0xFF9E8D7C), Color(0xFFAE9374)];
    final wall = walls[(h * 3 + seed) % walls.length];
    final roofH = r.height * 0.3;
    final body = Rect.fromLTRB(r.left + 2, r.top + roofH, r.right - 2, r.bottom);
    c.drawRect(
        body,
        Paint()
          ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [wall, Color.lerp(wall, Colors.black, 0.35)!])
              .createShader(body));
    c.drawPath(
        Path()
          ..moveTo(r.left - 2, r.top + roofH)
          ..lineTo(r.center.dx, r.top)
          ..lineTo(r.right + 2, r.top + roofH)
          ..close(),
        Paint()..color = const Color(0xFF5B3A2C));
    // Shutters, closed alike on every house (no lit or dim window to read).
    final shutter = Paint()..color = const Color(0xFF4C5A5E);
    final slat = Paint()
      ..color = const Color(0x55000000)
      ..strokeWidth = 1;
    final sw = (body.width - 14) / 2;
    for (final x in [body.left + 4, body.left + 10 + sw]) {
      final s = Rect.fromLTWH(x, body.top + 5, sw, body.height * 0.34);
      c.drawRect(s, shutter);
      for (var y = s.top + 3; y < s.bottom; y += 3) {
        c.drawLine(Offset(s.left, y), Offset(s.right, y), slat);
      }
    }
    // Door and veranda.
    c.drawRect(Rect.fromLTWH(body.center.dx + 2, body.bottom - body.height * 0.42, 10, body.height * 0.42), Paint()..color = const Color(0xFF3A2A22));
    c.drawRect(Rect.fromLTWH(body.left - 2, body.bottom - 3, body.width + 4, 3), Paint()..color = const Color(0xFF6E6658));
    // The meter board (the same on every house).
    final m = Rect.fromLTWH(r.left + 6, r.bottom - 26, 11, 14);
    c.drawRRect(RRect.fromRectAndRadius(m, const Radius.circular(1.5)), Paint()..color = const Color(0xFFDCD6C8));
    c.drawRect(Rect.fromLTWH(m.left + 2, m.top + 2, 7, 4), Paint()..color = const Color(0xFF2E3A40));
    c.drawCircle(Offset(m.center.dx, m.bottom - 3.5), 1.6, Paint()..color = const Color(0xFF7C8186));
  }

  void _transformer(Canvas c, M5LvGeo g) {
    final pole = Paint()
      ..color = _poleCol
      ..strokeWidth = 3;
    c.drawLine(Offset(7, g.poleTop + 8), Offset(7, g.poleBase), pole);
    c.drawLine(Offset(27, g.poleTop + 8), Offset(27, g.poleBase), pole);
    c.drawRect(Rect.fromLTWH(2, g.dtr.bottom, 30, 3), Paint()..color = const Color(0xFF5E636A));
    final tank = g.dtr;
    c.drawRRect(
        RRect.fromRectAndRadius(tank, const Radius.circular(3)),
        Paint()
          ..shader = const LinearGradient(colors: [Color(0xFF7D8A80), Color(0xFF4E5A52)]).createShader(tank));
    for (var i = 0; i < 4; i++) {
      c.drawLine(Offset(tank.left + 4 + i * 6, tank.top + 4), Offset(tank.left + 4 + i * 6, tank.bottom - 4), Paint()..color = const Color(0x553A403C));
    }
    for (final x in [tank.left + 6, tank.center.dx, tank.right - 6]) {
      c.drawRect(Rect.fromLTWH(x - 1.5, tank.top - 7, 3, 7), Paint()..color = const Color(0xFFC9B48A));
    }
    // LT cable down to the LTDB.
    c.drawLine(Offset(tank.right - 4, tank.bottom), Offset(g.ltdb.right - 6, g.ltdb.top), Paint()
      ..color = _wire
      ..strokeWidth = 2);
    final box = g.ltdb;
    c.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(2)), Paint()..color = const Color(0xFF8E9399));
    c.drawRect(Rect.fromLTWH(box.left + 3, box.top + 4, box.width - 6, box.height - 8), Paint()..color = const Color(0xFF6B7076));
    c.drawLine(Offset(box.center.dx, box.bottom), Offset(box.center.dx, g.poleBase), Paint()
      ..color = _poleCol
      ..strokeWidth = 2);
    // Out to P1.
    for (var k = 0; k < 4; k++) {
      c.drawLine(Offset(tank.right, tank.top + 6 + k * 3), Offset(M5LvGeo.poleX(1), g.wireY[k]), Paint()
        ..color = _wire
        ..strokeWidth = 1.2);
    }
  }

  void _line(Canvas c, M5LvGeo g, double w) {
    final pole = Paint()
      ..shader = const LinearGradient(colors: [Color(0xFF9EA3AA), Color(0xFF6E737A)]).createShader(Rect.fromLTWH(0, g.poleTop, 4, g.poleBase - g.poleTop))
      ..strokeWidth = 4;
    final wire = Paint()
      ..color = _wire
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (var p = 1; p < M5LvGeo.poles; p++) {
      final a = M5LvGeo.poleX(p);
      final b = M5LvGeo.poleX(p + 1);
      for (final y in g.wireY) {
        c.drawPath(
            Path()
              ..moveTo(a, y)
              ..quadraticBezierTo((a + b) / 2, y + 5, b, y),
            wire);
      }
    }
    for (var p = 1; p <= M5LvGeo.poles; p++) {
      final x = M5LvGeo.poleX(p);
      c.drawLine(Offset(x, g.poleTop), Offset(x, g.poleBase), pole);
      c.drawRect(Rect.fromLTWH(x - 13, g.armY - 6, 26, 3), Paint()..color = const Color(0xFF5E636A));
      // R/Y/B tags on the cross-arm, the neutral below.
      for (var k = 0; k < 3; k++) {
        c.drawCircle(Offset(x - 9 + k * 9, g.armY - 7), 2.4, Paint()..color = _phaseCols[k]);
      }
      // The pole's number plate.
      final plate = Rect.fromLTWH(x - 9, g.poleBase - 46, 18, 11);
      c.drawRRect(RRect.fromRectAndRadius(plate, const Radius.circular(2)), Paint()..color = const Color(0xFFEDE8D8));
      final tp = TextPainter(
        text: TextSpan(text: 'P$p', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w900, color: Color(0xFF1E2430), height: 1)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(c, Offset(plate.center.dx - tp.width / 2, plate.center.dy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(M5LvStreetPainter old) => old.geo != geo || old.seed != seed;
}

/// A live tap change: the transformer flashes (in colour over the grey scene).
class M5LvFlashPainter extends CustomPainter {
  const M5LvFlashPainter({required this.geo, required this.v});
  final M5LvGeo geo;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final at = geo.flashAt;
    final r = 18 + 60 * v;
    c.drawCircle(at, r, Paint()..color = Color.fromRGBO(255, 236, 160, (0.85 * (1 - v * 0.6)).clamp(0, 1)));
    c.drawCircle(at, r * 0.45, Paint()..color = Color.fromRGBO(255, 255, 255, (1 - v * 0.5).clamp(0, 1)));
    final bolt = Paint()
      ..color = const Color(0xFFFFF2B0)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;
    for (var k = 0; k < 6; k++) {
      final a = k * math.pi / 3 + 0.3;
      final p = Path()..moveTo(at.dx, at.dy);
      var cur = at;
      for (var s = 1; s <= 3; s++) {
        cur = at + Offset(math.cos(a + (s.isOdd ? 0.25 : -0.25)), math.sin(a + (s.isOdd ? 0.25 : -0.25))) * (r * 0.4 * s);
        p.lineTo(cur.dx, cur.dy);
      }
      c.drawPath(p, bolt);
    }
  }

  @override
  bool shouldRepaint(M5LvFlashPainter old) => old.v != v || old.geo != geo;
}
