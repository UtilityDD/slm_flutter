import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The drawn world of lesson 7.5 কাজ 2 "দূর থেকে প্রমাণ"
// (m7_theft_evidence.dart), in two places:
//
// Phase 1 (M7LanePainter): a long lane at dusk seen from across the road.
// Layers: the sky (dusk or early night, a street light on at night) → far
// roofs → the LT line on its poles (bare conductors or an AB cable, dealt) →
// four houses, each with its legal service drop into its meter box → on one
// house (dealt, never the one beside the trainee) a theft: a hook (or a
// twisted wire) on the line and a thin wire that runs down into the wall,
// past the meter → the owner on his roof or in his doorway → the road with
// the crew van (left) and a tea stall (right). The theft hook and the wire's
// entry are drawn with the same care as every legal drop and meter, and no
// house is marked.
//
// Phase 2 (M7PolePainter): the same pole next morning, close: the LT line
// with the hook still on it and its wire into the house, the lane DTR's AB
// switch on its own pole at the left (module 7 ruling M7-9: no DO anywhere;
// AB + HG fuses), its handle at ON until the shutdown is called and then OFF
// with a tag; on the ground, in a dealt order: the vigilance officer with his
// order paper, the crew phone on a crate, the PPE bag, the tester beside a
// proving unit, the earth set; sometimes a constable (scenery). Once the bag
// is opened its four items lie in a row in front.
//
// Design: 360 wide × the scene's height. Phase 1 keeps every photographable
// thing under the evidence row at the top (slots and the live view), left of
// the zoom rail, and above the shutter row and the photo roll at the bottom.

/// Where the trainee watches from (phase 1).
enum M7Vantage { van, stall }

/// The LT line: bare conductors or an AB cable (lesson 7.5 point 2: a hook on
/// a bare conductor or on an AB cable).
enum M7LineKind { bare, abc }

/// How the theft is taken off the line: a bent hook, or a wire twisted on.
enum M7Method { hook, twist }

/// Where the house owner is (scenery; he comes out if the trainee walks up).
enum M7Owner { roof, door }

/// The light of phase 1.
enum M7Light { dusk, night }

/// The PPE in the bag (Module 1's set; lesson 7.5 pro tip 4 says "সম্পূর্ণ
/// PPE" without listing it).
enum M7Gear { helmet, gloves, boots, harness }

/// The things on the ground in phase 2 (their places are dealt).
enum M7Spot { officer, phone, bag, tester, earth }

/// The viewfinder at zoom 1 (design px, 4:3); it shrinks as the zoom grows.
const double m7FrameW = 200;
const double m7FrameH = 150;
const double m7ZoomMin = 1;
const double m7ZoomMax = 5;

/// How much of [part] lies inside [frame] (0..1).
double m7Coverage(Rect part, Rect frame) {
  final i = part.intersect(frame);
  if (i.width <= 0 || i.height <= 0) return 0;
  return (i.width * i.height) / (part.width * part.height);
}

/// The phone camera: the frame's centre on the scene and the zoom.
@immutable
class M7Cam {
  const M7Cam(this.center, this.zoom);
  final Offset center;
  final double zoom;

  Rect get frame => Rect.fromCenter(center: center, width: m7FrameW / zoom, height: m7FrameH / zoom);

  @override
  bool operator ==(Object other) => other is M7Cam && other.center == center && other.zoom == zoom;

  @override
  int get hashCode => Object.hash(center, zoom);
}

// ============================================================================
// Phase 1: the lane
// ============================================================================

/// Where things are in the lane (design px, 360 wide).
@immutable
class M7LaneGeo {
  const M7LaneGeo._(this.height, this.groundY, this.topInset);

  /// [inset] the bottom system inset and [topInset] the status bar, both in
  /// design px.
  factory M7LaneGeo.forScene(double height, double inset, {double topInset = 0}) => M7LaneGeo._(height, height - floorUp - inset * 0.5, topInset);

  /// The houses' feet sit this far above the bottom (the shutter row, the
  /// photo roll and the guide stand under them).
  static const double floorUp = 240;

  /// The highest photographable thing starts under the evidence row (design
  /// px below the status bar).
  static const double partsTop = 152;

  /// The four house places (centres).
  static const List<double> houseCx = [52, 127, 202, 276];
  static const double houseW = 56;

  /// The two vantages (the trainee's start).
  static double vantageX(M7Vantage v) => v == M7Vantage.van ? 40 : 226;

  /// A walk this near the stealing house brings its owner out.
  static const double zoneR = 40;

  final double height;
  final double groundY;
  final double topInset;

  /// The LT line (its lowest conductor).
  double get lineY => groundY - 132;

  /// The two poles of the span (a third at the right edge is cut off).
  static const List<double> poleX = [14, 164, 314];

  Rect house(int i) => Rect.fromLTRB(houseCx[i] - houseW / 2, groundY - 74, houseCx[i] + houseW / 2, groundY);
  Rect roof(int i) => Rect.fromLTRB(houseCx[i] - houseW / 2 - 4, groundY - 92, houseCx[i] + houseW / 2 + 4, groundY - 72);

  /// The legal meter box on a house's wall.
  Rect meter(int i) => Rect.fromLTWH(houseCx[i] - houseW / 2 + 6, groundY - 52, 11, 15);

  /// The theft hook on the line over the stealing house.
  Offset hookAt(int i) => Offset(houseCx[i] + 10, lineY);
  Rect hook(int i) {
    final h = hookAt(i);
    return Rect.fromLTRB(h.dx - 8, h.dy - 10, h.dx + 8, h.dy + 10);
  }

  /// Where the theft wire goes into the stealing house (beside its window,
  /// past its meter).
  Offset entryAt(int i) => Offset(houseCx[i] + 14, groundY - 58);
  Rect entry(int i) {
    final e = entryAt(i);
    return Rect.fromLTRB(e.dx - 15, e.dy - 11, e.dx + 15, e.dy + 13);
  }

  /// Where a house's legal drop leaves the line (at the nearer pole).
  Offset dropFrom(int i) {
    final cx = houseCx[i];
    final p = poleX.reduce((a, b) => (a - cx).abs() <= (b - cx).abs() ? a : b);
    return Offset(p, lineY - 6);
  }

  /// The trainee on the road at [x].
  Rect trainee(double x) => Rect.fromLTWH(x - 15, groundY + 62 - 76, 30, 76);
  double get roadTop => groundY + 8;

  /// The frame's centre may go anywhere the frame stays on the scene.
  M7Cam clampCam(M7Cam c) {
    final z = c.zoom.clamp(m7ZoomMin, m7ZoomMax).toDouble();
    final w = m7FrameW / z, fh = m7FrameH / z;
    final x = c.center.dx.clamp(w / 2, 360 - w / 2).toDouble();
    final top = 120 + fh / 2;
    final bottom = math.max(top, groundY + 30 - fh / 2);
    return M7Cam(Offset(x, c.center.dy.clamp(top, bottom).toDouble()), z);
  }

  /// Where the camera starts: the whole row of houses, zoom 1.
  M7Cam get startCam => clampCam(M7Cam(Offset(170, groundY - 70), 1));

  @override
  bool operator ==(Object other) => other is M7LaneGeo && other.height == height && other.groundY == groundY && other.topInset == topInset;

  @override
  int get hashCode => Object.hash(height, groundY, topInset);
}

/// What the lane shows this play.
@immutable
class M7LaneLook {
  const M7LaneLook({
    this.thief = 1,
    this.vantage = M7Vantage.van,
    this.line = M7LineKind.bare,
    this.method = M7Method.hook,
    this.owner = M7Owner.door,
    this.light = M7Light.dusk,
    this.ownerOut = false,
  });

  final int thief;
  final M7Vantage vantage;
  final M7LineKind line;
  final M7Method method;
  final M7Owner owner;
  final M7Light light;

  /// The owner has come out shouting (the trainee walked up).
  final bool ownerOut;

  M7LaneLook withOwnerOut(bool out) => M7LaneLook(thief: thief, vantage: vantage, line: line, method: method, owner: owner, light: light, ownerOut: out);

  @override
  bool operator ==(Object other) =>
      other is M7LaneLook &&
      other.thief == thief &&
      other.vantage == vantage &&
      other.line == line &&
      other.method == method &&
      other.owner == owner &&
      other.light == light &&
      other.ownerOut == ownerOut;

  @override
  int get hashCode => Object.hash(thief, vantage, line, method, owner, light, ownerOut);
}

const _wire = Color(0xFF2E3338);
const _poleGrey = Color(0xFF8C8F8A);
const _meterBox = Color(0xFFE4E7E2);
const _theft = Color(0xFF3A2E22);

const List<List<Color>> _walls = [
  [Color(0xFFE7C99A), Color(0xFFC9A773)],
  [Color(0xFFB9CFC2), Color(0xFF94AE9E)],
  [Color(0xFFE2B4A0), Color(0xFFC08F7B)],
  [Color(0xFFD7D2C2), Color(0xFFB5AF9C)],
];

class M7LanePainter extends CustomPainter {
  const M7LanePainter({required this.geo, required this.look, required this.seed});

  final M7LaneGeo geo;
  final M7LaneLook look;
  final int seed;

  bool get _night => look.light == M7Light.night;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    const w = 360.0;
    final rnd = math.Random(seed);
    final sky = Rect.fromLTWH(0, 0, w, g.groundY + 10);
    c.drawRect(
        sky,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _night ? const [Color(0xFF0E1834), Color(0xFF2B3560), Color(0xFF6A5A78)] : const [Color(0xFF2E4A7E), Color(0xFFB97C78), Color(0xFFF0B27A)],
          ).createShader(sky));
    if (_night) {
      final star = Paint()..color = const Color(0xCCFFFFFF);
      for (var k = 0; k < 18; k++) {
        c.drawCircle(Offset(rnd.nextDouble() * w, 20 + rnd.nextDouble() * (g.lineY - 60)), 0.7 + rnd.nextDouble() * 0.6, star);
      }
    }
    // Far roofs.
    final far = Paint()..color = _night ? const Color(0xFF232B45) : const Color(0xFF6F5C70);
    var x = -10.0;
    while (x < w) {
      final bw = 30 + rnd.nextDouble() * 30;
      final bh = 30 + rnd.nextDouble() * 34;
      c.drawRect(Rect.fromLTWH(x, g.groundY - 74 - bh * 0.6, bw, bh), far);
      x += bw - 2;
    }
    // The verge behind the houses.
    c.drawRect(Rect.fromLTRB(0, g.groundY - 6, w, g.groundY + 8), Paint()..color = _night ? const Color(0xFF2E3A2A) : const Color(0xFF6E7C4E));
    // The road.
    final road = Rect.fromLTRB(0, g.roadTop, w, g.height);
    c.drawRect(road, Paint()..color = _night ? const Color(0xFF2A2D33) : const Color(0xFF55585E));
    final dash = Paint()
      ..color = const Color(0x88E8E2C8)
      ..strokeWidth = 2;
    for (var dx = 6.0; dx < w; dx += 34) {
      c.drawLine(Offset(dx, g.groundY + 74), Offset(dx + 16, g.groundY + 74), dash);
    }
    for (var i = 0; i < 4; i++) {
      _house(c, i);
    }
    _poles(c);
    _line(c);
    for (var i = 0; i < 4; i++) {
      if (i != look.thief) _drop(c, i);
    }
    // The stealing house: its legal drop too (it has a meter), and the theft.
    _drop(c, look.thief);
    _theftWire(c);
    _owner(c);
    if (_night) _streetLight(c);
    _van(c);
    _stall(c);
  }

  void _house(Canvas c, int i) {
    final g = geo;
    final r = g.house(i);
    final cols = _walls[(i + seed) % _walls.length];
    c.drawRect(r, Paint()..shader = LinearGradient(colors: cols, begin: Alignment.topLeft, end: Alignment.bottomRight).createShader(r));
    if (_night) c.drawRect(r, Paint()..color = const Color(0x55101830));
    final roof = g.roof(i);
    c.drawPath(
        Path()
          ..moveTo(roof.left, roof.bottom)
          ..lineTo(roof.left + 6, roof.top)
          ..lineTo(roof.right - 6, roof.top)
          ..lineTo(roof.right, roof.bottom)
          ..close(),
        Paint()..color = _night ? const Color(0xFF4A3A36) : const Color(0xFF8E4B3A));
    // Door and window.
    final door = Rect.fromLTWH(r.center.dx - 7, r.bottom - 30, 14, 30);
    c.drawRect(door, Paint()..color = const Color(0xFF5B3A26));
    final win = Rect.fromLTWH(r.right - 22, r.top + 14, 15, 13);
    c.drawRect(win, Paint()..color = _night ? const Color(0xFFF6D57A) : const Color(0xFF5D7487));
    c.drawLine(win.topCenter, win.bottomCenter, Paint()
      ..color = const Color(0xFF3B2A1E)
      ..strokeWidth = 1);
    // The meter box (every house has one).
    final m = g.meter(i);
    c.drawRRect(RRect.fromRectAndRadius(m, const Radius.circular(1.5)), Paint()..color = _meterBox);
    c.drawRRect(RRect.fromRectAndRadius(m, const Radius.circular(1.5)), Paint()
      ..color = const Color(0xFF6B706B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7);
    c.drawRect(Rect.fromLTWH(m.left + 2, m.top + 3, m.width - 4, 4), Paint()..color = const Color(0xFF26313A));
    c.drawCircle(Offset(m.center.dx, m.bottom - 3.5), 1.4, Paint()..color = const Color(0xFFB71C1C));
  }

  void _poles(Canvas c) {
    final g = geo;
    final p = Paint()..color = _poleGrey;
    for (final x in M7LaneGeo.poleX) {
      c.drawRect(Rect.fromLTRB(x - 2.5, g.lineY - 18, x + 2.5, g.groundY + 4), p);
      c.drawRect(Rect.fromLTRB(x - 14, g.lineY - 18, x + 14, g.lineY - 15), Paint()..color = const Color(0xFF6D706B));
    }
  }

  void _line(Canvas c) {
    final g = geo;
    if (look.line == M7LineKind.bare) {
      final wire = Paint()
        ..color = _wire
        ..strokeWidth = 1.1
        ..style = PaintingStyle.stroke;
      for (var k = 0; k < 4; k++) {
        final y = g.lineY - 3 * k - 0.5;
        final path = Path()..moveTo(0, y + 2);
        for (var s = 0; s < M7LaneGeo.poleX.length - 1; s++) {
          final a = M7LaneGeo.poleX[s], b = M7LaneGeo.poleX[s + 1];
          path
            ..lineTo(a, y)
            ..quadraticBezierTo((a + b) / 2, y + 4, b, y);
        }
        path.lineTo(360, y + 2);
        c.drawPath(path, wire);
      }
    } else {
      final cable = Paint()
        ..color = const Color(0xFF16181B)
        ..strokeWidth = 3.4
        ..style = PaintingStyle.stroke;
      final path = Path()..moveTo(0, g.lineY - 2);
      for (var s = 0; s < M7LaneGeo.poleX.length - 1; s++) {
        final a = M7LaneGeo.poleX[s], b = M7LaneGeo.poleX[s + 1];
        path
          ..lineTo(a, g.lineY - 4)
          ..quadraticBezierTo((a + b) / 2, g.lineY + 2, b, g.lineY - 4);
      }
      path.lineTo(360, g.lineY - 2);
      c.drawPath(path, cable);
    }
  }

  /// A house's legal service drop: from the line at the pole to its meter.
  void _drop(Canvas c, int i) {
    final g = geo;
    final from = g.dropFrom(i);
    final m = g.meter(i);
    final to = Offset(m.center.dx, m.top);
    c.drawPath(
        Path()
          ..moveTo(from.dx, from.dy)
          ..quadraticBezierTo((from.dx + to.dx) / 2, math.max(from.dy, to.dy) - 8, to.dx, to.dy - 10)
          ..lineTo(to.dx, to.dy),
        Paint()
          ..color = const Color(0xFF1C1F22)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke);
    // The clamp at the pole.
    c.drawCircle(from, 1.6, Paint()..color = const Color(0xFF9AA0A6));
  }

  /// The theft: a hook (or a twisted wire) on the line and a thin wire down
  /// into the wall beside the window.
  void _theftWire(Canvas c) {
    final g = geo;
    final i = look.thief;
    final h = g.hookAt(i);
    final e = g.entryAt(i);
    final wire = Paint()
      ..color = _theft
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    if (look.method == M7Method.hook) {
      // A bent rod hung over the top conductor.
      c.drawPath(
          Path()
            ..moveTo(h.dx - 3, h.dy + 6)
            ..lineTo(h.dx - 3, h.dy - 6)
            ..quadraticBezierTo(h.dx - 3, h.dy - 10, h.dx + 1, h.dy - 10)
            ..quadraticBezierTo(h.dx + 5, h.dy - 10, h.dx + 4, h.dy - 6),
          Paint()
            ..color = const Color(0xFF7A6A55)
            ..strokeWidth = 1.6
            ..style = PaintingStyle.stroke);
    } else {
      // A wire wound round the conductor.
      final coil = Paint()
        ..color = const Color(0xFFB0753A)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      for (var k = 0; k < 4; k++) {
        c.drawOval(Rect.fromCenter(center: Offset(h.dx - 4 + k * 2.6, h.dy - 5), width: 2.6, height: 6), coil);
      }
    }
    c.drawPath(
        Path()
          ..moveTo(h.dx - 3, h.dy + 6)
          ..quadraticBezierTo(h.dx + 12, (h.dy + e.dy) / 2, e.dx, e.dy),
        wire);
    // The hole in the wall (no meter on this wire).
    c.drawCircle(e, 1.6, Paint()..color = const Color(0xFF2A1E14));
  }

  void _owner(Canvas c) {
    final g = geo;
    final i = look.thief;
    final r = g.house(i);
    final Offset at;
    if (look.ownerOut) {
      at = Offset(r.center.dx - 12, g.groundY + 4);
    } else if (look.owner == M7Owner.roof) {
      at = Offset(r.left + 12, g.roof(i).top + 1);
    } else {
      at = Offset(r.center.dx, r.bottom);
    }
    _person(c, at, const Color(0xFFF2F2F2), const Color(0xFF3B4E6B), 0.62);
    if (look.ownerOut) {
      final shout = Paint()
        ..color = const Color(0xFFE53935)
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke;
      for (var k = -1; k <= 1; k++) {
        c.drawLine(at.translate(k * 6.0, -40), at.translate(k * 8.0, -48), shout);
      }
    }
  }

  void _streetLight(Canvas c) {
    final g = geo;
    final top = Offset(M7LaneGeo.poleX[1] + 12, g.lineY + 16);
    c.drawLine(Offset(M7LaneGeo.poleX[1], g.lineY + 18), top, Paint()
      ..color = _poleGrey
      ..strokeWidth = 1.6);
    c.drawCircle(top.translate(2, 2), 3, Paint()..color = const Color(0xFFFFF1B8));
    c.drawCircle(top.translate(2, 2), 14, Paint()..color = const Color(0x33FFF1B8));
  }

  void _van(Canvas c) {
    final g = geo;
    final y = g.groundY + 40;
    final body = Rect.fromLTWH(-24, y - 34, 74, 34);
    c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(5)), Paint()..color = const Color(0xFFF3F4F1));
    c.drawRect(Rect.fromLTWH(-24, y - 16, 74, 5), Paint()..color = const Color(0xFF1F5F8F));
    c.drawRect(Rect.fromLTWH(32, y - 30, 14, 11), Paint()..color = const Color(0xFF6D8CA3));
    for (final wx in [-4.0, 34.0]) {
      c.drawCircle(Offset(wx, y), 6, Paint()..color = const Color(0xFF1E2023));
      c.drawCircle(Offset(wx, y), 2.4, Paint()..color = const Color(0xFF9A9EA3));
    }
  }

  void _stall(Canvas c) {
    final g = geo;
    final y = g.groundY + 44;
    final at = 270.0;
    c.drawRect(Rect.fromLTWH(at - 28, y - 26, 56, 26), Paint()..color = const Color(0xFF8B5A2B));
    c.drawPath(
        Path()
          ..moveTo(at - 34, y - 26)
          ..lineTo(at - 26, y - 40)
          ..lineTo(at + 26, y - 40)
          ..lineTo(at + 34, y - 26)
          ..close(),
        Paint()..color = const Color(0xFF2E7D32));
    c.drawRect(Rect.fromLTWH(at - 20, y - 22, 12, 9), Paint()..color = const Color(0xFFBCAAA4));
    c.drawCircle(Offset(at + 10, y - 16), 4, Paint()..color = const Color(0xFFD7CCC8));
  }

  @override
  bool shouldRepaint(M7LanePainter old) => old.geo != geo || old.look != look || old.seed != seed;
}

/// A small standing person (owner, officer, constable): feet at [feet].
void _person(Canvas c, Offset feet, Color shirt, Color pants, double s, {Color? cap}) {
  final h = 64 * s;
  final legs = Paint()
    ..color = pants
    ..strokeWidth = 5 * s
    ..strokeCap = StrokeCap.round;
  c.drawLine(feet.translate(-3 * s, 0), feet.translate(-2 * s, -h * 0.42), legs);
  c.drawLine(feet.translate(3 * s, 0), feet.translate(2 * s, -h * 0.42), legs);
  final body = Rect.fromCenter(center: feet.translate(0, -h * 0.62), width: 16 * s, height: h * 0.4);
  c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(4 * s)), Paint()..color = shirt);
  c.drawCircle(feet.translate(0, -h * 0.92), 6.5 * s, Paint()..color = const Color(0xFFA9724B));
  if (cap != null) {
    c.drawRect(Rect.fromCenter(center: feet.translate(0, -h * 1.0), width: 14 * s, height: 4 * s), Paint()..color = cap);
  }
}

/// The world painted through a crop (the phone's live view and the photos in
/// the roll and the slots): [crop] fills the box; with [cam] it follows the
/// camera.
class M7CropPainter extends CustomPainter {
  M7CropPainter({required this.world, this.crop, this.cam}) : super(repaint: cam);

  final M7LanePainter world;
  final Rect? crop;
  final ValueListenable<M7Cam>? cam;

  @override
  void paint(Canvas c, Size size) {
    final r = crop ?? cam?.value.frame;
    if (r == null || r.width <= 0) return;
    c.save();
    c.clipRect(Offset.zero & size);
    final s = math.max(size.width / r.width, size.height / r.height);
    c.translate((size.width - r.width * s) / 2, (size.height - r.height * s) / 2);
    c.scale(s);
    c.translate(-r.left, -r.top);
    world.paint(c, Size(360, world.geo.height));
    c.restore();
  }

  @override
  bool shouldRepaint(M7CropPainter old) => old.world != world || old.crop != crop || old.cam != cam;
}

/// The viewfinder on the scene: a soft veil outside the frame, white corner
/// brackets, a centre cross. Its look never depends on what is under it.
class M7FramePainter extends CustomPainter {
  M7FramePainter({required this.cam}) : super(repaint: cam);

  final ValueListenable<M7Cam> cam;

  @override
  void paint(Canvas c, Size size) {
    final f = cam.value.frame;
    c.drawPath(
        Path()
          ..fillType = PathFillType.evenOdd
          ..addRect(Offset.zero & size)
          ..addRect(f),
        Paint()..color = const Color(0x3D000000));
    final l = math.min(16.0, f.shortestSide * 0.3);
    for (final p in [
      Paint()
        ..color = const Color(0x66000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    ]) {
      c.drawPath(
          Path()
            ..moveTo(f.left, f.top + l)
            ..lineTo(f.left, f.top)
            ..lineTo(f.left + l, f.top)
            ..moveTo(f.right - l, f.top)
            ..lineTo(f.right, f.top)
            ..lineTo(f.right, f.top + l)
            ..moveTo(f.right, f.bottom - l)
            ..lineTo(f.right, f.bottom)
            ..lineTo(f.right - l, f.bottom)
            ..moveTo(f.left + l, f.bottom)
            ..lineTo(f.left, f.bottom)
            ..lineTo(f.left, f.bottom - l),
          p);
    }
    final cross = Paint()
      ..color = const Color(0xCCFFFFFF)
      ..strokeWidth = 1;
    c.drawLine(f.center.translate(-5, 0), f.center.translate(5, 0), cross);
    c.drawLine(f.center.translate(0, -5), f.center.translate(0, 5), cross);
  }

  @override
  bool shouldRepaint(M7FramePainter old) => old.cam != cam;
}

// ============================================================================
// Phase 2: the pole next morning
// ============================================================================

/// Where things are at the pole (design px, 360 wide).
@immutable
class M7PoleGeo {
  const M7PoleGeo._(this.height, this.groundY);

  factory M7PoleGeo.forScene(double height, double inset) => M7PoleGeo._(height, height - floorUp - inset * 0.5);

  /// The feet line sits this far above the bottom (the ground row and the
  /// opened bag's items stand in front of it, the guide in the corner).
  static const double floorUp = 210;

  final double height;
  final double groundY;

  double get lineY => math.max(150, groundY - 205);
  static const double poleX = 150;

  /// The AB switch's pole (the lane DTR stands off to the left).
  static const double abX = 24;
  Rect get abHandle => Rect.fromLTWH(abX - 7, groundY - 66, 22, 26);

  /// The hook on the line and its wire into the house at the right.
  Offset get hookAt => Offset(232, lineY);
  Rect get hook => Rect.fromLTRB(hookAt.dx - 14, hookAt.dy - 16, hookAt.dx + 14, hookAt.dy + 20);
  Rect get houseWall => Rect.fromLTRB(296, groundY - 120, 380, groundY);
  Offset get entryAt => Offset(300, groundY - 82);

  /// The line as a drop target (the tester's probe, the earth's clamps):
  /// anywhere along the span, a finger's width round it.
  Rect get lineBand => Rect.fromLTRB(40, lineY - 22, 296, lineY + 26);

  /// Where the earth's clamps go on the line (left of the hook).
  Offset get earthAt => Offset(184, lineY);

  /// The five ground places (centres), in a row in front of the trainee.
  static const List<double> spotX = [36, 102, 168, 234, 300];
  double get spotY => groundY + 40;
  Rect spot(int i) => Rect.fromCenter(center: Offset(spotX[i], spotY), width: 54, height: 44);

  /// The officer stands at his place (his body is taller than a thing).
  Rect officer(int i) => Rect.fromLTRB(spotX[i] - 18, spotY - 62, spotX[i] + 18, spotY + 22);

  /// The tester and the proving unit share the tester's place.
  Rect tester(int i) => Rect.fromLTWH(spotX[i] - 26, spotY - 22, 26, 44);
  Rect prover(int i) => Rect.fromLTWH(spotX[i] + 2, spotY - 12, 24, 30);

  /// The opened bag's items (a row in front, left of the guide's corner).
  static const List<double> gearX = [50, 106, 162, 218];
  double get gearY => groundY + 92;
  Rect gear(M7Gear g) => Rect.fromCenter(center: Offset(gearX[g.index], gearY), width: 48, height: 38);

  /// The trainee by the pole.
  Rect get trainee => Rect.fromLTWH(poleX - 52, groundY - 76, 32, 76);

  Offset get constableAt => Offset(338, groundY + 2);

  @override
  bool operator ==(Object other) => other is M7PoleGeo && other.height == height && other.groundY == groundY;

  @override
  int get hashCode => Object.hash(height, groundY);
}

/// What the pole shows now.
@immutable
class M7PoleLook {
  const M7PoleLook({
    this.layout = const [M7Spot.officer, M7Spot.phone, M7Spot.bag, M7Spot.tester, M7Spot.earth],
    this.line = M7LineKind.bare,
    this.method = M7Method.hook,
    this.constable = false,
    this.off = false,
    this.earthed = false,
    this.hookOff = false,
    this.bagOpen = false,
    this.worn = const {},
    this.reading = '',
    this.carrying,
    this.hookLift = 0,
  });

  /// What stands at each ground place.
  final List<M7Spot> layout;
  final M7LineKind line;
  final M7Method method;
  final bool constable;

  /// The shutdown called: the AB handle down to OFF with its tag.
  final bool off;
  final bool earthed;
  final bool hookOff;
  final bool bagOpen;
  final Set<M7Gear> worn;

  /// The tester's last reading ('' none, 'LIVE', '0 V').
  final String reading;

  /// The thing in the trainee's hand (not drawn at its place): a spot, a
  /// gear item, or null.
  final Object? carrying;

  /// How far the hook has been pulled down (design px) while held.
  final double hookLift;

  int at(M7Spot s) => layout.indexOf(s);

  M7PoleLook copyWith({bool? off, bool? earthed, bool? hookOff, bool? bagOpen, Set<M7Gear>? worn, String? reading, Object? carrying = _keep, double? hookLift}) => M7PoleLook(
        layout: layout,
        line: line,
        method: method,
        constable: constable,
        off: off ?? this.off,
        earthed: earthed ?? this.earthed,
        hookOff: hookOff ?? this.hookOff,
        bagOpen: bagOpen ?? this.bagOpen,
        worn: worn ?? this.worn,
        reading: reading ?? this.reading,
        carrying: identical(carrying, _keep) ? this.carrying : carrying,
        hookLift: hookLift ?? this.hookLift,
      );

  @override
  bool operator ==(Object other) =>
      other is M7PoleLook &&
      listEquals(other.layout, layout) &&
      other.line == line &&
      other.method == method &&
      other.constable == constable &&
      other.off == off &&
      other.earthed == earthed &&
      other.hookOff == hookOff &&
      other.bagOpen == bagOpen &&
      setEquals(other.worn, worn) &&
      other.reading == reading &&
      other.carrying == carrying &&
      other.hookLift == hookLift;

  @override
  int get hashCode => Object.hash(Object.hashAll(layout), line, method, constable, off, earthed, hookOff, bagOpen, Object.hashAll(worn.toList()..sort((a, b) => a.index - b.index)), reading, carrying, hookLift);
}

const Object _keep = Object();

class M7PolePainter extends CustomPainter {
  const M7PolePainter({required this.geo, required this.look});

  final M7PoleGeo geo;
  final M7PoleLook look;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    const w = 360.0;
    final sky = Rect.fromLTWH(0, 0, w, g.groundY);
    c.drawRect(
        sky,
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8DB9E0), Color(0xFFD7E8F1), Color(0xFFF5EBD3)])
              .createShader(sky));
    // Far trees.
    final tree = Paint()..color = const Color(0xFF8FAF86);
    for (var k = 0; k < 9; k++) {
      c.drawCircle(Offset(k * 44.0 + 8, g.groundY - 60 - (k % 3) * 8), 26, tree);
    }
    // The ground.
    final ground = Rect.fromLTRB(0, g.groundY - 4, w, g.height);
    c.drawRect(ground, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFB59C74), Color(0xFF8E7856)]).createShader(ground));
    _house(c);
    _abPole(c);
    _pole(c);
    _line(c);
    if (!look.hookOff) _hook(c);
    if (look.earthed) _earthOn(c);
    if (look.constable) _person(c, g.constableAt, const Color(0xFFC7B48A), const Color(0xFFC7B48A), 0.9, cap: const Color(0xFF2F3E2F));
    for (final (i, s) in look.layout.indexed) {
      if (look.carrying == s) continue;
      switch (s) {
        case M7Spot.officer:
          _officer(c, i);
        case M7Spot.phone:
          _phone(c, g.spot(i).center);
        case M7Spot.bag:
          _bag(c, g.spot(i).center);
        case M7Spot.tester:
          _tester(c, g.tester(i).center);
          _prover(c, g.prover(i));
          if (look.reading.isNotEmpty) _readingBox(c, g.spot(i).topCenter.translate(0, -16));
        case M7Spot.earth:
          if (!look.earthed) _earthSet(c, g.spot(i).center);
      }
    }
    if (look.bagOpen) {
      for (final gear in M7Gear.values) {
        if (look.worn.contains(gear) || look.carrying == gear) continue;
        m7PaintGear(c, gear, g.gear(gear).center);
      }
    }
  }

  void _house(Canvas c) {
    final r = geo.houseWall;
    c.drawRect(r, Paint()..color = const Color(0xFFE2B4A0));
    c.drawRect(Rect.fromLTWH(r.left + 18, r.top + 26, 22, 20), Paint()..color = const Color(0xFF5D7487));
    c.drawRect(Rect.fromLTWH(r.left - 4, r.top - 8, r.width + 8, 10), Paint()..color = const Color(0xFF8E4B3A));
    c.drawCircle(geo.entryAt, 2, Paint()..color = const Color(0xFF2A1E14));
  }

  void _abPole(Canvas c) {
    final g = geo;
    const x = M7PoleGeo.abX;
    c.drawRect(Rect.fromLTRB(x - 3, g.lineY - 40, x + 3, g.groundY + 2), Paint()..color = _poleGrey);
    // The AB switch on top (three blades) and the HG fuse horns under it.
    final top = g.lineY - 40;
    for (var k = 0; k < 3; k++) {
      final bx = x - 14.0 + k * 14;
      c.drawRect(Rect.fromLTWH(bx - 1, top - 10, 2, 10), Paint()..color = const Color(0xFFDADDE0));
      final blade = Paint()
        ..color = const Color(0xFF9AA3AA)
        ..strokeWidth = 1.6;
      if (look.off) {
        c.drawLine(Offset(bx, top - 10), Offset(bx + 6, top - 20), blade);
      } else {
        c.drawLine(Offset(bx, top - 10), Offset(bx + 8, top - 10), blade);
      }
      final horn = Paint()
        ..color = const Color(0xFF7E8890)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      c.drawLine(Offset(bx - 3, top + 8), Offset(bx - 1, top + 2), horn);
      c.drawLine(Offset(bx + 3, top + 8), Offset(bx + 1, top + 2), horn);
    }
    // The operating pipe down to the handle.
    c.drawLine(Offset(x + 5, top), Offset(x + 5, g.abHandle.top + 6), Paint()
      ..color = const Color(0xFF5E6368)
      ..strokeWidth = 1.6);
    final hr = g.abHandle;
    c.drawRect(Rect.fromLTWH(hr.left, hr.top + 8, 10, 12), Paint()..color = const Color(0xFF4A5056));
    final lever = Paint()
      ..color = const Color(0xFFC62828)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final pivot = Offset(hr.left + 5, hr.top + 14);
    c.drawLine(pivot, look.off ? pivot.translate(10, 10) : pivot.translate(10, -10), lever);
    _label(c, look.off ? 'OFF' : 'ON', Offset(hr.left + 5, hr.top + 30), 6.5, look.off ? const Color(0xFFB71C1C) : const Color(0xFF1B5E20));
    if (look.off) {
      // The tag on the locked handle.
      final tag = Rect.fromLTWH(pivot.dx + 8, pivot.dy + 8, 14, 18);
      c.drawRRect(RRect.fromRectAndRadius(tag, const Radius.circular(2)), Paint()..color = const Color(0xFFFFD54F));
      c.drawRRect(RRect.fromRectAndRadius(tag, const Radius.circular(2)), Paint()
        ..color = const Color(0xFFB71C1C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);
      c.drawCircle(Offset(pivot.dx + 10, pivot.dy + 10), 2.2, Paint()..color = const Color(0xFF424242));
    }
  }

  void _pole(Canvas c) {
    final g = geo;
    const x = M7PoleGeo.poleX;
    c.drawRect(Rect.fromLTRB(x - 4, g.lineY - 30, x + 4, g.groundY + 2), Paint()..color = _poleGrey);
    c.drawRect(Rect.fromLTRB(x - 30, g.lineY - 30, x + 30, g.lineY - 25), Paint()..color = const Color(0xFF6D706B));
  }

  void _line(Canvas c) {
    final g = geo;
    if (look.line == M7LineKind.bare) {
      final wire = Paint()
        ..color = _wire
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke;
      for (var k = 0; k < 4; k++) {
        final y = g.lineY - 6.0 * k;
        c.drawPath(
            Path()
              ..moveTo(0, y + 3)
              ..quadraticBezierTo(M7PoleGeo.poleX / 2, y + 6, M7PoleGeo.poleX, y)
              ..quadraticBezierTo(255, y + 8, 360, y + 2),
            wire);
      }
    } else {
      c.drawPath(
          Path()
            ..moveTo(0, g.lineY)
            ..quadraticBezierTo(M7PoleGeo.poleX / 2, g.lineY + 4, M7PoleGeo.poleX, g.lineY - 3)
            ..quadraticBezierTo(255, g.lineY + 6, 360, g.lineY),
          Paint()
            ..color = const Color(0xFF16181B)
            ..strokeWidth = 5
            ..style = PaintingStyle.stroke);
    }
  }

  void _hook(Canvas c) {
    final g = geo;
    final h = g.hookAt.translate(0, look.hookLift);
    if (look.method == M7Method.hook) {
      c.drawPath(
          Path()
            ..moveTo(h.dx - 5, h.dy + 12)
            ..lineTo(h.dx - 5, h.dy - 8)
            ..quadraticBezierTo(h.dx - 5, h.dy - 15, h.dx + 2, h.dy - 15)
            ..quadraticBezierTo(h.dx + 9, h.dy - 15, h.dx + 8, h.dy - 8),
          Paint()
            ..color = const Color(0xFF7A6A55)
            ..strokeWidth = 2.6
            ..style = PaintingStyle.stroke);
    } else {
      final coil = Paint()
        ..color = const Color(0xFFB0753A)
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke;
      for (var k = 0; k < 5; k++) {
        c.drawOval(Rect.fromCenter(center: Offset(h.dx - 7 + k * 3.4, h.dy - 7), width: 3.6, height: 10), coil);
      }
    }
    final e = g.entryAt;
    c.drawPath(
        Path()
          ..moveTo(h.dx - 5, h.dy + 12)
          ..quadraticBezierTo(h.dx + 30, (h.dy + e.dy) / 2 + 20, e.dx, e.dy),
        Paint()
          ..color = _theft
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke);
  }

  void _earthOn(Canvas c) {
    final g = geo;
    final at = g.earthAt;
    final lead = Paint()
      ..color = const Color(0xFF2E7D32)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    for (var k = 0; k < 3; k++) {
      final clamp = at.translate(-8.0 + k * 8, -6.0 * (k % 2));
      c.drawRect(Rect.fromCenter(center: clamp, width: 5, height: 7), Paint()..color = const Color(0xFFB0BEC5));
      c.drawPath(
          Path()
            ..moveTo(clamp.dx, clamp.dy + 3)
            ..quadraticBezierTo(clamp.dx - 30, (clamp.dy + g.groundY) / 2, M7PoleGeo.poleX + 18, g.groundY),
          lead);
    }
    // The earth rod.
    c.drawRect(Rect.fromLTWH(M7PoleGeo.poleX + 16, g.groundY - 4, 4, 8), Paint()..color = const Color(0xFF8D6E63));
  }

  void _officer(Canvas c, int i) {
    final r = geo.officer(i);
    final feet = Offset(r.center.dx, r.bottom - 22);
    _person(c, feet, const Color(0xFFF5F5F5), const Color(0xFF37474F), 0.95);
    // His order paper in his hand.
    final paper = Rect.fromLTWH(feet.dx + 7, feet.dy - 44, 14, 18);
    c.drawRect(paper, Paint()..color = Colors.white);
    c.drawRect(paper, Paint()
      ..color = const Color(0xFF90A4AE)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8);
    for (var k = 0; k < 4; k++) {
      c.drawLine(Offset(paper.left + 2, paper.top + 4 + k * 3.5), Offset(paper.right - 2, paper.top + 4 + k * 3.5), Paint()
        ..color = const Color(0xFF90A4AE)
        ..strokeWidth = 0.8);
    }
  }

  void _phone(Canvas c, Offset at) {
    // A crate with the crew phone on it.
    c.drawRect(Rect.fromCenter(center: at.translate(0, 8), width: 40, height: 24), Paint()..color = const Color(0xFF9C7A4B));
    c.drawRect(Rect.fromCenter(center: at.translate(0, 8), width: 40, height: 24), Paint()
      ..color = const Color(0xFF6D532F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);
    final ph = RRect.fromRectAndRadius(Rect.fromCenter(center: at.translate(0, -8), width: 14, height: 24), const Radius.circular(3));
    c.drawRRect(ph, Paint()..color = const Color(0xFF212121));
    c.drawRect(Rect.fromCenter(center: at.translate(0, -9), width: 10, height: 16), Paint()..color = const Color(0xFF64B5F6));
  }

  void _bag(Canvas c, Offset at) {
    final r = Rect.fromCenter(center: at.translate(0, 4), width: 44, height: look.bagOpen ? 22 : 30);
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(6)), Paint()..color = const Color(0xFF1F5F8F));
    c.drawRect(Rect.fromLTWH(r.left, r.top + 6, r.width, 3), Paint()..color = const Color(0xFFFF851B));
    c.drawArc(Rect.fromCenter(center: r.topCenter, width: 18, height: 14), math.pi, math.pi, false, Paint()
      ..color = const Color(0xFF15405F)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke);
  }

  void _tester(Canvas c, Offset at) => m7PaintTester(c, at);

  void _prover(Canvas c, Rect r) {
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), Paint()..color = const Color(0xFFFFC107));
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), Paint()
      ..color = const Color(0xFF795548)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);
    c.drawCircle(r.center.translate(0, -4), 3.2, Paint()..color = const Color(0xFF424242));
    _label(c, 'PROVING', r.center.translate(0, 8), 4.6, const Color(0xFF3E2723));
  }

  void _readingBox(Canvas c, Offset at) {
    final live = look.reading == 'LIVE';
    final r = Rect.fromCenter(center: at, width: 38, height: 14);
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), Paint()..color = const Color(0xFF102027));
    _label(c, look.reading, at, 8, live ? const Color(0xFFFF5252) : const Color(0xFF69F0AE));
  }

  void _earthSet(Canvas c, Offset at) {
    // A coiled green lead with three clamps and the rod.
    final lead = Paint()
      ..color = const Color(0xFF2E7D32)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    for (var k = 0; k < 3; k++) {
      c.drawOval(Rect.fromCenter(center: at.translate(0, 6), width: 34 - k * 6.0, height: 16 - k * 3.0), lead);
    }
    for (var k = 0; k < 3; k++) {
      c.drawRect(Rect.fromCenter(center: at.translate(-12.0 + k * 12, -10), width: 6, height: 8), Paint()..color = const Color(0xFFB0BEC5));
    }
    c.drawRect(Rect.fromLTWH(at.dx + 16, at.dy - 14, 3, 26), Paint()..color = const Color(0xFF8D6E63));
  }

  @override
  bool shouldRepaint(M7PolePainter old) => old.geo != geo || old.look != look;
}

/// The tester (a voltage detector on a short insulated stick), centred at [at].
void m7PaintTester(Canvas c, Offset at) {
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: at.translate(0, 6), width: 8, height: 26), const Radius.circular(3)), Paint()..color = const Color(0xFFFFB300));
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: at.translate(0, -12), width: 12, height: 12), const Radius.circular(3)), Paint()..color = const Color(0xFF37474F));
  c.drawCircle(at.translate(0, -12), 2.6, Paint()..color = const Color(0xFFEF5350));
  c.drawLine(at.translate(0, -18), at.translate(0, -24), Paint()
    ..color = const Color(0xFFB0BEC5)
    ..strokeWidth = 1.6);
}

/// One PPE item, centred at [at].
void m7PaintGear(Canvas c, M7Gear g, Offset at) {
  switch (g) {
    case M7Gear.helmet:
      c.drawArc(Rect.fromCenter(center: at.translate(0, 6), width: 34, height: 30), math.pi, math.pi, true, Paint()..color = const Color(0xFFFFD34E));
      c.drawRect(Rect.fromCenter(center: at.translate(0, 7), width: 40, height: 4), Paint()..color = const Color(0xFFE0B23A));
    case M7Gear.gloves:
      for (final dx in [-9.0, 9.0]) {
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: at.translate(dx, 0), width: 14, height: 26), const Radius.circular(6)), Paint()..color = const Color(0xFFC62828));
        c.drawRect(Rect.fromCenter(center: at.translate(dx, 11), width: 15, height: 5), Paint()..color = const Color(0xFF8E1C1C));
      }
    case M7Gear.boots:
      for (final dx in [-10.0, 10.0]) {
        c.drawPath(
            Path()
              ..moveTo(at.dx + dx - 6, at.dy - 12)
              ..lineTo(at.dx + dx + 2, at.dy - 12)
              ..lineTo(at.dx + dx + 2, at.dy + 4)
              ..lineTo(at.dx + dx + 9, at.dy + 6)
              ..lineTo(at.dx + dx + 9, at.dy + 12)
              ..lineTo(at.dx + dx - 6, at.dy + 12)
              ..close(),
            Paint()..color = const Color(0xFF3E2C22));
      }
    case M7Gear.harness:
      final strap = Paint()
        ..color = const Color(0xFFFF851B)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      c.drawLine(at.translate(-10, -14), at.translate(6, 12), strap);
      c.drawLine(at.translate(10, -14), at.translate(-6, 12), strap);
      c.drawLine(at.translate(-14, 2), at.translate(14, 2), strap);
      c.drawCircle(at.translate(0, -14), 3, Paint()
        ..color = const Color(0xFF9E9E9E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6);
  }
}

void _label(Canvas c, String text, Offset centre, double size, Color color) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: FontWeight.w900, color: color)),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
  tp.dispose();
}

/// What the trainee carries, drawn at the finger while it is dragged.
class M7CarryPainter extends CustomPainter {
  M7CarryPainter({required this.what, required this.at}) : super(repaint: at);

  /// An [M7Spot] (tester, earth) or an [M7Gear].
  final Object what;
  final ValueListenable<Offset?> at;

  @override
  void paint(Canvas c, Size size) {
    final p = at.value;
    if (p == null) return;
    final w = what;
    if (w is M7Gear) {
      m7PaintGear(c, w, p);
    } else if (w == M7Spot.tester) {
      m7PaintTester(c, p);
    } else if (w == M7Spot.earth) {
      final lead = Paint()
        ..color = const Color(0xFF2E7D32)
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke;
      c.drawOval(Rect.fromCenter(center: p.translate(0, 6), width: 30, height: 14), lead);
      for (var k = 0; k < 3; k++) {
        c.drawRect(Rect.fromCenter(center: p.translate(-10.0 + k * 10, -8), width: 6, height: 8), Paint()..color = const Color(0xFFB0BEC5));
      }
    }
  }

  @override
  bool shouldRepaint(M7CarryPainter old) => old.what != what || old.at != at;
}

/// The arc at the hook off a live line: a flash in colour over the frozen
/// grey scene.
class M7FlashPainter extends CustomPainter {
  const M7FlashPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final r = 30 + 150 * v;
    c.drawCircle(
        at,
        r,
        Paint()
          ..shader = RadialGradient(colors: [
            Colors.white.withValues(alpha: (1 - v * 0.6).clamp(0.0, 1.0)),
            const Color(0xFF9FD8FF).withValues(alpha: (0.8 - v * 0.5).clamp(0.0, 1.0)),
            const Color(0x009FD8FF),
          ]).createShader(Rect.fromCircle(center: at, radius: r)));
    final bolt = Paint()
      ..color = Colors.white.withValues(alpha: (1 - v).clamp(0.0, 1.0))
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;
    final rnd = math.Random(7);
    for (var k = 0; k < 5; k++) {
      final a = k * 1.25 + 0.4;
      var p = at;
      final path = Path()..moveTo(p.dx, p.dy);
      for (var s = 0; s < 4; s++) {
        p = p + Offset(math.cos(a), math.sin(a)) * (12 + 10 * v) + Offset(rnd.nextDouble() * 8 - 4, rnd.nextDouble() * 8 - 4);
        path.lineTo(p.dx, p.dy);
      }
      c.drawPath(path, bolt);
    }
  }

  @override
  bool shouldRepaint(M7FlashPainter old) => old.at != at || old.v != v;
}
