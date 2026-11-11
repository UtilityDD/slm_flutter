import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The places of "কঙ্কালের স্বাস্থ্য" (lesson 3.3 "ক্রস-আর্ম ও ক্ল্যাম্প", কাজ 2):
//   • the ground view: the evening sky, a far tree line, fields, the lane and
//     the hero — a PCC pole with its channel cross-arm (three pin insulators,
//     the conductors), the wrap-around clamp that holds the arm to the pole
//     (lesson point 2: PCC → wrap-around clamp) and the two braces under it.
//     The line is shut down: an earth set hangs from the three conductors to a
//     rod in the ground. The arm can be rusty or bent, the clamp rusty or
//     slipped down the pole (lesson point 4) — drawn, never written;
//   • the close view up the pole: the arm–clamp joint big, the clamp bolts and
//     the brace bolt (nut, spring washer or only a flat one, loose or tight),
//     the trainee's pole strap round the pole and his gloved hand on the
//     wrench.
// No words in the art.
//
// Design: 360 wide × the scene's height; the ground row follows the bottom of
// the screen (a tall phone gets more sky).

/// What is wrong with the structure as seen from the ground.
enum M3CrossarmFault { none, rustArm, bentArm, slippedClamp, rustClamp }

/// What can be looked at from the ground.
enum M3CrossarmPart { arm, clamp, brace }

/// One bolt in the close view, as it is now.
@immutable
class M3CrossarmBoltLook {
  const M3CrossarmBoltLook({required this.loose, required this.washer, required this.checked});
  final bool loose;
  final bool washer;

  /// Tap-checked: a loose nut shows its gap only once the spanner tried it.
  final bool checked;

  @override
  bool operator ==(Object other) => other is M3CrossarmBoltLook && other.loose == loose && other.washer == washer && other.checked == checked;

  @override
  int get hashCode => Object.hash(loose, washer, checked);
}

/// Where things stand (design px, 360 wide).
@immutable
class M3CrossarmGeo {
  const M3CrossarmGeo({required this.height, required this.groundY});

  factory M3CrossarmGeo.forScene(double h, double inset) => M3CrossarmGeo(height: h, groundY: (h - 300 - inset).clamp(360.0, 700.0));

  final double height;
  final double groundY;

  double get horizonY => groundY - 120;

  // --- the ground view ----------------------------------------------------
  static const poleX = 236.0;
  double get armY => math.max(150.0, groundY - 330);
  double get poleTop => armY - 64;

  /// The arm's seat drops this much when the clamp slipped.
  static const slipDrop = 26.0;

  Rect get armHit => Rect.fromLTRB(140, armY - 18, 332, armY + 20);
  Rect get clampHit => Rect.fromCenter(center: Offset(poleX, armY + 6), width: 56, height: 56);
  Rect get braceHit => Rect.fromLTRB(168, armY + 16, 228, armY + 80);

  Rect hit(M3CrossarmPart p) => switch (p) {
        M3CrossarmPart.arm => armHit,
        M3CrossarmPart.clamp => clampHit,
        M3CrossarmPart.brace => braceHit,
      };

  /// The part under a tap (the clamp wins over the arm it sits on).
  M3CrossarmPart? partAt(Offset p) {
    for (final part in const [M3CrossarmPart.clamp, M3CrossarmPart.brace, M3CrossarmPart.arm]) {
      if (hit(part).contains(p)) return part;
    }
    return null;
  }

  /// The trainee's box (feet on the ground, left of the pole).
  Rect get trainee => Rect.fromLTWH(14, groundY - 208, 104, 208);

  // --- the close view up the pole --------------------------------------------
  static const upPoleX = 210.0;
  double get upArmY => groundY - 200;

  /// The bolts: the clamp's two (each side of the pole) and the brace bolt.
  List<Offset> get bolts => [Offset(upPoleX - 52, upArmY), Offset(upPoleX + 52, upArmY), Offset(70, upArmY)];
  Rect boltHit(int i) => Rect.fromCenter(center: bolts[i], width: 58, height: 58);

  int? boltAt(Offset p) {
    for (var i = 0; i < bolts.length; i++) {
      if (boltHit(i).contains(p)) return i;
    }
    return null;
  }

  @override
  bool operator ==(Object other) => other is M3CrossarmGeo && other.height == height && other.groundY == groundY;

  @override
  int get hashCode => Object.hash(height, groundY);
}

// ============================================================================
// Shared bits
// ============================================================================

const _galv = [Color(0xFFD5DBE0), Color(0xFF9AA4AD)];
const _rust = [Color(0xFFB0643A), Color(0xFF6E3518)];

void _sky(Canvas c, Size size, double hz) {
  final r = Rect.fromLTWH(0, 0, size.width, hz + 4);
  c.drawRect(r, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF345F8C), Color(0xFF86AECD), Color(0xFFF1D7A2)]).createShader(r));
  final cloud = Paint()..color = const Color(0x55FFFFFF);
  for (final (x, y, rr) in [(48.0, 210.0, 20.0), (76.0, 202.0, 26.0), (108.0, 212.0, 18.0), (282.0, 250.0, 17.0), (306.0, 242.0, 22.0), (332.0, 252.0, 15.0)]) {
    c.drawCircle(Offset(x, math.min(y, hz - 40)), rr, cloud);
  }
}

/// Rust blotches over a steel shape (fixed pattern).
void _rustSpots(Canvas c, Rect r, int seed) {
  final rnd = math.Random(seed);
  final p = Paint()..color = const Color(0xCC5A2610);
  for (var i = 0; i < 14; i++) {
    c.drawOval(Rect.fromCenter(center: Offset(r.left + rnd.nextDouble() * r.width, r.top + rnd.nextDouble() * r.height), width: 3 + rnd.nextDouble() * 9, height: 2 + rnd.nextDouble() * 5), p);
  }
}

void _pinInsulator(Canvas c, Offset base, double s) {
  final glaze = Paint()..shader = const LinearGradient(colors: [Color(0xFFF6F3EA), Color(0xFFC9C3B2)]).createShader(Rect.fromCenter(center: base, width: 20 * s, height: 30 * s));
  c.drawRect(Rect.fromCenter(center: base + Offset(0, -4 * s), width: 3 * s, height: 8 * s), Paint()..color = const Color(0xFF7D858C));
  for (var i = 0; i < 2; i++) {
    final y = base.dy - 10 * s - i * 9 * s;
    c.drawOval(Rect.fromCenter(center: Offset(base.dx, y), width: (20 - i * 4) * s, height: 7 * s), glaze);
  }
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(base.dx, base.dy - 27 * s), width: 9 * s, height: 10 * s), Radius.circular(3 * s)), glaze);
}

// ============================================================================
// The ground view
// ============================================================================

class M3CrossarmGroundPainter extends CustomPainter {
  const M3CrossarmGroundPainter({required this.geo, required this.fault, this.looking});

  final M3CrossarmGeo geo;
  final M3CrossarmFault fault;

  /// The part being looked at (a soft ring on it).
  final M3CrossarmPart? looking;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final g = geo.groundY;
    final hz = geo.horizonY;
    _sky(c, size, hz);
    // Far tree line.
    final far = Path()..moveTo(0, hz);
    for (var x = 0.0; x <= w; x += 18) {
      far.lineTo(x, hz - 16 - 9 * math.sin(x * 0.08) - 6 * math.cos(x * 0.21));
    }
    far
      ..lineTo(w, hz + 2)
      ..lineTo(0, hz + 2)
      ..close();
    c.drawPath(far, Paint()..color = const Color(0xFF4B7651));
    // The far poles of the same line.
    final farPole = Paint()
      ..color = const Color(0xFF8D8D86)
      ..strokeWidth = 3;
    c.drawLine(Offset(40, hz + 6), Offset(40, hz - 62), farPole);
    c.drawLine(Offset(22, hz - 56), Offset(58, hz - 56), farPole..strokeWidth = 2);
    // Fields and the lane.
    c.drawRect(Rect.fromLTWH(0, hz, w, g - hz), Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF82A35C), Color(0xFF5D7E43)]).createShader(Rect.fromLTWH(0, hz, w, g - hz)));
    c.drawRect(Rect.fromLTWH(0, g, w, size.height - g), Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFB59B74), Color(0xFF8A7454)]).createShader(Rect.fromLTWH(0, g, w, size.height - g)));
    final pebble = Paint()..color = const Color(0x33000000);
    final rnd = math.Random(5);
    for (var i = 0; i < 24; i++) {
      c.drawCircle(Offset(rnd.nextDouble() * w, g + 6 + rnd.nextDouble() * (size.height - g - 10)), 1.2 + rnd.nextDouble() * 1.6, pebble);
    }
    _pole(c);
  }

  void _pole(Canvas c) {
    final g = geo.groundY;
    const px = M3CrossarmGeo.poleX;
    final top = geo.poleTop;
    final slipped = fault == M3CrossarmFault.slippedClamp;
    final ay = geo.armY + (slipped ? M3CrossarmGeo.slipDrop : 0);
    // The PCC pole.
    final pole = Path()
      ..moveTo(px - 6, top)
      ..lineTo(px + 6, top)
      ..lineTo(px + 11, g + 4)
      ..lineTo(px - 11, g + 4)
      ..close();
    c.drawPath(pole, Paint()..shader = const LinearGradient(colors: [Color(0xFFBDBDB6), Color(0xFF8B8B84)]).createShader(Rect.fromLTRB(px - 11, top, px + 11, g)));
    c.drawOval(Rect.fromCenter(center: Offset(px, g + 4), width: 48, height: 8), Paint()..color = const Color(0x33000000));
    if (slipped) {
      // The old seat: a clean band on the pole where the clamp sat.
      c.drawRect(Rect.fromLTWH(px - 8, geo.armY - 6, 16, 14), Paint()..color = const Color(0xFFD9D8CF));
    }
    // The arm (a channel): straight, or bent with its right end drooping.
    final bent = fault == M3CrossarmFault.bentArm;
    final tilt = slipped ? 0.05 : 0.0;
    final armPaint = Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: fault == M3CrossarmFault.rustArm ? _rust : _galv).createShader(Rect.fromLTRB(146, ay - 5, 326, ay + 5));
    Offset on(double x) {
      var y = ay + (x - px) * tilt;
      if (bent && x > 262) y += (x - 262) * 0.42;
      return Offset(x, y);
    }

    final arm = Path()..moveTo(146, on(146).dy - 5);
    for (var x = 146.0; x <= 326; x += 6) {
      arm.lineTo(x, on(x).dy - 5);
    }
    for (var x = 326.0; x >= 146; x -= 6) {
      arm.lineTo(x, on(x).dy + 5);
    }
    arm.close();
    // The braces: from the arm down to the pole (a V).
    final brace = Paint()
      ..color = const Color(0xFF8F99A2)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    c.drawLine(on(182) + const Offset(0, 4), Offset(px - 7, ay + 64), brace);
    c.drawLine(on(290) + const Offset(0, 4), Offset(px + 7, ay + 64), brace);
    c.drawPath(arm, armPaint);
    if (fault == M3CrossarmFault.rustArm) _rustSpots(c, Rect.fromLTRB(150, ay - 5, 322, ay + 5), 11);
    // The wrap-around clamp on the pole.
    final clamp = Rect.fromCenter(center: Offset(px, ay + 2), width: 26, height: 18);
    c.drawRRect(RRect.fromRectAndRadius(clamp, const Radius.circular(3)),
        Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: fault == M3CrossarmFault.rustClamp ? _rust : const [Color(0xFFC6CDD3), Color(0xFF7E8890)]).createShader(clamp));
    if (fault == M3CrossarmFault.rustClamp) _rustSpots(c, clamp.deflate(2), 23);
    for (final dx in const [-8.0, 8.0]) {
      c.drawCircle(Offset(px + dx, ay + 2), 2.6, Paint()..color = const Color(0xFF3D444B));
    }
    // Insulators and the conductors.
    final wire = Paint()
      ..color = const Color(0xFF2A2F36)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (final x in const [160.0, 206.0, 310.0]) {
      final base = on(x) - const Offset(0, 5);
      _pinInsulator(c, base, 0.8);
      final top = base - const Offset(0, 24);
      c.drawPath(
          Path()
            ..moveTo(0, top.dy + 28)
            ..quadraticBezierTo(top.dx / 2, top.dy + 36, top.dx, top.dy)
            ..quadraticBezierTo((top.dx + 360) / 2, top.dy + 10, 360, top.dy + 14),
          wire);
    }
    // The earth set: three leads from the conductors to a rod (the line is
    // shut down and earthed).
    const ex = 112.0;
    final lead = Paint()
      ..color = const Color(0xFF8C5A2B)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final rod = Offset(ex + 6, g - 2);
    for (final (i, x) in const [160.0, 206.0, 310.0].indexed) {
      final top = on(x) - const Offset(0, 29);
      final atX = ex - 6 + i * 4.0;
      final y = top.dy + 28 + (atX / math.max(1, top.dx)) * -28 + 8 * (atX / top.dx) * (1 - atX / top.dx);
      c.drawCircle(Offset(atX, y), 2.6, Paint()..color = const Color(0xFFE2B33A));
      c.drawPath(
          Path()
            ..moveTo(atX, y)
            ..quadraticBezierTo(atX - 10, (y + rod.dy) / 2, rod.dx, rod.dy - 18),
          lead);
    }
    c.drawLine(Offset(rod.dx, rod.dy - 20), Offset(rod.dx, rod.dy + 4), Paint()
      ..color = const Color(0xFF6F7A82)
      ..strokeWidth = 3);
    c.drawRect(Rect.fromLTWH(rod.dx - 5, rod.dy - 22, 10, 6), Paint()..color = const Color(0xFFE2B33A));
    if (looking != null) {
      final r = geo.hit(looking!).deflate(4);
      c.drawRRect(RRect.fromRectAndRadius(r.shift(Offset(0, slipped && looking != M3CrossarmPart.brace ? M3CrossarmGeo.slipDrop / 2 : 0)), const Radius.circular(10)), Paint()
        ..color = const Color(0xCCFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(M3CrossarmGroundPainter old) => old.geo != geo || old.fault != fault || old.looking != looking;
}

/// The part close up, as the trainee sees it from below (the lens): the arm
/// straight or bent, shiny or rusty; the clamp on its seat or slipped, shiny
/// or rusty; the brace. [rattle]: the loose nut's chatter marks in the wind.
class M3CrossarmLensPainter extends CustomPainter {
  const M3CrossarmLensPainter({required this.part, required this.fault, this.rattle = false});
  final M3CrossarmPart part;
  final M3CrossarmFault fault;
  final bool rattle;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    final r = Offset.zero & size;
    c.drawRect(r, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF7FA8C9), Color(0xFFE3D3A8)]).createShader(r));
    final cx = w * 0.5;
    // The pole section.
    c.drawRect(Rect.fromLTWH(cx - 18, 0, 36, h), Paint()..shader = const LinearGradient(colors: [Color(0xFFC4C4BD), Color(0xFF8B8B84)]).createShader(Rect.fromLTWH(cx - 18, 0, 36, h)));
    final slipped = fault == M3CrossarmFault.slippedClamp;
    final ay = h * 0.42 + (slipped ? 18 : 0);
    if (slipped) c.drawRect(Rect.fromLTWH(cx - 18, h * 0.42 - 10, 36, 22), Paint()..color = const Color(0xFFE2E1D8));
    final rustArm = fault == M3CrossarmFault.rustArm;
    final bent = fault == M3CrossarmFault.bentArm;
    double armY(double x) => ay + (slipped ? (x - cx) * 0.06 : 0) + (bent && x > cx + 30 ? (x - cx - 30) * 0.4 : 0);
    final arm = Path()..moveTo(0, armY(0) - 9);
    for (var x = 0.0; x <= w; x += 4) {
      arm.lineTo(x, armY(x) - 9);
    }
    for (var x = w; x >= 0; x -= 4) {
      arm.lineTo(x, armY(x) + 9);
    }
    arm.close();
    // The brace.
    final braceP = Paint()
      ..color = const Color(0xFF97A1AA)
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(cx - 58, armY(cx - 58) + 8), Offset(cx - 16, h - 6), braceP);
    c.drawPath(arm, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: rustArm ? _rust : _galv).createShader(Rect.fromLTWH(0, ay - 9, w, 18)));
    // The channel's lip.
    c.drawPath(
        Path()
          ..moveTo(0, armY(0) - 4)
          ..lineTo(cx - 20, armY(cx - 20) - 4)
          ..moveTo(cx + 20, armY(cx + 20) - 4)
          ..lineTo(w, armY(w) - 4),
        Paint()
          ..color = const Color(0x33000000)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke);
    if (rustArm) _rustSpots(c, Rect.fromLTWH(4, ay - 8, w - 8, 16), 31);
    // The clamp.
    final clamp = Rect.fromCenter(center: Offset(cx, ay + 1), width: 52, height: 30);
    final rustClamp = fault == M3CrossarmFault.rustClamp;
    c.drawRRect(RRect.fromRectAndRadius(clamp, const Radius.circular(5)),
        Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: rustClamp ? _rust : const [Color(0xFFCBD2D8), Color(0xFF7E8890)]).createShader(clamp));
    if (rustClamp) _rustSpots(c, clamp.deflate(3), 41);
    for (final dx in const [-16.0, 16.0]) {
      final o = Offset(cx + dx, ay + 1);
      c.drawCircle(o, 6, Paint()..color = rustClamp ? const Color(0xFF5E2A12) : const Color(0xFF4A525A));
      c.drawCircle(o, 2.4, Paint()..color = const Color(0xFF8C969E));
    }
    if (rattle) {
      final mark = Paint()
        ..color = const Color(0xFFFFFFFF)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      for (final s in const [1.0, -1.0]) {
        for (var i = 0; i < 2; i++) {
          c.drawArc(Rect.fromCenter(center: Offset(cx + 16 * s, ay + 1), width: 26.0 + i * 12, height: 26.0 + i * 12), s > 0 ? -0.6 : math.pi - 0.6, 1.2, false, mark);
        }
      }
    }
    // Which part the eye is on: a soft ring.
    final focus = switch (part) {
      M3CrossarmPart.arm => Rect.fromLTWH(cx + 34, ay - 22, w - cx - 40, 44 + (bent ? 26 : 0)),
      M3CrossarmPart.clamp => clamp.inflate(8),
      M3CrossarmPart.brace => Rect.fromLTRB(cx - 70, ay + 6, cx - 8, h - 2),
    };
    c.drawRRect(RRect.fromRectAndRadius(focus, const Radius.circular(10)), Paint()
      ..color = const Color(0xAAFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(M3CrossarmLensPainter old) => old.part != part || old.fault != fault || old.rattle != rattle;
}

/// The deadly consequence over the grey scene, in colour: the weak arm gives
/// way where it is rotten or bent — a crack, the broken end drops, dust.
/// Non-graphic.
class M3CrossarmBreakPainter extends CustomPainter {
  const M3CrossarmBreakPainter({required this.geo, required this.v});
  final M3CrossarmGeo geo;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final at = Offset(270, geo.armY);
    final t = Curves.easeIn.transform(v.clamp(0.0, 1.0));
    // The broken end swings down from the crack.
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(1.1 * t);
    c.drawRect(const Rect.fromLTWH(0, -5, 58, 10), Paint()..shader = const LinearGradient(colors: _rust).createShader(const Rect.fromLTWH(0, -5, 58, 10)));
    c.restore();
    // The crack.
    final crack = Path()..moveTo(at.dx - 4, at.dy - 9);
    for (var i = 1; i <= 5; i++) {
      crack.lineTo(at.dx + (i.isOdd ? 4 : -3), at.dy - 9 + i * 4);
    }
    c.drawPath(
        crack,
        Paint()
          ..color = const Color(0xFFFFE08A)
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke);
    // Dust and flakes.
    final rnd = math.Random(7);
    for (var i = 0; i < 16; i++) {
      final a = rnd.nextDouble() * math.pi;
      final d = 8 + 46 * t * rnd.nextDouble();
      c.drawCircle(at + Offset(math.cos(a) * d, math.sin(a) * d * 1.3), 2 + rnd.nextDouble() * 2.5, Paint()..color = Color.fromRGBO(150, 82, 40, (1 - t * 0.7).clamp(0.0, 1.0)));
    }
    final flash = (1 - v * 4).clamp(0.0, 1.0);
    if (flash > 0) c.drawRect(Offset.zero & size, Paint()..color = Color.fromRGBO(255, 255, 255, 0.7 * flash));
  }

  @override
  bool shouldRepaint(M3CrossarmBreakPainter old) => old.v != v || old.geo != geo;
}

// ============================================================================
// The close view up the pole
// ============================================================================

class M3CrossarmUpPainter extends CustomPainter {
  const M3CrossarmUpPainter({required this.geo, required this.bolts, this.selected});

  final M3CrossarmGeo geo;
  final List<M3CrossarmBoltLook> bolts;
  final int? selected;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    final r = Offset.zero & size;
    c.drawRect(r, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2F5A88), Color(0xFF7FA8C9), Color(0xFFDCCDA6)]).createShader(r));
    // Far fields far below.
    final fy = geo.upArmY + 170;
    c.drawRect(Rect.fromLTWH(0, fy, w, h - fy), Paint()..color = const Color(0x664B7651));
    const px = M3CrossarmGeo.upPoleX;
    final ay = geo.upArmY;
    // The conductors above, with the earth set clamps on them.
    final wire = Paint()
      ..color = const Color(0xFF22272D)
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke;
    for (final x in const [118.0, 318.0]) {
      final top = Offset(x, ay - 78);
      c.drawLine(Offset(0, top.dy + 10), Offset(w, top.dy - 6), wire);
      _pinInsulator(c, Offset(x, ay - 14), 1.9);
      c.drawCircle(Offset(x - 40, top.dy + 6 + (x - 40) / w * -16), 4.5, Paint()..color = const Color(0xFFE2B33A));
      c.drawLine(Offset(x - 40, top.dy + 8), Offset(x - 52, top.dy + 120), Paint()
        ..color = const Color(0xFF8C5A2B)
        ..strokeWidth = 2.4);
    }
    // The pole.
    c.drawRect(Rect.fromLTWH(px - 34, 0, 68, h), Paint()..shader = const LinearGradient(colors: [Color(0xFFC6C6BF), Color(0xFF8A8A83)]).createShader(Rect.fromLTWH(px - 34, 0, 68, h)));
    // The brace: from the pole low down to the arm at the brace bolt.
    final bb = geo.bolts[2];
    c.drawLine(Offset(px - 30, ay + 150), bb + const Offset(0, 6), Paint()
      ..color = const Color(0xFF96A0A9)
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round);
    // The arm: a galvanised channel across.
    final arm = Rect.fromLTRB(-4, ay - 22, w + 4, ay + 22);
    c.drawRect(arm, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE0E5E9), Color(0xFFA3ADB5), Color(0xFF8A949C)]).createShader(arm));
    c.drawLine(Offset(-4, ay - 15), Offset(w + 4, ay - 15), Paint()
      ..color = const Color(0x33000000)
      ..strokeWidth = 2);
    c.drawLine(Offset(-4, ay + 15), Offset(w + 4, ay + 15), Paint()
      ..color = const Color(0x22FFFFFF)
      ..strokeWidth = 2);
    // The wrap-around clamp: the strap round the pole, its ears on the arm.
    final strap = Paint()
      ..shader = const LinearGradient(colors: [Color(0xFFB9C1C8), Color(0xFF6F7981)]).createShader(Rect.fromLTRB(px - 70, ay - 30, px + 70, ay + 30));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(px - 38, ay - 30, px + 38, ay + 30), const Radius.circular(6)), strap);
    for (final dx in const [-52.0, 52.0]) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(px + dx, ay), width: 34, height: 52), const Radius.circular(5)), strap);
    }
    // The trainee's pole strap (harness) round the pole, low.
    final belt = Rect.fromLTRB(px - 40, ay + 96, px + 40, ay + 112);
    c.drawRRect(RRect.fromRectAndRadius(belt, const Radius.circular(6)), Paint()..color = const Color(0xFFE8711C));
    c.drawRect(Rect.fromCenter(center: belt.center, width: 16, height: 20), Paint()..color = const Color(0xFF2B2F35));
    // The bolts.
    for (var i = 0; i < bolts.length; i++) {
      _bolt(c, geo.bolts[i], bolts[i], i == selected);
    }
    // His gloved hand with the wrench on the bolt he works on.
    final s = selected;
    if (s != null) {
      final o = geo.bolts[s];
      final grip = o + const Offset(54, 64);
      c.drawLine(o, grip, Paint()
        ..color = const Color(0xFF3A3F45)
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round);
      c.drawCircle(o, 9, Paint()
        ..color = const Color(0xFF3A3F45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: grip + const Offset(4, 6), width: 34, height: 28), const Radius.circular(10)), Paint()..color = const Color(0xFFE2A93A));
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(grip.dx - 8, grip.dy + 14, 28, 60), const Radius.circular(8)), Paint()..color = const Color(0xFF2D4A7A));
    }
  }

  void _bolt(Canvas c, Offset o, M3CrossarmBoltLook b, bool sel) {
    // The flat washer always; the spring washer (a split ring) when fitted.
    c.drawCircle(o, 21, Paint()..color = const Color(0xFFB5BDC4));
    c.drawCircle(o, 21, Paint()
      ..color = const Color(0xFF6F7880)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2);
    if (b.washer) {
      final ring = Paint()
        ..color = const Color(0xFF3B4148)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5;
      c.drawArc(Rect.fromCircle(center: o, radius: 17), -1.2, 2 * math.pi - 0.45, false, ring);
      c.drawLine(o + Offset(17 * math.cos(-1.2), 17 * math.sin(-1.2)), o + Offset(19.5 * math.cos(-1.32), 19.5 * math.sin(-1.32)), ring..strokeWidth = 3);
    }
    final shown = b.checked && b.loose;
    final no = shown ? o + const Offset(5, -5) : o;
    if (shown) {
      // Backed off: the thread shows under the nut.
      c.drawCircle(o, 12.5, Paint()..color = const Color(0xFF7A848C));
      for (var i = 0; i < 3; i++) {
        c.drawArc(Rect.fromCircle(center: o, radius: 7.0 + i * 2.2), 0.4, 4.6, false, Paint()
          ..color = const Color(0xFF4C545B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
      }
    }
    final hex = Path();
    for (var i = 0; i < 6; i++) {
      final a = math.pi / 6 + i * math.pi / 3;
      final p = no + Offset(math.cos(a) * 14, math.sin(a) * 14);
      i == 0 ? hex.moveTo(p.dx, p.dy) : hex.lineTo(p.dx, p.dy);
    }
    hex.close();
    c.drawPath(hex, Paint()..shader = const LinearGradient(colors: [Color(0xFFDDE3E8), Color(0xFF7D878F)]).createShader(Rect.fromCircle(center: no, radius: 14)));
    c.drawPath(hex, Paint()
      ..color = const Color(0xFF4C545B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3);
    c.drawCircle(no, 5.5, Paint()..color = const Color(0xFF8E979F));
    c.drawCircle(no, 5.5, Paint()
      ..color = const Color(0xFF555D64)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);
    if (shown) {
      // It turns under the spanner: chatter marks.
      final mark = Paint()
        ..color = const Color(0xFFFFC23A)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      for (final r in const [33.0, 40.0]) {
        c.drawArc(Rect.fromCircle(center: o, radius: r), -0.45, 0.9, false, mark);
        c.drawArc(Rect.fromCircle(center: o, radius: r), math.pi - 0.45, 0.9, false, mark);
      }
    }
    if (sel) {
      c.drawCircle(o, 28, Paint()
        ..color = const Color(0xCCFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2);
    }
  }

  @override
  bool shouldRepaint(M3CrossarmUpPainter old) => old.geo != geo || !listEquals(old.bolts, bolts) || old.selected != selected;
}
