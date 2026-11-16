import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

// The drawn world of lesson 7.6 কাজ 2 "ক্ষতি হলে কার কাছে?"
// (m7_ppe_mishap_route.dart): a roadside 11 kV work site in the morning. The
// van carries the day's docket on its door (today's date, the two marks of the
// work decision and the work pin's pocket); a notice board for the next job;
// the supervisor at his motorbike (name badge); the coworker (badge); a
// roadside hardware shop with its signboard; a dry cloth on the van step; the
// trainee's kit bag; and the trainee himself with a pocket diary in his shirt
// pocket (a scene object, never prompted). Nothing marks a place as the right
// one: the boards, badges and labels are what a worker reads on a site.
//
// Code-drawn, gradients, no bitmaps. Design: 360 wide × the scene's height; a
// tall phone gets more ground, never a stretched site.

/// The four kit items of the lesson.
enum M7PpeItem { gloves, helmet, boots, harness }

/// One mishap: what happened to which item.
enum M7PpeKind {
  glovesTorn(M7PpeItem.gloves, damaged: true, deadlyIfKept: true),
  glovesMuddy(M7PpeItem.gloves, damaged: false),
  helmetCracked(M7PpeItem.helmet, damaged: true),
  helmetDusty(M7PpeItem.helmet, damaged: false),
  bootSplit(M7PpeItem.boots, damaged: true),
  harnessNicked(M7PpeItem.harness, damaged: true, deadlyIfKept: true);

  const M7PpeKind(this.item, {required this.damaged, this.deadlyIfKept = false});
  final M7PpeItem item;

  /// A real fault (tear, crack, split, cut) — not just dirt or dust.
  final bool damaged;

  /// Using it (bagged or worked in) is deadly: torn gloves, cut webbing.
  final bool deadlyIfKept;
}

/// Where things are (design px, 360 wide).
@immutable
class M7PpeGeo {
  const M7PpeGeo._(this.height, this.bottom);

  factory M7PpeGeo.forScene(double height, double inset) => M7PpeGeo._(height, height - inset * 0.5);

  final double height;

  /// The lowest line controls may use (over the system inset).
  final double bottom;

  /// The docket on the van's door, its two marks and the work pin's pocket.
  static const Rect docket = Rect.fromLTRB(16, 124, 190, 236);
  static const Rect goMark = Rect.fromLTRB(24, 172, 104, 226);
  static const Rect stopMark = Rect.fromLTRB(110, 172, 184, 226);
  static const Offset pinHome = Offset(107, 148);
  static const double pinGrabR = 30;

  /// The notice board for the next job (scenery).
  static const Rect board = Rect.fromLTRB(226, 110, 350, 176);

  /// Where the item can be carried to.
  static const Rect supervisor = Rect.fromLTRB(230, 186, 354, 302);
  static const Rect cloth = Rect.fromLTRB(14, 250, 96, 306);
  static const Rect coworker = Rect.fromLTRB(106, 246, 190, 306);
  static const Rect shop = Rect.fromLTRB(224, 310, 354, 394);

  /// The supervisor's reply bubble.
  static const Rect reply = Rect.fromLTRB(226, 136, 352, 190);

  /// The trainee's feet line (clear of the guide at the bottom corner).
  double get feetY => math.max(470, bottom - 170);
  Offset get trainee => Offset(180, feetY);
  Rect get traineeBody => Rect.fromLTRB(146, feetY - 92, 214, feetY + 4);
  Offset get hand => Offset(262, feetY - 50);
  Rect get itemGrab => Rect.fromCenter(center: hand, width: 72, height: 72);
  Rect get bag => Rect.fromLTRB(18, feetY - 100, 100, feetY - 22);
  Rect get diary => Rect.fromCenter(center: Offset(188, feetY - 46), width: 54, height: 54);

  /// Keeping the item in use: the kit bag, or back on the trainee himself.
  bool keepAt(Offset p) => bag.inflate(6).contains(p) || traineeBody.inflate(4).contains(p);

  @override
  bool operator ==(Object other) => other is M7PpeGeo && other.height == height && other.bottom == bottom;

  @override
  int get hashCode => Object.hash(height, bottom);
}

/// The names on boards and badges (a worker's own words).
abstract final class M7PpeSigns {
  static const shop = 'হার্ডওয়্যার';
  static const cloth = 'কাপড়';
  static const bag = 'কিট ব্যাগ';
  static const board = 'পরের কাজ';
  static const supervisorTag = 'সুপারভাইজার';
  static const docket = 'ডকেট';
  static const go = 'কাজ চালাই';
  static const stop = 'এই কাজ আজ নয়';
  static const diary = 'ডায়েরি';
  static const pin = 'কাজের পিন';
  static const glove = 'IS 4770 · টাইপ 4';
  static const helmetIs = 'IS 2925';
  static const bootIs = 'IS 15298';
}

void _text(Canvas c, String s, Offset centre, {double size = 9, Color color = const Color(0xFF2A2018), FontWeight weight = FontWeight.w800, double maxW = 90}) {
  final tp = TextPainter(
    text: TextSpan(text: s, style: bangla(fontSize: size, fontWeight: weight, color: color, height: 1.1)),
    textAlign: TextAlign.center,
    textDirection: TextDirection.ltr,
    maxLines: 2,
  )..layout(maxWidth: maxW);
  tp.paint(c, Offset(centre.dx - tp.width / 2, centre.dy - tp.height / 2));
}

void _board(Canvas c, Rect r, {Color bg = const Color(0xFFF7F1DE)}) {
  final rr = RRect.fromRectAndRadius(r, const Radius.circular(3));
  c.drawRRect(rr.shift(const Offset(0, 1.5)), Paint()..color = const Color(0x55000000));
  c.drawRRect(rr, Paint()..color = bg);
  c.drawRRect(
      rr,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8
        ..color = const Color(0x88000000));
}

// ============================================================================
// The site
// ============================================================================

class M7PpeSceneryPainter extends CustomPainter {
  const M7PpeSceneryPainter({required this.geo, this.date = ''});
  final M7PpeGeo geo;

  /// Today's date on the docket (English digits).
  final String date;

  @override
  void paint(Canvas c, Size size) {
    final h = geo.height;
    // Sky and far fields.
    c.drawRect(
      Rect.fromLTWH(0, 0, 360, 150),
      Paint()
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF9FC7E8), Color(0xFFE6F0F2)])
            .createShader(const Rect.fromLTWH(0, 0, 360, 150)),
    );
    final far = Paint()..color = const Color(0xFF7BA55E);
    for (var i = 0; i < 7; i++) {
      c.drawOval(Rect.fromCenter(center: Offset(20 + i * 56.0, 150), width: 90, height: 26), far);
    }
    // Ground: grass, then the dusty roadside.
    c.drawRect(
      Rect.fromLTWH(0, 148, 360, h - 148),
      Paint()
        ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: const [Color(0xFF86B466), Color(0xFF6E9A52)])
            .createShader(Rect.fromLTWH(0, 148, 360, h - 148)),
    );
    final road = Rect.fromLTWH(0, 300, 360, 14);
    c.drawRect(Rect.fromLTWH(0, 296, 360, 22), Paint()..color = const Color(0xFFB7A98B));
    c.drawRect(road, Paint()..color = const Color(0xFF8E8A82));
    final dash = Paint()
      ..color = const Color(0xCCF3EBD3)
      ..strokeWidth = 1.5;
    for (var x = 6.0; x < 360; x += 20) {
      c.drawLine(Offset(x, 307), Offset(x + 9, 307), dash);
    }
    final rnd = math.Random(5);
    final patch = Paint()..color = const Color(0x22FFFFFF);
    for (var i = 0; i < 18; i++) {
      c.drawOval(Rect.fromCenter(center: Offset(rnd.nextDouble() * 360, 330 + rnd.nextDouble() * (h - 330)), width: 18, height: 6), patch);
    }
    // The next job's notice board on two posts.
    final b = M7PpeGeo.board;
    c.drawRect(Rect.fromLTWH(b.left + 14, b.bottom, 4, 14), Paint()..color = const Color(0xFF6D4C41));
    c.drawRect(Rect.fromLTWH(b.right - 18, b.bottom, 4, 14), Paint()..color = const Color(0xFF6D4C41));
    _board(c, b, bg: const Color(0xFFE9D9B0));
    _text(c, M7PpeSigns.board, Offset(b.center.dx, b.top + 11), size: 10);
    final ink = Paint()
      ..color = const Color(0x553A2A16)
      ..strokeWidth = 1.5;
    for (var i = 0; i < 3; i++) {
      c.drawLine(Offset(b.left + 10, b.top + 24 + i * 11), Offset(b.right - 10 - (i == 2 ? 30 : 0), b.top + 24 + i * 11), ink);
    }
    _van(c);
    _bike(c);
    _shop(c);
    _cloth(c);
    _bag(c);
  }

  void _van(Canvas c) {
    // The van's side, the docket on its door, wheels and the step.
    final body = RRect.fromRectAndRadius(const Rect.fromLTRB(6, 104, 206, 266), const Radius.circular(10));
    c.drawRRect(body.shift(const Offset(0, 4)), Paint()..color = const Color(0x44000000));
    c.drawRRect(
        body,
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF4F1E8), Color(0xFFD7D2C4)])
              .createShader(body.outerRect));
    c.drawRRect(
        body,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFF8D8777));
    c.drawRect(const Rect.fromLTWH(10, 252, 192, 4), Paint()..color = const Color(0xFFD08A2E));
    // The docket (a board on the door).
    const d = M7PpeGeo.docket;
    _board(c, d, bg: const Color(0xFFFFFBEC));
    c.drawRect(Rect.fromLTWH(d.left, d.top, d.width, 20), Paint()..color = const Color(0xFF2D4F73));
    _text(c, '${M7PpeSigns.docket} · $date', Offset(d.center.dx, d.top + 10), size: 10.5, color: Colors.white, maxW: d.width - 8);
    // The work pin's pocket.
    c.drawCircle(M7PpeGeo.pinHome, 19, Paint()..color = const Color(0x22000000));
    // The step, with wheels.
    c.drawRect(const Rect.fromLTRB(14, 266, 96, 272), Paint()..color = const Color(0xFF6A6A6A));
    final wheel = Paint()..color = const Color(0xFF263238);
    c.drawCircle(const Offset(122, 266), 16, wheel);
    c.drawCircle(const Offset(122, 266), 7, Paint()..color = const Color(0xFFB0BEC5));
    c.drawCircle(const Offset(186, 266), 14, wheel);
    c.drawCircle(const Offset(186, 266), 6, Paint()..color = const Color(0xFFB0BEC5));
  }

  void _bike(Canvas c) {
    // The supervisor's motorbike (he stands beside it).
    final wheel = Paint()
      ..color = const Color(0xFF263238)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    c.drawCircle(const Offset(246, 290), 11, wheel);
    c.drawCircle(const Offset(318, 290), 11, wheel);
    final frame = Paint()
      ..color = const Color(0xFFC62828)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    c.drawPath(
        Path()
          ..moveTo(246, 290)
          ..lineTo(268, 270)
          ..lineTo(300, 270)
          ..lineTo(318, 290)
          ..moveTo(300, 270)
          ..lineTo(308, 256),
        frame);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(262, 260, 32, 10), const Radius.circular(4)), Paint()..color = const Color(0xFF37474F));
  }

  void _shop(Canvas c) {
    // A roadside hardware shop.
    const r = M7PpeGeo.shop;
    final wall = RRect.fromRectAndRadius(Rect.fromLTRB(r.left, r.top + 18, r.right, r.bottom), const Radius.circular(4));
    c.drawRRect(wall.shift(const Offset(0, 3)), Paint()..color = const Color(0x44000000));
    c.drawRRect(
        wall,
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE7C99A), Color(0xFFC9A872)])
              .createShader(wall.outerRect));
    c.drawPath(
        Path()
          ..moveTo(r.left - 6, r.top + 22)
          ..lineTo(r.left + 6, r.top + 6)
          ..lineTo(r.right - 6, r.top + 6)
          ..lineTo(r.right + 6, r.top + 22)
          ..close(),
        Paint()..color = const Color(0xFF8D3A2E));
    _board(c, Rect.fromCenter(center: Offset(r.center.dx, r.top + 36), width: 84, height: 18), bg: const Color(0xFFFFF2B8));
    _text(c, M7PpeSigns.shop, Offset(r.center.dx, r.top + 36), size: 10.5);
    c.drawRect(Rect.fromLTWH(r.left + 12, r.top + 52, 40, 32), Paint()..color = const Color(0xFF4E3B2A));
    c.drawRect(Rect.fromLTWH(r.left + 64, r.top + 54, 50, 30), Paint()..color = const Color(0xFF8FB8C9));
    // Tools on the counter.
    final t = Paint()
      ..color = const Color(0xFF455A64)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    c.drawLine(Offset(r.left + 72, r.top + 80), Offset(r.left + 72, r.top + 62), t);
    c.drawLine(Offset(r.left + 86, r.top + 80), Offset(r.left + 92, r.top + 62), t);
    c.drawLine(Offset(r.left + 100, r.top + 80), Offset(r.left + 100, r.top + 64), t);
  }

  void _cloth(Canvas c) {
    // A dry cloth folded on the van step.
    const r = M7PpeGeo.cloth;
    final shadow = RRect.fromRectAndRadius(Rect.fromLTWH(r.left + 8, r.top + 22, r.width - 16, 26), const Radius.circular(6));
    c.drawRRect(shadow.shift(const Offset(0, 3)), Paint()..color = const Color(0x44000000));
    c.drawRRect(
        shadow,
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFFDF2), Color(0xFFE9E3CB)])
              .createShader(shadow.outerRect));
    final fold = Paint()
      ..color = const Color(0x44A89F7F)
      ..strokeWidth = 1.2;
    c.drawLine(Offset(r.left + 14, r.top + 35), Offset(r.right - 14, r.top + 35), fold);
    c.drawLine(Offset(r.left + 30, r.top + 24), Offset(r.left + 30, r.top + 46), fold);
    _text(c, M7PpeSigns.cloth, Offset(r.center.dx, r.top + 10), size: 10, color: const Color(0xFF2A2018), weight: FontWeight.w900);
  }

  void _bag(Canvas c) {
    // The trainee's kit bag on the ground.
    final r = geo.bag;
    final body = RRect.fromRectAndRadius(Rect.fromLTRB(r.left + 6, r.top + 22, r.right - 6, r.bottom), const Radius.circular(10));
    c.drawRRect(body.shift(const Offset(0, 4)), Paint()..color = const Color(0x44000000));
    c.drawRRect(
        body,
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8D6E63), Color(0xFF5D4037)])
              .createShader(body.outerRect));
    c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTRB(r.left + 14, r.top + 34, r.right - 14, r.top + 54), const Radius.circular(5)), Paint()..color = const Color(0x33000000));
    final strap = Paint()
      ..color = const Color(0xFF3E2723)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    c.drawArc(Rect.fromLTRB(r.left + 22, r.top + 6, r.right - 22, r.top + 40), math.pi, math.pi, false, strap);
    _text(c, M7PpeSigns.bag, Offset(r.center.dx, r.bottom - 12), size: 10, color: const Color(0xFFFFF3E0), weight: FontWeight.w900);
  }

  @override
  bool shouldRepaint(M7PpeSceneryPainter old) => old.geo != geo || old.date != date;
}

// ============================================================================
// People
// ============================================================================

enum M7PpeRole { supervisor, coworker, trainee }

/// A man standing, 40 × 64 design px, with a name badge (left or right of his
/// chest). The trainee has a shirt pocket for his diary instead of a badge.
class M7PpePersonPainter extends CustomPainter {
  const M7PpePersonPainter({required this.role, this.name = '', this.badgeRight = false, this.helmet = true});
  final M7PpeRole role;
  final String name;
  final bool badgeRight;

  /// The trainee's own helmet on his head (a dusty helmet put back on).
  final bool helmet;

  @override
  void paint(Canvas c, Size size) {
    final s = size.width / 40;
    c.save();
    c.scale(s, s);
    c.drawOval(Rect.fromCenter(center: const Offset(20, 62), width: 28, height: 6), Paint()..color = const Color(0x44000000));
    final skin = Paint()..color = role == M7PpeRole.supervisor ? const Color(0xFFC68B59) : const Color(0xFFB77A4B);
    final leg = Paint()
      ..color = const Color(0xFF37474F)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    c.drawLine(const Offset(15, 44), const Offset(14, 60), leg);
    c.drawLine(const Offset(25, 44), const Offset(26, 60), leg);
    final shirtColors = switch (role) {
      M7PpeRole.supervisor => const [Color(0xFF8D6E63), Color(0xFF5D4037)],
      M7PpeRole.coworker => const [Color(0xFFFFB74D), Color(0xFFEF6C00)],
      M7PpeRole.trainee => const [Color(0xFF42A5F5), Color(0xFF1E6FB5)],
    };
    final shirt = RRect.fromRectAndRadius(const Rect.fromLTWH(9, 20, 22, 26), const Radius.circular(5));
    c.drawRRect(shirt, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: shirtColors).createShader(shirt.outerRect));
    final arm = Paint()
      ..color = shirtColors.last
      ..strokeWidth = 4.4
      ..strokeCap = StrokeCap.round;
    c.drawLine(const Offset(10, 24), const Offset(6, 40), arm);
    c.drawLine(const Offset(30, 24), const Offset(34, 40), arm);
    c.drawCircle(const Offset(6, 41.5), 2.4, skin);
    c.drawCircle(const Offset(34, 41.5), 2.4, skin);
    c.drawCircle(const Offset(20, 12), 7.5, skin);
    c.drawCircle(const Offset(22.4, 12.6), 0.9, Paint()..color = const Color(0xFF2B1B12));
    c.drawCircle(const Offset(17.6, 12.6), 0.9, Paint()..color = const Color(0xFF2B1B12));
    final hat = switch (role) {
      M7PpeRole.supervisor => const Color(0xFFFFFFFF),
      M7PpeRole.coworker => const Color(0xFFFFD54F),
      M7PpeRole.trainee => const Color(0xFFFFEB3B),
    };
    if (role == M7PpeRole.trainee && !helmet) {
      c.drawArc(Rect.fromCircle(center: const Offset(20, 10), radius: 7.6), math.pi, math.pi, true, Paint()..color = const Color(0xFF2B1B12));
    } else {
      c.drawArc(Rect.fromCircle(center: const Offset(20, 10), radius: 8.4), math.pi, math.pi, true, Paint()..color = hat);
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(10.5, 9, 19, 2.4), const Radius.circular(1.2)), Paint()..color = hat);
      c.drawLine(
          const Offset(20, 2.2),
          const Offset(20, 9),
          Paint()
            ..color = const Color(0x33000000)
            ..strokeWidth = 0.8);
    }
    if (role == M7PpeRole.trainee) {
      // The shirt pocket the diary rides in.
      c.drawRect(const Rect.fromLTWH(22, 26, 7, 8), Paint()..color = const Color(0x44000000));
    } else {
      // The name badge.
      final x = badgeRight ? 22.0 : 10.0;
      final r = Rect.fromLTWH(x, 25, 14, 8);
      c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(1.5)), Paint()..color = const Color(0xFFFAFAFA));
      _text(c, name, r.center, size: 4.6, maxW: 14, weight: FontWeight.w900);
    }
    c.restore();
  }

  @override
  bool shouldRepaint(M7PpePersonPainter old) => old.role != role || old.name != name || old.badgeRight != badgeRight || old.helmet != helmet;
}

/// The pocket diary (a small book with a pen), or a held page of its line.
class M7DiaryPainter extends CustomPainter {
  const M7DiaryPainter({this.written = false, this.holding = false});
  final bool written;
  final bool holding;

  @override
  void paint(Canvas c, Size size) {
    final r = Rect.fromLTWH(size.width * 0.34, size.height * 0.26, size.width * 0.32, size.height * 0.46);
    c.drawRRect(RRect.fromRectAndRadius(r.shift(const Offset(1, 2)), const Radius.circular(2)), Paint()..color = const Color(0x55000000));
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), Paint()..color = const Color(0xFF8E3B2F));
    c.drawLine(
        Offset(r.left + 3, r.top + 2),
        Offset(r.left + 3, r.bottom - 2),
        Paint()
          ..color = const Color(0x55FFFFFF)
          ..strokeWidth = 1.2);
    c.drawLine(
        Offset(r.right - 3, r.top - 3),
        Offset(r.right - 3, r.top + 8),
        Paint()
          ..color = const Color(0xFF263238)
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round);
    if (written) {
      c.drawCircle(Offset(r.center.dx, r.center.dy), 2.4, Paint()..color = const Color(0xFF9BE7A9));
    }
    if (holding) {
      c.drawRRect(
          RRect.fromRectAndRadius(r.inflate(3), const Radius.circular(4)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = const Color(0xCCFFFFFF));
    }
  }

  @override
  bool shouldRepaint(M7DiaryPainter old) => old.written != written || old.holding != holding;
}

/// The work pin on the docket (a map pin).
class M7PinPainter extends CustomPainter {
  const M7PinPainter({this.lifted = false});
  final bool lifted;

  @override
  void paint(Canvas c, Size size) {
    final m = Offset(size.width / 2, size.height / 2);
    final s = size.width / 34;
    c.save();
    c.translate(m.dx, m.dy - (lifted ? 4 : 0));
    c.scale(s, s);
    c.drawOval(Rect.fromCenter(center: const Offset(0, 14), width: lifted ? 18 : 12, height: 4), Paint()..color = const Color(0x55000000));
    c.drawPath(
        Path()
          ..moveTo(0, 14)
          ..lineTo(-6, -2)
          ..arcToPoint(const Offset(6, -2), radius: const Radius.circular(6.4), clockwise: true)
          ..close(),
        Paint()..color = const Color(0xFF1E88E5));
    c.drawCircle(const Offset(0, -5), 6.6, Paint()..color = const Color(0xFF1E88E5));
    c.drawCircle(const Offset(0, -5), 2.6, Paint()..color = Colors.white);
    c.restore();
  }

  @override
  bool shouldRepaint(M7PinPainter old) => old.lifted != lifted;
}

// ============================================================================
// The kit
// ============================================================================

/// One PPE item, drawn in the middle of its box. [spare] = a new one with its
/// IS mark; [clean] = wiped (the mud or dust gone).
class M7ItemPainter extends CustomPainter {
  const M7ItemPainter({required this.kind, this.spare = false, this.clean = false, this.labels = false});
  final M7PpeKind kind;
  final bool spare;
  final bool clean;

  /// Draw the IS marks (for the close view and the spare).
  final bool labels;

  @override
  void paint(Canvas c, Size size) {
    final s = math.min(size.width, size.height) / 100;
    c.save();
    c.translate((size.width - 100 * s) / 2, (size.height - 100 * s) / 2);
    c.scale(s, s);
    c.drawOval(Rect.fromCenter(center: const Offset(50, 92), width: 64, height: 10), Paint()..color = const Color(0x33000000));
    switch (kind.item) {
      case M7PpeItem.gloves:
        _glove(c);
      case M7PpeItem.helmet:
        _helmet(c);
      case M7PpeItem.boots:
        _boot(c);
      case M7PpeItem.harness:
        _harness(c);
    }
    c.restore();
  }

  bool get _dirty => !spare && !clean && kind == M7PpeKind.glovesMuddy;

  void _glove(Canvas c) {
    final base = spare ? const Color(0xFFE65100) : const Color(0xFFD84315);
    final dark = const Color(0xFF8E2A0C);
    final p = Paint()..color = base;
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = dark;
    // Palm and four fingers.
    final palm = RRect.fromRectAndRadius(const Rect.fromLTWH(26, 44, 46, 34), const Radius.circular(10));
    for (var i = 0; i < 4; i++) {
      final f = RRect.fromRectAndRadius(Rect.fromLTWH(27.0 + i * 11.5, 14 + (i == 1 || i == 2 ? -5 : 0), 10, 38), const Radius.circular(5));
      c.drawRRect(f, p);
      c.drawRRect(f, edge);
    }
    final thumb = RRect.fromRectAndRadius(const Rect.fromLTWH(14, 40, 24, 10), const Radius.circular(5));
    c.save();
    c.translate(24, 52);
    c.rotate(-0.7);
    c.translate(-24, -52);
    c.drawRRect(thumb, p);
    c.drawRRect(thumb, edge);
    c.restore();
    c.drawRRect(palm, p);
    c.drawRRect(palm, edge);
    // The cuff with its rating mark.
    final cuff = RRect.fromRectAndRadius(const Rect.fromLTWH(24, 76, 50, 14), const Radius.circular(3));
    c.drawRRect(cuff, Paint()..color = const Color(0xFFFFF3E0));
    c.drawRRect(cuff, edge);
    _text(c, M7PpeSigns.glove, cuff.outerRect.center, size: 5.6, maxW: 48, weight: FontWeight.w900);
    if (kind == M7PpeKind.glovesTorn && !spare) {
      // A rip across the palm, frayed edges.
      final hole = Path()
        ..moveTo(36, 56)
        ..lineTo(44, 50)
        ..lineTo(50, 58)
        ..lineTo(57, 52)
        ..lineTo(62, 62)
        ..lineTo(52, 66)
        ..lineTo(45, 62)
        ..close();
      c.drawPath(hole, Paint()..color = const Color(0xFF263238));
      c.drawPath(
          hole,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..color = const Color(0xFFFFCC80));
    }
    if (_dirty) {
      final mud = Paint()..color = const Color(0xCC5D4037);
      for (final (x, y, r) in const [(34.0, 62.0, 6.0), (52.0, 54.0, 7.0), (62.0, 68.0, 5.0), (40.0, 30.0, 4.5), (60.0, 26.0, 4.0), (48.0, 74.0, 4.0)]) {
        c.drawCircle(Offset(x, y), r, mud);
      }
    }
    if (spare) _shine(c, const Rect.fromLTWH(20, 10, 56, 70));
  }

  void _helmet(Canvas c) {
    final base = spare ? const Color(0xFFFFEB3B) : const Color(0xFFFDD835);
    final dome = Path()
      ..moveTo(18, 62)
      ..cubicTo(18, 24, 82, 24, 82, 62)
      ..close();
    c.drawPath(dome, Paint()..color = base);
    c.drawPath(
        dome,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFF9A7B00));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(10, 60, 80, 9), const Radius.circular(4.5)), Paint()..color = const Color(0xFFF9A825));
    c.drawLine(
        const Offset(50, 30),
        const Offset(50, 60),
        Paint()
          ..color = const Color(0x44000000)
          ..strokeWidth = 3);
    if (kind == M7PpeKind.helmetCracked && !spare) {
      final crack = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFF3E2723);
      c.drawPath(
          Path()
            ..moveTo(60, 34)
            ..lineTo(55, 44)
            ..lineTo(64, 50)
            ..lineTo(58, 60)
            ..moveTo(55, 44)
            ..lineTo(46, 48),
          crack);
    }
    if (kind == M7PpeKind.helmetDusty && !spare && !clean) {
      final dust = Paint()..color = const Color(0x99B8A27A);
      final rnd = math.Random(3);
      for (var i = 0; i < 26; i++) {
        c.drawCircle(Offset(26 + rnd.nextDouble() * 48, 36 + rnd.nextDouble() * 26), 1.6 + rnd.nextDouble() * 1.4, dust);
      }
    }
    if (spare || labels) _text(c, M7PpeSigns.helmetIs, const Offset(50, 76), size: 6.5, maxW: 40, weight: FontWeight.w900, color: const Color(0xFF3E2723));
    if (spare) _shine(c, const Rect.fromLTWH(18, 28, 64, 40));
  }

  void _boot(Canvas c) {
    final leather = spare ? const Color(0xFF6D4C41) : const Color(0xFF5D4037);
    final shaft = RRect.fromRectAndRadius(const Rect.fromLTWH(26, 14, 28, 48), const Radius.circular(6));
    c.drawRRect(shaft, Paint()..color = leather);
    final foot = Path()
      ..moveTo(26, 56)
      ..lineTo(54, 56)
      ..lineTo(60, 62)
      ..lineTo(84, 66)
      ..cubicTo(90, 68, 90, 78, 82, 78)
      ..lineTo(26, 78)
      ..close();
    c.drawPath(foot, Paint()..color = leather);
    c.drawPath(
        foot,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFF3E2723));
    // The sole.
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(24, 78, 66, 8), const Radius.circular(3)), Paint()..color = const Color(0xFF263238));
    if (kind == M7PpeKind.bootSplit && !spare) {
      // The sole split from the upper.
      c.drawPath(
          Path()
            ..moveTo(52, 78)
            ..lineTo(88, 74)
            ..lineTo(90, 86)
            ..lineTo(56, 86)
            ..close(),
          Paint()..color = const Color(0xFF1B1B1B));
      c.drawLine(
          const Offset(52, 78),
          const Offset(90, 74),
          Paint()
            ..color = const Color(0xFFBCAAA4)
            ..strokeWidth = 1.6);
    }
    if (spare || labels) _text(c, M7PpeSigns.bootIs, const Offset(40, 42), size: 6, maxW: 26, color: Colors.white, weight: FontWeight.w900);
    if (spare) _shine(c, const Rect.fromLTWH(24, 14, 64, 72));
  }

  void _harness(Canvas c) {
    final web = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.butt
      ..color = spare ? const Color(0xFFFF8F00) : const Color(0xFFF57C00);
    // Shoulder straps in an X, a chest strap and two leg loops.
    c.drawLine(const Offset(30, 12), const Offset(68, 56), web);
    c.drawLine(const Offset(70, 12), const Offset(32, 56), web);
    c.drawLine(const Offset(34, 34), const Offset(66, 34), web);
    c.drawArc(const Rect.fromLTWH(24, 52, 24, 30), 0, math.pi * 2, false, web);
    c.drawArc(const Rect.fromLTWH(52, 52, 24, 30), 0, math.pi * 2, false, web);
    // The D-ring and the buckles.
    final metal = Paint()..color = const Color(0xFFB0BEC5);
    c.drawCircle(const Offset(50, 36), 5, metal);
    c.drawCircle(
        const Offset(50, 36),
        2.2,
        Paint()
          ..color = const Color(0xFF607D8B)
          ..style = PaintingStyle.fill);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(30, 30, 8, 8), const Radius.circular(1.5)), metal);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(62, 30, 8, 8), const Radius.circular(1.5)), metal);
    if (kind == M7PpeKind.harnessNicked && !spare) {
      // A cut across a strap: the webbing frays open.
      c.drawPath(
          Path()
            ..moveTo(40, 38)
            ..lineTo(48, 33)
            ..lineTo(50, 42)
            ..lineTo(44, 47)
            ..close(),
          Paint()..color = const Color(0xFF263238));
      final fray = Paint()
        ..color = const Color(0xFFFFE0B2)
        ..strokeWidth = 1.2;
      c.drawLine(const Offset(40, 38), const Offset(35, 40), fray);
      c.drawLine(const Offset(41, 41), const Offset(36, 45), fray);
      c.drawLine(const Offset(48, 33), const Offset(52, 29), fray);
      c.drawLine(const Offset(50, 42), const Offset(54, 46), fray);
    }
    if (spare) _shine(c, const Rect.fromLTWH(22, 8, 56, 76));
  }

  /// A new item's sheen and its tag.
  void _shine(Canvas c, Rect r) {
    c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(r.left + 4, r.top + 4, 6, r.height * 0.5), const Radius.circular(3)), Paint()..color = const Color(0x55FFFFFF));
    c.drawCircle(Offset(r.right - 2, r.top + 4), 5, Paint()..color = const Color(0xFF43A047));
    c.drawPath(
        Path()
          ..moveTo(r.right - 5, r.top + 4)
          ..lineTo(r.right - 3, r.top + 6.4)
          ..lineTo(r.right + 1.2, r.top + 1.6),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round
          ..color = Colors.white);
  }

  @override
  bool shouldRepaint(M7ItemPainter old) => old.kind != kind || old.spare != spare || old.clean != clean || old.labels != labels;
}

/// The consequence of a deadly choice, in colour over the frozen scene: a flash
/// of arc light and sparks around [at]. [v] runs 0 → 1.
class M7FlashPainter extends CustomPainter {
  const M7FlashPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final glow = Curves.easeOut.transform(v.clamp(0.0, 1.0));
    c.drawCircle(
      at,
      30 + 160 * glow,
      Paint()
        ..shader = RadialGradient(colors: [Color.fromRGBO(255, 244, 200, 0.9 * (1 - glow * 0.5)), const Color(0x00FFB300)]).createShader(Rect.fromCircle(center: at, radius: 30 + 160 * glow)),
    );
    final rnd = math.Random(11);
    final spark = Paint()
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..color = Color.fromRGBO(255, 214, 79, 1 - glow * 0.4);
    for (var i = 0; i < 16; i++) {
      final a = rnd.nextDouble() * math.pi * 2;
      final d0 = 18 + rnd.nextDouble() * 20, d1 = d0 + 20 + 90 * glow * (0.5 + rnd.nextDouble());
      c.drawLine(at + Offset(math.cos(a), math.sin(a)) * d0, at + Offset(math.cos(a), math.sin(a)) * d1, spark);
    }
  }

  @override
  bool shouldRepaint(M7FlashPainter old) => old.v != v || old.at != at;
}
