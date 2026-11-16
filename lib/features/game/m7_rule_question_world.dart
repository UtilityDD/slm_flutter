import 'dart:math' as math;

import 'package:flutter/material.dart';

// The drawn world of lesson 7.1 কাজ 2 "প্রশ্ন করার অধিকার"
// (m7_rule_question.dart): an LT lane on a shutdown morning. From the left:
// the DTR on its plinth (its AB switch on the pole stub above, open, the
// handle locked and tagged, three HG fuses under it — M7-9, no DO; nothing is
// ever charged in 7.1: a readied DTR only loses its tag, the AB stays open
// — M7-6 / M6-1), with its
// body and neutral earth leads running down to two earth pits; the feeder
// pillar (the danger plate on its door, or a bare door, or the plate lying on
// the ground against its foot); the LT pole with the service line to a new house whose
// balcony reaches toward it (clear above it, or resting on the railing); in
// front, the crew van with its rear open (the kit crate, and the helmet hook
// on its side), and today's helper with his ID card on a lanyard.
//
// No text in the art except labels a worker reads (the danger plate). The
// helper's ID card back is a widget (m7_rule_question.dart), not painted.
// Code-drawn, gradients, no bitmaps.
//
// Design: 360 wide × the scene's height. The lane itself is drawn in its own
// 360 × 470 box ("lane units") scaled uniformly to fit between the header and
// the floor line (a short phone gets a smaller lane, never a squashed one; a
// tall phone gets more sky). The floor line sits above the guide and the
// controls at the bottom of the screen.

/// The five things an order can be about (one per scene object).
enum M7RqKind { helper, pillar, earth, balcony, kit }

/// The danger plate on the pillar door.
enum M7RqPlate { fixed, bare, ground }

/// The DTR's earth leads.
enum M7RqLead { ok, cut, hanging }

/// The service line by the new balcony.
enum M7RqLine { clear, resting }

/// What the lane shows now.
@immutable
class M7RqLook {
  const M7RqLook({
    this.helperPerson = 0,
    this.helperUp = false,
    this.plate = M7RqPlate.fixed,
    this.plateRight = false,
    this.lead = M7RqLead.ok,
    this.badLeadIsBody = true,
    this.neutralLeft = true,
    this.dtrReady = false,
    this.line = M7RqLine.clear,
    this.lineLive = false,
    this.helmetIn = true,
    this.crate = 0,
    this.pillarOn = false,
    this.crewWorking = false,
  });

  /// Which man stands there (his shirt): 0 today's helper, 1 a second helper,
  /// 2 a fit lineman brought in after a question.
  final int helperPerson;

  /// The helper is up the pole (his order carried out). Only for the rest of
  /// that order: every new order starts with the lane back in its shutdown
  /// state (him at the pole's foot, nothing charged), so no charge is ever
  /// shown with a man up (M5-1 / X7). His tap area stays at the foot, where
  /// he always is while an order is decided.
  final bool helperUp;

  final M7RqPlate plate;

  /// The plate's side on the door (or on the ground).
  final bool plateRight;

  final M7RqLead lead;

  /// Which lead is cut or hanging (the body earth, else the neutral earth).
  final bool badLeadIsBody;

  /// The neutral lead runs down the left side (else the right).
  final bool neutralLeft;

  /// The DTR was readied for charging: the shutdown tag and padlock are off,
  /// the AB stays open and nothing glows. Never charged in 7.1 (charging with
  /// a broken earth is deadly, M6-1; 7.1 is slips only, M7-6).
  final bool dtrReady;

  final M7RqLine line;

  /// The service line was kept on (sparks where it rests).
  final bool lineLive;

  /// A helmet in the crate and one on the hook (else both empty).
  final bool helmetIn;

  /// The crate's other contents (a dealt mix: 0–2).
  final int crate;

  /// The pillar was charged.
  final bool pillarOn;

  /// The crew went to work from the van (the kit order carried out).
  final bool crewWorking;

  M7RqLook copyWith({
    int? helperPerson,
    bool? helperUp,
    M7RqPlate? plate,
    M7RqLead? lead,
    bool? badLeadIsBody,
    bool? dtrReady,
    M7RqLine? line,
    bool? lineLive,
    bool? helmetIn,
    bool? pillarOn,
    bool? crewWorking,
  }) =>
      M7RqLook(
        helperPerson: helperPerson ?? this.helperPerson,
        helperUp: helperUp ?? this.helperUp,
        plate: plate ?? this.plate,
        plateRight: plateRight,
        lead: lead ?? this.lead,
        badLeadIsBody: badLeadIsBody ?? this.badLeadIsBody,
        neutralLeft: neutralLeft,
        dtrReady: dtrReady ?? this.dtrReady,
        line: line ?? this.line,
        lineLive: lineLive ?? this.lineLive,
        helmetIn: helmetIn ?? this.helmetIn,
        crate: crate,
        pillarOn: pillarOn ?? this.pillarOn,
        crewWorking: crewWorking ?? this.crewWorking,
      );

  @override
  bool operator ==(Object other) =>
      other is M7RqLook &&
      other.helperPerson == helperPerson &&
      other.helperUp == helperUp &&
      other.plate == plate &&
      other.plateRight == plateRight &&
      other.lead == lead &&
      other.badLeadIsBody == badLeadIsBody &&
      other.neutralLeft == neutralLeft &&
      other.dtrReady == dtrReady &&
      other.line == line &&
      other.lineLive == lineLive &&
      other.helmetIn == helmetIn &&
      other.crate == crate &&
      other.pillarOn == pillarOn &&
      other.crewWorking == crewWorking;

  @override
  int get hashCode => Object.hash(helperPerson, helperUp, plate, plateRight, lead, badLeadIsBody, neutralLeft, dtrReady, line, lineLive, helmetIn,
      crate, pillarOn, crewWorking);
}

/// Where things are (design px, 360 wide). Lane units: a 360 × 470 box.
@immutable
class M7RqGeo {
  const M7RqGeo._(this.height, this.floorY, this.k);

  factory M7RqGeo.forScene(double height, double inset) {
    final floor = height - floorUp - inset;
    final k = ((floor - top) / laneH).clamp(0.45, 1.0);
    return M7RqGeo._(height, floor, k);
  }

  final double height;

  /// The lane's bottom edge (the front road line), above the controls.
  final double floorY;

  /// Lane units → design px.
  final double k;

  /// The floor sits this far above the bottom (the phone, the decision row
  /// and the guide stand under it).
  static const double floorUp = 200;

  /// The highest the lane may reach (under the header).
  static const double top = 128;

  static const double laneW = 360;
  static const double laneH = 470;

  /// The lane box's left and top edges in design px.
  double get ox => (360 - laneW * k) / 2;
  double get oy => floorY - laneH * k;

  Offset map(Offset p) => Offset(ox + p.dx * k, oy + p.dy * k);
  Rect mapRect(Rect r) => Rect.fromPoints(map(r.topLeft), map(r.bottomRight));

  /// Where each object is touched (lane units).
  static const Map<M7RqKind, Rect> laneHits = {
    M7RqKind.earth: Rect.fromLTRB(4, 262, 116, 410),
    M7RqKind.pillar: Rect.fromLTRB(120, 316, 192, 410),
    M7RqKind.balcony: Rect.fromLTRB(238, 110, 300, 262),
    M7RqKind.kit: Rect.fromLTRB(52, 414, 128, 470),
    M7RqKind.helper: Rect.fromLTRB(194, 368, 234, 470),
  };

  /// What a close-up shows (lane units; the helper's card is a widget).
  static const Map<M7RqKind, Rect> zooms = {
    M7RqKind.earth: Rect.fromLTRB(2, 252, 122, 414),
    M7RqKind.pillar: Rect.fromLTRB(110, 314, 212, 414),
    M7RqKind.balcony: Rect.fromLTRB(214, 104, 300, 270),
    M7RqKind.kit: Rect.fromLTRB(40, 402, 132, 470),
  };

  Rect hit(M7RqKind kind) => mapRect(laneHits[kind]!);

  /// The object under [p] (design px), or null.
  M7RqKind? kindAt(Offset p) {
    for (final e in laneHits.entries) {
      if (mapRect(e.value).contains(p)) return e.key;
    }
    return null;
  }

  @override
  bool operator ==(Object other) => other is M7RqGeo && other.height == height && other.floorY == floorY;

  @override
  int get hashCode => Object.hash(height, floorY);
}

/// The lane: the whole scene ([zoom] null) or a close-up of [zoom] (lane
/// units) filling the canvas.
class M7RqLanePainter extends CustomPainter {
  const M7RqLanePainter({required this.look, this.geo, this.zoom});

  final M7RqLook look;
  final M7RqGeo? geo;
  final Rect? zoom;

  @override
  void paint(Canvas c, Size size) {
    final z = zoom;
    final g = geo;
    if (z != null) {
      final s = math.max(size.width / z.width, size.height / z.height);
      c.save();
      c.clipRect(Offset.zero & size);
      c.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFCFE3F0));
      c.translate((size.width - z.width * s) / 2 - z.left * s, (size.height - z.height * s) / 2 - z.top * s);
      c.scale(s);
      _ground(c, const Rect.fromLTRB(-400, -200, 760, 700));
      _lane(c);
      c.restore();
      return;
    }
    if (g == null) return;
    _sky(c, size, g);
    c.save();
    c.translate(g.ox, g.oy);
    c.scale(g.k);
    // The ground reaches the scene's edges (a narrow lane leaves margins).
    _ground(c, Rect.fromLTRB(-g.ox / g.k - 2, 0, (360 - g.ox) / g.k + 2, (size.height - g.oy) / g.k + 2));
    _far(c, -g.ox / g.k - 2, (360 - g.ox) / g.k + 2);
    _lane(c);
    c.restore();
  }

  // --- the backdrop ------------------------------------------------------------
  void _sky(Canvas c, Size size, M7RqGeo g) {
    final r = Offset.zero & size;
    c.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6FA8D6), Color(0xFFB9D8EC), Color(0xFFF4E3C2)],
          stops: [0, 0.55, 1],
        ).createShader(r),
    );
    // The morning sun, low on the left.
    final sun = Offset(54, g.oy + 60 * g.k);
    c.drawCircle(sun, 34, Paint()..color = const Color(0x33FFE7A8));
    c.drawCircle(sun, 18, Paint()..color = const Color(0xFFFFF0C4));
  }

  void _far(Canvas c, double left, double right) {
    final p = Paint()..color = const Color(0xFF9DB3C4);
    final path = Path()..moveTo(left, 410);
    var x = left;
    var i = 0;
    while (x < right) {
      final w = 34.0 + (i * 13) % 22;
      final h = 60.0 + (i * 29) % 70;
      path
        ..lineTo(x, 410 - h)
        ..lineTo(x + w, 410 - h);
      x += w;
      i++;
    }
    path
      ..lineTo(right, 410)
      ..close();
    c.drawPath(path, p);
  }

  void _ground(Canvas c, Rect r) {
    // Back verge, the lane's road, the front kerb.
    final back = Rect.fromLTRB(r.left, 404, r.right, 420);
    c.drawRect(back, Paint()..color = const Color(0xFF8E9A6A));
    final road = Rect.fromLTRB(r.left, 418, r.right, math.max(r.bottom, 480));
    c.drawRect(
      road,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8C8478), Color(0xFF6E675E)],
        ).createShader(road),
    );
    final dash = Paint()
      ..color = const Color(0x55FFFFFF)
      ..strokeWidth = 2;
    for (var x = r.left - (r.left % 40); x < r.right; x += 40) {
      c.drawLine(Offset(x, 474), Offset(x + 18, 474), dash);
    }
  }

  // --- the lane ------------------------------------------------------------------
  void _lane(Canvas c) {
    _house(c);
    _pole(c);
    _serviceLine(c);
    _dtr(c);
    _pillar(c);
    _van(c);
    _helper(c);
  }

  void _house(Canvas c) {
    final wall = const Rect.fromLTRB(270, 140, 372, 410);
    c.drawRect(
      wall,
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFFF1E4C8), Color(0xFFE0CFA8)]).createShader(wall),
    );
    c.drawRect(const Rect.fromLTRB(264, 132, 376, 142), Paint()..color = const Color(0xFFB9A88A));
    final win = Paint()..color = const Color(0xFF5E7C94);
    c.drawRect(const Rect.fromLTRB(296, 290, 330, 330), win);
    c.drawRect(const Rect.fromLTRB(300, 170, 334, 206), win);
    c.drawRect(const Rect.fromLTRB(288, 350, 318, 410), Paint()..color = const Color(0xFF7A5634));
    // The new balcony (fresh paint) reaching out toward the line.
    c.drawRect(const Rect.fromLTRB(240, 250, 272, 257), Paint()..color = const Color(0xFFE6E2DA));
    final rail = Paint()
      ..color = const Color(0xFF3F6E8C)
      ..strokeWidth = 2;
    c.drawLine(const Offset(240, 228), const Offset(272, 228), rail..strokeWidth = 3);
    rail.strokeWidth = 1.6;
    for (var x = 242.0; x <= 270; x += 5) {
      c.drawLine(Offset(x, 228), Offset(x, 250), rail);
    }
    // The bracket on the wall where the service line ends.
    c.drawCircle(const Offset(272, 200), 2.6, Paint()..color = const Color(0xFF3A3A3A));
  }

  void _pole(Canvas c) {
    final pole = const Rect.fromLTRB(232, 100, 240, 410);
    c.drawRect(
      pole,
      Paint()..shader = const LinearGradient(colors: [Color(0xFF9AA0A6), Color(0xFF5E646A)]).createShader(pole),
    );
    c.drawRect(const Rect.fromLTRB(212, 116, 262, 121), Paint()..color = const Color(0xFF4A4F55));
    final ins = Paint()..color = const Color(0xFFF2F2EE);
    for (final x in [218.0, 236.0, 256.0]) {
      c.drawRect(Rect.fromLTWH(x - 2.5, 108, 5, 9), ins);
    }
    // The LT line runs off along the lane.
    final wire = Paint()
      ..color = const Color(0xFF2A2A2A)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (final x in [218.0, 236.0, 256.0]) {
      c.drawPath(
          Path()
            ..moveTo(-300, 128)
            ..quadraticBezierTo((x - 300) / 2, 150, x, 110),
          wire);
    }
  }

  void _serviceLine(Canvas c) {
    final wire = Paint()
      ..color = const Color(0xFF1E1E1E)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(236, 112);
    if (look.line == M7RqLine.clear) {
      path.quadraticBezierTo(254, 160, 272, 200);
    } else {
      // Sagged onto the new railing, then up to the bracket.
      path
        ..quadraticBezierTo(244, 190, 256, 227)
        ..quadraticBezierTo(264, 214, 272, 200);
    }
    c.drawPath(path, wire);
    if (look.line == M7RqLine.resting && look.lineLive) {
      final spark = Paint()
        ..color = const Color(0xFFFFC23A)
        ..strokeWidth = 1.4;
      const o = Offset(256, 227);
      c.drawCircle(o, 7, Paint()..color = const Color(0x66FFB300));
      for (var i = 0; i < 6; i++) {
        final a = i * math.pi / 3 + 0.3;
        c.drawLine(o, o + Offset(math.cos(a), math.sin(a)) * 9, spark);
      }
    }
  }

  void _dtr(Canvas c) {
    // The AB switch on its pole stub, the handle locked and tagged.
    final stub = const Rect.fromLTRB(8, 140, 15, 410);
    c.drawRect(stub, Paint()..color = const Color(0xFF6E747A));
    c.drawRect(const Rect.fromLTRB(4, 156, 104, 161), Paint()..color = const Color(0xFF4A4F55));
    final ins = Paint()..color = const Color(0xFFEDEDE6);
    final blade = Paint()
      ..color = const Color(0xFFB8BEC4)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (final x in [34.0, 58.0, 82.0]) {
      c.drawRect(Rect.fromLTWH(x - 9, 148, 4, 9), ins);
      c.drawRect(Rect.fromLTWH(x + 5, 148, 4, 9), ins);
      // Open, always (nothing is charged in 7.1).
      c.drawLine(Offset(x - 7, 147), Offset(x - 1, 133), blade);
    }
    // The HG fuses on the lower arm.
    c.drawRect(const Rect.fromLTRB(16, 202, 100, 206), Paint()..color = const Color(0xFF4A4F55));
    final horn = Paint()
      ..color = const Color(0xFF8A9096)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final drop = Paint()
      ..color = const Color(0xFF2A2A2A)
      ..strokeWidth = 1.1;
    for (final x in [34.0, 58.0, 82.0]) {
      c.drawRect(Rect.fromLTWH(x - 2.5, 194, 5, 8), ins);
      c.drawLine(Offset(x - 1, 194), Offset(x - 6, 184), horn);
      c.drawLine(Offset(x + 1, 194), Offset(x + 6, 184), horn);
      c.drawLine(Offset(x, 157), Offset(x, 194), drop);
      c.drawLine(Offset(x, 206), Offset(x + (x - 58) * 0.2 + 2, 270), drop);
    }
    // The operating handle with a padlock and a red tag (shutdown; both off
    // once readied).
    c.drawRect(const Rect.fromLTRB(15, 340, 25, 346), Paint()..color = const Color(0xFF3A3E43));
    if (!look.dtrReady) {
      c.drawRect(const Rect.fromLTRB(17, 347, 23, 354), Paint()..color = const Color(0xFFC9A227));
      c.drawRect(const Rect.fromLTRB(16, 356, 26, 370), Paint()..color = const Color(0xFFC0392B));
    }
    // The tank on its plinth.
    final tank = const Rect.fromLTRB(30, 272, 96, 360);
    c.drawRRect(
      RRect.fromRectAndRadius(tank, const Radius.circular(4)),
      Paint()..shader = const LinearGradient(colors: [Color(0xFF7C9284), Color(0xFF55695C)]).createShader(tank),
    );
    final fin = Paint()
      ..color = const Color(0x553A4A40)
      ..strokeWidth = 2;
    for (var x = 38.0; x < 92; x += 7) {
      c.drawLine(Offset(x, 282), Offset(x, 352), fin);
    }
    for (final x in [44.0, 62.0, 80.0]) {
      c.drawRect(Rect.fromLTWH(x - 3, 262, 6, 11), Paint()..color = const Color(0xFF9A6B4A));
    }
    // LT bushings (neutral at the end the neutral lead leaves from).
    final nx = look.neutralLeft ? 34.0 : 92.0;
    c.drawRect(Rect.fromLTWH(nx - 3, 266, 6, 7), Paint()..color = const Color(0xFFEDEDE6));
    final plinth = const Rect.fromLTRB(20, 360, 106, 400);
    c.drawRect(plinth, Paint()..color = const Color(0xFFB4ADA0));
    c.drawRect(const Rect.fromLTRB(20, 360, 106, 364), Paint()..color = const Color(0xFFCAC3B6));
    // The two earth pits and their leads.
    final pitL = const Offset(26, 405);
    final pitR = const Offset(100, 405);
    for (final p in [pitL, pitR]) {
      c.drawRect(Rect.fromCenter(center: p, width: 18, height: 8), Paint()..color = const Color(0xFF8C877E));
      c.drawCircle(p.translate(0, -1), 2, Paint()..color = const Color(0xFF4A4A4A));
    }
    final neutralTop = Offset(nx, 270);
    final bodyTop = look.neutralLeft ? const Offset(96, 350) : const Offset(30, 350);
    final neutralPit = look.neutralLeft ? pitL : pitR;
    final bodyPit = look.neutralLeft ? pitR : pitL;
    _lead(c, neutralTop, neutralPit, bad: look.lead != M7RqLead.ok && !look.badLeadIsBody);
    _lead(c, bodyTop, bodyPit, bad: look.lead != M7RqLead.ok && look.badLeadIsBody);
  }

  void _lead(Canvas c, Offset from, Offset pit, {required bool bad}) {
    final p = Paint()
      ..color = const Color(0xFFB87333)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final side = from.dx < 63 ? -1.0 : 1.0;
    final elbow = Offset(pit.dx + side * 0, from.dy + 6);
    final out = Offset(from.dx + side * 6, from.dy + 4);
    final top = pit.translate(0, -2);
    if (!bad || look.lead == M7RqLead.ok) {
      c.drawPath(
          Path()
            ..moveTo(from.dx, from.dy)
            ..lineTo(out.dx, out.dy)
            ..lineTo(elbow.dx, elbow.dy)
            ..lineTo(top.dx, top.dy),
          p);
      return;
    }
    if (look.lead == M7RqLead.cut) {
      // Cut in the middle of its run down the plinth: two frayed ends.
      final midA = Offset(pit.dx, (elbow.dy + top.dy) / 2 - 8);
      final midB = Offset(pit.dx, (elbow.dy + top.dy) / 2 + 8);
      c.drawPath(
          Path()
            ..moveTo(from.dx, from.dy)
            ..lineTo(out.dx, out.dy)
            ..lineTo(elbow.dx, elbow.dy)
            ..lineTo(midA.dx, midA.dy),
          p);
      c.drawLine(midB, top, p);
      final fray = Paint()
        ..color = const Color(0xFFD08A4A)
        ..strokeWidth = 1;
      for (final d in [-3.0, 0.0, 3.0]) {
        c.drawLine(midA, midA + Offset(d, 4), fray);
        c.drawLine(midB, midB + Offset(d, -4), fray);
      }
      return;
    }
    // Hanging: the lower end off its pit clamp, curled in the air.
    final end = Offset(pit.dx + side * 10, pit.dy - 18);
    c.drawPath(
        Path()
          ..moveTo(from.dx, from.dy)
          ..lineTo(out.dx, out.dy)
          ..lineTo(elbow.dx, elbow.dy)
          ..quadraticBezierTo(pit.dx, end.dy - 4, end.dx, end.dy),
        p);
  }

  void _pillar(Canvas c) {
    final body = const Rect.fromLTRB(126, 326, 172, 404);
    c.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(3)),
      Paint()..shader = const LinearGradient(colors: [Color(0xFFA9B1B8), Color(0xFF79828A)]).createShader(body),
    );
    c.drawRect(const Rect.fromLTRB(122, 320, 176, 328), Paint()..color = const Color(0xFF6A737B));
    final door = const Rect.fromLTRB(130, 332, 168, 400);
    c.drawRect(
        door,
        Paint()
          ..color = const Color(0xFF5C656D)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
    c.drawRect(const Rect.fromLTRB(162, 362, 165, 372), Paint()..color = const Color(0xFF3A3E43));
    final plateRect = look.plateRight ? const Rect.fromLTRB(149, 338, 166, 358) : const Rect.fromLTRB(132, 338, 149, 358);
    switch (look.plate) {
      case M7RqPlate.fixed:
        _dangerPlate(c, plateRect);
        for (final o in [plateRect.topLeft.translate(2, 2), plateRect.topRight.translate(-2, 2)]) {
          c.drawCircle(o, 0.9, Paint()..color = const Color(0xFF555555));
        }
      case M7RqPlate.bare:
      case M7RqPlate.ground:
        // The screw holes where the plate should be.
        for (final o in [plateRect.topLeft.translate(2, 2), plateRect.topRight.translate(-2, 2)]) {
          c.drawCircle(o, 1.1, Paint()..color = const Color(0xFF2E2E2E));
        }
        if (look.plate == M7RqPlate.ground) {
          // Against the pillar's foot (inside its tap area, never the earth's).
          final x = look.plateRight ? 176.0 : 128.0;
          c.save();
          c.translate(x, 404);
          c.rotate(look.plateRight ? 0.5 : -0.5);
          _dangerPlate(c, const Rect.fromLTRB(-8, -18, 9, 2));
          c.restore();
        }
    }
    if (look.pillarOn) {
      c.drawCircle(const Offset(149, 366), 26, Paint()..color = const Color(0x26FFB300));
    }
  }

  /// The danger plate: white, red border, a skull and the two words.
  void _dangerPlate(Canvas c, Rect r) {
    c.drawRect(r, Paint()..color = const Color(0xFFFDFDF8));
    c.drawRect(
        r.deflate(0.8),
        Paint()
          ..color = const Color(0xFFC62828)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
    final skull = Offset(r.center.dx, r.top + r.height * 0.36);
    c.drawCircle(skull, r.width * 0.16, Paint()..color = const Color(0xFFC62828));
    c.drawCircle(skull.translate(-r.width * 0.06, 0), r.width * 0.04, Paint()..color = const Color(0xFFFDFDF8));
    c.drawCircle(skull.translate(r.width * 0.06, 0), r.width * 0.04, Paint()..color = const Color(0xFFFDFDF8));
    final tp = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(text: 'বিপদ\n', style: TextStyle(fontSize: r.height * 0.2, fontWeight: FontWeight.w900, color: const Color(0xFFC62828), height: 1)),
          TextSpan(text: 'DANGER', style: TextStyle(fontSize: r.height * 0.14, fontWeight: FontWeight.w900, color: const Color(0xFFC62828), height: 1)),
        ],
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: r.width * 1.4);
    c.save();
    c.translate(r.center.dx - tp.width / 2, r.top + r.height * 0.55);
    tp.paint(c, Offset.zero);
    c.restore();
  }

  void _van(Canvas c) {
    final body = const Rect.fromLTRB(4, 418, 124, 460);
    c.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(5)),
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF2F4F6), Color(0xFFC6CCD2)]).createShader(body),
    );
    c.drawRect(const Rect.fromLTRB(4, 438, 124, 442), Paint()..color = const Color(0xFF2F6FA8));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTRB(8, 422, 34, 436), const Radius.circular(3)), Paint()..color = const Color(0xFF6E8CA6));
    for (final x in [26.0, 100.0]) {
      c.drawCircle(Offset(x, 462), 8, Paint()..color = const Color(0xFF222222));
      c.drawCircle(Offset(x, 462), 3.4, Paint()..color = const Color(0xFF8A8A8A));
    }
    // The helmet hook on the side.
    final hook = Paint()
      ..color = const Color(0xFF3A3E43)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    c.drawPath(
        Path()
          ..moveTo(62, 422)
          ..lineTo(62, 428)
          ..quadraticBezierTo(62, 432, 66, 431),
        hook);
    if (look.helmetIn && !look.crewWorking) _helmet(c, const Offset(62, 434), 7);
    // The open rear: the kit crate.
    final crate = const Rect.fromLTRB(80, 421, 122, 446);
    c.drawRect(crate, Paint()..color = const Color(0xFF3A2E22));
    c.drawRect(crate.deflate(2), Paint()..color = const Color(0xFF8B6A44));
    final items = Paint()..style = PaintingStyle.fill;
    // Dealt other contents: a rope coil, a gloves pouch, a tester.
    if (look.crate != 1) {
      c.drawCircle(const Offset(88, 437), 5, items..color = const Color(0xFFB08A50));
      c.drawCircle(const Offset(88, 437), 2.4, items..color = const Color(0xFF8B6A44));
    }
    if (look.crate != 2) c.drawRect(const Rect.fromLTRB(96, 431, 104, 443), items..color = const Color(0xFFE07B22));
    c.drawRect(const Rect.fromLTRB(106, 428, 109, 444), items..color = const Color(0xFFE8C21C));
    if (look.helmetIn && !look.crewWorking) _helmet(c, const Offset(115, 437), 6.5);
  }

  void _helmet(Canvas c, Offset at, double r) {
    final dome = Rect.fromCircle(center: at, radius: r);
    c.drawArc(dome, math.pi, math.pi, true, Paint()..color = const Color(0xFFF2C21B));
    c.drawRect(Rect.fromLTRB(at.dx - r - 1.5, at.dy - 0.5, at.dx + r + 1.5, at.dy + 1.5), Paint()..color = const Color(0xFFD9A812));
  }

  void _helper(Canvas c) {
    final shirt = switch (look.helperPerson) {
      0 => const Color(0xFF3E7CB1),
      1 => const Color(0xFF7E5BA6),
      _ => const Color(0xFF2E8B57),
    };
    // On the pole (the order carried out) or standing by its foot.
    final base = look.helperUp ? const Offset(226, 290) : const Offset(214, 468);
    final s = look.helperUp ? 0.8 : 1.0;
    c.save();
    c.translate(base.dx, base.dy);
    c.scale(s);
    final skin = Paint()..color = const Color(0xFF9A6A48);
    final legs = Paint()..color = const Color(0xFF2E3440);
    c.drawRect(const Rect.fromLTRB(-7, -38, -1, 0), legs);
    c.drawRect(const Rect.fromLTRB(1, -38, 7, 0), legs);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTRB(-10, -74, 10, -36), const Radius.circular(4)), Paint()..color = shirt);
    c.drawRect(const Rect.fromLTRB(-14, -72, -9, -46), Paint()..color = shirt);
    c.drawRect(const Rect.fromLTRB(9, -72, 14, -46), Paint()..color = shirt);
    c.drawCircle(const Offset(0, -84), 9, skin);
    c.drawArc(const Rect.fromLTRB(-9, -94, 9, -78), math.pi, math.pi, true, Paint()..color = const Color(0xFF1E1E1E));
    // The ID card on its lanyard.
    final lan = Paint()
      ..color = const Color(0xFFC0392B)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    c.drawPath(
        Path()
          ..moveTo(-5, -74)
          ..lineTo(0, -60)
          ..lineTo(5, -74),
        lan);
    c.drawRect(const Rect.fromLTRB(-4, -60, 4, -50), Paint()..color = const Color(0xFFFDFDF8));
    c.drawRect(const Rect.fromLTRB(-4, -60, 4, -57), Paint()..color = const Color(0xFF2F6FA8));
    c.restore();
  }

  @override
  bool shouldRepaint(M7RqLanePainter old) => old.look != look || old.geo != geo || old.zoom != zoom;
}

/// A soft flash over an object as its state changes (the fix plays).
class M7RqFlashPainter extends CustomPainter {
  const M7RqFlashPainter({required this.rect, required this.v});
  final Rect rect;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    if (v <= 0) return;
    c.drawRRect(
      RRect.fromRectAndRadius(rect.inflate(4), const Radius.circular(10)),
      Paint()..color = Color.fromRGBO(255, 255, 255, 0.55 * v),
    );
  }

  @override
  bool shouldRepaint(M7RqFlashPainter old) => old.v != v || old.rect != rect;
}
