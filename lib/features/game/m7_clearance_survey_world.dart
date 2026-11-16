import 'dart:math' as math;

import 'package:flutter/material.dart';

// The drawn world of lesson 7.3 কাজ 1 "আইনের মাপজোখ" (m7_clearance_survey.dart):
// a semi-urban patrol road, one site at a time, every site drawn to one fixed
// scale (metres → design px, the same for the whole play).
//
// Three kinds of site (lesson 7.3 sections 1–2):
//  * road  — a span across the road between two poles, sagging to its lowest
//    point mid-span; the road's centre line under it, the kerb at the left
//    pole's foot.
//  * roof  — a two-storey house under the line, a চিলেকোঠা (stair room) on
//    the roof on most plays; the line runs level over it to a pole beside the
//    house.
//  * side  — a two-storey house beside the line, a first-floor balcony on most
//    plays; the pole's crossarm carries the conductor (seen end-on) beside it.
//
// Every site has a small pole plate a worker reads (415 V / 11 kV / 33 kV).
// No other text in the art. Nothing marks the points the tape snaps to: every
// feature (the wire, the pole's crossarm, the road, the roof, the চিলেকোঠা top,
// the wall, the balcony edge, a window sill, the house's foot) is a plain part
// of the drawing.
//
// Design: 360 wide × the scene's height; the ground follows the bottom of the
// screen. Heights in metres go up from the ground; x in metres from the
// site's left edge (kM7ClrSiteW wide).

/// The kind of site (one of each per play).
enum M7ClrPlace { road, roof, side }

/// The line's voltage (the pole plate).
enum M7ClrVolt { lt, kv11, kv33 }

/// The points the tape's handles snap to (every one alike).
enum M7ClrPoint {
  // road
  attachL,
  attachR,
  wireLow,
  wireQuarter,
  roadMid,
  roadKerb,
  // roof
  attach,
  wireTop,
  wireRoof,
  chileTop,
  roofTop,
  sill,
  houseFoot,
  // side
  conductor,
  poleArm,
  wallFace,
  balconyEdge,
  roofCorner,
}

/// A site is this wide (metres).
const double kM7ClrSiteW = 10.6;

/// The house's height (two storeys) and the চিলেকোঠা's.
const double kM7ClrHouseH = 6.0;
const double kM7ClrChileH = 2.4;

/// The side site's conductor height and balcony.
const double kM7ClrSideWireH = 4.4;
const double kM7ClrBalconyD = 1.2;
const double kM7ClrRailTop = 3.9;

/// One site as drawn: where every snap point is (metres).
@immutable
class M7ClrLayout {
  const M7ClrLayout({
    required this.place,
    required this.points,
    required this.mirror,
    this.sagT = 0,
    this.chile = false,
    this.balcony = false,
    required this.wireH,
  });

  final M7ClrPlace place;
  final Map<M7ClrPoint, Offset> points;
  final bool mirror;

  /// Road: the sag (tenths of a metre) from the poles' attachment to the low point.
  final int sagT;
  final bool chile;
  final bool balcony;

  /// The wire's height at its low point / over the house / at the crossarm.
  final double wireH;

  /// The tape's reading between two points (metres, tenths): the tape locks
  /// to the longer axis (vertical or horizontal).
  static int readingT(Offset a, Offset b) {
    final dx = (a.dx - b.dx).abs();
    final dy = (a.dy - b.dy).abs();
    return ((dy >= dx ? dy : dx) * 10).round();
  }

  /// The tape locks vertical between these two points.
  static bool vertical(Offset a, Offset b) => (a.dy - b.dy).abs() >= (a.dx - b.dx).abs();
}

/// Builds a site's snap points. [readingT] is the true clearance (tenths).
M7ClrLayout m7ClrLayout({
  required M7ClrPlace place,
  required int readingT,
  required bool mirror,
  int sagT = 8,
  bool chile = true,
  bool balcony = true,
}) {
  final r = readingT / 10;
  double mx(double x) => mirror ? kM7ClrSiteW - x : x;
  switch (place) {
    case M7ClrPlace.road:
      final sag = sagT / 10;
      final h = r + sag;
      // The span is symmetric (poles at 1.6 and 9.0); the kerb point is always
      // the left pole's foot.
      const l = 1.6, rt = 9.0, mid = (l + rt) / 2;
      final q = mirror ? mid + (mid - l) / 2 : mid - (mid - l) / 2;
      final qy = r + sag * math.pow((q - mid) / (mid - l), 2);
      return M7ClrLayout(
        place: place,
        mirror: mirror,
        sagT: sagT,
        wireH: r,
        points: {
          M7ClrPoint.attachL: Offset(l, h),
          M7ClrPoint.attachR: Offset(rt, h),
          M7ClrPoint.wireLow: Offset(mid, r),
          M7ClrPoint.wireQuarter: Offset(q, qy.toDouble()),
          M7ClrPoint.roadMid: const Offset(mid, 0),
          M7ClrPoint.roadKerb: const Offset(l, 0),
        },
      );
    case M7ClrPlace.roof:
      final top = chile ? kM7ClrHouseH + kM7ClrChileH : kM7ClrHouseH;
      final wh = top + r;
      final houseL = math.min(mx(2.4), mx(8.4));
      return M7ClrLayout(
        place: place,
        mirror: mirror,
        chile: chile,
        wireH: wh,
        points: {
          M7ClrPoint.attach: Offset(mx(9.9), wh),
          M7ClrPoint.wireTop: Offset(mx(4.5), wh),
          if (chile) ...{
            M7ClrPoint.chileTop: Offset(mx(4.5), top),
            M7ClrPoint.wireRoof: Offset(mx(7.0), wh),
            M7ClrPoint.roofTop: Offset(mx(7.0), kM7ClrHouseH),
          } else ...{
            M7ClrPoint.roofTop: Offset(mx(4.5), kM7ClrHouseH),
            M7ClrPoint.sill: Offset(mx(6.6), 4.0),
          },
          M7ClrPoint.houseFoot: Offset(houseL, 0),
        },
      );
    case M7ClrPlace.side:
      const wall = 3.0;
      final face = balcony ? wall + kM7ClrBalconyD : wall;
      final cx = face + r;
      return M7ClrLayout(
        place: place,
        mirror: mirror,
        balcony: balcony,
        wireH: kM7ClrSideWireH,
        points: {
          M7ClrPoint.conductor: Offset(mx(cx), kM7ClrSideWireH),
          M7ClrPoint.poleArm: Offset(mx(cx + 1.0), kM7ClrSideWireH),
          M7ClrPoint.wallFace: Offset(mx(wall), kM7ClrSideWireH),
          if (balcony) M7ClrPoint.balconyEdge: Offset(mx(face), kM7ClrRailTop),
          M7ClrPoint.roofCorner: Offset(mx(wall), kM7ClrHouseH),
        },
      );
  }
}

/// Where things are (design px, 360 wide).
@immutable
class M7ClrGeo {
  const M7ClrGeo._(this.height, this.floorY);

  factory M7ClrGeo.forScene(double height, double inset) => M7ClrGeo._(height, height - floorUp - inset * 0.5);

  final double height;

  /// The ground line.
  final double floorY;

  /// The ground sits this far above the bottom (the button row under it).
  static const double floorUp = 96;

  /// The top of the working area (under the header).
  static const double top = 132;

  /// A handle snaps to a point within this distance of where it is let go.
  static const double snap = 30;

  /// The working height.
  double get a => floorY - top - 8;

  /// The one scale (px per metre) for every site of the play.
  double get scale => math.min(34.0, a / 16);

  /// The site's left edge.
  double get ox => (360 - kM7ClrSiteW * scale) / 2;

  /// A point in metres → design px.
  Offset at(Offset m) => Offset(ox + m.dx * scale, floorY - m.dy * scale);
  double x(double m) => ox + m * scale;
  double yAt(double m) => floorY - m * scale;

  /// The tape's case (handles park here between measures).
  Offset park(int handle) => Offset(handle == 0 ? 162 : 202, top + 26);
  Rect get caseRect => Rect.fromCenter(center: Offset(182, top + 26), width: 92, height: 34);
  Rect parkHit(int handle) => Rect.fromCircle(center: park(handle), radius: 19);

  /// Where the trainee stands (left, on the footpath).
  Rect get trainee => Rect.fromLTWH(2, floorY - 98, 42, 98);

  /// The nearest of [points] to [p] within [snap] (design px), or null.
  M7ClrPoint? snapTo(Offset p, Map<M7ClrPoint, Offset> points, {Set<M7ClrPoint> except = const {}}) {
    M7ClrPoint? best;
    var bd = snap;
    for (final e in points.entries) {
      if (except.contains(e.key)) continue;
      final d = (at(e.value) - p).distance;
      if (d <= bd) {
        bd = d;
        best = e.key;
      }
    }
    return best;
  }

  @override
  bool operator ==(Object other) => other is M7ClrGeo && other.height == height && other.floorY == floorY;

  @override
  int get hashCode => Object.hash(height, floorY);
}

String m7ClrPlate(M7ClrVolt v) => switch (v) {
      M7ClrVolt.lt => '415 V',
      M7ClrVolt.kv11 => '11 kV',
      M7ClrVolt.kv33 => '33 kV',
    };

// ============================================================================
// Painters
// ============================================================================

const _sky0 = Color(0xFF8EC5E8);
const _sky1 = Color(0xFFDDEFF7);
const _concrete0 = Color(0xFFB8B4AA);
const _concrete1 = Color(0xFF8D887E);
const _wire = Color(0xFF1E2228);

/// The site, still (it repaints only when the site changes).
class M7ClrSitePainter extends CustomPainter {
  M7ClrSitePainter({required this.geo, required this.layout, required this.volt});

  final M7ClrGeo geo;
  final M7ClrLayout layout;
  final M7ClrVolt volt;

  double _mx(double x) => layout.mirror ? kM7ClrSiteW - x : x;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final g = geo;
    // Sky.
    c.drawRect(
      Rect.fromLTWH(0, 0, w, g.floorY),
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_sky0, _sky1]).createShader(Rect.fromLTWH(0, 0, w, g.floorY)),
    );
    // Far town (a soft band of roofs).
    final far = Path()..moveTo(0, g.floorY);
    final rnd = math.Random(layout.place.index * 7 + (layout.mirror ? 1 : 0));
    var fx = 0.0;
    while (fx < w) {
      final bw = 28.0 + rnd.nextInt(30);
      final bh = 30.0 + rnd.nextInt(46);
      far
        ..lineTo(fx, g.floorY - bh)
        ..lineTo(fx + bw, g.floorY - bh);
      fx += bw;
    }
    far
      ..lineTo(w, g.floorY)
      ..close();
    c.drawPath(far, Paint()..color = const Color(0x33506A80));
    // Ground: the footpath strip to the bottom.
    c.drawRect(Rect.fromLTWH(0, g.floorY, w, size.height - g.floorY), Paint()..color = const Color(0xFF8C8577));
    c.drawRect(Rect.fromLTWH(0, g.floorY, w, 6), Paint()..color = const Color(0xFF6E685D));
    switch (layout.place) {
      case M7ClrPlace.road:
        _road(c, w);
      case M7ClrPlace.roof:
        _roof(c, w);
      case M7ClrPlace.side:
        _side(c, w);
    }
  }

  void _pole(Canvas c, double xm, double hm, {bool plate = false, double plateH = 4.8}) {
    final g = geo;
    final x = g.x(xm);
    final top = g.yAt(hm);
    final bw = math.max(5.0, g.scale * 0.28);
    final tw = bw * 0.62;
    final path = Path()
      ..moveTo(x - bw / 2, g.floorY + 2)
      ..lineTo(x - tw / 2, top)
      ..lineTo(x + tw / 2, top)
      ..lineTo(x + bw / 2, g.floorY + 2)
      ..close();
    c.drawPath(path, Paint()..shader = const LinearGradient(colors: [_concrete0, _concrete1]).createShader(Rect.fromLTRB(x - bw, top, x + bw, g.floorY)));
    // High on the pole, inside the screen and clear of the corner guide.
    if (plate) _plate(c, x.clamp(22.0, 338.0), g.yAt(plateH));
  }

  void _plate(Canvas c, double x, double y) {
    final r = Rect.fromCenter(center: Offset(x, y), width: 36, height: 16);
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), Paint()..color = const Color(0xFFF7F4EA));
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFFB3261E)
      ..strokeWidth = 1.2);
    final tp = TextPainter(
      text: TextSpan(text: m7ClrPlate(volt), style: const TextStyle(color: Color(0xFFB3261E), fontSize: 9.5, fontWeight: FontWeight.w800)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(x - tp.width / 2, y - tp.height / 2));
  }

  void _insulator(Canvas c, Offset p) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: p.translate(0, 4), width: 6, height: 9), const Radius.circular(2)), Paint()..color = const Color(0xFF9C6B3E));
  }

  void _arm(Canvas c, double xm, double hm, double half) {
    final g = geo;
    c.drawRect(Rect.fromLTRB(g.x(xm - half), g.yAt(hm) + 3, g.x(xm + half), g.yAt(hm) + 7), Paint()..color = const Color(0xFF5B5F66));
  }

  void _road(Canvas c, double w) {
    final g = geo;
    final p = layout.points;
    // The road surface under the span.
    final roadTop = g.floorY - 2;
    c.drawRect(Rect.fromLTRB(g.x(2.1), roadTop, g.x(8.5), roadTop + 30), Paint()..color = const Color(0xFF3D4047));
    final dash = Paint()
      ..color = const Color(0xFFEDEDED)
      ..strokeWidth = 2;
    for (var x = g.x(2.4); x < g.x(8.3); x += 18) {
      c.drawLine(Offset(x, roadTop + 14), Offset(x + 9, roadTop + 14), dash);
    }
    // Kerbs.
    c.drawRect(Rect.fromLTRB(g.x(1.9), roadTop - 4, g.x(2.1), roadTop + 30), Paint()..color = const Color(0xFFD9D4C6));
    c.drawRect(Rect.fromLTRB(g.x(8.5), roadTop - 4, g.x(8.7), roadTop + 30), Paint()..color = const Color(0xFFD9D4C6));
    final aL = p[M7ClrPoint.attachL]!;
    final aR = p[M7ClrPoint.attachR]!;
    // The plate on the left pole (the right one stands by the corner guide).
    _pole(c, aL.dx, aL.dy + 0.5, plate: true);
    _pole(c, aR.dx, aR.dy + 0.5);
    _arm(c, aL.dx, aL.dy, 0.7);
    _arm(c, aR.dx, aR.dy, 0.7);
    _insulator(c, g.at(aL));
    _insulator(c, g.at(aR));
    // The span: a parabola through the low point.
    final pl = g.at(aL);
    final pr = g.at(aR);
    final low = g.at(p[M7ClrPoint.wireLow]!);
    final ctrl = Offset(low.dx, 2 * low.dy - pl.dy);
    final span = Path()
      ..moveTo(pl.dx, pl.dy)
      ..quadraticBezierTo(ctrl.dx, ctrl.dy, pr.dx, pr.dy);
    c.drawPath(span, Paint()
      ..style = PaintingStyle.stroke
      ..color = _wire
      ..strokeWidth = 2);
    // The span runs on past the poles (off the picture).
    c.drawLine(pl, Offset(0, pl.dy + 6), Paint()
      ..color = _wire
      ..strokeWidth = 2);
    c.drawLine(pr, Offset(w, pr.dy + 6), Paint()
      ..color = _wire
      ..strokeWidth = 2);
  }

  void _house(Canvas c, double l, double r, {required bool windowsLeft}) {
    final g = geo;
    final body = Rect.fromLTRB(g.x(l), g.yAt(kM7ClrHouseH), g.x(r), g.floorY + 1);
    c.drawRect(body, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF1D9B5), Color(0xFFD9BC92)]).createShader(body));
    // Floor band at the first floor and the roof slab.
    c.drawRect(Rect.fromLTRB(body.left - 2, g.yAt(3.0) - 2, body.right + 2, g.yAt(3.0) + 2), Paint()..color = const Color(0xFFB99A70));
    c.drawRect(Rect.fromLTRB(body.left - 3, g.yAt(kM7ClrHouseH) - 2, body.right + 3, g.yAt(kM7ClrHouseH) + 3), Paint()..color = const Color(0xFFA88A62));
    // Windows (two a floor).
    final wp = Paint()..color = const Color(0xFF51708A);
    final frame = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF6E5638)
      ..strokeWidth = 1.4;
    for (final fy in [1.0, 4.0]) {
      for (final fxm in [0.28, 0.66]) {
        final cx = body.left + body.width * fxm;
        final win = Rect.fromLTWH(cx - g.scale * 0.45, g.yAt(fy + 1.2), g.scale * 0.9, g.scale * 1.2);
        c.drawRect(win, wp);
        c.drawRect(win, frame);
      }
    }
    // A door on the ground floor.
    final dx = windowsLeft ? body.right - g.scale * 1.1 : body.left + g.scale * 0.3;
    c.drawRect(Rect.fromLTWH(dx, g.yAt(2.1), g.scale * 0.8, g.scale * 2.1), Paint()..color = const Color(0xFF7A4E2D));
  }

  void _roof(Canvas c, double w) {
    final g = geo;
    final p = layout.points;
    final l = math.min(_mx(2.4), _mx(8.4));
    final r = math.max(_mx(2.4), _mx(8.4));
    _house(c, l, r, windowsLeft: !layout.mirror);
    if (layout.chile) {
      final cx = _mx(4.5);
      final room = Rect.fromLTRB(g.x(cx - 1.1), g.yAt(kM7ClrHouseH + kM7ClrChileH), g.x(cx + 1.1), g.yAt(kM7ClrHouseH));
      c.drawRect(room, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE9CFA7), Color(0xFFCFB287)]).createShader(room));
      c.drawRect(Rect.fromLTRB(room.left - 2, room.top - 2, room.right + 2, room.top + 2), Paint()..color = const Color(0xFFA88A62));
      c.drawRect(Rect.fromLTWH(room.center.dx - g.scale * 0.35, g.yAt(kM7ClrHouseH + 1.9), g.scale * 0.7, g.scale * 1.9), Paint()..color = const Color(0xFF7A4E2D));
    }
    // The line: level over the house to a pole beside it.
    final a = p[M7ClrPoint.attach]!;
    _pole(c, a.dx, a.dy + 0.5, plate: true, plateH: a.dy - 1.0);
    _arm(c, a.dx, a.dy, 0.7);
    _insulator(c, g.at(a));
    final y = g.yAt(layout.wireH);
    c.drawLine(Offset(layout.mirror ? w : 0, y), g.at(a), Paint()
      ..color = _wire
      ..strokeWidth = 2);
    // On past the pole.
    c.drawLine(g.at(a), Offset(layout.mirror ? 0 : w, y + 5), Paint()
      ..color = _wire
      ..strokeWidth = 2);
  }

  void _side(Canvas c, double w) {
    final g = geo;
    final p = layout.points;
    final l = math.min(_mx(-0.4), _mx(3.0));
    final r = math.max(_mx(-0.4), _mx(3.0));
    _house(c, l, r, windowsLeft: layout.mirror);
    if (layout.balcony) {
      final wall = _mx(3.0);
      final edge = _mx(3.0 + kM7ClrBalconyD);
      final bl = math.min(wall, edge), br = math.max(wall, edge);
      // Slab.
      c.drawRect(Rect.fromLTRB(g.x(bl), g.yAt(3.0) - 3, g.x(br), g.yAt(3.0) + 4), Paint()..color = const Color(0xFFA88A62));
      // Railing.
      final rail = Paint()
        ..color = const Color(0xFF4A4F57)
        ..strokeWidth = 1.6;
      c.drawLine(Offset(g.x(bl), g.yAt(kM7ClrRailTop)), Offset(g.x(br), g.yAt(kM7ClrRailTop)), rail..strokeWidth = 2.4);
      rail.strokeWidth = 1.4;
      for (var k = 0; k <= 6; k++) {
        final x = g.x(bl) + (g.x(br) - g.x(bl)) * k / 6;
        c.drawLine(Offset(x, g.yAt(kM7ClrRailTop)), Offset(x, g.yAt(3.0)), rail);
      }
    }
    // The pole, its crossarm and the two conductors (end-on).
    final arm = p[M7ClrPoint.poleArm]!;
    final cond = p[M7ClrPoint.conductor]!;
    _pole(c, arm.dx, kM7ClrSideWireH + 0.8, plate: true, plateH: 3.2);
    final half = 1.15;
    _arm(c, arm.dx, kM7ClrSideWireH - 0.15, half);
    final far = Offset(arm.dx + (arm.dx - cond.dx), cond.dy);
    for (final q in [cond, far]) {
      final at = g.at(q);
      _insulator(c, at.translate(0, 2));
      c.drawCircle(at, 3.4, Paint()..color = _wire);
    }
  }

  @override
  bool shouldRepaint(M7ClrSitePainter old) => old.geo != geo || old.layout != layout || old.volt != volt;
}

/// The measuring tape: its case, the two handles and the tape between them.
class M7ClrTapePainter extends CustomPainter {
  M7ClrTapePainter({required this.geo, required this.handles, required this.locked});

  final M7ClrGeo geo;

  /// Each handle's place now (design px).
  final List<Offset> handles;

  /// Both handles are on points: the tape locks to its axis.
  final bool locked;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final cr = RRect.fromRectAndRadius(g.caseRect, const Radius.circular(10));
    c.drawRRect(cr, Paint()..color = const Color(0xFF283548));
    c.drawRRect(cr, Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFFF2C14E)
      ..strokeWidth = 1.6);
    final a = handles[0], b = handles[1];
    final parkedA = (a - g.park(0)).distance < 1;
    final parkedB = (b - g.park(1)).distance < 1;
    if (!(parkedA && parkedB)) {
      final band = Paint()
        ..color = const Color(0xFFF7D046)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      if (locked) {
        final v = (a.dy - b.dy).abs() >= (a.dx - b.dx).abs();
        final corner = v ? Offset(a.dx, b.dy) : Offset(b.dx, a.dy);
        c.drawLine(a, corner, band);
        _ticks(c, a, corner);
        if ((corner - b).distance > 1) {
          c.drawLine(corner, b, Paint()
            ..color = const Color(0x99F7D046)
            ..strokeWidth = 1.2);
        }
      } else {
        c.drawLine(a, b, band);
      }
    }
    for (final h in [a, b]) {
      c.drawCircle(h, 11, Paint()..color = const Color(0xFFF2C14E));
      c.drawCircle(h, 11, Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xFF3A2A08)
        ..strokeWidth = 2);
      c.drawCircle(h, 3, Paint()..color = const Color(0xFF3A2A08));
    }
  }

  void _ticks(Canvas c, Offset from, Offset to) {
    final len = (to - from).distance;
    if (len < 4) return;
    final step = geo.scale / 2;
    final dir = (to - from) / len;
    final n = Offset(-dir.dy, dir.dx);
    final p = Paint()
      ..color = const Color(0xFF3A2A08)
      ..strokeWidth = 1;
    for (var d = step; d < len; d += step) {
      final q = from + dir * d;
      c.drawLine(q - n * 2, q + n * 2, p);
    }
  }

  @override
  bool shouldRepaint(M7ClrTapePainter old) => old.geo != geo || old.locked != locked || old.handles[0] != handles[0] || old.handles[1] != handles[1];
}
