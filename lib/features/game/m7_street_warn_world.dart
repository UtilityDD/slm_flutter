import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

// The scene of m7_street_warn (lesson 7.3 কাজ 2 "পাড়ার পাহারা"): a breezy
// afternoon পাড়া drawn as a street elevation in design units (360 wide).
//
//   sky + far roofs                                   (still)
//   the top band: house A · house B under the LT line (two spans on three
//     poles, x 16–240), the free lane (a gap going back between house B and
//     house D, NO line over it) and house D (no wire near its roof)
//   the back lane (people walk left/right; the LT line over x 16–240 only)
//   the plot (a vacant plot or a half-built house) right under the 11 kV line
//   the main road with the 11 kV line along all of it (three conductors)
//   the trainee at the lane corner (bottom left)
//
// Heights scale with the working height so short and tall phones keep the
// same order of things; nothing is captioned on the scene.

/// Where a person walks.
enum M7WarnLane { main, back, free }

/// What a person looks like (decoys are drawn alike: the free lane's bamboo
/// pair is drawn exactly as the back lane's).
enum M7WarnLook { rod, bamboo, cyclist, vendor, bag }

/// The roof item of the play.
enum M7WarnRoof { clothes, bamboo }

/// The roof item's state.
enum M7WarnRoofState { hidden, shown, cleared }

class M7WarnGeo {
  M7WarnGeo._(this.height, this.top, this.bottom) : k = ((bottom - top) / 560).clamp(0.6, 1.15);

  factory M7WarnGeo.forScene(double height, double inset) {
    const top = 128.0;
    // The play stays above the corner guide's band (his sprite and the
    // bottom row); under it is the near pavement with the trainee.
    final b = math.max(height - footBand - inset * 0.5, top + 330);
    return M7WarnGeo._(height, top, b);
  }

  /// The band kept under the play (the corner guide stands there).
  static const double footBand = 196;

  final double height;

  /// The working area (under the header, over the bottom row).
  final double top;
  final double bottom;

  /// Height scale (1 on a 780-high design).
  final double k;

  double y(double f) => top + f * (bottom - top);

  // --- the top band ------------------------------------------------------------
  /// The houses' base line and their height.
  double get houseBase => y(0.485);
  double get houseH => 60 * k;
  double get roofY => houseBase - houseH;

  /// The three houses (A and B under the LT line, D with no wire).
  static const houseX = [(6.0, 120.0), (134.0, 236.0), (292.0, 356.0)];
  Rect house(int i) => Rect.fromLTRB(houseX[i].$1, roofY, houseX[i].$2, houseBase);

  /// Where a roof item stands on house [i] (left of the roof's middle).
  Offset roofSpot(int i) => Offset(houseX[i].$1 + (houseX[i].$2 - houseX[i].$1) * 0.42, roofY);

  // --- the LT line -----------------------------------------------------------
  static const ltXs = [16.0, 128.0, 240.0];
  double get ltGap => 44 * k;

  /// The LT line's height at a pole top (the lower conductor).
  double get ltY => roofY - ltGap;

  /// The lower LT conductor's height at [x] (a sagging span dips low).
  double ltWireY(double x, {int? sagSpan, int wire = 0}) {
    final base = ltY - wire * 5 * k;
    if (x < ltXs[0] || x > ltXs[2]) return base;
    final span = x < ltXs[1] ? 0 : 1;
    final a = ltXs[span];
    final b = ltXs[span + 1];
    final t = (x - a) / (b - a);
    final dip = (span == sagSpan ? 30 : 5) * k;
    return base + 4 * t * (1 - t) * dip;
  }

  /// The hold area of LT span [j].
  Rect span(int j, {int? sagSpan}) {
    final a = ltXs[j];
    final b = ltXs[j + 1];
    final low = ltWireY((a + b) / 2, sagSpan: sagSpan);
    return Rect.fromLTRB(a + 8, ltY - 5 * k - 12, b - 8, low + 12);
  }

  // --- the back lane and the free lane ---------------------------------------
  double get backY => y(0.53);
  static const laneX = 268.0;
  double get laneFarY => roofY + 16 * k;

  // --- the plot and the 11 kV line --------------------------------------------
  double get plotBase => y(0.85);
  Rect get plot => Rect.fromLTRB(112, plotBase - 98 * k, 240, plotBase + 2);
  static const htXs = [20.0, 180.0, 340.0];
  double get htPoleBase => y(0.89);

  /// The 11 kV conductors' height (0 top … 2 the lowest).
  double htWireY(double x, int wire) {
    final base = htPoleBase - 150 * k + wire * 6 * k;
    final i = x < htXs[1] ? 0 : 1;
    final a = htXs[i];
    final b = htXs[i + 1];
    final t = ((x - a) / (b - a)).clamp(0.0, 1.0);
    return base + 4 * t * (1 - t) * 6 * k;
  }

  double get mainY => y(0.94);

  // --- the trainee --------------------------------------------------------------
  Rect get trainee {
    final feet = math.min(bottom + 64, height - 24);
    final h = 92 * (0.7 + 0.3 * k);
    return Rect.fromLTWH(8, feet - h, h * 0.55, h);
  }
  Offset get traineeMouth => Offset(trainee.center.dx + 6, trainee.top + 12);

  /// An empty bit of road for the hold hint (nobody there now).
  Offset get emptyRoad => Offset(196, mainY + 22 * k);

  // --- paths ----------------------------------------------------------------------
  /// Lane x at progress [p] (0 at the entry edge) walking [forward] (left →
  /// right on the main road and the back lane).
  static double laneXAt(double p, bool forward) => forward ? lerpDouble(-26, 386, p)! : lerpDouble(386, -26, p)!;

  /// The progress at which a walker on the main road / back lane is at [x].
  static double progressAt(double x, bool forward) => forward ? (x + 26) / 412 : (386 - x) / 412;

  /// A person's feet at progress [p].
  Offset at(M7WarnLane lane, double p, bool forward) {
    switch (lane) {
      case M7WarnLane.main:
        return Offset(laneXAt(p, forward), mainY);
      case M7WarnLane.back:
        return Offset(laneXAt(p, forward), backY);
      case M7WarnLane.free:
        // forward: in from the right edge along the back lane, then up the
        // free lane; back: the reverse.
        final q = forward ? p : 1 - p;
        if (q < 0.5) return Offset(lerpDouble(386, laneX, q / 0.5)!, backY);
        return Offset(laneX, lerpDouble(backY, laneFarY, (q - 0.5) / 0.5)!);
    }
  }

  /// A person's size at his feet [y] (the free lane recedes).
  double scaleAt(Offset feet) {
    final base = 0.78 + 0.22 * k;
    if (feet.dy >= mainY - 1) return base;
    if (feet.dy >= backY - 1) return base * 0.9;
    final t = ((backY - feet.dy) / (backY - laneFarY)).clamp(0.0, 1.0);
    return base * (0.9 - 0.32 * t);
  }

  /// A person's hold area.
  Rect personRect(Offset feet, M7WarnLook look) {
    final s = scaleAt(feet);
    final wide = look == M7WarnLook.bamboo ? 30.0 : (look == M7WarnLook.cyclist ? 26.0 : 18.0);
    return Rect.fromLTRB(feet.dx - wide * s - 4, feet.dy - 48 * s, feet.dx + wide * s + 4, feet.dy + 6);
  }

  /// The conductor point a raised load would touch above [feet].
  Offset wireAbove(M7WarnLane lane, Offset feet, {int? sagSpan}) => lane == M7WarnLane.main
      ? Offset(feet.dx, htWireY(feet.dx, 2))
      : Offset(feet.dx, ltWireY(feet.dx, sagSpan: sagSpan));
}

/// A person as drawn now.
@immutable
class M7WarnActorView {
  const M7WarnActorView({
    required this.at,
    required this.look,
    required this.facingLeft,
    required this.tint,
    this.phase,
    this.lift = 0,
    this.liftTo,
    this.opacity = 1,
    this.lowered = false,
    this.palm = false,
    this.up = false,
  });

  /// The feet.
  final Offset at;
  final M7WarnLook look;
  final bool facingLeft;
  final int tint;

  /// The walk cycle (0..1) or null standing.
  final double? phase;

  /// 0 carrying, 1 the load's tip at [liftTo].
  final double lift;
  final Offset? liftTo;
  final double opacity;

  /// Warned: the load carried low, walking away.
  final bool lowered;

  /// The trainee's "stop" reached him (a raised palm for a moment).
  final bool palm;

  /// Walking up the free lane (seen from the back).
  final bool up;
}

/// What the static scene shows now (repaints only when this changes).
@immutable
class M7WarnSceneView {
  const M7WarnSceneView({
    required this.sagSpan,
    required this.roof,
    required this.roofHouse,
    required this.roofState,
    required this.decoyRoof,
    required this.build,
    required this.masonsDown,
  });

  final int? sagSpan;
  final M7WarnRoof roof;
  final int roofHouse;
  final M7WarnRoofState roofState;

  /// Clothes on house D's roof (no wire near it).
  final bool decoyRoof;

  /// A half-built house on the plot (else a vacant plot).
  final bool build;
  final bool masonsDown;

  @override
  bool operator ==(Object other) =>
      other is M7WarnSceneView &&
      other.sagSpan == sagSpan &&
      other.roof == roof &&
      other.roofHouse == roofHouse &&
      other.roofState == roofState &&
      other.decoyRoof == decoyRoof &&
      other.build == build &&
      other.masonsDown == masonsDown;

  @override
  int get hashCode => Object.hash(sagSpan, roof, roofHouse, roofState, decoyRoof, build, masonsDown);
}

const _skin = Color(0xFF9C6B4A);
const _hair = Color(0xFF231C18);
const _shirts = [Color(0xFF8E6B4E), Color(0xFF5F7488), Color(0xFF7D6A7F), Color(0xFF6E805F), Color(0xFF9A7B4F), Color(0xFF7A5F5F)];
const _lungis = [Color(0xFF3F4A5C), Color(0xFF4C3F3A), Color(0xFF3D4C44), Color(0xFF4A4458), Color(0xFF433F35), Color(0xFF52463A)];

/// A small standing person (roof owners, masons): feet at [o].
void m7WarnFigure(Canvas c, Offset o, double s, {int tint = 0, bool sari = false, bool armUp = false, bool facingLeft = false}) {
  final f = facingLeft ? -1.0 : 1.0;
  c.drawOval(Rect.fromCenter(center: o, width: 14 * s, height: 3 * s), Paint()..color = const Color(0x44000000));
  final leg = Paint()
    ..color = _skin
    ..strokeWidth = 2.4 * s
    ..strokeCap = StrokeCap.round;
  c.drawLine(o + Offset(-2 * s, -11 * s), o + Offset(-2 * s, 0), leg);
  c.drawLine(o + Offset(2 * s, -11 * s), o + Offset(2 * s, 0), leg);
  final hip = o + Offset(0, -11 * s);
  if (sari) {
    c.drawPath(
      Path()
        ..moveTo(hip.dx - 6 * s, hip.dy - 13 * s)
        ..lineTo(hip.dx + 6 * s, hip.dy - 13 * s)
        ..lineTo(hip.dx + 7 * s, hip.dy + 11 * s)
        ..lineTo(hip.dx - 7 * s, hip.dy + 11 * s)
        ..close(),
      Paint()..color = _shirts[(tint + 2) % _shirts.length],
    );
    c.drawLine(hip + Offset(-5 * s, -12 * s), hip + Offset(6 * s, 2 * s), Paint()
      ..color = const Color(0xFFB9483A)
      ..strokeWidth = 2 * s);
  } else {
    c.drawRect(Rect.fromLTRB(hip.dx - 5 * s, hip.dy - 9 * s, hip.dx + 5 * s, hip.dy + 3 * s), Paint()..color = _lungis[tint % _lungis.length]);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(hip.dx - 5.5 * s, hip.dy - 22 * s, 11 * s, 14 * s), Radius.circular(3 * s)),
        Paint()..color = _shirts[tint % _shirts.length]);
  }
  final arm = Paint()
    ..color = _skin
    ..strokeWidth = 2 * s
    ..strokeCap = StrokeCap.round;
  final sh = hip + Offset(f * 4 * s, -19 * s);
  c.drawLine(sh, sh + (armUp ? Offset(f * 4 * s, -10 * s) : Offset(0, 10 * s)), arm);
  c.drawLine(hip + Offset(-f * 4 * s, -19 * s), hip + Offset(-f * 4 * s, -9 * s), arm);
  final head = hip + Offset(0, -27 * s);
  c.drawCircle(head, 4.3 * s, Paint()..color = _skin);
  c.drawArc(Rect.fromCircle(center: head, radius: 4.5 * s), math.pi, math.pi, false, Paint()..color = _hair);
  if (sari) c.drawCircle(head + Offset(-f * 3.4 * s, -1 * s), 2.2 * s, Paint()..color = _hair);
}

/// The still street: sky, houses, the LT and 11 kV lines, the plot, the roof
/// items, the roads. Repaints only when [view] changes.
class M7WarnLanePainter extends CustomPainter {
  const M7WarnLanePainter({required this.geo, required this.view});
  final M7WarnGeo geo;
  final M7WarnSceneView view;

  @override
  void paint(Canvas canvas, Size size) {
    _sky(canvas, size);
    _ground(canvas, size);
    _freeLane(canvas);
    for (var i = 0; i < 3; i++) {
      _house(canvas, i);
    }
    _roofItems(canvas);
    _ltLine(canvas);
    _plot(canvas);
    _htLine(canvas);
  }

  void _sky(Canvas c, Size size) {
    final g = geo;
    final sky = Rect.fromLTWH(0, 0, size.width, g.roofY + 10);
    c.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6FA6D6), Color(0xFFA9CBE6), Color(0xFFE6D9B8)],
        ).createShader(sky),
    );
    // A warm afternoon sun and a few soft clouds.
    final sun = Offset(300, g.top + 26);
    c.drawCircle(
      sun,
      46,
      Paint()
        ..shader = const RadialGradient(colors: [Color(0x88FFF3C4), Color(0x00FFF3C4)]).createShader(Rect.fromCircle(center: sun, radius: 46)),
    );
    c.drawCircle(sun, 13, Paint()..color = const Color(0xFFFFF0B8));
    final cloud = Paint()..color = const Color(0x99FFFFFF);
    final r = math.Random(73);
    for (var i = 0; i < 5; i++) {
      final cx = r.nextDouble() * 360;
      final cy = 40 + r.nextDouble() * (g.top - 10);
      c.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: 90 + r.nextDouble() * 70, height: 18 + r.nextDouble() * 10), cloud);
    }
    // Far roofs and a few trees on the skyline (behind the houses).
    final hz = g.roofY - 30 * g.k;
    final far = Paint()..color = const Color(0xFF9AA3A8);
    final farDark = Paint()..color = const Color(0xFF858E94);
    for (var i = 0; i < 9; i++) {
      final x0 = -14.0 + i * 44 + r.nextDouble() * 10;
      final w = 34 + r.nextDouble() * 14;
      final h = (16 + r.nextDouble() * 22) * g.k;
      c.drawRect(Rect.fromLTWH(x0, hz - h, w, h + 30 * g.k), i.isEven ? far : farDark);
    }
    final leaf = Paint()..color = const Color(0xFF6E8F6A);
    for (var i = 0; i < 4; i++) {
      final cx = 40 + i * 92 + r.nextDouble() * 20;
      c.drawCircle(Offset(cx, hz - 18 * g.k), 15 * g.k + r.nextDouble() * 5, leaf);
    }
  }

  void _ground(Canvas c, Size size) {
    final g = geo;
    // The back lane (packed earth with a brick edge).
    final back = Rect.fromLTRB(0, g.houseBase, size.width, g.backY + 14 * g.k);
    c.drawRect(back, Paint()..color = const Color(0xFFB59C7A));
    c.drawLine(Offset(0, g.houseBase + 1), Offset(size.width, g.houseBase + 1), Paint()
      ..color = const Color(0xFF8E6E52)
      ..strokeWidth = 2);
    // Between the back lane and the main road: verge and the plot's ground.
    final mid = Rect.fromLTRB(0, back.bottom, size.width, g.htPoleBase + 4);
    c.drawRect(
      mid,
      Paint()
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8DA06A), Color(0xFF7A8E5C)])
            .createShader(mid),
    );
    // The main road (tarmac) and its near edge.
    final road = Rect.fromLTRB(0, mid.bottom, size.width, size.height);
    c.drawRect(
      road,
      Paint()
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF5E6064), Color(0xFF47494D)])
            .createShader(road),
    );
    final dash = Paint()
      ..color = const Color(0xCCE9E2CF)
      ..strokeWidth = 2.2;
    final dy = g.mainY + 14 * g.k;
    for (var x = 6.0; x < size.width; x += 34) {
      c.drawLine(Offset(x, dy), Offset(x + 16, dy), dash);
    }
    final kerb = Paint()..color = const Color(0xFF9C9A92);
    c.drawRect(Rect.fromLTRB(0, mid.bottom, size.width, mid.bottom + 3), kerb);
    // A hand-cart path worn across the verge.
    final cart = Paint()
      ..color = const Color(0x55684E33)
      ..strokeWidth = 3;
    c.drawLine(Offset(300, back.bottom), Offset(326, mid.bottom), cart);
    c.drawLine(Offset(312, back.bottom), Offset(338, mid.bottom), cart);
  }

  void _freeLane(Canvas c) {
    final g = geo;
    const x = M7WarnGeo.laneX;
    final far = g.laneFarY - 10 * g.k;
    final lane = Path()
      ..moveTo(x - 22, g.houseBase)
      ..lineTo(x - 9, far)
      ..lineTo(x + 9, far)
      ..lineTo(x + 22, g.houseBase)
      ..close();
    c.drawPath(lane, Paint()..color = const Color(0xFFA88E6C));
    // The far wall at its end (in shade).
    c.drawRect(Rect.fromLTRB(x - 14, far - 22 * g.k, x + 14, far), Paint()..color = const Color(0xFF8C7F72));
  }

  void _house(Canvas c, int i) {
    final g = geo;
    final r = g.house(i);
    const walls = [Color(0xFFE2C79A), Color(0xFFCFD8C4), Color(0xFFE6B9A2)];
    c.drawRect(r, Paint()..color = walls[i]);
    c.drawRect(Rect.fromLTRB(r.left, r.top, r.right, r.top + 4 * g.k), Paint()..color = const Color(0xFFB0A493));
    // Parapet line and a water tank on house B.
    c.drawRect(Rect.fromLTRB(r.left - 2, r.top - 3 * g.k, r.right + 2, r.top + 1), Paint()..color = const Color(0xFF9D917F));
    if (i == 1) {
      final tank = Rect.fromLTWH(r.right - 26, r.top - 18 * g.k, 18, 15 * g.k);
      c.drawRRect(RRect.fromRectAndRadius(tank, const Radius.circular(3)), Paint()..color = const Color(0xFF3E4A44));
    }
    // Windows and a door.
    final win = Paint()..color = const Color(0xFF51606B);
    final frame = Paint()
      ..color = const Color(0xFF7A5A3C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final w = r.width;
    for (final fx in [0.16, 0.62]) {
      final wr = Rect.fromLTWH(r.left + w * fx, r.top + g.houseH * 0.28, w * 0.2, g.houseH * 0.3);
      c.drawRect(wr, win);
      c.drawRect(wr, frame);
    }
    final door = Rect.fromLTWH(r.left + w * 0.4, r.bottom - g.houseH * 0.52, w * 0.16, g.houseH * 0.52);
    c.drawRect(door, Paint()..color = const Color(0xFF6B4A2E));
    // Roof clutter: a broken chair and pots.
    final pot = Paint()..color = const Color(0xFF9E5A3A);
    c.drawRect(Rect.fromLTWH(r.right - 14 - (i == 1 ? 26 : 0), r.top - 6 * g.k, 7, 6 * g.k), pot);
  }

  void _roofItems(Canvas c) {
    final g = geo;
    final v = view;
    if (v.roofState == M7WarnRoofState.shown) {
      final at = g.roofSpot(v.roofHouse);
      if (v.roof == M7WarnRoof.clothes) {
        _clothesLine(c, at, wet: true);
        m7WarnFigure(c, at + Offset(30, 0), 0.62 * (0.8 + 0.2 * g.k), tint: 3, sari: true, armUp: true, facingLeft: true);
      } else {
        // A long bamboo leaning up from the roof toward the wire.
        final foot = at + Offset(-8, 0);
        final tip = Offset(at.dx + 22, g.ltWireY(at.dx + 22) + 7 * g.k);
        _bamboo(c, foot, tip, 3.2);
        m7WarnFigure(c, at + Offset(26, 0), 0.62 * (0.8 + 0.2 * g.k), tint: 1, armUp: true, facingLeft: true);
      }
    }
    if (v.decoyRoof) {
      final at = g.roofSpot(2);
      _clothesLine(c, at, wet: true);
      m7WarnFigure(c, at + Offset(30, 0), 0.62 * (0.8 + 0.2 * g.k), tint: 4, sari: true, armUp: true, facingLeft: true);
    }
  }

  void _clothesLine(Canvas c, Offset at, {required bool wet}) {
    final g = geo;
    final h = 30 * g.k;
    final stick = Paint()
      ..color = const Color(0xFF7A5A3C)
      ..strokeWidth = 1.8;
    final a = at + Offset(-20, 0);
    final b = at + Offset(18, 0);
    c.drawLine(a, a + Offset(0, -h), stick);
    c.drawLine(b, b + Offset(0, -h), stick);
    final line = Paint()
      ..color = const Color(0xFF3A3A3A)
      ..strokeWidth = 1;
    c.drawLine(a + Offset(0, -h), b + Offset(0, -h), line);
    const cloth = [Color(0xFFD0453A), Color(0xFF3C7FC2), Color(0xFFE2B13C), Color(0xFF6BA35A)];
    for (var i = 0; i < 4; i++) {
      final x = a.dx + 3 + i * 9.0;
      final r = Rect.fromLTWH(x, a.dy - h + 1, 7.5, (12 + (i % 2) * 4) * g.k);
      c.drawRect(r, Paint()..color = cloth[i]);
      if (wet) {
        c.drawCircle(Offset(r.center.dx, r.bottom + 3), 0.9, Paint()..color = const Color(0xCC5AA0D8));
      }
    }
  }

  void _bamboo(Canvas c, Offset from, Offset to, double w) {
    c.drawLine(
      from,
      to,
      Paint()
        ..color = const Color(0xFFC9A55A)
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round,
    );
    final d = to - from;
    final n = Offset(-d.dy, d.dx) / d.distance;
    final knot = Paint()
      ..color = const Color(0xFF8C6E35)
      ..strokeWidth = 1;
    for (var t = 0.2; t < 1; t += 0.2) {
      final p = from + d * t;
      c.drawLine(p - n * w * 0.6, p + n * w * 0.6, knot);
    }
  }

  void _pole(Canvas c, Offset base, double topY, double w) {
    final body = Rect.fromLTRB(base.dx - w / 2, topY, base.dx + w / 2, base.dy);
    c.drawRect(
      body,
      Paint()..shader = const LinearGradient(colors: [Color(0xFF8F949A), Color(0xFFD0D4D8), Color(0xFF7D838A)]).createShader(body),
    );
    c.drawOval(Rect.fromCenter(center: base, width: w * 2.4, height: 3), Paint()..color = const Color(0x55000000));
  }

  void _ltLine(Canvas c) {
    final g = geo;
    for (final x in M7WarnGeo.ltXs) {
      _pole(c, Offset(x, g.houseBase + 3), g.ltY - 12 * g.k, 4.6);
      c.drawRect(Rect.fromCenter(center: Offset(x, g.ltY - 6 * g.k), width: 22, height: 3), Paint()..color = const Color(0xFF6A5A48));
    }
    final wire = Paint()
      ..color = const Color(0xFF2A2C2F)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (var w = 0; w < 2; w++) {
      final p = Path();
      for (var x = M7WarnGeo.ltXs.first; x <= M7WarnGeo.ltXs.last + 0.1; x += 4) {
        final yy = g.ltWireY(x, sagSpan: view.sagSpan, wire: w);
        if (x == M7WarnGeo.ltXs.first) {
          p.moveTo(x, yy);
        } else {
          p.lineTo(x, yy);
        }
      }
      c.drawPath(p, wire);
    }
    // The service drop into house B (an ordinary span end).
    c.drawLine(Offset(M7WarnGeo.ltXs.last, g.ltY), Offset(g.house(1).right - 6, g.roofY + 6), Paint()
      ..color = const Color(0xFF2A2C2F)
      ..strokeWidth = 1);
  }

  void _plot(Canvas c) {
    final g = geo;
    final p = g.plot;
    final base = g.plotBase;
    // The plot's ground (bare earth, a sand heap, bricks).
    c.drawRect(Rect.fromLTRB(p.left, base - 8 * g.k, p.right, base + 2), Paint()..color = const Color(0xFF9B8461));
    c.drawPath(
      Path()
        ..moveTo(p.left + 6, base)
        ..quadraticBezierTo(p.left + 22, base - 18 * g.k, p.left + 40, base)
        ..close(),
      Paint()..color = const Color(0xFFD8BE85),
    );
    if (!view.build) {
      // A vacant plot: grass tufts and a stack of old bricks.
      final tuft = Paint()
        ..color = const Color(0xFF5F7A45)
        ..strokeWidth = 1.4;
      for (var i = 0; i < 7; i++) {
        final x = p.left + 50 + i * 11.0;
        c.drawLine(Offset(x, base - 2), Offset(x - 2, base - 9 * g.k), tuft);
        c.drawLine(Offset(x, base - 2), Offset(x + 3, base - 8 * g.k), tuft);
      }
      c.drawRect(Rect.fromLTWH(p.right - 30, base - 10 * g.k, 20, 10 * g.k), Paint()..color = const Color(0xFFA2553A));
      return;
    }
    // A half-built house: brick walls, a bamboo scaffold up toward the line.
    final wall = Rect.fromLTRB(p.left + 44, base - 58 * g.k, p.right - 8, base - 2);
    c.drawRect(wall, Paint()..color = const Color(0xFFB4593C));
    final mortar = Paint()
      ..color = const Color(0x66E8D2B8)
      ..strokeWidth = 0.8;
    for (var yy = wall.top + 5; yy < wall.bottom; yy += 6) {
      c.drawLine(Offset(wall.left, yy), Offset(wall.right, yy), mortar);
    }
    c.drawRect(Rect.fromLTWH(wall.left + 22, wall.bottom - 30 * g.k, 18, 30 * g.k), Paint()..color = const Color(0xFF5B4636));
    final pole = Paint()
      ..color = const Color(0xFFC9A55A)
      ..strokeWidth = 2.2;
    final sTop = base - 94 * g.k;
    for (final x in [p.left + 36, p.left + 70, p.left + 104]) {
      c.drawLine(Offset(x, base), Offset(x, sTop), pole);
    }
    for (final yy in [base - 30 * g.k, base - 62 * g.k, sTop + 6 * g.k]) {
      c.drawLine(Offset(p.left + 34, yy), Offset(p.left + 106, yy), pole);
    }
    final s = 0.66 * (0.8 + 0.2 * g.k);
    if (view.masonsDown) {
      m7WarnFigure(c, Offset(p.left + 18, base), s, tint: 2);
      m7WarnFigure(c, Offset(p.left + 30, base + 1), s, tint: 5, facingLeft: true);
    } else {
      // Two masons up on the top board, one lifting a steel bar.
      m7WarnFigure(c, Offset(p.left + 52, sTop + 6 * g.k), s, tint: 2, armUp: true);
      m7WarnFigure(c, Offset(p.left + 88, sTop + 6 * g.k), s, tint: 5, facingLeft: true);
      c.drawLine(Offset(p.left + 56, sTop - 4 * g.k), Offset(p.left + 66, sTop - 26 * g.k), Paint()
        ..color = const Color(0xFF6E737A)
        ..strokeWidth = 1.6);
    }
  }

  void _htLine(Canvas c) {
    final g = geo;
    for (final x in M7WarnGeo.htXs) {
      _pole(c, Offset(x, g.htPoleBase), g.htWireY(x, 0) - 14 * g.k, 6.4);
      final arm = Rect.fromCenter(center: Offset(x, g.htWireY(x, 0) - 4 * g.k), width: 34, height: 4);
      c.drawRect(arm, Paint()..color = const Color(0xFF55595E));
      for (final dx in [-13.0, 0.0, 13.0]) {
        c.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x + dx, arm.top - 3), width: 4, height: 7), const Radius.circular(2)),
          Paint()..color = const Color(0xFFE8E2D6),
        );
      }
    }
    final wire = Paint()
      ..color = const Color(0xFF26282B)
      ..strokeWidth = 1.7
      ..style = PaintingStyle.stroke;
    for (var w = 0; w < 3; w++) {
      final p = Path()..moveTo(-4, g.htWireY(0, w));
      for (var x = 0.0; x <= 364; x += 6) {
        p.lineTo(x, g.htWireY(x, w));
      }
      c.drawPath(p, wire);
    }
  }

  @override
  bool shouldRepaint(M7WarnLanePainter old) => old.view != view || old.geo.height != geo.height || old.geo.bottom != geo.bottom;
}

/// The people (repaints on its notifier while they walk; still otherwise).
class M7WarnActorsPainter extends CustomPainter {
  M7WarnActorsPainter({required this.geo, required this.views, super.repaint});
  final M7WarnGeo geo;
  final List<M7WarnActorView> Function() views;

  @override
  void paint(Canvas canvas, Size size) {
    final list = [...views()]..sort((a, b) => a.at.dy.compareTo(b.at.dy));
    for (final v in list) {
      if (v.opacity <= 0.01) continue;
      _person(canvas, v);
    }
  }

  void _person(Canvas c, M7WarnActorView v) {
    final s = geo.scaleAt(v.at);
    final a = (v.opacity.clamp(0.0, 1.0) * 255).round();
    Color op(Color col) => col.withAlpha((col.a * a).round());
    final f = v.facingLeft ? -1.0 : 1.0;
    final o = v.at;
    final swing = v.phase == null ? 0.0 : math.sin(v.phase! * 2 * math.pi) * 4 * s;
    if (v.look == M7WarnLook.bamboo) {
      // Two labourers carrying one long bamboo between them.
      final back = o + Offset(-f * 16 * s, 0);
      final front = o + Offset(f * 16 * s, 0);
      _body(c, back, s, v.tint, swing, op, f);
      _body(c, front, s, v.tint + 1, -swing, op, f);
      final hBack = back + Offset(0, -30 * s);
      final hFront = front + Offset(0, -30 * s);
      Offset tail = hBack + Offset(-f * 30 * s, 2 * s);
      Offset tip = hFront + Offset(f * 30 * s, -2 * s);
      if (v.up) {
        // Up the free lane: the bamboo points along the lane.
        tail = hBack + Offset(0, 22 * s);
        tip = hFront + Offset(0, -22 * s);
      }
      if (v.liftTo != null && v.lift > 0) tip = Offset.lerp(tip, v.liftTo!, Curves.easeIn.transform(v.lift))!;
      if (v.lowered) tip = hFront + Offset(f * 30 * s, 6 * s);
      _pole(c, tail, tip, 3.4 * s, op(const Color(0xFFC9A55A)), knots: true, op: op);
    } else {
      _body(c, o, s, v.tint, swing, op, f, bike: v.look == M7WarnLook.cyclist);
      final hand = o + Offset(f * 5 * s, -24 * s);
      switch (v.look) {
        case M7WarnLook.rod:
          var tip = hand + Offset(f * 30 * s, -46 * s);
          final tail = hand + Offset(-f * 12 * s, 16 * s);
          if (v.liftTo != null && v.lift > 0) tip = Offset.lerp(tip, v.liftTo!, Curves.easeIn.transform(v.lift))!;
          if (v.lowered) tip = hand + Offset(f * 44 * s, 4 * s);
          _pole(c, tail, tip, 2.2 * s, op(const Color(0xFF6E737A)));
        case M7WarnLook.vendor:
          // A basket on the head.
          final head = o + Offset(0, -33 * s);
          c.drawOval(Rect.fromCenter(center: head + Offset(0, -6 * s), width: 18 * s, height: 7 * s), Paint()..color = op(const Color(0xFFB98A4A)));
          c.drawCircle(head + Offset(-3 * s, -9 * s), 2.6 * s, Paint()..color = op(const Color(0xFFD9583B)));
          c.drawCircle(head + Offset(3 * s, -9 * s), 2.6 * s, Paint()..color = op(const Color(0xFF7DB04E)));
        case M7WarnLook.bag:
          final b = Rect.fromLTWH(o.dx + f * 5 * s - 4 * s, o.dy - 18 * s, 8 * s, 9 * s);
          c.drawRRect(RRect.fromRectAndRadius(b, Radius.circular(2 * s)), Paint()..color = op(const Color(0xFF3F5E7C)));
        case M7WarnLook.cyclist || M7WarnLook.bamboo:
          break;
      }
    }
    if (v.palm) _palm(c, o + Offset(0, -50 * s), s, op);
  }

  void _body(Canvas c, Offset o, double s, int tint, double swing, Color Function(Color) op, double f, {bool bike = false}) {
    c.drawOval(Rect.fromCenter(center: o, width: (bike ? 30 : 16) * s, height: 4 * s), Paint()..color = op(const Color(0x55000000)));
    if (bike) {
      final wheel = Paint()
        ..color = op(const Color(0xFF2A2C2F))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6 * s;
      c.drawCircle(o + Offset(-10 * s, -6 * s), 6 * s, wheel);
      c.drawCircle(o + Offset(10 * s, -6 * s), 6 * s, wheel);
      c.drawLine(o + Offset(-10 * s, -6 * s), o + Offset(10 * s, -6 * s), wheel);
      c.drawLine(o + Offset(10 * s, -6 * s), o + Offset(f * 9 * s, -18 * s), wheel);
    }
    final leg = Paint()
      ..color = op(_skin)
      ..strokeWidth = 2.6 * s
      ..strokeCap = StrokeCap.round;
    final hip = o + Offset(0, bike ? -16 * s : -12 * s);
    if (bike) {
      c.drawLine(hip, o + Offset(swing * 0.5, -6 * s), leg);
    } else {
      c.drawLine(hip + Offset(-2 * s, 0), o + Offset(-2 * s + swing, 0), leg);
      c.drawLine(hip + Offset(2 * s, 0), o + Offset(2 * s - swing, 0), leg);
    }
    c.drawPath(
      Path()
        ..moveTo(hip.dx - 5 * s, hip.dy - 10 * s)
        ..lineTo(hip.dx + 5 * s, hip.dy - 10 * s)
        ..lineTo(hip.dx + 6 * s, hip.dy + 3 * s)
        ..lineTo(hip.dx - 6 * s, hip.dy + 3 * s)
        ..close(),
      Paint()..color = op(_lungis[tint % _lungis.length]),
    );
    final torso = RRect.fromRectAndRadius(Rect.fromLTWH(hip.dx - 6 * s, hip.dy - 24 * s, 12 * s, 15 * s), Radius.circular(3 * s));
    c.drawRRect(torso, Paint()..color = op(_shirts[tint % _shirts.length]));
    final arm = Paint()
      ..color = op(_skin)
      ..strokeWidth = 2.2 * s
      ..strokeCap = StrokeCap.round;
    c.drawLine(hip + Offset(f * 4 * s, -21 * s), hip + Offset(f * 6 * s, -12 * s), arm);
    c.drawLine(hip + Offset(-f * 4 * s, -21 * s), hip + Offset(-f * 4 * s + swing * 0.6, -10 * s), arm);
    final head = hip + Offset(f * 0.5 * s, -29 * s);
    c.drawCircle(head, 4.6 * s, Paint()..color = op(_skin));
    c.drawArc(Rect.fromCircle(center: head, radius: 4.8 * s), math.pi, math.pi, false, Paint()..color = op(_hair));
  }

  void _pole(Canvas c, Offset from, Offset to, double w, Color col, {bool knots = false, Color Function(Color)? op}) {
    c.drawLine(
      from,
      to,
      Paint()
        ..color = col
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round,
    );
    if (!knots || op == null) return;
    final d = to - from;
    if (d.distance < 1) return;
    final n = Offset(-d.dy, d.dx) / d.distance;
    final knot = Paint()
      ..color = op(const Color(0xFF8C6E35))
      ..strokeWidth = 1;
    for (var t = 0.15; t < 1; t += 0.17) {
      final p = from + d * t;
      c.drawLine(p - n * w * 0.6, p + n * w * 0.6, knot);
    }
  }

  /// A raised open palm (the trainee's "stop" reached him).
  void _palm(Canvas c, Offset at, double s, Color Function(Color) op) {
    c.drawCircle(at, 8 * s, Paint()..color = op(const Color(0xEEFFFFFF)));
    final p = Paint()..color = op(const Color(0xFFD8452F));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: at + Offset(0, 1.5 * s), width: 6 * s, height: 5 * s), Radius.circular(1.5 * s)), p);
    for (var i = 0; i < 4; i++) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(at.dx - 3 * s + i * 1.6 * s, at.dy - 5 * s, 1.2 * s, 5 * s), Radius.circular(0.6 * s)), p);
    }
  }

  @override
  bool shouldRepaint(M7WarnActorsPainter old) => true;
}

/// A load touched the line: the flash at the wire, in colour over the grey
/// scene.
class M7WarnFlashPainter extends CustomPainter {
  const M7WarnFlashPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas canvas, Size size) {
    final k = Curves.easeOut.transform(v.clamp(0.0, 1.0));
    final glow = Paint()
      ..shader = RadialGradient(colors: [
        Color.fromRGBO(255, 250, 210, 0.95 * (1 - k * 0.4)),
        Color.fromRGBO(255, 190, 60, 0.6 * (1 - k * 0.5)),
        const Color(0x00FF9020),
      ]).createShader(Rect.fromCircle(center: at, radius: 18 + 36 * k));
    canvas.drawCircle(at, 18 + 36 * k, glow);
    final bolt = Paint()
      ..color = Color.fromRGBO(255, 245, 190, 1 - k * 0.5)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + 0.3;
      final r1 = 7 + 9 * k;
      final r2 = 16 + 28 * k;
      final mid = at + Offset(math.cos(a + 0.2) * (r1 + r2) / 2, math.sin(a + 0.2) * (r1 + r2) / 2);
      canvas.drawLine(at + Offset(math.cos(a) * r1, math.sin(a) * r1), mid, bolt);
      canvas.drawLine(mid, at + Offset(math.cos(a) * r2, math.sin(a) * r2), bolt);
    }
  }

  @override
  bool shouldRepaint(M7WarnFlashPainter old) => old.v != v || old.at != at;
}

/// The hold ring under the finger (fills over the hold time).
class M7WarnHoldRingPainter extends CustomPainter {
  const M7WarnHoldRingPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(at, 20, Paint()
      ..color = const Color(0x55FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
    canvas.drawArc(
      Rect.fromCircle(center: at, radius: 20),
      -math.pi / 2,
      2 * math.pi * v.clamp(0.0, 1.0),
      false,
      Paint()
        ..color = const Color(0xFFFFD26A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(M7WarnHoldRingPainter old) => old.v != v || old.at != at;
}
