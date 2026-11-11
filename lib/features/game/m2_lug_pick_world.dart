import 'dart:math' as math;

import 'package:flutter/material.dart';

// The workshop for lesson 2.3, কাজ 1 "সঠিক ল্যাগ": a drawn scene — a back
// wall with a window and a pegboard of crimping tools (hydraulic crimper, hand
// crimper, wire brush, cable knife), a wooden bench seen from the front, a vice
// at the back holding the new cable's end, and a parts tray of lugs in front
// (the lugs, the cable's print and the trainee are widgets on it). No text in
// the art. Design: 360 wide × any height; the bench stands on the floor row,
// so a tall phone gets more wall, never a stretched bench.
//
// Also here: the lug itself (side view, end view) and the strip bench (the
// cable end and the lug laid beside it to measure the strip).

/// Where things are, in design pixels (360 × [h]).
@immutable
class LugBenchGeo {
  const LugBenchGeo(this.h);
  final double h;

  /// The bench's front edge (the top of its front face).
  double get top => h - 196;

  /// The bench top, seen from the front and a little above.
  Rect get surface => Rect.fromLTRB(0, top - 64, 360, top);
  Rect get front => Rect.fromLTRB(0, top, 360, top + 28);

  /// The vice at the back of the bench; the cable runs through its jaws.
  Rect get vice => Rect.fromLTRB(72, top - 96, 128, top - 32);

  double get cableY => top - 62;
  static const cableT = 15.0;
  double get cableEnd => 206;

  /// The cable's visible run right of the vice (tap it to read its print).
  Rect get cableTap => Rect.fromLTRB(130, cableY - 16, cableEnd + 4, cableY + 16);

  /// Where the sheath print sits.
  Rect get print => Rect.fromLTRB(134, cableY - cableT / 2, cableEnd - 6, cableY + cableT / 2);

  /// A lug fitted on the cable's end.
  Rect get fitted => Rect.fromLTWH(cableEnd - 18, cableY - 10, 50, 20);

  /// The parts tray in front.
  Rect get tray => Rect.fromLTRB(212, top - 50, 354, top - 4);

  /// Compartment [i] of [n]: a lug lies in it.
  Rect slot(int i, int n) {
    final t = tray.deflate(4);
    final w = t.width / n;
    return Rect.fromLTWH(t.left + w * i, t.top, w, t.height);
  }

  /// Lugs set aside, at the bench's left front.
  Rect aside(int i) => Rect.fromLTWH(140 + i * 22.0, top - 30, 20, 26);

  /// The trainee, behind the bench on the left (the bench hides his legs).
  Rect get trainee => Rect.fromLTWH(-2, top - 150, 76, 152);

  Rect get wall => Rect.fromLTRB(0, 0, 360, top - 64);
}

/// The back wall: plaster, a window with daylight, a pegboard of tools.
class LugWallPainter extends CustomPainter {
  const LugWallPainter(this.geo);
  final LugBenchGeo geo;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final wall = Rect.fromLTWH(0, 0, w, geo.surface.top + 2);
    c.drawRect(
      wall,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7E9A8C), Color(0xFFA9BFB0), Color(0xFFC7D3C4)],
        ).createShader(wall),
    );
    // A dado band at the bottom of the wall.
    c.drawRect(Rect.fromLTRB(0, geo.surface.top - 46, w, geo.surface.top + 2), Paint()..color = const Color(0xFF6F8A7C));
    c.drawRect(Rect.fromLTRB(0, geo.surface.top - 48, w, geo.surface.top - 45), Paint()..color = const Color(0xFF5C7568));

    // The window (daylight, a far pole and line), upper left.
    final pb = Rect.fromLTRB(150, geo.surface.top - 250, 350, geo.surface.top - 64);
    final win = Rect.fromLTRB(16, pb.top + 6, 132, pb.top + 120);
    c.drawRRect(RRect.fromRectAndRadius(win.inflate(6), const Radius.circular(4)), Paint()..color = const Color(0xFF5A4632));
    c.drawRect(
      win,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8FC3E6), Color(0xFFD5EAF2)],
        ).createShader(win),
    );
    c.save();
    c.clipRect(win);
    final far = Paint()..color = const Color(0xFF8CA4B4);
    c.drawRect(Rect.fromLTWH(win.left + 78, win.top + 30, 4, 90), far);
    c.drawRect(Rect.fromLTWH(win.left + 66, win.top + 36, 28, 3), far);
    c.drawLine(Offset(win.left - 4, win.top + 44), Offset(win.right + 4, win.top + 40), Paint()
      ..color = const Color(0xFF6E8696)
      ..strokeWidth = 1.2);
    c.drawOval(Rect.fromLTWH(win.left + 8, win.top + 14, 44, 14), Paint()..color = const Color(0xCCFFFFFF));
    c.drawRect(Rect.fromLTWH(win.left, win.bottom - 24, win.width, 24), Paint()..color = const Color(0xFF9DB07A));
    c.restore();
    final bar = Paint()..color = const Color(0xFF5A4632);
    c.drawRect(Rect.fromLTWH(win.center.dx - 2, win.top, 4, win.height), bar);
    c.drawRect(Rect.fromLTWH(win.left, win.center.dy - 2, win.width, 4), bar);
    c.drawLine(Offset(win.left + 10, win.bottom - 10), Offset(win.left + 30, win.top + 14), Paint()
      ..color = const Color(0x55FFFFFF)
      ..strokeWidth = 4);

    // The pegboard.
    c.drawRRect(RRect.fromRectAndRadius(pb.shift(const Offset(2, 4)), const Radius.circular(4)), Paint()..color = const Color(0x33000000));
    c.drawRRect(RRect.fromRectAndRadius(pb, const Radius.circular(4)), Paint()..color = const Color(0xFFC9A877));
    final hole = Paint()..color = const Color(0xFF8E7148);
    for (var y = pb.top + 10; y < pb.bottom - 4; y += 14) {
      for (var x = pb.left + 10; x < pb.right - 4; x += 14) {
        c.drawCircle(Offset(x, y), 1.4, hole);
      }
    }
    _hydraulic(c, Offset(pb.left + 18, pb.top + 22));
    _handCrimper(c, Offset(pb.left + 112, pb.top + 22));
    _brush(c, Offset(pb.left + 160, pb.top + 24));
    _knife(c, Offset(pb.left + 112, pb.top + 128));
    // A coil of cable on a hook.
    final coil = Paint()
      ..color = const Color(0xFF26292D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    for (var i = 0; i < 3; i++) {
      c.drawOval(Rect.fromCenter(center: Offset(pb.left + 44 + i * 3.0, pb.top + 140), width: 58, height: 44), coil);
    }

    // A lamp hangs over the bench.
    final lx = 250.0;
    c.drawLine(Offset(lx, 0), Offset(lx, pb.top - 20), Paint()
      ..color = const Color(0xFF3B3F45)
      ..strokeWidth = 1.6);
    final shade = Path()
      ..moveTo(lx - 8, pb.top - 26)
      ..lineTo(lx + 8, pb.top - 26)
      ..lineTo(lx + 26, pb.top - 6)
      ..lineTo(lx - 26, pb.top - 6)
      ..close();
    c.drawPath(shade, Paint()..color = const Color(0xFF3F6E5A));
    c.drawOval(Rect.fromCenter(center: Offset(lx, pb.top - 5), width: 22, height: 7), Paint()..color = const Color(0xFFFFF2C2));
  }

  void _hydraulic(Canvas c, Offset o) {
    // Head (C-frame with the die) and two long handles.
    final steel = Paint()..color = const Color(0xFF6C747C);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(o.dx, o.dy, 34, 30), const Radius.circular(10)), steel);
    c.drawCircle(o + const Offset(17, 15), 7, Paint()..color = const Color(0xFFC9A877));
    c.drawRect(Rect.fromLTWH(o.dx + 10, o.dy + 28, 14, 18), Paint()..color = const Color(0xFF8E969E));
    final red = Paint()
      ..color = const Color(0xFFC0392B)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final yel = Paint()
      ..color = const Color(0xFFE2B33C)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    c.drawLine(o + const Offset(13, 46), o + const Offset(6, 118), red);
    c.drawLine(o + const Offset(21, 46), o + const Offset(36, 116), yel);
  }

  void _handCrimper(Canvas c, Offset o) {
    final jaw = Paint()..color = const Color(0xFF7D858C);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(o.dx, o.dy, 20, 22), const Radius.circular(5)), jaw);
    final grip = Paint()
      ..color = const Color(0xFF2F5FA8)
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    c.drawLine(o + const Offset(6, 22), o + const Offset(2, 76), grip);
    c.drawLine(o + const Offset(14, 22), o + const Offset(22, 76), grip);
  }

  void _brush(Canvas c, Offset o) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(o.dx, o.dy, 9, 58), const Radius.circular(3)), Paint()..color = const Color(0xFF9A6A3A));
    final bristle = Paint()
      ..color = const Color(0xFFB9BEC2)
      ..strokeWidth = 1;
    for (var i = 0; i < 9; i++) {
      c.drawLine(Offset(o.dx + 9, o.dy + 4 + i * 4.0), Offset(o.dx + 15, o.dy + 4 + i * 4.0), bristle);
    }
  }

  void _knife(Canvas c, Offset o) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(o.dx, o.dy, 38, 9), const Radius.circular(4)), Paint()..color = const Color(0xFFE2B33C));
    final blade = Path()
      ..moveTo(o.dx + 38, o.dy + 1)
      ..lineTo(o.dx + 66, o.dy + 3)
      ..quadraticBezierTo(o.dx + 60, o.dy + 10, o.dx + 38, o.dy + 9)
      ..close();
    c.drawPath(blade, Paint()..color = const Color(0xFFCBD1D6));
  }

  @override
  bool shouldRepaint(LugWallPainter old) => old.geo.h != geo.h;
}

/// The bench, the vice and the cable (drawn over the trainee's legs).
class LugBenchPainter extends CustomPainter {
  const LugBenchPainter(this.geo, {required this.al});
  final LugBenchGeo geo;

  /// The cable's conductor is aluminium (else copper): its cut end shows it.
  final bool al;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final h = s.height;
    // The floor.
    final floor = Rect.fromLTWH(0, geo.front.bottom - 6, w, h - geo.front.bottom + 6);
    c.drawRect(
      floor,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6A645A), Color(0xFF4B463F)],
        ).createShader(floor),
    );
    final tile = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 1;
    for (var x = -40.0; x < w + 40; x += 48) {
      c.drawLine(Offset(x + 24, floor.top), Offset(x - 30, h), tile);
    }
    // Legs and the shelf under the bench.
    final leg = Paint()..color = const Color(0xFF6B4A2B);
    for (final x in [14.0, 330.0]) {
      c.drawRect(Rect.fromLTWH(x, geo.front.bottom, 16, 96), leg);
    }
    c.drawRect(Rect.fromLTWH(14, geo.front.bottom + 64, 332, 8), Paint()..color = const Color(0xFF5B3E24));
    c.drawOval(Rect.fromLTRB(-10, geo.front.bottom + 92, w + 10, geo.front.bottom + 112), Paint()..color = const Color(0x33000000));

    // The bench top and its front face.
    final top = geo.surface;
    c.drawRect(
      top,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFA77A4A), Color(0xFFC79A64)],
        ).createShader(top),
    );
    final grain = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 1;
    for (var y = top.top + 9; y < top.bottom; y += 11) {
      c.drawLine(Offset(0, y), Offset(w, y + 2), grain);
    }
    final fr = geo.front;
    c.drawRect(
      fr,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8A5E33), Color(0xFF6B4524)],
        ).createShader(fr),
    );
    c.drawRect(Rect.fromLTWH(0, fr.top, w, 2.5), Paint()..color = const Color(0xFFD9B07A));

    // The tray (its lugs are widgets in it).
    final tr = geo.tray;
    c.drawRRect(RRect.fromRectAndRadius(tr.shift(const Offset(2, 3)), const Radius.circular(5)), Paint()..color = const Color(0x44000000));
    c.drawRRect(
      RRect.fromRectAndRadius(tr, const Radius.circular(5)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2E4F7A), Color(0xFF1F3858)],
        ).createShader(tr),
    );
    c.drawRRect(RRect.fromRectAndRadius(tr.deflate(3), const Radius.circular(3)), Paint()..color = const Color(0xFF16263B));

    // The cable: from the left edge through the vice to its cut end.
    final y = geo.cableY;
    const t = LugBenchGeo.cableT;
    final end = geo.cableEnd;
    final sheath = Rect.fromLTRB(-4, y - t / 2, end, y + t / 2);
    c.drawRRect(
      RRect.fromRectAndRadius(sheath, const Radius.circular(3)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3A3E44), Color(0xFF15171A), Color(0xFF2A2D31)],
        ).createShader(sheath),
    );
    // The cut end shows the conductor's metal.
    c.drawOval(Rect.fromCenter(center: Offset(end, y), width: 6, height: t), Paint()..color = const Color(0xFF15171A));
    c.drawOval(Rect.fromCenter(center: Offset(end + 0.5, y), width: 4, height: t * 0.68), Paint()..color = metalMid(al));

    // The vice: base on the bench, a jaw each side of the cable, the screw handle.
    final v = geo.vice;
    final iron = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF4F7FB0), Color(0xFF2C527B)],
      ).createShader(v);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(v.left - 6, v.bottom - 10, v.right + 6, v.bottom), const Radius.circular(3)), iron);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(v.left + 6, y + t / 2 + 1, v.right - 6, v.bottom - 8), const Radius.circular(3)), iron);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(v.left + 6, v.top, v.right - 6, y - t / 2 - 1), const Radius.circular(3)), iron);
    final jaw = Paint()..color = const Color(0xFF8E969E);
    c.drawRect(Rect.fromLTRB(v.left + 4, y - t / 2 - 5, v.right - 4, y - t / 2 - 1), jaw);
    c.drawRect(Rect.fromLTRB(v.left + 4, y + t / 2 + 1, v.right - 4, y + t / 2 + 5), jaw);
    c.drawLine(Offset(v.center.dx, v.top - 2), Offset(v.center.dx, v.top - 22), Paint()
      ..color = const Color(0xFF9AA3AB)
      ..strokeWidth = 4);
    c.drawLine(Offset(v.center.dx - 16, v.top - 22), Offset(v.center.dx + 16, v.top - 22), Paint()
      ..color = const Color(0xFF9AA3AB)
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(LugBenchPainter old) => old.geo.h != geo.h || old.al != al;
}

// ---------------------------------------------------------------------------
// The lug
// ---------------------------------------------------------------------------

/// Light, mid and dark tones of the metal.
Color metalLight(bool al) => al ? const Color(0xFFF1F4F6) : const Color(0xFFF2B47A);
Color metalMid(bool al) => al ? const Color(0xFFBCC3C9) : const Color(0xFFC77A3C);
Color metalDark(bool al) => al ? const Color(0xFF7A838B) : const Color(0xFF7E431C);

/// How many stretches the barrel is looked at in.
const kLugBins = 16;
int lugBin(double u) => (u * kLugBins).floor().clamp(0, kLugBins - 1);

/// A tube lug, side view, lying lengthwise: the barrel's mouth at the left,
/// the palm with its bolt hole at the right. A crack in the barrel shows
/// only where the hand has been ([seenBarrel]: stretches of [kLugBins]; null
/// = all seen); unseen stretches are washed with [veil] when it is set.
/// [glass] draws the barrel see-through (the strip bench shows the conductor
/// inside it).
class LugSidePainter extends CustomPainter {
  LugSidePainter({required this.al, this.crack = false, this.seenBarrel, this.veil, this.glass = false});
  final bool al;
  final bool crack;
  final Set<int>? seenBarrel;
  final Color? veil;
  final bool glass;

  static const crackU = 0.55;

  static double barrelX0(Size s) => s.width * 0.03;
  static double barrelX1(Size s) => s.width * 0.6;

  /// How far along the barrel (0 mouth … 1 bottom) [x] is.
  static double barrelU(Size s, double x) => ((x - barrelX0(s)) / (barrelX1(s) - barrelX0(s))).clamp(0.0, 1.0);

  static bool crackSeen(Set<int>? seen) {
    if (seen == null) return true;
    for (var i = lugBin(crackU - 0.04); i <= lugBin(crackU + 0.04); i++) {
      if (seen.contains(i)) return true;
    }
    return false;
  }

  @override
  void paint(Canvas c, Size s) {
    final h = s.height;
    final cy = h / 2;
    final rb = h * 0.3;
    final x0 = barrelX0(s);
    final x1 = barrelX1(s);
    final neck = s.width * 0.7;
    final px1 = s.width * 0.98;
    final ph = h * 0.36;
    final shade = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [metalLight(al), metalMid(al), metalDark(al)],
      stops: const [0.05, 0.55, 1],
    );
    final alpha = glass ? 0.55 : 1.0;

    // The palm (flattened end) with its bolt hole.
    final palm = RRect.fromRectAndCorners(
      Rect.fromLTRB(neck - 2, cy - ph / 2, px1, cy + ph / 2),
      topRight: Radius.circular(ph / 2),
      bottomRight: Radius.circular(ph / 2),
    );
    c.drawRRect(palm, Paint()..shader = shade.createShader(palm.outerRect));
    c.drawRRect(
      palm,
      Paint()
        ..color = metalDark(al)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.6, h * 0.02),
    );
    c.drawCircle(Offset(s.width * 0.9, cy), ph * 0.26, Paint()..color = const Color(0xFF1C2229));

    // The neck, tapering from the barrel to the palm.
    final nk = Path()
      ..moveTo(x1 - 1, cy - rb)
      ..lineTo(neck, cy - ph / 2)
      ..lineTo(neck, cy + ph / 2)
      ..lineTo(x1 - 1, cy + rb)
      ..close();
    c.drawPath(nk, Paint()..shader = shade.createShader(Rect.fromLTRB(x1, cy - rb, neck, cy + rb)));

    // The barrel.
    final barrel = Rect.fromLTRB(x0, cy - rb, x1, cy + rb);
    final bp = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [metalLight(al).withValues(alpha: alpha), metalMid(al).withValues(alpha: alpha), metalDark(al).withValues(alpha: alpha)],
        stops: const [0.05, 0.55, 1],
      ).createShader(barrel);
    c.drawRect(barrel, bp);
    c.drawLine(Offset(x0, cy - rb), Offset(x1, cy - rb), Paint()
      ..color = metalDark(al)
      ..strokeWidth = math.max(0.6, h * 0.02));
    c.drawLine(Offset(x0, cy + rb), Offset(x1, cy + rb), Paint()
      ..color = metalDark(al)
      ..strokeWidth = math.max(0.6, h * 0.02));
    // The mouth's rim (an ellipse: we see it a little from the side).
    final rim = Rect.fromCenter(center: Offset(x0, cy), width: rb * 0.5, height: rb * 2);
    c.drawOval(rim, Paint()..color = metalMid(al));
    c.drawOval(rim.deflate(rb * 0.12), Paint()..color = const Color(0xFF2A2F35));
    // A highlight along the top.
    c.drawLine(Offset(x0 + rb * 0.4, cy - rb * 0.55), Offset(x1 - 2, cy - rb * 0.55), Paint()
      ..color = Colors.white.withValues(alpha: 0.45 * alpha)
      ..strokeWidth = math.max(0.8, h * 0.04)
      ..strokeCap = StrokeCap.round);

    if (crack && crackSeen(seenBarrel)) {
      final cx = x0 + (x1 - x0) * crackU;
      final p = Path()
        ..moveTo(cx - rb * 0.2, cy - rb)
        ..lineTo(cx + rb * 0.15, cy - rb * 0.4)
        ..lineTo(cx - rb * 0.1, cy + rb * 0.1)
        ..lineTo(cx + rb * 0.25, cy + rb * 0.6)
        ..lineTo(cx + rb * 0.05, cy + rb);
      c.drawPath(
        p,
        Paint()
          ..color = const Color(0xFF1E1A16)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.0, h * 0.035)
          ..strokeJoin = StrokeJoin.round,
      );
      c.drawLine(Offset(cx + rb * 0.25, cy - rb * 0.5), Offset(cx + rb * 0.4, cy - rb * 0.2), Paint()
        ..color = const Color(0xCCFFFFFF)
        ..strokeWidth = math.max(0.5, h * 0.015));
    }

    // What has not been looked at yet is washed out.
    final v = veil;
    final seen = seenBarrel;
    if (v != null && seen != null) {
      final wash = Paint()..color = v.withValues(alpha: 0.62);
      final bw = (x1 - x0) / kLugBins;
      for (var i = 0; i < kLugBins; i++) {
        if (!seen.contains(i)) c.drawRect(Rect.fromLTWH(x0 + bw * i - 0.5, cy - rb - 2, bw + 1, rb * 2 + 4), wash);
      }
    }
  }

  @override
  bool shouldRepaint(LugSidePainter old) =>
      old.al != al || old.crack != crack || old.veil != veil || old.glass != glass || !_same(old.seenBarrel, seenBarrel);

  static bool _same(Set<int>? a, Set<int>? b) {
    if (a == null || b == null) return a == b;
    return a.length == b.length && a.containsAll(b);
  }
}

/// Looking into the barrel's mouth: a ring of metal and the inside — dark
/// until looked at ([seen]); then bright clean metal, or oil and grime.
class LugMouthPainter extends CustomPainter {
  const LugMouthPainter({required this.al, required this.dirt, required this.seen});
  final bool al;
  final bool dirt;
  final bool seen;

  @override
  void paint(Canvas c, Size s) {
    final ctr = s.center(Offset.zero);
    final r = s.shortestSide * 0.46;
    c.drawCircle(
      ctr,
      r,
      Paint()
        ..shader = RadialGradient(colors: [metalLight(al), metalMid(al), metalDark(al)], stops: const [0.6, 0.85, 1])
            .createShader(Rect.fromCircle(center: ctr, radius: r)),
    );
    final ri = r * 0.7;
    final inner = Rect.fromCircle(center: ctr, radius: ri);
    if (!seen) {
      c.drawCircle(ctr, ri, Paint()..color = const Color(0xFF151A20));
      return;
    }
    c.drawCircle(
      ctr,
      ri,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.2, -0.3),
          colors: [metalLight(al), metalMid(al), const Color(0xFF2A2F35)],
          stops: const [0, 0.55, 1],
        ).createShader(inner),
    );
    if (dirt) {
      c.save();
      c.clipPath(Path()..addOval(inner));
      final grime = Paint()..color = const Color(0xE03A2A16);
      for (final o in const [Offset(-0.35, 0.2), Offset(0.3, 0.35), Offset(0.1, -0.3), Offset(-0.1, 0.55), Offset(0.5, -0.1)]) {
        c.drawCircle(ctr + Offset(o.dx * ri, o.dy * ri), ri * 0.32, grime);
      }
      // An oily sheen.
      c.drawOval(
        Rect.fromCenter(center: ctr + Offset(-ri * 0.2, -ri * 0.1), width: ri * 0.8, height: ri * 0.3),
        Paint()..color = const Color(0x667FD6C8),
      );
      c.restore();
    }
  }

  @override
  bool shouldRepaint(LugMouthPainter old) => old.al != al || old.dirt != dirt || old.seen != seen;
}

// ---------------------------------------------------------------------------
// The strip bench
// ---------------------------------------------------------------------------

/// Where things are on the strip bench ([s]: its box) for a lug of [size] sq mm.
@immutable
class LugStripGeo {
  const LugStripGeo(this.s, this.size);
  final Size s;
  final int size;

  double get cableY => s.height * 0.72;
  double get cableT => s.height * 0.26;
  double get cableEnd => s.width * 0.62;
  double get lugY => s.height * 0.24;
  double get lugH => s.height * 0.3;

  /// The barrel's depth in px: a bigger lug has a longer barrel.
  double get depth => s.width * (0.15 + 0.0016 * size);

  /// The lug's box when laid beside the cable (its barrel bottom over the cable's end).
  Rect lugRect(double mouthX, double y) {
    // In LugSidePainter, the barrel runs 0.03w … 0.6w of the lug's box.
    final w = depth / 0.57;
    return Rect.fromLTWH(mouthX - w * 0.03, y - lugH / 2, w, lugH);
  }

  /// The knife at [u] barrel depths from the cable's end.
  double knifeX(double u) => cableEnd - depth * u;

  /// The farthest back the knife goes.
  double get maxU => (cableEnd - s.width * 0.04) / depth;
}

/// The cable end on the strip bench, the lug beside it, and the knife mark;
/// after the cut ([cut]: strip length in barrel depths), the insulation off to
/// the knife and the lug pushed on ([t] 0 → 1).
class LugStripPainter extends CustomPainter {
  LugStripPainter({required this.geo, required this.al, required this.knife, this.cut, this.t = 0, this.outline = false});
  final LugStripGeo geo;
  final bool al;
  final double knife;
  final double? cut;
  final double t;

  /// Only the bare conductor's outline (drawn over the see-through barrel,
  /// so where the conductor ends inside it shows).
  final bool outline;

  @override
  void paint(Canvas c, Size s) {
    final g = geo;
    final y = g.cableY;
    final ct = g.cableT;
    final end = g.cableEnd;
    final cutAt = cut == null ? end : g.knifeX(cut!);
    if (outline) {
      if (cut == null) return;
      final cond = Rect.fromLTRB(cutAt, y - ct * 0.33, end, y + ct * 0.33);
      c.drawRect(
        cond,
        Paint()
          ..color = const Color(0xE61E1A16)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
      c.drawLine(Offset(end, cond.top), Offset(end, cond.bottom), Paint()
        ..color = const Color(0xFF1E1A16)
        ..strokeWidth = 3);
      return;
    }

    // The insulation, up to the knife's cut.
    final ins = Rect.fromLTRB(-4, y - ct / 2, cutAt, y + ct / 2);
    c.drawRRect(
      RRect.fromRectAndRadius(ins, Radius.circular(ct * 0.15)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF454A51), Color(0xFF17191C), Color(0xFF2C2F33)],
        ).createShader(ins),
    );
    // The bare strands, from the cut to the end.
    if (cut != null) {
      final cond = Rect.fromLTRB(cutAt - 1, y - ct * 0.33, end, y + ct * 0.33);
      c.drawRect(
        cond,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [metalLight(al), metalMid(al), metalDark(al)],
          ).createShader(cond),
      );
      final strand = Paint()
        ..color = metalDark(al).withValues(alpha: 0.7)
        ..strokeWidth = 1;
      for (var i = -2; i <= 2; i++) {
        final yy = y + i * ct * 0.12;
        for (var x = cutAt; x < end - 6; x += 12) {
          c.drawLine(Offset(x, yy), Offset(x + 8, yy + ct * 0.06), strand);
        }
      }
    } else {
      c.drawOval(Rect.fromCenter(center: Offset(end, y), width: ct * 0.3, height: ct), Paint()..color = const Color(0xFF17191C));
      c.drawOval(Rect.fromCenter(center: Offset(end + 0.5, y), width: ct * 0.2, height: ct * 0.68), Paint()..color = metalMid(al));
    }

    // The knife's mark across the insulation (before the cut).
    if (cut == null) {
      final kx = g.knifeX(knife);
      final mark = Paint()
        ..color = const Color(0xFFFF851B)
        ..strokeWidth = 2.4;
      for (var yy = y - ct * 1.0; yy < y + ct * 0.9; yy += 7) {
        c.drawLine(Offset(kx, yy), Offset(kx, yy + 4), mark);
      }
      // The blade, standing on the mark.
      final blade = Path()
        ..moveTo(kx, y - ct * 0.55)
        ..lineTo(kx - 7, y - ct * 1.3)
        ..lineTo(kx + 7, y - ct * 1.3)
        ..close();
      c.drawPath(blade, Paint()..color = const Color(0xFFCBD1D6));
      c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(kx, y - ct * 1.6), width: 14, height: ct * 0.7), const Radius.circular(3)),
        Paint()..color = const Color(0xFFE2B33C),
      );
    }
  }

  @override
  bool shouldRepaint(LugStripPainter old) => old.outline != outline || old.knife != knife || old.cut != cut || old.t != t || old.al != al || old.geo.s != geo.s || old.geo.size != geo.size;
}
