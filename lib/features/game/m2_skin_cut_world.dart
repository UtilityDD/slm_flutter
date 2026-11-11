import 'dart:math' as math;

import 'package:flutter/material.dart';

// The drawn world of lesson 2.6 কাজ 2 (m2_skin_cut.dart): a work bench at a
// job site, the trainee standing at its left end, an LT cable lying across
// the bench with its end pointing away from him (to the right), the lug for
// the job beside the cable end, the skinning knife. Design px: 360 wide, the
// scene's height (560–900).

/// What the stripped end of a cable shows under the lens (lesson point 3).
enum SkinFault { none, nick, strand, black, edge }

@immutable
class SkinGeo {
  const SkinGeo._(this.h, this.inset);

  factory SkinGeo.forScene(double height, double inset) => SkinGeo._(height, inset);

  final double h;
  final double inset;

  static const double endX = 322;
  static const double cableLeft = 52;
  static const double cableR = 12;
  static const double copperR = 7.5;

  double get horizonY => h * 0.40;
  double get benchTop => h * 0.50;
  double get benchBottom => benchTop + 100;
  double get groundY => h * 0.82;
  double get cableY => benchTop + 64;
  double get lugY => benchTop + 26;

  /// The bench round: three stripped ends, one under the other.
  double endRowY(int i) => benchTop + 20 + 30 * i;
  static const double endLeft = 92;
  static const double endRight = 306;
  static const double endBare = 56;

  /// The cable's strip zone for a mark [strip] px from the end.
  Rect stripZone(double strip) => Rect.fromLTRB(endX - strip, cableY - cableR, endX, cableY + cableR);

  /// The cable on the bench (taps and strokes).
  Rect get cableRect => Rect.fromLTRB(cableLeft + 30, cableY - 26, endX + 10, cableY + 26);

  /// One of the bench round's ends (a tap opens the lens).
  Rect endRect(int i) => Rect.fromLTRB(endLeft, endRowY(i) - 15, endRight + 8, endRowY(i) + 15);

  /// The trainee's box: at the bench's left end, facing it.
  Rect get traineeBox {
    const fh = 232.0;
    return Rect.fromLTWH(-34, groundY - fh + 6, fh / 2, fh);
  }

  @override
  bool operator ==(Object other) => other is SkinGeo && other.h == h && other.inset == inset;

  @override
  int get hashCode => Object.hash(h, inset);
}

/// The yard behind the bench and the bench itself (still; repaints only when
/// the geometry changes).
class SkinYardPainter extends CustomPainter {
  const SkinYardPainter({required this.geo});
  final SkinGeo geo;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final hz = geo.horizonY;
    // Sky.
    c.drawRect(
        Rect.fromLTWH(0, 0, w, hz + 2),
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF6FA8D8), Color(0xFFCFE3F0)])
              .createShader(Rect.fromLTWH(0, 0, w, hz)));
    // Far trees.
    final tree = Paint()..color = const Color(0xFF5E8B5A);
    for (var i = 0; i < 9; i++) {
      final x = i * 44.0 + 8;
      c.drawCircle(Offset(x, hz - 8 - (i % 3) * 5), 22 + (i % 2) * 6, tree);
    }
    // A distant pole with its lines.
    final pole = Paint()..color = const Color(0xFF8E9399);
    c.drawRect(Rect.fromLTWH(262, hz - 150, 6, 152), pole);
    c.drawRect(Rect.fromLTWH(238, hz - 140, 54, 5), pole);
    final wire = Paint()
      ..color = const Color(0xFF4A4F55)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (final x in [242.0, 265.0, 288.0]) {
      c.drawPath(Path()..moveTo(0, hz - 120)..quadraticBezierTo(x / 2, hz - 108, x, hz - 142), wire);
      c.drawPath(Path()..moveTo(x, hz - 142)..quadraticBezierTo((x + w) / 2, hz - 110, w, hz - 126), wire);
    }
    // Ground.
    c.drawRect(
        Rect.fromLTWH(0, hz, w, size.height - hz),
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF9DAF6E), Color(0xFF7A8B4E), Color(0xFF5F6B3C)])
              .createShader(Rect.fromLTWH(0, hz, w, size.height - hz)));
    // The van, far right, and a cable drum.
    final van = Rect.fromLTWH(210, hz - 34, 120, 52);
    c.drawRRect(RRect.fromRectAndRadius(van, const Radius.circular(8)), Paint()..color = const Color(0xFFE9ECEF));
    c.drawRect(Rect.fromLTWH(212, hz - 4, 116, 8), Paint()..color = const Color(0xFF1F5F8F));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(296, 0, 28, 20).shift(Offset(0, hz - 28)), const Radius.circular(3)), Paint()..color = const Color(0xFF9CC4E4));
    for (final x in [234.0, 306.0]) {
      c.drawCircle(Offset(x, hz + 18), 9, Paint()..color = const Color(0xFF22272E));
    }
    final drum = Offset(48, hz + 30);
    c.drawCircle(drum, 30, Paint()..color = const Color(0xFF8A5A32));
    c.drawCircle(drum, 20, Paint()..color = const Color(0xFF2B2B2E));
    c.drawCircle(drum, 8, Paint()..color = const Color(0xFF8A5A32));

    // The bench: its top (seen a little from above), its front, its legs.
    final top = Rect.fromLTRB(26, geo.benchTop, 352, geo.benchBottom);
    final legs = Paint()..color = const Color(0xFF5B3A1E);
    c.drawRect(Rect.fromLTRB(44, geo.benchBottom, 58, geo.groundY), legs);
    c.drawRect(Rect.fromLTRB(322, geo.benchBottom, 336, geo.groundY), legs);
    c.drawOval(Rect.fromLTRB(20, geo.groundY - 6, 360, geo.groundY + 10), Paint()..color = const Color(0x33000000));
    c.drawRect(
        top,
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFC89A62), Color(0xFFB0824C)])
              .createShader(top));
    final grain = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = geo.benchTop + i * 25.0;
      c.drawLine(Offset(top.left, y), Offset(top.right, y), grain);
    }
    c.drawRect(Rect.fromLTRB(26, geo.benchBottom, 352, geo.benchBottom + 22), Paint()..color = const Color(0xFF7A5230));
    c.drawLine(Offset(26, geo.benchBottom), Offset(352, geo.benchBottom), Paint()..color = const Color(0xFF5B3A1E)..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(SkinYardPainter old) => old.geo != geo;
}

/// A round of cutting: the cable, the lug beside it, the chalk mark, the
/// strokes so far and the sleeve sliding off at the end.
class SkinCablePainter extends CustomPainter {
  const SkinCablePainter({
    required this.geo,
    required this.barrel,
    required this.mark,
    required this.depth,
    required this.peel,
    required this.insulation,
  });

  final SkinGeo geo;

  /// The lug's barrel length (design px).
  final double barrel;

  /// The chalk mark, px from the end (null: not marked yet).
  final double? mark;

  /// How deep the strokes have gone (0–3; 3 = through to the conductor).
  final int depth;

  /// The cut sleeve sliding off the end (0 → 1).
  final double peel;

  /// The insulation's colour (the phase colour).
  final Color insulation;

  @override
  void paint(Canvas c, Size size) {
    final y = geo.cableY;
    const r = SkinGeo.cableR;
    const end = SkinGeo.endX;
    // The lug, lying beside the cable end: barrel over the strip length,
    // the palm with its hole beyond the end.
    final lugTop = geo.lugY - 8;
    final barrelRect = Rect.fromLTRB(end - barrel, lugTop, end, lugTop + 16);
    final tin = Paint()
      ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE6E9EC), Color(0xFF9AA3AB), Color(0xFFD5DADF)])
          .createShader(barrelRect);
    c.drawRRect(RRect.fromRectAndRadius(barrelRect, const Radius.circular(4)), tin);
    final palm = RRect.fromRectAndRadius(Rect.fromLTRB(end - 2, lugTop + 1, end + 30, lugTop + 15), const Radius.circular(7));
    c.drawRRect(palm, tin);
    c.drawCircle(Offset(end + 20, lugTop + 8), 3.6, Paint()..color = const Color(0xFF7A848D));
    // The barrel mouth.
    c.drawOval(Rect.fromLTRB(end - barrel - 2, lugTop, end - barrel + 4, lugTop + 16), Paint()..color = const Color(0xFF6E777F));
    c.drawLine(Offset(end - 2, lugTop + 1), Offset(end - 2, lugTop + 15), Paint()..color = const Color(0x55000000)..strokeWidth = 1);

    // The cable from the coil at his side to its end.
    final strip = mark;
    final through = depth >= 3;
    final keepRight = strip == null || !through ? end : end - strip;
    final ins = Paint()
      ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [
        Color.lerp(insulation, Colors.white, 0.35)!,
        insulation,
        Color.lerp(insulation, Colors.black, 0.35)!,
      ]).createShader(Rect.fromLTRB(0, y - r, 360, y + r));
    // The coil, back towards him.
    c.drawPath(
        Path()
          ..moveTo(keepRight, y)
          ..lineTo(SkinGeo.cableLeft + 24, y)
          ..quadraticBezierTo(SkinGeo.cableLeft - 8, y, SkinGeo.cableLeft - 18, y + 34),
        Paint()
          ..shader = ins.shader
          ..strokeWidth = r * 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.butt);

    if (through && strip != null) {
      // The bare conductor: bright copper strands.
      final bare = Rect.fromLTRB(end - strip, y - SkinGeo.copperR, end, y + SkinGeo.copperR);
      paintStrands(c, bare);
      // A clean square edge on the insulation.
      c.drawLine(Offset(end - strip, y - r), Offset(end - strip, y + r), Paint()..color = Color.lerp(insulation, Colors.black, 0.5)!..strokeWidth = 1.6);
      // The cut sleeve sliding off the end.
      if (peel < 1) {
        final dx = 120 * Curves.easeIn.transform(peel);
        final sleeve = Rect.fromLTRB(end - strip + dx + 2, y - r, end + dx, y + r);
        c.save();
        c.translate(0, 18 * peel);
        c.drawRRect(RRect.fromRectAndRadius(sleeve, const Radius.circular(3)), ins);
        c.restore();
      }
    } else {
      // The insulation to the end; the strokes shave the strip zone.
      c.drawRect(Rect.fromLTRB(end - 40, y - r, end, y + r), ins);
      c.drawOval(Rect.fromLTRB(end - 3, y - r, end + 3, y + r), Paint()..color = Color.lerp(insulation, Colors.black, 0.25)!);
      c.drawCircle(Offset(end + 0.5, y), SkinGeo.copperR - 1, Paint()..color = const Color(0xFFC97A3A));
      if (strip != null && depth > 0) {
        final zone = Rect.fromLTRB(end - strip, y - r, end, y + r);
        // Each stroke takes a shaving off: a lighter, flatter face.
        for (var i = 0; i < depth; i++) {
          final f = Rect.fromLTRB(zone.left + 2, zone.top + 2 + i * 3.5, zone.right - 2, zone.top + 7 + i * 3.5);
          c.drawRRect(RRect.fromRectAndRadius(f, const Radius.circular(2)), Paint()..color = Color.lerp(insulation, Colors.white, 0.5 + 0.12 * i)!);
        }
        c.drawLine(Offset(zone.left, zone.top + 1), Offset(zone.left - 4, zone.top + 4), Paint()..color = const Color(0x88000000)..strokeWidth = 1.2);
      }
    }
    // The chalk mark across the cable.
    if (strip != null && !through) {
      final x = end - strip;
      c.drawLine(Offset(x, y - r - 5), Offset(x, y + r + 5), Paint()
        ..color = const Color(0xFFFFE14D)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(SkinCablePainter old) =>
      old.geo != geo || old.barrel != barrel || old.mark != mark || old.depth != depth || old.peel != peel || old.insulation != insulation;
}

/// Copper strands seen from the side (a lay of short slanted stripes).
void paintStrands(Canvas c, Rect r, {double stripe = 5}) {
  c.drawRRect(
      RRect.fromRectAndRadius(r, Radius.circular(r.height * 0.3)),
      Paint()
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF7C27E), Color(0xFFD9893F), Color(0xFF9E5A22)])
            .createShader(r));
  final lay = Paint()
    ..color = const Color(0x66703A10)
    ..strokeWidth = math.max(0.8, stripe * 0.18);
  c.save();
  c.clipRRect(RRect.fromRectAndRadius(r, Radius.circular(r.height * 0.3)));
  for (var x = r.left - r.height; x < r.right + r.height; x += stripe) {
    c.drawLine(Offset(x, r.bottom), Offset(x + r.height * 0.7, r.top), lay);
  }
  c.restore();
}

/// The skinning knife lying on the bench (or in the hand, at [at]).
class SkinKnifePainter extends CustomPainter {
  const SkinKnifePainter({required this.at, required this.blunt, this.angle = -0.18});
  final Offset at;
  final bool blunt;
  final double angle;

  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(angle);
    // The handle (left), the blade (right; edge down, spine up).
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-46, -6, 36, 12), const Radius.circular(5)), Paint()..color = const Color(0xFF2C2C30));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-42, -4, 28, 3), const Radius.circular(2)), Paint()..color = const Color(0xFFFFD34E));
    final blade = Path()
      ..moveTo(-10, -5)
      ..lineTo(16, -5)
      ..quadraticBezierTo(26, -4, 28, 2)
      ..lineTo(-10, 5)
      ..close();
    c.drawPath(
        blade,
        Paint()
          ..color = blunt ? const Color(0xFF8C8F92) : const Color(0xFFDDE3E8));
    c.drawLine(const Offset(-10, 4.4), const Offset(27, 1.6), Paint()
      ..color = blunt ? const Color(0xFF6E6250) : Colors.white
      ..strokeWidth = 1.2);
    c.restore();
  }

  @override
  bool shouldRepaint(SkinKnifePainter old) => old.at != at || old.blunt != blunt || old.angle != angle;
}

/// The bench round: three stripped ends (somebody's work, to be checked).
class SkinBenchPainter extends CustomPainter {
  const SkinBenchPainter({required this.geo, required this.faults, required this.colours});
  final SkinGeo geo;
  final List<SkinFault> faults;
  final List<Color> colours;

  @override
  void paint(Canvas c, Size size) {
    for (var i = 0; i < faults.length; i++) {
      final y = geo.endRowY(i);
      const r = 10.0;
      final bareLeft = SkinGeo.endRight - SkinGeo.endBare;
      final col = colours[i % colours.length];
      final ins = Paint()
        ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [
          Color.lerp(col, Colors.white, 0.35)!,
          col,
          Color.lerp(col, Colors.black, 0.35)!,
        ]).createShader(Rect.fromLTRB(0, y - r, 360, y + r));
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(SkinGeo.endLeft, y - r, bareLeft, y + r), const Radius.circular(3)), ins);
      paintStrands(c, Rect.fromLTRB(bareLeft, y - 6, SkinGeo.endRight, y + 6), stripe: 4);
      // The small sign of the fault (seen properly only under the lens).
      switch (faults[i]) {
        case SkinFault.none:
          break;
        case SkinFault.nick:
          c.drawLine(Offset(bareLeft + 20, y - 6), Offset(bareLeft + 23, y - 1), Paint()..color = const Color(0xFF5A2E0E)..strokeWidth = 1.4);
        case SkinFault.strand:
          c.drawLine(Offset(bareLeft + 30, y - 5), Offset(bareLeft + 38, y - 12), Paint()..color = const Color(0xFFD9893F)..strokeWidth = 1.4);
        case SkinFault.black:
          c.drawCircle(Offset(bareLeft + 26, y), 3, Paint()..color = const Color(0xCC1A1410));
        case SkinFault.edge:
          final e = Path()..moveTo(bareLeft, y - r);
          for (var k = 0; k < 6; k++) {
            e.lineTo(bareLeft + (k.isEven ? 5 : -2), y - r + (k + 1) * (2 * r / 6));
          }
          c.drawPath(e, Paint()..color = Color.lerp(col, Colors.black, 0.5)!..strokeWidth = 1.4..style = PaintingStyle.stroke);
      }
    }
  }

  @override
  bool shouldRepaint(SkinBenchPainter old) => old.geo != geo || !_same(old.faults, faults);

  static bool _same(List<SkinFault> a, List<SkinFault> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Where a fault sits in the lens (fractions of the lens size).
Rect skinFaultRect(SkinFault f, Size s) => switch (f) {
      SkinFault.nick => Rect.fromCenter(center: Offset(s.width * 0.6, s.height * 0.36), width: s.width * 0.2, height: s.height * 0.32),
      SkinFault.strand => Rect.fromCenter(center: Offset(s.width * 0.72, s.height * 0.3), width: s.width * 0.24, height: s.height * 0.4),
      SkinFault.black => Rect.fromCenter(center: Offset(s.width * 0.64, s.height * 0.52), width: s.width * 0.22, height: s.height * 0.36),
      SkinFault.edge => Rect.fromCenter(center: Offset(s.width * 0.34, s.height * 0.5), width: s.width * 0.2, height: s.height * 0.8),
      SkinFault.none => Rect.zero,
    };

/// The stripped end under the lens: the insulation on the left with its cut
/// edge, the bare strands to the right, and the fault if there is one.
class SkinLensPainter extends CustomPainter {
  const SkinLensPainter({required this.fault, required this.colour});
  final SkinFault fault;
  final Color colour;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    c.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18)), Paint()..color = const Color(0xFFB98C58));
    final cy = h * 0.5;
    final insR = h * 0.3;
    final cuR = h * 0.19;
    final edgeX = w * 0.34;
    final ins = Paint()
      ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [
        Color.lerp(colour, Colors.white, 0.35)!,
        colour,
        Color.lerp(colour, Colors.black, 0.35)!,
      ]).createShader(Rect.fromLTRB(0, cy - insR, w, cy + insR));
    // The bare conductor (behind the edge).
    final bare = Rect.fromLTRB(edgeX - 6, cy - cuR, w * 0.92, cy + cuR);
    paintStrands(c, bare, stripe: h * 0.075);
    // The insulation with its cut edge.
    final insPath = Path()..moveTo(0, cy - insR);
    if (fault == SkinFault.edge) {
      insPath.lineTo(edgeX - 4, cy - insR);
      const teeth = [0.0, 14.0, 2.0, 18.0, -2.0, 12.0, 4.0, 16.0];
      for (var k = 0; k < teeth.length; k++) {
        insPath.lineTo(edgeX + teeth[k], cy - insR + (k + 1) * (2 * insR / teeth.length));
      }
      insPath.lineTo(edgeX - 6, cy + insR);
    } else {
      insPath.lineTo(edgeX, cy - insR);
      insPath.lineTo(edgeX, cy + insR);
    }
    insPath
      ..lineTo(0, cy + insR)
      ..close();
    c.drawPath(insPath, ins);
    c.drawPath(insPath, Paint()..color = Color.lerp(colour, Colors.black, 0.5)!..style = PaintingStyle.stroke..strokeWidth = 1.5);
    // The conductor's end face.
    c.drawOval(Rect.fromLTRB(w * 0.92 - 6, cy - cuR, w * 0.92 + 6, cy + cuR), Paint()..color = const Color(0xFFE6A160));
    switch (fault) {
      case SkinFault.none:
      case SkinFault.edge:
        break;
      case SkinFault.nick:
        final x = w * 0.6;
        final top = cy - cuR;
        c.drawPath(
            Path()
              ..moveTo(x - h * 0.06, top - 1)
              ..lineTo(x, top + cuR * 0.75)
              ..lineTo(x + h * 0.05, top - 1)
              ..close(),
            Paint()..color = const Color(0xFFB98C58));
        c.drawPath(
            Path()
              ..moveTo(x - h * 0.06, top)
              ..lineTo(x, top + cuR * 0.75)
              ..lineTo(x + h * 0.05, top),
            Paint()..color = const Color(0xFF5A2E0E)..style = PaintingStyle.stroke..strokeWidth = 1.6);
      case SkinFault.strand:
        final x = w * 0.66;
        final p = Paint()
          ..color = const Color(0xFFE3954A)
          ..strokeWidth = h * 0.035
          ..strokeCap = StrokeCap.round;
        c.drawLine(Offset(x, cy - cuR + 3), Offset(x + w * 0.08, cy - cuR - h * 0.16), p);
        c.drawLine(Offset(x + w * 0.04, cy - cuR + 3), Offset(x + w * 0.14, cy - cuR - h * 0.1), p);
        c.drawCircle(Offset(x + w * 0.08, cy - cuR - h * 0.16), h * 0.022, Paint()..color = const Color(0xFF9E5A22));
      case SkinFault.black:
        final dark = Paint()..color = const Color(0xE01A1410);
        c.drawOval(Rect.fromCenter(center: Offset(w * 0.64, cy), width: w * 0.12, height: cuR * 1.4), dark);
        c.drawCircle(Offset(w * 0.71, cy - cuR * 0.4), h * 0.03, dark);
    }
  }

  @override
  bool shouldRepaint(SkinLensPainter old) => old.fault != fault || old.colour != colour;
}

/// The knife's blade, close up: a sharp clean edge, or a dull, chipped,
/// rusty one (lesson point 1's daily check).
class SkinBladePainter extends CustomPainter {
  const SkinBladePainter({required this.blunt});
  final bool blunt;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    c.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(18)), Paint()..color = const Color(0xFF26303D));
    // Handle.
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.04, h * 0.38, w * 0.3, h * 0.24), Radius.circular(h * 0.1)), Paint()..color = const Color(0xFF111114));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.07, h * 0.42, w * 0.22, h * 0.05), Radius.circular(h * 0.02)), Paint()..color = const Color(0xFFFFD34E));
    // Blade.
    final blade = Path()
      ..moveTo(w * 0.33, h * 0.36)
      ..lineTo(w * 0.8, h * 0.36)
      ..quadraticBezierTo(w * 0.95, h * 0.4, w * 0.96, h * 0.56)
      ..lineTo(w * 0.33, h * 0.64)
      ..close();
    c.drawPath(
        blade,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: blunt ? const [Color(0xFF9A9C9E), Color(0xFF6D7073)] : const [Color(0xFFF4F7FA), Color(0xFFB7C1CA)],
          ).createShader(Rect.fromLTWH(w * 0.33, h * 0.36, w * 0.63, h * 0.28)));
    // The edge.
    final edge = Path()..moveTo(w * 0.33, h * 0.635);
    if (blunt) {
      // Chips along a dull, rounded edge.
      for (var k = 1; k <= 12; k++) {
        final x = w * 0.33 + k * (w * 0.63 / 12);
        final y = h * 0.635 - k * (h * 0.075 / 12);
        edge.lineTo(x - w * 0.02, y + (k.isEven ? -h * 0.03 : 0));
        edge.lineTo(x, y);
      }
    } else {
      edge.lineTo(w * 0.96, h * 0.56);
    }
    c.drawPath(edge, Paint()
      ..color = blunt ? const Color(0xFF4F4A42) : Colors.white
      ..strokeWidth = blunt ? 3 : 2
      ..style = PaintingStyle.stroke);
    if (blunt) {
      final rust = Paint()..color = const Color(0xCC8A4B1C);
      for (final (fx, fy, fr) in const [(0.5, 0.52, 0.035), (0.62, 0.45, 0.025), (0.74, 0.55, 0.03), (0.42, 0.44, 0.02)]) {
        c.drawCircle(Offset(w * fx, h * fy), h * fr, rust);
      }
    } else {
      c.drawLine(Offset(w * 0.4, h * 0.42), Offset(w * 0.78, h * 0.41), Paint()..color = const Color(0xAAFFFFFF)..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(SkinBladePainter old) => old.blunt != blunt;
}
