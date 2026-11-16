import 'dart:math' as math;

import 'package:flutter/material.dart';

// The drawn world of lesson 8.10 "রেগুলেশন এবং আপনি: ফিল্ডে প্রয়োগ" (pack
// do_8_10_a, m8_duty_logbook.dart): one village lane on PCC poles — the crew
// van with the docket on its door, houses with meter boxes, the work pole, a
// scrap crate on the tailgate — and, a camera pan to the right, the window of
// the substation gate where the written permit is handed out. Bottom left, the
// tray: the logbook (ruled page) and the PTW book; at the tailgate the page
// grows to fill the screen.
//
// Geometry in design px (360 wide); everything the player touches is a rect
// here so the page and the tests share it. The art carries only Latin digits
// and labels a worker reads (a tester's display); no logos, no real forms.
// Code-drawn, gradients, no bitmaps.

/// Where the crew is in the time-lapse (what the pole shows).
enum M8Crew { idle, testLive1, testDead, testLive2, earthed, up, down, earthOff }

/// The logbook's columns.
enum M8Col { taken, released, work, sign }

/// The pages of the page (the five 'lines' a read pass must cover).
const int kM8ReadZones = 5;

/// The columns' cut on the open page (page units: x from the page's left).
abstract final class M8PageGeo {
  static const double left = 10, top = 128, width = 340;
  static const double headH = 24, rowH = 26, todayH = 100;
  static const double height = headH + 2 * rowH + todayH;
  static const List<double> colW = [74, 74, 118, 74];

  static Rect get page => const Rect.fromLTWH(left, top, width, height);
  static Rect col(M8Col c) {
    var x = left;
    for (var i = 0; i < c.index; i++) {
      x += colW[i];
    }
    return Rect.fromLTWH(x, top + headH + 2 * rowH, colW[c.index], todayH);
  }

  static Rect headCol(M8Col c) {
    final r = col(c);
    return Rect.fromLTWH(r.left, top, r.width, headH);
  }

  static Rect earlier(int i) => Rect.fromLTWH(left, top + headH + rowH * i, width, rowH);

  /// The five zones a finger must pass down (header, two earlier rows, the
  /// two halves of today's row).
  static Rect zone(int i) => switch (i) {
        0 => Rect.fromLTWH(left, top, width, headH),
        1 => earlier(0),
        2 => earlier(1),
        3 => Rect.fromLTWH(left, top + headH + 2 * rowH, width, todayH / 2),
        _ => Rect.fromLTWH(left, top + headH + 2 * rowH + todayH / 2, width, todayH / 2),
      };

  /// Which zone a point at [y] lies in (null: off the page).
  static int? zoneAt(double y) {
    for (var i = 0; i < kM8ReadZones; i++) {
      final z = zone(i);
      if (y >= z.top && y < z.bottom) return i;
    }
    return null;
  }
}

/// Where things are on the scene.
@immutable
class M8Geo {
  const M8Geo._(this.height, this.inset);

  factory M8Geo.forScene(double height, double inset) => M8Geo._(height, inset);

  final double height;
  final double inset;

  double get base => height - inset * 0.5;

  /// The bottom of the scene proper (the tray and the guide lie below).
  double get sceneBottom => base - 190 - (height >= 700 ? 25 : 0);
  double get ground => sceneBottom - 26;

  /// The dash clock and the phone (HUD chips on the van's dash).
  Rect get clock => const Rect.fromLTWH(14, 128, 104, 44);
  Rect get phone => const Rect.fromLTWH(126, 128, 106, 44);

  Rect get pole => Rect.fromLTWH(268, ground - 212, 64, 198);
  Rect get van => Rect.fromLTWH(12, ground - 90, 130, 100);
  Rect get crate => Rect.fromLTWH(152, ground - 32, 34, 32);
  Rect get docketOnDoor => Rect.fromLTWH(70, ground - 58, 30, 24);

  double get traineeX => 204;
  double get manX => 246;
  Rect get pocket => Rect.fromLTWH(traineeX - 10, ground - 52, 24, 20);
  Rect get note => Rect.fromLTWH(212, ground - 66, 38, 24);
  Rect get meterBox => Rect.fromLTWH(224, ground - 100, 28, 34);
  Rect get coil => Rect.fromLTWH(226, ground - 26, 26, 22);
  Rect get manBox => Rect.fromLTWH(228, ground - 70, 40, 70);

  /// The man's caption (silent) above him; the clerk's at the window.
  Rect get bubble => Rect.fromLTWH(104, ground - 156, 168, 52);

  /// The four places for the carbon copy and the copy in hand.
  Rect place(int i) => Rect.fromLTWH(8 + 84.0 * i, sceneBottom - 170, 78, 56);
  Rect get copyInHand => Rect.fromLTWH(131, sceneBottom - 238, 98, 56);

  /// The tray (compact logbook) and the PTW book beside it.
  Rect get tray => Rect.fromLTWH(8, base - 176, 238, 112);
  Rect get ptwBook => Rect.fromLTWH(8, base - 58, 104, 46);

  /// A compact tray column (header + today's row).
  Rect trayCol(M8Col c) {
    const w = [62.0, 62.0, 70.0, 44.0];
    var x = tray.left;
    for (var i = 0; i < c.index; i++) {
      x += w[i];
    }
    return Rect.fromLTWH(x, tray.top + 22 + 28, w[c.index], 56 + 6);
  }

  /// The open page and its strip of things to drag (tailgate).
  Rect get stripTop => const Rect.fromLTWH(10, 312, 340, 56);

  /// Slot [i] of the strip: 0-2 the crate's parts, 3 the docket card, 4 the
  /// carbon copy, 5 the clock.
  Rect slot(int i) => Rect.fromLTWH(10 + 57.0 * i, 314, 52, 52);

  /// Where the deadly inset sits.
  Rect get inset0 => Rect.fromCenter(center: Offset(180, ground - 80), width: 300, height: 230);

  @override
  bool operator ==(Object other) => other is M8Geo && other.height == height && other.inset == inset;

  @override
  int get hashCode => Object.hash(height, inset);
}

const _skyTop = Color(0xFF8CC4EA);
const _skyLow = Color(0xFFE3F0DC);

/// The lane: sky, far hills, houses, poles, the van, the crate; the work pole
/// with whatever the crew is doing; the station panel to its right (a 720 px
/// wide strip: the lane then the gate).
class M8WorldPainter extends CustomPainter {
  M8WorldPainter({required this.geo, required this.crew, required this.house, required this.parts, required this.phoneOn, required this.signed})
      : super();
  final M8Geo geo;
  final M8Crew crew;

  /// 0-2: which house stands behind the man (its colour).
  final int house;

  /// Old parts in the scrap crate.
  final int parts;
  final bool phoneOn;
  final bool signed;

  @override
  void paint(Canvas c, Size size) {
    _lane(c);
    c.save();
    c.translate(360, 0);
    _station(c);
    c.restore();
  }

  void _lane(Canvas c) {
    final g = geo.ground;
    final sky = Rect.fromLTWH(0, 0, 360, g);
    c.drawRect(sky, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_skyTop, _skyLow]).createShader(sky));
    // Far hills.
    final hills = Path()
      ..moveTo(0, g - 40)
      ..quadraticBezierTo(70, g - 96, 150, g - 52)
      ..quadraticBezierTo(240, g - 100, 360, g - 46)
      ..lineTo(360, g)
      ..lineTo(0, g)
      ..close();
    c.drawPath(hills, Paint()..color = const Color(0xFF9CC48A));
    // The ground and the lane.
    final ground = Rect.fromLTWH(0, g, 360, geo.height - g);
    c.drawRect(ground, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8A7A5E), Color(0xFF5E5240)]).createShader(ground));
    c.drawRect(Rect.fromLTWH(0, g, 360, 6), Paint()..color = const Color(0xFFB09A74));
    _houses(c, g);
    _farPoles(c, g);
    _van(c, g);
    _pole(c, g);
    _trainee(c, g);
  }

  void _houses(Canvas c, double g) {
    const walls = [Color(0xFFE9D8B4), Color(0xFFD7E3C8), Color(0xFFE8C9B8)];
    const roofs = [Color(0xFF9C4A32), Color(0xFF6A7A8C), Color(0xFF8A5A3A)];
    // The house behind the man (dealt colour), a second far to the right.
    final h = Rect.fromLTWH(196, g - 112, 84, 112);
    c.drawRect(h, Paint()..color = walls[house % 3]);
    final roof = Path()
      ..moveTo(h.left - 6, h.top)
      ..lineTo(h.center.dx, h.top - 26)
      ..lineTo(h.right + 6, h.top)
      ..close();
    c.drawPath(roof, Paint()..color = roofs[house % 3]);
    c.drawRect(Rect.fromLTWH(h.left + 46, h.top + 52, 22, 60), Paint()..color = const Color(0xFF6A4A32));
    c.drawRect(Rect.fromLTWH(h.left + 8, h.top + 54, 24, 20), Paint()..color = const Color(0xFF7AA4C8));
    // Its meter box (a grey box with a round dial).
    final m = geo.meterBox;
    c.drawRRect(RRect.fromRectAndRadius(m, const Radius.circular(3)), Paint()..color = const Color(0xFFB8BDC2));
    c.drawCircle(m.center.translate(0, -3), 8, Paint()..color = const Color(0xFFF4F1E8));
    c.drawLine(m.center.translate(0, -3), m.center.translate(4, -7), Paint()
      ..color = const Color(0xFF26303D)
      ..strokeWidth = 1.4);
    c.drawRect(Rect.fromLTWH(m.left + 6, m.bottom - 10, m.width - 12, 5), Paint()..color = const Color(0xFF6C7278));
    // A second house at the right edge.
    final h2 = Rect.fromLTWH(332, g - 84, 40, 84);
    c.drawRect(h2, Paint()..color = const Color(0xFFD8C7A8));
    c.drawRect(Rect.fromLTWH(h2.left - 4, h2.top - 10, h2.width + 8, 12), Paint()..color = const Color(0xFF8A5A3A));
  }

  void _farPoles(Canvas c, double g) {
    final pole = Paint()..color = const Color(0xFF9A9FA4);
    final wire = Paint()
      ..color = const Color(0xFF2A2A2A)
      ..strokeWidth = 1.4;
    for (final x in [40.0, 212.0]) {
      c.drawRect(Rect.fromLTWH(x - 3, g - 130, 6, 130), pole);
      c.drawRect(Rect.fromLTWH(x - 20, g - 126, 40, 4), Paint()..color = const Color(0xFF5B6168));
    }
    final wx = geo.pole.center.dx;
    final top = geo.pole.top + 8;
    for (var i = 0; i < 3; i++) {
      final y0 = g - 124 + i * 0.0;
      final p = Path()
        ..moveTo(0, y0 + 6)
        ..quadraticBezierTo(20, y0 + 14, 40 - 16 + i * 16, y0)
        ..quadraticBezierTo(120, y0 + 20, 212 - 16 + i * 16, y0)
        ..quadraticBezierTo(250, y0 + 18, wx - 20 + i * 20, top + 12);
      c.drawPath(p, wire..style = PaintingStyle.stroke);
    }
    final p2 = Path()
      ..moveTo(wx, top + 12)
      ..quadraticBezierTo(340, top + 40, 360, top + 30);
    c.drawPath(p2, wire);
  }

  void _van(Canvas c, double g) {
    final v = geo.van;
    final body = RRect.fromRectAndRadius(Rect.fromLTWH(v.left, v.top + 14, v.width, v.height - 24), const Radius.circular(8));
    c.drawRRect(body, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF2EEE0), Color(0xFFD6D0BE)]).createShader(v));
    c.drawRect(Rect.fromLTWH(v.left, v.top + 54, v.width, 6), Paint()..color = const Color(0xFF2E6FB0));
    // The cab window and the dash.
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(v.right - 52, v.top + 20, 40, 26), const Radius.circular(4)), Paint()..color = const Color(0xFF6C8CA6));
    // The docket on the door.
    final d = geo.docketOnDoor;
    c.drawRect(d, Paint()..color = const Color(0xFFFBF7EC));
    c.drawRect(d, Paint()
      ..color = const Color(0xFF9C8A6A)
      ..style = PaintingStyle.stroke);
    for (var i = 0; i < 3; i++) {
      c.drawLine(Offset(d.left + 4, d.top + 6 + i * 6), Offset(d.right - 4 - (i == 2 ? 8 : 0), d.top + 6 + i * 6), Paint()
        ..color = const Color(0xFF8A7A5E)
        ..strokeWidth = 1);
    }
    // Wheels.
    for (final x in [v.left + 32, v.right - 30]) {
      c.drawCircle(Offset(x, g + 6), 14, Paint()..color = const Color(0xFF1E1E1E));
      c.drawCircle(Offset(x, g + 6), 6, Paint()..color = const Color(0xFF8A8F94));
    }
    // The tailgate crate and the old parts in it.
    final k = geo.crate;
    c.drawRect(k, Paint()..color = const Color(0xFF8A6A3C));
    c.drawRect(Rect.fromLTWH(k.left, k.top, k.width, 4), Paint()..color = const Color(0xFFB08A52));
    for (var i = 0; i < parts.clamp(0, 3); i++) {
      c.drawCircle(Offset(k.left + 9 + i * 8, k.top - 2 - (i == 1 ? 4 : 0)), 5, Paint()..color = const [Color(0xFF8A8F94), Color(0xFFB0602E), Color(0xFFD8D2C0)][i]);
    }
  }

  void _pole(Canvas c, double g) {
    final p = geo.pole;
    final cx = p.center.dx;
    // The PCC pole and its cross-arm.
    c.drawRect(Rect.fromLTWH(cx - 7, p.top + 10, 14, g - p.top - 10), Paint()..shader = const LinearGradient(colors: [Color(0xFFB4B9BD), Color(0xFF8A8F94)]).createShader(Rect.fromLTWH(cx - 7, p.top, 14, g - p.top)));
    c.drawRect(Rect.fromLTWH(cx - 30, p.top + 14, 60, 6), Paint()..color = const Color(0xFF5B6168));
    for (final x in [cx - 24, cx, cx + 24]) {
      c.drawRect(Rect.fromLTWH(x - 3, p.top + 6, 6, 9), Paint()..color = const Color(0xFFE8E2D2));
    }
    final earthed = crew == M8Crew.earthed || crew == M8Crew.up;
    final base = g;
    // The tester and its display (live → dead → live).
    if (crew == M8Crew.testLive1 || crew == M8Crew.testDead || crew == M8Crew.testLive2) {
      final live = crew != M8Crew.testDead;
      final t = Rect.fromLTWH(cx - 78, base - 62, 52, 36);
      c.drawRRect(RRect.fromRectAndRadius(t, const Radius.circular(5)), Paint()..color = const Color(0xFF2F3A44));
      final s = Rect.fromLTWH(t.left + 5, t.top + 5, t.width - 10, 16);
      c.drawRRect(RRect.fromRectAndRadius(s, const Radius.circular(2)), Paint()..color = live ? const Color(0xFFFFE9A8) : const Color(0xFFB8F0C0));
      _text(c, live ? '230 V' : '0 V', s, const Color(0xFF1A2A1A));
      c.drawLine(Offset(t.right, t.top + 18), Offset(cx - 8, base - 70), Paint()
        ..color = const Color(0xFFC62828)
        ..strokeWidth = 2);
      c.drawLine(Offset(t.right, t.top + 24), Offset(cx - 8, base - 40), Paint()
        ..color = const Color(0xFF1C1C1C)
        ..strokeWidth = 2);
    }
    // The earth rod and its lead.
    if (earthed) {
      c.drawRect(Rect.fromLTWH(cx + 22, base - 6, 4, 22), Paint()..color = const Color(0xFF8A8F94));
      c.drawLine(Offset(cx + 24, base - 4), Offset(cx + 24, p.top + 22), Paint()
        ..color = const Color(0xFF3A8A3A)
        ..strokeWidth = 2.4);
      c.drawLine(Offset(cx + 24, p.top + 22), Offset(cx + 10, p.top + 30), Paint()
        ..color = const Color(0xFF3A8A3A)
        ..strokeWidth = 2.4);
    }
    // The crew: up at the cross-arm, or down at the foot.
    if (crew == M8Crew.up) _lineman(c, Offset(cx - 18, p.top + 40), up: true);
    if (crew == M8Crew.down || crew == M8Crew.earthOff) _lineman(c, Offset(cx - 34, base - 2), up: false);
  }

  void _lineman(Canvas c, Offset at, {required bool up}) {
    c.save();
    c.translate(at.dx, at.dy);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-7, -26, 14, 24), const Radius.circular(5)), Paint()..color = const Color(0xFF2E6FB0));
    c.drawCircle(const Offset(0, -33), 7, Paint()..color = const Color(0xFFC98E62));
    c.drawArc(const Rect.fromLTWH(-8, -42, 16, 12), math.pi, math.pi, true, Paint()..color = const Color(0xFFF2C230));
    if (up) {
      c.drawLine(const Offset(-3, -20), const Offset(-16, -34), Paint()
        ..color = const Color(0xFF2E6FB0)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round);
    } else {
      c.drawRect(const Rect.fromLTWH(-6, -2, 4, 10), Paint()..color = const Color(0xFF26303D));
      c.drawRect(const Rect.fromLTWH(2, -2, 4, 10), Paint()..color = const Color(0xFF26303D));
    }
    c.restore();
  }

  void _trainee(Canvas c, double g) {
    final x = geo.traineeX;
    c.save();
    c.translate(x, g + 2);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-8, -52, 16, 34), const Radius.circular(6)), Paint()..color = const Color(0xFF2E6FB0));
    c.drawRect(const Rect.fromLTWH(-7, -20, 5, 18), Paint()..color = const Color(0xFF26303D));
    c.drawRect(const Rect.fromLTWH(2, -20, 5, 18), Paint()..color = const Color(0xFF26303D));
    c.drawCircle(const Offset(0, -60), 9, Paint()..color = const Color(0xFFC98E62));
    c.drawArc(const Rect.fromLTWH(-10, -71, 20, 15), math.pi, math.pi, true, Paint()..color = const Color(0xFFF2C230));
    // The shirt pocket.
    c.drawRect(const Rect.fromLTWH(-6, -46, 8, 7), Paint()
      ..color = const Color(0xFF1C4A80)
      ..style = PaintingStyle.stroke);
    c.restore();
  }

  void _station(Canvas c) {
    final g = geo.ground;
    final sky = Rect.fromLTWH(0, 0, 360, g);
    c.drawRect(sky, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_skyTop, _skyLow]).createShader(sky));
    final ground = Rect.fromLTWH(0, g, 360, geo.height - g);
    c.drawRect(ground, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8A7A5E), Color(0xFF5E5240)]).createShader(ground));
    // The substation wall and its gate.
    final wall = Rect.fromLTWH(0, g - 150, 360, 150);
    c.drawRect(wall, Paint()..color = const Color(0xFFCDBFA3));
    c.drawRect(Rect.fromLTWH(0, g - 150, 360, 8), Paint()..color = const Color(0xFF8A7A5E));
    for (var x = 0.0; x < 360; x += 24) {
      c.drawLine(Offset(x, g - 142), Offset(x, g), Paint()
        ..color = const Color(0x14000000)
        ..strokeWidth = 1);
    }
    // Far: a gantry and a yard (soft-focus shapes, nothing readable).
    for (final x in [30.0, 70.0, 300.0]) {
      c.drawRect(Rect.fromLTWH(x, g - 214, 5, 66), Paint()..color = const Color(0xFF8A8F94));
      c.drawRect(Rect.fromLTWH(x - 14, g - 214, 34, 4), Paint()..color = const Color(0xFF6C7278));
    }
    // The window with the clerk.
    final w = Rect.fromLTWH(96, g - 118, 168, 84);
    c.drawRRect(RRect.fromRectAndRadius(w.inflate(6), const Radius.circular(6)), Paint()..color = const Color(0xFF4A3A2A));
    c.drawRect(w, Paint()..color = const Color(0xFF2B3A4E));
    final head = Offset(w.center.dx, w.top + 30);
    c.drawPath(
        Path()
          ..moveTo(w.center.dx - 34, w.bottom)
          ..quadraticBezierTo(w.center.dx - 32, w.top + 50, w.center.dx, w.top + 48)
          ..quadraticBezierTo(w.center.dx + 32, w.top + 50, w.center.dx + 34, w.bottom)
          ..close(),
        Paint()..color = const Color(0xFF8FB8DA));
    c.drawCircle(head, 15, Paint()..color = const Color(0xFFC98E62));
    c.drawArc(Rect.fromCircle(center: head.translate(0, -3), radius: 15), math.pi, math.pi, true, Paint()..color = const Color(0xFF2A1E18));
    c.drawRect(Rect.fromLTWH(w.left - 10, w.bottom, w.width + 20, 10), Paint()..color = const Color(0xFF9A6B42));
    // The door of the gate at the left.
    c.drawRect(Rect.fromLTWH(12, g - 100, 56, 100), Paint()..color = const Color(0xFF3A4A5A));
    c.drawRect(Rect.fromLTWH(280, g - 100, 60, 100), Paint()..color = const Color(0xFF3A4A5A));
  }

  void _text(Canvas c, String s, Rect r, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(r.center.dx - tp.width / 2, r.center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(M8WorldPainter old) => old.geo != geo || old.crew != crew || old.house != house || old.parts != parts || old.phoneOn != phoneOn || old.signed != signed;
}

/// The man at the house (a silent figure; the note and the hook coil are
/// widgets) or the angry consumer — same silhouette, other hair and shirt.
class M8ManPainter extends CustomPainter {
  const M8ManPainter({required this.angry});
  final bool angry;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width, h = size.height;
    final shirt = angry ? const Color(0xFFB4452E) : const Color(0xFF6A7A4A);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.2, h * 0.36, w * 0.6, h * 0.42), const Radius.circular(6)), Paint()..color = shirt);
    c.drawRect(Rect.fromLTWH(w * 0.24, h * 0.78, w * 0.2, h * 0.22), Paint()..color = const Color(0xFFE8E2D2));
    c.drawRect(Rect.fromLTWH(w * 0.56, h * 0.78, w * 0.2, h * 0.22), Paint()..color = const Color(0xFFE8E2D2));
    c.drawCircle(Offset(w * 0.5, h * 0.24), w * 0.22, Paint()..color = const Color(0xFFB87A52));
    c.drawArc(Rect.fromCircle(center: Offset(w * 0.5, h * 0.2), radius: w * 0.22), math.pi, math.pi, true, Paint()..color = const Color(0xFF2A1E18));
    if (angry) {
      final b = Paint()
        ..color = const Color(0xFF2A1E18)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      c.drawLine(Offset(w * 0.34, h * 0.2), Offset(w * 0.46, h * 0.23), b);
      c.drawLine(Offset(w * 0.66, h * 0.2), Offset(w * 0.54, h * 0.23), b);
    }
  }

  @override
  bool shouldRepaint(M8ManPainter old) => old.angry != angry;
}

/// The hook coil on the ground (a loop of thin wire on a spool).
class M8CoilPainter extends CustomPainter {
  const M8CoilPainter();

  @override
  void paint(Canvas c, Size size) {
    final r = Rect.fromLTWH(2, 2, size.width - 4, size.height - 4);
    for (var i = 0; i < 4; i++) {
      c.drawOval(r.deflate(i * 2.2), Paint()
        ..color = i.isEven ? const Color(0xFF1C1C1C) : const Color(0xFF55606A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6);
    }
  }

  @override
  bool shouldRepaint(M8CoilPainter old) => false;
}

/// A rupee note (plain green paper with a corner mark; no real design).
class M8NotePainter extends CustomPainter {
  const M8NotePainter();

  @override
  void paint(Canvas c, Size size) {
    final r = Offset.zero & size;
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), Paint()..shader = const LinearGradient(colors: [Color(0xFFB8D8A8), Color(0xFF8AB87A)]).createShader(r));
    c.drawRRect(
        RRect.fromRectAndRadius(r.deflate(3), const Radius.circular(2)),
        Paint()
          ..color = const Color(0xFF4A7A3A)
          ..style = PaintingStyle.stroke);
    c.drawCircle(r.center, size.height * 0.28, Paint()..color = const Color(0x554A7A3A));
  }

  @override
  bool shouldRepaint(M8NotePainter old) => false;
}

/// A signature scribble (the same for one [seed]).
class M8ScribblePainter extends CustomPainter {
  const M8ScribblePainter({required this.seed});
  final int seed;

  @override
  void paint(Canvas c, Size size) {
    final r = math.Random(seed);
    final path = Path();
    final y0 = size.height * 0.62;
    var x = size.width * 0.06;
    path.moveTo(x, y0);
    while (x < size.width * 0.9) {
      final dx = size.width * (0.06 + r.nextDouble() * 0.07);
      final up = size.height * (0.2 + r.nextDouble() * 0.3);
      path.cubicTo(x + dx * 0.2, y0 - up, x + dx * 0.8, y0 - up, x + dx, y0 + size.height * 0.06 * (r.nextDouble() - 0.3));
      x += dx;
    }
    c.drawPath(path, Paint()
      ..color = const Color(0xFF1A3A8A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(M8ScribblePainter old) => old.seed != seed;
}

/// The reading ruler: a soft band at the finger's height on the page.
class M8RulerPainter extends CustomPainter {
  const M8RulerPainter({required this.y, required this.count});
  final double? y;
  final int count;

  @override
  void paint(Canvas c, Size size) {
    final yy = y;
    if (yy == null) return;
    final r = Rect.fromLTWH(0, yy - 7, size.width, 14);
    c.drawRect(r, Paint()..color = const Color(0x55F2C230));
    c.drawRect(Rect.fromLTWH(r.left, r.top, 4, r.height), Paint()..color = const Color(0xFFC48A2E));
  }

  @override
  bool shouldRepaint(M8RulerPainter old) => old.y != y || old.count != count;
}

/// The deadly inset, in colour over the grey lane: the lineman at the cross-arm
/// on a line that was never made dead, the arc, the fall ([v] 0 → 1).
class M8InsetPainter extends CustomPainter {
  const M8InsetPainter({required this.rect, required this.v});
  final Rect rect;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final a = v.clamp(0.0, 1.0);
    final r = Rect.lerp(rect.deflate(30), rect, Curves.easeOutBack.transform(a))!;
    c.save();
    c.clipRRect(RRect.fromRectAndRadius(r, const Radius.circular(14)));
    c.drawRect(r, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF7FB6E6), Color(0xFFE7F0D8)]).createShader(r));
    c.drawRect(Rect.fromLTWH(r.left, r.bottom - 26, r.width, 26), Paint()..color = const Color(0xFF6E9A4A));
    final pole = Rect.fromLTWH(r.center.dx - 6, r.top + 26, 12, r.height - 40);
    c.drawRect(pole, Paint()..color = const Color(0xFF8A8F94));
    final arm = Rect.fromLTWH(r.center.dx - 70, r.top + 40, 140, 7);
    c.drawRect(arm, Paint()..color = const Color(0xFF5B6168));
    final wire = Paint()
      ..color = const Color(0xFF2A2A2A)
      ..strokeWidth = 2;
    for (final x in [arm.left + 8, arm.right - 8]) {
      c.drawLine(Offset(r.left, r.top + 34), Offset(x, arm.top - 2), wire);
      c.drawLine(Offset(x, arm.top - 2), Offset(r.right, r.top + 34), wire);
    }
    final fall = math.max(0.0, (a - 0.6) / 0.4);
    final man = Offset(r.center.dx + 22 + fall * 18, r.top + 70 + fall * 60);
    c.save();
    c.translate(man.dx, man.dy);
    c.rotate(fall * 0.9);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-8, -6, 16, 30), const Radius.circular(5)), Paint()..color = const Color(0xFF2E6FB0));
    c.drawCircle(const Offset(0, -14), 8, Paint()..color = const Color(0xFFC98E62));
    c.drawArc(const Rect.fromLTWH(-9, -24, 18, 14), math.pi, math.pi, true, Paint()..color = const Color(0xFFF2C230));
    c.drawLine(const Offset(-4, 0), const Offset(-20, -22), Paint()
      ..color = const Color(0xFF2E6FB0)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round);
    c.restore();
    if (a > 0.25) {
      final at = Offset(r.center.dx + 2, r.top + 46);
      final glow = Paint()..shader = const RadialGradient(colors: [Color(0xFFFFFFFF), Color(0xCCFFE066), Color(0x00FF8A00)]).createShader(Rect.fromCircle(center: at, radius: 40));
      c.drawCircle(at, 40 * math.min(1.0, (a - 0.25) * 3), glow);
      final bolt = Path()
        ..moveTo(at.dx - 2, at.dy - 4)
        ..lineTo(at.dx + 10, at.dy + 10)
        ..lineTo(at.dx + 2, at.dy + 12)
        ..lineTo(at.dx + 14, at.dy + 28);
      c.drawPath(bolt, Paint()
        ..color = const Color(0xFFFFF59D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3);
    }
    c.restore();
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(14)), Paint()
      ..color = const Color(0xFFF2C230)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(M8InsetPainter old) => old.v != v || old.rect != rect;
}
