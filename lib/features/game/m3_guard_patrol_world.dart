import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The crossing on patrol (lesson 3.9 "গার্ড ওয়্যার ও ক্রেডল গার্ডিং", কাজ 1): a
// drawn, layered place — the day sky, a far tree line and village roofs, the
// crossing under the line (a road, a railway or a telecom line, running away
// into the distance), and the hero: an 11 kV-style line on two PCC poles, one
// each side of the crossing, with the cradle guard (a GI net — longitudinal
// wires laced crosswise) hung under the conductors, and the guard's earth lead
// down each pole into its pipe. The only marks in the art are the ones a
// worker would see; the faults are drawn into the equipment (no labels).
//
// Design: 360 wide × the scene's height; the ground row follows the bottom of
// the screen (a tall phone gets more sky).

/// What the line crosses this round (lesson point 1: roads, railways,
/// telecom lines).
enum M3GuardPatrolCrossing { road, rail, telecom }

/// Where a fault can be: the guard's earth at each pole, or a third of the
/// guard span.
enum M3GuardPatrolSpot { earthL, earthR, spanL, spanM, spanR }

/// What can be wrong (lesson point 4, pro tips 1 and 4).
enum M3GuardPatrolFault {
  /// The earth lead stolen: cut off, the pipe empty.
  earthGone,

  /// The earth lead run down the pole outside its pipe.
  earthBare,

  /// The galvanising gone: the GI wire rusty.
  rust,

  /// A guard wire snapped, its end hanging down.
  broken,

  /// The guard sagging / slack.
  sag,

  /// The live conductor too close above the guard (vertical clearance).
  gap,
}

bool m3GuardPatrolIsEarth(M3GuardPatrolSpot s) => s == M3GuardPatrolSpot.earthL || s == M3GuardPatrolSpot.earthR;

/// Where things stand (design px, 360 wide).
@immutable
class M3GuardPatrolGeo {
  const M3GuardPatrolGeo({required this.height, required this.groundY});

  factory M3GuardPatrolGeo.forScene(double h, double inset) => M3GuardPatrolGeo(height: h, groundY: (h - 260 - inset).clamp(380.0, 720.0));

  final double height;
  final double groundY;

  double get horizonY => groundY - 150;

  static const poleLX = 34.0;
  static const poleRX = 326.0;

  double get poleTop => groundY - 420;

  /// The line's cross-arm (conductors on its pins).
  double get lineY => groundY - 384;

  /// The guard's arm and the top of the net; the net's lower edge.
  double get guardY => groundY - 312;
  double get guardLowY => guardY + 26;

  /// The span's thirds.
  static const _spanX = {
    M3GuardPatrolSpot.spanL: (52.0, 136.0),
    M3GuardPatrolSpot.spanM: (136.0, 224.0),
    M3GuardPatrolSpot.spanR: (224.0, 308.0),
  };

  (double, double) spanX(M3GuardPatrolSpot s) => _spanX[s] ?? (136.0, 224.0);

  double poleX(M3GuardPatrolSpot s) => s == M3GuardPatrolSpot.earthL ? poleLX : poleRX;

  /// Where a tap reaches a spot (≥ 48 design px each way).
  Rect hit(M3GuardPatrolSpot s) {
    if (m3GuardPatrolIsEarth(s)) {
      final x = poleX(s);
      final inward = s == M3GuardPatrolSpot.earthL ? 1.0 : -1.0;
      return Rect.fromCenter(center: Offset(x + inward * 4, groundY - 100), width: 60, height: 220);
    }
    final (a, b) = spanX(s);
    return Rect.fromLTRB(a, lineY + 14, b, guardLowY + 70);
  }

  /// A snapped wire's hanging end in [s]: from the net down to head height.
  (Offset, Offset) dangle(M3GuardPatrolSpot s) {
    final (a, b) = spanX(s);
    final x = (a + b) / 2;
    return (Offset(x - 2, guardY + 4), Offset(x + 10, groundY - 150));
  }

  Rect dangleHit(M3GuardPatrolSpot s) {
    final (top, end) = dangle(s);
    return Rect.fromLTRB(math.min(top.dx, end.dx) - 24, top.dy, math.max(top.dx, end.dx) + 24, end.dy + 14);
  }

  /// Where a spot's tag (the trainee's red mark) sits.
  Offset tagAt(M3GuardPatrolSpot s) {
    if (m3GuardPatrolIsEarth(s)) {
      final x = poleX(s);
      return Offset(s == M3GuardPatrolSpot.earthL ? x + 22 : x - 22, groundY - 128);
    }
    final (a, b) = spanX(s);
    return Offset((a + b) / 2 - 22, guardLowY + 38);
  }

  /// The trainee's box (feet on the near verge, by the left pole).
  Rect get trainee => Rect.fromLTWH(70, groundY + 44 - 208, 104, 208);

  /// The trainee under a hanging wire end (he reached for it).
  Rect traineeAt(M3GuardPatrolSpot s) {
    final (_, end) = dangle(s);
    return Rect.fromLTWH((end.dx - 64).clamp(4.0, 252.0), end.dy - 12, 104, 208);
  }

  @override
  bool operator ==(Object other) => other is M3GuardPatrolGeo && other.height == height && other.groundY == groundY;

  @override
  int get hashCode => Object.hash(height, groundY);
}

/// The sky, the land, the crossing, the poles, the line, the cradle guard and
/// its earths, with this round's faults drawn in and the trainee's tags.
class M3GuardPatrolWorldPainter extends CustomPainter {
  const M3GuardPatrolWorldPainter({required this.geo, required this.crossing, required this.faults, this.tags = const {}});

  final M3GuardPatrolGeo geo;
  final M3GuardPatrolCrossing crossing;
  final Map<M3GuardPatrolSpot, M3GuardPatrolFault> faults;
  final Set<M3GuardPatrolSpot> tags;

  M3GuardPatrolSpot? _where(M3GuardPatrolFault f) {
    for (final e in faults.entries) {
      if (e.value == f) return e.key;
    }
    return null;
  }

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final g = geo.groundY;
    final hz = geo.horizonY;
    // Sky (clear day).
    final sky = Rect.fromLTWH(0, 0, w, hz + 4);
    c.drawRect(sky, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3F79B5), Color(0xFF8DBBE0), Color(0xFFE6F0E8)]).createShader(sky));
    c.drawCircle(Offset(286, hz - 96), 22, Paint()..color = const Color(0x88FFF6D2));
    final cloud = Paint()..color = const Color(0x66FFFFFF);
    for (final (x, y, r) in [(70.0, hz - 60, 18.0), (94.0, hz - 66, 24.0), (122.0, hz - 58, 16.0), (232.0, hz - 120, 14.0), (254.0, hz - 126, 19.0)]) {
      c.drawCircle(Offset(x, y), r, cloud);
    }
    // Far tree line and roofs.
    final far = Path()..moveTo(0, hz);
    for (var x = 0.0; x <= w; x += 16) {
      far.lineTo(x, hz - 14 - 9 * math.sin(x * 0.08) - 5 * math.cos(x * 0.21));
    }
    far
      ..lineTo(w, hz + 2)
      ..lineTo(0, hz + 2)
      ..close();
    c.drawPath(far, Paint()..color = const Color(0xFF557F58));
    final roof = Paint()..color = const Color(0xFF8A4B36);
    final wall = Paint()..color = const Color(0xFFDCCBA8);
    for (final x in [16.0, 268.0, 318.0]) {
      c.drawRect(Rect.fromLTWH(x, hz - 13, 24, 13), wall);
      c.drawPath(
          Path()
            ..moveTo(x - 3, hz - 13)
            ..lineTo(x + 12, hz - 24)
            ..lineTo(x + 27, hz - 13)
            ..close(),
          roof);
    }
    // Fields to the bottom.
    final field = Rect.fromLTWH(0, hz, w, size.height - hz);
    c.drawRect(field, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8DAE62), Color(0xFF5F8443)]).createShader(field));
    switch (crossing) {
      case M3GuardPatrolCrossing.road:
        _road(c, size);
      case M3GuardPatrolCrossing.rail:
        _rail(c, size);
      case M3GuardPatrolCrossing.telecom:
        _telecom(c, size);
    }
    // The near verge the poles stand on.
    c.drawRect(Rect.fromLTWH(0, g - 3, 64, 7), Paint()..color = const Color(0x33402A10));
    c.drawRect(Rect.fromLTWH(w - 64, g - 3, 64, 7), Paint()..color = const Color(0x33402A10));

    _conductors(c, size);
    _pole(c, M3GuardPatrolGeo.poleLX);
    _pole(c, M3GuardPatrolGeo.poleRX);
    _earth(c, M3GuardPatrolSpot.earthL);
    _earth(c, M3GuardPatrolSpot.earthR);
    _guard(c);
    for (final s in tags) {
      _tag(c, geo.tagAt(s));
    }
  }

  // --- the crossing ---------------------------------------------------------
  /// The crossing's strip from the horizon (narrow) to the bottom (wide).
  Path _strip(Size size, double farHalf, double nearHalf) {
    const cx = 180.0;
    final hz = geo.horizonY;
    return Path()
      ..moveTo(cx - farHalf, hz)
      ..lineTo(cx + farHalf, hz)
      ..lineTo(cx + nearHalf, size.height)
      ..lineTo(cx - nearHalf, size.height)
      ..close();
  }

  double _xAt(double y, double farHalf, double nearHalf, double side, Size size) {
    final t = ((y - geo.horizonY) / (size.height - geo.horizonY)).clamp(0.0, 1.0);
    return 180 + side * (farHalf + (nearHalf - farHalf) * t);
  }

  void _road(Canvas c, Size size) {
    c.drawPath(_strip(size, 12, 130), Paint()..color = const Color(0xFF55595E));
    final edge = Paint()
      ..color = const Color(0xFFE9E6DA)
      ..strokeWidth = 2.2;
    final hz = geo.horizonY;
    for (final side in [-1.0, 1.0]) {
      c.drawLine(Offset(_xAt(hz, 11, 122, side, size), hz), Offset(_xAt(size.height, 11, 122, side, size), size.height), edge);
    }
    // Centre dashes (longer near).
    final dash = Paint()..color = const Color(0xFFF2D04A);
    for (var t = 0.06; t < 1; t *= 1.55) {
      final y0 = hz + (size.height - hz) * t;
      final y1 = y0 + 4 + 26 * t;
      c.drawRect(Rect.fromLTRB(180 - 0.6 - 2.4 * t, y0, 180 + 0.6 + 2.4 * t, math.min(y1, size.height)), dash);
    }
    // A bus far down the road.
    final by = hz + 26;
    final bus = Rect.fromLTWH(186, by - 20, 26, 20);
    c.drawRRect(RRect.fromRectAndRadius(bus, const Radius.circular(3)), Paint()..color = const Color(0xFFD9822B));
    c.drawRect(Rect.fromLTWH(bus.left + 3, bus.top + 3, bus.width - 6, 7), Paint()..color = const Color(0xFF2E4A5E));
    c.drawCircle(Offset(bus.left + 6, bus.bottom), 2.6, Paint()..color = const Color(0xFF1A1A1A));
    c.drawCircle(Offset(bus.right - 6, bus.bottom), 2.6, Paint()..color = const Color(0xFF1A1A1A));
  }

  void _rail(Canvas c, Size size) {
    c.drawPath(_strip(size, 16, 132), Paint()..color = const Color(0xFF8A8173));
    final hz = geo.horizonY;
    final sleeper = Paint()..color = const Color(0xFF5E4630);
    for (var t = 0.03; t < 1; t *= 1.22) {
      final y = hz + (size.height - hz) * t;
      final hw = 10 + 92 * t;
      c.drawRect(Rect.fromLTRB(180 - hw, y, 180 + hw, y + 1.5 + 9 * t), sleeper);
    }
    final rail = Paint()
      ..color = const Color(0xFFC9CDD2)
      ..strokeWidth = 2.6;
    for (final side in [-1.0, 1.0]) {
      c.drawLine(Offset(_xAt(hz, 5, 66, side, size), hz), Offset(_xAt(size.height, 5, 66, side, size), size.height), rail);
    }
  }

  void _telecom(Canvas c, Size size) {
    // A dirt path along the telecom line.
    c.drawPath(_strip(size, 10, 80), Paint()..color = const Color(0xFFB59B74));
    final hz = geo.horizonY;
    // Telecom poles running away (smaller far), their wires low under the guard.
    final pole = Paint()..color = const Color(0xFF6B5A44);
    final tops = <Offset>[];
    for (final t in [0.03, 0.09, 0.2, 0.42]) {
      final y = hz + (size.height - hz) * t;
      final x = _xAt(y, 18, 110, 1, size);
      final hgt = 18 + 230 * t;
      c.drawRect(Rect.fromLTRB(x - 1 - 3 * t, y - hgt, x + 1 + 3 * t, y), pole);
      c.drawRect(Rect.fromLTRB(x - 4 - 16 * t, y - hgt + 2, x + 4 + 16 * t, y - hgt + 3 + 4 * t), pole);
      tops.add(Offset(x, y - hgt + 3));
    }
    final wire = Paint()
      ..color = const Color(0xFF26292D)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;
    for (final dx in [-0.8, 0.8]) {
      final p = Path()..moveTo(tops.first.dx, tops.first.dy);
      for (final t in tops.skip(1)) {
        final s = (t.dy - hz) / (size.height - hz);
        p.lineTo(t.dx + dx * 14 * s, t.dy);
      }
      p.lineTo(size.width + 40, size.height * 0.98 - 60);
      c.drawPath(p, wire);
    }
  }

  // --- the line, the poles ---------------------------------------------------
  void _conductors(Canvas c, Size size) {
    final gap = _where(M3GuardPatrolFault.gap) != null;
    final wire = Paint()
      ..color = const Color(0xFF2A2F36)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    const l = M3GuardPatrolGeo.poleLX, r = M3GuardPatrolGeo.poleRX;
    for (final (i, dy) in const [-14.0, -2.0, 4.0].indexed) {
      final y = geo.lineY + dy;
      // Normal sag; with the gap fault the conductors hang far down mid-span.
      final sag = gap ? (geo.guardY - 12 - y) * (0.95 - 0.12 * i) : 12.0;
      c.drawPath(
          Path()
            ..moveTo(-20, y + 10)
            ..quadraticBezierTo(l / 2 - 10, y + 12, l, y)
            ..quadraticBezierTo(180, y + 2 * sag, r, y)
            ..quadraticBezierTo(r + 20, y + 6, size.width + 20, y + 10),
          wire);
    }
  }

  void _pole(Canvas c, double px) {
    final g = geo.groundY;
    final top = geo.poleTop;
    final pole = Path()
      ..moveTo(px - 6, top)
      ..lineTo(px + 6, top)
      ..lineTo(px + 10, g + 4)
      ..lineTo(px - 10, g + 4)
      ..close();
    c.drawPath(pole, Paint()..shader = const LinearGradient(colors: [Color(0xFFBDBDB6), Color(0xFF8D8D86)]).createShader(Rect.fromLTRB(px - 10, top, px + 10, g)));
    // Line cross-arm with three pin insulators.
    final arm = Paint()..color = const Color(0xFF4A4F57);
    c.drawRect(Rect.fromLTWH(px - 26, geo.lineY - 2, 52, 5), arm);
    final pin = Paint()..color = const Color(0xFFF2F0E8);
    for (final (dx, dy) in [(0.0, -14.0), (-18.0, -2.0), (18.0, 4.0)]) {
      final top2 = geo.lineY + dy - 6;
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(px + dx - 4, top2, 8, dy < -10 ? 10 : 6), const Radius.circular(2)), pin);
    }
    c.drawRect(Rect.fromLTWH(px - 3, geo.lineY - 22, 6, 20), arm);
    // The guard arm.
    c.drawRect(Rect.fromLTWH(px - 22, geo.guardY - 2, 44, 4), Paint()..color = const Color(0xFF7D848C));
    // A danger plate.
    final plate = Rect.fromLTWH(px - 7, g - 236, 14, 16);
    c.drawRect(plate, Paint()..color = const Color(0xFFF2F0E8));
    c.drawPath(
        Path()
          ..moveTo(plate.center.dx + 1, plate.top + 3)
          ..lineTo(plate.center.dx - 3, plate.center.dy + 1)
          ..lineTo(plate.center.dx + 1, plate.center.dy + 1)
          ..lineTo(plate.center.dx - 1, plate.bottom - 3),
        Paint()
          ..color = const Color(0xFFD83A2E)
          ..strokeWidth = 1.6
          ..style = PaintingStyle.stroke);
    c.drawOval(Rect.fromCenter(center: Offset(px, g + 4), width: 40, height: 7), Paint()..color = const Color(0x33000000));
  }

  /// The guard's earth lead down the pole: healthy (into its pipe), stolen
  /// (cut, the pipe empty) or bare (no pipe).
  void _earth(Canvas c, M3GuardPatrolSpot s) {
    final f = faults[s];
    final g = geo.groundY;
    final px = geo.poleX(s);
    final side = s == M3GuardPatrolSpot.earthL ? 1.0 : -1.0;
    final x = px + side * 14;
    final pipeTop = g - 96;
    final lead = Paint()
      ..color = const Color(0xFF3A4248)
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke;
    final arm = Offset(px + side * 20, geo.guardY + 1);
    // From the guard arm to the pole, then down it.
    final cutY = g - 196.0;
    final endY = f == M3GuardPatrolFault.earthGone ? cutY : (f == M3GuardPatrolFault.earthBare ? g + 2 : pipeTop + 4);
    c.drawPath(
        Path()
          ..moveTo(arm.dx, arm.dy)
          ..quadraticBezierTo(x + side * 6, geo.guardY + 14, x, geo.guardY + 30)
          ..lineTo(x, endY),
        lead);
    // Clamps on the pole.
    final clamp = Paint()..color = const Color(0xFF2A2F33);
    for (var y = geo.guardY + 60; y < endY - 6; y += 46) {
      c.drawRect(Rect.fromLTRB(math.min(x, px) - 2, y, math.max(x, px) + 2, y + 3), clamp);
    }
    if (f == M3GuardPatrolFault.earthGone) {
      // The cut end, frayed.
      final fray = Paint()
        ..color = const Color(0xFFC08A4A)
        ..strokeWidth = 1.4;
      for (final dx in [-3.0, 0.0, 3.0]) {
        c.drawLine(Offset(x, cutY), Offset(x + dx, cutY + 7), fray);
      }
      // Bare clamps left where the lead went, lower down.
      for (final y in [g - 150, g - 112]) {
        c.drawRect(Rect.fromLTRB(math.min(x, px) - 2, y, math.max(x, px) + 2, y + 3), clamp);
      }
    }
    if (f != M3GuardPatrolFault.earthBare) {
      // The GI pipe up the pole's foot.
      final pipe = Rect.fromLTRB(x - 5, pipeTop, x + 5, g + 3);
      c.drawRect(pipe, Paint()..shader = const LinearGradient(colors: [Color(0xFFE3E8EC), Color(0xFF8E979E)]).createShader(pipe));
      c.drawRect(pipe, Paint()
        ..color = const Color(0xFF3A4248)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2);
      c.drawRect(Rect.fromLTWH(x - 6.5, pipeTop - 2, 13, 4), Paint()..color = const Color(0xFF3A4248));
      c.drawRect(Rect.fromLTRB(math.min(x, px) - 2, pipeTop + 44, math.max(x, px) + 2, pipeTop + 47), clamp);
    }
    // The earth pit cover by the pole.
    final pit = Offset(x + side * 18, g + 8);
    c.drawOval(Rect.fromCenter(center: pit, width: 22, height: 7), Paint()..color = const Color(0xFF6A6E70));
    if (f != M3GuardPatrolFault.earthGone) {
      c.drawLine(Offset(x, g + 2), pit, lead);
    }
  }

  // --- the cradle guard -------------------------------------------------------
  void _guard(Canvas c) {
    const l = M3GuardPatrolGeo.poleLX + 18, r = M3GuardPatrolGeo.poleRX - 18;
    final sagAt = _where(M3GuardPatrolFault.sag);
    final rustAt = _where(M3GuardPatrolFault.rust);
    final brokeAt = _where(M3GuardPatrolFault.broken);

    double base(double x) {
      final t = (x - l) / (r - l);
      return 10 * 4 * t * (1 - t);
    }

    double droop(double x) {
      if (sagAt == null) return 0;
      final (a, b) = geo.spanX(sagAt);
      if (x <= a - 20 || x >= b + 20) return 0;
      final t = ((x - (a - 20)) / (b - a + 40)).clamp(0.0, 1.0);
      return 46 * math.sin(t * math.pi);
    }

    double topY(double x) => geo.guardY + base(x) + 0.5 * droop(x);
    double lowY(double x) => geo.guardLowY + base(x) + droop(x);

    bool inSpan(M3GuardPatrolSpot? s, double x) {
      if (s == null) return false;
      final (a, b) = geo.spanX(s);
      return x >= a && x <= b;
    }

    // The cut in the top wire.
    double? cutX;
    if (brokeAt != null) {
      final (a, b) = geo.spanX(brokeAt);
      cutX = (a + b) / 2;
    }

    const steel = Color(0xFF8E979D);
    const rusty = Color(0xFF9A5426);
    Paint wire(double x, double width) => Paint()
      ..color = inSpan(rustAt, x) ? rusty : steel
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;

    // Longitudinal wires, segment by segment (colour per span).
    for (var x = l; x < r; x += 4) {
      final x2 = math.min(r, x + 4);
      final skipTop = cutX != null && x2 > cutX - 5 && x < cutX + 5;
      if (!skipTop) c.drawLine(Offset(x, topY(x)), Offset(x2, topY(x2)), wire(x, 1.6));
      c.drawLine(Offset(x, lowY(x)), Offset(x2, lowY(x2)), wire(x, 1.6));
      c.drawLine(Offset(x, (topY(x) + lowY(x)) / 2 + 3), Offset(x2, (topY(x2) + lowY(x2)) / 2 + 3), wire(x, 1.1));
    }
    // The cross lacing (a zig-zag "cradle").
    var up = true;
    for (var x = l; x < r - 8; x += 12) {
      final x2 = x + 12;
      final nearCut = cutX != null && (x - cutX).abs() < 18;
      if (!nearCut) {
        c.drawLine(Offset(x, up ? topY(x) : lowY(x)), Offset(x2, up ? lowY(x2) : topY(x2)), wire(x, 1.1));
      }
      up = !up;
    }
    // Rust blotches.
    if (rustAt != null) {
      final (a, b) = geo.spanX(rustAt);
      final rnd = math.Random(5);
      final blot = Paint()..color = const Color(0xCCB4581C);
      for (var i = 0; i < 9; i++) {
        final x = a + 8 + rnd.nextDouble() * (b - a - 16);
        final y = rnd.nextBool() ? topY(x) : lowY(x);
        c.drawOval(Rect.fromCenter(center: Offset(x, y), width: 5 + rnd.nextDouble() * 4, height: 3.4), blot);
      }
    }
    // The snapped wire: one end curls short, the other hangs down long.
    if (brokeAt != null && cutX != null) {
      final (top, end) = geo.dangle(brokeAt);
      final hang = Paint()
        ..color = inSpan(rustAt, cutX) ? rusty : const Color(0xFF5F686E)
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      c.drawPath(
          Path()
            ..moveTo(cutX - 5, topY(cutX - 5))
            ..cubicTo(top.dx - 4, top.dy + 40, end.dx - 14, end.dy - 60, end.dx, end.dy),
          hang);
      c.drawPath(
          Path()
            ..moveTo(cutX + 5, topY(cutX + 5))
            ..quadraticBezierTo(cutX + 12, topY(cutX) + 14, cutX + 6, topY(cutX) + 22),
          hang);
    }
    // The net's ends tied to the guard arms.
    final tie = Paint()
      ..color = steel
      ..strokeWidth = 1.4;
    for (final (px, x) in [(M3GuardPatrolGeo.poleLX + 20, l), (M3GuardPatrolGeo.poleRX - 20, r)]) {
      c.drawLine(Offset(px, geo.guardY), Offset(x, topY(x)), tie);
      c.drawLine(Offset(px, geo.guardY), Offset(x, lowY(x)), tie);
    }
  }

  /// The trainee's mark on a spot: a red tag on a string.
  void _tag(Canvas c, Offset at) {
    c.drawLine(at + const Offset(0, -14), at + const Offset(0, -4), Paint()
      ..color = const Color(0xFF2A2F36)
      ..strokeWidth = 1.4);
    c.drawCircle(at + const Offset(1.5, 2), 10, Paint()..color = const Color(0x55000000));
    c.drawCircle(at, 10, Paint()..color = const Color(0xFFE23B2E));
    c.drawCircle(at, 10, Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6);
    final mark = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    c.drawLine(at + const Offset(0, -5), at + const Offset(0, 1.5), mark);
    c.drawCircle(at + const Offset(0, 5), 1.5, Paint()..color = const Color(0xFFFFFFFF));
  }

  @override
  bool shouldRepaint(M3GuardPatrolWorldPainter old) =>
      old.geo != geo || old.crossing != crossing || !mapEquals(old.faults, faults) || !setEquals(old.tags, tags);
}

/// The guard alive under his hand (the deadly consequence, in colour over the
/// grey scene): a white flash, a blue-white glow and sparks at the wire's end.
/// Non-graphic.
class M3GuardPatrolZapPainter extends CustomPainter {
  const M3GuardPatrolZapPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final flick = v < 0.5 ? (0.65 + 0.35 * math.sin(v * 60).abs()) : (1 - (v - 0.5) * 1.2).clamp(0.4, 1.0);
    final r = 24 + 44 * Curves.easeOut.transform(v.clamp(0.0, 1.0));
    c.drawCircle(at, r, Paint()..shader = RadialGradient(colors: [Color.fromRGBO(220, 235, 255, 0.95 * flick), const Color(0x002F6FD0)]).createShader(Rect.fromCircle(center: at, radius: r)));
    final rnd = math.Random(11);
    final arc = Path()..moveTo(at.dx, at.dy - 60);
    for (var i = 1; i <= 6; i++) {
      arc.lineTo(at.dx + (rnd.nextDouble() - 0.5) * 16, at.dy - 60 + i * 10);
    }
    c.drawPath(
        arc,
        Paint()
          ..color = Color.fromRGBO(255, 255, 255, flick)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke);
    final spark = Paint()
      ..color = Color.fromRGBO(255, 214, 90, (1 - v).clamp(0.0, 1.0))
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 14; i++) {
      final a = i / 14 * math.pi * 2 + 0.3;
      final d0 = 10 + 36 * v;
      c.drawLine(at + Offset(math.cos(a) * d0, math.sin(a) * d0), at + Offset(math.cos(a) * (d0 + 12), math.sin(a) * (d0 + 12)), spark);
    }
    final white = (1 - v * 4).clamp(0.0, 1.0);
    if (white > 0) c.drawRect(Offset.zero & size, Paint()..color = Color.fromRGBO(255, 255, 255, 0.8 * white));
  }

  @override
  bool shouldRepaint(M3GuardPatrolZapPainter old) => old.v != v || old.at != at;
}
