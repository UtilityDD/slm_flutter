import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The site of "পিলারের তল্লাশি" (lesson 3.7, কাজ 2): a drawn, layered place —
// the morning sky, the village roofs, the DP structure with the distribution
// transformer behind, the lane, and the hero: the LT feeder pillar on its
// plinth. Closed (station ক): the roof cap with its seal, the door with its
// hasp and padlock, the plinth with the cable entries. Open (stations খ, গ):
// the R Y B N busbars, three outgoing SFUs (handle ON/OFF, three HRC fuses
// each, the outgoing cable down to the glands), the neutral link and the
// earthing terminal. On the ground: the kit bag with the insulated gloves and
// the megger. The only words in the art are the ones a worker reads: R Y B N,
// the feeder numbers, ON/OFF, MΩ.
//
// Design: 360 wide × the scene's height; the ground row follows the bottom of
// the screen (a tall phone gets more sky).

/// Where the trainee looks (stations ক and খ) — every place a fault can hide.
enum M3PillarInspectSpot { roof, lock, door, entry, top, busbar, fuse1, fuse2, fuse3, neutral, earth, glands }

/// What can be wrong (lesson 3.7: the daily checks, point 3's faults, myth 2).
enum M3PillarInspectFault { noLock, roofSeal, doorRust, entryGap, hotspot, waterIn, ratBite, wireFuse }

/// Which view the pillar is in.
enum M3PillarInspectView { closed, open }

const m3PillarInspectOutside = [M3PillarInspectSpot.roof, M3PillarInspectSpot.lock, M3PillarInspectSpot.door, M3PillarInspectSpot.entry];
const m3PillarInspectInside = [
  M3PillarInspectSpot.top,
  M3PillarInspectSpot.busbar,
  M3PillarInspectSpot.fuse1,
  M3PillarInspectSpot.fuse2,
  M3PillarInspectSpot.fuse3,
  M3PillarInspectSpot.neutral,
  M3PillarInspectSpot.earth,
  M3PillarInspectSpot.glands,
];

/// The fuse spot of outgoing feeder [k] (0–2).
M3PillarInspectSpot m3PillarInspectFuseSpot(int k) => const [M3PillarInspectSpot.fuse1, M3PillarInspectSpot.fuse2, M3PillarInspectSpot.fuse3][k];

/// Where things stand (design px, 360 wide).
@immutable
class M3PillarInspectGeo {
  const M3PillarInspectGeo({required this.height, required this.groundY});

  factory M3PillarInspectGeo.forScene(double h, double inset) => M3PillarInspectGeo(height: h, groundY: (h - 300 - inset).clamp(380.0, 700.0));

  final double height;
  final double groundY;

  double get horizonY => groundY - 150;

  /// The pillar's body (on its plinth).
  Rect get pillar => Rect.fromLTRB(118, groundY - 304, 342, groundY - 12);
  Rect get roofCap => Rect.fromLTRB(110, groundY - 318, 350, groundY - 300);
  Rect get plinth => Rect.fromLTRB(108, groundY - 12, 352, groundY + 10);

  /// Inside the open pillar.
  Rect get inner => Rect.fromLTRB(128, groundY - 296, 332, groundY - 20);
  double get _x0 => inner.left;
  double get _y0 => inner.top;

  /// The four busbars' centre lines (R Y B N).
  List<double> get busY => [for (var i = 0; i < 4; i++) _y0 + 36 + i * 12];

  /// Outgoing SFU [k]: the whole unit, its handle part, its fuse part.
  Rect unit(int k) => Rect.fromLTWH(_x0 + 12 + k * 52, _y0 + 86, 48, 92);
  Rect handle(int k) => Rect.fromLTWH(unit(k).left, unit(k).top, 48, 36);
  Rect fuses(int k) => Rect.fromLTWH(unit(k).left, unit(k).top + 38, 48, 54);

  /// Outgoing cable [k] below its unit (where the megger leads go).
  Rect cable(int k) => Rect.fromLTWH(unit(k).left, _y0 + 180, 48, 52);

  /// The terminal on cable [k] the megger's L lead goes on.
  Offset cableLug(int k) => Offset(unit(k).center.dx, _y0 + 192);

  Rect get neutral => Rect.fromLTWH(_x0 + 166, _y0 + 86, 36, 92);
  Rect get earth => Rect.fromLTWH(_x0 + 166, _y0 + 184, 36, 46);
  Rect get glands => Rect.fromLTWH(_x0, _y0 + 236, 204, 40);

  /// Where a tap reaches [s] (≥ 44 design px).
  Rect spot(M3PillarInspectSpot s) => switch (s) {
        M3PillarInspectSpot.roof => Rect.fromLTRB(110, groundY - 330, 350, groundY - 292),
        M3PillarInspectSpot.lock => Rect.fromCenter(center: hasp, width: 52, height: 70),
        M3PillarInspectSpot.door => Rect.fromLTRB(176, groundY - 288, 340, groundY - 56),
        M3PillarInspectSpot.entry => Rect.fromLTRB(108, groundY - 54, 352, groundY + 14),
        M3PillarInspectSpot.top => Rect.fromLTRB(inner.left, inner.top - 8, inner.right, inner.top + 28),
        M3PillarInspectSpot.busbar => Rect.fromLTRB(inner.left, inner.top + 28, inner.right, inner.top + 84),
        M3PillarInspectSpot.fuse1 => unit(0),
        M3PillarInspectSpot.fuse2 => unit(1),
        M3PillarInspectSpot.fuse3 => unit(2),
        M3PillarInspectSpot.neutral => neutral.inflate(4),
        M3PillarInspectSpot.earth => earth.inflate(4),
        M3PillarInspectSpot.glands => glands.inflate(2),
      };

  /// Where a fault's mark sits on [s] (the ring's centre).
  Offset spotMark(M3PillarInspectSpot s) => switch (s) {
        M3PillarInspectSpot.door => Offset(256, groundY - 170),
        M3PillarInspectSpot.entry => Offset(230, groundY - 22),
        _ => spot(s).center,
      };

  /// The hasp on the door's free (left) edge.
  Offset get hasp => Offset(146, groundY - 158);

  /// The kit bag on the ground: the gloves and the megger.
  Rect get kit => Rect.fromLTWH(12, groundY + 8, 100, 46);
  Rect get gloves => Rect.fromLTWH(10, groundY + 2, 50, 56);
  Rect get megger => Rect.fromLTWH(64, groundY + 4, 46, 44);

  /// The trainee's box (feet on the ground, left of the pillar).
  Rect get trainee => Rect.fromLTWH(4, groundY - 208, 104, 208);

  @override
  bool operator ==(Object other) => other is M3PillarInspectGeo && other.height == height && other.groundY == groundY;

  @override
  int get hashCode => Object.hash(height, groundY);
}

/// The whole place, in one painter (it repaints only when the page rebuilds
/// it with a new state — an idle screen draws nothing).
class M3PillarInspectPainter extends CustomPainter {
  const M3PillarInspectPainter({
    required this.geo,
    required this.view,
    required this.faults,
    this.flagged = const {},
    this.missed = const {},
    this.switchedOff = const {},
    this.fusesOut = const {},
    this.meggerOn,
    this.glovesOn = false,
    this.lockedNew = false,
    this.lockMissing = false,
  });

  final M3PillarInspectGeo geo;
  final M3PillarInspectView view;

  /// The faults on show, by spot.
  final Map<M3PillarInspectSpot, M3PillarInspectFault> faults;

  /// Spots the trainee marked as faulty (a red ring).
  final Set<M3PillarInspectSpot> flagged;

  /// Faults he missed (an orange ring, after the report).
  final Set<M3PillarInspectSpot> missed;
  final Set<int> switchedOff;
  final Set<int> fusesOut;

  /// The cable the megger's leads are on.
  final int? meggerOn;
  final bool glovesOn;

  /// The door closed and locked at the end of the job.
  final bool lockedNew;

  /// The padlock is missing (station ক's fault; also later until locked).
  final bool lockMissing;

  bool _has(M3PillarInspectFault f) => faults.containsValue(f);

  @override
  void paint(Canvas c, Size size) {
    _land(c, size);
    _transformer(c);
    _kit(c);
    if (view == M3PillarInspectView.closed || lockedNew) {
      _closed(c);
    } else {
      _open(c);
    }
    _rings(c);
  }

  // --- the place --------------------------------------------------------------
  void _land(Canvas c, Size size) {
    final w = size.width;
    final g = geo.groundY;
    final hz = geo.horizonY;
    c.drawRect(
        Rect.fromLTWH(0, 0, w, hz + 4),
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3B78B0), Color(0xFF8DBBDD), Color(0xFFE8EED8)])
              .createShader(Rect.fromLTWH(0, 0, w, hz + 4)));
    final cloud = Paint()..color = const Color(0x66FFFFFF);
    for (final (x, y, r) in [(40.0, 96.0, 20.0), (68.0, 88.0, 26.0), (98.0, 98.0, 18.0), (230.0, 140.0, 16.0), (256.0, 132.0, 22.0), (284.0, 142.0, 15.0)]) {
      c.drawCircle(Offset(x, y), r, cloud);
    }
    // Village roofs and trees on the horizon.
    final far = Path()..moveTo(0, hz);
    for (var x = 0.0; x <= w; x += 16) {
      far.lineTo(x, hz - 16 - 9 * math.sin(x * 0.06) - 5 * math.cos(x * 0.21));
    }
    far
      ..lineTo(w, hz + 2)
      ..lineTo(0, hz + 2)
      ..close();
    c.drawPath(far, Paint()..color = const Color(0xFF557F58));
    final roof = Paint()..color = const Color(0xFF8A4B36);
    final wall = Paint()..color = const Color(0xFFDCCBA8);
    for (final x in [150.0, 214.0, 318.0]) {
      c.drawRect(Rect.fromLTWH(x, hz - 18, 30, 18), wall);
      c.drawPath(
          Path()
            ..moveTo(x - 4, hz - 18)
            ..lineTo(x + 15, hz - 32)
            ..lineTo(x + 34, hz - 18)
            ..close(),
          roof);
    }
    // The verge, then the lane to the bottom.
    c.drawRect(Rect.fromLTWH(0, hz, w, g - hz),
        Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF86A75F), Color(0xFF627F45)]).createShader(Rect.fromLTWH(0, hz, w, g - hz)));
    c.drawRect(Rect.fromLTWH(0, g, w, size.height - g),
        Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFB8A079), Color(0xFF8C7556)]).createShader(Rect.fromLTWH(0, g, w, size.height - g)));
    final pebble = Paint()..color = const Color(0x33000000);
    final rnd = math.Random(7);
    for (var i = 0; i < 24; i++) {
      c.drawCircle(Offset(rnd.nextDouble() * w, g + 6 + rnd.nextDouble() * (size.height - g - 10)), 1.2 + rnd.nextDouble() * 1.6, pebble);
    }
  }

  /// The DP structure and the distribution transformer behind, on the left.
  void _transformer(Canvas c) {
    final g = geo.groundY;
    final base = geo.horizonY + 40;
    final top = math.max(40.0, g - 470);
    final pole = Paint()..shader = const LinearGradient(colors: [Color(0xFFB4B4AD), Color(0xFF8A8A83)]).createShader(Rect.fromLTRB(20, top, 110, base));
    for (final x in [28.0, 96.0]) {
      c.drawPath(
          Path()
            ..moveTo(x - 4, top)
            ..lineTo(x + 4, top)
            ..lineTo(x + 6, base)
            ..lineTo(x - 6, base)
            ..close(),
          pole);
    }
    final steel = Paint()..color = const Color(0xFF4A4F57);
    c.drawRect(Rect.fromLTWH(18, top + 14, 92, 4), steel);
    c.drawRect(Rect.fromLTWH(22, base - 92, 84, 5), steel);
    // The tank with its fins and three bushings.
    final tank = Rect.fromLTWH(38, base - 136, 52, 44);
    c.drawRRect(RRect.fromRectAndRadius(tank, const Radius.circular(4)), Paint()..color = const Color(0xFF6E8A6A));
    final fin = Paint()
      ..color = const Color(0xFF55704F)
      ..strokeWidth = 2;
    for (var i = 0; i < 6; i++) {
      final x = tank.left + 6 + i * 8;
      c.drawLine(Offset(x, tank.top + 6), Offset(x, tank.bottom - 4), fin);
    }
    final bush = Paint()..color = const Color(0xFF8B5E3C);
    for (var i = 0; i < 3; i++) {
      c.drawRect(Rect.fromLTWH(tank.left + 8 + i * 16, tank.top - 10, 5, 10), bush);
    }
    // The LT cable down the pole and along to the pillar.
    final cable = Paint()
      ..color = const Color(0xFF1A1D22)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    c.drawPath(
        Path()
          ..moveTo(92, tank.center.dy)
          ..lineTo(100, tank.center.dy)
          ..lineTo(100, g - 2)
          ..lineTo(120, g + 4),
        cable);
  }

  void _kit(Canvas c) {
    final k = geo.kit;
    c.drawRRect(RRect.fromRectAndRadius(k.translate(0, 8), const Radius.circular(8)), Paint()..color = const Color(0xFF3F3A33));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(k.left, k.top + 10, k.width, k.height - 8), const Radius.circular(8)), Paint()..color = const Color(0xFF6B4F35));
    // The insulated gloves (red rubber) — gone from the bag once on.
    if (!glovesOn) {
      final glove = Paint()..color = const Color(0xFFD9402F);
      final gl = geo.gloves;
      for (final dx in [0.0, 14.0]) {
        final o = Offset(gl.left + 10 + dx, gl.top + 12);
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(o.dx, o.dy, 16, 26), const Radius.circular(6)), glove);
        for (var f = 0; f < 3; f++) {
          c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(o.dx + 1 + f * 5, o.dy - 9, 4, 11), const Radius.circular(2)), glove);
        }
        c.drawRect(Rect.fromLTWH(o.dx - 1, o.dy + 22, 18, 6), Paint()..color = const Color(0xFFF2C14E));
      }
    }
    // The megger: a yellow case, a dial, two terminals.
    final m = geo.megger;
    c.drawRRect(RRect.fromRectAndRadius(m, const Radius.circular(6)), Paint()..color = const Color(0xFFF2B21B));
    c.drawRRect(RRect.fromRectAndRadius(m, const Radius.circular(6)), Paint()
      ..color = const Color(0xFF3A2500)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);
    final dial = Rect.fromLTWH(m.left + 6, m.top + 6, m.width - 12, 20);
    c.drawRect(dial, Paint()..color = const Color(0xFFF7F3E3));
    final needleA = meggerOn == null ? math.pi * 0.95 : math.pi * 0.2;
    final pivot = Offset(dial.center.dx, dial.bottom - 1);
    c.drawLine(pivot, pivot + Offset(math.cos(needleA) * 15, -math.sin(needleA) * 15), Paint()
      ..color = const Color(0xFFD02A20)
      ..strokeWidth = 1.6);
    _text(c, 'MΩ', Offset(m.center.dx, m.bottom - 10), 8, const Color(0xFF2B2416));
    c.drawCircle(Offset(m.left + 9, m.bottom - 8), 3, Paint()..color = const Color(0xFFD83A2E));
    c.drawCircle(Offset(m.right - 9, m.bottom - 8), 3, Paint()..color = const Color(0xFF15191D));
    // The leads, from the megger to cable [meggerOn] (L) and the earth bar (E).
    final on = meggerOn;
    if (on != null) {
      void lead(Offset from, Offset to, Color col, double sag) {
        final mid = Offset((from.dx + to.dx) / 2, math.max(from.dy, to.dy) + sag);
        c.drawPath(
            Path()
              ..moveTo(from.dx, from.dy)
              ..quadraticBezierTo(mid.dx, mid.dy, to.dx, to.dy),
            Paint()
              ..color = col
              ..strokeWidth = 2.6
              ..style = PaintingStyle.stroke);
        c.drawCircle(to, 4, Paint()..color = col);
      }

      lead(Offset(m.left + 9, m.bottom - 8), geo.cableLug(on), const Color(0xFFD83A2E), 30);
      lead(Offset(m.right - 9, m.bottom - 8), geo.earth.center, const Color(0xFF15191D), 40);
    }
  }

  // --- closed ---------------------------------------------------------------
  void _closed(Canvas c) {
    final p = geo.pillar;
    final g = geo.groundY;
    // The plinth and the cables going in at its foot.
    c.drawRect(geo.plinth, Paint()..color = const Color(0xFF9C9A92));
    c.drawRect(Rect.fromLTWH(geo.plinth.left, geo.plinth.top, geo.plinth.width, 3), Paint()..color = const Color(0xFF7D7B74));
    // The body.
    c.drawRect(p, Paint()..shader = const LinearGradient(colors: [Color(0xFF8E9AA1), Color(0xFFB5C0C6), Color(0xFF7C878E)]).createShader(p));
    // The door (hinged on the right) and its gap.
    final door = Rect.fromLTRB(p.left + 8, p.top + 10, p.right - 8, p.bottom - 10);
    final ajar = lockMissing && !lockedNew;
    c.drawRect(door, Paint()..color = const Color(0xFF9EABB2));
    c.drawRect(door, Paint()
      ..color = const Color(0xFF55616A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
    if (ajar) {
      // Not shut: a dark gap along the free edge.
      c.drawRect(Rect.fromLTWH(door.left - 2, door.top + 4, 6, door.height - 8), Paint()..color = const Color(0xFF1C2228));
    }
    // Louvres.
    final louvre = Paint()
      ..color = const Color(0xFF6F7C84)
      ..strokeWidth = 2;
    for (var i = 0; i < 4; i++) {
      final y = door.top + 18 + i * 8;
      c.drawLine(Offset(door.center.dx - 40, y), Offset(door.center.dx + 40, y), louvre);
    }
    // The danger plate (a worker reads it; no words needed — the bolt).
    final plate = Rect.fromCenter(center: Offset(door.center.dx + 6, door.top + 92), width: 54, height: 40);
    c.drawRRect(RRect.fromRectAndRadius(plate, const Radius.circular(4)), Paint()..color = const Color(0xFFF7F3E3));
    c.drawRRect(RRect.fromRectAndRadius(plate, const Radius.circular(4)), Paint()
      ..color = const Color(0xFFD02A20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
    c.drawPath(
        Path()
          ..moveTo(plate.center.dx + 4, plate.top + 6)
          ..lineTo(plate.center.dx - 6, plate.center.dy + 2)
          ..lineTo(plate.center.dx + 2, plate.center.dy + 2)
          ..lineTo(plate.center.dx - 4, plate.bottom - 6)
          ..lineTo(plate.center.dx + 8, plate.center.dy - 4)
          ..lineTo(plate.center.dx, plate.center.dy - 4)
          ..close(),
        Paint()..color = const Color(0xFFD02A20));
    // Hinges on the right.
    for (final y in [door.top + 30, door.bottom - 30]) {
      c.drawRect(Rect.fromLTWH(door.right - 3, y - 8, 7, 16), Paint()..color = const Color(0xFF4A545B));
    }
    // The rust and the broken corner (fault: doorRust).
    if (_has(M3PillarInspectFault.doorRust)) {
      final rust = Paint()..color = const Color(0xCC9A4A1C);
      final rnd = math.Random(11);
      for (var i = 0; i < 9; i++) {
        c.drawOval(Rect.fromCenter(center: Offset(door.center.dx - 30 + rnd.nextDouble() * 90, door.bottom - 90 + rnd.nextDouble() * 70), width: 10 + rnd.nextDouble() * 18, height: 6 + rnd.nextDouble() * 10), rust);
      }
      final hole = Path()
        ..moveTo(door.right - 50, door.bottom)
        ..lineTo(door.right - 46, door.bottom - 22)
        ..lineTo(door.right - 30, door.bottom - 30)
        ..lineTo(door.right - 18, door.bottom - 14)
        ..lineTo(door.right - 10, door.bottom)
        ..close();
      c.drawPath(hole, Paint()..color = const Color(0xFF1C2228));
      c.drawPath(hole, Paint()
        ..color = const Color(0xFF9A4A1C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5);
    }
    // The hasp and its padlock (fault: noLock — the hasp hangs empty).
    final h = geo.hasp;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: h, width: 14, height: 30), const Radius.circular(3)), Paint()..color = const Color(0xFF3E474E));
    if (!lockMissing || lockedNew) {
      final body = Rect.fromCenter(center: h + const Offset(0, 22), width: 22, height: 20);
      c.drawArc(Rect.fromCenter(center: h + const Offset(0, 12), width: 14, height: 16), math.pi, math.pi, false, Paint()
        ..color = const Color(0xFFB8BEC4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3);
      c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(3)), Paint()..color = const Color(0xFFC9A227));
      c.drawCircle(body.center, 2.2, Paint()..color = const Color(0xFF3A2C00));
    } else {
      // An empty staple.
      c.drawArc(Rect.fromCenter(center: h + const Offset(0, 4), width: 10, height: 10), 0, math.pi * 2, false, Paint()
        ..color = const Color(0xFF8A939A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
    }
    _roof(c);
    _entry(c, g);
  }

  void _roof(Canvas c) {
    final r = geo.roofCap;
    c.drawRect(r, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF6D7A82), Color(0xFF4E5A62)]).createShader(r));
    // The seal strip under the cap (black rubber); torn = a gap and a stain.
    final seal = Rect.fromLTWH(r.left + 8, r.bottom, r.width - 16, 5);
    c.drawRect(seal, Paint()..color = const Color(0xFF15191D));
    if (_has(M3PillarInspectFault.roofSeal)) {
      final gap = Rect.fromLTWH(r.left + 120, r.bottom - 1, 46, 8);
      c.drawRect(gap, Paint()..color = const Color(0xFFB5C0C6));
      final torn = Paint()
        ..color = const Color(0xFF15191D)
        ..strokeWidth = 2;
      c.drawLine(Offset(gap.left, gap.top + 2), Offset(gap.left + 6, gap.bottom + 4), torn);
      c.drawLine(Offset(gap.right, gap.top + 2), Offset(gap.right - 5, gap.bottom + 5), torn);
      // A crack in the cap and a wet streak just under it.
      c.drawLine(Offset(r.left + 136, r.top + 2), Offset(r.left + 148, r.bottom - 2), Paint()
        ..color = const Color(0xFF1C2228)
        ..strokeWidth = 2);
      c.drawRect(Rect.fromLTWH(gap.left + 14, gap.bottom, 16, 12), Paint()..color = const Color(0x664A6B85));
    }
  }

  void _entry(Canvas c, double g) {
    // Three cables go into the plinth; sealed (grey compound) or a gap.
    final cable = Paint()..color = const Color(0xFF1A1D22);
    for (final x in [170.0, 230.0, 290.0]) {
      c.drawRect(Rect.fromLTWH(x - 5, g - 2, 10, 14), cable);
    }
    if (_has(M3PillarInspectFault.entryGap)) {
      final hole = Path()
        ..moveTo(206, g + 10)
        ..quadraticBezierTo(208, g - 8, 230, g - 10)
        ..quadraticBezierTo(252, g - 8, 254, g + 10)
        ..close();
      c.drawPath(hole, Paint()..color = const Color(0xFF0E1114));
      c.drawRect(Rect.fromLTWH(225, g - 4, 10, 14), cable);
      // Loose earth thrown out by a burrow.
      final dirt = Paint()..color = const Color(0xFF7A6142);
      for (final (x, y) in [(258.0, 6.0), (264.0, 9.0), (200.0, 8.0), (196.0, 5.0)]) {
        c.drawCircle(Offset(x, g + y), 3, dirt);
      }
    } else {
      for (final x in [170.0, 230.0, 290.0]) {
        c.drawOval(Rect.fromCenter(center: Offset(x, g - 1), width: 22, height: 7), Paint()..color = const Color(0xFF7F7F78));
      }
    }
  }

  // --- open -----------------------------------------------------------------
  void _open(Canvas c) {
    final p = geo.pillar;
    final i = geo.inner;
    c.drawRect(geo.plinth, Paint()..color = const Color(0xFF9C9A92));
    c.drawRect(p, Paint()..color = const Color(0xFF7C878E));
    c.drawRect(i, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3D474F), Color(0xFF2A3239)]).createShader(i));
    // The door swung open on its right hinge.
    c.drawPath(
        Path()
          ..moveTo(p.right, p.top + 6)
          ..lineTo(p.right + 22, p.top + 22)
          ..lineTo(p.right + 22, p.bottom - 2)
          ..lineTo(p.right, p.bottom - 10)
          ..close(),
        Paint()..color = const Color(0xFF8E9AA1));
    _roof(c);
    _busbars(c);
    for (var k = 0; k < 3; k++) {
      _sfu(c, k);
    }
    _neutralEarth(c);
    _glands(c);
    if (_has(M3PillarInspectFault.waterIn)) _water(c);
  }

  void _busbars(Canvas c) {
    final i = geo.inner;
    const cols = [Color(0xFFD83A2E), Color(0xFFE8C21E), Color(0xFF2F6FD0), Color(0xFF15191D)];
    const names = ['R', 'Y', 'B', 'N'];
    // The incomer up the left wall.
    c.drawRect(Rect.fromLTWH(i.left + 2, geo.busY.first - 4, 8, i.bottom - geo.busY.first), Paint()..color = const Color(0xFF111418));
    for (var b = 0; b < 4; b++) {
      final y = geo.busY[b];
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(i.left + 14, y - 4, i.width - 24, 8), const Radius.circular(2)),
          Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.lerp(cols[b], Colors.white, 0.25)!, cols[b]]).createShader(Rect.fromLTWH(0, y - 4, 10, 8)));
      _text(c, names[b], Offset(i.left + 20, y), 7, b == 1 ? const Color(0xFF2B2416) : Colors.white);
    }
    if (faults[M3PillarInspectSpot.busbar] == M3PillarInspectFault.hotspot) {
      _hot(c, Offset(i.left + 120, geo.busY[1]));
    }
  }

  void _sfu(Canvas c, int k) {
    final u = geo.unit(k);
    final off = switchedOff.contains(k);
    // Droppers from the busbars to the unit.
    final drop = Paint()
      ..color = const Color(0xFFB87333)
      ..strokeWidth = 3;
    for (var f = 0; f < 3; f++) {
      final x = u.left + 10 + f * 14;
      c.drawLine(Offset(x, geo.busY[f]), Offset(x, u.top), drop);
    }
    c.drawRRect(RRect.fromRectAndRadius(u, const Radius.circular(4)), Paint()..color = const Color(0xFF5E6B73));
    c.drawRRect(RRect.fromRectAndRadius(u, const Radius.circular(4)), Paint()
      ..color = const Color(0xFF20272D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4);
    // The handle: up = ON, down = OFF.
    final h = geo.handle(k);
    _text(c, '${k + 1}', Offset(h.left + 8, h.top + 8), 9, Colors.white);
    final pivot = Offset(h.center.dx + 4, h.center.dy + 2);
    final tip = pivot + (off ? const Offset(10, 10) : const Offset(10, -10));
    c.drawLine(pivot, tip, Paint()
      ..color = off ? const Color(0xFF1FBF8F) : const Color(0xFFD83A2E)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round);
    c.drawCircle(pivot, 4, Paint()..color = const Color(0xFF20272D));
    _text(c, off ? 'OFF' : 'ON', Offset(h.left + 13, h.bottom - 6), 7, off ? const Color(0xFF9CF5D2) : const Color(0xFFFFC2BC));
    // The three HRC fuses (or empty bases once pulled).
    final fs = geo.fuses(k);
    final wired = faults[m3PillarInspectFuseSpot(k)] == M3PillarInspectFault.wireFuse;
    for (var f = 0; f < 3; f++) {
      final r = Rect.fromLTWH(fs.left + 4 + f * 14, fs.top + 4, 12, fs.height - 10);
      c.drawRect(Rect.fromLTWH(r.left + 3, r.top - 2, 6, 4), Paint()..color = const Color(0xFFB87333));
      c.drawRect(Rect.fromLTWH(r.left + 3, r.bottom - 2, 6, 4), Paint()..color = const Color(0xFFB87333));
      if (fusesOut.contains(k)) {
        c.drawRect(r.deflate(3), Paint()..color = const Color(0xFF20272D));
        continue;
      }
      if (wired && f == 1) {
        // A thick bare copper wire across the fuse base (myth 2).
        final wire = Path()
          ..moveTo(r.center.dx, r.top)
          ..cubicTo(r.left - 4, r.top + 14, r.right + 4, r.bottom - 14, r.center.dx, r.bottom);
        c.drawPath(wire, Paint()
          ..color = const Color(0xFFCF7A3A)
          ..strokeWidth = 3.4
          ..style = PaintingStyle.stroke);
        continue;
      }
      c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), Paint()..color = const Color(0xFFEDE6D6));
      c.drawRect(Rect.fromLTWH(r.left, r.top, r.width, 4), Paint()..color = const Color(0xFFB8BEC4));
      c.drawRect(Rect.fromLTWH(r.left, r.bottom - 4, r.width, 4), Paint()..color = const Color(0xFFB8BEC4));
    }
    if (faults[m3PillarInspectFuseSpot(k)] == M3PillarInspectFault.hotspot) _hot(c, Offset(fs.left + 24, fs.bottom - 4));
    // The outgoing cable down to its gland (with a lug at the top).
    final cx = u.center.dx;
    final cable = Paint()..color = const Color(0xFF111418);
    c.drawRect(Rect.fromLTWH(cx - 5, u.bottom, 10, geo.glands.top - u.bottom + 6), cable);
    c.drawRect(Rect.fromLTWH(cx - 7, geo.cableLug(k).dy - 4, 14, 8), Paint()..color = const Color(0xFFB87333));
  }

  void _neutralEarth(Canvas c) {
    final n = geo.neutral;
    c.drawRect(Rect.fromLTWH(n.left + 10, n.top, 14, n.height), Paint()..color = const Color(0xFFB87333));
    for (var j = 0; j < 4; j++) {
      c.drawCircle(Offset(n.left + 17, n.top + 12 + j * 22), 3, Paint()..color = const Color(0xFF6B4320));
      c.drawLine(Offset(n.left + 17, n.top + 12 + j * 22), Offset(n.left + 2, n.top + 18 + j * 22), Paint()
        ..color = const Color(0xFF15191D)
        ..strokeWidth = 3);
    }
    _text(c, 'N', Offset(n.left + 30, n.top + 6), 8, Colors.white);
    final e = geo.earth;
    c.drawRect(Rect.fromLTWH(e.left + 6, e.top + 14, 24, 10), Paint()..color = const Color(0xFFB87333));
    final gy = Paint()
      ..shader = const LinearGradient(colors: [Color(0xFF2F9E44), Color(0xFFE8C21E), Color(0xFF2F9E44), Color(0xFFE8C21E)], stops: [0, 0.33, 0.66, 1]).createShader(Rect.fromLTWH(e.left, e.top, 12, 12))
      ..strokeWidth = 4;
    c.drawLine(Offset(e.left + 18, e.top + 24), Offset(e.left + 18, e.bottom + 6), gy);
    // The earth symbol.
    final s = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.5;
    final o = Offset(e.left + 18, e.top + 4);
    c.drawLine(o + const Offset(-7, 0), o + const Offset(7, 0), s);
    c.drawLine(o + const Offset(-4, 3), o + const Offset(4, 3), s);
    c.drawLine(o + const Offset(-1.5, 6), o + const Offset(1.5, 6), s);
  }

  void _glands(Canvas c) {
    final gl = geo.glands;
    c.drawRect(gl, Paint()..color = const Color(0xFF20272D));
    for (var k = 0; k < 3; k++) {
      final x = geo.unit(k).center.dx;
      c.drawOval(Rect.fromCenter(center: Offset(x, gl.top + 10), width: 22, height: 8), Paint()..color = const Color(0xFF6F7C84));
    }
    if (_has(M3PillarInspectFault.ratBite)) {
      // Gnawed insulation on cable 2 (copper showing) and droppings.
      final x = geo.unit(1).center.dx;
      final bite = Rect.fromLTWH(x - 6, gl.top - 14, 12, 12);
      c.drawRect(bite, Paint()..color = const Color(0xFF2A3239));
      c.drawRect(Rect.fromLTWH(x - 2, bite.top, 4, bite.height), Paint()..color = const Color(0xFFCF7A3A));
      final chew = Paint()
        ..color = const Color(0xFF111418)
        ..strokeWidth = 1.6;
      for (var j = 0; j < 4; j++) {
        c.drawLine(Offset(bite.left, bite.top + j * 3), Offset(bite.left - 3, bite.top + j * 3 + 2), chew);
        c.drawLine(Offset(bite.right, bite.top + j * 3), Offset(bite.right + 3, bite.top + j * 3 + 2), chew);
      }
      final drop = Paint()..color = const Color(0xFF4A3524);
      for (final (dx, dy) in [(-30.0, 22.0), (-24.0, 26.0), (26.0, 24.0), (34.0, 28.0), (40.0, 22.0)]) {
        c.drawOval(Rect.fromCenter(center: Offset(x + dx, gl.top + dy), width: 6, height: 3), drop);
      }
      // A gap in the gland seal.
      c.drawOval(Rect.fromCenter(center: Offset(x + 16, gl.top + 10), width: 12, height: 6), Paint()..color = const Color(0xFF0B0D10));
    }
  }

  void _water(Canvas c) {
    final i = geo.inner;
    // Drips from the top seal, a wet streak and rust down the back wall.
    final wet = Paint()..color = const Color(0x884A90C8);
    for (final x in [i.left + 60, i.left + 140]) {
      c.drawRect(Rect.fromLTWH(x - 5, i.top, 10, 26), wet);
      c.drawRect(Rect.fromLTWH(x - 3, i.top + 26, 6, 14), Paint()..color = const Color(0x889A4A1C));
      c.drawCircle(Offset(x, i.top + 18), 3.5, Paint()..color = const Color(0xFFBFE3FF));
      c.drawPath(
          Path()
            ..moveTo(x, i.top + 6)
            ..quadraticBezierTo(x + 5, i.top + 14, x, i.top + 16)
            ..quadraticBezierTo(x - 5, i.top + 14, x, i.top + 6),
          Paint()..color = const Color(0xFFBFE3FF));
    }
  }

  /// A hotspot: a burnt black mark at a connection, a brown halo and a wisp
  /// of smoke (the burnt smell).
  void _hot(Canvas c, Offset at) {
    c.drawCircle(at, 11, Paint()..color = const Color(0x88613012));
    c.drawCircle(at, 6.5, Paint()..color = const Color(0xFF0B0B0B));
    final smoke = Paint()
      ..color = const Color(0xAACFCFCF)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final dx in [-4.0, 4.0]) {
      c.drawPath(
          Path()
            ..moveTo(at.dx + dx, at.dy - 8)
            ..quadraticBezierTo(at.dx + dx + 6, at.dy - 14, at.dx + dx, at.dy - 20)
            ..quadraticBezierTo(at.dx + dx - 6, at.dy - 26, at.dx + dx + 2, at.dy - 32),
          smoke);
    }
  }

  // --- the trainee's marks ----------------------------------------------------
  void _rings(Canvas c) {
    for (final s in flagged) {
      final at = geo.spotMark(s);
      c.drawCircle(at, 17, Paint()
        ..color = const Color(0xFFE23B2E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3);
      final tag = Offset(at.dx + 15, at.dy - 15);
      c.drawCircle(tag, 8, Paint()..color = const Color(0xFFE23B2E));
      _text(c, '!', tag, 11, Colors.white);
    }
    for (final s in missed) {
      final at = geo.spotMark(s);
      final ring = Paint()
        ..color = const Color(0xFFFF9F1C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      for (var a = 0; a < 12; a++) {
        c.drawArc(Rect.fromCircle(center: at, radius: 20), a * math.pi / 6, math.pi / 10, false, ring);
      }
    }
  }

  void _text(Canvas c, String t, Offset centre, double size, Color col) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: TextStyle(fontSize: size, fontWeight: FontWeight.w900, color: col)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(M3PillarInspectPainter old) =>
      old.geo != geo ||
      old.view != view ||
      !mapEquals(old.faults, faults) ||
      !setEquals(old.flagged, flagged) ||
      !setEquals(old.missed, missed) ||
      !setEquals(old.switchedOff, switchedOff) ||
      !setEquals(old.fusesOut, fusesOut) ||
      old.meggerOn != meggerOn ||
      old.glovesOn != glovesOn ||
      old.lockedNew != lockedNew ||
      old.lockMissing != lockMissing;
}

/// The gloves on his hands (red rubber), drawn over the figure.
class M3PillarInspectGlovesPainter extends CustomPainter {
  const M3PillarInspectGlovesPainter({required this.hands});
  final List<Offset> hands;

  @override
  void paint(Canvas c, Size size) {
    for (final h in hands) {
      c.drawCircle(h, 7, Paint()..color = const Color(0xFFD9402F));
      c.drawCircle(h, 7, Paint()
        ..color = const Color(0xFF7A1E14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2);
    }
  }

  @override
  bool shouldRepaint(M3PillarInspectGlovesPainter old) => !listEquals(old.hands, hands);
}

/// The flash at a live cable when the megger's leads go on it (the deadly
/// consequence, in colour over the grey scene). Non-graphic.
class M3PillarInspectZapPainter extends CustomPainter {
  const M3PillarInspectZapPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final flick = v < 0.5 ? (0.65 + 0.35 * math.sin(v * 60).abs()) : (1 - (v - 0.5) * 1.2).clamp(0.4, 1.0);
    final r = 26 + 46 * Curves.easeOut.transform(v.clamp(0.0, 1.0));
    c.drawCircle(at, r, Paint()..shader = RadialGradient(colors: [Color.fromRGBO(220, 235, 255, 0.95 * flick), const Color(0x002F6FD0)]).createShader(Rect.fromCircle(center: at, radius: r)));
    final spark = Paint()
      ..color = Color.fromRGBO(255, 214, 90, (1 - v).clamp(0.0, 1.0))
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 14; i++) {
      final a = i / 14 * math.pi * 2 + 0.3;
      final d0 = 10 + 38 * v;
      c.drawLine(at + Offset(math.cos(a) * d0, math.sin(a) * d0), at + Offset(math.cos(a) * (d0 + 12), math.sin(a) * (d0 + 12)), spark);
    }
    final white = (1 - v * 4).clamp(0.0, 1.0);
    if (white > 0) c.drawRect(Offset.zero & size, Paint()..color = Color.fromRGBO(255, 255, 255, 0.8 * white));
  }

  @override
  bool shouldRepaint(M3PillarInspectZapPainter old) => old.v != v || old.at != at;
}
