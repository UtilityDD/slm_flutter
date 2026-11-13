import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/en_digits.dart';

// The drawn world of lesson 5.1 কাজ 2 "ট্রিপ মানে ডেড নয়" (m5_recloser_watch.dart):
// a village road at dusk, an 11 kV feeder on five PCC poles (four spans) along
// its far side, houses and a tea stall behind it, the crew's van on the road
// by pole 1. The feeder has tripped: every window and street lamp is dark.
//
// A reclose (the recloser charging the line again) lights every window and
// street lamp together for about a second; a bang and a flash at the fault
// span; dark again. Decoys look alike only at a glance: lightning (storm
// plays), a motorbike's headlight down the road, one house on its inverter.
// The fault itself (a branch, a bird, a melted jumper, two clashed
// conductors) is drawn only in the instant of a flash, and fully under the
// torch at the end — never otherwise: all four spans look the same.
//
// Code-drawn, gradients, no bitmaps, no text but the pole numbers (labels a
// lineman reads). Design: 360 wide × the scene's height; the road follows the
// bottom of the screen (a tall phone gets more sky, never a stretched scene).

/// The weather this play (the lesson's clue: a storm's instant trip = a tree
/// or a branch; a clear day = a bird or a melted jumper; repeated recloses =
/// conductors clashing in the wind).
enum M5Weather { storm, windy, clear }

/// What is on the line at the fault span.
enum M5Fault { branch, bird, jumper, clash }

/// What happens in the dark: a real reclose or a decoy.
enum M5EventKind { shot, lightning, headlight, inverter }

/// One thing that lights up during the watch.
@immutable
class M5Event {
  const M5Event({required this.atMs, required this.kind, this.spot = 0, this.fromLeft = true});

  /// When it starts, from the start of the watch.
  final int atMs;
  final M5EventKind kind;

  /// The house (inverter) or the sky spot (lightning), 0–5.
  final int spot;

  /// The headlight comes from the left.
  final bool fromLeft;

  /// How long it shows.
  int get ms => switch (kind) {
        M5EventKind.shot => 1400,
        M5EventKind.lightning => 700,
        M5EventKind.headlight => 2200,
        M5EventKind.inverter => 1300,
      };

  @override
  bool operator ==(Object other) =>
      other is M5Event && other.atMs == atMs && other.kind == kind && other.spot == spot && other.fromLeft == fromLeft;

  @override
  int get hashCode => Object.hash(atMs, kind, spot, fromLeft);
}

/// Where things are (design px, 360 wide).
@immutable
class M5RecloserGeo {
  const M5RecloserGeo._(this.height, this.groundY, this.topY);

  factory M5RecloserGeo.forScene(double height, double inset) {
    final g = height - floorUp - inset * 0.5;
    return M5RecloserGeo._(height, g, math.max(176.0, g - 420));
  }

  final double height;

  /// The near edge of the road.
  final double groundY;

  /// The pole tops.
  final double topY;

  /// The road sits this far above the bottom (the notepad, radio and tools
  /// stand under it).
  static const double floorUp = 124;

  /// The five poles (number plates 1–5); span i runs from pole i to pole i+1.
  static const List<double> poleX = [36, 108, 180, 252, 324];
  static const int spans = 4;

  double get roadTop => groundY - 46;
  double get poleBase => roadTop + 2;
  double get armY => topY + 16;

  /// The three conductors at a pole (A, B, C).
  static const List<double> phaseDy = [-12, 0, 12];

  /// A conductor's height at [x] (a gentle sag between poles).
  double wireY(int phase, double x) {
    final base = armY + phaseDy[phase];
    for (var i = 0; i < spans; i++) {
      final a = poleX[i], b = poleX[i + 1];
      if (x >= a && x <= b) {
        final u = (x - a) / (b - a);
        return base + 9 * 4 * u * (1 - u);
      }
    }
    return base;
  }

  Offset spanMid(int i) {
    final x = (poleX[i] + poleX[i + 1]) / 2;
    return Offset(x, wireY(1, x));
  }

  /// Tap a span (the lock-out report; the earth clamp's drop).
  Rect spanHit(int i) => Rect.fromLTRB(poleX[i] + 8, armY - 40, poleX[i + 1] - 8, armY + 58);

  /// The houses behind the road (the tea stall is [stall]).
  List<Rect> get houses => [
        Rect.fromLTRB(4, roadTop - 74, 58, roadTop - 6),
        Rect.fromLTRB(66, roadTop - 92, 128, roadTop - 6),
        Rect.fromLTRB(140, roadTop - 66, 188, roadTop - 6),
        Rect.fromLTRB(262, roadTop - 84, 316, roadTop - 6),
        Rect.fromLTRB(322, roadTop - 70, 360, roadTop - 6),
      ];

  /// The tea stall (tap it: the locals saw the flash).
  Rect get stall => Rect.fromLTRB(198, roadTop - 60, 252, roadTop - 2);

  /// A house's windows.
  List<Rect> windows(Rect h) {
    final w = h.width;
    final y = h.top + h.height * 0.42;
    final n = w > 52 ? 2 : 1;
    return [
      for (var k = 0; k < n; k++)
        Rect.fromLTWH(h.left + w * (n == 1 ? 0.36 : (k == 0 ? 0.16 : 0.6)), y, w * (n == 1 ? 0.28 : 0.24), h.height * 0.24),
    ];
  }

  /// The street lamps (on poles 1, 3, 5).
  List<Offset> get lamps => [for (final i in [0, 2, 4]) Offset(poleX[i] + 12, armY + 92)];

  /// The van on the road, its centre at [x].
  Rect vanRect(double x) => Rect.fromCenter(center: Offset(x, groundY - 22), width: 72, height: 36);
  static const double vanHome = 44;
  double vanX(int? span) => span == null ? vanHome : spanMid(span).dx;

  /// The pole the trainee works at: the van's span's left pole (pole 1 at home).
  int poleOf(int? span) => span ?? 0;

  /// The trainee on the road by the van, and up the pole.
  Rect ground(double vanCentre) => Rect.fromLTWH(math.min(312.0, vanCentre + 30), groundY - 96, 44, 92);
  Rect aloft(int pole) => Rect.fromLTWH(poleX[pole] - 2, armY + 8, 44, 88);

  /// "পোলে উঠুন" on the pole (a plain sign the whole play).
  Rect climbSign(int pole) => Rect.fromCenter(center: Offset(poleX[pole].clamp(40.0, 320.0), armY + 142), width: 78, height: 44);

  /// The earth spike at the pole's foot.
  Offset spike(int pole) => Offset(poleX[pole] + 18, roadTop - 2);

  /// Where the flash (and the arc) shows at a span.
  Offset flashAt(int span) => spanMid(span);

  /// The sky spots for lightning.
  Offset sky(int spot) => Offset(40 + 56.0 * (spot % 6), topY - 60);

  @override
  bool operator ==(Object other) => other is M5RecloserGeo && other.height == height && other.groundY == groundY && other.topY == topY;

  @override
  int get hashCode => Object.hash(height, groundY, topY);
}

/// What the village shows now.
@immutable
class M5RecloserRig {
  const M5RecloserRig({
    required this.weather,
    required this.fault,
    required this.faultSpan,
    this.lit = false,
    this.night = false,
    this.torch = false,
    this.cleared = false,
    this.pole = 0,
    this.spike = false,
    this.clamp = false,
    this.tested = 0,
  });

  final M5Weather weather;
  final M5Fault fault;
  final int faultSpan;

  /// Every window and lamp on (before the trip).
  final bool lit;

  /// Full night (after the patrol starts).
  final bool night;

  /// The torch on the fault span (the fault drawn in full).
  final bool torch;

  /// The fault taken off the line.
  final bool cleared;

  /// The pole the crew works at (earth set, tester dots).
  final int pole;
  final bool spike;
  final bool clamp;

  /// Phases proved dead (0–3).
  final int tested;

  @override
  bool operator ==(Object other) =>
      other is M5RecloserRig &&
      other.weather == weather &&
      other.fault == fault &&
      other.faultSpan == faultSpan &&
      other.lit == lit &&
      other.night == night &&
      other.torch == torch &&
      other.cleared == cleared &&
      other.pole == pole &&
      other.spike == spike &&
      other.clamp == clamp &&
      other.tested == tested;

  @override
  int get hashCode => Object.hash(weather, fault, faultSpan, lit, night, torch, cleared, pole, spike, clamp, tested);
}

const _concrete = Color(0xFF8C8F92);
const _concreteDark = Color(0xFF55595D);
const _wire = Color(0xFF1C2026);
const _porcelain = Color(0xFFD9DEE3);
const _glow = Color(0xFFFFD877);

/// The static village (repaints only when the rig changes).
class M5RecloserPainter extends CustomPainter {
  M5RecloserPainter({required this.geo, required this.rig});
  final M5RecloserGeo geo;
  final M5RecloserRig rig;

  @override
  void paint(Canvas canvas, Size size) {
    final g = geo;
    final w = size.width;
    _sky(canvas, size);
    // Far tree line.
    final trees = Path()..moveTo(0, g.roadTop - 70);
    for (var x = 0.0; x <= w + 20; x += 20) {
      trees.quadraticBezierTo(x + 10, g.roadTop - 96 - 10 * math.sin(x * 0.07), x + 20, g.roadTop - 72);
    }
    trees
      ..lineTo(w, g.roadTop)
      ..lineTo(0, g.roadTop)
      ..close();
    canvas.drawPath(trees, Paint()..color = rig.night ? const Color(0xFF0B1418) : const Color(0xFF1A2A2A));
    // Houses and the tea stall.
    for (final h in g.houses) {
      _house(canvas, h, lit: rig.lit);
    }
    _stall(canvas, g.stall);
    // The road.
    final road = Rect.fromLTRB(0, g.roadTop, w, size.height);
    canvas.drawRect(
      road,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: rig.night ? const [Color(0xFF23262B), Color(0xFF101215)] : const [Color(0xFF3A3A3E), Color(0xFF1C1D20)],
        ).createShader(road),
    );
    canvas.drawRect(Rect.fromLTRB(0, g.roadTop, w, g.roadTop + 3), Paint()..color = const Color(0xFF5B5246));
    final dash = Paint()..color = const Color(0x55E8E2CF);
    for (var x = 6.0; x < w; x += 34) {
      canvas.drawRect(Rect.fromLTWH(x, g.groundY - 24, 16, 2.4), dash);
    }
    canvas.drawRect(Rect.fromLTRB(0, g.groundY, w, size.height), Paint()..color = const Color(0xFF14130F));
    // Poles, arms, lamps, wires.
    for (var i = 0; i < M5RecloserGeo.poleX.length; i++) {
      _pole(canvas, i);
    }
    for (var p = 0; p < 3; p++) {
      final path = Path()..moveTo(-4, g.wireY(p, M5RecloserGeo.poleX[0]) + 6);
      path.lineTo(M5RecloserGeo.poleX[0], g.wireY(p, M5RecloserGeo.poleX[0]));
      for (var i = 0; i < M5RecloserGeo.spans; i++) {
        final a = M5RecloserGeo.poleX[i], b = M5RecloserGeo.poleX[i + 1];
        final mid = (a + b) / 2;
        final sag = g.wireY(p, mid) * 2 - (g.wireY(p, a) + g.wireY(p, b)) / 2;
        if (rig.torch && !rig.cleared && rig.fault == M5Fault.clash && i == rig.faultSpan && p > 0) {
          // Two conductors pulled together where they clashed.
          path.quadraticBezierTo(mid, g.wireY(1, mid) + 14 + (p == 2 ? -4 : 4), b, g.wireY(p, b));
        } else {
          path.quadraticBezierTo(mid, sag, b, g.wireY(p, b));
        }
      }
      path.lineTo(w + 4, g.wireY(p, M5RecloserGeo.poleX[4]) + 6);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = _wire,
      );
    }
    for (final l in g.lamps) {
      _lamp(canvas, l, lit: rig.lit);
    }
    // Weather in front of the far layers.
    if (rig.weather == M5Weather.storm) _rain(canvas, size);
    // The earth set at the crew's pole.
    if (rig.spike) _spike(canvas, g.spike(rig.pole));
    if (rig.clamp) _earthLead(canvas);
    // The torch on the fault (the end).
    if (rig.torch) _torch(canvas);
  }

  void _sky(Canvas canvas, Size size) {
    final g = geo;
    final sky = Rect.fromLTRB(0, 0, size.width, g.roadTop);
    final colors = switch ((rig.night, rig.weather)) {
      (true, _) => const [Color(0xFF02040A), Color(0xFF0A1222), Color(0xFF141C2C)],
      (false, M5Weather.storm) => const [Color(0xFF0E131C), Color(0xFF222A36), Color(0xFF3A3A44)],
      (false, M5Weather.windy) => const [Color(0xFF0D1428), Color(0xFF2B2A48), Color(0xFF6A4A52)],
      (false, M5Weather.clear) => const [Color(0xFF0B1430), Color(0xFF2C2C5A), Color(0xFF8A5A5C)],
    };
    canvas.drawRect(
      sky,
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors, stops: const [0, 0.62, 1]).createShader(sky),
    );
    if (rig.weather == M5Weather.storm) {
      final cloud = Paint()..color = const Color(0xCC1B2129);
      for (var i = 0; i < 6; i++) {
        canvas.drawOval(Rect.fromCenter(center: Offset(30 + i * 62.0, g.topY - 70 + (i.isEven ? 0 : 18)), width: 120, height: 44), cloud);
      }
    } else {
      final star = Paint()..color = const Color(0xCCFFFFFF);
      final r = math.Random(7);
      for (var i = 0; i < 26; i++) {
        canvas.drawCircle(Offset(r.nextDouble() * size.width, 90 + r.nextDouble() * (g.topY - 80)), r.nextDouble() * 0.9 + 0.3, star);
      }
      if (rig.weather == M5Weather.clear) {
        canvas.drawCircle(Offset(292, g.topY - 64), 13, Paint()..color = const Color(0xFFF2EBD0));
        canvas.drawCircle(Offset(298, g.topY - 68), 11, Paint()..color = colors[0]);
      } else {
        final streak = Paint()
          ..color = const Color(0x553E3A58)
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 4; i++) {
          final y = g.topY - 90 + i * 22.0;
          canvas.drawLine(Offset(20 + i * 70.0, y), Offset(120 + i * 70.0, y - 6), streak);
        }
      }
    }
  }

  void _house(Canvas canvas, Rect h, {required bool lit}) {
    final body = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: rig.night ? const [Color(0xFF1C2028), Color(0xFF12151B)] : const [Color(0xFF3A3940), Color(0xFF26262C)],
      ).createShader(h);
    canvas.drawRect(h, body);
    final roof = Path()
      ..moveTo(h.left - 4, h.top + 2)
      ..lineTo(h.center.dx, h.top - 16)
      ..lineTo(h.right + 4, h.top + 2)
      ..close();
    canvas.drawPath(roof, Paint()..color = rig.night ? const Color(0xFF15181E) : const Color(0xFF3F2F2A));
    for (final win in geo.windows(h)) {
      canvas.drawRect(win, Paint()..color = lit ? _glow : const Color(0xFF0A0C10));
    }
  }

  void _stall(Canvas canvas, Rect s) {
    canvas.drawRect(Rect.fromLTRB(s.left + 4, s.top + 14, s.right - 4, s.bottom), Paint()..color = const Color(0xFF2E2620));
    final awning = Path()
      ..moveTo(s.left - 2, s.top + 16)
      ..lineTo(s.left + 6, s.top)
      ..lineTo(s.right - 6, s.top)
      ..lineTo(s.right + 2, s.top + 16)
      ..close();
    canvas.drawPath(awning, Paint()..color = const Color(0xFF5A3A2A));
    for (var k = 0; k < 4; k++) {
      canvas.drawRect(Rect.fromLTWH(s.left + 2 + k * 13.0, s.top + 2, 6, 13), Paint()..color = const Color(0x55E7D6B8));
    }
    // The bench and a kettle on the counter; a hurricane lamp (the stall's own).
    canvas.drawRect(Rect.fromLTRB(s.left + 8, s.bottom - 16, s.right - 8, s.bottom - 12), Paint()..color = const Color(0xFF6A4E36));
    final lamp = Offset(s.right - 14, s.top + 24);
    canvas.drawCircle(lamp, 9, Paint()..color = const Color(0x33FFB451));
    canvas.drawCircle(lamp, 2.6, Paint()..color = const Color(0xFFFFC46A));
  }

  void _pole(Canvas canvas, int i) {
    final g = geo;
    final x = M5RecloserGeo.poleX[i];
    final top = g.topY;
    final rect = Rect.fromLTRB(x - 4, top, x + 4, g.poleBase);
    canvas.drawRect(
      rect,
      Paint()..shader = const LinearGradient(colors: [_concreteDark, _concrete, _concreteDark]).createShader(rect),
    );
    // The cross-arm and three insulators.
    canvas.drawRect(Rect.fromLTRB(x - 18, g.armY + 3, x + 18, g.armY + 7), Paint()..color = const Color(0xFF5A5F66));
    for (var p = 0; p < 3; p++) {
      final y = g.armY + M5RecloserGeo.phaseDy[p];
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, y + 3), width: 7, height: 7), const Radius.circular(2)), Paint()..color = _porcelain);
    }
    // The number plate.
    final plate = Rect.fromCenter(center: Offset(x, g.armY + 56), width: 14, height: 13);
    canvas.drawRRect(RRect.fromRectAndRadius(plate, const Radius.circular(2)), Paint()..color = const Color(0xFFE8E3D2));
    final tp = TextPainter(
      text: TextSpan(text: enDigits('${i + 1}'), style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w900, color: Color(0xFF1A1A1A))),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, plate.center - Offset(tp.width / 2, tp.height / 2));
  }

  void _lamp(Canvas canvas, Offset l, {required bool lit}) {
    canvas.drawLine(l.translate(-12, 0), l, Paint()
      ..color = const Color(0xFF4A4F55)
      ..strokeWidth = 2);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: l.translate(2, 2), width: 10, height: 5), const Radius.circular(2)),
        Paint()..color = lit ? _glow : const Color(0xFF2A2E33));
  }

  void _rain(Canvas canvas, Size size) {
    final p = Paint()
      ..color = const Color(0x334E6A88)
      ..strokeWidth = 1;
    final r = math.Random(3);
    for (var i = 0; i < 70; i++) {
      final x = r.nextDouble() * size.width;
      final y = 90 + r.nextDouble() * (geo.groundY - 90);
      canvas.drawLine(Offset(x, y), Offset(x - 3, y + 11), p);
    }
  }

  void _spike(Canvas canvas, Offset s) {
    canvas.drawLine(s.translate(0, -10), s.translate(0, 4), Paint()
      ..color = const Color(0xFFB9A27A)
      ..strokeWidth = 3);
    canvas.drawCircle(s.translate(0, -10), 3, Paint()..color = const Color(0xFFD8C18E));
  }

  void _earthLead(Canvas canvas) {
    final g = geo;
    final x = M5RecloserGeo.poleX[rig.pole];
    final s = g.spike(rig.pole).translate(0, -10);
    final clampAt = Offset(x + 14, g.wireY(2, x + 14));
    final lead = Path()
      ..moveTo(s.dx, s.dy)
      ..quadraticBezierTo(x + 30, (s.dy + clampAt.dy) / 2, clampAt.dx, clampAt.dy);
    canvas.drawPath(
      lead,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = const Color(0xFF3FA06A),
    );
    for (var p = 0; p < 3; p++) {
      canvas.drawCircle(Offset(x + 14, g.wireY(p, x + 14)), 2.6, Paint()..color = const Color(0xFF6FD39A));
    }
  }

  void _torch(Canvas canvas) {
    final g = geo;
    final at = g.spanMid(rig.faultSpan);
    final from = Offset(M5RecloserGeo.poleX[rig.pole] + 10, g.armY + 48);
    final cone = Path()
      ..moveTo(from.dx, from.dy)
      ..lineTo(at.dx - 28, at.dy - 18)
      ..lineTo(at.dx + 28, at.dy + 12)
      ..close();
    canvas.drawPath(cone, Paint()..color = const Color(0x2EFFF2C2));
    canvas.drawCircle(at, 26, Paint()..color = const Color(0x22FFF2C2));
    if (!rig.cleared) paintM5Fault(canvas, rig.fault, at, lit: true, geo: g, span: rig.faultSpan);
  }

  @override
  bool shouldRepaint(M5RecloserPainter old) => old.geo != geo || old.rig != rig;
}

/// The fault at a span's middle [at]; [lit] = under a flash or the torch.
void paintM5Fault(Canvas canvas, M5Fault fault, Offset at, {required bool lit, required M5RecloserGeo geo, required int span}) {
  final ink = Paint()..color = lit ? const Color(0xFF2E2418) : const Color(0xFF0C0C0C);
  switch (fault) {
    case M5Fault.branch:
      final p = Paint()
        ..color = lit ? const Color(0xFF5A4126) : const Color(0xFF111111)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(at.translate(-20, -16), at.translate(16, 14), p);
      canvas.drawLine(at.translate(-4, -2), at.translate(6, -14), p..strokeWidth = 2);
      final leaf = Paint()..color = lit ? const Color(0xFF3E6B33) : const Color(0xFF101410);
      for (final d in const [Offset(-18, -18), Offset(6, -16), Offset(16, 12), Offset(-6, 4)]) {
        canvas.drawOval(Rect.fromCenter(center: at + d, width: 10, height: 6), leaf);
      }
    case M5Fault.bird:
      final body = Path()
        ..moveTo(at.dx - 10, at.dy - 2)
        ..quadraticBezierTo(at.dx, at.dy - 12, at.dx + 10, at.dy - 2)
        ..quadraticBezierTo(at.dx, at.dy + 4, at.dx - 10, at.dy - 2)
        ..close();
      canvas.drawPath(body, ink);
      canvas.drawLine(at.translate(-4, -6), at.translate(-16, -18), ink..strokeWidth = 2.4);
      canvas.drawLine(at.translate(4, -6), at.translate(16, 6), ink);
    case M5Fault.jumper:
      final x = M5RecloserGeo.poleX[span + 1] - 6;
      final y = geo.wireY(1, x);
      final drip = Paint()..color = lit ? const Color(0xFF8A8F96) : const Color(0xFF111111);
      canvas.drawCircle(Offset(x, y + 4), 3.4, drip);
      canvas.drawLine(Offset(x, y), Offset(x - 2, y + 14), drip..strokeWidth = 1.6);
      canvas.drawCircle(Offset(x - 2, y + 16), 2, Paint()..color = lit ? const Color(0xFF3A2C22) : const Color(0xFF0C0C0C));
    case M5Fault.clash:
      final a = Offset(at.dx - 6, geo.wireY(1, at.dx) + 6);
      canvas.drawCircle(a.translate(6, 0), 4, Paint()..color = lit ? const Color(0xFF3A3029) : const Color(0xFF0C0C0C));
  }
}

/// One watch event drawn while it plays ([t] 0 → 1 over [M5Event.ms]).
class M5EventPainter extends CustomPainter {
  M5EventPainter({required this.geo, required this.rig, required this.event, required this.t}) : super(repaint: t);
  final M5RecloserGeo geo;
  final M5RecloserRig rig;
  final M5Event? event;
  final Animation<double> t;

  @override
  void paint(Canvas canvas, Size size) {
    final e = event;
    final v = t.value;
    if (e == null || v <= 0 || v >= 1) return;
    final g = geo;
    switch (e.kind) {
      case M5EventKind.shot:
        // The line on: every window and lamp together, then the flash at the
        // fault span and dark again.
        final on = v < 0.06 ? v / 0.06 : (v < 0.78 ? 1.0 : 0.0);
        if (on > 0) {
          final glow = Paint()..color = _glow.withValues(alpha: on);
          for (final h in g.houses) {
            for (final w in g.windows(h)) {
              canvas.drawRect(w, glow);
            }
          }
          for (final l in g.lamps) {
            canvas.drawCircle(l.translate(2, 6), 22, Paint()..color = _glow.withValues(alpha: 0.18 * on));
            canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: l.translate(2, 2), width: 10, height: 5), const Radius.circular(2)), glow);
          }
        }
        if (v > 0.58 && v < 0.8) {
          final f = 1 - ((v - 0.69).abs() / 0.11).clamp(0.0, 1.0);
          final at = g.flashAt(rig.faultSpan);
          canvas.drawCircle(at, 40 * f + 6, Paint()..color = Color.fromRGBO(190, 220, 255, 0.35 * f));
          canvas.drawCircle(at, 12 * f + 2, Paint()..color = Color.fromRGBO(255, 255, 255, 0.95 * f));
          _rays(canvas, at, 26 * f + 4, f);
          paintM5Fault(canvas, rig.fault, at, lit: false, geo: g, span: rig.faultSpan);
        }
      case M5EventKind.lightning:
        final f = (v < 0.15 ? 1.0 : (v < 0.3 ? 0.3 : (v < 0.45 ? 0.9 : 0.0)));
        if (f <= 0) return;
        canvas.drawRect(Rect.fromLTRB(0, 0, size.width, g.roadTop), Paint()..color = Color.fromRGBO(220, 230, 255, 0.28 * f));
        final s = g.sky(e.spot);
        final bolt = Path()..moveTo(s.dx, 90);
        var x = s.dx;
        for (var y = 110.0; y < g.topY - 20; y += 20) {
          x += (y ~/ 20).isEven ? 9 : -7;
          bolt.lineTo(x, y);
        }
        canvas.drawPath(
          bolt,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2
            ..color = Color.fromRGBO(240, 245, 255, f),
        );
      case M5EventKind.headlight:
        final u = Curves.easeInOut.transform(v);
        final x = e.fromLeft ? -30 + u * (size.width + 60) : size.width + 30 - u * (size.width + 60);
        final y = g.groundY - 30;
        final dir = e.fromLeft ? 1.0 : -1.0;
        final beam = Path()
          ..moveTo(x, y)
          ..lineTo(x + dir * 110, y - 18)
          ..lineTo(x + dir * 110, y + 16)
          ..close();
        canvas.drawPath(beam, Paint()..color = const Color(0x55FFF6D0));
        canvas.drawCircle(Offset(x, y), 4, Paint()..color = const Color(0xFFFFF6D0));
        canvas.drawRect(Rect.fromCenter(center: Offset(x - dir * 10, y + 4), width: 18, height: 6), Paint()..color = const Color(0xFF15171B));
      case M5EventKind.inverter:
        final h = g.houses[e.spot % g.houses.length];
        final on = v < 0.1 ? v / 0.1 : (v < 0.85 ? 1.0 : (1 - v) / 0.15);
        for (final w in g.windows(h)) {
          canvas.drawRect(w, Paint()..color = const Color(0xFFE6F0FF).withValues(alpha: on.clamp(0.0, 1.0)));
        }
    }
  }

  void _rays(Canvas canvas, Offset at, double r, double f) {
    final p = Paint()
      ..color = Color.fromRGBO(220, 235, 255, f)
      ..strokeWidth = 1.6;
    for (var k = 0; k < 8; k++) {
      final a = k * math.pi / 4 + 0.3;
      canvas.drawLine(at + Offset(math.cos(a), math.sin(a)) * (r * 0.4), at + Offset(math.cos(a), math.sin(a)) * r, p);
    }
  }

  @override
  bool shouldRepaint(M5EventPainter old) => old.event != event || old.geo != geo || old.rig != rig;
}

/// The van (code-drawn).
class M5VanPainter extends CustomPainter {
  const M5VanPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final body = RRect.fromRectAndRadius(Rect.fromLTWH(0, h * 0.2, w, h * 0.62), const Radius.circular(5));
    canvas.drawRRect(
      body,
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE9E4D6), Color(0xFFB9B3A3)]).createShader(body.outerRect),
    );
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.62, h * 0.04, w * 0.36, h * 0.4), const Radius.circular(4)), Paint()..color = const Color(0xFFD9D3C2));
    canvas.drawRect(Rect.fromLTWH(w * 0.68, h * 0.1, w * 0.24, h * 0.22), Paint()..color = const Color(0xFF2A3A4C));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.5, w, h * 0.08), Paint()..color = const Color(0xFFE0A526));
    // A ladder on the roof.
    final lad = Paint()
      ..color = const Color(0xFF8E959C)
      ..strokeWidth = 1.4;
    canvas.drawLine(Offset(w * 0.04, h * 0.17), Offset(w * 0.58, h * 0.17), lad);
    for (var k = 0; k < 6; k++) {
      canvas.drawLine(Offset(w * (0.06 + k * 0.1), h * 0.13), Offset(w * (0.06 + k * 0.1), h * 0.2), lad);
    }
    final tyre = Paint()..color = const Color(0xFF111214);
    canvas.drawCircle(Offset(w * 0.22, h * 0.84), h * 0.15, tyre);
    canvas.drawCircle(Offset(w * 0.78, h * 0.84), h * 0.15, tyre);
  }

  @override
  bool shouldRepaint(M5VanPainter old) => false;
}

/// The deadly consequence: the line comes on with the trainee on it — the
/// arc in colour over the frozen grey scene ([v] 0 → 1).
class M5ArcPainter extends CustomPainter {
  M5ArcPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas canvas, Size size) {
    if (v <= 0) return;
    final f = math.sin(math.min(1.0, v) * math.pi).clamp(0.0, 1.0);
    canvas.drawCircle(at, 70 * f + 10, Paint()..color = Color.fromRGBO(120, 170, 255, 0.28 * f));
    canvas.drawCircle(at, 22 * f + 4, Paint()..color = Color.fromRGBO(255, 255, 255, 0.9 * f));
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = Color.fromRGBO(200, 225, 255, f);
    final r = math.Random(11);
    for (var k = 0; k < 7; k++) {
      final a = k * 2 * math.pi / 7;
      final path = Path()..moveTo(at.dx, at.dy);
      var q = at;
      for (var s = 0; s < 4; s++) {
        q = q + Offset(math.cos(a), math.sin(a)) * (12 * f + 4) + Offset(r.nextDouble() * 8 - 4, r.nextDouble() * 8 - 4);
        path.lineTo(q.dx, q.dy);
      }
      canvas.drawPath(path, p);
    }
  }

  @override
  bool shouldRepaint(M5ArcPainter old) => old.v != v || old.at != at;
}
