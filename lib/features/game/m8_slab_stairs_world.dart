import 'dart:math' as math;

import 'package:flutter/material.dart';

// The drawn world of lesson 8.7 কাজ "বিলের সিঁড়ি" (m8_slab_stairs.dart): a
// village verandah at dusk, one doorstep at a time. The customer (dealt look)
// holds the bill out at the trainee. In front of him the lineman's own sketch
// on the back of the bill, an "explain board": a floor tray, step 1 (low, a
// small coin, 'প্রথম 102 ইউনিট', with its fill gauge), step 2 (tall, a big
// coin, 'পরের ইউনিট'), a band along the top and a small bin. Below stands the
// tile tray; when a block is on the cutter the tray shows its unit ruler.
//
// Height shows cost (no rupees): a unit on step 2 is drawn 2.2 times as tall
// as a unit on step 1. Only words a worker reads are painted: the step labels,
// the 'N/102' gauge, the unit counts on the blocks, 'MVCA' on its band, the
// bill's own lines. Code-drawn.
//
// Design: 360 wide × the scene's height. The guide stands at the bottom corner
// (x 244..360, just above the tray): nothing a hand needs sits under him.

/// The three kinds of doorstep.
enum M8Kind { closed, slab, mvca }

/// The tiles in the tray.
enum M8TileKind { fixed, block, mvca, pf }

/// The parts of the finished tower (what the customer asks about).
enum M8Part { floor, step1, step2, top }

/// Step 1 holds this many units (lesson 8.7: প্রথম ১০২ ইউনিট).
const int kM8Step1Cap = 102;

/// A tile in the tray. [upper] marks the piece above the cut (it goes on
/// step 2 whole).
@immutable
class M8Tile {
  const M8Tile(this.kind, {this.units = 0, this.upper = false});
  final M8TileKind kind;
  final int units;
  final bool upper;

  @override
  bool operator ==(Object other) => other is M8Tile && other.kind == kind && other.units == units && other.upper == upper;

  @override
  int get hashCode => Object.hash(kind, units, upper);

  @override
  String toString() => 'M8Tile(${kind.name}, $units${upper ? ', upper' : ''})';
}

/// How the customer and the house look (dealt).
@immutable
class M8Look {
  const M8Look({required this.skin, required this.shirt, required this.hair, required this.elder, required this.light});
  final int skin;
  final int shirt;
  final int hair;
  final bool elder;

  /// The dusk light (index into [kM8Skies]).
  final int light;

  @override
  bool operator ==(Object other) =>
      other is M8Look && other.skin == skin && other.shirt == shirt && other.hair == hair && other.elder == elder && other.light == light;

  @override
  int get hashCode => Object.hash(skin, shirt, hair, elder, light);
}

const List<Color> kM8Skins = [Color(0xFFA8714B), Color(0xFFC08A5E), Color(0xFF8A5A3C)];
const List<Color> kM8Shirts = [Color(0xFF3F6E8F), Color(0xFFB5523B), Color(0xFF5B8A4A), Color(0xFF7A5C99)];
const List<Color> kM8Hairs = [Color(0xFF1E1A16), Color(0xFF3A2A1C), Color(0xFFD9D4CC)];

/// The dusk sky (dealt a play): top, middle, horizon.
const List<List<Color>> kM8Skies = [
  [Color(0xFF2B3A67), Color(0xFFB5667B), Color(0xFFF2A65A)],
  [Color(0xFF34406E), Color(0xFF8E6F9B), Color(0xFFF0B07A)],
  [Color(0xFF25355C), Color(0xFFC0795E), Color(0xFFF6C27C)],
];

/// Where things are (design px, 360 wide).
@immutable
class M8StairsGeo {
  const M8StairsGeo._(this.height, this.trayTop);

  factory M8StairsGeo.forScene(double height, double inset) => M8StairsGeo._(height, height - trayH - inset * 0.6);

  final double height;

  /// The top of the tile tray.
  final double trayTop;

  static const double trayH = 104;

  /// A dragged tile sits this far above the finger.
  static const double lift = 26;

  // --- the top row: the customer, his bill, his words ------------------------
  Rect get customer => const Rect.fromLTWH(6, 146, 54, 64);
  Rect get bill => const Rect.fromLTWH(62, 148, 146, 58);
  Rect get caption => const Rect.fromLTWH(212, 146, 142, 62);

  // --- the explain board -----------------------------------------------------
  Rect get board => Rect.fromLTRB(8, 216, 352, math.max(216 + 170, trayTop - 124));
  Rect get topBand => Rect.fromLTWH(board.left + 8, board.top + 8, board.width - 16, 30);
  Rect get floor => Rect.fromLTWH(board.left + 8, board.bottom - 8 - 32, board.width - 16, 32);
  double get stackTop => topBand.bottom + 6;
  double get stackBottom => floor.top - 4;
  double get stackH => stackBottom - stackTop;

  /// Drawn height of one unit on step 2 / step 1 (a step-2 unit costs 2.2×).
  double get u2 => stackH / 160;
  double get u1 => u2 / 2.2;

  Rect get step1Col => Rect.fromLTRB(board.left + 8, stackTop, board.left + 110, stackBottom);
  Rect get step2Col => Rect.fromLTRB(board.left + 114, stackTop, board.left + 266, stackBottom);
  Rect get bin => Rect.fromLTRB(board.left + 272, math.max(stackTop, stackBottom - 76), board.right - 8, stackBottom);

  /// Step 1's box (its 102 units' height) and step 2's.
  Rect get step1Box => Rect.fromLTRB(step1Col.left + 4, stackBottom - kM8Step1Cap * u1, step1Col.right - 4, stackBottom);
  Rect get step2Box => Rect.fromLTRB(step2Col.left + 4, stackBottom - 160 * u2, step2Col.right - 4, stackBottom);

  /// The step-1 fill gauge (above its box).
  Rect get gauge => Rect.fromLTWH(step1Col.left + 6, stackTop + 18, step1Col.width - 12, 8);

  /// The part a point falls on in the finished tower (null: none).
  Rect partRect(M8Part p) => switch (p) {
        M8Part.floor => floor,
        M8Part.step1 => step1Col,
        M8Part.step2 => step2Col,
        M8Part.top => topBand,
      };

  // --- below the board -------------------------------------------------------
  Rect get cutterPad => Rect.fromLTWH(8, trayTop - 114, 120, 108);
  Rect get trainee => Rect.fromLTWH(136, trayTop - 116, 46, 106);
  Rect get meterBox => Rect.fromLTWH(190, trayTop - 100, 50, 70);

  // --- the tile tray (4 × 2 slots) and the cutter's ruler ---------------------
  Rect get tray => Rect.fromLTWH(6, trayTop, 348, trayH - 4);
  Rect slot(int i) => Rect.fromLTWH(12 + (i % 4) * 86.0, trayTop + 6 + (i ~/ 4) * 48.0, 80, 42);

  Rect get ruler => Rect.fromLTWH(26, trayTop + 34, 308, 34);
  Rect get readout => Rect.fromLTWH(26, trayTop + 6, 308, 24);
  Rect get back => Rect.fromLTWH(26, trayTop + 70, 96, 28);

  /// The cutter's handle at design-x [x] on the ruler.
  Rect handle(double x) => Rect.fromCenter(center: Offset(x.clamp(ruler.left, ruler.right), ruler.center.dy), width: 32, height: 40);

  /// The zone a dragged tile's centre is over.
  M8Zone zoneAt(Offset p) {
    if (topBand.inflate(4).contains(p)) return M8Zone.top;
    if (floor.inflate(4).contains(p)) return M8Zone.floor;
    if (bin.inflate(8).contains(p)) return M8Zone.bin;
    if (step1Col.inflate(2).contains(p)) return M8Zone.step1;
    if (step2Col.inflate(2).contains(p)) return M8Zone.step2;
    if (cutterPad.inflate(6).contains(p)) return M8Zone.cutter;
    return M8Zone.none;
  }

  @override
  bool operator ==(Object other) => other is M8StairsGeo && other.height == height && other.trayTop == trayTop;

  @override
  int get hashCode => Object.hash(height, trayTop);
}

/// Where a dragged tile or part can be dropped.
enum M8Zone { floor, step1, step2, top, bin, cutter, none }

/// What the board shows (immutable: the painter repaints only when it changes).
@immutable
class M8BoardView {
  const M8BoardView({
    this.floorOn = false,
    this.step1 = const [],
    this.step2 = const [],
    this.topOn = false,
    this.ghost,
    this.held,
  });

  final bool floorOn;

  /// The blocks on each step (units), bottom first.
  final List<int> step1;
  final List<int> step2;
  final bool topOn;

  /// Last month's units, drawn as a dotted outline on step 1 (null: none).
  final int? ghost;

  /// The part under the finger (a soft shine).
  final M8Part? held;

  int get fill1 => step1.fold(0, (a, b) => a + b);

  @override
  bool operator ==(Object other) =>
      other is M8BoardView &&
      other.floorOn == floorOn &&
      other.topOn == topOn &&
      other.ghost == ghost &&
      other.held == held &&
      _same(other.step1, step1) &&
      _same(other.step2, step2);

  static bool _same(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(floorOn, topOn, ghost, held, Object.hashAll(step1), Object.hashAll(step2));
}

Paint _fill(Color c) => Paint()..color = c;
Paint _stroke(Color c, double w) => Paint()
  ..color = c
  ..strokeWidth = w
  ..style = PaintingStyle.stroke
  ..strokeCap = StrokeCap.round;

void _text(Canvas c, String text, Offset centre, {double size = 9, Color color = const Color(0xFF2A2018), FontWeight weight = FontWeight.w800, double maxWidth = 120}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: weight, color: color, height: 1.05)),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
    maxLines: 2,
  )..layout(maxWidth: maxWidth);
  tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
}

void _dashedRect(Canvas c, Rect r, Paint p, {double dash = 5, double gap = 4}) {
  void line(Offset a, Offset b) {
    final d = b - a;
    final len = d.distance;
    final u = d / len;
    for (var t = 0.0; t < len; t += dash + gap) {
      c.drawLine(a + u * t, a + u * math.min(t + dash, len), p);
    }
  }

  line(r.topLeft, r.topRight);
  line(r.topRight, r.bottomRight);
  line(r.bottomRight, r.bottomLeft);
  line(r.bottomLeft, r.topLeft);
}

void _coin(Canvas c, Offset at, double r) {
  c.drawCircle(at, r, _fill(const Color(0xFFF2CF5B)));
  c.drawCircle(at, r, _stroke(const Color(0xFF8A6A3C), 1.2));
  c.drawCircle(at, r * 0.55, _stroke(const Color(0xFFC9A227), 1));
}

/// The verandah at dusk: sky, wall, floor, a lamp, the wall meter box, the
/// padlocked gate when the house is closed. Static (the same for the whole
/// doorstep; only the light and the closed house change it).
class M8StairsBackPainter extends CustomPainter {
  const M8StairsBackPainter({required this.geo, required this.light, required this.closed});
  final M8StairsGeo geo;
  final int light;
  final bool closed;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final sky = kM8Skies[light % kM8Skies.length];
    final skyR = Rect.fromLTWH(0, 0, w, 236);
    c.drawRect(skyR, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: sky).createShader(skyR));
    // Far roofs and a coconut palm against the dusk.
    final far = _fill(const Color(0xFF3A3250));
    for (var i = 0; i < 7; i++) {
      final x = i * 58.0 - 12;
      c.drawRect(Rect.fromLTWH(x, 196 - (i * 29 % 4) * 7.0, 46, 60), far);
    }
    c.drawLine(const Offset(318, 236), const Offset(312, 150), _stroke(const Color(0xFF2A2440), 4));
    for (var k = 0; k < 5; k++) {
      final a = -2.6 + k * 0.55;
      c.drawLine(const Offset(312, 150), Offset(312 + 26 * math.cos(a), 150 + 14 * math.sin(a) + 8), _stroke(const Color(0xFF2E3F36), 3));
    }
    // The verandah wall and its floor.
    final wall = Rect.fromLTRB(0, 214, w, size.height);
    c.drawRect(wall, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFD9C3A0), Color(0xFFBFA583), Color(0xFF9C8466)]).createShader(wall));
    c.drawRect(Rect.fromLTRB(0, 208, w, 220), _fill(const Color(0xFF6B4A33)));
    final fl = Rect.fromLTRB(0, geo.trayTop - 8, w, size.height);
    c.drawRect(fl, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF7A6650), Color(0xFF4F4034)]).createShader(fl));
    // Verandah posts at the edges.
    for (final x in [0.0, w - 9]) {
      c.drawRect(Rect.fromLTRB(x, 150, x + 9, geo.trayTop - 6), _fill(const Color(0xFF7B5A3D)));
    }
    // The lamp: lit when someone is home, dark at a closed house.
    c.drawLine(const Offset(180, 140), const Offset(180, 158), _stroke(const Color(0xFF5B4630), 1.5));
    c.drawCircle(const Offset(180, 164), 7, _fill(closed ? const Color(0xFF8A8478) : const Color(0xFFFFE08A)));
    if (!closed) c.drawCircle(const Offset(180, 164), 18, _fill(const Color(0x33FFE08A)));
    // The wall meter box with its window and seal, beside the trainee.
    final mb = geo.meterBox;
    c.drawRRect(RRect.fromRectAndRadius(mb, const Radius.circular(4)), _fill(const Color(0xFFB9C2C8)));
    c.drawRRect(RRect.fromRectAndRadius(mb, const Radius.circular(4)), _stroke(const Color(0xFF4B5258), 1.6));
    final win = Rect.fromLTWH(mb.left + 7, mb.top + 8, mb.width - 14, 22);
    c.drawRect(win, _fill(const Color(0xFF1C2230)));
    for (var i = 0; i < 4; i++) {
      c.drawRect(Rect.fromLTWH(win.left + 4 + i * 8.0, win.top + 7, 5, 9), _fill(const Color(0xFF7CFC9A)));
    }
    c.drawCircle(Offset(mb.center.dx, mb.top + 46), 5, _fill(const Color(0xFFEFEFEF)));
    c.drawCircle(Offset(mb.center.dx, mb.top + 46), 5, _stroke(const Color(0xFF4B5258), 1));
    if (closed) {
      // A padlock on the gate chain behind the meter box.
      final lock = Rect.fromCenter(center: Offset(mb.left - 10, mb.top + 52), width: 12, height: 10);
      c.drawRect(lock, _fill(const Color(0xFFC9A227)));
      c.drawArc(Rect.fromCenter(center: Offset(mb.left - 10, mb.top + 47), width: 9, height: 10), math.pi, math.pi, false, _stroke(const Color(0xFF6B5410), 1.6));
    }
  }

  @override
  bool shouldRepaint(M8StairsBackPainter old) => old.geo != geo || old.light != light || old.closed != closed;
}

/// The customer holding the bill out (silent: his words show as a caption).
class M8CustomerPainter extends CustomPainter {
  const M8CustomerPainter({required this.geo, required this.look});
  final M8StairsGeo geo;
  final M8Look look;

  @override
  void paint(Canvas c, Size size) {
    final r = geo.customer;
    final skin = kM8Skins[look.skin % kM8Skins.length];
    final shirt = kM8Shirts[look.shirt % kM8Shirts.length];
    final hair = look.elder ? kM8Hairs[2] : kM8Hairs[look.hair % 2];
    final foot = Offset(r.center.dx - 4, r.bottom);
    // Legs.
    c.drawLine(foot + const Offset(-4, -22), foot + const Offset(-4, -2), _stroke(const Color(0xFF3A3F55), 6));
    c.drawLine(foot + const Offset(5, -22), foot + const Offset(5, -2), _stroke(const Color(0xFF3A3F55), 6));
    // Body.
    final body = Rect.fromLTRB(foot.dx - 11, foot.dy - 50, foot.dx + 11, foot.dy - 20);
    c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(5)), _fill(shirt));
    // The arm out to the bill.
    c.drawLine(Offset(body.right - 2, body.top + 6), Offset(body.right + 12, body.top + 2), _stroke(shirt, 5));
    c.drawCircle(Offset(body.right + 13, body.top + 2), 3, _fill(skin));
    c.drawLine(Offset(body.left + 2, body.top + 6), Offset(body.left, body.top + 24), _stroke(shirt, 5));
    // Head and hair.
    final head = Offset(foot.dx, foot.dy - 58);
    c.drawCircle(head, 7.5, _fill(skin));
    c.drawArc(Rect.fromCircle(center: head, radius: 8), math.pi, math.pi, true, _fill(hair));
    if (look.elder) {
      c.drawLine(head + const Offset(-4, 1), head + const Offset(4, 1), _stroke(const Color(0xFF2A2018), 1));
    }
  }

  @override
  bool shouldRepaint(M8CustomerPainter old) => old.geo != geo || old.look != look;
}

/// The bill paper in the customer's hand: 'এ মাসে', 'আগের মাসে' and 'MVCA'
/// lines as the doorstep has them.
class M8BillPainter extends CustomPainter {
  const M8BillPainter({required this.geo, required this.units, required this.last, required this.mvca, required this.thisMonth, required this.lastMonth});
  final M8StairsGeo geo;
  final int units;
  final int? last;
  final bool mvca;
  final String thisMonth;
  final String lastMonth;

  @override
  void paint(Canvas c, Size size) {
    final r = geo.bill;
    c.drawRRect(RRect.fromRectAndRadius(r.shift(const Offset(1, 2)), const Radius.circular(3)), _fill(const Color(0x55000000)));
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), _fill(const Color(0xFFFBF7EA)));
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), _stroke(const Color(0xFF8A6A3C), 1.2));
    final style = const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF2A2018), height: 1.1);
    var y = r.top + 5;
    void line(String s, {Color? color}) {
      final tp = TextPainter(
        text: TextSpan(text: s, style: color == null ? style : style.copyWith(color: color)),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: r.width - 12);
      tp.paint(c, Offset(r.left + 6, y));
      y += 15;
    }

    line(thisMonth);
    if (last != null) line(lastMonth);
    if (mvca) line('MVCA', color: const Color(0xFF6A3FA0));
  }

  @override
  bool shouldRepaint(M8BillPainter old) =>
      old.geo != geo || old.units != units || old.last != last || old.mvca != mvca || old.thisMonth != thisMonth || old.lastMonth != lastMonth;
}

/// The explain board: floor tray, two steps with the blocks on them, the top
/// band, the gauge, the bin and (slab, after the answer) last month's ghost.
class M8BoardPainter extends CustomPainter {
  const M8BoardPainter({required this.geo, required this.view, required this.fixedLabel, required this.step1Label, required this.step2Label});
  final M8StairsGeo geo;
  final M8BoardView view;
  final String fixedLabel;
  final String step1Label;
  final String step2Label;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    // The clipboard.
    final b = g.board;
    c.drawRRect(RRect.fromRectAndRadius(b.shift(const Offset(0, 3)), const Radius.circular(8)), _fill(const Color(0x66000000)));
    c.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(8)), _fill(const Color(0xFF8A6A3C)));
    final paper = b.deflate(4);
    c.drawRRect(RRect.fromRectAndRadius(paper, const Radius.circular(5)), _fill(const Color(0xFFF7F1DE)));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(b.center.dx, b.top + 1), width: 44, height: 9), const Radius.circular(3)), _fill(const Color(0xFF9AA2A8)));

    // The top band: dashed when empty, a purple band with the MVCA word on it.
    final tb = g.topBand;
    if (view.topOn) {
      c.drawRRect(RRect.fromRectAndRadius(tb, const Radius.circular(4)), _fill(const Color(0xFF8E6BBF)));
      c.drawRRect(RRect.fromRectAndRadius(tb, const Radius.circular(4)), _stroke(const Color(0xFF4D3578), 1.6));
      _text(c, 'MVCA', tb.center, size: 12, color: Colors.white, weight: FontWeight.w900);
    } else {
      _dashedRect(c, tb, _stroke(const Color(0x66786A50), 1.2));
    }
    if (view.held == M8Part.top) c.drawRRect(RRect.fromRectAndRadius(tb.inflate(2), const Radius.circular(5)), _stroke(const Color(0xAAFFFFFF), 2));

    // Step boxes (the capacity outlines) and their labels, coins and gauge.
    final s1 = g.step1Box;
    final s2 = g.step2Box;
    _dashedRect(c, s1, _stroke(const Color(0x88786A50), 1.2));
    _dashedRect(c, s2, _stroke(const Color(0x66786A50), 1.2));
    _text(c, step1Label, Offset(g.step1Col.center.dx + 6, s1.top - 10), size: 8.5, maxWidth: 88);
    _coin(c, Offset(g.step1Col.left + 8, s1.top - 10), 5);
    _text(c, step2Label, Offset(g.step2Col.center.dx + 8, s2.top + 8), size: 8.5, maxWidth: 110);
    _coin(c, Offset(g.step2Col.left + 14, s2.top + 8), 9);
    // The step-1 fill gauge: units / 102.
    final gg = g.gauge;
    c.drawRRect(RRect.fromRectAndRadius(gg, const Radius.circular(3)), _fill(const Color(0xFFE5DCC2)));
    final f = (view.fill1 / kM8Step1Cap).clamp(0.0, 1.0);
    if (f > 0) c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(gg.left, gg.top, gg.width * f, gg.height), const Radius.circular(3)), _fill(const Color(0xFF2E9E4F)));
    c.drawRRect(RRect.fromRectAndRadius(gg, const Radius.circular(3)), _stroke(const Color(0xFF786A50), 1));
    _text(c, '${view.fill1}/$kM8Step1Cap', Offset(gg.center.dx, gg.top - 6), size: 9, weight: FontWeight.w900, maxWidth: 90);

    // The blocks, bottom first.
    var y = g.stackBottom;
    for (var i = 0; i < view.step1.length; i++) {
      final h = view.step1[i] * g.u1;
      _block(c, Rect.fromLTRB(s1.left + 1, y - h, s1.right - 1, y), view.step1[i], const Color(0xFFE9B949), i);
      y -= h;
    }
    y = g.stackBottom;
    for (var i = 0; i < view.step2.length; i++) {
      final h = view.step2[i] * g.u2;
      _block(c, Rect.fromLTRB(s2.left + 1, y - h, s2.right - 1, y), view.step2[i], const Color(0xFFD9822B), i);
      y -= h;
    }
    // Last month, dotted (slab, after the answer): all of it on step 1.
    final gh = view.ghost;
    if (gh != null) {
      final r = Rect.fromLTRB(s1.left - 2, g.stackBottom - gh * g.u1, s1.right + 2, g.stackBottom);
      _dashedRect(c, r, _stroke(const Color(0xFF3A2A16), 1.8), dash: 3, gap: 3);
      _text(c, '$gh', Offset(r.center.dx, r.top - 5), size: 8, weight: FontWeight.w900, maxWidth: 60);
    }
    if (view.held == M8Part.step1) c.drawRect(g.step1Col.inflate(1), _stroke(const Color(0xAAFFFFFF), 2));
    if (view.held == M8Part.step2) c.drawRect(g.step2Col.inflate(1), _stroke(const Color(0xAAFFFFFF), 2));

    // The floor tray: a slab of ground, the fixed charge on it when put there.
    final fr = g.floor;
    c.drawRRect(RRect.fromRectAndRadius(fr, const Radius.circular(4)), _fill(const Color(0xFFD9CDAA)));
    c.drawRRect(RRect.fromRectAndRadius(fr, const Radius.circular(4)), _stroke(const Color(0xFF786A50), 1.4));
    if (view.floorOn) {
      final t = Rect.fromCenter(center: fr.center, width: fr.width - 20, height: fr.height - 8);
      c.drawRRect(RRect.fromRectAndRadius(t, const Radius.circular(3)), _fill(const Color(0xFF7FB3D5)));
      c.drawRRect(RRect.fromRectAndRadius(t, const Radius.circular(3)), _stroke(const Color(0xFF2C5D7C), 1.4));
      _text(c, fixedLabel, t.center, size: 10, color: const Color(0xFF12324A), maxWidth: t.width - 8);
    }
    if (view.held == M8Part.floor) c.drawRRect(RRect.fromRectAndRadius(fr.inflate(2), const Radius.circular(5)), _stroke(const Color(0xAAFFFFFF), 2));

    // The bin.
    final bn = g.bin;
    final lid = Rect.fromLTWH(bn.left + 2, bn.top + 4, bn.width - 4, 7);
    final body = Rect.fromLTRB(bn.left + 6, lid.bottom, bn.right - 6, bn.bottom);
    c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(4)), _fill(const Color(0xFF9AA2A8)));
    c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(4)), _stroke(const Color(0xFF4B5258), 1.5));
    c.drawRRect(RRect.fromRectAndRadius(lid, const Radius.circular(3)), _fill(const Color(0xFF7B838A)));
    c.drawRRect(RRect.fromRectAndRadius(lid, const Radius.circular(3)), _stroke(const Color(0xFF4B5258), 1.5));
    for (var i = 1; i < 4; i++) {
      final x = body.left + body.width * i / 4;
      c.drawLine(Offset(x, body.top + 6), Offset(x, body.bottom - 5), _stroke(const Color(0x664B5258), 1.4));
    }
  }

  void _block(Canvas c, Rect r, int units, Color color, int i) {
    final shade = i.isOdd ? Color.lerp(color, Colors.white, 0.18)! : color;
    c.drawRect(r, _fill(shade));
    c.drawRect(r, _stroke(const Color(0xFF6B4A1E), 1.2));
    if (r.height >= 11) _text(c, '$units', r.center, size: 9, weight: FontWeight.w900, maxWidth: r.width);
  }

  @override
  bool shouldRepaint(M8BoardPainter old) => old.geo != geo || old.view != view || old.fixedLabel != fixedLabel || old.step1Label != step1Label || old.step2Label != step2Label;
}

/// The cutter pad on the verandah floor (a pair of scissors over a ruler).
class M8CutterPadPainter extends CustomPainter {
  const M8CutterPadPainter({required this.geo, required this.loaded});
  final M8StairsGeo geo;
  final bool loaded;

  @override
  void paint(Canvas c, Size size) {
    final r = geo.cutterPad;
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(8)), _fill(const Color(0xFFE7DCC0)));
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(8)), _stroke(loaded ? const Color(0xFF2E9E4F) : const Color(0xFF786A50), 2));
    // The ruler strip.
    final strip = Rect.fromLTWH(r.left + 10, r.bottom - 34, r.width - 20, 14);
    c.drawRect(strip, _fill(const Color(0xFFF2CF5B)));
    c.drawRect(strip, _stroke(const Color(0xFF8A6A3C), 1.2));
    for (var i = 1; i < 10; i++) {
      final x = strip.left + strip.width * i / 10;
      c.drawLine(Offset(x, strip.top), Offset(x, strip.top + (i.isEven ? 8 : 5)), _stroke(const Color(0xFF8A6A3C), 1));
    }
    // The scissors.
    final m = Offset(r.center.dx, r.top + 38);
    final ink = _stroke(const Color(0xFF2A2018), 3);
    c.drawCircle(m + const Offset(-10, 18), 8, ink);
    c.drawCircle(m + const Offset(10, 18), 8, ink);
    c.drawLine(m + const Offset(-6, 11), m + const Offset(12, -16), ink);
    c.drawLine(m + const Offset(6, 11), m + const Offset(-12, -16), ink);
  }

  @override
  bool shouldRepaint(M8CutterPadPainter old) => old.geo != geo || old.loaded != loaded;
}
