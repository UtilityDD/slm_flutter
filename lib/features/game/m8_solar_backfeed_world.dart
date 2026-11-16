import 'dart:math' as math;

import 'package:flutter/material.dart';

// The drawn world of lesson 8.8 কাজ "ছাদে সূর্য, লাইনে বিপদ" (m8_solar_backfeed.dart):
// a narrow residential lane at midday, wider than the screen (600 design px
// on a 360 px view: swipe to pan). Two rows of two-storey flat-roof houses
// (the back row smaller, up the lane), a PCC LT pole at the lane mouth with a
// fuse board of 6-8 unlabelled carriers and a service cable crossing the lane
// to every house, the trainee at the pole's foot with a ladder lying by him
// and a belt pouch, the DTR at the far right end of the lane: the WBSEDCL one,
// an AB switch with three blades seen open, its handle locked and tagged
// 'শাটডাউন', and HG fuses (ruling M8-19; no DO fuses).
//
// Every house looks alike in kind: roofs carry decoys (a blue tarp, a skylight,
// a row of tanks) and clutter (a tank, a clothesline, an aerial); solar roofs
// carry panels in plain view, or only low behind the parapet (seen by holding
// the roof), or none in sight at all (a clue on the meter box or the pole
// carrier is then all there is). A meter box hangs on every wall; some wear a
// green sticker; the net meter (Import / Export pages, arrows) differs from an
// ordinary meter only once the box is zoomed.
//
// Nothing here marks a right answer: no ring, no count, no label on a house or
// a carrier. Only words a worker reads are painted: 'শাটডাউন' on the DTR's
// tag, '11 kV' on its tank. Code-drawn with gradients.
//
// Design: 360 wide x the scene's height; the world is [M8Geo.worldW] wide.

/// What a solar house shows.
enum M8Clue { panelsLane, panelsParapet, stickerBox, stickerCarrier, netMeter }

/// A look-alike on a roof of a house with no solar.
enum M8Decoy { none, tarp, skylight, tanks }

/// What a reason asks about.
enum M8WhyKind { backfeed, clue, climb }

/// The faulty inverter of the death scene (a looks-only detail).
enum M8Fault { relayStuck, noAntiIsland, running }

/// One dealt house (a site of the eight).
@immutable
class M8House {
  const M8House({
    required this.site,
    required this.solar,
    required this.slot,
    required this.sag,
    required this.mirror,
    required this.palette,
    required this.clutter,
    this.clues = const {},
    this.decoy = M8Decoy.none,
  });

  /// 0-3 the front row (left, left, right, right), 4-7 the back row.
  final int site;
  final bool solar;
  final Set<M8Clue> clues;
  final M8Decoy decoy;

  /// The carrier slot on the pole board this house's service cable ends at.
  final int slot;

  /// How far the cable sags (design px).
  final double sag;

  /// Door and meter box swap sides.
  final bool mirror;
  final int palette;

  /// 0 none, 1 a small tank, 2 a clothesline, 3 an aerial.
  final int clutter;

  bool get panelsLane => clues.contains(M8Clue.panelsLane);
  bool get panelsParapet => clues.contains(M8Clue.panelsParapet);
  bool get stickerBox => clues.contains(M8Clue.stickerBox);
  bool get stickerCarrier => clues.contains(M8Clue.stickerCarrier);
  bool get netMeter => clues.contains(M8Clue.netMeter);

  /// Known only by a sticker or the net meter (no panel to see).
  bool get nonRoofOnly => solar && !panelsLane && !panelsParapet;
}

/// The dealt lane.
@immutable
class M8SolarDeal {
  const M8SolarDeal({required this.houses, required this.fault, required this.light});

  /// In site order.
  final List<M8House> houses;
  final M8Fault fault;
  final int light;

  int get n => houses.length;

  /// Rows of the pole board (two carriers a row).
  int get rows => (n + 1) ~/ 2;

  Iterable<M8House> get solarHouses => houses.where((h) => h.solar);

  M8House? at(int site) {
    for (final h in houses) {
      if (h.site == site) return h;
    }
    return null;
  }
}

/// Where everything stands (design px; the world is [worldW] wide).
class M8Geo {
  const M8Geo._(this.height, this.groundY);

  factory M8Geo.forScene(double height, double inset) => M8Geo._(height, math.max(height - 200 - inset * 0.6, 400.0));

  final double height;

  /// The front row's foot line and the pole's base (the guide's bubble and
  /// the header stay clear of the houses above it).
  final double groundY;

  static const double worldW = 600;
  static const double poleX = 300;
  static const double camMax = worldW - 360;
  static const double camStart = 120;

  static const _sites = <(double, double, bool)>[
    (14, 100, true),
    (120, 100, true),
    (380, 100, true),
    (486, 100, true),
    (48, 92, false),
    (146, 92, false),
    (362, 92, false),
    (460, 92, false),
  ];

  static bool isFront(int site) => site < 4;
  static bool isLeft(int site) => site == 0 || site == 1 || site == 4 || site == 5;

  double _bottom(int site) => isFront(site) ? groundY : groundY - 146;
  double _h(int site) => isFront(site) ? 128 : 96;

  /// A house's wall.
  Rect house(int site) {
    final (x, w, _) = _sites[site];
    final b = _bottom(site);
    return Rect.fromLTRB(x, b - _h(site), x + w, b);
  }

  /// Hold here to look over the parapet.
  Rect roof(int site) {
    final r = house(site);
    return Rect.fromLTRB(r.left - 4, r.top - 30, r.right + 4, r.top + 14);
  }

  Rect door(int site, bool mirror) {
    final r = house(site);
    return Rect.fromLTWH(mirror ? r.right - 36 : r.left + 12, r.bottom - 40, 24, 40);
  }

  Rect meter(int site, bool mirror) {
    final r = house(site);
    return Rect.fromLTWH(mirror ? r.left + 12 : r.right - 36, r.bottom - (isFront(site) ? 78 : 66), 24, 30);
  }

  /// The wall clip a service cable ends at, on the wall facing the pole.
  Offset bracket(int site) {
    final r = house(site);
    return Offset(isLeft(site) ? r.right - 5 : r.left + 5, r.top + 26);
  }

  Rect boardOf(int rows) => Rect.fromLTWH(258, groundY - 236, 84, rows * 34 + 14);

  Rect slot(int slot) => Rect.fromLTWH(262 + (slot % 2) * 40.0, groundY - 228 + (slot ~/ 2) * 34.0, 36, 30);

  Offset terminal(int slot) {
    final r = this.slot(slot);
    return Offset(r.center.dx, r.bottom + 1);
  }

  /// A house's service cable, bracket first, then to its carrier (36 points).
  List<Offset> cable(M8House h) {
    final a = bracket(h.site);
    final b = terminal(h.slot);
    final ctl = Offset((a.dx + b.dx) / 2, math.max(a.dy, b.dy) + h.sag);
    return [
      for (var i = 0; i <= 35; i++)
        () {
          final t = i / 35;
          final u = 1 - t;
          return Offset(u * u * a.dx + 2 * u * t * ctl.dx + t * t * b.dx, u * u * a.dy + 2 * u * t * ctl.dy + t * t * b.dy);
        }(),
    ];
  }

  Rect get pole => Rect.fromLTWH(poleX - 5, groundY - 266, 10, 294);

  /// Drop the ladder here to climb.
  Rect get poleDrop => Rect.fromLTWH(poleX - 34, groundY - 270, 68, 322);

  Rect get trainee => Rect.fromLTWH(226, groundY - 42, 46, 106);
  Rect get pouch => Rect.fromLTWH(262, groundY + 22, 30, 30);

  /// The ladder lying by the pole's foot.
  Rect get ladder => Rect.fromLTWH(70, groundY + 56, 124, 20);

  Offset get sun => Offset(440, math.max(groundY - 330, 104));

  Rect get dtr => Rect.fromCenter(center: Offset(520, groundY - 290), width: 70, height: 56);

  /// The trainee's hand on the ladder at the pole (the death scene).
  Offset get handAt => Offset(poleX - 8, groundY - 168);
}

Paint _fill(Color c) => Paint()..color = c;
Paint _stroke(Color c, double w) => Paint()
  ..color = c
  ..strokeWidth = w
  ..style = PaintingStyle.stroke
  ..strokeCap = StrokeCap.round;

void _text(Canvas c, String text, Offset centre, {double size = 7, Color color = const Color(0xFF26303D), FontWeight weight = FontWeight.w800, double maxWidth = 80}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: weight, color: color, height: 1.0)),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  )..layout(maxWidth: maxWidth);
  tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
}

const _skies = <(Color, Color)>[
  (Color(0xFF8CC4EA), Color(0xFFE4F2FA)),
  (Color(0xFFB4D2E2), Color(0xFFF6ECD8)),
  (Color(0xFF74B2E4), Color(0xFFD6EAF6)),
];

const _walls = <(Color, Color)>[
  (Color(0xFFF0E4CA), Color(0xFFD9C9A6)),
  (Color(0xFFE8C6BC), Color(0xFFCFA396)),
  (Color(0xFFD0E1C4), Color(0xFFABC49B)),
  (Color(0xFFC6D9E9), Color(0xFF9DB7CF)),
  (Color(0xFFE8D090), Color(0xFFCDB06A)),
];

// ============================================================================
// Roofs
// ============================================================================

void _panelsLane(Canvas c, Rect a) {
  final pw = (a.width - 10) / 3;
  for (var i = 0; i < 3; i++) {
    final x = a.left + 2 + i * (pw + 3);
    final p = Path()
      ..moveTo(x, a.bottom)
      ..lineTo(x + pw, a.bottom)
      ..lineTo(x + pw - 5, a.top + 4)
      ..lineTo(x + 5, a.top + 4)
      ..close();
    c.drawPath(p, _fill(const Color(0xFF1F3C7C)));
    final g = _stroke(const Color(0xFF6A8FD4), 0.7);
    for (var k = 1; k < 3; k++) {
      final t = k / 3;
      c.drawLine(Offset(x + t * pw, a.bottom), Offset(x + 5 + t * (pw - 10), a.top + 4), g);
    }
    c.drawLine(Offset(x + 2.5, (a.bottom + a.top + 4) / 2), Offset(x + pw - 2.5, (a.bottom + a.top + 4) / 2), g);
    c.drawPath(p, _stroke(const Color(0xFFC9D2DA), 1.1));
  }
}

void _tarp(Canvas c, Rect a) {
  final p = Path()
    ..moveTo(a.left + 6, a.bottom)
    ..lineTo(a.right - 4, a.bottom)
    ..lineTo(a.right - 14, a.top + 5)
    ..lineTo(a.left + 18, a.top + 3)
    ..close();
  c.drawPath(p, _fill(const Color(0xFF63AEE8)));
  final w = _stroke(const Color(0xFF3F86BF), 0.9);
  c.drawLine(Offset(a.left + 22, a.bottom - 1), Offset(a.left + 30, a.top + 5), w);
  c.drawLine(Offset(a.center.dx, a.bottom - 1), Offset(a.center.dx + 6, a.top + 5), w);
  c.drawLine(Offset(a.right - 22, a.bottom - 1), Offset(a.right - 20, a.top + 5), w);
  for (final o in [Offset(a.left + 8, a.bottom - 3), Offset(a.right - 7, a.bottom - 3), Offset(a.center.dx, a.top + 5)]) {
    c.drawCircle(o, 1.6, _fill(const Color(0xFFF4F4F0)));
  }
}

void _skylight(Canvas c, Rect a) {
  final r = Rect.fromCenter(center: a.center + const Offset(0, 4), width: math.min(54, a.width - 12), height: a.height - 6);
  c.drawRect(r, _fill(const Color(0xFFD6F0FA)));
  c.drawRect(r, _stroke(const Color(0xFF8FA0AB), 1.3));
  c.drawLine(Offset(r.center.dx, r.top), Offset(r.center.dx, r.bottom), _stroke(const Color(0xFF8FA0AB), 0.9));
  c.drawLine(Offset(r.left, r.center.dy), Offset(r.right, r.center.dy), _stroke(const Color(0xFF8FA0AB), 0.9));
  c.drawLine(r.topLeft + const Offset(3, 3), r.topLeft + const Offset(10, 3), _stroke(const Color(0xCCFFFFFF), 1.2));
}

void _tank(Canvas c, Rect r) {
  final body = RRect.fromRectAndRadius(r, const Radius.circular(3));
  c.drawRRect(body, _fill(const Color(0xFF2A2C31)));
  c.drawRect(Rect.fromLTWH(r.left + 2, r.top + 3, 2.2, r.height - 6), _fill(const Color(0x55FFFFFF)));
  c.drawOval(Rect.fromLTWH(r.left, r.top - 3, r.width, 6), _fill(const Color(0xFF40434A)));
}

void _tanks(Canvas c, Rect a) {
  for (var i = 0; i < 3; i++) {
    _tank(c, Rect.fromLTWH(a.left + 6 + i * ((a.width - 12) / 3), a.top + 6, (a.width - 12) / 3 - 4, a.height - 6));
  }
}

void _clutter(Canvas c, Rect a, int k, int salt) {
  switch (k) {
    case 1:
      _tank(c, Rect.fromLTWH(a.left + 8 + (salt % 3) * 18, a.top + 8, 18, a.height - 8));
    case 2:
      final y = a.top + 6;
      c.drawLine(Offset(a.left + 6, a.bottom), Offset(a.left + 6, y), _stroke(const Color(0xFF6B6F76), 1.4));
      c.drawLine(Offset(a.right - 6, a.bottom), Offset(a.right - 6, y), _stroke(const Color(0xFF6B6F76), 1.4));
      c.drawLine(Offset(a.left + 6, y), Offset(a.right - 6, y), _stroke(const Color(0xFF8A8D93), 0.8));
      const cols = [Color(0xFFD94A4A), Color(0xFFF2C94C), Color(0xFFEFEFEF), Color(0xFF4A8BD9)];
      for (var i = 0; i < 3; i++) {
        c.drawRect(Rect.fromLTWH(a.left + 16 + i * 17, y, 11, 9 + (i + salt) % 3 * 2), _fill(cols[(i + salt) % cols.length]));
      }
    case 3:
      final x = a.left + 14 + (salt % 4) * 16;
      c.drawLine(Offset(x, a.bottom), Offset(x, a.top + 2), _stroke(const Color(0xFF7C8088), 1.3));
      c.drawLine(Offset(x - 8, a.top + 6), Offset(x + 8, a.top + 6), _stroke(const Color(0xFF7C8088), 1.1));
      c.drawLine(Offset(x - 5, a.top + 11), Offset(x + 5, a.top + 11), _stroke(const Color(0xFF7C8088), 1.1));
  }
}

/// A roof as seen from the lane (above the parapet).
void _laneRoof(Canvas c, Rect wall, M8House h) {
  final a = Rect.fromLTRB(wall.left + 6, wall.top - 26, wall.right - 6, wall.top - 2);
  if (h.panelsLane) {
    _panelsLane(c, a);
  } else if (h.decoy == M8Decoy.tarp) {
    _tarp(c, a);
  } else if (h.decoy == M8Decoy.skylight) {
    _skylight(c, a);
  } else if (h.decoy == M8Decoy.tanks) {
    _tanks(c, a);
  } else {
    _clutter(c, a, h.clutter, h.site);
  }
}

// ============================================================================
// The static world
// ============================================================================

/// The whole lane: sky, far roofs, the DTR, ground, houses, cables, the pole.
class M8WorldPainter extends CustomPainter {
  const M8WorldPainter({required this.geo, required this.deal});
  final M8Geo geo;
  final M8SolarDeal deal;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final sky = _skies[deal.light % _skies.length];
    c.drawRect(
      Rect.fromLTWH(0, 0, M8Geo.worldW, g.groundY + 90),
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [sky.$1, sky.$2]).createShader(Rect.fromLTWH(0, 0, 1, g.groundY)),
    );
    _sun(c, g.sun);
    _farRoofs(c, g);
    _dtr(c, g);
    _ground(c, g, size);
    for (var s = 0; s < 8; s++) {
      final h = deal.at(s);
      if (h == null) {
        _vacant(c, g, s);
      } else {
        _houseArt(c, g, h);
      }
    }
    for (final h in deal.houses) {
      _cable(c, g, h);
    }
    _pole(c, g);
  }

  void _sun(Canvas c, Offset o) {
    c.drawCircle(o, 54, Paint()..shader = const RadialGradient(colors: [Color(0x66FFE9A6), Color(0x00FFE9A6)]).createShader(Rect.fromCircle(center: o, radius: 54)));
    c.drawCircle(o, 22, _fill(const Color(0xFFFFE27A)));
    c.drawCircle(o, 16, _fill(const Color(0xFFFFF3B8)));
  }

  void _farRoofs(Canvas c, M8Geo g) {
    final base = g.groundY - 236;
    final p = Path()..moveTo(0, base + 60);
    var x = 0.0;
    var i = 0;
    while (x < M8Geo.worldW + 40) {
      final h = 22 + (i * 37 % 5) * 7.0;
      p
        ..lineTo(x, base + 60 - h)
        ..lineTo(x + 34, base + 60 - h);
      x += 34;
      i++;
    }
    p
      ..lineTo(M8Geo.worldW, base + 60)
      ..close();
    c.drawPath(p, _fill(const Color(0xFF9DB1C0)));
    final q = Path()..moveTo(0, base + 70);
    x = 10;
    i = 3;
    while (x < M8Geo.worldW + 40) {
      final h = 14 + (i * 53 % 4) * 6.0;
      q
        ..lineTo(x, base + 70 - h)
        ..lineTo(x + 28, base + 70 - h);
      x += 28;
      i++;
    }
    q
      ..lineTo(M8Geo.worldW, base + 70)
      ..close();
    c.drawPath(q, _fill(const Color(0xFF86998A)));
  }

  /// The DTR at the lane's far end: AB switch open (three blades seen), handle
  /// locked and tagged, HG fuses (M8-19).
  void _dtr(Canvas c, M8Geo g) {
    final r = g.dtr;
    // The double pole.
    for (final dx in [-24.0, 24.0]) {
      c.drawRect(Rect.fromLTWH(r.center.dx + dx - 2.5, r.top + 6, 5, r.height + 18), _fill(const Color(0xFF9A9CA0)));
    }
    c.drawRect(Rect.fromLTWH(r.left - 6, r.top + 22, r.width + 12, 4), _fill(const Color(0xFF7A7C80)));
    // The tank, with its plate.
    final tank = Rect.fromLTWH(r.center.dx - 17, r.top + 28, 34, 26);
    c.drawRRect(RRect.fromRectAndRadius(tank, const Radius.circular(3)), _fill(const Color(0xFF55606B)));
    c.drawRect(Rect.fromLTWH(tank.left + 7, tank.top + 8, 20, 9), _fill(const Color(0xFFE9EDF0)));
    _text(c, '11 kV', Offset(tank.center.dx, tank.top + 12.5), size: 5.4, maxWidth: 24);
    // The AB switch: three blades open, in a row on the crossarm.
    for (var i = 0; i < 3; i++) {
      final x = r.left + 8 + i * 27.0;
      c.drawRect(Rect.fromLTWH(x - 1, r.top + 14, 2.4, 9), _fill(const Color(0xFFD9D9DC)));
      c.drawLine(Offset(x + 0.2, r.top + 14), Offset(x + 7, r.top + 2), _stroke(const Color(0xFFE6E8EA), 1.7));
      c.drawCircle(Offset(x + 0.2, r.top + 14), 1.7, _fill(const Color(0xFF6B6F76)));
      // The HG fuse below.
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 2.5, r.top + 24, 5, 9), const Radius.circular(1.5)), _fill(const Color(0xFFB8452F)));
    }
    // The locked handle and the tag.
    c.drawLine(Offset(r.left + 2, r.top + 24), Offset(r.left + 2, r.bottom + 10), _stroke(const Color(0xFF4F5258), 1.6));
    c.drawCircle(Offset(r.left + 2, r.bottom + 4), 2.6, _fill(const Color(0xFFE9C46A)));
    final tag = Rect.fromLTWH(r.left - 10, r.bottom + 6, 40, 12);
    c.drawRRect(RRect.fromRectAndRadius(tag, const Radius.circular(2)), _fill(const Color(0xFFF4DD6B)));
    _text(c, 'শাটডাউন', tag.center, size: 6.6, maxWidth: 38);
  }

  void _ground(Canvas c, M8Geo g, Size size) {
    final top = g.groundY - 252;
    c.drawRect(Rect.fromLTRB(0, top, M8Geo.worldW, g.groundY - 146), _fill(const Color(0xFFB7BFA2)));
    // The lane between the rows.
    c.drawRect(Rect.fromLTRB(0, g.groundY - 146, M8Geo.worldW, g.groundY - 128), _fill(const Color(0xFF9A9892)));
    c.drawRect(Rect.fromLTRB(0, g.groundY - 128, M8Geo.worldW, g.groundY), _fill(const Color(0xFFB7BFA2)));
    // The pavement and the road in front.
    c.drawRect(Rect.fromLTRB(0, g.groundY, M8Geo.worldW, g.groundY + 40), _fill(const Color(0xFFC9C3B4)));
    c.drawRect(Rect.fromLTRB(0, g.groundY + 40, M8Geo.worldW, size.height + 60), _fill(const Color(0xFF8D8C88)));
    c.drawLine(Offset(0, g.groundY + 40), Offset(M8Geo.worldW, g.groundY + 40), _stroke(const Color(0xFF6E6D69), 1.4));
  }

  void _vacant(Canvas c, M8Geo g, int s) {
    final r = g.house(s);
    c.drawRect(Rect.fromLTRB(r.left, r.bottom - 14, r.right, r.bottom), _fill(const Color(0xFFB9B2A0)));
    c.drawRect(Rect.fromLTRB(r.left, r.bottom - 14, r.right, r.bottom - 11), _fill(const Color(0xFF9C9686)));
    final tx = r.center.dx + (s.isEven ? -10 : 12);
    c.drawRect(Rect.fromLTWH(tx - 2, r.bottom - 40, 4, 28), _fill(const Color(0xFF6B4F35)));
    c.drawCircle(Offset(tx, r.bottom - 48), 15, _fill(const Color(0xFF5E8C4F)));
    c.drawCircle(Offset(tx + 8, r.bottom - 42), 10, _fill(const Color(0xFF6FA25D)));
  }

  void _houseArt(Canvas c, M8Geo g, M8House h) {
    final r = g.house(h.site);
    final pal = _walls[h.palette % _walls.length];
    c.drawRect(
      r,
      Paint()..shader = LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [pal.$1, pal.$2]).createShader(r),
    );
    // Parapet.
    c.drawRect(Rect.fromLTRB(r.left - 3, r.top - 5, r.right + 3, r.top + 4), _fill(const Color(0xFFB9B3A6)));
    c.drawRect(Rect.fromLTRB(r.left - 3, r.top + 4, r.right + 3, r.top + 6), _fill(const Color(0x33000000)));
    _laneRoof(c, r, h);
    // Floor line and windows.
    final storeys = M8Geo.isFront(h.site) ? 2 : 1;
    if (storeys == 2) c.drawRect(Rect.fromLTRB(r.left, r.top + 62, r.right, r.top + 65), _fill(const Color(0x22000000)));
    final win = h.mirror ? [r.left + 52, r.left + 20] : [r.left + 20, r.left + 52];
    for (var i = 0; i < 2; i++) {
      final wr = Rect.fromLTWH(win[i], r.top + 34, 18, 20);
      _window(c, wr);
      if (storeys == 2 && i == 0) _window(c, Rect.fromLTWH(win[i] + (h.mirror ? 22 : 28), r.top + 74, 14, 18));
    }
    // The door.
    final d = g.door(h.site, h.mirror);
    c.drawRect(d, _fill(const Color(0xFF6A4A33)));
    c.drawRect(d.deflate(3), _fill(const Color(0xFF7D5A41)));
    c.drawCircle(Offset(d.right - 5, d.center.dy), 1.4, _fill(const Color(0xFFE9C46A)));
    // The meter box (alike from the lane; a sticker shows as a green patch).
    final m = g.meter(h.site, h.mirror);
    c.drawRRect(RRect.fromRectAndRadius(m, const Radius.circular(2.5)), _fill(const Color(0xFFB8BDC2)));
    c.drawRRect(RRect.fromRectAndRadius(m, const Radius.circular(2.5)), _stroke(const Color(0xFF6C7278), 1));
    c.drawRect(Rect.fromLTWH(m.left + 4, m.top + 4, m.width - 8, 9), _fill(const Color(0xFF2E3B33)));
    c.drawRect(Rect.fromLTWH(m.left + 6, m.top + 6, m.width - 12, 5), _fill(const Color(0xFF9DBB8E)));
    c.drawCircle(Offset(m.center.dx, m.top + 21), 3, _fill(const Color(0xFFE8E8E8)));
    if (h.stickerBox) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(m.right - 11, m.bottom - 9, 9, 7), const Radius.circular(1)), _fill(const Color(0xFF2FA24A)));
    }
    // The cable drop from the wall clip to the meter box.
    final b = g.bracket(h.site);
    c.drawLine(b, Offset(b.dx, m.top - 2), _stroke(const Color(0xFF2B2B2E), 1.4));
    c.drawLine(Offset(b.dx, m.top - 2), Offset(m.center.dx, m.top), _stroke(const Color(0xFF2B2B2E), 1.4));
    // The wall clip.
    c.drawCircle(b, 3.4, _fill(const Color(0xFF8A9096)));
    c.drawCircle(b, 3.4, _stroke(const Color(0xFF4F555B), 1));
  }

  void _window(Canvas c, Rect r) {
    c.drawRect(r.inflate(1.6), _fill(const Color(0xFFF1EEE6)));
    c.drawRect(r, _fill(const Color(0xFF7FA6BE)));
    c.drawRect(Rect.fromLTWH(r.left, r.top, r.width, r.height * 0.4), _fill(const Color(0x33FFFFFF)));
    c.drawLine(Offset(r.center.dx, r.top), Offset(r.center.dx, r.bottom), _stroke(const Color(0xFFF1EEE6), 1));
  }

  void _cable(Canvas c, M8Geo g, M8House h) {
    final pts = g.cable(h);
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    c.drawPath(path, _stroke(const Color(0x33000000), 3.4)..strokeJoin = StrokeJoin.round);
    c.drawPath(path, _stroke(const Color(0xFF25262A), 1.9)..strokeJoin = StrokeJoin.round);
  }

  void _pole(Canvas c, M8Geo g) {
    final p = g.pole;
    c.drawRect(
      p,
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFF8B8E93), Color(0xFFC8CBCF), Color(0xFF7A7D82)]).createShader(p),
    );
    // A crossarm with insulators.
    c.drawRect(Rect.fromLTWH(g.pole.center.dx - 38, g.groundY - 270, 76, 5), _fill(const Color(0xFF6C6F74)));
    for (final dx in [-32.0, -10.0, 12.0, 34.0]) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(g.pole.center.dx + dx - 2.5, g.groundY - 280, 5, 10), const Radius.circular(2)), _fill(const Color(0xFFB07A4E)));
    }
    // The fuse board housing (the carriers are a separate layer).
    final b = g.boardOf(deal.rows);
    c.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(5)), _fill(const Color(0xFF5E636B)));
    c.drawRRect(RRect.fromRectAndRadius(b.deflate(2.5), const Radius.circular(3.5)), _fill(const Color(0xFF3F434A)));
    // The base: a concrete step.
    c.drawRect(Rect.fromLTWH(p.left - 5, g.groundY + 22, p.width + 10, 7), _fill(const Color(0xFF9C9689)));
  }

  @override
  bool shouldRepaint(M8WorldPainter old) => old.geo.groundY != geo.groundY || old.deal != deal;
}

// ============================================================================
// The fuse carriers, the chalk marks, the lit trace
// ============================================================================

/// The carriers on the pole board: in place, out (an empty slot), the
/// selected one lifted a little (or pulled down under the finger).
class M8BoardPainter extends CustomPainter {
  const M8BoardPainter({required this.geo, required this.deal, required this.out, required this.selected, required this.pullDy});
  final M8Geo geo;
  final M8SolarDeal deal;

  /// Sites whose carrier is out of the board.
  final Set<int> out;
  final int? selected;
  final double pullDy;

  @override
  void paint(Canvas c, Size size) {
    for (var s = 0; s < deal.n; s++) {
      final r = geo.slot(s);
      c.drawRRect(RRect.fromRectAndRadius(r.deflate(1), const Radius.circular(3)), _fill(const Color(0xFF23262B)));
    }
    for (final h in deal.houses) {
      final r = geo.slot(h.slot);
      if (out.contains(h.site)) {
        // An empty slot: two bare contact tips.
        for (final dx in [-7.0, 7.0]) {
          c.drawRect(Rect.fromCenter(center: Offset(r.center.dx + dx, r.center.dy - 6), width: 3.4, height: 9), _fill(const Color(0xFFC9CDD2)));
        }
        continue;
      }
      final sel = selected == h.site;
      final shift = sel ? math.max(pullDy, 0.0) - 3 : 0.0;
      _carrier(c, r.shift(Offset(0, shift)), h, sel);
    }
  }

  void _carrier(Canvas c, Rect r, M8House h, bool sel) {
    if (sel) {
      c.drawRRect(RRect.fromRectAndRadius(r.inflate(2.5), const Radius.circular(6)), _stroke(const Color(0xFFFFFFFF), 1.8));
    }
    final body = RRect.fromRectAndRadius(r.deflate(2), const Radius.circular(4));
    c.drawRRect(
      body,
      Paint()..shader = const LinearGradient(colors: [Color(0xFFEFE9DA), Color(0xFFCFC7B3)]).createShader(r),
    );
    c.drawRRect(body, _stroke(const Color(0xFF8C8571), 1));
    c.drawRect(Rect.fromLTWH(r.left + 4, r.top + 2, r.width - 8, 6), _fill(const Color(0xFFB8452F)));
    c.drawLine(Offset(r.center.dx, r.bottom - 12), Offset(r.center.dx, r.bottom - 4), _stroke(const Color(0xFF6C6753), 2.4));
    if (h.stickerCarrier) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.left + 6, r.top + 11, r.width - 12, 7), const Radius.circular(1.2)), _fill(const Color(0xFF2FA24A)));
    }
  }

  @override
  bool shouldRepaint(M8BoardPainter old) =>
      old.geo.groundY != geo.groundY || old.deal != deal || old.selected != selected || old.pullDy != pullDy || old.out.length != out.length || !old.out.containsAll(out);
}

/// The chalk sun marks on the doors of the marked houses.
class M8MarksPainter extends CustomPainter {
  const M8MarksPainter({required this.geo, required this.deal, required this.marked});
  final M8Geo geo;
  final M8SolarDeal deal;
  final Set<int> marked;

  @override
  void paint(Canvas c, Size size) {
    for (final h in deal.houses) {
      if (!marked.contains(h.site)) continue;
      final d = geo.door(h.site, h.mirror);
      final o = d.center + const Offset(0, -2);
      final p = _stroke(const Color(0xF2FFF6D2), 1.5);
      c.drawCircle(o, 4.6, p);
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4;
        c.drawLine(o + Offset(math.cos(a), math.sin(a)) * 7, o + Offset(math.cos(a), math.sin(a)) * 10.4, p);
      }
    }
  }

  @override
  bool shouldRepaint(M8MarksPainter old) => old.geo.groundY != geo.groundY || old.deal != deal || old.marked.length != marked.length || !old.marked.containsAll(marked);
}

/// The cable lit under the finger from its bracket (the chalk of the trace).
class M8TracePainter extends CustomPainter {
  M8TracePainter({required this.points, required this.upTo, required this.finger}) : super(repaint: Listenable.merge([upTo, finger]));

  /// The traced cable (null: none).
  final List<Offset>? Function() points;

  /// How many points are lit.
  final ValueNotifier<int> upTo;
  final ValueNotifier<Offset?> finger;

  @override
  void paint(Canvas c, Size size) {
    final pts = points();
    final n = upTo.value;
    if (pts == null || n < 1) return;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < math.min(n + 1, pts.length); i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    c.drawPath(path, _stroke(const Color(0x66FFE27A), 7)..strokeJoin = StrokeJoin.round);
    c.drawPath(path, _stroke(const Color(0xFFFFF0A0), 2.6)..strokeJoin = StrokeJoin.round);
    final head = pts[math.min(n, pts.length - 1)];
    c.drawCircle(head, 5.5, _fill(const Color(0xFFFFF7C4)));
    c.drawCircle(head, 5.5, _stroke(const Color(0xFFE0A526), 1.4));
  }

  @override
  bool shouldRepaint(M8TracePainter old) => false;
}

// ============================================================================
// Ladder, pouch
// ============================================================================

class M8LadderPainter extends CustomPainter {
  const M8LadderPainter({this.vertical = false});
  final bool vertical;

  @override
  void paint(Canvas c, Size size) {
    final long = vertical ? size.height : size.width;
    final short = vertical ? size.width : size.height;
    final rail = _stroke(const Color(0xFFD7A24A), 3.2);
    final rung = _stroke(const Color(0xFFB07C2B), 2.2);
    Offset p(double a, double b) => vertical ? Offset(b, a) : Offset(a, b);
    c.drawLine(p(0, 2), p(long, 2), rail);
    c.drawLine(p(0, short - 2), p(long, short - 2), rail);
    for (var x = 8.0; x < long; x += 12) {
      c.drawLine(p(x, 2), p(x, short - 2), rung);
    }
  }

  @override
  bool shouldRepaint(M8LadderPainter old) => old.vertical != vertical;
}

/// The belt pouch: only the pulled count shows, as carriers in it.
class M8PouchPainter extends CustomPainter {
  const M8PouchPainter({required this.count});
  final int count;

  @override
  void paint(Canvas c, Size size) {
    final r = Rect.fromLTWH(2, 8, size.width - 4, size.height - 10);
    for (var i = 0; i < math.min(count, 4); i++) {
      c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(r.left + 3 + i * 5.5, 0.5, 5, 12), const Radius.circular(1.5)),
        _fill(const Color(0xFFEFE9DA)),
      );
      c.drawRect(Rect.fromLTWH(r.left + 3 + i * 5.5, 0.5, 5, 3), _fill(const Color(0xFFB8452F)));
    }
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)), _fill(const Color(0xFF6B4A2E)));
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)), _stroke(const Color(0xFF3F2B18), 1.2));
    c.drawLine(Offset(r.left + 2, r.top + 7), Offset(r.right - 2, r.top + 7), _stroke(const Color(0xFF3F2B18), 1));
    c.drawCircle(Offset(r.center.dx, r.top + 7), 2, _fill(const Color(0xFFE9C46A)));
  }

  @override
  bool shouldRepaint(M8PouchPainter old) => old.count != count;
}

// ============================================================================
// Peek over the parapet: the roof from above
// ============================================================================

/// What is on a roof, seen from above (every roof answers alike).
class M8RoofPlanPainter extends CustomPainter {
  const M8RoofPlanPainter({required this.house});
  final M8House house;

  @override
  void paint(Canvas c, Size size) {
    final r = Offset.zero & size;
    c.drawRect(r, _fill(const Color(0xFFB9B4A6)));
    c.drawRect(r.deflate(3), _stroke(const Color(0xFF8C887A), 5));
    final a = r.deflate(14);
    if (house.panelsLane || house.panelsParapet) {
      final pw = (a.width - 12) / 3;
      for (var i = 0; i < 3; i++) {
        final pr = Rect.fromLTWH(a.left + i * (pw + 6), a.top + 6, pw, a.height * 0.52);
        c.drawRect(pr, _fill(const Color(0xFF1F3C7C)));
        final g = _stroke(const Color(0xFF6A8FD4), 0.8);
        for (var k = 1; k < 4; k++) {
          c.drawLine(Offset(pr.left + pr.width * k / 4, pr.top), Offset(pr.left + pr.width * k / 4, pr.bottom), g);
        }
        for (var k = 1; k < 3; k++) {
          c.drawLine(Offset(pr.left, pr.top + pr.height * k / 3), Offset(pr.right, pr.top + pr.height * k / 3), g);
        }
        c.drawRect(pr, _stroke(const Color(0xFFC9D2DA), 1.4));
      }
    } else if (house.decoy == M8Decoy.tarp) {
      final p = Path()
        ..moveTo(a.left + 6, a.top + 14)
        ..lineTo(a.right - 8, a.top + 6)
        ..lineTo(a.right - 2, a.top + a.height * 0.58)
        ..lineTo(a.left + 12, a.top + a.height * 0.62)
        ..close();
      c.drawPath(p, _fill(const Color(0xFF63AEE8)));
      c.drawPath(p, _stroke(const Color(0xFF3F86BF), 1.2));
      for (final o in [Offset(a.left + 12, a.top + 18), Offset(a.right - 12, a.top + 12), Offset(a.right - 8, a.top + a.height * 0.54), Offset(a.left + 18, a.top + a.height * 0.56)]) {
        c.drawCircle(o, 2, _fill(const Color(0xFFF4F4F0)));
      }
    } else if (house.decoy == M8Decoy.skylight) {
      final sr = Rect.fromCenter(center: a.center + const Offset(0, -6), width: a.width * 0.5, height: a.height * 0.5);
      c.drawRect(sr, _fill(const Color(0xFFD6F0FA)));
      c.drawRect(sr, _stroke(const Color(0xFF8FA0AB), 1.6));
      c.drawLine(Offset(sr.center.dx, sr.top), Offset(sr.center.dx, sr.bottom), _stroke(const Color(0xFF8FA0AB), 1.2));
      c.drawLine(Offset(sr.left, sr.center.dy), Offset(sr.right, sr.center.dy), _stroke(const Color(0xFF8FA0AB), 1.2));
    } else if (house.decoy == M8Decoy.tanks) {
      for (var i = 0; i < 3; i++) {
        final o = Offset(a.left + a.width * (0.2 + 0.3 * i), a.top + a.height * 0.34);
        c.drawCircle(o, 13, _fill(const Color(0xFF2A2C31)));
        c.drawCircle(o, 9, _fill(const Color(0xFF40434A)));
      }
    } else {
      switch (house.clutter) {
        case 1:
          c.drawCircle(a.center + const Offset(14, -8), 12, _fill(const Color(0xFF2A2C31)));
          c.drawCircle(a.center + const Offset(14, -8), 8, _fill(const Color(0xFF40434A)));
        case 2:
          final p = _stroke(const Color(0xFF8A8D93), 1);
          c.drawLine(Offset(a.left + 6, a.top + 10), Offset(a.right - 6, a.top + 10), p);
          const cols = [Color(0xFFD94A4A), Color(0xFFF2C94C), Color(0xFFEFEFEF), Color(0xFF4A8BD9)];
          for (var i = 0; i < 3; i++) {
            c.drawRect(Rect.fromLTWH(a.left + 18 + i * 28, a.top + 10, 14, 10), _fill(cols[(i + house.site) % cols.length]));
          }
        case 3:
          c.drawCircle(a.center + const Offset(-20, 0), 3, _fill(const Color(0xFF7C8088)));
          c.drawLine(a.center + const Offset(-30, 0), a.center + const Offset(-10, 0), _stroke(const Color(0xFF7C8088), 1.2));
      }
    }
    // The stair-head box every roof has.
    c.drawRect(Rect.fromLTWH(r.right - 34, r.bottom - 30, 22, 18), _fill(const Color(0xFFA19B8C)));
    c.drawRect(Rect.fromLTWH(r.right - 34, r.bottom - 30, 22, 18), _stroke(const Color(0xFF7A7568), 1));
  }

  @override
  bool shouldRepaint(M8RoofPlanPainter old) => old.house != house;
}

// ============================================================================
// The death scene: the back-feed chain in colour, and the safe climb's crew
// ============================================================================

/// The chain, in colour over the grey freeze: the sun, the panels, the running
/// inverter, the meter, the service cable, the pole, the trainee's hand.
class M8ChainPainter extends CustomPainter {
  const M8ChainPainter({required this.geo, required this.house, required this.fault, required this.v});
  final M8Geo geo;
  final M8House house;
  final M8Fault fault;

  /// 0 to 1: how far the chain has lit.
  final double v;

  double _seg(double a, double b) => ((v - a) / (b - a)).clamp(0.0, 1.0);

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final wall = g.house(house.site);
    final glow = _fill(const Color(0xFFFFD84A));
    // 1 the sun, a beam to the roof.
    final s1 = _seg(0, 0.14);
    if (s1 > 0) {
      c.drawCircle(g.sun, 24, _fill(const Color(0xFFFFE27A)));
      final to = Offset(wall.center.dx, wall.top - 12);
      c.drawLine(g.sun, Offset.lerp(g.sun, to, s1)!, _stroke(const Color(0xAAFFE27A), 5));
    }
    // 2 the panels light up.
    final s2 = _seg(0.14, 0.28);
    if (s2 > 0) {
      final a = Rect.fromLTRB(wall.left + 6, wall.top - 26, wall.right - 6, wall.top - 2);
      _panelsLane(c, a);
      c.drawRect(a.inflate(2), _stroke(const Color(0xFFFFE27A).withValues(alpha: s2), 2.4));
    }
    // 3 the inverter on the wall, running.
    final inv = Rect.fromLTWH(wall.center.dx - 12, wall.top + 34, 24, 18);
    final s3 = _seg(0.28, 0.42);
    if (s3 > 0) {
      c.drawLine(Offset(wall.center.dx, wall.top - 2), Offset(wall.center.dx, inv.top), _stroke(const Color(0xFFFFE27A).withValues(alpha: s3), 2.4));
      c.drawRRect(RRect.fromRectAndRadius(inv, const Radius.circular(2.5)), _fill(const Color(0xFFE6E8EA)));
      c.drawRRect(RRect.fromRectAndRadius(inv, const Radius.circular(2.5)), _stroke(const Color(0xFF6C7278), 1));
      final led = switch (fault) {
        M8Fault.relayStuck => const Color(0xFFE53935),
        M8Fault.noAntiIsland => const Color(0xFFFB8C00),
        M8Fault.running => const Color(0xFF43A047),
      };
      c.drawCircle(inv.center + const Offset(-6, 0), 2.6, _fill(led));
      c.drawLine(inv.center + const Offset(1, -3), inv.center + const Offset(8, -3), _stroke(const Color(0xFF6C7278), 1.2));
      c.drawLine(inv.center + const Offset(1, 3), inv.center + const Offset(8, 3), _stroke(const Color(0xFF6C7278), 1.2));
    }
    // 4 the meter box.
    final m = g.meter(house.site, house.mirror);
    final s4 = _seg(0.42, 0.52);
    if (s4 > 0) {
      c.drawLine(inv.center, m.center, _stroke(const Color(0xFFFFE27A).withValues(alpha: s4), 2.2));
      c.drawRRect(RRect.fromRectAndRadius(m.inflate(2), const Radius.circular(3)), _stroke(const Color(0xFFFFD84A).withValues(alpha: s4), 2));
    }
    // 5 the service cable, lit from the bracket to the pole.
    final pts = g.cable(house);
    final s5 = _seg(0.52, 0.8);
    if (s5 > 0) {
      c.drawLine(m.topCenter, g.bracket(house.site), _stroke(const Color(0xFFFFE27A), 3));
      final k = (s5 * (pts.length - 1)).floor();
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (var i = 1; i <= k; i++) {
        path.lineTo(pts[i].dx, pts[i].dy);
      }
      c.drawPath(path, _stroke(const Color(0x77FFD84A), 8)..strokeJoin = StrokeJoin.round);
      c.drawPath(path, _stroke(const Color(0xFFFFF0A0), 3)..strokeJoin = StrokeJoin.round);
    }
    // 6 the board and the pole.
    final s6 = _seg(0.8, 0.92);
    if (s6 > 0) {
      final slot = g.slot(house.slot);
      c.drawRRect(RRect.fromRectAndRadius(slot.inflate(3), const Radius.circular(5)), _stroke(const Color(0xFFFFD84A).withValues(alpha: s6), 3));
      c.drawLine(Offset(g.pole.center.dx, slot.bottom), Offset(g.pole.center.dx, g.handAt.dy), _stroke(const Color(0xFFFFD84A).withValues(alpha: s6), 3));
    }
    // 7 the trainee on the ladder, the spark at his hand.
    final s7 = _seg(0.92, 1);
    final h = g.handAt;
    c.drawLine(Offset(g.pole.left - 32, g.groundY + 40), Offset(g.pole.left - 6, h.dy - 70), _stroke(const Color(0xFFD7A24A), 3.4));
    c.drawLine(Offset(g.pole.left - 20, g.groundY + 42), Offset(g.pole.left + 6, h.dy - 68), _stroke(const Color(0xFFD7A24A), 3.4));
    c.drawCircle(h + const Offset(-10, -12), 6, _fill(const Color(0xFFF2C7A1)));
    c.drawRect(Rect.fromLTWH(h.dx - 16, h.dy - 6, 12, 26), _fill(const Color(0xFF2E6FD0)));
    c.drawLine(h + const Offset(-6, -2), h + const Offset(5, 0), _stroke(const Color(0xFFE08A1E), 3.4));
    if (s7 > 0) {
      for (var i = 0; i < 8; i++) {
        final a = i * math.pi / 4 + 0.3;
        final r1 = 5 + 10 * s7;
        c.drawLine(h + Offset(math.cos(a), math.sin(a)) * 3, h + Offset(math.cos(a), math.sin(a)) * r1, _stroke(glow.color, 2.2));
      }
      c.drawCircle(h, 5 + 3 * s7, _fill(const Color(0xFFFFFFFF)));
    }
  }

  @override
  bool shouldRepaint(M8ChainPainter old) => old.v != v || old.house != house || old.geo.groundY != geo.groundY;
}

/// The safe climb's coda: the crew's tester on a live point, then 0 V (ডেড),
/// the earths on the pole, the trainee a few rungs up. Art only (M8-17).
class M8CrewPainter extends CustomPainter {
  const M8CrewPainter({required this.geo, required this.v});
  final M8Geo geo;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final px = g.pole.center.dx;
    // The crew man at the pole's right, his tester held to the line.
    final base = Offset(px + 44, g.groundY + 62);
    c.drawCircle(base + const Offset(0, -92), 7, _fill(const Color(0xFFF2C7A1)));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: base + const Offset(0, -92 - 3), width: 16, height: 8), const Radius.circular(3)), _fill(const Color(0xFFF2C94C)));
    c.drawRect(Rect.fromLTWH(base.dx - 8, base.dy - 84, 16, 40), _fill(const Color(0xFF2E6FD0)));
    c.drawRect(Rect.fromLTWH(base.dx - 7, base.dy - 44, 6, 38), _fill(const Color(0xFF3A3F55)));
    c.drawRect(Rect.fromLTWH(base.dx + 1, base.dy - 44, 6, 38), _fill(const Color(0xFF3A3F55)));
    final hand = Offset.lerp(base + const Offset(-6, -70), Offset(px + 12, g.groundY - 206), (v * 2).clamp(0, 1))!;
    c.drawLine(base + const Offset(-5, -76), hand, _stroke(const Color(0xFF2E6FD0), 4));
    // The tester: a small box with its window.
    final t = Rect.fromCenter(center: hand + const Offset(4, -6), width: 16, height: 11);
    c.drawRRect(RRect.fromRectAndRadius(t, const Radius.circular(2)), _fill(const Color(0xFFE6E8EA)));
    c.drawRect(Rect.fromLTWH(t.left + 2, t.top + 2, t.width - 4, 4), _fill(v < 0.5 ? const Color(0xFFFFD84A) : const Color(0xFF9DBB8E)));
    // The earth clamps on the pole with their green-yellow leads to the ground.
    final e = ((v - 0.5) * 3).clamp(0.0, 1.0);
    if (e > 0) {
      final top = Offset(px, g.groundY - 214);
      final foot = Offset(px - 22, g.groundY + 30);
      c.drawLine(top, Offset.lerp(top, foot, e)!, _stroke(const Color(0xFF2FA24A), 2.4));
      c.drawCircle(top, 3.4, _fill(const Color(0xFFC9CDD2)));
      c.drawLine(Offset(foot.dx, foot.dy), Offset(foot.dx, foot.dy + 8), _stroke(const Color(0xFF8A7C57), 3));
    }
    // The ladder is up; the trainee a few rungs in.
    c.drawLine(Offset(g.pole.left - 34, g.groundY + 40), Offset(g.pole.left - 8, g.groundY - 120), _stroke(const Color(0xFFD7A24A), 3.4));
    c.drawLine(Offset(g.pole.left - 22, g.groundY + 42), Offset(g.pole.left + 4, g.groundY - 118), _stroke(const Color(0xFFD7A24A), 3.4));
    final climb = Offset.lerp(Offset(g.pole.left - 20, g.groundY - 4), Offset(g.pole.left - 8, g.groundY - 62), v)!;
    c.drawCircle(climb + const Offset(0, -30), 6, _fill(const Color(0xFFF2C7A1)));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: climb + const Offset(0, -33), width: 14, height: 7), const Radius.circular(3)), _fill(const Color(0xFFF2C94C)));
    c.drawRect(Rect.fromLTWH(climb.dx - 7, climb.dy - 24, 14, 22), _fill(const Color(0xFF2E6FD0)));
  }

  @override
  bool shouldRepaint(M8CrewPainter old) => old.v != v || old.geo.groundY != geo.groundY;
}
