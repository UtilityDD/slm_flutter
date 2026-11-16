import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

// The drawn world of lesson 8.2 কাজ "দিন গুনুন, তারপর কাটুন"
// (m8_notice_calendar.dart): a morning residential lane, three houses one at a
// time. Each house hands the trainee a paper (the docket) with plain dates; a
// paper wall calendar hangs below it. Live-line houses (arrears) use a rolling
// ten-week month grid (Sunday first); cut-line houses use a 12-month year
// planner (a row a month, a column a day) so the long spans fit. Only 'আজ' is
// printed on a cell; nothing marks a docket date, a 15th or a 180th day.
//
// Words a worker reads are painted (month names, week days, 'আজ'); no brand,
// no logo (M8-11): generic papers, a generic van crate.
//
// Design: 360 wide x the scene's height. The guide stands at the bottom right
// (its bubble just above) and the tiles at the bottom left, so every panel
// ends above [M8Geo.guideTop].

/// The six houses a play can be dealt (three of them a play).
enum M8Kind {
  /// Arrears, a written notice 3-10 days ago: hold.
  shortNotice,

  /// Arrears, a written notice 20-40 days ago: cut.
  longNotice,

  /// Arrears, only told by mouth: hold whatever the count.
  noNotice,

  /// Line cut 40-120 days ago, the consumer pleading or with a part / no-charge
  /// receipt: hold.
  recentCut,

  /// Line cut 200-290 days ago, nothing paid: dismantle.
  oldCut,

  /// Line cut earlier, dues and reconnection charge paid in full: reconnect.
  paidCut,
}

/// A decision tile (and the right answer of a house).
enum M8Tile { cut, hold, reconnect, dismantle }

/// What the consumer's receipt shows (none = no paper in hand).
enum M8Receipt { none, part, chargeBlank, full }

/// The lines of a docket.
enum M8Label { bill, notice, spoken, cut, reading }

bool m8Live(M8Kind k) => k == M8Kind.shortNotice || k == M8Kind.longNotice || k == M8Kind.noNotice;

M8Tile m8Answer(M8Kind k) => switch (k) {
      M8Kind.shortNotice || M8Kind.noNotice || M8Kind.recentCut => M8Tile.hold,
      M8Kind.longNotice => M8Tile.cut,
      M8Kind.oldCut => M8Tile.dismantle,
      M8Kind.paidCut => M8Tile.reconnect,
    };

/// One house: its dates (all inside the calendar it uses), receipt, meter.
@immutable
class M8House {
  const M8House({
    required this.kind,
    required this.today,
    required this.bill,
    required this.reading,
    required this.order,
    required this.meter,
    required this.sealIntact,
    this.notice,
    this.cut,
    this.receipt = M8Receipt.none,
    this.due = 0,
    this.paid = 0,
    this.receiptNo = 0,
    this.wall = 0,
  });

  final M8Kind kind;
  final DateTime today;
  final DateTime bill;
  final DateTime reading;

  /// The written notice (null = only told by mouth, or not a notice house).
  final DateTime? notice;

  /// The date the line was cut (cut houses).
  final DateTime? cut;
  final M8Receipt receipt;
  final int due;
  final int paid;
  final int receiptNo;

  /// The docket's lines in the order they are printed.
  final List<M8Label> order;

  /// The meter's 5-digit counter and the seal.
  final List<int> meter;
  final bool sealIntact;
  final int wall;

  bool get live => m8Live(kind);
  bool get planner => !live;
  M8Tile get answer => m8Answer(kind);
  bool get hasReceipt => receipt != M8Receipt.none;

  /// Tiles for this house (live line vs cut line only).
  List<M8Tile> get tiles => live ? const [M8Tile.cut, M8Tile.hold] : const [M8Tile.reconnect, M8Tile.dismantle, M8Tile.hold];

  int daysAgo(DateTime d) => today.difference(d).inDays;

  DateTime? dateOf(M8Label l) => switch (l) {
        M8Label.bill => bill,
        M8Label.notice => notice,
        M8Label.cut => cut,
        M8Label.reading => reading,
        M8Label.spoken => null,
      };

  /// Every date the docket prints.
  List<DateTime> get docketDates => [for (final l in order) ?dateOf(l)];

  /// The meter counter as the 5 digits one reads.
  String get counter => meter.join();
}

/// The three houses of a play.
@immutable
class M8Deal {
  const M8Deal({
    required this.today,
    required this.houses,
    required this.hisHouse,
    required this.crateLeft,
    required this.tileOrder,
    required this.noteWhy,
    required this.light,
  });

  final DateTime today;
  final List<M8House> houses;

  /// The house the coworker comes at (a hold house, a reconnection house or a
  /// no-notice house: the ones whose myth he can push).
  final int hisHouse;

  /// Per house: the store crate stands on the left (the verandah on the right).
  final List<bool> crateLeft;

  /// Per house: the tiles in their dealt order.
  final List<List<M8Tile>> tileOrder;

  /// Per house: a cut asks about the note instead of the cut (alternating).
  final List<bool> noteWhy;
  final int light;
}

const kM8Months = ['জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন', 'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'];
const kM8MonthsShort = ['জানু', 'ফেব্রু', 'মার্চ', 'এপ্রি', 'মে', 'জুন', 'জুলাই', 'আগ', 'সেপ্টে', 'অক্টো', 'নভে', 'ডিসে'];
const kM8Dow = ['রবি', 'সোম', 'মঙ্গল', 'বুধ', 'বৃহ', 'শুক্র', 'শনি'];

/// The morning light of the lane (sky top, sky bottom, ground).
const kM8Skies = <(Color, Color, Color)>[
  (Color(0xFF8EC3E6), Color(0xFFFFE9C2), Color(0xFF8E9A78)),
  (Color(0xFFA9C7E0), Color(0xFFF4F0E4), Color(0xFF9AA08C)),
  (Color(0xFF7FA9D6), Color(0xFFFFD9B0), Color(0xFF8A8F72)),
];

const kM8Walls = [Color(0xFFE9D9B8), Color(0xFFD6E4D2), Color(0xFFE6C9C0)];

DateTime _utc(DateTime d) => DateTime.utc(d.year, d.month, d.day);

/// The Sunday that opens the rolling ten-week grid (today's week is the last).
DateTime m8GridStart(DateTime today) => _utc(today).subtract(Duration(days: today.weekday % 7 + 63));

/// The first of the oldest month of the year planner (12 months to today's).
DateTime m8PlannerStart(DateTime today) => DateTime.utc(today.year, today.month - 11, 1);

int _dim(int y, int m) => DateUtils.getDaysInMonth(y, m);

/// '12 মে' (English digits, the month in Bangla).
String m8DateText(DateTime d) => '${d.day} ${kM8Months[d.month - 1]}';

M8House m8DealHouse(M8Kind k, DateTime today, math.Random rng) {
  DateTime ago(int n) => _utc(today).subtract(Duration(days: n));
  int between(int a, int b) => a + rng.nextInt(b - a + 1);
  final order = [...(m8Live(k) ? [M8Label.bill, k == M8Kind.noNotice ? M8Label.spoken : M8Label.notice, M8Label.reading] : [M8Label.bill, M8Label.notice, M8Label.cut, M8Label.reading])]..shuffle(rng);
  final meter = [for (var i = 0; i < 5; i++) rng.nextInt(10)];
  final seal = rng.nextBool();
  final wall = rng.nextInt(kM8Walls.length);
  final due = 10 * between(150, 940);
  switch (k) {
    case M8Kind.shortNotice:
      final n = between(3, 10);
      // The bill date is always earlier, so a count from it overshoots (18+).
      final b = between(18, 32);
      return M8House(kind: k, today: today, bill: ago(b), notice: ago(n), reading: ago(_readDays(rng, n)), order: order, meter: meter, sealIntact: seal, wall: wall);
    case M8Kind.longNotice:
      final n = between(20, 40);
      final b = n + between(5, 20);
      return M8House(kind: k, today: today, bill: ago(b), notice: ago(n), reading: ago(_readDays(rng, n)), order: order, meter: meter, sealIntact: seal, wall: wall);
    case M8Kind.noNotice:
      final b = between(20, 45);
      return M8House(kind: k, today: today, bill: ago(b), reading: ago(_readDays(rng, -1)), order: order, meter: meter, sealIntact: seal, wall: wall);
    case M8Kind.recentCut || M8Kind.oldCut || M8Kind.paidCut:
      final c = switch (k) {
        M8Kind.recentCut => between(40, 120),
        M8Kind.oldCut => between(200, 290),
        _ => between(40, 130),
      };
      final n = c + between(18, 22);
      final b = n + between(5, 20);
      final r = rng.nextInt(3);
      final receipt = switch (k) {
        M8Kind.paidCut => M8Receipt.full,
        M8Kind.recentCut => [M8Receipt.none, M8Receipt.part, M8Receipt.chargeBlank][r],
        _ => M8Receipt.none,
      };
      final paid = switch (receipt) {
        M8Receipt.none => 0,
        M8Receipt.part => 10 * (((due * (0.35 + 0.3 * rng.nextDouble())) / 10).round()),
        _ => due,
      };
      return M8House(
        kind: k,
        today: today,
        bill: ago(b),
        notice: ago(n),
        cut: ago(c),
        reading: ago(c + between(2, 9)),
        order: order,
        meter: meter,
        sealIntact: seal,
        receipt: receipt,
        due: due,
        paid: paid,
        receiptNo: between(1000, 9999),
        wall: wall,
      );
  }
}

int _readDays(math.Random rng, int not) {
  var d = 1 + rng.nextInt(12);
  if (d == not) d = d == 12 ? 11 : d + 1;
  return d;
}

/// Acts: cut, dismantle, reconnect. Holds: the other three.
bool m8IsAct(M8Kind k) => m8Answer(k) != M8Tile.hold;

/// The kinds whose myth the coworker can push.
bool m8HisKind(M8Kind k) => k == M8Kind.shortNotice || k == M8Kind.noNotice || k == M8Kind.recentCut || k == M8Kind.paidCut;

M8Deal m8DealPlay(math.Random rng) {
  final today = DateTime.utc(2026, 1, 1).add(Duration(days: 60 + rng.nextInt(280)));
  List<M8Kind> pick() {
    final all = [...M8Kind.values]..shuffle(rng);
    return all.take(3).toList();
  }

  var kinds = pick();
  while (!kinds.any(m8IsAct) || kinds.every(m8IsAct)) {
    kinds = pick();
  }
  final houses = [for (final k in kinds) m8DealHouse(k, today, rng)];
  final eligible = [for (var i = 0; i < 3; i++) if (m8HisKind(kinds[i])) i];
  return M8Deal(
    today: today,
    houses: houses,
    hisHouse: eligible[rng.nextInt(eligible.length)],
    crateLeft: [for (var i = 0; i < 3; i++) rng.nextBool()],
    tileOrder: [for (final h in houses) ([...h.tiles]..shuffle(rng))],
    noteWhy: [for (var i = 0; i < 3; i++) rng.nextBool()],
    light: rng.nextInt(kM8Skies.length),
  );
}

/// Where things are (design px, 360 wide).
@immutable
class M8Geo {
  const M8Geo._(this.height, this.inset);

  factory M8Geo.forScene(double height, double inset) => M8Geo._(height, inset);

  final double height;

  /// The bottom system inset in design px.
  final double inset;

  static const double top = 112;
  static const double guideZone = 172;
  static const double calH = 214;
  static const double calHead = 16;
  static const double docketH = 62;
  static const double tileH = 56;
  static const double planLabelW = 44;
  static const int gridRows = 10;

  double get bottom => height - inset;

  /// Every panel ends here; the guide's bubble and sprite stand below.
  double get guideTop => bottom - guideZone;

  /// The guide's bubble (parts stay clear of it) and sprite.
  Rect get bubble => Rect.fromLTRB(128, guideTop + 2, 360, guideTop + 58);
  Rect get guide => Rect.fromLTRB(244, bottom - 118, 360, bottom);

  // --- measuring stage ----------------------------------------------------
  Rect get cal => Rect.fromLTWH(6, guideTop - calH, 348, calH);
  Rect get docket => Rect.fromLTWH(6, cal.top - docketH - 4, 248, docketH);
  Rect get receiptIcon => Rect.fromLTWH(260, docket.top, 94, 28);
  Rect get countChip => Rect.fromLTWH(260, docket.top + 32, 94, 30);

  /// The pinned paper before it is opened.
  Rect get closedDocket => Rect.fromCenter(center: Offset(180, guideTop - 108), width: 88, height: 104);

  /// The open receipt card.
  Rect get receiptCard => Rect.fromLTWH(30, cal.top + 20, 300, 150);

  /// Decision tiles (equal size; the row sits left of the guide).
  Rect tile(int i, int n) {
    final tw = n == 2 ? 112.0 : 72.0;
    return Rect.fromLTWH(6 + i * (tw + 8), bottom - tileH - 6, tw, tileH);
  }

  // --- notebook stage -------------------------------------------------------
  static const double nbH = 158;
  Rect get notebook => Rect.fromLTWH(6, guideTop - nbH, 348, nbH);
  Rect wheel(int i) => Rect.fromLTWH(18.0 + i * 44, notebook.top + 28, 40, 66);
  Rect get chipOk => Rect.fromLTWH(246, notebook.top + 30, 102, 32);
  Rect get chipBroken => Rect.fromLTWH(246, notebook.top + 68, 102, 32);
  Rect get noteBtn => Rect.fromLTWH(18, notebook.top + 106, 328, 44);
  Rect get meterBox => Rect.fromLTWH(22, notebook.top - 108, 156, 96);
  Rect get discBtn => Rect.fromLTWH(206, notebook.top - 108, 130, 96);

  // --- dismantle stage ------------------------------------------------------
  double get itemsTop => guideTop - 232;
  Rect get meterItem => Rect.fromLTWH(66, itemsTop, 92, 66);
  Rect get coilItem => Rect.fromLTWH(206, itemsTop, 92, 66);

  /// The two drop pads (0 = left, 1 = right), equal size.
  Rect pad(int i) => Rect.fromLTWH(i == 0 ? 6 : 204, guideTop - 104, 150, 96);

  // --- the calendar -------------------------------------------------------
  double get _rowH => (calH - calHead) / (gridRows);
  double get _cellW => cal.width / 7;
  double get _planRowH => (calH - calHead) / 12;
  double get _planColW => (cal.width - planLabelW) / 31;

  /// Where a date sits on the calendar [h] uses (null = outside it).
  Rect? dateRect(M8House h, DateTime d) {
    final day = _utc(d);
    if (h.planner) {
      final s = m8PlannerStart(h.today);
      final row = (day.year - s.year) * 12 + day.month - s.month;
      if (row < 0 || row > 11) return null;
      return Rect.fromLTWH(cal.left + planLabelW + (day.day - 1) * _planColW, cal.top + calHead + row * _planRowH, _planColW, _planRowH);
    }
    final off = day.difference(m8GridStart(h.today)).inDays;
    if (off < 0 || off >= gridRows * 7) return null;
    return Rect.fromLTWH(cal.left + (off % 7) * _cellW, cal.top + calHead + (off ~/ 7) * _rowH, _cellW, _rowH);
  }

  Rect todayRect(M8House h) => dateRect(h, h.today)!;

  /// The date under a point (null = no date cell there).
  DateTime? dateAt(M8House h, Offset p) {
    if (!cal.contains(p) || p.dy < cal.top + calHead) return null;
    if (h.planner) {
      final s = m8PlannerStart(h.today);
      final row = ((p.dy - cal.top - calHead) / _planRowH).floor();
      final col = ((p.dx - cal.left - planLabelW) / _planColW).floor();
      if (row < 0 || row > 11 || col < 0 || col > 30) return null;
      final m = DateTime.utc(s.year, s.month + row, 1);
      if (col + 1 > _dim(m.year, m.month)) return null;
      return DateTime.utc(m.year, m.month, col + 1);
    }
    final row = ((p.dy - cal.top - calHead) / _rowH).floor();
    final col = ((p.dx - cal.left) / _cellW).floor();
    if (row < 0 || row >= gridRows || col < 0 || col > 6) return null;
    return m8GridStart(h.today).add(Duration(days: row * 7 + col));
  }

  /// A cell near the middle of the calendar that is no docket date and not in
  /// today's row (the drag hand starts here and runs along the row).
  Offset hintCell(M8House h) {
    final dates = {for (final d in h.docketDates) _utc(d)};
    final rows = h.planner ? [5, 4, 6, 3] : [4, 3, 5, 2];
    final cols = h.planner ? [13, 12, 14, 11, 15] : [3, 2, 4, 1, 5];
    for (final r in rows) {
      for (final c in cols) {
        final p = h.planner
            ? Offset(cal.left + planLabelW + (c + 0.5) * _planColW, cal.top + calHead + (r + 0.5) * _planRowH)
            : Offset(cal.left + (c + 0.5) * _cellW, cal.top + calHead + (r + 0.5) * _rowH);
        final d = dateAt(h, p);
        if (d != null && !dates.contains(d)) return p;
      }
    }
    return cal.center;
  }
}

// ============================================================================
// Painters
// ============================================================================

/// The lane behind everything: sky, far houses, this house's wall, the ground.
class M8BackPainter extends CustomPainter {
  const M8BackPainter({required this.geo, required this.light, required this.wall, required this.consumer});

  final M8Geo geo;
  final int light;
  final int wall;

  /// A consumer stands at the door (cut houses).
  final bool consumer;

  @override
  void paint(Canvas c, Size size) {
    final (skyTop, skyBot, ground) = kM8Skies[light % kM8Skies.length];
    final h = geo.height;
    c.drawRect(Rect.fromLTWH(0, 0, 360, h), Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [skyTop, skyBot]).createShader(Rect.fromLTWH(0, 0, 360, h * 0.6)));
    c.drawCircle(Offset(310, 142), 18, Paint()..color = const Color(0x66FFF3C4));
    // Far houses along the lane.
    final far = Paint()..color = const Color(0xFF9FB0BF);
    final gy = geo.guideTop - 6;
    for (var i = 0; i < 4; i++) {
      final x = -10.0 + i * 98;
      c.drawRect(Rect.fromLTWH(x, gy - 90 - (i % 2) * 14, 70, 90 + (i % 2) * 14), far);
      c.drawPath(Path()..moveTo(x - 4, gy - 90 - (i % 2) * 14)..lineTo(x + 35, gy - 112 - (i % 2) * 14)..lineTo(x + 74, gy - 90 - (i % 2) * 14)..close(), Paint()..color = const Color(0xFF8798A8));
    }
    // This house.
    final wallTop = math.max(M8Geo.top + 30, gy - 230);
    final wallRect = Rect.fromLTRB(14, wallTop, 346, gy);
    c.drawRect(wallRect, Paint()..color = kM8Walls[wall % kM8Walls.length]);
    c.drawPath(
      Path()..moveTo(6, wallTop)..lineTo(180, wallTop - 34)..lineTo(354, wallTop)..close(),
      Paint()..color = const Color(0xFF8A5A44),
    );
    // Window and door.
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(212, wallTop + 22, 58, 52), const Radius.circular(4)), Paint()..color = const Color(0xFF6C8CA8));
    c.drawRect(Rect.fromLTWH(212, wallTop + 22, 58, 52), Paint()..color = const Color(0x00000000)..style = PaintingStyle.stroke);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(290, gy - 96, 44, 96), const Radius.circular(3)), Paint()..color = const Color(0xFF6B4A36));
    if (consumer) {
      // A consumer at the door: head, body (silent; no caption).
      c.drawCircle(Offset(268, gy - 76), 9, Paint()..color = const Color(0xFFD9B08C));
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(258, gy - 66, 20, 46), const Radius.circular(6)), Paint()..color = const Color(0xFF5B6E8C));
      c.drawRect(Rect.fromLTWH(260, gy - 20, 7, 20), Paint()..color = const Color(0xFF3A3F4A));
      c.drawRect(Rect.fromLTWH(269, gy - 20, 7, 20), Paint()..color = const Color(0xFF3A3F4A));
    }
    // The lane.
    c.drawRect(Rect.fromLTRB(0, gy, 360, h), Paint()..color = ground);
    c.drawRect(Rect.fromLTRB(0, gy, 360, gy + 6), Paint()..color = const Color(0x33000000));
  }

  @override
  bool shouldRepaint(M8BackPainter old) => old.light != light || old.wall != wall || old.consumer != consumer || old.geo.height != geo.height || old.geo.inset != geo.inset;
}

TextPainter _tp(String t, double size, Color color, {FontWeight w = FontWeight.w700, double? maxW, TextAlign align = TextAlign.left}) {
  final p = TextPainter(
    text: TextSpan(text: t, style: bangla(fontSize: size, fontWeight: w, color: color, height: 1.1)),
    textDirection: TextDirection.ltr,
    textAlign: align,
    maxLines: 1,
    ellipsis: '',
  )..layout(maxWidth: maxW ?? double.infinity);
  return p;
}

/// The calendar's paper: static per house (the ribbon is drawn above it).
class M8CalGridPainter extends CustomPainter {
  const M8CalGridPainter({required this.geo, required this.house});

  final M8Geo geo;
  final M8House house;

  @override
  void paint(Canvas c, Size size) {
    final cal = geo.cal;
    c.drawRRect(RRect.fromRectAndRadius(cal, const Radius.circular(6)), Paint()..color = const Color(0xFFFBF6E6));
    c.drawRRect(RRect.fromRectAndRadius(cal, const Radius.circular(6)), Paint()..color = const Color(0xFF8A6A3C)..style = PaintingStyle.stroke..strokeWidth = 1.6);
    final ink = const Color(0xFF2A2018);
    final line = Paint()..color = const Color(0x33806040)..strokeWidth = 0.6;
    if (house.planner) {
      final s = m8PlannerStart(house.today);
      final colW = (cal.width - M8Geo.planLabelW) / 31;
      final rowH = (M8Geo.calH - M8Geo.calHead) / 12;
      // Column numbers.
      for (final d in const [1, 5, 10, 15, 20, 25, 30]) {
        final t = _tp('$d', 8, const Color(0xFF6A5232), w: FontWeight.w800);
        t.paint(c, Offset(cal.left + M8Geo.planLabelW + (d - 0.5) * colW - t.width / 2, cal.top + 3));
      }
      for (var r = 0; r < 12; r++) {
        final m = DateTime.utc(s.year, s.month + r, 1);
        final y = cal.top + M8Geo.calHead + r * rowH;
        if (r.isOdd) c.drawRect(Rect.fromLTWH(cal.left + 2, y, cal.width - 4, rowH), Paint()..color = const Color(0x14806040));
        final t = _tp(kM8MonthsShort[m.month - 1], 9, ink, w: FontWeight.w800, maxW: M8Geo.planLabelW - 4);
        t.paint(c, Offset(cal.left + 5, y + (rowH - t.height) / 2));
        final n = _dim(m.year, m.month);
        for (var d = 1; d <= n; d++) {
          final x = cal.left + M8Geo.planLabelW + (d - 1) * colW;
          c.drawRect(Rect.fromLTWH(x + 0.5, y + 1.5, colW - 1, rowH - 3), Paint()..color = const Color(0xFFFFFFFF));
          c.drawRect(Rect.fromLTWH(x + 0.5, y + 1.5, colW - 1, rowH - 3), Paint()..color = const Color(0x33806040)..style = PaintingStyle.stroke..strokeWidth = 0.5);
        }
      }
    } else {
      final cellW = cal.width / 7;
      final rowH = (M8Geo.calH - M8Geo.calHead) / M8Geo.gridRows;
      for (var i = 0; i < 7; i++) {
        final t = _tp(kM8Dow[i], 9, i == 0 ? const Color(0xFF8A2A16) : const Color(0xFF6A5232), w: FontWeight.w800);
        t.paint(c, Offset(cal.left + (i + 0.5) * cellW - t.width / 2, cal.top + 2));
      }
      final start = m8GridStart(house.today);
      for (var r = 0; r < M8Geo.gridRows; r++) {
        for (var k = 0; k < 7; k++) {
          final d = start.add(Duration(days: r * 7 + k));
          final rect = Rect.fromLTWH(cal.left + k * cellW, cal.top + M8Geo.calHead + r * rowH, cellW, rowH);
          if (d.month.isEven) c.drawRect(rect, Paint()..color = const Color(0x1A806040));
          c.drawRect(rect, line..style = PaintingStyle.stroke);
          final first = d.day == 1;
          final t = _tp(first ? '1 ${kM8Months[d.month - 1]}' : '${d.day}', first ? 8.5 : 10.5, first ? const Color(0xFF8A2A16) : ink, w: first ? FontWeight.w900 : FontWeight.w700, maxW: cellW - 3);
          t.paint(c, Offset(rect.left + 3, rect.top + (rowH - t.height) / 2));
        }
      }
    }
    // 'আজ' on today's cell only.
    final today = geo.todayRect(house);
    c.drawRect(today, Paint()..color = const Color(0x55E9C46A));
    c.drawRect(today.deflate(0.5), Paint()..color = const Color(0xFFB8842A)..style = PaintingStyle.stroke..strokeWidth = 1.4);
    final az = _tp('আজ', house.planner ? 8 : 10, const Color(0xFF5A2A06), w: FontWeight.w900, maxW: house.planner ? 30 : today.width - 2);
    if (house.planner) {
      // The planner's cell is a sliver: the word sits to its left on the row.
      az.paint(c, Offset(today.left - az.width - 2, today.center.dy - az.height / 2));
    } else {
      az.paint(c, Offset(today.right - az.width - 3, today.center.dy - az.height / 2));
    }
  }

  @override
  bool shouldRepaint(M8CalGridPainter old) => old.house != house || old.geo.height != geo.height || old.geo.inset != geo.inset;
}

/// The ribbon from the start date to 'আজ', in one neutral colour at every
/// length (no mark at 15 or 180), and the finger's tail while it drags.
class M8RibbonPainter extends CustomPainter {
  const M8RibbonPainter({required this.geo, required this.house, required this.start, required this.finger});

  final M8Geo geo;
  final M8House house;
  final DateTime? start;
  final Offset? finger;

  @override
  void paint(Canvas c, Size size) {
    final s = start;
    if (s == null) return;
    final fill = Paint()..color = const Color(0x992AA7A1);
    final days = house.today.difference(s).inDays;
    for (var i = 0; i <= days; i++) {
      final r = geo.dateRect(house, s.add(Duration(days: i)));
      if (r != null) c.drawRect(r.deflate(0.6), fill);
    }
    final a = geo.dateRect(house, s);
    if (a != null) c.drawCircle(a.center, 3.2, Paint()..color = const Color(0xFF0E5A58));
    final f = finger;
    if (f != null && a != null) {
      c.drawLine(a.center, f, Paint()..color = const Color(0xFF0E5A58)..strokeWidth = 2..strokeCap = StrokeCap.round);
      c.drawCircle(f, 5, Paint()..color = const Color(0xFF0E5A58));
    }
  }

  @override
  bool shouldRepaint(M8RibbonPainter old) => old.start != start || old.finger != finger || old.house != house;
}

/// A tiny wall meter for the house strip is a widget on the page; this paints
/// the coiled service wire (an item to drag).
class M8CoilPainter extends CustomPainter {
  const M8CoilPainter();

  @override
  void paint(Canvas c, Size size) {
    final p = Paint()
      ..color = const Color(0xFF2A2F35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final cx = size.width / 2, cy = size.height / 2;
    for (var i = 0; i < 3; i++) {
      c.drawOval(Rect.fromCenter(center: Offset(cx, cy), width: size.width * (0.86 - i * 0.2), height: size.height * (0.8 - i * 0.2)), p);
    }
    c.drawLine(Offset(cx, cy), Offset(size.width - 4, size.height - 6), p..strokeWidth = 4);
  }

  @override
  bool shouldRepaint(M8CoilPainter old) => false;
}
