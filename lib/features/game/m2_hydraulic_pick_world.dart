import 'dart:math' as math;

import 'package:flutter/material.dart';

// Lesson 2.9 (হাইড্রোলিক ক্রিম্পার ও কাটার), কাজ 1 — the drawn world: the
// tool store before the job. A back wall with a window, a pegboard where the
// hydraulic crimpers and cutters hang (the tools are widgets on it), the
// docket's clipboard on the wall by the door, a bench below with the open die
// case and a crate for tools sent to servicing. No text in the art. Design:
// 360 wide × any height; the bench stands on the floor row, so a tall phone
// gets more wall and window, never a stretched bench.
//
// The tools themselves are drawn by [HydToolPainter] (pegboard, close look),
// the job close-ups (crimping a lug, cutting an armoured cable) by
// [HydWorkPainter]. Everything is code-drawn: no new asset folder for the
// scene.

/// What the docket asks for.
enum HydJob { crimp, cut }

/// What hangs on the pegboard.
enum HydKind {
  /// Hand-pumped hydraulic crimper (C head, hex dies, two pump arms).
  crimper,

  /// Battery hydraulic crimper (pistol body, battery pack with a charge gauge).
  batteryCrimper,

  /// Hand-pumped hydraulic cable cutter (curved blades, safety lock).
  cutter,

  /// A small mechanical hand crimper (hand strength only).
  handCrimper,

  /// A hacksaw.
  hacksaw,
}

/// A fault a tool can have. Each shows only to a check that looks for it.
enum HydFlaw {
  none,

  /// Oil seeping at the seal between head and body (the seals are gone).
  leak,

  /// The pump arm sticks half way: the pumping action is not smooth.
  pump,

  /// The battery pack is flat (battery crimper only).
  battery,
}

extension HydKindInfo on HydKind {
  bool get hydraulic => this == HydKind.crimper || this == HydKind.batteryCrimper || this == HydKind.cutter;
  bool get crimps => this == HydKind.crimper || this == HydKind.batteryCrimper || this == HydKind.handCrimper;
}

/// Where things are, in design pixels (360 × [h]).
@immutable
class HydStoreGeo {
  const HydStoreGeo(this.h);
  final double h;

  /// The bench top (the die case and the crate stand on it).
  double get bench => h - 150;

  /// The floor line (behind the bench's legs).
  double get floor => h - 60;

  /// The pegboard on the back wall.
  Rect get board => Rect.fromLTRB(92, bench - 318, 354, bench - 22);

  /// Hook [i] of [n] on the pegboard (two columns).
  Rect slot(int i, int n) {
    final rows = (n / 2).ceil();
    final b = board.deflate(8);
    final cw = b.width / 2;
    final rh = b.height / rows;
    final col = i % 2;
    final row = i ~/ 2;
    return Rect.fromLTWH(b.left + cw * col + 3, b.top + rh * row + 10, cw - 6, rh - 16);
  }

  /// The docket's clipboard, on the wall by the door.
  Rect get docket => Rect.fromLTWH(12, bench - 304, 66, 118);

  /// The open die case on the bench.
  Rect get dieCase => Rect.fromLTWH(104, bench - 46, 124, 48);

  /// The crate for tools sent to servicing.
  Rect get crate => Rect.fromLTWH(244, bench - 52, 108, 54);

  /// The trainee, by the door.
  Rect get trainee => Rect.fromLTWH(0, floor - 150, 78, 156);
}

class HydStorePainter extends CustomPainter {
  const HydStorePainter(this.geo);
  final HydStoreGeo geo;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final h = s.height;

    // Back wall: warm plaster, darker towards the floor.
    final wall = Rect.fromLTWH(0, 0, w, geo.floor);
    c.drawRect(
      wall,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFCFD6D2), Color(0xFFB7C1BC), Color(0xFF98A49F)],
          stops: [0, 0.6, 1],
        ).createShader(wall),
    );
    // A painted dado band at hand height.
    c.drawRect(Rect.fromLTWH(0, geo.bench - 6, w, geo.floor - geo.bench + 6), Paint()..color = const Color(0xFF6F8C86));

    // The window (only where the wall is tall enough): sky and a far line.
    final winBottom = geo.board.top - 26;
    if (winBottom > 150) {
      final win = Rect.fromLTRB(120, math.max(96, winBottom - 150), 326, winBottom);
      c.drawRect(
        win,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF5D9BD3), Color(0xFFBFDCEF)],
          ).createShader(win),
      );
      final far = Paint()..color = const Color(0xFF8EA8BA);
      for (final x in [win.left + 30, win.left + 110, win.left + 180]) {
        c.drawRect(Rect.fromLTWH(x, win.bottom - 60, 3, 60), far);
        c.drawRect(Rect.fromLTWH(x - 9, win.bottom - 60, 21, 2.5), far);
      }
      c.drawLine(
        Offset(win.left, win.bottom - 57),
        Offset(win.right, win.bottom - 55),
        Paint()
          ..color = const Color(0xFF8EA8BA)
          ..strokeWidth = 1,
      );
      final frame = Paint()
        ..color = const Color(0xFF5A6460)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5;
      c.drawRect(win, frame);
      c.drawLine(Offset(win.center.dx, win.top), Offset(win.center.dx, win.bottom), frame..strokeWidth = 3);
      c.drawLine(Offset(win.left, win.center.dy), Offset(win.right, win.center.dy), frame);
    }

    // The door frame on the left (the clipboard hangs beside it).
    c.drawRect(Rect.fromLTWH(-8, geo.bench - 360, 8 + 6, geo.floor - geo.bench + 360), Paint()..color = const Color(0xFF6E5A44));

    // Pegboard: hardboard with a hole grid.
    final b = geo.board;
    c.drawRRect(RRect.fromRectAndRadius(b.inflate(4), const Radius.circular(4)), Paint()..color = const Color(0xFF7A5E3E));
    c.drawRect(
      b,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFC79B67), Color(0xFFB4844F)],
        ).createShader(b),
    );
    final hole = Paint()..color = const Color(0x66432C14);
    for (var y = b.top + 9.0; y < b.bottom - 4; y += 14) {
      for (var x = b.left + 9.0; x < b.right - 4; x += 14) {
        c.drawCircle(Offset(x, y), 1.4, hole);
      }
    }

    // The bench: a thick top, an apron, legs to the floor.
    final top = Rect.fromLTRB(88, geo.bench, w + 4, geo.bench + 14);
    c.drawRect(top, Paint()..shader = const LinearGradient(colors: [Color(0xFF8B5E34), Color(0xFF6F4826)]).createShader(top));
    c.drawRect(Rect.fromLTRB(88, geo.bench + 14, w + 4, geo.bench + 34), Paint()..color = const Color(0xFF5B3B1F));
    final leg = Paint()..color = const Color(0xFF4A3018);
    for (final x in [98.0, 334.0]) {
      c.drawRect(Rect.fromLTWH(x, geo.bench + 34, 12, geo.floor - geo.bench - 34 + 10), leg);
    }

    // Floor: concrete.
    final floor = Rect.fromLTWH(0, geo.floor, w, h - geo.floor);
    c.drawRect(
      floor,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8C8F8C), Color(0xFF6C6F6D)],
        ).createShader(floor),
    );
    c.drawLine(
      Offset(0, geo.floor),
      Offset(w, geo.floor),
      Paint()
        ..color = const Color(0xFF555856)
        ..strokeWidth = 2,
    );
    // The bench's shadow on the floor.
    c.drawOval(Rect.fromLTRB(84, geo.floor + 2, w + 10, geo.floor + 18), Paint()..color = const Color(0x33000000));

    // The crate for servicing (its label is a widget).
    final cr = geo.crate;
    c.drawRect(cr, Paint()..color = const Color(0xFF3D5A80));
    final slat = Paint()..color = const Color(0xFF2E4766);
    for (var i = 1; i < 3; i++) {
      c.drawRect(Rect.fromLTWH(cr.left, cr.top + cr.height * i / 3 - 1.5, cr.width, 3), slat);
    }
    c.drawRect(
      cr,
      Paint()
        ..color = const Color(0xFF243A55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(HydStorePainter old) => old.geo.h != geo.h;
}

/// How many stretches the body of a tool is looked at in (the finger slide).
const kHydBins = 16;
int hydBin(double u) => (u * kHydBins).floor().clamp(0, kHydBins - 1);

/// Where the oil seeps on a leaking tool (0 head … 1 handle end).
const kHydLeakU = 0.29;

/// A tool drawn lengthwise, head on the left. [seen]: stretches of the body
/// the finger has run along (null = all seen) — a leak shows only there; the
/// unseen part is washed with [veil] when it is set. [stroked]: the pump arm
/// (or the trigger) has been tried, so a sticking pump shows its rusted pivot
/// and a flat battery its dead gauge blinks. [arm]: the pump arm's stroke
/// (0 up … 1 down; a sticking arm stops half way).
class HydToolPainter extends CustomPainter {
  HydToolPainter(this.kind, this.flaw, {this.seen, this.veil, this.stroked = false, this.arm = 0});
  final HydKind kind;
  final HydFlaw flaw;
  final Set<int>? seen;
  final Color? veil;
  final bool stroked;
  final double arm;

  static bool _any(Set<int>? seen, double a, double b) {
    if (seen == null) return true;
    for (var i = hydBin(a); i <= hydBin(b); i++) {
      if (seen.contains(i)) return true;
    }
    return false;
  }

  /// The tool's fault is in view (false for a sound tool). A leak needs the
  /// finger over the seal; a sticking pump needs a stroke of the arm; a flat
  /// battery shows on the gauge at once (the gauge is always lit).
  static bool flawSeen(HydFlaw flaw, Set<int>? seen, {required bool stroked}) => switch (flaw) {
        HydFlaw.none => false,
        HydFlaw.leak => _any(seen, kHydLeakU - 0.05, kHydLeakU + 0.05),
        HydFlaw.pump => stroked,
        HydFlaw.battery => true,
      };

  static const _steel = Color(0xFF9AA4AD);
  static const _steelDark = Color(0xFF5E6870);

  @override
  void paint(Canvas c, Size s) {
    switch (kind) {
      case HydKind.handCrimper:
        _handCrimper(c, s);
      case HydKind.hacksaw:
        _hacksaw(c, s);
      case HydKind.crimper:
      case HydKind.cutter:
        _pumpTool(c, s);
      case HydKind.batteryCrimper:
        _batteryTool(c, s);
    }
    _wash(c, s);
  }

  Paint _fill(Rect r, Color a, Color b) => Paint()
    ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [a, b]).createShader(r);

  /// The C head with its hex die halves (crimper) or the curved blades (cutter).
  void _head(Canvas c, Size s, {required bool cutter}) {
    final w = s.width;
    final h = s.height;
    final head = Rect.fromLTRB(w * 0.03, h * 0.12, w * 0.27, h * 0.78);
    if (cutter) {
      // Two hooked steel blades round an open throat.
      final throat = Offset(w * 0.13, h * 0.44);
      final r = math.min(w * 0.1, h * 0.3);
      final upper = Path()
        ..moveTo(w * 0.27, h * 0.3)
        ..quadraticBezierTo(w * 0.2, h * 0.02, throat.dx - r * 0.9, h * 0.14)
        ..quadraticBezierTo(throat.dx - r * 1.3, throat.dy - r * 0.2, throat.dx - r * 0.2, throat.dy - r * 0.15)
        ..quadraticBezierTo(throat.dx + r * 0.6, throat.dy - r * 0.9, w * 0.27, h * 0.46)
        ..close();
      final lower = Path()
        ..moveTo(w * 0.27, h * 0.5)
        ..quadraticBezierTo(throat.dx + r * 0.5, throat.dy + r * 1.1, throat.dx - r * 0.3, throat.dy + r * 0.25)
        ..quadraticBezierTo(throat.dx - r * 1.2, throat.dy + r * 0.6, throat.dx - r * 0.7, h * 0.8)
        ..quadraticBezierTo(w * 0.2, h * 0.86, w * 0.27, h * 0.66)
        ..close();
      c.drawPath(upper, _fill(head, const Color(0xFFC9D0D6), _steelDark));
      c.drawPath(lower, _fill(head, const Color(0xFFB7BFC6), _steelDark));
      final edge = Paint()
        ..color = const Color(0xFFEFF3F6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, h * 0.02);
      c.drawPath(upper, edge);
      c.drawPath(lower, edge);
      // The safety lock pin across the throat's mouth.
      c.drawCircle(Offset(throat.dx - r * 0.85, h * 0.2), math.max(1.6, h * 0.035), Paint()..color = const Color(0xFFE0B23A));
    } else {
      final ring = RRect.fromRectAndCorners(head, topLeft: Radius.circular(h * 0.12), bottomLeft: Radius.circular(h * 0.12), topRight: Radius.circular(h * 0.05), bottomRight: Radius.circular(h * 0.05));
      c.drawRRect(ring, _fill(head, const Color(0xFFB9C2CA), _steelDark));
      // The open side (left) and the die window.
      final win = Rect.fromLTRB(w * 0.0, h * 0.3, w * 0.19, h * 0.6);
      c.drawRRect(RRect.fromRectAndRadius(win, Radius.circular(h * 0.04)), Paint()..color = const Color(0xFF2A3036));
      // Hex die halves (brass), top and bottom.
      final die = Paint()..color = const Color(0xFFD9A441);
      final dx = w * 0.11;
      for (final top in [true, false]) {
        final y = top ? win.top : win.bottom;
        final k = top ? 1.0 : -1.0;
        final p = Path()
          ..moveTo(dx - w * 0.07, y)
          ..lineTo(dx + w * 0.07, y)
          ..lineTo(dx + w * 0.045, y + k * h * 0.11)
          ..lineTo(dx - w * 0.045, y + k * h * 0.11)
          ..close();
        c.drawPath(p, die);
      }
      c.drawRRect(
        ring,
        Paint()
          ..color = const Color(0xFF444C53)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(0.8, h * 0.015),
      );
    }
  }

  void _seal(Canvas c, Size s) {
    final w = s.width;
    final h = s.height;
    c.drawRect(Rect.fromLTRB(w * (kHydLeakU - 0.025), h * 0.27, w * (kHydLeakU + 0.025), h * 0.63), Paint()..color = const Color(0xFF1E2226));
  }

  void _leak(Canvas c, Size s) {
    if (flaw != HydFlaw.leak || !flawSeen(flaw, seen, stroked: stroked)) return;
    final w = s.width;
    final h = s.height;
    final oil = Paint()..color = const Color(0xE0C08A1E);
    final x = w * kHydLeakU;
    // A wet smear along the body's underside and drops falling from the seal.
    c.drawOval(Rect.fromCenter(center: Offset(x + w * 0.04, h * 0.62), width: w * 0.12, height: h * 0.07), Paint()..color = const Color(0x99A8741A));
    final drop = Path()
      ..moveTo(x, h * 0.62)
      ..quadraticBezierTo(x + w * 0.012, h * 0.7, x, h * 0.73)
      ..quadraticBezierTo(x - w * 0.012, h * 0.7, x, h * 0.62);
    c.drawPath(drop, oil);
    c.drawCircle(Offset(x + w * 0.002, h * 0.84), math.max(1.2, h * 0.03), oil);
    c.drawOval(Rect.fromCenter(center: Offset(x + w * 0.01, h * 0.96), width: w * 0.08, height: h * 0.04), Paint()..color = const Color(0xAA8A5E14));
    c.drawCircle(Offset(x - w * 0.006, h * 0.66), math.max(0.6, h * 0.01), Paint()..color = const Color(0xCCFFF2C8));
  }

  void _pumpTool(Canvas c, Size s) {
    final w = s.width;
    final h = s.height;
    final cutter = kind == HydKind.cutter;
    // Fixed handle (behind), with its black grip.
    final fixed = Rect.fromLTRB(w * 0.52, h * 0.48, w * 0.98, h * 0.6);
    c.drawRRect(RRect.fromRectAndRadius(fixed, Radius.circular(h * 0.05)), Paint()..color = _steel);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(w * 0.7, h * 0.46, w * 0.98, h * 0.62), Radius.circular(h * 0.07)), Paint()..color = const Color(0xFF26292D));
    // Body: the oil cylinder.
    final body = Rect.fromLTRB(w * 0.3, h * 0.27, w * 0.56, h * 0.63);
    c.drawRRect(
      RRect.fromRectAndRadius(body, Radius.circular(h * 0.08)),
      _fill(body, cutter ? const Color(0xFF3E78B8) : const Color(0xFFD2412F), cutter ? const Color(0xFF1F4672) : const Color(0xFF8A2318)),
    );
    c.drawRect(Rect.fromLTRB(w * 0.31, h * 0.31, w * 0.55, h * 0.35), Paint()..color = const Color(0x40FFFFFF));
    // The release valve knob on top.
    c.drawCircle(Offset(w * 0.5, h * 0.24), math.max(2.0, h * 0.05), Paint()..color = const Color(0xFFC9CED3));
    c.drawCircle(Offset(w * 0.5, h * 0.24), math.max(1.0, h * 0.022), Paint()..color = _steelDark);
    // The pump arm, hinged at the body's top right; [arm] brings it down.
    final pivot = Offset(w * 0.56, h * 0.34);
    final stick = flaw == HydFlaw.pump;
    final a = (stick ? math.min(arm, 0.45) : arm).clamp(0.0, 1.0);
    final angle = -0.32 + 0.26 * a;
    final len = w * 0.42;
    final tip = pivot + Offset(math.cos(angle), math.sin(angle)) * len;
    c.drawLine(
      pivot,
      tip,
      Paint()
        ..color = _steel
        ..strokeWidth = math.max(2.0, h * 0.09)
        ..strokeCap = StrokeCap.round,
    );
    final gripFrom = Offset.lerp(pivot, tip, 0.45)!;
    c.drawLine(
      gripFrom,
      tip,
      Paint()
        ..color = cutter ? const Color(0xFF1F4672) : const Color(0xFFB8321F)
        ..strokeWidth = math.max(2.6, h * 0.12)
        ..strokeCap = StrokeCap.round,
    );
    c.drawCircle(pivot, math.max(1.8, h * 0.045), Paint()..color = stick && stroked ? const Color(0xFF8A4E22) : _steelDark);
    if (stick && stroked) {
      final rust = Paint()..color = const Color(0xFFB4652E);
      for (final o in const [Offset(-0.6, -0.4), Offset(0.7, 0.3), Offset(0.2, -0.8), Offset(-0.3, 0.7)]) {
        c.drawCircle(pivot + Offset(o.dx * h * 0.06, o.dy * h * 0.06), math.max(0.8, h * 0.018), rust);
      }
    }
    _seal(c, s);
    _head(c, s, cutter: cutter);
    _leak(c, s);
  }

  void _batteryTool(Canvas c, Size s) {
    final w = s.width;
    final h = s.height;
    // Grip, trigger, battery pack.
    final grip = Path()
      ..moveTo(w * 0.5, h * 0.55)
      ..lineTo(w * 0.62, h * 0.55)
      ..lineTo(w * 0.7, h * 0.86)
      ..lineTo(w * 0.56, h * 0.86)
      ..close();
    c.drawPath(grip, Paint()..color = const Color(0xFF26292D));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(w * 0.49, h * 0.56, w * 0.53, h * 0.7), Radius.circular(h * 0.02)), Paint()..color = const Color(0xFF8A939B));
    final pack = Rect.fromLTRB(w * 0.46, h * 0.84, w * 0.8, h * 0.99);
    c.drawRRect(RRect.fromRectAndRadius(pack, Radius.circular(h * 0.03)), _fill(pack, const Color(0xFF3B4148), const Color(0xFF1C1F23)));
    // The charge gauge: four lights.
    final flat = flaw == HydFlaw.battery;
    for (var i = 0; i < 4; i++) {
      final on = flat ? i == 0 : i < 4;
      final col = !on ? const Color(0xFF4A4F55) : (flat ? const Color(0xFFE5483A) : const Color(0xFF4CD964));
      c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * (0.6 + i * 0.045), h * 0.885, w * 0.032, h * 0.05), Radius.circular(h * 0.01)),
        Paint()..color = col,
      );
    }
    // Body (motor + pump + cylinder).
    final body = Rect.fromLTRB(w * 0.3, h * 0.25, w * 0.9, h * 0.6);
    c.drawRRect(RRect.fromRectAndRadius(body, Radius.circular(h * 0.12)), _fill(body, const Color(0xFF2E8B74), const Color(0xFF175345)));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(w * 0.64, h * 0.29, w * 0.86, h * 0.56), Radius.circular(h * 0.08)), Paint()..color = const Color(0xFF26292D));
    for (var i = 0; i < 4; i++) {
      c.drawLine(
        Offset(w * (0.68 + i * 0.045), h * 0.33),
        Offset(w * (0.68 + i * 0.045), h * 0.52),
        Paint()
          ..color = const Color(0xFF4A4F55)
          ..strokeWidth = math.max(0.8, w * 0.008),
      );
    }
    // The release button on top.
    c.drawCircle(Offset(w * 0.5, h * 0.22), math.max(2.0, h * 0.045), Paint()..color = const Color(0xFFC9CED3));
    _seal(c, s);
    _head(c, s, cutter: false);
    _leak(c, s);
  }

  void _handCrimper(Canvas c, Size s) {
    final w = s.width;
    final h = s.height;
    // Two long handles from a small jaw: hand strength only.
    final jaw = Rect.fromLTRB(w * 0.08, h * 0.32, w * 0.3, h * 0.56);
    c.drawRRect(RRect.fromRectAndRadius(jaw, Radius.circular(h * 0.06)), _fill(jaw, const Color(0xFFB9C2CA), _steelDark));
    for (final x in [0.13, 0.19, 0.25]) {
      c.drawCircle(Offset(w * x, h * 0.44), math.max(1.0, h * 0.03), Paint()..color = const Color(0xFF2A3036));
    }
    final steel = Paint()
      ..color = _steel
      ..strokeWidth = math.max(1.6, h * 0.06)
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(w * 0.3, h * 0.38), Offset(w * 0.95, h * 0.24), steel);
    c.drawLine(Offset(w * 0.3, h * 0.5), Offset(w * 0.95, h * 0.64), steel);
    final sleeve = Paint()
      ..color = const Color(0xFFE0B23A)
      ..strokeWidth = math.max(2.4, h * 0.1)
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(w * 0.6, h * 0.31), Offset(w * 0.95, h * 0.24), sleeve);
    c.drawLine(Offset(w * 0.6, h * 0.57), Offset(w * 0.95, h * 0.64), sleeve);
    c.drawCircle(Offset(w * 0.3, h * 0.44), math.max(1.6, h * 0.04), Paint()..color = _steelDark);
  }

  void _hacksaw(Canvas c, Size s) {
    final w = s.width;
    final h = s.height;
    final frame = Path()
      ..moveTo(w * 0.06, h * 0.7)
      ..lineTo(w * 0.06, h * 0.24)
      ..lineTo(w * 0.8, h * 0.24)
      ..lineTo(w * 0.8, h * 0.7);
    c.drawPath(
      frame,
      Paint()
        ..color = const Color(0xFF3E78B8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(2.0, h * 0.07)
        ..strokeJoin = StrokeJoin.round,
    );
    // The blade with its teeth.
    c.drawRect(Rect.fromLTRB(w * 0.06, h * 0.66, w * 0.8, h * 0.72), Paint()..color = const Color(0xFFD7DCE0));
    final teeth = Path()..moveTo(w * 0.06, h * 0.72);
    for (var x = 0.06; x < 0.8; x += 0.025) {
      teeth
        ..lineTo(w * (x + 0.0125), h * 0.76)
        ..lineTo(w * (x + 0.025), h * 0.72);
    }
    c.drawPath(teeth, Paint()..color = const Color(0xFFAEB5BB));
    // The handle.
    final grip = Path()
      ..moveTo(w * 0.8, h * 0.6)
      ..quadraticBezierTo(w * 0.98, h * 0.6, w * 0.97, h * 0.86)
      ..lineTo(w * 0.86, h * 0.86)
      ..quadraticBezierTo(w * 0.86, h * 0.72, w * 0.8, h * 0.72)
      ..close();
    c.drawPath(grip, Paint()..color = const Color(0xFF26292D));
  }

  /// What the finger has not run along yet is washed out (the body only).
  void _wash(Canvas c, Size s) {
    final v = veil;
    final sn = seen;
    if (v == null || sn == null || !kind.hydraulic) return;
    final wash = Paint()..color = v.withValues(alpha: 0.55);
    final bw = s.width / kHydBins;
    for (var i = 0; i < kHydBins; i++) {
      if (!sn.contains(i)) c.drawRect(Rect.fromLTWH(bw * i - 0.5, s.height * 0.56, bw + 1, s.height * 0.44), wash);
    }
  }

  @override
  bool shouldRepaint(HydToolPainter old) =>
      old.kind != kind || old.flaw != flaw || old.veil != veil || old.stroked != stroked || old.arm != arm || !_same(old.seen, seen);

  static bool _same(Set<int>? a, Set<int>? b) {
    if (a == null || b == null) return a == b;
    return a.length == b.length && a.containsAll(b);
  }
}

/// The job, close up: a lug crimped on a cable between the hex die halves
/// ([job] crimp), or an armoured cable between the cutter's blades (cut).
/// [p]: how far the pump has brought the die / blades (0 open … 1 full);
/// [done]: full pressure reached (the release valve clicked; the cable cut).
/// [locked]: the cutter's safety lock is closed.
class HydWorkPainter extends CustomPainter {
  const HydWorkPainter({required this.job, required this.p, required this.done, required this.locked});
  final HydJob job;
  final double p;
  final bool done;
  final bool locked;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final h = s.height;
    final bg = Offset.zero & s;
    c.drawRect(bg, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3A4654), Color(0xFF26303B)]).createShader(bg));
    if (job == HydJob.crimp) {
      _crimp(c, s, w, h);
    } else {
      _cut(c, s, w, h);
    }
  }

  void _crimp(Canvas c, Size s, double w, double h) {
    final cy = h * 0.5;
    // The cable, from the right: black sheath, then bare copper into the barrel.
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(w * 0.62, cy - h * 0.13, w * 1.02, cy + h * 0.13), Radius.circular(h * 0.06)), Paint()..color = const Color(0xFF1C1E21));
    c.drawRect(Rect.fromLTRB(w * 0.56, cy - h * 0.1, w * 0.63, cy + h * 0.1), Paint()..color = const Color(0xFFC77B3A));
    // The lug: palm with its bolt hole on the left, barrel in the middle.
    final squeeze = 0.08 * p;
    final palm = RRect.fromRectAndRadius(Rect.fromLTRB(w * 0.04, cy - h * 0.08, w * 0.3, cy + h * 0.08), Radius.circular(h * 0.08));
    c.drawRRect(palm, Paint()..color = const Color(0xFFD9954A));
    c.drawCircle(Offset(w * 0.13, cy), h * 0.04, Paint()..color = const Color(0xFF26303B));
    final barrel = Rect.fromLTRB(w * 0.28, cy - h * (0.15 - squeeze), w * 0.58, cy + h * (0.15 - squeeze));
    c.drawRRect(RRect.fromRectAndRadius(barrel, Radius.circular(h * 0.05)), Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF0B46A), Color(0xFFB06A2C)]).createShader(barrel));
    if (done) {
      // The hex crimp marks pressed into the barrel.
      final mark = Paint()..color = const Color(0xFF8A4E1C);
      for (final x in [0.36, 0.5]) {
        final r = Rect.fromCenter(center: Offset(w * x, cy), width: w * 0.07, height: barrel.height * 0.92);
        c.drawRect(r, mark);
        c.drawRect(r.deflate(r.width * 0.25), Paint()..color = const Color(0xFFB06A2C));
      }
    }
    // The die halves, top and bottom, closing on the barrel.
    final gap = h * (0.32 - 0.15 * p);
    final die = Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE8C46A), Color(0xFFB0841E)]).createShader(Offset.zero & s);
    for (final top in [true, false]) {
      final k = top ? -1.0 : 1.0;
      final face = cy + k * gap;
      final back = cy + k * (gap + h * 0.2);
      final p0 = Path()
        ..moveTo(w * 0.3, face)
        ..lineTo(w * 0.56, face)
        ..lineTo(w * 0.6, back)
        ..lineTo(w * 0.26, back)
        ..close();
      c.drawPath(p0, die);
      // The head's steel jaws holding the dies.
      c.drawRect(Rect.fromLTRB(w * 0.22, top ? 0 : back, w * 0.64, top ? back : h), Paint()..color = const Color(0xFF6B757D));
      c.drawPath(p0, die);
    }
  }

  void _cut(Canvas c, Size s, double w, double h) {
    final cy = h * 0.52;
    // The armoured cable, across: black outer sheath with steel armour bands.
    final cutX = w * 0.48;
    final apart = done ? w * 0.05 : 0.0;
    for (final left in [true, false]) {
      final r = left ? Rect.fromLTRB(-4, cy - h * 0.15, cutX - apart, cy + h * 0.15) : Rect.fromLTRB(cutX + apart, cy - h * 0.15, w + 4, cy + h * 0.15);
      c.save();
      if (done) {
        c.translate(left ? 0 : 0, left ? h * 0.02 : h * 0.04);
      }
      c.drawRect(r, Paint()..color = const Color(0xFF1C1E21));
      final band = Paint()..color = const Color(0xFF59626A);
      for (var x = r.left + 6; x < r.right - 4; x += 12) {
        c.drawRect(Rect.fromLTWH(x, r.top + 2, 4, r.height - 4), band);
      }
      if (done) {
        // The clean cut face: copper cores in their insulation.
        final fx = left ? r.right : r.left;
        c.drawRect(Rect.fromLTRB(fx - 3, r.top, fx + 3, r.bottom), Paint()..color = const Color(0xFF2E3236));
        for (var i = 0; i < 3; i++) {
          c.drawCircle(Offset(fx, r.top + r.height * (0.25 + i * 0.25)), h * 0.03, Paint()..color = const Color(0xFFC77B3A));
        }
      }
      c.restore();
    }
    // The blades: closing from above and below on the cut line.
    final reach = h * (0.36 - 0.36 * p);
    final blade = Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFDDE3E8), Color(0xFF7D878F)]).createShader(Offset.zero & s);
    final upper = Path()
      ..moveTo(cutX - w * 0.14, 0)
      ..lineTo(cutX + w * 0.1, 0)
      ..quadraticBezierTo(cutX + w * 0.05, cy - reach - h * 0.06, cutX, cy - reach)
      ..quadraticBezierTo(cutX - w * 0.08, cy - reach - h * 0.1, cutX - w * 0.14, 0);
    final lower = Path()
      ..moveTo(cutX - w * 0.1, h)
      ..lineTo(cutX + w * 0.14, h)
      ..quadraticBezierTo(cutX + w * 0.08, cy + reach + h * 0.1, cutX, cy + reach)
      ..quadraticBezierTo(cutX - w * 0.05, cy + reach + h * 0.06, cutX - w * 0.1, h);
    c.drawPath(upper, blade);
    c.drawPath(lower, blade);
    // The safety lock: a latch bar across the head's mouth (left), open or shut.
    final pin = Offset(w * 0.18, h * 0.16);
    final bar = Paint()
      ..color = const Color(0xFFE0B23A)
      ..strokeWidth = h * 0.045
      ..strokeCap = StrokeCap.round;
    c.drawCircle(pin, h * 0.04, Paint()..color = const Color(0xFF8A6418));
    if (locked) {
      c.drawLine(pin, Offset(w * 0.18, h * 0.88), bar);
      c.drawCircle(Offset(w * 0.18, h * 0.88), h * 0.035, Paint()..color = const Color(0xFF8A6418));
    } else {
      c.drawLine(pin, pin + Offset(-w * 0.12, h * 0.28), bar);
    }
  }

  @override
  bool shouldRepaint(HydWorkPainter old) => old.job != job || old.p != p || old.done != done || old.locked != locked;
}
