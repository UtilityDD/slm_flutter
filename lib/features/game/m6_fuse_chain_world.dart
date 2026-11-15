import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The drawn world of lesson 6.3 কাজ 2 "কোন প্রহরী পড়ল?" (m6_fuse_chain.dart):
// a daylight village lane. On the left the WBSEDCL pole transformer (DTR):
// the 11 kV line comes in on the left at the top into the AB switch (three
// blades; its operating rod runs down the pole to a ground handle), below it
// the three horn-gap (HG) fuses, then the tank with its nameplate (kVA), the
// LT box (a door; inside, the supply-side bar at the top and three HRC
// cartridges R/Y/B with indicator dots) and its LT switch lever (ON/OFF,
// lock and tag). The LT line (R, Y, B, N) runs right over the lane; the
// called house stands near with its service drop clamped to one phase and
// its veranda meter board (main switch, a kit-kat carrier marked 16A); the
// other houses of the lane stand further back. The van at the kerb carries
// the PPE hook (gloves, goggles) and the scrap pile. No DO fuse anywhere
// (ruling M6-2). No text in the art except labels a worker reads (R/Y/B/N,
// ON/OFF, the kVA plate, house numbers, 16A). Code-drawn, gradients, no
// bitmaps.
//
// Design: 360 wide × the scene's height; the ground follows the bottom of the
// screen (a tall phone gets a taller pole and more sky, never stretched).

/// What a guard holds once opened (lesson 6.3 points 4–5, pro tip 3).
enum M6Content { melted, gi, aluminium, thickCopper, blownHrc, strip }

/// The reading card's picture.
enum M6Card { hg, blades, kitkat, hrc }

/// The state of one HRC way in the LT box.
enum M6HrcState { ok, blown, out }

/// Where things are (design px, 360 wide).
@immutable
class M6ChainGeo {
  const M6ChainGeo._(this.height, this.groundY, this.topY);

  factory M6ChainGeo.forScene(double height, double inset) {
    final g = height - floorUp - inset * 0.5;
    return M6ChainGeo._(height, g, math.max(130.0, g - 460));
  }

  final double height;

  /// The ground line (the poles' feet, the van's wheels).
  final double groundY;

  /// The top of the DTR pole.
  final double topY;

  /// The ground sits this far above the bottom (the tool belt stands on it).
  static const double floorUp = 112;

  /// The DTR pole's axis and the three phases (AB blades, HG fuses).
  static const double poleX = 70;
  static const List<double> phaseX = [38, 70, 102];

  /// The pole's height.
  double get h => groundY - topY;

  /// A height on the pole (0 = the top, 1 = the ground).
  double y(double f) => topY + f * h;

  // --- the AB switch ---------------------------------------------------------
  double get abArmY => y(0.06);

  /// The three AB blades (tap to look at them).
  Rect get abBladesHit => Rect.fromLTRB(26, abArmY - 18, 116, abArmY + 18);

  /// The AB's line side (the incoming 11 kV jaws): always live — the tester
  /// is proved here.
  Rect get abLineHit => Rect.fromLTWH(2, abArmY - 14, 22, 26);

  /// The AB's ground handle: the stroke runs down (open) or up (close).
  Rect get abHandle => Rect.fromLTRB(78, y(0.70), 114, y(0.90));
  double get abTravel => abHandle.height - 16;
  Offset knob(bool closed) => Offset(abHandle.center.dx, closed ? abHandle.top + 8 : abHandle.bottom - 8);

  // --- the HG fuses ----------------------------------------------------------
  double get hgY => y(0.19);
  Rect get hgHit => Rect.fromLTRB(22, hgY - 18, 118, hgY + 18);

  // --- the tank and the LT box -------------------------------------------------
  Rect get tank => Rect.fromLTRB(26, y(0.27), 114, y(0.40));
  Rect get ltBox => Rect.fromLTRB(8, y(0.45), 104, y(0.64));

  /// The supply-side bar inside the LT box (live while the AB is closed).
  Rect get ltSupplyHit => Rect.fromLTRB(ltBox.left + 4, ltBox.top + 3, ltBox.right - 4, ltBox.top + ltBox.height * 0.3);
  Offset hrcCenter(int i) => Offset(26 + 28.0 * i, ltBox.top + ltBox.height * 0.66);
  Rect hrcHit(int i) => Rect.fromCenter(center: hrcCenter(i), width: 26, height: ltBox.height * 0.5);

  /// The open door's leaf, dropped below the box (a tap shuts it). Its left
  /// part only, clear of the AB's ground handle.
  Rect get doorHit => Rect.fromLTRB(ltBox.left, ltBox.bottom, ltBox.right - 30, ltBox.bottom + 20);

  /// The LT switch lever on the box's right (swipe down = OFF, up = ON).
  Rect get ltLeverHit => Rect.fromLTRB(108, ltBox.top, 142, ltBox.top + ltBox.height * 0.8);

  /// The LT line over the lane (R, Y, B, N from the top).
  double wireY(int i) => y(0.222) + 6.0 * i;

  // --- the called house ----------------------------------------------------------
  Rect get house => Rect.fromLTRB(146, y(0.33), 224, groundY - 58);
  Rect get meterBoard => Rect.fromLTRB(156, y(0.38), 216, y(0.62));
  Rect get mainHit => Rect.fromLTRB(meterBoard.left, meterBoard.top, meterBoard.right, meterBoard.center.dy);
  Rect get kitkatHit => Rect.fromLTRB(meterBoard.left, meterBoard.center.dy, meterBoard.right, meterBoard.bottom);

  // --- the van ----------------------------------------------------------------
  Rect get van => Rect.fromLTRB(168, groundY - 58, 252, groundY);

  /// The PPE hook on the van's side: 0 = gloves, 1 = goggles.
  Offset ppeAt(int i) => Offset(i == 0 ? 186 : 220, groundY - 36);
  Rect ppeHit(int i) => Rect.fromCenter(center: ppeAt(i), width: 28, height: 28);

  /// The scrap pile at the van's tail.
  Offset get scrapAt => Offset(160, groundY - 6);

  /// The worker (between the pole and the van).
  Rect get worker => Rect.fromLTWH(118, groundY - 104, 44, 104);

  /// The docket board (a widget), top right.
  static const Rect docket = Rect.fromLTWH(226, 122, 130, 178);

  /// The reading card (the last look's close-up), under the docket.
  static const Rect card = Rect.fromLTWH(228, 304, 128, 72);

  @override
  bool operator ==(Object other) => other is M6ChainGeo && other.height == height && other.groundY == groundY && other.topY == topY;

  @override
  int get hashCode => Object.hash(height, groundY, topY);
}

/// What the scene shows now.
@immutable
class M6ChainRig {
  const M6ChainRig({
    required this.house,
    required this.phase,
    required this.kva,
    this.hgBlown = -1,
    this.abClosed = true,
    this.earthed = false,
    this.doorOpen = false,
    this.hrc = const [M6HrcState.ok, M6HrcState.ok, M6HrcState.ok],
    this.ltOn = true,
    this.lockTag = false,
    this.mainOn = true,
    this.kitkatOut = false,
    this.gloves = false,
    this.goggles = false,
    this.lit = false,
  });

  /// The called house's number (1–6) and the phase its drop is clamped to.
  final int house;
  final int phase;

  /// The DTR's nameplate.
  final int kva;

  /// The HG phase whose wire is gone (-1: all three wired).
  final int hgBlown;
  final bool abClosed;
  final bool earthed;
  final bool doorOpen;
  final List<M6HrcState> hrc;
  final bool ltOn;
  final bool lockTag;

  /// The meter board: its main switch, the kit-kat carrier drawn out.
  final bool mainOn;
  final bool kitkatOut;

  /// Still on the van's hook unless worn.
  final bool gloves;
  final bool goggles;

  /// The house has its light back (the call is done).
  final bool lit;

  @override
  bool operator ==(Object other) =>
      other is M6ChainRig &&
      other.house == house &&
      other.phase == phase &&
      other.kva == kva &&
      other.hgBlown == hgBlown &&
      other.abClosed == abClosed &&
      other.earthed == earthed &&
      other.doorOpen == doorOpen &&
      listEquals(other.hrc, hrc) &&
      other.ltOn == ltOn &&
      other.lockTag == lockTag &&
      other.mainOn == mainOn &&
      other.kitkatOut == kitkatOut &&
      other.gloves == gloves &&
      other.goggles == goggles &&
      other.lit == lit;

  @override
  int get hashCode => Object.hash(house, phase, kva, hgBlown, abClosed, earthed, doorOpen, Object.hashAll(hrc), ltOn, lockTag, mainOn, kitkatOut, gloves, goggles, lit);
}

const _steel = Color(0xFF6F7880);
const _wire = Color(0xFF30363C);
const _porcelain = Color(0xFFE9EDF0);
const _copper = Color(0xFFC77A3A);
const List<Color> m6PhaseColors = [Color(0xFFD63A2F), Color(0xFFE8B400), Color(0xFF2F6FD6)];

void _text(Canvas c, String s, Offset at, {double size = 9, Color color = const Color(0xFF1C2430), FontWeight weight = FontWeight.w800, bool center = true}) {
  final tp = TextPainter(
    text: TextSpan(text: s, style: TextStyle(fontSize: size, color: color, fontWeight: weight, height: 1)),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(c, center ? at - Offset(tp.width / 2, tp.height / 2) : at);
}

class M6ChainPainter extends CustomPainter {
  M6ChainPainter({required this.geo, required this.rig, required this.seed});

  final M6ChainGeo geo;
  final M6ChainRig rig;
  final int seed;

  /// The service drop's ends (the roof mast, the phase clamp, the neutral
  /// clamp), worked out with the line and drawn over the house.
  (Offset, Offset, Offset)? _dropTo;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    final rnd = math.Random(seed);
    // Sky.
    c.drawRect(
      Rect.fromLTWH(0, 0, w, g.groundY),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5FA8E0), Color(0xFFBFE0F2)],
        ).createShader(Rect.fromLTWH(0, 0, w, g.groundY)),
    );
    // Clouds (a little drift per call).
    for (var i = 0; i < 3; i++) {
      final cx = 40 + rnd.nextDouble() * 300;
      final cy = 150 + rnd.nextDouble() * 40;
      final p = Paint()..color = const Color(0xCCFFFFFF);
      c.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 46, height: 14), p);
      c.drawOval(Rect.fromCenter(center: Offset(cx + 12, cy - 5), width: 26, height: 14), p);
    }
    // Far trees.
    final trees = Paint()..color = const Color(0xFF6E9E5A);
    for (var x = -10.0; x < w + 20; x += 34) {
      c.drawCircle(Offset(x, g.groundY - 120 + (x % 3) * 4), 22, trees);
    }
    // The lane.
    final lane = Rect.fromLTWH(0, g.groundY - 40, w, size.height - g.groundY + 40);
    c.drawRect(
      lane,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB59B74), Color(0xFF8C7556)],
        ).createShader(lane),
    );
    c.drawRect(Rect.fromLTWH(0, g.groundY - 44, w, 5), Paint()..color = const Color(0xFF7EA35E));
    _farHouses(c, g);
    _lineAndDrop(c, g);
    _nearHouse(c, g);
    _dtr(c, g);
    _van(c, g);
  }

  void _farHouses(Canvas c, M6ChainGeo g) {
    // The other houses of the lane, further back (numbers on their doors).
    final others = [for (var n = 1; n <= 6; n++) if (n != rig.house) n];
    final top = M6ChainGeo.card.bottom + 6;
    final base = g.groundY - 44;
    final hh = math.max(30.0, math.min(70.0, base - top));
    for (var i = 0; i < others.length; i++) {
      final x = 230.0 + i * 26;
      final r = Rect.fromLTWH(x, base - hh, 24, hh);
      c.drawRect(r, Paint()..color = i.isEven ? const Color(0xFFE7D3B0) : const Color(0xFFD9C3A0));
      final roof = Path()
        ..moveTo(r.left - 2, r.top)
        ..lineTo(r.center.dx, r.top - 9)
        ..lineTo(r.right + 2, r.top)
        ..close();
      c.drawPath(roof, Paint()..color = const Color(0xFF9C4A32));
      c.drawRect(Rect.fromLTWH(r.left + 8, r.bottom - 14, 8, 14), Paint()..color = const Color(0xFF6B4A2E));
      _text(c, '${others[i]}', Offset(r.center.dx, r.bottom - 19), size: 6.5, color: const Color(0xFF3A2A16));
    }
  }

  void _lineAndDrop(Canvas c, M6ChainGeo g) {
    // The LT line from the DTR pole's LT cross-arm across the lane.
    final arm = Paint()..color = _steel;
    c.drawRect(Rect.fromLTWH(M6ChainGeo.poleX - 4, g.wireY(0) - 4, 60, 4), arm);
    for (var i = 0; i < 4; i++) {
      final y = g.wireY(i);
      final p = Paint()
        ..color = _wire
        ..strokeWidth = 1.4;
      final path = Path()
        ..moveTo(M6ChainGeo.poleX + 50, y)
        ..quadraticBezierTo(240, y + 10, 360, y + 3);
      c.drawPath(path, p..style = PaintingStyle.stroke);
      // The phase marker by the cross-arm.
      c.drawCircle(Offset(M6ChainGeo.poleX + 52, y), 2.6, Paint()..color = i < 3 ? m6PhaseColors[i] : const Color(0xFF222222));
      _text(c, const ['R', 'Y', 'B', 'N'][i], Offset(M6ChainGeo.poleX + 60, y), size: 6.5, color: const Color(0xFF1C2430));
    }
    // The called house's service drop: from a mast on its roof up to its
    // phase wire (a coloured clamp) and the neutral — left of the docket, so
    // it shows on every phone.
    final roofAt = Offset(g.house.left + 16, g.house.top - 12);
    const clampX = 210.0;
    double yAt(int i, double x) {
      // the wire's sag at x (same curve as above)
      final t = ((x - (M6ChainGeo.poleX + 50)) / (360 - (M6ChainGeo.poleX + 50))).clamp(0.0, 1.0);
      final y0 = g.wireY(i);
      return (1 - t) * (1 - t) * y0 + 2 * (1 - t) * t * (y0 + 10) + t * t * (y0 + 3);
    }

    final pY = yAt(rig.phase, clampX);
    final nY = yAt(3, clampX + 8);
    // (the cable is drawn over the house, in [_nearHouse])
    _dropTo = (roofAt, Offset(clampX, pY), Offset(clampX + 8, nY));
    c.drawRect(Rect.fromCenter(center: Offset(clampX, pY), width: 8, height: 6), Paint()..color = m6PhaseColors[rig.phase]);
    c.drawRect(Rect.fromCenter(center: Offset(clampX + 8, nY), width: 8, height: 6), Paint()..color = const Color(0xFF222222));
  }

  void _nearHouse(Canvas c, M6ChainGeo g) {
    final r = g.house;
    c.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFFF1DDBA), Color(0xFFE0C79C)]).createShader(r),
    );
    final roof = Path()
      ..moveTo(r.left - 6, r.top)
      ..lineTo(r.center.dx, r.top - 14)
      ..lineTo(r.right + 6, r.top)
      ..close();
    c.drawPath(roof, Paint()..color = const Color(0xFFA24E33));
    // The service drop: a mast on the roof, the cable up to its phase clamp.
    final d = _dropTo;
    if (d != null) {
      final cable = Paint()
        ..color = const Color(0xFF1A1E22)
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke;
      c.drawLine(Offset(d.$1.dx, r.top - 4), d.$1, Paint()
        ..color = const Color(0xFF7C858C)
        ..strokeWidth = 2.4);
      c.drawPath(Path()..moveTo(d.$1.dx, d.$1.dy)..quadraticBezierTo((d.$1.dx + d.$2.dx) / 2, d.$1.dy + 2, d.$2.dx, d.$2.dy), cable);
      c.drawPath(Path()..moveTo(d.$1.dx + 2, d.$1.dy)..quadraticBezierTo((d.$1.dx + d.$3.dx) / 2, d.$1.dy + 4, d.$3.dx, d.$3.dy), cable);
    }
    // Veranda posts and the door.
    final post = Paint()..color = const Color(0xFF8A7154);
    c.drawRect(Rect.fromLTWH(r.left + 2, r.top, 4, r.height), post);
    c.drawRect(Rect.fromLTWH(r.right - 6, r.top, 4, r.height), post);
    final door = Rect.fromLTWH(r.left + 26, r.bottom - 40, 22, 40);
    c.drawRect(door, Paint()..color = const Color(0xFF6B4A2E));
    // House number plate.
    final plate = Rect.fromLTWH(r.left + 10, r.top + 4, 18, 13);
    c.drawRRect(RRect.fromRectAndRadius(plate, const Radius.circular(2)), Paint()..color = const Color(0xFF1F4E79));
    _text(c, '${rig.house}', plate.center, size: 9, color: Colors.white);
    // A window: lit once the light is back.
    final win = Rect.fromLTWH(r.right - 26, r.bottom - 34, 16, 14);
    c.drawRect(win, Paint()..color = rig.lit ? const Color(0xFFFFE27A) : const Color(0xFF39424D));
    // The meter board.
    final b = g.meterBoard;
    c.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(4)), Paint()..color = const Color(0xFF5B3B22));
    c.drawRRect(RRect.fromRectAndRadius(b.deflate(3), const Radius.circular(3)), Paint()..color = const Color(0xFF8B6440));
    // The main switch (top half): a lever, up = ON.
    final ms = g.mainHit.deflate(6);
    c.drawRRect(RRect.fromRectAndRadius(ms, const Radius.circular(3)), Paint()..color = const Color(0xFF2B2F35));
    final lx = ms.center.dx;
    final ly = rig.mainOn ? ms.top + ms.height * 0.3 : ms.bottom - ms.height * 0.3;
    c.drawLine(Offset(lx, ms.center.dy), Offset(lx, ly), Paint()
      ..color = const Color(0xFFE53935)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round);
    _text(c, 'ON', Offset(ms.right - 8, ms.top + 6), size: 5.5, color: const Color(0xFFDDE3EA));
    _text(c, 'OFF', Offset(ms.right - 8, ms.bottom - 5), size: 5.5, color: const Color(0xFFDDE3EA));
    // The kit-kat (bottom half): a porcelain base; the carrier in or drawn.
    final kk = g.kitkatHit.deflate(6);
    c.drawRRect(RRect.fromRectAndRadius(kk, const Radius.circular(3)), Paint()..color = const Color(0xFFD8D3C8));
    final carrier = Rect.fromCenter(center: kk.center, width: kk.width * 0.6, height: kk.height * 0.7);
    if (!rig.kitkatOut) {
      c.drawRRect(RRect.fromRectAndRadius(carrier, const Radius.circular(3)), Paint()..color = _porcelain);
      c.drawRRect(
          RRect.fromRectAndRadius(carrier, const Radius.circular(3)),
          Paint()
            ..color = const Color(0xFF9AA1A7)
            ..style = PaintingStyle.stroke);
      _text(c, '16A', carrier.center, size: 6.5);
    } else {
      c.drawRect(Rect.fromCenter(center: kk.center, width: carrier.width * 0.5, height: 4), Paint()..color = const Color(0xFF6E6A62));
    }
  }

  void _dtr(Canvas c, M6ChainGeo g) {
    final px = M6ChainGeo.poleX;
    // The pole.
    c.drawRect(
      Rect.fromLTWH(px - 5, g.topY, 10, g.groundY - g.topY),
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFF8D959C), Color(0xFF5E666D)]).createShader(Rect.fromLTWH(px - 5, g.topY, 10, 10)),
    );
    // The incoming 11 kV line (left) to the AB's line-side jaws.
    final hv = Paint()
      ..color = _wire
      ..strokeWidth = 1.5;
    final jawTop = g.abArmY - 12;
    final line = g.abLineHit;
    c.drawRRect(RRect.fromRectAndRadius(line.deflate(4), const Radius.circular(3)), Paint()..color = const Color(0xFF4B5258));
    for (var i = 0; i < 3; i++) {
      c.drawLine(Offset(0, line.top + 6 + i * 5.0), Offset(line.right - 4, line.top + 6 + i * 5.0), hv);
      c.drawLine(Offset(line.right - 4, line.top + 6 + i * 5.0), Offset(M6ChainGeo.phaseX[i], jawTop), hv);
    }
    // The AB arm and its three blades (closed: upright; open: swung out).
    c.drawRect(Rect.fromLTWH(26, g.abArmY + 12, 90, 4), Paint()..color = _steel);
    for (var i = 0; i < 3; i++) {
      final x = M6ChainGeo.phaseX[i];
      final ins = Paint()..color = _porcelain;
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 3, jawTop - 2, 6, 6), const Radius.circular(2)), ins);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 3, g.abArmY + 6, 6, 6), const Radius.circular(2)), ins);
      final pivot = Offset(x, g.abArmY + 8);
      final tip = rig.abClosed ? Offset(x, jawTop + 2) : pivot + Offset.fromDirection(-math.pi / 2 - 1.0, 20);
      c.drawLine(pivot, tip, Paint()
        ..color = const Color(0xFFB8C0C6)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round);
    }
    // The operating rod down the pole to the handle.
    c.drawLine(Offset(px + 7, g.abArmY + 16), Offset(px + 7, g.abHandle.top + 4), Paint()
      ..color = const Color(0xFF7C858C)
      ..strokeWidth = 2);
    c.drawLine(Offset(px + 7, g.abHandle.top + 4), Offset(g.abHandle.center.dx, g.abHandle.top + 4), Paint()
      ..color = const Color(0xFF7C858C)
      ..strokeWidth = 2);
    // The handle's guide slot and its knob.
    final slot = Rect.fromLTRB(g.abHandle.center.dx - 3, g.abHandle.top + 4, g.abHandle.center.dx + 3, g.abHandle.bottom - 4);
    c.drawRRect(RRect.fromRectAndRadius(slot, const Radius.circular(3)), Paint()..color = const Color(0xFF3A4046));
    final k = g.knob(rig.abClosed);
    c.drawLine(Offset(px + 5, k.dy), k, Paint()
      ..color = const Color(0xFF9AA2A8)
      ..strokeWidth = 4);
    c.drawCircle(k, 7, Paint()..color = const Color(0xFFE53935));
    c.drawCircle(k, 7, Paint()
      ..color = const Color(0xFF7A1A14)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4);
    // The HG fuses: two horns on porcelain, a fuse wire between them.
    c.drawRect(Rect.fromLTWH(22, g.hgY + 10, 96, 4), Paint()..color = _steel);
    for (var i = 0; i < 3; i++) {
      final x = M6ChainGeo.phaseX[i];
      final ins = Paint()..color = _porcelain;
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 13, g.hgY, 6, 10), const Radius.circular(2)), ins);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x + 7, g.hgY, 6, 10), const Radius.circular(2)), ins);
      final horn = Paint()
        ..color = _copper
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      c.drawPath(Path()..moveTo(x - 10, g.hgY)..quadraticBezierTo(x - 12, g.hgY - 12, x - 4, g.hgY - 16), horn);
      c.drawPath(Path()..moveTo(x + 10, g.hgY)..quadraticBezierTo(x + 12, g.hgY - 12, x + 4, g.hgY - 16), horn);
      if (rig.hgBlown != i) {
        c.drawLine(Offset(x - 9, g.hgY - 3), Offset(x + 9, g.hgY - 3), Paint()
          ..color = const Color(0xFF3E444A)
          ..strokeWidth = 1.8);
      }
      // Down-leads to the tank.
      c.drawLine(Offset(x, g.hgY + 14), Offset(44 + 26.0 * i, g.tank.top - 6), hv);
    }
    if (rig.earthed) {
      // The earth set: clamps on the three HG lower terminals, a lead down the pole.
      final e = Paint()
        ..color = const Color(0xFF2E7D32)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      for (var i = 0; i < 3; i++) {
        final x = M6ChainGeo.phaseX[i];
        c.drawCircle(Offset(x + 10, g.hgY + 8), 3, Paint()..color = const Color(0xFF2E7D32));
        c.drawLine(Offset(x + 10, g.hgY + 8), Offset(x + 10, g.hgY + 22), e);
      }
      c.drawLine(Offset(M6ChainGeo.phaseX[0] + 10, g.hgY + 22), Offset(M6ChainGeo.phaseX[2] + 10, g.hgY + 22), e);
      c.drawLine(Offset(px - 8, g.hgY + 22), Offset(px - 8, g.groundY), e);
    }
    // The tank, HT bushings, nameplate.
    final t = g.tank;
    for (var i = 0; i < 3; i++) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(41 + 26.0 * i, t.top - 9, 6, 10), const Radius.circular(2)), Paint()..color = const Color(0xFF8D6E4C));
    }
    c.drawRRect(
      RRect.fromRectAndRadius(t, const Radius.circular(5)),
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFF8FA293), Color(0xFF6F8273)]).createShader(t),
    );
    for (var x = t.left + 8; x < t.right - 4; x += 8) {
      c.drawLine(Offset(x, t.top + 6), Offset(x, t.bottom - 6), Paint()
        ..color = const Color(0xFF627566)
        ..strokeWidth = 1.5);
    }
    final plate = Rect.fromCenter(center: t.center, width: 40, height: 14);
    c.drawRRect(RRect.fromRectAndRadius(plate, const Radius.circular(2)), Paint()..color = const Color(0xFFE3E6DE));
    _text(c, '${rig.kva} kVA', plate.center, size: 7.5);
    // LT leads down to the box.
    for (var i = 0; i < 3; i++) {
      c.drawLine(Offset(50 + 18.0 * i, t.bottom), Offset(30 + 26.0 * i, g.ltBox.top), Paint()
        ..color = const Color(0xFF1A1E22)
        ..strokeWidth = 2);
    }
    // The LT box: door shut, or open with the supply bar and three HRCs.
    final b = g.ltBox;
    c.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(4)), Paint()..color = const Color(0xFF7D868C));
    if (!rig.doorOpen) {
      c.drawRRect(
        RRect.fromRectAndRadius(b.deflate(3), const Radius.circular(3)),
        Paint()
          ..shader = const LinearGradient(colors: [Color(0xFF98A2A9), Color(0xFF7A848B)]).createShader(b),
      );
      c.drawCircle(Offset(b.right - 10, b.center.dy), 3, Paint()..color = const Color(0xFF3A4046));
    } else {
      c.drawRect(b.deflate(3), Paint()..color = const Color(0xFF2B3036));
      // The door hangs open below the box (hinged at its bottom edge), with
      // its handle on the part a tap shuts.
      final lh = math.min(15.0, g.h * 0.045);
      final leaf = Path()
        ..moveTo(b.left + 2, b.bottom)
        ..lineTo(b.right - 2, b.bottom)
        ..lineTo(b.right + 1, b.bottom + lh)
        ..lineTo(b.left - 1, b.bottom + lh)
        ..close();
      c.drawPath(
        leaf,
        Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF6E777E), Color(0xFF9AA4AB)]).createShader(Rect.fromLTRB(b.left, b.bottom, b.right, b.bottom + lh)),
      );
      c.drawCircle(Offset(g.doorHit.center.dx, b.bottom + lh * 0.55), 2.6, Paint()..color = const Color(0xFF3A4046));
      final bar = g.ltSupplyHit.deflate(3);
      c.drawRect(bar, Paint()..color = _copper);
      for (var i = 0; i < 3; i++) {
        final hc = g.hrcCenter(i);
        final base = Rect.fromCenter(center: hc, width: 20, height: b.height * 0.44);
        c.drawRect(base, Paint()..color = const Color(0xFF545B62));
        c.drawLine(Offset(hc.dx, bar.bottom), Offset(hc.dx, base.top), Paint()
          ..color = _copper
          ..strokeWidth = 2);
        final s = rig.hrc[i];
        if (s != M6HrcState.out) {
          final body = Rect.fromCenter(center: hc, width: 14, height: b.height * 0.36);
          c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(3)), Paint()..color = const Color(0xFFEDE6D8));
          c.drawRect(Rect.fromLTWH(body.left, body.top, body.width, 3), Paint()..color = const Color(0xFFB0B6BB));
          c.drawRect(Rect.fromLTWH(body.left, body.bottom - 3, body.width, 3), Paint()..color = const Color(0xFFB0B6BB));
          c.drawCircle(body.center, 2.6, Paint()..color = s == M6HrcState.blown ? const Color(0xFF1A1A1A) : const Color(0xFFE53935));
        }
        _text(c, const ['R', 'Y', 'B'][i], Offset(hc.dx, b.bottom - 5), size: 6, color: const Color(0xFFDDE3EA));
      }
    }
    // The LT switch lever (ON up / OFF down) with its lock and tag.
    final lv = g.ltLeverHit;
    final housing = Rect.fromLTWH(lv.left + 6, lv.top + 4, 20, lv.height - 8);
    c.drawRRect(RRect.fromRectAndRadius(housing, const Radius.circular(3)), Paint()..color = const Color(0xFF3A4046));
    final ly = rig.ltOn ? housing.top + 8 : housing.bottom - 8;
    c.drawLine(Offset(housing.center.dx, housing.center.dy), Offset(housing.center.dx, ly), Paint()
      ..color = const Color(0xFFE53935)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round);
    _text(c, 'ON', Offset(housing.center.dx, housing.top - 3), size: 5.5, color: const Color(0xFF1C2430));
    _text(c, 'OFF', Offset(housing.center.dx, housing.bottom + 4), size: 5.5, color: const Color(0xFF1C2430));
    if (rig.lockTag) {
      c.drawCircle(Offset(housing.right + 2, ly), 4, Paint()
        ..color = const Color(0xFFFFC107)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
      c.drawRect(Rect.fromLTWH(housing.right - 2, ly + 4, 10, 12), Paint()..color = const Color(0xFFD32F2F));
    }
  }

  void _van(Canvas c, M6ChainGeo g) {
    final v = g.van;
    c.drawRRect(
      RRect.fromRectAndRadius(v, const Radius.circular(6)),
      Paint()
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF2F4F5), Color(0xFFC9CFD3)]).createShader(v),
    );
    c.drawRect(Rect.fromLTWH(v.left, v.top + 14, v.width, 4), Paint()..color = const Color(0xFF1F5F8F));
    c.drawCircle(Offset(v.left + 16, v.bottom), 7, Paint()..color = const Color(0xFF22272C));
    c.drawCircle(Offset(v.right - 16, v.bottom), 7, Paint()..color = const Color(0xFF22272C));
    // The hook rail.
    c.drawLine(Offset(v.left + 6, v.top + 24), Offset(v.right - 6, v.top + 24), Paint()
      ..color = const Color(0xFF5E666D)
      ..strokeWidth = 2);
    if (!rig.gloves) _glovesIcon(c, g.ppeAt(0));
    if (!rig.goggles) m6GogglesIcon(c, g.ppeAt(1), 1);
    // The scrap pile.
    final s = g.scrapAt;
    final p = Paint()
      ..color = const Color(0xFF6E6A62)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    c.drawOval(Rect.fromCenter(center: s, width: 18, height: 7), Paint()..color = const Color(0xFF5A544A));
    c.drawLine(s + const Offset(-6, -2), s + const Offset(5, -6), p);
    c.drawLine(s + const Offset(-3, -5), s + const Offset(7, -1), p);
  }

  void _glovesIcon(Canvas c, Offset at) {
    final p = Paint()..color = const Color(0xFFC62828);
    c.drawLine(at + const Offset(0, -14), at + const Offset(0, -8), Paint()
      ..color = const Color(0xFF5E666D)
      ..strokeWidth = 1.5);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: at + const Offset(-4, 2), width: 9, height: 16), const Radius.circular(4)), p);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: at + const Offset(5, 3), width: 9, height: 16), const Radius.circular(4)), p);
  }

  @override
  bool shouldRepaint(M6ChainPainter old) => old.geo != geo || old.rig != rig || old.seed != seed;
}

/// Safety goggles (the hook, the worker's head).
void m6GogglesIcon(Canvas c, Offset at, double s) {
  final strap = Paint()
    ..color = const Color(0xFF1E2A33)
    ..strokeWidth = 1.6 * s;
  c.drawLine(at + Offset(-10 * s, 0), at + Offset(10 * s, 0), strap);
  final lens = Paint()..color = const Color(0xCC7FD3F7);
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: at + Offset(-4 * s, 0), width: 7 * s, height: 6 * s), Radius.circular(2 * s)), lens);
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: at + Offset(4 * s, 0), width: 7 * s, height: 6 * s), Radius.circular(2 * s)), lens);
}

/// The goggles on the worker's head once worn (over the figure).
class M6GogglesPainter extends CustomPainter {
  const M6GogglesPainter();

  @override
  void paint(Canvas c, Size size) => m6GogglesIcon(c, Offset(size.width / 2, size.height * 0.12), 0.9);

  @override
  bool shouldRepaint(M6GogglesPainter old) => false;
}

/// The reading card: a close-up of the last thing looked at or drawn out.
class M6CardPainter extends CustomPainter {
  const M6CardPainter({required this.card, this.hgBlown = -1, this.content = M6Content.melted});

  final M6Card card;
  final int hgBlown;
  final M6Content content;

  @override
  void paint(Canvas c, Size size) {
    final r = Offset.zero & size;
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(10)), Paint()..color = const Color(0xF0101A2B));
    c.drawRRect(
        RRect.fromRectAndRadius(r.deflate(1), const Radius.circular(10)),
        Paint()
          ..color = const Color(0xFF6E7C90)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6);
    switch (card) {
      case M6Card.hg:
        for (var i = 0; i < 3; i++) {
          final x = size.width * (0.2 + 0.3 * i);
          final y = size.height * 0.62;
          final horn = Paint()
            ..color = _copper
            ..strokeWidth = 3
            ..style = PaintingStyle.stroke;
          c.drawPath(Path()..moveTo(x - 14, y + 10)..quadraticBezierTo(x - 16, y - 8, x - 5, y - 18), horn);
          c.drawPath(Path()..moveTo(x + 14, y + 10)..quadraticBezierTo(x + 16, y - 8, x + 5, y - 18), horn);
          c.drawRect(Rect.fromLTWH(x - 18, y + 10, 8, 8), Paint()..color = _porcelain);
          c.drawRect(Rect.fromLTWH(x + 10, y + 10, 8, 8), Paint()..color = _porcelain);
          if (hgBlown != i) {
            c.drawLine(Offset(x - 13, y + 2), Offset(x + 13, y + 2), Paint()
              ..color = const Color(0xFFF4F4EE)
              ..strokeWidth = 2.4);
          } else {
            // A melted stub on each horn.
            final stub = Paint()
              ..color = const Color(0xFFB8B8AE)
              ..strokeWidth = 2.4;
            c.drawLine(Offset(x - 13, y + 2), Offset(x - 8, y + 4), stub);
            c.drawLine(Offset(x + 13, y + 2), Offset(x + 9, y + 5), stub);
          }
        }
      case M6Card.blades:
        for (var i = 0; i < 3; i++) {
          final x = size.width * (0.2 + 0.3 * i);
          final pivot = Offset(x, size.height * 0.78);
          c.drawRect(Rect.fromCenter(center: Offset(x, size.height * 0.2), width: 10, height: 8), Paint()..color = _porcelain);
          c.drawRect(Rect.fromCenter(center: pivot, width: 10, height: 8), Paint()..color = _porcelain);
          c.drawLine(pivot, pivot + Offset.fromDirection(-math.pi / 2 - 1.0, size.height * 0.5), Paint()
            ..color = const Color(0xFFB8C0C6)
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round);
        }
      case M6Card.kitkat:
        final carrier = Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: size.width * 0.7, height: size.height * 0.5);
        c.drawRRect(RRect.fromRectAndRadius(carrier, const Radius.circular(6)), Paint()..color = const Color(0xFFCDD2D6));
        final a = Offset(carrier.left + 10, carrier.center.dy);
        final b = Offset(carrier.right - 10, carrier.center.dy);
        c.drawCircle(a, 3, Paint()..color = const Color(0xFF9AA1A7));
        c.drawCircle(b, 3, Paint()..color = const Color(0xFF9AA1A7));
        _wireBetween(c, a, b, content);
      case M6Card.hrc:
        final base = Rect.fromCenter(center: Offset(size.width / 2, size.height / 2), width: size.width * 0.78, height: size.height * 0.46);
        c.drawRect(base, Paint()..color = const Color(0xFF545B62));
        final a = Offset(base.left + 12, base.center.dy);
        final b = Offset(base.right - 12, base.center.dy);
        c.drawRect(Rect.fromCenter(center: a, width: 8, height: 16), Paint()..color = const Color(0xFFB0B6BB));
        c.drawRect(Rect.fromCenter(center: b, width: 8, height: 16), Paint()..color = const Color(0xFFB0B6BB));
        if (content == M6Content.strip || content == M6Content.thickCopper) {
          // A hidden bypass across the base contacts, behind the cartridge.
          _wireBetween(c, a, b, content);
        } else {
          // The drawn cartridge: its dot gone.
          final body = Rect.fromCenter(center: base.center, width: base.width * 0.6, height: base.height * 0.7);
          c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(4)), Paint()..color = const Color(0xFFEDE6D8));
          c.drawCircle(body.center, 3.5, Paint()..color = const Color(0xFF1A1A1A));
        }
    }
  }

  void _wireBetween(Canvas c, Offset a, Offset b, M6Content k) {
    switch (k) {
      case M6Content.melted:
        // A thin tinned wire, melted through in the middle (a bead each side).
        final p = Paint()
          ..color = const Color(0xFF6F6F68)
          ..strokeWidth = 1.4;
        final m = Offset.lerp(a, b, 0.5)!;
        c.drawLine(a, m - const Offset(6, 0), p);
        c.drawLine(m + const Offset(6, 0), b, p);
        c.drawCircle(m - const Offset(6, 0), 2.2, Paint()..color = const Color(0xFF55554F));
        c.drawCircle(m + const Offset(6, 0), 2.2, Paint()..color = const Color(0xFF55554F));
        c.drawCircle(m, 4, Paint()..color = const Color(0x55222222));
      case M6Content.gi:
        c.drawLine(a, b, Paint()
          ..color = const Color(0xFF4F5359)
          ..strokeWidth = 3.6);
        for (var t = 0.15; t < 0.9; t += 0.18) {
          final m = Offset.lerp(a, b, t)!;
          c.drawCircle(m, 1.4, Paint()..color = const Color(0xFF9C6A3C));
        }
      case M6Content.aluminium:
        for (var k2 = -1; k2 <= 1; k2++) {
          c.drawLine(a + Offset(0, k2 * 1.8), b + Offset(0, -k2 * 1.8), Paint()
            ..color = const Color(0xFF8E979F)
            ..strokeWidth = 2);
        }
      case M6Content.thickCopper:
        c.drawLine(a, b, Paint()
          ..color = _copper
          ..strokeWidth = 4.2
          ..strokeCap = StrokeCap.round);
      case M6Content.strip:
        c.drawRect(Rect.fromPoints(a - const Offset(0, 3), b + const Offset(0, 3)), Paint()..color = _copper);
      case M6Content.blownHrc:
        break;
    }
  }

  @override
  bool shouldRepaint(M6CardPainter old) => old.card != card || old.hgBlown != hgBlown || old.content != content;
}

/// The arc flash (a deadly move): a white-hot burst at [at].
class M6FlashPainter extends CustomPainter {
  const M6FlashPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final r = 20 + 60 * v;
    c.drawCircle(
      at,
      r,
      Paint()
        ..shader = RadialGradient(colors: [
          Color.fromRGBO(255, 255, 255, 0.95 * (1 - v * 0.5)),
          Color.fromRGBO(255, 214, 90, 0.7 * (1 - v * 0.6)),
          const Color(0x00FF7A00),
        ], stops: const [0, 0.4, 1]).createShader(Rect.fromCircle(center: at, radius: r)),
    );
    final bolt = Paint()
      ..color = Color.fromRGBO(255, 240, 160, 1 - v * 0.7)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3 + v;
      final p1 = at + Offset.fromDirection(a, 10);
      final p2 = at + Offset.fromDirection(a + 0.2, 10 + 30 * v);
      c.drawLine(p1, p2, bolt);
    }
  }

  @override
  bool shouldRepaint(M6FlashPainter old) => old.v != v || old.at != at;
}
