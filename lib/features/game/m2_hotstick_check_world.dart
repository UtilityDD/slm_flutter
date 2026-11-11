import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'scene_kit.dart' show Carry, LinemanFigure, LinemanMode;

// Lesson 2.5, কাজ 1 "রডের স্বাস্থ্য": the drawn world. A site just after the
// rain — a grey sky breaking up, wet ground with puddles, a far row of trees
// and roofs — an 11 kV pole on the right with its cross-arm, pin insulators
// and the three DO fuse cutouts, and on the left the site's rod stand (two
// posts and a bar with hooks: the operating rods hang on it, hook up — the
// lesson's "দেওয়ালে ঝুলিয়ে রাখুন", never on the ground). The rods themselves
// are widgets on the stand ([HotStickPainter]). No text in the art. Design:
// 360 wide × any height; the ground row stays put, a tall phone gets more sky.

/// Where things are, in design pixels (360 × [h]).
@immutable
class StickSiteGeo {
  const StickSiteGeo(this.h);
  final double h;

  double get ground => h - 112;

  /// The stand's bar (the rods hang from it).
  double get barY => ground - 356;
  double get postL => 82;
  double get postR => 248;

  /// Inside the stand: where the rods hang.
  Rect get opening => Rect.fromLTRB(postL + 10, barY + 6, postR - 8, ground - 26);

  /// Hook [i] of [n]: the rod hanging on it.
  Rect slot(int i, int n) {
    final w = opening.width / n;
    return Rect.fromLTWH(opening.left + w * i, opening.top, w, opening.height);
  }

  /// The docket's clipboard, hung on a nail on the left post.
  Rect get docket => Rect.fromLTWH(10, ground - 318, 64, 114);

  /// The pole (concrete), its cross-arm and the DO fuse cutouts.
  double get poleX => 318;
  double get armY => math.max(130.0, ground - 470);
  List<double> get fuseX => const [262, 292, 346];

  /// Where the [i]th rod set aside leans, against the pole.
  Rect aside(int i) => Rect.fromLTWH(254 + i * 18.0, ground - 300, 30, 292);

  /// The trainee, at the stand's left.
  Rect get trainee => Rect.fromLTWH(-4, ground - 120, 68, 138);
}

class StickSitePainter extends CustomPainter {
  const StickSitePainter(this.geo);
  final StickSiteGeo geo;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final h = s.height;
    final g = geo.ground;

    // Sky after the rain: grey cloud clearing to a pale band low down.
    final sky = Rect.fromLTWH(0, 0, w, g);
    c.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF55677A), Color(0xFF8FA4B6), Color(0xFFDCE5EA)],
          stops: [0, 0.55, 1],
        ).createShader(sky),
    );
    void cloud(double x, double y, double k, Color col) {
      final p = Paint()..color = col;
      c.drawOval(Rect.fromCenter(center: Offset(x, y), width: 120 * k, height: 30 * k), p);
      c.drawCircle(Offset(x - 26 * k, y - 10 * k), 20 * k, p);
      c.drawCircle(Offset(x + 12 * k, y - 16 * k), 26 * k, p);
      c.drawCircle(Offset(x + 40 * k, y - 4 * k), 16 * k, p);
    }

    cloud(70, g - 520, 1.3, const Color(0xCC6E7F90));
    cloud(250, g - 590, 1.1, const Color(0xB37A8B9C));
    cloud(180, g - 420, 0.9, const Color(0x99B9C7D2));
    // A break in the cloud: the sun coming back.
    final sun = Offset(w * 0.78, g - 360);
    c.drawCircle(sun, 90, Paint()..shader = const RadialGradient(colors: [Color(0x66FFF3D0), Color(0x00FFF3D0)]).createShader(Rect.fromCircle(center: sun, radius: 90)));

    // Far: trees and roofs, hazy.
    final far = Paint()..color = const Color(0xFF8C9C8E);
    for (var i = 0; i < 9; i++) {
      final x = i * 44.0 + 10;
      c.drawCircle(Offset(x, g - 44 - (i % 3) * 6), 24 + (i % 2) * 6, far);
    }
    final roof = Paint()..color = const Color(0xFF9AA5A8);
    c.drawRect(Rect.fromLTWH(120, g - 62, 54, 40), roof);
    c.drawPath(Path()..moveTo(114, g - 62)..lineTo(147, g - 80)..lineTo(180, g - 62)..close(), Paint()..color = const Color(0xFF7F8A8C));
    c.drawRect(Rect.fromLTWH(196, g - 50, 40, 30), roof);

    // A far line, its poles hazy.
    final hazy = Paint()
      ..color = const Color(0xFF7D8D99)
      ..strokeWidth = 1;
    for (final x in const [24.0, 150.0]) {
      c.drawRect(Rect.fromLTWH(x, g - 150, 3, 130), Paint()..color = const Color(0xFF8E9DA8));
      c.drawRect(Rect.fromLTWH(x - 12, g - 150, 27, 2.5), Paint()..color = const Color(0xFF8E9DA8));
    }
    c.drawLine(Offset(0, g - 147), Offset(geo.poleX, geo.armY + 40), hazy);

    // Ground: wet earth with grass edges and puddles.
    final field = Rect.fromLTWH(0, g, w, h - g);
    c.drawRect(
      field,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6E7A4C), Color(0xFF5A5236), Color(0xFF4A4330)],
          stops: [0, 0.35, 1],
        ).createShader(field),
    );
    final grass = Paint()
      ..color = const Color(0xFF4F6234)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 40; i++) {
      final x = i * 9.3 + 3;
      c.drawLine(Offset(x, g + 3), Offset(x + 2, g - 5 - (i % 4) * 2), grass);
    }
    void puddle(Rect r) {
      c.drawOval(r, Paint()..color = const Color(0xFF3E4A52));
      c.drawOval(
        r.deflate(2),
        Paint()
          ..shader = const LinearGradient(colors: [Color(0xFF9FB3C2), Color(0xFF5E7282)]).createShader(r),
      );
      c.drawLine(Offset(r.left + r.width * 0.25, r.center.dy - 1), Offset(r.left + r.width * 0.6, r.center.dy - 2),
          Paint()
            ..color = const Color(0x99FFFFFF)
            ..strokeWidth = 1.2);
    }

    puddle(Rect.fromLTWH(96, g + 30, 110, 16));
    puddle(Rect.fromLTWH(232, g + 62, 90, 14));
    puddle(Rect.fromLTWH(14, g + 76, 70, 12));

    _pole(c, s);
    _stand(c);
  }

  void _pole(Canvas c, Size s) {
    final g = geo.ground;
    final x = geo.poleX;
    final arm = geo.armY;
    final pole = Rect.fromLTRB(x - 8, arm - 30, x + 8, g + 6);
    c.drawRect(pole, Paint()..shader = const LinearGradient(colors: [Color(0xFFC3C2BA), Color(0xFF8F8E87)]).createShader(pole));
    // Rain streaks down the pole.
    c.drawLine(Offset(x - 3, arm + 30), Offset(x - 3, g - 40), Paint()
      ..color = const Color(0x33384048)
      ..strokeWidth = 2);
    // Cross-arm (steel channel).
    c.drawRect(Rect.fromLTRB(244, arm, s.width + 4, arm + 8), Paint()..color = const Color(0xFF4A5259));
    c.drawRect(Rect.fromLTRB(244, arm + 6, s.width + 4, arm + 8), Paint()..color = const Color(0xFF353B41));
    // Pin insulators on the arm and the three phases.
    final porcelain = Paint()..color = const Color(0xFFEDE7DA);
    final rim = Paint()..color = const Color(0xFF8E5A3C);
    final wire = Paint()
      ..color = const Color(0xFF2B2F35)
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke;
    for (final ix in const [256.0, 300.0, 344.0]) {
      for (var i = 0; i < 3; i++) {
        c.drawOval(Rect.fromCenter(center: Offset(ix, arm - 3 - i * 4.0), width: 14 - i * 2.0, height: 5), i.isEven ? porcelain : rim);
      }
      final p = Path()
        ..moveTo(0, arm - 40 + (ix - 256) * 0.1)
        ..quadraticBezierTo(ix * 0.45, arm - 4, ix, arm - 14);
      c.drawPath(p, wire);
    }
    // The DO fuse cutouts hanging under the arm (porcelain body, the fuse
    // barrel, its pull ring).
    for (final fx in geo.fuseX) {
      final top = arm + 14;
      c.drawLine(Offset(fx, arm + 8), Offset(fx, top), Paint()
        ..color = const Color(0xFF353B41)
        ..strokeWidth = 3);
      final body = Rect.fromCenter(center: Offset(fx, top + 26), width: 9, height: 48);
      c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(3)), Paint()..color = const Color(0xFFD9D2C3));
      for (var i = 0; i < 4; i++) {
        c.drawRect(Rect.fromCenter(center: Offset(fx, top + 10 + i * 10.0), width: 13, height: 3), Paint()..color = const Color(0xFFB9B1A1));
      }
      final barrel = Rect.fromCenter(center: Offset(fx + 9, top + 28), width: 5, height: 40);
      c.drawRRect(RRect.fromRectAndRadius(barrel, const Radius.circular(2)), Paint()..color = const Color(0xFF6B5B45));
      c.drawCircle(Offset(fx + 9, top + 6), 3.2, Paint()
        ..color = const Color(0xFF9AA3AB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4);
      // Drop lead down towards the transformer below the frame.
      c.drawLine(Offset(fx + 9, top + 48), Offset(fx + 4, top + 82), wire..strokeWidth = 1.6);
    }
  }

  void _stand(Canvas c) {
    final g = geo.ground;
    final top = geo.barY;
    // Two square steel posts and the bar.
    final post = Paint()..shader = const LinearGradient(colors: [Color(0xFF6F7880), Color(0xFF454C53)]).createShader(Rect.fromLTWH(0, top, 10, g - top));
    for (final x in [geo.postL, geo.postR]) {
      c.drawRect(Rect.fromLTWH(x - 5, top - 10, 10, g - top + 14), post);
      c.drawRect(Rect.fromLTWH(x - 9, g, 18, 6), Paint()..color = const Color(0xFF353B41));
    }
    c.drawRect(Rect.fromLTRB(geo.postL - 8, top - 12, geo.postR + 8, top), Paint()..color = const Color(0xFF5B646C));
    c.drawRect(Rect.fromLTRB(geo.postL - 8, top - 3, geo.postR + 8, top), Paint()..color = const Color(0xFF3A4046));
    // A drip line of rain still on the bar.
    final drip = Paint()..color = const Color(0x99D5E4EE);
    for (var x = geo.postL + 8; x < geo.postR; x += 23) {
      c.drawCircle(Offset(x, top + 2), 1.4, drip);
    }
    // The nail for the docket.
    c.drawCircle(Offset(geo.postL - 5, geo.docket.top - 8), 2.2, Paint()..color = const Color(0xFF2A2E33));
    c.drawLine(Offset(geo.postL - 5, geo.docket.top - 8), Offset(geo.docket.center.dx, geo.docket.top), Paint()
      ..color = const Color(0xFF2A2E33)
      ..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(StickSitePainter old) => old.geo.h != geo.h;
}

// ============================================================================
// The operating rod (hot stick)
// ============================================================================

/// What the painter needs to know of a rod (kept free of the play logic).
enum StickBuild { fibreglass, bamboo }

enum StickMark { none, crack, scratch, glaze, wet, overdue }

/// How many stretches the stick is felt in.
const kStickBins = 20;
int stickBin(double u) => (u * kStickBins).floor().clamp(0, kStickBins - 1);

/// An operating rod drawn lengthwise, head at the left: the metal universal
/// head with its fuse-puller hook, the yellow fibreglass stick in telescopic
/// sections (ferrules at the joints), a dark grip and the end cap — or the
/// bamboo jugaad (knots, a bent hook bound on with wire). Surface marks — a
/// crack, a deep scratch, worn glaze (fibres showing), water drops — show only
/// where the hand has felt ([seen]: stretches of [kStickBins]; null = all).
/// [wiped] dries it (the cloth has been along it). Unfelt stretches are washed
/// with [veil] when set.
class HotStickPainter extends CustomPainter {
  HotStickPainter({required this.build, this.mark = StickMark.none, this.seen, this.wiped = false, this.veil});
  final StickBuild build;
  final StickMark mark;
  final Set<int>? seen;
  final bool wiped;
  final Color? veil;

  static const crackU = 0.62;
  static const scratchU = 0.42;
  static const glazeA = 0.24;
  static const glazeB = 0.34;
  static const wetA = 0.18;
  static const wetB = 0.82;

  static double x0(Size s) => s.width * 0.17;
  static double x1(Size s) => s.width * 0.96;
  static double thick(Size s) => math.max(3.0, s.height * 0.16);
  static double cy(Size s) => s.height * 0.5;

  /// How far along the stick (0 head end … 1 grip end) [x] is.
  static double stickU(Size s, double x) => ((x - x0(s)) / (x1(s) - x0(s))).clamp(0.0, 1.0);

  static bool _any(Set<int>? seen, double a, double b) {
    if (seen == null) return true;
    for (var i = stickBin(a); i <= stickBin(b); i++) {
      if (seen.contains(i)) return true;
    }
    return false;
  }

  /// The mark is under a felt stretch (false for marks felt elsewhere, or none).
  static bool markFelt(StickMark mark, Set<int>? seen) => switch (mark) {
        StickMark.crack => _any(seen, crackU - 0.03, crackU + 0.03),
        StickMark.scratch => _any(seen, scratchU - 0.04, scratchU + 0.04),
        StickMark.glaze => _any(seen, glazeA, glazeB),
        StickMark.wet => _any(seen, wetA, wetB),
        _ => false,
      };

  @override
  void paint(Canvas canvas, Size s) {
    final t = thick(s);
    final y = cy(s);
    final a = x0(s);
    final b = x1(s);
    final bamboo = build == StickBuild.bamboo;
    final shows = markFelt(mark, seen);

    // Head.
    if (bamboo) {
      final hook = Path()
        ..moveTo(a + t * 0.6, y)
        ..lineTo(a - s.width * 0.03, y - t * 0.2)
        ..quadraticBezierTo(a - s.width * 0.08, y - t * 0.6, a - s.width * 0.06, y - t * 2.2)
        ..lineTo(a - s.width * 0.035, y - t * 2.0);
      canvas.drawPath(
        hook,
        Paint()
          ..color = const Color(0xFF6B6F73)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.0, t * 0.22)
          ..strokeCap = StrokeCap.round,
      );
    } else {
      final metal = Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFD5DBE0), Color(0xFF7E878F)]).createShader(Rect.fromLTWH(a - t * 2, y - t, t * 3, t * 2));
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(a - t * 1.6, y - t * 0.62, a + t * 0.3, y + t * 0.62), Radius.circular(t * 0.2)), metal);
      // Splined collar.
      for (var i = 0; i < 3; i++) {
        canvas.drawLine(Offset(a - t * 1.3 + i * t * 0.4, y - t * 0.6), Offset(a - t * 1.3 + i * t * 0.4, y + t * 0.6), Paint()
          ..color = const Color(0xFF5F676E)
          ..strokeWidth = math.max(0.5, t * 0.07));
      }
      // The fuse-puller hook.
      final hook = Path()
        ..moveTo(a - t * 1.6, y)
        ..lineTo(a - s.width * 0.055, y)
        ..quadraticBezierTo(a - s.width * 0.1, y, a - s.width * 0.1, y - t * 1.3)
        ..quadraticBezierTo(a - s.width * 0.1, y - t * 2.3, a - s.width * 0.065, y - t * 2.3)
        ..quadraticBezierTo(a - s.width * 0.04, y - t * 2.3, a - s.width * 0.04, y - t * 1.6);
      canvas.drawPath(
        hook,
        Paint()
          ..color = const Color(0xFF9AA3AB)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.2, t * 0.38)
          ..strokeCap = StrokeCap.round,
      );
    }

    // Stick.
    final stick = RRect.fromRectAndRadius(Rect.fromLTRB(a, y - t / 2, b, y + t / 2), Radius.circular(t / 2));
    if (bamboo) {
      canvas.drawRRect(stick, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFD8C47F), Color(0xFFA88F4C)]).createShader(stick.outerRect));
      final knot = Paint()..color = const Color(0xFF7D6A33);
      for (final u in const [0.2, 0.45, 0.7, 0.92]) {
        canvas.drawRect(Rect.fromCenter(center: Offset(a + (b - a) * u, y), width: math.max(1.0, t * 0.22), height: t * 1.1), knot);
      }
      // Wire binding the hook on.
      final bind = Paint()
        ..color = const Color(0xFF7A7F85)
        ..strokeWidth = math.max(0.6, t * 0.1);
      for (var i = 0; i < 4; i++) {
        final x = a + t * 0.2 + i * t * 0.25;
        canvas.drawLine(Offset(x, y - t * 0.55), Offset(x + t * 0.15, y + t * 0.55), bind);
      }
    } else {
      canvas.drawRRect(stick, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF7D35C), Color(0xFFE2A92C)]).createShader(stick.outerRect));
      // Glaze highlight.
      canvas.drawLine(Offset(a + t, y - t * 0.22), Offset(b - t, y - t * 0.22), Paint()
        ..color = const Color(0x88FFFFFF)
        ..strokeWidth = math.max(0.5, t * 0.12));
      // Telescopic ferrules.
      final ferrule = Paint()..color = const Color(0xFF8F979E);
      for (final u in const [0.36, 0.58]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(a + (b - a) * u, y), width: t * 0.7, height: t * 1.18), Radius.circular(t * 0.15)),
          ferrule,
        );
      }
      // Grip and end cap.
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(a + (b - a) * 0.78, y - t * 0.58, b - t * 0.4, y + t * 0.58), Radius.circular(t * 0.3)), Paint()..color = const Color(0xFF34383E));
      canvas.drawRect(Rect.fromCenter(center: Offset(a + (b - a) * 0.76, y), width: t * 0.5, height: t * 1.2), Paint()..color = const Color(0xFFC0392B));
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(b - t * 0.5, y - t * 0.5, b + t * 0.15, y + t * 0.5), Radius.circular(t * 0.25)), Paint()..color = const Color(0xFF1E2228));
    }
    canvas.drawRRect(
      stick,
      Paint()
        ..color = bamboo ? const Color(0xFF7D6A33) : const Color(0xFF9C7420)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.5, t * 0.08),
    );

    // Marks, only where felt.
    double ux(double u) => a + (b - a) * u;
    if (shows) {
      switch (mark) {
        case StickMark.crack:
          final cx = ux(crackU);
          final crack = Path()
            ..moveTo(cx - t * 1.2, y - t * 0.45)
            ..lineTo(cx - t * 0.4, y + t * 0.1)
            ..lineTo(cx + t * 0.2, y - t * 0.25)
            ..lineTo(cx + t * 1.0, y + t * 0.42);
          canvas.drawPath(crack, Paint()
            ..color = const Color(0xFF3B2A12)
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(0.8, t * 0.14));
          canvas.drawLine(Offset(cx - t * 0.4, y + t * 0.1), Offset(cx - t * 0.6, y + t * 0.45), Paint()
            ..color = const Color(0xFF3B2A12)
            ..strokeWidth = math.max(0.5, t * 0.08));
        case StickMark.scratch:
          final cx = ux(scratchU);
          canvas.drawLine(Offset(cx - t * 2.2, y - t * 0.3), Offset(cx + t * 2.0, y + t * 0.25), Paint()
            ..color = const Color(0xFF8A5E14)
            ..strokeWidth = math.max(1.0, t * 0.2)
            ..strokeCap = StrokeCap.round);
          canvas.drawLine(Offset(cx - t * 2.0, y - t * 0.36), Offset(cx + t * 2.0, y + t * 0.16), Paint()
            ..color = const Color(0xCCFFF4D0)
            ..strokeWidth = math.max(0.5, t * 0.07));
        case StickMark.glaze:
          final r = Rect.fromLTRB(ux(glazeA), y - t * 0.48, ux(glazeB), y + t * 0.48);
          canvas.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(t * 0.3)), Paint()..color = const Color(0xE6EDE6D2));
          final fibre = Paint()
            ..color = const Color(0xFFBFA77A)
            ..strokeWidth = math.max(0.4, t * 0.06);
          for (var i = 0; i < 9; i++) {
            final x = r.left + r.width * (i + 0.5) / 9;
            canvas.drawLine(Offset(x - t * 0.2, r.top + 1), Offset(x + t * 0.25, r.bottom - 1), fibre);
          }
        case StickMark.wet:
          if (!wiped) {
            final drop = Paint()..color = const Color(0xCC5FA8D8);
            final shine = Paint()..color = const Color(0xEEFFFFFF);
            final rng = math.Random(11);
            for (var i = 0; i < 16; i++) {
              final u = wetA + (wetB - wetA) * (i + rng.nextDouble() * 0.6) / 16;
              final dy = (rng.nextDouble() - 0.5) * t * 0.6;
              final r = t * (0.13 + rng.nextDouble() * 0.12);
              final c = Offset(ux(u), y + dy);
              canvas.drawOval(Rect.fromCenter(center: c, width: r * 2, height: r * 2.4), drop);
              canvas.drawCircle(c - Offset(r * 0.3, r * 0.4), r * 0.3, shine);
            }
            // A drip hanging from the underside.
            final d = Offset(ux(0.5), y + t * 0.5);
            canvas.drawPath(
              Path()
                ..moveTo(d.dx - t * 0.15, d.dy)
                ..quadraticBezierTo(d.dx, d.dy + t * 0.7, d.dx + t * 0.15, d.dy)
                ..close(),
              drop,
            );
          }
        default:
          break;
      }
    }

    // What has not been felt yet is washed out.
    final v = veil;
    final felt = seen;
    if (v != null && felt != null) {
      final wash = Paint()..color = v.withValues(alpha: 0.6);
      final bw = (b - a) / kStickBins;
      for (var i = 0; i < kStickBins; i++) {
        if (!felt.contains(i)) canvas.drawRect(Rect.fromLTWH(a + bw * i - 0.5, y - t * 0.75, bw + 1, t * 1.5), wash);
      }
    }
  }

  @override
  bool shouldRepaint(HotStickPainter old) =>
      old.build != build || old.mark != mark || old.wiped != wiped || old.veil != veil || !_same(old.seen, seen);

  static bool _same(Set<int>? a, Set<int>? b) {
    if (a == null || b == null) return a == b;
    return a.length == b.length && a.containsAll(b);
  }
}

// ============================================================================
// The deadly move, staged in colour over the frozen site
// ============================================================================

/// What the flash shows on the stick.
enum StickFlashKind { rating, wet, bamboo }

/// Where things are in the consequence picture ([s]: the panel).
@immutable
class StickFlashGeo {
  const StickFlashGeo(this.s);
  final Size s;

  double get ground => s.height * 0.9;
  double get poleX => s.width * 0.88;
  double get armY => s.height * 0.16;

  /// The DO fuse's pull ring (the rod's hook goes into it).
  Offset get ring => Offset(s.width * 0.7, armY + 30);

  Rect get figure {
    final fh = s.height * 0.5;
    return Rect.fromLTWH(s.width * 0.04, ground - fh * 0.985, fh * 0.5, fh);
  }

  Offset get hand => figure.topLeft + LinemanFigure.tipOf(LinemanMode.hold, Carry.none, figure.size);
  Offset get dir => (ring - hand) / (ring - hand).distance;
  Offset get nrm => Offset(-dir.dy, dir.dx);
  double get len => (ring - hand).distance;
  Offset along(double u) => hand + dir * (len * u);
}

/// The still picture behind the flash: the pole top with the DO fuse.
class StickPoleTopPainter extends CustomPainter {
  const StickPoleTopPainter(this.g);
  final StickFlashGeo g;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final h = s.height;
    final sky = Rect.fromLTWH(0, 0, w, g.ground);
    c.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4F6072), Color(0xFF93A7B7), Color(0xFFD7E0E5)],
          stops: [0, 0.6, 1],
        ).createShader(sky),
    );
    final field = Rect.fromLTWH(0, g.ground, w, h - g.ground);
    c.drawRect(field, Paint()..color = const Color(0xFF5E6440));
    final pole = Rect.fromLTRB(g.poleX - 8, h * 0.05, g.poleX + 8, g.ground + 4);
    c.drawRect(pole, Paint()..shader = const LinearGradient(colors: [Color(0xFFB9B8B1), Color(0xFF8C8B85)]).createShader(pole));
    c.drawRect(Rect.fromLTRB(w * 0.56, g.armY, w + 4, g.armY + 7), Paint()..color = const Color(0xFF4F565D));
    final wire = Paint()
      ..color = const Color(0xFF2B2F35)
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke;
    c.drawLine(Offset(0, g.armY - 20), Offset(w * 0.66, g.armY - 10), wire);
    c.drawLine(Offset(0, g.armY - 30), Offset(w, g.armY - 14), wire);
    // The cutout and its fuse barrel; the ring the hook goes in.
    final fx = g.ring.dx;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(fx - 8, g.armY + 34), width: 10, height: 50), const Radius.circular(3)), Paint()..color = const Color(0xFFD9D2C3));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(fx, g.armY + 44), width: 6, height: 40), const Radius.circular(2)), Paint()..color = const Color(0xFF6B5B45));
    c.drawCircle(g.ring, 4, Paint()
      ..color = const Color(0xFF9AA3AB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8);
  }

  @override
  bool shouldRepaint(StickPoleTopPainter old) => old.g.s != g.s;
}

/// The stick from the gloved hands up to the ring; the charge tracks down it
/// (over the water film, through the bamboo, through a rod rated too low) to
/// the hands. [t]: 0 … 1.
class StickFlashPainter extends CustomPainter {
  StickFlashPainter({required this.g, required this.t, required this.kind});
  final StickFlashGeo g;
  final double t;
  final StickFlashKind kind;

  @override
  void paint(Canvas c, Size s) {
    final nrm = g.nrm;
    final w = math.max(7.0, g.s.width * 0.03);
    Offset edge(double u, double side) => g.along(u) + nrm * (side * w / 2);
    final stick = Path()
      ..moveTo(edge(-0.1, 1).dx, edge(-0.1, 1).dy)
      ..lineTo(edge(0.93, 1).dx, edge(0.93, 1).dy)
      ..lineTo(edge(0.93, -1).dx, edge(0.93, -1).dy)
      ..lineTo(edge(-0.1, -1).dx, edge(-0.1, -1).dy)
      ..close();
    final bamboo = kind == StickFlashKind.bamboo;
    c.drawPath(stick, Paint()..color = bamboo ? const Color(0xFFCDB772) : const Color(0xFFF2C64A));
    c.drawPath(stick, Paint()
      ..color = bamboo ? const Color(0xFF7D6A33) : const Color(0xFF8A6418)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2);
    if (bamboo) {
      final knot = Paint()
        ..color = const Color(0xFF7D6A33)
        ..strokeWidth = 2;
      for (final u in const [0.25, 0.5, 0.75]) {
        c.drawLine(edge(u, 1), edge(u, -1), knot);
      }
    } else {
      c.drawLine(g.along(-0.1), g.along(0.1), Paint()
        ..color = const Color(0xFF34383E)
        ..strokeWidth = w * 1.15);
      c.drawLine(g.along(0.12), g.along(0.14), Paint()
        ..color = const Color(0xFFC0392B)
        ..strokeWidth = w * 1.2);
    }
    if (kind == StickFlashKind.wet) {
      final drop = Paint()..color = const Color(0xDD5FA8D8);
      for (var i = 0; i < 14; i++) {
        final u = 0.18 + i * 0.05;
        c.drawCircle(g.along(u) + nrm * ((i.isEven ? 1 : -1) * w * 0.25), w * 0.2, drop);
      }
    }
    // The hook in the ring.
    final r = g.ring;
    c.drawPath(
      Path()
        ..moveTo(g.along(0.93).dx, g.along(0.93).dy)
        ..lineTo(r.dx - 2, r.dy + 6)
        ..quadraticBezierTo(r.dx - 8, r.dy - 2, r.dx, r.dy - 6),
      Paint()
        ..color = const Color(0xFF9AA3AB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );

    // The charge tracks down the stick to the hands.
    final reach = (t / 0.55).clamp(0.0, 1.0);
    if (reach > 0) {
      final rng = math.Random(5 + (t * 14).floor());
      final arc = Path()..moveTo(r.dx, r.dy);
      const n = 16;
      for (var i = 1; i <= n; i++) {
        final u = 0.93 * (1 - (i / n) * reach);
        final p = g.along(u) + nrm * ((rng.nextDouble() - 0.5) * w * 2.2);
        arc.lineTo(p.dx, p.dy);
      }
      c.drawPath(arc, Paint()
        ..color = const Color(0x8066B7FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      c.drawPath(arc, Paint()
        ..color = const Color(0xFFE8F6FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeJoin = StrokeJoin.round);
      c.drawCircle(r, 10 + 10 * reach, Paint()
        ..color = const Color(0x99FFF3B0)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
    }
    if (t > 0.55) {
      final f = ((t - 0.55) / 0.45).clamp(0.0, 1.0);
      final hand = g.hand;
      final rr = 24 + 56 * f;
      c.drawCircle(
        hand,
        rr,
        Paint()..shader = RadialGradient(colors: [Color.fromRGBO(255, 250, 220, 0.95 * (1 - f * 0.3)), const Color(0x00FFC24A)]).createShader(Rect.fromCircle(center: hand, radius: rr)),
      );
      final spark = Paint()
        ..color = Color.fromRGBO(255, 236, 160, 1 - f * 0.4)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4 + 0.3;
        final d = Offset(math.cos(a), math.sin(a));
        c.drawLine(hand + d * (14 + 10 * f), hand + d * (26 + 26 * f), spark);
      }
    }
  }

  @override
  bool shouldRepaint(StickFlashPainter old) => old.t != t || old.kind != kind || old.g.s != g.s;
}
