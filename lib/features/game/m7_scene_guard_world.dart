import 'dart:math' as math;

import 'package:flutter/material.dart';

// The drawn world of lesson 7.7 কাজ 1 "যেমন ছিল, তেমন থাক"
// (m7_scene_guard.dart): the aftermath of an accident, one of three sites
// (dealt): a roadside LT pole (S1), a village road with a snapped service wire
// (S2) or a feeder pillar (S3). A ground band runs along the bottom; the
// trainee stands on it (dragged left and right), six things lie along it
// (four pieces of evidence, two care things), and hands reach in from the
// frame edges toward one thing at a time.
//
// No text in the art and no highlight: evidence and care things are drawn the
// same plain way and the hands move the same way. The snapped wire's ground
// zone (S2) is not marked.
//
// Design: 360 wide × the scene's height (a tall phone gets more sky, never a
// stretched band). [M7SceneGeo] holds every place; the play logic
// (m7_scene_guard.dart) works in the band's x only.

enum M7Site { pole, village, pillar }

/// Everything that can lie on the band.
enum M7Item { ladder, glove, pliers, scorch, cow, insulator, rope, wire, door, fuse, soot, tape, colleague, child, cart, ember }

/// Where places are (design px).
@immutable
class M7SceneGeo {
  const M7SceneGeo._(this.height, this.groundY, this.site, this.mirror, this.slotOf);

  factory M7SceneGeo.forScene(double height, double inset, M7Site site, bool mirror, Map<M7Item, int> slotOf) {
    final ground = height - floorUp - inset * 0.5;
    return M7SceneGeo._(height, ground, site, mirror, slotOf);
  }

  final double height;

  /// The trainee's feet.
  final double groundY;
  final M7Site site;
  final bool mirror;

  /// Which slot (0..5) each item of this play lies on.
  final Map<M7Item, int> slotOf;

  /// The band's near edge sits this far above the bottom of the screen.
  static const double floorUp = 96;

  /// The trainee's rest place, the slots, the lane around a slot.
  static const double home = 180;
  static const List<double> slotX = [30, 72, 114, 246, 288, 330];
  static const double laneHalf = 22;
  static const double bandMin = 22;
  static const double bandMax = 338;

  double x(double v) => mirror ? 360 - v : v;
  double get horizon => math.max(height * 0.36, groundY - 230);

  /// Where an item lies (its base): two depths, so close slots do not overlap.
  Offset itemAt(M7Item i) {
    final s = slotOf[i] ?? 0;
    return Offset(x(slotX[s]), groundY - 8 - (s.isEven ? 0 : 16));
  }

  /// The lane's centre for an item (the trainee's x that stops the hand).
  /// The snapped wire's lane lies short of its ground zone, on the hand's way.
  double laneX(M7Item i) {
    final v = x(slotX[slotOf[i] ?? 0]);
    if (i != M7Item.wire) return v;
    return v > 180 ? v - 44 : v + 44;
  }

  /// The trainee: feet at [groundY], 48 × 96.
  Rect workerRect(double wx) => Rect.fromLTWH(wx - 24, groundY - 88, 48, 96);
  Offset workerHand(double wx) => Offset(wx, groundY - 48);

  /// The snapped wire's ground zone (S2): the band's x-range around its coil;
  /// null elsewhere.
  ({double a, double b})? get zone {
    if (site != M7Site.village || !slotOf.containsKey(M7Item.wire)) return null;
    final w = x(slotX[slotOf[M7Item.wire] ?? 5]);
    return w > 180 ? (a: w - 18, b: 360) : (a: 0, b: w + 18);
  }

  /// Where a hand comes in from.
  Offset handFrom(bool fromLeft, M7Item i) => Offset(fromLeft ? -30 : 390, itemAt(i).dy - 96);
  Offset handTo(M7Item i) => itemAt(i) + const Offset(0, -16);

  /// The supervisor's van (parked at the near edge, arrives at the end).
  Offset get vanAt => Offset(x(180), horizon + 52);

  @override
  bool operator ==(Object other) =>
      other is M7SceneGeo && other.height == height && other.groundY == groundY && other.site == site && other.mirror == mirror && _same(other.slotOf);

  bool _same(Map<M7Item, int> o) {
    if (o.length != slotOf.length) return false;
    for (final e in slotOf.entries) {
      if (o[e.key] != e.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(height, groundY, site, mirror, slotOf.length);
}

/// One thing as drawn now (taken things fade as the hand carries them off).
@immutable
class M7ItemView {
  const M7ItemView({required this.item, required this.at, this.alpha = 1, this.scale = 1});
  final M7Item item;
  final Offset at;
  final double alpha;
  final double scale;
}

/// A reaching hand as drawn now.
@immutable
class M7HandView {
  const M7HandView({required this.from, required this.to, required this.p, required this.tint});
  final Offset from;
  final Offset to;

  /// How far along from the frame edge to the thing (0..1).
  final double p;
  final int tint;

  /// A point of the hand's curved way (0..1 from the edge to the thing).
  Offset at(double t) {
    final ctrl = Offset((from.dx + to.dx) / 2, math.min(from.dy, to.dy) - 34);
    final a = Offset.lerp(from, ctrl, t)!;
    final b = Offset.lerp(ctrl, to, t)!;
    return Offset.lerp(a, b, t)!;
  }

  Offset get tip => at(p.clamp(0.0, 1.0));
}

/// Everything that moves in the band, drawn now.
@immutable
class M7ActionFrame {
  const M7ActionFrame({this.items = const [], this.hand, this.palmAt, this.van = 0});
  final List<M7ItemView> items;
  final M7HandView? hand;

  /// The raised palm over the trainee (a block).
  final Offset? palmAt;

  /// The van's arrival (0 = away, 1 = parked).
  final double van;
}

// ============================================================================
// Painters
// ============================================================================

const _ink = Color(0xFF1E2329);
const _skin = Color(0xFF9C6B4A);
const _sleeves = [Color(0xFF8E6B4E), Color(0xFF6F7F8E), Color(0xFF7D6A7F), Color(0xFF6E805F), Color(0xFFC77B2C)];

/// The place: sky, scenery, the ground band (static per play).
class M7SceneBackPainter extends CustomPainter {
  const M7SceneBackPainter({required this.geo, required this.seed});
  final M7SceneGeo geo;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    switch (geo.site) {
      case M7Site.pole:
        _pole(canvas, size);
      case M7Site.village:
        _village(canvas, size);
      case M7Site.pillar:
        _pillar(canvas, size);
    }
  }

  void _skyGround(Canvas c, Size size, List<Color> sky, Color far, Color near, Color verge) {
    final h = geo.horizon;
    final skyRect = Rect.fromLTWH(0, 0, size.width, h + 4);
    c.drawRect(
      skyRect,
      Paint()
        ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: sky).createShader(skyRect),
    );
    final ground = Rect.fromLTRB(0, h, size.width, size.height);
    c.drawRect(
      ground,
      Paint()
        ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [far, near]).createShader(ground),
    );
    // The trainee's band: a worn strip.
    final band = Rect.fromLTRB(0, geo.groundY - 46, size.width, geo.groundY + 18);
    c.drawRect(band, Paint()..color = verge.withValues(alpha: 0.5));
    final rng = math.Random(seed);
    final speck = Paint()..color = const Color(0x22000000);
    for (var i = 0; i < 46; i++) {
      c.drawCircle(Offset(rng.nextDouble() * size.width, geo.horizon + 10 + rng.nextDouble() * (size.height - geo.horizon)), 0.8 + rng.nextDouble() * 1.4, speck);
    }
  }

  void _houses(Canvas c, Size size, Color wall, Color roof) {
    final h = geo.horizon;
    final xs = [18.0, 120.0, 238.0, 318.0];
    final ws = [70.0, 84.0, 62.0, 70.0];
    for (var i = 0; i < xs.length; i++) {
      final x = geo.mirror ? 360 - xs[i] - ws[i] : xs[i];
      final top = h - 46 - (i.isEven ? 6 : 18);
      c.drawRect(Rect.fromLTWH(x, top, ws[i], h - top + 2), Paint()..color = wall);
      c.drawRect(Rect.fromLTWH(x - 3, top - 7, ws[i] + 6, 8), Paint()..color = roof);
      c.drawRect(Rect.fromLTWH(x + ws[i] * 0.2, top + 16, 10, 14), Paint()..color = const Color(0x55000000));
      c.drawRect(Rect.fromLTWH(x + ws[i] * 0.62, top + 16, 10, 14), Paint()..color = const Color(0x55000000));
    }
  }

  void _poleAt(Canvas c, double x, double base, double hgt, {bool snapped = false}) {
    final p = Paint()..color = const Color(0xFF6C6458);
    c.drawRect(Rect.fromLTWH(x - 4, base - hgt, 8, hgt), p);
    c.drawRect(Rect.fromLTWH(x - 24, base - hgt + 8, 48, 4), Paint()..color = const Color(0xFF4A453D));
    final w = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    for (final dx in [-20.0, -7.0, 7.0, 20.0]) {
      if (snapped && dx == 7.0) continue;
      c.drawLine(Offset(x + dx, base - hgt + 10), Offset(x + dx + (dx < 0 ? -80 : 80), base - hgt + 18), w);
    }
  }

  void _pole(Canvas c, Size size) {
    _skyGround(c, size, const [Color(0xFF8DB3D6), Color(0xFFC8DAE8), Color(0xFFE3E8E6)], const Color(0xFF8E9186), const Color(0xFF6D7068), const Color(0xFF5A5C55));
    _houses(c, size, const Color(0xFFC9B79C), const Color(0xFF8A5A44));
    final h = geo.horizon;
    // The road (asphalt) with its centre line.
    final road = Rect.fromLTWH(0, h + 14, size.width, 44);
    c.drawRect(road, Paint()..color = const Color(0xFF4B4E53));
    for (var x = 4.0; x < size.width; x += 44) {
      c.drawRect(Rect.fromLTWH(x, road.center.dy - 1, 22, 2.4), Paint()..color = const Color(0xCCE8E2C4));
    }
    // The LT pole with its crossarm, a scorch low on it.
    final px = geo.x(236);
    _poleAt(c, px, h + 70, 190);
    c.drawOval(Rect.fromCenter(center: Offset(px, h + 40), width: 12, height: 26), Paint()..color = const Color(0x99120E0A));
    // The van waits at the far side.
    _van(c, Offset(geo.x(64), h + 62), 0.9, parked: true);
  }

  void _village(Canvas c, Size size) {
    _skyGround(c, size, const [Color(0xFF9CC3E0), Color(0xFFD7E6EE), Color(0xFFEDE7D2)], const Color(0xFF7F9A58), const Color(0xFF677F43), const Color(0xFF8A7A52));
    _houses(c, size, const Color(0xFFB59C7A), const Color(0xFF6E5436));
    final h = geo.horizon;
    // A dirt road across the far ground, palms on the verge.
    c.drawRect(Rect.fromLTWH(0, h + 16, size.width, 40), Paint()..color = const Color(0xFFA68E66));
    for (final px in [28.0, 322.0]) {
      final x = geo.x(px);
      c.drawLine(Offset(x, h + 30), Offset(x + 3, h - 84), Paint()
        ..color = const Color(0xFF6A5A3E)
        ..strokeWidth = 5);
      for (var k = 0; k < 6; k++) {
        final a = -math.pi * (0.1 + 0.16 * k);
        c.drawLine(Offset(x + 3, h - 84), Offset(x + 3 + math.cos(a) * 34, h - 84 - math.sin(a) * 18 + 10), Paint()
          ..color = const Color(0xFF3F6B33)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round);
      }
    }
    // The pole whose service wire has snapped: it droops to the coil on the
    // grass (the coil itself is an item, drawn with the things).
    final pxp = geo.x(200);
    _poleAt(c, pxp, h + 64, 176, snapped: true);
    final wire = geo.itemAt(M7Item.wire);
    final start = Offset(pxp + (geo.mirror ? -7 : 7), h + 64 - 176 + 10);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..quadraticBezierTo((start.dx + wire.dx) / 2, start.dy + 70, wire.dx, wire.dy - 10);
    c.drawPath(
        path,
        Paint()
          ..color = _ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8);
  }

  void _pillar(Canvas c, Size size) {
    _skyGround(c, size, const [Color(0xFF7E8EA0), Color(0xFFB4BEC8), Color(0xFFD5D8D8)], const Color(0xFF8D8B86), const Color(0xFF73726D), const Color(0xFF5C5B57));
    final h = geo.horizon;
    // A brick wall and a shopfront behind the pillar.
    final wall = Rect.fromLTWH(0, h - 96, size.width, 100);
    c.drawRect(wall, Paint()..color = const Color(0xFFB07A5E));
    final line = Paint()
      ..color = const Color(0x33000000)
      ..strokeWidth = 1;
    for (var y = wall.top; y < wall.bottom; y += 10) {
      c.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    for (var x = 0.0; x < size.width; x += 24) {
      for (var y = wall.top; y < wall.bottom; y += 20) {
        c.drawLine(Offset(x + ((y - wall.top) / 10).floor() % 2 * 12, y), Offset(x + ((y - wall.top) / 10).floor() % 2 * 12, y + 10), line);
      }
    }
    c.drawRect(Rect.fromLTWH(geo.x(250), h - 60, 78, 64), Paint()..color = const Color(0xFF3E4A55));
    // The feeder pillar: a grey steel box on a plinth, its door open and
    // scorched (the door is an item).
    final bx = geo.x(180);
    final box = Rect.fromCenter(center: Offset(bx, h + 8), width: 74, height: 96);
    c.drawRect(box.shift(const Offset(0, 4)), Paint()..color = const Color(0xFF55585C));
    c.drawRect(box, Paint()..color = const Color(0xFF8C9298));
    c.drawRect(box.deflate(7), Paint()..color = const Color(0xFF2B2E31));
    for (var i = 0; i < 3; i++) {
      c.drawRect(Rect.fromLTWH(box.left + 14 + i * 17, box.top + 22, 9, 42), Paint()..color = const Color(0xFF5A4F46));
    }
    c.drawRect(Rect.fromLTWH(box.left - 6, box.bottom, box.width + 12, 8), Paint()..color = const Color(0xFF6B6A66));
    // Soot above the box, an oil stain on the ground.
    c.drawOval(Rect.fromCenter(center: Offset(bx, box.top - 10), width: 56, height: 30), Paint()..color = const Color(0x44100C08));
  }

  void _van(Canvas c, Offset base, double s, {required bool parked}) {
    final body = Rect.fromLTWH(base.dx - 38 * s, base.dy - 34 * s, 76 * s, 34 * s);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(6 * s)), Paint()..color = const Color(0xFFE9ECEF));
    c.drawRect(Rect.fromLTWH(body.left + 4 * s, body.top + 5 * s, 24 * s, 12 * s), Paint()..color = const Color(0xFF6E8CA3));
    c.drawRect(Rect.fromLTWH(body.left, body.bottom - 8 * s, body.width, 4 * s), Paint()..color = const Color(0xFFE08A1E));
    for (final dx in [-22.0, 22.0]) {
      c.drawCircle(Offset(base.dx + dx * s, base.dy), 6 * s, Paint()..color = _ink);
      c.drawCircle(Offset(base.dx + dx * s, base.dy), 2.6 * s, Paint()..color = const Color(0xFF9AA0A6));
    }
  }

  @override
  bool shouldRepaint(M7SceneBackPainter old) => old.geo != geo || old.seed != seed;
}

/// The things on the band, the reaching hand, the raised palm and the van
/// (repaints from the level's frame notifier only while something moves).
class M7ActionPainter extends CustomPainter {
  M7ActionPainter({required this.geo, required this.frame, super.repaint});
  final M7SceneGeo geo;
  final M7ActionFrame Function() frame;

  @override
  void paint(Canvas canvas, Size size) {
    final f = frame();
    if (f.van > 0) {
      // The van pulls in from the road's far edge.
      final from = Offset(geo.mirror ? -60 : 420, geo.vanAt.dy);
      final at = Offset.lerp(from, geo.vanAt, Curves.easeOut.transform(f.van.clamp(0.0, 1.0)))!;
      const M7SceneBackPainter(geo: _dummy, seed: 0)._van(canvas, at + const Offset(0, 8), 1.1, parked: f.van >= 1);
    }
    final items = [...f.items]..sort((a, b) => a.at.dy.compareTo(b.at.dy));
    for (final v in items) {
      if (v.alpha <= 0.01) continue;
      canvas.save();
      canvas.translate(v.at.dx, v.at.dy);
      canvas.scale(v.scale);
      if (v.alpha < 0.99) canvas.saveLayer(const Rect.fromLTRB(-70, -90, 70, 30), Paint()..color = Color.fromRGBO(255, 255, 255, v.alpha));
      _item(canvas, v.item);
      if (v.alpha < 0.99) canvas.restore();
      canvas.restore();
    }
    final h = f.hand;
    if (h != null) _hand(canvas, h);
    final palm = f.palmAt;
    if (palm != null) _palm(canvas, palm);
  }

  static const _dummy = M7SceneGeo._(0, 0, M7Site.pole, false, {});

  // --- the hand ----------------------------------------------------------------
  void _hand(Canvas c, M7HandView h) {
    final tip = h.tip;
    final sleeve = Paint()
      ..color = _sleeves[h.tint % _sleeves.length]
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(h.from.dx, h.from.dy);
    const n = 14;
    for (var i = 1; i <= n; i++) {
      final p = h.at(h.p.clamp(0.0, 1.0) * i / n);
      path.lineTo(p.dx, p.dy);
    }
    c.drawPath(path, sleeve);
    // The palm and fingers, open toward the thing.
    final skin = Paint()..color = _skin;
    c.drawCircle(tip, 9, skin);
    for (var i = -2; i <= 2; i++) {
      c.drawLine(tip, tip + Offset(i * 3.4, 11 - i.abs() * 1.2), Paint()
        ..color = _skin
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round);
    }
  }

  /// A raised open palm (the trainee's block).
  void _palm(Canvas c, Offset at) {
    c.drawCircle(at, 12, Paint()..color = const Color(0xEEFFFFFF));
    final p = Paint()..color = const Color(0xFFD8452F);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: at + const Offset(0, 2), width: 9, height: 8), const Radius.circular(2)), p);
    for (var i = 0; i < 4; i++) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(at.dx - 4.5 + i * 2.4, at.dy - 7, 1.8, 7), const Radius.circular(1)), p);
    }
  }

  // --- the things (drawn around their base point, y up is negative) ----------------
  void _shadow(Canvas c, double w) => c.drawOval(Rect.fromCenter(center: const Offset(0, 1), width: w, height: 8), Paint()..color = const Color(0x44000000));

  void _item(Canvas c, M7Item i) {
    switch (i) {
      case M7Item.ladder:
        _shadow(c, 70);
        final rail = Paint()
          ..color = const Color(0xFFB9C0C7)
          ..strokeWidth = 3.2
          ..strokeCap = StrokeCap.round;
        c.drawLine(const Offset(-30, -4), const Offset(30, -14), rail);
        c.drawLine(const Offset(-28, -13), const Offset(32, -22), rail);
        for (var k = 0; k < 6; k++) {
          final t = k / 5;
          c.drawLine(Offset(-28 + t * 58, -5 - t * 10), Offset(-26 + t * 58, -14 - t * 9), Paint()
            ..color = const Color(0xFF8E959C)
            ..strokeWidth = 2);
        }
      case M7Item.glove:
        _shadow(c, 34);
        final p = Paint()..color = const Color(0xFF3B2A22);
        c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-12, -18, 24, 16), const Radius.circular(5)), p);
        for (var k = 0; k < 4; k++) {
          c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-12 + k * 6.2, -30 + (k == 1 || k == 2 ? -3 : 0), 5, 14), const Radius.circular(2.5)), p);
        }
        c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-17, -16, 7, 10), const Radius.circular(3)), p);
        c.drawOval(const Rect.fromLTWH(-6, -14, 9, 6), Paint()..color = const Color(0xFFB5541C));
      case M7Item.pliers:
        _shadow(c, 38);
        final h1 = Paint()
          ..color = const Color(0xFFC0392B)
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round;
        c.drawLine(const Offset(-16, -3), const Offset(6, -13), h1);
        c.drawLine(const Offset(-16, -13), const Offset(6, -3), h1);
        final j = Paint()
          ..color = const Color(0xFF8E959C)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round;
        c.drawLine(const Offset(6, -13), const Offset(18, -9), j);
        c.drawLine(const Offset(6, -3), const Offset(18, -7), j);
        c.drawCircle(const Offset(-1, -8), 2.4, Paint()..color = const Color(0xFF55595E));
      case M7Item.scorch:
        final p = Path()
          ..moveTo(-22, -6)
          ..quadraticBezierTo(-26, -20, -8, -22)
          ..quadraticBezierTo(8, -30, 20, -16)
          ..quadraticBezierTo(30, -4, 10, -2)
          ..quadraticBezierTo(-6, 4, -22, -6);
        c.drawPath(p, Paint()..color = const Color(0xCC15110E));
        c.drawPath(p.shift(const Offset(2, -2)), Paint()..color = const Color(0x6636302A));
        for (var k = 0; k < 5; k++) {
          c.drawCircle(Offset(-18.0 + k * 9, -2.0 - (k.isEven ? 0 : 20)), 2, Paint()..color = const Color(0x8815110E));
        }
      case M7Item.cow:
        _shadow(c, 72);
        c.drawOval(const Rect.fromLTWH(-30, -26, 56, 26), Paint()..color = const Color(0xFF8A5A3C));
        c.drawOval(const Rect.fromLTWH(-14, -22, 14, 10), Paint()..color = const Color(0xFFE9DFCF));
        c.drawOval(const Rect.fromLTWH(22, -22, 16, 14), Paint()..color = const Color(0xFF7A4B31));
        c.drawLine(const Offset(30, -24), const Offset(34, -30), Paint()
          ..color = const Color(0xFFE9DFCF)
          ..strokeWidth = 2);
        final leg = Paint()
          ..color = const Color(0xFF6D4630)
          ..strokeWidth = 3.4
          ..strokeCap = StrokeCap.round;
        for (final dx in [-22.0, -12.0, 8.0, 18.0]) {
          c.drawLine(Offset(dx, -8), Offset(dx + 3, -20 + (dx > 0 ? -8 : 0)), leg);
        }
      case M7Item.insulator:
        _shadow(c, 30);
        final p = Paint()..color = const Color(0xFFD9D2C3);
        c.drawOval(const Rect.fromLTWH(-12, -12, 24, 12), p);
        c.drawOval(const Rect.fromLTWH(-8, -20, 16, 10), Paint()..color = const Color(0xFFC9C1B0));
        c.drawLine(const Offset(2, -20), const Offset(10, -8), Paint()
          ..color = const Color(0xFF55595E)
          ..strokeWidth = 1.6);
        c.drawOval(const Rect.fromLTWH(14, -9, 10, 7), p);
      case M7Item.rope:
        _shadow(c, 38);
        for (var k = 0; k < 4; k++) {
          c.drawOval(
              Rect.fromCenter(center: Offset(0, -8 - k * 1.4), width: 34 - k * 6, height: 16 - k * 3),
              Paint()
                ..color = k.isEven ? const Color(0xFFC9A66B) : const Color(0xFFA88649)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2.6);
        }
        c.drawLine(const Offset(14, -6), const Offset(26, -2), Paint()
          ..color = const Color(0xFFC9A66B)
          ..strokeWidth = 2.6);
      case M7Item.wire:
        _shadow(c, 44);
        for (var k = 0; k < 3; k++) {
          c.drawOval(
              Rect.fromCenter(center: Offset(0, -7 - k * 2), width: 38 - k * 6, height: 15 - k * 2),
              Paint()
                ..color = const Color(0xFF2B2F33)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 3);
        }
        c.drawLine(const Offset(14, -6), const Offset(28, -12), Paint()
          ..color = const Color(0xFF2B2F33)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round);
        c.drawCircle(const Offset(28, -12), 2, Paint()..color = const Color(0xFFBFC4C9));
      case M7Item.door:
        _shadow(c, 40);
        final d = RRect.fromRectAndRadius(const Rect.fromLTWH(-17, -42, 34, 42), const Radius.circular(2));
        c.drawRRect(d, Paint()..color = const Color(0xFF878D93));
        c.drawRRect(d.deflate(4), Paint()..color = const Color(0xFF7A8087));
        c.drawOval(const Rect.fromLTWH(-14, -38, 22, 24), Paint()..color = const Color(0x8815110E));
        c.drawCircle(const Offset(9, -20), 2.2, Paint()..color = const Color(0xFF3F4347));
      case M7Item.fuse:
        _shadow(c, 30);
        c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-6, -26, 12, 26), const Radius.circular(3)), Paint()..color = const Color(0xFFE9E6DF));
        c.drawRect(const Rect.fromLTWH(-8, -30, 16, 6), Paint()..color = const Color(0xFFC0392B));
        c.drawRect(const Rect.fromLTWH(-5, -8, 10, 8), Paint()..color = const Color(0xFF2A2420));
        c.drawLine(const Offset(0, -24), const Offset(0, -10), Paint()
          ..color = const Color(0xFF55595E)
          ..strokeWidth = 1.2);
      case M7Item.soot:
        for (var k = 0; k < 4; k++) {
          c.drawOval(Rect.fromCenter(center: Offset(-12.0 + k * 9, -14.0 - (k.isEven ? 6 : 0)), width: 22 - k * 2, height: 16), Paint()..color = const Color(0x5515110E));
        }
        c.drawOval(const Rect.fromLTWH(-22, -22, 44, 20), Paint()..color = const Color(0x4415110E));
      case M7Item.tape:
        _shadow(c, 30);
        c.drawOval(const Rect.fromLTWH(-13, -18, 26, 18), Paint()..color = const Color(0xFF1C1C1E));
        c.drawOval(const Rect.fromLTWH(-5, -13, 10, 8), Paint()..color = const Color(0xFF6D7480));
        c.drawPath(
            Path()
              ..moveTo(10, -6)
              ..quadraticBezierTo(24, -8, 26, -2),
            Paint()
              ..color = const Color(0xFF1C1C1E)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3);
      case M7Item.colleague:
        _shadow(c, 40);
        c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-11, -40, 22, 30), const Radius.circular(6)), Paint()..color = const Color(0xFF9A7B4E));
        c.drawRect(const Rect.fromLTWH(-13, -12, 26, 12), Paint()..color = const Color(0xFF3F4A5C));
        c.drawCircle(const Offset(0, -48), 8.5, Paint()..color = _skin);
        c.drawArc(Rect.fromCircle(center: const Offset(0, -49), radius: 9), math.pi, math.pi, false, Paint()..color = const Color(0xFF231C18));
        c.drawLine(const Offset(-8, -36), const Offset(-16, -20), Paint()
          ..color = _skin
          ..strokeWidth = 3.4
          ..strokeCap = StrokeCap.round);
        c.drawLine(const Offset(8, -36), const Offset(14, -22), Paint()
          ..color = _skin
          ..strokeWidth = 3.4
          ..strokeCap = StrokeCap.round);
        c.drawOval(const Rect.fromLTWH(-14, -30, 10, 7), Paint()..color = const Color(0x88C0392B));
      case M7Item.child:
        _shadow(c, 24);
        c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-7, -28, 14, 16), const Radius.circular(4)), Paint()..color = const Color(0xFFC0693C));
        c.drawRect(const Rect.fromLTWH(-6, -13, 12, 11), Paint()..color = const Color(0xFF3D4C44));
        c.drawCircle(const Offset(0, -34), 6.5, Paint()..color = _skin);
        c.drawArc(Rect.fromCircle(center: const Offset(0, -35), radius: 7), math.pi, math.pi, false, Paint()..color = const Color(0xFF231C18));
        c.drawLine(const Offset(-7, -24), const Offset(-12, -14), Paint()
          ..color = _skin
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round);
      case M7Item.cart:
        _shadow(c, 56);
        c.drawRect(const Rect.fromLTWH(-26, -26, 42, 7), Paint()..color = const Color(0xFF6E5A3F));
        c.drawLine(const Offset(16, -22), const Offset(26, -36), Paint()
          ..color = const Color(0xFF3F4347)
          ..strokeWidth = 3);
        c.drawLine(const Offset(22, -37), const Offset(30, -35), Paint()
          ..color = const Color(0xFF3F4347)
          ..strokeWidth = 3);
        for (final dx in [-18.0, 8.0, 22.0]) {
          c.drawCircle(Offset(dx, -7), 7, Paint()..color = _ink);
          c.drawCircle(Offset(dx, -7), 2.6, Paint()..color = const Color(0xFF9AA0A6));
        }
        c.drawRect(const Rect.fromLTWH(-22, -32, 18, 6), Paint()..color = const Color(0xFFB5541C));
      case M7Item.ember:
        c.drawOval(const Rect.fromLTWH(-24, -9, 48, 12), Paint()..color = const Color(0xCC15110E));
        c.drawOval(const Rect.fromLTWH(-14, -8, 18, 5), Paint()..color = const Color(0x667A8CA3));
        final flame = Path()
          ..moveTo(-8, -6)
          ..quadraticBezierTo(-12, -22, -2, -34)
          ..quadraticBezierTo(0, -22, 6, -26)
          ..quadraticBezierTo(14, -14, 8, -6)
          ..close();
        c.drawPath(flame, Paint()..color = const Color(0xFFE8751A));
        c.drawPath(flame.shift(const Offset(0, 4)), Paint()..color = const Color(0xFFF4C04A));
    }
  }

  @override
  bool shouldRepaint(M7ActionPainter old) => true;
}

/// The one gesture-hint-free demo is not needed: a deadly move flashes here,
/// in colour over the grey scene.
class M7FlashPainter extends CustomPainter {
  const M7FlashPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas canvas, Size size) {
    final k = Curves.easeOut.transform(v.clamp(0.0, 1.0));
    final glow = Paint()
      ..shader = RadialGradient(colors: [
        Color.fromRGBO(255, 250, 210, 0.95 * (1 - k * 0.4)),
        Color.fromRGBO(255, 190, 60, 0.6 * (1 - k * 0.5)),
        const Color(0x00FF9020),
      ]).createShader(Rect.fromCircle(center: at, radius: 20 + 40 * k));
    canvas.drawCircle(at, 20 + 40 * k, glow);
    final bolt = Paint()
      ..color = Color.fromRGBO(255, 245, 190, 1 - k * 0.5)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + 0.3;
      final r1 = 8 + 10 * k;
      final r2 = 18 + 30 * k;
      final mid = at + Offset(math.cos(a + 0.2) * (r1 + r2) / 2, math.sin(a + 0.2) * (r1 + r2) / 2);
      canvas.drawLine(at + Offset(math.cos(a) * r1, math.sin(a) * r1), mid, bolt);
      canvas.drawLine(mid, at + Offset(math.cos(a) * r2, math.sin(a) * r2), bolt);
    }
  }

  @override
  bool shouldRepaint(M7FlashPainter old) => old.v != v || old.at != at;
}
