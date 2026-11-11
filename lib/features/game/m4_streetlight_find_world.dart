import 'dart:math' as math;

import 'package:flutter/material.dart';

// The drawn world of lesson 4.9 কাজ 1 "অন্ধকার রাস্তা — দোষ কোথায়?"
// (m4_streetlight_find.dart): a town road at night — far houses, two lit
// street lights down the road (the rest of the street has light; only this
// one is dark), and the near pole with its luminaire opened up: the control
// gear (ballast) at the pole end, the terminal block L · N, the lamp in its
// holder under the reflector, the photocell on top. The light's own MCB is in
// a box on the pole at hand height; a ladder leans on the pole. Code-drawn,
// gradients, no bitmaps. Design space 360 wide; the road sits
// [M4StreetlightFindGeo.floorUp] above the bottom so the controls sit on it.

/// Where things are in the scene (design px, 360 wide).
@immutable
class M4StreetlightFindGeo {
  const M4StreetlightFindGeo._(this.height, this.groundY);

  factory M4StreetlightFindGeo.forScene(double height, double inset) => M4StreetlightFindGeo._(height, height - floorUp - inset * 0.5);

  final double height;

  /// The footpath line at the pole's foot.
  final double groundY;

  static const double floorUp = 104;

  // The pole and its arm.
  double get poleX => 300;
  double get fitTop => groundY - 440;
  double get poleTop => fitTop - 24;

  /// The opened luminaire.
  Rect get housing => Rect.fromLTRB(52, fitTop, 268, fitTop + 86);

  /// The control gear (ballast) box at the pole end.
  Rect get gear => Rect.fromLTWH(198, fitTop + 20, 58, 50);
  Rect get gearHit => gear.inflate(8);

  /// The terminal block (L, N) where the supply comes in.
  Rect get terminalBlock => Rect.fromLTWH(152, fitTop + 26, 36, 38);
  List<Offset> get terminals => [Offset(terminalBlock.center.dx, terminalBlock.top + 11), Offset(terminalBlock.center.dx, terminalBlock.bottom - 11)];
  Rect get terminalHit => Rect.fromLTRB(terminalBlock.left - 6, terminalBlock.top - 8, terminalBlock.right + 6, terminalBlock.bottom + 8);

  /// The lamp in its holder.
  Rect get lamp => Rect.fromLTWH(70, fitTop + 36, 58, 22);
  Rect get holder => Rect.fromLTWH(128, fitTop + 33, 16, 28);
  Rect get lampHit => Rect.fromLTRB(60, fitTop + 16, 148, fitTop + 76);

  /// The photocell on the housing's top.
  Offset get photocell => Offset(232, fitTop - 6);

  /// The light's MCB box on the pole, and its handle (tap to switch).
  Rect get mcbBox => Rect.fromLTWH(278, groundY - 206, 44, 72);
  Rect get mcbHit => Rect.fromLTRB(266, groundY - 220, 334, groundY - 124);
  Offset get mcbHandle => Offset(mcbBox.center.dx, mcbBox.center.dy + 4);

  /// The multimeter's face, while it reads (left of the pole, under the fitting).
  Rect get meterCard => Rect.fromLTWH(18, fitTop + 112, 132, 150);

  /// Where the lineman stands: by the pole, clear of the guide's corner.
  Rect get trainee => Rect.fromLTWH(196, groundY - 140, 70, 140);

  @override
  bool operator ==(Object other) => other is M4StreetlightFindGeo && other.height == height && other.groundY == groundY;

  @override
  int get hashCode => Object.hash(height, groundY);
}

/// The lamp in the fitting (lesson 4.9's own examples: 70W HPSV, 150W MH).
enum M4StreetlightFindLamp { hpsv70, mh150 }

/// What the light shows now.
@immutable
class M4StreetlightFindPoleState {
  const M4StreetlightFindPoleState({
    required this.lamp,
    required this.mcbOn,
    required this.lit,
    required this.newLamp,
    required this.newGear,
    required this.probes,
  });

  final M4StreetlightFindLamp lamp;
  final bool mcbOn;

  /// The lamp gives light.
  final bool lit;

  /// A new lamp is in the holder (bright glass) / a new gear box is in.
  final bool newLamp;
  final bool newGear;

  /// The multimeter's leads are on the terminal block.
  final bool probes;

  @override
  bool operator ==(Object other) =>
      other is M4StreetlightFindPoleState &&
      other.lamp == lamp &&
      other.mcbOn == mcbOn &&
      other.lit == lit &&
      other.newLamp == newLamp &&
      other.newGear == newGear &&
      other.probes == probes;

  @override
  int get hashCode => Object.hash(lamp, mcbOn, lit, newLamp, newGear, probes);
}

/// The lamp's rating as printed on the fitting and on a ballast.
String m4StreetlightFindRating(M4StreetlightFindLamp l) => switch (l) {
      M4StreetlightFindLamp.hpsv70 => '70W HPSV',
      M4StreetlightFindLamp.mh150 => '150W MH',
    };

/// HPSV gives yellow light, MH white (lesson 4.9 point 1).
Color m4StreetlightFindGlow(M4StreetlightFindLamp l) => switch (l) {
      M4StreetlightFindLamp.hpsv70 => const Color(0xFFFFB648),
      M4StreetlightFindLamp.mh150 => const Color(0xFFEAF2FF),
    };

/// The night street and the near pole. [warm] (0–1) is how far a lamp that
/// has just come on has warmed up: a discharge lamp takes a moment to reach
/// full light (lesson 4.9, the engineering facts).
class M4StreetlightFindStreetPainter extends CustomPainter {
  const M4StreetlightFindStreetPainter({required this.geo, required this.pole, required this.seed, this.warm = 1});

  final M4StreetlightFindGeo geo;
  final M4StreetlightFindPoleState pole;
  final int seed;
  final double warm;

  double get _glow => pole.lit ? warm.clamp(0.0, 1.0) : 0;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    // The night sky.
    c.drawRect(
        Rect.fromLTWH(0, 0, w, g.groundY),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF060B1C), Color(0xFF16233F), Color(0xFF2A3350)],
            stops: [0, 0.65, 1],
          ).createShader(Rect.fromLTWH(0, 0, w, g.groundY)));
    final rnd = math.Random(seed);
    final star = Paint()..color = const Color(0xAAE8EEFF);
    for (var i = 0; i < 26; i++) {
      c.drawCircle(Offset(rnd.nextDouble() * w, rnd.nextDouble() * (g.fitTop - 20)), 0.6 + rnd.nextDouble() * 0.9, star);
    }
    final moon = Offset(70, math.max(40, g.fitTop - 120));
    c.drawCircle(moon, 30, Paint()..shader = const RadialGradient(colors: [Color(0x44DDE6FF), Color(0x00DDE6FF)]).createShader(Rect.fromCircle(center: moon, radius: 30)));
    c.drawCircle(moon, 10, Paint()..color = const Color(0xFFE6EBF5));

    // Far houses, a few windows lit.
    final horizon = g.groundY - 120;
    final house = Paint()..color = const Color(0xFF0E1426);
    final win = Paint()..color = const Color(0xFFE7B95A);
    var x = -6.0;
    while (x < w) {
      final hw = 34 + rnd.nextDouble() * 26;
      final hh = 40 + rnd.nextDouble() * 50;
      final r = Rect.fromLTWH(x, horizon - hh, hw, hh + 6);
      c.drawRect(r, house);
      for (var k = 0; k < 3; k++) {
        if (rnd.nextDouble() < 0.4) c.drawRect(Rect.fromLTWH(r.left + 6 + k * 10, r.top + 10 + rnd.nextDouble() * 14, 5, 6), win);
      }
      x += hw + 4;
    }

    // The footpath and the road.
    final path = Rect.fromLTRB(0, horizon, w, g.groundY + 8);
    c.drawRect(path, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2B2F3A), Color(0xFF3A3E48)]).createShader(path));
    final road = Rect.fromLTRB(0, g.groundY + 8, w, size.height);
    c.drawRect(road, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF22252C), Color(0xFF15171C)]).createShader(road));
    c.drawLine(Offset(0, g.groundY + 8), Offset(w, g.groundY + 8), Paint()
      ..color = const Color(0xFF6C7078)
      ..strokeWidth = 3);
    final dash = Paint()
      ..color = const Color(0x88E8E2C8)
      ..strokeWidth = 3;
    for (var dx = 8.0; dx < w; dx += 40) {
      c.drawLine(Offset(dx, g.groundY + 52), Offset(dx + 20, g.groundY + 52), dash);
    }

    // Two far lights down the road: lit (only this pole is dark).
    _farLight(c, Offset(28, horizon - 4), 0.55);
    _farLight(c, Offset(150, horizon + 6), 0.7);

    _pole(c);
    _ladder(c);
    _fitting(c);
    _mcb(c);
  }

  void _farLight(Canvas c, Offset foot, double s) {
    final top = foot - Offset(0, 150 * s);
    c.drawLine(foot, top, Paint()
      ..color = const Color(0xFF4A505C)
      ..strokeWidth = 4 * s);
    final head = top + Offset(-22 * s, 2 * s);
    c.drawLine(top, head, Paint()
      ..color = const Color(0xFF4A505C)
      ..strokeWidth = 3 * s);
    final cone = Path()
      ..moveTo(head.dx - 5 * s, head.dy + 3 * s)
      ..lineTo(head.dx + 5 * s, head.dy + 3 * s)
      ..lineTo(head.dx + 40 * s, foot.dy + 8)
      ..lineTo(head.dx - 40 * s, foot.dy + 8)
      ..close();
    c.drawPath(cone, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x55FFC060), Color(0x00FFC060)]).createShader(cone.getBounds()));
    c.drawOval(Rect.fromCenter(center: head + Offset(0, 3 * s), width: 16 * s, height: 6 * s), Paint()..color = const Color(0xFFFFD27A));
    c.drawCircle(head, 14 * s, Paint()..shader = RadialGradient(colors: const [Color(0x88FFC060), Color(0x00FFC060)]).createShader(Rect.fromCircle(center: head, radius: 14 * s)));
  }

  void _pole(Canvas c) {
    final g = geo;
    final px = g.poleX;
    final body = Rect.fromLTRB(px - 7, g.poleTop, px + 7, g.groundY + 6);
    c.drawRect(body, Paint()..shader = const LinearGradient(colors: [Color(0xFF5B6270), Color(0xFF9AA2AE), Color(0xFF545B68)]).createShader(body));
    // Base plinth.
    c.drawRect(Rect.fromLTRB(px - 13, g.groundY - 6, px + 13, g.groundY + 8), Paint()..color = const Color(0xFF6E6A62));
    // The arm out to the fitting.
    final arm = Path()
      ..moveTo(px, g.poleTop + 6)
      ..quadraticBezierTo(px - 4, g.fitTop + 4, g.housing.right - 4, g.fitTop + 16);
    c.drawPath(arm, Paint()
      ..color = const Color(0xFF6B7280)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round);
    // The supply cable down the pole into the MCB box, up to the fitting.
    c.drawLine(Offset(px + 4, g.mcbBox.top), Offset(px + 4, g.fitTop + 18), Paint()
      ..color = const Color(0xFF1A1C20)
      ..strokeWidth = 2.5);
  }

  void _ladder(Canvas c) {
    final g = geo;
    final foot = Offset(346, g.groundY + 4);
    final top = Offset(g.poleX + 10, g.fitTop + 40);
    final rail = Paint()
      ..color = const Color(0xFFB9C1CB)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    const gap = Offset(9, 0);
    c.drawLine(foot, top, rail);
    c.drawLine(foot + gap, top + gap, rail);
    final rung = Paint()
      ..color = const Color(0xFF9AA2AD)
      ..strokeWidth = 2.2;
    for (var k = 1; k < 16; k++) {
      final p = Offset.lerp(foot, top, k / 16)!;
      c.drawLine(p, p + gap, rung);
    }
  }

  void _fitting(Canvas c) {
    final g = geo;
    final p = pole;
    final glow = _glow;
    final col = m4StreetlightFindGlow(p.lamp);

    // The light cone onto the road (when lit).
    if (glow > 0) {
      final from = g.lamp.center + const Offset(0, 14);
      final cone = Path()
        ..moveTo(g.housing.left + 6, g.housing.bottom - 2)
        ..lineTo(g.housing.left + 120, g.housing.bottom - 2)
        ..lineTo(from.dx + 150, g.groundY + 40)
        ..lineTo(from.dx - 110, g.groundY + 40)
        ..close();
      c.drawPath(
          cone,
          Paint()
            ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [col.withValues(alpha: 0.36 * glow), col.withValues(alpha: 0)])
                .createShader(cone.getBounds()));
      final pool = Rect.fromCenter(center: Offset(from.dx + 20, g.groundY + 22), width: 260, height: 50);
      c.drawOval(pool, Paint()..shader = RadialGradient(colors: [col.withValues(alpha: 0.32 * glow), col.withValues(alpha: 0)]).createShader(pool));
    }

    // The housing: a grey shell, its lower cover hinged open so the inside shows.
    final h = g.housing;
    final shell = RRect.fromRectAndCorners(h, topLeft: const Radius.circular(30), topRight: const Radius.circular(14), bottomLeft: const Radius.circular(8), bottomRight: const Radius.circular(8));
    c.drawRRect(shell.shift(const Offset(3, 4)), Paint()..color = const Color(0x55000000));
    c.drawRRect(shell, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF9AA3AE), Color(0xFF5E6672)]).createShader(h));
    final inside = RRect.fromRectAndCorners(h.deflate(6), topLeft: const Radius.circular(24), topRight: const Radius.circular(10), bottomLeft: const Radius.circular(4), bottomRight: const Radius.circular(4));
    c.drawRRect(inside, Paint()..color = const Color(0xFF2A2F37));
    // The reflector over the lamp.
    final refl = Rect.fromLTRB(h.left + 8, h.top + 8, g.holder.right + 4, h.top + 32);
    c.drawRRect(RRect.fromRectAndCorners(refl, topLeft: const Radius.circular(20)),
        Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFDDE3EA), Color(0xFF7D8794)]).createShader(refl));
    // The open cover hanging from its hinge (a glass bowl).
    final cover = Path()
      ..moveTo(h.left + 4, h.bottom)
      ..quadraticBezierTo(h.left - 8, h.bottom + 34, h.left + 6, h.bottom + 58)
      ..lineTo(h.left + 14, h.bottom + 56)
      ..quadraticBezierTo(h.left + 2, h.bottom + 32, h.left + 12, h.bottom + 2)
      ..close();
    c.drawPath(cover, Paint()..color = const Color(0x8899AABB));

    // The photocell on top (its sensor window to the sky).
    final pc = g.photocell;
    c.drawRect(Rect.fromCenter(center: pc + const Offset(0, 6), width: 14, height: 8), Paint()..color = const Color(0xFF3B414B));
    c.drawOval(Rect.fromCenter(center: pc, width: 18, height: 12), Paint()..color = const Color(0xFF222731));
    c.drawOval(Rect.fromCenter(center: pc + const Offset(0, -2), width: 10, height: 5), Paint()..color = const Color(0xFF7FA6D6));

    // The lamp's rating, printed on the housing.
    _label(c, m4StreetlightFindRating(p.lamp), Offset(h.left + 70, h.bottom - 10), 9, const Color(0xFFF2F4F7), bg: const Color(0xFF1B1F26));

    // The control gear (ballast): new = a fresh blue-grey box.
    final gr = g.gear;
    final gb = RRect.fromRectAndRadius(gr, const Radius.circular(4));
    c.drawRRect(
        gb,
        Paint()
          ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: p.newGear ? const [Color(0xFF6C93BF), Color(0xFF3C5F86)] : const [Color(0xFF6E6B60), Color(0xFF45423A)])
              .createShader(gr));
    c.drawRRect(gb, Paint()
      ..color = const Color(0xFF15171A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2);
    _label(c, 'BALLAST', Offset(gr.center.dx, gr.top + 12), 8, const Color(0xFFF1F1EC));
    _label(c, m4StreetlightFindRating(p.lamp), Offset(gr.center.dx, gr.top + 25), 7.5, const Color(0xFFE2E2D8));
    // The ignitor and the capacitor beside it (small).
    c.drawRect(Rect.fromLTWH(gr.left + 6, gr.bottom - 15, 16, 10), Paint()..color = const Color(0xFF2E3238));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(gr.right - 22, gr.bottom - 17, 14, 12), const Radius.circular(5)), Paint()..color = const Color(0xFF3F6D4A));

    // Wiring: block ↔ gear ↔ holder.
    final wire = Paint()
      ..color = const Color(0xFF151515)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final tb = g.terminalBlock;
    c.drawLine(Offset(tb.right, tb.top + 11), Offset(gr.left, gr.top + 18), wire);
    c.drawLine(Offset(tb.right, tb.bottom - 11), Offset(gr.left, gr.bottom - 14), wire);
    c.drawPath(
        Path()
          ..moveTo(gr.left + 10, gr.bottom)
          ..quadraticBezierTo(gr.left - 20, h.bottom - 6, g.holder.right - 2, g.holder.bottom - 4),
        wire);
    c.drawLine(Offset(gr.right, gr.top + 10), Offset(h.right - 4, h.top + 16), wire);

    // The terminal block: two screws, L (brown lead) and N (blue lead).
    c.drawRRect(RRect.fromRectAndRadius(tb, const Radius.circular(3)), Paint()..color = const Color(0xFFECE6D6));
    for (final (i, at) in g.terminals.indexed) {
      c.drawCircle(at, 5.5, Paint()..shader = const RadialGradient(colors: [Color(0xFFF3F4F6), Color(0xFF8B949B)]).createShader(Rect.fromCircle(center: at, radius: 5.5)));
      c.drawLine(at + const Offset(-3, 0), at + const Offset(3, 0), Paint()
        ..color = const Color(0xFF444B51)
        ..strokeWidth = 1.4);
      _label(c, i == 0 ? 'L' : 'N', at + const Offset(-12, 0), 8, const Color(0xFF2A2A2A));
    }
    if (p.probes) {
      for (final (i, at) in g.terminals.indexed) {
        final lead = i == 0 ? const Color(0xFFD63A2F) : const Color(0xFF1E1E1E);
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: at + const Offset(9, 0), width: 12, height: 6), const Radius.circular(2)), Paint()..color = lead);
        c.drawPath(
            Path()
              ..moveTo(at.dx + 15, at.dy)
              ..quadraticBezierTo(at.dx + 10, h.bottom + 60, g.meterCard.right - 30 + 8.0 * i, g.meterCard.top + 4),
            Paint()
              ..color = lead
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.8);
      }
    }

    // The holder and the lamp (tubular, horizontal).
    c.drawRRect(RRect.fromRectAndRadius(g.holder, const Radius.circular(3)), Paint()..color = const Color(0xFF3B3326));
    final lr = g.lamp;
    final lamp = RRect.fromRectAndRadius(lr, Radius.circular(lr.height / 2));
    if (glow > 0) {
      c.drawCircle(lr.center, 46, Paint()..shader = RadialGradient(colors: [col.withValues(alpha: 0.75 * glow), col.withValues(alpha: 0)]).createShader(Rect.fromCircle(center: lr.center, radius: 46)));
    }
    c.drawRRect(
        lamp,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: glow > 0
                ? [Color.lerp(const Color(0xFFDDD8CC), Colors.white, glow)!, Color.lerp(const Color(0xFFB7AE9C), col, glow)!]
                : p.newLamp
                    ? const [Color(0xFFF2F5F8), Color(0xFFC9D2DC)]
                    : const [Color(0xFFB9B2A2), Color(0xFF7D7566)],
          ).createShader(lr));
    // The arc tube inside (blackened ends on the old lamp).
    final tube = Rect.fromLTRB(lr.left + 8, lr.center.dy - 3, lr.right - 6, lr.center.dy + 3);
    c.drawRRect(RRect.fromRectAndRadius(tube, const Radius.circular(3)), Paint()..color = glow > 0 ? Colors.white : (p.newLamp ? const Color(0xFFE6E2D6) : const Color(0xFF8E8676)));
    if (!p.newLamp && glow == 0) {
      c.drawCircle(Offset(tube.left + 2, tube.center.dy), 3.4, Paint()..color = const Color(0xFF3A342B));
      c.drawCircle(Offset(tube.right - 2, tube.center.dy), 3.4, Paint()..color = const Color(0xFF3A342B));
    }
    c.drawRRect(lamp, Paint()
      ..color = const Color(0x55000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);
  }

  void _mcb(Canvas c) {
    final g = geo;
    final b = g.mcbBox;
    final box = RRect.fromRectAndRadius(b, const Radius.circular(5));
    c.drawRRect(box.shift(const Offset(2, 3)), Paint()..color = const Color(0x66000000));
    c.drawRRect(box, Paint()..shader = const LinearGradient(colors: [Color(0xFF8E979F), Color(0xFFC5CCD2), Color(0xFF7D868E)]).createShader(b));
    c.drawRRect(box, Paint()
      ..color = const Color(0xFF3E454B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3);
    // The MCB itself: a white module with its toggle (up = ON).
    final m = Rect.fromCenter(center: g.mcbHandle, width: 22, height: 40);
    c.drawRRect(RRect.fromRectAndRadius(m, const Radius.circular(3)), Paint()..color = const Color(0xFFF4F4F0));
    c.drawRRect(RRect.fromRectAndRadius(m, const Radius.circular(3)), Paint()
      ..color = const Color(0xFF6E737A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);
    final on = pole.mcbOn;
    final slot = Rect.fromCenter(center: g.mcbHandle, width: 10, height: 22);
    c.drawRect(slot, Paint()..color = const Color(0xFF2B2F35));
    final knob = Rect.fromCenter(center: g.mcbHandle + Offset(0, on ? -6 : 6), width: 12, height: 12);
    c.drawRRect(RRect.fromRectAndRadius(knob, const Radius.circular(2)), Paint()..color = on ? const Color(0xFFC8302A) : const Color(0xFF2E8B45));
    _label(c, 'MCB', Offset(b.center.dx, b.top + 9), 8.5, const Color(0xFF22282D));
    _label(c, on ? 'ON' : 'OFF', Offset(b.center.dx, b.bottom - 9), 9, on ? const Color(0xFFB0261C) : const Color(0xFF1E6B34));
  }

  void _label(Canvas c, String s, Offset centre, double size, Color color, {Color? bg}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontFamily: 'Roboto', fontSize: size, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.2)),
      textDirection: TextDirection.ltr,
    )..layout();
    final at = centre - Offset(tp.width / 2, tp.height / 2);
    if (bg != null) c.drawRRect(RRect.fromRectAndRadius((at & tp.size).inflate(2.5), const Radius.circular(3)), Paint()..color = bg);
    tp.paint(c, at);
  }

  @override
  bool shouldRepaint(M4StreetlightFindStreetPainter old) => old.geo != geo || old.pole != pole || old.seed != seed || old.warm != warm;
}

/// The multimeter's face: the LCD reads [volts] (null = nothing yet).
class M4StreetlightFindMeterPainter extends CustomPainter {
  const M4StreetlightFindMeterPainter({required this.volts});
  final int? volts;

  @override
  void paint(Canvas c, Size size) {
    final r = Offset.zero & size;
    final body = RRect.fromRectAndRadius(r.deflate(2), const Radius.circular(16));
    c.drawRRect(body, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFC94A), Color(0xFFDB8E12)]).createShader(r));
    c.drawRRect(body, Paint()
      ..color = const Color(0xFF6B4A0C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
    final face = RRect.fromRectAndRadius(Rect.fromLTWH(10, 10, size.width - 20, size.height - 20), const Radius.circular(10));
    c.drawRRect(face, Paint()..color = const Color(0xFF23272D));
    // The LCD.
    final lcd = Rect.fromLTWH(18, 18, size.width - 36, size.height * 0.34);
    c.drawRRect(RRect.fromRectAndRadius(lcd, const Radius.circular(5)), Paint()..color = const Color(0xFFB9C7A6));
    final v = volts;
    _text(c, v == null ? '- - -' : '$v', Offset(lcd.center.dx - 8, lcd.center.dy), 24, const Color(0xFF1C2416));
    _text(c, 'V~', Offset(lcd.right - 14, lcd.bottom - 10), 10, const Color(0xFF1C2416));
    // The dial, set to AC volts.
    final dial = Offset(size.width / 2, lcd.bottom + (size.height - 10 - lcd.bottom) / 2);
    c.drawCircle(dial, 22, Paint()..color = const Color(0xFF3A3F47));
    c.drawCircle(dial, 16, Paint()..color = const Color(0xFF15181C));
    final a = -math.pi * 0.75;
    c.drawLine(dial, dial + Offset(math.cos(a), math.sin(a)) * 14, Paint()
      ..color = Colors.white
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round);
    _text(c, 'V~', dial + Offset(math.cos(a), math.sin(a)) * 30, 9, const Color(0xFFFFE08A));
    _text(c, 'Ω', dial + const Offset(30, -8), 9, const Color(0xFF9AA3AD));
    _text(c, 'A', dial + const Offset(28, 14), 9, const Color(0xFF9AA3AD));
  }

  void _text(Canvas c, String s, Offset centre, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontFamily: 'Roboto', fontSize: size, fontWeight: FontWeight.w900, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(M4StreetlightFindMeterPainter old) => old.volts != volts;
}

/// The flash at the lamp holder when the live fitting is worked on (the
/// deadly moment, in colour over the frozen scene).
class M4StreetlightFindArcPainter extends CustomPainter {
  const M4StreetlightFindArcPainter({required this.geo, required this.v});
  final M4StreetlightFindGeo geo;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final at = geo.holder.center;
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
  bool shouldRepaint(M4StreetlightFindArcPainter old) => old.v != v || old.geo != geo;
}
