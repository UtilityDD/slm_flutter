import 'dart:math' as math;

import 'package:flutter/material.dart';

// Lesson 2.6, কাজ 1 (সঠিক ছুরি, সঠিক প্রস্তুতি): the drawn world. A roadside
// pole late in the morning; the service cable comes down the pole and its cut
// end hangs in front of it, ready to be skinned; a trestle bench beside it
// with the canvas tool roll hung open on its back rail (the tools are widgets
// in its pockets), the cut-resistant gloves and the tester on the bench top.
// No text in the art. Design: 360 wide × any height; everything stands on
// the ground row, so a tall phone gets more sky, never a stretched bench.

/// The cables a job can be (lesson 2.6: small wire, LT PVC cable, AB cable).
enum SkinCable { wire, ltPvc, ab }

/// The tools in the roll.
enum SkinTool { skinKnife, stripper, abTool, kitchen }

/// What a blade can have wrong (lesson 2.6 daily check: sharp and clean).
enum BladeFlaw { none, blunt, dirty }

/// Where things are, in design pixels (360 × [h]).
@immutable
class SkinWorldGeo {
  const SkinWorldGeo(this.h);
  final double h;

  /// The ground row (bench legs and the pole stand on it).
  double get ground => h - 116;

  Rect get pole => Rect.fromLTRB(296, ground - 470, 312, ground + 6);

  /// The bench top (front edge).
  double get benchTop => ground - 118;

  Rect get bench => Rect.fromLTRB(8, benchTop, 244, ground);

  /// The canvas roll hung on the bench's back rail.
  Rect get roll => Rect.fromLTRB(14, benchTop - 176, 216, benchTop - 6);

  /// Pocket [i] of [n] in the roll (a tool stands in it, blade up).
  Rect pocket(int i, int n) {
    final r = roll.deflate(8);
    final w = r.width / n;
    return Rect.fromLTWH(r.left + w * i + 2, r.top + 4, w - 4, r.height - 10);
  }

  /// Where the [i]th tool set aside lies, on the bench top (tagged বাতিল).
  Rect aside(int i) => Rect.fromLTWH(18 + i * 64.0, benchTop - 2, 60, 22);

  /// The cut-resistant gloves on the bench top.
  Rect get gloves => Rect.fromLTWH(118, benchTop - 34, 56, 34);

  /// The tester lying on the bench top.
  Rect get tester => Rect.fromLTWH(184, benchTop - 30, 54, 26);

  /// The tester held to the cable end.
  Rect get testerOn => Rect.fromLTWH(cableEnd.left + 4, cableEnd.top - 36, 54, 26);

  /// The cable's cut end in front of the pole (tap target, painted by [SkinCablePainter]).
  Rect get cableEnd => Rect.fromLTWH(206, ground - 268, 92, 30);

  /// The job card clipped to the pole, above the cable.
  Rect get jobCard => Rect.fromLTWH(232, ground - 400, 62, 96);

  /// The trainee, by the pole.
  Rect get trainee => Rect.fromLTWH(234, ground - 132, 66, 134);
}

class SkinWorldPainter extends CustomPainter {
  const SkinWorldPainter(this.geo);
  final SkinWorldGeo geo;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final h = s.height;
    final g = geo.ground;

    // Sky.
    final sky = Rect.fromLTWH(0, 0, w, g);
    c.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4A8BC6), Color(0xFF9DC7E4), Color(0xFFEAF0EC)],
          stops: [0, 0.6, 1],
        ).createShader(sky),
    );
    final sun = Offset(w * 0.18, math.max(80, g - 520));
    c.drawCircle(sun, 110, Paint()..shader = const RadialGradient(colors: [Color(0x80FFF6D8), Color(0x00FFF6D8)]).createShader(Rect.fromCircle(center: sun, radius: 110)));
    c.drawCircle(sun, 17, Paint()..color = const Color(0xFFFFF4CF));
    void cloud(double x, double y, double k) {
      final p = Paint()..color = const Color(0xE6FFFFFF);
      c.drawOval(Rect.fromCenter(center: Offset(x, y), width: 90 * k, height: 24 * k), p);
      c.drawCircle(Offset(x - 16 * k, y - 8 * k), 15 * k, p);
      c.drawCircle(Offset(x + 12 * k, y - 12 * k), 19 * k, p);
    }

    cloud(250, math.max(70, g - 560), 1.1);
    cloud(110, math.max(120, g - 470), 0.8);

    // Far: tree line and village roofs, hazy.
    final far = Paint()..color = const Color(0xFF9DB7A8);
    final trees = Path()..moveTo(0, g - 120);
    for (var x = 0.0; x <= w; x += 24) {
      trees.quadraticBezierTo(x + 12, g - 150 - (x * 7 % 23), x + 24, g - 122);
    }
    trees
      ..lineTo(w, g)
      ..lineTo(0, g)
      ..close();
    c.drawPath(trees, far);
    final roof = Paint()..color = const Color(0xFFB59A86);
    final wall = Paint()..color = const Color(0xFFD9CDBE);
    for (final x in [24.0, 132.0, 210.0]) {
      c.drawRect(Rect.fromLTWH(x, g - 96, 58, 50), wall);
      c.drawPath(
        Path()
          ..moveTo(x - 6, g - 96)
          ..lineTo(x + 29, g - 120)
          ..lineTo(x + 64, g - 96)
          ..close(),
        roof,
      );
      c.drawRect(Rect.fromLTWH(x + 22, g - 74, 14, 28), Paint()..color = const Color(0xFF8E7A68));
    }
    // A far line of poles.
    final farPole = Paint()..color = const Color(0xFF8FA6A0);
    for (final x in [60.0, 180.0]) {
      c.drawRect(Rect.fromLTWH(x, g - 210, 3, 150), farPole);
      c.drawRect(Rect.fromLTWH(x - 9, g - 206, 21, 2.4), farPole);
    }
    c.drawLine(Offset(0, g - 204), Offset(w, g - 198), Paint()
      ..color = const Color(0xFF8FA6A0)
      ..strokeWidth = 1);

    // Ground: verge and road edge.
    final field = Rect.fromLTWH(0, g - 46, w, h - g + 46);
    c.drawRect(
      field,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8E9B5A), Color(0xFF6A7540), Color(0xFF5A5F4A)],
          stops: [0, 0.45, 1],
        ).createShader(field),
    );
    c.drawRect(Rect.fromLTWH(0, g + 40, w, h - g - 40), Paint()..color = const Color(0xFF4F535A));
    c.drawRect(Rect.fromLTWH(0, g + 38, w, 3), Paint()..color = const Color(0xFFBFB9A6));

    // The pole (PCC), its cross-arm and insulators up top.
    final p = geo.pole;
    c.drawRect(p, Paint()..shader = const LinearGradient(colors: [Color(0xFFC4C2BA), Color(0xFF8E8C86)]).createShader(p));
    final arm = Rect.fromLTRB(p.left - 56, p.top + 22, p.right + 40, p.top + 30);
    c.drawRect(arm, Paint()..color = const Color(0xFF4F565D));
    final porcelain = Paint()..color = const Color(0xFFEDE7DA);
    for (final x in [arm.left + 8, arm.right - 8]) {
      c.drawOval(Rect.fromCenter(center: Offset(x, arm.top - 5), width: 12, height: 9), porcelain);
    }
    final line = Paint()
      ..color = const Color(0xFF2B2F35)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    c.drawLine(Offset(0, arm.top - 9), Offset(arm.left + 8, arm.top - 9), line);
    c.drawLine(Offset(arm.right - 8, arm.top - 9), Offset(w, arm.top - 7), line);
    // Danger plate (no text — the red band and bolt mark).
    final plate = Rect.fromLTWH(p.left - 1, p.top + 120, p.width + 2, 22);
    c.drawRect(plate, Paint()..color = const Color(0xFFF2EFE6));
    c.drawRect(Rect.fromLTWH(plate.left, plate.top, plate.width, 5), Paint()..color = const Color(0xFFC0392B));

    // The bench: top, front board, trestle legs; the back rail the roll hangs from.
    final b = geo.bench;
    final leg = Paint()..color = const Color(0xFF6B4A2B);
    for (final x in [b.left + 12, b.right - 22]) {
      c.drawRect(Rect.fromLTWH(x, b.top, 10, b.height), leg);
    }
    c.drawRect(Rect.fromLTWH(b.left + 12, b.top + b.height * 0.55, b.width - 24, 5), leg);
    final rail = Rect.fromLTRB(geo.roll.left - 4, geo.roll.top - 8, geo.roll.right + 4, geo.roll.top - 2);
    c.drawRect(Rect.fromLTWH(rail.left, rail.top, 5, b.top - rail.top), leg);
    c.drawRect(Rect.fromLTWH(rail.right - 5, rail.top, 5, b.top - rail.top), leg);
    c.drawRRect(RRect.fromRectAndRadius(rail, const Radius.circular(2)), Paint()..color = const Color(0xFF7D5A36));
    // The roll: canvas, stitched pockets.
    final roll = geo.roll;
    c.drawRRect(
      RRect.fromRectAndRadius(roll, const Radius.circular(6)),
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8C7A55), Color(0xFF6E5E40)]).createShader(roll),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(roll.deflate(4), const Radius.circular(4)),
      Paint()
        ..color = const Color(0xFFC9B98E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final pocket = Paint()..color = const Color(0xFF5C4E34);
    c.drawRect(Rect.fromLTRB(roll.left + 6, roll.bottom - 54, roll.right - 6, roll.bottom - 8), pocket);
    // Bench top.
    final top = Rect.fromLTRB(b.left, b.top - 8, b.right, b.top + 10);
    c.drawRect(top, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFB98A55), Color(0xFF8A6238)]).createShader(top));
    c.drawRect(Rect.fromLTRB(b.left, b.top + 10, b.right, b.top + 13), Paint()..color = const Color(0x55000000));

    // Shadows on the verge.
    c.drawOval(Rect.fromLTRB(b.left, g - 6, b.right, g + 8), Paint()..color = const Color(0x33000000));
  }

  @override
  bool shouldRepaint(SkinWorldPainter old) => old.geo.h != geo.h;
}

/// The service cable: down the pole, then its cut end hanging in front of it
/// — a small black wire, a grey LT PVC cable, or the black AB cable with its
/// bunched cores. [skinned]: the insulation is off a clean length and the
/// bright conductor shows (after a right job).
class SkinCablePainter extends CustomPainter {
  const SkinCablePainter({required this.geo, required this.cable, required this.skinned});
  final SkinWorldGeo geo;
  final SkinCable cable;
  final bool skinned;

  double get _thick => switch (cable) {
        SkinCable.wire => 5,
        SkinCable.ltPvc => 11,
        SkinCable.ab => 14,
      };

  Color get _skin => switch (cable) {
        SkinCable.wire => const Color(0xFF2A2C30),
        SkinCable.ltPvc => const Color(0xFF8D9399),
        SkinCable.ab => const Color(0xFF1B1D20),
      };

  @override
  void paint(Canvas c, Size s) {
    final p = geo.pole;
    final e = geo.cableEnd;
    final t = _thick;
    final cy = e.center.dy;
    final path = Path()
      ..moveTo(p.left - 2, p.top + 34)
      ..lineTo(p.left - 2, cy - 40)
      ..quadraticBezierTo(p.left - 2, cy, p.left - 30, cy)
      ..lineTo(e.left + 26, cy);
    final paint = Paint()
      ..color = _skin
      ..style = PaintingStyle.stroke
      ..strokeWidth = t
      ..strokeCap = StrokeCap.butt;
    c.drawPath(path, paint);
    // Clamps on the pole.
    final clamp = Paint()..color = const Color(0xFF9AA3AB);
    for (final y in [p.top + 80, p.top + 200, cy - 60]) {
      c.drawRect(Rect.fromLTWH(p.left - 2 - t / 2 - 2, y, t + 4, 5), clamp);
    }
    if (cable == SkinCable.ab) {
      // Bunched cores: the twist shows as slanted ridges.
      final ridge = Paint()
        ..color = const Color(0xFF3A3D42)
        ..strokeWidth = 1.4;
      for (var x = e.left + 30; x < p.left - 30; x += 7) {
        c.drawLine(Offset(x, cy - t / 2 + 1), Offset(x + 5, cy + t / 2 - 1), ridge);
      }
    } else {
      c.drawLine(Offset(e.left + 26, cy - t * 0.25), Offset(p.left - 30, cy - t * 0.25), Paint()
        ..color = const Color(0x33FFFFFF)
        ..strokeWidth = math.max(1, t * 0.18));
    }
    // The end: insulation to the cut, or the bright conductor once skinned.
    final endFrom = e.left + 6;
    if (skinned) {
      final cu = cable == SkinCable.ab ? const Color(0xFFC9CDD2) : const Color(0xFFE09A4F);
      final core = Rect.fromLTRB(endFrom, cy - t * 0.32, e.left + 28, cy + t * 0.32);
      c.drawRRect(RRect.fromRectAndRadius(core, Radius.circular(t * 0.2)), Paint()..color = cu);
      c.drawLine(Offset(core.left, cy - t * 0.12), Offset(core.right, cy - t * 0.12), Paint()
        ..color = const Color(0xCCFFFFFF)
        ..strokeWidth = 1.2);
      // The clean square edge of the insulation.
      c.drawRect(Rect.fromLTWH(e.left + 26, cy - t / 2, 2, t), Paint()..color = const Color(0xFF55585C));
    } else {
      c.drawLine(Offset(endFrom, cy), Offset(e.left + 27, cy), paint);
      c.drawOval(Rect.fromCenter(center: Offset(endFrom, cy), width: t * 0.5, height: t), Paint()..color = const Color(0xFF55585C));
      c.drawCircle(Offset(endFrom, cy), t * 0.22, Paint()..color = cable == SkinCable.ab ? const Color(0xFFC9CDD2) : const Color(0xFFE09A4F));
    }
  }

  @override
  bool shouldRepaint(SkinCablePainter old) => old.cable != cable || old.skinned != skinned || old.geo.h != geo.h;
}

/// How many stretches a blade is looked at in.
const kBladeBins = 14;

/// A tool drawn lengthwise, blade (or jaws) at the left, handle at the right:
/// the cable skinning knife (hook blade, orange handle), the wire stripper
/// (notched jaws, red handles), the AB cable stripper (yellow body with its
/// guide and blade), or the kitchen knife (wide blade, wooden handle).
/// A blade's flaw (blunt edge, grime and rust) shows only on stretches that
/// have been looked at ([seen]: bins of [kBladeBins]; null = all); unseen
/// stretches are washed with [veil] when it is set.
class SkinToolPainter extends CustomPainter {
  const SkinToolPainter({required this.tool, this.flaw = BladeFlaw.none, this.seen, this.veil});
  final SkinTool tool;
  final BladeFlaw flaw;
  final Set<int>? seen;
  final Color? veil;

  /// The blade's stretch along the width (0 … 1).
  static (double, double) bladeSpan(SkinTool t) => switch (t) {
        SkinTool.skinKnife => (0.06, 0.56),
        SkinTool.stripper => (0.06, 0.42),
        SkinTool.abTool => (0.1, 0.5),
        SkinTool.kitchen => (0.04, 0.62),
      };

  /// The bin under [u] (0 … 1 across the width), or null off the blade.
  static int? binAt(SkinTool t, double u) {
    final (a, b) = bladeSpan(t);
    if (u < a - 0.04 || u > b + 0.04) return null;
    return (((u - a) / (b - a)) * kBladeBins).floor().clamp(0, kBladeBins - 1);
  }

  /// Where along the blade the flaw shows (blunt / dirty), as bins.
  static Set<int> flawBins(BladeFlaw f) => switch (f) {
        BladeFlaw.none => const {},
        BladeFlaw.blunt => const {4, 5, 6, 7, 8, 9},
        BladeFlaw.dirty => const {2, 3, 9, 10},
      };

  /// The flaw is in view (false for a sound blade).
  static bool flawSeen(BladeFlaw f, Set<int>? seen) => f != BladeFlaw.none && (seen == null || flawBins(f).any(seen.contains));

  /// The whole blade has been looked over.
  static bool allSeen(Set<int>? seen) => seen == null || seen.length >= kBladeBins;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final h = s.height;
    final cy = h * 0.5;
    final (a, b) = bladeSpan(tool);
    final x0 = w * a;
    final x1 = w * b;
    final steel = Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFEFF2F4), Color(0xFFA9B1B8)]).createShader(Rect.fromLTRB(x0, cy - h * 0.3, x1, cy + h * 0.3));
    final outline = Paint()
      ..color = const Color(0xFF4A5056)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(0.8, h * 0.025);
    // The cutting edge runs along the blade's lower side at [edgeY].
    var edgeY = cy + h * 0.12;
    switch (tool) {
      case SkinTool.skinKnife:
        final blade = Path()
          ..moveTo(x1, cy - h * 0.14)
          ..lineTo(x0 + w * 0.05, cy - h * 0.14)
          ..quadraticBezierTo(x0 - w * 0.02, cy - h * 0.12, x0, cy + h * 0.06)
          ..quadraticBezierTo(x0 + w * 0.01, cy + h * 0.2, x0 + w * 0.05, cy + h * 0.08)
          ..lineTo(x0 + w * 0.06, cy + h * 0.12)
          ..lineTo(x1, cy + h * 0.12)
          ..close();
        c.drawPath(blade, steel);
        c.drawPath(blade, outline);
        final handle = RRect.fromRectAndRadius(Rect.fromLTRB(x1, cy - h * 0.2, w * 0.96, cy + h * 0.2), Radius.circular(h * 0.12));
        c.drawRRect(handle, Paint()..color = const Color(0xFFE8731C));
        final grip = Paint()..color = const Color(0xFF2B2B2B);
        for (var i = 0; i < 4; i++) {
          c.drawRect(Rect.fromLTWH(x1 + w * (0.06 + i * 0.08), cy - h * 0.2, w * 0.03, h * 0.4), grip);
        }
        c.drawRRect(handle, outline);
      case SkinTool.stripper:
        // Jaws: two flat jaws closed, the notches (sizes) along the edge.
        final jaw = Path()
          ..moveTo(x1, cy - h * 0.16)
          ..lineTo(x0 + w * 0.03, cy - h * 0.1)
          ..quadraticBezierTo(x0, cy, x0 + w * 0.03, cy + h * 0.1)
          ..lineTo(x1, cy + h * 0.16)
          ..close();
        c.drawPath(jaw, steel);
        c.drawPath(jaw, outline);
        c.drawLine(Offset(x0 + w * 0.02, cy), Offset(x1, cy), outline);
        final notch = Paint()..color = const Color(0xFF4A5056);
        for (var i = 0; i < 4; i++) {
          c.drawCircle(Offset(x0 + w * (0.09 + i * 0.07), cy), h * (0.035 + i * 0.01), notch);
        }
        edgeY = cy;
        // Pivot and handles.
        c.drawCircle(Offset(x1, cy), h * 0.08, Paint()..color = const Color(0xFF6E767D));
        final red = Paint()..color = const Color(0xFFC62828);
        c.drawPath(
            Path()
              ..moveTo(x1, cy - h * 0.12)
              ..lineTo(w * 0.96, cy - h * 0.3)
              ..lineTo(w * 0.96, cy - h * 0.14)
              ..lineTo(x1, cy - h * 0.02)
              ..close(),
            red);
        c.drawPath(
            Path()
              ..moveTo(x1, cy + h * 0.12)
              ..lineTo(w * 0.96, cy + h * 0.3)
              ..lineTo(w * 0.96, cy + h * 0.14)
              ..lineTo(x1, cy + h * 0.02)
              ..close(),
            red);
      case SkinTool.abTool:
        final body = RRect.fromRectAndRadius(Rect.fromLTRB(x0 - w * 0.04, cy - h * 0.26, x1 + w * 0.02, cy + h * 0.22), Radius.circular(h * 0.08));
        c.drawRRect(body, Paint()..color = const Color(0xFFF2C230));
        c.drawRRect(body, outline);
        // The V guide the cable sits in, and the blade across it.
        c.drawPath(
          Path()
            ..moveTo(x0, cy - h * 0.26)
            ..lineTo((x0 + x1) / 2, cy - h * 0.02)
            ..lineTo(x1, cy - h * 0.26)
            ..close(),
          Paint()..color = const Color(0xFF3B3F45),
        );
        final blade = Rect.fromLTRB(x0, cy + h * 0.02, x1, cy + h * 0.12);
        c.drawRect(blade, steel);
        c.drawRect(blade, outline);
        // Thumb screw (depth) and the black handle.
        c.drawCircle(Offset(x1 - w * 0.04, cy - h * 0.3), h * 0.06, Paint()..color = const Color(0xFF6E767D));
        final handle = RRect.fromRectAndRadius(Rect.fromLTRB(x1 + w * 0.02, cy - h * 0.14, w * 0.95, cy + h * 0.14), Radius.circular(h * 0.1));
        c.drawRRect(handle, Paint()..color = const Color(0xFF2E3136));
        c.drawRRect(handle, outline);
      case SkinTool.kitchen:
        final blade = Path()
          ..moveTo(x1, cy - h * 0.22)
          ..lineTo(x0 + w * 0.06, cy - h * 0.2)
          ..quadraticBezierTo(x0, cy - h * 0.12, x0, cy + h * 0.06)
          ..quadraticBezierTo(x0 + w * 0.12, cy + h * 0.16, x1, cy + h * 0.16)
          ..close();
        c.drawPath(blade, steel);
        c.drawPath(blade, outline);
        edgeY = cy + h * 0.14;
        final handle = RRect.fromRectAndRadius(Rect.fromLTRB(x1, cy - h * 0.15, w * 0.97, cy + h * 0.15), Radius.circular(h * 0.08));
        c.drawRRect(handle, Paint()..color = const Color(0xFF8A5A2B));
        c.drawRRect(handle, outline);
        final rivet = Paint()..color = const Color(0xFFD9DEE2);
        for (final u in const [0.7, 0.8, 0.9]) {
          c.drawCircle(Offset(w * u, cy), h * 0.035, rivet);
        }
    }

    // The edge: a keen dark line, or (where looked) the flaw.
    final bw = (x1 - x0) / kBladeBins;
    final shows = flawSeen(flaw, seen);
    c.drawLine(Offset(x0 + bw * 0.5, edgeY), Offset(x1, edgeY), Paint()
      ..color = const Color(0xFF30363C)
      ..strokeWidth = math.max(0.6, h * 0.012));
    if (shows) {
      final bins = flawBins(flaw);
      for (final i in bins) {
        if (seen != null && !seen!.contains(i)) continue;
        final r = Rect.fromLTWH(x0 + bw * i, edgeY - h * 0.05, bw, h * 0.1);
        if (flaw == BladeFlaw.blunt) {
          // A blunt edge is rounded: it catches the light as a bright band, with chips.
          c.drawRect(Rect.fromLTWH(r.left, edgeY - h * 0.03, r.width, h * 0.05), Paint()..color = const Color(0xFFFFFFFF));
          c.drawLine(Offset(r.left, edgeY + h * 0.02), Offset(r.right, edgeY + h * 0.02), Paint()
            ..color = const Color(0xFF6E767D)
            ..strokeWidth = math.max(1, h * 0.03));
          if (i.isEven) {
            c.drawPath(
              Path()
                ..moveTo(r.left + r.width * 0.3, edgeY + h * 0.02)
                ..lineTo(r.left + r.width * 0.5, edgeY - h * 0.03)
                ..lineTo(r.left + r.width * 0.7, edgeY + h * 0.02)
                ..close(),
              Paint()..color = const Color(0xFF4A5056),
            );
          }
        } else {
          // Grime and rust on the blade.
          final rust = Paint()..color = const Color(0xCC8A4B1E);
          final grime = Paint()..color = const Color(0xAA2E2418);
          c.drawCircle(Offset(r.center.dx, edgeY - h * 0.08), h * 0.045, rust);
          c.drawCircle(Offset(r.center.dx + bw * 0.3, edgeY - h * 0.02), h * 0.03, grime);
          c.drawCircle(Offset(r.center.dx - bw * 0.3, edgeY - h * 0.12), h * 0.025, rust);
        }
      }
    }

    // What has not been looked at yet is washed out.
    final v = veil;
    final sn = seen;
    if (v != null && sn != null) {
      final wash = Paint()..color = v.withValues(alpha: 0.62);
      for (var i = 0; i < kBladeBins; i++) {
        if (!sn.contains(i)) c.drawRect(Rect.fromLTWH(x0 + bw * i - 0.5, cy - h * 0.34, bw + 1, h * 0.62), wash);
      }
    }
  }

  @override
  bool shouldRepaint(SkinToolPainter old) =>
      old.tool != tool || old.flaw != flaw || old.veil != veil || !_same(old.seen, seen);

  static bool _same(Set<int>? a, Set<int>? b) {
    if (a == null || b == null) return a == b;
    return a.length == b.length && a.containsAll(b);
  }
}

/// The cut-resistant gloves lying on the bench (grey knit, a dotted palm).
class SkinGlovesPainter extends CustomPainter {
  const SkinGlovesPainter();

  @override
  void paint(Canvas c, Size s) {
    void glove(Offset o, double k, bool flip) {
      c.save();
      c.translate(o.dx, o.dy);
      if (flip) c.scale(-1, 1);
      final knit = Paint()..color = const Color(0xFF9AA5AE);
      final palm = Path()
        ..moveTo(0, s.height * 0.95)
        ..lineTo(0, s.height * 0.45)
        ..lineTo(-s.width * 0.04, s.height * 0.1)
        ..lineTo(s.width * 0.04, s.height * 0.1)
        ..lineTo(s.width * 0.06, s.height * 0.38)
        ..lineTo(s.width * 0.1, s.height * 0.02)
        ..lineTo(s.width * 0.17, s.height * 0.02)
        ..lineTo(s.width * 0.18, s.height * 0.36)
        ..lineTo(s.width * 0.24, s.height * 0.08)
        ..lineTo(s.width * 0.3, s.height * 0.12)
        ..lineTo(s.width * 0.3, s.height * 0.5)
        ..lineTo(s.width * 0.38, s.height * 0.42)
        ..lineTo(s.width * 0.4, s.height * 0.55)
        ..lineTo(s.width * 0.3, s.height * 0.95)
        ..close();
      c.drawPath(palm, knit);
      c.drawPath(
        palm,
        Paint()
          ..color = const Color(0xFF5E6870)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
      final dot = Paint()..color = const Color(0xFF3D4A57);
      for (var y = 0.55; y < 0.9; y += 0.12) {
        for (var x = 0.04; x < 0.28; x += 0.07) {
          c.drawCircle(Offset(s.width * x, s.height * y), 0.9, dot);
        }
      }
      c.drawRect(Rect.fromLTWH(0, s.height * 0.86, s.width * 0.3, s.height * 0.1), Paint()..color = const Color(0xFF2F6FB0));
      c.restore();
    }

    glove(Offset(s.width * 0.06, 0), 1, false);
    glove(Offset(s.width * 0.94, 0), 1, true);
  }

  @override
  bool shouldRepaint(SkinGlovesPainter old) => false;
}

/// The voltage tester (a pen-type detector): grey body, a lamp at the tip,
/// a small display. [state]: null = off, true = live (red lamp), false = no
/// voltage (green lamp).
class SkinTesterPainter extends CustomPainter {
  const SkinTesterPainter({this.state});
  final bool? state;

  @override
  void paint(Canvas c, Size s) {
    final cy = s.height * 0.55;
    final body = RRect.fromRectAndRadius(Rect.fromLTRB(s.width * 0.12, cy - s.height * 0.22, s.width * 0.98, cy + s.height * 0.22), Radius.circular(s.height * 0.2));
    c.drawRRect(body, Paint()..color = const Color(0xFF3B4148));
    c.drawRRect(Rect.fromLTRB(s.width * 0.55, cy - s.height * 0.22, s.width * 0.98, cy + s.height * 0.22).toRRect(s.height * 0.2), Paint()..color = const Color(0xFFF2C230));
    // Tip.
    c.drawPath(
      Path()
        ..moveTo(s.width * 0.12, cy - s.height * 0.16)
        ..lineTo(0, cy)
        ..lineTo(s.width * 0.12, cy + s.height * 0.16)
        ..close(),
      Paint()..color = const Color(0xFFDCE1E5),
    );
    final lit = state;
    final lamp = lit == null ? const Color(0xFF5A6068) : (lit ? const Color(0xFFFF3B30) : const Color(0xFF34C759));
    final at = Offset(s.width * 0.26, cy);
    if (lit != null) {
      c.drawCircle(at, s.height * 0.5, Paint()..shader = RadialGradient(colors: [lamp.withValues(alpha: 0.7), lamp.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: at, radius: s.height * 0.5)));
    }
    c.drawCircle(at, s.height * 0.13, Paint()..color = lamp);
  }

  @override
  bool shouldRepaint(SkinTesterPainter old) => old.state != state;
}

extension on Rect {
  RRect toRRect(double r) => RRect.fromRectAndRadius(this, Radius.circular(r));
}

/// The deadly move, staged in colour over the frozen scene: the blade bites
/// into a live cable's insulation, an arc flashes at the cut and the current
/// runs into the hand. (Illustrates "টেস্ট না করে লাইভ কেবিলে ছুরি".)
class SkinLiveFlashPainter extends CustomPainter {
  const SkinLiveFlashPainter({required this.t, required this.cable});
  final double t;
  final SkinCable cable;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final h = s.height;
    final bg = Rect.fromLTWH(0, 0, w, h);
    c.drawRect(bg, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF26313D), Color(0xFF111820)]).createShader(bg));
    final cy = h * 0.42;
    final thick = switch (cable) {
      SkinCable.wire => h * 0.05,
      SkinCable.ltPvc => h * 0.09,
      SkinCable.ab => h * 0.11,
    };
    // The cable across the panel.
    c.drawLine(Offset(0, cy), Offset(w, cy), Paint()
      ..color = cable == SkinCable.ltPvc ? const Color(0xFF8D9399) : const Color(0xFF1F2226)
      ..strokeWidth = thick);
    // A gloved hand with the knife pressing into it.
    final cut = Offset(w * 0.46, cy - thick * 0.2);
    final blade = Path()
      ..moveTo(cut.dx - w * 0.02, cut.dy)
      ..lineTo(cut.dx + w * 0.2, cut.dy - h * 0.2)
      ..lineTo(cut.dx + w * 0.24, cut.dy - h * 0.16)
      ..lineTo(cut.dx + w * 0.03, cut.dy + h * 0.02)
      ..close();
    c.drawPath(blade, Paint()..color = const Color(0xFFD5DADF));
    final handle = Path()
      ..moveTo(cut.dx + w * 0.2, cut.dy - h * 0.2)
      ..lineTo(cut.dx + w * 0.38, cut.dy - h * 0.38)
      ..lineTo(cut.dx + w * 0.42, cut.dy - h * 0.34)
      ..lineTo(cut.dx + w * 0.24, cut.dy - h * 0.16)
      ..close();
    c.drawPath(handle, Paint()..color = const Color(0xFFE8731C));
    final hand = Offset(cut.dx + w * 0.33, cut.dy - h * 0.3);
    c.drawCircle(hand, h * 0.09, Paint()..color = const Color(0xFF9AA5AE));
    // The arc at the cut and the current up the blade.
    final reach = (t / 0.5).clamp(0.0, 1.0);
    if (reach > 0) {
      final rng = math.Random(3 + (t * 14).floor());
      final arc = Path()..moveTo(cut.dx, cut.dy);
      for (var i = 1; i <= 10; i++) {
        final p = Offset.lerp(cut, hand, i / 10 * reach)! + Offset((rng.nextDouble() - 0.5) * 14, (rng.nextDouble() - 0.5) * 14);
        arc.lineTo(p.dx, p.dy);
      }
      c.drawPath(arc, Paint()
        ..color = const Color(0x8066B7FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
      c.drawPath(arc, Paint()
        ..color = const Color(0xFFE8F6FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2);
    }
    final f = t;
    final r = h * (0.08 + 0.3 * f);
    c.drawCircle(cut, r, Paint()..shader = RadialGradient(colors: [Color.fromRGBO(255, 250, 220, 0.95 * (1 - f * 0.4)), const Color(0x00FFC24A)]).createShader(Rect.fromCircle(center: cut, radius: r)));
    final spark = Paint()
      ..color = Color.fromRGBO(255, 236, 160, 1 - f * 0.4)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + 0.2;
      final d = Offset(math.cos(a), math.sin(a));
      c.drawLine(cut + d * (r * 0.5), cut + d * (r * 0.9), spark);
    }
  }

  @override
  bool shouldRepaint(SkinLiveFlashPainter old) => old.t != t || old.cable != cable;
}
