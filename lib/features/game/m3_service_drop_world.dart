import 'dart:math' as math;

import 'package:flutter/material.dart';

// The last mile for lesson 3.8 কাজ 1 "শেষ মাইল" (m3_service_drop): a drawn,
// layered place — the evening-blue sky, a far tree line, the LT pole by the
// lane (its cross-arm, four LT conductors with the earth set on them: the
// line is under shutdown, PTW and earth), the service bracket on the pole, a
// village house with its wall hook under the eave and the meter box on the
// wall, and on the lane three cable drums (the player picks one). Then the GI
// bearer wire from the pole to the house, the service cable hung on it with
// clips, and the cable's run down the wall into the meter box (a U drip loop,
// or a wrong way in). No text in the art (the drums' tags are widgets).
//
// Design: 360 wide × the scene's height; the ground follows the bottom of the
// screen (a tall phone gets more sky).

/// How the cable can go into the meter box.
enum M3ServiceDropEntry { loop, top, side }

/// Where the trainee is.
enum M3ServiceDropSpot { lane, pole, wall }

/// Where things stand (design px, 360 wide).
@immutable
class M3ServiceDropGeo {
  const M3ServiceDropGeo({required this.height, required this.groundY});

  factory M3ServiceDropGeo.forScene(double h, double inset) => M3ServiceDropGeo(height: h, groundY: h - 150 - inset);

  /// The pole's axis.
  static const px = 56.0;

  /// The house's left wall.
  static const wallX = 206.0;

  final double height;
  final double groundY;

  double get horizonY => groundY - 150;
  double get topY => groundY - 360;
  double get armY => topY + 14;

  /// The LT conductors' heights at the pole.
  List<double> get ltY => [armY - 3, armY - 3, armY - 3, armY - 3];
  List<double> get ltX => const [px - 26, px - 10, px + 10, px + 26];

  /// The service bracket on the pole (the bearer's pole end).
  Offset get poleHook => Offset(px + 12, topY + 62);

  /// The wall hook under the eave (the bearer's house end).
  Offset get houseHook => Offset(wallX + 12, groundY - 232);
  double get eaveY => groundY - 250;
  double get roofTop => groundY - 298;

  /// The meter box on the wall.
  Rect get meterBox => Rect.fromCenter(center: Offset(wallX + 58, groundY - 150), width: 42, height: 56);

  /// The cable gland under the meter box (where a drip loop comes in).
  Offset get glandBottom => Offset(meterBox.center.dx - 6, meterBox.bottom + 3);

  /// The bearer's sag (design px at mid-span).
  static const bearerSag = 7.0;

  /// The span: where a bearer, the cable or the clips go (tap area).
  Rect get spanRect {
    final a = poleHook;
    final b = houseHook;
    return Rect.fromLTRB(a.dx + 14, math.min(a.dy, b.dy) - 18, b.dx - 10, math.max(a.dy, b.dy) + 24);
  }

  /// A point on the bearer at [k] (0 pole → 1 house).
  Offset bearerAt(double k) {
    final p = Offset.lerp(poleHook, houseHook, k)!;
    return p.translate(0, bearerSag * 4 * k * (1 - k));
  }

  /// The three drums on the lane.
  static const drumR = 26.0;
  Offset drum(int i) => Offset(104 + i * 62.0, groundY + 30);
  Rect drumRect(int i) => Rect.fromCenter(center: drum(i).translate(0, 12), width: 60, height: 84);

  /// Where the drum's tag sits (top-left of a 60-wide label).
  Offset tagAt(int i) => drum(i).translate(-30, drumR + 6);

  /// The rings for the three ways into the meter box.
  Offset entryRing(M3ServiceDropEntry e) => switch (e) {
        M3ServiceDropEntry.loop => Offset(meterBox.center.dx - 18, meterBox.bottom + 32),
        M3ServiceDropEntry.top => Offset(meterBox.center.dx, meterBox.top - 30),
        M3ServiceDropEntry.side => Offset(meterBox.left - 26, meterBox.center.dy),
      };
  Rect entryRect(M3ServiceDropEntry e) => Rect.fromCenter(center: entryRing(e), width: 46, height: 46);

  /// The trainee's figure size (design px).
  static const figH = 112.0;
  static const figW = 56.0;

  /// The trainee's box at [s].
  Rect spotBox(M3ServiceDropSpot s) => switch (s) {
        M3ServiceDropSpot.lane => Rect.fromLTWH(-2, groundY - 36, figW, figH),
        M3ServiceDropSpot.pole => Rect.fromLTWH(px + 6, topY + 52, figW * 0.86, figH * 0.86),
        M3ServiceDropSpot.wall => Rect.fromLTWH(wallX - 52, groundY - 84, figW, figH),
      };

  @override
  bool operator ==(Object other) => other is M3ServiceDropGeo && other.height == height && other.groundY == groundY;

  @override
  int get hashCode => Object.hash(height, groundY);
}

/// One drum on the lane.
@immutable
class M3ServiceDropDrum {
  const M3ServiceDropDrum({required this.four, required this.cut, this.cutAngle = 0.6});

  /// A four-core cable (else twin-core).
  final bool four;

  /// The insulation is cut on the outer turn.
  final bool cut;
  final double cutAngle;

  @override
  bool operator ==(Object other) => other is M3ServiceDropDrum && other.four == four && other.cut == cut && other.cutAngle == cutAngle;

  @override
  int get hashCode => Object.hash(four, cut, cutAngle);
}

/// What the rig shows.
@immutable
class M3ServiceDropRig {
  const M3ServiceDropRig({
    required this.drums,
    this.taken,
    this.bearer = false,
    this.cableOn = false,
    this.clipped = false,
    this.entry,
  });

  final List<M3ServiceDropDrum> drums;

  /// The drum he took (its cable is run out).
  final int? taken;
  final bool bearer;

  /// The cable is laid along the bearer (not clipped yet).
  final bool cableOn;
  final bool clipped;

  /// How the cable goes into the meter box (null: its end hangs free).
  final M3ServiceDropEntry? entry;

  bool get four => taken != null && drums[taken!].four;

  @override
  bool operator ==(Object other) =>
      other is M3ServiceDropRig &&
      _sameDrums(other.drums, drums) &&
      other.taken == taken &&
      other.bearer == bearer &&
      other.cableOn == cableOn &&
      other.clipped == clipped &&
      other.entry == entry;

  static bool _sameDrums(List<M3ServiceDropDrum> a, List<M3ServiceDropDrum> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(drums), taken, bearer, cableOn, clipped, entry);
}

Path _sag(Offset p, Offset q, double sag) {
  final path = Path()..moveTo(p.dx, p.dy);
  const n = 22;
  for (var j = 1; j <= n; j++) {
    final k = j / n;
    final pt = Offset.lerp(p, q, k)!;
    path.lineTo(pt.dx, pt.dy + sag * 4 * k * (1 - k));
  }
  return path;
}

/// The cable's run from the wall hook into the meter box for [e] (null: its
/// end hangs free down the wall).
Path m3ServiceDropRun(M3ServiceDropGeo geo, M3ServiceDropEntry? e) {
  final h = geo.houseHook.translate(0, 4);
  final box = geo.meterBox;
  final p = Path()..moveTo(h.dx, h.dy);
  switch (e) {
    case null:
      p.quadraticBezierTo(h.dx - 4, h.dy + 30, h.dx + 4, h.dy + 46);
    case M3ServiceDropEntry.loop:
      // Down the wall past the box, the U below the gland, up into it.
      final low = geo.entryRing(M3ServiceDropEntry.loop);
      p
        ..lineTo(h.dx, box.center.dy)
        ..quadraticBezierTo(h.dx, low.dy + 6, low.dx, low.dy + 6)
        ..quadraticBezierTo(geo.glandBottom.dx, low.dy + 6, geo.glandBottom.dx, geo.glandBottom.dy);
    case M3ServiceDropEntry.top:
      p
        ..lineTo(h.dx, box.top - 30)
        ..quadraticBezierTo(h.dx, box.top - 12, box.center.dx - 6, box.top - 10)
        ..lineTo(box.center.dx - 6, box.top);
    case M3ServiceDropEntry.side:
      p
        ..lineTo(h.dx, box.center.dy - 12)
        ..quadraticBezierTo(h.dx, box.center.dy, h.dx + 10, box.center.dy)
        ..lineTo(box.left, box.center.dy);
  }
  return p;
}

/// The place: sky, land, the LT pole, the house and meter box, the drums,
/// the bearer and the cable.
class M3ServiceDropWorldPainter extends CustomPainter {
  const M3ServiceDropWorldPainter({required this.geo, required this.rig});
  final M3ServiceDropGeo geo;
  final M3ServiceDropRig rig;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final hz = geo.horizonY;
    final g = geo.groundY;

    // --- sky -------------------------------------------------------------------
    final sky = Rect.fromLTWH(0, 0, w, hz + 6);
    c.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4F8CC9), Color(0xFF9CC4E4), Color(0xFFF1E6C8)],
          stops: [0, 0.62, 1],
        ).createShader(sky),
    );
    final sun = Offset(w * 0.78, hz * 0.34);
    c.drawCircle(sun, 90, Paint()..shader = const RadialGradient(colors: [Color(0x80FFF4D2), Color(0x00FFF4D2)]).createShader(Rect.fromCircle(center: sun, radius: 90)));
    c.drawCircle(sun, 13, Paint()..color = const Color(0xFFFFF6DC));
    final cloud = Paint()..color = const Color(0xCCFFFFFF);
    for (final (x, y, r) in [(120.0, hz * 0.42, 15.0), (300.0, hz * 0.18, 19.0), (210.0, hz * 0.66, 11.0)]) {
      c.drawCircle(Offset(x, y), r, cloud);
      c.drawCircle(Offset(x + r, y + 4), r * 0.8, cloud);
      c.drawCircle(Offset(x - r, y + 5), r * 0.7, cloud);
    }

    // --- far land --------------------------------------------------------------
    final tree = Path()..moveTo(0, hz);
    for (var x = 0.0; x <= w + 16; x += 16) {
      final bump = 13 + 8 * math.sin(x * 0.05 + 0.7) + 5 * math.sin(x * 0.17 + 1.1);
      tree.quadraticBezierTo(x + 8, hz - bump - 9, x + 16, hz - bump * 0.6);
    }
    tree
      ..lineTo(w, hz + 4)
      ..lineTo(0, hz + 4)
      ..close();
    c.drawPath(tree, Paint()..color = const Color(0xFF4F7A55));
    final field = Rect.fromLTRB(0, hz, w, g + 10);
    c.drawRect(
      field,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8DB860), Color(0xFF6E9E45)],
        ).createShader(field),
    );

    // --- the lane ----------------------------------------------------------------
    final verge = Rect.fromLTRB(0, g - 14, w, g + 12);
    c.drawRect(verge, Paint()..color = const Color(0xFF5E8E3A));
    final lane = Rect.fromLTRB(0, g + 8, w, size.height);
    c.drawRect(
      lane,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF9A8A6C), Color(0xFF7A6C54)],
        ).createShader(lane),
    );
    final pebble = Paint()..color = const Color(0x33FFFFFF);
    for (var i = 0; i < 26; i++) {
      c.drawCircle(Offset((i * 47.0) % w, g + 20 + (i * 29.0) % 120), 1.4, pebble);
    }

    // --- the house ---------------------------------------------------------------
    _house(c, w);

    // --- the LT line and the pole ----------------------------------------------
    _ltLine(c, w);
    _pole(c);

    // --- the bearer and the cable ----------------------------------------------
    _span(c);

    // --- the drums -----------------------------------------------------------------
    for (var i = 0; i < rig.drums.length; i++) {
      _drum(c, geo.drum(i), rig.drums[i], taken: rig.taken == i);
    }
  }

  void _house(Canvas c, double w) {
    final g = geo.groundY;
    const x0 = M3ServiceDropGeo.wallX;
    // The wall (plastered brick) and its plinth.
    final wall = Rect.fromLTRB(x0, geo.eaveY, w + 4, g);
    c.drawRect(
      wall,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF0E2C4), Color(0xFFDCC8A2)],
        ).createShader(wall),
    );
    c.drawRect(Rect.fromLTRB(x0, g - 14, w + 4, g), Paint()..color = const Color(0xFFB79E78));
    c.drawLine(Offset(x0, geo.eaveY), Offset(x0, g), Paint()
      ..color = const Color(0xFFC2AE88)
      ..strokeWidth = 2);
    // The tin roof with its overhang.
    final roof = Path()
      ..moveTo(x0 - 18, geo.eaveY + 2)
      ..lineTo(x0 + 34, geo.roofTop)
      ..lineTo(w + 6, geo.roofTop)
      ..lineTo(w + 6, geo.eaveY + 2)
      ..close();
    c.drawPath(roof, Paint()..color = const Color(0xFF8E979E));
    final rib = Paint()
      ..color = const Color(0xFF6F787F)
      ..strokeWidth = 1.2;
    for (var x = x0 + 4.0; x < w + 6; x += 12) {
      c.drawLine(Offset(x - 16, geo.eaveY + 1), Offset(x + 22, geo.roofTop + 1), rib);
    }
    c.drawRect(Rect.fromLTRB(x0 - 18, geo.eaveY - 1, w + 6, geo.eaveY + 4), Paint()..color = const Color(0xFF5E666C));
    // A window and the door.
    final win = Rect.fromLTWH(x0 + 100, g - 176, 36, 40);
    c.drawRect(win, Paint()..color = const Color(0xFF3F5B70));
    final bar = Paint()
      ..color = const Color(0xFF6E5236)
      ..strokeWidth = 2;
    for (var i = 1; i < 4; i++) {
      c.drawLine(Offset(win.left + i * 9, win.top), Offset(win.left + i * 9, win.bottom), bar);
    }
    c.drawRect(win, Paint()
      ..color = const Color(0xFF6E5236)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3);
    c.drawRect(Rect.fromLTWH(x0 + 100, g - 92, 46, 78), Paint()..color = const Color(0xFF7A4E2C));
    c.drawCircle(Offset(x0 + 138, g - 52), 2.2, Paint()..color = const Color(0xFFD9B44A));

    // The wall hook (an eye bolt) under the eave.
    final hk = geo.houseHook;
    c.drawRect(Rect.fromCenter(center: hk.translate(-4, 0), width: 10, height: 3), Paint()..color = const Color(0xFF555C62));
    c.drawCircle(hk, 3.6, Paint()
      ..color = const Color(0xFF555C62)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);

    // The meter box: a grey box with a window on the meter (an LCD).
    final box = geo.meterBox;
    final rr = RRect.fromRectAndRadius(box, const Radius.circular(4));
    c.drawRRect(rr.shift(const Offset(2, 3)), Paint()..color = const Color(0x33000000));
    c.drawRRect(
        rr,
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFDDE2E6), Color(0xFFB3BAC0)])
              .createShader(box));
    c.drawRRect(rr, Paint()
      ..color = const Color(0xFF6E767C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6);
    final glass = Rect.fromLTWH(box.left + 7, box.top + 8, box.width - 14, box.height * 0.5);
    c.drawRRect(RRect.fromRectAndRadius(glass, const Radius.circular(3)), Paint()..color = const Color(0xFF2E3B44));
    c.drawRect(Rect.fromLTWH(glass.left + 4, glass.top + 5, glass.width - 8, 8), Paint()..color = const Color(0xFF9FD8A8));
    c.drawCircle(Offset(glass.right - 6, glass.bottom - 6), 1.8, Paint()..color = const Color(0xFFE74C3C));
    // The company seal on the cover screw (a lead seal on a wire).
    final seal = Offset(box.center.dx, box.bottom - 9);
    c.drawLine(seal.translate(-5, -3), seal.translate(0, 0), Paint()
      ..color = const Color(0xFF9AA1A7)
      ..strokeWidth = 1);
    c.drawCircle(seal, 2.6, Paint()..color = const Color(0xFF8C8F93));
    // The gland under the box.
    c.drawRect(Rect.fromCenter(center: geo.glandBottom.translate(0, -1), width: 8, height: 5), Paint()..color = const Color(0xFF3A3F45));
  }

  void _ltLine(Canvas c, double w) {
    final wire = Paint()
      ..color = const Color(0xFF2E3338)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 4; i++) {
      final y = geo.ltY[i];
      final x = geo.ltX[i];
      c.drawPath(_sag(Offset(-10, y + 6 + i * 2.0), Offset(x, y), 10), wire);
      c.drawPath(_sag(Offset(x, y), Offset(w + 10, y + 16 + i * 3.0), 24), wire);
    }
  }

  void _pole(Canvas c) {
    const px = M3ServiceDropGeo.px;
    final g = geo.groundY;
    final top = geo.topY;
    const half0 = 11.0;
    const half1 = 6.5;
    final body = Path()
      ..moveTo(px - half0, g + 4)
      ..lineTo(px - half1, top)
      ..lineTo(px + half1, top)
      ..lineTo(px + half0, g + 4)
      ..close();
    c.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(colors: [Color(0xFF9C988E), Color(0xFFCBC7BC), Color(0xFF8E8A80)], stops: [0, 0.45, 1])
            .createShader(Rect.fromLTRB(px - half0, top, px + half0, g)),
    );
    // The cross-arm and four LT pin insulators.
    c.drawRect(Rect.fromLTRB(px - 34, geo.armY - 2, px + 34, geo.armY + 4), Paint()..color = const Color(0xFF6E757B));
    for (final x in geo.ltX) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, geo.armY - 5), width: 6, height: 7), const Radius.circular(2)), Paint()..color = const Color(0xFFF2EFE6));
    }
    // The earth set on the four conductors (shutdown, PTW, earth), its lead
    // down the pole to the spike.
    final lead = Paint()
      ..color = const Color(0xFFB87333)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final join = Offset(px - 18, geo.armY + 34);
    for (final x in geo.ltX) {
      final at = Offset(x - 5, geo.armY - 2);
      c.drawPath(Path()
        ..moveTo(at.dx, at.dy)
        ..quadraticBezierTo((at.dx + join.dx) / 2, join.dy - 4, join.dx, join.dy), lead);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: at, width: 6, height: 6), const Radius.circular(1.5)), Paint()..color = const Color(0xFF2E9A44));
      c.drawRect(Rect.fromCenter(center: at.translate(0, 1), width: 6, height: 1.6), Paint()..color = const Color(0xFFF4D03F));
    }
    final spike = Offset(px - 26, g + 14);
    c.drawPath(Path()
      ..moveTo(join.dx, join.dy)
      ..quadraticBezierTo(join.dx - 6, (join.dy + spike.dy) / 2, spike.dx, spike.dy - 10), lead..strokeWidth = 2);
    c.drawRect(Rect.fromLTWH(spike.dx - 1.5, spike.dy - 12, 3, 16), Paint()..color = const Color(0xFF6B7076));
    // Step bolts.
    final bolt = Paint()..color = const Color(0xFF6B7076);
    var left = true;
    for (var y = g - 60; y > geo.poleHook.dy + 60; y -= 34) {
      final k = (y - top) / (g - top);
      final half = half1 + (half0 - half1) * k;
      c.drawRect(Rect.fromLTWH(left ? px - half - 7 : px + half, y, 8, 2.4), bolt);
      left = !left;
    }
    // The service bracket (the bearer's pole end).
    final hk = geo.poleHook;
    c.drawRect(Rect.fromLTRB(px - 6, hk.dy - 3, hk.dx + 2, hk.dy + 3), Paint()..color = const Color(0xFF555C62));
    c.drawCircle(hk, 3.4, Paint()
      ..color = const Color(0xFF555C62)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
  }

  void _span(Canvas c) {
    final a = geo.poleHook;
    final b = geo.houseHook;
    if (rig.bearer) {
      c.drawPath(
          _sag(a, b, M3ServiceDropGeo.bearerSag),
          Paint()
            ..color = const Color(0xFF9AA3AA)
            ..strokeWidth = 1.6
            ..style = PaintingStyle.stroke);
    }
    if (!rig.cableOn && !rig.clipped) return;
    final cable = Paint()
      ..color = const Color(0xFF1E2226)
      ..strokeWidth = rig.four ? 3.4 : 2.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    if (rig.clipped) {
      // Hung on the bearer: clips every few px, the cable just under it.
      final path = Path();
      const n = 24;
      for (var j = 0; j <= n; j++) {
        final p = geo.bearerAt(j / n).translate(0, 3);
        j == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      c.drawPath(path, cable);
      final clip = Paint()..color = const Color(0xFFE8E4D8);
      for (var k = 0.12; k < 0.95; k += 0.13) {
        final p = geo.bearerAt(k);
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: p.translate(0, 1.5), width: 4, height: 7), const Radius.circular(1)), clip);
      }
    } else {
      // Laid along the bearer, not clipped yet: it droops below.
      c.drawPath(_sag(a.translate(0, 3), b.translate(0, 3), 30), cable);
    }
    // The pole end: down to the LT line's connection.
    c.drawPath(
        Path()
          ..moveTo(a.dx, a.dy + 3)
          ..quadraticBezierTo(a.dx - 2, a.dy - 20, geo.ltX[2], geo.armY + 4),
        cable);
    // The house end: down the wall to the meter box.
    c.drawPath(m3ServiceDropRun(geo, rig.entry), cable);
  }

  void _drum(Canvas c, Offset o, M3ServiceDropDrum d, {required bool taken}) {
    const r = M3ServiceDropGeo.drumR;
    c.drawOval(Rect.fromCenter(center: o.translate(0, r + 2), width: r * 2.2, height: 8), Paint()..color = const Color(0x44000000));
    // The flange (wood) and the wound cable.
    c.drawCircle(o, r, Paint()..color = const Color(0xFFA97B4F));
    c.drawCircle(o, r, Paint()
      ..color = const Color(0xFF6E4A2A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
    final wound = taken ? r * 0.55 : r * 0.82;
    c.drawCircle(o, wound, Paint()..color = const Color(0xFF22262A));
    final turn = Paint()
      ..color = const Color(0xFF3A4046)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var k = 0.5; k < 0.95; k += 0.15) {
      c.drawCircle(o, wound * k / 0.95, turn);
    }
    c.drawCircle(o, r * 0.24, Paint()..color = const Color(0xFFC79A6A));
    c.drawCircle(o, r * 0.1, Paint()..color = const Color(0xFF4A3420));
    if (d.cut && !taken) {
      // A gash in the outer turn: the bare aluminium strands show.
      final p = o + Offset(math.cos(d.cutAngle), math.sin(d.cutAngle)) * (wound - 3);
      c.save();
      c.translate(p.dx, p.dy);
      c.rotate(d.cutAngle + math.pi / 2);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 13, height: 6), const Radius.circular(2)), Paint()..color = const Color(0xFFD9DDE0));
      final strand = Paint()
        ..color = const Color(0xFF8D949B)
        ..strokeWidth = 0.9;
      for (var x = -5.0; x <= 5; x += 2.5) {
        c.drawLine(Offset(x, -2.6), Offset(x + 1.2, 2.6), strand);
      }
      c.restore();
    }
    // The cable's end out of the drum: its cores show at the cut face.
    final end = o + const Offset(r * 0.95, -r * 0.55);
    c.drawLine(o + Offset(wound * 0.7, -wound * 0.7), end, Paint()
      ..color = const Color(0xFF22262A)
      ..strokeWidth = d.four ? 6 : 5
      ..strokeCap = StrokeCap.round);
    c.drawCircle(end, d.four ? 7 : 6, Paint()..color = const Color(0xFF22262A));
    final cores = d.four
        ? const [(Offset(-2.6, -2.6), Color(0xFFE74C3C)), (Offset(2.6, -2.6), Color(0xFFF1C40F)), (Offset(-2.6, 2.6), Color(0xFF3498DB)), (Offset(2.6, 2.6), Color(0xFF111111))]
        : const [(Offset(-2.4, 0), Color(0xFFE74C3C)), (Offset(2.4, 0), Color(0xFF111111))];
    for (final (dx, col) in cores) {
      c.drawCircle(end + dx, 2.1, Paint()..color = const Color(0xFFD9DDE0));
      c.drawCircle(end + dx, 1.5, Paint()..color = col);
    }
  }

  @override
  bool shouldRepaint(M3ServiceDropWorldPainter old) => old.geo != geo || old.rig != rig;
}

/// The trainee's pole strap and the step under his boots while he works on
/// the pole (he wears his harness: anyone on a pole does).
class M3ServiceDropStrapPainter extends CustomPainter {
  const M3ServiceDropStrapPainter({required this.box});
  final Rect box;

  @override
  void paint(Canvas c, Size size) {
    final hip = Offset(box.left + box.width * 0.5, box.top + box.height * 0.52);
    final strap = Paint()
      ..color = const Color(0xFF3A2A16)
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke;
    const px = M3ServiceDropGeo.px;
    const far = px - 9;
    final feet = box.bottom - 3;
    c.drawRect(Rect.fromLTRB(px, feet, box.left + box.width * 0.7, feet + 3), Paint()..color = const Color(0xFF5A6066));
    c.drawPath(
        Path()
          ..moveTo(hip.dx, hip.dy)
          ..quadraticBezierTo(px, hip.dy - 10, far, hip.dy - 6)
          ..moveTo(hip.dx, hip.dy + 2)
          ..quadraticBezierTo(px, hip.dy + 4, far, hip.dy - 6),
        strap);
    // The harness's back lanyard, hooked above him on the pole.
    final hookAt = Offset(px - 4, box.top - 4);
    c.drawPath(
        Path()
          ..moveTo(hip.dx - 4, hip.dy - 18)
          ..quadraticBezierTo(px + 6, box.top + 14, hookAt.dx, hookAt.dy),
        Paint()
          ..color = const Color(0xFFE67E22)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke);
    c.drawCircle(hookAt, 2.6, Paint()..color = const Color(0xFF555C62));
  }

  @override
  bool shouldRepaint(M3ServiceDropStrapPainter old) => old.box != box;
}

/// Rain on the finished drip loop: a drop runs down the cable and falls off
/// the U's bottom, clear of the meter box ([v] 0 → 1, a one-shot).
class M3ServiceDropDripPainter extends CustomPainter {
  const M3ServiceDropDripPainter({required this.geo, required this.v});
  final M3ServiceDropGeo geo;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final low = geo.entryRing(M3ServiceDropEntry.loop).translate(0, 9);
    final drop = Paint()..color = const Color(0xCC6FB6E8);
    for (var i = 0; i < 3; i++) {
      final k = ((v * 1.6) - i * 0.3).clamp(0.0, 1.0);
      if (k <= 0 || k >= 1) continue;
      final p = low.translate(0, k * 44);
      c.drawPath(
          Path()
            ..moveTo(p.dx, p.dy - 5)
            ..quadraticBezierTo(p.dx + 3.4, p.dy, p.dx, p.dy + 2.4)
            ..quadraticBezierTo(p.dx - 3.4, p.dy, p.dx, p.dy - 5),
          drop);
    }
  }

  @override
  bool shouldRepaint(M3ServiceDropDripPainter old) => old.v != v || old.geo != geo;
}
