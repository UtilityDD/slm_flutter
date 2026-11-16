import 'dart:math' as math;

import 'package:flutter/material.dart';

// The drawn world of lesson 7.4 কাজ 1 "সইয়ের আগে" (m7_ptw_sign.dart): the
// issuing counter of a 33/11 kV substation control room. Behind the counter
// the issuer (the control room operator) and a soft-focus control panel (no
// readable breaker state), a wall clock and a door with the crew van outside;
// on the counter, in front of the player (today's receiver), the PTW carbon
// book, the pen and — once signed — the two perforated stubs to tear the
// player's copy from.
//
// The sheets themselves are widgets (m7_ptw_sign.dart, text in Bangla); this
// file holds the geometry both use (design px, 360 wide; the sheet in its own
// 300 × 250 units, scaled into the book), the room painter, the signature
// scribble, the live ink and the deadly inset (a crew on a line nobody
// certified). No text in the art. Code-drawn, gradients, no bitmaps.

/// The copies of the carbon book (which one is on top is dealt).
enum M7PtwCopy { control, field }

/// The boxes of a sheet (a box tapped in a send-back).
enum M7PtwBox { number, feeder, date, time, issuer, condition, receiver }

/// The sheet's own layout (300 × 250 units).
abstract final class M7PtwSheetGeo {
  static const Size size = Size(300, 250);

  /// The top edge (the book's spine strip): swiped up = sent back; the folded
  /// top sheet lies here while the copy beneath is shown.
  static const Rect spine = Rect.fromLTWH(0, 0, 300, 26);
  static const Rect label = Rect.fromLTWH(8, 28, 284, 20);
  static const Rect number = Rect.fromLTWH(8, 52, 138, 28);
  static const Rect feeder = Rect.fromLTWH(154, 52, 138, 28);
  static const Rect date = Rect.fromLTWH(8, 84, 138, 28);
  static const Rect time = Rect.fromLTWH(154, 84, 138, 28);
  static const Rect issuer = Rect.fromLTWH(8, 116, 284, 32);
  static const Rect condLabel = Rect.fromLTWH(8, 150, 120, 14);
  static Rect cond(int i) => Rect.fromLTWH(8, 166 + 22.0 * i, 284, 20);

  /// The receiver's box and its dotted line (traced to sign).
  static const Rect receiver = Rect.fromLTWH(8, 212, 236, 36);
  static const double lineY = 238;
  static const double lineX0 = 98;
  static const double lineX1 = 236;

  /// How far off the dotted line a stroke still counts (units).
  static const double lineSlack = 20;

  /// The dog-eared corner the top sheet is peeled up by.
  static const Rect corner = Rect.fromLTWH(250, 210, 50, 40);

  /// Every box (condition lines one by one), with its line for a condition.
  static List<(M7PtwBox, int, Rect)> get boxes => [
        (M7PtwBox.number, 0, number),
        (M7PtwBox.feeder, 0, feeder),
        (M7PtwBox.date, 0, date),
        (M7PtwBox.time, 0, time),
        (M7PtwBox.issuer, 0, issuer),
        (M7PtwBox.condition, 0, cond(0)),
        (M7PtwBox.condition, 1, cond(1)),
        (M7PtwBox.receiver, 0, receiver),
      ];

  /// The box at [p] (sheet units), or null.
  static (M7PtwBox, int)? boxAt(Offset p) {
    for (final (b, i, r) in boxes) {
      if (r.inflate(1).contains(p)) return (b, i);
    }
    return null;
  }

  /// The share of the dotted line covered by [points] (sheet units): the
  /// line in 20 slices, a slice counts when a point lies on it.
  static double coverage(List<Offset> points) {
    const n = 20;
    final hit = List<bool>.filled(n, false);
    for (final p in points) {
      if ((p.dy - lineY).abs() > lineSlack) continue;
      final f = (p.dx - lineX0) / (lineX1 - lineX0);
      if (f < 0 || f > 1) continue;
      hit[math.min(n - 1, (f * n).floor())] = true;
    }
    // A fast stroke leaves gaps between its points: a slice between two hit
    // slices that a straight piece of the stroke crosses counts too.
    final pts = [for (final p in points) if ((p.dy - lineY).abs() <= lineSlack) p];
    for (var i = 1; i < pts.length; i++) {
      final a = (pts[i - 1].dx - lineX0) / (lineX1 - lineX0);
      final b = (pts[i].dx - lineX0) / (lineX1 - lineX0);
      final lo = math.max(0.0, math.min(a, b)), hi = math.min(1.0, math.max(a, b));
      if (hi - lo > 0.25) continue;
      for (var k = (lo * n).floor(); k < math.min(n, (hi * n).ceil()); k++) {
        hit[k] = true;
      }
    }
    return hit.where((h) => h).length / n;
  }
}

/// Where things are on the scene (design px, 360 wide).
@immutable
class M7PtwGeo {
  const M7PtwGeo._(this.height, this.book, this.s);

  factory M7PtwGeo.forScene(double height, double inset) {
    final bottom = height - (height >= 700 ? 245 : 195) - inset * 0.5;
    final s = math.min(1.08, math.min((bottom - bookTop) / M7PtwSheetGeo.size.height, 340 / M7PtwSheetGeo.size.width));
    final w = M7PtwSheetGeo.size.width * s;
    return M7PtwGeo._(height, Rect.fromLTWH((360 - w) / 2, bookTop, w, M7PtwSheetGeo.size.height * s), s);
  }

  final double height;

  /// The book's sheet on the counter.
  final Rect book;

  /// Sheet units → design px.
  final double s;

  /// The book's top (just over the counter's front edge).
  static const double bookTop = 206;

  /// The counter's back edge (the issuer stands behind it).
  static const double counterY = 198;

  Rect map(Rect r) => Rect.fromLTWH(book.left + r.left * s, book.top + r.top * s, r.width * s, r.height * s);
  Offset mapP(Offset p) => Offset(book.left + p.dx * s, book.top + p.dy * s);
  Offset toSheet(Offset p) => Offset((p.dx - book.left) / s, (p.dy - book.top) / s);
  bool onBook(Offset p) => book.contains(p);

  Rect get spine => map(M7PtwSheetGeo.spine);
  Rect get corner => map(M7PtwSheetGeo.corner);
  Rect get receiver => map(M7PtwSheetGeo.receiver);
  Offset get lineStart => mapP(const Offset(M7PtwSheetGeo.lineX0, M7PtwSheetGeo.lineY));
  Offset get lineEnd => mapP(const Offset(M7PtwSheetGeo.lineX1, M7PtwSheetGeo.lineY));
  Rect cond(int i) => map(M7PtwSheetGeo.cond(i));
  List<Rect> get boxes => [for (final (_, _, r) in M7PtwSheetGeo.boxes) map(r)];

  /// The pen on the counter (under the book, left: clear of the guide).
  Rect get pen => Rect.fromLTWH(16, book.bottom + 8, 124, 34);

  /// The two perforated stubs (0: the top sheet's copy, 1: the one beneath).
  Rect tab(int i) => Rect.fromLTWH(12, book.bottom + 50 + 46.0 * i, 128, 40);

  /// The issuer (painted) and his speech bubble (a widget).
  Rect get issuer => const Rect.fromLTWH(18, 104, 76, 94);
  Rect get bubble => const Rect.fromLTWH(98, 112, 212, 56);

  /// Where the deadly inset sits.
  Rect get inset => Rect.fromCenter(center: Offset(180, book.center.dy), width: 300, height: 220);

  @override
  bool operator ==(Object other) => other is M7PtwGeo && other.height == height && other.book == book;

  @override
  int get hashCode => Object.hash(height, book);
}

/// The control room behind the counter and the counter itself.
class M7PtwRoomPainter extends CustomPainter {
  M7PtwRoomPainter({required this.geo});
  final M7PtwGeo geo;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width, h = size.height;
    // The back wall.
    c.drawRect(
      Rect.fromLTWH(0, 0, w, M7PtwGeo.counterY + 4),
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2B3A4E), Color(0xFF4A5C70)]).createShader(Rect.fromLTWH(0, 0, w, M7PtwGeo.counterY)),
    );
    // The soft-focus control panel (blocks and dim lamps, nothing readable).
    final panel = const Rect.fromLTWH(196, 92, 92, 100);
    c.drawRRect(RRect.fromRectAndRadius(panel, const Radius.circular(4)), Paint()..color = const Color(0xFF6F7F8C));
    for (var i = 0; i < 3; i++) {
      final r = Rect.fromLTWH(panel.left + 8 + i * 28.0, panel.top + 10, 20, 34);
      c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), Paint()..color = const Color(0xFF55636F));
      c.drawCircle(Offset(r.center.dx, panel.top + 58), 4.5, Paint()..color = const Color(0xFF8E9AA4));
      c.drawRect(Rect.fromLTWH(r.left, panel.top + 70, 20, 20), Paint()..color = const Color(0xFF5E6C78));
    }
    c.drawRRect(RRect.fromRectAndRadius(panel.inflate(3), const Radius.circular(6)), Paint()
      ..color = const Color(0x332B3A4E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6);
    // The wall clock.
    const clock = Offset(160, 96);
    c.drawCircle(clock, 15, Paint()..color = const Color(0xFFF4F1E8));
    c.drawCircle(clock, 15, Paint()
      ..color = const Color(0xFF26303D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5);
    final hand = Paint()
      ..color = const Color(0xFF26303D)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    c.drawLine(clock, clock + const Offset(-6, -5), hand);
    c.drawLine(clock, clock + const Offset(0, -11), hand..strokeWidth = 1.4);
    // The door and the crew van outside.
    final door = const Rect.fromLTWH(298, 84, 56, 114);
    c.drawRect(door, Paint()..color = const Color(0xFF3A2C20));
    final glass = door.deflate(6);
    c.drawRect(glass, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF9CC9E8), Color(0xFFD8E9C8)]).createShader(glass));
    final van = Rect.fromLTWH(glass.left + 4, glass.bottom - 34, glass.width + 2, 22);
    c.save();
    c.clipRect(glass);
    c.drawRRect(RRect.fromRectAndRadius(van, const Radius.circular(4)), Paint()..color = const Color(0xFFE8E2D2));
    c.drawRect(Rect.fromLTWH(van.left, van.top + 9, van.width, 4), Paint()..color = const Color(0xFF2E6FB0));
    c.drawRect(Rect.fromLTWH(van.left + 6, van.top + 2, 14, 7), Paint()..color = const Color(0xFF5A7890));
    for (final x in [van.left + 9, van.right - 12]) {
      c.drawCircle(Offset(x, van.bottom), 4, Paint()..color = const Color(0xFF1C1C1C));
    }
    c.restore();
    // The issuer behind the counter (shoulders and head).
    final i = geo.issuer;
    final body = Path()
      ..moveTo(i.left + 4, i.bottom)
      ..quadraticBezierTo(i.left + 6, i.top + 50, i.center.dx, i.top + 46)
      ..quadraticBezierTo(i.right - 6, i.top + 50, i.right - 4, i.bottom)
      ..close();
    c.drawPath(body, Paint()..shader = const LinearGradient(colors: [Color(0xFF8FB8DA), Color(0xFF5E8DB6)]).createShader(i));
    c.drawLine(Offset(i.center.dx, i.top + 48), Offset(i.center.dx, i.bottom), Paint()
      ..color = const Color(0xFF4C7AA2)
      ..strokeWidth = 1.5);
    final head = Offset(i.center.dx, i.top + 26);
    c.drawCircle(head, 17, Paint()..color = const Color(0xFFC98E62));
    c.drawArc(Rect.fromCircle(center: head.translate(0, -3), radius: 17), math.pi, math.pi, true, Paint()..color = const Color(0xFF2A1E18));
    c.drawCircle(head.translate(-6, 2), 1.8, Paint()..color = const Color(0xFF2A1E18));
    c.drawCircle(head.translate(6, 2), 1.8, Paint()..color = const Color(0xFF2A1E18));
    c.drawArc(Rect.fromCenter(center: head.translate(0, 8), width: 10, height: 5), 0, math.pi, false, Paint()
      ..color = const Color(0xFF6E3B2A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4);
    // The counter top, the player's side of it to the foot of the screen.
    final top = Rect.fromLTWH(0, M7PtwGeo.counterY, w, h - M7PtwGeo.counterY);
    c.drawRect(top, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF9A6B42), Color(0xFF6E4728)]).createShader(top));
    c.drawRect(Rect.fromLTWH(0, M7PtwGeo.counterY, w, 5), Paint()..color = const Color(0xFFB98A5C));
    final grain = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 1;
    for (var y = M7PtwGeo.counterY + 22; y < h; y += 26) {
      c.drawLine(Offset(0, y), Offset(w, y + 6), grain);
    }
    // The book's board under the sheet.
    final b = geo.book.inflate(6);
    c.drawRRect(RRect.fromRectAndRadius(b.translate(0, 4), const Radius.circular(8)), Paint()..color = const Color(0x55000000));
    c.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(8)), Paint()..color = const Color(0xFF2F4A63));
  }

  @override
  bool shouldRepaint(M7PtwRoomPainter old) => old.geo != geo;
}

/// A signature: a quick cursive scribble, the same for one [seed].
class M7PtwScribblePainter extends CustomPainter {
  M7PtwScribblePainter({required this.seed, this.color = const Color(0xFF1A3A8A)});
  final int seed;
  final Color color;

  @override
  void paint(Canvas c, Size size) {
    final r = math.Random(seed);
    final path = Path();
    final y0 = size.height * 0.62;
    var x = size.width * 0.06;
    path.moveTo(x, y0);
    while (x < size.width * 0.9) {
      final dx = size.width * (0.06 + r.nextDouble() * 0.07);
      final up = size.height * (0.25 + r.nextDouble() * 0.35);
      path.cubicTo(x + dx * 0.2, y0 - up, x + dx * 0.8, y0 - up, x + dx, y0 + size.height * 0.08 * (r.nextDouble() - 0.3));
      x += dx;
    }
    path.moveTo(size.width * 0.1, y0 + size.height * 0.18);
    path.quadraticBezierTo(size.width * 0.5, y0 + size.height * 0.06, size.width * 0.86, y0 + size.height * 0.14);
    c.drawPath(path, Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(M7PtwScribblePainter old) => old.seed != seed || old.color != color;
}

/// The receiver's own strokes (sheet units), blue ink or carbon.
class M7PtwInkPainter extends CustomPainter {
  M7PtwInkPainter({required this.points, required this.color, required this.count});
  final List<Offset> points;
  final Color color;

  /// The number of points (the list grows in place while tracing).
  final int count;

  @override
  void paint(Canvas c, Size size) {
    if (points.length < 2) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    c.drawPath(path, Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(M7PtwInkPainter old) => old.count != count || old.color != color || !identical(old.points, points);
}

/// The deadly inset, in colour over the grey counter: the crew up a pole on a
/// line nobody certified dead, the arc, the fall ([v] 0 → 1).
class M7PtwInsetPainter extends CustomPainter {
  M7PtwInsetPainter({required this.rect, required this.v});
  final Rect rect;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final a = v.clamp(0.0, 1.0);
    final r = Rect.lerp(rect.deflate(30), rect, Curves.easeOutBack.transform(a))!;
    c.save();
    c.clipRRect(RRect.fromRectAndRadius(r, const Radius.circular(14)));
    c.drawRect(r, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF7FB6E6), Color(0xFFE7F0D8)]).createShader(r));
    c.drawRect(Rect.fromLTWH(r.left, r.bottom - 26, r.width, 26), Paint()..color = const Color(0xFF6E9A4A));
    // The pole, its cross-arm and the line.
    final pole = Rect.fromLTWH(r.center.dx - 6, r.top + 26, 12, r.height - 40);
    c.drawRect(pole, Paint()..color = const Color(0xFF8A8F94));
    final arm = Rect.fromLTWH(r.center.dx - 70, r.top + 40, 140, 7);
    c.drawRect(arm, Paint()..color = const Color(0xFF5B6168));
    final wire = Paint()
      ..color = const Color(0xFF2A2A2A)
      ..strokeWidth = 2;
    for (final x in [arm.left + 8, arm.right - 8]) {
      c.drawLine(Offset(r.left, r.top + 34), Offset(x, arm.top - 2), wire);
      c.drawLine(Offset(x, arm.top - 2), Offset(r.right, r.top + 34), wire);
    }
    // The lineman at the cross-arm (falling back as v ends).
    final fall = math.max(0.0, (a - 0.6) / 0.4);
    final man = Offset(r.center.dx + 22 + fall * 18, r.top + 70 + fall * 60);
    c.save();
    c.translate(man.dx, man.dy);
    c.rotate(fall * 0.9);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-8, -6, 16, 30), const Radius.circular(5)), Paint()..color = const Color(0xFF2E6FB0));
    c.drawCircle(const Offset(0, -14), 8, Paint()..color = const Color(0xFFC98E62));
    c.drawArc(const Rect.fromLTWH(-9, -24, 18, 14), math.pi, math.pi, true, Paint()..color = const Color(0xFFF2C230));
    c.drawLine(const Offset(-4, 0), const Offset(-20, -22), Paint()
      ..color = const Color(0xFF2E6FB0)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round);
    c.restore();
    // The arc off the wire at his hand.
    if (a > 0.25) {
      final at = Offset(r.center.dx + 2, r.top + 46);
      final glow = Paint()..shader = RadialGradient(colors: [const Color(0xFFFFFFFF), const Color(0xCCFFE066), const Color(0x00FF8A00)]).createShader(Rect.fromCircle(center: at, radius: 40));
      c.drawCircle(at, 40 * math.min(1.0, (a - 0.25) * 3), glow);
      final bolt = Path()
        ..moveTo(at.dx - 2, at.dy - 4)
        ..lineTo(at.dx + 10, at.dy + 10)
        ..lineTo(at.dx + 2, at.dy + 12)
        ..lineTo(at.dx + 14, at.dy + 28);
      c.drawPath(bolt, Paint()
        ..color = const Color(0xFFFFF59D)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3);
    }
    c.restore();
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(14)), Paint()
      ..color = const Color(0xFFF2C230)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(M7PtwInsetPainter old) => old.v != v || old.rect != rect;
}
