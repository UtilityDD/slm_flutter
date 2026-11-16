import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The drawn world of lesson 6.6 কাজ 1 "মেসেঞ্জারে ঝোলাও" (m6_abc_clamp_seat.dart).
//
// Two views, daytime, a town lane where a bare LT run is being replaced with
// AB cable (the crew's PTW, isolation, tester and earths are done: drawn at
// pole 1's foot, not scored — X1):
//
//  The lane (side view): 3 or 4 PCC poles left to right. Pole 1 is where the
//    run starts: the new cable drops down it to the feeder pillar at its foot
//    and nothing runs on to the left (an end). The middle poles are straight,
//    or the road turns at one of them: from there the road bends away into
//    the distance and the poles after it stand smaller and higher (a turn).
//    The last pole is a dead end (the cable stops there, the lane goes on
//    with no line). Each pole has a bracket near its top (a roller goes on
//    it for the pull); the drum stands at the source by pole 1. A short
//    ladder leans on the pole the trainee is working on. No labels.
//  The lens (a close-up of the pole top, side view): the AB bundle — three
//    black phase cores and the neutral-cum-messenger twisted together — runs
//    across under the open jaw of the clamp just taken up. The twist shows
//    as successive slanted segments; the one under the jaw is the core the
//    jaw would close on. Phase cores carry 1, 2 or 3 thin raised ridges along
//    their insulation (lesson pro tip 2); the messenger is bare stranded
//    aluminium, or insulated but thicker, or insulated with a subtle row of
//    printed dots (pro tip 1: different size or a special mark). Nothing
//    highlights the core under the jaw.
//
// Code-drawn, gradients, no bitmaps. Design: 360 wide × the scene's height
// (560–900); a tall phone gets more sky, never stretched poles.

/// Where the trainee is in the job.
enum M6ClampStage { pull, pole, next, done }

/// A pole's place in the run (read from the drawing, never labelled).
enum M6PoleKind { end, straight, bend }

/// The clamps in the pouch: the two AB clamps (lesson 6.6 point 2) and an
/// ordinary bare-conductor clamp (myth 2).
enum M6Clamp { suspension, tension, bare }

/// How the messenger looks this play (pro tip 1).
enum M6Messenger { bare, thick, mark }

/// Where things are (design px, 360 wide).
@immutable
class M6ClampGeo {
  const M6ClampGeo._(this.height, this.groundY, this.poles, this.bend, this.poleH);

  factory M6ClampGeo.forScene(double height, double inset, {required int poles, int? bend}) {
    final g = height - floorUp - inset * 0.5;
    final ph = (g - 340).clamp(130.0, 240.0);
    return M6ClampGeo._(height, g, poles, bend, ph);
  }

  final double height;

  /// The ground line at the poles' feet.
  final double groundY;
  final int poles;
  final int? bend;

  /// A near pole's height.
  final double poleH;

  /// The ground sits this far above the bottom (the bag row stands on it).
  static const double floorUp = 112;

  double poleX(int i) => poles == 3 ? 96.0 + 102 * i : 82.0 + 76 * i;

  /// Steps past the turn (0 before it or with no turn).
  int _past(int i) => bend == null || i <= bend! ? 0 : i - bend!;

  /// Poles past the turn stand farther: smaller and higher.
  double poleScale(int i) => math.pow(0.74, _past(i)).toDouble();
  double poleBase(int i) => groundY - 50.0 * _past(i);
  Offset poleTop(int i) => Offset(poleX(i), poleBase(i) - poleH * poleScale(i));

  /// The bracket near the top (a roller goes on it).
  Offset bracket(int i) => poleTop(i) + Offset(12 * poleScale(i), 18 * poleScale(i));
  Rect bracketHit(int i) => Rect.fromCenter(center: bracket(i), width: 42, height: 42);

  /// Where the cable rides (the roller's groove, then the clamp).
  Offset cableAt(int i) => poleTop(i) + Offset(14 * poleScale(i), 26 * poleScale(i));

  /// Tap a pole (its upper part) to go to it.
  Rect poleHit(int i) {
    final t = poleTop(i);
    return Rect.fromLTRB(t.dx - 22, t.dy - 8, t.dx + 22, t.dy + 56);
  }

  /// The drum at the source, left of pole 1.
  Offset get drum => Offset(poleX(0) - 50, groundY - 24);

  /// The trainee by the drum (the pull) or on the ladder at pole [i].
  Rect get traineeGround => Rect.fromLTWH(poleX(0) - 32, groundY - 104, 44, 104);
  Rect traineePole(int i) {
    final s = poleScale(i);
    final t = poleTop(i);
    return Rect.fromLTWH(t.dx - 42 * s, t.dy + 18 * s, 38 * s, 88 * s);
  }

  /// Empty sky (nothing to touch).
  Offset get skyEmpty => Offset(180, math.max(150.0, poleTop(0).dy - 60));

  // --- the lens --------------------------------------------------------------

  Rect get lens {
    var top = double.infinity;
    for (var i = 0; i < poles; i++) {
      top = math.min(top, poleTop(i).dy);
    }
    final h = (top - 140).clamp(170.0, 250.0);
    return Rect.fromLTWH(14, 128, 332, h);
  }

  /// The bundle's centre line in the lens.
  double get bundleY => lens.top + lens.height * 0.64;

  /// The jaw sits over this x (the core here is the one it closes on).
  double get jawX => lens.center.dx - 22;

  /// One twist segment's width.
  static const double segW = 46;

  /// Swipe up or down here to roll the bundle.
  Rect get bundleHit => Rect.fromLTRB(lens.left + 10, bundleY - 40, lens.right - 10, bundleY + 40);

  /// The clamp's bolt (hold it to close the jaw).
  Offset get bolt => Offset(lens.center.dx + 50, bundleY - 74);
  Rect get boltHit => Rect.fromCenter(center: bolt, width: 46, height: 46);

  /// Put the clamp back in the pouch.
  Rect get backHit => Rect.fromLTWH(lens.right - 50, lens.top + 4, 46, 46);

  /// A spot in the lens with nothing on it.
  Offset get lensEmpty => Offset(lens.left + 40, lens.top + 30);

  @override
  bool operator ==(Object other) =>
      other is M6ClampGeo && other.height == height && other.groundY == groundY && other.poles == poles && other.bend == bend && other.poleH == poleH;

  @override
  int get hashCode => Object.hash(height, groundY, poles, bend, poleH);
}

/// What the lane shows now.
@immutable
class M6ClampLaneRig {
  const M6ClampLaneRig({
    required this.poles,
    required this.bend,
    required this.rollers,
    required this.pulled,
    required this.seated,
    required this.at,
    required this.stage,
    this.scuffAt,
  });

  final int poles;
  final int? bend;

  /// Poles with a roller on the bracket.
  final Set<int> rollers;

  /// The cable is up over the poles.
  final bool pulled;

  /// The clamps done (pole → clamp type).
  final Map<int, M6Clamp> seated;

  /// The pole the trainee works on (the ladder), or -1 on the ground.
  final int at;
  final M6ClampStage stage;

  /// The cable scuffed on this pole's bare bracket (the slip).
  final int? scuffAt;

  @override
  bool operator ==(Object other) =>
      other is M6ClampLaneRig &&
      other.poles == poles &&
      other.bend == bend &&
      setEquals(other.rollers, rollers) &&
      other.pulled == pulled &&
      mapEquals(other.seated, seated) &&
      other.at == at &&
      other.stage == stage &&
      other.scuffAt == scuffAt;

  @override
  int get hashCode => Object.hash(poles, bend, Object.hashAllUnordered(rollers), pulled, Object.hashAllUnordered(seated.entries.map((e) => e.key * 10 + e.value.index)), at, stage, scuffAt);
}

/// The kind of pole [i] in a run of [poles] with the turn at [bend].
M6PoleKind m6PoleKind(int i, int poles, int? bend) => i == 0 || i == poles - 1 ? M6PoleKind.end : (i == bend ? M6PoleKind.bend : M6PoleKind.straight);

// ============================================================================
// The lane
// ============================================================================

class M6ClampLanePainter extends CustomPainter {
  M6ClampLanePainter({required this.geo, required this.rig, required this.pull}) : super(repaint: pull);

  final M6ClampGeo geo;
  final M6ClampLaneRig rig;

  /// The pull's progress (0 … 1; a one-shot).
  final Animation<double> pull;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = geo.height;
    final g = geo.groundY;
    // Sky.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7FB6E0), Color(0xFFCFE4F2), Color(0xFFF1E9D6)],
          stops: [0, 0.6, 1],
        ).createShader(Rect.fromLTWH(0, 0, w, g)),
    );
    // Clouds.
    final cloud = Paint()..color = const Color(0xCCFFFFFF);
    for (final c in [Offset(60, g * 0.22), Offset(250, g * 0.15), Offset(320, g * 0.3)]) {
      canvas.drawOval(Rect.fromCenter(center: c, width: 70, height: 18), cloud);
      canvas.drawOval(Rect.fromCenter(center: c + const Offset(16, -7), width: 40, height: 18), cloud);
    }
    _houses(canvas, g);
    _road(canvas, w, g);
    _source(canvas, g);
    // Poles back to front (the far ones first).
    for (var i = geo.poles - 1; i >= 0; i--) {
      _pole(canvas, i);
    }
    _cable(canvas);
    for (var i = 0; i < geo.poles; i++) {
      if (rig.rollers.contains(i) && !rig.seated.containsKey(i)) _roller(canvas, i);
      final c = rig.seated[i];
      if (c != null) _seatedClamp(canvas, i, c);
    }
    if (rig.at >= 0 && rig.at < geo.poles) _ladder(canvas, rig.at);
    final s = rig.scuffAt;
    if (s != null) _scuff(canvas, s);
  }

  void _houses(Canvas canvas, double g) {
    final wall = Paint()..color = const Color(0xFFE2C9A0);
    final wall2 = Paint()..color = const Color(0xFFD7B98C);
    final roof = Paint()..color = const Color(0xFF9C5B3B);
    final win = Paint()..color = const Color(0xFF4A5C70);
    for (var k = 0; k < 6; k++) {
      final x = 8.0 + k * 60;
      final hh = 52.0 + (k * 23 % 30);
      final r = Rect.fromLTWH(x, g - 30 - hh, 50, hh);
      canvas.drawRect(r, k.isEven ? wall : wall2);
      canvas.drawRect(Rect.fromLTWH(r.left - 2, r.top - 6, r.width + 4, 7), roof);
      for (var j = 0; j < 2; j++) {
        canvas.drawRect(Rect.fromLTWH(r.left + 8 + j * 20, r.top + 12, 11, 13), win);
      }
    }
  }

  void _road(Canvas canvas, double w, double g) {
    final road = Paint()..color = const Color(0xFF8A8478);
    final edge = Paint()
      ..color = const Color(0xFFBDB5A4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final b = geo.bend;
    final path = Path()..moveTo(0, g - 14);
    if (b == null) {
      path
        ..lineTo(w, g - 14)
        ..lineTo(w, g + 40)
        ..lineTo(0, g + 40)
        ..close();
    } else {
      // The road turns away at the bend pole into the distance.
      final bx = geo.poleX(b) + 10;
      path
        ..lineTo(bx, g - 14)
        ..quadraticBezierTo(bx + 40, g - 18, w, g - 70)
        ..lineTo(w, g - 46)
        ..quadraticBezierTo(bx + 60, g + 4, bx + 30, g + 40)
        ..lineTo(0, g + 40)
        ..close();
    }
    canvas.drawPath(path, road);
    canvas.drawPath(path, edge);
    // The verge in front.
    canvas.drawRect(Rect.fromLTWH(0, g + 40, w, geo.height - g - 40), Paint()..color = const Color(0xFF7E9B5A));
  }

  /// The drum, the feeder pillar at pole 1's foot (with the crew's
  /// isolation tag on its door), the tester and earth (staged, X1).
  void _source(Canvas canvas, double g) {
    final d = geo.drum;
    final rim = Paint()..color = const Color(0xFF8B5A2B);
    canvas.drawCircle(d, 24, rim);
    canvas.drawCircle(d, 17, Paint()..color = const Color(0xFF1E1E1E));
    canvas.drawCircle(d, 5, Paint()..color = const Color(0xFF6E4623));
    final coil = Paint()
      ..color = const Color(0xFF3A3A3A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var r = 8.0; r < 17; r += 3) {
      canvas.drawCircle(d, r, coil);
    }
    canvas.drawRect(Rect.fromLTWH(d.dx - 26, g - 4, 52, 5), Paint()..color = const Color(0xFF5B4A3A));
    // The feeder pillar (the source) by pole 1.
    final p0 = geo.poleX(0);
    final box = Rect.fromLTWH(p0 + 8, g - 44, 26, 40);
    canvas.drawRRect(
      RRect.fromRectAndRadius(box, const Radius.circular(3)),
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFF6C7A6A), Color(0xFF4A574A)]).createShader(box),
    );
    canvas.drawLine(Offset(box.center.dx, box.top + 6), Offset(box.center.dx, box.bottom - 6), Paint()..color = const Color(0xFF2E382E));
    // The isolation tag hung on the pillar door (the switch is open; X1).
    final tag = Rect.fromLTWH(box.center.dx + 2, box.top + 10, 9, 13);
    canvas.drawLine(Offset(tag.center.dx, box.top + 6), Offset(tag.center.dx, tag.top), Paint()
      ..color = const Color(0xFF2E2E2E)
      ..strokeWidth = 0.8);
    canvas.drawRect(tag, Paint()..color = const Color(0xFFF2EEE4));
    canvas.drawRect(Rect.fromLTWH(tag.left, tag.top + 3, tag.width, 3.5), Paint()..color = const Color(0xFFC62828));
    // The crew's earth rod and lead, and the tester leaning on it (X1).
    final rod = Offset(p0 + 46, g + 2);
    canvas.drawLine(rod, rod + const Offset(0, -26), Paint()
      ..color = const Color(0xFF9A6A3A)
      ..strokeWidth = 3);
    canvas.drawLine(rod + const Offset(0, -24), Offset(box.right, box.top + 10), Paint()
      ..color = const Color(0xFF2E7D32)
      ..strokeWidth = 1.6);
    final tester = RRect.fromRectAndRadius(Rect.fromLTWH(rod.dx + 5, rod.dy - 30, 7, 26), const Radius.circular(3));
    canvas.drawRRect(tester, Paint()..color = const Color(0xFFF2C230));
    canvas.drawCircle(Offset(rod.dx + 8.5, rod.dy - 26), 2.4, Paint()..color = const Color(0xFF34C759));
  }

  void _pole(Canvas canvas, int i) {
    final s = geo.poleScale(i);
    final top = geo.poleTop(i);
    final base = geo.poleBase(i);
    final wTop = 7 * s;
    final wBase = 12 * s;
    final path = Path()
      ..moveTo(top.dx - wTop / 2, top.dy)
      ..lineTo(top.dx + wTop / 2, top.dy)
      ..lineTo(top.dx + wBase / 2, base)
      ..lineTo(top.dx - wBase / 2, base)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFFB9B6AE), Color(0xFF8E8B83), Color(0xFFA9A69E)]).createShader(Rect.fromLTRB(top.dx - wBase, top.dy, top.dx + wBase, base)),
    );
    // The bracket (a short arm with an eye).
    final b = geo.bracket(i);
    final arm = Paint()
      ..color = const Color(0xFF5E636B)
      ..strokeWidth = 3 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(top.dx + wTop / 2, b.dy - 6 * s), b, arm);
    canvas.drawCircle(b, 3 * s, Paint()..color = const Color(0xFF41464E));
    // Its foot in the ground.
    canvas.drawOval(Rect.fromCenter(center: Offset(top.dx, base), width: 22 * s, height: 5 * s), Paint()..color = const Color(0x55302A20));
  }

  /// The cable: on the drum before the pull, then over the poles (the pull
  /// draws it out to the last pole, or to the scuffed one).
  void _cable(Canvas canvas) {
    final cable = Paint()
      ..color = const Color(0xFF1A1A1A)
      ..strokeWidth = 3.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final pts = [for (var i = 0; i < geo.poles; i++) geo.cableAt(i)];
    final up = rig.pulled ? 1.0 : pull.value;
    if (up <= 0) return;
    final last = rig.scuffAt ?? geo.poles - 1;
    // From the drum up pole 1, then span by span.
    final d = geo.drum;
    final path = Path()..moveTo(d.dx + 10, d.dy - 16);
    path.quadraticBezierTo(pts[0].dx - 20, pts[0].dy + 30, pts[0].dx, pts[0].dy);
    final spans = math.max(1, last);
    final reach = up * spans;
    for (var k = 0; k < last; k++) {
      final a = pts[k];
      final b = pts[k + 1];
      final f = (reach - k).clamp(0.0, 1.0);
      if (f <= 0) break;
      final sag = 10 + (b.dx - a.dx) * 0.08;
      final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2 + sag);
      if (f >= 1) {
        path.quadraticBezierTo(mid.dx, mid.dy, b.dx, b.dy);
      } else {
        // A partial span: the head of the cable on its way.
        final t = f;
        final q0 = Offset.lerp(a, mid, t)!;
        final q1 = Offset.lerp(mid, b, t)!;
        final head = Offset.lerp(q0, q1, t)!;
        path.quadraticBezierTo(q0.dx, q0.dy, head.dx, head.dy);
      }
    }
    canvas.drawPath(path, cable);
    // Pole 1 is the start: once up and clamped, a drop down to the pillar.
    if (rig.pulled && rig.seated.containsKey(0)) {
      final p0 = geo.poleX(0);
      canvas.drawLine(pts[0], Offset(p0 + 21, geo.groundY - 44), cable..strokeWidth = 2.6);
    }
  }

  void _roller(Canvas canvas, int i) {
    final s = geo.poleScale(i);
    final c = geo.cableAt(i);
    final frame = Paint()
      ..color = const Color(0xFFE0A21B)
      ..strokeWidth = 2 * s
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(c + Offset(0, 4 * s), 6 * s, Paint()..color = const Color(0xFF3B3F45));
    canvas.drawCircle(c + Offset(0, 4 * s), 6 * s, frame);
    canvas.drawLine(geo.bracket(i), c + Offset(0, 4 * s), frame);
  }

  void _seatedClamp(Canvas canvas, int i, M6Clamp c) {
    final s = geo.poleScale(i);
    final p = geo.cableAt(i);
    final metal = Paint()..color = const Color(0xFF9AA3AD);
    final dark = Paint()..color = const Color(0xFF59616B);
    switch (c) {
      case M6Clamp.suspension:
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: p, width: 12 * s, height: 7 * s), Radius.circular(3 * s)), metal);
        canvas.drawLine(geo.bracket(i), p, dark..strokeWidth = 2 * s);
      case M6Clamp.tension:
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: p + Offset(6 * s, 0), width: 20 * s, height: 6 * s), Radius.circular(3 * s)), metal);
        canvas.drawLine(geo.bracket(i), p, dark..strokeWidth = 2 * s);
      case M6Clamp.bare:
        canvas.drawRect(Rect.fromCenter(center: p, width: 12 * s, height: 9 * s), dark);
    }
  }

  void _ladder(Canvas canvas, int i) {
    final s = geo.poleScale(i);
    final top = geo.poleTop(i);
    final base = geo.poleBase(i);
    final rail = Paint()
      ..color = const Color(0xFFB07A3E)
      ..strokeWidth = 2.4 * s;
    final a = Offset(top.dx - 6 * s, top.dy + 40 * s);
    final b = Offset(top.dx - 28 * s, base);
    final a2 = a + Offset(-9 * s, 0);
    final b2 = b + Offset(-9 * s, 0);
    canvas.drawLine(a, b, rail);
    canvas.drawLine(a2, b2, rail);
    for (var k = 1; k < 10; k++) {
      final t = k / 10;
      canvas.drawLine(Offset.lerp(a, b, t)!, Offset.lerp(a2, b2, t)!, rail..strokeWidth = 1.6 * s);
    }
  }

  void _scuff(Canvas canvas, int i) {
    final c = geo.cableAt(i);
    final p = Paint()
      ..color = const Color(0xFFE85A2A)
      ..strokeWidth = 1.6;
    for (var k = 0; k < 6; k++) {
      final a = k * math.pi / 3;
      canvas.drawLine(c, c + Offset(math.cos(a), math.sin(a)) * 9, p);
    }
    canvas.drawCircle(c, 4, Paint()..color = const Color(0xFFF4C27A));
  }

  @override
  bool shouldRepaint(M6ClampLanePainter old) => old.geo != geo || old.rig != rig || old.pull != pull;
}

// ============================================================================
// The lens
// ============================================================================

/// What the lens shows now.
@immutable
class M6ClampLensRig {
  const M6ClampLensRig({
    required this.clamp,
    required this.order,
    required this.top,
    required this.messenger,
    required this.closed,
  });

  final M6Clamp clamp;

  /// The cores round the bundle: 0 the messenger, 1–3 the phase cores
  /// (their ridge count).
  final List<int> order;

  /// The index in [order] now under the jaw.
  final int top;
  final M6Messenger messenger;

  /// The jaw is closed on the core under it.
  final bool closed;

  @override
  bool operator ==(Object other) =>
      other is M6ClampLensRig && other.clamp == clamp && listEquals(other.order, order) && other.top == top && other.messenger == messenger && other.closed == closed;

  @override
  int get hashCode => Object.hash(clamp, Object.hashAll(order), top, messenger, closed);
}

class M6ClampLensPainter extends CustomPainter {
  M6ClampLensPainter({required this.geo, required this.rig, required this.roll}) : super(repaint: roll);

  final M6ClampGeo geo;
  final M6ClampLensRig rig;

  /// The roll's leftover offset in segments (−1 … 1 → 0; a one-shot).
  final Animation<double> roll;

  static const _black = Color(0xFF1C1D20);

  @override
  void paint(Canvas canvas, Size size) {
    final l = geo.lens;
    final rr = RRect.fromRectAndRadius(l, const Radius.circular(22));
    canvas.drawRRect(
      rr,
      Paint()
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF9CC7E6), Color(0xFFD9EAF3)]).createShader(l),
    );
    canvas.save();
    canvas.clipRRect(rr);
    // The pole and its bracket arm on the left.
    final pole = Rect.fromLTWH(l.left + 6, l.top, 30, l.height);
    canvas.drawRect(pole, Paint()..shader = const LinearGradient(colors: [Color(0xFFB9B6AE), Color(0xFF8E8B83)]).createShader(pole));
    final armY = geo.bundleY - 92;
    canvas.drawLine(Offset(pole.right, armY), Offset(geo.jawX - 30, armY), Paint()
      ..color = const Color(0xFF5E636B)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round);
    _bundle(canvas, l);
    _clamp(canvas);
    canvas.restore();
    // The back button (put the clamp back): an arrow into the pouch.
    final b = geo.backHit;
    canvas.drawCircle(b.center, 16, Paint()..color = const Color(0xCC0B1324));
    final arrow = Paint()
      ..color = const Color(0xFFF7F1DE)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(b.center + const Offset(-6, -6), b.center + const Offset(6, 6), arrow);
    canvas.drawLine(b.center + const Offset(6, -6), b.center + const Offset(-6, 6), arrow);
    canvas.drawRRect(rr, Paint()
      ..color = const Color(0xFFE8C66A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
  }

  int _coreAt(int k) => rig.order[((rig.top + k) % 4 + 4) % 4];

  void _bundle(Canvas canvas, Rect l) {
    final y = geo.bundleY;
    // The bundle behind (the cores out of sight).
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTRB(l.left - 4, y - 16, l.right + 4, y + 20), const Radius.circular(14)),
      Paint()..color = const Color(0xFF101114),
    );
    final shift = roll.value;
    for (var k = -5; k <= 5; k++) {
      final cx = geo.jawX + (k + shift) * M6ClampGeo.segW;
      if (cx < l.left - 60 || cx > l.right + 60) continue;
      _segment(canvas, Offset(cx, y), _coreAt(k));
    }
  }

  /// One visible twist of a core, slanted.
  void _segment(Canvas canvas, Offset c, int core) {
    final messenger = core == 0;
    final thick = messenger && rig.messenger == M6Messenger.thick;
    final hh = thick ? 19.0 : 15.0;
    const half = M6ClampGeo.segW / 2 + 3;
    final path = Path()
      ..moveTo(c.dx - half + 8, c.dy - hh)
      ..lineTo(c.dx + half + 8, c.dy - hh)
      ..quadraticBezierTo(c.dx + half + 2, c.dy, c.dx + half - 8, c.dy + hh)
      ..lineTo(c.dx - half - 8, c.dy + hh)
      ..quadraticBezierTo(c.dx - half - 2, c.dy, c.dx - half + 8, c.dy - hh)
      ..close();
    final box = Rect.fromCenter(center: c, width: half * 2 + 16, height: hh * 2);
    if (messenger && rig.messenger == M6Messenger.bare) {
      // Bare stranded aluminium.
      canvas.drawPath(
        path,
        Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE6E9EC), Color(0xFF9EA6AE), Color(0xFFC7CDD3)]).createShader(box),
      );
      final strand = Paint()
        ..color = const Color(0xFF7E868F)
        ..strokeWidth = 1;
      for (var x = -half; x < half; x += 5) {
        canvas.drawLine(Offset(c.dx + x + 6, c.dy - hh + 1), Offset(c.dx + x - 4, c.dy + hh - 1), strand);
      }
    } else {
      canvas.drawPath(
        path,
        Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF4A4C52), _black, Color(0xFF2A2B30)]).createShader(box),
      );
      if (messenger && rig.messenger == M6Messenger.mark) {
        // A subtle printed row of dots (not a ridge).
        final dot = Paint()..color = const Color(0xFF85888F);
        for (var x = -half + 6; x < half - 2; x += 8) {
          canvas.drawCircle(Offset(c.dx + x + 2, c.dy - 2), 1.8, dot);
        }
      } else if (!messenger) {
        // Raised ridges along the insulation: 1, 2 or 3.
        final ridge = Paint()
          ..color = const Color(0xFF8E9299)
          ..strokeWidth = 1.8;
        for (var r = 0; r < core; r++) {
          final dy = -hh + 4 + r * 4.0;
          canvas.drawLine(Offset(c.dx - half + 6, c.dy + dy), Offset(c.dx + half + 4, c.dy + dy), ridge);
        }
      }
    }
    canvas.drawPath(path, Paint()
      ..color = const Color(0xFF0A0A0C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);
  }

  void _clamp(Canvas canvas) {
    final x = geo.jawX;
    final y = geo.bundleY;
    final jawY = rig.closed ? y - 14 : y - 44;
    final metal = Paint()
      ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFD5DBE1), Color(0xFF8C959F)]).createShader(Rect.fromLTWH(x - 60, jawY - 60, 160, 80));
    final dark = Paint()..color = const Color(0xFF4E565F);
    final hang = Paint()
      ..color = const Color(0xFF5E636B)
      ..strokeWidth = 4;
    final armY = y - 92;
    switch (rig.clamp) {
      case M6Clamp.suspension:
        // A short cradle hung from the arm.
        canvas.drawLine(Offset(x, armY), Offset(x, jawY - 18), hang);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 26, jawY - 20, 52, 16), const Radius.circular(8)), metal);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 20, jawY - 6, 40, 8), const Radius.circular(4)), dark);
      case M6Clamp.tension:
        // A long wedge body on a bail back to the pole.
        canvas.drawLine(Offset(x - 40, armY), Offset(x - 30, jawY - 10), hang);
        final body = Path()
          ..moveTo(x - 34, jawY - 18)
          ..lineTo(x + 44, jawY - 10)
          ..lineTo(x + 44, jawY + 2)
          ..lineTo(x - 34, jawY + 2)
          ..close();
        canvas.drawPath(body, metal);
        canvas.drawRect(Rect.fromLTWH(x - 20, jawY - 2, 40, 5), dark);
      case M6Clamp.bare:
        // An ordinary bolted bare-conductor clamp: a serrated plate, two U-bolts.
        canvas.drawLine(Offset(x, armY), Offset(x, jawY - 18), hang);
        canvas.drawRect(Rect.fromLTWH(x - 28, jawY - 18, 56, 14), dark);
        final saw = Paint()..color = const Color(0xFFB8BEC4);
        for (var k = 0; k < 5; k++) {
          final sx = x - 20 + k * 8.0;
          canvas.drawPath(
            Path()
              ..moveTo(sx, jawY - 4)
              ..lineTo(sx + 4, jawY + 2)
              ..lineTo(sx + 8, jawY - 4)
              ..close(),
            saw,
          );
        }
        final u = Paint()
          ..color = const Color(0xFF8C959F)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;
        for (final ux in [x - 18, x + 18]) {
          canvas.drawArc(Rect.fromCenter(center: Offset(ux, jawY + 2), width: 14, height: 18), 0, math.pi, false, u);
        }
    }
    // The bolt and the link to it.
    final b = geo.bolt;
    canvas.drawLine(Offset(x + 20, jawY - 12), b, Paint()
      ..color = const Color(0xFF7A838C)
      ..strokeWidth = 3);
    final hex = Path();
    for (var k = 0; k < 6; k++) {
      final a = k * math.pi / 3;
      final p = b + Offset(math.cos(a), math.sin(a)) * 11;
      k == 0 ? hex.moveTo(p.dx, p.dy) : hex.lineTo(p.dx, p.dy);
    }
    hex.close();
    canvas.drawPath(hex, Paint()..color = const Color(0xFFB5BCC4));
    canvas.drawPath(hex, Paint()
      ..color = const Color(0xFF4E565F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4);
    canvas.drawCircle(b, 4, dark);
  }

  @override
  bool shouldRepaint(M6ClampLensPainter old) => old.geo != geo || old.rig != rig || old.roll != roll;
}

/// The shock at the bare hand (deadly): a flash in colour over the grey.
class M6ClampFlashPainter extends CustomPainter {
  M6ClampFlashPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas canvas, Size size) {
    final r = 20 + 70 * v;
    canvas.drawCircle(
      at,
      r,
      Paint()..shader = RadialGradient(colors: [Color.fromRGBO(255, 255, 230, 0.95 * (1 - v * 0.5)), const Color(0x00FFE066)]).createShader(Rect.fromCircle(center: at, radius: r)),
    );
    final bolt = Paint()
      ..color = const Color(0xFFFFE066)
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke;
    for (var k = 0; k < 5; k++) {
      final a = k * 2 * math.pi / 5 + 0.3;
      final p = Path()..moveTo(at.dx, at.dy);
      var q = at;
      for (var j = 1; j <= 3; j++) {
        q = at + Offset(math.cos(a + (j.isEven ? 0.25 : -0.25)), math.sin(a + (j.isEven ? 0.25 : -0.25))) * (r * j / 3);
        p.lineTo(q.dx, q.dy);
      }
      canvas.drawPath(p, bolt);
    }
  }

  @override
  bool shouldRepaint(M6ClampFlashPainter old) => old.at != at || old.v != v;
}
