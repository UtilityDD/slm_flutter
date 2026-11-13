import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The drawn world of lesson 5.6 কাজ 1 "দুই শত্রুর খাতা" (m5_fault_casebook.dart):
// a village edge in the late afternoon. An 11 kV line comes in from a far pole
// on the left, over the near pole's cross-arm and on to the right; a service
// line drops to a small brick pump house in the far field on the right. A
// villager stands on the left; the trainee stands by the near pole with his
// notebook; a strip of grass and path lies under the span in front.
//
// Every case is played in the same place with the same four clue spots (the
// person, the pole top, the ground strip, the pump house): the scene itself
// never shows what happened — a clue is seen only through its close-up lens
// (M5LensPainter) once the player spends a clue on it. Code-drawn, gradients,
// no bitmaps, no text.
//
// Design: 360 wide × the scene's height; the ground follows the bottom of the
// screen (a tall phone gets a taller pole and more sky, never stretched).

/// The four clue spots (the same in every case).
enum M5Spot { person, pole, ground, pump }

/// How a spot is opened: tap the person, swipe up the pole, sweep the ground,
/// hold the pump-house door.
enum M5Gesture { tap, swipeUp, sweep, hold }

M5Gesture m5GestureFor(M5Spot s) => switch (s) {
      M5Spot.person => M5Gesture.tap,
      M5Spot.pole => M5Gesture.swipeUp,
      M5Spot.ground => M5Gesture.sweep,
      M5Spot.pump => M5Gesture.hold,
    };

/// What a spot's close-up lens shows.
enum M5Look {
  // the person (the witness)
  witnessBang,
  witnessQuiet,
  witnessGroan,
  witnessSmoke,
  // the pole top
  poleClash,
  poleBranch,
  poleBird,
  poleJumper,
  polePhase,
  poleClean,
  poleDryBranch,
  // the ground strip under the span
  groundMelt,
  groundTwigs,
  groundFeathers,
  groundClean,
  groundLeaves,
  // the pump house
  pumpStopped,
  pumpGroan,
  pumpRunning,
}

/// Where things are (design px, 360 wide).
@immutable
class M5CaseGeo {
  const M5CaseGeo._(this.height, this.groundY);

  factory M5CaseGeo.forScene(double height, double inset) => M5CaseGeo._(height, height - floorUp - inset * 0.5);

  final double height;

  /// The front edge of the ground strip (the notebook sits below it).
  final double groundY;

  /// The ground sits this far above the bottom (the notebook stands on it).
  static const double floorUp = 206;

  /// The near pole's axis and its top.
  static const double poleX = 175;
  double get topY => math.max(150.0, groundY - 360);

  /// The cross-arm and the three insulator tops (the line runs over them).
  double get armY => topY + 16;
  static const List<double> phaseX = [150, 175, 200];

  /// The pole's foot (on the back edge of the ground strip).
  double get footY => groundY - 70;

  /// The pump house in the far field (its door faces the player).
  double get pumpTop => math.max(128.0, groundY - 262);
  Rect get pumpHouse => Rect.fromLTWH(262, pumpTop + 26, 78, 62);
  Rect get pumpDoor => Rect.fromLTWH(pumpHouse.left + 30, pumpHouse.top + 22, 20, pumpHouse.height - 22);

  /// The far field's edge (the horizon line behind the pump house).
  double get fieldTop => math.min(groundY - 190, pumpHouse.bottom - 14);

  /// The villager (feet on the ground) and the trainee by the pole.
  Rect get villager => Rect.fromLTWH(26, groundY - 150, 56, 140);
  Rect get trainee => Rect.fromLTWH(98, groundY - 182, 44, 112);

  /// Each spot's touch area. They never overlap; all below the header and
  /// above the notebook.
  Rect hit(M5Spot s) => switch (s) {
        M5Spot.person => Rect.fromLTRB(14, groundY - 170, 94, groundY - 6),
        M5Spot.pole => Rect.fromLTRB(138, topY - 6, 212, footY - 4),
        M5Spot.ground => Rect.fromLTRB(96, groundY - 64, 246, groundY - 2),
        M5Spot.pump => Rect.fromLTRB(252, pumpTop, 350, pumpTop + 96),
      };

  /// The spot under [p] (design px), or null.
  M5Spot? spotAt(Offset p) {
    for (final s in M5Spot.values) {
      if (hit(s).contains(p)) return s;
    }
    return null;
  }

  /// The close-up lens over a spot (kept on the scene, under the header).
  Rect lens(M5Spot s) {
    const d = 132.0;
    final c = hit(s).center;
    final x = c.dx.clamp(6 + d / 2, 354 - d / 2).toDouble();
    final y = c.dy.clamp(126 + d / 2, math.max(126 + d / 2, groundY - 4 - d / 2)).toDouble();
    return Rect.fromCenter(center: Offset(x, y), width: d, height: d);
  }

  @override
  bool operator ==(Object other) => other is M5CaseGeo && other.height == height && other.groundY == groundY;

  @override
  int get hashCode => Object.hash(height, groundY);
}

const _wire = Color(0xFF34393F);
const _steel = Color(0xFF6E767E);
const _porcelain = Color(0xFFE6EAEE);
const _scorch = Color(0xFF17120E);

/// The whole place (static; it repaints only when the geometry or the case's
/// light changes).
class M5CasebookPainter extends CustomPainter {
  const M5CasebookPainter({required this.geo, required this.light, required this.opened});

  final M5CaseGeo geo;

  /// 0..3: the sun sinks a little with each case (cosmetic, never a clue).
  final int light;

  /// Spots already opened this case (a small notebook tab marks them).
  final Set<M5Spot> opened;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    final sink = light.clamp(0, 3) / 3.0;
    // Sky: late afternoon, warmer case by case.
    final skyRect = Rect.fromLTWH(0, 0, w, g.fieldTop + 2);
    c.drawRect(
      skyRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(const Color(0xFF4F76A8), const Color(0xFF3E5B8C), sink)!,
            Color.lerp(const Color(0xFFE7B07A), const Color(0xFFE59A62), sink)!,
            Color.lerp(const Color(0xFFF7DDB0), const Color(0xFFF3C894), sink)!,
          ],
          stops: const [0, 0.72, 1],
        ).createShader(skyRect),
    );
    // The low sun.
    final sun = Offset(78, g.fieldTop - 46 + 22 * sink);
    c.drawCircle(sun, 34, Paint()..color = const Color(0x33FFE2A8));
    c.drawCircle(sun, 18, Paint()..color = const Color(0xFFFFE6B0));
    // Far tree line and huts.
    final trees = Paint()..color = const Color(0xFF4C6A3E);
    for (var i = 0; i < 12; i++) {
      final x = i * 32.0 + (i.isOdd ? 8 : 0);
      c.drawOval(Rect.fromCenter(center: Offset(x, g.fieldTop - 6), width: 44, height: 24 + (i % 3) * 6), trees);
    }
    for (final x in [16.0, 58.0]) {
      final base = g.fieldTop + 2;
      c.drawRect(Rect.fromLTWH(x, base - 16, 30, 16), Paint()..color = const Color(0xFFB08A62));
      c.drawPath(
        Path()
          ..moveTo(x - 4, base - 15)
          ..lineTo(x + 15, base - 28)
          ..lineTo(x + 34, base - 15)
          ..close(),
        Paint()..color = const Color(0xFF7A4E2E),
      );
    }
    // Fields.
    final fieldRect = Rect.fromLTRB(0, g.fieldTop, w, g.groundY - 64);
    c.drawRect(
      fieldRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8FA858), Color(0xFF6F8F45)],
        ).createShader(fieldRect),
    );
    final rows = Paint()
      ..color = const Color(0x2A2F4A1C)
      ..strokeWidth = 1.2;
    for (var y = g.fieldTop + 10; y < g.groundY - 70; y += 14) {
      c.drawLine(Offset(0, y), Offset(w, y + 4), rows);
    }
    // A water channel from the pump house.
    final ph = g.pumpHouse;
    c.drawPath(
      Path()
        ..moveTo(ph.left + 6, ph.bottom + 2)
        ..quadraticBezierTo(220, ph.bottom + 30, 252, g.groundY - 70)
        ..lineTo(266, g.groundY - 70)
        ..quadraticBezierTo(236, ph.bottom + 32, ph.left + 18, ph.bottom + 2)
        ..close(),
      Paint()..color = const Color(0xFF7E9AA6),
    );
    // The pump house: brick walls, tin roof, a green door, the outlet pipe.
    c.drawRect(
      ph,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB4664A), Color(0xFF8E4C36)],
        ).createShader(ph),
    );
    final mortar = Paint()
      ..color = const Color(0x40FFFFFF)
      ..strokeWidth = 0.8;
    for (var y = ph.top + 8; y < ph.bottom; y += 8) {
      c.drawLine(Offset(ph.left, y), Offset(ph.right, y), mortar);
    }
    c.drawPath(
      Path()
        ..moveTo(ph.left - 6, ph.top + 2)
        ..lineTo(ph.center.dx, ph.top - 20)
        ..lineTo(ph.right + 6, ph.top + 2)
        ..close(),
      Paint()..color = const Color(0xFF9AA3A8),
    );
    final door = g.pumpDoor;
    c.drawRect(door, Paint()..color = const Color(0xFF2F5B45));
    c.drawCircle(Offset(door.right - 4, door.center.dy), 1.6, Paint()..color = const Color(0xFFD9C27A));
    c.drawRect(Rect.fromLTWH(ph.left - 10, ph.bottom - 12, 12, 5), Paint()..color = _steel);
    // The far poles and the line.
    final farL = Offset(22, g.armY + 70);
    final farR = Offset(352, g.armY + 54);
    final pole = Paint()
      ..color = const Color(0xFF8D949A)
      ..strokeWidth = 4;
    c.drawLine(farL.translate(0, -6), Offset(farL.dx, g.fieldTop + 8), pole);
    c.drawLine(farR.translate(0, -6), Offset(farR.dx, g.fieldTop + 4), pole);
    // The service drop to the pump house.
    final drop = Paint()
      ..color = _wire
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;
    c.drawPath(
      Path()
        ..moveTo(M5CaseGeo.phaseX.last + 40, g.armY - 6)
        ..quadraticBezierTo(250, ph.top - 4, ph.right - 6, ph.top + 4),
      drop,
    );
    // The near pole (PCC, tapered), the cross-arm and insulators.
    final px = M5CaseGeo.poleX;
    final body = Path()
      ..moveTo(px - 5, g.topY)
      ..lineTo(px + 5, g.topY)
      ..lineTo(px + 8, g.footY)
      ..lineTo(px - 8, g.footY)
      ..close();
    c.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFFB9BEC2), Color(0xFF8C9297)])
            .createShader(Rect.fromLTRB(px - 8, g.topY, px + 8, g.footY)),
    );
    c.drawRect(Rect.fromLTRB(px - 34, g.armY, px + 34, g.armY + 6), Paint()..color = _steel);
    for (final x in M5CaseGeo.phaseX) {
      c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x - 4, g.armY - 14, 8, 14), const Radius.circular(3)),
        Paint()..color = _porcelain,
      );
    }
    // The three phase wires: from the far left pole over the insulators to the right.
    final wire = Paint()
      ..color = _wire
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 3; i++) {
      final x = M5CaseGeo.phaseX[i];
      final top = Offset(x, g.armY - 14);
      final l = farL.translate(-4.0 + i * 4, -6.0 - i * 2);
      final r = farR.translate(-4.0 + i * 4, -6.0 - i * 2);
      c.drawPath(
        Path()
          ..moveTo(l.dx, l.dy)
          ..quadraticBezierTo((l.dx + top.dx) / 2, math.max(l.dy, top.dy) + 18, top.dx, top.dy)
          ..quadraticBezierTo((top.dx + r.dx) / 2, math.max(r.dy, top.dy) + 16, r.dx, r.dy),
        wire,
      );
    }
    // Front ground strip under the span (grass and a dirt path).
    final strip = Rect.fromLTRB(0, g.groundY - 66, w, size.height);
    c.drawRect(
      strip,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5E7F3A), Color(0xFF3F5A27), Color(0xFF2A3B1B)],
          stops: [0, 0.35, 1],
        ).createShader(strip),
    );
    c.drawPath(
      Path()
        ..moveTo(110, g.groundY - 66)
        ..lineTo(230, g.groundY - 66)
        ..lineTo(270, g.groundY + 20)
        ..lineTo(80, g.groundY + 20)
        ..close(),
      Paint()..color = const Color(0xFF9C8360),
    );
    final blade = Paint()
      ..color = const Color(0x553A5A22)
      ..strokeWidth = 1.2;
    final rnd = math.Random(56);
    for (var i = 0; i < 46; i++) {
      final x = rnd.nextDouble() * w;
      final y = g.groundY - 60 + rnd.nextDouble() * 70;
      c.drawLine(Offset(x, y), Offset(x + 2, y - 6), blade);
    }
    // The villager: lungi, kurta, a gamchha on the shoulder.
    _villager(c, g.villager);
    // Opened spots: a small notebook tab at the corner (seen, not judged).
    for (final s in opened) {
      final r = g.hit(s);
      final at = Offset(r.right - 8, r.top + 8);
      c.drawCircle(at, 8, Paint()..color = const Color(0xFFFDF6E3));
      c.drawCircle(
          at,
          8,
          Paint()
            ..color = const Color(0xFF8A6A2E)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4);
      c.drawLine(at.translate(-3.5, 0), at.translate(3.5, 0), Paint()..color = const Color(0xFF8A6A2E)..strokeWidth = 1.4);
      c.drawLine(at.translate(-3.5, -3), at.translate(3.5, -3), Paint()..color = const Color(0xFF8A6A2E)..strokeWidth = 1.4);
      c.drawLine(at.translate(-3.5, 3), at.translate(1.5, 3), Paint()..color = const Color(0xFF8A6A2E)..strokeWidth = 1.4);
    }
  }

  void _villager(Canvas c, Rect r) {
    final cx = r.center.dx;
    final skin = Paint()..color = const Color(0xFFB07A52);
    // legs
    c.drawRect(Rect.fromLTWH(cx - 9, r.bottom - 34, 7, 34), skin);
    c.drawRect(Rect.fromLTWH(cx + 2, r.bottom - 34, 7, 34), skin);
    // lungi (checked)
    final lungi = Rect.fromLTWH(cx - 14, r.top + 72, 28, 40);
    c.drawRect(lungi, Paint()..color = const Color(0xFF2F5D8A));
    final check = Paint()
      ..color = const Color(0x55FFFFFF)
      ..strokeWidth = 1;
    for (var x = lungi.left + 5; x < lungi.right; x += 7) {
      c.drawLine(Offset(x, lungi.top), Offset(x, lungi.bottom), check);
    }
    // kurta
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(cx - 15, r.top + 30, 30, 46), const Radius.circular(7)),
        Paint()..color = const Color(0xFFEDE6D6));
    // gamchha
    c.drawLine(Offset(cx - 13, r.top + 32), Offset(cx + 6, r.top + 60), Paint()..color = const Color(0xFFC0392B)..strokeWidth = 4);
    // arms
    c.drawLine(Offset(cx - 14, r.top + 36), Offset(cx - 20, r.top + 70), skin..strokeWidth = 5);
    c.drawLine(Offset(cx + 14, r.top + 36), Offset(cx + 20, r.top + 70), skin);
    // head
    c.drawCircle(Offset(cx, r.top + 18), 12, Paint()..color = const Color(0xFFB07A52));
    c.drawArc(Rect.fromCircle(center: Offset(cx, r.top + 16), radius: 12.5), math.pi, math.pi, true, Paint()..color = const Color(0xFF1E1A17));
  }

  @override
  bool shouldRepaint(M5CasebookPainter old) => old.geo != geo || old.light != light || !setEquals(old.opened, opened);
}

/// One clue's close-up, drawn inside a circle (the lens). No text.
class M5LensPainter extends CustomPainter {
  const M5LensPainter({required this.look});

  final M5Look look;

  @override
  void paint(Canvas c, Size size) {
    final r = Offset.zero & size;
    final clip = Path()..addOval(r);
    c.save();
    c.clipPath(clip);
    switch (look) {
      case M5Look.witnessBang || M5Look.witnessQuiet || M5Look.witnessGroan || M5Look.witnessSmoke:
        _witness(c, size);
      case M5Look.poleClash ||
            M5Look.poleBranch ||
            M5Look.poleBird ||
            M5Look.poleJumper ||
            M5Look.polePhase ||
            M5Look.poleClean ||
            M5Look.poleDryBranch:
        _poleTop(c, size);
      case M5Look.groundMelt || M5Look.groundTwigs || M5Look.groundFeathers || M5Look.groundClean || M5Look.groundLeaves:
        _ground(c, size);
      case M5Look.pumpStopped || M5Look.pumpGroan || M5Look.pumpRunning:
        _pump(c, size);
    }
    c.restore();
    // The lens rim.
    c.drawOval(
      r.deflate(1.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = const Color(0xFF3B2A12),
    );
    c.drawOval(
      r.deflate(4.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0x88FFFFFF),
    );
  }

  void _sky(Canvas c, Size s) {
    final r = Offset.zero & s;
    c.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7FA3C9), Color(0xFFF2CF9E)],
        ).createShader(r),
    );
  }

  void _witness(Canvas c, Size s) {
    _sky(c, s);
    final w = s.width;
    final face = Offset(w * 0.42, s.height * 0.56);
    // shoulders, face, hair
    c.drawOval(Rect.fromCenter(center: face.translate(0, w * 0.42), width: w * 0.8, height: w * 0.5), Paint()..color = const Color(0xFFEDE6D6));
    c.drawCircle(face, w * 0.2, Paint()..color = const Color(0xFFB07A52));
    c.drawArc(Rect.fromCircle(center: face.translate(0, -2), radius: w * 0.21), math.pi, math.pi, true, Paint()..color = const Color(0xFF1E1A17));
    final eye = Paint()..color = const Color(0xFF1E1A17);
    final mouth = Paint()
      ..color = const Color(0xFF5A2E1E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    switch (look) {
      case M5Look.witnessBang:
        // wide eyes, open mouth, a raised hand, burst lines up and right
        c.drawCircle(face.translate(-7, -3), 3.2, eye);
        c.drawCircle(face.translate(7, -3), 3.2, eye);
        c.drawOval(Rect.fromCenter(center: face.translate(0, 9), width: 9, height: 11), Paint()..color = const Color(0xFF5A2E1E));
        c.drawLine(face.translate(w * 0.22, w * 0.2), face.translate(w * 0.34, -w * 0.08), Paint()..color = const Color(0xFFB07A52)..strokeWidth = 7);
        final burst = Paint()
          ..color = const Color(0xFFFFF2A8)
          ..strokeWidth = 2.6;
        final at = Offset(w * 0.8, s.height * 0.2);
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          c.drawLine(at + Offset(math.cos(a), math.sin(a)) * 6, at + Offset(math.cos(a), math.sin(a)) * 16, burst);
        }
      case M5Look.witnessQuiet:
        // calm eyes, flat mouth, open palm (nothing seen)
        c.drawLine(face.translate(-10, -3), face.translate(-4, -3), mouth);
        c.drawLine(face.translate(4, -3), face.translate(10, -3), mouth);
        c.drawLine(face.translate(-5, 9), face.translate(5, 9), mouth);
        c.drawOval(Rect.fromCenter(center: face.translate(w * 0.3, w * 0.12), width: 16, height: 12), Paint()..color = const Color(0xFFB07A52));
      case M5Look.witnessGroan:
        // a hand at the ear, wavy sound lines from the right
        c.drawCircle(face.translate(-7, -3), 2.6, eye);
        c.drawCircle(face.translate(7, -3), 2.6, eye);
        c.drawArc(Rect.fromCenter(center: face.translate(0, 12), width: 12, height: 8), math.pi, math.pi, false, mouth);
        c.drawOval(Rect.fromCenter(center: face.translate(w * 0.2, 0), width: 12, height: 18), Paint()..color = const Color(0xFFB07A52));
        final wave = Paint()
          ..color = const Color(0xFF3B4A5A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        for (var k = 0; k < 3; k++) {
          final x = w * 0.72 + k * 9;
          final p = Path()..moveTo(x, s.height * 0.38);
          for (var j = 0; j < 4; j++) {
            p.relativeQuadraticBezierTo(6, 5, 0, 10);
            p.relativeQuadraticBezierTo(-6, 5, 0, 10);
          }
          c.drawPath(p, wave);
        }
      case M5Look.witnessSmoke:
        // pointing up, a grey wisp at the top right
        c.drawCircle(face.translate(-7, -3), 2.6, eye);
        c.drawCircle(face.translate(7, -3), 2.6, eye);
        c.drawLine(face.translate(-5, 10), face.translate(5, 8), mouth);
        c.drawLine(face.translate(w * 0.22, w * 0.2), face.translate(w * 0.36, -w * 0.18), Paint()..color = const Color(0xFFB07A52)..strokeWidth = 6);
        _wisp(c, Offset(w * 0.78, s.height * 0.3), 0.9);
      default:
        break;
    }
  }

  void _wisp(Canvas c, Offset at, double k) {
    final smoke = Paint()..color = const Color(0x889AA0A6);
    for (var i = 0; i < 4; i++) {
      c.drawCircle(at.translate(i * 3.0 * k, -i * 9.0 * k), (6 + i * 2.5) * k, smoke);
    }
  }

  void _poleTop(Canvas c, Size s) {
    _sky(c, s);
    final w = s.width;
    final armY = s.height * 0.5;
    final xs = [w * 0.24, w * 0.5, w * 0.76];
    // pole and cross-arm
    c.drawRect(Rect.fromLTRB(w * 0.46, armY, w * 0.54, s.height), Paint()..color = const Color(0xFFA8AEB3));
    c.drawRect(Rect.fromLTRB(w * 0.08, armY, w * 0.92, armY + 8), Paint()..color = _steel);
    for (final x in xs) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, armY - 9), width: 11, height: 18), const Radius.circular(4)),
          Paint()..color = _porcelain);
    }
    final wire = Paint()
      ..color = _wire
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;
    final scorch = Paint()..color = _scorch;
    // Each phase: a wire across the lens through its insulator top.
    void phase(int i, {bool cut = false, double bow = 0}) {
      final y = armY - 18;
      final x = xs[i];
      if (!cut) {
        c.drawPath(
          Path()
            ..moveTo(x - w * 0.5, y - 10)
            ..quadraticBezierTo(x - w * 0.2 + bow, y + 4, x, y)
            ..quadraticBezierTo(x + w * 0.2 + bow, y + 4, x + w * 0.5, y - 10),
          wire,
        );
      } else {
        // Line on the left only; the jumper end hangs free.
        c.drawPath(
          Path()
            ..moveTo(x - w * 0.5, y - 10)
            ..quadraticBezierTo(x - w * 0.2, y + 4, x - 4, y),
          wire,
        );
        c.drawPath(
          Path()
            ..moveTo(x - 4, y)
            ..quadraticBezierTo(x + 10, y + 22, x + 2, y + 44),
          wire,
        );
        c.drawPath(
          Path()
            ..moveTo(x + 14, y + 2)
            ..quadraticBezierTo(x + w * 0.2, y + 6, x + w * 0.5, y - 10),
          wire,
        );
      }
    }

    switch (look) {
      case M5Look.poleClash:
        phase(0, bow: 10);
        phase(1, bow: -10);
        phase(2);
        final mid = Offset((xs[0] + xs[1]) / 2, armY - 16);
        c.drawOval(Rect.fromCenter(center: mid, width: 26, height: 10), scorch);
        c.drawCircle(mid.translate(-14, 2), 4, scorch);
        c.drawCircle(mid.translate(12, -1), 3, scorch);
      case M5Look.poleBranch:
        for (var i = 0; i < 3; i++) {
          phase(i);
        }
        final branch = Paint()
          ..color = const Color(0xFF5B3A1E)
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round;
        c.drawLine(Offset(xs[1] - 30, armY - 40), Offset(xs[2] + 22, armY - 14), branch);
        c.drawLine(Offset(xs[1] + 6, armY - 31), Offset(xs[1] + 18, armY - 52), branch..strokeWidth = 3);
        for (final x in [xs[1] + 4, xs[2] - 4]) {
          c.drawCircle(Offset(x, armY - 24), 6, scorch);
        }
        for (var k = 0; k < 4; k++) {
          c.drawOval(Rect.fromCenter(center: Offset(xs[1] - 18 + k * 18, armY - 44 + k * 6), width: 10, height: 6), Paint()..color = const Color(0xFF2E2418));
        }
      case M5Look.poleBird:
        for (var i = 0; i < 3; i++) {
          phase(i);
        }
        // a dark, wide-winged bird across two wires
        final bird = Paint()..color = const Color(0xFF241F1C);
        final at = Offset((xs[0] + xs[1]) / 2, armY - 26);
        c.drawOval(Rect.fromCenter(center: at, width: 22, height: 12), bird);
        c.drawPath(
          Path()
            ..moveTo(at.dx - 6, at.dy)
            ..lineTo(xs[0] - 6, at.dy + 6)
            ..lineTo(at.dx - 2, at.dy + 4)
            ..close(),
          bird,
        );
        c.drawPath(
          Path()
            ..moveTo(at.dx + 6, at.dy)
            ..lineTo(xs[1] + 6, at.dy + 6)
            ..lineTo(at.dx + 2, at.dy + 4)
            ..close(),
          bird,
        );
        c.drawCircle(Offset(xs[0] + 2, armY - 20), 5, scorch);
        c.drawCircle(Offset(xs[1] - 2, armY - 20), 5, scorch);
      case M5Look.poleJumper:
        phase(0);
        phase(1, cut: true);
        phase(2);
      case M5Look.polePhase:
        phase(0);
        phase(1);
        phase(2, cut: true);
      case M5Look.poleClean:
        for (var i = 0; i < 3; i++) {
          phase(i);
        }
      case M5Look.poleDryBranch:
        for (var i = 0; i < 3; i++) {
          phase(i);
        }
        final dry = Paint()
          ..color = const Color(0xFFC9B48A)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round;
        c.drawLine(Offset(xs[2] + 34, s.height * 0.95), Offset(xs[2] - 4, armY - 22), dry);
        c.drawLine(Offset(xs[2] + 14, armY + 10), Offset(xs[2] + 30, armY - 6), dry..strokeWidth = 2.4);
        c.drawCircle(Offset(xs[2] - 2, armY - 20), 3.5, Paint()..color = const Color(0xFF5B4A33));
        _wisp(c, Offset(xs[2] - 2, armY - 28), 0.8);
      default:
        break;
    }
  }

  void _ground(Canvas c, Size s) {
    final r = Offset.zero & s;
    c.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6B8C42), Color(0xFF4A6A2C)],
        ).createShader(r),
    );
    final w = s.width;
    final blade = Paint()
      ..color = const Color(0xFF3A5A22)
      ..strokeWidth = 1.6;
    final rnd = math.Random(7);
    for (var i = 0; i < 40; i++) {
      final x = rnd.nextDouble() * w;
      final y = rnd.nextDouble() * s.height;
      c.drawLine(Offset(x, y), Offset(x + 2, y - 7), blade);
    }
    final centre = Offset(w * 0.5, s.height * 0.55);
    switch (look) {
      case M5Look.groundMelt:
        c.drawOval(Rect.fromCenter(center: centre, width: w * 0.5, height: w * 0.28), Paint()..color = const Color(0xAA1C140E));
        final bead = Paint()..color = const Color(0xFF6C6F72);
        for (final o in const [Offset(-14, -4), Offset(6, 6), Offset(18, -8), Offset(-4, 10), Offset(26, 4)]) {
          c.drawCircle(centre + o, 3.2, bead);
          c.drawCircle(centre + o + const Offset(-1, -1), 1.1, Paint()..color = const Color(0xFFE0E3E6));
        }
      case M5Look.groundTwigs:
        c.drawOval(Rect.fromCenter(center: centre, width: w * 0.46, height: w * 0.24), Paint()..color = const Color(0x881C140E));
        final twig = Paint()
          ..color = const Color(0xFF231A12)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
        c.drawLine(centre.translate(-26, 4), centre.translate(20, -8), twig);
        c.drawLine(centre.translate(-6, -2), centre.translate(4, 14), twig..strokeWidth = 2);
        for (var k = 0; k < 4; k++) {
          c.drawOval(Rect.fromCenter(center: centre.translate(-20.0 + k * 14, 10.0 - k * 3), width: 10, height: 6), Paint()..color = const Color(0xFF3A2A18));
        }
      case M5Look.groundFeathers:
        c.drawOval(Rect.fromCenter(center: centre, width: w * 0.42, height: w * 0.22), Paint()..color = const Color(0x881C140E));
        final feather = Paint()..color = const Color(0xFF4A4642);
        for (final o in const [Offset(-18, -2), Offset(4, 8), Offset(16, -6), Offset(-4, -10)]) {
          c.save();
          c.translate(centre.dx + o.dx, centre.dy + o.dy);
          c.rotate(o.dx / 20);
          c.drawOval(Rect.fromCenter(center: Offset.zero, width: 16, height: 5), feather);
          c.restore();
        }
      case M5Look.groundLeaves:
        for (final o in const [Offset(-22, 0), Offset(-2, 8), Offset(18, -4), Offset(6, -12), Offset(-12, 14)]) {
          c.drawOval(Rect.fromCenter(center: centre + o, width: 14, height: 8), Paint()..color = const Color(0xFFC9A25A));
          c.drawOval(Rect.fromCenter(center: centre + o + const Offset(4, 0), width: 6, height: 7), Paint()..color = const Color(0xFF3A2614));
        }
      default:
        break;
    }
  }

  void _pump(Canvas c, Size s) {
    final r = Offset.zero & s;
    c.drawRect(r, Paint()..color = const Color(0xFF5C4033));
    final w = s.width;
    // Inside the pump house: a floor, the motor and its pump, the outlet pipe.
    c.drawRect(Rect.fromLTRB(0, s.height * 0.7, w, s.height), Paint()..color = const Color(0xFF7A6A5A));
    final motor = Rect.fromLTWH(w * 0.2, s.height * 0.42, w * 0.36, s.height * 0.26);
    c.drawRRect(
      RRect.fromRectAndRadius(motor, const Radius.circular(8)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3F7FA8), Color(0xFF235673)],
        ).createShader(motor),
    );
    for (var k = 1; k < 5; k++) {
      final x = motor.left + motor.width * k / 5;
      c.drawLine(Offset(x, motor.top + 4), Offset(x, motor.bottom - 4), Paint()..color = const Color(0x55FFFFFF)..strokeWidth = 1.2);
    }
    final pump = Rect.fromLTWH(motor.right + 2, motor.top + 6, w * 0.16, motor.height - 10);
    c.drawRRect(RRect.fromRectAndRadius(pump, const Radius.circular(6)), Paint()..color = const Color(0xFF6E767E));
    final pipe = Paint()
      ..color = const Color(0xFF8D949A)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final out = Offset(w * 0.92, s.height * 0.5);
    c.drawLine(pump.centerRight, out, pipe);
    switch (look) {
      case M5Look.pumpGroan:
        final shake = Paint()
          ..color = const Color(0xFFFFE08A)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        for (final side in [-1.0, 1.0]) {
          final x = side < 0 ? motor.left - 6 : motor.center.dx;
          final p = Path()..moveTo(x, motor.top - 6);
          for (var j = 0; j < 3; j++) {
            p.relativeLineTo(side * 5, -5);
            p.relativeLineTo(-side * 5, -5);
          }
          c.drawPath(p, shake);
        }
      case M5Look.pumpRunning:
        final water = Paint()..color = const Color(0xCC7FC4E8);
        c.drawPath(
          Path()
            ..moveTo(out.dx - 2, out.dy - 4)
            ..quadraticBezierTo(out.dx + 10, out.dy + 10, out.dx + 4, s.height)
            ..lineTo(out.dx - 8, s.height)
            ..quadraticBezierTo(out.dx, out.dy + 12, out.dx - 2, out.dy + 4)
            ..close(),
          water,
        );
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(M5LensPainter old) => old.look != look;
}
