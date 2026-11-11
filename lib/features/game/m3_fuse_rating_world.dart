import 'dart:math' as math;

import 'package:flutter/material.dart';

// The roadside for lesson 3.4, কাজ 1 "সঠিক ফিউজ তার": a drawn scene — sky,
// a far tree line, a road verge; the line van on the left; a DTR on its
// double-pole structure on the right (the transformer tank with its plate,
// the three DO fuse mounts on the cross-arm, their barrels already down at
// the van); and a folding table in front with the fuse-wire reels (the reels,
// the plate's print and the trainee are widgets on it). No text in the art.
// Design: 360 wide × any height; the ground row sits on the bottom, so a tall
// phone gets more sky, never a stretched yard.
//
// Also here: a reel (link spool, thick copper coil, plain GI wire), the DO
// fuse barrel up close (its contacts and the link inside it), and the fire
// of the deadly consequence (a transformer burning on a bodged fuse).

/// Where things are, in design pixels (360 × [h]).
@immutable
class M3FuseRatingGeo {
  const M3FuseRatingGeo(this.h);
  final double h;

  /// The table's top edge (the back of its top).
  double get base => h - 262;

  /// The table, seen from the front and a little above.
  Rect get tableTop => Rect.fromLTRB(96, base, 360, base + 34);
  Rect get tableFront => Rect.fromLTRB(96, base + 34, 360, base + 48);

  /// Compartment [i] of [n] on the table: a reel stands in it.
  Rect slot(int i, int n) {
    const l = 106.0, r = 352.0;
    final w = (r - l) / n;
    return Rect.fromLTWH(l + w * i, base - 34, w, 62);
  }

  /// Reels put aside (wrong ones), on the ground in front of the table.
  Rect aside(int i) => Rect.fromLTWH(110 + i * 40.0, base + 54, 36, 34);

  /// The trainee, standing left of the table in front of the van.
  Rect get trainee => Rect.fromLTWH(4, base - 92, 84, 168);

  /// The van, behind the trainee.
  Rect get van => Rect.fromLTRB(-34, base - 118, 168, base - 6);

  /// The DTR's two poles.
  double get poleL => 262;
  double get poleR => 336;
  double get poleTop => base - 276;

  /// The platform channel the tank stands on.
  double get platformY => base - 132;

  /// The transformer tank.
  Rect get tank => Rect.fromLTRB(270, base - 204, 328, platformY);

  /// The rating plate on the tank's face.
  Rect get plate => Rect.fromLTRB(283, base - 186, 315, base - 166);

  /// Tap here to read the plate close.
  Rect get plateTap => tank.inflate(10);

  /// The cross-arm with the three DO fuse mounts.
  double get armY => base - 248;
  List<double> get doX => const [266, 299, 332];

  /// Where the fire of the deadly consequence sits.
  Offset get fireAt => Offset(tank.center.dx, tank.top + 6);
}

const _skyTop = Color(0xFF7DB5E0);
const _skyLow = Color(0xFFDDEBEF);
const _steel = Color(0xFF8A939C);
const _steelDark = Color(0xFF5B636B);

/// The yard: sky, far trees, the road verge, the van and the DTR structure.
/// [round] picks the tank's paint (each DTR on the docket looks a little different).
class M3FuseRatingYardPainter extends CustomPainter {
  const M3FuseRatingYardPainter(this.geo, {this.round = 0});
  final M3FuseRatingGeo geo;
  final int round;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final g = geo;
    final sky = Rect.fromLTWH(0, 0, w, g.base - 40);
    c.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_skyTop, _skyLow],
        ).createShader(sky),
    );
    // Clouds.
    final cloud = Paint()..color = const Color(0xCCFFFFFF);
    for (final (x, y, r) in [(60.0, g.base - 330, 18.0), (200.0, g.base - 360, 14.0), (150.0, g.base - 300, 11.0)]) {
      c.drawOval(Rect.fromCenter(center: Offset(x, y), width: r * 4.2, height: r * 1.5), cloud);
      c.drawCircle(Offset(x - r * 0.6, y - r * 0.4), r * 0.8, cloud);
      c.drawCircle(Offset(x + r * 0.5, y - r * 0.5), r * 0.65, cloud);
    }
    // The far tree line and fields.
    final far = Path()..moveTo(0, g.base - 40);
    for (var x = 0.0; x <= w + 20; x += 20) {
      far.quadraticBezierTo(x + 10, g.base - 64 - 10 * math.sin(x * 0.07), x + 20, g.base - 44);
    }
    far
      ..lineTo(w, g.base - 30)
      ..lineTo(0, g.base - 30)
      ..close();
    c.drawPath(far, Paint()..color = const Color(0xFF7FA37A));
    c.drawRect(Rect.fromLTRB(0, g.base - 44, w, g.base - 26), Paint()..color = const Color(0xFF9DBB78));
    // The road (grey) and the verge (earth, in front).
    c.drawRect(Rect.fromLTRB(0, g.base - 28, w, g.base - 4), Paint()..color = const Color(0xFF8F8C86));
    c.drawRect(Rect.fromLTRB(0, g.base - 17, w, g.base - 15), Paint()..color = const Color(0xFFE9E2C8));
    final verge = Rect.fromLTRB(0, g.base - 6, w, s.height);
    c.drawRect(
      verge,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB79A6E), Color(0xFF8C7048)],
        ).createShader(verge),
    );
    final tuft = Paint()
      ..color = const Color(0xFF6E8A4A)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final rng = math.Random(7);
    for (var i = 0; i < 26; i++) {
      final x = rng.nextDouble() * w;
      final y = g.base + 4 + rng.nextDouble() * (s.height - g.base - 10);
      c.drawLine(Offset(x, y), Offset(x - 3, y - 6), tuft);
      c.drawLine(Offset(x, y), Offset(x + 2, y - 7), tuft);
    }

    _structure(c);
    _van(c);
  }

  void _structure(Canvas c) {
    final g = geo;
    // The HT line overhead (three conductors to the pole tops).
    final wire = Paint()
      ..color = const Color(0xFF3C4148)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 3; i++) {
      final y = g.poleTop + 6 + i * 3.0;
      c.drawPath(
        Path()
          ..moveTo(-4, y - 18)
          ..quadraticBezierTo(140, y + 14, g.poleL, y),
        wire,
      );
    }
    // The poles.
    for (final x in [g.poleL, g.poleR]) {
      final r = Rect.fromLTRB(x - 4.5, g.poleTop, x + 4.5, g.base - 2);
      c.drawRect(
        r,
        Paint()
          ..shader = const LinearGradient(colors: [Color(0xFFB9B4AA), Color(0xFF8E897F), Color(0xFF6F6A61)]).createShader(r),
      );
    }
    // The cross-arm with the three DO mounts (barrels down: only the
    // porcelain and the empty top and hinge contacts).
    final arm = Rect.fromLTRB(g.poleL - 12, g.armY - 3, g.poleR + 14, g.armY + 3);
    c.drawRect(arm, Paint()..color = _steelDark);
    for (final x in g.doX) {
      final por = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, g.armY + 18), width: 7, height: 26), const Radius.circular(3));
      c.drawRRect(por, Paint()..color = const Color(0xFF7A4A2E));
      for (var k = 0; k < 4; k++) {
        c.drawOval(Rect.fromCenter(center: Offset(x, g.armY + 9 + k * 6.0), width: 12, height: 3.4), Paint()..color = const Color(0xFF8C5636));
      }
      // Empty top contact (above) and hinge (below), offset to one side.
      c.drawRect(Rect.fromLTWH(x + 3, g.armY + 4, 7, 3), Paint()..color = const Color(0xFFC9A24A));
      c.drawRect(Rect.fromLTWH(x + 3, g.armY + 30, 7, 4), Paint()..color = const Color(0xFFC9A24A));
      // The jumper down to the tank's bushing.
      c.drawPath(
        Path()
          ..moveTo(x + 8, g.armY + 34)
          ..quadraticBezierTo(x + 2, g.armY + 60, g.tank.left + 10 + (x - g.doX.first) * 0.55, g.tank.top - 12),
        wire,
      );
    }
    // The platform channel.
    c.drawRect(Rect.fromLTRB(g.poleL - 14, g.platformY, g.poleR + 14, g.platformY + 6), Paint()..color = _steelDark);
    c.drawRect(Rect.fromLTRB(g.poleL - 14, g.platformY + 6, g.poleR + 14, g.platformY + 8), Paint()..color = const Color(0xFF41474D));
    // The tank: radiator fins, body, lid, HT bushings.
    final t = g.tank;
    final paint = const [Color(0xFF8D9BA3), Color(0xFF7F9A86), Color(0xFF98A0A6)][round % 3];
    final fin = Paint()..color = Color.lerp(paint, Colors.black, 0.25)!;
    for (var i = 0; i < 4; i++) {
      c.drawRect(Rect.fromLTWH(t.left - 6, t.top + 12 + i * 12.0, 6, 8), fin);
      c.drawRect(Rect.fromLTWH(t.right, t.top + 12 + i * 12.0, 6, 8), fin);
    }
    c.drawRRect(
      RRect.fromRectAndRadius(t, const Radius.circular(3)),
      Paint()
        ..shader = LinearGradient(colors: [Color.lerp(paint, Colors.white, 0.25)!, paint, Color.lerp(paint, Colors.black, 0.3)!]).createShader(t),
    );
    c.drawRect(Rect.fromLTRB(t.left - 3, t.top - 4, t.right + 3, t.top + 2), Paint()..color = Color.lerp(paint, Colors.black, 0.35)!);
    for (var i = 0; i < 3; i++) {
      final x = t.left + 10 + i * 19.0;
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 3, t.top - 16, 6, 13), const Radius.circular(2)), Paint()..color = const Color(0xFF8C5636));
    }
    // The plate (blank: its print is a widget).
    final p = g.plate;
    c.drawRect(p.inflate(1.2), Paint()..color = const Color(0xFF5E666C));
    c.drawRect(p, Paint()..color = const Color(0xFFDCD9CC));
  }

  void _van(Canvas c) {
    final v = geo.van;
    // Body.
    final body = RRect.fromRectAndCorners(v, topLeft: const Radius.circular(6), topRight: const Radius.circular(16), bottomRight: const Radius.circular(4));
    c.drawRRect(body.shift(const Offset(0, 3)), Paint()..color = const Color(0x33000000));
    c.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF2F0E8), Color(0xFFD9D5C8)],
        ).createShader(v),
    );
    // A stripe and the windows (cab on the right).
    c.drawRect(Rect.fromLTRB(v.left, v.bottom - 40, v.right, v.bottom - 32), Paint()..color = const Color(0xFF2F6FB0));
    c.drawRRect(
      RRect.fromRectAndCorners(Rect.fromLTRB(v.right - 46, v.top + 10, v.right - 8, v.top + 38), topRight: const Radius.circular(10)),
      Paint()..color = const Color(0xFF6E94AE),
    );
    c.drawRect(Rect.fromLTRB(v.left + 40, v.top + 12, v.right - 60, v.top + 34), Paint()..color = const Color(0xFF8AA9BC));
    // Wheels.
    for (final x in [v.left + 52, v.right - 30]) {
      c.drawCircle(Offset(x, v.bottom), 13, Paint()..color = const Color(0xFF22252A));
      c.drawCircle(Offset(x, v.bottom), 6, Paint()..color = _steel);
    }
  }

  @override
  bool shouldRepaint(M3FuseRatingYardPainter old) => old.geo.h != geo.h || old.round != round;
}

/// The folding table in front.
class M3FuseRatingTablePainter extends CustomPainter {
  const M3FuseRatingTablePainter(this.geo);
  final M3FuseRatingGeo geo;

  @override
  void paint(Canvas c, Size s) {
    final top = geo.tableTop;
    final front = geo.tableFront;
    final leg = Paint()
      ..color = const Color(0xFF4E555C)
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(top.left + 14, front.bottom), Offset(top.left + 6, front.bottom + 66), leg);
    c.drawLine(Offset(top.right - 10, front.bottom), Offset(top.right - 4, front.bottom + 66), leg);
    c.drawOval(Rect.fromLTRB(top.left - 4, front.bottom + 56, top.right + 8, front.bottom + 74), Paint()..color = const Color(0x30000000));
    c.drawRect(
      top,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6C7884), Color(0xFF8A96A1)],
        ).createShader(top),
    );
    c.drawRect(front, Paint()..color = const Color(0xFF3E4750));
    c.drawRect(Rect.fromLTRB(front.left, front.top, front.right, front.top + 2), Paint()..color = const Color(0xFFA9B4BE));
  }

  @override
  bool shouldRepaint(M3FuseRatingTablePainter old) => old.geo.h != geo.h;
}

/// The kinds of wire the van carries (mirrors the page's reel kinds).
enum M3FuseRatingWire { link, copper, plain }

/// A reel standing on the table (or held up): a link spool (thin tinned
/// wire on a small drum with a tag), a thick copper coil, or plain GI wire.
class M3FuseRatingReelPainter extends CustomPainter {
  const M3FuseRatingReelPainter(this.wire, {this.big = false});
  final M3FuseRatingWire wire;
  final bool big;

  @override
  void paint(Canvas c, Size s) {
    final cx = s.width / 2;
    final r = math.min(s.width, s.height) * 0.42;
    final centre = Offset(cx, s.height - r - 2);
    c.drawOval(Rect.fromCenter(center: Offset(cx, s.height - 2), width: r * 2.1, height: r * 0.4), Paint()..color = const Color(0x40000000));
    switch (wire) {
      case M3FuseRatingWire.link:
        // A drum: two flanges, a winding of thin silver wire, a paper tag.
        final drum = Rect.fromCenter(center: centre, width: r * 1.5, height: r * 1.8);
        c.drawRRect(RRect.fromRectAndRadius(drum.deflate(r * 0.12), Radius.circular(r * 0.2)), Paint()..color = const Color(0xFFCFD5DA));
        final wind = Paint()
          ..color = const Color(0xFF9AA3AA)
          ..strokeWidth = big ? 1.2 : 0.7;
        for (var y = drum.top + r * 0.2; y < drum.bottom - r * 0.15; y += big ? 3 : 2) {
          c.drawLine(Offset(drum.left + r * 0.14, y), Offset(drum.right - r * 0.14, y + 1), wind);
        }
        final flange = Paint()..color = const Color(0xFF2F3A44);
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(drum.left - r * 0.1, drum.top, r * 0.22, drum.height), Radius.circular(r * 0.08)), flange);
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(drum.right - r * 0.12, drum.top, r * 0.22, drum.height), Radius.circular(r * 0.08)), flange);
        // The tag on a string.
        final tag = Rect.fromLTWH(drum.center.dx - r * 0.42, drum.top - r * 0.05, r * 0.84, r * 0.5);
        c.drawLine(Offset(tag.center.dx, tag.top), Offset(tag.center.dx, drum.top - r * 0.2), Paint()
          ..color = const Color(0xFF6B5B3E)
          ..strokeWidth = 0.8);
        c.drawRRect(RRect.fromRectAndRadius(tag, Radius.circular(r * 0.06)), Paint()..color = const Color(0xFFF4E7B8));
        c.drawRRect(
          RRect.fromRectAndRadius(tag, Radius.circular(r * 0.06)),
          Paint()
            ..style = PaintingStyle.stroke
            ..color = const Color(0xFFB59A4E)
            ..strokeWidth = 0.8,
        );
      case M3FuseRatingWire.copper:
      case M3FuseRatingWire.plain:
        // A loose coil: thick copper (bright orange, fat strokes) or GI
        // binding wire (dull grey, thin).
        final cu = wire == M3FuseRatingWire.copper;
        final col = cu ? const Color(0xFFC9702F) : const Color(0xFF8E979C);
        final hi = cu ? const Color(0xFFF2B27A) : const Color(0xFFC4CBCF);
        final sw = (cu ? 0.16 : 0.06) * r;
        for (var i = 0; i < (cu ? 4 : 7); i++) {
          final o = Rect.fromCenter(center: centre.translate((i - 2) * r * 0.05, (i - 2) * r * 0.03), width: r * 1.9, height: r * 1.55);
          c.drawOval(o, Paint()
            ..style = PaintingStyle.stroke
            ..color = col
            ..strokeWidth = sw);
          c.drawArc(o, math.pi * 1.1, math.pi * 0.5, false, Paint()
            ..style = PaintingStyle.stroke
            ..color = hi
            ..strokeWidth = sw * 0.4);
        }
        // A loose end.
        c.drawPath(
          Path()
            ..moveTo(centre.dx + r * 0.9, centre.dy)
            ..quadraticBezierTo(centre.dx + r * 1.15, centre.dy - r * 0.7, centre.dx + r * 0.7, centre.dy - r * 1.05),
          Paint()
            ..style = PaintingStyle.stroke
            ..color = col
            ..strokeWidth = sw
            ..strokeCap = StrokeCap.round,
        );
    }
  }

  @override
  bool shouldRepaint(M3FuseRatingReelPainter old) => old.wire != wire || old.big != big;
}

/// Where the barrel's parts are inside its close-up box.
@immutable
class M3FuseRatingBarrelGeo {
  const M3FuseRatingBarrelGeo(this.size);
  final Size size;

  double get cy => size.height * 0.42;
  double get tubeH => size.height * 0.30;

  /// The fibre tube.
  Rect get tube => Rect.fromLTRB(size.width * 0.18, cy - tubeH / 2, size.width * 0.70, cy + tubeH / 2);

  /// The top cap with its contact (left end).
  Rect get topContact => Rect.fromLTRB(size.width * 0.03, cy - tubeH * 0.62, size.width * 0.19, cy + tubeH * 0.62);

  /// The bottom ferrule with the hinge contact (right end).
  Rect get bottomContact => Rect.fromLTRB(size.width * 0.69, cy - tubeH * 0.66, size.width * 0.83, cy + tubeH * 0.66);

  /// The link's tail comes out of the bottom end to the wing-nut terminal.
  Offset get tailFrom => Offset(size.width * 0.80, cy + tubeH * 0.66);
  Offset get terminal => Offset(size.width * 0.90, size.height * 0.86);

  /// The strip where the tail is pulled (drag right to pull it taut).
  Rect get pullStrip => Rect.fromLTRB(size.width * 0.70, size.height * 0.62, size.width, size.height);
}

/// The DO fuse barrel up close: the tube cut away to show the link inside,
/// the top and bottom contacts (soot on them fades as it is wiped:
/// [soot] 0 = clean … 1 = black), and the link's tail to the terminal
/// ([tension] 0 = hanging slack … 1 = taut; null = no link yet).
class M3FuseRatingBarrelPainter extends CustomPainter {
  const M3FuseRatingBarrelPainter({required this.sootTop, required this.sootBottom, this.tension, this.linkColor = const Color(0xFFB8C0C6)});
  final double sootTop;
  final double sootBottom;
  final double? tension;
  final Color linkColor;

  @override
  void paint(Canvas c, Size s) {
    final g = M3FuseRatingBarrelGeo(s);
    final tube = g.tube;
    // Tube: brown fibre, with a cut-away window.
    c.drawRRect(
      RRect.fromRectAndRadius(tube, Radius.circular(tube.height * 0.2)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB98A55), Color(0xFF8A5E33), Color(0xFF5E3C1E)],
        ).createShader(tube),
    );
    final win = Rect.fromLTRB(tube.left + tube.width * 0.08, tube.top + tube.height * 0.24, tube.right - tube.width * 0.06, tube.bottom - tube.height * 0.24);
    c.drawRRect(RRect.fromRectAndRadius(win, const Radius.circular(3)), Paint()..color = const Color(0xFF2B1C10));
    // The link inside (straight when taut).
    final t = tension;
    if (t != null) {
      final link = Paint()
        ..color = linkColor
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      c.drawLine(Offset(g.topContact.right - 4, g.cy), Offset(win.right, g.cy), link);
      // The tail from the bottom end to the terminal: sags when slack.
      final sag = (1 - t.clamp(0.0, 1.0)) * s.height * 0.32;
      final a = g.tailFrom;
      final b = g.terminal;
      final mid = Offset((a.dx + b.dx) / 2 - sag * 0.4, (a.dy + b.dy) / 2 + sag);
      c.drawLine(Offset(win.right, g.cy), Offset(g.bottomContact.right - 6, g.cy), link);
      c.drawPath(
        Path()
          ..moveTo(g.bottomContact.right - 6, g.cy)
          ..quadraticBezierTo(g.bottomContact.right + 2, g.cy + 4, a.dx, a.dy)
          ..quadraticBezierTo(mid.dx, mid.dy, b.dx, b.dy),
        link..strokeWidth = 2.2,
      );
    }
    // The contacts: brass, with soot.
    _contact(c, g.topContact, sootTop, cap: true);
    _contact(c, g.bottomContact, sootBottom, cap: false);
    // The hinge trunnion under the bottom contact.
    c.drawCircle(Offset(g.bottomContact.center.dx, g.bottomContact.bottom + 4), s.height * 0.05, Paint()..color = const Color(0xFF9C7B2E));
    // The wing-nut terminal.
    final tm = g.terminal;
    c.drawCircle(tm, s.height * 0.05, Paint()..color = const Color(0xFFB9963F));
    c.drawCircle(tm, s.height * 0.022, Paint()..color = const Color(0xFF5C4614));
    c.drawLine(tm.translate(-s.height * 0.08, 0), tm.translate(s.height * 0.08, 0), Paint()
      ..color = const Color(0xFFB9963F)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round);
  }

  void _contact(Canvas c, Rect r, double soot, {required bool cap}) {
    final rr = RRect.fromRectAndRadius(r, Radius.circular(r.height * (cap ? 0.22 : 0.12)));
    c.drawRRect(
      rr,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF1D58A), Color(0xFFC9A24A), Color(0xFF8E6E22)],
        ).createShader(r),
    );
    if (soot <= 0.01) {
      // A clean shine.
      c.drawLine(r.topLeft.translate(r.width * 0.2, r.height * 0.22), r.topRight.translate(-r.width * 0.2, r.height * 0.22), Paint()
        ..color = const Color(0xAAFFFFFF)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round);
      return;
    }
    c.save();
    c.clipRRect(rr);
    final a = soot.clamp(0.0, 1.0);
    final black = Paint()..color = Color.fromRGBO(24, 20, 16, 0.85 * a);
    final rng = math.Random(cap ? 3 : 5);
    for (var i = 0; i < 9; i++) {
      final p = Offset(r.left + rng.nextDouble() * r.width, r.top + rng.nextDouble() * r.height);
      c.drawOval(Rect.fromCenter(center: p, width: r.width * (0.3 + rng.nextDouble() * 0.4), height: r.height * (0.2 + rng.nextDouble() * 0.3)), black);
    }
    c.restore();
  }

  @override
  bool shouldRepaint(M3FuseRatingBarrelPainter old) =>
      old.sootTop != sootTop || old.sootBottom != sootBottom || old.tension != tension || old.linkColor != linkColor;
}

/// The deadly consequence: the transformer burning — the fuse with thick
/// copper in it never blew. [v] 0…1 grows the fire.
class M3FuseRatingFirePainter extends CustomPainter {
  const M3FuseRatingFirePainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas c, Size s) {
    final k = Curves.easeOut.transform(v.clamp(0.0, 1.0));
    if (k <= 0) return;
    // Smoke.
    for (var i = 0; i < 5; i++) {
      final p = at.translate(-20 + i * 9.0, -50 - 24.0 * i * k);
      c.drawCircle(p, (14 + i * 6) * k, Paint()..color = Color.fromRGBO(40, 38, 36, 0.35 * k));
    }
    // Glow.
    c.drawCircle(
      at,
      70 * k,
      Paint()
        ..shader = RadialGradient(colors: [Color.fromRGBO(255, 170, 40, 0.55 * k), const Color(0x00FF8800)]).createShader(Rect.fromCircle(center: at, radius: 70 * k)),
    );
    // Flames: tongues of orange and yellow.
    for (var i = 0; i < 5; i++) {
      final x = at.dx - 26 + i * 13.0;
      final hgt = (34 + (i.isEven ? 16 : 0)) * k;
      final f = Path()
        ..moveTo(x - 9, at.dy + 6)
        ..quadraticBezierTo(x - 10, at.dy - hgt * 0.5, x + (i.isEven ? 3 : -3), at.dy - hgt)
        ..quadraticBezierTo(x + 10, at.dy - hgt * 0.45, x + 9, at.dy + 6)
        ..close();
      c.drawPath(f, Paint()..color = const Color(0xFFF2611D));
      final inner = Path()
        ..moveTo(x - 4, at.dy + 6)
        ..quadraticBezierTo(x - 5, at.dy - hgt * 0.3, x, at.dy - hgt * 0.62)
        ..quadraticBezierTo(x + 5, at.dy - hgt * 0.3, x + 4, at.dy + 6)
        ..close();
      c.drawPath(inner, Paint()..color = const Color(0xFFFFD34D));
    }
  }

  @override
  bool shouldRepaint(M3FuseRatingFirePainter old) => old.v != v || old.at != at;
}
