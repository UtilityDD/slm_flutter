import 'dart:math' as math;

import 'package:flutter/material.dart';

// The drawn world of lesson 2.1 কাজ 2 "সঠিক কাজে সঠিক হাতিয়ার"
// (m2_tool_use.dart): a roadside LT PCC pole with its distribution box open
// at chest height (the line is shut down; the docket says so), the trainee in
// front of it, and his toolbox open on the ground in the foreground. A round
// lens shows the work piece close up with the tool he is trying on it.
//
// Everything here is still (no clock): an idle scene draws no frames.

/// The job at the box.
enum TuJob { nut, screw, strip, neutral, crimp }

/// The screw head on the terminal.
enum TuScrew { flatBig, flatSmall, phillips }

/// The tools in the open box.
enum TuTool { pliersVde, pliersPlain, cutter, stripper, knife, tester, meter, flatBig, flatSmall, phillips, sp13, sp17, sp19 }

extension TuToolInfo on TuTool {
  bool get spanner => this == TuTool.sp13 || this == TuTool.sp17 || this == TuTool.sp19;
  bool get driver => this == TuTool.flatBig || this == TuTool.flatSmall || this == TuTool.phillips;
  bool get pliers => this == TuTool.pliersVde || this == TuTool.pliersPlain;

  /// The spanner's size (mm), stamped on it.
  int get mm => switch (this) {
        TuTool.sp13 => 13,
        TuTool.sp17 => 17,
        TuTool.sp19 => 19,
        _ => 0,
      };
}

/// Where things are in the scene (design px, 360 wide).
@immutable
class TuGeo {
  const TuGeo._(this.h, this.groundY, this.box, this.tray, this.lens, this.lensR);

  factory TuGeo.forScene(double h, double inset) {
    final trayBottom = h - inset - 8;
    final tray = Rect.fromLTRB(6, trayBottom - 196, 354, trayBottom);
    final groundY = tray.top - 8;
    final box = Rect.fromLTWH(150, groundY - 168, 82, 88);
    final lensY = (groundY - 318).clamp(196.0, 262.0);
    return TuGeo._(h, groundY, box, tray, Offset(100, lensY), 82);
  }

  final double h;
  final double groundY;

  /// The distribution box on the pole.
  final Rect box;

  /// The open toolbox (foreground).
  final Rect tray;

  /// The close-up lens.
  final Offset lens;
  final double lensR;

  double get poleX => box.center.dx;
  double get poleTop => math.max(118, groundY - 440);
  double get horizonY => groundY - 96;

  /// The trainee in front of the box (his hand reaches its left edge).
  Rect get trainee {
    const fh = 176.0;
    const fw = fh / 2;
    return Rect.fromLTWH(box.left - fw * 0.8, groundY - fh + 2, fw, fh);
  }

  /// Where the job's piece is on the box.
  Offset pieceAt(TuJob j) => switch (j) {
        TuJob.screw => Offset(box.left + box.width * 0.5, box.top + box.height * 0.27),
        TuJob.neutral => Offset(box.left + box.width * 0.72, box.top + box.height * 0.53),
        TuJob.nut => Offset(box.left + box.width * 0.26, box.top + box.height * 0.8),
        TuJob.strip || TuJob.crimp => Offset(box.left + box.width * 0.62, box.bottom + 20),
      };

  /// The slots of the open box: row 1 (7) and row 2 (6), in [order].
  Map<TuTool, Rect> slots(List<TuTool> order) {
    final r1 = order.take(7).toList();
    final r2 = order.skip(7).toList();
    final inner = tray.deflate(10);
    final out = <TuTool, Rect>{};
    final w1 = inner.width / r1.length;
    for (final (i, t) in r1.indexed) {
      out[t] = Rect.fromLTWH(inner.left + w1 * i, inner.top + 18, w1, 78);
    }
    final w2 = inner.width / r2.length;
    for (final (i, t) in r2.indexed) {
      out[t] = Rect.fromLTWH(inner.left + w2 * i, inner.top + 100, w2, 76);
    }
    return out;
  }

  @override
  bool operator ==(Object other) => other is TuGeo && other.h == h && other.groundY == groundY;
  @override
  int get hashCode => Object.hash(h, groundY);
}

// ============================================================================
// The world (still)
// ============================================================================

class TuWorldPainter extends CustomPainter {
  const TuWorldPainter({required this.geo, required this.job, required this.stripped});
  final TuGeo geo;

  /// The current job (its place on the box is marked); null: none.
  final TuJob? job;

  /// The service cable end is stripped (after the strip job).
  final bool stripped;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final g = geo;
    // Sky.
    c.drawRect(
        Rect.fromLTWH(0, 0, w, g.horizonY + 2),
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF6FA8DC), Color(0xFFBFD9EE), Color(0xFFEAF1E6)])
              .createShader(Rect.fromLTWH(0, 0, w, g.horizonY)));
    // A few soft clouds.
    final cloud = Paint()..color = const Color(0xCCFFFFFF);
    for (final (x, y, s) in [(60.0, 0.22, 1.0), (210.0, 0.14, 0.8), (320.0, 0.3, 0.6)]) {
      final cy = g.horizonY * y + 40;
      c.drawOval(Rect.fromCenter(center: Offset(x, cy), width: 70 * s, height: 20 * s), cloud);
      c.drawOval(Rect.fromCenter(center: Offset(x + 14 * s, cy - 8 * s), width: 40 * s, height: 22 * s), cloud);
    }
    // Far houses and trees.
    final far = Paint()..color = const Color(0xFF9DB3A6);
    final farDark = Paint()..color = const Color(0xFF7F978A);
    final hy = g.horizonY;
    for (final (x, bw, bh) in [(4.0, 40.0, 34.0), (52.0, 30.0, 46.0), (150.0, 46.0, 30.0), (300.0, 36.0, 40.0)]) {
      c.drawRect(Rect.fromLTWH(x, hy - bh, bw, bh), far);
      c.drawRect(Rect.fromLTWH(x + bw * 0.2, hy - bh + 8, 6, 6), farDark);
      c.drawRect(Rect.fromLTWH(x + bw * 0.6, hy - bh + 8, 6, 6), farDark);
    }
    final tree = Paint()..color = const Color(0xFF6E9A72);
    for (final (x, r) in [(100.0, 20.0), (128.0, 15.0), (205.0, 18.0), (346.0, 22.0)]) {
      c.drawRect(Rect.fromLTWH(x - 2, hy - r, 4, r), Paint()..color = const Color(0xFF6B5A44));
      c.drawCircle(Offset(x, hy - r - r * 0.6), r, tree);
    }
    // Ground: verge, a strip of road behind, grass in front.
    c.drawRect(
        Rect.fromLTRB(0, hy, w, size.height),
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFA9B98C), Color(0xFF8DA36C)])
              .createShader(Rect.fromLTRB(0, hy, w, size.height)));
    c.drawRect(Rect.fromLTRB(0, hy + 14, w, hy + 46), Paint()..color = const Color(0xFF6E7378));
    final dash = Paint()
      ..color = const Color(0xFFE9E3C9)
      ..strokeWidth = 2;
    for (var x = 8.0; x < w; x += 34) {
      c.drawLine(Offset(x, hy + 30), Offset(x + 16, hy + 30), dash);
    }
    c.drawRect(Rect.fromLTRB(0, hy + 46, w, g.groundY + 30), Paint()..color = const Color(0xFFB59E74));
    // Pebbles on the dirt.
    final peb = Paint()..color = const Color(0xFF9C865E);
    final rnd = math.Random(3);
    for (var i = 0; i < 26; i++) {
      c.drawCircle(Offset(rnd.nextDouble() * w, hy + 52 + rnd.nextDouble() * (g.groundY - hy - 30)), 1 + rnd.nextDouble() * 1.6, peb);
    }
    _pole(c, size);
    _box(c);
    _cable(c);
  }

  void _pole(Canvas c, Size size) {
    final g = geo;
    final x = g.poleX;
    final top = g.poleTop;
    final base = g.groundY + 4;
    // The LT PCC pole: tapered, concrete grey.
    final pole = Path()
      ..moveTo(x - 6, top)
      ..lineTo(x + 6, top)
      ..lineTo(x + 10, base)
      ..lineTo(x - 10, base)
      ..close();
    c.drawPath(
        pole,
        Paint()
          ..shader = const LinearGradient(colors: [Color(0xFF8E9296), Color(0xFFCBCFD2), Color(0xFF7C8084)]).createShader(Rect.fromLTRB(x - 10, top, x + 10, base)));
    c.drawOval(Rect.fromCenter(center: Offset(x, base + 1), width: 34, height: 8), Paint()..color = const Color(0x55000000));
    // The LT cross-arm (channel) with four shackle insulators and the wires.
    final armY = top + 22;
    c.drawRect(Rect.fromLTRB(x - 70, armY - 3, x + 60, armY + 4), Paint()..color = const Color(0xFF4F555B));
    final wire = Paint()
      ..color = const Color(0xFF2B2F33)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    for (final dx in [-60.0, -30.0, 22.0, 50.0]) {
      final p = Offset(x + dx, armY + 10);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: p, width: 8, height: 12), const Radius.circular(3)), Paint()..color = const Color(0xFF7A4A2A));
      c.drawPath(
          Path()
            ..moveTo(-10, p.dy + 26)
            ..quadraticBezierTo(p.dx * 0.5, p.dy + 34, p.dx, p.dy + 4)
            ..quadraticBezierTo(p.dx + (size.width - p.dx) * 0.5, p.dy + 30, size.width + 10, p.dy + 18),
          wire);
    }
    // The service cable down the pole into the box.
    c.drawLine(Offset(x + 4, armY + 30), Offset(x + 4, g.box.top), Paint()
      ..color = const Color(0xFF1C1C1C)
      ..strokeWidth = 2.4);
    // The pole's earth wire down to the ground.
    c.drawLine(Offset(x - 7, g.box.bottom), Offset(x - 8, base), Paint()
      ..color = const Color(0xFF6C7A3A)
      ..strokeWidth = 1.6);
  }

  void _box(Canvas c) {
    final b = geo.box;
    // The open door (hinged on the right, swung out).
    final door = Path()
      ..moveTo(b.right, b.top)
      ..lineTo(b.right + 30, b.top + 8)
      ..lineTo(b.right + 30, b.bottom + 6)
      ..lineTo(b.right, b.bottom)
      ..close();
    c.drawPath(door, Paint()..color = const Color(0xFF9AA3A8));
    c.drawPath(
        door,
        Paint()
          ..color = const Color(0xFF5E676C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
    // The danger plate on the door (a worker reads it).
    final plate = Rect.fromLTWH(b.right + 6, b.top + 22, 18, 22);
    c.drawRect(plate, Paint()..color = const Color(0xFFF2C230));
    final bolt = Path()
      ..moveTo(plate.center.dx + 2, plate.top + 3)
      ..lineTo(plate.center.dx - 4, plate.center.dy + 1)
      ..lineTo(plate.center.dx + 1, plate.center.dy + 1)
      ..lineTo(plate.center.dx - 2, plate.bottom - 3)
      ..lineTo(plate.center.dx + 5, plate.center.dy - 2)
      ..lineTo(plate.center.dx, plate.center.dy - 2)
      ..close();
    c.drawPath(bolt, Paint()..color = const Color(0xFFB0281C));
    // The box body and its inside.
    c.drawRRect(RRect.fromRectAndRadius(b.inflate(3), const Radius.circular(3)), Paint()..color = const Color(0xFF7D868B));
    c.drawRect(b, Paint()..color = const Color(0xFF3F4A50));
    c.drawRect(b.deflate(4), Paint()..color = const Color(0xFFDCE0E2));
    // The terminal strip (three screws).
    final ts = Rect.fromLTWH(b.left + 10, b.top + b.height * 0.18, b.width - 20, 16);
    c.drawRect(ts, Paint()..color = const Color(0xFF2E3338));
    for (var i = 0; i < 3; i++) {
      final p = Offset(ts.left + ts.width * (0.2 + 0.3 * i), ts.center.dy);
      c.drawCircle(p, 4.2, Paint()..color = const Color(0xFFC9A44A));
      c.drawLine(p - const Offset(3, 0), p + const Offset(3, 0), Paint()
        ..color = const Color(0xFF6B5420)
        ..strokeWidth = 1.2);
    }
    // Three phase wires (R Y B) down from the strip.
    for (final (i, col) in [(0, const Color(0xFFC62828)), (1, const Color(0xFFF2C230)), (2, const Color(0xFF1E5AA8))]) {
      final x = ts.left + ts.width * (0.2 + 0.3 * i);
      c.drawLine(Offset(x, ts.bottom), Offset(x, b.top + b.height * 0.42), Paint()
        ..color = col
        ..strokeWidth = 2.2);
    }
    // The neutral bar (N).
    final nb = Rect.fromLTWH(b.left + b.width * 0.5, b.top + b.height * 0.47, b.width * 0.38, 9);
    c.drawRect(nb, Paint()..color = const Color(0xFFB8893A));
    _label(c, 'N', Offset(nb.left - 7, nb.center.dy), 9, const Color(0xFF1F2A30));
    c.drawLine(Offset(nb.right - 6, nb.bottom), Offset(nb.right - 6, b.bottom - 4), Paint()
      ..color = const Color(0xFF222222)
      ..strokeWidth = 2.2);
    // The earth bolt (hex nut) with its green-yellow wire.
    final e = Offset(b.left + b.width * 0.26, b.top + b.height * 0.8);
    c.drawLine(e, Offset(b.left - 4, b.bottom + 2), Paint()
      ..color = const Color(0xFF3E8E3E)
      ..strokeWidth = 2.6);
    _hex(c, e, 5.2, const Color(0xFF9EA6AB));
    // Where the job is: a dashed ring and a thin line to the lens.
    final j = job;
    if (j != null) {
      final p = geo.pieceAt(j);
      final ring = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;
      const n = 14;
      for (var i = 0; i < n; i += 1) {
        if (i.isOdd) continue;
        c.drawArc(Rect.fromCircle(center: p, radius: 10), i / n * 2 * math.pi, 2 * math.pi / n, false, ring);
      }
      final l = geo.lens;
      final dir = (p - l) / (p - l).distance;
      c.drawLine(l + dir * (geo.lensR + 2), p - dir * 11, Paint()
        ..color = const Color(0xCCFFFFFF)
        ..strokeWidth = 1.2);
    }
  }

  /// The service cable hanging out of the box bottom.
  void _cable(Canvas c) {
    final b = geo.box;
    final start = Offset(b.left + b.width * 0.62, b.bottom);
    final end = geo.pieceAt(TuJob.strip);
    c.drawPath(
        Path()
          ..moveTo(start.dx, start.dy)
          ..quadraticBezierTo(start.dx + 2, start.dy + 10, end.dx, end.dy - 4),
        Paint()
          ..color = const Color(0xFF1C1C1C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4);
    if (stripped) {
      c.drawLine(Offset(end.dx, end.dy - 4), Offset(end.dx, end.dy + 4), Paint()
        ..color = const Color(0xFFD08A3C)
        ..strokeWidth = 3);
    }
  }

  @override
  bool shouldRepaint(TuWorldPainter old) => old.geo != geo || old.job != job || old.stripped != stripped;
}

/// The open toolbox in the foreground (its slots; the tools are widgets on it).
class TuTrayPainter extends CustomPainter {
  const TuTrayPainter({required this.geo, required this.slots});
  final TuGeo geo;
  final Map<TuTool, Rect> slots;

  @override
  void paint(Canvas c, Size size) {
    final t = geo.tray;
    // The lid, open behind.
    final lid = Rect.fromLTRB(t.left + 6, t.top - 18, t.right - 6, t.top + 8);
    c.drawRRect(RRect.fromRectAndRadius(lid, const Radius.circular(6)), Paint()..color = const Color(0xFFA8321E));
    c.drawLine(Offset(t.center.dx - 26, t.top - 10), Offset(t.center.dx + 26, t.top - 10), Paint()
      ..color = const Color(0xFF5E1A10)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round);
    c.drawRRect(RRect.fromRectAndRadius(t.translate(0, 4), const Radius.circular(10)), Paint()..color = const Color(0x55000000));
    c.drawRRect(
        RRect.fromRectAndRadius(t, const Radius.circular(10)),
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFD9432A), Color(0xFF9E2C1A)]).createShader(t));
    // The foam tray.
    final foam = t.deflate(8);
    c.drawRRect(RRect.fromRectAndRadius(foam, const Radius.circular(6)), Paint()..color = const Color(0xFF2A2F36));
    final slot = Paint()..color = const Color(0xFF1B1F24);
    for (final r in slots.values) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(r.left + 3, r.top + 2, r.right - 3, r.bottom - 18), const Radius.circular(6)), slot);
    }
  }

  @override
  bool shouldRepaint(TuTrayPainter old) => old.geo != geo || old.slots.keys.join() != slots.keys.join();
}

void _label(Canvas c, String s, Offset centre, double size, Color color) {
  final tp = TextPainter(
    text: TextSpan(text: s, style: TextStyle(fontSize: size, fontWeight: FontWeight.w900, color: color)),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
}

/// A hex nut, flats up/down, [r] = across the corners / 2.
void _hex(Canvas c, Offset p, double r, Color color, {double turn = 0}) {
  final path = Path();
  for (var i = 0; i < 6; i++) {
    final a = turn + i * math.pi / 3;
    final q = p + Offset(math.cos(a) * r, math.sin(a) * r);
    i == 0 ? path.moveTo(q.dx, q.dy) : path.lineTo(q.dx, q.dy);
  }
  path.close();
  c.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(colors: [Color.lerp(color, Colors.white, 0.35)!, color, Color.lerp(color, Colors.black, 0.3)!])
            .createShader(Rect.fromCircle(center: p, radius: r)));
  c.drawPath(
      path,
      Paint()
        ..color = Color.lerp(color, Colors.black, 0.5)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, r * 0.06));
  c.drawCircle(p, r * 0.45, Paint()..color = Color.lerp(color, Colors.black, 0.25)!);
}

// ============================================================================
// The tools (drawn upright in a box: the working end up)
// ============================================================================

const _red = Color(0xFFD7262E);
const _yellow = Color(0xFFF5C518);
const _steel = Color(0xFFB9C0C6);
const _steelDark = Color(0xFF6E777E);

Paint _steelPaint(Rect r) => Paint()..shader = const LinearGradient(colors: [Color(0xFFE6EAED), _steel, _steelDark]).createShader(r);

/// A VDE two-tone handle (red with a yellow core line) or bare steel.
void _handle(Canvas c, Path p, Rect r, {required bool vde}) {
  if (vde) {
    c.drawPath(p, Paint()..color = _red);
    c.drawPath(
        p,
        Paint()
          ..color = _yellow
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1, r.width * 0.05));
  } else {
    c.drawPath(p, _steelPaint(r));
    c.drawPath(
        p,
        Paint()
          ..color = _steelDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8);
  }
}

/// Draws [tool] upright, fitted in [r]. [vdeMark]: print "1000V" on VDE
/// handles (the close-up only).
void paintTuTool(Canvas c, TuTool tool, Rect r, {bool vdeMark = false}) {
  final w = r.width;
  final h = r.height;
  final cx = r.center.dx;
  Offset at(double x, double y) => Offset(r.left + w * x, r.top + h * y);
  switch (tool) {
    case TuTool.pliersVde:
    case TuTool.pliersPlain:
    case TuTool.cutter:
    case TuTool.stripper:
      final vde = tool != TuTool.pliersPlain;
      final headH = tool == TuTool.cutter ? 0.24 : 0.36;
      final pivot = at(0.5, headH + 0.04);
      // Handles.
      for (final s in [-1.0, 1.0]) {
        final hp = Path()
          ..moveTo(pivot.dx + s * w * 0.06, pivot.dy)
          ..quadraticBezierTo(cx + s * w * 0.2, r.top + h * 0.7, cx + s * w * 0.3, r.bottom - h * 0.02)
          ..lineTo(cx + s * w * 0.18, r.bottom - h * 0.02)
          ..quadraticBezierTo(cx + s * w * 0.08, r.top + h * 0.7, pivot.dx - s * w * 0.01, pivot.dy + h * 0.06)
          ..close();
        _handle(c, hp, r, vde: vde);
      }
      // The head.
      final head = Path();
      if (tool == TuTool.cutter) {
        head
          ..moveTo(pivot.dx - w * 0.13, pivot.dy)
          ..quadraticBezierTo(cx - w * 0.14, r.top + h * 0.06, cx, r.top + h * 0.02)
          ..quadraticBezierTo(cx + w * 0.14, r.top + h * 0.06, pivot.dx + w * 0.13, pivot.dy)
          ..close();
      } else {
        head
          ..moveTo(pivot.dx - w * 0.12, pivot.dy)
          ..lineTo(cx - w * 0.07, r.top + h * 0.02)
          ..lineTo(cx + w * 0.07, r.top + h * 0.02)
          ..lineTo(pivot.dx + w * 0.12, pivot.dy)
          ..close();
      }
      c.drawPath(head, _steelPaint(r));
      c.drawPath(
          head,
          Paint()
            ..color = _steelDark
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.9);
      // The jaw line, the cutter edge, the stripper's notches.
      final line = Paint()
        ..color = const Color(0xFF3B4247)
        ..strokeWidth = math.max(0.8, w * 0.02);
      c.drawLine(Offset(cx, r.top + h * 0.03), Offset(cx, pivot.dy), line);
      if (tool == TuTool.stripper) {
        for (var i = 0; i < 3; i++) {
          c.drawCircle(Offset(cx, r.top + h * (0.09 + 0.07 * i)), w * (0.025 + 0.012 * i), Paint()..color = const Color(0xFF3B4247));
        }
      } else if (!tool.pliers) {
        // cutter: nothing more
      } else {
        for (var i = 0; i < 4; i++) {
          final y = r.top + h * (0.06 + 0.05 * i);
          c.drawLine(Offset(cx - w * 0.05, y), Offset(cx + w * 0.05, y), line);
        }
      }
      c.drawCircle(pivot, w * 0.05, Paint()..color = const Color(0xFF59626A));
      if (vdeMark && vde) _mark(c, at(0.5, 0.72), w);
    case TuTool.knife:
      // A folding knife: blade up, wooden handle.
      final blade = Path()
        ..moveTo(cx - w * 0.08, r.top + h * 0.5)
        ..lineTo(cx - w * 0.08, r.top + h * 0.12)
        ..quadraticBezierTo(cx, r.top, cx + w * 0.1, r.top + h * 0.04)
        ..lineTo(cx + w * 0.08, r.top + h * 0.5)
        ..close();
      c.drawPath(blade, _steelPaint(r));
      c.drawLine(Offset(cx + w * 0.07, r.top + h * 0.08), Offset(cx + w * 0.06, r.top + h * 0.48), Paint()
        ..color = Colors.white
        ..strokeWidth = 0.8);
      final hd = RRect.fromRectAndRadius(Rect.fromLTRB(cx - w * 0.11, r.top + h * 0.48, cx + w * 0.11, r.bottom), Radius.circular(w * 0.08));
      c.drawRRect(hd, Paint()..color = const Color(0xFF8A5A2E));
      c.drawCircle(Offset(cx, r.top + h * 0.56), w * 0.025, Paint()..color = _steel);
    case TuTool.tester:
      // A neon line tester: a slim screwdriver with a clear handle and a lamp.
      c.drawRect(Rect.fromLTRB(cx - w * 0.025, r.top + h * 0.02, cx + w * 0.025, r.top + h * 0.38), Paint()..color = _steel);
      final body = RRect.fromRectAndRadius(Rect.fromLTRB(cx - w * 0.08, r.top + h * 0.36, cx + w * 0.08, r.bottom), Radius.circular(w * 0.06));
      c.drawRRect(body, Paint()..color = const Color(0xCC9FD4E8));
      c.drawRRect(
          body,
          Paint()
            ..color = const Color(0xFF3C7D96)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.9);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(cx - w * 0.035, r.top + h * 0.48, cx + w * 0.035, r.top + h * 0.66), Radius.circular(w * 0.03)),
          Paint()..color = const Color(0xFFE85A3C));
      c.drawRect(Rect.fromLTRB(cx + w * 0.07, r.top + h * 0.4, cx + w * 0.11, r.top + h * 0.7), Paint()..color = const Color(0xFF2C3E50));
    case TuTool.meter:
      // A digital multimeter with its two leads.
      final lead = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1, w * 0.035);
      c.drawPath(
          Path()
            ..moveTo(cx - w * 0.12, r.bottom - h * 0.08)
            ..quadraticBezierTo(r.left, r.bottom, r.left + w * 0.06, r.top + h * 0.2),
          lead..color = _red);
      c.drawPath(
          Path()
            ..moveTo(cx + w * 0.12, r.bottom - h * 0.08)
            ..quadraticBezierTo(r.right, r.bottom, r.right - w * 0.06, r.top + h * 0.2),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(1, w * 0.035)
            ..color = const Color(0xFF202020));
      final body = RRect.fromRectAndRadius(Rect.fromLTRB(cx - w * 0.24, r.top + h * 0.1, cx + w * 0.24, r.bottom - h * 0.04), Radius.circular(w * 0.06));
      c.drawRRect(body, Paint()..color = const Color(0xFFF2B705));
      c.drawRRect(RRect.fromRectAndRadius(body.outerRect.deflate(w * 0.04), Radius.circular(w * 0.04)), Paint()..color = const Color(0xFF34383C));
      c.drawRect(Rect.fromLTRB(cx - w * 0.15, r.top + h * 0.18, cx + w * 0.15, r.top + h * 0.38), Paint()..color = const Color(0xFFB9C7A3));
      c.drawCircle(at(0.5, 0.6), w * 0.1, Paint()..color = const Color(0xFF1E2124));
      c.drawLine(at(0.5, 0.6), at(0.5, 0.6) + Offset(w * 0.06, -w * 0.06), Paint()
        ..color = Colors.white
        ..strokeWidth = 1);
      // Probe tips.
      c.drawLine(Offset(r.left + w * 0.06, r.top + h * 0.2), Offset(r.left + w * 0.06, r.top + h * 0.04), Paint()
        ..color = _steel
        ..strokeWidth = 1.4);
      c.drawLine(Offset(r.right - w * 0.06, r.top + h * 0.2), Offset(r.right - w * 0.06, r.top + h * 0.04), Paint()
        ..color = _steel
        ..strokeWidth = 1.4);
    case TuTool.flatBig:
    case TuTool.flatSmall:
    case TuTool.phillips:
      final big = tool != TuTool.flatSmall;
      final hw = w * (big ? 0.15 : 0.11);
      final shaft = w * (big ? 0.05 : 0.035);
      // The insulated shaft up to the metal tip.
      c.drawRect(Rect.fromLTRB(cx - shaft, r.top + h * 0.1, cx + shaft, r.top + h * 0.5), Paint()..color = _red);
      final tip = Path();
      if (tool == TuTool.phillips) {
        tip
          ..moveTo(cx - shaft, r.top + h * 0.1)
          ..lineTo(cx, r.top)
          ..lineTo(cx + shaft, r.top + h * 0.1)
          ..close();
      } else {
        final tw = big ? w * 0.08 : w * 0.045;
        tip
          ..moveTo(cx - shaft, r.top + h * 0.12)
          ..lineTo(cx - tw, r.top + h * 0.02)
          ..lineTo(cx + tw, r.top + h * 0.02)
          ..lineTo(cx + shaft, r.top + h * 0.12)
          ..close();
      }
      c.drawPath(tip, _steelPaint(r));
      if (tool == TuTool.phillips) {
        c.drawLine(Offset(cx, r.top + h * 0.01), Offset(cx, r.top + h * 0.09), Paint()
          ..color = _steelDark
          ..strokeWidth = 0.8);
      }
      final hd = RRect.fromRectAndRadius(Rect.fromLTRB(cx - hw, r.top + h * 0.48, cx + hw, r.bottom), Radius.circular(hw * 0.7));
      c.drawRRect(hd, Paint()..color = _red);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(cx - hw * 0.45, r.top + h * 0.55, cx + hw * 0.45, r.bottom - h * 0.06), Radius.circular(hw * 0.3)),
          Paint()..color = _yellow);
      if (vdeMark) _mark(c, at(0.5, 0.76), w);
    case TuTool.sp13:
    case TuTool.sp17:
    case TuTool.sp19:
      // A double-ended open spanner: the mouth up, size stamped on it.
      final k = tool.mm / 19;
      final mouth = w * 0.22 * k;
      final head = Offset(cx, r.top + h * 0.14);
      final jaw = Path()
        ..addOval(Rect.fromCircle(center: head, radius: mouth * 1.25))
        ..addRect(Rect.fromLTRB(cx - w * 0.07, head.dy, cx + w * 0.07, r.bottom - h * 0.12))
        ..addOval(Rect.fromCircle(center: Offset(cx, r.bottom - h * 0.1), radius: mouth * 1.1));
      c.drawPath(jaw, _steelPaint(r));
      // The open mouths (cut out with the tray colour behind).
      final cut = Paint()..color = const Color(0xFF1B1F24);
      c.drawRect(Rect.fromLTRB(cx - mouth * 0.55, r.top, cx + mouth * 0.55, head.dy + mouth * 0.15), cut);
      c.drawRect(Rect.fromLTRB(cx - mouth * 0.45, r.bottom - h * 0.1 - mouth * 0.1, cx + mouth * 0.45, r.bottom + 1), cut);
      _label(c, '${tool.mm}', Offset(cx, r.top + h * 0.55), math.max(7, w * 0.16), const Color(0xFF2B3238));
  }
}

void _mark(Canvas c, Offset p, double w) {
  final tp = TextPainter(
    text: TextSpan(text: '1000V', style: TextStyle(fontSize: math.max(6, w * 0.075), fontWeight: FontWeight.w900, color: Colors.black)),
    textDirection: TextDirection.ltr,
  )..layout();
  final box = Rect.fromCenter(center: p, width: tp.width + 4, height: tp.height + 1);
  c.drawRect(box, Paint()..color = _yellow);
  tp.paint(c, Offset(box.left + 2, box.top + 0.5));
}

/// One tool on its slot (the label is a widget under it).
class TuToolPainter extends CustomPainter {
  const TuToolPainter(this.tool, {this.lifted = false});
  final TuTool tool;
  final bool lifted;

  @override
  void paint(Canvas c, Size size) {
    final r = (Offset.zero & size).deflate(3);
    if (lifted) {
      c.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(8)), Paint()..color = const Color(0x33FFD34E));
    }
    paintTuTool(c, tool, r);
  }

  @override
  bool shouldRepaint(TuToolPainter old) => old.tool != tool || old.lifted != lifted;
}

// ============================================================================
// The lens: the work piece close up, and the tool he is trying on it
// ============================================================================

/// How the tool sits on the piece.
enum TuFit { fits, loose, tooSmall, wrongTip, other, none }

/// The fit of [tool] on the piece of a job ([nutMm] / [screw] for the sized ones).
TuFit tuFitOf(TuJob job, TuTool? tool, {int nutMm = 0, TuScrew? screw}) {
  if (tool == null) return TuFit.none;
  if (job == TuJob.nut && tool.spanner) {
    if (tool.mm == nutMm) return TuFit.fits;
    return tool.mm > nutMm ? TuFit.loose : TuFit.tooSmall;
  }
  if (job == TuJob.screw && tool.driver) {
    final want = switch (screw!) {
      TuScrew.flatBig => TuTool.flatBig,
      TuScrew.flatSmall => TuTool.flatSmall,
      TuScrew.phillips => TuTool.phillips,
    };
    return tool == want ? TuFit.fits : TuFit.wrongTip;
  }
  return TuFit.other;
}

class TuLensPainter extends CustomPainter {
  const TuLensPainter({required this.job, required this.tool, required this.nutMm, required this.screw, required this.done});
  final TuJob job;
  final TuTool? tool;
  final int nutMm;
  final TuScrew? screw;

  /// The job done (0 → 1: the nut turns, the insulation comes off …).
  final double done;

  @override
  void paint(Canvas c, Size size) {
    final r = Offset.zero & size;
    final o = r.center;
    final rad = size.shortestSide / 2;
    c.save();
    c.clipPath(Path()..addOval(Rect.fromCircle(center: o, radius: rad)));
    // The inside of the box, close up.
    c.drawRect(r, Paint()..color = const Color(0xFFD5DADD));
    final fit = tuFitOf(job, tool, nutMm: nutMm, screw: screw);
    switch (job) {
      case TuJob.nut:
        _nutPiece(c, o, rad, fit);
      case TuJob.screw:
        _screwPiece(c, o, rad, fit);
      case TuJob.strip:
        _cablePiece(c, o, rad, stripped: done > 0.5, lug: false, crimped: false);
      case TuJob.crimp:
        _cablePiece(c, o, rad, stripped: true, lug: true, crimped: done > 0.5);
      case TuJob.neutral:
        _neutralPiece(c, o, rad);
    }
    final t = tool;
    if (t != null && fit == TuFit.other) {
      // Any other tool: held at the piece, at a slant.
      c.save();
      c.translate(o.dx + rad * 0.34, o.dy + rad * 0.3);
      c.rotate(-0.55);
      final tw = rad * 0.62;
      paintTuTool(c, t, Rect.fromLTWH(-tw / 2, -tw * 0.55, tw, tw * 1.35), vdeMark: true);
      c.restore();
    }
    if (job == TuJob.neutral && t == TuTool.meter && done > 0.3) {
      // The reading.
      final d = Rect.fromCenter(center: o + Offset(0, -rad * 0.6), width: rad * 0.9, height: rad * 0.32);
      c.drawRRect(RRect.fromRectAndRadius(d, const Radius.circular(4)), Paint()..color = const Color(0xFFB9C7A3));
      _label(c, '0.0 V', d.center, rad * 0.2, const Color(0xFF1F2A1A));
    }
    c.restore();
    // The rim.
    c.drawCircle(
        o,
        rad - 2,
        Paint()
          ..color = const Color(0xFFF7F1E1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4);
    c.drawCircle(
        o,
        rad - 0.5,
        Paint()
          ..color = const Color(0x88000000)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
  }

  void _nutPiece(Canvas c, Offset o, double rad, TuFit fit) {
    // The earth wire's lug under the nut.
    c.drawLine(o, o + Offset(-rad, rad * 0.9), Paint()
      ..color = const Color(0xFF3E8E3E)
      ..strokeWidth = rad * 0.12);
    c.drawCircle(o, rad * 0.42, Paint()..color = const Color(0xFFC08A3E));
    final nr = rad * 0.26 * nutMm / 17;
    final turn = done * math.pi / 3;
    _hex(c, o, nr, const Color(0xFF9EA6AB), turn: turn);
    // Bolt end.
    c.drawCircle(o, nr * 0.4, Paint()..color = const Color(0xFF7C858B));
    final t = tool;
    if (t == null || !t.spanner) return;
    // The spanner's open jaw round the flats (flats across = nr·√3).
    final flats = nr * math.sqrt(3);
    final mouth = flats * t.mm / nutMm;
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(turn);
    final sp = _steelPaint(Rect.fromCircle(center: Offset.zero, radius: rad));
    final outer = mouth / 2 + rad * 0.16;
    // Too small: it rests on the nut's face, off to the side (it cannot go on).
    final dy = fit == TuFit.tooSmall ? -nr * 0.9 : 0.0;
    final dx = fit == TuFit.loose ? rad * 0.08 : 0.0;
    final head = Path()
      ..addRect(Rect.fromLTRB(-outer, -outer * 0.95 + dy, outer, outer * 0.95 + dy))
      ..addRect(Rect.fromLTRB(-rad * 0.14, outer * 0.6 + dy, rad * 0.14, rad * 1.2));
    final gap = Path()..addRect(Rect.fromLTRB(-mouth / 2 + dx, -rad * 1.2, mouth / 2 + dx, nr * 0.55 + dy));
    final jaw = Path.combine(PathOperation.difference, head, gap);
    c.drawPath(jaw, sp);
    c.drawPath(
        jaw,
        Paint()
          ..color = _steelDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
    _label(c, '${t.mm}', Offset(0, rad * 0.9), rad * 0.16, const Color(0xFF2B3238));
    c.restore();
  }

  void _screwPiece(Canvas c, Offset o, double rad, TuFit fit) {
    // The terminal block and its brass screw head.
    c.drawRect(Rect.fromCenter(center: o, width: rad * 2, height: rad * 0.9), Paint()..color = const Color(0xFF2E3338));
    for (final (dx, col) in [(-0.7, const Color(0xFFC62828)), (0.7, const Color(0xFF1E5AA8))]) {
      c.drawLine(o + Offset(rad * dx, rad * 0.45), o + Offset(rad * dx, rad), Paint()
        ..color = col
        ..strokeWidth = rad * 0.1);
    }
    final hr = rad * (screw == TuScrew.flatSmall ? 0.2 : 0.3);
    c.drawCircle(o, hr, Paint()..shader = const RadialGradient(colors: [Color(0xFFF0D27A), Color(0xFFA9842E)]).createShader(Rect.fromCircle(center: o, radius: hr)));
    c.save();
    c.translate(o.dx, o.dy);
    c.rotate(done * math.pi / 2);
    final slot = Paint()
      ..color = const Color(0xFF4A3A14)
      ..strokeWidth = hr * (screw == TuScrew.flatSmall ? 0.22 : 0.2)
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(-hr * 0.75, 0), Offset(hr * 0.75, 0), slot);
    if (screw == TuScrew.phillips) c.drawLine(Offset(0, -hr * 0.75), Offset(0, hr * 0.75), slot);
    // The driver's tip seen from above, on the head.
    final t = tool;
    if (t != null && t.driver) {
      final tipLen = switch (t) {
        TuTool.flatBig => rad * 0.3 * 1.5,
        TuTool.flatSmall => rad * 0.2 * 1.5,
        _ => rad * 0.3 * 1.5,
      };
      final off = fit == TuFit.wrongTip ? Offset(hr * 0.35, -hr * 0.3) : Offset.zero;
      final tip = Paint()
        ..color = const Color(0xE6C8CED3)
        ..strokeWidth = hr * 0.18
        ..strokeCap = StrokeCap.butt;
      c.drawLine(off + Offset(-tipLen / 2, 0), off + Offset(tipLen / 2, 0), tip);
      if (t == TuTool.phillips) c.drawLine(off + Offset(0, -tipLen / 2), off + Offset(0, tipLen / 2), tip);
      // The shaft rising to the viewer: a red ring.
      c.drawCircle(off, hr * 0.32, Paint()..color = const Color(0xCCD7262E));
    }
    c.restore();
  }

  void _cablePiece(Canvas c, Offset o, double rad, {required bool stripped, required bool lug, required bool crimped}) {
    // The service cable end, across the lens.
    final y = o.dy;
    final endX = o.dx + rad * 0.2;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(o.dx - rad * 1.1, y - rad * 0.16, endX, y + rad * 0.16), Radius.circular(rad * 0.08)),
        Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF4A4A4A), Color(0xFF151515)]).createShader(Rect.fromCircle(center: o, radius: rad)));
    if (!stripped) {
      // A mark where the insulation will come off.
      c.drawLine(Offset(endX - rad * 0.36, y - rad * 0.17), Offset(endX - rad * 0.36, y + rad * 0.17), Paint()
        ..color = const Color(0x88FFFFFF)
        ..strokeWidth = 1);
      return;
    }
    // Bare copper strands.
    final cu = Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF2B27A), Color(0xFFB0662A)]).createShader(Rect.fromCircle(center: o, radius: rad));
    c.drawRect(Rect.fromLTRB(endX, y - rad * 0.1, endX + rad * 0.36, y + rad * 0.1), cu);
    if (!lug) return;
    // The copper lug over the strands, its palm with a hole.
    final barrel = Rect.fromLTRB(endX - rad * 0.02, y - rad * 0.13, endX + rad * 0.4, y + rad * 0.13);
    c.drawRect(barrel, Paint()..color = const Color(0xFFC98B4E));
    final palm = Rect.fromLTRB(barrel.right, y - rad * 0.2, barrel.right + rad * 0.42, y + rad * 0.2);
    c.drawRRect(RRect.fromRectAndRadius(palm, Radius.circular(rad * 0.2)), Paint()..color = const Color(0xFFD99A5B));
    c.drawCircle(palm.center, rad * 0.07, Paint()..color = const Color(0xFFD5DADD));
    if (crimped) {
      for (var i = 0; i < 2; i++) {
        final x = barrel.left + barrel.width * (0.3 + 0.35 * i);
        c.drawLine(Offset(x, barrel.top), Offset(x, barrel.bottom), Paint()
          ..color = const Color(0xFF7A4A1E)
          ..strokeWidth = rad * 0.05);
      }
    }
  }

  void _neutralPiece(Canvas c, Offset o, double rad) {
    final bar = Rect.fromCenter(center: o, width: rad * 1.5, height: rad * 0.28);
    c.drawRect(bar, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE0B56A), Color(0xFF9C6E22)]).createShader(bar));
    for (var i = 0; i < 3; i++) {
      c.drawCircle(Offset(bar.left + bar.width * (0.2 + 0.3 * i), bar.center.dy), rad * 0.06, Paint()..color = const Color(0xFF6E5420));
    }
    _label(c, 'N', Offset(bar.left - rad * 0.14, bar.center.dy), rad * 0.24, const Color(0xFF1F2A30));
    c.drawLine(Offset(bar.left + bar.width * 0.5, bar.bottom), Offset(bar.left + bar.width * 0.5, o.dy + rad), Paint()
      ..color = const Color(0xFF222222)
      ..strokeWidth = rad * 0.1);
  }

  @override
  bool shouldRepaint(TuLensPainter old) =>
      old.job != job || old.tool != tool || old.done != done || old.nutMm != nutMm || old.screw != screw;
}
