import 'dart:math' as math;

import 'package:flutter/material.dart';

// The drawn world of lesson 6.10 কাজ 1 "মিটারের নাড়ি" (m6_meter_pulse.dart):
// an evening house call in a village house.
//
// Two places, the same geometry class:
//  * the house — a cut-away of the rooms, wider than the screen and panned
//    by a sideways swipe: five rooms in a row (the last one the yard), each
//    with its appliance and its own wall switch. A running appliance shows
//    only what a worker would see (a fan's blades a blur, a tube light's
//    glow, a TV's lit screen, the fridge's door lamp under the curtain, the
//    pump's water); a switch shows its rocker (down = ON) and its little red
//    pilot lamp. The yard (and one room) are out of the first view. The
//    customer waits in the front room with his bill.
//  * the veranda — the meter close up (LCD, push-button, the red CAL LED
//    with "3200 imp/kWh" printed beside it, the sealed terminal cover), the
//    service cable down from the pole top, a wall clock, a socket, and the
//    trainee's tray: a 100 W bulb on a lead and an insulated tester.
//
// No text in the art except labels a worker reads (the meter's own print,
// IN/OUT on the terminal cover, the clock's numbers, the LCD). Code-drawn,
// gradients, no bitmaps.
//
// Design: 360 wide × the scene's height; the floor follows the bottom of the
// screen (a tall phone gets taller rooms, never stretched sideways).

/// The five appliances (each in its own room; the pump in the yard).
enum M6PulseAppliance { fan, tube, tv, fridge, pump }

/// The fault places on a blank call (lesson 6.10 point 3, complaint 2).
enum M6PulsePlace { meter, cable, pole }

/// The house is this wide (two screens): the first view shows rooms 0–2.
const double kM6PulsePanoW = 720;

/// The camera's travel.
const double kM6PulseCamMax = kM6PulsePanoW - 360;

/// Where things are (design px, 360 wide).
@immutable
class M6PulseGeo {
  const M6PulseGeo._(this.height, this.floorY);

  factory M6PulseGeo.forScene(double height, double inset) => M6PulseGeo._(height, height - floorUp - inset * 0.5);

  final double height;

  /// The floor line.
  final double floorY;

  /// The floor sits this far above the bottom (the button row stands under it).
  static const double floorUp = 96;

  /// The top of the working area (under the header).
  static const double top = 132;

  /// The working height.
  double get a => floorY - top - 8;

  /// A height in the working area (0 = the top, 1 = the floor).
  double y(double f) => top + f * a;

  // --- the house ---------------------------------------------------------------

  /// The centre of room [i] on the panorama (0–4; 4 = the yard).
  static double roomX(int i) => const [62.0, 178.0, 294.0, 478.0, 640.0][i];

  /// Room [i]'s walls on the panorama.
  static double roomLeft(int i) => const [4.0, 120.0, 236.0, 400.0, 556.0][i];
  static double roomRight(int i) => const [120.0, 236.0, 352.0, 556.0, 716.0][i];

  /// The appliance's place in room [i] (panorama px).
  /// (Ceiling and wall things hang over the whole room; floor things stand in
  /// this column, clear of the switch.)
  Rect appliance(int i) => Rect.fromLTRB(roomLeft(i) + 54, y(0.04), roomRight(i) - 8, floorY - 8);

  /// Room [i]'s wall switch (panorama px).
  Rect switchAt(int i) => Rect.fromCenter(center: Offset(roomLeft(i) + 28, y(0.56)), width: 44, height: 56);

  /// The switch on screen with the camera at [camX].
  Rect switchOnScreen(int i, double camX) => switchAt(i).shift(Offset(-camX, 0));

  // --- the veranda -------------------------------------------------------------

  /// The meter.
  Rect get meter => Rect.fromLTWH(52, y(0.18), 124, (0.42 * a).clamp(140.0, 230.0));

  Rect get lcd => Rect.fromLTWH(meter.left + 12, meter.top + 14, meter.width - 24, 30);
  Offset get pushButton => Offset(meter.left + 26, meter.top + 68);
  Offset get led => Offset(meter.right - 26, meter.top + 68);

  /// The sealed terminal cover (IN at the left, OUT at the right).
  Rect get cover => Rect.fromLTWH(meter.left, meter.bottom - 40, meter.width, 40);

  /// The meter itself as a fault place (above the cover).
  Rect get meterHit => Rect.fromLTRB(meter.left, meter.top, meter.right, cover.top);

  /// The incoming terminals (the tester's target).
  Rect get incomingHit => Rect.fromLTWH(cover.left, cover.top, 56, 46);

  /// The pole top and its connection.
  Offset get poleTop => Offset(330, top + 36);
  Rect get poleHit => Rect.fromCenter(center: poleTop.translate(0, 6), width: 60, height: 56);

  /// The service cable from the pole top down to the meter.
  Offset get cableFrom => poleTop.translate(-10, 10);
  Offset get cableTo => Offset(meter.right - 22, meter.top);
  Offset get cableMid => Offset.lerp(cableFrom, cableTo, 0.45)! + const Offset(0, 8);
  Rect get cableHit => Rect.fromCenter(center: cableMid, width: 60, height: 40);

  /// The wall clock.
  Offset get clock => Offset(300, y(0.46));
  double get clockR => (0.11 * a).clamp(34.0, 44.0);
  double get clockTouch => clockR + 16;
  Rect get clockHit => Rect.fromCircle(center: clock, radius: clockTouch);
  bool inClock(Offset p) {
    final d = (p - clock).distance;
    return d <= clockTouch && d >= 6;
  }

  /// The minute hand's tip at [minute] (0–60 from the top, clockwise).
  Offset minuteTip(double minute) {
    final th = -math.pi / 2 + minute / 60 * 2 * math.pi;
    return clock + Offset(math.cos(th), math.sin(th)) * clockR * 0.82;
  }

  /// The wall socket for the bulb.
  Offset get socket => Offset(204, y(0.62));
  Rect get socketHit => Rect.fromCenter(center: socket, width: 52, height: 52);

  /// The trainee's tray: the bulb on its lead, and the tester.
  Rect get bulbTray => Rect.fromLTWH(52, floorY - 60, 90, 52);
  Rect get testerTray => Rect.fromLTWH(150, floorY - 60, 90, 52);

  /// Where the trainee stands on the veranda (left).
  Rect get trainee => Rect.fromLTWH(2, floorY - 112, 46, 112);

  @override
  bool operator ==(Object other) => other is M6PulseGeo && other.height == height && other.floorY == floorY;

  @override
  int get hashCode => Object.hash(height, floorY);
}

void _label(Canvas c, String text, Offset centre, {double size = 6.5, Color color = const Color(0xFF26303D), FontWeight weight = FontWeight.w800}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: weight, color: color, letterSpacing: 0.3, height: 1.05)),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  )..layout(maxWidth: 140);
  tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
}

Paint _fill(Color c) => Paint()..color = c;
Paint _stroke(Color c, double w) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..color = c
  ..strokeCap = StrokeCap.round;

/// One room's appliance as found now.
@immutable
class M6PulseRoom {
  const M6PulseRoom({required this.appliance, required this.switchOn, required this.running});
  final M6PulseAppliance appliance;

  /// The wall switch's rocker is at ON.
  final bool switchOn;

  /// It is drawing power (switched on and the house has supply).
  final bool running;

  @override
  bool operator ==(Object other) => other is M6PulseRoom && other.appliance == appliance && other.switchOn == switchOn && other.running == running;

  @override
  int get hashCode => Object.hash(appliance, switchOn, running);
}

// ============================================================================
// The house
// ============================================================================

/// The cut-away house, panned by [camX]. [powered]: the house has supply
/// (else every room is dark, whatever its switch says).
class M6PulseHousePainter extends CustomPainter {
  const M6PulseHousePainter({required this.geo, required this.camX, required this.rooms, required this.powered});

  final M6PulseGeo geo;
  final double camX;
  final List<M6PulseRoom> rooms;
  final bool powered;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    // The evening sky behind the roof and the yard.
    final sky = Rect.fromLTWH(0, 0, w, g.floorY);
    c.drawRect(
        sky,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B2547), Color(0xFF6A4C78), Color(0xFFE09A6A)],
          ).createShader(sky));
    c.save();
    c.translate(-camX, 0);
    // The ground.
    final ground = Rect.fromLTRB(-20, g.floorY, kM6PulsePanoW + 20, size.height);
    c.drawRect(ground, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF6B5A45), Color(0xFF3F3428)]).createShader(ground));
    // The house body (rooms 0–3) under one roof; the yard open.
    final houseR = M6PulseGeo.roomRight(3);
    final roofY = M6PulseGeo.top - 18;
    final roof = Path()
      ..moveTo(-10, roofY + 14)
      ..lineTo(houseR + 14, roofY + 14)
      ..lineTo(houseR + 4, roofY - 6)
      ..lineTo(0, roofY - 6)
      ..close();
    c.drawPath(roof, Paint()..shader = const LinearGradient(colors: [Color(0xFF7A3B2A), Color(0xFF5A2A1E)]).createShader(Rect.fromLTRB(0, roofY - 6, houseR, roofY + 14)));
    for (var i = 0; i < 4; i++) {
      final r = Rect.fromLTRB(M6PulseGeo.roomLeft(i), roofY + 14, M6PulseGeo.roomRight(i), g.floorY);
      final lit = powered && rooms[i].running;
      c.drawRect(
          r,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: !powered
                  ? const [Color(0xFF232A3C), Color(0xFF1A2030)]
                  : (lit ? const [Color(0xFFF2E3BE), Color(0xFFD9C79E)] : const [Color(0xFFC9BC9A), Color(0xFFAE9F7F)]),
            ).createShader(r));
      // Skirting and the wall between rooms.
      c.drawRect(Rect.fromLTRB(r.left, g.floorY - 8, r.right, g.floorY), _fill(const Color(0xFF6E5A44)));
      c.drawRect(Rect.fromLTWH(r.right - 3, r.top, 6, r.height), _fill(const Color(0xFF8A7458)));
    }
    c.drawRect(Rect.fromLTWH(0, roofY + 14, 6, g.floorY - roofY - 14), _fill(const Color(0xFF8A7458)));
    // The yard: a low wall and a tap stand.
    final yard = Rect.fromLTRB(M6PulseGeo.roomLeft(4), g.y(0.62), M6PulseGeo.roomRight(4), g.floorY);
    c.drawRect(Rect.fromLTRB(yard.left, g.floorY - 30, yard.right, g.floorY), _fill(const Color(0xFF9B8B74)));
    for (var x = yard.left + 6; x < yard.right; x += 26) {
      c.drawLine(Offset(x, g.floorY - 30), Offset(x, g.floorY), _stroke(const Color(0xFF7D6E5A), 1));
    }
    for (var i = 0; i < 5; i++) {
      _appliance(c, i);
      _switch(c, i);
    }
    _customer(c);
    c.restore();
  }

  /// The customer in the front room, his bill in hand.
  void _customer(Canvas c) {
    final g = geo;
    final foot = Offset(g.switchAt(0).center.dx, g.floorY - 6);
    final h = math.min(84.0, foot.dy - g.switchAt(0).bottom - 6);
    final s = h / 84;
    final body = Rect.fromCenter(center: foot.translate(0, -h * 0.5), width: 22 * s, height: h * 0.42);
    c.drawLine(foot.translate(-5 * s, 0), body.bottomCenter.translate(-4 * s, 0), _stroke(const Color(0xFF3A3A48), 5 * s));
    c.drawLine(foot.translate(5 * s, 0), body.bottomCenter.translate(4 * s, 0), _stroke(const Color(0xFF3A3A48), 5 * s));
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(6 * s)), _fill(const Color(0xFFE8E2D0)));
    c.drawCircle(body.topCenter.translate(0, -10 * s), 9 * s, _fill(const Color(0xFF9A6A48)));
    c.drawArc(Rect.fromCircle(center: body.topCenter.translate(0, -12 * s), radius: 9 * s), math.pi, math.pi, true, _fill(const Color(0xFF2A2A2A)));
    // The bill.
    final bill = Rect.fromLTWH(body.right - 2, body.top + 8 * s, 14 * s, 18 * s);
    c.drawRect(bill, _fill(const Color(0xFFFFFFFF)));
    for (var k = 0; k < 3; k++) {
      c.drawLine(bill.topLeft.translate(2 * s, (5 + 4 * k) * s), bill.topRight.translate(-2 * s, (5 + 4 * k) * s), _stroke(const Color(0xFF8A8A8A), 0.8));
    }
  }

  void _appliance(Canvas c, int i) {
    final g = geo;
    final r = g.appliance(i);
    final room = rooms[i];
    final on = powered && room.running;
    switch (room.appliance) {
      case M6PulseAppliance.fan:
        final hub = Offset(M6PulseGeo.roomX(i), r.top + 10);
        c.drawLine(Offset(hub.dx, r.top - 18), hub, _stroke(const Color(0xFF4A4A4A), 3));
        if (on) {
          // A running fan: the blades are a soft blur.
          c.drawOval(Rect.fromCenter(center: hub.translate(0, 4), width: 96, height: 22), _fill(const Color(0x66828A93)));
          c.drawOval(Rect.fromCenter(center: hub.translate(0, 4), width: 70, height: 14), _fill(const Color(0x55A7AFB8)));
        } else {
          for (final s in [-1.0, 1.0]) {
            c.drawOval(Rect.fromCenter(center: hub.translate(s * 26, 4), width: 44, height: 8), _fill(const Color(0xFF7D858E)));
          }
          c.drawOval(Rect.fromCenter(center: hub.translate(0, 6), width: 10, height: 18), _fill(const Color(0xFF6B737C)));
        }
        c.drawCircle(hub.translate(0, 4), 7, _fill(const Color(0xFF5B636C)));
      case M6PulseAppliance.tube:
        final tube = Rect.fromCenter(center: Offset(M6PulseGeo.roomX(i), r.top + 12), width: 80, height: 9);
        if (on) {
          c.drawRect(tube.inflate(26), Paint()..shader = RadialGradient(colors: [const Color(0x88FFFDE8), const Color(0x00FFFDE8)]).createShader(tube.inflate(26)));
        }
        c.drawRRect(RRect.fromRectAndRadius(tube.inflate(2), const Radius.circular(4)), _fill(const Color(0xFF8C8C8C)));
        c.drawRRect(RRect.fromRectAndRadius(tube, const Radius.circular(4)), _fill(on ? const Color(0xFFFFFFF4) : const Color(0xFFBFC3C6)));
      case M6PulseAppliance.tv:
        // On its table, standing on the floor.
        final table = Rect.fromLTWH(r.left, r.bottom - 40, r.width, 40);
        c.drawRect(table, _fill(const Color(0xFF6A4A30)));
        c.drawRect(Rect.fromLTWH(table.left + 4, table.top + 8, table.width - 8, 3), _fill(const Color(0xFF4E3622)));
        final tv = Rect.fromLTWH(r.left + 2, table.top - 50, r.width - 4, 44);
        c.drawRRect(RRect.fromRectAndRadius(tv, const Radius.circular(4)), _fill(const Color(0xFF1C1C20)));
        final screen = tv.deflate(4);
        c.drawRect(
            screen,
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: on ? const [Color(0xFF7FD3FF), Color(0xFF3A7BD5)] : const [Color(0xFF14161A), Color(0xFF26292F)],
              ).createShader(screen));
        c.drawRect(Rect.fromLTWH(tv.center.dx - 8, tv.bottom, 16, 6), _fill(const Color(0xFF1C1C20)));
      case M6PulseAppliance.fridge:
        // An old fridge on the floor behind a curtain: its top and its door
        // lamp show.
        final fh = (0.5 * geo.a).clamp(110.0, 200.0);
        final body = Rect.fromLTWH(r.left + 2, r.bottom - fh, r.width - 4, fh);
        c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(6)), _fill(const Color(0xFFDCE2E2)));
        final lamp = Offset(body.right - 9, body.bottom - 12);
        if (on) c.drawCircle(lamp, 6, _fill(const Color(0x6643E07A)));
        c.drawCircle(lamp, 2.6, _fill(on ? const Color(0xFF43E07A) : const Color(0xFF4F5A52)));
        final curtain = Rect.fromLTRB(body.left - 4, body.top + 18, body.right + 4, body.bottom - 22);
        c.drawLine(Offset(curtain.left - 4, curtain.top), Offset(curtain.right + 4, curtain.top), _stroke(const Color(0xFF6B4A2A), 3));
        c.drawRect(curtain, Paint()..shader = const LinearGradient(colors: [Color(0xFF9C3F55), Color(0xFFB85A6E), Color(0xFF9C3F55), Color(0xFFB85A6E)]).createShader(curtain));
        for (var x = curtain.left + 9; x < curtain.right; x += 12) {
          c.drawLine(Offset(x, curtain.top), Offset(x, curtain.bottom), _stroke(const Color(0x33000000), 1.2));
        }
      case M6PulseAppliance.pump:
        // On a brick plinth in the yard (high enough to be seen over the
        // guide's corner), its pipe to a bucket.
        final top = geo.y(0.64);
        final plinth = Rect.fromLTRB(r.left - 4, top, r.right + 4, geo.floorY);
        c.drawRect(plinth, _fill(const Color(0xFF9A5A44)));
        for (var yy = top + 10; yy < geo.floorY; yy += 10) {
          c.drawLine(Offset(plinth.left, yy), Offset(plinth.right, yy), _stroke(const Color(0xFF7A4434), 1));
        }
        final base = Rect.fromLTWH(r.left, top - 30, 50, 30);
        c.drawRRect(RRect.fromRectAndRadius(base, const Radius.circular(5)), _fill(const Color(0xFF2E6FA8)));
        c.drawCircle(base.centerLeft.translate(14, -2), 10, _fill(const Color(0xFF235A8A)));
        final spout = Offset(r.right - 14, base.top + 4);
        final pipe = Path()
          ..moveTo(base.right, base.top + 8)
          ..lineTo(spout.dx, base.top + 8)
          ..lineTo(spout.dx, spout.dy + 14);
        c.drawPath(pipe, _stroke(const Color(0xFF8A8F94), 5));
        final bucket = Rect.fromLTWH(spout.dx - 13, top - 24, 26, 24);
        c.drawRect(bucket, _fill(const Color(0xFF6E7B86)));
        if (on) {
          c.drawLine(Offset(spout.dx, spout.dy + 16), Offset(spout.dx, bucket.top + 2), _stroke(const Color(0xCC8FD3FF), 3.2));
          c.drawRect(Rect.fromLTWH(bucket.left + 2, bucket.top + 3, bucket.width - 4, 5), _fill(const Color(0xCC6FB8E8)));
        }
        // The pump's cable to its switch on the post.
        final sw = geo.switchAt(i);
        c.drawLine(base.topLeft.translate(6, 0), Offset(sw.center.dx, sw.bottom), _stroke(const Color(0xFF3A3A3A), 1.6));
    }
  }

  void _switch(Canvas c, int i) {
    if (i == 4) {
      // The yard switch is on a post.
      final s = geo.switchAt(i);
      c.drawRect(Rect.fromLTRB(s.center.dx - 4, s.center.dy, s.center.dx + 4, geo.floorY), _fill(const Color(0xFF7A6A55)));
    }
    final r = geo.switchAt(i).deflate(6);
    final on = rooms[i].switchOn;
    c.drawRRect(RRect.fromRectAndRadius(r.inflate(2), const Radius.circular(5)), _fill(const Color(0x44000000)));
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(5)), _fill(const Color(0xFFF4F1EA)));
    final rocker = Rect.fromCenter(center: r.center.translate(0, 2), width: 16, height: 24);
    c.drawRRect(RRect.fromRectAndRadius(rocker, const Radius.circular(3)), _fill(const Color(0xFFDCD7CC)));
    // Indian switch: rocker pressed at the bottom = ON.
    final pressed = on ? Rect.fromLTRB(rocker.left, rocker.center.dy, rocker.right, rocker.bottom) : Rect.fromLTRB(rocker.left, rocker.top, rocker.right, rocker.center.dy);
    c.drawRRect(RRect.fromRectAndRadius(pressed, const Radius.circular(3)), _fill(const Color(0xFFB9B3A6)));
    // The pilot lamp lights only with the switch ON and supply in the house.
    final pilot = Offset(r.center.dx, r.top + 6);
    c.drawCircle(pilot, 2.6, _fill(on && powered ? const Color(0xFFFF4A3A) : const Color(0xFF8A7F78)));
  }

  @override
  bool shouldRepaint(M6PulseHousePainter old) => old.geo != geo || old.camX != camX || old.powered != powered || !_same(old.rooms, rooms);

  static bool _same(List<M6PulseRoom> a, List<M6PulseRoom> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

// ============================================================================
// The veranda
// ============================================================================

/// What the veranda shows now.
@immutable
class M6PulseRig {
  const M6PulseRig({
    this.lcdOn = true,
    this.reading = 0,
    this.minute = 10,
    this.hour = 7,
    this.plugged = false,
    this.plugAt,
    this.testerAt,
    this.testerOnIncoming = false,
    this.testerLit = false,
  });

  /// The LCD shows (a blank meter shows nothing).
  final bool lcdOn;

  /// The kWh on the LCD in tenths.
  final int reading;

  /// The clock: the minute (0–60, may be fractional) and the hour.
  final double minute;
  final int hour;

  /// The bulb is in the socket (lit).
  final bool plugged;

  /// The bulb's plug while dragged (null: on its tray or in the socket).
  final Offset? plugAt;

  /// The tester while dragged (null: on its tray or on the terminals).
  final Offset? testerAt;
  final bool testerOnIncoming;
  final bool testerLit;

  @override
  bool operator ==(Object other) =>
      other is M6PulseRig &&
      other.lcdOn == lcdOn &&
      other.reading == reading &&
      other.minute == minute &&
      other.hour == hour &&
      other.plugged == plugged &&
      other.plugAt == plugAt &&
      other.testerAt == testerAt &&
      other.testerOnIncoming == testerOnIncoming &&
      other.testerLit == testerLit;

  @override
  int get hashCode => Object.hash(lcdOn, reading, minute, hour, plugged, plugAt, testerAt, testerOnIncoming, testerLit);
}

/// The kWh in tenths as the LCD shows it ("01234.5").
String m6PulseLcd(int tenths) => '${(tenths ~/ 10).toString().padLeft(5, '0')}.${tenths % 10}';

/// The veranda: the wall, the pole and the cable, the meter (all but its CAL
/// LED, which [M6PulseLedPainter] draws), the clock, the socket and the tray.
class M6PulseVerandaPainter extends CustomPainter {
  const M6PulseVerandaPainter({required this.geo, required this.rig});

  final M6PulseGeo geo;
  final M6PulseRig rig;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    // The evening sky over the veranda wall's top.
    final sky = Rect.fromLTWH(0, 0, w, M6PulseGeo.top + 60);
    c.drawRect(sky, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1B2547), Color(0xFF7A5578)]).createShader(sky));
    // The pole (right) behind the wall.
    c.drawRect(Rect.fromLTWH(g.poleTop.dx - 6, g.poleTop.dy - 20, 12, g.floorY), Paint()..shader = const LinearGradient(colors: [Color(0xFF9A9A92), Color(0xFF6E6E68)]).createShader(Rect.fromLTWH(g.poleTop.dx - 6, 0, 12, 10)));
    c.drawRect(Rect.fromLTWH(g.poleTop.dx - 30, g.poleTop.dy - 6, 60, 6), _fill(const Color(0xFF5A5A55)));
    for (final dx in [-24.0, 0.0, 24.0]) {
      c.drawLine(Offset(g.poleTop.dx + dx - 30, g.poleTop.dy - 14), Offset(g.poleTop.dx + dx + 30, g.poleTop.dy - 12), _stroke(const Color(0xFF2A2A2A), 1.4));
    }
    c.drawCircle(g.cableFrom, 4, _fill(const Color(0xFF3A3A3A)));
    // The veranda wall.
    final wall = Rect.fromLTRB(0, M6PulseGeo.top + 50, w, g.floorY);
    c.drawRect(wall, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFD8C9A4), Color(0xFFC2B28C)]).createShader(wall));
    c.drawRect(Rect.fromLTRB(0, M6PulseGeo.top + 44, w * 0.78, M6PulseGeo.top + 54), _fill(const Color(0xFF7A3B2A)));
    final floor = Rect.fromLTRB(0, g.floorY, w, size.height);
    c.drawRect(floor, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8E7E6A), Color(0xFF5E5244)]).createShader(floor));
    c.drawRect(Rect.fromLTRB(0, g.floorY - 6, w, g.floorY), _fill(const Color(0xFF6E5A44)));
    // The service cable: pole top → the meter's top.
    final cable = Path()
      ..moveTo(g.cableFrom.dx, g.cableFrom.dy)
      ..quadraticBezierTo(g.cableMid.dx, g.cableMid.dy + 10, g.cableTo.dx, g.cableTo.dy - 6)
      ..lineTo(g.cableTo.dx, g.cableTo.dy);
    c.drawPath(cable, _stroke(const Color(0xFF1E1E1E), 3.4));
    _meter(c);
    _clock(c);
    _socket(c);
    _tray(c);
  }

  void _meter(Canvas c) {
    final g = geo;
    final m = g.meter;
    c.drawRRect(RRect.fromRectAndRadius(m.inflate(3).shift(const Offset(2, 3)), const Radius.circular(8)), _fill(const Color(0x44000000)));
    c.drawRRect(RRect.fromRectAndRadius(m, const Radius.circular(8)), Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFF2F2EE), Color(0xFFD3D6D6)]).createShader(m));
    c.drawRRect(RRect.fromRectAndRadius(m, const Radius.circular(8)), _stroke(const Color(0xFF8A9096), 1.6));
    // The LCD.
    final l = g.lcd;
    c.drawRRect(RRect.fromRectAndRadius(l.inflate(2), const Radius.circular(3)), _fill(const Color(0xFF555A5E)));
    c.drawRect(l, _fill(rig.lcdOn ? const Color(0xFFB8D8A6) : const Color(0xFF8E9A88)));
    if (rig.lcdOn) {
      _label(c, m6PulseLcd(rig.reading), l.center.translate(-6, 1), size: 15, color: const Color(0xFF1E2A1A), weight: FontWeight.w700);
      _label(c, 'kWh', Offset(l.right - 10, l.bottom - 6), size: 5.6, color: const Color(0xFF1E2A1A));
    }
    // The push-button and the LED's print (the LED itself is its own layer).
    c.drawCircle(g.pushButton, 8, _fill(const Color(0xFF3A5F8A)));
    c.drawCircle(g.pushButton, 8, _stroke(const Color(0xFF203A58), 1.4));
    c.drawCircle(g.led, 7, _fill(const Color(0xFF3A3F44)));
    _label(c, 'CAL', g.led.translate(0, -12), size: 5.4);
    _label(c, '3200 imp/kWh', g.led.translate(-12, 13), size: 5.4);
    // The sealed terminal cover.
    final cv = g.cover;
    c.drawRRect(RRect.fromRectAndRadius(cv, const Radius.circular(4)), Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFC9CDCF), Color(0xFFAEB3B6)]).createShader(cv));
    c.drawLine(cv.topLeft.translate(4, 0), cv.topRight.translate(-4, 0), _stroke(const Color(0xFF7D8388), 1.2));
    _label(c, 'IN', Offset(cv.left + 16, cv.top + 9), size: 6);
    _label(c, 'OUT', Offset(cv.right - 18, cv.top + 9), size: 6);
    // The seal: a wire loop and a lead disc.
    final seal = Offset(cv.center.dx, cv.top + 12);
    c.drawLine(seal.translate(-10, -6), seal, _stroke(const Color(0xFF9A9A9A), 1));
    c.drawCircle(seal, 4, _fill(const Color(0xFF8A8F96)));
    // The cables into the cover from below (IN from the service cable side).
    c.drawLine(Offset(cv.left + 16, cv.bottom), Offset(cv.left + 16, cv.bottom + 26), _stroke(const Color(0xFF1E1E1E), 3));
    c.drawLine(Offset(cv.right - 18, cv.bottom), Offset(cv.right - 18, cv.bottom + 26), _stroke(const Color(0xFF1E1E1E), 3));
    // The tester on the incoming terminals, its lamp lit or dark.
    if (rig.testerOnIncoming) _tester(c, Offset(cv.left + 18, cv.top + 22), lit: rig.testerLit);
  }

  void _clock(Canvas c) {
    final g = geo;
    final o = g.clock;
    final r = g.clockR;
    c.drawCircle(o.translate(2, 3), r + 4, _fill(const Color(0x44000000)));
    c.drawCircle(o, r + 4, _fill(const Color(0xFF6A4A30)));
    c.drawCircle(o, r, Paint()..shader = const RadialGradient(colors: [Color(0xFFFFFDF4), Color(0xFFE8E1CC)]).createShader(Rect.fromCircle(center: o, radius: r)));
    for (var i = 0; i < 12; i++) {
      final th = -math.pi / 2 + i / 12 * 2 * math.pi;
      final d = Offset(math.cos(th), math.sin(th));
      if (i % 3 == 0) {
        _label(c, '${i == 0 ? 12 : i}', o + d * (r - 9), size: 7.5, color: const Color(0xFF2A2018));
      } else {
        c.drawLine(o + d * (r - 6), o + d * (r - 2), _stroke(const Color(0xFF2A2018), 1.2));
      }
    }
    final minute = rig.minute;
    final hourF = (rig.hour % 12) + minute / 60;
    final thH = -math.pi / 2 + hourF / 12 * 2 * math.pi;
    c.drawLine(o, o + Offset(math.cos(thH), math.sin(thH)) * r * 0.5, _stroke(const Color(0xFF2A2018), 3.2));
    c.drawLine(o, g.minuteTip(minute), _stroke(const Color(0xFF2A2018), 2.2));
    c.drawCircle(o, 3, _fill(const Color(0xFFB0322A)));
  }

  void _socket(Canvas c) {
    final g = geo;
    final s = Rect.fromCenter(center: g.socket, width: 34, height: 40);
    c.drawRRect(RRect.fromRectAndRadius(s.inflate(2), const Radius.circular(4)), _fill(const Color(0x44000000)));
    c.drawRRect(RRect.fromRectAndRadius(s, const Radius.circular(4)), _fill(const Color(0xFFF4F1EA)));
    for (final p in [g.socket.translate(-6, 4), g.socket.translate(6, 4), g.socket.translate(0, -6)]) {
      c.drawCircle(p, 2.4, _fill(const Color(0xFF3A3A3A)));
    }
    if (rig.plugged) {
      // The plug in; the bulb hangs on its lead, lit.
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: g.socket.translate(0, 2), width: 18, height: 20), const Radius.circular(3)), _fill(const Color(0xFF2A2A2A)));
      final bulb = g.socket.translate(0, 44);
      c.drawLine(g.socket.translate(0, 12), bulb.translate(0, -12), _stroke(const Color(0xFF1E1E1E), 2));
      c.drawCircle(bulb, 22, _fill(const Color(0x55FFF0A8)));
      _bulb(c, bulb, lit: true);
    }
  }

  void _tray(Canvas c) {
    final g = geo;
    for (final t in [g.bulbTray, g.testerTray]) {
      c.drawRRect(RRect.fromRectAndRadius(t, const Radius.circular(6)), _fill(const Color(0xFF4A3A2C)));
      c.drawRRect(RRect.fromRectAndRadius(t.deflate(3), const Radius.circular(5)), _fill(const Color(0xFF6B5440)));
    }
    if (!rig.plugged) {
      final at = rig.plugAt;
      final bulb = g.bulbTray.centerLeft.translate(22, 0);
      _bulb(c, bulb, lit: false);
      final plug = at ?? g.bulbTray.centerRight.translate(-18, 0);
      final lead = Path()
        ..moveTo(bulb.dx + 10, bulb.dy)
        ..quadraticBezierTo((bulb.dx + plug.dx) / 2, math.max(bulb.dy, plug.dy) + 14, plug.dx, plug.dy);
      c.drawPath(lead, _stroke(const Color(0xFF1E1E1E), 2));
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: plug, width: 16, height: 18), const Radius.circular(3)), _fill(const Color(0xFF2A2A2A)));
      c.drawLine(plug.translate(-4, -9), plug.translate(-4, -14), _stroke(const Color(0xFFC8A040), 2));
      c.drawLine(plug.translate(4, -9), plug.translate(4, -14), _stroke(const Color(0xFFC8A040), 2));
    }
    if (!rig.testerOnIncoming) _tester(c, rig.testerAt ?? g.testerTray.center, lit: false);
  }

  void _bulb(Canvas c, Offset o, {required bool lit}) {
    c.drawCircle(o, 11, Paint()..shader = RadialGradient(colors: lit ? const [Color(0xFFFFFFF0), Color(0xFFFFD86A)] : const [Color(0xFFF4F4F0), Color(0xFFC9CCCC)]).createShader(Rect.fromCircle(center: o, radius: 11)));
    c.drawRect(Rect.fromCenter(center: o.translate(0, -12), width: 9, height: 7), _fill(const Color(0xFFB0A070)));
  }

  /// The insulated tester: a red-handled probe with its neon lamp.
  void _tester(Canvas c, Offset tip, {required bool lit}) {
    final body = Rect.fromLTWH(tip.dx - 5, tip.dy, 10, 34);
    c.drawLine(tip.translate(0, -8), tip, _stroke(const Color(0xFFB8B8B8), 2.4));
    c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(4)), _fill(const Color(0xFFC0392B)));
    final lamp = tip.translate(0, 9);
    if (lit) c.drawCircle(lamp, 7, _fill(const Color(0x88FF7A3A)));
    c.drawCircle(lamp, 3, _fill(lit ? const Color(0xFFFFB070) : const Color(0xFF5A2A20)));
  }

  @override
  bool shouldRepaint(M6PulseVerandaPainter old) => old.geo != geo || old.rig != rig;
}

/// How the CAL LED behaves during a look.
/// [leak]: every load off, yet a fast blink (lesson 6.10 point 2).
/// [off]: a blank meter (no supply reaches it) — the LED is dark, always.
enum M6PulseLed { off, steady, leak, fast, faster }

/// The CAL LED alone (it repaints with its look's clock, nothing else does).
/// [t]: the look's progress 0…1 over its window (null: no look running —
/// the LED rests lit, the same for every truth — except [M6PulseLed.off],
/// which never lights).
class M6PulseLedPainter extends CustomPainter {
  M6PulseLedPainter({required this.geo, required this.pattern, required this.windowMs, this.t}) : super(repaint: t);

  final M6PulseGeo geo;
  final M6PulseLed pattern;
  final int windowMs;
  final Animation<double>? t;

  /// Lit at [ms] into the look.
  static bool litAt(M6PulseLed p, double ms) {
    if (p == M6PulseLed.off) return false;
    final period = switch (p) {
      M6PulseLed.off => 0.0,
      M6PulseLed.steady => 0.0,
      M6PulseLed.leak => 520.0,
      M6PulseLed.fast => 760.0,
      M6PulseLed.faster => 420.0,
    };
    if (period == 0) return true;
    return (ms % period) < 150;
  }

  @override
  void paint(Canvas c, Size size) {
    final anim = t;
    final running = anim != null && anim.value > 0 && anim.value < 1;
    final lit = pattern != M6PulseLed.off && (!running || litAt(pattern, anim.value * windowMs));
    final o = geo.led;
    if (lit) c.drawCircle(o, 9, _fill(const Color(0x66FF3B30)));
    c.drawCircle(
        o,
        5,
        Paint()
          ..shader = RadialGradient(colors: lit ? const [Color(0xFFFFFFFF), Color(0xFFFF3B30)] : const [Color(0xFF7A2A26), Color(0xFF4A1A18)])
              .createShader(Rect.fromCircle(center: o, radius: 5)));
  }

  @override
  bool shouldRepaint(M6PulseLedPainter old) => old.geo != geo || old.pattern != pattern || old.t != t || old.windowMs != windowMs;
}
