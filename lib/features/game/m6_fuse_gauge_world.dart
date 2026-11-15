import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The drawn world of lesson 6.3 কাজ 1 "মেপে তবেই বাঁধো" (m6_fuse_gauge.dart):
// a village lane by a DTR pole in the daytime. On the pole (back right) the
// AB switch and the HG fuses up top, the LT box lower down with its switch
// OFF, a padlock and a red tag (the LT carriers come from an isolated,
// locked, proved-dead board — ruling X4). In front, the van's tailgate is a
// bench: the round wire-gauge plate (six slots, read in mm) or, on the
// micrometer job, a micrometer; a tray of four tinned-copper fuse-wire reels
// with their tags worn off (all alike); and at the bench edge on every play
// an ACSR offcut and a GI binding-wire coil. On the right the porcelain
// kit-kat carrier to be wired, its old melted wire still on it until the new
// wire is tied between its top and bottom screws.
//
// No text in the art except what a worker reads: the plate's mm marks, the
// micrometer's mm readout, the trainee's own chalk number under a reel he
// measured, OFF on the LT switch. Code-drawn, gradients, no bitmaps.
//
// Design: 360 wide × the scene's height; everything sits relative to the
// bottom (a tall phone gets more sky, never a stretched bench).

/// Where the carrier came from (lesson 6.3 point 3: old LT boxes, rural DBs,
/// consumer meter boards).
enum M6FusePlace { ltBox, ruralDb, meterBoard }

/// The job's measuring tool.
enum M6FuseTool { plate, micrometer }

/// The wire sources on the bench: reels 0–3, then the ACSR offcut (4) and the
/// GI binding coil (5).
const int m6AcsrSrc = 4;
const int m6GiSrc = 5;
const int m6SourceCount = 6;

/// The plate's six slots, in hundredths of a mm (the lesson's four IS 9926
/// diameters and two decoy sizes that carry no rating claim).
const List<int> m6PlateMm = [50, 70, 85, 120, 150, 200];

/// 0.85 → "0.85".
String m6Mm(int mm100) => (mm100 / 100).toStringAsFixed(2);

/// Where things are (design px, 360 wide).
@immutable
class M6FuseGeo {
  const M6FuseGeo._(this.height, this.base);

  factory M6FuseGeo.forScene(double height, double inset) => M6FuseGeo._(height, height - inset * 0.5);

  final double height;

  /// The visible bottom of the scene.
  final double base;

  /// The job docket clipped to the bench (a widget, not painted).
  static const Rect docket = Rect.fromLTWH(8, 128, 150, 54);

  /// The transformer tank on the pole (the fire of a jugaad wire is drawn here).
  static const Rect dtrTank = Rect.fromLTWH(308, 136, 40, 44);

  /// The reel tray: four reels in a row.
  double get reelY => base - 225;
  Offset reel(int i) => Offset(30 + 54.0 * i, reelY);

  /// The bench-edge junk: two places, the ACSR and the GI coil dealt to them.
  Offset junk(int slot) => Offset(slot == 0 ? 42 : 108, base - 118);

  /// A source's centre (reels 0–3; ACSR / GI by the dealt side).
  Offset source(int src, {required bool acsrLeft}) {
    if (src < 4) return reel(src);
    final left = (src == m6AcsrSrc) == acsrLeft;
    return junk(left ? 0 : 1);
  }

  Rect sourceHit(int src, {required bool acsrLeft}) =>
      src < 4 ? Rect.fromCenter(center: reel(src), width: 46, height: 62) : Rect.fromCenter(center: source(src, acsrLeft: acsrLeft), width: 58, height: 46);

  /// The gauge plate (plate jobs) / the micrometer (the micrometer job).
  Offset get plate => Offset(84, (docket.bottom + reelY - 31) / 2);
  static const double plateR = 52;

  /// Slot [k] of the plate: clockwise from the top, thinnest first.
  Offset slot(int k) {
    final a = -math.pi / 2 + k * math.pi / 3;
    return plate + Offset(math.cos(a), math.sin(a)) * 44;
  }

  Rect slotHit(int k) => Rect.fromCenter(center: slot(k), width: 26, height: 26);
  Rect get plateHit => Rect.fromCircle(center: plate, radius: plateR + 8);

  /// The micrometer: its jaws (the wire goes in) and its thimble (roll it).
  Rect get jawsHit => Rect.fromCenter(center: Offset(48, plate.dy), width: 46, height: 50);
  Rect get thimbleHit => Rect.fromCenter(center: Offset(150, plate.dy), width: 70, height: 56);
  Rect get readout => Rect.fromCenter(center: Offset(112, plate.dy - 42), width: 86, height: 24);

  /// The kit-kat carrier and its two screws.
  Rect get carrier {
    final room = (base - 192) - 132 - 210;
    return Rect.fromLTWH(236, 132 + math.max(0.0, room / 2), 96, 210);
  }

  Offset get topScrew => Offset(carrier.center.dx, carrier.top + 40);
  Offset get bottomScrew => Offset(carrier.center.dx, carrier.top + 170);
  Rect get topScrewHit => Rect.fromCenter(center: topScrew, width: 46, height: 46);
  Rect get bottomScrewHit => Rect.fromCenter(center: bottomScrew, width: 46, height: 46);

  /// The trainee stands by the bench.
  Rect get trainee => Rect.fromLTWH(158, base - 114, 44, 104);

  /// The bench top (the tailgate).
  double get benchTop => reelY - 44;

  @override
  bool operator ==(Object other) => other is M6FuseGeo && other.height == height && other.base == base;

  @override
  int get hashCode => Object.hash(height, base);
}

/// What the bench and the carrier show now.
@immutable
class M6FuseRig {
  const M6FuseRig({
    required this.place,
    required this.tool,
    required this.acsrLeft,
    this.chalk = const {},
    this.held,
    this.anchored,
    this.fitted = false,
    this.micLoaded,
    this.micReading,
  });

  final M6FusePlace place;
  final M6FuseTool tool;
  final bool acsrLeft;

  /// The trainee's chalk number under each reel he measured snug (mm100).
  final Map<int, int> chalk;

  /// The source in his hand, the one tied to the top screw.
  final int? held;
  final int? anchored;

  /// The new wire is tied (the job is done).
  final bool fitted;

  /// The micrometer: the source in its jaws, its last reading (mm100).
  final int? micLoaded;
  final int? micReading;

  @override
  bool operator ==(Object other) =>
      other is M6FuseRig &&
      other.place == place &&
      other.tool == tool &&
      other.acsrLeft == acsrLeft &&
      mapEquals(other.chalk, chalk) &&
      other.held == held &&
      other.anchored == anchored &&
      other.fitted == fitted &&
      other.micLoaded == micLoaded &&
      other.micReading == micReading;

  @override
  int get hashCode => Object.hash(place, tool, acsrLeft, Object.hashAllUnordered(chalk.entries.map((e) => e.key * 1000 + e.value)), held, anchored, fitted, micLoaded, micReading);
}

const _copper = Color(0xFFC77B3A);
const _copperDark = Color(0xFF8A4E22);
const _tin = Color(0xFFD9D4C8);
const _tinWire = Color(0xFF8F979C);
const _steel = Color(0xFF7A848C);
const _porcelain = Color(0xFFEFF1EC);
const _brass = Color(0xFFC9A23E);

class M6FusePainter extends CustomPainter {
  const M6FusePainter({required this.geo, required this.rig, required this.seed});

  final M6FuseGeo geo;
  final M6FuseRig rig;
  final int seed;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    final rnd = math.Random(seed);
    _sky(c, w, g, rnd);
    _pole(c, g);
    _ground(c, w, size.height, g, rnd);
    _bench(c, g);
    if (rig.tool == M6FuseTool.plate) {
      _plate(c, g);
    } else {
      _micrometer(c, g);
    }
    for (var i = 0; i < 4; i++) {
      _reel(c, g.reel(i), i);
    }
    _acsr(c, g.source(m6AcsrSrc, acsrLeft: rig.acsrLeft));
    _gi(c, g.source(m6GiSrc, acsrLeft: rig.acsrLeft));
    _carrier(c, g);
    final a = rig.anchored;
    if (a != null && !rig.fitted) {
      // The wire end runs from its source up to the top screw.
      final from = g.source(a, acsrLeft: rig.acsrLeft);
      _wireLine(c, from, g.topScrew, a);
    }
  }

  void _sky(Canvas c, double w, M6FuseGeo g, math.Random rnd) {
    final sky = Rect.fromLTWH(0, 0, w, g.benchTop);
    c.drawRect(
        sky,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5A93C9), Color(0xFFB2D3EC), Color(0xFFE8EEDB)],
          ).createShader(sky));
    final cloud = Paint()..color = const Color(0xCCFFFFFF);
    for (var i = 0; i < 3; i++) {
      final cx = 20 + rnd.nextDouble() * 200;
      final cy = 70 + rnd.nextDouble() * 40;
      for (var k = 0; k < 4; k++) {
        c.drawOval(Rect.fromCenter(center: Offset(cx + k * 12 - 18, cy - (k.isOdd ? 4 : 0)), width: 30, height: 14), cloud);
      }
    }
    // Far fields and a row of trees; the place sets the near backdrop.
    final horizon = g.benchTop - 40;
    final far = Rect.fromLTWH(0, horizon - 30, w, 70);
    c.drawRect(far, Paint()..color = const Color(0xFF9CBF7A));
    final tree = Paint()..color = const Color(0xFF4F7A3A);
    for (var x = -10.0; x < w; x += 26 + rnd.nextDouble() * 14) {
      c.drawCircle(Offset(x, horizon - 30), 12 + rnd.nextDouble() * 6, tree);
    }
    switch (rig.place) {
      case M6FusePlace.ltBox:
        break;
      case M6FusePlace.ruralDb:
        // A village shop wall with the DB on it.
        final wall = Rect.fromLTWH(150, horizon - 60, 70, 60);
        c.drawRect(wall, Paint()..color = const Color(0xFFD8C3A0));
        c.drawRect(Rect.fromLTWH(170, horizon - 46, 26, 22), Paint()..color = const Color(0xFF8C9298));
      case M6FusePlace.meterBoard:
        // A house with its meter board by the door.
        final wall = Rect.fromLTWH(140, horizon - 66, 80, 66);
        c.drawRect(wall, Paint()..color = const Color(0xFFE6D7B8));
        final roof = Path()
          ..moveTo(134, horizon - 66)
          ..lineTo(180, horizon - 92)
          ..lineTo(226, horizon - 66)
          ..close();
        c.drawPath(roof, Paint()..color = const Color(0xFF9A4A32));
        c.drawRect(Rect.fromLTWH(150, horizon - 40, 18, 40), Paint()..color = const Color(0xFF6B4A33));
        c.drawRect(Rect.fromLTWH(186, horizon - 52, 22, 18), Paint()..color = const Color(0xFF3E4A56));
    }
  }

  /// The DTR pole at the back right: the AB switch and HG fuses up top, the
  /// transformer, the LT box OFF with a padlock and a tag.
  void _pole(Canvas c, M6FuseGeo g) {
    const x = 334.0;
    const top = 96.0;
    final foot = g.benchTop - 20;
    c.drawRect(Rect.fromLTRB(x - 5, top, x + 5, foot), Paint()..color = const Color(0xFF9A9C98));
    // Cross-arm with three AB blades and the HG horns.
    c.drawRect(Rect.fromLTRB(x - 30, top + 8, x + 26, top + 13), Paint()..color = _steel);
    for (var i = 0; i < 3; i++) {
      final bx = x - 24 + i * 22.0;
      c.drawRect(Rect.fromLTWH(bx - 2, top - 2, 4, 10), Paint()..color = _porcelain);
      final horn = Paint()
        ..color = _copperDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;
      c.drawArc(Rect.fromCenter(center: Offset(bx, top + 24), width: 10, height: 12), math.pi, math.pi, false, horn);
    }
    // The transformer tank on its platform.
    const tank = M6FuseGeo.dtrTank; // (x - 26, top + 40, 40, 44)
    c.drawRRect(RRect.fromRectAndRadius(tank, const Radius.circular(3)), Paint()..color = const Color(0xFF6E7F72));
    c.drawRect(Rect.fromLTWH(x - 32, tank.bottom, 52, 4), Paint()..color = _steel);
    // The LT box: switch OFF, padlock, red tag.
    final box = Rect.fromLTWH(x - 28, tank.bottom + 16, 34, 30);
    c.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(2)), Paint()..color = const Color(0xFF8A949C));
    c.drawRect(Rect.fromLTWH(box.right - 10, box.top + 6, 4, 14), Paint()..color = const Color(0xFF2B2F33));
    c.drawCircle(Offset(box.right - 8, box.top + 23), 3.2, Paint()..color = _brass);
    c.drawRect(Rect.fromLTWH(box.right - 4, box.top + 18, 9, 12), Paint()..color = const Color(0xFFD03A2C));
    _text(c, 'OFF', Offset(box.left + 11, box.top + 9), const Color(0xFF1E2226), 6.5);
  }

  void _ground(Canvas c, double w, double h, M6FuseGeo g, math.Random rnd) {
    final lane = Rect.fromLTRB(0, g.benchTop - 20, w, h);
    c.drawRect(lane, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFB59A70), Color(0xFF7F6746)]).createShader(lane));
    final pebble = Paint()..color = const Color(0x33402E1A);
    for (var i = 0; i < 24; i++) {
      c.drawCircle(Offset(rnd.nextDouble() * w, g.benchTop + rnd.nextDouble() * (h - g.benchTop)), 1 + rnd.nextDouble() * 2, pebble);
    }
  }

  /// The van's tailgate as a bench under the plate and the reels.
  void _bench(Canvas c, M6FuseGeo g) {
    final top = Rect.fromLTRB(2, g.benchTop, 226, g.reelY + 40);
    c.drawRRect(
        RRect.fromRectAndRadius(top, const Radius.circular(6)),
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFDCE2E6), Color(0xFFAEB7BD)]).createShader(top));
    c.drawRect(Rect.fromLTRB(2, top.bottom - 6, 226, top.bottom), Paint()..color = const Color(0xFF7D868C));
    // A plank on the ground for the offcuts.
    final plank = Rect.fromLTRB(6, g.base - 142, 142, g.base - 94);
    c.drawRRect(RRect.fromRectAndRadius(plank, const Radius.circular(4)), Paint()..color = const Color(0xFF9C7A50));
  }

  void _plate(Canvas c, M6FuseGeo g) {
    final p = g.plate;
    final r = M6FuseGeo.plateR;
    c.drawCircle(p + const Offset(2, 3), r, Paint()..color = const Color(0x44000000));
    c.drawCircle(
        p,
        r,
        Paint()
          ..shader = const RadialGradient(colors: [Color(0xFFE4E8EA), Color(0xFFA9B2B8)]).createShader(Rect.fromCircle(center: p, radius: r)));
    c.drawCircle(p, r, Paint()
      ..color = const Color(0xFF6C767C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);
    // The hub (a rivet), then the slots and their marks.
    c.drawCircle(p, 6, Paint()..color = const Color(0xFF6C767C));
    for (var k = 0; k < 6; k++) {
      final a = -math.pi / 2 + k * math.pi / 3;
      final dir = Offset(math.cos(a), math.sin(a));
      final width = 1.6 + m6PlateMm[k] / 100 * 2.2;
      final slot = Path()
        ..moveTo((p + dir * 40).dx, (p + dir * 40).dy)
        ..lineTo((p + dir * (r + 1)).dx, (p + dir * (r + 1)).dy);
      c.drawPath(slot, Paint()
        ..color = const Color(0xFF2E3438)
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke);
      _text(c, m6Mm(m6PlateMm[k]), p + dir * 26, const Color(0xFF22282C), 8.5);
    }
  }

  void _micrometer(Canvas c, M6FuseGeo g) {
    final y = g.plate.dy;
    // The C-frame, the anvil and spindle (jaws), the sleeve and the thimble.
    final frame = Path()
      ..moveTo(30, y - 8)
      ..lineTo(30, y + 22)
      ..quadraticBezierTo(30, y + 40, 60, y + 40)
      ..lineTo(96, y + 40)
      ..quadraticBezierTo(116, y + 40, 116, y + 18)
      ..lineTo(116, y - 2);
    c.drawPath(frame, Paint()
      ..color = const Color(0xFF39424A)
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke);
    c.drawRect(Rect.fromLTRB(30, y - 6, 42, y + 6), Paint()..color = _steel);
    c.drawRect(Rect.fromLTRB(54, y - 5, 116, y + 5), Paint()..color = _steel);
    final sleeve = Rect.fromLTRB(116, y - 9, 132, y + 9);
    c.drawRect(sleeve, Paint()..color = const Color(0xFFC5CCD1));
    final thimble = Rect.fromLTRB(132, y - 14, 178, y + 14);
    c.drawRRect(
        RRect.fromRectAndRadius(thimble, const Radius.circular(3)),
        Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE2E6E8), Color(0xFF8D979D)]).createShader(thimble));
    final tick = Paint()
      ..color = const Color(0xFF4A5258)
      ..strokeWidth = 1;
    for (var i = 0; i < 9; i++) {
      final x = thimble.left + 5 + i * 4.5;
      c.drawLine(Offset(x, thimble.top + 3), Offset(x, thimble.top + 9), tick);
    }
    c.drawRect(Rect.fromLTRB(178, y - 7, 194, y + 7), Paint()..color = const Color(0xFF6C767C));
    final m = rig.micLoaded;
    if (m != null) {
      // A wire in the jaws.
      c.drawLine(Offset(42, y), Offset(54, y), Paint()
        ..color = _wireColor(m)
        ..strokeWidth = 3);
    }
    // The readout (mm only).
    final r = g.readout;
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)), Paint()..color = const Color(0xFF1B2A20));
    final read = rig.micReading;
    _text(c, read == null ? '-.-- mm' : '${m6Mm(read)} mm', r.center, const Color(0xFF9CF0A8), 10);
  }

  Color _wireColor(int src) => src == m6AcsrSrc
      ? const Color(0xFFB8BEC4)
      : src == m6GiSrc
          ? const Color(0xFF6E777E)
          : _tinWire;

  /// A reel of tinned-copper fuse wire, its tag worn off. All four look
  /// alike at screen scale; the trainee's chalk number shows under one he
  /// measured snug.
  void _reel(Canvas c, Offset at, int i) {
    final lift = rig.held == i ? -6.0 : 0.0;
    final o = at.translate(0, lift);
    if (rig.held == i) _ring(c, Rect.fromCenter(center: o, width: 46, height: 58));
    final flange = Rect.fromCenter(center: o, width: 38, height: 44);
    c.drawOval(flange.translate(0, 3), Paint()..color = const Color(0x33000000));
    c.drawOval(flange, Paint()..color = const Color(0xFF4A3A2C));
    c.drawOval(flange.deflate(5), Paint()..shader = const RadialGradient(colors: [_tin, _copper]).createShader(flange));
    final turn = Paint()
      ..color = _copperDark.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (var k = 1; k < 4; k++) {
      c.drawOval(flange.deflate(5.0 + k * 3), turn);
    }
    c.drawOval(flange.deflate(15), Paint()..color = const Color(0xFF4A3A2C));
    // A torn, blank tag.
    c.drawRect(Rect.fromLTWH(o.dx + 10, o.dy - 26, 9, 7), Paint()..color = const Color(0xFFE9DFC7));
    final ch = rig.chalk[i];
    if (ch != null) {
      // His chalk on a slate tag on the bench above the reel (clear of the
      // guide's bubble below).
      final tag = Rect.fromCenter(center: Offset(at.dx, at.dy - 33), width: 34, height: 14);
      c.drawRRect(RRect.fromRectAndRadius(tag, const Radius.circular(3)), Paint()..color = const Color(0xFF2B3238));
      _text(c, m6Mm(ch), tag.center, Colors.white, 9);
    }
  }

  void _acsr(Canvas c, Offset at) {
    final held = rig.held == m6AcsrSrc;
    final o = at.translate(0, held ? -5 : 0);
    if (held) _ring(c, Rect.fromCenter(center: o, width: 58, height: 42));
    final body = Rect.fromCenter(center: o, width: 48, height: 12);
    c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(6)), Paint()..color = const Color(0xFFAEB5BB));
    final strand = Paint()
      ..color = const Color(0xFF7E878E)
      ..strokeWidth = 1;
    for (var x = body.left + 3; x < body.right - 3; x += 5) {
      c.drawLine(Offset(x, body.top + 1), Offset(x + 4, body.bottom - 1), strand);
    }
    // A strand teased out at one end.
    final loose = Path()
      ..moveTo(body.right - 2, o.dy)
      ..quadraticBezierTo(body.right + 8, o.dy - 10, body.right + 4, o.dy - 16);
    c.drawPath(loose, Paint()
      ..color = const Color(0xFFC3C9CE)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke);
  }

  void _gi(Canvas c, Offset at) {
    final held = rig.held == m6GiSrc;
    final o = at.translate(0, held ? -5 : 0);
    if (held) _ring(c, Rect.fromCenter(center: o, width: 58, height: 42));
    final coil = Paint()
      ..color = const Color(0xFF8E979E)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (var k = 0; k < 4; k++) {
      c.drawOval(Rect.fromCenter(center: o.translate(k * 2.0 - 3, 0), width: 34, height: 22 - k * 1.5), coil);
    }
  }

  /// The same ring on whatever is in hand (never a mark of the answer).
  void _ring(Canvas c, Rect r) {
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(10)), Paint()
      ..color = const Color(0xCCFFD34E)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke);
  }

  void _carrier(Canvas c, M6FuseGeo g) {
    final r = g.carrier;
    c.drawRRect(RRect.fromRectAndRadius(r.translate(3, 4), const Radius.circular(14)), Paint()..color = const Color(0x44000000));
    c.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(14)),
        Paint()..shader = const LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Color(0xFFFFFFFF), _porcelain, Color(0xFFC9CEC8)]).createShader(r));
    // The grip ridge and the two brass blades.
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: r.center, width: r.width - 26, height: 26), const Radius.circular(8)), Paint()..color = const Color(0xFFDDE1DB));
    for (final y in [g.topScrew.dy, g.bottomScrew.dy]) {
      c.drawRect(Rect.fromCenter(center: Offset(r.center.dx, y), width: 44, height: 12), Paint()..color = _brass);
      c.drawCircle(Offset(r.center.dx, y), 8, Paint()..color = const Color(0xFF8C7430));
      c.drawLine(Offset(r.center.dx - 5, y), Offset(r.center.dx + 5, y), Paint()
        ..color = const Color(0xFF3A2E10)
        ..strokeWidth = 1.6);
    }
    final a = rig.anchored;
    if (rig.fitted && a != null) {
      // The new wire, taut between the screws.
      c.drawLine(g.topScrew, g.bottomScrew, Paint()
        ..color = _wireColor(a)
        ..strokeWidth = 3);
    } else {
      // The old melted wire: two stubs and a bead.
      final melt = Paint()
        ..color = const Color(0xFF3B3430)
        ..strokeWidth = 2;
      c.drawLine(g.topScrew, g.topScrew.translate(3, 34), melt);
      c.drawLine(g.bottomScrew, g.bottomScrew.translate(-2, -30), melt);
      c.drawCircle(g.topScrew.translate(3, 36), 3, Paint()..color = const Color(0xFF2A2420));
      final soot = Paint()..color = const Color(0x553A3028);
      c.drawOval(Rect.fromCenter(center: r.center.translate(0, 4), width: 30, height: 18), soot);
    }
  }

  void _wireLine(Canvas c, Offset from, Offset to, int src) {
    final mid = Offset((from.dx + to.dx) / 2, math.max(from.dy, to.dy) + 24);
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(mid.dx, mid.dy, to.dx, to.dy);
    c.drawPath(path, Paint()
      ..color = _wireColor(src)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke);
  }

  void _text(Canvas c, String text, Offset at, Color color, double size) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: size, fontWeight: FontWeight.w900)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, at - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(M6FusePainter old) => old.geo != geo || old.rig != rig || old.seed != seed;
}

/// The wire end following the finger while it is dragged.
class M6DragWirePainter extends CustomPainter {
  const M6DragWirePainter({required this.from, required this.to});
  final Offset from;
  final Offset to;

  @override
  void paint(Canvas c, Size size) {
    c.drawLine(from, to, Paint()
      ..color = _tinWire
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round);
    c.drawCircle(to, 4, Paint()..color = _copper);
  }

  @override
  bool shouldRepaint(M6DragWirePainter old) => old.from != from || old.to != to;
}

/// The consequence of a jugaad wire in the fuse's place: the fault current
/// goes straight to the transformer and it burns (lesson 6.3 point 5).
class M6FuseFirePainter extends CustomPainter {
  const M6FuseFirePainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final flick = 0.7 + 0.3 * math.sin(v * 50).abs();
    final r = 24 + 80 * Curves.easeOut.transform(v.clamp(0.0, 1.0));
    c.drawCircle(
        at,
        r,
        Paint()
          ..shader = RadialGradient(colors: [
            Color.fromRGBO(255, 244, 200, 0.95 * flick),
            Color.fromRGBO(255, 140, 40, 0.75 * flick),
            const Color(0x00C0392B),
          ]).createShader(Rect.fromCircle(center: at, radius: r)));
    final smoke = Paint()..color = Color.fromRGBO(40, 36, 34, (0.5 * v).clamp(0.0, 0.5));
    for (var i = 0; i < 5; i++) {
      c.drawCircle(at.translate(-20 + i * 10, -r * 0.6 - i * 6 * v), 14 + 10 * v, smoke);
    }
    final white = (1 - v * 4).clamp(0.0, 1.0);
    if (white > 0) c.drawRect(Offset.zero & size, Paint()..color = Color.fromRGBO(255, 230, 200, 0.7 * white));
  }

  @override
  bool shouldRepaint(M6FuseFirePainter old) => old.v != v || old.at != at;
}
