import 'dart:math' as math;

import 'package:flutter/material.dart';

// The place for lesson 4.2 কাজ 1 "জাম্পার বানাও" (m4_jumper_make.dart): the
// top of an 11 kV dead-end pole seen from the side of the line — a morning
// sky, far trees and fields, the PCC pole with its steel cross-arm (end on),
// a strain insulator string out to each side, each holding a conductor in its
// strain clamp (the span runs off to the left and to the right), the two
// conductor tails hanging from the clamps, and between them the gap the
// jumper bridges (lesson point 1: the strain string stops the current; the
// jumper carries it across). The line is dead: shutdown, PTW and the earth set
// clamped on both spans with its leads down to the spike. The trainee is up
// the pole in helmet and harness, his pole strap round the pole.
//
// Also here: the close looks the page puts in its panels — a joint (the
// conductor tail and the jumper's end side by side, dirty → brushed → paste →
// the connector → tightened with two spanners; a stray strand), the coil rack
// (jumper pieces of different sizes, the cut end showing its strands), the
// cross-sections side by side, the connector chips and the jumper's shape.
// No text in the art (labels a worker reads are widgets).
//
// Design: 360 wide × the scene's height; the ground follows the bottom of the
// screen (a tall phone gets more sky). Static painters: they repaint when the
// play changes, never on a clock.

/// What joins the jumper to a conductor tail (lesson point 2, pro tip 3).
enum M4JumperMakeConn { pgAl, pgCu, bimetal, twist }

/// How the jumper is bent once both ends are on (lesson point 2, step 4).
enum M4JumperMakeShape { tight, smooth, long }

const _al0 = Color(0xFFE3E7EA);
const _al1 = Color(0xFF8C949B);
const _cu0 = Color(0xFFE6A06A);
const _cu1 = Color(0xFF8E4F23);
const _oxide = Color(0xFF7F8A80);
const _speck = Color(0xFF46524A);

/// Where things are (design px, 360 wide).
@immutable
class M4JumperMakeGeo {
  const M4JumperMakeGeo({required this.height, required this.groundY, required this.armY});

  factory M4JumperMakeGeo.forScene(double h, double inset) =>
      M4JumperMakeGeo(height: h, groundY: h - 46 - inset, armY: (h * 0.30).clamp(176.0, 270.0));

  /// The pole's axis.
  static const px = 180.0;

  final double height;
  final double groundY;
  final double armY;

  /// The strain strings' axis.
  double get lineY => armY + 8;
  double get horizonY => armY + (groundY - armY) * 0.30;

  /// The strain clamps (left, right).
  Offset get clampL => Offset(px - 84, lineY);
  Offset get clampR => Offset(px + 84, lineY);

  /// Where the jumper meets each tail (the joints).
  Offset get jointL => Offset(px - 100, lineY + 40);
  Offset get jointR => Offset(px + 100, lineY + 40);

  /// The jumper's sag below the joints for a shape (null: hung on, not yet bent).
  static double sagOf(M4JumperMakeShape? s) => switch (s) {
        null => 78,
        M4JumperMakeShape.tight => 0,
        M4JumperMakeShape.smooth => 50,
        M4JumperMakeShape.long => 138,
      };

  /// Where a too-long jumper swings into the pole (the spark).
  Offset get touch => Offset(px - 9, lineY + 40 + sagOf(M4JumperMakeShape.long) * 0.74);

  /// The trainee's figure (on his step, left of the pole, under the jumper).
  static const figH = 100.0;
  static const figW = 50.0;
  Rect get traineeBox => Rect.fromLTWH(px - 56, lineY + 96, figW, figH);

  @override
  bool operator ==(Object other) => other is M4JumperMakeGeo && other.height == height && other.groundY == groundY && other.armY == armY;

  @override
  int get hashCode => Object.hash(height, groundY, armY);
}

/// What the scene shows of the job.
@immutable
class M4JumperMakeRig {
  const M4JumperMakeRig({this.copperRight = false, this.leftOn = false, this.rightOn = false, this.shape});

  /// The right span is an old copper conductor (the joint there needs a
  /// bi-metallic connector, pro tip 3).
  final bool copperRight;

  /// The jumper's end is clamped on the left tail / the right tail.
  final bool leftOn;
  final bool rightOn;

  /// The bend (null: hung on, not yet shaped).
  final M4JumperMakeShape? shape;

  @override
  bool operator ==(Object other) =>
      other is M4JumperMakeRig && other.copperRight == copperRight && other.leftOn == leftOn && other.rightOn == rightOn && other.shape == shape;

  @override
  int get hashCode => Object.hash(copperRight, leftOn, rightOn, shape);
}

Paint _metal(Rect r, Color a, Color b) => Paint()
  ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [a, b]).createShader(r);

/// The place: sky, land, the pole, its arm and strings, the spans, the tails
/// and the earth set. The jumper is [M4JumperMakeJumperPainter] (it can sway).
class M4JumperMakeWorldPainter extends CustomPainter {
  const M4JumperMakeWorldPainter({required this.geo, required this.rig});
  final M4JumperMakeGeo geo;
  final M4JumperMakeRig rig;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final hz = geo.horizonY;
    final g = geo.groundY;

    // --- sky -------------------------------------------------------------------
    final sky = Rect.fromLTWH(0, 0, w, hz + 6);
    c.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4F8FCB), Color(0xFF9CC5E6), Color(0xFFF1E7CB)],
          stops: [0, 0.62, 1],
        ).createShader(sky),
    );
    final sun = Offset(w * 0.82, hz * 0.24);
    c.drawCircle(
        sun,
        110,
        Paint()
          ..shader = const RadialGradient(colors: [Color(0x80FFF4D2), Color(0x00FFF4D2)]).createShader(Rect.fromCircle(center: sun, radius: 110)));
    c.drawCircle(sun, 15, Paint()..color = const Color(0xFFFFF6DC));
    final cloud = Paint()..color = const Color(0xCCFFFFFF);
    for (final (x, y, r) in [(60.0, hz * 0.30, 18.0), (250.0, hz * 0.12, 14.0), (300.0, hz * 0.55, 12.0), (110.0, hz * 0.70, 10.0)]) {
      c.drawCircle(Offset(x, y), r, cloud);
      c.drawCircle(Offset(x + r, y + 4), r * 0.8, cloud);
      c.drawCircle(Offset(x - r, y + 5), r * 0.7, cloud);
    }

    // --- far land --------------------------------------------------------------
    final tree = Path()..moveTo(0, hz);
    for (var x = 0.0; x <= w + 16; x += 16) {
      final bump = 12 + 8 * math.sin(x * 0.05) + 5 * math.sin(x * 0.19 + 0.7);
      tree.quadraticBezierTo(x + 8, hz - bump - 9, x + 16, hz - bump * 0.6);
    }
    tree
      ..lineTo(w, hz + 4)
      ..lineTo(0, hz + 4)
      ..close();
    c.drawPath(tree, Paint()..color = const Color(0xFF4F7A55));
    for (final (x, sz) in const [(40.0, 1.0), (72.0, 0.8), (286.0, 0.9)]) {
      final b = Rect.fromLTWH(x, hz - 12 * sz, 24 * sz, 12 * sz);
      c.drawRect(b, Paint()..color = const Color(0xFFB59A74));
      c.drawPath(
          Path()
            ..moveTo(x - 3 * sz, hz - 11 * sz)
            ..lineTo(x + 12 * sz, hz - 20 * sz)
            ..lineTo(x + 27 * sz, hz - 11 * sz)
            ..close(),
          Paint()..color = const Color(0xFF8E979E));
    }
    final field = Rect.fromLTRB(0, hz, w, g + 10);
    c.drawRect(
      field,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8DB860), Color(0xFF6E9E45)],
        ).createShader(field),
    );
    final row = Paint()
      ..color = const Color(0x335A7F2E)
      ..strokeWidth = 1.2;
    for (var i = 1; i < 8; i++) {
      final y = hz + (g - hz) * (i / 8) * (i / 8) * 0.95;
      c.drawLine(Offset(0, y), Offset(w, y), row);
    }
    // The verge and the road at the foot of the pole.
    final verge = Rect.fromLTRB(0, g - 18, w, g + 20);
    c.drawRect(verge, _metal(verge, const Color(0xFF5E8E3A), const Color(0xFF7A6A48)));
    final road = Rect.fromLTRB(0, g + 20, w, size.height);
    c.drawRect(road, _metal(road, const Color(0xFF8A7B62), const Color(0xFF6E624E)));
    for (final x in const [96.0, 270.0]) {
      final base = Offset(x, g + 34);
      c.drawPath(
          Path()
            ..moveTo(base.dx - 9, base.dy)
            ..lineTo(base.dx - 2, base.dy - 24)
            ..lineTo(base.dx + 2, base.dy - 24)
            ..lineTo(base.dx + 9, base.dy)
            ..close(),
          Paint()..color = const Color(0xFFF07C1E));
      c.drawRect(Rect.fromLTWH(base.dx - 6, base.dy - 14, 12, 4), Paint()..color = const Color(0xFFF5F5F0));
      c.drawRect(Rect.fromLTWH(base.dx - 12, base.dy - 1, 24, 3), Paint()..color = const Color(0xFF3A3A3A));
    }

    _pole(c);
    _spans(c);
    _earth(c);
  }

  void _pole(Canvas c) {
    const px = M4JumperMakeGeo.px;
    final g = geo.groundY;
    final top = geo.armY - 26;
    const half0 = 15.0;
    const half1 = 9.0;
    final body = Path()
      ..moveTo(px - half0, g + 6)
      ..lineTo(px - half1, top)
      ..lineTo(px + half1, top)
      ..lineTo(px + half0, g + 6)
      ..close();
    c.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFF9C988E), Color(0xFFCBC7BC), Color(0xFF8E8A80)], stops: [0, 0.45, 1])
            .createShader(Rect.fromLTRB(px - half0, top, px + half0, g)),
    );
    c.drawRect(Rect.fromLTRB(px - half1 - 1, top - 3, px + half1 + 1, top + 2), Paint()..color = const Color(0xFF8E8A80));
    // Step bolts.
    final bolt = Paint()..color = const Color(0xFF6B7076);
    var left = true;
    for (var y = g - 60; y > geo.armY + 40; y -= 40) {
      final k = (y - top) / (g - top);
      final half = half1 + (half0 - half1) * k;
      c.drawRect(Rect.fromLTWH(left ? px - half - 9 : px + half, y, 10, 2.8), bolt);
      left = !left;
    }
    // The danger plate.
    final dy = geo.lineY + 230;
    if (dy < g - 40) {
      c.drawRect(Rect.fromLTWH(px - 9, dy, 18, 14), Paint()..color = const Color(0xFFF2EFE4));
      c.drawRect(Rect.fromLTWH(px - 7, dy + 2, 14, 3), Paint()..color = const Color(0xFFC0392B));
    }
    // The cross-arm, end on (a steel channel in its pole clamp), and the
    // strain plates out to each side.
    final arm = Rect.fromCenter(center: Offset(px, geo.armY), width: 30, height: 16);
    c.drawRect(arm, _metal(arm, const Color(0xFF8C949A), const Color(0xFF575E64)));
    c.drawRect(arm.deflate(4), Paint()..color = const Color(0xFF3F454A));
    for (final dx in const [-11.0, 11.0]) {
      c.drawCircle(Offset(px + dx, geo.armY + 10), 2, Paint()..color = const Color(0xFFB8BEC4));
    }
    final plate = Paint()
      ..color = const Color(0xFF5A6066)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(px - 14, geo.armY + 4), Offset(px - 22, geo.lineY), plate);
    c.drawLine(Offset(px + 14, geo.armY + 4), Offset(px + 22, geo.lineY), plate);
  }

  void _string(Canvas c, double from, double to) {
    final y = geo.lineY;
    final disc = Paint()..color = const Color(0xFF7B4526);
    final shine = Paint()..color = const Color(0xFFA8714A);
    final rod = Paint()
      ..color = const Color(0xFF5A6066)
      ..strokeWidth = 1.6;
    c.drawLine(Offset(from, y), Offset(to, y), rod);
    const n = 4;
    for (var i = 0; i < n; i++) {
      final x = from + (to - from) * (i + 0.8) / (n + 0.6);
      c.drawOval(Rect.fromCenter(center: Offset(x, y), width: 6, height: 17), disc);
      c.drawOval(Rect.fromCenter(center: Offset(x + 1, y - 3), width: 1.8, height: 7), shine);
    }
  }

  void _spans(Canvas c) {
    const px = M4JumperMakeGeo.px;
    final y = geo.lineY;
    _string(c, px - 22, geo.clampL.dx + 6);
    _string(c, px + 22, geo.clampR.dx - 6);
    Paint wire(bool cu) => Paint()
      ..color = cu ? const Color(0xFFA9612E) : const Color(0xFF5E666D)
      ..strokeWidth = 3.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final left = wire(false);
    final right = wire(rig.copperRight);
    // The spans out to the next poles.
    c.drawPath(Path()
      ..moveTo(geo.clampL.dx, y)
      ..quadraticBezierTo(geo.clampL.dx - 50, y + 10, -10, y + 4), left);
    c.drawPath(Path()
      ..moveTo(geo.clampR.dx, y)
      ..quadraticBezierTo(geo.clampR.dx + 50, y + 10, 370, y + 4), right);
    // The tails from the strain clamps down to the joints.
    for (final (clamp, joint, p) in [(geo.clampL, geo.jointL, left), (geo.clampR, geo.jointR, right)]) {
      final out = (joint.dx - clamp.dx).sign;
      c.drawPath(
          Path()
            ..moveTo(clamp.dx, clamp.dy)
            ..cubicTo(clamp.dx + out * 14, clamp.dy + 2, joint.dx, joint.dy - 22, joint.dx, joint.dy + 6),
          p);
      final body = Rect.fromCenter(center: clamp, width: 16, height: 9);
      c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(3)), _metal(body, const Color(0xFFB9C0C6), const Color(0xFF6E767D)));
      for (final dx in const [-4.0, 4.0]) {
        c.drawCircle(clamp.translate(dx, 0), 1.4, Paint()..color = const Color(0xFF3C4248));
      }
    }
  }

  void _earth(Canvas c) {
    // An earth clamp on each span; the braided leads run down to the spike.
    // The leads meet on the pole's far side and run down it to the spike.
    const px = M4JumperMakeGeo.px;
    final spike = Offset(px + 30, geo.groundY + 14);
    final join = Offset(px + 12, geo.lineY + 58);
    final lead = Paint()
      ..color = const Color(0xFFB87333)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    c.drawPath(
        Path()
          ..moveTo(join.dx, join.dy)
          ..lineTo(px + 14, spike.dy - 40)
          ..quadraticBezierTo(px + 16, spike.dy - 14, spike.dx, spike.dy - 10),
        lead);
    for (final at in [Offset(geo.clampL.dx - 36, geo.lineY + 6), Offset(geo.clampR.dx + 36, geo.lineY + 6)]) {
      c.drawPath(
          Path()
            ..moveTo(at.dx, at.dy + 4)
            ..quadraticBezierTo(at.dx + (join.dx - at.dx) * 0.2, join.dy + 26, join.dx, join.dy),
          lead);
      final jaw = Rect.fromCenter(center: at, width: 11, height: 10);
      c.drawRRect(RRect.fromRectAndRadius(jaw, const Radius.circular(2)), Paint()..color = const Color(0xFF2E9A44));
      c.drawRect(Rect.fromCenter(center: at.translate(0, 1), width: 11, height: 2.4), Paint()..color = const Color(0xFFF4D03F));
    }
    c.drawRect(Rect.fromLTWH(spike.dx - 1.5, spike.dy - 12, 3, 18), Paint()..color = const Color(0xFF6B7076));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: spike.translate(0, -10), width: 10, height: 7), const Radius.circular(2)),
        Paint()..color = const Color(0xFF2E9A44));
  }

  @override
  bool shouldRepaint(M4JumperMakeWorldPainter old) => old.geo != geo || old.rig != rig;
}

/// The jumper itself: its ends on the tails (or one end on, the other
/// hanging), bent to [M4JumperMakeRig.shape]. [sway] (−1…1) swings its
/// belly sideways (the wind, on a wrong bend); [spark] marks where it touches.
class M4JumperMakeJumperPainter extends CustomPainter {
  M4JumperMakeJumperPainter({required this.geo, required this.rig, required this.sway, this.spark = false}) : super(repaint: sway);
  final M4JumperMakeGeo geo;
  final M4JumperMakeRig rig;
  final Animation<double> sway;
  final bool spark;

  static Path pathFor(Offset a, Offset b, double sag, {double swing = 0}) {
    if (sag <= 0.5) {
      return Path()
        ..moveTo(a.dx, a.dy)
        ..lineTo(b.dx, b.dy);
    }
    final k = sag * 1.33;
    return Path()
      ..moveTo(a.dx, a.dy)
      ..cubicTo(a.dx + swing * 0.4, a.dy + k, b.dx + swing * 0.4, b.dy + k, b.dx, b.dy);
  }

  @override
  void paint(Canvas c, Size size) {
    if (!rig.leftOn) return;
    final wire = Paint()
      ..color = const Color(0xFF6A7279)
      ..strokeWidth = 3.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final shine = Paint()
      ..color = const Color(0x99E3E7EA)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final a = geo.jointL;
    final Path p;
    if (!rig.rightOn) {
      // One end on: the rest hangs down from the left joint.
      p = Path()
        ..moveTo(a.dx, a.dy)
        ..cubicTo(a.dx + 4, a.dy + 40, a.dx + 30, a.dy + 70, a.dx + 34, a.dy + 104);
    } else {
      final swing = sway.value * 70;
      p = pathFor(a, geo.jointR, M4JumperMakeGeo.sagOf(rig.shape), swing: swing);
    }
    c.drawPath(p, wire);
    c.drawPath(p.shift(const Offset(-0.8, -0.8)), shine);
    for (final (at, on) in [(a, true), (geo.jointR, rig.rightOn)]) {
      if (!on) continue;
      final body = Rect.fromCenter(center: at.translate(0, -2), width: 13, height: 16);
      c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(2.5)), _metal(body, const Color(0xFFCDD3D8), const Color(0xFF7B838A)));
      c.drawCircle(at.translate(0, -6), 1.8, Paint()..color = const Color(0xFF3C4248));
      c.drawCircle(at.translate(0, 2), 1.8, Paint()..color = const Color(0xFF3C4248));
    }
    if (spark) {
      final s = geo.touch;
      final ray = Paint()
        ..color = const Color(0xFFFFF3A0)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 8; i++) {
        final ang = i * math.pi / 4 + 0.3;
        c.drawLine(s + Offset(math.cos(ang), math.sin(ang)) * 5, s + Offset(math.cos(ang), math.sin(ang)) * (i.isEven ? 16 : 10), ray);
      }
      c.drawCircle(s, 6, Paint()..color = const Color(0xFFFFFFFF));
      c.drawCircle(s, 10, Paint()..color = const Color(0x66FFD54F));
    }
  }

  @override
  bool shouldRepaint(M4JumperMakeJumperPainter old) => old.geo != geo || old.rig != rig || old.spark != spark;
}

/// The trainee's pole strap (harness lanyard round the pole) and his step.
class M4JumperMakeStrapPainter extends CustomPainter {
  const M4JumperMakeStrapPainter({required this.box});
  final Rect box;

  @override
  void paint(Canvas c, Size size) {
    const px = M4JumperMakeGeo.px;
    final hip = Offset(box.left + box.width * 0.5, box.top + box.height * 0.5);
    final strap = Paint()
      ..color = const Color(0xFF3A2A16)
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke;
    c.drawRect(Rect.fromLTRB(box.left + box.width * 0.3, box.bottom - 3, px, box.bottom + 0.6), Paint()..color = const Color(0xFF5A6066));
    c.drawPath(
        Path()
          ..moveTo(hip.dx, hip.dy)
          ..quadraticBezierTo(px, hip.dy - 12, px + 13, hip.dy - 6)
          ..moveTo(hip.dx, hip.dy + 2)
          ..quadraticBezierTo(px, hip.dy + 5, px + 13, hip.dy - 6),
        strap);
  }

  @override
  bool shouldRepaint(M4JumperMakeStrapPainter old) => old.box != box;
}

// ============================================================================
// Close looks (the panels)
// ============================================================================

void _strands(Canvas c, Offset o, double r, {required bool steelCore, bool copper = false}) {
  // The cut end: a ring of strands round a core (steel for ACSR).
  c.drawCircle(o, r, Paint()..color = copper ? _cu1 : _al1);
  final s = r / 2.5;
  void strand(Offset at, bool steel) {
    final rr = Rect.fromCircle(center: at, radius: s * 0.96);
    c.drawCircle(
        at,
        s * 0.96,
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(-0.3, -0.4),
            colors: steel ? const [Color(0xFF9AA3AB), Color(0xFF4C545B)] : (copper ? const [_cu0, _cu1] : const [_al0, _al1]),
          ).createShader(rr));
  }

  strand(o, steelCore);
  for (var i = 0; i < 6; i++) {
    final a = i * math.pi / 3;
    strand(o + Offset(math.cos(a), math.sin(a)) * (2 * s), steelCore);
  }
  for (var i = 0; i < 12; i++) {
    final a = i * math.pi / 6 + math.pi / 12;
    strand(o + Offset(math.cos(a), math.sin(a)) * (r - s * 0.98), false);
  }
  c.drawCircle(
      o,
      r,
      Paint()
        ..color = const Color(0x55000000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, r * 0.04));
}

/// Two cut ends side by side at one scale: the line's conductor (left) and
/// the jumper piece being looked at (right). [piece] is the piece's size
/// relative to the line's conductor (1 = the same).
class M4JumperMakeCrossPainter extends CustomPainter {
  const M4JumperMakeCrossPainter({required this.piece, required this.steelCore});
  final double piece;
  final bool steelCore;

  /// The biggest piece dealt (sets the scale).
  static const maxPiece = 1.3;

  @override
  void paint(Canvas c, Size size) {
    final r = math.min(size.width / 4.6, size.height / 2.4) / maxPiece;
    final y = size.height / 2;
    _strands(c, Offset(size.width * 0.27, y), r, steelCore: steelCore);
    _strands(c, Offset(size.width * 0.73, y), r * piece, steelCore: steelCore);
  }

  @override
  bool shouldRepaint(M4JumperMakeCrossPainter old) => old.piece != piece || old.steelCore != steelCore;
}

/// A jumper piece on the rack: a coil of conductor, its cut end out front.
class M4JumperMakeCoilPainter extends CustomPainter {
  const M4JumperMakeCoilPainter({required this.piece, required this.steelCore});
  final double piece;
  final bool steelCore;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    final o = Offset(w * 0.5, h * 0.46);
    final t = 3.2 * piece + 0.6;
    final ring = Paint()
      ..color = _al1
      ..style = PaintingStyle.stroke
      ..strokeWidth = t;
    final lit = Paint()
      ..color = _al0
      ..style = PaintingStyle.stroke
      ..strokeWidth = t * 0.4;
    for (var i = 0; i < 4; i++) {
      final rect = Rect.fromCenter(center: o.translate(i * 2.0 - 3, i * 1.0), width: w * 0.66, height: h * 0.56);
      c.drawOval(rect, ring);
      c.drawArc(rect.shift(Offset(-t * 0.2, -t * 0.25)), math.pi * 1.05, math.pi * 0.7, false, lit);
    }
    // The tie on the coil.
    c.drawLine(o.translate(-w * 0.33, -2), o.translate(-w * 0.28, 8), Paint()
      ..color = const Color(0xFFB03A2E)
      ..strokeWidth = 2.4);
    // The cut end, sticking out of the coil towards the viewer.
    final end = Offset(w * 0.78, h * 0.78);
    c.drawLine(o.translate(w * 0.24, h * 0.16), end, ring);
    _strands(c, end, t * 1.25, steelCore: steelCore);
  }

  @override
  bool shouldRepaint(M4JumperMakeCoilPainter old) => old.piece != piece || old.steelCore != steelCore;
}

/// A connector on the tray (or in the joint).
class M4JumperMakeConnPainter extends CustomPainter {
  const M4JumperMakeConnPainter({required this.conn});
  final M4JumperMakeConn conn;

  @override
  void paint(Canvas c, Size size) {
    final r = Rect.fromCenter(center: size.center(Offset.zero), width: size.width * 0.86, height: size.height * 0.78);
    _connector(c, r, conn, tight: 1, nutTurn: 0);
  }

  @override
  bool shouldRepaint(M4JumperMakeConnPainter old) => old.conn != conn;
}

void _connector(Canvas c, Rect r, M4JumperMakeConn conn, {required double tight, required double nutTurn}) {
  if (conn == M4JumperMakeConn.twist) {
    // A hank of binding wire twisted round (no connector at all).
    final p = Paint()
      ..color = const Color(0xFF9AA0A6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, r.height * 0.06);
    for (var i = 0; i < 6; i++) {
      final x = r.left + r.width * (0.12 + i * 0.15);
      c.drawLine(Offset(x, r.top + r.height * 0.1), Offset(x + r.width * 0.12, r.bottom - r.height * 0.1), p);
    }
    c.drawPath(
        Path()
          ..moveTo(r.right - r.width * 0.06, r.bottom - r.height * 0.1)
          ..quadraticBezierTo(r.right + r.width * 0.06, r.center.dy, r.right - r.width * 0.02, r.top),
        p);
    return;
  }
  final gap = r.height * 0.08 * (1 - tight);
  final top = Rect.fromLTRB(r.left, r.top, r.right, r.center.dy - gap / 2);
  final bottom = Rect.fromLTRB(r.left, r.center.dy + gap / 2, r.right, r.bottom);
  // The top groove holds the tail (copper on the old span), the bottom the
  // aluminium jumper: a bi-metallic clamp is copper on top, aluminium below.
  final (Color a0, Color a1) = conn == M4JumperMakeConn.pgAl ? (const Color(0xFFD9DEE2), const Color(0xFF7D858C)) : (_cu0, _cu1);
  final (Color b0, Color b1) = conn == M4JumperMakeConn.pgCu ? (_cu0, _cu1) : (const Color(0xFFD9DEE2), const Color(0xFF7D858C));
  final rad = Radius.circular(r.height * 0.14);
  c.drawRRect(RRect.fromRectAndRadius(top, rad), _metal(top, a0, a1));
  c.drawRRect(RRect.fromRectAndRadius(bottom, rad), _metal(bottom, b0, b1));
  // The two grooves (one per conductor).
  final groove = Paint()
    ..color = const Color(0x55000000)
    ..strokeWidth = math.max(1, r.height * 0.05);
  c.drawLine(Offset(r.left + 2, r.top + r.height * 0.3), Offset(r.right - 2, r.top + r.height * 0.3), groove);
  c.drawLine(Offset(r.left + 2, r.bottom - r.height * 0.3), Offset(r.right - 2, r.bottom - r.height * 0.3), groove);
  if (conn == M4JumperMakeConn.bimetal) {
    // The bi-metallic liner's seam.
    c.drawLine(Offset(r.left + 2, r.center.dy), Offset(r.right - 2, r.center.dy), Paint()
      ..color = const Color(0xFF3C4248)
      ..strokeWidth = math.max(1, r.height * 0.04));
  }
  // Two bolts: the head on the face, the nut turned by [nutTurn].
  for (final fx in const [0.3, 0.7]) {
    final o = Offset(r.left + r.width * fx, r.center.dy);
    final s = r.height * 0.2;
    final hex = Path();
    for (var i = 0; i < 6; i++) {
      final a = nutTurn + i * math.pi / 3;
      final p = o + Offset(math.cos(a), math.sin(a)) * s;
      if (i == 0) {
        hex.moveTo(p.dx, p.dy);
      } else {
        hex.lineTo(p.dx, p.dy);
      }
    }
    hex.close();
    c.drawPath(hex, Paint()..color = const Color(0xFF59616A));
    c.drawCircle(o, s * 0.45, Paint()..color = const Color(0xFFB8BEC4));
  }
}

/// A joint close up (the lens): the conductor tail along the top, the
/// jumper's end along the bottom, side by side where the connector goes.
@immutable
class M4JumperMakeJointView {
  const M4JumperMakeJointView({
    this.copper = false,
    this.brushed = 0,
    this.pasted = false,
    this.conn,
    this.tight = 0,
    this.wrenches = 0,
    this.stray = false,
  });

  /// The tail is copper (the old copper span).
  final bool copper;

  /// 0 dirty → 1 clean.
  final double brushed;
  final bool pasted;
  final M4JumperMakeConn? conn;

  /// 0 just put on → 1 tight.
  final double tight;

  /// Spanners on it while tightening (0, 1 or 2).
  final int wrenches;

  /// A strand of the jumper's cut end sticks out (a sharp edge).
  final bool stray;
}

class M4JumperMakeJointPainter extends CustomPainter {
  M4JumperMakeJointPainter({required this.view, this.brushing, this.turning}) : super(repaint: Listenable.merge([?brushing, ?turning]));
  final M4JumperMakeJointView view;

  /// While brushing: the stroke (0…1, the brush moves back and forth).
  final Animation<double>? brushing;

  /// While tightening: 0…1 of the hold (the nuts turn, the plates close).
  final Animation<double>? turning;

  /// Where the stray strand's tip is (its tap area, in the panel's pixels).
  static Rect strandArea(Size s) => Rect.fromCenter(center: Offset(s.width * 0.13, s.height * 0.86), width: 48, height: 40);

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final h = s.height;
    final bg = Offset.zero & s;
    c.drawRRect(RRect.fromRectAndRadius(bg, const Radius.circular(12)), _metal(bg, const Color(0xFFBFD8EC), const Color(0xFFEDE6D2)));
    final th = h * 0.15;
    final topY = h * 0.36;
    final botY = h * 0.64;
    final zone = Rect.fromLTRB(w * 0.24, topY - th, w * 0.80, botY + th);

    void conductor(double y, double x0, double x1, bool cu) {
      final r = Rect.fromLTRB(math.min(x0, x1), y - th / 2, math.max(x0, x1), y + th / 2);
      c.drawRRect(RRect.fromRectAndRadius(r, Radius.circular(th * 0.3)), _metal(r, cu ? _cu0 : _al0, cu ? _cu1 : _al1));
      // The lay of the strands.
      final lay = Paint()
        ..color = const Color(0x40000000)
        ..strokeWidth = 1;
      for (var x = r.left + 3; x < r.right - 2; x += th * 0.55) {
        c.drawLine(Offset(x, r.top + 1), Offset(x + th * 0.4, r.bottom - 1), lay);
      }
      // The cut end.
      final ex = x1;
      c.drawOval(Rect.fromCenter(center: Offset(ex, y), width: th * 0.45, height: th), Paint()..color = cu ? _cu1 : _al1);
    }

    // The tail comes in from the left (top), the jumper's end from the right (bottom).
    conductor(topY, -4, w * 0.86, view.copper);
    conductor(botY, w + 4, w * 0.16, false);
    if (view.stray) {
      final tip = strandArea(s).center;
      c.drawLine(Offset(w * 0.17, botY + th * 0.2), tip, Paint()
        ..color = const Color(0xFF5E666D)
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.butt);
      c.drawLine(Offset(w * 0.17, botY + th * 0.2), tip, Paint()
        ..color = _al0
        ..strokeWidth = 0.8);
    }

    // Dirt on the contact faces (oxide and grime) until brushed.
    final dirt = (1 - math.max(view.brushed, brushing?.value ?? 0.0)).clamp(0.0, 1.0).toDouble();
    if (dirt > 0) {
      for (final y in [topY, botY]) {
        final band = Rect.fromLTRB(zone.left, y - th / 2, zone.right, y + th / 2);
        c.drawRect(band, Paint()..color = _oxide.withValues(alpha: 0.85 * dirt));
        final sp = Paint()..color = _speck.withValues(alpha: dirt);
        for (var i = 0; i < 16; i++) {
          final fx = (i * 0.618) % 1.0;
          final fy = ((i * 0.37) % 1.0) - 0.5;
          c.drawCircle(Offset(band.left + band.width * fx, y + fy * th * 0.7), th * (0.07 + 0.05 * (i % 3)), sp);
        }
      }
    }
    if (view.brushed >= 1 && !view.pasted && view.conn == null) {
      for (final y in [topY, botY]) {
        c.drawLine(Offset(zone.left + 4, y - th * 0.22), Offset(zone.right - 4, y - th * 0.22), Paint()
          ..color = const Color(0xCCFFFFFF)
          ..strokeWidth = 1.4);
      }
    }
    if (view.pasted) {
      for (final y in [topY, botY]) {
        final band = Rect.fromLTRB(zone.left + 6, y - th / 2 - 1, zone.right - 6, y + th / 2 + 1);
        c.drawRRect(RRect.fromRectAndRadius(band, Radius.circular(th * 0.4)), Paint()..color = const Color(0x8C3A3F44));
      }
    }

    // The brush, scrubbing.
    final b = brushing;
    if (b != null && view.conn == null && view.brushed < 1) {
      final phase = math.sin(b.value * math.pi * 10);
      final at = Offset(zone.center.dx + phase * zone.width * 0.28, h * 0.5);
      final head = Rect.fromCenter(center: at, width: w * 0.2, height: h * 0.16);
      c.drawRRect(RRect.fromRectAndRadius(head, const Radius.circular(3)), Paint()..color = const Color(0xFF8A5A2B));
      final wire = Paint()
        ..color = const Color(0xFFC9CED3)
        ..strokeWidth = 1;
      for (var x = head.left + 2; x < head.right - 1; x += 2.4) {
        c.drawLine(Offset(x, head.bottom), Offset(x, head.bottom + h * 0.06), wire);
      }
      c.drawLine(head.centerRight, head.centerRight + Offset(w * 0.16, -h * 0.22), Paint()
        ..color = const Color(0xFF8A5A2B)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round);
    }

    // The connector across both.
    final conn = view.conn;
    if (conn != null) {
      final t = turning == null ? view.tight : math.max(view.tight, turning!.value);
      final r = Rect.fromLTRB(w * 0.34, topY - th * 1.05, w * 0.70, botY + th * 1.05);
      _connector(c, r, conn, tight: t, nutTurn: t * math.pi * 1.6);
      final n = view.wrenches;
      if (n > 0 && conn != M4JumperMakeConn.twist) {
        final spanner = Paint()
          ..color = const Color(0xFF3B4C5E)
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round;
        final o = Offset(r.left + r.width * 0.3, r.center.dy);
        // The spanner on the nut (turning), and the one holding the bolt's head.
        final a = -1.1 + t * 0.9;
        c.drawLine(o, o + Offset(math.cos(a), math.sin(a)) * h * 0.5, spanner);
        c.drawCircle(o, h * 0.07, Paint()
          ..color = const Color(0xFF3B4C5E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
        if (n > 1) {
          final o2 = o.translate(2, 2);
          c.drawLine(o2, o2 + Offset(-h * 0.36, h * 0.34), spanner..color = const Color(0xFF5E4B3B));
        }
      }
    }
  }

  @override
  bool shouldRepaint(M4JumperMakeJointPainter old) =>
      old.view.copper != view.copper ||
      old.view.brushed != view.brushed ||
      old.view.pasted != view.pasted ||
      old.view.conn != view.conn ||
      old.view.tight != view.tight ||
      old.view.wrenches != view.wrenches ||
      old.view.stray != view.stray ||
      old.brushing != brushing ||
      old.turning != turning;
}

/// A bend for the jumper (the shape tiles): the arm end on, the two strain
/// clamps and tails, the jumper bent as [shape].
class M4JumperMakeShapePainter extends CustomPainter {
  const M4JumperMakeShapePainter({required this.shape});
  final M4JumperMakeShape shape;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final h = s.height;
    final k = w / 200;
    final cx = w / 2;
    final y = h * 0.16;
    final pole = Rect.fromLTRB(cx - 5 * k, 0, cx + 5 * k, h);
    c.drawRect(pole, Paint()..color = const Color(0xFFB9B5AA));
    final arm = Rect.fromCenter(center: Offset(cx, y - 4 * k), width: 18 * k, height: 10 * k);
    c.drawRect(arm, Paint()..color = const Color(0xFF6E757B));
    final rod = Paint()
      ..color = const Color(0xFF7B4526)
      ..strokeWidth = 5 * k
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(cx - 14 * k, y), Offset(cx - 70 * k, y), rod);
    c.drawLine(Offset(cx + 14 * k, y), Offset(cx + 70 * k, y), rod);
    final wire = Paint()
      ..color = const Color(0xFF4E565D)
      ..strokeWidth = 3 * k
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final a = Offset(cx - 84 * k, y + 28 * k);
    final b = Offset(cx + 84 * k, y + 28 * k);
    c.drawPath(Path()
      ..moveTo(cx - 72 * k, y)
      ..quadraticBezierTo(a.dx, y, a.dx, a.dy), wire);
    c.drawPath(Path()
      ..moveTo(cx + 72 * k, y)
      ..quadraticBezierTo(b.dx, y, b.dx, b.dy), wire);
    final sag = switch (shape) {
          M4JumperMakeShape.tight => 0.0,
          M4JumperMakeShape.smooth => 42.0,
          M4JumperMakeShape.long => 104.0,
        } *
        k;
    final jumper = Paint()
      ..color = const Color(0xFF8C949B)
      ..strokeWidth = 3.4 * k
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    if (shape == M4JumperMakeShape.tight) {
      // Pulled straight across, a kink at each end.
      c.drawPath(
          Path()
            ..moveTo(a.dx, a.dy)
            ..lineTo(a.dx + 6 * k, a.dy - 6 * k)
            ..lineTo(b.dx - 6 * k, b.dy - 6 * k)
            ..lineTo(b.dx, b.dy),
          jumper);
    } else {
      c.drawPath(M4JumperMakeJumperPainter.pathFor(a, b, sag), jumper);
    }
    for (final p in [a, b]) {
      c.drawRect(Rect.fromCenter(center: p, width: 8 * k, height: 10 * k), Paint()..color = const Color(0xFFAEB5BB));
    }
  }

  @override
  bool shouldRepaint(M4JumperMakeShapePainter old) => old.shape != shape;
}
