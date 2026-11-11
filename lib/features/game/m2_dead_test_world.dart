import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The site of the dead test (lesson 2.2 "মাল্টিমিটারের জাদু", কাজ 2): a drawn,
// layered place — the evening sky, a far tree line and village roofs, the
// lane, and the hero: an LT distribution box on a PCC pole (its LT switch at
// OFF, the outgoing terminals R Y B N) or, at a house, the service board on the
// wall (cut-out OFF, terminals P N). On the ground in front: the kit bag with
// the proving unit (the known live source the meter is proven on). The only
// words in the art are the ones a worker reads: the terminal letters, OFF,
// "LT", "PROVING UNIT".
//
// Design: 360 wide × the scene's height; the ground row follows the bottom of
// the screen (a tall phone gets more sky).

/// Which site the round is at.
enum DeadSite { threePhase, single }

/// A terminal on the box (3φ: R Y B N; 1φ: P N).
enum DeadPoint { r, y, b, n, p }

/// Where things stand (design px, 360 wide).
@immutable
class DeadGeo {
  const DeadGeo({required this.height, required this.groundY});

  factory DeadGeo.forScene(double h, double inset) => DeadGeo(height: h, groundY: (h - 300 - inset).clamp(360.0, 700.0));

  final double height;
  final double groundY;

  double get horizonY => groundY - 120;

  /// The box (3φ) or the service board (1φ).
  Rect box(DeadSite s) => s == DeadSite.threePhase
      ? Rect.fromLTRB(128, groundY - 262, 342, groundY - 104)
      : Rect.fromLTRB(150, groundY - 262, 330, groundY - 104);

  /// The terminal row.
  double get termY => groundY - 146;

  static const _x3 = {DeadPoint.r: 160.0, DeadPoint.y: 210.0, DeadPoint.b: 260.0, DeadPoint.n: 312.0};
  static const _x1 = {DeadPoint.p: 205.0, DeadPoint.n: 278.0};

  List<DeadPoint> points(DeadSite s) => s == DeadSite.threePhase ? const [DeadPoint.r, DeadPoint.y, DeadPoint.b, DeadPoint.n] : const [DeadPoint.p, DeadPoint.n];

  Offset terminal(DeadSite s, DeadPoint p) => Offset((s == DeadSite.threePhase ? _x3 : _x1)[p] ?? 200, termY);

  /// Where a tap reaches a terminal (≥ 48 design px wide).
  Rect terminalHit(DeadSite s, DeadPoint p) => Rect.fromCenter(center: terminal(s, p), width: 48, height: 64);

  /// The proving unit on the kit bag.
  Rect get prover => Rect.fromLTWH(132, groundY - 62, 82, 50);
  Rect get proverHit => prover.inflate(10);

  /// Its two test sockets.
  List<Offset> get proverSockets => [prover.topLeft + const Offset(24, 30), prover.topLeft + const Offset(58, 30)];

  /// The trainee's box (feet on the ground, left of the box).
  Rect get trainee => Rect.fromLTWH(14, groundY - 208, 104, 208);

  @override
  bool operator ==(Object other) => other is DeadGeo && other.height == height && other.groundY == groundY;

  @override
  int get hashCode => Object.hash(height, groundY);
}

String deadPointBn(DeadPoint p) => switch (p) {
      DeadPoint.r => 'R',
      DeadPoint.y => 'Y',
      DeadPoint.b => 'B',
      DeadPoint.n => 'N',
      DeadPoint.p => 'P',
    };

/// The sky, the land, the pole (or the house) and the box, the kit bag and
/// the proving unit. [lit]: terminals the probes are on now (a soft ring).
class DeadWorldPainter extends CustomPainter {
  const DeadWorldPainter({required this.geo, required this.site, this.lit = const {}, this.proverLit = false});

  final DeadGeo geo;
  final DeadSite site;
  final Set<DeadPoint> lit;
  final bool proverLit;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final g = geo.groundY;
    final hz = geo.horizonY;
    // Sky (late afternoon).
    c.drawRect(
        Rect.fromLTWH(0, 0, w, hz + 4),
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2E5C8A), Color(0xFF7FA8C9), Color(0xFFF3D9A4)])
              .createShader(Rect.fromLTWH(0, 0, w, hz + 4)));
    // The sun low behind the haze.
    c.drawCircle(Offset(70, hz - 70), 26, Paint()..color = const Color(0x66FFF1C4));
    // Clouds.
    final cloud = Paint()..color = const Color(0x55FFFFFF);
    for (final (x, y, r) in [(60.0, 120.0, 22.0), (90.0, 112.0, 28.0), (124.0, 122.0, 20.0), (250.0, 170.0, 18.0), (276.0, 162.0, 24.0), (304.0, 172.0, 17.0)]) {
      c.drawCircle(Offset(x, y), r, cloud);
    }
    // Far tree line and village roofs.
    final far = Path()..moveTo(0, hz);
    for (var x = 0.0; x <= w; x += 18) {
      far.lineTo(x, hz - 18 - 10 * math.sin(x * 0.07) - 6 * math.cos(x * 0.19));
    }
    far
      ..lineTo(w, hz + 2)
      ..lineTo(0, hz + 2)
      ..close();
    c.drawPath(far, Paint()..color = const Color(0xFF4F7A55));
    final roof = Paint()..color = const Color(0xFF8A4B36);
    final wall = Paint()..color = const Color(0xFFD9C7A3);
    for (final x in [24.0, 92.0, 300.0]) {
      c.drawRect(Rect.fromLTWH(x, hz - 16, 30, 16), wall);
      c.drawPath(
          Path()
            ..moveTo(x - 4, hz - 16)
            ..lineTo(x + 15, hz - 30)
            ..lineTo(x + 34, hz - 16)
            ..close(),
          roof);
    }
    // Fields to the lane.
    c.drawRect(Rect.fromLTWH(0, hz, w, g - hz),
        Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF7FA05A), Color(0xFF5E7F43)]).createShader(Rect.fromLTWH(0, hz, w, g - hz)));
    // The lane (dusty ground) to the bottom.
    c.drawRect(Rect.fromLTWH(0, g, w, size.height - g),
        Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFB59B74), Color(0xFF8C7556)]).createShader(Rect.fromLTWH(0, g, w, size.height - g)));
    final pebble = Paint()..color = const Color(0x33000000);
    final rnd = math.Random(3);
    for (var i = 0; i < 26; i++) {
      c.drawCircle(Offset(rnd.nextDouble() * w, g + 6 + rnd.nextDouble() * (size.height - g - 10)), 1.2 + rnd.nextDouble() * 1.6, pebble);
    }

    if (site == DeadSite.threePhase) {
      _pole(c, size);
    } else {
      _house(c, size);
    }
    _box(c);
    _kit(c);
  }

  void _pole(Canvas c, Size size) {
    final g = geo.groundY;
    const px = 300.0;
    // Wires to the far pole.
    final wire = Paint()
      ..color = const Color(0xFF2A2F36)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final top = math.max(70.0, g - 470);
    for (var i = 0; i < 4; i++) {
      final y = top + 18 + i * 14;
      c.drawPath(
          Path()
            ..moveTo(0, y + 26)
            ..quadraticBezierTo(px / 2, y + 40, px, y)
            ..quadraticBezierTo(px + 30, y + 6, 360, y + 14),
          wire);
    }
    // The PCC pole (tapered, concrete grey).
    final pole = Path()
      ..moveTo(px - 7, top)
      ..lineTo(px + 7, top)
      ..lineTo(px + 11, g + 4)
      ..lineTo(px - 11, g + 4)
      ..close();
    c.drawPath(pole, Paint()..shader = const LinearGradient(colors: [Color(0xFFB9B9B2), Color(0xFF8D8D86)]).createShader(Rect.fromLTRB(px - 11, top, px + 11, g)));
    // LT cross-arm with shackle insulators.
    final arm = Paint()..color = const Color(0xFF4A4F57);
    c.drawRect(Rect.fromLTWH(px - 40, top + 12, 80, 5), arm);
    final shackle = Paint()..color = const Color(0xFFF2F0E8);
    for (var i = 0; i < 4; i++) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(px - 34 + i * 20, top + 17, 8, 12), const Radius.circular(3)), shackle);
    }
    // The cable down to the box.
    c.drawLine(Offset(px - 4, top + 30), Offset(px - 4, geo.box(site).top), Paint()
      ..color = const Color(0xFF1A1D22)
      ..strokeWidth = 4);
    // Base shadow.
    c.drawOval(Rect.fromCenter(center: Offset(px, g + 4), width: 46, height: 8), Paint()..color = const Color(0x33000000));
  }

  void _house(Canvas c, Size size) {
    final g = geo.groundY;
    final wall = Rect.fromLTRB(120, g - 340, 372, g + 2);
    c.drawRect(wall, Paint()..shader = const LinearGradient(colors: [Color(0xFFE8D9B8), Color(0xFFCDB991)]).createShader(wall));
    // Roof edge and a window.
    c.drawRect(Rect.fromLTRB(110, g - 352, 372, g - 336), Paint()..color = const Color(0xFF7D4A33));
    c.drawRect(Rect.fromLTWH(140, g - 320, 56, 44), Paint()..color = const Color(0xFF6B8CA6));
    c.drawRect(Rect.fromLTWH(140, g - 320, 56, 44), Paint()
      ..color = const Color(0xFF5A4636)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
    // Service cable from the pole in the lane to the wall.
    c.drawPath(
        Path()
          ..moveTo(0, g - 400)
          ..quadraticBezierTo(150, g - 330, 300, g - 300)
          ..lineTo(300, geo.box(site).top),
        Paint()
          ..color = const Color(0xFF1A1D22)
          ..strokeWidth = 2.4
          ..style = PaintingStyle.stroke);
    // Plinth.
    c.drawRect(Rect.fromLTRB(120, g - 10, 372, g + 2), Paint()..color = const Color(0xFF9C8A6A));
  }

  void _box(Canvas c) {
    final r = geo.box(site);
    final three = site == DeadSite.threePhase;
    // Body (grey steel, door open to the left).
    c.drawRRect(RRect.fromRectAndRadius(r.shift(const Offset(3, 4)), const Radius.circular(6)), Paint()..color = const Color(0x44000000));
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(6)),
        Paint()..shader = LinearGradient(colors: three ? const [Color(0xFF8E9AA3), Color(0xFF6D7880)] : const [Color(0xFF7C6A54), Color(0xFF5E4F3E)]).createShader(r));
    final inner = r.deflate(9);
    c.drawRRect(RRect.fromRectAndRadius(inner, const Radius.circular(4)), Paint()..color = three ? const Color(0xFF2F363C) : const Color(0xFF3A3027));
    // The open door (seen edge-on, left).
    c.drawPath(
        Path()
          ..moveTo(r.left, r.top + 4)
          ..lineTo(r.left - 18, r.top - 6)
          ..lineTo(r.left - 18, r.bottom + 8)
          ..lineTo(r.left, r.bottom - 4)
          ..close(),
        Paint()..color = three ? const Color(0xFF5F6A72) : const Color(0xFF4E4133));
    // The switch (3φ: LT switch handle at OFF) or the cut-out (1φ: carrier out).
    final sw = Rect.fromLTWH(inner.left + 12, inner.top + 10, inner.width - 24, 52);
    c.drawRRect(RRect.fromRectAndRadius(sw, const Radius.circular(4)), Paint()..color = const Color(0xFF1C2126));
    final handle = Paint()
      ..color = const Color(0xFFE23B2E)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final hc = Offset(sw.right - 26, sw.center.dy);
    c.drawCircle(hc, 9, Paint()..color = const Color(0xFF3B434B));
    c.drawLine(hc, hc + const Offset(0, 18), handle); // pointing down = OFF
    _label(c, 'OFF', Offset(sw.right - 58, sw.center.dy + 2), 12, const Color(0xFFF2F0E8));
    _label(c, three ? 'LT' : 'MAIN', Offset(sw.left + 22, sw.center.dy + 2), 12, const Color(0xFFFFD34E));
    if (!three) {
      // The energy meter above the board.
      final m = Rect.fromLTWH(r.left + 40, r.top - 74, 100, 66);
      c.drawRRect(RRect.fromRectAndRadius(m, const Radius.circular(6)), Paint()..color = const Color(0xFFEDEDE6));
      c.drawRect(Rect.fromLTWH(m.left + 18, m.top + 12, 64, 18), Paint()..color = const Color(0xFF203A2E));
      c.drawLine(Offset(m.center.dx - 20, m.bottom), Offset(geo.terminal(site, DeadPoint.p).dx, r.top + 8), Paint()
        ..color = const Color(0xFF1A1D22)
        ..strokeWidth = 3);
    }
    // Busbar strip and the terminals.
    final bar = Rect.fromLTRB(inner.left + 8, geo.termY - 16, inner.right - 8, geo.termY + 16);
    c.drawRRect(RRect.fromRectAndRadius(bar, const Radius.circular(4)), Paint()..color = const Color(0xFF15191D));
    for (final p in geo.points(site)) {
      final o = geo.terminal(site, p);
      final col = switch (p) {
        DeadPoint.r => const Color(0xFFD83A2E),
        DeadPoint.y => const Color(0xFFF2C230),
        DeadPoint.b => const Color(0xFF2F6FD0),
        DeadPoint.p => const Color(0xFFD83A2E),
        DeadPoint.n => const Color(0xFF15191D),
      };
      // Its cable up into the switch.
      c.drawLine(Offset(o.dx, sw.bottom), Offset(o.dx, o.dy - 8), Paint()
        ..color = col == const Color(0xFF15191D) ? const Color(0xFF3A3F45) : col
        ..strokeWidth = 5);
      c.drawCircle(o, 9.5, Paint()..shader = const RadialGradient(colors: [Color(0xFFF6D98A), Color(0xFFB08A3A)]).createShader(Rect.fromCircle(center: o, radius: 9.5)));
      c.drawCircle(o, 3.2, Paint()..color = const Color(0xFF6E5420));
      if (lit.contains(p)) {
        c.drawCircle(o, 15, Paint()
          ..color = const Color(0xCCFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2);
      }
      _label(c, deadPointBn(p), Offset(o.dx, o.dy + 26), 14, const Color(0xFFF2F0E8));
    }
  }

  void _kit(Canvas c) {
    final g = geo.groundY;
    // The kit bag.
    final bag = Rect.fromLTWH(118, g - 22, 112, 26);
    c.drawRRect(RRect.fromRectAndRadius(bag, const Radius.circular(8)), Paint()..color = const Color(0xFF2F4A3A));
    c.drawRRect(RRect.fromRectAndRadius(bag.deflate(3), const Radius.circular(6)), Paint()
      ..color = const Color(0xFF223629)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);
    // The proving unit on it (yellow case, two sockets).
    final p = geo.prover;
    c.drawRRect(RRect.fromRectAndRadius(p.shift(const Offset(2, 3)), const Radius.circular(7)), Paint()..color = const Color(0x55000000));
    c.drawRRect(RRect.fromRectAndRadius(p, const Radius.circular(7)), Paint()..shader = const LinearGradient(colors: [Color(0xFFFFD34E), Color(0xFFE0A21A)]).createShader(p));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(p.left + 6, p.top + 5, p.width - 12, 13), const Radius.circular(3)), Paint()..color = const Color(0xFF2B2416));
    _label(c, 'PROVING UNIT', Offset(p.center.dx, p.top + 12), 7.5, const Color(0xFFFFE9A8));
    for (final s in geo.proverSockets) {
      c.drawCircle(s, 6.5, Paint()..color = const Color(0xFF1C1C1C));
      c.drawCircle(s, 2.4, Paint()..color = const Color(0xFF8A7A55));
    }
    if (proverLit) {
      c.drawRRect(RRect.fromRectAndRadius(p.inflate(4), const Radius.circular(9)), Paint()
        ..color = const Color(0xCCFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2);
    }
    // Shadow on the ground.
    c.drawOval(Rect.fromCenter(center: Offset(bag.center.dx, g + 5), width: 120, height: 8), Paint()..color = const Color(0x22000000));
  }

  static void _label(Canvas c, String t, Offset centre, double size, Color col) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: TextStyle(fontFamily: 'Roboto', fontSize: size, fontWeight: FontWeight.w900, color: col, letterSpacing: 0.5)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(DeadWorldPainter old) => old.geo != geo || old.site != site || !setEquals(old.lit, lit) || old.proverLit != proverLit;
}

/// The probe leads: red and black from his hands to where the tips are.
class DeadLeadsPainter extends CustomPainter {
  const DeadLeadsPainter({required this.hand, this.red, this.black, this.broken = false});
  final Offset hand;
  final Offset? red;
  final Offset? black;

  /// The red lead is cut (shown only once a proof has failed).
  final bool broken;

  @override
  void paint(Canvas c, Size size) {
    void lead(Offset? tip, Color col, double sag, bool cut) {
      final to = tip ?? hand + Offset(col == const Color(0xFFD83A2E) ? 10 : 4, 40);
      final mid = Offset((hand.dx + to.dx) / 2, math.max(hand.dy, to.dy) + sag);
      final path = Path()
        ..moveTo(hand.dx, hand.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, to.dx, to.dy);
      c.drawPath(
          path,
          Paint()
            ..color = col
            ..strokeWidth = 3
            ..style = PaintingStyle.stroke);
      if (cut) {
        final m = Offset((hand.dx + 2 * mid.dx + to.dx) / 4, (hand.dy + 2 * mid.dy + to.dy) / 4);
        c.drawCircle(m, 5, Paint()..color = const Color(0xFFFFFFFF));
        c.drawCircle(m, 5, Paint()
          ..color = const Color(0xFFE23B2E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
      }
      if (tip != null) {
        // The probe body and its metal tip.
        final dir = (to - mid);
        final d = dir.distance == 0 ? const Offset(0, -1) : dir / dir.distance;
        c.drawLine(to - d * 16, to - d * 3, Paint()
          ..color = col
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round);
        c.drawLine(to - d * 3, to, Paint()
          ..color = const Color(0xFFD7DCE0)
          ..strokeWidth = 2);
      }
    }

    lead(black, const Color(0xFF15191D), 50, false);
    lead(red, const Color(0xFFD83A2E), 36, broken);
  }

  @override
  bool shouldRepaint(DeadLeadsPainter old) => old.hand != hand || old.red != red || old.black != black || old.broken != broken;
}

/// The arc at the terminals (the deadly consequence, in colour over the grey
/// scene): a white flash, a blue-white arc between the probe tips, sparks.
/// Non-graphic.
class DeadZapPainter extends CustomPainter {
  const DeadZapPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final flick = v < 0.5 ? (0.65 + 0.35 * math.sin(v * 60).abs()) : (1 - (v - 0.5) * 1.2).clamp(0.4, 1.0);
    final r = 26 + 46 * Curves.easeOut.transform(v.clamp(0.0, 1.0));
    c.drawCircle(at, r, Paint()..shader = RadialGradient(colors: [Color.fromRGBO(220, 235, 255, 0.95 * flick), const Color(0x002F6FD0)]).createShader(Rect.fromCircle(center: at, radius: r)));
    final rnd = math.Random(9);
    final arc = Path()..moveTo(at.dx - 30, at.dy);
    for (var i = 1; i <= 6; i++) {
      arc.lineTo(at.dx - 30 + i * 10, at.dy + (rnd.nextDouble() - 0.5) * 18);
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
      final d0 = 10 + 38 * v;
      c.drawLine(at + Offset(math.cos(a) * d0, math.sin(a) * d0), at + Offset(math.cos(a) * (d0 + 12), math.sin(a) * (d0 + 12)), spark);
    }
    final white = (1 - v * 4).clamp(0.0, 1.0);
    if (white > 0) c.drawRect(Offset.zero & size, Paint()..color = Color.fromRGBO(255, 255, 255, 0.8 * white));
  }

  @override
  bool shouldRepaint(DeadZapPainter old) => old.v != v || old.at != at;
}
