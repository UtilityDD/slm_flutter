import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The drawn world of lesson 6.4 কাজ 1 "এক টানে তিন ফেজ" (m6_ab_gap_log.dart):
// a roadside 11 kV DP structure in the morning, seen from the front. On its top
// channel sits a gang-operated AB switch (three phases; horizontal break in one
// job, vertical break in the other), the morning sun right behind it. An
// operating pipe runs down the left pole to a ground handle on a quadrant
// plate (ON stop at the top, OFF stop at the bottom); a green-yellow earth lead
// runs from the handle's gearbox down the pole to an earth pipe, its last
// stretch and clamp in the grass (a cut or a loose clamp shows only in the
// close-up). The trainee stands by the handle; the crew van stands on the
// right (the docket hangs on its door — a widget, not painted here).
//
// Two close-ups (widgets over the scene, painted here): the tilt-up gap view
// (one phase at a time, a real blade position: open, stuck in its jaw, or only
// just out of it) and the earth-lead view (lead, clamp, the spare lead, the
// clamp nut). No text in the art except labels a worker reads (ON/OFF, 11 kV).
// Code-drawn, gradients, no bitmaps.
//
// Design: 360 wide × the scene's height; the ground follows the bottom of the
// screen (a tall phone gets a taller structure and more sky, never stretched).

/// How the switch's blades open (lesson 6.4 point 3).
enum M6AbBreak { horizontal, vertical }

/// The handle's earth lead as dealt.
enum M6AbEarth { ok, cut, loose }

/// A phase after the stroke: fully open, stuck in its jaw, or only just
/// clear of it (not fully open — the lesson's "আটকে যেতে পারে").
enum M6AbBlade { open, stuck, part }

/// Where the job is.
enum M6AbPlace { road, field, market }

/// How far a blade opens (0 = in its jaw, 1 = fully open).
double m6BladeOpen(M6AbBlade b) => switch (b) {
      M6AbBlade.open => 1.0,
      M6AbBlade.stuck => 0.0,
      M6AbBlade.part => 0.18,
    };

/// Where things are (design px, 360 wide).
@immutable
class M6AbGeo {
  const M6AbGeo._(this.height, this.groundY, this.topY);

  factory M6AbGeo.forScene(double height, double inset) {
    final g = height - floorUp - inset * 0.5;
    return M6AbGeo._(height, g, math.max(150.0, g - 420));
  }

  final double height;

  /// The ground line at the poles' feet.
  final double groundY;

  /// The top channel's level (the switch sits on it).
  final double topY;

  /// The ground sits this far above the bottom (the phone row stands on it).
  static const double floorUp = 112;

  /// The two poles' axes.
  static const double lp = 30;
  static const double rp = 158;

  /// The three phases R, Y, B (left to right).
  static const List<double> phaseX = [52, 94, 136];

  /// The switch's middle (the deadly arc flashes here).
  Offset get abCentre => Offset(phaseX[1], topY - 6);

  /// The handle's pivot on the left pole, the lever's length and its arc
  /// (radians, screen angles: ON up, OFF down-right).
  Offset get pivot => Offset(lp + 10, groundY - 70);
  static const double armLen = 44;
  static const double a0 = -80 * math.pi / 180;
  static const double a1 = 35 * math.pi / 180;
  double angleAt(double t) => a0 + (a1 - a0) * t.clamp(0.0, 1.0);
  Offset grip(double t) {
    final a = angleAt(t);
    return pivot + Offset(math.cos(a), math.sin(a)) * armLen;
  }

  /// The stroke's progress (0 ON … 1 OFF) for a finger at [p]; null when the
  /// finger is behind the pole (left of the pivot: no angle to read).
  double? progressAt(Offset p) {
    final d = p - pivot;
    if (d.dx < -4) return null;
    final a = math.atan2(d.dy, d.dx);
    return ((a - a0) / (a1 - a0)).clamp(0.0, 1.0);
  }

  /// Hold the handle here.
  Rect get handleHit => Rect.fromLTRB(pivot.dx - 14, pivot.dy - armLen - 14, pivot.dx + armLen + 14, pivot.dy + 34);

  /// The earth lead: gearbox → down the pole → the earth pipe (in the grass).
  Offset get leadTop => Offset(pivot.dx, pivot.dy + 12);
  Offset get leadBend => Offset(pivot.dx, groundY - 24);
  Offset get earthPipe => Offset(pivot.dx + 40, groundY - 6);

  /// A swipe down from here follows the lead (the earth look).
  Offset get leadSwipeFrom => Offset(pivot.dx + 2, pivot.dy + 18);
  Rect get earthZone => Rect.fromLTRB(0, pivot.dy - 10, 130, groundY + 6);

  /// A swipe up from here tilts the view up to the switch.
  Offset get swipeFrom => Offset(phaseX[1], y(0.55));
  Rect get structureZone => Rect.fromLTRB(0, topY - 30, 200, groundY);

  /// A height on the structure (0 = the top channel, 1 = the ground).
  double y(double f) => topY + f * (groundY - topY);

  /// Where the lineman stands (right of the handle).
  Rect get ground => Rect.fromLTWH(104, groundY - 104, 44, 104);

  /// The van on the right.
  Rect get van => Rect.fromLTRB(192, groundY - 150, 362, groundY - 4);

  /// The docket on the van door (a widget).
  static const Rect docket = Rect.fromLTWH(206, 128, 148, 136);

  /// The close-up views (gap view / earth view; a widget).
  static const Rect view = Rect.fromLTWH(8, 128, 190, 172);

  @override
  bool operator ==(Object other) => other is M6AbGeo && other.height == height && other.groundY == groundY && other.topY == topY;

  @override
  int get hashCode => Object.hash(height, groundY, topY);
}

/// What the structure shows now.
@immutable
class M6AbRig {
  const M6AbRig({required this.place, required this.kind, this.blades = const [0, 0, 0], this.handleEarthed = true});

  final M6AbPlace place;
  final M6AbBreak kind;

  /// How far each blade is open (0 … 1).
  final List<double> blades;

  /// The lead looks whole at this scale either way (its fault is in the
  /// grass); kept for the close-up.
  final bool handleEarthed;

  @override
  bool operator ==(Object other) =>
      other is M6AbRig && other.place == place && other.kind == kind && listEquals(other.blades, blades) && other.handleEarthed == handleEarthed;

  @override
  int get hashCode => Object.hash(place, kind, Object.hashAll(blades), handleEarthed);
}

const _concrete = Color(0xFF9DA3A6);
const _steel = Color(0xFF5F676E);
const _porcelain = Color(0xFFDDE3E8);
const _wire = Color(0xFF3A4046);
const _lead = Color(0xFF3E9A3A);
const _leadStripe = Color(0xFFE7D23A);

/// Draws one insulator post (a stack of discs) from [base] up to [top].
void _post(Canvas c, Offset base, double top, double r) {
  final n = math.max(3, ((base.dy - top) / (r * 1.1)).floor());
  final step = (base.dy - top) / n;
  c.drawRect(Rect.fromLTRB(base.dx - r * 0.28, top, base.dx + r * 0.28, base.dy), Paint()..color = const Color(0xFFB9C1C7));
  for (var i = 0; i < n; i++) {
    final cy = base.dy - step * (i + 0.5);
    c.drawOval(
      Rect.fromCenter(center: Offset(base.dx, cy), width: r * 2, height: step * 0.62),
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFFF4F7F9), _porcelain, Color(0xFF9BA6AE)])
            .createShader(Rect.fromCenter(center: Offset(base.dx, cy), width: r * 2, height: step)),
    );
  }
}

/// The scene's blade tips (R, Y, B) on [g] for [rig] with the handle at
/// [handle] (0 ON … 1 OFF): each blade follows the gang shaft up to how far
/// it can open, so before the stroke every tip sits in its jaw.
List<Offset> m6SceneBladeTips(M6AbGeo g, M6AbRig rig, double handle) {
  final postTop = g.topY - 22;
  return [
    for (var i = 0; i < 3; i++) m6BladeTip(rig.kind, Offset(M6AbGeo.phaseX[i] - 12, postTop), 24, math.min(handle, rig.blades[i])),
  ];
}

/// The jaw each scene blade closes into (R, Y, B).
List<Offset> m6SceneJaws(M6AbGeo g) => [for (var i = 0; i < 3; i++) Offset(M6AbGeo.phaseX[i] + 12, g.topY - 22)];

/// A blade from [hinge] (length [len]) at openness [open] for [kind]: the
/// tip, in the picture's plane. Horizontal break swings toward the viewer
/// (foreshortened); vertical break lifts up.
Offset m6BladeTip(M6AbBreak kind, Offset hinge, double len, double open) {
  if (kind == M6AbBreak.horizontal) {
    final th = open * math.pi / 2;
    return hinge + Offset(len * math.cos(th), len * 0.35 * math.sin(th));
  }
  final ph = open * 80 * math.pi / 180;
  return hinge + Offset(len * math.cos(ph), -len * math.sin(ph));
}

class M6AbPainter extends CustomPainter {
  M6AbPainter({required this.geo, required this.rig, required this.seed, required this.handle}) : super(repaint: handle);

  final M6AbGeo geo;
  final M6AbRig rig;
  final int seed;

  /// The handle's place on its arc (0 ON … 1 OFF); repaints the lever and
  /// the blades, which follow it.
  final ValueListenable<double> handle;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    final rnd = math.Random(seed);
    // Morning sky.
    final sky = Rect.fromLTWH(0, 0, w, g.groundY);
    c.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7FB6E6), Color(0xFFBFDCF2), Color(0xFFF6E3C0)],
        ).createShader(sky),
    );
    // Far: by place.
    _far(c, g, w, rnd);
    // Ground: verge and road.
    final verge = Rect.fromLTRB(0, g.groundY - 6, w, size.height);
    c.drawRect(
      verge,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7FA35A), Color(0xFF5E8240)],
        ).createShader(verge),
    );
    final road = Rect.fromLTRB(0, g.groundY + 22, w, size.height);
    c.drawRect(road, Paint()..color = const Color(0xFF55595E));
    for (var x = 8.0; x < w; x += 46) {
      c.drawRect(Rect.fromLTWH(x, g.groundY + 50, 24, 4), Paint()..color = const Color(0xFFE6E2D3));
    }
    _van(c, g);
    _structure(c, g);
    _switch(c, g);
    _handle(c, g, handle.value);
    _earthLead(c, g, rnd);
    // The morning sun right behind the switch: its glare washes the far
    // blades (look up through the gap view to see them).
    final sun = g.abCentre + const Offset(6, -18);
    c.drawCircle(
      sun,
      120,
      Paint()
        ..shader = RadialGradient(colors: [
          const Color(0xF2FFFFF4),
          const Color(0xB3FFF6D6),
          const Color(0x33FFF0C0),
          const Color(0x00FFF0C0),
        ], stops: const [0.0, 0.28, 0.6, 1.0])
            .createShader(Rect.fromCircle(center: sun, radius: 120)),
    );
  }

  void _far(Canvas c, M6AbGeo g, double w, math.Random rnd) {
    final base = g.groundY - 4;
    switch (rig.place) {
      case M6AbPlace.road:
        for (var i = 0; i < 6; i++) {
          final x = i * 66.0 - 10 + rnd.nextDouble() * 12;
          final h = 34 + rnd.nextDouble() * 40;
          c.drawRect(Rect.fromLTWH(x, base - h, 52, h), Paint()..color = Color.lerp(const Color(0xFFC9B79C), const Color(0xFFB3A48E), rnd.nextDouble())!);
          for (var k = 0; k < 2; k++) {
            c.drawRect(Rect.fromLTWH(x + 8 + k * 22, base - h + 10, 12, 10), Paint()..color = const Color(0xFF7D8C99));
          }
        }
      case M6AbPlace.field:
        c.drawRect(Rect.fromLTRB(0, base - 18, w, base), Paint()..color = const Color(0xFF9DBB6A));
        for (var i = 0; i < 7; i++) {
          final x = i * 54.0 + rnd.nextDouble() * 20;
          final r = 14 + rnd.nextDouble() * 10;
          c.drawRect(Rect.fromLTWH(x - 2, base - 30, 4, 22), Paint()..color = const Color(0xFF6B4E30));
          c.drawCircle(Offset(x, base - 34 - r * 0.4), r, Paint()..color = const Color(0xFF4F7F3A));
        }
      case M6AbPlace.market:
        for (var i = 0; i < 5; i++) {
          final x = i * 76.0 - 6;
          c.drawRect(Rect.fromLTWH(x, base - 46, 66, 46), Paint()..color = const Color(0xFFD7C7A8));
          final awning = Path()
            ..moveTo(x - 4, base - 46)
            ..lineTo(x + 70, base - 46)
            ..lineTo(x + 64, base - 34)
            ..lineTo(x + 2, base - 34)
            ..close();
          c.drawPath(awning, Paint()..color = [const Color(0xFFC0563A), const Color(0xFF3A7FC0), const Color(0xFFD9A030)][(i + rnd.nextInt(3)) % 3]);
        }
    }
  }

  void _van(Canvas c, M6AbGeo g) {
    final v = g.van;
    final body = RRect.fromRectAndCorners(v, topLeft: const Radius.circular(10), topRight: const Radius.circular(6));
    c.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF2F2EE), Color(0xFFC9CCC8)]).createShader(v),
    );
    c.drawRect(Rect.fromLTWH(v.left, v.bottom - 30, v.width, 8), Paint()..color = const Color(0xFF1F5F8F));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(v.left + 8, v.top + 12, v.width - 20, v.height - 50), const Radius.circular(4)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = const Color(0xFF9EA3A0));
    for (final x in [v.left + 30, v.right - 34]) {
      c.drawCircle(Offset(x, v.bottom), 14, Paint()..color = const Color(0xFF222629));
      c.drawCircle(Offset(x, v.bottom), 6, Paint()..color = const Color(0xFF8D949A));
    }
  }

  void _structure(Canvas c, M6AbGeo g) {
    for (final x in [M6AbGeo.lp, M6AbGeo.rp]) {
      final pole = Path()
        ..moveTo(x - 4, g.topY - 66)
        ..lineTo(x + 4, g.topY - 66)
        ..lineTo(x + 6, g.groundY)
        ..lineTo(x - 6, g.groundY)
        ..close();
      c.drawPath(
        pole,
        Paint()..shader = const LinearGradient(colors: [Color(0xFFB8BDC0), _concrete, Color(0xFF7A8084)]).createShader(Rect.fromLTRB(x - 6, g.topY, x + 6, g.groundY)),
      );
    }
    // The channels (the top one carries the line's pin insulators).
    for (final yy in [g.topY - 60, g.topY + 4, g.topY + 46]) {
      c.drawRect(Rect.fromLTRB(M6AbGeo.lp - 8, yy, M6AbGeo.rp + 8, yy + 7), Paint()..color = _steel);
    }
    // A danger plate on the right pole (a label a worker reads).
    final plate = Rect.fromCenter(center: Offset(M6AbGeo.rp, g.y(0.42)), width: 22, height: 16);
    c.drawRect(plate, Paint()..color = const Color(0xFFF2F0E6));
    c.drawRect(plate, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFFC0392B));
    final tp = TextPainter(
      text: const TextSpan(text: '11 kV', style: TextStyle(fontSize: 6.5, fontWeight: FontWeight.w900, color: Color(0xFFC0392B))),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, plate.center - Offset(tp.width / 2, tp.height / 2));
    // The operating pipe down the left pole to the gearbox.
    c.drawLine(Offset(M6AbGeo.lp + 9, g.topY + 10), Offset(M6AbGeo.lp + 9, g.pivot.dy - 8), Paint()
      ..color = const Color(0xFF7D868D)
      ..strokeWidth = 3.4);
    // The gang shaft along the channel.
    c.drawLine(Offset(M6AbGeo.lp + 9, g.topY + 10), Offset(M6AbGeo.rp - 10, g.topY + 10), Paint()
      ..color = const Color(0xFF7D868D)
      ..strokeWidth = 2.4);
  }

  void _switch(Canvas c, M6AbGeo g) {
    final postTop = g.topY - 22;
    // The blades turn with the handle (never ahead of it).
    final tips = m6SceneBladeTips(g, rig, handle.value);
    for (var i = 0; i < 3; i++) {
      final x = M6AbGeo.phaseX[i];
      final hinge = Offset(x - 12, postTop);
      final jaw = Offset(x + 12, postTop);
      _post(c, Offset(hinge.dx, g.topY + 4), postTop, 4.2);
      _post(c, Offset(jaw.dx, g.topY + 4), postTop, 4.2);
      // The jumpers up to the line's pin insulators on the top channel.
      for (final (e, dx) in [(hinge, -3.0), (jaw, 3.0)]) {
        final top = Offset(e.dx + dx, g.topY - 54);
        c.drawLine(e, top, Paint()
          ..color = _wire
          ..strokeWidth = 1.2);
        c.drawRect(Rect.fromCenter(center: top + const Offset(0, -2), width: 5, height: 6), Paint()..color = _porcelain);
      }
      // Jaw and blade.
      c.drawRect(Rect.fromCenter(center: jaw, width: 6, height: 5), Paint()..color = const Color(0xFF8C7B4A));
      final tip = tips[i];
      c.drawLine(hinge, tip, Paint()
        ..color = const Color(0xFF8E8A80)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round);
    }
  }

  void _handle(Canvas c, M6AbGeo g, double t) {
    final p = g.pivot;
    // The quadrant plate with its two stops.
    final arc = Rect.fromCircle(center: p, radius: M6AbGeo.armLen + 6);
    c.drawArc(arc, M6AbGeo.a0, M6AbGeo.a1 - M6AbGeo.a0, false, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..color = const Color(0xFF4A5157));
    for (final (a, label) in [(M6AbGeo.a0, 'ON'), (M6AbGeo.a1, 'OFF')]) {
      final s = p + Offset(math.cos(a), math.sin(a)) * (M6AbGeo.armLen + 6);
      c.drawCircle(s, 3.4, Paint()..color = const Color(0xFF2E3338));
      final tp = TextPainter(
        text: TextSpan(text: label, style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: Color(0xFF1E2328))),
        textDirection: TextDirection.ltr,
      )..layout();
      final at = p + Offset(math.cos(a), math.sin(a)) * (M6AbGeo.armLen + 16);
      tp.paint(c, at - Offset(tp.width / 2, tp.height / 2));
    }
    // The gearbox.
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: p, width: 18, height: 22), const Radius.circular(3)), Paint()..color = const Color(0xFF3E464C));
    // The lever and its grip.
    final grip = g.grip(t);
    c.drawLine(p, grip, Paint()
      ..color = const Color(0xFF6E777E)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round);
    final a = g.angleAt(t);
    final d = Offset(math.cos(a), math.sin(a));
    c.drawLine(grip - d * 12, grip + d * 2, Paint()
      ..color = const Color(0xFFD23C2A)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round);
    c.drawCircle(p, 3.5, Paint()..color = const Color(0xFFB9C1C7));
  }

  void _earthLead(Canvas c, M6AbGeo g, math.Random rnd) {
    final path = Path()
      ..moveTo(g.leadTop.dx, g.leadTop.dy)
      ..lineTo(g.leadBend.dx, g.leadBend.dy)
      ..lineTo(g.earthPipe.dx, g.earthPipe.dy);
    c.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..color = _lead);
    c.drawPath(path, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = _leadStripe);
    // The earth pipe's head.
    c.drawRect(Rect.fromCenter(center: g.earthPipe, width: 7, height: 10), Paint()..color = const Color(0xFF9AA2A8));
    // Grass over the lead's last stretch and the clamp.
    final grass = Paint()
      ..color = const Color(0xFF4E7A34)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (var x = 12.0; x < 126; x += 3.2) {
      final h = 10 + rnd.nextDouble() * 16;
      final lean = (rnd.nextDouble() - 0.5) * 7;
      c.drawLine(Offset(x, g.groundY + 2), Offset(x + lean, g.groundY - h), grass);
    }
  }

  @override
  bool shouldRepaint(M6AbPainter old) => old.geo != geo || old.rig != rig || old.seed != seed || old.handle != handle;
}

/// The tilt-up gap view: one phase, close up, its real blade position.
class M6AbGapViewPainter extends CustomPainter {
  const M6AbGapViewPainter({required this.kind, required this.open, required this.phase, required this.seed});

  final M6AbBreak kind;
  final double open;
  final int phase;
  final int seed;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    final r = Offset.zero & size;
    c.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6FA8DC), Color(0xFFB9D7EE), Color(0xFFE8F0F2)],
        ).createShader(r),
    );
    final rnd = math.Random(seed * 3 + phase);
    for (var i = 0; i < 2; i++) {
      final cx = rnd.nextDouble() * w;
      final cy = 14 + rnd.nextDouble() * h * 0.25;
      for (var k = 0; k < 3; k++) {
        c.drawCircle(Offset(cx + k * 12, cy + (k == 1 ? -5 : 0)), 10, Paint()..color = const Color(0xCCFFFFFF));
      }
    }
    // The channel at the bottom.
    c.drawRect(Rect.fromLTRB(0, h * 0.9, w, h * 0.97), Paint()..color = _steel);
    final postTop = h * 0.64;
    final hinge = Offset(w * 0.26, postTop);
    final jaw = Offset(w * 0.74, postTop);
    _post(c, Offset(hinge.dx, h * 0.9), postTop, 11);
    _post(c, Offset(jaw.dx, h * 0.9), postTop, 11);
    // The line conductors off the edges.
    final line = Paint()
      ..color = _wire
      ..strokeWidth = 2.6;
    c.drawLine(hinge, Offset(0, postTop - 34), line);
    c.drawLine(jaw, Offset(w, postTop - 34), line);
    // The jaw: two contact fingers.
    final fp = Paint()
      ..color = const Color(0xFFB08A3E)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    c.drawLine(jaw + const Offset(-10, -9), jaw + const Offset(4, -9), fp);
    c.drawLine(jaw + const Offset(-10, 3), jaw + const Offset(4, 3), fp);
    c.drawRect(Rect.fromCenter(center: jaw + const Offset(4, -3), width: 6, height: 16), Paint()..color = const Color(0xFF8C6E30));
    // The blade from its hinge.
    final len = math.min(jaw.dx - hinge.dx - 2, postTop - 14);
    final tip = m6BladeTip(kind, hinge + const Offset(0, -3), len, open);
    c.drawLine(hinge + const Offset(0, -3), tip, Paint()
      ..color = const Color(0xFF9C978A)
      ..strokeWidth = kind == M6AbBreak.horizontal ? 6 - 2.5 * open : 6
      ..strokeCap = StrokeCap.round);
    c.drawCircle(tip, 3.4, Paint()..color = const Color(0xFFC9A55A));
    c.drawCircle(hinge + const Offset(0, -3), 7, Paint()..color = const Color(0xFF6E767C));
    // Arrows on the sides (there is a phase that way).
    final ap = Paint()
      ..color = const Color(0x8C0B1324)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    if (phase > 0) c.drawPath(Path()..moveTo(14, h * 0.42)..lineTo(6, h * 0.5)..lineTo(14, h * 0.58), ap);
    if (phase < 2) c.drawPath(Path()..moveTo(w - 14, h * 0.42)..lineTo(w - 6, h * 0.5)..lineTo(w - 14, h * 0.58), ap);
  }

  @override
  bool shouldRepaint(M6AbGapViewPainter old) => old.kind != kind || old.open != open || old.phase != phase || old.seed != seed;
}

/// The earth-lead view's layout (local px in [M6AbGeo.view]'s size).
abstract final class M6EarthView {
  static const Offset gap = Offset(118, 95);
  static const Offset nut = Offset(134, 138);
  static const Offset spareHome = Offset(40, 142);
  static Rect get nutHit => Rect.fromCenter(center: nut, width: 44, height: 40);
  static Rect spareHit(Offset at) => Rect.fromCenter(center: at, width: 60, height: 44);

  /// A spare lead dropped this close to the cut bridges it.
  static const double dropRadius = 34;
}

/// The earth-lead close-up: the lead from the gearbox to the earth pipe's
/// clamp, as dealt (whole / cut / clamp loose) or fixed; the spare lead at
/// [spare] (it follows the finger while dragged).
class M6AbEarthViewPainter extends CustomPainter {
  M6AbEarthViewPainter({required this.state, required this.fixed, required this.spare}) : super(repaint: spare);

  final M6AbEarth state;
  final bool fixed;
  final ValueListenable<Offset> spare;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    final r = Offset.zero & size;
    c.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8DB36A), Color(0xFF6B8F4A), Color(0xFF7A5B3A)])
            .createShader(r),
    );
    // The pole's foot and the gearbox.
    c.drawRect(Rect.fromLTRB(14, 0, 40, h), Paint()..shader = const LinearGradient(colors: [Color(0xFFB8BDC0), _concrete, Color(0xFF7A8084)]).createShader(Rect.fromLTRB(14, 0, 40, h)));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(20, 0, 30, 18), const Radius.circular(3)), Paint()..color = const Color(0xFF3E464C));
    // The earth pipe in its pit.
    c.drawOval(Rect.fromCenter(center: Offset(118, h - 18), width: 64, height: 22), Paint()..color = const Color(0xFF4A3524));
    c.drawRect(Rect.fromLTRB(112, 128, 124, h - 12), Paint()..shader = const LinearGradient(colors: [Color(0xFFC7CDD1), Color(0xFF8E979D)]).createShader(Rect.fromLTRB(112, 128, 124, h)));
    // The lead: gearbox → down → across → down to the clamp.
    final lp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = _lead;
    final sp = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..color = _leadStripe;
    void lead(Path p) {
      c.drawPath(p, lp);
      c.drawPath(p, sp);
    }

    final cut = state == M6AbEarth.cut && !fixed;
    final loose = state == M6AbEarth.loose && !fixed;
    final upper = Path()
      ..moveTo(36, 16)
      ..lineTo(60, 52)
      ..lineTo(118, 60)
      ..lineTo(118, cut ? 84 : 132);
    lead(upper);
    if (cut) {
      lead(Path()
        ..moveTo(118, 108)
        ..lineTo(118, 132));
      // Frayed copper ends.
      final cu = Paint()
        ..color = const Color(0xFFD08A3A)
        ..strokeWidth = 1.4;
      for (final (y, s) in [(84.0, 1.0), (108.0, -1.0)]) {
        for (var k = -2; k <= 2; k++) {
          c.drawLine(Offset(118, y), Offset(118 + k * 2.4, y + s * 7), cu);
        }
      }
    }
    if (state == M6AbEarth.cut && fixed) {
      // The spare lead bolted across the cut.
      final p = Path()
        ..moveTo(118, 78)
        ..quadraticBezierTo(130, 96, 118, 114);
      lead(p);
      for (final y in [78.0, 114.0]) {
        c.drawRect(Rect.fromCenter(center: Offset(118, y), width: 12, height: 6), Paint()..color = const Color(0xFFB8BFC4));
      }
    }
    // The clamp band round the pipe, its nut; a loose one hangs open with
    // the lead's lug off it.
    c.drawRect(Rect.fromLTRB(108, 130, 128, 142), Paint()..color = const Color(0xFFB8BFC4));
    final nut = M6EarthView.nut + (loose ? const Offset(7, 2) : Offset.zero);
    if (loose) {
      c.drawLine(const Offset(128, 136), nut, Paint()
        ..color = const Color(0xFF8E979D)
        ..strokeWidth = 3);
    }
    final hex = Path();
    for (var k = 0; k < 6; k++) {
      final a = k * math.pi / 3;
      final pt = nut + Offset(math.cos(a), math.sin(a)) * 7;
      k == 0 ? hex.moveTo(pt.dx, pt.dy) : hex.lineTo(pt.dx, pt.dy);
    }
    c.drawPath(hex..close(), Paint()..color = const Color(0xFF7D868D));
    if (loose) {
      // The lug off the clamp: the lead's end hangs beside it.
      lead(Path()
        ..moveTo(118, 118)
        ..quadraticBezierTo(104, 140, 96, 150));
      c.drawCircle(const Offset(96, 151), 4, Paint()..color = const Color(0xFFB8BFC4));
    }
    // The spare lead (a short coil with two lugs), wherever it is now.
    final at = spare.value;
    if (!(state == M6AbEarth.cut && fixed)) {
      final coil = Path()
        ..moveTo(at.dx - 22, at.dy + 4)
        ..cubicTo(at.dx - 10, at.dy - 14, at.dx + 6, at.dy + 16, at.dx + 22, at.dy - 4);
      lead(coil);
      for (final e in [Offset(at.dx - 22, at.dy + 4), Offset(at.dx + 22, at.dy - 4)]) {
        c.drawRect(Rect.fromCenter(center: e, width: 9, height: 6), Paint()..color = const Color(0xFFB8BFC4));
      }
    }
    // A spanner resting by the nut.
    final sp2 = Paint()
      ..color = const Color(0xFF9AA1A7)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(w - 22, h - 46), Offset(w - 46, h - 18), sp2);
    c.drawCircle(Offset(w - 20, h - 48), 6, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFF9AA1A7));
    // Grass tufts on top (the view parts them over the lead).
    final grass = Paint()
      ..color = const Color(0xFF3F6A2A)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final rnd = math.Random(7);
    for (var x = 0.0; x < w; x += 5) {
      if ((x - 118).abs() < 20) continue;
      final hh = 8 + rnd.nextDouble() * 12;
      c.drawLine(Offset(x, h), Offset(x + (rnd.nextDouble() - 0.5) * 6, h - hh), grass);
    }
  }

  @override
  bool shouldRepaint(M6AbEarthViewPainter old) => old.state != state || old.fixed != fixed || old.spare != spare;
}

/// The arc of an AB opened on load: a white-violet burst at the switch,
/// coming off the grey frozen scene in colour.
class M6AbFlashPainter extends CustomPainter {
  const M6AbFlashPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final r = 30 + 90 * v;
    c.drawCircle(
      at,
      r,
      Paint()
        ..shader = RadialGradient(colors: [
          Colors.white.withValues(alpha: 0.95),
          const Color(0xFFB9A8FF).withValues(alpha: 0.75 * (1 - v * 0.4)),
          const Color(0x00B9A8FF),
        ], stops: const [0.0, 0.35, 1.0])
            .createShader(Rect.fromCircle(center: at, radius: r)),
    );
    final bolt = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;
    final rnd = math.Random(11);
    for (var k = 0; k < 6; k++) {
      final a = k * math.pi / 3 + rnd.nextDouble() * 0.4;
      var p = at;
      final path = Path()..moveTo(p.dx, p.dy);
      for (var s = 0; s < 4; s++) {
        p = p + Offset(math.cos(a + (rnd.nextDouble() - 0.5)), math.sin(a + (rnd.nextDouble() - 0.5))) * (10 + 14 * v);
        path.lineTo(p.dx, p.dy);
      }
      c.drawPath(path, bolt);
    }
  }

  @override
  bool shouldRepaint(M6AbFlashPainter old) => old.at != at || old.v != v;
}
