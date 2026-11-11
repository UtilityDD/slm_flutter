import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The drawn world of lesson 4.10 কাজ "তিন ফেজে সমান ভার" (m4_phase_balance.dart):
// a street corner at the evening peak — the distribution transformer on its
// plinth, its LT cable down into a feeder pillar with the door open (the LT
// main switch with its handle, the four bars R · Y · B · N, a lug on a bar
// for every service connection on that phase, the outgoing cables where the
// tong tester clamps), the houses behind with their lights. Code-drawn,
// gradients, no bitmaps. Design space 360 wide; the ground sits
// [M4PhaseBalanceGeo.floorUp] above the bottom so the controls sit on it.

/// Where things are in the scene (design px, 360 wide).
@immutable
class M4PhaseBalanceGeo {
  const M4PhaseBalanceGeo._(this.height, this.groundY);

  factory M4PhaseBalanceGeo.forScene(double height, double inset) => M4PhaseBalanceGeo._(height, height - floorUp - inset * 0.5);

  final double height;

  /// The ground line.
  final double groundY;

  static const double floorUp = 104;

  /// The feeder pillar (door open).
  Rect get pillar => Rect.fromLTRB(84, groundY - 262, 278, groundY - 6);

  /// The LT main switch inside the pillar and its handle (tap to switch).
  Rect get switchBox => Rect.fromLTWH(94, pillar.top + 16, 62, 88);
  Rect get handleHit => Rect.fromLTWH(88, pillar.top + 8, 76, 104);
  Offset get handlePivot => Offset(switchBox.right - 6, switchBox.top + 46);

  /// The four bars, left → right: R, Y, B, N.
  static const _barX = [176.0, 202.0, 228.0, 254.0];
  double barX(int i) => _barX[i];
  double get barTop => pillar.top + 18;
  double get barBottom => pillar.top + 124;

  /// The bars as one target (the spanner works the service connections there).
  Rect get barsHit => Rect.fromLTRB(164, pillar.top + 8, 268, pillar.top + 128);

  /// Where the tong tester's jaws close round the outgoing cable [i].
  Offset clampAt(int i) => Offset(_barX[i], pillar.top + 150);
  Rect cableHit(int i) => Rect.fromCenter(center: clampAt(i), width: 26, height: 48);

  /// The transformer on its plinth, behind the pillar's right.
  Rect get tank => Rect.fromLTRB(288, groundY - 300, 350, groundY - 206);

  /// The earthing rod by the pillar's foot.
  Offset get earthRod => Offset(pillar.right - 8, groundY + 6);

  /// Where the lineman stands: by the pillar, clear of the guide's corner.
  Rect get trainee => Rect.fromLTWH(6, groundY - 140, 70, 140);

  @override
  bool operator ==(Object other) => other is M4PhaseBalanceGeo && other.height == height && other.groundY == groundY;

  @override
  int get hashCode => Object.hash(height, groundY);
}

/// The wire colours (0 R, 1 Y, 2 B, 3 N).
const m4PhaseBalanceWireColors = [Color(0xFFD63A2F), Color(0xFFF2C230), Color(0xFF2F6FD6), Color(0xFF1E1E1E)];
const m4PhaseBalanceWireNames = ['R', 'Y', 'B', 'N'];

/// What the yard shows now.
@immutable
class M4PhaseBalanceYard {
  const M4PhaseBalanceYard({
    required this.lugs,
    required this.switchOn,
    required this.ptw,
    required this.earthOn,
    required this.clampOn,
    required this.shiftTok,
  });

  /// Service connections on R, Y, B.
  final List<int> lugs;
  final bool switchOn;
  final bool ptw;
  final bool earthOn;

  /// The cable the tong tester is round, if any.
  final int? clampOn;

  /// Bumps when the connections were moved (the moved lugs glint).
  final int shiftTok;

  @override
  bool operator ==(Object other) =>
      other is M4PhaseBalanceYard &&
      listEquals(other.lugs, lugs) &&
      other.switchOn == switchOn &&
      other.ptw == ptw &&
      other.earthOn == earthOn &&
      other.clampOn == clampOn &&
      other.shiftTok == shiftTok;

  @override
  int get hashCode => Object.hash(Object.hashAll(lugs), switchOn, ptw, earthOn, clampOn, shiftTok);
}

/// The street corner: sky, houses, transformer, pillar. [t] (seconds) is the
/// clock while awake (the transformer's hum lines, the lights' flicker).
class M4PhaseBalancePainter extends CustomPainter {
  M4PhaseBalancePainter({required this.geo, required this.yard, required this.t, required this.seed}) : super(repaint: t);

  final M4PhaseBalanceGeo geo;
  final M4PhaseBalanceYard yard;
  final ValueListenable<double> t;
  final int seed;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    // The evening sky.
    c.drawRect(
        Rect.fromLTWH(0, 0, w, g.groundY),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1D2A4D), Color(0xFF5B4A78), Color(0xFFE59A6A)],
            stops: [0, 0.55, 1],
          ).createShader(Rect.fromLTWH(0, 0, w, g.groundY)));
    final moon = Offset(56, g.pillar.top - 150);
    c.drawCircle(moon, 10, Paint()..color = const Color(0xFFF4E9C8));
    _houses(c, w);
    _ground(c, size);
    _transformer(c);
    _pillar(c);
  }

  void _houses(Canvas c, double w) {
    final g = geo;
    final rnd = math.Random(seed);
    final base = g.groundY - 40;
    var x = -8.0;
    var k = 0;
    while (x < w + 10) {
      final hw = 46 + rnd.nextDouble() * 22;
      final hh = 70 + rnd.nextDouble() * 60;
      final r = Rect.fromLTWH(x, base - hh, hw, hh + 40);
      final tone = 0.75 + rnd.nextDouble() * 0.25;
      c.drawRect(r, Paint()..color = Color.lerp(const Color(0xFF2A2D3E), const Color(0xFF4A4558), tone)!);
      c.drawRect(Rect.fromLTWH(r.left - 2, r.top - 4, r.width + 4, 5), Paint()..color = const Color(0xFF22242F));
      // Windows: warm when the supply is on, dark when it is off.
      for (var wy = r.top + 12; wy < base + 14; wy += 26) {
        for (var wx = r.left + 8; wx < r.right - 12; wx += 18) {
          final lit = yard.switchOn && rnd.nextDouble() > 0.25;
          c.drawRect(Rect.fromLTWH(wx, wy, 9, 11), Paint()..color = lit ? const Color(0xFFFFD27A) : const Color(0xFF1A1C26));
        }
      }
      x += hw + 4;
      k++;
      if (k > 12) break;
    }
  }

  void _ground(Canvas c, Size size) {
    final g = geo;
    final floor = Rect.fromLTRB(0, g.groundY, size.width, size.height);
    c.drawRect(floor, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF6B6459), Color(0xFF3F3A33)]).createShader(floor));
    c.drawLine(Offset(0, g.groundY), Offset(size.width, g.groundY), Paint()
      ..color = const Color(0xFF2F2B26)
      ..strokeWidth = 2);
    // The pillar's concrete base.
    c.drawRect(Rect.fromLTRB(g.pillar.left - 6, g.pillar.bottom - 2, g.pillar.right + 6, g.groundY + 8), Paint()..color = const Color(0xFF9A948A));
  }

  void _transformer(Canvas c) {
    final g = geo;
    final tk = g.tank;
    // The plinth and its two legs.
    final plinth = Rect.fromLTRB(tk.left - 8, tk.bottom, tk.right + 8, tk.bottom + 10);
    c.drawRect(plinth, Paint()..color = const Color(0xFF8E887E));
    for (final lx in [tk.left - 2, tk.right - 8]) {
      c.drawRect(Rect.fromLTWH(lx, plinth.bottom, 10, g.groundY - plinth.bottom), Paint()..color = const Color(0xFF7E786E));
    }
    // The tank (green-grey) with its fins.
    c.drawRRect(RRect.fromRectAndRadius(tk, const Radius.circular(4)),
        Paint()..shader = const LinearGradient(colors: [Color(0xFF55705E), Color(0xFF7E9A86), Color(0xFF4A6252)]).createShader(tk));
    final fin = Paint()
      ..color = const Color(0x66203028)
      ..strokeWidth = 2;
    for (var x = tk.left + 8; x < tk.right - 4; x += 7) {
      c.drawLine(Offset(x, tk.top + 14), Offset(x, tk.bottom - 6), fin);
    }
    // HT bushings on top, LT bushings on the side.
    for (var i = 0; i < 3; i++) {
      final bx = tk.left + 14 + 17.0 * i;
      c.drawRect(Rect.fromLTWH(bx - 3, tk.top - 20, 6, 20), Paint()..color = const Color(0xFFB98A5A));
      for (var r = 0; r < 3; r++) {
        c.drawOval(Rect.fromCenter(center: Offset(bx, tk.top - 6 - 6.0 * r), width: 11, height: 4), Paint()..color = const Color(0xFFA5764A));
      }
    }
    for (var i = 0; i < 4; i++) {
      final by = tk.top + 20 + 11.0 * i;
      c.drawRect(Rect.fromLTWH(tk.left - 8, by - 2, 8, 4), Paint()..color = const Color(0xFF8C8C8C));
    }
    _label(c, 'DTR', Offset(tk.center.dx, tk.center.dy + 10), 10, const Color(0xFFE7EFE9));
    // The LT cable from the side bushings down into the pillar's top.
    final cable = Path()
      ..moveTo(tk.left - 8, tk.top + 36)
      ..quadraticBezierTo(tk.left - 24, tk.top + 50, tk.left - 22, g.pillar.top - 8)
      ..quadraticBezierTo(tk.left - 22, g.pillar.top + 2, g.pillar.right - 20, g.pillar.top + 4);
    c.drawPath(cable, Paint()
      ..color = const Color(0xFF151515)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7);
    // The hum while it carries load.
    if (yard.switchOn) {
      final v = t.value;
      final hum = Paint()
        ..color = Color.fromRGBO(255, 230, 160, 0.25 + 0.15 * math.sin(v * 6).abs())
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;
      for (var k = 0; k < 2; k++) {
        c.drawArc(Rect.fromCenter(center: Offset(tk.right + 4, tk.center.dy), width: 14.0 + 8 * k, height: 24.0 + 10 * k), -0.8, 1.6, false, hum);
      }
    }
  }

  void _pillar(Canvas c) {
    final g = geo;
    final y = yard;
    final p = g.pillar;
    // The cabinet: grey steel, the door swung open to the left.
    final body = RRect.fromRectAndRadius(p, const Radius.circular(5));
    c.drawRRect(body.shift(const Offset(3, 4)), Paint()..color = const Color(0x66000000));
    c.drawRRect(body, Paint()..shader = const LinearGradient(colors: [Color(0xFF8D969C), Color(0xFFB9C1C6), Color(0xFF7D868C)]).createShader(p));
    final inner = p.deflate(6);
    c.drawRRect(RRect.fromRectAndRadius(inner, const Radius.circular(3)), Paint()..color = const Color(0xFF2A3036));
    final door = Path()
      ..moveTo(p.left, p.top + 4)
      ..lineTo(p.left - 22, p.top + 16)
      ..lineTo(p.left - 22, p.bottom - 14)
      ..lineTo(p.left, p.bottom - 2)
      ..close();
    c.drawPath(door, Paint()..color = const Color(0xFF6E777D));
    c.drawPath(door, Paint()
      ..color = const Color(0xFF3E454B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2);
    // The danger plate on the door.
    final plate = Rect.fromLTWH(p.left - 19, p.top + 40, 15, 22);
    c.drawRect(plate, Paint()..color = const Color(0xFFF2F2EE));
    c.drawPath(
        Path()
          ..moveTo(plate.center.dx + 2, plate.top + 3)
          ..lineTo(plate.center.dx - 3, plate.center.dy + 1)
          ..lineTo(plate.center.dx + 1, plate.center.dy + 1)
          ..lineTo(plate.center.dx - 2, plate.bottom - 3),
        Paint()
          ..color = const Color(0xFFC62828)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6);

    // The LT main switch.
    final sb = RRect.fromRectAndRadius(g.switchBox, const Radius.circular(5));
    c.drawRRect(sb, Paint()..shader = const LinearGradient(colors: [Color(0xFF6F7880), Color(0xFFA8B1B7), Color(0xFF636C74)]).createShader(g.switchBox));
    c.drawRRect(sb, Paint()
      ..color = const Color(0xFF1E2226)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4);
    _label(c, 'LT MAIN', Offset(g.switchBox.center.dx - 4, g.switchBox.top + 11), 8.5, const Color(0xFF15191C));
    _label(c, 'ON', Offset(g.switchBox.left + 16, g.switchBox.top + 32), 9.5, y.switchOn ? const Color(0xFFB0261C) : const Color(0xFF3E454B));
    _label(c, 'OFF', Offset(g.switchBox.left + 18, g.switchBox.bottom - 14), 9.5, y.switchOn ? const Color(0xFF3E454B) : const Color(0xFF1E6B34));
    final pivot = g.handlePivot;
    final ang = y.switchOn ? -0.95 : 0.95;
    final tip = pivot + Offset(-math.cos(ang) * 28, math.sin(ang) * 28);
    c.drawLine(pivot, tip, Paint()
      ..color = const Color(0xFF15181B)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round);
    c.drawCircle(tip, 6.5, Paint()..color = const Color(0xFFC8302A));
    c.drawCircle(pivot, 5, Paint()..color = const Color(0xFF2B3035));
    // The switch feeds the bars.
    c.drawLine(Offset(g.switchBox.right, g.barTop + 4), Offset(g.barX(3), g.barTop + 4), Paint()
      ..color = const Color(0xFF111111)
      ..strokeWidth = 3);

    // The permit, hung on the switch while the work is on.
    if (y.ptw) {
      final tag = Rect.fromLTWH(g.switchBox.left + 2, g.switchBox.bottom + 8, 54, 34);
      c.drawLine(Offset(g.switchBox.left + 16, g.switchBox.bottom - 4), Offset(tag.center.dx, tag.top), Paint()
        ..color = const Color(0xFF333333)
        ..strokeWidth = 1);
      c.drawRRect(RRect.fromRectAndRadius(tag, const Radius.circular(3)), Paint()..color = const Color(0xFFFFF4D2));
      c.drawRRect(
          RRect.fromRectAndRadius(tag, const Radius.circular(3)),
          Paint()
            ..color = const Color(0xFFB0261C)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6);
      _label(c, 'PTW', Offset(tag.center.dx, tag.top + 10), 10, const Color(0xFFB0261C));
      _label(c, 'MEN AT WORK', Offset(tag.center.dx, tag.top + 24), 6.5, const Color(0xFF333333));
    }

    // The bars with their lugs (a lug = a service connection on that phase).
    for (var i = 0; i < 4; i++) {
      final x = g.barX(i);
      final bar = Rect.fromLTRB(x - 4, g.barTop, x + 4, g.barBottom);
      c.drawRect(bar, Paint()..shader = LinearGradient(colors: [const Color(0xFFB87333), const Color(0xFFE2A66A), const Color(0xFFA0602A)]).createShader(bar));
      c.drawRect(Rect.fromLTWH(x - 5, g.barTop - 12, 10, 10), Paint()..color = m4PhaseBalanceWireColors[i]);
      _label(c, m4PhaseBalanceWireNames[i], Offset(x, g.barTop - 7), 7.5, i == 1 ? const Color(0xFF3A2A00) : Colors.white);
      if (i < 3) {
        final n = y.lugs[i];
        for (var k = 0; k < n; k++) {
          final ly = g.barTop + 10 + 10.5 * k;
          if (ly > g.barBottom - 6) break;
          c.drawRect(Rect.fromLTWH(x + 3, ly - 2, 9, 4), Paint()..color = const Color(0xFFC9CDD1));
          c.drawLine(Offset(x + 12, ly), Offset(x + 13, ly + 4), Paint()
            ..color = m4PhaseBalanceWireColors[i]
            ..strokeWidth = 2);
        }
      }
      // The outgoing cable down out of the pillar.
      c.drawLine(Offset(x, g.barBottom), Offset(x, p.bottom - 4), Paint()
        ..color = const Color(0xFF0E0E0E)
        ..strokeWidth = 7);
      c.drawLine(Offset(x, g.barBottom), Offset(x, p.bottom - 4), Paint()
        ..color = m4PhaseBalanceWireColors[i]
        ..strokeWidth = 4.5);
    }
    // The glint on the bars just after the connections were moved.
    if (y.shiftTok > 0) {
      final glint = Paint()..color = const Color(0x33FFF3C0);
      c.drawRect(Rect.fromLTRB(g.barX(0) - 8, g.barTop, g.barX(2) + 16, g.barBottom), glint);
    }

    // The earthing set: a clamp on every bar, the lead to the rod.
    if (y.earthOn) {
      final ey = g.barTop + 2;
      final lead = Paint()
        ..color = const Color(0xFF2E9A3E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      c.drawLine(Offset(g.barX(0), ey), Offset(g.barX(3), ey), lead);
      for (var i = 0; i < 4; i++) {
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(g.barX(i), ey), width: 12, height: 10), const Radius.circular(2)), Paint()..color = const Color(0xFFE7C33A));
      }
      c.drawPath(
          Path()
            ..moveTo(g.barX(3), ey)
            ..quadraticBezierTo(g.pillar.right + 14, ey + 60, g.earthRod.dx, g.earthRod.dy - 6),
          lead);
      c.drawRect(Rect.fromLTWH(g.earthRod.dx - 2, g.earthRod.dy - 8, 4, 16), Paint()..color = const Color(0xFF9AA1A7));
    }

    // The tong tester round a cable.
    final on = y.clampOn;
    if (on != null) {
      final at = g.clampAt(on);
      final jaw = Paint()
        ..color = const Color(0xFFE53935)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      c.drawCircle(at, 9, jaw);
      final body = Rect.fromLTWH(at.dx - 9, at.dy + 8, 18, 34);
      c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(4)), Paint()..color = const Color(0xFFFFC233));
      c.drawRect(Rect.fromLTWH(body.left + 3, body.top + 4, body.width - 6, 9), Paint()..color = const Color(0xFF9FB89A));
    }
  }

  void _label(Canvas c, String s, Offset centre, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontFamily: 'Roboto', fontSize: size, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.2)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(M4PhaseBalancePainter old) => old.geo != geo || old.yard != yard || old.seed != seed;
}

/// The flash off the bars when a spanner goes on them live (the deadly
/// moment, in colour over the frozen scene).
class M4PhaseBalanceArcPainter extends CustomPainter {
  const M4PhaseBalanceArcPainter({required this.geo, required this.v});
  final M4PhaseBalanceGeo geo;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final at = Offset(geo.barX(1) + 13, geo.barTop + 50);
    final flick = v < 0.5 ? (0.65 + 0.35 * math.sin(v * 60).abs()) : (1 - (v - 0.5) * 1.2).clamp(0.4, 1.0);
    final r = 26 + 70 * Curves.easeOut.transform(v.clamp(0.0, 1.0));
    c.drawCircle(
        at,
        r,
        Paint()
          ..shader = RadialGradient(colors: [Color.fromRGBO(255, 250, 220, 0.95 * flick), Color.fromRGBO(140, 170, 255, 0.5 * flick), const Color(0x00FFC24A)])
              .createShader(Rect.fromCircle(center: at, radius: r)));
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
  bool shouldRepaint(M4PhaseBalanceArcPainter old) => old.v != v || old.geo != geo;
}
