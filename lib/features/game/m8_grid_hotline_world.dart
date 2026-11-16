import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';

// The drawn world of lesson 8.4 "গ্রিড কোড" কাজ 1 "হটলাইন বাজছে"
// (m8_grid_hotline.dart): a 33/11 kV substation control room at dusk.
//
// From the top: the wall frequency meter (two decimals, a trend strip, no
// band and no countdown) with a small state-map inset that lights only after
// shedding; the window onto the town (one neighbourhood per feeder, dark once
// its feeder is OFF); a panel of six identical 11 kV feeder bays (a nameplate,
// ON / OFF lamps, a mimic line and a pistol-grip switch twisted along its
// arc); and the desk with the red SLDC hotline, an ordinary black phone and
// the closed load-shedding register.
//
// No text in the art except labels a worker reads (the nameplates, ON / OFF,
// SLDC, the register's own print). Code-drawn, gradients, no bitmaps.
//
// Design: 360 wide × the scene's height; the floor follows the bottom of the
// screen (a taller phone gets a bigger gap above the desk, never stretched).

/// How many feeders (bays) there are.
const int kM8Bays = 6;

/// One ring (hotline or black phone): a burst, then a pause.
const int kM8RingMs = 1500;

/// The ringing part of one ring cycle.
const int kM8RingBurstMs = 900;

/// Where things are (design px, 360 wide).
@immutable
class M8GridGeo {
  const M8GridGeo._(this.height, this.floorY);

  factory M8GridGeo.forScene(double height, double inset) => M8GridGeo._(height, height - floorUp - inset * 0.5);

  final double height;
  final double floorY;

  /// The floor sits this far above the bottom.
  static const double floorUp = 96;

  /// The top of the working area (under the header).
  static const double top = 132;

  double get a => floorY - top - 8;

  // --- the wall ----------------------------------------------------------------
  Rect get meter => const Rect.fromLTWH(10, top, 238, 88);
  Rect get stateMap => const Rect.fromLTWH(254, top, 96, 88);
  Rect get window => const Rect.fromLTWH(10, top + 94, 340, 56);

  // --- the panel ---------------------------------------------------------------
  double get baysTop => window.bottom + 8;
  double get bayH => (0.27 * a).clamp(138.0, 180.0);
  Rect bay(int i) => Rect.fromLTWH(12 + i * 56.0, baysTop, 54, bayH);
  Offset knob(int i) => Offset(bay(i).center.dx, bay(i).top + bayH * 0.66);
  Rect switchHit(int i) => Rect.fromCenter(center: knob(i), width: 52, height: 62);

  // --- the desk ----------------------------------------------------------------
  double get deskTop => bay(0).bottom + 10;
  double get deskY => deskTop + 32;
  Rect get hotline => Rect.fromCenter(center: Offset(88, deskY), width: 60, height: 56);
  Rect get blackPhone => Rect.fromCenter(center: Offset(154, deskY), width: 60, height: 56);
  Rect get register => Rect.fromCenter(center: Offset(222, deskY), width: 56, height: 52);
  Rect get trainee => Rect.fromLTWH(2, deskTop - 2, 46, 100);

  /// The open register: over the window and the panel, the meter stays in
  /// view; it never reaches the guide in the corner.
  Rect get registerPanel => Rect.fromLTRB(10, window.top, 350, math.min(register.bottom + 8, height - 190));

  /// The register's handle (tap or swipe down closes it).
  Rect get registerHandle => Rect.fromLTWH(registerPanel.left, registerPanel.top, registerPanel.width, 30);

  /// The SLDC / customer caption bubble (over the window band).
  Rect get caption => Rect.fromLTWH(14, window.top + 2, 332, 52);

  @override
  bool operator ==(Object other) => other is M8GridGeo && other.height == height && other.floorY == floorY;

  @override
  int get hashCode => Object.hash(height, floorY);
}

/// Which handset.
enum M8Phone { hot, black }

/// What the desk's phones are doing now.
@immutable
class M8Phones {
  const M8Phones({this.hotRinging = false, this.blackRinging = false, this.hotLit = false, this.blackLit = false, this.hotLift = 0, this.blackLift = 0});

  /// The hotline is ringing (a burst each cycle).
  final bool hotRinging;
  final bool blackRinging;

  /// The hotline's lamp stays lit (it rang, nobody lifted it).
  final bool hotLit;
  final bool blackLit;

  M8Phones copyWith({bool? hotRinging, bool? blackRinging, bool? hotLit, bool? blackLit, double? hotLift, double? blackLift}) => M8Phones(
        hotRinging: hotRinging ?? this.hotRinging,
        blackRinging: blackRinging ?? this.blackRinging,
        hotLit: hotLit ?? this.hotLit,
        blackLit: blackLit ?? this.blackLit,
        hotLift: hotLift ?? this.hotLift,
        blackLift: blackLift ?? this.blackLift,
      );

  /// How far each handset is lifted off its cradle (design px).
  final double hotLift;
  final double blackLift;

  @override
  bool operator ==(Object other) =>
      other is M8Phones && other.hotRinging == hotRinging && other.blackRinging == blackRinging && other.hotLit == hotLit && other.blackLit == blackLit && other.hotLift == hotLift && other.blackLift == blackLift;

  @override
  int get hashCode => Object.hash(hotRinging, blackRinging, hotLit, blackLit, hotLift, blackLift);
}

/// A bay's switch being twisted (progress 0 = ON … 1 = OFF).
@immutable
class M8BayDrag {
  const M8BayDrag(this.bay, this.progress);
  final int bay;
  final double progress;

  @override
  bool operator ==(Object other) => other is M8BayDrag && other.bay == bay && other.progress == progress;

  @override
  int get hashCode => Object.hash(bay, progress);
}

/// The switch handle's angle (radians, screen) at ON and at OFF: a quarter
/// turn, clockwise.
const double kM8KnobOn = -math.pi * 0.75;
const double kM8KnobOff = -math.pi * 0.25;

Paint _fill(Color c) => Paint()..color = c;
Paint _stroke(Color c, double w) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..color = c
  ..strokeCap = StrokeCap.round;

void _label(Canvas c, String text, Offset centre, {double size = 7, Color color = const Color(0xFFE6E9EE), FontWeight weight = FontWeight.w800, double maxW = 52, int lines = 2}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: weight, color: color, height: 1.05)),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
    maxLines: lines,
    ellipsis: '',
  )..layout(maxWidth: maxW);
  tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
}

// ============================================================================
// The room (window, neighbourhoods, desk) — static
// ============================================================================

class M8RoomPainter extends CustomPainter {
  const M8RoomPainter({required this.geo, required this.lit, required this.storm});

  final M8GridGeo geo;

  /// Per bay: its neighbourhood has supply.
  final List<bool> lit;

  /// A storm evening (darker sky, rain), else the evening peak.
  final bool storm;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    final wall = Rect.fromLTWH(0, 0, w, g.floorY);
    c.drawRect(wall, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1A2438), Color(0xFF263148)]).createShader(wall));
    // The window onto the town.
    final win = g.window;
    c.drawRRect(RRect.fromRectAndRadius(win.inflate(4), const Radius.circular(8)), _fill(const Color(0xFF0E1522)));
    c.save();
    c.clipRRect(RRect.fromRectAndRadius(win, const Radius.circular(5)));
    c.drawRect(
        win,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: storm ? const [Color(0xFF1B2030), Color(0xFF3A3F55), Color(0xFF59506A)] : const [Color(0xFF1B2547), Color(0xFF6A4C78), Color(0xFFE09A6A)],
          ).createShader(win));
    if (storm) {
      final rain = _stroke(const Color(0x55C9D6EE), 0.9);
      for (var x = win.left + 6; x < win.right; x += 11) {
        c.drawLine(Offset(x, win.top + 4 + (x * 7) % 17), Offset(x - 4, win.top + 16 + (x * 7) % 17), rain);
      }
    }
    // One neighbourhood per bay: a row of little houses; windows lit with
    // supply, dark without.
    for (var i = 0; i < kM8Bays; i++) {
      final colL = win.left + i * (win.width / kM8Bays);
      final cw = win.width / kM8Bays;
      final on = i < lit.length && lit[i];
      for (var k = 0; k < 3; k++) {
        final hw = cw / 3 - 3;
        final hh = 14.0 + ((i * 3 + k * 5) % 3) * 5;
        final hx = colL + 3 + k * (cw / 3);
        final r = Rect.fromLTWH(hx, win.bottom - hh, hw, hh);
        c.drawRect(r, _fill(const Color(0xFF141B2B)));
        final roof = Path()
          ..moveTo(r.left - 1, r.top)
          ..lineTo(r.center.dx, r.top - 5)
          ..lineTo(r.right + 1, r.top)
          ..close();
        c.drawPath(roof, _fill(const Color(0xFF0E1420)));
        if (on) {
          c.drawRect(Rect.fromLTWH(r.left + 2.5, r.top + 4, 3.4, 3.4), _fill(const Color(0xFFFFD66B)));
          if (hh > 20) c.drawRect(Rect.fromLTWH(r.right - 6, r.top + 4, 3.4, 3.4), _fill(const Color(0xFFFFD66B)));
          c.drawRect(Rect.fromLTWH(r.left + 3, r.bottom - 6, 3, 3), _fill(const Color(0xFFFFE9A6)));
        }
      }
    }
    c.restore();
    // The desk and the floor.
    final deskR = Rect.fromLTRB(0, g.deskTop, w, g.floorY);
    c.drawRect(deskR, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF6D5538), Color(0xFF4A3826)]).createShader(deskR));
    c.drawRect(Rect.fromLTWH(0, g.deskTop, w, 3), _fill(const Color(0xFF8C7048)));
    final floor = Rect.fromLTRB(0, g.floorY, w, size.height);
    c.drawRect(floor, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2B2F3A), Color(0xFF181B23)]).createShader(floor));
  }

  @override
  bool shouldRepaint(M8RoomPainter old) => old.geo != geo || old.storm != storm || !_sameList(old.lit, lit);
}

bool _sameList(List<bool> a, List<bool> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

// ============================================================================
// The frequency meter and the state-map inset
// ============================================================================

/// The wall meter. [freq] is read each frame (the page owns the clock);
/// [hist] is the trend (oldest first), appended by the page; [dim] 0–1 is how
/// many of the inset's dots have gone dark.
class M8MeterPainter extends CustomPainter {
  M8MeterPainter({required this.geo, required this.freq, required this.hist, required this.dim, required Listenable repaint}) : super(repaint: repaint);

  final M8GridGeo geo;
  final double Function() freq;
  final List<double> hist;
  final double Function() dim;

  /// The text of the reading (two decimals).
  static String text(double f) => f.toStringAsFixed(2);

  @override
  void paint(Canvas c, Size size) {
    final m = geo.meter;
    final box = RRect.fromRectAndRadius(m, const Radius.circular(10));
    c.drawRRect(box, _fill(const Color(0xFF0B1019)));
    c.drawRRect(box, _stroke(const Color(0xFF4E5A70), 2));
    // The digits.
    final f = freq();
    final tp = TextPainter(
      text: TextSpan(text: text(f), style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w800, color: Color(0xFFFFC857), fontFeatures: [FontFeature.tabularFigures()], letterSpacing: 1)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(m.left + 14, m.top + 6));
    _label(c, 'Hz', Offset(m.left + 14 + tp.width + 16, m.top + 30), size: 14, color: const Color(0xFFB9A26A), lines: 1, maxW: 40);
    _label(c, 'FREQUENCY', Offset(m.right - 40, m.top + 14), size: 7, color: const Color(0xFF7D879A), lines: 1, maxW: 70);
    // The trend strip (auto-scaled; no band, no limit lines).
    final strip = Rect.fromLTWH(m.left + 12, m.top + 54, m.width - 24, 26);
    c.drawRect(strip, _fill(const Color(0xFF121A28)));
    final pts = <double>[...hist, f];
    if (pts.length >= 2) {
      var lo = pts.reduce(math.min);
      var hi = pts.reduce(math.max);
      if (hi - lo < 0.2) {
        final mid = (hi + lo) / 2;
        lo = mid - 0.1;
        hi = mid + 0.1;
      }
      final path = Path();
      for (var i = 0; i < pts.length; i++) {
        final x = strip.left + strip.width * i / (pts.length - 1);
        final y = strip.bottom - 3 - (strip.height - 6) * (pts[i] - lo) / (hi - lo);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      c.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..strokeJoin = StrokeJoin.round
            ..color = const Color(0xFF7FE0A8));
    }
    // The state-map inset: a dot field that dims after shedding.
    final s = geo.stateMap;
    c.drawRRect(RRect.fromRectAndRadius(s, const Radius.circular(10)), _fill(const Color(0xFF0B1019)));
    c.drawRRect(RRect.fromRectAndRadius(s, const Radius.circular(10)), _stroke(const Color(0xFF4E5A70), 2));
    final d = dim().clamp(0.0, 1.0);
    const cols = 6;
    const rows = 4;
    var k = 0;
    for (var r = 0; r < rows; r++) {
      for (var q = 0; q < cols; q++) {
        final p = Offset(s.left + 14 + q * ((s.width - 28) / (cols - 1)), s.top + 14 + r * 13.5);
        final off = (k % 5 == 0 || k % 7 == 3) && d > 0;
        final a = off ? 1 - 0.78 * d : 1.0;
        c.drawCircle(p, 3.1, _fill(Color.fromRGBO(255, 214, 107, a)));
        k++;
      }
    }
    _label(c, 'STATE', Offset(s.center.dx, s.bottom - 9), size: 6.5, color: const Color(0xFF7D879A), lines: 1, maxW: 60);
  }

  @override
  bool shouldRepaint(M8MeterPainter old) => old.geo != geo;
}

// ============================================================================
// The feeder bays
// ============================================================================

class M8BayPainter extends CustomPainter {
  M8BayPainter({required this.geo, required this.names, required this.off, required this.drag}) : super(repaint: drag);

  final M8GridGeo geo;

  /// The nameplate of each bay, in panel order.
  final List<String> names;

  /// Each bay's switch is at OFF.
  final List<bool> off;

  /// The bay being twisted now.
  final ValueListenable<M8BayDrag?> drag;

  @override
  void paint(Canvas c, Size size) {
    final d = drag.value;
    for (var i = 0; i < kM8Bays; i++) {
      final r = geo.bay(i);
      final isOff = off[i];
      final body = RRect.fromRectAndRadius(r, const Radius.circular(7));
      c.drawRRect(body, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8B94A3), Color(0xFF626B7B)]).createShader(r));
      c.drawRRect(body, _stroke(const Color(0xFF3B4352), 1.4));
      // The nameplate.
      final plate = Rect.fromLTWH(r.left + 3, r.top + 3, r.width - 6, 22);
      c.drawRRect(RRect.fromRectAndRadius(plate, const Radius.circular(3)), _fill(const Color(0xFFF1EBD8)));
      _label(c, names[i], plate.center, size: 8.4, color: const Color(0xFF1D2430), maxW: plate.width - 3);
      // The mimic line: the feeder from the bus (top) to the load (bottom).
      final cx = r.center.dx;
      final lineTop = r.top + 52;
      final live = !isOff;
      c.drawLine(Offset(cx, lineTop), Offset(cx, r.bottom - 8), _stroke(live ? const Color(0xFFFFE08A) : const Color(0xFF3D4452), 3));
      c.drawCircle(Offset(cx, lineTop), 3, _fill(const Color(0xFFD8DEE8)));
      // ON / OFF lamps with their printed letters.
      final lampY = r.top + 36;
      c.drawCircle(Offset(cx - 11, lampY), 4.6, _fill(live ? const Color(0xFFFF4A3D) : const Color(0xFF4A2A2A)));
      c.drawCircle(Offset(cx + 11, lampY), 4.6, _fill(isOff ? const Color(0xFF52E08B) : const Color(0xFF244A33)));
      _label(c, 'ON', Offset(cx - 11, lampY + 9), size: 5.5, color: const Color(0xFF1D2430), lines: 1, maxW: 20);
      _label(c, 'OFF', Offset(cx + 11, lampY + 9), size: 5.5, color: const Color(0xFF1D2430), lines: 1, maxW: 20);
      // The pistol-grip switch: a dial with a handle at ON or OFF (or between
      // while it is being twisted).
      final k = geo.knob(i);
      final p = d != null && d.bay == i ? d.progress.clamp(0.0, 1.0) : (isOff ? 1.0 : 0.0);
      final ang = kM8KnobOn + (kM8KnobOff - kM8KnobOn) * p;
      c.drawCircle(k, 17, _fill(const Color(0xFF2B3140)));
      c.drawCircle(k, 17, _stroke(const Color(0xFFC9D0DC), 1.6));
      // The two stops of the arc.
      for (final a in [kM8KnobOn, kM8KnobOff]) {
        c.drawCircle(k + Offset(math.cos(a), math.sin(a)) * 21, 1.8, _fill(const Color(0xFFE6E9EE)));
      }
      final tip = k + Offset(math.cos(ang), math.sin(ang)) * 21;
      c.drawLine(k, tip, _stroke(const Color(0xFFFFFFFF), 6));
      c.drawLine(k, tip, _stroke(const Color(0xFF39404F), 3.2));
      c.drawCircle(k, 5, _fill(const Color(0xFFD1D6E0)));
    }
  }

  @override
  bool shouldRepaint(M8BayPainter old) => old.geo != geo || !_sameList(old.off, off) || !_sameNames(old.names, names);
}

bool _sameNames(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

// ============================================================================
// The desk: hotline, black phone, register
// ============================================================================

/// The phones' shake while ringing needs a clock: [ring] is a controller
/// whose [Animation.value] runs while something rings (the page stops it when
/// nothing does, so the desk rests).
class M8DeskPainter extends CustomPainter {
  M8DeskPainter({required this.geo, required this.phones, required this.ring, required this.ringMs}) : super(repaint: Listenable.merge([phones, ring]));

  final M8GridGeo geo;
  final ValueListenable<M8Phones> phones;
  final Animation<double> ring;

  /// The controller's full length (ms), to turn its value into time.
  final double Function() ringMs;

  /// Shake (px) at [ms] into a ringing: a burst of ~900 ms, a pause of 600.
  static double shake(double ms) {
    final t = ms % kM8RingMs;
    if (t > kM8RingBurstMs) return 0;
    return math.sin(t / 38) * 2.4;
  }

  @override
  void paint(Canvas c, Size size) {
    final s = phones.value;
    final ms = ring.value * ringMs();
    // The register (closed): a thick book with a ribbon.
    final reg = geo.register;
    c.drawRRect(RRect.fromRectAndRadius(reg, const Radius.circular(4)), _fill(const Color(0xFF3A2B1E)));
    c.drawRRect(RRect.fromRectAndRadius(reg.deflate(3), const Radius.circular(3)), _fill(const Color(0xFF7A3B2A)));
    c.drawRect(Rect.fromLTWH(reg.left + 8, reg.top + 3, 3, reg.height - 6), _fill(const Color(0xFFE2C98B)));
    _label(c, 'REGISTER', reg.center + const Offset(4, 0), size: 6, color: const Color(0xFFF1EBD8), lines: 1, maxW: 40);
    // The hotline (red) and the black phone.
    _phone(c, geo.hotline, hot: true, ringing: s.hotRinging, lit: s.hotLit, lift: s.hotLift, shake: s.hotRinging ? shake(ms) : 0);
    _phone(c, geo.blackPhone, hot: false, ringing: s.blackRinging, lit: s.blackLit, lift: s.blackLift, shake: s.blackRinging ? shake(ms) : 0);
  }

  void _phone(Canvas c, Rect r, {required bool hot, required bool ringing, required bool lit, required double lift, required double shake}) {
    final base = hot ? const Color(0xFFC62828) : const Color(0xFF20242C);
    final hi = hot ? const Color(0xFFFF6A5E) : const Color(0xFF505968);
    // The base (cradle).
    final b = Rect.fromLTWH(r.left + 2, r.bottom - 24, r.width - 4, 22);
    c.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(6)), _fill(base));
    c.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(6)), _stroke(hi, 1.2));
    c.drawCircle(Offset(b.left + 9, b.center.dy), 3, _fill(lit || ringing ? const Color(0xFFFFE066) : const Color(0xFF2A2F3A)));
    if (hot) _label(c, 'SLDC', Offset(b.center.dx + 6, b.center.dy), size: 7.5, color: Colors.white, lines: 1, maxW: 38);
    // Digits of a dial pad.
    for (var q = 0; q < 6; q++) {
      c.drawCircle(Offset(b.right - 12 - (q % 3) * 6.0, b.center.dy - 3 + (q ~/ 3) * 6.5), 1.4, _fill(const Color(0x66FFFFFF)));
    }
    // The handset on the cradle, lifted by [lift].
    c.save();
    c.translate(shake, -lift);
    final h = RRect.fromRectAndRadius(Rect.fromLTWH(r.left + 5, r.top + 6, r.width - 10, 13), const Radius.circular(7));
    c.drawRRect(h, _fill(base));
    c.drawRRect(h, _stroke(hi, 1.2));
    c.drawCircle(Offset(h.left + 8, h.center.dy + 5), 5, _fill(base));
    c.drawCircle(Offset(h.right - 8, h.center.dy + 5), 5, _fill(base));
    c.restore();
    if (ringing) {
      // Ring marks.
      final a = _stroke(const Color(0xCCFFE066), 1.8);
      for (var i = 0; i < 2; i++) {
        final rr = 10.0 + i * 6;
        c.drawArc(Rect.fromCircle(center: Offset(r.right - 4, r.top + 8), radius: rr), -math.pi * 0.6, math.pi * 0.5, false, a);
      }
    }
  }

  @override
  bool shouldRepaint(M8DeskPainter old) => old.geo != geo || old.phones != phones;
}

// ============================================================================
// The register (open)
// ============================================================================

/// The open register: the areas in their fixed order down the side, the last
/// three days across, a dark-moon mark where an area was shed. No highlight.
class M8RegisterPainter extends CustomPainter {
  const M8RegisterPainter({required this.geo, required this.areas, required this.dates, required this.marks});

  final M8GridGeo geo;
  final List<String> areas;

  /// Three column headings (dates), oldest first.
  final List<String> dates;

  /// marks[row][col]: the row's area was shed on that day.
  final List<List<bool>> marks;

  @override
  void paint(Canvas c, Size size) {
    final p = geo.registerPanel;
    final page = RRect.fromRectAndRadius(p, const Radius.circular(10));
    c.drawRRect(page, _fill(const Color(0xFFF4EEDC)));
    c.drawRRect(page, _stroke(const Color(0xFF7A3B2A), 3));
    // The handle.
    final hd = geo.registerHandle;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(hd.left, hd.top, hd.right, hd.bottom), const Radius.circular(10)), _fill(const Color(0xFF7A3B2A)));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: hd.center, width: 46, height: 5), const Radius.circular(3)), _fill(const Color(0xFFE2C98B)));
    final body = Rect.fromLTRB(p.left + 8, hd.bottom + 4, p.right - 8, p.bottom - 8);
    const head = 24.0;
    final rowH = (body.height - head) / areas.length;
    final nameW = body.width * 0.4;
    final colW = (body.width - nameW) / 3;
    final line = _stroke(const Color(0xFFB9AE92), 1);
    c.drawLine(Offset(body.left, body.top + head), Offset(body.right, body.top + head), line);
    _label(c, 'এলাকা', Offset(body.left + nameW / 2, body.top + head / 2), size: 11, color: const Color(0xFF3A2B1E), lines: 1, maxW: nameW);
    for (var q = 0; q < 3; q++) {
      final cx = body.left + nameW + colW * (q + 0.5);
      _label(c, dates[q], Offset(cx, body.top + head / 2), size: 11, color: const Color(0xFF3A2B1E), lines: 1, maxW: colW);
      c.drawLine(Offset(body.left + nameW + colW * q, body.top), Offset(body.left + nameW + colW * q, body.bottom), line);
    }
    for (var r = 0; r < areas.length; r++) {
      final y = body.top + head + rowH * r;
      if (r > 0) c.drawLine(Offset(body.left, y), Offset(body.right, y), line);
      _label(c, areas[r], Offset(body.left + nameW / 2, y + rowH / 2), size: 12.5, color: const Color(0xFF1D2430), lines: 1, maxW: nameW - 6);
      for (var q = 0; q < 3; q++) {
        if (!marks[r][q]) continue;
        final m = Offset(body.left + nameW + colW * (q + 0.5), y + rowH / 2);
        final rad = math.min(rowH * 0.34, 11.0);
        // A dark moon: a full dark disc with a bright bite.
        c.drawCircle(m, rad, _fill(const Color(0xFF232A3C)));
        c.drawCircle(m + Offset(rad * 0.42, -rad * 0.28), rad * 0.82, _fill(const Color(0xFFF4EEDC)));
        c.drawCircle(m, rad, _stroke(const Color(0xFF232A3C), 1.4));
      }
    }
  }

  @override
  bool shouldRepaint(M8RegisterPainter old) => old.geo != geo || old.areas != areas || old.dates != dates || old.marks != marks;
}
