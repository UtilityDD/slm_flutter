import 'dart:math' as math;

import 'package:flutter/material.dart';

// The drawn world of lesson 5.6 কাজ 2 "ছেঁড়া তার, তবু লাইভ"
// (m5_live_wire_guard.dart): a village lane after a storm, overcast day. A
// 415 V LT span has snapped: end A hangs low from pole A; end B (from the next
// pole at the far end) rests on the GI fence along one side, on the tin shed's
// roof on the other side, or on the bare road (dealt). A bicycle leans on the
// fence or the shed (touching it, or standing on its stand with a gap); a GI
// clothesline is tied to the fence or the shed (or to a bamboo post a little
// short of it). The crew's rope ring is already up round the fallen wire. A
// tree, a wooden bench and a plastic drum stand about. The trainee waits
// outside the ring at the bottom of the lane; people walk in from the edges.
//
// No highlight on anything live and no text in the art: contact or gap is
// drawn plainly, the same way whether it matters or not.
//
// Design: 360 wide × the scene's height; the lane follows the screen (a tall
// phone gets a longer lane, never stretched). [M5WireGeo] holds every place;
// the play logic (m5_live_wire_guard.dart) walks people between them.

/// Where the snapped wire's far end (end B) rests.
enum M5WireRest { fence, shed, road }

/// What a chain object (the bicycle, the clothesline) touches — or nearly.
enum M5Host { fence, shed }

/// The things in the lane a person may walk to.
enum M5Thing { endA, wireB, fenceNear, fenceFar, shedNear, shedFar, bicycle, clothesline, tree, bench, drum }

/// What the deal sets in the lane (drawing and live-ness).
@immutable
class M5WireLayout {
  const M5WireLayout({
    required this.rest,
    required this.mirror,
    required this.bikeHost,
    required this.bikeTouch,
    required this.lineHost,
    required this.lineTied,
  });

  final M5WireRest rest;

  /// The fence on the right and the shed on the left.
  final bool mirror;

  /// The bicycle leans on [bikeHost] (touching it) or stands a little apart.
  final M5Host bikeHost;
  final bool bikeTouch;

  /// The GI clothesline runs from [lineHost] (tied to it) or from a bamboo
  /// post a little short of it.
  final M5Host lineHost;
  final bool lineTied;

  bool get fenceLive => rest == M5WireRest.fence;
  bool get shedLive => rest == M5WireRest.shed;
  bool _hostLive(M5Host h) => h == M5Host.fence ? fenceLive : shedLive;
  bool get bikeLive => bikeTouch && _hostLive(bikeHost);
  bool get lineLive => lineTied && _hostLive(lineHost);

  /// Treated as live: the wire, and every conductor touching it (or touching
  /// such a conductor) — lesson 5.6 pro tip 1.
  bool live(M5Thing t) => switch (t) {
        M5Thing.endA || M5Thing.wireB => true,
        M5Thing.fenceNear || M5Thing.fenceFar => fenceLive,
        M5Thing.shedNear || M5Thing.shedFar => shedLive,
        M5Thing.bicycle => bikeLive,
        M5Thing.clothesline => lineLive,
        M5Thing.tree || M5Thing.bench || M5Thing.drum => false,
      };

  /// Inside the rope ring (the rest are outside it).
  bool inRing(M5Thing t) => switch (t) {
        M5Thing.endA || M5Thing.wireB => true,
        M5Thing.fenceNear => fenceLive,
        M5Thing.shedNear => shedLive,
        _ => false,
      };

  @override
  bool operator ==(Object other) =>
      other is M5WireLayout &&
      other.rest == rest &&
      other.mirror == mirror &&
      other.bikeHost == bikeHost &&
      other.bikeTouch == bikeTouch &&
      other.lineHost == lineHost &&
      other.lineTied == lineTied;

  @override
  int get hashCode => Object.hash(rest, mirror, bikeHost, bikeTouch, lineHost, lineTied);
}

/// Where things are (design px, 360 wide).
@immutable
class M5WireGeo {
  const M5WireGeo._(this.height, this.top, this.bottom, this.layout);

  factory M5WireGeo.forScene(double height, double inset, M5WireLayout layout) {
    final bottom = height - floorUp - inset * 0.5;
    return M5WireGeo._(height, math.max(150.0, height * 0.26), bottom, layout);
  }

  final double height;

  /// The lane's far end (people come in here) and its near end (the
  /// trainee's feet).
  final double top;
  final double bottom;
  final M5WireLayout layout;

  /// The lane's near end sits this far above the bottom of the screen.
  static const double floorUp = 96;

  /// A late stop: the walker is this close to his target (or under the rope).
  static const double reach = 30;

  double get laneH => bottom - top;
  double y(double f) => top + f * laneH;
  double x(double v) => layout.mirror ? 360 - v : v;
  Offset p(double vx, double f) => Offset(x(vx), y(f));

  /// Perspective: far things are smaller.
  double scaleAt(double py) => 0.74 + 0.26 * ((py - top) / laneH).clamp(0.0, 1.2);

  // --- the lane ------------------------------------------------------------
  double get fenceX => x(34);
  double get fenceTop => y(-0.04);
  double get fenceBottom => y(0.90);
  Rect get shed => Rect.fromPoints(p(258, 0.16), p(352, 0.56));
  Offset get poleA => p(150, 0.14);
  Offset get poleB => p(306, -0.03);
  double get armLift => math.min(150.0, top - 40);
  Offset get armA => Offset(poleA.dx, poleA.dy - armLift);
  Offset get armB => Offset(poleB.dx, poleB.dy - armLift * 0.8);

  // --- the snapped span ----------------------------------------------------
  /// End A: hanging low from pole A's cross-arm.
  Offset get endA => p(172, 0.30);
  Offset get hangA => Offset(x(176), armA.dy + 6);

  /// Where piece B first touches something (the roof edge, the road).
  Offset? get touchB => switch (layout.rest) {
        M5WireRest.fence => p(120, 0.40),
        M5WireRest.shed => p(266, 0.20),
        M5WireRest.road => p(176, 0.36),
      };

  /// End B, on the ground (or draped on the fence).
  Offset get endB => switch (layout.rest) {
        M5WireRest.fence => p(38, 0.42),
        M5WireRest.shed => p(240, 0.32),
        M5WireRest.road => p(130, 0.46),
      };

  /// The crew's rope ring round the fallen wire.
  Rect get ring {
    final pts = [endA, endB, ?touchB];
    final xs = pts.map((o) => o.dx);
    final ys = pts.map((o) => o.dy);
    return Rect.fromLTRB(
      math.max(6, xs.reduce(math.min) - 28),
      ys.reduce(math.min) - 22,
      math.min(354, xs.reduce(math.max) + 28),
      ys.reduce(math.max) + 24,
    );
  }

  // --- the things ----------------------------------------------------------
  /// The bicycle's spot (by its host).
  Offset get bike => layout.bikeHost == M5Host.fence ? p(56, 0.74) : p(244, 0.48);

  /// The clothesline: from its tie point to its bamboo post.
  Offset get lineFrom => layout.lineHost == M5Host.fence
      ? p(layout.lineTied ? 34 : 50, 0.58)
      : p(layout.lineTied ? 258 : 242, 0.50);
  Offset get lineTo => layout.lineHost == M5Host.fence ? p(128, 0.61) : p(190, 0.55);

  Offset get treeAt => p(108, 0.80);
  Offset get benchAt => p(330, 0.80);
  Offset get drumAt => p(158, 0.70);

  /// Where a person stands to touch [t] (their feet).
  Offset target(M5Thing t) => switch (t) {
        M5Thing.endA => endA + Offset(layout.mirror ? 6 : -6, 6),
        M5Thing.wireB => layout.rest == M5WireRest.shed
            ? endB + Offset(layout.mirror ? 8 : -8, 6)
            : Offset.lerp(endB, touchB, 0.5)! + const Offset(0, 6),
        M5Thing.fenceNear => p(46, layout.fenceLive ? 0.43 : 0.40),
        M5Thing.fenceFar => p(46, 0.84),
        M5Thing.shedNear => p(250, layout.shedLive ? 0.25 : 0.28),
        M5Thing.shedFar => p(300, 0.59),
        M5Thing.bicycle => bike + Offset((layout.bikeHost == M5Host.fence) != layout.mirror ? 12 : -12, 4),
        M5Thing.clothesline => Offset.lerp(lineFrom, lineTo, 0.45)! + const Offset(0, 6),
        M5Thing.tree => treeAt + Offset(layout.mirror ? -14 : 14, 4),
        M5Thing.bench => benchAt + Offset(layout.mirror ? 22 : -22, 2),
        M5Thing.drum => drumAt + Offset(layout.mirror ? -14 : 14, 4),
      };

  /// Where people come in from (the lane's far end, its sides, its near end).
  List<Offset> get spawns => [
        p(70, -0.04),
        p(120, -0.04),
        p(236, -0.04),
        p(362, 0.66),
        p(362, 0.10),
        Offset(x(16), bottom + 30),
        Offset(x(190), bottom + 34),
      ];

  /// The trainee (outside the ring at the near end) and his hand (a swipe
  /// starts here).
  Rect get trainee => Rect.fromLTWH(x(262) - 24, bottom - 96, 48, 96);
  Offset get traineeHand => Offset(x(262), bottom - 52);

  /// The one-time demo's grey figure (not a target, outside the ring).
  Offset get demoAt => p(196, 0.64);

  /// True if a walk from [a] to [b] stays clear of the ring (unless [intoRing])
  /// and never goes through the shed or across the fence.
  bool clearPath(Offset a, Offset b, {required bool intoRing}) {
    final ring = this.ring.inflate(6);
    final shed = this.shed.deflate(6);
    final n = math.max(8, ((b - a).distance / 4).ceil());
    for (var i = 1; i < n; i++) {
      final q = Offset.lerp(a, b, i / n)!;
      if (!intoRing && ring.contains(q)) return false;
      if (shed.contains(q)) return false;
    }
    // The fence: both ends on the lane side unless past its end.
    final side = layout.mirror ? -1 : 1;
    double s(Offset o) => (o.dx - fenceX) * side;
    if (s(a) < 0 && s(b) > 0 || s(a) > 0 && s(b) < 0) {
      final t = (fenceX - a.dx) / (b.dx - a.dx);
      final yy = a.dy + (b.dy - a.dy) * t;
      if (yy >= fenceTop && yy <= fenceBottom) return false;
    }
    return true;
  }

  @override
  bool operator ==(Object other) =>
      other is M5WireGeo && other.height == height && other.top == top && other.bottom == bottom && other.layout == layout;

  @override
  int get hashCode => Object.hash(height, top, bottom, layout);
}

/// One person in the lane, as drawn now.
@immutable
class M5WalkerView {
  const M5WalkerView({
    required this.at,
    required this.facingLeft,
    required this.phase,
    required this.opacity,
    required this.tint,
    this.reachTo,
    this.stopped = false,
    this.grey = false,
  });

  final Offset at;
  final bool facingLeft;

  /// The stride (0..1, loops while walking; null = standing).
  final double? phase;
  final double opacity;
  final int tint;

  /// Reaching out toward this point.
  final Offset? reachTo;

  /// Stopped by the trainee: a raised palm over him.
  final bool stopped;

  /// The demo's grey figure.
  final bool grey;
}

// ============================================================================
// Painters
// ============================================================================

const _ink = Color(0xFF1E2329);
const _gi = Color(0xFF9AA4AC);
const _giDark = Color(0xFF6E7880);
const _wire = Color(0xFF2B2F33);

/// The lane: sky, houses, the road, the fence, the shed, the poles, the
/// snapped span, the rope ring and the things (static per play).
class M5WireLanePainter extends CustomPainter {
  const M5WireLanePainter({required this.geo, required this.seed});
  final M5WireGeo geo;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final g = geo;
    final l = g.layout;
    _sky(canvas, size);
    _ground(canvas, size);
    // Far to near.
    _pole(canvas, g.poleB, g.armB, 0.8);
    _pole(canvas, g.poleA, g.armA, 1);
    _shed(canvas);
    _fence(canvas);
    _ring(canvas, back: true);
    _tree(canvas, g.treeAt);
    _drum(canvas, g.drumAt);
    _bench(canvas, g.benchAt);
    _clothesline(canvas);
    _bike(canvas);
    _wires(canvas, l.rest);
    _ring(canvas, back: false);
  }

  void _sky(Canvas c, Size size) {
    final sky = Rect.fromLTWH(0, 0, size.width, geo.top + 10);
    c.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5E6B78), Color(0xFF8C98A3), Color(0xFFB7BFC6)],
        ).createShader(sky),
    );
    final cloud = Paint()..color = const Color(0x55444E59);
    final r = math.Random(seed);
    for (var i = 0; i < 6; i++) {
      final cx = r.nextDouble() * 360;
      final cy = 30 + r.nextDouble() * (geo.top * 0.5);
      c.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 120 + r.nextDouble() * 80, height: 26 + r.nextDouble() * 14), cloud);
    }
    // Far houses and trees on the horizon.
    final hz = geo.top - 6;
    final house = Paint()..color = const Color(0xFF5B5F63);
    final roof = Paint()..color = const Color(0xFF474B50);
    for (var i = 0; i < 7; i++) {
      final x0 = -10.0 + i * 56 + r.nextDouble() * 12;
      final w = 40 + r.nextDouble() * 14;
      final h = 18 + r.nextDouble() * 12;
      c.drawRect(Rect.fromLTWH(x0, hz - h, w, h), house);
      c.drawPath(
        Path()
          ..moveTo(x0 - 4, hz - h)
          ..lineTo(x0 + w / 2, hz - h - 10)
          ..lineTo(x0 + w + 4, hz - h)
          ..close(),
        roof,
      );
    }
    final leaf = Paint()..color = const Color(0xFF3F5546);
    for (var i = 0; i < 5; i++) {
      final cx = 30 + i * 80 + r.nextDouble() * 20;
      c.drawCircle(Offset(cx, hz - 26), 16 + r.nextDouble() * 6, leaf);
    }
  }

  void _ground(Canvas c, Size size) {
    final g = geo;
    final land = Rect.fromLTWH(0, g.top - 8, size.width, size.height - g.top + 8);
    c.drawRect(
      land,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6E6656), Color(0xFF5A5246), Color(0xFF4A4339)],
        ).createShader(land),
    );
    // The road (darker, packed) between the verges.
    final road = Path()
      ..moveTo(g.x(96), g.top - 8)
      ..lineTo(g.x(250), g.top - 8)
      ..lineTo(g.x(330), size.height)
      ..lineTo(g.x(60), size.height)
      ..close();
    c.drawPath(road, Paint()..color = const Color(0x334A4640));
    // Puddles and storm litter.
    final r = math.Random(seed + 7);
    final puddle = Paint()..color = const Color(0x667F8C96);
    for (var i = 0; i < 5; i++) {
      final o = Offset(70 + r.nextDouble() * 220, g.y(0.2 + r.nextDouble() * 0.75));
      if (g.ring.inflate(10).contains(o)) continue;
      c.drawOval(Rect.fromCenter(center: o, width: 26 + r.nextDouble() * 22, height: 7 + r.nextDouble() * 4), puddle);
    }
    final twig = Paint()
      ..color = const Color(0xFF3E3428)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final leaf = Paint()..color = const Color(0xFF4F6A3E);
    for (var i = 0; i < 14; i++) {
      final o = Offset(20 + r.nextDouble() * 320, g.y(r.nextDouble() * 0.98));
      if (r.nextBool()) {
        c.drawLine(o, o + Offset(8 + r.nextDouble() * 8, -2 + r.nextDouble() * 4), twig);
      } else {
        c.drawOval(Rect.fromCenter(center: o, width: 6, height: 3), leaf);
      }
    }
  }

  void _pole(Canvas c, Offset base, Offset arm, double k) {
    final w = 7.0 * k;
    final body = Rect.fromLTRB(base.dx - w / 2, arm.dy - 14 * k, base.dx + w / 2, base.dy);
    c.drawRect(
      body,
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFF8F949A), Color(0xFFC7CCD1), Color(0xFF7D838A)]).createShader(body),
    );
    c.drawOval(Rect.fromCenter(center: base, width: 16 * k, height: 4 * k), Paint()..color = const Color(0x55000000));
    // The LT cross-arm and its four insulators.
    final armR = Rect.fromCenter(center: arm, width: 64 * k, height: 5 * k);
    c.drawRect(armR, Paint()..color = const Color(0xFF6A5A48));
    for (final dx in [-26.0, -9.0, 9.0, 26.0]) {
      final o = arm + Offset(dx * k, -5 * k);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: 5 * k, height: 8 * k), const Radius.circular(2)),
          Paint()..color = const Color(0xFFE6E2D6));
    }
  }

  void _fence(Canvas c) {
    final g = geo;
    final x = g.fenceX;
    final post = Paint()
      ..color = _giDark
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final wire = Paint()
      ..color = _gi
      ..strokeWidth = 1.3;
    final mesh = Paint()
      ..color = const Color(0x889AA4AC)
      ..strokeWidth = 0.8;
    final dir = g.layout.mirror ? -1.0 : 1.0;
    final hTop = 30 * g.scaleAt(g.fenceTop);
    final hBot = 30 * g.scaleAt(g.fenceBottom);
    // Seen from the lane: its height leans out toward the screen's edge, so
    // the panels show as a side wall of posts and mesh.
    Offset at(double yy, double up) {
      final t = ((yy - g.fenceTop) / (g.fenceBottom - g.fenceTop)).clamp(0.0, 1.0);
      final h = hTop + (hBot - hTop) * t;
      return Offset(x - dir * (4 * t + h * up * 0.62), yy - h * up * 0.72);
    }

    // Mesh (diagonals) between the line wires.
    for (var yy = g.fenceTop; yy < g.fenceBottom; yy += 10) {
      c.drawLine(at(yy, 0.05), at(yy + 10, 0.95), mesh);
      c.drawLine(at(yy + 10, 0.05), at(yy, 0.95), mesh);
    }
    for (final up in [0.1, 0.5, 0.95]) {
      final path = Path()..moveTo(at(g.fenceTop, up).dx, at(g.fenceTop, up).dy);
      for (var yy = g.fenceTop; yy <= g.fenceBottom; yy += 12) {
        final o = at(yy, up);
        path.lineTo(o.dx, o.dy);
      }
      final o = at(g.fenceBottom, up);
      path.lineTo(o.dx, o.dy);
      c.drawPath(path, wire..style = PaintingStyle.stroke);
    }
    for (var yy = g.fenceTop; yy <= g.fenceBottom + 0.5; yy += (g.fenceBottom - g.fenceTop) / 9) {
      c.drawLine(at(yy, 0), at(yy, 1.08), post);
    }
  }

  void _shed(Canvas c) {
    final g = geo;
    final r = g.shed;
    // The wall facing the lane (corrugated tin) and the roof above it.
    final wall = Rect.fromLTRB(r.left, r.top + 10, r.right, r.bottom);
    c.drawRect(
      wall,
      Paint()
        ..shader = LinearGradient(
          begin: g.layout.mirror ? Alignment.centerRight : Alignment.centerLeft,
          end: g.layout.mirror ? Alignment.centerLeft : Alignment.centerRight,
          colors: const [Color(0xFFA9B1B7), Color(0xFF7F888F)],
        ).createShader(wall),
    );
    final rib = Paint()
      ..color = const Color(0x55394047)
      ..strokeWidth = 1;
    for (var xx = wall.left + 5; xx < wall.right; xx += 6) {
      c.drawLine(Offset(xx, wall.top), Offset(xx, wall.bottom), rib);
    }
    final roof = Path()
      ..moveTo(r.left - 6, r.top + 12)
      ..lineTo(r.left + 8, r.top - 6)
      ..lineTo(r.right + 4, r.top - 6)
      ..lineTo(r.right + 6, r.top + 12)
      ..close();
    c.drawPath(roof, Paint()..color = const Color(0xFF8A6E58));
    c.drawPath(
        roof,
        Paint()
          ..color = const Color(0xFF5E4A3B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
    // A door at the lane's near end of the wall.
    final door = Rect.fromLTWH(g.layout.mirror ? r.right - 34 : r.left + 12, r.bottom - 44, 22, 44);
    c.drawRect(door, Paint()..color = const Color(0xFF59616A));
    c.drawCircle(Offset(door.center.dx + 6, door.center.dy), 1.6, Paint()..color = const Color(0xFFCFD5DA));
  }

  void _wires(Canvas c, M5WireRest rest) {
    final g = geo;
    final w = Paint()
      ..color = _wire
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    // The intact phases leave both poles off screen.
    for (final dx in [-26.0, -9.0, 26.0]) {
      final a = g.armA + Offset(dx, -9);
      c.drawLine(a, Offset(g.x(-20), a.dy - 22), w..strokeWidth = 1.4);
      final b = g.armB + Offset(dx * 0.8, -7);
      c.drawLine(b, Offset(g.x(380), b.dy - 18), w);
    }
    w.strokeWidth = 2;
    // End A: hangs low from pole A, its broken tip a little frayed.
    final hang = Path()
      ..moveTo(g.hangA.dx, g.hangA.dy)
      ..quadraticBezierTo(g.hangA.dx + g.x(8) - g.x(0), (g.hangA.dy + g.endA.dy) / 2, g.endA.dx, g.endA.dy);
    c.drawPath(hang, w);
    _fray(c, g.endA);
    // Piece B: from pole B, sags across, then lies where it rests.
    final from = g.armB + Offset(g.layout.mirror ? 7 : -7, -7);
    final touch = g.touchB ?? g.endB;
    final sag = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo((from.dx + touch.dx) / 2, math.max(from.dy, touch.dy) - 10, touch.dx, touch.dy);
    if (rest == M5WireRest.shed) {
      // Over the roof edge and down the wall to the ground.
      sag.quadraticBezierTo(touch.dx + (g.endB.dx - touch.dx) * 0.2, (touch.dy + g.endB.dy) / 2, g.endB.dx, g.endB.dy);
    } else {
      sag.quadraticBezierTo((touch.dx + g.endB.dx) / 2, touch.dy + 6, g.endB.dx, g.endB.dy);
    }
    c.drawPath(sag, w);
    _fray(c, g.endB);
  }

  void _fray(Canvas c, Offset at) {
    final p = Paint()
      ..color = const Color(0xFFB87333)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    for (final a in [-0.6, 0.0, 0.7]) {
      c.drawLine(at, at + Offset(math.cos(a + 1.2) * 5, math.sin(a + 1.2) * 5), p);
    }
  }

  /// The rope ring: its back half under the things, its front half over them.
  void _ring(Canvas c, {required bool back}) {
    final r = geo.ring;
    final rope = Paint()
      ..color = const Color(0xFFE2B33C)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    final flag = Paint()..color = const Color(0xFFD8452F);
    final y0 = back ? r.top : r.bottom;
    c.drawLine(Offset(r.left, y0), Offset(r.right, y0), rope);
    if (back) {
      c.drawLine(r.topLeft, r.bottomLeft, rope);
      c.drawLine(r.topRight, r.bottomRight, rope);
    }
    final posts = back ? [r.topLeft, r.topCenter, r.topRight] : [r.bottomLeft, r.bottomCenter, r.bottomRight];
    for (final o in posts) {
      final s = geo.scaleAt(o.dy);
      final pole = Rect.fromLTWH(o.dx - 1.5, o.dy - 16 * s, 3, 16 * s);
      c.drawRect(pole, Paint()..color = const Color(0xFFEDEDED));
      for (var i = 0; i < 3; i++) {
        c.drawRect(Rect.fromLTWH(pole.left, pole.top + i * 5.4 * s, 3, 2.6 * s), flag);
      }
    }
    // Little red flags on the rope.
    final n = ((r.width) / 26).floor();
    for (var i = 1; i < n; i++) {
      final xx = r.left + i * r.width / n;
      c.drawPath(
        Path()
          ..moveTo(xx - 2.5, y0)
          ..lineTo(xx + 2.5, y0)
          ..lineTo(xx, y0 + 5)
          ..close(),
        flag,
      );
    }
  }

  void _tree(Canvas c, Offset at) {
    final s = geo.scaleAt(at.dy);
    c.drawOval(Rect.fromCenter(center: at, width: 34 * s, height: 7 * s), Paint()..color = const Color(0x44000000));
    final trunk = Rect.fromLTWH(at.dx - 4 * s, at.dy - 40 * s, 8 * s, 40 * s);
    c.drawRect(trunk, Paint()..color = const Color(0xFF5B4330));
    final leaf = Paint()..color = const Color(0xFF41603F);
    final leaf2 = Paint()..color = const Color(0xFF557A4C);
    c.drawCircle(at + Offset(-10 * s, -50 * s), 15 * s, leaf);
    c.drawCircle(at + Offset(10 * s, -52 * s), 16 * s, leaf);
    c.drawCircle(at + Offset(0, -64 * s), 15 * s, leaf2);
  }

  void _drum(Canvas c, Offset at) {
    final s = geo.scaleAt(at.dy);
    final body = Rect.fromLTWH(at.dx - 9 * s, at.dy - 24 * s, 18 * s, 24 * s);
    c.drawOval(Rect.fromCenter(center: at, width: 24 * s, height: 5 * s), Paint()..color = const Color(0x44000000));
    c.drawRRect(
      RRect.fromRectAndRadius(body, Radius.circular(4 * s)),
      Paint()..shader = const LinearGradient(colors: [Color(0xFF2F6FB0), Color(0xFF4F92D2), Color(0xFF2A5F98)]).createShader(body),
    );
    c.drawLine(Offset(body.left, body.top + 7 * s), Offset(body.right, body.top + 7 * s), Paint()..color = const Color(0x66FFFFFF));
  }

  void _bench(Canvas c, Offset at) {
    final s = geo.scaleAt(at.dy);
    final wood = Paint()
      ..color = const Color(0xFF7A5A3C)
      ..strokeWidth = 3 * s
      ..strokeCap = StrokeCap.round;
    c.drawOval(Rect.fromCenter(center: at, width: 44 * s, height: 6 * s), Paint()..color = const Color(0x44000000));
    c.drawLine(at + Offset(-18 * s, -12 * s), at + Offset(18 * s, -12 * s), wood..strokeWidth = 5 * s);
    wood.strokeWidth = 2.6 * s;
    for (final dx in [-15.0, 15.0]) {
      c.drawLine(at + Offset(dx * s, -12 * s), at + Offset(dx * s, 0), wood);
    }
  }

  void _clothesline(Canvas c) {
    final g = geo;
    final a = g.lineFrom;
    final b = g.lineTo;
    final bamboo = Paint()
      ..color = const Color(0xFFB59A5A)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final lineH = 34 * g.scaleAt(a.dy);
    // The far post (always) and the near post when it is not tied to the host.
    c.drawLine(b, b - Offset(0, lineH), bamboo);
    if (!g.layout.lineTied) c.drawLine(a, a - Offset(0, lineH), bamboo);
    final top = a - Offset(0, lineH * (g.layout.lineTied && g.layout.lineHost == M5Host.shed ? 1.4 : 0.92));
    final end = b - Offset(0, lineH);
    final line = Path()
      ..moveTo(top.dx, top.dy)
      ..quadraticBezierTo((top.dx + end.dx) / 2, math.max(top.dy, end.dy) + 6, end.dx, end.dy);
    c.drawPath(
        line,
        Paint()
          ..color = _gi
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke);
    // Clothes on the line.
    const colors = [Color(0xFFB24A3A), Color(0xFFE0C76A), Color(0xFF4F7FB0), Color(0xFFE9E3D5)];
    for (var i = 0; i < 4; i++) {
      final t = 0.22 + i * 0.18;
      final o = Offset.lerp(top, end, t)! + Offset(0, 4 * math.sin(t * math.pi));
      c.drawRect(Rect.fromLTWH(o.dx - 5, o.dy, 10, 13), Paint()..color = colors[i]);
    }
  }

  void _bike(Canvas c) {
    final g = geo;
    final at = g.bike;
    final s = g.scaleAt(at.dy);
    final hostX = g.layout.bikeHost == M5Host.fence ? g.fenceX : (g.layout.mirror ? g.shed.right : g.shed.left);
    final toward = (hostX - at.dx).sign;
    final frame = Paint()
      ..color = const Color(0xFF2E5E8C)
      ..strokeWidth = 2.2 * s
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final tyre = Paint()
      ..color = _ink
      ..strokeWidth = 2 * s
      ..style = PaintingStyle.stroke;
    c.drawOval(Rect.fromCenter(center: at, width: 46 * s, height: 6 * s), Paint()..color = const Color(0x44000000));
    // Seen end-on along the lane: two wheels one behind the other, leaning
    // its handlebar onto the host (touching) or upright on its stand (gap).
    final lean = g.layout.bikeTouch ? 0.32 : 0.0;
    final topX = g.layout.bikeTouch ? hostX - toward * 1.5 : at.dx + toward * 3;
    final w1 = at + Offset(-toward * 3 * s, -11 * s);
    final w2 = at + Offset(-toward * 1 * s, -15 * s);
    c.drawCircle(w1, 11 * s, tyre);
    c.drawCircle(w2, 10 * s, tyre);
    final bar = Offset(topX, at.dy - 30 * s - lean * 4);
    c.drawLine(w1, bar, frame);
    c.drawLine(w2, Offset((w2.dx + bar.dx) / 2, bar.dy + 4 * s), frame);
    c.drawLine(bar + Offset(-6 * s, 0), bar + Offset(6 * s, 0), frame..color = const Color(0xFF3A3F45));
    if (!g.layout.bikeTouch) {
      c.drawLine(at + Offset(0, -4 * s), at + Offset(-toward * 6 * s, 0), frame..strokeWidth = 1.4 * s);
    }
  }

  @override
  bool shouldRepaint(M5WireLanePainter old) => old.geo != geo || old.seed != seed;
}

/// The people in the lane (repaints from the level's frame notifier only
/// while a wave walks).
class M5WalkersPainter extends CustomPainter {
  M5WalkersPainter({required this.geo, required this.views, super.repaint});
  final M5WireGeo geo;
  final List<M5WalkerView> Function() views;

  static const shirts = [Color(0xFF8E6B4E), Color(0xFF6F7F8E), Color(0xFF7D6A7F), Color(0xFF6E805F), Color(0xFF8A7A5A)];
  static const lungis = [Color(0xFF3F4A5C), Color(0xFF4C3F3A), Color(0xFF3D4C44), Color(0xFF4A4458), Color(0xFF433F35)];

  @override
  void paint(Canvas canvas, Size size) {
    final list = [...views()]..sort((a, b) => a.at.dy.compareTo(b.at.dy));
    for (final v in list) {
      if (v.opacity <= 0.01) continue;
      _person(canvas, v);
    }
  }

  void _person(Canvas c, M5WalkerView v) {
    final s = geo.scaleAt(v.at.dy) * 0.9;
    final a = (v.opacity.clamp(0.0, 1.0) * 255).round();
    Color op(Color col) => col.withAlpha((col.a * a).round());
    final shirt = v.grey ? const Color(0xFF8D949B) : shirts[v.tint % shirts.length];
    final lungi = v.grey ? const Color(0xFF6E757C) : lungis[v.tint % lungis.length];
    final skin = v.grey ? const Color(0xFFA2A8AE) : const Color(0xFF9C6B4A);
    final f = v.facingLeft ? -1.0 : 1.0;
    final o = v.at;
    c.drawOval(Rect.fromCenter(center: o, width: 18 * s, height: 4 * s), Paint()..color = op(const Color(0x55000000)));
    final leg = Paint()
      ..color = op(skin)
      ..strokeWidth = 2.6 * s
      ..strokeCap = StrokeCap.round;
    final swing = v.phase == null ? 0.0 : math.sin(v.phase! * 2 * math.pi) * 4 * s;
    c.drawLine(o + Offset(-2 * s, -12 * s), o + Offset(-2 * s + swing, 0), leg);
    c.drawLine(o + Offset(2 * s, -12 * s), o + Offset(2 * s - swing, 0), leg);
    // Lungi / trousers and the shirt.
    final hip = o + Offset(0, -12 * s);
    c.drawPath(
      Path()
        ..moveTo(hip.dx - 5 * s, hip.dy - 10 * s)
        ..lineTo(hip.dx + 5 * s, hip.dy - 10 * s)
        ..lineTo(hip.dx + 6 * s, hip.dy + 4 * s)
        ..lineTo(hip.dx - 6 * s, hip.dy + 4 * s)
        ..close(),
      Paint()..color = op(lungi),
    );
    final torso = RRect.fromRectAndRadius(Rect.fromLTWH(hip.dx - 6 * s, hip.dy - 24 * s, 12 * s, 15 * s), Radius.circular(3 * s));
    c.drawRRect(torso, Paint()..color = op(shirt));
    final arm = Paint()
      ..color = op(skin)
      ..strokeWidth = 2.2 * s
      ..strokeCap = StrokeCap.round;
    final shoulder = hip + Offset(f * 4 * s, -21 * s);
    if (v.reachTo != null) {
      final d = v.reachTo! - shoulder;
      final n = d.distance == 0 ? Offset(f, 0) : d / d.distance;
      c.drawLine(shoulder, shoulder + n * 12 * s, arm);
    } else {
      c.drawLine(shoulder, shoulder + Offset(-swing * 0.6, 11 * s), arm);
    }
    c.drawLine(hip + Offset(-f * 4 * s, -21 * s), hip + Offset(-f * 4 * s + swing * 0.6, -10 * s), arm);
    final head = hip + Offset(f * 0.5 * s, -29 * s);
    c.drawCircle(head, 4.6 * s, Paint()..color = op(skin));
    c.drawArc(Rect.fromCircle(center: head, radius: 4.8 * s), math.pi, math.pi, false,
        Paint()..color = op(v.grey ? const Color(0xFF6A7076) : const Color(0xFF231C18)));
    if (v.stopped) _palm(c, head + Offset(0, -14 * s), s, op);
  }

  /// A raised open palm (the trainee's "stop" reached him).
  void _palm(Canvas c, Offset at, double s, Color Function(Color) op) {
    c.drawCircle(at, 8 * s, Paint()..color = op(const Color(0xEEFFFFFF)));
    final p = Paint()..color = op(const Color(0xFFD8452F));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: at + Offset(0, 1.5 * s), width: 6 * s, height: 5 * s), Radius.circular(1.5 * s)), p);
    for (var i = 0; i < 4; i++) {
      c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(at.dx - 3 * s + i * 1.6 * s, at.dy - 5 * s, 1.2 * s, 5 * s), Radius.circular(0.6 * s)),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(M5WalkersPainter old) => true;
}

/// The one-time demo's hand: from the trainee's hand toward the grey figure
/// (two laps, then still).
class M5DemoHandPainter extends CustomPainter {
  const M5DemoHandPainter({required this.from, required this.to, required this.t});
  final Offset from;
  final Offset to;

  /// 0..1 through one lap.
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final e = Curves.easeInOut.transform(t.clamp(0.0, 1.0));
    final tip = Offset.lerp(from, Offset.lerp(from, to, 0.82)!, e)!;
    final trail = Paint()
      ..shader = LinearGradient(colors: const [Color(0x00FFFFFF), Color(0x99FFFFFF)]).createShader(Rect.fromPoints(from, tip))
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    if ((tip - from).distance > 4) canvas.drawLine(from, tip, trail);
    // A pointing finger.
    final hand = Paint()..color = const Color(0xFFF4E9DC);
    final edge = Paint()
      ..color = const Color(0xFF4A3B30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final palm = RRect.fromRectAndRadius(Rect.fromCenter(center: tip + const Offset(4, 12), width: 16, height: 16), const Radius.circular(6));
    final finger = RRect.fromRectAndRadius(Rect.fromLTWH(tip.dx - 3, tip.dy - 2, 6, 14), const Radius.circular(3));
    canvas.drawRRect(palm, hand);
    canvas.drawRRect(finger, hand);
    canvas.drawRRect(palm, edge);
    canvas.drawRRect(finger, edge);
  }

  @override
  bool shouldRepaint(M5DemoHandPainter old) => old.t != t || old.from != from || old.to != to;
}

/// A deadly move: the flash at the live metal, in colour over the grey scene.
class M5WireFlashPainter extends CustomPainter {
  const M5WireFlashPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas canvas, Size size) {
    final k = Curves.easeOut.transform(v.clamp(0.0, 1.0));
    final glow = Paint()
      ..shader = RadialGradient(colors: [
        Color.fromRGBO(255, 250, 210, 0.95 * (1 - k * 0.4)),
        Color.fromRGBO(255, 190, 60, 0.6 * (1 - k * 0.5)),
        const Color(0x00FF9020),
      ]).createShader(Rect.fromCircle(center: at, radius: 20 + 40 * k));
    canvas.drawCircle(at, 20 + 40 * k, glow);
    final bolt = Paint()
      ..color = Color.fromRGBO(255, 245, 190, 1 - k * 0.5)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + 0.3;
      final r1 = 8 + 10 * k;
      final r2 = 18 + 30 * k;
      final mid = at + Offset(math.cos(a + 0.2) * (r1 + r2) / 2, math.sin(a + 0.2) * (r1 + r2) / 2);
      canvas.drawLine(at + Offset(math.cos(a) * r1, math.sin(a) * r1), mid, bolt);
      canvas.drawLine(mid, at + Offset(math.cos(a) * r2, math.sin(a) * r2), bolt);
    }
  }

  @override
  bool shouldRepaint(M5WireFlashPainter old) => old.v != v || old.at != at;
}
