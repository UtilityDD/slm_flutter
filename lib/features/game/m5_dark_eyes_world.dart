import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The drawn world of lesson 5.7 কাজ 2 "আঁধারে চোখ-কান" (m5_dark_eyes.dart):
// about 2 a.m. at the edge of a village. A dirt path runs from a house with a
// lit door (the resident) along an in-service 11 kV line. The line crosses
// three stretches, each with two poles and a landmark between them — a pond,
// a bamboo grove, a small temple (the order along the path is dealt). The
// camera follows the trainee along the path and settles on a stretch while
// he stands in it.
//
// Night rules of the picture: before the eyes adapt only silhouettes show.
// The torch lights the stretch he stands in — then every insulator glints
// (so a glint proves nothing). With both lights off and the trainee still,
// the stars come out and the silhouettes lighten (the adaptation); only then
// does the fault's own light — a corona glow, tracking or an intermittent
// flash — show on the faulty insulator. Holes on the path show only in the
// headlamp's beam. Code-drawn, gradients, no bitmaps, no text except the
// pole number plates (a label a worker reads).
//
// Design: 360 wide × the scene's height; the world is [M5DarkEyesGeo.worldW]
// wide and scrolls under a camera ([M5DarkEyesGeo.camFor]).

/// The landmarks between a stretch's poles.
enum M5Landmark { pond, bamboo, temple }

/// The fault's own light (lesson 5.7 point 3).
enum M5Clue { corona, tracking, flash }

/// A sound heard at the fault stretch in the quiet (lesson 5.7 point 4).
enum M5Sound { none, hiss, rattle }

/// Where things are (design px; x in world px, y in scene px).
@immutable
class M5DarkEyesGeo {
  const M5DarkEyesGeo._(this.height, this.groundY, this.armY);

  factory M5DarkEyesGeo.forScene(double height, double inset) {
    final g = height - floorUp - inset * 0.5;
    return M5DarkEyesGeo._(height, g, math.max(190.0, g - 330));
  }

  final double height;

  /// The path line (the trainee's feet).
  final double groundY;

  /// The cross-arms' height.
  final double armY;

  /// The path sits this far above the bottom (the switch row stands under it).
  static const double floorUp = 150;

  static const double worldW = 1820;
  static const List<double> stretchX = [560, 1000, 1440];

  /// A stretch is "here" while the trainee is this close to its centre.
  static const double zoneHalf = 110;
  static const double poleOff = 70;
  static const double startX = 180;
  static const double endX = 1700;
  static const double doorX = 96;

  /// The gaps between the places where holes may lie (world x ranges).
  static const List<(double, double)> holeGaps = [(250, 420), (700, 850), (1140, 1290)];

  /// The stretch the trainee stands in, or null between stretches.
  static int? zoneAt(double x) {
    for (var i = 0; i < stretchX.length; i++) {
      if ((x - stretchX[i]).abs() <= zoneHalf) return i;
    }
    return null;
  }

  /// The camera's left edge for the trainee at world [walker]: it follows him
  /// (he stands a third in) and settles on a stretch as he nears its centre.
  static double camFor(double walker) {
    var cam = walker - 120;
    for (final c in stretchX) {
      final w = (1 - (walker - c).abs() / 150).clamp(0.0, 1.0);
      final ws = w * w * (3 - 2 * w);
      cam = cam + (c - 180 - cam) * ws;
    }
    return cam.clamp(0.0, worldW - 360);
  }

  double poleX(int stretch, int pole) => stretchX[stretch] + (pole == 0 ? -poleOff : poleOff);
  double get poleBaseY => groundY - 28;
  double get poleTopY => armY - 26;

  /// An insulator's centre (world x): phase 0 left pin, 1 the pole-top pin,
  /// 2 right pin.
  Offset insulator(int stretch, int pole, int phase) {
    final px = poleX(stretch, pole);
    return switch (phase) {
      0 => Offset(px - 38, armY - 12),
      1 => Offset(px, armY - 36),
      _ => Offset(px + 38, armY - 12),
    };
  }

  /// The long-press area of an insulator (world x).
  Rect insulatorHit(int stretch, int pole, int phase) => Rect.fromCenter(center: insulator(stretch, pole, phase), width: 34, height: 40);

  /// The number plate on a pole (world x) and its tap area.
  Offset plate(int stretch, int pole) => Offset(poleX(stretch, pole), poleBaseY - 104);
  Rect plateHit(int stretch, int pole) => Rect.fromCenter(center: plate(stretch, pole), width: 44, height: 36);

  /// The house's lit door (world x) and its tap area.
  Rect get door => Rect.fromLTWH(doorX - 14, groundY - 84, 28, 54);
  Rect get doorHit => door.inflate(14);

  /// The trainee's box at world [x].
  Rect walker(double x) => Rect.fromLTWH(x - 26, groundY - 98, 52, 100);

  @override
  bool operator ==(Object other) => other is M5DarkEyesGeo && other.height == height && other.groundY == groundY && other.armY == armY;

  @override
  int get hashCode => Object.hash(height, groundY, armY);
}

/// What the world shows now.
@immutable
class M5DarkView {
  const M5DarkView({
    required this.landmarks,
    required this.poleBase,
    required this.walker,
    required this.facingRight,
    required this.torch,
    required this.headlamp,
    required this.holes,
    required this.residentOut,
    this.marked,
  });

  /// The landmark of each stretch (index = stretch).
  final List<M5Landmark> landmarks;

  /// The first stretch's first pole number (the rest count on).
  final int poleBase;
  final double walker;
  final bool facingRight;
  final bool torch;
  final bool headlamp;

  /// Holes on the path (world x).
  final List<double> holes;

  /// The resident stands in the open door.
  final bool residentOut;

  /// The insulator the trainee marked (stretch, pole, phase).
  final (int, int, int)? marked;

  int poleNumber(int stretch, int pole) => poleBase + stretch * 2 + pole;

  @override
  bool operator ==(Object other) =>
      other is M5DarkView &&
      listEquals(other.landmarks, landmarks) &&
      other.poleBase == poleBase &&
      other.walker == walker &&
      other.facingRight == facingRight &&
      other.torch == torch &&
      other.headlamp == headlamp &&
      listEquals(other.holes, holes) &&
      other.residentOut == residentOut &&
      other.marked == marked;

  @override
  int get hashCode => Object.hash(Object.hashAll(landmarks), poleBase, walker, facingRight, torch, headlamp, Object.hashAll(holes), residentOut, marked);
}

Color _lift(Color c, double p) => Color.lerp(c, const Color(0xFF7D8DA8), p * 0.32)!;

/// The sky and the stars that come out as the eyes adapt ([adapt] 0..1).
class M5DarkSkyPainter extends CustomPainter {
  M5DarkSkyPainter({required this.geo, required this.cam, required this.adapt}) : super(repaint: adapt);
  final M5DarkEyesGeo geo;
  final double cam;
  final ValueListenable<double> adapt;

  @override
  void paint(Canvas canvas, Size size) {
    final p = adapt.value;
    final sky = Rect.fromLTWH(0, 0, 360, geo.groundY);
    canvas.drawRect(
      sky,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color.lerp(const Color(0xFF03060F), const Color(0xFF0A1226), p)!, Color.lerp(const Color(0xFF0B1428), const Color(0xFF1A2742), p)!],
        ).createShader(sky),
    );
    // A few stars always; many once the eyes have adapted.
    final rng = math.Random(57);
    final dot = Paint();
    for (var i = 0; i < 90; i++) {
      final wx = rng.nextDouble() * (M5DarkEyesGeo.worldW * 0.2 + 360);
      final y = 70 + rng.nextDouble() * (geo.armY - 20);
      final r = 0.5 + rng.nextDouble() * 0.9;
      final always = i < 6;
      final a = always ? 0.35 : (p * (0.35 + 0.6 * rng.nextDouble()));
      if (a <= 0.01) continue;
      final x = (wx - cam * 0.2) % (M5DarkEyesGeo.worldW * 0.2 + 360);
      if (x > 362) continue;
      dot.color = Color.fromRGBO(220, 230, 255, a);
      canvas.drawCircle(Offset(x, y), r, dot);
    }
    // The far tree line (slow parallax).
    final far = Path()..moveTo(0, geo.groundY - 40);
    for (var x = 0.0; x <= 360; x += 12) {
      final wx = x + cam * 0.5;
      final hgt = 30 + 18 * math.sin(wx * 0.021) + 12 * math.sin(wx * 0.057 + 1.3);
      far.lineTo(x, geo.groundY - 34 - hgt);
    }
    far
      ..lineTo(360, geo.groundY)
      ..lineTo(0, geo.groundY)
      ..close();
    canvas.drawPath(far, Paint()..color = _lift(const Color(0xFF050A14), p * 0.6));
  }

  @override
  bool shouldRepaint(M5DarkSkyPainter old) => old.geo != geo || old.cam != cam || old.adapt != adapt;
}

/// The place: field, path, house, landmarks, poles, the line, holes, plates.
class M5DarkWorldPainter extends CustomPainter {
  M5DarkWorldPainter({required this.geo, required this.cam, required this.view, required this.adapt}) : super(repaint: adapt);
  final M5DarkEyesGeo geo;
  final double cam;
  final M5DarkView view;
  final ValueListenable<double> adapt;

  double _sx(double wx) => wx - cam;
  bool _seen(double wx, [double pad = 80]) => _sx(wx) > -pad && _sx(wx) < 360 + pad;

  @override
  void paint(Canvas canvas, Size size) {
    final p = adapt.value;
    final g = geo;
    // Field and path.
    final field = Rect.fromLTWH(0, g.groundY - 34, 360, size.height - g.groundY + 34);
    canvas.drawRect(
      field,
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_lift(const Color(0xFF07100C), p), const Color(0xFF03060A)]).createShader(field),
    );
    final path = Path()
      ..moveTo(0, g.groundY - 8)
      ..lineTo(360, g.groundY - 8)
      ..lineTo(360, g.groundY + 16)
      ..lineTo(0, g.groundY + 16)
      ..close();
    canvas.drawPath(path, Paint()..color = _lift(const Color(0xFF151B26), p));
    // Grass tufts along the path edge.
    final tuft = Paint()
      ..color = _lift(const Color(0xFF0C1A10), p)
      ..strokeWidth = 1.2;
    for (var wx = (cam ~/ 23) * 23.0; wx < cam + 380; wx += 23) {
      final x = _sx(wx);
      canvas.drawLine(Offset(x, g.groundY - 8), Offset(x - 3, g.groundY - 16), tuft);
      canvas.drawLine(Offset(x + 4, g.groundY - 8), Offset(x + 6, g.groundY - 15), tuft);
    }
    _house(canvas, p);
    for (var s = 0; s < 3; s++) {
      if (_seen(M5DarkEyesGeo.stretchX[s], 200)) _landmark(canvas, view.landmarks[s], _sx(M5DarkEyesGeo.stretchX[s]), p);
    }
    _line(canvas, p);
    for (var s = 0; s < 3; s++) {
      for (var pole = 0; pole < 2; pole++) {
        if (_seen(g.poleX(s, pole))) _pole(canvas, s, pole, p);
      }
    }
    _holes(canvas);
  }

  void _house(Canvas canvas, double p) {
    final g = geo;
    if (!_seen(80, 120)) return;
    final wall = Rect.fromLTRB(_sx(20), g.groundY - 104, _sx(156), g.groundY - 26);
    canvas.drawRect(wall, Paint()..color = _lift(const Color(0xFF111826), p));
    final roof = Path()
      ..moveTo(wall.left - 10, wall.top + 4)
      ..lineTo(wall.center.dx, wall.top - 30)
      ..lineTo(wall.right + 10, wall.top + 4)
      ..close();
    canvas.drawPath(roof, Paint()..color = _lift(const Color(0xFF1A2130), p));
    // The lit window.
    final win = Rect.fromLTWH(_sx(124), g.groundY - 86, 20, 16);
    canvas.drawRect(win, Paint()..color = const Color(0xFFE8A440));
    canvas.drawRect(win.inflate(10), Paint()..color = const Color(0x22FFB547));
    // The lit door: a crack of light, or open with the resident in it.
    final d = g.door.shift(Offset(-cam, 0));
    canvas.drawRect(d.inflate(16), Paint()..color = const Color(0x1FFFB547));
    if (!view.residentOut) {
      canvas.drawRect(d, Paint()..color = const Color(0xFF3A2814));
      canvas.drawRect(Rect.fromLTWH(d.right - 5, d.top, 4, d.height), Paint()..color = const Color(0xFFFFC566));
      canvas.drawRect(Rect.fromLTWH(d.left, d.bottom - 2, d.width, 2), Paint()..color = const Color(0xFFFFC566));
    } else {
      canvas.drawRect(d, Paint()..color = const Color(0xFFFFC060));
      final body = Paint()..color = const Color(0xFF1D1610);
      canvas.drawCircle(Offset(d.center.dx, d.top + 11), 6, body);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(d.center.dx - 8, d.top + 17, 16, 32), const Radius.circular(5)), body);
      // A lantern in his hand.
      canvas.drawCircle(Offset(d.center.dx + 12, d.top + 34), 9, Paint()..color = const Color(0x44FFD27A));
      canvas.drawCircle(Offset(d.center.dx + 12, d.top + 34), 3.4, Paint()..color = const Color(0xFFFFE2A0));
    }
  }

  void _landmark(Canvas canvas, M5Landmark l, double cx, double p) {
    final g = geo;
    switch (l) {
      case M5Landmark.pond:
        final water = Rect.fromCenter(center: Offset(cx, g.groundY - 46), width: 124, height: 26);
        canvas.drawOval(water.inflate(4), Paint()..color = _lift(const Color(0xFF0A140E), p));
        canvas.drawOval(
          water,
          Paint()
            ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_lift(const Color(0xFF0B1A2E), p), _lift(const Color(0xFF050B16), p)])
                .createShader(water),
        );
        // Star glints on the water once the eyes have adapted.
        final glint = Paint()..color = Color.fromRGBO(200, 215, 255, 0.15 + 0.5 * p);
        for (final dx in [-38.0, -10.0, 22.0, 44.0]) {
          canvas.drawLine(Offset(cx + dx - 4, g.groundY - 46 + dx * 0.08), Offset(cx + dx + 4, g.groundY - 46 + dx * 0.08), glint..strokeWidth = 1);
        }
        final reed = Paint()
          ..color = _lift(const Color(0xFF0D1C12), p)
          ..strokeWidth = 1.4;
        for (final dx in [-66.0, -60.0, 58.0, 64.0, 70.0]) {
          canvas.drawLine(Offset(cx + dx, g.groundY - 40), Offset(cx + dx + 2, g.groundY - 62), reed);
        }
      case M5Landmark.bamboo:
        final stalk = Paint()
          ..color = _lift(const Color(0xFF0E1C10), p)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;
        final leaf = Paint()..color = _lift(const Color(0xFF0B170D), p);
        for (var i = 0; i < 8; i++) {
          final bx = cx - 42 + i * 12.0;
          final top = g.groundY - 120 - (i % 3) * 18.0;
          final lean = (i - 3.5) * 5.0;
          final s = Path()
            ..moveTo(bx, g.groundY - 30)
            ..quadraticBezierTo(bx + lean * 0.3, (g.groundY + top) / 2, bx + lean, top);
          canvas.drawPath(s, stalk);
          canvas.drawOval(Rect.fromCenter(center: Offset(bx + lean, top + 6), width: 26, height: 14), leaf);
        }
      case M5Landmark.temple:
        final body = Paint()..color = _lift(const Color(0xFF181E2C), p);
        final base = Rect.fromLTWH(cx - 30, g.groundY - 88, 60, 58);
        canvas.drawRect(base, body);
        final spire = Path()
          ..moveTo(cx - 24, base.top)
          ..quadraticBezierTo(cx - 14, base.top - 40, cx, base.top - 66)
          ..quadraticBezierTo(cx + 14, base.top - 40, cx + 24, base.top)
          ..close();
        canvas.drawPath(spire, body);
        canvas.drawLine(Offset(cx, base.top - 66), Offset(cx, base.top - 82), Paint()
          ..color = _lift(const Color(0xFF2A2F3C), p)
          ..strokeWidth = 1.4);
        final flag = Path()
          ..moveTo(cx, base.top - 82)
          ..lineTo(cx + 12, base.top - 78)
          ..lineTo(cx, base.top - 74)
          ..close();
        canvas.drawPath(flag, Paint()..color = _lift(const Color(0xFF3A2416), p));
        // Its doorway and a small oil lamp (a landmark light, far from the line).
        final door = Rect.fromLTWH(cx - 9, base.bottom - 30, 18, 30);
        canvas.drawRRect(RRect.fromRectAndCorners(door, topLeft: const Radius.circular(9), topRight: const Radius.circular(9)), Paint()..color = const Color(0xFF07090E));
        canvas.drawCircle(Offset(cx, base.bottom - 7), 7, Paint()..color = const Color(0x33FFB547));
        canvas.drawCircle(Offset(cx, base.bottom - 7), 2.2, Paint()..color = const Color(0xFFFFC870));
    }
  }

  /// The three phases from pole to pole, sagging, across the whole world.
  void _line(Canvas canvas, double p) {
    final g = geo;
    final wire = Paint()
      ..color = _lift(const Color(0xFF2A3446), p)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (var ph = 0; ph < 3; ph++) {
      final pts = <Offset>[
        Offset(-60 - cam, g.insulator(0, 0, ph).dy - 9),
        for (var s = 0; s < 3; s++)
          for (var pole = 0; pole < 2; pole++) g.insulator(s, pole, ph).translate(-cam, -9),
        Offset(M5DarkEyesGeo.worldW + 60 - cam, g.insulator(2, 1, ph).dy - 9),
      ];
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (var i = 1; i < pts.length; i++) {
        final a = pts[i - 1], b = pts[i];
        if (b.dx < -40 || a.dx > 400) {
          path.moveTo(b.dx, b.dy);
          continue;
        }
        final sag = (b.dx - a.dx).abs() * 0.07;
        path.quadraticBezierTo((a.dx + b.dx) / 2, (a.dy + b.dy) / 2 + sag, b.dx, b.dy);
      }
      canvas.drawPath(path, wire);
    }
  }

  void _pole(Canvas canvas, int s, int pole, double p) {
    final g = geo;
    final lit = view.torch && M5DarkEyesGeo.zoneAt(view.walker) == s;
    final x = _sx(g.poleX(s, pole));
    final body = Rect.fromLTRB(x - 4, g.poleTopY, x + 4, g.poleBaseY + 6);
    canvas.drawRect(
      body,
      Paint()
        ..shader = LinearGradient(
          colors: lit ? const [Color(0xFF6E7888), Color(0xFFA9B3C2), Color(0xFF5B6574)] : [_lift(const Color(0xFF151B27), p), _lift(const Color(0xFF232B3A), p), _lift(const Color(0xFF121822), p)],
        ).createShader(body),
    );
    final arm = Rect.fromLTWH(x - 48, g.armY - 3, 96, 6);
    canvas.drawRect(arm, Paint()..color = lit ? const Color(0xFF8E98A6) : _lift(const Color(0xFF1B2230), p));
    for (var ph = 0; ph < 3; ph++) {
      _insulator(canvas, g.insulator(s, pole, ph).translate(-cam, 0), lit, p);
    }
    // The number plate: readable only in the torch light.
    final pc = g.plate(s, pole).translate(-cam, 0);
    final plate = Rect.fromCenter(center: pc, width: 20, height: 13);
    canvas.drawRect(plate, Paint()..color = lit ? const Color(0xFFF2F4F0) : _lift(const Color(0xFF1E2532), p));
    if (lit) {
      final tp = TextPainter(
        text: TextSpan(text: '${view.poleNumber(s, pole)}', style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Color(0xFF14202E))),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, pc - Offset(tp.width / 2, tp.height / 2));
    }
  }

  void _insulator(Canvas canvas, Offset c, bool lit, double p) {
    final body = lit ? const Color(0xFFDCE4EC) : _lift(const Color(0xFF2B3444), p);
    final shed = lit ? const Color(0xFFF4F7FA) : _lift(const Color(0xFF353F51), p);
    canvas.drawRect(Rect.fromCenter(center: c.translate(0, 8), width: 3, height: 8), Paint()..color = lit ? const Color(0xFF8E98A6) : _lift(const Color(0xFF1B2230), p));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: 9, height: 16), const Radius.circular(3)), Paint()..color = body);
    for (final dy in [-4.0, 1.0, 6.0]) {
      canvas.drawOval(Rect.fromCenter(center: c.translate(0, dy), width: 15, height: 4.4), Paint()..color = shed);
    }
  }

  void _holes(Canvas canvas) {
    if (!view.headlamp) return;
    final g = geo;
    for (final h in view.holes) {
      if ((h - view.walker).abs() > 140) continue;
      final r = Rect.fromCenter(center: Offset(_sx(h), g.groundY + 4), width: 30, height: 9);
      canvas.drawOval(r.inflate(2), Paint()..color = const Color(0xFF3A3326));
      canvas.drawOval(r, Paint()..color = const Color(0xFF010203));
    }
  }

  @override
  bool shouldRepaint(M5DarkWorldPainter old) => old.geo != geo || old.cam != cam || old.view != view || old.adapt != adapt;
}

/// The lights: the headlamp's beam on the path, the torch's beam on the
/// stretch (every insulator glints under it), and the trainee's mark.
class M5DarkBeamPainter extends CustomPainter {
  M5DarkBeamPainter({required this.geo, required this.cam, required this.view});
  final M5DarkEyesGeo geo;
  final double cam;
  final M5DarkView view;

  @override
  void paint(Canvas canvas, Size size) {
    final g = geo;
    final x = view.walker - cam;
    final dir = view.facingRight ? 1.0 : -1.0;
    final head = Offset(x + 4 * dir, g.groundY - 88);
    if (view.headlamp) {
      final beam = Path()
        ..moveTo(head.dx, head.dy)
        ..lineTo(x + 170 * dir, g.groundY - 10)
        ..lineTo(x + 170 * dir, g.groundY + 18)
        ..lineTo(x + 26 * dir, g.groundY + 18)
        ..close();
      canvas.drawPath(
        beam,
        Paint()
          ..shader = RadialGradient(colors: const [Color(0x55FFE9B0), Color(0x00FFE9B0)], radius: 1).createShader(Rect.fromCircle(center: head, radius: 190)),
      );
      canvas.drawCircle(head, 2.6, Paint()..color = const Color(0xFFFFF1C4));
    }
    final zone = M5DarkEyesGeo.zoneAt(view.walker);
    if (view.torch) {
      final hand = Offset(x + 12 * dir, g.groundY - 56);
      final aim = zone != null ? Offset(M5DarkEyesGeo.stretchX[zone] - cam, g.armY - 10) : Offset(x + 170 * dir, g.armY + 30);
      final d = aim - hand;
      final n = Offset(-d.dy, d.dx) / d.distance;
      final spread = d.distance * 0.42;
      final beam = Path()
        ..moveTo(hand.dx, hand.dy)
        ..lineTo(aim.dx + n.dx * spread, aim.dy + n.dy * spread)
        ..lineTo(aim.dx - n.dx * spread, aim.dy - n.dy * spread)
        ..close();
      canvas.drawPath(
        beam,
        Paint()..shader = RadialGradient(colors: const [Color(0x4CE6F0FF), Color(0x08E6F0FF)], radius: 1).createShader(Rect.fromCircle(center: hand, radius: d.distance * 1.1)),
      );
      canvas.drawCircle(hand, 2.4, Paint()..color = const Color(0xFFF4F8FF));
      // Under the torch every insulator glints — the glint proves nothing.
      if (zone != null) {
        for (var pole = 0; pole < 2; pole++) {
          for (var ph = 0; ph < 3; ph++) {
            _glint(canvas, g.insulator(zone, pole, ph).translate(-cam - 3, -5));
          }
        }
      }
    }
    final m = view.marked;
    if (m != null) {
      final c = g.insulator(m.$1, m.$2, m.$3).translate(-cam, 0);
      canvas.drawCircle(
        c,
        15,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFFFFC94A),
      );
    }
  }

  void _glint(Canvas canvas, Offset c) {
    final p = Paint()
      ..color = const Color(0xEEFFFFFF)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c.translate(-4, 0), c.translate(4, 0), p);
    canvas.drawLine(c.translate(0, -4), c.translate(0, 4), p);
    canvas.drawCircle(c, 1.4, p);
  }

  @override
  bool shouldRepaint(M5DarkBeamPainter old) => old.geo != geo || old.cam != cam || old.view != view;
}

/// The fault's own light on the faulty insulator, once the eyes have adapted
/// ([t] 0..1 plays once; at 1 a still frame), and a wordless sound wave by the
/// trainee's head if a sound is dealt.
class M5DarkCluePainter extends CustomPainter {
  M5DarkCluePainter({required this.geo, required this.cam, required this.at, required this.clue, required this.sound, required this.walker, required this.t})
      : super(repaint: t);
  final M5DarkEyesGeo geo;
  final double cam;

  /// The faulty insulator (stretch, pole, phase).
  final (int, int, int) at;
  final M5Clue clue;
  final M5Sound sound;
  final double walker;
  final ValueListenable<double> t;

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value;
    final c = geo.insulator(at.$1, at.$2, at.$3).translate(-cam, 0);
    final fadeIn = (v / 0.2).clamp(0.0, 1.0);
    switch (clue) {
      case M5Clue.corona:
        final pulse = v >= 1 ? 0.8 : 0.65 + 0.35 * math.sin(v * math.pi * 9).abs();
        final a = fadeIn * pulse;
        canvas.drawCircle(
          c,
          18,
          Paint()..shader = RadialGradient(colors: [Color.fromRGBO(150, 120, 255, 0.75 * a), Color.fromRGBO(90, 140, 255, 0)]).createShader(Rect.fromCircle(center: c, radius: 18)),
        );
        canvas.drawCircle(c, 5, Paint()..color = Color.fromRGBO(190, 170, 255, 0.55 * a));
      case M5Clue.tracking:
        final flick = v >= 1 ? 0.75 : (math.sin(v * math.pi * 23).abs() > 0.35 ? 1.0 : 0.35);
        final a = fadeIn * flick;
        final line = Paint()
          ..color = Color.fromRGBO(120, 190, 255, 0.95 * a)
          ..strokeWidth = 1.1
          ..style = PaintingStyle.stroke;
        for (final side in [-1.0, 1.0]) {
          final z = Path()..moveTo(c.dx + 3 * side, c.dy - 8);
          for (var i = 1; i <= 4; i++) {
            z.lineTo(c.dx + (i.isOdd ? 6 : 2) * side, c.dy - 8 + i * 4);
          }
          canvas.drawPath(z, line);
        }
        canvas.drawCircle(c, 10, Paint()..color = Color.fromRGBO(110, 170, 255, 0.18 * a));
      case M5Clue.flash:
        // Three bursts, then a faint afterglow held still.
        double burst(double a, double b) => v < a || v > b ? 0 : math.sin((v - a) / (b - a) * math.pi);
        final f = math.max(burst(0.12, 0.2), math.max(burst(0.45, 0.53), burst(0.78, 0.86)));
        final glow = 0.32 * fadeIn;
        canvas.drawCircle(c, 9, Paint()..color = Color.fromRGBO(170, 200, 255, glow));
        if (f > 0) {
          canvas.drawCircle(
            c,
            30 * f + 6,
            Paint()..shader = RadialGradient(colors: [Color.fromRGBO(240, 248, 255, 0.95 * f), Color.fromRGBO(140, 180, 255, 0)]).createShader(Rect.fromCircle(center: c, radius: 30 * f + 6)),
          );
          final ray = Paint()
            ..color = Color.fromRGBO(230, 240, 255, f)
            ..strokeWidth = 1.3;
          for (var k = 0; k < 6; k++) {
            final ang = k * math.pi / 3 + 0.3;
            canvas.drawLine(c + Offset(math.cos(ang), math.sin(ang)) * 6, c + Offset(math.cos(ang), math.sin(ang)) * (12 + 14 * f), ray);
          }
        }
    }
    if (sound != M5Sound.none) {
      // A wordless sound wave by his ear: a hiss is fine and even, a rattle
      // comes in knocks.
      final ear = Offset(walker - cam + 22, geo.groundY - 106);
      final bar = Paint()
        ..color = Color.fromRGBO(255, 214, 120, 0.85 * fadeIn)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      for (var k = 0; k < 5; k++) {
        final phase = v >= 1 ? 0.6 : (math.sin(v * math.pi * 14 + k * 1.1).abs());
        final hgt = sound == M5Sound.hiss ? 3 + 4 * phase : (k.isEven ? 10 * phase + 2 : 2.0);
        final x = ear.dx + k * 5;
        canvas.drawLine(Offset(x, ear.dy - hgt), Offset(x, ear.dy + hgt), bar);
      }
    }
  }

  @override
  bool shouldRepaint(M5DarkCluePainter old) =>
      old.geo != geo || old.cam != cam || old.at != at || old.clue != clue || old.sound != sound || old.walker != walker || old.t != t;
}

/// The deadly end in colour over the grey scene: a ladder up the live pole or
/// a bamboo pushed at the live insulator, and the arc off it ([v] 0..1).
class M5DarkHarmPainter extends CustomPainter {
  M5DarkHarmPainter({required this.geo, required this.cam, required this.at, required this.walker, required this.climb, required this.v});
  final M5DarkEyesGeo geo;
  final double cam;
  final (int, int, int) at;
  final double walker;
  final bool climb;
  final double v;

  @override
  void paint(Canvas canvas, Size size) {
    final c = geo.insulator(at.$1, at.$2, at.$3).translate(-cam, 0);
    if (climb) {
      final px = geo.poleX(at.$1, at.$2) - cam;
      final rail = Paint()
        ..color = const Color(0xFFC9A46A)
        ..strokeWidth = 2.4;
      canvas.drawLine(Offset(px - 22, geo.poleBaseY), Offset(px - 6, geo.armY + 12), rail);
      canvas.drawLine(Offset(px - 10, geo.poleBaseY), Offset(px + 4, geo.armY + 12), rail);
      for (var k = 1; k < 9; k++) {
        final f = k / 9;
        final y = geo.poleBaseY + (geo.armY + 12 - geo.poleBaseY) * f;
        canvas.drawLine(Offset(px - 22 + 16 * f, y), Offset(px - 10 + 14 * f, y), rail..strokeWidth = 1.6);
      }
    } else {
      final hand = Offset(walker - cam + 12, geo.groundY - 60);
      canvas.drawLine(
        hand,
        c.translate(0, 8),
        Paint()
          ..color = const Color(0xFF9DBA5A)
          ..strokeWidth = 3.4
          ..strokeCap = StrokeCap.round,
      );
    }
    final r = 14 + 36 * v;
    canvas.drawCircle(
      c,
      r,
      Paint()..shader = RadialGradient(colors: [Color.fromRGBO(255, 255, 255, 0.95 * v), Color.fromRGBO(120, 170, 255, 0.6 * v), const Color(0x00508CFF)]).createShader(Rect.fromCircle(center: c, radius: r)),
    );
  }

  @override
  bool shouldRepaint(M5DarkHarmPainter old) => old.v != v || old.cam != cam || old.climb != climb || old.at != at || old.walker != walker || old.geo != geo;
}
