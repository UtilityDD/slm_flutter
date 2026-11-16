import 'dart:math' as math;

import 'package:flutter/material.dart';

// The drawn world of lesson 7.2 কাজ 1 "কোন খাতে ক্ষতিপূরণ?" (m7_comp_casebook.dart):
// the depot's welfare room by day. A pale wall with a barred window, a cork
// notice board and a slow ceiling fan (still), a floor of grey tiles. The
// filing cabinet, the বাতিল bin, the calendar and the desk with its case
// files are the page's own widgets laid over this room.
//
// The story frame (M7StoryPainter) is the picture a case file lifts: the
// accident day at work, then — one torn calendar page at a time — the
// hospital, the recovery at home and, 'অনেক পরে', how the worker's life
// turned out. The first three pictures depend only on the accident kind (so a
// case that heals and one that loses a finger look alike until the last
// page); only the last picture differs. A death case is one picture: the
// family at the office desk with a garlanded photo.
//
// Code-drawn, gradients, no bitmaps, no text. Design box of a story picture:
// 240 × 150 (scaled to fit, centred).

/// What happened on the accident day (the first picture).
enum M7Accident { poleFall, dtrFlash, comeAlong, drumRoll }

/// How it turned out ('অনেক পরে'; a death case shows only its family).
enum M7Outcome { backOnPole, backOnLine, fingerCounter, eyeDesk, handCounter, homeChair, homeBed, familyWife, familyParents }

/// The four story stages (a death case has only [later]).
enum M7Stage { accident, hospital, recovering, later }

const _ink = Color(0xFF2B2111);
const _skin = Color(0xFFC98E62);
const _skinDark = Color(0xFFA9714A);
const _hair = Color(0xFF231A14);
const _helmet = Color(0xFFF2C230);
const _khaki = Color(0xFF6E7F57);
const _bandage = Color(0xFFF4F1EA);

/// The welfare room behind the page's widgets (static: draws once).
class M7RoomPainter extends CustomPainter {
  const M7RoomPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final floorY = h * 0.70;
    // The wall.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, floorY),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFCFE0D2), Color(0xFFB7CDBB)],
        ).createShader(Rect.fromLTWH(0, 0, w, floorY)),
    );
    // A dado band.
    canvas.drawRect(Rect.fromLTWH(0, floorY - h * 0.16, w, h * 0.16), Paint()..color = const Color(0xFF9DB7A2));
    canvas.drawRect(Rect.fromLTWH(0, floorY - h * 0.16, w, 3), Paint()..color = const Color(0xFF7E9A84));
    // The floor.
    final floor = Rect.fromLTWH(0, floorY, w, h - floorY);
    canvas.drawRect(
      floor,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8E9296), Color(0xFF6C7074)],
        ).createShader(floor),
    );
    final grout = Paint()
      ..color = const Color(0x33000000)
      ..strokeWidth = 1;
    for (var y = floorY + 24.0; y < h; y += 34) {
      canvas.drawLine(Offset(0, y), Offset(w, y), grout);
    }
    for (var x = 0.0; x < w; x += 48) {
      canvas.drawLine(Offset(x, floorY), Offset(x - 30, h), grout);
    }
    canvas.drawRect(Rect.fromLTWH(0, floorY - 4, w, 5), Paint()..color = const Color(0xFF5E6B5F));
    // The window (top right, under the header shade).
    final win = Rect.fromLTWH(w * 0.62, h * 0.05, w * 0.32, h * 0.12);
    canvas.drawRRect(RRect.fromRectAndRadius(win.inflate(5), const Radius.circular(4)), Paint()..color = const Color(0xFF7A5A36));
    canvas.drawRect(
      win,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF9ED4F2), Color(0xFFD9F0FA)],
        ).createShader(win),
    );
    final bar = Paint()
      ..color = const Color(0xFF4B4F55)
      ..strokeWidth = 2;
    for (var i = 1; i < 6; i++) {
      final x = win.left + win.width * i / 6;
      canvas.drawLine(Offset(x, win.top), Offset(x, win.bottom), bar);
    }
    // A notice board (top left).
    final board = Rect.fromLTWH(w * 0.05, h * 0.06, w * 0.26, h * 0.10);
    canvas.drawRRect(RRect.fromRectAndRadius(board.inflate(4), const Radius.circular(3)), Paint()..color = const Color(0xFF6B4A2B));
    canvas.drawRect(board, Paint()..color = const Color(0xFFC8A06A));
    final notes = [const Color(0xFFFFFDF2), const Color(0xFFFFF0B8), const Color(0xFFE6F2FF)];
    for (var i = 0; i < 3; i++) {
      final r = Rect.fromLTWH(board.left + 6 + i * board.width / 3.2, board.top + 6 + (i.isOdd ? 6 : 0), board.width / 4, board.height * 0.62);
      canvas.drawRect(r, Paint()..color = notes[i]);
      canvas.drawCircle(Offset(r.center.dx, r.top + 3), 2.4, Paint()..color = const Color(0xFFC0392B));
      final line = Paint()
        ..color = const Color(0x55000000)
        ..strokeWidth = 1;
      for (var k = 0; k < 3; k++) {
        canvas.drawLine(Offset(r.left + 3, r.top + 9 + k * 5), Offset(r.right - 3, r.top + 9 + k * 5), line);
      }
    }
  }

  @override
  bool shouldRepaint(M7RoomPainter old) => false;
}

/// One story picture of a case.
class M7StoryPainter extends CustomPainter {
  const M7StoryPainter({required this.accident, required this.stage, required this.outcome, required this.ownFault});

  /// Null for a death case (only its family is drawn).
  final M7Accident? accident;
  final M7Stage stage;
  final M7Outcome outcome;

  /// The worker's own lapse shows on the accident day: plain hurry or
  /// carelessness — a foot slipped, a spanner slipped from his hand, a rope
  /// slipped — with every PPE item on and every safety device in use (the
  /// lanyard clipped, গ্লাভস on). Never a skipped safety device or rule.
  final bool ownFault;

  static const box = Size(240, 150);

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width / box.width, size.height / box.height);
    canvas.save();
    canvas.translate((size.width - box.width * s) / 2, (size.height - box.height * s) / 2);
    canvas.scale(s);
    canvas.clipRect(Offset.zero & box);
    final a = accident;
    if (a == null || stage == M7Stage.later) {
      _outcome(canvas, outcome);
    } else {
      switch (stage) {
        case M7Stage.accident:
          _accident(canvas, a);
        case M7Stage.hospital:
          _hospital(canvas, a);
        case M7Stage.recovering:
          _recovering(canvas, a);
        case M7Stage.later:
          break;
      }
    }
    canvas.restore();
  }

  // --- backdrops ---------------------------------------------------------------
  void _outdoor(Canvas c) {
    const sky = Rect.fromLTWH(0, 0, 240, 150);
    c.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8CC8EE), Color(0xFFD8EEF8)],
        ).createShader(sky),
    );
    c.drawRect(const Rect.fromLTWH(0, 122, 240, 28), Paint()..color = const Color(0xFF7DA35A));
    c.drawRect(const Rect.fromLTWH(0, 122, 240, 3), Paint()..color = const Color(0xFF5E8442));
  }

  void _indoor(Canvas c, Color wall) {
    c.drawRect(const Rect.fromLTWH(0, 0, 240, 150), Paint()..color = wall);
    c.drawRect(const Rect.fromLTWH(0, 118, 240, 32), Paint()..color = const Color(0xFF9A8F80));
    c.drawRect(const Rect.fromLTWH(0, 118, 240, 2), Paint()..color = const Color(0xFF6F665A));
  }

  void _window(Canvas c, Rect r) {
    c.drawRect(r.inflate(3), Paint()..color = const Color(0xFF7A5A36));
    c.drawRect(r, Paint()..color = const Color(0xFFBFE4F6));
    final p = Paint()
      ..color = const Color(0xFF7A5A36)
      ..strokeWidth = 2;
    c.drawLine(Offset(r.center.dx, r.top), Offset(r.center.dx, r.bottom), p);
    c.drawLine(Offset(r.left, r.center.dy), Offset(r.right, r.center.dy), p);
  }

  void _pole(Canvas c, double x) {
    c.drawRect(Rect.fromLTWH(x - 4, 10, 8, 114), Paint()..color = const Color(0xFF8A8F96));
    c.drawRect(Rect.fromLTWH(x - 26, 22, 52, 5), Paint()..color = const Color(0xFF5E6268));
    for (final dx in [-22.0, 0.0, 22.0]) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x + dx - 3, 13, 6, 10), const Radius.circular(2)), Paint()..color = const Color(0xFF8B5A3C));
    }
    final wire = Paint()
      ..color = const Color(0xFF333333)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (final dx in [-22.0, 0.0, 22.0]) {
      c.drawLine(Offset(0, 16), Offset(x + dx, 13), wire);
      c.drawLine(Offset(x + dx, 13), Offset(240, 16), wire);
    }
  }

  // --- people -------------------------------------------------------------------
  /// A standing worker (feet at [feet]); [arm] raises the near arm.
  void _worker(
    Canvas c,
    Offset feet, {
    double scale = 1,
    Color shirt = _khaki,
    bool helmet = true,
    bool gloves = true,
    bool eyePatch = false,
    bool stump = false,
    double arm = 0.3,
    double tilt = 0,
    bool sling = false,
  }) {
    c.save();
    c.translate(feet.dx, feet.dy);
    c.rotate(tilt);
    c.scale(scale);
    final leg = Paint()
      ..color = const Color(0xFF3A4A5C)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    c.drawLine(const Offset(-4, 0), const Offset(-3, -22), leg);
    c.drawLine(const Offset(4, 0), const Offset(3, -22), leg);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-9, -46, 18, 26), const Radius.circular(5)), Paint()..color = shirt);
    final armP = Paint()
      ..color = shirt
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    // Far arm (down).
    c.drawLine(const Offset(-8, -42), const Offset(-11, -24), armP);
    c.drawCircle(const Offset(-11, -23), 2.8, Paint()..color = gloves ? const Color(0xFF2E2E2E) : _skin);
    // Near arm.
    if (sling) {
      c.drawLine(const Offset(8, -42), const Offset(6, -30), armP);
      c.drawLine(const Offset(6, -30), const Offset(-4, -32), armP);
      c.drawLine(const Offset(9, -44), const Offset(-6, -30), Paint()
        ..color = _bandage
        ..strokeWidth = 3);
    } else {
      final end = Offset(8 + 14 * math.cos(-math.pi / 2 + arm * math.pi), -42 + 14 * math.sin(-math.pi / 2 + arm * math.pi) * -1);
      c.drawLine(const Offset(8, -42), end, armP);
      if (stump) {
        c.drawCircle(end, 3.2, Paint()..color = _bandage);
      } else {
        c.drawCircle(end, 2.8, Paint()..color = gloves ? const Color(0xFF2E2E2E) : _skin);
      }
    }
    // Head.
    c.drawCircle(const Offset(0, -53), 7.5, Paint()..color = _skin);
    if (helmet) {
      c.drawArc(Rect.fromCircle(center: const Offset(0, -54), radius: 8.5), math.pi, math.pi, true, Paint()..color = _helmet);
      c.drawRect(const Rect.fromLTWH(-10, -55, 20, 2), Paint()..color = const Color(0xFFD9A81E));
    } else {
      c.drawArc(Rect.fromCircle(center: const Offset(0, -55), radius: 7.6), math.pi, math.pi, true, Paint()..color = _hair);
    }
    c.drawCircle(const Offset(3, -53), 1, Paint()..color = _ink);
    if (eyePatch) {
      c.drawCircle(const Offset(-2.5, -53), 2.4, Paint()..color = const Color(0xFF1B1B1B));
      c.drawLine(const Offset(-7, -57), const Offset(7, -50), Paint()
        ..color = const Color(0xFF1B1B1B)
        ..strokeWidth = 0.8);
    } else {
      c.drawCircle(const Offset(-2.5, -53), 1, Paint()..color = _ink);
    }
    c.restore();
  }

  /// A seated person on a chair (seat at [seat]).
  void _seated(Canvas c, Offset seat, {Color shirt = const Color(0xFF8C6E5A), bool sling = false, bool crutch = false, bool wheelchair = false, bool sad = false}) {
    if (wheelchair) {
      final wh = Paint()
        ..color = const Color(0xFF4A5560)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      c.drawCircle(seat + const Offset(-4, 14), 14, wh);
      c.drawLine(seat + const Offset(-14, 0), seat + const Offset(12, 0), wh);
      c.drawLine(seat + const Offset(-14, 0), seat + const Offset(-16, -24), wh);
    } else {
      final chair = Paint()..color = const Color(0xFF7A5A36);
      c.drawRect(Rect.fromLTWH(seat.dx - 14, seat.dy - 2, 28, 4), chair);
      c.drawRect(Rect.fromLTWH(seat.dx - 14, seat.dy, 3, 22), chair);
      c.drawRect(Rect.fromLTWH(seat.dx + 11, seat.dy, 3, 22), chair);
      c.drawRect(Rect.fromLTWH(seat.dx - 14, seat.dy - 28, 3, 28), chair);
    }
    final leg = Paint()
      ..color = const Color(0xFF3A4A5C)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    c.drawLine(seat + const Offset(-4, -2), seat + const Offset(10, -2), leg);
    c.drawLine(seat + const Offset(10, -2), seat + const Offset(11, 18), leg);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(seat.dx - 10, seat.dy - 28, 17, 26), const Radius.circular(5)), Paint()..color = shirt);
    final armP = Paint()
      ..color = shirt
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    if (sling) {
      c.drawLine(seat + const Offset(4, -24), seat + const Offset(6, -12), armP);
      c.drawLine(seat + const Offset(6, -12), seat + const Offset(-4, -14), armP);
      c.drawLine(seat + const Offset(6, -26), seat + const Offset(-6, -12), Paint()
        ..color = _bandage
        ..strokeWidth = 3);
    } else {
      c.drawLine(seat + const Offset(4, -24), seat + const Offset(10, -10), armP);
      c.drawCircle(seat + const Offset(10, -9), 2.6, Paint()..color = _skin);
    }
    c.drawCircle(seat + const Offset(-1, -35), 7.2, Paint()..color = _skin);
    c.drawArc(Rect.fromCircle(center: seat + const Offset(-1, -37), radius: 7.3), math.pi, math.pi, true, Paint()..color = _hair);
    final mouth = Paint()
      ..color = _ink
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    c.drawArc(Rect.fromCenter(center: seat + Offset(1, sad ? -29.5 : -31.5), width: 5, height: 3), sad ? math.pi : 0, math.pi, false, mouth);
    if (crutch) {
      c.drawLine(seat + const Offset(18, 20), seat + const Offset(14, -26), Paint()
        ..color = const Color(0xFF9A9FA5)
        ..strokeWidth = 2.4);
    }
  }

  /// A person lying in a bed (bed top-left at [at]).
  void _inBed(Canvas c, Offset at, {required M7Accident? a, bool hospital = true}) {
    final frame = Paint()..color = hospital ? const Color(0xFFB8C2CC) : const Color(0xFF7A5A36);
    c.drawRect(Rect.fromLTWH(at.dx, at.dy + 16, 120, 8), frame);
    c.drawRect(Rect.fromLTWH(at.dx, at.dy - 8, 5, 46), frame);
    c.drawRect(Rect.fromLTWH(at.dx + 115, at.dy + 4, 5, 34), frame);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(at.dx + 4, at.dy + 6, 112, 12), const Radius.circular(4)), Paint()..color = const Color(0xFFF7F7F2));
    // Blanket over the body.
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(at.dx + 30, at.dy - 2, 84, 14), const Radius.circular(6)),
      Paint()..color = hospital ? const Color(0xFF8FB3D9) : const Color(0xFFC77D5B),
    );
    // Head on the pillow.
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(at.dx + 6, at.dy - 2, 22, 10), const Radius.circular(4)), Paint()..color = Colors.white);
    c.drawCircle(Offset(at.dx + 20, at.dy - 4), 7, Paint()..color = _skin);
    if (a == M7Accident.dtrFlash) {
      c.drawArc(Rect.fromCircle(center: Offset(at.dx + 20, at.dy - 5), radius: 7.4), math.pi * 0.9, math.pi * 1.2, false, Paint()
        ..color = _bandage
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3);
    } else {
      c.drawArc(Rect.fromCircle(center: Offset(at.dx + 20, at.dy - 6), radius: 7), math.pi, math.pi, true, Paint()..color = _hair);
    }
    // The hurt part.
    switch (a) {
      case M7Accident.poleFall:
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(at.dx + 96, at.dy - 6, 30, 10), const Radius.circular(4)), Paint()..color = _bandage);
      case M7Accident.comeAlong || M7Accident.drumRoll || M7Accident.dtrFlash:
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(at.dx + 40, at.dy - 8, 22, 8), const Radius.circular(4)), Paint()..color = _bandage);
      case null:
        break;
    }
  }

  // --- stage 0: the accident day -------------------------------------------------
  void _star(Canvas c, Offset at, double r, Color color) {
    final p = Path();
    for (var i = 0; i < 16; i++) {
      final rr = i.isEven ? r : r * 0.45;
      final a = i * math.pi / 8;
      final pt = at + Offset(rr * math.cos(a), rr * math.sin(a));
      if (i == 0) {
        p.moveTo(pt.dx, pt.dy);
      } else {
        p.lineTo(pt.dx, pt.dy);
      }
    }
    p.close();
    c.drawPath(p, Paint()..color = color);
  }

  void _accident(Canvas c, M7Accident a) {
    switch (a) {
      case M7Accident.poleFall:
        _outdoor(c);
        _pole(c, 150);
        // The step-bolts up the pole.
        final bolt = Paint()
          ..color = const Color(0xFF5E6268)
          ..strokeWidth = 2.4
          ..strokeCap = StrokeCap.round;
        for (var k = 0; k < 4; k++) {
          final y = 48.0 + k * 18;
          final side = k.isEven ? -1.0 : 1.0;
          c.drawLine(Offset(150 + 4 * side, y), Offset(150 + 11 * side, y), bolt);
        }
        // The full-body harness lanyard, clipped round the pole (always: the
        // own-fault lapse is never a skipped safety device).
        final lanyard = Paint()
          ..color = const Color(0xFFE67E22)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        c.drawLine(const Offset(124, 74), const Offset(146, 60), lanyard);
        c.drawLine(const Offset(146, 60), const Offset(150, 52), Paint()
          ..color = const Color(0xFF7A3E12)
          ..strokeWidth = 3);
        if (ownFault) {
          // In a hurry his foot slipped off a step-bolt: a skid streak at the
          // bolt and a little slip star.
          c.drawLine(const Offset(139, 84), const Offset(131, 94), Paint()
            ..color = const Color(0xCCFFFFFF)
            ..strokeWidth = 2.2
            ..strokeCap = StrokeCap.round);
          _star(c, const Offset(140, 84), 6, const Color(0xFFFFE066));
        }
        _worker(c, const Offset(122, 98), tilt: -0.9, arm: 0.85);
        final motion = Paint()
          ..color = const Color(0x99FFFFFF)
          ..strokeWidth = 2;
        for (var i = 0; i < 3; i++) {
          c.drawLine(Offset(98 + i * 8, 40.0 + i * 4), Offset(98 + i * 8, 58.0 + i * 4), motion);
        }
      case M7Accident.dtrFlash:
        _outdoor(c);
        // The DTR on its plinth: tank, fins, three bushings.
        c.drawRect(const Rect.fromLTWH(128, 112, 80, 12), Paint()..color = const Color(0xFF9E9E9E));
        c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(138, 62, 60, 50), const Radius.circular(4)), Paint()..color = const Color(0xFF5F7F6C));
        for (var i = 0; i < 5; i++) {
          c.drawRect(Rect.fromLTWH(140 + i * 12.0, 66, 5, 42), Paint()..color = const Color(0xFF4E6B59));
        }
        for (final x in [148.0, 168.0, 188.0]) {
          c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 3, 46, 6, 16), const Radius.circular(2)), Paint()..color = const Color(0xFF8B5A3C));
        }
        _star(c, const Offset(150, 56), 18, const Color(0xFFFFE066));
        _star(c, const Offset(150, 56), 9, Colors.white);
        if (ownFault) {
          // In a hurry the spanner slipped from his gloved hand into the
          // bushings (a falling spanner and its motion marks).
          c.save();
          c.translate(136, 66);
          c.rotate(0.7);
          final steel = Paint()..color = const Color(0xFF9AA3AB);
          c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-2, -11, 4, 22), const Radius.circular(1.5)), steel);
          c.drawCircle(const Offset(0, -12), 4, steel);
          c.drawCircle(const Offset(0, -12), 1.8, Paint()..color = const Color(0xFF5F7F6C));
          c.restore();
          final motion = Paint()
            ..color = const Color(0x99FFFFFF)
            ..strokeWidth = 1.6;
          for (var i = 0; i < 3; i++) {
            c.drawLine(Offset(122 + i * 5.0, 48), Offset(126 + i * 5.0, 58), motion);
          }
        }
        // Gloves on whether or not it was his own lapse.
        _worker(c, const Offset(112, 122), tilt: -0.25, arm: 0.95);
      case M7Accident.comeAlong:
        _outdoor(c);
        // The conductor and the come-along (grip, ratchet, handle).
        final wire = Paint()
          ..color = const Color(0xFF555555)
          ..strokeWidth = 2;
        c.drawLine(const Offset(0, 62), const Offset(240, 70), wire);
        c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(120, 58, 26, 10), const Radius.circular(3)), Paint()..color = const Color(0xFF8A8F96));
        c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(146, 62, 18, 14), const Radius.circular(3)), Paint()..color = const Color(0xFFB0412E));
        c.drawLine(const Offset(158, 72), const Offset(176, 98), Paint()
          ..color = const Color(0xFFB0412E)
          ..strokeWidth = 4);
        _worker(c, const Offset(118, 122), arm: 0.12);
        _star(c, Offset(ownFault ? 128 : 140, ownFault ? 63 : 70), 9, const Color(0xFFE74C3C));
      case M7Accident.drumRoll:
        _outdoor(c);
        // A truck bed, a ramp, a cable drum rolling down onto the worker.
        c.drawRect(const Rect.fromLTWH(170, 80, 70, 12), Paint()..color = const Color(0xFF3D5A80));
        c.drawRect(const Rect.fromLTWH(170, 92, 70, 20), Paint()..color = const Color(0xFF2C4260));
        c.drawLine(const Offset(170, 82), const Offset(120, 122), Paint()
          ..color = const Color(0xFF6F5B3E)
          ..strokeWidth = 4);
        if (!ownFault) {
          // A wedge that split.
          c.drawPath(
              Path()
                ..moveTo(116, 122)
                ..lineTo(126, 122)
                ..lineTo(118, 114)
                ..close(),
              Paint()..color = const Color(0xFF8B5A3C));
        } else {
          // Not thinking, he let the lowering rope slip from his hands: the
          // rope runs slack from the drum to the ground by his feet.
          c.drawPath(
              Path()
                ..moveTo(140, 78)
                ..quadraticBezierTo(124, 70, 112, 92)
                ..quadraticBezierTo(104, 108, 92, 120),
              Paint()
                ..color = const Color(0xFFC9A66B)
                ..strokeWidth = 2.2
                ..style = PaintingStyle.stroke);
        }
        final drum = Paint()..color = const Color(0xFF9C6B3A);
        c.drawCircle(const Offset(140, 96), 20, drum);
        c.drawCircle(const Offset(140, 96), 20, Paint()
          ..color = const Color(0xFF6D4A25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
        c.drawCircle(const Offset(140, 96), 9, Paint()..color = const Color(0xFF333333));
        for (var i = 0; i < 4; i++) {
          final an = i * math.pi / 4;
          c.drawLine(Offset(140 + 20 * math.cos(an), 96 + 20 * math.sin(an)), Offset(140 - 20 * math.cos(an), 96 - 20 * math.sin(an)), Paint()
            ..color = const Color(0xFF6D4A25)
            ..strokeWidth = 1.5);
        }
        _worker(c, const Offset(104, 122), tilt: -0.15, arm: 0.6);
        _star(c, const Offset(118, 118), 8, const Color(0xFFE74C3C));
    }
  }

  // --- stage 1: weeks later — in hospital ---------------------------------------
  void _hospital(Canvas c, M7Accident a) {
    _indoor(c, const Color(0xFFE7EEF2));
    _window(c, const Rect.fromLTWH(170, 18, 50, 36));
    // A drip stand.
    c.drawLine(const Offset(160, 40), const Offset(160, 118), Paint()
      ..color = const Color(0xFF8A9199)
      ..strokeWidth = 2);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(154, 36, 12, 18), const Radius.circular(3)), Paint()..color = const Color(0xCCBDE3F5));
    c.drawLine(const Offset(160, 54), const Offset(110, 84), Paint()
      ..color = const Color(0x998A9199)
      ..strokeWidth = 1);
    _inBed(c, const Offset(30, 84), a: a);
  }

  // --- stage 2: months later — getting well at home -----------------------------
  void _recovering(Canvas c, M7Accident a) {
    _indoor(c, const Color(0xFFF1E3C8));
    _window(c, const Rect.fromLTWH(30, 22, 54, 40));
    // A calendar-free wall: a framed picture and a shelf.
    c.drawRect(const Rect.fromLTWH(170, 30, 40, 28), Paint()..color = const Color(0xFF7A5A36));
    c.drawRect(const Rect.fromLTWH(173, 33, 34, 22), Paint()..color = const Color(0xFF9FC27A));
    _seated(c, const Offset(124, 98), sling: a != M7Accident.poleFall, crutch: a == M7Accident.poleFall);
  }

  // --- stage 3: much later — how it turned out ----------------------------------
  void _counter(Canvas c) {
    _indoor(c, const Color(0xFFE6DCC8));
    // Shelves with boxes.
    for (var row = 0; row < 3; row++) {
      final y = 20.0 + row * 26;
      c.drawRect(Rect.fromLTWH(120, y + 18, 110, 3), Paint()..color = const Color(0xFF7A5A36));
      for (var k = 0; k < 4; k++) {
        c.drawRect(Rect.fromLTWH(124 + k * 26.0, y + 2, 20, 16), Paint()..color = [const Color(0xFFB98B55), const Color(0xFF8FA6B8), const Color(0xFFC9A26A), const Color(0xFF9DB08A)][(k + row) % 4]);
      }
    }
  }

  void _deskFront(Canvas c, {bool register = true}) {
    c.drawRect(const Rect.fromLTWH(20, 96, 200, 8), Paint()..color = const Color(0xFF8B5E34));
    c.drawRect(const Rect.fromLTWH(26, 104, 188, 20), Paint()..color = const Color(0xFF6F4A28));
    if (register) {
      c.drawRect(const Rect.fromLTWH(58, 90, 34, 7), Paint()..color = const Color(0xFFF3EDDD));
      c.drawRect(const Rect.fromLTWH(74, 90, 2, 7), Paint()..color = const Color(0xFF9C8256));
    }
  }

  void _garlandPhoto(Canvas c, Offset centre) {
    final frame = Rect.fromCenter(center: centre, width: 30, height: 36);
    c.drawRect(frame.inflate(2), Paint()..color = const Color(0xFF3B2A1A));
    c.drawRect(frame, Paint()..color = const Color(0xFFD9D2C0));
    c.drawCircle(centre + const Offset(0, -4), 7, Paint()..color = const Color(0xFF8C8577));
    c.drawRect(Rect.fromCenter(center: centre + const Offset(0, 10), width: 16, height: 10), Paint()..color = const Color(0xFF8C8577));
    // The marigold garland.
    for (var i = 0; i <= 10; i++) {
      final t = i / 10;
      final p = Offset(frame.left + frame.width * t, frame.top + 8 + math.sin(t * math.pi) * 26);
      c.drawCircle(p, 3.2, Paint()..color = i.isEven ? const Color(0xFFF39C12) : const Color(0xFFE67E22));
    }
  }

  void _outcome(Canvas c, M7Outcome o) {
    switch (o) {
      case M7Outcome.backOnPole:
        _outdoor(c);
        _pole(c, 150);
        _worker(c, const Offset(140, 86), arm: 0.75);
        c.drawLine(const Offset(144, 50), const Offset(150, 46), Paint()
          ..color = const Color(0xFFE67E22)
          ..strokeWidth = 2);
        c.drawCircle(const Offset(36, 30), 12, Paint()..color = const Color(0xFFFFE08A));
      case M7Outcome.backOnLine:
        _outdoor(c);
        _pole(c, 196);
        // A ladder on the pole and the worker at its foot, ready.
        final lad = Paint()
          ..color = const Color(0xFFB08A4A)
          ..strokeWidth = 2.4;
        c.drawLine(const Offset(170, 122), const Offset(190, 40), lad);
        c.drawLine(const Offset(180, 122), const Offset(198, 44), lad);
        for (var i = 1; i < 7; i++) {
          final t = i / 7;
          c.drawLine(Offset(170 + 20 * t, 122 - 82 * t), Offset(180 + 18 * t, 122 - 78 * t), lad);
        }
        _worker(c, const Offset(140, 122), arm: 0.7);
        c.drawCircle(const Offset(36, 30), 12, Paint()..color = const Color(0xFFFFE08A));
      case M7Outcome.fingerCounter:
        _counter(c);
        _worker(c, const Offset(70, 112), helmet: false, gloves: false, shirt: const Color(0xFF5D7FA3), arm: 0.55);
        _deskFront(c);
        _handInset(c, missing: true);
      case M7Outcome.eyeDesk:
        _indoor(c, const Color(0xFFDDE5D5));
        _window(c, const Rect.fromLTWH(170, 20, 50, 34));
        c.drawRect(const Rect.fromLTWH(20, 30, 44, 50), Paint()..color = const Color(0xFF8C9AA6));
        for (var i = 0; i < 3; i++) {
          c.drawRect(Rect.fromLTWH(22, 34 + i * 15.0, 40, 12), Paint()..color = const Color(0xFFA6B3BE));
        }
        _worker(c, const Offset(110, 112), helmet: false, gloves: false, shirt: const Color(0xFF7A8C5E), eyePatch: true, arm: 0.5);
        _deskFront(c);
      case M7Outcome.handCounter:
        _counter(c);
        _worker(c, const Offset(70, 112), helmet: false, gloves: false, shirt: const Color(0xFF8E6C9E), stump: true, arm: 0.4);
        _deskFront(c);
      case M7Outcome.homeChair:
        _indoor(c, const Color(0xFFEFDCC0));
        _window(c, const Rect.fromLTWH(30, 22, 54, 40));
        // His helmet hangs on the wall, unused.
        c.drawArc(Rect.fromCircle(center: const Offset(196, 44), radius: 10), math.pi, math.pi, true, Paint()..color = const Color(0xFFBFA14A));
        c.drawLine(const Offset(196, 26), const Offset(196, 34), Paint()
          ..color = const Color(0xFF6F665A)
          ..strokeWidth = 1);
        _seated(c, const Offset(130, 96), wheelchair: true, sad: true);
      case M7Outcome.homeBed:
        _indoor(c, const Color(0xFFEFDCC0));
        _window(c, const Rect.fromLTWH(160, 20, 54, 40));
        _inBed(c, const Offset(24, 82), a: null, hospital: false);
        // His wife beside him.
        _woman(c, const Offset(176, 118));
      case M7Outcome.familyWife:
        _indoor(c, const Color(0xFFE2E6EA));
        _garlandPhoto(c, const Offset(120, 40));
        _woman(c, const Offset(150, 112));
        _child(c, const Offset(176, 114));
        _deskFront(c);
      case M7Outcome.familyParents:
        _indoor(c, const Color(0xFFE2E6EA));
        _garlandPhoto(c, const Offset(120, 40));
        _oldMan(c, const Offset(150, 112));
        _woman(c, const Offset(182, 112), grey: true);
        _deskFront(c);
    }
  }

  void _handInset(Canvas c, {required bool missing}) {
    const centre = Offset(196, 34);
    c.drawCircle(centre, 24, Paint()..color = Colors.white);
    c.drawCircle(centre, 24, Paint()
      ..color = const Color(0xFF7A5A36)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: centre + const Offset(0, 8), width: 18, height: 16), const Radius.circular(5)), Paint()..color = _skin);
    final finger = Paint()
      ..color = _skin
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 4; i++) {
      final x = centre.dx - 6.5 + i * 4.3;
      final len = (missing && i == 1) ? 2.0 : (i == 0 || i == 3 ? 9.0 : 12.0);
      c.drawLine(Offset(x, centre.dy + 1), Offset(x, centre.dy + 1 - len), finger);
    }
    c.drawLine(centre + const Offset(9, 10), centre + const Offset(15, 3), finger);
    if (missing) c.drawCircle(Offset(centre.dx - 2.2, centre.dy - 1), 2, Paint()..color = _skinDark);
  }

  void _woman(Canvas c, Offset feet, {bool grey = false}) {
    // A sari (a long bell) and the end over the shoulder.
    final sari = Path()
      ..moveTo(feet.dx - 12, feet.dy)
      ..lineTo(feet.dx + 12, feet.dy)
      ..lineTo(feet.dx + 7, feet.dy - 40)
      ..lineTo(feet.dx - 7, feet.dy - 40)
      ..close();
    c.drawPath(sari, Paint()..color = grey ? const Color(0xFFE8E4DA) : const Color(0xFFB24A5A));
    c.drawLine(feet + const Offset(-6, -40), feet + const Offset(8, -14), Paint()
      ..color = grey ? const Color(0xFFBFB8A8) : const Color(0xFF7E2C3B)
      ..strokeWidth = 3);
    c.drawCircle(feet + const Offset(0, -47), 7, Paint()..color = _skin);
    c.drawArc(Rect.fromCircle(center: feet + const Offset(0, -48), radius: 7.6), math.pi * 0.9, math.pi * 1.2, true, Paint()..color = grey ? const Color(0xFFBDBDBD) : _hair);
  }

  void _child(Canvas c, Offset feet) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(feet.dx - 6, feet.dy - 24, 12, 18), const Radius.circular(4)), Paint()..color = const Color(0xFF4F86C6));
    final leg = Paint()
      ..color = const Color(0xFF3A4A5C)
      ..strokeWidth = 4;
    c.drawLine(feet + const Offset(-3, -6), feet + const Offset(-3, 0), leg);
    c.drawLine(feet + const Offset(3, -6), feet + const Offset(3, 0), leg);
    c.drawCircle(feet + const Offset(0, -30), 5.5, Paint()..color = _skin);
    c.drawArc(Rect.fromCircle(center: feet + const Offset(0, -31), radius: 5.8), math.pi, math.pi, true, Paint()..color = _hair);
  }

  void _oldMan(Canvas c, Offset feet) {
    _worker(c, feet, helmet: false, gloves: false, shirt: const Color(0xFFEDEBE4), arm: 0.15);
    c.drawArc(Rect.fromCircle(center: feet + const Offset(0, -55), radius: 7.6), math.pi, math.pi, true, Paint()..color = const Color(0xFFCFCFCF));
  }

  @override
  bool shouldRepaint(M7StoryPainter old) => old.accident != accident || old.stage != stage || old.outcome != outcome || old.ownFault != ownFault;
}

/// The photo clipped to a case file: a head and shoulders.
class M7PortraitPainter extends CustomPainter {
  const M7PortraitPainter(this.seed);
  final int seed;

  static const _shirts = [Color(0xFF6E7F57), Color(0xFF5D7FA3), Color(0xFF8E6C9E), Color(0xFFB0683A), Color(0xFF4F7F7A), Color(0xFF7A5A36)];
  static const _skins = [Color(0xFFC98E62), Color(0xFFB57A50), Color(0xFFD7A07A), Color(0xFFA9714A)];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFD7E2EA));
    final skin = _skins[seed % _skins.length];
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.12, h * 0.66, w * 0.76, h * 0.5), Radius.circular(w * 0.2)),
      Paint()..color = _shirts[seed % _shirts.length],
    );
    canvas.drawCircle(Offset(w / 2, h * 0.42), w * 0.25, Paint()..color = skin);
    canvas.drawArc(Rect.fromCircle(center: Offset(w / 2, h * 0.38), radius: w * 0.26), math.pi, math.pi, true, Paint()..color = _hair);
    if (seed % 3 != 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w / 2, h * 0.53), width: w * 0.22, height: h * 0.04), const Radius.circular(2)),
        Paint()..color = _hair,
      );
    }
    final eye = Paint()..color = _ink;
    canvas.drawCircle(Offset(w * 0.41, h * 0.42), w * 0.025, eye);
    canvas.drawCircle(Offset(w * 0.59, h * 0.42), w * 0.025, eye);
  }

  @override
  bool shouldRepaint(M7PortraitPainter old) => old.seed != seed;
}
