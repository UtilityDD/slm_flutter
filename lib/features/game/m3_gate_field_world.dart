import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

// The drawn world of the Module 3 rank gate (m3_gate_field.dart): the SLD on
// a clipboard, a patrolled span (pin insulator, clamp, conductor, disc string,
// cross-arm), the plinth DTR with its DO pole and LA, the LT feeder pillar,
// a service drop to a house and a cradle guard over a road. Everything is
// painted, in design pixels (360 wide, the scene height follows the phone).

void _label(Canvas c, String text, Offset centre, double size, Color color, {bool bn = false}) {
  final style = bn
      ? bangla(fontSize: size, fontWeight: FontWeight.w800, color: color)
      : TextStyle(fontSize: size, fontWeight: FontWeight.w800, color: color);
  final tp = TextPainter(text: TextSpan(text: text, style: style), textDirection: TextDirection.ltr)..layout();
  tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
}

Paint _stroke(Color c, double w) => Paint()
  ..color = c
  ..strokeWidth = w
  ..style = PaintingStyle.stroke
  ..strokeCap = StrokeCap.round;

void _sky(Canvas canvas, Size size, double groundY, {bool road = false}) {
  final w = size.width;
  canvas.drawRect(
    Rect.fromLTWH(0, 0, w, groundY),
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF6FA8DC), Color(0xFFD6EAF6)],
      ).createShader(Rect.fromLTWH(0, 0, w, groundY)),
  );
  final far = Paint()..color = const Color(0xFF86AD7E);
  final hills = Path()..moveTo(0, groundY);
  for (var x = 0.0; x <= w; x += 24) {
    hills.lineTo(x, groundY - 22 - 10 * math.sin(x / 29) - 7 * math.cos(x / 11));
  }
  canvas.drawPath(hills..lineTo(w, groundY)..close(), far);
  canvas.drawRect(
    Rect.fromLTWH(0, groundY, w, size.height - groundY),
    Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF8DA65A), Color(0xFF5E7A38)],
      ).createShader(Rect.fromLTWH(0, groundY, w, size.height - groundY)),
  );
  if (road) {
    final r = Rect.fromLTWH(0, groundY + 24, w, 58);
    canvas.drawRect(r, Paint()..color = const Color(0xFF4A4F57));
    final dash = Paint()
      ..color = const Color(0xFFF2F2F2)
      ..strokeWidth = 3;
    for (var x = 6.0; x < w; x += 34) {
      canvas.drawLine(Offset(x, r.center.dy), Offset(x + 18, r.center.dy), dash);
    }
  } else {
    canvas.drawPath(
      Path()
        ..moveTo(0, groundY + 40)
        ..quadraticBezierTo(150, groundY + 18, 360, groundY + 30)
        ..lineTo(360, groundY + 52)
        ..quadraticBezierTo(150, groundY + 42, 0, groundY + 70)
        ..close(),
      Paint()..color = const Color(0xFFB59B6A),
    );
  }
}

void _pole(Canvas c, double x, double top, double bottom) {
  c.drawRect(
    Rect.fromLTWH(x - 6, top, 12, bottom - top),
    Paint()
      ..shader = const LinearGradient(colors: [Color(0xFF8E9399), Color(0xFFC9CDD2), Color(0xFF8E9399)])
          .createShader(Rect.fromLTWH(x - 6, top, 12, bottom - top)),
  );
}

// ============================================================================
// Station 1 — the single line diagram
// ============================================================================

/// The SLD symbols the player can tap.
enum M3SldSym { ab, no, dtrA, dtrB, la, earth }

@immutable
class M3SldGeo {
  const M3SldGeo(this.h, {required this.noMid});
  final double h;

  /// The ring tie (NO point) branches off mid-feeder to the left; otherwise it
  /// closes the feeder at its far end.
  final bool noMid;

  Rect get paper => Rect.fromLTWH(14, 128, 332, h - 128 - 92);
  static const x = 120.0;
  double get _s0 => paper.top + 74;
  double get _len => paper.bottom - 54 - _s0;
  double at(double f) => _s0 + _len * f;

  Offset get source => Offset(x, paper.top + 40);
  Offset get cb => Offset(x, at(0));
  Offset get ab => Offset(x, at(0.17));
  double get yA => at(0.36);
  double get yB => at(0.66);
  double get yTie => at(0.51);
  Offset get no => noMid ? Offset(48, yTie + (paper.bottom - 40 - yTie) * 0.42) : Offset(x, at(0.86));
  Offset get feeder9 => noMid ? Offset(48, paper.bottom - 26) : Offset(x, paper.bottom - 22);
  Offset get dtrACoil => Offset(232, yA);
  Offset get dtrBCoil => Offset(232, yB);
  Offset get laBox => Offset(186, yA + 28);
  Offset get earthSym => Offset(186, yA + 58);

  Offset centre(M3SldSym s) => switch (s) {
        M3SldSym.ab => ab,
        M3SldSym.no => no,
        M3SldSym.dtrA => dtrACoil,
        M3SldSym.dtrB => dtrBCoil,
        M3SldSym.la => laBox,
        M3SldSym.earth => earthSym,
      };

  Rect hit(M3SldSym s) => Rect.fromCenter(center: centre(s), width: s == M3SldSym.dtrA || s == M3SldSym.dtrB ? 58 : 46, height: s == M3SldSym.earth ? 26 : 40);
}

/// The clipboard SLD. [marked]: symbols the player ringed as isolation points.
class M3SldPainter extends CustomPainter {
  const M3SldPainter({required this.geo, required this.marked});
  final M3SldGeo geo;
  final Set<M3SldSym> marked;

  static const _ink = Color(0xFF1D2B3A);

  @override
  void paint(Canvas canvas, Size size) {
    final g = geo;
    // Desk + clipboard.
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF5B4632));
    final board = g.paper.inflate(8);
    canvas.drawRRect(RRect.fromRectAndRadius(board, const Radius.circular(12)), Paint()..color = const Color(0xFF9B6B3E));
    canvas.drawRRect(RRect.fromRectAndRadius(g.paper, const Radius.circular(4)), Paint()..color = const Color(0xFFFBF8EF));
    final grid = Paint()
      ..color = const Color(0x1A2A62C9)
      ..strokeWidth = 0.7;
    for (var y = g.paper.top + 12; y < g.paper.bottom; y += 14) {
      canvas.drawLine(Offset(g.paper.left, y), Offset(g.paper.right, y), grid);
    }
    final clip = Rect.fromCenter(center: Offset(g.paper.center.dx, board.top + 4), width: 96, height: 20);
    canvas.drawRRect(RRect.fromRectAndRadius(clip, const Radius.circular(6)), Paint()..color = const Color(0xFFB8BEC6));
    _label(canvas, 'SLD · ফিডার-7', Offset(g.paper.right - 60, g.paper.top + 14), 9, _ink, bn: true);

    final line = _stroke(_ink, 2.2);
    // Source and CB.
    final src = Rect.fromCenter(center: g.source, width: 132, height: 26);
    canvas.drawRect(src, _stroke(_ink, 1.6));
    _label(canvas, '33/11 kV উপকেন্দ্র', g.source, 9.5, _ink, bn: true);
    canvas.drawLine(Offset(M3SldGeo.x, src.bottom), g.cb - const Offset(0, 9), line);
    canvas.drawRect(Rect.fromCenter(center: g.cb, width: 18, height: 18), _stroke(_ink, 2));
    _label(canvas, 'CB', g.cb + const Offset(24, 0), 8.5, _ink);
    _label(canvas, '11 kV', g.cb + const Offset(-36, 14), 8.5, _ink);
    // Main line down to the last DTR (or the NO point).
    final end = g.noMid ? g.yB : g.no.dy - 14;
    canvas.drawLine(g.cb + const Offset(0, 9), Offset(M3SldGeo.x, g.ab.dy - 14), line);
    _isolator(canvas, g.ab, 'AB-1');
    canvas.drawLine(Offset(M3SldGeo.x, g.ab.dy + 14), Offset(M3SldGeo.x, end), line);
    // DTR branches.
    _dtrBranch(canvas, g.yA, 'DTR-12', withLa: true);
    _dtrBranch(canvas, g.yB, 'DTR-17', withLa: false);
    // The ring tie.
    if (g.noMid) {
      canvas.drawCircle(Offset(M3SldGeo.x, g.yTie), 3, Paint()..color = _ink);
      canvas.drawLine(Offset(M3SldGeo.x, g.yTie), Offset(g.no.dx, g.yTie), line);
      canvas.drawLine(Offset(g.no.dx, g.yTie), g.no - const Offset(0, 14), line);
      _isolator(canvas, g.no, 'NO', labelLeft: false);
      canvas.drawLine(g.no + const Offset(0, 14), g.feeder9 - const Offset(0, 12), line);
      final f9 = Rect.fromCenter(center: g.feeder9, width: 60, height: 22);
      canvas.drawRect(f9, _stroke(_ink, 1.6));
      _label(canvas, 'ফিডার-9', g.feeder9, 8.5, _ink, bn: true);
      // End cap of the main line.
      canvas.drawLine(Offset(M3SldGeo.x - 8, g.yB), Offset(M3SldGeo.x + 8, g.yB), line);
    } else {
      _isolator(canvas, g.no, 'NO');
      canvas.drawLine(g.no + const Offset(0, 14), g.feeder9 - const Offset(0, 11), line);
      final f9 = Rect.fromCenter(center: g.feeder9, width: 72, height: 22);
      canvas.drawRect(f9, _stroke(_ink, 1.6));
      _label(canvas, 'ফিডার-9', g.feeder9, 8.5, _ink, bn: true);
    }
    // Ring marks.
    for (final s in marked) {
      final r = g.hit(s);
      canvas.drawOval(r.inflate(2), _stroke(const Color(0xFFD32F2F), 2.6));
    }
  }

  void _isolator(Canvas c, Offset p, String tag, {bool labelLeft = true}) {
    final ink = _stroke(_ink, 2.2);
    c.drawLine(p - const Offset(0, 14), p - const Offset(0, 8), ink);
    c.drawLine(p + const Offset(0, 8), p + const Offset(0, 14), ink);
    c.drawCircle(p + const Offset(0, 8), 2.2, Paint()..color = _ink);
    c.drawCircle(p - const Offset(0, 8), 2.2, Paint()..color = _ink);
    // The open blade: a broken line.
    c.drawLine(p + const Offset(0, 8), p + const Offset(10, -7), ink);
    _label(c, tag, p + Offset(labelLeft ? -26 : 24, 0), 9, _ink);
  }

  void _dtrBranch(Canvas c, double y, String name, {required bool withLa}) {
    final ink = _stroke(_ink, 2.2);
    c.drawCircle(Offset(M3SldGeo.x, y), 3, Paint()..color = _ink);
    c.drawLine(Offset(M3SldGeo.x, y), Offset(150, y), ink);
    // DO fuse: a fuse box with an arrow.
    final fuse = Rect.fromCenter(center: Offset(160, y), width: 20, height: 9);
    c.drawRect(fuse, _stroke(_ink, 1.6));
    c.drawLine(Offset(fuse.left, y), Offset(fuse.right, y), _stroke(_ink, 1));
    c.drawLine(Offset(156, y - 9), Offset(166, y - 14), _stroke(_ink, 1.4));
    c.drawLine(Offset(166, y - 14), Offset(162, y - 15), _stroke(_ink, 1.4));
    c.drawLine(Offset(170, y), Offset(208, y), ink);
    // Transformer: two coils that do not touch.
    c.drawCircle(Offset(222, y), 11, _stroke(_ink, 2));
    c.drawCircle(Offset(247, y), 11, _stroke(_ink, 2));
    c.drawLine(Offset(258, y), Offset(300, y), ink);
    c.drawLine(Offset(300, y), Offset(294, y - 5), ink);
    c.drawLine(Offset(300, y), Offset(294, y + 5), ink);
    _label(c, name, Offset(234, y - 22), 8.5, _ink);
    _label(c, '415 V', Offset(306, y + 12), 8, _ink);
    if (withLa) {
      final la = laAt(y);
      c.drawLine(Offset(la.dx, y), Offset(la.dx, la.dy - 12), ink);
      // Arrow-head on a box, down to earth.
      final p = Path()
        ..moveTo(la.dx - 6, la.dy - 12)
        ..lineTo(la.dx + 6, la.dy - 12)
        ..lineTo(la.dx, la.dy - 4)
        ..close();
      c.drawPath(p, Paint()..color = _ink);
      c.drawRect(Rect.fromCenter(center: la + const Offset(0, 4), width: 14, height: 14), _stroke(_ink, 1.8));
      _label(c, 'LA', la + const Offset(-20, 2), 8.5, _ink);
      final e = Offset(la.dx, la.dy + 30);
      c.drawLine(la + const Offset(0, 11), e - const Offset(0, 6), ink);
      for (var i = 0; i < 3; i++) {
        final hw = 10.0 - i * 3.4;
        c.drawLine(Offset(e.dx - hw, e.dy - 6 + i * 4), Offset(e.dx + hw, e.dy - 6 + i * 4), _stroke(_ink, 1.8));
      }
    }
  }

  Offset laAt(double y) => Offset(186, y + 28);

  @override
  bool shouldRepaint(M3SldPainter old) => old.geo.h != geo.h || old.geo.noMid != geo.noMid || old.marked.length != marked.length;
}

// ============================================================================
// Station 2 — the patrolled span
// ============================================================================

enum M3Part { pin, clamp, strand, disc, arm }

enum M3Fault { chip, slipped, cut, crack, rust, bent }

@immutable
class M3PatrolGeo {
  const M3PatrolGeo(this.h);
  final double h;
  double get groundY => h - 200;
  static const poleL = 84.0;
  static const poleR = 282.0;
  double get top => 168;
  double get armY => top + 22;
  double get sagY => armY + 44;

  Offset centre(M3Part p) => switch (p) {
        M3Part.pin => Offset(40, armY - 14),
        M3Part.clamp => Offset(poleL, armY + 24),
        M3Part.strand => Offset(182, sagY),
        M3Part.disc => Offset(poleR - 46, armY + 6),
        M3Part.arm => Offset(poleR + 30, armY),
      };

  Rect hit(M3Part p) => Rect.fromCenter(center: centre(p), width: p == M3Part.strand ? 64 : 48, height: 42);
}

/// The span seen from the ground. [faults]: what is wrong with each part;
/// [ok] / [flagged]: the player's verdicts so far.
class M3PatrolPainter extends CustomPainter {
  const M3PatrolPainter({required this.geo, required this.faults, required this.ok, required this.flagged});
  final M3PatrolGeo geo;
  final Map<M3Part, M3Fault?> faults;
  final Set<M3Part> ok;
  final Set<M3Part> flagged;

  @override
  void paint(Canvas canvas, Size size) {
    final g = geo;
    _sky(canvas, size, g.groundY);
    _pole(canvas, M3PatrolGeo.poleL, g.top, g.groundY + 6);
    _pole(canvas, M3PatrolGeo.poleR, g.top, g.groundY + 6);
    final steel = Paint()..color = const Color(0xFF5A6068);
    // Left pole: the cross-arm (tilts when the clamp slipped) with pin insulators.
    final slipped = faults[M3Part.clamp] == M3Fault.slipped;
    canvas.save();
    if (slipped) {
      canvas.translate(M3PatrolGeo.poleL, g.armY);
      canvas.rotate(0.09);
      canvas.translate(-M3PatrolGeo.poleL, -g.armY);
    }
    canvas.drawRect(Rect.fromLTWH(26, g.armY - 3, 116, 7), steel);
    for (final x in const [40.0, 128.0]) {
      M3PartPainter.pin(canvas, Offset(x, g.armY - 4), 1, chipped: x == 40 && faults[M3Part.pin] == M3Fault.chip);
    }
    canvas.restore();
    M3PartPainter.pin(canvas, Offset(M3PatrolGeo.poleL, g.top + 2), 1);
    // The clamp band on the pole and the brace.
    final cy = g.armY + (slipped ? 30 : 8);
    canvas.drawRect(Rect.fromLTWH(M3PatrolGeo.poleL - 9, cy - 4, 18, 9), Paint()..color = const Color(0xFF7D858E));
    canvas.drawLine(Offset(M3PatrolGeo.poleL, cy + 22), Offset(120, g.armY + 3), _stroke(const Color(0xFF5A6068), 3));
    // Right pole: a tension cross-arm with a disc string toward the span.
    final bent = faults[M3Part.arm] == M3Fault.bent;
    final rust = faults[M3Part.arm] == M3Fault.rust;
    final arm = Path()
      ..moveTo(M3PatrolGeo.poleR - 58, g.armY - 3)
      ..lineTo(M3PatrolGeo.poleR + 20, g.armY - 3)
      ..lineTo(M3PatrolGeo.poleR + 56, g.armY - 3 + (bent ? 13 : 0))
      ..lineTo(M3PatrolGeo.poleR + 56, g.armY + 4 + (bent ? 13 : 0))
      ..lineTo(M3PatrolGeo.poleR + 20, g.armY + 4)
      ..lineTo(M3PatrolGeo.poleR - 58, g.armY + 4)
      ..close();
    canvas.drawPath(arm, steel);
    if (rust) {
      final r = Paint()..color = const Color(0xFFB4572A);
      for (final dx in const [8.0, 22.0, 36.0, 48.0]) {
        canvas.drawOval(Rect.fromCenter(center: Offset(M3PatrolGeo.poleR + dx, g.armY + 1), width: 9, height: 6), r);
      }
    }
    M3PartPainter.disc(canvas, Offset(M3PatrolGeo.poleR - 46, g.armY + 6), 1, cracked: faults[M3Part.disc] == M3Fault.crack);
    M3PartPainter.disc(canvas, Offset(M3PatrolGeo.poleR + 46, g.armY + 6 + (bent ? 12 : 0)), 1);
    // Conductors: insulator tops on the left to the disc strings on the right.
    final wire = _stroke(const Color(0xFF2F343A), 1.8);
    for (final (fromX, dy) in const [(40.0, 0.0), (128.0, 0.0), (84.0, -26.0)]) {
      final from = Offset(fromX, g.armY - 20 + dy + (slipped && fromX != 84 ? (fromX - 84) * 0.09 : 0));
      final to = Offset(M3PatrolGeo.poleR - 66, g.armY + 6 + dy * 0.4);
      canvas.drawPath(Path()..moveTo(from.dx, from.dy)..quadraticBezierTo((from.dx + to.dx) / 2, g.sagY + dy * 0.6, to.dx, to.dy), wire);
    }
    canvas.drawLine(Offset(M3PatrolGeo.poleR + 66, g.armY + 6), Offset(size.width + 4, g.armY + 30), wire);
    if (faults[M3Part.strand] == M3Fault.cut) {
      final p = g.centre(M3Part.strand) + const Offset(0, -6);
      final f = _stroke(const Color(0xFFB9BFC6), 1.3);
      for (var i = 0; i < 5; i++) {
        final a = -1.9 + i * 0.32;
        canvas.drawLine(p, p + Offset(math.cos(a), math.sin(a)) * 11, f);
      }
    }
    // Verdict tags.
    for (final part in M3Part.values) {
      final c = g.hit(part).topRight + const Offset(-6, 4);
      if (ok.contains(part)) {
        canvas.drawCircle(c, 8, Paint()..color = const Color(0xFF2E7D32));
        _label(canvas, '✓', c, 10, Colors.white);
      } else if (flagged.contains(part)) {
        canvas.drawCircle(c, 8, Paint()..color = const Color(0xFFC62828));
        _label(canvas, '!', c, 11, Colors.white);
      }
    }
  }

  @override
  bool shouldRepaint(M3PatrolPainter old) => old.geo.h != geo.h || old.ok.length != ok.length || old.flagged.length != flagged.length;
}

/// A part seen up close (the inspect sheet), or drawn small in the span.
class M3PartPainter extends CustomPainter {
  const M3PartPainter(this.part, this.fault);
  final M3Part part;
  final M3Fault? fault;

  static void pin(Canvas c, Offset base, double s, {bool chipped = false}) {
    final body = Paint()..color = const Color(0xFF8C5A3C);
    final rim = Paint()..color = const Color(0xFFA8714D);
    c.drawRect(Rect.fromCenter(center: base + Offset(0, -4 * s), width: 3 * s, height: 8 * s), Paint()..color = const Color(0xFF6B7178));
    final sheds = [(-10.0, 9.0), (-17.0, 7.5), (-23.0, 5.5)];
    for (final (dy, hw) in sheds) {
      c.drawOval(Rect.fromCenter(center: base + Offset(0, dy * s), width: hw * 2 * s, height: 5 * s), rim);
    }
    c.drawRect(Rect.fromLTWH(base.dx - 3.5 * s, base.dy - 26 * s, 7 * s, 18 * s), body);
    if (chipped) {
      c.drawPath(
        Path()
          ..moveTo(base.dx - 9.5 * s, base.dy - 12 * s)
          ..lineTo(base.dx - 4 * s, base.dy - 10 * s)
          ..lineTo(base.dx - 8 * s, base.dy - 6 * s)
          ..close(),
        Paint()..color = const Color(0xFFF2E6D6),
      );
      c.drawCircle(base + Offset(-2 * s, -14 * s), 2.4 * s, Paint()..color = const Color(0xAA222222));
    }
  }

  static void disc(Canvas c, Offset centre, double s, {bool cracked = false}) {
    final d = Paint()..color = const Color(0xFF8C5A3C);
    final hi = Paint()..color = const Color(0xFFB07A55);
    for (var i = -1; i <= 1; i++) {
      final cc = centre + Offset(i * 9.0 * s, 0);
      c.drawOval(Rect.fromCenter(center: cc, width: 7 * s, height: 20 * s), d);
      c.drawOval(Rect.fromCenter(center: cc + Offset(-1 * s, -3 * s), width: 3 * s, height: 8 * s), hi);
    }
    c.drawLine(centre + Offset(-17 * s, 0), centre + Offset(17 * s, 0), _stroke(const Color(0xFF5A6068), 1.4 * s));
    if (cracked) {
      final crack = _stroke(const Color(0xFF111111), math.max(0.8, 0.7 * s));
      final x = centre.dx;
      c.drawPath(
        Path()
          ..moveTo(x - 1 * s, centre.dy - 9 * s)
          ..lineTo(x + 1.5 * s, centre.dy - 4 * s)
          ..lineTo(x - 1 * s, centre.dy)
          ..lineTo(x + 1.2 * s, centre.dy + 5 * s),
        crack,
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width / 120, size.height / 90);
    final c = Offset(size.width / 2, size.height / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
      Paint()..color = const Color(0xFFCFE6F5),
    );
    switch (part) {
      case M3Part.pin:
        canvas.drawRect(Rect.fromLTWH(0, c.dy + 18 * s, size.width, 8 * s), Paint()..color = const Color(0xFF5A6068));
        pin(canvas, Offset(c.dx, c.dy + 18 * s), s * 2, chipped: fault == M3Fault.chip);
      case M3Part.disc:
        canvas.drawLine(Offset(0, c.dy), Offset(size.width, c.dy), _stroke(const Color(0xFF2F343A), 2 * s));
        disc(canvas, c, s * 2.2, cracked: fault == M3Fault.crack);
      case M3Part.strand:
        final y = c.dy;
        for (var i = -3; i <= 3; i++) {
          canvas.drawLine(Offset(0, y + i * 2.2 * s), Offset(size.width, y + i * 2.2 * s), _stroke(i.isEven ? const Color(0xFFB9BFC6) : const Color(0xFF9AA1A9), 2.2 * s));
        }
        if (fault == M3Fault.cut) {
          final f = _stroke(const Color(0xFFD5DADF), 2 * s);
          for (var i = 0; i < 6; i++) {
            final a = -2.2 + i * 0.36;
            canvas.drawLine(c + Offset(0, -4 * s), c + Offset(0, -4 * s) + Offset(math.cos(a), math.sin(a)) * 26 * s, f);
          }
        }
      case M3Part.clamp:
        _pole(canvas, c.dx, 0, size.height);
        final slipped = fault == M3Fault.slipped;
        final y = slipped ? c.dy + 22 * s : c.dy - 6 * s;
        canvas.drawRect(Rect.fromCenter(center: Offset(c.dx, y), width: 34 * s, height: 14 * s), Paint()..color = const Color(0xFF7D858E));
        for (final dx in const [-12.0, 12.0]) {
          canvas.drawCircle(Offset(c.dx + dx * s, y), 3 * s, Paint()..color = const Color(0xFF3B4148));
        }
        canvas.save();
        canvas.translate(c.dx, c.dy - 18 * s);
        if (slipped) canvas.rotate(0.14);
        canvas.drawRect(Rect.fromLTWH(-56 * s, -4 * s, 112 * s, 9 * s), Paint()..color = const Color(0xFF5A6068));
        canvas.restore();
        if (slipped) {
          canvas.drawRect(Rect.fromCenter(center: Offset(c.dx, c.dy - 6 * s), width: 34 * s, height: 14 * s), _stroke(const Color(0x88FFFFFF), 1.2 * s));
        }
      case M3Part.arm:
        final bent = fault == M3Fault.bent;
        final arm = Path()
          ..moveTo(4 * s, c.dy - 6 * s)
          ..lineTo(c.dx, c.dy - 6 * s)
          ..lineTo(size.width - 6 * s, c.dy - 6 * s + (bent ? 26 * s : 0))
          ..lineTo(size.width - 6 * s, c.dy + 8 * s + (bent ? 26 * s : 0))
          ..lineTo(c.dx, c.dy + 8 * s)
          ..lineTo(4 * s, c.dy + 8 * s)
          ..close();
        canvas.drawPath(arm, Paint()..color = const Color(0xFF8E959C));
        if (fault == M3Fault.rust) {
          final r = Paint()..color = const Color(0xFFB4572A);
          final r2 = Paint()..color = const Color(0xFF7A3418);
          for (final dx in const [16.0, 40.0, 66.0, 90.0]) {
            canvas.drawOval(Rect.fromCenter(center: Offset(dx * s, c.dy), width: 14 * s, height: 10 * s), r);
            canvas.drawCircle(Offset(dx * s + 2 * s, c.dy + 1 * s), 2.4 * s, r2);
          }
        }
    }
  }

  @override
  bool shouldRepaint(M3PartPainter old) => old.part != part || old.fault != fault;
}

// ============================================================================
// Stations 3 and 4 — the DTR yard
// ============================================================================

enum M3LaFault { crack, hanging }

@immutable
class M3DtrGeo {
  const M3DtrGeo(this.h);
  final double h;
  double get groundY => h - 196;
  static const doPole = 64.0;
  double get top => 150;
  double get armY => top + 20;
  double doX(int i) => 28.0 + i * 36;
  double get doTop => armY + 6;
  static const doLen = 36.0;
  Rect doHit(int i) => Rect.fromLTWH(doX(i) - 16, doTop - 10, 32, doLen + 30);

  Rect get plinth => Rect.fromLTWH(128, groundY - 34, 168, 40);
  Rect get tank => Rect.fromLTWH(146, groundY - 34 - 128, 132, 128);
  Rect get conservator => Rect.fromLTWH(160, tank.top - 46, 104, 24);
  Rect get breather => Rect.fromLTWH(142, conservator.bottom + 6, 16, 34);
  Offset get gauge => Offset(conservator.right - 10, conservator.center.dy);
  Rect get oilHit => Rect.fromLTWH(tank.left - 6, tank.bottom - 30, 54, 50);
  Rect get breatherHit => breather.inflate(14);
  Offset get tapDial => Offset(tank.left + 40, tank.top + 44);
  Rect get tapHit => Rect.fromCircle(center: tapDial, radius: 24);
  double htX(int i) => tank.left + 34.0 + i * 30;
  Rect get la => Rect.fromLTWH(tank.right + 18, tank.top - 54, 14, 40);
  Rect get laHit => Rect.fromLTWH(la.left - 14, la.top - 10, la.width + 28, la.height + 46);
  Rect get ltBox => Rect.fromLTWH(306, groundY - 96, 44, 58);
  Rect get ltSwitch => Rect.fromLTWH(ltBox.left + 8, ltBox.top + 22, 28, 18);
  Rect get ltHit => ltBox.inflate(6);
}

class M3DtrPainter extends CustomPainter {
  const M3DtrPainter({
    required this.geo,
    required this.doOpen,
    required this.dropped,
    required this.laFault,
    required this.laReplaced,
    required this.gelPink,
    required this.gelNew,
    required this.oilLeak,
    required this.oilFixed,
    required this.ltOn,
    required this.tap,
  });

  final M3DtrGeo geo;
  final List<bool> doOpen;
  final int dropped;
  final M3LaFault? laFault;
  final bool laReplaced;
  final bool gelPink;
  final bool gelNew;
  final bool oilLeak;
  final bool oilFixed;
  final bool ltOn;
  final int tap;

  @override
  void paint(Canvas canvas, Size size) {
    final g = geo;
    _sky(canvas, size, g.groundY);
    // HT line in from the left.
    final wire = _stroke(const Color(0xFF2F343A), 1.6);
    for (var i = 0; i < 3; i++) {
      canvas.drawPath(Path()..moveTo(-4, g.top - 34 + i * 4)..quadraticBezierTo(10, g.top - 4, g.doX(i), g.doTop - 6), wire);
    }
    _pole(canvas, M3DtrGeo.doPole, g.top - 20, g.groundY + 6);
    canvas.drawRect(Rect.fromLTWH(10, g.armY - 4, 112, 7), Paint()..color = const Color(0xFF4A5058));
    for (var i = 0; i < 3; i++) {
      _do(canvas, i, doOpen[i] || i == dropped);
    }
    // Jumpers from the DO bottoms to the HT bushings.
    final t = g.tank;
    for (var i = 0; i < 3; i++) {
      canvas.drawPath(
        Path()
          ..moveTo(g.doX(i), g.doTop + M3DtrGeo.doLen + 8)
          ..quadraticBezierTo(g.htX(i) - 30, g.doTop + 70 + i * 6, g.htX(i), t.top - 30),
        wire,
      );
    }
    // Plinth and tank.
    canvas.drawRect(g.plinth, Paint()..color = const Color(0xFFA9A397));
    canvas.drawRect(Rect.fromLTWH(g.plinth.left, g.plinth.top, g.plinth.width, 4), Paint()..color = const Color(0xFFC8C2B6));
    canvas.drawRRect(
      RRect.fromRectAndRadius(t, const Radius.circular(5)),
      Paint()..shader = const LinearGradient(colors: [Color(0xFF6C7B66), Color(0xFF9AAB92), Color(0xFF6C7B66)]).createShader(t),
    );
    final fin = _stroke(const Color(0xFF55634F), 2);
    for (var x = t.left + 66; x < t.right - 6; x += 8) {
      canvas.drawLine(Offset(x, t.top + 12), Offset(x, t.bottom - 8), fin);
    }
    // Conservator, oil gauge, breather.
    final cons = g.conservator;
    canvas.drawRRect(RRect.fromRectAndRadius(cons, const Radius.circular(12)), Paint()..color = const Color(0xFF7E8E77));
    canvas.drawLine(Offset(cons.center.dx, cons.bottom), Offset(cons.center.dx, t.top), _stroke(const Color(0xFF55634F), 4));
    canvas.drawCircle(g.gauge, 8, Paint()..color = Colors.white);
    canvas.drawCircle(g.gauge, 8, _stroke(const Color(0xFF26303D), 1.4));
    final low = oilLeak && !oilFixed;
    canvas.drawLine(g.gauge, g.gauge + Offset(low ? -5 : 5, low ? 4 : -5), _stroke(const Color(0xFFC62828), 1.6));
    final b = g.breather;
    canvas.drawLine(Offset(b.center.dx, cons.center.dy), Offset(b.center.dx, b.top), _stroke(const Color(0xFF55634F), 3));
    canvas.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(4)), Paint()..color = const Color(0xFFE8EEF2));
    final gel = gelPink && !gelNew ? const Color(0xFFF4A3C0) : const Color(0xFF2F6FD6);
    final dots = Paint()..color = gel;
    for (var y = b.top + 6; y < b.bottom - 3; y += 5) {
      for (var x = b.left + 4; x < b.right - 2; x += 5) {
        canvas.drawCircle(Offset(x, y), 2, dots);
      }
    }
    // HT bushings (big) and LT bushings (small).
    for (var i = 0; i < 3; i++) {
      _bushing(canvas, Offset(g.htX(i), t.top), 30, 7);
    }
    for (var i = 0; i < 4; i++) {
      _bushing(canvas, Offset(t.right - 16 - i * 13.0, t.top), 14, 4);
    }
    _plate(canvas, Rect.fromLTWH(t.left + 74, t.top + 54, 50, 28), 'DTR-17', '100 kVA');
    // Tap dial.
    final d = g.tapDial;
    canvas.drawCircle(d, 17, Paint()..color = const Color(0xFF3B4148));
    canvas.drawCircle(d, 15, Paint()..color = const Color(0xFFE6E2D6));
    for (var p = 1; p <= 5; p++) {
      final a = -math.pi * 0.9 + (p - 1) * math.pi * 0.45;
      _label(canvas, '$p', d + Offset(math.cos(a), math.sin(a)) * 10.5, 6.5, const Color(0xFF26303D));
    }
    final a = -math.pi * 0.9 + (tap - 1) * math.pi * 0.45;
    canvas.drawLine(d, d + Offset(math.cos(a), math.sin(a)) * 7, _stroke(const Color(0xFFC62828), 2.4));
    _label(canvas, 'TAP', d + const Offset(0, 24), 7, const Color(0xFFF2F2F2));
    // Oil leak.
    if (oilLeak && !oilFixed) {
      final drip = Paint()..color = const Color(0xFF3A2A12);
      canvas.drawPath(
        Path()
          ..moveTo(t.left + 12, t.bottom - 6)
          ..quadraticBezierTo(t.left + 8, t.bottom + 6, t.left + 12, t.bottom + 10)
          ..quadraticBezierTo(t.left + 16, t.bottom + 6, t.left + 12, t.bottom - 6),
        drip,
      );
      canvas.drawOval(Rect.fromCenter(center: Offset(t.left + 16, g.plinth.top + 6), width: 46, height: 9), Paint()..color = const Color(0xCC2A1E0C));
    }
    // LA beside the HT bushings, its earth lead down the side.
    final la = g.la;
    final bad = laFault != null && !laReplaced;
    canvas.drawLine(Offset(g.htX(2), t.top - 30), Offset(la.center.dx, la.top), wire);
    for (var y = la.top; y < la.bottom; y += 8) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(la.left - 2, y, la.width + 4, 6), const Radius.circular(3)), Paint()..color = const Color(0xFF8C5A3C));
    }
    canvas.drawRect(Rect.fromLTWH(la.left + 3, la.top, la.width - 6, la.height), Paint()..color = const Color(0xFF7A4B2F));
    canvas.drawRect(Rect.fromLTWH(la.left + 1, la.bottom, la.width - 2, 7), Paint()..color = const Color(0xFF4A5058));
    if (bad && laFault == M3LaFault.crack) {
      canvas.drawPath(
        Path()
          ..moveTo(la.center.dx - 2, la.top + 6)
          ..lineTo(la.center.dx + 3, la.top + 16)
          ..lineTo(la.center.dx - 2, la.top + 24)
          ..lineTo(la.center.dx + 2, la.top + 32),
        _stroke(const Color(0xFF111111), 1.4),
      );
      canvas.drawCircle(Offset(la.center.dx + 3, la.top + 28), 4, Paint()..color = const Color(0x99222222));
    }
    final earth = _stroke(const Color(0xFF3B6E3B), 2);
    final leadTop = Offset(la.center.dx, la.bottom + 7);
    if (bad && laFault == M3LaFault.hanging) {
      // The disconnector blew: the lead hangs loose.
      canvas.drawLine(leadTop + const Offset(4, 10), leadTop + const Offset(10, 64), earth);
      canvas.drawLine(Offset(la.center.dx + 8, g.groundY - 40), Offset(la.center.dx + 8, g.groundY + 6), earth);
    } else {
      canvas.drawPath(Path()..moveTo(leadTop.dx, leadTop.dy)..lineTo(leadTop.dx + 8, leadTop.dy + 20)..lineTo(leadTop.dx + 8, g.groundY + 6), earth);
    }
    // LT box with its switch, cable from the LT bushings.
    canvas.drawPath(
      Path()
        ..moveTo(t.right - 16, t.top - 14)
        ..quadraticBezierTo(t.right + 40, t.top - 10, g.ltBox.center.dx, g.ltBox.top),
      _stroke(const Color(0xFF1B1E22), 4),
    );
    final box = g.ltBox;
    canvas.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(3)), Paint()..color = const Color(0xFF8B969F));
    canvas.drawRRect(RRect.fromRectAndRadius(box.deflate(2), const Radius.circular(2)), Paint()..color = const Color(0xFFA9B4BC));
    _label(canvas, 'LT', Offset(box.center.dx, box.top + 10), 8, const Color(0xFF26303D));
    final sw = g.ltSwitch;
    canvas.drawRRect(RRect.fromRectAndRadius(sw, const Radius.circular(3)), Paint()..color = ltOn ? const Color(0xFFC62828) : const Color(0xFF2E7D32));
    _label(canvas, ltOn ? 'ON' : 'OFF', sw.center, 7.5, Colors.white);
    canvas.drawRect(Rect.fromLTWH(box.left + 18, box.bottom, 8, g.groundY - box.bottom + 6), Paint()..color = const Color(0xFF6B7178));
  }

  void _do(Canvas c, int i, bool open) {
    final g = geo;
    final x = g.doX(i);
    final por = Paint()..color = const Color(0xFF8C5A3C);
    c.drawRect(Rect.fromLTWH(x - 3.5, g.doTop - 8, 7, 10), por);
    c.drawRect(Rect.fromLTWH(x - 3.5, g.doTop + M3DtrGeo.doLen - 2, 7, 10), por);
    final tube = Paint()
      ..color = const Color(0xFF3B3F45)
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round;
    final bottom = Offset(x, g.doTop + M3DtrGeo.doLen);
    if (open) {
      c.drawLine(bottom, bottom + const Offset(15, M3DtrGeo.doLen * 0.8), tube);
    } else {
      c.drawLine(Offset(x, g.doTop + 2), bottom, tube);
      c.drawCircle(Offset(x + 4, g.doTop + 6), 3.4, _stroke(const Color(0xFF9AA4AE), 1.6));
    }
  }

  void _bushing(Canvas c, Offset base, double h, double w) {
    final p = Paint()..color = const Color(0xFF8C5A3C);
    for (var y = 0.0; y < h; y += 6) {
      c.drawOval(Rect.fromCenter(center: base - Offset(0, y + 3), width: w * 2, height: 4), p);
    }
    c.drawRect(Rect.fromLTWH(base.dx - w / 2, base.dy - h, w, h), p);
  }

  void _plate(Canvas c, Rect r, String a, String b) {
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), Paint()..color = const Color(0xFFE9E4D4));
    _label(c, a, Offset(r.center.dx, r.top + 8), 7.5, const Color(0xFF26303D));
    _label(c, b, Offset(r.center.dx, r.bottom - 8), 7.5, const Color(0xFF26303D));
  }

  @override
  bool shouldRepaint(M3DtrPainter old) =>
      old.geo.h != geo.h ||
      old.doOpen.where((o) => o).length != doOpen.where((o) => o).length ||
      old.laReplaced != laReplaced ||
      old.gelNew != gelNew ||
      old.oilFixed != oilFixed ||
      old.ltOn != ltOn ||
      old.tap != tap ||
      old.dropped != dropped;
}

/// Small LA close-up for the inspect sheet.
class M3LaPainter extends CustomPainter {
  const M3LaPainter(this.fault);
  final M3LaFault? fault;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)), Paint()..color = const Color(0xFFCFE6F5));
    final s = size.height / 170;
    final cx = size.width / 2;
    final top = 14 * s;
    canvas.drawLine(Offset(cx, 0), Offset(cx, top), _stroke(const Color(0xFF2F343A), 2.4 * s));
    for (var y = top; y < top + 90 * s; y += 16 * s) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(cx - 20 * s, y, 40 * s, 12 * s), Radius.circular(6 * s)),
        Paint()..color = const Color(0xFF8C5A3C),
      );
    }
    canvas.drawRect(Rect.fromLTWH(cx - 12 * s, top, 24 * s, 90 * s), Paint()..color = const Color(0xFF7A4B2F));
    final disc = Rect.fromLTWH(cx - 10 * s, top + 92 * s, 20 * s, 14 * s);
    canvas.drawRect(disc, Paint()..color = const Color(0xFF4A5058));
    _label(canvas, 'disconnector', Offset(cx + 54 * s, disc.center.dy), 8 * s, const Color(0xFF26303D));
    final earth = _stroke(const Color(0xFF3B6E3B), 3 * s);
    if (fault == M3LaFault.hanging) {
      canvas.drawLine(Offset(cx + 6 * s, disc.bottom + 14 * s), Offset(cx + 26 * s, size.height - 6 * s), earth);
      canvas.drawCircle(Offset(cx, disc.bottom + 4 * s), 5 * s, Paint()..color = const Color(0xFF222222));
    } else {
      canvas.drawLine(Offset(cx, disc.bottom), Offset(cx, size.height), earth);
    }
    if (fault == M3LaFault.crack) {
      canvas.drawPath(
        Path()
          ..moveTo(cx - 3 * s, top + 10 * s)
          ..lineTo(cx + 5 * s, top + 34 * s)
          ..lineTo(cx - 4 * s, top + 52 * s)
          ..lineTo(cx + 4 * s, top + 76 * s),
        _stroke(const Color(0xFF111111), 2 * s),
      );
      canvas.drawCircle(Offset(cx + 6 * s, top + 66 * s), 9 * s, Paint()..color = const Color(0x88222222));
    }
  }

  @override
  bool shouldRepaint(M3LaPainter old) => old.fault != fault;
}

// ============================================================================
// Station 5 — the LT feeder pillar
// ============================================================================

@immutable
class M3PillarGeo {
  const M3PillarGeo(this.h);
  final double h;
  Rect get box => Rect.fromLTWH(26, 150, 308, math.max(330, h - 150 - 168));
  double busY(int i) => box.top + 40 + i * 22.0;
  Rect get busHit => Rect.fromLTWH(box.left + 14, busY(0) - 10, box.width - 28, 22 * 4.0);

  /// Joint bolts on the busbars: index = phase * 2 + side (0 left, 1 right).
  Offset bolt(int i) => Offset(i.isEven ? box.left + 62 : box.right - 62, busY(i ~/ 2));
  Rect boltHit(int i) => Rect.fromCenter(center: bolt(i), width: 36, height: 22);

  /// HRC fuse carriers of the three outgoing ways (way × R/Y/B).
  Offset fuse(int way, int ph) => Offset(box.left + 58 + way * 96.0 + (ph - 1) * 24, box.top + 182);
  Rect fuseHit(int way, int ph) => Rect.fromCenter(center: fuse(way, ph), width: 24, height: 62);
}

class M3PillarPainter extends CustomPainter {
  const M3PillarPainter({
    required this.geo,
    required this.doorOpen,
    required this.blownWay,
    required this.blownPh,
    required this.fitted,
    required this.hotBolt,
    required this.tightened,
    required this.tested,
  });
  final M3PillarGeo geo;
  final bool doorOpen;
  final int blownWay;
  final int blownPh;
  final bool fitted;
  final int hotBolt;
  final bool tightened;
  final bool tested;

  static const _phase = [Color(0xFFD7312B), Color(0xFFF2C40F), Color(0xFF2A62C9), Color(0xFF16181C)];

  @override
  void paint(Canvas canvas, Size size) {
    final g = geo;
    _sky(canvas, size, g.box.bottom + 20);
    final b = g.box;
    canvas.drawRect(Rect.fromLTWH(b.left - 6, b.bottom, b.width + 12, 18), Paint()..color = const Color(0xFFA9A397));
    canvas.drawRRect(RRect.fromRectAndRadius(b.inflate(6), const Radius.circular(6)), Paint()..color = const Color(0xFF6E7B86));
    canvas.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(4)), Paint()..color = const Color(0xFF2B333B));
    if (!doorOpen) {
      canvas.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(4)), Paint()..color = const Color(0xFF8B969F));
      for (var y = b.top + 20; y < b.bottom - 10; y += 14) {
        canvas.drawLine(Offset(b.left + 20, y), Offset(b.right - 20, y), _stroke(const Color(0xFF7A858E), 1));
      }
      final plate = Rect.fromCenter(center: b.center - const Offset(0, 40), width: 120, height: 54);
      canvas.drawRRect(RRect.fromRectAndRadius(plate, const Radius.circular(4)), Paint()..color = const Color(0xFFFFE04A));
      canvas.drawRRect(RRect.fromRectAndRadius(plate, const Radius.circular(4)), _stroke(const Color(0xFFB71C1C), 2));
      _label(canvas, '⚡ 415 V', plate.center - const Offset(0, 10), 13, const Color(0xFFB71C1C));
      _label(canvas, 'ফিডার পিলার', plate.center + const Offset(0, 12), 11, const Color(0xFFB71C1C), bn: true);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(b.right - 34, b.center.dy - 16, 12, 32), const Radius.circular(3)),
        Paint()..color = const Color(0xFF3B4148),
      );
      return;
    }
    // Busbars R Y B N with joint bolts.
    for (var i = 0; i < 4; i++) {
      final y = g.busY(i);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(b.left + 18, y - 5, b.width - 36, 10), const Radius.circular(2)), Paint()..color = const Color(0xFFC98A4B));
      canvas.drawRect(Rect.fromLTWH(b.left + 18, y - 5, 10, 10), Paint()..color = _phase[i]);
      _label(canvas, const ['R', 'Y', 'B', 'N'][i], Offset(b.left + 23, y), 7, i == 1 ? Colors.black : Colors.white);
    }
    for (var i = 0; i < 6; i++) {
      final p = g.bolt(i);
      final hot = i == hotBolt && !tightened;
      if (hot) {
        canvas.drawOval(Rect.fromCenter(center: p, width: 30, height: 16), Paint()..color = const Color(0xFF1A1410));
        canvas.drawOval(Rect.fromCenter(center: p, width: 18, height: 10), Paint()..color = const Color(0xFF3A2416));
      }
      canvas.drawCircle(p, 4.2, Paint()..color = hot ? const Color(0xFF2A2420) : const Color(0xFF9AA4AE));
      canvas.drawCircle(p, 4.2, _stroke(const Color(0xFF3B4148), 1));
    }
    // Outgoing ways: three HRC fuses each.
    for (var w = 0; w < 3; w++) {
      final x0 = b.left + 22 + w * 96.0;
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x0, b.top + 140, 74, 90), const Radius.circular(4)), Paint()..color = const Color(0xFF39434D));
      _label(canvas, 'OUT-${w + 1}', Offset(x0 + 37, b.top + 148), 7.5, const Color(0xFFE0E6EA));
      for (var ph = 0; ph < 3; ph++) {
        final c = g.fuse(w, ph);
        final missing = w == blownWay && ph == blownPh;
        canvas.drawLine(Offset(c.dx, g.busY(ph) + 5), Offset(c.dx, c.dy - 26), _stroke(const Color(0x66C98A4B), 2));
        canvas.drawRect(Rect.fromCenter(center: c - const Offset(0, 26), width: 14, height: 6), Paint()..color = const Color(0xFF9AA4AE));
        canvas.drawRect(Rect.fromCenter(center: c + const Offset(0, 26), width: 14, height: 6), Paint()..color = const Color(0xFF9AA4AE));
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: c, width: 16, height: 42), const Radius.circular(4)),
          Paint()..color = const Color(0xFFEDE7DA),
        );
        canvas.drawRect(Rect.fromCenter(center: c - const Offset(0, 22), width: 12, height: 4), Paint()..color = const Color(0xFF7D858E));
        canvas.drawRect(Rect.fromCenter(center: c + const Offset(0, 22), width: 12, height: 4), Paint()..color = const Color(0xFF7D858E));
        if (missing && !fitted) {
          // The blown fuse's indicator has popped (red).
          canvas.drawCircle(c - const Offset(0, 12), 4.5, Paint()..color = const Color(0xFFD32F2F));
          canvas.drawCircle(c + const Offset(0, 2), 3, Paint()..color = const Color(0x55000000));
        }
        _label(canvas, 'HRC', c + const Offset(0, 6), 5.5, const Color(0xFF5A5040));
      }
    }
    // Earth terminal and the neutral link.
    canvas.drawRect(Rect.fromLTWH(b.left + 18, b.bottom - 34, 60, 10), Paint()..color = const Color(0xFF3B6E3B));
    _label(canvas, 'E', Offset(b.left + 88, b.bottom - 29), 8, const Color(0xFF9BE7B0));
    if (tested) {
      _label(canvas, '0 V', Offset(b.right - 42, g.busY(0) - 18), 10, const Color(0xFF9BE7B0));
    }
    // The open door, swung to the left edge.
    canvas.drawPath(
      Path()
        ..moveTo(b.left - 4, b.top)
        ..lineTo(b.left - 22, b.top + 14)
        ..lineTo(b.left - 22, b.bottom - 14)
        ..lineTo(b.left - 4, b.bottom)
        ..close(),
      Paint()..color = const Color(0xFF7A858E),
    );
  }

  @override
  bool shouldRepaint(M3PillarPainter old) =>
      old.geo.h != geo.h ||
      old.doorOpen != doorOpen ||
      old.fitted != fitted ||
      old.tightened != tightened ||
      old.tested != tested ||
      old.blownWay != blownWay ||
      old.blownPh != blownPh ||
      old.hotBolt != hotBolt;
}

// ============================================================================
// Station 6 — the service drop
// ============================================================================

@immutable
class M3ServiceGeo {
  const M3ServiceGeo(this.h);
  final double h;
  double get groundY => h - 210;
  static const poleX = 54.0;
  double get poleTop => 170;
  Rect get house => Rect.fromLTWH(206, groundY - 150, 140, 150);
  Rect get meter => Rect.fromLTWH(house.left + 22, house.top + 58, 34, 44);
  Offset get poleTap => Offset(poleX + 8, poleTop + 34);
}

class M3ServicePainter extends CustomPainter {
  const M3ServicePainter({
    required this.geo,
    required this.threePhase,
    required this.cableOn,
    required this.bearer,
    required this.drip,
    required this.neutralDone,
  });
  final M3ServiceGeo geo;
  final bool threePhase;
  final bool cableOn;
  final bool bearer;
  final bool drip;
  final bool neutralDone;

  @override
  void paint(Canvas canvas, Size size) {
    final g = geo;
    _sky(canvas, size, g.groundY);
    // LT pole with four wires.
    _pole(canvas, M3ServiceGeo.poleX, g.poleTop - 10, g.groundY + 6);
    canvas.drawRect(Rect.fromLTWH(M3ServiceGeo.poleX - 4, g.poleTop - 4, 10, 64), Paint()..color = const Color(0xFF5A6068));
    final wire = _stroke(const Color(0xFF2F343A), 1.6);
    for (var i = 0; i < 4; i++) {
      final y = g.poleTop + i * 14.0;
      M3PartPainter.pin(canvas, Offset(M3ServiceGeo.poleX + 12, y + 6), 0.5);
      canvas.drawLine(Offset(-4, y + 6), Offset(M3ServiceGeo.poleX + 40, y + 10), wire);
    }
    // House.
    final hs = g.house;
    canvas.drawRect(hs, Paint()..color = const Color(0xFFE8D9BC));
    canvas.drawPath(
      Path()
        ..moveTo(hs.left - 10, hs.top)
        ..lineTo(hs.center.dx, hs.top - 40)
        ..lineTo(hs.right + 10, hs.top)
        ..close(),
      Paint()..color = const Color(0xFFB0563A),
    );
    canvas.drawRect(Rect.fromLTWH(hs.right - 54, hs.bottom - 70, 34, 70), Paint()..color = const Color(0xFF7A4E2A));
    canvas.drawRect(Rect.fromLTWH(hs.left + 72, hs.top + 34, 30, 26), Paint()..color = const Color(0xFF6FA0C8));
    final m = g.meter;
    canvas.drawRRect(RRect.fromRectAndRadius(m, const Radius.circular(4)), Paint()..color = const Color(0xFFF4F1E8));
    canvas.drawRRect(RRect.fromRectAndRadius(m, const Radius.circular(4)), _stroke(const Color(0xFF3B4148), 1.4));
    canvas.drawRect(Rect.fromLTWH(m.left + 5, m.top + 7, m.width - 10, 10), Paint()..color = const Color(0xFF8DD3A0));
    _label(canvas, 'kWh', Offset(m.center.dx, m.top + 26), 7, const Color(0xFF26303D));
    canvas.drawCircle(Offset(m.right - 6, m.bottom - 6), 2.6, Paint()..color = const Color(0xFFD32F2F));
    // Connection plate.
    final plate = Rect.fromLTWH(hs.left + 64, hs.top + 74, 66, 18);
    canvas.drawRRect(RRect.fromRectAndRadius(plate, const Radius.circular(3)), Paint()..color = const Color(0xFF1B3A57));
    _label(canvas, threePhase ? '3-ফেজ সংযোগ' : '1-ফেজ সংযোগ', plate.center, 8, Colors.white, bn: true);
    // The drop.
    final from = g.poleTap;
    final entry = Offset(m.left - 14, m.top - 14);
    if (bearer) {
      canvas.drawPath(Path()..moveTo(from.dx, from.dy - 8)..quadraticBezierTo((from.dx + entry.dx) / 2, from.dy + 6, hs.left, entry.dy - 12), _stroke(const Color(0xFF9AA1A9), 1.4));
      canvas.drawCircle(Offset(hs.left + 2, entry.dy - 12), 2.4, Paint()..color = const Color(0xFF5A6068));
    }
    if (cableOn) {
      final cable = _stroke(const Color(0xFF15171A), 3.2);
      final sag = bearer ? from.dy + 10 : from.dy + 34;
      final p = Path()
        ..moveTo(from.dx, from.dy)
        ..quadraticBezierTo((from.dx + entry.dx) / 2, sag, entry.dx, entry.dy);
      if (drip) {
        p
          ..quadraticBezierTo(entry.dx + 2, entry.dy + 34, entry.dx + 10, entry.dy + 30)
          ..quadraticBezierTo(entry.dx + 18, entry.dy + 26, m.left, m.top + 10);
      } else {
        p.lineTo(m.left, m.top + 6);
      }
      canvas.drawPath(p, cable);
      if (bearer) {
        final tie = _stroke(const Color(0xFF9AA1A9), 1);
        for (var t = 0.2; t < 0.85; t += 0.16) {
          final x = from.dx + (entry.dx - from.dx) * t;
          canvas.drawLine(Offset(x, from.dy - 3 + 10 * t), Offset(x, from.dy + 6 + 10 * t), tie);
        }
      }
    }
    if (neutralDone) {
      canvas.drawCircle(from, 4, Paint()..color = const Color(0xFF41C463));
    }
  }

  @override
  bool shouldRepaint(M3ServicePainter old) =>
      old.geo.h != geo.h ||
      old.cableOn != cableOn ||
      old.bearer != bearer ||
      old.drip != drip ||
      old.neutralDone != neutralDone ||
      old.threePhase != threePhase;
}

// ============================================================================
// Station 7 — the cradle guard over the road
// ============================================================================

enum M3GuardFault { leftEarth, rightEarth, brokenWire }

@immutable
class M3GuardGeo {
  const M3GuardGeo(this.h);
  final double h;
  double get groundY => h - 230;
  static const poleL = 40.0;
  static const poleR = 320.0;
  double get top => 160;
  double get lineY => top + 18;
  double get cradleY => top + 70;

  Offset spot(M3GuardFault f) => switch (f) {
        M3GuardFault.leftEarth => Offset(poleL + 10, groundY - 70),
        M3GuardFault.rightEarth => Offset(poleR - 10, groundY - 70),
        M3GuardFault.brokenWire => Offset(180, cradleY + 18),
      };

  Rect hit(M3GuardFault f) => Rect.fromCenter(center: spot(f), width: f == M3GuardFault.brokenWire ? 90 : 44, height: f == M3GuardFault.brokenWire ? 54 : 90);
}

class M3GuardPainter extends CustomPainter {
  const M3GuardPainter({required this.geo, required this.fault, required this.fixed});
  final M3GuardGeo geo;
  final M3GuardFault fault;
  final bool fixed;

  @override
  void paint(Canvas canvas, Size size) {
    final g = geo;
    _sky(canvas, size, g.groundY, road: true);
    for (final x in const [M3GuardGeo.poleL, M3GuardGeo.poleR]) {
      _pole(canvas, x, g.top - 10, g.groundY + 10);
      canvas.drawRect(Rect.fromLTWH(x - 26, g.lineY + 2, 52, 6), Paint()..color = const Color(0xFF5A6068));
      canvas.drawRect(Rect.fromLTWH(x - 34, g.cradleY - 3, 68, 6), Paint()..color = const Color(0xFF5A6068));
    }
    // Live conductors.
    final wire = _stroke(const Color(0xFF2F343A), 1.8);
    for (final dx in const [-20.0, 0.0, 20.0]) {
      canvas.drawPath(
        Path()
          ..moveTo(M3GuardGeo.poleL + dx, g.lineY)
          ..quadraticBezierTo(180, g.lineY + 26, M3GuardGeo.poleR + dx, g.lineY),
        wire,
      );
    }
    // The cradle: longitudinal GI wires with cross lacing.
    final gi = _stroke(const Color(0xFF9AA1A9), 1.3);
    final broken = fault == M3GuardFault.brokenWire && !fixed;
    double yAt(double x, double off) => g.cradleY + off + 20 * math.sin(math.pi * (x - M3GuardGeo.poleL) / (M3GuardGeo.poleR - M3GuardGeo.poleL));
    for (final off in const [0.0, 6.0]) {
      final p = Path()..moveTo(M3GuardGeo.poleL, yAt(M3GuardGeo.poleL, off));
      for (var x = M3GuardGeo.poleL; x <= M3GuardGeo.poleR; x += 10) {
        p.lineTo(x, yAt(x, off));
      }
      canvas.drawPath(p, gi);
    }
    for (var x = M3GuardGeo.poleL + 20; x < M3GuardGeo.poleR - 10; x += 20) {
      if (broken && (x - 180).abs() < 12) {
        canvas.drawLine(Offset(x, yAt(x, 0)), Offset(x + 6, yAt(x, 0) + 40), gi);
        continue;
      }
      canvas.drawLine(Offset(x, yAt(x, 0)), Offset(x - 6, yAt(x, 0) + 6), gi);
    }
    if (broken) {
      canvas.drawLine(Offset(186, yAt(186, 0) + 6), Offset(176, yAt(186, 0) + 52), _stroke(const Color(0xFF9AA1A9), 1.6));
    }
    // Earth leads down each pole into a protective pipe.
    for (final f in const [M3GuardFault.leftEarth, M3GuardFault.rightEarth]) {
      final x = f == M3GuardFault.leftEarth ? M3GuardGeo.poleL + 9 : M3GuardGeo.poleR - 9;
      final cut = fault == f && !fixed;
      final lead = _stroke(const Color(0xFF3B6E3B), 2);
      if (cut) {
        canvas.drawLine(Offset(x, g.cradleY), Offset(x, g.groundY - 110), lead);
        canvas.drawLine(Offset(x, g.groundY - 110), Offset(x + 6, g.groundY - 98), lead);
        canvas.drawLine(Offset(x, g.groundY - 46), Offset(x, g.groundY + 8), lead);
      } else {
        canvas.drawLine(Offset(x, g.cradleY), Offset(x, g.groundY + 8), lead);
      }
      if (fixed && fault == f) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(x - 4, g.groundY - 110, 8, 118), const Radius.circular(3)),
          Paint()..color = const Color(0xFF6B7178),
        );
      }
      canvas.drawRect(Rect.fromLTWH(x - 4, g.groundY - 30, 8, 38), Paint()..color = const Color(0xFF6B7178));
    }
    // A bus waiting on the road.
    final bus = Rect.fromLTWH(118, g.groundY + 6, 120, 44);
    canvas.drawRRect(RRect.fromRectAndRadius(bus, const Radius.circular(6)), Paint()..color = const Color(0xFFE0A030));
    for (var i = 0; i < 4; i++) {
      canvas.drawRect(Rect.fromLTWH(bus.left + 10 + i * 26.0, bus.top + 8, 18, 14), Paint()..color = const Color(0xFF6FA0C8));
    }
    canvas.drawCircle(Offset(bus.left + 24, bus.bottom), 8, Paint()..color = const Color(0xFF1B1E22));
    canvas.drawCircle(Offset(bus.right - 24, bus.bottom), 8, Paint()..color = const Color(0xFF1B1E22));
  }

  @override
  bool shouldRepaint(M3GuardPainter old) => old.geo.h != geo.h || old.fault != fault || old.fixed != fixed;
}

/// A spark (an arc on a deadly move, a small flash otherwise).
class M3SparkPainter extends CustomPainter {
  const M3SparkPainter({required this.at, this.big = false});
  final Offset at;
  final bool big;

  @override
  void paint(Canvas canvas, Size size) {
    final r = big ? 46.0 : 16.0;
    canvas.drawCircle(
      at,
      r,
      Paint()
        ..shader = RadialGradient(
          colors: big
              ? const [Color(0xFFFFFFFF), Color(0xFFFFE070), Color(0x00FF7A00)]
              : const [Color(0xFFFFFFFF), Color(0xFF9FD8FF), Color(0x002A7FFF)],
        ).createShader(Rect.fromCircle(center: at, radius: r)),
    );
    final ray = Paint()
      ..color = big ? const Color(0xFFFFF3B0) : const Color(0xFFDDF2FF)
      ..strokeWidth = big ? 2.4 : 1.4;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + 0.3;
      canvas.drawLine(at + Offset(math.cos(a), math.sin(a)) * r * 0.4, at + Offset(math.cos(a), math.sin(a)) * r * 1.15, ray);
    }
  }

  @override
  bool shouldRepaint(M3SparkPainter old) => old.at != at || old.big != big;
}
