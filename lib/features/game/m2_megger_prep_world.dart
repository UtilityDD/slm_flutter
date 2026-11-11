import 'dart:math' as math;

import 'package:flutter/material.dart';

// The pump room of lesson 2.7 কাজ 1 ("মেগারের আগে"), drawn in code: a
// plastered wall with a window, the main switch box (ON/OFF lever, lamp) and
// the earth bar with its green-yellow discharge lead, the conduit down to a
// 415V motor on a plinth (terminal box, earth bolt on the foot, pump), and
// on the floor the megger (display, voltage knob, TEST, L and E sockets),
// the two-pole tester and, at the start, two pairs of test leads.
// Static layers repaint only when their state changes (an idle screen draws
// zero frames); the megger's count runs on its own one-shot.

/// Where things stand in the room (design px, 360 wide × the scene's height).
@immutable
class MeggerGeo {
  const MeggerGeo.forScene(this.height, double inset) : floorY = height - 262 - inset;

  final double height;

  /// Where the wall meets the floor.
  final double floorY;

  Rect get switchBox => Rect.fromLTWH(16, floorY - 206, 64, 88);
  Rect get earthBar => Rect.fromLTWH(18, floorY - 98, 60, 9);

  /// The discharge lead's clip, hanging from the earth bar.
  Offset get earthClipRest => Offset(56, floorY - 62);

  Rect get motor => Rect.fromLTWH(176, floorY - 96, 118, 76);
  Rect get plinth => Rect.fromLTWH(166, floorY - 20, 184, 22);
  Rect get terminalBox => Rect.fromLTWH(206, floorY - 124, 56, 28);
  Offset get terminals => terminalBox.center.translate(0, 2);
  Offset get earthBolt => Offset(188, floorY - 27);
  Rect get pump => Rect.fromLTWH(298, floorY - 78, 48, 56);

  /// The helper: hand on the terminal box, or stepped back.
  Rect helperBox({required bool clear}) =>
      clear ? Rect.fromLTWH(318, floorY - 140, 72, 150) : Rect.fromLTWH(254, floorY - 144, 74, 154);

  /// The trainee (the player), feet on the floor in front of the wall.
  Rect get traineeBox => Rect.fromLTWH(84, floorY - 108, 80, 160);
  Offset get hands => Offset(traineeBox.right - 14, traineeBox.top + 78);

  Rect get megger => Rect.fromLTWH(64, floorY + 132, 152, 90);
  Rect get display => Rect.fromLTWH(megger.left + 10, megger.top + 10, 78, 36);
  Offset get knob => Offset(megger.right - 32, megger.top + 34);
  Offset get testButton => Offset(megger.left + 30, megger.bottom - 22);
  Offset get socketL => Offset(megger.left + 74, megger.bottom - 20);
  Offset get socketE => Offset(megger.left + 100, megger.bottom - 20);

  /// Where an unclipped lead's crocodile clip rests on the floor.
  Offset get clipLRest => Offset(megger.right + 18, megger.top + 6);
  Offset get clipERest => Offset(megger.right + 30, megger.top + 30);

  Rect get tester => Rect.fromLTWH(16, floorY + 18, 62, 22);

  /// The two pairs of test leads at the start.
  Rect get leadsLeft => Rect.fromLTWH(10, floorY + 66, 96, 58);
  Rect get leadsRight => Rect.fromLTWH(172, floorY + 8, 84, 50);

  @override
  bool operator ==(Object other) => other is MeggerGeo && other.height == height && other.floorY == floorY;

  @override
  int get hashCode => Object.hash(height, floorY);
}

/// The knob's positions (what is printed round it on a real megger).
const meggerVolts = [500, 1000, 2500, 5000];

String meggerVoltLabel(int v) => switch (v) {
      500 => '500V',
      1000 => '1kV',
      2500 => '2.5kV',
      _ => '5kV',
    };

/// The knob's angle for a voltage (null = OFF, straight up-left).
double meggerKnobAngle(int? v) => v == null ? -2.4 : -1.2 + 0.8 * meggerVolts.indexOf(v);

// ============================================================================
// The room
// ============================================================================

class MeggerRoomPainter extends CustomPainter {
  const MeggerRoomPainter({required this.geo, required this.switchOn});
  final MeggerGeo geo;
  final bool switchOn;

  @override
  void paint(Canvas canvas, Size size) {
    final g = geo;
    final w = size.width;
    // Wall.
    canvas.drawRect(
      Rect.fromLTRB(0, 0, w, g.floorY),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8C9A8E), Color(0xFFB9C2AE), Color(0xFFA7AE98)],
        ).createShader(Rect.fromLTRB(0, 0, w, g.floorY)),
    );
    // Damp patches on the plaster.
    final damp = Paint()..color = const Color(0x1A3B3020);
    canvas.drawOval(Rect.fromLTWH(110, g.floorY - 70, 60, 40), damp);
    canvas.drawOval(Rect.fromLTWH(300, g.floorY - 210, 50, 70), damp);
    // Skirting.
    canvas.drawRect(Rect.fromLTRB(0, g.floorY - 10, w, g.floorY), Paint()..color = const Color(0xFF6F6A5C));
    // Window with bars, daylight outside.
    final win = Rect.fromLTWH(206, math.max(110, g.floorY - 300), 110, 92);
    canvas.drawRect(win.inflate(6), Paint()..color = const Color(0xFF5B4A36));
    canvas.drawRect(
      win,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF9FD4F2), Color(0xFFD9F0E0), Color(0xFF7DB36A)],
        ).createShader(win),
    );
    final bar = Paint()
      ..color = const Color(0xFF3A3A3A)
      ..strokeWidth = 3;
    for (var i = 1; i < 5; i++) {
      final x = win.left + win.width * i / 5;
      canvas.drawLine(Offset(x, win.top), Offset(x, win.bottom), bar);
    }
    // Floor (cement), with a little perspective.
    final floor = Rect.fromLTRB(0, g.floorY, w, size.height);
    canvas.drawRect(
      floor,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8E8A80), Color(0xFF6E6A62), Color(0xFF55524C)],
        ).createShader(floor),
    );
    final seam = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 1;
    for (var i = 0; i < 9; i++) {
      final x = -80.0 + i * 70;
      canvas.drawLine(Offset(180 + (x - 180) * 0.6, g.floorY), Offset(x, size.height), seam);
    }
    for (final dy in [40.0, 110.0, 210.0]) {
      canvas.drawLine(Offset(0, g.floorY + dy), Offset(w, g.floorY + dy), seam);
    }

    // Conduit: from the switch box down the wall, along the skirting to the motor.
    final conduit = Paint()
      ..color = const Color(0xFF3D3D3D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    final sb = g.switchBox;
    final run = Path()
      ..moveTo(sb.center.dx + 14, sb.bottom)
      ..lineTo(sb.center.dx + 14, g.floorY - 16)
      ..quadraticBezierTo(sb.center.dx + 14, g.floorY - 6, sb.center.dx + 26, g.floorY - 6)
      ..lineTo(g.terminalBox.left - 18, g.floorY - 6)
      ..quadraticBezierTo(g.terminalBox.left - 6, g.floorY - 6, g.terminalBox.left - 6, g.floorY - 30)
      ..lineTo(g.terminalBox.left - 6, g.terminalBox.center.dy)
      ..lineTo(g.terminalBox.left, g.terminalBox.center.dy);
    canvas.drawPath(run, conduit);
    canvas.drawPath(run, Paint()
      ..color = const Color(0x33FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);

    _switchBox(canvas, g);
    _earthBar(canvas, g);
    _motor(canvas, g);
  }

  void _switchBox(Canvas canvas, MeggerGeo g) {
    final b = g.switchBox;
    final body = RRect.fromRectAndRadius(b, const Radius.circular(5));
    canvas.drawRRect(body.shift(const Offset(3, 4)), Paint()..color = const Color(0x55000000));
    canvas.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFF6C7A86), Color(0xFF46525C)]).createShader(b),
    );
    canvas.drawRRect(body, Paint()
      ..color = const Color(0xFF2B333A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);
    // Danger plate.
    final plate = Rect.fromLTWH(b.left + 8, b.top + 6, b.width - 16, 14);
    canvas.drawRect(plate, Paint()..color = const Color(0xFFF2C21B));
    _text(canvas, '415V', plate.center, 9, const Color(0xFF1A1A1A));
    // Lever slot and lever (up = ON).
    final slot = Rect.fromLTWH(b.center.dx - 4, b.top + 28, 8, 42);
    canvas.drawRRect(RRect.fromRectAndRadius(slot, const Radius.circular(4)), Paint()..color = const Color(0xFF1C2226));
    final ky = switchOn ? slot.top + 8 : slot.bottom - 8;
    canvas.drawLine(Offset(slot.center.dx, slot.center.dy), Offset(slot.center.dx + 16, ky), Paint()
      ..color = const Color(0xFFB0321F)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round);
    canvas.drawCircle(Offset(slot.center.dx + 16, ky), 6, Paint()..color = const Color(0xFFD9452B));
    _text(canvas, 'ON', Offset(b.left + 12, slot.top + 6), 8, const Color(0xFFE8F0E8));
    _text(canvas, 'OFF', Offset(b.left + 13, slot.bottom - 6), 8, const Color(0xFFE8F0E8));
    // Lamp: green while the supply is on.
    final lamp = Offset(b.center.dx, b.bottom - 8);
    canvas.drawCircle(lamp, 5, Paint()..color = switchOn ? const Color(0xFF3CE06A) : const Color(0xFF39433C));
    if (switchOn) {
      canvas.drawCircle(lamp, 9, Paint()
        ..color = const Color(0x553CE06A)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    }
  }

  void _earthBar(Canvas canvas, MeggerGeo g) {
    final e = g.earthBar;
    canvas.drawRect(e, Paint()..color = const Color(0xFFC98A3A));
    canvas.drawRect(e, Paint()
      ..color = const Color(0xFF7A4F1C)
      ..style = PaintingStyle.stroke);
    for (var i = 0; i < 4; i++) {
      canvas.drawCircle(Offset(e.left + 8 + i * 15, e.center.dy), 2.2, Paint()..color = const Color(0xFF5C3B12));
    }
    // The earth wire down into the floor.
    canvas.drawLine(Offset(e.left + 4, e.bottom), Offset(e.left + 4, g.floorY), Paint()
      ..color = const Color(0xFF2E8B3A)
      ..strokeWidth = 3);
  }

  void _motor(Canvas canvas, MeggerGeo g) {
    // Plinth.
    final p = g.plinth;
    canvas.drawRect(p.shift(const Offset(0, 4)), Paint()..color = const Color(0x44000000));
    canvas.drawRect(p, Paint()..color = const Color(0xFF9C978C));
    canvas.drawRect(Rect.fromLTWH(p.left, p.top, p.width, 4), Paint()..color = const Color(0xFFB8B3A6));
    // Feet.
    final m = g.motor;
    final foot = Paint()..color = const Color(0xFF2F4B5E);
    canvas.drawRect(Rect.fromLTWH(m.left + 2, m.bottom - 2, 26, p.top - m.bottom + 4), foot);
    canvas.drawRect(Rect.fromLTWH(m.right - 30, m.bottom - 2, 26, p.top - m.bottom + 4), foot);
    // Body with fins.
    final body = RRect.fromRectAndRadius(m, const Radius.circular(14));
    canvas.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5E8AA6), Color(0xFF34617E), Color(0xFF1F4258)],
        ).createShader(m),
    );
    final fin = Paint()
      ..color = const Color(0x55102030)
      ..strokeWidth = 2;
    for (var x = m.left + 14; x < m.right - 10; x += 8) {
      canvas.drawLine(Offset(x, m.top + 6), Offset(x, m.bottom - 6), fin);
    }
    // Nameplate.
    final plate = Rect.fromLTWH(m.left + 36, m.top + 30, 44, 22);
    canvas.drawRect(plate, Paint()..color = const Color(0xFFD8D8D0));
    _text(canvas, '415V', plate.center.translate(0, -4), 8, const Color(0xFF1B1B1B));
    _text(canvas, '3~ 5HP', plate.center.translate(0, 6), 6.5, const Color(0xFF333333));
    // Shaft to the pump.
    canvas.drawRect(Rect.fromLTWH(m.right - 2, m.center.dy - 5, g.pump.left - m.right + 4, 10), Paint()..color = const Color(0xFF8C8C8C));
    final pu = g.pump;
    canvas.drawRRect(
      RRect.fromRectAndRadius(pu, const Radius.circular(18)),
      Paint()..shader = const LinearGradient(colors: [Color(0xFF3E6F48), Color(0xFF244A2C)]).createShader(pu),
    );
    canvas.drawRect(Rect.fromLTWH(pu.center.dx - 6, pu.top - 26, 12, 28), Paint()..color = const Color(0xFF555555));
    canvas.drawRect(Rect.fromLTWH(pu.center.dx - 6, pu.top - 26, 60, 10), Paint()..color = const Color(0xFF555555));
    // Terminal box (lid open) with three studs.
    final t = g.terminalBox;
    canvas.drawRect(t, Paint()..color = const Color(0xFF2B4D63));
    canvas.drawRect(t.deflate(4), Paint()..color = const Color(0xFF1A2128));
    for (var i = 0; i < 3; i++) {
      final c = Offset(t.left + 12 + i * 16, t.center.dy + 1);
      canvas.drawCircle(c, 4, Paint()..color = const Color(0xFFD8A24A));
      canvas.drawCircle(c, 1.6, Paint()..color = const Color(0xFF6A4A16));
    }
    // The lid, hinged open.
    final lid = Path()
      ..moveTo(t.left, t.top)
      ..lineTo(t.left + 6, t.top - 18)
      ..lineTo(t.right + 6, t.top - 18)
      ..lineTo(t.right, t.top)
      ..close();
    canvas.drawPath(lid, Paint()..color = const Color(0xFF3B6680));
    // Earth bolt on the foot.
    canvas.drawCircle(g.earthBolt, 5, Paint()..color = const Color(0xFFBFC4C8));
    canvas.drawCircle(g.earthBolt, 2, Paint()..color = const Color(0xFF4A4F55));
    canvas.drawLine(g.earthBolt, Offset(g.earthBolt.dx - 18, g.plinth.top + 2), Paint()
      ..color = const Color(0xFF2E8B3A)
      ..strokeWidth = 2.4);
  }

  @override
  bool shouldRepaint(MeggerRoomPainter old) => old.geo != geo || old.switchOn != switchOn;
}

// ============================================================================
// The gear on the floor: megger, leads, tester, discharge lead
// ============================================================================

class MeggerGearPainter extends CustomPainter {
  const MeggerGearPainter({
    required this.geo,
    required this.leadsTaken,
    required this.crackedLeft,
    required this.volt,
    required this.lClipped,
    required this.eClipped,
    required this.testerOn,
    required this.earthOn,
  });

  final MeggerGeo geo;

  /// The good pair is plugged into the megger (the start: both pairs on the floor).
  final bool leadsTaken;
  final bool crackedLeft;
  final int? volt;
  final bool lClipped;
  final bool eClipped;

  /// The tester's prods are on the terminals.
  final bool testerOn;

  /// The discharge lead's clip is on the terminals.
  final bool earthOn;

  @override
  void paint(Canvas canvas, Size size) {
    final g = geo;
    if (!leadsTaken) {
      _coil(canvas, g.leadsLeft, cracked: crackedLeft);
      _coil(canvas, g.leadsRight, cracked: !crackedLeft);
    }
    _discharge(canvas, g);
    _tester(canvas, g);
    _megger(canvas, g);
    if (leadsTaken) {
      _lead(canvas, g.socketL, lClipped ? g.terminals.translate(-14, 0) : g.clipLRest, const Color(0xFFD23A2A));
      _lead(canvas, g.socketE, eClipped ? g.earthBolt : g.clipERest, const Color(0xFF1E1E1E));
    }
  }

  void _coil(Canvas canvas, Rect r, {required bool cracked}) {
    for (final (i, col) in [(0, const Color(0xFFD23A2A)), (1, const Color(0xFF1E1E1E))]) {
      final c = Offset(r.left + r.width * (0.34 + 0.32 * i), r.center.dy);
      for (var k = 0; k < 3; k++) {
        canvas.drawOval(
          Rect.fromCenter(center: c.translate(0, k * 2.0), width: r.width * 0.42 - k * 4, height: r.height * 0.5 - k * 3),
          Paint()
            ..color = col
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.4,
        );
      }
      // Crocodile clip and plug.
      final clip = c.translate(r.width * 0.12, r.height * 0.34);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: clip, width: 14, height: 6), const Radius.circular(2)), Paint()..color = const Color(0xFFB8BEC4));
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: c.translate(-r.width * 0.14, -r.height * 0.3), width: 6, height: 12), const Radius.circular(2)), Paint()..color = col);
    }
    if (cracked) {
      // The insulation split open: bare copper shows on the red lead.
      final at = Offset(r.left + r.width * 0.2, r.center.dy - r.height * 0.12);
      canvas.drawLine(at, at.translate(12, -4), Paint()
        ..color = const Color(0xFFE08A3C)
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.round);
      canvas.drawLine(at.translate(1, 1), at.translate(11, -2), Paint()
        ..color = const Color(0xFFFFC37A)
        ..strokeWidth = 1.2);
      final split = Paint()
        ..color = const Color(0xFF7A1A12)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(at.translate(-3, -3), at.translate(2, 2), split);
      canvas.drawLine(at.translate(10, -8), at.translate(15, -1), split);
    }
  }

  void _discharge(Canvas canvas, MeggerGeo g) {
    final from = Offset(g.earthBar.right - 6, g.earthBar.bottom);
    final to = earthOn ? g.terminals.translate(14, -2) : g.earthClipRest;
    final mid = Offset((from.dx + to.dx) / 2, math.max(from.dy, to.dy) + 26);
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(mid.dx, mid.dy, to.dx, to.dy);
    canvas.drawPath(path, Paint()
      ..color = const Color(0xFF2E8B3A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.6);
    canvas.drawPath(path, Paint()
      ..color = const Color(0xFFE8D23A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4);
    // Insulated handle and the clip.
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: to.translate(0, 9), width: 9, height: 18), const Radius.circular(3)), Paint()..color = const Color(0xFF2E8B3A));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: to, width: 12, height: 6), const Radius.circular(2)), Paint()..color = const Color(0xFFB8BEC4));
  }

  void _tester(Canvas canvas, MeggerGeo g) {
    if (testerOn) {
      // Prods on two studs, the body in the hand's reach; no lamp lit (dead).
      final a = g.terminals.translate(-10, 0);
      final b = g.terminals.translate(8, 0);
      final body = Rect.fromCenter(center: g.terminals.translate(-30, 30), width: 16, height: 34);
      final wire = Paint()
        ..color = const Color(0xFF222222)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(body.topCenter, a, wire);
      canvas.drawLine(body.topCenter, b, wire);
      canvas.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(4)), Paint()..color = const Color(0xFFF2C21B));
      for (var i = 0; i < 3; i++) {
        canvas.drawCircle(Offset(body.center.dx, body.top + 8 + i * 8), 2.6, Paint()..color = const Color(0xFF4A3A10));
      }
      return;
    }
    final r = g.tester;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.left, r.top + 4, 26, 14), const Radius.circular(4)), Paint()..color = const Color(0xFFF2C21B));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.right - 22, r.top + 6, 22, 10), const Radius.circular(3)), Paint()..color = const Color(0xFFF2C21B));
    canvas.drawLine(Offset(r.left + 26, r.center.dy), Offset(r.right - 22, r.center.dy), Paint()
      ..color = const Color(0xFF222222)
      ..strokeWidth = 2);
  }

  void _megger(Canvas canvas, MeggerGeo g) {
    final m = g.megger;
    final body = RRect.fromRectAndRadius(m, const Radius.circular(10));
    canvas.drawRRect(body.shift(const Offset(3, 5)), Paint()..color = const Color(0x66000000));
    canvas.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF4C430), Color(0xFFD9A417)],
        ).createShader(m),
    );
    canvas.drawRRect(body.deflate(5), Paint()
      ..color = const Color(0xFF2B2B2B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);
    // Knob with its positions.
    final k = g.knob;
    canvas.drawCircle(k, 18, Paint()..color = const Color(0xFF2A2A2A));
    canvas.drawCircle(k, 13, Paint()..color = const Color(0xFF4A4A4A));
    final a = meggerKnobAngle(volt) - math.pi / 2;
    canvas.drawLine(k, k + Offset(math.cos(a), math.sin(a)) * 12, Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round);
    _text(canvas, 'OFF', k + _polar(meggerKnobAngle(null), 25), 6.5, const Color(0xFF1A1A1A));
    for (final v in meggerVolts) {
      _text(canvas, meggerVoltLabel(v), k + _polar(meggerKnobAngle(v), 26), 6.5, const Color(0xFF1A1A1A));
    }
    // TEST button.
    final tb = g.testButton;
    canvas.drawCircle(tb, 12, Paint()..color = const Color(0xFF7A1E14));
    canvas.drawCircle(tb, 10, Paint()..color = const Color(0xFFD23A2A));
    _text(canvas, 'TEST', tb.translate(0, -18), 7, const Color(0xFF1A1A1A));
    // Sockets.
    for (final (o, label, col) in [(g.socketL, 'L', const Color(0xFFD23A2A)), (g.socketE, 'E', const Color(0xFF1E1E1E))]) {
      canvas.drawCircle(o, 6, Paint()..color = col);
      canvas.drawCircle(o, 2.4, Paint()..color = const Color(0xFF0E0E0E));
      _text(canvas, label, o.translate(0, -12), 8, const Color(0xFF1A1A1A));
    }
  }

  void _lead(Canvas canvas, Offset from, Offset to, Color col) {
    final mid = Offset((from.dx + to.dx) / 2 + 10, math.max(from.dy, to.dy) + 30);
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(mid.dx, mid.dy, to.dx, to.dy);
    canvas.drawPath(path, Paint()
      ..color = col
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: to, width: 13, height: 6), const Radius.circular(2)), Paint()..color = const Color(0xFFB8BEC4));
  }

  @override
  bool shouldRepaint(MeggerGearPainter old) =>
      old.geo != geo ||
      old.leadsTaken != leadsTaken ||
      old.crackedLeft != crackedLeft ||
      old.volt != volt ||
      old.lClipped != lClipped ||
      old.eClipped != eClipped ||
      old.testerOn != testerOn ||
      old.earthOn != earthOn;
}

Offset _polar(double angle, double r) => Offset(math.cos(angle - math.pi / 2), math.sin(angle - math.pi / 2)) * r;

void _text(Canvas canvas, String s, Offset centre, double size, Color color) {
  final tp = TextPainter(
    text: TextSpan(text: s, style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, color: color)),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, centre - Offset(tp.width / 2, tp.height / 2));
}

/// The megger's display: the chosen voltage, the 1-minute count, then the
/// reading in MΩ. [t] runs 0 → 1 over the (sped-up) minute; null = idle.
class MeggerDisplayPainter extends CustomPainter {
  const MeggerDisplayPainter({required this.volt, required this.t, required this.reading});
  final int? volt;
  final double? t;
  final int? reading;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)), Paint()..color = const Color(0xFF1B2A1E));
    canvas.drawRRect(RRect.fromRectAndRadius(r.deflate(2), const Radius.circular(3)), Paint()..color = const Color(0xFF9BC59A));
    const ink = Color(0xFF14261A);
    final v = volt;
    _text(canvas, v == null ? 'OFF' : meggerVoltLabel(v), Offset(size.width * 0.26, size.height * 0.28), 8, ink);
    final tt = t;
    if (tt != null) {
      final s = (60 * tt).floor().clamp(0, 60);
      _text(canvas, s >= 60 ? '01:00' : '00:${s.toString().padLeft(2, '0')}', Offset(size.width * 0.72, size.height * 0.28), 8, ink);
      final shown = tt >= 1 ? reading : ((reading ?? 0) * tt * tt).round();
      _text(canvas, '${shown ?? 0} MΩ', Offset(size.width * 0.5, size.height * 0.7), 11, ink);
    } else if (reading != null) {
      _text(canvas, '$reading MΩ', Offset(size.width * 0.5, size.height * 0.7), 11, ink);
    } else {
      _text(canvas, '--- MΩ', Offset(size.width * 0.5, size.height * 0.7), 11, ink);
    }
  }

  @override
  bool shouldRepaint(MeggerDisplayPainter old) => old.volt != volt || old.t != t || old.reading != reading;
}

// ============================================================================
// One-shots: spark, ping, the deadly zap
// ============================================================================

class MeggerOneShot extends StatefulWidget {
  const MeggerOneShot({super.key, required this.ms, required this.painter});
  final int ms;
  final CustomPainter Function(Animation<double> t) painter;

  @override
  State<MeggerOneShot> createState() => _MeggerOneShotState();
}

class _MeggerOneShotState extends State<MeggerOneShot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Duration(milliseconds: widget.ms))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(painter: widget.painter(_c));
}

/// "চট্": the stored charge goes to earth.
class MeggerSparkPainter extends CustomPainter {
  MeggerSparkPainter(this.t) : super(repaint: t);
  final Animation<double> t;

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value;
    if (v >= 1) return;
    final c = size.center(Offset.zero);
    final fade = 1 - v;
    canvas.drawCircle(c, 5 + 12 * v, Paint()
      ..color = Color.fromRGBO(255, 244, 180, 0.85 * fade)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    final ray = Paint()
      ..color = Color.fromRGBO(255, 210, 31, fade)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + 0.3;
      final d = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(c + d * (6 + 8 * v), c + d * (12 + 16 * v), ray);
    }
  }

  @override
  bool shouldRepaint(MeggerSparkPainter old) => false;
}

/// A red ring where a wrong move landed.
class MeggerPingPainter extends CustomPainter {
  MeggerPingPainter(this.t) : super(repaint: t);
  final Animation<double> t;

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value;
    if (v >= 1) return;
    canvas.drawCircle(size.center(Offset.zero), 10 + 26 * v, Paint()
      ..color = Color.fromRGBO(192, 57, 43, 1 - v)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4);
  }

  @override
  bool shouldRepaint(MeggerPingPainter old) => false;
}

/// The deadly moment in colour: the live supply jumps from the terminals
/// along [path] through the trainee to the floor; the body glows red.
class MeggerZapPainter extends CustomPainter {
  MeggerZapPainter(this.t, {required this.path, required this.figure}) : super(repaint: t);
  final Animation<double> t;
  final List<Offset> path;
  final Rect figure;

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value;
    final flash = (v < 0.2 ? v / 0.2 : (1 - (v - 0.2) / 0.8)).clamp(0.0, 1.0);
    canvas.drawRect(Offset.zero & size, Paint()..color = Color.fromRGBO(255, 240, 230, 0.4 * flash));
    canvas.drawOval(figure.inflate(8), Paint()
      ..color = const Color(0x99FF3B2F)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    final rnd = math.Random(v >= 1 ? 7 : (v * 14).floor());
    final arc = Path()..moveTo(path.first.dx, path.first.dy);
    for (var i = 1; i < path.length; i++) {
      final a = path[i - 1];
      final b = path[i];
      for (var j = 1; j <= 5; j++) {
        final p = Offset.lerp(a, b, j / 5)!;
        final jitter = j == 5 ? 0.0 : (rnd.nextDouble() - 0.5) * 14;
        arc.lineTo(p.dx + jitter, p.dy + jitter * 0.3);
      }
    }
    canvas.drawPath(arc, Paint()
      ..color = const Color(0xAA8FD3FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawPath(arc, Paint()
      ..color = const Color(0xFFFFF7D6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeJoin = StrokeJoin.round);
    final ray = Paint()
      ..color = const Color(0xFFFFD21F)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final o = path.first;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + v * 2;
      final d = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(o + d * 6, o + d * (14 + 6 * flash), ray);
    }
  }

  @override
  bool shouldRepaint(MeggerZapPainter old) => false;
}

/// The voltage knob, big (the close-up when the player reaches for it).
class MeggerKnobPainter extends CustomPainter {
  const MeggerKnobPainter({required this.volt});
  final int? volt;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = math.min(size.width, size.height) / 2;
    canvas.drawCircle(c, r, Paint()..color = const Color(0xFF2A2A2A));
    canvas.drawCircle(c, r * 0.78, Paint()
      ..shader = const RadialGradient(colors: [Color(0xFF6A6A6A), Color(0xFF3A3A3A)]).createShader(Rect.fromCircle(center: c, radius: r)));
    final a = meggerKnobAngle(volt) - math.pi / 2;
    canvas.drawLine(c, c + Offset(math.cos(a), math.sin(a)) * r * 0.7, Paint()
      ..color = Colors.white
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(MeggerKnobPainter old) => old.volt != volt;
}
