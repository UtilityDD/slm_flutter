import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

// The drawn world of lesson 7.6 কাজ "কাউন্টারে দাবি" (m7_ppe_counter_claim.dart):
// dawn at the section store. The storekeeper stands behind the issue counter
// in front of his shelves; a rubber mat on the counter takes one item at a
// time (helmet, safety shoes, gloves, harness); the trainee stands at the
// counter's left edge (hand, foot and body free for a try-on); the day's
// docket (job + kit list) lies on the counter's right; the issue register
// (one ruled line per item) and a stand of six rubber stamps run along the
// bottom edge; a wall calendar hangs over the counter.
//
// Every item is drawn as a real one with every marking at once and never
// ringed or captioned: a helmet's 'IS 2925' sticker (or none, or a shoe's code
// on it), a shoe's 'IS 15298', a glove cuff 'IS 4770 · টাইপ 4' (a lower type
// on a wrong pair; the live lesson 7.6: IS 4770 type 4 is the 11 kV glove, X3 —
// never '11 kV গ্লাভস'), a harness's date label ('মেয়াদ 03/2027'), its webbing
// and its 'এই প্রথম এল' tag. A wrong size shows only in the try-on.
//
// Design: 360 wide × the scene's height. The stand and register stand on the
// bottom edge; the guide and his bubble keep the lower right, clear of every
// part. Code-drawn with gradients; idle = nothing moves.

/// The four kit items, in register order.
enum M7Item { helmet, shoes, gloves, harness }

/// The day's job: only 11 kV jobs can deal a glove fault.
enum M7Job { kv11, lt }

/// What an item on the mat is like.
enum M7Look { ok, cracked, splitSole, noIs, wrongIs, wrongSize, torn, lowType, cutWebbing, expired, newType }

/// The six rubber stamps.
enum M7Claim { sign, replace, isMark, rating, size, training }

/// The two docket stamps.
enum M7Docket { go, refuse }

/// Faults per item (gloves: 11 kV jobs only).
List<M7Look> m7FaultPool(M7Item i, M7Job j) => switch (i) {
      M7Item.helmet => const [M7Look.cracked, M7Look.noIs, M7Look.wrongIs, M7Look.wrongSize],
      M7Item.shoes => const [M7Look.splitSole, M7Look.noIs, M7Look.wrongIs, M7Look.wrongSize],
      M7Item.gloves => j == M7Job.kv11 ? const [M7Look.torn, M7Look.lowType] : const [],
      M7Item.harness => const [M7Look.cutWebbing, M7Look.expired, M7Look.newType, M7Look.wrongSize],
    };

/// The claim that answers a look (an ok item: the signature).
M7Claim m7RightClaim(M7Look l) => switch (l) {
      M7Look.ok => M7Claim.sign,
      M7Look.cracked || M7Look.splitSole || M7Look.torn || M7Look.cutWebbing || M7Look.expired => M7Claim.replace,
      M7Look.noIs || M7Look.wrongIs => M7Claim.isMark,
      M7Look.lowType => M7Claim.rating,
      M7Look.wrongSize => M7Claim.size,
      M7Look.newType => M7Claim.training,
    };

/// Signing for it is deadly (torn or unrated glove, cut webbing).
bool m7DeadlySign(M7Look l) => l == M7Look.torn || l == M7Look.lowType || l == M7Look.cutWebbing;

/// Is this look possible on this item?
bool m7LookFits(M7Item i, M7Look l, M7Job j) => l == M7Look.ok || m7FaultPool(i, j).contains(l);

/// The calendar on the wall (also the date on the register's page).
@immutable
class M7Calendar {
  const M7Calendar({required this.day, required this.month, required this.year});
  final int day;
  final int month;
  final int year;

  static const monthsBn = [
    'জানুয়ারি',
    'ফেব্রুয়ারি',
    'মার্চ',
    'এপ্রিল',
    'মে',
    'জুন',
    'জুলাই',
    'আগস্ট',
    'সেপ্টেম্বর',
    'অক্টোবর',
    'নভেম্বর',
    'ডিসেম্বর',
  ];

  String get monthName => monthsBn[month - 1];

  /// 'DD/MM/YYYY' (English digits).
  String get dateText => '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';

  /// 'MM/YYYY' that many months from now.
  String monthsFromNow(int delta) {
    final total = year * 12 + (month - 1) + delta;
    final y = total ~/ 12;
    final m = total % 12 + 1;
    return '${m.toString().padLeft(2, '0')}/$y';
  }
}

/// One thing on the mat.
@immutable
class M7Piece {
  const M7Piece({required this.id, required this.item, required this.look, this.labelMonths = 8, this.tint = 0, this.big = true});

  /// Unique in a deal (keys the mat's widget).
  final int id;
  final M7Item item;
  final M7Look look;

  /// The harness label's date: this many months from today (negative =
  /// before today = expired).
  final int labelMonths;

  /// A colour variant (0..2).
  final int tint;

  /// A wrong size: too big (true) or too small (false) in the try-on.
  final bool big;

  @override
  bool operator ==(Object other) => other is M7Piece && other.id == id && other.look == look;

  @override
  int get hashCode => Object.hash(id, look);
}

/// The IS codes (lesson 7.6 point 3).
const kM7HelmetIs = 'IS 2925';
const kM7ShoeIs = 'IS 15298';

/// The glove cuff's print: 11 kV jobs carry the type-4 glove (IS 4770 ·
/// টাইপ 4, up to 17,000 V); a lower type is the wrong glove for them.
String m7GloveCuff(M7Look l, M7Job j) => switch ((l, j)) {
      (M7Look.lowType, _) => 'IS 4770 · টাইপ 2',
      (_, M7Job.kv11) => 'IS 4770 · টাইপ 4',
      _ => 'IS 4770',
    };

/// The sticker an item shows (null = none).
String? m7IsPrint(M7Item i, M7Look l) {
  if (l == M7Look.noIs) return null;
  return switch (i) {
    M7Item.helmet => l == M7Look.wrongIs ? kM7ShoeIs : kM7HelmetIs,
    M7Item.shoes => l == M7Look.wrongIs ? kM7HelmetIs : kM7ShoeIs,
    _ => null,
  };
}

/// Where things are (design px, 360 wide).
@immutable
class M7PpeGeo {
  const M7PpeGeo._(this.height, this.standTop);

  factory M7PpeGeo.forScene(double height, double inset) => M7PpeGeo._(height, height - standH - inset * 0.6);

  final double height;

  /// The top of the stamp stand.
  final double standTop;

  static const double standH = 104;

  /// A dragged stamp's pin sits this far above the finger.
  static const double lift = 26;

  /// How long the stamp is held on the line to ink.
  static const holdMs = 600;

  Rect get stand => Rect.fromLTWH(6, standTop, 348, standH - 6);
  Rect stamp(int i) => Rect.fromLTWH(8 + 58.0 * i, standTop + 6, 54, standH - 18);
  Rect docketStamp(int i) => Rect.fromLTWH(24 + 168.0 * i, standTop + 6, 144, standH - 18);

  /// The issue register and its four ruled lines (register order).
  Rect get register => Rect.fromLTWH(8, standTop - 104, 228, 98);
  Rect line(int k) => Rect.fromLTWH(14, standTop - 104 + 17 + 20.0 * k, 216, 20);

  /// The mat on the counter, and the item on it.
  Rect get mat => Rect.fromLTWH(86, standTop - 296, 148, 112);
  Rect get item => mat.deflate(5);

  /// The trainee at the counter's left edge.
  Rect get trainee => Rect.fromLTWH(10, standTop - 222, 46, 106);

  /// The docket on the counter's right.
  Rect get docket => Rect.fromLTWH(246, standTop - 290, 108, 120);

  /// The wall calendar.
  Rect get calendar => Rect.fromLTWH(254, standTop - 396, 92, 78);

  /// The close-up tray, its picture and its ✕.
  Rect get tray => Rect.fromLTWH(60, standTop - 326, 182, 160);
  Rect get trayArt => Rect.fromLTWH(66, standTop - 284, 170, 116);
  Rect get trayClose => Rect.fromLTWH(tray.right - 40, tray.top, 40, 40);

  /// The counter's back edge (the wall ends here).
  double get counterY => standTop - 312;

  /// Where the guide's bubble sits (parts must stay clear of it).
  Rect get bubble => Rect.fromLTRB(128, standTop - 166, 360, standTop - 112);

  /// The register line under a stamp's pin (nearest line centre), or null.
  int? lineAt(Offset pin) {
    if (pin.dx < 14 || pin.dx > 230) return null;
    for (var k = 0; k < 4; k++) {
      if ((pin.dy - line(k).center.dy).abs() <= 11) return k;
    }
    return null;
  }

  /// A stamp under a finger (the six, or the two docket stamps).
  int? stampAt(Offset p, {required bool docketPhase}) {
    if (docketPhase) {
      for (var i = 0; i < 2; i++) {
        if (docketStamp(i).contains(p)) return i;
      }
      return null;
    }
    for (var i = 0; i < 6; i++) {
      if (stamp(i).inflate(2).contains(p)) return i;
    }
    return null;
  }
}

// ============================================================================
// The back: wall, shelves, the storekeeper, the counter, the calendar
// ============================================================================

/// Three dawn lights for the window (index into this list).
const kM7PpeSkies = [
  [Color(0xFFF6C9A0), Color(0xFFD9D2C4)],
  [Color(0xFFF1DBA8), Color(0xFFE2DCC8)],
  [Color(0xFFE3B7A6), Color(0xFFCFC8BD)],
];

class M7PpeBackPainter extends CustomPainter {
  const M7PpeBackPainter({required this.geo, required this.light, required this.cal});
  final M7PpeGeo geo;
  final int light;
  final M7Calendar cal;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final cy = geo.counterY;
    final sky = kM7PpeSkies[light % kM7PpeSkies.length];
    // The back wall, lit from the window.
    c.drawRect(
      Rect.fromLTWH(0, 0, w, cy + 6),
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [sky[1], const Color(0xFFB9B2A4)]).createShader(Rect.fromLTWH(0, 0, w, cy)),
    );
    // A window with the dawn.
    final win = Rect.fromLTWH(w - 118, math.max(8, cy - 330), 70, 60);
    c.drawRRect(RRect.fromRectAndRadius(win.inflate(4), const Radius.circular(3)), Paint()..color = const Color(0xFF6B5A44));
    c.drawRect(win, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0xFF8FB4D8), sky[0]]).createShader(win));
    c.drawLine(win.topCenter, win.bottomCenter, Paint()..color = const Color(0xFF6B5A44)..strokeWidth = 2);
    // Shelves with boxes and coiled stock.
    final shelf = Paint()..color = const Color(0xFF7A5C38);
    final box = [Paint()..color = const Color(0xFFC9A66B), Paint()..color = const Color(0xFFB98B54), Paint()..color = const Color(0xFFD8BE8C)];
    for (var r = 0; r < 3; r++) {
      final y = cy - 200 + r * 62.0;
      if (y < 60) continue;
      c.drawRect(Rect.fromLTWH(0, y, 190, 5), shelf);
      var x = 6.0;
      var i = r;
      while (x < 176) {
        final bw = 26.0 + (i * 7 % 3) * 8;
        final bh = 24.0 + (i * 5 % 3) * 7;
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y - bh, bw, bh), const Radius.circular(2)), box[i % 3]);
        c.drawLine(Offset(x + bw / 2, y - bh), Offset(x + bw / 2, y), Paint()..color = const Color(0x33000000)..strokeWidth = 1);
        x += bw + 4;
        i++;
      }
    }
    // The storekeeper behind the counter.
    _storekeeper(c, Offset(166, cy + 4));
    // The wall calendar.
    _calendar(c, geo.calendar);
    // The counter: back edge, top, front.
    final top = Rect.fromLTWH(0, cy, w, size.height - cy);
    c.drawRect(top, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: const [Color(0xFFB88A55), Color(0xFF8E6538), Color(0xFF5E4125)]).createShader(top));
    c.drawRect(Rect.fromLTWH(0, cy, w, 4), Paint()..color = const Color(0xFFD9B27A));
    // The rubber mat.
    final mat = geo.mat;
    c.drawRRect(RRect.fromRectAndRadius(mat, const Radius.circular(8)), Paint()..color = const Color(0x55000000));
    c.drawRRect(RRect.fromRectAndRadius(mat.translate(0, -2), const Radius.circular(8)), Paint()..color = const Color(0xFF2F4A3C));
    c.drawRRect(RRect.fromRectAndRadius(mat.translate(0, -2).deflate(4), const Radius.circular(6)), Paint()..color = const Color(0xFF3B5B4A));
  }

  void _storekeeper(Canvas c, Offset base) {
    // Torso in a work coat, head, a cap; arms on the counter.
    final coat = Paint()..color = const Color(0xFF3C5A8C);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: base.translate(0, -34), width: 58, height: 70), const Radius.circular(14)), coat);
    c.drawRect(Rect.fromCenter(center: base.translate(0, -62), width: 16, height: 8), Paint()..color = const Color(0xFFC99673));
    c.drawCircle(base.translate(0, -78), 15, Paint()..color = const Color(0xFFD7A582));
    c.drawArc(Rect.fromCenter(center: base.translate(0, -82), width: 34, height: 28), math.pi, math.pi, true, Paint()..color = const Color(0xFF8A2A2A));
    c.drawRect(Rect.fromLTWH(base.dx - 17, base.dy - 83, 34, 4), Paint()..color = const Color(0xFF8A2A2A));
    c.drawCircle(base.translate(-5, -76), 1.6, Paint()..color = const Color(0xFF2A2018));
    c.drawCircle(base.translate(5, -76), 1.6, Paint()..color = const Color(0xFF2A2018));
    c.drawLine(base.translate(-4, -70), base.translate(4, -70), Paint()..color = const Color(0xFF7A4A3A)..strokeWidth = 1.4..strokeCap = StrokeCap.round);
    // An ID card on a lanyard.
    c.drawLine(base.translate(-6, -62), base.translate(0, -40), Paint()..color = const Color(0xFFE9C46A)..strokeWidth = 1.5);
    c.drawLine(base.translate(6, -62), base.translate(0, -40), Paint()..color = const Color(0xFFE9C46A)..strokeWidth = 1.5);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: base.translate(0, -34), width: 12, height: 15), const Radius.circular(2)), Paint()..color = Colors.white);
    // Hands on the counter.
    final skin = Paint()..color = const Color(0xFFD7A582);
    c.drawOval(Rect.fromCenter(center: base.translate(-28, -2), width: 18, height: 10), skin);
    c.drawOval(Rect.fromCenter(center: base.translate(28, -2), width: 18, height: 10), skin);
  }

  void _calendar(Canvas c, Rect r) {
    c.drawRRect(RRect.fromRectAndRadius(r.translate(2, 3), const Radius.circular(4)), Paint()..color = const Color(0x33000000));
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)), Paint()..color = const Color(0xFFFAF6EA));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.left, r.top, r.width, 20), const Radius.circular(4)), Paint()..color = const Color(0xFFB4262B));
    c.drawCircle(Offset(r.left + 14, r.top + 3), 2.5, Paint()..color = const Color(0xFF444444));
    c.drawCircle(Offset(r.right - 14, r.top + 3), 2.5, Paint()..color = const Color(0xFF444444));
    _text(c, '${cal.monthName} ${cal.year}', Offset(r.center.dx, r.top + 11), 9.5, Colors.white, bold: true, maxW: r.width - 6);
    _text(c, '${cal.day}', Offset(r.center.dx, r.top + 44), 26, const Color(0xFF2A2018), bold: true, maxW: r.width - 6);
    _text(c, cal.dateText, Offset(r.center.dx, r.bottom - 8), 8, const Color(0xFF6A5232), maxW: r.width - 6);
  }

  @override
  bool shouldRepaint(M7PpeBackPainter old) => old.light != light || old.geo.height != geo.height || old.cal != cal;
}

/// Centred text (shrinks to [maxW]).
void _text(Canvas c, String s, Offset at, double size, Color color, {bool bold = false, double maxW = 200, double angle = 0}) {
  final tp = TextPainter(
    text: TextSpan(text: s, style: bangla(fontSize: size, fontWeight: bold ? FontWeight.w900 : FontWeight.w600, color: color, height: 1.1)),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  final k = tp.width > maxW ? maxW / tp.width : 1.0;
  c.save();
  c.translate(at.dx, at.dy);
  if (angle != 0) c.rotate(angle);
  c.scale(k);
  tp.paint(c, Offset(-tp.width / 2, -tp.height / 2));
  c.restore();
}

// ============================================================================
// The items
// ============================================================================

const _tints = [
  [Color(0xFFF2C21B), Color(0xFFC99A0B)],
  [Color(0xFFF3F1EA), Color(0xFFBDB8A8)],
  [Color(0xFFF08A24), Color(0xFFBD6212)],
];

/// An item drawn into [size] with every marking at once.
class M7PiecePainter extends CustomPainter {
  const M7PiecePainter({required this.piece, required this.job, required this.cal});
  final M7Piece piece;
  final M7Job job;
  final M7Calendar cal;

  @override
  void paint(Canvas c, Size size) {
    switch (piece.item) {
      case M7Item.helmet:
        _helmet(c, size);
      case M7Item.shoes:
        _shoes(c, size);
      case M7Item.gloves:
        _gloves(c, size);
      case M7Item.harness:
        _harness(c, size);
    }
  }

  void _helmet(Canvas c, Size s) {
    final col = _tints[piece.tint % 3];
    final cx = s.width / 2;
    final base = s.height * 0.72;
    final rw = s.width * 0.34;
    final dome = Rect.fromCenter(center: Offset(cx, base), width: rw * 2, height: s.height * 1.0);
    c.drawOval(Rect.fromCenter(center: Offset(cx, base + 4), width: rw * 2.7, height: s.height * 0.13), Paint()..color = const Color(0x44000000));
    c.save();
    c.clipRect(Rect.fromLTRB(0, 0, s.width, base));
    c.drawOval(dome, Paint()..shader = RadialGradient(center: const Alignment(-0.3, -0.5), radius: 1.0, colors: [col[0], col[1]]).createShader(dome));
    c.restore();
    // The brim and the ridge.
    final brim = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, base + 1), width: rw * 2.4, height: s.height * 0.1), const Radius.circular(6));
    c.drawRRect(brim, Paint()..color = col[1]);
    c.drawLine(Offset(cx, base - s.height * 0.5), Offset(cx, base - 2), Paint()..color = col[1]..strokeWidth = 3);
    c.drawLine(Offset(cx - rw * 0.55, base - s.height * 0.4), Offset(cx - rw * 0.4, base - 2), Paint()..color = col[1].withValues(alpha: 0.6)..strokeWidth = 2);
    c.drawLine(Offset(cx + rw * 0.55, base - s.height * 0.4), Offset(cx + rw * 0.4, base - 2), Paint()..color = col[1].withValues(alpha: 0.6)..strokeWidth = 2);
    // The IS sticker on the brow.
    final print = m7IsPrint(M7Item.helmet, piece.look);
    if (print != null) {
      final r = Rect.fromCenter(center: Offset(cx, base - s.height * 0.16), width: rw * 1.2, height: s.height * 0.17);
      c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), Paint()..color = Colors.white);
      c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), Paint()..color = const Color(0xFF333333)..style = PaintingStyle.stroke..strokeWidth = 0.8);
      _text(c, print, r.center, 10, const Color(0xFF1B1B1B), bold: true, maxW: r.width - 4);
    }
    if (piece.look == M7Look.cracked) {
      final p = Path()
        ..moveTo(cx + rw * 0.2, base - s.height * 0.48)
        ..lineTo(cx + rw * 0.05, base - s.height * 0.34)
        ..lineTo(cx + rw * 0.3, base - s.height * 0.24)
        ..lineTo(cx + rw * 0.12, base - s.height * 0.1)
        ..lineTo(cx + rw * 0.4, base - 2);
      c.drawPath(p, Paint()..color = const Color(0xFF2B2118)..style = PaintingStyle.stroke..strokeWidth = 2.2..strokeJoin = StrokeJoin.round);
    }
  }

  void _boot(Canvas c, Rect r, {required bool left}) {
    final dir = left ? 1.0 : -1.0;
    final x0 = left ? r.left : r.right;
    final shaft = Path()
      ..moveTo(x0 + dir * r.width * 0.06, r.top)
      ..lineTo(x0 + dir * r.width * 0.46, r.top)
      ..lineTo(x0 + dir * r.width * 0.5, r.top + r.height * 0.58)
      ..quadraticBezierTo(x0 + dir * r.width * 0.74, r.top + r.height * 0.6, x0 + dir * r.width * 0.96, r.top + r.height * 0.72)
      ..lineTo(x0 + dir * r.width * 0.96, r.bottom - r.height * 0.2)
      ..lineTo(x0 + dir * r.width * 0.02, r.bottom - r.height * 0.2)
      ..close();
    c.drawPath(shaft, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3A3A3F), Color(0xFF17171B)]).createShader(r));
    // Toe cap.
    c.drawPath(
      Path()
        ..moveTo(x0 + dir * r.width * 0.66, r.top + r.height * 0.66)
        ..quadraticBezierTo(x0 + dir * r.width * 0.92, r.top + r.height * 0.68, x0 + dir * r.width * 0.96, r.top + r.height * 0.74)
        ..lineTo(x0 + dir * r.width * 0.96, r.bottom - r.height * 0.2)
        ..lineTo(x0 + dir * r.width * 0.66, r.bottom - r.height * 0.2)
        ..close(),
      Paint()..color = const Color(0xFF55555C),
    );
    // The sole.
    final sole = Rect.fromLTRB(math.min(x0, x0 + dir * r.width), r.bottom - r.height * 0.2, math.max(x0, x0 + dir * r.width), r.bottom);
    c.drawRRect(RRect.fromRectAndRadius(sole, const Radius.circular(3)), Paint()..color = const Color(0xFFD6CFBE));
    if (piece.look == M7Look.splitSole) {
      // The sole has come away from the upper.
      c.drawRect(Rect.fromLTRB(sole.left + sole.width * (left ? 0.5 : 0.04), sole.top - 1, sole.left + sole.width * (left ? 0.96 : 0.5), sole.top + 4), Paint()..color = const Color(0xFF0A0A0C));
      c.drawLine(Offset(sole.center.dx, sole.top), Offset(sole.center.dx + dir * 4, sole.bottom), Paint()..color = const Color(0xFF0A0A0C)..strokeWidth = 2);
    }
  }

  void _shoes(Canvas c, Size s) {
    final h = s.height * 0.78;
    final w = s.width * 0.44;
    final y = (s.height - h) / 2;
    _boot(c, Rect.fromLTWH(s.width * 0.04, y, w, h), left: true);
    _boot(c, Rect.fromLTWH(s.width * 0.96 - w, y, w, h), left: false);
    final print = m7IsPrint(M7Item.shoes, piece.look);
    if (print != null) {
      final r = Rect.fromCenter(center: Offset(s.width * 0.04 + w * 0.26, y + h * 0.3), width: w * 0.46, height: h * 0.2);
      c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), Paint()..color = Colors.white);
      _text(c, print, r.center, 8.5, const Color(0xFF1B1B1B), bold: true, maxW: r.width - 3);
    }
  }

  void _glove(Canvas c, Rect r, Color col, Color dark, String cuffText, {required bool tear}) {
    // Cuff.
    final cuff = Rect.fromLTWH(r.left + r.width * 0.12, r.bottom - r.height * 0.34, r.width * 0.76, r.height * 0.34);
    // Palm and fingers.
    final palm = RRect.fromRectAndRadius(Rect.fromLTWH(r.left + r.width * 0.1, r.top + r.height * 0.34, r.width * 0.8, r.height * 0.34), const Radius.circular(8));
    c.drawRRect(palm, Paint()..color = col);
    for (var f = 0; f < 4; f++) {
      final fh = r.height * (0.36 - (f == 0 || f == 3 ? 0.07 : 0));
      final fr = Rect.fromLTWH(r.left + r.width * (0.1 + 0.2 * f), r.top + r.height * 0.36 - fh, r.width * 0.18, fh + 6);
      c.drawRRect(RRect.fromRectAndRadius(fr, const Radius.circular(6)), Paint()..color = col);
      c.drawRRect(RRect.fromRectAndRadius(fr, const Radius.circular(6)), Paint()..color = dark..style = PaintingStyle.stroke..strokeWidth = 0.8);
    }
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.left + r.width * 0.84, r.top + r.height * 0.4, r.width * 0.2, r.height * 0.14), const Radius.circular(6)), Paint()..color = col);
    c.drawRRect(palm, Paint()..color = dark..style = PaintingStyle.stroke..strokeWidth = 0.8);
    // The cuff band with its print.
    c.drawRRect(RRect.fromRectAndRadius(cuff, const Radius.circular(4)), Paint()..color = dark);
    c.drawRRect(RRect.fromRectAndRadius(cuff.deflate(2), const Radius.circular(3)), Paint()..color = col);
    _text(c, cuffText, cuff.center, 8, const Color(0xFF1B1B1B), bold: true, maxW: cuff.width - 6);
    if (tear) {
      final p = Path()
        ..moveTo(r.left + r.width * 0.34, r.top + r.height * 0.4)
        ..lineTo(r.left + r.width * 0.42, r.top + r.height * 0.5)
        ..lineTo(r.left + r.width * 0.36, r.top + r.height * 0.58)
        ..lineTo(r.left + r.width * 0.52, r.top + r.height * 0.62)
        ..lineTo(r.left + r.width * 0.46, r.top + r.height * 0.48)
        ..close();
      c.drawPath(p, Paint()..color = const Color(0xFF3A2A1E));
      c.drawPath(p, Paint()..color = const Color(0xFFF2E3C8)..style = PaintingStyle.stroke..strokeWidth = 1.1);
    }
  }

  void _gloves(Canvas c, Size s) {
    final col = const [Color(0xFFD9541E), Color(0xFFC23B3B), Color(0xFFE08A1E)][piece.tint % 3];
    final dark = Color.lerp(col, Colors.black, 0.45)!;
    final w = s.width * 0.44;
    final text = m7GloveCuff(piece.look, job);
    _glove(c, Rect.fromLTWH(s.width * 0.04, s.height * 0.05, w, s.height * 0.9), col, dark, text, tear: piece.look == M7Look.torn);
    _glove(c, Rect.fromLTWH(s.width * 0.52, s.height * 0.05, w, s.height * 0.9), col, dark, text, tear: false);
  }

  void _harness(Canvas c, Size s) {
    final col = const [Color(0xFF1F5FA8), Color(0xFFB4262B), Color(0xFF2E7D4F)][piece.tint % 3];
    final strap = Paint()
      ..color = col
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.butt
      ..style = PaintingStyle.stroke;
    final stitch = Paint()
      ..color = Colors.white70
      ..strokeWidth = 0.9
      ..style = PaintingStyle.stroke;
    final cx = s.width / 2;
    final top = s.height * 0.08;
    final cut = piece.look == M7Look.cutWebbing;
    // Shoulder straps (a V from the back ring).
    void shoulder(double dir, {required bool broken}) {
      final from = Offset(cx + dir * s.width * 0.2, top);
      final to = Offset(cx + dir * 4, s.height * 0.46);
      if (!broken) {
        c.drawLine(from, to, strap);
        c.drawLine(from, to, stitch);
        return;
      }
      final mid = Offset.lerp(from, to, 0.45)!;
      c.drawLine(from, mid, strap);
      c.drawLine(Offset.lerp(from, to, 0.62)!, to, strap);
      // The frayed ends.
      for (var i = -2; i <= 2; i++) {
        c.drawLine(mid, mid.translate(i * 1.8 + dir * 3, 7 + (i.abs()) * 0.8), Paint()..color = col..strokeWidth = 1.2);
        final m2 = Offset.lerp(from, to, 0.62)!;
        c.drawLine(m2, m2.translate(i * 1.8 - dir * 3, -7 - (i.abs()) * 0.8), Paint()..color = col..strokeWidth = 1.2);
      }
    }

    shoulder(-1, broken: cut);
    shoulder(1, broken: false);
    // Chest strap and the back ring.
    c.drawLine(Offset(cx - s.width * 0.12, s.height * 0.3), Offset(cx + s.width * 0.12, s.height * 0.3), strap);
    c.drawCircle(Offset(cx, top), 6, Paint()..color = const Color(0xFFB9BCC2)..style = PaintingStyle.stroke..strokeWidth = 3);
    // Waist and leg loops.
    c.drawLine(Offset(cx - s.width * 0.2, s.height * 0.5), Offset(cx + s.width * 0.2, s.height * 0.5), strap);
    for (final dir in [-1.0, 1.0]) {
      c.drawOval(Rect.fromCenter(center: Offset(cx + dir * s.width * 0.17, s.height * 0.74), width: s.width * 0.22, height: s.height * 0.4), strap);
    }
    // The label tag hangs at the waist.
    final tag = Rect.fromCenter(center: Offset(cx + s.width * 0.3, s.height * 0.62), width: s.width * 0.26, height: s.height * 0.3);
    c.drawLine(Offset(cx + s.width * 0.2, s.height * 0.5), Offset(tag.center.dx, tag.top), Paint()..color = const Color(0xFF777777)..strokeWidth = 1);
    c.drawRRect(RRect.fromRectAndRadius(tag, const Radius.circular(3)), Paint()..color = Colors.white);
    c.drawRRect(RRect.fromRectAndRadius(tag, const Radius.circular(3)), Paint()..color = const Color(0xFF333333)..style = PaintingStyle.stroke..strokeWidth = 0.8);
    _text(c, 'মেয়াদ', tag.center.translate(0, -tag.height * 0.24), 7, const Color(0xFF333333), maxW: tag.width - 3);
    _text(c, cal.monthsFromNow(piece.labelMonths), tag.center.translate(0, tag.height * 0.06), 8.5, const Color(0xFF1B1B1B), bold: true, maxW: tag.width - 3);
    if (piece.look == M7Look.newType) {
      final nt = Rect.fromCenter(center: Offset(cx - s.width * 0.32, s.height * 0.64), width: s.width * 0.3, height: s.height * 0.2);
      c.drawLine(Offset(cx - s.width * 0.2, s.height * 0.5), Offset(nt.center.dx, nt.top), Paint()..color = const Color(0xFF777777)..strokeWidth = 1);
      c.drawRRect(RRect.fromRectAndRadius(nt, const Radius.circular(3)), Paint()..color = const Color(0xFFD62828));
      _text(c, 'এই প্রথম এল', nt.center, 8, Colors.white, bold: true, maxW: nt.width - 4);
    }
  }

  @override
  bool shouldRepaint(M7PiecePainter old) => old.piece != piece || old.job != job || old.cal != cal;
}

/// The item put on the trainee: the same item scaled to the body part it
/// belongs on, snug or (a wrong size) hanging off it. Nothing is captioned.
class M7TryOnPainter extends CustomPainter {
  const M7TryOnPainter({required this.piece, required this.job, required this.cal});
  final M7Piece piece;
  final M7Job job;
  final M7Calendar cal;

  @override
  void paint(Canvas c, Size s) {
    final wrong = piece.look == M7Look.wrongSize;
    final k = wrong ? (piece.big ? 1.45 : 0.68) : 1.0;
    final inner = M7PiecePainter(piece: piece, job: job, cal: cal);
    void put(Rect r, {Offset shift = Offset.zero}) {
      c.save();
      c.translate(r.center.dx + shift.dx, r.center.dy + shift.dy);
      c.scale(k);
      c.translate(-r.width / 2, -r.height / 2);
      inner.paint(c, r.size);
      c.restore();
    }

    switch (piece.item) {
      case M7Item.helmet:
        put(Rect.fromLTWH(s.width * 0.5 - 21, -6, 42, 34), shift: wrong ? Offset(0, piece.big ? 9 : -9) : const Offset(0, 2));
      case M7Item.shoes:
        put(Rect.fromLTWH(-6, s.height - 26, s.width + 12, 26));
      case M7Item.gloves:
        put(Rect.fromLTWH(-8, s.height * 0.4, s.width + 16, 30));
      case M7Item.harness:
        put(Rect.fromLTWH(-10, s.height * 0.26, s.width + 20, 56), shift: wrong ? Offset(0, piece.big ? 12 : -4) : Offset.zero);
    }
  }

  @override
  bool shouldRepaint(M7TryOnPainter old) => old.piece != piece || old.job != job;
}
