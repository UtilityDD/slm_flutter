import 'dart:math' as math;

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';

// The place for lesson 4.8 কাজ 2 "ডাল নামাও, লাইন বাঁচিয়ে" (m4_tree_cut): a
// drawn, layered roadside — the morning sky, a far tree line and village,
// paddy fields, the road with cones, the work area roped off with red-white
// tape; on the right the LT line on its dead-end pole (strain insulators, the
// earth set clamped on all three conductors with its leads down to the spike:
// the line is shut down, PTW and earth); on the left a big roadside tree whose
// heavy limb reaches out over the conductors, a side branch and small twigs
// on it, and the shoots of its crown. The trainee works from the tree (helmet,
// harness, his lanyard round the trunk); his ground mate holds the rope below.
// No text in the art, and nothing marks where a cut goes (no chalk ticks —
// audit 2026-11-11): only the kerfs of cuts already made are drawn.
//
// Design: 360 wide × the scene's height; the ground follows the bottom of the
// screen (a tall phone gets more sky).

/// What can be trimmed in the first station (the big limb is a target too —
/// cutting it first is the order slip).
enum M4TreeCutPiece { tipTwig, twigA, twigB, side, limb }

/// Where the trainee can stand for the big cut.
enum M4TreeCutSpot { below, out, beside }

/// The three cuts on the heavy limb (the lesson's 3-cut method).
enum M4TreeCutMark { collar, under, top }

/// The crown's shoots (the clearance check): two on the line side (one grows
/// towards the conductors — dealt), one on the far side.
enum M4TreeCutShoot { low, mid, back }

/// Where things stand (design px, 360 wide).
@immutable
class M4TreeCutGeo {
  const M4TreeCutGeo({required this.height, required this.groundY, required this.topY});

  factory M4TreeCutGeo.forScene(double h, double inset) {
    final g = h - 150 - inset;
    return M4TreeCutGeo(height: h, groundY: g, topY: (150 + (h - 560) * 0.1).clamp(150.0, 200.0));
  }

  /// The trunk's axis (left: the limb reaches right over the line).
  static const tx = 60.0;

  /// The dead-end pole of the line.
  static const px = 132.0;

  final double height;
  final double groundY;
  final double topY;

  double get horizonY => topY + (groundY - topY) * 0.42;

  /// Where the heavy limb leaves the trunk.
  double get limbY => topY + (groundY - topY) * 0.30;

  /// The conductors' height at the pole.
  double get lineY => limbY + 120;

  /// The trunk's half width at [y].
  double trunkHalf(double y) => 9 + 6 * ((y - topY) / (groundY - topY)).clamp(0.0, 1.0);

  /// The heavy limb's centre line (0 at the trunk → 1 at its tip): it rises a
  /// little, then droops out over the conductors.
  Offset limbAt(double k) {
    final b = Offset(tx + 6, limbY);
    final c = Offset(tx + 100, limbY - 26);
    final t = Offset(tx + 212, limbY + 46);
    final u = 1 - k;
    return b * (u * u) + c * (2 * k * u) + t * (k * k);
  }

  /// The limb's thickness at [k].
  static double limbW(double k) => 13 - 9.5 * k;

  /// The side branch (from the limb, up and out) and its tip.
  static const sideK = 0.55;
  Offset get sideBase => limbAt(sideK);
  Offset get sideTip => sideBase + const Offset(30, -64);

  /// The end of each trimmable piece (its leaves), and where it joins.
  Offset pieceEnd(M4TreeCutPiece p) => switch (p) {
        M4TreeCutPiece.tipTwig => limbAt(1) + const Offset(22, 30),
        M4TreeCutPiece.twigA => sideTip + const Offset(26, -14),
        M4TreeCutPiece.twigB => sideTip + const Offset(-16, -28),
        M4TreeCutPiece.side => Offset.lerp(sideBase, sideTip, 0.55)!,
        M4TreeCutPiece.limb => limbAt(0.42),
      };

  Offset pieceRoot(M4TreeCutPiece p) => switch (p) {
        M4TreeCutPiece.tipTwig => limbAt(0.97),
        M4TreeCutPiece.twigA || M4TreeCutPiece.twigB => sideTip,
        M4TreeCutPiece.side => sideBase,
        M4TreeCutPiece.limb => limbAt(0.08),
      };

  /// The tap area of [p] (around its leaves / its middle).
  Rect pieceRect(M4TreeCutPiece p) => switch (p) {
        M4TreeCutPiece.limb => Rect.fromCenter(center: limbAt(0.4), width: 54, height: 40),
        M4TreeCutPiece.side => Rect.fromCenter(center: pieceEnd(p), width: 40, height: 44),
        _ => Rect.fromCenter(center: Offset.lerp(pieceRoot(p), pieceEnd(p), 0.7)!, width: 46, height: 46),
      };

  /// The heavy limb as one tap area (the rope station).
  Rect get limbRect => Rect.fromPoints(limbAt(0.15), limbAt(0.9)).inflate(22);

  /// Where the rope is tied (outboard of the cuts) and the crotch it runs over.
  static const tieK = 0.62;
  Offset get tie => limbAt(tieK);
  Offset get crotch => Offset(tx + 2, limbY - 52);

  /// The cuts' places on the limb (the kerf runs across it).
  static double markK(M4TreeCutMark m) => switch (m) {
        M4TreeCutMark.collar => 0.06,
        M4TreeCutMark.under => 0.2,
        M4TreeCutMark.top => 0.32,
      };

  Offset markAt(M4TreeCutMark m) {
    final k = markK(m);
    final p = limbAt(k);
    final w = limbW(k) / 2;
    return switch (m) {
      M4TreeCutMark.under => p.translate(0, w),
      M4TreeCutMark.top => p.translate(0, -w),
      M4TreeCutMark.collar => p,
    };
  }

  /// The tap area of a cut (the under cut is reached from below, the top
  /// cut from above).
  Rect markRect(M4TreeCutMark m) {
    final p = markAt(m);
    return switch (m) {
      M4TreeCutMark.under => Rect.fromCenter(center: p.translate(0, 12), width: 40, height: 40),
      M4TreeCutMark.top => Rect.fromCenter(center: p.translate(0, -12), width: 40, height: 40),
      M4TreeCutMark.collar => Rect.fromCenter(center: p, width: 40, height: 44),
    };
  }

  /// A shoot's base, and its tip ([toward]: growing at the conductors).
  Offset shootBase(M4TreeCutShoot s) => switch (s) {
        M4TreeCutShoot.low => Offset(tx + 8, limbY + 66),
        M4TreeCutShoot.mid => Offset(tx + 8, limbY + 32),
        M4TreeCutShoot.back => Offset(tx - 8, limbY - 14),
      };

  Offset shootTip(M4TreeCutShoot s, {required bool toward}) => switch (s) {
        M4TreeCutShoot.low => toward ? Offset(px - 12, lineY - 22) : Offset(tx + 22, limbY + 14),
        M4TreeCutShoot.mid => toward ? Offset(px + 2, lineY - 38) : Offset(tx + 30, limbY - 26),
        M4TreeCutShoot.back => Offset(tx - 44, limbY - 60),
      };

  Rect shootRect(M4TreeCutShoot s, {required bool toward}) =>
      Rect.fromCenter(center: Offset.lerp(shootBase(s), shootTip(s, toward: toward), 0.7)!, width: 46, height: 42);

  /// The trainee's figure size (design px).
  static const figH = 80.0;
  static const figW = 40.0;

  /// His box at [s] (all face right).
  Rect spotBox(M4TreeCutSpot s) => switch (s) {
        M4TreeCutSpot.below => Rect.fromLTWH(tx + 4, limbY + 14, figW, figH),
        M4TreeCutSpot.out => Rect.fromLTWH(limbAt(0.46).dx - figW / 2, limbAt(0.46).dy - figH + 6, figW, figH),
        M4TreeCutSpot.beside => Rect.fromLTWH(tx - 10 - figW, limbY - 74, figW, figH),
      };

  /// The ring the player taps for [s] (on the figure's chest).
  Rect spotRect(M4TreeCutSpot s) {
    final b = spotBox(s);
    return Rect.fromCenter(center: Offset(b.center.dx, b.top + figH * 0.38), width: 46, height: 46);
  }

  /// The ground mate (on the ground left of the trunk, the rope's tail).
  Rect get mateBox => Rect.fromLTWH(2, groundY - 70, 36, 72);
  Offset get mateHands => Offset(mateBox.center.dx + 8, mateBox.top + 34);

  /// Where the lowered limb comes to rest (hanging from the rope by the
  /// trunk, its end on the ground, clear of the line).
  Offset get restTie => Offset(tx + 40, groundY - 96);

  @override
  bool operator ==(Object other) => other is M4TreeCutGeo && other.height == height && other.groundY == groundY && other.topY == topY;

  @override
  int get hashCode => Object.hash(height, groundY, topY);
}

/// What the tree shows.
@immutable
class M4TreeCutTree {
  const M4TreeCutTree({
    required this.present,
    this.gone = const {},
    this.roped = false,
    this.cuts = const {},
    this.lower = 0,
    this.toward = M4TreeCutShoot.low,
    this.shootCut = false,
  });

  /// The trimmable pieces dealt this play (twigs and the side branch).
  final Set<M4TreeCutPiece> present;

  /// Those already cut.
  final Set<M4TreeCutPiece> gone;
  final bool roped;

  /// The cuts made on the heavy limb.
  final Set<M4TreeCutMark> cuts;

  /// The freed limb on the rope: 0 just cut free → 1 down on the ground.
  final double lower;

  /// The shoot that grows at the conductors.
  final M4TreeCutShoot toward;
  final bool shootCut;

  bool get freed => cuts.contains(M4TreeCutMark.top) && cuts.contains(M4TreeCutMark.under);

  @override
  bool operator ==(Object other) =>
      other is M4TreeCutTree &&
      setEquals(other.present, present) &&
      setEquals(other.gone, gone) &&
      other.roped == roped &&
      setEquals(other.cuts, cuts) &&
      other.lower == lower &&
      other.toward == toward &&
      other.shootCut == shootCut;

  @override
  int get hashCode => Object.hash(Object.hashAllUnordered(present), Object.hashAllUnordered(gone), roped, Object.hashAllUnordered(cuts), lower, toward, shootCut);
}

Path _span(Offset p, Offset q, double sag) {
  final path = Path()..moveTo(p.dx, p.dy);
  const n = 22;
  for (var j = 1; j <= n; j++) {
    final k = j / n;
    final pt = Offset.lerp(p, q, k)!;
    path.lineTo(pt.dx, pt.dy + sag * 4 * k * (1 - k));
  }
  return path;
}

const _bark = Color(0xFF6B4A2E);
const _barkLight = Color(0xFF8C6640);
const _leaf = Color(0xFF3F7A3A);
const _leafLight = Color(0xFF5E9B4C);

void _leaves(Canvas c, Offset at, double r, {int seed = 0}) {
  final dark = Paint()..color = _leaf;
  final light = Paint()..color = _leafLight;
  for (var i = 0; i < 6; i++) {
    final a = seed * 1.7 + i * math.pi / 3;
    final o = at + Offset(math.cos(a), math.sin(a)) * r * 0.55;
    c.drawCircle(o, r * 0.55, i.isEven ? dark : light);
  }
  c.drawCircle(at, r * 0.6, light);
}

/// A tapering branch from [a] to [b] (width [w0] → [w1]).
void _branch(Canvas c, Offset a, Offset b, double w0, double w1, {Offset? bend}) {
  final mid = bend ?? Offset.lerp(a, b, 0.5)!;
  final n = (b - a) / math.max(1, (b - a).distance);
  final perp = Offset(-n.dy, n.dx);
  final path = Path()
    ..moveTo(a.dx + perp.dx * w0 / 2, a.dy + perp.dy * w0 / 2)
    ..quadraticBezierTo(mid.dx + perp.dx * (w0 + w1) / 4, mid.dy + perp.dy * (w0 + w1) / 4, b.dx + perp.dx * w1 / 2, b.dy + perp.dy * w1 / 2)
    ..lineTo(b.dx - perp.dx * w1 / 2, b.dy - perp.dy * w1 / 2)
    ..quadraticBezierTo(mid.dx - perp.dx * (w0 + w1) / 4, mid.dy - perp.dy * (w0 + w1) / 4, a.dx - perp.dx * w0 / 2, a.dy - perp.dy * w0 / 2)
    ..close();
  c.drawPath(path, Paint()..color = _bark);
}

/// The heavy limb from [k0] to [k1], drawn through [tf] (identity on the
/// tree; the freed piece is moved and turned).
void _limb(Canvas c, M4TreeCutGeo geo, double k0, double k1, {Offset Function(Offset)? tf, bool leaves = true}) {
  Offset f(Offset p) => tf == null ? p : tf(p);
  const n = 18;
  final top = <Offset>[];
  final bot = <Offset>[];
  for (var j = 0; j <= n; j++) {
    final k = k0 + (k1 - k0) * j / n;
    final p = geo.limbAt(k);
    final q = geo.limbAt(math.min(1, k + 0.01));
    final d = q - geo.limbAt(math.max(0, k - 0.01));
    final u = d / math.max(0.001, d.distance);
    final perp = Offset(u.dy, -u.dx);
    final w = M4TreeCutGeo.limbW(k) / 2;
    top.add(f(p + perp * w));
    bot.add(f(p - perp * w));
  }
  final path = Path()..moveTo(top.first.dx, top.first.dy);
  for (final p in top.skip(1)) {
    path.lineTo(p.dx, p.dy);
  }
  for (final p in bot.reversed) {
    path.lineTo(p.dx, p.dy);
  }
  path.close();
  c.drawPath(path, Paint()..color = _bark);
  final hl = Path()..moveTo(top.first.dx, top.first.dy);
  for (final p in top.skip(1)) {
    hl.lineTo(p.dx, p.dy);
  }
  c.drawPath(
      hl,
      Paint()
        ..color = _barkLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4);
  if (leaves && k1 >= 1) {
    _leaves(c, f(geo.limbAt(0.78)).translate(0, -6), 13, seed: 2);
    _leaves(c, f(geo.limbAt(0.92)).translate(0, -2), 11, seed: 5);
  }
}

/// The place: sky, land, the line on its dead-end pole with the earth set,
/// the tree with its limb, branches and shoots, the rope, the freed limb.
class M4TreeCutWorldPainter extends CustomPainter {
  const M4TreeCutWorldPainter({required this.geo, required this.tree});
  final M4TreeCutGeo geo;
  final M4TreeCutTree tree;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final hz = geo.horizonY;
    final g = geo.groundY;

    // --- sky -------------------------------------------------------------------
    final sky = Rect.fromLTWH(0, 0, w, hz + 6);
    c.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5C9BD1), Color(0xFF9FC7E6), Color(0xFFEFE6CC)],
          stops: [0, 0.6, 1],
        ).createShader(sky),
    );
    final sun = Offset(w * 0.78, hz * 0.32);
    c.drawCircle(
        sun,
        100,
        Paint()
          ..shader = const RadialGradient(colors: [Color(0x80FFF4D2), Color(0x00FFF4D2)]).createShader(Rect.fromCircle(center: sun, radius: 100)));
    c.drawCircle(sun, 14, Paint()..color = const Color(0xFFFFF6DC));
    final cloud = Paint()..color = const Color(0xCCFFFFFF);
    for (final (x, y, r) in [(250.0, hz * 0.5, 16.0), (180.0, hz * 0.2, 20.0), (320.0, hz * 0.66, 12.0)]) {
      c.drawCircle(Offset(x, y), r, cloud);
      c.drawCircle(Offset(x + r, y + 4), r * 0.8, cloud);
      c.drawCircle(Offset(x - r, y + 5), r * 0.7, cloud);
    }

    // --- far land --------------------------------------------------------------
    final far = Path()..moveTo(0, hz);
    for (var x = 0.0; x <= w + 16; x += 16) {
      final bump = 13 + 8 * math.sin(x * 0.05 + 2) + 5 * math.sin(x * 0.17 + 0.4);
      far.quadraticBezierTo(x + 8, hz - bump - 9, x + 16, hz - bump * 0.6);
    }
    far
      ..lineTo(w, hz + 4)
      ..lineTo(0, hz + 4)
      ..close();
    c.drawPath(far, Paint()..color = const Color(0xFF4F7A55));
    for (final (x, sz) in const [(208.0, 1.0), (240.0, 0.8), (300.0, 0.9)]) {
      final b = Rect.fromLTWH(x, hz - 12 * sz, 24 * sz, 12 * sz);
      c.drawRect(b, Paint()..color = const Color(0xFFB59A74));
      c.drawPath(
          Path()
            ..moveTo(x - 3 * sz, hz - 11 * sz)
            ..lineTo(x + 12 * sz, hz - 20 * sz)
            ..lineTo(x + 27 * sz, hz - 11 * sz)
            ..close(),
          Paint()..color = const Color(0xFF8E979E));
    }
    final field = Rect.fromLTRB(0, hz, w, g + 10);
    c.drawRect(
      field,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8DB860), Color(0xFF6E9E45)],
        ).createShader(field),
    );
    final row = Paint()
      ..color = const Color(0x335A7F2E)
      ..strokeWidth = 1.2;
    for (var i = 1; i < 7; i++) {
      final y = hz + (g - hz) * (i / 7) * (i / 7) * 0.9;
      c.drawLine(Offset(0, y), Offset(w, y), row);
    }

    // --- the verge and the road -----------------------------------------------
    final verge = Rect.fromLTRB(0, g - 22, w, g + 28);
    c.drawRect(
      verge,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5E8E3A), Color(0xFF7A6A48)],
        ).createShader(verge),
    );
    final road = Rect.fromLTRB(0, g + 28, w, size.height);
    c.drawRect(
      road,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8A7B62), Color(0xFF6E624E)],
        ).createShader(road),
    );
    final tuft = Paint()
      ..color = const Color(0xFF4C7A2C)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (var x = 6.0; x < w; x += 19) {
      for (final k in const [-3.0, 0.0, 3.0]) {
        c.drawLine(Offset(x + k, g + 4), Offset(x + k + 3, g - 8 - (k == 0 ? 3 : 0)), tuft);
      }
    }
    // The work area roped off (red-white tape on posts) and cones on the road.
    _cordon(c);
    for (final x in const [96.0, 236.0]) {
      final base = Offset(x, g + 44);
      c.drawPath(
          Path()
            ..moveTo(base.dx - 9, base.dy)
            ..lineTo(base.dx - 2, base.dy - 24)
            ..lineTo(base.dx + 2, base.dy - 24)
            ..lineTo(base.dx + 9, base.dy)
            ..close(),
          Paint()..color = const Color(0xFFF07C1E));
      c.drawRect(Rect.fromLTWH(base.dx - 6, base.dy - 14, 12, 4), Paint()..color = const Color(0xFFF5F5F0));
      c.drawRect(Rect.fromLTWH(base.dx - 12, base.dy - 1, 24, 3), Paint()..color = const Color(0xFF3A3A3A));
    }

    // --- the line: the dead-end pole, conductors, earth set ---------------
    _line(c, w);

    // --- the tree -----------------------------------------------------------------
    _tree(c);
  }

  void _cordon(Canvas c) {
    final g = geo.groundY;
    final post = Paint()..color = const Color(0xFF5A4A3A);
    const xs = [16.0, 176.0, 300.0];
    for (final x in xs) {
      c.drawRect(Rect.fromLTWH(x - 1.5, g - 26, 3, 30), post);
    }
    for (var i = 0; i < xs.length - 1; i++) {
      final a = Offset(xs[i], g - 22);
      final b = Offset(xs[i + 1], g - 22);
      const seg = 10.0;
      final len = (b - a).distance;
      for (var s = 0.0; s < len; s += seg) {
        final p = Offset.lerp(a, b, s / len)!;
        final q = Offset.lerp(a, b, math.min(1, (s + seg) / len))!;
        c.drawLine(
            p.translate(0, 2 * math.sin(s / len * math.pi)),
            q.translate(0, 2 * math.sin(math.min(1, (s + seg) / len) * math.pi)),
            Paint()
              ..color = (s ~/ seg).isEven ? const Color(0xFFD63A2F) : const Color(0xFFF7F3EA)
              ..strokeWidth = 2.6);
      }
    }
  }

  void _line(Canvas c, double w) {
    const px = M4TreeCutGeo.px;
    final g = geo.groundY;
    final top = geo.lineY - 26;
    final body = Path()
      ..moveTo(px - 7, g + 6)
      ..lineTo(px - 4.5, top)
      ..lineTo(px + 4.5, top)
      ..lineTo(px + 7, g + 6)
      ..close();
    c.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFF9C988E), Color(0xFFCBC7BC), Color(0xFF8E8A80)], stops: [0, 0.45, 1])
            .createShader(Rect.fromLTRB(px - 7, top, px + 7, g)),
    );
    // The cross-arm and three strain strings out to the right.
    final armY = geo.lineY - 18;
    c.drawRect(Rect.fromLTRB(px - 16, armY - 3, px + 26, armY + 3), Paint()..color = const Color(0xFF6E757B));
    final ends = <Offset>[];
    for (var i = 0; i < 3; i++) {
      final x0 = px - 10 + i * 16.0;
      final clamp = Offset(x0 + 20, armY + 8 + i * 5);
      final disc = Paint()..color = const Color(0xFF7B4526);
      for (var j = 0; j < 3; j++) {
        final cx = x0 + 4 + j * 5.0;
        final cy = armY + 3 + (clamp.dy - armY - 3) * (j / 3);
        c.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 4, height: 10), disc);
      }
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: clamp, width: 7, height: 5), const Radius.circular(2)), Paint()..color = const Color(0xFF8A9096));
      ends.add(clamp);
    }
    final wire = Paint()
      ..color = const Color(0xFF2E3338)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 3; i++) {
      final e = ends[i];
      c.drawPath(_span(e, Offset(w + 30, e.dy - 6), 30), wire);
    }
    // The earth set: a clamp on each conductor, leads down the pole to the spike.
    final lead = Paint()
      ..color = const Color(0xFFB87333)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final join = Offset(px + 4, armY + 40);
    for (var i = 0; i < 3; i++) {
      final at = ends[i].translate(9, 2);
      c.drawPath(
          Path()
            ..moveTo(at.dx, at.dy)
            ..quadraticBezierTo((at.dx + join.dx) / 2 + 4, join.dy - 4, join.dx, join.dy),
          lead);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: at, width: 7, height: 6), const Radius.circular(2)), Paint()..color = const Color(0xFF2E9A44));
      c.drawRect(Rect.fromCenter(center: at.translate(0, 1), width: 7, height: 2), Paint()..color = const Color(0xFFF4D03F));
    }
    final spike = Offset(px + 22, g + 12);
    c.drawPath(
        Path()
          ..moveTo(join.dx, join.dy)
          ..quadraticBezierTo(join.dx + 6, (join.dy + spike.dy) / 2, spike.dx, spike.dy - 10),
        lead..strokeWidth = 2);
    c.drawRect(Rect.fromLTWH(spike.dx - 1.5, spike.dy - 12, 3, 16), Paint()..color = const Color(0xFF6B7076));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: spike.translate(0, -10), width: 8, height: 6), const Radius.circular(2)),
        Paint()..color = const Color(0xFF2E9A44));
  }

  void _tree(Canvas c) {
    const tx = M4TreeCutGeo.tx;
    final g = geo.groundY;
    final top = geo.topY;
    // The crown behind (the tree's own foliage, away from the line).
    for (final (dx, dy, r) in const [(-30.0, 30.0, 40.0), (6.0, 6.0, 46.0), (-52.0, 70.0, 30.0), (30.0, 40.0, 30.0)]) {
      _leaves(c, Offset(tx + dx, top + dy), r, seed: dx.toInt());
    }
    // The trunk.
    final body = Path()
      ..moveTo(tx - geo.trunkHalf(g) - 4, g + 8)
      ..lineTo(tx - geo.trunkHalf(top), top + 20)
      ..lineTo(tx + geo.trunkHalf(top), top + 20)
      ..lineTo(tx + geo.trunkHalf(g) + 4, g + 8)
      ..close();
    c.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFF5A3D24), Color(0xFF8C6640), Color(0xFF5A3D24)], stops: [0, 0.4, 1])
            .createShader(Rect.fromLTRB(tx - 16, top, tx + 16, g)),
    );
    final ridge = Paint()
      ..color = const Color(0x553A2716)
      ..strokeWidth = 1.2;
    for (var y = top + 40; y < g; y += 26) {
      c.drawLine(Offset(tx - 4, y), Offset(tx - 1, y + 14), ridge);
      c.drawLine(Offset(tx + 5, y + 10), Offset(tx + 3, y + 22), ridge);
    }

    // The crown's shoots.
    for (final s in M4TreeCutShoot.values) {
      final toward = s == tree.toward;
      if (toward && tree.shootCut) {
        // The cut stub.
        _branch(c, geo.shootBase(s), Offset.lerp(geo.shootBase(s), geo.shootTip(s, toward: true), 0.12)!, 4.5, 3.5);
        continue;
      }
      final tip = geo.shootTip(s, toward: toward);
      _branch(c, geo.shootBase(s), tip, 5, 1.8);
      _leaves(c, tip, 10, seed: s.index + 3);
    }

    // The heavy limb: whole, or the stub once cut free (the collar cut
    // leaves a clean, short stub).
    final cuts = tree.cuts;
    final freed = tree.freed;
    if (!freed) {
      _limb(c, geo, 0, 1);
    } else {
      final end = cuts.contains(M4TreeCutMark.collar) ? M4TreeCutGeo.markK(M4TreeCutMark.collar) : M4TreeCutGeo.markK(M4TreeCutMark.under);
      _limb(c, geo, 0, end, leaves: false);
      final face = geo.limbAt(end);
      c.drawOval(Rect.fromCenter(center: face, width: 4, height: M4TreeCutGeo.limbW(end)), Paint()..color = const Color(0xFFE2C79A));
    }
    // Kerfs of the cuts made so far (before the limb is free).
    if (!freed && cuts.contains(M4TreeCutMark.under)) {
      final p = geo.markAt(M4TreeCutMark.under);
      c.drawLine(p, p.translate(0, -M4TreeCutGeo.limbW(M4TreeCutGeo.markK(M4TreeCutMark.under)) * 0.4), Paint()
        ..color = const Color(0xFFF2DDB4)
        ..strokeWidth = 2.2);
    }

    // The side branch and the twigs (before the limb is free).
    if (!freed) {
      if (tree.present.contains(M4TreeCutPiece.side) && !tree.gone.contains(M4TreeCutPiece.side)) {
        _branch(c, geo.sideBase, geo.sideTip, 6, 3.2);
        for (final t in const [M4TreeCutPiece.twigA, M4TreeCutPiece.twigB]) {
          if (tree.present.contains(t) && !tree.gone.contains(t)) {
            _branch(c, geo.pieceRoot(t), geo.pieceEnd(t), 2.6, 1.2);
            _leaves(c, geo.pieceEnd(t), 10, seed: t.index);
          }
        }
        _leaves(c, geo.sideTip, 9, seed: 7);
      } else if (tree.present.contains(M4TreeCutPiece.side)) {
        final s = geo.sideBase;
        c.drawOval(Rect.fromCenter(center: s.translate(2, -3), width: 5, height: 4), Paint()..color = const Color(0xFFE2C79A));
      }
      if (tree.present.contains(M4TreeCutPiece.tipTwig) && !tree.gone.contains(M4TreeCutPiece.tipTwig)) {
        const t = M4TreeCutPiece.tipTwig;
        _branch(c, geo.pieceRoot(t), geo.pieceEnd(t), 3, 1.2);
        _leaves(c, geo.pieceEnd(t), 11, seed: 9);
      }
    }

    // The rope: tied on the limb outboard of the cuts, over the crotch, down to
    // the ground mate's hands.
    if (tree.roped) {
      final tie = freed ? _freedTf(geo.tie) : geo.tie;
      final rope = Paint()
        ..color = const Color(0xFFE0C068)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      final cr = geo.crotch;
      c.drawPath(
          Path()
            ..moveTo(tie.dx, tie.dy)
            ..quadraticBezierTo((tie.dx + cr.dx) / 2, math.min(tie.dy, cr.dy) - (freed ? 0 : 10), cr.dx, cr.dy)
            ..quadraticBezierTo(cr.dx - 14, (cr.dy + geo.mateHands.dy) / 2, geo.mateHands.dx, geo.mateHands.dy),
          rope);
      c.drawCircle(cr, 3, Paint()..color = const Color(0xFFB0903A));
      c.drawCircle(tie, 3.2, Paint()..color = const Color(0xFFB0903A));
    }

    // The freed limb, on the rope: it swings in to the trunk, clear of the
    // line, then goes down to the ground.
    if (freed) {
      _limb(c, geo, M4TreeCutGeo.markK(M4TreeCutMark.top), 1, tf: _freedTf);
    }
  }

  /// The freed limb's move: turn about the tie point (tip down) while the
  /// tie swings in to the trunk, then down to the ground.
  Offset _freedTf(Offset p) {
    final l = tree.lower.clamp(0.0, 1.0);
    final swing = Curves.easeOut.transform((l / 0.4).clamp(0.0, 1.0));
    final drop = Curves.easeInOut.transform(((l - 0.4) / 0.6).clamp(0.0, 1.0));
    final a = 1.35 * swing;
    final tie0 = geo.tie;
    final hang = Offset(geo.restTie.dx, geo.limbY + 6);
    final tie = Offset.lerp(tie0, hang, swing)! + Offset(0, (geo.restTie.dy - hang.dy) * drop);
    final r = p - tie0;
    final ca = math.cos(a);
    final sa = math.sin(a);
    return tie + Offset(r.dx * ca - r.dy * sa, r.dx * sa + r.dy * ca);
  }

  @override
  bool shouldRepaint(M4TreeCutWorldPainter old) => old.geo != geo || old.tree != tree;
}

/// His lanyard round the trunk (as the pole strap in Module 2).
class M4TreeCutStrapPainter extends CustomPainter {
  const M4TreeCutStrapPainter({required this.box, required this.geo});
  final Rect box;
  final M4TreeCutGeo geo;

  @override
  void paint(Canvas c, Size size) {
    final hip = Offset(box.left + box.width * 0.5, box.top + box.height * 0.5);
    final strap = Paint()
      ..color = const Color(0xFF3A2A16)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;
    const tx = M4TreeCutGeo.tx;
    final half = geo.trunkHalf(hip.dy) + 1;
    final right = hip.dx > tx;
    final far = right ? tx - half : tx + half;
    if ((hip.dx - tx).abs() < 70) {
      c.drawPath(
          Path()
            ..moveTo(hip.dx, hip.dy)
            ..quadraticBezierTo(tx, hip.dy - 9, far, hip.dy - 5)
            ..moveTo(hip.dx, hip.dy + 2)
            ..quadraticBezierTo(tx, hip.dy + 4, far, hip.dy - 5),
          strap);
    }
  }

  @override
  bool shouldRepaint(M4TreeCutStrapPainter old) => old.box != box || old.geo != geo;
}

/// A cut piece dropping into the roped-off area ([v] 0 → 1).
class M4TreeCutDropPainter extends CustomPainter {
  M4TreeCutDropPainter({required this.from, required this.to, required this.v, required this.big});
  final Offset from;
  final Offset to;
  final double v;
  final bool big;

  @override
  void paint(Canvas c, Size size) {
    final k = Curves.easeIn.transform(v.clamp(0.0, 1.0));
    final p = Offset.lerp(from, to, k)!;
    c.save();
    c.translate(p.dx, p.dy);
    c.rotate(k * 2.4);
    final len = big ? 30.0 : 18.0;
    c.drawLine(Offset(-len / 2, 0), Offset(len / 2, 0), Paint()
      ..color = _bark
      ..strokeWidth = big ? 4 : 2.4
      ..strokeCap = StrokeCap.round);
    _leaves(c, Offset(len / 2, 0), big ? 10 : 7);
    c.restore();
  }

  @override
  bool shouldRepaint(M4TreeCutDropPainter old) => old.v != v || old.from != from || old.to != to;
}

/// The fall (in colour over the frozen grey scene): the heavy limb comes
/// off and drops along its fall line onto the spot where he stands.
/// Non-graphic: a streak, the falling limb, a white burst.
class M4TreeCutFallPainter extends CustomPainter {
  M4TreeCutFallPainter({required this.geo, required this.at, required this.v});
  final M4TreeCutGeo geo;
  final Offset at;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final from = geo.limbAt(0.45);
    final k = Curves.easeIn.transform(v.clamp(0.0, 1.0));
    final pos = Offset.lerp(from, at, k)!;
    c.drawLine(
        from,
        at,
        Paint()
          ..color = const Color(0x88E74C3C)
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round);
    c.save();
    c.translate(pos.dx, pos.dy);
    c.rotate(0.9 * k);
    c.drawLine(const Offset(-44, 0), const Offset(44, 0), Paint()
      ..color = _bark
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round);
    _leaves(c, const Offset(44, -4), 12);
    c.restore();
    if (k > 0.9) {
      final burst = Paint()
        ..color = const Color(0xEEFFFFFF)
        ..strokeWidth = 3;
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4;
        c.drawLine(at, at + Offset(math.cos(a), math.sin(a)) * 26, burst);
      }
      c.drawCircle(at, 12, Paint()..color = const Color(0xFFFFFFFF));
    }
  }

  @override
  bool shouldRepaint(M4TreeCutFallPainter old) => old.v != v || old.at != at || old.geo != geo;
}
