import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The drawn world of lesson 6.10 কাজ 2 "মিটার বদল, ছবিতে প্রমাণ"
// (m6_meter_swap_proof.dart).
//
// One house wall at a time (three in the lane), daytime: the service cable
// comes from a pole on the left (its fuse is out of reach) to the meter's
// incoming cut-out (a porcelain base with its carrier), then down to the
// meter's incoming terminal. The meter sits in its box on a board: an old
// disc meter (the aluminium disc and the drum counter) or an old electronic
// meter (an LCD and a push-button), a seal on the body and one on the
// terminal cover, all alike until tugged. The consumer's main switch box is
// on the right and the house cable goes in through the wall. Every wall has
// a second dark cable (a TV cable from the roof, or a bypass tapped off the
// service cable before the cut-out) and small dark things on top of, beside
// and under the box (a cable clip, a mud nest, a rubber grommet, or a
// magnet): at this size they look alike; a close look shows what they are.
//
// No text in the art except what a worker reads (the meter's own screen).
// Code-drawn, gradients, no bitmaps. Design: 360 wide × the scene's height
// (560–900); a tall phone gets more sky, never a stretched wall.

/// The old meter on the wall (lesson 6.10 point 1): a disc meter with a drum
/// counter, or an electronic meter with an LCD and a push-button.
enum M6SwapMeter { disc, lcd }

/// The two seals on the old meter (lesson 6.10 point 4).
enum M6SwapSeal { body, terminal }

/// The close-look places: on top of the box, beside it, under it, and the
/// service cable just before the cut-out.
enum M6SwapSpot { top, side, under, junction }

/// A harmless dark thing at a spot.
enum M6SwapDecoy { clip, nest, grommet }

/// What a meter's screen shows now (the drum is the disc meter's counter).
enum M6SwapScreen { kwh, kw, volt, amp, tamper, blank, drum }

/// What a close look finds.
enum M6SwapThing { magnet, clip, nest, grommet, bypass, cable }

/// The tester's two places on the cut-out: the line side (fed from the pole;
/// a known live point) and the load side (to the meter).
enum M6SwapPoint { line, load }

/// Where things are (design px, 360 wide).
@immutable
class M6SwapGeo {
  const M6SwapGeo._(this.height, this.bT, this.groundY);

  factory M6SwapGeo.forScene(double height, double inset) {
    final g = height - floorUp - inset * 0.5;
    // High enough that the guide's bubble (over the bottom of the scene)
    // never covers a seal or a close-look place.
    final top = math.max(150.0, g - 372);
    return M6SwapGeo._(height, top, g);
  }

  final double height;

  /// The board's top line (everything on the wall hangs from it).
  final double bT;

  /// The ground line (the tool row stands under it).
  final double groundY;

  /// The ground sits this far above the bottom.
  static const double floorUp = 112;

  // --- the pole and the service cable ----------------------------------------
  static const double poleX = 18;
  Offset get poleTop => Offset(poleX + 6, bT - 18);

  // --- the cut-out ------------------------------------------------------------
  static const double cutX = 84;
  Rect get cutBase => Rect.fromLTWH(cutX - 20, bT + 38, 40, 74);
  Offset get lineContact => Offset(cutX, bT + 46);
  Offset get loadContact => Offset(cutX, bT + 104);

  /// The carrier in its base, or pulled out (hanging lower).
  Rect carrier(bool inBase) => inBase ? Rect.fromLTWH(cutX - 17, bT + 54, 34, 42) : Rect.fromLTWH(cutX - 17, bT + 128, 34, 42);
  Rect carrierHit(bool inBase) => inBase ? Rect.fromLTWH(cutX - 20, bT + 58, 40, 32) : Rect.fromLTWH(cutX - 20, bT + 126, 40, 46);

  /// The tester's places (the line contact and the load contact).
  Rect pointHit(M6SwapPoint p) => Rect.fromCenter(center: p == M6SwapPoint.line ? lineContact : loadContact, width: 44, height: 18);

  // --- the meter box ------------------------------------------------------------
  Rect get box => Rect.fromLTWH(124, bT + 8, 118, 192);
  Rect get meter => Rect.fromLTWH(138, bT + 22, 90, 158);
  Rect get screen => Rect.fromLTWH(148, bT + 40, 58, 24);
  Offset get button => Offset(216, bT + 52);
  Rect get buttonHit => Rect.fromCenter(center: button, width: 30, height: 30);
  Rect get disc => Rect.fromLTWH(154, bT + 76, 58, 14);
  Rect get terminalCover => Rect.fromLTWH(144, bT + 140, 78, 34);

  /// The box itself, for the screwdriver (the cover's area, not the seals).
  Rect get boxHit => Rect.fromLTWH(140, bT + 104, 80, 34);

  Offset seal(M6SwapSeal s) => s == M6SwapSeal.body ? Offset(236, bT + 86) : Offset(183, bT + 184);
  Rect sealHit(M6SwapSeal s) => Rect.fromCenter(center: seal(s), width: 30, height: 30);

  // --- the close-look places ------------------------------------------------------
  Offset spot(M6SwapSpot s) => switch (s) {
        M6SwapSpot.top => Offset(170, bT + 2),
        M6SwapSpot.side => Offset(120, bT + 150),
        M6SwapSpot.under => Offset(183, bT + 222),
        M6SwapSpot.junction => Offset(40, bT + 24),
      };
  Rect spotHit(M6SwapSpot s) => Rect.fromCenter(center: spot(s), width: s == M6SwapSpot.junction ? 34 : 30, height: s == M6SwapSpot.junction ? 30 : 26);

  /// Where the close look's bubble sits for [s] (clear of the spot).
  Offset lookAt(M6SwapSpot s) => switch (s) {
        M6SwapSpot.top => Offset(282, bT + 8),
        M6SwapSpot.side => Offset(66, bT + 196),
        M6SwapSpot.under => Offset(284, bT + 186),
        M6SwapSpot.junction => Offset(130, bT - 6),
      };
  static const double lookR = 40;

  // --- the main switch and the house -------------------------------------------------
  Rect get mainSwitch => Rect.fromLTWH(262, bT + 40, 46, 66);
  Rect get window => Rect.fromLTWH(270, bT - 112, 62, 70);
  Offset get wallHole => Offset(332, bT + 150);

  /// The trainee by the pole.
  Rect get trainee => Rect.fromLTWH(18, groundY - 104, 44, 104);

  /// A spot on the wall with nothing on it (for the hold hint).
  Offset get emptyWall => Offset(196, bT + 252);

  /// Where the flash comes off: the box, or the bypass joint.
  Offset get flashBox => Offset(183, bT + 150);
  Offset get flashJoint => spot(M6SwapSpot.junction);

  /// Every scene place a tool or a look can touch.
  List<Rect> get lookRects => [for (final s in M6SwapSeal.values) sealHit(s), for (final s in M6SwapSpot.values) spotHit(s)];

  @override
  bool operator ==(Object other) => other is M6SwapGeo && other.height == height && other.bT == bT && other.groundY == groundY;

  @override
  int get hashCode => Object.hash(height, bT, groundY);
}

/// The text a screen shows (the meter's own raw display; no game label).
String m6SwapScreenText(M6SwapScreen s, {required int kwhTenths, required int kwHundredths, required int volt, required int ampTenths, String tamperWord = 'Tamper'}) =>
    switch (s) {
      M6SwapScreen.kwh => '${(kwhTenths ~/ 10).toString().padLeft(5, '0')}.${kwhTenths % 10}',
      M6SwapScreen.kw => '${kwHundredths ~/ 100}.${(kwHundredths % 100).toString().padLeft(2, '0')}',
      M6SwapScreen.volt => '$volt',
      M6SwapScreen.amp => '${ampTenths ~/ 10}.${ampTenths % 10}',
      M6SwapScreen.tamper => tamperWord,
      M6SwapScreen.blank => '',
      M6SwapScreen.drum => (kwhTenths ~/ 10).toString().padLeft(5, '0'),
    };

/// The unit glyph a real LCD shows beside the number.
String m6SwapUnit(M6SwapScreen s) => switch (s) {
      M6SwapScreen.kwh => 'kWh',
      M6SwapScreen.kw => 'kW',
      M6SwapScreen.volt => 'V',
      M6SwapScreen.amp => 'A',
      _ => '',
    };

/// A photo or the meter's face: the screen kind and the number on it.
@immutable
class M6SwapShot {
  const M6SwapShot(this.screen, this.text);
  final M6SwapScreen screen;
  final String text;

  @override
  bool operator ==(Object other) => other is M6SwapShot && other.screen == screen && other.text == text;

  @override
  int get hashCode => Object.hash(screen, text);
}

/// What the wall shows now.
@immutable
class M6SwapWallRig {
  const M6SwapWallRig({
    required this.palette,
    required this.meter,
    required this.fresh,
    required this.face,
    required this.carrierIn,
    required this.broken,
    required this.tugged,
    required this.bypass,
    required this.decoys,
    required this.magnetAt,
    required this.boxOpen,
  });

  /// The house's colours (0–2).
  final int palette;
  final M6SwapMeter meter;

  /// The new meter is on the wall (after the swap).
  final bool fresh;

  /// The screen now.
  final M6SwapShot face;
  final bool carrierIn;

  /// The broken seal (if any) and the seals tugged so far.
  final M6SwapSeal? broken;
  final Set<M6SwapSeal> tugged;

  /// A bypass cable (else the TV cable from the roof).
  final bool bypass;

  /// The harmless things at the three box spots, and the magnet's spot.
  final Map<M6SwapSpot, M6SwapDecoy> decoys;
  final M6SwapSpot? magnetAt;
  final bool boxOpen;

  @override
  bool operator ==(Object other) =>
      other is M6SwapWallRig &&
      other.palette == palette &&
      other.meter == meter &&
      other.fresh == fresh &&
      other.face == face &&
      other.carrierIn == carrierIn &&
      other.broken == broken &&
      setEquals(other.tugged, tugged) &&
      other.bypass == bypass &&
      mapEquals(other.decoys, decoys) &&
      other.magnetAt == magnetAt &&
      other.boxOpen == boxOpen;

  @override
  int get hashCode => Object.hash(palette, meter, fresh, face, carrierIn, broken, Object.hashAllUnordered(tugged), bypass, Object.hashAllUnordered(decoys.entries.map((e) => '${e.key}${e.value}')), magnetAt, boxOpen);
}

Paint _fill(Color c) => Paint()..color = c;
Paint _stroke(Color c, double w) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

void _text(Canvas c, String text, Offset centre, {double size = 9, Color color = const Color(0xFF14261A), FontWeight weight = FontWeight.w800, String? family}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: weight, color: color, fontFamily: family, height: 1)),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
}

const _walls = [
  [Color(0xFFE9D9B8), Color(0xFFD7C29A)],
  [Color(0xFFD8E2D0), Color(0xFFBCCBB2)],
  [Color(0xFFEBD3C4), Color(0xFFD6B7A4)],
];

/// The wall: sky, the pole and the service cable, the cut-out, the meter in
/// its box, the main switch, the house cable, the second dark cable, the
/// small dark things.
class M6SwapWallPainter extends CustomPainter {
  const M6SwapWallPainter({required this.geo, required this.rig});
  final M6SwapGeo geo;
  final M6SwapWallRig rig;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    final wall = _walls[rig.palette % _walls.length];
    // Sky.
    final roof = g.bT - 140;
    c.drawRect(Rect.fromLTWH(0, 0, w, roof),
        Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8EC3E6), Color(0xFFD9ECF6)]).createShader(Rect.fromLTWH(0, 0, w, roof)));
    // The roof edge and the wall.
    c.drawRect(Rect.fromLTWH(0, roof - 10, w, 14), _fill(const Color(0xFF7A5A40)));
    final wallRect = Rect.fromLTWH(0, roof + 4, w, g.groundY - roof - 4);
    c.drawRect(wallRect, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: wall).createShader(wallRect));
    // Plaster marks.
    final mark = _stroke(wall[1].withValues(alpha: 0.7), 1);
    for (var i = 0; i < 6; i++) {
      final y = roof + 30 + i * 52.0;
      c.drawLine(Offset(20.0 + (i * 37) % 80, y), Offset(60.0 + (i * 37) % 80, y + 3), mark);
    }
    // Ground.
    final ground = Rect.fromLTWH(0, g.groundY, w, size.height - g.groundY);
    c.drawRect(ground, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF9C8A6A), Color(0xFF6E604A)]).createShader(ground));
    // The window (lit while the supply is on).
    final win = g.window;
    c.drawRRect(RRect.fromRectAndRadius(win.inflate(4), const Radius.circular(3)), _fill(const Color(0xFF6B4A33)));
    c.drawRect(win, _fill(rig.carrierIn ? const Color(0xFFFFE9A8) : const Color(0xFF3A4452)));
    c.drawLine(win.topCenter, win.bottomCenter, _stroke(const Color(0xFF6B4A33), 3));
    c.drawLine(win.centerLeft, win.centerRight, _stroke(const Color(0xFF6B4A33), 3));

    // The pole (left edge) and its cross-arm; the pole fuse is high up.
    c.drawRect(Rect.fromLTWH(GeoPole.left, 0, 12, g.groundY), Paint()..shader = const LinearGradient(colors: [Color(0xFF8D949B), Color(0xFF5E666D)]).createShader(Rect.fromLTWH(GeoPole.left, 0, 12, g.groundY)));
    c.drawRect(Rect.fromLTWH(0, g.poleTop.dy - 8, 46, 6), _fill(const Color(0xFF4A5056)));

    // The second dark cable: a TV cable from the roof, or a bypass off the
    // service cable before the cut-out. Both end at the wall hole.
    final dark = _stroke(const Color(0xFF26292D), 2.4);
    final j = g.spot(M6SwapSpot.junction);
    final p2 = Path();
    if (rig.bypass) {
      p2.moveTo(j.dx, j.dy);
      p2.cubicTo(j.dx + 20, j.dy - 30, 250, g.bT - 22, 318, g.bT - 8);
    } else {
      p2.moveTo(j.dx + 6, roof - 4);
      p2.cubicTo(j.dx + 10, g.bT - 30, 250, g.bT - 26, 318, g.bT - 8);
    }
    p2.lineTo(330, g.bT + 20);
    p2.lineTo(g.wallHole.dx - 2, g.wallHole.dy - 8);
    c.drawPath(p2, dark);

    // The service cable: pole → (the junction) → the cut-out's line contact.
    final svc = Path()
      ..moveTo(g.poleTop.dx, g.poleTop.dy)
      ..quadraticBezierTo(j.dx - 10, j.dy + 6, j.dx, j.dy)
      ..quadraticBezierTo(GeoPole.cut - 8, g.bT + 30, g.lineContact.dx, g.lineContact.dy - 6);
    c.drawPath(svc, _stroke(const Color(0xFF1B1D20), 4));
    // Cable clips on the wall (every wall).
    for (final at in [Offset(j.dx + 12, j.dy + 2), Offset(g.cutBase.left - 6, g.bT + 30)]) {
      c.drawCircle(at, 2.6, _fill(const Color(0xFFEDEDED)));
    }

    // The board.
    final board = Rect.fromLTWH(54, g.bT - 4, 270, 222);
    c.drawRRect(RRect.fromRectAndRadius(board, const Radius.circular(5)),
        Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF9C6B43), Color(0xFF7A5130)]).createShader(board));
    c.drawRRect(RRect.fromRectAndRadius(board, const Radius.circular(5)), _stroke(const Color(0xFF5A3A22), 1.5));

    // The cut-out: the porcelain base, its contacts, the carrier.
    final base = g.cutBase;
    c.drawRRect(RRect.fromRectAndRadius(base, const Radius.circular(6)),
        Paint()..shader = const LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFFD9D6CF)]).createShader(base));
    c.drawRRect(RRect.fromRectAndRadius(base, const Radius.circular(6)), _stroke(const Color(0xFF9A968C), 1.2));
    for (final p in [g.lineContact, g.loadContact]) {
      c.drawRect(Rect.fromCenter(center: p, width: 18, height: 6), _fill(const Color(0xFFB8862E)));
    }
    final car = g.carrier(rig.carrierIn);
    c.drawRRect(RRect.fromRectAndRadius(car, const Radius.circular(5)),
        Paint()..shader = const LinearGradient(colors: [Color(0xFFF7F4EE), Color(0xFFCFCAC0)]).createShader(car));
    c.drawRRect(RRect.fromRectAndRadius(car, const Radius.circular(5)), _stroke(const Color(0xFF8F8A80), 1.3));
    c.drawLine(car.topCenter + const Offset(0, 6), car.bottomCenter - const Offset(0, 6), _stroke(const Color(0xFFB8862E), 2));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: car.center, width: 20, height: 8), const Radius.circular(3)), _fill(const Color(0xFFBDB6AA)));

    // The cut-out → the meter's incoming terminal; the meter → main switch.
    final feed = Path()
      ..moveTo(g.loadContact.dx, g.loadContact.dy + 4)
      ..lineTo(g.loadContact.dx, g.bT + 188)
      ..lineTo(g.terminalCover.left + 10, g.bT + 188)
      ..lineTo(g.terminalCover.left + 10, g.terminalCover.bottom - 4);
    c.drawPath(feed, _stroke(const Color(0xFF1B1D20), 3));
    final out = Path()
      ..moveTo(g.terminalCover.right - 10, g.terminalCover.bottom - 4)
      ..lineTo(g.terminalCover.right - 10, g.bT + 196)
      ..lineTo(g.mainSwitch.center.dx, g.bT + 196)
      ..lineTo(g.mainSwitch.center.dx, g.mainSwitch.bottom);
    c.drawPath(out, _stroke(const Color(0xFF1B1D20), 3));
    c.drawLine(Offset(g.mainSwitch.right, g.mainSwitch.center.dy), Offset(g.wallHole.dx, g.mainSwitch.center.dy), _stroke(const Color(0xFF1B1D20), 3));
    c.drawLine(Offset(g.wallHole.dx, g.mainSwitch.center.dy), g.wallHole, _stroke(const Color(0xFF1B1D20), 3));
    c.drawCircle(g.wallHole, 4, _fill(const Color(0xFF3A2C20)));

    // The main switch box (the consumer's; not this job).
    final ms = g.mainSwitch;
    c.drawRRect(RRect.fromRectAndRadius(ms, const Radius.circular(4)),
        Paint()..shader = const LinearGradient(colors: [Color(0xFF5B6168), Color(0xFF393E44)]).createShader(ms));
    c.drawRect(Rect.fromCenter(center: ms.center, width: 10, height: 22), _fill(const Color(0xFF22262A)));
    c.drawRect(Rect.fromCenter(center: ms.center - const Offset(0, 6), width: 8, height: 8), _fill(const Color(0xFFB03A2E)));

    // The meter box and the meter.
    final bx = g.box;
    c.drawRRect(RRect.fromRectAndRadius(bx, const Radius.circular(6)),
        Paint()..shader = const LinearGradient(colors: [Color(0xFFDDE3E8), Color(0xFFAEB7BF)]).createShader(bx));
    c.drawRRect(RRect.fromRectAndRadius(bx, const Radius.circular(6)), _stroke(const Color(0xFF6E7A85), 1.6));
    _meter(c);

    // The small dark things on the box (alike at this size).
    for (final s in const [M6SwapSpot.top, M6SwapSpot.side, M6SwapSpot.under]) {
      _darkThing(c, g.spot(s));
    }
    // The junction always has a dark lump (a tap joint, or the cable clip).
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: j, width: 10, height: 7), const Radius.circular(2)), _fill(const Color(0xFF202326)));
  }

  void _darkThing(Canvas c, Offset at) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: at, width: 13, height: 9), const Radius.circular(3)), _fill(const Color(0xFF26292C)));
    c.drawLine(at + const Offset(-4, -2), at + const Offset(3, -2), _stroke(const Color(0x55FFFFFF), 1));
  }

  void _meter(Canvas c) {
    final g = geo;
    final m = g.meter;
    final fresh = rig.fresh;
    final body = RRect.fromRectAndRadius(m, const Radius.circular(8));
    c.drawRRect(body,
        Paint()..shader = LinearGradient(colors: fresh ? const [Color(0xFFF4F6F7), Color(0xFFCDD3D8)] : const [Color(0xFF3D4650), Color(0xFF242A31)]).createShader(m));
    c.drawRRect(body, _stroke(const Color(0xFF1A1E22), 1.4));
    final lcd = fresh || rig.meter == M6SwapMeter.lcd;
    if (lcd) {
      paintM6SwapScreen(c, g.screen, rig.face);
      // The push-button.
      c.drawCircle(g.button, 8, _fill(const Color(0xFF1A1E22)));
      c.drawCircle(g.button, 6, Paint()..shader = const RadialGradient(colors: [Color(0xFF6F8FB0), Color(0xFF2C4560)]).createShader(Rect.fromCircle(center: g.button, radius: 6)));
      // The CAL LED.
      c.drawCircle(Offset(m.left + 12, g.screen.bottom + 14), 2.6, _fill(const Color(0xFF7A2A26)));
    } else {
      // The drum counter window and the disc.
      paintM6SwapScreen(c, g.screen, rig.face);
      final d = g.disc;
      c.drawRect(d, _fill(const Color(0xFF14181C)));
      c.drawRect(Rect.fromLTWH(d.left + 4, d.center.dy - 2, d.width - 8, 4), Paint()..shader = const LinearGradient(colors: [Color(0xFFB9C1C8), Color(0xFFF2F4F6), Color(0xFFB9C1C8)]).createShader(d));
      c.drawRect(Rect.fromLTWH(d.center.dx - 2, d.center.dy - 2, 4, 4), _fill(const Color(0xFF14181C)));
    }
    // The terminal cover.
    final tc = g.terminalCover;
    c.drawRRect(RRect.fromRectAndRadius(tc, const Radius.circular(4)), _fill(fresh ? const Color(0xFFDCE0E3) : const Color(0xFF2E353C)));
    c.drawRRect(RRect.fromRectAndRadius(tc, const Radius.circular(4)), _stroke(const Color(0xFF15191C), 1.2));
    for (final x in [tc.left + 12, tc.right - 12]) {
      c.drawCircle(Offset(x, tc.top + 8), 2.4, _fill(const Color(0xFF9AA3AB)));
    }
    if (rig.boxOpen) {
      c.drawRect(tc.deflate(4), _fill(const Color(0xFF1A1A1A)));
    }
    // The seals (the new meter's are fresh and never tugged).
    for (final s in M6SwapSeal.values) {
      _seal(c, s);
    }
  }

  void _seal(Canvas c, M6SwapSeal s) {
    final at = geo.seal(s);
    final loose = !rig.fresh && rig.broken == s && rig.tugged.contains(s);
    // An intact seal once tugged shows its wire pulled taut (brighter,
    // thicker), so a muted player can see it was checked and held.
    final taut = !rig.fresh && rig.tugged.contains(s);
    final wire = taut ? _stroke(const Color(0xFFD7DCE0), 1.8) : _stroke(const Color(0xFF9AA0A6), 1.2);
    final anchor = s == M6SwapSeal.body ? at + const Offset(-10, -8) : at + const Offset(-8, -10);
    if (loose) {
      // Cut: the wire hangs and the lead swings off its loop.
      c.drawLine(anchor, anchor + const Offset(-2, 12), wire);
      final lead = at + const Offset(-4, 14);
      c.drawLine(anchor + const Offset(4, 0), lead, wire);
      c.drawCircle(lead, 4.2, Paint()..shader = const RadialGradient(colors: [Color(0xFFC9CDD1), Color(0xFF7D848B)]).createShader(Rect.fromCircle(center: lead, radius: 4.2)));
      return;
    }
    c.drawLine(anchor, at, wire);
    c.drawLine(anchor + const Offset(4, 0), at, wire);
    c.drawCircle(at, 4.2, Paint()..shader = const RadialGradient(colors: [Color(0xFFC9CDD1), Color(0xFF7D848B)]).createShader(Rect.fromCircle(center: at, radius: 4.2)));
  }

  @override
  bool shouldRepaint(M6SwapWallPainter old) => old.geo != geo || old.rig != rig;
}

/// The pole's and the cut-out's fixed x (painter helpers).
abstract final class GeoPole {
  static const double left = M6SwapGeo.poleX;
  static const double cut = M6SwapGeo.cutX;
}

/// A meter's screen in [r]: the LCD (number + its unit, a tamper word, or
/// blank) or the disc meter's drum counter.
void paintM6SwapScreen(Canvas c, Rect r, M6SwapShot face) {
  if (face.screen == M6SwapScreen.drum) {
    c.drawRect(r, _fill(const Color(0xFF101315)));
    final n = face.text.length;
    final cw = (r.width - 8) / (n + 1);
    for (var i = 0; i <= n; i++) {
      final cell = Rect.fromLTWH(r.left + 4 + i * cw, r.top + 3, cw - 1.5, r.height - 6);
      final last = i == n;
      c.drawRect(cell, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: last ? const [Color(0xFF8C1F1A), Color(0xFFC0392B), Color(0xFF8C1F1A)] : const [Color(0xFFB5B9BC), Color(0xFFFFFFFF), Color(0xFFB5B9BC)]).createShader(cell));
      _text(c, last ? '0' : face.text[i], cell.center, size: r.height * 0.55, color: last ? const Color(0xFFFFFFFF) : const Color(0xFF15181B));
    }
    return;
  }
  final on = face.screen != M6SwapScreen.blank;
  c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)),
      Paint()..shader = LinearGradient(colors: on ? const [Color(0xFFB7D3A2), Color(0xFF9EBE88)] : const [Color(0xFF4C5A48), Color(0xFF3E4A3B)]).createShader(r));
  c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), _stroke(const Color(0xFF1A1E22), 1));
  if (!on) return;
  const ink = Color(0xFF1C2A16);
  final unit = m6SwapUnit(face.screen);
  if (unit.isEmpty) {
    _text(c, face.text, r.center, size: r.height * 0.48, color: ink, weight: FontWeight.w900);
    return;
  }
  _text(c, face.text, Offset(r.left + r.width * 0.42, r.center.dy), size: r.height * 0.5, color: ink, weight: FontWeight.w900);
  _text(c, unit, Offset(r.right - r.width * 0.1, r.bottom - r.height * 0.26), size: r.height * 0.28, color: ink);
}

/// A photo or a screen on its own (the phone's photos, the job card).
class M6SwapScreenPainter extends CustomPainter {
  const M6SwapScreenPainter(this.shot);
  final M6SwapShot? shot;

  @override
  void paint(Canvas c, Size size) {
    final r = Offset.zero & size;
    final s = shot;
    if (s == null) {
      c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)), _fill(const Color(0xFF2A3240)));
      c.drawRRect(RRect.fromRectAndRadius(r.deflate(1), const Radius.circular(4)), _stroke(const Color(0xFF55627A), 1.2));
      return;
    }
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)), _fill(const Color(0xFF1A1E22)));
    paintM6SwapScreen(c, r.deflate(size.height * 0.14), s);
  }

  @override
  bool shouldRepaint(M6SwapScreenPainter old) => old.shot != shot;
}

/// The close look's bubble: what is really at a spot, big.
class M6SwapLookPainter extends CustomPainter {
  const M6SwapLookPainter(this.thing);
  final M6SwapThing thing;

  @override
  void paint(Canvas c, Size size) {
    final o = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    c.drawCircle(o, r, _fill(const Color(0xFFE6DCC4)));
    c.save();
    c.clipPath(Path()..addOval(Rect.fromCircle(center: o, radius: r - 2)));
    switch (thing) {
      case M6SwapThing.magnet:
        // A strong block magnet stuck to the meter.
        final b = Rect.fromCenter(center: o, width: r * 1.1, height: r * 0.7);
        c.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(4)), Paint()..shader = const LinearGradient(colors: [Color(0xFF9AA3AB), Color(0xFFE9EDF0), Color(0xFF7B848C)]).createShader(b));
        c.drawRRect(RRect.fromRectAndRadius(b.deflate(4), const Radius.circular(3)), _fill(const Color(0xFF30353A)));
        c.drawLine(b.centerLeft + Offset(r * 0.25, 0), b.centerRight - Offset(r * 0.25, 0), _stroke(const Color(0xFFB03A2E), 2.4));
        for (var i = 0; i < 3; i++) {
          final rr = Rect.fromCenter(center: o, width: r * (1.4 + i * 0.3), height: r * (1.0 + i * 0.3));
          c.drawArc(rr, -0.6, 1.2, false, _stroke(const Color(0x667B848C), 1.2));
          c.drawArc(rr, math.pi - 0.6, 1.2, false, _stroke(const Color(0x667B848C), 1.2));
        }
      case M6SwapThing.clip:
        // A cable clip with a nail.
        c.drawRect(Rect.fromCenter(center: o, width: r * 1.6, height: 4), _fill(const Color(0xFF1B1D20)));
        c.drawArc(Rect.fromCenter(center: o, width: r * 0.6, height: r * 0.6), math.pi, math.pi, false, _stroke(const Color(0xFF2B2E31), 5));
        c.drawCircle(o + Offset(0, -r * 0.3), 3, _fill(const Color(0xFFB0B4B8)));
      case M6SwapThing.nest:
        // A mud wasp nest.
        for (var i = 0; i < 4; i++) {
          c.drawOval(Rect.fromCenter(center: o + Offset((i - 1.5) * r * 0.28, (i.isEven ? -1 : 1) * 3.0), width: r * 0.36, height: r * 0.7), _fill(Color.lerp(const Color(0xFF6B4E33), const Color(0xFF4A3420), i / 4)!));
        }
      case M6SwapThing.grommet:
        // A black rubber grommet.
        c.drawCircle(o, r * 0.45, _fill(const Color(0xFF222528)));
        c.drawCircle(o, r * 0.2, _fill(const Color(0xFFE6DCC4)));
      case M6SwapThing.bypass:
        // A tap joint on the service cable: bare strands twisted on and taped,
        // a second cable going off.
        c.drawLine(o + Offset(-r, -r * 0.2), o + Offset(r, r * 0.1), _stroke(const Color(0xFF1B1D20), 7));
        c.drawLine(o, o + Offset(r * 0.3, -r), _stroke(const Color(0xFF26292D), 5));
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: r * 0.6, height: r * 0.42), const Radius.circular(3)), _fill(const Color(0xFF111214)));
        for (var i = 0; i < 4; i++) {
          c.drawLine(o + Offset(-r * 0.12 + i * 4, -r * 0.28), o + Offset(-r * 0.08 + i * 4, r * 0.24), _stroke(const Color(0xFFC77A3A), 1.6));
        }
      case M6SwapThing.cable:
        // The service cable alone, under its clip.
        c.drawLine(o + Offset(-r, -r * 0.2), o + Offset(r, r * 0.1), _stroke(const Color(0xFF1B1D20), 7));
        c.drawArc(Rect.fromCenter(center: o, width: r * 0.5, height: r * 0.5), math.pi, math.pi, false, _stroke(const Color(0xFFEDEDED), 4));
    }
    c.restore();
    c.drawCircle(o, r - 1, _stroke(const Color(0xFF3B4A5E), 3));
  }

  @override
  bool shouldRepaint(M6SwapLookPainter old) => old.thing != thing;
}

/// The flash (a deadly act): a white-yellow burst at [at], in colour over
/// the grey scene, [v] 0 → 1.
class M6SwapFlashPainter extends CustomPainter {
  const M6SwapFlashPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final r = 20 + 70 * v;
    c.drawCircle(at, r, Paint()..shader = RadialGradient(colors: [const Color(0xFFFFFFFF).withValues(alpha: 1 - v * 0.6), const Color(0xFFFFE066).withValues(alpha: 0.8 - v * 0.5), const Color(0x00FF8A00)]).createShader(Rect.fromCircle(center: at, radius: r)));
    final p = _stroke(const Color(0xFFFFF3B0).withValues(alpha: 1 - v * 0.7), 2.2);
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + 0.2;
      c.drawLine(at + Offset(math.cos(a), math.sin(a)) * (r * 0.4), at + Offset(math.cos(a), math.sin(a)) * (r * 0.95), p);
    }
  }

  @override
  bool shouldRepaint(M6SwapFlashPainter old) => old.at != at || old.v != v;
}
