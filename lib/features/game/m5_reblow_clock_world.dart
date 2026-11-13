import 'dart:math' as math;

import 'package:flutter/material.dart';

// The drawn world of lesson 5.4 কাজ 2 "লাগাতেই, না পরে?" (m5_reblow_clock.dart):
// an 11 kV spur in open country. The spur comes in from the left over a
// middle pole and ends on the DTR pole on the right: a top cross-arm with
// three pin insulators, the DO-fuse cross-arm under it with three drop-out
// fuses (one barrel hangs dropped, hinged at its bottom contact), leads down
// to the pole-mounted transformer. A second DTR stands far away on the
// spur. The trainee stands to the side of the DO (never under the barrel),
// with gloves and the operating rod when he re-fits. In front: the van's
// bonnet with the logbook (a stopwatch dial in its corner), the ink pad with
// two identical stamps and the "look first" button.
//
// The sky is a time-lapse layer: holding the stopwatch runs it (the sun
// moves, the clouds stream); the weather sign comes in at the end (a wind
// gust, a lightning bolt, or a flock of birds on the line).
//
// Code-drawn, gradients, no bitmaps, no text in the art (labels a worker
// reads — the DTR plate, the logbook, the stamps — are widgets).
// Design: 360 wide × the scene's height; the bonnet follows the bottom of
// the screen, a tall phone gets a taller pole and more sky.

/// The spans the "কোথায় দেখবেন?" deck can show (the right ones first).
enum M5ReblowSpot { sagHeavy, branchClose, sagNormal, treeSafe, treeTrimmed, spanClear, roadHigh }

/// Lesson 5.4 point 2: where the wire sags too much or a branch is too close.
const m5ReblowSpotRight = {M5ReblowSpot.sagHeavy, M5ReblowSpot.branchClose};

/// What stands under a spot card's wires.
enum M5ReblowScenery { none, branchIn, treeSmall, treeTrimmed, cropField, road }

/// What a spot card draws: the wires' sag (× the card's height) and what
/// stands under them. Every spot looks different, so no deal shows two cards
/// alike.
(double, M5ReblowScenery) m5ReblowSpotLook(M5ReblowSpot s) => switch (s) {
      M5ReblowSpot.sagHeavy => (0.36, M5ReblowScenery.none),
      M5ReblowSpot.branchClose => (0.09, M5ReblowScenery.branchIn),
      M5ReblowSpot.sagNormal => (0.09, M5ReblowScenery.none),
      M5ReblowSpot.treeSafe => (0.09, M5ReblowScenery.treeSmall),
      M5ReblowSpot.treeTrimmed => (0.09, M5ReblowScenery.treeTrimmed),
      // Short tight span over an open crop field with a low bund.
      M5ReblowSpot.spanClear => (0.04, M5ReblowScenery.cropField),
      M5ReblowSpot.roadHigh => (0.05, M5ReblowScenery.road),
    };

/// The sign that comes as the barrel drops on a transient fault.
enum M5ReblowWeather { wind, lightning, bird }

/// Where things are (design px, 360 wide).
@immutable
class M5ReblowGeo {
  const M5ReblowGeo._(this.height, this.bonnetTop);

  factory M5ReblowGeo.forScene(double height, double inset) => M5ReblowGeo._(height, height - bonnetH - inset * 0.5);

  final double height;

  /// The top edge of the van's bonnet (the logbook and the stamps sit on it).
  final double bonnetTop;

  static const double bonnetH = 236;

  /// The pole's foot (just above the bonnet).
  double get groundY => bonnetTop - 10;

  /// The far fields' horizon.
  double get horizonY => bonnetTop - 96;

  static const double poleX = 252;
  double get poleTop => math.max(132.0, groundY - 380);
  double get h => groundY - poleTop;

  /// A height on the pole (0 = the top, 1 = the foot).
  double y(double f) => poleTop + f * h;

  double get topArmY => y(0.02);
  double get armY => y(0.15);
  static double doX(int i) => poleX - 38 + 38.0 * i;

  /// The DO's bottom contact (the barrel's hinge) and its top contact.
  Offset doHinge(int i) => Offset(doX(i), armY + 46);
  Offset doTopContact(int i) => Offset(doX(i), armY + 8);

  /// Hold here to re-fit the dropped barrel of phase [i].
  Rect doHit(int i) => Rect.fromCenter(center: Offset(doX(i), armY + 36), width: 58, height: 80);

  Rect get tank => Rect.fromLTRB(poleX - 36, y(0.38), poleX + 36, y(0.58));

  /// The DO arm's left end, where the fuse-rating tag hangs.
  Offset get armEnd => Offset(doX(0) - 18, armY);

  /// The fuse-rating tag (ruling M5-8: the re-fit shows the correct fuse
  /// rating), tied to the DO arm on a short string, level with the barrels.
  /// It stays clear of the DO's hold box.
  Rect get ratingTag => Rect.fromLTWH(doHit(0).left - 4 - 84, armY + 2, 84, 18);

  /// The trainee: to the side of the DO, never under the barrel.
  Rect get trainee => Rect.fromLTWH(112, groundY - 116, 58, 116);
  Offset get grip => Offset(trainee.right - 6, trainee.top + 50);

  /// The far DTR on the spur (its pole foot).
  Offset get farDtr => Offset(64, horizonY + 6);
  Offset get midPole => Offset(150, horizonY + 18);

  // --- the bonnet -------------------------------------------------------------
  Rect get log => Rect.fromLTWH(10, bonnetTop + 16, 216, 192);
  Rect get dial => Rect.fromLTWH(log.right - 50, log.top + 6, 44, 44);
  Rect get today => Rect.fromLTWH(log.left + 8, log.bottom - 70, log.width - 16, 62);
  Rect stamp(int slot) => Rect.fromLTWH(238 + slot * 58.0, bonnetTop + 22, 52, 78);
  Rect get pad => Rect.fromLTWH(232, bonnetTop + 86, 120, 20);
  Rect get check => Rect.fromLTWH(240, bonnetTop + 122, 108, 58);

  /// Where the arc flashes on a re-fit of phase [i].
  Offset blastAt(int i) => Offset(doX(i), armY + 20);

  @override
  bool operator ==(Object other) => other is M5ReblowGeo && other.height == height && other.bonnetTop == bonnetTop;

  @override
  int get hashCode => Object.hash(height, bonnetTop);
}

/// What the structure shows now.
@immutable
class M5ReblowRig {
  const M5ReblowRig({required this.phase, required this.barrelUp, required this.rod, required this.seed});

  /// The phase whose barrel dropped (0..2).
  final int phase;

  /// The dropped barrel is pushed back in (the line holds).
  final bool barrelUp;

  /// The operating rod is up at the DO (a re-fit in progress).
  final bool rod;

  /// Scenery variety (trees, clouds).
  final int seed;

  @override
  bool operator ==(Object other) => other is M5ReblowRig && other.phase == phase && other.barrelUp == barrelUp && other.rod == rod && other.seed == seed;

  @override
  int get hashCode => Object.hash(phase, barrelUp, rod, seed);
}

const _wire = Color(0xFF3C4248);
const _steel = Color(0xFF6F7880);
const _porcelain = Color(0xFFE6EAEE);

/// The time-lapse sky. [lapse] 0..1 runs while the clock is held; [hour]
/// 0..1 is the dealt time of day (morning → afternoon).
class M5ReblowSkyPainter extends CustomPainter {
  M5ReblowSkyPainter({required this.geo, required this.lapse, required this.hour, required this.seed}) : super(repaint: lapse);

  final M5ReblowGeo geo;
  final Animation<double> lapse;
  final double hour;
  final int seed;

  @override
  void paint(Canvas c, Size size) {
    final t = lapse.value.clamp(0.0, 1.0);
    final day = (hour + t * 0.55).clamp(0.0, 1.0);
    // Morning blue → noon pale → late amber.
    final top = Color.lerp(const Color(0xFF3E78C2), const Color(0xFF7C6AA8), math.max(0, day - 0.5) * 2)!;
    final low = Color.lerp(const Color(0xFFBFDDF2), const Color(0xFFF2C38E), math.max(0, day - 0.45) * 1.8)!;
    c.drawRect(
      Rect.fromLTWH(0, 0, size.width, geo.horizonY + 4),
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, low]).createShader(Rect.fromLTWH(0, 0, 1, geo.horizonY)),
    );
    // The sun on its arc.
    final sx = 20 + day * 320;
    final sy = geo.horizonY - 40 - math.sin(day * math.pi) * (geo.horizonY - 170).clamp(40.0, 400.0);
    c.drawCircle(Offset(sx, sy), 30, Paint()..color = const Color(0x33FFF2B0));
    c.drawCircle(Offset(sx, sy), 15, Paint()..color = const Color(0xFFFFF0B8));
    // Clouds stream past as time runs.
    final cloud = Paint()..color = const Color(0xD9FFFFFF);
    final rng = math.Random(seed);
    for (var i = 0; i < 4; i++) {
      final cy = 150.0 + rng.nextDouble() * math.max(40, geo.horizonY - 260);
      final cx = ((rng.nextDouble() * 420 + t * 260 * (0.6 + i * 0.25)) % 460) - 50;
      final w = 46.0 + rng.nextDouble() * 40;
      c.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: w, height: w * 0.36), cloud);
      c.drawOval(Rect.fromCenter(center: Offset(cx + w * 0.22, cy - w * 0.12), width: w * 0.56, height: w * 0.34), cloud);
    }
  }

  @override
  bool shouldRepaint(M5ReblowSkyPainter old) => old.geo != geo || old.hour != hour || old.seed != seed || old.lapse != lapse;
}

/// The fields, the spur, the DTR with its DOs, the far DTR.
class M5ReblowWorldPainter extends CustomPainter {
  const M5ReblowWorldPainter({required this.geo, required this.rig});

  final M5ReblowGeo geo;
  final M5ReblowRig rig;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    // Far fields and near grass.
    c.drawRect(
      Rect.fromLTRB(0, g.horizonY, w, g.bonnetTop + 4),
      Paint()
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8DB06A), Color(0xFF5E8A43)])
            .createShader(Rect.fromLTWH(0, g.horizonY, 1, g.bonnetTop - g.horizonY)),
    );
    final treeDark = Paint()..color = const Color(0xFF3F6A36);
    final rng = math.Random(rig.seed);
    for (var i = 0; i < 6; i++) {
      final x = 8.0 + i * 62 + rng.nextDouble() * 24;
      final s = 10.0 + rng.nextDouble() * 8;
      c.drawCircle(Offset(x, g.horizonY - s * 0.4), s, treeDark);
    }
    // A field bund.
    c.drawLine(Offset(0, g.horizonY + 34), Offset(w, g.horizonY + 26), Paint()
      ..color = const Color(0x553A5A2A)
      ..strokeWidth = 3);

    // The spur: far DTR pole → middle pole → this DTR's top arm.
    final far = g.farDtr;
    final mid = g.midPole;
    final farTop = far.translate(0, -66);
    final midTop = mid.translate(0, -104);
    _pole(c, far, farTop, 3);
    _pole(c, mid, midTop, 4);
    // The far DTR's tank.
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: far.translate(7, -36), width: 12, height: 14), const Radius.circular(2)), Paint()..color = const Color(0xFF7E8890));
    final wireP = Paint()
      ..color = _wire
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;
    for (var k = 0; k < 3; k++) {
      final a = farTop.translate(-6 + 6.0 * k, 2);
      final b = midTop.translate(-10 + 10.0 * k, 2);
      final e = Offset(M5ReblowGeo.doX(k) - 0, g.topArmY - 14);
      _span(c, a, b, 4, wireP);
      _span(c, b, e, 10, wireP..strokeWidth = 1.7);
    }

    // This DTR pole.
    final pole = Rect.fromLTRB(M5ReblowGeo.poleX - 6, g.poleTop - 8, M5ReblowGeo.poleX + 6, g.groundY);
    c.drawRect(
      pole,
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFF8E979E), Color(0xFFC3C9CE), Color(0xFF7D868D)]).createShader(pole),
    );
    // Top arm + pin insulators.
    final arm = Paint()..color = _steel;
    c.drawRect(Rect.fromLTRB(M5ReblowGeo.doX(0) - 14, g.topArmY - 3, M5ReblowGeo.doX(2) + 14, g.topArmY + 4), arm);
    for (var k = 0; k < 3; k++) {
      final x = M5ReblowGeo.doX(k);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(x - 4, g.topArmY - 16, x + 4, g.topArmY - 2), const Radius.circular(3)), Paint()..color = _porcelain);
    }
    // DO arm.
    c.drawRect(Rect.fromLTRB(M5ReblowGeo.doX(0) - 18, g.armY - 3, M5ReblowGeo.doX(2) + 18, g.armY + 4), arm);
    // Jumpers top arm → DO top contacts; leads DO hinge → HT bushings.
    final lead = Paint()
      ..color = _wire
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final tank = g.tank;
    for (var k = 0; k < 3; k++) {
      final x = M5ReblowGeo.doX(k);
      c.drawPath(Path()
        ..moveTo(x, g.topArmY - 14)
        ..quadraticBezierTo(x + 9, (g.topArmY + g.armY) / 2, x, g.doTopContact(k).dy), lead);
      final bush = Offset(tank.left + 12 + 24.0 * k, tank.top - 10);
      c.drawPath(Path()
        ..moveTo(x, g.doHinge(k).dy)
        ..quadraticBezierTo(x, (g.doHinge(k).dy + bush.dy) / 2 + 6, bush.dx, bush.dy), lead);
    }
    // The fuse-rating tag's string to the DO arm (the tag is a widget).
    final tag = g.ratingTag;
    c.drawLine(Offset(tag.right - 4, tag.top + 3), g.armEnd.translate(2, 2), Paint()
      ..color = const Color(0xFF3A3020)
      ..strokeWidth = 1.1);
    // The DOs.
    for (var k = 0; k < 3; k++) {
      _do(c, k, dropped: k == rig.phase && !rig.barrelUp);
    }
    // The transformer, hung on the pole.
    c.drawRect(Rect.fromLTRB(tank.left + 6, tank.top + 10, tank.right - 6, tank.top + 16), arm);
    final tankR = RRect.fromRectAndRadius(tank, const Radius.circular(5));
    c.drawRRect(
      tankR,
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFF6D7880), Color(0xFFA3AEB6), Color(0xFF66717A)]).createShader(tank),
    );
    final fin = Paint()
      ..color = const Color(0x55212A31)
      ..strokeWidth = 1.2;
    for (var i = 1; i < 8; i++) {
      final x = tank.left + i * tank.width / 8;
      c.drawLine(Offset(x, tank.top + 22), Offset(x, tank.bottom - 6), fin);
    }
    for (var k = 0; k < 3; k++) {
      final b = Offset(tank.left + 12 + 24.0 * k, tank.top);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(b.dx - 3, b.dy - 11, b.dx + 3, b.dy), const Radius.circular(2)), Paint()..color = const Color(0xFF9B5E3A));
    }
    // LT cable down the pole.
    c.drawLine(Offset(tank.right - 8, tank.bottom), Offset(M5ReblowGeo.poleX + 9, g.groundY - 30), Paint()
      ..color = const Color(0xFF1E1E1E)
      ..strokeWidth = 3);
    c.drawRect(Rect.fromLTWH(M5ReblowGeo.poleX + 2, g.groundY - 46, 22, 20), Paint()..color = const Color(0xFF8C969E));

    // The operating rod from the trainee's gloved hands up to the barrel.
    if (rig.rod) {
      final tip = g.doTopContact(rig.phase).translate(-2, 6);
      final grip = g.grip;
      c.drawLine(grip.translate(4, 16), tip, Paint()
        ..color = const Color(0xFFE2A21C)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round);
      c.drawLine(grip.translate(4, 16), tip, Paint()
        ..color = const Color(0x55FFFFFF)
        ..strokeWidth = 1.2);
      final glove = Paint()..color = const Color(0xFF2F5BD0);
      c.drawCircle(grip.translate(1, 10), 4.6, glove);
      c.drawCircle(grip.translate(7, 24), 4.6, glove);
    }
  }

  void _pole(Canvas c, Offset foot, Offset top, double half) {
    c.drawRect(Rect.fromLTRB(foot.dx - half, top.dy, foot.dx + half, foot.dy), Paint()..color = const Color(0xFF9AA2A8));
    c.drawRect(Rect.fromLTRB(foot.dx - half * 4, top.dy + 2, foot.dx + half * 4, top.dy + 4 + half * 0.4), Paint()..color = _steel);
  }

  void _span(Canvas c, Offset a, Offset b, double sag, Paint p) {
    c.drawPath(Path()
      ..moveTo(a.dx, a.dy)
      ..quadraticBezierTo((a.dx + b.dx) / 2, (a.dy + b.dy) / 2 + sag * 2, b.dx, b.dy), p);
  }

  /// One drop-out fuse: the porcelain body and the barrel (closed upright
  /// between the contacts, or dropped: hanging from the bottom hinge).
  void _do(Canvas c, int k, {required bool dropped}) {
    final g = geo;
    final x = M5ReblowGeo.doX(k);
    final top = g.doTopContact(k);
    final hinge = g.doHinge(k);
    // Bracket + porcelain body behind.
    c.drawRect(Rect.fromLTRB(x + 4, g.armY - 2, x + 8, hinge.dy + 2), Paint()..color = _steel);
    final body = Rect.fromLTRB(x + 6, top.dy - 2, x + 13, hinge.dy);
    c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(3)), Paint()..color = _porcelain);
    for (var i = 1; i < 5; i++) {
      final yy = body.top + i * body.height / 5;
      c.drawLine(Offset(body.left - 1, yy), Offset(body.right + 1, yy), Paint()
        ..color = const Color(0xFFC8CED4)
        ..strokeWidth = 1.4);
    }
    // Contacts.
    final contact = Paint()..color = const Color(0xFFB9C1C7);
    c.drawRect(Rect.fromCenter(center: top, width: 12, height: 5), contact);
    c.drawRect(Rect.fromCenter(center: hinge, width: 12, height: 5), contact);
    // The barrel.
    final angle = dropped ? 2.55 : 0.0;
    c.save();
    c.translate(hinge.dx, hinge.dy);
    c.rotate(angle);
    final len = hinge.dy - top.dy - 4;
    final barrel = Rect.fromLTRB(-3.6, -len, 3.6, 0);
    c.drawRRect(
      RRect.fromRectAndRadius(barrel, const Radius.circular(3)),
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFF6B3E22), Color(0xFF9C6236), Color(0xFF5E361E)]).createShader(barrel),
    );
    c.drawCircle(Offset(0, -len - 2), 3.2, Paint()
      ..color = const Color(0xFFB9C1C7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6);
    if (dropped) {
      // The fuse-link tail, burnt.
      c.drawLine(const Offset(0, 0), const Offset(2, 9), Paint()
        ..color = const Color(0xFF2A2A2A)
        ..strokeWidth = 1.2);
    }
    c.restore();
  }

  @override
  bool shouldRepaint(M5ReblowWorldPainter old) => old.geo != geo || old.rig != rig;
}

/// The van's bonnet under the logbook and the stamps.
class M5ReblowBonnetPainter extends CustomPainter {
  const M5ReblowBonnetPainter({required this.geo});
  final M5ReblowGeo geo;

  @override
  void paint(Canvas c, Size size) {
    final top = geo.bonnetTop;
    final r = Rect.fromLTRB(-10, top, size.width + 10, size.height + 10);
    final path = Path()
      ..moveTo(r.left, top + 18)
      ..quadraticBezierTo(size.width / 2, top - 10, r.right, top + 18)
      ..lineTo(r.right, r.bottom)
      ..lineTo(r.left, r.bottom)
      ..close();
    c.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF2F4F2), Color(0xFFC9D0CB), Color(0xFF9EA8A2)])
            .createShader(r),
    );
    c.drawPath(path, Paint()
      ..color = const Color(0x66000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);
    // The company stripe and the ink pad.
    c.drawRect(Rect.fromLTWH(0, size.height - 18, size.width, 6), Paint()..color = const Color(0xFF1F6FB5));
    final pad = geo.pad;
    c.drawRRect(RRect.fromRectAndRadius(pad, const Radius.circular(5)), Paint()..color = const Color(0xFF39404A));
    c.drawRRect(RRect.fromRectAndRadius(pad.deflate(3), const Radius.circular(3)), Paint()..color = const Color(0xFF5A3C8C));
  }

  @override
  bool shouldRepaint(M5ReblowBonnetPainter old) => old.geo != geo;
}

/// The sign as the barrel drops: [v] 0..1 one-shot, held still at 1.
class M5ReblowWeatherPainter extends CustomPainter {
  const M5ReblowWeatherPainter({required this.geo, required this.weather, required this.v});
  final M5ReblowGeo geo;
  final M5ReblowWeather weather;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final dark = Paint()..color = Color.fromRGBO(70, 78, 92, 0.55 * v.clamp(0.0, 1.0));
    switch (weather) {
      case M5ReblowWeather.wind:
        c.drawRect(Rect.fromLTWH(0, 0, size.width, geo.horizonY), dark);
        final streak = Paint()
          ..color = Color.fromRGBO(255, 255, 255, 0.55 * (1 - (v - 0.7).clamp(0.0, 0.3)))
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 9; i++) {
          final yy = 170.0 + i * (geo.horizonY - 180) / 9;
          final x0 = -60 + ((i * 47 + v * 300) % 420);
          c.drawLine(Offset(x0, yy), Offset(x0 + 36, yy - 3), streak);
        }
        // The far tree bends.
        final base = Offset(30, geo.horizonY + 4);
        c.drawLine(base, base.translate(10 + 8 * v, -30), Paint()
          ..color = const Color(0xFF4A3A2A)
          ..strokeWidth = 3);
        c.drawCircle(base.translate(16 + 10 * v, -36), 14, Paint()..color = const Color(0xFF3F6A36));
      case M5ReblowWeather.lightning:
        c.drawRect(Rect.fromLTWH(0, 0, size.width, geo.horizonY), dark..color = dark.color.withValues(alpha: 0.7 * v.clamp(0.0, 1.0)));
        final a = (v < 0.35 ? 1.0 : (1 - (v - 0.35) * 2.5)).clamp(0.0, 1.0);
        if (a > 0) {
          final bolt = Path()
            ..moveTo(110, 140)
            ..lineTo(96, geo.horizonY * 0.45)
            ..lineTo(112, geo.horizonY * 0.5)
            ..lineTo(92, geo.horizonY - 10);
          c.drawPath(bolt, Paint()
            ..color = Color.fromRGBO(255, 248, 200, a)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3);
          c.drawRect(Offset.zero & size, Paint()..color = Color.fromRGBO(255, 255, 255, 0.35 * a * (v < 0.15 ? 1 : 0)));
        }
      case M5ReblowWeather.bird:
        final bird = Paint()
          ..color = const Color(0xFF22262B)
          ..strokeWidth = 1.8
          ..style = PaintingStyle.stroke;
        for (var i = 0; i < 7; i++) {
          final p = Offset(200 + i * 12 - (1 - v) * 120, geo.topArmY - 26 - (i % 3) * 6 - (1 - v) * 40);
          c.drawPath(Path()
            ..moveTo(p.dx - 5, p.dy)
            ..quadraticBezierTo(p.dx - 2, p.dy - 4, p.dx, p.dy)
            ..quadraticBezierTo(p.dx + 2, p.dy - 4, p.dx + 5, p.dy), bird);
        }
    }
  }

  @override
  bool shouldRepaint(M5ReblowWeatherPainter old) => old.v != v || old.weather != weather || old.geo != geo;
}

/// The instant blast with arc at the DO ([v] 0..1).
class M5ReblowBlastPainter extends CustomPainter {
  const M5ReblowBlastPainter({required this.geo, required this.phase, required this.v});
  final M5ReblowGeo geo;
  final int phase;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final at = geo.blastAt(phase);
    final flick = v < 0.5 ? (0.65 + 0.35 * math.sin(v * 60).abs()) : (1 - (v - 0.5) * 1.6).clamp(0.0, 1.0);
    final r = 22 + 64 * Curves.easeOut.transform(v.clamp(0.0, 1.0));
    c.drawCircle(
      at,
      r,
      Paint()
        ..shader = RadialGradient(colors: [Color.fromRGBO(255, 250, 220, 0.95 * flick), Color.fromRGBO(255, 150, 60, 0.6 * flick), const Color(0x00FF7A1A)])
            .createShader(Rect.fromCircle(center: at, radius: r)),
    );
    final spark = Paint()
      ..color = Color.fromRGBO(255, 214, 90, (1 - v).clamp(0.0, 1.0))
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 14; i++) {
      final a = i / 14 * math.pi * 2 + 0.3;
      final d0 = 8 + 46 * v;
      c.drawLine(at + Offset(math.cos(a), math.sin(a)) * d0, at + Offset(math.cos(a), math.sin(a)) * (d0 + 12), spark);
    }
    // The arc: a jagged bolt between the contacts.
    if (v < 0.6) {
      final top = geo.doTopContact(phase);
      final hinge = geo.doHinge(phase);
      final arc = Path()..moveTo(top.dx, top.dy);
      for (var i = 1; i <= 5; i++) {
        arc.lineTo(top.dx + (i.isOdd ? 7 : -7), top.dy + (hinge.dy - top.dy) * i / 5);
      }
      c.drawPath(arc, Paint()
        ..color = Color.fromRGBO(200, 220, 255, 1 - v / 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4);
    }
    final white = (1 - v * 5).clamp(0.0, 1.0);
    if (white > 0) c.drawRect(Offset.zero & size, Paint()..color = Color.fromRGBO(255, 255, 255, 0.7 * white));
  }

  @override
  bool shouldRepaint(M5ReblowBlastPainter old) => old.v != v || old.phase != phase || old.geo != geo;
}

/// A hold ring that fills with [fill] (0..1) round [box].
class M5ReblowHoldRingPainter extends CustomPainter {
  M5ReblowHoldRingPainter({required this.fill, required this.armed}) : super(repaint: fill);
  final Animation<double> fill;

  /// Draw the faint idle ring (the control is live).
  final bool armed;

  @override
  void paint(Canvas c, Size size) {
    final centre = size.center(Offset.zero);
    final r = math.min(size.width, size.height) / 2 - 3;
    if (armed) {
      c.drawCircle(centre, r, Paint()
        ..color = const Color(0x88FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
    }
    final v = fill.value;
    if (v <= 0) return;
    c.drawArc(Rect.fromCircle(center: centre, radius: r), -math.pi / 2, math.pi * 2 * v, false, Paint()
      ..color = const Color(0xFFFFD25A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(M5ReblowHoldRingPainter old) => old.fill != fill || old.armed != armed;
}

/// The stopwatch dial in the logbook's corner; its hand turns with [run].
class M5ReblowDialPainter extends CustomPainter {
  M5ReblowDialPainter({required this.run, required this.live}) : super(repaint: run);
  final Animation<double> run;
  final bool live;

  @override
  void paint(Canvas c, Size size) {
    final o = size.center(Offset.zero);
    final r = math.min(size.width, size.height) / 2 - 5;
    c.drawCircle(o, r + 2, Paint()..color = const Color(0xFF2B3138));
    c.drawCircle(o, r, Paint()..color = live ? const Color(0xFFFFFBEA) : const Color(0xFFE9E6DA));
    c.drawRect(Rect.fromCenter(center: o.translate(0, -r - 4), width: 8, height: 5), Paint()..color = const Color(0xFF2B3138));
    final tick = Paint()
      ..color = const Color(0xFF59606A)
      ..strokeWidth = 1.2;
    for (var i = 0; i < 12; i++) {
      final a = i / 12 * math.pi * 2;
      c.drawLine(o + Offset(math.sin(a), -math.cos(a)) * (r - 4), o + Offset(math.sin(a), -math.cos(a)) * r, tick);
    }
    final a = run.value * math.pi * 2 * 6;
    c.drawLine(o, o + Offset(math.sin(a), -math.cos(a)) * (r - 5), Paint()
      ..color = const Color(0xFFC0392B)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round);
    c.drawCircle(o, 2.4, Paint()..color = const Color(0xFF2B3138));
  }

  @override
  bool shouldRepaint(M5ReblowDialPainter old) => old.run != run || old.live != live;
}

/// One span on a "কোথায় দেখবেন?" card (local box, no text).
class M5ReblowSpotPainter extends CustomPainter {
  const M5ReblowSpotPainter(this.spot);
  final M5ReblowSpot spot;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final h = s.height;
    c.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF9FCBEA), Color(0xFFDDEFF8)])
            .createShader(Offset.zero & s),
    );
    final ground = h * 0.80;
    c.drawRect(Rect.fromLTRB(0, ground, w, h), Paint()..color = const Color(0xFF6E9A4E));
    final pole = Paint()..color = const Color(0xFF8E979E);
    final l = Offset(w * 0.12, h * 0.24);
    final r = Offset(w * 0.88, h * 0.24);
    c.drawRect(Rect.fromLTRB(l.dx - 3, l.dy, l.dx + 3, ground), pole);
    c.drawRect(Rect.fromLTRB(r.dx - 3, r.dy, r.dx + 3, ground), pole);
    c.drawRect(Rect.fromLTRB(l.dx - 10, l.dy, l.dx + 10, l.dy + 3), pole);
    c.drawRect(Rect.fromLTRB(r.dx - 10, r.dy, r.dx + 10, r.dy + 3), pole);
    final (sagF, scenery) = m5ReblowSpotLook(spot);
    final sag = h * sagF;
    // Trees first (behind the wires).
    void tree(Offset base, double size, {bool trimmed = false}) {
      c.drawRect(Rect.fromLTRB(base.dx - 3, base.dy - size * 1.1, base.dx + 3, base.dy), Paint()..color = const Color(0xFF5A4330));
      final crown = Paint()..color = const Color(0xFF3F7A3A);
      if (trimmed) {
        c.drawOval(Rect.fromCenter(center: base.translate(0, -size * 1.2), width: size * 1.3, height: size * 0.7), crown);
      } else {
        c.drawCircle(base.translate(0, -size * 1.35), size * 0.62, crown);
        c.drawCircle(base.translate(-size * 0.4, -size * 1.05), size * 0.45, crown);
        c.drawCircle(base.translate(size * 0.4, -size * 1.05), size * 0.45, crown);
      }
    }

    switch (scenery) {
      case M5ReblowScenery.branchIn:
        tree(Offset(w * 0.52, ground), h * 0.30);
        // A branch reaching into the wires.
        c.drawLine(Offset(w * 0.52, ground - h * 0.38), Offset(w * 0.40, l.dy + h * 0.06), Paint()
          ..color = const Color(0xFF5A4330)
          ..strokeWidth = 3);
        c.drawCircle(Offset(w * 0.40, l.dy + h * 0.06), h * 0.08, Paint()..color = const Color(0xFF3F7A3A));
      case M5ReblowScenery.treeSmall:
        tree(Offset(w * 0.50, ground), h * 0.14);
      case M5ReblowScenery.treeTrimmed:
        tree(Offset(w * 0.46, ground), h * 0.20, trimmed: true);
      case M5ReblowScenery.road:
        c.drawRect(Rect.fromLTRB(0, ground + 2, w, ground + h * 0.12), Paint()..color = const Color(0xFF55595E));
        c.drawLine(Offset(w * 0.1, ground + h * 0.06), Offset(w * 0.9, ground + h * 0.06), Paint()
          ..color = const Color(0xFFF2F2F2)
          ..strokeWidth = 1.5);
      case M5ReblowScenery.cropField:
        // A paddy field in rows up to a low bund; nothing tall under the span.
        c.drawRect(Rect.fromLTRB(0, ground - h * 0.06, w, h), Paint()..color = const Color(0xFF9CC25A));
        final row = Paint()
          ..color = const Color(0xFF5F8E34)
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round;
        for (var y = ground - h * 0.01; y < h; y += h * 0.07) {
          for (var x = w * 0.05; x < w; x += w * 0.1) {
            c.drawLine(Offset(x, y), Offset(x - 1.5, y - h * 0.035), row);
            c.drawLine(Offset(x, y), Offset(x + 1.5, y - h * 0.035), row);
          }
        }
        c.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTRB(0, ground - h * 0.085, w, ground - h * 0.055), const Radius.circular(3)),
          Paint()..color = const Color(0xFF8A6E4B),
        );
      case M5ReblowScenery.none:
        break;
    }
    final wire = Paint()
      ..color = _wire
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    for (var k = 0; k < 2; k++) {
      final a = l.translate(k == 0 ? -8 : 8, 0);
      final b = r.translate(k == 0 ? -8 : 8, 0);
      final extra = spot == M5ReblowSpot.sagHeavy && k == 1 ? h * 0.06 : 0.0;
      c.drawPath(Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(w / 2, a.dy + (sag + extra) * 2, b.dx, b.dy), wire);
    }
  }

  @override
  bool shouldRepaint(M5ReblowSpotPainter old) => old.spot != spot;
}

/// The three spots the "look first" check runs over: the DTR, the DO and the
/// span (design px).
List<Rect> m5ReblowCheckSpots(M5ReblowGeo g, int phase) => [
      g.tank.inflate(6),
      g.doHit(phase).deflate(6),
      Rect.fromCenter(center: Offset((g.midPole.dx + M5ReblowGeo.poleX) / 2, g.topArmY + 10), width: 90, height: 40),
    ];
