import 'dart:math' as math;

import 'package:flutter/material.dart';

// The drawn world of lesson 4.3 কাজ 1 "কানেকশনের প্রস্তুতি"
// (m4_service_plan.dart): a village road with the LT pole on the near side
// and the consumer's new house across the road (no service line yet), a tree
// and a neighbour's house between; the trainee by the pole; in the
// foreground his planning board (a clipboard on the site table): the
// papers, the survey sketch, the material shelf or the work order.
//
// Everything here is still (no clock): an idle scene draws no frames.

/// The four rounds of the plan.
enum M4ServicePlanRound { papers, route, kit, order }

/// The three papers the lesson asks for before the work starts.
enum M4ServicePlanPaper { order, meter, permit }

/// What is wrong with the papers this play (none: all three in order).
enum M4ServicePlanFault { none, orderUnapproved, meterMissing, permitMissing }

/// The routes on the survey sketch.
enum M4ServicePlanRoute { straight, tree, roof, detour }

/// The things on the store shelf.
enum M4ServicePlanItem { cable, thinCable, giWire, rackBolt, clamp, ipc, straps, tape }

/// The work order's steps (lesson 4.3, points 2–4), in the right order.
enum M4ServicePlanStep { anchor, giWire, strap, connect }

extension M4ServicePlanFaultInfo on M4ServicePlanFault {
  /// The paper that is missing or not approved.
  M4ServicePlanPaper? get paper => switch (this) {
        M4ServicePlanFault.none => null,
        M4ServicePlanFault.orderUnapproved => M4ServicePlanPaper.order,
        M4ServicePlanFault.meterMissing => M4ServicePlanPaper.meter,
        M4ServicePlanFault.permitMissing => M4ServicePlanPaper.permit,
      };
}

/// Where things are in the scene (design px, 360 wide).
@immutable
class M4ServicePlanGeo {
  const M4ServicePlanGeo._(this.h, this.board);

  factory M4ServicePlanGeo.forScene(double h, double inset) {
    final bottom = h - inset - 8;
    return M4ServicePlanGeo._(h, Rect.fromLTRB(6, bottom - 300, 354, bottom));
  }

  final double h;

  /// The planning board (foreground).
  final Rect board;

  double get groundY => board.top - 6;
  double get horizonY => groundY - 112;
  double get poleX => 58;
  double get poleTop => math.max(112, groundY - 330);

  /// The round's work area on the board.
  Rect get content => Rect.fromLTRB(board.left + 10, board.top + 32, board.right - 10, board.bottom - 66);

  /// The button row at the board's foot.
  Rect get buttons => Rect.fromLTRB(board.left + 12, board.bottom - 60, board.right - 12, board.bottom - 8);

  /// The trainee beside the pole.
  Rect get trainee {
    const fh = 150.0;
    return Rect.fromLTWH(poleX + 18, groundY - fh + 4, fh / 2, fh);
  }

  /// The three paper slots.
  List<Rect> paperSlots() {
    final c = content;
    const gap = 10.0;
    final w = (c.width - gap * 2) / 3;
    return [for (var i = 0; i < 3; i++) Rect.fromLTWH(c.left + (w + gap) * i, c.top + 4, w, c.height - 8)];
  }

  /// The shelf: 4 × 2 tiles in [order].
  Map<M4ServicePlanItem, Rect> shelf(List<M4ServicePlanItem> order) {
    final c = content;
    const gap = 6.0;
    final w = (c.width - gap * 3) / 4;
    final rh = (c.height - gap) / 2;
    return {
      for (final (i, it) in order.indexed) it: Rect.fromLTWH(c.left + (w + gap) * (i % 4), c.top + (rh + gap) * (i ~/ 4), w, rh),
    };
  }

  /// The work-order cards, top to bottom in [order].
  Map<M4ServicePlanStep, Rect> cards(List<M4ServicePlanStep> order) {
    final c = content;
    const gap = 6.0;
    final ch = (c.height - gap * 3) / 4;
    return {
      for (final (i, s) in order.indexed) s: Rect.fromLTWH(c.left + 8, c.top + (ch + gap) * i, c.width - 16, ch),
    };
  }

  @override
  bool operator ==(Object other) => other is M4ServicePlanGeo && other.h == h && other.board == board;
  @override
  int get hashCode => Object.hash(h, board);
}

// ============================================================================
// The survey sketch (top-down; normalised 0..1 in the work area)
// ============================================================================

/// The sketch's places (unmirrored).
abstract final class M4ServicePlanMap {
  static const pole = Offset(0.22, 0.86);
  static const house = Rect.fromLTRB(0.58, 0.04, 0.82, 0.30);
  static const meterAt = Offset(0.64, 0.28);
  static const tree = Offset(0.30, 0.24);
  static const treeR = 0.085;
  static const neighbour = Rect.fromLTRB(0.50, 0.62, 0.70, 0.78);
  static const roadTop = 0.42;
  static const roadBottom = 0.56;

  /// The route's points from the pole to the meter.
  static List<Offset> route(M4ServicePlanRoute r) => switch (r) {
        M4ServicePlanRoute.straight => const [pole, meterAt],
        M4ServicePlanRoute.tree => const [pole, tree, meterAt],
        M4ServicePlanRoute.roof => [pole, neighbour.center, meterAt],
        M4ServicePlanRoute.detour => const [pole, Offset(0.94, 0.92), Offset(0.94, 0.34), meterAt],
      };

  /// Where the route's number sits.
  static Offset chip(M4ServicePlanRoute r) => switch (r) {
        M4ServicePlanRoute.straight => const Offset(0.47, 0.51),
        M4ServicePlanRoute.tree => const Offset(0.27, 0.42),
        M4ServicePlanRoute.roof => const Offset(0.40, 0.80),
        M4ServicePlanRoute.detour => const Offset(0.94, 0.62),
      };

  /// The route's length on the sketch (for the tests: the straight one is shortest).
  static double length(M4ServicePlanRoute r) {
    final p = route(r);
    var s = 0.0;
    for (var i = 1; i < p.length; i++) {
      s += (p[i] - p[i - 1]).distance;
    }
    return s;
  }

  static Offset place(Offset n, Rect area, bool mirror) => Offset(area.left + (mirror ? 1 - n.dx : n.dx) * area.width, area.top + n.dy * area.height);
}

class M4ServicePlanWorldPainter extends CustomPainter {
  const M4ServicePlanWorldPainter({required this.geo});
  final M4ServicePlanGeo geo;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final g = geo;
    final hy = g.horizonY;
    c.drawRect(
        Rect.fromLTWH(0, 0, w, hy + 2),
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF6FA8DC), Color(0xFFBFD9EE), Color(0xFFEFF2E2)])
              .createShader(Rect.fromLTWH(0, 0, w, hy)));
    final cloud = Paint()..color = const Color(0xCCFFFFFF);
    for (final (x, y, s) in [(70.0, 0.22, 1.0), (230.0, 0.14, 0.8), (330.0, 0.3, 0.6)]) {
      final cy = hy * y + 30;
      c.drawOval(Rect.fromCenter(center: Offset(x, cy), width: 70 * s, height: 20 * s), cloud);
      c.drawOval(Rect.fromCenter(center: Offset(x + 14 * s, cy - 8 * s), width: 40 * s, height: 22 * s), cloud);
    }
    // Far fields and trees.
    c.drawRect(Rect.fromLTRB(0, hy - 10, w, hy + 2), Paint()..color = const Color(0xFF9DB79A));
    final farTree = Paint()..color = const Color(0xFF7FA483);
    for (final (x, r) in [(20.0, 12.0), (120.0, 10.0), (346.0, 14.0)]) {
      c.drawCircle(Offset(x, hy - 12 - r * 0.5), r, farTree);
    }
    // Ground: the far verge, the road, the near verge.
    c.drawRect(
        Rect.fromLTRB(0, hy, w, size.height),
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFA9B98C), Color(0xFF8DA36C)])
              .createShader(Rect.fromLTRB(0, hy, w, size.height)));
    final roadTop = hy + 40;
    final roadBottom = hy + 76;
    c.drawRect(Rect.fromLTRB(0, roadTop, w, roadBottom), Paint()..color = const Color(0xFF6E7378));
    final dash = Paint()
      ..color = const Color(0xFFE9E3C9)
      ..strokeWidth = 2;
    for (var x = 8.0; x < w; x += 34) {
      c.drawLine(Offset(x, (roadTop + roadBottom) / 2), Offset(x + 16, (roadTop + roadBottom) / 2), dash);
    }
    c.drawRect(Rect.fromLTRB(0, roadBottom, w, g.groundY + 30), Paint()..color = const Color(0xFFB59E74));
    final peb = Paint()..color = const Color(0xFF9C865E);
    final rnd = math.Random(5);
    for (var i = 0; i < 22; i++) {
      c.drawCircle(Offset(rnd.nextDouble() * w, roadBottom + 4 + rnd.nextDouble() * (g.groundY - roadBottom)), 1 + rnd.nextDouble() * 1.5, peb);
    }
    // Across the road: the tree, the neighbour's house, the new house.
    final baseFar = roadTop - 2;
    _tree(c, Offset(128, baseFar), 30);
    _house(c, Rect.fromLTRB(168, baseFar - 46, 222, baseFar), const Color(0xFFD9C7A6), const Color(0xFF9A5A3C), meter: false);
    final house = Rect.fromLTRB(246, baseFar - 62, 334, baseFar);
    _house(c, house, const Color(0xFFF3EEE2), const Color(0xFF5D7A8C), meter: true);
    _pole(c);
  }

  void _tree(Canvas c, Offset base, double r) {
    c.drawRect(Rect.fromLTWH(base.dx - 3, base.dy - r * 1.3, 6, r * 1.3), Paint()..color = const Color(0xFF6B5A44));
    c.drawCircle(Offset(base.dx, base.dy - r * 1.6), r, Paint()..color = const Color(0xFF5E8F62));
    c.drawCircle(Offset(base.dx - r * 0.5, base.dy - r * 1.3), r * 0.6, Paint()..color = const Color(0xFF6E9F70));
    c.drawCircle(Offset(base.dx + r * 0.5, base.dy - r * 1.9), r * 0.55, Paint()..color = const Color(0xFF7AAE7A));
  }

  void _house(Canvas c, Rect r, Color wall, Color roof, {required bool meter}) {
    c.drawRect(r, Paint()..color = wall);
    c.drawRect(
        r,
        Paint()
          ..color = const Color(0x55000000)
          ..style = PaintingStyle.stroke);
    final roofP = Path()
      ..moveTo(r.left - 5, r.top + 2)
      ..lineTo(r.center.dx, r.top - r.height * 0.32)
      ..lineTo(r.right + 5, r.top + 2)
      ..close();
    c.drawPath(roofP, Paint()..color = roof);
    // A door and a window.
    c.drawRect(Rect.fromLTWH(r.center.dx - 6, r.bottom - 20, 12, 20), Paint()..color = const Color(0xFF7A5536));
    c.drawRect(Rect.fromLTWH(r.left + 8, r.top + 12, 12, 10), Paint()..color = const Color(0xFF8FB4C9));
    if (meter) {
      // The new meter board by the door, waiting for its line.
      final m = Rect.fromLTWH(r.right - 22, r.top + 14, 14, 18);
      c.drawRRect(RRect.fromRectAndRadius(m, const Radius.circular(2)), Paint()..color = const Color(0xFFE9EDF0));
      c.drawRRect(
          RRect.fromRectAndRadius(m, const Radius.circular(2)),
          Paint()
            ..color = const Color(0xFF4F5A63)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2);
      c.drawRect(Rect.fromLTWH(m.left + 3, m.top + 3, 8, 5), Paint()..color = const Color(0xFF263238));
      // The rack bolt on the wall.
      c.drawCircle(Offset(r.left + 10, r.top + 16), 2.4, Paint()..color = const Color(0xFF5B6168));
    }
  }

  void _pole(Canvas c) {
    final g = geo;
    final x = g.poleX;
    final top = g.poleTop;
    final base = g.groundY + 4;
    final pole = Path()
      ..moveTo(x - 5, top)
      ..lineTo(x + 5, top)
      ..lineTo(x + 9, base)
      ..lineTo(x - 9, base)
      ..close();
    c.drawPath(
        pole,
        Paint()
          ..shader = const LinearGradient(colors: [Color(0xFF8E9296), Color(0xFFCBCFD2), Color(0xFF7C8084)]).createShader(Rect.fromLTRB(x - 9, top, x + 9, base)));
    c.drawOval(Rect.fromCenter(center: Offset(x, base + 1), width: 30, height: 7), Paint()..color = const Color(0x55000000));
    final armY = top + 18;
    c.drawRect(Rect.fromLTRB(x - 40, armY - 3, x + 44, armY + 3), Paint()..color = const Color(0xFF4F555B));
    final wire = Paint()
      ..color = const Color(0xFF2B2F33)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;
    for (final dx in [-34.0, -14.0, 14.0, 36.0]) {
      c.drawCircle(Offset(x + dx, armY + 7), 3, Paint()..color = const Color(0xFFEDE7D6));
      // The LT wires run along the road, off both edges.
      final p = Path()
        ..moveTo(0, armY + 9 + dx * 0.04)
        ..quadraticBezierTo(x + dx, armY + 12, 360, armY + 9 - dx * 0.04);
      c.drawPath(p, wire);
    }
  }

  @override
  bool shouldRepaint(M4ServicePlanWorldPainter old) => old.geo != geo;
}

/// The planning board (the site table and the clipboard).
class M4ServicePlanBoardPainter extends CustomPainter {
  const M4ServicePlanBoardPainter({required this.geo});
  final M4ServicePlanGeo geo;

  @override
  void paint(Canvas c, Size size) {
    final b = geo.board;
    c.drawRRect(RRect.fromRectAndRadius(b.shift(const Offset(0, 4)), const Radius.circular(16)), Paint()..color = const Color(0x55000000));
    c.drawRRect(
        RRect.fromRectAndRadius(b, const Radius.circular(16)),
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8A6A44), Color(0xFF6E5233)]).createShader(b));
    // Wood grain.
    final grain = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 1;
    for (var y = b.top + 14; y < b.bottom - 6; y += 13) {
      c.drawLine(Offset(b.left + 10, y), Offset(b.right - 10, y + 2), grain);
    }
    // The clipboard sheet under the round's work.
    final sheet = geo.content.inflate(4);
    c.drawRRect(RRect.fromRectAndRadius(sheet, const Radius.circular(8)), Paint()..color = const Color(0xFFF4EEDD));
    // The clip.
    final clip = Rect.fromCenter(center: Offset(b.center.dx, sheet.top - 2), width: 70, height: 14);
    c.drawRRect(RRect.fromRectAndRadius(clip, const Radius.circular(4)), Paint()..color = const Color(0xFF9EA6AD));
    c.drawRRect(
        RRect.fromRectAndRadius(clip, const Radius.circular(4)),
        Paint()
          ..color = const Color(0xFF5C646B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4);
  }

  @override
  bool shouldRepaint(M4ServicePlanBoardPainter old) => old.geo != geo;
}

/// The survey sketch with the routes (the [picked] one drawn bold).
class M4ServicePlanMapPainter extends CustomPainter {
  const M4ServicePlanMapPainter({required this.routes, required this.mirror, required this.picked});
  final List<M4ServicePlanRoute> routes;
  final bool mirror;
  final M4ServicePlanRoute? picked;

  static const routeColors = [Color(0xFF1E6FD9), Color(0xFFD9541E), Color(0xFF7B3FC4)];

  @override
  void paint(Canvas c, Size size) {
    final a = Offset.zero & size;
    Offset p(Offset n) => M4ServicePlanMap.place(n, a, mirror);
    Rect r(Rect n) => Rect.fromPoints(p(n.topLeft), p(n.bottomRight));
    // Grid paper.
    final grid = Paint()
      ..color = const Color(0x1A3A5A7A)
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 16) {
      c.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = 0.0; y < size.height; y += 16) {
      c.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    // The road.
    final road = Rect.fromLTRB(0, M4ServicePlanMap.roadTop * size.height, size.width, M4ServicePlanMap.roadBottom * size.height);
    c.drawRect(road, Paint()..color = const Color(0xFFB7BCC1));
    final dash = Paint()
      ..color = const Color(0xFFF7F3E6)
      ..strokeWidth = 1.6;
    for (var x = 4.0; x < size.width; x += 22) {
      c.drawLine(Offset(x, road.center.dy), Offset(x + 10, road.center.dy), dash);
    }
    // The LT line along the near side, through the pole.
    final ltY = p(M4ServicePlanMap.pole).dy;
    c.drawLine(
        Offset(0, ltY),
        Offset(size.width, ltY),
        Paint()
          ..color = const Color(0xFF3B4248)
          ..strokeWidth = 1.6);
    // The tree (seen from above).
    final t = p(M4ServicePlanMap.tree);
    final tr = M4ServicePlanMap.treeR * size.width;
    c.drawCircle(t, tr, Paint()..color = const Color(0xFF6E9F70));
    c.drawCircle(t.translate(-tr * 0.3, -tr * 0.2), tr * 0.55, Paint()..color = const Color(0xFF86B786));
    c.drawCircle(
        t,
        tr,
        Paint()
          ..color = const Color(0xFF3F6F45)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4);
    // The neighbour's house (a roof from above) and the new house.
    final n = r(M4ServicePlanMap.neighbour);
    c.drawRect(n, Paint()..color = const Color(0xFFC98A64));
    c.drawLine(n.centerLeft, n.centerRight, Paint()..color = const Color(0xFF8E5537)..strokeWidth = 1.4);
    c.drawRect(n, Paint()..color = const Color(0xFF8E5537)..style = PaintingStyle.stroke..strokeWidth = 1.4);
    final h = r(M4ServicePlanMap.house);
    c.drawRect(h, Paint()..color = const Color(0xFFE6EEF3));
    c.drawRect(h, Paint()..color = const Color(0xFF5D7A8C)..style = PaintingStyle.stroke..strokeWidth = 1.8);
    // The meter point on the new house.
    final m = p(M4ServicePlanMap.meterAt);
    c.drawRect(Rect.fromCenter(center: m, width: 9, height: 9), Paint()..color = const Color(0xFF263238));
    // The pole.
    final pl = p(M4ServicePlanMap.pole);
    c.drawCircle(pl, 7, Paint()..color = const Color(0xFF9AA0A6));
    c.drawCircle(pl, 7, Paint()..color = const Color(0xFF3B4248)..style = PaintingStyle.stroke..strokeWidth = 1.6);
    // The routes (dashed; the picked one bold and solid).
    for (final (i, route) in routes.indexed) {
      final pts = M4ServicePlanMap.route(route).map(p).toList();
      final on = picked == route;
      final paint = Paint()
        ..color = on ? const Color(0xFFE0A100) : routeColors[i % routeColors.length]
        ..strokeWidth = on ? 4 : 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      for (var k = 1; k < pts.length; k++) {
        if (on) {
          c.drawLine(pts[k - 1], pts[k], paint);
        } else {
          _dashed(c, pts[k - 1], pts[k], paint);
        }
      }
    }
  }

  void _dashed(Canvas c, Offset a, Offset b, Paint paint) {
    final d = (b - a).distance;
    if (d == 0) return;
    final dir = (b - a) / d;
    for (var s = 0.0; s < d; s += 10) {
      c.drawLine(a + dir * s, a + dir * math.min(d, s + 6), paint);
    }
  }

  @override
  bool shouldRepaint(M4ServicePlanMapPainter old) => old.picked != picked || old.mirror != mirror || old.routes != routes;
}

/// One thing on the store shelf.
class M4ServicePlanItemPainter extends CustomPainter {
  const M4ServicePlanItemPainter(this.item);
  final M4ServicePlanItem item;

  @override
  void paint(Canvas c, Size s) {
    final cx = s.width / 2;
    final cy = s.height / 2;
    final u = math.min(s.width, s.height) / 60;
    final dark = Paint()..color = const Color(0xFF263238);
    final steel = Paint()
      ..shader = const LinearGradient(colors: [Color(0xFFE3E7EA), Color(0xFF9AA3AA), Color(0xFF6E777E)]).createShader(Offset.zero & s);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    switch (item) {
      case M4ServicePlanItem.cable:
      case M4ServicePlanItem.thinCable:
        // A cable drum (side view): flanges and the coiled cable.
        final thick = item == M4ServicePlanItem.cable;
        final r = 22 * u;
        c.drawCircle(Offset(cx, cy), r, Paint()..color = const Color(0xFF9B7448));
        c.drawCircle(Offset(cx, cy), r, line..color = const Color(0xFF5E4428)..strokeWidth = 2 * u);
        final coil = Paint()
          ..color = const Color(0xFF1C1F22)
          ..style = PaintingStyle.stroke
          ..strokeWidth = (thick ? 4.2 : 1.4) * u;
        final step = (thick ? 5.0 : 2.6) * u;
        for (var rr = 8 * u; rr < r - 3 * u; rr += step) {
          c.drawCircle(Offset(cx, cy), rr, coil);
        }
        c.drawCircle(Offset(cx, cy), 5 * u, Paint()..color = const Color(0xFF5E4428));
        // The loose end.
        c.drawLine(Offset(cx + r - 4 * u, cy + 6 * u), Offset(cx + r + 6 * u, cy + 18 * u), coil);
      case M4ServicePlanItem.giWire:
        // A coil of galvanised steel wire.
        final wire = Paint()
          ..color = const Color(0xFF8D979E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8 * u;
        for (var i = 0; i < 7; i++) {
          c.drawOval(Rect.fromCenter(center: Offset(cx + (i - 3) * 1.6 * u, cy), width: 40 * u, height: 30 * u), wire);
        }
        c.drawOval(
            Rect.fromCenter(center: Offset(cx, cy), width: 46 * u, height: 36 * u),
            Paint()
              ..color = const Color(0xFFC8CFD4)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1 * u);
      case M4ServicePlanItem.rackBolt:
        // A rack bolt: threaded shank, the bracket with its spool.
        c.drawRect(Rect.fromLTWH(cx - 24 * u, cy - 3 * u, 30 * u, 6 * u), steel);
        for (var x = cx - 22 * u; x < cx + 4 * u; x += 3 * u) {
          c.drawLine(Offset(x, cy - 3 * u), Offset(x + 1.5 * u, cy + 3 * u), line..color = const Color(0xFF5C646B)..strokeWidth = 0.8 * u);
        }
        c.drawRect(Rect.fromLTWH(cx + 6 * u, cy - 14 * u, 4 * u, 28 * u), steel);
        c.drawRect(Rect.fromLTWH(cx + 18 * u, cy - 14 * u, 4 * u, 28 * u), steel);
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 9 * u, cy - 9 * u, 10 * u, 18 * u), Radius.circular(3 * u)), Paint()..color = const Color(0xFFEDE7D6));
      case M4ServicePlanItem.clamp:
        // A pole anchor clamp: a steel band with the hook.
        c.drawArc(Rect.fromCenter(center: Offset(cx - 4 * u, cy), width: 34 * u, height: 34 * u), -1.2, 5.6, false, line..color = const Color(0xFF7C858C)..strokeWidth = 4 * u);
        c.drawRect(Rect.fromLTWH(cx + 10 * u, cy - 6 * u, 10 * u, 12 * u), steel);
        c.drawArc(Rect.fromCenter(center: Offset(cx + 24 * u, cy), width: 12 * u, height: 14 * u), -1.6, 3.6, false, line..color = const Color(0xFF5C646B)..strokeWidth = 3 * u);
      case M4ServicePlanItem.ipc:
        // An IPC connector: the black body, the bolt and the shear head.
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy + 4 * u), width: 30 * u, height: 26 * u), Radius.circular(5 * u)), dark);
        c.drawRect(Rect.fromCenter(center: Offset(cx, cy + 4 * u), width: 34 * u, height: 4 * u), Paint()..color = const Color(0xFF455A64));
        c.drawRect(Rect.fromLTWH(cx - 4 * u, cy - 16 * u, 8 * u, 8 * u), steel);
        c.drawRect(Rect.fromLTWH(cx - 3 * u, cy - 22 * u, 6 * u, 6 * u), Paint()..color = const Color(0xFFB0BEC5));
      case M4ServicePlanItem.straps:
        // A bundle of black plastic straps.
        for (var i = 0; i < 6; i++) {
          final y = cy - 12 * u + i * 4.5 * u;
          c.drawLine(Offset(cx - 22 * u, y), Offset(cx + 22 * u, y - 2 * u), line..color = const Color(0xFF1C1F22)..strokeWidth = 2.6 * u);
        }
        c.drawRect(Rect.fromLTWH(cx - 3 * u, cy - 16 * u, 6 * u, 30 * u), Paint()..color = const Color(0xFFD9541E));
      case M4ServicePlanItem.tape:
        // A roll of black insulating tape.
        c.drawCircle(Offset(cx, cy), 18 * u, dark);
        c.drawCircle(Offset(cx, cy), 9 * u, Paint()..color = const Color(0xFFF4EEDD));
        c.drawCircle(Offset(cx, cy), 9 * u, line..color = const Color(0xFF8D6E63)..strokeWidth = 1.6 * u);
        c.drawLine(Offset(cx + 16 * u, cy + 6 * u), Offset(cx + 26 * u, cy + 16 * u), line..color = const Color(0xFF263238)..strokeWidth = 5 * u);
    }
  }

  @override
  bool shouldRepaint(M4ServicePlanItemPainter old) => old.item != item;
}
