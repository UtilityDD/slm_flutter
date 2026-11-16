import 'dart:math' as math;

import 'package:flutter/material.dart';

// The drawn world of lesson 6.9 কাজ 1 "তাপের চোখ" (m6_pillar_thermal.dart): a
// lane corner by a DTR, an LT feeder pillar (metal or polycarbonate) standing
// open for preventive maintenance. Inside (lesson 6.9 point 2): the R, Y, B
// busbars across the top, the incomer column at one side (its R, Y, B cable
// lugs on risers to the bars, its neutral on the link), 3–5 outgoing ways —
// each three HRC fuse carriers (R, Y, B) with a busbar-side joint above and a
// cable-lug joint below, the armoured cables going down out of the gland
// plate — the common neutral link with every way's neutral bolt, and the
// earthing terminal. Everything looks alike to the eye; only a 'late'
// hotspot shows the lesson's own outward signs (point 3: a blackened joint
// and a wisp of burnt smell).
//
// Over the top floats the thermal camera's live screen (an inset): a
// false-colour picture of only what is under the camera's aim frame — the
// column of the way it points at, its joints as warm blobs. Loose joints run
// hot (red or white, the lesson's image note); the rest show dull, uneven
// warm tones (load varies from way to way and joint to joint), so only a
// joint's sisters on the same way tell a hotspot.
//
// No text in the art except labels a worker reads (way numbers, R/Y/B/N on
// the bars). Code-drawn, gradients, no bitmaps. Design: 360 wide × the
// scene's height; a tall phone gets a taller pillar, never stretched.

/// A joint's place on its way. Outgoing ways use all seven; the incomer
/// column uses the three cable lugs and its neutral.
enum M6Slot { busR, busY, busB, lugR, lugY, lugB, n }

/// The phases written on the job card (and on the bars).
enum M6Phase { r, y, b, n }

M6Phase m6SlotPhase(M6Slot s) => switch (s) {
      M6Slot.busR || M6Slot.lugR => M6Phase.r,
      M6Slot.busY || M6Slot.lugY => M6Phase.y,
      M6Slot.busB || M6Slot.lugB => M6Phase.b,
      M6Slot.n => M6Phase.n,
    };

/// The joints a column has (unit 0 = the incomer).
List<M6Slot> m6SlotsOf(int unit) => unit == 0 ? const [M6Slot.lugR, M6Slot.lugY, M6Slot.lugB, M6Slot.n] : M6Slot.values;

/// The thermal camera's false-colour palette ("iron"): 0 cold → 1 white hot.
Color m6ThermalColor(double t) {
  const stops = <double>[0, 0.22, 0.42, 0.6, 0.78, 1];
  const colors = <Color>[
    Color(0xFF120E3A),
    Color(0xFF4A1A82),
    Color(0xFFB02A74),
    Color(0xFFEE6A1E),
    Color(0xFFFFC93A),
    Color(0xFFFFFFF4),
  ];
  final x = t.clamp(0.0, 1.0);
  for (var i = 1; i < stops.length; i++) {
    if (x <= stops[i]) {
      final f = (x - stops[i - 1]) / (stops[i] - stops[i - 1]);
      return Color.lerp(colors[i - 1], colors[i], f)!;
    }
  }
  return colors.last;
}

/// Where things are (design px, 360 wide).
@immutable
class M6ThermalGeo {
  const M6ThermalGeo._(this.height, this.floorY, this.ways, this.mirror);

  factory M6ThermalGeo.forScene(double height, double inset, {required int ways, required bool mirror}) =>
      M6ThermalGeo._(height, height - floorUp - inset * 0.5, ways, mirror);

  final double height;
  final double floorY;

  /// Outgoing ways (3–5).
  final int ways;

  /// The incomer stands on the right (the pillar seen mirrored).
  final bool mirror;

  /// The floor sits this far above the bottom (the job card stands on it).
  static const double floorUp = 96;

  /// The camera's live screen (over the top of the scene, under the header).
  Rect get cam => Rect.fromLTWH(16, 134, 328, (0.19 * height).clamp(122.0, 160.0));

  /// The picture area inside the camera's bezel.
  Rect get screen => Rect.fromLTRB(cam.left + 12, cam.top + 10, cam.right - 12, cam.bottom - 10);

  /// The pillar box (its foot stands on the floor).
  Rect get pillar => Rect.fromLTRB(16, cam.bottom + 12, 344, floorY);

  /// The working face (busbars to the earth terminal). It stays clear of the
  /// corner guide and, on a tall phone, of his speech bubble (bottom right).
  Rect get work {
    final top = pillar.top + 12;
    final bottom = math.min(height >= 700 ? height - 246 : height - 190, top + 280);
    return Rect.fromLTRB(pillar.left + 10, top, pillar.right - 10, bottom);
  }

  /// A height on the working face (0 = top, 1 = foot).
  double y(double f) => work.top + f * work.height;

  static const double _incomerW = 50;
  static const double _earthW = 16;

  /// The ways' strip (from the incomer side outward).
  double get _waysStart => work.left + _incomerW + 4;
  double get _waysEnd => work.right - _earthW;

  /// One way's width.
  double get pitch => (_waysEnd - _waysStart) / ways;

  double _flip(double x) => mirror ? 360 - x : x;

  /// The centre of column [unit] (0 = the incomer, 1… = F1… outward).
  double unitX(int unit) => _flip(unit == 0 ? work.left + _incomerW / 2 : _waysStart + pitch * (unit - 0.5));

  /// How near the frame's centre must be to a column to see it whole.
  double unitReach(int unit) => unit == 0 ? 14 : (pitch * 0.3).clamp(12.0, 26.0);

  /// The column under the frame centred at [fx], or null between columns.
  int? unitAt(double fx) {
    for (var u = 0; u <= ways; u++) {
      if ((fx - unitX(u)).abs() <= unitReach(u)) return u;
    }
    return null;
  }

  /// The aim frame's width, and where its centre may go.
  double get frameW => (pitch * 0.9).clamp(42.0, 68.0);
  double get frameMinX => work.left + frameW / 2 - 6;
  double get frameMaxX => work.right - frameW / 2 + 6;

  /// The frame starts between the two middle-most columns (it sees nothing).
  double get frameStart {
    final k = ways ~/ 2;
    return (unitX(k) + unitX(k + 1)) / 2;
  }

  Rect frameAt(double fx) => Rect.fromLTRB(fx - frameW / 2, y(0.2), fx + frameW / 2, y(0.86));

  /// Where a drag on the pillar moves the camera.
  Rect get dragHit => Rect.fromLTRB(pillar.left, work.top, pillar.right, work.bottom);

  // Rows on the working face.
  static const double rowBarR = 0.06, rowBarY = 0.12, rowBarB = 0.18;
  static const double rowBus = 0.28, rowFuseTop = 0.3, rowFuseBottom = 0.5, rowLug = 0.54, rowLink = 0.76, rowEarth = 0.92;

  double _phaseDx(M6Phase p, int unit) {
    final i = switch (p) {
      M6Phase.r => -1,
      M6Phase.y => 0,
      M6Phase.b => 1,
      M6Phase.n => 0,
    };
    final dx = unit == 0 ? 14.0 * i : pitch * 0.27 * i;
    return mirror ? -dx : dx;
  }

  /// A joint on the pillar (the eye view).
  Offset joint(int unit, M6Slot s) {
    final x = unitX(unit);
    if (s == M6Slot.n) return Offset(x, y(rowLink));
    final p = m6SlotPhase(s);
    final bus = s == M6Slot.busR || s == M6Slot.busY || s == M6Slot.busB;
    return Offset(x + _phaseDx(p, unit), y(bus ? rowBus : rowLug));
  }

  /// The busbar row of a phase.
  double barY(M6Phase p) => y(switch (p) {
        M6Phase.r => rowBarR,
        M6Phase.y => rowBarY,
        M6Phase.b => rowBarB,
        M6Phase.n => rowLink,
      });

  /// A joint on the camera's live screen (the column under the frame).
  Offset camJoint(int unit, M6Slot s) {
    final r = screen;
    final p = m6SlotPhase(s);
    final fx = switch (p) {
      M6Phase.r => 0.2,
      M6Phase.y => 0.4,
      M6Phase.b => 0.6,
      M6Phase.n => 0.84,
    };
    final bus = s == M6Slot.busR || s == M6Slot.busY || s == M6Slot.busB;
    final fy = unit == 0 ? 0.6 : (bus ? 0.3 : 0.74);
    return Offset(r.left + fx * r.width, r.top + fy * r.height);
  }

  /// A joint's touch box on the live screen.
  Rect camJointHit(int unit, M6Slot s) => Rect.fromCenter(center: camJoint(unit, s), width: 48, height: 44);

  /// The job card (bottom left, on the floor row).
  Rect get jobCard => Rect.fromLTRB(8, floorY + 4, 246, math.max(floorY + 60, height - 6));

  /// The trainee with the camera (in front of the pillar's foot).
  Rect get trainee => Rect.fromLTWH(mirror ? 300 : 14, floorY - 100, 44, 100);

  @override
  bool operator ==(Object other) =>
      other is M6ThermalGeo && other.height == height && other.floorY == floorY && other.ways == ways && other.mirror == mirror;

  @override
  int get hashCode => Object.hash(height, floorY, ways, mirror);
}

/// What the pillar shows to the eye.
@immutable
class M6PillarLook {
  const M6PillarLook({required this.metal, this.late = const [], this.missed = const [], this.tagged = const []});

  /// Metal (grey steel) or polycarbonate (pale) body.
  final bool metal;

  /// Joints that run hot long enough to show (blackened, a smell wisp).
  final List<(int, M6Slot)> late;

  /// Hotspots left behind once the scan ended (shown with a red ring).
  final List<(int, M6Slot)> missed;

  /// Hotspots on the job card (a paper tag on the joint).
  final List<(int, M6Slot)> tagged;

  @override
  bool operator ==(Object other) =>
      other is M6PillarLook &&
      other.metal == metal &&
      _same(other.late, late) &&
      _same(other.missed, missed) &&
      _same(other.tagged, tagged);

  static bool _same(List<(int, M6Slot)> a, List<(int, M6Slot)> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(metal, Object.hashAll(late), Object.hashAll(missed), Object.hashAll(tagged));
}

/// The lane, the DTR pole behind, and the open pillar (the eye view).
class M6PillarPainter extends CustomPainter {
  const M6PillarPainter({required this.geo, required this.look});
  final M6ThermalGeo geo;
  final M6PillarLook look;

  @override
  void paint(Canvas c, Size size) {
    final h = geo.height;
    // Sky and the lane wall.
    c.drawRect(
      Rect.fromLTWH(0, 0, 360, h),
      Paint()
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF7FB2DA), Color(0xFFCFE2EE)])
            .createShader(Rect.fromLTWH(0, 0, 360, h * 0.5)),
    );
    final wallTop = geo.cam.bottom - 30;
    c.drawRect(
      Rect.fromLTRB(0, wallTop, 360, geo.floorY),
      Paint()
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFD8C7A6), Color(0xFFBFA982)])
            .createShader(Rect.fromLTRB(0, wallTop, 360, geo.floorY)),
    );
    final brick = Paint()
      ..color = const Color(0x22000000)
      ..strokeWidth = 1;
    for (var yy = wallTop + 14; yy < geo.floorY; yy += 14) {
      c.drawLine(Offset(0, yy), Offset(360, yy), brick);
    }
    // The DTR pole at the far side, behind the pillar.
    final poleX = geo.mirror ? 22.0 : 338.0;
    c.drawRect(Rect.fromLTRB(poleX - 6, 0, poleX + 6, geo.floorY), Paint()..color = const Color(0xFF8E9298));
    c.drawRect(Rect.fromLTRB(poleX - 6, 0, poleX - 2, geo.floorY), Paint()..color = const Color(0x33FFFFFF));
    // The lane.
    c.drawRect(
      Rect.fromLTRB(0, geo.floorY, 360, h),
      Paint()
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8A8478), Color(0xFF5E5A52)])
            .createShader(Rect.fromLTRB(0, geo.floorY, 360, h)),
    );
    _pillar(c);
  }

  void _pillar(Canvas c) {
    final p = geo.pillar;
    final w = geo.work;
    final metal = look.metal;
    // Plinth and the box.
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(p.left - 6, p.bottom - 10, p.right + 6, p.bottom + 4), const Radius.circular(2)), Paint()..color = const Color(0xFF9C968A));
    c.drawRRect(
      RRect.fromRectAndRadius(p, const Radius.circular(5)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: metal ? const [Color(0xFFB9C1C8), Color(0xFF7C858E)] : const [Color(0xFFEDE8DA), Color(0xFFC9C2AE)],
        ).createShader(p),
    );
    // The roof lip.
    c.drawRect(Rect.fromLTRB(p.left - 5, p.top - 6, p.right + 5, p.top + 2), Paint()..color = metal ? const Color(0xFF6E7780) : const Color(0xFFB3AC97));
    // The inside (back plate).
    final back = Rect.fromLTRB(w.left - 4, w.top - 4, w.right + 4, p.bottom - 14);
    c.drawRect(
      back,
      Paint()
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3B434B), Color(0xFF262C32)]).createShader(back),
    );
    // Busbars across the top (R, Y, B), labelled at the incomer end.
    final barL = w.left + 2, barR = w.right - 18;
    for (final ph in [M6Phase.r, M6Phase.y, M6Phase.b]) {
      final yy = geo.barY(ph);
      final r = Rect.fromLTRB(geo.mirror ? 360 - barR : barL, yy - 2.6, geo.mirror ? 360 - barL : barR, yy + 2.6);
      c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(1.5)), _copper(r));
      _label(c, _phaseText(ph), Offset(geo.mirror ? r.right + 7 : r.left - 6, yy), 7);
    }
    // The neutral link.
    final linkY = geo.y(M6ThermalGeo.rowLink);
    final link = Rect.fromLTRB(geo.mirror ? 360 - barR : barL, linkY - 3, geo.mirror ? 360 - barL : barR, linkY + 3);
    c.drawRRect(RRect.fromRectAndRadius(link, const Radius.circular(1.5)), _copper(link));
    _label(c, 'N', Offset(geo.mirror ? link.right + 7 : link.left - 6, linkY - 9), 7);
    // The earthing terminal (far corner) and its bonding strap to the body.
    final ex = geo.mirror ? w.left + 8 : w.right - 8;
    final ey = geo.y(M6ThermalGeo.rowEarth);
    final earth = Rect.fromCenter(center: Offset(ex, ey), width: 12, height: 22);
    c.drawRRect(RRect.fromRectAndRadius(earth, const Radius.circular(2)), _copper(earth));
    _earthMark(c, Offset(ex, ey - 18));
    // The incomer column.
    _incomer(c);
    // The outgoing ways.
    for (var u = 1; u <= geo.ways; u++) {
      _way(c, u);
    }
    // The gland plate the cables leave through.
    c.drawRect(Rect.fromLTRB(back.left, p.bottom - 20, back.right, p.bottom - 14), Paint()..color = const Color(0xFF555D66));
    // The door, swung open against the far side.
    final doorX = geo.mirror ? p.left - 12 : p.right + 2;
    final door = Path()
      ..moveTo(doorX, p.top + 4)
      ..lineTo(doorX + 10, p.top - 4)
      ..lineTo(doorX + 10, p.bottom + 2)
      ..lineTo(doorX, p.bottom - 6)
      ..close();
    c.drawPath(door, Paint()..color = metal ? const Color(0xFF8F98A1) : const Color(0xFFD8D1BC));
    // Marks on the eye view: late signs, tags, missed hotspots.
    for (final (u, s) in look.late) {
      _lateSign(c, geo.joint(u, s));
    }
    for (final (u, s) in look.tagged) {
      _tag(c, geo.joint(u, s));
    }
    for (final (u, s) in look.missed) {
      final at = geo.joint(u, s);
      c.drawCircle(
          at,
          9,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4
            ..color = const Color(0xFFE53935));
    }
  }

  void _incomer(Canvas c) {
    final x = geo.unitX(0);
    final lugY = geo.y(M6ThermalGeo.rowLug);
    final bottom = geo.pillar.bottom - 16;
    // The incomer cable comes up from the gland plate.
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(x - 12, lugY + 14, x + 12, bottom), const Radius.circular(4)), Paint()..color = const Color(0xFF1B1E22));
    for (final s in const [M6Slot.lugR, M6Slot.lugY, M6Slot.lugB]) {
      final j = geo.joint(0, s);
      final barY = geo.barY(m6SlotPhase(s));
      // Riser from the lug up to its bar.
      c.drawRect(Rect.fromLTRB(j.dx - 1.6, barY, j.dx + 1.6, j.dy), _copper(Rect.fromLTRB(j.dx - 2, barY, j.dx + 2, j.dy)));
      c.drawCircle(Offset(j.dx, barY), 2.4, Paint()..color = const Color(0xFFB8BEC4));
      // Core down to the cable.
      c.drawLine(j, Offset(x, lugY + 16), Paint()
        ..color = const Color(0xFF2A2E33)
        ..strokeWidth = 3);
      _lug(c, j);
    }
    // Its neutral core up to the link.
    final nj = geo.joint(0, M6Slot.n);
    c.drawLine(Offset(x + (geo.mirror ? -8 : 8), lugY + 16), nj, Paint()
      ..color = const Color(0xFF2A2E33)
      ..strokeWidth = 3);
    _bolt(c, nj);
  }

  void _way(Canvas c, int u) {
    final x = geo.unitX(u);
    final fuseTop = geo.y(M6ThermalGeo.rowFuseTop), fuseBottom = geo.y(M6ThermalGeo.rowFuseBottom);
    final bottom = geo.pillar.bottom - 16;
    final cw = (geo.pitch * 0.18).clamp(5.0, 11.0);
    // The way's number above its fuses.
    _label(c, 'F$u', Offset(x, geo.y(0.235)), 7.5);
    // The armoured cable (one per way) down to the gland plate.
    final cableTop = geo.y(M6ThermalGeo.rowLug) + 18;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(x - cw * 0.8, cableTop, x + cw * 0.8, bottom), const Radius.circular(3)), Paint()..color = const Color(0xFF1B1E22));
    for (final s in const [M6Slot.busR, M6Slot.busY, M6Slot.busB]) {
      final bj = geo.joint(u, s);
      final barY = geo.barY(m6SlotPhase(s));
      // Link from the bar to the fuse base.
      c.drawRect(Rect.fromLTRB(bj.dx - 1.4, barY, bj.dx + 1.4, bj.dy), _copper(Rect.fromLTRB(bj.dx - 2, barY, bj.dx + 2, bj.dy)));
      c.drawCircle(Offset(bj.dx, barY), 2.2, Paint()..color = const Color(0xFFB8BEC4));
      // The HRC fuse carrier (ceramic body, black handle).
      final body = Rect.fromLTRB(bj.dx - cw / 2, fuseTop, bj.dx + cw / 2, fuseBottom);
      c.drawRRect(
        RRect.fromRectAndRadius(body, const Radius.circular(2)),
        Paint()
          ..shader = const LinearGradient(colors: [Color(0xFFF4F1EA), Color(0xFFCFC9BC)]).createShader(body),
      );
      c.drawRect(Rect.fromLTRB(body.left - 1, body.center.dy - 3, body.right + 1, body.center.dy + 3), Paint()..color = const Color(0xFF202326));
      _bolt(c, bj);
      // The lug side: the core from the fuse down into the cable.
      final lj = geo.joint(u, M6Slot.values[s.index + 3]);
      c.drawLine(lj, Offset(x, cableTop + 2), Paint()
        ..color = const Color(0xFF2A2E33)
        ..strokeWidth = 2.4);
      _lug(c, lj);
    }
    // Its neutral core up to the link.
    final nj = geo.joint(u, M6Slot.n);
    c.drawLine(Offset(x, cableTop + 2), nj, Paint()
      ..color = const Color(0xFF2A2E33)
      ..strokeWidth = 2.4);
    _bolt(c, nj);
  }

  Paint _copper(Rect r) => Paint()
    ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF0B07A), Color(0xFFB0683A)]).createShader(r);

  void _lug(Canvas c, Offset at) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: at, width: 6, height: 8), const Radius.circular(2)), Paint()..color = const Color(0xFFC9CDD2));
    c.drawCircle(at, 1.6, Paint()..color = const Color(0xFF6B7178));
  }

  void _bolt(Canvas c, Offset at) {
    c.drawCircle(at, 3, Paint()..color = const Color(0xFFC9CDD2));
    c.drawCircle(at, 1.4, Paint()..color = const Color(0xFF6B7178));
  }

  void _lateSign(Canvas c, Offset at) {
    // A blackened joint (lesson 6.9 point 3) and a wisp of burnt smell.
    c.drawCircle(
        at,
        7,
        Paint()
          ..shader = const RadialGradient(colors: [Color(0xFF15100C), Color(0xCC2A1A10), Color(0x002A1A10)]).createShader(Rect.fromCircle(center: at, radius: 7)));
    final wisp = Path()
      ..moveTo(at.dx, at.dy - 6)
      ..cubicTo(at.dx - 6, at.dy - 12, at.dx + 6, at.dy - 16, at.dx, at.dy - 22)
      ..cubicTo(at.dx - 5, at.dy - 27, at.dx + 4, at.dy - 30, at.dx + 1, at.dy - 34);
    c.drawPath(
        wisp,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..color = const Color(0x99D6D6D6));
  }

  void _tag(Canvas c, Offset at) {
    final r = Rect.fromLTWH(at.dx + 3, at.dy - 12, 9, 7);
    c.drawLine(at, r.centerLeft, Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 1);
    c.drawRect(r, Paint()..color = const Color(0xFFFFE07A));
  }

  void _earthMark(Canvas c, Offset at) {
    final p = Paint()
      ..color = const Color(0xFFE8E8E8)
      ..strokeWidth = 1.4;
    c.drawLine(at.translate(0, -5), at, p);
    c.drawLine(at.translate(-5, 0), at.translate(5, 0), p);
    c.drawLine(at.translate(-3, 2.5), at.translate(3, 2.5), p);
    c.drawLine(at.translate(-1.2, 5), at.translate(1.2, 5), p);
  }

  static String _phaseText(M6Phase p) => switch (p) {
        M6Phase.r => 'R',
        M6Phase.y => 'Y',
        M6Phase.b => 'B',
        M6Phase.n => 'N',
      };

  void _label(Canvas c, String text, Offset centre, double size) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, color: const Color(0xFFF2F2F2))),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(M6PillarPainter old) => old.geo != geo || old.look != look;
}

/// The camera's aim frame on the pillar (white corner brackets).
class M6AimFramePainter extends CustomPainter {
  const M6AimFramePainter({required this.rect, required this.on});
  final Rect rect;

  /// A whole column sits in the frame.
  final bool on;

  @override
  void paint(Canvas c, Size size) {
    final p = Paint()
      ..color = on ? const Color(0xFFFFFFFF) : const Color(0xCCFFFFFF)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const k = 10.0;
    final r = rect;
    for (final (o, dx, dy) in [(r.topLeft, 1.0, 1.0), (r.topRight, -1.0, 1.0), (r.bottomLeft, 1.0, -1.0), (r.bottomRight, -1.0, -1.0)]) {
      c.drawLine(o, o.translate(k * dx, 0), p);
      c.drawLine(o, o.translate(0, k * dy), p);
    }
    final m = r.center;
    final thin = Paint()
      ..color = const Color(0x99FFFFFF)
      ..strokeWidth = 1;
    c.drawLine(m.translate(-5, 0), m.translate(5, 0), thin);
    c.drawLine(m.translate(0, -5), m.translate(0, 5), thin);
  }

  @override
  bool shouldRepaint(M6AimFramePainter old) => old.rect != rect || old.on != on;
}

/// The camera's live screen: the column under the frame in false colour, or
/// the dull back plate when the frame sits between columns.
class M6ThermalScreenPainter extends CustomPainter {
  const M6ThermalScreenPainter({required this.geo, required this.unit, required this.tones, this.tagged = const {}});
  final M6ThermalGeo geo;

  /// The column in the frame, or null.
  final int? unit;

  /// That column's joint tones (by slot), 0…1.
  final Map<M6Slot, double> tones;

  /// Joints on the job card (the camera's tag marker).
  final Set<M6Slot> tagged;

  @override
  void paint(Canvas c, Size size) {
    final cam = geo.cam;
    // The camera body and bezel.
    c.drawRRect(
      RRect.fromRectAndRadius(cam, const Radius.circular(14)),
      Paint()
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3A3F46), Color(0xFF16191D)]).createShader(cam),
    );
    c.drawRRect(
        RRect.fromRectAndRadius(cam.deflate(1), const Radius.circular(13)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFFFFB300));
    final s = geo.screen;
    c.save();
    c.clipRRect(RRect.fromRectAndRadius(s, const Radius.circular(6)));
    c.drawRect(s, Paint()..color = m6ThermalColor(0.06));
    final u = unit;
    if (u == null) {
      // Between columns: the back plate, dull and even.
      c.drawRect(
        s,
        Paint()
          ..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [m6ThermalColor(0.1), m6ThermalColor(0.16), m6ThermalColor(0.08)])
              .createShader(s),
      );
    } else {
      _column(c, u, s);
    }
    c.restore();
    // The reticle in the middle and the colour scale at the side.
    final scale = Rect.fromLTWH(s.right - 7, s.top + 8, 4, s.height - 16);
    c.drawRect(
      scale,
      Paint()
        ..shader = LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [for (var i = 0; i <= 5; i++) m6ThermalColor(i / 5)])
            .createShader(scale),
    );
  }

  double _t(M6Slot s) => tones[s] ?? 0.2;

  void _column(Canvas c, int u, Rect s) {
    final slots = m6SlotsOf(u);
    final base = slots.map(_t).reduce(math.min);
    // Busbar stubs and fuse bodies, a shade under their joints.
    for (final sl in slots) {
      if (sl == M6Slot.n) continue;
      final at = geo.camJoint(u, sl);
      final ph = m6SlotPhase(sl);
      if (u == 0) {
        c.drawRect(Rect.fromLTRB(at.dx - 5, s.top, at.dx + 5, at.dy), Paint()..color = m6ThermalColor(math.min(_t(sl), base + 0.12) - 0.04));
        c.drawRect(Rect.fromLTRB(at.dx - 6, at.dy, at.dx + 6, s.bottom), Paint()..color = m6ThermalColor(base - 0.04));
        continue;
      }
      final bus = geo.camJoint(u, switch (ph) {
        M6Phase.r => M6Slot.busR,
        M6Phase.y => M6Slot.busY,
        _ => M6Slot.busB,
      });
      final lug = geo.camJoint(u, switch (ph) {
        M6Phase.r => M6Slot.lugR,
        M6Phase.y => M6Slot.lugY,
        _ => M6Slot.lugB,
      });
      if (sl == M6Slot.busR || sl == M6Slot.busY || sl == M6Slot.busB) {
        c.drawRect(Rect.fromLTRB(bus.dx - 4, s.top, bus.dx + 4, bus.dy), Paint()..color = m6ThermalColor(base - 0.03));
        final body = Rect.fromLTRB(bus.dx - 9, bus.dy + 8, bus.dx + 9, lug.dy - 8);
        c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(3)), Paint()..color = m6ThermalColor(base - 0.05));
      } else {
        c.drawRect(Rect.fromLTRB(lug.dx - 3, lug.dy, lug.dx + 3, s.bottom), Paint()..color = m6ThermalColor(base - 0.06));
      }
    }
    // The neutral link stub.
    final n = geo.camJoint(u, M6Slot.n);
    c.drawRect(Rect.fromLTRB(n.dx - 18, n.dy - 3, n.dx + 18, n.dy + 3), Paint()..color = m6ThermalColor(base - 0.08));
    c.drawRect(Rect.fromLTRB(n.dx - 3, n.dy, n.dx + 3, s.bottom), Paint()..color = m6ThermalColor(base - 0.08));
    // The joints: a warm blob each; a hot one heats what is round it.
    for (final sl in slots) {
      final at = geo.camJoint(u, sl);
      final t = _t(sl);
      final halo = 12 + 22 * ((t - base) * 2).clamp(0.0, 1.0);
      c.drawCircle(
          at,
          halo,
          Paint()
            ..shader = RadialGradient(colors: [m6ThermalColor(t - 0.1).withValues(alpha: 0.85), m6ThermalColor(base).withValues(alpha: 0)])
                .createShader(Rect.fromCircle(center: at, radius: halo)));
      c.drawCircle(
          at,
          9,
          Paint()
            ..shader = RadialGradient(colors: [m6ThermalColor(t), m6ThermalColor(t - 0.08)]).createShader(Rect.fromCircle(center: at, radius: 9)));
      if (tagged.contains(sl)) {
        final p = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = const Color(0xFFFFFFFF);
        c.drawRect(Rect.fromCenter(center: at, width: 30, height: 30), p);
      }
    }
  }

  @override
  bool shouldRepaint(M6ThermalScreenPainter old) =>
      old.geo != geo || old.unit != unit || !_sameTones(old.tones, tones) || !_sameSet(old.tagged, tagged);

  static bool _sameTones(Map<M6Slot, double> a, Map<M6Slot, double> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }

  static bool _sameSet(Set<M6Slot> a, Set<M6Slot> b) => a.length == b.length && a.containsAll(b);
}

/// The arc flash off a live joint (the deadly freeze), in colour.
class M6ThermalFlashPainter extends CustomPainter {
  const M6ThermalFlashPainter({required this.at, required this.v, this.water = false});
  final Offset at;
  final double v;

  /// Water on the joint: steam and spray burst with the flash.
  final bool water;

  @override
  void paint(Canvas c, Size size) {
    final flick = v < 0.5 ? (0.65 + 0.35 * math.sin(v * 60).abs()) : (1 - (v - 0.5) * 1.2).clamp(0.4, 1.0);
    final r = 30 + 80 * Curves.easeOut.transform(v.clamp(0.0, 1.0));
    c.drawCircle(
        at,
        r,
        Paint()
          ..shader = RadialGradient(colors: [Color.fromRGBO(255, 250, 225, 0.95 * flick), Color.fromRGBO(130, 165, 255, 0.5 * flick), const Color(0x00FFC24A)])
              .createShader(Rect.fromCircle(center: at, radius: r)));
    final spark = Paint()
      ..color = Color.fromRGBO(255, 214, 90, (1 - v).clamp(0.0, 1.0))
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 16; i++) {
      final a = i / 16 * math.pi * 2 + 0.2;
      final d0 = 10 + 56 * v;
      c.drawLine(at + Offset(math.cos(a), math.sin(a)) * d0, at + Offset(math.cos(a), math.sin(a)) * (d0 + 14), spark);
    }
    if (water) {
      final drop = Paint()..color = Color.fromRGBO(170, 210, 255, (0.9 - v * 0.6).clamp(0.0, 1.0));
      for (var i = 0; i < 10; i++) {
        final a = -math.pi / 2 + (i - 4.5) * 0.28;
        c.drawCircle(at + Offset(math.cos(a), math.sin(a)) * (16 + 60 * v), 2.4, drop);
      }
    }
    final white = (1 - v * 4).clamp(0.0, 1.0);
    if (white > 0) c.drawRect(Offset.zero & size, Paint()..color = Color.fromRGBO(255, 255, 255, 0.8 * white));
  }

  @override
  bool shouldRepaint(M6ThermalFlashPainter old) => old.v != v || old.at != at || old.water != water;
}
