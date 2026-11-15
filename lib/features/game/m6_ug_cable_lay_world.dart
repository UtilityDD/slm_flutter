import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

// The drawn world of lesson 6.5 কাজ 1 "বাঁক বুঝে কেবিল পাতা"
// (m6_ug_cable_lay.dart): a new 11 kV XLPE cable laid in a town lane trench
// from a DTR plinth, round the lane corner, under a culvert and up a riser
// pole. Three stations:
//
//  বাঁক (three of four dealt): a close-up of one bend in the trench. The
//    cable comes in on one leg, turns a quarter circle and leaves on the
//    other; the corner is dug wide up to a wall on the inside of the turn
//    (the DTR plinth's footing, a house's foundation, the culvert's box or a
//    brick kerb), which stops the bend from opening further. Plan view for
//    the plinth and the lane corner, a cut-away side view for the culvert
//    and the riser.
//  আর্মার: both cable ends side by side — the DTR plinth end and the riser
//    pole end — each with its gland, its armour earth lead and lug hanging,
//    and an earth point. The two ends are drawn alike.
//  টার্মিনেশন: the riser pole with the cable's open end at the top; at its
//    foot a termination-kit box and a phone, the same size.
//
// No numbers, strain colours or ticks on the bend: the only measure is the
// docket's ring (drawn by the page under the finger, or ghosted after a
// slip). Code-drawn, gradients, no bitmaps. Design: 360 wide × the scene's
// height; the ground follows the bottom of the screen.

/// The four bends a route can deal.
enum M6Bend { plinth, corner, culvert, riser }

/// The cable's drawn width (design px).
const double kM6CableW = 15;

/// The tightest the belly handle can pull a bend (design px).
const double kM6RLow = 30;

/// The belly of a quarter bend sits this far in from the corner, per unit of
/// radius (√2 − 1).
const double kM6Belly = 0.41421356;

/// Where things are (design px, 360 wide).
@immutable
class M6UgGeo {
  const M6UgGeo._(this.height, this.inset);

  factory M6UgGeo.forScene(double height, double inset) => M6UgGeo._(height, inset);

  final double height;
  final double inset;

  /// The job docket (hold it: the ring under the finger).
  static const Rect docket = Rect.fromLTWH(8, 108, 172, 66);

  /// The work area's top (under the docket).
  static const double top = 190;

  /// The bottom of the work area (the button row and the guide below).
  double get bottom => height - 150 - inset * 0.5;

  /// The ground line of the side views (armour, termination).
  double get groundY => height - 150 - inset * 0.5;

  // --- a bend -----------------------------------------------------------------
  /// +1: the straight leg comes in from the left; −1: from the right.
  static int sx(M6Bend k) => k == M6Bend.corner || k == M6Bend.culvert ? -1 : 1;

  /// +1: the other leg runs down; −1: up (the riser).
  static int sy(M6Bend k) => k == M6Bend.riser ? -1 : 1;

  /// A plan view (from above) or a cut-away side view.
  static bool plan(M6Bend k) => k == M6Bend.plinth || k == M6Bend.corner;

  /// The corner the two legs' centre lines meet at.
  Offset corner(M6Bend k) => switch (k) {
        M6Bend.plinth => const Offset(262, top + 38),
        M6Bend.corner => const Offset(98, top + 38),
        M6Bend.culvert => const Offset(98, top + 46),
        M6Bend.riser => Offset(250, math.max(top + 70, bottom - 160)),
      };

  /// The unit direction into the turn (the way a bend widens).
  static Offset inward(M6Bend k) => Offset(-sx(k).toDouble(), sy(k).toDouble()) / math.sqrt2;

  /// The bend's centre for radius [r].
  Offset centre(M6Bend k, double r) => corner(k) + Offset(-sx(k) * r, sy(k) * r);

  /// The arc's middle point (the belly handle) for radius [r].
  Offset belly(M6Bend k, double r) => corner(k) + inward(k) * (kM6Belly * r);

  /// The belly handle's touch box.
  Rect handleHit(M6Bend k, double r) => Rect.fromCenter(center: belly(k, r), width: 56, height: 56);

  /// The wall's corner on the inside of the turn: the belly cannot pass it.
  Offset wallApex(M6Bend k, double rMax) => corner(k) + inward(k) * (kM6Belly * rMax + kM6CableW * 0.55);

  /// The radius a finger at [p] asks for, from a grab at [from] on a bend of
  /// radius [r0] (moved along the inward diagonal only).
  double radiusFor(M6Bend k, {required double r0, required Offset from, required Offset p}) {
    final d = p - from;
    final i = inward(k);
    return r0 + (d.dx * i.dx + d.dy * i.dy) / kM6Belly;
  }

  /// The cable's path for a bend of radius [r] (edge → leg → arc → leg → edge).
  Path cablePath(M6Bend k, double r) {
    final s = sx(k), t = sy(k);
    final kk = corner(k);
    final o = centre(k, r);
    final a = Offset(kk.dx - s * r, kk.dy);
    return Path()
      ..moveTo(s > 0 ? -12 : 372, kk.dy)
      ..lineTo(a.dx, a.dy)
      ..arcTo(Rect.fromCircle(center: o, radius: r), -t * math.pi / 2, s * t * math.pi / 2, false)
      ..lineTo(kk.dx, t > 0 ? height + 12 : -12);
  }

  /// The ghost ring (shown after a slip): the tightest allowed bend, touching
  /// both legs.
  Offset ghostCentre(M6Bend k, double rMin) => centre(k, rMin);

  // --- the armour ends --------------------------------------------------------
  /// The gland level (above the guide's bubble on every phone).
  double get glandY => math.max(top + 30, groundY - 230);

  /// Each end's centre x: 0 the DTR plinth, 1 the riser pole.
  static const List<double> endX = [96, 250];

  Offset gland(int i) => Offset(endX[i], glandY);

  /// Where the armour earth lead's lug hangs, free.
  Offset lugRest(int i) => Offset(endX[i] - 36, glandY + 52);

  /// The earth point the lug is bolted to.
  Offset earthPoint(int i) => Offset(endX[i] + 40, glandY + 40);
  Rect lugHit(int i) => Rect.fromCenter(center: lugRest(i), width: 48, height: 48);
  Rect earthHit(int i) => Rect.fromCenter(center: earthPoint(i), width: 56, height: 56);

  // --- the termination --------------------------------------------------------
  static const double poleX = 236;

  /// The kit box and the phone stand in these two slots by the pole's foot
  /// (left of the guide's speech bubble).
  Rect slot(int i) => Rect.fromLTWH(i == 0 ? 14 : 82, groundY - 110, 60, 56);

  /// The cable's open end at the pole top.
  Offset get cableTop => Offset(poleX - 16, math.max(118.0, groundY - 420));

  @override
  bool operator ==(Object other) => other is M6UgGeo && other.height == height && other.inset == inset;

  @override
  int get hashCode => Object.hash(height, inset);
}

/// What a bend station shows now.
@immutable
class M6BendRig {
  const M6BendRig({required this.kind, required this.r, required this.rMin, required this.rMax, this.ghost = false, this.crease, this.placed = false});
  final M6Bend kind;

  /// The bend's radius now.
  final double r;
  final double rMin;
  final double rMax;

  /// After a slip: the ring ghosted in the corner.
  final bool ghost;

  /// After a slip: the crease cut-away at the belly of a bend of this radius
  /// (null: none).
  final double? crease;

  /// Placed right: the cable is laid (bedded with sand).
  final bool placed;

  @override
  bool operator ==(Object other) =>
      other is M6BendRig &&
      other.kind == kind &&
      other.r == r &&
      other.rMin == rMin &&
      other.rMax == rMax &&
      other.ghost == ghost &&
      other.crease == crease &&
      other.placed == placed;

  @override
  int get hashCode => Object.hash(kind, r, rMin, rMax, ghost, crease, placed);
}

// ============================================================================
// The bend
// ============================================================================

class M6BendPainter extends CustomPainter {
  const M6BendPainter({required this.geo, required this.rig, required this.seed});
  final M6UgGeo geo;
  final M6BendRig rig;
  final int seed;

  @override
  void paint(Canvas c, Size size) {
    final k = rig.kind;
    final rnd = math.Random(seed);
    final w = size.width;
    final h = size.height;
    final kk = geo.corner(k);
    final s = M6UgGeo.sx(k), t = M6UgGeo.sy(k);
    final apex = geo.wallApex(k, rig.rMax);
    if (M6UgGeo.plan(k)) {
      _lane(c, w, h, rnd);
    } else {
      _soil(c, w, h, kk, t, rnd);
    }
    // The trench: dug from its outer edge to the wall on the inside.
    const half = 26.0;
    final outer = Offset(kk.dx + s * half, kk.dy - t * half);
    final far = Offset(s > 0 ? -2 : w + 2, t > 0 ? h + 2 : -2);
    final trench = Rect.fromPoints(outer, far);
    c.drawRect(
      trench,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: M6UgGeo.plan(k) ? const [Color(0xFF6E5236), Color(0xFF52391F)] : const [Color(0xFF4A3420), Color(0xFF392816)],
        ).createShader(trench),
    );
    // Sand bed speckle.
    final sand = Paint()..color = const Color(0x33E8D5A6);
    for (var i = 0; i < 70; i++) {
      final p = Offset(trench.left + rnd.nextDouble() * trench.width, trench.top + rnd.nextDouble() * trench.height);
      c.drawCircle(p, 1 + rnd.nextDouble() * 1.4, sand);
    }
    // The trench's outer edges (a lip of lighter soil).
    final lip = Paint()
      ..color = const Color(0xFF9C7A52)
      ..strokeWidth = 4;
    c.drawLine(Offset(far.dx, outer.dy), outer, lip);
    c.drawLine(outer, Offset(outer.dx, far.dy), lip);
    // The wall on the inside of the turn.
    final wall = Rect.fromPoints(apex, Offset(s > 0 ? -2 : w + 2, t > 0 ? h + 2 : -2));
    _wall(c, wall, k, apex, rnd);
    // The ghost ring: the tightest allowed bend, in the corner.
    if (rig.ghost) _ghost(c, geo.ghostCentre(k, rig.rMin), rig.rMin);
    // The cable.
    final path = geo.cablePath(k, rig.r);
    c.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = kM6CableW + 3
        ..strokeCap = StrokeCap.butt
        ..color = const Color(0x66000000),
    );
    c.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = kM6CableW
        ..color = const Color(0xFF1D2025),
    );
    c.drawPath(
      path.shift(Offset(-s * 1.5, -t * 1.5)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0x40FFFFFF),
    );
    if (rig.placed) {
      // Bedded: a sand cover over the laid cable.
      c.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = kM6CableW + 8
          ..color = const Color(0x55E8D5A6),
      );
    }
    final cr = rig.crease;
    if (cr != null) _crease(c, geo.belly(k, cr), M6UgGeo.inward(k));
  }

  void _lane(Canvas c, double w, double h, math.Random rnd) {
    final r = Rect.fromLTWH(0, 0, w, h);
    c.drawRect(r, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8E9298), Color(0xFF6C7077)]).createShader(r));
    final joint = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 1;
    for (var y = 0.0; y < h; y += 22) {
      c.drawLine(Offset(0, y), Offset(w, y), joint);
      final off = (y ~/ 22).isEven ? 0.0 : 18.0;
      for (var x = off; x < w; x += 36) {
        c.drawLine(Offset(x, y), Offset(x, y + 22), joint);
      }
    }
    final stain = Paint()..color = const Color(0x14000000);
    for (var i = 0; i < 9; i++) {
      c.drawCircle(Offset(rnd.nextDouble() * w, rnd.nextDouble() * h), 8 + rnd.nextDouble() * 18, stain);
    }
  }

  void _soil(Canvas c, double w, double h, Offset kk, int t, math.Random rnd) {
    // A cut-away: the sky above the ground line, soil layers below.
    final ground = t > 0 ? M6UgGeo.top - 40 : math.max(60.0, kk.dy - 210);
    final sky = Rect.fromLTWH(0, 0, w, ground);
    c.drawRect(sky, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF7FB7E0), Color(0xFFCFE6F2)]).createShader(sky));
    final soil = Rect.fromLTWH(0, ground, w, h - ground);
    c.drawRect(soil, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8A6A47), Color(0xFF5E452C)]).createShader(soil));
    final layer = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 2;
    for (var y = ground + 40; y < h; y += 46) {
      c.drawLine(Offset(0, y + rnd.nextDouble() * 6), Offset(w, y + rnd.nextDouble() * 6), layer);
    }
    // The road / lane surface.
    c.drawRect(Rect.fromLTWH(0, ground - 6, w, 10), Paint()..color = const Color(0xFF4A4E55));
    final stone = Paint()..color = const Color(0x33FFFFFF);
    for (var i = 0; i < 30; i++) {
      c.drawCircle(Offset(rnd.nextDouble() * w, ground + 12 + rnd.nextDouble() * (h - ground)), 1.2 + rnd.nextDouble() * 2, stone);
    }
    if (t < 0) {
      // The riser pole the cable climbs (beside the vertical leg).
      final px = kk.dx + 22;
      final pole = Rect.fromLTRB(px, 0, px + 14, ground + 26);
      c.drawRect(pole, Paint()..shader = const LinearGradient(colors: [Color(0xFFB9BDC2), Color(0xFF8A8F95)]).createShader(pole));
    }
  }

  void _wall(Canvas c, Rect wall, M6Bend k, Offset apex, math.Random rnd) {
    final colors = switch (k) {
      M6Bend.plinth => const [Color(0xFFC9C4B8), Color(0xFF9E998C)],
      M6Bend.corner => const [Color(0xFFB0563A), Color(0xFF8A3F28)],
      M6Bend.culvert => const [Color(0xFFADB1B4), Color(0xFF7E8387)],
      M6Bend.riser => const [Color(0xFFA35A3C), Color(0xFF7C4129)],
    };
    c.drawRect(wall, Paint()..shader = LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors).createShader(wall));
    final line = Paint()
      ..color = const Color(0x33000000)
      ..strokeWidth = 1.2;
    if (k == M6Bend.corner || k == M6Bend.riser) {
      // Brick courses.
      for (var y = wall.top; y < wall.bottom; y += 12) {
        c.drawLine(Offset(wall.left, y), Offset(wall.right, y), line);
        final off = ((y - wall.top) ~/ 12).isEven ? 0.0 : 12.0;
        for (var x = wall.left + off; x < wall.right; x += 24) {
          c.drawLine(Offset(x, y), Offset(x, y + 12), line);
        }
      }
    } else {
      // Concrete: a few pores and a shuttering line.
      final pore = Paint()..color = const Color(0x22000000);
      for (var i = 0; i < 26; i++) {
        c.drawCircle(Offset(wall.left + rnd.nextDouble() * wall.width, wall.top + rnd.nextDouble() * wall.height), 1 + rnd.nextDouble() * 1.5, pore);
      }
      if (k == M6Bend.culvert) {
        // The culvert's pipe mouth.
        final m = Offset((wall.left + wall.right) / 2, (wall.top + wall.bottom) / 2);
        c.drawCircle(m, math.min(40, math.min(wall.width, wall.height) * 0.3), Paint()..color = const Color(0xFF2C3036));
      }
    }
    // The wall's two faces toward the trench (the stop).
    final edge = Paint()
      ..color = const Color(0xFF3A3530)
      ..strokeWidth = 3;
    final farX = apex.dx == wall.left ? wall.right : wall.left;
    final farY = apex.dy == wall.top ? wall.bottom : wall.top;
    c.drawLine(apex, Offset(apex.dx, farY), edge);
    c.drawLine(apex, Offset(farX, apex.dy), edge);
  }

  void _ghost(Canvas c, Offset at, double r) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0x8CFFE7A0);
    const n = 28;
    for (var i = 0; i < n; i++) {
      final a = i * 2 * math.pi / n;
      c.drawArc(Rect.fromCircle(center: at, radius: r), a, math.pi / n, false, p);
    }
  }

  /// A magnifier off the belly: the cable's layers, cracked.
  void _crease(Canvas c, Offset belly, Offset inward) {
    final at = belly + inward * 50;
    const r = 30.0;
    c.drawCircle(at, r + 3, Paint()..color = const Color(0xFFFFFFFF));
    c.save();
    c.clipPath(Path()..addOval(Rect.fromCircle(center: at, radius: r)));
    c.drawCircle(at, r, Paint()..color = const Color(0xFF1D2025));
    for (final (rr, col) in const [
      (24.0, Color(0xFF7B8189)),
      (19.0, Color(0xFFC07A3A)),
      (15.0, Color(0xFF2B2B2B)),
      (12.0, Color(0xFFF2F2EE)),
      (6.0, Color(0xFFB8BEC5)),
    ]) {
      c.drawCircle(at, rr, Paint()..color = col);
    }
    final crack = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = const Color(0xFFE53935);
    c.drawPath(
      Path()
        ..moveTo(at.dx - 20, at.dy - 6)
        ..lineTo(at.dx - 8, at.dy + 2)
        ..lineTo(at.dx - 2, at.dy - 5)
        ..lineTo(at.dx + 7, at.dy + 4)
        ..lineTo(at.dx + 20, at.dy - 2),
      crack,
    );
    c.restore();
    c.drawCircle(
      at,
      r + 3,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = const Color(0xFFE53935),
    );
    c.drawLine(belly, at + (belly - at) / (belly - at).distance * (r + 3), Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(M6BendPainter old) => old.geo != geo || old.rig != rig || old.seed != seed;
}

/// The docket's ring at true size (centred in its box).
class M6RingPainter extends CustomPainter {
  const M6RingPainter();

  @override
  void paint(Canvas c, Size size) {
    final o = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 4;
    c.drawCircle(
      o,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..color = const Color(0x66FFD54F),
    );
    c.drawCircle(
      o,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFFFFE082),
    );
    c.drawCircle(o, 3, Paint()..color = const Color(0xFFFFE082));
  }

  @override
  bool shouldRepaint(M6RingPainter old) => false;
}

// ============================================================================
// The armour ends
// ============================================================================

@immutable
class M6ArmourRig {
  const M6ArmourRig({this.bonded = const {}, this.dragging, this.dragAt});

  /// The ends whose lug is bolted to the earth point.
  final Set<int> bonded;

  /// The lug in the hand (its end) and where it is now.
  final int? dragging;
  final Offset? dragAt;

  @override
  bool operator ==(Object other) => other is M6ArmourRig && setEquals(other.bonded, bonded) && other.dragging == dragging && other.dragAt == dragAt;

  @override
  int get hashCode => Object.hash(Object.hashAllUnordered(bonded), dragging, dragAt);
}

class M6ArmourPainter extends CustomPainter {
  const M6ArmourPainter({required this.geo, required this.rig, required this.seed});
  final M6UgGeo geo;
  final M6ArmourRig rig;
  final int seed;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    final g = geo.groundY;
    final rnd = math.Random(seed);
    final sky = Rect.fromLTWH(0, 0, w, g);
    c.drawRect(sky, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8CC3E8), Color(0xFFDDEEF5)]).createShader(sky));
    final ground = Rect.fromLTWH(0, g, w, h - g);
    c.drawRect(ground, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF7A6046), Color(0xFF574330)]).createShader(ground));
    // Far houses.
    for (var i = 0; i < 6; i++) {
      final x = i * 64.0 + rnd.nextDouble() * 10;
      final hh = 70 + rnd.nextDouble() * 70;
      c.drawRect(Rect.fromLTWH(x, g - 160 - hh, 54, hh), Paint()..color = Color.lerp(const Color(0xFFD9CFC0), const Color(0xFFB9C3CC), rnd.nextDouble())!);
    }
    // A divider between the two ends (two places, one cable).
    c.drawLine(Offset(w / 2 - 7, 0), Offset(w / 2 - 7, h), Paint()
      ..color = const Color(0x55FFFFFF)
      ..strokeWidth = 3);
    // End 0: the DTR on its plinth.
    final plinth = Rect.fromLTRB(16, geo.glandY + 14, 168, g + 4);
    c.drawRect(plinth, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFD4CFC4), Color(0xFFA8A396)]).createShader(plinth));
    final tank = Rect.fromLTRB(36, geo.glandY - 120, 150, geo.glandY + 14);
    c.drawRRect(RRect.fromRectAndRadius(tank, const Radius.circular(6)), Paint()..shader = const LinearGradient(colors: [Color(0xFF6F8A78), Color(0xFF4E6656)]).createShader(tank));
    for (var i = 0; i < 6; i++) {
      final x = tank.left + 12 + i * 17.0;
      c.drawLine(Offset(x, tank.top + 18), Offset(x, tank.bottom - 10), Paint()
        ..color = const Color(0x33000000)
        ..strokeWidth = 5);
    }
    // End 1: the riser pole.
    const px = 290.0;
    final pole = Rect.fromLTRB(px, 0, px + 16, g + 6);
    c.drawRect(pole, Paint()..shader = const LinearGradient(colors: [Color(0xFFBFC3C8), Color(0xFF8B9096)]).createShader(pole));
    final pipe = Rect.fromLTRB(geo.gland(1).dx - 9, geo.gland(1).dy - 150, geo.gland(1).dx + 9, geo.gland(1).dy - 8);
    c.drawRect(pipe, Paint()..color = const Color(0xFF7D838A));
    for (var y = pipe.top + 20; y < pipe.bottom; y += 40) {
      c.drawLine(Offset(pipe.left - 4, y), Offset(px + 2, y), Paint()
        ..color = const Color(0xFF5A6067)
        ..strokeWidth = 3);
    }
    for (var i = 0; i < 2; i++) {
      _end(c, i, g);
    }
  }

  void _end(Canvas c, int i, double g) {
    final gl = geo.gland(i);
    // The cable from the ground up into the gland.
    final cable = Paint()
      ..strokeWidth = kM6CableW
      ..color = const Color(0xFF1D2025);
    c.drawLine(Offset(gl.dx, g + 30), Offset(gl.dx, gl.dy + 8), cable);
    // The gland.
    final body = Rect.fromCenter(center: gl, width: 26, height: 18);
    c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(4)), Paint()..shader = const LinearGradient(colors: [Color(0xFFE2C26A), Color(0xFFB08A2E)]).createShader(body));
    // The earth point: a copper bar with a bolt, and its earth lead to the
    // ground.
    final e = geo.earthPoint(i);
    final bar = Rect.fromCenter(center: e, width: 34, height: 12);
    c.drawLine(Offset(e.dx, e.dy + 6), Offset(e.dx, g + 22), Paint()
      ..color = const Color(0xFF3E9E4A)
      ..strokeWidth = 4);
    c.drawLine(Offset(e.dx, e.dy + 6), Offset(e.dx, g + 22), Paint()
      ..color = const Color(0xFFE7D23A)
      ..strokeWidth = 1.6);
    c.drawRRect(RRect.fromRectAndRadius(bar, const Radius.circular(3)), Paint()..shader = const LinearGradient(colors: [Color(0xFFE0915A), Color(0xFFA75A28)]).createShader(bar));
    c.drawCircle(e, 3.4, Paint()..color = const Color(0xFF6B6F75));
    // The earth sign under the bar.
    final s = Offset(e.dx + 24, e.dy + 8);
    final sign = Paint()
      ..color = const Color(0xFF2E3338)
      ..strokeWidth = 2;
    c.drawLine(s.translate(0, -8), s, sign);
    c.drawLine(s.translate(-7, 0), s.translate(7, 0), sign);
    c.drawLine(s.translate(-4.5, 3.5), s.translate(4.5, 3.5), sign);
    c.drawLine(s.translate(-2, 7), s.translate(2, 7), sign);
    // The armour earth lead and its lug.
    final bonded = rig.bonded.contains(i);
    final lug = bonded ? e : (rig.dragging == i && rig.dragAt != null ? rig.dragAt! : geo.lugRest(i));
    final from = gl.translate(-6, 8);
    final mid = Offset((from.dx + lug.dx) / 2 - 6, math.max(from.dy, lug.dy) + 16);
    final lead = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(mid.dx, mid.dy, lug.dx, lug.dy);
    c.drawPath(lead, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = const Color(0xFF3E9E4A));
    c.drawPath(lead, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = const Color(0xFFE7D23A));
    c.drawCircle(lug, 8, Paint()..color = const Color(0xFFC77B3E));
    c.drawCircle(lug, 3.4, Paint()..color = bonded ? const Color(0xFF6B6F75) : const Color(0xFF2B2016));
    if (bonded) {
      // The bolt and nut over the lug.
      c.drawRect(Rect.fromCenter(center: e, width: 9, height: 9), Paint()..color = const Color(0xFF8D9399));
    }
  }

  @override
  bool shouldRepaint(M6ArmourPainter old) => old.geo != geo || old.rig != rig || old.seed != seed;
}

// ============================================================================
// The termination
// ============================================================================

class M6TermPainter extends CustomPainter {
  const M6TermPainter({required this.geo, required this.kitSlot, required this.kitLabel, required this.seed});
  final M6UgGeo geo;

  /// The slot (0 left, 1 right) the kit box stands in; the phone in the other.
  final int kitSlot;
  final String kitLabel;
  final int seed;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    final g = geo.groundY;
    final rnd = math.Random(seed);
    final sky = Rect.fromLTWH(0, 0, w, g);
    c.drawRect(sky, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF86BFE6), Color(0xFFDCEDF5)]).createShader(sky));
    final ground = Rect.fromLTWH(0, g, w, h - g);
    c.drawRect(ground, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8C8F94), Color(0xFF63666B)]).createShader(ground));
    for (var i = 0; i < 5; i++) {
      final x = i * 80.0 + rnd.nextDouble() * 14;
      final hh = 90 + rnd.nextDouble() * 80;
      c.drawRect(Rect.fromLTWH(x, g - 30 - hh, 66, hh + 30), Paint()..color = Color.lerp(const Color(0xFFE3D8C6), const Color(0xFFC3CBD2), rnd.nextDouble())!);
    }
    // The pole, its cross-arm and the overhead line.
    const px = M6UgGeo.poleX;
    final top = geo.cableTop.dy - 40;
    final pole = Rect.fromLTRB(px, top - 10, px + 16, g + 4);
    c.drawRect(pole, Paint()..shader = const LinearGradient(colors: [Color(0xFFC3C7CB), Color(0xFF8E9399)]).createShader(pole));
    c.drawRect(Rect.fromLTRB(px - 70, top, px + 86, top + 8), Paint()..color = const Color(0xFF6A6F75));
    final wire = Paint()
      ..color = const Color(0xFF2F343A)
      ..strokeWidth = 1.6;
    for (final x in [px - 56, px + 8, px + 72]) {
      c.drawRect(Rect.fromLTWH(x - 4, top - 14, 8, 14), Paint()..color = const Color(0xFF8E6A4A));
      c.drawLine(Offset(0, top - 16 + (x - px) * 0.02), Offset(w, top - 18 + (x - px) * 0.02), wire);
    }
    // The cable up the pole in clamps, to its open end.
    final ct = geo.cableTop;
    c.drawLine(Offset(ct.dx, g + 30), ct, Paint()
      ..strokeWidth = 10
      ..color = const Color(0xFF1D2025));
    for (var y = ct.dy + 30; y < g; y += 52) {
      c.drawRect(Rect.fromCenter(center: Offset(ct.dx + 6, y), width: 22, height: 5), Paint()..color = const Color(0xFF5A6067));
    }
    // Three bare cores splayed: no termination yet.
    for (final (dx, col) in const [(-9.0, Color(0xFFD32F2F)), (0.0, Color(0xFFFBC02D)), (9.0, Color(0xFF1976D2))]) {
      c.drawLine(ct, ct + Offset(dx, -18), Paint()
        ..strokeWidth = 3.4
        ..color = col);
    }
    // A tarp at the pole's foot with the kit box and the phone on it.
    final tarp = Rect.fromLTRB(geo.slot(0).left - 10, geo.slot(0).bottom - 8, geo.slot(1).right + 10, geo.slot(0).bottom + 10);
    c.drawRRect(RRect.fromRectAndRadius(tarp, const Radius.circular(4)), Paint()..color = const Color(0xFF2E6FA8));
    _kit(c, geo.slot(kitSlot));
    _phone(c, geo.slot(1 - kitSlot));
  }

  void _kit(Canvas c, Rect r) {
    final box = r.deflate(4);
    c.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(4)), Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFD7B47A), Color(0xFFB08850)]).createShader(box));
    c.drawLine(Offset(box.left, box.top + 12), Offset(box.right, box.top + 12), Paint()
      ..color = const Color(0x55000000)
      ..strokeWidth = 1.4);
    final tp = TextPainter(
      text: TextSpan(text: kitLabel, style: bangla(fontSize: 8.5, fontWeight: FontWeight.w800, color: const Color(0xFF3A2A16), height: 1.1)),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 2,
    )..layout(maxWidth: box.width - 6);
    tp.paint(c, Offset(box.center.dx - tp.width / 2, box.top + 16));
  }

  void _phone(Canvas c, Rect r) {
    final cloth = r.deflate(4);
    c.drawRRect(RRect.fromRectAndRadius(cloth, const Radius.circular(4)), Paint()..color = const Color(0xFF4F5A3C));
    final ph = Rect.fromCenter(center: cloth.center, width: 26, height: 40);
    c.drawRRect(RRect.fromRectAndRadius(ph, const Radius.circular(5)), Paint()..color = const Color(0xFF15181C));
    final screen = ph.deflate(3).translate(0, -2);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(screen.left, screen.top, screen.right, screen.bottom - 3), const Radius.circular(2)), Paint()..color = const Color(0xFF3B6E9A));
  }

  @override
  bool shouldRepaint(M6TermPainter old) => old.geo != geo || old.kitSlot != kitSlot || old.kitLabel != kitLabel || old.seed != seed;
}

/// The deadly moment: a fault flash at the unearthed armour, in colour over
/// the grey scene.
class M6FlashPainter extends CustomPainter {
  const M6FlashPainter({required this.at, required this.v});
  final List<Offset> at;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    for (final p in at) {
      final r = 16 + 70 * v;
      c.drawCircle(
        p,
        r,
        Paint()
          ..shader = RadialGradient(colors: [
            const Color(0xFFFFFFFF).withValues(alpha: 0.95 * (1 - v * 0.4)),
            const Color(0xFF9FD8FF).withValues(alpha: 0.7 * (1 - v * 0.5)),
            const Color(0x00448AFF),
          ]).createShader(Rect.fromCircle(center: p, radius: r)),
      );
      final bolt = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..color = const Color(0xFFE3F4FF).withValues(alpha: 1 - v * 0.5);
      for (var i = 0; i < 5; i++) {
        final a = i * 2 * math.pi / 5 + v;
        final path = Path()..moveTo(p.dx, p.dy);
        var q = p;
        for (var k = 1; k <= 3; k++) {
          q = p + Offset(math.cos(a + (k.isEven ? 0.3 : -0.3)), math.sin(a + (k.isEven ? 0.3 : -0.3))) * (k * 14.0 * (0.6 + v));
          path.lineTo(q.dx, q.dy);
        }
        c.drawPath(path, bolt);
      }
    }
  }

  @override
  bool shouldRepaint(M6FlashPainter old) => old.v != v || !listEquals(old.at, at);
}
