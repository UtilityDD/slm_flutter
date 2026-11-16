import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

import '../../core/en_digits.dart';
import '../../core/theme/app_theme.dart';

// The drawn world and the deal of lesson 8.5 "সেফটি কোড", কাজ 1 "ঝুলে পড়া তার —
// মেপে দেখুন" (m8_clearance_gauge.dart). A patrol day: five spans, each a
// function of the position along it (t = 0 at the left pole, 1 at the right):
//
//  * road — an 11 kV span across a road, seen from the side. The reading is
//    the height from the LOCAL ground to the wire, so a culvert hump, a raised
//    edge, an embankment or unequal poles move the worst point away from
//    mid-span. The conductor is an honest sagging curve (a parabola between
//    the two pole tops); some spans carry covered conductor. Lesson 8.5 and
//    ruling A2: across a road 11 kV needs 6.5 m.
//  * lt   — an LT line over a lane, seen from above (drone eye): the reading
//    is the HORIZONTAL gap from the house front or balcony to the line. The
//    line drifts a little across the lane; balconies jut toward it. Lesson
//    8.5: LT 1.2 m from a house or balcony.
//
// Dealt numbers (M8-12, notes.mismatches): sound road spans 6.8–7.5 m at the
// worst point, low ones 4.0–5.6 m (never 5.7–6.7 m); sound LT gaps 1.5–2.2 m,
// close ones 0.5–0.9 m. A low span is low over a broad stretch (at least 30 %
// of its length is under the rule), so a handful of well-spread probes always
// finds it. Nothing on the drawing marks the worst point, no figure shows the
// rule, and the number a probe reads has no colour.

enum M8GaugeKind { road, lt }

enum M8GaugeProfile { flat, crowned, hump, raisedEdge, embankment, unequal }

/// What a vehicle on the span is (road: side view; LT: from above).
enum M8Vehicle { car, bus, truck, auto, cycle }

/// The rule per kind (metres): 11 kV across a road 6.5, LT beside a house 1.2.
double m8GaugeRuleM(M8GaugeKind k) => k == M8GaugeKind.road ? 6.5 : 1.2;

/// A reading in tenths of a metre → '5.8 মি' (English digits).
String m8GaugeText(int tenths) => enDigits('${(tenths / 10).toStringAsFixed(1)} মি');

/// The span's number plate (a worker reads it; the only label).
String m8GaugePlate(M8GaugeKind k) => k == M8GaugeKind.road ? '11 kV' : 'LT';

/// The most probes laid at a time on a span.
const int kM8GaugeProbes = 4;

/// Probe positions snap to this grid (t in 1/100).
const int kM8GaugeGrid = 100;

double _smooth(double x) {
  final c = x.clamp(0.0, 1.0);
  return c * c * (3 - 2 * c);
}

@immutable
class M8Traffic {
  const M8Traffic({required this.kind, required this.phase, required this.dir});
  final M8Vehicle kind;
  final double phase;
  final int dir;
}

/// One span: the function and what is drawn from it.
@immutable
class M8GaugeSpan {
  const M8GaugeSpan._({
    required this.kind,
    required this.covered,
    required this.profile,
    required this.mirror,
    required this.poleA,
    required this.poleB,
    required this.sag,
    required this.gAmp,
    required this.gCentre,
    required this.gWidth,
    required this.lineDrift,
    required this.base,
    required this.bumps,
    required this.traffic,
    required this.look,
    required this.minValue,
    required this.minT,
    required this.zone,
    required this.tries,
  });

  final M8GaugeKind kind;

  /// Covered conductor (11 kV road spans only). It changes nothing about the rule.
  final bool covered;
  final M8GaugeProfile profile;
  final bool mirror;

  // road: pole tops above their own ground, the sag against the chord, the ground profile.
  final double poleA, poleB, sag, gAmp, gCentre, gWidth;

  // lt: the line's drift across the lane, the house front's base offset, the balconies.
  final double lineDrift, base;
  final List<({double c, double w, double d})> bumps;

  final List<M8Traffic> traffic;

  /// Palette / decoration seed.
  final int look;

  /// The true worst reading (rounded to 0.1 m), where it is, and how much of
  /// the span lies under the rule.
  final double minValue, minT, zone;

  /// How many draws the deal took (tests).
  final int tries;

  bool get isRoad => kind == M8GaugeKind.road;
  double get ruleM => m8GaugeRuleM(kind);

  /// The truth: somewhere along the span the reading is under the rule.
  bool get breach => minValue < ruleM;
  String get plate => m8GaugePlate(kind);

  double _u(double t) => mirror ? 1 - t : t;

  /// Ground elevation (road), metres.
  double groundAt(double t) {
    final u = _u(t);
    switch (profile) {
      case M8GaugeProfile.flat:
      case M8GaugeProfile.unequal:
        return 0;
      case M8GaugeProfile.crowned:
        return gAmp * math.sin(math.pi * u);
      case M8GaugeProfile.hump:
        final z = (u - gCentre) / gWidth;
        return gAmp * math.exp(-z * z);
      case M8GaugeProfile.raisedEdge:
        return gAmp * _smooth((u - gCentre) / 0.08);
      case M8GaugeProfile.embankment:
        return gAmp * u;
    }
  }

  /// Wire elevation above the datum (road), metres: a parabola between the two pole tops.
  double wireAt(double t) {
    final u = _u(t);
    final a = groundAt(mirror ? 1 : 0) + poleA;
    final b = groundAt(mirror ? 0 : 1) + poleB;
    return a + (b - a) * u - 4 * sag * u * (1 - u);
  }

  /// LT: the line's offset across the lane (metres, down the screen).
  double lineOffAt(double t) {
    final u = _u(t);
    return math.max(0, -lineDrift) + lineDrift * u;
  }

  /// LT: the house front's offset (metres, down the screen).
  double frontOffAt(double t) {
    final u = _u(t);
    var f = base;
    for (final b in bumps) {
      final d = (u - b.c).abs();
      final shape = d <= b.w * 0.55 ? 1.0 : 1 - _smooth((d - b.w * 0.55) / (b.w * 0.45));
      f -= b.d * shape;
    }
    return f;
  }

  /// The true reading at [t] (metres, unrounded).
  double valueAt(double t) => isRoad ? wireAt(t) - groundAt(t) : frontOffAt(t) - lineOffAt(t);

  /// What a probe at [t] shows (tenths of a metre).
  int readingT(double t) => (valueAt(t) * 10).round();

  static const int _n = 600;

  static ({double min, double minT, double zone}) _scan(M8GaugeSpan Function() build) {
    final s = build();
    var min = double.infinity, at = 0.0, under = 0;
    for (var i = 0; i <= _n; i++) {
      final v = s.valueAt(i / _n);
      if (v < min) {
        min = v;
        at = i / _n;
      }
      if (v < s.ruleM) under++;
    }
    return (min: (min * 10).round() / 10, minT: at, zone: under / (_n + 1));
  }

  M8GaugeSpan _scanned(int tries) {
    final r = _scan(() => this);
    return M8GaugeSpan._(
      kind: kind,
      covered: covered,
      profile: profile,
      mirror: mirror,
      poleA: poleA,
      poleB: poleB,
      sag: sag,
      gAmp: gAmp,
      gCentre: gCentre,
      gWidth: gWidth,
      lineDrift: lineDrift,
      base: base,
      bumps: bumps,
      traffic: traffic,
      look: look,
      minValue: r.min,
      minT: r.minT,
      zone: r.zone,
      tries: tries,
    );
  }

  /// A span from explicit numbers (tests, the fallback).
  factory M8GaugeSpan.raw({
    required M8GaugeKind kind,
    bool covered = false,
    M8GaugeProfile profile = M8GaugeProfile.flat,
    bool mirror = false,
    double poleA = 9.2,
    double poleB = 9.2,
    double sag = 2.0,
    double gAmp = 0,
    double gCentre = 0.5,
    double gWidth = 0.14,
    double lineDrift = 0,
    double base = 2.6,
    List<({double c, double w, double d})> bumps = const [],
    List<M8Traffic> traffic = const [],
    int look = 0,
  }) =>
      M8GaugeSpan._(
        kind: kind,
        covered: covered,
        profile: profile,
        mirror: mirror,
        poleA: poleA,
        poleB: poleB,
        sag: sag,
        gAmp: gAmp,
        gCentre: gCentre,
        gWidth: gWidth,
        lineDrift: lineDrift,
        base: base,
        bumps: bumps,
        traffic: traffic,
        look: look,
        minValue: 0,
        minT: 0,
        zone: 0,
        tries: 0,
      )._scanned(0);

  /// Deals a span: [breach] decides which band the worst point falls in.
  factory M8GaugeSpan.deal(math.Random rng, {required M8GaugeKind kind, required bool breach, bool covered = false}) {
    final traffic = [
      for (var i = 0; i < 2 + rng.nextInt(2); i++)
        M8Traffic(
          kind: kind == M8GaugeKind.road ? const [M8Vehicle.car, M8Vehicle.bus, M8Vehicle.truck, M8Vehicle.auto][rng.nextInt(4)] : (rng.nextBool() ? M8Vehicle.cycle : M8Vehicle.auto),
          phase: rng.nextDouble(),
          dir: rng.nextBool() ? 1 : -1,
        ),
    ];
    final look = rng.nextInt(1 << 20);
    for (var tries = 1; tries <= 3000; tries++) {
      final mirror = rng.nextBool();
      M8GaugeSpan cand;
      if (kind == M8GaugeKind.road) {
        final profile = M8GaugeProfile.values[rng.nextInt(M8GaugeProfile.values.length)];
        final pa = 8.6 + rng.nextDouble() * 1.6;
        final skew = profile == M8GaugeProfile.unequal ? (1.1 + rng.nextDouble() * 1.1) * (rng.nextBool() ? 1 : -1) : (rng.nextDouble() - 0.5) * 1.2;
        cand = M8GaugeSpan._(
          kind: kind,
          covered: covered,
          profile: profile,
          mirror: mirror,
          poleA: pa,
          poleB: (pa + skew).clamp(8.0, 10.4),
          sag: breach ? 1.4 + rng.nextDouble() * 3.4 : 0.5 + rng.nextDouble() * 2.2,
          gAmp: switch (profile) {
            M8GaugeProfile.crowned => 0.25 + rng.nextDouble() * 0.2,
            M8GaugeProfile.hump => 0.9 + rng.nextDouble() * 0.7,
            M8GaugeProfile.raisedEdge => 0.8 + rng.nextDouble() * 0.6,
            M8GaugeProfile.embankment => 0.8 + rng.nextDouble() * 0.8,
            _ => 0,
          },
          gCentre: profile == M8GaugeProfile.raisedEdge ? 0.62 + rng.nextDouble() * 0.2 : 0.3 + rng.nextDouble() * 0.4,
          gWidth: 0.10 + rng.nextDouble() * 0.07,
          lineDrift: 0,
          base: 0,
          bumps: const [],
          traffic: traffic,
          look: look,
          minValue: 0,
          minT: 0,
          zone: 0,
          tries: 0,
        );
      } else {
        final nb = 1 + rng.nextInt(3);
        cand = M8GaugeSpan._(
          kind: kind,
          covered: false,
          profile: M8GaugeProfile.flat,
          mirror: mirror,
          poleA: 0,
          poleB: 0,
          sag: 0,
          gAmp: 0,
          gCentre: 0.5,
          gWidth: 0.14,
          lineDrift: (rng.nextDouble() - 0.5) * 1.8,
          base: 2.3 + rng.nextDouble() * 1.2,
          bumps: [for (var i = 0; i < nb; i++) (c: 0.12 + rng.nextDouble() * 0.76, w: 0.20 + rng.nextDouble() * 0.12, d: 0.5 + rng.nextDouble() * 1.2)],
          traffic: traffic,
          look: look,
          minValue: 0,
          minT: 0,
          zone: 0,
          tries: 0,
        );
      }
      final s = cand._scanned(tries);
      if (s._fits(breach)) return s;
    }
    return _fallback(kind, breach, covered, traffic, look, rng.nextBool());
  }

  bool _fits(bool wantBreach) {
    if (isRoad) {
      final ends = math.min(valueAt(0), valueAt(1));
      if (ends < 7.2) return false;
      if (wantBreach) return minValue >= 4.0 && minValue <= 5.6 && zone >= 0.30;
      return minValue >= 6.8 && minValue <= 7.5;
    }
    var far = 0.0;
    for (var i = 0; i <= 20; i++) {
      far = math.max(far, valueAt(i / 20));
    }
    if (far > 3.7) return false;
    if (wantBreach) return minValue >= 0.5 && minValue <= 0.9 && zone >= 0.30;
    return minValue >= 1.5 && minValue <= 2.2;
  }

  static M8GaugeSpan _fallback(M8GaugeKind kind, bool breach, bool covered, List<M8Traffic> traffic, int look, bool mirror) {
    if (kind == M8GaugeKind.road) {
      return M8GaugeSpan._(
        kind: kind,
        covered: covered,
        profile: M8GaugeProfile.flat,
        mirror: mirror,
        poleA: 9.2,
        poleB: 9.2,
        sag: breach ? 3.9 : 2.0,
        gAmp: 0,
        gCentre: 0.5,
        gWidth: 0.14,
        lineDrift: 0,
        base: 0,
        bumps: const [],
        traffic: traffic,
        look: look,
        minValue: 0,
        minT: 0,
        zone: 0,
        tries: 0,
      )._scanned(-1);
    }
    return M8GaugeSpan._(
      kind: kind,
      covered: false,
      profile: M8GaugeProfile.flat,
      mirror: mirror,
      poleA: 0,
      poleB: 0,
      sag: 0,
      gAmp: 0,
      gCentre: 0.5,
      gWidth: 0.14,
      lineDrift: 0,
      base: breach ? 1.3 : 2.6,
      bumps: breach ? const [(c: 0.5, w: 0.4, d: 0.7)] : const [],
      traffic: traffic,
      look: look,
      minValue: 0,
      minT: 0,
      zone: 0,
      tries: 0,
    )._scanned(-1);
  }
}

/// A probe position: the grid cell nearest to [t] (never at the poles).
double m8GaugeSnap(double t) => (t.clamp(0.04, 0.96) * kM8GaugeGrid).round() / kM8GaugeGrid;

// ============================================================================
// Geometry (design px: 360 wide × the scene's height)
// ============================================================================

class M8GaugeGeo {
  M8GaugeGeo._(this.height, this.floorY, this.inset);

  factory M8GaugeGeo.forScene(double height, double inset) => M8GaugeGeo._(height, height - 250 - inset * 0.5, inset);

  final double height;
  final double floorY;
  final double inset;

  static const double top = 96;
  static const double poleL = 44;
  static const double poleR = 316;

  /// The ground-profile reference: road px per metre.
  double get scaleRoad => ((floorY - top - 10) / 11.9).clamp(12.0, 24.0);

  /// LT: the line's top edge and px per metre.
  double get yLine0 => top + 58;
  double get scaleLt => ((floorY + 60 - yLine0 - 20) / 4.6).clamp(26.0, 46.0);

  double x(double t) => poleL + (poleR - poleL) * t;
  double tOf(double px) => ((px - poleL) / (poleR - poleL));

  double roadY(double elevM) => floorY - elevM * scaleRoad;
  double groundY(M8GaugeSpan s, double t) => roadY(s.groundAt(t));
  double wireY(M8GaugeSpan s, double t) => roadY(s.wireAt(t));

  double lineY(M8GaugeSpan s, double t) => yLine0 + s.lineOffAt(t) * scaleLt;
  double frontY(M8GaugeSpan s, double t) => yLine0 + s.frontOffAt(t) * scaleLt;

  /// The probe's two ends (upper, lower) on the screen.
  (Offset, Offset) probeEnds(M8GaugeSpan s, double t) {
    final px = x(t);
    return s.isRoad ? (Offset(px, wireY(s, t)), Offset(px, groundY(s, t))) : (Offset(px, lineY(s, t)), Offset(px, frontY(s, t)));
  }

  /// A tap lands on the span when it is between the poles and in the span's band.
  bool onSpan(Offset p) => p.dx >= poleL - 14 && p.dx <= poleR + 14 && p.dy >= top - 6 && p.dy <= floorY + 80;

  /// The trainee beside the left pole (road spans), standing on the ground.
  Rect trainee(M8GaugeSpan s) {
    final gy = s.isRoad ? groundY(s, 0) : floorY;
    return Rect.fromLTWH(-4, gy - 80, 58, 84);
  }
}

// ============================================================================
// Painters
// ============================================================================

const _sky0 = Color(0xFFBBDDF1);
const _sky1 = Color(0xFFEFF7FB);

/// The place: sky, town, ground or lane, poles, the conductor.
class M8GaugeScenePainter extends CustomPainter {
  M8GaugeScenePainter({required this.geo, required this.span});

  final M8GaugeGeo geo;
  final M8GaugeSpan span;

  @override
  void paint(Canvas c, Size size) {
    if (span.isRoad) {
      _road(c, size);
    } else {
      _lane(c, size);
    }
  }

  void _plate(Canvas c, Offset at) {
    final tp = TextPainter(
      text: TextSpan(text: span.plate, style: bangla(fontSize: 9.5, fontWeight: FontWeight.w900, color: const Color(0xFF14233B))),
      textDirection: TextDirection.ltr,
    )..layout();
    final r = RRect.fromRectAndRadius(Rect.fromCenter(center: at, width: tp.width + 8, height: tp.height + 4), const Radius.circular(3));
    c.drawRRect(r, Paint()..color = const Color(0xFFF4EFD8));
    c.drawRRect(r, Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = const Color(0xFF14233B));
    tp.paint(c, at - Offset(tp.width / 2, tp.height / 2));
  }

  void _road(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    final rnd = math.Random(span.look);
    c.drawRect(
      Rect.fromLTWH(0, 0, w, g.floorY + 40),
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_sky0, _sky1]).createShader(Rect.fromLTWH(0, 0, w, g.floorY)),
    );
    // Far town: a soft band of roofs behind the road.
    final far = Path()..moveTo(0, g.floorY);
    var fx = 0.0;
    while (fx < w) {
      final bw = 26.0 + rnd.nextInt(32);
      final bh = 26.0 + rnd.nextInt(44);
      far
        ..lineTo(fx, g.floorY - bh)
        ..lineTo(fx + bw, g.floorY - bh);
      fx += bw;
    }
    far
      ..lineTo(w, g.floorY)
      ..close();
    c.drawPath(far, Paint()..color = const Color(0x33506A80));
    // Trees.
    for (var i = 0; i < 4; i++) {
      final tx = 12.0 + rnd.nextInt(330);
      c.drawCircle(Offset(tx, g.floorY - 34), 13, Paint()..color = const Color(0x552E6B3A));
    }
    // The ground profile and the road surface along it.
    final ground = Path()..moveTo(0, g.height);
    final top = <Offset>[];
    for (var i = 0; i <= 72; i++) {
      final px = w * i / 72;
      final t = px <= M8GaugeGeo.poleL ? 0.0 : (px >= M8GaugeGeo.poleR ? 1.0 : g.tOf(px));
      top.add(Offset(px, g.groundY(span, t)));
    }
    ground.lineTo(0, top.first.dy);
    for (final p in top.skip(1)) {
      ground.lineTo(p.dx, p.dy);
    }
    ground
      ..lineTo(w, g.height)
      ..close();
    c.drawPath(ground, Paint()..color = const Color(0xFF8C8577));
    final surface = Path()..moveTo(top.first.dx, top.first.dy);
    for (final p in top.skip(1)) {
      surface.lineTo(p.dx, p.dy);
    }
    c.drawPath(surface, Paint()..style = PaintingStyle.stroke..strokeWidth = 7..strokeJoin = StrokeJoin.round..color = const Color(0xFF3D4047));
    c.drawPath(surface.shift(const Offset(0, 5)), Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = const Color(0x886E685D));
    // Culvert / raised edge: a masonry face under the surface.
    if (span.profile == M8GaugeProfile.hump || span.profile == M8GaugeProfile.raisedEdge) {
      final face = Paint()..color = const Color(0x66605A4E);
      for (var i = 1; i < top.length; i += 3) {
        if (top[i].dy < g.floorY - 3) c.drawRect(Rect.fromLTRB(top[i].dx - 1, top[i].dy + 5, top[i].dx + 1, g.floorY + 4), face);
      }
    }
    // The poles.
    _pole(c, 0);
    _pole(c, 1);
    // The conductor.
    final wire = Path()..moveTo(g.x(0), g.wireY(span, 0));
    for (var i = 1; i <= 60; i++) {
      wire.lineTo(g.x(i / 60), g.wireY(span, i / 60));
    }
    if (span.covered) {
      c.drawPath(wire, Paint()..style = PaintingStyle.stroke..strokeWidth = 5.4..strokeCap = StrokeCap.round..color = const Color(0xFF1E2228));
      c.drawPath(wire, Paint()..style = PaintingStyle.stroke..strokeWidth = 3.4..strokeCap = StrokeCap.round..color = const Color(0xFF6F7C86));
    } else {
      c.drawPath(wire, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.4..strokeCap = StrokeCap.round..color = const Color(0xFF1E2228));
    }
    // The patrol van at the kerb, far right.
    final vy = g.groundY(span, 1);
    final van = RRect.fromRectAndRadius(Rect.fromLTWH(w - 62, vy - 34, 56, 30), const Radius.circular(5));
    c.drawRRect(van, Paint()..color = const Color(0xFFEDEDED));
    c.drawRect(Rect.fromLTWH(w - 62, vy - 22, 56, 5), Paint()..color = const Color(0xFF1C2E4A));
    c.drawRect(Rect.fromLTWH(w - 20, vy - 30, 12, 11), Paint()..color = const Color(0xFF9CC4DB));
    for (final wx in [w - 50, w - 20]) {
      c.drawCircle(Offset(wx, vy - 4), 5, Paint()..color = const Color(0xFF222222));
    }
  }

  void _pole(Canvas c, double t) {
    final g = geo;
    final x = g.x(t);
    final base = g.groundY(span, t) + 2;
    final top = g.wireY(span, t) - 4;
    final bw = math.max(6.0, g.scaleRoad * 0.3);
    final tw = bw * 0.6;
    final path = Path()
      ..moveTo(x - bw / 2, base)
      ..lineTo(x - tw / 2, top)
      ..lineTo(x + tw / 2, top)
      ..lineTo(x + bw / 2, base)
      ..close();
    c.drawPath(path, Paint()..shader = const LinearGradient(colors: [Color(0xFFB8B4AA), Color(0xFF8D887E)]).createShader(Rect.fromLTRB(x - bw, top, x + bw, base)));
    c.drawRect(Rect.fromCenter(center: Offset(x, top + 2), width: 30, height: 3.5), Paint()..color = const Color(0xFF4B4B4B));
    c.drawCircle(Offset(x, top - 1), 3, Paint()..color = const Color(0xFF7A8B99));
    _plate(c, Offset(x, base - (base - top) * 0.34));
  }

  void _lane(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    final rnd = math.Random(span.look);
    // The lane's asphalt, seen from above.
    c.drawRect(Rect.fromLTWH(0, 0, w, g.height), Paint()..color = const Color(0xFF6C7077));
    // Opposite row of roofs along the top.
    c.drawRect(Rect.fromLTWH(0, 0, w, M8GaugeGeo.top + 6), Paint()..color = const Color(0xFFB07B5A));
    for (var x = 0.0; x < w; x += 22) {
      c.drawRect(Rect.fromLTWH(x, 0, 1.4, M8GaugeGeo.top + 6), Paint()..color = const Color(0x33000000));
    }
    c.drawRect(Rect.fromLTWH(0, M8GaugeGeo.top + 6, w, 5), Paint()..color = const Color(0xFF55585E));
    // A dashed centre mark.
    for (var x = 4.0; x < w; x += 26) {
      c.drawRect(Rect.fromLTWH(x, g.yLine0 - 20, 14, 2.4), Paint()..color = const Color(0x88F4EFD8));
    }
    // The house fronts: one polygon along the true front line (balconies included).
    final front = <Offset>[];
    for (var i = 0; i <= 90; i++) {
      final px = w * i / 90;
      final t = px <= M8GaugeGeo.poleL ? 0.0 : (px >= M8GaugeGeo.poleR ? 1.0 : g.tOf(px));
      // Outside the poles the front goes on as it is at the poles (balconies never run off the screen).
      front.add(Offset(px, g.frontY(span, t)));
    }
    const roofs = [Color(0xFFC9906B), Color(0xFFB9A58A), Color(0xFFC77C6B), Color(0xFFA9B4A2)];
    final houses = Path()..moveTo(0, g.height);
    for (final p in front) {
      houses.lineTo(p.dx, p.dy);
    }
    houses
      ..lineTo(w, g.height)
      ..close();
    c.drawPath(houses, Paint()..color = roofs[span.look % roofs.length]);
    // Walls between the houses.
    var wx = 14.0 + rnd.nextInt(40);
    while (wx < w) {
      final i = (wx / w * 90).round().clamp(0, 90);
      c.drawRect(Rect.fromLTRB(wx - 1.2, front[i].dy, wx + 1.2, g.height), Paint()..color = const Color(0x55000000));
      wx += 58 + rnd.nextInt(40);
    }
    // The front edge and the balcony rails.
    final edge = Path()..moveTo(front.first.dx, front.first.dy);
    for (final p in front.skip(1)) {
      edge.lineTo(p.dx, p.dy);
    }
    c.drawPath(edge, Paint()..style = PaintingStyle.stroke..strokeWidth = 3..strokeJoin = StrokeJoin.round..color = const Color(0xFF5B3A2A));
    final rail = Paint()..color = const Color(0xFF3B2A20)..strokeWidth = 1.4;
    for (var i = 0; i <= 90; i += 2) {
      final p = front[i];
      final inside = i > 0 && i < 90 && p.dy < g.frontY(span, 0.0) - 6 && p.dx > M8GaugeGeo.poleL && p.dx < M8GaugeGeo.poleR;
      if (inside) c.drawLine(p, p + const Offset(0, 6), rail);
    }
    // Terrace: a water tank and a clothes line on the house side.
    final ti = (30 + span.look % 30).clamp(2, 88);
    c.drawCircle(front[ti] + const Offset(0, 38), 11, Paint()..color = const Color(0xFF3F5E78));
    final cl = front[(55 + span.look % 20).clamp(2, 80)];
    final cy = cl.dy + 20;
    c.drawLine(Offset(cl.dx, cy), Offset(cl.dx + 70, cy), Paint()..color = const Color(0xFF3B2A20)..strokeWidth = 1);
    const cloth = [Color(0xFFF2E3C4), Color(0xFF4F7FB0), Color(0xFFD65C4B), Color(0xFFE9C34A)];
    for (var i = 0; i < 4; i++) {
      c.drawRect(Rect.fromLTWH(cl.dx + 6 + i * 16, cy, 9, 13), Paint()..color = cloth[(span.look + i) % 4]);
    }
    // The LT line, straight between the two poles, and the poles from above.
    final a = Offset(g.x(0), g.lineY(span, 0));
    final b = Offset(g.x(1), g.lineY(span, 1));
    c.drawLine(a + const Offset(-60, 0), a, Paint()..color = const Color(0xFF1E2228)..strokeWidth = 2.4);
    c.drawLine(a, b, Paint()..color = const Color(0xFF1E2228)..strokeWidth = 2.4);
    c.drawLine(b, b + const Offset(60, 0), Paint()..color = const Color(0xFF1E2228)..strokeWidth = 2.4);
    for (final p in [a, b]) {
      c.drawCircle(p, 8, Paint()..color = const Color(0xFFB8B4AA));
      c.drawCircle(p, 8, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.6..color = const Color(0xFF4B4B4B));
      c.drawRect(Rect.fromCenter(center: p, width: 18, height: 3), Paint()..color = const Color(0xFF4B4B4B));
    }
    _plate(c, a + const Offset(0, -20));
    // The patrol van at the kerb (from above), left edge.
    final v = RRect.fromRectAndRadius(Rect.fromLTWH(4, g.yLine0 - 70, 34, 52), const Radius.circular(6));
    c.drawRRect(v, Paint()..color = const Color(0xFFEDEDED));
    c.drawRect(Rect.fromLTWH(8, g.yLine0 - 66, 26, 10), Paint()..color = const Color(0xFF9CC4DB));
    c.drawRect(Rect.fromLTWH(4, g.yLine0 - 40, 34, 4), Paint()..color = const Color(0xFF1C2E4A));
  }

  @override
  bool shouldRepaint(M8GaugeScenePainter old) => !identical(old.span, span) || old.geo.floorY != geo.floorY || old.geo.height != geo.height;
}

/// Traffic passing under (road: side view) or along (LT: from above) the span;
/// it moves only while the scene is awake (the clock stops, nothing draws).
class M8TrafficPainter extends CustomPainter {
  M8TrafficPainter({required this.geo, required this.span, required this.clock}) : super(repaint: clock);

  final M8GaugeGeo geo;
  final M8GaugeSpan span;
  final ValueListenable<double> clock;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width + 120;
    for (final v in span.traffic) {
      final speed = switch (v.kind) {
        M8Vehicle.bus || M8Vehicle.truck => 20.0,
        M8Vehicle.car => 34.0,
        M8Vehicle.auto => 26.0,
        M8Vehicle.cycle => 12.0,
      };
      var x = (v.phase * w + v.dir * clock.value * speed) % w;
      if (x < 0) x += w;
      x -= 60;
      if (span.isRoad) {
        _side(c, v.kind, x, v.dir);
      } else {
        _top(c, v.kind, x, v.dir);
      }
    }
  }

  void _side(Canvas c, M8Vehicle k, double x, int dir) {
    final g = geo;
    final t = ((x - M8GaugeGeo.poleL) / (M8GaugeGeo.poleR - M8GaugeGeo.poleL)).clamp(0.0, 1.0);
    final gy = g.groundY(span, t);
    // metres → px at the road scale; heights stay under the lowest span (4.0 m).
    final s = g.scaleRoad;
    final (wm, hm, col) = switch (k) {
      M8Vehicle.car => (3.8, 1.5, const Color(0xFFC0392B)),
      M8Vehicle.bus => (9.0, 3.2, const Color(0xFF2E7DB5)),
      M8Vehicle.truck => (7.0, 3.4, const Color(0xFF8A6A35)),
      M8Vehicle.auto => (2.6, 1.7, const Color(0xFF2F8F4E)),
      M8Vehicle.cycle => (1.7, 1.7, const Color(0xFF444444)),
    };
    final body = Rect.fromLTWH(x - wm * s / 2, gy - 5 - hm * s, wm * s, hm * s);
    c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(3)), Paint()..color = col);
    c.drawRect(Rect.fromLTWH(body.left + 3, body.top + 3, body.width - 6, body.height * 0.3), Paint()..color = const Color(0x88DCEBF5));
    for (final wx in [body.left + body.width * 0.22, body.right - body.width * 0.22]) {
      c.drawCircle(Offset(wx, gy - 3), 3.4, Paint()..color = const Color(0xFF1A1A1A));
    }
    final head = dir > 0 ? body.right : body.left;
    c.drawCircle(Offset(head, body.bottom - 5), 1.8, Paint()..color = const Color(0xFFF7D046));
  }

  void _top(Canvas c, M8Vehicle k, double x, int dir) {
    final g = geo;
    final y = g.yLine0 - 22 + (dir > 0 ? 7 : -7);
    final r = switch (k) {
      M8Vehicle.cycle => Rect.fromCenter(center: Offset(x, y), width: 16, height: 5),
      _ => Rect.fromCenter(center: Offset(x, y), width: 24, height: 12),
    };
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), Paint()..color = k == M8Vehicle.cycle ? const Color(0xFF2B2B2B) : const Color(0xFF2F8F4E));
    c.drawCircle(Offset(x - dir * 2.0, y), 3, Paint()..color = const Color(0xFFE8C27C));
  }

  @override
  bool shouldRepaint(M8TrafficPainter old) => !identical(old.span, span) || old.geo.floorY != geo.floorY;
}

/// The probes: a thin dashed line from the wire (or the house front) to the
/// ground (or the line) with one number at its end — no colour, no target. A
/// revealed probe glides from where it was to the true worst point.
class M8ProbePainter extends CustomPainter {
  M8ProbePainter({
    required this.geo,
    required this.span,
    required this.ts,
    this.glideFrom,
    this.glideTo,
    this.glide,
    this.booked = false,
  }) : super(repaint: glide);

  final M8GaugeGeo geo;
  final M8GaugeSpan span;
  final List<double> ts;
  final double? glideFrom;
  final double? glideTo;
  final Animation<double>? glide;

  /// A tag is tied on the pole (the span is booked).
  final bool booked;

  void _probe(Canvas c, double t) {
    final (a, b) = geo.probeEnds(span, t);
    final pen = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 1.7;
    final len = (b - a).distance;
    const dash = 5.0, gap = 3.5;
    final dir = (b - a) / (len == 0 ? 1 : len);
    for (var d = 0.0; d < len; d += dash + gap) {
      c.drawLine(a + dir * d, a + dir * math.min(d + dash, len), pen);
    }
    c.drawCircle(a, 3, Paint()..color = const Color(0xFF14233B));
    c.drawCircle(a, 3, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2..color = const Color(0xFFFFFFFF));
    c.drawCircle(b, 3, Paint()..color = const Color(0xFF14233B));
    c.drawCircle(b, 3, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2..color = const Color(0xFFFFFFFF));
    final tp = TextPainter(
      text: TextSpan(text: m8GaugeText(span.readingT(t)), style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: const Color(0xFFFFFFFF))),
      textDirection: TextDirection.ltr,
    )..layout();
    // The number sits at the probe's lower end (road: by the ground, LT: by the house front).
    final at = Offset((b.dx + 6).clamp(2.0, 360 - tp.width - 12), (span.isRoad ? (a.dy + b.dy) / 2 : b.dy + 8) - tp.height / 2);
    final pill = RRect.fromRectAndRadius(Rect.fromLTWH(at.dx - 4, at.dy - 2, tp.width + 8, tp.height + 4), const Radius.circular(7));
    c.drawRRect(pill, Paint()..color = const Color(0xE6101C30));
    tp.paint(c, at);
  }

  @override
  void paint(Canvas c, Size size) {
    for (final t in ts) {
      _probe(c, t);
    }
    final to = glideTo;
    if (to != null) {
      final k = Curves.easeInOutCubic.transform((glide?.value ?? 1).clamp(0.0, 1.0));
      _probe(c, (glideFrom ?? to) + (to - (glideFrom ?? to)) * k);
    }
    if (booked) _tag(c);
  }

  void _tag(Canvas c) {
    final x = geo.x(span.mirror ? 1 : 0);
    final y = span.isRoad ? geo.wireY(span, span.mirror ? 1 : 0) + 38 : geo.lineY(span, span.mirror ? 1 : 0) + 22;
    c.drawLine(Offset(x, y - 8), Offset(x + 6, y), Paint()..color = const Color(0xFF333333)..strokeWidth = 1.2);
    final tag = Path()
      ..moveTo(x + 2, y)
      ..lineTo(x + 18, y)
      ..lineTo(x + 22, y + 7)
      ..lineTo(x + 18, y + 14)
      ..lineTo(x + 2, y + 14)
      ..close();
    c.drawPath(tag, Paint()..color = const Color(0xFFD94A3A));
    c.drawCircle(Offset(x + 7, y + 7), 1.8, Paint()..color = const Color(0xFFFFFFFF));
  }

  @override
  bool shouldRepaint(M8ProbePainter old) =>
      !identical(old.span, span) || old.geo.floorY != geo.floorY || old.booked != booked || old.glideTo != glideTo || old.glideFrom != glideFrom || !_same(old.ts, ts);

  static bool _same(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
