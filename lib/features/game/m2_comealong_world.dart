import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'm2_comealong_pick.dart';

// Drawn art for lesson 2.4, কাজ 1 "সঠিক কাম-অ্যালং": the come-along
// (ratchet puller) and the wire grip, drawn lengthwise so the van's rack can
// hang them (rotated) and the close look can show them big; and the deadly
// consequence (an under-rated puller snaps under the conductor's pull and the
// whole rig whips back like a sling-shot — lesson point 2). No text in the
// art: the rating plate and the grip's label are widgets on top.
//
// The close look is hands-on: two strips are felt with the finger — the top
// strip (hook, ratchet and pawl; or the grip's jaws and teeth) and the bottom
// strip (the wire rope to the far hook; or the grip's eye). A flaw shows only
// where the hand has been ([CaToolPainter.flawSeen]).

/// How many stretches each strip is looked at in.
const kCaBins = 20;
int caBin(double u) => (u * kCaBins).floor().clamp(0, kCaBins - 1);

/// Where a flaw sits: strip (top = true) and its stretch (0..1 along the tool).
(bool, double, double)? caFlawSpot(CaFlaw f) => switch (f) {
      CaFlaw.none => null,
      CaFlaw.latch => (true, 0.03, 0.13),
      CaFlaw.pawl => (true, 0.4, 0.52),
      CaFlaw.rope => (false, 0.55, 0.66),
      CaFlaw.grease => (true, 0.16, 0.42),
      CaFlaw.teeth => (true, 0.24, 0.4),
    };

class CaToolPainter extends CustomPainter {
  CaToolPainter(this.item, {this.seenTop, this.seenLow, this.veil});
  final CaItem item;

  /// Stretches looked at (of [kCaBins]); null = all seen.
  final Set<int>? seenTop;
  final Set<int>? seenLow;

  /// Washes what has not been looked at yet (the close look only).
  final Color? veil;

  /// The tool's box inside [s]: never longer than it really is.
  static Rect box(Size s, CaKind k) {
    final maxW = s.height * (k == CaKind.puller ? 6.4 : 2.6);
    final w = math.min(s.width, maxW);
    return Rect.fromLTWH((s.width - w) / 2, 0, w, s.height);
  }

  /// How far along the tool (0 … 1) the point under [x] is.
  static double uAt(Size s, CaKind k, double x) {
    final b = box(s, k);
    return ((x - b.left) / b.width).clamp(0.0, 1.0);
  }

  /// The rating plate (puller) or the grip's label, where the readable tag sits.
  static Rect plate(Size s, CaKind k) {
    final b = box(s, k);
    Offset p(double u, double v) => Offset(b.left + u * b.width, v * b.height);
    return k == CaKind.puller ? Rect.fromPoints(p(0.2, 0.25), p(0.33, 0.5)) : Rect.fromPoints(p(0.08, 0.4), p(0.42, 0.52));
  }

  static bool _any(Set<int>? seen, double a, double b) {
    if (seen == null) return true;
    for (var i = caBin(a); i <= caBin(b); i++) {
      if (seen.contains(i)) return true;
    }
    return false;
  }

  /// The tool's flaw is in view (false for a sound tool).
  static bool flawSeen(CaItem item, Set<int>? top, Set<int>? low) {
    final spot = caFlawSpot(item.flaw);
    if (spot == null) return false;
    final (isTop, a, b) = spot;
    return _any(isTop ? top : low, a, b);
  }

  @override
  void paint(Canvas c, Size s) {
    final b = box(s, item.kind);
    final shows = flawSeen(item, seenTop, seenLow);
    if (item.kind == CaKind.puller) {
      _puller(c, b, shows);
    } else {
      _grip(c, b, shows);
    }
    final v = veil;
    if (v != null) {
      final wash = Paint()..color = v.withValues(alpha: 0.5);
      for (var i = 0; i < kCaBins; i++) {
        final x0 = b.left + b.width * i / kCaBins;
        final x1 = b.left + b.width * (i + 1) / kCaBins;
        if (seenTop != null && !seenTop!.contains(i)) c.drawRect(Rect.fromLTRB(x0, 0, x1 + 0.5, s.height * 0.52), wash);
        if (seenLow != null && !seenLow!.contains(i)) c.drawRect(Rect.fromLTRB(x0, s.height * 0.52, x1 + 0.5, s.height), wash);
      }
    }
  }

  // ---- the come-along -------------------------------------------------------

  void _hook(Canvas c, Offset at, double r, {required bool latch, required bool broken, required bool openLeft}) {
    final steel = Paint()
      ..color = const Color(0xFFC9A227)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.4, r * 0.42)
      ..strokeCap = StrokeCap.round;
    final dir = openLeft ? -1.0 : 1.0;
    // Shank, then the bend.
    final hook = Path()
      ..moveTo(at.dx - dir * r * 1.6, at.dy)
      ..lineTo(at.dx - dir * r * 0.2, at.dy)
      ..arcToPoint(Offset(at.dx - dir * r * 0.2, at.dy + r * 1.6), radius: Radius.circular(r * 0.8), clockwise: !openLeft)
      ..lineTo(at.dx - dir * r * 0.9, at.dy + r * 1.2);
    c.drawPath(hook, steel);
    if (!latch) return;
    final l = Paint()
      ..color = const Color(0xFFD5DADF)
      ..strokeWidth = math.max(0.8, r * 0.2)
      ..strokeCap = StrokeCap.round;
    if (!broken) {
      c.drawLine(Offset(at.dx - dir * r * 1.0, at.dy + r * 0.15), Offset(at.dx - dir * r * 0.85, at.dy + r * 1.15), l);
    } else {
      // The latch snapped: a stub at the shank, the throat open.
      c.drawLine(Offset(at.dx - dir * r * 1.0, at.dy + r * 0.15), Offset(at.dx - dir * r * 1.15, at.dy + r * 0.5), l);
      c.drawCircle(Offset(at.dx - dir * r * 0.55, at.dy + r * 0.75), r * 0.75,
          Paint()
            ..color = const Color(0xCCE53935)
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(0.8, r * 0.14));
    }
  }

  void _puller(Canvas c, Rect b, bool shows) {
    Offset p(double u, double v) => Offset(b.left + u * b.width, b.top + v * b.height);
    final h = b.height;
    final flaw = item.flaw;

    // The wire rope: off the drum, down and along to the far hook.
    final rope = Paint()
      ..color = const Color(0xFF8E979F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, h * 0.055)
      ..strokeCap = StrokeCap.round;
    final kink = flaw == CaFlaw.rope && shows;
    final path = Path()
      ..moveTo(p(0.4, 0.48).dx, p(0.4, 0.48).dy)
      ..quadraticBezierTo(p(0.44, 0.8).dx, p(0.44, 0.8).dy, p(0.52, 0.8).dx, p(0.52, 0.8).dy);
    if (kink) {
      path.lineTo(p(0.56, 0.8).dx, p(0.56, 0.8).dy);
      for (var i = 1; i <= 6; i++) {
        final q = p(0.56 + 0.015 * i, 0.8 + (i.isOdd ? -0.09 : 0.07));
        path.lineTo(q.dx, q.dy);
      }
    }
    path.lineTo(p(0.88, 0.8).dx, p(0.88, 0.8).dy);
    c.drawPath(path, rope);
    // The lay of the strands.
    final lay = Paint()
      ..color = const Color(0xFF5E666D)
      ..strokeWidth = math.max(0.5, h * 0.015);
    for (var u = 0.5; u < 0.87; u += 0.02) {
      if (kink && u > 0.55 && u < 0.67) continue;
      c.drawLine(p(u, 0.775), p(u + 0.008, 0.825), lay);
    }
    if (kink) {
      final strand = Paint()
        ..color = const Color(0xFFB8C0C7)
        ..strokeWidth = math.max(0.6, h * 0.02)
        ..strokeCap = StrokeCap.round;
      final at = p(0.62, 0.8);
      for (var i = 0; i < 5; i++) {
        final a = -math.pi / 2 + (i - 2) * 0.45;
        c.drawLine(at, at + Offset(math.cos(a), math.sin(a)) * h * 0.16, strand);
      }
    }
    // The far hook (on the rope's end).
    _hook(c, p(0.94, 0.8), h * 0.08, latch: true, broken: false, openLeft: false);

    // The handle, from the ratchet up and away, with its black grip.
    final arm = Paint()
      ..shader = const LinearGradient(colors: [Color(0xFFDDE2E6), Color(0xFF8E979F)]).createShader(b)
      ..strokeWidth = math.max(1.6, h * 0.07)
      ..strokeCap = StrokeCap.round;
    c.drawLine(p(0.46, 0.36), p(0.8, 0.12), arm);
    c.drawLine(p(0.72, 0.17), p(0.84, 0.09), Paint()
      ..color = const Color(0xFF1F2328)
      ..strokeWidth = math.max(2.0, h * 0.11)
      ..strokeCap = StrokeCap.round);

    // The frame (zinc plates).
    final frame = RRect.fromRectAndRadius(Rect.fromPoints(p(0.15, 0.2), p(0.52, 0.56)), Radius.circular(h * 0.06));
    c.drawRRect(
      frame,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE3E7EA), Color(0xFF9AA3AB)],
        ).createShader(frame.outerRect),
    );
    c.drawRRect(
      frame,
      Paint()
        ..color = const Color(0xFF5E666D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.6, h * 0.015),
    );
    // The rating plate (orange-red, its print is a widget on top).
    final plate = Rect.fromPoints(p(0.2, 0.25), p(0.33, 0.5));
    c.drawRect(plate, Paint()..color = const Color(0xFFE5532D));
    c.drawRect(
      plate,
      Paint()
        ..color = const Color(0xFF3A1B12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.5, h * 0.012),
    );
    // The drum with the rope wound on it.
    final drum = p(0.4, 0.38);
    c.drawCircle(drum, h * 0.13, Paint()..color = const Color(0xFF6E777F));
    for (var i = -2; i <= 2; i++) {
      c.drawLine(drum + Offset(-h * 0.1, i * h * 0.04), drum + Offset(h * 0.1, i * h * 0.04 + h * 0.015), lay);
    }
    // The ratchet wheel and its pawl.
    final gear = p(0.47, 0.36);
    final gr = h * 0.12;
    final teeth = Path();
    for (var i = 0; i < 12; i++) {
      final a0 = i * math.pi / 6;
      final a1 = a0 + math.pi / 9;
      teeth
        ..moveTo(gear.dx + math.cos(a0) * gr * 0.8, gear.dy + math.sin(a0) * gr * 0.8)
        ..lineTo(gear.dx + math.cos(a1) * gr * 1.15, gear.dy + math.sin(a1) * gr * 1.15)
        ..lineTo(gear.dx + math.cos(a1) * gr * 0.8, gear.dy + math.sin(a1) * gr * 0.8);
    }
    c.drawCircle(gear, gr * 0.85, Paint()..color = const Color(0xFFB8860B));
    c.drawPath(
      teeth,
      Paint()
        ..color = const Color(0xFF8A6508)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.6, h * 0.02),
    );
    c.drawCircle(gear, gr * 0.28, Paint()..color = const Color(0xFF4A3A10));
    final pawl = Paint()
      ..color = const Color(0xFF3C4249)
      ..strokeWidth = math.max(1.0, h * 0.045)
      ..strokeCap = StrokeCap.round;
    final pivot = p(0.51, 0.16);
    if (flaw == CaFlaw.pawl && shows) {
      // The pawl snapped short: its tip no longer reaches the teeth.
      c.drawLine(pivot, pivot + Offset(-h * 0.03, h * 0.06), pawl);
      final tip = gear + Offset(gr * 0.6, -gr * 1.3);
      c.drawLine(tip, tip + Offset(h * 0.05, -h * 0.02), pawl..strokeWidth = math.max(0.8, h * 0.03));
      c.drawCircle(gear + Offset(gr * 0.35, -gr * 0.95), gr * 0.7,
          Paint()
            ..color = const Color(0xCCE53935)
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(0.8, h * 0.02));
    } else {
      c.drawLine(pivot, gear + Offset(gr * 0.3, -gr * 0.95), pawl);
    }
    c.drawCircle(pivot, h * 0.025, Paint()..color = const Color(0xFF22262B));
    // The anchor hook on the frame's end.
    c.drawLine(p(0.09, 0.36), p(0.16, 0.36), Paint()
      ..color = const Color(0xFF9AA3AB)
      ..strokeWidth = math.max(1.4, h * 0.06));
    _hook(c, p(0.07, 0.26), h * 0.15, latch: true, broken: flaw == CaFlaw.latch && shows, openLeft: true);
  }

  // ---- the wire grip ---------------------------------------------------------

  void _grip(Canvas c, Rect b, bool shows) {
    Offset p(double u, double v) => Offset(b.left + u * b.width, b.top + v * b.height);
    final h = b.height;
    final flaw = item.flaw;
    const gold = [Color(0xFFF2C94C), Color(0xFFC9971C)];
    Paint goldOf(Rect r) => Paint()
      ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: gold).createShader(r);
    final edge = Paint()
      ..color = const Color(0xFF7A5A0E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.6, h * 0.012);

    // The eye (bail) the come-along's hook takes.
    final bail = RRect.fromRectAndRadius(Rect.fromPoints(p(0.64, 0.6), p(0.97, 0.86)), Radius.circular(h * 0.13));
    c.drawRRect(
      bail,
      Paint()
        ..color = const Color(0xFFAEB6BD)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.4, h * 0.05),
    );
    // The lever plate (the long triangle), and the link to the bail.
    final lever = Path()
      ..moveTo(p(0.2, 0.08).dx, p(0.2, 0.08).dy)
      ..lineTo(p(0.66, 0.5).dx, p(0.66, 0.5).dy)
      ..lineTo(p(0.62, 0.66).dx, p(0.62, 0.66).dy)
      ..lineTo(p(0.24, 0.3).dx, p(0.24, 0.3).dy)
      ..close();
    c.drawPath(lever, goldOf(Rect.fromPoints(p(0.2, 0.08), p(0.66, 0.66))));
    c.drawPath(lever, edge);
    // The upper jaw (teeth along its lower edge), the conductor's channel, the lower jaw.
    final upper = Rect.fromPoints(p(0.06, 0.2), p(0.5, 0.35));
    c.drawRRect(RRect.fromRectAndRadius(upper, Radius.circular(h * 0.04)), goldOf(upper));
    c.drawRRect(RRect.fromRectAndRadius(upper, Radius.circular(h * 0.04)), edge);
    final lower = Rect.fromPoints(p(0.06, 0.39), p(0.48, 0.53));
    c.drawRRect(RRect.fromRectAndRadius(lower, Radius.circular(h * 0.04)), goldOf(lower));
    c.drawRRect(RRect.fromRectAndRadius(lower, Radius.circular(h * 0.04)), edge);
    final tooth = Paint()..color = const Color(0xFF8A6A12);
    final worn = flaw == CaFlaw.teeth && shows;
    for (var u = 0.08; u < 0.47; u += 0.032) {
      final flat = worn && u > 0.22 && u < 0.42;
      final d = flat ? h * 0.012 : h * 0.06;
      c.drawPath(
        Path()
          ..moveTo(p(u, 0.35).dx, p(u, 0.35).dy)
          ..lineTo(p(u + 0.016, 0.35).dx, p(u, 0.35).dy + d)
          ..lineTo(p(u + 0.032, 0.35).dx, p(u, 0.35).dy)
          ..close(),
        tooth,
      );
      c.drawPath(
        Path()
          ..moveTo(p(u, 0.39).dx, p(u, 0.39).dy)
          ..lineTo(p(u + 0.016, 0.39).dx, p(u, 0.39).dy - d)
          ..lineTo(p(u + 0.032, 0.39).dx, p(u, 0.39).dy)
          ..close(),
        tooth,
      );
    }
    if (worn) {
      c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromPoints(p(0.21, 0.29), p(0.43, 0.45)), Radius.circular(h * 0.05)),
        Paint()
          ..color = const Color(0xCCE53935)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(0.8, h * 0.02),
      );
    }
    if (flaw == CaFlaw.grease && shows) {
      // Black grease and grit packed into the teeth.
      final grease = Paint()..color = const Color(0xE61C1712);
      for (final (u, v, r) in const [(0.19, 0.37, 0.07), (0.26, 0.355, 0.08), (0.33, 0.38, 0.07), (0.39, 0.36, 0.06)]) {
        c.drawOval(Rect.fromCenter(center: p(u, v), width: b.width * r, height: h * 0.1), grease);
      }
      final shine = Paint()..color = const Color(0x88FFFFFF);
      for (final u in const [0.2, 0.27, 0.34]) {
        c.drawOval(Rect.fromCenter(center: p(u, 0.345), width: b.width * 0.02, height: h * 0.02), shine);
      }
    }
    // Bolts.
    final bolt = Paint()..color = const Color(0xFFCBD2D8);
    final ring = Paint()
      ..color = const Color(0xFF6F777E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.5, h * 0.012);
    for (final q in [p(0.24, 0.17), p(0.12, 0.45), p(0.4, 0.46), p(0.62, 0.58)]) {
      c.drawCircle(q, h * 0.045, bolt);
      c.drawCircle(q, h * 0.045, ring);
    }
  }

  @override
  bool shouldRepaint(CaToolPainter old) =>
      old.item != item || old.veil != veil || !_same(old.seenTop, seenTop) || !_same(old.seenLow, seenLow);

  static bool _same(Set<int>? a, Set<int>? b) => a == null ? b == null : (b != null && a.length == b.length && a.containsAll(b));
}

// ============================================================================
// The deadly consequence: the sling-shot
// ============================================================================

/// The rig on the pole: anchor strap on the pole, the come-along, the grip
/// biting the conductor. [t] 0..1: the pull strains the small puller (its
/// plate glows), then at ~0.4 it snaps and the conductor with the grip whips
/// back across the work area.
class CaSnapPainter extends CustomPainter {
  CaSnapPainter({required this.t});
  final double t;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final h = s.height;
    final ground = h * 0.86;
    final sky = Rect.fromLTWH(0, 0, w, ground);
    c.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2E5E8E), Color(0xFF7FA9C9), Color(0xFFD7E3E8)],
        ).createShader(sky),
    );
    c.drawRect(Rect.fromLTWH(0, ground, w, h - ground), Paint()..color = const Color(0xFF6E7B44));
    // The pole and its cross-arm.
    final px = w * 0.16;
    final pole = Rect.fromLTRB(px - 9, h * 0.06, px + 9, ground + 2);
    c.drawRect(pole, Paint()..shader = const LinearGradient(colors: [Color(0xFFB9B8B1), Color(0xFF8C8B85)]).createShader(pole));
    final armY = h * 0.2;
    c.drawRect(Rect.fromLTRB(px - 30, armY, px + 40, armY + 7), Paint()..color = const Color(0xFF4F565D));
    // The anchor strap on the pole.
    final anchor = Offset(px + 10, h * 0.34);
    c.drawRect(Rect.fromLTRB(px - 10, anchor.dy - 5, px + 12, anchor.dy + 5), Paint()..color = const Color(0xFF3C4249));

    final snap = ((t - 0.4) / 0.6).clamp(0.0, 1.0);
    final strain = (t / 0.4).clamp(0.0, 1.0);
    final wire = Paint()
      ..color = const Color(0xFF2B2F35)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Where the grip bites the conductor: steady, then whipping right and down.
    final gripRest = Offset(w * 0.58, h * 0.32);
    final swing = Curves.easeOut.transform(snap);
    final gripAt = Offset.lerp(gripRest, Offset(w * 0.9, h * 0.72), swing)!;
    // The conductor: from the grip out to the next pole (off the right edge), then the slack tail back toward the pole.
    final cond = Path()
      ..moveTo(w + 4, h * 0.26)
      ..quadraticBezierTo(w * 0.8, h * 0.3 + h * 0.25 * swing, gripAt.dx, gripAt.dy);
    c.drawPath(cond, wire);
    final tail = Path()
      ..moveTo(gripAt.dx, gripAt.dy)
      ..quadraticBezierTo(w * 0.4, h * 0.5 + h * 0.1 * swing, px + 8, h * 0.6);
    c.drawPath(tail, wire..strokeWidth = 2.2);

    if (snap == 0) {
      // The puller in one piece, straining: the rope taut, the plate glowing.
      final mid = Offset.lerp(anchor, gripRest, 0.4)!;
      c.drawLine(anchor, mid, Paint()
        ..color = const Color(0xFF9AA3AB)
        ..strokeWidth = 5);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: mid, width: 34, height: 18), const Radius.circular(4)), Paint()..color = const Color(0xFFC9CFD4));
      c.drawRect(Rect.fromCenter(center: mid, width: 12, height: 10), Paint()..color = Color.lerp(const Color(0xFFE5532D), const Color(0xFFFFE08A), strain)!);
      c.drawLine(mid, gripRest, Paint()
        ..color = const Color(0xFF8E979F)
        ..strokeWidth = 2);
      if (strain > 0.5) {
        c.drawCircle(
          mid,
          18 + 10 * strain,
          Paint()
            ..color = Color.fromRGBO(255, 80, 60, 0.35 * strain)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }
    } else {
      // Snapped: a stub at the anchor, the broken half flying with the conductor.
      final stub = Offset.lerp(anchor, gripRest, 0.25)!;
      c.drawLine(anchor, stub, Paint()
        ..color = const Color(0xFF9AA3AB)
        ..strokeWidth = 5);
      final fly = Offset.lerp(Offset.lerp(anchor, gripRest, 0.5)!, gripAt + const Offset(-30, -6), swing)!;
      c.save();
      c.translate(fly.dx, fly.dy);
      c.rotate(swing * 5);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 26, height: 14), const Radius.circular(3)), Paint()..color = const Color(0xFFC9CFD4));
      c.restore();
      c.drawLine(fly, gripAt, Paint()
        ..color = const Color(0xFF8E979F)
        ..strokeWidth = 2);
      // The burst where it broke.
      final burst = Paint()
        ..color = Color.fromRGBO(255, 230, 140, 1 - snap * 0.7)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4 + 0.2;
        final d = Offset(math.cos(a), math.sin(a));
        c.drawLine(stub + d * (8 + 10 * snap), stub + d * (18 + 26 * snap), burst);
      }
      // Speed lines along the whip's arc.
      final speed = Paint()
        ..color = Color.fromRGBO(255, 255, 255, 0.8 * (1 - snap * 0.5))
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      final arc = Rect.fromCircle(center: Offset(w * 0.55, h * 0.3), radius: h * 0.42);
      for (var i = 0; i < 3; i++) {
        c.drawArc(arc.deflate(i * 10.0), 0.15, 0.9 * swing, false, speed);
      }
    }
    // The grip on the conductor.
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: gripAt, width: 20, height: 10), const Radius.circular(3)), Paint()..color = const Color(0xFFE0B23A));
  }

  @override
  bool shouldRepaint(CaSnapPainter old) => old.t != t;
}
