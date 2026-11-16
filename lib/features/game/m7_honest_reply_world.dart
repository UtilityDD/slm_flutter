import 'dart:math' as math;

import 'package:flutter/material.dart';

// The drawn world of lesson 7.9 কাজ 2 "সৎ জবাব" (m7_honest_reply.dart): a para
// lane at noon. Far off, roofs and trees; on the right a pole with its
// pole-mounted transformer (an AB switch and the HG fuses on the cross-arm,
// no DO: owner ruling M7-9); on the left a house veranda with a meter board
// (the new meter in, a cloth bag with the old one on the floor) and a
// clipboard on a nail. The customers (silent, with caption bubbles) stand in
// the lane one at a time; the trainee stands left.
//
// No text in the art except a label a worker would read (the meter's
// display). Code-drawn, gradients, no bitmaps.
//
// Design: 360 wide × the scene's height; the ground follows the bottom of the
// screen above the speech strip and the tray (a tall phone gets more sky,
// never a stretched lane).

/// How a customer feels (the face and the arms).
enum M7Mood { waiting, calm, upset }

/// Where things are (design px, 360 wide).
@immutable
class M7HonestGeo {
  const M7HonestGeo._(this.height, this.floorY);

  factory M7HonestGeo.forScene(double height, double inset) => M7HonestGeo._(height, height - bottomBlock - inset * 0.5);

  final double height;

  /// The ground line the figures stand on.
  final double floorY;

  /// The speech strip and the tray stand on this much of the bottom.
  static const double bottomBlock = 222;

  /// The customer's caption bubble (clear of the header and the guide).
  Rect get bubble => const Rect.fromLTWH(8, 124, 236, 84);

  /// The trainee (left, in front of the veranda).
  Rect get trainee => Rect.fromLTWH(8, floorY - 104, 44, 104);

  /// A customer's box: [right] stands further to the right in the lane.
  Rect customer(bool right) => Rect.fromLTWH(right ? 176 : 112, floorY - 114, 58, 114);

  /// The job sheet on its nail (the veranda wall), and where it is dropped.
  Rect get sheet => Rect.fromLTWH(60, floorY - 156, 46, 60);

  /// The pole and its transformer (right edge).
  Rect get pole => Rect.fromLTWH(296, floorY - 230, 58, 230);

  @override
  bool operator ==(Object other) => other is M7HonestGeo && other.height == height && other.floorY == floorY;

  @override
  int get hashCode => Object.hash(height, floorY);
}

/// What a customer looks like (dealt).
@immutable
class M7Look {
  const M7Look({required this.skin, required this.shirt, required this.hair, this.cap = false, this.dupatta = false, this.lungi = false});
  final Color skin;
  final Color shirt;
  final Color hair;
  final bool cap;
  final bool dupatta;
  final bool lungi;

  @override
  bool operator ==(Object other) => other is M7Look && other.skin == skin && other.shirt == shirt && other.hair == hair && other.cap == cap && other.dupatta == dupatta && other.lungi == lungi;

  @override
  int get hashCode => Object.hash(skin, shirt, hair, cap, dupatta, lungi);
}

/// Six looks to deal from.
const List<M7Look> kM7Looks = [
  M7Look(skin: Color(0xFFB07A52), shirt: Color(0xFF3F7F9E), hair: Color(0xFF1E1A18), lungi: true),
  M7Look(skin: Color(0xFFC58B63), shirt: Color(0xFFB4533C), hair: Color(0xFF2A2220), cap: true),
  M7Look(skin: Color(0xFF9A6A48), shirt: Color(0xFFC2457E), hair: Color(0xFF1A1614), dupatta: true),
  M7Look(skin: Color(0xFFD19A74), shirt: Color(0xFF5C8A4E), hair: Color(0xFFB9B5AE)),
  M7Look(skin: Color(0xFFA9714A), shirt: Color(0xFF7A5BA6), hair: Color(0xFF241E1B), lungi: true, cap: true),
  M7Look(skin: Color(0xFFBF8560), shirt: Color(0xFFD9A441), hair: Color(0xFF211B19), dupatta: true),
];

/// The lane: sky, roofs, trees, the veranda with its meter board, the pole
/// and its transformer, the ground. Still: it repaints only on a new size.
class M7HonestWorldPainter extends CustomPainter {
  const M7HonestWorldPainter({required this.geo});

  final M7HonestGeo geo;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    final sky = Rect.fromLTWH(0, 0, w, g.floorY);
    c.drawRect(
        sky,
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF6EB4E8), Color(0xFFBFE0F2), Color(0xFFE9F1E4)]).createShader(sky));
    // A noon sun, high.
    c.drawCircle(Offset(w * 0.78, 96), 26, Paint()..color = const Color(0x33FFF3B0));
    c.drawCircle(Offset(w * 0.78, 96), 15, Paint()..color = const Color(0xFFFFF6C4));
    _farTown(c, w, g.floorY);
    _veranda(c, g);
    _pole(c, g);
    // The lane.
    final ground = Rect.fromLTRB(0, g.floorY, w, size.height);
    c.drawRect(ground, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFB59C73), Color(0xFF8A7552)]).createShader(ground));
    c.drawRect(Rect.fromLTRB(0, g.floorY, w, g.floorY + 6), Paint()..color = const Color(0x33000000));
    final rnd = math.Random(7);
    final grass = Paint()
      ..color = const Color(0xFF5E8A46)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 26; i++) {
      final x = rnd.nextDouble() * w;
      final y = g.floorY + 6 + rnd.nextDouble() * 12;
      c.drawLine(Offset(x, y), Offset(x - 1, y - 5), grass);
      c.drawLine(Offset(x, y), Offset(x + 2, y - 4), grass);
    }
  }

  void _farTown(Canvas c, double w, double floorY) {
    final y = floorY - 70;
    // Roofs.
    final roofs = [
      (100.0, 56.0, 38.0, const Color(0xFFC78A62)),
      (160.0, 70.0, 46.0, const Color(0xFFB9C4C9)),
      (232.0, 50.0, 34.0, const Color(0xFFD1A57E)),
    ];
    for (final r in roofs) {
      c.drawRect(Rect.fromLTWH(r.$1, y - r.$3 + 36, r.$2, r.$3), Paint()..color = r.$4);
      c.drawRect(Rect.fromLTWH(r.$1 - 2, y - r.$3 + 32, r.$2 + 4, 5), Paint()..color = const Color(0xFF6B5A4A));
      c.drawRect(Rect.fromLTWH(r.$1 + 8, y - r.$3 + 46, 9, 14), Paint()..color = const Color(0xFF3E4A52));
    }
    // Trees.
    for (final t in [(84.0, 26.0), (150.0, 20.0), (224.0, 24.0), (286.0, 22.0)]) {
      c.drawRect(Rect.fromLTWH(t.$1 - 2, floorY - 42, 4, 40), Paint()..color = const Color(0xFF5C4630));
      c.drawCircle(Offset(t.$1, floorY - 46), t.$2, Paint()..color = const Color(0xFF4F8A4A));
      c.drawCircle(Offset(t.$1 - 8, floorY - 40), t.$2 * 0.7, Paint()..color = const Color(0xFF5FA056));
    }
  }

  void _veranda(Canvas c, M7HonestGeo g) {
    final f = g.floorY;
    // The house wall, the veranda roof and its posts.
    final wall = Rect.fromLTRB(0, f - 190, 118, f);
    c.drawRect(wall, Paint()..shader = const LinearGradient(colors: [Color(0xFFE6D3A8), Color(0xFFD9C192)]).createShader(wall));
    c.drawRect(Rect.fromLTRB(0, f - 200, 126, f - 186), Paint()..color = const Color(0xFF8A5A3C));
    c.drawRect(Rect.fromLTRB(0, f - 186, 126, f - 181), Paint()..color = const Color(0x33000000));
    c.drawRect(Rect.fromLTWH(118, f - 186, 8, 186), Paint()..color = const Color(0xFF9C6B45));
    // A window.
    c.drawRect(Rect.fromLTWH(10, f - 172, 36, 40), Paint()..color = const Color(0xFF47606E));
    c.drawLine(Offset(28, f - 172), Offset(28, f - 132), Paint()..color = const Color(0xFF6B5A4A));
    // The meter board: the new meter, its display, the wires in.
    final board = Rect.fromLTWH(60, f - 92, 52, 70);
    c.drawRRect(RRect.fromRectAndRadius(board, const Radius.circular(3)), Paint()..color = const Color(0xFF6E5A44));
    c.drawRRect(RRect.fromRectAndRadius(board.deflate(3), const Radius.circular(2)), Paint()..color = const Color(0xFFCBBF9F));
    final meter = Rect.fromLTWH(board.left + 8, board.top + 8, 36, 40);
    c.drawRRect(RRect.fromRectAndRadius(meter, const Radius.circular(4)), Paint()..color = const Color(0xFFF1F3F4));
    c.drawRRect(
        RRect.fromRectAndRadius(meter, const Radius.circular(4)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = const Color(0xFF6B747A));
    c.drawRect(Rect.fromLTWH(meter.left + 5, meter.top + 6, 26, 11), Paint()..color = const Color(0xFF1B2A24));
    _text(c, '0042.7', Offset(meter.center.dx, meter.top + 11.5), 6.6, const Color(0xFF9BE8A6));
    c.drawCircle(Offset(meter.center.dx, meter.top + 29), 5, Paint()..color = const Color(0xFFD7DBDD));
    for (final x in [meter.left + 8, meter.right - 8]) {
      c.drawLine(Offset(x, meter.bottom), Offset(x, board.bottom - 2), Paint()
        ..color = const Color(0xFF2C2C2C)
        ..strokeWidth = 2.2);
    }
    // The old meter in its cloth bag, on the floor.
    final bag = Path()
      ..moveTo(116, f)
      ..quadraticBezierTo(112, f - 22, 124, f - 28)
      ..lineTo(142, f - 28)
      ..quadraticBezierTo(154, f - 22, 150, f)
      ..close();
    c.drawPath(bag, Paint()..color = const Color(0xFFB9926A));
    c.drawLine(Offset(124, f - 28), Offset(142, f - 28), Paint()
      ..color = const Color(0xFF6B4A2E)
      ..strokeWidth = 2.4);
    c.drawCircle(Offset(133, f - 12), 7, Paint()..color = const Color(0x33FFFFFF));
    // The nail the job sheet hangs on.
    c.drawCircle(Offset(g.sheet.center.dx, g.sheet.top - 4), 2.4, Paint()..color = const Color(0xFF5C5C5C));
  }

  void _pole(Canvas c, M7HonestGeo g) {
    final p = g.pole;
    final f = g.floorY;
    final x = p.center.dx;
    // The pole.
    c.drawRect(Rect.fromLTWH(x - 5, p.top, 10, p.height), Paint()..color = const Color(0xFF8E8A82));
    c.drawRect(Rect.fromLTWH(x - 5, p.top, 3, p.height), Paint()..color = const Color(0x33FFFFFF));
    // Cross-arm with the AB switch (three blades, closed) and the HG fuses.
    final arm = p.top + 10;
    c.drawRect(Rect.fromLTWH(x - 34, arm, 68, 6), Paint()..color = const Color(0xFF59626B));
    for (var i = 0; i < 3; i++) {
      final ix = x - 26 + i * 26.0;
      c.drawRect(Rect.fromLTWH(ix - 2, arm - 8, 4, 8), Paint()..color = const Color(0xFFEDE3C8));
      c.drawLine(Offset(ix, arm - 8), Offset(ix, arm - 30), Paint()
        ..color = const Color(0xFF2B2B2B)
        ..strokeWidth = 1.4);
      c.drawLine(Offset(ix, arm + 6), Offset(ix + 4, arm + 26), Paint()
        ..color = const Color(0xFFB87333)
        ..strokeWidth = 2.6);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(ix - 3, arm + 24, 6, 16), const Radius.circular(2)), Paint()..color = const Color(0xFFC9B07A));
    }
    // The AB switch handle down the pole.
    c.drawLine(Offset(x + 5, arm + 8), Offset(x + 5, arm + 72), Paint()
      ..color = const Color(0xFF3A4048)
      ..strokeWidth = 2);
    c.drawCircle(Offset(x + 5, arm + 72), 3, Paint()..color = const Color(0xFFD7332A));
    // The pole-mounted transformer.
    final tank = Rect.fromLTWH(x - 24, arm + 82, 48, 56);
    c.drawRRect(RRect.fromRectAndRadius(tank, const Radius.circular(6)), Paint()..shader = const LinearGradient(colors: [Color(0xFF9BA6AE), Color(0xFF6E7A83)]).createShader(tank));
    for (var i = 1; i < 6; i++) {
      c.drawLine(Offset(tank.left + i * 8, tank.top + 6), Offset(tank.left + i * 8, tank.bottom - 6), Paint()
        ..color = const Color(0x44000000)
        ..strokeWidth = 1.2);
    }
    for (var i = 0; i < 3; i++) {
      c.drawRect(Rect.fromLTWH(tank.left + 8 + i * 14.0, tank.top - 6, 5, 7), Paint()..color = const Color(0xFFEDE3C8));
    }
    // Wires away to the left.
    final wire = Paint()
      ..color = const Color(0xFF2B2B2B)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 3; i++) {
      final y0 = arm - 28 + i * 3.0;
      c.drawPath(
          Path()
            ..moveTo(x - 26 + i * 26.0, y0)
            ..quadraticBezierTo(x - 120, y0 + 38, -10, y0 + 6),
          wire);
    }
    c.drawRect(Rect.fromLTWH(x - 8, f - 5, 16, 5), Paint()..color = const Color(0x33000000));
  }

  void _text(Canvas c, String text, Offset centre, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.4)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(M7HonestWorldPainter old) => old.geo != geo;
}

/// One customer, standing: the look, the mood (the face, a raised hand when
/// upset), facing left or right.
class M7CustomerPainter extends CustomPainter {
  const M7CustomerPainter({required this.look, required this.mood, required this.faceLeft});

  final M7Look look;
  final M7Mood mood;
  final bool faceLeft;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    if (faceLeft) {
      c.translate(w, 0);
      c.scale(-1, 1);
    }
    final cx = w / 2;
    // Shadow.
    c.drawOval(Rect.fromCenter(center: Offset(cx, h - 2), width: w * 0.9, height: 7), Paint()..color = const Color(0x33000000));
    // Legs or a lungi.
    if (look.lungi) {
      final p = Path()
        ..moveTo(cx - 15, h * 0.52)
        ..lineTo(cx + 15, h * 0.52)
        ..lineTo(cx + 17, h - 8)
        ..lineTo(cx - 17, h - 8)
        ..close();
      c.drawPath(p, Paint()..color = const Color(0xFF6A7FB4));
      c.drawLine(Offset(cx - 8, h * 0.56), Offset(cx - 9, h - 10), Paint()..color = const Color(0x55FFFFFF));
    } else {
      for (final dx in [-8.0, 8.0]) {
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + dx - 6, h * 0.52, 12, h * 0.48 - 4), const Radius.circular(4)), Paint()..color = const Color(0xFF3B4252));
      }
    }
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 16, h - 8, 14, 6), const Radius.circular(3)), Paint()..color = const Color(0xFF2B2420));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx + 2, h - 8, 14, 6), const Radius.circular(3)), Paint()..color = const Color(0xFF2B2420));
    // Torso.
    final torso = RRect.fromRectAndRadius(Rect.fromLTWH(cx - 18, h * 0.27, 36, h * 0.3), const Radius.circular(10));
    c.drawRRect(torso, Paint()..color = look.shirt);
    c.drawRRect(torso, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0x44000000));
    if (look.dupatta) {
      final d = Path()
        ..moveTo(cx - 18, h * 0.3)
        ..quadraticBezierTo(cx, h * 0.46, cx + 20, h * 0.28)
        ..lineTo(cx + 22, h * 0.56)
        ..lineTo(cx + 12, h * 0.56)
        ..quadraticBezierTo(cx, h * 0.42, cx - 12, h * 0.56)
        ..close();
      c.drawPath(d, Paint()..color = const Color(0xFFF1E7D0));
    }
    // Arms: down when waiting or calm; one raised and one on the hip when upset.
    final arm = Paint()
      ..color = look.skin
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final sleeve = Paint()
      ..color = look.shirt
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    if (mood == M7Mood.upset) {
      c.drawLine(Offset(cx + 16, h * 0.33), Offset(cx + 26, h * 0.2), sleeve);
      c.drawLine(Offset(cx + 26, h * 0.2), Offset(cx + 27, h * 0.1), arm);
      c.drawLine(Offset(cx - 16, h * 0.33), Offset(cx - 24, h * 0.46), sleeve);
      c.drawLine(Offset(cx - 24, h * 0.46), Offset(cx - 14, h * 0.52), arm);
    } else {
      c.drawLine(Offset(cx - 17, h * 0.33), Offset(cx - 21, h * 0.5), sleeve);
      c.drawLine(Offset(cx - 21, h * 0.5), Offset(cx - 20, h * 0.58), arm);
      c.drawLine(Offset(cx + 17, h * 0.33), Offset(cx + 21, h * 0.5), sleeve);
      c.drawLine(Offset(cx + 21, h * 0.5), Offset(cx + 20, h * 0.58), arm);
    }
    // Head.
    final head = Offset(cx, h * 0.17);
    const hr = 15.0;
    c.drawCircle(head, hr, Paint()..color = look.skin);
    if (look.cap) {
      c.drawPath(
          Path()
            ..moveTo(cx - hr, head.dy - 1)
            ..quadraticBezierTo(cx, head.dy - hr - 9, cx + hr, head.dy - 1)
            ..close(),
          Paint()..color = const Color(0xFFF2F2EC));
    } else {
      c.drawPath(
          Path()
            ..moveTo(cx - hr, head.dy + 1)
            ..quadraticBezierTo(cx, head.dy - hr - 7, cx + hr, head.dy + 1)
            ..quadraticBezierTo(cx, head.dy - 6, cx - hr, head.dy + 1)
            ..close(),
          Paint()..color = look.hair);
    }
    // Face: brows and mouth show the mood.
    final ink = Paint()
      ..color = const Color(0xFF2A1C14)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    c.drawCircle(Offset(cx - 5, head.dy + 1), 1.5, Paint()..color = const Color(0xFF1A1210));
    c.drawCircle(Offset(cx + 5, head.dy + 1), 1.5, Paint()..color = const Color(0xFF1A1210));
    switch (mood) {
      case M7Mood.waiting:
        c.drawLine(Offset(cx - 4, head.dy + 8), Offset(cx + 4, head.dy + 8), ink);
        c.drawLine(Offset(cx - 8, head.dy - 3.5), Offset(cx - 2, head.dy - 4), ink);
        c.drawLine(Offset(cx + 2, head.dy - 4), Offset(cx + 8, head.dy - 3.5), ink);
      case M7Mood.calm:
        c.drawPath(Path()..moveTo(cx - 5, head.dy + 6)..quadraticBezierTo(cx, head.dy + 11, cx + 5, head.dy + 6), ink);
      case M7Mood.upset:
        c.drawPath(Path()..moveTo(cx - 5, head.dy + 10)..quadraticBezierTo(cx, head.dy + 5, cx + 5, head.dy + 10), ink);
        c.drawLine(Offset(cx - 8, head.dy - 2), Offset(cx - 2, head.dy - 5), ink);
        c.drawLine(Offset(cx + 2, head.dy - 5), Offset(cx + 8, head.dy - 2), ink);
    }
  }

  @override
  bool shouldRepaint(M7CustomerPainter old) => old.look != look || old.mood != mood || old.faceLeft != faceLeft;
}
