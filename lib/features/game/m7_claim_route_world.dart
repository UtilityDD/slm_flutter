import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

// The drawn world of lesson 7.2 কাজ 2 "দাবির পথ" (m7_claim_route.dart): a
// small town seen from above at a slight tilt — a grid of roads, and on its
// crossings the work site (a pole with a ladder), the মোড় (a roundabout), the
// সরকারি হাসপাতাল, the কোম্পানির ডিসপেন্সারি, an ওষুধের দোকান, the company
// office (its gate with a red ডাক বাক্স on one side and the guard booth on the
// other), the worker's home, the শ্রমিক ইউনিয়ন office and the লেবার
// কমিশনারের অফিস. Empty crossings get trees. No path, arrow, glow or number
// marks any stop: the board on each building is the only text (the names a
// worker reads on the street).
//
// Code-drawn, gradients, no bitmaps. Design: 360 wide × the scene's height; a
// tall phone gets more room between the rows, never a stretched town.

/// The stops on the map (the [M7ClaimNode.site] is where the ambulance
/// starts; the [M7ClaimNode.junction] is where it lets him off).
enum M7ClaimNode { site, junction, hospital, dispensary, shop, mailbox, guard, home, union, commissioner }

/// A crossing on the 4 × 3 road grid.
typedef M7Slot = ({int col, int row});

/// The three town layouts (the office's mailbox and guard booth always side by
/// side in one row; the ambulance's site next to the মোড়).
const List<Map<M7ClaimNode, M7Slot>> m7ClaimLayouts = [
  {
    M7ClaimNode.hospital: (col: 0, row: 0),
    M7ClaimNode.shop: (col: 1, row: 0),
    M7ClaimNode.union: (col: 2, row: 0),
    M7ClaimNode.commissioner: (col: 3, row: 0),
    M7ClaimNode.site: (col: 0, row: 1),
    M7ClaimNode.junction: (col: 1, row: 1),
    M7ClaimNode.dispensary: (col: 3, row: 1),
    M7ClaimNode.home: (col: 0, row: 2),
    M7ClaimNode.mailbox: (col: 1, row: 2),
    M7ClaimNode.guard: (col: 2, row: 2),
  },
  {
    M7ClaimNode.union: (col: 0, row: 0),
    M7ClaimNode.mailbox: (col: 1, row: 0),
    M7ClaimNode.guard: (col: 2, row: 0),
    M7ClaimNode.home: (col: 3, row: 0),
    M7ClaimNode.hospital: (col: 0, row: 1),
    M7ClaimNode.junction: (col: 1, row: 1),
    M7ClaimNode.shop: (col: 2, row: 1),
    M7ClaimNode.site: (col: 3, row: 1),
    M7ClaimNode.commissioner: (col: 0, row: 2),
    M7ClaimNode.dispensary: (col: 2, row: 2),
  },
  {
    M7ClaimNode.home: (col: 0, row: 0),
    M7ClaimNode.union: (col: 1, row: 0),
    M7ClaimNode.site: (col: 2, row: 0),
    M7ClaimNode.hospital: (col: 3, row: 0),
    M7ClaimNode.mailbox: (col: 0, row: 1),
    M7ClaimNode.guard: (col: 1, row: 1),
    M7ClaimNode.junction: (col: 2, row: 1),
    M7ClaimNode.shop: (col: 3, row: 1),
    M7ClaimNode.dispensary: (col: 1, row: 2),
    M7ClaimNode.commissioner: (col: 3, row: 2),
  },
];

/// One dealt town: a layout, maybe mirrored left ↔ right, maybe with the
/// hospital and the dispensary swapped (which doctor's desk is nearer).
@immutable
class M7ClaimMap {
  const M7ClaimMap({required this.layout, this.mirror = false, this.swapDesks = false});
  final int layout;
  final bool mirror;
  final bool swapDesks;

  M7Slot slotOf(M7ClaimNode n) {
    var k = n;
    if (swapDesks && n == M7ClaimNode.hospital) k = M7ClaimNode.dispensary;
    if (swapDesks && n == M7ClaimNode.dispensary) k = M7ClaimNode.hospital;
    final s = m7ClaimLayouts[layout][k]!;
    return mirror ? (col: 3 - s.col, row: s.row) : s;
  }

  /// The stop on a crossing, or null (an empty lot).
  M7ClaimNode? nodeAt(M7Slot s) {
    for (final n in M7ClaimNode.values) {
      if (slotOf(n) == s) return n;
    }
    return null;
  }

  @override
  bool operator ==(Object other) => other is M7ClaimMap && other.layout == layout && other.mirror == mirror && other.swapDesks == swapDesks;

  @override
  int get hashCode => Object.hash(layout, mirror, swapDesks);
}

/// Where things are (design px, 360 wide).
@immutable
class M7ClaimGeo {
  const M7ClaimGeo._(this.height, this.bottom);

  factory M7ClaimGeo.forScene(double height, double inset) => M7ClaimGeo._(height, height - inset * 0.5);

  final double height;

  /// The lowest line controls may use (over the system inset).
  final double bottom;

  static const List<double> cols = [45, 135, 225, 315];

  /// The first road row (under the paper tray).
  static const double row0 = 310;

  /// The last road row (clear of the folder, the phone and the guide).
  double get row2 => math.max(row0 + 120, bottom - 206);
  double rowY(int r) => row0 + (row2 - row0) * r / 2;

  /// The space between two road rows.
  double get rowGap => (row2 - row0) / 2;

  Offset slot(M7Slot s) => Offset(cols[s.col], rowY(s.row));
  Offset at(M7ClaimMap map, M7ClaimNode n) => slot(map.slotOf(n));

  /// A release this close to a crossing stops him there.
  static const double nodeR = 34;

  /// The paper tray under the header (papers slide out here).
  static const Rect tray = Rect.fromLTRB(12, 112, 348, 250);

  /// Paper [i] of [n] in the tray.
  static Rect paper(int i, int n) {
    if (n <= 2) {
      const w = 150.0, h = 104.0;
      final gap = n == 1 ? 0.0 : 18.0;
      final total = n * w + (n - 1) * gap;
      final left = tray.center.dx - total / 2 + i * (w + gap);
      return Rect.fromLTWH(left, tray.top + 8, w, h);
    }
    const gap = 8.0;
    final w = (tray.width - 8 - gap * (n - 1)) / n;
    return Rect.fromLTWH(tray.left + 4 + i * (w + gap), tray.top + 20, w, 86);
  }

  /// The company letter, open (with its signature box).
  static const Rect letter = Rect.fromLTRB(16, 110, 344, 252);
  static const Rect sign = Rect.fromLTRB(236, 206, 334, 244);

  /// The claim folder (bottom left) and the phone (beside it).
  Rect get folder => Rect.fromLTWH(10, bottom - 104, 88, 92);
  Rect get phone => Rect.fromLTWH(110, bottom - 98, 60, 84);

  /// The worker drawn standing at [feet].
  static Rect figure(Offset feet) => Rect.fromLTWH(feet.dx - 17, feet.dy - 52, 34, 56);

  /// Where a finger grabs him.
  static Offset grab(Offset feet) => feet.translate(0, -22);
  static const double grabR = 38;

  /// The home's wall calendar (beside the door).
  static Rect calendar(Offset home) => Rect.fromLTWH(home.dx + 14, home.dy - 58, 24, 26);

  @override
  bool operator ==(Object other) => other is M7ClaimGeo && other.height == height && other.bottom == bottom;

  @override
  int get hashCode => Object.hash(height, bottom);
}

/// The names on the buildings' boards (a worker's own words).
abstract final class M7ClaimSigns {
  static const site = 'কাজের জায়গা';
  static const junction = 'মোড়';
  static const hospital = 'সরকারি হাসপাতাল';
  static const dispensary = 'কোম্পানির ডিসপেন্সারি';
  static const shop = 'ওষুধের দোকান';
  static const office = 'কোম্পানি অফিস';
  static const mailbox = 'ডাক বাক্স';
  static const guard = 'গার্ড';
  static const home = 'বাড়ি';
  static const union = 'শ্রমিক ইউনিয়ন';
  static const commissioner = 'লেবার কমিশনারের অফিস';

  static String of(M7ClaimNode n) => switch (n) {
        M7ClaimNode.site => site,
        M7ClaimNode.junction => junction,
        M7ClaimNode.hospital => hospital,
        M7ClaimNode.dispensary => dispensary,
        M7ClaimNode.shop => shop,
        M7ClaimNode.mailbox => mailbox,
        M7ClaimNode.guard => guard,
        M7ClaimNode.home => home,
        M7ClaimNode.union => union,
        M7ClaimNode.commissioner => commissioner,
      };
}

// ============================================================================
// The town
// ============================================================================

class M7ClaimMapPainter extends CustomPainter {
  const M7ClaimMapPainter({required this.geo, required this.map});
  final M7ClaimGeo geo;
  final M7ClaimMap map;

  double get _bh => (geo.rowGap * 0.5).clamp(30.0, 56.0);

  @override
  void paint(Canvas c, Size size) {
    final h = geo.height;
    // Ground: a warm field with a soft vignette.
    c.drawRect(
      Rect.fromLTWH(0, 0, 360, h),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8DB86B), Color(0xFF7AA65C), Color(0xFF6C9550)],
        ).createShader(Rect.fromLTWH(0, 0, 360, h)),
    );
    // A far strip of fields and the sky edge under the header.
    c.drawRect(
      const Rect.fromLTWH(0, 0, 360, 104),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF9FC7E8), Color(0xFFCFE3EE)],
        ).createShader(const Rect.fromLTWH(0, 0, 360, 104)),
    );
    final far = Paint()..color = const Color(0xFF6E9A52);
    for (var i = 0; i < 7; i++) {
      c.drawOval(Rect.fromCenter(center: Offset(20 + i * 56.0, 104), width: 80, height: 22), far);
    }
    // Lawn patches (a little texture, fixed).
    final patch = Paint()..color = const Color(0x22FFFFFF);
    final rnd = math.Random(7);
    for (var i = 0; i < 26; i++) {
      c.drawOval(Rect.fromCenter(center: Offset(rnd.nextDouble() * 360, 110 + rnd.nextDouble() * (h - 110)), width: 18, height: 6), patch);
    }
    _roads(c);
    // Buildings back to front (upper rows first).
    final office = <M7Slot>[map.slotOf(M7ClaimNode.mailbox), map.slotOf(M7ClaimNode.guard)];
    for (var r = 0; r < 3; r++) {
      if (office.first.row == r) _office(c, geo.slot(office.first), geo.slot(office.last));
      for (var col = 0; col < 4; col++) {
        final s = (col: col, row: r);
        final n = map.nodeAt(s);
        final p = geo.slot(s);
        switch (n) {
          case null:
            _trees(c, p);
          case M7ClaimNode.site:
            _site(c, p);
          case M7ClaimNode.junction:
            _junction(c, p);
          case M7ClaimNode.hospital:
            _clinic(c, p, big: true);
          case M7ClaimNode.dispensary:
            _clinic(c, p, big: false);
          case M7ClaimNode.shop:
            _shop(c, p);
          case M7ClaimNode.mailbox:
            _mailbox(c, p);
          case M7ClaimNode.guard:
            _booth(c, p);
          case M7ClaimNode.home:
            _home(c, p);
          case M7ClaimNode.union:
            _union(c, p);
          case M7ClaimNode.commissioner:
            _govt(c, p);
        }
      }
    }
  }

  void _roads(Canvas c) {
    final road = Paint()
      ..color = const Color(0xFF8E8A82)
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;
    final edge = Paint()
      ..color = const Color(0xFF6F6B64)
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round;
    final dash = Paint()
      ..color = const Color(0xCCF3EBD3)
      ..strokeWidth = 1.6;
    final x0 = M7ClaimGeo.cols.first, x1 = M7ClaimGeo.cols.last;
    for (final p in [edge, road]) {
      for (var r = 0; r < 3; r++) {
        final y = geo.rowY(r);
        c.drawLine(Offset(x0 - 40, y), Offset(x1 + 40, y), p);
      }
      for (final x in M7ClaimGeo.cols) {
        c.drawLine(Offset(x, geo.rowY(0) - 20), Offset(x, geo.row2 + 30), p);
      }
    }
    for (var r = 0; r < 3; r++) {
      final y = geo.rowY(r);
      for (var x = x0 - 36; x < x1 + 36; x += 14) {
        c.drawLine(Offset(x, y), Offset(x + 6, y), dash);
      }
    }
  }

  /// A board with the building's name on it.
  void _board(Canvas c, Offset centre, String text, {Color bg = const Color(0xFFF7F1DE), Color ink = const Color(0xFF2A2018), double maxW = 82}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: bangla(fontSize: 8.4, fontWeight: FontWeight.w800, color: ink, height: 1.1)),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 2,
    )..layout(maxWidth: maxW);
    final r = Rect.fromCenter(center: centre, width: tp.width + 8, height: tp.height + 4);
    c.drawRRect(RRect.fromRectAndRadius(r.shift(const Offset(0, 1.5)), const Radius.circular(3)), Paint()..color = const Color(0x55000000));
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), Paint()..color = bg);
    c.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(3)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = const Color(0x88000000));
    tp.paint(c, Offset(r.left + 4, r.top + 2));
  }

  /// A box building standing just above its crossing [p].
  Rect _box(Canvas c, Offset p, {required double w, required double hgt, required List<Color> wall, required Color roof}) {
    final base = p.dy - 12;
    final r = Rect.fromLTRB(p.dx - w / 2, base - hgt, p.dx + w / 2, base);
    // Shadow, then the wall, then a roof slab seen at a tilt.
    c.drawRect(r.shift(const Offset(4, 3)), Paint()..color = const Color(0x33000000));
    c.drawRect(
      r,
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: wall).createShader(r),
    );
    final roofR = Rect.fromLTRB(r.left - 3, r.top - 7, r.right + 3, r.top + 2);
    c.drawRect(roofR, Paint()..color = roof);
    c.drawRect(Rect.fromLTRB(roofR.left, roofR.bottom - 2, roofR.right, roofR.bottom), Paint()..color = const Color(0x33000000));
    return r;
  }

  void _windows(Canvas c, Rect r, {int n = 3, Color glass = const Color(0xFF7FB2D6)}) {
    final w = (r.width - 10) / n;
    final g = Paint()..color = glass;
    for (var i = 0; i < n; i++) {
      final x = r.left + 5 + i * w + w * 0.18;
      c.drawRect(Rect.fromLTWH(x, r.top + r.height * 0.22, w * 0.64, r.height * 0.22), g);
    }
  }

  void _door(Canvas c, Rect r, {Color color = const Color(0xFF6B4A2E)}) {
    c.drawRect(Rect.fromLTWH(r.center.dx - 6, r.bottom - r.height * 0.38, 12, r.height * 0.38), Paint()..color = color);
  }

  void _cross(Canvas c, Offset at, double s, Color color) {
    final p = Paint()..color = color;
    c.drawRect(Rect.fromCenter(center: at, width: s, height: s / 3), p);
    c.drawRect(Rect.fromCenter(center: at, width: s / 3, height: s), p);
  }

  void _clinic(Canvas c, Offset p, {required bool big}) {
    final r = _box(c, p,
        w: big ? 78 : 64,
        hgt: _bh * (big ? 1 : 0.86),
        wall: big ? const [Color(0xFFFFFFFF), Color(0xFFE3E7EA)] : const [Color(0xFFF4FBF5), Color(0xFFD6E9DA)],
        roof: big ? const Color(0xFF8E98A3) : const Color(0xFF4F8A5F));
    _windows(c, r, n: big ? 3 : 2);
    _door(c, r, color: const Color(0xFF5A7A92));
    _cross(c, Offset(r.right - 9, r.top + 8), 9, big ? const Color(0xFFD7332A) : const Color(0xFF2E9E4F));
    _board(c, Offset(p.dx, r.top - 12), big ? M7ClaimSigns.hospital : M7ClaimSigns.dispensary);
  }

  void _shop(Canvas c, Offset p) {
    final r = _box(c, p, w: 58, hgt: _bh * 0.78, wall: const [Color(0xFFF6E7C8), Color(0xFFE2CDA2)], roof: const Color(0xFF9A6B3C));
    // A striped awning over the counter.
    final aw = Rect.fromLTRB(r.left - 2, r.top + r.height * 0.22, r.right + 2, r.top + r.height * 0.42);
    for (var i = 0; i < 6; i++) {
      c.drawRect(Rect.fromLTWH(aw.left + i * aw.width / 6, aw.top, aw.width / 6, aw.height), Paint()..color = i.isEven ? const Color(0xFF2E9E4F) : const Color(0xFFF7F1DE));
    }
    c.drawRect(Rect.fromLTRB(r.left + 4, aw.bottom + 2, r.right - 4, r.bottom - 2), Paint()..color = const Color(0xFF5B4632));
    // Pill bottles on the counter.
    for (var i = 0; i < 4; i++) {
      c.drawRect(Rect.fromLTWH(r.left + 8 + i * 11.0, r.bottom - 10, 6, 8), Paint()..color = [const Color(0xFFE57373), const Color(0xFF64B5F6), const Color(0xFFFFD54F), const Color(0xFF81C784)][i]);
    }
    _board(c, Offset(p.dx, r.top - 12), M7ClaimSigns.shop);
  }

  void _office(Canvas c, Offset a, Offset b) {
    final left = math.min(a.dx, b.dx), right = math.max(a.dx, b.dx);
    final base = a.dy - 12;
    final r = Rect.fromLTRB(left + 6, base - _bh * 0.95, right - 6, base - 8);
    c.drawRect(r.shift(const Offset(4, 3)), Paint()..color = const Color(0x33000000));
    c.drawRect(r, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE9DCC4), Color(0xFFCDBB98)]).createShader(r));
    c.drawRect(Rect.fromLTRB(r.left - 3, r.top - 7, r.right + 3, r.top + 2), Paint()..color = const Color(0xFF7E5A3A));
    _windows(c, r, n: 5, glass: const Color(0xFF8DB7CF));
    // The boundary wall and the gate between the two stops.
    final wall = Paint()..color = const Color(0xFFB9A684);
    c.drawRect(Rect.fromLTRB(left - 30, base - 9, right + 30, base - 3), wall);
    final g = Paint()
      ..color = const Color(0xFF4A4F57)
      ..strokeWidth = 1.6;
    final gc = (left + right) / 2;
    for (var x = gc - 14; x <= gc + 14; x += 5) {
      c.drawLine(Offset(x, base - 18), Offset(x, base - 2), g);
    }
    _board(c, Offset(gc, r.top - 12), M7ClaimSigns.office, maxW: 96);
  }

  void _mailbox(Canvas c, Offset p) {
    // A red pillar box by the gate.
    final body = Rect.fromLTWH(p.dx - 9, p.dy - 44, 18, 30);
    c.drawRect(body.shift(const Offset(3, 2)), Paint()..color = const Color(0x33000000));
    c.drawRRect(
      RRect.fromRectAndCorners(body, topLeft: const Radius.circular(9), topRight: const Radius.circular(9)),
      Paint()..shader = const LinearGradient(colors: [Color(0xFFE53935), Color(0xFFB71C1C)]).createShader(body),
    );
    c.drawRect(Rect.fromLTWH(p.dx - 6, p.dy - 34, 12, 2.5), Paint()..color = const Color(0xFF3A0D0D));
    _board(c, Offset(p.dx, p.dy - 54), M7ClaimSigns.mailbox, bg: const Color(0xFFFFEBEE));
  }

  void _booth(Canvas c, Offset p) {
    final r = Rect.fromLTWH(p.dx - 13, p.dy - 46, 26, 32);
    c.drawRect(r.shift(const Offset(3, 2)), Paint()..color = const Color(0x33000000));
    c.drawRect(r, Paint()..color = const Color(0xFF90A4AE));
    c.drawRect(Rect.fromLTWH(r.left + 4, r.top + 6, r.width - 8, 9), Paint()..color = const Color(0xFF8DB7CF));
    c.drawRect(Rect.fromLTRB(r.left - 3, r.top - 5, r.right + 3, r.top + 1), Paint()..color = const Color(0xFF455A64));
    _board(c, Offset(p.dx, p.dy - 58), M7ClaimSigns.guard, bg: const Color(0xFFECEFF1));
  }

  void _home(Canvas c, Offset p) {
    final base = p.dy - 12;
    final r = Rect.fromLTRB(p.dx - 26, base - _bh * 0.8, p.dx + 26, base);
    c.drawRect(r.shift(const Offset(4, 3)), Paint()..color = const Color(0x33000000));
    c.drawRect(r, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF3D9B1), Color(0xFFDDBA88)]).createShader(r));
    // A tiled roof.
    final roof = Path()
      ..moveTo(r.left - 6, r.top + 2)
      ..lineTo(p.dx, r.top - 16)
      ..lineTo(r.right + 6, r.top + 2)
      ..close();
    c.drawPath(roof, Paint()..color = const Color(0xFFB4532A));
    c.drawPath(
        roof,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0xFF7A3418));
    _door(c, r, color: const Color(0xFF6B4A2E));
    c.drawRect(Rect.fromLTWH(r.left + 5, r.top + r.height * 0.3, 10, 9), Paint()..color = const Color(0xFF7FB2D6));
    _board(c, Offset(p.dx - 18, r.top - 20), M7ClaimSigns.home, bg: const Color(0xFFFFF3E0));
  }

  void _union(Canvas c, Offset p) {
    final r = _box(c, p, w: 64, hgt: _bh * 0.86, wall: const [Color(0xFFFFF0E0), Color(0xFFEBCFB0)], roof: const Color(0xFF8D3B2F));
    _windows(c, r, n: 2);
    _door(c, r);
    // A flag on a pole.
    final pole = Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 1.6;
    c.drawLine(Offset(r.right - 6, r.top - 6), Offset(r.right - 6, r.top - 24), pole);
    c.drawRect(Rect.fromLTWH(r.right - 6, r.top - 24, 13, 8), Paint()..color = const Color(0xFFD32F2F));
    _board(c, Offset(p.dx - 4, r.top - 12), M7ClaimSigns.union);
  }

  void _govt(Canvas c, Offset p) {
    final r = _box(c, p, w: 80, hgt: _bh, wall: const [Color(0xFFFFF8E7), Color(0xFFE6D9BB)], roof: const Color(0xFF9E9E9E));
    // Columns and a pediment.
    final col = Paint()..color = const Color(0xFFFDFBF4);
    for (var i = 0; i < 5; i++) {
      c.drawRect(Rect.fromLTWH(r.left + 6 + i * 15.0, r.top + 6, 5, r.height - 8), col);
    }
    final ped = Path()
      ..moveTo(r.left - 2, r.top - 6)
      ..lineTo(p.dx, r.top - 18)
      ..lineTo(r.right + 2, r.top - 6)
      ..close();
    c.drawPath(ped, Paint()..color = const Color(0xFFBDB6A2));
    _board(c, Offset(p.dx, r.top - 26), M7ClaimSigns.commissioner, maxW: 88);
  }

  void _site(Canvas c, Offset p) {
    // A line pole with its cross-arm and a ladder against it.
    final base = p.dy - 12;
    final pole = Rect.fromLTWH(p.dx - 3, base - _bh * 1.15, 6, _bh * 1.15);
    c.drawRect(pole, Paint()..shader = const LinearGradient(colors: [Color(0xFF9EA4AA), Color(0xFF6B7178)]).createShader(pole));
    c.drawRect(Rect.fromLTWH(p.dx - 18, pole.top + 6, 36, 3.5), Paint()..color = const Color(0xFF5A6066));
    for (final dx in [-15.0, 0.0, 15.0]) {
      c.drawCircle(Offset(p.dx + dx, pole.top + 4), 2.2, Paint()..color = const Color(0xFF8D6E63));
    }
    final w = Paint()
      ..color = const Color(0xFF3A3F45)
      ..strokeWidth = 0.9;
    c.drawLine(Offset(p.dx - 45, pole.top + 4), Offset(p.dx + 45, pole.top + 6), w);
    final lad = Paint()
      ..color = const Color(0xFFB08A4E)
      ..strokeWidth = 1.6;
    c.drawLine(Offset(p.dx + 14, base), Offset(p.dx + 4, pole.top + 16), lad);
    c.drawLine(Offset(p.dx + 22, base), Offset(p.dx + 11, pole.top + 16), lad);
    for (var k = 1; k < 6; k++) {
      final t = k / 6;
      c.drawLine(Offset.lerp(Offset(p.dx + 14, base), Offset(p.dx + 4, pole.top + 16), t)!, Offset.lerp(Offset(p.dx + 22, base), Offset(p.dx + 11, pole.top + 16), t)!, lad);
    }
    // A safety cone.
    final cone = Path()
      ..moveTo(p.dx - 22, base)
      ..lineTo(p.dx - 17, base - 13)
      ..lineTo(p.dx - 12, base)
      ..close();
    c.drawPath(cone, Paint()..color = const Color(0xFFFF7043));
    _board(c, Offset(p.dx - 6, pole.top - 10), M7ClaimSigns.site);
  }

  void _junction(Canvas c, Offset p) {
    c.drawCircle(p, 16, Paint()..color = const Color(0xFF6F6B64));
    c.drawCircle(p, 11, Paint()..color = const Color(0xFF7BA35E));
    c.drawCircle(p, 4, Paint()..color = const Color(0xFFF7F1DE));
    _board(c, p.translate(-28, -22), M7ClaimSigns.junction, bg: const Color(0xFFFFF8E1));
  }

  void _trees(Canvas c, Offset p) {
    for (final (dx, s) in [(-16.0, 1.0), (10.0, 0.85), (-2.0, 0.7)]) {
      final at = Offset(p.dx + dx, p.dy - 26 * s - 10);
      c.drawRect(Rect.fromLTWH(at.dx - 1.5, at.dy, 3, 12 * s), Paint()..color = const Color(0xFF6D4C41));
      c.drawCircle(at, 11 * s, Paint()..color = const Color(0xFF4E8B3A));
      c.drawCircle(at.translate(-3, -3), 6 * s, Paint()..color = const Color(0x3389C26B));
    }
  }

  @override
  bool shouldRepaint(M7ClaimMapPainter old) => old.geo != geo || old.map != map;
}

/// The ambulance on the road (its body points along [dir]).
class M7AmbulancePainter extends CustomPainter {
  const M7AmbulancePainter({required this.at, required this.dir, this.lights = false});
  final Offset at;
  final Offset dir;
  final bool lights;

  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.translate(at.dx, at.dy - 9);
    final flip = dir.dx < -0.1;
    if (flip) c.scale(-1, 1);
    final body = Rect.fromLTWH(-20, -10, 40, 18);
    c.drawRect(body.shift(const Offset(2, 3)), Paint()..color = const Color(0x44000000));
    c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(3)), Paint()..color = const Color(0xFFFDFDFD));
    c.drawRect(const Rect.fromLTWH(9, -8, 9, 7), Paint()..color = const Color(0xFF7FB2D6));
    c.drawRect(const Rect.fromLTWH(-20, 0, 40, 2.5), Paint()..color = const Color(0xFFD7332A));
    final cross = Paint()..color = const Color(0xFFD7332A);
    c.drawRect(const Rect.fromLTWH(-9, -7, 3, 9), cross);
    c.drawRect(const Rect.fromLTWH(-12, -4, 9, 3), cross);
    c.drawRect(Rect.fromLTWH(-4, -13, 8, 3), Paint()..color = lights ? const Color(0xFF42A5F5) : const Color(0xFF1E5A8A));
    for (final x in [-12.0, 12.0]) {
      c.drawCircle(Offset(x, 8), 3.6, Paint()..color = const Color(0xFF263238));
    }
    c.restore();
  }

  @override
  bool shouldRepaint(M7AmbulancePainter old) => old.at != at || old.dir != dir || old.lights != lights;
}

/// The injured worker: blue shirt, his arm in a white sling, a bag at his
/// hip with the claim folder's corner showing.
class M7WorkerPainter extends CustomPainter {
  const M7WorkerPainter({this.lifted = false});

  /// He is being dragged (a little higher, a bigger shadow).
  final bool lifted;

  @override
  void paint(Canvas c, Size size) {
    final s = size.width / 34;
    c.save();
    c.scale(s, s);
    final up = lifted ? -3.0 : 0.0;
    c.drawOval(Rect.fromCenter(center: const Offset(17, 53), width: lifted ? 26 : 20, height: 6), Paint()..color = const Color(0x44000000));
    c.translate(0, up);
    final skin = Paint()..color = const Color(0xFFC68B59);
    // Legs and shoes.
    final leg = Paint()
      ..color = const Color(0xFF37474F)
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round;
    c.drawLine(const Offset(13.5, 38), const Offset(12.5, 50), leg);
    c.drawLine(const Offset(20.5, 38), const Offset(21.5, 50), leg);
    // The shirt.
    final shirt = RRect.fromRectAndRadius(const Rect.fromLTWH(9, 18, 16, 22), const Radius.circular(4));
    c.drawRRect(shirt, Paint()..shader = const LinearGradient(colors: [Color(0xFF42A5F5), Color(0xFF1E6FB5)]).createShader(shirt.outerRect));
    // The free arm.
    final arm = Paint()
      ..color = const Color(0xFF1E6FB5)
      ..strokeWidth = 3.6
      ..strokeCap = StrokeCap.round;
    c.drawLine(const Offset(24.5, 21), const Offset(27, 34), arm);
    c.drawCircle(const Offset(27, 35.5), 1.9, skin);
    // The bag strap, the bag and the folder's corner.
    c.drawLine(
        const Offset(22, 19),
        const Offset(10, 36),
        Paint()
          ..color = const Color(0xFF6D4C41)
          ..strokeWidth = 1.6);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(3, 33, 11, 9), const Radius.circular(2)), Paint()..color = const Color(0xFF8D6E63));
    c.drawRect(const Rect.fromLTWH(5, 31, 7, 3), Paint()..color = const Color(0xFFE8C77A));
    // The sling: the arm bent across the chest in a white cloth.
    c.drawLine(
        const Offset(11, 19),
        const Offset(23, 29),
        Paint()
          ..color = const Color(0xFFF5F5F5)
          ..strokeWidth = 1.8);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(10, 26, 13, 6), const Radius.circular(3)), Paint()..color = const Color(0xFFFAFAFA));
    c.drawRRect(
        RRect.fromRectAndRadius(const Rect.fromLTWH(10, 26, 13, 6), const Radius.circular(3)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6
          ..color = const Color(0xFFB0BEC5));
    // Head and hair.
    c.drawCircle(const Offset(17, 11), 6, skin);
    c.drawArc(Rect.fromCircle(center: const Offset(17, 10), radius: 6.2), math.pi, math.pi, true, Paint()..color = const Color(0xFF2B1B12));
    c.drawCircle(const Offset(19.2, 11.5), 0.8, Paint()..color = const Color(0xFF2B1B12));
    c.restore();
  }

  @override
  bool shouldRepaint(M7WorkerPainter old) => old.lifted != lifted;
}

/// The claim folder: a manila folder; one paper edge shows for each paper in.
class M7FolderPainter extends CustomPainter {
  const M7FolderPainter({required this.papers});
  final int papers;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width, h = size.height;
    final back = Rect.fromLTWH(4, h * 0.18, w - 8, h * 0.74);
    c.drawRRect(RRect.fromRectAndRadius(back.shift(const Offset(2, 3)), const Radius.circular(5)), Paint()..color = const Color(0x55000000));
    c.drawRRect(RRect.fromRectAndRadius(back, const Radius.circular(5)), Paint()..color = const Color(0xFFC9A55C));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(8, h * 0.1, w * 0.36, h * 0.14), const Radius.circular(3)), Paint()..color = const Color(0xFFC9A55C));
    for (var i = 0; i < papers.clamp(0, 6); i++) {
      final r = Rect.fromLTWH(10 + i * 2.0, h * 0.2 - i * 3.0, w - 24, h * 0.5);
      c.drawRect(r, Paint()..color = const Color(0xFFFDFBF4));
      c.drawRect(
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.6
            ..color = const Color(0x55000000));
    }
    final front = Rect.fromLTWH(4, h * 0.36, w - 8, h * 0.56);
    c.drawRRect(
      RRect.fromRectAndRadius(front, const Radius.circular(5)),
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE8C77A), Color(0xFFD1AC5E)]).createShader(front),
    );
  }

  @override
  bool shouldRepaint(M7FolderPainter old) => old.papers != papers;
}

/// The home's wall calendar; [turn] (0…1 per page) lifts the top page over.
class M7CalendarPainter extends CustomPainter {
  const M7CalendarPainter({required this.turn});
  final double turn;

  @override
  void paint(Canvas c, Size size) {
    final r = Offset.zero & size;
    c.drawRect(r.shift(const Offset(1.5, 1.5)), Paint()..color = const Color(0x44000000));
    c.drawRect(r, Paint()..color = const Color(0xFFFDFBF4));
    c.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.26), Paint()..color = const Color(0xFFD32F2F));
    final dot = Paint()..color = const Color(0x553A2A16);
    for (var y = 0; y < 3; y++) {
      for (var x = 0; x < 4; x++) {
        c.drawRect(Rect.fromLTWH(3 + x * 5.0, size.height * 0.38 + y * 5.0, 3, 2.5), dot);
      }
    }
    final f = turn - turn.floorToDouble();
    if (f > 0.001) {
      // The top page lifting up and over (no dates: a game device).
      final lift = Rect.fromLTWH(0, size.height * 0.26, size.width, size.height * 0.74 * (1 - f));
      c.drawRect(lift, Paint()..color = const Color(0xFFF1E8D2));
      c.drawRect(
          lift,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.6
            ..color = const Color(0x66000000));
    }
  }

  @override
  bool shouldRepaint(M7CalendarPainter old) => old.turn != turn;
}

/// The point [t] (0…1) along the L-shaped road from [a] to [b] (along the
/// row first, then the column), and the way it is heading.
(Offset, Offset) m7RoadPoint(Offset a, Offset b, double t) {
  final corner = Offset(b.dx, a.dy);
  final l1 = (corner - a).distance, l2 = (b - corner).distance;
  final total = l1 + l2;
  if (total <= 0) return (a, const Offset(1, 0));
  final d = t.clamp(0.0, 1.0) * total;
  if (d <= l1 && l1 > 0) {
    final dir = (corner - a) / l1;
    return (a + dir * d, dir);
  }
  final dir = l2 > 0 ? (b - corner) / l2 : const Offset(1, 0);
  return (corner + dir * (d - l1), dir);
}
