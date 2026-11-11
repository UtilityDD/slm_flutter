import 'dart:math' as math;

import 'package:flutter/material.dart';

// The store yard before line work (lesson 3.1, কাজ 1 "কোন তার কোনটা"): a drawn
// yard — sky, the store shed at the back with its corrugated roof and drums
// stacked inside, the boundary wall, the van backed in on the right (its bed
// takes the drums that are loaded), a post on the left with the docket's
// clipboard nail, and the gravel ground the conductor drums stand on (the drums
// are widgets, drawn by [M3ConductorIdDrumPainter]). No text in the art.
// Design: 360 wide × any height; everything stands on the ground row, so a
// tall phone gets more sky, never a stretched yard.

/// Where things are, in design pixels (360 × [h]).
@immutable
class M3ConductorIdGeo {
  const M3ConductorIdGeo(this.h);
  final double h;

  /// The ground row the drums stand on.
  double get ground => h - 112;

  /// The shed's floor line at the back (the far ground).
  double get back => ground - 120;

  /// Drum place [i] of three in the front row.
  Rect drum(int i) => Rect.fromLTWH(70 + i * 96.0, ground - 92, 92, 100);

  /// The van's bed (right, midground): loaded drum [i] sits on it.
  Rect get bed => Rect.fromLTWH(212, back - 30, 140, 30);
  Rect loaded(int i) => Rect.fromLTWH(bed.left + 6 + i * 44.0, bed.top - 38, 40, 40);

  /// The docket's clipboard on its post, left.
  Rect get docket => Rect.fromLTWH(8, back - 150, 74, 120);

  /// The trainee, at the left of the drum row.
  Rect get trainee => Rect.fromLTWH(-4, ground - 128, 70, 140);
}

class M3ConductorIdYardPainter extends CustomPainter {
  const M3ConductorIdYardPainter(this.geo);
  final M3ConductorIdGeo geo;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final g = geo.ground;
    final back = geo.back;

    // Sky.
    final sky = Rect.fromLTWH(0, 0, w, back);
    c.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6FA6D6), Color(0xFFBFDCEE), Color(0xFFE6EEE6)],
          stops: [0, 0.75, 1],
        ).createShader(sky),
    );
    final cloud = Paint()..color = const Color(0xCCFFFFFF);
    for (final (x, y, r) in [(60.0, back - 300, 18.0), (86.0, back - 296, 24.0), (112.0, back - 302, 16.0), (262.0, back - 340, 20.0), (290.0, back - 336, 15.0)]) {
      if (y > 70) c.drawCircle(Offset(x, y), r, cloud);
    }
    // Far trees over the wall.
    final tree = Paint()..color = const Color(0xFF5E8A5A);
    for (var x = -10.0; x < w + 20; x += 34) {
      c.drawCircle(Offset(x, back - 92 + (x % 3) * 3), 22, tree);
    }

    // The store shed at the back: brick wall, a dark open bay, corrugated roof.
    final shed = Rect.fromLTRB(96, back - 112, 330, back);
    c.drawRect(shed, Paint()..color = const Color(0xFFB0674A));
    final mortar = Paint()
      ..color = const Color(0x33FFFFFF)
      ..strokeWidth = 0.8;
    for (var y = shed.top + 8; y < shed.bottom; y += 8) {
      c.drawLine(Offset(shed.left, y), Offset(shed.right, y), mortar);
    }
    final bay = Rect.fromLTRB(shed.left + 20, shed.top + 24, shed.right - 20, shed.bottom);
    c.drawRect(bay, Paint()..color = const Color(0xFF2E2A27));
    // Drums stacked in the bay (far, small, in the dark).
    for (var i = 0; i < 5; i++) {
      final cx = bay.left + 22 + i * 40.0;
      c.drawCircle(Offset(cx, bay.bottom - 18), 17, Paint()..color = const Color(0xFF6A4E33));
      c.drawCircle(Offset(cx, bay.bottom - 18), 5, Paint()..color = const Color(0xFF3A3A3A));
    }
    final roof = Path()
      ..moveTo(shed.left - 14, shed.top + 4)
      ..lineTo(shed.left + 6, shed.top - 22)
      ..lineTo(shed.right - 6, shed.top - 22)
      ..lineTo(shed.right + 14, shed.top + 4)
      ..close();
    c.drawPath(roof, Paint()..color = const Color(0xFF8E979E));
    final rib = Paint()
      ..color = const Color(0x44000000)
      ..strokeWidth = 1;
    for (var x = shed.left - 8; x < shed.right + 10; x += 9) {
      c.drawLine(Offset(x, shed.top + 3), Offset(x + 6, shed.top - 21), rib);
    }

    // The boundary wall left and right of the shed.
    final wall = Paint()..color = const Color(0xFFD9D2C3);
    c.drawRect(Rect.fromLTRB(0, back - 44, shed.left, back), wall);
    c.drawRect(Rect.fromLTRB(shed.right, back - 44, w, back), wall);
    c.drawRect(Rect.fromLTRB(0, back - 46, shed.left, back - 42), Paint()..color = const Color(0xFFBDB4A2));

    // The ground: packed gravel, lighter toward the back.
    final ground = Rect.fromLTWH(0, back, w, s.height - back);
    c.drawRect(
      ground,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB9AC92), Color(0xFF9C8E74), Color(0xFF7F725B)],
          stops: [0, 0.6, 1],
        ).createShader(ground),
    );
    final rng = math.Random(7);
    final pebble = Paint()..color = const Color(0x33000000);
    for (var i = 0; i < 70; i++) {
      final y = back + rng.nextDouble() * (s.height - back);
      c.drawCircle(Offset(rng.nextDouble() * w, y), 0.8 + rng.nextDouble() * 1.4, pebble);
    }
    // The drums' shadows on the ground.
    for (var i = 0; i < 3; i++) {
      final r = geo.drum(i);
      c.drawOval(Rect.fromLTWH(r.left + 2, g - 2, r.width - 4, 14), Paint()..color = const Color(0x33000000));
    }

    // The van, backed in on the right: cab beyond the bed, the open tailgate.
    final bed = geo.bed;
    final cab = Rect.fromLTWH(bed.right - 40, bed.top - 52, 40, 52);
    c.drawRRect(RRect.fromRectAndRadius(cab, const Radius.circular(6)), Paint()..color = const Color(0xFF2F6DB5));
    c.drawRect(Rect.fromLTWH(cab.left + 6, cab.top + 8, 26, 18), Paint()..color = const Color(0xFFBFD8EC));
    c.drawRect(Rect.fromLTWH(bed.left, bed.top, bed.width - 40, bed.height), Paint()..color = const Color(0xFF3B79C2));
    c.drawRect(Rect.fromLTWH(bed.left, bed.top, bed.width - 40, 4), Paint()..color = const Color(0xFF24558F));
    for (final x in [bed.left + 18, bed.right - 30]) {
      c.drawCircle(Offset(x, bed.bottom + 4), 10, Paint()..color = const Color(0xFF1F2328));
      c.drawCircle(Offset(x, bed.bottom + 4), 4, Paint()..color = const Color(0xFF9AA0A5));
    }

    // The docket's post and nail.
    final d = geo.docket;
    c.drawRect(Rect.fromLTWH(d.center.dx - 4, d.top - 10, 8, back - d.top + 10), Paint()..color = const Color(0xFF7A5A36));
    c.drawCircle(Offset(d.center.dx, d.top - 4), 2.4, Paint()..color = const Color(0xFF3A3F45));
  }

  @override
  bool shouldRepaint(M3ConductorIdYardPainter old) => old.geo.h != geo.h;
}

// ---------------------------------------------------------------------------
// The conductor, drawn
// ---------------------------------------------------------------------------

const _alLight = Color(0xFFE6EAED);
const _alDark = Color(0xFF9EA7AF);
const _stLight = Color(0xFF8C969E);
const _stDark = Color(0xFF4C545B);

/// A conductor drum seen from the side, a little turned: the front flange (a
/// wooden disc with its steel hub and a weathered tag whose print has faded),
/// the barrel's wraps of bare conductor showing over its rim, and the free
/// end tied down at the top with its cut face out. ACSR and AAAC look alike
/// from here.
class M3ConductorIdDrumPainter extends CustomPainter {
  const M3ConductorIdDrumPainter({this.gone = false});

  /// Loaded or set aside: drawn faint.
  final bool gone;

  @override
  void paint(Canvas c, Size s) {
    final r = math.min(s.width, s.height) * 0.46;
    final centre = Offset(s.width * 0.52, s.height - r - 2);
    if (gone) {
      c.saveLayer(Offset.zero & s, Paint()..color = const Color(0x55FFFFFF));
    }
    // The back flange (offset) and the wraps between.
    final backC = centre + Offset(-r * 0.22, -r * 0.06);
    c.drawCircle(backC, r, Paint()..color = const Color(0xFF6E4F31));
    final wraps = Rect.fromCircle(center: Offset.lerp(backC, centre, 0.5)!, radius: r * 0.9);
    c.drawCircle(
      wraps.center,
      wraps.width / 2,
      Paint()
        ..shader = const RadialGradient(colors: [_alLight, _alDark], stops: [0.6, 1]).createShader(wraps),
    );
    // The front flange: planks and a dark rim.
    final front = Rect.fromCircle(center: centre, radius: r);
    c.drawCircle(
      centre,
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB8875A), Color(0xFF8E6440)],
        ).createShader(front),
    );
    c.save();
    c.clipPath(Path()..addOval(front));
    final plank = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 1;
    for (var x = front.left; x < front.right; x += r * 0.34) {
      c.drawLine(Offset(x, front.top), Offset(x, front.bottom), plank);
    }
    c.restore();
    c.drawCircle(
        centre,
        r,
        Paint()
          ..color = const Color(0xFF5A3E25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2);
    // The steel hub and its bolts.
    c.drawCircle(centre, r * 0.2, Paint()..color = const Color(0xFF7D858C));
    c.drawCircle(centre, r * 0.09, Paint()..color = const Color(0xFF2B2F33));
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2 + 0.6;
      c.drawCircle(centre + Offset(math.cos(a), math.sin(a)) * r * 0.32, 1.6, Paint()..color = const Color(0xFF3B3F44));
    }
    // The weathered tag: a tin plate, its print washed out.
    final tag = Rect.fromCenter(center: centre + Offset(0, r * 0.56), width: r * 0.78, height: r * 0.3);
    c.drawRRect(RRect.fromRectAndRadius(tag, const Radius.circular(2)), Paint()..color = const Color(0xFFD8D3C4));
    final faded = Paint()
      ..color = const Color(0x33555B63)
      ..strokeWidth = 1.4;
    for (var i = 0; i < 2; i++) {
      final y = tag.top + tag.height * (0.35 + 0.32 * i);
      c.drawLine(Offset(tag.left + 4, y), Offset(tag.right - 4 - i * 6, y), faded);
    }
    c.drawCircle(tag.topLeft + const Offset(4, 4), 0.9, Paint()..color = const Color(0xFF8A6A3A));
    // The free end: over the top of the flange, tied, its cut face out.
    final top = centre + Offset(r * 0.1, -r * 0.98);
    final endP = top + Offset(r * 0.62, -r * 0.18);
    final cond = Paint()
      ..color = _alDark
      ..strokeWidth = r * 0.12
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    c.drawPath(
      Path()
        ..moveTo(top.dx - r * 0.5, top.dy + r * 0.12)
        ..quadraticBezierTo(top.dx, top.dy - r * 0.14, endP.dx, endP.dy),
      cond,
    );
    // The binding wire.
    c.drawLine(top + Offset(-r * 0.18, -r * 0.06), top + Offset(-r * 0.18, r * 0.12), Paint()
      ..color = const Color(0xFF3A3F45)
      ..strokeWidth = 1.6);
    // The cut face: a dull disc (grime hides what is inside).
    c.drawCircle(endP, r * 0.09, Paint()..color = const Color(0xFF8A8478));
    c.drawCircle(endP, r * 0.09, Paint()
      ..color = const Color(0xFF55524B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);
    if (gone) c.restore();
  }

  @override
  bool shouldRepaint(M3ConductorIdDrumPainter old) => old.gone != gone;
}

/// The strand layout of a conductor's cut face: centre ring first.
/// [steelRings] of the inner rings are galvanised steel (ACSR), the rest
/// aluminium (alloy for AAAC).
@immutable
class M3ConductorIdLayout {
  const M3ConductorIdLayout({required this.rings, required this.steelRings});

  /// Strands per ring from the centre: 1, 6, 12, 18 …
  final List<int> rings;
  final int steelRings;
}

/// How many cells (per side) the grime on a cut face is cleaned in.
const kM3ConductorIdGrid = 6;

/// The cut face, up close: strands in rings — steel ones darker and duller
/// than aluminium — under a crust of grime that comes off cell by cell where
/// a thumb has rubbed ([cleared]: indices `row * grid + col`; null = clean).
class M3ConductorIdEndPainter extends CustomPainter {
  const M3ConductorIdEndPainter({required this.layout, this.cleared});
  final M3ConductorIdLayout layout;
  final Set<int>? cleared;

  /// The cell under [p] in a face of size [s].
  static int cellAt(Size s, Offset p) {
    final col = (p.dx / s.width * kM3ConductorIdGrid).floor().clamp(0, kM3ConductorIdGrid - 1);
    final row = (p.dy / s.height * kM3ConductorIdGrid).floor().clamp(0, kM3ConductorIdGrid - 1);
    return row * kM3ConductorIdGrid + col;
  }

  /// The four centre cells: once they are clean the core shows.
  static const coreCells = {14, 15, 20, 21};

  static bool coreSeen(Set<int>? cleared) => cleared == null || coreCells.every(cleared.contains);

  @override
  void paint(Canvas c, Size s) {
    final centre = s.center(Offset.zero);
    final rad = math.min(s.width, s.height) * 0.46;
    final n = layout.rings.length;
    // Strand radius so the outer ring just fits.
    final sr = rad / (2 * n - 1);
    c.drawCircle(centre, rad + 1.5, Paint()..color = const Color(0xFF3A3F45));
    for (var ring = 0; ring < n; ring++) {
      final count = layout.rings[ring];
      final steel = ring < layout.steelRings;
      for (var k = 0; k < count; k++) {
        final a = count == 1 ? 0.0 : 2 * math.pi * k / count + ring * 0.2;
        final p = centre + Offset(math.cos(a), math.sin(a)) * (2 * sr * ring);
        final r = Rect.fromCircle(center: p, radius: sr * 0.96);
        c.drawCircle(
          p,
          sr * 0.96,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-0.35, -0.35),
              colors: steel ? const [_stLight, _stDark] : const [_alLight, _alDark],
            ).createShader(r),
        );
        if (steel) {
          // Galvanised: a faint zinc spangle.
          c.drawCircle(p + Offset(sr * 0.2, sr * 0.15), sr * 0.18, Paint()..color = const Color(0x33DDE4EA));
        }
      }
    }
    // The grime: a crust over every cell not yet rubbed clean.
    final cl = cleared;
    if (cl != null) {
      final cw = s.width / kM3ConductorIdGrid;
      final ch = s.height / kM3ConductorIdGrid;
      c.save();
      c.clipPath(Path()..addOval(Rect.fromCircle(center: centre, radius: rad + 2)));
      final crust = Paint()..color = const Color(0xF0776E5F);
      final fleck = Paint()..color = const Color(0x66453E33);
      for (var row = 0; row < kM3ConductorIdGrid; row++) {
        for (var col = 0; col < kM3ConductorIdGrid; col++) {
          if (cl.contains(row * kM3ConductorIdGrid + col)) continue;
          final cell = Rect.fromLTWH(col * cw - 0.5, row * ch - 0.5, cw + 1, ch + 1);
          c.drawRect(cell, crust);
          c.drawCircle(cell.center + Offset(cw * 0.15 * ((row + col) % 3 - 1), ch * 0.1), cw * 0.12, fleck);
        }
      }
      c.restore();
    }
  }

  @override
  bool shouldRepaint(M3ConductorIdEndPainter old) => old.layout != layout || old.cleared?.length != cleared?.length;
}

/// How many stretches the outer wraps are looked at in.
const kM3ConductorIdBins = 20;
int m3ConductorIdBin(double u) => (u * kM3ConductorIdBins).floor().clamp(0, kM3ConductorIdBins - 1);

/// The outer wraps on the drum, up close: one length of stranded conductor
/// running across, its strands laid in a helix. [cutU] (0..1, null = sound)
/// is where one strand is cut, its end sprung out — it shows only once its
/// stretch has been looked at ([seen]: stretches of [kM3ConductorIdBins];
/// null = all seen); unseen stretches are washed with a dull veil.
class M3ConductorIdWrapPainter extends CustomPainter {
  const M3ConductorIdWrapPainter({this.cutU, this.seen});
  final double? cutU;
  final Set<int>? seen;

  static const pad = 10.0;
  static double uAt(Size s, double x) => ((x - pad) / (s.width - 2 * pad)).clamp(0.0, 1.0);
  static double xAt(Size s, double u) => pad + u * (s.width - 2 * pad);

  static bool cutSeen(double? cutU, Set<int>? seen) {
    if (cutU == null) return false;
    return seen == null || seen.contains(m3ConductorIdBin(cutU));
  }

  @override
  void paint(Canvas c, Size s) {
    final h = s.height;
    final band = Rect.fromLTRB(pad, h * 0.3, s.width - pad, h * 0.7);
    c.drawRRect(
      RRect.fromRectAndRadius(band, Radius.circular(band.height / 2)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_alLight, Color(0xFFC3CAD0), _alDark],
        ).createShader(band),
    );
    // The lay: diagonal strand lines.
    final lay = Paint()
      ..color = const Color(0x55525A62)
      ..strokeWidth = 1.2;
    c.save();
    c.clipRRect(RRect.fromRectAndRadius(band, Radius.circular(band.height / 2)));
    final step = band.height * 0.42;
    final cu = cutU;
    for (var x = band.left - band.height; x < band.right + band.height; x += step) {
      if (cu != null && (x + band.height / 2 - xAt(s, cu)).abs() < step * 0.6 && cutSeen(cu, seen)) continue;
      c.drawLine(Offset(x, band.bottom), Offset(x + band.height, band.top), lay);
    }
    c.restore();
    if (cu != null && cutSeen(cu, seen)) {
      // One strand cut: a gap in the lay and its end sprung up and out.
      final x = xAt(s, cu);
      c.drawLine(Offset(x - band.height * 0.5, band.bottom - 1), Offset(x - 2, band.top + band.height * 0.3), Paint()
        ..color = const Color(0xFF3B4148)
        ..strokeWidth = 2.2);
      final spring = Path()
        ..moveTo(x, band.top + band.height * 0.25)
        ..quadraticBezierTo(x + 6, band.top - 10, x + 18, band.top - 16);
      c.drawPath(
          spring,
          Paint()
            ..color = const Color(0xFFB8C0C7)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.2
            ..strokeCap = StrokeCap.round);
      c.drawPath(
          spring,
          Paint()
            ..color = const Color(0xFF6E777F)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1);
    }
    // The veil over stretches not yet looked at.
    final sn = seen;
    if (sn != null) {
      final veil = Paint()..color = const Color(0x99404852);
      for (var i = 0; i < kM3ConductorIdBins; i++) {
        if (sn.contains(i)) continue;
        final x0 = xAt(s, i / kM3ConductorIdBins);
        final x1 = xAt(s, (i + 1) / kM3ConductorIdBins);
        c.drawRect(Rect.fromLTRB(x0, 0, x1 + 0.5, h), veil);
      }
    }
  }

  @override
  bool shouldRepaint(M3ConductorIdWrapPainter old) => old.cutU != cutU || old.seen?.length != seen?.length;
}

/// A horseshoe magnet (red, with steel pole tips), drawn pointing left.
class M3ConductorIdMagnetPainter extends CustomPainter {
  const M3ConductorIdMagnetPainter();

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final h = s.height;
    final arm = h * 0.3;
    final body = Path()
      ..moveTo(0, 0)
      ..lineTo(w - h / 2, 0)
      ..arcToPoint(Offset(w - h / 2, h), radius: Radius.circular(h / 2))
      ..lineTo(0, h)
      ..lineTo(0, h - arm)
      ..lineTo(w - h / 2, h - arm)
      ..arcToPoint(Offset(w - h / 2, arm), radius: Radius.circular(h / 2 - arm), clockwise: false)
      ..lineTo(0, arm)
      ..close();
    c.drawPath(body, Paint()..color = const Color(0xFFD23B2E));
    c.drawRect(Rect.fromLTWH(0, 0, w * 0.18, arm), Paint()..color = const Color(0xFFC9CED2));
    c.drawRect(Rect.fromLTWH(0, h - arm, w * 0.18, arm), Paint()..color = const Color(0xFFC9CED2));
  }

  @override
  bool shouldRepaint(M3ConductorIdMagnetPainter old) => false;
}
