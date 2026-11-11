import 'dart:math' as math;

import 'package:flutter/material.dart';

// The tool store before an LT job (lesson 2.1, কাজ 1 "টুলবক্স সাজাও"): a drawn
// room — a window with daylight, a pegboard on the wall (the tools hang on it
// as widgets), a shelf, the workbench with the open red toolbox (four
// compartments), a wooden crate at the bench's right end for tools set aside,
// and the docket's nail on the left wall. No text in the art. Design: 360 wide
// × any height; everything stands on the floor row, so a tall phone gets more
// wall, never a stretched bench.

/// Where things are, in design pixels (360 × [h]).
@immutable
class ToolStoreGeo {
  const ToolStoreGeo(this.h);
  final double h;

  /// The floor's edge (the bench's feet stand on it).
  double get ground => h - 112;

  /// The bench top.
  double get bench => ground - 70;

  /// The pegboard the tools hang on.
  Rect get board => Rect.fromLTRB(92, ground - 366, 290, bench - 98);

  /// The open toolbox on the bench.
  Rect get box => Rect.fromLTWH(92, bench - 50, 196, 62);

  /// Compartment [i] of the toolbox's tray (four).
  Rect compartment(int i) => Rect.fromLTWH(box.left + 6 + i * 47.0, box.top + 8, 43, 34);

  /// Hanging place [i] of [n] on the pegboard.
  Rect slot(int i, int n) {
    final w = (board.width - 12) / n;
    return Rect.fromLTWH(board.left + 6 + w * i, board.top + 10, w, board.height - 18);
  }

  /// The docket on its nail, left wall.
  Rect get docket => Rect.fromLTWH(8, board.top + 6, 72, 132);

  /// The crate for tools set aside (bench, right end).
  Rect get crate => Rect.fromLTWH(296, bench - 34, 58, 46);

  /// Where the [i]th tool set aside stands in the crate, handle up.
  Rect aside(int i) => Rect.fromLTWH(crate.left + 2 + i * 17.0, bench - 150, 24, 128);

  /// The trainee, by the bench's left end.
  Rect get trainee => Rect.fromLTWH(-4, ground - 128, 70, 140);
}

class ToolStorePainter extends CustomPainter {
  const ToolStorePainter(this.geo);
  final ToolStoreGeo geo;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final g = geo.ground;

    // The wall: pale green distemper, darker toward the floor.
    final wall = Rect.fromLTWH(0, 0, w, g);
    c.drawRect(
      wall,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB9CDBF), Color(0xFFA3B9A9), Color(0xFF8DA393)],
          stops: [0, 0.7, 1],
        ).createShader(wall),
    );
    // Old patches on the plaster.
    final patch = Paint()..color = const Color(0x14000000);
    c.drawOval(Rect.fromLTWH(20, g - 230, 60, 30), patch);
    c.drawOval(Rect.fromLTWH(300, geo.board.top - 30, 50, 22), patch);

    // The window, high on the left, with daylight and its bars.
    final win = Rect.fromLTWH(14, math.max(90, geo.board.top - 150), 70, 96);
    if (win.bottom < geo.docket.top - 10) {
      c.drawRect(win.inflate(5), Paint()..color = const Color(0xFF6D7F72));
      c.drawRect(
        win,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF7FB2DE), Color(0xFFCFE4F2)],
          ).createShader(win),
      );
      c.drawOval(Rect.fromLTWH(win.left + 8, win.top + 18, 34, 12), Paint()..color = const Color(0xCCFFFFFF));
      final bar = Paint()
        ..color = const Color(0xFF52605A)
        ..strokeWidth = 2.2;
      for (var i = 1; i < 4; i++) {
        final x = win.left + win.width * i / 4;
        c.drawLine(Offset(x, win.top), Offset(x, win.bottom), bar);
      }
      c.drawLine(Offset(win.left, win.center.dy), Offset(win.right, win.center.dy), bar);
    }

    // A shelf above the pegboard with boxes on it (when there is wall room).
    final shelfY = geo.board.top - 26;
    if (shelfY > 110) {
      c.drawRect(Rect.fromLTWH(96, shelfY, 190, 6), Paint()..color = const Color(0xFF7A5A36));
      for (final (x, bw, bh, col) in const [
        (104.0, 40.0, 30.0, Color(0xFFC79A5B)),
        (150.0, 34.0, 22.0, Color(0xFF9A7448)),
        (192.0, 52.0, 34.0, Color(0xFFB8874D)),
        (252.0, 28.0, 18.0, Color(0xFF8D6A40)),
      ]) {
        final r = Rect.fromLTWH(x, shelfY - bh, bw, bh);
        c.drawRect(r, Paint()..color = col);
        c.drawRect(Rect.fromLTWH(x, shelfY - bh, bw, 4), Paint()..color = const Color(0x22000000));
      }
    }

    // The pegboard: hardboard with a hole grid and a frame.
    final b = geo.board;
    c.drawRRect(RRect.fromRectAndRadius(b.inflate(6), const Radius.circular(3)), Paint()..color = const Color(0xFF6B4C2C));
    c.drawRect(
      b,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFC59A68), Color(0xFFB0844F)],
        ).createShader(b),
    );
    final hole = Paint()..color = const Color(0xFF7D5A34);
    for (var y = b.top + 8; y < b.bottom - 4; y += 14) {
      for (var x = b.left + 8; x < b.right - 4; x += 14) {
        c.drawCircle(Offset(x, y), 1.6, hole);
      }
    }

    // The crate's back boards (behind the tools set aside) — drawn with the bench.

    // The workbench: a thick wooden top and a dark front with two drawers.
    final top = Rect.fromLTWH(80, geo.bench, w - 80, 12);
    c.drawRect(top, Paint()..color = const Color(0xFF8B6239));
    c.drawRect(Rect.fromLTWH(80, geo.bench, w - 80, 3), Paint()..color = const Color(0xFFA77A4C));
    final front = Rect.fromLTWH(86, geo.bench + 12, w - 86, g - geo.bench - 12);
    c.drawRect(front, Paint()..color = const Color(0xFF5E4127));
    for (final x in [112.0, 232.0]) {
      final d = Rect.fromLTWH(x, geo.bench + 20, 92, 24);
      c.drawRect(d, Paint()..color = const Color(0xFF6E4D2F));
      c.drawRect(Rect.fromLTWH(d.center.dx - 10, d.center.dy - 2, 20, 4), Paint()..color = const Color(0xFFB9BDC0));
    }

    // The floor: grey cement.
    final floor = Rect.fromLTWH(0, g, w, s.height - g);
    c.drawRect(
      floor,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8E9296), Color(0xFF6C7075)],
        ).createShader(floor),
    );
    c.drawRect(Rect.fromLTWH(0, g, w, 3), Paint()..color = const Color(0x33000000));

    // The open toolbox: the lid leaning back, the red body, the tray.
    final bx = geo.box;
    final lid = Path()
      ..moveTo(bx.left + 4, bx.top)
      ..lineTo(bx.left + 12, bx.top - 42)
      ..lineTo(bx.right - 12, bx.top - 42)
      ..lineTo(bx.right - 4, bx.top)
      ..close();
    c.drawPath(lid, Paint()..color = const Color(0xFFA3221C));
    c.drawPath(lid, Paint()
      ..color = const Color(0x33000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2);
    c.drawRect(Rect.fromLTWH(bx.left + 14, bx.top - 38, bx.width - 28, 3), Paint()..color = const Color(0x44FFFFFF));
    c.drawRRect(
      RRect.fromRectAndRadius(bx, const Radius.circular(4)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFD8352B), Color(0xFF9C1E18)],
        ).createShader(bx),
    );
    // The tray's compartments (dark wells).
    for (var i = 0; i < 4; i++) {
      c.drawRRect(RRect.fromRectAndRadius(geo.compartment(i), const Radius.circular(2)), Paint()..color = const Color(0xFF3B1210));
    }
    // Latches and the handle.
    for (final x in [bx.left + 20, bx.right - 30]) {
      c.drawRect(Rect.fromLTWH(x, bx.bottom - 14, 10, 8), Paint()..color = const Color(0xFFC9CED2));
    }

    // The crate for tools set aside.
    final cr = geo.crate;
    for (var i = 0; i < 3; i++) {
      c.drawRect(Rect.fromLTWH(cr.left, cr.top + i * 16, cr.width, 13), Paint()..color = i.isEven ? const Color(0xFFB98B55) : const Color(0xFFA8794A));
    }
    c.drawRect(Rect.fromLTWH(cr.left, cr.top, 4, cr.height), Paint()..color = const Color(0xFF7A5634));
    c.drawRect(Rect.fromLTWH(cr.right - 4, cr.top, 4, cr.height), Paint()..color = const Color(0xFF7A5634));

    // The docket's nail.
    c.drawCircle(Offset(geo.docket.center.dx, geo.docket.top - 4), 2.4, Paint()..color = const Color(0xFF4A4F55));
  }

  @override
  bool shouldRepaint(ToolStorePainter old) => old.geo.h != geo.h;
}
