import 'dart:math' as math;

import 'package:flutter/material.dart';

// The drawn world of lesson 8.1 "জনশুনানির দাঁড়িপাল্লা" (m8_hearing_balance.dart):
// a public-hearing hall in a district town, in layers: tall windows with
// evening light and ceiling fans → the commission bench at the front under a
// plain banner 'WBERC · জনশুনানি' → the company table on the left (files and
// its own stamp pad) → consumer benches on the right → the centre aisle where
// the trainee stands with the roving mic → the hall door. Above the bench
// hangs a brass balance with two pans (an office icon left, a home icon right)
// and a free-swinging pointer: no numbers, no marked level zone.
//
// No logos and no real forms (owner M8-11): plain text labels only. Code-drawn
// with gradients, no bitmaps. The balance and the people are separate painters
// (the hall itself is still and repaints only on a new size).
//
// Design: 360 wide × the scene's height; everything hangs from the top, the
// floor runs down to the bottom of the screen (a tall phone gets more floor).

/// Which side a speaker is on.
enum M8Side { office, home }

/// How a person is drawn.
enum M8Pose { seated, raised, speaking, standing, walking }

/// Where things are (design px, 360 wide).
@immutable
class M8Geo {
  const M8Geo._(this.height);

  factory M8Geo.forScene(double height, double inset) => M8Geo._(height);

  final double height;

  /// Seats per side (3 columns × 3 rows).
  static const int seatsPerSide = 9;

  /// The brass balance above the bench.
  Rect get balance => const Rect.fromLTWH(80, 112, 200, 134);

  /// The commission bench (a drop target for the file and the sheet).
  Rect get bench => const Rect.fromLTWH(104, 246, 152, 54);

  /// The strip of hearing time inlaid in the bench front.
  Rect get timeBar => const Rect.fromLTWH(122, 284, 116, 8);

  /// The company's table, its stamp pad, and the pad's drop area.
  Rect get companyTable => const Rect.fromLTWH(6, 246, 92, 54);
  Rect get pad => const Rect.fromLTWH(54, 252, 40, 26);
  Rect get padTarget => const Rect.fromLTWH(44, 236, 60, 62);

  /// The consumer benches (right).
  Rect get consumerBench => const Rect.fromLTWH(262, 252, 92, 48);

  /// The speaker's caption (below the bench row, above the seats).
  Rect get bubble => const Rect.fromLTWH(8, 306, 344, 48);

  /// A seat: [idx] 0..8, three columns and three rows per side.
  Rect seat(M8Side side, int idx) {
    final col = idx % 3;
    final row = idx ~/ 3;
    final x = side == M8Side.office ? 6.0 + col * 38 : 246.0 + col * 38;
    return Rect.fromLTWH(x, 364.0 + row * 58, 36, 56);
  }

  /// The trainee, standing in the aisle; the mic at rest; the file in hand.
  Rect get trainee => const Rect.fromLTWH(150, 404, 44, 104);
  Rect get micHome => const Rect.fromLTWH(198, 458, 44, 44);
  Rect get fileHome => const Rect.fromLTWH(196, 404, 46, 50);

  /// The company officer who brings the proposal.
  Rect get proposalOfficer => const Rect.fromLTWH(108, 424, 36, 60);

  /// The foul officer walks from [foulStart] to [foulEnd] (toward his own pad).
  Rect get foulStart => const Rect.fromLTWH(124, 308, 36, 56);
  Rect get foulEnd => const Rect.fromLTWH(52, 296, 36, 56);

  /// The unhappy party who waves the order (appeal beat).
  Rect get protester => const Rect.fromLTWH(196, 384, 46, 80);

  /// The hall door (right wall).
  Rect get door => const Rect.fromLTWH(318, 112, 38, 110);

  /// The mic held up at a speaker's seat.
  Rect micAt(Rect seat) => Rect.fromLTWH(seat.center.dx - 22, seat.top - 6, 44, 44);

  @override
  bool operator ==(Object other) => other is M8Geo && other.height == height;

  @override
  int get hashCode => height.hashCode;
}

/// What a person looks like.
@immutable
class M8Look {
  const M8Look({required this.skin, required this.shirt, required this.hair, this.tie = false, this.cap = false, this.dupatta = false});
  final Color skin;
  final Color shirt;
  final Color hair;
  final bool tie;
  final bool cap;
  final bool dupatta;

  @override
  bool operator ==(Object other) => other is M8Look && other.skin == skin && other.shirt == shirt && other.hair == hair && other.tie == tie && other.cap == cap && other.dupatta == dupatta;

  @override
  int get hashCode => Object.hash(skin, shirt, hair, tie, cap, dupatta);
}

/// Company officers (a shirt and tie).
const List<M8Look> kM8OfficeLooks = [
  M8Look(skin: Color(0xFFC58B63), shirt: Color(0xFFE8EEF2), hair: Color(0xFF1E1A18), tie: true),
  M8Look(skin: Color(0xFFB07A52), shirt: Color(0xFFBFD3E3), hair: Color(0xFF2A2220), tie: true),
  M8Look(skin: Color(0xFFD19A74), shirt: Color(0xFFF1E9DA), hair: Color(0xFFB9B5AE), tie: true),
  M8Look(skin: Color(0xFF9A6A48), shirt: Color(0xFFD9E4D4), hair: Color(0xFF1A1614), tie: true),
];

/// Consumers (everyday clothes).
const List<M8Look> kM8HomeLooks = [
  M8Look(skin: Color(0xFFB07A52), shirt: Color(0xFF3F7F9E), hair: Color(0xFF1E1A18)),
  M8Look(skin: Color(0xFFC58B63), shirt: Color(0xFFB4533C), hair: Color(0xFF2A2220), cap: true),
  M8Look(skin: Color(0xFF9A6A48), shirt: Color(0xFFC2457E), hair: Color(0xFF1A1614), dupatta: true),
  M8Look(skin: Color(0xFFD19A74), shirt: Color(0xFF5C8A4E), hair: Color(0xFFB9B5AE)),
  M8Look(skin: Color(0xFFA9714A), shirt: Color(0xFF7A5BA6), hair: Color(0xFF241E1B), cap: true),
  M8Look(skin: Color(0xFFBF8560), shirt: Color(0xFFD9A441), hair: Color(0xFF211B19), dupatta: true),
];

/// The hall: wall and tall windows with evening light, ceiling fans, the
/// bench with its banner, the company table with files and the stamp pad, the
/// consumer benches, the floor and the aisle runner, the door. Still.
class M8HallPainter extends CustomPainter {
  const M8HallPainter({required this.geo});

  final M8Geo geo;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final g = geo;
    // The wall.
    final wall = Rect.fromLTWH(0, 0, w, 300);
    c.drawRect(wall, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFD9C79B), Color(0xFFC4AE80)]).createShader(wall));
    // A wooden dado on the lower wall.
    c.drawRect(const Rect.fromLTWH(0, 212, 360, 90), Paint()..color = const Color(0xFF7B5A3A));
    c.drawRect(const Rect.fromLTWH(0, 208, 360, 5), Paint()..color = const Color(0xFF5E4229));
    for (var x = 0.0; x < 360; x += 36) {
      c.drawRect(Rect.fromLTWH(x + 4, 220, 28, 76), Paint()..color = const Color(0x22000000));
    }
    _windows(c);
    _fans(c);
    _door(c, g);
    // The floor and the aisle runner.
    final floor = Rect.fromLTRB(0, 300, w, size.height);
    c.drawRect(floor, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFA67C52), Color(0xFF7E5A3A)]).createShader(floor));
    for (var y = 312.0; y < size.height; y += 22) {
      c.drawLine(Offset(0, y), Offset(w, y), Paint()
        ..color = const Color(0x22000000)
        ..strokeWidth = 1);
    }
    final runner = Rect.fromLTRB(126, 300, 234, size.height);
    c.drawRect(runner, Paint()..color = const Color(0xFF8E2F2F));
    c.drawRect(Rect.fromLTRB(126, 300, 130, size.height), Paint()..color = const Color(0xFFD9A441));
    c.drawRect(Rect.fromLTRB(230, 300, 234, size.height), Paint()..color = const Color(0xFFD9A441));
    c.drawRect(Rect.fromLTRB(126, 300, 234, 306), Paint()..color = const Color(0x33000000));
    _benchFront(c, g);
    _companyTable(c, g);
    _consumerBench(c, g);
  }

  void _windows(Canvas c) {
    for (final x in [14.0, 84.0, 250.0]) {
      final r = Rect.fromLTWH(x, 112, 46, 86);
      final arch = Path()
        ..moveTo(r.left, r.bottom)
        ..lineTo(r.left, r.top + 22)
        ..quadraticBezierTo(r.center.dx, r.top - 10, r.right, r.top + 22)
        ..lineTo(r.right, r.bottom)
        ..close();
      c.drawPath(arch, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFD58A), Color(0xFFF2A65A)]).createShader(r));
      c.drawPath(arch, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFF5E4229));
      c.drawLine(Offset(r.center.dx, r.top + 4), Offset(r.center.dx, r.bottom), Paint()
        ..color = const Color(0xFF5E4229)
        ..strokeWidth = 2);
      c.drawLine(Offset(r.left, r.top + 44), Offset(r.right, r.top + 44), Paint()
        ..color = const Color(0xFF5E4229)
        ..strokeWidth = 2);
    }
  }

  void _fans(Canvas c) {
    for (final x in [70.0, 290.0]) {
      c.drawLine(Offset(x, 96), Offset(x, 104), Paint()
        ..color = const Color(0xFF3A3A3A)
        ..strokeWidth = 2);
      c.drawCircle(Offset(x, 106), 4, Paint()..color = const Color(0xFF3A3A3A));
      for (final a in [0.0, 2.1, 4.2]) {
        final dx = math.cos(a) * 28;
        final dy = math.sin(a) * 4;
        c.drawLine(Offset(x, 106), Offset(x + dx, 106 + dy), Paint()
          ..color = const Color(0xFF4A4A4A)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round);
      }
    }
  }

  void _door(Canvas c, M8Geo g) {
    final d = g.door;
    c.drawRect(d.inflate(3), Paint()..color = const Color(0xFF5E4229));
    c.drawRect(d, Paint()..color = const Color(0xFF8A5A3C));
    c.drawRect(d.deflate(7), Paint()..color = const Color(0x22000000));
    c.drawCircle(Offset(d.left + 8, d.center.dy), 2.6, Paint()..color = const Color(0xFFD9A441));
  }

  void _benchFront(Canvas c, M8Geo g) {
    final b = g.bench;
    // The back panel and a plain banner above the bench.
    final banner = Rect.fromLTWH(b.left + 6, b.top - 6, b.width - 12, 22);
    c.drawRRect(RRect.fromRectAndRadius(banner, const Radius.circular(3)), Paint()..color = const Color(0xFF1C2E4A));
    c.drawRRect(
        RRect.fromRectAndRadius(banner, const Radius.circular(3)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = const Color(0xFFF2D58A));
    _text(c, 'WBERC · জনশুনানি', banner.center, 11.5, const Color(0xFFF2D58A));
    // The bench itself: top and front.
    final top = Rect.fromLTWH(b.left, b.top + 14, b.width, 14);
    c.drawRRect(RRect.fromRectAndRadius(top, const Radius.circular(4)), Paint()..color = const Color(0xFF9A6B45));
    c.drawRect(Rect.fromLTWH(top.left, top.top, top.width, 3), Paint()..color = const Color(0x44FFFFFF));
    final front = Rect.fromLTWH(b.left + 4, top.bottom, b.width - 8, b.bottom - top.bottom);
    c.drawRect(front, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF7B5232), Color(0xFF5E3D24)]).createShader(front));
    c.drawRect(Rect.fromLTWH(front.left + 8, front.top + 5, front.width - 16, front.height - 10), Paint()..color = const Color(0x22000000));
    // A small gavel block.
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(b.right - 34, top.top - 5, 18, 7), const Radius.circular(2)), Paint()..color = const Color(0xFFB98A52));
    // The time inlay's slot.
    c.drawRRect(RRect.fromRectAndRadius(g.timeBar.inflate(2), const Radius.circular(4)), Paint()..color = const Color(0xFF2F1E10));
  }

  void _companyTable(Canvas c, M8Geo g) {
    final t = g.companyTable;
    final top = Rect.fromLTWH(t.left, t.top + 16, t.width, 12);
    c.drawRRect(RRect.fromRectAndRadius(top, const Radius.circular(3)), Paint()..color = const Color(0xFF9A6B45));
    final front = Rect.fromLTWH(t.left + 3, top.bottom, t.width - 6, t.bottom - top.bottom);
    c.drawRect(front, Paint()..color = const Color(0xFF6A4630));
    // Files on the table.
    for (var i = 0; i < 3; i++) {
      final f = Rect.fromLTWH(t.left + 6 + i * 12.0, t.top + 4 + (i.isEven ? 2 : 0), 18, 14);
      c.drawRect(f, Paint()..color = [const Color(0xFFE8D9B0), const Color(0xFFC9D8E3), const Color(0xFFE3C9C9)][i]);
      c.drawRect(f, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x66000000));
    }
    // Its own stamp pad (the same size and weight as the bench: always there).
    final p = g.pad;
    c.drawRRect(RRect.fromRectAndRadius(p, const Radius.circular(5)), Paint()..color = const Color(0xFF3A3A3F));
    c.drawRRect(RRect.fromRectAndRadius(p.deflate(4), const Radius.circular(3)), Paint()..color = const Color(0xFF7A2B3A));
    c.drawRRect(
        RRect.fromRectAndRadius(p, const Radius.circular(5)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = const Color(0xFFF2D58A));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(p.left + 12, p.top - 7, 16, 9), const Radius.circular(3)), Paint()..color = const Color(0xFFB98A52));
  }

  void _consumerBench(Canvas c, M8Geo g) {
    final b = g.consumerBench;
    final top = Rect.fromLTWH(b.left, b.top + 12, b.width, 12);
    c.drawRRect(RRect.fromRectAndRadius(top, const Radius.circular(3)), Paint()..color = const Color(0xFF8A6A48));
    final front = Rect.fromLTWH(b.left + 3, top.bottom, b.width - 6, b.bottom - top.bottom);
    c.drawRect(front, Paint()..color = const Color(0xFF6A4E34));
    // A water jug and a cloth bag on the bench.
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(b.left + 10, b.top + 1, 11, 13), const Radius.circular(4)), Paint()..color = const Color(0xFF8CB9C9));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(b.left + 40, b.top + 4, 18, 11), const Radius.circular(4)), Paint()..color = const Color(0xFFB9926A));
  }

  void _text(Canvas c, String text, Offset centre, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.3)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(M8HallPainter old) => old.geo != geo;
}

/// The brass balance: a beam on a pivot, two pans with the weights heard so
/// far (a small side icon each, no verdict), and a free-swinging pointer.
/// [angle] is the beam's tilt in radians (positive = the home pan lower);
/// [pointer] the needle's own swing. No numbers, no mark for 'level'.
class M8BalancePainter extends CustomPainter {
  const M8BalancePainter({required this.angle, required this.pointer, required this.office, required this.home});

  final double angle;
  final double pointer;
  final int office;
  final int home;

  static const double armLen = 70;
  static const double drop = 46;

  @override
  void paint(Canvas c, Size size) {
    final pivot = Offset(size.width / 2, 34);
    // The hanging chain up to the ceiling.
    c.drawLine(Offset(pivot.dx, 0), Offset(pivot.dx, pivot.dy - 6), Paint()
      ..color = const Color(0xFF8A6A2A)
      ..strokeWidth = 3);
    final dx = math.cos(angle) * armLen;
    final dy = math.sin(angle) * armLen;
    final left = pivot + Offset(-dx, -dy);
    final right = pivot + Offset(dx, dy);
    final brass = Paint()
      ..color = const Color(0xFFD9A441)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    c.drawLine(left, right, brass);
    c.drawLine(left, right, Paint()
      ..color = const Color(0x55FFFFFF)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round);
    // The pointer: a needle hanging from the pivot, swinging by itself.
    final tip = pivot + Offset(math.sin(pointer) * 40, math.cos(pointer) * 40);
    c.drawLine(pivot, tip, Paint()
      ..color = const Color(0xFFB02A2A)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round);
    c.drawCircle(pivot, 6, Paint()..color = const Color(0xFFF2D58A));
    c.drawCircle(pivot, 6, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = const Color(0xFF8A6A2A));
    _pan(c, left, office, M8Side.office);
    _pan(c, right, home, M8Side.home);
  }

  void _pan(Canvas c, Offset end, int n, M8Side side) {
    final plate = Offset(end.dx, end.dy + drop);
    final str = Paint()
      ..color = const Color(0xFF8A6A2A)
      ..strokeWidth = 1.4;
    c.drawLine(end, plate + const Offset(-28, 0), str);
    c.drawLine(end, plate + const Offset(28, 0), str);
    // The weights, in rows of five on the plate.
    for (var i = 0; i < n; i++) {
      final row = i ~/ 5;
      final col = i % 5;
      final inRow = math.min(5, n - row * 5);
      final x = plate.dx + (col - (inRow - 1) / 2) * 11.5;
      final y = plate.dy - 6 - row * 11.5;
      _weight(c, Offset(x, y), side);
    }
    final p = Path()
      ..moveTo(plate.dx - 32, plate.dy - 1)
      ..lineTo(plate.dx + 32, plate.dy - 1)
      ..quadraticBezierTo(plate.dx + 26, plate.dy + 12, plate.dx, plate.dy + 12)
      ..quadraticBezierTo(plate.dx - 26, plate.dy + 12, plate.dx - 32, plate.dy - 1)
      ..close();
    c.drawPath(p, Paint()..color = const Color(0xFFD9A441));
    c.drawPath(
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = const Color(0xFF8A6A2A));
    // The pan's own side icon on its rim.
    _icon(c, Offset(plate.dx, plate.dy + 5), 5, side, const Color(0xFF5E4229));
  }

  void _weight(Canvas c, Offset at, M8Side side) {
    c.drawCircle(at, 5.4, Paint()..color = const Color(0xFFF7E3A4));
    c.drawCircle(
        at,
        5.4,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0xFF8A6A2A));
    _icon(c, at, 3.4, side, const Color(0xFF5E4229));
  }

  /// A tiny office (a block with two windows) or home (a roof on a box).
  static void _icon(Canvas c, Offset at, double r, M8Side side, Color color) {
    final p = Paint()..color = color;
    if (side == M8Side.home) {
      final roof = Path()
        ..moveTo(at.dx - r, at.dy - r * 0.1)
        ..lineTo(at.dx, at.dy - r)
        ..lineTo(at.dx + r, at.dy - r * 0.1)
        ..close();
      c.drawPath(roof, p);
      c.drawRect(Rect.fromLTRB(at.dx - r * 0.7, at.dy - r * 0.1, at.dx + r * 0.7, at.dy + r * 0.9), p);
    } else {
      c.drawRect(Rect.fromLTRB(at.dx - r * 0.8, at.dy - r, at.dx + r * 0.8, at.dy + r * 0.9), p);
      final w = Paint()..color = const Color(0xFFF7E3A4);
      c.drawRect(Rect.fromCenter(center: Offset(at.dx - r * 0.3, at.dy - r * 0.35), width: r * 0.35, height: r * 0.35), w);
      c.drawRect(Rect.fromCenter(center: Offset(at.dx + r * 0.3, at.dy - r * 0.35), width: r * 0.35, height: r * 0.35), w);
    }
  }

  @override
  bool shouldRepaint(M8BalancePainter old) => old.angle != angle || old.pointer != pointer || old.office != office || old.home != home;
}

/// A person (design 36 × 56): seated behind a bench rail, one hand raised,
/// speaking, or standing. [faceLeft] mirrors him.
class M8PersonPainter extends CustomPainter {
  const M8PersonPainter({required this.look, required this.pose, this.faceLeft = false, this.holding = false});

  final M8Look look;
  final M8Pose pose;
  final bool faceLeft;

  /// A paper in the hand (the file, the sheet, the order).
  final bool holding;

  @override
  void paint(Canvas c, Size size) {
    final s = math.min(size.width / 36, size.height / 56);
    c.translate((size.width - 36 * s) / 2, size.height - 56 * s);
    c.scale(s);
    if (faceLeft) {
      c.translate(36, 0);
      c.scale(-1, 1);
    }
    final seated = pose == M8Pose.seated || pose == M8Pose.raised || pose == M8Pose.speaking;
    // Shadow.
    c.drawOval(const Rect.fromLTWH(3, 52, 30, 5), Paint()..color = const Color(0x33000000));
    // Legs (standing or walking).
    if (!seated) {
      final shift = pose == M8Pose.walking ? 3.0 : 0.0;
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(10 - shift, 36, 7, 17), const Radius.circular(3)), Paint()..color = const Color(0xFF3B4252));
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(19 + shift, 36, 7, 17), const Radius.circular(3)), Paint()..color = const Color(0xFF3B4252));
    }
    // Torso.
    final torso = RRect.fromRectAndRadius(const Rect.fromLTWH(7, 22, 22, 20), const Radius.circular(7));
    c.drawRRect(torso, Paint()..color = look.shirt);
    c.drawRRect(
        torso,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0x44000000));
    if (look.tie) {
      c.drawPath(
          Path()
            ..moveTo(18, 23)
            ..lineTo(15.5, 28)
            ..lineTo(18, 38)
            ..lineTo(20.5, 28)
            ..close(),
          Paint()..color = const Color(0xFF8E2F2F));
    }
    if (look.dupatta) {
      final d = Path()
        ..moveTo(7, 24)
        ..quadraticBezierTo(18, 36, 30, 22)
        ..lineTo(31, 40)
        ..lineTo(24, 40)
        ..quadraticBezierTo(18, 32, 12, 40)
        ..close();
      c.drawPath(d, Paint()..color = const Color(0xFFF1E7D0));
    }
    // Head.
    c.drawCircle(const Offset(18, 14), 8.5, Paint()..color = look.skin);
    if (look.cap) {
      c.drawPath(
          Path()
            ..moveTo(9.5, 12)
            ..quadraticBezierTo(18, 0, 26.5, 12)
            ..close(),
          Paint()..color = const Color(0xFFF1F0EA));
    } else {
      c.drawPath(
          Path()
            ..moveTo(9.5, 13)
            ..quadraticBezierTo(18, 1, 26.5, 13)
            ..quadraticBezierTo(18, 8, 9.5, 13)
            ..close(),
          Paint()..color = look.hair);
    }
    final dark = Paint()..color = const Color(0xFF1A1210);
    c.drawCircle(const Offset(14.5, 15), 1.1, dark);
    c.drawCircle(const Offset(21.5, 15), 1.1, dark);
    if (pose == M8Pose.speaking) {
      c.drawOval(const Rect.fromLTWH(15.5, 18.5, 5, 3.6), Paint()..color = const Color(0xFF5A2A22));
    } else {
      c.drawLine(const Offset(15.5, 20), const Offset(20.5, 20), Paint()
        ..color = const Color(0xFF2A1C14)
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round);
    }
    // Arms.
    final sleeve = Paint()
      ..color = look.shirt
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final hand = Paint()..color = look.skin;
    if (pose == M8Pose.raised) {
      c.drawLine(const Offset(29, 26), const Offset(32, 10), sleeve);
      c.drawCircle(const Offset(32, 7.5), 3.3, hand);
      c.drawLine(const Offset(7, 28), const Offset(5, 38), sleeve);
    } else if (pose == M8Pose.speaking) {
      c.drawLine(const Offset(29, 26), const Offset(31, 18), sleeve);
      c.drawCircle(const Offset(31, 16), 3, hand);
      c.drawLine(const Offset(7, 28), const Offset(5, 38), sleeve);
    } else {
      c.drawLine(const Offset(7, 28), const Offset(5, 40), sleeve);
      c.drawLine(const Offset(29, 28), const Offset(31, 40), sleeve);
      c.drawCircle(const Offset(5, 41.5), 2.6, hand);
      c.drawCircle(const Offset(31, 41.5), 2.6, hand);
    }
    if (holding) {
      c.drawRect(const Rect.fromLTWH(27, 31, 12, 15), Paint()..color = const Color(0xFFF7F1DE));
      c.drawRect(
          const Rect.fromLTWH(27, 31, 12, 15),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..color = const Color(0xFF8A6A3C));
      for (var i = 0; i < 3; i++) {
        c.drawLine(Offset(29, 35 + i * 3.5), Offset(37, 35 + i * 3.5), Paint()
          ..color = const Color(0x668A6A3C)
          ..strokeWidth = 1);
      }
    }
    // The bench rail hides a seated person's lower half.
    if (seated) {
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(0, 42, 36, 14), const Radius.circular(3)), Paint()..color = const Color(0xFF6A4630));
      c.drawRect(const Rect.fromLTWH(0, 42, 36, 2.5), Paint()..color = const Color(0x44FFFFFF));
    }
  }

  @override
  bool shouldRepaint(M8PersonPainter old) => old.look != look || old.pose != pose || old.faceLeft != faceLeft || old.holding != holding;
}

/// A hand-held microphone icon.
class M8MicPainter extends CustomPainter {
  const M8MicPainter({this.ghost = false});
  final bool ghost;

  @override
  void paint(Canvas c, Size size) {
    final a = ghost ? 0.3 : 1.0;
    final cx = size.width / 2;
    final head = Rect.fromCenter(center: Offset(cx, size.height * 0.32), width: size.width * 0.38, height: size.height * 0.4);
    c.drawRRect(RRect.fromRectAndRadius(head, Radius.circular(size.width * 0.19)), Paint()..color = const Color(0xFF2B2F36).withValues(alpha: a));
    for (var i = 0; i < 3; i++) {
      c.drawLine(Offset(head.left + 3, head.top + 6 + i * 6), Offset(head.right - 3, head.top + 6 + i * 6), Paint()
        ..color = const Color(0xFF8A929C).withValues(alpha: a)
        ..strokeWidth = 1.2);
    }
    c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(cx - 3.5, head.bottom - 2, 7, size.height * 0.4), const Radius.circular(3)), Paint()..color = const Color(0xFFD9A441).withValues(alpha: a));
    c.drawRect(Rect.fromLTWH(cx - 4, size.height * 0.5, 8, 3), Paint()..color = const Color(0xFFB02A2A).withValues(alpha: a));
  }

  @override
  bool shouldRepaint(M8MicPainter old) => old.ghost != ghost;
}
