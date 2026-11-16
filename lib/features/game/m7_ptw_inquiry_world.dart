import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

// The drawn world of lesson 7.4 কাজ 2 "বৈধ PTW ছিল কি?" (m7_ptw_inquiry.dart):
// the inquiry room at the division office after an accident (no injury is
// shown — only the records).
//
// One place, laid out top to bottom on the table under a corkboard:
//  * the case folder (date and feeder of the job) and beside it the crew's
//    field copy of the PTW (its number only) — or an empty plastic sleeve,
//    'ফিল্ড কপি পাওয়া যায়নি';
//  * on the corkboard the big photo: the site photo picked on the film strip,
//    with the phone's own time stamp burnt into its corner;
//  * the film strip of the day's 6–9 site photos (a small time under each)
//    and its scrubber thumb;
//  * the bound PTW logbook, open: তারিখ · PTW নং · ফিডার · ইস্যু · বাতিল,
//    three rows a page, pages turned by a swipe. The row the trainee clips
//    carries a paper clip.
// Behind, on the wall above the board, the inquiry officer and one of the
// crew sit at the far side of the table.
//
// No captions: only what a worker reads (the folder's fields, the logbook's
// columns and rows, the photo stamps, the field copy). Nothing on the strip or
// in the book marks the permit window — times are read and compared by the
// player. Code-drawn, gradients, no bitmaps. Design: 360 wide × the scene's
// height (560–900); a tall phone gets a taller photo and logbook.

/// What a site photo shows.
enum M7PtwShot {
  /// The van has just come; the crew on the ground.
  arrive,

  /// The crew at the pole's foot; the ladder on the ground.
  ground,

  /// A man on the ladder against the pole, halfway up.
  climb,

  /// A man at the crossarm, his harness round the pole.
  up,

  /// The crew loading the ladder into the van.
  pack,
}

/// Somebody is up the pole in this shot.
bool m7PtwOnPole(M7PtwShot s) => s == M7PtwShot.climb || s == M7PtwShot.up;

/// 'HH:MM' for minutes after midnight (English digits).
String m7PtwClock(int minute) {
  final h = (minute ~/ 60) % 24;
  final m = minute % 60;
  return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
}

/// 'DD/MM' (English digits).
String m7PtwDate(int day, int month) => '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}';

/// One site photo of the day.
@immutable
class M7PtwPhoto {
  const M7PtwPhoto({required this.minute, required this.shot, this.variant = 0});

  /// The phone's time stamp (minutes after midnight).
  final int minute;
  final M7PtwShot shot;

  /// The camera's angle (0–2): where the pole and the van stand.
  final int variant;

  bool get onPole => m7PtwOnPole(shot);

  @override
  bool operator ==(Object other) => other is M7PtwPhoto && other.minute == minute && other.shot == shot && other.variant == variant;

  @override
  int get hashCode => Object.hash(minute, shot, variant);
}

/// One logbook row.
@immutable
class M7PtwRow {
  const M7PtwRow({required this.id, required this.day, required this.month, required this.ptwNo, required this.feeder, required this.issue, required this.cancel});

  final int id;
  final int day;
  final int month;
  final int ptwNo;

  /// Index into the level's feeder names.
  final int feeder;

  /// Issue and cancellation (minutes after midnight).
  final int issue;
  final int cancel;

  /// Sorting key: the logbook is written day by day.
  int get order => (month * 32 + day) * 2000 + issue;

  @override
  bool operator ==(Object other) =>
      other is M7PtwRow &&
      other.id == id &&
      other.day == day &&
      other.month == month &&
      other.ptwNo == ptwNo &&
      other.feeder == feeder &&
      other.issue == issue &&
      other.cancel == cancel;

  @override
  int get hashCode => Object.hash(id, day, month, ptwNo, feeder, issue, cancel);
}

/// Rows on one logbook page.
const int kM7PtwRowsPerPage = 3;

/// Where things are (design px, 360 wide).
@immutable
class M7PtwGeo {
  const M7PtwGeo._(this.height, this.inset);

  factory M7PtwGeo.forScene(double height, double inset) => M7PtwGeo._(height, inset);

  final double height;
  final double inset;

  /// The top of the working area (under the header and the case dots).
  static const double top = 134;

  /// The working area ends here (the stamps and the guide stand below).
  double get bottom => height - 140 - inset;

  double get avail => bottom - top;

  /// The case folder (left) and the field copy (right).
  Rect get folder => const Rect.fromLTWH(8, top, 238, 50);
  Rect get fieldCopy => const Rect.fromLTWH(252, top, 100, 50);

  /// The big photo on the corkboard (held = the pin).
  Rect get photo {
    final h = (avail * 0.27).clamp(90.0, 196.0);
    return Rect.fromLTWH(24, folder.bottom + 10, 312, h);
  }

  Rect get cork => photo.inflate(8);

  /// The film strip's thumbnails band.
  double get _thumbH => (avail * 0.095).clamp(34.0, 50.0);
  Rect get stripBand => Rect.fromLTWH(8, cork.bottom + 6, 344, _thumbH + 40);
  Rect thumb(int i, int n) {
    const l = 16.0, r = 344.0, gap = 4.0;
    final w = (r - l - gap * (n - 1)) / n;
    return Rect.fromLTWH(l + i * (w + gap), stripBand.top + 5, w, _thumbH);
  }

  /// The small time under thumbnail [i].
  Offset thumbTime(int i, int n) => thumb(i, n).bottomCenter.translate(0, 8);

  /// The scrubber's track and its thumb.
  double get trackY => stripBand.bottom - 9;
  Offset knob(int i, int n) => Offset(thumb(i, n).center.dx, trackY);

  /// The index of the photo nearest [x] on the strip.
  int photoAt(double x, int n) {
    var best = 0;
    var d = double.infinity;
    for (var i = 0; i < n; i++) {
      final e = (thumb(i, n).center.dx - x).abs();
      if (e < d) {
        d = e;
        best = i;
      }
    }
    return best;
  }

  /// The whole strip (taps, drags).
  Rect get stripHit => stripBand;

  /// The open logbook.
  Rect get book => Rect.fromLTRB(8, stripBand.bottom + 6, 352, bottom);
  double get _bookHead => 34;
  double get rowH => (book.height - _bookHead - 6) / kM7PtwRowsPerPage;

  /// Row [i] of the page (0–2).
  Rect row(int i) => Rect.fromLTWH(book.left + 6, book.top + _bookHead + i * rowH, book.width - 12, rowH);

  /// The table's top edge (wood under the folder, the strip and the book).
  double get tableY => cork.bottom + 2;

  /// The far side of the table: the officer (right) and a crew man (left).
  Rect get officer => const Rect.fromLTWH(292, 64, 60, 70);
  Rect get crewman => const Rect.fromLTWH(8, 70, 50, 64);
}

/// What the desk shows now.
@immutable
class M7PtwDesk {
  const M7PtwDesk({
    required this.caseLabel,
    required this.dateLabel,
    required this.feederLabel,
    required this.fieldCopyNo,
    required this.photos,
    required this.photoIndex,
    required this.rows,
    required this.feederNames,
    required this.page,
    required this.pages,
    required this.clipped,
    required this.wrongRow,
    required this.labels,
  });

  final String caseLabel;
  final String dateLabel;
  final String feederLabel;

  /// The field copy's PTW number, or null: the empty sleeve.
  final int? fieldCopyNo;
  final List<M7PtwPhoto> photos;
  final int photoIndex;

  /// The rows of the page on view.
  final List<M7PtwRow> rows;
  final List<String> feederNames;
  final int page;
  final int pages;

  /// The clipped row's id, and a row just tapped that is not this permit's.
  final int? clipped;
  final int? wrongRow;

  /// The words printed on the desk.
  final M7PtwDeskLabels labels;

  @override
  bool operator ==(Object other) =>
      other is M7PtwDesk &&
      other.caseLabel == caseLabel &&
      other.dateLabel == dateLabel &&
      other.feederLabel == feederLabel &&
      other.fieldCopyNo == fieldCopyNo &&
      listEquals(other.photos, photos) &&
      other.photoIndex == photoIndex &&
      listEquals(other.rows, rows) &&
      other.page == page &&
      other.pages == pages &&
      other.clipped == clipped &&
      other.wrongRow == wrongRow;

  @override
  int get hashCode => Object.hash(caseLabel, dateLabel, feederLabel, fieldCopyNo, Object.hashAll(photos), photoIndex, Object.hashAll(rows), page, pages, clipped, wrongRow);
}

/// The printed words (from the level's Lines class).
@immutable
class M7PtwDeskLabels {
  const M7PtwDeskLabels({
    required this.caseFile,
    required this.date,
    required this.feeder,
    required this.fieldCopy,
    required this.ptwNo,
    required this.noFieldCopy,
    required this.logbook,
    required this.columns,
    required this.page,
  });

  final String caseFile;
  final String date;
  final String feeder;
  final String fieldCopy;
  final String ptwNo;
  final String noFieldCopy;
  final String logbook;

  /// তারিখ · PTW নং · ফিডার · ইস্যু · বাতিল.
  final List<String> columns;

  /// 'পাতা n/m'.
  final String Function(int n, int m) page;
}

void _text(Canvas c, String t, Offset at, double size, Color color, {FontWeight weight = FontWeight.w800, double? maxWidth, bool left = false}) {
  final tp = TextPainter(
    text: TextSpan(text: t, style: bangla(fontSize: size, fontWeight: weight, color: color, height: 1.1)),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  final s = maxWidth != null && tp.width > maxWidth ? maxWidth / tp.width : 1.0;
  c.save();
  c.translate(at.dx, at.dy);
  c.scale(s, s);
  tp.paint(c, Offset(left ? 0 : -tp.width / 2, -tp.height / 2));
  c.restore();
}

/// The desk, the corkboard and everything on them.
class M7PtwDeskPainter extends CustomPainter {
  M7PtwDeskPainter({required this.geo, required this.desk});

  final M7PtwGeo geo;
  final M7PtwDesk desk;

  @override
  void paint(Canvas canvas, Size size) {
    final g = geo;
    final w = size.width;
    final h = size.height;
    // The wall.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2E3A4C), Color(0xFF4A5566)]).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    // A window with afternoon light (left) and a ceiling-fan shadow.
    final win = const Rect.fromLTWH(96, 40, 120, 80);
    canvas.drawRRect(RRect.fromRectAndRadius(win, const Radius.circular(4)), Paint()..color = const Color(0xFF1C2433));
    canvas.drawRect(win.deflate(5), Paint()..shader = const LinearGradient(colors: [Color(0xFF9EC6E8), Color(0xFFDDE9F2)]).createShader(win));
    canvas.drawLine(win.topCenter, win.bottomCenter, Paint()
      ..color = const Color(0xFF1C2433)
      ..strokeWidth = 4);
    canvas.drawLine(win.centerLeft, win.centerRight, Paint()
      ..color = const Color(0xFF1C2433)
      ..strokeWidth = 4);
    _bust(canvas, g.crewman, shirt: const Color(0xFFB8682C), left: true);
    _bust(canvas, g.officer, shirt: const Color(0xFFE9E4D6), left: false);
    // The table (wood) from under the corkboard to the floor.
    final table = Rect.fromLTWH(0, g.folder.top - 8, w, h - g.folder.top + 8);
    canvas.drawRect(
      table,
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF6B4426), Color(0xFF4C2E18)]).createShader(table),
    );
    final grain = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 1;
    for (var y = table.top + 14; y < h; y += 23) {
      canvas.drawLine(Offset(0, y), Offset(w, y + 6), grain);
    }
    _folder(canvas);
    _cork(canvas);
    _strip(canvas);
    _book(canvas);
  }

  void _bust(Canvas c, Rect r, {required Color shirt, required bool left}) {
    final head = Offset(r.center.dx, r.top + 18);
    final body = RRect.fromRectAndCorners(Rect.fromLTWH(r.left + 4, r.top + 32, r.width - 8, r.height - 32), topLeft: const Radius.circular(18), topRight: const Radius.circular(18));
    c.drawRRect(body, Paint()..shader = LinearGradient(colors: [shirt, Color.lerp(shirt, Colors.black, 0.3)!]).createShader(body.outerRect));
    c.drawCircle(head, 13, Paint()..color = const Color(0xFF8A5A3C));
    c.drawArc(Rect.fromCircle(center: head.translate(0, -3), radius: 13), math.pi, math.pi, true, Paint()..color = const Color(0xFF1E1A18));
    if (!left) {
      // The officer's spectacles.
      final p = Paint()
        ..color = const Color(0xFF111111)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4;
      c.drawCircle(head.translate(-5, 1), 3.4, p);
      c.drawCircle(head.translate(5, 1), 3.4, p);
    }
  }

  void _folder(Canvas c) {
    final f = geo.folder;
    final l = desk.labels;
    c.drawRRect(RRect.fromRectAndRadius(f.translate(2, 3), const Radius.circular(6)), Paint()..color = const Color(0x55000000));
    c.drawRRect(
      RRect.fromRectAndRadius(f, const Radius.circular(6)),
      Paint()..shader = const LinearGradient(colors: [Color(0xFFE8C98A), Color(0xFFD9B26A)]).createShader(f),
    );
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(f.left + 10, f.top - 5, 64, 10), const Radius.circular(3)), Paint()..color = const Color(0xFFD9B26A));
    const ink = Color(0xFF2A1E10);
    _text(c, '${l.caseFile} · ${desk.caseLabel}', Offset(f.left + 10, f.top + 11), 11, ink, left: true, maxWidth: f.width - 20);
    _text(c, '${l.date}: ${desk.dateLabel}', Offset(f.left + 10, f.top + 26), 12, ink, left: true, weight: FontWeight.w900, maxWidth: f.width - 20);
    _text(c, '${l.feeder}: ${desk.feederLabel}', Offset(f.left + 10, f.top + 40), 12, ink, left: true, weight: FontWeight.w900, maxWidth: f.width - 20);
    final fc = geo.fieldCopy;
    final no = desk.fieldCopyNo;
    if (no != null) {
      c.drawRect(fc.translate(2, 3), Paint()..color = const Color(0x55000000));
      c.drawRect(fc, Paint()..color = const Color(0xFFF7F1E1));
      c.drawRect(Rect.fromLTWH(fc.left, fc.top, fc.width, 12), Paint()..color = const Color(0xFFC9483B));
      _text(c, l.fieldCopy, Offset(fc.center.dx, fc.top + 6), 8.5, Colors.white, maxWidth: fc.width - 8);
      _text(c, l.ptwNo, Offset(fc.center.dx, fc.top + 20), 9.5, const Color(0xFF3A3A3A));
      _text(c, '$no', Offset(fc.center.dx, fc.top + 37), 17, const Color(0xFF14284A), weight: FontWeight.w900);
    } else {
      // The empty plastic sleeve.
      c.drawRRect(RRect.fromRectAndRadius(fc, const Radius.circular(4)), Paint()..color = const Color(0x55DDE6EE));
      c.drawRRect(
        RRect.fromRectAndRadius(fc, const Radius.circular(4)),
        Paint()
          ..color = const Color(0xAAE6EEF5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      c.drawLine(fc.topLeft.translate(8, 6), fc.topLeft.translate(30, 44), Paint()
        ..color = const Color(0x55FFFFFF)
        ..strokeWidth = 3);
      final words = l.noFieldCopy.split(' ');
      final half = (words.length / 2).ceil();
      _text(c, words.take(half).join(' '), Offset(fc.center.dx, fc.top + 19), 9.5, const Color(0xFFF2F5F8), maxWidth: fc.width - 8);
      _text(c, words.skip(half).join(' '), Offset(fc.center.dx, fc.top + 33), 9.5, const Color(0xFFF2F5F8), maxWidth: fc.width - 8);
    }
  }

  void _cork(Canvas c) {
    final k = geo.cork;
    c.drawRRect(RRect.fromRectAndRadius(k.inflate(3), const Radius.circular(5)), Paint()..color = const Color(0xFF3B2414));
    c.drawRRect(
      RRect.fromRectAndRadius(k, const Radius.circular(4)),
      Paint()..shader = const RadialGradient(colors: [Color(0xFFC18E5A), Color(0xFF9C6A3C)], radius: 1.2).createShader(k),
    );
    final p = geo.photo;
    if (desk.photos.isEmpty) return;
    final shot = desk.photos[desk.photoIndex.clamp(0, desk.photos.length - 1)];
    c.drawRect(p.translate(3, 4), Paint()..color = const Color(0x66000000));
    c.drawRect(p.inflate(3), Paint()..color = const Color(0xFFF4F1EA));
    paintM7PtwPhoto(c, p, shot, stamp: '${desk.dateLabel} ${m7PtwClock(shot.minute)}');
    // The drawing pin at the top.
    c.drawCircle(p.topCenter.translate(0, -1), 5, Paint()..color = const Color(0xFFD23C2E));
    c.drawCircle(p.topCenter.translate(-1.5, -2.5), 1.6, Paint()..color = const Color(0x99FFFFFF));
  }

  void _strip(Canvas c) {
    final b = geo.stripBand;
    c.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(5)), Paint()..color = const Color(0xFF15171C));
    final hole = Paint()..color = const Color(0xFF3A3E46);
    for (var x = b.left + 8; x < b.right - 6; x += 12) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, b.top + 1, 6, 3), const Radius.circular(1)), hole);
    }
    final n = desk.photos.length;
    for (var i = 0; i < n; i++) {
      final r = geo.thumb(i, n);
      paintM7PtwPhoto(c, r, desk.photos[i]);
      final on = i == desk.photoIndex;
      c.drawRect(
        r,
        Paint()
          ..color = on ? const Color(0xFFF2C14E) : const Color(0xFF5A606B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = on ? 2.2 : 1,
      );
      _text(c, m7PtwClock(desk.photos[i].minute), geo.thumbTime(i, n), 9, on ? const Color(0xFFF2C14E) : const Color(0xFFD5D9E0), maxWidth: r.width + 4);
    }
    // The scrubber's track and thumb.
    final y = geo.trackY;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(b.left + 14, y - 2, b.right - 14, y + 2), const Radius.circular(2)), Paint()..color = const Color(0xFF59606C));
    if (n > 0) {
      final k = geo.knob(desk.photoIndex.clamp(0, n - 1), n);
      c.drawCircle(k, 8, Paint()..color = const Color(0xFFF2C14E));
      c.drawCircle(k, 8, Paint()
        ..color = const Color(0xFF3A2A08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4);
    }
  }

  void _book(Canvas c) {
    final b = geo.book;
    final l = desk.labels;
    c.drawRRect(RRect.fromRectAndRadius(b.inflate(3).translate(0, 3), const Radius.circular(6)), Paint()..color = const Color(0x66000000));
    // The binding (dark red cloth) and the page.
    c.drawRRect(RRect.fromRectAndRadius(b.inflate(3), const Radius.circular(6)), Paint()..color = const Color(0xFF6E1F1A));
    c.drawRect(b, Paint()..shader = const LinearGradient(colors: [Color(0xFFF3EEDF), Color(0xFFE9E1CB)]).createShader(b));
    const ink = Color(0xFF1E2A44);
    _text(c, l.logbook, Offset(b.left + 10, b.top + 9), 10.5, const Color(0xFF6E1F1A), left: true, weight: FontWeight.w900);
    _text(c, l.page(desk.page + 1, desk.pages), Offset(b.right - 34, b.top + 9), 9.5, const Color(0xFF6E1F1A));
    final cols = _cols(b);
    for (var i = 0; i < 5; i++) {
      _text(c, l.columns[i], Offset(cols[i], b.top + 25), 9, const Color(0xFF55607A), maxWidth: 60);
    }
    final rule = Paint()
      ..color = const Color(0x553A6EA8)
      ..strokeWidth = 1;
    c.drawLine(Offset(b.left + 4, b.top + 32), Offset(b.right - 4, b.top + 32), Paint()
      ..color = const Color(0xAA6E1F1A)
      ..strokeWidth = 1.2);
    for (var i = 0; i < kM7PtwRowsPerPage; i++) {
      final r = geo.row(i);
      c.drawLine(r.bottomLeft, r.bottomRight, rule);
      if (i >= desk.rows.length) continue;
      final row = desk.rows[i];
      if (row.id == desk.clipped) c.drawRect(r.deflate(1), Paint()..color = const Color(0x66F7D55A));
      if (row.id == desk.wrongRow) c.drawRect(r.deflate(1), Paint()..color = const Color(0x22B22A22));
      final y = r.center.dy;
      final fs = (r.height * 0.42).clamp(10.0, 13.5);
      _text(c, m7PtwDate(row.day, row.month), Offset(cols[0], y), fs, ink);
      _text(c, '${row.ptwNo}', Offset(cols[1], y), fs, ink, weight: FontWeight.w900);
      _text(c, desk.feederNames[row.feeder], Offset(cols[2], y), fs, ink, maxWidth: 92);
      _text(c, m7PtwClock(row.issue), Offset(cols[3], y), fs, ink);
      _text(c, m7PtwClock(row.cancel), Offset(cols[4], y), fs, ink);
      if (row.id == desk.clipped) _clip(c, Offset(r.left - 2, r.top + 2), r.height);
    }
    // The page's turned corner (swipe for the next page).
    final corner = Path()
      ..moveTo(b.right, b.bottom - 16)
      ..lineTo(b.right - 16, b.bottom)
      ..lineTo(b.right, b.bottom)
      ..close();
    c.drawPath(corner, Paint()..color = const Color(0xFFCFC4A6));
  }

  static List<double> _cols(Rect b) {
    final x = b.left;
    return [x + 34, x + 92, x + 170, x + 250, x + 306];
  }

  void _clip(Canvas c, Offset at, double h) {
    final p = Paint()
      ..color = const Color(0xFF8E98A6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    final r = RRect.fromRectAndRadius(Rect.fromLTWH(at.dx, at.dy, 9, h - 4), const Radius.circular(5));
    c.drawRRect(r, p);
    c.drawLine(at.translate(4.5, 4), at.translate(4.5, h - 10), p);
  }

  @override
  bool shouldRepaint(M7PtwDeskPainter old) => old.desk != desk || old.geo.height != geo.height || old.geo.inset != geo.inset;
}

/// A site photo in [r]: the pole and its line, the crew, the van; [stamp] =
/// the phone's time stamp burnt into the corner (the big photo only).
void paintM7PtwPhoto(Canvas c, Rect r, M7PtwPhoto p, {String? stamp}) {
  c.save();
  c.clipRect(r);
  final s = r.height / 100;
  final v = p.variant % 3;
  // Sky and ground.
  final sky = Rect.fromLTWH(r.left, r.top, r.width, r.height * 0.72);
  c.drawRect(
    sky,
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [const [Color(0xFF6FA8DC), Color(0xFF8DB7D9), Color(0xFF7FA6C8)][v], const Color(0xFFDCE8EF)],
      ).createShader(sky),
  );
  final ground = Rect.fromLTWH(r.left, sky.bottom, r.width, r.height - sky.height);
  c.drawRect(ground, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8C9A5B), Color(0xFF6A7444)]).createShader(ground));
  // Far trees.
  final tree = Paint()..color = const Color(0xFF4F6B3A);
  for (var i = 0; i < 5; i++) {
    final x = r.left + r.width * (0.08 + 0.21 * i + 0.03 * v);
    c.drawOval(Rect.fromCenter(center: Offset(x, sky.bottom - 6 * s), width: 26 * s, height: 16 * s), tree);
  }
  // The pole.
  final px = r.left + r.width * (const [0.42, 0.52, 0.36][v]);
  final poleTop = r.top + 12 * s;
  final foot = sky.bottom + 6 * s;
  c.drawRect(
    Rect.fromLTRB(px - 2.6 * s, poleTop, px + 2.6 * s, foot),
    Paint()..shader = const LinearGradient(colors: [Color(0xFF9A9C98), Color(0xFFC9CAC4), Color(0xFF8C8E8A)]).createShader(Rect.fromLTRB(px - 3 * s, 0, px + 3 * s, 1)),
  );
  // The crossarm, the pins and the three conductors.
  final armY = poleTop + 6 * s;
  final arm = Paint()
    ..color = const Color(0xFF4A4F57)
    ..strokeWidth = 2.4 * s;
  c.drawLine(Offset(px - 22 * s, armY), Offset(px + 22 * s, armY), arm);
  final wire = Paint()
    ..color = const Color(0xFF2B2F35)
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(0.8, 0.9 * s);
  for (final dx in [-19.0, 0.0, 19.0]) {
    final ix = px + dx * s;
    c.drawRect(Rect.fromCenter(center: Offset(ix, armY - 3 * s), width: 3 * s, height: 5 * s), Paint()..color = const Color(0xFFE6E3DA));
    final y = armY - 5 * s;
    final path = Path()
      ..moveTo(r.left, y + 5 * s)
      ..quadraticBezierTo((r.left + ix) / 2, y + 9 * s, ix, y)
      ..quadraticBezierTo((ix + r.right) / 2, y + 9 * s, r.right, y + 5 * s);
    c.drawPath(path, wire);
  }
  // The van.
  final vanLeft = v == 1;
  final vx = vanLeft ? r.left + r.width * 0.06 : r.left + r.width * 0.70;
  final van = Rect.fromLTWH(vx, sky.bottom - 12 * s, 34 * s, 18 * s);
  c.drawRRect(RRect.fromRectAndRadius(van, Radius.circular(3 * s)), Paint()..color = const Color(0xFFEDEDED));
  c.drawRect(Rect.fromLTWH(van.left + (vanLeft ? 24 : 2) * s, van.top + 3 * s, 8 * s, 6 * s), Paint()..color = const Color(0xFF6E8CA8));
  c.drawRect(Rect.fromLTWH(van.left, van.top + 10 * s, van.width, 2.5 * s), Paint()..color = const Color(0xFF2F6DB5));
  for (final wx in [7.0, 27.0]) {
    c.drawCircle(Offset(van.left + wx * s, van.bottom), 3.2 * s, Paint()..color = const Color(0xFF1C1C1C));
  }
  // The crew.
  void man(Offset feet, {bool up = false, double lean = 0}) {
    final body = Paint()..color = const Color(0xFFE07A1F);
    final legs = Paint()
      ..color = const Color(0xFF2F3A4F)
      ..strokeWidth = 2.2 * s
      ..strokeCap = StrokeCap.round;
    c.drawLine(feet.translate(-2 * s, 0), feet.translate(-1 * s, -7 * s), legs);
    c.drawLine(feet.translate(2 * s, 0), feet.translate(1 * s, -7 * s), legs);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: feet.translate(lean * s, -11.5 * s), width: 6.5 * s, height: 9 * s), Radius.circular(2 * s)), body);
    c.drawCircle(feet.translate(lean * s, -18 * s), 2.6 * s, Paint()..color = const Color(0xFF8A5A3C));
    c.drawArc(Rect.fromCircle(center: feet.translate(lean * s, -19 * s), radius: 3 * s), math.pi, math.pi, true, Paint()..color = const Color(0xFFF2C230));
    if (up) {
      // The harness strap round the pole.
      c.drawLine(feet.translate(-4 * s, -12 * s), Offset(px + 3 * s, feet.dy - 13 * s), Paint()
        ..color = const Color(0xFF1C1C1C)
        ..strokeWidth = 1.2 * s);
    }
  }

  void ladder(Offset foot, Offset top) {
    final rail = Paint()
      ..color = const Color(0xFFB98A4A)
      ..strokeWidth = 1.4 * s;
    final n = Offset(-(top - foot).dy, (top - foot).dx) / (top - foot).distance * 3 * s;
    c.drawLine(foot + n, top + n, rail);
    c.drawLine(foot - n, top - n, rail);
    for (var t = 0.1; t < 1; t += 0.12) {
      final m = Offset.lerp(foot, top, t)!;
      c.drawLine(m + n, m - n, rail);
    }
  }

  final ground0 = sky.bottom + 14 * s;
  switch (p.shot) {
    case M7PtwShot.arrive:
      man(Offset(van.left - 6 * s, ground0));
      man(Offset(van.left - 16 * s, ground0 + 4 * s), lean: 1);
      ladder(Offset(van.left + 2 * s, van.top - 1 * s), Offset(van.right - 2 * s, van.top - 1 * s));
    case M7PtwShot.ground:
      man(Offset(px - 12 * s, ground0));
      man(Offset(px + 12 * s, ground0 + 3 * s), lean: -1);
      ladder(Offset(px - 30 * s, ground0 + 8 * s), Offset(px + 26 * s, ground0 + 10 * s));
    case M7PtwShot.climb:
      ladder(Offset(px - 12 * s, foot + 6 * s), Offset(px - 2 * s, armY + 14 * s));
      man(Offset(px - 6 * s, r.top + 58 * s), up: true);
      man(Offset(px - 18 * s, ground0 + 2 * s), lean: 1);
    case M7PtwShot.up:
      man(Offset(px - 5 * s, armY + 24 * s), up: true);
      man(Offset(px + 16 * s, ground0 + 2 * s), lean: -1);
    case M7PtwShot.pack:
      ladder(Offset(van.left - 18 * s, van.top + 2 * s), Offset(van.left + 10 * s, van.top + 4 * s));
      man(Offset(van.left - 20 * s, ground0));
      man(Offset(van.left + 2 * s, ground0 + 3 * s), lean: -1);
  }
  if (stamp != null) {
    final tp = TextPainter(
      text: TextSpan(
        text: stamp,
        style: TextStyle(
          fontSize: math.max(9, 10 * s),
          fontWeight: FontWeight.w700,
          color: const Color(0xFFFF9A2E),
          fontFeatures: const [FontFeature.tabularFigures()],
          shadows: const [Shadow(color: Color(0xCC000000), blurRadius: 2)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(r.right - tp.width - 6, r.bottom - tp.height - 4));
  }
  c.restore();
}
