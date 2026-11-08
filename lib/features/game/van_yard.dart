import 'package:flutter/material.dart';

// Beside the work van at 7:20 in the morning (lesson 1.1's glove check): a
// drawn scene — morning sky, the substation wall and gate, the utility van
// side-on with its ladder rack and the side door open on kit shelves, cones
// on the road. No text in the art. Design: 360 wide × any height.
class VanYardPainter extends CustomPainter {
  const VanYardPainter();

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final h = s.height;
    final ground = h * 0.66;

    // Morning sky.
    c.drawRect(
      Rect.fromLTWH(0, 0, w, ground),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7FB2DA), Color(0xFFCFE2EE), Color(0xFFF6E3C2)],
          stops: [0, 0.6, 1],
        ).createShader(Rect.fromLTWH(0, 0, w, ground)),
    );
    // Low sun glow.
    c.drawCircle(
      Offset(w * 0.18, ground - 120),
      110,
      Paint()..shader = const RadialGradient(colors: [Color(0x66FFF1C8), Color(0x00FFF1C8)]).createShader(Rect.fromCircle(center: Offset(w * 0.18, ground - 120), radius: 110)),
    );
    // Distant poles and line.
    final pole = Paint()..color = const Color(0xFF9A9890);
    for (final x in const [40.0, 210.0, 380.0]) {
      c.drawRect(Rect.fromLTWH(x, ground - 200, 5, 200), pole);
      c.drawRect(Rect.fromLTWH(x - 18, ground - 192, 41, 3), Paint()..color = const Color(0xFF6F767D));
    }
    c.drawPath(
      Path()
        ..moveTo(0, ground - 186)
        ..quadraticBezierTo(125, ground - 172, 212, ground - 188)
        ..quadraticBezierTo(300, ground - 172, w, ground - 186),
      Paint()
        ..color = const Color(0xFF3D434A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // The substation wall and gate.
    final wallTop = ground - 74;
    c.drawRect(Rect.fromLTWH(0, wallTop, w, 74), Paint()..color = const Color(0xFFCFC6B4));
    c.drawRect(Rect.fromLTWH(0, wallTop, w, 6), Paint()..color = const Color(0xFFB7AD98));
    for (var x = 0.0; x < w; x += 46) {
      c.drawRect(Rect.fromLTWH(x, wallTop + 6, 2, 68), Paint()..color = const Color(0x22000000));
    }
    final gate = Rect.fromLTWH(w * 0.04, wallTop - 10, 74, 84);
    c.drawRect(gate, Paint()..color = const Color(0xFF5F676F));
    final bar = Paint()
      ..color = const Color(0xFF3B4148)
      ..strokeWidth = 3;
    for (var x = gate.left + 8; x < gate.right; x += 11) {
      c.drawLine(Offset(x, gate.top + 4), Offset(x, gate.bottom), bar);
    }

    // The road.
    final road = Rect.fromLTWH(0, ground, w, h - ground);
    c.drawRect(
      road,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8D8A84), Color(0xFF6E6B66)],
        ).createShader(road),
    );
    c.drawRect(Rect.fromLTWH(0, ground, w, 5), Paint()..color = const Color(0xFFB5AFA3));

    // The van, side-on, parked along the wall (right half).
    final body = Rect.fromLTWH(w * 0.38, ground - 128, w * 0.66, 112);
    final van = RRect.fromRectAndCorners(body, topLeft: const Radius.circular(18), topRight: const Radius.circular(10), bottomLeft: const Radius.circular(6), bottomRight: const Radius.circular(6));
    c.drawRRect(van.shift(const Offset(0, 6)), Paint()..color = const Color(0x33000000));
    c.drawRRect(
      van,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF4F6F7), Color(0xFFD6DBDF)],
        ).createShader(body),
    );
    // Blue stripe and the cab window.
    c.drawRect(Rect.fromLTWH(body.left, body.top + 62, body.width, 12), Paint()..color = const Color(0xFF2F6FD0));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(body.left + 10, body.top + 14, 50, 36), const Radius.circular(8)), Paint()..color = const Color(0xFF7FA7C2));
    // The open side door: shelves with kit inside.
    final door = Rect.fromLTWH(body.left + 76, body.top + 12, 92, 92);
    c.drawRect(door, Paint()..color = const Color(0xFF2B3138));
    for (var i = 1; i < 3; i++) {
      c.drawRect(Rect.fromLTWH(door.left + 4, door.top + i * 30.0, door.width - 8, 3), Paint()..color = const Color(0xFF8D969D));
    }
    for (final (dx, dy, col) in const [(10.0, 14.0, Color(0xFFFF851B)), (34.0, 16.0, Color(0xFFFFD34E)), (58.0, 12.0, Color(0xFFD23A2C)), (14.0, 46.0, Color(0xFF1F5F8F)), (44.0, 44.0, Color(0xFF6B4A33)), (66.0, 72.0, Color(0xFFB98B54))]) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(door.left + dx, door.top + dy, 18, 14), const Radius.circular(3)), Paint()..color = col);
    }
    // Ladder on the roof rack.
    final rackY = body.top - 8;
    c.drawRect(Rect.fromLTWH(body.left + 30, rackY, body.width - 40, 3), Paint()..color = const Color(0xFF8D969D));
    c.drawRect(Rect.fromLTWH(body.left + 30, rackY - 9, body.width - 40, 3), Paint()..color = const Color(0xFFB0B7BD));
    for (var x = body.left + 36; x < body.right - 14; x += 14) {
      c.drawLine(Offset(x, rackY - 9), Offset(x, rackY), Paint()
        ..color = const Color(0xFFB0B7BD)
        ..strokeWidth = 2);
    }
    // Wheels.
    for (final x in [body.left + 40, body.right - 50]) {
      c.drawCircle(Offset(x, ground - 14), 18, Paint()..color = const Color(0xFF1E2126));
      c.drawCircle(Offset(x, ground - 14), 8, Paint()..color = const Color(0xFF8D969D));
    }

    // Two cones on the road.
    for (final x in const [36.0, 92.0]) {
      final cone = Path()
        ..moveTo(x, ground + 18)
        ..lineTo(x + 10, ground + 44)
        ..lineTo(x - 10, ground + 44)
        ..close();
      c.drawPath(cone, Paint()..color = const Color(0xFFFF851B));
      c.drawRect(Rect.fromLTWH(x - 6, ground + 28, 12, 4), Paint()..color = const Color(0xFFF5F7FA));
      c.drawRect(Rect.fromLTWH(x - 13, ground + 44, 26, 4), Paint()..color = const Color(0xFF3B3F45));
    }
  }

  @override
  bool shouldRepaint(VanYardPainter old) => false;
}
