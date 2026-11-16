import 'dart:math' as math;

import 'package:flutter/material.dart';

// The drawn world of lesson 8.1 কাজ "তর্ক নয়, তথ্য দিন" (m8_bill_listen.dart):
// an evening in a West Bengal town, full screen in layers (low sun, rooftops
// and a far pole line → the place → the figures). Three places are dealt (at
// least one with a bill in the hand and one at the counter, a play):
//  door — a house doorway with a tin awning, the consumer holds a paper bill;
//  roadside — the parked van and a pole, the consumer holds a paper bill;
//  office — the section-office counter; the notice board hangs on the side
//    wall, out of the frame until the camera pans to it.
// The consumer is a silent drawn figure (ruling M8-10) with a dealt look.
// The tariff table (a bill's back, or the notice board's paper) is drawn in
// the page; its three zones are equal and alike.
//
// Design: 360 wide × the scene's height. The listen pad stands bottom centre,
// the guide in the bottom-right corner, the bubble under the header.

/// Where the complaint happens.
enum M8BillPlace { door, roadside, office }

/// The four complaint classes (a play deals 3 of them, no repeat).
enum M8BillComplaint { company, lineman, unit, fixed }

/// The three equal zones of the tariff table.
enum M8BillZone { header, unit, fixed }

/// The zone that answers a complaint.
M8BillZone m8BillZoneOf(M8BillComplaint c) => switch (c) {
      M8BillComplaint.company || M8BillComplaint.lineman => M8BillZone.header,
      M8BillComplaint.unit => M8BillZone.unit,
      M8BillComplaint.fixed => M8BillZone.fixed,
    };

/// How he is standing (and what his hands do).
enum M8BillMood {
  /// Ranting: one arm up, moving.
  rant,

  /// A false pause: both hands still moving (the bubble stays open).
  pause,

  /// The real end: the bill held out (door, roadside).
  holdOut,

  /// The real end: pointing at the wall (office).
  point,

  /// After the right reply: shoulders dropped.
  calm,

  /// After a listened-to push: turned away, fists.
  storm,
}

/// A consumer's look: shirt, trousers, hair, glasses, build.
@immutable
class M8BillLook {
  const M8BillLook({required this.shirt, required this.trousers, required this.hair, required this.glasses, required this.skin, this.bald = false});
  final Color shirt;
  final Color trousers;
  final Color hair;
  final bool glasses;
  final Color skin;
  final bool bald;
}

const List<M8BillLook> kM8BillLooks = [
  M8BillLook(shirt: Color(0xFFB5543A), trousers: Color(0xFF3B3F4A), hair: Color(0xFF1E1A16), glasses: false, skin: Color(0xFFA8714B)),
  M8BillLook(shirt: Color(0xFF4F7FA8), trousers: Color(0xFF2E3A4E), hair: Color(0xFFB9B9B9), glasses: true, skin: Color(0xFF9B6642)),
  M8BillLook(shirt: Color(0xFFE6DFC8), trousers: Color(0xFF8A7B63), hair: Color(0xFF1E1A16), glasses: true, skin: Color(0xFFB57A52), bald: true),
  M8BillLook(shirt: Color(0xFF5B8A5E), trousers: Color(0xFF4A3F36), hair: Color(0xFF3A2A1E), glasses: false, skin: Color(0xFFC08A62)),
];

/// The evening light (dealt a play): sky top, middle, horizon.
const List<List<Color>> kM8BillSkies = [
  [Color(0xFF6C7FB8), Color(0xFFE8A27A), Color(0xFFFFD79A)],
  [Color(0xFF5D6FA3), Color(0xFFD98E7E), Color(0xFFF7C98F)],
  [Color(0xFF7A86B5), Color(0xFFEBB08A), Color(0xFFFFE0A6)],
];

/// Where things are (design px, 360 wide).
@immutable
class M8BillGeo {
  const M8BillGeo._(this.height, this.bottomY);

  factory M8BillGeo.forScene(double height, double inset) => M8BillGeo._(height, height - inset * 0.6);

  final double height;
  final double bottomY;

  /// The figures stand on this line.
  double get groundY => bottomY - 124;

  /// The round listen pad (the only control while he talks).
  Offset get padCentre => Offset(180, bottomY - 50);
  static const double padR = 36;
  Rect get pad => Rect.fromCircle(center: padCentre, radius: padR);

  /// The trainee faces right, the consumer left.
  Rect get trainee => Rect.fromLTWH(64, groundY - 106, 46, 106);

  /// Where the consumer stands (and where he walks in from).
  static const double consumerX = 232;
  static const double consumerW = 64;
  Rect get consumer => Rect.fromLTWH(consumerX, groundY - 112, consumerW, 112);

  /// His bubble (a burst of words, or the reply) under the header.
  Rect get bubble => const Rect.fromLTWH(14, 148, 332, 76);

  /// The bill in his raised hand (door, roadside), and where a swipe on it starts.
  Rect get billHand => Rect.fromCenter(center: Offset(consumerX - 5, groundY - 98), width: 30, height: 40);
  Rect get billTouch => billHand.inflate(30);

  /// The tariff table's paper (a bill's back, or the notice board's chart).
  Rect get panel => const Rect.fromLTWH(30, 238, 300, 190);

  /// The table inside the paper: three equal zones, header on top.
  Rect get table => const Rect.fromLTWH(44, 252, 272, 162);

  /// The zone's touch box: the header is always on top, the two rows are in
  /// [unitFirst] order.
  Rect zone(M8BillZone z, {required bool unitFirst}) {
    final i = switch (z) {
      M8BillZone.header => 0,
      M8BillZone.unit => unitFirst ? 1 : 2,
      M8BillZone.fixed => unitFirst ? 2 : 1,
    };
    final h = table.height / 3;
    return Rect.fromLTWH(table.left, table.top + h * i, table.width, h);
  }

  /// The centre of the scene (a sideways drag hint starts here).
  Offset get sceneCentre => Offset(180, groundY - 150);

  @override
  bool operator ==(Object other) => other is M8BillGeo && other.height == height && other.bottomY == bottomY;

  @override
  int get hashCode => Object.hash(height, bottomY);
}

Paint _fill(Color c) => Paint()..color = c;
Paint _stroke(Color c, double w) => Paint()
  ..color = c
  ..strokeWidth = w
  ..style = PaintingStyle.stroke
  ..strokeCap = StrokeCap.round;

/// The sky, the low sun, the rooftops and a far pole line (same for every
/// place).
class M8BillBackPainter extends CustomPainter {
  const M8BillBackPainter({required this.geo, required this.light});
  final M8BillGeo geo;
  final int light;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    final sky = kM8BillSkies[light % kM8BillSkies.length];
    final skyR = Rect.fromLTWH(0, 0, w, g.groundY);
    c.drawRect(skyR, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: sky).createShader(skyR));
    c.drawCircle(Offset(w * 0.2, g.groundY - 120), 34, _fill(const Color(0x44FFE9B0)));
    c.drawCircle(Offset(w * 0.2, g.groundY - 120), 20, _fill(const Color(0xFFFFE9A8)));
    // Rooftops.
    final roofs = _fill(const Color(0xFF7C6A78));
    for (var i = 0; i < 9; i++) {
      final x = i * 44.0 - 14;
      final hgt = 36.0 + (i * 37 % 5) * 10;
      c.drawRect(Rect.fromLTWH(x, g.groundY - hgt - 24, 40, hgt + 24), roofs);
      c.drawRect(Rect.fromLTWH(x + 6, g.groundY - hgt - 30, 14, 8), roofs);
    }
    // A far pole line with its sagging wires.
    final pole = _stroke(const Color(0xFF4A4350), 2);
    final wire = _stroke(const Color(0xAA3A3340), 0.9);
    final xs = [-10.0, 100.0, 210.0, 320.0, 430.0];
    for (final x in xs) {
      c.drawLine(Offset(x, g.groundY - 100), Offset(x, g.groundY - 20), pole);
      c.drawLine(Offset(x - 8, g.groundY - 96), Offset(x + 8, g.groundY - 96), pole);
    }
    for (var i = 0; i < xs.length - 1; i++) {
      for (final dy in [-96.0, -92.0]) {
        final p = Path()
          ..moveTo(xs[i] + (dy == -96 ? 8 : -8), g.groundY + dy)
          ..quadraticBezierTo((xs[i] + xs[i + 1]) / 2, g.groundY + dy + 12, xs[i + 1] + (dy == -96 ? -8 : 8), g.groundY + dy);
        c.drawPath(p, wire);
      }
    }
    // The ground.
    final ground = Rect.fromLTRB(0, g.groundY - 6, w, size.height);
    c.drawRect(ground, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFB59E86), Color(0xFF8E8479), Color(0xFF5E5A58)]).createShader(ground));
  }

  @override
  bool shouldRepaint(M8BillBackPainter old) => old.geo != geo || old.light != light;
}

/// One place, drawn over the back. The office draws two screens side by side
/// (the counter, then the side wall with the notice board) and slides by [pan]
/// (0 = the counter, 1 = the board).
class M8BillPlacePainter extends CustomPainter {
  const M8BillPlacePainter({required this.geo, required this.place, this.pan = 0});
  final M8BillGeo geo;
  final M8BillPlace place;
  final double pan;

  @override
  void paint(Canvas c, Size size) {
    switch (place) {
      case M8BillPlace.door:
        _door(c, size);
      case M8BillPlace.roadside:
        _roadside(c, size);
      case M8BillPlace.office:
        c.save();
        c.translate(-360 * pan, 0);
        _office(c, size);
        c.restore();
    }
  }

  void _door(Canvas c, Size size) {
    final g = geo.groundY;
    // The house wall.
    final wall = Rect.fromLTRB(0, g - 196, 360, g);
    c.drawRect(wall, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE9D9B8), Color(0xFFD3C09A)]).createShader(wall));
    c.drawRect(Rect.fromLTRB(0, g - 12, 360, g), _fill(const Color(0xFF9B8A70)));
    // The door.
    final door = Rect.fromLTRB(116, g - 150, 190, g);
    c.drawRRect(RRect.fromRectAndCorners(door, topLeft: const Radius.circular(4), topRight: const Radius.circular(4)), _fill(const Color(0xFF5E4630)));
    c.drawRect(door.deflate(8), _fill(const Color(0xFF6D5339)));
    c.drawCircle(Offset(door.right - 12, door.center.dy + 6), 2.6, _fill(const Color(0xFFD9B35A)));
    // A barred window.
    final win = Rect.fromLTWH(238, g - 150, 70, 62);
    c.drawRect(win, _fill(const Color(0xFF7C8C99)));
    for (var i = 1; i < 4; i++) {
      c.drawLine(Offset(win.left + i * 17.5, win.top), Offset(win.left + i * 17.5, win.bottom), _stroke(const Color(0xFF3A3F45), 1.6));
    }
    c.drawRect(win.inflate(2), _stroke(const Color(0xFF3A3F45), 2));
    // The tin awning over the door.
    final tin = Path()
      ..moveTo(98, g - 158)
      ..lineTo(208, g - 158)
      ..lineTo(222, g - 128)
      ..lineTo(84, g - 128)
      ..close();
    c.drawPath(tin, _fill(const Color(0xFF8F9BA6)));
    for (var i = 0; i < 8; i++) {
      c.drawLine(Offset(104 + i * 13.0, g - 157), Offset(92 + i * 16.0, g - 129), _stroke(const Color(0x66FFFFFF), 1));
    }
    c.drawLine(Offset(98, g - 128), Offset(98, g - 112), _stroke(const Color(0xFF5B5F63), 2));
    c.drawLine(Offset(208, g - 128), Offset(208, g - 112), _stroke(const Color(0xFF5B5F63), 2));
    // The step.
    c.drawRect(Rect.fromLTRB(104, g - 8, 202, g + 4), _fill(const Color(0xFFB9AE9A)));
  }

  void _roadside(Canvas c, Size size) {
    final g = geo.groundY;
    // The road and the kerb.
    c.drawRect(Rect.fromLTRB(0, g - 6, 360, g + 14), _fill(const Color(0xFFC9C2B2)));
    c.drawRect(Rect.fromLTRB(0, g + 14, 360, size.height), _fill(const Color(0xFF69655F)));
    for (var x = 6.0; x < 360; x += 48) {
      c.drawRect(Rect.fromLTWH(x, g + 52, 26, 3), _fill(const Color(0xFFE8E2CF)));
    }
    // The parked van.
    final body = RRect.fromRectAndRadius(Rect.fromLTRB(-4, g - 86, 134, g - 6), const Radius.circular(8));
    c.drawRRect(body, _fill(const Color(0xFFF1EFE8)));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(96, g - 80, 130, g - 44), const Radius.circular(4)), _fill(const Color(0xFF8DA5B5)));
    c.drawRect(Rect.fromLTRB(-4, g - 54, 134, g - 46), _fill(const Color(0xFF1F5F8F)));
    c.drawCircle(Offset(26, g - 6), 11, _fill(const Color(0xFF2A2A2E)));
    c.drawCircle(Offset(26, g - 6), 5, _fill(const Color(0xFFB0B4B8)));
    c.drawCircle(Offset(104, g - 6), 11, _fill(const Color(0xFF2A2A2E)));
    c.drawCircle(Offset(104, g - 6), 5, _fill(const Color(0xFFB0B4B8)));
    // The pole at the right.
    final pole = Rect.fromLTRB(320, g - 190, 331, g + 2);
    c.drawRect(pole, Paint()..shader = const LinearGradient(colors: [Color(0xFF8E9399), Color(0xFFC9CDD1), Color(0xFF7C8187)]).createShader(pole));
    c.drawLine(const Offset(296, 0) + Offset(0, g - 176), Offset(356, g - 176), _stroke(const Color(0xFF5B5F63), 3));
    for (final x in [300.0, 325.0, 352.0]) {
      c.drawCircle(Offset(x, g - 180), 3, _fill(const Color(0xFFE8E2CF)));
    }
  }

  void _office(Canvas c, Size size) {
    final g = geo.groundY;
    // The office wall and floor (two screens wide).
    final wall = Rect.fromLTRB(0, g - 230, 720, g);
    c.drawRect(wall, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFD6D2C2), Color(0xFFBDB8A6)]).createShader(wall));
    c.drawRect(Rect.fromLTRB(0, g - 14, 720, g + 6), _fill(const Color(0xFF8E8676)));
    c.drawRect(Rect.fromLTRB(0, g + 6, 720, size.height), _fill(const Color(0xFF6B6558)));
    // A window with the evening in it, and a wall clock.
    final win = Rect.fromLTWH(34, g - 190, 96, 80);
    c.drawRect(win, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF9DA9D2), Color(0xFFF2C98F)]).createShader(win));
    c.drawLine(Offset(win.center.dx, win.top), Offset(win.center.dx, win.bottom), _stroke(const Color(0xFF5B5448), 2));
    c.drawRect(win.inflate(2), _stroke(const Color(0xFF5B5448), 3));
    c.drawCircle(const Offset(180, 0) + Offset(0, g - 168), 14, _fill(const Color(0xFFF4F1E6)));
    c.drawCircle(const Offset(180, 0) + Offset(0, g - 168), 14, _stroke(const Color(0xFF5B5448), 1.6));
    c.drawLine(Offset(180, g - 168), Offset(180, g - 177), _stroke(const Color(0xFF3A3F45), 1.4));
    c.drawLine(Offset(180, g - 168), Offset(187, g - 165), _stroke(const Color(0xFF3A3F45), 1.4));
    // The counter, with a ledger and a rubber stamp on it.
    final top = Rect.fromLTRB(0, g - 62, 360, g - 50);
    final front = Rect.fromLTRB(0, g - 50, 360, g + 4);
    c.drawRect(front, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8A6A3C), Color(0xFF6B4F2B)]).createShader(front));
    c.drawRect(top, _fill(const Color(0xFFB08A52)));
    c.drawRect(Rect.fromLTWH(18, g - 70, 44, 8), _fill(const Color(0xFF3F5F8F)));
    c.drawRect(Rect.fromLTWH(24, g - 76, 14, 6), _fill(const Color(0xFFB5543A)));
    // The side wall's corner and the notice board (in the second screen).
    c.drawRect(Rect.fromLTRB(358, g - 230, 362, g), _fill(const Color(0xFF9E9886)));
    final board = Rect.fromLTWH(380, 226, 320, 214);
    c.drawRRect(RRect.fromRectAndRadius(board, const Radius.circular(6)), _fill(const Color(0xFF7A5A34)));
    c.drawRRect(RRect.fromRectAndRadius(board.deflate(7), const Radius.circular(3)), _fill(const Color(0xFF3F7A5B)));
    // Small pinned papers around the chart's place (not the chart).
    for (final r in [
      const Rect.fromLTWH(392, 236, 22, 28),
      const Rect.fromLTWH(668, 238, 22, 26),
      const Rect.fromLTWH(394, 396, 20, 30),
      const Rect.fromLTWH(666, 398, 24, 28),
    ]) {
      c.drawRect(r, _fill(const Color(0xFFF1ECD9)));
      c.drawCircle(r.topCenter + const Offset(0, 3), 1.8, _fill(const Color(0xFFC62828)));
    }
  }

  @override
  bool shouldRepaint(M8BillPlacePainter old) => old.geo != geo || old.place != place || old.pan != pan;
}

/// The consumer: a silent figure facing left, in his mood. [beat] repaints it
/// (the hands move) only while he is talking.
class M8ConsumerPainter extends CustomPainter {
  M8ConsumerPainter({required this.look, required this.mood, required this.bill, required this.louder, this.beat}) : super(repaint: beat);
  final M8BillLook look;
  final M8BillMood mood;

  /// A paper bill in his hand (door, roadside) at the real end.
  final bool bill;
  final bool louder;
  final ValueNotifier<int>? beat;

  @override
  void paint(Canvas c, Size size) {
    final t = (beat?.value ?? 0).toDouble();
    final foot = Offset(size.width / 2, size.height - 2);
    final skin = _fill(look.skin);
    final sw = math.sin(t * 1.3);
    final lean = switch (mood) {
      M8BillMood.storm => 7.0,
      M8BillMood.calm => -2.0,
      _ => louder ? -3.0 : 0.0,
    };
    // Legs.
    c.drawLine(foot + const Offset(-6, -42), foot + const Offset(-7, -2), _stroke(look.trousers, 7));
    c.drawLine(foot + const Offset(6, -42), foot + const Offset(7, -2), _stroke(look.trousers, 7));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: foot + const Offset(-8, -1), width: 12, height: 5), const Radius.circular(2)), _fill(const Color(0xFF2A2018)));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: foot + const Offset(6, -1), width: 12, height: 5), const Radius.circular(2)), _fill(const Color(0xFF2A2018)));
    // Body.
    final shoulderDrop = mood == M8BillMood.calm ? 4.0 : 0.0;
    final body = Rect.fromLTRB(foot.dx - 13 + lean, foot.dy - 82 + shoulderDrop, foot.dx + 13 + lean, foot.dy - 40);
    c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(6)), _fill(look.shirt));
    c.drawLine(Offset(body.center.dx, body.top + 4), Offset(body.center.dx, body.bottom - 2), _stroke(const Color(0x33000000), 1));
    final shoulderL = Offset(body.left + 3, body.top + 8);
    final shoulderR = Offset(body.right - 3, body.top + 8);
    final shirt = _stroke(look.shirt, 6);
    switch (mood) {
      case M8BillMood.rant:
        // The left arm (towards the trainee) up and shaking; the other down.
        c.drawLine(shoulderL, shoulderL + Offset(-14 + sw * 4, -16 - sw * 3), shirt);
        c.drawCircle(shoulderL + Offset(-14 + sw * 4, -18 - sw * 3), 3.4, skin);
        c.drawLine(shoulderR, shoulderR + const Offset(3, 28), shirt);
        c.drawCircle(shoulderR + const Offset(3, 30), 3.2, skin);
      case M8BillMood.pause:
        // Both hands still moving, out in front.
        c.drawLine(shoulderL, shoulderL + Offset(-15, 6 + sw * 8), shirt);
        c.drawCircle(shoulderL + Offset(-15, 8 + sw * 8), 3.4, skin);
        c.drawLine(shoulderR, shoulderR + Offset(-6, 12 - sw * 8), shirt);
        c.drawCircle(shoulderR + Offset(-6, 14 - sw * 8), 3.4, skin);
      case M8BillMood.holdOut:
        // One arm held out with the bill (or empty-handed in the office).
        c.drawLine(shoulderL, shoulderL + const Offset(-18, -4), shirt);
        c.drawCircle(shoulderL + const Offset(-19, -5), 3.4, skin);
        c.drawLine(shoulderR, shoulderR + const Offset(3, 28), shirt);
        c.drawCircle(shoulderR + const Offset(3, 30), 3.2, skin);
        if (bill) _bill(c, shoulderL + const Offset(-27, -22));
      case M8BillMood.point:
        // Pointing back at the wall behind him.
        c.drawLine(shoulderR, shoulderR + const Offset(20, -8), shirt);
        c.drawCircle(shoulderR + const Offset(21, -9), 3.4, skin);
        c.drawLine(shoulderR + const Offset(21, -9), shoulderR + const Offset(30, -12), _stroke(look.skin, 2.4));
        c.drawLine(shoulderL, shoulderL + const Offset(-4, 28), shirt);
        c.drawCircle(shoulderL + const Offset(-4, 30), 3.2, skin);
      case M8BillMood.calm:
        c.drawLine(shoulderL, shoulderL + const Offset(-3, 28), shirt);
        c.drawCircle(shoulderL + const Offset(-3, 30), 3.2, skin);
        c.drawLine(shoulderR, shoulderR + const Offset(3, 28), shirt);
        c.drawCircle(shoulderR + const Offset(3, 30), 3.2, skin);
      case M8BillMood.storm:
        c.drawLine(shoulderL, shoulderL + const Offset(-6, 16), shirt);
        c.drawCircle(shoulderL + const Offset(-6, 18), 4, skin);
        c.drawLine(shoulderR, shoulderR + const Offset(4, 16), shirt);
        c.drawCircle(shoulderR + const Offset(4, 18), 4, skin);
    }
    // Head.
    final head = Offset(body.center.dx - 1 + (mood == M8BillMood.storm ? 3 : 0), body.top - 10);
    c.drawCircle(head, 9.5, skin);
    if (!look.bald) {
      c.drawArc(Rect.fromCircle(center: head + const Offset(0, -1), radius: 10), math.pi, math.pi, true, _fill(look.hair));
    } else {
      c.drawArc(Rect.fromCircle(center: head + const Offset(5, -1), radius: 9), math.pi * 1.1, math.pi * 0.8, false, _stroke(const Color(0xFFB9B9B9), 2));
    }
    // Face (towards the trainee, left): brows, eye, mouth.
    final angry = mood == M8BillMood.rant || mood == M8BillMood.pause || mood == M8BillMood.storm;
    final eye = head + const Offset(-4, 0);
    c.drawCircle(eye, 1.3, _fill(const Color(0xFF1E1A16)));
    c.drawLine(eye + Offset(-3, angry ? -4 : -3.5), eye + Offset(3, angry ? -2 : -3.5), _stroke(const Color(0xFF1E1A16), 1.3));
    if (look.glasses) c.drawCircle(eye, 3.4, _stroke(const Color(0xFF3A3F45), 1));
    final mouthOpen = mood == M8BillMood.rant ? 3.0 + (sw.abs() * 2) : (mood == M8BillMood.storm ? 4.0 : 0.0);
    final mouth = head + const Offset(-5, 5);
    if (mouthOpen > 0) {
      c.drawOval(Rect.fromCenter(center: mouth, width: 5, height: mouthOpen), _fill(const Color(0xFF5B1A12)));
    } else {
      c.drawLine(mouth + const Offset(-2, 0), mouth + Offset(2, mood == M8BillMood.calm ? -0.6 : 0.6), _stroke(const Color(0xFF5B1A12), 1.2));
    }
    if (louder && angry) {
      // A few sweat/anger ticks by the head.
      for (final dx in [-4.0, 0.0, 4.0]) {
        c.drawLine(head + Offset(8 + dx, -14), head + Offset(11 + dx, -19), _stroke(const Color(0xFFC62828), 1.6));
      }
    }
  }

  void _bill(Canvas c, Offset at) {
    final r = Rect.fromCenter(center: at, width: 30, height: 40);
    c.drawRect(r.shift(const Offset(2, 2)), _fill(const Color(0x33000000)));
    c.drawRect(r, _fill(const Color(0xFFF4EEDA)));
    c.drawRect(r, _stroke(const Color(0xFF8A7A5A), 1));
    for (var i = 0; i < 5; i++) {
      c.drawLine(Offset(r.left + 4, r.top + 6 + i * 7), Offset(r.right - 4 - (i.isOdd ? 6 : 0), r.top + 6 + i * 7), _stroke(const Color(0x66333333), 1.2));
    }
    c.drawRect(Rect.fromLTWH(r.left + 4, r.top + 3, 12, 3), _fill(const Color(0xFF3F5F8F)));
  }

  @override
  bool shouldRepaint(M8ConsumerPainter old) => old.look != look || old.mood != mood || old.bill != bill || old.louder != louder;
}
