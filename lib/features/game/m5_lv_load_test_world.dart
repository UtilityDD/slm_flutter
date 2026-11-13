import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The drawn world of lesson 5.5 কাজ 2 "লোড দিয়ে মাপুন" (m5_lv_load_test.dart):
// one house at dusk. On the left the street's LT pole carries the phase and
// the neutral wire; the house's service cable taps both just right of the
// pole (the pole-end joints) and droops to the veranda. On the veranda wall:
// the meter board — the energy meter, and under a clear cover three brass
// terminals in a row (incoming P, incoming N and the earth terminal, drawn
// alike). The customer stands in the doorway on the right; the trainee by the
// board; the analogue tester (a widget, see the page) stands on the veranda
// floor with its two leads.
//
// No hint is drawn: the joints look alike, nothing on the wall is ringed.
// After a joint is tightened its nut shows bright (feedback, after the act).
//
// Design: 360 wide × the scene's height; the ground follows the bottom of the
// screen (a tall phone gets more sky, never a stretched picture).

/// The meter board's three terminals.
enum M5LvLoadTerm { p, n, e }

/// The service connection's joints: two at the pole end, two at the meter.
enum M5LvLoadJoint { poleP, poleN, meterP, meterN }

/// Where things are (design px, 360 wide).
@immutable
class M5LvLoadGeo {
  const M5LvLoadGeo._(this.height, this.groundY, this.topY, this.houseTop);

  factory M5LvLoadGeo.forScene(double height, double inset) {
    final g = height - floorUp - inset * 0.5;
    final top = math.max(128.0, g - 480);
    final houseH = (g - top - 110).clamp(210.0, 340.0);
    return M5LvLoadGeo._(height, g, top, g - houseH);
  }

  final double height;

  /// The veranda floor / ground line.
  final double groundY;

  /// The pole top.
  final double topY;

  /// The top of the house wall.
  final double houseTop;

  /// The ground sits this far above the bottom (the switchboard row stands
  /// under it).
  static const double floorUp = 118;

  static const double poleX = 30;

  /// The LT phase and neutral wires (heights at the pole).
  double get wireP => topY + 22;
  double get wireN => topY + 70;

  /// The house wall.
  double get houseLeft => 84;

  /// The meter board and its meter.
  Rect get board => Rect.fromLTWH(98, houseTop + 22, 140, 128);
  Rect get meterBox => Rect.fromLTWH(126, houseTop + 32, 84, 52);

  /// The terminal row under the clear cover.
  double get termY => houseTop + 120;
  static const Map<M5LvLoadTerm, double> termX = {M5LvLoadTerm.p: 128, M5LvLoadTerm.n: 170, M5LvLoadTerm.e: 212};
  Offset termAt(M5LvLoadTerm t) => Offset(termX[t]!, termY);
  Rect termHit(M5LvLoadTerm t) => Rect.fromCenter(center: termAt(t), width: 40, height: 48);

  Offset jointAt(M5LvLoadJoint j) => switch (j) {
        M5LvLoadJoint.poleP => Offset(62, wireP + 3),
        M5LvLoadJoint.poleN => Offset(62, wireN + 3),
        M5LvLoadJoint.meterP => termAt(M5LvLoadTerm.p),
        M5LvLoadJoint.meterN => termAt(M5LvLoadTerm.n),
      };
  Rect jointHit(M5LvLoadJoint j) => switch (j) {
        M5LvLoadJoint.poleP || M5LvLoadJoint.poleN => Rect.fromCenter(center: jointAt(j), width: 56, height: 44),
        M5LvLoadJoint.meterP => termHit(M5LvLoadTerm.p),
        M5LvLoadJoint.meterN => termHit(M5LvLoadTerm.n),
      };

  /// The doorway (the customer stands in it): tap to ask him.
  Rect get door {
    // Below the probes' rest (a short phone gets a shorter door).
    final top = math.max(groundY - 140, houseTop + 196);
    return Rect.fromLTRB(284, top, 340, groundY);
  }

  Rect get doorHit => door.inflate(6);

  /// The customer's speech bubble (above the door, right edge).
  Offset get bubbleAt => Offset(352, door.top - 8);

  /// The analogue tester on a shelf right of the board (clear of the corner
  /// guide at the bottom left), and its two lead sockets.
  Rect get tester => Rect.fromLTWH(252, houseTop + 24, 96, 112);
  Rect get shelf => Rect.fromLTWH(246, tester.bottom, 108, 7);
  Offset get socketRed => Offset(tester.left + 30, tester.bottom - 8);
  Offset get socketBlack => Offset(tester.right - 30, tester.bottom - 8);

  /// Where the two probes rest when not on a terminal (drag them up).
  Offset get restRed => Offset(tester.left + 22, houseTop + 168);
  Offset get restBlack => Offset(tester.right - 22, houseTop + 168);
  Rect restHit(bool red) => Rect.fromCenter(center: red ? restRed : restBlack, width: 44, height: 40);

  /// The trainee under the board (clear of the corner guide's sprite, which
  /// stands at the bottom left up to x ≈ 213).
  Rect get trainee => Rect.fromLTWH(218, groundY - 112, 56, 112);

  /// The tightening hint's tap (how, never what): open sky right of the pole,
  /// between the two LT wires and above the house — clear of every joint,
  /// terminal, the door, the tester and the probes on any scene height.
  Offset get tightenHint => Offset(300, topY + 56);

  @override
  bool operator ==(Object other) => other is M5LvLoadGeo && other.height == height && other.groundY == groundY && other.topY == topY;

  @override
  int get hashCode => Object.hash(height, groundY, topY);
}

/// What the house shows now.
@immutable
class M5LvLoadRig {
  const M5LvLoadRig({required this.supplyOn, required this.tight, required this.wall, required this.lit});

  /// The supply is on (the windows glow).
  final bool supplyOn;

  /// The joints tightened this call (their nuts show bright).
  final Set<M5LvLoadJoint> tight;

  /// The house's wall tone (a fresh house each call).
  final int wall;

  /// How many lights / loads are on (the window's glow).
  final int lit;

  @override
  bool operator ==(Object other) =>
      other is M5LvLoadRig && other.supplyOn == supplyOn && setEquals(other.tight, tight) && other.wall == wall && other.lit == lit;

  @override
  int get hashCode => Object.hash(supplyOn, Object.hashAllUnordered(tight), wall, lit);
}

const _walls = [
  [Color(0xFFE6D3B0), Color(0xFFCDB58C)],
  [Color(0xFFCFE0D2), Color(0xFFA9C2AF)],
  [Color(0xFFE8C9BE), Color(0xFFCCA394)],
  [Color(0xFFD7D4E6), Color(0xFFB2AECB)],
];
const _wire = Color(0xFF2C3036);
const _brass = Color(0xFFC9A04A);

class M5LvLoadWorldPainter extends CustomPainter {
  const M5LvLoadWorldPainter({required this.geo, required this.rig});

  final M5LvLoadGeo geo;
  final M5LvLoadRig rig;

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
          colors: [Color(0xFF1B2246), Color(0xFF5B3F6E), Color(0xFFE08A5C)],
          stops: [0, 0.55, 1],
        ).createShader(Rect.fromLTWH(0, 0, w, g.groundY)),
    );
    // Far houses (the neighbours: their windows lit).
    final far = Paint()..color = const Color(0xFF2E2440);
    final farTop = g.houseTop + 40;
    c.drawRect(Rect.fromLTRB(0, farTop, 90, g.groundY), far);
    final glow = Paint()..color = const Color(0xFFFFD27A);
    for (final x in [14.0, 50.0]) {
      c.drawRect(Rect.fromLTWH(x, farTop + 26, 14, 16), glow);
    }
    // Ground / veranda floor.
    c.drawRect(
      Rect.fromLTWH(0, g.groundY, w, size.height - g.groundY),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6B5A4A), Color(0xFF3A3028)],
        ).createShader(Rect.fromLTWH(0, g.groundY, w, size.height - g.groundY)),
    );
    _house(c, w);
    _pole(c);
    _serviceCable(c);
    _board(c);
    _door(c);
  }

  void _pole(Canvas c) {
    final g = geo;
    final pole = Path()
      ..moveTo(_Pole.poleL, g.groundY)
      ..lineTo(_Pole.poleL + 3, g.topY)
      ..lineTo(_Pole.poleR - 3, g.topY)
      ..lineTo(_Pole.poleR, g.groundY)
      ..close();
    c.drawPath(
      pole,
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFF8C8F92), Color(0xFF5E6265)])
            .createShader(Rect.fromLTRB(_Pole.poleL, g.topY, _Pole.poleR, g.groundY)),
    );
    // Cross-arm and the two LT wires running along the street.
    c.drawRect(Rect.fromLTWH(M5LvLoadGeo.poleX - 26, g.topY + 10, 52, 6), Paint()..color = const Color(0xFF55595D));
    final wire = Paint()
      ..color = _wire
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    for (final y in [g.wireP, g.wireN]) {
      c.drawPath(
        Path()
          ..moveTo(-10, y + 6)
          ..quadraticBezierTo(M5LvLoadGeo.poleX - 10, y - 2, M5LvLoadGeo.poleX, y)
          ..quadraticBezierTo(200, y + 18, 370, y + 6),
        wire,
      );
    }
    // The pole-end joints (alike; bright once tightened).
    for (final j in [M5LvLoadJoint.poleP, M5LvLoadJoint.poleN]) {
      _clamp(c, g.jointAt(j), rig.tight.contains(j));
    }
  }

  void _clamp(Canvas c, Offset at, bool tight) {
    final body = RRect.fromRectAndRadius(Rect.fromCenter(center: at, width: 16, height: 12), const Radius.circular(3));
    c.drawRRect(body, Paint()..color = const Color(0xFF8A8F96));
    c.drawCircle(at, 3.6, Paint()..color = tight ? const Color(0xFFF2D27A) : const Color(0xFF5B5F66));
  }

  void _serviceCable(Canvas c) {
    final g = geo;
    final entry = Offset(g.houseLeft + 6, g.houseTop + 26);
    final p = Paint()
      ..color = const Color(0xFF1E2126)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final pj = g.jointAt(M5LvLoadJoint.poleP);
    final nj = g.jointAt(M5LvLoadJoint.poleN);
    // Two cores from the joints down to a twisted service cable.
    final knot = Offset(74, g.wireN + 30);
    c.drawPath(Path()..moveTo(pj.dx + 6, pj.dy)..quadraticBezierTo(76, (pj.dy + knot.dy) / 2, knot.dx, knot.dy), p..strokeWidth = 2);
    c.drawPath(Path()..moveTo(nj.dx + 6, nj.dy)..quadraticBezierTo(70, (nj.dy + knot.dy) / 2, knot.dx, knot.dy), p);
    c.drawPath(Path()..moveTo(knot.dx, knot.dy)..quadraticBezierTo((knot.dx + entry.dx) / 2, entry.dy + 24, entry.dx, entry.dy), p..strokeWidth = 3.4);
    // Along the wall to the board (P and N to their terminals, from above).
    final b = g.board;
    c.drawPath(
      Path()
        ..moveTo(entry.dx, entry.dy)
        ..lineTo(b.left - 4, entry.dy)
        ..lineTo(b.left - 4, b.bottom - 14),
      p..strokeWidth = 3,
    );
  }

  void _house(Canvas c, double w) {
    final g = geo;
    final tone = _walls[rig.wall % _walls.length];
    final wall = Rect.fromLTRB(g.houseLeft, g.houseTop, w, g.groundY);
    c.drawRect(
      wall,
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: tone).createShader(wall),
    );
    // Parapet.
    c.drawRect(Rect.fromLTRB(g.houseLeft - 6, g.houseTop - 12, w, g.houseTop), Paint()..color = const Color(0xFF8E7C66));
    // Dusk shade at the bottom of the wall.
    c.drawRect(
      wall,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x00000000), Color(0x55201030)],
        ).createShader(wall),
    );
    // The tester's shelf.
    final sh = g.shelf;
    c.drawRect(sh, Paint()..color = const Color(0xFF6B4E32));
    c.drawLine(Offset(sh.left + 10, sh.bottom), Offset(sh.left + 22, sh.bottom + 14), Paint()
      ..color = const Color(0xFF55402A)
      ..strokeWidth = 3);
    c.drawLine(Offset(sh.right - 10, sh.bottom), Offset(sh.right - 22, sh.bottom + 14), Paint()
      ..color = const Color(0xFF55402A)
      ..strokeWidth = 3);
  }

  void _board(Canvas c) {
    final g = geo;
    final b = g.board;
    // Wooden board.
    c.drawRRect(
      RRect.fromRectAndRadius(b, const Radius.circular(6)),
      Paint()..shader = const LinearGradient(colors: [Color(0xFF7A5634), Color(0xFF5C3F25)]).createShader(b),
    );
    // The meter.
    final m = g.meterBox;
    c.drawRRect(RRect.fromRectAndRadius(m, const Radius.circular(6)), Paint()..color = const Color(0xFFE9ECEF));
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(m.left + 12, m.top + 10, m.width - 24, 18), const Radius.circular(3)),
      Paint()..color = rig.supplyOn ? const Color(0xFF8FD18A) : const Color(0xFF55605A),
    );
    c.drawCircle(Offset(m.right - 14, m.bottom - 10), 3, Paint()..color = rig.supplyOn ? const Color(0xFFE5533D) : const Color(0xFF6A4A44));
    // The seal wire (a real meter's lead seal).
    c.drawLine(Offset(m.center.dx, m.bottom), Offset(m.center.dx, m.bottom + 8), Paint()
      ..color = const Color(0xFF9AA0A6)
      ..strokeWidth = 1.2);
    c.drawCircle(Offset(m.center.dx, m.bottom + 10), 2.6, Paint()..color = const Color(0xFF9AA0A6));
    // Wires from the terminals up into the meter.
    final wp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    for (final t in M5LvLoadTerm.values) {
      final at = g.termAt(t);
      wp.color = switch (t) {
        M5LvLoadTerm.p => const Color(0xFFB8322A),
        M5LvLoadTerm.n => const Color(0xFF22242A),
        M5LvLoadTerm.e => const Color(0xFF3F8A4A),
      };
      c.drawLine(Offset(at.dx, at.dy - 10), Offset(at.dx, m.bottom + (t == M5LvLoadTerm.e ? 22 : 0)), wp);
    }
    // The terminals (alike) under a clear cover.
    for (final t in M5LvLoadTerm.values) {
      final at = g.termAt(t);
      final tight = (t == M5LvLoadTerm.p && rig.tight.contains(M5LvLoadJoint.meterP)) || (t == M5LvLoadTerm.n && rig.tight.contains(M5LvLoadJoint.meterN));
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: at, width: 22, height: 18), const Radius.circular(3)),
          Paint()..color = const Color(0xFF3A3D42));
      c.drawCircle(at, 6.4, Paint()..color = tight ? const Color(0xFFF4D88A) : _brass);
      c.drawCircle(at, 2.2, Paint()..color = const Color(0xFF5A4520));
    }
    final cover = Rect.fromLTRB(b.left + 10, g.termY - 22, b.right - 10, g.termY + 18);
    c.drawRRect(RRect.fromRectAndRadius(cover, const Radius.circular(5)), Paint()..color = const Color(0x22D8F0FF));
    c.drawRRect(
      RRect.fromRectAndRadius(cover, const Radius.circular(5)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0x88D8F0FF),
    );
    // The terminal marks a worker reads.
    for (final t in M5LvLoadTerm.values) {
      final at = g.termAt(t);
      final tp = TextPainter(
        text: TextSpan(
          text: switch (t) {
            M5LvLoadTerm.p => 'P',
            M5LvLoadTerm.n => 'N',
            M5LvLoadTerm.e => 'E',
          },
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFF3E6C8)),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(c, Offset(at.dx - tp.width / 2, at.dy + 20));
    }
  }

  void _door(Canvas c) {
    final d = geo.door;
    c.drawRect(d.inflate(4), Paint()..color = const Color(0xFF5A4532));
    // The room behind the door glows with the supply and the loads on.
    final glow = !rig.supplyOn
        ? const Color(0xFF2E2A30)
        : Color.lerp(const Color(0xFF6E5A3E), const Color(0xFFE8C27A), (rig.lit / 3).clamp(0.0, 1.0))!;
    c.drawRect(d, Paint()..color = glow);
    // The customer in the doorway.
    final cx = d.center.dx;
    final top = d.top + 16;
    final skin = Paint()..color = const Color(0xFFB98260);
    c.drawCircle(Offset(cx, top + 12), 11, skin);
    c.drawPath(
      Path()
        ..moveTo(cx - 13, top + 8)
        ..quadraticBezierTo(cx, top - 6, cx + 13, top + 8)
        ..lineTo(cx + 12, top + 4)
        ..quadraticBezierTo(cx, top - 2, cx - 12, top + 4)
        ..close(),
      Paint()..color = const Color(0xFF1E1A18),
    );
    final shirt = Rect.fromLTRB(cx - 17, top + 24, cx + 17, math.min(d.bottom - 40, top + 82));
    c.drawRRect(RRect.fromRectAndRadius(shirt, const Radius.circular(8)), Paint()..color = const Color(0xFF3F6FA8));
    c.drawRect(Rect.fromLTRB(cx - 15, shirt.bottom, cx + 15, d.bottom), Paint()..color = const Color(0xFFE7E1D2));
  }

  @override
  bool shouldRepaint(M5LvLoadWorldPainter old) => old.geo != geo || old.rig != rig;
}

/// The pole's outline x (a tapering concrete pole).
abstract final class _Pole {
  static const double poleL = M5LvLoadGeo.poleX - 7;
  static const double poleR = M5LvLoadGeo.poleX + 7;
}

/// The two test leads: from the tester's sockets to the probe tips.
class M5LvLoadLeadsPainter extends CustomPainter {
  const M5LvLoadLeadsPainter({required this.geo, required this.red, required this.black});

  final M5LvLoadGeo geo;
  final Offset red;
  final Offset black;

  @override
  void paint(Canvas c, Size size) {
    _lead(c, geo.socketRed, red, const Color(0xFFD23A2E));
    _lead(c, geo.socketBlack, black, const Color(0xFF1C1E22));
  }

  void _lead(Canvas c, Offset from, Offset tip, Color colour) {
    final mid = Offset((from.dx + tip.dx) / 2, math.max(from.dy, tip.dy) + 18);
    c.drawPath(
      Path()
        ..moveTo(from.dx, from.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, tip.dx, tip.dy + 14),
      Paint()
        ..color = colour
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6,
    );
    // The probe body (insulated handle, a short metal tip).
    final handle = RRect.fromRectAndRadius(Rect.fromCenter(center: tip.translate(0, 9), width: 8, height: 18), const Radius.circular(3));
    c.drawRRect(handle, Paint()..color = colour);
    c.drawLine(tip, tip.translate(0, -4), Paint()
      ..color = const Color(0xFFD9DDE2)
      ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(M5LvLoadLeadsPainter old) => old.geo != geo || old.red != red || old.black != black;
}

/// The tester's analogue dial: 0–300 V, no coloured zone; the needle at [v].
class M5LvLoadDialPainter extends CustomPainter {
  const M5LvLoadDialPainter({required this.v});

  final double v;

  static const double maxV = 300;

  @override
  void paint(Canvas c, Size size) {
    final centre = Offset(size.width / 2, size.height * 0.92);
    final r = math.min(size.width / 2 - 6, size.height * 0.84);
    c.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(6)), Paint()..color = const Color(0xFFF4F1E6));
    final scale = Paint()
      ..color = const Color(0xFF2A2C30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    c.drawArc(Rect.fromCircle(center: centre, radius: r), math.pi * 1.15, math.pi * 0.7, false, scale);
    for (var i = 0; i <= 6; i++) {
      final a = math.pi * 1.15 + math.pi * 0.7 * i / 6;
      final o = centre + Offset(math.cos(a), math.sin(a)) * r;
      final inner = centre + Offset(math.cos(a), math.sin(a)) * (r - (i.isEven ? 7 : 4));
      c.drawLine(inner, o, scale);
      if (i.isEven) {
        final tp = TextPainter(
          text: TextSpan(text: '${(maxV * i / 6).round()}', style: const TextStyle(fontSize: 7, color: Color(0xFF2A2C30))),
          textDirection: TextDirection.ltr,
        )..layout();
        final at = centre + Offset(math.cos(a), math.sin(a)) * (r - 14);
        tp.paint(c, at - Offset(tp.width / 2, tp.height / 2));
      }
    }
    final a = math.pi * 1.15 + math.pi * 0.7 * (v / maxV).clamp(0.0, 1.0);
    c.drawLine(
      centre,
      centre + Offset(math.cos(a), math.sin(a)) * (r - 2),
      Paint()
        ..color = const Color(0xFF1A1A1A)
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );
    c.drawCircle(centre, 3, Paint()..color = const Color(0xFF1A1A1A));
  }

  @override
  bool shouldRepaint(M5LvLoadDialPainter old) => old.v != v;
}

/// A deadly move: the flash at the terminal in colour over the grey scene.
class M5LvLoadFlashPainter extends CustomPainter {
  const M5LvLoadFlashPainter({required this.at, required this.v});

  final Offset at;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    if (v <= 0) return;
    final r = 14 + 60 * v;
    c.drawCircle(
      at,
      r,
      Paint()
        ..shader = RadialGradient(colors: [
          Color.fromRGBO(255, 255, 255, 0.95 * (1 - v * 0.4)),
          Color.fromRGBO(255, 214, 90, 0.8 * (1 - v * 0.5)),
          const Color(0x00FF8A00),
        ], stops: const [0, 0.35, 1])
            .createShader(Rect.fromCircle(center: at, radius: r)),
    );
    final bolt = Paint()
      ..color = const Color(0xFFFFF3B0)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3 + 0.3;
      final p = Path()..moveTo(at.dx, at.dy);
      var cur = at;
      for (var k = 1; k <= 3; k++) {
        cur = at + Offset(math.cos(a + (k.isEven ? 0.25 : -0.25)), math.sin(a + (k.isEven ? 0.25 : -0.25))) * (r * k / 3);
        p.lineTo(cur.dx, cur.dy);
      }
      c.drawPath(p, bolt);
    }
  }

  @override
  bool shouldRepaint(M5LvLoadFlashPainter old) => old.v != v || old.at != at;
}
