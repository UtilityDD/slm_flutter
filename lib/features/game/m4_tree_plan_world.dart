import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

// The place for lesson 4.8 কাজ 1 "কাটার আগে পরিকল্পনা" (m4_tree_plan.dart):
// a roadside stretch of line — an 11 kV line (three bare wires on cross-arms)
// or an LT এবি কেবিল — running across between two poles, a tree under it with
// some branches grown up into the wires, the verge, the road in front with
// people on it. The trainee stands on the verge; once the plan is made the
// cordon tape, the helper at the road with his flag and the earth leads on the
// pole (after শাটডাউন) show in the scene. Design space: 360 wide,
// [M4TreePlanGeo.height] high. Static painters only (they repaint when the
// play changes, never on a clock).

/// What line runs past the tree.
enum M4TreePlanWire { hv11, abLt }

/// One branch of the tree, relative to the fork at the top of the trunk
/// (design px). A branch that grows up to the line ([toward]) ends at the
/// lowest wire, whatever the sag there; the others end at ([dx], [dy]).
@immutable
class M4TreePlanBranch {
  const M4TreePlanBranch({required this.dx, required this.dy, required this.baseDy, required this.bend, required this.toward});
  final double dx;
  final double dy;

  /// Where it leaves the trunk (below the fork = positive).
  final double baseDy;

  /// The curve's bow, sideways (a fraction of its length).
  final double bend;
  final bool toward;

  M4TreePlanBranch mirrored() => M4TreePlanBranch(dx: -dx, dy: dy, baseDy: baseDy, bend: -bend, toward: toward);
}

/// The scene's geometry (design px).
@immutable
class M4TreePlanGeo {
  const M4TreePlanGeo._(this.height, this.groundY, this.wireY);

  factory M4TreePlanGeo.forScene(double height, double inset) {
    final ground = height - 172 - inset * 0.4;
    final wire = math.max(140.0, ground - 380);
    return M4TreePlanGeo._(height, ground, wire);
  }

  final double height;
  final double groundY;

  /// The top wire at the poles.
  final double wireY;

  static const poleL = 22.0;
  static const poleR = 338.0;

  /// The road in front of the verge.
  double get roadTop => groundY + 70;
  double get roadBottom => groundY + 130;

  /// The trainee's height on screen.
  double get man => 86;

  /// The fork at the top of the trunk.
  Offset forkOf(double treeX) => Offset(treeX, wireY + 140);

  /// The wire offsets below [wireY] at the poles (11 kV: three; LT এবি: one).
  static List<double> wiresOf(M4TreePlanWire w) => w == M4TreePlanWire.hv11 ? const [0, 8, 16] : const [10];

  /// A wire's height at [x] (sagging between the poles).
  double wireAt(double x, double offset) {
    final u = ((x - 180) / 158).clamp(-1.0, 1.0);
    return wireY + offset + 20 * (1 - u * u);
  }

  /// The lowest wire's height at [x].
  double lowWireAt(M4TreePlanWire w, double x) => wireAt(x, wiresOf(w).last);

  /// A branch's points: base (on the trunk), the curve's control, the tip.
  (Offset, Offset, Offset) branchOf(M4TreePlanBranch b, double treeX, M4TreePlanWire w) {
    final fork = forkOf(treeX);
    final base = fork + Offset(0, b.baseDy);
    final tipX = treeX + b.dx;
    final tip = b.toward ? Offset(tipX, lowWireAt(w, tipX) + 1) : fork + Offset(b.dx, b.dy);
    final mid = (base + tip) / 2;
    final d = tip - base;
    final ctrl = mid + Offset(-d.dy, d.dx) * b.bend;
    return (base, ctrl, tip);
  }

  /// Distance from [p] to the branch's curve.
  double distanceTo(Offset p, M4TreePlanBranch b, double treeX, M4TreePlanWire w) {
    final (a, c, t) = branchOf(b, treeX, w);
    var best = double.infinity;
    for (var i = 0; i <= 16; i++) {
      final s = i / 16;
      final q = a * ((1 - s) * (1 - s)) + c * (2 * s * (1 - s)) + t * (s * s);
      best = math.min(best, (q - p).distance);
    }
    return best;
  }

  /// The branch under a tap, or null (the nearest within 22 px).
  int? branchAt(Offset p, List<M4TreePlanBranch> bs, double treeX, M4TreePlanWire w, {Set<int> skip = const {}}) {
    int? hit;
    var best = 22.0;
    for (var i = 0; i < bs.length; i++) {
      if (skip.contains(i)) continue;
      final d = distanceTo(p, bs[i], treeX, w);
      if (d < best) {
        best = d;
        hit = i;
      }
    }
    return hit;
  }

  /// The cordon around the drop zone centred at [x].
  Rect cordonOf(double x) => Rect.fromLTRB(x - 70, groundY + 4, x + 70, groundY + 60);

  @override
  bool operator ==(Object other) => other is M4TreePlanGeo && other.height == height && other.groundY == groundY;

  @override
  int get hashCode => Object.hash(height, groundY);
}

void _quad(Canvas c, Offset a, Offset ctrl, Offset t, double w0, double w1, Color col) {
  // A tapering branch: several strokes thinning to the tip.
  const n = 6;
  for (var i = 0; i < n; i++) {
    final s0 = i / n;
    final s1 = (i + 1) / n;
    Offset at(double s) => a * ((1 - s) * (1 - s)) + ctrl * (2 * s * (1 - s)) + t * (s * s);
    c.drawLine(
      at(s0),
      at(s1),
      Paint()
        ..color = col
        ..strokeCap = StrokeCap.round
        ..strokeWidth = w0 + (w1 - w0) * (s0 + s1) / 2,
    );
  }
}

void _leaves(Canvas c, Offset at, double r, int seed, {double alpha = 1}) {
  final rnd = math.Random(seed);
  final dark = Paint()..color = Color.fromRGBO(46, 104, 52, alpha);
  final light = Paint()..color = Color.fromRGBO(92, 150, 70, alpha);
  for (var i = 0; i < 7; i++) {
    final o = Offset((rnd.nextDouble() - 0.5) * r * 1.6, (rnd.nextDouble() - 0.5) * r * 1.1);
    c.drawCircle(at + o, r * (0.45 + rnd.nextDouble() * 0.25), i.isEven ? dark : light);
  }
}

/// The stretch: sky, far fields, verge, road with people, the two poles and
/// the line; the cordon, the earth leads (shutdown taken).
class M4TreePlanWorldPainter extends CustomPainter {
  const M4TreePlanWorldPainter({required this.geo, required this.wire, required this.walkerX, this.cordonX, this.earthed = false});

  final M4TreePlanGeo geo;
  final M4TreePlanWire wire;

  /// Where the person on the road walks.
  final double walkerX;

  /// The cordon's centre, once set.
  final double? cordonX;

  /// The line is shut down, tested and earthed (leads on the left pole).
  final bool earthed;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final sky = Rect.fromLTWH(0, 0, 360, g.groundY);
    c.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6CA4D6), Color(0xFFBCDAEE), Color(0xFFEAF1E8)],
        ).createShader(sky),
    );
    final cloud = Paint()..color = const Color(0xCCFFFFFF);
    for (final (x, y, r) in [(70.0, g.wireY - 64, 18.0), (94.0, g.wireY - 58, 24.0), (118.0, g.wireY - 66, 16.0), (276.0, g.wireY - 96, 15.0), (298.0, g.wireY - 90, 21.0)]) {
      c.drawCircle(Offset(x, y), r, cloud);
    }
    // Far tree line and fields.
    final farPath = Path()..moveTo(0, g.groundY - 34);
    for (var x = 0.0; x <= 360; x += 30) {
      farPath.quadraticBezierTo(x + 15, g.groundY - 58 - (x % 90 == 0 ? 12 : 0), x + 30, g.groundY - 34);
    }
    farPath
      ..lineTo(360, g.groundY)
      ..lineTo(0, g.groundY)
      ..close();
    c.drawPath(farPath, Paint()..color = const Color(0xFF86A87C));
    // Verge.
    final verge = Rect.fromLTWH(0, g.groundY, 360, size.height - g.groundY);
    c.drawRect(
      verge,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8F9D5C), Color(0xFF6E7B45)],
        ).createShader(verge),
    );
    final peb = Paint()..color = const Color(0x55302A1A);
    final rnd = math.Random(5);
    for (var i = 0; i < 24; i++) {
      c.drawCircle(Offset(rnd.nextDouble() * 360, g.groundY + 6 + rnd.nextDouble() * 56), 1.2 + rnd.nextDouble() * 1.3, peb);
    }
    // The road.
    c.drawRect(Rect.fromLTRB(0, g.roadTop, 360, g.roadBottom), Paint()..color = const Color(0xFF5A5E66));
    c.drawRect(Rect.fromLTRB(0, g.roadTop, 360, g.roadTop + 3), Paint()..color = const Color(0xFF8A8D93));
    final dash = Paint()
      ..color = const Color(0xFFE8E2C8)
      ..strokeWidth = 3;
    for (var x = 8.0; x < 360; x += 44) {
      c.drawLine(Offset(x, g.roadTop + 32), Offset(x + 22, g.roadTop + 32), dash);
    }
    _walker(c, Offset(walkerX, g.roadTop + 50));

    // The poles and the line.
    for (final x in const [M4TreePlanGeo.poleL, M4TreePlanGeo.poleR]) {
      final pole = Path()
        ..moveTo(x - 5, g.wireY - 34)
        ..lineTo(x + 5, g.wireY - 34)
        ..lineTo(x + 8, g.groundY + 4)
        ..lineTo(x - 8, g.groundY + 4)
        ..close();
      c.drawPath(
        pole,
        Paint()..shader = const LinearGradient(colors: [Color(0xFFB9B5AA), Color(0xFF8E8A80)]).createShader(Rect.fromLTWH(x - 8, g.wireY, 16, g.groundY - g.wireY)),
      );
      if (wire == M4TreePlanWire.hv11) {
        c.drawRect(Rect.fromLTWH(x - 18, g.wireY - 6, 36, 5), Paint()..color = const Color(0xFF4F555C));
        for (final o in M4TreePlanGeo.wiresOf(wire)) {
          c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 3, g.wireY + o - 7, 6, 8), const Radius.circular(2)), Paint()..color = const Color(0xFFD9D2C3));
        }
      } else {
        c.drawRect(Rect.fromLTWH(x - 8, g.wireY + 4, 16, 6), Paint()..color = const Color(0xFF4F555C));
      }
    }
    final wirePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = wire == M4TreePlanWire.hv11 ? 1.8 : 5
      ..color = wire == M4TreePlanWire.hv11 ? const Color(0xFF3B3F46) : const Color(0xFF15171B);
    for (final o in M4TreePlanGeo.wiresOf(wire)) {
      final p = Path()..moveTo(M4TreePlanGeo.poleL, g.wireAt(M4TreePlanGeo.poleL, o));
      for (var x = M4TreePlanGeo.poleL; x <= M4TreePlanGeo.poleR; x += 8) {
        p.lineTo(x, g.wireAt(x, o));
      }
      c.drawPath(p, wirePaint);
    }
    if (earthed) {
      // Portable earth leads from each wire near the left pole to a rod.
      final lead = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = const Color(0xFFB8732E);
      final rod = Offset(M4TreePlanGeo.poleL + 22, g.groundY + 8);
      for (final o in M4TreePlanGeo.wiresOf(wire)) {
        final top = Offset(M4TreePlanGeo.poleL + 16, g.wireAt(M4TreePlanGeo.poleL + 16, o));
        c.drawCircle(top, 2.4, Paint()..color = const Color(0xFF2E7D32));
        c.drawPath(
          Path()
            ..moveTo(top.dx, top.dy)
            ..quadraticBezierTo(top.dx + 18, (top.dy + rod.dy) / 2, rod.dx, rod.dy - 4),
          lead,
        );
      }
      c.drawLine(rod, rod + const Offset(0, 10), Paint()
        ..strokeWidth = 3
        ..color = const Color(0xFF6B6F75));
    }
    final cx = cordonX;
    if (cx != null) _cordon(c, g.cordonOf(cx));
  }

  void _walker(Canvas c, Offset feet) {
    // A person walking on the road (and a cycle behind).
    final body = Paint()..color = const Color(0xFF7A3E8F);
    c.drawCircle(feet + const Offset(0, -38), 5, Paint()..color = const Color(0xFF9C6B47));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: feet + const Offset(0, -24), width: 11, height: 20), const Radius.circular(4)), body);
    final leg = Paint()
      ..color = const Color(0xFF2E2E36)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    c.drawLine(feet + const Offset(-1, -14), feet + const Offset(-5, 0), leg);
    c.drawLine(feet + const Offset(1, -14), feet + const Offset(5, 0), leg);
    final cyc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF22252B);
    final w = feet + Offset(feet.dx > 180 ? -70 : 60, -6);
    c.drawCircle(w, 7, cyc);
    c.drawCircle(w + const Offset(24, 0), 7, cyc);
    c.drawPath(
      Path()
        ..moveTo(w.dx, w.dy)
        ..lineTo(w.dx + 10, w.dy - 10)
        ..lineTo(w.dx + 24, w.dy)
        ..moveTo(w.dx + 10, w.dy - 10)
        ..lineTo(w.dx + 20, w.dy - 12),
      cyc,
    );
  }

  void _cordon(Canvas c, Rect r) {
    final post = Paint()..color = const Color(0xFF3A3F45);
    for (final p in [r.topLeft, r.topRight, r.bottomLeft, r.bottomRight]) {
      c.drawRect(Rect.fromLTWH(p.dx - 1.5, p.dy - 18, 3, 20), post);
    }
    void tape(Offset a, Offset b) {
      final len = (b - a).distance;
      final n = (len / 10).floor();
      for (var i = 0; i < n; i++) {
        c.drawLine(
          Offset.lerp(a, b, i / n)!,
          Offset.lerp(a, b, (i + 1) / n)!,
          Paint()
            ..strokeWidth = 3
            ..color = i.isEven ? const Color(0xFFD32F2F) : const Color(0xFFF5F5F5),
        );
      }
    }

    const up = Offset(0, -14);
    tape(r.topLeft + up, r.topRight + up);
    tape(r.topLeft + up, r.bottomLeft + up);
    tape(r.topRight + up, r.bottomRight + up);
    tape(r.bottomLeft + up, r.bottomRight + up);
  }

  @override
  bool shouldRepaint(M4TreePlanWorldPainter o) => o.geo != geo || o.wire != wire || o.walkerX != walkerX || o.cordonX != cordonX || o.earthed != earthed;
}

/// The tree: trunk, crown, the branches still on it (marked ones carry a
/// red-and-white ribbon).
class M4TreePlanTreePainter extends CustomPainter {
  const M4TreePlanTreePainter({
    required this.geo,
    required this.wire,
    required this.treeX,
    required this.branches,
    required this.big,
    required this.marked,
    required this.gone,
  });

  final M4TreePlanGeo geo;
  final M4TreePlanWire wire;
  final double treeX;
  final List<M4TreePlanBranch> branches;

  /// The branches grown into the line are thick (a chainsaw job).
  final bool big;
  final Set<int> marked;

  /// Cut and gone (they lie in the cordon).
  final Set<int> gone;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final fork = g.forkOf(treeX);
    const bark = Color(0xFF6B4A2E);
    // Trunk.
    final trunk = Path()
      ..moveTo(treeX - 13, g.groundY + 6)
      ..quadraticBezierTo(treeX - 9, (g.groundY + fork.dy) / 2, treeX - 6, fork.dy + 40)
      ..lineTo(treeX + 6, fork.dy + 40)
      ..quadraticBezierTo(treeX + 9, (g.groundY + fork.dy) / 2, treeX + 13, g.groundY + 6)
      ..close();
    c.drawPath(trunk, Paint()..color = bark);
    // The crown (well below the line).
    for (final (dx, dy, r) in [(-46.0, 4.0, 30.0), (40.0, 6.0, 30.0), (-10.0, -14.0, 34.0), (14.0, 26.0, 30.0), (-30.0, 34.0, 24.0)]) {
      _leaves(c, fork + Offset(dx, dy), r, (dx * 7 + dy).round());
    }
    for (var i = 0; i < branches.length; i++) {
      if (gone.contains(i)) continue;
      final b = branches[i];
      final (a, ctrl, t) = g.branchOf(b, treeX, wire);
      final thick = b.toward && big;
      _quad(c, a, ctrl, t, thick ? 9 : 5, thick ? 4 : 2, bark);
      _leaves(c, t + Offset(0, b.toward ? 6 : 0), b.toward ? 13 : 16, i * 31 + 7);
      if (marked.contains(i)) {
        // Ribbon tied near the middle.
        final s = 0.55;
        final m = a * ((1 - s) * (1 - s)) + ctrl * (2 * s * (1 - s)) + t * (s * s);
        c.drawCircle(m, 5, Paint()..color = const Color(0xFFD32F2F));
        c.drawCircle(m, 2.2, Paint()..color = const Color(0xFFFFFFFF));
        c.drawLine(m, m + const Offset(4, 11), Paint()
          ..strokeWidth = 2.4
          ..color = const Color(0xFFD32F2F));
        c.drawLine(m, m + const Offset(-3, 12), Paint()
          ..strokeWidth = 2.4
          ..color = const Color(0xFFF5F5F5));
      }
    }
    // The wires pass in front of the tips: redraw them over the tree.
    final wirePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = wire == M4TreePlanWire.hv11 ? 1.8 : 5
      ..color = wire == M4TreePlanWire.hv11 ? const Color(0xFF3B3F46) : const Color(0xFF15171B);
    for (final o in M4TreePlanGeo.wiresOf(wire)) {
      final p = Path()..moveTo(treeX - 130, g.wireAt(treeX - 130, o));
      for (var x = treeX - 130; x <= treeX + 130; x += 8) {
        p.lineTo(x, g.wireAt(x, o));
      }
      c.drawPath(p, wirePaint);
    }
  }

  @override
  bool shouldRepaint(M4TreePlanTreePainter o) =>
      o.geo != geo || o.wire != wire || o.treeX != treeX || o.big != big || o.marked.length != marked.length || o.gone.length != gone.length || !identical(o.branches, branches);
}

/// The cut branches coming down into the cordon ([v] 0 → 1, then lying).
class M4TreePlanFallPainter extends CustomPainter {
  const M4TreePlanFallPainter({
    required this.geo,
    required this.wire,
    required this.treeX,
    required this.branches,
    required this.cut,
    required this.dropX,
    required this.big,
    required this.v,
  });

  final M4TreePlanGeo geo;
  final M4TreePlanWire wire;
  final double treeX;
  final List<M4TreePlanBranch> branches;
  final List<int> cut;
  final double dropX;
  final bool big;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final e = Curves.easeIn.transform(v.clamp(0.0, 1.0));
    for (var k = 0; k < cut.length; k++) {
      final b = branches[cut[k]];
      final (a, ctrl, t) = geo.branchOf(b, treeX, wire);
      // They come to rest inside the cordon (dropX ± 70).
      final lieA = Offset(dropX - 58 + 28 * k, geo.groundY + 34 + 7 * k);
      final lieT = lieA + const Offset(46, -4);
      final pa = Offset.lerp(a, lieA, e)!;
      final pt = Offset.lerp(t, lieT, e)!;
      final pc = Offset.lerp(ctrl, (lieA + lieT) / 2 + const Offset(0, -6), e)!;
      _quad(c, pa, pc, pt, big ? 9 : 5, big ? 4 : 2, const Color(0xFF6B4A2E));
      _leaves(c, pt, 13, cut[k] * 31 + 7);
      if (v < 0.25) {
        // The cut: a few chips at the base.
        final chip = Paint()..color = const Color(0xFFE2C48E);
        for (var i = 0; i < 4; i++) {
          c.drawCircle(a + Offset(-6.0 + 4 * i, 4.0 + 3 * i * v * 8), 1.6, chip);
        }
      }
    }
  }

  @override
  bool shouldRepaint(M4TreePlanFallPainter o) => o.v != v || o.dropX != dropX || o.cut.length != cut.length;
}

/// The flash where a branch touches the live wire ([v] 0 → 1).
class M4TreePlanArcPainter extends CustomPainter {
  const M4TreePlanArcPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final r = 10 + 40 * v;
    c.drawCircle(
      at,
      r * 1.6,
      Paint()
        ..shader = ui.Gradient.radial(at, r * 1.6, const [Color(0xCCFFF6C8), Color(0x66FFB020), Color(0x00FFB020)], const [0, 0.45, 1]),
    );
    c.drawCircle(at, r * 0.35, Paint()..color = const Color(0xFFFFFFFF));
    final bolt = Paint()
      ..color = const Color(0xFFFFE066)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    final rnd = math.Random(11);
    for (var i = 0; i < 6; i++) {
      final ang = i * math.pi / 3 + rnd.nextDouble() * 0.5;
      var p = at;
      for (var k = 0; k < 3; k++) {
        final q = p + Offset(math.cos(ang + (k.isEven ? 0.4 : -0.4)), math.sin(ang + (k.isEven ? 0.4 : -0.4))) * (r * 0.4);
        c.drawLine(p, q, bolt);
        p = q;
      }
    }
  }

  @override
  bool shouldRepaint(M4TreePlanArcPainter o) => o.v != v || o.at != at;
}

/// Safety goggles over the trainee's eyes (drawn in his box).
class M4TreePlanGogglesPainter extends CustomPainter {
  const M4TreePlanGogglesPainter();

  @override
  void paint(Canvas c, Size s) {
    final band = RRect.fromRectAndRadius(Rect.fromLTWH(0, s.height * 0.3, s.width, s.height * 0.42), Radius.circular(s.height * 0.2));
    c.drawRRect(band, Paint()..color = const Color(0xCC1B2A3A));
    c.drawRRect(
      band.deflate(1.2),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFF9FD3FF),
    );
  }

  @override
  bool shouldRepaint(M4TreePlanGogglesPainter o) => false;
}

/// The helper's red flag (traffic), held up.
class M4TreePlanFlagPainter extends CustomPainter {
  const M4TreePlanFlagPainter();

  @override
  void paint(Canvas c, Size s) {
    c.drawLine(Offset(s.width * 0.1, s.height), Offset(s.width * 0.1, 0), Paint()
      ..strokeWidth = 2.2
      ..color = const Color(0xFF5B4630));
    c.drawPath(
      Path()
        ..moveTo(s.width * 0.1, 1)
        ..lineTo(s.width, s.height * 0.18)
        ..lineTo(s.width * 0.1, s.height * 0.38)
        ..close(),
      Paint()..color = const Color(0xFFE53935),
    );
  }

  @override
  bool shouldRepaint(M4TreePlanFlagPainter o) => false;
}
