import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The drawn world of lesson 2.8 কাজ 2 "উল্টো ঘুরছে পাম্প" (m2_phase_swap.dart):
// a farm pump house in the evening sun — a brick wall with the consumer's
// wooden panel board (the main switch with its handle, the outgoing terminal
// block R · Y · B with the earth bar under it, the motor starter with START /
// STOP), the cable along the wall to a three-phase motor coupled to the pump,
// the outlet pipe over the irrigation channel. Code-drawn, gradients, no
// bitmaps. Design space 360 wide; the floor sits [PhaseGeo.floorUp] above the
// bottom so the controls sit on it.

/// Where things are in the scene (design px, 360 wide).
@immutable
class PhaseGeo {
  const PhaseGeo._(this.height, this.groundY);

  factory PhaseGeo.forScene(double height, double inset) => PhaseGeo._(height, height - floorUp - inset * 0.5);

  final double height;

  /// The floor line under the motor.
  final double groundY;

  static const double floorUp = 104;

  // The panel board on the wall.
  double get boardTop => groundY - 342;
  Rect get board => Rect.fromLTRB(14, boardTop, 196, boardTop + 214);

  /// The main switch box and its handle (tap to switch).
  Rect get switchBox => Rect.fromLTWH(24, boardTop + 14, 70, 96);
  Rect get handleHit => Rect.fromLTWH(18, boardTop + 6, 84, 112);
  Offset get handlePivot => Offset(switchBox.right - 6, switchBox.top + 50);

  /// The outgoing terminal block and its three terminals (left → right).
  Rect get terminalBlock => Rect.fromLTWH(104, boardTop + 20, 84, 48);
  List<Offset> get terminals => [for (var i = 0; i < 3; i++) Offset(118 + 28.0 * i, boardTop + 44)];
  Rect terminalHit(int i) => Rect.fromCenter(center: terminals[i], width: 28, height: 52);

  /// The earth bar under the terminals (a probe must never touch it).
  Rect get earthBar => Rect.fromLTWH(106, boardTop + 82, 80, 12);
  Rect get earthHit => earthBar.inflate(8);

  /// The motor starter with its buttons.
  Rect get starter => Rect.fromLTWH(108, boardTop + 112, 76, 92);
  Offset get startButton => Offset(starter.left + 22, starter.top + 60);
  Offset get stopButton => Offset(starter.right - 22, starter.top + 60);
  Rect get startHit => Rect.fromCenter(center: startButton, width: 36, height: 36);

  // The motor and the pump on their plinth.
  Rect get plinth => Rect.fromLTRB(196, groundY - 16, 352, groundY);
  Rect get motor => Rect.fromLTRB(214, groundY - 72, 292, groundY - 18);
  Rect get pump => Rect.fromLTRB(300, groundY - 66, 342, groundY - 18);
  Offset get fan => Offset(motor.left - 2, motor.center.dy);
  Offset get spout => Offset(352, groundY - 132);

  /// Where the lineman stands: under the main switch, clear of the guide's corner.
  Rect get trainee => Rect.fromLTWH(8, groundY - 140, 70, 140);

  @override
  bool operator ==(Object other) => other is PhaseGeo && other.height == height && other.groundY == groundY;

  @override
  int get hashCode => Object.hash(height, groundY);
}

/// The wire colours at the terminals (index = phase colour 0 R, 1 Y, 2 B).
const phaseWireColors = [Color(0xFFD63A2F), Color(0xFFF2C230), Color(0xFF2F6FD6)];

/// What the panel shows now.
@immutable
class PanelState {
  const PanelState({
    required this.wires,
    required this.switchOn,
    required this.locked,
    required this.probes,
    required this.lifted,
    required this.pumpOn,
  });

  /// The wire colour on each terminal (left → right).
  final List<int> wires;
  final bool switchOn;
  final bool locked;

  /// Terminals with a meter clip on.
  final Set<int> probes;

  /// The terminal whose wire is lifted for the swap, if any.
  final int? lifted;
  final bool pumpOn;

  @override
  bool operator ==(Object other) =>
      other is PanelState &&
      listEquals(other.wires, wires) &&
      other.switchOn == switchOn &&
      other.locked == locked &&
      setEquals(other.probes, probes) &&
      other.lifted == lifted &&
      other.pumpOn == pumpOn;

  @override
  int get hashCode => Object.hash(Object.hashAll(wires), switchOn, locked, Object.hashAllUnordered(probes), lifted, pumpOn);
}

/// The pump house: wall, panel, motor, pump, water. [t] (seconds) turns the
/// motor's fan and runs the water while awake.
class PumpHousePainter extends CustomPainter {
  PumpHousePainter({required this.geo, required this.panel, required this.t, required this.seed}) : super(repaint: t);

  final PhaseGeo geo;
  final PanelState panel;
  final ValueListenable<double> t;
  final int seed;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    // Sky (the evening sun) and the far fields.
    c.drawRect(
        Rect.fromLTWH(0, 0, w, g.groundY),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5E86B8), Color(0xFFF2C38A)],
          ).createShader(Rect.fromLTWH(0, 0, w, g.boardTop + 40)));
    final sun = Offset(300, g.boardTop - 40);
    c.drawCircle(sun, 46, Paint()..shader = RadialGradient(colors: const [Color(0x88FFE6A8), Color(0x00FFE6A8)]).createShader(Rect.fromCircle(center: sun, radius: 46)));
    c.drawCircle(sun, 15, Paint()..color = const Color(0xFFFFE3A0));
    // The far field and a line of trees.
    final horizon = g.boardTop - 6;
    final tree = Paint()..color = const Color(0xFF3E6B3A);
    final rnd = math.Random(seed);
    for (var x = -10.0; x < w + 20; x += 22 + rnd.nextDouble() * 18) {
      final r = 10 + rnd.nextDouble() * 9;
      c.drawCircle(Offset(x, horizon - r * 0.6), r, tree);
    }
    c.drawRect(Rect.fromLTWH(0, horizon - 4, w, g.groundY - horizon + 4), Paint()..color = const Color(0xFF6E9A4E));

    // The pump-house wall (brick, plastered at the top).
    final wall = Rect.fromLTRB(0, g.boardTop - 30, 206, g.groundY);
    c.drawRect(wall, Paint()..shader = const LinearGradient(colors: [Color(0xFFB4664A), Color(0xFF9A5238)]).createShader(wall));
    final mortar = Paint()
      ..color = const Color(0x55E8C9A8)
      ..strokeWidth = 1;
    var row = 0;
    for (var y = wall.top + 14; y < wall.bottom; y += 11) {
      c.drawLine(Offset(0, y), Offset(wall.right, y), mortar);
      for (var x = (row.isEven ? 0.0 : 12.0); x < wall.right; x += 24) {
        c.drawLine(Offset(x, y), Offset(x, y + 11), mortar);
      }
      row++;
    }
    c.drawRect(Rect.fromLTRB(0, wall.top, wall.right + 8, wall.top + 12), Paint()..color = const Color(0xFF8C8478));
    c.drawRect(Rect.fromLTRB(wall.right - 6, wall.top, wall.right, wall.bottom), Paint()..color = const Color(0x33000000));

    // The floor: a concrete apron and the earth beyond.
    final floor = Rect.fromLTRB(0, g.groundY, w, size.height);
    c.drawRect(floor, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFA9A397), Color(0xFF7D776C)]).createShader(floor));
    c.drawLine(Offset(0, g.groundY), Offset(w, g.groundY), Paint()
      ..color = const Color(0xFF5F5A52)
      ..strokeWidth = 2);

    _panel(c);
    _cable(c);
    _motorAndPump(c);
  }

  void _panel(Canvas c) {
    final g = geo;
    final p = panel;
    // The wooden board.
    final b = RRect.fromRectAndRadius(g.board, const Radius.circular(6));
    c.drawRRect(b.shift(const Offset(3, 4)), Paint()..color = const Color(0x55000000));
    c.drawRRect(b, Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF9A6A3C), Color(0xFF6E4524)]).createShader(g.board));
    final grain = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 1;
    for (var y = g.board.top + 9; y < g.board.bottom; y += 13) {
      c.drawLine(Offset(g.board.left + 4, y), Offset(g.board.right - 4, y + 2), grain);
    }

    // The main switch box (grey steel) and its side handle.
    final sb = RRect.fromRectAndRadius(g.switchBox, const Radius.circular(5));
    c.drawRRect(sb, Paint()..shader = const LinearGradient(colors: [Color(0xFF7D8790), Color(0xFFB8C0C6), Color(0xFF6F7880)]).createShader(g.switchBox));
    c.drawRRect(sb, Paint()
      ..color = const Color(0xFF3E454B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4);
    _label(c, 'MAIN', Offset(g.switchBox.center.dx - 4, g.switchBox.top + 12), 9, const Color(0xFF22282D));
    // ON / OFF marks by the handle.
    _label(c, 'ON', Offset(g.switchBox.left + 16, g.switchBox.top + 34), 9.5, p.switchOn ? const Color(0xFFB0261C) : const Color(0xFF4A5157));
    _label(c, 'OFF', Offset(g.switchBox.left + 18, g.switchBox.bottom - 16), 9.5, p.switchOn ? const Color(0xFF4A5157) : const Color(0xFF1E6B34));
    // The handle: up = ON, down = OFF.
    final pivot = g.handlePivot;
    final ang = p.switchOn ? -0.95 : 0.95;
    final tip = pivot + Offset(-math.cos(ang) * 30, math.sin(ang) * 30);
    c.drawLine(pivot, tip, Paint()
      ..color = const Color(0xFF1E2226)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round);
    c.drawCircle(tip, 6.5, Paint()..color = const Color(0xFFC8302A));
    c.drawCircle(pivot, 5, Paint()..color = const Color(0xFF2B3035));
    // The lock and its tag (only when off).
    if (p.locked) {
      final at = Offset(g.switchBox.left + 14, g.switchBox.bottom - 4);
      c.drawArc(Rect.fromCenter(center: at + const Offset(0, -6), width: 12, height: 14), math.pi, math.pi, false, Paint()
        ..color = const Color(0xFF9AA1A7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: at + const Offset(0, 3), width: 16, height: 13), const Radius.circular(2.5)), Paint()..color = const Color(0xFFD9A441));
      final tag = Rect.fromLTWH(at.dx - 12, at.dy + 10, 40, 30);
      c.drawLine(at + const Offset(0, 9), tag.topCenter, Paint()
        ..color = const Color(0xFF333333)
        ..strokeWidth = 1);
      c.drawRRect(RRect.fromRectAndRadius(tag, const Radius.circular(3)), Paint()..color = const Color(0xFFD7261E));
      _label(c, 'DANGER', Offset(tag.center.dx, tag.top + 8), 7, Colors.white);
      _label(c, 'DO NOT', Offset(tag.center.dx, tag.top + 16), 6.5, Colors.white);
      _label(c, 'OPERATE', Offset(tag.center.dx, tag.top + 23.5), 6.5, Colors.white);
    }

    // The terminal block (black bakelite), the three terminals and their wires.
    final tb = RRect.fromRectAndRadius(g.terminalBlock, const Radius.circular(4));
    c.drawRRect(tb, Paint()..color = const Color(0xFF23262B));
    for (var i = 0; i < 3; i++) {
      final at = g.terminals[i];
      final col = phaseWireColors[p.wires[i]];
      final lifted = p.lifted == i;
      // The wire comes up from the starter into the terminal (lifted: pulled out, hanging).
      final end = lifted ? at + const Offset(-6, 30) : at + const Offset(0, 6);
      final path = Path()
        ..moveTo(at.dx, g.starter.top)
        ..cubicTo(at.dx, g.starter.top - 18, end.dx + (lifted ? -10 : 0), end.dy + 24, end.dx, end.dy);
      c.drawPath(path, Paint()
        ..color = const Color(0xFF15171A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7);
      c.drawPath(path, Paint()
        ..color = col
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5);
      if (lifted) c.drawCircle(end, 2.6, Paint()..color = const Color(0xFFE0A060));
      // The screw.
      c.drawCircle(at, 7, Paint()..shader = const RadialGradient(colors: [Color(0xFFF1F3F5), Color(0xFF8B949B)]).createShader(Rect.fromCircle(center: at, radius: 7)));
      c.drawLine(at + const Offset(-4, 0), at + const Offset(4, 0), Paint()
        ..color = const Color(0xFF444B51)
        ..strokeWidth = 1.6);
      // The incoming supply leads above (from the main switch).
      c.drawLine(Offset(at.dx, g.terminalBlock.top - 10), Offset(at.dx, at.dy - 7), Paint()
        ..color = const Color(0xFF2B2B2B)
        ..strokeWidth = 4);
    }
    // The supply leads from the switch to the terminals.
    c.drawLine(Offset(g.switchBox.right, g.terminalBlock.top - 10), Offset(g.terminals[2].dx, g.terminalBlock.top - 10), Paint()
      ..color = const Color(0xFF2B2B2B)
      ..strokeWidth = 4);
    // The meter's clips on the terminals.
    for (final i in p.probes) {
      final at = g.terminals[i] + const Offset(0, 10);
      final clip = Paint()..color = phaseWireColors[i];
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: at, width: 10, height: 15), const Radius.circular(3)), clip);
      c.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: at, width: 10, height: 15), const Radius.circular(3)),
          Paint()
            ..color = const Color(0xFF111111)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1);
      // The lead down to the meter (off the board's foot).
      c.drawPath(
          Path()
            ..moveTo(at.dx, at.dy + 7)
            ..quadraticBezierTo(at.dx - 30, g.board.bottom + 10, g.board.left + 60 + 6.0 * i, g.board.bottom + 18),
          Paint()
            ..color = phaseWireColors[i]
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }

    // The earth bar (green-yellow) under the block.
    final eb = g.earthBar;
    c.drawRRect(RRect.fromRectAndRadius(eb, const Radius.circular(2)), Paint()..color = const Color(0xFFB98C3A));
    for (var x = eb.left + 3; x < eb.right - 3; x += 9) {
      c.drawRect(Rect.fromLTWH(x, eb.top + 1, 4.5, eb.height - 2), Paint()..color = const Color(0xFF3E9A3E));
    }
    c.drawCircle(Offset(eb.left - 4, eb.center.dy), 6, Paint()..color = const Color(0xFF2E7D32));
    _label(c, 'E', Offset(eb.left - 4, eb.center.dy), 8, Colors.white);
    c.drawLine(Offset(eb.left - 4, eb.center.dy + 6), Offset(eb.left - 4, g.board.bottom), Paint()
      ..color = const Color(0xFF3E9A3E)
      ..strokeWidth = 2.5);

    // The starter (cream steel) with START (green) and STOP (red).
    final st = RRect.fromRectAndRadius(g.starter, const Radius.circular(5));
    c.drawRRect(st, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE8E2CF), Color(0xFFC7BFA6)]).createShader(g.starter));
    c.drawRRect(st, Paint()
      ..color = const Color(0xFF6E6650)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2);
    _label(c, 'STARTER', Offset(g.starter.center.dx, g.starter.top + 12), 8.5, const Color(0xFF3D3826));
    c.drawCircle(g.startButton, 11, Paint()..color = const Color(0xFF1C1C1C));
    c.drawCircle(g.startButton, 9, Paint()..color = p.pumpOn ? const Color(0xFF7CF08A) : const Color(0xFF2FA046));
    c.drawCircle(g.stopButton, 11, Paint()..color = const Color(0xFF1C1C1C));
    c.drawCircle(g.stopButton, 9, Paint()..color = const Color(0xFFC8302A));
    _label(c, 'START', Offset(g.startButton.dx, g.startButton.dy + 18), 7.5, const Color(0xFF2B2716));
    _label(c, 'STOP', Offset(g.stopButton.dx, g.stopButton.dy + 18), 7.5, const Color(0xFF2B2716));
    // The run lamp.
    final lamp = Offset(g.starter.center.dx, g.starter.top + 30);
    c.drawCircle(lamp, 5, Paint()..color = p.pumpOn ? const Color(0xFF9DFFA8) : const Color(0xFF4C5A4E));
  }

  void _cable(Canvas c) {
    final g = geo;
    // From the starter's foot along the wall to the motor's terminal box.
    final path = Path()
      ..moveTo(g.starter.center.dx, g.starter.bottom)
      ..lineTo(g.starter.center.dx, g.groundY - 24)
      ..quadraticBezierTo(g.starter.center.dx, g.groundY - 10, g.starter.center.dx + 20, g.groundY - 10)
      ..lineTo(g.motor.left + 30, g.groundY - 10)
      ..lineTo(g.motor.left + 30, g.motor.top + 4);
    c.drawPath(path, Paint()
      ..color = const Color(0xFF1E1E1E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5);
  }

  void _motorAndPump(Canvas c) {
    final g = geo;
    final on = panel.pumpOn;
    final time = t.value;
    // The plinth.
    c.drawRect(g.plinth, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFC9C3B6), Color(0xFF969082)]).createShader(g.plinth));
    // The motor body (ribbed, blue-grey) with its terminal box on top.
    final m = g.motor;
    c.drawRRect(RRect.fromRectAndRadius(m, const Radius.circular(10)), Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF5C86A8), Color(0xFF2E4E6A)]).createShader(m));
    final rib = Paint()
      ..color = const Color(0x55102030)
      ..strokeWidth = 1.4;
    for (var y = m.top + 8; y < m.bottom - 4; y += 6) {
      c.drawLine(Offset(m.left + 10, y), Offset(m.right - 8, y), rib);
    }
    c.drawRect(Rect.fromLTWH(m.left + 22, m.top - 9, 18, 10), Paint()..color = const Color(0xFF3E6482));
    // The feet.
    c.drawRect(Rect.fromLTWH(m.left + 8, m.bottom - 2, 14, 4), Paint()..color = const Color(0xFF263E54));
    c.drawRect(Rect.fromLTWH(m.right - 22, m.bottom - 2, 14, 4), Paint()..color = const Color(0xFF263E54));
    // The fan cover at the back end, with the fan turning while it runs.
    final fan = g.fan;
    c.drawOval(Rect.fromCenter(center: fan, width: 16, height: m.height - 4), Paint()..color = const Color(0xFF2A4258));
    final spin = on ? time * 14 : 0.0;
    final blade = Paint()
      ..color = const Color(0xFF9FB6C9)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final a = spin + i * math.pi / 2;
      c.drawLine(fan, fan + Offset(math.cos(a) * 5, math.sin(a) * (m.height / 2 - 6)), blade);
    }
    // The coupling guard and the pump casing.
    c.drawRect(Rect.fromLTRB(m.right, m.center.dy - 8, g.pump.left, m.center.dy + 8), Paint()..color = const Color(0xFFE0A21E));
    final pc = g.pump;
    c.drawOval(pc, Paint()..shader = const RadialGradient(colors: [Color(0xFF8E9AA3), Color(0xFF4E5961)]).createShader(pc));
    // The suction pipe down into the ground, the outlet up and out over the channel.
    final pipe = Paint()
      ..color = const Color(0xFF5E676E)
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;
    c.drawLine(Offset(pc.center.dx, pc.bottom - 4), Offset(pc.center.dx, g.groundY + 30), pipe);
    c.drawPath(
        Path()
          ..moveTo(pc.center.dx, pc.top + 4)
          ..lineTo(pc.center.dx, g.spout.dy)
          ..lineTo(g.spout.dx, g.spout.dy),
        pipe);
    // The channel at the foot.
    final ch = Rect.fromLTRB(326, g.groundY + 6, 360, g.groundY + 22);
    c.drawRect(ch, Paint()..color = on ? const Color(0xFF4F8FC7) : const Color(0xFF6E6252));
    // Water while the pump runs the right way.
    if (on) {
      final fall = Rect.fromLTRB(g.spout.dx - 6, g.spout.dy - 3, g.spout.dx + 2, g.groundY + 12);
      c.drawRect(fall, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xCC9BD3FF), Color(0x884F8FC7)]).createShader(fall));
      final drop = Paint()..color = const Color(0xDDE6F4FF);
      for (var i = 0; i < 5; i++) {
        final y = fall.top + ((time * 90 + i * 26) % fall.height);
        c.drawCircle(Offset(fall.center.dx + (i.isEven ? -1.5 : 1.5), y), 1.6, drop);
      }
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
  bool shouldRepaint(PumpHousePainter old) => old.geo != geo || old.panel != panel || old.seed != seed;
}

/// The phase sequence meter's face: a rotating disc (turns clockwise for
/// R-Y-B, anti-clockwise for R-B-Y) or the digital LEDs (FWD green / REV red).
/// [forward] null = no supply on the probes (nothing lit, the disc still).
class MeterFacePainter extends CustomPainter {
  MeterFacePainter({required this.disc, required this.forward, required this.t}) : super(repaint: t);

  final bool disc;
  final bool? forward;
  final ValueListenable<double> t;

  @override
  void paint(Canvas c, Size size) {
    final r = Offset.zero & size;
    final body = RRect.fromRectAndRadius(r.deflate(2), const Radius.circular(16));
    c.drawRRect(body, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFC94A), Color(0xFFE09A16)]).createShader(r));
    c.drawRRect(body, Paint()
      ..color = const Color(0xFF6B4A0C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
    // The three leads at the top.
    for (var i = 0; i < 3; i++) {
      final x = size.width * (0.3 + 0.2 * i);
      c.drawLine(Offset(x, 0), Offset(x, 12), Paint()
        ..color = phaseWireColors[i]
        ..strokeWidth = 4);
      _text(c, const ['R', 'Y', 'B'][i], Offset(x, 22), 11, const Color(0xFF3A2500));
    }
    final face = Rect.fromLTWH(size.width * 0.14, size.height * 0.24, size.width * 0.72, size.height * 0.6);
    c.drawRRect(RRect.fromRectAndRadius(face, const Radius.circular(10)), Paint()..color = const Color(0xFF1B1F24));
    if (disc) {
      _disc(c, face);
    } else {
      _digital(c, face);
    }
  }

  void _disc(Canvas c, Rect face) {
    final centre = face.center;
    final rad = math.min(face.width, face.height) * 0.36;
    // The window and the disc (a black sector on white so its turning shows).
    c.drawCircle(centre, rad + 4, Paint()..color = const Color(0xFF5A6066));
    final fwd = forward;
    final spin = fwd == null ? 0.0 : (fwd ? 1 : -1) * t.value * 5.0;
    c.drawCircle(centre, rad, Paint()..color = const Color(0xFFF4F4F0));
    c.save();
    c.translate(centre.dx, centre.dy);
    c.rotate(spin);
    c.drawArc(Rect.fromCircle(center: Offset.zero, radius: rad), 0, math.pi / 2, true, Paint()..color = const Color(0xFF1C1C1C));
    c.drawArc(Rect.fromCircle(center: Offset.zero, radius: rad), math.pi, math.pi / 2, true, Paint()..color = const Color(0xFF1C1C1C));
    c.restore();
    // The motion streaks round the disc: the way it turns (still frames too).
    if (fwd != null) {
      final streak = Paint()
        ..color = const Color(0xFFFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;
      for (var k = 0; k < 2; k++) {
        final base = spin + k * math.pi;
        final arc = Rect.fromCircle(center: centre, radius: rad + 11);
        final start = base - 0.2;
        final sweep = fwd ? 1.1 : -1.1;
        c.drawArc(arc, start, sweep, false, streak);
        final endA = start + sweep;
        final tip = centre + Offset(math.cos(endA), math.sin(endA)) * (rad + 11);
        final dir = fwd ? endA + math.pi / 2 : endA - math.pi / 2;
        final back = tip - Offset(math.cos(dir), math.sin(dir)) * 7;
        final side = Offset(math.cos(dir + math.pi / 2), math.sin(dir + math.pi / 2)) * 4.5;
        c.drawPath(
            Path()
              ..moveTo(tip.dx, tip.dy)
              ..lineTo(back.dx + side.dx, back.dy + side.dy)
              ..lineTo(back.dx - side.dx, back.dy - side.dy)
              ..close(),
            Paint()..color = Colors.white);
      }
    }
    // The case's own mark: clockwise (CW) is R-Y-B.
    _text(c, 'CW = R-Y-B', Offset(centre.dx, face.bottom - 9), 10, const Color(0xFFB9C2CA));
  }

  void _digital(Canvas c, Rect face) {
    final fwd = forward;
    void led(Offset at, String label, bool lit, Color on) {
      if (lit) c.drawCircle(at, 16, Paint()..shader = RadialGradient(colors: [on.withValues(alpha: 0.7), on.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: at, radius: 16)));
      c.drawCircle(at, 8, Paint()..color = lit ? on : const Color(0xFF3A3F45));
      _text(c, label, at + const Offset(0, 20), 12, lit ? Colors.white : const Color(0xFF7D858C));
    }

    final y = face.center.dy - 8;
    led(Offset(face.left + face.width * 0.3, y), 'FWD', fwd == true, const Color(0xFF39D353));
    led(Offset(face.left + face.width * 0.7, y), 'REV', fwd == false, const Color(0xFFFF4D3D));
  }

  void _text(Canvas c, String s, Offset centre, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontFamily: 'Roboto', fontSize: size, fontWeight: FontWeight.w900, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(MeterFacePainter old) => old.disc != disc || old.forward != forward;
}

/// The flash at the terminals when a live terminal is worked on (the deadly
/// moment, in colour over the frozen scene).
class TerminalArcPainter extends CustomPainter {
  const TerminalArcPainter({required this.geo, required this.v});
  final PhaseGeo geo;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final at = geo.terminals[1];
    final flick = v < 0.5 ? (0.65 + 0.35 * math.sin(v * 60).abs()) : (1 - (v - 0.5) * 1.2).clamp(0.4, 1.0);
    final r = 26 + 70 * Curves.easeOut.transform(v.clamp(0.0, 1.0));
    c.drawCircle(at, r, Paint()..shader = RadialGradient(colors: [Color.fromRGBO(255, 250, 220, 0.95 * flick), Color.fromRGBO(140, 170, 255, 0.5 * flick), const Color(0x00FFC24A)]).createShader(Rect.fromCircle(center: at, radius: r)));
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
  bool shouldRepaint(TerminalArcPainter old) => old.v != v || old.geo != geo;
}
