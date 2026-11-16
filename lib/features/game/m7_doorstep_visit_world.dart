import 'dart:math' as math;

import 'package:flutter/material.dart';

// The drawn world of lesson 7.9 কাজ "দরজা থেকে মিটার বক্স" (m7_doorstep_visit.dart):
// a para lane in the morning. Three dealt house fronts (a village courtyard
// house, a two-storey town house, a shop-front with a back store), the crew
// van at the kerb with the visit docket on its side door, and the colleague
// beside it. A low front wall with a gate and a letterbox runs across each
// front; a customer (a man, or a woman alone) may stand at the gate.
//
// Going in pans to a side-cut ground floor: veranda at the front, a hall with
// stairs and the kitchen and back store behind it, the curtained bedroom and
// the puja room at the back. A real grey conduit runs from the meter box to
// the switchboard. Nothing is dimmed, ringed or captioned: the private rooms
// look like every other room, and no state is shown that a worker would not
// see.
//
// Only words a worker reads are painted (none here: signs, labels and speech
// are widgets on the page). Code-drawn, gradients, no bitmaps.
//
// Design: 360 wide × the scene's height; the lane's stack follows the bottom
// of the screen (a tall phone gets more sky, never stretched).

/// The rooms of the ground floor.
enum M7DvRoom { veranda, hall, stairs, kitchen, store, bedroom, puja }

/// Who is at the door.
enum M7DvCust { none, man, woman }

/// Where things are (design px, 360 wide).
@immutable
class M7DvGeo {
  const M7DvGeo._(this.height, this.bottom);

  factory M7DvGeo.forScene(double height, double inset) => M7DvGeo._(height, height - inset * 0.5);

  final double height;
  final double bottom;

  /// The top of the working scene (under the header).
  static const double top = 128;

  // ---------------------------------------------------------------- the lane
  /// The pavement line (the wall's base).
  double get gateY => math.max(262.0, bottom - 360);

  Rect get houseBody => Rect.fromLTWH(138, gateY - 196, 214, 142);
  Rect get wall => Rect.fromLTWH(128, gateY - 54, 232, 54);
  Rect get gate => Rect.fromLTWH(222, gateY - 54, 46, 54);
  Rect get letterbox => Rect.fromLTWH(146, gateY - 44, 26, 22);

  /// The customer at the gate, and the zone that takes a drop for him.
  Rect get cust => Rect.fromLTWH(gate.center.dx - 17, gateY - 124, 34, 90);
  Rect get custZone => cust.inflate(12);

  /// The pavement in front of the gate (the arrival zone).
  Rect get gateFront => Rect.fromLTWH(168, gateY + 2, 150, 100);

  /// Where the trainee stands at the gate; at the van.
  Rect get traineeGate => Rect.fromLTWH(gate.center.dx - 19, gateY + 8, 38, 88);
  Rect get traineeStart => Rect.fromLTWH(10, gateY + 28, 38, 88);

  /// The van (at the kerb, its side door towards us) and the zone that is
  /// "back at the van".
  Rect get van => Rect.fromLTWH(0, gateY - 70, 120, 90);
  Rect get vanZone => Rect.fromLTWH(0, gateY - 74, 150, 190);

  /// The visit docket on the van's door; its close-up (a card over the scene)
  /// and the close-up's close button.
  Rect get docket => Rect.fromLTWH(32, gateY - 56, 66, 46);
  Rect get closeup => Rect.fromLTWH(30, top + 70, 300, 150);
  Rect get closeupX => Rect.fromLTWH(closeup.right - 46, closeup.top + 6, 40, 40);

  /// The colleague by the van; beside the trainee once called.
  Rect get colleagueBase => Rect.fromLTWH(60, gateY + 24, 38, 92);
  Rect get colleagueGate => traineeGate.shift(const Offset(-46, 0));

  /// The tray (three equal items) under the gate, above the guide's bubble.
  Rect get tray => Rect.fromLTWH(12, bottom - 244, 336, 62);
  Rect trayItem(int i) => Rect.fromLTWH(tray.left + i * 114.0, tray.top, 108, tray.height);

  /// What the customer says at the gate (the woman's first line, then his
  /// answer above it).
  Rect get speechA => Rect.fromLTWH(gate.left - 146, gateY - 98, 140, 26);
  Rect get speechNone => Rect.fromLTWH(gate.center.dx - 22, gateY - 96, 44, 26);
  Rect get speechB => Rect.fromLTWH(gate.left - 146, gateY - 130, 140, 26);

  // ----------------------------------------------------------- the cutaway
  /// The ground floor, side-cut. Its height grows on a tall phone.
  Rect get cut => Rect.fromLTWH(10, 138, 340, (bottom - 175 - 138).clamp(240.0, 320.0));

  Rect room(M7DvRoom r) {
    final c = cut;
    final h1 = c.height * 0.30;
    final h2 = c.height * 0.36;
    final h3 = c.height - h1 - h2;
    final y1 = c.top;
    final y2 = c.top + h1;
    final y3 = y2 + h2;
    switch (r) {
      case M7DvRoom.bedroom:
        return Rect.fromLTWH(c.left, y1, 170, h1);
      case M7DvRoom.puja:
        return Rect.fromLTWH(c.left + 170, y1, 170, h1);
      case M7DvRoom.hall:
        return Rect.fromLTWH(c.left, y2, 130, h2);
      case M7DvRoom.stairs:
        return Rect.fromLTWH(c.left + 130, y2, 40, h2);
      case M7DvRoom.kitchen:
        return Rect.fromLTWH(c.left + 170, y2, 85, h2);
      case M7DvRoom.store:
        return Rect.fromLTWH(c.left + 255, y2, 85, h2);
      case M7DvRoom.veranda:
        return Rect.fromLTWH(c.left, y3, 340, h3);
    }
  }

  /// The way out (the veranda's door, at the front).
  Rect get exitDoor => Rect.fromLTWH(cut.left + 8, room(M7DvRoom.veranda).bottom - 40, 44, 40);

  /// The trainee's rect in [r] (his feet on its floor).
  Rect traineeIn(M7DvRoom r) {
    final rr = room(r);
    final h = math.min(64.0, rr.height - 8);
    final w = h * 0.44;
    final x = r == M7DvRoom.veranda ? rr.center.dx + 20 : rr.center.dx;
    return Rect.fromLTWH(x - w / 2, rr.bottom - 4 - h, w, h);
  }

  /// The meter box in its room, and the switchboard in its room.
  Rect meterBox(M7DvRoom r) {
    final rr = room(r);
    return Rect.fromLTWH(rr.left + 8, rr.top + 12, 22, 28);
  }

  Rect switchBoard(M7DvRoom r) {
    final rr = room(r);
    return Rect.fromLTWH(rr.right - 32, rr.top + 12, 24, 28);
  }

  /// The conduit from the meter box to the switchboard (orthogonal runs
  /// along the ceiling).
  List<Offset> conduit(M7DvRoom meter, M7DvRoom board) {
    final m = meterBox(meter).center;
    final s = switchBoard(board).center;
    final y0 = math.min(room(meter).top, room(board).top) + 5;
    return [m, Offset(m.dx, y0), Offset(s.dx, y0), s];
  }

  /// The floor strip of a room, where offcuts lie and the broom works.
  Rect floor(M7DvRoom r) {
    final rr = room(r);
    return Rect.fromLTWH(rr.left + 4, rr.bottom - 18, rr.width - 8, 18);
  }

  /// The broom and the "কাজ শেষ" button, under the cutaway on the left.
  Rect get broom => Rect.fromLTWH(14, cut.bottom + 12, 54, 54);
  Rect get doneBtn => Rect.fromLTWH(76, cut.bottom + 12, 66, 54);

  /// What the customer says inside (where the meter is).
  Rect get meterSays => Rect.fromLTWH(24, 98, 312, 28);

  /// The work beat's bar (above the trainee's room).
  Rect workBar(M7DvRoom r) {
    final rr = room(r);
    return Rect.fromLTWH(rr.center.dx - 26, rr.top + 46, 52, 8);
  }

  @override
  bool operator ==(Object other) => other is M7DvGeo && other.height == height && other.bottom == bottom;

  @override
  int get hashCode => Object.hash(height, bottom);
}

/// What the world shows now.
@immutable
class M7DvRig {
  const M7DvRig({
    required this.house,
    required this.tone,
    required this.inside,
    required this.cust,
    required this.custOut,
    required this.custLook,
    required this.meter,
    required this.board,
    this.slipInBox = false,
  });

  /// 0 village courtyard house, 1 two-storey town house, 2 shop-front.
  final int house;

  /// The morning tint (0 pale gold, 1 clear blue, 2 hazy grey).
  final int tone;
  final bool inside;
  final M7DvCust cust;

  /// The customer has come to the gate (the trainee is there).
  final bool custOut;
  final int custLook;
  final M7DvRoom meter;
  final M7DvRoom board;

  /// A notice slip sits in the letterbox.
  final bool slipInBox;

  @override
  bool operator ==(Object other) =>
      other is M7DvRig &&
      other.house == house &&
      other.tone == tone &&
      other.inside == inside &&
      other.cust == cust &&
      other.custOut == custOut &&
      other.custLook == custLook &&
      other.meter == meter &&
      other.board == board &&
      other.slipInBox == slipInBox;

  @override
  int get hashCode => Object.hash(house, tone, inside, cust, custOut, custLook, meter, board, slipInBox);
}

const _skies = [
  [Color(0xFFBFD9EE), Color(0xFFF6E3B4)],
  [Color(0xFF8FC1E8), Color(0xFFDCEEFA)],
  [Color(0xFFB4C0C8), Color(0xFFE4E6E2)],
];

/// A simple standing person (customer / colleague): [r] is its box.
void _person(Canvas c, Rect r, {required Color shirt, required Color skin, bool woman = false, bool helmet = false, Color? legs}) {
  final w = r.width;
  final head = Offset(r.center.dx, r.top + w * 0.42);
  // Legs / lower cloth.
  if (woman) {
    final sari = Path()
      ..moveTo(r.left + w * 0.12, r.top + r.height * 0.40)
      ..lineTo(r.right - w * 0.12, r.top + r.height * 0.40)
      ..lineTo(r.right - w * 0.02, r.bottom)
      ..lineTo(r.left + w * 0.02, r.bottom)
      ..close();
    c.drawPath(sari, Paint()..color = shirt);
    c.drawPath(
      Path()
        ..moveTo(r.left + w * 0.16, r.top + r.height * 0.40)
        ..lineTo(r.right - w * 0.34, r.top + r.height * 0.40)
        ..lineTo(r.right - w * 0.08, r.bottom - 2)
        ..lineTo(r.left + w * 0.2, r.bottom - 2)
        ..close(),
      Paint()..color = Color.lerp(shirt, const Color(0xFFFFFFFF), 0.28)!,
    );
  } else {
    final lp = Paint()..color = legs ?? const Color(0xFF3B4658);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.left + w * 0.18, r.top + r.height * 0.62, w * 0.28, r.height * 0.38), const Radius.circular(3)), lp);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.right - w * 0.46, r.top + r.height * 0.62, w * 0.28, r.height * 0.38), const Radius.circular(3)), lp);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.left + w * 0.1, r.top + w * 0.78, w * 0.8, r.height * 0.4), const Radius.circular(6)), Paint()..color = shirt);
  }
  // Arms.
  final arm = Paint()..color = shirt;
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.left - w * 0.04, r.top + w * 0.82, w * 0.16, r.height * 0.32), const Radius.circular(4)), arm);
  c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.right - w * 0.12, r.top + w * 0.82, w * 0.16, r.height * 0.32), const Radius.circular(4)), arm);
  // Head.
  c.drawCircle(head, w * 0.28, Paint()..color = skin);
  if (woman) {
    c.drawArc(Rect.fromCircle(center: head, radius: w * 0.3), math.pi, math.pi, true, Paint()..color = const Color(0xFF1B1613));
    c.drawCircle(head.translate(w * 0.2, w * 0.06), w * 0.13, Paint()..color = const Color(0xFF1B1613));
  } else if (helmet) {
    c.drawArc(Rect.fromCircle(center: head, radius: w * 0.32), math.pi, math.pi, true, Paint()..color = const Color(0xFFF5F2E8));
    c.drawRect(Rect.fromLTWH(head.dx - w * 0.36, head.dy - w * 0.02, w * 0.72, w * 0.05), Paint()..color = const Color(0xFFD9D4C4));
  } else {
    c.drawArc(Rect.fromCircle(center: head, radius: w * 0.29), math.pi, math.pi, true, Paint()..color = const Color(0xFF2A211C));
  }
  c.drawCircle(head.translate(-w * 0.09, 0), 1.1, Paint()..color = const Color(0xFF2A211C));
  c.drawCircle(head.translate(w * 0.09, 0), 1.1, Paint()..color = const Color(0xFF2A211C));
}

const _shirts = [Color(0xFF3F7F6A), Color(0xFFB8503E), Color(0xFF3E5E9A)];
const _skins = [Color(0xFFC89472), Color(0xFFB07A58), Color(0xFFD9A98A)];
const _saris = [Color(0xFFB02E5C), Color(0xFF2E7D8A), Color(0xFFC77A1E)];

/// The lane: sky, street, the house front, wall and gate, the van, people.
class M7DvLanePainter extends CustomPainter {
  const M7DvLanePainter({required this.geo, required this.rig});
  final M7DvGeo geo;
  final M7DvRig rig;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    final gy = geo.gateY;
    final sky = _skies[rig.tone.clamp(0, 2)];
    c.drawRect(
      Rect.fromLTWH(0, 0, w, gy + 2),
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: sky).createShader(Rect.fromLTWH(0, 0, w, gy)),
    );
    // Far rooftops and trees.
    final far = Paint()..color = const Color(0x33405868);
    for (var i = 0; i < 6; i++) {
      final x = 8.0 + i * 62;
      c.drawRect(Rect.fromLTWH(x, gy - 150 - (i % 3) * 14, 40, 90 + (i % 3) * 14), far);
    }
    final leaf = Paint()..color = const Color(0x55386B3E);
    c.drawCircle(Offset(120, gy - 140), 26, leaf);
    c.drawCircle(Offset(345, gy - 216), 22, leaf);
    // Ground: pavement, then the lane.
    final pave = Rect.fromLTWH(0, gy, w, 46);
    c.drawRect(pave, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFD8CFBD), Color(0xFFBDB29C)]).createShader(pave));
    final lane = Rect.fromLTWH(0, gy + 46, w, h - gy - 46);
    c.drawRect(lane, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF6D6A66), Color(0xFF4A4845)]).createShader(lane));
    c.drawLine(Offset(0, gy + 46), Offset(w, gy + 46), Paint()
      ..color = const Color(0xFF8E8A82)
      ..strokeWidth = 3);
    final dash = Paint()
      ..color = const Color(0x55F2EEDC)
      ..strokeWidth = 3;
    for (var x = 8.0; x < w; x += 48) {
      c.drawLine(Offset(x, gy + 150), Offset(x + 22, gy + 150), dash);
    }
    _house(c);
    _wall(c);
    _van(c);
    // Letterbox slip.
    if (rig.slipInBox) {
      c.drawRect(Rect.fromLTWH(geo.letterbox.left + 6, geo.letterbox.top - 5, 14, 9), Paint()..color = const Color(0xFFFFF3B0));
    }
    // People: the customer at the gate, the colleague is a widget-free figure
    // drawn here too (his place follows the page).
    if (rig.cust != M7DvCust.none && rig.custOut) {
      final woman = rig.cust == M7DvCust.woman;
      _person(
        c,
        geo.cust,
        shirt: woman ? _saris[rig.custLook % 3] : _shirts[rig.custLook % 3],
        skin: _skins[rig.custLook % 3],
        woman: woman,
        legs: const Color(0xFF8A7B63),
      );
    }
  }

  void _house(Canvas c) {
    final b = geo.houseBody;
    switch (rig.house) {
      case 0:
        // Village courtyard house: mud-plaster walls, a tin roof, a verandah.
        c.drawRect(b, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFD7B98A), Color(0xFFC09E6E)]).createShader(b));
        final roof = Path()
          ..moveTo(b.left - 10, b.top + 18)
          ..lineTo(b.left + 24, b.top - 22)
          ..lineTo(b.right - 24, b.top - 22)
          ..lineTo(b.right + 10, b.top + 18)
          ..close();
        c.drawPath(roof, Paint()..color = const Color(0xFF8F6A52));
        for (var i = 1; i < 6; i++) {
          c.drawLine(Offset(b.left + 24 + i * 24.0, b.top - 20), Offset(b.left + i * 36.0, b.top + 16), Paint()
            ..color = const Color(0x33000000)
            ..strokeWidth = 1.2);
        }
        c.drawRect(Rect.fromLTWH(b.left + 14, b.top + 40, 34, 40), Paint()..color = const Color(0xFF6A4B36));
        c.drawRect(Rect.fromLTWH(b.right - 52, b.top + 40, 34, 40), Paint()..color = const Color(0xFF6A4B36));
        // A tulsi mancha and a cot in the courtyard.
        c.drawRect(Rect.fromLTWH(b.left + 60, b.bottom - 34, 22, 18), Paint()..color = const Color(0xFFE9E2D2));
        c.drawCircle(Offset(b.left + 71, b.bottom - 44), 8, Paint()..color = const Color(0xFF4F8B4C));
      case 1:
        // Two-storey town house: concrete, a balcony, a flat roof.
        c.drawRect(b, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE6E0D4), Color(0xFFCFC8BA)]).createShader(b));
        c.drawRect(Rect.fromLTWH(b.left - 4, b.top - 8, b.width + 8, 10), Paint()..color = const Color(0xFFB9B2A4));
        for (final x in [b.left + 18, b.left + 78, b.left + 138]) {
          c.drawRect(Rect.fromLTWH(x, b.top + 18, 40, 34), Paint()..color = const Color(0xFF7FA9C8));
          c.drawRect(Rect.fromLTWH(x, b.top + 18, 40, 34), Paint()
            ..color = const Color(0xFF8D877A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
          c.drawLine(Offset(x + 20, b.top + 18), Offset(x + 20, b.top + 52), Paint()
            ..color = const Color(0xFF8D877A)
            ..strokeWidth = 1.5);
        }
        c.drawRect(Rect.fromLTWH(b.left + 10, b.top + 56, 94, 5), Paint()..color = const Color(0xFF9C9588));
        for (var x = b.left + 12; x < b.left + 104; x += 12) {
          c.drawLine(Offset(x, b.top + 56), Offset(x, b.top + 74), Paint()
            ..color = const Color(0xFF9C9588)
            ..strokeWidth = 1.5);
        }
        c.drawRect(Rect.fromLTWH(b.left + 130, b.top + 76, 46, 50), Paint()..color = const Color(0xFF7FA9C8));
      default:
        // Shop-front: a signboard, a striped awning, a rolled shutter.
        c.drawRect(b, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFD9C6A8), Color(0xFFBFA886)]).createShader(b));
        c.drawRect(Rect.fromLTWH(b.left + 8, b.top + 10, b.width - 16, 26), Paint()..color = const Color(0xFF2F4E7A));
        c.drawRect(Rect.fromLTWH(b.left + 14, b.top + 16, b.width - 28, 14), Paint()..color = const Color(0xFFF1E7C4));
        for (var i = 0; i < 9; i++) {
          c.drawRect(Rect.fromLTWH(b.left + 6 + i * 22.5, b.top + 44, 22.5, 18), Paint()..color = i.isEven ? const Color(0xFFB8503E) : const Color(0xFFF2EBD8));
        }
        c.drawRect(Rect.fromLTWH(b.left + 14, b.top + 66, b.width - 56, 56), Paint()..color = const Color(0xFF8C9296));
        for (var y = b.top + 72; y < b.top + 122; y += 8) {
          c.drawLine(Offset(b.left + 14, y), Offset(b.right - 42, y), Paint()
            ..color = const Color(0x33000000)
            ..strokeWidth = 1);
        }
    }
  }

  void _wall(Canvas c) {
    final wl = geo.wall;
    final g = geo.gate;
    // The wall: brick courses, a cap; the gate leaves.
    final left = Rect.fromLTRB(wl.left, wl.top, g.left, wl.bottom);
    final right = Rect.fromLTRB(g.right, wl.top, wl.right, wl.bottom);
    for (final r in [left, right]) {
      c.drawRect(r, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFB5624A), Color(0xFF944B38)]).createShader(r));
      for (var y = r.top + 9; y < r.bottom; y += 9) {
        c.drawLine(Offset(r.left, y), Offset(r.right, y), Paint()
          ..color = const Color(0x44000000)
          ..strokeWidth = 1);
      }
      c.drawRect(Rect.fromLTWH(r.left - 2, r.top - 4, r.width + 4, 5), Paint()..color = const Color(0xFFD0C7B6));
    }
    // The gate: two iron leaves, part open.
    c.drawRect(g, Paint()..color = const Color(0xFF2A2420));
    final iron = Paint()
      ..color = const Color(0xFF3F4650)
      ..strokeWidth = 2.2;
    for (var x = g.left + 4; x < g.right - 2; x += 8) {
      c.drawLine(Offset(x, g.top + 4), Offset(x, g.bottom), iron);
    }
    c.drawLine(Offset(g.left, g.top + 10), Offset(g.right, g.top + 10), iron);
    c.drawLine(Offset(g.left, g.bottom - 12), Offset(g.right, g.bottom - 12), iron);
    for (final x in [g.left - 3, g.right + 1]) {
      c.drawRect(Rect.fromLTWH(x, g.top - 8, 5, g.height + 8), Paint()..color = const Color(0xFFC9C0AE));
    }
    // The letterbox.
    final lb = geo.letterbox;
    c.drawRRect(RRect.fromRectAndRadius(lb, const Radius.circular(3)), Paint()..color = const Color(0xFFC63A2F));
    c.drawRect(Rect.fromLTWH(lb.left + 4, lb.top + 6, lb.width - 8, 3), Paint()..color = const Color(0xFF2A1210));
  }

  void _van(Canvas c) {
    final v = geo.van;
    final body = RRect.fromRectAndRadius(v, const Radius.circular(10));
    c.drawRRect(body, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF2EFE6), Color(0xFFC4BFB0)]).createShader(v));
    c.drawRect(Rect.fromLTWH(v.left, v.bottom - 22, v.width, 6), Paint()..color = const Color(0xFFD07A22));
    // Cab window and the sliding door's frame.
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(v.right - 34, v.top + 8, 26, 24), const Radius.circular(4)), Paint()..color = const Color(0xFF6C8296));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(v.left + 24, v.top + 6, 80 - 12, 62), const Radius.circular(4)), Paint()
      ..color = const Color(0x553A3E44)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
    for (final x in [v.left + 28, v.right - 26]) {
      c.drawCircle(Offset(x, v.bottom + 2), 15, Paint()..color = const Color(0xFF15181C));
      c.drawCircle(Offset(x, v.bottom + 2), 6, Paint()..color = const Color(0xFF7A7E84));
    }
  }

  @override
  bool shouldRepaint(M7DvLanePainter old) => old.geo != geo || old.rig != rig;
}

/// The colleague by the van (or beside the trainee).
class M7DvPersonPainter extends CustomPainter {
  const M7DvPersonPainter({required this.look, this.woman = false, this.crew = false});
  final int look;
  final bool woman;
  final bool crew;

  @override
  void paint(Canvas c, Size size) {
    _person(
      c,
      Offset.zero & size,
      shirt: crew ? const Color(0xFF1F3A68) : _shirts[look % 3],
      skin: _skins[look % 3],
      helmet: crew,
      woman: woman,
    );
  }

  @override
  bool shouldRepaint(M7DvPersonPainter old) => old.look != look || old.woman != woman || old.crew != crew;
}

/// The side-cut ground floor with its conduit.
class M7DvInsidePainter extends CustomPainter {
  const M7DvInsidePainter({required this.geo, required this.rig});
  final M7DvGeo geo;
  final M7DvRig rig;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    // The wall behind the cut: a dusky backdrop.
    c.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3A3F4C), Color(0xFF262A34)]).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
    final cut = geo.cut;
    c.drawRRect(RRect.fromRectAndRadius(cut.inflate(5), const Radius.circular(6)), Paint()..color = const Color(0xFF6B5B4A));
    for (final r in M7DvRoom.values) {
      _room(c, r);
    }
    // Room walls (thin partitions).
    final part = Paint()
      ..color = const Color(0xFF7B6A58)
      ..strokeWidth = 3;
    for (final r in M7DvRoom.values) {
      final rr = geo.room(r);
      c.drawRect(rr, part..style = PaintingStyle.stroke);
    }
    // Door gaps are implied by the partitions; the exit door.
    final ex = geo.exitDoor;
    c.drawRect(ex, Paint()..color = const Color(0xFF5A3E2A));
    c.drawRect(ex.deflate(4), Paint()..color = const Color(0xFFA67B52));
    c.drawCircle(Offset(ex.right - 9, ex.center.dy), 2, Paint()..color = const Color(0xFFE8D9A8));
    // The conduit, the meter box, the switchboard.
    final pts = geo.conduit(rig.meter, rig.board);
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final p in pts.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    c.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF55595F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.4
        ..strokeJoin = StrokeJoin.round,
    );
    c.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFB3B8BF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
    final mb = geo.meterBox(rig.meter);
    c.drawRRect(RRect.fromRectAndRadius(mb, const Radius.circular(3)), Paint()..color = const Color(0xFF9DA4AC));
    c.drawCircle(mb.center.translate(0, -3), 6.5, Paint()..color = const Color(0xFFF2F4F2));
    c.drawCircle(mb.center.translate(0, -3), 6.5, Paint()
      ..color = const Color(0xFF3A3F46)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2);
    c.drawLine(mb.center.translate(0, -3), mb.center.translate(3, -6), Paint()
      ..color = const Color(0xFFC63A2F)
      ..strokeWidth = 1.4);
    c.drawRect(Rect.fromLTWH(mb.left + 4, mb.bottom - 9, mb.width - 8, 5), Paint()..color = const Color(0xFF3A3F46));
    final sb = geo.switchBoard(rig.board);
    c.drawRRect(RRect.fromRectAndRadius(sb, const Radius.circular(2)), Paint()..color = const Color(0xFFE9E6DC));
    for (var i = 0; i < 3; i++) {
      c.drawRect(Rect.fromLTWH(sb.left + 4 + i * 6.5, sb.top + 6, 4, 9), Paint()..color = const Color(0xFF3A3F46));
      c.drawRect(Rect.fromLTWH(sb.left + 4 + i * 6.5, sb.top + 17, 4, 5), Paint()..color = const Color(0xFFB0B4B8));
    }
  }

  void _room(Canvas c, M7DvRoom r) {
    final rr = geo.room(r);
    final base = switch (r) {
      M7DvRoom.veranda => const [Color(0xFFE8DCC0), Color(0xFFCDBE9C)],
      M7DvRoom.hall => const [Color(0xFFE9E1CF), Color(0xFFD2C7AE)],
      M7DvRoom.stairs => const [Color(0xFFDAD2C2), Color(0xFFC0B7A4)],
      M7DvRoom.kitchen => const [Color(0xFFE4EAE0), Color(0xFFC9D2C4)],
      M7DvRoom.store => const [Color(0xFFD9D0BE), Color(0xFFBDB29C)],
      M7DvRoom.bedroom => const [Color(0xFFEBDCE0), Color(0xFFD4C0C6)],
      M7DvRoom.puja => const [Color(0xFFF1E3BF), Color(0xFFDCC794)],
    };
    c.drawRect(rr, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: base).createShader(rr));
    // The floor.
    final fl = Rect.fromLTWH(rr.left, rr.bottom - 14, rr.width, 14);
    c.drawRect(fl, Paint()..color = const Color(0x33503C28));
    switch (r) {
      case M7DvRoom.veranda:
        // A bench and a shoe rack.
        c.drawRect(Rect.fromLTWH(rr.left + 78, rr.bottom - 36, 70, 6), Paint()..color = const Color(0xFF8A5E3C));
        c.drawRect(Rect.fromLTWH(rr.left + 82, rr.bottom - 30, 5, 16), Paint()..color = const Color(0xFF6E4A2E));
        c.drawRect(Rect.fromLTWH(rr.left + 140, rr.bottom - 30, 5, 16), Paint()..color = const Color(0xFF6E4A2E));
        c.drawRect(Rect.fromLTWH(rr.right - 60, rr.bottom - 34, 40, 20), Paint()..color = const Color(0xFF9A7A58));
        c.drawLine(Offset(rr.right - 60, rr.bottom - 24), Offset(rr.right - 20, rr.bottom - 24), Paint()..color = const Color(0xFF6E4A2E));
      case M7DvRoom.hall:
        // A settee, a table, an almirah.
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(rr.left + 40, rr.bottom - 34, 50, 20), const Radius.circular(4)), Paint()..color = const Color(0xFF4F7A68));
        c.drawRect(Rect.fromLTWH(rr.left + 40, rr.bottom - 44, 50, 12), Paint()..color = const Color(0xFF3F6A58));
        c.drawRect(Rect.fromLTWH(rr.right - 30, rr.top + 30, 22, rr.height - 44), Paint()..color = const Color(0xFF8B6A4A));
        c.drawLine(Offset(rr.right - 19, rr.top + 30), Offset(rr.right - 19, rr.bottom - 14), Paint()..color = const Color(0xFF5C4430));
      case M7DvRoom.stairs:
        for (var i = 0; i < 5; i++) {
          final y = rr.bottom - 14 - i * (rr.height - 30) / 5;
          c.drawRect(Rect.fromLTWH(rr.left + 4 + i * 5.0, y - 5, rr.width - 8 - i * 5.0, 5), Paint()..color = Color.lerp(const Color(0xFFB4A890), const Color(0xFF9A8E78), i / 5)!);
        }
      case M7DvRoom.kitchen:
        c.drawRect(Rect.fromLTWH(rr.left + 6, rr.bottom - 36, 34, 22), Paint()..color = const Color(0xFF6C7580));
        c.drawCircle(Offset(rr.left + 16, rr.bottom - 38), 4, Paint()..color = const Color(0xFF2E3338));
        c.drawCircle(Offset(rr.left + 30, rr.bottom - 38), 4, Paint()..color = const Color(0xFF2E3338));
        c.drawRect(Rect.fromLTWH(rr.right - 30, rr.top + 40, 24, 5), Paint()..color = const Color(0xFF8B6A4A));
        c.drawRect(Rect.fromLTWH(rr.right - 28, rr.top + 28, 8, 12), Paint()..color = const Color(0xFFC63A2F));
      case M7DvRoom.store:
        c.drawRect(Rect.fromLTWH(rr.left + 10, rr.bottom - 34, 26, 20), Paint()..color = const Color(0xFFA5814E));
        c.drawRect(Rect.fromLTWH(rr.left + 40, rr.bottom - 26, 22, 12), Paint()..color = const Color(0xFFB69462));
        c.drawRect(Rect.fromLTWH(rr.left + 16, rr.bottom - 52, 22, 18), Paint()..color = const Color(0xFFB69462));
        c.drawOval(Rect.fromLTWH(rr.right - 28, rr.bottom - 30, 20, 16), Paint()..color = const Color(0xFFD9CDB0));
      case M7DvRoom.bedroom:
        // A bed, and a curtain across the doorway.
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(rr.left + 20, rr.bottom - 34, 70, 20), const Radius.circular(4)), Paint()..color = const Color(0xFF8E4A5E));
        c.drawRect(Rect.fromLTWH(rr.left + 16, rr.bottom - 44, 8, 30), Paint()..color = const Color(0xFF6E3A4A));
        final cur = Rect.fromLTWH(rr.right - 46, rr.top + 6, 38, rr.height - 20);
        for (var i = 0; i < 6; i++) {
          c.drawRect(Rect.fromLTWH(cur.left + i * cur.width / 6, cur.top, cur.width / 6 + 0.5, cur.height), Paint()..color = i.isEven ? const Color(0xFF7A5C94) : const Color(0xFF6A4C84));
        }
        c.drawLine(Offset(cur.left - 2, cur.top), Offset(cur.right + 2, cur.top), Paint()
          ..color = const Color(0xFF3A2A4A)
          ..strokeWidth = 3);
      case M7DvRoom.puja:
        // A small shrine with a lamp and a marigold garland.
        c.drawRect(Rect.fromLTWH(rr.center.dx - 24, rr.bottom - 40, 48, 26), Paint()..color = const Color(0xFFA06A2A));
        c.drawRect(Rect.fromLTWH(rr.center.dx - 18, rr.bottom - 66, 36, 26), Paint()..color = const Color(0xFFD59B3A));
        c.drawCircle(Offset(rr.center.dx, rr.bottom - 55), 7, Paint()..color = const Color(0xFF7A3E1E));
        c.drawCircle(Offset(rr.center.dx - 12, rr.bottom - 44), 3, Paint()..color = const Color(0xFFFFE08A));
        for (var i = 0; i < 7; i++) {
          c.drawCircle(Offset(rr.center.dx - 18 + i * 6.0, rr.bottom - 68 + (i % 2) * 2), 2.6, Paint()..color = const Color(0xFFF08A1C));
        }
    }
  }

  @override
  bool shouldRepaint(M7DvInsidePainter old) => old.geo != geo || old.rig != rig;
}
