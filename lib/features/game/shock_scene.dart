import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'shock_rescue.dart' show BodyZone, RescueObject, ShockScene;

// The drawn places of lesson 1.7's "ছোঁবেন না!" (shock_rescue.dart): a
// house, a pump room, a paddy field and a roadside, each a layered scene —
// sky or room, the far layer, the place where the colleague is stuck to the
// wire — plus the colleague himself, the switch on the wall, the things lying
// about, and the current's path for the deadly freeze. Non-graphic: the
// colleague is stiff at the wire with a buzzing spark at his grip; freed, he
// sits slumped. No text in the art (only ON / OFF on the switch).
//
// Design: 360 wide × the scene's height; the floor row follows the bottom of
// the screen. The colleague faces left, the source is on the left, the
// trainee stands left and pushes him to the right, away from the wire.

/// Where things stand in the shock scene (design px, 360 wide).
@immutable
class ShockGeo {
  const ShockGeo({required this.height, required this.groundY});

  /// The scene of design height [h] with [inset] (bottom system inset, design px).
  /// The colleague stands high enough that the corner guide's bubble
  /// (bottom right) stays below his legs, a push target.
  factory ShockGeo.forScene(double h, double inset) => ShockGeo(height: h, groundY: h - 236 - inset);

  final double height;

  /// Where the colleague's feet stand.
  final double groundY;

  /// The colleague's feet (centre).
  static const vx = 206.0;

  double get gy => groundY;

  /// His hand on the wire.
  Offset get grip => Offset(vx - 52, gy - 126);
  Offset get head => Offset(vx - 2, gy - 139);
  Offset get chest => Offset(vx, gy - 98);

  /// The switch on the wall (house: main board; pump room: the pump's switch box).
  Rect get switchRect => Rect.fromLTWH(22, gy - 270, 66, 96);

  /// Where the things lie on the floor in front.
  Rect slot(int i) => Rect.fromLTWH(10 + i * 58.0, gy + 94, 54, 80);

  /// The trainee at his place (feet a little in front of the colleague's).
  Rect get traineeHome => Rect.fromLTWH(14, gy + 8 - traineeSize.height, traineeSize.width, traineeSize.height);
  static const traineeSize = Size(76, 152);

  /// The arm on the wire, and his other arm.
  Rect get frontArm => Rect.fromLTRB(vx - 50, gy - 138, vx - 16, gy - 108);
  Rect get backArm => Rect.fromLTRB(vx + 12, gy - 120, vx + 36, gy - 62);

  Rect zone(BodyZone z) => switch (z) {
        BodyZone.head => Rect.fromCircle(center: head, radius: 17),
        BodyZone.chest => Rect.fromLTRB(vx - 19, gy - 124, vx + 13, gy - 70),
        BodyZone.arm => frontArm,
        BodyZone.leg => Rect.fromLTRB(vx - 22, gy - 70, vx + 22, gy + 2),
      };

  /// The part of him at [p], or null.
  BodyZone? zoneAt(Offset p) {
    if ((p - head).distance <= 18) return BodyZone.head;
    if (frontArm.inflate(4).contains(p) || backArm.inflate(4).contains(p)) return BodyZone.arm;
    if (zone(BodyZone.chest).inflate(3).contains(p)) return BodyZone.chest;
    if (zone(BodyZone.leg).inflate(4).contains(p)) return BodyZone.leg;
    return null;
  }

  /// Where the wire comes from in [s].
  Offset source(ShockScene s) => switch (s) {
        ShockScene.house => Offset(119, gy - 96),
        ShockScene.pump => Offset(switchRect.right, gy - 206),
        ShockScene.field => Offset(38, gy - 300),
        ShockScene.roadside => Offset(21, gy - 292),
      };

  @override
  bool operator ==(Object other) => other is ShockGeo && other.height == height && other.groundY == groundY;

  @override
  int get hashCode => Object.hash(height, groundY);
}

// ============================================================================
// The places
// ============================================================================

/// The place behind everything (static: drawn once per scene).
class ShockPlacePainter extends CustomPainter {
  const ShockPlacePainter({required this.scene, required this.geo});
  final ShockScene scene;
  final ShockGeo geo;

  @override
  void paint(Canvas c, Size s) {
    switch (scene) {
      case ShockScene.house:
        _house(c, s);
      case ShockScene.pump:
        _pump(c, s);
      case ShockScene.field:
        _field(c, s);
      case ShockScene.roadside:
        _roadside(c, s);
    }
  }

  // --- shared bits ---------------------------------------------------------------
  static void _vertical(Canvas c, Rect r, List<Color> colors, [List<double>? stops]) => c.drawRect(
        r,
        Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors, stops: stops).createShader(r),
      );

  void _sky(Canvas c, Size s, double hz) {
    _vertical(c, Rect.fromLTWH(0, 0, s.width, hz + 4), const [Color(0xFF5E9BD0), Color(0xFF9CC6E6), Color(0xFFEDE6CF)], const [0, 0.62, 1]);
    final sun = Offset(s.width * 0.8, hz - 290);
    c.drawCircle(sun, 110, Paint()..shader = const RadialGradient(colors: [Color(0x80FFF4D2), Color(0x00FFF4D2)]).createShader(Rect.fromCircle(center: sun, radius: 110)));
    c.drawCircle(sun, 15, Paint()..color = const Color(0xFFFFF6DC));
    final cloud = Paint()..color = const Color(0xD9FFFFFF);
    for (final (x, y, r) in const [(70.0, 0.30, 20.0), (250.0, 0.20, 16.0), (330.0, 0.36, 22.0)]) {
      final cy = hz * y + 30;
      c.drawOval(Rect.fromCenter(center: Offset(x, cy), width: r * 4.2, height: r * 1.3), cloud);
      c.drawCircle(Offset(x - r * 0.6, cy - r * 0.35), r * 0.8, cloud);
      c.drawCircle(Offset(x + r * 0.5, cy - r * 0.5), r, cloud);
    }
  }

  void _treeLine(Canvas c, double w, double hz, Color col) {
    final p = Path()..moveTo(0, hz);
    for (var x = 0.0; x <= w + 16; x += 16) {
      final bump = 12 + 8 * math.sin(x * 0.05) + 5 * math.sin(x * 0.17 + 1.1);
      p.quadraticBezierTo(x + 8, hz - bump - 9, x + 16, hz - bump * 0.6);
    }
    p
      ..lineTo(w, hz + 2)
      ..lineTo(0, hz + 2)
      ..close();
    c.drawPath(p, Paint()..color = col);
  }

  /// A concrete pole from [top] to [base] at [x], with a cross-arm and pin insulators.
  void _pole(Canvas c, double x, double top, double base, double k) {
    final body = Rect.fromLTRB(x - 6 * k, top, x + 6 * k, base);
    c.drawRect(body, Paint()..shader = const LinearGradient(colors: [Color(0xFF8E9296), Color(0xFFC9CCCE), Color(0xFF8A8E92)]).createShader(body));
    final arm = Rect.fromLTRB(x - 30 * k, top + 12 * k, x + 30 * k, top + 18 * k);
    c.drawRect(arm, Paint()..color = const Color(0xFF5C5F63));
    for (final dx in [-26.0, 0.0, 26.0]) {
      final ins = Rect.fromCenter(center: Offset(x + dx * k, top + 7 * k), width: 7 * k, height: 10 * k);
      c.drawRRect(RRect.fromRectAndRadius(ins, Radius.circular(2 * k)), Paint()..color = const Color(0xFF7A4A2A));
    }
    c.drawOval(Rect.fromCenter(center: Offset(x, base), width: 22 * k, height: 5 * k), Paint()..color = const Color(0x55000000));
  }

  void _wire(Canvas c, Offset a, Offset b, double sag, {double width = 1.6, Color color = const Color(0xFF2A2D31)}) {
    final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2 + sag);
    c.drawPath(
      Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, b.dx, b.dy),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
  }

  void _tufts(Canvas c, double w, double from, double to, Color col) {
    final p = Paint()
      ..color = col
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final rng = math.Random(7);
    for (var i = 0; i < 40; i++) {
      final x = rng.nextDouble() * w;
      final y = from + rng.nextDouble() * (to - from);
      c.drawLine(Offset(x, y), Offset(x - 2, y - 6), p);
      c.drawLine(Offset(x, y), Offset(x + 2.5, y - 7), p);
    }
  }

  // --- the house ------------------------------------------------------------------
  void _house(Canvas c, Size s) {
    final w = s.width;
    final gy = geo.gy;
    final floorY = gy - 26;
    _vertical(c, Rect.fromLTWH(0, 0, w, floorY), const [Color(0xFFD9CCB2), Color(0xFFEDE3CF), Color(0xFFE4D6BB)], const [0, 0.5, 1]);
    // Window with its grill and a curtain.
    final win = Rect.fromLTWH(232, gy - 318, 96, 124);
    c.drawRect(win.inflate(6), Paint()..color = const Color(0xFF7A5232));
    _vertical(c, win, const [Color(0xFF6FA7D6), Color(0xFFBFDDF0), Color(0xFFD8E8C6)], const [0, 0.7, 1]);
    c.drawOval(Rect.fromCenter(center: win.center.translate(-14, -30), width: 46, height: 14), Paint()..color = const Color(0xCCFFFFFF));
    c.drawRect(Rect.fromLTWH(win.left, win.bottom - 26, win.width, 26), Paint()..color = const Color(0xFF6E9A58));
    final grill = Paint()
      ..color = const Color(0xFF3B3F44)
      ..strokeWidth = 2;
    for (var x = win.left + 16; x < win.right; x += 16) {
      c.drawLine(Offset(x, win.top), Offset(x, win.bottom), grill);
    }
    c.drawLine(Offset(win.left, win.center.dy), Offset(win.right, win.center.dy), grill);
    final curtain = Path()
      ..moveTo(win.right - 4, win.top - 8)
      ..lineTo(win.right + 16, win.top - 8)
      ..quadraticBezierTo(win.right + 10, win.center.dy, win.right + 20, win.bottom + 14)
      ..lineTo(win.right - 10, win.bottom + 14)
      ..quadraticBezierTo(win.right - 2, win.center.dy, win.right - 4, win.top - 8)
      ..close();
    c.drawPath(curtain, Paint()..shader = const LinearGradient(colors: [Color(0xFFB8463A), Color(0xFF8E2E26)]).createShader(curtain.getBounds()));
    // A wall clock (ticks only) and a shelf.
    final clock = Offset(166, gy - 212);
    c.drawCircle(clock, 17, Paint()..color = const Color(0xFF6B4A2E));
    c.drawCircle(clock, 14, Paint()..color = const Color(0xFFFFFBF0));
    final tick = Paint()
      ..color = const Color(0xFF333333)
      ..strokeWidth = 1.2;
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      c.drawLine(clock + Offset(math.cos(a), math.sin(a)) * 11, clock + Offset(math.cos(a), math.sin(a)) * 13, tick);
    }
    c.drawLine(clock, clock + const Offset(0, -9), tick..strokeWidth = 1.6);
    c.drawLine(clock, clock + const Offset(6, 2), tick);
    c.drawRect(Rect.fromLTWH(140, gy - 248, 64, 5), Paint()..color = const Color(0xFF7A5232));
    c.drawRect(Rect.fromLTWH(148, gy - 266, 12, 18), Paint()..color = const Color(0xFF3F7DA8));
    c.drawRect(Rect.fromLTWH(164, gy - 262, 18, 14), Paint()..color = const Color(0xFFC9973E));
    // The conduit from the main board down to the socket.
    final conduit = Paint()
      ..color = const Color(0xFFF7F4EC)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    final sw = geo.switchRect;
    c.drawPath(
      Path()
        ..moveTo(sw.center.dx, sw.bottom)
        ..lineTo(sw.center.dx, gy - 96)
        ..lineTo(110, gy - 96),
      conduit,
    );
    // The socket board.
    final sock = Rect.fromCenter(center: Offset(119, gy - 96), width: 22, height: 22);
    c.drawRRect(RRect.fromRectAndRadius(sock, const Radius.circular(3)), Paint()..color = const Color(0xFFFAF8F2));
    c.drawRRect(RRect.fromRectAndRadius(sock, const Radius.circular(3)), Paint()
      ..color = const Color(0xFFB8B2A4)
      ..style = PaintingStyle.stroke);
    c.drawRect(Rect.fromCenter(center: sock.center, width: 9, height: 11), Paint()..color = const Color(0xFF2B2B2B));
    // Skirting and the tiled floor.
    c.drawRect(Rect.fromLTWH(0, floorY - 6, w, 6), Paint()..color = const Color(0xFFB59E7C));
    _vertical(c, Rect.fromLTWH(0, floorY, w, s.height - floorY), const [Color(0xFFBFA987), Color(0xFFD8C5A4)]);
    final line = Paint()
      ..color = const Color(0x33503A20)
      ..strokeWidth = 1;
    var y = floorY + 6.0;
    var step = 8.0;
    while (y < s.height) {
      c.drawLine(Offset(0, y), Offset(w, y), line);
      step *= 1.32;
      y += step;
    }
    final vp = Offset(w * 0.5, floorY - 220);
    for (var x = -400.0; x <= w + 400; x += 60) {
      final a = Offset(x, s.height);
      final t = (floorY - vp.dy) / (a.dy - vp.dy);
      c.drawLine(Offset.lerp(vp, a, t)!, a, line);
    }
    // A table fan on the floor at the right (the cord goes to it).
    final fan = Offset(306, gy - 34);
    c.drawRect(Rect.fromLTWH(fan.dx - 3, fan.dy, 6, 28), Paint()..color = const Color(0xFF5A6068));
    c.drawOval(Rect.fromCenter(center: Offset(fan.dx, gy - 3), width: 34, height: 8), Paint()..color = const Color(0xFF41464C));
    c.drawCircle(fan, 22, Paint()..color = const Color(0xFF8FA6B8));
    c.drawCircle(fan, 22, Paint()
      ..color = const Color(0xFF55606A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
    final blade = Paint()..color = const Color(0xFFE9EEF2);
    for (var i = 0; i < 3; i++) {
      final a = i * math.pi * 2 / 3 + 0.4;
      c.drawOval(Rect.fromCenter(center: fan + Offset(math.cos(a), math.sin(a)) * 10, width: 14, height: 8), blade);
    }
    c.drawCircle(fan, 4, Paint()..color = const Color(0xFF41464C));
  }

  // --- the pump room --------------------------------------------------------------
  void _pump(Canvas c, Size s) {
    final w = s.width;
    final gy = geo.gy;
    final floorY = gy - 26;
    c.drawRect(Rect.fromLTWH(0, 0, w, floorY), Paint()..color = const Color(0xFFA9583F));
    final mortar = Paint()
      ..color = const Color(0x66E8D6C2)
      ..strokeWidth = 1.2;
    final shade = Paint()..color = const Color(0x14000000);
    var row = 0;
    for (var y = floorY - 12.0; y > -12; y -= 12, row++) {
      c.drawLine(Offset(0, y), Offset(w, y), mortar);
      final off = row.isEven ? 0.0 : 13.0;
      for (var x = -off; x < w; x += 26) {
        c.drawLine(Offset(x, y), Offset(x, y + 12), mortar);
        if ((x * 7 + y).round() % 3 == 0) c.drawRect(Rect.fromLTWH(x + 1, y + 1, 24, 10), shade);
      }
    }
    // A light from the top: the wall darkens to the floor.
    _vertical(c, Rect.fromLTWH(0, 0, w, floorY), const [Color(0x00000000), Color(0x33000000)]);
    // The barred window high on the right.
    final win = Rect.fromLTWH(244, gy - 336, 74, 52);
    c.drawRect(win.inflate(4), Paint()..color = const Color(0xFF6E6A62));
    _vertical(c, win, const [Color(0xFFFFF4D8), Color(0xFFE9D9A8)]);
    final bar = Paint()
      ..color = const Color(0xFF3B3F44)
      ..strokeWidth = 2.2;
    for (var x = win.left + 12; x < win.right; x += 12) {
      c.drawLine(Offset(x, win.top), Offset(x, win.bottom), bar);
    }
    // The delivery pipe up the wall, the junction box.
    final pipe = Rect.fromLTWH(322, 0, 12, gy - 40);
    c.drawRect(pipe, Paint()..shader = const LinearGradient(colors: [Color(0xFF6D7378), Color(0xFFB9BFC4), Color(0xFF6D7378)]).createShader(pipe));
    final jb = Rect.fromCenter(center: Offset(300, gy - 206), width: 18, height: 18);
    c.drawRect(jb, Paint()..color = const Color(0xFF8C9399));
    c.drawLine(Offset(300, gy - 197), Offset(300, gy - 60), Paint()
      ..color = const Color(0xFF2A2D31)
      ..strokeWidth = 2.4);
    // Concrete floor with stains.
    _vertical(c, Rect.fromLTWH(0, floorY, w, s.height - floorY), const [Color(0xFF7E7C76), Color(0xFFA19E96)]);
    c.drawRect(Rect.fromLTWH(0, floorY, w, 5), Paint()..color = const Color(0x33000000));
    for (final (x, y, r) in [(70.0, 40.0, 26.0), (250.0, 90.0, 34.0), (150.0, 140.0, 20.0)]) {
      c.drawOval(Rect.fromCenter(center: Offset(x, floorY + y), width: r * 2.4, height: r * 0.7), Paint()..color = const Color(0x1A1E1A10));
    }
    // The pump set: a green motor and a blue pump on a plinth.
    final plinth = Rect.fromLTWH(254, gy - 22, 92, 18);
    c.drawRect(plinth, Paint()..color = const Color(0xFF8E8B84));
    final motor = Rect.fromLTWH(262, gy - 64, 48, 42);
    c.drawRRect(RRect.fromRectAndRadius(motor, const Radius.circular(8)),
        Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF5FA36F), Color(0xFF2F6B3E)]).createShader(motor));
    final fin = Paint()
      ..color = const Color(0x55163A1F)
      ..strokeWidth = 1.4;
    for (var y = motor.top + 6; y < motor.bottom - 4; y += 5) {
      c.drawLine(Offset(motor.left + 4, y), Offset(motor.right - 4, y), fin);
    }
    final pump = Rect.fromLTWH(310, gy - 52, 30, 30);
    c.drawOval(pump, Paint()..shader = const RadialGradient(colors: [Color(0xFF6FA3E0), Color(0xFF2C5C9C)]).createShader(pump));
    c.drawRect(Rect.fromLTWH(318, gy - 70, 14, 22), Paint()..color = const Color(0xFF6D7378));
  }

  // --- the field --------------------------------------------------------------
  void _field(Canvas c, Size s) {
    final w = s.width;
    final gy = geo.gy;
    final hz = gy - 64;
    _sky(c, s, hz);
    _treeLine(c, w, hz, const Color(0xFF557A4A));
    // Huts in the tree line.
    for (final x in [214.0, 300.0]) {
      c.drawRect(Rect.fromLTWH(x, hz - 14, 22, 14), Paint()..color = const Color(0xFFB59A72));
      c.drawPath(
          Path()
            ..moveTo(x - 4, hz - 13)
            ..lineTo(x + 11, hz - 24)
            ..lineTo(x + 26, hz - 13)
            ..close(),
          Paint()..color = const Color(0xFF7C6A55));
    }
    // Paddy rows to the bund.
    final bund = gy - 24;
    _vertical(c, Rect.fromLTWH(0, hz, w, bund - hz), const [Color(0xFF8DBB57), Color(0xFF5E9A3A)]);
    final rowP = Paint()
      ..color = const Color(0x553C6E22)
      ..strokeWidth = 1.2;
    var y = hz + 4.0;
    var step = 3.0;
    while (y < bund) {
      c.drawLine(Offset(0, y), Offset(w, y), rowP);
      step *= 1.25;
      y += step;
    }
    // The poles: the line crosses the field; one conductor has snapped.
    _pole(c, 334, hz - 150, hz + 6, 0.6);
    // The near pole at the left edge, clear of the trainee.
    _pole(c, 8, gy - 312, gy - 34, 1);
    // Two still strung (left and middle insulators); the right one has snapped.
    for (final dx in [-26.0, 0.0]) {
      _wire(c, Offset(8 + dx, gy - 304), Offset(334 + dx * 0.6, hz - 146), 26);
    }
    // The dirt bund in front where they stand.
    _vertical(c, Rect.fromLTWH(0, bund, w, s.height - bund), const [Color(0xFF9A7A52), Color(0xFFB8956A)]);
    c.drawRect(Rect.fromLTWH(0, bund, w, 4), Paint()..color = const Color(0x33000000));
    _tufts(c, w, bund + 8, s.height, const Color(0xFF6F8F3E));
  }

  // --- the roadside -----------------------------------------------------------
  void _roadside(Canvas c, Size s) {
    final w = s.width;
    final gy = geo.gy;
    final hz = gy - 76;
    _sky(c, s, hz);
    // Far shops (no signs to read).
    final rng = math.Random(3);
    for (var x = -10.0; x < w; x += 46) {
      final h = 34 + rng.nextDouble() * 40;
      final col = [const Color(0xFFB9A58C), const Color(0xFFA7B4BC), const Color(0xFFC9B9A0), const Color(0xFF9FB09A)][rng.nextInt(4)];
      final r = Rect.fromLTWH(x, hz - h, 42, h);
      c.drawRect(r, Paint()..color = col);
      for (var wy = r.top + 6; wy < r.bottom - 10; wy += 12) {
        c.drawRect(Rect.fromLTWH(r.left + 6, wy, 9, 6), Paint()..color = const Color(0x664A5560));
        c.drawRect(Rect.fromLTWH(r.left + 24, wy, 9, 6), Paint()..color = const Color(0x664A5560));
      }
    }
    // The road behind them.
    final road = Rect.fromLTWH(0, hz, w, 40);
    c.drawRect(road, Paint()..color = const Color(0xFF5C5F63));
    final dash = Paint()
      ..color = const Color(0xCCF2F2F2)
      ..strokeWidth = 2.4;
    for (var x = 8.0; x < w; x += 40) {
      c.drawLine(Offset(x, hz + 20), Offset(x + 20, hz + 20), dash);
    }
    // A tin-roof house with its service connection.
    final house = Rect.fromLTWH(248, gy - 196, 104, 150);
    c.drawRect(house, Paint()..color = const Color(0xFFD8C7A4));
    c.drawPath(
        Path()
          ..moveTo(house.left - 10, house.top + 4)
          ..lineTo(house.center.dx, house.top - 28)
          ..lineTo(house.right + 10, house.top + 4)
          ..close(),
        Paint()..color = const Color(0xFF7D8890));
    c.drawRect(Rect.fromLTWH(house.left + 16, house.top + 40, 28, 26), Paint()..color = const Color(0xFF4F6F86));
    c.drawRect(Rect.fromLTWH(house.left + 60, house.top + 62, 30, 88), Paint()..color = const Color(0xFF7A5232));
    // The pole and the service wires: one has snapped.
    // The near pole at the left edge, clear of the trainee.
    _pole(c, 8, gy - 318, gy - 30, 1);
    _wire(c, Offset(34, gy - 304), Offset(house.left + 4, house.top + 8), 18);
    // The shoulder where they stand.
    final shoulder = hz + 40;
    _vertical(c, Rect.fromLTWH(0, shoulder, w, s.height - shoulder), const [Color(0xFFA3865E), Color(0xFFBFA078)]);
    c.drawRect(Rect.fromLTWH(0, shoulder, w, 3), Paint()..color = const Color(0x44000000));
    _tufts(c, w, shoulder + 10, s.height, const Color(0xFF7C8F45));
  }

  @override
  bool shouldRepaint(ShockPlacePainter old) => old.scene != scene || old.geo != geo;
}

// ============================================================================
// The colleague and the wire
// ============================================================================

/// How the colleague is now.
enum VictimState {
  /// Stuck to the live wire (spark at the grip).
  stuck,

  /// The power is off: he let go and sank down where he stood.
  slumped,

  /// Pushed clear: he sits slumped, away from the wire.
  pushed,
}

class ShockVictimPainter extends CustomPainter {
  ShockVictimPainter({required this.scene, required this.geo, required this.state, required this.t}) : super(repaint: t);
  final ShockScene scene;
  final ShockGeo geo;
  final VictimState state;

  /// Seconds while awake (the spark and the tremor move), else still.
  final ValueListenable<double> t;

  /// Pushed clear: how far to the right of the wire he sits.
  static const pushedShift = 44.0;

  static const _shirt = Color(0xFF4F86C6);
  static const _pants = Color(0xFF2E3A4C);
  static const _skin = Color(0xFFB07650);

  @override
  void paint(Canvas c, Size s) {
    final tt = t.value;
    final stuck = state == VictimState.stuck;
    _paintWire(c, stuck);
    if (stuck) {
      final j = math.sin(tt * 57) * 0.9;
      c.save();
      c.translate(ShockGeo.vx + j, geo.gy);
      _stuckFigure(c);
      c.restore();
      _tremor(c, tt);
      _spark(c, geo.grip, tt);
    } else {
      c.save();
      c.translate(ShockGeo.vx + (state == VictimState.pushed ? pushedShift : 0), geo.gy);
      _sitting(c);
      c.restore();
    }
  }

  void _paintWire(Canvas c, bool stuck) {
    final g = geo;
    final src = g.source(scene);
    final grip = g.grip;
    final cord = Paint()
      ..color = scene == ShockScene.house ? const Color(0xFFEDEDED) : const Color(0xFF1E2228)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = scene == ShockScene.house ? 3 : 2.6;
    final edge = Paint()
      ..color = const Color(0xFF6F6A60)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round;
    final p = Path()..moveTo(src.dx, src.dy);
    switch (scene) {
      case ShockScene.house:
        // From the socket, a damaged cord up into his hand; on to the fan.
        if (stuck) {
          p
            ..quadraticBezierTo(126, g.gy - 52, grip.dx, grip.dy)
            ..quadraticBezierTo(grip.dx + 70, g.gy + 12, 292, g.gy - 22);
        } else {
          p.cubicTo(150, g.gy + 6, 240, g.gy + 8, 292, g.gy - 22);
        }
      case ShockScene.pump:
        final jb = Offset(291, g.gy - 206);
        if (stuck) {
          p
            ..quadraticBezierTo(112, g.gy - 132, grip.dx, grip.dy)
            ..quadraticBezierTo(232, g.gy - 120, jb.dx, jb.dy);
        } else {
          p.quadraticBezierTo(190, g.gy - 70, jb.dx, jb.dy);
        }
      case ShockScene.field:
      case ShockScene.roadside:
        // The snapped conductor hangs down; its end lies on the ground.
        if (stuck) {
          p
            ..quadraticBezierTo(src.dx + 20, grip.dy - 60, grip.dx, grip.dy)
            ..quadraticBezierTo(grip.dx + 10, g.gy - 40, grip.dx + 22, g.gy + 6);
        } else {
          // Freed: it swings back and hangs down by its pole at the left edge,
          // its end on the ground there — behind the trainee (who has stepped
          // up to push) and well away from the colleague pushed to the right.
          p
            ..quadraticBezierTo(src.dx - 6, g.gy - 150, 20, g.gy - 20)
            ..lineTo(6, g.gy - 15);
        }
    }
    if (scene == ShockScene.house) c.drawPath(p, edge);
    c.drawPath(p, cord);
    if (stuck) {
      // The bare copper where the insulation is gone (in his hand).
      c.drawLine(grip.translate(-5, -2), grip.translate(5, 2), Paint()
        ..color = const Color(0xFFD9893A)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round);
    }
  }

  Paint _limb(Color col, double w) => Paint()
    ..color = col
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke;

  void _poly(Canvas c, List<Offset> pts, Paint p) {
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final q in pts.skip(1)) {
      path.lineTo(q.dx, q.dy);
    }
    c.drawPath(path, p);
  }

  void _head(Canvas c, Offset h, {required bool eyesShut, double tilt = 0}) {
    c.save();
    c.translate(h.dx, h.dy);
    c.rotate(tilt);
    c.drawRect(const Rect.fromLTWH(-4, 10, 8, 6), Paint()..color = _skin);
    c.drawCircle(Offset.zero, 13, Paint()..color = _skin);
    // Hair line and ear.
    c.drawCircle(const Offset(5, 1), 3, Paint()..color = const Color(0xFF8E5C3C));
    // Helmet (white), brim to the front (left).
    final dome = Rect.fromCircle(center: const Offset(0, -2), radius: 14.5);
    c.drawArc(dome, math.pi, math.pi, true, Paint()..shader = const LinearGradient(colors: [Color(0xFFFFFFFF), Color(0xFFCFCFC8)]).createShader(dome));
    c.drawLine(const Offset(-20, -2), const Offset(14, -2), _limb(const Color(0xFFDAD9D2), 3.2));
    final eye = Paint()
      ..color = const Color(0xFF231A14)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    if (eyesShut) {
      c.drawLine(const Offset(-9, 3), const Offset(-4, 3.6), eye);
    } else {
      // Strained: eyes squeezed, mouth tight.
      c.drawLine(const Offset(-10, 1.5), const Offset(-4, 3.5), eye);
      c.drawLine(const Offset(-10, 8.5), const Offset(-4, 8.5), eye);
    }
    c.restore();
  }

  /// Stiff at the wire, facing left: the front arm reaches to the grip.
  void _stuckFigure(Canvas c) {
    final pants = _limb(_pants, 12);
    _poly(c, const [Offset(-4, -70), Offset(-7, -36), Offset(-10, -4)], pants);
    _poly(c, const [Offset(6, -70), Offset(9, -36), Offset(12, -4)], pants);
    final boot = Paint()..color = const Color(0xFF2A211A);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-20, -6, 16, 7), const Radius.circular(3)), boot);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(4, -6, 16, 7), const Radius.circular(3)), boot);
    // Back arm: stiff, fingers spread.
    final sleeve = _limb(const Color(0xFF3F70AA), 9.5);
    _poly(c, const [Offset(12, -114), Offset(21, -92), Offset(27, -72)], sleeve);
    c.drawCircle(const Offset(28, -68), 4.4, Paint()..color = _skin);
    final finger = _limb(_skin, 1.6);
    for (final a in [1.2, 1.6, 2.0]) {
      c.drawLine(const Offset(28, -68), const Offset(28, -68) + Offset(math.cos(a), math.sin(a)) * 7, finger);
    }
    // Torso.
    const torso = Rect.fromLTRB(-17, -124, 17, -66);
    c.drawRRect(RRect.fromRectAndRadius(torso, const Radius.circular(10)),
        Paint()..shader = const LinearGradient(colors: [Color(0xFF6A9AD2), _shirt, Color(0xFF3B6CA6)]).createShader(torso));
    c.drawRect(const Rect.fromLTRB(-17, -72, 17, -66), Paint()..color = const Color(0xFF3A2C20));
    // Front arm to the wire.
    _poly(c, const [Offset(-12, -116), Offset(-32, -122), Offset(-48, -126)], _limb(_shirt, 9.5));
    c.drawCircle(const Offset(-52, -126), 4.8, Paint()..color = _skin);
    _head(c, const Offset(-2, -139), eyesShut: false);
  }

  /// Sitting slumped on the floor, facing left, eyes shut.
  void _sitting(Canvas c) {
    final pants = _limb(_pants, 12);
    _poly(c, const [Offset(6, -16), Offset(-16, -28), Offset(-34, -6)], pants);
    _poly(c, const [Offset(10, -12), Offset(-10, -18), Offset(-30, -2)], pants);
    final boot = Paint()..color = const Color(0xFF2A211A);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-46, -9, 16, 7), const Radius.circular(3)), boot);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-42, -4, 16, 7), const Radius.circular(3)), boot);
    c.save();
    c.translate(8, -14);
    c.rotate(0.32);
    const torso = Rect.fromLTRB(-16, -56, 16, 0);
    c.drawRRect(RRect.fromRectAndRadius(torso, const Radius.circular(10)),
        Paint()..shader = const LinearGradient(colors: [Color(0xFF6A9AD2), _shirt, Color(0xFF3B6CA6)]).createShader(torso));
    _poly(c, const [Offset(-10, -48), Offset(-18, -26), Offset(-22, -6)], _limb(_shirt, 9));
    c.drawCircle(const Offset(-22, -3), 4.4, Paint()..color = _skin);
    _head(c, const Offset(-4, -70), eyesShut: true, tilt: -0.25);
    c.restore();
  }

  void _tremor(Canvas c, double tt) {
    final p = Paint()
      ..color = const Color(0xFFFFB020)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final h = geo.head;
    final wob = math.sin(tt * 40) * 1.2;
    for (final (o, a) in [(const Offset(-24, -6), 3.4), (const Offset(22, -12), -0.3), (const Offset(28, 30), 0.1), (const Offset(-34, 56), 3.0)]) {
      final base = h + o + Offset(0, wob);
      final d = Offset(math.cos(a), math.sin(a));
      final n = Offset(-d.dy, d.dx);
      c.drawPath(
        Path()
          ..moveTo(base.dx, base.dy)
          ..lineTo(base.dx + d.dx * 4 + n.dx * 3, base.dy + d.dy * 4 + n.dy * 3)
          ..lineTo(base.dx + d.dx * 8 - n.dx * 3, base.dy + d.dy * 8 - n.dy * 3)
          ..lineTo(base.dx + d.dx * 12, base.dy + d.dy * 12),
        p,
      );
    }
  }

  void _spark(Canvas c, Offset at, double tt) {
    final flick = 0.75 + 0.25 * math.sin(tt * 31).abs();
    c.drawCircle(at, 24 * flick, Paint()..shader = const RadialGradient(colors: [Color(0xCCFFF6B0), Color(0x66FFD21F), Color(0x00FFD21F)]).createShader(Rect.fromCircle(center: at, radius: 24 * flick)));
    final ray = Paint()
      ..color = const Color(0xFFFFE45C)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + tt * 3;
      final len = 12 + 7 * math.sin(tt * 23 + i * 1.7).abs();
      c.drawLine(at + Offset(math.cos(a), math.sin(a)) * 7, at + Offset(math.cos(a), math.sin(a)) * len, ray);
    }
    c.drawCircle(at, 4.5, Paint()..color = const Color(0xFFFFFFFF));
  }

  @override
  bool shouldRepaint(ShockVictimPainter old) => old.scene != scene || old.geo != geo || old.state != state || old.t != t;
}

// ============================================================================
// The switch on the wall
// ============================================================================

/// The main switch (house: a board of MCBs with the main lever; pump room: the
/// pump's steel switch box). [v]: 0 = ON (lever up) … 1 = OFF (down).
class ShockSwitchPainter extends CustomPainter {
  ShockSwitchPainter({required this.v, required this.steel});
  final double v;
  final bool steel;

  void _label(Canvas c, String text, Offset centre, Color col, double size) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: FontWeight.w900, color: col, height: 1)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas c, Size size) {
    final k = size.width / 66;
    c.scale(k);
    const box = Rect.fromLTWH(3, 4, 60, 88);
    c.drawRRect(RRect.fromRectAndRadius(box.shift(const Offset(2, 3)), const Radius.circular(5)), Paint()..color = const Color(0x55000000));
    final on = v < 0.5;
    if (steel) {
      c.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(5)),
          Paint()..shader = const LinearGradient(colors: [Color(0xFF5E6B66), Color(0xFF8C9A94), Color(0xFF55615C)]).createShader(box));
      c.drawRRect(RRect.fromRectAndRadius(box.deflate(5), const Radius.circular(3)), Paint()
        ..color = const Color(0x55000000)
        ..style = PaintingStyle.stroke);
    } else {
      c.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(5)),
          Paint()..shader = const LinearGradient(colors: [Color(0xFFDCDCD6), Color(0xFFF7F7F2), Color(0xFFD2D2CB)]).createShader(box));
      // The small MCBs in a row (all up).
      for (var i = 0; i < 3; i++) {
        final r = Rect.fromLTWH(8 + i * 9.0, 12, 7, 22);
        c.drawRect(r, Paint()..color = const Color(0xFFFFFFFF));
        c.drawRect(r, Paint()
          ..color = const Color(0xFF9A9A92)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8);
        c.drawRect(Rect.fromLTWH(r.left + 1.5, r.top + 3, 4, 6), Paint()..color = const Color(0xFF2B2B2B));
      }
    }
    // The lamp: red while live.
    final lamp = const Offset(52, 14);
    final lc = on ? const Color(0xFFE5483A) : const Color(0xFF5B636B);
    if (on) {
      c.drawCircle(lamp, 8, Paint()..shader = RadialGradient(colors: [lc.withValues(alpha: 0.6), lc.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: lamp, radius: 8)));
    }
    c.drawCircle(lamp, 3.4, Paint()..color = lc);
    // The main lever: a slot with ON at the top and OFF at the bottom.
    const slot = Rect.fromLTWH(36, 34, 14, 48);
    c.drawRRect(RRect.fromRectAndRadius(slot, const Radius.circular(3)), Paint()..color = const Color(0xFF2B2F35));
    final textCol = steel ? const Color(0xFFF2F2F2) : const Color(0xFF2B2F35);
    _label(c, 'ON', const Offset(20, 42), on ? const Color(0xFFD32F2F) : textCol.withValues(alpha: 0.55), 9);
    _label(c, 'OFF', const Offset(20, 76), on ? textCol.withValues(alpha: 0.55) : const Color(0xFF1B8A45), 9);
    final ky = slot.top + 8 + v * (slot.height - 16);
    final knob = Rect.fromCenter(center: Offset(slot.center.dx, ky), width: 20, height: 14);
    c.drawRRect(RRect.fromRectAndRadius(knob.shift(const Offset(1, 2)), const Radius.circular(4)), Paint()..color = const Color(0x66000000));
    c.drawRRect(RRect.fromRectAndRadius(knob, const Radius.circular(4)),
        Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: steel ? const [Color(0xFFE53935), Color(0xFF9E1B17)] : const [Color(0xFF4A4F57), Color(0xFF1E2126)]).createShader(knob));
    c.drawLine(knob.centerLeft.translate(4, 0), knob.centerRight.translate(-4, 0), Paint()
      ..color = const Color(0x66FFFFFF)
      ..strokeWidth = 1.2);
  }

  @override
  bool shouldRepaint(ShockSwitchPainter old) => old.v != v || old.steel != steel;
}

// ============================================================================
// The things lying about
// ============================================================================

/// Draws [o] from [a] (the held end, or its lower end lying down) to [b]
/// (the tip). [lying]: on the floor (a wet stick leaves a puddle).
void paintRescueObject(Canvas c, RescueObject o, Offset a, Offset b, {bool lying = false}) {
  final d = b - a;
  final len = math.max(1.0, d.distance);
  final dir = d / len;
  final n = Offset(-dir.dy, dir.dx);
  Paint stroke(Color col, double w) => Paint()
    ..color = col
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round;
  void shadow(double w) {
    if (!lying) return;
    c.drawLine(a.translate(2, 4), b.translate(2, 4), stroke(const Color(0x33000000), w + 2));
  }

  switch (o) {
    case RescueObject.bamboo:
      shadow(8);
      c.drawLine(a, b, stroke(const Color(0xFFD9C27E), 8));
      c.drawLine(a + n * 1.8, b + n * 1.8, stroke(const Color(0x66FFF6D0), 2));
      for (var u = 0.14; u < 0.97; u += 0.21) {
        final p = Offset.lerp(a, b, u)!;
        c.drawLine(p - n * 4.5, p + n * 4.5, stroke(const Color(0xFF8E7838), 2.2));
      }
    case RescueObject.hotStick:
      shadow(7);
      c.drawLine(a, b, stroke(const Color(0xFFF2B22C), 7));
      c.drawLine(a + n * 1.6, b + n * 1.6, stroke(const Color(0x88FFF1C0), 1.6));
      // Grip band at the held end, the metal head fitting at the tip.
      c.drawLine(a, a + dir * len * 0.22, stroke(const Color(0xFF2E2E2E), 8));
      c.drawLine(b - dir * 7, b, stroke(const Color(0xFF9AA3AA), 7));
    case RescueObject.plank:
      shadow(12);
      c.drawLine(a, b, stroke(const Color(0xFFC79A60), 12)..strokeCap = StrokeCap.square);
      c.drawLine(a + n * 2.5, b + n * 2.5, stroke(const Color(0xFF9C6F3A), 1));
      c.drawLine(a - n * 2.8 + dir * 6, b - n * 2.2 - dir * 10, stroke(const Color(0xFF9C6F3A), 1));
    case RescueObject.wetStick:
      shadow(8);
      c.drawLine(a, b, stroke(const Color(0xFF4A3622), 8));
      c.drawLine(a + n * 2, b + n * 2, stroke(const Color(0x9988C4F0), 1.8));
      final drop = Paint()..color = const Color(0xFF5AA8E6);
      for (final u in const [0.2, 0.42, 0.63, 0.84]) {
        final p = Offset.lerp(a, b, u)!;
        c.drawPath(
          Path()
            ..moveTo(p.dx, p.dy + 5)
            ..quadraticBezierTo(p.dx - 3, p.dy + 10, p.dx, p.dy + 11)
            ..quadraticBezierTo(p.dx + 3, p.dy + 10, p.dx, p.dy + 5),
          drop,
        );
      }
      if (lying) {
        final m = Offset.lerp(a, b, 0.5)!;
        c.drawOval(Rect.fromCenter(center: m.translate(0, 10), width: len * 0.9, height: 9), Paint()..color = const Color(0x665AA8E6));
      }
    case RescueObject.ironRod:
      shadow(6);
      c.drawLine(a, b, stroke(const Color(0xFF5E666D), 6));
      c.drawLine(a + n * 1.4, b + n * 1.4, stroke(const Color(0xFFC6CDD3), 1.4));
      for (var u = 0.08; u < 0.95; u += 0.09) {
        final p = Offset.lerp(a, b, u)!;
        c.drawLine(p - n * 3 - dir * 1.5, p + n * 3 + dir * 1.5, stroke(const Color(0xFF454C52), 1));
      }
    case RescueObject.ladder:
      shadow(14);
      final rail = stroke(const Color(0xFFB9C1C8), 2.8);
      c.drawLine(a + n * 6, b + n * 6, rail);
      c.drawLine(a - n * 6, b - n * 6, rail);
      c.drawLine(a + n * 7, b + n * 7, stroke(const Color(0x88FFFFFF), 0.8));
      for (var u = 0.08; u < 0.97; u += 0.14) {
        final p = Offset.lerp(a, b, u)!;
        c.drawLine(p - n * 6, p + n * 6, stroke(const Color(0xFF98A1A9), 2.2));
      }
    case RescueObject.chair:
      // A plastic chair: upright, its front legs towards the tip.
      final h = math.min(46.0, len * 0.9);
      final base = Offset(b.dx - h * 0.45, math.max(a.dy, b.dy) + (lying ? 0 : h * 0.3));
      final col = const Color(0xFF2F6FD0);
      final dark = const Color(0xFF1F4F9C);
      final seat = Rect.fromCenter(center: base.translate(0, -h * 0.42), width: h * 0.72, height: h * 0.12);
      if (lying) c.drawOval(Rect.fromCenter(center: base.translate(0, 2), width: h * 0.9, height: 6), Paint()..color = const Color(0x33000000));
      final leg = stroke(dark, h * 0.08);
      c.drawLine(seat.bottomLeft.translate(3, 0), base.translate(-h * 0.34, 0), leg);
      c.drawLine(seat.bottomRight.translate(-3, 0), base.translate(h * 0.34, 0), leg);
      final back = RRect.fromRectAndRadius(Rect.fromLTRB(seat.left, seat.top - h * 0.5, seat.left + h * 0.16, seat.top + 2), Radius.circular(h * 0.06));
      c.drawRRect(back, Paint()..color = col);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(seat.left, seat.top - h * 0.52, seat.left + h * 0.5, seat.top - h * 0.36), Radius.circular(h * 0.06)), Paint()..color = col);
      c.drawRRect(RRect.fromRectAndRadius(seat, Radius.circular(h * 0.05)), Paint()..color = col);
      c.drawLine(seat.topLeft.translate(4, 2), seat.topRight.translate(-4, 2), stroke(const Color(0x66FFFFFF), 1.2));
  }
}

/// Where [o] lies in [slot]: its two ends (a chair stands upright).
(Offset, Offset) restingEnds(RescueObject o, Rect slot) => o == RescueObject.chair
    ? (slot.bottomLeft.translate(6, -10), slot.bottomRight.translate(-2, -10))
    : (slot.bottomLeft.translate(5, -16), slot.topRight.translate(-4, 14));

/// The things on the floor; [hidden] are in the hands or used.
class ShockFloorPainter extends CustomPainter {
  const ShockFloorPainter({required this.objects, required this.geo, required this.hidden});
  final List<RescueObject> objects;
  final ShockGeo geo;
  final Set<int> hidden;

  @override
  void paint(Canvas c, Size s) {
    for (var i = 0; i < objects.length; i++) {
      if (hidden.contains(i)) continue;
      final (a, b) = restingEnds(objects[i], geo.slot(i));
      paintRescueObject(c, objects[i], a, b, lying: true);
    }
  }

  @override
  bool shouldRepaint(ShockFloorPainter old) => old.objects != objects || old.geo != geo || !setEquals(old.hidden, hidden);

  static bool setEquals(Set<int> a, Set<int> b) => a.length == b.length && a.containsAll(b);
}

/// One thing between two points (in the hands: under the finger, or pushing).
class RescueObjectPainter extends CustomPainter {
  const RescueObjectPainter({required this.object, required this.a, required this.b});
  final RescueObject object;
  final Offset a;
  final Offset b;

  @override
  void paint(Canvas c, Size s) => paintRescueObject(c, object, a, b);

  @override
  bool shouldRepaint(RescueObjectPainter old) => old.object != object || old.a != a || old.b != b;
}

// ============================================================================
// The deadly freeze: the current's path through the helper, in colour
// ============================================================================

class ShockZapPainter extends CustomPainter {
  const ShockZapPainter({required this.t, required this.path, required this.halos});

  /// 0 → 1: the current runs along [path].
  final double t;
  final List<Offset> path;

  /// The bodies it goes through (a red glow on each).
  final List<Offset> halos;

  @override
  void paint(Canvas c, Size s) {
    if (path.length < 2) return;
    for (final h in halos) {
      final r = 34 + 6 * math.sin(t * math.pi * 6);
      c.drawCircle(h, r, Paint()..shader = const RadialGradient(colors: [Color(0x99FF3B2F), Color(0x00FF3B2F)]).createShader(Rect.fromCircle(center: h, radius: r)));
    }
    var total = 0.0;
    for (var i = 1; i < path.length; i++) {
      total += (path[i] - path[i - 1]).distance;
    }
    final upto = total * t.clamp(0.0, 1.0);
    final p = Path()..moveTo(path.first.dx, path.first.dy);
    var run = 0.0;
    var end = path.first;
    for (var i = 1; i < path.length; i++) {
      final a = path[i - 1];
      final b = path[i];
      final seg = (b - a).distance;
      if (run + seg <= upto) {
        _bolt(p, a, b, i);
        run += seg;
        end = b;
      } else {
        final f = ((upto - run) / math.max(seg, 0.001)).clamp(0.0, 1.0);
        end = Offset.lerp(a, b, f)!;
        _bolt(p, a, end, i);
        break;
      }
    }
    c.drawPath(p, Paint()
      ..color = const Color(0xAAFFC93C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    c.drawPath(p, Paint()
      ..color = const Color(0xFFFFF4B8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);
    c.drawCircle(end, 6, Paint()..color = const Color(0xFFFFFFFF));
    if (t >= 0.98) {
      // Into the ground under the helper's feet.
      final g = path.last;
      final arc = Paint()
        ..color = const Color(0xCCFFC93C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      for (final r in [10.0, 18.0, 26.0]) {
        c.drawArc(Rect.fromCenter(center: g, width: r * 2, height: r * 0.7), 0, math.pi, false, arc);
      }
    }
  }

  void _bolt(Path p, Offset a, Offset b, int seed) {
    final d = b - a;
    final len = d.distance;
    if (len < 1) return;
    final n = Offset(-d.dy, d.dx) / len;
    final steps = math.max(1, (len / 14).round());
    for (var k = 1; k <= steps; k++) {
      final q = Offset.lerp(a, b, k / steps)!;
      final off = k == steps ? 0.0 : math.sin(seed * 12.9 + k * 78.2) * 5;
      p.lineTo(q.dx + n.dx * off, q.dy + n.dy * off);
    }
  }

  @override
  bool shouldRepaint(ShockZapPainter old) => old.t != t || old.path != path;
}
