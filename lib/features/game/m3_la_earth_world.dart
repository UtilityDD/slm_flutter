import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals, mapEquals;
import 'package:flutter/material.dart';

// The yard of lesson 3.5 কাজ 2 ("কবচের মাটি"), drawn in code: a roadside
// 11 kV double-pole (DP) transformer structure seen from the front — the HT
// crossarm with three pin insulators, three DO fuses, the LA crossarm with
// one lightning arrester per phase (R, Y, B; pro tip 3), each with its
// disconnector at the bottom (point 3), the earth leads from the LAs' bottom
// terminals joined and run down the left pole to the earth rod in the ground
// (film: "বডি ও আর্থিং রড"), the transformer on its platform below, and on a
// tarp the kit: HT tester on a rod, the temporary earth set, the harness
// (in a dealt order — never laid out in the order of use).
// Static layers repaint only when their state changes (an idle screen draws
// zero frames); sparks and the deadly zap are one-shots.

/// Where the earth path can be looked at (and, later, mended).
enum M3LaEarthSpot { joint0, joint1, joint2, leadUpper, leadLower, rodClamp }

/// The bottom joint of LA [i].
M3LaEarthSpot m3LaEarthJoint(int i) => M3LaEarthSpot.values[i];

/// What is wrong with a spot.
enum M3LaEarthFault { loose, cut }

/// The kit on the tarp (laid out in a dealt order, never the order of use).
enum M3LaEarthKit { tester, earthSet, harness }

/// Where things stand (design px, 360 wide × the scene's height).
@immutable
class M3LaEarthGeo {
  const M3LaEarthGeo.forScene(this.height, double inset) : groundY = height - 250 - inset;

  final double height;

  /// Where the poles meet the ground.
  final double groundY;

  /// The HT crossarm (the line).
  double get topY => math.max(118.0, groundY - 440);
  double get span => groundY - topY;

  double get leftPoleX => 60;
  double get rightPoleX => 300;

  /// The three phases left to right (R, Y, B).
  double phaseX(int i) => 130.0 + 50 * i;
  double get doY => topY + 0.13 * span;
  double get laTop => topY + 0.30 * span;
  double get laBot => laTop + 56;

  Rect laBox(int i) => Rect.fromLTWH(phaseX(i) - 12, laTop, 24, laBot - laTop);
  Offset laBottomTerm(int i) => Offset(phaseX(i), laBot + 14);
  Rect doBox(int i) => Rect.fromCenter(center: Offset(phaseX(i), doY + 18), width: 26, height: 44);

  /// Where the three leads meet before running down the pole.
  Offset get junction => Offset(leftPoleX + 6, laBot + 40);

  Rect get tank => Rect.fromLTWH(132, laBot + 56, 96, math.max(56, 0.24 * span));
  double get platformY => tank.bottom + 4;

  Offset get leadUpper => Offset(leftPoleX + 6, junction.dy + (groundY - junction.dy) * 0.30);
  Offset get leadLower => Offset(leftPoleX + 6, junction.dy + (groundY - junction.dy) * 0.74);
  Offset get rodTop => Offset(30, groundY + 14);

  Offset spotAt(M3LaEarthSpot s) => switch (s) {
        M3LaEarthSpot.joint0 => laBottomTerm(0),
        M3LaEarthSpot.joint1 => laBottomTerm(1),
        M3LaEarthSpot.joint2 => laBottomTerm(2),
        M3LaEarthSpot.leadUpper => leadUpper,
        M3LaEarthSpot.leadLower => leadLower,
        M3LaEarthSpot.rodClamp => rodTop,
      };

  /// A thumb-sized tap area round a spot.
  Rect spotBox(M3LaEarthSpot s) => Rect.fromCenter(center: spotAt(s), width: 48, height: 48);

  // The kit on the tarp.
  Rect get tarp => Rect.fromLTWH(84, groundY + 76, 196, 78);

  /// Slot [k] (0 left … 2 right) on the tarp.
  Rect kitSlot(int k) => Rect.fromLTWH(tarp.left + const [6.0, 68.0, 132.0][k], tarp.top + 6, 60, 66);

  /// Where [item] lies in the dealt layout [order].
  Rect kitBox(M3LaEarthKit item, List<M3LaEarthKit> order) => kitSlot(order.indexOf(item));

  /// The trainee: on the ground, or up a pole with the harness on — the left
  /// pole for the R-phase LA ([left]), else the right one.
  Rect traineeBox({required bool up, bool left = false}) => !up
      ? Rect.fromLTWH(262, groundY - 96, 72, 150)
      : left
          ? Rect.fromLTWH(leftPoleX - 10, laTop - 6, 66, 132)
          : Rect.fromLTWH(rightPoleX - 52, laTop - 6, 66, 132);
  Offset hands({required bool up, bool left = false}) {
    final b = traineeBox(up: up, left: left);
    return left ? Offset(b.right - 10, b.top + 64) : Offset(b.left + 10, b.top + 64);
  }

  @override
  bool operator ==(Object other) => other is M3LaEarthGeo && other.height == height && other.groundY == groundY;

  @override
  int get hashCode => Object.hash(height, groundY);
}

void _text(Canvas canvas, String s, Offset centre, double size, Color color) {
  final tp = TextPainter(
    text: TextSpan(text: s, style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, color: color)),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(canvas, centre - Offset(tp.width / 2, tp.height / 2));
}

Paint _stroke(Color c, double w) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

// ============================================================================
// The yard (static)
// ============================================================================

class M3LaEarthYardPainter extends CustomPainter {
  const M3LaEarthYardPainter({required this.geo});
  final M3LaEarthGeo geo;

  @override
  void paint(Canvas canvas, Size size) {
    final g = geo;
    final w = size.width;
    // Sky: a heavy pre-monsoon afternoon.
    final sky = Rect.fromLTRB(0, 0, w, g.groundY);
    canvas.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5E7A97), Color(0xFF9DB5C6), Color(0xFFD8DCC8)],
        ).createShader(sky),
    );
    final cloud = Paint()..color = const Color(0x55E9EEF2);
    for (final c in [Offset(60, g.topY - 40), Offset(250, g.topY - 70), Offset(330, g.topY + 30)]) {
      canvas.drawOval(Rect.fromCenter(center: c, width: 120, height: 34), cloud);
      canvas.drawOval(Rect.fromCenter(center: c.translate(30, -12), width: 70, height: 30), cloud);
    }
    // Far tree line and village roofs (parallax layer, still).
    final far = Path()..moveTo(0, g.groundY - 40);
    for (var x = 0.0; x <= w; x += 30) {
      far.quadraticBezierTo(x + 15, g.groundY - 70 - (x % 90 == 0 ? 16 : 0), x + 30, g.groundY - 40);
    }
    far
      ..lineTo(w, g.groundY)
      ..lineTo(0, g.groundY)
      ..close();
    canvas.drawPath(far, Paint()..color = const Color(0xFF5F7F55));
    final roof = Paint()..color = const Color(0xFF8C5A3C);
    canvas.drawRect(Rect.fromLTWH(206, g.groundY - 34, 34, 22), Paint()..color = const Color(0xFFCFC2A3));
    canvas.drawPath(
        Path()
          ..moveTo(200, g.groundY - 34)
          ..lineTo(223, g.groundY - 50)
          ..lineTo(246, g.groundY - 34)
          ..close(),
        roof);
    // Ground: earth and grass, a road at the bottom.
    final ground = Rect.fromLTRB(0, g.groundY, w, size.height);
    canvas.drawRect(
      ground,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7E8F4E), Color(0xFF6C7B44), Color(0xFF5A5E3E)],
        ).createShader(ground),
    );
    canvas.drawRect(Rect.fromLTRB(0, g.groundY + 170, w, size.height), Paint()..color = const Color(0xFF55524E));
    final tuft = _stroke(const Color(0xFF4F6A33), 1.6);
    for (var i = 0; i < 26; i++) {
      final x = (i * 37) % 360.0;
      final y = g.groundY + 8 + (i * 23) % 150;
      canvas.drawLine(Offset(x, y), Offset(x - 3, y - 7), tuft);
      canvas.drawLine(Offset(x, y), Offset(x + 3, y - 6), tuft);
    }

    // The two poles (PSC, grey).
    for (final x in [g.leftPoleX, g.rightPoleX]) {
      final pole = Rect.fromLTRB(x - 7, g.topY - 30, x + 7, g.groundY + 6);
      canvas.drawRect(
        pole,
        Paint()..shader = const LinearGradient(colors: [Color(0xFF8E8E88), Color(0xFFC6C6BE), Color(0xFF7C7C76)]).createShader(pole),
      );
      canvas.drawOval(Rect.fromCenter(center: Offset(x, g.groundY + 6), width: 30, height: 8), Paint()..color = const Color(0x55000000));
    }
    // Crossarms (channel iron).
    final arm = Paint()..color = const Color(0xFF4A4F57);
    for (final y in [g.topY, g.doY, g.laTop + 6]) {
      canvas.drawRect(Rect.fromLTRB(g.leftPoleX - 10, y - 4, g.rightPoleX + 10, y + 4), arm);
    }
    // HT pin insulators and the three conductors (seen end-on, running away).
    for (var i = 0; i < 3; i++) {
      final x = g.phaseX(i);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x - 7, g.topY - 22, 14, 18), const Radius.circular(4)),
        Paint()..color = const Color(0xFFE9E4D6),
      );
      canvas.drawLine(Offset(x - 9, g.topY - 14), Offset(x + 9, g.topY - 14), _stroke(const Color(0xFFBDB6A4), 2));
      canvas.drawCircle(Offset(x, g.topY - 24), 4, Paint()..color = const Color(0xFF8B8F96));
      canvas.drawLine(Offset(x, g.topY - 24), Offset(x - 70, g.topY - 70), _stroke(const Color(0xFF6F757D), 2));
    }
    // The transformer and its platform.
    final p = Rect.fromLTRB(g.leftPoleX - 12, g.platformY, g.rightPoleX + 12, g.platformY + 8);
    canvas.drawRect(p, arm);
    final t = g.tank;
    canvas.drawRRect(RRect.fromRectAndRadius(t, const Radius.circular(6)),
        Paint()..shader = const LinearGradient(colors: [Color(0xFF59705E), Color(0xFF7F9A84), Color(0xFF4D6352)]).createShader(t));
    final fin = _stroke(const Color(0xFF465A4A), 3);
    for (var x = t.left + 10; x < t.right - 6; x += 10) {
      canvas.drawLine(Offset(x, t.top + 14), Offset(x, t.bottom - 8), fin);
    }
    // Conservator and the three HT bushings on the lid.
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(t.right - 30, t.top - 22, 40, 14), const Radius.circular(7)),
        Paint()..color = const Color(0xFF6A8370));
    for (var i = 0; i < 3; i++) {
      final x = g.phaseX(i);
      final b = Rect.fromLTWH(x - 5, t.top - 26, 10, 26);
      canvas.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(3)), Paint()..color = const Color(0xFFD9D1BC));
      // The jumper from the DO down past the LA to the bushing.
      canvas.drawLine(Offset(x + 8, g.doY + 40), Offset(x + 8, t.top - 26), _stroke(const Color(0xFF6F757D), 1.6));
      canvas.drawLine(Offset(x + 8, t.top - 26), Offset(x, t.top - 26), _stroke(const Color(0xFF6F757D), 1.6));
    }
    // Danger plate on the tank.
    final plate = Rect.fromCenter(center: t.center.translate(0, 6), width: 46, height: 16);
    canvas.drawRect(plate, Paint()..color = const Color(0xFFF2C21B));
    _text(canvas, '11 kV', plate.center, 9, const Color(0xFF1A1A1A));
    // The earth pit: a concrete ring round the rod.
    canvas.drawOval(Rect.fromCenter(center: g.rodTop.translate(0, 8), width: 40, height: 14), Paint()..color = const Color(0xFF9C9A92));
    canvas.drawOval(Rect.fromCenter(center: g.rodTop.translate(0, 8), width: 28, height: 8), Paint()..color = const Color(0xFF4A4436));
    // The tarp for the kit.
    canvas.drawRRect(RRect.fromRectAndRadius(g.tarp, const Radius.circular(8)), Paint()..color = const Color(0xFF2F5D8A));
    canvas.drawRRect(RRect.fromRectAndRadius(g.tarp, const Radius.circular(8)), _stroke(const Color(0xFF1F3F5E), 2));
  }

  @override
  bool shouldRepaint(M3LaEarthYardPainter old) => old.geo != geo;
}

// ============================================================================
// The gear (changes with the play)
// ============================================================================

class M3LaEarthGearPainter extends CustomPainter {
  const M3LaEarthGearPainter({
    required this.geo,
    required this.badLa,
    required this.laReplaced,
    required this.faults,
    required this.flagged,
    required this.mended,
    required this.doOpen,
    required this.proved,
    required this.earthed,
    required this.harnessOn,
    required this.kit,
  });

  final M3LaEarthGeo geo;

  /// The tarp's layout, left to right.
  final List<M3LaEarthKit> kit;

  /// The LA whose disconnector has gone (its lead hangs).
  final int badLa;
  final bool laReplaced;
  final Map<M3LaEarthSpot, M3LaEarthFault> faults;

  /// Faults the player has tagged (red tag).
  final Set<M3LaEarthSpot> flagged;

  /// Faults mended (a new clamp / lead piece).
  final Set<M3LaEarthSpot> mended;

  /// Shutdown taken: the three DO fuses hang open.
  final bool doOpen;

  /// The tester has proved the line dead (left hooked on phase B).
  final bool proved;

  /// The temporary earth set is on the three phases.
  final bool earthed;
  final bool harnessOn;

  @override
  void paint(Canvas canvas, Size size) {
    final g = geo;
    for (var i = 0; i < 3; i++) {
      _doFuse(canvas, g.doBox(i), open: doOpen);
    }
    _leads(canvas);
    for (var i = 0; i < 3; i++) {
      _la(canvas, i);
    }
    for (final s in flagged) {
      if (!mended.contains(s)) _tag(canvas, g.spotAt(s));
    }
    if (earthed) _earthSet(canvas);
    _kit(canvas);
  }

  void _doFuse(Canvas canvas, Rect b, {required bool open}) {
    // Porcelain body on the crossarm, the fuse tube between the contacts.
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(b.left - 2, b.top - 4, 8, b.height + 8), const Radius.circular(3)),
        Paint()..color = const Color(0xFFE6E0D0));
    final tube = _stroke(const Color(0xFF3B3B3B), 5);
    if (open) {
      // Dropped out: hanging from the bottom hinge.
      canvas.drawLine(Offset(b.left + 8, b.bottom), Offset(b.right + 4, b.bottom - 20), tube);
    } else {
      canvas.drawLine(Offset(b.left + 8, b.top + 2), Offset(b.left + 12, b.bottom - 2), tube);
    }
    canvas.drawCircle(Offset(b.left + 9, b.top + 2), 3, Paint()..color = const Color(0xFF9A9A9A));
    canvas.drawCircle(Offset(b.left + 12, b.bottom - 1), 3, Paint()..color = const Color(0xFF9A9A9A));
  }

  void _la(Canvas canvas, int i) {
    final g = geo;
    final b = g.laBox(i);
    final bad = i == badLa && !laReplaced;
    // Line terminal and its jumper to the phase.
    canvas.drawLine(Offset(b.center.dx, b.top), Offset(b.center.dx + 8, b.top - 10), _stroke(const Color(0xFF6F757D), 1.8));
    // Polymer housing: a stack of sheds.
    canvas.drawRect(Rect.fromLTWH(b.center.dx - 5, b.top, 10, b.height), Paint()..color = const Color(0xFF7A7F86));
    final shed = Paint()..color = laReplaced && i == badLa ? const Color(0xFF8E959E) : const Color(0xFF9AA0A8);
    for (var k = 0; k < 5; k++) {
      final y = b.top + 6 + k * 10.0;
      canvas.drawOval(Rect.fromCenter(center: Offset(b.center.dx, y), width: b.width, height: 7), shed);
      canvas.drawOval(Rect.fromCenter(center: Offset(b.center.dx, y), width: b.width, height: 7), _stroke(const Color(0xFF5E636A), 0.8));
    }
    // Disconnector: a small cylinder; burst and blackened on the bad one.
    final dc = Rect.fromLTWH(b.center.dx - 5, b.bottom, 10, 12);
    if (bad) {
      canvas.drawRect(Rect.fromLTWH(dc.left, dc.top, 10, 5), Paint()..color = const Color(0xFF2A2522));
      canvas.drawCircle(Offset(dc.center.dx, dc.top + 6), 7, Paint()
        ..color = const Color(0x55302A26)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      final bit = _stroke(const Color(0xFF2A2522), 1.6);
      canvas.drawLine(Offset(dc.left, dc.top + 5), Offset(dc.left - 4, dc.top + 9), bit);
      canvas.drawLine(Offset(dc.right, dc.top + 5), Offset(dc.right + 4, dc.top + 10), bit);
    } else {
      canvas.drawRRect(RRect.fromRectAndRadius(dc, const Radius.circular(2)), Paint()..color = const Color(0xFF3E4248));
    }
  }

  void _leads(Canvas canvas) {
    final g = geo;
    const copper = Color(0xFFB8733A);
    final lead = _stroke(const Color(0xFF2F3A2A), 3.2);
    final j = g.junction;
    // From each LA's bottom to the junction on the left pole.
    for (var i = 0; i < 3; i++) {
      final s = m3LaEarthJoint(i);
      final t = g.laBottomTerm(i);
      if (i == badLa && !laReplaced) {
        // The disconnector has thrown the lead off: it hangs loose.
        final hang = Path()
          ..moveTo(j.dx + 30 + 10 * i, j.dy - 4)
          ..quadraticBezierTo(t.dx - 6, j.dy + 30, t.dx + 4, j.dy + 54);
        canvas.drawPath(hang, lead);
        canvas.drawCircle(Offset(t.dx + 4, j.dy + 54), 2.4, Paint()..color = copper);
        continue;
      }
      final loose = faults[s] == M3LaEarthFault.loose && !mended.contains(s);
      final from = loose ? t.translate(9, 15) : t;
      final path = Path()
        ..moveTo(from.dx, from.dy)
        ..quadraticBezierTo(from.dx - 10, j.dy - 6, j.dx + 30 + 10 * i, j.dy - 4)
        ..lineTo(j.dx, j.dy);
      canvas.drawPath(path, lead);
      _joint(canvas, t, loose: loose, mended: mended.contains(s));
    }
    // Down the pole to the rod.
    final down = Path()..moveTo(j.dx, j.dy);
    for (final s in [M3LaEarthSpot.leadUpper, M3LaEarthSpot.leadLower]) {
      final p = g.spotAt(s);
      final cut = faults[s] == M3LaEarthFault.cut && !mended.contains(s);
      if (cut) {
        down.lineTo(p.dx, p.dy - 10);
        canvas.drawPath(down, lead);
        // Frayed strands at both ends of the cut, copper showing.
        final fray = _stroke(copper, 1.8);
        for (final dx in [-5.0, -2.0, 2.0, 5.0]) {
          canvas.drawLine(Offset(p.dx, p.dy - 10), Offset(p.dx + dx, p.dy - 2), fray);
          canvas.drawLine(Offset(p.dx, p.dy + 10), Offset(p.dx + dx * 0.8, p.dy + 3), fray);
        }
        down.reset();
        down.moveTo(p.dx, p.dy + 10);
      } else {
        down.lineTo(p.dx, p.dy);
        if (mended.contains(s)) {
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: p, width: 8, height: 14), const Radius.circular(2)),
              Paint()..color = const Color(0xFF3FAE4A));
        }
      }
      // Pole clamps holding the lead.
      canvas.drawLine(Offset(p.dx - 9, p.dy + 18), Offset(p.dx + 3, p.dy + 18), _stroke(const Color(0xFF5A5A5A), 2));
    }
    final r = g.rodTop;
    final rodLoose = faults[M3LaEarthSpot.rodClamp] == M3LaEarthFault.loose && !mended.contains(M3LaEarthSpot.rodClamp);
    down
      ..lineTo(g.leftPoleX + 6, g.groundY - 2)
      ..quadraticBezierTo(g.leftPoleX + 4, r.dy - 4, rodLoose ? r.dx + 12 : r.dx + 4, rodLoose ? r.dy - 8 : r.dy);
    canvas.drawPath(down, lead);
    // The rod's head above the pit.
    canvas.drawRect(Rect.fromLTWH(r.dx - 3, r.dy - 6, 6, 14), Paint()..color = const Color(0xFF8C6239));
    _joint(canvas, r, loose: rodLoose, mended: mended.contains(M3LaEarthSpot.rodClamp));
  }

  /// A bolted clamp; loose = the nut backed off and a gap.
  void _joint(Canvas canvas, Offset p, {required bool loose, required bool mended}) {
    final clamp = Paint()..color = mended ? const Color(0xFF3FAE4A) : const Color(0xFF7D838B);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: p, width: 10, height: 8), const Radius.circular(2)), clamp);
    if (loose) {
      canvas.save();
      canvas.translate(p.dx + 12, p.dy + 4);
      canvas.rotate(0.6);
      canvas.drawRect(const Rect.fromLTWH(-4, -4, 8, 8), Paint()..color = const Color(0xFFA0A6AE));
      canvas.drawRect(const Rect.fromLTWH(-4, -4, 8, 8), _stroke(const Color(0xFF4A4F57), 1));
      canvas.restore();
      final strand = _stroke(const Color(0xFFB8733A), 1.6);
      canvas.drawLine(p.translate(3, 6), p.translate(8, 14), strand);
      canvas.drawLine(p.translate(1, 6), p.translate(4, 15), strand);
    } else {
      canvas.drawCircle(p, 2, Paint()..color = const Color(0xFF4A4F57));
    }
  }

  /// The player's red tag on a fault.
  void _tag(Canvas canvas, Offset p) {
    final at = p.translate(14, -10);
    final tag = Path()
      ..moveTo(at.dx, at.dy)
      ..lineTo(at.dx + 8, at.dy - 6)
      ..lineTo(at.dx + 22, at.dy - 6)
      ..lineTo(at.dx + 22, at.dy + 6)
      ..lineTo(at.dx + 8, at.dy + 6)
      ..close();
    canvas.drawLine(p, at, _stroke(const Color(0xFF2B2B2B), 1));
    canvas.drawPath(tag, Paint()..color = const Color(0xFFD83A2C));
    canvas.drawPath(tag, _stroke(const Color(0xFF7A1A12), 1));
    canvas.drawCircle(at.translate(6, 0), 1.6, Paint()..color = Colors.white);
  }

  /// The temporary earth set: a clamp on each phase, leads down to a spike.
  void _earthSet(Canvas canvas) {
    final g = geo;
    final spike = Offset(g.rightPoleX + 26, g.groundY + 22);
    final lead = _stroke(const Color(0xFF2E7D32), 2);
    for (var i = 0; i < 3; i++) {
      final c = Offset(g.phaseX(i) + 4, g.topY - 22);
      canvas.drawRect(Rect.fromCenter(center: c, width: 8, height: 8), Paint()..color = const Color(0xFFC9A227));
      canvas.drawLine(c, Offset(g.rightPoleX + 14, g.topY - 6), lead);
    }
    canvas.drawLine(Offset(g.rightPoleX + 14, g.topY - 6), spike, lead);
    canvas.drawLine(spike, spike.translate(0, 14), _stroke(const Color(0xFF8C6239), 3));
  }

  void _kit(Canvas canvas) {
    final g = geo;
    if (!proved) _testerArt(canvas, g.kitBox(M3LaEarthKit.tester, kit));
    if (!earthed) _earthSetArt(canvas, g.kitBox(M3LaEarthKit.earthSet, kit));
    if (!harnessOn) _harnessArt(canvas, g.kitBox(M3LaEarthKit.harness, kit));
  }

  void _testerArt(Canvas canvas, Rect b) {
    // An HT voltage detector on a short insulated rod.
    canvas.drawLine(Offset(b.left + 6, b.bottom - 8), Offset(b.right - 14, b.top + 16), _stroke(const Color(0xFFE0B422), 5));
    canvas.drawLine(Offset(b.left + 6, b.bottom - 8), Offset(b.left + 22, b.bottom - 24), _stroke(const Color(0xFFC0392B), 6));
    final head = Rect.fromCenter(center: Offset(b.right - 10, b.top + 12), width: 16, height: 22);
    canvas.drawRRect(RRect.fromRectAndRadius(head, const Radius.circular(4)), Paint()..color = const Color(0xFF2B2B2B));
    canvas.drawCircle(head.center.translate(0, -4), 3, Paint()..color = const Color(0xFFE53935));
    canvas.drawCircle(head.center.translate(0, 4), 3, Paint()..color = const Color(0xFF43A047));
  }

  void _earthSetArt(Canvas canvas, Rect b) {
    final lead = _stroke(const Color(0xFF2E7D32), 2.2);
    for (var k = 0; k < 3; k++) {
      final c = Offset(b.left + 12 + 18.0 * k, b.top + 12);
      canvas.drawRect(Rect.fromCenter(center: c, width: 10, height: 10), Paint()..color = const Color(0xFFC9A227));
      canvas.drawLine(c.translate(0, 5), Offset(b.center.dx, b.bottom - 16), lead);
    }
    canvas.drawLine(Offset(b.center.dx, b.bottom - 16), Offset(b.center.dx + 14, b.bottom - 4), _stroke(const Color(0xFF8C6239), 4));
  }

  void _harnessArt(Canvas canvas, Rect b) {
    final belt = _stroke(const Color(0xFFEF6C00), 4);
    canvas.drawOval(Rect.fromLTWH(b.left + 8, b.top + 30, b.width - 16, 24), belt);
    canvas.drawLine(Offset(b.left + 16, b.top + 32), Offset(b.left + 22, b.top + 6), belt);
    canvas.drawLine(Offset(b.right - 16, b.top + 32), Offset(b.right - 22, b.top + 6), belt);
    canvas.drawCircle(Offset(b.center.dx, b.top + 54), 5, _stroke(const Color(0xFF9A9A9A), 2.4));
    // Helmet beside it.
    canvas.drawArc(Rect.fromLTWH(b.left + 18, b.top + 4, 26, 22), math.pi, math.pi, true, Paint()..color = const Color(0xFFFFD34E));
  }

  @override
  bool shouldRepaint(M3LaEarthGearPainter old) =>
      old.geo != geo ||
      old.badLa != badLa ||
      old.laReplaced != laReplaced ||
      old.doOpen != doOpen ||
      old.proved != proved ||
      old.earthed != earthed ||
      old.harnessOn != harnessOn ||
      old.flagged.length != flagged.length ||
      old.mended.length != mended.length ||
      !listEquals(old.kit, kit) ||
      !mapEquals(old.faults, faults);
}

// ============================================================================
// One-shots: spark, ping, the deadly zap
// ============================================================================

class M3LaEarthOneShot extends StatefulWidget {
  const M3LaEarthOneShot({super.key, required this.ms, required this.painter});
  final int ms;
  final CustomPainter Function(Animation<double> t) painter;

  @override
  State<M3LaEarthOneShot> createState() => _M3LaEarthOneShotState();
}

class _M3LaEarthOneShotState extends State<M3LaEarthOneShot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Duration(milliseconds: widget.ms))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(painter: widget.painter(_c));
}

/// A green ring where a right move landed.
class M3LaEarthOkPainter extends CustomPainter {
  M3LaEarthOkPainter(this.t) : super(repaint: t);
  final Animation<double> t;

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value;
    if (v >= 1) return;
    canvas.drawCircle(size.center(Offset.zero), 8 + 22 * v, Paint()
      ..color = Color.fromRGBO(76, 224, 122, 1 - v)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4);
  }

  @override
  bool shouldRepaint(M3LaEarthOkPainter old) => false;
}

/// A red ring where a wrong move landed.
class M3LaEarthPingPainter extends CustomPainter {
  M3LaEarthPingPainter(this.t) : super(repaint: t);
  final Animation<double> t;

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value;
    if (v >= 1) return;
    canvas.drawCircle(size.center(Offset.zero), 10 + 26 * v, Paint()
      ..color = Color.fromRGBO(192, 57, 43, 1 - v)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4);
  }

  @override
  bool shouldRepaint(M3LaEarthPingPainter old) => false;
}

/// The deadly moment in colour: 11 kV jumps from the live LA's terminal
/// along [path] through the trainee to the pole; the body glows red.
class M3LaEarthZapPainter extends CustomPainter {
  M3LaEarthZapPainter(this.t, {required this.path, required this.figure}) : super(repaint: t);
  final Animation<double> t;
  final List<Offset> path;
  final Rect figure;

  @override
  void paint(Canvas canvas, Size size) {
    final v = t.value;
    final flash = (v < 0.2 ? v / 0.2 : (1 - (v - 0.2) / 0.8)).clamp(0.0, 1.0);
    canvas.drawRect(Offset.zero & size, Paint()..color = Color.fromRGBO(255, 240, 230, 0.4 * flash));
    canvas.drawOval(figure.inflate(8), Paint()
      ..color = const Color(0x99FF3B2F)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    final rnd = math.Random(v >= 1 ? 7 : (v * 14).floor());
    final arc = Path()..moveTo(path.first.dx, path.first.dy);
    for (var i = 1; i < path.length; i++) {
      final a = path[i - 1];
      final b = path[i];
      for (var j = 1; j <= 5; j++) {
        final p = Offset.lerp(a, b, j / 5)!;
        final jitter = j == 5 ? 0.0 : (rnd.nextDouble() - 0.5) * 14;
        arc.lineTo(p.dx + jitter, p.dy + jitter * 0.3);
      }
    }
    canvas.drawPath(arc, Paint()
      ..color = const Color(0xAA8FD3FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    canvas.drawPath(arc, Paint()
      ..color = const Color(0xFFFFF7D6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeJoin = StrokeJoin.round);
    final ray = Paint()
      ..color = const Color(0xFFFFD21F)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final o = path.first;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + v * 2;
      final d = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(o + d * 6, o + d * (14 + 6 * flash), ray);
    }
  }

  @override
  bool shouldRepaint(M3LaEarthZapPainter old) => false;
}
