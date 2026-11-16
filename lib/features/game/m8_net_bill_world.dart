import 'dart:math' as math;

import 'package:flutter/material.dart';

// The drawn world of lesson 8.8 কাজ "নেট মিটারের হিসাব" (m8_net_bill.dart):
// three solar houses on the walk, one at a time. Each visit is the same
// verandah: the roof with its panels, the meter box on the left wall (a small
// display and ONE push button that pages the display), an inverter box low on
// the wall, the consumer at the door, and the trainee's clipboard along the
// bottom edge (a widget on the page: the same blank slip every visit).
//
// The meter is either a bi-directional net meter (its pages: date, time, IMPORT
// and EXPORT kWh, in a dealt order, with an arrow on the two kWh pages) or an
// ordinary one (date, time and a single kWh page, no arrow; lesson 8.8 point 1).
// The light is the season: a low pale winter sun, a high bright summer sun
// (a banked visit is a winter one, a net-bill visit a summer one).
//
// Only words a worker reads are painted: 'kWh' on the meter, the wall and the
// door carry no caption. Code-drawn with gradients; no logo of any company
// (ruling M8-11).
//
// Design: 360 wide × the scene's height. The left strip (x < 124) carries the
// meter box and the inverter, so the guide's bubble (x 128 … 360, just above
// the clipboard) never hides the push button or the display; the right
// column (roof, caption, consumer) stays above the bubble.

/// The four kinds of visit (three are dealt a play).
enum M8Case { net, banked, ordinary, apply }

/// A page of the meter display.
enum M8Page { date, time, import, export, kwh }

/// The season's light.
enum M8Season { winter, summer }

/// How the consumer is drawn (clothes, hair) and the wall's colour.
const int kM8Looks = 4;

/// The meter's make (the box colour only; no brand mark).
const int kM8Makes = 3;

/// Where things are (design px, 360 wide).
@immutable
class M8Geo {
  const M8Geo._(this.height, this.clipTop);

  factory M8Geo.forScene(double height, double inset) => M8Geo._(height, height - clipH - inset * 0.6);

  final double height;

  /// The top of the clipboard.
  final double clipTop;

  static const double clipH = 212;
  static const double top = 148;

  /// The widest the slider goes (kW) and its step.
  static const double maxKw = 8;
  static const double stepKw = 0.5;

  // --- the clipboard -----------------------------------------------------------
  Rect get clip => Rect.fromLTWH(8, clipTop, 344, clipH - 6);

  /// The slip's top bar: drag from here to hand the slip over.
  Rect get handle => Rect.fromLTWH(8, clipTop, 250, 32);

  /// The flip corner (front / back of the slip).
  Rect get flip => Rect.fromLTWH(262, clipTop + 3, 88, 29);

  Rect get importLine => Rect.fromLTWH(16, clipTop + 56, 100, 22);
  Rect get exportLine => Rect.fromLTWH(16, clipTop + 82, 100, 22);

  /// The three roller digits of নেট ইউনিট (left = hundreds).
  Rect dig(int i) => Rect.fromLTWH(126 + 58.0 * i, clipTop + 50, 52, 56);
  Rect get digits => Rect.fromLTWH(126, clipTop + 50, 168, 56);

  Rect get billSeg => Rect.fromLTWH(16, clipTop + 112, 80, 40);
  Rect get bankSeg => Rect.fromLTWH(100, clipTop + 112, 80, 40);
  Rect get fixYes => Rect.fromLTWH(190, clipTop + 112, 76, 40);
  Rect get fixNo => Rect.fromLTWH(270, clipTop + 112, 76, 40);
  Rect get stamp => Rect.fromLTWH(16, clipTop + 158, 328, 40);

  /// Every control of the slip's front (the hand's sweep passes over all).
  List<Rect> get frontControls => [dig(0), dig(1), dig(2), billSeg, bankSeg, fixYes, fixNo, stamp, flip];

  // --- the application strip (the back) ------------------------------------------
  Rect get sanctionBox => Rect.fromLTWH(16, clipTop + 44, 156, 52);
  Rect get askedBox => Rect.fromLTWH(188, clipTop + 44, 156, 52);
  Rect get readout => Rect.fromLTWH(16, clipTop + 100, 328, 30);
  Rect get track => Rect.fromLTWH(34, clipTop + 152, 292, 8);

  double _kwX(double kw) => track.left + track.width * (kw / maxKw);

  /// The slider knob's touch box for a value.
  Rect knob(double kw) => Rect.fromCenter(center: Offset(_kwX(kw), track.center.dy), width: 46, height: 46);

  /// The slider value (0.5 kW steps) for a finger at [x].
  double kwAt(double x) => ((x - track.left) / track.width * maxKw / stepKw).round().clamp(0, (maxKw / stepKw).round()) * stepKw;

  // --- the scene ---------------------------------------------------------------
  Rect get meterBox => const Rect.fromLTWH(10, 158, 112, 150);
  Rect get display => const Rect.fromLTWH(19, 172, 94, 48);
  Rect get push => Rect.fromCenter(center: const Offset(66, 264), width: 48, height: 48);

  /// The inverter box low on the left wall (null when the screen is short).
  Rect? get inverter {
    final h = math.min(64.0, clipTop - 8 - 322);
    return h < 36 ? null : Rect.fromLTWH(10, 322, 112, h);
  }

  /// The consumer's feet stand here (above the guide's bubble).
  double get rightGround => math.max(clipTop - 170, 262);
  Rect get consumer {
    final h = math.min(150.0, rightGround - (top + 44));
    return Rect.fromLTRB(264, rightGround - h, 350, rightGround);
  }

  /// The consumer's line (a silent caption).
  Rect get caption => Rect.fromLTWH(128, top + 42, 134, (rightGround - (top + 42)).clamp(70.0, 104.0));

  /// The trainee on the verandah floor (null when the screen is too short to
  /// leave room under the consumer's caption).
  Rect? get trainee {
    final r = Rect.fromLTWH(140, rightGround - 106, 46, 106);
    return r.top >= caption.bottom + 2 ? r : null;
  }

  /// The slip is handed over when it is dropped here.
  Rect get handTarget => consumer.inflate(16);

  Rect get roof => const Rect.fromLTWH(0, top, 360, 38);
  Rect get panels => const Rect.fromLTWH(142, top + 3, 208, 32);

  @override
  bool operator ==(Object other) => other is M8Geo && other.height == height && other.clipTop == clipTop;

  @override
  int get hashCode => Object.hash(height, clipTop);
}

/// The season's sky: [top, horizon].
const Map<M8Season, List<Color>> kM8Skies = {
  M8Season.winter: [Color(0xFF9DB9CF), Color(0xFFE6EBEC), Color(0xFFF4EDDC)],
  M8Season.summer: [Color(0xFF55A2E0), Color(0xFFB4DBF5), Color(0xFFFFF1C9)],
};

Paint _fill(Color c) => Paint()..color = c;
Paint _stroke(Color c, double w) => Paint()
  ..color = c
  ..strokeWidth = w
  ..style = PaintingStyle.stroke
  ..strokeCap = StrokeCap.round;

/// The sky, the sun and the far rooftops (the same for every visit, so the
/// camera pan slides only the house over them).
class M8BackPainter extends CustomPainter {
  const M8BackPainter({required this.geo, required this.season});
  final M8Geo geo;
  final M8Season season;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final sky = kM8Skies[season]!;
    final r = Rect.fromLTWH(0, 0, w, size.height);
    c.drawRect(r, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: sky).createShader(r));
    // The sun: summer high and white-hot, winter low and pale.
    final sun = season == M8Season.summer ? const Offset(60, 108) : const Offset(40, 138);
    c.drawCircle(sun, season == M8Season.summer ? 36 : 28, _fill(season == M8Season.summer ? const Color(0x55FFE9A0) : const Color(0x44FFE4B5)));
    c.drawCircle(sun, season == M8Season.summer ? 20 : 15, _fill(season == M8Season.summer ? const Color(0xFFFFF3B0) : const Color(0xFFFFE9C4)));
    // Far rooftops and trees.
    final far = _fill(season == M8Season.summer ? const Color(0xFF9DB9C4) : const Color(0xFFB3BFC6));
    for (var i = 0; i < 9; i++) {
      final x = i * 44.0 - 8;
      final h = 26.0 + (i * 37 % 5) * 8;
      c.drawRect(Rect.fromLTWH(x, geo.clipTop - h - 14, 38, h + 14), far);
    }
    final tree = _fill(season == M8Season.summer ? const Color(0xFF6FA06A) : const Color(0xFF9DB19A));
    for (final x in [24.0, 150.0, 262.0, 340.0]) {
      c.drawCircle(Offset(x, geo.clipTop - 52), 20, tree);
    }
    // The ground in front of the verandah.
    final g = Rect.fromLTRB(0, geo.clipTop - 20, w, size.height);
    c.drawRect(g, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFB9A887), Color(0xFF8C8478)]).createShader(g));
  }

  @override
  bool shouldRepaint(M8BackPainter old) => old.geo != geo || old.season != season;
}

const List<Color> _walls = [Color(0xFFE9DDC3), Color(0xFFD9E3D4), Color(0xFFE8D2C8), Color(0xFFD6DDE8)];
const List<Color> _meterBodies = [Color(0xFFCFD3D6), Color(0xFFE4DDC8), Color(0xFFBFD0DC)];

/// One house: the wall, the roof with its panels, the meter box (body, display
/// glass and push button), the inverter and the consumer at the door.
class M8HousePainter extends CustomPainter {
  const M8HousePainter({required this.geo, required this.season, required this.make, required this.look, required this.bidirectional, required this.showConsumer});
  final M8Geo geo;
  final M8Season season;
  final int make;
  final int look;
  final bool bidirectional;
  final bool showConsumer;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    // The wall down to the ground.
    final wall = Rect.fromLTRB(0, M8Geo.top + 36, w, geo.clipTop - 18);
    c.drawRect(wall, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_walls[look % kM8Looks], Color.lerp(_walls[look % kM8Looks], const Color(0xFF7C6A55), 0.18)!]).createShader(wall));
    // The roof edge and the panels.
    final roof = geo.roof;
    c.drawRect(roof, _fill(const Color(0xFF8A5A44)));
    c.drawRect(Rect.fromLTWH(0, roof.bottom - 4, w, 5), _fill(const Color(0xFF5E3A2C)));
    _panels(c, geo.panels);
    // The door and the step (the consumer stands in it).
    final cons = geo.consumer;
    final door = Rect.fromLTRB(cons.left - 6, cons.top - 12, cons.right + 4, geo.rightGround + 8);
    c.drawRRect(RRect.fromRectAndRadius(door, const Radius.circular(3)), _fill(const Color(0xFF4A3426)));
    c.drawRRect(RRect.fromRectAndRadius(door.deflate(5), const Radius.circular(2)), _fill(const Color(0xFF2C2118)));
    c.drawRect(Rect.fromLTRB(door.left - 8, door.bottom - 4, door.right + 8, door.bottom + 4), _fill(const Color(0xFFB7B0A2)));
    _meter(c);
    final inv = geo.inverter;
    if (inv != null) _inverter(c, inv);
    if (showConsumer) _consumer(c, geo.consumer);
    // The verandah rail on the right, under the figure.
    final rail = _stroke(const Color(0xFF6B4A36), 3);
    c.drawLine(Offset(130, geo.rightGround + 4), Offset(w - 6, geo.rightGround + 4), rail);
  }

  void _panels(Canvas c, Rect r) {
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), _fill(const Color(0xFF9AA0A6)));
    const cols = 6;
    const rows = 2;
    final cw = (r.width - 8) / cols;
    final ch = (r.height - 6) / rows;
    for (var i = 0; i < cols; i++) {
      for (var j = 0; j < rows; j++) {
        final cell = Rect.fromLTWH(r.left + 4 + i * cw + 1, r.top + 3 + j * ch + 1, cw - 2, ch - 2);
        c.drawRect(cell, Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF2B4F8A), Color(0xFF15305E)]).createShader(cell));
        c.drawLine(Offset(cell.center.dx, cell.top), Offset(cell.center.dx, cell.bottom), _stroke(const Color(0x66A9C4EE), 0.6));
        c.drawLine(Offset(cell.left, cell.center.dy), Offset(cell.right, cell.center.dy), _stroke(const Color(0x66A9C4EE), 0.6));
      }
    }
    // A glint of sun.
    c.drawLine(Offset(r.left + 14, r.top + 6), Offset(r.left + 40, r.top + 6), _stroke(const Color(0x66FFFFFF), 1.4));
  }

  void _meter(Canvas c) {
    final b = geo.meterBox;
    final body = _meterBodies[make % kM8Makes];
    c.drawRRect(RRect.fromRectAndRadius(b.shift(const Offset(0, 3)), const Radius.circular(10)), _fill(const Color(0x44000000)));
    c.drawRRect(
      RRect.fromRectAndRadius(b, const Radius.circular(10)),
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.lerp(body, Colors.white, 0.35)!, body, Color.lerp(body, const Color(0xFF59616A), 0.3)!]).createShader(b),
    );
    c.drawRRect(RRect.fromRectAndRadius(b.deflate(1), const Radius.circular(9)), _stroke(const Color(0xFF59616A), 1.2));
    // The display glass.
    final d = geo.display;
    c.drawRRect(RRect.fromRectAndRadius(d.inflate(3), const Radius.circular(6)), _fill(const Color(0xFF39414A)));
    // A row of little screws and a vent.
    for (final x in [b.left + 9, b.right - 9]) {
      c.drawCircle(Offset(x, b.top + 9), 2.2, _fill(const Color(0xFF8B939A)));
      c.drawCircle(Offset(x, b.bottom - 9), 2.2, _fill(const Color(0xFF8B939A)));
    }
    // The push button.
    final p = geo.push.center;
    c.drawCircle(p, 20, _fill(const Color(0xFF59616A)));
    c.drawCircle(p, 17, Paint()..shader = const RadialGradient(colors: [Color(0xFFF2C94C), Color(0xFFC9951A)], center: Alignment(-0.3, -0.3)).createShader(Rect.fromCircle(center: p, radius: 17)));
    c.drawCircle(p, 17, _stroke(const Color(0xFF7A5A10), 1.2));
    // The meter's two terminals at the foot (a bi-directional one has a second pair).
    c.drawRect(Rect.fromLTWH(b.left + 24, b.bottom - 7, 10, 7), _fill(const Color(0xFF3B4147)));
    c.drawRect(Rect.fromLTWH(b.right - 34, b.bottom - 7, 10, 7), _fill(const Color(0xFF3B4147)));
    // The service wire to the roof.
    c.drawLine(Offset(b.center.dx, b.top), Offset(b.center.dx, M8Geo.top + 30), _stroke(const Color(0xFF2C2C2C), 2));
  }

  void _inverter(Canvas c, Rect r) {
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(7)), Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFEDEFF1), Color(0xFFB9BFC4)]).createShader(r));
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(7)), _stroke(const Color(0xFF59616A), 1.2));
    // Cooling fins and a small status lamp.
    for (var i = 0; i < 4; i++) {
      c.drawLine(Offset(r.left + 12, r.bottom - 12 - i * 5), Offset(r.right - 12, r.bottom - 12 - i * 5), _stroke(const Color(0xFF8B939A), 1.4));
    }
    c.drawCircle(Offset(r.right - 12, r.top + 10), 3.4, _fill(const Color(0xFF3FB950)));
    c.drawLine(Offset(r.center.dx, r.top), Offset(r.center.dx, geo.meterBox.bottom), _stroke(const Color(0xFF2C2C2C), 2));
  }

  void _consumer(Canvas c, Rect r) {
    final k = look % kM8Looks;
    final cx = r.center.dx;
    final feet = r.bottom;
    final hgt = r.height;
    final u = hgt / 150.0;
    final skin = const [Color(0xFFD9A57A), Color(0xFFC98E62), Color(0xFFE2B58C), Color(0xFFB87D55)][k];
    final cloth = const [Color(0xFFB5413A), Color(0xFF2F6E5C), Color(0xFFD1962B), Color(0xFF3C5A99)][k];
    final dark = Color.lerp(cloth, Colors.black, 0.28)!;
    final hair = const Color(0xFF2B2018);
    // Legs and body.
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(cx - 16 * u, feet - 52 * u, cx - 3 * u, feet), Radius.circular(4 * u)), _fill(dark));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(cx + 3 * u, feet - 52 * u, cx + 16 * u, feet), Radius.circular(4 * u)), _fill(dark));
    final torso = Rect.fromLTRB(cx - 22 * u, feet - 112 * u, cx + 22 * u, feet - 46 * u);
    c.drawRRect(RRect.fromRectAndRadius(torso, Radius.circular(12 * u)), _fill(cloth));
    if (season == M8Season.winter) {
      // A shawl over the shoulders.
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(cx - 26 * u, feet - 114 * u, cx + 26 * u, feet - 84 * u), Radius.circular(12 * u)), _fill(const Color(0xFF8D8A86)));
      c.drawLine(Offset(cx - 22 * u, feet - 96 * u), Offset(cx + 22 * u, feet - 96 * u), _stroke(const Color(0x66FFFFFF), 1.2));
    }
    // Arms.
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(cx - 30 * u, feet - 108 * u, cx - 20 * u, feet - 62 * u), Radius.circular(5 * u)), _fill(cloth));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(cx + 20 * u, feet - 108 * u, cx + 30 * u, feet - 62 * u), Radius.circular(5 * u)), _fill(cloth));
    c.drawCircle(Offset(cx - 25 * u, feet - 58 * u), 5 * u, _fill(skin));
    c.drawCircle(Offset(cx + 25 * u, feet - 58 * u), 5 * u, _fill(skin));
    // Head.
    final head = Offset(cx, feet - 128 * u);
    c.drawCircle(head, 15 * u, _fill(skin));
    switch (k) {
      case 0:
        c.drawArc(Rect.fromCircle(center: head, radius: 15.5 * u), math.pi, math.pi, true, _fill(hair));
      case 1:
        // A cap.
        c.drawArc(Rect.fromCircle(center: head, radius: 15.5 * u), math.pi, math.pi, true, _fill(const Color(0xFFEFE9DA)));
        c.drawRect(Rect.fromLTRB(cx - 16 * u, head.dy - 3 * u, cx + 16 * u, head.dy), _fill(const Color(0xFFEFE9DA)));
      case 2:
        // Hair in a bun.
        c.drawArc(Rect.fromCircle(center: head, radius: 15.5 * u), math.pi * 0.9, math.pi * 1.2, true, _fill(hair));
        c.drawCircle(Offset(cx, head.dy - 17 * u), 6 * u, _fill(hair));
      default:
        // Grey hair, a moustache.
        c.drawArc(Rect.fromCircle(center: head, radius: 15.5 * u), math.pi, math.pi, true, _fill(const Color(0xFF9A9894)));
        c.drawLine(Offset(cx - 6 * u, head.dy + 5 * u), Offset(cx + 6 * u, head.dy + 5 * u), _stroke(const Color(0xFF3A332C), 2 * u));
    }
    // Eyes.
    c.drawCircle(Offset(cx - 5 * u, head.dy - 1 * u), 1.5 * u, _fill(const Color(0xFF1B1B1B)));
    c.drawCircle(Offset(cx + 5 * u, head.dy - 1 * u), 1.5 * u, _fill(const Color(0xFF1B1B1B)));
  }

  @override
  bool shouldRepaint(M8HousePainter old) =>
      old.geo != geo || old.season != season || old.make != make || old.look != look || old.bidirectional != bidirectional || old.showConsumer != showConsumer;
}
