import 'dart:math' as math;

import 'package:flutter/material.dart';

// The substation store room at 7 in the morning (lesson 1.1's Do levels):
// a drawn scene, full screen behind the play — back wall with the window's
// morning light, steel shelves with boxes and folded kit, a clothes rail,
// grey lockers, a hanging lamp, a tiled floor. No text in the art.
// Design: 360 wide × any height (the floor line follows the height).
class StoreRoomPainter extends CustomPainter {
  const StoreRoomPainter();

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final h = s.height;
    final floorY = h * 0.70;

    // Back wall: warm cream to a soft teal at the top.
    c.drawRect(
      Rect.fromLTWH(0, 0, w, floorY),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6E8F8E), Color(0xFFB9C7BC), Color(0xFFE2D8C3)],
          stops: [0, 0.45, 1],
        ).createShader(Rect.fromLTWH(0, 0, w, floorY)),
    );
    // A dado line and skirting.
    c.drawRect(Rect.fromLTWH(0, floorY - 70, w, 3), Paint()..color = const Color(0x55524A3C));
    c.drawRect(Rect.fromLTWH(0, floorY - 8, w, 8), Paint()..color = const Color(0xFF6D6253));

    // Window with morning light (top right).
    const win = Rect.fromLTWH(232, 92, 96, 74);
    c.drawRRect(RRect.fromRectAndRadius(win.inflate(5), const Radius.circular(4)), Paint()..color = const Color(0xFF5F676F));
    c.drawRect(
      win,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF4D6), Color(0xFFB7DDF2)],
        ).createShader(win),
    );
    final bar = Paint()
      ..color = const Color(0xFF5F676F)
      ..strokeWidth = 3;
    c.drawLine(Offset(win.center.dx, win.top), Offset(win.center.dx, win.bottom), bar);
    c.drawLine(Offset(win.left, win.center.dy), Offset(win.right, win.center.dy), bar);
    // The light falling across the floor.
    final beam = Path()
      ..moveTo(win.left, win.bottom)
      ..lineTo(win.right, win.bottom)
      ..lineTo(w * 0.62, h)
      ..lineTo(w * 0.08, h)
      ..close();
    c.drawPath(
      beam,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFFFFF1C4).withValues(alpha: 0.30), const Color(0xFFFFF1C4).withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(0, win.bottom, w, h - win.bottom)),
    );

    // Steel shelves (left) with boxes and folded kit.
    final shelf = Paint()..color = const Color(0xFF8D969D);
    for (final x in const [14.0, 104.0]) {
      c.drawRect(Rect.fromLTWH(x, 96, 4, floorY - 96), shelf);
    }
    for (final y in [126.0, 186.0, 246.0]) {
      c.drawRect(Rect.fromLTWH(10, y, 100, 5), shelf);
    }
    final rnd = math.Random(4);
    const boxCols = [Color(0xFFB98B54), Color(0xFFA9783F), Color(0xFFC79A60)];
    for (final y in [126.0, 186.0, 246.0]) {
      var x = 18.0;
      while (x < 98) {
        final bw = 18 + rnd.nextDouble() * 14;
        final bh = 16 + rnd.nextDouble() * 18;
        if (x + bw > 104) break;
        final col = rnd.nextInt(5) == 0 ? const Color(0xFF2F4F6E) : boxCols[rnd.nextInt(boxCols.length)];
        c.drawRect(Rect.fromLTWH(x, y - bh, bw, bh), Paint()..color = col);
        c.drawRect(Rect.fromLTWH(x, y - bh, bw, 3), Paint()..color = const Color(0x33000000));
        x += bw + 3;
      }
    }

    // Clothes rail (centre back) with hanging coveralls.
    c.drawLine(const Offset(132, 104), const Offset(214, 104), Paint()
      ..color = const Color(0xFF5F676F)
      ..strokeWidth = 3);
    for (final (x, col) in const [(144.0, Color(0xFF1F5F8F)), (166.0, Color(0xFF2B4A6E)), (190.0, Color(0xFFFF851B)), (206.0, Color(0xFF1F5F8F))]) {
      c.drawLine(Offset(x, 104), Offset(x, 112), Paint()
        ..color = const Color(0xFF3B3F45)
        ..strokeWidth = 1.5);
      final coat = Path()
        ..moveTo(x - 9, 114)
        ..lineTo(x + 9, 114)
        ..lineTo(x + 11, 170)
        ..lineTo(x - 11, 170)
        ..close();
      c.drawPath(coat, Paint()..color = col.withValues(alpha: 0.85));
    }

    // Grey lockers (right).
    for (var i = 0; i < 2; i++) {
      final r = Rect.fromLTWH(274.0 + i * 40, 190, 38, floorY - 190 - 8);
      c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), Paint()..color = const Color(0xFF8A949C));
      c.drawRect(r.deflate(3), Paint()..color = const Color(0xFF9AA4AC));
      for (var v = 0; v < 4; v++) {
        c.drawRect(Rect.fromLTWH(r.left + 8, r.top + 10 + v * 6.0, 22, 2), Paint()..color = const Color(0xFF6D777F));
      }
      c.drawRect(Rect.fromLTWH(r.right - 9, r.center.dy, 3, 12), Paint()..color = const Color(0xFF3B3F45));
    }

    // The hanging lamp and its glow.
    // (Left of centre, so it never sits under the header's round dots.)
    final lx = w * 0.36;
    c.drawLine(Offset(lx, 0), Offset(lx, 88), Paint()
      ..color = const Color(0xFF3B3F45)
      ..strokeWidth = 1.5);
    c.drawPath(
      Path()
        ..moveTo(lx - 18, 100)
        ..lineTo(lx + 18, 100)
        ..lineTo(lx + 8, 88)
        ..lineTo(lx - 8, 88)
        ..close(),
      Paint()..color = const Color(0xFF2F3A45),
    );
    c.drawCircle(
      Offset(lx, 108),
      90,
      Paint()..shader = RadialGradient(colors: [const Color(0xFFFFE7A8).withValues(alpha: 0.32), const Color(0xFFFFE7A8).withValues(alpha: 0)]).createShader(Rect.fromCircle(center: Offset(lx, 108), radius: 90)),
    );

    // Tiled floor.
    final floor = Rect.fromLTWH(0, floorY, w, h - floorY);
    c.drawRect(
      floor,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8C8273), Color(0xFF6B6255)],
        ).createShader(floor),
    );
    final grout = Paint()
      ..color = const Color(0x33000000)
      ..strokeWidth = 1;
    for (var y = floorY + 18; y < h; y += 26) {
      c.drawLine(Offset(0, y), Offset(w, y), grout);
    }
    for (var x = -40.0; x < w + 40; x += 44) {
      c.drawLine(Offset(w / 2 + (x - w / 2) * 0.4, floorY), Offset(x, h), grout);
    }
  }

  @override
  bool shouldRepaint(StoreRoomPainter old) => false;
}
