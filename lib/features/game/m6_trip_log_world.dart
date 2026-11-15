import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The drawn world of lesson 6.2 কাজ 1 "ট্রিপের খাতা" (m6_trip_log.dart): a
// distribution substation at night, two rooms.
//
//  * The control room: on the back wall the relay board (one relay case per
//    feeder, its feeder plate on top; from across the room every case looks
//    the same — the drop flags and the fault window are read only in the
//    lens), the red alarm lamp on the board, a glass door on the right to the
//    breaker room (plate 'ব্রেকার রুম'), and the desk with the trip register
//    (closed) and the radio.
//  * The breaker room: a glass door on the left back to the control room
//    (plate 'কন্ট্রোল রুম') and a row of 3–4 indoor breaker panels. Each panel
//    has its feeder plate, its VCB/OCB face, a red ON and a green OFF lamp of
//    the same size (the lit one glows the same, red or green), the TRIP CKT
//    HEALTHY lamp, the spring flag and the operation counter (shown, never
//    scored), the breaker door and its handle; a planned-OFF breaker carries a
//    padlock and a red tag on its handle. A panel the trainee has marked open
//    carries a chalk ring.
//
// No captions in the art; only labels a worker reads (feeder plates, room
// plates, VCB/OCB, ON/OFF, R/Y/B, the relay's own window). Code-drawn,
// gradients, no bitmaps. Design: 360 wide × the scene's height (560–900).

/// Which room the trainee is in.
enum M6Room { control, breakers }

/// The breaker's arc-quenching kind (lesson 6.2 point 2).
enum M6Face { vcb, ocb }

/// Where things are (design px, 360 wide).
@immutable
class M6TripGeo {
  const M6TripGeo._(this.height);

  factory M6TripGeo.forScene(double height) => M6TripGeo._(height);

  final double height;

  /// Where the wall meets the floor.
  double get floorY => height - 170;

  // --- the control room ------------------------------------------------------
  /// The relay board on the back wall.
  static const Rect relayBoard = Rect.fromLTRB(6, 130, 256, 242);

  /// Relay case [i] of [n].
  static Rect relay(int i, int n) {
    const l = 14.0, r = 248.0, gap = 6.0;
    final w = (r - l - gap * (n - 1)) / n;
    return Rect.fromLTWH(l + i * (w + gap), 144, w, 92);
  }

  /// The glass door to the breaker room (right wall).
  static const Rect doorToBreakers = Rect.fromLTWH(272, 138, 78, 196);

  /// The lens over a relay face (below the board).
  static const Rect lens = Rect.fromLTWH(12, 250, 238, 122);

  /// The radio on the desk.
  Offset get radio => Offset(150, floorY - 14);

  // --- the breaker room ------------------------------------------------------
  /// The glass door back to the control room (left wall).
  static const Rect doorToControl = Rect.fromLTWH(8, 150, 54, 190);

  /// The panel row's height (a tall phone gets taller panels, up to a limit).
  double get panelH => (height - 380).clamp(200.0, 270.0);

  /// Breaker panel [i] of [n].
  Rect panel(int i, int n) {
    const l = 70.0, r = 352.0, gap = 4.0;
    final w = (r - l - gap * (n - 1)) / n;
    return Rect.fromLTWH(l + i * (w + gap), 136, w, panelH);
  }

  /// The 'দেখা শেষ' button under the panels (clear of the guide).
  Rect get lookDone => Rect.fromLTWH(70, 136 + panelH + 12, 132, 40);

  /// Where the trainee stands.
  Rect trainee(M6Room room) => Rect.fromLTWH(room == M6Room.control ? 200 : 76, height - 158, 44, 104);

  @override
  bool operator ==(Object other) => other is M6TripGeo && other.height == height;

  @override
  int get hashCode => height.hashCode;
}

/// What the rooms show now.
@immutable
class M6TripRig {
  const M6TripRig({
    required this.room,
    required this.names,
    required this.faces,
    required this.open,
    required this.planned,
    required this.counters,
    this.marks = const {},
  });

  final M6Room room;

  /// Feeder plates, left to right (panels and relay cases alike).
  final List<String> names;
  final List<M6Face> faces;

  /// The breaker is open (green lit) — tripped or planned OFF.
  final List<bool> open;

  /// The planned-OFF breaker (padlock + tag), or −1.
  final int planned;
  final List<int> counters;

  /// The panels chalk-marked open.
  final Set<int> marks;

  @override
  bool operator ==(Object other) =>
      other is M6TripRig &&
      other.room == room &&
      listEquals(other.names, names) &&
      listEquals(other.faces, faces) &&
      listEquals(other.open, open) &&
      other.planned == planned &&
      listEquals(other.counters, counters) &&
      setEquals(other.marks, marks);

  @override
  int get hashCode => Object.hash(room, Object.hashAll(names), Object.hashAll(faces), Object.hashAll(open), planned, Object.hashAll(counters), Object.hashAllUnordered(marks));
}

const _lampRed = Color(0xFFFF3B30);
const _lampGreen = Color(0xFF2EE66B);

void _text(Canvas c, String t, Offset at, double size, Color color, {FontWeight weight = FontWeight.w900, double? maxWidth}) {
  final tp = TextPainter(
    text: TextSpan(text: t, style: TextStyle(color: color, fontSize: size, fontWeight: weight, height: 1.1)),
    textDirection: TextDirection.ltr,
    maxLines: 1,
  )..layout();
  var w = tp.width;
  if (maxWidth != null && w > maxWidth) {
    c.save();
    c.translate(at.dx, at.dy);
    final s = maxWidth / w;
    c.scale(s, s);
    tp.paint(c, Offset(-tp.width / 2, -tp.height / 2));
    c.restore();
    return;
  }
  w = tp.width;
  tp.paint(c, at - Offset(w / 2, tp.height / 2));
}

class M6TripPainter extends CustomPainter {
  const M6TripPainter({required this.geo, required this.rig});

  final M6TripGeo geo;
  final M6TripRig rig;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final floor = geo.floorY;
    // The wall: a dim night room under tube light.
    final wall = Rect.fromLTWH(0, 0, w, floor);
    c.drawRect(
        wall,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: rig.room == M6Room.control ? const [Color(0xFF26364A), Color(0xFF3A4C60)] : const [Color(0xFF2E3A40), Color(0xFF46555C)],
          ).createShader(wall));
    // The tube light at the top.
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w / 2 - 70, 104, 140, 7), const Radius.circular(3)), Paint()..color = const Color(0xFFE8F2FF));
    c.drawRect(Rect.fromLTWH(w / 2 - 90, 111, 180, 26), Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x33E8F2FF), Color(0x00E8F2FF)]).createShader(Rect.fromLTWH(w / 2 - 90, 111, 180, 26)));
    // The floor: grey stone tiles.
    final fl = Rect.fromLTRB(0, floor, w, size.height);
    c.drawRect(fl, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF5E666C), Color(0xFF3A4046)]).createShader(fl));
    final tile = Paint()
      ..color = const Color(0x33101418)
      ..strokeWidth = 1;
    for (var y = floor + 18.0; y < size.height; y += 26) {
      c.drawLine(Offset(0, y), Offset(w, y), tile);
    }
    for (var x = -40.0; x < w + 40; x += 46) {
      c.drawLine(Offset(x + 20, floor), Offset(x - 40, size.height), tile);
    }
    c.drawRect(Rect.fromLTWH(0, floor - 4, w, 5), Paint()..color = const Color(0xFF1E262C));
    if (rig.room == M6Room.control) {
      _controlRoom(c, w);
    } else {
      _breakerRoom(c, w);
    }
  }

  // --- the control room --------------------------------------------------------
  void _controlRoom(Canvas c, double w) {
    final n = rig.names.length;
    // The relay board: a grey steel cabinet.
    const b = M6TripGeo.relayBoard;
    c.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(4)), Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFB9C2C6), Color(0xFF8E989D)]).createShader(b));
    c.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(4)), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF59646A));
    // The alarm lamp on top of the board (lit: a feeder has tripped).
    final alarm = Offset(b.right - 16, b.top + 7);
    c.drawCircle(alarm, 9, Paint()..color = const Color(0x55FF3B30));
    c.drawCircle(alarm, 5, Paint()..color = _lampRed);
    for (var i = 0; i < n; i++) {
      _relayCase(c, M6TripGeo.relay(i, n), rig.names[i]);
    }
    // The glass door to the breaker room.
    _glassDoor(c, M6TripGeo.doorToBreakers, 'ব্রেকার রুম', handleLeft: true);
    _nightWindow(c);
    _clock(c, Offset(311, M6TripGeo.doorToBreakers.bottom + 36));
    // The desk with the register and the radio.
    final top = geo.floorY - 30;
    final desk = Rect.fromLTRB(4, top, 252, top + 14);
    c.drawRRect(RRect.fromRectAndRadius(desk, const Radius.circular(3)), Paint()..color = const Color(0xFF8A5A34));
    c.drawRect(Rect.fromLTRB(14, desk.bottom, 26, geo.floorY + 30), Paint()..color = const Color(0xFF5E3C22));
    c.drawRect(Rect.fromLTRB(230, desk.bottom, 242, geo.floorY + 30), Paint()..color = const Color(0xFF5E3C22));
    // The trip register, closed.
    final book = Rect.fromLTWH(40, top - 9, 70, 10);
    c.drawRRect(RRect.fromRectAndRadius(book, const Radius.circular(2)), Paint()..color = const Color(0xFF7A1F1F));
    c.drawRect(Rect.fromLTWH(book.left + 3, book.top + 2, book.width - 6, 3), Paint()..color = const Color(0xFFF2E9D2));
    // The radio.
    final r = geo.radio;
    final body = Rect.fromCenter(center: r.translate(0, -6), width: 30, height: 22);
    c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(4)), Paint()..color = const Color(0xFF22282E));
    c.drawLine(Offset(body.right - 6, body.top), Offset(body.right - 2, body.top - 18), Paint()
      ..color = const Color(0xFF22282E)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round);
    for (var k = 0; k < 3; k++) {
      c.drawLine(Offset(body.left + 5, body.top + 6 + k * 4.0), Offset(body.left + 16, body.top + 6 + k * 4.0), Paint()
        ..color = const Color(0xFF5A646E)
        ..strokeWidth = 1.4);
    }
    c.drawCircle(Offset(body.right - 7, body.top + 7), 2, Paint()..color = const Color(0xFF6BE08A));
  }

  /// A window on the night outside (a moon, the yard's far poles), under
  /// the relay board and above the desk.
  void _nightWindow(Canvas c) {
    final bottom = geo.floorY - 48;
    final top = math.max(M6TripGeo.relayBoard.bottom + 14, bottom - 84);
    if (bottom - top < 30) return;
    final r = Rect.fromLTRB(40, top, 220, bottom);
    c.drawRect(r.inflate(4), Paint()..color = const Color(0xFF6B7378));
    c.drawRect(r, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF07101F), Color(0xFF1A2A44)]).createShader(r));
    c.save();
    c.clipRect(r);
    c.drawCircle(Offset(r.right - 30, r.top + 18), 9, Paint()..color = const Color(0xFFF4EBC8));
    final star = Paint()..color = const Color(0xAAFFFFFF);
    for (final p in const [Offset(0.12, 0.2), Offset(0.3, 0.12), Offset(0.48, 0.3), Offset(0.62, 0.16)]) {
      c.drawCircle(Offset(r.left + r.width * p.dx, r.top + r.height * p.dy), 1.2, star);
    }
    final pole = Paint()
      ..color = const Color(0xFF2C3A50)
      ..strokeWidth = 2;
    for (var k = 0; k < 4; k++) {
      final x = r.left + 18 + k * 46.0;
      c.drawLine(Offset(x, r.bottom), Offset(x, r.bottom - 34), pole);
      c.drawLine(Offset(x - 8, r.bottom - 30), Offset(x + 8, r.bottom - 30), pole);
    }
    c.drawLine(Offset(r.left, r.bottom - 29), Offset(r.right, r.bottom - 27), Paint()
      ..color = const Color(0xFF2C3A50)
      ..strokeWidth = 1);
    c.restore();
    c.drawLine(Offset(r.center.dx, r.top), Offset(r.center.dx, r.bottom), Paint()
      ..color = const Color(0xFF6B7378)
      ..strokeWidth = 3);
  }

  /// A wall clock at about two at night (no digits).
  void _clock(Canvas c, Offset at) {
    if (at.dy + 20 > geo.floorY - 40) return;
    c.drawCircle(at, 18, Paint()..color = const Color(0xFF59646A));
    c.drawCircle(at, 15.5, Paint()..color = const Color(0xFFF2EEE2));
    final tick = Paint()
      ..color = const Color(0xFF2A3036)
      ..strokeWidth = 1.4;
    for (var i = 0; i < 12; i++) {
      final a = i / 12 * math.pi * 2;
      c.drawLine(at + Offset(math.sin(a), -math.cos(a)) * 12, at + Offset(math.sin(a), -math.cos(a)) * 14.5, tick);
    }
    final hand = Paint()
      ..color = const Color(0xFF1E2328)
      ..strokeCap = StrokeCap.round;
    const h = 2.17 / 12 * math.pi * 2;
    const m = 10 / 60 * math.pi * 2;
    c.drawLine(at, at + Offset(math.sin(h), -math.cos(h)) * 8, hand..strokeWidth = 2.4);
    c.drawLine(at, at + Offset(math.sin(m), -math.cos(m)) * 12, hand..strokeWidth = 1.6);
  }

  /// A relay case from across the room: plate, display, three flag windows,
  /// the reset button — every case alike until read in the lens.
  void _relayCase(Canvas c, Rect r, String name) {
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF39434A), Color(0xFF242C32)]).createShader(r));
    final plate = Rect.fromLTWH(r.left + 3, r.top + 4, r.width - 6, 17);
    c.drawRRect(RRect.fromRectAndRadius(plate, const Radius.circular(2)), Paint()..color = const Color(0xFFF2E9D2));
    _text(c, name, plate.center, 10.5, const Color(0xFF1E1A14), maxWidth: plate.width - 4);
    final disp = Rect.fromLTWH(r.left + 6, r.top + 27, r.width - 12, 14);
    c.drawRRect(RRect.fromRectAndRadius(disp, const Radius.circular(2)), Paint()..color = const Color(0xFF0E1A14));
    for (var p = 0; p < 3; p++) {
      final at = Offset(r.left + r.width * (0.25 + 0.25 * p), r.top + 56);
      c.drawCircle(at, 5, Paint()..color = const Color(0xFF0A0D10));
      c.drawCircle(at, 5, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFF6A747C));
    }
    c.drawCircle(Offset(r.center.dx, r.bottom - 14), 5, Paint()..color = const Color(0xFF8A929A));
    c.drawCircle(Offset(r.center.dx, r.bottom - 14), 2.4, Paint()..color = const Color(0xFF3A4248));
  }

  void _glassDoor(Canvas c, Rect d, String plate, {required bool handleLeft}) {
    c.drawRect(d.inflate(3), Paint()..color = const Color(0xFF6B7378));
    c.drawRect(d, Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF7FA6B8), Color(0xFF3F6474), Color(0xFF6E96A8)]).createShader(d));
    // Glints on the glass.
    final glint = Paint()
      ..color = const Color(0x44FFFFFF)
      ..strokeWidth = 5;
    c.drawLine(Offset(d.left + d.width * 0.25, d.top + 30), Offset(d.left + d.width * 0.55, d.top + 6), glint);
    c.drawLine(Offset(d.left + d.width * 0.3, d.top + 52), Offset(d.left + d.width * 0.72, d.top + 14), glint);
    final p = Rect.fromLTWH(d.left + 4, d.top + 40, d.width - 8, 18);
    c.drawRRect(RRect.fromRectAndRadius(p, const Radius.circular(2)), Paint()..color = const Color(0xFFF2E9D2));
    _text(c, plate, p.center, 10, const Color(0xFF1E1A14), maxWidth: p.width - 4);
    final hx = handleLeft ? d.left + 8 : d.right - 8;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(hx, d.center.dy + 10), width: 5, height: 34), const Radius.circular(2)), Paint()..color = const Color(0xFFD9DEE1));
  }

  // --- the breaker room --------------------------------------------------------
  void _breakerRoom(Canvas c, double w) {
    _glassDoor(c, M6TripGeo.doorToControl, 'কন্ট্রোল রুম', handleLeft: false);
    final n = rig.names.length;
    for (var i = 0; i < n; i++) {
      _panel(c, geo.panel(i, n), i);
    }
  }

  void _panel(Canvas c, Rect p, int i) {
    final ivory = Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFD7D9CF), Color(0xFFB4B8AC)]).createShader(p);
    c.drawRRect(RRect.fromRectAndRadius(p, const Radius.circular(3)), ivory);
    c.drawRRect(RRect.fromRectAndRadius(p, const Radius.circular(3)), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = const Color(0xFF6E7468));
    final cx = p.center.dx;
    // Feeder plate.
    final plate = Rect.fromLTWH(p.left + 4, p.top + 6, p.width - 8, 18);
    c.drawRRect(RRect.fromRectAndRadius(plate, const Radius.circular(2)), Paint()..color = const Color(0xFF1C2E4A));
    _text(c, rig.names[i], plate.center, 10.5, const Color(0xFFF2E9D2), maxWidth: plate.width - 4);
    // Face label.
    _text(c, rig.faces[i] == M6Face.vcb ? 'VCB' : 'OCB', Offset(cx, p.top + 33), 9, const Color(0xFF2A3036));
    // ON (red) / OFF (green) lamps: the same size; the lit one glows the same.
    final open = rig.open[i];
    _lamp(c, Offset(cx - 14, p.top + 52), _lampRed, lit: !open);
    _lamp(c, Offset(cx + 14, p.top + 52), _lampGreen, lit: open);
    _text(c, 'ON', Offset(cx - 14, p.top + 66), 7, const Color(0xFF2A3036));
    _text(c, 'OFF', Offset(cx + 14, p.top + 66), 7, const Color(0xFF2A3036));
    // TRIP CKT HEALTHY (lit), spring flag, counter — shown, not scored.
    _lamp(c, Offset(cx - 14, p.top + 82), const Color(0xFFFFF2C2), lit: true, r: 4.5);
    _text(c, 'TCH', Offset(cx + 8, p.top + 82), 7, const Color(0xFF2A3036));
    final spring = Rect.fromCenter(center: Offset(cx, p.top + 98), width: math.min(48, p.width - 10), height: 11);
    c.drawRect(spring, Paint()..color = const Color(0xFFF2D24A));
    _text(c, 'CHARGED', spring.center, 6.5, const Color(0xFF2A2408), maxWidth: spring.width - 2);
    final ctr = Rect.fromCenter(center: Offset(cx, p.top + 115), width: math.min(44, p.width - 12), height: 12);
    c.drawRect(ctr, Paint()..color = const Color(0xFF14181C));
    _text(c, rig.counters[i].toString().padLeft(5, '0'), ctr.center, 7.5, const Color(0xFFE8EEF2), maxWidth: ctr.width - 2);
    // The breaker door: louvres and a handle.
    final door = Rect.fromLTRB(p.left + 5, p.top + 128, p.right - 5, p.bottom - 6);
    c.drawRRect(RRect.fromRectAndRadius(door, const Radius.circular(2)), Paint()..color = const Color(0xFFC6C9BE));
    c.drawRRect(RRect.fromRectAndRadius(door, const Radius.circular(2)), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0xFF7E8478));
    final lv = Paint()
      ..color = const Color(0xFF8E9488)
      ..strokeWidth = 1.4;
    for (var k = 0; k < 4; k++) {
      final y = door.top + 8 + k * 6.0;
      c.drawLine(Offset(door.left + 8, y), Offset(door.right - 8, y), lv);
    }
    final handle = Offset(door.right - 10, door.top + door.height * 0.55);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: handle, width: 6, height: 26), const Radius.circular(3)), Paint()..color = const Color(0xFF3A4046));
    if (i == rig.planned) {
      // Padlock and a red tag on the handle (planned work, lock + tag).
      final lock = handle.translate(-4, 18);
      c.drawArc(Rect.fromCenter(center: lock.translate(0, -5), width: 10, height: 10), math.pi, math.pi, false, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xFF9AA2A8));
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: lock.translate(0, 2), width: 13, height: 11), const Radius.circular(2)), Paint()..color = const Color(0xFFE0B23A));
      final tag = Path()
        ..moveTo(lock.dx - 6, lock.dy + 8)
        ..lineTo(lock.dx - 26, lock.dy + 12)
        ..lineTo(lock.dx - 26, lock.dy + 36)
        ..lineTo(lock.dx - 6, lock.dy + 32)
        ..close();
      c.drawPath(tag, Paint()..color = const Color(0xFFC62828));
      c.drawCircle(Offset(lock.dx - 16, lock.dy + 22), 4, Paint()..color = const Color(0xFFFFFFFF));
    }
    if (rig.marks.contains(i)) {
      // The trainee's chalk ring on the breaker door.
      final at = Offset(door.center.dx - 4, door.top + door.height * 0.62);
      final chalk = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xF2FFFFFF);
      final rr = math.min(17.0, door.width * 0.3);
      c.drawArc(Rect.fromCircle(center: at, radius: rr), -0.6, 5.6, false, chalk);
      c.drawLine(at.translate(-7, 0), at.translate(-2, 6), chalk);
      c.drawLine(at.translate(-2, 6), at.translate(8, -7), chalk);
    }
  }

  void _lamp(Canvas c, Offset at, Color color, {required bool lit, double r = 7.5}) {
    c.drawCircle(at, r + 2, Paint()..color = const Color(0xFF2A3036));
    if (lit) {
      c.drawCircle(at, r + 6, Paint()..color = color.withValues(alpha: 0.28));
      c.drawCircle(at, r, Paint()..shader = RadialGradient(colors: [Colors.white, color]).createShader(Rect.fromCircle(center: at, radius: r)));
    } else {
      c.drawCircle(at, r, Paint()..color = Color.lerp(color, const Color(0xFF1A1E22), 0.78)!);
    }
  }

  @override
  bool shouldRepaint(M6TripPainter old) => old.geo != geo || old.rig != rig;
}

/// The lens over one relay face: its plate, the fault window and the three
/// drop flags (R, Y, B). A dropped flag shows orange and white; the rest
/// stay black. A relay that did not operate shows no flag and a blank window.
class M6LensPainter extends CustomPainter {
  const M6LensPainter({required this.name, required this.flags, required this.window});

  final String name;
  final Set<int> flags;

  /// The fault window's words ('' = blank).
  final String window;

  static const phases = ['R', 'Y', 'B'];

  @override
  void paint(Canvas c, Size size) {
    final r = Offset.zero & size;
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(14)), Paint()..color = const Color(0xFF0B1324));
    final face = r.deflate(6);
    c.drawRRect(RRect.fromRectAndRadius(face, const Radius.circular(10)), Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3E4950), Color(0xFF262E34)]).createShader(face));
    c.drawRRect(RRect.fromRectAndRadius(r.deflate(2), const Radius.circular(12)), Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFFE2C26A));
    final plate = Rect.fromLTWH(face.left + 10, face.top + 6, face.width - 20, 22);
    c.drawRRect(RRect.fromRectAndRadius(plate, const Radius.circular(3)), Paint()..color = const Color(0xFFF2E9D2));
    _text(c, name, plate.center, 14, const Color(0xFF1E1A14), maxWidth: plate.width - 6);
    final win = Rect.fromLTWH(face.left + 16, face.top + 34, face.width - 32, 26);
    c.drawRRect(RRect.fromRectAndRadius(win, const Radius.circular(3)), Paint()..color = const Color(0xFF0E1A14));
    if (window.isNotEmpty) _text(c, window, win.center, 14, const Color(0xFF8CFFB0), maxWidth: win.width - 8);
    for (var p = 0; p < 3; p++) {
      final at = Offset(face.left + face.width * (0.25 + 0.25 * p), face.top + 80);
      c.drawCircle(at, 13, Paint()..color = const Color(0xFF6A747C));
      if (flags.contains(p)) {
        c.save();
        c.clipPath(Path()..addOval(Rect.fromCircle(center: at, radius: 11)));
        c.drawCircle(at, 11, Paint()..color = const Color(0xFFFF8A1E));
        final stripe = Paint()
          ..color = Colors.white
          ..strokeWidth = 3.4;
        for (var k = -2; k <= 2; k++) {
          c.drawLine(at.translate(-14 + k * 7.0, 14), at.translate(k * 7.0 + 0, -14), stripe);
        }
        c.restore();
      } else {
        c.drawCircle(at, 11, Paint()..color = const Color(0xFF07090B));
      }
      _text(c, phases[p], at.translate(0, 22), 11, const Color(0xFFE8EEF2));
    }
  }

  @override
  bool shouldRepaint(M6LensPainter old) => old.name != name || !setEquals(old.flags, flags) || old.window != window;
}

/// A breaker re-trips (or a neighbour opens on a fault): a burst at [at],
/// [v] 0 → 1.
class M6BangPainter extends CustomPainter {
  const M6BangPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final a = (1 - v).clamp(0.0, 1.0);
    if (a <= 0) return;
    final r = 18 + 60 * Curves.easeOut.transform(v.clamp(0.0, 1.0));
    c.drawCircle(
        at,
        r,
        Paint()
          ..shader = RadialGradient(colors: [Color.fromRGBO(255, 252, 230, 0.95 * a), Color.fromRGBO(140, 190, 255, 0.45 * a), const Color(0x00FFFFFF)])
              .createShader(Rect.fromCircle(center: at, radius: r)));
    final spark = Paint()
      ..color = Color.fromRGBO(255, 214, 90, a)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 12; i++) {
      final t = i / 12 * math.pi * 2;
      final d0 = 8 + 40 * v;
      c.drawLine(at + Offset(math.cos(t), math.sin(t)) * d0, at + Offset(math.cos(t), math.sin(t)) * (d0 + 10), spark);
    }
  }

  @override
  bool shouldRepaint(M6BangPainter old) => old.v != v || old.at != at;
}

/// The deadly consequence in colour over the grey room: out on the feeder at
/// night, the crew member on the pole top and the line he took for dead —
/// back-fed from another feeder, it arcs to his hands. [v] 0 → 1.
class M6BackfeedPainter extends CustomPainter {
  const M6BackfeedPainter({required this.v, required this.height});
  final double v;
  final double height;

  @override
  void paint(Canvas c, Size size) {
    final box = Rect.fromCenter(center: Offset(size.width / 2, math.max(300, height * 0.42)), width: 280, height: 190);
    final appear = Curves.easeOut.transform((v * 3).clamp(0.0, 1.0));
    c.save();
    c.translate(box.center.dx, box.center.dy);
    c.scale(0.85 + 0.15 * appear);
    c.translate(-box.center.dx, -box.center.dy);
    final rr = RRect.fromRectAndRadius(box, const Radius.circular(14));
    c.drawRRect(rr, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0B1630), Color(0xFF1D2C4A)]).createShader(box));
    c.save();
    c.clipRRect(rr);
    // Ground and two poles with the line between them.
    c.drawRect(Rect.fromLTRB(box.left, box.bottom - 30, box.right, box.bottom), Paint()..color = const Color(0xFF243018));
    final lp = Offset(box.left + 50, box.bottom - 30);
    final rp = Offset(box.right - 70, box.bottom - 30);
    final pole = Paint()..color = const Color(0xFF8E9498);
    c.drawRect(Rect.fromLTWH(lp.dx - 3, box.top + 40, 6, lp.dy - box.top - 40), pole);
    c.drawRect(Rect.fromLTWH(rp.dx - 3, box.top + 40, 6, rp.dy - box.top - 40), pole);
    final arm = Paint()
      ..color = const Color(0xFF6A7074)
      ..strokeWidth = 4;
    c.drawLine(Offset(lp.dx - 24, box.top + 46), Offset(lp.dx + 24, box.top + 46), arm);
    c.drawLine(Offset(rp.dx - 24, box.top + 46), Offset(rp.dx + 24, box.top + 46), arm);
    final wire = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = const Color(0xFFB8C0C6);
    for (final dx in [-18.0, 0.0, 18.0]) {
      c.drawPath(
          Path()
            ..moveTo(box.left, box.top + 44 + dx * 0.1)
            ..quadraticBezierTo(lp.dx + dx, box.top + 50, lp.dx + dx, box.top + 44)
            ..quadraticBezierTo((lp.dx + rp.dx) / 2, box.top + 60, rp.dx + dx, box.top + 44)
            ..quadraticBezierTo(box.right - 20, box.top + 52, box.right, box.top + 46),
          wire);
    }
    // The back-feed coming in from the far side (another feeder).
    final glow = (0.5 + 0.5 * math.sin(v * 40).abs()) * (1 - (v - 0.7).clamp(0.0, 0.3));
    final feed = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Color.fromRGBO(255, 210, 80, 0.85 * glow);
    c.drawPath(
        Path()
          ..moveTo(box.right, box.top + 46)
          ..quadraticBezierTo(box.right - 20, box.top + 52, rp.dx + 18, box.top + 44),
        feed);
    // The crew member on the right pole top (harness to the pole), hands up
    // to the line.
    final body = Offset(rp.dx + 16, box.top + 86);
    final man = Paint()..color = const Color(0xFF1F5F8F);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: body, width: 18, height: 36), const Radius.circular(5)), man);
    c.drawRect(Rect.fromCenter(center: body.translate(0, 2), width: 18, height: 5), Paint()..color = const Color(0xFFFF851B));
    c.drawLine(body.translate(-9, 8), Offset(rp.dx + 3, body.dy + 6), Paint()
      ..color = const Color(0xFF3A3020)
      ..strokeWidth = 2.4);
    final legs = Paint()
      ..color = const Color(0xFF26303D)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    c.drawLine(body.translate(-4, 17), Offset(rp.dx + 4, body.dy + 36), legs);
    c.drawLine(body.translate(4, 17), Offset(rp.dx + 16, body.dy + 38), legs);
    c.drawCircle(body.translate(0, -26), 8, Paint()..color = const Color(0xFFA86E48));
    c.drawArc(Rect.fromCenter(center: body.translate(0, -30), width: 19, height: 13), math.pi, math.pi, true, Paint()..color = const Color(0xFFFFD34E));
    final armP = Paint()
      ..color = const Color(0xFF1F5F8F)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final hand = Offset(rp.dx + 18, box.top + 50);
    c.drawLine(body.translate(2, -12), hand, armP);
    // The arc from the line to his hand.
    final arcA = (v < 0.12 ? 0.0 : 1.0) * glow;
    if (arcA > 0) {
      c.drawCircle(hand, 14 + 8 * glow, Paint()..color = Color.fromRGBO(255, 240, 160, 0.5 * arcA));
      final bolt = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4
        ..strokeJoin = StrokeJoin.round
        ..color = Color.fromRGBO(255, 250, 215, arcA);
      final a = Offset(rp.dx + 18, box.top + 44);
      c.drawPath(
          Path()
            ..moveTo(a.dx, a.dy - 2)
            ..lineTo(a.dx + 6, a.dy + 2)
            ..lineTo(a.dx - 4, a.dy + 4)
            ..lineTo(hand.dx, hand.dy),
          bolt);
      final spark = Paint()
        ..color = Color.fromRGBO(255, 214, 90, arcA)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 8; i++) {
        final t = i / 8 * math.pi * 2 + v * 3;
        c.drawLine(hand + Offset(math.cos(t), math.sin(t)) * 10, hand + Offset(math.cos(t), math.sin(t)) * (18 + 6 * glow), spark);
      }
    }
    c.restore();
    c.drawRRect(rr, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = const Color(0xFFE2C26A));
    c.restore();
    final white = (1 - v * 5).clamp(0.0, 1.0);
    if (white > 0) c.drawRect(Offset.zero & size, Paint()..color = Color.fromRGBO(255, 255, 255, 0.7 * white));
  }

  @override
  bool shouldRepaint(M6BackfeedPainter old) => old.v != v || old.height != height;
}
