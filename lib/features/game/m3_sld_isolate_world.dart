import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart' show banglaFont;

// The drawn world of lesson 3.10 কাজ "ম্যাপ দেখে বিচ্ছিন্ন" (m3_sld_isolate.dart):
// a roadside 11kV line in the late morning — sky, the line on its poles going
// away, the van's bonnet — and on the bonnet the field tablet with the area's
// digital single line diagram (SLD), read top (source) → bottom (load): the
// substation's 11kV bus with two feeder breakers (CB), the docket's feeder
// running down through its isolator (AB-1) into the work section (three poles,
// a transformer tap through its DO fuse), and — on a ring — the tie switch
// (AB-2 · NO) across to the other substation's feeder and its breaker.
// Switch states in colour as the lesson's digital SLD shows them (ON red ·
// OFF green). Code-drawn, gradients, no bitmaps. Design space 360 wide.

/// The kinds of network on the docket.
enum M3SldIsolateKind {
  /// One source: the feeder's breaker and isolator.
  radial,

  /// A ring whose tie switch is open (NO) today.
  ringNo,

  /// A ring whose NO tie switch is closed today (shown ON on the SLD).
  ringClosed,
}

/// The switching points on the SLD (and the two traps).
enum M3SldIsolatePoint {
  /// The docket feeder's breaker at the substation.
  cbA,

  /// The docket feeder's isolator above the work section (AB-1).
  abA,

  /// The neighbouring feeder's breaker (the wrong feeder).
  cbX,

  /// The transformer tap's DO fuse (isolates the transformer only).
  doFuse,

  /// The other substation's feeder breaker (ring only).
  cbB,

  /// The ring's tie switch, AB-2 · NO (ring only).
  tie,
}

/// Where things are (design px, 360 wide).
@immutable
class M3SldIsolateGeo {
  const M3SldIsolateGeo._(this.height, this.groundY, this.top, this.flip, this.workLeft);

  /// [top] = the top system inset in design px (the header floats under it).
  factory M3SldIsolateGeo.forScene(double height, double inset, {double top = 0, bool flip = false, bool workLeft = true}) =>
      M3SldIsolateGeo._(height, height - floorUp - inset * 0.5, top, flip, workLeft);

  final double height;
  final double groundY;
  final double top;

  /// Mirror the map (the ring's other substation on the left).
  final bool flip;

  /// The docket feeder is the left one of the two at substation A.
  final bool workLeft;

  static const double floorUp = 96;

  /// The tablet on the van's bonnet.
  Rect get board => Rect.fromLTRB(10, 92 + top, 350, groundY - 4);

  /// The tablet's screen.
  Rect get screen => board.deflate(8);

  /// The docket strip at the top of the screen.
  Rect get docketStrip => Rect.fromLTWH(screen.left + 6, screen.top + 6, screen.width - 12, 40);

  double get _top => screen.top + 82;
  double get _bot => screen.bottom - 112;

  /// A row of the diagram, 0 (the source bus) … 1 (the tie row).
  double y(double f) => _top + f * (_bot - _top);

  double _x(double v) => flip ? 360 - v : v;

  /// Towards the ring's other substation (+1 right, −1 left).
  double get side => flip ? -1 : 1;

  double get workX => _x(workLeft ? 70 : 150);
  double get neighbourX => _x(workLeft ? 150 : 70);
  double get bX => _x(292);

  /// The substation A bus (11kV) and the B bus.
  double get busY => y(0);
  (double, double) get busA => (math.min(_x(40), _x(182)), math.max(_x(40), _x(182)));
  (double, double) get busB => (math.min(_x(262), _x(326)), math.max(_x(262), _x(326)));

  /// The work section between AB-1 and the tie row.
  double get sectionTop => y(0.45);
  double get sectionBottom => y(0.74);
  List<Offset> get poles => [for (final f in [0.50, 0.595, 0.69]) Offset(workX, y(f))];
  Rect get sectionBox => Rect.fromLTRB(workX - 16, sectionTop, workX + 16, sectionBottom);

  /// The transformer tap off the section.
  double get tapY => y(0.595);
  Offset get transformer => Offset(workX + side * 70, tapY);

  /// The end of a radial line (an arrow on to the village).
  double get radialEnd => y(0.92);

  Offset point(M3SldIsolatePoint p) => switch (p) {
        M3SldIsolatePoint.cbA => Offset(workX, y(0.15)),
        M3SldIsolatePoint.abA => Offset(workX, y(0.32)),
        M3SldIsolatePoint.cbX => Offset(neighbourX, y(0.15)),
        M3SldIsolatePoint.doFuse => Offset(workX + side * 36, tapY),
        M3SldIsolatePoint.cbB => Offset(bX, y(0.15)),
        M3SldIsolatePoint.tie => Offset((workX + bX) / 2, y(1)),
      };

  Rect hit(M3SldIsolatePoint p) => Rect.fromCenter(center: point(p), width: 46, height: 46);

  /// The tester's lamp, by the section.
  Offset get testerAt => Offset(workX - side * 14, sectionTop - 4);

  /// The lineman, at the foot of the bonnet (clear of the guide's corner).
  Rect get trainee => Rect.fromLTWH(4, groundY - 112, 56, 112);

  @override
  bool operator ==(Object other) =>
      other is M3SldIsolateGeo && other.height == height && other.groundY == groundY && other.top == top && other.flip == flip && other.workLeft == workLeft;

  @override
  int get hashCode => Object.hash(height, groundY, top, flip, workLeft);
}

/// What the SLD shows now.
@immutable
class M3SldIsolateMap {
  const M3SldIsolateMap({
    required this.kind,
    required this.opened,
    required this.tieTagged,
    required this.earthed,
    required this.dead,
    required this.docketBn,
    required this.feederA,
    required this.feederX,
    required this.feederB,
    required this.firstPole,
  });

  final M3SldIsolateKind kind;
  final Set<M3SldIsolatePoint> opened;
  final bool tieTagged;
  final bool earthed;

  /// The work is on: the section proved dead and earthed.
  final bool dead;
  final String docketBn;
  final String feederA;
  final String feederX;
  final String feederB;
  final int firstPole;

  bool get ring => kind != M3SldIsolateKind.radial;

  /// Is [p] closed (ON) now?
  bool closed(M3SldIsolatePoint p) => switch (p) {
        M3SldIsolatePoint.tie => kind == M3SldIsolateKind.ringClosed && !opened.contains(p),
        _ => !opened.contains(p),
      };

  /// Carries a tag (opened by the player, or the NO tie secured).
  bool tagged(M3SldIsolatePoint p) => p == M3SldIsolatePoint.tie ? (tieTagged || opened.contains(p)) : opened.contains(p);

  @override
  bool operator ==(Object other) =>
      other is M3SldIsolateMap &&
      other.kind == kind &&
      setEquals(other.opened, opened) &&
      other.tieTagged == tieTagged &&
      other.earthed == earthed &&
      other.dead == dead &&
      other.docketBn == docketBn &&
      other.feederA == feederA &&
      other.feederX == feederX &&
      other.feederB == feederB &&
      other.firstPole == firstPole;

  @override
  int get hashCode => Object.hash(kind, Object.hashAllUnordered(opened), tieTagged, earthed, dead, docketBn, feederA, feederX, feederB, firstPole);
}

const _on = Color(0xFFE5484D);
const _off = Color(0xFF34C77B);
const _ink = Color(0xFFC9D4E0);
const _dim = Color(0xFF7E8DA0);
const _amber = Color(0xFFF5B83D);

/// The roadside, the van's bonnet and the tablet with the SLD.
class M3SldIsolatePainter extends CustomPainter {
  const M3SldIsolatePainter({required this.geo, required this.map, required this.seed});

  final M3SldIsolateGeo geo;
  final M3SldIsolateMap map;
  final int seed;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    // Sky and the far fields.
    c.drawRect(
        Rect.fromLTWH(0, 0, w, g.groundY),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4F86C6), Color(0xFFA9CBE6), Color(0xFFDDE8D2)],
          ).createShader(Rect.fromLTWH(0, 0, w, g.groundY)));
    final rnd = math.Random(seed);
    final tree = Paint()..color = const Color(0xFF3F6E3C);
    final horizon = g.groundY - 30;
    for (var x = -10.0; x < w + 20; x += 20 + rnd.nextDouble() * 20) {
      final r = 9 + rnd.nextDouble() * 10;
      c.drawCircle(Offset(x, horizon - r * 0.5), r, tree);
    }
    // The 11kV line on its poles going away (behind the tablet, seen at its edges).
    final pole = Paint()
      ..color = const Color(0xFF6D747C)
      ..strokeWidth = 3;
    final wire = Paint()
      ..color = const Color(0xAA2B3138)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (final (x, top, bottom) in [(26.0, 30.0, horizon), (338.0, 46.0, horizon)]) {
      c.drawLine(Offset(x, top), Offset(x, bottom), pole);
      c.drawLine(Offset(x - 12, top + 6), Offset(x + 12, top + 6), pole..strokeWidth = 2.4);
      pole.strokeWidth = 3;
    }
    for (final dy in [36.0, 40.0]) {
      c.drawPath(Path()
        ..moveTo(0, dy)
        ..quadraticBezierTo(180, dy + 26, 360, dy + 14), wire);
    }
    // The verge.
    final ground = Rect.fromLTRB(0, horizon, w, size.height);
    c.drawRect(ground, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF7FA35A), Color(0xFF5E7F43)]).createShader(ground));
    c.drawRect(Rect.fromLTRB(0, g.groundY - 6, w, size.height), Paint()..color = const Color(0xFF8C8270));

    _bonnet(c);
    _tablet(c);
    _sld(c);
  }

  void _bonnet(Canvas c) {
    final g = geo;
    // The van's white bonnet under the tablet.
    final b = Rect.fromLTRB(0, g.board.bottom - 70, 360, g.groundY + 8);
    final r = RRect.fromRectAndCorners(b, topLeft: const Radius.circular(26), topRight: const Radius.circular(26));
    c.drawRRect(r, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF3F4F2), Color(0xFFBFC3C2)]).createShader(b));
    c.drawLine(Offset(40, b.top + 22), Offset(320, b.top + 22), Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 2);
  }

  void _tablet(Canvas c) {
    final g = geo;
    final frame = RRect.fromRectAndRadius(g.board, const Radius.circular(16));
    c.drawRRect(frame.shift(const Offset(0, 6)), Paint()..color = const Color(0x55000000));
    c.drawRRect(frame, Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF2B323B), Color(0xFF15191F)]).createShader(g.board));
    final s = RRect.fromRectAndRadius(g.screen, const Radius.circular(10));
    c.drawRRect(s, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF12223A), Color(0xFF0B1628)]).createShader(g.screen));
    // A faint grid, like the control room's display.
    final grid = Paint()
      ..color = const Color(0x0FFFFFFF)
      ..strokeWidth = 1;
    for (var x = g.screen.left + 20; x < g.screen.right; x += 20) {
      c.drawLine(Offset(x, g.screen.top + 50), Offset(x, g.screen.bottom - 4), grid);
    }
    for (var y = g.screen.top + 60; y < g.screen.bottom; y += 20) {
      c.drawLine(Offset(g.screen.left + 4, y), Offset(g.screen.right - 4, y), grid);
    }
    // The docket strip (the job and the shutdown).
    final d = RRect.fromRectAndRadius(g.docketStrip, const Radius.circular(8));
    c.drawRRect(d, Paint()..color = const Color(0xFFF7F1E1));
    _text(c, 'ডকেট · শাটডাউন', Offset(g.docketStrip.left + 8, g.docketStrip.top + 3), 10, const Color(0xFF6B5B3A), bn: true);
    _text(c, map.docketBn, Offset(g.docketStrip.left + 8, g.docketStrip.top + 17), 12.5, const Color(0xFF2B2416), bn: true, bold: true, maxWidth: g.docketStrip.width - 16);
    // The legend (as on the digital SLD).
    final ly = g.screen.bottom - 20;
    final lx = 132.0;
    c.drawRect(Rect.fromLTWH(lx, ly - 5, 10, 10), Paint()..color = _on);
    _text(c, 'ON', Offset(lx + 14, ly - 7), 10, _ink);
    c.drawRect(Rect.fromLTWH(lx + 46, ly - 5, 10, 10), Paint()..color = _off);
    _text(c, 'OFF', Offset(lx + 60, ly - 7), 10, _ink);
    _text(c, 'SLD', Offset(g.screen.right - 34, g.screen.bottom - 27), 10, _dim);
  }

  void _sld(Canvas c) {
    final g = geo;
    final m = map;
    final line = Paint()
      ..color = _ink
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final bus = Paint()
      ..color = _ink
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final pA = g.point(M3SldIsolatePoint.cbA);
    final pAb = g.point(M3SldIsolatePoint.abA);
    final pX = g.point(M3SldIsolatePoint.cbX);
    final pDo = g.point(M3SldIsolatePoint.doFuse);

    // Substation A: the 11kV bus and its two feeders.
    final (a0, a1) = g.busA;
    c.drawLine(Offset(a0, g.busY), Offset(a1, g.busY), bus);
    _text(c, '11kV সাবস্টেশন', Offset((a0 + a1) / 2, g.busY - 20), 10, _ink, bn: true, centre: true);
    for (final p in [pA, pX]) {
      c.drawLine(Offset(p.dx, g.busY), p, line);
    }
    // The neighbour feeder runs off to its own area.
    final xEnd = g.y(0.36);
    c.drawLine(pX, Offset(pX.dx, xEnd), line);
    _arrow(c, Offset(pX.dx, xEnd + 6), line.color);
    // The docket feeder down to the section.
    c.drawLine(pA, pAb, line);
    c.drawLine(pAb, Offset(g.workX, g.sectionTop), line);
    final endY = m.ring ? g.y(1) : g.radialEnd;
    c.drawLine(Offset(g.workX, g.sectionTop), Offset(g.workX, endY), line);
    if (!m.ring) _arrow(c, Offset(g.workX, endY + 6), line.color);
    // The work section (the docket's bracket).
    _workBracket(c);
    for (final (i, p) in g.poles.indexed) {
      c.drawCircle(p, 4, Paint()..color = _ink);
      _text(c, 'P${m.firstPole + i}', Offset(p.dx - g.side * 30, p.dy - 7), 9.5, _dim, centre: true);
    }
    // The transformer tap: DO fuse, then the transformer (two coils, not touching).
    final t = g.transformer;
    c.drawLine(Offset(g.workX, g.tapY), Offset(t.dx - g.side * 9, g.tapY), line);
    _fuse(c, pDo, m.closed(M3SldIsolatePoint.doFuse));
    final coil = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    c.drawCircle(t + Offset(g.side * 0, -9), 8, coil);
    c.drawCircle(t + Offset(g.side * 0, 9), 8, coil);
    _text(c, '100kVA', t + Offset(g.side * 0, 22), 9, _dim, centre: true);
    _text(c, 'DO', pDo + const Offset(0, 18), 9.5, _dim, centre: true);

    // Earth on both sides of the section once it is proved dead.
    if (m.earthed) {
      _earth(c, Offset(g.workX + g.side * 14, g.sectionTop + 6));
      _earth(c, Offset(g.workX + g.side * 14, g.sectionBottom - 14));
    }

    // The ring: the tie row across to substation B's feeder.
    if (m.ring) {
      final pB = g.point(M3SldIsolatePoint.cbB);
      final pT = g.point(M3SldIsolatePoint.tie);
      final (b0, b1) = g.busB;
      c.drawLine(Offset(b0, g.busY), Offset(b1, g.busY), bus);
      _text(c, '11kV', Offset((b0 + b1) / 2, g.busY - 20), 10, _ink, centre: true);
      c.drawLine(Offset(g.bX, g.busY), pB, line);
      c.drawLine(pB, Offset(g.bX, g.y(1)), line);
      c.drawLine(Offset(g.workX, g.y(1)), Offset(pT.dx - g.side * 14, g.y(1)), line);
      c.drawLine(Offset(pT.dx + g.side * 14, g.y(1)), Offset(g.bX, g.y(1)), line);
      _isolator(c, pT, closed: m.closed(M3SldIsolatePoint.tie), horizontal: true);
      _text(c, 'AB-2 · NO', pT + const Offset(0, -26), 9.5, _ink, centre: true);
      _breaker(c, pB, closed: m.closed(M3SldIsolatePoint.cbB));
      _feederName(c, pB, m.feederB);
      if (m.tagged(M3SldIsolatePoint.tie)) _tag(c, pT + Offset(g.side * 4, 12));
      if (m.tagged(M3SldIsolatePoint.cbB)) _tag(c, pB + Offset(g.side * 14, 8));
    }

    _breaker(c, pA, closed: m.closed(M3SldIsolatePoint.cbA));
    _breaker(c, pX, closed: true);
    _feederName(c, pA, m.feederA);
    _feederName(c, pX, m.feederX);
    _isolator(c, pAb, closed: m.closed(M3SldIsolatePoint.abA), horizontal: false);
    _text(c, 'AB-1', pAb + Offset(-g.side * 30, -6), 9.5, _ink, centre: true);
    if (m.tagged(M3SldIsolatePoint.cbA)) _tag(c, pA + Offset(-g.side * 16, 8));
    if (m.tagged(M3SldIsolatePoint.abA)) _tag(c, pAb + Offset(g.side * 14, 4));
  }

  void _workBracket(Canvas c) {
    final g = geo;
    final r = g.sectionBox.inflate(4);
    final dead = map.dead;
    final col = dead ? _off : _amber;
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(8)), Paint()..color = col.withValues(alpha: 0.12));
    final dash = Paint()
      ..color = col
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final path = Path()..addRRect(RRect.fromRectAndRadius(r, const Radius.circular(8)));
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 9) {
        c.drawPath(metric.extractPath(d, math.min(d + 5, metric.length)), dash);
      }
    }
    // The badge sits outside the bracket, on the transformer side, at its top.
    final box = Rect.fromCenter(center: Offset(g.workX + g.side * 40, g.sectionTop + 6), width: 36, height: 20);
    c.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(5)), Paint()..color = col);
    _text(c, 'কাজ', box.center - const Offset(0, 1), 10, const Color(0xFF1A1405), bn: true, bold: true, centre: true);
  }

  void _breaker(Canvas c, Offset p, {required bool closed}) {
    final r = Rect.fromCenter(center: p, width: 24, height: 24);
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), Paint()..color = closed ? _on : _off);
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), Paint()
      ..color = const Color(0xFFEFF3F7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6);
    _text(c, 'CB', p - const Offset(0, 1), 9, Colors.white, centre: true, bold: true);
  }

  void _isolator(Canvas c, Offset p, {required bool closed, required bool horizontal}) {
    // A straight line with a break (the blade), as the lesson draws it.
    final a = horizontal ? p + const Offset(-14, 0) : p + const Offset(0, -14);
    final b = horizontal ? p + const Offset(14, 0) : p + const Offset(0, 14);
    c.drawCircle(p, 18, Paint()..color = const Color(0xFF0B1628));
    final blade = Paint()
      ..color = closed ? _on : _off
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    final dot = Paint()..color = _ink;
    c.drawCircle(a, 3, dot);
    c.drawCircle(b, 3, dot);
    if (closed) {
      c.drawLine(b, a, blade);
    } else {
      final open = horizontal ? a + const Offset(20, -14) : b + const Offset(14, -20);
      c.drawLine(horizontal ? a : b, open, blade);
    }
  }

  void _fuse(Canvas c, Offset p, bool closed) {
    final r = Rect.fromCenter(center: p, width: 20, height: 10);
    c.drawRect(r, Paint()..color = const Color(0xFF0B1628));
    c.drawRect(r, Paint()
      ..color = closed ? _on : _off
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
    c.drawLine(r.centerLeft, r.centerRight, Paint()
      ..color = closed ? _on : _off
      ..strokeWidth = 1.4);
    // The drop-out arrow.
    c.drawLine(p + const Offset(-6, 10), p + const Offset(6, -10), Paint()
      ..color = _ink
      ..strokeWidth = 1.4);
    c.drawPath(Path()
      ..moveTo(p.dx + 6, p.dy - 10)
      ..lineTo(p.dx + 1, p.dy - 7)
      ..lineTo(p.dx + 6, p.dy - 4)
      ..close(), Paint()..color = _ink);
  }

  void _earth(Canvas c, Offset top) {
    final p = Paint()
      ..color = _off
      ..strokeWidth = 2;
    c.drawLine(top, top + const Offset(0, 6), p);
    for (final (i, half) in [9.0, 6.0, 3.0].indexed) {
      final y = top.dy + 6 + i * 3.5;
      c.drawLine(Offset(top.dx - half, y), Offset(top.dx + half, y), p);
    }
  }

  void _tag(Canvas c, Offset at) {
    final r = Rect.fromCenter(center: at, width: 12, height: 15);
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(0.25);
    c.translate(-at.dx, -at.dy);
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), Paint()..color = _amber);
    c.drawCircle(Offset(at.dx, r.top + 3), 1.6, Paint()..color = const Color(0xFF0B1628));
    c.drawLine(Offset(at.dx - 3, at.dy + 1), Offset(at.dx + 3, at.dy + 1), Paint()
      ..color = const Color(0xFF8A1C10)
      ..strokeWidth = 1.4);
    c.restore();
  }

  void _arrow(Canvas c, Offset tip, Color col) {
    c.drawPath(Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(tip.dx - 5, tip.dy - 8)
      ..lineTo(tip.dx + 5, tip.dy - 8)
      ..close(), Paint()..color = col);
  }

  void _feederName(Canvas c, Offset cb, String name) {
    _text(c, name, cb + const Offset(0, 22), 9.5, _ink, bn: true, centre: true);
  }

  void _text(Canvas c, String s, Offset at, double size, Color color, {bool bn = false, bool bold = false, bool centre = false, double? maxWidth}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontFamily: bn ? banglaFont : 'Roboto',
          fontFamilyFallback: const ['Roboto', banglaFont],
          fontSize: size,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          color: color,
          height: 1.1,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth ?? double.infinity);
    tp.paint(c, centre ? at - Offset(tp.width / 2, tp.height / 2) : at);
  }

  @override
  bool shouldRepaint(M3SldIsolatePainter old) => old.geo != geo || old.map != map || old.seed != seed;
}

/// The flash at the work section when a hand meets a live line, or at an
/// isolator opened on load (the deadly moment, in colour over the frozen scene).
class M3SldIsolateArcPainter extends CustomPainter {
  const M3SldIsolateArcPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final flick = v < 0.5 ? (0.65 + 0.35 * math.sin(v * 60).abs()) : (1 - (v - 0.5) * 1.2).clamp(0.4, 1.0);
    final r = 26 + 70 * Curves.easeOut.transform(v.clamp(0.0, 1.0));
    c.drawCircle(at, r, Paint()..shader = RadialGradient(colors: [Color.fromRGBO(255, 250, 220, 0.95 * flick), Color.fromRGBO(140, 170, 255, 0.5 * flick), const Color(0x00FFC24A)]).createShader(Rect.fromCircle(center: at, radius: r)));
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
  bool shouldRepaint(M3SldIsolateArcPainter old) => old.v != v || old.at != at;
}
