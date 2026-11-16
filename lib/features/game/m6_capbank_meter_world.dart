import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/en_digits.dart';

// The drawn world of lesson 6.7 কাজ 2 "মিটারে ব্যাংকের নাড়ি"
// (m6_capbank_meter.dart): a 33/11 kV substation at dusk.
//
//  The yard: a dusk sky (three dealt tints), the far gantry and fence, and
//    three capacitor banks on their plinths — from the walkway they look the
//    same (cans in a steel frame, a fuse over each can, the bank's own
//    switch). Only the plinth plate (1, 2, 3) tells them apart. A tap on a
//    bank brings it close (the zoom): there a swollen can bulges with an oil
//    streak and a drip, a blown external fuse hangs open — a sound bank and a
//    weak one look exactly alike (lesson 6.7 pro tip 1: the internal fuses
//    cannot be seen from outside).
//  The control room panel: the feeder ammeter (A, 0–400) and the PF meter
//    (0.6–1.0 lag) up top, the log sheet with the A and PF strips under them
//    (the player's own pencil ticks, before and after), and each bank's
//    control switch (lamp, lever ON/OFF, the 'চালু করবেন না' tag hook).
//
// No text except labels a worker reads (scale numbers, A / PF, ON / OFF, the
// plates, the tag). Code-drawn, gradients, no bitmaps.
//
// Design: 360 wide × the scene's height; a tall phone gets bigger meters.

/// What a bank really is (dealt; the panel never says).
enum M6CbmState { healthy, weak, blown, swollen }

/// The two meters (and their log strips).
enum M6CbmMeter { amps, pf }

/// The dusk tints.
enum M6CbmSky { dusk, amber, violet }

/// The meter scales (illustrative, M6-13).
const double kM6CbmAmpMax = 400;
const double kM6CbmPfMin = 0.6;
const double kM6CbmPfMax = 1.0;

/// A value as a fraction of its scale (0 … 1).
double m6CbmFrac(M6CbmMeter m, double v) => switch (m) {
      M6CbmMeter.amps => (v / kM6CbmAmpMax).clamp(0.0, 1.0),
      M6CbmMeter.pf => ((v - kM6CbmPfMin) / (kM6CbmPfMax - kM6CbmPfMin)).clamp(0.0, 1.0),
    };

/// A fraction of the scale back to a value.
double m6CbmValue(M6CbmMeter m, double f) => switch (m) {
      M6CbmMeter.amps => f.clamp(0.0, 1.0) * kM6CbmAmpMax,
      M6CbmMeter.pf => kM6CbmPfMin + f.clamp(0.0, 1.0) * (kM6CbmPfMax - kM6CbmPfMin),
    };

/// How a reading is written in the log (English digits).
String m6CbmReading(M6CbmMeter m, double v) => enDigits(m == M6CbmMeter.amps ? '${v.round()}' : v.toStringAsFixed(2));

/// Where things are (design px, 360 wide).
@immutable
class M6CbmGeo {
  const M6CbmGeo._(this.height);

  factory M6CbmGeo.forScene(double height, double inset) => M6CbmGeo._(height - inset * 0.5);

  final double height;

  /// Under the header.
  static const double top = 136;

  /// Extra meter height on a tall phone.
  double get stretch => ((height - 700) / 200).clamp(0.0, 1.0) * 56;

  // --- the panel ---------------------------------------------------------------
  Rect meter(M6CbmMeter m) => m == M6CbmMeter.amps ? Rect.fromLTWH(14, top, 160, 104 + stretch) : Rect.fromLTWH(186, top, 160, 104 + stretch);

  /// The dial's pivot and radius in a meter face.
  Offset pivot(M6CbmMeter m) {
    final r = meter(m);
    return Offset(r.center.dx, r.bottom - 16);
  }

  double dialR(M6CbmMeter m) {
    final r = meter(m);
    return math.min(r.width / 2 - 16, r.height - 38);
  }

  /// The dial sweeps from 200° to 340° (screen angles, y down).
  static const double a0 = math.pi * 200 / 180;
  static const double a1 = math.pi * 340 / 180;
  static double angle(double f) => a0 + (a1 - a0) * f.clamp(0.0, 1.0);

  /// The log sheet.
  Rect get log => Rect.fromLTWH(10, meter(M6CbmMeter.amps).bottom + 6, 340, 88);

  static const double stripX0 = 44;
  static const double stripX1 = 324;

  /// A strip's ruler (the ticks sit on its middle line).
  Rect strip(M6CbmMeter m) => Rect.fromLTRB(stripX0, log.top + (m == M6CbmMeter.amps ? 18 : 54), stripX1, log.top + (m == M6CbmMeter.amps ? 44 : 80));

  /// Where a strip takes the pencil.
  Rect stripHit(M6CbmMeter m) => Rect.fromLTRB(stripX0 - 14, strip(m).top - 6, stripX1 + 14, strip(m).bottom + 4);

  /// The x of a value on a strip, and back.
  double stripXOf(M6CbmMeter m, double v) => stripX0 + m6CbmFrac(m, v) * (stripX1 - stripX0);
  double valueAtX(M6CbmMeter m, double x) => m6CbmValue(m, (x - stripX0) / (stripX1 - stripX0));

  /// The strip a touch is on (null: neither).
  M6CbmMeter? stripAt(Offset p) {
    for (final m in M6CbmMeter.values) {
      if (stripHit(m).contains(p)) return m;
    }
    return null;
  }

  /// The switch band: three columns (lamp, lever, tag hook).
  double get bandTop => log.bottom + 6;
  static double colX(int i) => 50.0 + 80 * i;
  Offset lamp(int i) => Offset(colX(i), bandTop + 7);
  Rect leverHit(int i) => Rect.fromLTWH(colX(i) - 24, bandTop + 14, 48, 48);
  Rect tagHit(int i) => Rect.fromLTWH(colX(i) - 24, bandTop + 64, 48, 42);
  double get bandBottom => bandTop + 108;

  /// The pencil at rest (right of the log).
  Offset get pencilRest => Offset(stripX1 + 12, log.top + 8);

  // --- the yard -----------------------------------------------------------------
  /// The banks stand clear of the guide and his bubble.
  double get yardBottom => height >= 700 ? math.min(height - 250, 480) : height - 205;
  double get groundY => yardBottom - 18;
  Rect bank(int i) => Rect.fromLTRB(48 + 104.0 * i, 196, 140 + 104.0 * i, yardBottom);

  /// The bank a touch is on (null: none).
  int? bankAt(Offset p) {
    for (var i = 0; i < 3; i++) {
      if (bank(i).contains(p)) return i;
    }
    return null;
  }

  Rect get trainee => Rect.fromLTWH(2, yardBottom - 100, 42, 100);

  /// Where a deadly burst comes off (the swollen can, close up).
  Offset get flashAt => Offset(180, (top + yardBottom) / 2);

  /// The current bank's lever and tag hook together (the decision's sweep).
  Rect column(int i) => leverHit(i).expandToInclude(tagHit(i));

  @override
  bool operator ==(Object other) => other is M6CbmGeo && other.height == height;

  @override
  int get hashCode => height.hashCode;
}

/// What the switch band shows now.
@immutable
class M6CbmPanelRig {
  const M6CbmPanelRig({required this.on, required this.tagged, required this.current, required this.sky});
  final List<bool> on;
  final List<bool> tagged;

  /// The bank being worked (its column is lit).
  final int current;
  final M6CbmSky sky;

  @override
  bool operator ==(Object other) =>
      other is M6CbmPanelRig && _same(other.on, on) && _same(other.tagged, tagged) && other.current == current && other.sky == sky;

  @override
  int get hashCode => Object.hash(Object.hashAll(on), Object.hashAll(tagged), current, sky);
}

bool _same(List<bool> a, List<bool> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// The log's ticks and the pencil.
@immutable
class M6CbmLogRig {
  const M6CbmLogRig({required this.bank, this.before = const {}, this.after = const {}, this.pencilX, this.pencilOn});
  final int bank;
  final Map<M6CbmMeter, double> before;
  final Map<M6CbmMeter, double> after;

  /// The pencil in hand over a strip (null: at rest).
  final double? pencilX;
  final M6CbmMeter? pencilOn;

  @override
  bool operator ==(Object other) =>
      other is M6CbmLogRig &&
      other.bank == bank &&
      _sameMap(other.before, before) &&
      _sameMap(other.after, after) &&
      other.pencilX == pencilX &&
      other.pencilOn == pencilOn;

  @override
  int get hashCode => Object.hash(bank, Object.hashAll(before.values), Object.hashAll(after.values), pencilX, pencilOn);
}

bool _sameMap(Map<M6CbmMeter, double> a, Map<M6CbmMeter, double> b) {
  if (a.length != b.length) return false;
  for (final e in a.entries) {
    if (b[e.key] != e.value) return false;
  }
  return true;
}

TextPainter _label(String s, double size, Color c, {FontWeight w = FontWeight.w800}) => TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontSize: size, fontWeight: w, color: c, height: 1)),
      textDirection: TextDirection.ltr,
    )..layout();

void _text(Canvas c, String s, Offset centre, double size, Color col, {FontWeight w = FontWeight.w800}) {
  final tp = _label(s, size, col, w: w);
  tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
}

List<Color> _skyOf(M6CbmSky s) => switch (s) {
      M6CbmSky.dusk => const [Color(0xFF1C2A4E), Color(0xFF5A4A78), Color(0xFFE08A5A)],
      M6CbmSky.amber => const [Color(0xFF22304F), Color(0xFF8A5A5A), Color(0xFFF2A24E)],
      M6CbmSky.violet => const [Color(0xFF161E3C), Color(0xFF4A3A6E), Color(0xFFC07A8A)],
    };

// ============================================================================
// The yard
// ============================================================================

class M6CbmYardPainter extends CustomPainter {
  const M6CbmYardPainter({required this.geo, required this.sky});
  final M6CbmGeo geo;
  final M6CbmSky sky;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    final g = geo.groundY;
    final cols = _skyOf(sky);
    c.drawRect(
      Rect.fromLTWH(0, 0, w, g),
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: cols, stops: const [0, 0.6, 1]).createShader(Rect.fromLTWH(0, 0, w, g)),
    );
    // The low sun behind the gantry.
    c.drawCircle(Offset(w * 0.78, g - 34), 22, Paint()..color = const Color(0x66FFE2A0));
    c.drawCircle(Offset(w * 0.78, g - 34), 14, Paint()..color = const Color(0xCCFFD58A));
    // The far gantry (33 kV) and the fence.
    final steel = Paint()
      ..color = const Color(0xFF2A3346)
      ..strokeWidth = 3;
    final thin = Paint()
      ..color = const Color(0xFF2A3346)
      ..strokeWidth = 1.4;
    final gy = 150.0;
    for (final x in [24.0, 180.0, 336.0]) {
      c.drawLine(Offset(x, g - 8), Offset(x, gy), steel);
    }
    c.drawLine(Offset(16, gy), Offset(344, gy), steel);
    c.drawLine(Offset(16, gy + 12), Offset(344, gy + 12), thin);
    for (var x = 30.0; x < 340; x += 26) {
      c.drawLine(Offset(x, gy), Offset(x + 13, gy + 12), thin);
      c.drawLine(Offset(x + 13, gy + 12), Offset(x + 26, gy), thin);
    }
    for (final x in [60.0, 120.0, 240.0, 300.0]) {
      c.drawLine(Offset(x, gy + 12), Offset(x, gy + 26), thin);
      c.drawCircle(Offset(x, gy + 28), 2.4, Paint()..color = const Color(0xFF8D96A8));
    }
    // Ground and gravel.
    c.drawRect(
      Rect.fromLTWH(0, g, w, h - g),
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF4A4A50), Color(0xFF26262C)]).createShader(Rect.fromLTWH(0, g, w, h - g)),
    );
    final dot = Paint()..color = const Color(0x33FFFFFF);
    final rnd = math.Random(7);
    for (var i = 0; i < 140; i++) {
      c.drawCircle(Offset(rnd.nextDouble() * w, g + 4 + rnd.nextDouble() * (h - g - 4)), 0.9, dot);
    }
    // The fence along the yard.
    final fence = Paint()
      ..color = const Color(0xFF59627A)
      ..strokeWidth = 1;
    final fy = g - 26;
    c.drawLine(Offset(0, fy), Offset(w, fy), fence);
    for (var x = 0.0; x < w; x += 9) {
      c.drawLine(Offset(x, fy), Offset(x + 9, g), fence);
      c.drawLine(Offset(x + 9, fy), Offset(x, g), fence);
    }
    // The three banks (alike from here).
    for (var i = 0; i < 3; i++) {
      _bankFar(c, geo.bank(i), i);
    }
  }

  void _bankFar(Canvas c, Rect r, int i) {
    // Plinth.
    final plinth = Rect.fromLTRB(r.left - 4, r.bottom - 24, r.right + 4, r.bottom);
    c.drawRRect(RRect.fromRectAndRadius(plinth, const Radius.circular(2)), Paint()..color = const Color(0xFF8C8A84));
    c.drawRect(Rect.fromLTRB(plinth.left, plinth.top, plinth.right, plinth.top + 3), Paint()..color = const Color(0xFFB4B1A8));
    // Its plate.
    final plate = Rect.fromCenter(center: plinth.center, width: 26, height: 15);
    c.drawRRect(RRect.fromRectAndRadius(plate, const Radius.circular(2)), Paint()..color = const Color(0xFFF2EEDC));
    _text(c, '${i + 1}', plate.center, 11, const Color(0xFF1B2230), w: FontWeight.w900);
    // Steel frame.
    final frame = Rect.fromLTRB(r.left + 4, r.top + 30, r.right - 4, plinth.top);
    final steel = Paint()
      ..color = const Color(0xFF6E7888)
      ..strokeWidth = 3;
    c.drawLine(frame.topLeft, frame.bottomLeft, steel);
    c.drawLine(frame.topRight, frame.bottomRight, steel);
    c.drawLine(Offset(frame.left, frame.top + frame.height * 0.55), Offset(frame.right, frame.top + frame.height * 0.55), steel);
    // Cans: two rows of three.
    final cw = (frame.width - 12) / 3;
    for (var row = 0; row < 2; row++) {
      final top = row == 0 ? frame.top + 10 : frame.top + frame.height * 0.55 + 4;
      final bottom = row == 0 ? frame.top + frame.height * 0.55 - 2 : frame.bottom - 4;
      for (var k = 0; k < 3; k++) {
        final can = Rect.fromLTWH(frame.left + 3 + k * (cw + 3), top, cw, bottom - top);
        c.drawRRect(
          RRect.fromRectAndRadius(can, const Radius.circular(3)),
          Paint()..shader = const LinearGradient(colors: [Color(0xFFB9C1CB), Color(0xFF8792A0)]).createShader(can),
        );
        c.drawLine(Offset(can.center.dx, can.top), Offset(can.center.dx, can.top - 5), Paint()..color = const Color(0xFF6B4A2E)..strokeWidth = 2);
      }
    }
    // Fuses over the frame and the incoming bus.
    final bus = Paint()
      ..color = const Color(0xFFC9A44A)
      ..strokeWidth = 1.6;
    c.drawLine(Offset(r.left, r.top + 8), Offset(r.right, r.top + 8), bus);
    for (var k = 0; k < 3; k++) {
      final x = frame.left + 3 + k * (cw + 3) + cw / 2;
      c.drawLine(Offset(x, r.top + 8), Offset(x, r.top + 26), Paint()..color = const Color(0xFF3A3F48)..strokeWidth = 3);
    }
  }

  @override
  bool shouldRepaint(M6CbmYardPainter old) => old.geo != geo || old.sky != sky;
}

/// A bank close up (the zoom): its six cans, a fuse over each, its own
/// switch. [defect] is the can (swollen) or the fuse (blown) that is bad.
class M6CbmZoomPainter extends CustomPainter {
  const M6CbmZoomPainter({required this.state, required this.defect, required this.bank});
  final M6CbmState state;
  final int defect;
  final int bank;

  @override
  void paint(Canvas c, Size s) {
    final r = Offset.zero & s;
    c.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(14)),
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3A4A6E), Color(0xFF6A5A7A), Color(0xFF3A3A40)], stops: [0, 0.55, 0.56]).createShader(r),
    );
    final w = s.width;
    final h = s.height;
    // Plinth and plate.
    final plinth = Rect.fromLTRB(w * 0.08, h * 0.86, w * 0.92, h * 0.97);
    c.drawRect(plinth, Paint()..color = const Color(0xFF8C8A84));
    final plate = Rect.fromCenter(center: plinth.center, width: 34, height: 18);
    c.drawRRect(RRect.fromRectAndRadius(plate, const Radius.circular(2)), Paint()..color = const Color(0xFFF2EEDC));
    _text(c, '${bank + 1}', plate.center, 13, const Color(0xFF1B2230), w: FontWeight.w900);
    // Frame.
    final frame = Rect.fromLTRB(w * 0.24, h * 0.30, w * 0.90, plinth.top);
    final steel = Paint()
      ..color = const Color(0xFF6E7888)
      ..strokeWidth = 5;
    c.drawLine(frame.topLeft, frame.bottomLeft, steel);
    c.drawLine(frame.topRight, frame.bottomRight, steel);
    final mid = frame.top + frame.height * 0.52;
    c.drawLine(Offset(frame.left, mid), Offset(frame.right, mid), steel);
    // The bank's own switch (left), with its operating rod.
    final sw = Rect.fromLTWH(w * 0.05, h * 0.36, w * 0.13, h * 0.22);
    c.drawRRect(RRect.fromRectAndRadius(sw, const Radius.circular(4)), Paint()..color = const Color(0xFF59627A));
    c.drawRRect(RRect.fromRectAndRadius(sw.deflate(4), const Radius.circular(3)), Paint()..color = const Color(0xFF7D879C));
    c.drawLine(Offset(sw.center.dx, sw.bottom), Offset(sw.center.dx, plinth.top), Paint()..color = const Color(0xFF3A3F48)..strokeWidth = 3);
    // The incoming bus over the fuses.
    final busY = h * 0.10;
    c.drawLine(Offset(sw.center.dx, sw.top), Offset(sw.center.dx, busY), Paint()..color = const Color(0xFFC9A44A)..strokeWidth = 2.4);
    c.drawLine(Offset(sw.center.dx, busY), Offset(frame.right, busY), Paint()..color = const Color(0xFFC9A44A)..strokeWidth = 2.4);
    // Cans: two rows of three; the fuses feed the top row's three phases.
    final cw = (frame.width - 24) / 3;
    for (var row = 0; row < 2; row++) {
      final top = row == 0 ? frame.top + 14 : mid + 8;
      final bottom = row == 0 ? mid - 6 : frame.bottom - 6;
      for (var k = 0; k < 3; k++) {
        final can = Rect.fromLTWH(frame.left + 6 + k * (cw + 6), top, cw, bottom - top);
        final swollen = state == M6CbmState.swollen && row == 0 && k == defect;
        _can(c, can, swollen);
      }
    }
    for (var k = 0; k < 3; k++) {
      final x = frame.left + 6 + k * (cw + 6) + cw / 2;
      final blown = state == M6CbmState.blown && k == defect;
      _fuse(c, Offset(x, busY), Offset(x, frame.top + 8), blown);
    }
  }

  void _can(Canvas c, Rect can, bool swollen) {
    final body = Path();
    if (swollen) {
      // Bulged sides and a domed lid.
      final b = can.width * 0.18;
      body
        ..moveTo(can.left, can.top + 6)
        ..quadraticBezierTo(can.center.dx, can.top - 8, can.right, can.top + 6)
        ..quadraticBezierTo(can.right + b, can.center.dy, can.right, can.bottom)
        ..lineTo(can.left, can.bottom)
        ..quadraticBezierTo(can.left - b, can.center.dy, can.left, can.top + 6)
        ..close();
    } else {
      body.addRRect(RRect.fromRectAndRadius(can, const Radius.circular(4)));
    }
    c.drawPath(body, Paint()..shader = const LinearGradient(colors: [Color(0xFFD4DAE2), Color(0xFF8E99A8)]).createShader(can.inflate(8)));
    c.drawPath(body, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0xFF5A6474));
    // Bushings.
    for (final f in [0.32, 0.68]) {
      final x = can.left + can.width * f;
      final bt = can.top - (swollen ? 10 : 2);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 4, bt - 12, 8, 12), const Radius.circular(2)), Paint()..color = const Color(0xFF7A4A2A));
    }
    if (swollen) {
      // The oil streak and the drip on the plinth.
      final oil = Paint()..color = const Color(0xCC5A3A12);
      final streak = Path()
        ..moveTo(can.right - can.width * 0.30, can.top + 10)
        ..quadraticBezierTo(can.right - can.width * 0.18, can.center.dy, can.right - can.width * 0.26, can.bottom)
        ..lineTo(can.right - can.width * 0.36, can.bottom)
        ..quadraticBezierTo(can.right - can.width * 0.28, can.center.dy, can.right - can.width * 0.38, can.top + 10)
        ..close();
      c.drawPath(streak, oil);
      c.drawOval(Rect.fromCenter(center: Offset(can.right - can.width * 0.3, can.bottom + 4), width: can.width * 0.6, height: 5), oil);
    }
  }

  void _fuse(Canvas c, Offset top, Offset bottom, bool blown) {
    final holder = Paint()
      ..color = const Color(0xFF3A3F48)
      ..strokeWidth = 3;
    // Insulators at both ends.
    for (final p in [top.translate(0, 8), bottom.translate(0, -8)]) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: p, width: 10, height: 12), const Radius.circular(3)), Paint()..color = const Color(0xFF7A4A2A));
    }
    final a = top.translate(0, 16);
    final b = bottom.translate(0, -16);
    if (!blown) {
      c.drawLine(a, b, holder);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(a.dx, (a.dy + b.dy) / 2), width: 9, height: (b.dy - a.dy) * 0.7), const Radius.circular(3)), Paint()..color = const Color(0xFF2C2F36));
      return;
    }
    // The tube dropped open, swinging from its lower hinge; the link's tail out.
    final len = (b.dy - a.dy) * 0.9;
    final tip = b + Offset(math.cos(-math.pi / 2 + 0.9), math.sin(-math.pi / 2 + 0.9)) * len;
    c.drawLine(b, tip, Paint()
      ..color = const Color(0xFF2C2F36)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round);
    c.drawLine(tip, tip + const Offset(10, 12), Paint()
      ..color = const Color(0xFFB0B4BA)
      ..strokeWidth = 1.4);
    c.drawCircle(a, 3, Paint()..color = const Color(0xFF3A3F48));
  }

  @override
  bool shouldRepaint(M6CbmZoomPainter old) => old.state != state || old.defect != defect || old.bank != bank;
}

// ============================================================================
// The panel
// ============================================================================

class M6CbmPanelPainter extends CustomPainter {
  const M6CbmPanelPainter({required this.geo, required this.rig});
  final M6CbmGeo geo;
  final M6CbmPanelRig rig;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    // The control room wall, the window at dusk.
    c.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF2A3140));
    final win = Rect.fromLTWH(0, 0, w, M6CbmGeo.top - 6);
    c.drawRect(win, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: _skyOf(rig.sky)).createShader(win));
    // The panel face.
    final face = Rect.fromLTRB(4, M6CbmGeo.top - 6, w - 4, h);
    c.drawRect(
      face,
      Paint()..shader = const LinearGradient(colors: [Color(0xFFCDD3D9), Color(0xFFAEB6BE)]).createShader(face),
    );
    for (final m in M6CbmMeter.values) {
      _meterFace(c, m);
    }
    _logSheet(c);
    _switches(c);
  }

  void _meterFace(Canvas c, M6CbmMeter m) {
    final r = geo.meter(m);
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(6)), Paint()..color = const Color(0xFF26303D));
    final dial = r.deflate(5);
    c.drawRRect(RRect.fromRectAndRadius(dial, const Radius.circular(4)), Paint()..color = const Color(0xFFF7F3E6));
    final p = geo.pivot(m);
    final rad = geo.dialR(m);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = const Color(0xFF26303D);
    c.drawArc(Rect.fromCircle(center: p, radius: rad), M6CbmGeo.a0, M6CbmGeo.a1 - M6CbmGeo.a0, false, arc);
    final major = m == M6CbmMeter.amps ? 4 : 4;
    final minor = 5;
    for (var i = 0; i <= major * minor; i++) {
      final f = i / (major * minor);
      final a = M6CbmGeo.angle(f);
      final big = i % minor == 0;
      final d = Offset(math.cos(a), math.sin(a));
      c.drawLine(p + d * rad, p + d * (rad - (big ? 9 : 5)), Paint()
        ..color = const Color(0xFF26303D)
        ..strokeWidth = big ? 1.6 : 1);
      if (big) {
        final v = m6CbmValue(m, f);
        final s = m == M6CbmMeter.amps ? '${v.round()}' : v.toStringAsFixed(1);
        _text(c, enDigits(s), p + d * (rad - 18), 9.5, const Color(0xFF26303D));
      }
    }
    _text(c, m == M6CbmMeter.amps ? 'A' : 'PF', Offset(p.dx, p.dy - rad * 0.42), 13, const Color(0xFF8A2A16), w: FontWeight.w900);
    if (m == M6CbmMeter.pf) _text(c, 'LAG', Offset(p.dx, p.dy - rad * 0.42 + 13), 7.5, const Color(0xFF59627A));
    c.drawCircle(p, 5, Paint()..color = const Color(0xFF26303D));
  }

  void _logSheet(Canvas c) {
    final r = geo.log;
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)), Paint()..color = const Color(0xFFF7F1DE));
    c.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(4)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFF8A6A3C),
    );
    for (final m in M6CbmMeter.values) {
      final s = geo.strip(m);
      final y = s.center.dy;
      final ink = Paint()
        ..color = const Color(0xFF5A6474)
        ..strokeWidth = 1.2;
      c.drawLine(Offset(s.left, y), Offset(s.right, y), ink);
      for (var i = 0; i <= 20; i++) {
        final f = i / 20;
        final x = s.left + f * s.width;
        final big = i % 5 == 0;
        c.drawLine(Offset(x, y - (big ? 6 : 3)), Offset(x, y + (big ? 6 : 3)), ink);
        if (big) {
          final v = m6CbmValue(m, f);
          _text(c, enDigits(m == M6CbmMeter.amps ? '${v.round()}' : v.toStringAsFixed(1)), Offset(x, s.bottom + 1), 7.5, const Color(0xFF5A6474));
        }
      }
      _text(c, m == M6CbmMeter.amps ? 'A' : 'PF', Offset(r.left + 16, y), 11, const Color(0xFF3A2A16), w: FontWeight.w900);
    }
  }

  void _switches(Canvas c) {
    final band = Rect.fromLTRB(14, geo.bandTop, 250, geo.bandBottom);
    c.drawRRect(RRect.fromRectAndRadius(band, const Radius.circular(6)), Paint()..color = const Color(0xFF9AA3AD));
    for (var i = 0; i < 3; i++) {
      final x = M6CbmGeo.colX(i);
      final cur = i == rig.current;
      final col = Rect.fromLTRB(x - 32, geo.bandTop + 2, x + 32, geo.bandBottom - 2);
      c.drawRRect(RRect.fromRectAndRadius(col, const Radius.circular(5)), Paint()..color = cur ? const Color(0xFFBFC7D0) : const Color(0xFFA6AFB9));
      // ON lamp (red) lit while the bank is in.
      final lamp = geo.lamp(i);
      c.drawCircle(lamp, 6, Paint()..color = const Color(0xFF3A4048));
      c.drawCircle(lamp, 4.5, Paint()..color = rig.on[i] ? const Color(0xFFFF5A4E) : const Color(0xFF6A3A38));
      _text(c, '${i + 1}', lamp.translate(-22, 0), 10, const Color(0xFF1B2230), w: FontWeight.w900);
      // The lever: up = ON, down = OFF.
      final lv = geo.leverHit(i);
      final plate = Rect.fromCenter(center: lv.center, width: 30, height: 44);
      c.drawRRect(RRect.fromRectAndRadius(plate, const Radius.circular(4)), Paint()..color = const Color(0xFF2C3440));
      _text(c, 'ON', Offset(plate.right + 10, plate.top + 6), 7.5, const Color(0xFF1B2230));
      _text(c, 'OFF', Offset(plate.right + 11, plate.bottom - 6), 7.5, const Color(0xFF1B2230));
      final up = rig.on[i];
      final knob = Offset(plate.center.dx, up ? plate.top + 9 : plate.bottom - 9);
      c.drawLine(plate.center, knob, Paint()
        ..color = const Color(0xFFD0D6DC)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round);
      c.drawCircle(knob, 7, Paint()..color = const Color(0xFFE8ECEF));
      // The tag hook; the tag hangs on the lever once given.
      final th = geo.tagHit(i);
      if (rig.tagged[i]) {
        _tag(c, Offset(plate.center.dx, plate.bottom - 2), hung: true);
        c.drawLine(Offset(th.center.dx - 8, th.top + 10), Offset(th.center.dx + 8, th.top + 10), Paint()
          ..color = const Color(0xFF3A3F48)
          ..strokeWidth = 2.4);
      } else {
        c.drawLine(Offset(th.center.dx - 8, th.top + 6), Offset(th.center.dx + 8, th.top + 6), Paint()
          ..color = const Color(0xFF3A3F48)
          ..strokeWidth = 2.4);
        _tag(c, Offset(th.center.dx, th.top + 6), hung: false);
      }
    }
  }

  void _tag(Canvas c, Offset hook, {required bool hung}) {
    final r = Rect.fromLTWH(hook.dx - 14, hook.dy + 6, 28, hung ? 30 : 30);
    c.drawLine(hook, Offset(r.center.dx, r.top), Paint()
      ..color = const Color(0xFF3A3F48)
      ..strokeWidth = 1.2);
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), Paint()..color = const Color(0xFFD7332A));
    c.drawRRect(RRect.fromRectAndRadius(r.deflate(2), const Radius.circular(2)), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFFFFE0D8));
    final tp = TextPainter(
      text: const TextSpan(text: 'চালু\nকরবেন\nনা', style: TextStyle(fontSize: 6.5, height: 1.1, fontWeight: FontWeight.w900, color: Colors.white)),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: r.width);
    tp.paint(c, Offset(r.center.dx - tp.width / 2, r.center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(M6CbmPanelPainter old) => old.geo != geo || old.rig != rig;
}

/// The two needles (each moves only while its value changes).
class M6CbmNeedlePainter extends CustomPainter {
  const M6CbmNeedlePainter({required this.geo, required this.meter, required this.value});
  final M6CbmGeo geo;
  final M6CbmMeter meter;
  final double value;

  @override
  void paint(Canvas c, Size size) {
    final p = geo.pivot(meter);
    final a = M6CbmGeo.angle(m6CbmFrac(meter, value));
    final tip = p + Offset(math.cos(a), math.sin(a)) * (geo.dialR(meter) - 4);
    c.drawLine(p, tip, Paint()
      ..color = const Color(0xFFC0392B)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round);
    c.drawCircle(p, 3.5, Paint()..color = const Color(0xFFC0392B));
  }

  @override
  bool shouldRepaint(M6CbmNeedlePainter old) => old.value != value || old.geo != geo || old.meter != meter;
}

/// The player's ticks on the log and the pencil.
class M6CbmLogPainter extends CustomPainter {
  const M6CbmLogPainter({required this.geo, required this.rig});
  final M6CbmGeo geo;
  final M6CbmLogRig rig;

  @override
  void paint(Canvas c, Size size) {
    for (final m in M6CbmMeter.values) {
      final s = geo.strip(m);
      final b = rig.before[m];
      final a = rig.after[m];
      if (b != null) _tick(c, m, b, s, above: true, ink: const Color(0xFF59627A));
      if (a != null) _tick(c, m, a, s, above: false, ink: const Color(0xFF1B2230));
    }
    final on = rig.pencilOn;
    final x = rig.pencilX;
    final tipAt = on != null && x != null ? Offset(x.clamp(M6CbmGeo.stripX0, M6CbmGeo.stripX1), geo.strip(on).center.dy) : geo.pencilRest;
    _pencil(c, tipAt, inHand: on != null);
  }

  void _tick(Canvas c, M6CbmMeter m, double v, Rect s, {required bool above, required Color ink}) {
    final x = geo.stripXOf(m, v);
    final y = s.center.dy;
    c.drawLine(Offset(x, y - 9), Offset(x, y + 9), Paint()
      ..color = ink
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round);
    // The written figure: before above the line, after below it.
    final tp = _label(m6CbmReading(m, v), 8.5, ink, w: FontWeight.w900);
    final dy = above ? s.top - 9 - tp.height / 2 + 4 : s.bottom + 9 - tp.height / 2 - 2;
    final dx = (x - tp.width / 2).clamp(s.left - 10, s.right - tp.width + 10);
    c.drawRect(Rect.fromLTWH(dx - 1, dy - 1, tp.width + 2, tp.height + 2), Paint()..color = const Color(0xFFF7F1DE));
    tp.paint(c, Offset(dx, dy));
  }

  void _pencil(Canvas c, Offset tip, {required bool inHand}) {
    c.save();
    c.translate(tip.dx, tip.dy);
    c.rotate(inHand ? -0.5 : -0.9);
    final body = Rect.fromLTWH(-3, -44, 6, 34);
    c.drawRect(body, Paint()..color = const Color(0xFFF2B33D));
    c.drawRect(Rect.fromLTWH(-3, -50, 6, 6), Paint()..color = const Color(0xFFE88A8A));
    final cone = Path()
      ..moveTo(-3, -10)
      ..lineTo(3, -10)
      ..lineTo(0, 0)
      ..close();
    c.drawPath(cone, Paint()..color = const Color(0xFFE8C8A0));
    c.drawCircle(Offset.zero, 1.4, Paint()..color = const Color(0xFF2A2A2A));
    c.restore();
  }

  @override
  bool shouldRepaint(M6CbmLogPainter old) => old.rig != rig || old.geo != geo;
}

/// The deadly burst: a can splits, a flash and a crackle in colour over the
/// grey scene.
class M6CbmFlashPainter extends CustomPainter {
  const M6CbmFlashPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final k = Curves.easeOut.transform(v.clamp(0.0, 1.0));
    c.drawCircle(at, 30 + 110 * k, Paint()..color = Color.fromRGBO(255, 230, 140, 0.55 * (1 - k * 0.6)));
    c.drawCircle(at, 14 + 40 * k, Paint()..color = Color.fromRGBO(255, 255, 255, 0.85 * (1 - k * 0.5)));
    final bolt = Paint()
      ..color = const Color(0xFF8FD8FF)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final rnd = math.Random(11);
    for (var i = 0; i < 7; i++) {
      final a = i * math.pi * 2 / 7 + 0.3;
      var p = at;
      for (var j = 0; j < 4; j++) {
        final q = p + Offset(math.cos(a + rnd.nextDouble() - 0.5), math.sin(a + rnd.nextDouble() - 0.5)) * (14 + 18 * k);
        c.drawLine(p, q, bolt);
        p = q;
      }
    }
  }

  @override
  bool shouldRepaint(M6CbmFlashPainter old) => old.v != v || old.at != at;
}
