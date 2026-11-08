import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The field for lesson 1.9 কাজ 2 ("সুপারভাইজারের চাপ"): a village roadside where
// a crew's job is half done and the weather turns. A drawn, layered place —
// sky and a cloud bank that builds and darkens, far tree line and huts, the
// paddy, the verge with a lone tree, the 11 kV pole with its three wires, the
// crew's van on the shoulder and the road in front — plus the weather: drizzle
// or driving rain (front layer), wind that bends the trees and sets the wires
// galloping, and lightning flashes. No text in the art.
//
// Motion runs only while the scene's clock is awake (AwakeClock): an idle
// screen holds a still frame. Design: 360 wide × the scene's height; the
// ground row follows the bottom of the screen.

/// How the sky looks now (all 0..1).
@immutable
class StormWeather {
  const StormWeather({required this.cloud, required this.rain, required this.wind, required this.lightning});

  /// 0 = a few white clouds, 1 = a black bank.
  final double cloud;

  /// 0 = dry, ~0.3 = drizzle, 1 = driving rain.
  final double rain;

  /// 0 = still, 1 = a gale (trees bent, wires galloping).
  final double wind;

  /// 1 = a thunderstorm (flashes, a bolt in the distance).
  final double lightning;

  static const fair = StormWeather(cloud: 0.2, rain: 0, wind: 0.04, lightning: 0);
  static const drizzle = StormWeather(cloud: 0.5, rain: 0.28, wind: 0.06, lightning: 0);
  static const gale = StormWeather(cloud: 0.8, rain: 0.9, wind: 1, lightning: 0);
  static const thunder = StormWeather(cloud: 1, rain: 0.75, wind: 0.42, lightning: 1);

  static StormWeather lerp(StormWeather a, StormWeather b, double t) {
    double l(double x, double y) => x + (y - x) * t;
    return StormWeather(cloud: l(a.cloud, b.cloud), rain: l(a.rain, b.rain), wind: l(a.wind, b.wind), lightning: l(a.lightning, b.lightning));
  }

  @override
  bool operator ==(Object other) =>
      other is StormWeather && other.cloud == cloud && other.rain == rain && other.wind == wind && other.lightning == lightning;

  @override
  int get hashCode => Object.hash(cloud, rain, wind, lightning);
}

/// Animates one weather into the next.
class StormWeatherTween extends Tween<StormWeather> {
  StormWeatherTween({super.begin, super.end});

  @override
  StormWeather lerp(double t) => StormWeather.lerp(begin ?? end!, end ?? begin!, t);
}

/// Where things stand (design px, 360 wide).
@immutable
class StormGeo {
  const StormGeo({required this.height, required this.groundY, required this.length});

  factory StormGeo.forScene(double h, double inset) {
    // The ground row stands clear of the corner guide and his bubble.
    final g = h - 236 - inset;
    return StormGeo(height: h, groundY: g, length: (g - 180).clamp(240.0, 380.0));
  }

  /// The pole's axis.
  static const poleX = 150.0;

  /// The lone tree on the verge.
  static const treeX = 314.0;

  final double height;

  /// Where the pole enters the soil (the verge's front edge).
  final double groundY;

  /// The pole above the ground.
  final double length;

  double get topY => groundY - length;
  double get armY => topY + 18;
  double get horizonY => groundY - 74;

  /// Metres of pole per design px (9 m above ground).
  double get ppm => length / 9;

  /// The ladder leans on the pole: its feet on the verge, its top at the
  /// cross-arm's height minus a little.
  Offset get ladderFoot => Offset(poleX + 48, groundY + 4);
  Offset get ladderTop => Offset(poleX + 8, groundY - length * 0.64);
  double get ladderLength => (ladderTop - ladderFoot).distance;

  /// The crew's van on the shoulder, front left.
  Rect get van => Rect.fromLTWH(2, groundY - 40, 116, 62);

  /// The worker's size (1.7 m).
  Size get worker => Size(36, 1.75 * ppm);

  /// Where the crown of the lone tree sits (before the wind bends it).
  Offset get crown => Offset(treeX, groundY - 132);

  @override
  bool operator ==(Object other) => other is StormGeo && other.height == height && other.groundY == groundY && other.length == length;

  @override
  int get hashCode => Object.hash(height, groundY, length);
}

/// How bright a lightning flash is at second [t] of the clock (0 = none).
/// Flashes come early in each awake window and never at its end, so the
/// still frame after it is dark.
double stormFlashAt(double t, double lightning) {
  if (lightning < 0.5) return 0;
  var f = 0.0;
  for (final at in const [0.35, 2.6, 4.4]) {
    final d = t - at;
    if (d < 0 || d > 0.42) continue;
    // A double flicker.
    final a = d < 0.08 ? 1.0 : (d < 0.14 ? 0.25 : (d < 0.22 ? 0.85 : 1 - (d - 0.22) / 0.2));
    f = math.max(f, a.clamp(0.0, 1.0));
  }
  return f * lightning;
}

Color _dim(Color c, double k) => Color.lerp(c, const Color(0xFF1A2230), k.clamp(0.0, 1.0))!;

/// The place: sky, far land, verge, tree, pole and wires, van, road.
class StormWorldPainter extends CustomPainter {
  StormWorldPainter({required this.geo, required this.weather, required this.clock, required this.quiet}) : super(repaint: clock);

  final StormGeo geo;
  final StormWeather weather;
  final ValueListenable<double> clock;
  final bool quiet;

  @override
  void paint(Canvas c, Size s) {
    final t = clock.value;
    final w = weather;
    final dark = w.cloud * 0.62;
    final flash = quiet ? 0.0 : stormFlashAt(t, w.lightning);
    final hz = geo.horizonY;
    final g = geo.groundY;

    // --- sky ---------------------------------------------------------------
    final sky = Rect.fromLTWH(0, 0, s.width, hz + 6);
    c.drawRect(
      sky,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(const Color(0xFF6FA6D6), const Color(0xFF151C27), w.cloud)!,
            Color.lerp(const Color(0xFFA7CBE6), const Color(0xFF323C4A), w.cloud)!,
            Color.lerp(const Color(0xFFE9E3CC), const Color(0xFF5B6670), w.cloud)!,
          ],
          stops: const [0, 0.6, 1],
        ).createShader(sky),
    );
    // A distant bolt behind the clouds (always in a thunderstorm, so a still
    // frame shows it too), brighter in a flash.
    if (w.lightning > 0.5) _bolt(c, Offset(s.width * 0.78, hz * 0.34), Offset(s.width * 0.7, hz - 8), 0.35 + 0.65 * flash, 11);
    // The cloud bank: lower, wider and darker as the weather builds.
    _clouds(c, s, t, dark);

    // --- far land ----------------------------------------------------------
    final farTree = _dim(const Color(0xFF3E6A3A), dark + 0.1);
    final sway = w.wind * (0.6 + 0.4 * math.sin(t * 2.4));
    final far = Path()..moveTo(0, hz + 2);
    for (var x = 0.0; x <= s.width + 16; x += 12) {
      final bump = 10 + 7 * math.sin(x * 0.05) + 5 * math.sin(x * 0.17 + 1.1);
      far.quadraticBezierTo(x + 6 + sway * 10, hz - bump - 8 + sway * 3, x + 12, hz - bump * 0.55);
    }
    far
      ..lineTo(s.width, hz + 4)
      ..lineTo(0, hz + 4)
      ..close();
    c.drawPath(far, Paint()..color = farTree);
    // Huts at the edge of the village.
    final hut = Paint()..color = _dim(const Color(0xFF8E7356), dark + 0.15);
    final roof = Paint()..color = _dim(const Color(0xFF5A4636), dark + 0.15);
    for (final x in const [40.0, 70.0, 238.0]) {
      c.drawRect(Rect.fromLTWH(x, hz - 12, 20, 12), hut);
      c.drawPath(
        Path()
          ..moveTo(x - 4, hz - 11)
          ..lineTo(x + 10, hz - 22)
          ..lineTo(x + 24, hz - 11)
          ..close(),
        roof,
      );
    }
    // The paddy between the far trees and the verge.
    final field = Rect.fromLTRB(0, hz, s.width, g - 6);
    c.drawRect(
      field,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_dim(const Color(0xFF8DB25A), dark), _dim(const Color(0xFF5E8C3A), dark)],
        ).createShader(field),
    );
    final row = Paint()
      ..color = _dim(const Color(0xFF4E7A31), dark).withValues(alpha: 0.55)
      ..strokeWidth = 1;
    for (var y = hz + 6.0; y < g - 8; y += 7 + (y - hz) * 0.12) {
      c.drawLine(Offset(0, y), Offset(s.width, y + 1), row);
    }
    // Rain blurs the far land.
    if (w.rain > 0.05) {
      c.drawRect(Rect.fromLTRB(0, hz * 0.4, s.width, g), Paint()..color = const Color(0xFF8B97A3).withValues(alpha: 0.18 * w.rain));
    }

    // --- the verge, the shoulder, the road ---------------------------------
    final verge = Rect.fromLTRB(0, g - 8, s.width, g + 16);
    c.drawRect(verge, Paint()..color = _dim(const Color(0xFF6E8F3C), dark));
    final shoulder = Rect.fromLTRB(0, g + 14, s.width, g + 34);
    c.drawRect(shoulder, Paint()..color = _dim(const Color(0xFF9B7B52), dark));
    final road = Rect.fromLTRB(0, g + 32, s.width, s.height);
    c.drawRect(
      road,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_dim(const Color(0xFF555B61), dark * 0.8), _dim(const Color(0xFF3B4045), dark * 0.8)],
        ).createShader(road),
    );
    final dash = Paint()
      ..color = _dim(const Color(0xFFE9E2C8), dark).withValues(alpha: 0.8)
      ..strokeWidth = 3;
    for (var x = 8.0; x < s.width; x += 46) {
      c.drawLine(Offset(x, g + 92), Offset(x + 22, g + 92), dash);
    }
    // The near verge: a grass strip and a ditch along the road's near side.
    final near = Rect.fromLTRB(0, g + 152, s.width, s.height);
    c.drawRect(
      near,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_dim(const Color(0xFF7A9A45), dark), _dim(const Color(0xFF4C6B2C), dark)],
        ).createShader(near),
    );
    c.drawRect(Rect.fromLTRB(0, g + 150, s.width, g + 156), Paint()..color = _dim(const Color(0xFF8E7A58), dark));
    final ditch = Path()
      ..moveTo(0, g + 178)
      ..quadraticBezierTo(s.width * 0.5, g + 172, s.width, g + 180)
      ..lineTo(s.width, g + 192)
      ..quadraticBezierTo(s.width * 0.5, g + 186, 0, g + 192)
      ..close();
    c.drawPath(ditch, Paint()..color = Color.lerp(_dim(const Color(0xFF5B6B4A), dark), const Color(0xFF7D8E9C), 0.3 * w.rain)!);
    // Puddles on the shoulder and the road (a sheen of the sky).
    if (w.rain > 0.2) {
      final sheen = Paint()..color = Color.lerp(const Color(0x66A7C2D6), const Color(0x885C6B7A), w.cloud)!.withValues(alpha: 0.5 * w.rain);
      c.drawOval(Rect.fromCenter(center: Offset(geo.ladderFoot.dx + 52, g + 26), width: 54, height: 7), sheen);
      c.drawOval(Rect.fromCenter(center: Offset(250, g + 62), width: 80, height: 10), sheen);
      c.drawOval(Rect.fromCenter(center: Offset(60, g + 120), width: 70, height: 9), sheen);
    }
    // Grass tufts along the verge (they lean with the wind).
    final tuft = Paint()
      ..color = _dim(const Color(0xFF4F7A2C), dark)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (var x = 6.0; x < s.width; x += 13) {
      final lean = w.wind * (5 + 2 * math.sin(t * 3 + x));
      c.drawLine(Offset(x, g + 12), Offset(x + 2 + lean, g + 2), tuft);
      c.drawLine(Offset(x + 4, g + 12), Offset(x + 3 + lean, g + 4), tuft);
    }

    // --- the lone tree -----------------------------------------------------
    _tree(c, t, dark);

    // --- the pole and the wires ---------------------------------------------
    _pole(c, s, t, dark);

    // --- the van -----------------------------------------------------------
    _van(c, dark);

    // A flash lights everything for an instant.
    if (flash > 0) c.drawRect(Offset.zero & s, Paint()..color = const Color(0xFFEFF4FF).withValues(alpha: 0.42 * flash));
  }

  void _clouds(Canvas c, Size s, double t, double dark) {
    final w = weather;
    final drift = t * (4 + 26 * w.wind);
    final base = geo.horizonY * (0.16 + 0.22 * w.cloud);
    final light = Color.lerp(const Color(0xF2FFFFFF), const Color(0xFF59626E), w.cloud)!;
    final under = Color.lerp(const Color(0xFFD9E2EA), const Color(0xFF2A313B), w.cloud)!;
    final n = 4 + (w.cloud * 7).round();
    for (var i = 0; i < n; i++) {
      final period = s.width + 160;
      final x = ((i * 97.0 + drift * (0.7 + 0.1 * (i % 3))) % period) - 80;
      final y = base + (i % 3) * 16.0 - 18 + 6 * math.sin(i * 1.7);
      final r = 18 + w.cloud * 16 + (i % 4) * 4;
      c.drawOval(Rect.fromCenter(center: Offset(x, y + r * 0.35), width: r * 4.4, height: r * 1.2), Paint()..color = under);
      final p = Paint()..color = light;
      c.drawCircle(Offset(x - r * 0.9, y), r * 0.75, p);
      c.drawCircle(Offset(x, y - r * 0.35), r, p);
      c.drawCircle(Offset(x + r * 0.95, y), r * 0.8, p);
    }
    // A low dark shelf as the storm nears.
    if (w.cloud > 0.55) {
      final k = ((w.cloud - 0.55) / 0.45).clamp(0.0, 1.0);
      final shelf = Rect.fromLTWH(0, 0, s.width, base + 40);
      c.drawRect(
        shelf,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFF0E131B).withValues(alpha: 0.8 * k), const Color(0x000E131B)],
          ).createShader(shelf),
      );
    }
    // Rain curtains hanging from the clouds.
    if (w.rain > 0.5) {
      final curtain = Paint()
        ..color = const Color(0xFF6A7682).withValues(alpha: 0.22 * w.rain)
        ..strokeWidth = 18;
      for (final x in const [30.0, 120.0, 260.0]) {
        final lean = 22 * w.wind;
        c.drawLine(Offset(x, base + 20), Offset(x + lean, geo.horizonY), curtain);
      }
    }
  }

  void _bolt(Canvas c, Offset from, Offset to, double a, int seed) {
    final rng = math.Random(seed);
    final p = Path()..moveTo(from.dx, from.dy);
    const n = 7;
    for (var i = 1; i <= n; i++) {
      final k = i / n;
      final x = from.dx + (to.dx - from.dx) * k + (i == n ? 0 : (rng.nextDouble() - 0.5) * 18);
      p.lineTo(x, from.dy + (to.dy - from.dy) * k);
    }
    c.drawPath(
      p,
      Paint()
        ..color = const Color(0xFFBFD8FF).withValues(alpha: 0.45 * a)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
    c.drawPath(
      p,
      Paint()
        ..color = const Color(0xFFFFFFFF).withValues(alpha: a)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
  }

  void _tree(Canvas c, double t, double dark) {
    final w = weather;
    final g = geo.groundY;
    const x = StormGeo.treeX;
    // The wind bends the crown downwind (to the right) and makes it rock.
    final bend = w.wind * (26 + 8 * math.sin(t * 2.7));
    final crown = geo.crown + Offset(bend, bend.abs() * 0.15);
    final trunk = Path()
      ..moveTo(x - 7, g + 6)
      ..quadraticBezierTo(x - 6 + bend * 0.2, g - 60, crown.dx - 4, crown.dy + 30)
      ..lineTo(crown.dx + 4, crown.dy + 30)
      ..quadraticBezierTo(x + 6 + bend * 0.2, g - 60, x + 7, g + 6)
      ..close();
    c.drawPath(trunk, Paint()..color = _dim(const Color(0xFF6A4A2C), dark));
    final leaf = _dim(const Color(0xFF3F6E33), dark);
    final leafHi = _dim(const Color(0xFF5B8E43), dark);
    for (final (dx, dy, r, hi) in const [
      (-30.0, 12.0, 30.0, false),
      (28.0, 10.0, 30.0, false),
      (0.0, -14.0, 38.0, false),
      (-14.0, -4.0, 26.0, true),
      (16.0, -20.0, 22.0, true),
    ]) {
      final sway = bend * (dy < 0 ? 0.5 : 0.25);
      c.drawCircle(crown + Offset(dx + sway, dy), r, Paint()..color = hi ? leafHi : leaf);
    }
    // Leaves torn off in a gale.
    if (w.wind > 0.6) {
      final p = Paint()..color = leafHi;
      for (var i = 0; i < 10; i++) {
        final k = ((t * 0.9 + i * 0.11) % 1.0);
        final at = crown + Offset(-260 + ((i * 53.0 + k * 300) % 320), -40 + i * 11 + 18 * math.sin(k * 6 + i));
        c.save();
        c.translate(at.dx, at.dy);
        c.rotate(k * 9 + i);
        c.drawOval(const Rect.fromLTWH(-4, -2, 8, 4), p);
        c.restore();
      }
    }
  }

  void _pole(Canvas c, Size s, double t, double dark) {
    final w = weather;
    final g = geo.groundY;
    final top = geo.topY;
    const x = StormGeo.poleX;
    // A PCC pole, tapering, with its shadow side.
    final body = Path()
      ..moveTo(x - 9, g + 8)
      ..lineTo(x - 5.5, top)
      ..lineTo(x + 5.5, top)
      ..lineTo(x + 9, g + 8)
      ..close();
    c.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          colors: [_dim(const Color(0xFFB8B4AA), dark), _dim(const Color(0xFF8F8B82), dark), _dim(const Color(0xFF6F6B63), dark)],
          stops: const [0, 0.55, 1],
        ).createShader(Rect.fromLTRB(x - 9, top, x + 9, g)),
    );
    // Wet streaks down the pole in the rain.
    if (w.rain > 0.2) {
      final wet = Paint()
        ..color = const Color(0xFF4B4E52).withValues(alpha: 0.35 * w.rain)
        ..strokeWidth = 1.4;
      for (final dx in const [-3.0, 1.0, 4.0]) {
        c.drawLine(Offset(x + dx, top + 30), Offset(x + dx * 1.3, g - 10), wet);
      }
    }
    // The cross-arm and three porcelain pin insulators.
    final arm = geo.armY;
    c.drawRect(Rect.fromLTRB(x - 46, arm - 3, x + 46, arm + 3), Paint()..color = _dim(const Color(0xFF4A4F55), dark));
    c.drawLine(Offset(x - 26, arm + 3), Offset(x - 4, arm + 26), Paint()..color = _dim(const Color(0xFF4A4F55), dark)..strokeWidth = 2.5);
    c.drawLine(Offset(x + 26, arm + 3), Offset(x + 4, arm + 26), Paint()..color = _dim(const Color(0xFF4A4F55), dark)..strokeWidth = 2.5);
    final pins = [Offset(x - 40, arm - 3), Offset(x, top), Offset(x + 40, arm - 3)];
    final porcelain = Paint()..color = _dim(const Color(0xFF8A4B26), dark * 0.8);
    for (final p in pins) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: p.translate(0, -6), width: 9, height: 12), const Radius.circular(3)), porcelain);
      c.drawOval(Rect.fromCenter(center: p.translate(0, -9), width: 13, height: 4), porcelain);
    }
    // The three wires span off both sides; in wind they gallop (each its own way).
    final wire = Paint()
      ..color = _dim(const Color(0xFF2A2E33), dark * 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (var i = 0; i < 3; i++) {
      final at = pins[i].translate(0, -12);
      final gallop = w.wind * (12 + 8 * i) * math.sin(t * 2.3 + i * 1.9 + 0.8);
      final sag = 20 + 4 * i.toDouble();
      final left = Path()
        ..moveTo(-10, at.dy - 22)
        ..quadraticBezierTo((at.dx - 10) / 2, at.dy + sag + gallop, at.dx, at.dy);
      final right = Path()
        ..moveTo(at.dx, at.dy)
        ..quadraticBezierTo((at.dx + s.width + 10) / 2, at.dy + sag - gallop, s.width + 10, at.dy - 26);
      c.drawPath(left, wire);
      c.drawPath(right, wire);
    }
  }

  void _van(Canvas c, double dark) {
    final r = geo.van;
    final body = RRect.fromRectAndCorners(
      Rect.fromLTRB(r.left, r.top + 8, r.right, r.bottom - 10),
      topLeft: const Radius.circular(10),
      topRight: const Radius.circular(4),
      bottomLeft: const Radius.circular(4),
      bottomRight: const Radius.circular(4),
    );
    c.drawRRect(body.shift(const Offset(2, 3)), Paint()..color = const Color(0x55000000));
    c.drawRRect(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_dim(const Color(0xFFF4F1EA), dark * 0.8), _dim(const Color(0xFFCFCAC0), dark * 0.8)],
        ).createShader(body.outerRect),
    );
    // The blue stripe and the cab with its window (rolled up).
    c.drawRect(Rect.fromLTRB(r.left, r.top + 30, r.right, r.top + 36), Paint()..color = _dim(const Color(0xFF1F5F8F), dark * 0.8));
    final glass = RRect.fromRectAndCorners(
      Rect.fromLTRB(r.left + 6, r.top + 13, r.left + 34, r.top + 28),
      topLeft: const Radius.circular(7),
      topRight: const Radius.circular(2),
    );
    c.drawRRect(
      glass,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_dim(const Color(0xFFB9D3E6), dark), _dim(const Color(0xFF4F6E86), dark)],
        ).createShader(glass.outerRect),
    );
    // The cargo door's seam and handle.
    final seam = Paint()
      ..color = _dim(const Color(0xFF8E897F), dark)
      ..strokeWidth = 1;
    c.drawLine(Offset(r.left + 40, r.top + 10), Offset(r.left + 40, r.bottom - 11), seam);
    c.drawLine(Offset(r.left + 40, r.top + 10), Offset(r.right - 3, r.top + 10), seam);
    c.drawRect(Rect.fromLTWH(r.left + 44, r.top + 38, 8, 2.5), Paint()..color = _dim(const Color(0xFF6A665E), dark));
    // A ladder rack on the roof.
    c.drawLine(Offset(r.left + 40, r.top + 5), Offset(r.right - 4, r.top + 5), Paint()..color = _dim(const Color(0xFF7C8186), dark)..strokeWidth = 2);
    for (final dx in const [46.0, 74.0, 102.0]) {
      c.drawLine(Offset(r.left + dx, r.top + 5), Offset(r.left + dx, r.top + 9), Paint()..color = _dim(const Color(0xFF7C8186), dark)..strokeWidth = 2);
    }
    // Headlight, the mirror arm, and a hook by the rear door (gloves hang there).
    c.drawRect(Rect.fromLTWH(r.left + 1, r.top + 33, 4, 6), Paint()..color = _dim(const Color(0xFFFFE9A6), dark * 0.5));
    c.drawLine(Offset(r.left + 8, r.top + 18), Offset(r.left - 0, r.top + 22), Paint()..color = _dim(const Color(0xFF3A3F45), dark)..strokeWidth = 2);
    c.drawCircle(Offset(r.right - 21, r.top + 10), 2, Paint()..color = _dim(const Color(0xFF3A3F45), dark));
    // Wheels.
    for (final cx in [r.left + 22, r.right - 22]) {
      final at = Offset(cx, r.bottom - 10);
      c.drawCircle(at, 10, Paint()..color = const Color(0xFF1E2125));
      c.drawCircle(at, 4.5, Paint()..color = _dim(const Color(0xFF9AA1A8), dark));
    }
  }

  @override
  bool shouldRepaint(StormWorldPainter old) => old.geo != geo || old.weather != weather || old.clock != clock || old.quiet != quiet;
}

/// Rain in front of everything: drizzle (thin, sparse, nearly straight) or
/// driving rain (dense, long, slanted by the wind), with splashes on the road.
class StormRainPainter extends CustomPainter {
  StormRainPainter({required this.geo, required this.weather, required this.clock}) : super(repaint: clock);

  final StormGeo geo;
  final StormWeather weather;
  final ValueListenable<double> clock;

  @override
  void paint(Canvas c, Size s) {
    final w = weather;
    if (w.rain < 0.03) return;
    final t = clock.value;
    final n = (30 + 170 * w.rain).round();
    final len = 6 + 16 * w.rain;
    final slant = 0.08 + 0.75 * w.wind;
    final speed = 260 + 420 * w.rain;
    final p = Paint()
      ..color = Color.lerp(const Color(0xFFDDE8F2), const Color(0xFFB8C6D4), w.cloud)!.withValues(alpha: 0.28 + 0.32 * w.rain)
      ..strokeWidth = 0.8 + 0.6 * w.rain
      ..strokeCap = StrokeCap.round;
    final rng = math.Random(7);
    final h = s.height + len;
    for (var i = 0; i < n; i++) {
      final x0 = rng.nextDouble() * (s.width + 80) - 40;
      final y0 = rng.nextDouble() * h;
      final k = 0.7 + rng.nextDouble() * 0.6;
      final y = (y0 + t * speed * k) % h - len;
      final x = x0 + y * slant;
      c.drawLine(Offset(x, y), Offset(x + len * slant, y + len * k), p);
    }
    // Splashes on the road.
    if (w.rain > 0.4) {
      final sp = Paint()
        ..color = const Color(0xFFE6EEF5).withValues(alpha: 0.35 * w.rain)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;
      for (var i = 0; i < 14; i++) {
        final x = rng.nextDouble() * s.width;
        final y = geo.groundY + 36 + rng.nextDouble() * (s.height - geo.groundY - 40);
        final k = ((t * 2.2 + i * 0.13) % 1.0);
        c.drawOval(Rect.fromCenter(center: Offset(x, y), width: 3 + 7 * k, height: 1 + 2 * k), sp);
      }
    }
  }

  @override
  bool shouldRepaint(StormRainPainter old) => old.geo != geo || old.weather != weather || old.clock != clock;
}

/// The aluminium ladder against the pole; [lay] 0 = leaning, 1 = laid down on
/// the verge (job stopped); [pull] −1..1: the hand on it (up lifts it a
/// touch, down starts to lower it).
class StormLadderPainter extends CustomPainter {
  const StormLadderPainter({required this.geo, required this.lay, required this.dark});
  final StormGeo geo;
  final double lay;
  final double dark;

  /// The ladder's top for [lay].
  static Offset topFor(StormGeo geo, double lay) {
    final foot = geo.ladderFoot;
    final up = geo.ladderTop - foot;
    final a0 = math.atan2(up.dy, up.dx);
    // Laid down to the right, foreshortened as it lies along the verge.
    final a = a0 * (1 - lay);
    final len = geo.ladderLength * (1 - 0.45 * lay);
    return foot + Offset(math.cos(a), math.sin(a)) * len;
  }

  @override
  void paint(Canvas c, Size s) {
    final foot = geo.ladderFoot;
    final top = topFor(geo, lay);
    final dir = top - foot;
    final len = dir.distance;
    if (len < 1) return;
    final u = dir / len;
    final n = Offset(-u.dy, u.dx);
    final half = 7.0 - 1.5 * lay;
    final rail = Paint()
      ..color = _dim(const Color(0xFFC9D0D6), dark)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    final shade = Paint()
      ..color = _dim(const Color(0xFF7F888F), dark)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    c.drawLine(foot + n * half + const Offset(1, 1), top + n * half + const Offset(1, 1), shade);
    c.drawLine(foot - n * half, top - n * half, rail);
    c.drawLine(foot + n * half, top + n * half, rail);
    final rung = Paint()
      ..color = _dim(const Color(0xFFAEB6BD), dark)
      ..strokeWidth = 1.8;
    for (var d = 12.0; d < len - 4; d += 14) {
      final p = foot + u * d;
      c.drawLine(p - n * half, p + n * half, rung);
    }
    // Rubber feet.
    c.drawCircle(foot - n * half, 2.4, Paint()..color = const Color(0xFF26292D));
    c.drawCircle(foot + n * half, 2.4, Paint()..color = const Color(0xFF26292D));
  }

  @override
  bool shouldRepaint(StormLadderPainter old) => old.geo != geo || old.lay != lay || old.dark != dark;
}

/// A pair of gloves: waterproof rubber gauntlets (dark blue, long cuffs).
class StormGlovesPainter extends CustomPainter {
  const StormGlovesPainter();

  @override
  void paint(Canvas c, Size s) {
    void glove(Offset at, double tilt) {
      c.save();
      c.translate(at.dx, at.dy);
      c.rotate(tilt);
      final k = s.height / 40;
      final palm = RRect.fromRectAndRadius(Rect.fromLTWH(-6 * k, 6 * k, 12 * k, 16 * k), Radius.circular(5 * k));
      final cuff = RRect.fromRectAndRadius(Rect.fromLTWH(-7 * k, -10 * k, 14 * k, 17 * k), Radius.circular(3 * k));
      final blue = Paint()..color = const Color(0xFF22406E);
      c.drawRRect(cuff, Paint()..color = const Color(0xFF1A3157));
      c.drawRRect(palm, blue);
      for (var i = 0; i < 4; i++) {
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-6 * k + i * 3.1 * k, 19 * k, 2.6 * k, 8 * k), Radius.circular(1.3 * k)), blue);
      }
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(5 * k, 10 * k, 3 * k, 7 * k), Radius.circular(1.5 * k)), blue);
      c.drawLine(Offset(-7 * k, 5 * k), Offset(7 * k, 5 * k), Paint()..color = const Color(0xFFE8B931)..strokeWidth = 1.4 * k);
      c.restore();
    }

    // Hung by a cord from the hook.
    c.drawLine(Offset(s.width * 0.5, 0), Offset(s.width * 0.32, s.height * 0.18), Paint()..color = const Color(0xFF2B2B2B)..strokeWidth = 1);
    c.drawLine(Offset(s.width * 0.5, 0), Offset(s.width * 0.68, s.height * 0.18), Paint()..color = const Color(0xFF2B2B2B)..strokeWidth = 1);
    glove(Offset(s.width * 0.32, s.height * 0.3), 0.12);
    glove(Offset(s.width * 0.68, s.height * 0.3), -0.12);
  }

  @override
  bool shouldRepaint(StormGlovesPainter old) => false;
}
