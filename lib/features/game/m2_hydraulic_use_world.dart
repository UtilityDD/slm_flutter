import 'dart:math' as math;

import 'package:flutter/material.dart';

// The cable trench where the big cable is cut or crimped (lesson 2.9
// "হাইড্রোলিক ক্রিম্পার ও কাটার", কাজ 2 "কাটার আগে নিশ্চিত হও"): a drawn,
// layered place — an evening sky, a substation's gantry behind a brick wall,
// the dug-up verge and an open trench with three armoured cables on sand,
// each with its feeder tag. The page puts the tester's reading, the earth
// lead, the hydraulic head and the cut on the chosen cable. The only text in
// the art is what a worker reads: the cable tags.
//
// Design: 360 wide × the scene's height; the trench follows the bottom of the
// screen (a tall phone gets more sky).

/// Where things are (design px, 360 wide).
@immutable
class HydGeo {
  const HydGeo({required this.height, required this.trench});

  factory HydGeo.forScene(double h, double inset) {
    // Clear of the tool row, the stop button and the guide's bubble.
    final bottom = h - 252 - inset;
    return HydGeo(height: h, trench: Rect.fromLTRB(12, bottom - 166, 348, bottom));
  }

  final double height;
  final Rect trench;

  @override
  bool operator ==(Object other) => other is HydGeo && other.height == height && other.trench == trench;

  @override
  int get hashCode => Object.hash(height, trench);

  /// The verge the trainee stands on (the trench's lip).
  double get groundY => trench.top - 14;

  /// The wall's foot, behind the verge.
  double get wallY => groundY - 46;

  /// The centre line of cable [slot] (0 top … 2 bottom).
  double cableY(int slot) => trench.top + 38 + slot * 46;

  /// Where a tap picks cable [slot].
  Rect cableRect(int slot) => Rect.fromLTRB(trench.left, cableY(slot) - 19, trench.right, cableY(slot) + 19);

  /// The cable's tag (centre), a different place on each cable.
  Offset tagAt(int slot) => Offset(const [72.0, 182.0, 288.0][slot], cableY(slot) - 1);

  /// Where the tester's probe and the earth lead clip on (design x).
  static const testX = 118.0;
  static const earthX = 150.0;

  /// Where the hydraulic head sits on the cable (design x).
  static const toolX = 236.0;

  /// The trainee's box (standing on the verge, left).
  Rect get trainee => Rect.fromLTWH(18, groundY - 124, 62, 124);
}

/// The yard and the trench: sky, gantry, wall, verge, trench walls and sand.
/// Static: repaints only when the size changes.
class HydYardPainter extends CustomPainter {
  const HydYardPainter({required this.geo});
  final HydGeo geo;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final t = geo.trench;
    // Sky: dusk blue to a warm horizon.
    c.drawRect(
        Rect.fromLTRB(0, 0, w, geo.wallY + 4),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF16325C), Color(0xFF3E5F8C), Color(0xFFE7A86A)],
            stops: [0, 0.62, 1],
          ).createShader(Rect.fromLTRB(0, 0, w, geo.wallY + 4)));
    // A low sun glow.
    c.drawCircle(
        Offset(290, geo.wallY - 30),
        70,
        Paint()
          ..shader = RadialGradient(colors: [const Color(0x66FFE2A8), const Color(0x00FFE2A8)])
              .createShader(Rect.fromCircle(center: Offset(290, geo.wallY - 30), radius: 70)));
    // The substation gantry behind the wall (silhouette).
    final steel = Paint()
      ..color = const Color(0xFF26364F)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final gTop = geo.wallY - 120;
    for (final x in const [150.0, 230.0, 310.0]) {
      c.drawLine(Offset(x, geo.wallY), Offset(x, gTop), steel);
      c.drawLine(Offset(x - 10, geo.wallY), Offset(x, gTop + 16), steel..strokeWidth = 1.6);
      c.drawLine(Offset(x + 10, geo.wallY), Offset(x, gTop + 16), steel);
      steel.strokeWidth = 3;
    }
    c.drawLine(Offset(140, gTop + 8), Offset(320, gTop + 8), steel);
    c.drawLine(Offset(140, gTop + 34), Offset(320, gTop + 34), steel..strokeWidth = 2);
    // Insulator strings and the bus wires.
    final ins = Paint()..color = const Color(0xFF3A4C68);
    for (final x in const [170.0, 190.0, 250.0, 270.0, 290.0]) {
      c.drawRect(Rect.fromLTWH(x - 2, gTop + 8, 4, 16), ins);
    }
    final wire = Paint()
      ..color = const Color(0xFF1C2A40)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 3; i++) {
      final y = gTop + 26 + i * 3.0;
      c.drawPath(Path()..moveTo(0, y + 30)..quadraticBezierTo(80, y + 46, 150, y), wire);
    }
    // A transformer silhouette.
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(176, geo.wallY - 44, 40, 44), const Radius.circular(3)), Paint()..color = const Color(0xFF2A3B55));
    for (var i = 0; i < 5; i++) {
      c.drawRect(Rect.fromLTWH(172 + i * 10.0, geo.wallY - 40, 3, 36), Paint()..color = const Color(0xFF223149));
    }
    // The brick boundary wall.
    final wall = Rect.fromLTRB(0, geo.wallY - 30, w, geo.wallY);
    c.drawRect(wall, Paint()..color = const Color(0xFF9A5B3F));
    final mortar = Paint()
      ..color = const Color(0xFF7C4630)
      ..strokeWidth = 1;
    for (var row = 0; row < 5; row++) {
      final y = wall.top + row * 6.0;
      c.drawLine(Offset(0, y), Offset(w, y), mortar);
      for (var x = (row.isEven ? 0.0 : 9.0); x < w; x += 18) {
        c.drawLine(Offset(x, y), Offset(x, y + 6), mortar);
      }
    }
    c.drawRect(Rect.fromLTRB(0, wall.top - 4, w, wall.top), Paint()..color = const Color(0xFFB9B2A4));
    // The verge (dug soil) down to the bottom.
    c.drawRect(
        Rect.fromLTRB(0, geo.wallY, w, size.height),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF8C6A45), Color(0xFF6B4E31), Color(0xFF4A3420)],
          ).createShader(Rect.fromLTRB(0, geo.wallY, w, size.height)));
    // Grass tufts on the verge.
    final grass = Paint()
      ..color = const Color(0xFF5E7A3A)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final rnd = math.Random(11);
    for (var i = 0; i < 26; i++) {
      final x = rnd.nextDouble() * w;
      final y = geo.wallY + 6 + rnd.nextDouble() * (geo.groundY - geo.wallY - 4);
      c.drawLine(Offset(x, y), Offset(x - 2, y - 6), grass);
      c.drawLine(Offset(x + 2, y), Offset(x + 3, y - 5), grass);
    }
    // The spoil heap on the right of the trench lip.
    c.drawPath(
        Path()
          ..moveTo(250, geo.groundY + 2)
          ..quadraticBezierTo(300, geo.groundY - 26, 352, geo.groundY + 2)
          ..close(),
        Paint()..color = const Color(0xFF7A5A39));
    // The trench: a dark cut with lit walls and sand on the floor.
    final cut = RRect.fromRectAndRadius(t, const Radius.circular(6));
    c.drawRRect(
        cut,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2E2014), Color(0xFF4A3622), Color(0xFFB79A6A)],
            stops: [0, 0.55, 1],
          ).createShader(t));
    c.drawRect(Rect.fromLTRB(t.left, t.top, t.right, t.top + 8), Paint()..color = const Color(0xFF241810));
    c.drawRRect(
        cut,
        Paint()
          ..color = const Color(0xFF241810)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    // Sand grains on the floor.
    final sand = Paint()..color = const Color(0x55E9D3A3);
    for (var i = 0; i < 60; i++) {
      c.drawCircle(Offset(t.left + 8 + rnd.nextDouble() * (t.width - 16), t.bottom - 4 - rnd.nextDouble() * 34), 0.9, sand);
    }
    // Warning tape posts at the trench corners.
    final post = Paint()..color = const Color(0xFFE9E1CF);
    for (final x in [t.left + 4, t.right - 8]) {
      c.drawRect(Rect.fromLTWH(x, geo.groundY - 34, 4, 34), post);
    }
    final tape = Paint()
      ..color = const Color(0xFFE53935)
      ..strokeWidth = 2.4;
    c.drawLine(Offset(t.left + 6, geo.groundY - 30), Offset(t.right - 6, geo.groundY - 30), tape);
    final tapeW = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 2.4;
    for (var x = t.left + 10; x < t.right - 10; x += 16) {
      c.drawLine(Offset(x, geo.groundY - 30), Offset(x + 7, geo.groundY - 30), tapeW);
    }
  }

  @override
  bool shouldRepaint(HydYardPainter old) => old.geo != geo;
}

/// The state of one cable in the trench, as drawn.
@immutable
class HydCableLook {
  const HydCableLook({
    required this.tag,
    this.picked = false,
    this.reading,
    this.earthed = false,
    this.tool,
    this.cut = false,
    this.crimped = false,
    this.closing = 0,
  });

  final String tag;

  /// The player's chosen cable (a plain white outline, the same for any cable).
  final bool picked;

  /// The tester's reading on it: true = voltage, false = none, null = not tested.
  final bool? reading;
  final bool earthed;

  /// The hydraulic head on it: true = the cutter, false = the crimper.
  final bool? tool;

  /// Cut through (the two ends part).
  final bool cut;

  /// The lug crimped (a hex mark on the barrel).
  final bool crimped;

  /// How far the head's jaws have closed (0 … 1).
  final double closing;
}

/// The three armoured cables, their tags, the reading, the lead and the head.
class HydCablesPainter extends CustomPainter {
  const HydCablesPainter({required this.geo, required this.cables});
  final HydGeo geo;
  final List<HydCableLook> cables;

  @override
  void paint(Canvas c, Size size) {
    final t = geo.trench;
    for (var i = 0; i < cables.length; i++) {
      final look = cables[i];
      final y = geo.cableY(i);
      final gapHalf = look.cut ? 7.0 : 0.0;
      void band(double from, double to) {
        final r = Rect.fromLTRB(from, y - 9, to, y + 9);
        if (look.picked) {
          c.drawRRect(
              RRect.fromRectAndRadius(r.inflate(3.5), const Radius.circular(10)),
              Paint()
                ..color = const Color(0xEEFFFFFF)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2.6);
        }
        c.drawRRect(
            RRect.fromRectAndRadius(r, const Radius.circular(9)),
            Paint()
              ..shader = const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF4A4A4A), Color(0xFF151515), Color(0xFF2A2A2A)],
              ).createShader(r));
        // The armour's spiral lay, faint through the sheath.
        final lay = Paint()
          ..color = const Color(0x2EFFFFFF)
          ..strokeWidth = 1.2;
        for (var x = from + 6; x < to - 4; x += 9) {
          c.drawLine(Offset(x, y - 8), Offset(x + 5, y + 8), lay);
        }
      }

      if (look.cut) {
        band(t.left - 6, HydGeo.toolX - gapHalf);
        band(HydGeo.toolX + gapHalf, t.right + 6);
        // The clean cut faces: copper cores in the armour ring.
        for (final x in [HydGeo.toolX - gapHalf, HydGeo.toolX + gapHalf]) {
          c.drawCircle(Offset(x, y), 8.5, Paint()..color = const Color(0xFF8A8F96));
          for (final d in const [Offset(-3, -2.5), Offset(3, -2.5), Offset(0, 3)]) {
            c.drawCircle(Offset(x, y) + d, 2.6, Paint()..color = const Color(0xFFD9893B));
          }
        }
      } else {
        band(t.left - 6, t.right + 6);
      }
      // The tag (a yellow plate tied round the cable).
      final tagC = geo.tagAt(i);
      final plate = RRect.fromRectAndRadius(Rect.fromCenter(center: tagC, width: 44, height: 20), const Radius.circular(4));
      c.drawRRect(plate, Paint()..color = const Color(0xFFFFD34E));
      c.drawRRect(
          plate,
          Paint()
            ..color = const Color(0xFF6B5300)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2);
      final tp = TextPainter(
        text: TextSpan(text: look.tag, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFF2B2416))),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(c, tagC - Offset(tp.width / 2, tp.height / 2));
      // The earth lead: a green-yellow wire from the trench lip to a clamp.
      if (look.earthed) {
        final clamp = Offset(HydGeo.earthX, y);
        final lead = Path()
          ..moveTo(HydGeo.earthX - 30, geo.groundY - 2)
          ..quadraticBezierTo(HydGeo.earthX - 34, (geo.groundY + y) / 2, clamp.dx, clamp.dy - 8);
        c.drawPath(
            lead,
            Paint()
              ..color = const Color(0xFF2E9D4A)
              ..strokeWidth = 3.4
              ..style = PaintingStyle.stroke);
        c.drawPath(
            lead,
            Paint()
              ..color = const Color(0xFFF2D43C)
              ..strokeWidth = 1.4
              ..style = PaintingStyle.stroke);
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: clamp, width: 12, height: 22), const Radius.circular(3)), Paint()..color = const Color(0xFFB8C0C8));
        c.drawCircle(Offset(HydGeo.earthX - 30, geo.groundY - 2), 4, Paint()..color = const Color(0xFF6B737C));
      }
      // The hydraulic head round the cable.
      final tool = look.tool;
      if (tool != null) _head(c, Offset(HydGeo.toolX, y), cutter: tool, closing: look.closing, crimped: look.crimped);
    }
  }

  /// A C-head (crimper: the lug's copper barrel and the hex dies; cutter:
  /// two blades) clamped on the cable, its hose running up to the pump.
  void _head(Canvas c, Offset at, {required bool cutter, required double closing, required bool crimped}) {
    if (!cutter) {
      // The lug barrel on the cable.
      final barrel = Rect.fromCenter(center: at, width: 34, height: 15);
      c.drawRRect(
          RRect.fromRectAndRadius(barrel, const Radius.circular(4)),
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF0B070), Color(0xFFB8682C)],
            ).createShader(barrel));
      if (crimped) {
        final hex = Paint()
          ..color = const Color(0xFF7A3E12)
          ..strokeWidth = 1.4
          ..style = PaintingStyle.stroke;
        c.drawPath(_hexPath(at, 6.5), hex);
      }
    }
    final body = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE4462F), Color(0xFF8E1F12)],
      ).createShader(Rect.fromCenter(center: at, width: 60, height: 60));
    final steel = Paint()..color = const Color(0xFF9AA3AD);
    // The C frame.
    final frame = Path()
      ..addArc(Rect.fromCenter(center: at, width: 46, height: 46), math.pi * 0.25, math.pi * 1.5);
    c.drawPath(
        frame,
        Paint()
          ..color = const Color(0xFF6F7780)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 9);
    // The ram body below, the hose up to the lip.
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(at.dx - 12, at.dy + 18, 24, 30), const Radius.circular(5)), body);
    c.drawPath(
        Path()
          ..moveTo(at.dx + 10, at.dy + 40)
          ..cubicTo(at.dx + 60, at.dy + 50, at.dx + 70, geo.groundY - 30, at.dx + 50, geo.groundY - 6),
        Paint()
          ..color = const Color(0xFF111111)
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke);
    // The jaws closing on the cable.
    final gap = 13 * (1 - closing.clamp(0.0, 1.0));
    if (cutter) {
      final blade = Paint()..color = const Color(0xFFD6DCE2);
      c.drawPath(Path()..moveTo(at.dx - 7, at.dy - 9 - gap)..lineTo(at.dx + 7, at.dy - 9 - gap)..lineTo(at.dx, at.dy - gap + 2)..close(), blade);
      c.drawPath(Path()..moveTo(at.dx - 7, at.dy + 9 + gap)..lineTo(at.dx + 7, at.dy + 9 + gap)..lineTo(at.dx, at.dy + gap - 2)..close(), blade);
    } else {
      c.drawRect(Rect.fromLTWH(at.dx - 8, at.dy - 16 - gap, 16, 7), steel);
      c.drawRect(Rect.fromLTWH(at.dx - 8, at.dy + 9 + gap, 16, 7), steel);
    }
  }

  @override
  bool shouldRepaint(HydCablesPainter old) => old.geo != geo || !_same(old.cables, cables);

  static bool _same(List<HydCableLook> a, List<HydCableLook> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final x = a[i];
      final y = b[i];
      if (x.tag != y.tag ||
          x.picked != y.picked ||
          x.reading != y.reading ||
          x.earthed != y.earthed ||
          x.tool != y.tool ||
          x.cut != y.cut ||
          x.crimped != y.crimped ||
          x.closing != y.closing) {
        return false;
      }
    }
    return true;
  }
}

Path _hexPath(Offset c, double r) {
  final p = Path();
  for (var i = 0; i < 6; i++) {
    final a = math.pi / 3 * i;
    final o = c + Offset(math.cos(a) * r, math.sin(a) * r);
    if (i == 0) {
      p.moveTo(o.dx, o.dy);
    } else {
      p.lineTo(o.dx, o.dy);
    }
  }
  return p..close();
}

/// Where the free hand can go in the close-up (design px of a 300 × 170 card).
enum HydZone { jaws, cable, handle }

/// The close-up card's zones (300 × 170).
Rect hydZoneRect(HydZone z) => switch (z) {
      HydZone.jaws => const Rect.fromLTWH(54, 30, 72, 92),
      HydZone.cable => const Rect.fromLTWH(0, 56, 52, 44),
      HydZone.handle => const Rect.fromLTWH(196, 40, 104, 92),
    };

/// The close-up of the tool on the cable: the head round the cable (or the
/// lug), the pump body and its handle, the pressure gauge. [hand]: where the
/// trainee's free hand is (null = not placed yet).
class HydCloseupPainter extends CustomPainter {
  const HydCloseupPainter({
    required this.cutter,
    required this.closing,
    required this.done,
    this.hand,
    this.locked = false,
  });

  final bool cutter;
  final double closing;
  final bool done;
  final HydZone? hand;
  final bool locked;

  @override
  void paint(Canvas c, Size size) {
    final k = size.width / 300;
    c.save();
    c.scale(k);
    final cy = 78.0;
    final head = const Offset(90, 78);
    // The cable through the head (cut: it parts at the blades).
    final cable = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF555555), Color(0xFF151515), Color(0xFF333333)],
      ).createShader(Rect.fromLTWH(0, cy - 16, 300, 32));
    final part = cutter && done ? 10.0 : 0.0;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(-10, cy - 15, head.dx - part, cy + 15), const Radius.circular(12)), cable);
    if (!cutter) {
      // The lug: copper barrel over the bare conductor, then its palm.
      final barrel = Rect.fromLTRB(head.dx - 26, cy - 12, head.dx + 30, cy + 12);
      c.drawRRect(
          RRect.fromRectAndRadius(barrel, const Radius.circular(5)),
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF4BC7E), Color(0xFFB0602A)],
            ).createShader(barrel));
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(head.dx + 30, cy - 9, head.dx + 70, cy + 9), const Radius.circular(9)), Paint()..color = const Color(0xFFD08A48));
      c.drawCircle(Offset(head.dx + 56, cy), 4.5, Paint()..color = const Color(0xFF3B2A1A));
      if (done) c.drawPath(_hexPath(head, 10), Paint()..color = const Color(0xFF7A3E12)..style = PaintingStyle.stroke..strokeWidth = 2);
    } else {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(head.dx + part, cy - 15, 150, cy + 15), const Radius.circular(12)), cable);
    }
    // The C head.
    c.drawPath(
        Path()..addArc(Rect.fromCenter(center: head, width: 84, height: 84), math.pi * 0.3, math.pi * 1.4),
        Paint()
          ..color = const Color(0xFF6F7780)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 15);
    // The safety lock: a latch across the C's mouth (closed or swung open).
    final latch = Paint()
      ..color = locked ? const Color(0xFF2E9D4A) : const Color(0xFF9AA3AD)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    if (cutter) {
      if (locked) {
        c.drawLine(head + const Offset(26, -30), head + const Offset(26, 30), latch);
      } else {
        c.drawLine(head + const Offset(26, -30), head + const Offset(48, -52), latch);
      }
    }
    // The jaws (dies or blades).
    final gap = 18 * (1 - closing.clamp(0.0, 1.0));
    final steel = Paint()..color = const Color(0xFFCDD3DA);
    if (cutter) {
      c.drawPath(Path()..moveTo(head.dx - 10, cy - 20 - gap)..lineTo(head.dx + 10, cy - 20 - gap)..lineTo(head.dx, cy - gap + 4)..close(), steel);
      c.drawPath(Path()..moveTo(head.dx - 10, cy + 20 + gap)..lineTo(head.dx + 10, cy + 20 + gap)..lineTo(head.dx, cy + gap - 4)..close(), steel);
    } else {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(head.dx - 14, cy - 30 - gap, 28, 14), const Radius.circular(3)), steel);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(head.dx - 14, cy + 16 + gap, 28, 14), const Radius.circular(3)), steel);
    }
    // The ram and the pump body, the handle on the right.
    final red = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE4462F), Color(0xFF8E1F12)],
      ).createShader(const Rect.fromLTWH(70, 110, 230, 50));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(74, 118, 34, 40), const Radius.circular(6)), red);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(104, 128, 120, 22), const Radius.circular(8)), red);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(206, 96, 86, 18), const Radius.circular(9)), Paint()..color = const Color(0xFF222222));
    c.drawLine(const Offset(214, 112), const Offset(214, 130), Paint()..color = const Color(0xFF6F7780)..strokeWidth = 6);
    // The pressure gauge.
    const g = Offset(160, 106);
    c.drawCircle(g, 17, Paint()..color = const Color(0xFFF2F2EE));
    c.drawCircle(g, 17, Paint()..color = const Color(0xFF3A3F46)..style = PaintingStyle.stroke..strokeWidth = 3);
    c.drawArc(Rect.fromCircle(center: g, radius: 12), math.pi * 0.75, math.pi * 1.5, false,
        Paint()..color = const Color(0xFFBFC5CC)..style = PaintingStyle.stroke..strokeWidth = 3);
    c.drawArc(Rect.fromCircle(center: g, radius: 12), math.pi * 1.95, math.pi * 0.3, false,
        Paint()..color = const Color(0xFF2E9D4A)..style = PaintingStyle.stroke..strokeWidth = 3);
    final a = math.pi * 0.75 + math.pi * 1.5 * closing.clamp(0.0, 1.0);
    c.drawLine(g, g + Offset(math.cos(a) * 13, math.sin(a) * 13), Paint()..color = const Color(0xFFC0392B)..strokeWidth = 2.2..strokeCap = StrokeCap.round);
    // The free hand, once placed (a gloved hand, drawn plainly).
    final h = hand;
    if (h != null) {
      final at = hydZoneRect(h).center;
      final glove = Paint()..color = const Color(0xFFC8A15A);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: at, width: 30, height: 22), const Radius.circular(9)), glove);
      for (var i = 0; i < 4; i++) {
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(at.dx - 14 + i * 7.5, at.dy - 22, 6, 14), const Radius.circular(3)), glove);
      }
      c.drawRect(Rect.fromLTWH(at.dx - 12, at.dy + 10, 24, 12), Paint()..color = const Color(0xFF1F5F8F));
    }
    c.restore();
  }

  @override
  bool shouldRepaint(HydCloseupPainter old) =>
      old.cutter != cutter || old.closing != closing || old.done != done || old.hand != hand || old.locked != locked;
}
