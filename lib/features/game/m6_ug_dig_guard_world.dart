import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The drawn world of lesson 6.5 কাজ 2 "খোঁড়ার আগে কেবিলের পথ"
// (m6_ug_dig_guard.dart): a town street seen from a high front angle in the
// daytime. Houses stand along the far footpath; the 11 kV riser pole stands on
// it at the right — the line comes over its cross-arm, the UG cable's end
// termination sits under the arm and the cable runs down the pole into the
// ground at its foot. Across the road, on the near footpath at the left, the
// DTR stands on its concrete plinth; its cable goes back into the ground at
// the plinth's right foot. Two or three identical, unlabelled iron covers lie
// on the road and footpaths: one or two hide a cable joint, one hides a
// drain (lift a cover to see). No route paint, no labels, no text in the art.
//
// The player's chalk legs (straight between the anchors he tapped, the turns
// drawn gently round — ruling M6-7, IS 1255 cl 5.3: never a sharp corner),
// or after a wrong peg the true route; in the dig stage three identical chalk
// circles and the excavator (its own painter, driven by the descent).
//
// Design: 360 wide × the scene's height; the ground follows the bottom of the
// screen (a tall phone gets more sky and a wider road, never stretched).
// Code-drawn, gradients, no bitmaps.

/// What a close look shows (unscored): the pole-top termination, or the
/// cable going into the DTR's plinth.
enum M6Look { termination, dtrEntry }

/// Anchor ids on the street: the pole foot, the DTR entry; a cover is its
/// own index (0, 1, 2).
const int kM6Pole = -1;
const int kM6Dtr = -2;

/// Where things are (design px, 360 wide).
@immutable
class M6DigGeo {
  const M6DigGeo._(this.height, this.groundY, this.roadTop, this.roadBottom);

  factory M6DigGeo.forScene(double height, double inset) {
    final g = height - floorUp - inset * 0.5;
    final roadH = (height - 390).clamp(170.0, 230.0);
    final rb = g - 40;
    return M6DigGeo._(height, g, rb - roadH, rb);
  }

  final double height;

  /// The near footpath's front edge (the controls stand under it).
  final double groundY;

  /// The road's far and near kerbs.
  final double roadTop;
  final double roadBottom;

  /// The ground sits this far above the bottom (the buttons stand under it).
  static const double floorUp = 112;

  /// The far footpath's back edge (the houses stand on it).
  double get farTop => roadTop - 44;

  /// The riser pole on the far footpath (right).
  static const double poleX = 300;
  Offset get poleFoot => Offset(poleX, roadTop - 20);
  double get poleTopY => math.max(132.0, poleFoot.dy - 150);

  /// The cable's end termination under the cross-arm (a look).
  Offset get riserTop => Offset(poleX, poleTopY + 18);
  Rect get riserHit => Rect.fromCenter(center: riserTop, width: 46, height: 40);
  Rect get poleFootHit => Rect.fromCenter(center: poleFoot, width: 44, height: 36);

  /// The DTR on its plinth (near footpath, left) and where its cable goes
  /// back into the ground.
  Rect get plinth => Rect.fromLTWH(18, roadBottom + 6, 84, 26);
  Rect get dtrBox => Rect.fromLTWH(30, plinth.top - 60, 60, 58);
  Offset get dtrEntry => Offset(plinth.right + 16, roadBottom + 16);
  Rect get dtrEntryHit => Rect.fromCenter(center: dtrEntry, width: 40, height: 34);

  /// An iron cover (drawn and hit).
  static const double coverW = 32;
  static const double coverH = 24;
  Rect coverRect(Offset c) => Rect.fromCenter(center: c, width: coverW, height: coverH);
  Rect coverHit(Offset c) => Rect.fromCenter(center: c, width: 44, height: 40);

  /// A chalk dig circle.
  static const double spotR = 16;

  /// The look card (top left, under the header).
  static const Rect card = Rect.fromLTWH(6, 122, 134, 90);

  /// Where the trainee stands (near footpath, clear of the anchors).
  Rect get trainee => Rect.fromLTWH(164, groundY - 98, 42, 98);

  /// Places a cover or a dig circle may sit: on the street, clear of the
  /// guide and his bubble (bottom right), the DTR and the screen edges.
  bool free(Offset p, double r) {
    final x = p.dx, y = p.dy;
    if (x - r < 22 || x + r > 338) return false;
    // The guide's bubble (two short lines) and the guide himself.
    if (x + r > 140 && y + r > groundY - 150) return false;
    if (x - r < 112 && y + r > roadBottom - 64) return false;
    return true;
  }

  @override
  bool operator ==(Object other) => other is M6DigGeo && other.height == height && other.groundY == groundY;

  @override
  int get hashCode => Object.hash(height, groundY);
}

double _dist(Offset a, Offset b) => (a - b).distance;

/// The distance from [p] to the segment [a]–[b].
double m6SegDist(Offset p, Offset a, Offset b) {
  final d = b - a;
  final l = d.dx * d.dx + d.dy * d.dy;
  final t = l == 0 ? 0.0 : (((p.dx - a.dx) * d.dx + (p.dy - a.dy) * d.dy) / l).clamp(0.0, 1.0);
  return _dist(p, a + d * t);
}

/// The distance from [p] to the polyline [pts].
double m6PolyDist(Offset p, List<Offset> pts) {
  var best = double.infinity;
  for (var i = 0; i + 1 < pts.length; i++) {
    best = math.min(best, m6SegDist(p, pts[i], pts[i + 1]));
  }
  return best;
}

/// The turn at [b] (degrees of direction change from a→b to b→c).
double m6Turn(Offset a, Offset b, Offset c) {
  final v1 = b - a, v2 = c - b;
  final d = (v1.dx * v2.dx + v1.dy * v2.dy) / (v1.distance * v2.distance);
  return math.acos(d.clamp(-1.0, 1.0)) * 180 / math.pi;
}

/// Where the covers and the dig circles lie on one screen.
@immutable
class M6DigLayout {
  const M6DigLayout({required this.covers, required this.route, required this.spots, this.fallback = false});

  /// The covers by index (joints and the drain, positions).
  final List<Offset> covers;

  /// The true route: the pole foot, the joints in order, the DTR entry.
  final List<Offset> route;

  /// The dig circles in dig order.
  final List<Offset> spots;

  /// The fixed layout was used (the sampler found none; tests assert never).
  final bool fallback;
}

/// Lays the dealt street out on [geo]: the joints off the straight line
/// pole→DTR (at least one by 42 px, every turn ≤ 75° — a gentle bend), the
/// drain clear of the route (near the straight line when it can be, the
/// "straight across" trap), the circles on the route at its legs' middles or
/// clearly off it (≥ 56 px). Deterministic for a [seed] and screen.
M6DigLayout m6DigLayout({
  required int seed,
  required int drain,
  required List<int> jointRoute,
  required List<bool> onRoute,
  required M6DigGeo geo,
}) {
  final rng = math.Random(seed);
  for (var k = 0; k < 600; k++) {
    final l = _tryLayout(rng, drain, jointRoute, onRoute, geo);
    if (l != null) return l;
  }
  return _fixedLayout(drain, jointRoute, onRoute, geo);
}

M6DigLayout? _tryLayout(math.Random rng, int drain, List<int> jointRoute, List<bool> onRoute, M6DigGeo g) {
  double uni(double a, double b) => a + rng.nextDouble() * (b - a);
  final p = g.poleFoot, d = g.dtrEntry;
  final dir = d - p;
  final len = dir.distance;
  final n = Offset(dir.dy / len, -dir.dx / len);
  final joints = jointRoute.length;
  final js = <Offset>[];
  var far = 0.0;
  final yLo = g.roadTop - 28, yHi = g.roadBottom - 22;
  for (var k = 0; k < joints; k++) {
    final t = (k + 1) / (joints + 1) + uni(-0.1, 0.1);
    final o = uni(-90, 90);
    final j = p + dir * t + n * o;
    if (j.dy < yLo || j.dy > yHi || !g.free(j, 18)) return null;
    if (_dist(j, p) < 60 || _dist(j, d) < 60) return null;
    far = math.max(far, o.abs());
    js.add(j);
  }
  if (far < 42) return null;
  final route = [p, ...js, d];
  for (var i = 0; i + 1 < route.length; i++) {
    if (_dist(route[i], route[i + 1]) < 62) return null;
  }
  for (var i = 1; i + 1 < route.length; i++) {
    if (m6Turn(route[i - 1], route[i], route[i + 1]) > 75) return null;
  }
  for (var i = 0; i < js.length; i++) {
    for (var k = i + 1; k < js.length; k++) {
      if (_dist(js[i], js[k]) < 64) return null;
    }
  }
  Offset? dr;
  for (var k = 0; k < 120; k++) {
    final c = Offset(uni(30, 330), uni(yLo, yHi));
    if (!g.free(c, 18)) continue;
    if (m6PolyDist(c, route) < 46) continue;
    if (js.any((j) => _dist(c, j) < 64) || _dist(c, p) < 60 || _dist(c, d) < 60) continue;
    if (k < 80 && m6SegDist(c, p, d) > 44) continue;
    dr = c;
    break;
  }
  if (dr == null) return null;
  final covers = List<Offset>.filled(joints + 1, Offset.zero);
  covers[drain] = dr;
  for (final (i, ci) in jointRoute.indexed) {
    covers[ci] = js[i];
  }
  bool clearOf(Offset s, List<Offset> placed) =>
      g.free(s, 18) &&
      !covers.any((c) => _dist(s, c) < 40) &&
      _dist(s, p) >= 42 &&
      _dist(s, d) >= 42 &&
      !placed.any((q) => _dist(s, q) < 52) &&
      !g.trainee.inflate(18).contains(s);
  final sLo = g.roadTop - 28, sHi = g.roadBottom - 16;
  final on = <Offset>[], off = <Offset>[];
  final nOn = onRoute.where((x) => x).length;
  for (var k = 0; k < nOn; k++) {
    Offset? got;
    for (var a = 0; a < 60; a++) {
      final i = rng.nextInt(route.length - 1);
      final t = uni(0.3, 0.7);
      final s = Offset.lerp(route[i], route[i + 1], t)!;
      if (s.dy < sLo || s.dy > sHi || !clearOf(s, [...on, ...off])) continue;
      got = s;
      break;
    }
    if (got == null) return null;
    on.add(got);
  }
  for (var k = 0; k < onRoute.length - nOn; k++) {
    Offset? got;
    for (var a = 0; a < 80; a++) {
      final s = Offset(uni(30, 330), uni(sLo, sHi));
      if (m6PolyDist(s, route) < 56 || !clearOf(s, [...on, ...off])) continue;
      got = s;
      break;
    }
    if (got == null) return null;
    off.add(got);
  }
  var a = 0, b = 0;
  return M6DigLayout(covers: covers, route: route, spots: [for (final r in onRoute) r ? on[a++] : off[b++]]);
}

/// A plain layout for a screen the sampler could not fill (never seen in the
/// tests' seeds and heights).
M6DigLayout _fixedLayout(int drain, List<int> jointRoute, List<bool> onRoute, M6DigGeo g) {
  final p = g.poleFoot, d = g.dtrEntry;
  final joints = jointRoute.length == 1 ? [Offset(250, g.roadTop + 30)] : [Offset(250, g.roadTop + 30), Offset(120, g.roadTop + 50)];
  final covers = List<Offset>.filled(jointRoute.length + 1, Offset.zero);
  covers[drain] = Offset(70, g.roadTop - 8);
  for (final (i, ci) in jointRoute.indexed) {
    covers[ci] = joints[i];
  }
  final route = [p, ...joints, d];
  final on = [Offset.lerp(route[0], route[1], 0.5)!, Offset.lerp(route[1], route[2], 0.5)!];
  final off = [Offset(190, g.roadTop - 10), Offset(320, g.roadTop + 40)];
  var a = 0, b = 0;
  return M6DigLayout(covers: covers, route: route, spots: [for (final r in onRoute) r ? on[a++ % 2] : off[b++ % 2]], fallback: true);
}

/// What the street shows now.
@immutable
class M6DigRig {
  const M6DigRig({
    required this.layout,
    required this.drain,
    required this.seed,
    this.open = const {},
    this.chalk = const [],
    this.showTrue = false,
    this.spotsUp = false,
    this.dug = const {},
  });

  final M6DigLayout layout;

  /// Which cover hides the drain (the others a joint).
  final int drain;
  final int seed;

  /// The covers lifted now.
  final Set<int> open;

  /// The player's chalk anchors in order (legs between them).
  final List<Offset> chalk;

  /// The true route chalked in (after a wrong peg).
  final bool showTrue;

  /// The dig circles are drawn; [dug] = spots already dug.
  final bool spotsUp;
  final Set<int> dug;

  @override
  bool operator ==(Object other) =>
      other is M6DigRig &&
      identical(other.layout, layout) &&
      other.drain == drain &&
      other.seed == seed &&
      setEquals(other.open, open) &&
      listEquals(other.chalk, chalk) &&
      other.showTrue == showTrue &&
      other.spotsUp == spotsUp &&
      setEquals(other.dug, dug);

  @override
  int get hashCode => Object.hash(layout, drain, seed, Object.hashAllUnordered(open), Object.hashAll(chalk), showTrue, spotsUp, Object.hashAllUnordered(dug));
}

const _iron = Color(0xFF4A4F55);
const _ironHi = Color(0xFF6E757D);
const _chalk = Color(0xE6F4F1E6);
const _cable = Color(0xFF15181C);

/// The chalk path through [pts]: straight legs, each turn rounded (a gentle
/// bend, never a sharp corner: ruling M6-7).
Path m6ChalkPath(List<Offset> pts, {double radius = 18}) {
  final path = Path();
  if (pts.isEmpty) return path;
  path.moveTo(pts.first.dx, pts.first.dy);
  for (var i = 1; i < pts.length; i++) {
    final b = pts[i];
    if (i + 1 < pts.length) {
      final a = pts[i - 1], c = pts[i + 1];
      final inL = (b - a).distance, outL = (c - b).distance;
      final r = math.min(radius, math.min(inL, outL) / 2);
      final p1 = b - (b - a) / inL * r;
      final p2 = b + (c - b) / outL * r;
      path.lineTo(p1.dx, p1.dy);
      path.quadraticBezierTo(b.dx, b.dy, p2.dx, p2.dy);
    } else {
      path.lineTo(b.dx, b.dy);
    }
  }
  return path;
}

class M6DigPainter extends CustomPainter {
  const M6DigPainter({required this.geo, required this.rig});

  final M6DigGeo geo;
  final M6DigRig rig;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    final rnd = math.Random(rig.seed);
    // Sky.
    c.drawRect(
        Rect.fromLTWH(0, 0, w, g.farTop + 2),
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF6FA8DC), Color(0xFFCFE4F2)])
              .createShader(Rect.fromLTWH(0, 0, w, g.farTop + 2)));
    // Houses along the far footpath.
    var x = -10.0;
    while (x < w + 10) {
      final hw = 54 + rnd.nextDouble() * 34;
      final hh = 70 + rnd.nextDouble() * 70;
      final r = Rect.fromLTWH(x, g.farTop - hh, hw - 4, hh);
      final tone = [const Color(0xFFE8D5B0), const Color(0xFFD9B99B), const Color(0xFFC9D6C4), const Color(0xFFE3C9C0)][rnd.nextInt(4)];
      c.drawRect(r, Paint()..color = tone);
      c.drawRect(Rect.fromLTWH(r.left - 2, r.top - 5, r.width + 4, 6), Paint()..color = const Color(0xFF8C7A66));
      for (var wy = r.top + 14; wy < r.bottom - 22; wy += 26) {
        for (var wx = r.left + 8; wx < r.right - 14; wx += 18) {
          c.drawRect(Rect.fromLTWH(wx, wy, 10, 12), Paint()..color = const Color(0xFF51677A));
        }
      }
      c.drawRect(Rect.fromLTWH(r.center.dx - 7, r.bottom - 20, 14, 20), Paint()..color = const Color(0xFF6B4A33));
      x += hw;
    }
    // Far footpath.
    final far = Rect.fromLTRB(0, g.farTop, w, g.roadTop);
    c.drawRect(far, Paint()..color = const Color(0xFFBDB6A8));
    _pavers(c, far, const Color(0x22000000));
    // Road.
    final road = Rect.fromLTRB(0, g.roadTop, w, g.roadBottom);
    c.drawRect(
        road,
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF5C6066), Color(0xFF4A4E54)])
              .createShader(road));
    for (var i = 0; i < 40; i++) {
      final p = Offset(rnd.nextDouble() * w, g.roadTop + rnd.nextDouble() * road.height);
      c.drawCircle(p, 1 + rnd.nextDouble() * 1.6, Paint()..color = const Color(0x18FFFFFF));
    }
    final mid = (g.roadTop + g.roadBottom) / 2;
    for (var dx = 6.0; dx < w; dx += 40) {
      c.drawRect(Rect.fromLTWH(dx, mid - 2, 22, 4), Paint()..color = const Color(0xCCEFE7C8));
    }
    // Kerbs.
    c.drawRect(Rect.fromLTWH(0, g.roadTop - 3, w, 4), Paint()..color = const Color(0xFF9A948A));
    c.drawRect(Rect.fromLTWH(0, g.roadBottom - 1, w, 5), Paint()..color = const Color(0xFF9A948A));
    // Near footpath and the drain strip under it.
    final near = Rect.fromLTRB(0, g.roadBottom + 4, w, g.groundY);
    c.drawRect(near, Paint()..color = const Color(0xFFC6BFB1));
    _pavers(c, near, const Color(0x22000000));
    c.drawRect(
        Rect.fromLTRB(0, g.groundY, w, size.height),
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8E8778), Color(0xFF5E584D)])
              .createShader(Rect.fromLTRB(0, g.groundY, w, size.height)));
    _pole(c, w);
    _dtr(c);
    // The covers (a lifted one shows its pit).
    for (final (i, at) in rig.layout.covers.indexed) {
      _cover(c, at, i == rig.drain, rig.open.contains(i));
    }
    // The dig circles and the pits dug.
    if (rig.spotsUp) {
      for (final (i, s) in rig.layout.spots.indexed) {
        if (rig.dug.contains(i)) {
          _pit(c, s);
        } else {
          _chalkCircle(c, s);
        }
      }
    }
    // The chalk: the true route after a wrong peg, else the player's legs.
    final pts = rig.showTrue ? rig.layout.route : rig.chalk;
    if (pts.length >= 2) {
      final path = m6ChalkPath(pts);
      c.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = const Color(0x33000000));
      c.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.4
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = _chalk);
    }
    if (!rig.showTrue) {
      for (final p in rig.chalk) {
        c.drawCircle(p, 4.2, Paint()..color = _chalk);
      }
    }
  }

  void _pavers(Canvas c, Rect r, Color line) {
    final p = Paint()
      ..color = line
      ..strokeWidth = 1;
    for (var y = r.top + 11; y < r.bottom; y += 11) {
      c.drawLine(Offset(r.left, y), Offset(r.right, y), p);
    }
    var row = 0;
    for (var y = r.top; y < r.bottom; y += 11) {
      for (var x = (row.isEven ? 0.0 : 11.0); x < r.right; x += 22) {
        c.drawLine(Offset(x, y), Offset(x, math.min(r.bottom, y + 11)), p);
      }
      row++;
    }
  }

  void _pole(Canvas c, double w) {
    final g = geo;
    final x = M6DigGeo.poleX;
    final top = g.poleTopY;
    final foot = g.poleFoot;
    // Shadow, then the concrete pole.
    c.drawOval(Rect.fromCenter(center: foot.translate(8, 3), width: 26, height: 8), Paint()..color = const Color(0x33000000));
    c.drawRect(
        Rect.fromLTRB(x - 5, top, x + 5, foot.dy),
        Paint()
          ..shader = const LinearGradient(colors: [Color(0xFF9EA3A6), Color(0xFFD7DADB), Color(0xFF8C9194)]).createShader(Rect.fromLTRB(x - 5, top, x + 5, foot.dy)));
    // Cross-arm with three pin insulators and the line running off.
    final arm = top + 4;
    c.drawRect(Rect.fromLTRB(x - 34, arm - 3, x + 34, arm + 3), Paint()..color = const Color(0xFF6F7880));
    final wire = Paint()
      ..color = const Color(0xFF30353A)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    for (final dx in const [-28.0, 0.0, 28.0]) {
      final ins = Offset(x + dx, arm - 7);
      c.drawRect(Rect.fromCenter(center: ins, width: 6, height: 8), Paint()..color = const Color(0xFFE9EDF0));
      c.drawPath(
          Path()
            ..moveTo(ins.dx, ins.dy - 4)
            ..quadraticBezierTo(ins.dx - 90, ins.dy + 6, -10, ins.dy - 6),
          wire);
    }
    // The end termination under the arm: three sealed ends (stress-control
    // skirts) with leads up to the line.
    final t = g.riserTop;
    for (final (i, dx) in const [-12.0, 0.0, 12.0].indexed) {
      final head = Offset(x - 9 + dx, t.dy - 2);
      c.drawLine(head, Offset(x + const [-28.0, 0.0, 28.0][i], arm - 9), wire);
      for (var s = 0; s < 3; s++) {
        c.drawOval(Rect.fromCenter(center: head.translate(0, 3.0 + s * 4), width: 9, height: 3.4), Paint()..color = const Color(0xFF9A3B2E));
      }
      c.drawLine(head.translate(0, 14), Offset(x - 9, t.dy + 20), Paint()
        ..color = _cable
        ..strokeWidth = 2.2);
    }
    // The cable down the pole's left side into the ground (in a guard pipe
    // near the foot), and the soil mound where it goes in.
    c.drawLine(Offset(x - 9, t.dy + 20), Offset(x - 9, foot.dy - 4), Paint()
      ..color = _cable
      ..strokeWidth = 4);
    c.drawRect(Rect.fromLTRB(x - 13, foot.dy - 34, x - 5, foot.dy - 2), Paint()..color = const Color(0xFF7D858C));
    for (var y = top + 30; y < foot.dy - 40; y += 26) {
      c.drawRect(Rect.fromLTRB(x - 12, y, x - 6, y + 3), Paint()..color = const Color(0xFF5A6066));
    }
    c.drawOval(Rect.fromCenter(center: foot.translate(-8, 0), width: 22, height: 9), Paint()..color = const Color(0xFF6B5136));
  }

  void _dtr(Canvas c) {
    final g = geo;
    final p = g.plinth;
    final b = g.dtrBox;
    c.drawRect(p.translate(4, 4), Paint()..color = const Color(0x33000000));
    c.drawRect(p, Paint()..color = const Color(0xFFB9B3A8));
    c.drawRect(Rect.fromLTWH(p.left, p.top, p.width, 4), Paint()..color = const Color(0xFFD5D0C6));
    // The tank with cooling fins, HT bushings on top, the LT box at its right.
    c.drawRect(
        b,
        Paint()
          ..shader = const LinearGradient(colors: [Color(0xFF5E7D6B), Color(0xFF7FA08C), Color(0xFF557364)]).createShader(b));
    for (var x = b.left + 6; x < b.right - 4; x += 7) {
      c.drawLine(Offset(x, b.top + 10), Offset(x, b.bottom - 6), Paint()
        ..color = const Color(0x55233A2E)
        ..strokeWidth = 2);
    }
    c.drawRect(Rect.fromLTWH(b.left - 3, b.top - 4, b.width + 6, 6), Paint()..color = const Color(0xFF486555));
    for (final dx in const [14.0, 30.0, 46.0]) {
      final s = Offset(b.left + dx, b.top - 4);
      for (var k = 0; k < 3; k++) {
        c.drawOval(Rect.fromCenter(center: s.translate(0, -3.0 - k * 4), width: 9, height: 3.6), Paint()..color = const Color(0xFF8B5A3C));
      }
    }
    final lt = Rect.fromLTWH(b.right - 2, b.top + 18, 14, 22);
    c.drawRect(lt, Paint()..color = const Color(0xFF6F7880));
    // Its cable down into the plinth and back into the ground at the foot.
    final e = g.dtrEntry;
    c.drawPath(
        Path()
          ..moveTo(lt.center.dx, lt.bottom)
          ..lineTo(lt.center.dx, p.top + 4)
          ..quadraticBezierTo(lt.center.dx, p.bottom - 6, e.dx - 6, e.dy - 2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = _cable);
    c.drawOval(Rect.fromCenter(center: e, width: 20, height: 9), Paint()..color = const Color(0xFF6B5136));
  }

  void _cover(Canvas c, Offset at, bool drain, bool open) {
    final r = geo.coverRect(at);
    if (open) {
      // The pit under it.
      final pit = RRect.fromRectAndRadius(r, const Radius.circular(3));
      c.drawRRect(pit, Paint()..color = const Color(0xFF1E1A16));
      c.save();
      c.clipRRect(pit);
      if (drain) {
        c.drawRect(Rect.fromLTRB(r.left, r.center.dy - 2, r.right, r.bottom), Paint()..color = const Color(0xFF3F5560));
        for (var k = 0; k < 3; k++) {
          c.drawLine(Offset(r.left + 4 + k * 9, r.center.dy + 4 + k * 2.0), Offset(r.left + 10 + k * 9, r.center.dy + 4 + k * 2.0), Paint()
            ..color = const Color(0x88B8D2DC)
            ..strokeWidth = 1.2);
        }
      } else {
        c.drawLine(Offset(r.left - 2, r.center.dy + 3), Offset(r.right + 2, r.center.dy + 1), Paint()
          ..color = _cable
          ..strokeWidth = 4);
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: r.center.translate(0, 2), width: 18, height: 8), const Radius.circular(3)), Paint()..color = const Color(0xFF2E3338));
        c.drawLine(r.center.translate(-6, 0), r.center.translate(6, 0), Paint()
          ..color = const Color(0xFF5A6066)
          ..strokeWidth = 1);
      }
      c.restore();
      // The lid slid up off the pit.
      _lid(c, r.translate(0, -r.height * 0.75));
      return;
    }
    c.drawRect(r.translate(2, 3), Paint()..color = const Color(0x44000000));
    _lid(c, r);
  }

  void _lid(Canvas c, Rect r) {
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(3));
    c.drawRRect(rr, Paint()..shader = const LinearGradient(colors: [_ironHi, _iron]).createShader(r));
    final hatch = Paint()
      ..color = const Color(0x553A3F44)
      ..strokeWidth = 1;
    for (var x = r.left + 5; x < r.right - 3; x += 5) {
      c.drawLine(Offset(x, r.top + 3), Offset(x, r.bottom - 3), hatch);
    }
    c.drawRRect(rr, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFF2E3338));
    c.drawCircle(Offset(r.left + 5, r.center.dy), 1.6, Paint()..color = const Color(0xFF2E3338));
    c.drawCircle(Offset(r.right - 5, r.center.dy), 1.6, Paint()..color = const Color(0xFF2E3338));
  }

  void _chalkCircle(Canvas c, Offset s) {
    const r = M6DigGeo.spotR;
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..color = _chalk;
    for (var a = 0; a < 12; a++) {
      final s0 = a * math.pi / 6;
      c.drawArc(Rect.fromCircle(center: s, radius: r), s0, math.pi / 9, false, p);
    }
    c.drawLine(s.translate(-4, 0), s.translate(4, 0), p);
    c.drawLine(s.translate(0, -4), s.translate(0, 4), p);
  }

  void _pit(Canvas c, Offset s) {
    c.drawOval(Rect.fromCenter(center: s.translate(14, -6), width: 24, height: 12), Paint()..color = const Color(0xFF8A6A44));
    c.drawOval(Rect.fromCenter(center: s, width: 30, height: 18), Paint()..color = const Color(0xFF3A2A1A));
    c.drawOval(Rect.fromCenter(center: s.translate(0, 2), width: 22, height: 11), Paint()..color = const Color(0xFF241A10));
  }

  @override
  bool shouldRepaint(M6DigPainter old) => old.geo != geo || old.rig != rig;
}

/// The excavator: it drives from [from] to [spot] ([travel]) and lowers its
/// bucket over the dig circle ([drop]: 0 = raised, 1 = touching). In reduced
/// motion the bucket moves in four still steps ([stepped]).
class M6DiggerPainter extends CustomPainter {
  M6DiggerPainter({required this.spot, required this.from, required this.drop, required this.travel, this.stepped = false})
      : super(repaint: Listenable.merge([drop, travel]));

  final Offset spot;
  final Offset from;
  final Animation<double> drop;
  final Animation<double> travel;
  final bool stepped;

  /// The bucket's height over the ground at [v] (design px).
  static double liftAt(double v) => 66 * (1 - v.clamp(0.0, 1.0));

  @override
  void paint(Canvas c, Size size) {
    final t = Curves.easeInOut.transform(travel.value.clamp(0.0, 1.0));
    final at = Offset.lerp(from, spot, t)!;
    var v = drop.value;
    if (stepped) v = (v * 4).floor() / 4;
    final right = at.dx < 220;
    final body = at + Offset(right ? 60 : -60, 22);
    final lift = liftAt(v);
    final bucket = at.translate(0, -lift - 6);
    // The shadow on the circle darkens as the bucket comes down.
    c.drawOval(Rect.fromCenter(center: at, width: 30, height: 12), Paint()..color = Color.fromRGBO(0, 0, 0, 0.12 + 0.35 * v));
    // Tracks and the turntable.
    final tr = Rect.fromCenter(center: body.translate(0, 10), width: 64, height: 16);
    c.drawRRect(RRect.fromRectAndRadius(tr.translate(3, 4), const Radius.circular(8)), Paint()..color = const Color(0x44000000));
    c.drawRRect(RRect.fromRectAndRadius(tr, const Radius.circular(8)), Paint()..color = const Color(0xFF2D3035));
    for (var k = 0; k < 6; k++) {
      c.drawCircle(Offset(tr.left + 8 + k * 9.6, tr.center.dy), 3, Paint()..color = const Color(0xFF55595F));
    }
    final hull = Rect.fromCenter(center: body.translate(0, -6), width: 58, height: 22);
    c.drawRRect(RRect.fromRectAndRadius(hull, const Radius.circular(4)),
        Paint()..shader = const LinearGradient(colors: [Color(0xFFF2B51E), Color(0xFFD9900E)]).createShader(hull));
    // The cab with the operator.
    final cab = Rect.fromLTWH(right ? hull.right - 26 : hull.left + 2, hull.top - 24, 24, 26);
    c.drawRRect(RRect.fromRectAndRadius(cab, const Radius.circular(3)), Paint()..color = const Color(0xFFE6A417));
    final glass = cab.deflate(4).translate(0, -1);
    c.drawRect(glass, Paint()..color = const Color(0xCC9CC7DD));
    c.drawCircle(glass.center.translate(0, 1), 4.2, Paint()..color = const Color(0xFF8A5A3A));
    c.drawRect(Rect.fromCenter(center: glass.center.translate(0, -3.5), width: 9, height: 3), Paint()..color = const Color(0xFFFFD34E));
    // The boom and the arm down to the bucket.
    final root = Offset(right ? hull.left + 10 : hull.right - 10, hull.top + 4);
    final elbow = Offset((root.dx + bucket.dx) / 2 + (right ? 6 : -6), math.min(root.dy, bucket.dy) - 34);
    final arm = Paint()
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFE0A012);
    c.drawLine(root, elbow, arm);
    c.drawLine(elbow, bucket.translate(0, -8), arm..strokeWidth = 5.5);
    c.drawLine(root.translate(0, -3), elbow.translate(0, 4), Paint()
      ..strokeWidth = 2
      ..color = const Color(0xFF6F7880));
    // The bucket with its teeth.
    final bk = Path()
      ..moveTo(bucket.dx - 11, bucket.dy - 10)
      ..lineTo(bucket.dx + 11, bucket.dy - 10)
      ..lineTo(bucket.dx + 8, bucket.dy + 2)
      ..lineTo(bucket.dx - 8, bucket.dy + 2)
      ..close();
    c.drawPath(bk, Paint()..color = const Color(0xFF3C4248));
    for (var k = 0; k < 4; k++) {
      final tx = bucket.dx - 7 + k * 4.6;
      c.drawPath(
          Path()
            ..moveTo(tx - 1.6, bucket.dy + 2)
            ..lineTo(tx + 1.6, bucket.dy + 2)
            ..lineTo(tx, bucket.dy + 6)
            ..close(),
          Paint()..color = const Color(0xFF8C939A));
    }
  }

  @override
  bool shouldRepaint(M6DiggerPainter old) => old.spot != spot || old.from != from || old.stepped != stepped || old.drop != drop || old.travel != travel;
}

/// The bucket through the live cable: a white-blue arc flash bursting off
/// the dig circle (in colour over the grey freeze), [v] 0→1.
class M6DigFlashPainter extends CustomPainter {
  const M6DigFlashPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final r = 18 + 120 * Curves.easeOut.transform(v);
    c.drawCircle(
        at,
        r,
        Paint()
          ..shader = RadialGradient(colors: [
            Color.fromRGBO(255, 255, 255, 0.95 * (1 - v * 0.5)),
            Color.fromRGBO(140, 200, 255, 0.7 * (1 - v * 0.6)),
            const Color(0x00508CFF),
          ], stops: const [0.0, 0.35, 1.0])
              .createShader(Rect.fromCircle(center: at, radius: r)));
    final rnd = math.Random(7);
    final bolt = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = Color.fromRGBO(220, 240, 255, 1 - v * 0.7);
    for (var k = 0; k < 7; k++) {
      final a = k * math.pi * 2 / 7 + rnd.nextDouble() * 0.4;
      final p = Path()..moveTo(at.dx, at.dy);
      var q = at;
      for (var s = 1; s <= 4; s++) {
        final d = (14 + 16 * s) * (0.5 + 0.5 * v);
        q = at + Offset(math.cos(a), math.sin(a)) * d + Offset(rnd.nextDouble() * 10 - 5, rnd.nextDouble() * 10 - 5);
        p.lineTo(q.dx, q.dy);
      }
      c.drawPath(p, bolt);
    }
    // Clods thrown up.
    for (var k = 0; k < 9; k++) {
      final a = -math.pi * (0.1 + 0.8 * rnd.nextDouble());
      final d = 20 + 70 * v * (0.6 + 0.4 * rnd.nextDouble());
      c.drawCircle(at + Offset(math.cos(a), math.sin(a)) * d, 3, Paint()..color = const Color(0xFF5A3E26));
    }
  }

  @override
  bool shouldRepaint(M6DigFlashPainter old) => old.at != at || old.v != v;
}

/// A close look (unscored), no words: the end termination on the pole top
/// (the cable rising out of the ground to the line), or the DTR's cable
/// going down through its plinth into the ground.
class M6LookPainter extends CustomPainter {
  const M6LookPainter({required this.look});
  final M6Look look;

  @override
  void paint(Canvas c, Size size) {
    final r = Offset.zero & size;
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(10));
    c.drawRRect(rr, Paint()..color = const Color(0xF2F7F1DE));
    c.drawRRect(rr, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = const Color(0xFF8A6A3C));
    c.save();
    c.clipRRect(rr.deflate(3));
    final cable = Paint()
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = _cable;
    switch (look) {
      case M6Look.termination:
        // The pole, the line above, three sealed ends, the cable going down
        // into the ground at the bottom.
        c.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.78), Paint()..color = const Color(0xFFCFE4F2));
        c.drawRect(Rect.fromLTWH(0, size.height * 0.78, size.width, size.height), Paint()..color = const Color(0xFF8A6A44));
        c.drawRect(Rect.fromLTWH(size.width * 0.62, 0, 10, size.height * 0.8), Paint()..color = const Color(0xFFB9BDBF));
        c.drawLine(Offset(0, 10), Offset(size.width, 10), Paint()
          ..strokeWidth = 1.4
          ..color = const Color(0xFF30353A));
        final x0 = size.width * 0.34;
        for (var k = 0; k < 3; k++) {
          final hx = x0 + k * 13.0;
          c.drawLine(Offset(hx, 14), Offset(hx, 10), Paint()
            ..strokeWidth = 1.4
            ..color = const Color(0xFF30353A));
          for (var s = 0; s < 3; s++) {
            c.drawOval(Rect.fromCenter(center: Offset(hx, 18.0 + s * 5), width: 11, height: 4), Paint()..color = const Color(0xFF9A3B2E));
          }
          c.drawLine(Offset(hx, 32), Offset(x0 + 13, 46), Paint()
            ..strokeWidth = 2.4
            ..color = _cable);
        }
        c.drawLine(Offset(x0 + 13, 46), Offset(x0 + 13, size.height * 0.9), cable);
        c.drawLine(Offset(x0 + 13, size.height * 0.84), Offset(x0 + 13, size.height + 4), cable..color = const Color(0x88151820));
      case M6Look.dtrEntry:
        // Cut-away: the plinth, the cable down through it, into the soil.
        c.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.42), Paint()..color = const Color(0xFFCFE4F2));
        c.drawRect(Rect.fromLTWH(0, size.height * 0.42, size.width, size.height), Paint()..color = const Color(0xFF9A7A52));
        for (var k = 0; k < 14; k++) {
          c.drawCircle(Offset(8.0 + k * 9.3, size.height * (0.55 + 0.3 * ((k * 37) % 7) / 7)), 1.4, Paint()..color = const Color(0x55302010));
        }
        final tank = Rect.fromLTWH(size.width * 0.18, 4, size.width * 0.42, size.height * 0.28);
        c.drawRect(tank, Paint()..color = const Color(0xFF6F907C));
        final pl = Rect.fromLTWH(size.width * 0.1, size.height * 0.32, size.width * 0.58, size.height * 0.16);
        c.drawRect(pl, Paint()..color = const Color(0xFFB9B3A8));
        final x = tank.right + 8;
        c.drawRect(Rect.fromLTWH(tank.right - 2, tank.top + 6, 12, 14), Paint()..color = const Color(0xFF6F7880));
        c.drawPath(
            Path()
              ..moveTo(x, tank.top + 20)
              ..lineTo(x, size.height * 0.62)
              ..quadraticBezierTo(x, size.height * 0.8, size.width + 6, size.height * 0.8),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 5
              ..color = _cable);
    }
    c.restore();
  }

  @override
  bool shouldRepaint(M6LookPainter old) => old.look != look;
}
