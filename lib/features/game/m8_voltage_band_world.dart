import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/en_digits.dart';

// The drawn world of lesson 8.4 কাজ 2 "ভোল্টেজ সীমায় রাখো"
// (m8_voltage_band.dart): the substation's control panel, seen from the
// operator's chair.
//
//  Top: a window on the yard (the power transformer, an LA on the 11 kV
//    structure with its insulators, a far village pump) and a wall clock
//    (decor).
//  The bus voltmeter: an analog dial with plain kV numerals and uniform
//    ticks — no coloured band, no mark on the declared value (the player
//    must know the limits: lesson 8.4, +6 % / -9 %).
//  The OLTC panel: the tap position digit between two hold buttons, RAISE
//    and LOWER (identical apart from the labels).
//  The capacitor bank breaker: ON / OFF lamps and a twist switch.
//  The shift log: a notebook with a pen (the pen tap writes the round's
//    entry) and the entries written so far.
//
// No text except what a worker reads (numerals, kV, RAISE / LOWER, ON / OFF,
// OLTC, the log header). Code-drawn, gradients, no bitmaps.
//
// Design: 360 wide × the scene's height; a tall phone gets a bigger dial.

/// The two bus voltages a play can use.
enum M8VbBus { kv11, kv33 }

extension M8VbBusX on M8VbBus {
  /// The declared value (kV).
  double get nominal => this == M8VbBus.kv11 ? 11 : 33;

  /// One OLTC step (about 1.5 % of nominal, ruling M8-12).
  double get step => nominal * 0.015;

  /// What the capacitor bank adds when it goes ON (a little, illustrative).
  double get capRise => nominal * 0.012;

  /// The lowest and highest allowed (lesson 8.4: not more than 6 % up, not
  /// more than 9 % down).
  double get lo => nominal * 0.91;
  double get hi => nominal * 1.06;

  String get label => enDigits('${nominal.round()} kV');
}

/// The dial runs from 80 % to 120 % of the declared value.
double m8VbFrac(M8VbBus b, double kv) => ((kv - b.nominal * 0.8) / (b.nominal * 0.4)).clamp(0.0, 1.0);

/// How a reading is written in the log (English digits, one decimal).
String m8VbReading(double kv) => enDigits(kv.toStringAsFixed(1));

/// The consequence a slip shows after the log.
enum M8VbInset { high, low }

/// Where things are (design px, 360 wide).
@immutable
class M8VbGeo {
  const M8VbGeo._(this.height);

  factory M8VbGeo.forScene(double height, double inset) => M8VbGeo._(height - inset * 0.5);

  final double height;

  /// Under the header.
  static const double top = 132;

  /// Extra dial height on a tall phone.
  double get stretch => ((height - 700) / 200).clamp(0.0, 1.0) * 56;

  Rect get window => Rect.fromLTWH(14, top, 262, 54 + stretch * 0.3);
  Offset get clock => Offset(318, window.center.dy);

  Rect get meter => Rect.fromLTWH(14, window.bottom + 6, 332, 128 + stretch * 0.55);
  Offset get pivot => Offset(meter.center.dx, meter.bottom - 14);
  double get dialR => math.min(meter.width / 2 - 38, meter.height - 36);

  /// The dial sweeps from 190° to 350° (screen angles, y down).
  static const double a0 = math.pi * 190 / 180;
  static const double a1 = math.pi * 350 / 180;
  static double angle(double f) => a0 + (a1 - a0) * f.clamp(0.0, 1.0);

  /// The OLTC panel: the digit between RAISE and LOWER.
  Rect get oltc => Rect.fromLTWH(14, meter.bottom + 6, 332, 54);
  Rect get raise => Rect.fromLTWH(24, oltc.top + 3, 108, 48);
  Rect get lower => Rect.fromLTWH(228, oltc.top + 3, 108, 48);
  Rect get tapBox => Rect.fromLTWH(140, oltc.top + 4, 80, 46);

  /// The capacitor bank breaker (the twist switch takes the whole box).
  Rect get cap => Rect.fromLTWH(14, oltc.bottom + 6, 126, 66);

  /// The shift log; the pen lies on it (a tap anywhere on the book writes).
  Rect get book => Rect.fromLTWH(148, oltc.bottom + 6, 102, 66);
  Rect get pen => book;

  /// The four controls together (the hint's sweep reads their keys).
  List<Rect> get controls => [raise, lower, cap, pen];

  /// The inset's frame (the consequence close-up).
  Rect get insetBox => Rect.fromLTWH(24, top + 8, 312, math.min(height - 330, 250));

  @override
  bool operator ==(Object other) => other is M8VbGeo && other.height == height;

  @override
  int get hashCode => height.hashCode;
}

/// What the panel shows now.
@immutable
class M8VbRig {
  const M8VbRig({required this.bus, required this.tap, required this.capOn, required this.entries, required this.current});
  final M8VbBus bus;

  /// The tap position digit.
  final int tap;
  final bool capOn;

  /// The log entries written so far (null: not yet).
  final List<double?> entries;
  final int current;

  @override
  bool operator ==(Object other) =>
      other is M8VbRig && other.bus == bus && other.tap == tap && other.capOn == capOn && other.current == current && _same(other.entries, entries);

  @override
  int get hashCode => Object.hash(bus, tap, capOn, current, Object.hashAll(entries));
}

bool _same(List<double?> a, List<double?> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
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

// ============================================================================
// The panel (static between moves)
// ============================================================================

class M8VbPanelPainter extends CustomPainter {
  const M8VbPanelPainter({required this.geo, required this.rig});
  final M8VbGeo geo;
  final M8VbRig rig;

  @override
  void paint(Canvas c, Size size) {
    // The wall.
    c.drawRect(
      Offset.zero & size,
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1B2638), Color(0xFF263447), Color(0xFF1A2230)]).createShader(Offset.zero & size),
    );
    _window(c);
    _clock(c);
    _meter(c);
    _oltc(c);
    _cap(c);
    _book(c);
  }

  void _window(Canvas c) {
    final w = geo.window;
    final frame = RRect.fromRectAndRadius(w.inflate(4), const Radius.circular(8));
    c.drawRRect(frame, Paint()..color = const Color(0xFF3A4658));
    final glass = RRect.fromRectAndRadius(w, const Radius.circular(5));
    c.save();
    c.clipRRect(glass);
    c.drawRect(
      w,
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF7FA4C8), Color(0xFFD6C4A0)]).createShader(w),
    );
    final ground = Rect.fromLTRB(w.left, w.bottom - 14, w.right, w.bottom);
    c.drawRect(ground, Paint()..color = const Color(0xFF55555B));
    // The power transformer: tank, fins, two bushings.
    final tank = Rect.fromLTWH(w.left + 20, w.bottom - 34, 52, 22);
    c.drawRRect(RRect.fromRectAndRadius(tank, const Radius.circular(3)), Paint()..color = const Color(0xFF7C8794));
    for (var i = 0; i < 6; i++) {
      c.drawLine(Offset(tank.left + 6 + i * 8.0, tank.top + 3), Offset(tank.left + 6 + i * 8.0, tank.bottom - 2), Paint()..color = const Color(0xFF5E6874)..strokeWidth = 1.2);
    }
    for (final x in [tank.left + 14, tank.left + 38]) {
      c.drawLine(Offset(x, tank.top), Offset(x, tank.top - 10), Paint()..color = const Color(0xFF8A5A3A)..strokeWidth = 3);
      c.drawCircle(Offset(x, tank.top - 11), 2.2, Paint()..color = const Color(0xFFC8CDD4));
    }
    // The 11 kV structure: a pole with an insulator string and an LA.
    final px = w.left + 130;
    c.drawLine(Offset(px, w.bottom - 12), Offset(px, w.top + 6), Paint()..color = const Color(0xFF4A4036)..strokeWidth = 3.4);
    c.drawLine(Offset(px - 24, w.top + 12), Offset(px + 24, w.top + 12), Paint()..color = const Color(0xFF4A4036)..strokeWidth = 2.6);
    for (final x in [px - 20, px, px + 20]) {
      for (var k = 0; k < 3; k++) {
        c.drawOval(Rect.fromCenter(center: Offset(x, w.top + 17 + k * 3.6), width: 7, height: 2.8), Paint()..color = const Color(0xFFB8C2CC));
      }
    }
    // The LA: a grey column on a bracket.
    final la = Rect.fromLTWH(px + 8, w.top + 26, 7, 18);
    c.drawRRect(RRect.fromRectAndRadius(la, const Radius.circular(2)), Paint()..color = const Color(0xFF9AA4AE));
    c.drawLine(Offset(px + 4, w.top + 30), Offset(px + 11, w.top + 30), Paint()..color = const Color(0xFF4A4036)..strokeWidth = 1.6);
    // The far village pump: a small shed and a pipe on a field.
    final fx = w.right - 70;
    c.drawRect(Rect.fromLTRB(fx - 10, w.bottom - 28, w.right, w.bottom - 14), Paint()..color = const Color(0xFF6E8F5A));
    c.drawRect(Rect.fromLTWH(fx + 10, w.bottom - 30, 16, 14), Paint()..color = const Color(0xFFB0A090));
    c.drawPath(Path()
      ..moveTo(fx + 8, w.bottom - 31)
      ..lineTo(fx + 18, w.bottom - 38)
      ..lineTo(fx + 28, w.bottom - 31)
      ..close(), Paint()..color = const Color(0xFF8A4A3A));
    c.drawLine(Offset(fx + 26, w.bottom - 22), Offset(fx + 44, w.bottom - 22), Paint()..color = const Color(0xFF4A5A66)..strokeWidth = 2.2);
    c.restore();
    // Mullion.
    c.drawLine(Offset(w.left + 96, w.top), Offset(w.left + 96, w.bottom), Paint()..color = const Color(0x553A4658)..strokeWidth = 2);
  }

  void _clock(Canvas c) {
    final o = geo.clock;
    c.drawCircle(o, 21, Paint()..color = const Color(0xFF39445A));
    c.drawCircle(o, 18, Paint()..color = const Color(0xFFF3EFE0));
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      c.drawLine(o + Offset(math.cos(a), math.sin(a)) * 14, o + Offset(math.cos(a), math.sin(a)) * 16.5, Paint()..color = const Color(0xFF26303D)..strokeWidth = 1);
    }
    c.drawLine(o, o + const Offset(0, -11), Paint()..color = const Color(0xFF26303D)..strokeWidth = 1.6..strokeCap = StrokeCap.round);
    c.drawLine(o, o + const Offset(7, 3), Paint()..color = const Color(0xFF26303D)..strokeWidth = 1.6..strokeCap = StrokeCap.round);
  }

  // The voltmeter face: numerals and ticks only.
  void _meter(Canvas c) {
    final r = geo.meter;
    final body = RRect.fromRectAndRadius(r, const Radius.circular(10));
    c.drawRRect(body, Paint()..color = const Color(0xFF0E141F));
    final face = RRect.fromRectAndRadius(r.deflate(4), const Radius.circular(7));
    c.drawRRect(
      face,
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF8F4E6), Color(0xFFE6DFC8)]).createShader(r),
    );
    final b = rig.bus;
    final p = geo.pivot;
    final R = geo.dialR;
    final ink = Paint()
      ..color = const Color(0xFF26303D)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    c.drawArc(Rect.fromCircle(center: p, radius: R), M8VbGeo.a0, M8VbGeo.a1 - M8VbGeo.a0, false, ink);
    // Minor ticks (uniform) and major numerals (every 1 kV on 11, every 3 kV on 33).
    final minorEvery = b == M8VbBus.kv11 ? 0.25 : 0.75;
    final majorEvery = b == M8VbBus.kv11 ? 1.0 : 3.0;
    final lo = b.nominal * 0.8;
    final hi = b.nominal * 1.2;
    final tick = Paint()
      ..color = const Color(0xFF26303D)
      ..strokeWidth = 1;
    for (var v = lo; v <= hi + 1e-6; v += minorEvery) {
      final a = M8VbGeo.angle(m8VbFrac(b, v));
      final d = Offset(math.cos(a), math.sin(a));
      final major = ((v / majorEvery) - (v / majorEvery).roundToDouble()).abs() < 1e-6;
      if (major) {
        c.drawLine(p + d * (R - 9), p + d * R, tick..strokeWidth = 1.8);
        _text(c, enDigits('${v.round()}'), p + d * (R + 12), 11.5, const Color(0xFF1B2230));
      } else {
        c.drawLine(p + d * (R - 5), p + d * R, tick..strokeWidth = 1);
      }
    }
    _text(c, 'kV', p + Offset(0, -R * 0.45), 13, const Color(0xFF8A2A16));
    _text(c, b.label, Offset(r.left + 36, r.top + 14), 11, const Color(0xFF1B2230));
  }

  void _oltc(Canvas c) {
    final r = geo.oltc;
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(10)), Paint()..color = const Color(0xFF0E141F));
    c.drawRRect(RRect.fromRectAndRadius(r.deflate(2), const Radius.circular(8)), Paint()..color = const Color(0xFF2B3548));
    _text(c, 'OLTC', Offset(r.center.dx, r.top + 8), 9.5, const Color(0xFFB8C2D0));
    // The digit window.
    final d = RRect.fromRectAndRadius(Rect.fromLTWH(r.center.dx - 22, r.top + 15, 44, 30), const Radius.circular(5));
    c.drawRRect(d, Paint()..color = const Color(0xFF05080F));
    _text(c, enDigits('${rig.tap}'), d.center, 22, const Color(0xFFFFC94A), w: FontWeight.w900);
    _button(c, geo.raise, 'RAISE', up: true);
    _button(c, geo.lower, 'LOWER', up: false);
  }

  void _button(Canvas c, Rect r, String s, {required bool up}) {
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(10));
    c.drawRRect(rr.shift(const Offset(0, 2)), Paint()..color = const Color(0x66000000));
    c.drawRRect(
      rr,
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3C4C68), Color(0xFF222D42)]).createShader(r),
    );
    c.drawRRect(rr, Paint()..color = const Color(0xFFC8A24A)..style = PaintingStyle.stroke..strokeWidth = 1.6);
    final cx = r.center.dx;
    final cy = r.center.dy;
    final tri = Path();
    if (up) {
      tri
        ..moveTo(cx - 40, cy + 5)
        ..lineTo(cx - 32, cy - 6)
        ..lineTo(cx - 24, cy + 5)
        ..close();
    } else {
      tri
        ..moveTo(cx - 40, cy - 5)
        ..lineTo(cx - 32, cy + 6)
        ..lineTo(cx - 24, cy - 5)
        ..close();
    }
    c.drawPath(tri, Paint()..color = const Color(0xFFFFC94A));
    _text(c, s, Offset(cx + 10, cy), 13, const Color(0xFFF3EFE0));
  }

  void _cap(Canvas c) {
    final r = geo.cap;
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(10)), Paint()..color = const Color(0xFF0E141F));
    c.drawRRect(RRect.fromRectAndRadius(r.deflate(2), const Radius.circular(8)), Paint()..color = const Color(0xFF2B3548));
    _text(c, 'ক্যাপাসিটর ব্যাংক', Offset(r.center.dx, r.top + 9), 9.5, const Color(0xFFB8C2D0), w: FontWeight.w700);
    // Lamps.
    final on = rig.capOn;
    final lampOn = Offset(r.left + 22, r.top + 30);
    final lampOff = Offset(r.left + 22, r.top + 52);
    c.drawCircle(lampOn, 6, Paint()..color = on ? const Color(0xFF45D46B) : const Color(0xFF1E3326));
    c.drawCircle(lampOff, 6, Paint()..color = on ? const Color(0xFF3A1E1E) : const Color(0xFFE04B3C));
    _text(c, 'ON', lampOn + const Offset(20, 0), 10, const Color(0xFFF3EFE0));
    _text(c, 'OFF', lampOff + const Offset(21, 0), 10, const Color(0xFFF3EFE0));
    // The twist switch: a knob that points to OFF (left) or ON (right).
    final k = Offset(r.right - 36, r.center.dy + 6);
    c.drawCircle(k, 21, Paint()..color = const Color(0xFF05080F));
    c.drawCircle(
      k,
      17,
      Paint()..shader = const RadialGradient(colors: [Color(0xFF8793A6), Color(0xFF3A4558)]).createShader(Rect.fromCircle(center: k, radius: 17)),
    );
    final a = on ? -math.pi / 4 : -math.pi * 3 / 4;
    c.drawLine(k, k + Offset(math.cos(a), math.sin(a)) * 15, Paint()..color = const Color(0xFFFFC94A)..strokeWidth = 3.2..strokeCap = StrokeCap.round);
    _text(c, 'OFF', k + const Offset(-24, -25), 8, const Color(0xFFB8C2D0));
    _text(c, 'ON', k + const Offset(24, -25), 8, const Color(0xFFB8C2D0));
  }

  void _book(Canvas c) {
    final r = geo.book;
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(6)), Paint()..color = const Color(0xFF5A3A24));
    final page = RRect.fromRectAndRadius(r.deflate(3), const Radius.circular(4));
    c.drawRRect(page, Paint()..color = const Color(0xFFF7F1DE));
    _text(c, 'শিফট লগ', Offset(r.left + 36, r.top + 11), 9, const Color(0xFF3A2A1C), w: FontWeight.w800);
    for (var i = 0; i < 3; i++) {
      final y = r.top + 24 + i * 13.0;
      c.drawLine(Offset(r.left + 8, y + 6), Offset(r.right - 8, y + 6), Paint()..color = const Color(0xFFB9AE92)..strokeWidth = 0.8);
      final e = rig.entries[i];
      final label = enDigits('${i + 1}');
      _text(c, label, Offset(r.left + 12, y), 9, const Color(0xFF6A5A44));
      if (e != null) {
        _text(c, m8VbReading(e), Offset(r.left + 44, y), 10.5, const Color(0xFF17325E), w: FontWeight.w700);
      } else if (i == rig.current) {
        c.drawCircle(Offset(r.left + 44, y + 1), 1.4, Paint()..color = const Color(0x8817325E));
      }
    }
    // The pen lying on the book.
    final pen = Path()
      ..moveTo(r.right - 40, r.bottom - 8)
      ..lineTo(r.right - 9, r.bottom - 30)
      ..lineTo(r.right - 5, r.bottom - 26)
      ..lineTo(r.right - 36, r.bottom - 4)
      ..close();
    c.drawPath(pen, Paint()..color = const Color(0xFF1F4E9E));
    c.drawLine(Offset(r.right - 40, r.bottom - 8), Offset(r.right - 44, r.bottom - 4), Paint()..color = const Color(0xFF111111)..strokeWidth = 1.6);
  }

  @override
  bool shouldRepaint(M8VbPanelPainter old) => old.geo != geo || old.rig != rig;
}

// ============================================================================
// The needle (the only thing that moves)
// ============================================================================

class M8VbNeedlePainter extends CustomPainter {
  const M8VbNeedlePainter({required this.geo, required this.bus, required this.kv});
  final M8VbGeo geo;
  final M8VbBus bus;
  final double kv;

  @override
  void paint(Canvas c, Size size) {
    final p = geo.pivot;
    final a = M8VbGeo.angle(m8VbFrac(bus, kv));
    final tip = p + Offset(math.cos(a), math.sin(a)) * (geo.dialR - 3);
    c.drawLine(p + const Offset(1.5, 1.5), tip + const Offset(1.5, 1.5), Paint()..color = const Color(0x44000000)..strokeWidth = 2.6..strokeCap = StrokeCap.round);
    c.drawLine(p, tip, Paint()..color = const Color(0xFFC0392B)..strokeWidth = 2.4..strokeCap = StrokeCap.round);
    c.drawCircle(p, 5, Paint()..color = const Color(0xFF26303D));
    c.drawCircle(p, 2, Paint()..color = const Color(0xFFD8D2BE));
  }

  @override
  bool shouldRepaint(M8VbNeedlePainter old) => old.kv != kv || old.bus != bus || old.geo != geo;
}

// ============================================================================
// The hold ring (only while a button is pressed)
// ============================================================================

class M8VbRingPainter extends CustomPainter {
  M8VbRingPainter({required this.at, required Animation<double> progress}) : _p = progress, super(repaint: progress);
  final Offset at;
  final Animation<double> _p;

  @override
  void paint(Canvas c, Size size) {
    final rect = Rect.fromCircle(center: at, radius: 24);
    c.drawCircle(at, 24, Paint()..color = const Color(0x55000000)..style = PaintingStyle.stroke..strokeWidth = 5);
    c.drawArc(rect, -math.pi / 2, math.pi * 2 * _p.value, false, Paint()..color = const Color(0xFFFFC94A)..style = PaintingStyle.stroke..strokeWidth = 5..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(M8VbRingPainter old) => old.at != at;
}

// ============================================================================
// The consequence close-up (after a wrong entry)
// ============================================================================

class M8VbInsetPainter extends CustomPainter {
  const M8VbInsetPainter({required this.kind, required this.v});
  final M8VbInset kind;

  /// 0 … 1 over the inset's life.
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final r = Offset.zero & size;
    final frame = RRect.fromRectAndRadius(r, const Radius.circular(14));
    c.drawRRect(frame, Paint()..color = const Color(0xFF0B1324));
    c.save();
    c.clipRRect(frame.deflate(3));
    c.drawRect(
      r,
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3A4E72), Color(0xFF9A8F78)]).createShader(r),
    );
    c.drawRect(Rect.fromLTRB(0, r.bottom - 36, r.right, r.bottom), Paint()..color = const Color(0xFF4F4F55));
    if (kind == M8VbInset.high) {
      _high(c, r);
    } else {
      _low(c, r);
    }
    c.restore();
    c.drawRRect(frame, Paint()..color = const Color(0xFFC8A24A)..style = PaintingStyle.stroke..strokeWidth = 3);
  }

  // An insulator string and an LA on the 11 kV structure: a flash, then they burst.
  void _high(Canvas c, Rect r) {
    final cx = r.center.dx;
    c.drawLine(Offset(cx, r.bottom - 30), Offset(cx, 14), Paint()..color = const Color(0xFF4A4036)..strokeWidth = 9);
    c.drawLine(Offset(cx - 90, 40), Offset(cx + 90, 40), Paint()..color = const Color(0xFF4A4036)..strokeWidth = 7);
    final burst = Curves.easeOut.transform(((v - 0.3) / 0.5).clamp(0.0, 1.0));
    for (final x in [cx - 70, cx - 4, cx + 62]) {
      for (var k = 0; k < 5; k++) {
        final dx = (x < cx ? -1 : 1) * burst * (6 + k * 2.4);
        c.drawOval(Rect.fromCenter(center: Offset(x + dx * (k.isEven ? 1 : -1) * 0.4, 52 + k * 10.0 + burst * 8), width: 22, height: 8), Paint()..color = burst > 0.2 && k == 2 ? const Color(0xFF6A6F76) : const Color(0xFFC8D0D8));
      }
    }
    // The LA.
    final la = Rect.fromLTWH(cx + 20, 96, 20, 70);
    c.drawRRect(RRect.fromRectAndRadius(la, const Radius.circular(5)), Paint()..color = burst > 0.4 ? const Color(0xFF55585E) : const Color(0xFF9AA4AE));
    if (v > 0.25 && v < 0.85) {
      final f = math.sin(((v - 0.25) / 0.6) * math.pi);
      c.drawCircle(Offset(cx, 70), 30 + 40 * f, Paint()..color = Color.fromRGBO(255, 235, 150, 0.55 * f));
      final bolt = Paint()
        ..color = Color.fromRGBO(255, 250, 220, f)
        ..strokeWidth = 3
        ..style = PaintingStyle.stroke;
      c.drawPath(Path()
        ..moveTo(cx - 30, 48)
        ..lineTo(cx - 8, 72)
        ..lineTo(cx - 20, 82)
        ..lineTo(cx + 10, 112), bolt);
    }
    if (burst > 0) {
      final spark = Paint()..color = Color.fromRGBO(255, 214, 120, 1 - burst * 0.6);
      for (var i = 0; i < 9; i++) {
        final a = i * 0.7 + 0.3;
        c.drawCircle(Offset(cx, 76) + Offset(math.cos(a), math.sin(a)) * (20 + burst * 70), 2.4, spark);
      }
    }
  }

  // The village pump motor smokes.
  void _low(Canvas c, Rect r) {
    final cx = r.center.dx;
    final base = r.bottom - 36;
    c.drawRect(Rect.fromLTWH(cx - 70, base - 6, 140, 6), Paint()..color = const Color(0xFF3A3A40));
    final motor = Rect.fromLTWH(cx - 52, base - 62, 78, 56);
    c.drawRRect(RRect.fromRectAndRadius(motor, const Radius.circular(8)), Paint()..color = v > 0.3 ? const Color(0xFF4A4642) : const Color(0xFF5E7BA8));
    for (var i = 0; i < 6; i++) {
      c.drawLine(Offset(motor.left + 12 + i * 11.0, motor.top + 6), Offset(motor.left + 12 + i * 11.0, motor.bottom - 6), Paint()..color = const Color(0x55000000)..strokeWidth = 2);
    }
    c.drawRect(Rect.fromLTWH(cx + 26, base - 40, 34, 14), Paint()..color = const Color(0xFF8A96A4));
    c.drawLine(Offset(cx + 60, base - 33), Offset(cx + 100, base - 33), Paint()..color = const Color(0xFF5A6674)..strokeWidth = 6);
    // Smoke puffs rising and growing.
    for (var i = 0; i < 6; i++) {
      final t = ((v * 1.4) - i * 0.12).clamp(0.0, 1.0);
      if (t <= 0) continue;
      final o = Offset(cx - 14 + math.sin(i * 1.7 + v * 3) * 18, motor.top - t * 90);
      c.drawCircle(o, 8 + t * 18, Paint()..color = Color.fromRGBO(40, 40, 44, 0.55 * (1 - t * 0.6)));
    }
    if (v > 0.2 && v < 0.6) {
      c.drawCircle(Offset(motor.center.dx, motor.top + 10), 10 * math.sin(((v - 0.2) / 0.4) * math.pi), Paint()..color = const Color(0xCCFFB347));
    }
  }

  @override
  bool shouldRepaint(M8VbInsetPainter old) => old.kind != kind || old.v != v;
}
