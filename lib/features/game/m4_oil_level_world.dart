import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The site of "তেলের মাপ" (lesson 4.5, কাজ 1): a drawn, layered place — the sky
// (a summer noon, a winter morning in fog, or a mild spring day), a far tree
// line and village roofs, the field and the lane, and the hero: a distribution
// transformer on a double-pole (DP) structure. Its parts, as the lesson names
// them: the conservator tank on top with its glass oil level gauge, the HT
// bushings (gaskets at their base), the tank's welded seams, the drain cock at
// the bottom, the cooling fins (radiators) at the sides; above, the three DO
// fuses on the cross-arm. A leak shows as a dark oil streak, drops and a stain
// below. In the top-up: the oil drums on the ground, the DO fuses hanging open
// after the shutdown, the earthing set on the HT side.
//
// Design: 360 wide × the scene's height; the ground row follows the bottom of
// the screen (a tall phone gets more sky). The only words in the art are the
// ones a worker reads (drum labels).

/// Where a transformer leaks (lesson point 3): the bushing's gasket, a welding
/// joint, the drain cock, a cooling fin.
enum M4OilLevelSpot { bushing, weld, drain, fin }

/// The drums for the top-up: new, filtered transformer oil of the same grade
/// (sealed), engine oil, old used oil, and transformer oil from a drum left
/// open in the rain (moist).
enum M4OilLevelDrum { fresh, engine, used, wet }

/// The weather at the inspection (pro tip 2: oil expands in heat, contracts
/// in cold).
enum M4OilLevelWeather { summer, winter, mild }

/// The gauge's marks (fraction of the glass, 0 = bottom, 1 = top).
const double kM4OilLevelMin = 0.2;
const double kM4OilLevelMark = 0.5;
const double kM4OilLevelMax = 0.8;

/// Where things stand (design px, 360 wide).
@immutable
class M4OilLevelGeo {
  const M4OilLevelGeo({required this.height, required this.groundY});

  factory M4OilLevelGeo.forScene(double h, double inset) => M4OilLevelGeo(height: h, groundY: (h - 300 - inset).clamp(380.0, 700.0));

  final double height;
  final double groundY;

  double get horizonY => groundY - 100;
  double get poleTop => groundY - 372;
  static const poleL = 196.0;
  static const poleR = 336.0;
  double get armY => groundY - 352;
  double doX(int i) => 238.0 + i * 36;
  double get doTopY => armY + 6;
  double get doLen => 36;
  double get platformY => groundY - 130;

  /// The main tank.
  Rect get tank => Rect.fromLTRB(214, platformY - 128, 318, platformY - 4);

  /// The conservator tank (a drum on brackets above the tank's left side).
  Rect get conservator => Rect.fromLTRB(204, tank.top - 38, 262, tank.top - 14);

  /// The glass gauge on the conservator's end cap.
  Rect get gauge => Rect.fromLTWH(conservator.left - 9, conservator.top + 2, 9, conservator.height - 4);
  Rect get gaugeHit => Rect.fromLTRB(conservator.left - 30, conservator.top - 16, conservator.right, conservator.bottom + 14);

  /// The filler cap on top of the conservator.
  Offset get filler => Offset(conservator.left + 16, conservator.top - 3);

  /// The HT bushings on the tank top.
  double bushX(int i) => 252.0 + i * 26;
  double get bushTop => tank.top - 26;

  /// Where each leak spot is.
  Offset spot(M4OilLevelSpot s) => switch (s) {
        M4OilLevelSpot.bushing => Offset(bushX(1), tank.top - 2),
        M4OilLevelSpot.weld => Offset(tank.right - 8, tank.bottom - 10),
        M4OilLevelSpot.drain => Offset(tank.left + 18, tank.bottom + 4),
        M4OilLevelSpot.fin => Offset(tank.right + 10, tank.center.dy + 2),
      };

  /// Where a tap reaches a spot (≥ 48 design px).
  Rect spotHit(M4OilLevelSpot s) => Rect.fromCenter(center: spot(s), width: 46, height: 46);

  /// The trainee on the ground (left of the structure).
  Rect get trainee => Rect.fromLTWH(10, groundY - 208, 104, 208);

  /// The trainee up on the platform (helmet and harness), beside the conservator.
  Rect get traineeUp => Rect.fromLTWH(132, platformY - 140, 70, 140);

  /// The drums on the ground.
  static const _drumX = [140.0, 196.0, 252.0, 308.0];
  Rect drum(int slot) => Rect.fromLTWH(_drumX[slot] - 25, groundY - 58, 50, 58);
  Rect drumHit(int slot) => drum(slot).inflate(4);

  /// The earth rod at the right pole's foot.
  Offset get earthRod => Offset(poleR + 14, groundY + 2);

  @override
  bool operator ==(Object other) => other is M4OilLevelGeo && other.height == height && other.groundY == groundY;

  @override
  int get hashCode => Object.hash(height, groundY);
}

/// The whole place. [leak]: the spot that leaks (null = none); [looked]: spots
/// the trainee has looked at (the same soft ring on every one, the leaking
/// part too — the oil streak is the evidence, the ring is not);
/// [gaugeLit]: the gauge is being read; [doOpen]: the DO fuses hang open
/// (shutdown); [earthed]: the earthing set is on; [climbed]: he is up (his
/// harness lanyard to the pole); [drums]: the drums in their slots (null = no
/// drums yet); [rejected]: drums set aside; [picked]: the drum in use.
class M4OilLevelWorldPainter extends CustomPainter {
  const M4OilLevelWorldPainter({
    required this.geo,
    required this.weather,
    this.leak,
    this.looked = const {},
    this.gaugeLit = false,
    this.doOpen = false,
    this.earthed = false,
    this.climbed = false,
    this.drums,
    this.rejected = const {},
    this.picked,
  });

  final M4OilLevelGeo geo;
  final M4OilLevelWeather weather;
  final M4OilLevelSpot? leak;
  final Set<M4OilLevelSpot> looked;
  final bool gaugeLit;
  final bool doOpen;
  final bool earthed;
  final bool climbed;
  final List<M4OilLevelDrum>? drums;
  final Set<M4OilLevelDrum> rejected;
  final M4OilLevelDrum? picked;

  @override
  void paint(Canvas c, Size size) {
    _sky(c, size);
    _land(c, size);
    _structure(c);
    _tank(c);
    if (leak != null) _leak(c, leak!);
    _rings(c);
    if (earthed) _earth(c);
    if (climbed) _lanyard(c);
    if (drums != null) _drums(c);
    if (weather == M4OilLevelWeather.winter) _fogFront(c, size);
  }

  void _sky(Canvas c, Size size) {
    final w = size.width;
    final hz = geo.horizonY;
    final colors = switch (weather) {
      M4OilLevelWeather.summer => const [Color(0xFF2F7FC9), Color(0xFF8CC3EA), Color(0xFFF6E7B0)],
      M4OilLevelWeather.winter => const [Color(0xFF8E9BA8), Color(0xFFB9C3CB), Color(0xFFDCE1E3)],
      M4OilLevelWeather.mild => const [Color(0xFF4F8CC4), Color(0xFF9CC6E4), Color(0xFFE3EFE6)],
    };
    final r = Rect.fromLTWH(0, 0, w, hz + 4);
    c.drawRect(r, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors).createShader(r));
    switch (weather) {
      case M4OilLevelWeather.summer:
        // The noon sun, high and fierce, with its glare.
        final sun = Offset(78, math.max(70.0, geo.poleTop - 10));
        c.drawCircle(sun, 70, Paint()..shader = const RadialGradient(colors: [Color(0x99FFF6C9), Color(0x00FFF6C9)]).createShader(Rect.fromCircle(center: sun, radius: 70)));
        final ray = Paint()
          ..color = const Color(0x88FFF3B0)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 12; i++) {
          final a = i / 12 * math.pi * 2;
          c.drawLine(sun + Offset(math.cos(a), math.sin(a)) * 30, sun + Offset(math.cos(a), math.sin(a)) * 44, ray);
        }
        c.drawCircle(sun, 24, Paint()..color = const Color(0xFFFFFBE6));
      case M4OilLevelWeather.winter:
        // A pale, low sun in the haze.
        c.drawCircle(Offset(300, hz - 40), 18, Paint()..color = const Color(0x88FFFFFF));
      case M4OilLevelWeather.mild:
        final cloud = Paint()..color = const Color(0x77FFFFFF);
        for (final (x, y, rr) in [(50.0, 120.0, 20.0), (78.0, 112.0, 26.0), (108.0, 122.0, 18.0), (110.0, 210.0, 14.0), (132.0, 204.0, 19.0)]) {
          c.drawCircle(Offset(x, y), rr, cloud);
        }
    }
  }

  void _land(Canvas c, Size size) {
    final w = size.width;
    final g = geo.groundY;
    final hz = geo.horizonY;
    final winter = weather == M4OilLevelWeather.winter;
    // Far tree line and village roofs.
    final far = Path()..moveTo(0, hz);
    for (var x = 0.0; x <= w; x += 18) {
      far.lineTo(x, hz - 20 - 10 * math.sin(x * 0.07) - 6 * math.cos(x * 0.19));
    }
    far
      ..lineTo(w, hz + 2)
      ..lineTo(0, hz + 2)
      ..close();
    c.drawPath(far, Paint()..color = winter ? const Color(0xFF7D8F82) : const Color(0xFF4F7A55));
    final roof = Paint()..color = winter ? const Color(0xFF8F7468) : const Color(0xFF8A4B36);
    final wall = Paint()..color = winter ? const Color(0xFFC9C3B6) : const Color(0xFFD9C7A3);
    for (final x in [18.0, 74.0, 140.0]) {
      c.drawRect(Rect.fromLTWH(x, hz - 16, 30, 16), wall);
      c.drawPath(
          Path()
            ..moveTo(x - 4, hz - 16)
            ..lineTo(x + 15, hz - 30)
            ..lineTo(x + 34, hz - 16)
            ..close(),
          roof);
    }
    if (winter) {
      // Fog over the far line.
      c.drawRect(Rect.fromLTWH(0, hz - 46, w, 52), Paint()..color = const Color(0x66E8ECEE));
    }
    // Field.
    final field = Rect.fromLTWH(0, hz, w, g - hz);
    c.drawRect(
        field,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: switch (weather) {
              M4OilLevelWeather.summer => const [Color(0xFFB7A35C), Color(0xFF8E8A45)],
              M4OilLevelWeather.winter => const [Color(0xFF8FA284), Color(0xFF6E8566)],
              M4OilLevelWeather.mild => const [Color(0xFF7FA05A), Color(0xFF5E7F43)],
            },
          ).createShader(field));
    // The lane to the bottom.
    final lane = Rect.fromLTWH(0, g, w, size.height - g);
    c.drawRect(lane, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFB59B74), Color(0xFF8C7556)]).createShader(lane));
    final pebble = Paint()..color = const Color(0x33000000);
    final rnd = math.Random(5);
    for (var i = 0; i < 24; i++) {
      c.drawCircle(Offset(rnd.nextDouble() * w, g + 6 + rnd.nextDouble() * (size.height - g - 10)), 1.2 + rnd.nextDouble() * 1.6, pebble);
    }
    if (weather == M4OilLevelWeather.summer) {
      // Heat shimmer over the lane.
      final sh = Paint()
        ..color = const Color(0x40FFFFFF)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke;
      for (var k = 0; k < 3; k++) {
        final y = g - 8 - k * 9.0;
        final p = Path()..moveTo(6, y);
        for (var x = 6.0; x < 120; x += 10) {
          p.quadraticBezierTo(x + 5, y - 3, x + 10, y);
        }
        c.drawPath(p, sh);
      }
    }
  }

  void _structure(Canvas c) {
    final g = geo.groundY;
    final wire = Paint()
      ..color = const Color(0xFF2F343A)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    // The 11 kV line coming in from the left at the top.
    for (var i = 0; i < 3; i++) {
      final y = geo.poleTop - 14 + i * 3.0;
      c.drawPath(
          Path()
            ..moveTo(0, y - 22)
            ..quadraticBezierTo(120, y + 12, geo.doX(i), geo.doTopY - 4),
          wire);
    }
    // The two PCC poles.
    for (final x in const [M4OilLevelGeo.poleL, M4OilLevelGeo.poleR]) {
      final r = Rect.fromLTRB(x - 7, geo.poleTop, x + 7, g + 4);
      c.drawPath(
          Path()
            ..moveTo(x - 6, geo.poleTop)
            ..lineTo(x + 6, geo.poleTop)
            ..lineTo(x + 9, g + 4)
            ..lineTo(x - 9, g + 4)
            ..close(),
          Paint()..shader = const LinearGradient(colors: [Color(0xFF8E9399), Color(0xFFC9CDD2), Color(0xFF8E9399)]).createShader(r));
      c.drawOval(Rect.fromCenter(center: Offset(x, g + 4), width: 36, height: 7), Paint()..color = const Color(0x33000000));
    }
    final steel = Paint()..color = const Color(0xFF4A5058);
    // Cross-arm and the DO fuses.
    c.drawRect(Rect.fromLTWH(M4OilLevelGeo.poleL - 10, geo.armY - 4, M4OilLevelGeo.poleR - M4OilLevelGeo.poleL + 20, 7), steel);
    for (var i = 0; i < 3; i++) {
      _doFuse(c, i);
    }
    // Leads from the DO fuses down to the HT bushings.
    for (var i = 0; i < 3; i++) {
      c.drawLine(Offset(geo.doX(i), geo.doTopY + geo.doLen + 8), Offset(geo.bushX(i), geo.bushTop), wire);
    }
    // The platform (channel) between the poles, with a side extension.
    final pf = geo.platformY;
    c.drawRect(Rect.fromLTRB(128, pf, 350, pf + 7), steel);
    c.drawRect(Rect.fromLTRB(128, pf + 7, 350, pf + 9), Paint()..color = const Color(0xFF2E3238));
    // The LT cable down the right pole.
    c.drawPath(
        Path()
          ..moveTo(geo.tank.right - 14, geo.tank.top + 22)
          ..quadraticBezierTo(M4OilLevelGeo.poleR + 4, geo.tank.top + 30, M4OilLevelGeo.poleR + 4, pf + 30)
          ..lineTo(M4OilLevelGeo.poleR + 4, g - 40),
        Paint()
          ..color = const Color(0xFF1B1E22)
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke);
    // The danger plate on the left pole.
    final plate = Rect.fromLTWH(M4OilLevelGeo.poleL - 11, g - 96, 22, 18);
    c.drawRRect(RRect.fromRectAndRadius(plate, const Radius.circular(2)), Paint()..color = const Color(0xFFF2F0E8));
    c.drawPath(
        Path()
          ..moveTo(plate.center.dx + 2, plate.top + 3)
          ..lineTo(plate.center.dx - 4, plate.center.dy + 1)
          ..lineTo(plate.center.dx + 1, plate.center.dy + 1)
          ..lineTo(plate.center.dx - 2, plate.bottom - 3)
          ..lineTo(plate.center.dx + 5, plate.center.dy - 2)
          ..lineTo(plate.center.dx, plate.center.dy - 2)
          ..close(),
        Paint()..color = const Color(0xFFD32F2F));
  }

  void _doFuse(Canvas c, int i) {
    final x = geo.doX(i);
    final por = Paint()..color = const Color(0xFF8C5A3C);
    c.drawRect(Rect.fromLTWH(x - 3.5, geo.doTopY - 8, 7, 10), por);
    c.drawRect(Rect.fromLTWH(x - 3.5, geo.doTopY + geo.doLen - 2, 7, 10), por);
    final tube = Paint()
      ..color = const Color(0xFF3B3F45)
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    final bottom = Offset(x, geo.doTopY + geo.doLen);
    if (doOpen) {
      // Dropped out: the tube hangs from its bottom hinge.
      c.drawLine(bottom, bottom + Offset(15, geo.doLen * 0.8), tube);
      c.drawCircle(bottom + Offset(17, geo.doLen * 0.84), 3.2, Paint()..color = const Color(0xFF9AA4AE));
    } else {
      c.drawLine(Offset(x, geo.doTopY + 2), bottom, tube);
      c.drawCircle(
          Offset(x + 4, geo.doTopY + 6),
          3.2,
          Paint()
            ..color = const Color(0xFF9AA4AE)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    }
  }

  void _tank(Canvas c) {
    final t = geo.tank;
    const body = [Color(0xFF6C7B66), Color(0xFF9AAB92), Color(0xFF6C7B66)];
    // Cooling fins (radiators) on both sides.
    final finPaint = Paint()..shader = const LinearGradient(colors: [Color(0xFF55634F), Color(0xFF8A9B82)]).createShader(Rect.fromLTRB(t.left - 18, t.top, t.right + 18, t.bottom));
    for (var k = 0; k < 4; k++) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(t.left - 17 + k * 4, t.top + 14, 3, t.height - 26), const Radius.circular(1.5)), finPaint);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(t.right + 2 + k * 4, t.top + 14, 3, t.height - 26), const Radius.circular(1.5)), finPaint);
    }
    for (final y in [t.top + 14, t.bottom - 12]) {
      c.drawRect(Rect.fromLTRB(t.left - 18, y - 2, t.left, y + 2), Paint()..color = const Color(0xFF4F5C4A));
      c.drawRect(Rect.fromLTRB(t.right, y - 2, t.right + 18, y + 2), Paint()..color = const Color(0xFF4F5C4A));
    }
    // The tank and its lid flange.
    c.drawRRect(RRect.fromRectAndRadius(t.shift(const Offset(3, 3)), const Radius.circular(4)), Paint()..color = const Color(0x44000000));
    c.drawRRect(RRect.fromRectAndRadius(t, const Radius.circular(4)), Paint()..shader = const LinearGradient(colors: body).createShader(t));
    c.drawRect(Rect.fromLTRB(t.left - 3, t.top - 2, t.right + 3, t.top + 5), Paint()..color = const Color(0xFF56634F));
    // Welded seams (a bead along the bottom and the right edge).
    final bead = Paint()
      ..color = const Color(0xFF4B5746)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    c.drawLine(Offset(t.left + 2, t.bottom - 10), Offset(t.right - 2, t.bottom - 10), bead);
    c.drawLine(Offset(t.right - 8, t.top + 6), Offset(t.right - 8, t.bottom - 2), bead);
    // The rating plate (blank metal) and the LT bushings on the front.
    c.drawRect(Rect.fromLTWH(t.center.dx - 18, t.top + 40, 36, 24), Paint()..color = const Color(0xFFC9CFC3));
    c.drawRect(Rect.fromLTWH(t.center.dx - 18, t.top + 40, 36, 24), Paint()
      ..color = const Color(0xFF56634F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2);
    for (var k = 0; k < 3; k++) {
      c.drawLine(Offset(t.center.dx - 12, t.top + 46 + k * 6.0), Offset(t.center.dx + 12, t.top + 46 + k * 6.0), Paint()
        ..color = const Color(0xFF8E968A)
        ..strokeWidth = 1.2);
    }
    // The drain cock (valve with a handle) at the bottom front.
    final dc = Offset(t.left + 18, t.bottom + 2);
    c.drawRect(Rect.fromCenter(center: dc, width: 12, height: 8), Paint()..color = const Color(0xFF3D4239));
    c.drawLine(dc + const Offset(-8, 5), dc + const Offset(8, 5), Paint()
      ..color = const Color(0xFFB23A2E)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round);
    // The HT bushings (brown porcelain sheds) with gaskets at their base.
    for (var i = 0; i < 3; i++) {
      final x = geo.bushX(i);
      c.drawRect(Rect.fromLTWH(x - 6, t.top - 4, 12, 4), Paint()..color = const Color(0xFF26292B));
      for (var k = 0; k < 4; k++) {
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, t.top - 7 - k * 5.5), width: 12 - k * 1.2, height: 4), const Radius.circular(2)), Paint()..color = const Color(0xFF8C5A3C));
      }
      c.drawRect(Rect.fromLTWH(x - 2.5, geo.bushTop - 2, 5, 6), Paint()..color = const Color(0xFF9AA4AE));
    }
    // The conservator on its brackets, the pipe down, the gauge glass, the filler cap.
    final cv = geo.conservator;
    for (final x in [cv.left + 10, cv.right - 10]) {
      c.drawRect(Rect.fromLTRB(x - 2, cv.bottom, x + 2, t.top - 1), Paint()..color = const Color(0xFF4F5C4A));
    }
    c.drawLine(Offset(cv.center.dx, cv.bottom), Offset(cv.center.dx + 6, t.top), Paint()
      ..color = const Color(0xFF3D4239)
      ..strokeWidth = 3);
    c.drawRRect(RRect.fromRectAndRadius(cv, Radius.circular(cv.height / 2)), Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: body).createShader(cv));
    c.drawCircle(geo.filler, 3.5, Paint()..color = const Color(0xFF3D4239));
    final gg = geo.gauge;
    c.drawRRect(RRect.fromRectAndRadius(gg.inflate(2), const Radius.circular(3)), Paint()..color = const Color(0xFF3D4239));
    c.drawRect(gg, Paint()..color = const Color(0xFFE8F1F2));
    if (gaugeLit) {
      c.drawRRect(RRect.fromRectAndRadius(gg.inflate(9), const Radius.circular(8)), Paint()
        ..color = const Color(0xCCFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2);
    }
  }

  void _leak(Canvas c, M4OilLevelSpot s) {
    final o = geo.spot(s);
    final oil = Paint()..color = const Color(0xF0301F08);
    final wet = Paint()..color = const Color(0xB0402A0C);
    final sheen = Paint()..color = const Color(0x99E0B04E);
    // A wet, dark patch on the metal round the spot, and the run down from it.
    final fall = switch (s) {
      M4OilLevelSpot.bushing => 40.0,
      M4OilLevelSpot.fin => 46.0,
      M4OilLevelSpot.weld => 14.0,
      M4OilLevelSpot.drain => 12.0,
    };
    c.drawOval(Rect.fromCenter(center: o + const Offset(0, 3), width: 20, height: 14), wet);
    c.drawPath(
        Path()
          ..moveTo(o.dx - 5, o.dy)
          ..quadraticBezierTo(o.dx - 7, o.dy + fall * 0.6, o.dx - 3, o.dy + fall)
          ..lineTo(o.dx + 3, o.dy + fall)
          ..quadraticBezierTo(o.dx + 6, o.dy + fall * 0.5, o.dx + 5, o.dy)
          ..close(),
        oil);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(o.dx - 1.5, o.dy + 2, 2.5, fall - 4), const Radius.circular(1)), sheen);
    c.drawCircle(o, 5.5, oil);
    c.drawCircle(o + const Offset(-1.5, -1.5), 1.6, sheen);
    // Drops falling, and the pool on the platform below.
    final pf = geo.platformY;
    for (final (dy, r) in [(fall + 9, 3.0), (fall + 22, 2.6), (fall + 36, 2.2)]) {
      if (o.dy + dy < pf - 3) c.drawOval(Rect.fromCenter(center: Offset(o.dx, o.dy + dy), width: r * 1.6, height: r * 2.3), oil);
    }
    c.drawOval(Rect.fromCenter(center: Offset(o.dx, pf + 1), width: 38, height: 7), Paint()..color = const Color(0xDD2A1A06));
    c.drawOval(Rect.fromCenter(center: Offset(o.dx - 4, pf), width: 12, height: 2.4), sheen);
    // Drips from the platform edge and old stains on the ground.
    c.drawOval(Rect.fromCenter(center: Offset(o.dx + 2, pf + 16), width: 4, height: 6), oil);
    c.drawOval(Rect.fromCenter(center: Offset(o.dx + 4, geo.groundY + 6), width: 54, height: 11), Paint()..color = const Color(0x99302210));
  }

  void _rings(Canvas c) {
    final ring = Paint()
      ..color = const Color(0x99FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (final s in looked) {
      c.drawCircle(geo.spot(s), 14, ring);
    }
  }

  void _earth(Canvas c) {
    // The earthing set: a clamp on each HT lead under the DO fuses, joined,
    // down the right pole to the earth rod.
    final lead = Paint()
      ..color = const Color(0xFF2E7D32)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    final y = geo.doTopY + geo.doLen + 22;
    final pts = [for (var i = 0; i < 3; i++) Offset(geo.doX(i) + (geo.bushX(i) - geo.doX(i)) * 0.3, y)];
    c.drawLine(pts.first, pts.last, lead);
    for (final p in pts) {
      c.drawRect(Rect.fromCenter(center: p, width: 7, height: 7), Paint()..color = const Color(0xFFF2C230));
    }
    c.drawPath(
        Path()
          ..moveTo(pts.last.dx, pts.last.dy)
          ..quadraticBezierTo(M4OilLevelGeo.poleR + 20, y + 40, M4OilLevelGeo.poleR + 14, geo.groundY - 4),
        lead);
    final rod = geo.earthRod;
    c.drawRect(Rect.fromLTWH(rod.dx - 2, rod.dy - 10, 4, 12), Paint()..color = const Color(0xFF9AA4AE));
  }

  void _lanyard(Canvas c) {
    final up = geo.traineeUp;
    final waist = Offset(up.center.dx + 6, up.top + up.height * 0.52);
    c.drawPath(
        Path()
          ..moveTo(waist.dx, waist.dy)
          ..quadraticBezierTo(M4OilLevelGeo.poleL - 10, waist.dy + 10, M4OilLevelGeo.poleL - 6, waist.dy - 6),
        Paint()
          ..color = const Color(0xFFFF851B)
          ..strokeWidth = 2.6
          ..style = PaintingStyle.stroke);
    c.drawCircle(Offset(M4OilLevelGeo.poleL - 6, waist.dy - 6), 3, Paint()..color = const Color(0xFF9AA4AE));
  }

  void _drums(Canvas c) {
    final list = drums!;
    for (var i = 0; i < list.length; i++) {
      final d = list[i];
      if (d == picked && climbed) continue;
      _drum(c, geo.drum(i), d, rejected.contains(d), d == picked);
    }
  }

  /// The label painted on a drum. Both transformer-oil drums carry the same
  /// label (the wet one is the same filtered oil, spoiled by rain), so only
  /// the sealed bung versus the open lid and rain water tell them apart.
  static (String, String) drumLabel(M4OilLevelDrum d) => switch (d) {
        M4OilLevelDrum.fresh || M4OilLevelDrum.wet => ('TRANSFORMER', 'OIL · FILTERED'),
        M4OilLevelDrum.engine => ('ENGINE', 'OIL'),
        M4OilLevelDrum.used => ('USED', 'OIL'),
      };

  void _drum(Canvas c, Rect r, M4OilLevelDrum d, bool out, bool inUse) {
    final (Color a, Color b) = switch (d) {
      M4OilLevelDrum.fresh => (const Color(0xFF1F5FA8), const Color(0xFF123E73)),
      M4OilLevelDrum.engine => (const Color(0xFFC62828), const Color(0xFF7F1D1D)),
      M4OilLevelDrum.used => (const Color(0xFF5B5148), const Color(0xFF3A332D)),
      M4OilLevelDrum.wet => (const Color(0xFF1F5FA8), const Color(0xFF123E73)),
    };
    c.drawOval(Rect.fromCenter(center: Offset(r.center.dx, r.bottom + 2), width: r.width + 8, height: 7), Paint()..color = const Color(0x44000000));
    final body = RRect.fromRectAndRadius(r, const Radius.circular(5));
    c.drawRRect(body, Paint()..shader = LinearGradient(colors: [b, a, b]).createShader(r));
    // Ribs.
    for (final y in [r.top + r.height * 0.33, r.top + r.height * 0.7]) {
      c.drawLine(Offset(r.left + 1, y), Offset(r.right - 1, y), Paint()
        ..color = const Color(0x55000000)
        ..strokeWidth = 1.6);
    }
    // The top: sealed bung, or an open lid.
    final top = Rect.fromLTWH(r.left + 2, r.top - 4, r.width - 4, 8);
    switch (d) {
      case M4OilLevelDrum.fresh:
        c.drawOval(top, Paint()..color = b);
        c.drawCircle(Offset(r.center.dx + 8, r.top), 2.6, Paint()..color = const Color(0xFFD7DCE0));
        // The seal (a band over the bung).
        c.drawLine(Offset(r.center.dx + 4, r.top - 1), Offset(r.center.dx + 12, r.top + 1), Paint()
          ..color = const Color(0xFFF2C230)
          ..strokeWidth = 2);
      case M4OilLevelDrum.engine:
        c.drawOval(top, Paint()..color = b);
        c.drawCircle(Offset(r.center.dx - 8, r.top), 3, Paint()..color = const Color(0xFFF2C230));
      case M4OilLevelDrum.used:
        // Open: black, old oil in it; drips down the side.
        c.drawOval(top, Paint()..color = const Color(0xFF15120E));
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.left + 6, r.top + 2, 4, 16), const Radius.circular(2)), Paint()..color = const Color(0xFF15120E));
      case M4OilLevelDrum.wet:
        // Open lid tipped back, rain water standing on the oil, drops around.
        c.drawOval(top, Paint()..color = const Color(0xFFB9852E));
        c.drawOval(Rect.fromCenter(center: top.center, width: top.width * 0.6, height: 4), Paint()..color = const Color(0xFFBFE3F2));
        c.drawOval(Rect.fromLTWH(r.right - 10, r.top - 16, 20, 7), Paint()..color = b);
        final drop = Paint()..color = const Color(0xCC9ED3EE);
        for (final o in [Offset(r.left + 6, r.top + 12), Offset(r.right - 8, r.top + 22), Offset(r.left + 12, r.top + 30)]) {
          c.drawOval(Rect.fromCenter(center: o, width: 3, height: 4.5), drop);
        }
        c.drawOval(Rect.fromCenter(center: Offset(r.center.dx, r.bottom + 3), width: r.width + 14, height: 6), Paint()..color = const Color(0x669ED3EE));
    }
    // The label a worker reads.
    final (String l1, String l2) = drumLabel(d);
    final lab = Rect.fromLTWH(r.left + 3, r.top + r.height * 0.38, r.width - 6, 16);
    c.drawRect(lab, Paint()..color = const Color(0xFFF2F0E8));
    _label(c, l1, Offset(lab.center.dx, lab.top + 4.5), 5.0, const Color(0xFF1B1E22));
    _label(c, l2, Offset(lab.center.dx, lab.top + 11.5), 4.8, const Color(0xFF1B1E22));
    if (inUse) {
      c.drawRRect(RRect.fromRectAndRadius(r.inflate(5), const Radius.circular(8)), Paint()
        ..color = const Color(0xFFFFD34E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6);
    }
    if (out) {
      // Set aside: a red cross over it.
      final x = Paint()
        ..color = const Color(0xFFE23B2E)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      c.drawLine(r.topLeft + const Offset(6, 8), r.bottomRight - const Offset(6, 8), x);
      c.drawLine(r.topRight + const Offset(-6, 8), r.bottomLeft + const Offset(6, -8), x);
    }
  }

  void _fogFront(Canvas c, Size size) {
    final band = Paint()..color = const Color(0x2EEFF2F3);
    c.drawRect(Rect.fromLTWH(0, geo.groundY - 70, size.width, 40), band);
  }

  static void _label(Canvas c, String t, Offset centre, double size, Color col) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: TextStyle(fontFamily: 'Roboto', fontSize: size, fontWeight: FontWeight.w900, color: col, letterSpacing: 0.2)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(M4OilLevelWorldPainter old) =>
      old.geo != geo ||
      old.weather != weather ||
      old.leak != leak ||
      !setEquals(old.looked, looked) ||
      old.gaugeLit != gaugeLit ||
      old.doOpen != doOpen ||
      old.earthed != earthed ||
      old.climbed != climbed ||
      !listEquals(old.drums, drums) ||
      !setEquals(old.rejected, rejected) ||
      old.picked != picked;
}

/// The oil level gauge, close up (what he sees from below): the glass with
/// the oil in it, the marks MAX · 30°C · MIN. [level]: 0 = bottom of the
/// glass, 1 = top.
class M4OilLevelGaugePainter extends CustomPainter {
  M4OilLevelGaugePainter({required this.from, required this.to, required this.pour}) : super(repaint: pour);

  /// The level before the pour, and where the pour takes it.
  final double from;
  final double to;

  /// The pour (0 = not yet, 1 = filled to [to]); only this repaints the gauge.
  final Animation<double> pour;

  double level() => from + (to - from) * pour.value;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    // The plate.
    final plate = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12));
    c.drawRRect(plate, Paint()..shader = const LinearGradient(colors: [Color(0xFF6C7B66), Color(0xFF9AAB92), Color(0xFF6C7B66)]).createShader(Offset.zero & size));
    c.drawRRect(plate.deflate(1), Paint()
      ..color = const Color(0xFF3D4239)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
    _text(c, 'OIL LEVEL', Offset(w / 2, 12), 10, const Color(0xFFF2F0E8));
    // The glass.
    final glass = Rect.fromLTWH(w * 0.56, 24, 22, h - 36);
    c.drawRRect(RRect.fromRectAndRadius(glass.inflate(4), const Radius.circular(8)), Paint()..color = const Color(0xFF2B2F2A));
    c.drawRRect(RRect.fromRectAndRadius(glass, const Radius.circular(6)), Paint()..color = const Color(0xFFE6EEF0));
    final f = level().clamp(0.0, 1.0);
    final top = glass.bottom - glass.height * f;
    final oil = Rect.fromLTRB(glass.left, top, glass.right, glass.bottom);
    c.save();
    c.clipRRect(RRect.fromRectAndRadius(glass, const Radius.circular(6)));
    c.drawRect(oil, Paint()..shader = const LinearGradient(colors: [Color(0xFFD9A632), Color(0xFFF2CB5C), Color(0xFFC08C22)]).createShader(oil));
    c.drawRect(Rect.fromLTWH(glass.left, top - 1, glass.width, 3), Paint()..color = const Color(0xFF8A5E10));
    c.restore();
    // The glint on the glass.
    c.drawRect(Rect.fromLTWH(glass.left + 4, glass.top + 4, 3, glass.height - 8), Paint()..color = const Color(0x66FFFFFF));
    // The marks.
    for (final (frac, label, col) in [
      (kM4OilLevelMax, 'MAX', const Color(0xFFFFFFFF)),
      (kM4OilLevelMark, '30°C', const Color(0xFFFFD34E)),
      (kM4OilLevelMin, 'MIN', const Color(0xFFFF8A80)),
    ]) {
      final y = glass.bottom - glass.height * frac;
      c.drawLine(Offset(glass.left - 14, y), Offset(glass.right + 6, y), Paint()
        ..color = col
        ..strokeWidth = 2.2);
      _text(c, label, Offset(glass.left - 34, y), 11, col);
    }
  }

  static void _text(Canvas c, String t, Offset centre, double size, Color col) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: TextStyle(fontFamily: 'Roboto', fontSize: size, fontWeight: FontWeight.w900, color: col)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(M4OilLevelGaugePainter old) => old.from != from || old.to != to || old.pour != pour;
}

/// The flash (the deadly consequence, in colour over the grey scene): a white
/// flash, a blue-white arc at [at], sparks. Non-graphic.
class M4OilLevelZapPainter extends CustomPainter {
  const M4OilLevelZapPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final flick = v < 0.5 ? (0.65 + 0.35 * math.sin(v * 60).abs()) : (1 - (v - 0.5) * 1.2).clamp(0.4, 1.0);
    final r = 26 + 46 * Curves.easeOut.transform(v.clamp(0.0, 1.0));
    c.drawCircle(at, r, Paint()..shader = RadialGradient(colors: [Color.fromRGBO(220, 235, 255, 0.95 * flick), const Color(0x002F6FD0)]).createShader(Rect.fromCircle(center: at, radius: r)));
    final rnd = math.Random(11);
    final arc = Path()..moveTo(at.dx - 30, at.dy);
    for (var i = 1; i <= 6; i++) {
      arc.lineTo(at.dx - 30 + i * 10, at.dy + (rnd.nextDouble() - 0.5) * 18);
    }
    c.drawPath(
        arc,
        Paint()
          ..color = Color.fromRGBO(255, 255, 255, flick)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke);
    final spark = Paint()
      ..color = Color.fromRGBO(255, 214, 90, (1 - v).clamp(0.0, 1.0))
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 14; i++) {
      final a = i / 14 * math.pi * 2 + 0.3;
      final d0 = 10 + 38 * v;
      c.drawLine(at + Offset(math.cos(a) * d0, math.sin(a) * d0), at + Offset(math.cos(a) * (d0 + 12), math.sin(a) * (d0 + 12)), spark);
    }
    final white = (1 - v * 4).clamp(0.0, 1.0);
    if (white > 0) c.drawRect(Offset.zero & size, Paint()..color = Color.fromRGBO(255, 255, 255, 0.8 * white));
  }

  @override
  bool shouldRepaint(M4OilLevelZapPainter old) => old.v != v || old.at != at;
}
