import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The site of "আর্থ মেরামত" (lesson 4.6, কাজ 2): a drawn, layered place — the
// afternoon sky, a far tree line and roofs, the field, and the hero: an LT
// feeder pillar on its plinth beside a PCC pole (the pillar's handle at OFF —
// the job is done under shutdown). Its body earth: a clamp on the pillar's
// side, the earth strip down the plinth and along the ground, and the pipe
// earth pit in front (a cover, the watering funnel, the electrode's clamp
// inside). The earth tester's two spikes go into the ground when the player
// measures (fall of potential, lesson point 3). The only words in the art
// are the ones a worker reads: "LT", "OFF".
//
// Design: 360 wide × the scene's height; the ground row follows the bottom of
// the screen (a tall phone gets more sky).

/// What can be looked at closely.
enum M4EarthFixSpot { joint, strip, pit }

/// What the fault looks like once seen (and how far the fix has come).
enum M4EarthFixLook { normal, rusty, cut, dry }

/// Where things stand (design px, 360 wide).
@immutable
class M4EarthFixGeo {
  const M4EarthFixGeo({required this.height, required this.groundY});

  factory M4EarthFixGeo.forScene(double h, double inset) => M4EarthFixGeo(height: h, groundY: (h - 300 - inset).clamp(360.0, 700.0));

  final double height;
  final double groundY;

  double get horizonY => groundY - 130;

  /// The feeder pillar (body) and its plinth.
  Rect get pillar => Rect.fromLTRB(206, groundY - 222, 322, groundY - 46);
  Rect get plinth => Rect.fromLTRB(194, groundY - 46, 334, groundY + 2);

  /// The body earth clamp on the pillar's left side.
  Offset get joint => Offset(pillar.left + 2, groundY - 116);

  /// The strip: down the plinth, then along the ground to the pit.
  Offset get stripBend => Offset(pillar.left - 8, groundY + 10);
  Offset get stripMid => Offset(pillar.left - 6, groundY - 40);

  /// The pit cover (centre) and the electrode clamp inside.
  Offset get pit => Offset(134, groundY + 30);
  Offset get funnel => Offset(pit.dx - 44, pit.dy - 14);

  Offset spot(M4EarthFixSpot s) => switch (s) {
        M4EarthFixSpot.joint => joint,
        M4EarthFixSpot.strip => stripMid,
        M4EarthFixSpot.pit => pit,
      };

  /// Where a tap reaches a spot (≥ 48 design px).
  Rect spotHit(M4EarthFixSpot s) => switch (s) {
        M4EarthFixSpot.joint => Rect.fromCenter(center: joint, width: 60, height: 56),
        M4EarthFixSpot.strip => Rect.fromCenter(center: stripMid, width: 52, height: 56),
        M4EarthFixSpot.pit => Rect.fromCenter(center: pit, width: 104, height: 56),
      };

  /// The tester's two spikes (fall of potential).
  List<Offset> get spikes => [Offset(262, groundY + 34), Offset(338, groundY + 46)];

  /// The trainee (feet on the ground, left).
  Rect get trainee => Rect.fromLTWH(10, groundY - 208, 104, 208);

  @override
  bool operator ==(Object other) => other is M4EarthFixGeo && other.height == height && other.groundY == groundY;

  @override
  int get hashCode => Object.hash(height, groundY);
}

/// The site. [looked]: spots seen up close (a ring: green fine, red the
/// fault). [fault]/[faultAt]: what is wrong and where (drawn once seen).
/// [fixed]: steps of the fix done so far (0 = nothing done); [fixSteps] in all.
class M4EarthFixWorldPainter extends CustomPainter {
  const M4EarthFixWorldPainter({
    required this.geo,
    required this.look,
    required this.faultAt,
    this.looked = const {},
    this.fixDone = 0,
    this.fixSteps = 1,
    this.spikes = false,
    this.dryDay = false,
  });

  final M4EarthFixGeo geo;
  final M4EarthFixLook look;
  final M4EarthFixSpot faultAt;
  final Set<M4EarthFixSpot> looked;
  final int fixDone;
  final int fixSteps;
  final bool spikes;
  final bool dryDay;

  bool get _seen => looked.contains(faultAt);
  bool get _fixed => fixDone >= fixSteps;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final g = geo.groundY;
    final hz = geo.horizonY;
    // Sky (a hot dry afternoon on a dry round, softer otherwise).
    final sky = dryDay ? const [Color(0xFF3F79B5), Color(0xFF9CC3DF), Color(0xFFF6E2B0)] : const [Color(0xFF2E5C8A), Color(0xFF7FA8C9), Color(0xFFEAD9B4)];
    c.drawRect(Rect.fromLTWH(0, 0, w, hz + 4), Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: sky).createShader(Rect.fromLTWH(0, 0, w, hz + 4)));
    c.drawCircle(Offset(64, hz - 96), dryDay ? 30 : 24, Paint()..color = dryDay ? const Color(0xAAFFF1C4) : const Color(0x66FFF1C4));
    final cloud = Paint()..color = const Color(0x55FFFFFF);
    for (final (x, y, r) in [(150.0, 110.0, 20.0), (176.0, 102.0, 26.0), (204.0, 112.0, 18.0), (270.0, 160.0, 16.0), (292.0, 152.0, 22.0)]) {
      c.drawCircle(Offset(x, y), r, cloud);
    }
    // Far tree line and roofs.
    final far = Path()..moveTo(0, hz);
    for (var x = 0.0; x <= w; x += 18) {
      far.lineTo(x, hz - 18 - 10 * math.sin(x * 0.06) - 6 * math.cos(x * 0.21));
    }
    far
      ..lineTo(w, hz + 2)
      ..lineTo(0, hz + 2)
      ..close();
    c.drawPath(far, Paint()..color = const Color(0xFF4F7A55));
    final roof = Paint()..color = const Color(0xFF8A4B36);
    final wall = Paint()..color = const Color(0xFFD9C7A3);
    for (final x in [30.0, 150.0]) {
      c.drawRect(Rect.fromLTWH(x, hz - 16, 30, 16), wall);
      c.drawPath(
          Path()
            ..moveTo(x - 4, hz - 16)
            ..lineTo(x + 15, hz - 30)
            ..lineTo(x + 34, hz - 16)
            ..close(),
          roof);
    }
    // Field to the yard.
    final field = dryDay ? const [Color(0xFFA9A15E), Color(0xFF8C8448)] : const [Color(0xFF7FA05A), Color(0xFF5E7F43)];
    c.drawRect(Rect.fromLTWH(0, hz, w, g - hz), Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: field).createShader(Rect.fromLTWH(0, hz, w, g - hz)));
    // The yard (dusty ground) to the bottom.
    c.drawRect(Rect.fromLTWH(0, g, w, size.height - g),
        Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFB59B74), Color(0xFF8C7556)]).createShader(Rect.fromLTWH(0, g, w, size.height - g)));
    final pebble = Paint()..color = const Color(0x33000000);
    final rnd = math.Random(5);
    for (var i = 0; i < 26; i++) {
      c.drawCircle(Offset(rnd.nextDouble() * w, g + 6 + rnd.nextDouble() * (size.height - g - 10)), 1.2 + rnd.nextDouble() * 1.6, pebble);
    }
    _pole(c);
    _pillar(c);
    _strip(c);
    _pit(c);
    if (spikes) _spikes(c);
    for (final s in looked) {
      _ring(c, s, s == faultAt && !_fixed);
    }
  }

  void _pole(Canvas c) {
    final g = geo.groundY;
    const px = 300.0;
    final top = math.max(60.0, g - 480);
    final wire = Paint()
      ..color = const Color(0xFF2A2F36)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 4; i++) {
      final y = top + 18 + i * 14;
      c.drawPath(
          Path()
            ..moveTo(0, y + 30)
            ..quadraticBezierTo(px / 2, y + 44, px, y)
            ..quadraticBezierTo(px + 30, y + 6, 360, y + 14),
          wire);
    }
    c.drawPath(
        Path()
          ..moveTo(px - 7, top)
          ..lineTo(px + 7, top)
          ..lineTo(px + 11, g - 40)
          ..lineTo(px - 11, g - 40)
          ..close(),
        Paint()..shader = const LinearGradient(colors: [Color(0xFFB9B9B2), Color(0xFF8D8D86)]).createShader(Rect.fromLTRB(px - 11, top, px + 11, g)));
    c.drawRect(Rect.fromLTWH(px - 40, top + 12, 80, 5), Paint()..color = const Color(0xFF4A4F57));
    final shackle = Paint()..color = const Color(0xFFF2F0E8);
    for (var i = 0; i < 4; i++) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(px - 34 + i * 20, top + 17, 8, 12), const Radius.circular(3)), shackle);
    }
    // The cable down into the pillar.
    c.drawLine(Offset(px - 4, top + 30), Offset(px - 4, geo.pillar.top), Paint()
      ..color = const Color(0xFF1A1D22)
      ..strokeWidth = 4);
  }

  void _pillar(Canvas c) {
    final r = geo.pillar;
    final p = geo.plinth;
    c.drawRect(p, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFB8B2A4), Color(0xFF8F897C)]).createShader(p));
    c.drawRRect(RRect.fromRectAndRadius(r.shift(const Offset(3, 4)), const Radius.circular(6)), Paint()..color = const Color(0x44000000));
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(6)), Paint()..shader = const LinearGradient(colors: [Color(0xFF6F8A78), Color(0xFF4F6857)]).createShader(r));
    // Roof cap and the two doors.
    c.drawRect(Rect.fromLTRB(r.left - 6, r.top - 8, r.right + 6, r.top + 2), Paint()..color = const Color(0xFF3F5546));
    final seam = Paint()
      ..color = const Color(0xFF34473A)
      ..strokeWidth = 2;
    c.drawLine(Offset(r.center.dx, r.top + 8), Offset(r.center.dx, r.bottom - 8), seam);
    // The handle at OFF.
    final hc = Offset(r.center.dx + 22, r.top + 58);
    c.drawCircle(hc, 9, Paint()..color = const Color(0xFF2A2F36));
    c.drawLine(hc, hc + const Offset(0, 18), Paint()
      ..color = const Color(0xFFE23B2E)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round);
    _label(c, 'OFF', Offset(hc.dx + 24, hc.dy + 8), 11, const Color(0xFFF2F0E8));
    _label(c, 'LT', Offset(r.center.dx - 28, r.top + 32), 15, const Color(0xFFFFD34E));
    // A small danger plate.
    final plate = Rect.fromCenter(center: Offset(r.center.dx - 28, r.top + 92), width: 30, height: 26);
    c.drawRect(plate, Paint()..color = const Color(0xFFF2F0E8));
    c.drawPath(
        Path()
          ..moveTo(plate.center.dx + 3, plate.top + 4)
          ..lineTo(plate.center.dx - 5, plate.center.dy + 2)
          ..lineTo(plate.center.dx + 1, plate.center.dy + 2)
          ..lineTo(plate.center.dx - 3, plate.bottom - 4)
          ..lineTo(plate.center.dx + 6, plate.center.dy - 2)
          ..lineTo(plate.center.dx, plate.center.dy - 2)
          ..close(),
        Paint()..color = const Color(0xFFD83A2E));
    // The body earth clamp (a bolt on a lug).
    final j = geo.joint;
    final rusty = look == M4EarthFixLook.rusty && faultAt == M4EarthFixSpot.joint && _seen && !_fixed;
    _clamp(c, j, rusty: rusty, shiny: look == M4EarthFixLook.rusty && faultAt == M4EarthFixSpot.joint && _fixed);
  }

  void _clamp(Canvas c, Offset at, {required bool rusty, required bool shiny}) {
    final lug = Rect.fromCenter(center: at, width: 22, height: 16);
    c.drawRRect(RRect.fromRectAndRadius(lug, const Radius.circular(3)), Paint()..color = rusty ? const Color(0xFF8A4A22) : (shiny ? const Color(0xFFE2B85A) : const Color(0xFF9AA2A8)));
    c.drawCircle(at, 5, Paint()..color = rusty ? const Color(0xFF6B3518) : (shiny ? const Color(0xFFF6D98A) : const Color(0xFFC9CED2)));
    c.drawCircle(at, 2, Paint()..color = const Color(0xFF3A3F45));
    if (rusty) {
      final flake = Paint()..color = const Color(0xFFB4642C);
      for (final o in const [Offset(-9, -6), Offset(8, 5), Offset(-6, 7), Offset(10, -4)]) {
        c.drawCircle(at + o, 2.4, flake);
      }
    }
  }

  void _strip(Canvas c) {
    final j = geo.joint;
    final b = geo.stripBend;
    final pit = geo.pit;
    final cut = look == M4EarthFixLook.cut;
    final fixedCut = cut && _fixed;
    final strip = Paint()
      ..color = fixedCut ? const Color(0xFFC9CED2) : const Color(0xFF9AA2A8)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(j.dx - 2, j.dy + 4)
      ..lineTo(b.dx, j.dy + 18)
      ..lineTo(b.dx, b.dy)
      ..lineTo(pit.dx + 30, pit.dy - 6);
    if (!cut || fixedCut) {
      c.drawPath(path, strip);
      return;
    }
    // Cut (stolen): a gap on the plinth run; once seen, the cut ends stand out.
    final gapTop = geo.stripMid.dy - 20;
    final gapBot = geo.stripMid.dy + 20;
    c.drawPath(
        Path()
          ..moveTo(j.dx - 2, j.dy + 4)
          ..lineTo(b.dx, j.dy + 18)
          ..lineTo(b.dx, gapTop),
        strip);
    c.drawPath(
        Path()
          ..moveTo(b.dx + 3, gapBot + 4)
          ..lineTo(b.dx, b.dy)
          ..lineTo(pit.dx + 30, pit.dy - 6),
        strip);
    if (_seen) {
      // The cut ends, bent out where the piece was taken.
      final bent = Paint()
        ..color = const Color(0xFF9AA2A8)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      c.drawLine(Offset(b.dx, gapTop), Offset(b.dx - 9, gapTop + 9), bent);
      c.drawLine(Offset(b.dx + 3, gapBot + 4), Offset(b.dx - 8, gapBot - 4), bent);
      final end = Paint()..color = const Color(0xFFD83A2E);
      c.drawCircle(Offset(b.dx - 9, gapTop + 9), 3.6, end);
      c.drawCircle(Offset(b.dx - 8, gapBot - 4), 3.6, end);
    }
  }

  void _pit(Canvas c) {
    final pit = geo.pit;
    final dry = look == M4EarthFixLook.dry;
    final rustyHere = look == M4EarthFixLook.rusty && faultAt == M4EarthFixSpot.pit;
    final open = looked.contains(M4EarthFixSpot.pit) && !(dry && _fixed) && !(rustyHere && _fixed);
    // The funnel pipe (pipe earthing).
    final f = geo.funnel;
    c.drawRect(Rect.fromLTWH(f.dx - 3, f.dy - 4, 6, 18), Paint()..color = const Color(0xFF7D858C));
    c.drawPath(
        Path()
          ..moveTo(f.dx - 12, f.dy - 16)
          ..lineTo(f.dx + 12, f.dy - 16)
          ..lineTo(f.dx + 3, f.dy - 4)
          ..lineTo(f.dx - 3, f.dy - 4)
          ..close(),
        Paint()..color = const Color(0xFF9AA2A8));
    // The pit chamber.
    final chamber = Rect.fromCenter(center: pit, width: 78, height: 30);
    c.drawOval(chamber.inflate(5), Paint()..color = const Color(0xFF8F897C));
    if (open) {
      final soil = dry && !_fixed
          ? const Color(0xFFC9A877)
          : (dry && fixDone >= 2 ? const Color(0xFF4E3B26) : const Color(0xFF6B5236));
      c.drawOval(chamber, Paint()..color = soil);
      if (dry && fixDone < 2) {
        // Cracked dry soil.
        final crack = Paint()
          ..color = const Color(0xFF8A6A40)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;
        for (final (a, b) in const [(Offset(-26, -4), Offset(-8, 2)), (Offset(-8, 2), Offset(6, -6)), (Offset(6, -6), Offset(24, 2)), (Offset(-8, 2), Offset(-2, 10)), (Offset(6, -6), Offset(12, 6))]) {
          c.drawLine(pit + a, pit + b, crack);
        }
      }
      // The electrode head and its clamp.
      c.drawRect(Rect.fromCenter(center: pit + const Offset(10, -2), width: 8, height: 14), Paint()..color = const Color(0xFF7D858C));
      _clamp(c, pit + const Offset(10, -6), rusty: rustyHere && _seen && !_fixed, shiny: rustyHere && _fixed);
      // The cover, lifted aside.
      c.drawOval(Rect.fromCenter(center: pit + const Offset(58, 14), width: 56, height: 16), Paint()..color = const Color(0xFF5E636A));
    } else {
      final cover = Rect.fromCenter(center: pit, width: 72, height: 24);
      c.drawOval(cover, Paint()..shader = const LinearGradient(colors: [Color(0xFF7D858C), Color(0xFF5E636A)]).createShader(cover));
      c.drawOval(cover.deflate(6), Paint()
        ..color = const Color(0xFF4A4F57)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4);
      if (dry && _fixed) {
        // Wet ground round the pit after watering.
        c.drawOval(Rect.fromCenter(center: pit + const Offset(-20, 8), width: 120, height: 26), Paint()..color = const Color(0x334E3B26));
      }
    }
  }

  void _spikes(Canvas c) {
    final pit = geo.pit;
    final lead = Paint()
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    for (final (i, s) in geo.spikes.indexed) {
      c.drawLine(s + const Offset(0, -16), s + const Offset(0, 4), Paint()
        ..color = const Color(0xFFC9CED2)
        ..strokeWidth = 3);
      c.drawCircle(s + const Offset(0, -17), 3, Paint()..color = i == 0 ? const Color(0xFFF2C230) : const Color(0xFFD83A2E));
      lead.color = i == 0 ? const Color(0xFFF2C230) : const Color(0xFFD83A2E);
      c.drawPath(
          Path()
            ..moveTo(pit.dx + 20, pit.dy + 4)
            ..quadraticBezierTo((pit.dx + s.dx) / 2, s.dy + 18 + i * 6, s.dx, s.dy - 16),
          lead);
    }
  }

  void _ring(Canvas c, M4EarthFixSpot s, bool bad) {
    final o = geo.spot(s);
    final col = bad ? const Color(0xFFE23B2E) : const Color(0xFF2FB36B);
    final r = s == M4EarthFixSpot.pit ? 46.0 : 22.0;
    c.drawOval(Rect.fromCenter(center: o, width: r * 2, height: s == M4EarthFixSpot.pit ? 44 : r * 2), Paint()
      ..color = col
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6);
    // A small badge: ✓ fine, ! fault.
    final b = o + Offset(s == M4EarthFixSpot.pit ? -46 : -20, s == M4EarthFixSpot.pit ? -22 : -20);
    c.drawCircle(b, 9, Paint()..color = col);
    if (bad) {
      c.drawLine(b + const Offset(0, -5), b + const Offset(0, 1.5), Paint()
        ..color = Colors.white
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round);
      c.drawCircle(b + const Offset(0, 4.6), 1.4, Paint()..color = Colors.white);
    } else {
      c.drawPath(
          Path()
            ..moveTo(b.dx - 4.5, b.dy)
            ..lineTo(b.dx - 1, b.dy + 3.5)
            ..lineTo(b.dx + 4.5, b.dy - 3.5),
          Paint()
            ..color = Colors.white
            ..strokeWidth = 2.2
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round);
    }
  }

  static void _label(Canvas c, String t, Offset centre, double size, Color col) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: TextStyle(fontFamily: 'Roboto', fontSize: size, fontWeight: FontWeight.w900, color: col, letterSpacing: 0.5)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(M4EarthFixWorldPainter old) =>
      old.geo != geo ||
      old.look != look ||
      old.faultAt != faultAt ||
      !setEquals(old.looked, looked) ||
      old.fixDone != fixDone ||
      old.fixSteps != fixSteps ||
      old.spikes != spikes ||
      old.dryDay != dryDay;
}

/// The deadly consequence, in colour over the grey scene: later, a fault on
/// the pillar with its earth still cut — the body goes live and nothing trips;
/// a red glow and sparks at the body and the cut ends. Non-graphic.
class M4EarthFixZapPainter extends CustomPainter {
  const M4EarthFixZapPainter({required this.body, required this.cut, required this.v});
  final Rect body;
  final Offset cut;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final flick = v < 0.6 ? (0.6 + 0.4 * math.sin(v * 50).abs()) : (1 - (v - 0.6) * 1.5).clamp(0.3, 1.0);
    // The body glows (live).
    c.drawRRect(RRect.fromRectAndRadius(body.inflate(4), const Radius.circular(8)), Paint()
      ..color = Color.fromRGBO(255, 80, 60, 0.75 * flick)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5);
    c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(6)), Paint()..color = Color.fromRGBO(255, 90, 60, 0.22 * flick));
    // Sparks at the cut ends.
    final r = 18 + 30 * Curves.easeOut.transform(v.clamp(0.0, 1.0));
    c.drawCircle(cut, r, Paint()..shader = RadialGradient(colors: [Color.fromRGBO(255, 240, 200, 0.95 * flick), const Color(0x00FF6A3A)]).createShader(Rect.fromCircle(center: cut, radius: r)));
    final spark = Paint()
      ..color = Color.fromRGBO(255, 214, 90, (1 - v).clamp(0.0, 1.0))
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 12; i++) {
      final a = i / 12 * math.pi * 2 + 0.2;
      final d0 = 8 + 30 * v;
      c.drawLine(cut + Offset(math.cos(a) * d0, math.sin(a) * d0), cut + Offset(math.cos(a) * (d0 + 10), math.sin(a) * (d0 + 10)), spark);
    }
    final white = (1 - v * 4).clamp(0.0, 1.0);
    if (white > 0) c.drawRect(Offset.zero & size, Paint()..color = Color.fromRGBO(255, 255, 255, 0.7 * white));
  }

  @override
  bool shouldRepaint(M4EarthFixZapPainter old) => old.v != v || old.body != body || old.cut != cut;
}
