import 'dart:math' as math;

import 'package:flutter/material.dart';

// The drawn places of the Module 8 rank gate (m8_gate_case_file.dart): ACT 1,
// one town lane at dusk-to-night as a ~1230-design-px strip panned by swipe —
// the van with the phone, the PTW book and the file clip, the DTR (its AB
// switch and HG fuses, never DO fuses, M8-19), four PCC LT poles with the
// snapped LT conductor hanging clear of the ground and the crew's cordon up
// (M8-22), six houses with their service cables, meter boxes (net meters with
// Import/Export pages, green stickers) and roofs (panels, a blue tarp, a
// tank), a tree with three branches by the span, a tea stall. ACT 2, the CGRF
// hearing room, is a static painting. All in design pixels (360 wide, [M8GGeo.h]
// high). Nothing here names a fault or marks the right act: the clues are the
// world's own (panels, stickers, meter pages); only the player's own acts
// (rods, fuses, the crew) and the restored light change what is drawn.

/// What a token can be dropped on.
enum M8GTgtKind { van, dtr, pole, house, wire, branch, trunk }

/// One drop target: a kind and its index (pole 0–3, house/wire 0–5, branch 0–2).
@immutable
class M8GTgt {
  const M8GTgt(this.kind, [this.i = 0]);
  final M8GTgtKind kind;
  final int i;

  String get key => '${kind.name}$i';

  @override
  bool operator ==(Object other) => other is M8GTgt && other.kind == kind && other.i == i;
  @override
  int get hashCode => Object.hash(kind, i);
  @override
  String toString() => key;

  static const van = M8GTgt(M8GTgtKind.van);
  static const dtr = M8GTgt(M8GTgtKind.dtr);
  static const trunk = M8GTgt(M8GTgtKind.trunk);
  static M8GTgt pole(int i) => M8GTgt(M8GTgtKind.pole, i);
  static M8GTgt house(int i) => M8GTgt(M8GTgtKind.house, i);
  static M8GTgt wire(int i) => M8GTgt(M8GTgtKind.wire, i);
  static M8GTgt branch(int i) => M8GTgt(M8GTgtKind.branch, i);

  /// Every target of the lane (22).
  static final List<M8GTgt> all = [
    van,
    dtr,
    for (var i = 0; i < 4; i++) pole(i),
    for (var i = 0; i < 6; i++) house(i),
    for (var i = 0; i < 6; i++) wire(i),
    for (var i = 0; i < 3; i++) branch(i),
    trunk,
  ];
}

/// What one house's wall and roof show (clues only; nothing marks a right act).
@immutable
class M8GHouseArt {
  const M8GHouseArt({this.panel = false, this.parapet = false, this.sticker = false, this.net = false, this.flat = false, this.deco = 0});

  /// Solar panels on the visible roof.
  final bool panel;

  /// Panels behind the parapet (seen only by the roof hold).
  final bool parapet;

  /// A green sticker on the meter box.
  final bool sticker;

  /// A net meter (Import / Export pages and an arrow) instead of an ordinary one.
  final bool net;

  /// A flat roof with a parapet (else a pitched roof).
  final bool flat;

  /// 0 nothing, 1 a blue tarp, 2 a water tank (decoys).
  final int deco;

  @override
  bool operator ==(Object other) =>
      other is M8GHouseArt && other.panel == panel && other.parapet == parapet && other.sticker == sticker && other.net == net && other.flat == flat && other.deco == deco;
  @override
  int get hashCode => Object.hash(panel, parapet, sticker, net, flat, deco);
}

/// What does not change in a play (the painter's plan).
@immutable
class M8GPlan {
  const M8GPlan({required this.houses, required this.mirror, required this.hookHouse, required this.touching, required this.c3House, required this.nHouses});
  final List<M8GHouseArt> houses;
  final bool mirror;

  /// The hooking house, or -1.
  final int hookHouse;

  /// The branch resting on the span, or -1.
  final int touching;

  /// The consumer who says his supply has not come back, or -1.
  final int c3House;
  final int nHouses;

  @override
  bool operator ==(Object other) =>
      other is M8GPlan && other.mirror == mirror && other.hookHouse == hookHouse && other.touching == touching && other.c3House == c3House && _listEq(other.houses, houses);
  @override
  int get hashCode => Object.hash(mirror, hookHouse, touching, c3House, houses.length);
}

bool _listEq<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// What the lane shows now.
@immutable
class M8GView {
  const M8GView({
    this.pan = 0,
    this.permit = false,
    this.rods = const {},
    this.fusesOut = const {},
    this.crewAt,
    this.restored = false,
    this.hookGone = false,
    this.branchCut = false,
    this.c3Says = false,
    this.lit = 1,
  });

  /// The strip's left edge (world px).
  final double pan;

  /// The permit is in: the DTR shows OFF (AB open, locked and tagged).
  final bool permit;

  /// Earth rods set (pole 0–3).
  final Set<int> rods;

  /// Service fuses pulled (house 0–5).
  final Set<int> fusesOut;

  /// The crew up a pole (0–3) or null.
  final int? crewAt;

  /// The line is back.
  final bool restored;
  final bool hookGone;
  final bool branchCut;

  /// The consumer's caption is up.
  final bool c3Says;

  /// The light-up beat (0 → 1).
  final double lit;

  @override
  bool operator ==(Object other) =>
      other is M8GView &&
      other.pan == pan &&
      other.permit == permit &&
      other.crewAt == crewAt &&
      other.restored == restored &&
      other.hookGone == hookGone &&
      other.branchCut == branchCut &&
      other.c3Says == c3Says &&
      other.lit == lit &&
      other.rods.length == rods.length &&
      other.rods.containsAll(rods) &&
      other.fusesOut.length == fusesOut.length &&
      other.fusesOut.containsAll(fusesOut);
  @override
  int get hashCode => Object.hash(pan, permit, crewAt, restored, hookGone, branchCut, c3Says, lit, rods.length, fusesOut.length);
}

/// Layout of the gate's scenes (design px; world x for the lane).
@immutable
class M8GGeo {
  const M8GGeo(this.h, this.inset, {this.mirror = false});
  final double h;
  final double inset;
  final bool mirror;

  static const worldW = 1230.0;
  static const maxPan = worldW - 360;

  // World x of each thing (unmirrored).
  static const vanX = 56.0;
  static const dtrX = 160.0;
  static const stallX = 214.0;
  static const poleX = [270.0, 430.0, 650.0, 970.0];
  static const houseX = [345.0, 730.0, 810.0, 890.0, 1050.0, 1130.0];
  static const branchX = [482.0, 530.0, 578.0];
  static const trunkX = 530.0;

  // --- the bands ---------------------------------------------------------------
  Rect get docket => const Rect.fromLTWH(8, 64, 344, 32);
  Rect get clock => const Rect.fromLTWH(272, 67, 76, 26);
  double get beltTop => h - inset - 150;
  double get panoTop => 100;
  Rect get pano => Rect.fromLTRB(0, panoTop, 360, beltTop - 4);
  double get groundY => beltTop - 26;
  double get lineY => groundY - 160;
  double get roofTop => groundY - 66;

  double mx(double x) => mirror ? worldW - x : x;

  /// A target's hit box in world px.
  Rect world(M8GTgt t) {
    final r = switch (t.kind) {
      M8GTgtKind.van => Rect.fromLTRB(vanX - 46, groundY - 74, vanX + 46, groundY + 4),
      M8GTgtKind.dtr => Rect.fromLTRB(dtrX - 44, lineY - 6, dtrX + 44, groundY + 4),
      M8GTgtKind.pole => Rect.fromLTRB(poleX[t.i] - 26, lineY - 34, poleX[t.i] + 26, lineY + 30),
      M8GTgtKind.house => Rect.fromLTRB(houseX[t.i] - 32, groundY - 66, houseX[t.i] + 32, groundY + 2),
      M8GTgtKind.wire => Rect.fromLTRB(houseX[t.i] - 32, lineY + 34, houseX[t.i] + 32, groundY - 70),
      M8GTgtKind.branch => Rect.fromLTRB(branchX[t.i] - 24, lineY - 62, branchX[t.i] + 24, lineY - 6),
      M8GTgtKind.trunk => Rect.fromLTRB(trunkX - 24, lineY + 34, trunkX + 24, groundY + 2),
    };
    return mirror ? Rect.fromLTRB(worldW - r.right, r.top, worldW - r.left, r.bottom) : r;
  }

  /// A target's box on screen (design px) at [pan].
  Rect at(M8GTgt t, double pan) => world(t).shift(Offset(-pan, 0));

  /// The pan that centres [t].
  double panFor(M8GTgt t) => (world(t).center.dx - 180).clamp(0.0, maxPan);

  /// The pan a play starts on (the van in view).
  double get startPan => mirror ? maxPan : 0;

  // --- the belt: 11 same-size tokens, 6 + 5 -------------------------------------
  Rect tok(int i) {
    const w = (344 - 5 * 4) / 6;
    final row = i < 6 ? 0 : 1;
    final col = i < 6 ? i : i - 6;
    return Rect.fromLTWH(8 + col * (w + 4), beltTop + 8 + row * 68, w, 62);
  }

  List<Rect> get tokens => [for (var i = 0; i < 11; i++) tok(i)];

  /// The "বাড়ি চলুন" chip (fixed on the strip's bottom-left).
  Rect get home => Rect.fromLTWH(8, beltTop - 34, 78, 26);

  // --- the hearing -------------------------------------------------------------
  Rect get ask => Rect.fromLTRB(10, panoTop + 4, 350, panoTop + 78);
  Rect get bench => Rect.fromLTWH(30, panoTop + 100, 300, 92);
  Rect get fan => Rect.fromLTRB(0, beltTop + 6, 360, beltTop + 112);
  static const cardW = 92.0;
  static const cardH = 84.0;
  static const cardGap = 6.0;

  /// The first [n] fan cards as laid out (design px) with the fan scrolled to 0.
  List<Rect> cards(int n) => [
        for (var i = 0; i < n; i++) Rect.fromLTWH(8 + i * (cardW + cardGap), fan.top + 8, cardW, cardH),
      ];

  @override
  bool operator ==(Object other) => other is M8GGeo && other.h == h && other.inset == inset && other.mirror == mirror;
  @override
  int get hashCode => Object.hash(h, inset, mirror);
}

// ============================================================================
// The lane
// ============================================================================

class M8GWorldPainter extends CustomPainter {
  const M8GWorldPainter({required this.geo, required this.plan, required this.view});
  final M8GGeo geo;
  final M8GPlan plan;
  final M8GView view;

  static final _pole = Paint()..color = const Color(0xFF6E6A63);
  static final _wire = Paint()
    ..color = const Color(0xFF1C2126)
    ..strokeWidth = 1.6
    ..style = PaintingStyle.stroke;

  double _x(double x) => geo.mx(x);

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    c.save();
    c.clipRect(Rect.fromLTRB(0, 0, 360, g.beltTop));
    // Dusk sky turning to night.
    c.drawRect(
      Rect.fromLTRB(0, 0, 360, g.groundY),
      Paint()
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0E1830), Color(0xFF2A3452), Color(0xFF6A5A62)])
            .createShader(Rect.fromLTRB(0, 0, 360, g.groundY)),
    );
    // Far roofs (parallax).
    final far = Paint()..color = const Color(0xFF1A2236);
    for (var i = 0; i < 22; i++) {
      final x = i * 76.0 - view.pan * 0.35;
      if (x < -80 || x > 440) continue;
      final hgt = 26.0 + (i * 37 % 30);
      c.drawRect(Rect.fromLTWH(x, g.groundY - 40 - hgt, 56, hgt + 40), far);
    }
    // Ground and the lane.
    c.drawRect(Rect.fromLTRB(0, g.groundY, 360, g.beltTop), Paint()..color = const Color(0xFF2B3322));
    c.save();
    c.translate(-view.pan, 0);
    c.drawRect(Rect.fromLTRB(0, g.groundY + 4, M8GGeo.worldW, g.groundY + 22), Paint()..color = const Color(0xFF30343A));
    final dash = Paint()..color = const Color(0xFFE8E2C4);
    for (var i = 0; i < 26; i++) {
      c.drawRect(Rect.fromLTWH(10 + i * 48.0, g.groundY + 12, 20, 2), dash);
    }
    _stall(c);
    _van(c);
    _tree(c);
    _lines(c);
    for (var i = 0; i < 4; i++) {
      _poleAt(c, _x(M8GGeo.poleX[i]), i);
    }
    _dtr(c);
    _houses(c);
    _snapped(c);
    _cordon(c);
    _rods(c);
    _crew(c);
    c.restore();
    c.restore();
  }

  void _plate(Canvas c, String text, Offset at, {double size = 8.5}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, color: const Color(0xFF1C2126))),
      textDirection: TextDirection.ltr,
    )..layout();
    final r = Rect.fromCenter(center: at, width: tp.width + 8, height: tp.height + 3);
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), Paint()..color = const Color(0xFFF2EBD8));
    tp.paint(c, Offset(r.left + 4, r.top + 1.5));
  }

  void _poleAt(Canvas c, double x, int i) {
    final g = geo;
    c.drawRect(Rect.fromLTRB(x - 4, g.lineY - 16, x + 4, g.groundY + 4), _pole);
    c.drawRect(Rect.fromLTRB(x - 22, g.lineY - 4, x + 22, g.lineY + 1), Paint()..color = const Color(0xFF4F4A42));
    final ins = Paint()..color = const Color(0xFFCBD2D8);
    for (final dx in [-18.0, -6.0, 6.0, 18.0]) {
      c.drawRect(Rect.fromLTRB(x + dx - 1.5, g.lineY - 10, x + dx + 1.5, g.lineY - 3), ins);
    }
    _plate(c, '${i + 1}', Offset(x, g.groundY - 30), size: 9);
  }

  /// The LT conductor along the lane (four wires), the broken span apart.
  void _lines(Canvas c) {
    final g = geo;
    final p = [for (final x in M8GGeo.poleX) _x(x)];
    final lo = math.min(p[1], p[2]);
    final hi = math.max(p[1], p[2]);
    for (final dy in [0.0, 5.0, 10.0, 15.0]) {
      final y = g.lineY + dy;
      c.drawLine(Offset(math.min(p[0], p[3]) - 20, y), Offset(lo, y), _wire);
      c.drawLine(Offset(hi, y), Offset(math.max(p[0], p[3]) + 40, y), _wire);
      // Pole 2 – pole 3: intact only where the conductors are not the broken one.
      if (dy != 5.0) c.drawLine(Offset(lo, y), Offset(hi, y), _wire);
    }
  }

  /// The snapped conductor: both ends hang from the poles, well clear of the ground.
  void _snapped(Canvas c) {
    final g = geo;
    final a = _x(M8GGeo.poleX[1]);
    final b = _x(M8GGeo.poleX[2]);
    final dir = b > a ? 1.0 : -1.0;
    final y = g.lineY + 5;
    final w = Paint()
      ..color = const Color(0xFF1C2126)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    c.drawPath(Path()..moveTo(a, y)..quadraticBezierTo(a + dir * 30, y + 30, a + dir * 44, y + 52), w);
    c.drawPath(Path()..moveTo(b, y)..quadraticBezierTo(b - dir * 30, y + 28, b - dir * 40, y + 46), w);
  }

  /// The crew's cordon: cones and tape under the span (M8-22).
  void _cordon(Canvas c) {
    final g = geo;
    final a = _x(M8GGeo.poleX[1]);
    final b = _x(M8GGeo.poleX[2]);
    final l = math.min(a, b) + 14;
    final r = math.max(a, b) - 14;
    final tape = Paint()
      ..color = const Color(0xFFF2B632)
      ..strokeWidth = 1.6;
    c.drawLine(Offset(l, g.groundY - 20), Offset(r, g.groundY - 20), tape);
    for (final x in [l, (l + r) / 2, r]) {
      final cone = Path()
        ..moveTo(x - 5, g.groundY)
        ..lineTo(x + 5, g.groundY)
        ..lineTo(x, g.groundY - 22)
        ..close();
      c.drawPath(cone, Paint()..color = const Color(0xFFE8602A));
    }
  }

  void _van(Canvas c) {
    final g = geo;
    final x = _x(M8GGeo.vanX);
    final body = Rect.fromLTRB(x - 42, g.groundY - 56, x + 42, g.groundY);
    c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(6)), Paint()..color = const Color(0xFFE9E5DA));
    c.drawRect(Rect.fromLTWH(x - 36, g.groundY - 48, 28, 16), Paint()..color = const Color(0xFF7FA9C9));
    c.drawCircle(Offset(x - 26, g.groundY + 2), 7, Paint()..color = const Color(0xFF22262B));
    c.drawCircle(Offset(x + 26, g.groundY + 2), 7, Paint()..color = const Color(0xFF22262B));
    _plate(c, 'WBSEDCL', Offset(x + 10, g.groundY - 36), size: 7.5);
    // The phone on the dash, the PTW book and the file clip.
    c.drawRect(Rect.fromLTWH(x + 14, g.groundY - 22, 10, 14), Paint()..color = const Color(0xFF2E353D));
    c.drawRect(Rect.fromLTWH(x + 28, g.groundY - 22, 10, 14), Paint()..color = const Color(0xFFB23A2E));
  }

  void _stall(Canvas c) {
    final g = geo;
    final x = _x(M8GGeo.stallX);
    c.drawRect(Rect.fromLTWH(x - 18, g.groundY - 34, 36, 34), Paint()..color = const Color(0xFF5B4632));
    c.drawRect(Rect.fromLTWH(x - 22, g.groundY - 42, 44, 8), Paint()..color = const Color(0xFFB56A2E));
    c.drawCircle(Offset(x + 6, g.groundY - 22), 4, Paint()..color = const Color(0xFFFFD36B));
  }

  void _tree(Canvas c) {
    final g = geo;
    final tx = _x(M8GGeo.trunkX);
    c.drawRect(Rect.fromLTRB(tx - 7, g.lineY + 40, tx + 7, g.groundY + 2), Paint()..color = const Color(0xFF4E3A28));
    final leaf = Paint()..color = const Color(0xFF2F5A34);
    for (var j = 0; j < 3; j++) {
      final bx = _x(M8GGeo.branchX[j]);
      final cut = view.branchCut && plan.touching == j;
      c.drawLine(Offset(tx, g.lineY + 44), Offset(bx, g.lineY - 20), Paint()
        ..color = const Color(0xFF4E3A28)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round);
      if (!cut) {
        c.drawCircle(Offset(bx, g.lineY - 30), 17, leaf);
        c.drawCircle(Offset(bx + (bx > tx ? 8 : -8), g.lineY - 20), 12, leaf);
      }
    }
    // The branch that rests on the span: its twigs reach the wires.
    if (plan.touching >= 0 && !view.branchCut) {
      final bx = _x(M8GGeo.branchX[plan.touching]);
      c.drawLine(Offset(bx, g.lineY - 16), Offset(bx, g.lineY + 2), Paint()
        ..color = const Color(0xFF3E4F2F)
        ..strokeWidth = 3);
    }
  }

  void _dtr(Canvas c) {
    final g = geo;
    final x = _x(M8GGeo.dtrX);
    // Double pole, the AB switch on the crossarm (blades open once the permit is in),
    // HG fuses, the tank, the LT box.
    c.drawRect(Rect.fromLTRB(x - 24, g.lineY - 16, x - 17, g.groundY + 4), _pole);
    c.drawRect(Rect.fromLTRB(x + 17, g.lineY - 16, x + 24, g.groundY + 4), _pole);
    c.drawRect(Rect.fromLTRB(x - 30, g.lineY - 4, x + 30, g.lineY + 1), Paint()..color = const Color(0xFF4F4A42));
    final blade = Paint()
      ..color = const Color(0xFFB9C0C7)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final open = view.permit;
    for (final dx in [-12.0, 0.0, 12.0]) {
      final a = Offset(x + dx - 5, g.lineY - 12);
      final b = open ? Offset(x + dx - 1, g.lineY - 24) : Offset(x + dx + 5, g.lineY - 12);
      c.drawLine(a, b, blade);
    }
    final hg = Paint()..color = const Color(0xFFCBD2D8);
    for (final dx in [-12.0, 0.0, 12.0]) {
      c.drawRect(Rect.fromLTWH(x + dx - 2, g.lineY + 6, 4, 14), hg);
    }
    final tank = Rect.fromLTRB(x - 24, g.lineY + 28, x + 24, g.groundY - 56);
    c.drawRRect(RRect.fromRectAndRadius(tank, const Radius.circular(4)), Paint()..color = const Color(0xFF7C8A7A));
    final lt = Rect.fromLTRB(x - 24, g.groundY - 48, x + 24, g.groundY - 4);
    c.drawRRect(RRect.fromRectAndRadius(lt, const Radius.circular(3)), Paint()..color = const Color(0xFF8B9299));
    _plate(c, 'DTR', Offset(x, tank.center.dy));
    if (open) {
      // The handle locked and tagged.
      c.drawRect(Rect.fromLTWH(x + 26, g.groundY - 30, 8, 5), Paint()..color = const Color(0xFFB23A2E));
      c.drawRect(Rect.fromLTWH(x + 26, g.groundY - 24, 9, 12), Paint()..color = const Color(0xFFF2B632));
    }
  }

  void _houses(Canvas c) {
    final g = geo;
    for (var i = 0; i < M8GGeo.houseX.length; i++) {
      final x = _x(M8GGeo.houseX[i]);
      final art = i < plan.houses.length ? plan.houses[i] : const M8GHouseArt();
      final body = Rect.fromLTRB(x - 30, g.roofTop + 6, x + 30, g.groundY);
      c.drawRect(body, Paint()..color = const Color(0xFF6D5A47));
      // The roof.
      if (art.flat) {
        c.drawRect(Rect.fromLTRB(x - 33, g.roofTop - 2, x + 33, g.roofTop + 8), Paint()..color = const Color(0xFF5A4A3B));
        // A low parapet; the panels behind it do not show.
      } else {
        final roof = Path()
          ..moveTo(x - 34, g.roofTop + 8)
          ..lineTo(x, g.roofTop - 14)
          ..lineTo(x + 34, g.roofTop + 8)
          ..close();
        c.drawPath(roof, Paint()..color = const Color(0xFF4A3A2C));
        if (art.panel) {
          final p = Path()
            ..moveTo(x - 24, g.roofTop + 4)
            ..lineTo(x - 2, g.roofTop - 10)
            ..lineTo(x + 4, g.roofTop - 6)
            ..lineTo(x - 18, g.roofTop + 8)
            ..close();
          c.drawPath(p, Paint()..color = const Color(0xFF274A7A));
          c.drawLine(Offset(x - 13, g.roofTop - 2), Offset(x - 7, g.roofTop + 2), Paint()
            ..color = const Color(0xFF8FB4E0)
            ..strokeWidth = 0.8);
        }
      }
      if (art.deco == 1) {
        c.drawRect(Rect.fromLTWH(x + 6, g.roofTop - (art.flat ? 8 : 6), 22, 9), Paint()..color = const Color(0xFF2F6FB5));
      } else if (art.deco == 2) {
        c.drawRect(Rect.fromLTWH(x + 8, g.roofTop - (art.flat ? 16 : 12), 16, 14), Paint()..color = const Color(0xFF3E4650));
      }
      // Every window lights once the line is back (the lane's service is one circuit).
      final lamp = view.restored ? view.lit : 0.0;
      final win = Paint()..color = Color.lerp(const Color(0xFF2A2F36), const Color(0xFFFFD36B), lamp)!;
      c.drawRect(Rect.fromLTWH(x - 22, g.roofTop + 18, 12, 14), win);
      c.drawRect(Rect.fromLTWH(x + 10, g.roofTop + 18, 12, 14), win);
      // A fan turning (drawn still) at the consumer who complains.
      if (i == plan.c3House && view.restored) {
        c.drawLine(Offset(x - 6, g.roofTop + 28), Offset(x + 6, g.roofTop + 24), Paint()
          ..color = const Color(0xFFE8E2C4)
          ..strokeWidth = 1.4);
      }
      // The meter box on the wall: ordinary, or a net meter with Import/Export.
      final mb = Rect.fromLTWH(x - 12, g.groundY - 24, art.net ? 26 : 20, 18);
      c.drawRect(mb, Paint()..color = const Color(0xFFDAD6CC));
      c.drawRect(mb, Paint()
        ..color = const Color(0xFF6F6A60)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8);
      if (art.net) {
        final tp = TextPainter(
          text: const TextSpan(text: 'Imp⇄Exp', style: TextStyle(fontSize: 5.2, fontWeight: FontWeight.w900, color: Color(0xFF1C2126))),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(c, Offset(mb.left + 1.5, mb.top + 3));
        c.drawLine(Offset(mb.left + 4, mb.bottom - 4), Offset(mb.right - 4, mb.bottom - 4), Paint()
          ..color = const Color(0xFF1C2126)
          ..strokeWidth = 0.9);
      }
      if (art.sticker) {
        c.drawRect(Rect.fromLTWH(mb.right + 2, g.groundY - 24, 9, 9), Paint()..color = const Color(0xFF3FA34D));
      }
      // The hooking house's box has a loose wire end and no meter.
      if (i == plan.hookHouse && !view.hookGone) {
        c.drawLine(Offset(mb.left + 4, mb.top + 4), Offset(mb.left + 14, mb.top + 14), Paint()
          ..color = const Color(0xFF111111)
          ..strokeWidth = 1.2);
      }
      // The service cable from the pole's clamp (the hook leaves the span a little off the pole).
      final pi = _nearPole(i);
      final px = _x(M8GGeo.poleX[pi]);
      final hook = i == plan.hookHouse;
      if (!(hook && view.hookGone)) {
        final sx = hook ? px + (x > px ? 12.0 : -12.0) : px;
        final sy = g.lineY + (hook ? 7 : 10);
        c.drawPath(
          Path()
            ..moveTo(sx, sy)
            ..quadraticBezierTo((sx + x) / 2, sy + 22, x, g.roofTop + 6),
          Paint()
            ..color = const Color(0xFF111111)
            ..strokeWidth = 1.8
            ..style = PaintingStyle.stroke,
        );
      }
      if (view.fusesOut.contains(i)) {
        // The pulled fuse hanging at the pole.
        c.drawRect(Rect.fromLTWH(px + 6, g.lineY + 34 + i * 3.0, 4, 12), Paint()..color = const Color(0xFFE0A21B));
      }
      // The consumer who says the supply has not come (a silent figure).
      if (i == plan.c3House && view.c3Says) {
        c.drawCircle(Offset(x + 40, g.groundY - 30), 5, Paint()..color = const Color(0xFFD8B48C));
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x + 40, g.groundY - 14), width: 12, height: 22), const Radius.circular(3)), Paint()..color = const Color(0xFF8C5A3C));
      }
    }
  }

  int _nearPole(int house) {
    final x = M8GGeo.houseX[house];
    var best = 0;
    for (var i = 1; i < 4; i++) {
      if ((M8GGeo.poleX[i] - x).abs() < (M8GGeo.poleX[best] - x).abs()) best = i;
    }
    return best;
  }

  void _rods(Canvas c) {
    final g = geo;
    final p = Paint()
      ..color = const Color(0xFF3FA34D)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    for (final i in view.rods) {
      final x = _x(M8GGeo.poleX[i]);
      for (final dx in [-6.0, 0.0, 6.0]) {
        c.drawLine(Offset(x + dx, g.lineY + 3 + dx.abs() / 3), Offset(x + 12, g.groundY - 2), p);
      }
      c.drawRect(Rect.fromLTWH(x + 8, g.groundY - 6, 10, 6), Paint()..color = const Color(0xFF3FA34D));
    }
  }

  void _crew(Canvas c) {
    final i = view.crewAt;
    if (i == null) return;
    final g = geo;
    final x = _x(M8GGeo.poleX[i]) + 8;
    final y = g.lineY + 24;
    c.drawCircle(Offset(x, y - 14), 5, Paint()..color = Colors.white);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, y), width: 12, height: 18), const Radius.circular(3)), Paint()..color = const Color(0xFFF2B632));
  }

  @override
  bool shouldRepaint(M8GWorldPainter old) => old.geo != geo || old.plan != plan || old.view != view;
}

// ============================================================================
// The hearing room
// ============================================================================

/// ACT 2: the CGRF bench. Static; drawn once per size.
class M8GHearPainter extends CustomPainter {
  const M8GHearPainter({required this.geo, this.consumers = 1});
  final M8GGeo geo;
  final int consumers;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    c.save();
    c.clipRect(Rect.fromLTRB(0, 0, 360, g.beltTop));
    c.drawRect(
      Rect.fromLTRB(0, 0, 360, g.beltTop),
      Paint()
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3A3328), Color(0xFF574A38)])
            .createShader(Rect.fromLTRB(0, 0, 360, g.beltTop)),
    );
    // The wall board and the bench.
    c.drawRect(Rect.fromLTWH(20, g.panoTop + 84, 320, 14), Paint()..color = const Color(0xFF2E2418));
    final coats = [const Color(0xFF3B4A66), const Color(0xFF3B4A66), const Color(0xFF8A5A2E), const Color(0xFF3B4A66)];
    for (var i = 0; i < 4; i++) {
      final x = 66.0 + i * 76;
      c.drawCircle(Offset(x, g.panoTop + 62), 8, Paint()..color = const Color(0xFFD8B48C));
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 13, g.panoTop + 70, 26, 20), const Radius.circular(4)), Paint()..color = coats[i]);
    }
    // The bench table (the drop place) and the consumer's seat.
    c.drawRRect(
      RRect.fromRectAndRadius(g.bench, const Radius.circular(8)),
      Paint()..color = const Color(0xFF6B4E2E),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(g.bench.deflate(5), const Radius.circular(6)),
      Paint()
        ..color = const Color(0xFFB08A4A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    for (var i = 0; i < consumers; i++) {
      final x = 270.0 + i * 0;
      c.drawCircle(Offset(x, g.bench.bottom + 26), 7, Paint()..color = const Color(0xFFD8B48C));
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 11, g.bench.bottom + 33, 22, 20), const Radius.circular(4)), Paint()..color = const Color(0xFF8C5A3C));
    }
    c.restore();
  }

  @override
  bool shouldRepaint(M8GHearPainter old) => old.geo != geo || old.consumers != consumers;
}

/// A deadly move plays out in colour over the frozen scene (0 → 1).
class M8GHarmPainter extends CustomPainter {
  const M8GHarmPainter({required this.at, required this.k});
  final Offset at;
  final double k;

  @override
  void paint(Canvas c, Size size) {
    if (k <= 0) return;
    final r = 18 + 140 * Curves.easeOut.transform(k.clamp(0.0, 1.0));
    c.drawCircle(
      at,
      r,
      Paint()
        ..shader = RadialGradient(colors: [
          Colors.white.withValues(alpha: (1 - k) * 0.95),
          const Color(0xFFFFE066).withValues(alpha: (1 - k) * 0.8),
          const Color(0x00FF8A00),
        ]).createShader(Rect.fromCircle(center: at, radius: r)),
    );
    final bolt = Paint()
      ..color = const Color(0xFFFFF59D).withValues(alpha: (1 - k).clamp(0.0, 1.0))
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(at.dx, at.dy - 60);
    for (var i = 1; i <= 5; i++) {
      path.lineTo(at.dx + (i.isOdd ? 12 : -12), at.dy - 60 + i * 12);
    }
    c.drawPath(path, bolt);
  }

  @override
  bool shouldRepaint(M8GHarmPainter old) => old.k != k || old.at != at;
}
