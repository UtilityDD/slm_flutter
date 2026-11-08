import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'scene_kit.dart' show LinemanFigure, LinemanLook, LinemanMode;

// The harness store of lesson 1.4 কাজ 1 ("তিন মিনিটের পরীক্ষা"), drawn in
// code, full screen behind the play (GAME_LEVEL_PLAYBOOK.md §5):
//   sky and clouds through the window (a line pole far off) → shelves with
//   helmets and boxes → the pegboard where the harnesses hang on hooks →
//   the trainee behind the work bench → the bench with its inspection stand
//   (the harness taken down hangs on it, the hero) and the red reject crate.
// No text in the art (the crate's word and the calendar are widgets).
// Design: 360 wide × any height; the bench row keeps its place above the
// controls and a tall phone gets more wall and sky.

/// Where everything sits, in design pixels (360 × [height]).
@immutable
class HarnessGeo {
  const HarnessGeo._(this.height, this.inset);
  factory HarnessGeo.forScene(double height, double inset) => HarnessGeo._(height, inset);

  final double height;

  /// The bottom system inset (design px).
  final double inset;

  double get bottom => height - inset;

  /// The harness on the stand: its box above the tools, the buttons and the
  /// corner guide's speech bubble (guide at 72 + sprite 116 + a two-line
  /// bubble ≈ 250 px), so the bubble never hides the leg loops, the leg
  /// buckles or the crate. A little left of centre, so the stamp clears the
  /// guide standing over the reason deck.
  double get itemBottom => bottom - 250;
  double get itemH => (itemBottom - 266).clamp(176.0, 372.0);
  double get itemTop => itemBottom - itemH;
  static const itemCx = 176.0;
  Rect get item => Rect.fromCenter(center: Offset(itemCx, itemTop + itemH / 2), width: itemH * HarnessPainter.aspect, height: itemH);

  /// The pegboard with its four hooks.
  double get boardBottom => itemTop - 4;
  double get boardTop => boardBottom - 118;
  double get hookY => boardTop + 14;
  static const pegX = [46.0, 114.0, 182.0, 250.0];
  Rect pegItem(int i) => Rect.fromLTWH(pegX[i] - 30, hookY - 4, 60, 100);

  /// The wall calendar hangs on the board's right end.
  Rect get calendar => Rect.fromLTWH(296, boardTop + 12, 50, 62);

  /// The bench top: back edge (behind the stand) and front edge.
  double get benchBack => itemBottom - 22;
  double get benchFront => itemBottom + 24;

  /// The trainee stands behind the bench, left of the stand.
  Rect get trainee {
    final fh = (itemH * 0.92).clamp(170.0, 300.0);
    return Rect.fromLTWH(-4, benchBack + fh * 0.34 - fh, fh / 2, fh);
  }

  /// The red reject crate on the bench's right end.
  Rect get crate => Rect.fromLTWH(296, benchBack - 50, 60, 62);

  /// The window, up in the wall (more of it on a tall phone).
  Rect get window => Rect.fromLTWH(212, boardTop - 136, 124, 104);
}

/// The room behind: wall, window with sky and clouds, shelves, the pegboard.
class HarnessStorePainter extends CustomPainter {
  const HarnessStorePainter({required this.geo});
  final HarnessGeo geo;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final h = s.height;
    // Back wall: cool at the top, warm low down.
    c.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4F6B70), Color(0xFF93A9A4), Color(0xFFD6CDB8)],
          stops: [0, 0.5, 1],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // The window: sky, clouds, a line pole far off.
    final win = geo.window;
    c.drawRRect(RRect.fromRectAndRadius(win.inflate(6), const Radius.circular(4)), Paint()..color = const Color(0xFF55606A));
    c.save();
    c.clipRect(win);
    c.drawRect(
      win,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6FB3E6), Color(0xFFBFE3F6), Color(0xFFF6EBCB)],
          stops: [0, 0.7, 1],
        ).createShader(win),
    );
    final cloud = Paint()..color = const Color(0xEEFFFFFF);
    for (final (dx, dy, r) in const [(0.22, 0.26, 11.0), (0.32, 0.22, 14.0), (0.42, 0.28, 10.0), (0.72, 0.42, 9.0), (0.8, 0.38, 12.0)]) {
      c.drawCircle(Offset(win.left + win.width * dx, win.top + win.height * dy), r, cloud);
    }
    // Far trees and a distribution pole with its wires.
    final ground = win.bottom - win.height * 0.16;
    final trees = Paint()..color = const Color(0xFF6C9A6A);
    for (var i = 0; i < 6; i++) {
      c.drawCircle(Offset(win.left + 8 + i * 24.0, ground + 2), 13 + (i % 3) * 3.0, trees);
    }
    c.drawRect(Rect.fromLTRB(win.left, ground + 4, win.right, win.bottom), Paint()..color = const Color(0xFF9BB27C));
    final px = win.left + win.width * 0.62;
    c.drawRect(Rect.fromLTRB(px - 1.6, win.top + win.height * 0.2, px + 1.6, ground + 6), Paint()..color = const Color(0xFF8B8A84));
    c.drawRect(Rect.fromLTRB(px - 14, win.top + win.height * 0.24, px + 14, win.top + win.height * 0.24 + 2.4), Paint()..color = const Color(0xFF6B6F74));
    final wire = Paint()
      ..color = const Color(0x99404A52)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    for (final dx in const [-12.0, 0.0, 12.0]) {
      c.drawPath(
        Path()
          ..moveTo(win.left, win.top + win.height * 0.3)
          ..quadraticBezierTo(px + dx - 30, win.top + win.height * 0.34, px + dx, win.top + win.height * 0.23)
          ..quadraticBezierTo(px + dx + 30, win.top + win.height * 0.34, win.right, win.top + win.height * 0.3),
        wire,
      );
    }
    c.restore();
    final bar = Paint()
      ..color = const Color(0xFF55606A)
      ..strokeWidth = 4;
    c.drawLine(Offset(win.center.dx, win.top), Offset(win.center.dx, win.bottom), bar);
    c.drawLine(Offset(win.left, win.center.dy), Offset(win.right, win.center.dy), bar);
    // The sill and the morning light down the wall.
    c.drawRect(Rect.fromLTWH(win.left - 10, win.bottom + 5, win.width + 20, 6), Paint()..color = const Color(0xFF6B6255));
    c.drawPath(
      Path()
        ..moveTo(win.left, win.bottom + 11)
        ..lineTo(win.right, win.bottom + 11)
        ..lineTo(w * 0.7, h)
        ..lineTo(w * 0.18, h)
        ..close(),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [const Color(0xFFFFF1C4).withValues(alpha: 0.22), const Color(0xFFFFF1C4).withValues(alpha: 0)],
        ).createShader(Rect.fromLTWH(0, win.bottom, w, h - win.bottom)),
    );

    // Shelves, top left: helmets and boxes.
    final shelfTop = geo.boardTop - 128;
    final steel = Paint()..color = const Color(0xFF7F8A91);
    for (final x in const [10.0, 150.0]) {
      c.drawRect(Rect.fromLTWH(x, shelfTop, 4, geo.boardTop - shelfTop - 4), steel);
    }
    for (final y in [shelfTop + 50, shelfTop + 108]) {
      c.drawRect(Rect.fromLTWH(6, y, 152, 5), steel);
      c.drawRect(Rect.fromLTWH(6, y + 5, 152, 2), Paint()..color = const Color(0x33000000));
    }
    // Helmets on the upper shelf.
    for (final (x, col) in const [(30.0, Color(0xFFFFD34E)), (64.0, Color(0xFFFFFFFF)), (98.0, Color(0xFFFFD34E))]) {
      final y = shelfTop + 50;
      c.drawArc(Rect.fromLTWH(x - 14, y - 20, 28, 40), math.pi, math.pi, true, Paint()..color = col);
      c.drawRect(Rect.fromLTWH(x - 17, y - 3, 34, 3), Paint()..color = Color.lerp(col, Colors.black, 0.25)!);
    }
    // Boxes on the lower shelf.
    const boxCols = [Color(0xFFB98B54), Color(0xFF2F4F6E), Color(0xFFA9783F), Color(0xFFC79A60)];
    var bx = 16.0;
    for (var i = 0; i < 5; i++) {
      final bw = 20.0 + (i * 7) % 12;
      final bh = 22.0 + (i * 5) % 14;
      c.drawRect(Rect.fromLTWH(bx, shelfTop + 108 - bh, bw, bh), Paint()..color = boxCols[i % boxCols.length]);
      c.drawRect(Rect.fromLTWH(bx, shelfTop + 108 - bh, bw, 3), Paint()..color = const Color(0x22FFFFFF));
      bx += bw + 6;
    }

    // The pegboard: perforated hardboard in a timber frame, four hooks.
    final board = Rect.fromLTRB(6, geo.boardTop, 354, geo.boardBottom);
    c.drawRRect(RRect.fromRectAndRadius(board.inflate(4), const Radius.circular(3)), Paint()..color = const Color(0xFF6D4E2E));
    c.drawRect(
      board,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFC49A66), Color(0xFFAE8352)],
        ).createShader(board),
    );
    final hole = Paint()..color = const Color(0x55402A14);
    for (var y = board.top + 8; y < board.bottom - 4; y += 12) {
      for (var x = board.left + 8; x < board.right - 4; x += 12) {
        c.drawCircle(Offset(x, y), 1.3, hole);
      }
    }
    // A soft shadow under the top frame.
    c.drawRect(Rect.fromLTWH(board.left, board.top, board.width, 5), Paint()..color = const Color(0x33000000));
    for (final x in HarnessGeo.pegX) {
      _hook(c, Offset(x, geo.hookY));
    }
    // The calendar's nail.
    c.drawCircle(Offset(geo.calendar.center.dx, geo.calendar.top - 4), 2.4, Paint()..color = const Color(0xFF5E676F));
  }

  static void _hook(Canvas c, Offset o) {
    c.drawCircle(o + const Offset(1, 2), 4, Paint()..color = const Color(0x44000000));
    c.drawCircle(o, 4, Paint()..color = const Color(0xFF8D969D));
    c.drawLine(
      o,
      o + const Offset(0, 9),
      Paint()
        ..color = const Color(0xFFB8C0C6)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(HarnessStorePainter old) => old.geo.height != geo.height || old.geo.inset != geo.inset;
}

/// The work bench in front: the top, its front, the inspection stand, the
/// reject crate.
class HarnessBenchPainter extends CustomPainter {
  const HarnessBenchPainter({required this.geo});
  final HarnessGeo geo;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final back = geo.benchBack;
    final front = geo.benchFront;
    // The stand behind the harness: a post from the bench, an arm, a hook.
    final it = geo.item;
    final hookY = it.top + it.height * HarnessPainter.hookAt;
    final postX = it.right + 4;
    final steel = Paint()
      ..color = const Color(0xFF6F7880)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(postX, back + 6), Offset(postX, hookY - 14), steel);
    c.drawLine(Offset(postX, hookY - 14), Offset(HarnessGeo.itemCx, hookY - 14), steel);
    c.drawLine(Offset(HarnessGeo.itemCx, hookY - 14), Offset(HarnessGeo.itemCx, hookY - 4), steel..strokeWidth = 3.5);
    c.drawOval(Rect.fromCenter(center: Offset(postX, back + 8), width: 34, height: 8), Paint()..color = const Color(0xFF4A5157));

    // Bench top (planks), seen a little from above.
    final top = Rect.fromLTRB(0, back, w, front);
    c.drawRect(
      top,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF9C6B3E), Color(0xFFB98552)],
        ).createShader(top),
    );
    final seam = Paint()
      ..color = const Color(0x33402A14)
      ..strokeWidth = 1;
    for (var k = 1; k < 3; k++) {
      final y = back + (front - back) * k / 3;
      c.drawLine(Offset(0, y), Offset(w, y), seam);
    }
    // The front edge and the apron down to the floor.
    c.drawRect(Rect.fromLTRB(0, front, w, front + 4), Paint()..color = const Color(0xFFD9A46C));
    final apron = Rect.fromLTRB(0, front + 4, w, s.height);
    c.drawRect(
      apron,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6E4627), Color(0xFF3B2414)],
        ).createShader(apron),
    );
    final grain = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 1;
    for (var x = 30.0; x < w; x += 60) {
      c.drawLine(Offset(x, front + 8), Offset(x, s.height), grain);
    }
    // A row of drawers under the top (the bench is a store counter).
    final dh = math.min(64.0, (s.height - front) * 0.3);
    if (dh > 24) {
      final edge = Paint()
        ..color = const Color(0x55241409)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      final knob = Paint()..color = const Color(0xFFB0B6BC);
      for (var k = 0; k < 3; k++) {
        final d = Rect.fromLTWH(10 + k * (w - 20) / 3 + 4, front + 14, (w - 20) / 3 - 8, dh);
        c.drawRRect(RRect.fromRectAndRadius(d, const Radius.circular(3)), Paint()..color = const Color(0x22FFFFFF));
        c.drawRRect(RRect.fromRectAndRadius(d, const Radius.circular(3)), edge);
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: d.center.translate(0, -dh * 0.18), width: 30, height: 6), const Radius.circular(3)), knob);
      }
    }

    // The red reject crate on the right end.
    final cr = geo.crate;
    c.drawRect(Rect.fromLTRB(cr.left + 4, cr.bottom - 4, cr.right + 4, cr.bottom + 2), Paint()..color = const Color(0x44000000));
    c.drawRRect(
      RRect.fromRectAndRadius(cr, const Radius.circular(4)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFC63A2E), Color(0xFF8E2219)],
        ).createShader(cr),
    );
    final slot = Paint()..color = const Color(0x55000000);
    for (var k = 0; k < 3; k++) {
      c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(cr.left + 8 + k * 16, cr.bottom - 22, 10, 14), const Radius.circular(3)),
        slot,
      );
    }
    c.drawRect(Rect.fromLTWH(cr.left, cr.top, cr.width, 4), Paint()..color = const Color(0xFFE25A4B));
  }

  @override
  bool shouldRepaint(HarnessBenchPainter old) => old.geo.height != geo.height || old.geo.inset != geo.inset;
}

/// What a harness looks like on a hook (full body harness, or the waist belt).
enum HarnessShape { fullBody, belt }

/// A harness (or the waist belt) hanging from its back D-ring on a hook,
/// scaled into its box. The damage is not drawn: it is found close up.
class HarnessPainter extends CustomPainter {
  HarnessPainter({required this.shape, required this.color});
  final HarnessShape shape;
  final Color color;

  /// Width / height of the drawing.
  static const aspect = 180 / 374;

  /// Where (0–1 down the box) it hangs from its hook.
  static const hookAt = (70 - 56) / 374;

  static const _src = Rect.fromLTWH(100, 56, 180, 374);

  static const belt = Color(0xFF3A3F47);
  static const metal = Color(0xFF9AA3AB);

  /// The drawing's own coordinates for a point in a box of [size].
  static Offset toSrc(Offset p, Size size) {
    final k = math.min(size.width / _src.width, size.height / _src.height);
    final ox = (size.width - _src.width * k) / 2;
    final oy = (size.height - _src.height * k) / 2;
    return Offset((p.dx - ox) / k + _src.left, (p.dy - oy) / k + _src.top);
  }

  /// Which close look a tap at [p] (in a box of [size]) asks for: the
  /// label, a metal part, a stitched joint, or the webbing; null = missed.
  static int? zoneAt(HarnessShape shape, Offset p, Size size) {
    final q = toSrc(p, size);
    bool near(Offset o, double r) => (q - o).distance <= r;
    if (shape == HarnessShape.fullBody) {
      if (const Rect.fromLTWH(132, 226, 36, 44).contains(q)) return 3;
      if (near(const Offset(190, 70), 22) || near(const Offset(190, 200), 16) || near(const Offset(160, 396), 14) || near(const Offset(220, 396), 14)) return 2;
      if (near(const Offset(150, 200), 15) || near(const Offset(230, 200), 15) || near(const Offset(155, 310), 15) || near(const Offset(225, 310), 15)) return 1;
      if (const Rect.fromLTWH(118, 60, 140, 360).contains(q)) return 0;
      return null;
    }
    if (const Rect.fromLTWH(110, 150, 36, 44).contains(q)) return 3;
    if (near(const Offset(180, 300), 26) || near(const Offset(180, 418), 16)) return 2;
    if (near(const Offset(140, 288), 15) || near(const Offset(222, 288), 15)) return 1;
    if (const Rect.fromLTWH(96, 60, 190, 280).contains(q)) return 0;
    return null;
  }

  @override
  void paint(Canvas c, Size s) {
    final k = math.min(s.width / _src.width, s.height / _src.height);
    c.save();
    c.translate((s.width - _src.width * k) / 2, (s.height - _src.height * k) / 2);
    c.scale(k);
    c.translate(-_src.left, -_src.top);
    if (shape == HarnessShape.belt) {
      _belt(c);
    } else {
      _fullBody(c);
    }
    c.restore();
  }

  void _strap(Canvas c, Path p, double width, Color col) {
    c.drawPath(
      p,
      Paint()
        ..color = Color.lerp(col, Colors.black, 0.35)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    c.drawPath(
      p,
      Paint()
        ..color = col
        ..style = PaintingStyle.stroke
        ..strokeWidth = width - 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    // A row of stitches down the middle.
    final dash = Paint()
      ..color = Color.lerp(col, Colors.white, 0.45)!
      ..strokeWidth = 1;
    for (final m in p.computeMetrics()) {
      for (var d = 4.0; d < m.length - 3; d += 7) {
        final a = m.getTangentForOffset(d)!.position;
        final b = m.getTangentForOffset(math.min(m.length, d + 3.5))!.position;
        c.drawLine(a, b, dash);
      }
    }
  }

  void _buckle(Canvas c, Offset o, double w, double h) {
    final r = Rect.fromCenter(center: o, width: w, height: h);
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), Paint()..color = const Color(0xFF2B2F35));
    c.drawRRect(
      RRect.fromRectAndRadius(r.deflate(2.5), const Radius.circular(2)),
      Paint()
        ..color = metal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );
  }

  void _dRing(Canvas c, Offset top, double w, double h, {double stroke = 5}) {
    c.drawPath(
      Path()
        ..moveTo(top.dx - w / 2, top.dy + h)
        ..lineTo(top.dx - w / 2, top.dy + h * 0.45)
        ..quadraticBezierTo(top.dx - w / 2, top.dy, top.dx, top.dy)
        ..quadraticBezierTo(top.dx + w / 2, top.dy, top.dx + w / 2, top.dy + h * 0.45)
        ..lineTo(top.dx + w / 2, top.dy + h)
        ..close(),
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFFD5DADF), Color(0xFF7D868E)]).createShader(Rect.fromLTWH(top.dx - w / 2, top.dy, w, h))
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
  }

  void _fullBody(Canvas c) {
    const hook = Offset(190, 74);
    final l = Path()
      ..moveTo(hook.dx - 4, hook.dy + 18)
      ..quadraticBezierTo(140, 160, 150, 240)
      ..lineTo(156, 310);
    final r = Path()
      ..moveTo(hook.dx + 4, hook.dy + 18)
      ..quadraticBezierTo(240, 160, 230, 240)
      ..lineTo(224, 310);
    // Leg loops first (behind), then the shoulder straps, chest and waist.
    for (final x in const [160.0, 220.0]) {
      final loop = Path()
        ..moveTo(x - 4, 312)
        ..quadraticBezierTo(x - 32, 372, x, 398)
        ..quadraticBezierTo(x + 32, 372, x + 4, 312);
      _strap(c, loop, 11, color);
    }
    for (final p in [l, r]) {
      _strap(c, p, 13, color);
    }
    _strap(c, Path()..moveTo(146, 200)..lineTo(234, 200), 12, color);
    _strap(c, Path()..moveTo(148, 310)..lineTo(232, 310), 13, color);
    // Stitched joints (box stitches) where the straps cross.
    final box = Paint()
      ..color = Color.lerp(color, Colors.black, 0.5)!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final o in const [Offset(150, 200), Offset(230, 200), Offset(155, 310), Offset(225, 310)]) {
      final q = Rect.fromCenter(center: o, width: 10, height: 10);
      c.drawRect(q, box);
      c.drawLine(q.topLeft, q.bottomRight, box);
      c.drawLine(q.topRight, q.bottomLeft, box);
    }
    _buckle(c, const Offset(190, 200), 22, 16);
    for (final x in const [160.0, 220.0]) {
      _buckle(c, Offset(x, 398), 16, 12);
    }
    // Back D-ring on its pad.
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(hook.dx, hook.dy + 22), width: 30, height: 18), const Radius.circular(5)),
        Paint()..color = Color.lerp(color, Colors.black, 0.45)!);
    _dRing(c, Offset(hook.dx, hook.dy - 6), 24, 26);
    // The label tag on the left strap.
    const tag = Rect.fromLTWH(139, 234, 22, 32);
    c.drawRect(tag.shift(const Offset(1.5, 1.5)), Paint()..color = const Color(0x55000000));
    c.drawRect(tag, Paint()..color = Colors.white);
    final ink = Paint()
      ..color = const Color(0xFF8A9099)
      ..strokeWidth = 1.2;
    for (var y = tag.top + 7; y < tag.bottom - 4; y += 5) {
      c.drawLine(Offset(tag.left + 4, y), Offset(tag.right - 4, y), ink);
    }
  }

  void _belt(Canvas c) {
    const hook = Offset(190, 74);
    // A wide belt hanging as a loop from the hook, its back pad low down.
    final loop = Path()
      ..moveTo(hook.dx, hook.dy + 4)
      ..cubicTo(96, 140, 104, 300, 180, 302)
      ..cubicTo(256, 300, 284, 140, hook.dx, hook.dy + 4);
    _strap(c, loop, 24, belt);
    // The back pad.
    final pad = Path()
      ..moveTo(128, 268)
      ..quadraticBezierTo(180, 318, 232, 268);
    c.drawPath(
      pad,
      Paint()
        ..color = const Color(0xFF5B616B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 30
        ..strokeCap = StrokeCap.round,
    );
    // Side D-rings and the buckle.
    _dRing(c, const Offset(140, 280), 14, 16, stroke: 3.5);
    _dRing(c, const Offset(222, 280), 14, 16, stroke: 3.5);
    _buckle(c, const Offset(180, 300), 40, 28);
    // A short positioning rope with its hook.
    final rope = Paint()
      ..color = const Color(0xFF3B6EA8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    c.drawPath(Path()..moveTo(140, 294)..quadraticBezierTo(132, 372, 168, 398), rope);
    c.drawPath(
      Path()
        ..moveTo(168, 398)
        ..lineTo(168, 414)
        ..quadraticBezierTo(168, 428, 180, 428)
        ..quadraticBezierTo(192, 428, 192, 416),
      Paint()
        ..color = metal
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5,
    );
    // The label tag.
    const tag = Rect.fromLTWH(117, 158, 22, 30);
    c.drawRect(tag.shift(const Offset(1.5, 1.5)), Paint()..color = const Color(0x55000000));
    c.drawRect(tag, Paint()..color = Colors.white);
    final ink = Paint()
      ..color = const Color(0xFF8A9099)
      ..strokeWidth = 1.2;
    for (var y = tag.top + 7; y < tag.bottom - 4; y += 5) {
      c.drawLine(Offset(tag.left + 4, y), Offset(tag.right - 4, y), ink);
    }
    // Hung by a short loop on the hook.
    c.drawCircle(hook + const Offset(0, -2), 6, Paint()
      ..color = metal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(HarnessPainter old) => old.shape != shape || old.color != color;
}

/// The deadly moment, in colour over the frozen grey store: up on a pole,
/// the trainee slips — the damaged harness gives way and he falls; or, in
/// the waist belt, the jerk throws all the load on his belly and spine.
class HarnessFall extends StatelessWidget {
  const HarnessFall({super.key, required this.centre, required this.radius, required this.belt, required this.quiet});
  final Offset centre;
  final double radius;
  final bool belt;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final r = radius;
    final box = Rect.fromCircle(center: centre, radius: r);
    return Stack(
      children: [
        Positioned.fromRect(
          rect: box,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: quiet ? 1 : 0, end: 1),
            duration: const Duration(milliseconds: 1900),
            builder: (_, t, _) {
              final slip = Curves.easeIn.transform(((t - 0.12) / 0.3).clamp(0.0, 1.0));
              final fall = belt ? 0.0 : Curves.easeInCubic.transform(((t - 0.36) / 0.64).clamp(0.0, 1.0));
              final jerk = belt ? Curves.elasticOut.transform(((t - 0.4) / 0.6).clamp(0.0, 1.0)) : 0.0;
              // The figure: beside the pole, then slipping off, then falling.
              final fh = r * 0.95;
              final fw = fh / 2;
              final poleX = r * 0.62;
              final anchor = Offset(poleX + 4, r * 0.36);
              Offset backAt(double sl, double fa) {
                final f = Rect.fromLTWH(poleX + 8 + r * 0.18 * sl, r * 0.42 + r * 0.32 * sl + r * 1.6 * fa, fw, fh);
                return Offset(f.left + fw * 0.42, f.top + fh * (belt ? 0.5 : 0.34));
              }

              final drop = r * 0.32 * slip + r * 1.6 * fall;
              final fig = Rect.fromLTWH(poleX + 8 + r * 0.18 * slip, r * 0.42 + drop, fw, fh);
              final back = backAt(slip, fall);
              // Where the harness tore: its back D-ring tab, as the fall began.
              final torn = backAt(Curves.easeIn.transform(((0.36 - 0.12) / 0.3).clamp(0.0, 1.0)), 0);
              final angle = belt ? 1.25 * jerk : 0.9 * fall + 0.25 * slip;
              return ClipOval(
                child: Stack(
                  children: [
                    Positioned.fill(child: CustomPaint(painter: _FallBack(poleX: poleX))),
                    Positioned.fromRect(
                      rect: fig,
                      child: Transform.rotate(
                        angle: angle,
                        alignment: belt ? const Alignment(0, 0.0) : Alignment.topCenter,
                        child: const LinemanFigure(look: LinemanLook.trainee, mode: LinemanMode.worried, quiet: true),
                      ),
                    ),
                    Positioned.fill(
                      child: CustomPaint(painter: _FallFront(t: t, anchor: anchor, back: back, torn: torn, belt: belt, snapped: !belt && t > 0.36)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // The ring of the vignette (a dark rim outside it; no box shadow,
        // which would show through the open circle and dim the colour).
        Positioned.fromRect(
          rect: box.inflate(3),
          child: const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.fromBorderSide(BorderSide(color: Color(0x88000000), width: 3)),
              ),
            ),
          ),
        ),
        Positioned.fromRect(
          rect: box,
          child: const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.fromBorderSide(BorderSide(color: Color(0xFFE2463A), width: 5)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _FallBack extends CustomPainter {
  const _FallBack({required this.poleX});
  final double poleX;

  @override
  void paint(Canvas c, Size s) {
    c.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5FA8DE), Color(0xFFBFE0F2), Color(0xFF8DB06A)],
          stops: [0, 0.75, 1],
        ).createShader(Offset.zero & s),
    );
    // The pole (concrete), its cross-arm, insulators and the line.
    final w = s.width * 0.07;
    c.drawRect(Rect.fromLTRB(poleX - w / 2, s.height * 0.08, poleX + w / 2, s.height), Paint()..color = const Color(0xFFBDBAB1));
    c.drawRect(Rect.fromLTRB(poleX - w / 2, s.height * 0.08, poleX - w / 2 + 3, s.height), Paint()..color = const Color(0x22000000));
    final armY = s.height * 0.16;
    c.drawRect(Rect.fromLTRB(poleX - s.width * 0.3, armY, poleX + s.width * 0.3, armY + 6), Paint()..color = const Color(0xFF5F676F));
    for (final dx in [-0.26, 0.26]) {
      c.drawRect(Rect.fromCenter(center: Offset(poleX + s.width * dx, armY - 6), width: 8, height: 12), Paint()..color = const Color(0xFFEDE7DA));
    }
    c.drawLine(Offset(0, armY - 12), Offset(s.width, armY - 14), Paint()
      ..color = const Color(0xFF2B2F35)
      ..strokeWidth = 1.4);
  }

  @override
  bool shouldRepaint(_FallBack old) => old.poleX != poleX;
}

class _FallFront extends CustomPainter {
  _FallFront({required this.t, required this.anchor, required this.back, required this.torn, required this.belt, required this.snapped});
  final double t;
  final Offset anchor;
  final Offset back;

  /// Where the damaged harness tore away from the (whole) lanyard.
  final Offset torn;
  final bool belt;
  final bool snapped;

  @override
  void paint(Canvas c, Size s) {
    final rope = Paint()
      ..color = const Color(0xFFE67E22)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    // The lanyard round the pole.
    c.drawCircle(anchor, 5, Paint()
      ..color = const Color(0xFF9AA3AB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
    if (!snapped) {
      c.drawLine(anchor, back, rope);
    } else {
      // The harness gave way, not the lanyard: the lanyard still hangs from
      // the pole whole, a torn scrap of webbing on its hook; a frayed stub
      // on the falling man's back; a flash where the webbing tore.
      final k = ((t - 0.36) / 0.35).clamp(0.0, 1.0);
      final sag = Offset(-4, 10 * k);
      final end = torn + sag;
      c.drawPath(
        Path()
          ..moveTo(anchor.dx, anchor.dy)
          ..quadraticBezierTo((anchor.dx + end.dx) / 2 - 2, math.max(anchor.dy, end.dy) + 8 * k, end.dx, end.dy),
        rope,
      );
      final webbing = Paint()..color = const Color(0xFF2E5E9E);
      c.drawCircle(end, 3.5, Paint()
        ..color = const Color(0xFF9AA3AB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5);
      c.save();
      c.translate(end.dx, end.dy + 3);
      c.rotate(0.2);
      c.drawRect(const Rect.fromLTWH(-3, 0, 6, 11), webbing);
      final fray = Paint()
        ..color = const Color(0xFFE2463A)
        ..strokeWidth = 1.4;
      for (final dx in const [-2.5, 0.0, 2.5]) {
        c.drawLine(Offset(dx, 11), Offset(dx * 1.4, 15), fray);
      }
      c.restore();
      // The stub left on the harness's back.
      for (final dx in const [-3.0, 0.0, 3.0]) {
        c.drawLine(back + Offset(dx, 0), back + Offset(dx * 1.6, -7), fray..strokeWidth = 1.8);
      }
      if (k < 1) {
        final at = torn;
        final star = Paint()..color = Color.fromRGBO(255, 210, 80, 1 - k);
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4 + 0.3;
          final l = (10 + 18 * k) * (i.isEven ? 1 : 0.6);
          c.drawLine(at, at + Offset(math.cos(a), math.sin(a)) * l, star..strokeWidth = 3);
        }
        c.drawCircle(at, 7 * (1 - k) + 2, Paint()..color = Color.fromRGBO(226, 70, 58, 1 - k));
      }
    }
    if (belt && t > 0.4) {
      // All the load on the belly and the spine.
      final k = ((t - 0.4) / 0.6).clamp(0.0, 1.0);
      for (final d in const [0.0, 0.33, 0.66]) {
        final u = ((k - d) / 0.34).clamp(0.0, 1.0);
        if (u <= 0 || u >= 1) continue;
        c.drawCircle(back, 8 + 30 * u, Paint()
          ..color = Color.fromRGBO(226, 70, 58, 0.9 * (1 - u))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4);
      }
      c.drawCircle(back, 9, Paint()..color = const Color(0xCCE2463A));
    }
  }

  @override
  bool shouldRepaint(_FallFront old) => old.t != t || old.back != back || old.torn != torn || old.snapped != snapped;
}
