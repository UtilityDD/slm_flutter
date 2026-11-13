import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The drawn world of lesson 5.1 কাজ 1 "কন্ট্রোল রুমের ফোন" (m5_trip_call.dart):
// the section office's duty desk, seen over the trainee's shoulder.
//
//  • The cork board on the wall: the feeder map (the substation on the left,
//    the feeder running right through four sections — trees, river, market,
//    fields — in dealt places, all drawn with the same frame and weight) and,
//    under it, three suspect photo cards (a branch on the line, a bird on an
//    insulator, two wires touching). The red pin and the van magnet wait in
//    the board's right-hand column, clear of every card and section.
//  • A band of wall: the wall clock (the shift) and the window (the weather
//    of this call — storm, clear or windy — and the van outside).
//  • The desk: the notepad on the left, the phone on the right.
//
// No text in the art (names and labels are widgets on top). Code-drawn,
// gradients, no bitmaps. Design: 360 wide × the scene's height; a tall phone
// gets a taller board, never a stretched one.

/// The four kinds of section on a feeder map.
enum M5TripArea { trees, river, market, fields }

/// The suspect photo cards (lesson 5.1 point 3's three examples).
enum M5TripSuspect { branch, bird, clash }

/// The weather in the window (and at the trip).
enum M5TripSky { storm, clear, windy }

/// Where things are (design px, 360 wide).
@immutable
class M5TripGeo {
  const M5TripGeo._(this.height, this.deskY);

  factory M5TripGeo.forScene(double height) => M5TripGeo._(height, (height - 380).clamp(340.0, 600.0));

  final double height;

  /// The desk's front edge (the top of the desk).
  final double deskY;

  /// The cork board.
  Rect get board => Rect.fromLTRB(10, 96, 350, deskY - 70);

  /// The top of the suspect cards' row.
  double get cardsTop => board.top + board.height * 0.52;
  double get cardH => math.min(118.0, board.bottom - 8 - cardsTop);

  /// The feeder map (upper part of the board).
  Rect get map => Rect.fromLTRB(18, board.top + 8, 342, cardsTop - 8);
  Rect get substation => Rect.fromLTWH(20, map.top + 22, 32, 40);
  double get feederY => map.top + 10;

  /// The section at map place [i] (0 = next to the substation).
  Rect section(int i) => Rect.fromLTWH(58 + i * 71.0, map.top + 18, 67, map.height - 20);

  /// The suspect card at row place [i].
  Rect card(int i) => Rect.fromLTWH(18 + i * 88.0, cardsTop, 80, cardH);

  /// The red pin and the van magnet at home (the board's right column).
  Offset get pinHome => Offset(318, cardsTop + 22);
  Offset get vanHome => Offset(318, cardsTop + cardH - 20);
  Rect get pinHit => Rect.fromCenter(center: pinHome, width: 52, height: 52);
  Rect get vanHit => Rect.fromCenter(center: vanHome, width: 60, height: 44);

  /// The wall clock and the window (between the board and the desk).
  Rect get clock => Rect.fromLTWH(22, deskY - 60, 92, 40);
  Rect get window => Rect.fromLTRB(214, deskY - 66, 350, deskY - 6);

  /// The operator's words (over the clock while the handset is up).
  Rect get bubble => Rect.fromLTRB(10, deskY - 68, 206, deskY - 4);

  /// The notepad on the desk.
  Rect get notepad => Rect.fromLTRB(12, deskY + 8, 228, math.min(height - 40, deskY + 236));

  /// The phone: its base, the handset at rest and lifted.
  Rect get phoneBase => Rect.fromLTWH(246, deskY + 30, 96, 50);
  Rect get handsetRest => Rect.fromLTWH(240, deskY + 10, 108, 30);
  Rect get handsetUp => handsetRest.translate(0, -28);

  @override
  bool operator ==(Object other) => other is M5TripGeo && other.height == height && other.deskY == deskY;

  @override
  int get hashCode => Object.hash(height, deskY);
}

/// The room for this call.
@immutable
class M5TripRoom {
  const M5TripRoom({required this.sky, required this.day, required this.map, required this.cards});
  final M5TripSky sky;
  final bool day;

  /// The four sections, map place 0..3.
  final List<M5TripArea> map;

  /// The three suspect cards, row place 0..2.
  final List<M5TripSuspect> cards;

  @override
  bool operator ==(Object other) =>
      other is M5TripRoom && other.sky == sky && other.day == day && listEquals(other.map, map) && listEquals(other.cards, cards);

  @override
  int get hashCode => Object.hash(sky, day, Object.hashAll(map), Object.hashAll(cards));
}

/// The still room: wall, board, map, cards, clock frame, window, desk,
/// notepad paper and the phone base.
class M5TripPainter extends CustomPainter {
  const M5TripPainter({required this.geo, required this.room});
  final M5TripGeo geo;
  final M5TripRoom room;

  @override
  void paint(Canvas canvas, Size size) {
    final g = geo;
    // Wall.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, 360, g.deskY + 4),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: room.day ? const [Color(0xFF6E7F8E), Color(0xFF8C9AA3)] : const [Color(0xFF1A2433), Color(0xFF2A3647)],
        ).createShader(Rect.fromLTWH(0, 0, 360, g.deskY)),
    );
    _board(canvas);
    _clockFrame(canvas);
    _window(canvas);
    _desk(canvas, size);
  }

  void _board(Canvas canvas) {
    final b = geo.board;
    final frame = RRect.fromRectAndRadius(b.inflate(5), const Radius.circular(8));
    canvas.drawRRect(frame.shift(const Offset(0, 4)), Paint()..color = const Color(0x55000000));
    canvas.drawRRect(frame, Paint()..color = const Color(0xFF5B3A22));
    canvas.drawRRect(
      RRect.fromRectAndRadius(b, const Radius.circular(4)),
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFFC79A64), Color(0xFFB4834E)], begin: Alignment.topLeft, end: Alignment.bottomRight)
            .createShader(b),
    );
    // Cork speckle (seeded, still).
    final rng = math.Random(7);
    final dot = Paint()..color = const Color(0x22000000);
    for (var i = 0; i < 160; i++) {
      canvas.drawCircle(Offset(b.left + rng.nextDouble() * b.width, b.top + rng.nextDouble() * b.height), 0.9 + rng.nextDouble(), dot);
    }
    _map(canvas);
    for (var i = 0; i < room.cards.length; i++) {
      _card(canvas, geo.card(i), room.cards[i]);
    }
    // The pin cushion and the magnet strip (the tokens are drawn on top).
    final col = Rect.fromLTRB(290, geo.cardsTop - 2, 346, geo.cardsTop + geo.cardH + 2);
    canvas.drawRRect(RRect.fromRectAndRadius(col, const Radius.circular(8)), Paint()..color = const Color(0x33000000));
  }

  void _map(Canvas canvas) {
    final m = geo.map;
    canvas.drawRRect(RRect.fromRectAndRadius(m, const Radius.circular(4)), Paint()..color = const Color(0xFFF3EEDC));
    canvas.drawRRect(
      RRect.fromRectAndRadius(m, const Radius.circular(4)),
      Paint()
        ..color = const Color(0xFF8C7A57)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    // Map pins at the corners.
    for (final c in [m.topLeft + const Offset(5, 5), m.topRight + const Offset(-5, 5)]) {
      canvas.drawCircle(c, 3, Paint()..color = const Color(0xFF6B7C8F));
    }
    for (var i = 0; i < room.map.length; i++) {
      _section(canvas, geo.section(i), room.map[i]);
    }
    // The substation and the feeder through every section.
    final s = geo.substation;
    canvas.drawRect(s, Paint()..color = const Color(0xFF8D99A6));
    final grid = Paint()
      ..color = const Color(0xFF4D5966)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawRect(s, grid);
    for (var k = 1; k < 4; k++) {
      canvas.drawLine(Offset(s.left + k * s.width / 4, s.top), Offset(s.left + k * s.width / 4, s.bottom), grid);
    }
    final y = geo.feederY;
    final line = Paint()
      ..color = const Color(0xFF263241)
      ..strokeWidth = 2.2;
    canvas.drawLine(Offset(s.center.dx, s.top), Offset(s.center.dx, y), line);
    canvas.drawLine(Offset(s.center.dx, y), Offset(m.right - 6, y), line);
    final pole = Paint()..color = const Color(0xFF263241);
    for (var i = 0; i < 4; i++) {
      final r = geo.section(i);
      canvas.drawCircle(Offset(r.center.dx, y), 3.2, pole);
      canvas.drawLine(Offset(r.center.dx, y), Offset(r.center.dx, r.top), Paint()
        ..color = const Color(0x88263241)
        ..strokeWidth = 1.2);
    }
  }

  /// One section: the same frame and size for every kind; the icon in its
  /// upper part (the name is a widget under it).
  void _section(Canvas canvas, Rect r, M5TripArea a) {
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(5)), Paint()..color = const Color(0xFFE7E0C8));
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(5)),
      Paint()
        ..color = const Color(0xFF9C8B66)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final icon = Rect.fromLTRB(r.left + 6, r.top + 5, r.right - 6, r.bottom - 20);
    switch (a) {
      case M5TripArea.trees:
        for (final (dx, s) in [(0.22, 0.9), (0.52, 1.1), (0.8, 0.85)]) {
          final c = Offset(icon.left + icon.width * dx, icon.top + icon.height * 0.42);
          canvas.drawRect(Rect.fromCenter(center: c + Offset(0, icon.height * 0.32), width: 3, height: icon.height * 0.36), Paint()..color = const Color(0xFF6B4A2B));
          canvas.drawCircle(
            c,
            icon.height * 0.28 * s,
            Paint()..shader = const RadialGradient(colors: [Color(0xFF5FAF4E), Color(0xFF2F6E2C)]).createShader(Rect.fromCircle(center: c, radius: icon.height * 0.3)),
          );
        }
      case M5TripArea.river:
        final p = Path()..moveTo(icon.left, icon.top + icon.height * 0.25);
        for (var k = 0; k <= 4; k++) {
          final x = icon.left + icon.width * k / 4;
          p.quadraticBezierTo(x - icon.width / 8, icon.top + icon.height * (k.isEven ? 0.15 : 0.4), x, icon.top + icon.height * 0.25);
        }
        p
          ..lineTo(icon.right, icon.top + icon.height * 0.75)
          ..lineTo(icon.left, icon.top + icon.height * 0.75)
          ..close();
        canvas.drawPath(
          p,
          Paint()..shader = const LinearGradient(colors: [Color(0xFF5DA9D6), Color(0xFF2F6F9E)], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(icon),
        );
        final wave = Paint()
          ..color = const Color(0xAAFFFFFF)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;
        canvas.drawLine(Offset(icon.left + 8, icon.top + icon.height * 0.5), Offset(icon.left + 22, icon.top + icon.height * 0.5), wave);
        canvas.drawLine(Offset(icon.right - 24, icon.top + icon.height * 0.62), Offset(icon.right - 10, icon.top + icon.height * 0.62), wave);
      case M5TripArea.market:
        for (final (dx, c) in [(0.0, const Color(0xFFD9573B)), (0.36, const Color(0xFFE0A21E)), (0.68, const Color(0xFF3F8FCB))]) {
          final x = icon.left + icon.width * dx;
          final w = icon.width * 0.32;
          final roof = Path()
            ..moveTo(x, icon.top + icon.height * 0.42)
            ..lineTo(x + w / 2, icon.top + icon.height * 0.12)
            ..lineTo(x + w, icon.top + icon.height * 0.42)
            ..close();
          canvas.drawPath(roof, Paint()..color = c);
          canvas.drawRect(Rect.fromLTWH(x + 2, icon.top + icon.height * 0.42, w - 4, icon.height * 0.4), Paint()..color = const Color(0xFFB98B5A));
        }
      case M5TripArea.fields:
        for (var k = 0; k < 4; k++) {
          canvas.drawRect(
            Rect.fromLTWH(icon.left, icon.top + icon.height * (0.12 + k * 0.2), icon.width, icon.height * 0.16),
            Paint()..color = k.isEven ? const Color(0xFF7DBA4A) : const Color(0xFFD7C25A),
          );
        }
    }
  }

  /// A suspect photo card: the same frame for all three; the photo only.
  void _card(Canvas canvas, Rect r, M5TripSuspect s) {
    canvas.drawRRect(RRect.fromRectAndRadius(r.shift(const Offset(0, 3)), const Radius.circular(4)), Paint()..color = const Color(0x55000000));
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)), Paint()..color = const Color(0xFFFBF8EF));
    final photo = Rect.fromLTRB(r.left + 5, r.top + 5, r.right - 5, r.bottom - 22);
    canvas.save();
    canvas.clipRect(photo);
    canvas.drawRect(
      photo,
      Paint()..shader = const LinearGradient(colors: [Color(0xFF9EB8CC), Color(0xFFCBD6DC)], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(photo),
    );
    final wire = Paint()
      ..color = const Color(0xFF2C333B)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final h = photo.height;
    final w = photo.width;
    Offset at(double fx, double fy) => Offset(photo.left + w * fx, photo.top + h * fy);
    switch (s) {
      case M5TripSuspect.branch:
        canvas.drawLine(at(0, 0.3), at(1, 0.34), wire);
        canvas.drawLine(at(0, 0.55), at(1, 0.6), wire);
        final br = Paint()
          ..color = const Color(0xFF6B4A2B)
          ..strokeWidth = 3.2
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(at(0.15, 0.05), at(0.75, 0.85), br);
        canvas.drawLine(at(0.45, 0.42), at(0.82, 0.3), br..strokeWidth = 2);
        for (final p in [at(0.2, 0.15), at(0.82, 0.28), at(0.66, 0.74), at(0.36, 0.38)]) {
          canvas.drawOval(Rect.fromCenter(center: p, width: 12, height: 8), Paint()..color = const Color(0xFF3F8A3A));
        }
      case M5TripSuspect.bird:
        canvas.drawRect(Rect.fromLTWH(photo.left, photo.top + h * 0.58, w, 4), Paint()..color = const Color(0xFF6E5A44));
        for (final fx in [0.25, 0.75]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromCenter(center: at(fx, 0.48), width: 9, height: 16), const Radius.circular(3)),
            Paint()..color = const Color(0xFF8B5E3C),
          );
          canvas.drawLine(at(fx, 0.4), at(fx, 0.0), wire);
        }
        // The bird with wings spread from one insulator top to the other.
        final body = at(0.5, 0.34);
        canvas.drawOval(Rect.fromCenter(center: body, width: 16, height: 9), Paint()..color = const Color(0xFF1F2328));
        final wing = Path()
          ..moveTo(body.dx - 6, body.dy)
          ..quadraticBezierTo(body.dx - 18, body.dy - 12, at(0.25, 0.36).dx, at(0.25, 0.4).dy)
          ..moveTo(body.dx + 6, body.dy)
          ..quadraticBezierTo(body.dx + 18, body.dy - 12, at(0.75, 0.36).dx, at(0.75, 0.4).dy);
        canvas.drawPath(
          wing,
          Paint()
            ..color = const Color(0xFF1F2328)
            ..strokeWidth = 3
            ..style = PaintingStyle.stroke,
        );
        canvas.drawCircle(Offset(body.dx + 9, body.dy - 3), 3, Paint()..color = const Color(0xFF1F2328));
      case M5TripSuspect.clash:
        final a = Path()
          ..moveTo(photo.left, photo.top + h * 0.25)
          ..quadraticBezierTo(photo.left + w * 0.5, photo.top + h * 0.62, photo.right, photo.top + h * 0.25);
        final b = Path()
          ..moveTo(photo.left, photo.top + h * 0.7)
          ..quadraticBezierTo(photo.left + w * 0.5, photo.top + h * 0.3, photo.right, photo.top + h * 0.7);
        canvas.drawPath(a, wire);
        canvas.drawPath(b, wire);
        final c = at(0.5, 0.46);
        final spark = Paint()
          ..color = const Color(0xFFFFC640)
          ..strokeWidth = 1.6;
        for (var k = 0; k < 6; k++) {
          final ang = k * math.pi / 3;
          canvas.drawLine(c, c + Offset(math.cos(ang), math.sin(ang)) * 7, spark);
        }
    }
    canvas.restore();
  }

  void _clockFrame(Canvas canvas) {
    final c = geo.clock;
    canvas.drawRRect(RRect.fromRectAndRadius(c.inflate(3), const Radius.circular(7)), Paint()..color = const Color(0xFF3A3F45));
    canvas.drawRRect(RRect.fromRectAndRadius(c, const Radius.circular(5)), Paint()..color = const Color(0xFF0E1A12));
  }

  void _window(Canvas canvas) {
    final w = geo.window;
    canvas.drawRRect(RRect.fromRectAndRadius(w.inflate(4), const Radius.circular(4)), Paint()..color = const Color(0xFFDCD6C8));
    canvas.save();
    canvas.clipRect(w);
    final List<Color> sky = switch (room.sky) {
      M5TripSky.storm => const [Color(0xFF2B323C), Color(0xFF4B5562)],
      M5TripSky.windy => room.day ? const [Color(0xFF7D93A8), Color(0xFFA9B8C4)] : const [Color(0xFF1C2838), Color(0xFF34465A)],
      M5TripSky.clear => room.day ? const [Color(0xFF4F9BD8), Color(0xFFA8D4F0)] : const [Color(0xFF0B1630), Color(0xFF1D2F57)],
    };
    canvas.drawRect(w, Paint()..shader = LinearGradient(colors: sky, begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(w));
    final rng = math.Random(11);
    switch (room.sky) {
      case M5TripSky.storm:
        for (final (dx, dy, s) in [(0.2, 0.15, 1.0), (0.6, 0.1, 1.3), (0.9, 0.2, 0.9)]) {
          canvas.drawOval(Rect.fromCenter(center: Offset(w.left + w.width * dx, w.top + w.height * dy), width: 60 * s, height: 22 * s), Paint()..color = const Color(0xFF1B2028));
        }
        final rain = Paint()
          ..color = const Color(0x88C8D6E6)
          ..strokeWidth = 1;
        for (var i = 0; i < 26; i++) {
          final x = w.left + rng.nextDouble() * w.width;
          final y = w.top + rng.nextDouble() * w.height;
          canvas.drawLine(Offset(x, y), Offset(x - 4, y + 10), rain);
        }
        final bolt = Path()
          ..moveTo(w.left + w.width * 0.66, w.top + 10)
          ..lineTo(w.left + w.width * 0.6, w.top + 26)
          ..lineTo(w.left + w.width * 0.66, w.top + 26)
          ..lineTo(w.left + w.width * 0.58, w.top + 44);
        canvas.drawPath(
          bolt,
          Paint()
            ..color = const Color(0xFFFFF2A8)
            ..strokeWidth = 1.8
            ..style = PaintingStyle.stroke,
        );
      case M5TripSky.windy:
        final streak = Paint()
          ..color = room.day ? const Color(0xAAE6EDF2) : const Color(0x667A8DA3)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 4; i++) {
          final y = w.top + 8 + i * 9.0;
          final x = w.left + 10 + rng.nextDouble() * 40;
          canvas.drawLine(Offset(x, y), Offset(x + 40 + rng.nextDouble() * 30, y), streak);
        }
        // A tree bending in the wind.
        final base = Offset(w.left + 26, w.bottom);
        canvas.drawLine(base, base + const Offset(10, -26), Paint()
          ..color = const Color(0xFF3E2C1C)
          ..strokeWidth = 3);
        canvas.drawOval(Rect.fromCenter(center: base + const Offset(20, -32), width: 34, height: 18), Paint()..color = const Color(0xFF2F5A2C));
      case M5TripSky.clear:
        if (room.day) {
          canvas.drawCircle(Offset(w.right - 24, w.top + 16), 9, Paint()..color = const Color(0xFFFFE08A));
        } else {
          canvas.drawCircle(Offset(w.right - 24, w.top + 16), 7, Paint()..color = const Color(0xFFF2EBD0));
          final star = Paint()..color = const Color(0xCCFFFFFF);
          for (var i = 0; i < 12; i++) {
            canvas.drawCircle(Offset(w.left + rng.nextDouble() * w.width, w.top + rng.nextDouble() * w.height * 0.6), 0.9, star);
          }
        }
    }
    // The yard and the van outside.
    canvas.drawRect(Rect.fromLTRB(w.left, w.bottom - 10, w.right, w.bottom), Paint()..color = room.day ? const Color(0xFF6E7A5A) : const Color(0xFF1E2620));
    final van = Rect.fromLTWH(w.right - 64, w.bottom - 24, 44, 16);
    canvas.drawRRect(RRect.fromRectAndRadius(van, const Radius.circular(3)), Paint()..color = const Color(0xFFE8ECEF));
    canvas.drawRect(Rect.fromLTWH(van.left, van.top + 9, van.width, 2.5), Paint()..color = const Color(0xFFE07A1E));
    for (final x in [van.left + 9, van.right - 9]) {
      canvas.drawCircle(Offset(x, van.bottom), 3.4, Paint()..color = const Color(0xFF15191E));
    }
    canvas.restore();
    // Window bars.
    final bar = Paint()
      ..color = const Color(0xFFDCD6C8)
      ..strokeWidth = 3;
    canvas.drawLine(Offset(w.center.dx, w.top), Offset(w.center.dx, w.bottom), bar);
    canvas.drawLine(Offset(w.left, w.center.dy), Offset(w.right, w.center.dy), bar);
  }

  void _desk(Canvas canvas, Size size) {
    final top = geo.deskY;
    final desk = Rect.fromLTRB(0, top, 360, math.max(size.height, geo.height));
    canvas.drawRect(
      desk,
      Paint()..shader = const LinearGradient(colors: [Color(0xFF7A4E2D), Color(0xFF4E301B)], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(desk),
    );
    canvas.drawRect(Rect.fromLTWH(0, top, 360, 4), Paint()..color = const Color(0xFF9C6A42));
    // The notepad.
    final n = geo.notepad;
    canvas.drawRect(n.shift(const Offset(3, 4)), Paint()..color = const Color(0x66000000));
    canvas.drawRect(n, Paint()..color = const Color(0xFFFFFBEA));
    canvas.drawRect(Rect.fromLTWH(n.left, n.top, n.width, 12), Paint()..color = const Color(0xFFCF4A3A));
    final rule = Paint()
      ..color = const Color(0x332F6FB5)
      ..strokeWidth = 1;
    for (var y = n.top + 26.0; y < n.bottom - 4; y += 14) {
      canvas.drawLine(Offset(n.left + 4, y), Offset(n.right - 4, y), rule);
    }
    canvas.drawLine(Offset(n.left + 18, n.top + 12), Offset(n.left + 18, n.bottom), Paint()
      ..color = const Color(0x44CF4A3A)
      ..strokeWidth = 1);
    // The phone base.
    final b = geo.phoneBase;
    canvas.drawRRect(RRect.fromRectAndRadius(b.shift(const Offset(0, 4)), const Radius.circular(12)), Paint()..color = const Color(0x66000000));
    canvas.drawRRect(
      RRect.fromRectAndRadius(b, const Radius.circular(12)),
      Paint()..shader = const LinearGradient(colors: [Color(0xFF3A4048), Color(0xFF1A1E23)], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(b),
    );
    final key = Paint()..color = const Color(0xFFB9C2CC);
    for (var r = 0; r < 2; r++) {
      for (var c = 0; c < 4; c++) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(b.left + 14 + c * 18.0, b.top + 18 + r * 13.0, 12, 8), const Radius.circular(2)),
          key,
        );
      }
    }
  }

  @override
  bool shouldRepaint(M5TripPainter old) => old.geo != geo || old.room != room;
}

/// The handset (drawn where it is: at rest, lifted, or under the finger).
class M5TripHandsetPainter extends CustomPainter {
  const M5TripHandsetPainter({required this.lifted});
  final bool lifted;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    canvas.save();
    if (lifted) {
      canvas.translate(r.center.dx, r.center.dy);
      canvas.rotate(-0.12);
      canvas.translate(-r.center.dx, -r.center.dy);
    }
    final p = Path()
      ..moveTo(r.left + 6, r.top + r.height * 0.2)
      ..quadraticBezierTo(r.left, r.bottom, r.left + r.width * 0.22, r.bottom)
      ..lineTo(r.left + r.width * 0.3, r.top + r.height * 0.55)
      ..lineTo(r.right - r.width * 0.3, r.top + r.height * 0.55)
      ..lineTo(r.right - r.width * 0.22, r.bottom)
      ..quadraticBezierTo(r.right, r.bottom, r.right - 6, r.top + r.height * 0.2)
      ..quadraticBezierTo(r.center.dx, r.top - 4, r.left + 6, r.top + r.height * 0.2)
      ..close();
    canvas.drawShadow(p, Colors.black, 3, false);
    canvas.drawPath(
      p,
      Paint()..shader = const LinearGradient(colors: [Color(0xFF4A515A), Color(0xFF1C2127)], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(r),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(M5TripHandsetPainter old) => old.lifted != lifted;
}

/// The red pin (its head at the top of the box, the needle below).
class M5TripPinPainter extends CustomPainter {
  const M5TripPinPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height * 0.34);
    canvas.drawLine(c, Offset(c.dx + 3, size.height * 0.95), Paint()
      ..color = const Color(0xFF9AA3AD)
      ..strokeWidth = 2);
    canvas.drawCircle(
      c,
      size.width * 0.3,
      Paint()..shader = const RadialGradient(center: Alignment(-0.4, -0.4), colors: [Color(0xFFFF7A6B), Color(0xFFB3161B)]).createShader(Rect.fromCircle(center: c, radius: size.width * 0.3)),
    );
  }

  @override
  bool shouldRepaint(M5TripPinPainter old) => false;
}

/// The van magnet.
class M5TripVanPainter extends CustomPainter {
  const M5TripVanPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final body = Rect.fromLTWH(2, size.height * 0.18, size.width - 4, size.height * 0.58);
    canvas.drawRRect(RRect.fromRectAndRadius(body.shift(const Offset(0, 2)), const Radius.circular(4)), Paint()..color = const Color(0x55000000));
    canvas.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(4)), Paint()..color = const Color(0xFFF2F4F6));
    canvas.drawRect(Rect.fromLTWH(body.left, body.top + body.height * 0.55, body.width, 3), Paint()..color = const Color(0xFFE07A1E));
    canvas.drawRect(Rect.fromLTWH(body.right - body.width * 0.3, body.top + 3, body.width * 0.24, body.height * 0.34), Paint()..color = const Color(0xFF8DB7D6));
    for (final x in [body.left + body.width * 0.22, body.right - body.width * 0.22]) {
      canvas.drawCircle(Offset(x, body.bottom), size.height * 0.13, Paint()..color = const Color(0xFF15191E));
    }
  }

  @override
  bool shouldRepaint(M5TripVanPainter old) => false;
}

/// The deadly consequence: the feeder is charged onto a permanent fault — a
/// flash and fire at the fault's section on the map ([v] 0 → 1).
class M5TripFirePainter extends CustomPainter {
  const M5TripFirePainter({required this.at, required this.v});
  final Rect at;
  final double v;

  @override
  void paint(Canvas canvas, Size size) {
    final c = at.center;
    final glow = (1 - (v - 0.2).abs() * 1.4).clamp(0.0, 1.0);
    canvas.drawCircle(
      c,
      30 + 50 * v,
      Paint()
        ..shader = RadialGradient(colors: [Color.fromRGBO(255, 244, 190, glow), Color.fromRGBO(255, 150, 40, glow * 0.6), const Color(0x00FF7A00)])
            .createShader(Rect.fromCircle(center: c, radius: 30 + 50 * v)),
    );
    final f = v.clamp(0.0, 1.0);
    for (final (dx, s) in [(-16.0, 0.8), (0.0, 1.2), (16.0, 0.9)]) {
      final base = Offset(c.dx + dx, at.bottom - 6);
      final h = 34 * s * f;
      final flame = Path()
        ..moveTo(base.dx - 8 * s, base.dy)
        ..quadraticBezierTo(base.dx - 10 * s, base.dy - h * 0.6, base.dx, base.dy - h)
        ..quadraticBezierTo(base.dx + 10 * s, base.dy - h * 0.6, base.dx + 8 * s, base.dy)
        ..close();
      canvas.drawPath(
        flame,
        Paint()
          ..shader = const LinearGradient(colors: [Color(0xFFFFE27A), Color(0xFFFF7A1E), Color(0xFFD62A12)], begin: Alignment.bottomCenter, end: Alignment.topCenter)
              .createShader(Rect.fromLTRB(base.dx - 10, base.dy - h, base.dx + 10, base.dy)),
      );
    }
    // The spark along the feeder line.
    final s = Paint()
      ..color = Color.fromRGBO(255, 230, 120, glow)
      ..strokeWidth = 2.4;
    for (var k = 0; k < 8; k++) {
      final ang = k * math.pi / 4;
      canvas.drawLine(c, c + Offset(math.cos(ang), math.sin(ang)) * (18 + 26 * v), s);
    }
  }

  @override
  bool shouldRepaint(M5TripFirePainter old) => old.v != v || old.at != at;
}
