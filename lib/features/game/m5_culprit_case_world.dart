import 'dart:math' as math;

import 'package:flutter/material.dart';

// The drawn world of lesson 5.3 কাজ 1 "অপরাধী কে? সূত্রের সুতো"
// (m5_culprit_case.dart): the morning after a night trip on a rural 11 kV
// feeder. One spot of the line at a time: a village road, a tree on the left,
// an 11 kV pole in the middle (a pin insulator on the pole top and two on the
// cross-arm, a lightning arrester on its bracket below), the three conductors
// running left and right, a tea stall on the right.
//
// The spot's clues and decoys are drawn on fixed anchors (the insulators, the
// spans, the cross-arm ends, the pole, the ground, the tree crown, the stall
// roof): a cracked insulator, a carbon track, a branch on the wires, a melted
// PG clamp, a burnt bird, a blown LA, a kite's metal string … and things that
// only look like them (morning dew on a sound insulator, a pruned pile, a
// shiny new clamp, a live crow …). Nothing in the art is text.
//
// Design: 360 wide × the scene's height; the ground follows the bottom of the
// screen (a tall phone gets more sky, never stretched). Code-drawn, gradients,
// no bitmaps. The same painter draws the phone photos (a crop of the world).

/// The culprits of the lesson (5.3, "অপরাধীদের প্যারেড").
enum M5Culprit { tree, insulator, jumper, bird, la, kite }

/// What can be in a spot: the real clues (lesson 5.3's "সূত্র") and the
/// decoys that only look like one.
enum M5Clue {
  // real — tree
  branch,
  sag,
  armScar,
  // real — insulator
  pinCrack,
  carbon,
  chips,
  // real — conductor / jumper
  pgMelt,
  sleeveHot,
  wireDown,
  // real — bird or animal
  birdBody,
  blood,
  birdFlash,
  // real — LA
  laBlown,
  laLead,
  // real — kite
  kiteWire,
  manja,
  // decoys
  prunedPile,
  dryLeaves,
  dewInsulator,
  spareCrate,
  newClamp,
  wireCoil,
  liveCrow,
  catRoof,
  earthPit,
  tapePole,
  kiteTree,
  flagStall,
}

/// Where a clue can sit (design px from [M5CulpritGeo.anchor]).
enum M5Anchor { ins0, ins1, ins2, armL, armR, wireA, wireB, wireC, wireD, la, laLead, poleMid, poleLow, g0, g1, g2, g3, crown, stall }

/// The morning light of a spot.
enum M5Light { sun, haze }

/// One clue (or decoy) in a spot.
@immutable
class M5Placed {
  const M5Placed(this.clue, this.at);
  final M5Clue clue;
  final M5Anchor at;

  @override
  bool operator ==(Object other) => other is M5Placed && other.clue == clue && other.at == at;

  @override
  int get hashCode => Object.hash(clue, at);
}

/// What a spot shows.
@immutable
class M5View {
  const M5View({required this.items, required this.treeToGround, required this.light, required this.villager});
  final List<M5Placed> items;

  /// The branch on the wires reaches down to the ground (else it lies across two wires).
  final bool treeToGround;
  final M5Light light;

  /// The villager is at the tea stall.
  final bool villager;

  bool has(M5Clue c) => items.any((p) => p.clue == c);
}

/// Where things are (design px, 360 wide).
@immutable
class M5CulpritGeo {
  const M5CulpritGeo._(this.height, this.groundY, this.topY);

  factory M5CulpritGeo.forScene(double height, double inset) {
    final g = height - floorUp - inset * 0.5;
    return M5CulpritGeo._(height, g, math.max(150.0, g - 420));
  }

  final double height;

  /// The road edge at the pole's foot.
  final double groundY;

  /// The pole top.
  final double topY;

  /// The ground sits this far above the bottom (the phone row stands on it).
  static const double floorUp = 150;

  static const double poleX = 196;

  /// The cross-arm (its two pin insulators) below the pole-top insulator.
  double get armY => topY + 40;

  /// The insulator tops that carry the three conductors (left arm, pole top, right arm).
  List<Offset> get insulators => [Offset(142, armY - 18), Offset(poleX, topY - 18), Offset(250, armY - 18)];

  /// Conductor [i] at [x] (a gentle sag away from the pole), [sagged]: the
  /// left span of conductor 0 hangs low onto the tree.
  double wireY(int i, double x, {bool sagged = false}) {
    final p = insulators[i];
    final d = (x - p.dx).abs().clamp(0.0, 230.0);
    var y = p.dy + 24 * math.pow(d / 190, 2).toDouble();
    if (sagged && i == 0 && x < p.dx) y += 46 * math.sin(math.pi * (p.dx - x) / (p.dx + 10)).abs();
    return y;
  }

  /// The LA on its bracket below the right arm, and the foot of its earth lead.
  Offset get laAt => Offset(214, armY + 48);

  /// The tree on the left: trunk foot and crown.
  Offset get trunkFoot => Offset(46, groundY + 6);
  Offset get crownAt => Offset(66, armY + 66);
  double get crownR => 52;

  /// The tea stall on the right.
  Rect get stall => Rect.fromLTRB(274, groundY - 118, 360, groundY + 4);

  /// The villager at the stall (tap him).
  Rect get villager => Rect.fromLTWH(300, groundY - 92, 44, 94);

  /// Where the trainee stands (on the road, right of the pole).
  Rect get trainee => Rect.fromLTWH(224, groundY - 100, 48, 100);

  /// The phone's view: its centre on the scene (the reticle).
  Offset viewCentre() => Offset(180, height * 0.42);

  /// Where an anchor is in this spot.
  Offset anchor(M5Anchor a, {bool sagged = false}) => switch (a) {
        M5Anchor.ins0 => insulators[0].translate(0, -2),
        M5Anchor.ins1 => insulators[1].translate(0, -2),
        M5Anchor.ins2 => insulators[2].translate(0, -2),
        M5Anchor.armL => Offset(126, armY + 6),
        M5Anchor.armR => Offset(266, armY + 6),
        M5Anchor.wireA => Offset(48, wireY(0, 48, sagged: sagged)),
        M5Anchor.wireB => Offset(96, wireY(0, 96, sagged: sagged)),
        M5Anchor.wireC => Offset(304, wireY(2, 304)),
        M5Anchor.wireD => Offset(344, wireY(2, 344)),
        M5Anchor.la => laAt,
        M5Anchor.laLead => Offset(laAt.dx, laAt.dy + 54),
        M5Anchor.poleMid => Offset(poleX, armY + (groundY - armY) * 0.55),
        M5Anchor.poleLow => Offset(poleX, groundY - 46),
        // The ground right of the pole (the corner guide stands bottom left).
        M5Anchor.g0 => Offset(232, groundY + 28),
        M5Anchor.g1 => Offset(268, groundY + 44),
        M5Anchor.g2 => Offset(306, groundY + 30),
        M5Anchor.g3 => Offset(338, groundY + 46),
        M5Anchor.crown => Offset(70, armY + 52),
        M5Anchor.stall => Offset(318, groundY - 126),
      };

  @override
  bool operator ==(Object other) => other is M5CulpritGeo && other.height == height && other.groundY == groundY && other.topY == topY;

  @override
  int get hashCode => Object.hash(height, groundY, topY);
}

/// The spot: sky, field, road, tree, stall, the pole and line, and the clues.
class M5CulpritPainter extends CustomPainter {
  const M5CulpritPainter({required this.geo, required this.view, required this.seed});

  final M5CulpritGeo geo;
  final M5View view;
  final int seed;

  bool get _sagged => view.has(M5Clue.sag);

  @override
  void paint(Canvas canvas, Size size) {
    final g = geo;
    // The world is drawn wider than the screen: a zoomed phone view near an
    // edge never shows a dark border.
    const l = -320.0;
    const w = 1000.0;
    // Sky.
    final sky = view.light == M5Light.sun
        ? const [Color(0xFF7FB7E8), Color(0xFFBFDDF2), Color(0xFFF5E6C4)]
        : const [Color(0xFF9FB0BF), Color(0xFFC9D2D8), Color(0xFFE4E2D6)];
    canvas.drawRect(
      Rect.fromLTWH(l, -200, w, g.groundY + 200),
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: sky).createShader(Rect.fromLTWH(l, 0, w, g.groundY)),
    );
    if (view.light == M5Light.sun) {
      canvas.drawCircle(Offset(300, g.topY - 60), 26, Paint()..color = const Color(0x55FFF4C8));
      canvas.drawCircle(Offset(300, g.topY - 60), 15, Paint()..color = const Color(0xFFFFF0B8));
    }
    // Far fields and a tree line.
    final far = Path()..moveTo(l, g.groundY - 40);
    for (var x = l; x <= l + w; x += 30) {
      far.lineTo(x, g.groundY - 40 - 10 * math.sin((x + seed * 13) / 40));
    }
    far
      ..lineTo(l + w, g.groundY)
      ..lineTo(l, g.groundY)
      ..close();
    canvas.drawPath(far, Paint()..color = view.light == M5Light.sun ? const Color(0xFF6E9A5A) : const Color(0xFF768D6C));
    // Ground and road.
    canvas.drawRect(
      Rect.fromLTWH(l, g.groundY - 4, w, size.height - g.groundY + 300),
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8C9A5C), Color(0xFF6F7B47)]).createShader(Rect.fromLTWH(0, g.groundY, 360, 200)),
    );
    double roadY(double x, double y0, double y1) => y0 + (y1 - y0) * x / 360;
    final road = Path()
      ..moveTo(l, roadY(l, 50, 30) + g.groundY)
      ..lineTo(l + w, roadY(l + w, 50, 30) + g.groundY)
      ..lineTo(l + w, roadY(l + w, 118, 92) + g.groundY)
      ..lineTo(l, roadY(l, 118, 92) + g.groundY)
      ..close();
    canvas.drawPath(road, Paint()..color = const Color(0xFF8A7E6E));
    canvas.drawLine(Offset(l, roadY(l, 84, 61) + g.groundY), Offset(l + w, roadY(l + w, 84, 61) + g.groundY), Paint()..color = const Color(0x55FFFFFF)..strokeWidth = 2);

    _tree(canvas);
    _stall(canvas);
    _pole(canvas);
    _wires(canvas);
    _la(canvas);
    for (final p in view.items) {
      _clue(canvas, p.clue, g.anchor(p.at, sagged: _sagged));
    }
    if (view.villager) _villager(canvas);
  }

  // --- the scenery ----------------------------------------------------------
  void _tree(Canvas canvas) {
    final g = geo;
    final trunk = Path()
      ..moveTo(g.trunkFoot.dx - 9, g.trunkFoot.dy)
      ..lineTo(g.trunkFoot.dx - 4, g.crownAt.dy)
      ..lineTo(g.trunkFoot.dx + 6, g.crownAt.dy)
      ..lineTo(g.trunkFoot.dx + 10, g.trunkFoot.dy)
      ..close();
    canvas.drawPath(trunk, Paint()..color = const Color(0xFF5B4030));
    final c = g.crownAt;
    final leaf = Paint()
      ..shader = const RadialGradient(colors: [Color(0xFF4F8A3C), Color(0xFF2E5E2A)]).createShader(Rect.fromCircle(center: c, radius: g.crownR));
    for (final o in const [Offset(-26, 10), Offset(22, 14), Offset(0, -18), Offset(-8, 22), Offset(30, -6)]) {
      canvas.drawCircle(c + o, g.crownR * 0.62, leaf);
    }
  }

  void _stall(Canvas canvas) {
    final s = geo.stall;
    canvas.drawRect(Rect.fromLTRB(s.left + 6, s.top + 22, s.right, s.bottom), Paint()..color = const Color(0xFFB98A5A));
    canvas.drawRect(Rect.fromLTRB(s.left + 14, s.top + 50, s.right - 6, s.bottom - 30), Paint()..color = const Color(0xFF4A3426));
    final roof = Path()
      ..moveTo(s.left - 4, s.top + 26)
      ..lineTo(s.left + 18, s.top)
      ..lineTo(s.right + 4, s.top)
      ..lineTo(s.right + 4, s.top + 26)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFF8E9AA6));
    for (var x = s.left + 4; x < s.right; x += 10) {
      canvas.drawLine(Offset(x, s.top + 25), Offset(x + 14, s.top + 1), Paint()..color = const Color(0x33000000)..strokeWidth = 1);
    }
    // Bench and kettle.
    canvas.drawRect(Rect.fromLTWH(s.left - 2, s.bottom - 18, 40, 5), Paint()..color = const Color(0xFF6B4A32));
    canvas.drawCircle(Offset(s.left + 52, s.bottom - 36), 6, Paint()..color = const Color(0xFFB0B6BC));
  }

  void _pole(Canvas canvas) {
    final g = geo;
    const x = M5CulpritGeo.poleX;
    final body = Rect.fromLTRB(x - 6, g.topY, x + 6, g.groundY + 10);
    canvas.drawRect(
      body,
      Paint()..shader = const LinearGradient(colors: [Color(0xFF7D858C), Color(0xFFB9C0C6), Color(0xFF6C747B)]).createShader(body),
    );
    // Cross-arm.
    final arm = Rect.fromLTRB(118, g.armY - 3, 274, g.armY + 6);
    canvas.drawRect(arm, Paint()..color = const Color(0xFF59606A));
    canvas.drawLine(Offset(x, g.armY + 6), Offset(150, g.armY + 34), Paint()..color = const Color(0xFF59606A)..strokeWidth = 3);
    canvas.drawLine(Offset(x, g.armY + 6), Offset(242, g.armY + 34), Paint()..color = const Color(0xFF59606A)..strokeWidth = 3);
    // Insulators (sound, unless a clue changes one).
    final ins = g.insulators;
    for (var i = 0; i < 3; i++) {
      final a = [M5Anchor.ins0, M5Anchor.ins1, M5Anchor.ins2][i];
      final on = view.items.where((p) => p.at == a).map((p) => p.clue).firstOrNull;
      _insulator(canvas, ins[i], cracked: on == M5Clue.pinCrack);
    }
  }

  void _insulator(Canvas canvas, Offset top, {bool cracked = false}) {
    final shed = Paint()
      ..shader = const LinearGradient(colors: [Color(0xFF8A5236), Color(0xFFC07A50), Color(0xFF7A4630)]).createShader(Rect.fromCenter(center: top.translate(0, 8), width: 20, height: 22));
    canvas.drawRect(Rect.fromLTWH(top.dx - 2, top.dy + 12, 4, 10), Paint()..color = const Color(0xFF6E757C));
    if (cracked) {
      final half = Path()
        ..moveTo(top.dx - 10, top.dy + 6)
        ..lineTo(top.dx - 3, top.dy + 2)
        ..lineTo(top.dx + 1, top.dy + 7)
        ..lineTo(top.dx - 2, top.dy + 12)
        ..lineTo(top.dx - 10, top.dy + 12)
        ..close();
      canvas.drawPath(half, shed);
      canvas.drawOval(Rect.fromCenter(center: top.translate(5, 9), width: 9, height: 6), shed);
      canvas.drawLine(top.translate(1, 2), top.translate(4, 13), Paint()..color = const Color(0xFF2A1A12)..strokeWidth = 1.4);
      return;
    }
    canvas.drawOval(Rect.fromCenter(center: top.translate(0, 9), width: 20, height: 7), shed);
    canvas.drawOval(Rect.fromCenter(center: top.translate(0, 4), width: 15, height: 6), shed);
    canvas.drawCircle(top, 3.4, shed);
  }

  void _wires(Canvas canvas) {
    final g = geo;
    final p = Paint()
      ..color = const Color(0xFF2B2F33)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 3; i++) {
      final path = Path();
      for (var x = -320.0; x <= 680; x += 6) {
        final y = g.wireY(i, x, sagged: _sagged);
        if (x == -320) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, p);
    }
  }

  void _la(Canvas canvas) {
    final a = geo.laAt;
    canvas.drawLine(Offset(M5CulpritGeo.poleX + 6, a.dy + 4), Offset(a.dx + 4, a.dy + 4), Paint()..color = const Color(0xFF59606A)..strokeWidth = 3);
    // Lead from the right conductor down to the LA top.
    canvas.drawLine(geo.insulators[2].translate(0, 2), a.translate(0, -12), Paint()..color = const Color(0xFF2B2F33)..strokeWidth = 1.2);
    if (view.has(M5Clue.laBlown)) return;
    final body = Rect.fromCenter(center: a, width: 10, height: 24);
    canvas.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(3)),
        Paint()..shader = const LinearGradient(colors: [Color(0xFF6D747B), Color(0xFFA9B0B6), Color(0xFF656C73)]).createShader(body));
    for (var k = 0; k < 4; k++) {
      canvas.drawLine(Offset(a.dx - 7, a.dy - 8 + k * 5.5), Offset(a.dx + 7, a.dy - 8 + k * 5.5), Paint()..color = const Color(0xFF59606A)..strokeWidth = 1.6);
    }
    if (!view.has(M5Clue.laLead)) {
      // The earth lead runs down the pole, clamped.
      canvas.drawLine(a.translate(0, 12), Offset(M5CulpritGeo.poleX + 7, a.dy + 70), Paint()..color = const Color(0xFF3C4248)..strokeWidth = 1.3);
      canvas.drawLine(Offset(M5CulpritGeo.poleX + 7, a.dy + 70), Offset(M5CulpritGeo.poleX + 7, geo.groundY), Paint()..color = const Color(0xFF3C4248)..strokeWidth = 1.3);
    }
  }

  void _villager(Canvas canvas) {
    final r = geo.villager;
    final x = r.center.dx;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 11, r.top + 22, 22, 40), const Radius.circular(6)), Paint()..color = const Color(0xFFE6E0CF));
    canvas.drawRect(Rect.fromLTWH(x - 10, r.top + 60, 20, 32), Paint()..color = const Color(0xFF4F6E8E));
    canvas.drawCircle(Offset(x, r.top + 12), 10, Paint()..color = const Color(0xFF8A5A3C));
    canvas.drawArc(Rect.fromCircle(center: Offset(x, r.top + 9), radius: 10), math.pi, math.pi, true, Paint()..color = const Color(0xFF2A2420));
    // A tea cup in his hand.
    canvas.drawRect(Rect.fromLTWH(x + 11, r.top + 40, 6, 7), Paint()..color = Colors.white);
  }

  // --- the clues --------------------------------------------------------------
  void _clue(Canvas canvas, M5Clue c, Offset p) {
    final g = geo;
    final black = Paint()..color = const Color(0xFF15110E);
    switch (c) {
      case M5Clue.branch:
        final brown = Paint()
          ..color = const Color(0xFF5A3E2A)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round;
        final Offset a;
        final Offset b;
        if (view.treeToGround) {
          a = p.translate(-6, -6);
          b = Offset(p.dx + 26, g.groundY + 8);
        } else {
          a = Offset(p.dx - 30, g.wireY(1, p.dx - 30) - 4);
          b = Offset(p.dx + 34, g.wireY(0, p.dx + 34) + 6);
        }
        canvas.drawLine(a, b, brown);
        final mid = Offset.lerp(a, b, 0.5)!;
        canvas.drawLine(mid, mid.translate(-12, 10), brown..strokeWidth = 2.4);
        final leaf = Paint()..color = const Color(0xFF6E8A3A);
        for (var k = 0; k < 6; k++) {
          final q = Offset.lerp(a, b, 0.15 + k * 0.14)!;
          canvas.drawOval(Rect.fromCenter(center: q.translate(k.isEven ? 5 : -5, 3), width: 9, height: 5), leaf);
        }
        // The broken end, pale wood.
        canvas.drawCircle(a, 3, Paint()..color = const Color(0xFFE2C79A));
      case M5Clue.sag:
        // The sag is drawn by the wire itself; a small kink where it rests on the crown.
        canvas.drawCircle(p, 2.2, Paint()..color = const Color(0xFF2B2F33));
      case M5Clue.armScar:
        canvas.drawRect(Rect.fromCenter(center: p.translate(0, -4), width: 14, height: 6), Paint()..color = const Color(0xFFC9B48C));
        canvas.drawLine(p.translate(-7, -6), p.translate(6, -2), Paint()..color = const Color(0xFF3A2E22)..strokeWidth = 1.5);
        canvas.drawLine(p.translate(-4, -2), p.translate(3, -7), Paint()..color = const Color(0xFF3A2E22)..strokeWidth = 1.2);
      case M5Clue.pinCrack:
        // Drawn by the insulator; a chip falling.
        canvas.drawCircle(p.translate(9, 20), 1.8, Paint()..color = const Color(0xFFC07A50));
      case M5Clue.carbon:
      case M5Clue.birdFlash:
        final soot = Paint()
          ..color = const Color(0xE0141010)
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(p.translate(-3, 1), p.translate(-6, 12), soot);
        canvas.drawLine(p.translate(1, 2), p.translate(2, 13), soot);
        canvas.drawLine(p.translate(5, 3), p.translate(7, 11), soot);
        if (c == M5Clue.birdFlash) canvas.drawCircle(p.translate(0, 4), 5, Paint()..color = const Color(0x66201010));
      case M5Clue.chips:
        final shard = Paint()..color = const Color(0xFFB8744C);
        for (final o in const [Offset(-8, 0), Offset(0, 3), Offset(7, -1), Offset(3, -4)]) {
          canvas.drawPath(
            Path()
              ..moveTo(p.dx + o.dx, p.dy + o.dy)
              ..lineTo(p.dx + o.dx + 4, p.dy + o.dy - 2)
              ..lineTo(p.dx + o.dx + 2, p.dy + o.dy + 3)
              ..close(),
            shard,
          );
        }
      case M5Clue.pgMelt:
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: p, width: 14, height: 9), const Radius.circular(3)), black);
        canvas.drawOval(Rect.fromCenter(center: p.translate(2, 8), width: 5, height: 7), black);
        canvas.drawCircle(p.translate(-3, -1), 1.6, Paint()..color = const Color(0xFF8A5A2C));
      case M5Clue.sleeveHot:
        final r = Rect.fromCenter(center: p, width: 22, height: 6);
        canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)),
            Paint()..shader = const LinearGradient(colors: [Color(0xFFB5BCC2), Color(0xFF6A4F8E), Color(0xFF8E5A2C), Color(0xFFB5BCC2)]).createShader(r));
      case M5Clue.wireDown:
        final wire = Paint()
          ..color = const Color(0xFF3A3F44)
          ..strokeWidth = 1.8
          ..style = PaintingStyle.stroke;
        canvas.drawPath(
          Path()
            ..moveTo(p.dx - 16, p.dy - 2)
            ..quadraticBezierTo(p.dx - 2, p.dy + 8, p.dx + 8, p.dy - 1)
            ..quadraticBezierTo(p.dx + 14, p.dy - 6, p.dx + 18, p.dy + 2),
          wire,
        );
        for (var k = 0; k < 3; k++) {
          canvas.drawLine(p.translate(18, 2), p.translate(22 + k * 2.0, -2 + k * 3.0), wire..strokeWidth = 1);
        }
      case M5Clue.birdBody:
        final body = Paint()..color = const Color(0xFF241A14);
        canvas.drawOval(Rect.fromCenter(center: p, width: 14, height: 6), body);
        canvas.drawPath(
            Path()
              ..moveTo(p.dx - 4, p.dy)
              ..lineTo(p.dx - 16, p.dy - 6)
              ..lineTo(p.dx - 6, p.dy + 2)
              ..close(),
            body);
        canvas.drawPath(
            Path()
              ..moveTo(p.dx + 4, p.dy)
              ..lineTo(p.dx + 16, p.dy - 5)
              ..lineTo(p.dx + 6, p.dy + 2)
              ..close(),
            body);
        canvas.drawCircle(p.translate(8, -1), 2.5, body);
      case M5Clue.blood:
        final red = Paint()..color = const Color(0xFF7A1412);
        canvas.drawOval(Rect.fromCenter(center: p.translate(0, 1.5), width: 10, height: 3.5), red);
        canvas.drawOval(Rect.fromCenter(center: p.translate(1, 5), width: 2.5, height: 4), red);
      case M5Clue.laBlown:
        final grey = Paint()..color = const Color(0xFF6D747B);
        canvas.drawRect(Rect.fromLTWH(p.dx - 5, p.dy + 2, 10, 10), grey);
        canvas.drawPath(
          Path()
            ..moveTo(p.dx - 5, p.dy + 2)
            ..lineTo(p.dx - 2, p.dy - 6)
            ..lineTo(p.dx + 1, p.dy)
            ..lineTo(p.dx + 4, p.dy - 7)
            ..lineTo(p.dx + 5, p.dy + 2)
            ..close(),
          grey,
        );
        canvas.drawCircle(p.translate(0, -2), 6, Paint()..color = const Color(0x55141010));
        canvas.drawCircle(p.translate(-10, 24), 2, grey);
      case M5Clue.laLead:
        canvas.drawPath(
          Path()
            ..moveTo(geo.laAt.dx, geo.laAt.dy + 12)
            ..quadraticBezierTo(p.dx - 10, p.dy - 20, p.dx + 4, p.dy + 4),
          Paint()
            ..color = const Color(0xFF3C4248)
            ..strokeWidth = 1.3
            ..style = PaintingStyle.stroke,
        );
        canvas.drawCircle(p.translate(4, 4), 1.8, Paint()..color = const Color(0xFFB07A3C));
      case M5Clue.kiteWire:
      case M5Clue.kiteTree:
        final kite = Path()
          ..moveTo(p.dx, p.dy - 10)
          ..lineTo(p.dx + 8, p.dy)
          ..lineTo(p.dx, p.dy + 10)
          ..lineTo(p.dx - 8, p.dy)
          ..close();
        canvas.drawPath(kite, Paint()..color = c == M5Clue.kiteWire ? const Color(0xFFD8452E) : const Color(0xFFE0B23A));
        canvas.drawLine(p.translate(0, -10), p.translate(0, 10), Paint()..color = const Color(0x88000000)..strokeWidth = 0.8);
        canvas.drawPath(
          Path()
            ..moveTo(p.dx, p.dy + 10)
            ..quadraticBezierTo(p.dx + 6, p.dy + 18, p.dx - 2, p.dy + 26),
          Paint()
            ..color = const Color(0xFF7A5A9A)
            ..strokeWidth = 1
            ..style = PaintingStyle.stroke,
        );
      case M5Clue.manja:
        // A glinting metal string from this conductor up to the middle one.
        final x = p.dx;
        final yA = x > M5CulpritGeo.poleX ? g.wireY(2, x) : g.wireY(0, x, sagged: _sagged);
        final yB = g.wireY(1, x + 6);
        final glint = Paint()
          ..color = const Color(0xFFE8E2C8)
          ..strokeWidth = 1.1;
        canvas.drawLine(Offset(x, yA), Offset(x + 6, yB), glint);
        canvas.drawLine(Offset(x + 3, yA), Offset(x + 9, yB), glint..strokeWidth = 0.7);
      case M5Clue.prunedPile:
        final wood = Paint()
          ..color = const Color(0xFF6B4E34)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
        for (var k = 0; k < 4; k++) {
          canvas.drawLine(p.translate(-14, -k * 3.0), p.translate(14, -k * 3.0 - 1), wood);
          canvas.drawCircle(p.translate(14, -k * 3.0 - 1), 1.6, Paint()..color = const Color(0xFFF0DDB0));
        }
      case M5Clue.dryLeaves:
        final leaf = Paint()..color = const Color(0xFFA0702E);
        for (final o in const [Offset(-10, 0), Offset(-3, 4), Offset(5, -1), Offset(11, 3), Offset(2, -4)]) {
          canvas.drawOval(Rect.fromCenter(center: p + o, width: 6, height: 3), leaf);
        }
      case M5Clue.dewInsulator:
        final dew = Paint()..color = const Color(0xDDFFFFFF);
        for (final o in const [Offset(-6, 8), Offset(3, 9), Offset(6, 4), Offset(-2, 3)]) {
          canvas.drawCircle(p + o, 1.2, dew);
        }
      case M5Clue.spareCrate:
        canvas.drawRect(Rect.fromCenter(center: p, width: 24, height: 14), Paint()..color = const Color(0xFFA77B4C));
        canvas.drawLine(p.translate(-12, 0), p.translate(12, 0), Paint()..color = const Color(0xFF6E4E2E)..strokeWidth = 1);
        for (final dx in const [-6.0, 0.0, 6.0]) {
          canvas.drawCircle(p.translate(dx, -8), 3, Paint()..color = const Color(0xFFC07A50));
        }
      case M5Clue.newClamp:
        final r = Rect.fromCenter(center: p, width: 12, height: 8);
        canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)),
            Paint()..shader = const LinearGradient(colors: [Color(0xFFDDE3E8), Color(0xFF9AA4AC)]).createShader(r));
        canvas.drawCircle(p.translate(-3, 0), 1.3, Paint()..color = const Color(0xFF6A737B));
        canvas.drawCircle(p.translate(3, 0), 1.3, Paint()..color = const Color(0xFF6A737B));
      case M5Clue.wireCoil:
        final coil = Paint()
          ..color = const Color(0xFF9AA4AC)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        canvas.drawOval(Rect.fromCenter(center: p, width: 24, height: 9), coil);
        canvas.drawOval(Rect.fromCenter(center: p, width: 18, height: 6), coil);
        canvas.drawRect(Rect.fromCenter(center: p.translate(0, -4), width: 4, height: 4), Paint()..color = const Color(0xFF2F64B0));
      case M5Clue.liveCrow:
        final crow = Paint()..color = const Color(0xFF1C1E22);
        canvas.drawOval(Rect.fromCenter(center: p.translate(0, -6), width: 9, height: 11), crow);
        canvas.drawCircle(p.translate(3, -13), 3.4, crow);
        canvas.drawPath(
            Path()
              ..moveTo(p.dx + 6, p.dy - 13)
              ..lineTo(p.dx + 10, p.dy - 12)
              ..lineTo(p.dx + 6, p.dy - 11)
              ..close(),
            Paint()..color = const Color(0xFF3A3A3A));
        canvas.drawLine(p.translate(-2, 0), p.translate(-3, -1), crow..strokeWidth = 1);
      case M5Clue.catRoof:
        final cat = Paint()..color = const Color(0xFF6E5A48);
        canvas.drawOval(Rect.fromCenter(center: p.translate(0, 6), width: 16, height: 9), cat);
        canvas.drawCircle(p.translate(8, 1), 4.2, cat);
        canvas.drawPath(
            Path()
              ..moveTo(p.dx + 5, p.dy - 2)
              ..lineTo(p.dx + 6, p.dy - 7)
              ..lineTo(p.dx + 9, p.dy - 3)
              ..close(),
            cat);
      case M5Clue.earthPit:
        canvas.drawRect(Rect.fromCenter(center: p, width: 18, height: 8), Paint()..color = const Color(0xFFA6A39C));
        canvas.drawRect(Rect.fromCenter(center: p, width: 12, height: 4), Paint()..color = const Color(0xFF7E7A72));
      case M5Clue.tapePole:
        canvas.drawRect(Rect.fromCenter(center: p, width: 14, height: 8), Paint()..color = const Color(0xFF222428));
        canvas.drawLine(p.translate(6, 3), p.translate(10, 9), Paint()..color = const Color(0xFF222428)..strokeWidth = 1.4);
      case M5Clue.flagStall:
        canvas.drawLine(p.translate(0, 10), p.translate(0, -12), Paint()..color = const Color(0xFF5A4030)..strokeWidth = 1.4);
        canvas.drawRect(Rect.fromLTWH(p.dx, p.dy - 12, 12, 8), Paint()..color = const Color(0xFF2E8B57));
    }
  }

  @override
  bool shouldRepaint(M5CulpritPainter old) => old.geo != geo || !identical(old.view, view) || old.seed != seed;
}

/// A phone photo: the world around [centre], [zoom]× (the same painter), or
/// blurred when the shot was taken from too far.
class M5PhotoPainter extends CustomPainter {
  const M5PhotoPainter({required this.world, required this.height, required this.centre, this.span = 64, this.blurry = false});

  final M5CulpritPainter world;
  final double height;
  final Offset centre;

  /// The design px across the photo.
  final double span;
  final bool blurry;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final s = size.width / span;
    void draw(Offset nudge) {
      canvas.save();
      canvas.translate(size.width / 2 + nudge.dx, size.height / 2 + nudge.dy);
      canvas.scale(s);
      canvas.translate(-centre.dx, -centre.dy);
      world.paint(canvas, Size(360, height));
      canvas.restore();
    }

    if (blurry) {
      // A double, washed-out shot (no blur filter: a cheap ghost).
      draw(const Offset(-2.5, 0));
      canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0x66FFFFFF));
      canvas.saveLayer(Offset.zero & size, Paint()..color = const Color(0x80000000));
      draw(const Offset(2.5, 1.5));
      canvas.restore();
      canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0x55E8E8E8));
    } else {
      draw(Offset.zero);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(M5PhotoPainter old) =>
      old.centre != centre || old.blurry != blurry || old.span != span || old.world.shouldRepaint(world);
}

/// The phone's viewfinder on the scene: corner marks and the centre reticle.
class M5ViewfinderPainter extends CustomPainter {
  const M5ViewfinderPainter({required this.centre, required this.sharp});
  final Offset centre;

  /// Close enough for a sharp shot (the reticle turns from grey to white).
  final bool sharp;

  @override
  void paint(Canvas canvas, Size size) {
    final dim = Paint()..color = const Color(0x55000000);
    final frame = Rect.fromCenter(center: centre, width: 300, height: 220);
    canvas.drawPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(Offset.zero & size)
        ..addRRect(RRect.fromRectAndRadius(frame, const Radius.circular(18))),
      dim,
    );
    final mark = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;
    const l = 22.0;
    for (final c in [frame.topLeft, frame.topRight, frame.bottomLeft, frame.bottomRight]) {
      final sx = c.dx < centre.dx ? 1.0 : -1.0;
      final sy = c.dy < centre.dy ? 1.0 : -1.0;
      canvas.drawLine(c, c.translate(l * sx, 0), mark);
      canvas.drawLine(c, c.translate(0, l * sy), mark);
    }
    final ret = Paint()
      ..color = sharp ? Colors.white : const Color(0xAAFFFFFF)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(centre, 18, ret);
    canvas.drawLine(centre.translate(-26, 0), centre.translate(-10, 0), ret);
    canvas.drawLine(centre.translate(10, 0), centre.translate(26, 0), ret);
    canvas.drawLine(centre.translate(0, -26), centre.translate(0, -10), ret);
    canvas.drawLine(centre.translate(0, 10), centre.translate(0, 26), ret);
  }

  @override
  bool shouldRepaint(M5ViewfinderPainter old) => old.centre != centre || old.sharp != sharp;
}

/// The deadly consequence: an arc flash at the fault, in colour over the grey
/// scene ([v] 0 → 1).
class M5CulpritFlashPainter extends CustomPainter {
  const M5CulpritFlashPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas canvas, Size size) {
    if (v <= 0) return;
    final r = 20 + 70 * v;
    canvas.drawCircle(
      at,
      r,
      Paint()..shader = RadialGradient(colors: [const Color(0xFFFFFFFF), const Color(0xFFBFE4FF), const Color(0xFF4FA3FF).withValues(alpha: 0.5), const Color(0x004FA3FF)]).createShader(Rect.fromCircle(center: at, radius: r)),
    );
    final bolt = Paint()
      ..color = const Color(0xFFFFF6C8)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;
    final rnd = math.Random(7);
    for (var k = 0; k < 5; k++) {
      final path = Path()..moveTo(at.dx, at.dy);
      var p = at;
      final ang = k * math.pi * 2 / 5 + 0.4;
      for (var s = 0; s < 4; s++) {
        p = p + Offset(math.cos(ang) * 14 * v + rnd.nextDouble() * 8 - 4, math.sin(ang) * 14 * v + rnd.nextDouble() * 8 - 4);
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, bolt);
    }
  }

  @override
  bool shouldRepaint(M5CulpritFlashPainter old) => old.v != v || old.at != at;
}
