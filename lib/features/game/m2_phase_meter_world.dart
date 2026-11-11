import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The pump house where a new three-phase pump motor waits to be started
// (Module 2, lesson 2.8 "ফেজ সিকোয়েন্স মিটার", কাজ 1 "ঘূর্ণন পড়ুন"): a drawn,
// layered place — the whitewashed wall and concrete floor, the main switch
// (ON/OFF lever), the motor's open terminal box with three marked phase
// terminals (R, Y, B tags) and the incoming cables, the starter (START/STOP),
// the phase sequence meter with its three leads (rotating-disc or digital
// FWD/REV type), and the pump with the motor beside it (the pump's printed
// arrow shows its right direction). Only labels a worker reads: ON/OFF, the
// R/Y/B tags, START/STOP, FWD/REV.
//
// Design: 360 wide × the scene's height; the floor follows the bottom of the
// screen (a tall phone gets more wall above).

enum PmPhase { r, y, b }

enum PmMeter { disc, digital }

/// The incoming cable colours (lesson pro tip 1: the field does not always
/// follow the red-yellow-blue rule).
enum PmCables { standard, black, mixed }

/// What the meter shows.
enum PmReading { blank, fwd, rev }

extension PmPhaseX on PmPhase {
  String get tag => switch (this) {
        PmPhase.r => 'R',
        PmPhase.y => 'Y',
        PmPhase.b => 'B',
      };
  Color get color => switch (this) {
        PmPhase.r => const Color(0xFFD7372B),
        PmPhase.y => const Color(0xFFF2C21B),
        PmPhase.b => const Color(0xFF2F6FD6),
      };
}

/// Where things are (design px, 360 wide).
@immutable
class PmGeo {
  const PmGeo({required this.height, required this.floorY, required this.s});

  factory PmGeo.forScene(double h, double inset) {
    final f = h - 150 - inset;
    return PmGeo(height: h, floorY: f, s: ((f - 140) / 490).clamp(0.7, 1.0));
  }

  final double height;
  final double floorY;

  /// Vertical squeeze on a short screen.
  final double s;

  double y(double up) => floorY - up * s;

  Rect get mainSwitch => Rect.fromLTRB(14, y(480), 100, y(368));
  Rect get box => Rect.fromLTRB(122, y(480), 302, y(312));
  Rect get starter => Rect.fromLTRB(306, y(292), 352, y(184));
  Rect get meter => Rect.fromLTRB(10, y(300), 160, y(166));

  /// Terminal [slot] (0 left … 2 right) in the box.
  Offset terminal(int slot) => Offset(152 + 60.0 * slot, y(380));
  Offset tagAt(int slot) => Offset(152 + 60.0 * slot, y(428));

  /// Where a lead [i] (R, Y, B) leaves the meter, and where its clip rests.
  Offset socket(int i) => Offset(40 + 45.0 * i, meter.top + 4);
  Offset parked(int i) => Offset(40 + 45.0 * i, meter.top - 20);

  Offset get window => Offset(meter.center.dx, meter.top + 82 * s);
  Offset get pump => Offset(48, floorY - 50);
  Rect get motor => Rect.fromLTRB(80, floorY - 82, 154, floorY - 18);

  @override
  bool operator ==(Object other) => other is PmGeo && other.height == height && other.floorY == floorY && other.s == s;

  @override
  int get hashCode => Object.hash(height, floorY, s);
}

/// Everything the world painter shows (one moment's state).
@immutable
class PmView {
  const PmView({
    required this.order,
    required this.cables,
    required this.meter,
    required this.live,
    required this.clips,
    required this.selected,
    required this.reading,
    required this.badLead,
    required this.motor,
  });

  /// The tags left to right.
  final List<PmPhase> order;
  final PmCables cables;
  final PmMeter meter;
  final bool live;

  /// Lead → the terminal tag it is clipped to (absent = parked at the meter).
  final Map<PmPhase, PmPhase> clips;
  final PmPhase? selected;
  final PmReading reading;

  /// The damaged lead on this meter (drawn as it is: cracked near the socket).
  final PmPhase? badLead;

  /// The motor: 0 still, 1 the right way, −1 backwards.
  final int motor;

  @override
  bool operator ==(Object other) =>
      other is PmView &&
      listEquals(other.order, order) &&
      other.cables == cables &&
      other.meter == meter &&
      other.live == live &&
      mapEquals(other.clips, clips) &&
      other.selected == selected &&
      other.reading == reading &&
      other.badLead == badLead &&
      other.motor == motor;

  @override
  int get hashCode => Object.hash(Object.hashAll(order), cables, meter, live, Object.hashAll(clips.entries.map((e) => '${e.key}${e.value}')), selected, reading, badLead, motor);
}

/// The colour of the incoming cable on tag [tag].
Color pmCableColor(PmCables c, PmPhase tag) => switch (c) {
      PmCables.standard => tag.color,
      PmCables.black => const Color(0xFF202226),
      // Never the tag's own colour (a derangement): R gets yellow, Y blue, B red.
      PmCables.mixed => PmPhase.values[(tag.index + 1) % 3].color,
    };

void _label(Canvas c, String text, Offset centre, {double size = 10, Color color = Colors.white, FontWeight weight = FontWeight.w900}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: TextStyle(fontFamily: 'Roboto', fontSize: size, fontWeight: weight, color: color, height: 1)),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
}

/// The pump house, the panels, the meter and its leads, the pump and motor.
/// [t]: seconds of motion (advances only while the scene is awake).
class PmWorldPainter extends CustomPainter {
  PmWorldPainter({required this.geo, required this.view, required this.t}) : super(repaint: t);
  final PmGeo geo;
  final PmView view;
  final ValueListenable<double> t;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final f = geo.floorY;
    final time = t.value;
    // --- the wall and the floor -------------------------------------------------
    c.drawRect(
        Rect.fromLTRB(0, 0, w, f),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFCFC6B2), Color(0xFFE6DFCC), Color(0xFFD8CFB8)],
          ).createShader(Rect.fromLTRB(0, 0, w, f)));
    // The dado band and its line.
    c.drawRect(Rect.fromLTRB(0, f - 120, w, f), Paint()..color = const Color(0xFF9DB0A2));
    c.drawRect(Rect.fromLTRB(0, f - 124, w, f - 120), Paint()..color = const Color(0xFF7D9183));
    // Damp stains (a pump house).
    final stain = Paint()..color = const Color(0x18584A2C);
    c.drawOval(Rect.fromLTWH(196, f - 170, 90, 40), stain);
    c.drawOval(Rect.fromLTWH(20, geo.y(520), 120, 34), stain);
    c.drawRect(
        Rect.fromLTRB(0, f, w, size.height),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF8E8A80), Color(0xFF6D6A62)],
          ).createShader(Rect.fromLTRB(0, f, w, size.height)));
    final seam = Paint()
      ..color = const Color(0x33000000)
      ..strokeWidth = 1;
    for (var x = -40.0; x < w + 60; x += 70) {
      c.drawLine(Offset(x, f), Offset(x - 40, size.height), seam);
    }
    c.drawLine(Offset(0, f + 40), Offset(w, f + 40), seam);

    _conduits(c);
    _mainSwitch(c);
    _starter(c);
    _box(c);
    _pumpAndMotor(c, time);
    _meter(c, time);
  }

  Paint _steel(Rect r, {bool dark = false}) => Paint()
    ..shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: dark ? const [Color(0xFF5E6873), Color(0xFF39414B)] : const [Color(0xFFB9C2CB), Color(0xFF7D8892)],
    ).createShader(r);

  void _shadow(Canvas c, RRect r) => c.drawRRect(r.shift(const Offset(3, 4)), Paint()..color = const Color(0x40000000));

  void _conduits(Canvas c) {
    final pipe = Paint()
      ..color = const Color(0xFF6E7781)
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final ms = geo.mainSwitch;
    final b = geo.box;
    final st = geo.starter;
    // From the ceiling to the main switch; main switch → box; box → starter;
    // starter → down → along the floor to the motor.
    c.drawLine(Offset(ms.center.dx, 0), Offset(ms.center.dx, ms.top), pipe);
    c.drawLine(Offset(ms.right, ms.top + 22 * geo.s), Offset(b.left, ms.top + 22 * geo.s), pipe);
    c.drawPath(
        Path()
          ..moveTo(b.right, b.bottom - 20 * geo.s)
          ..lineTo(st.center.dx, b.bottom - 20 * geo.s)
          ..lineTo(st.center.dx, st.top),
        pipe);
    c.drawPath(
        Path()
          ..moveTo(st.center.dx, st.bottom)
          ..lineTo(st.center.dx, geo.floorY - 8)
          ..lineTo(geo.motor.right, geo.floorY - 8),
        pipe);
    final hi = Paint()
      ..color = const Color(0x55FFFFFF)
      ..strokeWidth = 2;
    c.drawLine(Offset(ms.center.dx - 2, 0), Offset(ms.center.dx - 2, ms.top), hi);
  }

  void _mainSwitch(Canvas c) {
    final r = geo.mainSwitch;
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(6));
    _shadow(c, rr);
    c.drawRRect(rr, _steel(r));
    c.drawRRect(
        rr,
        Paint()
          ..color = const Color(0xFF4B545E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    // The door seam and the rivets.
    c.drawRect(Rect.fromLTRB(r.left + 8, r.top + 8, r.right - 26, r.bottom - 8), Paint()..color = const Color(0x22000000));
    // The lever on its right side: up = ON, down = OFF.
    final pivot = Offset(r.right - 12, r.center.dy);
    final tip = view.live ? pivot + Offset(0, -38 * geo.s) : pivot + Offset(0, 38 * geo.s);
    c.drawLine(
        pivot,
        tip,
        Paint()
          ..color = const Color(0xFF2A2F35)
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round);
    c.drawCircle(tip, 8, Paint()..color = const Color(0xFFC62828));
    c.drawCircle(pivot, 6, Paint()..color = const Color(0xFF2A2F35));
    _label(c, 'ON', Offset(r.right - 40, r.top + 18 * geo.s), size: 11, color: const Color(0xFF14532D));
    _label(c, 'OFF', Offset(r.right - 40, r.bottom - 18 * geo.s), size: 11, color: const Color(0xFF7F1D1D));
    // The danger plate.
    final plate = Rect.fromCenter(center: Offset(r.left + 26, r.center.dy), width: 26, height: 22);
    c.drawRect(plate, Paint()..color = const Color(0xFFFFD34E));
    c.drawPath(
        Path()
          ..moveTo(plate.center.dx + 2, plate.top + 3)
          ..lineTo(plate.center.dx - 4, plate.center.dy + 1)
          ..lineTo(plate.center.dx + 1, plate.center.dy + 1)
          ..lineTo(plate.center.dx - 2, plate.bottom - 3)
          ..lineTo(plate.center.dx + 5, plate.center.dy - 2)
          ..lineTo(plate.center.dx, plate.center.dy - 2)
          ..close(),
        Paint()..color = const Color(0xFF1B1B1B));
  }

  void _starter(Canvas c) {
    final r = geo.starter;
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(5));
    _shadow(c, rr);
    c.drawRRect(rr, _steel(r, dark: true));
    final on = view.motor != 0;
    c.drawCircle(Offset(r.center.dx, r.top + 14 * geo.s), 6, Paint()..color = on ? const Color(0xFF7CFF7A) : const Color(0xFF1F3B22));
    c.drawCircle(Offset(r.center.dx, r.top + 42 * geo.s), 10, Paint()..color = const Color(0xFF1FA34A));
    _label(c, 'START', Offset(r.center.dx, r.top + 58 * geo.s), size: 8);
    c.drawCircle(Offset(r.center.dx, r.top + 80 * geo.s), 10, Paint()..color = const Color(0xFFC62828));
    _label(c, 'STOP', Offset(r.center.dx, r.top + 96 * geo.s), size: 8);
  }

  void _box(Canvas c) {
    final r = geo.box;
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(6));
    _shadow(c, rr);
    c.drawRRect(rr, _steel(r));
    // The open inside.
    final inner = RRect.fromRectAndRadius(r.deflate(8), const Radius.circular(4));
    c.drawRRect(inner, Paint()..color = const Color(0xFF2A3038));
    // The open cover, hinged on the left.
    c.drawPath(
        Path()
          ..moveTo(r.left, r.top + 4)
          ..lineTo(r.left - 18, r.top + 16)
          ..lineTo(r.left - 18, r.bottom - 16)
          ..lineTo(r.left, r.bottom - 4)
          ..close(),
        Paint()..color = const Color(0xFF8C969F));
    // The terminal rail.
    final railY = geo.terminal(0).dy;
    c.drawRect(Rect.fromLTRB(r.left + 14, railY - 4, r.right - 14, railY + 4), Paint()..color = const Color(0xFF8B949C));
    for (var i = 0; i < 3; i++) {
      final tag = view.order[i];
      final p = geo.terminal(i);
      final tagP = geo.tagAt(i);
      // The incoming cable: from the top of the box down to the terminal.
      final cable = Paint()
        ..color = pmCableColor(view.cables, tag)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      c.drawPath(
          Path()
            ..moveTo(r.left + 40 + i * 20, r.top + 8)
            ..cubicTo(r.left + 40 + i * 20, r.top + 30, p.dx, tagP.dy - 30, p.dx, p.dy - 14),
          cable);
      c.drawLine(
          Offset(r.left + 40 + i * 20 - 1.5, r.top + 10),
          Offset(r.left + 40 + i * 20 - 1.5, r.top + 22),
          Paint()
            ..color = const Color(0x44FFFFFF)
            ..strokeWidth = 1.5);
      // The outgoing cable to the starter, under the terminal.
      c.drawLine(
          Offset(p.dx, p.dy + 12),
          Offset(p.dx + 10, r.bottom - 8),
          Paint()
            ..color = const Color(0xFF202226)
            ..strokeWidth = 6
            ..strokeCap = StrokeCap.round);
      // The brass terminal and its screw.
      final t = RRect.fromRectAndRadius(Rect.fromCenter(center: p, width: 26, height: 24), const Radius.circular(3));
      c.drawRRect(
          t,
          Paint()
            ..shader = const LinearGradient(colors: [Color(0xFFF1CF6B), Color(0xFFA9782A)]).createShader(t.outerRect));
      c.drawCircle(p, 6, Paint()..color = const Color(0xFF8A6420));
      c.drawLine(p - const Offset(4, 0), p + const Offset(4, 0), Paint()..color = const Color(0xFF3D2A0A)..strokeWidth = 1.6);
      // The phase tag (painted marking: the identity of the phase).
      final tr = RRect.fromRectAndRadius(Rect.fromCenter(center: tagP, width: 26, height: 22), const Radius.circular(4));
      c.drawRRect(tr, Paint()..color = tag.color);
      c.drawRRect(
          tr,
          Paint()
            ..color = const Color(0xCC111111)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2);
      _label(c, tag.tag, tagP, size: 14, color: tag == PmPhase.y ? const Color(0xFF1B1B1B) : Colors.white);
    }
  }

  void _pumpAndMotor(Canvas c, double time) {
    final f = geo.floorY;
    final m = geo.motor;
    final p = geo.pump;
    // The base frame.
    c.drawRect(Rect.fromLTRB(8, f - 18, m.right + 8, f - 4), Paint()..color = const Color(0xFF3E4651));
    // The delivery pipe from the pump up and out through the wall.
    final pipe = Paint()
      ..color = const Color(0xFF5B87A8)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke;
    c.drawPath(
        Path()
          ..moveTo(p.dx, p.dy - 30)
          ..lineTo(p.dx, f - 150)
          ..lineTo(0, f - 150),
        pipe);
    // Water out of the pipe while the pump runs the right way.
    if (view.motor == 1) {
      final wv = Paint()
        ..color = const Color(0xAA6EC6FF)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 4; i++) {
        final k = ((time * 1.6 + i / 4) % 1);
        c.drawLine(Offset(p.dx - 4 + i * 3, f - 160 - k * 14), Offset(p.dx - 4 + i * 3, f - 166 - k * 14), wv);
      }
    }
    // The motor body with its cooling fins.
    final body = RRect.fromRectAndRadius(m, const Radius.circular(10));
    c.drawRRect(
        body,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF4FA36B), Color(0xFF235E39)],
          ).createShader(m));
    final fin = Paint()
      ..color = const Color(0x55102A18)
      ..strokeWidth = 2;
    for (var x = m.left + 10; x < m.right - 6; x += 8) {
      c.drawLine(Offset(x, m.top + 6), Offset(x, m.bottom - 6), fin);
    }
    c.drawRect(Rect.fromLTRB(m.left + 22, m.top - 10, m.left + 50, m.top + 2), Paint()..color = const Color(0xFF2E6B45));
    // The pump (seen from its end): volute, impeller, the printed arrow.
    c.drawCircle(p, 34, Paint()..color = const Color(0xFF41627E));
    c.drawCircle(
        p,
        34,
        Paint()
          ..color = const Color(0xFF243A4E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
    c.drawCircle(p, 22, Paint()..color = const Color(0xFF1A2633));
    final spin = view.motor * time * math.pi * 2 * 1.4;
    final vane = Paint()
      ..color = const Color(0xFFB9C9D8)
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 6; i++) {
      final a = spin + i * math.pi / 3;
      c.drawLine(p + Offset(math.cos(a), math.sin(a)) * 5, p + Offset(math.cos(a + 0.5), math.sin(a + 0.5)) * 19, vane);
    }
    c.drawCircle(p, 5, Paint()..color = const Color(0xFFDDE6EE));
    // The arrow cast on the volute: the right way round (clockwise).
    final arc = Paint()
      ..color = const Color(0xFFFFD34E)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    c.drawArc(Rect.fromCircle(center: p, radius: 29), -2.6, 1.7, false, arc);
    final head = p + Offset(math.cos(-0.9), math.sin(-0.9)) * 29;
    c.drawPath(
        Path()
          ..moveTo(head.dx + 6, head.dy + 1)
          ..lineTo(head.dx - 3, head.dy - 6)
          ..lineTo(head.dx - 2, head.dy + 6)
          ..close(),
        Paint()..color = const Color(0xFFFFD34E));
  }

  void _meter(Canvas c, double time) {
    final r = geo.meter;
    final s = geo.s;
    // The leads first (from the sockets to the clips), under the meter's top.
    final clips = <PmPhase, Offset>{};
    for (final lead in PmPhase.values) {
      final tag = view.clips[lead];
      final at = tag == null ? geo.parked(lead.index) : geo.terminal(view.order.indexOf(tag)) + const Offset(0, 6);
      clips[lead] = at;
      final from = geo.socket(lead.index);
      final wire = Paint()
        ..color = lead.color
        ..strokeWidth = 4.2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      final path = Path()..moveTo(from.dx, from.dy);
      if (tag == null) {
        path.quadraticBezierTo(from.dx - 14, from.dy - 6, at.dx, at.dy + 10);
      } else {
        path.cubicTo(from.dx, from.dy - 60, at.dx, at.dy + 70, at.dx, at.dy + 12);
      }
      c.drawPath(path, Paint()
        ..color = const Color(0x55000000)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke);
      c.drawPath(path, wire);
      // A cracked lead shows its copper near the socket (honest, small).
      if (view.badLead == lead) {
        final crack = from + const Offset(-6, -6);
        c.drawCircle(crack, 3.6, Paint()..color = const Color(0xFFD9822B));
        c.drawLine(crack - const Offset(4, 2), crack + const Offset(4, 2), Paint()..color = const Color(0xFF7A3E0E)..strokeWidth = 1.2);
      }
    }
    // The meter body.
    final body = RRect.fromRectAndRadius(r, const Radius.circular(14));
    _shadow(c, body);
    c.drawRRect(
        body,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFC928), Color(0xFFE09A0E)],
          ).createShader(r));
    final face = RRect.fromRectAndRadius(r.deflate(9), const Radius.circular(9));
    c.drawRRect(face, Paint()..color = const Color(0xFF1E232A));
    // The sockets.
    for (final lead in PmPhase.values) {
      final so = geo.socket(lead.index);
      c.drawCircle(so, 6.5, Paint()..color = const Color(0xFF111111));
      c.drawCircle(so, 4, Paint()..color = lead.color);
    }
    // The phase lamps (each lit when its lead is on a live terminal).
    for (final lead in PmPhase.values) {
      final lp = Offset(40 + 45.0 * lead.index, r.top + 30 * s);
      final lit = view.live && view.clips.containsKey(lead);
      c.drawCircle(lp, 6.5, Paint()..color = lit ? const Color(0xFFFF9A3C) : const Color(0xFF3A2A1E));
      if (lit) c.drawCircle(lp, 11, Paint()..color = const Color(0x33FF9A3C));
      _label(c, lead.tag, lp + Offset(0, 14 * s), size: 9, color: const Color(0xFFCBD5E1));
    }
    final win = geo.window;
    if (view.meter == PmMeter.disc) {
      // The rotating disc behind its window; the case's arrow marks the
      // right way (clockwise).
      c.drawCircle(win, 30 * s + 4, Paint()..color = const Color(0xFF0B0E12));
      c.drawCircle(win, 30 * s, Paint()..color = const Color(0xFFEDEFF2));
      final dir = switch (view.reading) {
        PmReading.fwd => 1,
        PmReading.rev => -1,
        PmReading.blank => 0,
      };
      final a0 = dir * time * math.pi * 2 * 0.9;
      final seg = Paint()..color = const Color(0xFF15181C);
      for (var i = 0; i < 4; i++) {
        final a = a0 + i * math.pi / 2;
        c.drawArc(Rect.fromCircle(center: win, radius: 30 * s - 2), a, 0.55, true, seg);
      }
      // One red mark on the disc, to follow with the eye.
      final mk = win + Offset(math.cos(a0 + 1.1), math.sin(a0 + 1.1)) * (22 * s);
      c.drawCircle(mk, 4, Paint()..color = const Color(0xFFE53935));
      c.drawCircle(win, 4, Paint()..color = const Color(0xFF6B7280));
      // The printed arrow above the window.
      final arc = Paint()
        ..color = const Color(0xFF7CFF7A)
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke;
      final ar = Rect.fromCircle(center: win, radius: 30 * s + 10);
      c.drawArc(ar, -2.4, 1.5, false, arc);
      final hp = win + Offset(math.cos(-0.9), math.sin(-0.9)) * (30 * s + 10);
      c.drawPath(
          Path()
            ..moveTo(hp.dx + 5, hp.dy + 2)
            ..lineTo(hp.dx - 3, hp.dy - 5)
            ..lineTo(hp.dx - 2, hp.dy + 6)
            ..close(),
          Paint()..color = const Color(0xFF7CFF7A));
    } else {
      // The digital type: FWD (clockwise) and REV (anti-clockwise) LEDs.
      for (final (i, k) in const [PmReading.fwd, PmReading.rev].indexed) {
        final p = win + Offset(i == 0 ? -34 : 34, -6 * s);
        final on = view.reading == k;
        final col = k == PmReading.fwd ? const Color(0xFF34D96A) : const Color(0xFFFF4D4D);
        final off = k == PmReading.fwd ? const Color(0xFF173421) : const Color(0xFF3B1717);
        if (on) c.drawCircle(p, 17, Paint()..color = col.withValues(alpha: 0.25));
        c.drawCircle(p, 10, Paint()..color = on ? col : off);
        _label(c, k == PmReading.fwd ? 'FWD' : 'REV', p + Offset(0, 22 * s), size: 10, color: const Color(0xFFCBD5E1));
        // The little arrow printed by each LED.
        final ap = p + Offset(0, -20 * s);
        final arrow = Paint()
          ..color = const Color(0xFF9CA3AF)
          ..strokeWidth = 1.6
          ..style = PaintingStyle.stroke;
        c.drawArc(Rect.fromCircle(center: ap, radius: 6), k == PmReading.fwd ? -2.6 : -0.5, k == PmReading.fwd ? 2.1 : -2.1, false, arrow);
      }
    }
    // The clips (over the meter and the box).
    for (final lead in PmPhase.values) {
      final at = clips[lead]!;
      final sel = view.selected == lead;
      if (sel) c.drawCircle(at, 19, Paint()..color = const Color(0x66FFFFFF));
      if (sel) {
        c.drawCircle(
            at,
            19,
            Paint()
              ..color = Colors.white
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.4);
      }
      final jaw = RRect.fromRectAndRadius(Rect.fromCenter(center: at, width: 14, height: 24), const Radius.circular(4));
      c.drawRRect(jaw, Paint()..color = lead.color);
      c.drawRRect(
          jaw,
          Paint()
            ..color = const Color(0xCC111111)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2);
      c.drawLine(at + const Offset(-5, -12), at + const Offset(-5, -16), Paint()..color = const Color(0xFF9CA3AF)..strokeWidth = 2);
      c.drawLine(at + const Offset(5, -12), at + const Offset(5, -16), Paint()..color = const Color(0xFF9CA3AF)..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(PmWorldPainter old) => old.view != view || old.geo != geo || old.t != t;
}

/// The arc at a terminal (in colour over the frozen grey room): a white
/// flash, a blue-white arc and sparks. Non-graphic.
class PmArcPainter extends CustomPainter {
  const PmArcPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final flick = v < 0.5 ? (0.65 + 0.35 * math.sin(v * 60).abs()) : (1 - (v - 0.5) * 1.2).clamp(0.4, 1.0);
    final r = 26 + 46 * Curves.easeOut.transform(v.clamp(0.0, 1.0));
    c.drawCircle(
        at,
        r,
        Paint()
          ..shader = RadialGradient(colors: [Color.fromRGBO(220, 235, 255, 0.95 * flick), const Color(0x0066A3FF)]).createShader(Rect.fromCircle(center: at, radius: r)));
    final rnd = math.Random(3);
    final arc = Paint()
      ..color = Color.fromRGBO(255, 255, 255, flick)
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke;
    for (var k = 0; k < 3; k++) {
      final path = Path()..moveTo(at.dx, at.dy);
      var p = at;
      for (var i = 0; i < 5; i++) {
        p = p + Offset((rnd.nextDouble() - 0.5) * 22, -8 - rnd.nextDouble() * 6) * (k.isEven ? 1 : -1);
        path.lineTo(p.dx, p.dy);
      }
      c.drawPath(path, arc);
    }
    final spark = Paint()
      ..color = Color.fromRGBO(255, 214, 90, (1 - v).clamp(0.0, 1.0))
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 14; i++) {
      final a = i / 14 * math.pi * 2 + 0.3;
      final d0 = 10 + 40 * v;
      c.drawLine(at + Offset(math.cos(a), math.sin(a)) * d0, at + Offset(math.cos(a), math.sin(a)) * (d0 + 12), spark);
    }
    final white = (1 - v * 4).clamp(0.0, 1.0);
    if (white > 0) c.drawRect(Offset.zero & size, Paint()..color = Color.fromRGBO(255, 255, 255, 0.8 * white));
  }

  @override
  bool shouldRepaint(PmArcPainter old) => old.v != v || old.at != at;
}

/// The three leads up close (the inspection card): each lead from its plug to
/// its clip; a damaged one shows cracked insulation and bare copper.
class PmLeadsPainter extends CustomPainter {
  const PmLeadsPainter({required this.bad});
  final PmPhase? bad;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    for (final lead in PmPhase.values) {
      final y = h * (0.22 + 0.28 * lead.index);
      final from = Offset(w * 0.06, y);
      final to = Offset(w * 0.86, y);
      final path = Path()
        ..moveTo(from.dx, from.dy)
        ..cubicTo(w * 0.35, y - 16, w * 0.55, y + 16, to.dx, to.dy);
      c.drawPath(path, Paint()
        ..color = const Color(0x55000000)
        ..strokeWidth = 12
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round);
      c.drawPath(path, Paint()
        ..color = lead.color
        ..strokeWidth = 9
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round);
      c.drawPath(path.shift(const Offset(0, -2.5)), Paint()
        ..color = const Color(0x40FFFFFF)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke);
      // The plug and the clip.
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: from, width: 22, height: 16), const Radius.circular(4)), Paint()..color = const Color(0xFF1B1B1B));
      final jaw = RRect.fromRectAndRadius(Rect.fromCenter(center: to + const Offset(12, 0), width: 30, height: 18), const Radius.circular(5));
      c.drawRRect(jaw, Paint()..color = lead.color);
      c.drawRRect(
          jaw,
          Paint()
            ..color = const Color(0xCC111111)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4);
      _label(c, lead.tag, to + const Offset(12, 0), size: 11, color: lead == PmPhase.y ? const Color(0xFF1B1B1B) : Colors.white);
      if (bad == lead) {
        // Split insulation with the copper strands showing.
        final at = Offset(w * 0.46, y + 1);
        c.drawOval(Rect.fromCenter(center: at, width: 26, height: 11), Paint()..color = const Color(0xFF2A1A0A));
        final cu = Paint()
          ..color = const Color(0xFFE08A35)
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round;
        for (var i = -3; i <= 3; i++) {
          c.drawLine(at + Offset(-10.0 + i, -2), at + Offset(8.0 + i, 2.5), cu);
        }
        final crack = Paint()
          ..color = const Color(0xFF1B1B1B)
          ..strokeWidth = 1.4
          ..style = PaintingStyle.stroke;
        c.drawPath(
            Path()
              ..moveTo(at.dx - 20, at.dy - 4)
              ..lineTo(at.dx - 14, at.dy - 1)
              ..moveTo(at.dx + 14, at.dy + 2)
              ..lineTo(at.dx + 21, at.dy + 5),
            crack);
      }
    }
  }

  @override
  bool shouldRepaint(PmLeadsPainter old) => old.bad != bad;
}
