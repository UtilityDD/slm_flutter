import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart' show banglaFont;

// The drawn world of lesson 7.5 কাজ 1 "তারের পিছু পিছু" (m7_theft_trace.dart).
//
// Lanes (rounds 1 and 2): an evening lane one screen wide. An LT line runs
// across the top from a pole on one side to the lane's DTR on the other (the
// DTR on its pole with its AB switch and HG fuses, ruling M7-9 — never a DO).
// The line is bare conductors or an AB cable (dealt per lane). Four or five
// service wires drop from the line to three or four houses, crossing each
// other; a leafy branch and a shop sign hide parts of them. Every wire is
// drawn the same — the same colour, the same small fitting where it leaves
// the line (a clamp, or a hook of the same size), old tape patches on legal
// wires as well. Legal service wires end on a meter board on the house wall;
// a hook wire goes into the wall with no meter; an upstream joint sends a
// short second wire into the wall before the meter; a meter loop jumps
// round the meter on its board.
//
// The meter close-up (round 3): one house's meter board for a meter-change
// job. The service cable comes down, into the meter's IN terminal, out of its
// OUT terminal and down into the wall pipe — or, on a bypass, a jumper under
// the terminal block carries the supply past the meter while the terminal
// stubs still look connected.
//
// Text in the art: only what a worker reads — the shop sign, the house
// numbers on the walls. Code-drawn, gradients, no bitmaps.
//
// Design: 360 wide × the scene's height (SceneMetrics); no camera.

/// The scene's width in design px.
const double kM7TtViewW = 360;

/// The line's conductor in a lane.
enum M7TtCond { bare, ab }

/// What a lane wire really is.
enum M7TtWireKind { legal, hook, upstream, loop }

/// The meter close-up's case.
enum M7TtMeterCase { intact, sealCut, magnet, bypass }

/// A point the notebook sketch shows (a pin can land on any of them).
enum M7TtSpot {
  /// Where a wire leaves the line: a proper clamp, or a hook.
  clamp,
  hook,

  /// The middle of a wire: plain, an old tape patch, or a joint sending a
  /// second wire into the house before the meter.
  plain,
  patch,
  joint,

  /// The wire's meter board: the meter, or the meter with a loop round it.
  meter,
  meterLoop,

  /// Into the house.
  house,

  /// The close-up: the cable, its seal, the meter's body (clean, a paper
  /// sticker, or a magnet), a jumper past the meter.
  cable,
  seal,
  sealCut,
  body,
  sticker,
  magnet,
  jumper,
}

/// One service wire of a lane.
@immutable
class M7TtWire {
  const M7TtWire({
    required this.id,
    required this.house,
    required this.kind,
    required this.patched,
    required this.rootX,
    required this.j1,
    required this.j2,
    required this.side,
  });

  final int id;

  /// The house slot (0–3, left to right) it ends at.
  final int house;
  final M7TtWireKind kind;

  /// An old tape patch half way (legal wires too).
  final bool patched;

  /// Where it leaves the line (design px).
  final double rootX;

  /// The bends of its run (design px, sideways).
  final double j1;
  final double j2;

  /// Which side of the house it ends on (−1 left, +1 right).
  final double side;
}

/// One lane: the conductor, the houses and their wires, the hiding places.
@immutable
class M7TtLane {
  const M7TtLane({
    required this.cond,
    required this.houses,
    required this.wires,
    required this.branchX,
    required this.signX,
    required this.dtrRight,
  });

  final M7TtCond cond;

  /// House slots in use (sorted).
  final List<int> houses;
  final List<M7TtWire> wires;

  /// The leafy branch and the shop sign (design px x; the middle band).
  final double branchX;
  final double signX;

  /// The DTR stands at the right end (else the left).
  final bool dtrRight;

  M7TtWire wire(int id) => wires.firstWhere((w) => w.id == id);
}

/// The meter close-up of round 3.
@immutable
class M7TtMeter {
  const M7TtMeter({required this.kase, required this.patched, required this.sticker, required this.houseNo});
  final M7TtMeterCase kase;

  /// An old tape patch on the incoming cable.
  final bool patched;

  /// A paper sticker on the meter's body (where a magnet would sit).
  final bool sticker;

  /// The number painted on the wall.
  final int houseNo;
}

/// The points a lane wire's notebook sketch shows, along the wire.
List<M7TtSpot> m7TtWireSpots(M7TtWire w) => switch (w.kind) {
      M7TtWireKind.legal => [M7TtSpot.clamp, w.patched ? M7TtSpot.patch : M7TtSpot.plain, M7TtSpot.meter, M7TtSpot.house],
      M7TtWireKind.hook => [M7TtSpot.hook, w.patched ? M7TtSpot.patch : M7TtSpot.plain, M7TtSpot.house],
      M7TtWireKind.upstream => [M7TtSpot.clamp, if (w.patched) M7TtSpot.patch, M7TtSpot.joint, M7TtSpot.meter, M7TtSpot.house],
      M7TtWireKind.loop => [M7TtSpot.clamp, w.patched ? M7TtSpot.patch : M7TtSpot.plain, M7TtSpot.meterLoop, M7TtSpot.house],
    };

/// The points of the close-up's sketch: in, seal, body, (jumper), out.
List<M7TtSpot> m7TtMeterSpots(M7TtMeter m) => [
      m.patched ? M7TtSpot.patch : M7TtSpot.cable,
      m.kase == M7TtMeterCase.sealCut ? M7TtSpot.sealCut : M7TtSpot.seal,
      m.kase == M7TtMeterCase.magnet ? M7TtSpot.magnet : (m.sticker ? M7TtSpot.sticker : M7TtSpot.body),
      if (m.kase == M7TtMeterCase.bypass) M7TtSpot.jumper,
      M7TtSpot.cable,
    ];

/// The theft spots (a pin there is right on its wire or meter).
const kM7TtTheftSpots = {M7TtSpot.hook, M7TtSpot.joint, M7TtSpot.meterLoop, M7TtSpot.sealCut, M7TtSpot.magnet, M7TtSpot.jumper};

/// Where things are (design px).
@immutable
class M7TtGeo {
  const M7TtGeo._(this.height, this.groundY);

  factory M7TtGeo.forScene(double height, double inset) => M7TtGeo._(height, height - groundUp - inset * 0.5);

  final double height;

  /// The lane's ground (house feet).
  final double groundY;

  /// The ground sits this far above the bottom.
  static const double groundUp = 112;

  /// The house slots' centres and the house width.
  static const houseXs = [52.0, 136.0, 220.0, 304.0];
  static const double houseW = 74;

  /// The root slots on the line.
  static const rootXs = [62.0, 104.0, 146.0, 188.0, 230.0, 272.0];

  double get lineY => math.max(150.0, height * 0.27);
  double get wallTop => height * 0.53;
  double get meterY => wallTop + 34;

  /// The middle band where the branch and the sign hang.
  double get bandY => lineY + (wallTop - lineY) * 0.5;

  /// A wire's root on the line.
  Offset root(M7TtWire w) => Offset(w.rootX, lineY + 3);

  /// A house's meter board (on its wall, on the wire's side).
  Rect meterBoard(int house, double side) => Rect.fromCenter(center: Offset(houseXs[house] + side * 16, meterY), width: 20, height: 26);

  /// The wall entry of a wire with no meter (a hook wire, an upstream stub).
  Offset wallEntry(int house, double side) => Offset(houseXs[house] + side * 26, wallTop + 12);

  /// Where a lane wire ends.
  Offset end(M7TtWire w) => w.kind == M7TtWireKind.hook ? wallEntry(w.house, w.side) : meterBoard(w.house, w.side).topCenter;

  /// A lane wire's run: a cubic curve from the root to its end, sampled.
  List<Offset> wirePoints(M7TtWire w) {
    final a = root(w);
    final e = end(w);
    final c1 = Offset(a.dx + (e.dx - a.dx) * 0.25 + w.j1, a.dy + (e.dy - a.dy) * 0.38);
    final c2 = Offset(a.dx + (e.dx - a.dx) * 0.75 + w.j2, a.dy + (e.dy - a.dy) * 0.74);
    return [
      for (var k = 0; k <= kSamples; k++) _bez(a, c1, c2, e, k / kSamples),
    ];
  }

  static const int kSamples = 40;

  static Offset _bez(Offset a, Offset b, Offset c, Offset d, double t) {
    final u = 1 - t;
    return a * (u * u * u) + b * (3 * u * u * t) + c * (3 * u * t * t) + d * (t * t * t);
  }

  /// A point [t] (0…1) of the way along a lane wire.
  Offset along(M7TtWire w, double t) {
    final pts = wirePoints(w);
    final f = (t.clamp(0.0, 1.0)) * kSamples;
    final i = f.floor().clamp(0, kSamples - 1);
    return Offset.lerp(pts[i], pts[i + 1], f - i)!;
  }

  /// The patch and the joint sit here along a wire.
  static const double patchT = 0.5;
  static const double jointT = 0.8;

  /// Where the red pin shows on the scene for a lane wire's theft.
  Offset theftAt(M7TtWire w) => switch (w.kind) {
        M7TtWireKind.hook => root(w),
        M7TtWireKind.upstream => along(w, jointT),
        M7TtWireKind.loop => meterBoard(w.house, w.side).center,
        M7TtWireKind.legal => end(w),
      };

  /// The branch and the sign (they hide parts of the wires).
  Offset branch(M7TtLane l) => Offset(l.branchX, bandY - 6);
  Rect sign(M7TtLane l) => Rect.fromCenter(center: Offset(l.signX, bandY + 20), width: 78, height: 24);

  /// The trainee (below, with his notebook).
  Rect trainee() => Rect.fromLTWH(160, groundY - 98, 40, 98);

  // --- the meter close-up --------------------------------------------------
  Rect get board => Rect.fromCenter(center: Offset(180, height * 0.5), width: 176, height: math.min(250.0, height * 0.34));
  Rect get meterBody => Rect.fromLTWH(board.left + 40, board.top + 18, 96, board.height * 0.52);
  double get termY => meterBody.bottom + 12;
  Offset get meterIn => Offset(meterBody.left + 22, termY);
  Offset get meterOut => Offset(meterBody.right - 22, termY);
  Offset get cableStart => Offset(board.left + 12, math.max(150.0, board.top - 70));
  double get underY => termY + 34;
  Offset get pipe => Offset(meterOut.dx + 30, math.min(groundY - 10, board.bottom + 26));

  /// The supply's path on the close-up (the trace follows it).
  List<Offset> meterPoints(M7TtMeter m) {
    final s = cableStart;
    final bend = Offset(s.dx, underY);
    final pts = <Offset>[s, Offset(s.dx, board.top + board.height * 0.3), bend];
    if (m.kase == M7TtMeterCase.bypass) {
      pts.addAll([
        Offset(meterIn.dx - 6, underY + 26),
        Offset(meterOut.dx + 6, underY + 26),
        Offset(pipe.dx, underY),
      ]);
    } else {
      pts.addAll([
        Offset(meterIn.dx, underY),
        meterIn,
        meterOut,
        Offset(meterOut.dx, underY),
        Offset(pipe.dx, underY),
      ]);
    }
    pts.add(pipe);
    return _densify(pts, 6);
  }

  static List<Offset> _densify(List<Offset> pts, double step) {
    final out = <Offset>[pts.first];
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1];
      final b = pts[i];
      final n = math.max(1, ((b - a).distance / step).ceil());
      for (var k = 1; k <= n; k++) {
        out.add(Offset.lerp(a, b, k / n)!);
      }
    }
    return out;
  }

  Offset get sealAt => Offset(meterBody.center.dx, termY + 3);
  Offset get bodyAt => Offset(meterBody.center.dx, meterBody.top + meterBody.height * 0.68);
  Offset get patchAt => Offset(cableStart.dx, board.top + board.height * 0.18);
  Offset get jumperAt => Offset(meterBody.center.dx, underY + 26);

  /// Where the red pin shows on the close-up.
  Offset meterTheftAt(M7TtMeter m) => switch (m.kase) {
        M7TtMeterCase.sealCut => sealAt,
        M7TtMeterCase.magnet => bodyAt,
        M7TtMeterCase.bypass => jumperAt,
        M7TtMeterCase.intact => sealAt,
      };

  // --- the notebook and the report (widgets on the scene) -------------------
  Rect get notebook => Rect.fromLTWH(14, math.max(146.0, height * 0.31), 332, 218);
  Rect get report => Rect.fromLTWH(22, math.max(146.0, height * 0.28), 316, 262);

  @override
  bool operator ==(Object other) => other is M7TtGeo && other.height == height && other.groundY == groundY;

  @override
  int get hashCode => Object.hash(height, groundY);
}

/// The notebook's sketch layout (local px of the notebook).
abstract final class M7TtSketch {
  static const double y = 92;
  static const double left = 40;
  static const double right = 292;
  static const Offset pinHome = Offset(44, 178);
  /// 48 px tall: the scene is 360 px wide, so ≥ 48 dp on any phone.
  static const Rect okBox = Rect.fromLTWH(186, 154, 132, 48);
  static const double reach = 30;

  /// Station [i] of [n].
  static Offset station(int i, int n) => Offset(left + (right - left) * (n == 1 ? 0.5 : i / (n - 1)), y);
}

/// On a bypass the meter's own points hang off the supply's line.
bool m7TtOffLine(List<M7TtSpot> sp, int i) =>
    sp.contains(M7TtSpot.jumper) && const {M7TtSpot.seal, M7TtSpot.sealCut, M7TtSpot.body, M7TtSpot.sticker, M7TtSpot.magnet}.contains(sp[i]);

/// Point [i]'s place in the notebook (local px).
Offset m7TtStationAt(List<M7TtSpot> sp, int i) => M7TtSketch.station(i, sp.length) + (m7TtOffLine(sp, i) ? const Offset(0, -34) : Offset.zero);

// ============================================================================
// Painters
// ============================================================================

const _wireCol = Color(0xFF23262B);

/// The still lane: dusk sky, far roofs, the line, its pole and DTR, the
/// houses with their meter boards, every wire, the branch and the sign.
class M7TtLanePainter extends CustomPainter {
  M7TtLanePainter({required this.geo, required this.lane});
  final M7TtGeo geo;
  final M7TtLane lane;

  @override
  void paint(Canvas c, Size size) {
    final h = geo.height;
    final g = geo.groundY;
    final sky = Rect.fromLTWH(0, 0, kM7TtViewW, g);
    c.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2E3A66), Color(0xFF8D6A8E), Color(0xFFF2A65E)],
          stops: [0, 0.55, 1],
        ).createShader(sky),
    );
    // Far roofs.
    final far = Paint()..color = const Color(0xFF5B4B66);
    final farPath = Path()..moveTo(0, geo.wallTop - 20);
    for (var x = 0.0; x <= kM7TtViewW; x += 40) {
      final up = 30 + 18 * math.sin(x / 37);
      farPath
        ..lineTo(x, geo.wallTop - up)
        ..lineTo(x + 32, geo.wallTop - up)
        ..lineTo(x + 40, geo.wallTop - 20);
    }
    farPath
      ..lineTo(kM7TtViewW, g)
      ..lineTo(0, g)
      ..close();
    c.drawPath(farPath, far);
    // The lane.
    final ground = Rect.fromLTWH(0, g, kM7TtViewW, h - g);
    c.drawRect(
      ground,
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF7A6A58), Color(0xFF4E4236)]).createShader(ground),
    );
    _poleAndDtr(c);
    for (final s in lane.houses) {
      _house(c, s);
    }
    _line(c);
    for (final w in lane.wires) {
      _wire(c, w);
    }
    _branch(c);
    _sign(c);
  }

  void _poleAndDtr(Canvas c) {
    final poleX = lane.dtrRight ? 16.0 : kM7TtViewW - 16;
    final dtrX = lane.dtrRight ? kM7TtViewW - 22.0 : 22.0;
    final pole = Paint()
      ..shader = const LinearGradient(colors: [Color(0xFF8E8A82), Color(0xFFB9B4AA), Color(0xFF6B675F)]).createShader(Rect.fromLTWH(poleX - 4, geo.lineY - 20, 8, geo.groundY - geo.lineY + 20));
    c.drawRect(Rect.fromLTRB(poleX - 3.5, geo.lineY - 18, poleX + 3.5, geo.groundY + 2), pole);
    c.drawRect(Rect.fromLTRB(dtrX - 4, geo.lineY - 70, dtrX + 4, geo.groundY + 2), pole);
    // The DTR on its pole, below the line.
    final tank = Rect.fromCenter(center: Offset(dtrX, geo.lineY + 44), width: 30, height: 38);
    c.drawRRect(
      RRect.fromRectAndRadius(tank, const Radius.circular(4)),
      Paint()..shader = const LinearGradient(colors: [Color(0xFF7D8C80), Color(0xFF4F5C53)]).createShader(tank),
    );
    for (var k = 0; k < 4; k++) {
      c.drawLine(Offset(tank.left + 4, tank.top + 7 + k * 8), Offset(tank.right - 4, tank.top + 7 + k * 8), Paint()
        ..color = const Color(0x553A443D)
        ..strokeWidth = 1.2);
    }
    // The HG fuses (a horn pair per phase) above the line.
    final horn = Paint()
      ..color = const Color(0xFF9AA0A6)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    for (var k = -1; k <= 1; k++) {
      final x = dtrX + k * 9.0;
      final y = geo.lineY - 34;
      c.drawLine(Offset(x - 3, y), Offset(x - 5, y - 9), horn);
      c.drawLine(Offset(x + 3, y), Offset(x + 5, y - 9), horn);
      c.drawRect(Rect.fromCenter(center: Offset(x, y + 4), width: 4, height: 7), Paint()..color = const Color(0xFF9A5A3A));
    }
    // The AB switch higher up: three blades and the operating rod.
    final ab = Paint()
      ..color = const Color(0xFF6E737A)
      ..strokeWidth = 2;
    final abY = geo.lineY - 60;
    c.drawLine(Offset(dtrX - 14, abY), Offset(dtrX + 14, abY), ab..strokeWidth = 3);
    for (var k = -1; k <= 1; k++) {
      c.drawLine(Offset(dtrX + k * 9.0 - 3, abY - 2), Offset(dtrX + k * 9.0 + 3, abY - 8), ab..strokeWidth = 2);
    }
    c.drawLine(Offset(dtrX + (lane.dtrRight ? -6 : 6), abY), Offset(dtrX + (lane.dtrRight ? -6 : 6), geo.groundY - 30), Paint()
      ..color = const Color(0xFF55595E)
      ..strokeWidth = 1.2);
  }

  void _house(Canvas c, int s) {
    final x = M7TtGeo.houseXs[s];
    final w = M7TtGeo.houseW;
    final top = geo.wallTop;
    final g = geo.groundY;
    final wall = Rect.fromLTRB(x - w / 2, top, x + w / 2, g);
    const walls = [Color(0xFFE2C9A0), Color(0xFFCFB8D6), Color(0xFFB8D0C4), Color(0xFFE8B9A0)];
    c.drawRect(wall, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [walls[s], Color.lerp(walls[s], const Color(0xFF3A3040), 0.35)!]).createShader(wall));
    // A flat roof parapet and a lit window and a door.
    c.drawRect(Rect.fromLTRB(wall.left - 3, top - 6, wall.right + 3, top), Paint()..color = const Color(0xFF8E7E70));
    final win = Rect.fromCenter(center: Offset(x - 14, top + 66), width: 18, height: 16);
    c.drawRect(win, Paint()..color = const Color(0xFFFFD27A));
    c.drawLine(win.topCenter, win.bottomCenter, Paint()
      ..color = const Color(0xFF6A5040)
      ..strokeWidth = 1.2);
    final door = Rect.fromLTWH(x + 6, g - 40, 18, 40);
    c.drawRect(door, Paint()..color = const Color(0xFF6A4A36));
    // The house number.
    final plate = Rect.fromCenter(center: Offset(x - 14, top + 92), width: 16, height: 10);
    c.drawRect(plate, Paint()..color = const Color(0xFFF7F1DE));
    _text(c, '${s + 1}', plate.center, 7.5, const Color(0xFF2A2018), bold: true);
  }

  void _line(Canvas c) {
    final y = geo.lineY;
    if (lane.cond == M7TtCond.ab) {
      // One thick twisted bundle.
      c.drawLine(Offset(0, y), Offset(kM7TtViewW, y), Paint()
        ..color = const Color(0xFF15171A)
        ..strokeWidth = 5.5);
      final twist = Paint()
        ..color = const Color(0xFF3A3E44)
        ..strokeWidth = 1.2;
      for (var x = 4.0; x < kM7TtViewW; x += 9) {
        c.drawLine(Offset(x, y - 2.5), Offset(x + 5, y + 2.5), twist);
      }
    } else {
      // Bare conductors on the pole's arm (three phases and the neutral).
      final p = Paint()
        ..color = const Color(0xFF8A8F96)
        ..strokeWidth = 1.4;
      for (final dy in const [-7.0, -2.5, 2.0, 6.5]) {
        c.drawLine(Offset(0, y + dy), Offset(kM7TtViewW, y + dy), p);
      }
    }
  }

  void _wire(Canvas c, M7TtWire w) {
    final pts = geo.wirePoints(w);
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final q in pts.skip(1)) {
      path.lineTo(q.dx, q.dy);
    }
    c.drawPath(path, Paint()
      ..color = _wireCol
      ..strokeWidth = 1.9
      ..style = PaintingStyle.stroke);
    // The fitting where it leaves the line: a small clamp, or a hook of the
    // same size and colour.
    final r = geo.root(w);
    final fit = Paint()..color = const Color(0xFF3B3F45);
    if (w.kind == M7TtWireKind.hook) {
      final hook = Path()
        ..moveTo(r.dx - 3, r.dy + 3)
        ..lineTo(r.dx - 3, r.dy - 6)
        ..quadraticBezierTo(r.dx + 1, r.dy - 10, r.dx + 4, r.dy - 5);
      c.drawPath(hook, Paint()
        ..color = const Color(0xFF3B3F45)
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke);
    } else {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: r.translate(0, -1), width: 7, height: 8), const Radius.circular(1.5)), fit);
    }
    if (w.patched) {
      final p = geo.along(w, M7TtGeo.patchT);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: p, width: 7, height: 6), const Radius.circular(2)), Paint()..color = const Color(0xFF101112));
    }
    switch (w.kind) {
      case M7TtWireKind.upstream:
        final j = geo.along(w, M7TtGeo.jointT);
        final entry = geo.wallEntry(w.house, -w.side);
        c.drawLine(j, entry, Paint()
          ..color = _wireCol
          ..strokeWidth = 1.6);
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: j, width: 7, height: 6), const Radius.circular(2)), Paint()..color = const Color(0xFF101112));
        _entry(c, entry);
        _meter(c, w, loop: false);
      case M7TtWireKind.loop:
        _meter(c, w, loop: true);
      case M7TtWireKind.legal:
        _meter(c, w, loop: false);
      case M7TtWireKind.hook:
        _entry(c, geo.end(w));
    }
  }

  void _entry(Canvas c, Offset p) {
    c.drawCircle(p, 2.6, Paint()..color = const Color(0xFF2A2420));
  }

  void _meter(Canvas c, M7TtWire w, {required bool loop}) {
    final b = geo.meterBoard(w.house, w.side);
    c.drawRect(b, Paint()..color = const Color(0xFFDCD6C8));
    c.drawRect(b, Paint()
      ..color = const Color(0xFF6A6458)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);
    final m = Rect.fromCenter(center: b.center.translate(0, -2), width: 12, height: 14);
    c.drawRRect(RRect.fromRectAndRadius(m, const Radius.circular(2)), Paint()..color = const Color(0xFF3E4650));
    c.drawRect(Rect.fromCenter(center: m.center.translate(0, -2), width: 8, height: 4), Paint()..color = const Color(0xFF9FD3A8));
    c.drawLine(b.bottomCenter, b.bottomCenter.translate(0, 8), Paint()
      ..color = _wireCol
      ..strokeWidth = 1.6);
    if (loop) {
      final lp = Path()
        ..moveTo(b.topCenter.dx - 2, b.top + 1)
        ..cubicTo(b.left - 9, b.top - 2, b.left - 9, b.bottom + 4, b.bottomCenter.dx - 2, b.bottom + 3);
      c.drawPath(lp, Paint()
        ..color = _wireCol
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke);
    }
  }

  void _branch(Canvas c) {
    final o = geo.branch(lane);
    final trunkX = o.dx < kM7TtViewW / 2 ? -10.0 : kM7TtViewW + 10;
    c.drawLine(Offset(trunkX, o.dy + 30), o, Paint()
      ..color = const Color(0xFF4A3424)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round);
    final leaf = Paint()..color = const Color(0xF0355C34);
    final leaf2 = Paint()..color = const Color(0xF0477A40);
    for (final (dx, dy, r) in const [(-20.0, 4.0, 18.0), (0.0, -8.0, 22.0), (20.0, 2.0, 18.0), (-6.0, 14.0, 16.0), (12.0, 16.0, 14.0)]) {
      c.drawCircle(o.translate(dx, dy), r, leaf);
      c.drawCircle(o.translate(dx - 4, dy - 4), r * 0.55, leaf2);
    }
  }

  void _sign(Canvas c) {
    final r = geo.sign(lane);
    c.drawLine(r.topLeft.translate(8, 0), r.topLeft.translate(8, -18), Paint()
      ..color = const Color(0xFF4A4640)
      ..strokeWidth = 1.5);
    c.drawLine(r.topRight.translate(-8, 0), r.topRight.translate(-8, -18), Paint()
      ..color = const Color(0xFF4A4640)
      ..strokeWidth = 1.5);
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), Paint()..shader = const LinearGradient(colors: [Color(0xFFC0392B), Color(0xFF962D22)]).createShader(r));
    _text(c, 'মুদির দোকান', r.center, 9, const Color(0xFFFFF4D6), bold: true);
  }

  static void _text(Canvas c, String s, Offset at, double size, Color color, {bool bold = false}) => _textAt(c, s, at, size, color, bold: bold);

  @override
  bool shouldRepaint(M7TtLanePainter old) => old.geo != geo || !identical(old.lane, lane);
}

/// The meter close-up: the wall, the board, the meter with its seal, the
/// cables and (a bypass) the jumper under the terminal block.
class M7TtMeterPainter extends CustomPainter {
  M7TtMeterPainter({required this.geo, required this.meter});
  final M7TtGeo geo;
  final M7TtMeter meter;

  @override
  void paint(Canvas c, Size size) {
    final h = geo.height;
    final wall = Rect.fromLTWH(0, 0, kM7TtViewW, h);
    c.drawRect(wall, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFD9C29A), Color(0xFFB99F78)]).createShader(wall));
    // Plaster cracks and the house number.
    final crack = Paint()
      ..color = const Color(0x33503A20)
      ..strokeWidth = 1;
    c.drawLine(Offset(40, h * 0.3), Offset(62, h * 0.36), crack);
    c.drawLine(Offset(300, h * 0.62), Offset(318, h * 0.7), crack);
    final plate = Rect.fromLTWH(290, math.max(150.0, h * 0.24), 36, 20);
    c.drawRect(plate, Paint()..color = const Color(0xFFF7F1DE));
    M7TtLanePainter._text(c, '${meter.houseNo}', plate.center, 11, const Color(0xFF2A2018), bold: true);
    // The board.
    final b = geo.board;
    c.drawRRect(
      RRect.fromRectAndRadius(b, const Radius.circular(4)),
      Paint()..shader = const LinearGradient(colors: [Color(0xFF8A6A44), Color(0xFF6A4E30)]).createShader(b),
    );
    // Cables (drawn under the meter where they run behind it).
    final cable = Paint()
      ..color = _wireCol
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final s = geo.cableStart;
    final under = geo.underY;
    final inP = geo.meterIn;
    final outP = geo.meterOut;
    final pipe = geo.pipe;
    final inPath = Path()
      ..moveTo(s.dx, s.dy)
      ..lineTo(s.dx, under)
      ..lineTo(inP.dx, under)
      ..lineTo(inP.dx, inP.dy);
    c.drawPath(inPath, cable);
    final outPath = Path()
      ..moveTo(outP.dx, outP.dy)
      ..lineTo(outP.dx, under)
      ..lineTo(pipe.dx, under)
      ..lineTo(pipe.dx, pipe.dy);
    c.drawPath(outPath, cable);
    if (meter.kase == M7TtMeterCase.bypass) {
      final j = Path()
        ..moveTo(s.dx, under)
        ..lineTo(inP.dx - 6, under + 26)
        ..lineTo(outP.dx + 6, under + 26)
        ..lineTo(pipe.dx, under);
      c.drawPath(j, cable..strokeWidth = 3.4);
      for (final p in [Offset(s.dx, under), Offset(pipe.dx, under)]) {
        c.drawCircle(p, 4.5, Paint()..color = const Color(0xFF101112));
      }
    }
    // The wall pipe.
    c.drawRect(Rect.fromCenter(center: pipe.translate(0, 8), width: 14, height: 18), Paint()..color = const Color(0xFF8C8C8C));
    if (meter.patched) {
      final p = geo.patchAt;
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: p, width: 10, height: 14), const Radius.circular(3)), Paint()..color = const Color(0xFF101112));
    }
    // The meter.
    final m = geo.meterBody;
    c.drawRRect(
      RRect.fromRectAndRadius(m, const Radius.circular(8)),
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFEDEFF2), Color(0xFFC3C8CE)]).createShader(m),
    );
    final disp = Rect.fromLTWH(m.left + 14, m.top + 14, m.width - 28, 22);
    c.drawRRect(RRect.fromRectAndRadius(disp, const Radius.circular(3)), Paint()..color = const Color(0xFF2E3B2E));
    M7TtLanePainter._text(c, '04217', disp.center, 11, const Color(0xFF9FE3A8), bold: true);
    c.drawCircle(Offset(m.right - 14, m.top + 46), 3, Paint()..color = const Color(0xFFE53935));
    // The terminal block and its cover.
    final term = Rect.fromLTRB(m.left + 6, m.bottom - 2, m.right - 6, geo.termY + 10);
    c.drawRRect(RRect.fromRectAndRadius(term, const Radius.circular(3)), Paint()..color = const Color(0xFF5E646C));
    // The seal on the terminal cover: a lead seal on a twisted wire (cut:
    // the wire broken, the seal hanging).
    final sa = geo.sealAt;
    final sw = Paint()
      ..color = const Color(0xFF9AA0A6)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    if (meter.kase == M7TtMeterCase.sealCut) {
      c.drawLine(sa.translate(-10, -6), sa.translate(-3, 2), sw);
      c.drawLine(sa.translate(3, 8), sa.translate(10, -6), sw);
      c.drawCircle(sa.translate(4, 14), 4, Paint()..color = const Color(0xFF7E848A));
    } else {
      c.drawLine(sa.translate(-10, -6), sa.translate(0, 4), sw);
      c.drawLine(sa.translate(0, 4), sa.translate(10, -6), sw);
      c.drawCircle(sa.translate(0, 7), 4, Paint()..color = const Color(0xFF7E848A));
    }
    // On the body: a magnet, a paper sticker or nothing.
    final ba = geo.bodyAt;
    if (meter.kase == M7TtMeterCase.magnet) {
      final mg = Rect.fromCenter(center: ba, width: 26, height: 16);
      c.drawRRect(RRect.fromRectAndRadius(mg, const Radius.circular(3)), Paint()..color = const Color(0xFF3A3D42));
      c.drawRect(Rect.fromLTWH(mg.left, mg.top, 6, mg.height), Paint()..color = const Color(0xFF55595F));
    } else if (meter.sticker) {
      final st = Rect.fromCenter(center: ba, width: 26, height: 16);
      c.drawRect(st, Paint()..color = const Color(0xFFF4F0D8));
      for (var k = 0; k < 3; k++) {
        c.drawLine(Offset(st.left + 4, st.top + 4 + k * 4), Offset(st.right - 4 - k * 3, st.top + 4 + k * 4), Paint()
          ..color = const Color(0x664A4030)
          ..strokeWidth = 1);
      }
    }
  }

  @override
  bool shouldRepaint(M7TtMeterPainter old) => old.geo != geo || !identical(old.meter, meter);
}

/// The chalk along the wire being traced (and the dim chalk of judged
/// wires), with its head.
class M7TtChalkPainter extends CustomPainter {
  M7TtChalkPainter({required this.points, required this.done, required Listenable repaint}) : super(repaint: repaint);

  /// The live chalk (from the root to the head; empty: none).
  final List<Offset> Function() points;

  /// The judged wires' chalk.
  final List<List<Offset>> Function() done;

  @override
  void paint(Canvas c, Size size) {
    for (final d in done()) {
      if (d.length < 2) continue;
      c.drawPath(_path(d), Paint()
        ..color = const Color(0x88FFFBEA)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke);
    }
    final pts = points();
    if (pts.isEmpty) return;
    if (pts.length > 1) {
      final p = _path(pts);
      c.drawPath(p, Paint()
        ..color = const Color(0x66FFFFFF)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke);
      c.drawPath(p, Paint()
        ..color = const Color(0xFFFFFBEA)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke);
    }
    final head = pts.last;
    c.drawCircle(head, 7, Paint()..color = const Color(0x55FFFFFF));
    c.drawCircle(head, 4, Paint()..color = const Color(0xFFFFFBEA));
  }

  static Path _path(List<Offset> pts) {
    final p = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final q in pts.skip(1)) {
      p.lineTo(q.dx, q.dy);
    }
    return p;
  }

  @override
  bool shouldRepaint(M7TtChalkPainter old) => true;
}

/// The red pin (a widget-sized painter; its point at the bottom centre).
class M7TtPinPainter extends CustomPainter {
  const M7TtPinPainter();

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    c.drawLine(Offset(w / 2, h * 0.42), Offset(w / 2, h), Paint()
      ..color = const Color(0xFF5A5A5A)
      ..strokeWidth = 2);
    final head = Offset(w / 2, h * 0.26);
    c.drawCircle(head, w * 0.34, Paint()..shader = const RadialGradient(colors: [Color(0xFFFF6B6B), Color(0xFFB71C1C)], center: Alignment(-0.3, -0.3)).createShader(Rect.fromCircle(center: head, radius: w * 0.34)));
  }

  @override
  bool shouldRepaint(M7TtPinPainter old) => false;
}

/// The notebook's sketch of the traced path: its points in a row, joined
/// where the supply runs (on a bypass the meter's points sit off the line).
class M7TtSketchPainter extends CustomPainter {
  const M7TtSketchPainter({required this.spots, required this.v});
  final List<M7TtSpot> spots;

  /// How much of the sketch is drawn (0…1).
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final n = spots.length;
    final bypass = spots.contains(M7TtSpot.jumper);
    bool offLine(int i) => m7TtOffLine(spots, i);
    Offset at(int i) => m7TtStationAt(spots, i);
    final ink = Paint()
      ..color = const Color(0xFF2A3A6A)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final onLine = [for (var i = 0; i < n; i++) if (!offLine(i)) i];
    final total = onLine.length - 1;
    for (var k = 0; k < total; k++) {
      final f = (v * total - k).clamp(0.0, 1.0);
      if (f <= 0) break;
      final a = at(onLine[k]);
      final b = at(onLine[k + 1]);
      c.drawLine(a, Offset.lerp(a, b, f)!, ink);
    }
    if (bypass) {
      // The meter's points hang off the line on a dashed stub.
      final dash = Paint()
        ..color = const Color(0x882A3A6A)
        ..strokeWidth = 1.4;
      for (var i = 0; i < n; i++) {
        if (!offLine(i)) continue;
        final a = at(i);
        for (var y = a.dy + 14; y < M7TtSketch.y - 6; y += 6) {
          c.drawLine(Offset(a.dx, y), Offset(a.dx, y + 3), dash);
        }
      }
    }
    for (var i = 0; i < n; i++) {
      final shown = v >= (onLine.contains(i) ? onLine.indexOf(i) / math.max(1, total) : 0.5) - 0.01;
      if (shown) m7TtDrawSpot(c, spots[i], at(i));
    }
  }

  @override
  bool shouldRepaint(M7TtSketchPainter old) => old.v != v || !identical(old.spots, spots);
}

/// One point of the sketch, drawn as a worker would in a notebook.
void m7TtDrawSpot(Canvas c, M7TtSpot s, Offset o) {
  final ink = Paint()
    ..color = const Color(0xFF2A3A6A)
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  final fill = Paint()..color = const Color(0xFF2A3A6A);
  final bg = Paint()..color = const Color(0xFFFFFDF4);
  c.drawCircle(o, 17, bg);
  switch (s) {
    case M7TtSpot.clamp:
      c.drawLine(o.translate(-14, -8), o.translate(14, -8), ink..strokeWidth = 3);
      c.drawRect(Rect.fromCenter(center: o.translate(0, -3), width: 9, height: 10), fill);
      c.drawLine(o.translate(0, 2), o.translate(0, 14), ink..strokeWidth = 2);
    case M7TtSpot.hook:
      c.drawLine(o.translate(-14, -8), o.translate(14, -8), ink..strokeWidth = 3);
      final p = Path()
        ..moveTo(o.dx, o.dy + 14)
        ..lineTo(o.dx, o.dy - 6)
        ..quadraticBezierTo(o.dx + 5, o.dy - 16, o.dx + 8, o.dy - 6);
      c.drawPath(p, ink..strokeWidth = 2.4);
    case M7TtSpot.plain:
    case M7TtSpot.cable:
      c.drawLine(o.translate(-14, 0), o.translate(14, 0), ink..strokeWidth = 2.4);
    case M7TtSpot.patch:
      c.drawLine(o.translate(-14, 0), o.translate(14, 0), ink..strokeWidth = 2.4);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: 12, height: 9), const Radius.circular(2)), Paint()..color = const Color(0xFF101112));
    case M7TtSpot.joint:
      c.drawLine(o.translate(-14, 0), o.translate(14, 0), ink..strokeWidth = 2.4);
      c.drawLine(o, o.translate(6, 14), ink..strokeWidth = 2);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: 9, height: 9), const Radius.circular(2)), Paint()..color = const Color(0xFF101112));
    case M7TtSpot.meter:
    case M7TtSpot.meterLoop:
      c.drawRect(Rect.fromCenter(center: o, width: 18, height: 22), ink..strokeWidth = 2);
      c.drawRect(Rect.fromCenter(center: o.translate(0, -4), width: 10, height: 5), fill);
      if (s == M7TtSpot.meterLoop) {
        final p = Path()
          ..moveTo(o.dx - 2, o.dy - 11)
          ..cubicTo(o.dx - 20, o.dy - 14, o.dx - 20, o.dy + 15, o.dx - 2, o.dy + 12);
        c.drawPath(p, ink..strokeWidth = 2);
      }
    case M7TtSpot.house:
      final p = Path()
        ..moveTo(o.dx - 11, o.dy - 2)
        ..lineTo(o.dx, o.dy - 12)
        ..lineTo(o.dx + 11, o.dy - 2)
        ..lineTo(o.dx + 11, o.dy + 12)
        ..lineTo(o.dx - 11, o.dy + 12)
        ..close();
      c.drawPath(p, ink..strokeWidth = 2);
    case M7TtSpot.seal:
    case M7TtSpot.sealCut:
      if (s == M7TtSpot.seal) {
        c.drawLine(o.translate(-10, -8), o.translate(0, 2), ink..strokeWidth = 1.6);
        c.drawLine(o.translate(0, 2), o.translate(10, -8), ink..strokeWidth = 1.6);
        c.drawCircle(o.translate(0, 7), 5, fill);
      } else {
        c.drawLine(o.translate(-10, -8), o.translate(-3, 0), ink..strokeWidth = 1.6);
        c.drawLine(o.translate(4, 4), o.translate(10, -8), ink..strokeWidth = 1.6);
        c.drawCircle(o.translate(5, 10), 5, fill);
      }
    case M7TtSpot.body:
    case M7TtSpot.sticker:
    case M7TtSpot.magnet:
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: 22, height: 26), const Radius.circular(4)), ink..strokeWidth = 2);
      if (s == M7TtSpot.sticker) {
        c.drawRect(Rect.fromCenter(center: o.translate(0, 5), width: 14, height: 9), Paint()..color = const Color(0xFFE6DFB8));
        c.drawRect(Rect.fromCenter(center: o.translate(0, 5), width: 14, height: 9), ink..strokeWidth = 1);
      } else if (s == M7TtSpot.magnet) {
        c.drawRect(Rect.fromCenter(center: o.translate(0, 5), width: 14, height: 9), fill);
      }
    case M7TtSpot.jumper:
      final p = Path()
        ..moveTo(o.dx - 14, o.dy - 4)
        ..quadraticBezierTo(o.dx, o.dy + 18, o.dx + 14, o.dy - 4);
      c.drawPath(p, ink..strokeWidth = 2.4);
      c.drawCircle(o.translate(-14, -4), 3, fill);
      c.drawCircle(o.translate(14, -4), 3, fill);
  }
}

void _textAt(Canvas c, String s, Offset at, double size, Color color, {bool bold = false}) {
  final tp = TextPainter(
    text: TextSpan(
      text: s,
      style: TextStyle(
        fontFamily: banglaFont,
        fontFamilyFallback: const ['Roboto', 'Noto Sans'],
        fontSize: size,
        color: color,
        fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
        height: 1,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(c, at - Offset(tp.width / 2, tp.height / 2));
}
