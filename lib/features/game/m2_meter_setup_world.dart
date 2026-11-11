import 'dart:math' as math;

import 'package:flutter/material.dart';

// The place for lesson 2.2, কাজ 1 "ডায়াল আর সকেট": a roadside service wall
// in late-morning light — houses far off, a plastered wall with the LT
// distribution board (its door open: the isolator, the fuse carrier, the
// incoming phase and neutral terminals), a solar street-light battery on a
// steel bracket, the docket clipped by the board, and a wooden bench below
// with the open meter case. No text in the art (the switch's ON/OFF and the
// battery's "12V" are widgets a worker reads). Design: 360 wide × any height;
// everything stands on the ground row, so a tall phone gets more sky.

/// Where things are, in design pixels (360 × [h]).
@immutable
class MeterSceneGeo {
  const MeterSceneGeo(this.h);
  final double h;

  double get ground => h - 112;

  /// The top of the board, the docket and the battery: high on the wall,
  /// right under the header, so neither the meter panel nor the guide's
  /// bubble above it covers them.
  double get top => math.max(100.0, ground - 580);

  /// The top of the wall (above it: sky).
  double get wallTop => top - 48;

  /// The LT board's steel box (door open).
  Rect get board => Rect.fromLTWH(18, top, 232, 196);

  /// The isolator switch (a widget: tap to throw it).
  Rect get isolator => Rect.fromLTWH(board.left + 16, board.top + 40, 52, 112);

  /// The fuse carrier on its base.
  Rect get fuse => Rect.fromLTWH(board.left + 86, board.top + 54, 62, 84);

  /// The incoming terminals: phase (red sleeve) and neutral (black).
  Rect get terminals => Rect.fromLTWH(board.left + 160, board.top + 34, 58, 124);

  /// The docket, clipped on the wall right of the board.
  Rect get docket => Rect.fromLTWH(264, top - 2, 82, 104);

  /// The street-light battery on its bracket.
  Rect get battery => Rect.fromLTWH(266, top + 120, 80, 66);

  /// The bench and the open meter case on it.
  Rect get bench => Rect.fromLTWH(96, ground - 150, 256, 150);
  Rect get caseBox => Rect.fromLTWH(118, ground - 262, 220, 116);

  /// Slot [i] of [n] in the case: a meter lies in it.
  Rect slot(int i, int n) {
    final w = (caseBox.width - 16) / n;
    return Rect.fromLTWH(caseBox.left + 8 + w * i + 4, caseBox.top + 12, w - 8, caseBox.height - 22);
  }

  /// Where the [i]th meter set aside lies, on the bench's left end.
  Rect aside(int i) => Rect.fromLTWH(102 + i * 30.0, ground - 142, 44, 60);

  /// The trainee, by the bench.
  Rect get trainee => Rect.fromLTWH(-4, ground - 150, 80, 160);
}

class MeterScenePainter extends CustomPainter {
  const MeterScenePainter(this.geo);
  final MeterSceneGeo geo;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final g = geo.ground;

    // Sky.
    final sky = Rect.fromLTWH(0, 0, w, geo.wallTop + 40);
    c.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4E8FCB), Color(0xFF9CC6E6), Color(0xFFE3ECEE)],
          stops: [0, 0.6, 1],
        ).createShader(sky),
    );
    final sun = Offset(w * 0.18, math.max(60, geo.wallTop - 50));
    c.drawCircle(sun, 100, Paint()..shader = const RadialGradient(colors: [Color(0x80FFF6D8), Color(0x00FFF6D8)]).createShader(Rect.fromCircle(center: sun, radius: 100)));
    c.drawCircle(sun, 16, Paint()..color = const Color(0xFFFFF4CF));
    void cloud(double x, double y, double k) {
      final p = Paint()..color = const Color(0xE6FFFFFF);
      c.drawOval(Rect.fromCenter(center: Offset(x, y), width: 88 * k, height: 24 * k), p);
      c.drawCircle(Offset(x - 16 * k, y - 8 * k), 15 * k, p);
      c.drawCircle(Offset(x + 10 * k, y - 12 * k), 19 * k, p);
    }

    if (geo.wallTop > 90) cloud(250, geo.wallTop * 0.5, 0.9);
    if (geo.wallTop > 200) cloud(110, geo.wallTop * 0.3, 0.7);

    // Far: rooftops and a line of poles over the wall, hazy.
    final far = Paint()..color = const Color(0xFFA9BCCB);
    final roofs = Path()..moveTo(0, geo.wallTop + 2);
    for (final (x, y) in const [(0.0, -28.0), (40.0, -28.0), (40.0, -46.0), (96.0, -46.0), (96.0, -20.0), (170.0, -20.0), (170.0, -38.0), (230.0, -38.0), (230.0, -24.0), (360.0, -24.0)]) {
      roofs.lineTo(x, geo.wallTop + y);
    }
    roofs
      ..lineTo(w, geo.wallTop + 2)
      ..close();
    c.drawPath(roofs, far);
    final pole = Paint()..color = const Color(0xFF93A8B8);
    for (final x in const [70.0, 300.0]) {
      c.drawRect(Rect.fromLTWH(x, geo.wallTop - 110, 4, 110), pole);
      c.drawRect(Rect.fromLTWH(x - 14, geo.wallTop - 104, 32, 3), pole);
    }
    c.drawLine(Offset(0, geo.wallTop - 100), Offset(w, geo.wallTop - 98), Paint()
      ..color = const Color(0xFF8297A8)
      ..strokeWidth = 1);

    // The wall: warm plaster with a darker plinth and a few cracks.
    final wall = Rect.fromLTRB(0, geo.wallTop, w, g);
    c.drawRect(
      wall,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE8D9B9), Color(0xFFD9C59E)],
        ).createShader(wall),
    );
    c.drawRect(Rect.fromLTRB(0, geo.wallTop, w, geo.wallTop + 8), Paint()..color = const Color(0xFFBFA77C));
    c.drawRect(Rect.fromLTRB(0, g - 46, w, g), Paint()..color = const Color(0xFFB59C74));
    final crack = Paint()
      ..color = const Color(0x55806A48)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    c.drawPath(Path()
      ..moveTo(300, geo.wallTop + 30)
      ..lineTo(306, geo.wallTop + 52)
      ..lineTo(302, geo.wallTop + 70), crack);
    c.drawPath(Path()
      ..moveTo(40, g - 70)
      ..lineTo(52, g - 88)
      ..lineTo(48, g - 104), crack);

    // Ground: the lane.
    final lane = Rect.fromLTRB(0, g, w, s.height);
    c.drawRect(
      lane,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF9A9284), Color(0xFF6F685D)],
        ).createShader(lane),
    );

    _board(c);
    _battery(c);
    _bench(c);
  }

  void _board(Canvas c) {
    final b = geo.board;
    // The cable up the wall into the board.
    final cable = Paint()
      ..color = const Color(0xFF2B2F35)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;
    c.drawLine(Offset(b.left + 190, geo.wallTop), Offset(b.left + 190, b.top), cable);
    c.drawLine(Offset(b.left + 60, b.bottom), Offset(b.left + 60, geo.ground - 46), cable);
    // Shadow and box.
    c.drawRRect(RRect.fromRectAndRadius(b.shift(const Offset(4, 5)), const Radius.circular(6)), Paint()..color = const Color(0x33000000));
    c.drawRRect(
      RRect.fromRectAndRadius(b, const Radius.circular(6)),
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFF9FA8AF), Color(0xFF7D868D)], begin: Alignment.topLeft, end: Alignment.bottomRight).createShader(b),
    );
    final inner = b.deflate(8);
    c.drawRRect(RRect.fromRectAndRadius(inner, const Radius.circular(3)), Paint()..color = const Color(0xFF3A4148));
    // The back plate the gear sits on.
    c.drawRect(inner.deflate(4), Paint()..color = const Color(0xFF4C555D));
    // DIN rail behind the isolator and fuse.
    c.drawRect(Rect.fromLTWH(inner.left + 4, b.top + 92, 150, 8), Paint()..color = const Color(0xFFB4BCC3));
    // The fuse carrier's base (porcelain) and the carrier.
    final f = geo.fuse;
    c.drawRRect(RRect.fromRectAndRadius(f, const Radius.circular(6)), Paint()..color = const Color(0xFFEDE7DA));
    c.drawRRect(
      RRect.fromRectAndRadius(f.deflate(10), const Radius.circular(8)),
      Paint()..color = const Color(0xFFD6CEBE),
    );
    final metal = Paint()..color = const Color(0xFFC9A24A);
    c.drawRect(Rect.fromCenter(center: Offset(f.center.dx, f.top + 8), width: 22, height: 8), metal);
    c.drawRect(Rect.fromCenter(center: Offset(f.center.dx, f.bottom - 8), width: 22, height: 8), metal);
    c.drawLine(Offset(f.center.dx, f.top + 14), Offset(f.center.dx, f.bottom - 14), Paint()
      ..color = const Color(0xFF8C877C)
      ..strokeWidth = 2);
    // The incoming terminals: phase with a red sleeve, neutral black.
    final t = geo.terminals;
    c.drawRRect(RRect.fromRectAndRadius(t, const Radius.circular(4)), Paint()..color = const Color(0xFF2B2F35));
    for (final (i, col) in const [(0, Color(0xFFC0392B)), (1, Color(0xFF15171A))]) {
      final cy = t.top + 34 + i * 54.0;
      c.drawRect(Rect.fromLTWH(t.left + 8, cy - 10, t.width - 16, 20), Paint()..color = const Color(0xFF59626A));
      c.drawCircle(Offset(t.center.dx, cy), 7, Paint()..color = const Color(0xFFD9B455));
      c.drawCircle(Offset(t.center.dx, cy), 3, Paint()..color = const Color(0xFF8C6A2A));
      // The cable into the stud, from above.
      c.drawLine(Offset(t.center.dx + (i == 0 ? -12 : 12), t.top - 2), Offset(t.center.dx + (i == 0 ? -12 : 12), cy - 10), Paint()
        ..color = col
        ..strokeWidth = 7);
    }
    // The open door, hinged left, seen edge-on.
    final door = Path()
      ..moveTo(b.left, b.top + 4)
      ..lineTo(b.left - 14, b.top + 18)
      ..lineTo(b.left - 14, b.bottom - 18)
      ..lineTo(b.left, b.bottom - 4)
      ..close();
    c.drawPath(door, Paint()..color = const Color(0xFF6E777E));
    // A red warning flash plate (a symbol only).
    final plate = Rect.fromLTWH(b.right - 34, b.bottom - 30, 22, 20);
    c.drawRect(plate, Paint()..color = const Color(0xFFF2C230));
    c.drawPath(
      Path()
        ..moveTo(plate.center.dx + 2, plate.top + 3)
        ..lineTo(plate.center.dx - 4, plate.center.dy + 1)
        ..lineTo(plate.center.dx + 1, plate.center.dy + 1)
        ..lineTo(plate.center.dx - 2, plate.bottom - 3)
        ..lineTo(plate.center.dx + 5, plate.center.dy - 2)
        ..lineTo(plate.center.dx, plate.center.dy - 2)
        ..close(),
      Paint()..color = const Color(0xFF1E2228),
    );
  }

  void _battery(Canvas c) {
    final r = geo.battery;
    // The steel bracket.
    final steel = Paint()..color = const Color(0xFF6F777E);
    c.drawRect(Rect.fromLTWH(r.left - 4, r.bottom, r.width + 8, 6), steel);
    c.drawPath(
      Path()
        ..moveTo(r.left, r.bottom + 6)
        ..lineTo(r.left + 6, r.bottom + 6)
        ..lineTo(r.left + 6, r.bottom + 40)
        ..close(),
      steel,
    );
    c.drawPath(
      Path()
        ..moveTo(r.right, r.bottom + 6)
        ..lineTo(r.right - 6, r.bottom + 6)
        ..lineTo(r.right - 6, r.bottom + 40)
        ..close(),
      steel,
    );
    // The small solar panel above, and its lead down to the battery.
    final panel = Rect.fromLTWH(r.left + 4, r.top - 60, r.width - 8, 30);
    c.drawLine(Offset(panel.center.dx, panel.bottom), Offset(panel.center.dx, r.top), Paint()
      ..color = const Color(0xFF2B2F35)
      ..strokeWidth = 2);
    final skew = Path()
      ..moveTo(panel.left + 6, panel.top)
      ..lineTo(panel.right, panel.top)
      ..lineTo(panel.right - 6, panel.bottom)
      ..lineTo(panel.left, panel.bottom)
      ..close();
    c.drawPath(skew, Paint()..color = const Color(0xFF1F3A63));
    final cell = Paint()
      ..color = const Color(0xFF6A8FBF)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    for (var i = 1; i < 4; i++) {
      final x = panel.left + panel.width * i / 4;
      c.drawLine(Offset(x + 3, panel.top), Offset(x - 3, panel.bottom), cell);
    }
    c.drawLine(Offset(panel.left + 3, panel.center.dy), Offset(panel.right - 3, panel.center.dy), cell);
    // The battery: a dark case, two terminals (red +, black −) on top.
    c.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(5)),
      Paint()..shader = const LinearGradient(colors: [Color(0xFF3E474F), Color(0xFF262C31)]).createShader(r),
    );
    c.drawRect(Rect.fromLTWH(r.left, r.top + 14, r.width, 4), Paint()..color = const Color(0xFF59626A));
    for (final (x, col) in [(r.left + 16, const Color(0xFFC0392B)), (r.right - 16, const Color(0xFF15171A))]) {
      c.drawRect(Rect.fromCenter(center: Offset(x, r.top - 3), width: 12, height: 8), Paint()..color = const Color(0xFFB9BEC2));
      c.drawRect(Rect.fromCenter(center: Offset(x, r.top + 4), width: 16, height: 6), Paint()..color = col);
    }
  }

  void _bench(Canvas c) {
    final b = geo.bench;
    final wood = Paint()..shader = const LinearGradient(colors: [Color(0xFF9C6B3C), Color(0xFF7A4F2A)], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(b);
    // Legs.
    for (final x in [b.left + 12, b.right - 26]) {
      c.drawRect(Rect.fromLTWH(x, b.top + 10, 14, b.height - 10), Paint()..color = const Color(0xFF5E3C1F));
    }
    // Top.
    c.drawRect(Rect.fromLTWH(b.left, b.top - 4, b.width, 16), wood);
    c.drawRect(Rect.fromLTWH(b.left, b.top + 12, b.width, 3), Paint()..color = const Color(0x55000000));
    // The case: an open hard case (lid up behind, foam bed in front).
    final k = geo.caseBox;
    final lid = Rect.fromLTWH(k.left + 6, k.top - 18, k.width - 12, 22);
    c.drawRRect(RRect.fromRectAndRadius(lid, const Radius.circular(6)), Paint()..color = const Color(0xFF232A31));
    c.drawRRect(RRect.fromRectAndRadius(k, const Radius.circular(8)), Paint()..color = const Color(0xFF2E3740));
    c.drawRRect(RRect.fromRectAndRadius(k.deflate(6), const Radius.circular(5)), Paint()..color = const Color(0xFF1B2026));
    // The case stands on the bench.
    c.drawRect(Rect.fromLTWH(k.left + 10, k.bottom, k.width - 20, b.top - 4 - k.bottom), Paint()..color = const Color(0xFF232A31));
  }

  @override
  bool shouldRepaint(MeterScenePainter old) => old.geo.h != geo.h;
}

/// A soft amber ring on what the current job measures (no text).
class MeterTargetRing extends StatelessWidget {
  const MeterTargetRing({super.key});

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xCCFFB020), width: 2.4),
            boxShadow: const [BoxShadow(color: Color(0x55FFB020), blurRadius: 10, spreadRadius: 1)],
          ),
        ),
      );
}

/// The two probe tips on the job, red and black, once the player has
/// touched them on.
class ProbeTips extends StatelessWidget {
  const ProbeTips({super.key});

  @override
  Widget build(BuildContext context) => IgnorePointer(child: CustomPaint(painter: _ProbeTipsPainter()));
}

class _ProbeTipsPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    void probe(Offset tip, Offset grip, Color col) {
      c.drawLine(tip, Offset.lerp(tip, grip, 0.25)!, Paint()
        ..color = const Color(0xFFD6DADE)
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round);
      c.drawLine(Offset.lerp(tip, grip, 0.25)!, grip, Paint()
        ..color = col
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round);
    }

    probe(Offset(s.width * 0.5, s.height * 0.3), Offset(s.width * 0.1, s.height + 30), const Color(0xFFC0392B));
    probe(Offset(s.width * 0.5, s.height * 0.72), Offset(s.width * 0.9, s.height + 40), const Color(0xFF15171A));
  }

  @override
  bool shouldRepaint(_ProbeTipsPainter old) => false;
}

/// The test leads laid out for the close look: red above, black below, each
/// from the plug (left) to the probe tip (right). A cut in the insulation or
/// a rusty tip shows only where the hand has been ([seenRed] / [seenBlack]:
/// stretches of [kLeadBins]; null = all seen); unseen stretches are washed
/// with [veil].
const kLeadBins = 16;
int leadBin(double u) => (u * kLeadBins).floor().clamp(0, kLeadBins - 1);

class LeadsPainter extends CustomPainter {
  LeadsPainter({required this.cutOn, required this.rustOn, this.seenRed, this.seenBlack, this.veil});

  /// The lead with a cut (null: none) and the lead with a rusty tip.
  final bool? cutOn;
  final bool? rustOn;
  final Set<int>? seenRed;
  final Set<int>? seenBlack;
  final Color? veil;

  static const cutU = 0.46;
  static const tipFrom = 0.88;

  /// The lead's centre line at [u] (0 plug … 1 tip): red at the top.
  static Offset at(Size s, bool red, double u) {
    final y0 = s.height * (red ? 0.3 : 0.72);
    return Offset(s.width * (0.06 + 0.88 * u), y0 + math.sin(u * math.pi * 2) * s.height * 0.07);
  }

  static double uOf(Size s, double x) => ((x / s.width - 0.06) / 0.88).clamp(0.0, 1.0);

  static bool _any(Set<int>? seen, double a, double b) {
    if (seen == null) return true;
    for (var i = leadBin(a); i <= leadBin(b); i++) {
      if (seen.contains(i)) return true;
    }
    return false;
  }

  /// The leads' flaw is in view.
  static bool flawSeen({required bool? cutOn, required bool? rustOn, Set<int>? red, Set<int>? black}) {
    if (cutOn != null && _any(cutOn ? red : black, cutU - 0.04, cutU + 0.04)) return true;
    if (rustOn != null && _any(rustOn ? red : black, tipFrom, 1)) return true;
    return false;
  }

  @override
  void paint(Canvas c, Size s) {
    for (final red in [true, false]) {
      final col = red ? const Color(0xFFC0392B) : const Color(0xFF15171A);
      final seen = red ? seenRed : seenBlack;
      final cut = cutOn == red && _any(seen, cutU - 0.04, cutU + 0.04);
      final rust = rustOn == red && _any(seen, tipFrom, 1);
      final th = math.max(4.0, s.height * 0.06);
      Path line(double a, double b) {
        final p = Path()..moveTo(at(s, red, a).dx, at(s, red, a).dy);
        for (var i = 1; i <= 24; i++) {
          final q = at(s, red, a + (b - a) * i / 24);
          p.lineTo(q.dx, q.dy);
        }
        return p;
      }

      final lead = Paint()
        ..color = col
        ..strokeWidth = th
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      // The plug at the left end.
      final plug = at(s, red, 0);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: plug, width: th * 3.2, height: th * 2.2), Radius.circular(th * 0.5)), Paint()..color = col);
      c.drawLine(plug, plug.translate(-th * 2.2, 0), Paint()
        ..color = const Color(0xFFC9CED3)
        ..strokeWidth = th * 0.6);
      if (cut) {
        c.drawPath(line(0.02, cutU - 0.025), lead);
        c.drawPath(line(cutU + 0.025, 0.84), lead);
        // Bare copper in the gap.
        c.drawPath(
          line(cutU - 0.03, cutU + 0.03),
          Paint()
            ..color = const Color(0xFFE09A4A)
            ..strokeWidth = th * 0.45
            ..style = PaintingStyle.stroke,
        );
      } else {
        c.drawPath(line(0.02, 0.84), lead);
      }
      // The probe body and its finger guard, then the metal tip.
      final body0 = at(s, red, 0.84);
      final body1 = at(s, red, 0.93);
      c.drawLine(body0, body1, Paint()
        ..color = col
        ..strokeWidth = th * 1.9
        ..strokeCap = StrokeCap.round);
      c.drawLine(body0.translate(0, -th * 1.4), body0.translate(0, th * 1.4), Paint()
        ..color = col
        ..strokeWidth = th * 0.8);
      final tipEnd = at(s, red, 1);
      c.drawLine(body1, tipEnd, Paint()
        ..color = rust ? const Color(0xFF9A5A2C) : const Color(0xFFD6DADE)
        ..strokeWidth = th * 0.6
        ..strokeCap = StrokeCap.round);
      if (rust) {
        final spot = Paint()..color = const Color(0xFFC9783A);
        for (final k in const [0.25, 0.55, 0.85]) {
          c.drawCircle(Offset.lerp(body1, tipEnd, k)!, th * 0.45, spot);
        }
      }
      // Unseen stretches washed out.
      final v = veil;
      if (v != null && seen != null) {
        final band = Paint()
          ..color = v.withValues(alpha: 0.62)
          ..strokeWidth = th * 3.2
          ..style = PaintingStyle.stroke;
        for (var i = 0; i < kLeadBins; i++) {
          if (!seen.contains(i)) c.drawPath(line(i / kLeadBins, (i + 1) / kLeadBins), band);
        }
      }
    }
  }

  @override
  bool shouldRepaint(LeadsPainter old) =>
      old.cutOn != cutOn || old.rustOn != rustOn || old.veil != veil || !_same(old.seenRed, seenRed) || !_same(old.seenBlack, seenBlack);

  static bool _same(Set<int>? a, Set<int>? b) {
    if (a == null || b == null) return a == b;
    return a.length == b.length && a.containsAll(b);
  }
}

/// The DC mark (a solid line over a dashed one), drawn — fonts lack ⎓.
class DcMark extends StatelessWidget {
  const DcMark({super.key, this.color = const Color(0xFF1E2228), this.width = 14});
  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(width: width, height: width * 0.5, child: CustomPaint(painter: _DcPainter(color)));
}

class _DcPainter extends CustomPainter {
  const _DcPainter(this.color);
  final Color color;

  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = color
      ..strokeWidth = math.max(1.2, s.height * 0.22);
    c.drawLine(Offset(0, s.height * 0.25), Offset(s.width, s.height * 0.25), p);
    for (var i = 0; i < 3; i++) {
      final x = s.width * i / 3;
      c.drawLine(Offset(x, s.height * 0.8), Offset(x + s.width * 0.22, s.height * 0.8), p);
    }
  }

  @override
  bool shouldRepaint(_DcPainter old) => old.color != color;
}

/// The deadly moment, staged in colour over the frozen scene: the meter at
/// the live terminals — with the red lead in the 10A socket, a dead short
/// through the meter flashes at the probes ([tenA]); or a CAT II meter on a
/// line-side job bursts at its case. (Illustrates the lesson: wrong port →
/// "ফিউজ উড়ে গিয়ে ক্ষতিগ্রস্ত"; CAT II on a line → "যন্ত্রটি বিস্ফোরিত হতে পারে".)
class MeterFlash extends StatelessWidget {
  const MeterFlash({super.key, required this.tenA, required this.quiet});
  final bool tenA;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = math.min(box.maxWidth - 40, 330.0);
        final h = math.min(w * 1.05, box.maxHeight * 0.66);
        return Align(
          alignment: const Alignment(0, -0.25),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: quiet ? 1 : 0, end: 1),
            duration: const Duration(milliseconds: 1600),
            builder: (_, t, _) {
              final pop = (t * 6).clamp(0.0, 1.0);
              return Opacity(
                opacity: pop,
                child: Container(
                  width: w,
                  height: h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5484D), width: 2.5),
                    boxShadow: const [BoxShadow(color: Color(0xAA000000), blurRadius: 24, offset: Offset(0, 10))],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: CustomPaint(painter: _FlashPainter(t: t, tenA: tenA), size: Size(w, h)),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _FlashPainter extends CustomPainter {
  _FlashPainter({required this.t, required this.tenA});
  final double t;
  final bool tenA;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final h = s.height;
    c.drawRect(Offset.zero & s, Paint()..color = const Color(0xFF3A4148));
    // The terminals at the top.
    final term = Rect.fromLTWH(w * 0.36, h * 0.06, w * 0.28, h * 0.28);
    c.drawRRect(RRect.fromRectAndRadius(term, const Radius.circular(6)), Paint()..color = const Color(0xFF2B2F35));
    final studs = [Offset(term.center.dx, term.top + term.height * 0.3), Offset(term.center.dx, term.top + term.height * 0.74)];
    for (final p in studs) {
      c.drawCircle(p, 8, Paint()..color = const Color(0xFFD9B455));
    }
    // The meter below.
    final m = Rect.fromLTWH(w * 0.3, h * 0.5, w * 0.4, h * 0.46);
    final burst = !tenA ? ((t - 0.45) / 0.55).clamp(0.0, 1.0) : 0.0;
    c.save();
    c.translate(m.center.dx, m.center.dy);
    c.rotate(burst * 0.08);
    c.translate(-m.center.dx, -m.center.dy);
    c.drawRRect(RRect.fromRectAndRadius(m, const Radius.circular(14)), Paint()..color = const Color(0xFFF2B705));
    c.drawRect(Rect.fromLTWH(m.left + m.width * 0.12, m.top + m.height * 0.1, m.width * 0.76, m.height * 0.26), Paint()..color = const Color(0xFFCFE3C8));
    c.drawCircle(Offset(m.center.dx, m.top + m.height * 0.6), m.width * 0.16, Paint()..color = const Color(0xFF2B2F35));
    final socks = [for (var i = 0; i < 3; i++) Offset(m.left + m.width * (0.2 + 0.3 * i), m.bottom - m.height * 0.1)];
    for (final p in socks) {
      c.drawCircle(p, 6, Paint()..color = const Color(0xFF15171A));
    }
    c.restore();
    // The leads up to the studs: black from COM; red from 10A (or VΩmA).
    final redFrom = tenA ? socks[0] : socks[2];
    for (final (from, to, col) in [(socks[1], studs[1], const Color(0xFF15171A)), (redFrom, studs[0], const Color(0xFFC0392B))]) {
      final p = Path()
        ..moveTo(from.dx, from.dy)
        ..quadraticBezierTo(from.dx + (col == const Color(0xFF15171A) ? 70 : -70), (from.dy + to.dy) / 2, to.dx, to.dy + 10);
      c.drawPath(p, Paint()
        ..color = col
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke);
    }
    // The flash: at the studs (10A short) or at the case (CAT II).
    final at = tenA ? studs[0] : m.center;
    final f = ((t - 0.25) / 0.75).clamp(0.0, 1.0);
    if (f > 0) {
      final r = 20 + 80 * f;
      c.drawCircle(
        at,
        r,
        Paint()..shader = RadialGradient(colors: [Color.fromRGBO(255, 250, 220, 0.95 * (1 - f * 0.3)), const Color(0x00FFC24A)]).createShader(Rect.fromCircle(center: at, radius: r)),
      );
      final spark = Paint()
        ..color = Color.fromRGBO(255, 236, 160, 1 - f * 0.4)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 10; i++) {
        final a = i * math.pi / 5 + 0.2;
        final d = Offset(math.cos(a), math.sin(a));
        c.drawLine(at + d * (16 + 14 * f), at + d * (30 + 40 * f), spark);
      }
    }
    if (burst > 0) {
      // Cracks across the case.
      final crack = Paint()
        ..color = const Color(0xFF3B2A12)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;
      c.drawPath(Path()
        ..moveTo(m.left + m.width * 0.2, m.top + m.height * 0.4)
        ..lineTo(m.center.dx, m.center.dy)
        ..lineTo(m.right - m.width * 0.15, m.top + m.height * 0.7), crack);
    }
  }

  @override
  bool shouldRepaint(_FlashPainter old) => old.t != t || old.tenA != tenA;
}
