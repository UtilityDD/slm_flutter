import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The drawn world of lesson 5.9 কাজ 2 "মাটির নিচের সূত্র"
// (m5_cable_route_locate.dart): a town seen from above, the substation gate
// at the bottom, streets running up between the houses. Two 11 kV feeder
// cables leave the gate under the same street (the trunk) and part at a
// junction, one up each branch; a side lane carries no cable. The cables are
// never drawn on the street — only the route map card shows them, both in the
// same style, told apart by their feeder labels alone.
//
// On the street: ground marks (the same blotch art wherever they lie, on a
// route or off it), joint-pit covers beside the road (on both branches), the
// walked trail, pins, the measuring wheel's chalk cross, the thump chalk ring,
// the peg, and the specialist team's van at the gate. Code-drawn, gradients,
// no bitmaps, no text.
//
// Design: 360 wide × the scene's height; the play area runs from below the
// header to the gate above the tool row (a tall phone gets longer streets).

/// Which street a thing lies on.
enum M5CrlPath { own, other, lane }

/// The street plan of one street round: one of [m5CrlLayouts] shapes,
/// mirrored or not, and which branch carries the docket's feeder.
@immutable
class M5CrlPlan {
  const M5CrlPlan({required this.layout, required this.mirror, required this.ownA});
  final int layout;
  final bool mirror;

  /// The docket's feeder takes branch A of the layout (else branch B).
  final bool ownA;

  @override
  bool operator ==(Object other) => other is M5CrlPlan && other.layout == layout && other.mirror == mirror && other.ownA == ownA;

  @override
  int get hashCode => Object.hash(layout, mirror, ownA);
}

/// The route shapes (unit space: u 0..1 left → right, v 0..1 top → the gate).
const int m5CrlLayouts = 4;

// The gate sits left of centre (the guide and his bubble stand bottom right;
// a mirrored plan puts the gate right and the guide left).
const List<List<Offset>> _trunks = [
  [Offset(0.3, 1), Offset(0.3, 0.56)],
  [Offset(0.3, 1), Offset(0.3, 0.66), Offset(0.58, 0.66), Offset(0.58, 0.44)],
  [Offset(0.3, 1), Offset(0.3, 0.36)],
  [Offset(0.3, 1), Offset(0.3, 0.62), Offset(0.66, 0.62), Offset(0.66, 0.40)],
];
const List<List<Offset>> _branchA = [
  [Offset(0.3, 0.56), Offset(0.08, 0.56), Offset(0.08, 0.03)],
  [Offset(0.58, 0.44), Offset(0.58, 0.03)],
  [Offset(0.3, 0.36), Offset(0.06, 0.36), Offset(0.06, 0.03)],
  [Offset(0.66, 0.40), Offset(0.66, 0.03)],
];
const List<List<Offset>> _branchB = [
  [Offset(0.3, 0.56), Offset(0.84, 0.56), Offset(0.84, 0.03)],
  [Offset(0.58, 0.44), Offset(0.12, 0.44), Offset(0.12, 0.03)],
  [Offset(0.3, 0.36), Offset(0.8, 0.36), Offset(0.8, 0.03)],
  [Offset(0.66, 0.40), Offset(0.2, 0.40), Offset(0.2, 0.03)],
];
const List<List<Offset>> _lanes = [
  [Offset(0.3, 0.80), Offset(0.0, 0.80)],
  [Offset(0.3, 0.84), Offset(0.0, 0.84)],
  [Offset(0.3, 0.68), Offset(0.0, 0.68)],
  [Offset(0.3, 0.82), Offset(0.0, 0.82)],
];

/// The nearest point of a path: its distance and its arc length.
typedef M5CrlNear = ({double d, double s});

double _len(List<Offset> p) {
  var l = 0.0;
  for (var i = 1; i < p.length; i++) {
    l += (p[i] - p[i - 1]).distance;
  }
  return l;
}

Offset _at(List<Offset> p, double s) {
  if (s <= 0) return p.first;
  var left = s;
  for (var i = 1; i < p.length; i++) {
    final seg = (p[i] - p[i - 1]).distance;
    if (left <= seg) return Offset.lerp(p[i - 1], p[i], seg == 0 ? 0 : left / seg)!;
    left -= seg;
  }
  return p.last;
}

/// The unit direction of a path at arc length [s].
Offset _dirAt(List<Offset> p, double s) {
  var left = s;
  for (var i = 1; i < p.length; i++) {
    final seg = (p[i] - p[i - 1]).distance;
    if (left <= seg || i == p.length - 1) {
      final d = p[i] - p[i - 1];
      return d.distance == 0 ? const Offset(0, -1) : d / d.distance;
    }
    left -= seg;
  }
  return const Offset(0, -1);
}

M5CrlNear _near(List<Offset> p, Offset q) {
  var best = double.infinity;
  var bestS = 0.0;
  var acc = 0.0;
  for (var i = 1; i < p.length; i++) {
    final a = p[i - 1];
    final b = p[i];
    final ab = b - a;
    final l2 = ab.dx * ab.dx + ab.dy * ab.dy;
    final t = l2 == 0 ? 0.0 : (((q - a).dx * ab.dx + (q - a).dy * ab.dy) / l2).clamp(0.0, 1.0);
    final pt = a + ab * t;
    final d = (q - pt).distance;
    if (d < best) {
      best = d;
      bestS = acc + math.sqrt(l2) * t;
    }
    acc += math.sqrt(l2);
  }
  return (d: best, s: bestS);
}

/// Where things are (design px, 360 wide).
@immutable
class M5CrlGeo {
  const M5CrlGeo._(this.height, this.top, this.gateY, this.own, this.other, this.lane, this.junctionS, this.ownLength, this.otherLength, this.laneLength, this.mirror);

  factory M5CrlGeo.forScene(double height, double inset, M5CrlPlan plan) {
    final gateY = height - floorUp - inset * 0.5;
    const top = playTop;
    Offset map(Offset u) {
      final x = plan.mirror ? 1 - u.dx : u.dx;
      return Offset(left + x * (360 - 2 * left), top + u.dy * (gateY - top));
    }

    final trunk = [for (final u in _trunks[plan.layout]) map(u)];
    final a = [for (final u in _branchA[plan.layout]) map(u)];
    final b = [for (final u in _branchB[plan.layout]) map(u)];
    final mine = plan.ownA ? a : b;
    final theirs = plan.ownA ? b : a;
    final own = [...trunk, ...mine.skip(1)];
    final lane = [for (final u in _lanes[plan.layout]) map(u)];
    return M5CrlGeo._(height, top, gateY, own, theirs, lane, _len(trunk), _len(own), _len(theirs), _len(lane), plan.mirror);
  }

  final double height;
  final double top;

  /// The substation gate (where every route starts).
  final double gateY;

  /// The docket feeder's route: gate → junction → its far end.
  final List<Offset> own;

  /// The other feeder's branch: junction → its far end.
  final List<Offset> other;

  /// A side lane with no cable under it.
  final List<Offset> lane;

  /// Arc length of the junction along [own].
  final double junctionS;
  final double ownLength;
  final double otherLength;
  final double laneLength;

  /// The plan is mirrored: the gate right of centre, the guide bottom left.
  final bool mirror;

  /// The gate sits this far above the bottom (the tool row stands below it).
  static const double floorUp = 128;

  /// The play area's top (below the header and the docket chip).
  static const double playTop = 150;

  /// The streets' side margin.
  static const double left = 22;

  /// A street's width.
  static const double roadW = 30;

  /// The junction as a fraction of [own].
  double get junctionT => junctionS / ownLength;

  Offset get gate => own.first;
  Offset get junction => _at(own, junctionS);

  Offset ownAt(double t) => _at(own, t.clamp(0.0, 1.0) * ownLength);
  Offset pathAt(M5CrlPath p, double t) => switch (p) {
        M5CrlPath.own => ownAt(t),
        M5CrlPath.other => _at(other, t.clamp(0.0, 1.0) * otherLength),
        M5CrlPath.lane => _at(lane, t.clamp(0.0, 1.0) * laneLength),
      };

  /// The side of the road (a unit normal) at [t] of [p].
  Offset normalAt(M5CrlPath p, double t) {
    final path = switch (p) { M5CrlPath.own => own, M5CrlPath.other => other, M5CrlPath.lane => lane };
    final l = switch (p) { M5CrlPath.own => ownLength, M5CrlPath.other => otherLength, M5CrlPath.lane => laneLength };
    final d = _dirAt(path, t.clamp(0.0, 1.0) * l);
    return Offset(-d.dy, d.dx);
  }

  /// A ground mark lies on the road, a little to one side.
  Offset markAt(M5CrlPath p, double t) => pathAt(p, t) - normalAt(p, t) * 5;

  /// A joint pit's cover sits on the footpath beside the road.
  Offset pitAt(M5CrlPath p, double t) => pathAt(p, t) + normalAt(p, t) * (roadW / 2 + 9);

  Rect markHit(Offset c) => Rect.fromCenter(center: c, width: 46, height: 46);
  Rect pitHit(Offset c) => Rect.fromCenter(center: c, width: 42, height: 42);

  /// The nearest point of the docket's route / the other branch.
  M5CrlNear nearOwn(Offset p) => _near(own, p);
  M5CrlNear nearOther(Offset p) => _near(other, p);

  /// The walker stands with his feet here.
  Rect walkerBox(Offset feet) => Rect.fromLTWH(feet.dx - 13, feet.dy - 46, 26, 48);

  /// The specialist team's van, parked beside the gate (away from the guide).
  Rect get van => Rect.fromLTWH(mirror ? gate.dx + 30 : gate.dx - 94, gateY - 6, 64, 34);

  /// Where the corner guide and his bubble stand (nothing to tap goes there).
  Rect get guideZone => mirror ? Rect.fromLTRB(0, height - 292, 222, height) : Rect.fromLTRB(138, height - 292, 360, height);

  @override
  bool operator ==(Object other) =>
      other is M5CrlGeo && other.height == height && other.gateY == gateY && listEquals(other.own, own) && listEquals(other.other, this.other) && listEquals(other.lane, lane);

  @override
  int get hashCode => Object.hash(height, gateY, Object.hashAll(own), Object.hashAll(other));
}

/// A thing on the street now (for the painter).
@immutable
class M5CrlSpot {
  const M5CrlSpot(this.at, {this.pinned = false, this.open = false});
  final Offset at;
  final bool pinned;
  final bool open;

  @override
  bool operator ==(Object other) => other is M5CrlSpot && other.at == at && other.pinned == pinned && other.open == open;

  @override
  int get hashCode => Object.hash(at, pinned, open);
}

/// What the street shows now.
@immutable
class M5CrlRig {
  const M5CrlRig({
    required this.marks,
    required this.pits,
    required this.walkedT,
    this.van = false,
    this.wheelChalk,
    this.chalk,
    this.peg,
  });

  final List<M5CrlSpot> marks;
  final List<M5CrlSpot> pits;

  /// How far along the docket's route the trainee has walked (0..1).
  final double walkedT;
  final bool van;

  /// The measuring wheel's chalk cross (the TDR distance on the route).
  final Offset? wheelChalk;

  /// The thump chalk ring.
  final Offset? chalk;

  /// The peg, driven.
  final Offset? peg;

  @override
  bool operator ==(Object other) =>
      other is M5CrlRig &&
      listEquals(other.marks, marks) &&
      listEquals(other.pits, pits) &&
      other.walkedT == walkedT &&
      other.van == van &&
      other.wheelChalk == wheelChalk &&
      other.chalk == chalk &&
      other.peg == peg;

  @override
  int get hashCode => Object.hash(Object.hashAll(marks), Object.hashAll(pits), walkedT, van, wheelChalk, chalk, peg);
}

/// The town from above.
class M5CrlStreetPainter extends CustomPainter {
  M5CrlStreetPainter({required this.geo, required this.rig, required this.seed});

  final M5CrlGeo geo;
  final M5CrlRig rig;
  final int seed;

  static const _roof = [Color(0xFFB4664A), Color(0xFF8E9399), Color(0xFF5F7E9C), Color(0xFFC7B48A), Color(0xFF9C5B4B), Color(0xFF7A8C6E)];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Ground: dusty town earth.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF55604A), Color(0xFF6B6A50)])
            .createShader(Offset.zero & size),
    );
    final streets = [geo.own, geo.other, geo.lane];
    bool nearRoad(Rect r) {
      for (final s in streets) {
        for (final c in [r.center, r.topLeft, r.topRight, r.bottomLeft, r.bottomRight]) {
          if (_near(s, c).d < M5CrlGeo.roadW / 2 + 12) return true;
        }
      }
      return false;
    }

    // Houses: rooftops in a loose grid, never on a street.
    final rng = math.Random(seed);
    for (var y = 70.0; y < h; y += 44) {
      for (var x = 4.0; x < w; x += 46) {
        final r = Rect.fromLTWH(x + rng.nextDouble() * 6, y + rng.nextDouble() * 6, 30 + rng.nextDouble() * 10, 26 + rng.nextDouble() * 10);
        final c = _roof[rng.nextInt(_roof.length)];
        if (nearRoad(r) || (r.bottom > geo.gateY - 20 && (r.center.dx - geo.gate.dx).abs() < 80)) continue;
        if (rng.nextDouble() < 0.18) {
          // A tree.
          canvas.drawCircle(r.center, 12, Paint()..color = const Color(0xFF2F4A2C));
          canvas.drawCircle(r.center.translate(-3, -3), 8, Paint()..color = const Color(0xFF3F6236));
          continue;
        }
        canvas.drawRRect(RRect.fromRectAndRadius(r.translate(2, 3), const Radius.circular(3)), Paint()..color = const Color(0x55000000));
        canvas.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(3)),
          Paint()..shader = LinearGradient(colors: [Color.lerp(c, Colors.white, 0.18)!, c]).createShader(r),
        );
        canvas.drawLine(Offset(r.left + 3, r.center.dy), Offset(r.right - 3, r.center.dy), Paint()..color = const Color(0x33000000)..strokeWidth = 1);
      }
    }
    // Streets: footpath, asphalt, centre dashes. The lane is a little narrower.
    void road(List<Offset> p, double width) {
      final path = Path()..moveTo(p.first.dx, p.first.dy);
      for (final q in p.skip(1)) {
        path.lineTo(q.dx, q.dy);
      }
      canvas.drawPath(path, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width + 10
        ..strokeJoin = StrokeJoin.miter
        ..color = const Color(0xFFA9A69A));
      canvas.drawPath(path, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeJoin = StrokeJoin.miter
        ..color = const Color(0xFF3C4046));
    }

    road(geo.lane, M5CrlGeo.roadW - 6);
    road(geo.own, M5CrlGeo.roadW);
    road(geo.other, M5CrlGeo.roadW);
    final dash = Paint()
      ..color = const Color(0x88E8E2CF)
      ..strokeWidth = 1.6;
    for (final (p, l) in [(geo.own, geo.ownLength), (geo.other, geo.otherLength)]) {
      for (var s = 8.0; s < l - 6; s += 16) {
        final a = _at(p, s);
        final b = _at(p, s + 7);
        canvas.drawLine(a, b, dash);
      }
    }
    // The far ends: a kiosk substation at the end of each branch (the same).
    for (final end in [geo.own.last, geo.other.last]) {
      final r = Rect.fromCenter(center: end.translate(0, -6), width: 26, height: 18);
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)),
          Paint()..shader = const LinearGradient(colors: [Color(0xFF8FA0AE), Color(0xFF5E6E7B)]).createShader(r));
      canvas.drawRect(Rect.fromCenter(center: r.center, width: 8, height: 8), Paint()..color = const Color(0xFFF2C14E));
    }
    // The substation yard below the gate.
    final yard = Rect.fromCenter(center: Offset(geo.gate.dx, geo.gateY + 34), width: 132, height: 56);
    canvas.drawRect(yard, Paint()..color = const Color(0xFF7D7A6C));
    final fence = Paint()
      ..color = const Color(0xFFD9D4C2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawLine(yard.topLeft, Offset(geo.gate.dx - 18, yard.top), fence);
    canvas.drawLine(Offset(geo.gate.dx + 18, yard.top), yard.topRight, fence);
    canvas.drawLine(yard.topLeft, yard.bottomLeft, fence);
    canvas.drawLine(yard.topRight, yard.bottomRight, fence);
    for (final dx in [-40.0, 40.0]) {
      final t = Rect.fromCenter(center: Offset(geo.gate.dx + dx, yard.top + 26), width: 26, height: 22);
      canvas.drawRRect(RRect.fromRectAndRadius(t, const Radius.circular(3)),
          Paint()..shader = const LinearGradient(colors: [Color(0xFF9AA6AF), Color(0xFF66737D)]).createShader(t));
    }
    // The walked trail: footprints along the docket's route.
    final steps = Paint()..color = const Color(0xCCF6E7A8);
    final walked = rig.walkedT * geo.ownLength;
    for (var s = 6.0; s < walked; s += 11) {
      final p = _at(geo.own, s);
      final n = _dirAt(geo.own, s);
      final side = Offset(-n.dy, n.dx) * ((s ~/ 11).isEven ? 3.0 : -3.0);
      canvas.drawCircle(p + side, 1.8, steps);
    }
    // Ground marks: one blotch art for all.
    for (final (i, m) in rig.marks.indexed) {
      _blotch(canvas, m.at, seed * 31 + i);
      if (m.pinned) _flag(canvas, m.at.translate(6, -2));
    }
    // Joint pits: a concrete cover, or open and dark.
    for (final p in rig.pits) {
      final r = Rect.fromCenter(center: p.at, width: 20, height: 20);
      if (p.open) {
        canvas.drawRect(r, Paint()..color = const Color(0xFF121416));
        canvas.drawRect(r.translate(6, -10), Paint()..color = const Color(0xFF9C9A90));
      } else {
        canvas.drawRect(r.translate(1, 2), Paint()..color = const Color(0x55000000));
        canvas.drawRect(r, Paint()..shader = const LinearGradient(colors: [Color(0xFFB9B6AA), Color(0xFF8D8A7E)]).createShader(r));
        canvas.drawLine(r.center.translate(-5, 0), r.center.translate(5, 0), Paint()..color = const Color(0xFF55534B)..strokeWidth = 2);
      }
      if (p.pinned) _flag(canvas, p.at.translate(8, -6));
    }
    final wc = rig.wheelChalk;
    if (wc != null) {
      final chalk = Paint()
        ..color = const Color(0xFFF4F1E6)
        ..strokeWidth = 2.2;
      canvas.drawLine(wc.translate(-6, -6), wc.translate(6, 6), chalk);
      canvas.drawLine(wc.translate(-6, 6), wc.translate(6, -6), chalk);
    }
    final ck = rig.chalk;
    if (ck != null) {
      canvas.drawCircle(ck, 9, Paint()
        ..color = const Color(0xFFF4F1E6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2);
    }
    final pg = rig.peg;
    if (pg != null) {
      canvas.drawLine(pg.translate(0, 2), pg.translate(0, -16), Paint()..color = const Color(0xFF8A5A32)..strokeWidth = 3.4);
      canvas.drawRect(Rect.fromLTWH(pg.dx - 2.5, pg.dy - 19, 5, 6), Paint()..color = const Color(0xFFD9412F));
    }
    if (rig.van) _van(canvas, geo.van);
  }

  void _blotch(Canvas canvas, Offset c, int s) {
    final r = math.Random(s);
    final base = Paint()..color = const Color(0xFF3A2C20);
    for (var k = 0; k < 5; k++) {
      final o = c.translate((r.nextDouble() - 0.5) * 10, (r.nextDouble() - 0.5) * 8);
      canvas.drawOval(Rect.fromCenter(center: o, width: 7 + r.nextDouble() * 6, height: 5 + r.nextDouble() * 5), base);
    }
    canvas.drawOval(Rect.fromCenter(center: c, width: 12, height: 8), Paint()..color = const Color(0xFF241A12));
    for (var k = 0; k < 4; k++) {
      canvas.drawCircle(c.translate((r.nextDouble() - 0.5) * 18, (r.nextDouble() - 0.5) * 14), 1.2, Paint()..color = const Color(0xFF8A6B4C));
    }
  }

  void _flag(Canvas canvas, Offset foot) {
    canvas.drawLine(foot, foot.translate(0, -16), Paint()..color = const Color(0xFFECECEC)..strokeWidth = 1.6);
    canvas.drawPath(
      Path()
        ..moveTo(foot.dx, foot.dy - 16)
        ..lineTo(foot.dx + 10, foot.dy - 12.5)
        ..lineTo(foot.dx, foot.dy - 9)
        ..close(),
      Paint()..color = const Color(0xFFE5483A),
    );
  }

  void _van(Canvas canvas, Rect r) {
    canvas.drawRRect(RRect.fromRectAndRadius(r.translate(2, 3), const Radius.circular(5)), Paint()..color = const Color(0x55000000));
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(5)),
        Paint()..shader = const LinearGradient(colors: [Color(0xFFF4F4F0), Color(0xFFC9CCD0)]).createShader(r));
    canvas.drawRect(Rect.fromLTWH(r.right - 16, r.top + 4, 12, r.height - 8), Paint()..color = const Color(0xFF7CA6C4));
    canvas.drawRect(Rect.fromLTWH(r.left, r.center.dy - 2, r.width - 18, 4), Paint()..color = const Color(0xFFE08A2E));
    // The TDR screen through the side door.
    canvas.drawRect(Rect.fromLTWH(r.left + 8, r.top + 6, 18, 12), Paint()..color = const Color(0xFF0E2A1E));
    canvas.drawLine(Offset(r.left + 9, r.top + 13), Offset(r.left + 25, r.top + 13), Paint()..color = const Color(0xFF59E39A)..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(M5CrlStreetPainter old) => old.geo != geo || old.rig != rig || old.seed != seed;
}

/// The route map card: the same streets, both feeder routes in one style,
/// their labels at the branch ends.
class M5CrlMapPainter extends CustomPainter {
  M5CrlMapPainter({required this.geo, required this.ownLabel, required this.otherLabel, required this.labelStyle});

  final M5CrlGeo geo;
  final String ownLabel;
  final String otherLabel;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final paper = Offset.zero & size;
    canvas.drawRRect(RRect.fromRectAndRadius(paper, const Radius.circular(10)),
        Paint()..shader = const LinearGradient(colors: [Color(0xFFF6EFD9), Color(0xFFE9DFC2)]).createShader(paper));
    // Fit the play area (top … gate + yard) into the card.
    final src = Rect.fromLTRB(0, geo.top - 22, 360, geo.gateY + 30);
    final k = math.min((size.width - 24) / src.width, (size.height - 24) / src.height);
    final dx = (size.width - src.width * k) / 2;
    final dy = (size.height - src.height * k) / 2;
    Offset m(Offset p) => Offset(dx + (p.dx - src.left) * k, dy + (p.dy - src.top) * k);
    void line(List<Offset> p, Paint paint) {
      final path = Path()..moveTo(m(p.first).dx, m(p.first).dy);
      for (final q in p.skip(1)) {
        path.lineTo(m(q).dx, m(q).dy);
      }
      canvas.drawPath(path, paint);
    }

    final street = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14 * k
      ..color = const Color(0xFFC9C0A6);
    line(geo.lane, street..strokeWidth = 11 * k);
    street.strokeWidth = 14 * k;
    line(geo.own, street);
    line(geo.other, street);
    // Both routes: one style (the same colour, width and dash).
    final route = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..color = const Color(0xFFB0412E);
    // The trunk carries both cables; then one goes up each branch.
    line(geo.own, route);
    line(geo.other, route);
    // The gate.
    final g = m(geo.gate.translate(0, 14));
    canvas.drawRect(Rect.fromCenter(center: g, width: 40 * k, height: 16 * k), Paint()..color = const Color(0xFF6E6A5C));
    // Labels at the branch ends (the only difference between the routes).
    void label(Offset end, String text) {
      final tp = TextPainter(text: TextSpan(text: text, style: labelStyle), textDirection: TextDirection.ltr)..layout(maxWidth: 120);
      final c = m(end);
      var x = c.dx - tp.width / 2;
      x = x.clamp(4.0, size.width - tp.width - 4);
      final box = Rect.fromLTWH(x - 4, c.dy - tp.height - 8, tp.width + 8, tp.height + 4);
      canvas.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(4)), Paint()..color = const Color(0xFFFFFBEF));
      canvas.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(4)), Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xFFB0412E));
      tp.paint(canvas, Offset(x, c.dy - tp.height - 6));
    }

    label(geo.own.last, ownLabel);
    label(geo.other.last, otherLabel);
  }

  @override
  bool shouldRepaint(M5CrlMapPainter old) => old.geo != geo || old.ownLabel != ownLabel || old.otherLabel != otherLabel;
}

/// The TDR screen: the launch pulse at the left; a reflection dip where the
/// fault answers ([at] 0..1 of the screen's range), or a flat line.
class M5CrlTdrPainter extends CustomPainter {
  M5CrlTdrPainter({required this.at, required this.arc});

  /// The reflection's place on the screen, or null (a blank trace).
  final double? at;

  /// The thumper's arc is on (ARM): the dip is sharp.
  final bool arc;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(6)), Paint()..color = const Color(0xFF07170F));
    final grid = Paint()
      ..color = const Color(0x3359E39A)
      ..strokeWidth = 0.8;
    for (var x = 0.0; x < size.width; x += size.width / 8) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += size.height / 4) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final base = size.height * 0.45;
    final path = Path()..moveTo(4, base);
    path.lineTo(10, base - size.height * 0.32);
    path.lineTo(16, base);
    final a = at;
    final dipX = a == null ? null : 20 + a * (size.width - 30);
    for (var x = 16.0; x < size.width - 4; x += 2) {
      var y = base + math.sin(x * 0.9) * 0.6;
      if (dipX != null && (x - dipX).abs() < 8) {
        final k = 1 - (x - dipX).abs() / 8;
        y += size.height * (arc ? 0.36 : 0.28) * k;
      }
      path.lineTo(x, y);
    }
    canvas.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = const Color(0xFF59E39A));
  }

  @override
  bool shouldRepaint(M5CrlTdrPainter old) => old.at != at || old.arc != arc;
}

/// A joint pit, close up: the concrete rim, the cable and its joint sleeve in
/// the dark; only the torch beam's circle shows what is there (a burnt joint's
/// soot and cracks too). The cover slides up as it is dragged ([lift] 0..1).
class M5CrlPitPainter extends CustomPainter {
  M5CrlPitPainter({required this.burnt, required this.lift, required this.beam, required this.beamR});

  final bool burnt;
  final double lift;

  /// The torch beam's centre (local px), or null (no light yet).
  final Offset? beam;
  final double beamR;

  @override
  void paint(Canvas canvas, Size size) {
    final rim = Offset.zero & size;
    canvas.drawRRect(RRect.fromRectAndRadius(rim, const Radius.circular(8)),
        Paint()..shader = const LinearGradient(colors: [Color(0xFFA7A396), Color(0xFF7A776B)]).createShader(rim));
    final hole = rim.deflate(14);
    canvas.drawRect(hole, Paint()..color = const Color(0xFF070809));
    final b = beam;
    if (b != null && lift >= 1) {
      canvas.save();
      canvas.clipRect(hole);
      canvas.clipPath(Path()..addOval(Rect.fromCircle(center: b, radius: beamR)));
      _inside(canvas, hole);
      canvas.restore();
      canvas.drawCircle(b, beamR, Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0x22FFF3C4)
        ..strokeWidth = 2);
    }
    if (lift < 1) {
      final cover = hole.inflate(6).translate(0, -lift * (hole.height + 20));
      canvas.save();
      canvas.clipRect(rim.inflate(40));
      canvas.drawRect(cover.translate(2, 3), Paint()..color = const Color(0x66000000));
      canvas.drawRect(cover, Paint()..shader = const LinearGradient(colors: [Color(0xFFC4C1B5), Color(0xFF8F8C80)]).createShader(cover));
      final grip = Paint()
        ..color = const Color(0xFF55534B)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(cover.center.translate(-22, 0), cover.center.translate(22, 0), grip);
      for (var i = 1; i < 4; i++) {
        final y = cover.top + cover.height * i / 4;
        canvas.drawLine(Offset(cover.left + 8, y), Offset(cover.right - 8, y), Paint()..color = const Color(0x22000000)..strokeWidth = 1);
      }
      canvas.restore();
    }
  }

  void _inside(Canvas canvas, Rect hole) {
    canvas.drawRect(hole, Paint()..shader = const LinearGradient(colors: [Color(0xFF5C5144), Color(0xFF3F372E)]).createShader(hole));
    // Wet soil specks.
    final r = math.Random(7);
    for (var k = 0; k < 40; k++) {
      canvas.drawCircle(Offset(hole.left + r.nextDouble() * hole.width, hole.top + r.nextDouble() * hole.height), 1.4,
          Paint()..color = const Color(0x55211A14));
    }
    final y = hole.center.dy + 6;
    final cable = Paint()
      ..color = const Color(0xFF1B1C1F)
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(hole.left - 4, y), Offset(hole.right + 4, y), cable);
    final sleeve = Rect.fromCenter(center: Offset(hole.center.dx, y), width: hole.width * 0.38, height: 26);
    canvas.drawRRect(RRect.fromRectAndRadius(sleeve, const Radius.circular(12)),
        Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3A3D42), Color(0xFF15161A)]).createShader(sleeve));
    if (burnt) {
      canvas.drawOval(sleeve.inflate(10).translate(6, -6), Paint()..color = const Color(0xCC0D0A08));
      canvas.drawOval(Rect.fromCenter(center: sleeve.center.translate(4, -2), width: 26, height: 14), Paint()..color = const Color(0xFF7A3B1C));
      final crack = Paint()
        ..color = const Color(0xFFE0A44A)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke;
      canvas.drawPath(
        Path()
          ..moveTo(sleeve.center.dx - 10, sleeve.top + 4)
          ..lineTo(sleeve.center.dx - 2, sleeve.center.dy)
          ..lineTo(sleeve.center.dx - 8, sleeve.bottom - 4)
          ..moveTo(sleeve.center.dx + 8, sleeve.top + 6)
          ..lineTo(sleeve.center.dx + 14, sleeve.center.dy + 2),
        crack,
      );
    } else {
      canvas.drawLine(Offset(sleeve.left + 10, sleeve.top + 6), Offset(sleeve.right - 10, sleeve.top + 6),
          Paint()..color = const Color(0x55FFFFFF)..strokeWidth = 1.4);
    }
  }

  @override
  bool shouldRepaint(M5CrlPitPainter old) => old.burnt != burnt || old.lift != lift || old.beam != beam || old.beamR != beamR;
}
