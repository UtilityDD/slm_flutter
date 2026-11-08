import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'scene_kit.dart';

// The shutdown site of lesson 1.6 কাজ 2 (পারমিটের সোনালি ধাপ + লাইন ক্লিয়ার):
// a drawn, layered place — sky and clouds, the far tree line and paddy, the
// substation's control-room building on the right with the line running to
// it, the PCC pole with a ladder in the middle ground, the van, and in front
// the supervisor's folding table (his phone, the permit clipboard) and the
// rod and tester on a tarp. A window into the control room (the operator's
// side: the breaker panel, the permit book) hangs top right, tied to the
// building by two faint lines. No words in the art except what a worker would
// read (they are put on as widgets by the page).
//
// Design: 360 wide × the scene's height; the ground row follows the bottom
// of the screen (the corner guide stands bottom right, so the work is left
// and in the middle, the right of the ground row stays clear).

/// Where things stand on the site (design px, 360 wide).
@immutable
class PtwYardGeo {
  const PtwYardGeo({required this.height, required this.ground, required this.topSafe});

  /// The scene of design height [h], bottom system inset [inset] and the
  /// header's height [topSafe] (both design px).
  factory PtwYardGeo.forScene(double h, double inset, double topSafe) => PtwYardGeo(height: h, ground: h - 290 - inset, topSafe: topSafe);

  final double height;

  /// Where the people in the middle ground stand (and the pole enters the soil).
  final double ground;

  /// Below the floating header.
  final double topSafe;

  static const poleX = 124.0;
  static const figure = Size(46, 92);

  double get horizon => ground - 64;
  double get poleTop => math.max(ground - 400, topSafe + 24);
  double get armY => poleTop + 18;

  /// The three insulators' tops: left and right on the cross-arm, one on the pole top.
  List<Offset> get insulators => [Offset(poleX - 42, armY - 13), Offset(poleX, poleTop - 9), Offset(poleX + 42, armY - 13)];

  /// Where the rod's hook sits on the left conductor.
  Offset get hook => Offset(poleX - 60, wireLeftY(0, poleX - 60));

  /// The left conductor [i]'s height at [x] (it sags off to the left edge).
  double wireLeftY(int i, double x) {
    final a = insulators[i];
    final t = (a.dx - x) / a.dx;
    return a.dy + 18 * t - 10 * t * (1 - t);
  }

  Offset get ladderFoot => Offset(poleX + 30, ground + 2);
  Offset get ladderTop => Offset(poleX + 8, armY + 34);

  /// The control room's window (the operator's side).
  Rect get inset => Rect.fromLTWH(184, topSafe + 10, 168, 134);
  Rect get building => Rect.fromLTWH(234, horizon - 94, 122, 94);
  Rect get buildingWindow => Rect.fromLTWH(building.left + 22, building.top + 30, 40, 26);
  Rect get van => Rect.fromLTWH(286, ground - 64, 112, 64);
  Rect get tarp => Rect.fromLTWH(40, ground - 14, 72, 16);
  double get tableTop => ground + 112;
  Rect get table => Rect.fromLTWH(8, tableTop, 142, 11);
  Rect get phone => Rect.fromLTWH(44, tableTop - 52, 34, 52);
  Rect get clipboard => Rect.fromLTWH(90, tableTop - 80, 60, 80);

  /// He stands behind his table (his feet just behind its legs).
  Rect get supervisor => Rect.fromLTWH(-12, tableTop + 40 - 128, 64, 128);
  Offset get earth => Offset(34, ground + 6);

  /// Inside the control-room window (relative to [inset]).
  static const breakerLocal = Rect.fromLTWH(8, 24, 60, 98);
  static const bookLocal = Rect.fromLTWH(98, 70, 62, 34);
  static const operatorLocal = Rect.fromLTWH(64, 38, 44, 88);
  Rect get breaker => breakerLocal.shift(inset.topLeft);
  Rect get book => bookLocal.shift(inset.topLeft);

  /// The rod lying on the tarp (0) or hooked on the line (1): bottom and top ends.
  (Offset, Offset) rodEnds(double t) {
    final b0 = Offset(tarp.left + 6, tarp.bottom - 6);
    final t0 = Offset(tarp.right + 4, tarp.top - 2);
    final b1 = Offset(poleX - 46, ground - 4);
    final t1 = hook;
    return (Offset.lerp(b0, b1, t)!, Offset.lerp(t0, t1, t)!);
  }

  /// Feet of worker [i] of [n] standing at the pole foot.
  Offset crewGround(int i, int n) => Offset((n == 3 ? const [180.0, 218.0, 256.0] : const [188.0, 232.0])[i], ground);

  /// Feet of worker [i] on the ladder (0 = the top one, at the line).
  Offset crewLadder(int i) => Offset.lerp(ladderFoot, ladderTop, const [0.82, 0.50, 0.18][i])!;

  /// A figure standing with its feet at [feet].
  static Rect figureAt(Offset feet) => Rect.fromLTWH(feet.dx - figure.width / 2, feet.dy - figure.height, figure.width, figure.height);

  @override
  bool operator ==(Object other) => other is PtwYardGeo && other.height == height && other.ground == ground && other.topSafe == topSafe;

  @override
  int get hashCode => Object.hash(height, ground, topSafe);
}

/// The people on the site.
abstract final class PtwLooks {
  static const supervisor = LinemanLook(
    helmet: Color(0xFFF5F7FA),
    shirt: Color(0xFF6C7A89),
    vest: Color(0xFF2E8B45),
    pants: Color(0xFF2F3A48),
    skin: Color(0xFF9C6644),
    moustache: true,
  );
  static const crew = LinemanLook(
    helmet: Color(0xFFFF851B),
    shirt: Color(0xFF5B4A7A),
    vest: Color(0xFFC6E03A),
    pants: Color(0xFF26303D),
    skin: Color(0xFF8E5B3C),
    gloves: true,
  );
  static const operator = LinemanLook(
    helmet: Color(0xFFF5F7FA),
    shirt: Color(0xFF8FB7DD),
    vest: Color(0xFF8FB7DD),
    pants: Color(0xFF34495E),
    skin: Color(0xFFB57A52),
  );
}

/// Sky, far trees and fields, the substation building, the ground, the pole
/// with its line, the ladder and the van. Static: never repaints.
class PtwYardPainter extends CustomPainter {
  const PtwYardPainter(this.geo);
  final PtwYardGeo geo;

  static Paint _fill(Color c) => Paint()..color = c;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final h = s.height;
    final hz = geo.horizon;
    final g = geo.ground;

    // Sky.
    final sky = Rect.fromLTWH(0, 0, w, hz + 4);
    c.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4F8FC9), Color(0xFF94C1E4), Color(0xFFE8E3CC)],
          stops: [0, 0.6, 1],
        ).createShader(sky),
    );
    final sun = Offset(w * 0.12, geo.topSafe + 40);
    c.drawCircle(sun, 110, Paint()..shader = const RadialGradient(colors: [Color(0x80FFF4D2), Color(0x00FFF4D2)]).createShader(Rect.fromCircle(center: sun, radius: 110)));
    c.drawCircle(sun, 15, _fill(const Color(0xFFFFF6DC)));
    final cloud = _fill(const Color(0xD9FFFFFF));
    for (final (x, y, r) in [(70.0, geo.topSafe + 120, 20.0), (230.0, geo.topSafe + 180, 16.0), (330.0, hz * 0.62, 22.0), (40.0, hz * 0.7, 14.0)]) {
      c.drawOval(Rect.fromCenter(center: Offset(x, y), width: r * 4.2, height: r * 1.3), cloud);
      c.drawCircle(Offset(x - r * 0.6, y - r * 0.35), r * 0.8, cloud);
      c.drawCircle(Offset(x + r * 0.5, y - r * 0.5), r, cloud);
    }

    // Far: the tree line, small poles of another line.
    final trees = Path()..moveTo(0, hz);
    for (var x = 0.0; x <= w; x += 14) {
      final bump = 12 + 8 * math.sin(x * 0.05) + 5 * math.sin(x * 0.17 + 1.1);
      trees.quadraticBezierTo(x + 7, hz - bump - 9, x + 14, hz - bump * 0.6);
    }
    trees
      ..lineTo(w, hz + 2)
      ..lineTo(0, hz + 2)
      ..close();
    c.drawPath(trees, _fill(const Color(0xFF6E9466)));
    final farPole = _fill(const Color(0xFF8F918A));
    for (final x in const [20.0, 300.0]) {
      c.drawRect(Rect.fromLTWH(x, hz - 54, 3, 54), farPole);
      c.drawRect(Rect.fromLTWH(x - 9, hz - 50, 21, 2), farPole);
    }

    // The fields between the trees and the site.
    final field = Rect.fromLTWH(0, hz, w, g - hz + 10);
    c.drawRect(
      field,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF9DBA6A), Color(0xFF7FA352)],
        ).createShader(field),
    );
    final rows = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 1;
    for (var i = 1; i < 6; i++) {
      final y = hz + (g - hz) * i / 6;
      c.drawLine(Offset(0, y), Offset(w, y), rows);
    }

    _building(c);

    // The site's ground and the dirt path in front.
    final dirt = Rect.fromLTWH(0, g - 8, w, h - g + 8);
    c.drawRect(
      dirt,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB59B72), Color(0xFF9C8360), Color(0xFF7E6A4E)],
          stops: [0, 0.4, 1],
        ).createShader(dirt),
    );
    final tuft = Paint()
      ..color = const Color(0xFF6E8F48)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (final (x, dy) in const [(14.0, 2.0), (170.0, 30.0), (238.0, 12.0), (320.0, 40.0), (96.0, 120.0), (200.0, 150.0)]) {
      final y = g + dy;
      if (y > h) continue;
      for (final k in const [-4.0, 0.0, 4.0]) {
        c.drawLine(Offset(x, y), Offset(x + k, y - 7), tuft);
      }
    }

    _van(c);
    _lineAndPole(c);
    _ladder(c);
    _callout(c);
  }

  /// The control-room building of the substation, a fence and a transformer.
  void _building(Canvas c) {
    final b = geo.building;
    c.drawRect(b.shift(const Offset(3, 3)), _fill(const Color(0x33000000)));
    c.drawRect(
      b,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE9E1CF), Color(0xFFCFC5AE)],
        ).createShader(b),
    );
    c.drawRect(Rect.fromLTWH(b.left - 4, b.top - 6, b.width + 8, 8), _fill(const Color(0xFF9E9480)));
    // Its window (the one we look into) and a door.
    final win = geo.buildingWindow;
    c.drawRect(win.inflate(2), _fill(const Color(0xFF8A8270)));
    c.drawRect(win, _fill(const Color(0xFF9CC3DD)));
    c.drawLine(win.topCenter, win.bottomCenter, Paint()
      ..color = const Color(0xFF8A8270)
      ..strokeWidth = 2);
    c.drawRect(Rect.fromLTWH(b.left + 78, b.top + 34, 24, b.height - 34), _fill(const Color(0xFF6B5B45)));
    // A gantry the line comes into.
    final gp = Paint()
      ..color = const Color(0xFF7E858C)
      ..strokeWidth = 3;
    final gx = b.left - 18;
    c.drawLine(Offset(gx, b.bottom), Offset(gx, b.top - 34), gp);
    c.drawLine(Offset(gx - 12, b.top - 30), Offset(gx + 14, b.top - 30), gp);
    // Fence in front.
    final fence = Paint()
      ..color = const Color(0xFF9AA0A6)
      ..strokeWidth = 1.2;
    final fy = b.bottom + 4;
    c.drawLine(Offset(b.left - 30, fy - 18), Offset(geo.van.left + 30, fy - 18), fence);
    for (var x = b.left - 30; x < geo.van.left + 30; x += 7) {
      c.drawLine(Offset(x, fy - 22), Offset(x, fy), fence);
    }
  }

  void _van(Canvas c) {
    final v = geo.van;
    final body = Rect.fromLTWH(v.left + 24, v.top, v.width - 24, v.height - 12);
    final cab = Rect.fromLTWH(v.left, v.top + 18, 34, v.height - 30);
    final shadow = _fill(const Color(0x33000000));
    c.drawOval(Rect.fromLTWH(v.left - 4, v.bottom - 8, v.width + 8, 12), shadow);
    final white = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF4F6F7), Color(0xFFD3D8DC)],
      ).createShader(v);
    c.drawRRect(RRect.fromRectAndCorners(cab, topLeft: const Radius.circular(12), bottomLeft: const Radius.circular(4)), white);
    c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(5)), white);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cab.left + 5, cab.top + 5, 22, 16), const Radius.circular(4)), _fill(const Color(0xFF7FA7C2)));
    c.drawRect(Rect.fromLTWH(v.left, body.top + 30, v.width, 7), _fill(const Color(0xFF2F6FD0)));
    // Ladder rack on the roof.
    final rack = Paint()
      ..color = const Color(0xFFA9B1B7)
      ..strokeWidth = 2;
    c.drawLine(Offset(body.left + 6, body.top - 5), Offset(body.right - 4, body.top - 5), rack);
    for (var x = body.left + 10; x < body.right - 6; x += 10) {
      c.drawLine(Offset(x, body.top - 5), Offset(x, body.top), rack);
    }
    for (final x in [v.left + 20, v.right - 26]) {
      c.drawCircle(Offset(x, v.bottom - 10), 11, _fill(const Color(0xFF1E2126)));
      c.drawCircle(Offset(x, v.bottom - 10), 4.5, _fill(const Color(0xFF8D969D)));
    }
  }

  void _lineAndPole(Canvas c) {
    final ins = geo.insulators;
    final wire = Paint()
      ..color = const Color(0xFF2E3338)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    // To the left edge (sagging away) and to the substation's gantry.
    final b = geo.building;
    final gx = b.left - 18;
    for (var i = 0; i < 3; i++) {
      final a = ins[i];
      final left = Path()..moveTo(a.dx, a.dy);
      for (var x = a.dx - 4; x >= 0; x -= 4) {
        left.lineTo(x, geo.wireLeftY(i, x));
      }
      c.drawPath(left, wire);
      final end = Offset(gx - 10 + i * 10, b.top - 30);
      final mid = Offset((a.dx + end.dx) / 2, (a.dy + end.dy) / 2 + 22);
      c.drawPath(Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, end.dx, end.dy), wire);
    }

    // The PCC pole: tapered, grey, a little shade on the right.
    const x = PtwYardGeo.poleX;
    final top = geo.poleTop;
    final g = geo.ground;
    final pole = Path()
      ..moveTo(x - 5, top)
      ..lineTo(x + 5, top)
      ..lineTo(x + 9, g + 6)
      ..lineTo(x - 9, g + 6)
      ..close();
    c.drawPath(
      pole,
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFFCFCBC2), Color(0xFFA9A49A), Color(0xFF8E8A82)], stops: [0, 0.6, 1])
            .createShader(Rect.fromLTRB(x - 9, top, x + 9, g)),
    );
    c.drawOval(Rect.fromCenter(center: Offset(x, g + 6), width: 30, height: 7), _fill(const Color(0x44000000)));
    // Cross-arm (steel channel) and its clamp.
    final arm = Rect.fromLTRB(x - 52, geo.armY - 3, x + 52, geo.armY + 4);
    c.drawRect(arm, _fill(const Color(0xFF5E666E)));
    c.drawRect(Rect.fromLTWH(x - 7, geo.armY - 6, 14, 13), _fill(const Color(0xFF474E55)));
    // Insulators: porcelain discs on pins.
    for (final a in ins) {
      final base = a.dy + 13;
      c.drawRect(Rect.fromLTWH(a.dx - 1.5, base - 4, 3, 6), _fill(const Color(0xFF474E55)));
      for (var k = 0; k < 3; k++) {
        c.drawOval(Rect.fromCenter(center: Offset(a.dx, base - 5 - k * 3.5), width: 13 - k * 2.0, height: 4), _fill(k.isEven ? const Color(0xFFF2EEE6) : const Color(0xFFC9C1B3)));
      }
    }
  }

  void _ladder(Canvas c) {
    final f = geo.ladderFoot;
    final t = geo.ladderTop;
    final rail = Paint()
      ..color = const Color(0xFFB7BEC4)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final rung = Paint()
      ..color = const Color(0xFF9AA2A9)
      ..strokeWidth = 2;
    const spread = 8.0;
    final a1 = f.translate(-spread, 0), a2 = f.translate(spread, 0);
    final b1 = t.translate(-spread * 0.8, 0), b2 = t.translate(spread * 0.8, 0);
    c.drawLine(a1, b1, rail);
    c.drawLine(a2, b2, rail);
    final n = ((f.dy - t.dy) / 16).floor();
    for (var i = 1; i < n; i++) {
      final k = i / n;
      c.drawLine(Offset.lerp(a1, b1, k)!, Offset.lerp(a2, b2, k)!, rung);
    }
  }

  /// Two faint lines tie the control-room window to the building's window.
  void _callout(Canvas c) {
    final i = geo.inset;
    final win = geo.buildingWindow;
    final p = Paint()
      ..color = const Color(0x66FFFFFF)
      ..strokeWidth = 1.4;
    c.drawLine(Offset(i.left + 40, i.bottom), win.topLeft, p);
    c.drawLine(Offset(i.right - 40, i.bottom), win.topRight, p);
  }

  @override
  bool shouldRepaint(PtwYardPainter old) => old.geo != geo;
}

/// The folding table in front (it hides the supervisor's legs).
class PtwTablePainter extends CustomPainter {
  const PtwTablePainter(this.geo);
  final PtwYardGeo geo;

  @override
  void paint(Canvas c, Size s) {
    final t = geo.table;
    final leg = Paint()
      ..color = const Color(0xFF5B4A38)
      ..strokeWidth = 4;
    c.drawLine(Offset(t.left + 14, t.bottom), Offset(t.left + 6, t.bottom + 54), leg);
    c.drawLine(Offset(t.right - 14, t.bottom), Offset(t.right - 6, t.bottom + 54), leg);
    c.drawOval(Rect.fromLTWH(t.left - 4, t.bottom + 48, t.width + 8, 10), Paint()..color = const Color(0x33000000));
    // The foreground of the site: the work-zone cones and a cable drum.
    for (final (x, y, k) in [(184.0, t.bottom + 46, 1.0), (22.0, t.bottom + 112, 1.25)]) {
      if (y - 40 * k > s.height) continue;
      _cone(c, Offset(x, y), k);
    }
    _drum(c, Offset(112, t.bottom + 104));
    c.drawRRect(
      RRect.fromRectAndRadius(t, const Radius.circular(3)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB98B54), Color(0xFF8C6A3E)],
        ).createShader(t),
    );
  }

  static void _cone(Canvas c, Offset base, double k) {
    c.drawOval(Rect.fromCenter(center: base.translate(2, 1), width: 30 * k, height: 7 * k), Paint()..color = const Color(0x33000000));
    c.drawRect(Rect.fromCenter(center: base.translate(0, -2 * k), width: 26 * k, height: 4 * k), Paint()..color = const Color(0xFFD9541E));
    final body = Path()
      ..moveTo(base.dx - 10 * k, base.dy - 4 * k)
      ..lineTo(base.dx - 2.5 * k, base.dy - 38 * k)
      ..lineTo(base.dx + 2.5 * k, base.dy - 38 * k)
      ..lineTo(base.dx + 10 * k, base.dy - 4 * k)
      ..close();
    c.drawPath(body, Paint()..color = const Color(0xFFFF7A2E));
    c.save();
    c.clipPath(body);
    c.drawRect(Rect.fromLTRB(base.dx - 12 * k, base.dy - 24 * k, base.dx + 12 * k, base.dy - 17 * k), Paint()..color = const Color(0xFFF5F7FA));
    c.drawRect(Rect.fromLTRB(base.dx + 3 * k, base.dy - 40 * k, base.dx + 12 * k, base.dy), Paint()..color = const Color(0x22000000));
    c.restore();
  }

  /// A wooden cable drum lying on its side, a little cable on it.
  static void _drum(Canvas c, Offset ctr) {
    c.drawOval(Rect.fromCenter(center: ctr.translate(4, 22), width: 70, height: 10), Paint()..color = const Color(0x33000000));
    c.drawRect(Rect.fromCenter(center: ctr, width: 46, height: 30), Paint()..color = const Color(0xFF2E3338));
    for (var i = 0; i < 5; i++) {
      final y = ctr.dy - 12 + i * 6;
      c.drawLine(Offset(ctr.dx - 22, y), Offset(ctr.dx + 22, y), Paint()
        ..color = const Color(0xFF474E55)
        ..strokeWidth = 1);
    }
    for (final dx in const [-26.0, 26.0]) {
      final r = Rect.fromCenter(center: ctr.translate(dx, 0), width: 12, height: 46);
      c.drawOval(r, Paint()..color = const Color(0xFFB98B54));
      c.drawOval(r.deflate(3), Paint()..color = const Color(0xFF9C7448));
    }
    c.drawCircle(ctr.translate(26, 0), 3, Paint()..color = const Color(0xFF5B4A38));
  }

  @override
  bool shouldRepaint(PtwTablePainter old) => old.geo != geo;
}

/// Inside the control room (the operator's side): wall, the breaker panel
/// with its lever ([off] 0 → 1 = ON → OFF), the lock and tag ([lock] 0 → 1
/// drops them in), the desk with the permit book ([open]).
class PtwRoomPainter extends CustomPainter {
  const PtwRoomPainter({required this.off, required this.lock, required this.open, required this.cancelled});
  final double off;
  final double lock;
  final bool open;
  final bool cancelled;

  @override
  void paint(Canvas c, Size s) {
    final r = Offset.zero & s;
    final frame = RRect.fromRectAndRadius(r, const Radius.circular(14));
    c.drawRRect(frame.shift(const Offset(0, 4)), Paint()..color = const Color(0x55000000));
    c.drawRRect(frame, Paint()..color = const Color(0xFFE6E9EC));
    final inner = RRect.fromRectAndRadius(r.deflate(6), const Radius.circular(9));
    c.save();
    c.clipRRect(inner);
    final room = r.deflate(6);
    c.drawRect(
      room,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF3EBD8), Color(0xFFE2D7BE)],
        ).createShader(room),
    );
    // The sign band at the top (its words go on as a widget).
    c.drawRect(Rect.fromLTWH(room.left, room.top, room.width, 16), Paint()..color = const Color(0xFF2F6FD0));
    // Floor.
    c.drawRect(Rect.fromLTWH(room.left, room.bottom - 14, room.width, 14), Paint()..color = const Color(0xFFB9AE96));

    // The breaker panel.
    final p = PtwYardGeo.breakerLocal;
    c.drawRRect(RRect.fromRectAndRadius(p.shift(const Offset(2, 2)), const Radius.circular(4)), Paint()..color = const Color(0x44000000));
    c.drawRRect(
      RRect.fromRectAndRadius(p, const Radius.circular(4)),
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFF8F9AA4), Color(0xFF6E7A85)]).createShader(p),
    );
    // The indicator window (ON / OFF words go on as a widget) and two lamps.
    final lampY = p.top + 40;
    final onLamp = Color.lerp(const Color(0xFFE03A2E), const Color(0xFF5A2A26), off)!;
    final offLamp = Color.lerp(const Color(0xFF26432E), const Color(0xFF3CCB5E), off)!;
    c.drawCircle(Offset(p.left + 18, lampY), 5, Paint()..color = onLamp);
    c.drawCircle(Offset(p.right - 18, lampY), 5, Paint()..color = offLamp);
    // The lever: up for ON, down for OFF.
    final pivot = Offset(p.center.dx, p.top + 66);
    c.drawCircle(pivot, 8, Paint()..color = const Color(0xFF3A4148));
    final tip = pivot + Offset(0, -20 + 40 * off);
    c.drawLine(pivot, tip, Paint()
      ..color = const Color(0xFF1E2329)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round);
    c.drawCircle(tip, 5, Paint()..color = const Color(0xFFC0392B));
    // Lock and tag (drop in from above).
    if (lock > 0) {
      final drop = (1 - lock) * -18;
      final lockC = Offset(pivot.dx + 13, pivot.dy + 12 + drop);
      c.drawArc(Rect.fromCenter(center: lockC.translate(0, -5), width: 10, height: 12), math.pi, math.pi, false, Paint()
        ..color = const Color(0xFFB7BEC4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: lockC.translate(0, 2), width: 13, height: 11), const Radius.circular(2)), Paint()..color = const Color(0xFFE03A2E));
      final tag = Rect.fromLTWH(lockC.dx - 9, lockC.dy + 9, 18, 22);
      c.drawLine(lockC.translate(0, 6), tag.topCenter, Paint()
        ..color = const Color(0xFF333333)
        ..strokeWidth = 1);
      c.drawRRect(RRect.fromRectAndRadius(tag, const Radius.circular(2)), Paint()..color = const Color(0xFFD23A2C));
      c.drawRect(Rect.fromLTWH(tag.left + 3, tag.top + 3, tag.width - 6, 5), Paint()..color = const Color(0xFFF5F7FA));
      c.drawRect(Rect.fromLTWH(tag.center.dx - 1.2, tag.top + 10, 2.4, 6), Paint()..color = const Color(0xFFF5F7FA));
      c.drawCircle(Offset(tag.center.dx, tag.top + 18.5), 1.3, Paint()..color = const Color(0xFFF5F7FA));
    }

    // The desk and the permit book.
    final b = PtwYardGeo.bookLocal;
    c.drawRect(Rect.fromLTWH(b.left - 6, b.bottom - 2, b.width + 14, 6), Paint()..color = const Color(0xFF8C6A3E));
    c.drawRect(Rect.fromLTWH(b.left - 2, b.bottom + 4, 4, room.bottom - b.bottom - 4), Paint()..color = const Color(0xFF6E5332));
    c.drawRect(Rect.fromLTWH(b.right + 2, b.bottom + 4, 4, room.bottom - b.bottom - 4), Paint()..color = const Color(0xFF6E5332));
    if (open) {
      final page = Rect.fromLTWH(b.left, b.top + 6, b.width, b.height - 8);
      c.drawRect(page.shift(const Offset(1, 2)), Paint()..color = const Color(0x33000000));
      c.drawRect(page, Paint()..color = const Color(0xFFFFFDF6));
      c.drawLine(page.topCenter, page.bottomCenter, Paint()
        ..color = const Color(0xFFCFC6B4)
        ..strokeWidth = 1);
    } else {
      final cover = Rect.fromLTWH(b.left + 10, b.top + 10, b.width - 20, b.height - 12);
      c.drawRRect(RRect.fromRectAndRadius(cover.shift(const Offset(1, 2)), const Radius.circular(2)), Paint()..color = const Color(0x33000000));
      c.drawRRect(RRect.fromRectAndRadius(cover, const Radius.circular(2)), Paint()..color = const Color(0xFF1F5F8F));
    }
    c.restore();
    c.drawRRect(inner, Paint()
      ..color = const Color(0xFFB0B7BD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(PtwRoomPainter old) => old.off != off || old.lock != lock || old.open != open || old.cancelled != cancelled;
}

/// The discharge rod (lying on the tarp at 0, hooked on the line at 1, with
/// its earth lead) and the tester on its head ([tested]: once on the line,
/// its lamp shows dead).
class PtwRodPainter extends CustomPainter {
  const PtwRodPainter({required this.geo, required this.t, required this.tested});
  final PtwYardGeo geo;
  final double t;
  final bool tested;

  @override
  void paint(Canvas c, Size s) {
    final tarp = geo.tarp;
    c.drawRRect(RRect.fromRectAndRadius(tarp, const Radius.circular(3)), Paint()..color = const Color(0xFF2F6FD0));
    c.drawRect(Rect.fromLTWH(tarp.left, tarp.top, tarp.width, 3), Paint()..color = const Color(0xFF4F8AE0));
    // Earth spike and the lead.
    final e = geo.earth;
    c.drawLine(e, e.translate(0, 10), Paint()
      ..color = const Color(0xFF8D969D)
      ..strokeWidth = 3);
    c.drawRect(Rect.fromCenter(center: e, width: 10, height: 4), Paint()..color = const Color(0xFFB87333));
    final (b, top) = geo.rodEnds(t);
    final lead = Path()
      ..moveTo(e.dx, e.dy)
      ..quadraticBezierTo((e.dx + top.dx) / 2 - 14, math.max(e.dy, top.dy) + 10 - (e.dy - top.dy).abs() * 0.4, top.dx, top.dy + 6);
    c.drawPath(lead, Paint()
      ..color = const Color(0xFF2E9E4A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6);
    // The rod: insulated stick, red bands, metal head and hook.
    final dir = top - b;
    final len = dir.distance;
    final u = dir / len;
    c.drawLine(b, top, Paint()
      ..color = const Color(0xFFF2B632)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round);
    for (final k in const [0.18, 0.5]) {
      final p = b + u * (len * k);
      c.drawLine(p, p + u * 6, Paint()
        ..color = const Color(0xFFC0392B)
        ..strokeWidth = 4.6);
    }
    final head = top - u * 8;
    c.drawLine(head, top, Paint()
      ..color = const Color(0xFF8D969D)
      ..strokeWidth = 3);
    // The tester rides on the rod's head, so it goes to the line with it; its
    // lamp shows dead only once it is there.
    final tc = top - u * 20;
    c.save();
    c.translate(tc.dx, tc.dy);
    c.rotate(math.atan2(u.dy, u.dx));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-13, -6.5, 26, 9), const Radius.circular(3)), Paint()..color = const Color(0xFFFF851B));
    c.drawCircle(const Offset(8, -2), 3, Paint()..color = tested && t > 0.9 ? const Color(0xFF3CCB5E) : const Color(0xFF59636C));
    c.restore();
    final n = Offset(-u.dy, u.dx);
    c.drawPath(
      Path()
        ..moveTo(top.dx, top.dy)
        ..quadraticBezierTo(top.dx + u.dx * 6 + n.dx * 5, top.dy + u.dy * 6 + n.dy * 5, top.dx + n.dx * 7, top.dy + n.dy * 7),
      Paint()
        ..color = const Color(0xFF8D969D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4,
    );
  }

  @override
  bool shouldRepaint(PtwRodPainter old) => old.t != t || old.tested != tested || old.geo != geo;
}

/// The supervisor's mobile phone on the table; [lit]: on a call.
class PtwPhonePainter extends CustomPainter {
  const PtwPhonePainter({required this.lit});
  final bool lit;

  @override
  void paint(Canvas c, Size s) {
    final r = Offset.zero & s;
    c.drawRRect(RRect.fromRectAndRadius(r.shift(const Offset(1.5, 2)), const Radius.circular(5)), Paint()..color = const Color(0x44000000));
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(5)), Paint()..color = const Color(0xFF22272D));
    final screen = Rect.fromLTWH(3, 4, s.width - 6, s.height - 10);
    c.drawRRect(RRect.fromRectAndRadius(screen, const Radius.circular(2)), Paint()..color = lit ? const Color(0xFF8FE3A2) : const Color(0xFF3B4A5A));
    if (lit) {
      final hand = Paint()
        ..color = const Color(0xFF1E6B34)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      final m = screen.center;
      c.drawLine(m.translate(-5, 2), m.translate(5, -4), hand);
    }
    c.drawCircle(Offset(s.width / 2, s.height - 3), 1.5, Paint()..color = const Color(0xFF59636C));
  }

  @override
  bool shouldRepaint(PtwPhonePainter old) => old.lit != lit;
}

/// The clipboard on the table (the permit's words go on as widgets); [paper]: a permit on it.
class PtwClipboardPainter extends CustomPainter {
  const PtwClipboardPainter({required this.paper});
  final bool paper;

  @override
  void paint(Canvas c, Size s) {
    final r = Offset.zero & s;
    c.drawRRect(RRect.fromRectAndRadius(r.shift(const Offset(2, 2)), const Radius.circular(4)), Paint()..color = const Color(0x44000000));
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)), Paint()..color = const Color(0xFF9C7A4C));
    if (paper) {
      final sheet = Rect.fromLTWH(4, 7, s.width - 8, s.height - 10);
      c.drawRect(sheet, Paint()..color = const Color(0xFFFFFDF6));
      // A signature at the foot of the permit.
      c.drawPath(
        Path()
          ..moveTo(sheet.left + 6, sheet.bottom - 6)
          ..cubicTo(sheet.left + 12, sheet.bottom - 14, sheet.left + 16, sheet.bottom - 1, sheet.left + 22, sheet.bottom - 8)
          ..cubicTo(sheet.left + 26, sheet.bottom - 12, sheet.left + 30, sheet.bottom - 4, sheet.left + 36, sheet.bottom - 7),
        Paint()
          ..color = const Color(0xFF2F6FD0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(s.width / 2 - 9, -2, 18, 7), const Radius.circular(2)), Paint()..color = const Color(0xFF8D969D));
  }

  @override
  bool shouldRepaint(PtwClipboardPainter old) => old.paper != paper;
}

/// The deadly moment, in colour over the grey site: the line is alive — an
/// arc jumps from the conductor to the top worker's hand, a white flash.
/// Never graphic: light only.
class PtwArcPainter extends CustomPainter {
  const PtwArcPainter({required this.from, required this.to, required this.t});
  final Offset from;
  final Offset to;

  /// 0 → 1 over the freeze (the flash fades, the arc flickers).
  final double t;

  @override
  void paint(Canvas c, Size s) {
    final glow = (1 - t * 0.6).clamp(0.4, 1.0);
    final mid = Offset.lerp(from, to, 0.5)!;
    c.drawCircle(mid, 110, Paint()..shader = RadialGradient(colors: [Color.fromRGBO(255, 244, 190, 0.9 * glow), const Color(0x00FFF4BE)]).createShader(Rect.fromCircle(center: mid, radius: 110)));
    c.drawCircle(to, 26 + 30 * t, Paint()
      ..color = Color.fromRGBO(255, 220, 90, 0.8 * (1 - t))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
    final rnd = math.Random((t * 12).floor());
    for (var k = 0; k < 2; k++) {
      final p = Path()..moveTo(from.dx, from.dy);
      const n = 7;
      for (var i = 1; i < n; i++) {
        final q = Offset.lerp(from, to, i / n)!;
        p.lineTo(q.dx + (rnd.nextDouble() - 0.5) * 16, q.dy + (rnd.nextDouble() - 0.5) * 10);
      }
      p.lineTo(to.dx, to.dy);
      c.drawPath(p, Paint()
        ..color = const Color(0xFFFFE066)
        ..style = PaintingStyle.stroke
        ..strokeWidth = k == 0 ? 7 : 2.6
        ..maskFilter = k == 0 ? const MaskFilter.blur(BlurStyle.normal, 3) : null);
    }
    c.drawCircle(to, 9 * glow + 3, Paint()..color = const Color(0xFFFFFBE0));
  }

  @override
  bool shouldRepaint(PtwArcPainter old) => old.t != t || old.from != from || old.to != to;
}
