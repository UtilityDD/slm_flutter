import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';

// The drawn world of lesson 8.3 কাজ 2 "শাটডাউনের ছক" (m8_shutdown_plan.dart):
// the section office wall and, on the shutdown morning, a village lane.
//
// Three places, one geometry class (design px, 360 wide x the scene's height;
// everything hangs from the top, so a tall phone only gets more wall):
//  * the planner — a magnetic board of five dated days, each a plain 00–24
//    strip with hour numbers only (every 3 hours; no night shading, no colour
//    band, no 'allowed' tint), a red 'এখন' magnet on the first day, the
//    docket clip under the board, and the job's block in a tray. A block that
//    is held shows only its times.
//  * the notice sheet — the board's day row with the placed block, three
//    swipe wheels (দিন · শুরু · শেষ) and the miking auto with its loudspeaker.
//  * the morning lane — three porches (a family group on each, silent
//    caption bubbles), the crew at the pole, a wall clock chip.
//
// No text in the art except labels a worker reads (day names, hour numbers,
// the docket, the clock). Code-drawn, gradients, no bitmaps.

/// The planner shows this many days (lesson 8.3: a long job needs 3 days'
/// notice, so a long job rolls to day 4 or 5).
const int kM8Days = 5;

/// The strip's left and right edge (design px).
const double kM8StripL = 54;
const double kM8StripR = 348;

/// Design px for one hour of the strip.
const double kM8PxH = (kM8StripR - kM8StripL) / 24;

/// The weekday names (Monday first).
const List<String> kM8DayNames = ['সোম', 'মঙ্গল', 'বুধ', 'বৃহ', 'শুক্র', 'শনি', 'রবি'];

/// "HH:MM" of [min] (whole minutes from the first day's midnight, any day).
String m8Clock(num min) {
  final m = (min.round() % 1440 + 1440) % 1440;
  return '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
}

/// Where things are.
@immutable
class M8PlanGeo {
  const M8PlanGeo._(this.height, this.inset);

  factory M8PlanGeo.forScene(double height, double inset) => M8PlanGeo._(height, inset);

  final double height;

  /// The bottom system inset (design px).
  final double inset;

  /// The top of the working area (under the header and the progress dots).
  static const double top = 132;

  double get stride => height >= 700 ? 46 : 40;
  double get rowH => stride - 6;
  double rowTop(int d) => top + 18 + d * stride;

  /// Day [d]'s hour strip.
  Rect strip(int d) => Rect.fromLTRB(kM8StripL, rowTop(d), kM8StripR, rowTop(d) + rowH);
  Rect dayLabel(int d) => Rect.fromLTRB(6, rowTop(d), kM8StripL - 4, rowTop(d) + rowH);

  double hourX(num h) => kM8StripL + h * kM8PxH;

  Rect get board => Rect.fromLTRB(4, top, 356, rowTop(kM8Days - 1) + rowH + 8);
  Rect get docket => Rect.fromLTWH(8, board.bottom + 8, 238, 48);

  /// The block's place in the tray, and the (larger) area that grabs it.
  Rect trayBlock(int len) => Rect.fromLTWH(22, docket.bottom + 10, len * kM8PxH, 32);
  Rect trayGrab(int len) {
    final b = trayBlock(len);
    return Rect.fromCenter(center: b.center, width: math.max(b.width, 56), height: 48);
  }

  /// A block of [len] hours standing on [day] from [hour].
  Rect blockRect(int day, int hour, int len) => Rect.fromLTWH(hourX(hour), rowTop(day) + 3, len * kM8PxH, rowH - 6);

  /// Which strip (0–4) a finger at [y] is over; null off the board's strips.
  int? rowAt(double y) {
    final i = ((y - (top + 18)) / stride).floor();
    if (i < 0 || i >= kM8Days) return null;
    return (y - rowTop(i)) <= rowH + 4 ? i : null;
  }

  /// The confirm button's rough place (it is a HUD button; only the hand
  /// sweep uses this).
  Rect get confirmBtn => Rect.fromLTWH(16, height - inset - 14 - 54, 150, 54);

  // --- the notice sheet ---------------------------------------------------------
  static const double wheelW = 96;
  double get wheelTop => top + 70;
  static const double wheelH = 132;
  Rect wheel(int i) => Rect.fromLTWH(24 + i * (wheelW + 12), wheelTop, wheelW, wheelH);
  Offset get mic => Offset(180, wheelTop + wheelH + 56);
  static const double micR = 32;
  Rect get micHit => Rect.fromCircle(center: mic, radius: micR + 10);
  Rect get miniBoard => Rect.fromLTRB(4, top, 356, top + 52);
  Rect get miniStrip => Rect.fromLTRB(kM8StripL, top + 18, kM8StripR, top + 18 + 28);

  /// The miking auto's rest place (it drives off to the right).
  Rect get auto => Rect.fromLTWH(16, wheelTop + wheelH + 84, 78, 34);

  // --- the morning lane ---------------------------------------------------------
  Rect get clockChip => Rect.fromLTWH(8, top, 104, 28);
  Offset get pole => const Offset(318, top + 8);
  Rect get crew => Rect.fromLTWH(262, top + 6, 88, 96);
  Rect porch(int i) => Rect.fromLTWH(8 + i * 118, top + 132, 108, 100);
  Rect bubble(int i) => Rect.fromLTWH(8 + i * 118, top + 88, 108, 40);

  /// The two equal morning controls (HUD buttons; the hand sweep uses these).
  Rect get lever => Rect.fromLTWH(10, height - inset - 14 - 56, 116, 56);
  Rect get inform => Rect.fromLTWH(134, height - inset - 14 - 56, 116, 56);

  @override
  bool operator ==(Object other) => other is M8PlanGeo && other.height == height && other.inset == inset;

  @override
  int get hashCode => Object.hash(height, inset);
}

Paint _fill(Color c) => Paint()..color = c;
Paint _stroke(Color c, double w) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..color = c
  ..strokeCap = StrokeCap.round;

void _text(Canvas c, String text, Offset at,
    {double size = 11, Color color = const Color(0xFF1E2430), FontWeight weight = FontWeight.w800, double maxW = 140, Alignment align = Alignment.center}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: bangla(fontSize: size, fontWeight: weight, color: color, height: 1.15)),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
    maxLines: 2,
    ellipsis: '…',
  )..layout(maxWidth: maxW);
  tp.paint(c, at - Offset(tp.width * (align.x + 1) / 2, tp.height * (align.y + 1) / 2));
}

/// One day's label on the board.
@immutable
class M8DayLabel {
  const M8DayLabel(this.name, this.date);
  final String name;
  final String date;

  @override
  bool operator ==(Object other) => other is M8DayLabel && other.name == name && other.date == date;

  @override
  int get hashCode => Object.hash(name, date);
}

void _wall(Canvas c, Size size, double floor) {
  final r = Rect.fromLTWH(0, 0, size.width, size.height);
  c.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3A4A66), Color(0xFF26324A)]).createShader(r));
}

/// The hour numbers and ticks of one strip (every strip alike).
void _strip(Canvas c, Rect s, {bool numbers = true}) {
  c.drawRRect(RRect.fromRectAndRadius(s, const Radius.circular(4)), _fill(const Color(0xFFF7F4EA)));
  for (var h = 0; h <= 24; h++) {
    final x = kM8StripL + h * kM8PxH;
    final major = h % 3 == 0;
    c.drawLine(Offset(x, s.top), Offset(x, s.top + (major ? 7 : 4)), _stroke(const Color(0xFF8A8F99), major ? 1.1 : 0.7));
  }
  if (numbers) {
    for (var h = 0; h <= 24; h += 3) {
      _text(c, '$h', Offset(kM8StripL + h * kM8PxH, s.bottom - 7), size: 7.5, weight: FontWeight.w700, color: const Color(0xFF5C6370), maxW: 20);
    }
  }
  c.drawRRect(RRect.fromRectAndRadius(s, const Radius.circular(4)), _stroke(const Color(0xFFB9B4A3), 1));
}

void _block(Canvas c, Rect r, int len, {bool lifted = false}) {
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(5));
  if (lifted) c.drawRRect(rr.shift(const Offset(0, 4)), _fill(const Color(0x66000000)));
  c.drawRRect(
      rr,
      Paint()
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3E6FB8), Color(0xFF244B86)]).createShader(r));
  c.drawRRect(rr, _stroke(const Color(0xFFD9E4F7), 1.2));
  _text(c, '$len', r.center, size: 12, color: Colors.white, maxW: math.max(r.width, 12));
}

// ============================================================================
// The planner
// ============================================================================

/// The planner board, the docket and the block in its tray. [block]: the
/// placed block's (day, hour), or null while it is in the tray; [drag]: the
/// finger while the block is held (the block follows it when it is not over
/// a strip); [readout]: its times only.
class M8PlanBoardPainter extends CustomPainter {
  const M8PlanBoardPainter({
    required this.geo,
    required this.days,
    required this.nowMin,
    required this.len,
    required this.docket,
    this.block,
    this.drag,
    this.readout,
  });

  final M8PlanGeo geo;
  final List<M8DayLabel> days;

  /// 'এখন', minutes from the first day's midnight.
  final double nowMin;
  final int len;
  final List<String> docket;
  final (int, int)? block;
  final Offset? drag;
  final String? readout;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    _wall(c, size, g.height);
    // The magnetic board.
    final b = RRect.fromRectAndRadius(g.board, const Radius.circular(10));
    c.drawRRect(b.shift(const Offset(0, 3)), _fill(const Color(0x55000000)));
    c.drawRRect(b, _fill(const Color(0xFFE8E4D6)));
    c.drawRRect(b, _stroke(const Color(0xFF7C8594), 2.4));
    for (var d = 0; d < kM8Days; d++) {
      final lab = g.dayLabel(d);
      _text(c, days[d].name, Offset(lab.center.dx, lab.top + lab.height * 0.32), size: 11, maxW: lab.width);
      _text(c, days[d].date, Offset(lab.center.dx, lab.top + lab.height * 0.72), size: 10, weight: FontWeight.w700, color: const Color(0xFF4A5160), maxW: lab.width);
      _strip(c, g.strip(d));
    }
    // 'এখন': a red magnet on the first day at the dealt time.
    final nx = g.hourX(nowMin / 60);
    final s0 = g.strip(0);
    c.drawLine(Offset(nx, s0.top - 3), Offset(nx, s0.bottom), _stroke(const Color(0xFFD63A32), 1.6));
    final tag = Rect.fromCenter(center: Offset(nx, s0.top - 3), width: 34, height: 15);
    c.drawRRect(RRect.fromRectAndRadius(tag, const Radius.circular(7)), _fill(const Color(0xFFD63A32)));
    _text(c, 'এখন', tag.center, size: 9, color: Colors.white, maxW: 40);
    // The docket on its clip.
    final dk = RRect.fromRectAndRadius(g.docket, const Radius.circular(6));
    c.drawRRect(dk.shift(const Offset(0, 2)), _fill(const Color(0x55000000)));
    c.drawRRect(dk, _fill(const Color(0xFFFBF1C9)));
    c.drawRRect(dk, _stroke(const Color(0xFFB59B4A), 1.2));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(g.docket.left + 14, g.docket.top - 6, 36, 12), const Radius.circular(3)), _fill(const Color(0xFF6A7380)));
    for (var i = 0; i < docket.length; i++) {
      _text(c, docket[i], Offset(g.docket.left + 10, g.docket.top + 14 + i * 17), size: i == 0 ? 11.5 : 10.5, maxW: g.docket.width - 16, align: Alignment.centerLeft);
    }
    // The tray.
    final tray = g.trayBlock(len);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(6, tray.top - 6, 252, tray.bottom + 6), const Radius.circular(8)), _fill(const Color(0xFF1C2638)));
    if (block == null && drag == null) _block(c, tray, len);
    // A placed block.
    final bl = block;
    if (bl != null) _block(c, g.blockRect(bl.$1, bl.$2, len), len);
    // A held block: over a strip it stands snapped there (drawn above), else it follows the finger.
    final dr = drag;
    if (dr != null) {
      if (bl == null) {
        final r = Rect.fromCenter(center: dr, width: len * kM8PxH, height: 32);
        _block(c, r, len, lifted: true);
      }
      final ro = readout;
      if (ro != null && bl != null) {
        final r = g.blockRect(bl.$1, bl.$2, len);
        _readoutChip(c, ro, r, size);
      }
    }
  }

  void _readoutChip(Canvas c, String text, Rect at, Size size) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: bangla(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white, height: 1.1)),
      textDirection: TextDirection.ltr,
    )..layout();
    final w = tp.width + 18;
    final x = (at.center.dx - w / 2).clamp(6.0, size.width - w - 6);
    final y = at.top - 28;
    final chip = RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, 24), const Radius.circular(8));
    c.drawRRect(chip, _fill(const Color(0xF2101828)));
    c.drawRRect(chip, _stroke(SlmColors.gold300, 1.2));
    tp.paint(c, Offset(x + 9, y + 12 - tp.height / 2));
  }

  @override
  bool shouldRepaint(M8PlanBoardPainter o) =>
      o.geo != geo || !identical(o.days, days) || o.nowMin != nowMin || o.len != len || o.block != block || o.drag != drag || o.readout != readout || !identical(o.docket, docket);
}

// ============================================================================
// The notice sheet
// ============================================================================

/// One wheel's three visible values (the middle one is picked).
@immutable
class M8WheelFace {
  const M8WheelFace(this.caption, this.prev, this.now, this.next);
  final String caption;
  final String prev;
  final String now;
  final String next;

  @override
  bool operator ==(Object other) => other is M8WheelFace && other.caption == caption && other.prev == prev && other.now == now && other.next == next;

  @override
  int get hashCode => Object.hash(caption, prev, now, next);
}

/// The notice sheet: the board's day row with the placed block, the miking
/// script's three wheels, the mic's hold ring and the auto. [drive] 0 = parked,
/// 1 = gone; [hold] = the mic ring's fill (0–1); both repaint this layer only.
class M8NoticePainter extends CustomPainter {
  M8NoticePainter({
    required this.geo,
    required this.day,
    required this.dayIndex,
    required this.startHour,
    required this.len,
    required this.wheels,
    required this.drive,
    required this.hold,
  }) : super(repaint: Listenable.merge([drive, hold]));

  final M8PlanGeo geo;
  final M8DayLabel day;
  final int dayIndex;
  final int startHour;
  final int len;
  final List<M8WheelFace> wheels;
  final Animation<double> drive;
  final Animation<double> hold;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    _wall(c, size, g.height);
    // The board's row for this job.
    final mb = RRect.fromRectAndRadius(g.miniBoard, const Radius.circular(10));
    c.drawRRect(mb, _fill(const Color(0xFFE8E4D6)));
    c.drawRRect(mb, _stroke(const Color(0xFF7C8594), 2.2));
    _text(c, day.name, Offset(30, g.miniStrip.top + 8), size: 11, maxW: 44);
    _text(c, day.date, Offset(30, g.miniStrip.top + 21), size: 10, weight: FontWeight.w700, color: const Color(0xFF4A5160), maxW: 44);
    final s = g.miniStrip;
    _strip(c, s);
    _block(c, Rect.fromLTWH(g.hourX(startHour), s.top + 3, len * kM8PxH, s.height - 6), len);
    // The script card with its wheels.
    final card = Rect.fromLTRB(10, g.wheelTop - 26, 350, g.wheelTop + M8PlanGeo.wheelH + 8);
    final cr = RRect.fromRectAndRadius(card, const Radius.circular(12));
    c.drawRRect(cr.shift(const Offset(0, 3)), _fill(const Color(0x55000000)));
    c.drawRRect(cr, _fill(const Color(0xFFFBF1C9)));
    c.drawRRect(cr, _stroke(const Color(0xFFB59B4A), 1.4));
    for (var i = 0; i < 3; i++) {
      final w = g.wheel(i);
      final f = wheels[i];
      _text(c, f.caption, Offset(w.center.dx, card.top + 11), size: 10.5, color: const Color(0xFF5A4A1C), maxW: w.width);
      c.drawRRect(RRect.fromRectAndRadius(w, const Radius.circular(10)), _fill(const Color(0xFF1C2638)));
      final mid = Rect.fromLTWH(w.left + 4, w.top + w.height / 3, w.width - 8, w.height / 3);
      c.drawRRect(RRect.fromRectAndRadius(mid, const Radius.circular(8)), _fill(const Color(0xFF2D4670)));
      c.drawRRect(RRect.fromRectAndRadius(mid, const Radius.circular(8)), _stroke(SlmColors.gold300, 1.4));
      _text(c, f.prev, Offset(w.center.dx, w.top + w.height / 6), size: 12, weight: FontWeight.w600, color: const Color(0x88FFFFFF), maxW: w.width - 6);
      _text(c, f.now, mid.center, size: 15, color: Colors.white, maxW: w.width - 8);
      _text(c, f.next, Offset(w.center.dx, w.bottom - w.height / 6), size: 12, weight: FontWeight.w600, color: const Color(0x88FFFFFF), maxW: w.width - 6);
    }
    // The mic with its hold ring.
    final m = g.mic;
    c.drawCircle(m, M8PlanGeo.micR, _fill(const Color(0xFF1C2638)));
    c.drawCircle(m, M8PlanGeo.micR, _stroke(SlmColors.gold300, 2));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: m.translate(0, -5), width: 14, height: 22), const Radius.circular(7)), _fill(const Color(0xFFE9EEF7)));
    c.drawArc(Rect.fromCenter(center: m.translate(0, -3), width: 24, height: 22), 0, math.pi, false, _stroke(const Color(0xFFE9EEF7), 2));
    c.drawLine(m.translate(0, 8), m.translate(0, 14), _stroke(const Color(0xFFE9EEF7), 2));
    if (hold.value > 0) {
      c.drawArc(Rect.fromCircle(center: m, radius: M8PlanGeo.micR + 6), -math.pi / 2, 2 * math.pi * hold.value, false, _stroke(const Color(0xFF7EE08F), 4));
    }
    // The miking auto: parked, then driving off to the right.
    final x = g.auto.left + drive.value * (size.width + 40 - g.auto.left);
    _auto(c, Rect.fromLTWH(x, g.auto.top, g.auto.width, g.auto.height));
  }

  void _auto(Canvas c, Rect r) {
    final body = RRect.fromRectAndRadius(Rect.fromLTWH(r.left, r.top + 6, r.width, r.height - 14), const Radius.circular(6));
    c.drawRRect(body, _fill(const Color(0xFF2E8B57)));
    c.drawRRect(body, _stroke(const Color(0xFF14543A), 1.2));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.left + 4, r.top, r.width - 14, 9), const Radius.circular(4)), _fill(const Color(0xFF2B3A55)));
    c.drawCircle(Offset(r.left + 14, r.bottom - 4), 7, _fill(const Color(0xFF111111)));
    c.drawCircle(Offset(r.right - 14, r.bottom - 4), 7, _fill(const Color(0xFF111111)));
    // The loudspeaker horn on the roof.
    final horn = Path()
      ..moveTo(r.left + 20, r.top - 3)
      ..lineTo(r.left + 34, r.top - 12)
      ..lineTo(r.left + 34, r.top + 2)
      ..close();
    c.drawPath(horn, _fill(const Color(0xFFD9DEE8)));
    c.drawRect(Rect.fromLTWH(r.left + 14, r.top - 4, 7, 6), _fill(const Color(0xFF8E96A6)));
  }

  @override
  bool shouldRepaint(M8NoticePainter o) =>
      o.geo != geo || o.dayIndex != dayIndex || o.startHour != startHour || o.len != len || !identical(o.wheels, wheels) || o.day != day || o.drive != drive || o.hold != hold;
}

// ============================================================================
// The morning lane
// ============================================================================

/// What a porch's bubble shows (silent caption figures, ruling M8-10).
@immutable
class M8PorchView {
  const M8PorchView({required this.name, this.caption});
  final String name;
  final String? caption;

  @override
  bool operator ==(Object other) => other is M8PorchView && other.name == name && other.caption == caption;

  @override
  int get hashCode => Object.hash(name, caption);
}

/// The village lane on the shutdown morning: three porches with a family on
/// each (and a para's name board), the crew at the pole, the clock chip.
/// [off]: the shutdown is done (the windows dark).
class M8LanePainter extends CustomPainter {
  const M8LanePainter({required this.geo, required this.porches, required this.clock, required this.off, required this.informed});

  final M8PlanGeo geo;
  final List<M8PorchView> porches;
  final String clock;
  final bool off;

  /// Porches the crew has told (a small tick on their bubble).
  final Set<int> informed;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final sky = Rect.fromLTWH(0, 0, size.width, g.porch(0).bottom + 40);
    c.drawRect(
        sky,
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8DB8E8), Color(0xFFF2D9A6)]).createShader(sky));
    final ground = Rect.fromLTWH(0, g.porch(0).bottom + 8, size.width, size.height);
    c.drawRect(ground, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8A7A5C), Color(0xFF4F4430)]).createShader(ground));
    // The pole, its crossarm and a wire along the lane, and the crew at its foot.
    final p = g.pole;
    c.drawLine(Offset(p.dx, p.dy), Offset(p.dx, g.porch(0).bottom + 8), _stroke(const Color(0xFF5B4630), 6));
    c.drawLine(Offset(p.dx - 26, p.dy + 8), Offset(p.dx + 26, p.dy + 8), _stroke(const Color(0xFF5B4630), 4));
    c.drawLine(Offset(0, p.dy + 18), Offset(p.dx - 24, p.dy + 10), _stroke(const Color(0xFF2A2F3A), 1.4));
    _crew(c, g.crew);
    // The porches.
    for (var i = 0; i < 3; i++) {
      _porch(c, g.porch(i), porches[i]);
      _bubble(c, g.bubble(i), porches[i].caption, informed.contains(i));
    }
    // The clock chip.
    final cc = RRect.fromRectAndRadius(g.clockChip, const Radius.circular(10));
    c.drawRRect(cc, _fill(const Color(0xF2101828)));
    c.drawRRect(cc, _stroke(SlmColors.gold300, 1.2));
    _text(c, clock, g.clockChip.center, size: 14, color: Colors.white, maxW: g.clockChip.width);
  }

  void _crew(Canvas c, Rect r) {
    for (var k = 0; k < 2; k++) {
      final x = r.left + 20 + k * 30;
      c.drawCircle(Offset(x, r.bottom - 52), 8, _fill(const Color(0xFFE0B48A)));
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 9, r.bottom - 44, 18, 26), const Radius.circular(5)), _fill(k == 0 ? const Color(0xFF2F5D9E) : const Color(0xFF9E5A2F)));
      c.drawRect(Rect.fromLTWH(x - 7, r.bottom - 18, 6, 16), _fill(const Color(0xFF2A2F3A)));
      c.drawRect(Rect.fromLTWH(x + 1, r.bottom - 18, 6, 16), _fill(const Color(0xFF2A2F3A)));
      c.drawArc(Rect.fromCenter(center: Offset(x, r.bottom - 55), width: 18, height: 12), math.pi, math.pi, true, _fill(const Color(0xFFF2C230)));
    }
  }

  void _porch(Canvas c, Rect r, M8PorchView v) {
    final wall = RRect.fromRectAndRadius(r, const Radius.circular(6));
    c.drawRRect(wall, _fill(const Color(0xFFD9C9A4)));
    c.drawRRect(wall, _stroke(const Color(0xFF8A7458), 1.4));
    // The roof over the porch.
    final roof = Path()
      ..moveTo(r.left - 6, r.top + 6)
      ..lineTo(r.left + r.width / 2, r.top - 16)
      ..lineTo(r.right + 6, r.top + 6)
      ..close();
    c.drawPath(roof, _fill(const Color(0xFF7A3B2A)));
    // Windows: lit, dark once the shutdown is done.
    for (var k = 0; k < 2; k++) {
      final w = Rect.fromLTWH(r.left + 10 + k * 56, r.top + 14, 34, 26);
      c.drawRect(w, _fill(off ? const Color(0xFF232A3C) : const Color(0xFFFFE9A8)));
      c.drawRect(w, _stroke(const Color(0xFF6E5A44), 1.2));
    }
    // A family group on the porch step.
    for (var k = 0; k < 3; k++) {
      final x = r.left + 24 + k * 30;
      final h = k == 1 ? 26.0 : 34.0;
      c.drawCircle(Offset(x, r.bottom - h - 14), 7, _fill(const Color(0xFFE0B48A)));
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 8, r.bottom - h - 7, 16, h), const Radius.circular(5)), _fill([const Color(0xFF8E3B6B), const Color(0xFF3B8E6B), const Color(0xFF3B5E8E)][k]));
    }
    // The para's name board.
    final nb = Rect.fromLTWH(r.left + 2, r.bottom - 2, r.width - 4, 18);
    c.drawRRect(RRect.fromRectAndRadius(nb, const Radius.circular(4)), _fill(const Color(0xFF2B3A55)));
    _text(c, v.name, nb.center, size: 10, color: Colors.white, maxW: nb.width - 4);
  }

  void _bubble(Canvas c, Rect r, String? caption, bool informed) {
    if (caption == null) return;
    final b = RRect.fromRectAndRadius(r, const Radius.circular(10));
    c.drawRRect(b, _fill(const Color(0xFFFFFFFF)));
    c.drawRRect(b, _stroke(informed ? const Color(0xFF2E9E5B) : const Color(0xFF8A8F99), informed ? 2 : 1.2));
    final tail = Path()
      ..moveTo(r.center.dx - 6, r.bottom)
      ..lineTo(r.center.dx, r.bottom + 7)
      ..lineTo(r.center.dx + 6, r.bottom)
      ..close();
    c.drawPath(tail, _fill(const Color(0xFFFFFFFF)));
    _text(c, caption, r.center, size: 10.5, maxW: r.width - 10);
  }

  @override
  bool shouldRepaint(M8LanePainter o) => o.geo != geo || !identical(o.porches, porches) || o.clock != clock || o.off != off || o.informed.length != informed.length;
}
