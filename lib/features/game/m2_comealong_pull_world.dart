import 'dart:math' as math;

import 'package:flutter/material.dart';

// The pole top for lesson 2.4 কাজ 2 "নিয়ন্ত্রিত টান" (m2_comealong_pull): a
// drawn, layered place — the morning sky, a far tree line and village, paddy
// fields, the next pole down the line, and close up the dead-end PCC pole: its
// steel cross-arm, three strain insulator strings, three conductors running to
// the far pole (two at the right sag, one sagging low), the earth set clamped
// on all three conductors with its leads down to the earth spike (the line is
// dead: shutdown, PTW and earth before the work), the come-along with its
// handle, cable and hook, and the wire grip on the slack conductor.
// No text in the art.
//
// Design: 360 wide × the scene's height; the ground follows the bottom of the
// screen (a tall phone gets more sky).

/// Where the come-along's fixed end can go (the scene's tap targets).
enum PullAnchor { sling, armBase, insulator, armTip, bracket }

/// Where the trainee can stand to work the handle.
enum PullSpot { front, behind, side }

/// Where things stand (design px, 360 wide).
@immutable
class PullGeo {
  const PullGeo({required this.height, required this.groundY, required this.topY});

  factory PullGeo.forScene(double h, double inset) {
    final g = h - 150 - inset;
    return PullGeo(height: h, groundY: g, topY: (150 + (h - 560) * 0.1).clamp(150.0, 200.0));
  }

  /// The pole's axis (right of centre: the span runs off to the left).
  static const px = 262.0;

  /// The far pole down the line.
  static const farX = 40.0;

  final double height;
  final double groundY;
  final double topY;

  double get armY => topY + 26;
  double get horizonY => topY + (groundY - topY) * 0.42;

  /// Where the cross-arm ends (left: the span side).
  double get armLeft => px - 146;
  double get armRight => px + 40;

  /// The strain strings hang from the arm here (inner = the slack phase).
  List<double> get phaseX => const [px - 34, px - 82, px - 128];

  /// The strain clamps at the strings' outer ends.
  List<Offset> get clamps => [for (final x in phaseX) Offset(x - 22, armY + 7)];

  double get farTop => horizonY - 96;
  double get farBase => horizonY + 26;
  List<Offset> get farPins => const [Offset(farX + 10, 0), Offset(farX, -6), Offset(farX - 10, 0)].map((o) => o.translate(0, farTop + 8)).toList();

  /// The line of pull's height (the come-along and the grip).
  double get lineY => armY + 34;

  /// The grip on the slack conductor at tension [t] (0 slack → 1 right sag).
  Offset grip(double t) => Offset(px - 120 + 22 * t, lineY + 2);

  /// The sag of the two good phases (design px at mid-span).
  static const okSag = 40.0;

  /// The slack phase's extra sag before the pull.
  static const slackExtra = 64.0;

  /// The slack phase's sag at tension [t] (t > 1: tighter than the others).
  static double sagAt(double t) => okSag + slackExtra * (1 - t);

  /// The come-along's fixed end for [a].
  Offset anchorPoint(PullAnchor a) => switch (a) {
        PullAnchor.sling => Offset(px - 9, lineY),
        PullAnchor.armBase => Offset(px - 12, armY + 6),
        PullAnchor.insulator => Offset(phaseX[0] - 10, armY + 6),
        PullAnchor.armTip => Offset(armLeft + 6, armY),
        PullAnchor.bracket => Offset(px + 14, armY + 70),
      };

  /// The tap area of [a].
  Rect anchorRect(PullAnchor a) => switch (a) {
        PullAnchor.sling => Rect.fromCenter(center: Offset(px, lineY), width: 40, height: 26),
        PullAnchor.armBase => Rect.fromCenter(center: Offset(px - 10, armY + 2), width: 30, height: 20),
        PullAnchor.insulator => Rect.fromCenter(center: Offset(phaseX[0] - 11, armY + 6), width: 26, height: 22),
        PullAnchor.armTip => Rect.fromCenter(center: Offset(armLeft + 8, armY), width: 30, height: 24),
        PullAnchor.bracket => Rect.fromCenter(center: Offset(px + 18, armY + 72), width: 30, height: 30),
      };

  /// Where the grip goes on (the slack conductor, out in the span).
  Rect get gripRect => Rect.fromCenter(center: grip(0), width: 50, height: 40);

  /// The hook dangling from the come-along before it is connected.
  Offset hookHang(PullAnchor a) {
    final p = anchorPoint(a);
    return Offset(p.dx - 44, p.dy + 26);
  }

  Rect hookRect(PullAnchor a) => Rect.fromCenter(center: hookHang(a), width: 40, height: 40);

  /// The camera: a close-up of the pole top (the scene is drawn in design
  /// px and seen through this zoom, [focus] landing on [focusView]).
  static const zoom = 1.5;
  Offset get focus => Offset(px - 60, lineY);
  Offset get focusView => Offset(170, height * 0.40);

  /// Design px → where it shows on the 360-wide scene.
  Offset view(Offset p) => focusView + (p - focus) * zoom;

  Matrix4 get camera {
    final t = focusView - focus * zoom;
    return Matrix4.translationValues(t.dx, t.dy, 0)..multiply(Matrix4.diagonal3Values(zoom, zoom, 1));
  }

  /// The trainee's figure size (design px).
  static const figH = 96.0;
  static const figW = 48.0;

  /// The trainee's box at [s] (facing the pole).
  Rect spotBox(PullSpot s) => switch (s) {
        PullSpot.front => Rect.fromLTWH(px - figW * 0.9 - 4, lineY - figH * 0.34, figW, figH),
        PullSpot.behind => Rect.fromLTWH(px + 4, lineY - figH * 0.34, figW, figH),
        PullSpot.side => Rect.fromLTWH(px - figW * 0.9 - 2, lineY + figH * 0.16, figW, figH),
      };

  /// The ring the player taps for [s] (on the figure's chest).
  Rect spotRect(PullSpot s) {
    final b = spotBox(s);
    return Rect.fromCenter(center: Offset(b.center.dx, b.top + figH * 0.36), width: 46, height: 46);
  }

  /// Where he stands while rigging (on his step, by the pole, below the arm).
  Rect get rigBox => spotBox(PullSpot.side);

  @override
  bool operator ==(Object other) => other is PullGeo && other.height == height && other.groundY == groundY && other.topY == topY;

  @override
  int get hashCode => Object.hash(height, groundY, topY);
}

/// What the rig shows.
@immutable
class PullRig {
  const PullRig({
    this.anchor,
    this.grip = false,
    this.hooked = false,
    this.tension = 0,
    this.clamped = false,
    this.slackOut = 0,
    this.removed = false,
  });

  /// Where the come-along is anchored (null: still on his tool belt).
  final PullAnchor? anchor;
  final bool grip;
  final bool hooked;

  /// 0 slack → 1 the right sag (more: too tight).
  final double tension;

  /// The conductor is fixed in its strain clamp (the load can come off).
  final bool clamped;

  /// How far the load is let off (0 → 1).
  final double slackOut;

  /// The come-along and grip are off the line.
  final bool removed;

  @override
  bool operator ==(Object other) =>
      other is PullRig &&
      other.anchor == anchor &&
      other.grip == grip &&
      other.hooked == hooked &&
      other.tension == tension &&
      other.clamped == clamped &&
      other.slackOut == slackOut &&
      other.removed == removed;

  @override
  int get hashCode => Object.hash(anchor, grip, hooked, tension, clamped, slackOut, removed);
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

/// The place: sky, land, the far pole, the dead-end pole, the conductors,
/// the earth set and the rig.
class PullWorldPainter extends CustomPainter {
  const PullWorldPainter({required this.geo, required this.rig});
  final PullGeo geo;
  final PullRig rig;

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
    final sun = Offset(w * 0.18, hz * 0.3);
    c.drawCircle(
        sun,
        100,
        Paint()
          ..shader = const RadialGradient(colors: [Color(0x80FFF4D2), Color(0x00FFF4D2)]).createShader(Rect.fromCircle(center: sun, radius: 100)));
    c.drawCircle(sun, 14, Paint()..color = const Color(0xFFFFF6DC));
    final cloud = Paint()..color = const Color(0xCCFFFFFF);
    for (final (x, y, r) in [(70.0, hz * 0.5, 16.0), (300.0, hz * 0.22, 20.0), (190.0, hz * 0.62, 12.0)]) {
      c.drawCircle(Offset(x, y), r, cloud);
      c.drawCircle(Offset(x + r, y + 4), r * 0.8, cloud);
      c.drawCircle(Offset(x - r, y + 5), r * 0.7, cloud);
    }

    // --- far land --------------------------------------------------------------
    final tree = Path()..moveTo(0, hz);
    for (var x = 0.0; x <= w + 16; x += 16) {
      final bump = 13 + 8 * math.sin(x * 0.05) + 5 * math.sin(x * 0.17 + 1.1);
      tree.quadraticBezierTo(x + 8, hz - bump - 9, x + 16, hz - bump * 0.6);
    }
    tree
      ..lineTo(w, hz + 4)
      ..lineTo(0, hz + 4)
      ..close();
    c.drawPath(tree, Paint()..color = const Color(0xFF4F7A55));
    for (final (x, sz) in const [(96.0, 1.0), (128.0, 0.8), (322.0, 0.9)]) {
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

    // --- the far pole ----------------------------------------------------------
    const fx = PullGeo.farX;
    c.drawPath(
        Path()
          ..moveTo(fx - 3, geo.farBase)
          ..lineTo(fx - 2, geo.farTop)
          ..lineTo(fx + 2, geo.farTop)
          ..lineTo(fx + 3, geo.farBase)
          ..close(),
        Paint()..color = const Color(0xFF9B9890));
    c.drawRect(Rect.fromLTWH(fx - 16, geo.farTop + 8, 32, 3), Paint()..color = const Color(0xFF70757A));
    for (final p in geo.farPins) {
      c.drawRect(Rect.fromCenter(center: p.translate(0, -2), width: 3.5, height: 5), Paint()..color = const Color(0xFF7A4A2A));
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
    // Cones round the work site.
    for (final x in const [150.0, 330.0]) {
      final base = Offset(x, g + 40);
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

    // --- the pole ---------------------------------------------------------------
    _pole(c);

    // --- the conductors -------------------------------------------------------
    final wire = Paint()
      ..color = const Color(0xFF2E3338)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    final pins = geo.farPins;
    for (var i = 1; i < 3; i++) {
      c.drawPath(_span(pins[i], geo.clamps[i], PullGeo.okSag), wire);
    }
    // The slack phase: from the far pole to the grip (or to its clamp once
    // the rig is off), then its tail through the strain clamp.
    final clamp0 = geo.clamps[0];
    final t = rig.tension;
    final gp = geo.grip(rig.grip ? t : 0);
    final near = Paint()
      ..color = const Color(0xFF23282C)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;
    if (rig.removed) {
      c.drawPath(_span(pins[0], clamp0, PullGeo.sagAt(t)), near);
      // The tail past the clamp, tied back.
      c.drawPath(
          Path()
            ..moveTo(clamp0.dx, clamp0.dy)
            ..quadraticBezierTo(clamp0.dx + 6, clamp0.dy + 14, clamp0.dx + 14, clamp0.dy + 10),
          near);
    } else {
      c.drawPath(_span(pins[0], gp, PullGeo.sagAt(t)), near);
      // The loose tail from the grip back through the clamp.
      c.drawPath(
          Path()
            ..moveTo(gp.dx, gp.dy)
            ..quadraticBezierTo((gp.dx + clamp0.dx) / 2, gp.dy + 18 - 10 * t.clamp(0.0, 1.0), clamp0.dx, clamp0.dy),
          near);
    }

    // --- the strain insulator strings ------------------------------------------
    for (var i = 0; i < 3; i++) {
      _strain(c, geo.phaseX[i], geo.armY + 3, geo.clamps[i]);
    }

    // --- the earth set (the line is dead and earthed) -------------------------
    _earth(c);

    // --- the rig ------------------------------------------------------------------
    if (!rig.removed) _rig(c, gp);
  }

  void _pole(Canvas c) {
    const px = PullGeo.px;
    final g = geo.groundY;
    final top = geo.topY;
    const half0 = 14.0;
    const half1 = 8.5;
    final body = Path()
      ..moveTo(px - half0, g + 6)
      ..lineTo(px - half1, top)
      ..lineTo(px + half1, top)
      ..lineTo(px + half0, g + 6)
      ..close();
    c.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFF9C988E), Color(0xFFCBC7BC), Color(0xFF8E8A80)], stops: [0, 0.45, 1])
            .createShader(Rect.fromLTRB(px - half0, top, px + half0, g)),
    );
    // Step bolts.
    final bolt = Paint()..color = const Color(0xFF6B7076);
    var left = true;
    for (var y = g - 70; y > geo.armY + 60; y -= 38) {
      final k = (y - top) / (g - top);
      final half = half1 + (half0 - half1) * k;
      c.drawRect(Rect.fromLTWH(left ? px - half - 8 : px + half, y, 9, 2.6), bolt);
      left = !left;
    }
    // The danger plate's loose bracket (a weak spot).
    final by = geo.armY + 72;
    c.drawRect(Rect.fromLTWH(px + 8, by - 2, 14, 3), Paint()..color = const Color(0xFF7A6A55));
    c.drawRect(Rect.fromLTWH(px + 16, by, 3, 12), Paint()..color = const Color(0xFF7A6A55));
    c.drawRect(Rect.fromLTWH(px + 10, by + 10, 20, 15), Paint()..color = const Color(0xFFD9D4C2));
    c.drawRect(Rect.fromLTWH(px + 12, by + 12, 16, 3), Paint()..color = const Color(0xFFC0392B));
    // The cross-arm (steel channel) and its brace.
    final arm = Paint()..color = const Color(0xFF6E757B);
    c.drawRect(Rect.fromLTRB(geo.armLeft, geo.armY - 4, geo.armRight, geo.armY + 4), arm);
    c.drawRect(Rect.fromLTRB(geo.armLeft, geo.armY - 4, geo.armRight, geo.armY - 2.5), Paint()..color = const Color(0xFF9AA1A7));
    c.drawLine(
        Offset(px - 62, geo.armY + 3),
        Offset(px - 8, geo.armY + 44),
        Paint()
          ..color = arm.color
          ..strokeWidth = 3);
    // The clamp where the arm meets the pole.
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(px, geo.armY), width: 24, height: 14), const Radius.circular(2)),
        Paint()..color = const Color(0xFF555C62));
    for (final dx in const [-7.0, 7.0]) {
      c.drawCircle(Offset(px + dx, geo.armY), 1.8, Paint()..color = const Color(0xFFB8BEC4));
    }
  }

  void _strain(Canvas c, double x, double y, Offset clamp) {
    // A shackle down from the arm, then the disc string out to the clamp.
    final metal = Paint()
      ..color = const Color(0xFF5A6066)
      ..strokeWidth = 2;
    c.drawLine(Offset(x, y), Offset(x - 3, y + 4), metal);
    final disc = Paint()..color = const Color(0xFF7B4526);
    final shine = Paint()..color = const Color(0xFFA8714A);
    for (var i = 0; i < 3; i++) {
      final cx = x - 6 - i * 5.0;
      final cy = y + 4 + (clamp.dy - y - 4) * (i / 3);
      c.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 4.4, height: 12), disc);
      c.drawOval(Rect.fromCenter(center: Offset(cx + 0.8, cy - 2), width: 1.4, height: 5), shine);
    }
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: clamp, width: 9, height: 6), const Radius.circular(2)), Paint()..color = const Color(0xFF8A9096));
  }

  void _earth(Canvas c) {
    // A clamp on each conductor by its strain clamp; braided leads join and
    // run down the pole to the spike in the ground.
    final spike = Offset(PullGeo.px - 46, geo.groundY + 14);
    final lead = Paint()
      ..color = const Color(0xFFB87333)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final join = Offset(PullGeo.px - 22, geo.armY + 70);
    for (var i = 0; i < 3; i++) {
      final at = geo.clamps[i].translate(4, i == 0 ? 6 : 4);
      c.drawPath(
          Path()
            ..moveTo(at.dx, at.dy)
            ..quadraticBezierTo((at.dx + join.dx) / 2, join.dy + 12, join.dx, join.dy),
          lead);
      // The earth clamp (green-yellow jaw).
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: at, width: 8, height: 7), const Radius.circular(2)), Paint()..color = const Color(0xFF2E9A44));
      c.drawRect(Rect.fromCenter(center: at.translate(0, 1), width: 8, height: 2), Paint()..color = const Color(0xFFF4D03F));
    }
    c.drawPath(
        Path()
          ..moveTo(join.dx, join.dy)
          ..quadraticBezierTo(join.dx - 14, (join.dy + spike.dy) / 2, spike.dx, spike.dy - 10),
        lead..strokeWidth = 2.2);
    // The spike and its clamp.
    c.drawRect(Rect.fromLTWH(spike.dx - 1.5, spike.dy - 12, 3, 16), Paint()..color = const Color(0xFF6B7076));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: spike.translate(0, -10), width: 9, height: 6), const Radius.circular(2)), Paint()..color = const Color(0xFF2E9A44));
  }

  void _rig(Canvas c, Offset gp) {
    final a = rig.anchor;
    // The wire grip on the conductor.
    if (rig.grip) _gripAt(c, gp);
    if (a == null) return;
    final p = geo.anchorPoint(a);
    // The sling / shackle at the anchor.
    final strap = Paint()
      ..color = const Color(0xFF2B5FA8)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    if (a == PullAnchor.sling) {
      c.drawLine(Offset(PullGeo.px - 10, p.dy - 4), Offset(PullGeo.px + 10, p.dy + 2), strap);
      c.drawLine(Offset(PullGeo.px - 10, p.dy + 4), Offset(PullGeo.px + 10, p.dy + 2), strap);
    }
    c.drawCircle(p, 3.2, Paint()..color = const Color(0xFF3C4248));
    // The come-along body (frame, drum, handle), just out from the anchor.
    final hookEnd = rig.hooked ? gp.translate(6, 0) : geo.hookHang(a);
    final dir = (hookEnd - p);
    final unit = dir / math.max(1, dir.distance);
    final body = p + unit * 18;
    final angle = math.atan2(unit.dy, unit.dx);
    c.save();
    c.translate(body.dx, body.dy);
    c.rotate(angle);
    final frame = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 26, height: 11), const Radius.circular(3));
    c.drawRRect(frame, Paint()..color = const Color(0xFFD1A414));
    c.drawRRect(
        frame,
        Paint()
          ..color = const Color(0xFF6B5208)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
    c.drawCircle(const Offset(2, 0), 4, Paint()..color = const Color(0xFF4A4F55));
    c.restore();
    // The handle hangs down from the body.
    final handle = Paint()
      ..color = const Color(0xFF3A3F45)
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round;
    c.drawLine(body, body + const Offset(-6, 24), handle);
    c.drawCircle(body + const Offset(-6, 24), 2.6, Paint()..color = const Color(0xFFC0392B));
    // The cable: taut when hooked, a loose loop before; its slack grows as
    // the load is let off.
    final cable = Paint()
      ..color = const Color(0xFF8D949B)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final from = body + unit * 13;
    final droop = rig.hooked ? 2 + 16 * rig.slackOut : 10;
    c.drawPath(
        Path()
          ..moveTo(from.dx, from.dy)
          ..quadraticBezierTo((from.dx + hookEnd.dx) / 2, (from.dy + hookEnd.dy) / 2 + droop, hookEnd.dx, hookEnd.dy),
        cable);
    // The hook.
    c.drawArc(Rect.fromCenter(center: hookEnd.translate(0, 4), width: 8, height: 9), -math.pi / 2, math.pi * 1.4, false,
        Paint()
          ..color = const Color(0xFF3C4248)
          ..strokeWidth = 2.2
          ..style = PaintingStyle.stroke);
  }

  void _gripAt(Canvas c, Offset gp) {
    // The grip's two jaws on the conductor and its eye-bolt towards the pole.
    final body = RRect.fromRectAndRadius(Rect.fromCenter(center: gp.translate(-6, 0), width: 22, height: 9), const Radius.circular(3));
    c.drawRRect(body, Paint()..color = const Color(0xFF2E6FB0));
    c.drawLine(gp.translate(-16, -3), gp.translate(4, -3), Paint()
      ..color = const Color(0xFF9CC7EE)
      ..strokeWidth = 1);
    c.drawCircle(gp.translate(7, 0), 3.4, Paint()
      ..color = const Color(0xFF3C4248)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8);
  }

  @override
  bool shouldRepaint(PullWorldPainter old) => old.geo != geo || old.rig != rig;
}

/// The trainee's pole strap and the step under his boots (as sky_read).
class PullStrapPainter extends CustomPainter {
  const PullStrapPainter({required this.box, required this.flip});
  final Rect box;

  /// He works from the far side of the pole.
  final bool flip;

  @override
  void paint(Canvas c, Size size) {
    final hip = Offset(box.left + box.width * 0.5, box.top + box.height * 0.5);
    final strap = Paint()
      ..color = const Color(0xFF3A2A16)
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke;
    final feet = box.bottom - 3;
    const px = PullGeo.px;
    final far = flip ? px - 13 : px + 13;
    c.drawRect(Rect.fromLTRB(flip ? px : box.left + box.width * 0.3, feet, flip ? box.right - box.width * 0.3 : px, feet + 3.2), Paint()..color = const Color(0xFF5A6066));
    c.drawPath(
        Path()
          ..moveTo(hip.dx, hip.dy)
          ..quadraticBezierTo(px, hip.dy - 10, far, hip.dy - 6)
          ..moveTo(hip.dx, hip.dy + 2)
          ..quadraticBezierTo(px, hip.dy + 4, far, hip.dy - 6),
        strap);
  }

  @override
  bool shouldRepaint(PullStrapPainter old) => old.box != box || old.flip != flip;
}

/// The come-along close up (the panel the player works): the ratchet wheel,
/// its pawl (seated in the teeth, or lifted off them), the drum with its
/// cable, and the handle at [handle] (0 up → 1 the end of a stroke).
/// [release]: the release lever is shown thrown (letting the load off).
class RatchetPainter extends CustomPainter {
  RatchetPainter({required this.handle, required this.pawlSeated, required this.turn, this.release = false}) : super(repaint: handle);
  final Animation<double> handle;
  final bool pawlSeated;

  /// The wheel's turn so far (strokes).
  final double turn;
  final bool release;

  /// The pawl's tap area in the panel (fractions of its size).
  static Rect pawlArea(Size s) => Rect.fromLTWH(s.width * 0.52, s.height * 0.05, s.width * 0.36, s.height * 0.4);

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    final hub = Offset(w * 0.42, h * 0.5);
    final r = h * 0.3;
    // The frame (two yellow side plates).
    final plate = RRect.fromRectAndRadius(Rect.fromCenter(center: hub.translate(w * 0.06, 0), width: w * 0.62, height: h * 0.78), Radius.circular(h * 0.12));
    c.drawRRect(
        plate,
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE8BE2A), Color(0xFFB98F0C)])
              .createShader(plate.outerRect));
    c.drawRRect(
        plate,
        Paint()
          ..color = const Color(0xFF6B5208)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    // The cable off the drum to the right (towards the grip).
    c.drawLine(hub.translate(0, r * 0.55), Offset(w, hub.dy + r * 0.55), Paint()
      ..color = const Color(0xFF8D949B)
      ..strokeWidth = 3);
    // The ratchet wheel with its teeth.
    final rot = turn * 0.5 + handle.value * 0.5;
    final teeth = Path();
    const n = 16;
    for (var i = 0; i < n; i++) {
      final a0 = rot + i * 2 * math.pi / n;
      final a1 = a0 + 2 * math.pi / n * 0.7;
      final a2 = a0 + 2 * math.pi / n;
      final p0 = hub + Offset(math.cos(a0), math.sin(a0)) * r;
      final p1 = hub + Offset(math.cos(a1), math.sin(a1)) * (r * 1.18);
      final p2 = hub + Offset(math.cos(a2), math.sin(a2)) * r;
      if (i == 0) teeth.moveTo(p0.dx, p0.dy);
      teeth
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy);
    }
    teeth.close();
    c.drawPath(teeth, Paint()..color = const Color(0xFF5E656C));
    c.drawPath(
        teeth,
        Paint()
          ..color = const Color(0xFF2E3338)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
    c.drawCircle(hub, r * 0.62, Paint()..color = const Color(0xFF8D949B));
    c.drawCircle(hub, r * 0.62, Paint()
      ..color = const Color(0xFF4A4F55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
    c.drawCircle(hub, r * 0.18, Paint()..color = const Color(0xFF2E3338));
    // The pawl: a dog on a pivot above the wheel; seated in the teeth, or
    // lifted clear of them (the wheel can run back).
    final pivot = Offset(w * 0.72, h * 0.16);
    final tipSeated = hub + Offset(math.cos(-0.9), math.sin(-0.9)) * (r * 1.08);
    final tip = pawlSeated ? tipSeated : tipSeated + Offset(w * 0.04, -h * 0.13);
    final pawl = Paint()
      ..color = pawlSeated ? const Color(0xFF2F3A44) : const Color(0xFF4A5560)
      ..strokeWidth = h * 0.065
      ..strokeCap = StrokeCap.round;
    c.drawLine(pivot, tip, pawl);
    c.drawCircle(pivot, h * 0.05, Paint()..color = const Color(0xFF1E2328));
    // Its spring.
    c.drawLine(pivot.translate(0, -h * 0.02), pivot.translate(w * 0.1, -h * 0.06), Paint()
      ..color = const Color(0xFF9AA1A7)
      ..strokeWidth = 1.6);
    // The handle: from the hub down-left; a stroke swings it down.
    final up = -2.25;
    final down = -0.95 + math.pi;
    final a = release ? -1.6 : up + (down - up) * 0.45 * handle.value;
    final end = hub + Offset(math.cos(a + math.pi), math.sin(a + math.pi)) * (w * 0.44);
    c.drawLine(hub, end, Paint()
      ..color = const Color(0xFF3A3F45)
      ..strokeWidth = h * 0.07
      ..strokeCap = StrokeCap.round);
    c.drawLine(Offset.lerp(hub, end, 0.62)!, end, Paint()
      ..color = const Color(0xFFC0392B)
      ..strokeWidth = h * 0.1
      ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(RatchetPainter old) => old.pawlSeated != pawlSeated || old.turn != turn || old.release != release || old.handle != handle;
}

/// The slingshot (in colour over the frozen grey scene): the grip lets go
/// and the come-along whips along the line of pull to where he stands.
/// Non-graphic: a streak, the flying come-along, a white burst.
class PullSlingPainter extends CustomPainter {
  PullSlingPainter({required this.geo, required this.at, required this.v});
  final PullGeo geo;
  final Offset at;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final from = geo.grip(0.5);
    final k = Curves.easeIn.transform(v.clamp(0.0, 1.0));
    final pos = Offset.lerp(from, at, k)!;
    // The line of pull, glowing.
    c.drawLine(
        from,
        at,
        Paint()
          ..color = const Color(0x88E74C3C)
          ..strokeWidth = 10
          ..strokeCap = StrokeCap.round);
    c.drawLine(
        from,
        pos,
        Paint()
          ..color = const Color(0xFFFFE08A)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: pos, width: 24, height: 11), const Radius.circular(3)), Paint()..color = const Color(0xFFD1A414));
    if (k > 0.9) {
      final burst = Paint()..color = const Color(0xEEFFFFFF);
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4;
        c.drawLine(at, at + Offset(math.cos(a), math.sin(a)) * 26, burst..strokeWidth = 3);
      }
      c.drawCircle(at, 12, Paint()..color = const Color(0xFFFFFFFF));
    }
  }

  @override
  bool shouldRepaint(PullSlingPainter old) => old.v != v || old.at != at || old.geo != geo;
}
