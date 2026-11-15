import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The drawn world of lesson 6.4 কাজ 2 "জ্যাম ছাড়াও, লাইন জোড়ো" (m6_ab_unjam.dart).
//
// Two places on one 11 kV DP (double pole) structure, daytime:
//
//  The head (on the platform): a side close-up of the AB switch under
//    শাটডাউন — the channel (cross-arm), three phases, each a tilting post
//    insulator carrying its blade (the hinge on top, the crank and its pivot
//    at the bottom on the common rod) and a fixed post insulator carrying the
//    jaw; the common rod under the channel ends at the bearing and the
//    operating lever on the right. The crew's earths are clamped on both
//    terminals of every phase, the hinge side and the jaw side (X1: the
//    isolation, the tester and the earths were done by the crew; a switch
//    under service is earthed on both sides), and the crew's voltage tester
//    hangs on the platform rail with its green "dead" light. The trainee
//    stands on the platform in harness, the lanyard round the pole. Grime is
//    drawn real (soot on a jaw, a brown film on an insulator) with no ticks.
//  The ground: the structure from the front (the AB small on top), the
//    operating rod down the left pole to the ground handle (it swings through
//    an arc: down = open, up = closed), a toolbox with the phone and the
//    crew's tester in front of it, the earths on both sides of the AB to a
//    rod by each pole (while the PTW is on), the dark houses behind that
//    light when the line is restored.
//
// No text in the art except what a worker reads. Code-drawn, gradients, no
// bitmaps. Design: 360 wide × the scene's height (560–900); a tall phone gets
// more sky, never a stretched structure.

/// The kind of AB on this pole (lesson 6.4 point 3): a tilting type (the post
/// insulator tilts with its blade) or a vertical break (the blade lifts at its
/// hinge). Both work the same way.
enum M6UnjamType { tilting, vertical }

/// Where the trainee is.
enum M6UnjamStage { head, ground }

/// Where things are (design px, 360 wide).
@immutable
class M6UnjamGeo {
  const M6UnjamGeo._(this.height, this.chY, this.groundY);

  factory M6UnjamGeo.forScene(double height, double inset) {
    final ch = 250 + (height - 560) * 0.45;
    final g = height - floorUp - inset * 0.5;
    return M6UnjamGeo._(height, ch, g);
  }

  final double height;

  // --- the head (platform close-up) -------------------------------------------

  /// The channel (cross-arm) line.
  final double chY;

  /// The phases' centres (R, Y, B).
  static const List<double> phaseX = [64, 164, 264];

  /// The tilting post (blade side) and the fixed post (jaw side) of phase [i].
  double tiltX(int i) => phaseX[i] - 24;
  double jawX(int i) => phaseX[i] + 24;

  /// The blade's hinge on top of the tilting post.
  Offset hinge(int i) => Offset(tiltX(i), chY - 92);

  /// The jaw on top of the fixed post.
  Offset jaw(int i) => Offset(jawX(i), chY - 98);

  static const double bladeLen = 52;

  /// The oil points: the three crank pivots on the common rod (0–2) and the
  /// bearing at the rod's end (3).
  Offset pivot(int i) => i < 3 ? Offset(tiltX(i), chY + 14) : Offset(330, chY + 14);
  Rect pivotHit(int i) => Rect.fromCenter(center: pivot(i), width: 40, height: 40);

  /// The rub places: phase [i]'s jaw (and the blade's contact) and its fixed
  /// post insulator.
  Rect jawHit(int i) => Rect.fromCenter(center: Offset(jawX(i), chY - 104), width: 46, height: 36);
  Rect insHit(int i) => Rect.fromLTRB(jawX(i) - 15, chY - 80, jawX(i) + 15, chY - 14);

  /// The operating lever hanging from the bearing (rock it left and right).
  Rect get leverHit => Rect.fromLTWH(306, chY + 38, 44, 70);
  Offset get leverGrip => Offset(330, chY + 88);

  /// The platform deck and the trainee on it.
  double get deckY => chY + 150;
  Rect get traineeUp => Rect.fromLTWH(6, deckY - 104, 44, 104);

  /// A spot on the head with nothing on it (between the posts, above them).
  Offset get headEmpty => Offset(phaseX[1], chY - 150);

  // --- the ground ----------------------------------------------------------------

  /// The ground sits this far above the bottom (the pouch row stands on it).
  static const double floorUp = 112;

  /// The ground line at the poles' feet.
  final double groundY;

  static const double lp = 50;
  static const double rp = 150;
  double get topY => math.max(150.0, groundY - 430);

  /// The AB on top (small).
  double get abY => topY + 26;
  double abPhaseX(int i) => 70 + 30.0 * i;

  /// The ground handle: its pivot on the left pole, its length; open points
  /// down-right (60°), closed up-right (−60°).
  Offset get handlePivot => Offset(lp + 14, groundY - 100);
  static const double handleLen = 44;
  static const double openDeg = 60;
  static const double closedDeg = -60;

  /// The knob at stroke progress [p] (0 = open, 1 = closed).
  Offset knob(double p) {
    final a = (openDeg + (closedDeg - openDeg) * p.clamp(0.0, 1.0)) * math.pi / 180;
    return handlePivot + Offset(math.cos(a), math.sin(a)) * handleLen;
  }

  /// The stroke progress for a finger at [at] (by its angle round the pivot).
  double progressAt(Offset at) {
    final d = at - handlePivot;
    final deg = math.atan2(d.dy, d.dx) * 180 / math.pi;
    return ((openDeg - deg) / (openDeg - closedDeg)).clamp(0.0, 1.0);
  }

  Rect knobHit(double p) => Rect.fromCenter(center: knob(p), width: 60, height: 60);

  /// The whole arc the knob travels (the handle's place for the hint sweep).
  Rect get handleArea => Rect.fromCenter(center: handlePivot + const Offset(26, 0), width: 64, height: 120);

  /// The phone on the toolbox.
  Offset get phone => Offset(206, groundY - 50);
  Rect get phoneHit => Rect.fromCenter(center: phone, width: 52, height: 60);

  /// The trainee by the handle.
  Rect get traineeDown => Rect.fromLTWH(104, groundY - 104, 44, 104);

  /// The houses on the right (they light on restore).
  Rect get houses => Rect.fromLTRB(236, groundY - 150, 356, groundY - 36);

  /// A swipe up the structure starts here (the tilt-up phase view).
  Offset get swipeFrom => Offset(rp + 30, groundY - 190);

  /// The tilt-up phase view card (top of the scene).
  static const Rect phaseCard = Rect.fromLTWH(70, 132, 220, 120);

  /// Where the flash comes off on the ground view (the AB on top).
  Offset get abCentre => Offset(abPhaseX(1), abY);

  @override
  bool operator ==(Object other) => other is M6UnjamGeo && other.height == height && other.chY == chY && other.groundY == groundY;

  @override
  int get hashCode => Object.hash(height, chY, groundY);
}

/// What the head shows now.
@immutable
class M6UnjamHeadRig {
  const M6UnjamHeadRig({
    required this.type,
    required this.jam,
    required this.stuck,
    required this.lag,
    required this.jawDirt,
    required this.insDirt,
    required this.oiled,
    required this.earths,
  });

  final M6UnjamType type;

  /// The jammed oil point (0–2 a crank pivot, 3 the bearing) and the phase
  /// that lags (the pivot's own, or the bearing's dealt one).
  final int jam;
  final int stuck;

  /// How much the jam still holds (1 = jammed, 0 = free).
  final double lag;

  /// Soot on each jaw / film on each insulator (0 clean … 1 dirty).
  final List<double> jawDirt;
  final List<double> insDirt;

  /// The oil points that had oil.
  final Set<int> oiled;

  /// The crew's earths on every jaw (under the PTW).
  final bool earths;

  @override
  bool operator ==(Object other) =>
      other is M6UnjamHeadRig &&
      other.type == type &&
      other.jam == jam &&
      other.stuck == stuck &&
      other.lag == lag &&
      listEquals(other.jawDirt, jawDirt) &&
      listEquals(other.insDirt, insDirt) &&
      setEquals(other.oiled, oiled) &&
      other.earths == earths;

  @override
  int get hashCode => Object.hash(type, jam, stuck, lag, Object.hashAll(jawDirt), Object.hashAll(insDirt), Object.hashAllUnordered(oiled), earths);
}

/// What the ground shows now.
@immutable
class M6UnjamGroundRig {
  const M6UnjamGroundRig({
    required this.type,
    required this.handle,
    required this.closed,
    required this.stuck,
    required this.seated,
    required this.earths,
    required this.lit,
    this.hot = false,
  });

  final M6UnjamType type;

  /// The handle's stroke progress (0 open … 1 closed).
  final double handle;

  /// The AB is closed (its blades in the jaws), [seated] = all three fully;
  /// otherwise phase [stuck] sits part way.
  final bool closed;
  final int stuck;
  final bool seated;

  final bool earths;

  /// The houses' windows (0 dark … 1 lit).
  final double lit;

  /// The part-seated jaw glows (the breaker came on with it).
  final bool hot;

  @override
  bool operator ==(Object other) =>
      other is M6UnjamGroundRig &&
      other.type == type &&
      other.handle == handle &&
      other.closed == closed &&
      other.stuck == stuck &&
      other.seated == seated &&
      other.earths == earths &&
      other.lit == lit &&
      other.hot == hot;

  @override
  int get hashCode => Object.hash(type, handle, closed, stuck, seated, earths, lit, hot);
}

const _steel = Color(0xFF6F7880);
const _steelDark = Color(0xFF454C53);
const _wire = Color(0xFF3C4248);
const _porcelain = Color(0xFFE6EBEF);
const _porcelainShade = Color(0xFFB8C2CA);
const _copper = Color(0xFFC88A4A);
const _soot = Color(0xFF1B1410);
const _grime = Color(0xFF6E5530);
const _earthGreen = Color(0xFF2E9E4F);
const _earthYellow = Color(0xFFF2C230);
const _testerBody = Color(0xFFF2C230);
const _testerStick = Color(0xFFD94A2B);
const _deadGreen = Color(0xFF3BE07A);

/// An earth lead (green with a yellow tracer) along [path].
void _earthLead(Canvas c, Path path, {double width = 2.6}) {
  c.drawPath(path, Paint()
    ..color = _earthGreen
    ..style = PaintingStyle.stroke
    ..strokeWidth = width);
  c.drawPath(path, Paint()
    ..color = _earthYellow
    ..style = PaintingStyle.stroke
    ..strokeWidth = width * 0.38);
}

/// The crew's voltage tester (a detector head on an insulated stick) from
/// [foot] to [head], its light green: proved, and the line read dead.
void _tester(Canvas c, Offset foot, Offset head, {double scale = 1}) {
  c.drawLine(foot, head, Paint()
    ..color = _testerStick
    ..strokeWidth = 4 * scale
    ..strokeCap = StrokeCap.round);
  final d = head - foot;
  final u = d / d.distance;
  // The dark grip band near the foot.
  c.drawLine(foot + u * 6 * scale, foot + u * 16 * scale, Paint()
    ..color = const Color(0xFF2A2A2A)
    ..strokeWidth = 5 * scale
    ..strokeCap = StrokeCap.round);
  // The detector head, its hook and its green light.
  c.save();
  c.translate(head.dx, head.dy);
  c.rotate(math.atan2(d.dy, d.dx) + math.pi / 2);
  final body = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(0, -8 * scale), width: 11 * scale, height: 20 * scale), Radius.circular(4 * scale));
  c.drawRRect(body, Paint()..color = _testerBody);
  c.drawRRect(body, Paint()
    ..color = const Color(0xFF7A5A12)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1);
  c.drawLine(Offset(0, -18 * scale), Offset(0, -25 * scale), Paint()
    ..color = _steelDark
    ..strokeWidth = 2 * scale);
  c.drawCircle(Offset(0, -6 * scale), 3.2 * scale, Paint()..color = _deadGreen);
  c.drawCircle(Offset(0, -6 * scale), 5.5 * scale, Paint()
    ..color = _deadGreen.withValues(alpha: 0.35)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
  c.restore();
}

void _sky(Canvas c, Rect r, {bool dusk = false}) {
  c.drawRect(
      r,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dusk ? const [Color(0xFF36578A), Color(0xFF8FA9C9), Color(0xFFD9C9A8)] : const [Color(0xFF4A86C4), Color(0xFFA5CDEB), Color(0xFFE6EFD9)],
        ).createShader(r));
}

/// A post insulator (sheds) from [base] up [h], tilted by [tilt] radians.
void _post(Canvas c, Offset base, double h, {double tilt = 0, double grime = 0}) {
  c.save();
  c.translate(base.dx, base.dy);
  c.rotate(tilt);
  final body = Rect.fromLTWH(-5, -h, 10, h);
  c.drawRect(body, Paint()..color = _porcelainShade);
  for (var y = -h + 6; y < -4; y += 11) {
    final shed = Rect.fromCenter(center: Offset(0, y), width: 24, height: 7);
    c.drawOval(
        shed,
        Paint()
          ..shader = const LinearGradient(colors: [_porcelain, _porcelainShade]).createShader(shed));
  }
  if (grime > 0.02) {
    final g = Paint()..color = _grime.withValues(alpha: 0.75 * grime);
    for (var y = -h + 8; y < -6; y += 11) {
      c.drawOval(Rect.fromCenter(center: Offset(1, y + 1), width: 22, height: 5), g);
    }
    c.drawRect(Rect.fromLTWH(-5, -h * 0.85, 10, h * 0.7), Paint()..color = _grime.withValues(alpha: 0.35 * grime));
  }
  // The steel cap and base.
  c.drawRect(Rect.fromLTWH(-7, -h - 4, 14, 6), Paint()..color = _steel);
  c.drawRect(Rect.fromLTWH(-7, -2, 14, 6), Paint()..color = _steel);
  c.restore();
}

/// The blade angles (radians, 0 = into the jaw, negative = up) for the head
/// view: the AB is open; a rock [t] (0…1) swings the blades toward closed and
/// back; the jammed phase (or all, for the bearing) lags and moves less while
/// the jam still holds ([lag]).
List<double> m6UnjamBladeAngles({required int jam, required int stuck, required double lag, required double t}) {
  const open = -75 * math.pi / 180;
  const swing = 30 * math.pi / 180;
  final free = math.sin(math.pi * t.clamp(0.0, 1.0));
  final late = math.sin(math.pi * ((t - 0.25 * lag) / (1 - 0.25 * lag)).clamp(0.0, 1.0)) * (1 - 0.6 * lag);
  return [
    for (var i = 0; i < 3; i++) open + swing * ((jam == 3 || i == stuck) ? late : free),
  ];
}

class M6UnjamHeadPainter extends CustomPainter {
  M6UnjamHeadPainter({required this.geo, required this.rig, required this.rock}) : super(repaint: rock);

  final M6UnjamGeo geo;
  final M6UnjamHeadRig rig;

  /// The rock in progress (0…1; 0 at rest).
  final ValueListenable<double> rock;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    _sky(c, Rect.fromLTWH(0, 0, w, size.height));
    // Far trees and fields below the platform.
    final far = Paint()..color = const Color(0xFF6C9A5A);
    final rnd = math.Random(7);
    for (var x = -10.0; x < w + 20; x += 16 + rnd.nextDouble() * 14) {
      final r = 8 + rnd.nextDouble() * 8;
      c.drawCircle(Offset(x, g.deckY + 40 - r * 0.4), r, far);
    }
    c.drawRect(Rect.fromLTRB(0, g.deckY + 40, w, size.height), Paint()..color = const Color(0xFF8DB55A));
    // The pole behind the middle phase.
    final pole = Rect.fromLTWH(g.tiltX(1) + 16, 0, 16, g.deckY + 60);
    c.drawRect(pole, Paint()..shader = const LinearGradient(colors: [Color(0xFF9AA0A5), Color(0xFF5E656B)]).createShader(pole));
    // Line drops from the top to every hinge and jaw terminal.
    final line = Paint()
      ..color = _wire
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 3; i++) {
      c.drawLine(Offset(g.tiltX(i) - 9, g.chY - 100), Offset(g.tiltX(i) - 20, 0), line);
      c.drawLine(Offset(g.jawX(i) + 9, g.chY - 104), Offset(g.jawX(i) + 20, 0), line);
    }
    // The channel.
    final ch = Rect.fromLTWH(22, g.chY - 6, 330, 12);
    c.drawRect(ch, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_steel, _steelDark]).createShader(ch));
    // The common rod, the cranks and the bearing.
    final rod = Paint()
      ..color = _steelDark
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(g.tiltX(0), g.chY + 14), Offset(330, g.chY + 14), rod);
    for (var i = 0; i < 4; i++) {
      final p = g.pivot(i);
      c.drawCircle(p, i == 3 ? 10 : 7, Paint()..color = _steel);
      c.drawCircle(p, i == 3 ? 10 : 7, Paint()
        ..color = _steelDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6);
      if (i < 3) c.drawLine(p, Offset(p.dx, g.chY + 2), Paint()..color = _steelDark..strokeWidth = 4);
      // Rust on every oil point (oiled ones turn dark and glossy).
      if (rig.oiled.contains(i)) {
        c.drawCircle(p.translate(0, 3), 4.2, Paint()..color = const Color(0xFF2A1C0C));
        c.drawCircle(p.translate(-1.5, 1.5), 1.4, Paint()..color = const Color(0xCCFFFFFF));
        c.drawLine(p.translate(0, 6), p.translate(0, 11), Paint()..color = const Color(0xFF2A1C0C)..strokeWidth = 1.6);
      } else {
        c.drawCircle(p.translate(2, 2), 3.2, Paint()..color = const Color(0x997A4A22));
      }
    }
    // The bearing block and the lever with its grip.
    c.drawRect(Rect.fromCenter(center: g.pivot(3), width: 26, height: 18), Paint()..color = _steelDark);
    final t = rock.value;
    final leverTilt = 0.18 * math.sin(math.pi * 2 * t);
    c.save();
    c.translate(330, g.chY + 14);
    c.rotate(leverTilt);
    c.drawLine(Offset.zero, const Offset(0, 80), Paint()
      ..color = _steel
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, 74), width: 14, height: 26), const Radius.circular(5)), Paint()..color = const Color(0xFFB03A2E));
    c.restore();

    final angles = m6UnjamBladeAngles(jam: rig.jam, stuck: rig.stuck, lag: rig.lag, t: t);
    for (var i = 0; i < 3; i++) {
      final tilting = rig.type == M6UnjamType.tilting;
      final postTilt = tilting ? (angles[i] + 75 * math.pi / 180) * 0.35 - 0.12 : 0.0;
      _post(c, Offset(g.tiltX(i), g.chY - 4), 84, tilt: postTilt);
      _post(c, Offset(g.jawX(i), g.chY - 4), 84, grime: rig.insDirt[i]);
      // The jaw: a copper U on the fixed post.
      final j = g.jaw(i);
      final jp = Path()
        ..moveTo(j.dx - 9, j.dy - 10)
        ..lineTo(j.dx - 9, j.dy + 6)
        ..lineTo(j.dx + 9, j.dy + 6)
        ..lineTo(j.dx + 9, j.dy - 10);
      c.drawPath(jp, Paint()
        ..color = _copper
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.2);
      // The blade from its hinge.
      final hinge = tilting ? g.hinge(i) + Offset(math.sin(postTilt) * 88, (1 - math.cos(postTilt)) * 88) : g.hinge(i);
      final tip = hinge + Offset(math.cos(angles[i]), math.sin(angles[i])) * M6UnjamGeo.bladeLen;
      c.drawLine(hinge, tip, Paint()
        ..color = _copper
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round);
      c.drawCircle(hinge, 4.5, Paint()..color = _steelDark);
      // Arcing marks: soot on the jaw's mouth and on the blade's tip.
      final d = rig.jawDirt[i];
      if (d > 0.02) {
        final s = Paint()..color = _soot.withValues(alpha: 0.85 * d);
        c.drawOval(Rect.fromCenter(center: j.translate(-6, -2), width: 8, height: 12), s);
        c.drawOval(Rect.fromCenter(center: j.translate(6, -4), width: 7, height: 10), s);
        c.drawOval(Rect.fromCenter(center: j.translate(0, 5), width: 14, height: 5), s);
        c.drawCircle(tip, 4, s);
        c.drawCircle(j.translate(-3, -9), 2.2, Paint()..color = const Color(0xFF5A6E7A).withValues(alpha: 0.7 * d));
      }
      // The crew's earths on both sides of the phase: a clamp on the jaw's
      // terminal and one on the hinge's, each lead down to the pole.
      if (rig.earths) {
        final pole = Offset(g.tiltX(1) + 24, g.chY + 40 + 6.0 * i);
        final jawClamp = Offset(g.jawX(i) + 10, g.chY - 108);
        final hingeClamp = Offset(g.tiltX(i) - 11, g.chY - 106);
        for (final clamp in [jawClamp, hingeClamp]) {
          c.drawRect(Rect.fromCenter(center: clamp, width: 8, height: 8), Paint()..color = _steelDark);
        }
        _earthLead(
            c,
            Path()
              ..moveTo(jawClamp.dx, jawClamp.dy)
              ..quadraticBezierTo(jawClamp.dx + 14, g.chY - 40, pole.dx, pole.dy));
        _earthLead(
            c,
            Path()
              ..moveTo(hingeClamp.dx, hingeClamp.dy)
              ..quadraticBezierTo(hingeClamp.dx - 12, g.chY - 40, pole.dx - 4, pole.dy + 3));
      }
    }
    // The crew's tester hung on the platform rail (it proved the line dead
    // before the earths went on; staged, X1).
    if (rig.earths) _tester(c, Offset(206, g.deckY - 2), Offset(196, g.deckY - 62));
    // The platform deck.
    final deck = Rect.fromLTWH(0, g.deckY, 220, 10);
    c.drawRect(deck, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8A7A62), Color(0xFF5C4E3C)]).createShader(deck));
    for (var x = 24.0; x < 220; x += 46) {
      c.drawLine(Offset(x, g.deckY + 10), Offset(x - 8, g.deckY + 50), Paint()..color = _steelDark..strokeWidth = 3);
    }
    // The harness lanyard from the trainee's waist round the pole.
    final waist = Offset(g.traineeUp.center.dx + 6, g.traineeUp.top + 58);
    final lanyard = Path()
      ..moveTo(waist.dx, waist.dy)
      ..quadraticBezierTo((waist.dx + pole.left) / 2, waist.dy + 18, pole.left, waist.dy - 6);
    c.drawPath(lanyard, Paint()
      ..color = const Color(0xFFE07A1F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
    c.drawCircle(Offset(pole.left + 2, waist.dy - 6), 3.5, Paint()..color = _steelDark);
  }

  @override
  bool shouldRepaint(M6UnjamHeadPainter old) => old.geo != geo || old.rig != rig || old.rock != rock;
}

class M6UnjamGroundPainter extends CustomPainter {
  const M6UnjamGroundPainter({required this.geo, required this.rig});

  final M6UnjamGeo geo;
  final M6UnjamGroundRig rig;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    _sky(c, Rect.fromLTWH(0, 0, w, g.groundY), dusk: true);
    final horizon = g.groundY - 40;
    // Far trees.
    final rnd = math.Random(11);
    final tree = Paint()..color = const Color(0xFF4C6B45);
    for (var x = -10.0; x < w + 20; x += 18 + rnd.nextDouble() * 16) {
      final r = 9 + rnd.nextDouble() * 9;
      c.drawCircle(Offset(x, horizon - r * 0.4), r, tree);
    }
    _houses(c);
    final floor = Rect.fromLTRB(0, horizon, w, size.height);
    c.drawRect(floor, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFA28A62), Color(0xFF6E5A40)]).createShader(floor));
    // The poles.
    for (final x in const [M6UnjamGeo.lp, M6UnjamGeo.rp]) {
      final p = Rect.fromLTRB(x - 7, g.topY, x + 7, g.groundY);
      c.drawRect(p, Paint()..shader = const LinearGradient(colors: [Color(0xFF9AA0A5), Color(0xFF5E656B)]).createShader(p));
    }
    // The cross-arm with the line over it.
    c.drawRect(Rect.fromLTWH(M6UnjamGeo.lp - 18, g.topY + 4, M6UnjamGeo.rp - M6UnjamGeo.lp + 36, 7), Paint()..color = _steelDark);
    final line = Paint()
      ..color = _wire
      ..strokeWidth = 1.6;
    for (var i = 0; i < 3; i++) {
      c.drawLine(Offset(0, g.topY - 10 + 4.0 * i), Offset(g.abPhaseX(i) - 10, g.abY - 4), line);
      c.drawLine(Offset(g.abPhaseX(i) + 10, g.abY - 4), Offset(w, g.topY - 14 + 4.0 * i), line);
    }
    // The AB, small: three blades (open up, closed flat, one part seated).
    c.drawRect(Rect.fromLTWH(M6UnjamGeo.lp - 6, g.abY + 6, M6UnjamGeo.rp - M6UnjamGeo.lp + 12, 5), Paint()..color = _steel);
    for (var i = 0; i < 3; i++) {
      final x = g.abPhaseX(i);
      c.drawRect(Rect.fromLTWH(x - 11, g.abY - 6, 4, 12), Paint()..color = _porcelain);
      c.drawRect(Rect.fromLTWH(x + 7, g.abY - 6, 4, 12), Paint()..color = _porcelain);
      final a = !rig.closed ? -70.0 : (!rig.seated && i == rig.stuck ? -16.0 : 0.0);
      final h = Offset(x - 9, g.abY - 7);
      final tip = h + Offset(math.cos(a * math.pi / 180), math.sin(a * math.pi / 180)) * 19;
      c.drawLine(h, tip, Paint()
        ..color = _copper
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round);
      if (rig.hot && !rig.seated && i == rig.stuck) {
        c.drawCircle(Offset(x + 9, g.abY - 8), 9, Paint()
          ..color = const Color(0xCCFF5A1F)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      }
    }
    // The operating rod down the left pole to the handle.
    final pv = g.handlePivot;
    c.drawLine(Offset(M6UnjamGeo.lp + 9, g.abY + 10), Offset(M6UnjamGeo.lp + 9, pv.dy), Paint()
      ..color = _steelDark
      ..strokeWidth = 3);
    // The handle's arc guide plate and the handle at its progress.
    final plate = Rect.fromCenter(center: pv, width: 2 * M6UnjamGeo.handleLen + 8, height: 2 * M6UnjamGeo.handleLen + 8);
    c.drawArc(plate, M6UnjamGeo.closedDeg * math.pi / 180, (M6UnjamGeo.openDeg - M6UnjamGeo.closedDeg) * math.pi / 180, false, Paint()
      ..color = const Color(0x553A3F45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5);
    final k = g.knob(rig.handle);
    c.drawLine(pv, k, Paint()
      ..color = _steel
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round);
    c.drawCircle(pv, 6, Paint()..color = _steelDark);
    c.drawCircle(k, 9, Paint()..color = const Color(0xFFB03A2E));
    c.drawCircle(k.translate(-2, -2), 3, Paint()..color = const Color(0x55FFFFFF));
    // The handle's earth strap to the ground.
    c.drawLine(pv.translate(0, 8), Offset(pv.dx + 4, g.groundY), Paint()
      ..color = _earthGreen
      ..strokeWidth = 2);
    // The crew's portable earths on both sides of the AB (under the PTW):
    // the jaw side to a rod by the right pole, the hinge side to a rod by the
    // left pole.
    if (rig.earths) {
      final right = Offset(M6UnjamGeo.rp + 22, g.groundY - 4);
      final left = Offset(M6UnjamGeo.lp - 24, g.groundY - 4);
      for (final rod in [right, left]) {
        c.drawLine(rod, rod.translate(0, -16), Paint()..color = _steelDark..strokeWidth = 3);
      }
      for (var i = 0; i < 3; i++) {
        final jawTop = Offset(g.abPhaseX(i) + 12, g.abY - 10);
        _earthLead(
            c,
            Path()
              ..moveTo(jawTop.dx, jawTop.dy)
              ..quadraticBezierTo(M6UnjamGeo.rp + 30, (jawTop.dy + right.dy) / 2, right.dx, right.dy - 16),
            width: 1.8);
        final hingeTop = Offset(g.abPhaseX(i) - 12, g.abY - 10);
        _earthLead(
            c,
            Path()
              ..moveTo(hingeTop.dx, hingeTop.dy)
              ..quadraticBezierTo(M6UnjamGeo.lp - 30, (hingeTop.dy + left.dy) / 2, left.dx, left.dy - 16),
            width: 1.8);
      }
    }
    // The toolbox and the phone on it.
    final box = Rect.fromCenter(center: g.phone.translate(0, 36), width: 64, height: 30);
    c.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(4)), Paint()..color = const Color(0xFFB03A2E));
    c.drawRect(Rect.fromLTWH(box.left, box.top + 10, box.width, 3), Paint()..color = const Color(0xFF7A231B));
    // The crew's tester lying in front of the toolbox (their kit).
    _tester(c, box.bottomLeft.translate(-2, 12), box.bottomRight.translate(-10, 8), scale: 0.8);
    final ph = RRect.fromRectAndRadius(Rect.fromCenter(center: g.phone, width: 24, height: 42), const Radius.circular(5));
    c.drawRRect(ph, Paint()..color = const Color(0xFF1C222A));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: g.phone.translate(0, -3), width: 18, height: 28), const Radius.circular(2)), Paint()..color = const Color(0xFF3E6C8F));
  }

  void _houses(Canvas c) {
    final r = geo.houses;
    final glow = rig.lit.clamp(0.0, 1.0);
    final xs = [r.left, r.left + 42, r.left + 82];
    for (final (i, x) in xs.indexed) {
      final top = r.top + 22.0 * (i % 2);
      final body = Rect.fromLTRB(x, top + 20, x + 36, r.bottom);
      c.drawRect(body, Paint()..color = Color.lerp(const Color(0xFF7D7468), const Color(0xFF9A8C76), glow)!);
      final roof = Path()
        ..moveTo(x - 4, top + 22)
        ..lineTo(x + 18, top)
        ..lineTo(x + 40, top + 22)
        ..close();
      c.drawPath(roof, Paint()..color = const Color(0xFF5B3A2A));
      for (final wy in [top + 32, top + 56]) {
        if (wy + 12 > r.bottom) continue;
        final win = Rect.fromLTWH(x + 6, wy, 10, 12);
        final win2 = Rect.fromLTWH(x + 20, wy, 10, 12);
        for (final wr in [win, win2]) {
          c.drawRect(wr, Paint()..color = Color.lerp(const Color(0xFF2B2F36), const Color(0xFFFFD86B), glow)!);
          if (glow > 0.05) {
            c.drawRect(wr.inflate(3), Paint()
              ..color = const Color(0xFFFFD86B).withValues(alpha: 0.35 * glow)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(M6UnjamGroundPainter old) => old.geo != geo || old.rig != rig;
}

/// The tilt-up view: the three blades in their jaws, large (seated, open, or
/// one part seated).
class M6UnjamPhasePainter extends CustomPainter {
  const M6UnjamPhasePainter({required this.closed, required this.seated, required this.stuck, this.hot = false});

  final bool closed;
  final bool seated;
  final int stuck;
  final bool hot;

  @override
  void paint(Canvas c, Size size) {
    final r = Offset.zero & size;
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(12)), Paint()..color = const Color(0xEE0B1324));
    final inner = r.deflate(6);
    c.save();
    c.clipRRect(RRect.fromRectAndRadius(inner, const Radius.circular(9)));
    _sky(c, inner, dusk: true);
    final cw = inner.width / 3;
    for (var i = 0; i < 3; i++) {
      final x0 = inner.left + cw * i;
      final base = inner.bottom - 10;
      final hingeX = x0 + cw * 0.24;
      final jawX = x0 + cw * 0.78;
      c.drawRect(Rect.fromLTWH(hingeX - 4, base - 56, 8, 56), Paint()..color = _porcelainShade);
      c.drawRect(Rect.fromLTWH(jawX - 4, base - 56, 8, 56), Paint()..color = _porcelainShade);
      final jaw = Offset(jawX, base - 62);
      final jp = Path()
        ..moveTo(jaw.dx - 8, jaw.dy - 9)
        ..lineTo(jaw.dx - 8, jaw.dy + 6)
        ..lineTo(jaw.dx + 8, jaw.dy + 6)
        ..lineTo(jaw.dx + 8, jaw.dy - 9);
      c.drawPath(jp, Paint()
        ..color = _copper
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4);
      final hinge = Offset(hingeX, base - 60);
      final len = jawX - hingeX + 4;
      final a = !closed ? -70.0 : (!seated && i == stuck ? -14.0 : 0.0);
      final tip = hinge + Offset(math.cos(a * math.pi / 180), math.sin(a * math.pi / 180)) * len;
      c.drawLine(hinge, tip, Paint()
        ..color = _copper
        ..strokeWidth = 4.4
        ..strokeCap = StrokeCap.round);
      c.drawCircle(hinge, 3.6, Paint()..color = _steelDark);
      if (hot && closed && !seated && i == stuck) {
        c.drawCircle(jaw, 12, Paint()
          ..color = const Color(0xCCFF5A1F)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
      }
    }
    c.restore();
  }

  @override
  bool shouldRepaint(M6UnjamPhasePainter old) => old.closed != closed || old.seated != seated || old.stuck != stuck || old.hot != hot;
}

/// The flash of an AB closed on load: a white-blue arc at [at], fading out.
class M6UnjamFlashPainter extends CustomPainter {
  const M6UnjamFlashPainter({required this.at, required this.v});

  final Offset at;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final a = (1 - v).clamp(0.0, 1.0);
    c.drawCircle(at, 30 + 70 * v, Paint()
      ..color = const Color(0xFFBFE3FF).withValues(alpha: 0.85 * a)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18));
    c.drawCircle(at, 10 + 20 * v, Paint()..color = Colors.white.withValues(alpha: a));
    final rnd = math.Random(5);
    final bolt = Paint()
      ..color = const Color(0xFFE8F4FF).withValues(alpha: a)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    for (var k = 0; k < 6; k++) {
      final p = Path()..moveTo(at.dx, at.dy);
      var cur = at;
      final dir = rnd.nextDouble() * math.pi * 2;
      for (var s = 0; s < 4; s++) {
        cur = cur + Offset(math.cos(dir + (rnd.nextDouble() - 0.5)), math.sin(dir + (rnd.nextDouble() - 0.5))) * (10 + 12 * v);
        p.lineTo(cur.dx, cur.dy);
      }
      c.drawPath(p, bolt);
    }
  }

  @override
  bool shouldRepaint(M6UnjamFlashPainter old) => old.at != at || old.v != v;
}

/// The crew's tester as a small glyph (the re-isolation cutscene: the line
/// proved dead before the earths go back on).
class M6UnjamTesterPainter extends CustomPainter {
  const M6UnjamTesterPainter();

  @override
  void paint(Canvas c, Size size) =>
      _tester(c, Offset(size.width * 0.2, size.height * 0.98), Offset(size.width * 0.45, size.height * 0.62), scale: size.height / 48);

  @override
  bool shouldRepaint(M6UnjamTesterPainter old) => false;
}
