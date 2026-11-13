import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The drawn world of lesson 5.9 কাজ 1 "কোর থেকে কোরে: ফল্টের ধরন"
// (m5_cable_fault_type.dart).
//
// Rounds 1–2, the cable room: a world two screens wide (720 design px). On the
// left screen (x 0–360) the substation's cable room: the panel switch (lever,
// hasp, tag hook), the open cable box with the R / Y / B lugs and the armour
// clamp (E) whose lead goes to the earth bar, the discharge rod hung on the
// bar. On the right screen (x 360–720), a pan away, the far end outdoors: the
// far-end box with its own R / Y / B lugs and the far switch. A switch that is
// ON shows ON only in its own place (no marker anywhere else).
//
// Round 3, the street: a strip of road from the substation (left) to the far
// end (right), 3 or 5 identical joint pits with their chainage marks, and —
// once a pit is opened — a close-up of the opened joint: the left section's
// three cores, the right section's three cores and the armour bond (E).
//
// The instrument in the trainee's hand (megger with a digital or a needle
// face, multimeter, discharge rod) is drawn in view coordinates by
// [M5CableMeterPainter]; the clips and leads by [M5CableLeadPainter].
// Code-drawn, gradients, no bitmaps; the only text is what a worker reads
// (ON / OFF, R Y B E, MΩ, chainage).

/// The three cores.
enum M5Core { r, y, b }

/// The two ends of the cable.
enum M5End { near, far }

/// The points a lead (or the rod) can go on.
enum M5Pt {
  nearR,
  nearY,
  nearB,
  armour,
  farR,
  farY,
  farB,
  pitLR,
  pitLY,
  pitLB,
  pitRR,
  pitRY,
  pitRB,
  pitE;

  /// The core under this point (null: the armour / earth bond).
  M5Core? get core => switch (this) {
        nearR || farR || pitLR || pitRR => M5Core.r,
        nearY || farY || pitLY || pitRY => M5Core.y,
        nearB || farB || pitLB || pitRB => M5Core.b,
        armour || pitE => null,
      };

  bool get isFar => this == farR || this == farY || this == farB;
  bool get isPit => index >= pitLR.index;

  /// In the opened pit: the left section (towards the substation).
  bool get pitLeft => this == pitLR || this == pitLY || this == pitLB;

  static const near = [nearR, nearY, nearB];
  static const far = [farR, farY, farB];
  static const pitL = [pitLR, pitLY, pitLB];
  static const pitR = [pitRR, pitRY, pitRB];
}

/// What is in the trainee's hand.
enum M5Tool { megger, multi, rod }

String m5CoreName(M5Core c) => switch (c) {
      M5Core.r => 'R',
      M5Core.y => 'Y',
      M5Core.b => 'B',
    };

const Map<M5Core, Color> m5CoreColour = {
  M5Core.r: Color(0xFFD8463B),
  M5Core.y: Color(0xFFF2C230),
  M5Core.b: Color(0xFF3A6FD8),
};

/// Where things are (design px; the cable room is 720 wide, the street 360).
@immutable
class M5CableGeo {
  const M5CableGeo._(this.height, this.groundY, this.k, this.kp);

  factory M5CableGeo.forScene(double height, double inset) {
    final g = height - floorUp - inset * 0.5;
    final mt = g - meterUp;
    // The room fits between the notebook (~196) and the meter; the street
    // and the opened pit likewise (squeezed on short screens).
    return M5CableGeo._(height, g, ((mt - 200) / 164).clamp(0.6, 1.0), ((mt - 180) / 236).clamp(0.6, 1.0));
  }

  final double height;

  /// The floor line (the meter and the trainee stand on it).
  final double groundY;

  /// Vertical squeeze on short screens (1 = the full layout): the room, the street.
  final double k;
  final double kp;

  /// The floor sits this far above the bottom (the tool row stands under it).
  static const double floorUp = 150;

  /// The instrument's top sits this far above the floor: clear of the corner
  /// guide (his bubble stays up between lines).
  static const double meterUp = 150;
  double get meterTop => groundY - meterUp;

  /// A height [d] on the room's scale (d = 166 is just above the meter;
  /// squeezed on short screens).
  double up(double d) => (meterTop - 4) - (d - 166) * k;

  /// The street and the pit: [d] above the meter.
  double pitUp(double d) => meterTop - d * kp;

  // --- the cable room (world x 0–720) ------------------------------------------
  static const double farX = 360;

  Rect switchBox(M5End e) =>
      e == M5End.near ? Rect.fromLTRB(16, up(330), 120, up(200)) : Rect.fromLTRB(farX + 240, up(330), farX + 344, up(200));
  double _switchX(M5End e) => switchBox(e).center.dx;

  Rect leverHit(M5End e) => Rect.fromCenter(center: Offset(_switchX(e), up(298)), width: 72, height: 46);
  Rect haspHit(M5End e) => Rect.fromCenter(center: Offset(_switchX(e), up(244)), width: 72, height: 38);
  Rect tagHit(M5End e) => Rect.fromCenter(center: Offset(_switchX(e), up(186)), width: 64, height: 40);

  Rect get nearBox => Rect.fromLTRB(148, up(320), 344, up(166));
  Rect get farBox => Rect.fromLTRB(farX + 16, up(320), farX + 212, up(166));
  static const nearLugX = [184.0, 246.0, 308.0];
  static const farLugX = [farX + 52, farX + 114, farX + 176];

  /// A lug's bolt (where a clip bites).
  Offset lugAt(M5Pt p) => switch (p) {
        M5Pt.nearR => Offset(nearLugX[0], up(262)),
        M5Pt.nearY => Offset(nearLugX[1], up(262)),
        M5Pt.nearB => Offset(nearLugX[2], up(262)),
        M5Pt.armour => Offset(246, up(194)),
        M5Pt.farR => Offset(farLugX[0], up(262)),
        M5Pt.farY => Offset(farLugX[1], up(262)),
        M5Pt.farB => Offset(farLugX[2], up(262)),
        M5Pt.pitLR => Offset(pitLugX[0], pitLug),
        M5Pt.pitLY => Offset(pitLugX[1], pitLug),
        M5Pt.pitLB => Offset(pitLugX[2], pitLug),
        M5Pt.pitRR => Offset(pitLugX[3], pitLug),
        M5Pt.pitRY => Offset(pitLugX[4], pitLug),
        M5Pt.pitRB => Offset(pitLugX[5], pitLug),
        M5Pt.pitE => Offset(180, pitUp(28)),
      };

  /// A point's tap area.
  Rect hit(M5Pt p) {
    final c = lugAt(p);
    if (p == M5Pt.armour) return Rect.fromCenter(center: c, width: 150, height: 36);
    if (p == M5Pt.pitE) return Rect.fromCenter(center: c, width: 96, height: math.max(28, 34 * kp));
    if (p.isPit) return Rect.fromCenter(center: c.translate(0, 8 * kp), width: 40, height: math.max(40, 58 * kp));
    return Rect.fromCenter(center: c.translate(0, -6), width: 50, height: 62);
  }

  /// The points on a cable-room screen.
  static const nearPts = [M5Pt.nearR, M5Pt.nearY, M5Pt.nearB, M5Pt.armour];
  static const farPts = [M5Pt.farR, M5Pt.farY, M5Pt.farB];
  static const pitPts = [M5Pt.pitLR, M5Pt.pitLY, M5Pt.pitLB, M5Pt.pitRR, M5Pt.pitRY, M5Pt.pitRB, M5Pt.pitE];

  /// The earth bar and the discharge rod hung on it (decoration).
  Rect get earthBar => Rect.fromLTRB(20, up(150), 122, up(136));

  /// The trainee (view coordinates), right of the meter, on the floor.
  Rect get trainee => Rect.fromLTWH(312, groundY - 104, 46, 104);

  // --- the instrument in hand (view coordinates) ---------------------------------
  Rect get meter => Rect.fromLTWH(140, meterTop, 170, 60);
  Offset get socketL => Offset(meter.left + 20, meter.top + 4);
  Offset get socketE => Offset(meter.left + 46, meter.top + 4);
  Rect get testPad => Rect.fromCenter(center: Offset(meter.right - 27, meter.center.dy), width: 50, height: 50);

  /// Where a lead drag may start (the lead sockets on top of the meter).
  Rect get leadGrab => Rect.fromLTRB(meter.left - 6, meter.top - 12, meter.left + 72, meter.bottom);

  // --- the street (round 3, 360 wide) --------------------------------------------
  double get stripTop => pitUp(236);
  double get stripBottom => pitUp(160);
  double get routeY => pitUp(198);
  double get chainY => pitUp(226);
  static const double routeL = 40;
  static const double routeR = 320;
  double pitX(int chain, int length) => routeL + (routeR - routeL) * chain / length;
  Rect pitHit(int chain, int length) => Rect.fromCenter(center: Offset(pitX(chain, length), routeY), width: 36, height: math.max(36, 44 * kp));

  /// The road on either side of the opened pit (where "this half" is tapped).
  Rect halfHit(bool left, double pitAt) => left
      ? Rect.fromLTRB(routeL - 18, stripTop, pitAt - 20, stripBottom)
      : Rect.fromLTRB(pitAt + 20, stripTop, routeR + 18, stripBottom);

  /// The opened joint, close up.
  Rect get pitPanel => Rect.fromLTRB(14, pitUp(150), 346, pitUp(4));
  double get pitLug => pitUp(100);
  static const pitLugX = [44.0, 84.0, 124.0, 236.0, 276.0, 316.0];

  @override
  bool operator ==(Object other) =>
      other is M5CableGeo && other.height == height && other.groundY == groundY && other.k == k && other.kp == kp;

  @override
  int get hashCode => Object.hash(height, groundY, k, kp);
}

/// What the cable room shows now.
@immutable
class M5CableRig {
  const M5CableRig({required this.on, required this.locked, required this.tagged, required this.cable});

  /// The ends whose switch is still ON.
  final Set<M5End> on;
  final Set<M5End> locked;
  final Set<M5End> tagged;

  /// Which cable (round 1 or 2): a different sleeve shade.
  final int cable;

  @override
  bool operator ==(Object other) =>
      other is M5CableRig && setEquals(other.on, on) && setEquals(other.locked, locked) && setEquals(other.tagged, tagged) && other.cable == cable;

  @override
  int get hashCode => Object.hash(Object.hashAllUnordered(on), Object.hashAllUnordered(locked), Object.hashAllUnordered(tagged), cable);
}

const _steel = Color(0xFF7D8790);
const _steelDark = Color(0xFF4A535C);
const _copper = Color(0xFFC77B3A);
const _ink = Color(0xFF16202C);

void _label(Canvas c, String text, Offset at, {double size = 11, Color color = Colors.white, FontWeight weight = FontWeight.w800}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: weight, color: color, height: 1)),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(c, at - Offset(tp.width / 2, tp.height / 2));
}

RRect _rr(Rect r, double rad) => RRect.fromRectAndRadius(r, Radius.circular(rad));

Paint _grad(Rect r, List<Color> colors, {bool vertical = true}) => Paint()
  ..shader = LinearGradient(
    begin: vertical ? Alignment.topCenter : Alignment.centerLeft,
    end: vertical ? Alignment.bottomCenter : Alignment.centerRight,
    colors: colors,
  ).createShader(r);

/// The cable room and the far end (720 wide, world coordinates).
class M5CableRoomPainter extends CustomPainter {
  M5CableRoomPainter({required this.geo, required this.rig});
  final M5CableGeo geo;
  final M5CableRig rig;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final g = geo.groundY;
    // --- near: the cable room ---
    final wall = Rect.fromLTRB(0, 0, 360, g);
    canvas.drawRect(wall, _grad(wall, const [Color(0xFF2C3846), Color(0xFF4A5A68), Color(0xFF5B6B78)]));
    // Window light high on the wall.
    final win = Rect.fromLTWH(196, geo.up(470).clamp(110.0, g), 120, 60);
    canvas.drawRRect(_rr(win, 4), _grad(win, const [Color(0xFF9FC4DD), Color(0xFF6E93AE)]));
    canvas.drawRRect(_rr(win, 4), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = _steelDark);
    canvas.drawLine(Offset(win.center.dx, win.top), Offset(win.center.dx, win.bottom), Paint()
      ..strokeWidth = 2
      ..color = _steelDark);
    // Cable tray along the wall.
    final tray = Rect.fromLTRB(0, geo.up(372), 360, geo.up(360));
    canvas.drawRect(tray, _grad(tray, const [Color(0xFF8C969E), Color(0xFF59626B)]));
    final floor = Rect.fromLTRB(0, g, 360, h);
    canvas.drawRect(floor, _grad(floor, const [Color(0xFF6C6A63), Color(0xFF3F3D38)]));
    // The trench the cable goes down into.
    final trench = Rect.fromLTRB(200, g - 2, 300, g + 16);
    canvas.drawRRect(_rr(trench, 3), Paint()..color = const Color(0xFF23211D));

    _switch(canvas, M5End.near);
    _box(canvas, geo.nearBox, M5CableGeo.nearLugX, armour: true);
    // The cable from the box down into the trench.
    final cab = Paint()
      ..color = const Color(0xFF1E2228)
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(246, geo.nearBox.bottom), Offset(246, g + 6), cab);
    // The earth bar, the armour's bond lead, and the discharge rod on its hook.
    final bar = geo.earthBar;
    canvas.drawRRect(_rr(bar, 3), _grad(bar, const [Color(0xFFE0A060), _copper]));
    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(Offset(bar.left + 12 + i * 19, bar.center.dy), 2.6, Paint()..color = const Color(0xFF6A3C14));
    }
    final bond = Path()
      ..moveTo(geo.lugAt(M5Pt.armour).dx - 70, geo.lugAt(M5Pt.armour).dy)
      ..quadraticBezierTo(130, geo.up(170), bar.right - 6, bar.center.dy);
    canvas.drawPath(bond, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = const Color(0xFF3E9A4A));
    canvas.drawPath(bond, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFFE6D23A));
    _rodHung(canvas, Offset(bar.left + 8, bar.top));

    // --- far: outdoors ---
    final sky = Rect.fromLTRB(360, 0, 720, g);
    canvas.drawRect(sky, _grad(sky, const [Color(0xFF6FA6D6), Color(0xFFB9D7EA), Color(0xFFE6EEDC)]));
    // Far trees and a wall.
    final tp = Paint()..color = const Color(0xFF5E8A5A);
    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(Offset(380 + i * 80.0, geo.up(372)), 34 + (i % 2) * 8, tp);
    }
    final fence = Rect.fromLTRB(360, geo.up(360), 720, g);
    canvas.drawRect(fence, _grad(fence, const [Color(0xFFBDB5A3), Color(0xFF948B78)]));
    final ground = Rect.fromLTRB(360, g, 720, h);
    canvas.drawRect(ground, _grad(ground, const [Color(0xFF7D6C52), Color(0xFF55473A)]));
    // The kiosk housing behind the far box and switch.
    final kiosk = Rect.fromLTRB(360 + 6, geo.up(344), 360 + 354, g);
    canvas.drawRRect(_rr(kiosk, 6), _grad(kiosk, const [Color(0xFF3F6B52), Color(0xFF2A4A38)]));
    _switch(canvas, M5End.far);
    _box(canvas, geo.farBox, M5CableGeo.farLugX, armour: false);
    canvas.drawLine(Offset(geo.farBox.center.dx, geo.farBox.bottom), Offset(geo.farBox.center.dx, g + 6), cab);
  }

  void _switch(Canvas canvas, M5End e) {
    final box = geo.switchBox(e);
    canvas.drawRRect(_rr(box.inflate(2), 7), Paint()..color = const Color(0x55000000));
    canvas.drawRRect(_rr(box, 6), _grad(box, const [Color(0xFF9AA3AB), Color(0xFF66707A)]));
    final on = rig.on.contains(e);
    final lever = geo.leverHit(e);
    // The lever: up = ON, down = OFF.
    final pivot = Offset(lever.center.dx, lever.center.dy + 4);
    final tip = pivot + (on ? const Offset(0, -20) : const Offset(0, 20));
    canvas.drawCircle(pivot, 8, Paint()..color = _steelDark);
    canvas.drawLine(pivot, tip, Paint()
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF26292E));
    canvas.drawCircle(tip, 6.5, Paint()..color = on ? const Color(0xFFD63A30) : const Color(0xFF2F9A4C));
    _label(canvas, 'ON', Offset(lever.left + 12, lever.top + 9), size: 9, color: on ? const Color(0xFFFFD0C8) : const Color(0xFFDCE2E6));
    _label(canvas, 'OFF', Offset(lever.left + 13, lever.bottom - 6), size: 9, color: on ? const Color(0xFFDCE2E6) : const Color(0xFFC6F5D0));
    // The hasp: a loop that a padlock closes.
    final hasp = geo.haspHit(e);
    final hp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..color = const Color(0xFF3B4148);
    canvas.drawRRect(_rr(Rect.fromCenter(center: hasp.center, width: 34, height: 16), 4), hp);
    if (rig.locked.contains(e)) {
      final body = Rect.fromCenter(center: hasp.center.translate(0, 8), width: 22, height: 18);
      canvas.drawArc(Rect.fromCenter(center: body.topCenter, width: 14, height: 16), math.pi, math.pi, false, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFFB8BEC4));
      canvas.drawRRect(_rr(body, 3), _grad(body, const [Color(0xFFE8B830), Color(0xFFB0841A)]));
    }
    if (rig.tagged.contains(e)) {
      final tag = geo.tagHit(e);
      final t = Rect.fromCenter(center: tag.center.translate(0, 4), width: 44, height: 28);
      canvas.drawLine(hasp.center.translate(0, 14), t.topCenter, Paint()
        ..strokeWidth = 1.4
        ..color = const Color(0xFF222222));
      canvas.drawRRect(_rr(t, 3), Paint()..color = const Color(0xFFD9342B));
      canvas.drawRRect(_rr(t.deflate(3), 2), Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.white);
      _label(canvas, 'DANGER', t.center, size: 8);
    }
  }

  void _box(Canvas canvas, Rect box, List<double> lugX, {required bool armour}) {
    canvas.drawRRect(_rr(box.inflate(3), 8), Paint()..color = const Color(0x66000000));
    canvas.drawRRect(_rr(box, 7), _grad(box, const [Color(0xFF5E6A74), Color(0xFF39434C)]));
    final inner = box.deflate(8);
    canvas.drawRRect(_rr(inner, 5), _grad(inner, const [Color(0xFF242B32), Color(0xFF353F48)]));
    final shade = rig.cable == 0 ? 1.0 : 0.82;
    for (var i = 0; i < 3; i++) {
      final core = M5Core.values[i];
      final x = lugX[i];
      final top = geo.up(262);
      // The core coming up from the gland, its colour sleeve, the lug.
      final from = Offset(box.center.dx + (i - 1) * 10, box.bottom - 10);
      final path = Path()
        ..moveTo(from.dx, from.dy)
        ..quadraticBezierTo(x, from.dy - 20, x, top + 20);
      canvas.drawPath(path, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..color = Color.lerp(Colors.black, m5CoreColour[core]!, shade)!);
      final lug = Rect.fromCenter(center: Offset(x, top + 6), width: 14, height: 26);
      canvas.drawRRect(_rr(lug, 3), _grad(lug, const [Color(0xFFE7A86A), _copper], vertical: false));
      canvas.drawCircle(Offset(x, top), 5, Paint()..color = const Color(0xFFB9C0C6));
      canvas.drawCircle(Offset(x, top), 2.2, Paint()..color = _steelDark);
      _label(canvas, m5CoreName(core), Offset(x, box.top + 18), size: 12, color: m5CoreColour[core]!);
    }
    if (armour) {
      final a = geo.lugAt(M5Pt.armour);
      final clamp = Rect.fromCenter(center: a, width: 120, height: 14);
      canvas.drawRRect(_rr(clamp, 4), _grad(clamp, const [Color(0xFFB9C0C6), _steel]));
      for (final dx in [-48.0, 48.0]) {
        canvas.drawCircle(a.translate(dx, 0), 3.4, Paint()..color = _steelDark);
      }
      _label(canvas, 'E', a.translate(72, 0), size: 12, color: const Color(0xFF8FE09A));
    }
  }

  void _rodHung(Canvas canvas, Offset at) {
    final p = Paint()
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(at, at.translate(0, -70 * geo.k), p..color = const Color(0xFFE2B33A));
    canvas.drawLine(at.translate(0, -70 * geo.k), at.translate(0, -96 * geo.k), p..color = const Color(0xFF8A9198));
    canvas.drawArc(Rect.fromCenter(center: at.translate(6, -98 * geo.k), width: 12, height: 10), math.pi, math.pi, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFF8A9198));
  }

  @override
  bool shouldRepaint(M5CableRoomPainter old) => old.geo != geo || old.rig != rig;
}

/// The street, its pits and (once opened) the joint close up (round 3).
class M5CableStreetPainter extends CustomPainter {
  M5CableStreetPainter({required this.geo, required this.pits, required this.length, required this.opened, required this.look});
  final M5CableGeo geo;
  final List<int> pits;
  final int length;

  /// The opened pit's index, or null.
  final int? opened;

  /// The street's dressing (0–2).
  final int look;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final sky = Rect.fromLTRB(0, 0, 360, geo.stripTop);
    canvas.drawRect(sky, _grad(sky, const [Color(0xFF79AEDB), Color(0xFFC6DDEB)]));
    // Houses along the far side of the road.
    final houses = [
      const [Color(0xFFD9B98C), Color(0xFFB8956A)],
      const [Color(0xFFB9C9D6), Color(0xFF8EA2B3)],
      const [Color(0xFFD7A9A0), Color(0xFFB2857C)],
    ];
    for (var i = 0; i < 6; i++) {
      final w = 46.0 + ((i * 7 + look * 5) % 3) * 8;
      final hh = 60.0 + ((i * 5 + look * 3) % 4) * 14;
      final r = Rect.fromLTWH(8 + i * 58.0, geo.stripTop - hh, w, hh);
      canvas.drawRect(r, _grad(r, houses[(i + look) % 3]));
      canvas.drawRect(Rect.fromLTWH(r.left + 10, r.top + 14, 12, 12), Paint()..color = const Color(0xFF51606C));
    }
    if (look == 1) {
      for (var i = 0; i < 4; i++) {
        canvas.drawCircle(Offset(40 + i * 92.0, geo.stripTop - 18), 18, Paint()..color = const Color(0xFF5B8E56));
      }
    }
    // The road strip and the footpath where the cable runs.
    final road = Rect.fromLTRB(0, geo.stripTop, 360, geo.stripBottom);
    canvas.drawRect(road, _grad(road, const [Color(0xFF9C9486), Color(0xFF7E776B)]));
    final below = Rect.fromLTRB(0, geo.stripBottom, 360, h);
    canvas.drawRect(below, _grad(below, const [Color(0xFF545A61), Color(0xFF353A40)]));
    for (var x = 6.0; x < 360; x += 34) {
      canvas.drawRect(Rect.fromLTWH(x, geo.stripBottom + 8, 18, 3), Paint()..color = const Color(0xFFD8D2C0));
    }
    // The cable route (dashed) from the substation to the far end.
    final dash = Paint()
      ..strokeWidth = 2
      ..color = const Color(0xFF4B3A26);
    for (var x = M5CableGeo.routeL; x < M5CableGeo.routeR; x += 12) {
      canvas.drawLine(Offset(x, geo.routeY), Offset(math.min(x + 7, M5CableGeo.routeR), geo.routeY), dash);
    }
    // The substation (left) and the far-end kiosk (right).
    final sub = Rect.fromLTRB(4, geo.stripTop + 6, 34, geo.stripBottom - 6);
    canvas.drawRRect(_rr(sub, 3), _grad(sub, const [Color(0xFF9AA3AB), Color(0xFF5E6870)]));
    final kiosk = Rect.fromLTRB(326, geo.stripTop + 10, 356, geo.stripBottom - 10);
    canvas.drawRRect(_rr(kiosk, 3), _grad(kiosk, const [Color(0xFF4E8063), Color(0xFF2A4A38)]));
    _label(canvas, '0 m', Offset(19, geo.chainY), size: 10, color: const Color(0xFFFFE9B0));
    _label(canvas, '$length m', Offset(336, geo.chainY), size: 10, color: const Color(0xFFFFE9B0));
    // The pits: identical lids; the chainage under each.
    for (var i = 0; i < pits.length; i++) {
      final hit = geo.pitHit(pits[i], length);
      final lid = Rect.fromCenter(center: Offset(hit.center.dx, geo.routeY), width: 26, height: 22);
      if (opened == i) {
        canvas.drawRect(lid.inflate(2), Paint()..color = const Color(0xFF1A140E));
        canvas.drawRect(lid.translate(16, -18), _grad(lid, const [Color(0xFF8E8A82), Color(0xFF5F5B54)]));
      } else {
        canvas.drawRect(lid, _grad(lid, const [Color(0xFF8E8A82), Color(0xFF5F5B54)]));
        canvas.drawRect(lid.deflate(4), Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0xFF45413B));
      }
      _label(canvas, '${pits[i]} m', Offset(hit.center.dx, geo.chainY), size: 10, color: const Color(0xFFFFE9B0));
    }
    if (opened != null) _joint(canvas);
  }

  void _joint(Canvas canvas) {
    final p = geo.pitPanel;
    canvas.drawRRect(_rr(p.inflate(3), 12), Paint()..color = const Color(0x88000000));
    canvas.drawRRect(_rr(p, 10), _grad(p, const [Color(0xFF4A3A2A), Color(0xFF2C2218)]));
    // The two cable ends coming in from the sides, the cores fanned to lugs.
    final cy = geo.pitUp(64);
    final cab = Paint()
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF1C2026);
    canvas.drawLine(Offset(p.left + 4, cy + 30), Offset(p.left + 40, cy + 30), cab);
    canvas.drawLine(Offset(p.right - 40, cy + 30), Offset(p.right - 4, cy + 30), cab);
    for (var i = 0; i < 6; i++) {
      final core = M5Core.values[i % 3];
      final x = M5CableGeo.pitLugX[i];
      final top = geo.pitLug;
      final from = i < 3 ? Offset(p.left + 40, cy + 30) : Offset(p.right - 40, cy + 30);
      final path = Path()
        ..moveTo(from.dx, from.dy)
        ..quadraticBezierTo(x, cy + 30, x, top + 20);
      canvas.drawPath(path, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..color = m5CoreColour[core]!);
      final lug = Rect.fromCenter(center: Offset(x, top + 6), width: 12, height: 22);
      canvas.drawRRect(_rr(lug, 3), _grad(lug, const [Color(0xFFE7A86A), _copper], vertical: false));
      canvas.drawCircle(Offset(x, top), 4.4, Paint()..color = const Color(0xFFB9C0C6));
      _label(canvas, m5CoreName(core), Offset(x, p.top + 14), size: 11, color: m5CoreColour[core]!);
    }
    // The gap between the sections, and the armour bond.
    canvas.drawLine(Offset(180, p.top + 12), Offset(180, geo.pitUp(46)), Paint()
      ..strokeWidth = 1.2
      ..color = const Color(0x55FFFFFF));
    final e = geo.lugAt(M5Pt.pitE);
    final bond = Rect.fromCenter(center: e, width: 84, height: 12);
    canvas.drawRRect(_rr(bond, 4), _grad(bond, const [Color(0xFFB9C0C6), _steel]));
    _label(canvas, 'E', e.translate(54, 0), size: 12, color: const Color(0xFF8FE09A));
  }

  @override
  bool shouldRepaint(M5CableStreetPainter old) =>
      old.geo != geo || !listEquals(old.pits, pits) || old.length != length || old.opened != opened || old.look != look;
}

/// The instrument in the trainee's hand (view coordinates).
class M5CableMeterPainter extends CustomPainter {
  M5CableMeterPainter({required this.geo, required this.tool, required this.needle, required this.reading, required this.low, required this.beep, this.rod = false});
  final M5CableGeo geo;

  /// The instrument drawn (the rod alone when nothing is clipped).
  final M5Tool tool;

  /// The rod is in hand as well (beside the clipped instrument).
  final bool rod;

  /// The megger's face this play: a needle dial (or digital).
  final bool needle;

  /// The reading on the face (null: none yet).
  final String? reading;

  /// The reading is low (the needle near 0).
  final bool low;

  /// The multimeter beeps.
  final bool beep;

  void _rod(Canvas canvas, Offset a, Offset b) {
      final p = Paint()
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(a, Offset.lerp(a, b, 0.62)!, p..color = const Color(0xFFE2B33A));
      canvas.drawLine(Offset.lerp(a, b, 0.62)!, b, p..color = const Color(0xFF8A9198));
      canvas.drawCircle(b, 5, Paint()..color = const Color(0xFF8A9198));
      final lead = Path()
        ..moveTo(a.dx + 30, a.dy - 10)
        ..quadraticBezierTo(a.dx - 30, a.dy + 10, a.dx - 60, a.dy - 30);
      canvas.drawPath(lead, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFF3E9A4A));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final m = geo.meter;
    if (tool == M5Tool.rod) {
      _rod(canvas, Offset(m.left + 12, m.bottom - 6), Offset(m.right - 30, m.top - 6));
      return;
    }
    if (rod) _rod(canvas, Offset(m.left - 30, m.bottom + 4), Offset(m.left + 20, m.top - 46));
    final megger = tool == M5Tool.megger;
    canvas.drawRRect(_rr(m.inflate(2), 10), Paint()..color = const Color(0x66000000));
    canvas.drawRRect(_rr(m, 9), _grad(m, megger ? const [Color(0xFFF2A23A), Color(0xFFC56E1C)] : const [Color(0xFFF2D14A), Color(0xFFC9A322)]));
    // Lead sockets: L (red), E / COM (black).
    canvas.drawCircle(geo.socketL, 6, Paint()..color = const Color(0xFFC8352C));
    canvas.drawCircle(geo.socketE, 6, Paint()..color = _ink);
    _label(canvas, megger ? 'L' : 'V/Ω', geo.socketL.translate(0, 13), size: 8, color: _ink);
    _label(canvas, megger ? 'E' : 'COM', geo.socketE.translate(0, 13), size: 8, color: _ink);
    final face = Rect.fromLTWH(m.left + 62, m.top + 6, 62, m.height - 12);
    canvas.drawRRect(_rr(face, 5), Paint()..color = const Color(0xFF1B2620));
    if (megger && needle) {
      // A needle dial over a small strip that shows the value read.
      final dial = Rect.fromLTRB(face.left + 3, face.top + 3, face.right - 3, face.bottom - 15);
      canvas.drawRRect(_rr(dial, 4), _grad(dial, const [Color(0xFFF4F0E2), Color(0xFFD8D2BE)]));
      final c = Offset(dial.center.dx, dial.bottom - 4);
      canvas.drawArc(Rect.fromCircle(center: c, radius: dial.height - 10), math.pi * 1.15, math.pi * 0.7, false, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = _ink);
      _label(canvas, '0', c + Offset.fromDirection(math.pi * 1.18, dial.height - 4), size: 7, color: _ink);
      _label(canvas, '∞', c + Offset.fromDirection(math.pi * 1.82, dial.height - 4), size: 8, color: _ink);
      final a = reading == null ? math.pi * 1.5 : (low ? math.pi * 1.18 : math.pi * 1.8);
      canvas.drawLine(c, c + Offset.fromDirection(a, dial.height - 12), Paint()
        ..strokeWidth = 1.6
        ..color = const Color(0xFFC8352C));
      _label(canvas, 'MΩ', Offset(dial.center.dx, dial.bottom - 8), size: 7, color: _ink);
      if (reading != null) _label(canvas, reading!, Offset(face.center.dx, face.bottom - 7), size: 8.5, color: const Color(0xFF9CF2A8));
    } else {
      final txt = reading ?? (megger ? '- - -' : '0.L');
      _label(canvas, txt, face.center, size: txt.length > 7 ? 9.5 : 11.5, color: const Color(0xFF9CF2A8));
      if (!megger && beep) {
        for (var i = 0; i < 3; i++) {
          canvas.drawArc(Rect.fromCircle(center: Offset(face.right + 6, face.top + 6), radius: 5.0 + i * 4), -0.7, 1.4, false, Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = Colors.white);
        }
      }
    }
    if (!megger) {
      canvas.drawCircle(Offset(m.right - 28, m.center.dy), 16, Paint()..color = const Color(0xFF2B2F35));
      canvas.drawLine(Offset(m.right - 28, m.center.dy), Offset(m.right - 36, m.center.dy - 12), Paint()
        ..strokeWidth = 3
        ..color = const Color(0xFFDDE2E6));
      _label(canvas, 'Ω', Offset(m.right - 14, m.top + 10), size: 9, color: _ink);
    }
  }

  @override
  bool shouldRepaint(M5CableMeterPainter old) =>
      old.geo != geo || old.tool != tool || old.rod != rod || old.needle != needle || old.reading != reading || old.low != low || old.beep != beep;
}

/// The leads from the meter to its clips (view coordinates; the clips are in
/// world coordinates, shifted by [shift]).
class M5CableLeadPainter extends CustomPainter {
  M5CableLeadPainter({required this.geo, required this.clipL, required this.clipE, required this.shift, this.drag});
  final M5CableGeo geo;

  /// Where the first (L / red) and the second (E / black) lead bite, world px.
  final Offset? clipL;
  final Offset? clipE;

  /// World → view (the camera).
  final double shift;

  /// A lead being dragged, world px.
  final Offset? drag;

  @override
  void paint(Canvas canvas, Size size) {
    void lead(Offset from, Offset to, Color colour) {
      final mid = Offset((from.dx + to.dx) / 2, math.max(from.dy, to.dy) + 40);
      final path = Path()
        ..moveTo(from.dx, from.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, to.dx, to.dy);
      canvas.drawPath(path, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = colour);
      // The crocodile clip.
      final r = Rect.fromCenter(center: to, width: 12, height: 18);
      canvas.drawRRect(_rr(r, 3), Paint()..color = colour);
      canvas.drawLine(r.topCenter, r.bottomCenter, Paint()
        ..strokeWidth = 1
        ..color = const Color(0x88FFFFFF));
    }

    final s = Offset(shift, 0);
    if (clipL != null) lead(geo.socketL, clipL! - s, const Color(0xFFC8352C));
    if (clipE != null) lead(geo.socketE, clipE! - s, const Color(0xFF15181C));
    final d = drag;
    if (d != null) lead(clipL == null ? geo.socketL : geo.socketE, d - s, clipL == null ? const Color(0xFFC8352C) : const Color(0xFF15181C));
  }

  @override
  bool shouldRepaint(M5CableLeadPainter old) => old.clipL != clipL || old.clipE != clipE || old.shift != shift || old.drag != drag || old.geo != geo;
}

/// The consequence on a deadly move: a flash at [at] (view px), [v] 0 → 1.
class M5CableFlashPainter extends CustomPainter {
  M5CableFlashPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas canvas, Size size) {
    final r = 20 + 120 * v;
    canvas.drawCircle(at, r, Paint()
      ..shader = RadialGradient(colors: [
        Color.fromRGBO(255, 255, 255, 0.95 * (1 - v * 0.4)),
        Color.fromRGBO(140, 200, 255, 0.7 * (1 - v * 0.5)),
        const Color(0x00508CFF),
      ]).createShader(Rect.fromCircle(center: at, radius: r)));
    final bolt = Paint()
      ..strokeWidth = 3
      ..color = const Color(0xFFE8F4FF)
      ..style = PaintingStyle.stroke;
    final rng = math.Random(7);
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3 + 0.3;
      var p = at;
      final path = Path()..moveTo(p.dx, p.dy);
      for (var j = 0; j < 4; j++) {
        p = p + Offset.fromDirection(a + (rng.nextDouble() - 0.5) * 0.9, 10 + 16 * v);
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, bolt);
    }
  }

  @override
  bool shouldRepaint(M5CableFlashPainter old) => old.v != v || old.at != at;
}
