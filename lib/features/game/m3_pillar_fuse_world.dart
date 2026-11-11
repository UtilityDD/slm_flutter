import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The drawn world of lesson 3.7 কাজ 1 "ফিউজ বদলাও ঠিকঠাক" (m3_pillar_fuse.dart):
// a street corner at dusk — the green steel LT feeder pillar on its concrete
// plinth (its door with the DANGER 415 V plate, the handle and the hasp), and
// inside: the R · Y · B busbars and the neutral bar along the top, three
// outgoing feeders F1 · F2 · F3 as rows of HRC fuse carriers on the phase
// risers, each feeder's cable lugs on the right, the cables down the gutter to
// the glands, the earth terminal. Behind: the pole transformer and the houses
// of the dead feeder (dark until its fuse is back). Code-drawn, gradients, no
// bitmaps. Design space 360 wide; the street sits [M3PillarFuseGeo.floorUp]
// above the bottom so the controls sit on it.

/// Why the fuse blew (lesson 3.7 point 3: hotspot, water, rodents).
enum M3PillarFuseCause { hotspot, water, rodent }

/// Where things are in the scene (design px, 360 wide).
@immutable
class M3PillarFuseGeo {
  const M3PillarFuseGeo._(this.height, this.groundY);

  factory M3PillarFuseGeo.forScene(double height, double inset) => M3PillarFuseGeo._(height, height - floorUp - inset * 0.5);

  final double height;

  /// The street line.
  final double groundY;

  static const double floorUp = 104;

  /// The pillar's top (the roof lip).
  double get top => groundY - 420;

  /// The steel body (and the closed door over it).
  Rect get body => Rect.fromLTRB(20, top, 250, top + 250);
  Rect get plinth => Rect.fromLTRB(12, body.bottom, 258, groundY);

  /// The open door, swung out to the right.
  Rect get openDoor => Rect.fromLTRB(250, top + 6, 290, top + 246);
  Rect get openDoorHit => Rect.fromLTRB(248, top, 300, top + 252);

  /// The phase risers (R, Y, B) and the feeder rows (F1, F2, F3).
  static const List<double> phaseX = [74, 122, 170];
  static const List<double> feederDy = [86, 132, 178];

  Offset fuse(int feeder, int phase) => Offset(phaseX[phase], top + feederDy[feeder]);
  Rect fuseHit(int feeder, int phase) => Rect.fromCenter(center: fuse(feeder, phase), width: 46, height: 44);

  /// A feeder's outgoing cable lugs (right of its fuses).
  Rect lugs(int feeder) => Rect.fromCenter(center: Offset(212, top + feederDy[feeder]), width: 32, height: 30);

  /// The water's way in: the broken roof seal, and the puddle on the floor.
  Offset get leak => Offset(140, top + 10);
  Rect get puddle => Rect.fromCenter(center: Offset(140, top + 232), width: 84, height: 16);

  /// The cable glands at the bottom right (where a rat gets in).
  Offset get gland => Offset(226, top + 234);

  /// Where a tap counts as spotting the cause.
  List<Rect> causeHits(M3PillarFuseCause c, int feeder) => switch (c) {
        M3PillarFuseCause.hotspot => [lugs(feeder).inflate(8)],
        M3PillarFuseCause.water => [Rect.fromCenter(center: leak + const Offset(0, 6), width: 76, height: 30), puddle.inflate(8)],
        M3PillarFuseCause.rodent => [Rect.fromCenter(center: gland + const Offset(-6, -6), width: 60, height: 38)],
      };

  /// The centre of the cause (for its ring and the flash).
  Offset causeAt(M3PillarFuseCause c, int feeder) => switch (c) {
        M3PillarFuseCause.hotspot => lugs(feeder).center,
        M3PillarFuseCause.water => leak + const Offset(0, 8),
        M3PillarFuseCause.rodent => gland + const Offset(-6, -6),
      };

  /// Where the lineman stands: by the houses, clear of the guide's corner.
  Rect get trainee => Rect.fromLTWH(286, groundY - 140, 70, 140);

  @override
  bool operator ==(Object other) => other is M3PillarFuseGeo && other.height == height && other.groundY == groundY;

  @override
  int get hashCode => Object.hash(height, groundY);
}

/// The phase colours (R, Y, B).
const m3PillarFusePhaseColors = [Color(0xFFD63A2F), Color(0xFFF2C230), Color(0xFF2F6FD6)];

/// What the pillar shows now.
@immutable
class M3PillarFuseBox {
  const M3PillarFuseBox({
    required this.doorOpen,
    required this.locked,
    required this.feeder,
    required this.phase,
    required this.slotEmpty,
    required this.fitted,
    required this.cause,
    required this.causeShown,
    required this.spotted,
  });

  final bool doorOpen;
  final bool locked;

  /// The dead feeder and the phase whose fuse blew.
  final int feeder;
  final int phase;

  /// The blown fuse is out; [fitted] = a new HRC fuse is in.
  final bool slotEmpty;
  final bool fitted;

  final M3PillarFuseCause cause;

  /// The cause is still there to see (false once it is put right).
  final bool causeShown;

  /// The cause was spotted (a ring round it).
  final bool spotted;

  bool get lightsOn => fitted;

  @override
  bool operator ==(Object other) =>
      other is M3PillarFuseBox &&
      other.doorOpen == doorOpen &&
      other.locked == locked &&
      other.feeder == feeder &&
      other.phase == phase &&
      other.slotEmpty == slotEmpty &&
      other.fitted == fitted &&
      other.cause == cause &&
      other.causeShown == causeShown &&
      other.spotted == spotted;

  @override
  int get hashCode => Object.hash(doorOpen, locked, feeder, phase, slotEmpty, fitted, cause, causeShown, spotted);
}

/// The street and the pillar. [t] (seconds) drips the water and curls the
/// smoke while awake.
class M3PillarFuseWorldPainter extends CustomPainter {
  M3PillarFuseWorldPainter({required this.geo, required this.box, required this.t, required this.seed}) : super(repaint: t);

  final M3PillarFuseGeo geo;
  final M3PillarFuseBox box;
  final ValueListenable<double> t;
  final int seed;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    // Dusk sky.
    c.drawRect(
        Rect.fromLTWH(0, 0, w, g.groundY),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF243A63), Color(0xFF6B6A8E), Color(0xFFE59A6A)],
            stops: [0, 0.6, 1],
          ).createShader(Rect.fromLTWH(0, 0, w, g.groundY)));
    // Far rooftops (parallax layer).
    final far = Paint()..color = const Color(0xFF3B3F5C);
    final rnd = math.Random(seed);
    final skyline = g.groundY - 150;
    for (var x = -8.0; x < w + 10; x += 34 + rnd.nextDouble() * 20) {
      final h = 30 + rnd.nextDouble() * 50;
      c.drawRect(Rect.fromLTWH(x, skyline - h, 30 + rnd.nextDouble() * 10, h + 150), far);
    }
    _pole(c);
    _houses(c, w);
    // The street and the footpath.
    final street = Rect.fromLTRB(0, g.groundY, w, size.height);
    c.drawRect(street, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF6D6A66), Color(0xFF45433F)]).createShader(street));
    c.drawLine(Offset(0, g.groundY), Offset(w, g.groundY), Paint()
      ..color = const Color(0xFF8E8A82)
      ..strokeWidth = 3);
    _pillar(c);
  }

  void _pole(Canvas c) {
    final g = geo;
    // The pole transformer at the corner (behind the houses).
    final px = 322.0;
    final top = g.top - 70;
    final pole = Paint()..color = const Color(0xFF7D7A73);
    c.drawRect(Rect.fromLTRB(px - 4, top, px + 4, g.groundY), pole);
    c.drawRect(Rect.fromLTRB(px - 30, top + 8, px + 30, top + 13), Paint()..color = const Color(0xFF5B5852));
    for (final dx in [-24.0, 0.0, 24.0]) {
      c.drawCircle(Offset(px + dx, top + 5), 3.2, Paint()..color = const Color(0xFFCFC9B8));
    }
    final tank = Rect.fromLTWH(px - 20, top + 44, 40, 46);
    c.drawRRect(RRect.fromRectAndRadius(tank, const Radius.circular(4)), Paint()..shader = const LinearGradient(colors: [Color(0xFF6E7E86), Color(0xFF9EB0B8), Color(0xFF5E6E76)]).createShader(tank));
    for (var y = tank.top + 6; y < tank.bottom - 3; y += 6) {
      c.drawLine(Offset(tank.left + 3, y), Offset(tank.right - 3, y), Paint()
        ..color = const Color(0x44000000)
        ..strokeWidth = 1);
    }
    // The LT cable down the pole to the pillar (under the street).
    c.drawLine(Offset(px - 6, tank.bottom), Offset(px - 6, g.groundY), Paint()
      ..color = const Color(0xFF1E1E1E)
      ..strokeWidth = 4);
  }

  void _houses(Canvas c, double w) {
    final g = geo;
    final lit = box.lightsOn;
    final rnd = math.Random(seed + 7);
    for (final (i, x) in [262.0, 308.0].indexed) {
      final h = 108 + rnd.nextDouble() * 24 + i * 6;
      final r = Rect.fromLTWH(x, g.groundY - h, 48, h);
      c.drawRect(r, Paint()..color = i.isEven ? const Color(0xFFB79C7E) : const Color(0xFF9E8A74));
      c.drawRect(Rect.fromLTWH(x - 3, r.top - 6, 54, 7), Paint()..color = const Color(0xFF6E5E4E));
      for (var row = 0; row < 2; row++) {
        for (var col = 0; col < 2; col++) {
          final win = Rect.fromLTWH(x + 7 + col * 21, r.top + 14 + row * 34, 13, 17);
          if (lit) {
            c.drawRect(win.inflate(4), Paint()..color = const Color(0x55FFD27A));
          }
          c.drawRect(win, Paint()..color = lit ? const Color(0xFFFFD98A) : const Color(0xFF2A2C38));
        }
      }
    }
  }

  void _pillar(Canvas c) {
    final g = geo;
    final b = box;
    // Plinth.
    c.drawRect(g.plinth, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFBDB6A6), Color(0xFF8F887A)]).createShader(g.plinth));
    c.drawRect(Rect.fromLTRB(g.plinth.left, g.plinth.top, g.plinth.right, g.plinth.top + 4), Paint()..color = const Color(0xFFD9D2C1));
    // The base's lower tier and its step.
    final tier = Rect.fromLTRB(g.plinth.left - 8, g.groundY - 60, g.plinth.right + 8, g.groundY);
    c.drawRect(tier, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFA9A291), Color(0xFF7D7668)]).createShader(tier));
    c.drawRect(Rect.fromLTRB(tier.left, tier.top, tier.right, tier.top + 4), Paint()..color = const Color(0xFFCBC4B2));
    // The cable trench cover on the base's face.
    c.drawRect(Rect.fromLTWH(g.plinth.left + 30, g.plinth.top + 30, g.plinth.width - 60, 40), Paint()..color = const Color(0x22000000));
    // Shadow, then the body.
    final body = RRect.fromRectAndRadius(g.body, const Radius.circular(4));
    c.drawRRect(body.shift(const Offset(4, 5)), Paint()..color = const Color(0x55000000));
    // The roof lip.
    c.drawRect(Rect.fromLTRB(g.body.left - 6, g.top - 8, g.body.right + 6, g.top + 2), Paint()..color = const Color(0xFF2F5A3C));
    if (b.doorOpen) {
      _inside(c);
      _openDoor(c);
    } else {
      _closedDoor(c);
    }
  }

  void _closedDoor(Canvas c) {
    final g = geo;
    final r = g.body;
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)), Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF4F8A5E), Color(0xFF2E5E3C)]).createShader(r));
    c.drawRRect(
        RRect.fromRectAndRadius(r.deflate(6), const Radius.circular(3)),
        Paint()
          ..color = const Color(0x33000000)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    // Louvres at the foot.
    for (var i = 0; i < 4; i++) {
      final y = r.bottom - 46 + i * 9.0;
      c.drawLine(Offset(r.left + 30, y), Offset(r.left + 110, y), Paint()
        ..color = const Color(0x55102018)
        ..strokeWidth = 3);
    }
    // The danger plate.
    final plate = Rect.fromLTWH(r.left + 48, r.top + 40, 120, 74);
    c.drawRRect(RRect.fromRectAndRadius(plate, const Radius.circular(4)), Paint()..color = const Color(0xFFF4F1E8));
    c.drawRRect(
        RRect.fromRectAndRadius(plate, const Radius.circular(4)),
        Paint()
          ..color = const Color(0xFFC62828)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    // A lightning flash on the plate.
    final bolt = Path()
      ..moveTo(plate.left + 26, plate.top + 10)
      ..lineTo(plate.left + 16, plate.top + 36)
      ..lineTo(plate.left + 26, plate.top + 36)
      ..lineTo(plate.left + 18, plate.top + 62)
      ..lineTo(plate.left + 36, plate.top + 30)
      ..lineTo(plate.left + 26, plate.top + 30)
      ..close();
    c.drawPath(bolt, Paint()..color = const Color(0xFFC62828));
    _label(c, 'DANGER', Offset(plate.left + 76, plate.top + 22), 14, const Color(0xFFC62828));
    _label(c, '415 V', Offset(plate.left + 76, plate.top + 48), 16, const Color(0xFF1E1E1E));
    // The handle and the hasp (and the padlock when locked).
    final h = Offset(r.right - 18, r.top + 128);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: h, width: 10, height: 44), const Radius.circular(4)), Paint()..color = const Color(0xFF1E2226));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: h + const Offset(0, 36), width: 16, height: 10), const Radius.circular(2)), Paint()..color = const Color(0xFF9AA1A7));
    if (box.locked) {
      final at = h + const Offset(0, 52);
      c.drawArc(Rect.fromCenter(center: at + const Offset(0, -5), width: 13, height: 16), math.pi, math.pi, false, Paint()
        ..color = const Color(0xFFB0B6BB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: at + const Offset(0, 6), width: 18, height: 15), const Radius.circular(3)), Paint()..color = const Color(0xFFD9A441));
      c.drawCircle(at + const Offset(0, 6), 2, Paint()..color = const Color(0xFF5A4410));
    }
  }

  void _openDoor(Canvas c) {
    final g = geo;
    final d = g.openDoor;
    final path = Path()
      ..moveTo(d.left, d.top)
      ..lineTo(d.right, d.top + 16)
      ..lineTo(d.right, d.bottom - 16)
      ..lineTo(d.left, d.bottom)
      ..close();
    c.drawPath(path, Paint()..shader = const LinearGradient(colors: [Color(0xFF2B4F35), Color(0xFF6E9C78)]).createShader(d));
    c.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF1E3826)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6);
    // Its inner face: the seal strip and the handle's back.
    c.drawLine(Offset(d.left + 5, d.top + 8), Offset(d.left + 5, d.bottom - 8), Paint()
      ..color = const Color(0xFF1A1A1A)
      ..strokeWidth = 3);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(d.right - 10, d.center.dy), width: 7, height: 30), const Radius.circular(3)), Paint()..color = const Color(0xFF1E2226));
  }

  void _inside(Canvas c) {
    final g = geo;
    final b = box;
    final time = t.value;
    final r = g.body;
    // The steel shell and the dark back plate.
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)), Paint()..color = const Color(0xFF2E5E3C));
    final back = r.deflate(8);
    c.drawRect(back, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3A4046), Color(0xFF23272B)]).createShader(back));
    // The busbars R · Y · B and the neutral bar along the top.
    for (var p = 0; p < 3; p++) {
      final y = g.top + 26 + p * 10.0;
      c.drawRect(Rect.fromLTRB(back.left + 14, y - 3, back.right - 8, y + 3), Paint()..color = m3PillarFusePhaseColors[p]);
      _label(c, const ['R', 'Y', 'B'][p], Offset(back.left + 7, y), 8, m3PillarFusePhaseColors[p]);
    }
    final ny = g.top + 58;
    c.drawRect(Rect.fromLTRB(back.left + 14, ny - 3, back.right - 8, ny + 3), Paint()..color = const Color(0xFF111111));
    _label(c, 'N', Offset(back.left + 7, ny), 8, const Color(0xFFDDDDDD));
    // The incomer from the transformer at the top right.
    c.drawLine(Offset(back.right - 14, g.top + 20), Offset(back.right - 14, g.top + 8), Paint()
      ..color = const Color(0xFF1E1E1E)
      ..strokeWidth = 7);
    // The phase risers down behind the fuses.
    for (var p = 0; p < 3; p++) {
      final x = M3PillarFuseGeo.phaseX[p];
      c.drawRect(Rect.fromLTRB(x - 3, g.top + 26 + p * 10.0, x + 3, g.top + 196), Paint()..color = m3PillarFusePhaseColors[p].withValues(alpha: 0.85));
    }
    // The three feeders.
    for (var f = 0; f < 3; f++) {
      final y = g.top + M3PillarFuseGeo.feederDy[f];
      // The feeder's tag at the left.
      final tag = Rect.fromCenter(center: Offset(back.left + 13, y), width: 20, height: 14);
      c.drawRRect(RRect.fromRectAndRadius(tag, const Radius.circular(2)), Paint()..color = const Color(0xFFF4F1E8));
      _label(c, 'F${f + 1}', tag.center, 8, const Color(0xFF1E1E1E));
      // The base rail.
      c.drawRect(Rect.fromLTRB(52, y - 18, 192, y + 18), Paint()..color = const Color(0x22000000));
      for (var p = 0; p < 3; p++) {
        _fuse(c, g.fuse(f, p), empty: f == b.feeder && p == b.phase && b.slotEmpty && !b.fitted, fresh: f == b.feeder && p == b.phase && b.fitted);
        // The lead from the fuse to the feeder's lugs.
        final from = g.fuse(f, p) + const Offset(10, 12);
        final to = Offset(g.lugs(f).left + 4 + p * 8.0, g.lugs(f).center.dy + 6);
        c.drawLine(from, to, Paint()
          ..color = const Color(0xFF151515)
          ..strokeWidth = 2.2);
      }
      // The lugs block and the cable down the gutter.
      final l = g.lugs(f);
      c.drawRRect(RRect.fromRectAndRadius(l, const Radius.circular(3)), Paint()..color = const Color(0xFF6B6F73));
      for (var k = 0; k < 4; k++) {
        c.drawCircle(Offset(l.left + 5 + k * 7.3, l.center.dy), 2.6, Paint()..color = k == 3 ? const Color(0xFF111111) : const Color(0xFFC79A55));
      }
      final cx = 232.0 + f * 4;
      c.drawPath(
          Path()
            ..moveTo(l.right, l.center.dy)
            ..quadraticBezierTo(cx, l.center.dy, cx, l.center.dy + 14)
            ..lineTo(cx, g.top + 240),
          Paint()
            ..color = const Color(0xFF151515)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4.5);
    }
    // The glands at the floor, and the earth terminal.
    c.drawRect(Rect.fromLTRB(back.left, g.top + 236, back.right, back.bottom), Paint()..color = const Color(0xFF555A5E));
    for (var f = 0; f < 3; f++) {
      c.drawRect(Rect.fromCenter(center: Offset(232.0 + f * 4, g.top + 237), width: 6, height: 6), Paint()..color = const Color(0xFF9AA1A7));
    }
    final e = Offset(back.left + 14, g.top + 226);
    c.drawCircle(e, 7, Paint()..color = const Color(0xFF2E7D32));
    _label(c, 'E', e, 8, Colors.white);
    // The cause.
    if (b.causeShown) _cause(c, time);
    if (b.spotted) {
      for (final h in g.causeHits(b.cause, b.feeder).take(1)) {
        c.drawOval(h.inflate(2), Paint()
          ..color = const Color(0xFF7CF08A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.6);
      }
    }
  }

  void _fuse(Canvas c, Offset at, {required bool empty, required bool fresh}) {
    // The carrier's base (black) with its two silver contact clips.
    final base = Rect.fromCenter(center: at, width: 34, height: 34);
    c.drawRRect(RRect.fromRectAndRadius(base, const Radius.circular(3)), Paint()..color = const Color(0xFF18191B));
    final clip = Paint()..color = const Color(0xFFB8C0C6);
    c.drawRect(Rect.fromCenter(center: at + const Offset(0, -13), width: 14, height: 5), clip);
    c.drawRect(Rect.fromCenter(center: at + const Offset(0, 13), width: 14, height: 5), clip);
    if (empty) return;
    // The cartridge: a ceramic body with metal end caps.
    final body = Rect.fromCenter(center: at, width: 16, height: 22);
    c.drawRRect(
        RRect.fromRectAndRadius(body, const Radius.circular(3)),
        Paint()
          ..shader = LinearGradient(colors: fresh ? const [Color(0xFFFFFDF2), Color(0xFFE9E1C6)] : const [Color(0xFFEDE6D2), Color(0xFFC9BF9F)]).createShader(body));
    final cap = Paint()..color = const Color(0xFFCFD5DA);
    c.drawRect(Rect.fromLTWH(body.left - 1, body.top - 3, body.width + 2, 5), cap);
    c.drawRect(Rect.fromLTWH(body.left - 1, body.bottom - 2, body.width + 2, 5), cap);
    // The red handle tab of the carrier.
    c.drawRect(Rect.fromCenter(center: at + const Offset(12, 0), width: 5, height: 14), Paint()..color = const Color(0xFFB0261C));
  }

  void _cause(Canvas c, double time) {
    final g = geo;
    final b = box;
    switch (b.cause) {
      case M3PillarFuseCause.hotspot:
        // Black scorch and a wisp of smoke on the loose lug.
        final l = g.lugs(b.feeder);
        c.drawOval(l.inflate(5), Paint()..shader = RadialGradient(colors: const [Color(0xEE0A0A0A), Color(0x99201008), Color(0x00201008)]).createShader(l.inflate(5)));
        c.drawCircle(l.center + const Offset(-4, 0), 3, Paint()..color = const Color(0xFFFF7A2E));
        final rise = (time * 14) % 30;
        for (var k = 0; k < 3; k++) {
          final y = l.top - 4 - ((rise + k * 10) % 30);
          c.drawCircle(Offset(l.center.dx + math.sin((y + k) / 6) * 4, y), 4.5 - k * 0.8, Paint()..color = const Color(0x66C8C8C8));
        }
      case M3PillarFuseCause.water:
        // The broken roof seal, drips down the back, rust, the puddle.
        final at = g.leak;
        c.drawRect(Rect.fromCenter(center: at + const Offset(0, -6), width: 30, height: 4), Paint()..color = const Color(0xFF8A4B24));
        final stream = Paint()
          ..color = const Color(0x886FB6E8)
          ..strokeWidth = 3;
        c.drawLine(at, Offset(at.dx + 2, g.puddle.top), stream);
        for (var k = 0; k < 3; k++) {
          final y = at.dy + ((time * 70 + k * 80) % (g.puddle.top - at.dy));
          c.drawOval(Rect.fromCenter(center: Offset(at.dx + 1, y), width: 5, height: 8), Paint()..color = const Color(0xDD9BD3FF));
        }
        c.drawOval(g.puddle, Paint()..color = const Color(0xAA4F8FC7));
        c.drawOval(g.puddle.deflate(5), Paint()..color = const Color(0x55BFE3FF));
        c.drawCircle(at + const Offset(-22, 26), 6, Paint()..color = const Color(0x888A4B24));
      case M3PillarFuseCause.rodent:
        // The chewed cable sheath at the gland, copper showing, and the rat.
        final at = g.gland + const Offset(0, -12);
        c.drawRect(Rect.fromCenter(center: at, width: 9, height: 12), Paint()..color = const Color(0xFFC77A3A));
        for (var k = 0; k < 4; k++) {
          c.drawCircle(at + Offset(-5 + k * 3.4, -7), 1.6, Paint()..color = const Color(0xFF151515));
        }
        final rat = g.gland + const Offset(-26, -2);
        final wiggle = math.sin(time * 6) * 1.5;
        c.drawOval(Rect.fromCenter(center: rat, width: 26, height: 13), Paint()..color = const Color(0xFF6D6259));
        c.drawCircle(rat + Offset(12, -2 + wiggle), 6, Paint()..color = const Color(0xFF6D6259));
        c.drawCircle(rat + Offset(10, -8 + wiggle), 3, Paint()..color = const Color(0xFFC9A49A));
        c.drawCircle(rat + Offset(15, -3 + wiggle), 1.3, Paint()..color = Colors.black);
        c.drawPath(
            Path()
              ..moveTo(rat.dx - 12, rat.dy)
              ..quadraticBezierTo(rat.dx - 24, rat.dy - 10 + wiggle, rat.dx - 30, rat.dy + 2),
            Paint()
              ..color = const Color(0xFFC9A49A)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.6);
    }
  }

  void _label(Canvas c, String s, Offset centre, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontFamily: 'Roboto', fontSize: size, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.2)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(M3PillarFuseWorldPainter old) => old.geo != geo || old.box != box || old.seed != seed;
}

/// The small pictures on the fuse tray (HRC fuse, copper strip, thick wire).
class M3PillarFuseItemPainter extends CustomPainter {
  const M3PillarFuseItemPainter(this.kind);

  /// 0 = HRC fuse, 1 = copper strip, 2 = thick wire.
  final int kind;

  @override
  void paint(Canvas c, Size size) {
    final ctr = size.center(Offset.zero);
    switch (kind) {
      case 0:
        final body = Rect.fromCenter(center: ctr, width: size.width * 0.34, height: size.height * 0.62);
        c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(4)), Paint()..shader = const LinearGradient(colors: [Color(0xFFFFFDF2), Color(0xFFD9CFAE)]).createShader(body));
        final cap = Paint()..color = const Color(0xFFCFD5DA);
        c.drawRect(Rect.fromLTWH(body.left - 2, body.top - 4, body.width + 4, 6), cap);
        c.drawRect(Rect.fromLTWH(body.left - 2, body.bottom - 2, body.width + 4, 6), cap);
        final tp = TextPainter(
          text: const TextSpan(text: 'HRC', style: TextStyle(fontFamily: 'Roboto', fontSize: 8, fontWeight: FontWeight.w900, color: Color(0xFF7A2A1A))),
          textDirection: TextDirection.ltr,
        )..layout();
        c.save();
        c.translate(ctr.dx, ctr.dy);
        c.rotate(-math.pi / 2);
        tp.paint(c, Offset(-tp.width / 2, -tp.height / 2));
        c.restore();
      case 1:
        final strip = Rect.fromCenter(center: ctr, width: size.width * 0.18, height: size.height * 0.74);
        c.drawRect(strip, Paint()..shader = const LinearGradient(colors: [Color(0xFFE39A5A), Color(0xFFB0602A), Color(0xFFE8A86E)]).createShader(strip));
      default:
        final p = Path()..moveTo(ctr.dx - size.width * 0.2, ctr.dy + size.height * 0.34);
        for (var k = 0; k < 4; k++) {
          final y = ctr.dy + size.height * (0.34 - 0.18 * (k + 1));
          p.quadraticBezierTo(ctr.dx + (k.isEven ? 1 : -1) * size.width * 0.34, y + size.height * 0.09, ctr.dx + (k.isEven ? -1 : 1) * size.width * 0.2, y);
        }
        c.drawPath(p, Paint()
          ..color = const Color(0xFFC77A3A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.5
          ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(M3PillarFuseItemPainter old) => old.kind != kind;
}

/// The flash in the box (the deadly moment, in colour over the frozen
/// scene): an arc flash at [at]; with [fire], the bodged slot burning.
class M3PillarFuseFlashPainter extends CustomPainter {
  const M3PillarFuseFlashPainter({required this.at, required this.v, required this.fire});
  final Offset at;
  final double v;
  final bool fire;

  @override
  void paint(Canvas c, Size size) {
    final flick = v < 0.5 ? (0.65 + 0.35 * math.sin(v * 60).abs()) : (1 - (v - 0.5) * 1.2).clamp(0.4, 1.0);
    final r = 30 + 90 * Curves.easeOut.transform(v.clamp(0.0, 1.0));
    final hot = fire ? const Color(0xFFFF8A2E) : const Color(0xFF8CAAFF);
    c.drawCircle(
        at,
        r,
        Paint()
          ..shader = RadialGradient(colors: [Color.fromRGBO(255, 250, 220, 0.95 * flick), hot.withValues(alpha: 0.55 * flick), const Color(0x00FFC24A)])
              .createShader(Rect.fromCircle(center: at, radius: r)));
    if (fire) {
      for (var i = 0; i < 7; i++) {
        final x = at.dx - 30 + i * 10.0;
        final h = 26 + 30 * math.sin(v * 20 + i).abs();
        c.drawPath(
            Path()
              ..moveTo(x - 6, at.dy + 10)
              ..quadraticBezierTo(x - 4, at.dy - h * 0.5, x, at.dy - h)
              ..quadraticBezierTo(x + 4, at.dy - h * 0.5, x + 6, at.dy + 10)
              ..close(),
            Paint()..color = Color.fromRGBO(255, 120 + i * 12, 30, 0.85 * flick));
      }
    }
    final spark = Paint()
      ..color = Color.fromRGBO(255, 214, 90, (1 - v).clamp(0.0, 1.0))
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 16; i++) {
      final a = i / 16 * math.pi * 2 + 0.2;
      final d0 = 10 + 50 * v;
      c.drawLine(at + Offset(math.cos(a), math.sin(a)) * d0, at + Offset(math.cos(a), math.sin(a)) * (d0 + 14), spark);
    }
    final white = (1 - v * 4).clamp(0.0, 1.0);
    if (white > 0) c.drawRect(Offset.zero & size, Paint()..color = Color.fromRGBO(255, 255, 255, 0.8 * white));
  }

  @override
  bool shouldRepaint(M3PillarFuseFlashPainter old) => old.v != v || old.at != at || old.fire != fire;
}
