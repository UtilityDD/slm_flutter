import 'dart:math' as math;

import 'package:flutter/material.dart';

// The drawn world of lesson 8.6 কাজ "ডকেট নম্বরটা দিন" (m8_docket_lookup.dart):
// the van cab at dusk in a para. Through the windscreen the lane: a house
// (lit or dark, a ceiling fan seen through its window, a service line from the
// pole), and the consumer who walked up, holding a phone with his SMS or a
// customer-care slip. Below the windscreen the dashboard carries the tablet
// (a widget on the page), four fixed action chips and the 'বাড়ি চলুন' key.
//
// The house tells the truth only in the drawn world (the lesson gives no way
// to judge a meter, so a fault is shown by what a worker would see):
//  dark   — windows black, the fan hangs still, the service line is down
//           (cut, two loose ends) → a real fault;
//  lit    — windows warm, the fan turning (a soft blur disc), the service line
//           intact → nothing wrong, a false complaint.
// After the crew's work the dark house lights up (litT 0 → 1).
//
// No logo, no real form, no Bangla in the painters (labels are widgets).
//
// Design: 360 wide × the scene's height. The tablet (rows) is a widget; the
// guide stands bottom-right of the windscreen with his bubble above, so the
// house, the consumer and the slip card stay clear of both.

/// The four fixed action chips, in the order they sit (2 × 2).
enum M8Chip { start, photo, report, call }

/// What a consumer is (dealt).
enum M8DocKind { noNumber, real, falseHouse, misread }

/// Where things are (design px, 360 wide).
@immutable
class M8DocGeo {
  const M8DocGeo._(this.height, this.inset);

  factory M8DocGeo.forScene(double height, double inset) => M8DocGeo._(height, inset);

  final double height;
  final double inset;

  static const double rowH = 40;
  static const double chipH = 44;
  static const double homeH = 36;

  /// The bottom of the dash controls (above the system inset).
  double get bottomY => height - 8 - inset * 0.6;

  /// 'বাড়ি চলুন'.
  Rect get home => Rect.fromLTWH(14, bottomY - homeH, 162, homeH);

  /// An action chip (2 × 2 above the home key).
  Rect chip(M8Chip c) {
    final chip2 = home.top - 8 - chipH;
    final chip1 = chip2 - 6 - chipH;
    final top = c.index < 2 ? chip1 : chip2;
    return Rect.fromLTWH(c.index.isEven ? 14 : 184, top, 162, chipH);
  }

  /// The top of the tablet = the bottom edge of the windscreen.
  double get tabTop => height >= 740 ? 330 : (height >= 700 ? 300 : 262);
  double get groundY => tabTop - 12;

  Rect get tablet => Rect.fromLTRB(10, tabTop, 350, chip(M8Chip.start).top - 8);
  Rect get colHead => Rect.fromLTWH(18, tabTop + 4, 324, 14);
  Rect get pinSlot => Rect.fromLTWH(18, tabTop + 20, 324, 28);
  Rect get list => Rect.fromLTRB(18, tabTop + 52, 342, tablet.bottom - 8);

  /// The consumer's silent words (a caption bubble under the header).
  Rect get caption => const Rect.fromLTWH(8, 122, 236, 32);

  double get _houseH => math.min(152, groundY - 168);
  Rect get house => Rect.fromLTWH(6, groundY - _houseH, 118, _houseH);
  Rect get consumer {
    // Up to the guide's sprite top (his bubble never covers the head).
    final h = math.min(104.0, groundY - 196);
    return Rect.fromLTWH(140, groundY - h, 64, h);
  }

  /// The phone slip in his hand, in front of him.
  Rect get slip => Rect.fromLTWH(120, groundY - 62, 120, 46);

  /// Where the guide's bubble sits (nothing of the scene may be under it).
  Rect get bubble => Rect.fromLTRB(128, tabTop - 170, 360, tabTop - 116);

  /// The guide's sprite.
  Rect get guide => Rect.fromLTRB(244, tabTop - 116, 360, tabTop);

  /// The pole carrying the service line, right of the house.
  Offset get poleBase => Offset(house.right + 8, groundY);

  /// The list's centre (the swipe hint starts here, never on one row).
  Offset get listCentre => list.center;

  @override
  bool operator ==(Object other) => other is M8DocGeo && other.height == height && other.inset == inset;

  @override
  int get hashCode => Object.hash(height, inset);
}

/// The dusk light (dealt a play): top, middle, horizon.
const List<List<Color>> kM8DocSkies = [
  [Color(0xFF26335E), Color(0xFF7C5479), Color(0xFFE9A06A)],
  [Color(0xFF2D3B66), Color(0xFF6E5A86), Color(0xFFF0B27A)],
  [Color(0xFF1F2C55), Color(0xFF8B4F6E), Color(0xFFE08A5C)],
];

/// The consumers' looks (a shirt, a skin tone, a hair or cap, an extra).
@immutable
class M8DocLook {
  const M8DocLook(this.shirt, this.skin, this.hair, {this.cap = false, this.glasses = false, this.umbrella = false});
  final Color shirt;
  final Color skin;
  final Color hair;
  final bool cap;
  final bool glasses;
  final bool umbrella;
}

const List<M8DocLook> kM8DocLooks = [
  M8DocLook(Color(0xFF3F7CAC), Color(0xFFC68E5E), Color(0xFF1E1A18)),
  M8DocLook(Color(0xFFB5523B), Color(0xFF9C6B45), Color(0xFF3A2A20), glasses: true),
  M8DocLook(Color(0xFF5E8C4A), Color(0xFFD0A074), Color(0xFF6B5A4E), cap: true),
  M8DocLook(Color(0xFF8B6BB5), Color(0xFFB27C52), Color(0xFF14110F), umbrella: true),
  M8DocLook(Color(0xFFD6A73F), Color(0xFFC08A5A), Color(0xFF2A211B), glasses: true),
  M8DocLook(Color(0xFF2F7E78), Color(0xFFA9724A), Color(0xFF8C8C8C), cap: true),
];

Paint _fill(Color c) => Paint()..color = c;
Paint _stroke(Color c, double w) => Paint()
  ..color = c
  ..strokeWidth = w
  ..style = PaintingStyle.stroke
  ..strokeCap = StrokeCap.round;

/// The dusk sky, the far roofs, the lane, the windscreen's pillars and the
/// dashboard under it (the same for every consumer).
class M8DocBackPainter extends CustomPainter {
  const M8DocBackPainter({required this.geo, required this.light});
  final M8DocGeo geo;
  final int light;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    final sky = kM8DocSkies[light % kM8DocSkies.length];
    final skyR = Rect.fromLTWH(0, 0, w, g.groundY);
    c.drawRect(skyR, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: sky).createShader(skyR));
    // The sun going down behind the roofs.
    c.drawCircle(Offset(w * 0.78, g.groundY - 40), 34, _fill(const Color(0x33FFD58A)));
    c.drawCircle(Offset(w * 0.78, g.groundY - 40), 18, _fill(const Color(0xFFFFD08A)));
    // Far roofs with a few lit windows.
    final far = _fill(const Color(0xFF2A2A45));
    final lamp = _fill(const Color(0xFFFFD98A));
    for (var i = 0; i < 9; i++) {
      final x = i * 44.0 - 8;
      final hgt = 34.0 + (i * 37 % 5) * 9;
      c.drawRect(Rect.fromLTWH(x, g.groundY - hgt - 22, 40, hgt + 22), far);
      if (i.isOdd) c.drawRect(Rect.fromLTWH(x + 10, g.groundY - hgt - 8, 6, 7), lamp);
      if (i % 3 == 0) c.drawRect(Rect.fromLTWH(x + 24, g.groundY - hgt - 8 + 12, 6, 7), lamp);
    }
    final tree = _fill(const Color(0xFF223344));
    for (final x in [188.0, 262.0, 340.0]) {
      c.drawCircle(Offset(x, g.groundY - 54), 20, tree);
    }
    // The lane.
    final lane = Rect.fromLTRB(0, g.groundY, w, g.tabTop);
    c.drawRect(lane, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF6C5E5A), Color(0xFF47403F)]).createShader(lane));
    c.drawRect(Rect.fromLTWH(0, g.groundY, w, 2), _fill(const Color(0x55FFFFFF)));
    // The windscreen's pillars and the dashboard.
    final pillar = _fill(const Color(0xFF0B1324));
    c.drawPath(Path()..moveTo(0, 96)..lineTo(10, 96)..lineTo(0, g.tabTop)..close(), pillar);
    c.drawPath(Path()..moveTo(w, 96)..lineTo(w - 10, 96)..lineTo(w, g.tabTop)..close(), pillar);
    final dash = Rect.fromLTRB(0, g.tabTop - 8, w, size.height);
    c.drawRect(dash, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1B2B4A), Color(0xFF0B1324)]).createShader(dash));
    c.drawRect(Rect.fromLTWH(0, g.tabTop - 8, w, 2), _fill(const Color(0xFF3A4E78)));
  }

  @override
  bool shouldRepaint(M8DocBackPainter old) => old.geo != geo || old.light != light;
}

/// The consumer's house: wall, roof, door, two windows with the ceiling fan
/// seen through the left one, the pole and the service line. [litT] 0 = dark
/// and the service line down, 1 = lit, fan turning, line intact.
class M8DocHousePainter extends CustomPainter {
  const M8DocHousePainter({required this.geo, required this.litT, this.mirror = false});
  final M8DocGeo geo;
  final double litT;
  final bool mirror;

  @override
  void paint(Canvas c, Size size) {
    final h = geo.house;
    c.save();
    if (mirror) {
      c.translate(h.left + h.right, 0);
      c.scale(-1, 1);
    }
    final t = litT.clamp(0.0, 1.0);
    final lit = t >= 0.5;
    final wall = Color.lerp(const Color(0xFF4B4E68), const Color(0xFFD8BE8C), t)!;
    final roofC = Color.lerp(const Color(0xFF2E2A3C), const Color(0xFF8F4B3A), t)!;
    final body = Rect.fromLTWH(h.left + 2, h.top + h.height * 0.34, h.width - 14, h.height * 0.66 - 1);
    c.drawRect(body, _fill(wall));
    c.drawPath(
      Path()
        ..moveTo(body.left - 5, body.top)
        ..lineTo(body.center.dx, h.top + 2)
        ..lineTo(body.right + 5, body.top)
        ..close(),
      _fill(roofC),
    );
    // The door.
    final door = Rect.fromLTWH(body.right - 26, body.bottom - 46, 18, 46);
    c.drawRect(door, _fill(Color.lerp(const Color(0xFF2A2230), const Color(0xFF6E4A2E), t)!));
    // The windows: the left one shows the fan.
    final winL = Rect.fromLTWH(body.left + 8, body.top + 14, 32, 32);
    final winR = Rect.fromLTWH(body.left + 52, body.top + 14, 22, 32);
    final glass = Color.lerp(const Color(0xFF151B30), const Color(0xFFFFE08A), t)!;
    for (final r in [winL, winR]) {
      if (lit) c.drawRRect(RRect.fromRectAndRadius(r.inflate(4), const Radius.circular(6)), _fill(const Color(0x40FFD36A)));
      c.drawRect(r, _fill(glass));
      c.drawRect(r, _stroke(const Color(0xFF2A2230), 1.4));
    }
    // The ceiling fan: three blades. Lit: turning (a soft disc of blur).
    final fc = winL.center.translate(0, -4);
    final bladeC = lit ? const Color(0xFFFFFFFF) : const Color(0xFF3D4560);
    if (lit) c.drawCircle(fc, 12, _fill(const Color(0x55FFFFFF)));
    for (var i = 0; i < 3; i++) {
      final a = i * 2 * math.pi / 3 + 0.5;
      c.drawLine(fc, fc + Offset(math.cos(a), math.sin(a)) * 11, _stroke(bladeC, lit ? 3.2 : 2.4));
    }
    c.drawCircle(fc, 2.4, _fill(const Color(0xFF8C93A8)));
    c.drawLine(fc, fc.translate(0, -13), _stroke(const Color(0xFF8C93A8), 1));
    // The pole and the service line.
    final base = geo.poleBase;
    final topP = Offset(base.dx, base.dy - h.height * 0.9);
    c.drawLine(base, topP, _stroke(const Color(0xFF3A3340), 4));
    c.drawLine(topP.translate(-9, 6), topP.translate(9, 6), _stroke(const Color(0xFF3A3340), 3));
    final wire = _stroke(const Color(0xFF14110F), 1.6);
    final eave = Offset(body.right + 4, body.top + 4);
    final from = topP.translate(-7, 6);
    if (lit) {
      c.drawPath(Path()..moveTo(from.dx, from.dy)..quadraticBezierTo((from.dx + eave.dx) / 2, math.max(from.dy, eave.dy) + 9, eave.dx, eave.dy), wire);
    } else {
      // Down: a short stub from the pole, a loose end hanging, the house end loose.
      c.drawPath(Path()..moveTo(from.dx, from.dy)..quadraticBezierTo(from.dx - 3, from.dy + 14, from.dx - 5, from.dy + 26), wire);
      c.drawPath(Path()..moveTo(eave.dx, eave.dy)..quadraticBezierTo(eave.dx + 1, eave.dy + 8, eave.dx + 3, eave.dy + 18), wire);
    }
    c.restore();
  }

  @override
  bool shouldRepaint(M8DocHousePainter old) => old.geo != geo || old.litT != litT || old.mirror != mirror;
}

/// One consumer, standing (a phone in his raised hand when [phone]).
class M8DocConsumerPainter extends CustomPainter {
  const M8DocConsumerPainter({required this.look, required this.rect, this.phone = true});
  final M8DocLook look;
  final Rect rect;
  final bool phone;

  @override
  void paint(Canvas c, Size size) {
    final r = rect;
    final cx = r.center.dx;
    final headR = r.width * 0.2;
    final headC = Offset(cx, r.top + headR + r.height * 0.08);
    final bodyTop = headC.dy + headR + 2;
    final shoulder = r.width * 0.32;
    // Legs.
    final legT = r.top + r.height * 0.62;
    c.drawRect(Rect.fromLTRB(cx - shoulder * 0.7, legT, cx - 2, r.bottom), _fill(const Color(0xFF2A2F46)));
    c.drawRect(Rect.fromLTRB(cx + 2, legT, cx + shoulder * 0.7, r.bottom), _fill(const Color(0xFF2A2F46)));
    // Torso.
    final torso = Rect.fromLTRB(cx - shoulder, bodyTop, cx + shoulder, legT + 4);
    c.drawRRect(RRect.fromRectAndRadius(torso, const Radius.circular(7)), _fill(look.shirt));
    // Arms: the left down, the right raised (the phone).
    c.drawLine(Offset(cx - shoulder + 2, bodyTop + 6), Offset(cx - shoulder - 3, legT - 4), _stroke(look.shirt, 6));
    final hand = Offset(cx + shoulder + 8, bodyTop + (phone ? 10 : 28));
    c.drawLine(Offset(cx + shoulder - 2, bodyTop + 6), hand, _stroke(look.shirt, 6));
    c.drawCircle(hand, 3.4, _fill(look.skin));
    // Head, hair or cap, glasses.
    c.drawCircle(headC, headR, _fill(look.skin));
    if (look.cap) {
      c.drawArc(Rect.fromCircle(center: headC, radius: headR + 0.5), math.pi, math.pi, true, _fill(const Color(0xFFEDE6D2)));
    } else {
      c.drawArc(Rect.fromCircle(center: headC, radius: headR + 0.5), math.pi, math.pi, true, _fill(look.hair));
    }
    if (look.glasses) {
      c.drawCircle(headC.translate(-headR * 0.4, 1), headR * 0.28, _stroke(const Color(0xFF14110F), 1));
      c.drawCircle(headC.translate(headR * 0.4, 1), headR * 0.28, _stroke(const Color(0xFF14110F), 1));
    }
    if (look.umbrella) {
      final top = Offset(cx - shoulder - 8, legT - 6);
      c.drawLine(top, top.translate(0, -r.height * 0.5), _stroke(const Color(0xFF14110F), 1.4));
      c.drawArc(Rect.fromCenter(center: top.translate(0, -r.height * 0.5), width: 34, height: 22), math.pi, math.pi, true, _fill(const Color(0xFF554C86)));
    }
  }

  @override
  bool shouldRepaint(M8DocConsumerPainter old) => old.look != look || old.rect != rect || old.phone != phone;
}

/// The crew's short visit (no steps shown): two hi-vis workers walk to the
/// pole, a flash at its head at [t] ≈ 0.6, then they walk off.
class M8DocCrewPainter extends CustomPainter {
  const M8DocCrewPainter({required this.geo, required this.t});
  final M8DocGeo geo;
  final double t;

  @override
  void paint(Canvas c, Size size) {
    final pole = geo.poleBase;
    final ground = geo.groundY;
    final walkIn = Curves.easeOut.transform((t / 0.45).clamp(0.0, 1.0));
    final walkOut = Curves.easeIn.transform(((t - 0.8) / 0.2).clamp(0.0, 1.0));
    for (var i = 0; i < 2; i++) {
      final x = -30 + (pole.dx + 6 + i * 22 + 30) * walkIn + 90 * walkOut * (i == 0 ? 1 : 0.7);
      final top = ground - 52;
      c.drawRect(Rect.fromLTWH(x - 7, top + 12, 14, 24), _fill(const Color(0xFFFF8A1F)));
      c.drawRect(Rect.fromLTWH(x - 6, top + 36, 5, 16), _fill(const Color(0xFF2A2F46)));
      c.drawRect(Rect.fromLTWH(x + 1, top + 36, 5, 16), _fill(const Color(0xFF2A2F46)));
      c.drawCircle(Offset(x, top + 6), 6, _fill(const Color(0xFFC68E5E)));
      c.drawArc(Rect.fromCircle(center: Offset(x, top + 6), radius: 7), math.pi, math.pi, true, _fill(const Color(0xFFFFD21F)));
    }
    // The flash at the pole head (the line goes back on).
    final f = ((t - 0.5) / 0.2).clamp(0.0, 1.0);
    if (f > 0 && t < 0.78) {
      final head = Offset(pole.dx - 7, pole.dy - geo.house.height * 0.9 + 6);
      final a = math.sin(f * math.pi);
      c.drawCircle(head, 18 * a + 4, _fill(Color.fromRGBO(255, 244, 170, 0.55 * a)));
      c.drawCircle(head, 6 * a + 2, _fill(Color.fromRGBO(255, 255, 255, 0.9 * a)));
    }
  }

  @override
  bool shouldRepaint(M8DocCrewPainter old) => old.t != t || old.geo != geo;
}
