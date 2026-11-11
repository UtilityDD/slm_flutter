import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/en_digits.dart';

// The place of "এল এ-র খবর" (lesson 3.5 লাইটনিং অ্যারেস্টার, কাজ 1): a
// distribution transformer (DTR) on a two-pole structure, the morning after a
// storm — a torn grey sky clearing, wet fields, puddles in the lane, a broken
// branch. On the top channel the 11 kV line on pin insulators; just below it,
// on the LA channel beside the HT bushings, three lightning arresters (R Y B —
// one per phase, pro tip 3), porcelain (brown) or polymer (grey, pro tip 4).
// Under each LA its disconnector; from it the LA's own earth lead runs to the
// pole and down to its earth rod (lesson point 3). The transformer sits on the
// platform between the poles. The only words a worker reads: the DTR number
// plate on the pole.
//
// What a storm can leave (lesson point 3): a disconnector blown and the earth
// lead hanging loose; a crack, a burn mark, a burst body; an earth lead cut.
//
// Design: 360 wide × the scene's height; the ground row follows the bottom of
// the screen (a tall phone gets more sky).

/// The three arresters, one per phase.
enum M3LaPatrolPhase { r, y, b }

/// What an arrester (and its earth lead) looks like after the storm.
enum M3LaPatrolFault { healthy, dropped, cracked, burnt, burst, leadCut }

/// The housing (lesson pro tip 4).
enum M3LaPatrolBody { porcelain, polymer }

String m3LaPatrolPhaseBn(M3LaPatrolPhase p) => switch (p) {
      M3LaPatrolPhase.r => 'R',
      M3LaPatrolPhase.y => 'Y',
      M3LaPatrolPhase.b => 'B',
    };

/// Where things stand (design px, 360 wide).
@immutable
class M3LaPatrolGeo {
  const M3LaPatrolGeo({required this.height, required this.groundY});

  factory M3LaPatrolGeo.forScene(double h, double inset) => M3LaPatrolGeo(height: h, groundY: (h - 270 - inset).clamp(420.0, 720.0));

  final double height;
  final double groundY;

  double get horizonY => groundY - 70;

  static const leftPoleX = 73.0;
  static const rightPoleX = 290.0;

  double get lineY => groundY - 392;
  double get topChannelY => groundY - 376;
  double get laChannelY => groundY - 300;
  double get laTop => groundY - 364;

  /// The LA's own column x (R Y B).
  static double laX(M3LaPatrolPhase p) => const [118.0, 181.0, 244.0][p.index];

  /// The arrester with its disconnector.
  Rect laBody(M3LaPatrolPhase p) => Rect.fromLTRB(laX(p) - 13, laTop, laX(p) + 13, groundY - 284);

  /// The transformer tank and its HT bushings.
  Rect get tank => Rect.fromLTRB(128, groundY - 214, 234, groundY - 128);
  List<Offset> get bushings => [for (final x in const [150.0, 181.0, 212.0]) Offset(x, groundY - 232)];
  double get platformY => groundY - 128;

  /// The earth lead as fitted: LA bottom → the pole → down → its rod.
  List<Offset> lead(M3LaPatrolPhase p) {
    final g = groundY;
    final x = laX(p);
    return switch (p) {
      M3LaPatrolPhase.r => [Offset(x, g - 284), Offset(x, g - 272), Offset(64, g - 246), Offset(64, g - 12), Offset(54, g + 2)],
      M3LaPatrolPhase.y => [Offset(x, g - 284), Offset(x, g - 266), Offset(82, g - 232), Offset(82, g - 12), Offset(94, g + 2)],
      M3LaPatrolPhase.b => [Offset(x, g - 284), Offset(x, g - 272), Offset(298, g - 246), Offset(298, g - 12), Offset(308, g + 2)],
    };
  }

  /// The x of the lead's run down the pole.
  static double runX(M3LaPatrolPhase p) => const [64.0, 82.0, 298.0][p.index];

  /// Which way is "away from the pole" for this lead (−1 left, +1 right).
  static double outward(M3LaPatrolPhase p) => p == M3LaPatrolPhase.r ? -1 : 1;

  /// A dropped lead: still clipped from this point down; above it, loose.
  Offset dropClip(M3LaPatrolPhase p) => Offset(runX(p), groundY - 176);

  /// The loose end of a dropped lead (with the blown disconnector's piece),
  /// hanging out from the pole.
  Offset dropEnd(M3LaPatrolPhase p) => Offset(runX(p) + outward(p) * 30, groundY - 72);

  /// The dropped lead's loose part (a curve), sampled.
  List<Offset> dropPath(M3LaPatrolPhase p) {
    final a = dropClip(p);
    final e = dropEnd(p);
    final ctl = Offset(a.dx + outward(p) * 30, a.dy + 30);
    return [
      for (var i = 0; i <= 10; i++)
        () {
          final t = i / 10;
          final u = 1 - t;
          return Offset(u * u * a.dx + 2 * u * t * ctl.dx + t * t * e.dx, u * u * a.dy + 2 * u * t * ctl.dy + t * t * e.dy);
        }(),
    ];
  }

  /// A cut lead: the upper part ends here, the stub starts at [cutBottom].
  Offset cutTop(M3LaPatrolPhase p) => Offset(runX(p) + outward(p) * 10, groundY - 86);
  Offset cutBottom(M3LaPatrolPhase p) => Offset(runX(p), groundY - 38);

  /// Where a mark ring goes for this phase and fault.
  Offset markAt(M3LaPatrolPhase p, M3LaPatrolFault f) => switch (f) {
        M3LaPatrolFault.dropped => dropEnd(p) + const Offset(0, -18),
        M3LaPatrolFault.leadCut => Offset(runX(p), groundY - 62),
        _ => laBody(p).center,
      };

  /// The phase a tap reaches (the LA, or anywhere along its earth lead), or
  /// null. The nearest wins.
  M3LaPatrolPhase? hit(Offset q, {M3LaPatrolPhase? dropped}) {
    M3LaPatrolPhase? best;
    var bestD = 22.0;
    for (final p in M3LaPatrolPhase.values) {
      var d = laBody(p).inflate(10).contains(q) ? 0.0 : double.infinity;
      d = math.min(d, _distToPolyline(q, lead(p)));
      if (p == dropped) d = math.min(d, _distToPolyline(q, dropPath(p)) - 4);
      if (d < bestD) {
        bestD = d;
        best = p;
      }
    }
    return best;
  }

  static double _distToPolyline(Offset q, List<Offset> pts) {
    var best = double.infinity;
    for (var i = 0; i + 1 < pts.length; i++) {
      final a = pts[i], b = pts[i + 1];
      final ab = b - a;
      final len2 = ab.dx * ab.dx + ab.dy * ab.dy;
      final t = len2 == 0 ? 0.0 : (((q - a).dx * ab.dx + (q - a).dy * ab.dy) / len2).clamp(0.0, 1.0);
      best = math.min(best, (q - (a + ab * t)).distance);
    }
    return best;
  }

  /// The trainee: in the lane in front of the structure (nearer the camera).
  Rect get trainee => Rect.fromLTWH(150, groundY - 120, 96, 192);

  /// The trainee standing right under a lead (the deadly reach).
  Rect traineeAt(Offset reach) => Rect.fromLTWH((reach.dx - 70).clamp(0.0, 264.0), groundY - 120, 96, 192);

  @override
  bool operator ==(Object other) => other is M3LaPatrolGeo && other.height == height && other.groundY == groundY;

  @override
  int get hashCode => Object.hash(height, groundY);
}

/// The sky, the land, the DTR structure, the line, the three arresters and
/// their earth leads, as this round's case left them.
class M3LaPatrolWorldPainter extends CustomPainter {
  const M3LaPatrolWorldPainter({
    required this.geo,
    required this.dtrNo,
    required this.body,
    required this.fault,
    required this.phase,
  });

  final M3LaPatrolGeo geo;
  final int dtrNo;
  final M3LaPatrolBody body;
  final M3LaPatrolFault fault;

  /// The phase the fault is on (ignored when healthy).
  final M3LaPatrolPhase phase;

  bool _is(M3LaPatrolPhase p, M3LaPatrolFault f) => fault == f && phase == p;

  @override
  void paint(Canvas c, Size size) {
    _sky(c, size);
    _land(c, size);
    _structure(c);
    _line(c, size);
    _tank(c);
    for (final p in M3LaPatrolPhase.values) {
      _leadOf(c, p);
    }
    for (final p in M3LaPatrolPhase.values) {
      _arrester(c, p);
    }
    _plate(c);
  }

  // --- the place --------------------------------------------------------------
  void _sky(Canvas c, Size size) {
    final w = size.width;
    final hz = geo.horizonY;
    final r = Rect.fromLTWH(0, 0, w, hz + 4);
    c.drawRect(r, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3E4B5C), Color(0xFF7D8D9E), Color(0xFFC9CFC8)]).createShader(r));
    // A gap clearing in the clouds.
    c.drawOval(Rect.fromCenter(center: Offset(250, hz * 0.42), width: 200, height: 70), Paint()..color = const Color(0x30DDE8F0));
    // Heavy storm clouds moving off.
    final cloud = Paint()..color = const Color(0xCC4A5664);
    final cloud2 = Paint()..color = const Color(0x99606C7A);
    for (final (x, y, rr) in [(20.0, 70.0, 46.0), (70.0, 56.0, 40.0), (120.0, 76.0, 38.0), (300.0, 40.0, 42.0), (350.0, 60.0, 36.0)]) {
      c.drawCircle(Offset(x, y), rr, cloud);
    }
    for (final (x, y, rr) in [(170.0, 120.0, 30.0), (205.0, 112.0, 26.0), (330.0, 150.0, 22.0), (40.0, 160.0, 24.0)]) {
      c.drawCircle(Offset(x, y), rr, cloud2);
    }
    // Far tree line and a far line of poles.
    final far = Path()..moveTo(0, hz);
    for (var x = 0.0; x <= w; x += 16) {
      far.lineTo(x, hz - 16 - 9 * math.sin(x * 0.08) - 5 * math.cos(x * 0.21));
    }
    far
      ..lineTo(w, hz + 2)
      ..lineTo(0, hz + 2)
      ..close();
    c.drawPath(far, Paint()..color = const Color(0xFF41604A));
    final farPole = Paint()
      ..color = const Color(0xFF6E7570)
      ..strokeWidth = 2;
    for (final x in [24.0, 336.0]) {
      c.drawLine(Offset(x, hz - 60), Offset(x, hz + 2), farPole);
      c.drawLine(Offset(x - 8, hz - 56), Offset(x + 8, hz - 56), farPole);
    }
  }

  void _land(Canvas c, Size size) {
    final w = size.width;
    final g = geo.groundY;
    final hz = geo.horizonY;
    // Wet fields.
    final f = Rect.fromLTWH(0, hz, w, g - hz);
    c.drawRect(f, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF5E7E4A), Color(0xFF4A6A3A)]).createShader(f));
    // The muddy lane to the bottom.
    final l = Rect.fromLTWH(0, g - 4, w, size.height - g + 4);
    c.drawRect(l, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8E7A5C), Color(0xFF6E5C44)]).createShader(l));
    // Puddles (sky in them).
    for (final (x, y, pw) in [(46.0, 46.0, 70.0), (250.0, 120.0, 96.0), (120.0, 190.0, 60.0)]) {
      final r = Rect.fromCenter(center: Offset(x, g + y), width: pw, height: pw * 0.18);
      c.drawOval(r, Paint()..color = const Color(0xFF9FB0BE));
      c.drawOval(r.deflate(3).shift(const Offset(4, -1)), Paint()..color = const Color(0x66E4ECF2));
    }
    final rnd = math.Random(5);
    final pebble = Paint()..color = const Color(0x33000000);
    for (var i = 0; i < 24; i++) {
      c.drawCircle(Offset(rnd.nextDouble() * w, g + 8 + rnd.nextDouble() * (size.height - g - 12)), 1.2 + rnd.nextDouble() * 1.4, pebble);
    }
    // A branch the storm brought down, with leaves.
    final br = Paint()
      ..color = const Color(0xFF4B3524)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(300, g + 64), Offset(356, g + 40), br);
    c.drawLine(Offset(326, g + 53), Offset(340, g + 28), br..strokeWidth = 3);
    final leaf = Paint()..color = const Color(0xFF3E6B32);
    for (final (x, y) in [(338.0, 26.0), (346.0, 34.0), (356.0, 38.0), (312.0, 58.0), (330.0, 30.0)]) {
      c.drawOval(Rect.fromCenter(center: Offset(x, g + y), width: 12, height: 6), leaf);
    }
  }

  void _structure(Canvas c) {
    final g = geo.groundY;
    for (final px in const [M3LaPatrolGeo.leftPoleX, M3LaPatrolGeo.rightPoleX]) {
      final top = geo.lineY - 18;
      final pole = Path()
        ..moveTo(px - 6, top)
        ..lineTo(px + 6, top)
        ..lineTo(px + 9, g + 2)
        ..lineTo(px - 9, g + 2)
        ..close();
      c.drawPath(pole, Paint()..shader = const LinearGradient(colors: [Color(0xFFBDBDB5), Color(0xFF8A8A83)]).createShader(Rect.fromLTRB(px - 9, top, px + 9, g)));
      c.drawOval(Rect.fromCenter(center: Offset(px, g + 3), width: 40, height: 7), Paint()..color = const Color(0x33000000));
    }
    final steel = Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF5A616B), Color(0xFF3A4048)]).createShader(Rect.fromLTWH(0, geo.topChannelY, 360, 8));
    // Top channel (line), LA channel, platform.
    c.drawRect(Rect.fromLTRB(56, geo.topChannelY, 308, geo.topChannelY + 7), steel);
    c.drawRect(Rect.fromLTRB(60, geo.laChannelY, 304, geo.laChannelY + 6), Paint()..color = const Color(0xFF474D56));
    c.drawRect(Rect.fromLTRB(58, geo.platformY, 306, geo.platformY + 9), Paint()..color = const Color(0xFF3F454D));
    // Earth rods with their clamps (one per LA lead).
    for (final p in M3LaPatrolPhase.values) {
      final e = geo.lead(p).last;
      c.drawRect(Rect.fromCenter(center: e + const Offset(0, 2), width: 7, height: 10), Paint()..color = const Color(0xFF6B5A3C));
      c.drawRect(Rect.fromCenter(center: e + const Offset(0, -2), width: 10, height: 4), Paint()..color = const Color(0xFF9A9A92));
    }
  }

  void _line(Canvas c, Size size) {
    final wire = Paint()
      ..color = const Color(0xFF23282E)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    final ins = Paint()..color = const Color(0xFFEDEBE3);
    final insShade = Paint()..color = const Color(0xFFB9B6AA);
    for (final p in M3LaPatrolPhase.values) {
      final x = M3LaPatrolGeo.laX(p);
      final y = geo.lineY + p.index * 0.0;
      // The conductor across the screen (a little sag between structures).
      c.drawPath(
          Path()
            ..moveTo(0, y + 10 + p.index * 3)
            ..quadraticBezierTo(x / 2, y + 16, x, y)
            ..quadraticBezierTo((x + 360) / 2, y + 14, 360, y + 8 + p.index * 3),
          wire);
      // Pin insulator.
      c.drawRect(Rect.fromLTWH(x - 2, y + 2, 4, geo.topChannelY - y - 2), insShade);
      c.drawOval(Rect.fromCenter(center: Offset(x, y + 4), width: 16, height: 6), ins);
      c.drawOval(Rect.fromCenter(center: Offset(x, y + 9), width: 12, height: 5), ins);
      // Jumper to the transformer bushing.
      final bu = geo.bushings[p.index];
      c.drawPath(
          Path()
            ..moveTo(x + 6, y + 1)
            ..quadraticBezierTo(x + 12, (y + bu.dy) / 2, bu.dx, bu.dy - 2),
          Paint()
            ..color = const Color(0xFF30363D)
            ..strokeWidth = 1.2
            ..style = PaintingStyle.stroke);
    }
  }

  void _tank(Canvas c) {
    final t = geo.tank;
    c.drawRRect(RRect.fromRectAndRadius(t.shift(const Offset(3, 4)), const Radius.circular(4)), Paint()..color = const Color(0x44000000));
    c.drawRRect(RRect.fromRectAndRadius(t, const Radius.circular(4)), Paint()..shader = const LinearGradient(colors: [Color(0xFF8C9A8A), Color(0xFF657363)]).createShader(t));
    // Cooling fins.
    final fin = Paint()..color = const Color(0x55222A22);
    for (var x = t.left + 10; x < t.right - 6; x += 9) {
      c.drawRect(Rect.fromLTWH(x, t.top + 14, 3, t.height - 22), fin);
    }
    // The lid and the HT bushings (brown porcelain).
    c.drawRect(Rect.fromLTRB(t.left - 4, t.top - 4, t.right + 4, t.top + 4), Paint()..color = const Color(0xFF55604F));
    for (final b in geo.bushings) {
      for (var i = 0; i < 3; i++) {
        c.drawOval(Rect.fromCenter(center: b + Offset(0, 6.0 + i * 5), width: 12 - i * 1.0, height: 5), Paint()..color = const Color(0xFF8B4A2B));
      }
      c.drawRect(Rect.fromCenter(center: b, width: 3, height: 6), Paint()..color = const Color(0xFFB0B0A8));
    }
    // LT side bushings (small, white) and the LT cable down.
    for (final x in [t.left + 18, t.left + 40, t.left + 62, t.left + 84]) {
      c.drawRect(Rect.fromLTWH(x - 2, t.top - 10, 4, 7), Paint()..color = const Color(0xFFE9E7DF));
    }
  }

  void _plate(Canvas c) {
    final g = geo.groundY;
    final r = Rect.fromCenter(center: Offset(M3LaPatrolGeo.leftPoleX + 0.5, g - 150), width: 40, height: 26);
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), Paint()..color = const Color(0xFF1E4F8C));
    c.drawRRect(RRect.fromRectAndRadius(r.deflate(1.5), const Radius.circular(2)), Paint()
      ..color = const Color(0xFFEFF3F8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);
    _label(c, 'DTR', r.center + const Offset(0, -6), 8, const Color(0xFFEFF3F8));
    _label(c, enDigits(dtrNo.toString().padLeft(2, '0')), r.center + const Offset(0, 5), 10, const Color(0xFFFFE27A));
  }

  // --- the arresters and their leads ---------------------------------------
  static final _leadPaint = Paint()
    ..color = const Color(0xFF2E3338)
    ..strokeWidth = 3.2
    ..style = PaintingStyle.stroke
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  static Path _poly(List<Offset> pts) {
    final p = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final q in pts.skip(1)) {
      p.lineTo(q.dx, q.dy);
    }
    return p;
  }

  void _clip(Canvas c, Offset at) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: at, width: 9, height: 4), const Radius.circular(1.5)), Paint()..color = const Color(0xFF5E646B));
  }

  void _leadOf(Canvas c, M3LaPatrolPhase p) {
    final pts = geo.lead(p);
    final g = geo.groundY;
    final x = M3LaPatrolGeo.runX(p);
    if (_is(p, M3LaPatrolFault.dropped)) {
      // Clipped from the clip down; above it, the lead hangs loose.
      final a = geo.dropClip(p);
      c.drawPath(_poly([a, pts[3], pts[4]]), _leadPaint);
      c.drawPath(_poly(geo.dropPath(p)), _leadPaint);
      // The blown disconnector's lower piece on the loose end (sooty).
      final e = geo.dropEnd(p);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: e + const Offset(0, 4), width: 9, height: 11), const Radius.circular(2)), Paint()..color = const Color(0xFF2A2725));
      c.drawCircle(e + const Offset(0, 9), 3, Paint()..color = const Color(0xFF111111));
      for (var y = g - 160.0; y < g - 20; y += 48) {
        _clip(c, Offset(x, y));
      }
      return;
    }
    if (_is(p, M3LaPatrolFault.leadCut)) {
      final top = geo.cutTop(p);
      final bot = geo.cutBottom(p);
      c.drawPath(_poly([pts[0], pts[1], pts[2], Offset(x, top.dy - 14), top]), _leadPaint);
      c.drawPath(_poly([bot, pts[3], pts[4]]), _leadPaint);
      // Frayed strands at both ends.
      final fray = Paint()
        ..color = const Color(0xFFB8BEC4)
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round;
      for (final (dx, dy) in [(-3.0, 5.0), (0.0, 6.0), (3.0, 4.5)]) {
        c.drawLine(top, top + Offset(dx, dy), fray);
        c.drawLine(bot, bot + Offset(dx, -dy), fray);
      }
    } else {
      c.drawPath(_poly(pts), _leadPaint);
    }
    for (var y = g - 210.0; y < g - 20; y += 48) {
      if (_is(p, M3LaPatrolFault.leadCut) && y > g - 100 && y < g - 30) continue;
      _clip(c, Offset(x, y));
    }
  }

  void _arrester(Canvas c, M3LaPatrolPhase p) {
    final x = M3LaPatrolGeo.laX(p);
    final top = geo.laTop;
    final base = geo.laChannelY;
    final porcelain = body == M3LaPatrolBody.porcelain;
    final burst = _is(p, M3LaPatrolFault.burst);
    // The jumper from the line down to the LA's top terminal.
    c.drawLine(Offset(x, geo.lineY + 2), Offset(x, burst ? top + 4 : top), Paint()
      ..color = const Color(0xFF30363D)
      ..strokeWidth = 1.6);
    // Mounting bracket on the LA channel.
    c.drawRect(Rect.fromLTWH(x - 10, base - 4, 20, 5), Paint()..color = const Color(0xFF6D747C));
    // The disconnector under the channel.
    final dis = Rect.fromLTWH(x - 5, base + 2, 10, 14);
    if (_is(p, M3LaPatrolFault.dropped)) {
      // Blown: only the upper half left, black with soot.
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 5, base + 2, 10, 7), const Radius.circular(2)), Paint()..color = const Color(0xFF1A1715));
      c.drawCircle(Offset(x, base + 10), 7, Paint()..color = const Color(0x55000000));
    } else {
      c.drawRRect(RRect.fromRectAndRadius(dis, const Radius.circular(2)), Paint()..color = const Color(0xFF3B3F45));
      c.drawRect(Rect.fromLTWH(x - 5, base + 7, 10, 2), Paint()..color = const Color(0xFF6E737A));
    }
    // The body.
    final coreW = porcelain ? 14.0 : 11.0;
    final shedW = porcelain ? 28.0 : 26.0;
    final sheds = porcelain ? 5 : 7;
    final bodyTop = top + 6;
    final bodyBot = base - 5;
    final glaze = porcelain ? const [Color(0xFFB0643A), Color(0xFF7A3A1C)] : const [Color(0xFF9EA4AA), Color(0xFF6A7177)];
    final shedC = porcelain ? const Color(0xFF94502C) : const Color(0xFF81888E);
    final shedHi = porcelain ? const Color(0xFFC8784A) : const Color(0xFFB9BEC3);
    final cut = burst ? bodyBot - (bodyBot - bodyTop) * 0.38 : bodyTop;
    final core = Rect.fromLTRB(x - coreW / 2, cut, x + coreW / 2, bodyBot);
    c.drawRect(core, Paint()..shader = LinearGradient(colors: glaze).createShader(core));
    final step = (bodyBot - bodyTop - 6) / (sheds - 1);
    for (var i = 0; i < sheds; i++) {
      final y = bodyTop + 3 + i * step;
      if (y < cut) continue;
      final r = Rect.fromCenter(center: Offset(x, y), width: shedW, height: porcelain ? 7 : 5);
      c.drawOval(r, Paint()..color = shedC);
      c.drawOval(Rect.fromLTWH(r.left + 3, r.top, r.width - 8, 2.2), Paint()..color = shedHi);
    }
    // Metal caps.
    final cap = Paint()..color = const Color(0xFF9A9FA5);
    c.drawRect(Rect.fromLTWH(x - 8, bodyBot, 16, 4), cap);
    if (!burst) {
      c.drawRect(Rect.fromLTWH(x - 8, top, 16, 6), cap);
      c.drawCircle(Offset(x, top - 1), 2.5, Paint()..color = const Color(0xFFC9CDD1));
    }

    if (_is(p, M3LaPatrolFault.cracked)) {
      // A jagged crack through the glaze, and a chipped shed.
      final crack = Path()
        ..moveTo(x - 6, bodyTop + 6)
        ..lineTo(x + 2, bodyTop + 16)
        ..lineTo(x - 3, bodyTop + 24)
        ..lineTo(x + 5, bodyTop + 34)
        ..lineTo(x - 1, bodyTop + 42)
        ..lineTo(x + 6, bodyTop + 50);
      c.drawPath(
          crack,
          Paint()
            ..color = const Color(0xFF140A05)
            ..strokeWidth = 2.2
            ..style = PaintingStyle.stroke
            ..strokeJoin = StrokeJoin.miter);
      c.drawPath(
          crack.shift(const Offset(1.2, 0)),
          Paint()
            ..color = const Color(0x66FFE2C8)
            ..strokeWidth = 0.8
            ..style = PaintingStyle.stroke);
      final chipY = bodyTop + 3 + 2 * step;
      c.drawPath(
          Path()
            ..moveTo(x + shedW / 2 - 9, chipY - 3)
            ..lineTo(x + shedW / 2 + 0.5, chipY - 1)
            ..lineTo(x + shedW / 2 - 2, chipY + 4)
            ..close(),
          Paint()..color = const Color(0xFFE7D9C6));
    }
    if (_is(p, M3LaPatrolFault.burnt)) {
      // Black flashover streaks down the housing.
      final soot = Paint()
        ..color = const Color(0xDD15110E)
        ..strokeWidth = 3.4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      c.drawPath(
          Path()
            ..moveTo(x - 4, bodyTop + 2)
            ..quadraticBezierTo(x + 6, bodyTop + 22, x - 2, bodyTop + 36)
            ..quadraticBezierTo(x - 8, bodyTop + 48, x + 3, bodyBot - 2),
          soot);
      c.drawPath(
          Path()
            ..moveTo(x + 5, bodyTop + 10)
            ..quadraticBezierTo(x + 9, bodyTop + 30, x + 6, bodyTop + 44),
          soot..strokeWidth = 2.2);
      c.drawOval(Rect.fromCenter(center: Offset(x, bodyTop + 6), width: shedW + 4, height: 12), Paint()..color = const Color(0x66000000));
    }
    if (burst) {
      // Shattered: a jagged stump, the top cap hanging from the jumper, soot,
      // and pieces fallen on the platform.
      final jag = Path()..moveTo(x - coreW / 2 - 1, cut + 2);
      for (var i = 0; i <= 6; i++) {
        jag.lineTo(x - coreW / 2 + i * coreW / 6, cut + (i.isEven ? -5 : 3));
      }
      jag
        ..lineTo(x + coreW / 2 + 1, cut + 4)
        ..close();
      c.drawPath(jag, Paint()..color = glaze.last);
      c.drawCircle(Offset(x, cut - 4), 10, Paint()..color = const Color(0x66000000));
      c.drawRect(Rect.fromLTWH(x - 7, top + 4, 14, 5), cap);
      final shard = Paint()..color = porcelain ? const Color(0xFF8E4A26) : const Color(0xFF7A8187);
      final g = geo.groundY;
      for (final (dx, dy, a) in [(-10.0, 0.0, 0.4), (6.0, 2.0, -0.6), (16.0, -1.0, 1.1), (-22.0, 1.0, -0.2)]) {
        c.save();
        c.translate(x + dx, geo.platformY - 1 + dy);
        c.rotate(a);
        c.drawPath(
            Path()
              ..moveTo(-4, 0)
              ..lineTo(3, -3)
              ..lineTo(5, 2)
              ..close(),
            shard);
        c.restore();
      }
      for (final (dx, a) in [(-30.0, 0.8), (14.0, -0.3), (40.0, 0.2)]) {
        c.save();
        c.translate(x + dx, g + 10);
        c.rotate(a);
        c.drawPath(
            Path()
              ..moveTo(-5, 0)
              ..lineTo(4, -4)
              ..lineTo(6, 3)
              ..close(),
            shard);
        c.restore();
      }
    }
  }

  static void _label(Canvas c, String t, Offset centre, double size, Color col) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: TextStyle(fontFamily: 'Roboto', fontSize: size, fontWeight: FontWeight.w900, color: col, letterSpacing: 0.4)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(M3LaPatrolWorldPainter old) => old.geo != geo || old.dtrNo != dtrNo || old.body != body || old.fault != fault || old.phase != phase;
}

/// The trainee's marks on the scene: a red ring where he pointed, an amber
/// ring on the fault he missed.
class M3LaPatrolMarkPainter extends CustomPainter {
  const M3LaPatrolMarkPainter({this.mark, this.reveal, this.v = 1});
  final Offset? mark;
  final Offset? reveal;

  /// 0 → 1 as the ring draws.
  final double v;

  @override
  void paint(Canvas c, Size size) {
    void ring(Offset at, Color col) {
      final r = Rect.fromCircle(center: at, radius: 24);
      c.drawCircle(at, 24, Paint()..color = col.withValues(alpha: 0.16));
      c.drawArc(
          r,
          -math.pi / 2,
          math.pi * 2 * v.clamp(0.0, 1.0),
          false,
          Paint()
            ..color = col
            ..strokeWidth = 3.4
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round);
    }

    if (reveal != null) ring(reveal!, const Color(0xFFFFB020));
    if (mark != null) ring(mark!, const Color(0xFFE5392B));
  }

  @override
  bool shouldRepaint(M3LaPatrolMarkPainter old) => old.mark != mark || old.reveal != reveal || old.v != v;
}

/// The deadly moment: the arc from the lead to the hand, in colour.
class M3LaPatrolZapPainter extends CustomPainter {
  const M3LaPatrolZapPainter({required this.from, required this.to, required this.v});
  final Offset from;
  final Offset to;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final flick = v < 0.5 ? (0.65 + 0.35 * math.sin(v * 60).abs()) : (1 - (v - 0.5) * 1.2).clamp(0.4, 1.0);
    final r = 26 + 46 * Curves.easeOut.transform(v.clamp(0.0, 1.0));
    c.drawCircle(from, r, Paint()..shader = RadialGradient(colors: [Color.fromRGBO(220, 235, 255, 0.95 * flick), const Color(0x002F6FD0)]).createShader(Rect.fromCircle(center: from, radius: r)));
    final rnd = math.Random(11);
    final arc = Path()..moveTo(from.dx, from.dy);
    for (var i = 1; i < 8; i++) {
      final t = i / 8;
      final p = Offset.lerp(from, to, t)!;
      arc.lineTo(p.dx + (rnd.nextDouble() - 0.5) * 16, p.dy + (rnd.nextDouble() - 0.5) * 8);
    }
    arc.lineTo(to.dx, to.dy);
    c.drawPath(
        arc,
        Paint()
          ..color = Color.fromRGBO(255, 255, 255, flick)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke);
    c.drawCircle(to, 14 + 10 * v, Paint()..color = Color.fromRGBO(255, 230, 140, 0.6 * flick));
    final spark = Paint()
      ..color = Color.fromRGBO(255, 214, 90, (1 - v).clamp(0.0, 1.0))
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 14; i++) {
      final a = i / 14 * math.pi * 2 + 0.3;
      final d0 = 10 + 38 * v;
      c.drawLine(from + Offset(math.cos(a) * d0, math.sin(a) * d0), from + Offset(math.cos(a) * (d0 + 12), math.sin(a) * (d0 + 12)), spark);
    }
    final white = (1 - v * 4).clamp(0.0, 1.0);
    if (white > 0) c.drawRect(Offset.zero & size, Paint()..color = Color.fromRGBO(255, 255, 255, 0.8 * white));
  }

  @override
  bool shouldRepaint(M3LaPatrolZapPainter old) => old.v != v || old.from != from || old.to != to;
}
