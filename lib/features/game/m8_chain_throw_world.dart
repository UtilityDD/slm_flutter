import 'dart:math' as math;

import 'package:flutter/material.dart';

// The drawn world of lesson 8.5 কাজ "দুই প্রান্তে কবচ — রড, তারপর চেইন"
// (m8_chain_throw.dart): a shut-down 11 kV village span. Three places, one
// walk apart:
//  * the substation: the feeder breaker's handle at OFF with its hasp, the
//    key-hook board, the operator (his open hand), a bench tray with the
//    padlock, the "কাজ চলছে" board and decoys, the key that pops out;
//  * an earth pole at each end of the span, seen end-on: a cross-arm with
//    three pins, the wires running away to the horizon, a tarp at the foot
//    with the rod set (rod, clamp, the spike in the ground), the chain bag, a
//    discard crate, and — until the line is proved — the tester and its
//    proving unit;
//  * the work pole in the middle (docket 'কাজের পোল'), the two earth poles
//    far off with what is on them, and the crew mate.
// No text in the art except labels a worker reads. Code-drawn, gradients, no
// bitmaps. Design: 360 wide x the scene's height; the floor follows the
// bottom of the screen.

/// Where the player is.
enum M8Station { sub, endA, work, endB }

/// A ball-chain as it comes out of the bag. Brass and copper are good; a
/// rusty stretch, a broken link, a bent end hook and a grey iron jugaad
/// chain are the ones the lesson bars (point 5 'বারণীয়').
enum M8ChainKind { brass, copper, rusty, broken, bentHook, iron }

bool m8ChainGood(M8ChainKind k) => k == M8ChainKind.brass || k == M8ChainKind.copper;

/// Where a chain is at an end.
enum M8ChainAt { bag, coil, line, down }

/// Things on the bench tray (a padlock, a board and two decoys).
enum M8TrayItem { padlock, board, torch, tape, fuse, rag }

/// The padlock's key.
enum M8Key { inLock, popped, pocket, hook, operator }

/// What the player is moving now (hidden from the scene while it is in hand).
enum M8Held { none, item, key, clamp, rod, tester, coil, bag, tail }

/// The crew mate at the work pole.
enum M8Mate { idle, job, descend, cleared }

/// One end's geometry, dealt (the throw to the line is not the same at both).
@immutable
class M8EndSpec {
  const M8EndSpec({required this.mirrored, required this.standDx, required this.condF, required this.spread, required this.raise});

  /// The kit is on the right of the pole (mirrored layout).
  final bool mirrored;

  /// How far the trainee stands from the pole (design px).
  final double standDx;

  /// The wires' height as a fraction of the working area: 0.06 high … 0.18 low.
  final double condF;

  /// The distance between phases (the cross-arm's shape).
  final double spread;

  /// The middle phase stands this much higher (a delta arm), else 0.
  final double raise;

  /// The flick length (design px) that just reaches the wires.
  double get reach => 150 + (0.18 - condF) / 0.12 * 60;

  /// How high the wires are above the hand, in flick terms.
  double get lineHeight => reach * 1.25;

  /// Half the width a thrown chain covers where it lands.
  static const double chainHalf = 80;
}

/// Where things are (design px, 360 wide).
@immutable
class M8Geo {
  const M8Geo._(this.height, this.floorY);

  factory M8Geo.forScene(double height, double inset) => M8Geo._(height, height - floorUp - inset * 0.5);

  final double height;
  final double floorY;

  static const double floorUp = 96;
  static const double top = 132;

  double get a => floorY - top;
  double y(double f) => top + f * a;

  /// The ground's far edge (the horizon sits just above).
  double get gy => y(0.60);

  // --- the substation -------------------------------------------------------
  Rect get panel => Rect.fromLTRB(88, y(0.04), 232, y(0.50));
  Offset get handle => Offset(160, y(0.30));
  Rect get handleHit => Rect.fromCenter(center: handle, width: 84, height: 70);

  /// Where the board hangs on the handle.
  Rect get boardOn => Rect.fromCenter(center: Offset(160, y(0.385)), width: 62, height: 22);

  Rect get hookBoard => Rect.fromLTRB(8, y(0.08), 68, y(0.40));
  Rect get hookBoardHit => hookBoard.inflate(6);
  Rect get operator => Rect.fromLTRB(246, y(0.10), 350, y(0.54));
  Offset get operatorHand => Offset(262, y(0.37));
  Rect get operatorHit => Rect.fromCircle(center: operatorHand, radius: 28);
  Rect get subTrainee => Rect.fromLTWH(238, y(0.58), 46, y(0.40));
  Offset get pocket => Offset(266, y(0.70));
  Rect get pocketHit => Rect.fromCircle(center: pocket, radius: 24);
  Rect get tray => Rect.fromLTRB(6, y(0.62), 226, y(0.99));
  Offset get keyAt => Offset(160, y(0.455));
  Rect get keyHit => Rect.fromCircle(center: keyAt, radius: 24);

  /// The tray's four slots.
  Rect slot(int i) => Rect.fromLTWH(12 + i * 53.0, y(0.70), 48, 50);

  // --- the work pole ---------------------------------------------------------
  double get workX => 180;
  double get workArmY => y(0.12);
  Rect get workTrainee => Rect.fromLTWH(104, y(0.60), 46, y(0.40));
  Rect get docket => Rect.fromCenter(center: Offset(180, y(0.40)), width: 70, height: 24);
  double get farArmY => y(0.34);
  static const double farL = 40, farR = 320;
  Offset get mateBase => Offset(216, y(0.945));
  Offset get mateTop => Offset(188, y(0.19));

  /// Where a deadly chain shows (the line above the player).
  Offset flashAtEnd(M8EndGeo e) => Offset(e.standX + (e.poleX - e.standX) * 0.5, e.armY);

  @override
  bool operator ==(Object other) => other is M8Geo && other.height == height && other.floorY == floorY;

  @override
  int get hashCode => Object.hash(height, floorY);
}

/// One end's places.
@immutable
class M8EndGeo {
  const M8EndGeo(this.g, this.s);

  final M8Geo g;
  final M8EndSpec s;

  double mx(double x) => s.mirrored ? 360 - x : x;
  Rect mr(Rect r) => s.mirrored ? Rect.fromLTRB(360 - r.right, r.top, 360 - r.left, r.bottom) : r;

  double get poleX => mx(292);
  double get armY => g.y(s.condF);
  double get standX => mx(292 - s.standDx);

  /// The three pins (phases R, Y, B), the middle one raised on a delta arm.
  List<Offset> get pins => [for (var i = 0; i < 3; i++) Offset(poleX + (i - 1) * s.spread, armY - (i == 1 ? s.raise : 0))];

  Rect get trainee => Rect.fromLTWH(standX - 23, g.y(0.60), 46, g.y(0.99) - g.y(0.60));
  Offset get coil => Offset(standX, g.y(0.955));
  Rect get coilHit => Rect.fromLTRB(standX - 46, g.y(0.55), standX + 46, g.y(0.995));

  Rect get tarp => mr(Rect.fromLTRB(4, g.y(0.64), 184, g.y(0.99)));
  Offset get tester => Offset(mx(34), g.y(0.705));
  Rect get testerHit => Rect.fromCenter(center: tester, width: 44, height: 46);
  Offset get prover => Offset(mx(142), g.y(0.695));
  Rect get proverHit => Rect.fromCenter(center: prover, width: 54, height: 38);
  Offset get bag => Offset(mx(44), g.y(0.82));
  Rect get bagHit => Rect.fromCenter(center: bag, width: 60, height: 46);
  Offset get clampRest => Offset(mx(42), g.y(0.925));
  Rect get clampHit => Rect.fromCenter(center: clampRest, width: 44, height: 38);
  Offset get rodBase => Offset(mx(138), g.y(0.985));
  Offset get rodRest => Offset(mx(150), g.y(0.775));
  Rect get rodHit => mr(Rect.fromLTRB(122, g.y(0.76), 162, g.y(0.99)));
  Offset get spike => Offset(mx(334), g.y(0.83));
  Rect get spikeHit => Rect.fromCenter(center: spike, width: 52, height: 56);
  Rect get crate => mr(Rect.fromLTRB(8, g.y(0.50), 92, g.y(0.60)));

  /// The wires' band: a rod head or the tester's tip that reaches it is on the line.
  Rect get lineBand => Rect.fromLTRB(0, armY - 26 - s.raise, 360, armY + 36);

  /// Where the rod's head hooks (the finger's x on the arm).
  double hookXFor(double x) => x.clamp(pins.first.dx - 18, pins.last.dx + 18);
  Offset rodHandle() => Offset(standX + (s.mirrored ? -16 : 16), g.y(0.90));
  Rect rodHeadHit(double hookX) => Rect.fromCenter(center: Offset(hookX, armY), width: 96, height: 84);

  /// The chain tail hanging on the player's side, and where it is grabbed.
  double tailX(int lo, int hi) {
    final p = pins;
    return s.mirrored ? p[hi].dx + 18 : p[lo].dx - 18;
  }

  Rect tailHit(int lo, int hi) => Rect.fromLTRB(tailX(lo, hi) - 28, armY + 12, tailX(lo, hi) + 28, math.min(armY + 150, g.y(0.52)));

  Offset flashAt() => Offset((standX + poleX) / 2, armY + 6);

  @override
  bool operator ==(Object other) => other is M8EndGeo && other.g == g && other.s == s;

  @override
  int get hashCode => Object.hash(g, s);
}

/// What a thrown chain did.
enum M8ThrowKind { short, over, beside, partial, full }

@immutable
class M8Throw {
  const M8Throw(this.kind, {this.lo = 0, this.hi = 0, this.landX = 0});
  final M8ThrowKind kind;

  /// The first and last phase it lies on (partial or full).
  final int lo;
  final int hi;
  final double landX;
  int get phases => kind == M8ThrowKind.full ? 3 : (kind == M8ThrowKind.partial ? hi - lo + 1 : 0);
}

/// The flick of [flick] (design px, from the coil to where the finger lifted):
/// its length is the strength, its angle the aim. Short of the wires it falls
/// back; far past them it slides off the other side; near either edge of the
/// range it lies on one or two phases; in the middle of the range, aimed over
/// the pole, it drapes all three.
M8Throw m8ThrowOf(Offset flick, M8EndGeo e) {
  final len = flick.distance;
  final reach = e.s.reach;
  final q = len / reach;
  if (q < 0.8) return const M8Throw(M8ThrowKind.short);
  if (q > 1.5) return const M8Throw(M8ThrowKind.over);
  // Aim from the vertical (right of it positive); the landing x.
  final aim = math.atan2(flick.dx, -flick.dy);
  final lx = e.standX + math.tan(aim) * e.s.lineHeight;
  final pins = e.pins;
  final covered = <int>[
    for (var i = 0; i < 3; i++)
      if ((pins[i].dx - lx).abs() <= M8EndSpec.chainHalf) i,
  ];
  if (covered.isEmpty) return M8Throw(M8ThrowKind.beside, landX: lx);
  final centre = q >= 1.0 && q <= 1.35;
  if (centre && covered.length == 3) return M8Throw(M8ThrowKind.full, lo: 0, hi: 2, landX: lx);
  // Marginal strength or a sideways aim: at most two phases.
  var lo = covered.first;
  var hi = covered.last;
  if (hi - lo > 1) {
    // Keep the two nearest the landing.
    final order = [...covered]..sort((p, r) => (pins[p].dx - lx).abs().compareTo((pins[r].dx - lx).abs()));
    final two = [order[0], order[1]]..sort();
    lo = two.first;
    hi = two.last;
  }
  return M8Throw(M8ThrowKind.partial, lo: lo, hi: hi, landX: lx);
}

/// A flick (from the coil) of [q] times the reach aimed [lateral] design px
/// off the middle of the pole (tests and the hint use it; never shown).
Offset m8FlickFor(M8EndGeo e, {double q = 1.15, double lateral = 0}) {
  final target = e.poleX + lateral;
  final tan = (target - e.standX) / e.s.lineHeight;
  final aim = math.atan(tan);
  final len = e.s.reach * q;
  return Offset(math.sin(aim) * len, -math.cos(aim) * len);
}

// ============================================================================
// What the scene shows
// ============================================================================

@immutable
class M8EndLook {
  const M8EndLook({
    this.clamped = false,
    this.hookX,
    this.drained = false,
    this.pulled = 0,
    this.chain = M8ChainKind.brass,
    this.defectSeg = 2,
    this.at = M8ChainAt.bag,
    this.lo = 0,
    this.hi = 2,
    this.tester = true,
    this.reading = '- - -',
    this.crate,
  });

  /// The earth clamp is on the spike.
  final bool clamped;

  /// The rod's hook is on the line at this x (null: the rod rests on the tarp).
  final double? hookX;
  final bool drained;
  final int pulled;
  final M8ChainKind chain;
  final int defectSeg;
  final M8ChainAt at;
  final int lo;
  final int hi;

  /// The tester and its proving unit are on the tarp (until the line is proved).
  final bool tester;
  final String reading;

  /// A chain thrown out is in the crate.
  final M8ChainKind? crate;

  @override
  bool operator ==(Object other) =>
      other is M8EndLook &&
      other.clamped == clamped &&
      other.hookX == hookX &&
      other.drained == drained &&
      other.pulled == pulled &&
      other.chain == chain &&
      other.defectSeg == defectSeg &&
      other.at == at &&
      other.lo == lo &&
      other.hi == hi &&
      other.tester == tester &&
      other.reading == reading &&
      other.crate == crate;

  @override
  int get hashCode => Object.hash(clamped, hookX, drained, pulled, chain, defectSeg, at, lo, hi, tester, reading, crate);
}

@immutable
class M8SubLook {
  const M8SubLook({required this.tray, this.padlock = false, this.board = false, this.key = M8Key.inLock});

  /// The four tray slots (null: taken).
  final List<M8TrayItem?> tray;
  final bool padlock;
  final bool board;
  final M8Key key;

  @override
  bool operator ==(Object other) => other is M8SubLook && other.padlock == padlock && other.board == board && other.key == key && _eq(other.tray, tray);

  @override
  int get hashCode => Object.hash(padlock, board, key, Object.hashAll(tray));
}

bool _eq<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

@immutable
class M8Rig {
  const M8Rig({required this.station, required this.sub, required this.ends, required this.specs, this.held = M8Held.none, this.heldSlot = -1});

  final M8Station station;
  final M8SubLook sub;
  final List<M8EndLook> ends;
  final List<M8EndSpec> specs;
  final M8Held held;
  final int heldSlot;

  int get endIndex => station == M8Station.endB ? 1 : 0;

  @override
  bool operator ==(Object other) =>
      other is M8Rig && other.station == station && other.sub == sub && _eq(other.ends, ends) && _eq(other.specs, specs) && other.held == held && other.heldSlot == heldSlot;

  @override
  int get hashCode => Object.hash(station, sub, Object.hashAll(ends), Object.hashAll(specs), held, heldSlot);
}

/// A thing in the hand, for the small painter that follows the finger.
@immutable
class M8DragView {
  const M8DragView({required this.held, required this.start, required this.at, this.item, this.chain = M8ChainKind.brass, this.cable, this.base});
  final M8Held held;
  final Offset start;
  final Offset at;
  final M8TrayItem? item;
  final M8ChainKind chain;

  /// The rod's or the clamp's cable end (the other end of the cable), and the rod's base.
  final Offset? cable;
  final Offset? base;
}

// ============================================================================
// Paint helpers
// ============================================================================

void _text(Canvas c, String text, Offset centre, {double size = 7, Color color = const Color(0xFF26303D), FontWeight weight = FontWeight.w800}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: weight, color: color, letterSpacing: 0.3, height: 1.05)),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  )..layout(maxWidth: 120);
  tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
}

Paint _fill(Color c) => Paint()..color = c;
Paint _stroke(Color c, double w, {StrokeCap cap = StrokeCap.round}) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = cap;

/// The balls of a chain along [pts] (polyline), 7 px apart; ball i belongs to
/// third (i*3 ~/ n). The defect shows in its third; iron is grey all through.
void m8PaintChain(Canvas c, List<Offset> pts, M8ChainKind kind, int defectSeg, {double reveal = 1.0, double r = 3.1}) {
  if (pts.length < 2) return;
  // Ball centres.
  final balls = <Offset>[];
  var carry = 0.0;
  for (var i = 1; i < pts.length; i++) {
    final a = pts[i - 1], b = pts[i];
    final len = (b - a).distance;
    if (len == 0) continue;
    var d = carry;
    while (d <= len) {
      balls.add(Offset.lerp(a, b, d / len)!);
      d += 7;
    }
    carry = d - len;
  }
  final n = balls.length;
  if (n == 0) return;
  final shown = (n * reveal).ceil().clamp(0, n);
  final line = _stroke(const Color(0xFF6A5A30), 1.2);
  // A broken link: two balls missing in its third, an open ring beside the gap.
  final int gapAt = kind == M8ChainKind.broken ? (n * (defectSeg + 0.5) / 3).round().clamp(2, math.max(2, n - 3)).toInt() : -10;
  bool gap(int i) => i == gapAt || i == gapAt + 1;
  for (var i = 1; i < shown; i++) {
    if (gap(i) || gap(i - 1)) continue;
    c.drawLine(balls[i - 1], balls[i], line);
  }
  for (var i = 0; i < shown; i++) {
    if (gap(i)) continue;
    final seg = (i * 3 ~/ n).clamp(0, 2);
    final o = balls[i];
    final inDefect = seg == defectSeg;
    var cols = const [Color(0xFFF7DE8A), Color(0xFFB8862E)];
    switch (kind) {
      case M8ChainKind.copper:
        cols = const [Color(0xFFF2A585), Color(0xFFB05A38)];
      case M8ChainKind.rusty:
        if (inDefect) cols = const [Color(0xFF9A6A3C), Color(0xFF4E2E18)];
      case M8ChainKind.iron:
        cols = const [Color(0xFF9AA0A6), Color(0xFF50565C)];
      case M8ChainKind.brass || M8ChainKind.broken || M8ChainKind.bentHook:
        break;
    }
    c.drawCircle(o, r, Paint()..shader = RadialGradient(center: const Alignment(-0.4, -0.4), colors: cols).createShader(Rect.fromCircle(center: o, radius: r)));
    if ((kind == M8ChainKind.rusty && inDefect) || (kind == M8ChainKind.iron && i % 3 == 0)) {
      c.drawCircle(o.translate(1, 0.6), 1.1, _fill(const Color(0xFFC0682C)));
    }
  }
  if (kind == M8ChainKind.broken && shown > gapAt + 1 && gapAt + 1 < n) {
    c.drawArc(Rect.fromCircle(center: balls[gapAt].translate(0, 2), radius: 4), 0.6, 4.6, false, _stroke(const Color(0xFFB8862E), 1.4));
    c.drawArc(Rect.fromCircle(center: balls[gapAt + 1].translate(0, -2), radius: 4), 3.7, 4.6, false, _stroke(const Color(0xFFB8862E), 1.4));
  }
  // The end hook (a J) at the last ball; bent in one kind.
  final last = balls[n - 1];
  final bent = kind == M8ChainKind.bentHook;
  if (shown >= n) {
    final hookCol = kind == M8ChainKind.iron ? const Color(0xFF50565C) : const Color(0xFFB8862E);
    final p = Path()
      ..moveTo(last.dx, last.dy)
      ..lineTo(last.dx + (bent ? 6 : 0), last.dy + 6)
      ..quadraticBezierTo(last.dx + (bent ? 16 : 6), last.dy + (bent ? 8 : 14), last.dx + (bent ? 11 : 0), last.dy + (bent ? 20 : 12));
    c.drawPath(p, _stroke(hookCol, 2.2));
  }
}

void _grass(Canvas c, Size size, M8Geo g) {
  final sky = Rect.fromLTWH(0, 0, size.width, g.gy);
  c.drawRect(sky, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF7FB6E6), Color(0xFFD7EBF6)]).createShader(sky));
  final far = Path()..moveTo(0, g.gy - 26);
  for (var x = 0.0; x <= size.width + 20; x += 20) {
    far.quadraticBezierTo(x + 10, g.gy - 42 - (x % 60 == 0 ? 8 : 0), x + 20, g.gy - 26);
  }
  far
    ..lineTo(size.width, g.gy)
    ..lineTo(0, g.gy)
    ..close();
  c.drawPath(far, _fill(const Color(0xFF6E9A5A)));
  final ground = Rect.fromLTRB(0, g.gy, size.width, size.height);
  c.drawRect(ground, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF7FA35E), Color(0xFF4F7A3E)]).createShader(ground));
}

/// A pole seen end-on: shaft, cross-arm, three pin insulators; the wires run
/// away to the horizon.
void _pole(Canvas c, M8Geo g, double x, double armY, List<Offset> pins, {double scale = 1.0, double baseY = 0}) {
  final base = baseY == 0 ? g.gy + 4 : baseY;
  final w = 9 * scale;
  final shaft = Rect.fromLTRB(x - w / 2, armY - 8 * scale, x + w / 2, base);
  c.drawRect(shaft, Paint()..shader = const LinearGradient(colors: [Color(0xFFB9B2A6), Color(0xFF8A8478)]).createShader(shaft));
  // Wires to the vanishing point.
  final vp = Offset(180, g.y(0.55));
  for (final p in pins) {
    final path = Path()
      ..moveTo(p.dx, p.dy)
      ..lineTo(vp.dx + (p.dx - vp.dx) * 0.18, vp.dy - (vp.dy - p.dy) * 0.22);
    c.drawPath(path, _stroke(const Color(0xFF4A4A4A), 1.3 * scale));
  }
  // The arm.
  final lo = pins.map((p) => p.dx).reduce(math.min) - 22 * scale;
  final hi = pins.map((p) => p.dx).reduce(math.max) + 22 * scale;
  final arm = Rect.fromLTRB(lo, armY + 2 * scale, hi, armY + 8 * scale);
  c.drawRect(arm, Paint()..shader = const LinearGradient(colors: [Color(0xFF6A5236), Color(0xFF8A6A44)]).createShader(arm));
  for (final p in pins) {
    final pinTop = Rect.fromCenter(center: Offset(p.dx, (p.dy + armY + 2 * scale) / 2), width: 7 * scale, height: (armY + 2 * scale - p.dy).abs() + 12 * scale);
    c.drawRRect(RRect.fromRectAndRadius(pinTop, Radius.circular(3 * scale)), _fill(const Color(0xFFB07A4A)));
    c.drawCircle(p, 3.4 * scale, _fill(const Color(0xFF3A3A3A)));
  }
}

/// A chain thrown across the pins [lo]..[hi]: the tail hangs on the player's
/// side, the other end on the far side.
List<Offset> m8LinePath(M8EndGeo e, int lo, int hi, {double drop = 96}) {
  final p = e.pins;
  final left = p[lo].dx - 14, right = p[hi].dx + 14;
  final top = math.min(p[lo].dy, p[hi].dy) - 4;
  final nearLeft = !e.s.mirrored;
  final nearDrop = drop, farDrop = drop * 0.72;
  return [
    Offset(left, top + (nearLeft ? nearDrop : farDrop)),
    Offset(left, top + 3),
    for (var i = lo; i <= hi; i++) Offset(p[i].dx, p[i].dy - 5),
    Offset(right, top + 3),
    Offset(right, top + (nearLeft ? farDrop : nearDrop)),
  ];
}

/// The coil of a pulled chain at [at].
List<Offset> m8CoilPath(Offset at, {double r = 24}) => [
      for (var k = 0; k <= 40; k++)
        at + Offset(math.cos(k / 40 * 3.6 * math.pi), math.sin(k / 40 * 3.6 * math.pi) * 0.55) * (r * (1 - 0.5 * k / 40)),
    ];

// ============================================================================
// The scene
// ============================================================================

class M8WorldPainter extends CustomPainter {
  const M8WorldPainter({required this.geo, required this.rig});

  final M8Geo geo;
  final M8Rig rig;

  @override
  void paint(Canvas c, Size size) {
    switch (rig.station) {
      case M8Station.sub:
        _sub(c, size);
      case M8Station.endA || M8Station.endB:
        _end(c, size);
      case M8Station.work:
        _work(c, size);
    }
  }

  // --- the substation ---------------------------------------------------------
  void _sub(Canvas c, Size size) {
    final g = geo;
    final wall = Rect.fromLTRB(0, 0, size.width, g.y(0.60));
    c.drawRect(wall, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8A9298), Color(0xFFB4BBBF)]).createShader(wall));
    final floor = Rect.fromLTRB(0, g.y(0.60), size.width, size.height);
    c.drawRect(floor, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF6E7378), Color(0xFF50555A)]).createShader(floor));
    // The feeder breaker's panel.
    final p = g.panel;
    c.drawRRect(RRect.fromRectAndRadius(p, const Radius.circular(6)), Paint()..shader = const LinearGradient(colors: [Color(0xFFCFD4D8), Color(0xFF9EA5AB)]).createShader(p));
    c.drawRRect(RRect.fromRectAndRadius(p, const Radius.circular(6)), _stroke(const Color(0xFF6A7178), 2));
    for (var i = 0; i < 3; i++) {
      c.drawCircle(Offset(p.left + 26 + i * 46.0, p.top + 22), 8, _fill(const Color(0xFF2E3338)));
      c.drawCircle(Offset(p.left + 26 + i * 46.0, p.top + 22), 4, _fill(const Color(0xFF8A9096)));
    }
    // The permit paper pinned on the panel (staged; not scored here).
    c.drawRect(Rect.fromLTWH(p.right - 38, p.top + 40, 28, 36), _fill(const Color(0xFFFFFFFF)));
    for (var i = 0; i < 4; i++) {
      c.drawLine(Offset(p.right - 34, p.top + 48 + i * 7.0), Offset(p.right - 14, p.top + 48 + i * 7.0), _stroke(const Color(0xFFB0B6BC), 1));
    }
    // The handle at OFF (down) and its hasp.
    final h = g.handle;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: h.translate(0, -26), width: 34, height: 12), const Radius.circular(3)), _fill(const Color(0xFF5A6066)));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: h.translate(0, -6), width: 14, height: 46), const Radius.circular(6)), Paint()..shader = const LinearGradient(colors: [Color(0xFFD64A38), Color(0xFF8E2A1E)]).createShader(Rect.fromCenter(center: h, width: 14, height: 46)));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: h.translate(0, 20), width: 24, height: 10), const Radius.circular(3)), _fill(const Color(0xFF454B50)));
    c.drawArc(Rect.fromCenter(center: h.translate(0, 22), width: 18, height: 16), math.pi, math.pi, false, _stroke(const Color(0xFF2E3338), 2.4));
    _text(c, 'OFF', h.translate(26, -4), size: 8, color: const Color(0xFF26303D));
    if (rig.sub.padlock) _padlock(c, h.translate(0, 28), 1.0);
    if (rig.sub.board) _board(c, g.boardOn);
    // The key-hook board.
    final hb = g.hookBoard;
    c.drawRRect(RRect.fromRectAndRadius(hb, const Radius.circular(4)), Paint()..shader = const LinearGradient(colors: [Color(0xFF8A5E34), Color(0xFF6A4624)]).createShader(hb));
    for (var i = 0; i < 4; i++) {
      final hook = Offset(hb.left + 16 + (i % 2) * 28.0, hb.top + 26 + (i ~/ 2) * 62.0);
      c.drawCircle(hook, 3, _fill(const Color(0xFFD7DCE0)));
      final decoy = i != 3 || rig.sub.key != M8Key.hook;
      if (decoy) {
        if (i < 3) _key(c, hook.translate(0, 14), const Color(0xFFB8BEC4));
      } else {
        _key(c, hook.translate(0, 14), const Color(0xFFF2CD6E));
      }
    }
    // The operator, his hand open.
    _operator(c, g.operator);
    if (rig.sub.key == M8Key.operator) _key(c, g.operatorHand.translate(0, -2), const Color(0xFFF2CD6E));
    // The bench tray.
    final t = g.tray;
    c.drawRRect(RRect.fromRectAndRadius(t, const Radius.circular(6)), Paint()..shader = const LinearGradient(colors: [Color(0xFF7A5A38), Color(0xFF5A4028)]).createShader(t));
    for (var i = 0; i < 4; i++) {
      final item = rig.sub.tray[i];
      if (item == null || (rig.held == M8Held.item && rig.heldSlot == i)) continue;
      m8PaintTrayItem(c, g.slot(i).center, item);
    }
    // The key: popped out of the lock, or in the pocket.
    if (rig.sub.key == M8Key.popped && rig.held != M8Held.key) _key(c, g.keyAt, const Color(0xFFF2CD6E), scale: 1.5);
    if (rig.sub.key == M8Key.pocket) _key(c, g.pocket.translate(0, -16), const Color(0xFFF2CD6E));
  }

  void _operator(Canvas c, Rect r) {
    final cx = r.center.dx;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(cx - 22, r.top + 40, cx + 22, r.bottom), const Radius.circular(10)), _fill(const Color(0xFF3A5A7A)));
    c.drawCircle(Offset(cx, r.top + 30), 14, _fill(const Color(0xFFD9A57A)));
    c.drawArc(Rect.fromCircle(center: Offset(cx, r.top + 28), radius: 16), math.pi, math.pi, true, _fill(const Color(0xFFE6B422)));
    // Arm out, palm up.
    final hand = geo.operatorHand;
    c.drawLine(Offset(cx - 18, r.top + 56), hand, _stroke(const Color(0xFF3A5A7A), 10));
    c.drawCircle(hand, 7, _fill(const Color(0xFFD9A57A)));
  }

  void _padlock(Canvas c, Offset at, double s) {
    c.drawArc(Rect.fromCenter(center: at.translate(0, -3 * s), width: 12 * s, height: 14 * s), math.pi, math.pi, false, _stroke(const Color(0xFFC8CDD2), 2.6 * s));
    final body = Rect.fromCenter(center: at.translate(0, 5 * s), width: 16 * s, height: 13 * s);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(2 * s)), Paint()..shader = const LinearGradient(colors: [Color(0xFFF2CD6E), Color(0xFFB8862E)]).createShader(body));
    c.drawCircle(at.translate(0, 5 * s), 1.6 * s, _fill(const Color(0xFF3A2A12)));
  }

  void _board(Canvas c, Rect r) {
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), _fill(const Color(0xFFD64A38)));
    c.drawRRect(RRect.fromRectAndRadius(r.deflate(2), const Radius.circular(2)), _stroke(const Color(0xFFFFFFFF), 1.2));
    c.drawLine(Offset(r.center.dx - 6, r.top - 4), Offset(r.center.dx - 6, r.top + 2), _stroke(const Color(0xFF2E3338), 1.4));
    c.drawLine(Offset(r.center.dx + 6, r.top - 4), Offset(r.center.dx + 6, r.top + 2), _stroke(const Color(0xFF2E3338), 1.4));
  }

  // --- an earth pole ---------------------------------------------------------
  void _end(Canvas c, Size size) {
    final g = geo;
    final i = rig.endIndex;
    final spec = rig.specs[i];
    final look = rig.ends[i];
    final e = M8EndGeo(g, spec);
    _grass(c, size, g);
    // The pole and its wires.
    _pole(c, g, e.poleX, e.armY, e.pins);
    // The tarp.
    final tarp = e.tarp;
    c.drawRRect(RRect.fromRectAndRadius(tarp, const Radius.circular(5)), Paint()..shader = const LinearGradient(colors: [Color(0xFF3F6E9A), Color(0xFF2C5276)]).createShader(tarp));
    c.drawRRect(RRect.fromRectAndRadius(tarp, const Radius.circular(5)), _stroke(const Color(0xFF1E3A56), 1.6));
    // The discard crate.
    final cr = e.crate;
    c.drawRRect(RRect.fromRectAndRadius(cr, const Radius.circular(3)), Paint()..shader = const LinearGradient(colors: [Color(0xFF9A7A4A), Color(0xFF6A4E2C)]).createShader(cr));
    for (var k = 1; k < 4; k++) {
      final x = cr.left + cr.width * k / 4;
      c.drawLine(Offset(x, cr.top + 2), Offset(x, cr.bottom - 2), _stroke(const Color(0x55000000), 1));
    }
    if (look.crate != null) {
      m8PaintChain(c, m8CoilPath(cr.center.translate(0, -2), r: 12), look.crate!, 1, r: 2.4);
    }
    // The earth spike, in the ground by the pole.
    c.drawRect(Rect.fromCenter(center: e.spike.translate(0, 14), width: 5, height: 34), _fill(const Color(0xFF8A9096)));
    c.drawCircle(e.spike.translate(0, -4), 5, _fill(const Color(0xFF6A7076)));
    if (look.clamped) _clamp(c, e.spike.translate(0, 2));
    // The kit on the tarp.
    if (look.tester && rig.held != M8Held.tester) _tester(c, e.tester, look.reading);
    if (look.tester) _prover(c, e.prover);
    if (!look.clamped && rig.held != M8Held.clamp) _clamp(c, e.clampRest);
    _bag(c, e, look);
    final rodHeld = rig.held == M8Held.rod;
    if (look.hookX == null && !rodHeld) {
      _rod(c, e.rodBase, e.rodRest, look.clamped ? e.spike.translate(0, 2) : e.clampRest);
    }
    if (look.hookX != null) {
      final head = Offset(look.hookX!, e.armY - 5);
      _rod(c, e.rodHandle(), head, e.spike.translate(0, 2), drained: look.drained);
    }
    // The chain.
    switch (look.at) {
      case M8ChainAt.bag:
        break;
      case M8ChainAt.coil:
        if (rig.held != M8Held.coil) m8PaintChain(c, m8CoilPath(e.coil), look.chain, look.defectSeg);
      case M8ChainAt.line:
        m8PaintChain(c, m8LinePath(e, look.lo, look.hi), look.chain, look.defectSeg);
      case M8ChainAt.down:
        break;
    }
  }

  void _bag(Canvas c, M8EndGeo e, M8EndLook look) {
    final o = e.bag;
    final body = Rect.fromCenter(center: o, width: 44, height: 40);
    c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(10)), Paint()..shader = const LinearGradient(colors: [Color(0xFF8A7A5A), Color(0xFF5E5238)]).createShader(body));
    c.drawLine(o.translate(-14, -14), o.translate(14, -14), _stroke(const Color(0xFF3A3220), 2.4));
    // Links hanging out while it is pulled.
    if (look.at == M8ChainAt.bag && look.pulled > 0) {
      final k = look.pulled / 3;
      final path = <Offset>[o.translate(0, -16), o.translate(10, -26 - 14 * k), o.translate(24, -22 - 6 * k), o.translate(34, -10 + 8 * k)];
      m8PaintChain(c, path, look.chain, look.defectSeg, reveal: k, r: 2.8);
    }
  }

  void _clamp(Canvas c, Offset at) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: at, width: 18, height: 12), const Radius.circular(3)), Paint()..shader = const LinearGradient(colors: [Color(0xFFE8C466), Color(0xFFA07A2A)]).createShader(Rect.fromCenter(center: at, width: 18, height: 12)));
    c.drawCircle(at, 2.2, _fill(const Color(0xFF3A2A12)));
    c.drawLine(at.translate(-9, 0), at.translate(-16, 5), _stroke(const Color(0xFFE8C466), 2.4));
  }

  void _tester(Canvas c, Offset at, String reading) {
    final body = Rect.fromCenter(center: at, width: 20, height: 40);
    c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(4)), Paint()..shader = const LinearGradient(colors: [Color(0xFFF2C94C), Color(0xFFC9972A)]).createShader(body));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: at.translate(0, -8), width: 14, height: 11), const Radius.circular(2)), _fill(const Color(0xFF1C2418)));
    _text(c, reading, at.translate(0, -8), size: reading.length > 3 ? 5.2 : 6, color: const Color(0xFFB8F0B0), weight: FontWeight.w900);
    c.drawLine(at.translate(0, -20), at.translate(0, -26), _stroke(const Color(0xFF8A9096), 2.2));
    c.drawCircle(at.translate(0, 9), 3, _fill(const Color(0xFFD64A38)));
  }

  void _prover(Canvas c, Offset at) {
    final body = Rect.fromCenter(center: at, width: 42, height: 30);
    c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(4)), Paint()..shader = const LinearGradient(colors: [Color(0xFFD64A38), Color(0xFF8E2A1E)]).createShader(body));
    c.drawCircle(at.translate(-8, -2), 4, _fill(const Color(0xFFFFE08A)));
    c.drawRect(Rect.fromCenter(center: at.translate(9, -2), width: 14, height: 8), _fill(const Color(0xFF1C2418)));
    _text(c, 'PROVE', at.translate(0, 9), size: 5.4, color: const Color(0xFFFFFFFF), weight: FontWeight.w900);
  }

  /// The rod: a long insulated shaft with a hooked head; its cable runs to the
  /// earth clamp. A drained rod's cable glows.
  void _rod(Canvas c, Offset base, Offset head, Offset cableTo, {bool drained = false}) {
    c.drawPath(
        Path()
          ..moveTo(base.dx, base.dy)
          ..quadraticBezierTo((base.dx + cableTo.dx) / 2, math.max(base.dy, cableTo.dy) + 14, cableTo.dx, cableTo.dy),
        _stroke(const Color(0xFF2E3338), 2.2));
    c.drawLine(base, head, _stroke(const Color(0xFFE8B422), 5.5));
    final dir = (head - base) / (head - base).distance;
    c.drawLine(base, base + dir * 26, _stroke(const Color(0xFF3A3F45), 6));
    // The hook.
    final hook = Path()
      ..moveTo(head.dx, head.dy)
      ..quadraticBezierTo(head.dx + 9, head.dy - 6, head.dx + 3, head.dy - 13);
    c.drawPath(hook, _stroke(const Color(0xFFC8CDD2), 3));
    if (drained) c.drawCircle(head, 7, _stroke(const Color(0x88FFE08A), 2));
  }

  // --- the work pole ---------------------------------------------------------
  void _work(Canvas c, Size size) {
    final g = geo;
    _grass(c, size, g);
    // The two earth poles far off, with what is on them.
    for (var i = 0; i < 2; i++) {
      final x = i == 0 ? M8Geo.farL : M8Geo.farR;
      final look = rig.ends[i];
      final pins = [for (var k = 0; k < 3; k++) Offset(x + (k - 1) * 8.0, g.farArmY)];
      _pole(c, g, x, g.farArmY, pins, scale: 0.55, baseY: g.gy + 2);
      if (look.at == M8ChainAt.line) {
        final p = [for (var k = look.lo; k <= look.hi; k++) pins[k].translate(0, -2)];
        if (p.length == 1) {
          c.drawLine(p.first.translate(-3, 0), p.first.translate(3, 0), _stroke(const Color(0xFFE8C466), 2.2));
        } else {
          c.drawLine(p.first.translate(-3, 0), p.last.translate(3, 0), _stroke(const Color(0xFFE8C466), 2.2));
        }
      }
      if (look.drained) {
        c.drawLine(Offset(x + (i == 0 ? 14 : -14), g.gy - 8), Offset(x + (look.hookX != null ? 0 : 0), g.farArmY - 2), _stroke(const Color(0xFFE8B422), 1.8));
      }
    }
    // The work pole: bigger, with its docket plate.
    final pins = [for (var k = 0; k < 3; k++) Offset(g.workX + (k - 1) * 30.0, g.workArmY)];
    _pole(c, g, g.workX, g.workArmY, pins, baseY: g.gy + 6);
    final d = g.docket;
    c.drawRRect(RRect.fromRectAndRadius(d, const Radius.circular(3)), _fill(const Color(0xFFF7F1DE)));
    c.drawRRect(RRect.fromRectAndRadius(d, const Radius.circular(3)), _stroke(const Color(0xFF8A6A3C), 1.2));
  }

  @override
  bool shouldRepaint(M8WorldPainter old) => old.geo != geo || old.rig != rig;
}

/// A tray item (also what the hand carries).
void m8PaintTrayItem(Canvas c, Offset at, M8TrayItem item) {
  switch (item) {
    case M8TrayItem.padlock:
      c.drawArc(Rect.fromCenter(center: at.translate(0, -6), width: 16, height: 18), math.pi, math.pi, false, _stroke(const Color(0xFFC8CDD2), 3.2));
      final body = Rect.fromCenter(center: at.translate(0, 7), width: 24, height: 20);
      c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(3)), Paint()..shader = const LinearGradient(colors: [Color(0xFFF2CD6E), Color(0xFFB8862E)]).createShader(body));
      c.drawCircle(at.translate(0, 7), 2.4, _fill(const Color(0xFF3A2A12)));
    case M8TrayItem.board:
      final r = Rect.fromCenter(center: at, width: 42, height: 24);
      c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), _fill(const Color(0xFFD64A38)));
      c.drawRRect(RRect.fromRectAndRadius(r.deflate(2.4), const Radius.circular(2)), _stroke(const Color(0xFFFFFFFF), 1.3));
    case M8TrayItem.torch:
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: at.translate(4, 4), width: 30, height: 12), const Radius.circular(4)), _fill(const Color(0xFF3A3F45)));
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: at.translate(-14, 4), width: 12, height: 18), const Radius.circular(3)), _fill(const Color(0xFFE8C466)));
    case M8TrayItem.tape:
      c.drawCircle(at, 14, _fill(const Color(0xFF202428)));
      c.drawCircle(at, 6, _fill(const Color(0xFF8A9096)));
    case M8TrayItem.fuse:
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: at, width: 30, height: 14), const Radius.circular(4)), _fill(const Color(0xFFE6E0D0)));
      c.drawRect(Rect.fromCenter(center: at.translate(-17, 0), width: 5, height: 12), _fill(const Color(0xFFB8BEC4)));
      c.drawRect(Rect.fromCenter(center: at.translate(17, 0), width: 5, height: 12), _fill(const Color(0xFFB8BEC4)));
    case M8TrayItem.rag:
      final p = Path()
        ..moveTo(at.dx - 16, at.dy - 8)
        ..quadraticBezierTo(at.dx, at.dy - 16, at.dx + 16, at.dy - 6)
        ..lineTo(at.dx + 12, at.dy + 10)
        ..quadraticBezierTo(at.dx, at.dy + 4, at.dx - 14, at.dy + 12)
        ..close();
      c.drawPath(p, _fill(const Color(0xFFC9B79A)));
  }
}

void _key(Canvas c, Offset at, Color col, {double scale = 1.0}) {
  c.drawCircle(at.translate(-5 * scale, 0), 4.2 * scale, _stroke(col, 2.2 * scale));
  c.drawLine(at.translate(-1 * scale, 0), at.translate(9 * scale, 0), _stroke(col, 2.2 * scale));
  c.drawLine(at.translate(6 * scale, 0), at.translate(6 * scale, 4 * scale), _stroke(col, 1.8 * scale));
  c.drawLine(at.translate(9 * scale, 0), at.translate(9 * scale, 3 * scale), _stroke(col, 1.8 * scale));
}

// ============================================================================
// The thing in the hand
// ============================================================================

class M8DragPainter extends CustomPainter {
  M8DragPainter({required this.view, required this.geo}) : super(repaint: view);

  final ValueNotifier<M8DragView?> view;
  final M8Geo geo;

  @override
  void paint(Canvas c, Size size) {
    final v = view.value;
    if (v == null) return;
    switch (v.held) {
      case M8Held.item:
        if (v.item != null) m8PaintTrayItem(c, v.at, v.item!);
      case M8Held.key:
        _key(c, v.at, const Color(0xFFF2CD6E), scale: 1.7);
      case M8Held.clamp:
        if (v.cable != null) c.drawLine(v.cable!, v.at, _stroke(const Color(0xFF2E3338), 2));
        M8WorldPainter(geo: geo, rig: _none)._clamp(c, v.at);
      case M8Held.rod:
        final base = v.base ?? v.at.translate(0, 120);
        if (v.cable != null) c.drawLine(base, v.cable!, _stroke(const Color(0xFF2E3338), 2));
        M8WorldPainter(geo: geo, rig: _none)._rod(c, base, v.at, v.cable ?? base);
      case M8Held.tester:
        M8WorldPainter(geo: geo, rig: _none)._tester(c, v.at, '- - -');
      case M8Held.coil:
        // A trail from the coil and the coiled chain in the hand.
        c.drawLine(v.start, v.at, _stroke(const Color(0x55FFFFFF), 3));
        m8PaintChain(c, m8CoilPath(v.at, r: 14), v.chain, 1, r: 2.4);
      case M8Held.bag:
        c.drawLine(v.start, v.at, _stroke(const Color(0x66FFFFFF), 2.4));
        c.drawCircle(v.at, 5, _fill(const Color(0xCCF2CD6E)));
      case M8Held.tail:
        c.drawLine(v.start, v.at, _stroke(const Color(0x66FFFFFF), 2.4));
        c.drawCircle(v.at, 5, _fill(const Color(0xCCF2CD6E)));
      case M8Held.none:
        break;
    }
  }

  static final M8Rig _none = M8Rig(station: M8Station.sub, sub: const M8SubLook(tray: [null, null, null, null]), ends: const [M8EndLook(), M8EndLook()], specs: const [
    M8EndSpec(mirrored: false, standDx: 60, condF: 0.12, spread: 30, raise: 0),
    M8EndSpec(mirrored: false, standDx: 60, condF: 0.12, spread: 30, raise: 0),
  ]);

  @override
  bool shouldRepaint(M8DragPainter old) => old.view != view || old.geo != geo;
}

/// The drain ring round the rod's head while it is held (the notifier runs 0 to 1).
class M8RingPainter extends CustomPainter {
  M8RingPainter({required this.at, required this.v}) : super(repaint: v);
  final Offset at;
  final ValueNotifier<double> v;

  @override
  void paint(Canvas c, Size size) {
    final t = v.value;
    if (t <= 0) return;
    c.drawCircle(at, 18, _stroke(const Color(0x66FFFFFF), 3));
    c.drawArc(Rect.fromCircle(center: at, radius: 18), -math.pi / 2, math.pi * 2 * t, false, _stroke(const Color(0xFFFFE08A), 4));
    if (t >= 1) {
      for (var i = 0; i < 8; i++) {
        final a = i / 8 * math.pi * 2;
        c.drawLine(at + Offset(math.cos(a), math.sin(a)) * 22, at + Offset(math.cos(a), math.sin(a)) * 30, _stroke(const Color(0xFFFFE08A), 2));
      }
    }
  }

  @override
  bool shouldRepaint(M8RingPainter old) => old.at != at;
}

/// The crew mate at the work pole: at the foot, up at work, coming down (t
/// 0 to 1, top to ground) or waving on the ground.
class M8MatePainter extends CustomPainter {
  const M8MatePainter({required this.geo, required this.mode, required this.t, this.wave = 0});
  final M8Geo geo;
  final M8Mate mode;
  final double t;
  final double wave;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    Offset at;
    var up = false;
    switch (mode) {
      case M8Mate.idle:
        at = g.mateBase;
      case M8Mate.job:
        at = g.mateTop;
        up = true;
      case M8Mate.descend:
        at = Offset.lerp(g.mateTop, g.mateBase, Curves.easeInOut.transform(t.clamp(0.0, 1.0)))!;
        up = t < 1;
      case M8Mate.cleared:
        at = g.mateBase;
    }
    final skin = _fill(const Color(0xFFD9A57A));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: at.translate(0, -16), width: 18, height: 30), const Radius.circular(6)), _fill(const Color(0xFFE0782A)));
    c.drawCircle(at.translate(0, -36), 8, skin);
    c.drawArc(Rect.fromCircle(center: at.translate(0, -37), radius: 9), math.pi, math.pi, true, _fill(const Color(0xFFE6B422)));
    if (up) {
      c.drawLine(at.translate(-9, -22), at.translate(-16, -34), _stroke(const Color(0xFFE0782A), 5));
      c.drawLine(at.translate(9, -22), at.translate(16, -34), _stroke(const Color(0xFFE0782A), 5));
    } else if (mode == M8Mate.cleared) {
      final sw = math.sin(wave * math.pi * 6) * 6;
      c.drawLine(at.translate(9, -24), at.translate(16 + sw, -46), _stroke(const Color(0xFFE0782A), 5));
      c.drawCircle(at.translate(16 + sw, -48), 3.4, skin);
      c.drawLine(at.translate(-9, -24), at.translate(-12, -10), _stroke(const Color(0xFFE0782A), 5));
    } else {
      c.drawLine(at.translate(-9, -24), at.translate(-12, -10), _stroke(const Color(0xFFE0782A), 5));
      c.drawLine(at.translate(9, -24), at.translate(12, -10), _stroke(const Color(0xFFE0782A), 5));
    }
  }

  @override
  bool shouldRepaint(M8MatePainter old) => old.mode != mode || old.t != t || old.wave != wave || old.geo != geo;
}

/// A chain in flight from the coil to where it lands (v 0 to 1), then it
/// settles over the pins ([landing] is the line path it ends on, or null for
/// a fall back / a slide off).
class M8FlightPainter extends CustomPainter {
  const M8FlightPainter({required this.from, required this.to, required this.v, required this.kind, required this.chain, this.back = false});
  final Offset from;
  final Offset to;
  final double v;
  final M8ChainKind chain;
  final M8ThrowKind kind;
  final bool back;

  @override
  void paint(Canvas c, Size size) {
    final up = (v * 2).clamp(0.0, 1.0);
    final down = ((v - 0.5) * 2).clamp(0.0, 1.0);
    Offset at;
    if (back || kind == M8ThrowKind.short || kind == M8ThrowKind.beside) {
      final peak = Offset.lerp(from, to, 0.7)!;
      at = v < 0.5 ? Offset.lerp(from, peak, Curves.easeOut.transform(up))! : Offset.lerp(peak, from.translate(0, 8), Curves.easeIn.transform(down))!;
    } else if (kind == M8ThrowKind.over) {
      final peak = to.translate(0, -10);
      at = v < 0.5 ? Offset.lerp(from, peak, Curves.easeOut.transform(up))! : Offset.lerp(peak, to.translate(120, 80), Curves.easeIn.transform(down))!;
    } else {
      at = Offset.lerp(from, to, Curves.easeOut.transform(v))!;
    }
    m8PaintChain(c, m8CoilPath(at, r: 13), chain, 1, r: 2.4);
  }

  @override
  bool shouldRepaint(M8FlightPainter old) => old.v != v || old.from != from || old.to != to;
}

/// The spark and flash where a chain (or a hook) met a line with no earth.
class M8FlashPainter extends CustomPainter {
  const M8FlashPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final flick = v < 0.5 ? (0.65 + 0.35 * math.sin(v * 60).abs()) : (1 - (v - 0.5) * 1.2).clamp(0.4, 1.0);
    final r = 30 + 80 * Curves.easeOut.transform(v.clamp(0.0, 1.0));
    c.drawCircle(
        at,
        r,
        Paint()
          ..shader = RadialGradient(colors: [Color.fromRGBO(255, 250, 225, 0.95 * flick), Color.fromRGBO(130, 165, 255, 0.5 * flick), const Color(0x00FFC24A)]).createShader(Rect.fromCircle(center: at, radius: r)));
    final spark = _stroke(Color.fromRGBO(255, 214, 90, (1 - v).clamp(0.0, 1.0)), 2.4);
    for (var i = 0; i < 16; i++) {
      final a = i / 16 * math.pi * 2 + 0.2;
      final d0 = 10 + 56 * v;
      c.drawLine(at + Offset(math.cos(a), math.sin(a)) * d0, at + Offset(math.cos(a), math.sin(a)) * (d0 + 14), spark);
    }
    final white = (1 - v * 4).clamp(0.0, 1.0);
    if (white > 0) c.drawRect(Offset.zero & size, _fill(Color.fromRGBO(255, 255, 255, 0.8 * white)));
  }

  @override
  bool shouldRepaint(M8FlashPainter old) => old.v != v || old.at != at;
}
