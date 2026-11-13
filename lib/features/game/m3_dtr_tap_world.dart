import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The drawn world of lesson 3.6 কাজ 2 "অফ-লোড ট্যাপ" (m3_dtr_tap.dart): a
// village DTR on an H-pole structure at dusk — the 11 kV line on the top arm,
// the AB switch (its operating handle low on the left pole), the three DO
// fuses, the tank on its platform with the off-load tap changer dial and the
// nameplate on the front, the LT box with its lever on the right pole, the LT
// line to the last house of the para (its lamp burns a plain steady light
// until the voltmeter has been read — it never gives the reading away — then
// dim when low, bright when right; dark when off) and the consumer's meter board on
// its wall. Code-drawn, gradients, no bitmaps. Design space 360 wide; the
// ground sits [M3DtrTapGeo.floorUp] above the bottom so the controls sit on it.

/// Where things are in the scene (design px, 360 wide).
@immutable
class M3DtrTapGeo {
  const M3DtrTapGeo._(this.height, this.groundY);

  factory M3DtrTapGeo.forScene(double height, double inset) => M3DtrTapGeo._(height, height - floorUp - inset * 0.5);

  final double height;

  /// The ground line.
  final double groundY;

  static const double floorUp = 104;
  static const double leftPole = 74;
  static const double rightPole = 208;

  /// The three HT phases (left → right).
  static const List<double> htX = [114, 140, 166];

  double get poleTop => groundY - 500;
  double get topArm => groundY - 486;
  double get abArm => groundY - 452;
  double get doTop => groundY - 420;
  double get doHinge => groundY - 372;
  double get bushTop => groundY - 330;

  /// The portable earthing set's clamp bar on the HT drops.
  double get earthBarY => groundY - 352;
  Offset get spike => Offset(26, groundY);

  Rect get tank => Rect.fromLTRB(96, groundY - 292, 186, groundY - 198);
  double get platY => groundY - 192;

  /// The off-load tap changer dial on the tank front (tap to work it).
  Offset get dial => Offset(120, groundY - 246);
  Rect get dialHit => Rect.fromCenter(center: dial, width: 48, height: 48);
  Rect get plate => Rect.fromLTWH(146, groundY - 258, 30, 22);

  /// The AB switch's operating handle, low on the left pole.
  Offset get abPivot => Offset(leftPole + 2, groundY - 172);
  Rect get abHit => Rect.fromLTWH(44, groundY - 222, 66, 96);

  /// The three DO fuses (tap: drop them with the operating rod / put them back).
  Rect get doHit => Rect.fromLTRB(96, groundY - 438, 186, groundY - 358);

  /// The LT box and its lever on the right pole.
  Rect get ltBox => Rect.fromLTWH(rightPole - 18, groundY - 212, 40, 54);
  Offset get ltPivot => Offset(ltBox.center.dx, ltBox.top + 30);
  Rect get ltHit => ltBox.inflate(12);

  /// The last house and the consumer's meter board on its wall.
  Rect get house => Rect.fromLTRB(256, groundY - 116, 360, groundY);
  Rect get meterBoard => Rect.fromLTWH(306, groundY - 96, 30, 40);
  Rect get houseHit => Rect.fromLTRB(250, groundY - 170, 360, groundY);
  Offset get window => Offset(276, groundY - 66);

  /// Where the tester's lamp shows (by the HT bushings).
  Offset get testerAt => Offset(tank.left - 4, bushTop - 40);

  /// Where the lineman stands: by the AB handle, clear of the guide's corner.
  Rect get trainee => Rect.fromLTWH(0, groundY - 140, 66, 140);

  @override
  bool operator ==(Object other) => other is M3DtrTapGeo && other.height == height && other.groundY == groundY;

  @override
  int get hashCode => Object.hash(height, groundY);
}

/// The lamp in the house: dark (no supply), lit (supplied, not read yet: the
/// same plain light on a low and a right site), dim (read low), bright (read
/// right).
enum M3DtrTapLamp { dark, lit, dim, bright }

/// What the structure shows now.
@immutable
class M3DtrTapState {
  const M3DtrTapState({
    required this.abClosed,
    required this.doIn,
    required this.ltOn,
    required this.locked,
    required this.earthed,
    required this.pos,
    required this.pinOut,
    required this.lamp,
  });

  final bool abClosed;
  final bool doIn;
  final bool ltOn;
  final bool locked;
  final bool earthed;

  /// The tap position on the dial (1..5).
  final int pos;
  final bool pinOut;
  final M3DtrTapLamp lamp;

  bool get htLive => abClosed && doIn;

  @override
  bool operator ==(Object other) =>
      other is M3DtrTapState &&
      other.abClosed == abClosed &&
      other.doIn == doIn &&
      other.ltOn == ltOn &&
      other.locked == locked &&
      other.earthed == earthed &&
      other.pos == pos &&
      other.pinOut == pinOut &&
      other.lamp == lamp;

  @override
  int get hashCode => Object.hash(abClosed, doIn, ltOn, locked, earthed, pos, pinOut, lamp);
}

/// The dial's handle angle for tap position [p] (1..5), canvas radians.
double m3DtrTapAngle(int p) => -2.45 + (p - 1) / 4 * (2.45 - 0.69);

/// The yard: sky, the H-pole structure with the DTR, the LT line, the house.
/// [t] (seconds) flickers the low-voltage lamp while awake.
class M3DtrTapYardPainter extends CustomPainter {
  M3DtrTapYardPainter({required this.geo, required this.s, required this.t, required this.seed}) : super(repaint: t);

  final M3DtrTapGeo geo;
  final M3DtrTapState s;
  final ValueListenable<double> t;
  final int seed;

  static const _steel = Color(0xFF6E7488);
  static const _steelDark = Color(0xFF4A4F60);
  static const _porc = Color(0xFFB8664A);
  static const _porcDark = Color(0xFF8A4632);
  static const _tank = Color(0xFF7D8CA3);
  static const _tankDark = Color(0xFF5E6B80);
  static const _wire = Color(0xFF23252E);

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    // Dusk sky and the far village.
    c.drawRect(
        Rect.fromLTWH(0, 0, w, g.groundY),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF34406E), Color(0xFF8A6E8E), Color(0xFFF0A86A)],
            stops: [0, 0.6, 1],
          ).createShader(Rect.fromLTWH(0, 0, w, g.groundY)));
    final sun = Offset(318, g.groundY - 150);
    c.drawCircle(sun, 52, Paint()..shader = const RadialGradient(colors: [Color(0x88FFD9A0), Color(0x00FFD9A0)]).createShader(Rect.fromCircle(center: sun, radius: 52)));
    final rnd = math.Random(seed);
    final horizon = g.groundY - 40;
    final tree = Paint()..color = const Color(0xFF3B4A3A);
    for (var x = -10.0; x < w + 20; x += 20 + rnd.nextDouble() * 20) {
      final r = 9 + rnd.nextDouble() * 9;
      c.drawCircle(Offset(x, horizon - r * 0.5), r, tree);
    }
    c.drawRect(Rect.fromLTWH(0, horizon - 2, w, g.groundY - horizon + 2), Paint()..color = const Color(0xFF4F6A3E));
    // The ground: a dusty path.
    final ground = Rect.fromLTRB(0, g.groundY, w, size.height);
    c.drawRect(ground, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFB08A60), Color(0xFF7E6244)]).createShader(ground));
    c.drawLine(Offset(0, g.groundY), Offset(w, g.groundY), Paint()
      ..color = const Color(0xFF6A5236)
      ..strokeWidth = 2);

    _ltLine(c, w);
    _house(c);
    _structure(c);
    _earthing(c);
  }

  // --- the structure ----------------------------------------------------------
  void _pole(Canvas c, double x) {
    final top = geo.poleTop, bot = geo.groundY + 2;
    final p = Path()
      ..moveTo(x - 4, top)
      ..lineTo(x + 4, top)
      ..lineTo(x + 6, bot)
      ..lineTo(x - 6, bot)
      ..close();
    c.drawPath(p, Paint()..shader = const LinearGradient(colors: [Color(0xFFB9B2A4), Color(0xFF8D877B)]).createShader(Rect.fromLTRB(x - 6, top, x + 6, bot)));
  }

  void _chan(Canvas c, double x0, double x1, double y, [double h = 6]) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(x0, y - h / 2, x1, y + h / 2), const Radius.circular(1.5)), Paint()..color = _steel);
    c.drawRect(Rect.fromLTRB(x0, y + h * 0.1, x1, y + h / 2), Paint()..color = _steelDark);
  }

  void _pin(Canvas c, double x, double y) {
    for (var k = 0; k < 3; k++) {
      final yy = y - 3 - k * 4.0;
      c.drawOval(Rect.fromCenter(center: Offset(x, yy), width: 11.0 - k * 2, height: 4), Paint()..color = k.isEven ? _porc : _porcDark);
    }
    c.drawCircle(Offset(x, y - 14), 2, Paint()..color = const Color(0xFFC9A060));
  }

  Paint get _wireP => Paint()
    ..color = _wire
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8
    ..strokeCap = StrokeCap.round;

  void _structure(Canvas c) {
    final g = geo;
    const lp = M3DtrTapGeo.leftPole, rp = M3DtrTapGeo.rightPole;
    // The 11 kV line arriving from the upper left.
    for (var k = 0; k < 3; k++) {
      final hx = M3DtrTapGeo.htX[k];
      c.drawPath(
          Path()
            ..moveTo(-10, g.topArm - 70 - k * 8)
            ..quadraticBezierTo(50, g.topArm - 30 - k * 4, hx, g.topArm - 14),
          _wireP);
    }
    _pole(c, lp);
    _pole(c, rp);
    _chan(c, lp - 10, rp + 8, g.topArm);
    _chan(c, lp - 8, rp + 8, g.abArm);
    _chan(c, lp - 8, rp + 8, g.doTop + 6);
    _chan(c, lp - 10, rp + 10, g.platY, 8);
    _chan(c, lp, rp, g.groundY - 90, 5);
    // Cross bracing under the platform.
    final brace = Paint()
      ..color = _steel
      ..strokeWidth = 2.4;
    c.drawLine(Offset(lp, g.groundY - 90), Offset(rp, g.platY + 4), brace);
    c.drawLine(Offset(rp, g.groundY - 90), Offset(lp, g.platY + 4), brace);
    // Anti-climb wire and the danger plate on the left pole.
    final barb = Paint()
      ..color = const Color(0xFF4E4A46)
      ..strokeWidth = 1;
    for (var k = 0; k < 3; k++) {
      for (final px in [lp, rp]) {
        c.drawLine(Offset(px - 9, g.groundY - 236 - k * 4.0), Offset(px + 9, g.groundY - 234 - k * 4.0), barb);
      }
    }
    final dp = Rect.fromLTWH(lp - 9, g.groundY - 130, 18, 22);
    c.drawRRect(RRect.fromRectAndRadius(dp, const Radius.circular(2)), Paint()..color = const Color(0xFFF2EFE8));
    c.drawRect(Rect.fromLTWH(dp.left, dp.top, dp.width, 5), Paint()..color = const Color(0xFFC8302A));
    _bolt(c, Offset(dp.center.dx, dp.center.dy + 3), 6, const Color(0xFFC8302A));

    // Pins, AB switch, DO fuses, the drops to the HT bushings.
    final ab = s.abClosed;
    for (var k = 0; k < 3; k++) {
      final hx = M3DtrTapGeo.htX[k];
      _pin(c, hx, g.topArm - 2);
      final abL = Offset(hx - 8, g.abArm - 14), abR = Offset(hx + 8, g.abArm - 14);
      c.drawPath(
          Path()
            ..moveTo(hx, g.topArm - 16)
            ..quadraticBezierTo(hx - 14, g.topArm - 4, abL.dx, abL.dy),
          _wireP);
      _pin(c, abL.dx, g.abArm - 2);
      _pin(c, abR.dx, g.abArm - 2);
      // The blade: across (closed) or swung up (open).
      c.save();
      c.translate(abL.dx, abL.dy);
      c.rotate(ab ? 0 : -1.15);
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-1, -1.6, 18, 3.2), const Radius.circular(1.5)), Paint()..color = const Color(0xFFDDE2EA));
      c.restore();
      c.drawCircle(abL, 2, Paint()..color = const Color(0xFF7E8796));
      // AB right post → the DO top contact.
      c.drawPath(
          Path()
            ..moveTo(abR.dx, abR.dy)
            ..quadraticBezierTo(hx + 12, g.doTop - 16, hx + 2, g.doTop - 4),
          _wireP);
      // The DO: insulator + the barrel, hinged at the bottom (dropped: hangs down).
      final ins = Rect.fromLTWH(hx - 9, g.doTop - 6, 5, 40);
      c.drawRRect(RRect.fromRectAndRadius(ins, const Radius.circular(2)), Paint()..color = _porcDark);
      for (var j = 0; j < 4; j++) {
        c.drawOval(Rect.fromCenter(center: Offset(ins.center.dx, ins.top + 5 + j * 9.0), width: 8, height: 3), Paint()..color = _porc);
      }
      final hinge = Offset(hx + 2, g.doHinge);
      c.save();
      c.translate(hinge.dx, hinge.dy);
      c.rotate(s.doIn ? 0 : 2.5);
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-3, -44, 6, 44), const Radius.circular(2.5)), Paint()..color = const Color(0xFF9AA2B4));
      c.drawRect(const Rect.fromLTWH(-3, -44, 2, 44), Paint()..color = const Color(0xFFC9CFDA));
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-3.5, -47, 7, 5), const Radius.circular(1.5)), Paint()..color = const Color(0xFFC9A060));
      c.restore();
      c.drawCircle(hinge, 2, Paint()..color = const Color(0xFF5A5F70));
      // The drop to the HT bushing.
      c.drawPath(
          Path()
            ..moveTo(hinge.dx, hinge.dy)
            ..quadraticBezierTo(hx + 8, hinge.dy + 16, hx, g.bushTop - 4),
          _wireP);
    }
    // The AB operating rod down the left pole to its handle.
    final rod = Paint()
      ..color = const Color(0xFF5A5F70)
      ..strokeWidth = 2.4;
    c.drawLine(Offset(M3DtrTapGeo.htX[2] + 10, g.abArm + 6), Offset(lp + 2, g.abArm + 6), rod);
    c.drawLine(Offset(lp + 2, g.abArm + 6), Offset(g.abPivot.dx, g.abPivot.dy), rod);
    _abHandle(c);

    // The platform skid and the tank.
    final tk = g.tank;
    // Conservator + breather on the left.
    final cons = Rect.fromLTWH(tk.left - 4, tk.top - 34, 46, 16);
    c.drawLine(Offset(cons.left + 8, cons.bottom), Offset(cons.left + 8, tk.top), Paint()
      ..color = _steelDark
      ..strokeWidth = 2.4);
    c.drawRRect(RRect.fromRectAndRadius(cons, const Radius.circular(8)), Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_tank, _tankDark]).createShader(cons));
    final br = Rect.fromLTWH(tk.left - 14, tk.top - 20, 9, 22);
    c.drawRRect(RRect.fromRectAndRadius(br, const Radius.circular(3)), Paint()..color = const Color(0xCCDDEBFF));
    for (var k = 0; k < 6; k++) {
      c.drawCircle(Offset(br.left + 2.5 + (k % 2) * 4, br.top + 4 + (k ~/ 2) * 6.0), 1.6, Paint()..color = const Color(0xFF2F6FE0));
    }
    // Radiators.
    for (final x0 in [tk.left - 10, tk.right]) {
      final rr = Rect.fromLTWH(x0, tk.top + 14, 10, tk.height - 20);
      c.drawRect(rr, Paint()..color = _tankDark);
      for (var k = 0; k < 3; k++) {
        c.drawRect(Rect.fromLTWH(rr.left + 1 + k * 3.0, rr.top + 2, 1.6, rr.height - 4), Paint()..color = const Color(0xFF8A97AC));
      }
    }
    c.drawRRect(RRect.fromRectAndRadius(tk, const Radius.circular(4)), Paint()..shader = const LinearGradient(colors: [Color(0xFF93A2B8), _tank, _tankDark]).createShader(tk));
    c.drawRect(Rect.fromLTWH(tk.left - 4, tk.top - 4, tk.width + 8, 6), Paint()..color = const Color(0xFF9AA3B6));
    _chan(c, tk.left - 6, tk.right + 6, tk.bottom + 2, 4);
    // HT bushings (tall) on the lid, LT bushings (small) to the right.
    for (final hx in M3DtrTapGeo.htX) {
      final bt = Rect.fromLTRB(hx - 3, g.bushTop, hx + 3, tk.top - 4);
      c.drawRRect(RRect.fromRectAndRadius(bt, const Radius.circular(2)), Paint()..color = _porcDark);
      for (var k = 0; k < 5; k++) {
        c.drawOval(Rect.fromCenter(center: Offset(hx, bt.top + 5 + k * 6.5), width: 10 - k * 0.4, height: 3.4), Paint()..color = _porc);
      }
      c.drawRect(Rect.fromLTWH(hx - 1.2, g.bushTop - 5, 2.4, 5), Paint()..color = const Color(0xFFC9A060));
    }
    final ltX = [tk.right - 22, tk.right - 15, tk.right - 8];
    for (final lx in [tk.right - 29, ...ltX]) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(lx - 1.8, tk.top - 16, lx + 1.8, tk.top - 4), const Radius.circular(1)), Paint()..color = _porcDark);
      c.drawOval(Rect.fromCenter(center: Offset(lx, tk.top - 8), width: 6, height: 2.6), Paint()..color = _porc);
    }
    // The tap changer dial and the nameplate on the front.
    m3DtrTapPaintDial(c, g.dial, 13, s.pos, s.pinOut);
    final pl = g.plate;
    c.drawRRect(RRect.fromRectAndRadius(pl, const Radius.circular(2)), Paint()..color = const Color(0xFFD5DAE3));
    for (var k = 0; k < 4; k++) {
      c.drawRect(Rect.fromLTWH(pl.left + 3, pl.top + 3 + k * 4.5, k == 0 ? 18 : 24 - k * 3, 2), Paint()..color = const Color(0xFF7E8796));
    }
    // The LT cable from the bushings down to the LT box, and up to the LT arm.
    final lt = Paint()
      ..color = _wire
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    c.drawPath(
        Path()
          ..moveTo(tk.right - 18, tk.top - 16)
          ..quadraticBezierTo(rp + 6, tk.top - 30, g.ltBox.center.dx + 4, g.ltBox.top),
        lt);
    _ltBox(c);
  }

  void _abHandle(Canvas c) {
    final g = geo;
    final pv = g.abPivot;
    final box = Rect.fromCenter(center: pv, width: 12, height: 18);
    c.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(2.5)), Paint()..color = const Color(0xFF3A3F55));
    // Up = closed (ON), down = open (OFF).
    final ang = s.abClosed ? -0.75 : 0.75;
    final tip = pv + Offset(math.cos(ang) * 26, math.sin(ang) * 26);
    c.drawLine(pv, tip, Paint()
      ..color = const Color(0xFF1B1E2C)
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round);
    c.drawCircle(tip, 4.5, Paint()..color = const Color(0xFFC8302A));
    c.drawCircle(pv, 3, Paint()..color = const Color(0xFF5A5F70));
    _label(c, 'ON', pv + const Offset(18, -26), 7.5, s.abClosed ? const Color(0xFFFFE6A0) : const Color(0x99FFFFFF));
    _label(c, 'OFF', pv + const Offset(19, 26), 7.5, s.abClosed ? const Color(0x99FFFFFF) : const Color(0xFFA8F0B8));
    if (s.locked) {
      final at = pv + const Offset(1, 16);
      c.drawArc(Rect.fromCenter(center: at + const Offset(0, -5), width: 9, height: 11), math.pi, math.pi, false, Paint()
        ..color = const Color(0xFF9AA1A7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: at + const Offset(0, 2), width: 12, height: 10), const Radius.circular(2)), Paint()..color = const Color(0xFFD9A441));
      final tag = Rect.fromLTWH(at.dx - 15, at.dy + 9, 32, 24);
      c.drawLine(at + const Offset(0, 7), tag.topCenter, Paint()
        ..color = const Color(0xFF333333)
        ..strokeWidth = 1);
      c.drawRRect(RRect.fromRectAndRadius(tag, const Radius.circular(2.5)), Paint()..color = const Color(0xFFD7261E));
      _label(c, 'DANGER', Offset(tag.center.dx, tag.top + 6.5), 6, Colors.white);
      _label(c, 'DO NOT', Offset(tag.center.dx, tag.top + 13), 5.4, Colors.white);
      _label(c, 'OPERATE', Offset(tag.center.dx, tag.top + 19), 5.4, Colors.white);
    }
  }

  void _ltBox(Canvas c) {
    final g = geo;
    final b = g.ltBox;
    c.drawRRect(RRect.fromRectAndRadius(b.shift(const Offset(2, 3)), const Radius.circular(4)), Paint()..color = const Color(0x55000000));
    c.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(4)), Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8A9AB4), Color(0xFF5F6E88)]).createShader(b));
    c.drawRect(Rect.fromLTWH(b.left, b.top, b.width, 7), Paint()..color = const Color(0xFF4E5C76));
    _label(c, 'LT', Offset(b.center.dx, b.top + 13), 8, const Color(0xFF1B2030));
    final pv = g.ltPivot;
    final ang = s.ltOn ? -0.8 : 0.8;
    final tip = pv + Offset(math.cos(ang) * 15, math.sin(ang) * 15);
    c.drawLine(pv, tip, Paint()
      ..color = const Color(0xFF1B1E2C)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round);
    c.drawCircle(tip, 3.6, Paint()..color = const Color(0xFFC8302A));
    c.drawCircle(pv, 2.6, Paint()..color = const Color(0xFF3A3F55));
    _label(c, s.ltOn ? 'ON' : 'OFF', Offset(b.center.dx - 9, b.bottom - 8), 7, s.ltOn ? const Color(0xFF7A1A12) : const Color(0xFF0E4A22));
  }

  // --- the LT line and the house ----------------------------------------------
  void _ltLine(Canvas c, double w) {
    final g = geo;
    const rp = M3DtrTapGeo.rightPole;
    final armY = g.groundY - 300;
    // The LT cable up the right pole to the LT arm, and the line across.
    c.drawLine(Offset(g.ltBox.center.dx - 6, g.ltBox.top), Offset(rp + 14, armY + 4), Paint()
      ..color = _wire
      ..strokeWidth = 3.4);
    _chan(c, rp - 4, rp + 52, armY, 4);
    for (var k = 0; k < 4; k++) {
      final x = rp + 10 + k * 13.0;
      c.drawCircle(Offset(x, armY - 4), 2.4, Paint()..color = const Color(0xFFE8E0D0));
      c.drawPath(
          Path()
            ..moveTo(x, armY - 5)
            ..quadraticBezierTo(x + 80, armY + 18 + k * 2, w + 10, armY - 10 + k * 3),
          _wireP..strokeWidth = 1.3);
    }
    // The service drop to the house.
    c.drawPath(
        Path()
          ..moveTo(rp + 36, armY - 4)
          ..quadraticBezierTo(g.house.left + 10, g.house.top - 40, g.meterBoard.center.dx, g.house.top - 18),
        _wireP..strokeWidth = 1.4);
  }

  void _house(Canvas c) {
    final g = geo;
    final h = g.house;
    // Wall, roof, door, window.
    c.drawRect(h, Paint()..shader = const LinearGradient(colors: [Color(0xFFD9B98A), Color(0xFFBF9C6C)]).createShader(h));
    final roof = Path()
      ..moveTo(h.left - 8, h.top + 4)
      ..lineTo(h.left + 10, h.top - 30)
      ..lineTo(h.right + 4, h.top - 30)
      ..lineTo(h.right + 4, h.top + 4)
      ..close();
    c.drawPath(roof, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8E4E36), Color(0xFF6E3626)]).createShader(Rect.fromLTRB(h.left, h.top - 30, h.right, h.top + 4)));
    c.drawRect(Rect.fromLTWH(h.left + 46, h.bottom - 54, 22, 54), Paint()..color = const Color(0xFF6A4630));
    final win = Rect.fromCenter(center: g.window, width: 24, height: 22);
    final flick = s.lamp == M3DtrTapLamp.dim ? 0.75 + 0.25 * math.sin(t.value * 23).abs() : 1.0;
    final (Color glass, double glow) = switch (s.lamp) {
      M3DtrTapLamp.dark => (const Color(0xFF2A2E3A), 0.0),
      M3DtrTapLamp.lit => (const Color(0xFFF0CF86), 0.42),
      M3DtrTapLamp.dim => (Color.fromRGBO(196, 120, 52, flick), 0.28 * flick),
      M3DtrTapLamp.bright => (const Color(0xFFFFE89A), 0.6),
    };
    if (glow > 0) {
      c.drawCircle(g.window, 40, Paint()..shader = RadialGradient(colors: [Color.fromRGBO(255, 214, 120, glow), const Color(0x00FFD678)]).createShader(Rect.fromCircle(center: g.window, radius: 40)));
    }
    c.drawRect(win, Paint()..color = glass);
    c.drawRect(
        win,
        Paint()
          ..color = const Color(0xFF5A3C28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    c.drawLine(win.topCenter, win.bottomCenter, Paint()
      ..color = const Color(0xFF5A3C28)
      ..strokeWidth = 1.6);
    // The meter board.
    final mb = g.meterBoard;
    c.drawRRect(RRect.fromRectAndRadius(mb, const Radius.circular(3)), Paint()..color = const Color(0xFF5E4430));
    final meter = Rect.fromLTWH(mb.left + 5, mb.top + 5, mb.width - 10, 18);
    c.drawRRect(RRect.fromRectAndRadius(meter, const Radius.circular(2)), Paint()..color = const Color(0xFFE8E4D8));
    c.drawRect(Rect.fromLTWH(meter.left + 3, meter.top + 4, meter.width - 6, 6), Paint()..color = s.lamp == M3DtrTapLamp.dark ? const Color(0xFF3A4A3A) : const Color(0xFF8FD08A));
    c.drawRect(Rect.fromLTWH(mb.left + 7, mb.bottom - 13, mb.width - 14, 8), Paint()..color = const Color(0xFF2B2B2B));
  }

  // --- the earthing set --------------------------------------------------------
  void _earthing(Canvas c) {
    if (!s.earthed) return;
    final g = geo;
    final y = g.earthBarY;
    final bar = Rect.fromLTRB(M3DtrTapGeo.htX[0] - 8, y - 2, M3DtrTapGeo.htX[2] + 8, y + 3);
    // The lead to the spike in the ground.
    final lead = Path()
      ..moveTo(bar.left, bar.center.dy)
      ..cubicTo(40, y + 40, 10, g.groundY - 120, g.spike.dx, g.spike.dy - 14);
    c.drawPath(lead, Paint()
      ..color = const Color(0xFF2E9A48)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
    c.drawPath(
        lead,
        Paint()
          ..color = const Color(0xFFE8D23A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6);
    c.drawRRect(RRect.fromRectAndRadius(bar, const Radius.circular(2)), Paint()..color = const Color(0xFFC87533));
    for (final hx in M3DtrTapGeo.htX) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(hx - 2.5, y - 8, 5, 8), const Radius.circular(1.5)), Paint()..color = const Color(0xFFB9C0CE));
    }
    c.drawRect(Rect.fromLTWH(g.spike.dx - 2, g.spike.dy - 18, 4, 22), Paint()..color = const Color(0xFF9AA2B4));
    c.drawRect(Rect.fromLTWH(g.spike.dx - 5, g.spike.dy - 16, 10, 4), Paint()..color = const Color(0xFFC9A060));
  }

  void _bolt(Canvas c, Offset at, double r, Color col) {
    c.drawPath(
        Path()
          ..moveTo(at.dx + r * 0.2, at.dy - r)
          ..lineTo(at.dx - r * 0.5, at.dy + r * 0.1)
          ..lineTo(at.dx, at.dy + r * 0.1)
          ..lineTo(at.dx - r * 0.2, at.dy + r)
          ..lineTo(at.dx + r * 0.5, at.dy - r * 0.15)
          ..lineTo(at.dx, at.dy - r * 0.15)
          ..close(),
        Paint()..color = col);
  }

  void _label(Canvas c, String s, Offset centre, double size, Color color) => m3DtrTapLabel(c, s, centre, size, color);

  @override
  bool shouldRepaint(M3DtrTapYardPainter old) => old.geo != geo || old.s != s || old.seed != seed;
}

void m3DtrTapLabel(Canvas c, String s, Offset centre, double size, Color color) {
  final tp = TextPainter(
    text: TextSpan(text: s, style: TextStyle(fontFamily: 'Roboto', fontSize: size, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.2)),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
}

/// The off-load tap changer dial: five numbered holes on an arc, the handle
/// at tap [pos], its red locking pin in the hole (lifted when [pinOut]).
void m3DtrTapPaintDial(Canvas c, Offset at, double r, int pos, bool pinOut) {
  c.drawCircle(at + Offset(r * 0.1, r * 0.14), r * 1.3, Paint()..color = const Color(0x4414101E));
  c.drawCircle(at, r * 1.3, Paint()..color = const Color(0xFFB9C0CE));
  c.drawCircle(at, r * 1.12, Paint()..color = const Color(0xFF8E96A8));
  for (var k = 0; k < 6; k++) {
    final a = k / 6 * math.pi * 2 + 0.3;
    c.drawCircle(at + Offset(math.cos(a), math.sin(a)) * r * 1.21, r * 0.055, Paint()..color = const Color(0xFF5A6278));
  }
  for (var p = 1; p <= 5; p++) {
    final a = m3DtrTapAngle(p);
    final hole = at + Offset(math.cos(a), math.sin(a)) * r * 0.78;
    c.drawCircle(hole, r * 0.1, Paint()..color = const Color(0xFF14161F));
    if (r > 30) m3DtrTapLabel(c, '$p', at + Offset(math.cos(a), math.sin(a)) * r * 1.0, r * 0.17, const Color(0xFF1B1E2C));
  }
  final a = m3DtrTapAngle(pos);
  final tip = at + Offset(math.cos(a), math.sin(a)) * r * 0.95;
  c.drawLine(at + Offset(r * 0.04, r * 0.08), tip + Offset(r * 0.04, r * 0.08), Paint()
    ..color = const Color(0x5A0A0814)
    ..strokeWidth = r * 0.26
    ..strokeCap = StrokeCap.round);
  c.drawLine(at, tip, Paint()
    ..color = const Color(0xFF2B2F42)
    ..strokeWidth = r * 0.24
    ..strokeCap = StrokeCap.round);
  c.drawLine(at, tip, Paint()
    ..color = const Color(0xFF4A5068)
    ..strokeWidth = r * 0.1
    ..strokeCap = StrokeCap.round);
  c.drawCircle(at, r * 0.3, Paint()..color = const Color(0xFF3A3F55));
  c.drawCircle(at - Offset(r * 0.08, r * 0.08), r * 0.12, Paint()..color = const Color(0xFF6A7090));
  // The locking pin over the hole: lifts out (bigger, offset shadow) when pulled.
  final pin = at + Offset(math.cos(a), math.sin(a)) * r * 0.78;
  final lift = pinOut ? 1.0 : 0.0;
  c.drawCircle(pin + Offset(r * 0.05 + lift * r * 0.12, r * 0.08 + lift * r * 0.14), r * (0.13 + 0.03 * lift), Paint()..color = const Color(0x6614101E));
  final knob = pin - Offset(0, lift * r * 0.1);
  c.drawCircle(knob, r * (0.13 + 0.05 * lift), Paint()..color = const Color(0xFFD8433A));
  c.drawCircle(knob - Offset(r * 0.04, r * 0.05), r * 0.05, Paint()..color = const Color(0xFFFF9A8A));
}

/// The big dial in the close-up card (positions labelled), the gloved hand on
/// the handle. Hits: [pinHit] the red pin, anywhere else on the dial = the handle.
class M3DtrTapDialPainter extends CustomPainter {
  const M3DtrTapDialPainter({required this.pos, required this.pinOut});
  final int pos;
  final bool pinOut;

  static Offset centreOf(Size s) => Offset(s.width / 2, s.height * 0.56);
  static double radiusOf(Size s) => math.min(s.width, s.height) * 0.3;

  /// The pin's tap target in the card for tap [pos].
  static Rect pinHit(Size s, int pos) {
    final a = m3DtrTapAngle(pos);
    final r = radiusOf(s);
    return Rect.fromCircle(center: centreOf(s) + Offset(math.cos(a), math.sin(a)) * r * 0.78, radius: 24);
  }

  @override
  void paint(Canvas c, Size size) {
    final r = Offset.zero & size;
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(18)), Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF7D8CA3), Color(0xFF55627A)]).createShader(r));
    c.drawRRect(
        RRect.fromRectAndRadius(r.deflate(1), const Radius.circular(18)),
        Paint()
          ..color = const Color(0xFFFFD34E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    m3DtrTapLabel(c, 'TAP', Offset(size.width / 2, 20), 13, const Color(0xFF1B2030));
    m3DtrTapPaintDial(c, centreOf(size), radiusOf(size), pos, pinOut);
  }

  @override
  bool shouldRepaint(M3DtrTapDialPainter old) => old.pos != pos || old.pinOut != pinOut;
}

/// The voltmeter in his hand: a yellow multimeter, the knob on V~, the
/// reading on its display ([volts] null = nothing on the leads yet).
class M3DtrTapMeterPainter extends CustomPainter {
  const M3DtrTapMeterPainter({required this.volts});
  final int? volts;

  @override
  void paint(Canvas c, Size size) {
    final r = Offset.zero & size;
    final body = RRect.fromRectAndRadius(r.deflate(2), const Radius.circular(16));
    c.drawRRect(body, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFC94A), Color(0xFFE09A16)]).createShader(r));
    c.drawRRect(
        body,
        Paint()
          ..color = const Color(0xFF6B4A0C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    final lcd = Rect.fromLTWH(size.width * 0.12, size.height * 0.1, size.width * 0.76, size.height * 0.34);
    c.drawRRect(RRect.fromRectAndRadius(lcd, const Radius.circular(6)), Paint()..color = const Color(0xFF1B1F24));
    final inner = lcd.deflate(5);
    c.drawRRect(RRect.fromRectAndRadius(inner, const Radius.circular(4)), Paint()..color = const Color(0xFFB8C8A8));
    final v = volts;
    final tp = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(text: v == null ? '- - -' : '$v', style: TextStyle(fontFamily: 'Roboto', fontSize: size.height * 0.17, fontWeight: FontWeight.w900, color: const Color(0xFF1A2214))),
          TextSpan(text: ' V', style: TextStyle(fontFamily: 'Roboto', fontSize: size.height * 0.09, fontWeight: FontWeight.w900, color: const Color(0xFF1A2214))),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, inner.center - Offset(tp.width / 2, tp.height / 2));
    // The knob, pointing at V~.
    final knob = Offset(size.width / 2, size.height * 0.68);
    final kr = size.width * 0.17;
    c.drawCircle(knob, kr + 6, Paint()..color = const Color(0xFF2B2F36));
    c.drawCircle(knob, kr, Paint()..color = const Color(0xFF454B55));
    c.drawLine(knob, knob + Offset(-kr * 0.7, -kr * 0.7), Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round);
    m3DtrTapLabel(c, 'V~', knob + Offset(-kr - 14, -kr - 4), 11, const Color(0xFF2B1C00));
    m3DtrTapLabel(c, 'Ω', knob + Offset(kr + 14, -kr - 4), 11, const Color(0x992B1C00));
    // The leads at the foot.
    c.drawLine(Offset(size.width * 0.38, size.height - 4), Offset(size.width * 0.38, size.height + 10), Paint()
      ..color = const Color(0xFFC8302A)
      ..strokeWidth = 4);
    c.drawLine(Offset(size.width * 0.62, size.height - 4), Offset(size.width * 0.62, size.height + 10), Paint()
      ..color = const Color(0xFF1B1E2C)
      ..strokeWidth = 4);
  }

  @override
  bool shouldRepaint(M3DtrTapMeterPainter old) => old.volts != volts;
}

/// The flash at [at] when a live transformer is worked on (the deadly
/// moment, in colour over the frozen scene).
class M3DtrTapArcPainter extends CustomPainter {
  const M3DtrTapArcPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final flick = v < 0.5 ? (0.65 + 0.35 * math.sin(v * 60).abs()) : (1 - (v - 0.5) * 1.2).clamp(0.4, 1.0);
    final r = 26 + 80 * Curves.easeOut.transform(v.clamp(0.0, 1.0));
    c.drawCircle(at, r, Paint()..shader = RadialGradient(colors: [Color.fromRGBO(255, 250, 220, 0.95 * flick), Color.fromRGBO(140, 170, 255, 0.5 * flick), const Color(0x00FFC24A)]).createShader(Rect.fromCircle(center: at, radius: r)));
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
  bool shouldRepaint(M3DtrTapArcPainter old) => old.v != v || old.at != at;
}
