import 'dart:math' as math;

import 'package:flutter/material.dart';

// The drawn world of lesson 8.6 কাজ "রাগ নয়, ঠিক রাস্তা" (m8_grievance_reply.
// dart): a para lane at dusk beside the van after a job. On the left the van
// with a board on its side (three planks, the complaint ladder: ডকেট · 1912 /
// CCC, CGRF, অম্বুডসম্যান; the planks themselves are widgets in the page), the
// trainee in front of it with the consumer's case file; far off a house gate
// and a tea stall; a street light, and a pole with its service lines on the
// right. Consumers (silent, with caption bubbles) walk up one at a time; an
// anger cloud swells over his head while he speaks.
//
// No text in the art. Code-drawn, gradients, no bitmaps. No logos (M8-11).
//
// Design: 360 wide × the scene's height; the ground follows the bottom of the
// screen above the deck / the send button (a tall phone gets more sky, never a
// stretched lane).

/// How a consumer feels (the face and the arms).
enum M8Mood { waiting, calm, upset }

/// Where things are (design px, 360 wide).
@immutable
class M8Geo {
  const M8Geo._(this.height, this.floorY);

  factory M8Geo.forScene(double height, double inset) => M8Geo._(height, height - bottomBlock - inset * 0.5);

  final double height;

  /// The ground line the figures stand on.
  final double floorY;

  /// The reply deck stands on this much of the bottom.
  static const double bottomBlock = 222;

  /// The consumer's caption bubble (clear of the header and the guide).
  Rect get bubble => const Rect.fromLTWH(8, 124, 236, 84);

  /// The van's body (left edge).
  Rect get van => Rect.fromLTWH(-8, floorY - 158, 114, 158);

  /// The board on the van's side that holds the three planks.
  Rect get board => Rect.fromLTWH(6, floorY - 152, 94, 118);

  /// Plank [i] of the ladder (0 = the lowest rung).
  Rect rung(int i) => Rect.fromLTWH(10, floorY - 72 - i * 38.0, 84, 32);

  /// Where the file sits on rung [i] (right end of the plank).
  Rect fileOnRung(int i) {
    final r = rung(i);
    return Rect.fromLTWH(r.right - 30, r.top + 2, 26, 28);
  }

  /// The trainee (in front of the van).
  Rect get trainee => Rect.fromLTWH(104, floorY - 104, 44, 104);

  /// The case file in the trainee's hand (its home).
  Rect get file => Rect.fromLTWH(140, floorY - 68, 30, 38);

  /// A consumer's box (with room above for his anger cloud): [right] stands
  /// further to the right in the lane.
  Rect consumer(bool right) => Rect.fromLTWH(right ? 194 : 172, floorY - 114, 58, 114);

  /// The anger cloud over a consumer's head.
  Rect cloud(bool right) {
    final c = consumer(right);
    return Rect.fromLTWH(c.left - 8, c.top - 40, 74, 42);
  }

  @override
  bool operator ==(Object other) => other is M8Geo && other.height == height && other.floorY == floorY;

  @override
  int get hashCode => Object.hash(height, floorY);
}

/// What a consumer looks like (dealt).
@immutable
class M8Look {
  const M8Look({required this.skin, required this.shirt, required this.hair, this.cap = false, this.dupatta = false, this.lungi = false});
  final Color skin;
  final Color shirt;
  final Color hair;
  final bool cap;
  final bool dupatta;
  final bool lungi;

  @override
  bool operator ==(Object other) => other is M8Look && other.skin == skin && other.shirt == shirt && other.hair == hair && other.cap == cap && other.dupatta == dupatta && other.lungi == lungi;

  @override
  int get hashCode => Object.hash(skin, shirt, hair, cap, dupatta, lungi);
}

/// Six looks to deal from.
const List<M8Look> kM8Looks = [
  M8Look(skin: Color(0xFFB07A52), shirt: Color(0xFF4A8FA8), hair: Color(0xFF1E1A18), lungi: true),
  M8Look(skin: Color(0xFFC58B63), shirt: Color(0xFFA8493A), hair: Color(0xFF2A2220), cap: true),
  M8Look(skin: Color(0xFF9A6A48), shirt: Color(0xFFB8467A), hair: Color(0xFF1A1614), dupatta: true),
  M8Look(skin: Color(0xFFD19A74), shirt: Color(0xFF5C8A4E), hair: Color(0xFFB9B5AE)),
  M8Look(skin: Color(0xFFA9714A), shirt: Color(0xFF7A5BA6), hair: Color(0xFF241E1B), lungi: true, cap: true),
  M8Look(skin: Color(0xFFBF8560), shirt: Color(0xFFD9A441), hair: Color(0xFF211B19), dupatta: true),
];

/// The lane at dusk: sky, roofs, a house gate, a tea stall, trees, the van,
/// the street light, the pole and its service lines, the ground. Still: it
/// repaints only on a new size.
class M8GrievanceWorldPainter extends CustomPainter {
  const M8GrievanceWorldPainter({required this.geo});

  final M8Geo geo;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    final sky = Rect.fromLTWH(0, 0, w, g.floorY);
    c.drawRect(
        sky,
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2B3A6B), Color(0xFF8A5C8E), Color(0xFFF0A36B), Color(0xFFF6CF93)], stops: [0, 0.45, 0.8, 1]).createShader(sky));
    // A low sun behind the roofs.
    c.drawCircle(Offset(w * 0.3, g.floorY - 96), 30, Paint()..color = const Color(0x44FFE3A0));
    c.drawCircle(Offset(w * 0.3, g.floorY - 96), 17, Paint()..color = const Color(0xFFFFE9B8));
    _farTown(c, w, g.floorY);
    _gate(c, g);
    _teaStall(c, g);
    _streetLight(c, g);
    _pole(c, g);
    _van(c, g);
    // The lane.
    final ground = Rect.fromLTRB(0, g.floorY, w, size.height);
    c.drawRect(ground, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8E7A5C), Color(0xFF5E513C)]).createShader(ground));
    c.drawRect(Rect.fromLTRB(0, g.floorY, w, g.floorY + 6), Paint()..color = const Color(0x44000000));
    final rnd = math.Random(11);
    final grass = Paint()
      ..color = const Color(0xFF4C703A)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 24; i++) {
      final x = rnd.nextDouble() * w;
      final y = g.floorY + 6 + rnd.nextDouble() * 12;
      c.drawLine(Offset(x, y), Offset(x - 1, y - 5), grass);
      c.drawLine(Offset(x, y), Offset(x + 2, y - 4), grass);
    }
  }

  void _farTown(Canvas c, double w, double floorY) {
    final y = floorY - 74;
    final roofs = [
      (118.0, 52.0, 36.0, const Color(0xFF6B4E5E)),
      (172.0, 66.0, 44.0, const Color(0xFF5C5468)),
      (244.0, 48.0, 32.0, const Color(0xFF745662)),
    ];
    for (final r in roofs) {
      c.drawRect(Rect.fromLTWH(r.$1, y - r.$3 + 36, r.$2, r.$3), Paint()..color = r.$4);
      c.drawRect(Rect.fromLTWH(r.$1 - 2, y - r.$3 + 32, r.$2 + 4, 5), Paint()..color = const Color(0xFF3E3040));
      c.drawRect(Rect.fromLTWH(r.$1 + 8, y - r.$3 + 46, 8, 12), Paint()..color = const Color(0xFFF2C46B));
    }
    for (final t in [(98.0, 22.0), (160.0, 18.0), (236.0, 22.0), (292.0, 20.0)]) {
      c.drawRect(Rect.fromLTWH(t.$1 - 2, floorY - 40, 4, 38), Paint()..color = const Color(0xFF3B2E2A));
      c.drawCircle(Offset(t.$1, floorY - 44), t.$2, Paint()..color = const Color(0xFF3A5A3E));
      c.drawCircle(Offset(t.$1 - 7, floorY - 38), t.$2 * 0.7, Paint()..color = const Color(0xFF486B46));
    }
  }

  /// A house gate: two brick posts and an iron gate, a lit window behind.
  void _gate(Canvas c, M8Geo g) {
    final f = g.floorY;
    c.drawRect(Rect.fromLTWH(112, f - 66, 8, 66), Paint()..color = const Color(0xFF8C5A44));
    c.drawRect(Rect.fromLTWH(196, f - 66, 8, 66), Paint()..color = const Color(0xFF8C5A44));
    c.drawRect(Rect.fromLTWH(110, f - 70, 12, 5), Paint()..color = const Color(0xFF5E3C2E));
    c.drawRect(Rect.fromLTWH(194, f - 70, 12, 5), Paint()..color = const Color(0xFF5E3C2E));
    final bar = Paint()
      ..color = const Color(0xFF2A2A30)
      ..strokeWidth = 2;
    c.drawLine(Offset(120, f - 56), Offset(196, f - 56), bar);
    c.drawLine(Offset(120, f - 14), Offset(196, f - 14), bar);
    for (var x = 126.0; x < 196; x += 10) {
      c.drawLine(Offset(x, f - 56), Offset(x, f - 14), bar);
    }
  }

  /// A tea stall: a thatched awning on two poles, a counter, a kettle.
  void _teaStall(Canvas c, M8Geo g) {
    final f = g.floorY;
    c.drawRect(Rect.fromLTWH(208, f - 62, 3, 62), Paint()..color = const Color(0xFF5C4630));
    c.drawRect(Rect.fromLTWH(264, f - 62, 3, 62), Paint()..color = const Color(0xFF5C4630));
    c.drawPath(
        Path()
          ..moveTo(204, f - 58)
          ..lineTo(270, f - 58)
          ..lineTo(262, f - 74)
          ..lineTo(212, f - 74)
          ..close(),
        Paint()..color = const Color(0xFF9C7A3E));
    c.drawRect(Rect.fromLTWH(210, f - 26, 54, 26), Paint()..color = const Color(0xFF6E5238));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(222, f - 38, 14, 12), const Radius.circular(3)), Paint()..color = const Color(0xFFB9C0C4));
    c.drawCircle(Offset(244, f - 50), 5, Paint()..color = const Color(0x55FFE3A0));
  }

  void _streetLight(Canvas c, M8Geo g) {
    final f = g.floorY;
    const x = 282.0;
    c.drawRect(Rect.fromLTWH(x - 2, f - 128, 4, 128), Paint()..color = const Color(0xFF3A3F48));
    c.drawLine(Offset(x, f - 128), Offset(x - 16, f - 126), Paint()
      ..color = const Color(0xFF3A3F48)
      ..strokeWidth = 3);
    c.drawCircle(Offset(x - 18, f - 120), 16, Paint()..color = const Color(0x33FFE9A8));
    c.drawCircle(Offset(x - 18, f - 124), 6, Paint()..color = const Color(0xFFFFEFB8));
  }

  void _pole(Canvas c, M8Geo g) {
    final f = g.floorY;
    const x = 338.0;
    c.drawRect(Rect.fromLTWH(x - 5, f - 210, 10, 210), Paint()..color = const Color(0xFF6E6A66));
    c.drawRect(Rect.fromLTWH(x - 5, f - 210, 3, 210), Paint()..color = const Color(0x22FFFFFF));
    final arm = f - 196;
    c.drawRect(Rect.fromLTWH(x - 28, arm, 56, 5), Paint()..color = const Color(0xFF3F464E));
    for (var i = 0; i < 3; i++) {
      final ix = x - 22 + i * 22.0;
      c.drawRect(Rect.fromLTWH(ix - 2, arm - 6, 4, 6), Paint()..color = const Color(0xFFD9CFB4));
    }
    // The service lines: one dips to the house (a gate light), the rest run on.
    final wire = Paint()
      ..color = const Color(0xFF1E1E22)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 3; i++) {
      final y0 = arm - 6 + i * 2.0;
      c.drawPath(
          Path()
            ..moveTo(x - 22 + i * 22.0, y0)
            ..quadraticBezierTo(x - 150, y0 + 40 + i * 4, -10, y0 + 14),
          wire);
    }
    c.drawPath(
        Path()
          ..moveTo(x - 4, arm + 8)
          ..quadraticBezierTo(x - 70, arm + 70, 204, f - 66),
        wire);
  }

  /// The van, side-on: body, the board's frame, a cab edge and a wheel.
  void _van(Canvas c, M8Geo g) {
    final v = g.van;
    final body = RRect.fromRectAndRadius(v, const Radius.circular(8));
    c.drawRRect(body, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE9E4D6), Color(0xFFBDB8AA)]).createShader(v));
    c.drawRect(Rect.fromLTWH(v.left, v.top + 8, v.width, 5), Paint()..color = const Color(0xFFC0392B));
    // The board the planks hang on.
    final b = g.board;
    c.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(5)), Paint()..color = const Color(0xFF4A3A2C));
    c.drawRRect(RRect.fromRectAndRadius(b.deflate(3), const Radius.circular(3)), Paint()..color = const Color(0xFFF3EEDD));
    // The wheel.
    c.drawCircle(Offset(v.left + 34, g.floorY - 2), 17, Paint()..color = const Color(0xFF24262A));
    c.drawCircle(Offset(v.left + 34, g.floorY - 2), 8, Paint()..color = const Color(0xFF9AA0A6));
    c.drawRect(Rect.fromLTWH(v.right - 4, g.floorY - 6, 6, 5), Paint()..color = const Color(0x55000000));
  }

  @override
  bool shouldRepaint(M8GrievanceWorldPainter old) => old.geo != geo;
}

/// One consumer, standing: the look, the mood (the face, a raised fist when
/// upset), facing left or right.
class M8ConsumerPainter extends CustomPainter {
  const M8ConsumerPainter({required this.look, required this.mood, required this.faceLeft});

  final M8Look look;
  final M8Mood mood;
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
    c.drawOval(Rect.fromCenter(center: Offset(cx, h - 2), width: w * 0.9, height: 7), Paint()..color = const Color(0x44000000));
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
    final torso = RRect.fromRectAndRadius(Rect.fromLTWH(cx - 18, h * 0.27, 36, h * 0.3), const Radius.circular(10));
    c.drawRRect(torso, Paint()..color = look.shirt);
    c.drawRRect(
        torso,
        Paint()
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
    final arm = Paint()
      ..color = look.skin
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final sleeve = Paint()
      ..color = look.shirt
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    if (mood == M8Mood.upset) {
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
    final ink = Paint()
      ..color = const Color(0xFF2A1C14)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    c.drawCircle(Offset(cx - 5, head.dy + 1), 1.5, Paint()..color = const Color(0xFF1A1210));
    c.drawCircle(Offset(cx + 5, head.dy + 1), 1.5, Paint()..color = const Color(0xFF1A1210));
    switch (mood) {
      case M8Mood.waiting:
        c.drawLine(Offset(cx - 4, head.dy + 8), Offset(cx + 4, head.dy + 8), ink);
        c.drawLine(Offset(cx - 8, head.dy - 3.5), Offset(cx - 2, head.dy - 4), ink);
        c.drawLine(Offset(cx + 2, head.dy - 4), Offset(cx + 8, head.dy - 3.5), ink);
      case M8Mood.calm:
        c.drawPath(Path()..moveTo(cx - 5, head.dy + 6)..quadraticBezierTo(cx, head.dy + 11, cx + 5, head.dy + 6), ink);
      case M8Mood.upset:
        c.drawPath(Path()..moveTo(cx - 5, head.dy + 10)..quadraticBezierTo(cx, head.dy + 5, cx + 5, head.dy + 10), ink);
        c.drawLine(Offset(cx - 8, head.dy - 2), Offset(cx - 2, head.dy - 5), ink);
        c.drawLine(Offset(cx + 2, head.dy - 5), Offset(cx + 8, head.dy - 2), ink);
    }
  }

  @override
  bool shouldRepaint(M8ConsumerPainter old) => old.look != look || old.mood != mood || old.faceLeft != faceLeft;
}

/// The anger cloud over a consumer's head: [anger] 0 (gone) … 1 (full) … a bit
/// more when he shouts back; [red] while he flashes red.
class M8CloudPainter extends CustomPainter {
  const M8CloudPainter({required this.anger, required this.red});

  final double anger;
  final bool red;

  @override
  void paint(Canvas c, Size size) {
    final a = anger.clamp(0.0, 1.3);
    if (a <= 0.02) return;
    final s = 0.35 + 0.65 * math.min(a, 1.0) + (a > 1 ? (a - 1) * 0.5 : 0);
    final base = red ? const Color(0xFFB8322A) : const Color(0xFF50505C);
    final dark = red ? const Color(0xFF7E1F1A) : const Color(0xFF34343E);
    final cx = size.width / 2;
    final cy = size.height * 0.62;
    c.save();
    c.translate(cx, cy);
    c.scale(s);
    final op = math.min(1.0, a * 1.6);
    final p = Paint()..color = base.withValues(alpha: op);
    for (final (dx, dy, r) in const [(-20.0, 4.0, 13.0), (-6.0, -6.0, 16.0), (10.0, -4.0, 15.0), (22.0, 5.0, 12.0), (0.0, 7.0, 15.0)]) {
      c.drawCircle(Offset(dx, dy), r, p);
    }
    c.drawCircle(const Offset(-4, 10), 10, Paint()..color = dark.withValues(alpha: op * 0.55));
    // Two angry slits.
    final ink = Paint()
      ..color = const Color(0xFFF5F0E6).withValues(alpha: op)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    c.drawLine(const Offset(-10, -2), const Offset(-3, 1), ink);
    c.drawLine(const Offset(10, -2), const Offset(3, 1), ink);
    c.restore();
  }

  @override
  bool shouldRepaint(M8CloudPainter old) => old.anger != anger || old.red != red;
}
