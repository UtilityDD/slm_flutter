import 'dart:math' as math;

import 'package:flutter/material.dart';

// The drawn world of lesson 7.10 কাজ 1 "যোগ্য হাতে কাজ" (m7_crew_papers.dart):
// the morning roll-call in a sub-division store yard. A pale sky, the
// store office with its barred windows and a flat roof, a row of poles with
// a line across, the crew van, a low fence and the packed-earth yard. The
// notice board of job cards, the tray, the wallet of papers and the gang
// tiles are the page's own widgets laid over this yard.
//
// A worker's look (M7Look) is drawn apart from his papers: ten looks (skin,
// shirt, hair, a cap, a helmet or nothing, glasses, a moustache) that the deal
// hands out at random, so a face never tells who holds which certificate.
// The player's own figure carries the foreman's clipboard.
//
// Code-drawn, gradients, no bitmaps, no text. The worker's design box is
// 60 × 96 (scaled to fit, centred).

/// How a worker looks (never tied to his papers).
@immutable
class M7Look {
  const M7Look({required this.skin, required this.shirt, required this.hair, this.hat = M7Hat.none, this.glasses = false, this.moustache = false});

  final Color skin;
  final Color shirt;
  final Color hair;
  final M7Hat hat;
  final bool glasses;
  final bool moustache;
}

enum M7Hat { none, cap, helmet }

/// The ten looks the deal draws from.
const List<M7Look> m7Looks = [
  M7Look(skin: Color(0xFFC98E62), shirt: Color(0xFF3F6FB5), hair: Color(0xFF231A14), hat: M7Hat.helmet),
  M7Look(skin: Color(0xFFA9714A), shirt: Color(0xFF6E7F57), hair: Color(0xFF1B1511), moustache: true),
  M7Look(skin: Color(0xFFE0AC7E), shirt: Color(0xFFB5503F), hair: Color(0xFF3A2A1E), hat: M7Hat.cap),
  M7Look(skin: Color(0xFF8D5A3B), shirt: Color(0xFF3F8F7B), hair: Color(0xFF15100C), glasses: true),
  M7Look(skin: Color(0xFFD29B6C), shirt: Color(0xFFC49A2E), hair: Color(0xFF2A2018), hat: M7Hat.helmet, moustache: true),
  M7Look(skin: Color(0xFFB9825A), shirt: Color(0xFF7A5BA8), hair: Color(0xFF241B15)),
  M7Look(skin: Color(0xFFC08A5E), shirt: Color(0xFF52525B), hair: Color(0xFF2E2A27), hat: M7Hat.cap, glasses: true),
  M7Look(skin: Color(0xFF9C6641), shirt: Color(0xFFD1763A), hair: Color(0xFF17120E), moustache: true, glasses: true),
  M7Look(skin: Color(0xFFD9A47A), shirt: Color(0xFF2F7D4F), hair: Color(0xFF3A2C20)),
  M7Look(skin: Color(0xFFB07750), shirt: Color(0xFF8C3B5C), hair: Color(0xFF1E1712), hat: M7Hat.helmet),
];

/// One worker (or the player, with the foreman's clipboard) as a figure.
class M7WorkerPainter extends CustomPainter {
  const M7WorkerPainter(this.look, {this.clipboard = false});

  final M7Look look;
  final bool clipboard;

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width / 60, size.height / 96);
    canvas.save();
    canvas.translate((size.width - 60 * s) / 2, (size.height - 96 * s) / 2);
    canvas.scale(s);
    final p = Paint();
    // Boots and trousers.
    p.color = const Color(0xFF2B3340);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(16, 60, 12, 30), const Radius.circular(4)), p);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(32, 60, 12, 30), const Radius.circular(4)), p);
    p.color = const Color(0xFF14181F);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(14, 86, 15, 8), const Radius.circular(3)), p);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(31, 86, 15, 8), const Radius.circular(3)), p);
    // Arms and shirt.
    p.color = Color.lerp(look.shirt, Colors.black, 0.18)!;
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(5, 32, 10, 30), const Radius.circular(5)), p);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(45, 32, 10, 30), const Radius.circular(5)), p);
    p.color = look.skin;
    canvas.drawCircle(const Offset(10, 64), 5, p);
    canvas.drawCircle(const Offset(50, 64), 5, p);
    p.shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [look.shirt, Color.lerp(look.shirt, Colors.black, 0.22)!])
        .createShader(const Rect.fromLTWH(12, 30, 36, 38));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(12, 30, 36, 38), const Radius.circular(9)), p);
    p.shader = null;
    // Collar.
    p.color = Color.lerp(look.shirt, Colors.white, 0.35)!;
    final collar = Path()
      ..moveTo(24, 30)
      ..lineTo(30, 40)
      ..lineTo(36, 30)
      ..close();
    canvas.drawPath(collar, p);
    // Neck and head.
    p.color = look.skin;
    canvas.drawRect(const Rect.fromLTWH(26, 24, 8, 8), p);
    canvas.drawOval(const Rect.fromLTWH(17, 4, 26, 28), p);
    // Hair, hat.
    p.color = look.hair;
    canvas.drawArc(const Rect.fromLTWH(16, 3, 28, 22), math.pi * 1.02, math.pi * 0.96, true, p);
    switch (look.hat) {
      case M7Hat.helmet:
        p.color = const Color(0xFFF2C230);
        canvas.drawArc(const Rect.fromLTWH(14, 0, 32, 26), math.pi, math.pi, true, p);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(12, 12, 36, 4), const Radius.circular(2)), p);
      case M7Hat.cap:
        p.color = const Color(0xFF334155);
        canvas.drawArc(const Rect.fromLTWH(15, 1, 30, 24), math.pi, math.pi, true, p);
        canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(30, 11, 20, 4), const Radius.circular(2)), p);
      case M7Hat.none:
        break;
    }
    // Face.
    p.color = const Color(0xFF1B1511);
    canvas.drawCircle(const Offset(25, 20), 1.6, p);
    canvas.drawCircle(const Offset(35, 20), 1.6, p);
    if (look.glasses) {
      final g = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0xFF111827);
      canvas.drawCircle(const Offset(25, 20), 4.2, g);
      canvas.drawCircle(const Offset(35, 20), 4.2, g);
      canvas.drawLine(const Offset(29.2, 20), const Offset(30.8, 20), g);
    }
    if (look.moustache) {
      p.color = look.hair;
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(24, 25, 12, 3), const Radius.circular(1.5)), p);
    } else {
      final m = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF7A3E2A);
      canvas.drawArc(const Rect.fromLTWH(26, 22, 8, 6), 0.2, math.pi - 0.4, false, m);
    }
    if (clipboard) {
      p.color = const Color(0xFFA16207);
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(34, 44, 22, 28), const Radius.circular(3)), p);
      p.color = const Color(0xFFFFFDF6);
      canvas.drawRect(const Rect.fromLTWH(37, 49, 16, 20), p);
      p.color = const Color(0xFFC8BF9F);
      canvas.drawRect(const Rect.fromLTWH(39, 53, 12, 2), p);
      canvas.drawRect(const Rect.fromLTWH(39, 58, 9, 2), p);
      p.color = const Color(0xFFD1D5DB);
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(40, 43, 10, 5), const Radius.circular(2)), p);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(M7WorkerPainter old) => old.look != look || old.clipboard != clipboard;
}

/// The store yard behind the page's widgets (static: draws once).
class M7YardPainter extends CustomPainter {
  const M7YardPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final groundY = h * 0.60;
    // Sky.
    final sky = Rect.fromLTWH(0, 0, w, groundY);
    canvas.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8CC8EE), Color(0xFFDCEFF7)]).createShader(sky),
    );
    // A few clouds.
    final cloud = Paint()..color = const Color(0xCCFFFFFF);
    for (final c in [Offset(w * 0.18, h * 0.14), Offset(w * 0.62, h * 0.09), Offset(w * 0.86, h * 0.2)]) {
      canvas.drawOval(Rect.fromCenter(center: c, width: 74, height: 20), cloud);
      canvas.drawOval(Rect.fromCenter(center: c + const Offset(16, -8), width: 44, height: 20), cloud);
    }
    // Far tree line.
    final tree = Paint()..color = const Color(0xFF7FA37A);
    for (var x = -10.0; x < w + 30; x += 46) {
      canvas.drawOval(Rect.fromLTWH(x, groundY - 38 - (x.toInt() % 3) * 6, 56, 52), tree);
    }
    // The store office.
    final ox = w * 0.04;
    final ow = w * 0.46;
    final oy = groundY - h * 0.2;
    canvas.drawRect(Rect.fromLTWH(ox, oy, ow, groundY - oy), Paint()..color = const Color(0xFFE9DCC3));
    canvas.drawRect(Rect.fromLTWH(ox - 4, oy - 7, ow + 8, 9), Paint()..color = const Color(0xFF8E7B61));
    canvas.drawRect(Rect.fromLTWH(ox, groundY - 8, ow, 8), Paint()..color = const Color(0xFFBFAF92));
    for (var i = 0; i < 3; i++) {
      final wx = ox + 14 + i * (ow - 28) / 3;
      final win = Rect.fromLTWH(wx, oy + 12, ow / 5.2, h * 0.075);
      canvas.drawRect(win, Paint()..color = const Color(0xFF9BC4DD));
      final bar = Paint()
        ..color = const Color(0xFF55616B)
        ..strokeWidth = 1.5;
      for (var k = 1; k < 4; k++) {
        canvas.drawLine(Offset(win.left + win.width * k / 4, win.top), Offset(win.left + win.width * k / 4, win.bottom), bar);
      }
      canvas.drawRect(win, Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0xFF55616B)
        ..strokeWidth = 2);
    }
    // The door.
    canvas.drawRect(Rect.fromLTWH(ox + ow / 2 - 14, groundY - h * 0.1, 28, h * 0.1), Paint()..color = const Color(0xFF6E4C2B));
    // The crew van.
    final vx = w * 0.62;
    final vy = groundY - h * 0.07;
    final van = RRect.fromRectAndRadius(Rect.fromLTWH(vx, vy, w * 0.3, h * 0.085), const Radius.circular(8));
    canvas.drawRRect(van, Paint()..color = const Color(0xFFF1F5F9));
    canvas.drawRRect(van, Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 2);
    canvas.drawRect(Rect.fromLTWH(vx + w * 0.2, vy + 5, w * 0.075, h * 0.03), Paint()..color = const Color(0xFF9BC4DD));
    canvas.drawRect(Rect.fromLTWH(vx + 6, vy + h * 0.05, w * 0.28, 5), Paint()..color = const Color(0xFFDC2626));
    for (final cx in [vx + w * 0.06, vx + w * 0.24]) {
      canvas.drawCircle(Offset(cx, vy + h * 0.087), 8, Paint()..color = const Color(0xFF1F2937));
      canvas.drawCircle(Offset(cx, vy + h * 0.087), 3.5, Paint()..color = const Color(0xFFCBD5E1));
    }
    // The ground and a low fence.
    final ground = Rect.fromLTWH(0, groundY, w, h - groundY);
    canvas.drawRect(
      ground,
      Paint()
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFC9B58F), Color(0xFFA48F68)]).createShader(ground),
    );
    final post = Paint()..color = const Color(0xFF6B5B3E);
    for (var x = 6.0; x < w; x += 30) {
      canvas.drawRect(Rect.fromLTWH(x, groundY - 14, 4, 20), post);
    }
    canvas.drawRect(Rect.fromLTWH(0, groundY - 10, w, 3), post);
    canvas.drawRect(Rect.fromLTWH(0, groundY - 2, w, 3), post);
    // Two poles with a line across the yard's top.
    final pole = Paint()..color = const Color(0xFF7A5A36);
    final line = Paint()
      ..color = const Color(0xFF374151)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (final px in [w * 0.03, w * 0.97]) {
      canvas.drawRect(Rect.fromLTWH(px - 3, h * 0.05, 6, groundY - h * 0.05 + 6), pole);
      canvas.drawRect(Rect.fromLTWH(px - 16, h * 0.07, 32, 4), pole);
    }
    final wire = Path()
      ..moveTo(w * 0.03, h * 0.075)
      ..quadraticBezierTo(w * 0.5, h * 0.125, w * 0.97, h * 0.075);
    canvas.drawPath(wire, line);
  }

  @override
  bool shouldRepaint(M7YardPainter old) => false;
}
