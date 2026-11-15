import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The drawn world of lesson 6.1 কাজ 2 "ক্ষতির খোঁজে কয়েল"
// (m6_dtr_coil_forensic.dart). Two places:
//
//  (1) The field, close up: a pole-mounted DTR (WBSEDCL: the AB switch and
//      the three HG horn-gap fuses on the pole above it, no DO). The tank on
//      its channel platform, the conservator drum with its oil gauge (MIN /
//      MAX) on a bracket above the tank, the breather hanging on its left
//      (silica gel in a glass), three tall HT bushings and four short LT
//      bushings, the drain valve low on the face, the earth lead down the
//      pole. The case's sign is drawn, never captioned: a wet streak from a
//      gasket, a joint or the drain valve with a puddle under the platform
//      and the gauge under MIN; pink or white gel; a glass bottle of dark
//      drain oil with smell lines, and the DTR tripped (the middle HG fuse
//      blown, its melted ends hanging); sound marks after listening (even arcs
//      for a steady hum, jagged marks for popping or crackling). A swipe
//      across the tank opens the X-ray cutaway: the oil, the leads and their
//      bolted joints, the copper coil round the laminated core, and the coil
//      cut open to show the kraft paper between its layers — every part drawn
//      the same way, every time.
//  (2) The repair shop: an opened coil standing on a turntable on the bench
//      (the core's top yoke above it). The damage is drawn on one face only;
//      the player turns the coil round to find it.
//
// No text in the art except labels a worker reads (MIN / MAX). Code-drawn,
// gradients, no bitmaps. Design: 360 wide × the scene's height; the ground
// follows the bottom of the screen (a tall phone gets more sky).

/// The outside signs (lesson 6.1 section 6; F0–F4 in the spec).
enum M6Sign { hum, leak, gel, burnt, crackle }

/// The inner things a sign can harm, and "normal".
enum M6Part { oil, paper, coil, conn, normal }

/// Where the oil comes out (lesson 6.1 point 3: a bushing gasket, a cracked
/// joint, a loose drain valve).
enum M6LeakSource { gasket, joint, drain }

/// The damage families seen on an opened coil (lesson 6.1 points 7–8).
enum M6Family { thermal, arc, turn, mech }

/// The morning, noon or evening light.
const m6LightCount = 3;

/// The four faces of the coil (90° apart).
const m6Faces = 4;

/// Where things are (design px, 360 wide).
@immutable
class M6CoilGeo {
  const M6CoilGeo._(this.height, this.groundY, this.topY);

  factory M6CoilGeo.forScene(double height, double inset) {
    final g = height - floorUp - inset * 0.5;
    return M6CoilGeo._(height, g, math.max(135.0, g - 420));
  }

  final double height;

  /// The ground line (the field) / the floor (the shop).
  final double groundY;

  /// The top of the pole (the field) / the top of the shop's view.
  final double topY;

  /// The ground sits this far above the bottom (the tag tray stands under it).
  static const double floorUp = 200;

  double get h => groundY - topY;

  /// A height on the structure (0 = the pole top, 1 = the ground).
  double y(double f) => topY + f * h;

  // --- the field ---------------------------------------------------------------
  static const double poleX = 136;

  /// The tank.
  Rect get tank => Rect.fromLTRB(44, y(0.28), 228, math.max(y(0.64), y(0.28) + 116));
  double get platformY => tank.bottom + 6;

  /// The X-ray zones inside the tank (and "normal" beside it).
  Rect zone(M6Part p) {
    final i = tank.deflate(6);
    final topH = i.height * 0.42;
    final half = i.width / 2;
    return switch (p) {
      M6Part.oil => Rect.fromLTWH(i.left, i.top, half - 2, topH),
      M6Part.conn => Rect.fromLTWH(i.left + half + 2, i.top, half - 2, topH),
      M6Part.coil => Rect.fromLTWH(i.left, i.top + topH + 4, half - 2, i.height - topH - 4),
      M6Part.paper => Rect.fromLTWH(i.left + half + 2, i.top + topH + 4, half - 2, i.height - topH - 4),
      M6Part.normal => Rect.fromLTWH(238, tank.center.dy - 22, 116, 44),
    };
  }

  /// The conservator drum on its bracket above the tank, its gauge glass at
  /// the left end.
  Rect get conservator => Rect.fromLTWH(50, tank.top - 30, 96, 20);
  Rect get gaugeGlass => Rect.fromLTWH(conservator.left + 6, conservator.top + 2, 10, conservator.height - 4);

  /// The breather (silica gel in a glass) hanging on the tank's left.
  Rect get breather => Rect.fromLTWH(8, tank.top - 2, 26, 40);

  /// Sound marks after listening (left of the tank, under the breather).
  Rect get waves => Rect.fromLTWH(4, tank.center.dy + 4, 36, math.max(30.0, tank.bottom - tank.center.dy - 14));

  /// The drain-oil bottle on the ground (a dark-oil case).
  Rect get bottle => Rect.fromLTWH(14, groundY - 46, 30, 42);

  /// The oil puddle on the ground under the platform (a leak case).
  Rect get puddle => Rect.fromLTWH(96, groundY - 22, 84, 20);

  /// The drain valve low on the tank's face.
  Offset get drainValve => Offset(tank.left + 22, tank.bottom - 7);

  /// The HT bushings on the tank top (tall) and the LT bushings out of its
  /// right wall (short).
  List<double> get htX => const [160, 186, 212];
  List<double> get ltY => [for (var i = 0; i < 4; i++) tank.top + 14 + i * 14.0];

  /// Where each leak source is.
  Offset leakAt(M6LeakSource s) => switch (s) {
        M6LeakSource.gasket => Offset(186, tank.top + 2),
        M6LeakSource.joint => Offset(tank.right - 3, tank.top + tank.height * 0.36),
        M6LeakSource.drain => drainValve,
      };

  /// The sign the player drags from (the pin is the sign itself).
  Rect pinHit(M6Sign s) => switch (s) {
        M6Sign.leak => puddle.inflate(6),
        M6Sign.gel => breather.inflate(5),
        M6Sign.burnt => bottle.inflate(5),
        M6Sign.hum || M6Sign.crackle => waves.inflate(3),
      };
  Offset pin(M6Sign s) => pinHit(s).center;

  /// The ear button (hold to listen).
  Rect get ear => Rect.fromLTWH(10, groundY + 16, 56, 56);

  // --- the shop ----------------------------------------------------------------
  double get benchTop => groundY - 60;

  /// The coil on the turntable.
  Rect get coil => Rect.fromLTRB(58, math.max(y(0.16), topY + 40), 202, benchTop - 12);
  double get coilR => coil.width / 2;

  @override
  bool operator ==(Object other) => other is M6CoilGeo && other.height == height && other.groundY == groundY && other.topY == topY;

  @override
  int get hashCode => Object.hash(height, groundY, topY);
}

/// The silica gel's colour: dry blue or orange, spent pink or white.
enum M6Gel { blue, orange, pink, white }

/// What the field DTR shows now.
@immutable
class M6FieldRig {
  const M6FieldRig({
    required this.sign,
    this.source = M6LeakSource.gasket,
    this.gel = M6Gel.blue,
    this.light = 0,
    this.listened = false,
    this.xray = false,
  });

  final M6Sign sign;
  final M6LeakSource source;
  final M6Gel gel;
  final int light;

  /// The sound marks show (a sound case, heard).
  final bool listened;

  /// The X-ray cutaway is open.
  final bool xray;

  /// The DTR tripped (the dark-oil case): an HG fuse blown, the DTR silent.
  bool get tripped => sign == M6Sign.burnt;

  @override
  bool operator ==(Object other) =>
      other is M6FieldRig &&
      other.sign == sign &&
      other.source == source &&
      other.gel == gel &&
      other.light == light &&
      other.listened == listened &&
      other.xray == xray;

  @override
  int get hashCode => Object.hash(sign, source, gel, light, listened, xray);
}

const _steel = Color(0xFF6F7880);
const _wire = Color(0xFF3C4248);
const _porcelain = Color(0xFFDDE3E8);
const _copper = Color(0xFFC77A3A);
const _paper = Color(0xFFE8D7A8);

List<Color> _skyFor(int light) => switch (light % m6LightCount) {
      0 => const [Color(0xFF8EC5F0), Color(0xFFE3F1FB)],
      1 => const [Color(0xFF5FA8E8), Color(0xFFCFE6F7)],
      _ => const [Color(0xFF6A6FB0), Color(0xFFF2B98A)],
    };

/// The field DTR, close up.
class M6FieldPainter extends CustomPainter {
  const M6FieldPainter({required this.geo, required this.rig});

  final M6CoilGeo geo;
  final M6FieldRig rig;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    // Sky, far trees, ground.
    c.drawRect(
      Rect.fromLTWH(0, 0, w, g.groundY),
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: _skyFor(rig.light)).createShader(Rect.fromLTWH(0, 0, w, g.groundY)),
    );
    final far = Paint()..color = const Color(0xFF6E9A6A);
    for (var i = 0; i < 9; i++) {
      final x = i * 44.0 - 10;
      c.drawOval(Rect.fromCenter(center: Offset(x, g.groundY - 16), width: 60, height: 34), far);
    }
    c.drawRect(
      Rect.fromLTWH(0, g.groundY, w, size.height - g.groundY),
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF9C8B62), Color(0xFF6E6043)]).createShader(Rect.fromLTWH(0, g.groundY, w, size.height - g.groundY)),
    );
    _pole(c);
    _platform(c);
    _conservator(c);
    _breather(c);
    _tank(c);
    if (rig.sign == M6Sign.leak) _leak(c);
    if (rig.sign == M6Sign.burnt) _bottle(c);
    if (rig.listened && (rig.sign == M6Sign.hum || rig.sign == M6Sign.crackle)) _waves(c);
  }

  void _pole(Canvas c) {
    final g = geo;
    const x = M6CoilGeo.poleX;
    c.drawRect(
      Rect.fromLTRB(x - 7, g.topY, x + 7, g.groundY),
      Paint()..shader = const LinearGradient(colors: [Color(0xFF8A8F94), Color(0xFFB9BEC2), Color(0xFF7B8085)]).createShader(Rect.fromLTRB(x - 7, g.topY, x + 7, g.groundY)),
    );
    // Cross-arm with the AB switch (three blades closed) and the HG fuses.
    final armY = g.y(0.04);
    c.drawRect(Rect.fromLTRB(84, armY, 188, armY + 6), Paint()..color = _steel);
    final blade = Paint()
      ..color = const Color(0xFFB0B6BC)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final bx in const [100.0, 136.0, 172.0]) {
      c.drawRect(Rect.fromCenter(center: Offset(bx, armY - 6), width: 8, height: 12), Paint()..color = _porcelain);
      c.drawLine(Offset(bx - 8, armY - 13), Offset(bx + 8, armY - 13), blade);
    }
    final hgY = g.y(0.15);
    c.drawRect(Rect.fromLTRB(96, hgY + 8, 176, hgY + 13), Paint()..color = _steel);
    final horn = Paint()
      ..color = const Color(0xFF8E9399)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final lead = Paint()
      ..color = _wire
      ..strokeWidth = 1.6;
    final fuse = Paint()
      ..color = _copper
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    final tripped = rig.tripped;
    for (final (i, hx) in const [108.0, 136.0, 164.0].indexed) {
      c.drawRect(Rect.fromCenter(center: Offset(hx, hgY + 2), width: 7, height: 12), Paint()..color = _porcelain);
      c.drawArc(Rect.fromCenter(center: Offset(hx - 5, hgY - 6), width: 10, height: 14), math.pi * 0.5, math.pi, false, horn);
      c.drawArc(Rect.fromCenter(center: Offset(hx + 5, hgY - 6), width: 10, height: 14), -math.pi * 0.5, math.pi, false, horn);
      // AB → HG → HT bushing.
      c.drawLine(Offset(const [100.0, 136.0, 172.0][i], armY + 6), Offset(hx, hgY - 4), lead);
      c.drawLine(Offset(hx, hgY + 8), Offset(g.htX[i], g.tank.top - 26), lead);
      // The fuse wire across the horn tips; after the trip (the dark-oil
      // case) the middle one has blown: two melted ends hanging, soot.
      final l = Offset(hx - 5, hgY - 13);
      final r = Offset(hx + 5, hgY - 13);
      if (tripped && i == 1) {
        c.drawCircle(Offset(hx, hgY - 12), 6, Paint()..color = const Color(0x553A2A1C));
        c.drawLine(l, l.translate(1, 6), fuse);
        c.drawLine(r, r.translate(-1, 5), fuse);
        c.drawCircle(l.translate(1, 6), 1.3, Paint()..color = const Color(0xFF3A2A1C));
        c.drawCircle(r.translate(-1, 5), 1.3, Paint()..color = const Color(0xFF3A2A1C));
      } else {
        c.drawLine(l, r, fuse);
      }
    }
    // The earth lead down the pole into the ground.
    c.drawLine(
      Offset(g.tank.right - 6, g.tank.bottom),
      Offset(x + 10, g.groundY),
      Paint()
        ..color = const Color(0xFF3E7A3A)
        ..strokeWidth = 2,
    );
  }

  void _platform(Canvas c) {
    final g = geo;
    final y = g.platformY;
    c.drawRect(Rect.fromLTRB(30, y - 6, 242, y + 4), Paint()..color = const Color(0xFF555C63));
    c.drawRect(Rect.fromLTRB(30, y + 4, 242, y + 7), Paint()..color = const Color(0xFF3A3F44));
  }

  void _conservator(Canvas c) {
    final g = geo;
    final r = g.conservator;
    c.drawRect(Rect.fromLTWH(r.center.dx - 3, r.bottom, 6, g.tank.top - r.bottom), Paint()..color = _steel);
    c.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(10)),
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF9BA6AE), Color(0xFF66717A)]).createShader(r),
    );
    // The gauge glass: MIN–MAX marks; the oil under MIN in a leak case.
    final gg = g.gaugeGlass;
    c.drawRect(gg, Paint()..color = const Color(0xFFEFF5F8));
    final low = rig.sign == M6Sign.leak;
    final level = low ? gg.bottom - gg.height * 0.12 : gg.top + gg.height * 0.48;
    c.drawRect(Rect.fromLTRB(gg.left, level, gg.right, gg.bottom), Paint()..color = const Color(0xFFC9962E));
    final mark = Paint()
      ..color = const Color(0xFF1E2A33)
      ..strokeWidth = 1;
    c.drawLine(Offset(gg.right, gg.top + gg.height * 0.22), Offset(gg.right + 4, gg.top + gg.height * 0.22), mark);
    c.drawLine(Offset(gg.right, gg.top + gg.height * 0.78), Offset(gg.right + 4, gg.top + gg.height * 0.78), mark);
    _label(c, 'MAX', Offset(gg.right + 5, gg.top - 3));
    _label(c, 'MIN', Offset(gg.right + 5, gg.top + gg.height * 0.56));
  }

  void _label(Canvas c, String t, Offset at) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: const TextStyle(fontSize: 5.5, fontWeight: FontWeight.w800, color: Color(0xFF1E2A33))),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, at);
  }

  void _breather(Canvas c) {
    final g = geo;
    final b = g.breather;
    final pipe = Paint()
      ..color = _steel
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    c.drawPath(
      Path()
        ..moveTo(g.conservator.left + 4, g.conservator.center.dy)
        ..lineTo(b.center.dx, g.conservator.center.dy)
        ..lineTo(b.center.dx, b.top),
      pipe,
    );
    c.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(5)), Paint()..color = const Color(0xFFCBD3D8));
    final glass = b.deflate(4);
    final gel = switch (rig.gel) {
      M6Gel.blue => const Color(0xFF2E6FD8),
      M6Gel.orange => const Color(0xFFF08A1C),
      M6Gel.pink => const Color(0xFFF4A6C0),
      M6Gel.white => const Color(0xFFF1EEE6),
    };
    c.drawRRect(RRect.fromRectAndRadius(glass, const Radius.circular(3)), Paint()..color = gel);
    // Beads.
    final bead = Paint()..color = Colors.white.withValues(alpha: 0.35);
    for (var i = 0; i < 10; i++) {
      c.drawCircle(Offset(glass.left + 4 + (i % 3) * 6.0, glass.top + 4 + (i ~/ 3) * 8.0), 1.6, bead);
    }
    c.drawRect(Rect.fromLTWH(b.center.dx - 5, b.bottom, 10, 4), Paint()..color = _steel);
  }

  void _tank(Canvas c) {
    final g = geo;
    final t = g.tank;
    // HT bushings (tall, wide sheds) and LT bushings (short).
    for (final x in g.htX) {
      for (var k = 0; k < 4; k++) {
        c.drawOval(Rect.fromCenter(center: Offset(x, t.top - 6 - k * 6.0), width: 14, height: 5), Paint()..color = _porcelain);
      }
      c.drawRect(Rect.fromCenter(center: Offset(x, t.top - 13), width: 5, height: 26), Paint()..color = const Color(0xFFC7CED4));
    }
    for (final y in g.ltY) {
      c.drawRect(Rect.fromLTWH(t.right, y - 3, 8, 6), Paint()..color = _porcelain);
      c.drawRect(Rect.fromLTWH(t.right + 8, y - 1.5, 4, 3), Paint()..color = _wire);
    }
    final body = RRect.fromRectAndRadius(t, const Radius.circular(4));
    if (!rig.xray) {
      c.drawRRect(
        body,
        Paint()..shader = const LinearGradient(colors: [Color(0xFF58636C), Color(0xFF8C979F), Color(0xFF5E6870)]).createShader(t),
      );
      // Fins (corrugations) across the face.
      final fin = Paint()
        ..color = const Color(0x33000000)
        ..strokeWidth = 2;
      for (var x = t.left + 12; x < t.right - 8; x += 10) {
        c.drawLine(Offset(x, t.top + 8), Offset(x, t.bottom - 14), fin);
      }
      // The lid's rim.
      c.drawRect(Rect.fromLTWH(t.left - 3, t.top - 3, t.width + 6, 5), Paint()..color = const Color(0xFF4C565E));
    } else {
      _xray(c, t);
    }
    // The drain valve.
    final dv = g.drainValve;
    c.drawRect(Rect.fromCenter(center: dv, width: 14, height: 8), Paint()..color = const Color(0xFF3F464C));
    c.drawCircle(dv.translate(-9, 0), 4, Paint()..color = const Color(0xFFB8402C));
  }

  /// The cutaway: oil everywhere; the leads and their bolted joints (top
  /// right); the free oil over the coils (top left); the copper coil round
  /// the laminated core (bottom left); the coil cut open, paper between the
  /// copper layers (bottom right). Every part the same weight of drawing.
  void _xray(Canvas c, Rect t) {
    final g = geo;
    c.drawRRect(RRect.fromRectAndRadius(t, const Radius.circular(4)), Paint()..color = const Color(0xFF384148));
    final inner = t.deflate(4);
    c.drawRect(inner, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE2B85A), Color(0xFFC08A2A)]).createShader(inner));
    // Oil (top left): the surface line and a few bubbles.
    final oil = g.zone(M6Part.oil);
    final surf = Paint()
      ..color = const Color(0x88FFF3C4)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final p = Path()..moveTo(oil.left, oil.top + 6);
    for (var x = oil.left; x <= oil.right; x += 8) {
      p.quadraticBezierTo(x + 2, oil.top + 3, x + 4, oil.top + 6);
      p.quadraticBezierTo(x + 6, oil.top + 9, x + 8, oil.top + 6);
    }
    c.drawPath(p, surf);
    final bub = Paint()..color = const Color(0x66FFFFFF);
    for (var i = 0; i < 6; i++) {
      c.drawCircle(Offset(oil.left + 10 + i * (oil.width - 20) / 5, oil.center.dy + (i.isEven ? 4 : -2)), 2.2, bub);
    }
    // Connections (top right): leads up to the bushings with bolted joints.
    final conn = g.zone(M6Part.conn);
    final leadP = Paint()
      ..color = _copper
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 3; i++) {
      final x = conn.left + 12 + i * (conn.width - 24) / 2;
      c.drawLine(Offset(x, conn.bottom), Offset(x, conn.top + 4), leadP);
      c.drawRect(Rect.fromCenter(center: Offset(x, conn.center.dy), width: 9, height: 6), Paint()..color = const Color(0xFF8E959B));
      c.drawCircle(Offset(x, conn.center.dy), 1.6, Paint()..color = _wire);
    }
    // The coil round the core (bottom left).
    final coil = g.zone(M6Part.coil);
    final core = Rect.fromCenter(center: coil.center, width: 10, height: coil.height);
    c.drawRect(core, Paint()..color = const Color(0xFF6B7178));
    for (final side in [-1.0, 1.0]) {
      final r = Rect.fromLTWH(side < 0 ? coil.left + 4 : core.right + 2, coil.top + 4, (coil.width - core.width) / 2 - 6, coil.height - 8);
      c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), Paint()..shader = const LinearGradient(colors: [Color(0xFF9A5420), _copper, Color(0xFF8C4A1C)]).createShader(r));
      final turn = Paint()
        ..color = const Color(0x55000000)
        ..strokeWidth = 1;
      for (var y = r.top + 4; y < r.bottom - 2; y += 5) {
        c.drawLine(Offset(r.left + 2, y), Offset(r.right - 2, y), turn);
      }
    }
    // The coil cut open (bottom right): copper layers with paper between.
    final paper = g.zone(M6Part.paper);
    final cut = paper.deflate(4);
    var y = cut.top;
    var k = 0;
    while (y < cut.bottom) {
      final hgt = k.isEven ? 5.0 : 3.0;
      c.drawRect(Rect.fromLTWH(cut.left, y, cut.width, math.min(hgt, cut.bottom - y)), Paint()..color = k.isEven ? _copper : _paper);
      y += hgt;
      k++;
    }
    // Hairline seams between the four parts of the cutaway.
    final seam = Paint()
      ..color = const Color(0x55384148)
      ..strokeWidth = 1;
    c.drawLine(Offset(inner.left, coil.top - 2), Offset(inner.right, coil.top - 2), seam);
    c.drawLine(Offset(inner.center.dx, inner.top), Offset(inner.center.dx, inner.bottom), seam);
  }

  void _leak(Canvas c) {
    final g = geo;
    final s = g.leakAt(rig.source);
    final wet = Paint()
      ..color = const Color(0xCC3A2408)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    final down = Offset(s.dx, g.tank.bottom);
    // The wet patch round the source, the streak down the tank.
    c.drawOval(Rect.fromCenter(center: s.translate(0, 6), width: 16, height: 22), Paint()..color = const Color(0x993A2408));
    c.drawLine(s, down, wet);
    c.drawCircle(s, 3.4, Paint()..color = const Color(0xCC3A2408));
    // Drips to the ground, the puddle.
    final drip = Paint()..color = const Color(0xBB3A2408);
    for (var i = 0; i < 3; i++) {
      c.drawOval(Rect.fromCenter(center: Offset(s.dx.clamp(g.puddle.left + 6, g.puddle.right - 6), g.platformY + 14 + i * 12.0), width: 3, height: 6), drip);
    }
    final pd = g.puddle;
    c.drawOval(pd, Paint()..color = const Color(0xDD2A1A08));
    c.drawOval(pd.deflate(5).translate(-6, -2), Paint()..color = const Color(0x55FFFFFF));
  }

  void _bottle(Canvas c) {
    final b = geo.bottle;
    final glass = RRect.fromRectAndCorners(Rect.fromLTRB(b.left, b.top + 12, b.right, b.bottom), topLeft: const Radius.circular(6), topRight: const Radius.circular(6), bottomLeft: const Radius.circular(3), bottomRight: const Radius.circular(3));
    c.drawRRect(glass, Paint()..color = const Color(0x55E8F4FA));
    c.drawRect(Rect.fromLTRB(b.left + 2, b.top + 22, b.right - 2, b.bottom - 2), Paint()..color = const Color(0xFF241408));
    c.drawRect(Rect.fromCenter(center: Offset(b.center.dx, b.top + 8), width: 10, height: 10), Paint()..color = const Color(0x77E8F4FA));
    c.drawRRect(glass, Paint()
      ..color = const Color(0xAAFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2);
    // Smell lines.
    final smell = Paint()
      ..color = const Color(0xAA4A4A4A)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 3; i++) {
      final x = b.left + 6 + i * 9.0;
      c.drawPath(
        Path()
          ..moveTo(x, b.top + 2)
          ..quadraticBezierTo(x - 4, b.top - 6, x, b.top - 12)
          ..quadraticBezierTo(x + 4, b.top - 18, x, b.top - 24),
        smell,
      );
    }
  }

  void _waves(Canvas c) {
    final w = geo.waves;
    final p = Paint()
      ..color = const Color(0xFF1E3A5A)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final o = Offset(w.right + 4, w.center.dy);
    if (rig.sign == M6Sign.hum) {
      for (var i = 1; i <= 3; i++) {
        c.drawArc(Rect.fromCircle(center: o, radius: 9.0 * i), math.pi * 0.72, math.pi * 0.56, false, p);
      }
    } else {
      for (var i = 0; i < 4; i++) {
        final y = w.top + 6 + i * (w.height - 12) / 3;
        final x0 = w.right - 6 - (i.isEven ? 0 : 8);
        c.drawPath(
          Path()
            ..moveTo(x0, y)
            ..lineTo(x0 - 6, y - 4)
            ..lineTo(x0 - 10, y + 3)
            ..lineTo(x0 - 16, y - 3)
            ..lineTo(x0 - 22, y + 2),
          p,
        );
      }
    }
  }

  @override
  bool shouldRepaint(M6FieldPainter old) => old.geo != geo || old.rig != rig;
}

/// The link: the line from the sign to the finger while dragging, or to the
/// part once linked; [glow] 0–1 runs the harm along it (after the action).
class M6LinkPainter extends CustomPainter {
  M6LinkPainter({required this.line, this.glow = 0}) : super(repaint: line);

  /// From → to (design px), or null.
  final ValueListenable<(Offset, Offset)?> line;
  final double glow;

  @override
  void paint(Canvas c, Size size) {
    final l = line.value;
    if (l == null) return;
    final (a, b) = l;
    final p = Paint()
      ..color = const Color(0xFFFFD34E)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    c.drawLine(a, b, Paint()
      ..color = const Color(0x99000000)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round);
    c.drawLine(a, b, p);
    c.drawCircle(a, 6, Paint()..color = const Color(0xFFFFD34E));
    c.drawCircle(a, 3, Paint()..color = const Color(0xFF7A4A00));
    c.drawCircle(b, 5, Paint()..color = const Color(0xFFFFD34E));
    if (glow > 0) {
      final at = Offset.lerp(a, b, glow.clamp(0.0, 1.0))!;
      c.drawCircle(at, 10, Paint()
        ..color = const Color(0xAAFF5A2A)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      c.drawCircle(at, 4, Paint()..color = const Color(0xFFFFF0C0));
    }
  }

  @override
  bool shouldRepaint(M6LinkPainter old) => old.glow != glow || old.line != line;
}

/// The repair shop: the bench, the turntable, the opened coil turned to
/// [angle] (radians; face k faces the player at k × 90°). [damageFace]'s
/// face carries [family]'s damage; everything else is clean.
class M6ShopPainter extends CustomPainter {
  M6ShopPainter({required this.geo, required this.family, required this.damageFace, required this.angle, this.light = 0, this.found = false}) : super(repaint: angle);

  final M6CoilGeo geo;
  final M6Family family;
  final int damageFace;
  final ValueListenable<double> angle;
  final int light;
  final bool found;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    // The shop wall and floor.
    c.drawRect(
      Rect.fromLTWH(0, 0, w, g.groundY),
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0xFF55606A), light == 2 ? const Color(0xFF8A7F70) : const Color(0xFF8D9AA4)]).createShader(Rect.fromLTWH(0, 0, w, g.groundY)),
    );
    // A window band and a lamp.
    c.drawRect(Rect.fromLTWH(232, g.topY - 10, 110, 70), Paint()..color = const Color(0xFFBFD8E8));
    c.drawRect(Rect.fromLTWH(232, g.topY - 10, 110, 70), Paint()
      ..color = const Color(0xFF3E474F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
    c.drawRect(Rect.fromLTWH(0, g.groundY, w, size.height - g.groundY), Paint()..color = const Color(0xFF3B3F44));
    // The bench.
    final bench = Rect.fromLTRB(10, g.benchTop, 350, g.benchTop + 14);
    c.drawRect(bench, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFA9773F), Color(0xFF7A5228)]).createShader(bench));
    for (final x in const [24.0, 330.0]) {
      c.drawRect(Rect.fromLTWH(x, bench.bottom, 10, g.groundY - bench.bottom), Paint()..color = const Color(0xFF5E3F1E));
    }
    // The turntable.
    final cx = g.coil.center.dx;
    c.drawOval(Rect.fromCenter(center: Offset(cx, g.benchTop - 6), width: g.coil.width + 30, height: 16), Paint()..color = const Color(0xFF2D3338));
    c.drawOval(Rect.fromCenter(center: Offset(cx, g.benchTop - 9), width: g.coil.width + 22, height: 12), Paint()..color = const Color(0xFF5A6268));
    _coil(c);
  }

  void _coil(Canvas c) {
    final g = geo;
    final r = g.coil;
    final cx = r.center.dx;
    final rad = g.coilR;
    final th = angle.value;
    // The core's top yoke and its leg through the coil.
    final yoke = Rect.fromLTRB(r.left - 14, r.top - 20, r.right + 14, r.top - 4);
    c.drawRect(yoke, Paint()..color = const Color(0xFF5F666D));
    final lam = Paint()
      ..color = const Color(0x33000000)
      ..strokeWidth = 1;
    for (var y = yoke.top + 3; y < yoke.bottom; y += 3) {
      c.drawLine(Offset(yoke.left, y), Offset(yoke.right, y), lam);
    }
    // The copper cylinder.
    final body = Rect.fromLTRB(r.left, r.top, r.right, r.bottom);
    c.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(10)),
      Paint()..shader = const LinearGradient(colors: [Color(0xFF7A3E14), _copper, Color(0xFFE9A066), _copper, Color(0xFF6E3810)], stops: [0, 0.3, 0.5, 0.72, 1]).createShader(body),
    );
    final turn = Paint()
      ..color = const Color(0x44000000)
      ..strokeWidth = 1;
    for (var y = body.top + 6; y < body.bottom - 3; y += 6) {
      c.drawLine(Offset(body.left + 3, y), Offset(body.right - 3, y), turn);
    }
    // The paper wrap at the top and bottom rims (a band of kraft paper).
    for (final y in [body.top, body.bottom - 8]) {
      c.drawRect(Rect.fromLTWH(body.left + 2, y, body.width - 4, 8), Paint()..color = _paper.withValues(alpha: 0.85));
    }
    // Spacer sticks every 45° and a lead every 90° (they turn with the coil).
    for (var k = 0; k < 8; k++) {
      final a = k * math.pi / 4 - th;
      final cs = math.cos(a);
      if (cs <= 0.05) continue;
      final x = cx + rad * math.sin(a) * 0.96;
      final sw = 6 * cs;
      c.drawRect(Rect.fromLTWH(x - sw / 2, body.top + 8, sw, body.height - 16), Paint()..color = const Color(0xFF9B7448).withValues(alpha: 0.55 + 0.45 * cs));
      if (k.isEven) {
        c.drawRect(Rect.fromLTWH(x - 2.5 * cs, body.top - 14, 5 * cs, 14), Paint()..color = _copper);
      }
    }
    // The damage on one face only.
    final a = damageFace * math.pi / 2 - th;
    final cs = math.cos(a);
    if (cs > 0.12) _damage(c, body, Offset(cx + rad * math.sin(a) * 0.8, body.center.dy), cs);
  }

  void _damage(Canvas c, Rect body, Offset at, double squash) {
    final w = 84 * squash;
    switch (family) {
      case M6Family.thermal:
        // The paper at the top of the coil burnt black (heat rises with the oil).
        final band = Rect.fromCenter(center: Offset(at.dx, body.top + body.height * 0.17), width: w * 1.3, height: body.height * 0.3);
        c.drawOval(band, Paint()
          ..color = const Color(0xF0141008)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
        c.drawOval(band.deflate(6), Paint()..color = const Color(0xFF2A2218));
      case M6Family.arc:
        // Copper melted into lumps and spattered.
        final lump = Paint()..color = const Color(0xFFE6B07A);
        final dark = Paint()..color = const Color(0xFF3A2010);
        c.drawOval(Rect.fromCenter(center: at, width: w, height: 44), dark);
        for (var i = 0; i < 7; i++) {
          final dx = (i - 3) * w / 8;
          final dy = (i.isEven ? -6 : 7) + (i % 3) * 2.0;
          c.drawCircle(at.translate(dx, dy * 1.4), 5.5 + (i % 3) * 1.5, lump);
        }
        for (var i = 0; i < 6; i++) {
          c.drawCircle(at.translate((i - 2.5) * w / 5, 22 + (i % 2) * 6.0), 1.8, lump);
        }
      case M6Family.turn:
        // A few turns burst open at one spot.
        final burst = Paint()
          ..color = const Color(0xFF2A1A0E)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
        c.drawOval(Rect.fromCenter(center: at, width: w * 0.7, height: 26), Paint()..color = const Color(0xFF1C120A));
        for (var i = 0; i < 5; i++) {
          final y = at.dy - 16 + i * 8.0;
          c.drawLine(Offset(at.dx - w * 0.45, y), Offset(at.dx - w * 0.12, y - 6), burst);
          c.drawLine(Offset(at.dx + w * 0.12, y - 6), Offset(at.dx + w * 0.45, y), burst);
        }
      case M6Family.mech:
        // The coil bulged and its turns pushed out of line.
        final bulge = Path()
          ..moveTo(at.dx - w * 0.6, body.top + 12)
          ..quadraticBezierTo(at.dx + w * 0.2, body.center.dy - 30, at.dx - w * 0.1, body.center.dy)
          ..quadraticBezierTo(at.dx - w * 0.5, body.center.dy + 30, at.dx - w * 0.6, body.bottom - 12);
        c.drawPath(bulge, Paint()
          ..color = const Color(0xFF4A2610)
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke);
        final off = Paint()
          ..color = const Color(0xFF5A3014)
          ..strokeWidth = 1.6;
        for (var i = 0; i < 6; i++) {
          final y = body.center.dy - 26 + i * 10.0;
          c.drawLine(Offset(at.dx - w * 0.5, y), Offset(at.dx + w * 0.5, y + (i.isEven ? 5 : -5)), off);
        }
    }
    if (found) {
      c.drawCircle(at.translate(0, body.height * (family == M6Family.thermal ? -0.33 : 0)), 34 * squash + 4, Paint()
        ..color = const Color(0xCCFFD34E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4);
    }
  }

  @override
  bool shouldRepaint(M6ShopPainter old) => old.geo != geo || old.family != family || old.damageFace != damageFace || old.found != found || old.light != light || old.angle != angle;
}

/// The deadly consequence: the burnt DTR charged again bursts (drawn
/// generically: a flash at the tank, then flame and smoke), in colour over
/// the grey scene.
class M6FlashPainter extends CustomPainter {
  const M6FlashPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final t = v.clamp(0.0, 1.0);
    final burst = Paint()
      ..color = Color.lerp(const Color(0xFFFFF6C8), const Color(0xFFFF6A1A), t)!.withValues(alpha: 0.9 * (1 - t * 0.4))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    c.drawCircle(at, 30 + 70 * t, burst);
    final flame = Paint()..color = const Color(0xFFFF8A1E).withValues(alpha: 0.9);
    for (var i = 0; i < 5; i++) {
      final x = at.dx - 40 + i * 20.0;
      c.drawPath(
        Path()
          ..moveTo(x - 10, at.dy)
          ..quadraticBezierTo(x, at.dy - 40 * t - 20, x + 10, at.dy)
          ..close(),
        flame,
      );
    }
    final smoke = Paint()..color = const Color(0xFF3A3A3A).withValues(alpha: 0.55 * t);
    for (var i = 0; i < 4; i++) {
      c.drawCircle(at.translate(-30 + i * 20.0, -50 - 40 * t - i * 6), 16 + 10 * t, smoke);
    }
  }

  @override
  bool shouldRepaint(M6FlashPainter old) => old.v != v || old.at != at;
}
