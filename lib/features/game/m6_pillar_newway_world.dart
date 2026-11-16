import 'dart:math' as math;

import 'package:flutter/material.dart';

// The drawn world of lesson 6.9 কাজ 2 "নতুন লাইন জুড়ুন" (m6_pillar_newway.dart):
// a lane-side LT feeder pillar by its DTR in the daytime. The pillar stands on
// the left with its door swung open (hinged on the left); inside, from the
// top: the R, Y and B busbars (each with its mark plate at the left end),
// three copper droppers that bend down from the bars behind a smoky
// insulating shroud (so the eye cannot follow a dropper from its bar to its
// fuse unit), the spare way's switch fuse unit (three fuse carriers, their
// labels worn off, each with an outgoing terminal at its foot), the SFU's
// door-mounted handle (it pokes through the shut door) with three neon lamps
// over it, the common neutral link and the earthing terminal (their sides
// are dealt), and at the foot the new lane's 4-core armoured cable rising
// from its gland: four cores with ferrule tags R, Y, B, N and the armour's
// braided earth lead, their lugs fanned out. On the right, low on the DTR
// pole, the DTR's LT switch box (its supply terminals at the top — always
// live — the OFF/ON handle and the lock-and-tag hasp), the PPE stand, the
// tester's pouch, the trainee and the crew's van.
//
// No text in the art except labels a worker reads (R, Y, B, N, LT, ON, OFF,
// the cable's lane tag, the tester's reading). Code-drawn, gradients, no
// bitmaps.
//
// Design: 360 wide × the scene's height; the pavement follows the bottom of
// the screen (a tall phone gets a taller pillar, never stretched sideways).

/// The new cable's five conductors: three phase cores, the neutral core and
/// the armour's earth lead.
enum M6NwCore { r, y, b, n, armour }

extension M6NwCoreX on M6NwCore {
  bool get isPhase => index < 3;

  /// The ferrule tag a worker reads (the armour lead carries none).
  String get tag => switch (this) {
        M6NwCore.r => 'R',
        M6NwCore.y => 'Y',
        M6NwCore.b => 'B',
        M6NwCore.n => 'N',
        M6NwCore.armour => '',
      };
}

/// Terminals: 0–2 the spare way's fuse units (left to right), then the
/// neutral link and the earthing terminal.
const int kM6NwNLink = 3;
const int kM6NwEarth = 4;
const int kM6NwTerms = 5;

/// The busbar marks.
const List<String> kM6NwBars = ['R', 'Y', 'B'];

/// Where things are (design px, 360 wide).
@immutable
class M6NwGeo {
  const M6NwGeo._(this.height, this.floorY);

  factory M6NwGeo.forScene(double height, double inset) => M6NwGeo._(height, height - floorUp - inset * 0.5);

  final double height;

  /// The pavement line at the pillar's plinth.
  final double floorY;

  /// The pavement sits this far above the bottom.
  static const double floorUp = 20;

  /// The top of the working area (under the header).
  static const double top = 132;

  /// The working height.
  double get a => floorY - top - 8;

  /// A height in the working area (0 = the top, 1 = the foot).
  double y(double f) => top + f * a;

  // --- the pillar ---------------------------------------------------------
  Rect get pillar => Rect.fromLTRB(8, top - 12, 252, floorY);
  Rect get inside => Rect.fromLTRB(24, y(-0.01), 248, y(0.9));

  /// The spare way's fuse units, left to right.
  static const List<double> fuseX = [70, 125, 180];

  /// Where the droppers meet the bars (above the shroud), left to right.
  static const List<double> attachX = [92, 147, 202];

  static const double barL = 52;
  static const double barR = 244;
  double barY(int phase) => y(0.03 + 0.055 * phase);
  Rect markRect(int phase) => Rect.fromCenter(center: Offset(39, barY(phase)), width: 20, height: 15);

  /// The tester on the bars (any bar).
  Rect get barsHit => Rect.fromLTRB(barL, y(0.012), barR, y(0.158));

  double get shroudTop => y(0.17);
  double get shroudBot => y(0.255);
  double get fuseTopY => y(0.33);
  double get fuseBodyTop => y(0.34);
  double get fuseBodyBot => y(0.44);
  double get outY => y(0.47);

  /// A dropper's free stretch under the shroud and its fuse unit's top (a tap
  /// plucks it).
  Rect pluckHit(int i) => Rect.fromLTRB(fuseX[i] - 18, shroudBot, fuseX[i] + 18, y(0.336));

  /// The dropper from fuse unit [i] (dealt: [perm] its bar, [sigma] where it
  /// comes out over the shroud): fuse top → under the shroud → over it → bar.
  List<Offset> dropper(int i, List<int> perm, List<int> sigma) => [
        Offset(fuseX[i], fuseTopY),
        Offset(fuseX[i], shroudBot + 4),
        Offset(attachX[sigma[i]], shroudTop - 4),
        Offset(attachX[sigma[i]], barY(perm[i])),
      ];

  /// The SFU's door-mounted handle (works with the door open or shut).
  Offset get sfu => Offset(226, y(0.395));
  Rect get sfuHit => Rect.fromLTRB(206, y(0.33), 246, y(0.45));

  /// The neutral link / earthing terminal row.
  double get rowY => y(0.56);
  double _rowX(int t, bool nLeft) => (t == kM6NwNLink) == nLeft ? 98 : 208;

  /// A terminal's stud (where a lug lands).
  Offset term(int t, bool nLeft) => t < 3 ? Offset(fuseX[t], outY) : Offset(_rowX(t, nLeft), rowY);
  Rect termHit(int t, bool nLeft) => Rect.fromCenter(center: term(t, nLeft), width: 44, height: 36);

  Rect nLink(bool nLeft) {
    final x = _rowX(kM6NwNLink, nLeft);
    return Rect.fromLTRB(x - 46, rowY - 8, x + 46, rowY + 8);
  }

  Rect earthBlock(bool nLeft) {
    final x = _rowX(kM6NwEarth, nLeft);
    return Rect.fromLTRB(x - 30, rowY - 12, x + 30, rowY + 12);
  }

  /// The lugs at rest (five slots, all left of the guide's bubble).
  static const List<double> lugX = [40, 82, 124, 61, 103];
  static const List<double> _lugF = [0.67, 0.67, 0.67, 0.79, 0.79];
  Offset lugHome(int slot) => Offset(lugX[slot], y(_lugF[slot]));
  Rect lugHit(int slot) => Rect.fromCenter(center: lugHome(slot), width: 40, height: 44);

  /// The cable gland (the cable comes up here).
  Offset gland(bool entryLeft) => Offset(entryLeft ? 54 : 150, y(0.93));

  // --- the door -------------------------------------------------------------
  /// The open door, swung to the left edge (a drag to the right shuts it).
  Rect get doorOpenHit => Rect.fromLTRB(0, y(0.05), 28, y(0.6));

  /// The shut door.
  Rect get doorShut => Rect.fromLTRB(10, top - 8, 250, y(0.9));

  /// The shut door's hasp (hold: the padlock; drag left: open the door).
  Offset get hasp => Offset(232, y(0.525));
  Rect get haspHit => Rect.fromLTRB(212, y(0.47), 250, y(0.58));

  // --- the DTR's LT switch box, the stand, the van --------------------------
  Rect get ltBox => Rect.fromLTRB(262, y(0), 356, y(0.21));

  /// The LT switch's supply terminals (always live: the tester is proved here).
  Rect get ltSupply => Rect.fromLTRB(262, y(0), 356, y(0.066));

  /// The lock-and-tag hasp on the switch.
  Rect get ltLockHit => Rect.fromLTRB(262, y(0.072), 306, y(0.21));

  /// The switch handle (drag down = OFF, up = ON).
  Offset get ltHandle => Offset(331, y(0.14));
  Rect get ltHandleHit => Rect.fromLTRB(308, y(0.072), 356, y(0.21));

  Rect get ppe => Rect.fromLTRB(258, y(0.24), 306, y(0.39));
  Rect get trainee => Rect.fromLTRB(310, y(0.22), 356, y(0.41));
  Rect get testerHit => Rect.fromLTRB(258, y(0.42), 302, y(0.54));
  Rect get van => Rect.fromLTRB(306, y(0.42), 358, y(0.58));

  /// Where a deadly arc flash comes off (the busbars).
  Offset get flashAt => Offset(150, barY(1));

  @override
  bool operator ==(Object other) => other is M6NwGeo && other.height == height && other.floorY == floorY;

  @override
  int get hashCode => Object.hash(height, floorY);
}

/// What the scene shows now.
@immutable
class M6NwRig {
  const M6NwRig({
    required this.perm,
    required this.sigma,
    required this.slots,
    required this.nLeft,
    required this.entryLeft,
    required this.lane,
    this.ppe = false,
    this.ltOn = true,
    this.lockTag = false,
    this.testerInHand = false,
    this.sfuOn = true,
    this.doorOpen = true,
    this.locked = false,
    this.landed = const {},
    this.dragging,
    this.plucked,
    this.lit = false,
    this.hot = const [],
    this.readAt,
    this.readLive = false,
  });

  /// Fuse unit i is fed from bar perm[i]; its dropper comes over the shroud
  /// at column sigma[i].
  final List<int> perm;
  final List<int> sigma;

  /// The lugs' rest slots: slots[k] rests in slot k.
  final List<M6NwCore> slots;
  final bool nLeft;
  final bool entryLeft;
  final int lane;
  final bool ppe;
  final bool ltOn;
  final bool lockTag;
  final bool testerInHand;
  final bool sfuOn;
  final bool doorOpen;
  final bool locked;

  /// Lugs landed: core → terminal.
  final Map<M6NwCore, int> landed;

  /// The lug in the hand (drawn by the drag layer, not at rest).
  final M6NwCore? dragging;

  /// The fuse unit whose dropper was plucked last (its bar's mark lights).
  final int? plucked;

  /// The new lane is fed (the neon lamps glow).
  final bool lit;

  /// Loose lugs glowing hot (the switch-on glance).
  final List<M6NwCore> hot;

  /// The tester's last reading and where.
  final Offset? readAt;
  final bool readLive;

  String get _sig => '${perm.join()}${sigma.join()}${slots.map((c) => c.index).join()}$nLeft$entryLeft$lane$ppe$ltOn$lockTag'
      '$testerInHand$sfuOn$doorOpen$locked${landed.entries.map((e) => '${e.key.index}${e.value}').join(',')}'
      '${dragging?.index}$plucked$lit${hot.map((c) => c.index).join()}$readAt$readLive';

  @override
  bool operator ==(Object other) => other is M6NwRig && other._sig == _sig;

  @override
  int get hashCode => _sig.hashCode;
}

void _label(Canvas c, String text, Offset centre, {double size = 7, Color color = const Color(0xFF26303D), FontWeight weight = FontWeight.w800}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: weight, color: color, letterSpacing: 0.3, height: 1.05)),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  )..layout(maxWidth: 120);
  tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
}

const _copper = Color(0xFFC77A3A);
const _copperHi = Color(0xFFF2B27A);
const _markColours = [Color(0xFFD7332A), Color(0xFFE8B21C), Color(0xFF2F66C8)];

Path _polyline(List<Offset> pts) {
  final p = Path()..moveTo(pts.first.dx, pts.first.dy);
  for (final o in pts.skip(1)) {
    p.lineTo(o.dx, o.dy);
  }
  return p;
}

/// A core from the gland to [to] (a soft bend).
Path m6NwCorePath(Offset from, Offset to) {
  final mid = Offset(from.dx, (from.dy + to.dy) / 2);
  return Path()
    ..moveTo(from.dx, from.dy)
    ..cubicTo(mid.dx, mid.dy, to.dx, mid.dy + (to.dy - mid.dy) * 0.4, to.dx, to.dy + 10);
}

/// The lug at [at]: a tinned lug on its core (with the ferrule tag), or the
/// armour's ring lug on its braid.
void m6NwPaintLug(Canvas c, M6NwCore core, Offset at, {bool lifted = false}) {
  if (lifted) c.drawCircle(at + const Offset(2, 5), 13, Paint()..color = const Color(0x44000000));
  final armour = core == M6NwCore.armour;
  // The core's insulation (black) or the braid (grey, hatched) under the lug.
  final sleeve = Rect.fromCenter(center: at + const Offset(0, 14), width: armour ? 9 : 11, height: 16);
  c.drawRRect(RRect.fromRectAndRadius(sleeve, const Radius.circular(3)), Paint()..color = armour ? const Color(0xFF8C939A) : const Color(0xFF1E2126));
  if (armour) {
    for (var k = 0; k < 4; k++) {
      final yy = sleeve.top + 3 + k * 3.4;
      c.drawLine(Offset(sleeve.left, yy), Offset(sleeve.right, yy + 2), Paint()
        ..color = const Color(0xFF5E656C)
        ..strokeWidth = 1);
    }
  } else {
    // The ferrule tag (white sleeve, black letter).
    final tag = Rect.fromCenter(center: at + const Offset(0, 17), width: 14, height: 9);
    c.drawRRect(RRect.fromRectAndRadius(tag, const Radius.circular(2)), Paint()..color = const Color(0xFFF4F1E8));
    _label(c, core.tag, tag.center, size: 7, color: const Color(0xFF15181C), weight: FontWeight.w900);
  }
  // The lug barrel and palm with its hole.
  final palm = Rect.fromCenter(center: at, width: 15, height: 15);
  c.drawRRect(
      RRect.fromRectAndRadius(palm, const Radius.circular(7)),
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFFE8ECEF), Color(0xFFA9B1B8)]).createShader(palm));
  c.drawRect(Rect.fromCenter(center: at + const Offset(0, 8), width: 8, height: 6), Paint()..color = const Color(0xFFBFC6CC));
  c.drawCircle(at, 3.4, Paint()..color = const Color(0xFF3A4048));
}

/// The pillar, its inside, the LT switch box, the stand, the van and the
/// street. Repaints only when the state changes.
class M6NwWorldPainter extends CustomPainter {
  const M6NwWorldPainter({required this.geo, required this.rig});

  final M6NwGeo geo;
  final M6NwRig rig;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    // The sky and a lane of houses far behind.
    final sky = Rect.fromLTWH(0, 0, w, g.floorY);
    c.drawRect(
        sky,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF8EC3E6), Color(0xFFCFE6F2), Color(0xFFE9E2CF)],
          ).createShader(sky));
    final houses = Paint()..color = const Color(0xFFB9AE98);
    for (var i = 0; i < 6; i++) {
      final x = -10.0 + i * 64;
      final h = 60.0 + (i * 37 % 40);
      c.drawRect(Rect.fromLTWH(x, g.floorY - 40 - h, 54, h + 40), houses);
      c.drawRect(Rect.fromLTWH(x + 10, g.floorY - 30 - h, 12, 12), Paint()..color = rig.lit ? const Color(0xFFFFE08A) : const Color(0xFF8C8270));
    }
    // The pavement.
    final floor = Rect.fromLTRB(0, g.floorY, w, size.height);
    c.drawRect(floor, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF9B9488), Color(0xFF6F6A61)]).createShader(floor));
    for (var x = 0.0; x < w; x += 30) {
      c.drawLine(Offset(x, g.floorY), Offset(x - 8, size.height), Paint()
        ..color = const Color(0xFF7E786E)
        ..strokeWidth = 1);
    }
    _pole(c);
    _ltBox(c);
    _stand(c);
    _pouch(c);
    _van(c);
    _pillar(c);
    if (rig.readAt != null) _reading(c, rig.readAt!, rig.readLive);
  }

  // --- the DTR pole and its LT switch box -------------------------------------
  void _pole(Canvas c) {
    final g = geo;
    final pole = Rect.fromLTRB(300, 0, 316, g.floorY);
    c.drawRect(pole, Paint()..shader = const LinearGradient(colors: [Color(0xFF9AA0A6), Color(0xFF6E757C)]).createShader(pole));
    // The DTR's tank bottom just under the header, its LT cable down to the box.
    final tank = Rect.fromLTRB(272, 60, 346, 118);
    c.drawRRect(RRect.fromRectAndRadius(tank, const Radius.circular(6)),
        Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF7D8C80), Color(0xFF55635A)]).createShader(tank));
    c.drawLine(const Offset(286, 118), Offset(286, g.ltBox.top), Paint()
      ..color = const Color(0xFF1E2126)
      ..strokeWidth = 5);
  }

  void _ltBox(Canvas c) {
    final g = geo;
    final b = g.ltBox;
    c.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(5)),
        Paint()..shader = const LinearGradient(colors: [Color(0xFFCBD2D8), Color(0xFF9EA7AF)]).createShader(b));
    c.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(5)), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF59626B));
    // The supply terminals (three, always live).
    final s = g.ltSupply;
    for (var k = 0; k < 3; k++) {
      final x = s.left + 22 + k * 25;
      c.drawCircle(Offset(x, s.center.dy), 5, Paint()..color = const Color(0xFF3A4048));
      c.drawCircle(Offset(x, s.center.dy), 3, Paint()..color = _copperHi);
    }
    c.drawLine(Offset(s.left + 6, s.bottom), Offset(s.right - 6, s.bottom), Paint()
      ..color = const Color(0xFF59626B)
      ..strokeWidth = 1.2);
    _label(c, 'LT', Offset(g.ltLockHit.center.dx, g.ltLockHit.top + 9), size: 9, weight: FontWeight.w900);
    // The handle: up = ON, down = OFF.
    final h = g.ltHandle;
    final slot = Rect.fromCenter(center: h, width: 10, height: 34);
    c.drawRRect(RRect.fromRectAndRadius(slot, const Radius.circular(4)), Paint()..color = const Color(0xFF2A2F35));
    _label(c, 'ON', h + const Offset(16, -13), size: 6.5);
    _label(c, 'OFF', h + const Offset(17, 13), size: 6.5);
    final tip = h + Offset(0, rig.ltOn ? -12 : 12);
    c.drawLine(h, tip, Paint()
      ..color = const Color(0xFF1B1E22)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round);
    c.drawCircle(tip, 6, Paint()..color = rig.ltOn ? const Color(0xFFD7332A) : const Color(0xFF2E9E4F));
    // The hasp, and the padlock and tag on it.
    final lockAt = Offset(g.ltLockHit.center.dx, g.ltLockHit.center.dy + 6);
    c.drawCircle(lockAt, 6, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..color = const Color(0xFF59626B));
    if (rig.lockTag) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: lockAt + const Offset(0, 7), width: 15, height: 12), const Radius.circular(3)), Paint()..color = const Color(0xFFC0392B));
      c.drawArc(Rect.fromCenter(center: lockAt + const Offset(0, 1), width: 10, height: 10), math.pi, math.pi, false, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = const Color(0xFF6E757C));
      final tag = Rect.fromLTWH(lockAt.dx + 9, lockAt.dy + 2, 14, 20);
      c.drawRect(tag, Paint()..color = const Color(0xFFFFD34D));
      c.drawRect(tag.deflate(2), Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFFC0392B));
    }
  }

  // --- the PPE stand, the tester pouch, the van -------------------------------
  void _stand(Canvas c) {
    final r = geo.ppe;
    final post = Paint()..color = const Color(0xFF5B4632);
    c.drawRect(Rect.fromLTRB(r.center.dx - 2, r.top + 6, r.center.dx + 2, r.bottom), post);
    c.drawRect(Rect.fromLTRB(r.left + 6, r.bottom - 4, r.right - 6, r.bottom), post);
    c.drawRect(Rect.fromLTRB(r.left + 4, r.top + 8, r.right - 4, r.top + 11), post);
    if (rig.ppe) return;
    // Helmet, goggles, gloves.
    final hc = Offset(r.center.dx, r.top + 6);
    c.drawArc(Rect.fromCenter(center: hc + const Offset(0, 4), width: 26, height: 20), math.pi, math.pi, true, Paint()..color = const Color(0xFFFFFFFF));
    c.drawLine(hc + const Offset(-15, 4), hc + const Offset(15, 4), Paint()
      ..color = const Color(0xFFDDDDDD)
      ..strokeWidth = 2.5);
    final gy = r.top + r.height * 0.42;
    for (final dx in [-7.0, 7.0]) {
      c.drawOval(Rect.fromCenter(center: Offset(r.center.dx + dx, gy), width: 12, height: 8), Paint()..color = const Color(0xFF79B8D6));
    }
    c.drawLine(Offset(r.left + 6, gy), Offset(r.right - 6, gy), Paint()
      ..color = const Color(0xFF26303D)
      ..strokeWidth = 1.4);
    for (final dx in [-10.0, 10.0]) {
      final glove = Rect.fromCenter(center: Offset(r.center.dx + dx, r.top + r.height * 0.72), width: 12, height: r.height * 0.32);
      c.drawRRect(RRect.fromRectAndRadius(glove, const Radius.circular(5)), Paint()..color = const Color(0xFFE8B21C));
    }
  }

  void _pouch(Canvas c) {
    final r = geo.testerHit;
    final pouch = Rect.fromLTRB(r.left + 8, r.top + r.height * 0.35, r.right - 8, r.bottom - 2);
    c.drawRRect(RRect.fromRectAndRadius(pouch, const Radius.circular(5)), Paint()..color = const Color(0xFF3B2E22));
    if (rig.testerInHand) return;
    // The two-pole tester standing in its pouch.
    final body = Rect.fromLTRB(r.center.dx - 5, r.top + 2, r.center.dx + 5, pouch.top + 6);
    c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(3)), Paint()..color = const Color(0xFFE8B21C));
    c.drawRect(Rect.fromCenter(center: Offset(body.center.dx, body.top + 6), width: 6, height: 5), Paint()..color = const Color(0xFF26303D));
  }

  void _van(Canvas c) {
    final r = geo.van;
    final body = Rect.fromLTRB(r.left + 2, r.top + r.height * 0.25, r.right, r.bottom - 7);
    c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(5)), Paint()..color = const Color(0xFFF2F4F5));
    c.drawRect(Rect.fromLTRB(body.left, body.center.dy - 2, body.right, body.center.dy + 2), Paint()..color = const Color(0xFF2F66C8));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(body.left + 4, body.top + 3, body.left + 18, body.center.dy - 4), const Radius.circular(2)), Paint()..color = const Color(0xFF79B8D6));
    for (final x in [body.left + 10, body.right - 10]) {
      c.drawCircle(Offset(x, r.bottom - 7), 6, Paint()..color = const Color(0xFF26292E));
      c.drawCircle(Offset(x, r.bottom - 7), 2.5, Paint()..color = const Color(0xFF9AA0A6));
    }
  }

  // --- the pillar ---------------------------------------------------------------
  void _pillar(Canvas c) {
    final g = geo;
    final p = g.pillar;
    // The plinth and the box.
    c.drawRect(Rect.fromLTRB(p.left - 4, g.floorY - 10, p.right + 4, g.floorY + 4), Paint()..color = const Color(0xFF8A847A));
    c.drawRRect(RRect.fromRectAndRadius(p, const Radius.circular(6)),
        Paint()..shader = const LinearGradient(colors: [Color(0xFF6F8A78), Color(0xFF55705F)]).createShader(p));
    // The cable from the pavement into the gland.
    final gl = g.gland(rig.entryLeft);
    c.drawLine(Offset(gl.dx, g.floorY + 30), gl, Paint()
      ..color = const Color(0xFF1E2126)
      ..strokeWidth = 14);
    if (!rig.doorOpen) {
      _cores(c);
      _door(c);
      return;
    }
    final ins = g.inside;
    c.drawRect(ins, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF39433E), Color(0xFF2A322E)]).createShader(ins));
    _bars(c);
    _droppers(c);
    _shroud(c);
    _fuses(c);
    _sfu(c);
    _row(c);
    _cores(c);
    // The open door, swung back to the left edge.
    final d = Rect.fromLTRB(0, g.doorShut.top + 6, 12, g.doorShut.bottom - 6);
    c.drawRect(d, Paint()..shader = const LinearGradient(colors: [Color(0xFF4B6352), Color(0xFF6F8A78)]).createShader(d));
    c.drawLine(Offset(d.right, d.top), Offset(d.right, d.bottom), Paint()
      ..color = const Color(0xFF2E3B33)
      ..strokeWidth = 1.5);
  }

  void _bars(Canvas c) {
    final g = geo;
    for (var k = 0; k < 3; k++) {
      final yy = g.barY(k);
      final bar = Rect.fromLTRB(M6NwGeo.barL, yy - 4, M6NwGeo.barR, yy + 4);
      c.drawRect(bar, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_copperHi, _copper, Color(0xFF8E5226)]).createShader(bar));
      // The mark plate; the plucked dropper's bar lights its mark.
      final lit = rig.plucked != null && rig.perm[rig.plucked!] == k;
      final m = g.markRect(k);
      if (lit) c.drawCircle(m.center, 15, Paint()..color = const Color(0x88FFF3B0));
      c.drawRRect(RRect.fromRectAndRadius(m, const Radius.circular(3)), Paint()..color = lit ? const Color(0xFFFFF7D6) : const Color(0xFFE3E0D6));
      _label(c, kM6NwBars[k], m.center, size: 9, color: _markColours[k], weight: FontWeight.w900);
    }
  }

  void _droppers(Canvas c) {
    final g = geo;
    for (var i = 0; i < 3; i++) {
      final pts = g.dropper(i, rig.perm, rig.sigma);
      final path = _polyline(pts);
      c.drawPath(path, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xFF7A4520));
      c.drawPath(path, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.6
        ..strokeJoin = StrokeJoin.round
        ..color = _copper);
      // The bolt where it meets its bar.
      c.drawCircle(pts.last, 4, Paint()..color = const Color(0xFFBFC6CC));
    }
  }

  void _shroud(Canvas c) {
    final g = geo;
    final s = Rect.fromLTRB(M6NwGeo.barL - 6, g.shroudTop, M6NwGeo.barR, g.shroudBot);
    c.drawRRect(RRect.fromRectAndRadius(s, const Radius.circular(3)),
        Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF262B2F), Color(0xFF363C41)]).createShader(s));
    for (var x = s.left + 14; x < s.right; x += 26) {
      c.drawCircle(Offset(x, s.top + 6), 2, Paint()..color = const Color(0xFF6E757C));
    }
  }

  void _fuses(Canvas c) {
    final g = geo;
    final body = Rect.fromLTRB(M6NwGeo.fuseX.first - 26, g.fuseBodyTop, M6NwGeo.fuseX.last + 26, g.fuseBodyBot);
    c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(4)), Paint()..color = const Color(0xFF1F2327));
    for (var i = 0; i < 3; i++) {
      final x = M6NwGeo.fuseX[i];
      // Top terminal (the dropper's), the carrier, the outgoing stud.
      c.drawCircle(Offset(x, g.fuseTopY), 4.5, Paint()..color = const Color(0xFFBFC6CC));
      final carrier = Rect.fromLTRB(x - 14, g.fuseBodyTop + 6, x + 14, g.fuseBodyBot - 6);
      c.drawRRect(RRect.fromRectAndRadius(carrier, const Radius.circular(4)),
          Paint()..shader = const LinearGradient(colors: [Color(0xFF4A4F55), Color(0xFF2E3338)]).createShader(carrier));
      // The worn label: a scuffed blank plate.
      c.drawRect(Rect.fromCenter(center: carrier.center, width: 16, height: 8), Paint()..color = const Color(0xFF8C8A80));
      c.drawLine(carrier.center + const Offset(-6, 1), carrier.center + const Offset(4, -2), Paint()
        ..color = const Color(0xFF6E6C64)
        ..strokeWidth = 1);
      _stud(c, Offset(x, g.outY), rig.landed.containsValue(i));
    }
  }

  void _stud(Canvas c, Offset at, bool used) {
    c.drawRect(Rect.fromCenter(center: at, width: 18, height: 12), Paint()..color = const Color(0xFF2A2F35));
    c.drawCircle(at, 5, Paint()..color = const Color(0xFFBFC6CC));
    c.drawCircle(at, 2, Paint()..color = const Color(0xFF59626B));
  }

  void _sfu(Canvas c) {
    final g = geo;
    final h = g.sfu;
    final plate = Rect.fromCenter(center: h, width: 30, height: 46);
    c.drawRRect(RRect.fromRectAndRadius(plate, const Radius.circular(4)), Paint()..color = const Color(0xFF2A2F35));
    _label(c, 'ON', h + const Offset(0, -17), size: 6, color: const Color(0xFFE3E0D6));
    _label(c, 'OFF', h + const Offset(0, 18), size: 6, color: const Color(0xFFE3E0D6));
    final tip = h + Offset(0, rig.sfuOn ? -9 : 9);
    c.drawLine(h, tip, Paint()
      ..color = const Color(0xFFD7332A)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round);
    c.drawCircle(h, 5, Paint()..color = const Color(0xFF6E757C));
    // The neon lamps over it (the way is fed).
    for (var k = 0; k < 3; k++) {
      final at = Offset(h.dx - 9 + k * 9.0, plate.top - 8);
      if (rig.lit) c.drawCircle(at, 6, Paint()..color = const Color(0x66FF9F43));
      c.drawCircle(at, 3.4, Paint()..color = rig.lit ? const Color(0xFFFFB347) : const Color(0xFF5A4A3A));
    }
  }

  void _row(Canvas c) {
    final g = geo;
    final n = g.nLink(rig.nLeft);
    c.drawRRect(RRect.fromRectAndRadius(n, const Radius.circular(3)), Paint()..shader = const LinearGradient(colors: [Color(0xFFE2C46A), Color(0xFFB08A2E)]).createShader(n));
    _label(c, 'N', Offset(n.left + 8, n.center.dy), size: 8, weight: FontWeight.w900);
    // The link's busy studs (the incomer's neutral and the other ways').
    for (final dx in [-30.0, 30.0]) {
      c.drawCircle(Offset(n.center.dx + dx, n.center.dy), 4, Paint()..color = const Color(0xFF6E5A20));
      c.drawLine(Offset(n.center.dx + dx, n.center.dy), Offset(n.center.dx + dx * 1.2, n.top - 20), Paint()
        ..color = const Color(0xFF1E2126)
        ..strokeWidth = 4);
    }
    _stud(c, g.term(kM6NwNLink, rig.nLeft), rig.landed.containsValue(kM6NwNLink));
    final e = g.earthBlock(rig.nLeft);
    c.drawRRect(RRect.fromRectAndRadius(e, const Radius.circular(3)), Paint()..color = const Color(0xFF8C939A));
    // The earth sign at its end, the body's bond on the other side.
    final s = Offset(e.right - 9, e.center.dy);
    final ink = Paint()
      ..color = const Color(0xFF26303D)
      ..strokeWidth = 1.6;
    c.drawLine(s + const Offset(0, -7), s + const Offset(0, -1), ink);
    for (var k = 0; k < 3; k++) {
      final half = 6.0 - k * 2;
      c.drawLine(s + Offset(-half, -1 + k * 3.0), s + Offset(half, -1 + k * 3.0), ink);
    }
    c.drawLine(Offset(e.left + 6, e.center.dy), Offset(e.left - 14, e.center.dy + 22), Paint()
      ..color = const Color(0xFF3E8E41)
      ..strokeWidth = 3);
    _stud(c, g.term(kM6NwEarth, rig.nLeft), rig.landed.containsValue(kM6NwEarth));
  }

  /// The new cable's cores from the gland to their lugs (at rest or landed).
  void _cores(Canvas c) {
    final g = geo;
    final gl = g.gland(rig.entryLeft);
    // The gland nut and the cable's cut end.
    c.drawRect(Rect.fromCenter(center: gl, width: 22, height: 10), Paint()..color = const Color(0xFF9AA0A6));
    _label(c, 'গলি ${rig.lane}', gl + const Offset(0, 16), size: 7.5, color: const Color(0xFF15181C));
    if (!rig.doorOpen) return;
    for (var slot = 0; slot < rig.slots.length; slot++) {
      final core = rig.slots[slot];
      if (core == rig.dragging) continue;
      final t = rig.landed[core];
      final at = t == null ? g.lugHome(slot) : g.term(t, rig.nLeft);
      c.drawPath(m6NwCorePath(gl, at), Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = core == M6NwCore.armour ? 4 : 5
        ..color = core == M6NwCore.armour ? const Color(0xFF7D848B) : const Color(0xFF1E2126));
      m6NwPaintLug(c, core, at);
      if (t != null) {
        // The nut on the stud (seated or not, it looks the same).
        c.drawPath(_hex(at, 5.5), Paint()..color = const Color(0xFFD5DADF));
        c.drawCircle(at, 2, Paint()..color = const Color(0xFF59626B));
      }
    }
  }

  Path _hex(Offset at, double r) {
    final p = Path();
    for (var k = 0; k < 6; k++) {
      final a = k * math.pi / 3;
      final o = at + Offset(math.cos(a), math.sin(a)) * r;
      k == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
    }
    return p..close();
  }

  void _door(Canvas c) {
    final g = geo;
    final d = g.doorShut;
    c.drawRRect(RRect.fromRectAndRadius(d, const Radius.circular(5)),
        Paint()..shader = const LinearGradient(colors: [Color(0xFF7E9A87), Color(0xFF5E7A68)]).createShader(d));
    // The louvres.
    for (var k = 0; k < 6; k++) {
      final yy = g.y(0.36) + k * 8.0;
      c.drawLine(Offset(d.left + 40, yy), Offset(d.right - 50, yy), Paint()
        ..color = const Color(0xFF3E5446)
        ..strokeWidth = 3);
    }
    // The hot glow of a loose lug, seen through the door.
    for (final core in rig.hot) {
      final t = rig.landed[core];
      if (t == null) continue;
      final at = g.term(t, rig.nLeft);
      c.drawCircle(
          at,
          30,
          Paint()
            ..shader = const RadialGradient(colors: [Color(0xFFFFFFFF), Color(0xFFFF5A3C), Color(0x00FF2A00)], stops: [0.0, 0.4, 1.0])
                .createShader(Rect.fromCircle(center: at, radius: 30)));
    }
    // The SFU handle through the door.
    _sfu(c);
    // The hasp, and the padlock on it.
    final h = g.hasp;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: h, width: 14, height: 24), const Radius.circular(3)), Paint()..color = const Color(0xFF3A4048));
    c.drawCircle(h + const Offset(0, -5), 4, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFBFC6CC));
    if (rig.locked) {
      c.drawArc(Rect.fromCenter(center: h + const Offset(0, 1), width: 14, height: 14), math.pi, math.pi, false, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFF9AA0A6));
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: h + const Offset(0, 9), width: 18, height: 15), const Radius.circular(3)), Paint()..color = const Color(0xFFC9A227));
      c.drawCircle(h + const Offset(0, 9), 2, Paint()..color = const Color(0xFF3A3020));
    }
  }

  void _reading(Canvas c, Offset at, bool live) {
    final box = Rect.fromCenter(center: at + const Offset(0, -22), width: 44, height: 18);
    c.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(5)), Paint()..color = const Color(0xF21B232C));
    c.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(5)), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFFE8B21C));
    _label(c, live ? 'লাইভ' : '0 V', box.center, size: 8.5, color: live ? const Color(0xFFFF8A80) : const Color(0xFFE3F2E5), weight: FontWeight.w900);
  }

  @override
  bool shouldRepaint(M6NwWorldPainter old) => old.geo != geo || old.rig != rig;
}

/// A plucked dropper twangs along its whole length ([v] 0 → 1, then still);
/// its stretch behind the shroud stays hidden (the shroud is opaque).
class M6NwTwangPainter extends CustomPainter {
  const M6NwTwangPainter({required this.path, required this.v});
  final List<Offset> path;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    if (v >= 1) return;
    final amp = 5 * (1 - v);
    final wobble = math.sin(v * 40);
    final p = Path();
    for (var s = 0; s < path.length - 1; s++) {
      // Segment 1 runs behind the shroud.
      if (s == 1) continue;
      final a = path[s];
      final b = path[s + 1];
      final d = b - a;
      final len = d.distance;
      if (len < 1) continue;
      final n = Offset(-d.dy, d.dx) / len;
      const steps = 14;
      for (var k = 0; k <= steps; k++) {
        final f = k / steps;
        final o = a + d * f + n * (amp * wobble * math.sin(f * math.pi));
        if (k == 0) {
          p.moveTo(o.dx, o.dy);
        } else {
          p.lineTo(o.dx, o.dy);
        }
      }
    }
    c.drawPath(p, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeJoin = StrokeJoin.round
      ..color = Color.fromRGBO(255, 214, 160, (1 - v * 0.6).clamp(0.0, 1.0)));
  }

  @override
  bool shouldRepaint(M6NwTwangPainter old) => old.v != v || old.path != path;
}

/// A hold ring filling round [at] (the spanner on a nut, the padlock).
class M6NwRingPainter extends CustomPainter {
  M6NwRingPainter({required this.at, required this.progress}) : super(repaint: progress);
  final Offset at;
  final Animation<double> progress;

  @override
  void paint(Canvas c, Size size) {
    final v = progress.value;
    c.drawCircle(at, 22, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = const Color(0x66FFFFFF));
    c.drawArc(Rect.fromCircle(center: at, radius: 22), -math.pi / 2, v * 2 * math.pi, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFFFD34D));
    // The insulated spanner's head over the nut.
    c.drawLine(at + const Offset(6, 6), at + const Offset(30, 30), Paint()
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFD7332A));
  }

  @override
  bool shouldRepaint(M6NwRingPainter old) => old.at != at || old.progress != progress;
}

/// The lug in the hand, its core trailing from the gland.
class M6NwDragPainter extends CustomPainter {
  const M6NwDragPainter({required this.core, required this.at, required this.gland});
  final M6NwCore core;
  final Offset at;
  final Offset gland;

  @override
  void paint(Canvas c, Size size) {
    c.drawPath(m6NwCorePath(gland, at), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = core == M6NwCore.armour ? 4 : 5
      ..color = core == M6NwCore.armour ? const Color(0xFF7D848B) : const Color(0xFF1E2126));
    m6NwPaintLug(c, core, at, lifted: true);
  }

  @override
  bool shouldRepaint(M6NwDragPainter old) => old.core != core || old.at != at || old.gland != gland;
}

/// The arc flash off the busbars (the deadly freeze), in colour.
class M6NwFlashPainter extends CustomPainter {
  const M6NwFlashPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final flick = v < 0.5 ? (0.65 + 0.35 * math.sin(v * 60).abs()) : (1 - (v - 0.5) * 1.2).clamp(0.4, 1.0);
    final r = 30 + 90 * Curves.easeOut.transform(v.clamp(0.0, 1.0));
    c.drawCircle(
        at,
        r,
        Paint()
          ..shader = RadialGradient(colors: [Color.fromRGBO(255, 250, 225, 0.95 * flick), Color.fromRGBO(130, 165, 255, 0.5 * flick), const Color(0x00FFC24A)])
              .createShader(Rect.fromCircle(center: at, radius: r)));
    final spark = Paint()
      ..color = Color.fromRGBO(255, 214, 90, (1 - v).clamp(0.0, 1.0))
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 16; i++) {
      final a = i / 16 * math.pi * 2 + 0.2;
      final d0 = 10 + 56 * v;
      c.drawLine(at + Offset(math.cos(a), math.sin(a)) * d0, at + Offset(math.cos(a), math.sin(a)) * (d0 + 14), spark);
    }
    final white = (1 - v * 4).clamp(0.0, 1.0);
    if (white > 0) c.drawRect(Offset.zero & size, Paint()..color = Color.fromRGBO(255, 255, 255, 0.8 * white));
  }

  @override
  bool shouldRepaint(M6NwFlashPainter old) => old.v != v || old.at != at;
}
