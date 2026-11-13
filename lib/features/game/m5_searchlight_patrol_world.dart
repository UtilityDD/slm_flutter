import 'dart:math' as math;

import 'package:flutter/material.dart';

// The drawn world of lesson 5.7 কাজ 1 "সার্চলাইটের টহল"
// (m5_searchlight_patrol.dart), at night:
//
//  * the depot: a lamp-lit wall with a shelf (torch, headlamp, phone), a
//    charging dock, the docket board, two jacket pegs, the floor, and the
//    patrol van by the open shutter (a roof searchlight hatch and the cab);
//  * the fork: the road out of the depot splits — a paved road under street
//    lamps and a dirt field track (which side is dealt);
//  * the patrol: a side-scrolling road beside an 11 kV line, poles on both
//    sides (far and near); the van holds the left third of the screen and its
//    roof searchlight throws a cone wherever the player aims it. Pole tops
//    are black silhouettes — all alike — until the searchlight rests on one
//    at a slow speed: then its cross-arm, insulators and any damage show.
//
// Code-drawn, gradients, no bitmaps, no text in the art except a pole's
// plate (read through the binoculars). Design: 360 wide × the scene's height;
// the road follows the bottom of the screen (a tall phone gets more sky).

/// The three devices on the depot shelf.
enum M5SlDevice { torch, headlamp, phone }

/// The two jackets on the depot pegs.
enum M5SlJacket { dark, reflective }

/// The two seats in the van.
enum M5SlSeat { driver, light }

/// The two people going out.
enum M5SlWho { trainee, partner }

/// Which side of the road a pole stands on.
enum M5SlSide { far, near }

/// What the searchlight shows at a pole top once it rests there.
enum M5SlFault { none, insulator, branch }

/// One pole of the patrolled stretch.
@immutable
class M5SlPole {
  const M5SlPole({required this.side, required this.fault, required this.porcelain, required this.plate});
  final M5SlSide side;
  final M5SlFault fault;

  /// Brown porcelain (true) or grey polymer insulators — both sound looks.
  final bool porcelain;

  /// The number on its plate (P-xx).
  final int plate;
}

/// Where things are (design px, 360 wide).
@immutable
class M5SlGeo {
  const M5SlGeo._(this.height, this.floorY);

  factory M5SlGeo.forScene(double height, double inset) => M5SlGeo._(height, height - floorUp - inset * 0.5);

  final double height;

  /// The depot floor / the line the HUD row stands on.
  final double floorY;

  /// The floor sits this far above the bottom (the HUD row is under it).
  static const double floorUp = 116;

  // ---- depot -----------------------------------------------------------------
  // Laid out up from the floor so nothing to touch sits in the guide's corner
  // ([guideZone], bottom left of centre) on any phone height.

  /// Taller phones lift the wall items clear of the guide's speech bubble.
  double get lift => ((height - 600) * 0.5).clamp(0.0, 60.0);

  /// The shelf board's top edge.
  double get shelfY => floorY - 262 - lift;
  Rect get shelf => Rect.fromLTWH(10, shelfY, 196, 10);

  /// A device's place on the shelf.
  Rect deviceHome(M5SlDevice d) => Rect.fromLTWH(16 + d.index * 62.0, shelfY - 52, 52, 52);

  /// The docket on the notice board.
  Rect get docket => Rect.fromLTWH(222, floorY - 318 - lift, 128, 48);

  /// The charging dock on the wall (drop a device here).
  Rect get dock => Rect.fromLTWH(230, floorY - 258 - lift, 116, 56);

  /// The jacket pegs (left wall).
  Rect peg(int i) => Rect.fromLTWH(16 + i * 68.0, floorY - 226 - lift, 56, 76);

  /// Where the two people stand before they get in (left, clear of the guide).
  Rect figureHome(M5SlWho w) => Rect.fromLTWH(w == M5SlWho.trainee ? 12 : 58, floorY - 86, 40, 86);

  /// The van in the depot (faces right; the cab at the front).
  Rect get depotVan => Rect.fromLTWH(206, floorY - 150, 150, 132);

  /// The seats (drop a person here): the roof searchlight hatch and the cab.
  Rect seat(M5SlSeat s) => s == M5SlSeat.light ? Rect.fromLTWH(224, floorY - 202, 50, 58) : Rect.fromLTWH(292, floorY - 140, 50, 56);

  /// The corner the guide stands in (design px, generous): keep touch
  /// targets out of it.
  Rect get guideZone => Rect.fromLTRB(102, floorY - 72, 230, floorY + 60);

  // ---- fork ------------------------------------------------------------------
  double get forkY => floorY - 170;
  double get forkHorizon => math.max(200.0, forkY - 200);
  Rect sign(bool left) => Rect.fromLTWH(left ? 22 : 190, math.max(130.0, forkHorizon - 82), 148, 66);

  /// The van at the foot of the trunk road (right of the guide's corner).
  Offset get forkVan => Offset(276, floorY - 34);

  // ---- patrol ----------------------------------------------------------------
  double get roadBottom => floorY - 70;
  double get roadTop => roadBottom - 82;
  double get farBase => roadTop + 2;
  double get farTopY => roadTop - (0.55 * (roadTop - 150)).clamp(120.0, 260.0);
  double get nearBase => roadBottom + 46;

  /// Near poles stand closer, so their tops rise higher on screen.
  double get nearTopY => math.max(150.0, farTopY - 36);
  double topY(M5SlSide s) => s == M5SlSide.far ? farTopY : nearTopY;
  double baseY(M5SlSide s) => s == M5SlSide.far ? farBase : nearBase;

  /// The van on the road (fixed on screen) and its roof searchlight.
  Rect get van => Rect.fromLTWH(112, roadTop - 8, 140, 70);
  Offset get lamp => Offset(van.left + 92, van.top - 14);

  /// Where a pole "comes level" with the van.
  double get levelX => lamp.dx;

  /// A pole's world x; on screen it is `worldX − x`.
  static const double firstPole = 430;
  static const double spacing = 176;
  static double poleWorldX(int i) => firstPole + i * spacing;
  double poleScreenX(int i, double x) => poleWorldX(i) - x;
  Offset poleTop(M5SlPole p, int i, double x) => Offset(poleScreenX(i, x), topY(p.side));

  /// A pole has left the screen (on the left).
  static const double goneX = -18;

  /// The cone's spot, and how near a pole top must be to it to be lit.
  static const double spot = 34;
  static const double litRadius = 42;

  /// The camera position that puts pole [i] where the trainee steps out.
  static double stepX(int i) => poleWorldX(i) - 304;

  /// The trainee by the road at the step-out (ahead of the van, by the pole).
  Rect get stepFigure => Rect.fromLTWH(254, roadBottom - 90, 42, 92);

  /// The sky band the cone sweeps (for the hint), both sides.
  List<Rect> get skyBand => [
        for (final (i, x) in [70.0, 160.0, 250.0, 330.0].indexed)
          Rect.fromCenter(center: Offset(x, i.isEven ? farTopY + 6 : nearTopY + 6), width: 40, height: 40),
      ];

  /// [skyBand] with each stop nudged sideways off any of the pole [tops]
  /// (a stop that cannot clear them all is left out).
  List<Rect> skyBandClear(List<Offset> tops) {
    bool clear(Offset c) => tops.every((t) => (t - c).distance > litRadius + 6);
    final out = <Rect>[];
    for (final r in skyBand) {
      Offset? at;
      for (final dx in const [0.0, 16.0, -16.0, 32.0, -32.0, 48.0, -48.0, 64.0, -64.0]) {
        final c = r.center.translate(dx, 0);
        if (c.dx >= 24 && c.dx <= 336 && clear(c)) {
          at = c;
          break;
        }
      }
      if (at != null) out.add(Rect.fromCenter(center: at, width: r.width, height: r.height));
    }
    return out;
  }

  @override
  bool operator ==(Object other) => other is M5SlGeo && other.height == height && other.floorY == floorY;

  @override
  int get hashCode => Object.hash(height, floorY);
}

// ============================================================================
// Shared bits
// ============================================================================

const _night = [Color(0xFF040812), Color(0xFF0B1730), Color(0xFF16284A)];

void _stars(Canvas c, Size s, double maxY, int seed, {double drift = 0}) {
  final r = math.Random(seed);
  final p = Paint();
  for (var i = 0; i < 46; i++) {
    final x = (r.nextDouble() * 400 - drift) % 400 - 20;
    final y = 70 + r.nextDouble() * (maxY - 70);
    final a = 0.25 + r.nextDouble() * 0.55;
    p.color = Color.fromRGBO(220, 230, 255, a);
    c.drawCircle(Offset(x, y), 0.6 + r.nextDouble() * 0.9, p);
  }
}

void _sky(Canvas c, Size s, double horizon) {
  c.drawRect(
    Offset.zero & s,
    Paint()
      ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: _night, stops: const [0, 0.55, 1])
          .createShader(Rect.fromLTWH(0, 0, s.width, horizon)),
  );
}

/// The patrol van, side view facing right; [roofLamp] at the hatch.
void paintVan(Canvas c, Rect b, {bool lampOn = true, bool headlights = true}) {
  final body = RRect.fromRectAndCorners(
    Rect.fromLTRB(b.left, b.top + b.height * 0.12, b.right, b.bottom - b.height * 0.18),
    topLeft: const Radius.circular(6),
    topRight: Radius.circular(b.width * 0.16),
    bottomLeft: const Radius.circular(4),
    bottomRight: const Radius.circular(6),
  );
  c.drawRRect(
    body,
    Paint()
      ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE9EEF5), Color(0xFF9AA6B8)])
          .createShader(body.outerRect),
  );
  // The utility stripe.
  c.drawRect(Rect.fromLTWH(b.left, body.outerRect.top + body.outerRect.height * 0.52, b.width, 6), Paint()..color = const Color(0xFFE0A21B));
  // Cab window and side windows.
  final glass = Paint()
    ..shader = const LinearGradient(colors: [Color(0xFF1B2D4A), Color(0xFF34507A)]).createShader(b);
  final cab = Path()
    ..moveTo(b.right - b.width * 0.30, body.outerRect.top + 6)
    ..lineTo(b.right - b.width * 0.08, body.outerRect.top + 6)
    ..lineTo(b.right - 4, body.outerRect.top + body.outerRect.height * 0.42)
    ..lineTo(b.right - b.width * 0.30, body.outerRect.top + body.outerRect.height * 0.42)
    ..close();
  c.drawPath(cab, glass);
  c.drawRRect(
    RRect.fromRectAndRadius(Rect.fromLTWH(b.left + 10, body.outerRect.top + 6, b.width * 0.46, body.outerRect.height * 0.36), const Radius.circular(3)),
    glass,
  );
  // Wheels.
  for (final fx in [0.2, 0.8]) {
    final w = Offset(b.left + b.width * fx, b.bottom - b.height * 0.16);
    c.drawCircle(w, b.height * 0.15, Paint()..color = const Color(0xFF14171D));
    c.drawCircle(w, b.height * 0.07, Paint()..color = const Color(0xFF7D8696));
  }
  // The roof searchlight on its stand.
  final lamp = Offset(b.left + b.width * 0.66, b.top + 2);
  c.drawRect(Rect.fromCenter(center: lamp.translate(0, 6), width: 6, height: 10), Paint()..color = const Color(0xFF3B4352));
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: lamp, width: 20, height: 12), const Radius.circular(4)), Paint()..color = const Color(0xFF2A303B));
  c.drawCircle(lamp.translate(6, 0), 4.4, Paint()..color = lampOn ? const Color(0xFFFFF4C8) : const Color(0xFF59606C));
  // Headlamp at the front.
  c.drawCircle(Offset(b.right - 3, body.outerRect.top + body.outerRect.height * 0.62), 3.4,
      Paint()..color = headlights ? const Color(0xFFFFF0B0) : const Color(0xFF59606C));
}

// ============================================================================
// Depot
// ============================================================================

/// The depot's static picture (devices, jackets, docket and people are
/// widgets over it).
class M5SlDepotPainter extends CustomPainter {
  const M5SlDepotPainter({required this.geo, required this.seed});
  final M5SlGeo geo;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final s = Size(360, geo.height);
    // The wall, lit by one lamp.
    canvas.drawRect(
      Offset.zero & s,
      Paint()
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1B2533), Color(0xFF2B3646), Color(0xFF222B38)])
            .createShader(Offset.zero & s),
    );
    canvas.drawCircle(
      Offset(120, geo.shelfY - 120),
      220,
      Paint()
        ..shader = const RadialGradient(colors: [Color(0x40FFE3A0), Color(0x00FFE3A0)]).createShader(Rect.fromCircle(center: Offset(120, geo.shelfY - 120), radius: 220)),
    );
    // The open shutter at the right: the night outside.
    final door = Rect.fromLTRB(196, geo.floorY - 196, 360, geo.floorY);
    canvas.drawRect(
      door,
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: _night).createShader(door),
    );
    canvas.save();
    canvas.clipRect(door);
    _stars(canvas, s, door.top + door.height * 0.5, seed);
    canvas.restore();
    final rail = Paint()..color = const Color(0xFF475263);
    canvas.drawRect(Rect.fromLTWH(door.left - 6, door.top - 10, door.width + 6, 12), rail);
    canvas.drawRect(Rect.fromLTWH(door.left - 6, door.top, 6, door.height), rail);
    // Lamp.
    canvas.drawRect(Rect.fromLTWH(112, math.max(100.0, geo.shelfY - 210), 16, 6), Paint()..color = const Color(0xFF59606C));
    // The notice board.
    final board = geo.docket.inflate(10);
    canvas.drawRRect(RRect.fromRectAndRadius(board, const Radius.circular(4)), Paint()..color = const Color(0xFF6B4A2B));
    canvas.drawRRect(RRect.fromRectAndRadius(board.deflate(4), const Radius.circular(3)), Paint()..color = const Color(0xFF9C7A4E));
    // The shelf and its brackets.
    final wood = Paint()..color = const Color(0xFF8A5F36);
    canvas.drawRect(geo.shelf, wood);
    for (final x in [26.0, 186.0]) {
      canvas.drawRect(Rect.fromLTWH(x, geo.shelfY + 10, 5, 18), Paint()..color = const Color(0xFF5C3F24));
    }
    // The charging dock: a board with three charging cradles.
    final dock = RRect.fromRectAndRadius(geo.dock, const Radius.circular(8));
    canvas.drawRRect(
      dock,
      Paint()
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF39445A), Color(0xFF232B3A)])
            .createShader(geo.dock),
    );
    for (var i = 0; i < 3; i++) {
      final cr = Rect.fromLTWH(geo.dock.left + 10 + i * 36.0, geo.dock.bottom - 26, 28, 16);
      canvas.drawRRect(RRect.fromRectAndRadius(cr, const Radius.circular(3)), Paint()..color = const Color(0xFF151A23));
      canvas.drawCircle(Offset(cr.center.dx, geo.dock.top + 14), 3, Paint()..color = const Color(0xFF52D27A));
    }
    // Jacket pegs.
    for (var i = 0; i < 2; i++) {
      final p = geo.peg(i);
      canvas.drawCircle(Offset(p.center.dx, p.top + 4), 4, Paint()..color = const Color(0xFFB7BEC9));
    }
    // The floor.
    final floor = Rect.fromLTRB(0, geo.floorY, 360, geo.height);
    canvas.drawRect(
      floor,
      Paint()
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3A3F47), Color(0xFF1E2228)])
            .createShader(floor),
    );
    canvas.drawLine(Offset(0, geo.floorY), Offset(360, geo.floorY), Paint()
      ..color = const Color(0xFF59606C)
      ..strokeWidth = 1.4);
    // The van; the two seats show as open places.
    paintVan(canvas, geo.depotVan, lampOn: false, headlights: false);
    final seatPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = const Color(0x99FFE7A8);
    for (final st in M5SlSeat.values) {
      canvas.drawRRect(RRect.fromRectAndRadius(geo.seat(st), const Radius.circular(8)), seatPaint);
    }
  }

  @override
  bool shouldRepaint(M5SlDepotPainter old) => old.geo != geo || old.seed != seed;
}

/// One device on the shelf (all three are always drawn; their charge shows
/// only when held).
class M5SlDevicePainter extends CustomPainter {
  const M5SlDevicePainter(this.device);
  final M5SlDevice device;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final dark = Paint()..color = const Color(0xFF20252E);
    final rim = Paint()..color = const Color(0xFF8C96A6);
    switch (device) {
      case M5SlDevice.torch:
        final body = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.12, h * 0.42, w * 0.56, h * 0.26), const Radius.circular(4));
        canvas.drawRRect(body, Paint()..color = const Color(0xFFCB3B2E));
        final head = Path()
          ..moveTo(w * 0.66, h * 0.40)
          ..lineTo(w * 0.90, h * 0.28)
          ..lineTo(w * 0.90, h * 0.82)
          ..lineTo(w * 0.66, h * 0.70)
          ..close();
        canvas.drawPath(head, rim);
        canvas.drawRect(Rect.fromLTWH(w * 0.86, h * 0.32, w * 0.05, h * 0.46), Paint()..color = const Color(0xFFFFF5D0));
        canvas.drawRect(Rect.fromLTWH(w * 0.32, h * 0.46, w * 0.1, h * 0.06), dark);
      case M5SlDevice.headlamp:
        final band = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = h * 0.08
          ..color = const Color(0xFF3B4A63);
        canvas.drawOval(Rect.fromLTWH(w * 0.1, h * 0.3, w * 0.8, h * 0.5), band);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.34, h * 0.22, w * 0.32, h * 0.26), const Radius.circular(5)), Paint()..color = const Color(0xFFE3B21B));
        canvas.drawCircle(Offset(w * 0.5, h * 0.35), w * 0.08, Paint()..color = const Color(0xFFFFF5D0));
      case M5SlDevice.phone:
        final body = RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.28, h * 0.12, w * 0.44, h * 0.78), const Radius.circular(6));
        canvas.drawRRect(body, dark);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.32, h * 0.2, w * 0.36, h * 0.6), const Radius.circular(3)), Paint()..color = const Color(0xFF2E4466));
        canvas.drawCircle(Offset(w * 0.5, h * 0.85), w * 0.03, rim);
    }
  }

  @override
  bool shouldRepaint(M5SlDevicePainter old) => old.device != device;
}

/// A jacket on its hanger.
class M5SlJacketPainter extends CustomPainter {
  const M5SlJacketPainter(this.jacket);
  final M5SlJacket jacket;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final cloth = jacket == M5SlJacket.reflective ? const [Color(0xFFD7F55A), Color(0xFFA9CC2C)] : const [Color(0xFF2A3140), Color(0xFF161B25)];
    final hanger = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFFB7BEC9);
    canvas.drawLine(Offset(w * 0.5, 2), Offset(w * 0.5, h * 0.1), hanger);
    canvas.drawLine(Offset(w * 0.2, h * 0.16), Offset(w * 0.5, h * 0.08), hanger);
    canvas.drawLine(Offset(w * 0.8, h * 0.16), Offset(w * 0.5, h * 0.08), hanger);
    final body = Path()
      ..moveTo(w * 0.32, h * 0.14)
      ..lineTo(w * 0.1, h * 0.24)
      ..lineTo(w * 0.04, h * 0.6)
      ..lineTo(w * 0.18, h * 0.62)
      ..lineTo(w * 0.2, h * 0.96)
      ..lineTo(w * 0.8, h * 0.96)
      ..lineTo(w * 0.82, h * 0.62)
      ..lineTo(w * 0.96, h * 0.6)
      ..lineTo(w * 0.9, h * 0.24)
      ..lineTo(w * 0.68, h * 0.14)
      ..lineTo(w * 0.5, h * 0.3)
      ..close();
    canvas.drawPath(body, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: cloth).createShader(Offset.zero & size));
    canvas.drawPath(body, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x66000000));
    // Two bands across (silver on the reflective one, a seam on the dark one).
    final band = Paint()..color = jacket == M5SlJacket.reflective ? const Color(0xFFE9EEF2) : const Color(0xFF232A36);
    for (final y in [0.58, 0.76]) {
      canvas.drawRect(Rect.fromLTWH(w * 0.2, h * y, w * 0.6, h * 0.06), band);
    }
    canvas.drawLine(Offset(w * 0.5, h * 0.3), Offset(w * 0.5, h * 0.96), Paint()
      ..color = const Color(0x55000000)
      ..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(M5SlJacketPainter old) => old.jacket != jacket;
}

// ============================================================================
// Fork
// ============================================================================

/// The road out of the depot splits: a paved road (street lamps, a centre
/// line) and a dirt field track; [fieldLeft] puts the track on the left.
class M5SlForkPainter extends CustomPainter {
  const M5SlForkPainter({required this.geo, required this.fieldLeft, required this.seed});
  final M5SlGeo geo;
  final bool fieldLeft;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final s = Size(360, geo.height);
    final horizon = geo.forkHorizon;
    _sky(canvas, s, horizon + 40);
    _stars(canvas, s, horizon - 10, seed);
    // Fields.
    final ground = Rect.fromLTRB(0, horizon, 360, geo.height);
    canvas.drawRect(
      ground,
      Paint()
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0E1A12), Color(0xFF1C2B1A)])
            .createShader(ground),
    );
    // The trunk road from the bottom to the fork.
    final fy = geo.forkY;
    final trunk = Path()
      ..moveTo(232, geo.height)
      ..quadraticBezierTo(206, (fy + geo.height) / 2, 160, fy)
      ..lineTo(200, fy)
      ..quadraticBezierTo(250, (fy + geo.height) / 2, 322, geo.height)
      ..close();
    final asphalt = Paint()..color = const Color(0xFF2A2E35);
    canvas.drawPath(trunk, asphalt);
    // The two branches.
    for (final left in [true, false]) {
      final field = left == fieldLeft;
      final dir = left ? -1.0 : 1.0;
      final p = Path()
        ..moveTo(180 + dir * 2, fy)
        ..lineTo(180 + dir * 40, fy)
        ..lineTo(180 + dir * 150, horizon + 6)
        ..lineTo(180 + dir * 128, horizon + 6)
        ..close();
      canvas.drawPath(p, field ? (Paint()..color = const Color(0xFF4A3A26)) : asphalt);
      if (field) {
        // Ruts and grass tufts.
        final rut = Paint()
          ..color = const Color(0xFF2E2416)
          ..strokeWidth = 2;
        canvas.drawLine(Offset(180 + dir * 14, fy - 2), Offset(180 + dir * 134, horizon + 8), rut);
        canvas.drawLine(Offset(180 + dir * 30, fy - 2), Offset(180 + dir * 142, horizon + 8), rut);
        final r = math.Random(seed + 3);
        final tuft = Paint()..color = const Color(0xFF3F5A2A);
        for (var i = 0; i < 9; i++) {
          final t = r.nextDouble();
          final x = 180 + dir * (20 + t * 120) + (r.nextDouble() - 0.5) * 14;
          final y = fy - t * (fy - horizon - 8);
          canvas.drawCircle(Offset(x, y), 2 + r.nextDouble() * 2, tuft);
        }
      } else {
        // Centre dashes and two street lamps.
        final dash = Paint()
          ..color = const Color(0xFFE6D27A)
          ..strokeWidth = 1.6;
        for (var t = 0.08; t < 0.9; t += 0.18) {
          final a = Offset(180 + dir * (22 + t * 116), fy - t * (fy - horizon - 6));
          final b = Offset(180 + dir * (22 + (t + 0.08) * 116), fy - (t + 0.08) * (fy - horizon - 6));
          canvas.drawLine(a, b, dash);
        }
        for (final t in [0.25, 0.65]) {
          final base = Offset(180 + dir * (52 + t * 122), fy - t * (fy - horizon - 6));
          final hgt = 46 * (1 - t * 0.6);
          canvas.drawLine(base, base.translate(0, -hgt), Paint()
            ..color = const Color(0xFF6E7684)
            ..strokeWidth = 2);
          final lamp = base.translate(0, -hgt);
          canvas.drawCircle(
            lamp,
            18 * (1 - t * 0.5),
            Paint()..shader = RadialGradient(colors: const [Color(0x66FFE3A0), Color(0x00FFE3A0)]).createShader(Rect.fromCircle(center: lamp, radius: 18)),
          );
          canvas.drawCircle(lamp, 2.4, Paint()..color = const Color(0xFFFFF1C2));
        }
      }
    }
    // The van at the bottom, from behind: two tail lights.
    final vb = Rect.fromCenter(center: geo.forkVan, width: 74, height: 56);
    canvas.drawRRect(RRect.fromRectAndRadius(vb, const Radius.circular(8)), Paint()..color = const Color(0xFFBFC8D6));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(vb.left + 8, vb.top + 6, vb.width - 16, 18), const Radius.circular(3)), Paint()..color = const Color(0xFF243652));
    for (final x in [vb.left + 7, vb.right - 7]) {
      canvas.drawCircle(Offset(x, vb.bottom - 14), 4, Paint()..color = const Color(0xFFE5483B));
    }
    canvas.drawCircle(Offset(vb.center.dx + 14, vb.top - 4), 4, Paint()..color = const Color(0xFFFFF4C8));
  }

  @override
  bool shouldRepaint(M5SlForkPainter old) => old.geo != geo || old.fieldLeft != fieldLeft || old.seed != seed;
}

// ============================================================================
// Patrol
// ============================================================================

/// The patrol camera and searchlight: changes every frame while the van
/// moves; only the patrol painter listens to it.
class M5SlPatrolView extends ChangeNotifier {
  /// Camera position (design px travelled).
  double x = 0;

  /// Where the searchlight's spot is (design px, on screen).
  Offset aim = const Offset(250, 260);

  /// The searchlight is on.
  bool lightOn = true;

  /// The van's headlights are on.
  bool headlights = true;

  /// The pole whose top is in the spot, and whether it has rested there long
  /// enough (at a slow speed) to show its detail.
  int? lit;
  bool resolved = false;
  double dwell = 0;

  /// Moving fast: the spot smears (no detail).
  bool fast = false;

  /// The poles marked so far.
  final Set<int> pinned = {};

  void changed() => notifyListeners();
}

/// The side-scrolling patrol: sky, tree line, the far poles, the road, the
/// van, the near poles, the searchlight cone and the lit pole top.
class M5SlPatrolPainter extends CustomPainter {
  M5SlPatrolPainter({required this.geo, required this.poles, required this.view, required this.seed}) : super(repaint: view);
  final M5SlGeo geo;
  final List<M5SlPole> poles;
  final M5SlPatrolView view;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    final s = Size(360, geo.height);
    final x = view.x;
    _sky(canvas, s, geo.roadTop);
    _stars(canvas, s, geo.farTopY - 20, seed, drift: x * 0.05);
    // The tree line (slow parallax).
    final tree = Path()..moveTo(0, geo.roadTop - 30);
    for (var px = 0.0; px <= 360; px += 12) {
      final wx = px + x * 0.35;
      final hgt = 22 + 12 * math.sin(wx * 0.045) + 8 * math.sin(wx * 0.13 + 1.3);
      tree.lineTo(px, geo.roadTop - 30 - hgt);
    }
    tree
      ..lineTo(360, geo.roadTop)
      ..lineTo(0, geo.roadTop)
      ..close();
    canvas.drawPath(tree, Paint()..color = const Color(0xFF07101C));
    canvas.drawRect(Rect.fromLTRB(0, geo.roadTop - 30, 360, geo.roadTop), Paint()..color = const Color(0xFF0A1420));
    // Far poles and their line.
    _side(canvas, M5SlSide.far, x);
    // The road.
    final road = Rect.fromLTRB(0, geo.roadTop, 360, geo.roadBottom);
    canvas.drawRect(road, Paint()
      ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1A1D23), Color(0xFF2A2E35)]).createShader(road));
    final dash = Paint()
      ..color = const Color(0xFF9C8F5A)
      ..strokeWidth = 2;
    final cy = (geo.roadTop + geo.roadBottom) / 2 + 6;
    for (var px = -(x % 44); px < 360; px += 44) {
      canvas.drawLine(Offset(px, cy), Offset(px + 20, cy), dash);
    }
    // Near verge.
    final verge = Rect.fromLTRB(0, geo.roadBottom, 360, geo.height);
    canvas.drawRect(verge, Paint()
      ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF13201A), Color(0xFF0B140F)]).createShader(verge));
    // Headlights on the road ahead.
    if (view.headlights) {
      final hl = Path()
        ..moveTo(geo.van.right - 2, geo.van.top + 38)
        ..lineTo(360, geo.van.top + 18)
        ..lineTo(360, geo.roadBottom - 2)
        ..close();
      canvas.drawPath(hl, Paint()
        ..shader = LinearGradient(colors: const [Color(0x55FFF0B0), Color(0x00FFF0B0)])
            .createShader(Rect.fromLTRB(geo.van.right, geo.roadTop, 360, geo.roadBottom)));
    }
    paintVan(canvas, geo.van, lampOn: view.lightOn, headlights: view.headlights);
    // Near poles and their line (in front of the van).
    _side(canvas, M5SlSide.near, x);
    // The searchlight cone and its spot.
    if (view.lightOn) {
      final o = geo.lamp;
      final a = view.aim;
      final d = a - o;
      final len = math.max(1.0, d.distance);
      final n = Offset(-d.dy / len, d.dx / len);
      final r = view.fast ? M5SlGeo.spot * 1.25 : M5SlGeo.spot;
      final cone = Path()
        ..moveTo(o.dx + n.dx * 3, o.dy + n.dy * 3)
        ..lineTo(a.dx + n.dx * r, a.dy + n.dy * r)
        ..lineTo(a.dx - n.dx * r, a.dy - n.dy * r)
        ..lineTo(o.dx - n.dx * 3, o.dy - n.dy * 3)
        ..close();
      canvas.drawPath(cone, Paint()
        ..shader = LinearGradient(colors: const [Color(0x55FFF6D6), Color(0x22FFF6D6)]).createShader(Rect.fromPoints(o, a)));
      canvas.drawCircle(a, r, Paint()
        ..shader = RadialGradient(colors: [Color.fromRGBO(255, 248, 220, view.fast ? 0.22 : 0.34), const Color(0x00FFF8DC)])
            .createShader(Rect.fromCircle(center: a, radius: r)));
    }
    // The lit pole top drawn again on top of the cone, in its colours.
    final lit = view.lit;
    if (lit != null && lit < poles.length && view.lightOn) {
      final p = poles[lit];
      _poleTop(canvas, p, Offset(geo.poleScreenX(lit, x), geo.topY(p.side)), p.side == M5SlSide.near ? 1.0 : 0.72, view.resolved && !view.fast ? 2 : 1);
    }
    // Marks on the pinned poles.
    for (final i in view.pinned) {
      final p = poles[i];
      final t = Offset(geo.poleScreenX(i, x), geo.topY(p.side));
      if (t.dx < -30 || t.dx > 390) continue;
      _pin(canvas, t.translate(0, p.side == M5SlSide.near ? 30 : 24));
    }
  }

  void _pin(Canvas c, Offset at) {
    c.drawLine(at, at.translate(0, -24), Paint()
      ..color = const Color(0xFFE9EEF5)
      ..strokeWidth = 1.6);
    final flag = Path()
      ..moveTo(at.dx, at.dy - 24)
      ..lineTo(at.dx + 16, at.dy - 19)
      ..lineTo(at.dx, at.dy - 13)
      ..close();
    c.drawPath(flag, Paint()..color = const Color(0xFFE5483B));
  }

  void _side(Canvas c, M5SlSide side, double x) {
    final k = side == M5SlSide.near ? 1.0 : 0.72;
    final mine = [for (var i = 0; i < poles.length; i++) if (poles[i].side == side) i];
    final wire = Paint()
      ..color = const Color(0xFF39465C)
      ..strokeWidth = side == M5SlSide.near ? 1.2 : 0.9
      ..style = PaintingStyle.stroke;
    final ty = geo.topY(side);
    final arm = 30 * k;
    // The line: three wires between this side's poles (and off both edges).
    final xs = [for (final i in mine) geo.poleScreenX(i, x)];
    final pts = [if (xs.isEmpty || xs.first > -40) -60.0, ...xs, if (xs.isEmpty || xs.last < 400) 420.0];
    for (final dx in [-arm * 0.8, 0.0, arm * 0.8]) {
      final path = Path()..moveTo(pts.first + dx, ty - 6 * k);
      for (var j = 1; j < pts.length; j++) {
        final a = pts[j - 1] + dx, b = pts[j] + dx;
        path.quadraticBezierTo((a + b) / 2, ty - 6 * k + 12 * k, b, ty - 6 * k);
      }
      c.drawPath(path, wire);
    }
    for (final i in mine) {
      final px = geo.poleScreenX(i, x);
      if (px < -40 || px > 400) continue;
      final base = geo.baseY(side);
      c.drawRect(Rect.fromLTRB(px - 3.4 * k, ty, px + 3.4 * k, base), Paint()
        ..shader = const LinearGradient(colors: [Color(0xFF1A202B), Color(0xFF2B3442), Color(0xFF151A23)])
            .createShader(Rect.fromLTRB(px - 4, ty, px + 4, base)));
      if (view.lit != i || !view.lightOn) _poleTop(c, poles[i], Offset(px, ty), k, 0);
    }
  }

  /// A pole top. [state] 0 = a black silhouette (the same for every pole),
  /// 1 = lit but moving or just arrived (lighter, no detail), 2 = resolved.
  void _poleTop(Canvas c, M5SlPole p, Offset t, double k, int state) {
    final arm = 34 * k;
    final silhouette = state == 0 ? const Color(0xFF03060C) : (state == 1 ? const Color(0xFF55607A) : null);
    final armPaint = Paint()..color = silhouette ?? const Color(0xFF8E97A6);
    c.drawRect(Rect.fromLTRB(t.dx - arm, t.dy - 2 * k, t.dx + arm, t.dy + 3 * k), armPaint);
    for (final (j, dx) in [-arm * 0.8, 0.0, arm * 0.8].indexed) {
      final base = Offset(t.dx + dx, t.dy - 2 * k);
      final broken = state == 2 && p.fault == M5SlFault.insulator && j == 2;
      final col = silhouette ?? (p.porcelain ? const Color(0xFFA0522D) : const Color(0xFF9AA3AE));
      final ins = Paint()..color = col;
      if (broken) {
        // A shattered insulator: the lower shed only, a jagged break, chips.
        final path = Path()
          ..moveTo(base.dx - 4 * k, base.dy)
          ..lineTo(base.dx - 4 * k, base.dy - 5 * k)
          ..lineTo(base.dx - 1 * k, base.dy - 8 * k)
          ..lineTo(base.dx + 1 * k, base.dy - 5 * k)
          ..lineTo(base.dx + 4 * k, base.dy - 7 * k)
          ..lineTo(base.dx + 4 * k, base.dy)
          ..close();
        c.drawPath(path, ins);
        c.drawLine(base.translate(-2 * k, -6 * k), base.translate(2 * k, -2 * k), Paint()
          ..color = const Color(0xFF2B1A10)
          ..strokeWidth = 1);
        for (final o in [const Offset(-7, 6), const Offset(6, 9), const Offset(9, 3)]) {
          c.drawCircle(base + o * k, 1.1 * k, ins);
        }
        // The wire sags off its top.
        c.drawLine(base.translate(0, -6 * k), base.translate(10 * k, 4 * k), Paint()
          ..color = const Color(0xFFB9C2D0)
          ..strokeWidth = 1.2 * k);
      } else {
        for (var sh = 0; sh < 3; sh++) {
          c.drawOval(Rect.fromCenter(center: base.translate(0, -2 * k - sh * 3.6 * k), width: (9 - sh) * k, height: 3.4 * k), ins);
        }
        c.drawRect(Rect.fromCenter(center: base.translate(0, -6 * k), width: 3 * k, height: 10 * k), ins);
      }
    }
    if (state == 2 && p.fault == M5SlFault.branch) {
      // A fallen branch lying across two phases, with leaves.
      final a = t.translate(-arm * 1.1, -12 * k);
      final b = t.translate(arm * 0.5, -1 * k);
      c.drawLine(a, b, Paint()
        ..color = const Color(0xFF6B4A2B)
        ..strokeWidth = 3 * k
        ..strokeCap = StrokeCap.round);
      c.drawLine(Offset.lerp(a, b, 0.4)!, Offset.lerp(a, b, 0.4)!.translate(-4 * k, -10 * k), Paint()
        ..color = const Color(0xFF6B4A2B)
        ..strokeWidth = 1.8 * k);
      final leaf = Paint()..color = const Color(0xFF4F8A3A);
      for (final f in [0.1, 0.3, 0.55, 0.8]) {
        final at = Offset.lerp(a, b, f)!;
        c.drawOval(Rect.fromCenter(center: at.translate(0, -3 * k), width: 7 * k, height: 4 * k), leaf);
      }
    }
    if (state == 2) {
      // The pole plate under the cross-arm.
      c.drawRect(Rect.fromCenter(center: t.translate(0, 18 * k), width: 10 * k, height: 6 * k), Paint()..color = const Color(0xFFE2E6EC));
    }
  }

  @override
  bool shouldRepaint(M5SlPatrolPainter old) => old.geo != geo || old.poles != poles || old.view != view || old.seed != seed;
}

/// A truck rushing past on the road ([v] 0 → 1 = right edge → off the left),
/// headlights blazing.
class M5SlTruckPainter extends CustomPainter {
  const M5SlTruckPainter({required this.geo, required this.v});
  final M5SlGeo geo;
  final double v;

  @override
  void paint(Canvas canvas, Size size) {
    final left = 380 - v * 560;
    final top = geo.roadTop + 4;
    final b = Rect.fromLTWH(left, top, 150, 66);
    canvas.drawPath(
      Path()
        ..moveTo(b.left, b.top + 30)
        ..lineTo(b.left - 120, b.top + 6)
        ..lineTo(b.left - 120, b.bottom + 6)
        ..close(),
      Paint()..shader = LinearGradient(colors: const [Color(0x88FFF3C0), Color(0x00FFF3C0)]).createShader(Rect.fromLTRB(b.left - 120, b.top, b.left, b.bottom)),
    );
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(b.left, b.top + 10, 44, 46), const Radius.circular(6)), Paint()..color = const Color(0xFFB4462E));
    canvas.drawRect(Rect.fromLTWH(b.left + 44, b.top, 106, 56), Paint()..color = const Color(0xFF59606C));
    for (final fx in [0.15, 0.6, 0.85]) {
      canvas.drawCircle(Offset(b.left + b.width * fx, b.bottom - 4), 9, Paint()..color = const Color(0xFF111318));
    }
    canvas.drawCircle(Offset(b.left + 3, b.top + 34), 4, Paint()..color = const Color(0xFFFFF3C0));
  }

  @override
  bool shouldRepaint(M5SlTruckPainter old) => old.v != v || old.geo != geo;
}

/// The trainee's own light at the step-out: a short beam from his head to
/// the pole's foot; [on] false = it has died.
class M5SlBeamPainter extends CustomPainter {
  const M5SlBeamPainter({required this.from, required this.to, required this.on});
  final Offset from;
  final Offset to;
  final double on;

  @override
  void paint(Canvas canvas, Size size) {
    if (on <= 0.01) return;
    final d = to - from;
    final len = math.max(1.0, d.distance);
    final n = Offset(-d.dy / len, d.dx / len);
    final p = Path()
      ..moveTo(from.dx, from.dy)
      ..lineTo(to.dx + n.dx * 22, to.dy + n.dy * 22)
      ..lineTo(to.dx - n.dx * 22, to.dy - n.dy * 22)
      ..close();
    canvas.drawPath(p, Paint()..color = Color.fromRGBO(255, 246, 210, 0.28 * on));
  }

  @override
  bool shouldRepaint(M5SlBeamPainter old) => old.on != on || old.from != from || old.to != to;
}

/// The deadly consequence: the tripped line charges again (the control room
/// or the recloser) while the trainee is on the pole — an arc at the top.
class M5SlFlashPainter extends CustomPainter {
  const M5SlFlashPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas canvas, Size size) {
    final r = 20 + 70 * v;
    canvas.drawCircle(
      at,
      r,
      Paint()
        ..shader = RadialGradient(colors: [Color.fromRGBO(255, 255, 255, 0.95 * (1 - v * 0.4)), Color.fromRGBO(120, 180, 255, 0.6 * (1 - v)), const Color(0x0078B4FF)])
            .createShader(Rect.fromCircle(center: at, radius: r)),
    );
    final bolt = Paint()
      ..color = Color.fromRGBO(200, 225, 255, 1 - v * 0.6)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;
    final rr = math.Random(7);
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3 + rr.nextDouble() * 0.5;
      final path = Path()..moveTo(at.dx, at.dy);
      var p = at;
      for (var j = 0; j < 4; j++) {
        p = p + Offset(math.cos(a), math.sin(a)) * (8 + 10 * v) + Offset(rr.nextDouble() * 8 - 4, rr.nextDouble() * 8 - 4);
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, bolt);
    }
  }

  @override
  bool shouldRepaint(M5SlFlashPainter old) => old.v != v || old.at != at;
}
