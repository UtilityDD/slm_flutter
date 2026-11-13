import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The drawn world of lesson 5.3 কাজ 2 "পোড়া জোড়, নরম তার" (m5_anneal_cut.dart).
//
// Two views:
//  • the section (pole 7 to pole 9, under the permit): three poles with their
//    number plates, the three phases R, Y, B across them, an earth set at each
//    end — clamped on and led down to its spike, or coiled on the ground by
//    the spike (a bare end);
//  • the workbench close-up of one repair spot: the conductor across the
//    screen between two gloved hands, and what sits in the middle:
//      jumper    — the burnt PG clamp (nut + spanner), the jumper hanging off
//                  it in a U loop on its side, the line straight on the other;
//      sleeve    — a long, heat-discoloured bolted joint sleeve (nut + spanner);
//      connector — the burnt PG clamp on a straight conductor;
//      snapped   — no clamp at all: two pieces with a gap, melted (beaded)
//                  ends drooping.
//    A soft (annealed) length shows only as a faint discolouration that fades
//    out with no edge, kinks where a bend stayed, the player's red tapes, the
//    cut faces (dark = still soft metal), the new part fitted at the end, and
//    the tool belt with the tray of two red tapes.
//
// No text in the art except the pole number plates (labels a worker reads).
// Day, overcast or dusk; at dusk the discolouration is faint. Code-drawn,
// gradients, no bitmaps. Design: 360 wide × the scene's height.

/// The light of the play.
enum M5AnnealLight { day, overcast, dusk }

/// The kinds of repair spot (the workbench).
enum M5AnnealKind {
  /// A burnt PG clamp on the jumper (the jumper soft or sound).
  jumper,

  /// An overheated, discoloured joint sleeve: the conductor round it soft.
  sleeve,

  /// A burnt connector on a sound conductor (only the connector to change).
  connector,

  /// The conductor snapped at a hotspot: melted (beaded) ends, soft behind.
  snapped,
}

/// The old joint sleeve's length on the bench (design px).
const double m5AnnealSleeveW = 76;

/// The gap the old clamp leaves on the bench (0..1 along the conductor).
const double m5AnnealGapLo = 0.47;
const double m5AnnealGapHi = 0.53;

/// Tapes and bends work on the conductor between the gloves only.
const double m5AnnealMinU = 0.06;
const double m5AnnealMaxU = 0.94;

/// The jumper's U loop: how deep it hangs (design px), and where (0..1 from
/// the far glove's side: 1 - this) it is back up at the glove's height.
const double m5AnnealUDepth = 28;
const double m5AnnealJumperEnd = 0.96;

/// How far a snapped conductor's broken ends droop (design px), and over what
/// length behind the break (0..1).
const double m5AnnealSnapDroop = 9;
const double m5AnnealSnapReach = 0.09;

/// The conductor's resting drop below the bench line at [u] (design px): the
/// jumper's U loop on its side; a snapped conductor's broken ends droop; a
/// sleeve or a connector spot lies straight.
double m5AnnealRestDy(M5AnnealKind kind, bool jumperRight, double u) {
  switch (kind) {
    case M5AnnealKind.jumper:
      final t = jumperRight
          ? (u - m5AnnealGapHi) / (m5AnnealJumperEnd - m5AnnealGapHi)
          : (m5AnnealGapLo - u) / (m5AnnealGapLo - (1 - m5AnnealJumperEnd));
      if (t <= 0 || t >= 1) return 0;
      return m5AnnealUDepth * math.sin(t * math.pi);
    case M5AnnealKind.snapped:
      final d = u < 0.5 ? u - (m5AnnealGapLo - m5AnnealSnapReach) : (m5AnnealGapHi + m5AnnealSnapReach) - u;
      if (d <= 0) return 0;
      final f = (d / m5AnnealSnapReach).clamp(0.0, 1.0);
      return m5AnnealSnapDroop * f * f;
    case M5AnnealKind.sleeve:
    case M5AnnealKind.connector:
      return 0;
  }
}

/// Where things are (design px, 360 wide).
@immutable
class M5AnnealGeo {
  const M5AnnealGeo._(this.height, this.groundY, this.topY);

  factory M5AnnealGeo.forScene(double height, double inset) {
    final g = height - floorUp - inset * 0.5;
    return M5AnnealGeo._(height, g, math.max(150.0, g - 420));
  }

  final double height;

  /// The ground line (the section) / the belt's foot (the bench).
  final double groundY;

  /// The pole tops (the section).
  final double topY;

  /// The ground sits this far above the bottom (the tool row stands on it).
  static const double floorUp = 112;

  // --- the section ------------------------------------------------------------
  /// Poles 7, 8, 9.
  static const List<double> poleX = [60, 180, 300];
  static const List<String> poleNo = ['7', '8', '9'];

  double get armY => topY + 34;

  /// The three phases' height at [x] (R top, Y, B), with a little sag mid-span.
  double wireY(int phase, double x) {
    final base = armY - 12 + phase * 12.0;
    // Sag between neighbouring poles.
    final span = x < 180 ? (x - 60) / 120 : (x - 180) / 120;
    final s = (span > 0 && span < 1) ? math.sin(span * math.pi) * 10 : 0.0;
    return base + s;
  }

  /// Tap here to test / earth the end at pole 7 ([left]) or pole 9.
  Rect endHit(bool left) => Rect.fromCenter(center: Offset(left ? poleX[0] : poleX[2], armY + 24), width: 96, height: 120);

  /// Where an end's earth set clamps (just inside the span) and its spike.
  double clampX(bool left) => left ? poleX[0] + 18 : poleX[2] - 18;
  Offset spike(bool left) => Offset(left ? 30 : 330, groundY - 4);

  /// Where the tester reading shows for an end.
  Offset testerAt(bool left) => Offset(left ? 18 : 228, armY + 70);

  /// The trainee on the ground (by pole 8).
  Rect get ground => Rect.fromLTWH(150, groundY - 112, 56, 112);

  /// Where the flash goes on a deadly climb (the bare end's line).
  Offset flashAt(bool left) => Offset(clampX(left), armY);

  // --- the bench ---------------------------------------------------------------
  /// The conductor's height on the bench.
  double get condY => math.max(200.0, height * 0.42);

  static const double benchL = 24;
  static const double benchR = 336;

  double xOf(double u) => benchL + u * (benchR - benchL);
  double uOf(double x) => (x - benchL) / (benchR - benchL);

  /// The old clamp's nut (the middle of the bench).
  Offset get nut => Offset(xOf(0.5), condY);

  /// The tray of red tapes on the tool belt, on the right (clear of the
  /// corner guide and its speech bubble on the left).
  Rect get tray => Rect.fromLTWH(232, groundY - 150, 116, 60);

  /// The conductor's line at [u] for a spot of [kind] (the jumper's U, a
  /// snapped end's droop).
  double lineY(M5AnnealKind kind, bool jumperRight, double u) => condY + m5AnnealRestDy(kind, jumperRight, u);

  /// The conductor band (bend, tape drop), round the drawn line.
  bool onLine(Offset p, M5AnnealKind kind, bool jumperRight) =>
      p.dx >= xOf(0.03) && p.dx <= xOf(0.97) && (p.dy - lineY(kind, jumperRight, uOf(p.dx))).abs() < 26;

  /// Where the gesture hand holds (always the same place along the conductor).
  static const double holdU = 0.3;

  @override
  bool operator ==(Object other) => other is M5AnnealGeo && other.height == height && other.groundY == groundY && other.topY == topY;

  @override
  int get hashCode => Object.hash(height, groundY, topY);
}

Color _skyTop(M5AnnealLight l) => switch (l) {
      M5AnnealLight.day => const Color(0xFF3F79B8),
      M5AnnealLight.overcast => const Color(0xFF6B7684),
      M5AnnealLight.dusk => const Color(0xFF2B2F52),
    };

Color _skyLow(M5AnnealLight l) => switch (l) {
      M5AnnealLight.day => const Color(0xFFCFE4EF),
      M5AnnealLight.overcast => const Color(0xFFB8BEC4),
      M5AnnealLight.dusk => const Color(0xFFD98A5C),
    };

/// How strong the soft length's discolouration shows in this light.
double m5AnnealTint(M5AnnealLight l) => switch (l) {
      M5AnnealLight.day => 0.8,
      M5AnnealLight.overcast => 0.62,
      M5AnnealLight.dusk => 0.34,
    };

// ============================================================================
// The section
// ============================================================================

class M5AnnealSitePainter extends CustomPainter {
  const M5AnnealSitePainter({required this.geo, required this.light, required this.earthL, required this.earthR, required this.seed});

  final M5AnnealGeo geo;
  final M5AnnealLight light;
  final bool earthL;
  final bool earthR;
  final int seed;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    final sky = Rect.fromLTWH(0, 0, w, g.groundY);
    c.drawRect(sky, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_skyTop(light), _skyLow(light)]).createShader(sky));
    final rnd = math.Random(seed);
    if (light != M5AnnealLight.dusk) {
      final cloud = Paint()..color = light == M5AnnealLight.overcast ? const Color(0x99D9DDE2) : const Color(0xCCFFFFFF);
      for (var i = 0; i < 4; i++) {
        final cx = 30 + rnd.nextDouble() * 300;
        final cy = 70 + rnd.nextDouble() * (g.topY - 40).clamp(20.0, 220.0);
        for (var k = 0; k < 4; k++) {
          c.drawOval(Rect.fromCenter(center: Offset(cx + k * 14 - 20, cy - (k.isOdd ? 6 : 0)), width: 36, height: 18), cloud);
        }
      }
    }
    // Far trees and fields.
    final horizon = g.groundY - (g.groundY - g.topY) * 0.2;
    final tree = Paint()..color = light == M5AnnealLight.dusk ? const Color(0xFF2E3D33) : const Color(0xFF4F7F45);
    for (var x = -10.0; x < w + 20; x += 18 + rnd.nextDouble() * 18) {
      final r = 8 + rnd.nextDouble() * 10;
      c.drawCircle(Offset(x, horizon - r * 0.5), r, tree);
    }
    c.drawRect(Rect.fromLTRB(0, horizon, w, g.groundY), Paint()..color = light == M5AnnealLight.dusk ? const Color(0xFF5E6B3C) : const Color(0xFF8DB55A));
    final floor = Rect.fromLTRB(0, g.groundY, w, size.height);
    c.drawRect(floor, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFA88B62), Color(0xFF7A6345)]).createShader(floor));

    // The phases run on past both ends (the line beyond the section).
    final wire = Paint()
      ..color = const Color(0xFF30363C)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    for (var p = 0; p < 3; p++) {
      final path = Path()..moveTo(0, g.wireY(p, 0) + 6);
      for (var x = 0.0; x <= w; x += 6) {
        final y = x < M5AnnealGeo.poleX[0]
            ? g.wireY(p, M5AnnealGeo.poleX[0]) + (M5AnnealGeo.poleX[0] - x) / M5AnnealGeo.poleX[0] * 6
            : x > M5AnnealGeo.poleX[2]
                ? g.wireY(p, M5AnnealGeo.poleX[2]) + (x - M5AnnealGeo.poleX[2]) / (w - M5AnnealGeo.poleX[2]) * 6
                : g.wireY(p, x);
        path.lineTo(x, y);
      }
      c.drawPath(path, wire);
    }
    for (final (i, x) in M5AnnealGeo.poleX.indexed) {
      _pole(c, x, M5AnnealGeo.poleNo[i]);
    }
    // The old repair on the middle span (a dark burnt clamp on Y).
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(236, g.wireY(1, 236)), width: 12, height: 7), const Radius.circular(2)),
        Paint()..color = const Color(0xFF2A2420));
    _earth(c, true, earthL);
    _earth(c, false, earthR);
  }

  void _pole(Canvas c, double x, String no) {
    final g = geo;
    final r = Rect.fromLTRB(x - 5, g.topY, x + 5, g.groundY + 4);
    c.drawRect(r, Paint()..shader = const LinearGradient(colors: [Color(0xFF8C939A), Color(0xFFC9CED2), Color(0xFF7A8187)]).createShader(r));
    // Cross-arm and three pin insulators.
    c.drawLine(Offset(x - 26, g.armY + 14), Offset(x + 26, g.armY + 14), Paint()
      ..color = const Color(0xFF4E565D)
      ..strokeWidth = 6);
    final porcelain = Paint()..color = const Color(0xFFE6EAEE);
    for (var p = 0; p < 3; p++) {
      final y = g.wireY(p, x);
      c.drawOval(Rect.fromCenter(center: Offset(x + (p - 1) * 2.0, y + 3), width: 9, height: 6), porcelain);
    }
    // The number plate (a label a worker reads).
    final plate = Rect.fromCenter(center: Offset(x, g.groundY - 70), width: 18, height: 20);
    c.drawRRect(RRect.fromRectAndRadius(plate, const Radius.circular(3)), Paint()..color = const Color(0xFFF2D24B));
    final tp = TextPainter(
      text: TextSpan(text: no, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF1B1B1B))),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, plate.center - Offset(tp.width / 2, tp.height / 2));
  }

  void _earth(Canvas c, bool left, bool on) {
    final g = geo;
    final spike = g.spike(left);
    c.drawLine(spike, spike.translate(0, 10), Paint()
      ..color = const Color(0xFF5A6066)
      ..strokeWidth = 4);
    c.drawCircle(spike, 4, Paint()..color = const Color(0xFF8C939A));
    final copper = Paint()
      ..color = const Color(0xFFC87533)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    if (on) {
      final x = g.clampX(left);
      final top = g.wireY(0, x);
      final low = g.wireY(2, x);
      // A clamp on each phase, the shorting bar, the lead down to the spike.
      for (var p = 0; p < 3; p++) {
        c.drawRect(Rect.fromCenter(center: Offset(x, g.wireY(p, x)), width: 6, height: 7), Paint()..color = const Color(0xFF3A3F45));
      }
      c.drawLine(Offset(x, top), Offset(x, low + 10), Paint()
        ..color = const Color(0xFF3A3F45)
        ..strokeWidth = 3);
      c.drawPath(
          Path()
            ..moveTo(x, low + 10)
            ..quadraticBezierTo(x + (left ? -10 : 10), (low + spike.dy) / 2, spike.dx, spike.dy),
          copper);
      c.drawCircle(spike, 5, Paint()..color = const Color(0xFFC87533));
    } else {
      // The earth set coiled on the ground by the spike.
      final at = spike.translate(left ? 16 : -16, 2);
      c.drawOval(Rect.fromCenter(center: at, width: 24, height: 9), copper);
      c.drawOval(Rect.fromCenter(center: at.translate(0, -1), width: 17, height: 6), copper);
      c.drawRect(Rect.fromCenter(center: at.translate(left ? 12 : -12, -3), width: 6, height: 6), Paint()..color = const Color(0xFF3A3F45));
    }
  }

  @override
  bool shouldRepaint(M5AnnealSitePainter old) =>
      old.geo != geo || old.light != light || old.earthL != earthL || old.earthR != earthR || old.seed != seed;
}

// ============================================================================
// The bench
// ============================================================================

/// What the workbench shows now.
@immutable
class M5AnnealBench {
  const M5AnnealBench({
    required this.kind,
    required this.lo,
    required this.hi,
    required this.jumperRight,
    required this.clampOff,
    required this.turn,
    required this.endL,
    required this.endR,
    required this.darkL,
    required this.darkR,
    required this.tapes,
    required this.trayLeft,
    required this.kinks,
    required this.fitted,
    this.flexAt = 0,
    this.flex = 0,
    this.ghost,
  });

  final M5AnnealKind kind;

  /// The soft length (lo == hi: none).
  final double lo;
  final double hi;
  final bool jumperRight;
  final bool clampOff;

  /// The nut's turn (radians) while the spanner works.
  final double turn;

  /// The ends of the two pieces once the clamp is off.
  final double endL;
  final double endR;
  final bool darkL;
  final bool darkR;

  /// Tapes on the conductor (not cut yet).
  final List<double> tapes;
  final int trayLeft;

  /// Bends that stayed (soft metal).
  final List<double> kinks;

  /// The repair is done: the new part is on.
  final bool fitted;

  /// A bend test in progress: where, and how far (0 = straight, 1 = full bend).
  final double flexAt;
  final double flex;

  /// A tape being dragged (design px), or null.
  final Offset? ghost;

  bool get soft => hi - lo > 0.001;

  @override
  bool operator ==(Object other) =>
      other is M5AnnealBench &&
      other.kind == kind &&
      other.lo == lo &&
      other.hi == hi &&
      other.jumperRight == jumperRight &&
      other.clampOff == clampOff &&
      other.turn == turn &&
      other.endL == endL &&
      other.endR == endR &&
      other.darkL == darkL &&
      other.darkR == darkR &&
      listEquals(other.tapes, tapes) &&
      other.trayLeft == trayLeft &&
      listEquals(other.kinks, kinks) &&
      other.fitted == fitted &&
      other.flexAt == flexAt &&
      other.flex == flex &&
      other.ghost == ghost;

  @override
  int get hashCode => Object.hash(kind, lo, hi, jumperRight, clampOff, turn, endL, endR, darkL, darkR, Object.hashAll(tapes), trayLeft,
      Object.hashAll(kinks), fitted, flexAt, flex, ghost);
}

class M5AnnealBenchPainter extends CustomPainter {
  const M5AnnealBenchPainter({required this.geo, required this.light, required this.bench});

  final M5AnnealGeo geo;
  final M5AnnealLight light;
  final M5AnnealBench bench;

  static const _kinkAmp = 8.0;
  static const _flexAmp = 14.0;

  /// The resting line's drop at [u] (the jumper's U, a snapped end's droop).
  double _rest(double u) => m5AnnealRestDy(bench.kind, bench.jumperRight, u);

  /// A kink still on a piece of conductor that is there (not cut away, not
  /// replaced by the new part).
  bool _kinkShows(double k) => !bench.fitted && (!bench.clampOff || k < bench.endL || k > bench.endR);

  /// The conductor's drop at [u] (its resting line + bends that stayed + a
  /// bend in progress).
  double _dy(double u) {
    var d = _rest(u);
    for (final k in bench.kinks) {
      if (!_kinkShows(k)) continue;
      final t = (u - k).abs() / 0.022;
      if (t < 1) d += _kinkAmp * (1 - t);
    }
    if (bench.flex > 0) {
      final t = (u - bench.flexAt).abs() / 0.04;
      if (t < 1) d += _flexAmp * bench.flex * math.cos(t * math.pi / 2);
    }
    return d;
  }

  /// The discolouration at [u] (0..1): full in the middle of the soft
  /// length, fading out before its end — no edge to read.
  double _tintAt(double u) {
    final b = bench;
    if (!b.soft || u <= b.lo || u >= b.hi) return 0;
    final mid = (b.lo + b.hi) / 2;
    final half = (u < mid ? mid - b.lo : b.hi - mid).clamp(0.001, 1.0);
    final f = (u - mid).abs() / half; // 0 middle → 1 at the end
    if (f < 0.55) return 1;
    return ((1 - f) / 0.45).clamp(0.0, 1.0);
  }

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    final sky = Rect.fromLTWH(0, 0, w, size.height);
    c.drawRect(sky, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_skyTop(light), _skyLow(light)]).createShader(sky));
    // The pole top behind (out of focus): a cross-arm and the pole.
    final back = Paint()..color = const Color(0x334E565D);
    c.drawRect(Rect.fromLTWH(206, 0, 22, size.height), back);
    c.drawRect(Rect.fromLTWH(0, g.condY - 70, w, 14), back);

    _conductor(c);
    _ends(c);
    if (!bench.clampOff) _clamp(c);
    _fitted(c);
    _tapes(c);
    _gloves(c);
    _belt(c, size);
    final ghost = bench.ghost;
    if (ghost != null) _tape(c, ghost, lifted: true);
  }

  /// The pieces of conductor on the bench (whole while the clamp is on).
  List<(double, double)> get _pieces => bench.clampOff
      ? [(0.0, bench.endL), (bench.endR, 1.0)]
      : [(0.0, 1.0)];

  void _conductor(Canvas c) {
    final g = geo;
    final tint = m5AnnealTint(light);
    final outline = Paint()
      ..color = const Color(0xFF4A5056)
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.butt
      ..style = PaintingStyle.stroke;
    final core = Paint()
      ..color = const Color(0xFFC9CFD4)
      ..strokeWidth = 8.4
      ..style = PaintingStyle.stroke;
    final strand = Paint()
      ..color = const Color(0x557A8288)
      ..strokeWidth = 1;
    for (final (a, b) in _pieces) {
      if (b - a < 0.002) continue;
      final path = Path();
      for (var u = a; u <= b + 1e-9; u += 0.004) {
        final p = Offset(g.xOf(u), g.condY + _dy(u));
        if (u == a) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      path.lineTo(g.xOf(b), g.condY + _dy(b));
      c.drawPath(path, outline);
      c.drawPath(path, core);
      // The strands' lay (short slanted marks).
      for (var u = a + 0.01; u < b - 0.005; u += 0.018) {
        final x = g.xOf(u);
        final y = g.condY + _dy(u);
        c.drawLine(Offset(x - 2.6, y - 3.6), Offset(x + 2.6, y + 3.6), strand);
      }
      // The discolouration (soft metal), fading out with no edge.
      for (var u = a; u < b; u += 0.006) {
        final f = _tintAt(u + 0.003);
        if (f <= 0) continue;
        final x0 = g.xOf(u);
        final x1 = g.xOf(math.min(b, u + 0.006));
        final y = g.condY + _dy(u + 0.003);
        c.drawLine(Offset(x0, y), Offset(x1, y), Paint()
          ..color = Color.fromRGBO(92, 62, 34, tint * f)
          ..strokeWidth = 8.6);
      }
    }
    // Kinks that stayed: splayed strands.
    final splay = Paint()
      ..color = const Color(0xFF9AA1A7)
      ..strokeWidth = 1.2;
    for (final k in bench.kinks) {
      if (!_kinkShows(k)) continue;
      final x = g.xOf(k);
      final y = g.condY + _dy(k);
      for (var i = -2; i <= 2; i++) {
        c.drawLine(Offset(x, y + 2), Offset(x + i * 3.2, y + 9 + (i.abs() * 1.5)), splay);
      }
    }
  }

  void _ends(Canvas c) {
    if (!bench.clampOff) return;
    final g = geo;
    final b = bench;
    final snapped = b.kind == M5AnnealKind.snapped;
    for (final left in [true, false]) {
      final u = left ? b.endL : b.endR;
      final at = Offset(g.xOf(u), g.condY + _dy(u));
      final dark = left ? b.darkL : b.darkR;
      final beaded = snapped && (left ? u >= m5AnnealGapLo - 1e-6 : u <= m5AnnealGapHi + 1e-6);
      if (beaded) {
        // A melted bead, strands splayed behind it.
        c.drawCircle(at.translate(left ? -1 : 1, 0), 7, Paint()..color = const Color(0xFF55504A));
        c.drawCircle(at.translate(left ? -2 : 2, -1.5), 2, Paint()..color = const Color(0x88D8D2C8));
        // Scorched, splayed strands just behind the bead.
        final burnt = Paint()
          ..color = const Color(0xFF6E5E4C)
          ..strokeWidth = 1.2;
        final bx = at.dx + (left ? -9 : 9);
        for (var i = -1; i <= 1; i++) {
          c.drawLine(Offset(bx, at.dy), Offset(bx + (left ? -3 : 3), at.dy + 6 + i * 3.0), burnt);
        }
      } else {
        c.drawOval(Rect.fromCenter(center: at, width: 6, height: 12), Paint()..color = dark ? const Color(0xFF3B2E22) : const Color(0xFFE4E8EB));
        c.drawOval(
            Rect.fromCenter(center: at, width: 6, height: 12),
            Paint()
              ..color = const Color(0xFF4A5056)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1);
      }
    }
  }

  void _clamp(Canvas c) {
    final g = geo;
    final n = g.nut;
    // Nothing holds a snapped conductor (its round starts with the pieces apart).
    if (bench.kind == M5AnnealKind.snapped) return;
    if (bench.kind == M5AnnealKind.sleeve) {
      // A long bolted joint sleeve, overheated: temper colours (straw, brown,
      // blue) and soot, crimp rings near its ends.
      final body = RRect.fromRectAndRadius(Rect.fromCenter(center: n, width: m5AnnealSleeveW, height: 18), const Radius.circular(8));
      c.drawRRect(
          body,
          Paint()
            ..shader = const LinearGradient(
              colors: [Color(0xFF9C8F7E), Color(0xFFB8945A), Color(0xFF7A4E2E), Color(0xFF4E4A72), Color(0xFF7A4E2E), Color(0xFFB8945A), Color(0xFF9C8F7E)],
              stops: [0, 0.16, 0.34, 0.5, 0.66, 0.84, 1],
            ).createShader(body.outerRect));
      c.drawRRect(
          body,
          Paint()
            ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x33FFFFFF), Color(0x00FFFFFF), Color(0x55000000)])
                .createShader(body.outerRect));
      final ring = Paint()
        ..color = const Color(0x66302820)
        ..strokeWidth = 1.4;
      for (final dx in const [-30.0, -25.0, 25.0, 30.0]) {
        c.drawLine(n.translate(dx, -8), n.translate(dx, 8), ring);
      }
      final soot = Paint()..color = const Color(0x8C1E1A17);
      c.drawOval(Rect.fromCenter(center: n.translate(-14, 5), width: 14, height: 6), soot);
      c.drawOval(Rect.fromCenter(center: n.translate(16, -5), width: 10, height: 5), soot);
    } else {
      // The burnt PG clamp (blackened, melted at an edge).
      final body = RRect.fromRectAndRadius(Rect.fromCenter(center: n, width: 46, height: 24), const Radius.circular(4));
      c.drawRRect(body, Paint()..shader = const LinearGradient(colors: [Color(0xFF2B2622), Color(0xFF5A4E44), Color(0xFF231F1C)]).createShader(body.outerRect));
      c.drawCircle(n.translate(-14, 8), 4, Paint()..color = const Color(0xFF1A1715));
    }
    // The nut, turned by the spanner.
    c.save();
    c.translate(n.dx, n.dy);
    c.rotate(bench.turn);
    final hex = Path();
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      final p = Offset(math.cos(a) * 9, math.sin(a) * 9);
      if (i == 0) {
        hex.moveTo(p.dx, p.dy);
      } else {
        hex.lineTo(p.dx, p.dy);
      }
    }
    hex.close();
    c.drawPath(hex, Paint()..color = const Color(0xFF8C939A));
    c.drawCircle(Offset.zero, 3, Paint()..color = const Color(0xFF4A5056));
    if (bench.turn != 0) {
      // The spanner on the nut.
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8, -4, 46, 8), const Radius.circular(3)), Paint()..color = const Color(0xFF7D8A96));
    }
    c.restore();
  }

  void _fitted(Canvas c) {
    final b = bench;
    if (!b.fitted) return;
    final g = geo;
    const shine = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF2F4F6), Color(0xFF9EA6AD)]);
    // The new length between the pieces, along the resting line (a new
    // jumper keeps its U).
    final path = Path()..moveTo(g.xOf(b.endL), g.condY + _rest(b.endL));
    for (var u = b.endL; u <= b.endR; u += 0.004) {
      path.lineTo(g.xOf(u), g.condY + _rest(u));
    }
    path.lineTo(g.xOf(b.endR), g.condY + _rest(b.endR));
    c.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF4A5056)
          ..strokeWidth = 12
          ..style = PaintingStyle.stroke);
    c.drawPath(
        path,
        Paint()
          ..color = b.soft ? const Color(0xFFE8EDF1) : const Color(0xFFC9CFD4)
          ..strokeWidth = 8.4
          ..style = PaintingStyle.stroke);
    // A joint sleeve at each cut end; a new connector where an end was not cut.
    final cutL = b.endL < m5AnnealGapLo - 1e-6;
    final cutR = b.endR > m5AnnealGapHi + 1e-6;
    for (final (u, cut) in [(b.endL, cutL), (b.endR, cutR)]) {
      if (!cut) continue;
      final r = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(g.xOf(u), g.condY + _rest(u)), width: 20, height: 12), const Radius.circular(3));
      c.drawRRect(r, Paint()..shader = shine.createShader(r.outerRect));
    }
    if (!cutL || !cutR) {
      final r = RRect.fromRectAndRadius(Rect.fromCenter(center: g.nut, width: 44, height: 22), const Radius.circular(4));
      c.drawRRect(r, Paint()..shader = shine.createShader(r.outerRect));
    }
  }

  void _tapes(Canvas c) {
    final g = geo;
    for (final u in bench.tapes) {
      _tape(c, Offset(g.xOf(u), g.condY + _dy(u)), lifted: false);
    }
  }

  void _tape(Canvas c, Offset at, {required bool lifted}) {
    final r = RRect.fromRectAndRadius(Rect.fromCenter(center: at, width: 10, height: lifted ? 20 : 17), const Radius.circular(2));
    if (lifted) c.drawRRect(r.shift(const Offset(2, 3)), Paint()..color = const Color(0x55000000));
    c.drawRRect(r, Paint()..color = const Color(0xFFD7262E));
    c.drawLine(at.translate(-4, -2), at.translate(4, -2), Paint()
      ..color = const Color(0x66FFFFFF)
      ..strokeWidth = 1);
  }

  void _gloves(Canvas c) {
    final g = geo;
    for (final left in [true, false]) {
      final x = left ? g.xOf(0.02) : g.xOf(0.98);
      final palm = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, g.condY + 6), width: 34, height: 40), const Radius.circular(12));
      c.drawRRect(palm, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF2B233), Color(0xFFC9861A)]).createShader(palm.outerRect));
      // Fingers over the conductor.
      final finger = Paint()..color = const Color(0xFFE3A12A);
      for (var i = 0; i < 4; i++) {
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 15 + i * 8, g.condY - 9, 7, 12), const Radius.circular(3)), finger);
      }
      // The cuff.
      c.drawRect(Rect.fromCenter(center: Offset(x, g.condY + 32), width: 36, height: 14), Paint()..color = const Color(0xFFB57412));
    }
  }

  void _belt(Canvas c, Size size) {
    final g = geo;
    final t = g.tray;
    // The tool belt across the bottom.
    final belt = Rect.fromLTRB(0, t.center.dy - 12, size.width, t.center.dy + 12);
    c.drawRect(belt, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF6B4A2B), Color(0xFF4A321D)]).createShader(belt));
    // Pouches left of the tray: the spanner and the cutter.
    final pouch = Paint()..color = const Color(0xFF5A3D23);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(t.left - 124, t.top + 6, 48, 52), const Radius.circular(8)), pouch);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(t.left - 64, t.top + 6, 48, 52), const Radius.circular(8)), pouch);
    c.drawRect(Rect.fromLTWH(t.left - 104, t.top - 8, 8, 26), Paint()..color = const Color(0xFF7D8A96));
    c.drawLine(Offset(t.left - 46, t.top - 8), Offset(t.left - 34, t.top + 14), Paint()
      ..color = const Color(0xFFD7262E)
      ..strokeWidth = 5);
    // The tray of red tapes.
    final tray = RRect.fromRectAndRadius(t, const Radius.circular(10));
    c.drawRRect(tray, Paint()..color = const Color(0xFF2D3640));
    c.drawRRect(
        tray,
        Paint()
          ..color = const Color(0xFF8C939A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6);
    for (var i = 0; i < bench.trayLeft; i++) {
      final at = Offset(t.left + 34 + i * 48, t.center.dy);
      c.drawCircle(at, 16, Paint()..color = const Color(0xFFD7262E));
      c.drawCircle(at, 6, Paint()..color = const Color(0xFF2D3640));
    }
  }

  @override
  bool shouldRepaint(M5AnnealBenchPainter old) => old.geo != geo || old.light != light || old.bench != bench;
}

/// The flash on the line at a bare end (a deadly climb), [v] 0 → 1.
class M5AnnealFlashPainter extends CustomPainter {
  const M5AnnealFlashPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final flick = v < 0.5 ? (0.65 + 0.35 * math.sin(v * 60).abs()) : (1 - (v - 0.5) * 1.2).clamp(0.4, 1.0);
    final r = 26 + 70 * Curves.easeOut.transform(v.clamp(0.0, 1.0));
    c.drawCircle(
        at,
        r,
        Paint()
          ..shader = RadialGradient(colors: [Color.fromRGBO(255, 250, 220, 0.95 * flick), Color.fromRGBO(140, 170, 255, 0.5 * flick), const Color(0x00FFC24A)])
              .createShader(Rect.fromCircle(center: at, radius: r)));
    final spark = Paint()
      ..color = Color.fromRGBO(255, 214, 90, (1 - v).clamp(0.0, 1.0))
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 16; i++) {
      final a = i / 16 * math.pi * 2 + 0.2;
      final d0 = 10 + 50 * v;
      c.drawLine(at + Offset(math.cos(a), math.sin(a)) * d0, at + Offset(math.cos(a), math.sin(a)) * (d0 + 14), spark);
    }
    final white = (1 - v * 4).clamp(0.0, 1.0);
    if (white > 0) c.drawRect(Offset.zero & size, Paint()..color = Color.fromRGBO(255, 255, 255, 0.8 * white));
  }

  @override
  bool shouldRepaint(M5AnnealFlashPainter old) => old.v != v || old.at != at;
}
