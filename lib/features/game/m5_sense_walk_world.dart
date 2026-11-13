import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The drawn world of lesson 5.2 কাজ 2 "থামুন, দেখুন, শুনুন" (m5_sense_walk.dart):
// a daytime village road beside one 11 kV section, between two FPI poles. The
// line runs along the far edge of a dusty path; the trainee walks the path
// from left to right (the camera follows him, he stays at [SenseWalkGeo.manX]).
// Potholes and ruts on the path, a culvert, fields and a tree line far off
// (parallax), maybe a pole-mounted DTR.
//
// Two views:
//  • eyes down (the ground view, [SenseWalkPainter]): whole poles, their
//    bodies, bases and stays, the path and anything lying on it;
//  • eyes up (a close look at the nearest pole's top, [SenseTopPainter]): the
//    cross-arm, its three insulators and the conductors either side.
// Every pole draws the same parts in the same detail (no clue stands out by
// detail); the clues (a cracked insulator, a kite / bird on the wire, a branch
// on the wire, a vehicle scrape, a damaged base, a slack stay, a dirt layer on
// an insulator) are drawn small and plain, no ring, no glow, no text.
//
// The fallen wire: one conductor of one span broken, both halves down, a piece
// lying across the path on dry soil or road pitch. No spark, no mark on the
// ground, no 10 m line. The rope ring is drawn only once the player lays it.
//
// Design: 360 wide × the scene's height; the path follows the bottom of the
// screen (a tall phone gets taller poles and more sky, never stretched).
// Distances: the world is in metres along the road; 8 design px a metre.

/// Design px per metre along the road.
const double kSensePxPerM = 8;

/// Metres between poles.
const double kSenseSpan = 30;

/// Where pole 0 (the near FPI pole) stands, metres.
const double kSensePole0 = 20;

/// Where the trainee starts, metres.
const double kSenseStart = 4;

/// The lying piece of the fallen wire reaches this far either side of its
/// middle (metres).
const double kSenseWireHalf = 1.5;

/// The safe distance from a fallen wire (lesson 5.2 point 3: 'কমপক্ষে ১০ মিটার').
const double kSenseZone = 10;

/// How far ahead of the trainee the screen shows (metres).
const double kSenseSeeAhead = (360 - SenseWalkGeo.manX) / kSensePxPerM;

/// Pole [i]'s place along the road (metres).
double sensePoleX(int i) => kSensePole0 + kSenseSpan * i;

/// The parts a player can tag. Eyes down: the pole body, its base, the stay's
/// anchor, the DTR tank. Eyes up: the three insulators, the conductors to the
/// left and to the right of the pole.
enum SensePart { body, base, anchor, tank, ins0, ins1, ins2, wireL, wireR }

const senseDownParts = [SensePart.body, SensePart.base, SensePart.anchor, SensePart.tank];
const senseUpParts = [SensePart.ins0, SensePart.ins1, SensePart.ins2, SensePart.wireL, SensePart.wireR];

/// The eye-up clue (lesson 5.2 point 2, "চোখ দিয়ে দেখুন (ওপরে)").
enum SenseUpKind { crack, kite, branch, bird }

/// The eye-down clue ("চোখ দিয়ে দেখুন (নিচে)").
enum SenseDownKind { vehicle, base, anchor }

/// The hidden clue: the ear (a hiss at a pole whose insulator shows only a
/// dirt layer) or the nose (a burnt-insulation / oil smell at the DTR).
enum SenseHidden { ear, nose }

/// What the fallen wire lies on (the lesson's myth reality: dry soil, pitch).
enum SenseGround { soil, pitch }

/// The deadly consequence drawn in colour over the frozen scene.
enum SenseHarm { zone, stride, touch }

/// A tag's key (pole, part).
int senseTagKey(int pole, SensePart p) => pole * 16 + p.index;

SensePart senseInsPart(int i) => [SensePart.ins0, SensePart.ins1, SensePart.ins2][i];

/// What this play's section looks like (dealt fresh; see m5_sense_walk.dart).
@immutable
class SenseLayout {
  const SenseLayout({
    required this.poles,
    required this.upPole,
    required this.upKind,
    required this.upPart,
    required this.downPole,
    required this.downKind,
    required this.hiddenPole,
    required this.hidden,
    required this.dirtyIns,
    required this.noseOil,
    required this.dtrPoles,
    required this.stays,
    required this.posterPole,
    required this.treePole,
    required this.treeRight,
    required this.brickPole,
    required this.potholes,
    required this.culvertX,
    required this.ground,
    required this.seed,
  });

  /// Number of poles (5–7); 0 and the last carry the FPIs.
  final int poles;
  final int upPole;
  final SenseUpKind upKind;

  /// The part the eye-up clue is on (an insulator for a crack, a side's wire
  /// for a kite, a bird or a branch).
  final SensePart upPart;
  final int downPole;
  final SenseDownKind downKind;
  final int hiddenPole;
  final SenseHidden hidden;

  /// The insulator with the dirt layer (ear clue).
  final int dirtyIns;

  /// The nose clue smells of oil (else burnt insulation).
  final bool noseOil;

  /// The poles with a DTR (the same look, smell or not): the nose pole and /
  /// or decoys. Every play has at least one, so a DTR on screen tells nothing.
  final Set<int> dtrPoles;

  /// Poles with a stay wire (and its anchor on the ground).
  final Set<int> stays;

  /// Decoys: a poster on a pole body; a tree beside a pole, its crown clear of
  /// the wires (side: [treeRight]); a brick pile by a pole.
  final int posterPole;
  final int? treePole;
  final bool treeRight;
  final int brickPole;

  /// Potholes on the path (metres).
  final List<double> potholes;
  final double culvertX;

  /// What the fallen wire lies on.
  final SenseGround ground;
  final int seed;

  double get endX => sensePoleX(poles - 1);

  /// The part the eye-down clue is on.
  SensePart get downPart => switch (downKind) {
        SenseDownKind.vehicle => SensePart.body,
        SenseDownKind.base => SensePart.base,
        SenseDownKind.anchor => SensePart.anchor,
      };

  /// The part the hidden clue is on.
  SensePart get hiddenPart => hidden == SenseHidden.ear ? senseInsPart(dirtyIns) : SensePart.tank;

  /// The insulator on [pole] with a dirt layer, or null. The ear pole always
  /// has one ([dirtyIns]); about half the other poles carry a decoy layer, so
  /// the dirt alone does not show the hiss pole (ruling M5-10: tag on the
  /// ear's evidence).
  int? dirtAt(int pole) {
    if (hidden == SenseHidden.ear && pole == hiddenPole) return dirtyIns;
    if (_hash(seed, pole + 7) >= 0.5) return null;
    return (_hash(seed, pole + 31) * 3).floor().clamp(0, 2);
  }

  /// The pole nearest to [x] (metres).
  int nearestPole(double x) => ((x - kSensePole0) / kSenseSpan).round().clamp(0, poles - 1);
}

/// What changes during a play.
@immutable
class SenseLive {
  const SenseLive({required this.tags, this.wireX, this.cordon, this.dragR, this.dropped = false});

  /// Tagged parts ([senseTagKey]).
  final Set<int> tags;

  /// The middle of the fallen wire (metres), or null (not fallen yet).
  final double? wireX;

  /// The rope ring laid (its distance from the wire, metres), or null.
  final double? cordon;

  /// The ring being dragged out (metres from the wire), or null.
  final double? dragR;

  /// The wire fell in front of him (the drop variant): the fall animates.
  final bool dropped;

  @override
  bool operator ==(Object other) =>
      other is SenseLive &&
      setEquals(other.tags, tags) &&
      other.wireX == wireX &&
      other.cordon == cordon &&
      other.dragR == dragR &&
      other.dropped == dropped;

  @override
  int get hashCode => Object.hash(Object.hashAllUnordered(tags), wireX, cordon, dragR, dropped);
}

/// Where things are on the ground view (design px, 360 wide).
@immutable
class SenseWalkGeo {
  const SenseWalkGeo._(this.height, this.feetY);

  factory SenseWalkGeo.forScene(double height, double inset) => SenseWalkGeo._(height, height - floorUpFor(height) - inset);

  final double height;

  /// The trainee's feet (the middle of the path).
  final double feetY;

  /// The feet stand this far above the bottom: the walk strip and the corner
  /// guide (his bubble) sit under them.
  static double floorUpFor(double height) => (height * 0.24).clamp(122.0, 190.0);

  /// The trainee stays here on screen; the world scrolls.
  static const double manX = 150;

  /// The poles' feet (the far edge of the path).
  double get baseY => feetY - 44;

  /// The pole tops.
  double get topY => math.max(150.0, baseY - 330);
  double get poleH => baseY - topY;
  double get armY => topY + 24;
  double get tankTop => topY + math.min(poleH * 0.40, poleH - 170);

  /// The horizon (fields meet the sky).
  double get horizonY => baseY - 70;

  /// The middle of the path band (where the lying wire and the rope ring are).
  double get pathMidY => (baseY + feetY) / 2 + 6;

  /// World metres → screen x, with the trainee at [pos].
  double sx(double wx, double pos) => manX + (wx - pos) * kSensePxPerM;

  /// Screen x → world metres.
  double wx(double sx, double pos) => pos + (sx - manX) / kSensePxPerM;

  /// The insulator tops of a pole standing at screen [x] (left, top, right).
  List<Offset> insTops(double x) => [Offset(x - 26, armY - 12), Offset(x, topY - 8), Offset(x + 26, armY - 12)];

  /// A tap zone of an eye-down part on a pole standing at screen [x].
  Rect partRect(SensePart p, double x) => switch (p) {
        SensePart.body => Rect.fromLTRB(x - 16, baseY - 100, x + 16, baseY - 26),
        SensePart.base => Rect.fromLTRB(x - 22, baseY - 26, x + 22, baseY + 10),
        SensePart.anchor => Rect.fromCenter(center: Offset(x + 54, baseY + 2), width: 36, height: 30),
        SensePart.tank => Rect.fromLTWH(x + 6, tankTop - 6, 46, 62),
        _ => Rect.zero,
      };

  /// The trainee's box.
  Rect get man => Rect.fromLTWH(manX - 28, feetY - 112, 56, 112);

  /// His feet (the drop variant's drag starts here).
  Rect get feet => Rect.fromCenter(center: Offset(manX, feetY - 30), width: 104, height: 96);

  /// The rope reel at his feet.
  Rect get reel => Rect.fromCenter(center: Offset(manX + 44, feetY - 12), width: 52, height: 44);

  /// The rope ring round a wire at screen [x] with radius [r] metres from the wire.
  Rect ring(double x, double r) {
    final rx = (r + kSenseWireHalf) * kSensePxPerM;
    final ry = (feetY - baseY) / 2 + 22;
    return Rect.fromCenter(center: Offset(x, pathMidY), width: rx * 2, height: ry * 2);
  }

  @override
  bool operator ==(Object other) => other is SenseWalkGeo && other.height == height && other.feetY == feetY;

  @override
  int get hashCode => Object.hash(height, feetY);
}

/// Where things are on the eye-up view (design px, 360 wide).
@immutable
class SenseTopGeo {
  const SenseTopGeo._(this.height);
  factory SenseTopGeo.forScene(double height) => SenseTopGeo._(height);

  final double height;

  double get armY => height * 0.42;
  static const List<double> insX = [100, 180, 260];

  /// Insulator [i]'s top (the conductor sits there); the cross-arm is drawn
  /// a little aslant so the three conductors run at three heights.
  Offset insTop(int i) => Offset(insX[i], armY - 50 + (i - 1) * 12.0);

  /// The conductor of phase [i] at screen [x].
  double wireY(int i, double x) {
    final t = insTop(i);
    final d = (x - t.dx).abs() / 180;
    return t.dy + 26 * d * d;
  }

  Rect partRect(SensePart p) => switch (p) {
        SensePart.ins0 => Rect.fromCenter(center: Offset(insX[0], armY - 22), width: 60, height: 90),
        SensePart.ins1 => Rect.fromCenter(center: Offset(insX[1], armY - 22), width: 60, height: 90),
        SensePart.ins2 => Rect.fromCenter(center: Offset(insX[2], armY - 22), width: 60, height: 90),
        SensePart.wireL => Rect.fromLTRB(0, armY - 130, 70, armY + 10),
        SensePart.wireR => Rect.fromLTRB(290, armY - 130, 360, armY + 10),
        _ => Rect.zero,
      };

  @override
  bool operator ==(Object other) => other is SenseTopGeo && other.height == height;

  @override
  int get hashCode => height.hashCode;
}

// ============================================================================
// Paint helpers
// ============================================================================

const _concrete = Color(0xFFA9ADB0);
const _concreteDark = Color(0xFF7D8287);
const _steel = Color(0xFF5E666E);
const _wire = Color(0xFF30363C);
const _porcelain = Color(0xFF8C4A2C);
const _porcelainLit = Color(0xFFB8683F);
const _tag = Color(0xFFE53935);

double _hash(int a, int b) {
  final v = math.sin(a * 12.9898 + b * 78.233) * 43758.5453;
  return v - v.floorToDouble();
}

void _tagRibbon(Canvas c, Offset at, double s) {
  final p = Paint()..color = _tag;
  c.drawLine(at, at + Offset(0, -10 * s), Paint()
    ..color = const Color(0xFF3A2A20)
    ..strokeWidth = 1.4 * s);
  c.drawPath(
    Path()
      ..moveTo(at.dx, at.dy - 10 * s)
      ..lineTo(at.dx + 14 * s, at.dy - 14 * s)
      ..lineTo(at.dx + 10 * s, at.dy - 9 * s)
      ..lineTo(at.dx + 14 * s, at.dy - 4 * s)
      ..lineTo(at.dx, at.dy - 6 * s)
      ..close(),
    p,
  );
}

void _kite(Canvas c, Offset at, double s) {
  final body = Path()
    ..moveTo(at.dx, at.dy - 14 * s)
    ..lineTo(at.dx + 9 * s, at.dy)
    ..lineTo(at.dx, at.dy + 16 * s)
    ..lineTo(at.dx - 9 * s, at.dy)
    ..close();
  c.drawPath(body, Paint()..color = const Color(0xFFE8B21E));
  c.drawPath(
    Path()
      ..moveTo(at.dx, at.dy - 14 * s)
      ..lineTo(at.dx + 9 * s, at.dy)
      ..lineTo(at.dx, at.dy + 16 * s)
      ..close(),
    Paint()..color = const Color(0xFFD9452B),
  );
  final tail = Paint()
    ..color = const Color(0xFF3F7FD0)
    ..strokeWidth = 1.6 * s
    ..style = PaintingStyle.stroke;
  c.drawPath(
    Path()
      ..moveTo(at.dx, at.dy + 16 * s)
      ..quadraticBezierTo(at.dx + 8 * s, at.dy + 26 * s, at.dx - 2 * s, at.dy + 34 * s)
      ..quadraticBezierTo(at.dx - 10 * s, at.dy + 42 * s, at.dx + 2 * s, at.dy + 50 * s),
    tail,
  );
}

void _bird(Canvas c, Offset at, double s) {
  // A bird caught on the wire, hanging (wings out).
  final p = Paint()..color = const Color(0xFF2E2A2A);
  c.drawOval(Rect.fromCenter(center: at + Offset(0, 9 * s), width: 9 * s, height: 15 * s), p);
  c.drawPath(
    Path()
      ..moveTo(at.dx - 3 * s, at.dy + 6 * s)
      ..lineTo(at.dx - 15 * s, at.dy + 2 * s)
      ..lineTo(at.dx - 4 * s, at.dy + 12 * s)
      ..close(),
    p,
  );
  c.drawPath(
    Path()
      ..moveTo(at.dx + 3 * s, at.dy + 6 * s)
      ..lineTo(at.dx + 15 * s, at.dy + 2 * s)
      ..lineTo(at.dx + 4 * s, at.dy + 12 * s)
      ..close(),
    p,
  );
  c.drawCircle(at + Offset(0, 18 * s), 3.2 * s, p);
  c.drawLine(at, at + Offset(0, 3 * s), Paint()
    ..color = const Color(0xFF6B5B4B)
    ..strokeWidth = 1.2 * s);
}

void _tree(Canvas c, Offset foot, double h, double s, {Offset? reach}) {
  final trunk = Paint()..color = const Color(0xFF6B4A2E);
  c.drawRect(Rect.fromLTWH(foot.dx - 4 * s, foot.dy - h * 0.45, 8 * s, h * 0.45), trunk);
  final crown = Paint()..color = const Color(0xFF3E7D3A);
  final crown2 = Paint()..color = const Color(0xFF4F9447);
  final top = foot.dy - h;
  c.drawCircle(Offset(foot.dx, top + h * 0.32), h * 0.30, crown);
  c.drawCircle(Offset(foot.dx - h * 0.18, top + h * 0.42), h * 0.22, crown2);
  c.drawCircle(Offset(foot.dx + h * 0.18, top + h * 0.40), h * 0.22, crown);
  if (reach != null) {
    final from = Offset(foot.dx, top + h * 0.3);
    c.drawPath(
      Path()
        ..moveTo(from.dx, from.dy)
        ..quadraticBezierTo((from.dx + reach.dx) / 2, from.dy - 6 * s, reach.dx, reach.dy),
      Paint()
        ..color = const Color(0xFF6B4A2E)
        ..strokeWidth = 3 * s
        ..style = PaintingStyle.stroke,
    );
    for (var k = 0; k < 4; k++) {
      final t = 0.55 + k * 0.15;
      final at = Offset.lerp(from, reach, t)!;
      c.drawOval(Rect.fromCenter(center: at + Offset(0, -3 * s), width: 10 * s, height: 6 * s), crown2);
    }
  }
}

// ============================================================================
// The ground view
// ============================================================================

class SenseWalkPainter extends CustomPainter {
  SenseWalkPainter({required this.geo, required this.layout, required this.live, required this.pos, this.drop, this.dropSpot})
      : super(repaint: Listenable.merge([pos, ?drop]));

  /// Drop variant: where the wire will land (its ground is there all along).
  final double? dropSpot;

  final SenseWalkGeo geo;
  final SenseLayout layout;
  final SenseLive live;
  final ValueListenable<double> pos;

  /// The fall of the wire in the drop variant (0 → 1).
  final Animation<double>? drop;

  @override
  void paint(Canvas canvas, Size size) {
    final p = pos.value;
    final g = geo;
    _sky(canvas, g);
    _far(canvas, g, p);
    _path(canvas, g, p);
    final wx = live.wireX;
    final dropT = live.dropped ? (drop?.value ?? 1.0) : 1.0;
    final spot = wx ?? dropSpot;
    _patches(canvas, g, p, spot);
    if (spot != null) _groundPatch(canvas, g, g.sx(spot, p), 1, layout.ground, 999);
    _potholes(canvas, g, p);
    final ring = live.cordon ?? live.dragR;
    if (wx != null && ring != null) _ring(canvas, g, g.sx(wx, p), ring, laid: live.cordon != null);
    for (var i = 0; i < layout.poles; i++) {
      final x = g.sx(sensePoleX(i), p);
      if (x < -140 || x > 500) continue;
      _behindPole(canvas, g, i, x);
    }
    _wires(canvas, g, p, wx, dropT);
    for (var i = 0; i < layout.poles; i++) {
      final x = g.sx(sensePoleX(i), p);
      if (x < -140 || x > 500) continue;
      _pole(canvas, g, i, x);
    }
    if (wx != null) _lyingWire(canvas, g, g.sx(wx, p), dropT);
  }

  void _sky(Canvas c, SenseWalkGeo g) {
    final r = Rect.fromLTWH(0, 0, 360, g.horizonY + 2);
    c.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6FB3E8), Color(0xFFBFE2F7), Color(0xFFEAF6FC)],
          stops: [0, 0.7, 1],
        ).createShader(r),
    );
    c.drawCircle(const Offset(300, 120), 26, Paint()..color = const Color(0x55FFF4C2));
    c.drawCircle(const Offset(300, 120), 16, Paint()..color = const Color(0xFFFFF1B0));
    final cloud = Paint()..color = const Color(0xCCFFFFFF);
    for (final (x, y, s) in [(70.0, 150.0, 1.0), (210.0, 110.0, 0.8)]) {
      c.drawOval(Rect.fromCenter(center: Offset(x, y), width: 70 * s, height: 22 * s), cloud);
      c.drawOval(Rect.fromCenter(center: Offset(x + 18 * s, y - 8 * s), width: 40 * s, height: 22 * s), cloud);
    }
  }

  void _far(Canvas c, SenseWalkGeo g, double p) {
    // The tree line far off (slow parallax), then the fields.
    final shift = p * kSensePxPerM * 0.35;
    final dark = Paint()..color = const Color(0xFF6E9A5C);
    for (var k = -1; k < 9; k++) {
      final base = (k * 52 - shift % 52);
      final n = (k + (shift / 52).floor());
      final h = 18 + 14 * _hash(n, 3);
      c.drawCircle(Offset(base, g.horizonY - h * 0.5), h * 0.75, dark);
    }
    final fields = Rect.fromLTRB(0, g.horizonY, 360, g.baseY - 8);
    c.drawRect(
      fields,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF9DBE6A), Color(0xFFB6C978)],
        ).createShader(fields),
    );
  }

  void _path(Canvas c, SenseWalkGeo g, double p) {
    // The verge (grass) where the poles stand, then the dusty path to the bottom.
    c.drawRect(Rect.fromLTRB(0, g.baseY - 8, 360, g.baseY + 8), Paint()..color = const Color(0xFF8FA956));
    final path = Rect.fromLTRB(0, g.baseY + 6, 360, g.height);
    c.drawRect(
      path,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFCBA978), Color(0xFFB8925F)],
        ).createShader(path),
    );
    final rut = Paint()
      ..color = const Color(0x339A7446)
      ..strokeWidth = 4;
    c.drawLine(Offset(0, g.feetY - 14), Offset(360, g.feetY - 14), rut);
    c.drawLine(Offset(0, g.feetY + 12), Offset(360, g.feetY + 12), rut);
    // Pebbles scroll with the walk (so walking shows).
    final peb = Paint()..color = const Color(0xFF9C7A4E);
    final first = (g.wx(0, p) / 2.5).floor();
    for (var n = first; n < first + 32; n++) {
      final x = g.sx(n * 2.5 + _hash(n, 1) * 2, p);
      final y = g.baseY + 14 + _hash(n, 2) * (g.height - g.baseY - 20);
      c.drawCircle(Offset(x, y), 1.4 + _hash(n, 5) * 1.4, peb);
    }
    // The culvert: a low parapet at the verge with a pipe mouth.
    final cx = g.sx(layout.culvertX, p);
    if (cx > -60 && cx < 420) {
      c.drawRect(Rect.fromLTWH(cx - 26, g.baseY - 2, 52, 12), Paint()..color = const Color(0xFFC9C6BE));
      c.drawCircle(Offset(cx, g.baseY + 4), 5, Paint()..color = const Color(0xFF4A4A44));
    }
  }

  /// A patch of dry cracked soil or of road pitch on the path. They lie all
  /// along the road (so the one under the wire is no marker).
  void _groundPatch(Canvas c, SenseWalkGeo g, double x, double a, SenseGround kind, int n) {
    final o = Offset(x, g.pathMidY + (_hash(n, 9) - 0.5) * 10);
    final rx = 30 + _hash(n, 7) * 10;
    final ry = (g.feetY - g.baseY) / 2 + 8;
    final shape = Path();
    for (var k = 0; k <= 12; k++) {
      final t = k / 12 * math.pi * 2;
      final w = 0.82 + 0.18 * _hash(n, 20 + k % 12);
      final pt = o + Offset(math.cos(t) * rx * w, math.sin(t) * ry * w);
      if (k == 0) {
        shape.moveTo(pt.dx, pt.dy);
      } else {
        shape.lineTo(pt.dx, pt.dy);
      }
    }
    shape.close();
    if (kind == SenseGround.pitch) {
      c.drawPath(shape, Paint()..color = Color.fromRGBO(58, 58, 60, 0.85 * a));
      return;
    }
    c.drawPath(shape, Paint()..color = Color.fromRGBO(206, 176, 128, 0.8 * a));
    final crack = Paint()
      ..color = Color.fromRGBO(150, 116, 74, a)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;
    for (var k = 0; k < 4; k++) {
      final a0 = k * 1.6 + _hash(n, k) * 0.8;
      c.drawPath(
        Path()
          ..moveTo(o.dx + math.cos(a0) * 4, o.dy + math.sin(a0) * 2)
          ..lineTo(o.dx + math.cos(a0) * rx * 0.45, o.dy + math.sin(a0) * ry * 0.4)
          ..lineTo(o.dx + math.cos(a0 + 0.35) * rx * 0.8, o.dy + math.sin(a0 + 0.35) * ry * 0.7),
        crack,
      );
    }
  }

  void _potholes(Canvas c, SenseWalkGeo g, double p) {
    // Potholes.
    final hole = Paint()..color = const Color(0xFF6E5233);
    final rim = Paint()
      ..color = const Color(0xFF8E6E46)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final h in layout.potholes) {
      final x = g.sx(h, p);
      if (x < -40 || x > 400) continue;
      final r = Rect.fromCenter(center: Offset(x, g.feetY - 2), width: 30, height: 10);
      c.drawOval(r, hole);
      c.drawOval(r, rim);
    }
  }

  /// Dry and pitch patches along the road, every ~20 m (none on the wire's spot).
  void _patches(Canvas c, SenseWalkGeo g, double p, double? wx) {
    final first = (g.wx(-60, p) / 20).floor();
    for (var n = first; n < first + 6; n++) {
      final x = n * 20 + 6 + _hash(n, 11) * 8;
      if (wx != null && (x - wx).abs() < 8) continue;
      final sx = g.sx(x, p);
      if (sx < -60 || sx > 420) continue;
      _groundPatch(c, g, sx, 1, _hash(n, 13) < 0.5 ? SenseGround.soil : SenseGround.pitch, n);
    }
  }

  void _ring(Canvas c, SenseWalkGeo g, double x, double r, {required bool laid}) {
    final rect = g.ring(x, r);
    final rope = Paint()
      ..color = laid ? const Color(0xFFF2C230) : const Color(0xCCF2C230)
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke;
    final path = Path()..addOval(rect);
    for (final m in path.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 14) {
        final seg = m.extractPath(d, math.min(d + 8, m.length));
        c.drawPath(seg, rope..color = (d ~/ 14).isEven ? const Color(0xFFF2C230) : const Color(0xFFD33A2C));
      }
    }
    if (!laid) return;
    final stake = Paint()
      ..color = const Color(0xFF6B4A2E)
      ..strokeWidth = 3;
    for (final s in [rect.centerLeft, rect.centerRight, rect.topCenter, rect.bottomCenter]) {
      c.drawLine(s + const Offset(0, 4), s - const Offset(0, 16), stake);
    }
  }

  void _behindPole(Canvas c, SenseWalkGeo g, int i, double x) {
    // Decoys and the stay behind / beside the pole.
    if (layout.brickPole == i) {
      final b = Paint()..color = const Color(0xFFB4553A);
      for (var k = 0; k < 3; k++) {
        c.drawRect(Rect.fromLTWH(x - 54 + k * 9, g.baseY - 6, 8, 5), b);
      }
      c.drawRect(Rect.fromLTWH(x - 50, g.baseY - 11, 8, 5), b);
    }
    final treeHere = layout.treePole == i || (layout.upPole == i && layout.upKind == SenseUpKind.branch);
    if (treeHere) {
      final branch = layout.upPole == i && layout.upKind == SenseUpKind.branch;
      final right = branch ? layout.upPart == SensePart.wireR : layout.treeRight;
      final tx = x + (right ? 62 : -62);
      final h = branch ? g.poleH * 0.92 : g.poleH * 0.55;
      _tree(c, Offset(tx, g.baseY - 4), h, 1, reach: branch ? Offset(x + (right ? 30 : -30), g.armY - 10) : null);
    }
    if (layout.stays.contains(i)) {
      final slack = layout.downPole == i && layout.downKind == SenseDownKind.anchor;
      final top = Offset(x + 2, g.topY + 46);
      final anchor = Offset(x + 54, g.baseY + 2);
      final stay = Paint()
        ..color = _steel
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke;
      if (slack) {
        c.drawPath(
          Path()
            ..moveTo(top.dx, top.dy)
            ..quadraticBezierTo(x + 6, g.baseY - 30, anchor.dx - 2, anchor.dy - 8),
          stay,
        );
        // The rod pulled up and leaning, soil heaved.
        c.drawLine(anchor + const Offset(-2, -8), anchor + const Offset(8, 6), Paint()
          ..color = const Color(0xFF6A6F74)
          ..strokeWidth = 3);
        c.drawOval(Rect.fromCenter(center: anchor + const Offset(4, 6), width: 22, height: 8), Paint()..color = const Color(0xFF8A6A42));
      } else {
        c.drawLine(top, anchor, stay);
        c.drawLine(anchor, anchor + const Offset(4, 8), Paint()
          ..color = const Color(0xFF6A6F74)
          ..strokeWidth = 3);
        c.drawOval(Rect.fromCenter(center: anchor + const Offset(4, 8), width: 14, height: 5), Paint()..color = const Color(0xFF9C7A4E));
      }
    }
  }

  void _pole(Canvas c, SenseWalkGeo g, int i, double x) {
    // A tapered PCC pole.
    final body = Path()
      ..moveTo(x - 9, g.baseY)
      ..lineTo(x - 5, g.topY)
      ..lineTo(x + 5, g.topY)
      ..lineTo(x + 9, g.baseY)
      ..close();
    c.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(colors: [_concreteDark, _concrete, _concreteDark], stops: [0, 0.45, 1])
            .createShader(Rect.fromLTRB(x - 9, g.topY, x + 9, g.baseY)),
    );
    // Its number plate (every pole).
    c.drawRect(Rect.fromLTWH(x - 5, g.baseY - 132, 10, 8), Paint()..color = const Color(0xFFE6C23A));
    // The base collar.
    c.drawRect(Rect.fromLTWH(x - 12, g.baseY - 6, 24, 8), Paint()..color = const Color(0xFF9EA2A4));
    if (layout.posterPole == i) {
      c.drawRect(Rect.fromLTWH(x - 8, g.baseY - 92, 16, 20), Paint()..color = const Color(0xFFF4E9D2));
      c.drawRect(Rect.fromLTWH(x - 6, g.baseY - 89, 12, 6), Paint()..color = const Color(0xFF2F7DC4));
      c.drawLine(Offset(x - 6, g.baseY - 79), Offset(x + 6, g.baseY - 79), Paint()
        ..color = const Color(0xFF8A7A66)
        ..strokeWidth = 1.2);
    }
    if (layout.downPole == i) {
      switch (layout.downKind) {
        case SenseDownKind.vehicle:
          // A scrape at bumper height: chipped concrete, a rusty bar showing.
          c.drawPath(
            Path()
              ..moveTo(x - 9, g.baseY - 58)
              ..lineTo(x + 4, g.baseY - 62)
              ..lineTo(x + 8, g.baseY - 46)
              ..lineTo(x - 7, g.baseY - 40)
              ..close(),
            Paint()..color = const Color(0xFFD9D6CC),
          );
          final gouge = Paint()
            ..color = const Color(0xFF55585B)
            ..strokeWidth = 1.2;
          c.drawLine(Offset(x - 8, g.baseY - 54), Offset(x + 6, g.baseY - 57), gouge);
          c.drawLine(Offset(x - 7, g.baseY - 48), Offset(x + 7, g.baseY - 51), gouge);
          c.drawLine(Offset(x - 2, g.baseY - 60), Offset(x - 1, g.baseY - 42), Paint()
            ..color = const Color(0xFF9A5A2E)
            ..strokeWidth = 1.6);
        case SenseDownKind.base:
          // Cracks up from the base, the soil washed out beside it.
          c.drawOval(Rect.fromCenter(center: Offset(x + 6, g.baseY + 4), width: 28, height: 9), Paint()..color = const Color(0xFF5E4428));
          final crack = Paint()
            ..color = const Color(0xFF3C3F42)
            ..strokeWidth = 1.3
            ..style = PaintingStyle.stroke;
          c.drawPath(
            Path()
              ..moveTo(x - 4, g.baseY - 2)
              ..lineTo(x - 1, g.baseY - 10)
              ..lineTo(x - 5, g.baseY - 18)
              ..lineTo(x - 2, g.baseY - 24),
            crack,
          );
          c.drawPath(
            Path()
              ..moveTo(x + 5, g.baseY - 2)
              ..lineTo(x + 3, g.baseY - 9)
              ..lineTo(x + 7, g.baseY - 14),
            crack,
          );
        case SenseDownKind.anchor:
          break;
      }
    }
    // The cross-arm and the insulators.
    c.drawRect(Rect.fromLTWH(x - 34, g.armY - 2, 68, 5), Paint()..color = _steel);
    final tops = g.insTops(x);
    for (final t in tops) {
      final r = Rect.fromLTWH(t.dx - 3.5, t.dy, 7, 11);
      c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), Paint()..color = _porcelain);
    }
    // The FPIs at both ends of the section: the near one lit (the fault
    // current passed it), the far one dark.
    if (i == 0 || i == layout.poles - 1) {
      final box = Rect.fromLTWH(x + 6, g.armY + 26, 12, 14);
      c.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(2)), Paint()..color = const Color(0xFF2B3036));
      final lit = i == 0;
      if (lit) c.drawCircle(box.center + const Offset(0, -1), 6, Paint()..color = const Color(0x66FF3B30));
      c.drawCircle(box.center + const Offset(0, -1), 3, Paint()..color = lit ? const Color(0xFFFF5A4E) : const Color(0xFF4A3A3A));
    }
    // The DTR on its platform (the same look, smell or not).
    if (layout.dtrPoles.contains(i)) {
      final t = Rect.fromLTWH(x + 10, g.tankTop, 38, 46);
      c.drawRect(Rect.fromLTWH(x + 4, t.bottom, 50, 4), Paint()..color = _steel);
      c.drawRRect(
        RRect.fromRectAndRadius(t, const Radius.circular(3)),
        Paint()
          ..shader = const LinearGradient(colors: [Color(0xFF6F7E70), Color(0xFF9AAA98), Color(0xFF6F7E70)]).createShader(t),
      );
      final fin = Paint()
        ..color = const Color(0xFF5E6C5F)
        ..strokeWidth = 1.2;
      for (var k = 0; k < 5; k++) {
        c.drawLine(Offset(t.left + 6 + k * 6.5, t.top + 10), Offset(t.left + 6 + k * 6.5, t.bottom - 4), fin);
      }
      for (var k = 0; k < 3; k++) {
        c.drawRect(Rect.fromLTWH(t.left + 7 + k * 11, t.top - 8, 4, 8), Paint()..color = _porcelain);
      }
    }
    // Eye-up things seen small from the ground (a kite, a bird on the wire).
    if (layout.upPole == i && (layout.upKind == SenseUpKind.kite || layout.upKind == SenseUpKind.bird)) {
      final right = layout.upPart == SensePart.wireR;
      final at = Offset(x + (right ? 40 : -40), g.armY - 8);
      if (layout.upKind == SenseUpKind.kite) {
        _kite(c, at, 0.5);
      } else {
        _bird(c, at, 0.5);
      }
    }
    // Tags.
    for (final part in senseDownParts) {
      if (!live.tags.contains(senseTagKey(i, part))) continue;
      final r = g.partRect(part, x);
      _tagRibbon(c, Offset(r.center.dx + 6, r.center.dy), 1.1);
    }
    if (senseUpParts.any((part) => live.tags.contains(senseTagKey(i, part)))) {
      _tagRibbon(c, Offset(x + 4, g.armY + 14), 1);
    }
  }

  void _wires(Canvas c, SenseWalkGeo g, double p, double? wx, double dropT) {
    final w = Paint()
      ..color = _wire
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;
    final broken = wx == null ? -99 : layout.nearestSpan(wx);
    // Spans from before the first visible pole to after the last.
    for (var i = -1; i < layout.poles; i++) {
      final a = i < 0 ? null : g.sx(sensePoleX(i), p);
      final b = i + 1 >= layout.poles ? null : g.sx(sensePoleX(i + 1), p);
      final ax = a ?? g.sx(sensePoleX(0) - kSenseSpan, p);
      final bx = b ?? g.sx(sensePoleX(layout.poles - 1) + kSenseSpan, p);
      if (bx < -20 || ax > 380) continue;
      final ta = g.insTops(ax);
      final tb = g.insTops(bx);
      for (var k = 0; k < 3; k++) {
        final from = ta[k];
        final to = tb[k];
        final mid = Offset((from.dx + to.dx) / 2, (from.dy + to.dy) / 2 + 18);
        if (i == broken && k == 2) {
          final gx = g.sx(wx!, p);
          final downA = Offset(gx - kSenseWireHalf * kSensePxPerM, g.baseY + 8);
          final downB = Offset(gx + kSenseWireHalf * kSensePxPerM, g.baseY + 8);
          final ea = Offset.lerp(mid, downA, dropT)!;
          final eb = Offset.lerp(mid, downB, dropT)!;
          final ca = Offset.lerp(mid, Offset(ea.dx - 30, (from.dy + ea.dy) / 2), dropT)!;
          final cb = Offset.lerp(mid, Offset(eb.dx + 30, (to.dy + eb.dy) / 2), dropT)!;
          c.drawPath(
            Path()
              ..moveTo(from.dx, from.dy)
              ..quadraticBezierTo(ca.dx, ca.dy, ea.dx, ea.dy),
            w,
          );
          c.drawPath(
            Path()
              ..moveTo(to.dx, to.dy)
              ..quadraticBezierTo(cb.dx, cb.dy, eb.dx, eb.dy),
            w,
          );
          continue;
        }
        c.drawPath(
          Path()
            ..moveTo(from.dx, from.dy)
            ..quadraticBezierTo(mid.dx, mid.dy + 18, to.dx, to.dy),
          w,
        );
      }
    }
  }

  void _lyingWire(Canvas c, SenseWalkGeo g, double x, double dropT) {
    if (dropT < 1) return;
    final w = Paint()
      ..color = _wire
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    final h = kSenseWireHalf * kSensePxPerM;
    c.drawPath(
      Path()
        ..moveTo(x - h, g.baseY + 8)
        ..cubicTo(x - h * 0.2, g.baseY + 20, x - h * 1.1, g.feetY - 10, x + h * 0.3, g.feetY + 2),
      w,
    );
    c.drawPath(
      Path()
        ..moveTo(x + h, g.baseY + 8)
        ..cubicTo(x + h * 1.2, g.baseY + 24, x + h * 0.4, g.pathMidY, x + h * 0.9, g.pathMidY + 6),
      w,
    );
  }

  @override
  bool shouldRepaint(SenseWalkPainter old) =>
      old.geo != geo || old.layout != layout || old.live != live || old.pos != pos || old.drop != drop;
}

extension SenseSpans on SenseLayout {
  /// The span (between pole i and i + 1) that holds [x]; -1 before pole 0.
  int nearestSpan(double x) => ((x - kSensePole0) / kSenseSpan).floor().clamp(-1, poles - 1);
}

// ============================================================================
// The eye-up view: the nearest pole's top, close
// ============================================================================

class SenseTopPainter extends CustomPainter {
  SenseTopPainter({required this.geo, required this.layout, required this.pole, required this.tags, this.broken});

  final SenseTopGeo geo;
  final SenseLayout layout;
  final int pole;
  final Set<int> tags;

  /// The span whose phase 3 lies on the ground (between pole [broken] and the
  /// next), or null while every conductor is whole. The poles either side of
  /// it show that phase hanging down on the broken side, as the road does.
  final int? broken;

  @override
  void paint(Canvas canvas, Size size) {
    final g = geo;
    final c = canvas;
    final sky = Rect.fromLTWH(0, 0, 360, g.height);
    c.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4F9BDA), Color(0xFF9BD0F2)],
        ).createShader(sky),
    );
    final cloud = Paint()..color = const Color(0xB3FFFFFF);
    c.drawOval(Rect.fromCenter(center: Offset(80, g.height * 0.16), width: 110, height: 30), cloud);
    c.drawOval(Rect.fromCenter(center: Offset(270, g.height * 0.10), width: 80, height: 24), cloud);
    final l = layout;
    // Trees beside the pole (a decoy clear of the wires, or the branch clue).
    final branch = l.upPole == pole && l.upKind == SenseUpKind.branch;
    if (branch || l.treePole == pole) {
      final right = branch ? l.upPart == SensePart.wireR : l.treeRight;
      final tx = right ? 340.0 : 20.0;
      if (branch) {
        final reachX = right ? 318.0 : 42.0;
        _tree(c, Offset(tx, g.height + 40), g.height - g.armY + 120, 2.2, reach: Offset(reachX, g.wireY(right ? 2 : 0, reachX) + 2));
      } else {
        _tree(c, Offset(tx, g.height + 40), g.height - g.armY - 30, 2.2);
      }
    }
    // The pole, from the cross-arm down out of the frame.
    final pole2 = Rect.fromLTRB(162, g.armY - 30, 198, g.height);
    c.drawRect(
      pole2,
      Paint()
        ..shader = const LinearGradient(colors: [_concreteDark, _concrete, _concreteDark], stops: [0, 0.45, 1]).createShader(pole2),
    );
    // The cross-arm (a little aslant).
    final arm = Path()
      ..moveTo(60, g.armY - 6 - 12)
      ..lineTo(300, g.armY - 6 + 12)
      ..lineTo(300, g.armY + 8 + 12)
      ..lineTo(60, g.armY + 8 - 12)
      ..close();
    c.drawPath(arm, Paint()..color = _steel);
    // FPI on the end poles.
    if (pole == 0 || pole == l.poles - 1) {
      final box = Rect.fromLTWH(200, g.armY + 40, 30, 36);
      c.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(4)), Paint()..color = const Color(0xFF2B3036));
      final lit = pole == 0;
      if (lit) c.drawCircle(box.center, 14, Paint()..color = const Color(0x66FF3B30));
      c.drawCircle(box.center, 6, Paint()..color = lit ? const Color(0xFFFF5A4E) : const Color(0xFF4A3A3A));
    }
    // Conductors: each runs left and right from its insulator top.
    final w = Paint()
      ..color = _wire
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke;
    final hangRight = broken != null && pole == broken;
    final hangLeft = broken != null && pole == broken! + 1;
    for (var k = 0; k < 3; k++) {
      final t = g.insTop(k);
      final cut = k == 2 && (hangLeft || hangRight);
      final from = cut && hangLeft ? t.dx : -4.0;
      final to = cut && hangRight ? t.dx : 364.0;
      final path = Path()..moveTo(from, g.wireY(k, from));
      for (var x = from + 12; x < to; x += 12) {
        path.lineTo(x, g.wireY(k, x));
      }
      path.lineTo(to, g.wireY(k, to));
      c.drawPath(path, w);
      if (cut) {
        // The broken half hangs from its insulator down to the road.
        final s = hangRight ? 1.0 : -1.0;
        c.drawPath(
          Path()
            ..moveTo(t.dx, t.dy)
            ..cubicTo(t.dx + 30 * s, t.dy + 6, t.dx + 44 * s, t.dy + 80, t.dx + 50 * s, g.height + 10),
          w,
        );
      }
      c.drawCircle(t, 3, Paint()..color = _wire);
    }
    // Insulators: three porcelain stacks on pins.
    for (var k = 0; k < 3; k++) {
      final t = g.insTop(k);
      final pinBase = Offset(t.dx, t.dy + 52);
      c.drawRect(Rect.fromLTWH(pinBase.dx - 3, pinBase.dy - 6, 6, 12), Paint()..color = _steel);
      for (var s = 0; s < 3; s++) {
        final y = t.dy + 8 + s * 14;
        final shed = Rect.fromCenter(center: Offset(t.dx, y + 4), width: 34 - s * 3.0, height: 10);
        c.drawOval(shed, Paint()..color = _porcelain);
        c.drawOval(shed.deflate(3).shift(const Offset(-2, -2)), Paint()..color = _porcelainLit);
      }
      c.drawRect(Rect.fromLTWH(t.dx - 7, t.dy, 14, 46), Paint()..color = _porcelain.withValues(alpha: 0.85));
      final part = senseInsPart(k);
      if (l.dirtAt(pole) == k) {
        // Only a dirt layer: nothing broken (the ear pole, or a decoy).
        c.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(t.dx - 17, t.dy + 14, 34, 30), const Radius.circular(6)),
          Paint()..color = const Color(0x40594A36),
        );
      }
      if (l.upPole == pole && l.upKind == SenseUpKind.crack && l.upPart == part) {
        c.drawPath(
          Path()
            ..moveTo(t.dx + 15, t.dy + 18)
            ..lineTo(t.dx + 6, t.dy + 22)
            ..lineTo(t.dx + 12, t.dy + 28)
            ..close(),
          Paint()..color = const Color(0xFFE8D9C8),
        );
        c.drawPath(
          Path()
            ..moveTo(t.dx - 14, t.dy + 12)
            ..lineTo(t.dx - 5, t.dy + 18)
            ..lineTo(t.dx - 9, t.dy + 26)
            ..lineTo(t.dx + 2, t.dy + 34)
            ..lineTo(t.dx - 2, t.dy + 42),
          Paint()
            ..color = const Color(0xFF1E1A18)
            ..strokeWidth = 1.6
            ..style = PaintingStyle.stroke,
        );
      }
      if (tags.contains(senseTagKey(pole, part))) _tagRibbon(c, Offset(t.dx + 18, t.dy + 34), 1.6);
    }
    // A kite or a bird caught on a wire.
    if (l.upPole == pole && (l.upKind == SenseUpKind.kite || l.upKind == SenseUpKind.bird)) {
      final right = l.upPart == SensePart.wireR;
      final x = right ? 326.0 : 34.0;
      final k = right ? 2 : 0;
      final at = Offset(x, g.wireY(k, x));
      if (l.upKind == SenseUpKind.kite) {
        _kite(c, at + const Offset(0, 22), 1.4);
        c.drawLine(at, at + const Offset(0, 4), Paint()
          ..color = const Color(0xFF8A7A66)
          ..strokeWidth = 1);
      } else {
        _bird(c, at, 1.5);
      }
    }
    for (final part in [SensePart.wireL, SensePart.wireR]) {
      if (!tags.contains(senseTagKey(pole, part))) continue;
      final r = g.partRect(part);
      _tagRibbon(c, Offset(r.center.dx - 6, r.bottom - 20), 1.6);
    }
  }

  @override
  bool shouldRepaint(SenseTopPainter old) =>
      old.geo != geo || old.layout != layout || old.pole != pole || old.broken != broken || !setEquals(old.tags, tags);
}

// ============================================================================
// The deadly consequence (over the grey scene, in colour)
// ============================================================================

class SenseHarmPainter extends CustomPainter {
  SenseHarmPainter({required this.geo, required this.wireSx, required this.harm, required this.v});

  final SenseWalkGeo geo;
  final double wireSx;
  final SenseHarm harm;
  final double v;

  @override
  void paint(Canvas canvas, Size size) {
    final g = geo;
    final o = Offset(wireSx, g.pathMidY);
    if (harm == SenseHarm.touch) {
      final glow = Paint()..color = Color.fromRGBO(255, 236, 120, 0.75 * v);
      canvas.drawCircle(o, 18 + 30 * v, glow);
      canvas.drawCircle(o, 10, Paint()..color = Color.fromRGBO(255, 255, 255, v));
    } else {
      // The ground is live: rings of voltage spread from the wire to his feet.
      final reach = (SenseWalkGeo.manX - wireSx).abs() + 40;
      for (var k = 1; k <= 5; k++) {
        final r = reach * k / 5 * v;
        canvas.drawOval(
          Rect.fromCenter(center: o, width: r * 2, height: r * 0.5),
          Paint()
            ..color = Color.fromRGBO(255, 196, 0, (0.9 - k * 0.14) * v)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4,
        );
      }
    }
    // The current through his legs (zone / stride) or his hands (touch).
    final feet = Offset(SenseWalkGeo.manX, g.feetY - 4);
    final bolt = Paint()
      ..color = Color.fromRGBO(255, 240, 90, v)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final gap = harm == SenseHarm.stride ? 22.0 : 10.0;
    if (harm == SenseHarm.touch) {
      canvas.drawPath(
        Path()
          ..moveTo(o.dx, o.dy)
          ..lineTo(o.dx - 10, o.dy - 30)
          ..lineTo(o.dx + 4, o.dy - 42)
          ..lineTo(o.dx - 6, o.dy - 70),
        bolt,
      );
    } else {
      canvas.drawPath(
        Path()
          ..moveTo(feet.dx - gap, feet.dy)
          ..lineTo(feet.dx - gap / 2, feet.dy - 26)
          ..lineTo(feet.dx, feet.dy - 14)
          ..lineTo(feet.dx + gap / 2, feet.dy - 30)
          ..lineTo(feet.dx + gap, feet.dy),
        bolt,
      );
    }
  }

  @override
  bool shouldRepaint(SenseHarmPainter old) => old.v != v || old.harm != harm || old.wireSx != wireSx || old.geo != geo;
}
