import 'dart:math' as math;

import 'package:flutter/material.dart';

// The line store before a new pole is dressed (lesson 3.3, কাজ 1 "সঠিক
// ক্রস-আর্ম, সঠিক ক্ল্যাম্প"): a drawn store room — a barred window, a steel
// rack with four galvanized shelves (the parts lie on it as widgets), a few
// PCC pole pieces lying along the back wall, the hand trolley on the floor
// (three wells: cross-arm, clamp, nuts and bolts) and a scrap drum at the
// right for parts set aside; the docket's nail on the left wall. No text in
// the art. Design: 360 wide × any height; everything stands on the floor row,
// so a tall phone gets more wall, never a stretched rack.

/// Where things are, in design pixels (360 × [h]).
@immutable
class M3CrossarmPickStoreGeo {
  const M3CrossarmPickStoreGeo(this.h);
  final double h;

  /// The floor's edge.
  double get ground => h - 112;

  /// The steel rack (four shelves).
  Rect get rack => Rect.fromLTRB(88, ground - 372, 300, ground - 120);

  /// Shelf row [i] of the rack (four, top to bottom) — a part lies on it.
  Rect slot(int i) {
    final r = rack;
    final rh = (r.height - 8) / 4;
    return Rect.fromLTWH(r.left + 8, r.top + 4 + rh * i, r.width - 16, rh - 8);
  }

  /// The hand trolley's bed on the floor.
  Rect get trolley => Rect.fromLTWH(104, ground - 66, 182, 40);

  /// Well [i] of the trolley (three).
  Rect well(int i) => Rect.fromLTWH(trolley.left + 6 + i * 58.0, trolley.top + 5, 54, 30);

  /// The docket on its nail, left wall.
  Rect get docket => Rect.fromLTWH(8, rack.top + 6, 74, 140);

  /// The scrap drum for parts set aside (floor, right).
  Rect get drum => Rect.fromLTWH(304, ground - 92, 50, 86);

  /// Where the [i]th part set aside leans in the drum.
  Rect aside(int i) => Rect.fromLTWH(drum.left - 6 + i * 4.0, drum.top - 30 + i * 18.0, 62, 24);

  /// The trainee, at the rack's left foot.
  Rect get trainee => Rect.fromLTWH(-4, ground - 128, 70, 140);
}

class M3CrossarmPickStorePainter extends CustomPainter {
  const M3CrossarmPickStorePainter(this.geo);
  final M3CrossarmPickStoreGeo geo;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final g = geo.ground;

    // The wall: cement grey with a lighter top, darker toward the floor.
    final wall = Rect.fromLTWH(0, 0, w, g);
    c.drawRect(
      wall,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFC8CCC4), Color(0xFFB2B7AE), Color(0xFF979D94)],
          stops: [0, 0.7, 1],
        ).createShader(wall),
    );
    // A painted dado band and old stains.
    c.drawRect(Rect.fromLTWH(0, g - 64, w, 64), Paint()..color = const Color(0x22455A6E));
    final stain = Paint()..color = const Color(0x12000000);
    c.drawOval(Rect.fromLTWH(14, g - 210, 58, 26), stain);
    c.drawOval(Rect.fromLTWH(306, geo.rack.top - 26, 44, 18), stain);

    // The window, high on the left, with daylight and its bars.
    final win = Rect.fromLTWH(14, math.max(90, geo.rack.top - 150), 70, 96);
    if (win.bottom < geo.docket.top - 10) {
      c.drawRect(win.inflate(5), Paint()..color = const Color(0xFF6E746C));
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

    // PCC pole pieces lying along the wall's foot, behind the rack.
    for (final (y, x0) in [(g - 14.0, 70.0), (g - 26.0, 120.0)]) {
      final r = Rect.fromLTRB(x0, y, w + 10, y + 14);
      c.drawRect(
        r,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFBFC1BC), Color(0xFF8F928C)],
          ).createShader(r),
      );
      c.drawRect(Rect.fromLTWH(x0, y, 3, 14), Paint()..color = const Color(0xFF7C7F79));
    }

    // The rack: orange uprights, galvanized shelves.
    final rk = geo.rack;
    final up = Paint()..color = const Color(0xFFD9741E);
    final upDark = Paint()..color = const Color(0xFFA9550F);
    for (final x in [rk.left - 6, rk.right]) {
      c.drawRect(Rect.fromLTWH(x, rk.top - 6, 6, g - rk.top + 6), up);
      c.drawRect(Rect.fromLTWH(x + 4, rk.top - 6, 2, g - rk.top + 6), upDark);
      for (var y = rk.top; y < g - 6; y += 12) {
        c.drawRect(Rect.fromLTWH(x + 1.5, y, 3, 4), Paint()..color = const Color(0xFF7A3F0C));
      }
    }
    // The back mesh.
    c.drawRect(rk, Paint()..color = const Color(0x22303A44));
    final mesh = Paint()
      ..color = const Color(0x1F1E252C)
      ..strokeWidth = 1;
    for (var x = rk.left + 10; x < rk.right; x += 14) {
      c.drawLine(Offset(x, rk.top), Offset(x, rk.bottom), mesh);
    }
    // Shelves under each row (and the lowest one at the rack's foot).
    for (var i = 0; i < 4; i++) {
      final row = geo.slot(i);
      final y = row.bottom + 2;
      final shelf = Rect.fromLTRB(rk.left - 2, y, rk.right + 2, y + 6);
      c.drawRect(
        shelf,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFDDE2E6), Color(0xFF8E979F)],
          ).createShader(shelf),
      );
    }
    final foot = Rect.fromLTRB(rk.left - 2, g - 50, rk.right + 2, g - 44);
    c.drawRect(foot, Paint()..color = const Color(0xFF9AA2A9));

    // The hand trolley: its bed with three wells, two wheels, the handle.
    final t = geo.trolley;
    c.drawLine(Offset(t.left + 4, t.top + 6), Offset(t.left - 18, t.top - 40), Paint()
      ..color = const Color(0xFF2F4A6B)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round);
    c.drawLine(Offset(t.left - 26, t.top - 40), Offset(t.left - 10, t.top - 40), Paint()
      ..color = const Color(0xFF1C1F24)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round);
    c.drawRRect(
      RRect.fromRectAndRadius(t, const Radius.circular(4)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3F6A9A), Color(0xFF243F60)],
        ).createShader(t),
    );
    for (var i = 0; i < 3; i++) {
      c.drawRRect(RRect.fromRectAndRadius(geo.well(i), const Radius.circular(3)), Paint()..color = const Color(0xFF152536));
    }
    for (final x in [t.left + 24, t.right - 24]) {
      final wc = Offset(x, t.bottom + 12);
      c.drawCircle(wc, 13, Paint()..color = const Color(0xFF1C1F24));
      c.drawCircle(wc, 5, Paint()..color = const Color(0xFFB9BDC0));
    }

    // The scrap drum for parts set aside.
    final d = geo.drum;
    c.drawRRect(
      RRect.fromRectAndRadius(d, const Radius.circular(5)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF5B4B3A), Color(0xFF8A6E4F), Color(0xFF4A3C2E)],
        ).createShader(d),
    );
    for (final y in [d.top + 16, d.bottom - 18]) {
      c.drawRect(Rect.fromLTWH(d.left, y, d.width, 4), Paint()..color = const Color(0xFF3A2E22));
    }
    c.drawOval(Rect.fromLTWH(d.left, d.top - 5, d.width, 10), Paint()..color = const Color(0xFF2A221A));

    // The docket's nail.
    c.drawCircle(Offset(geo.docket.center.dx, geo.docket.top - 4), 2.4, Paint()..color = const Color(0xFF4A4F55));
  }

  @override
  bool shouldRepaint(M3CrossarmPickStorePainter old) => old.geo.h != geo.h;
}
