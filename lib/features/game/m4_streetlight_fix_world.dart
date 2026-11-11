import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

// The drawn world of lesson 4.9 কাজ 2 "আলো ফেরাও" (m4_streetlight_fix.dart):
// a town street corner at dusk — a steel street-light pole on the footpath
// with its number plate, the bracket arm and the luminaire (photocell on
// top), the feeder pillar with the street-light MCBs (each tagged with its
// pole's number), a neighbouring street light further down the road, the
// ladder (leaning on the pole, tied with rope), the scrap crate for old lamps
// and a dustbin; sometimes an LT line on its own pole close to one side.
// Code-drawn, gradients, no bitmaps. Design space 360 wide; the footpath sits
// [M4StreetlightFixGeo.floorUp] above the bottom so the controls sit on the road.

enum M4StreetlightFixSide { left, right }

/// What is wrong with the bad ladder spot.
enum M4StreetlightFixBadSpot { line, slab }

/// Where things are in the scene (design px, 360 wide).
@immutable
class M4StreetlightFixGeo {
  const M4StreetlightFixGeo._(this.height, this.groundY);

  factory M4StreetlightFixGeo.forScene(double height, double inset) => M4StreetlightFixGeo._(height, height - floorUp - inset * 0.5);

  final double height;

  /// The footpath's top (where the pole and the ladder stand).
  final double groundY;

  static const double floorUp = 104;
  static const double poleX = 196;

  double get poleTop => groundY - 300;

  /// The luminaire at the end of the bracket arm.
  Rect get luminaire => Rect.fromLTWH(250, poleTop - 4, 56, 18);
  Offset get lampGlow => Offset(luminaire.center.dx, luminaire.bottom + 2);

  /// The pole's number plate.
  Rect get plate => Rect.fromCenter(center: Offset(poleX, groundY - 98), width: 38, height: 18);

  /// The feeder pillar and its two street-light MCBs (slot 0 left, 1 right).
  Rect get pillar => Rect.fromLTRB(296, groundY - 128, 354, groundY);
  Rect mcb(int slot) => Rect.fromLTWH(305 + 24.0 * slot, groundY - 92, 18, 34);
  Rect mcbHit(int slot) => Rect.fromCenter(center: mcb(slot).center, width: 26, height: 64);

  /// The ladder's foot on each side of the pole, and where its top rests.
  Offset foot(M4StreetlightFixSide s) => Offset(s == M4StreetlightFixSide.left ? 128 : 264, groundY - 2);
  Offset ladderTop(M4StreetlightFixSide s) => Offset(s == M4StreetlightFixSide.left ? poleX - 8 : poleX + 8, poleTop + 34);
  Rect spotHit(M4StreetlightFixSide s) => Rect.fromCenter(center: foot(s) - const Offset(0, 22), width: 62, height: 72);
  Rect spotRing(M4StreetlightFixSide s) => Rect.fromCenter(center: foot(s) - const Offset(0, 8), width: 46, height: 22);

  /// Tap the standing ladder (its foot) to climb or come down (kept below
  /// the raised corner guide).
  Rect ladderHit(M4StreetlightFixSide s) {
    final f = foot(s);
    final t = ladderTop(s);
    return Rect.fromLTRB(math.min(f.dx, t.dx) - 10, groundY - 84, math.max(f.dx, t.dx) + 10, groundY);
  }

  /// The LT line's pole (only when it is the bad spot): close on the left.
  double get ltPoleX => 150;
  double get ltArmY => poleTop + 44;

  /// The scrap crate for old lamps and the dustbin, at the back of the footpath.
  Rect get crate => Rect.fromLTWH(146, groundY - 30, 42, 28);
  Rect get crateHit => crate.inflate(10);
  Rect get dustbin => Rect.fromLTWH(222, groundY - 40, 26, 38);
  Rect get dustbinHit => dustbin.inflate(10);

  /// The neighbouring street light down the road (smaller, further back).
  Offset get farLamp => const Offset(62, 0) + Offset(0, groundY - 236);

  /// The trainee on the footpath, or on the ladder near its top.
  Rect get traineeDown => Rect.fromLTWH(214, groundY - 140, 70, 140);
  Rect traineeUp(M4StreetlightFixSide s) {
    final f = foot(s);
    final t = ladderTop(s);
    final feetY = poleTop + 120;
    final k = (f.dy - feetY) / (f.dy - t.dy);
    final x = f.dx + (t.dx - f.dx) * k;
    return Rect.fromLTWH(x - 35 + (s == M4StreetlightFixSide.left ? -6 : 6), feetY - 140, 70, 140);
  }

  @override
  bool operator ==(Object other) => other is M4StreetlightFixGeo && other.height == height && other.groundY == groundY;

  @override
  int get hashCode => Object.hash(height, groundY);
}

/// What the street shows now.
@immutable
class M4StreetlightFixView {
  const M4StreetlightFixView({
    required this.badSide,
    required this.badKind,
    required this.poleNo,
    required this.mcbNos,
    required this.mcbOn,
    required this.ladder,
    required this.tied,
    required this.lightOn,
    required this.farOn,
    required this.oldInHand,
    required this.inCrate,
    required this.inBin,
  });

  final M4StreetlightFixSide badSide;
  final M4StreetlightFixBadSpot badKind;
  final int poleNo;

  /// The pole number on each MCB's tag (slot 0, slot 1).
  final List<int> mcbNos;
  final List<bool> mcbOn;
  final M4StreetlightFixSide? ladder;
  final bool tied;
  final bool lightOn;
  final bool farOn;
  final bool oldInHand;
  final bool inCrate;
  final bool inBin;

  @override
  bool operator ==(Object other) =>
      other is M4StreetlightFixView &&
      other.badSide == badSide &&
      other.badKind == badKind &&
      other.poleNo == poleNo &&
      listEquals(other.mcbNos, mcbNos) &&
      listEquals(other.mcbOn, mcbOn) &&
      other.ladder == ladder &&
      other.tied == tied &&
      other.lightOn == lightOn &&
      other.farOn == farOn &&
      other.oldInHand == oldInHand &&
      other.inCrate == inCrate &&
      other.inBin == inBin;

  @override
  int get hashCode => Object.hash(badSide, badKind, poleNo, Object.hashAll(mcbNos), Object.hashAll(mcbOn), ladder, tied, lightOn, farOn, oldInHand, inCrate, inBin);
}

void _text(Canvas c, String s, Offset centre, double size, Color color, {bool bn = false}) {
  // The app's Bangla face carries Latin letters and digits too (one font for all labels).
  final style = bangla(fontSize: size, fontWeight: bn ? FontWeight.w800 : FontWeight.w900, color: color, height: 1.0);
  final tp = TextPainter(text: TextSpan(text: s, style: style), textDirection: TextDirection.ltr)..layout();
  tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
}

/// The street at dusk: sky, houses, road, footpath, the poles, the pillar,
/// the ladder. Static (repaints only when [view] changes).
class M4StreetlightFixStreetPainter extends CustomPainter {
  const M4StreetlightFixStreetPainter({required this.geo, required this.view, required this.seed});

  final M4StreetlightFixGeo geo;
  final M4StreetlightFixView view;
  final int seed;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final v = view;
    final w = size.width;
    // Dusk sky.
    final skyR = Rect.fromLTWH(0, 0, w, g.groundY);
    c.drawRect(
        skyR,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1B2547), Color(0xFF4B4677), Color(0xFFD9895A)],
            stops: [0, 0.55, 1],
          ).createShader(skyR));
    final rnd = math.Random(seed);
    final star = Paint()..color = const Color(0x99FFFFFF);
    for (var i = 0; i < 14; i++) {
      c.drawCircle(Offset(rnd.nextDouble() * w, rnd.nextDouble() * g.poleTop * 0.7), 0.9, star);
    }
    // Houses and shops down the street (silhouettes, a few lit windows).
    final back = g.groundY - 34;
    var x = -6.0;
    var i = 0;
    while (x < w) {
      final bw = 40 + rnd.nextDouble() * 36;
      final bh = 90 + rnd.nextDouble() * 110;
      final r = Rect.fromLTWH(x, back - bh, bw, bh);
      c.drawRect(r, Paint()..color = i.isEven ? const Color(0xFF2C2A44) : const Color(0xFF34304F));
      for (var wy = r.top + 12; wy < r.bottom - 16; wy += 22) {
        for (var wx = r.left + 8; wx < r.right - 10; wx += 16) {
          final lit = rnd.nextDouble() < 0.35;
          c.drawRect(Rect.fromLTWH(wx, wy, 7, 10), Paint()..color = lit ? const Color(0xFFF6C66B) : const Color(0xFF1E1C30));
        }
      }
      x += bw + 2;
      i++;
    }
    // The far footpath edge.
    c.drawRect(Rect.fromLTWH(0, back, w, 34), Paint()..color = const Color(0xFF3B3A48));

    _farLight(c);
    if (v.badKind == M4StreetlightFixBadSpot.line) _ltLine(c, w);

    // The footpath (slabs) and its kerb, the road in front.
    final path = Rect.fromLTRB(0, g.groundY - 22, w, g.groundY + 12);
    c.drawRect(path, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8D8A82), Color(0xFF6E6B64)]).createShader(path));
    final joint = Paint()
      ..color = const Color(0x55000000)
      ..strokeWidth = 1;
    for (var jx = 18.0; jx < w; jx += 40) {
      c.drawLine(Offset(jx, path.top), Offset(jx - 8, path.bottom), joint);
    }
    final kerb = Rect.fromLTRB(0, g.groundY + 12, w, g.groundY + 22);
    c.drawRect(kerb, Paint()..color = const Color(0xFFB9B3A6));
    for (var kx = 0.0; kx < w; kx += 24) {
      c.drawRect(Rect.fromLTWH(kx, kerb.top, 12, kerb.height), Paint()..color = const Color(0xFF2B2B2B));
    }
    final road = Rect.fromLTRB(0, g.groundY + 22, w, size.height);
    c.drawRect(road, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3A3B40), Color(0xFF232428)]).createShader(road));
    final dash = Paint()..color = const Color(0xCCEDE6D2);
    for (var dx = 6.0; dx < w; dx += 46) {
      c.drawRect(Rect.fromLTWH(dx, g.groundY + 58, 24, 3), dash);
    }
    if (v.badKind == M4StreetlightFixBadSpot.slab) _brokenSlab(c, g.foot(v.badSide));

    _dustbin(c);
    _crate(c);
    _pole(c);
    _pillar(c);
    final l = v.ladder;
    if (l != null) _ladder(c, l);
  }

  void _farLight(Canvas c) {
    final g = geo;
    final base = g.farLamp + const Offset(0, 190);
    final top = g.farLamp;
    c.drawLine(base, top, Paint()
      ..color = const Color(0xFF5B6270)
      ..strokeWidth = 3.4);
    c.drawLine(top, top + const Offset(26, 2), Paint()
      ..color = const Color(0xFF5B6270)
      ..strokeWidth = 2.4);
    final head = Rect.fromLTWH(top.dx + 18, top.dy, 18, 7);
    c.drawRRect(RRect.fromRectAndRadius(head, const Radius.circular(3)), Paint()..color = const Color(0xFF48505C));
    if (view.farOn) {
      final o = head.bottomCenter + const Offset(0, 2);
      c.drawCircle(o, 40, Paint()..shader = const RadialGradient(colors: [Color(0x88FFD58A), Color(0x00FFD58A)]).createShader(Rect.fromCircle(center: o, radius: 40)));
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(head.left + 2, head.bottom - 2, 14, 3), const Radius.circular(2)), Paint()..color = const Color(0xFFFFE6A8));
    }
  }

  void _ltLine(Canvas c, double w) {
    final g = geo;
    final x = g.ltPoleX;
    final base = g.groundY - 20;
    final top = g.ltArmY - 22;
    final pole = Rect.fromLTRB(x - 4, top, x + 4, base);
    c.drawRect(pole, Paint()..shader = const LinearGradient(colors: [Color(0xFF6D6A63), Color(0xFF9B978E), Color(0xFF6D6A63)]).createShader(pole));
    final arm = Rect.fromLTRB(x - 30, g.ltArmY - 3, x + 30, g.ltArmY + 3);
    c.drawRect(arm, Paint()..color = const Color(0xFF555A60));
    final wire = Paint()
      ..color = const Color(0xFF14161A)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    for (var k = 0; k < 4; k++) {
      final px = x - 24 + 16.0 * k;
      c.drawCircle(Offset(px, g.ltArmY - 6), 2.6, Paint()..color = const Color(0xFFEDE9DF));
      c.drawPath(
          Path()
            ..moveTo(px, g.ltArmY - 7)
            ..quadraticBezierTo(px - 60, g.ltArmY + 16, -10, g.ltArmY - 4 + 3.0 * k),
          wire);
    }
  }

  void _brokenSlab(Canvas c, Offset f) {
    final r = Rect.fromCenter(center: f - const Offset(0, 6), width: 54, height: 22);
    c.drawRect(r, Paint()..color = const Color(0xFF2A2622));
    final crack = Paint()
      ..color = const Color(0xFF8D8A82)
      ..style = PaintingStyle.fill;
    c.drawPath(
        Path()
          ..moveTo(r.left, r.top)
          ..lineTo(r.left + 20, r.top + 6)
          ..lineTo(r.left + 12, r.top + 14)
          ..lineTo(r.left, r.top + 10)
          ..close(),
        crack);
    c.drawPath(
        Path()
          ..moveTo(r.right, r.top + 2)
          ..lineTo(r.right - 16, r.top + 9)
          ..lineTo(r.right - 6, r.bottom)
          ..lineTo(r.right, r.bottom)
          ..close(),
        crack);
    // A tilted broken piece over the drain.
    c.save();
    c.translate(r.center.dx, r.center.dy);
    c.rotate(-0.22);
    c.drawRect(const Rect.fromLTWH(-12, -6, 22, 7), Paint()..color = const Color(0xFF7A776F));
    c.restore();
  }

  void _pole(Canvas c) {
    final g = geo;
    const x = M4StreetlightFixGeo.poleX;
    final body = Path()
      ..moveTo(x - 7, g.groundY)
      ..lineTo(x - 4, g.poleTop)
      ..lineTo(x + 4, g.poleTop)
      ..lineTo(x + 7, g.groundY)
      ..close();
    c.drawPath(body, Paint()..shader = const LinearGradient(colors: [Color(0xFF59616B), Color(0xFFA9B1BA), Color(0xFF59616B)]).createShader(Rect.fromLTRB(x - 7, g.poleTop, x + 7, g.groundY)));
    // Base plinth.
    c.drawRect(Rect.fromLTRB(x - 12, g.groundY - 10, x + 12, g.groundY + 2), Paint()..color = const Color(0xFF7E7A70));
    // The bracket arm and the luminaire.
    final arm = Paint()
      ..color = const Color(0xFF7E8791)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    c.drawPath(
        Path()
          ..moveTo(x, g.poleTop + 6)
          ..quadraticBezierTo(x + 14, g.poleTop - 16, g.luminaire.left + 4, g.luminaire.top + 6),
        arm);
    final lum = g.luminaire;
    final shell = Path()
      ..moveTo(lum.left, lum.top + 6)
      ..quadraticBezierTo(lum.left + 6, lum.top - 2, lum.center.dx, lum.top - 1)
      ..quadraticBezierTo(lum.right, lum.top, lum.right, lum.top + 10)
      ..lineTo(lum.right - 4, lum.bottom - 4)
      ..lineTo(lum.left + 4, lum.bottom - 4)
      ..close();
    c.drawPath(shell, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF9AA3AD), Color(0xFF4F5761)]).createShader(lum));
    // Photocell on top.
    c.drawRect(Rect.fromLTWH(lum.center.dx - 4, lum.top - 7, 8, 6), Paint()..color = const Color(0xFF2F3338));
    c.drawCircle(Offset(lum.center.dx, lum.top - 7), 3.2, Paint()..color = const Color(0xFFB9C7D6));
    final glass = Rect.fromLTRB(lum.left + 5, lum.bottom - 5, lum.right - 5, lum.bottom - 1);
    if (view.lightOn) {
      final o = g.lampGlow;
      c.drawCircle(o + const Offset(0, 30), 90, Paint()..shader = const RadialGradient(colors: [Color(0x99FFD58A), Color(0x00FFD58A)]).createShader(Rect.fromCircle(center: o + const Offset(0, 30), radius: 90)));
      final cone = Path()
        ..moveTo(glass.left, glass.bottom)
        ..lineTo(glass.right, glass.bottom)
        ..lineTo(glass.right + 50, g.groundY + 20)
        ..lineTo(glass.left - 50, g.groundY + 20)
        ..close();
      c.drawPath(cone, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x55FFE2A6), Color(0x00FFE2A6)]).createShader(Rect.fromLTRB(glass.left - 50, glass.bottom, glass.right + 50, g.groundY + 20)));
      c.drawRRect(RRect.fromRectAndRadius(glass, const Radius.circular(2)), Paint()..color = const Color(0xFFFFF0C2));
    } else {
      c.drawRRect(RRect.fromRectAndRadius(glass, const Radius.circular(2)), Paint()..color = const Color(0xFF3A3F47));
    }
    // The number plate.
    final p = RRect.fromRectAndRadius(g.plate, const Radius.circular(3));
    c.drawRRect(p, Paint()..color = const Color(0xFFF2EFE6));
    c.drawRRect(p, Paint()
      ..color = const Color(0xFF1F3C68)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4);
    _text(c, 'SL-${view.poleNo}', g.plate.center, 9, const Color(0xFF1F3C68));
  }

  void _pillar(Canvas c) {
    final g = geo;
    final r = g.pillar;
    c.drawRRect(RRect.fromRectAndRadius(r.shift(const Offset(2, 2)), const Radius.circular(4)), Paint()..color = const Color(0x55000000));
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)), Paint()..shader = const LinearGradient(colors: [Color(0xFF6F8A6A), Color(0xFF4D6649)]).createShader(r));
    // Its door stands open: the panel inside.
    final panel = Rect.fromLTRB(r.left + 4, r.top + 24, r.right - 4, r.bottom - 10);
    c.drawRect(panel, Paint()..color = const Color(0xFFE6E2D6));
    c.drawRect(Rect.fromLTRB(r.left + 2, r.top + 2, r.right - 2, r.top + 20), Paint()..color = const Color(0xFF3D5239));
    _text(c, 'SL', Offset(r.center.dx, r.top + 11), 8.5, const Color(0xFFF2EFE6));
    for (var s = 0; s < 2; s++) {
      final m = g.mcb(s);
      final on = view.mcbOn[s];
      _text(c, 'SL-${view.mcbNos[s]}', Offset(m.center.dx, m.top - 8), 6.4, const Color(0xFF1E2226));
      c.drawRRect(RRect.fromRectAndRadius(m, const Radius.circular(2)), Paint()..color = const Color(0xFFF8F7F2));
      c.drawRRect(RRect.fromRectAndRadius(m, const Radius.circular(2)), Paint()
        ..color = const Color(0xFF8A8F96)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);
      // The toggle: up = ON (red window), down = OFF (green window).
      final tog = Rect.fromCenter(center: Offset(m.center.dx, m.center.dy + (on ? -6 : 6)), width: 9, height: 12);
      c.drawRRect(RRect.fromRectAndRadius(tog, const Radius.circular(2)), Paint()..color = const Color(0xFF2B2F35));
      c.drawRect(Rect.fromCenter(center: Offset(m.center.dx, m.bottom - 5), width: 10, height: 4), Paint()..color = on ? const Color(0xFFD03A2C) : const Color(0xFF2E9A4E));
      _text(c, on ? 'ON' : 'OFF', Offset(m.center.dx, m.bottom + 7), 6.2, on ? const Color(0xFFB0261C) : const Color(0xFF1E6B34));
    }
  }

  void _crate(Canvas c) {
    final r = geo.crate;
    c.drawRect(r, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFD9822B), Color(0xFFA85E19)]).createShader(r));
    c.drawRect(r, Paint()
      ..color = const Color(0xFF6A3A0E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2);
    _text(c, 'বাতিল ল্যাম্প', Offset(r.center.dx, r.center.dy + 3), 6.6, const Color(0xFF2B1604), bn: true);
    if (view.inCrate) _oldLamp(c, Offset(r.center.dx, r.top - 3), 0.2);
  }

  void _dustbin(Canvas c) {
    final r = geo.dustbin;
    final body = Path()
      ..moveTo(r.left, r.top + 5)
      ..lineTo(r.right, r.top + 5)
      ..lineTo(r.right - 3, r.bottom)
      ..lineTo(r.left + 3, r.bottom)
      ..close();
    c.drawPath(body, Paint()..color = const Color(0xFF2F6E4A));
    c.drawRect(Rect.fromLTWH(r.left - 2, r.top + 1, r.width + 4, 5), Paint()..color = const Color(0xFF235238));
    if (view.inBin) _oldLamp(c, Offset(r.center.dx, r.top), -0.5);
  }

  void _oldLamp(Canvas c, Offset at, double angle) {
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(angle);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-10, -3, 16, 6), const Radius.circular(3)), Paint()..color = const Color(0xFFCFC6A8));
    c.drawRect(const Rect.fromLTWH(6, -2.4, 5, 4.8), Paint()..color = const Color(0xFF9A8F72));
    c.restore();
  }

  void _ladder(Canvas c, M4StreetlightFixSide s) {
    final g = geo;
    final f = g.foot(s);
    final t = g.ladderTop(s);
    final dir = (t - f);
    final len = dir.distance;
    final n = Offset(-dir.dy, dir.dx) / len;
    const half = 7.0;
    final rail = Paint()
      ..color = const Color(0xFFB98A4C)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    c.drawLine(f + n * half, t + n * half, rail);
    c.drawLine(f - n * half, t - n * half, rail);
    final rung = Paint()
      ..color = const Color(0xFF9C7139)
      ..strokeWidth = 2.2;
    for (var d = 14.0; d < len - 6; d += 17) {
      final p = f + dir * (d / len);
      c.drawLine(p + n * half, p - n * half, rung);
    }
    // Rubber feet.
    c.drawCircle(f + n * half, 2.6, Paint()..color = const Color(0xFF1E1E1E));
    c.drawCircle(f - n * half, 2.6, Paint()..color = const Color(0xFF1E1E1E));
    if (view.tied) {
      final rope = Paint()
        ..color = const Color(0xFFE2B33C)
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke;
      for (final k in [0.93, 0.55]) {
        final p = f + dir * k;
        c.drawOval(Rect.fromCenter(center: Offset((p.dx + M4StreetlightFixGeo.poleX) / 2, p.dy), width: (p.dx - M4StreetlightFixGeo.poleX).abs() + 22, height: 7), rope);
      }
    }
  }

  @override
  bool shouldRepaint(M4StreetlightFixStreetPainter old) => old.geo != geo || old.view != view || old.seed != seed;
}

/// The harness's lanyard round the pole and the old lamp in his hand.
class M4StreetlightFixHarnessPainter extends CustomPainter {
  const M4StreetlightFixHarnessPainter({required this.box, required this.up, required this.harness, required this.oldLamp});
  final Rect box;
  final bool up;
  final bool harness;
  final bool oldLamp;

  @override
  void paint(Canvas c, Size size) {
    final hip = Offset(box.center.dx, box.top + box.height * 0.52);
    if (harness) {
      final belt = Paint()
        ..color = const Color(0xFF1F2A3A)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      c.drawLine(hip + const Offset(-11, 0), hip + const Offset(11, 0), belt);
      c.drawLine(Offset(box.center.dx - 8, box.top + box.height * 0.3), hip + const Offset(-6, 0), belt..strokeWidth = 2);
      c.drawLine(Offset(box.center.dx + 8, box.top + box.height * 0.3), hip + const Offset(6, 0), belt);
      if (up) {
        const px = M4StreetlightFixGeo.poleX;
        final strap = Paint()
          ..color = const Color(0xFF3A2A16)
          ..strokeWidth = 2.6
          ..style = PaintingStyle.stroke;
        final far = hip.dx < px ? px + 9 : px - 9;
        c.drawPath(
            Path()
              ..moveTo(hip.dx, hip.dy)
              ..quadraticBezierTo(px, hip.dy - 12, far, hip.dy - 8)
              ..moveTo(hip.dx, hip.dy + 2)
              ..quadraticBezierTo(px, hip.dy + 4, far, hip.dy - 8),
            strap);
      }
    }
    if (oldLamp) {
      final at = Offset(box.center.dx + 20, box.top + box.height * 0.55);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: at, width: 18, height: 7), const Radius.circular(3)), Paint()..color = const Color(0xFFCFC6A8));
      c.drawRect(Rect.fromLTWH(at.dx + 8, at.dy - 2.5, 5, 5), Paint()..color = const Color(0xFF9A8F72));
    }
  }

  @override
  bool shouldRepaint(M4StreetlightFixHarnessPainter old) => old.box != box || old.up != up || old.harness != harness || old.oldLamp != oldLamp;
}

/// The flash at the luminaire (the deadly beat, in colour over the grey scene).
class M4StreetlightFixFlashPainter extends CustomPainter {
  const M4StreetlightFixFlashPainter({required this.geo, required this.v});
  final M4StreetlightFixGeo geo;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final o = geo.luminaire.centerLeft + const Offset(4, 6);
    final r = 18 + 70 * v;
    c.drawCircle(o, r, Paint()..shader = RadialGradient(colors: [Color.fromRGBO(255, 255, 255, 0.95 * (1 - v * 0.4)), Color.fromRGBO(120, 190, 255, 0.6 * (1 - v * 0.5)), const Color(0x0078BEFF)]).createShader(Rect.fromCircle(center: o, radius: r)));
    final bolt = Paint()
      ..color = const Color(0xFFBFE3FF)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;
    final rnd = math.Random(3);
    for (var k = 0; k < 6; k++) {
      final a = k * math.pi / 3 + 0.3;
      final path = Path()..moveTo(o.dx, o.dy);
      var p = o;
      for (var s = 0; s < 4; s++) {
        p = p + Offset(math.cos(a), math.sin(a)) * (8 + 10 * v) + Offset(rnd.nextDouble() * 8 - 4, rnd.nextDouble() * 8 - 4);
        path.lineTo(p.dx, p.dy);
      }
      c.drawPath(path, bolt);
    }
  }

  @override
  bool shouldRepaint(M4StreetlightFixFlashPainter old) => old.v != v || old.geo != geo;
}

// ============================================================================
// The open luminaire, close up (the card the player works in at the top)
// ============================================================================

/// The gear inside the luminaire.
enum M4StreetlightFixGear { hpsv70, mh150, led }

/// What the close-up shows.
@immutable
class M4StreetlightFixInside {
  const M4StreetlightFixInside({required this.gear, required this.loose, required this.tightened, required this.fitted, required this.driverHeld});
  final M4StreetlightFixGear gear;

  /// The loose, corroded terminal (0 L, 1 N, 2 E).
  final int loose;
  final bool tightened;

  /// The new part is in.
  final bool fitted;

  /// The screwdriver is in hand (the terminals ringed).
  final bool driverHeld;

  @override
  bool operator ==(Object other) =>
      other is M4StreetlightFixInside && other.gear == gear && other.loose == loose && other.tightened == tightened && other.fitted == fitted && other.driverHeld == driverHeld;

  @override
  int get hashCode => Object.hash(gear, loose, tightened, fitted, driverHeld);
}

/// Where the terminals are in the close-up (fractions of its size).
abstract final class M4StreetlightFixInsideGeo {
  static Offset terminal(int i, Size s) => Offset(s.width * (0.42 + 0.085 * i), s.height * 0.56);
  static Rect terminalHit(int i, Size s) => Rect.fromCenter(center: terminal(i, s), width: s.width * 0.085, height: s.height * 0.42);
  static const labels = ['L', 'N', 'E'];
}

class M4StreetlightFixInsidePainter extends CustomPainter {
  const M4StreetlightFixInsidePainter({required this.inside});
  final M4StreetlightFixInside inside;

  @override
  void paint(Canvas c, Size s) {
    final r = Offset.zero & s;
    // The open housing.
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(14)), Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8E98A3), Color(0xFF5A636D)]).createShader(r));
    final tray = Rect.fromLTRB(s.width * 0.04, s.height * 0.12, s.width * 0.96, s.height * 0.9);
    c.drawRRect(RRect.fromRectAndRadius(tray, const Radius.circular(10)), Paint()..color = const Color(0xFFD9DDE1));
    // The gear box (its label is what the player matches).
    final gearBox = Rect.fromLTWH(s.width * 0.07, s.height * 0.22, s.width * 0.27, s.height * 0.56);
    c.drawRRect(RRect.fromRectAndRadius(gearBox, const Radius.circular(5)), Paint()..shader = const LinearGradient(colors: [Color(0xFF3E4650), Color(0xFF262C33)]).createShader(gearBox));
    final label = Rect.fromCenter(center: gearBox.center, width: gearBox.width * 0.86, height: gearBox.height * 0.42);
    c.drawRect(label, Paint()..color = const Color(0xFFF2EFE6));
    final (l1, l2) = switch (inside.gear) {
      M4StreetlightFixGear.hpsv70 => ('BALLAST', 'HPSV 70W'),
      M4StreetlightFixGear.mh150 => ('BALLAST', 'MH 150W'),
      M4StreetlightFixGear.led => ('LED', 'DRIVER'),
    };
    _text(c, l1, label.center - Offset(0, label.height * 0.22), s.height * 0.07, const Color(0xFF444A52));
    _text(c, l2, label.center + Offset(0, label.height * 0.18), s.height * 0.085, const Color(0xFF15191E));
    // Wires from the gear to the terminal block.
    final wireCols = [const Color(0xFFC0392B), const Color(0xFF1F1F1F), const Color(0xFF2E9A4E)];
    for (var i = 0; i < 3; i++) {
      final t = M4StreetlightFixInsideGeo.terminal(i, s);
      final loose = i == inside.loose && !inside.tightened;
      final end = loose ? t + Offset(s.width * 0.02, -s.height * 0.16) : t + Offset(0, -s.height * 0.06);
      c.drawPath(
          Path()
            ..moveTo(gearBox.right, gearBox.top + gearBox.height * (0.3 + 0.2 * i))
            ..quadraticBezierTo(t.dx - s.width * 0.05, s.height * 0.2, end.dx, end.dy),
          Paint()
            ..color = wireCols[i]
            ..strokeWidth = 3
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round);
      if (loose) {
        // Bare, corroded strands, out of the terminal.
        c.drawCircle(end, s.height * 0.025, Paint()..color = const Color(0xFF5E8F62));
        c.drawCircle(end + const Offset(2, 2), s.height * 0.018, Paint()..color = const Color(0xFF8B5A2B));
      }
    }
    // The terminal block.
    final block = Rect.fromLTRB(s.width * 0.37, s.height * 0.46, s.width * 0.64, s.height * 0.68);
    c.drawRRect(RRect.fromRectAndRadius(block, const Radius.circular(4)), Paint()..color = const Color(0xFF2B2F35));
    for (var i = 0; i < 3; i++) {
      final t = M4StreetlightFixInsideGeo.terminal(i, s);
      final loose = i == inside.loose && !inside.tightened;
      c.drawCircle(t, s.height * 0.04, Paint()..color = loose ? const Color(0xFF7F8A6E) : const Color(0xFFC9CED4));
      c.drawLine(t - Offset(s.height * 0.025, 0), t + Offset(s.height * 0.025, 0), Paint()
        ..color = const Color(0xFF3A3F45)
        ..strokeWidth = 1.6);
      if (loose) c.drawCircle(t + const Offset(-3, 3), s.height * 0.02, Paint()..color = const Color(0xCC4E8A55));
      _text(c, M4StreetlightFixInsideGeo.labels[i], Offset(t.dx, block.bottom + s.height * 0.05), s.height * 0.06, const Color(0xFF2B2F35));
      if (inside.driverHeld) {
        c.drawCircle(t, s.height * 0.07, Paint()
          ..color = const Color(0xFFFFE08A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
      }
    }
    // The lamp (or the LED module) on the right.
    final lampArea = Rect.fromLTRB(s.width * 0.68, s.height * 0.2, s.width * 0.93, s.height * 0.82);
    final fresh = inside.fitted;
    switch (inside.gear) {
      case M4StreetlightFixGear.led:
        final board = Rect.fromCenter(center: lampArea.center, width: lampArea.width * 0.9, height: lampArea.height * 0.7);
        c.drawRRect(RRect.fromRectAndRadius(board, const Radius.circular(4)), Paint()..color = fresh ? const Color(0xFF1E5F3A) : const Color(0xFF3B3F2F));
        for (var yy = 0; yy < 4; yy++) {
          for (var xx = 0; xx < 3; xx++) {
            final p = Offset(board.left + board.width * (0.22 + 0.28 * xx), board.top + board.height * (0.16 + 0.22 * yy));
            c.drawCircle(p, s.height * 0.025, Paint()..color = fresh ? const Color(0xFFFFF4C8) : (xx + yy).isEven ? const Color(0xFF6B5A2E) : const Color(0xFF8E8A70));
          }
        }
      case M4StreetlightFixGear.hpsv70:
      case M4StreetlightFixGear.mh150:
        // The holder, then the bulb.
        final holder = Rect.fromLTWH(lampArea.left, lampArea.center.dy - s.height * 0.08, lampArea.width * 0.28, s.height * 0.16);
        c.drawRRect(RRect.fromRectAndRadius(holder, const Radius.circular(3)), Paint()..color = const Color(0xFFEDE7D6));
        final bulb = Rect.fromLTRB(holder.right - 2, lampArea.center.dy - s.height * 0.1, lampArea.right, lampArea.center.dy + s.height * 0.1);
        final hp = inside.gear == M4StreetlightFixGear.hpsv70;
        final glass = fresh ? const Color(0xFFF4F1E6) : const Color(0xFFB7AE95);
        c.drawRRect(RRect.fromRectAndRadius(hp ? Rect.fromCenter(center: bulb.center, width: bulb.width, height: bulb.height * 0.62) : bulb, Radius.circular(hp ? 8 : 20)), Paint()..color = glass);
        final arc = Rect.fromCenter(center: bulb.center, width: bulb.width * 0.6, height: s.height * 0.035);
        c.drawRRect(RRect.fromRectAndRadius(arc, const Radius.circular(3)), Paint()..color = fresh ? (hp ? const Color(0xFFF2B65A) : const Color(0xFFCFE3F2)) : const Color(0xFF5C5340));
        if (!fresh) {
          // The old lamp's blackened ends.
          c.drawCircle(Offset(bulb.left + 6, bulb.center.dy), s.height * 0.03, Paint()..color = const Color(0x664A3A20));
          c.drawCircle(Offset(bulb.right - 6, bulb.center.dy), s.height * 0.03, Paint()..color = const Color(0x664A3A20));
        }
    }
  }

  @override
  bool shouldRepaint(M4StreetlightFixInsidePainter old) => old.inside != inside;
}
