import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart' show banglaFont;

// The drawn world of lesson 6.8 কাজ 2 "তার ধরে সোর্সের দিকে"
// (m6_upstream_trace.dart): a daytime panorama two and a half screens wide.
// At one end the substation fence with two feeder bays; from them two 11 kV
// lines run side by side on their own poles. Ours: the main line (its
// recloser just outside the fence, or at a junction pole where a spur leaves),
// a junction where the branch line drops off, the branch's sectionalizer on
// its first pole, a fork where a decoy spur leaves (some plays through its own
// cut-out fuse), the tap pole where a cut-out fuse feeds the sub-line, and the
// work pole on that sub-line (its number plate). The neighbour feeder runs
// above or below ours, and its recloser stands nearest the work pole — it is
// not wired to it. The wires of both feeders look the same; nothing on the
// scene marks the path. Code-drawn, gradients, no bitmaps.
//
// Text in the art: only what a worker reads — the recloser plates ('R-12'),
// the feeder tag under each plate, the work pole's plate, the substation sign.
//
// Design: world [kM6UtWorldW] wide × the scene's height; the camera shows a
// 360-wide window of it. The panorama is laid out with the source on the left
// and mirrored (x → W − x) on half the plays.

/// The panorama's width in design px (about two and a half screens; a margin
/// beyond the work pole keeps it clear of the corner guide).
const double kM6UtWorldW = 960;

/// The screen's width in design px.
const double kM6UtViewW = 360;

/// The rows the wires run on.
enum M6UtRow { nbrTop, main, branch, work, nbrLow }

/// The devices a flag can hang on.
enum M6UtDevKind { recloser, nbrRecloser, sectionalizer, fuse }

/// A pole top (a node of the wire network).
@immutable
class M6UtNode {
  const M6UtNode(this.x, this.row, {this.feeder = 0});

  /// World x (already mirrored where the play is mirrored).
  final double x;
  final M6UtRow row;

  /// 0 = ours, 1 = the neighbour feeder.
  final int feeder;
}

/// A device on a pole.
@immutable
class M6UtDevice {
  const M6UtDevice(this.kind, this.node);
  final M6UtDevKind kind;
  final int node;
}

/// The wire network of one job (both feeders; they never meet).
@immutable
class M6UtMap {
  const M6UtMap({
    required this.nodes,
    required this.edges,
    required this.work,
    required this.source,
    required this.sNode,
    required this.rNode,
    required this.fuseNode,
    required this.nbrSource,
    required this.nbrRNode,
    required this.devices,
    required this.mirrored,
    required this.nbrAbove,
    required this.rNearSource,
    required this.decoySpur,
    required this.decoyFuse,
    required this.workFar,
    required this.junctionAt,
  });

  final List<M6UtNode> nodes;
  final List<(int, int)> edges;

  /// The work pole, our source gantry, the sectionalizer's pole, our
  /// recloser's pole, the tap pole with the work line's cut-out fuse.
  final int work;
  final int source;
  final int sNode;
  final int rNode;
  final int fuseNode;
  final int nbrSource;
  final int nbrRNode;
  final List<M6UtDevice> devices;

  // The deal (kept for tests and the variety check).
  final bool mirrored;
  final bool nbrAbove;
  final bool rNearSource;
  final bool decoySpur;
  final bool decoyFuse;
  final bool workFar;
  final int junctionAt;

  /// The poles wired to [i].
  List<int> neighbours(int i) => [
        for (final (a, b) in edges)
          if (a == i) b else if (b == i) a,
      ];

  /// The poles from the work pole to our source, in order (the right trace).
  List<int> upstreamPath() {
    final prev = <int, int>{work: -1};
    final queue = [work];
    while (queue.isNotEmpty) {
      final n = queue.removeAt(0);
      if (n == source) break;
      for (final c in neighbours(n)) {
        if (!prev.containsKey(c)) {
          prev[c] = n;
          queue.add(c);
        }
      }
    }
    final path = <int>[];
    for (var n = source; n != -1; n = prev[n]!) {
      path.insert(0, n);
    }
    return path;
  }

  /// The device on pole [n], if any.
  M6UtDevice? deviceAt(int n) {
    for (final d in devices) {
      if (d.node == n) return d;
    }
    return null;
  }
}

/// Builds one job's network (source on the left, then mirrored if asked).
///
/// Ours — main: the gantry, poles every 90 px, the junction (index 5) where
/// the branch drops off, on to a downstream end. A spur leaves the main line
/// at pole [junctionAt] (2 or 3); the recloser stands on pole 1 (just outside
/// the fence) or on that junction pole. Branch: the sectionalizer's pole, a
/// pole where a decoy spur may leave (with its own fuse on some plays), the
/// tap pole (the cut-out fuse for the sub-line), on to the branch's end.
/// Sub-line: one or two spans to the work pole. The neighbour feeder: its own
/// gantry and poles, its recloser nearest the work pole, never wired to ours.
M6UtMap m6UtBuildMap({
  required bool mirrored,
  required bool nbrAbove,
  required bool rNearSource,
  required int junctionAt,
  required bool decoySpur,
  required bool decoyFuse,
  required bool workFar,
}) {
  assert(junctionAt == 2 || junctionAt == 3);
  double mx(double x) => mirrored ? kM6UtWorldW - x : x;
  final nodes = <M6UtNode>[];
  final edges = <(int, int)>[];
  int add(double x, M6UtRow row, {int feeder = 0}) {
    nodes.add(M6UtNode(mx(x), row, feeder: feeder));
    return nodes.length - 1;
  }

  void wire(int a, int b) => edges.add((a, b));

  // Our main line.
  final main = [for (var i = 0; i < 10; i++) add(40 + 90.0 * i, M6UtRow.main)];
  for (var i = 0; i < main.length - 1; i++) {
    wire(main[i], main[i + 1]);
  }
  // The junction spur off the main line.
  final jx = 40 + 90.0 * junctionAt;
  final k1 = add(jx + 50, M6UtRow.branch);
  final k2 = add(jx + 108, M6UtRow.work);
  wire(main[junctionAt], k1);
  wire(k1, k2);
  // The branch line from the junction (main pole 5).
  final s = add(545, M6UtRow.branch);
  final b1 = add(620, M6UtRow.branch);
  final tap = add(695, M6UtRow.branch);
  final b3 = add(770, M6UtRow.branch);
  final bEnd = add(845, M6UtRow.branch);
  wire(main[5], s);
  wire(s, b1);
  wire(b1, tap);
  wire(tap, b3);
  wire(b3, bEnd);
  // The decoy spur off the branch.
  if (decoySpur) {
    final d1 = add(588, M6UtRow.work);
    final d2 = add(530, M6UtRow.work);
    wire(b1, d1);
    wire(d1, d2);
  }
  // The sub-line through the cut-out fuse to the work pole.
  final w1 = add(742, M6UtRow.work);
  var work = w1;
  wire(tap, w1);
  if (workFar) {
    work = add(800, M6UtRow.work);
    wire(w1, work);
  }
  // The neighbour feeder.
  final nRow = nbrAbove ? M6UtRow.nbrTop : M6UtRow.nbrLow;
  // Its poles stand clear of ours (no pole of one feeder looks like it
  // carries the other).
  final nbr = [for (final x in _nbrX) add(x, nRow, feeder: 1)];
  for (var i = 0; i < nbr.length - 1; i++) {
    wire(nbr[i], nbr[i + 1]);
  }
  // Its recloser stands nearest the work pole.
  final nbrR = nbr[8];

  final rNode = rNearSource ? main[1] : main[junctionAt];
  return M6UtMap(
    nodes: nodes,
    edges: edges,
    work: work,
    source: main[0],
    sNode: s,
    rNode: rNode,
    fuseNode: tap,
    nbrSource: nbr[0],
    nbrRNode: nbrR,
    devices: [
      M6UtDevice(M6UtDevKind.recloser, rNode),
      M6UtDevice(M6UtDevKind.sectionalizer, s),
      M6UtDevice(M6UtDevKind.fuse, tap),
      if (decoySpur && decoyFuse) M6UtDevice(M6UtDevKind.fuse, b1),
      M6UtDevice(M6UtDevKind.nbrRecloser, nbrR),
    ],
    mirrored: mirrored,
    nbrAbove: nbrAbove,
    rNearSource: rNearSource,
    decoySpur: decoySpur,
    decoyFuse: decoyFuse,
    workFar: workFar,
    junctionAt: junctionAt,
  );
}

/// The neighbour feeder's poles (unmirrored x): its gantry beside ours in the
/// yard, its recloser on the ninth.
const _nbrX = [14.0, 100.0, 178.0, 248.0, 380.0, 462.0, 560.0, 640.0, 712.0, 860.0];

/// Where things are (design px; world x, screen y).
@immutable
class M6UtGeo {
  const M6UtGeo._(this.height, this.groundY);

  factory M6UtGeo.forScene(double height, double inset) => M6UtGeo._(height, height - groundUp - inset * 0.5);

  final double height;

  /// The ground line (pole feet).
  final double groundY;

  /// The ground sits this far above the bottom (the PTT row stands under it).
  static const double groundUp = 118;

  /// How far the camera can pan.
  static const double camMax = kM6UtWorldW - kM6UtViewW;

  /// The wire height of a row.
  double rowY(M6UtRow r) => switch (r) {
        M6UtRow.nbrTop => height * 0.27,
        M6UtRow.main => height * 0.35,
        M6UtRow.branch => height * 0.45,
        M6UtRow.work => height * 0.55,
        M6UtRow.nbrLow => height * 0.64,
      };

  /// A pole top (where the wire sits).
  Offset node(M6UtMap m, int i) {
    final n = m.nodes[i];
    return Offset(n.x, rowY(n.row));
  }

  /// The wire's sag at mid-span.
  static const double sag = 6;

  /// A point on the span from [a] to [b] at [t] (a slight sag).
  static Offset span(Offset a, Offset b, double t) => Offset.lerp(a, b, t)! + Offset(0, sag * 4 * t * (1 - t));

  /// Where a device's tap box is (around its body on the pole).
  Rect deviceRect(M6UtMap m, M6UtDevice d) {
    final p = node(m, d.node);
    return switch (d.kind) {
      M6UtDevKind.recloser || M6UtDevKind.nbrRecloser => Rect.fromLTWH(p.dx - 27, p.dy + 2, 54, 66),
      M6UtDevKind.sectionalizer => Rect.fromLTWH(p.dx - 24, p.dy + 2, 48, 52),
      M6UtDevKind.fuse => Rect.fromLTWH(p.dx - 24, p.dy - 4, 48, 52),
    };
  }

  /// Where the flag hangs on a device (its top-left).
  Offset flagAt(M6UtMap m, M6UtDevice d) => node(m, d.node) + const Offset(10, 6);

  /// The docket (a widget, fixed on the screen, top right).
  static const Rect docket = Rect.fromLTWH(266, 134, 86, 92);

  /// The radio log (fixed on the screen, top left).
  static const Rect radio = Rect.fromLTWH(8, 134, 250, 92);

  /// The trainee at the work pole's foot (on the side away from the source).
  Rect trainee(M6UtMap m) {
    final p = node(m, m.work);
    final left = m.mirrored ? p.dx - 52 : p.dx + 8;
    return Rect.fromLTWH(left, groundY - 104, 44, 104);
  }

  /// The climbing boot's home (beside the pole's foot, on the source side,
  /// clear of the corner guide) and the pole step.
  Offset bootHome(M6UtMap m) {
    final p = node(m, m.work);
    return Offset(p.dx + (m.mirrored ? 24 : -24), groundY - 14);
  }

  Offset step(M6UtMap m) => Offset(node(m, m.work).dx, groundY - 76);

  /// The boot's grab box at [at].
  static Rect bootRect(Offset at) => Rect.fromCenter(center: at, width: 48, height: 40);

  /// The boot lands on the step within this reach.
  static const double stepReach = 30;

  /// Where the deadly flash comes off (the work pole's top).
  Offset flashAt(M6UtMap m) => node(m, m.work) + const Offset(0, -4);

  /// The crew's isolation at the work section (ruling X1, shown after a safe
  /// climb, no scoring): the sub-line opened just below the cut-out, the
  /// tester's hook on the wire by the work pole, an earth on the span on the
  /// source side and one off the work pole on the far side.
  M6UtCrewSpots crew(M6UtMap m) {
    final path = m.upstreamPath();
    final w = node(m, m.work);
    final u = node(m, path[1]);
    final at = path.indexOf(m.fuseNode);
    final sub = node(m, path[at - 1]);
    final away = m.mirrored ? -1.0 : 1.0;
    return M6UtCrewSpots(
      isolate: span(node(m, m.fuseNode), sub, 0.3),
      earthA: span(u, w, 0.72),
      earthB: w + Offset(away * 12, 2),
      earthBFoot: Offset(w.dx + away * 30, groundY),
      testerTip: span(u, w, 0.86),
      testerFoot: Offset(w.dx - away * 44, groundY - 6),
      away: away,
    );
  }


  @override
  bool operator ==(Object other) => other is M6UtGeo && other.height == height && other.groundY == groundY;

  @override
  int get hashCode => Object.hash(height, groundY);
}

/// Where the crew's isolation, tester and earths are drawn (world px).
@immutable
class M6UtCrewSpots {
  const M6UtCrewSpots({
    required this.isolate,
    required this.earthA,
    required this.earthB,
    required this.earthBFoot,
    required this.testerTip,
    required this.testerFoot,
    required this.away,
  });
  final Offset isolate;
  final Offset earthA;
  final Offset earthB;
  final Offset earthBFoot;
  final Offset testerTip;
  final Offset testerFoot;

  /// +1 when the far side (away from the source) is to the right.
  final double away;

  /// Where the tester's 0 V window sits (low on its stick).
  Offset get testerWindow => Offset.lerp(testerFoot, testerTip, 0.22)!;
}

/// The numbers on the plates.
@immutable
class M6UtPlates {
  const M6UtPlates({required this.feeder, required this.recloser, required this.nbrFeeder, required this.nbrRecloser, required this.pole});
  final int feeder;
  final int recloser;
  final int nbrFeeder;
  final int nbrRecloser;
  final int pole;
}

/// The camera (world x at the screen's left) that puts the work pole in view.
double m6UtCamForWork(M6UtMap m) => (m.nodes[m.work].x - 160).clamp(0.0, M6UtGeo.camMax);

String m6UtPlate(int n) => 'R-${n.toString().padLeft(2, '0')}';
String m6UtPolePlate(int n) => 'P-$n';

// ============================================================================
// Painters
// ============================================================================

/// The still world: sky, far fields, the substation, every pole and wire of
/// both feeders, the devices. Painted once per job and scene size.
class M6UtWorldPainter extends CustomPainter {
  M6UtWorldPainter({required this.geo, required this.map, required this.plates});
  final M6UtGeo geo;
  final M6UtMap map;
  final M6UtPlates plates;

  static const _wire = Color(0xFF2A2E33);
  static const _poleLight = Color(0xFF8E8A82);
  static const _poleDark = Color(0xFF6B675F);

  @override
  void paint(Canvas c, Size size) {
    final h = geo.height;
    final g = geo.groundY;
    // Sky.
    c.drawRect(
      Rect.fromLTWH(0, 0, kM6UtWorldW, g),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6FA8DC), Color(0xFFB9DAF2), Color(0xFFE6F1E4)],
        ).createShader(Rect.fromLTWH(0, 0, kM6UtWorldW, g)),
    );
    // Clouds (still).
    final cloud = Paint()..color = const Color(0xCCFFFFFF);
    for (final (x, y, r) in const [(110.0, 0.16, 18.0), (380.0, 0.13, 22.0), (640.0, 0.18, 16.0), (820.0, 0.12, 20.0)]) {
      for (final (dx, dr) in const [(-1.0, 0.75), (0.0, 1.0), (1.0, 0.8)]) {
        c.drawCircle(Offset(x + dx * r * 1.1, h * y), r * dr, cloud);
      }
    }
    // Far tree line.
    final far = Paint()..color = const Color(0xFF8DB48A);
    final farPath = Path()..moveTo(0, g - 40);
    for (var x = 0.0; x <= kM6UtWorldW; x += 30) {
      farPath.quadraticBezierTo(x + 15, g - 62 - 10 * math.sin(x / 47), x + 30, g - 40);
    }
    farPath
      ..lineTo(kM6UtWorldW, g)
      ..lineTo(0, g)
      ..close();
    c.drawPath(farPath, far);
    // Ground.
    c.drawRect(
      Rect.fromLTWH(0, g, kM6UtWorldW, h - g),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF7DAA5A), Color(0xFF557F3B)],
        ).createShader(Rect.fromLTWH(0, g, kM6UtWorldW, h - g)),
    );
    final path = Paint()..color = const Color(0xFFC8B48A);
    c.drawRect(Rect.fromLTWH(0, g + 14, kM6UtWorldW, 10), path);
    _substation(c);
    // Poles, back rows first (higher rows are further back).
    final order = [for (var i = 0; i < map.nodes.length; i++) i]..sort((a, b) => geo.rowY(map.nodes[a].row).compareTo(geo.rowY(map.nodes[b].row)));
    for (final i in order) {
      if (i == map.source || i == map.nbrSource) continue;
      _drawPole(c, i);
    }
    // Wires.
    final wp = Paint()
      ..color = _wire
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    for (final (a, b) in map.edges) {
      final pa = geo.node(map, a);
      final pb = geo.node(map, b);
      final pth = Path()..moveTo(pa.dx, pa.dy);
      for (var k = 1; k <= 12; k++) {
        final q = M6UtGeo.span(pa, pb, k / 12);
        pth.lineTo(q.dx, q.dy);
      }
      c.drawPath(pth, wp);
    }
    // Ends of the lines (a dead-end mark on the last pole is the pole itself).
    for (final d in map.devices) {
      switch (d.kind) {
        case M6UtDevKind.recloser:
          _recloser(c, d.node, plates.recloser, plates.feeder);
        case M6UtDevKind.nbrRecloser:
          _recloser(c, d.node, plates.nbrRecloser, plates.nbrFeeder);
        case M6UtDevKind.sectionalizer:
          _sectionalizer(c, d.node);
        case M6UtDevKind.fuse:
          _fuse(c, d.node);
      }
    }
    _workPlate(c);
  }

  void _drawPole(Canvas c, int i) {
    final p = geo.node(map, i);
    final back = map.nodes[i].row == M6UtRow.nbrTop || map.nodes[i].row == M6UtRow.main;
    final w = back ? 5.0 : 6.5;
    final r = Rect.fromLTRB(p.dx - w / 2, p.dy - 10, p.dx + w / 2, geo.groundY + 4);
    c.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(colors: [_poleLight, Color(0xFFB9B4AA), _poleDark]).createShader(r),
    );
    // Crossarm and pin insulator.
    c.drawRect(Rect.fromCenter(center: p.translate(0, -2), width: 26, height: 3.5), Paint()..color = const Color(0xFF5A5650));
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: p.translate(0, -6), width: 6, height: 8), const Radius.circular(2)),
      Paint()..color = const Color(0xFF9A5A3A),
    );
  }

  void _substation(Canvas c) {
    final g = geo.groundY;
    final srcX = map.nodes[map.source].x;
    final left = map.mirrored ? kM6UtWorldW - 70 : 0.0;
    final yard = Rect.fromLTWH(left, g - 70, 70, 74);
    // Gravel yard and fence.
    c.drawRect(yard, Paint()..color = const Color(0xFFB8B3A8));
    final fence = Paint()
      ..color = const Color(0xFF6E737A)
      ..strokeWidth = 1.2;
    for (var x = yard.left; x <= yard.right; x += 6) {
      c.drawLine(Offset(x, g - 30), Offset(x, g + 4), fence);
    }
    c.drawLine(Offset(yard.left, g - 30), Offset(yard.right, g - 30), fence..strokeWidth = 2);
    // A power transformer.
    final tx = Rect.fromLTWH(yard.left + 12, g - 58, 30, 30);
    c.drawRRect(
      RRect.fromRectAndRadius(tx, const Radius.circular(3)),
      Paint()..shader = const LinearGradient(colors: [Color(0xFF7D8C80), Color(0xFF55635A)]).createShader(tx),
    );
    // Two gantries (ours and the neighbour's bay).
    for (final s in [map.source, map.nbrSource]) {
      final p = geo.node(map, s);
      final gp = Paint()
        ..color = const Color(0xFF5E646C)
        ..strokeWidth = 3;
      c.drawLine(Offset(p.dx - 12, p.dy), Offset(p.dx - 12, g), gp);
      c.drawLine(Offset(p.dx + 12, p.dy), Offset(p.dx + 12, g), gp);
      c.drawLine(Offset(p.dx - 16, p.dy), Offset(p.dx + 16, p.dy), gp..strokeWidth = 4);
    }
    // The sign.
    final sign = Rect.fromLTWH(srcX - 30, g - 22, 60, 14);
    c.drawRect(sign, Paint()..color = const Color(0xFFF2EEE2));
    _text(c, 'সাবস্টেশন', sign.center, 7.5, const Color(0xFF2A2A2A));
  }

  void _recloser(Canvas c, int n, int plate, int feeder) {
    final p = geo.node(map, n);
    // The tank hanging under the crossarm, three bushings on top.
    final tank = Rect.fromLTWH(p.dx - 15, p.dy + 8, 30, 30);
    for (var k = -1; k <= 1; k++) {
      c.drawRect(Rect.fromLTWH(p.dx + k * 9 - 2, p.dy + 1, 4, 8), Paint()..color = const Color(0xFF9A5A3A));
    }
    c.drawRRect(
      RRect.fromRectAndRadius(tank, const Radius.circular(5)),
      Paint()..shader = const LinearGradient(colors: [Color(0xFFB7BEC5), Color(0xFF7D868F)]).createShader(tank),
    );
    // The plate.
    final pl = Rect.fromCenter(center: tank.center.translate(0, 2), width: 26, height: 11);
    c.drawRect(pl, Paint()..color = const Color(0xFFFFFFFF));
    _text(c, m6UtPlate(plate), pl.center, 7.5, const Color(0xFF1A1A1A), bold: true);
    // The feeder tag under it and the control box lower on the pole.
    final tag = Rect.fromCenter(center: Offset(p.dx, tank.bottom + 8), width: 34, height: 10);
    c.drawRect(tag, Paint()..color = const Color(0xFFFFF4C8));
    _text(c, 'ফিডার $feeder', tag.center, 6.5, const Color(0xFF3A2A10));
    final box = Rect.fromLTWH(p.dx - 9, tank.bottom + 16, 18, 14);
    c.drawLine(Offset(p.dx + 6, tank.bottom), Offset(p.dx + 6, box.top), Paint()
      ..color = const Color(0xFF333333)
      ..strokeWidth = 1.2);
    c.drawRect(box, Paint()..color = const Color(0xFF8A939B));
    c.drawRect(box, Paint()
      ..color = const Color(0xFF4A5056)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);
  }

  void _sectionalizer(Canvas c, int n) {
    final p = geo.node(map, n);
    for (var k = -1; k <= 1; k++) {
      c.drawRect(Rect.fromLTWH(p.dx + k * 7 - 1.5, p.dy + 1, 3, 7), Paint()..color = const Color(0xFF9A5A3A));
    }
    final body = Rect.fromLTWH(p.dx - 12, p.dy + 8, 24, 22);
    c.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(9)),
      Paint()..shader = const LinearGradient(colors: [Color(0xFFB0B8BE), Color(0xFF79828A)]).createShader(body),
    );
    c.drawLine(body.centerLeft.translate(3, 0), body.centerRight.translate(-3, 0), Paint()
      ..color = const Color(0x66333A40)
      ..strokeWidth = 1);
  }

  void _fuse(Canvas c, int n) {
    final p = geo.node(map, n);
    final dir = map.mirrored ? -1.0 : 1.0;
    // A cut-out on a bracket: porcelain body and the fuse tube at a slant.
    final base = p.translate(10 * dir, 8);
    c.drawLine(p.translate(0, 4), base, Paint()
      ..color = const Color(0xFF5A5650)
      ..strokeWidth = 2.5);
    c.save();
    c.translate(base.dx, base.dy);
    c.rotate(0.35 * dir);
    c.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(-4, 0, 8, 30), const Radius.circular(3)),
      Paint()..color = const Color(0xFF9A5A3A),
    );
    c.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(3, 3, 5, 24), const Radius.circular(2)),
      Paint()..color = const Color(0xFF3A3A36),
    );
    c.restore();
  }

  void _workPlate(Canvas c) {
    final p = geo.node(map, map.work);
    final pl = Rect.fromCenter(center: Offset(p.dx, geo.groundY - 46), width: 28, height: 12);
    c.drawRect(pl, Paint()..color = const Color(0xFFFFFFFF));
    c.drawRect(pl, Paint()
      ..color = const Color(0xFF333333)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8);
    _text(c, m6UtPolePlate(plates.pole), pl.center, 7, const Color(0xFF1A1A1A), bold: true);
    // The step bolt the boot goes on.
    final s = geo.step(map);
    c.drawRect(Rect.fromCenter(center: s, width: 16, height: 4), Paint()..color = const Color(0xFF4A4640));
  }

  static void _text(Canvas c, String s, Offset at, double size, Color color, {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontFamily: banglaFont,
          fontFamilyFallback: const ['Roboto', 'Noto Sans'],
          fontSize: size,
          color: color,
          fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, at - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(M6UtWorldPainter old) => old.geo != geo || !identical(old.map, map) || old.plates != plates;
}

/// The chalk along the traced wire (on-wire only) and its head.
class M6UtChalkPainter extends CustomPainter {
  M6UtChalkPainter({required this.points, required Listenable repaint}) : super(repaint: repaint);

  /// The chalk's points, from the work pole to the head (world px).
  final List<Offset> Function() points;

  @override
  void paint(Canvas c, Size size) {
    final pts = points();
    if (pts.isEmpty) return;
    if (pts.length > 1) {
      final pth = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (final q in pts.skip(1)) {
        pth.lineTo(q.dx, q.dy);
      }
      c.drawPath(
        pth,
        Paint()
          ..color = const Color(0x66FFFFFF)
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke,
      );
      c.drawPath(
        pth,
        Paint()
          ..color = const Color(0xFFFFFBEA)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke,
      );
    }
    // The head: where the finger holds the wire.
    final head = pts.last;
    c.drawCircle(head, 7, Paint()..color = const Color(0x55FFFFFF));
    c.drawCircle(head, 4, Paint()..color = const Color(0xFFFFFBEA));
  }

  @override
  bool shouldRepaint(M6UtChalkPainter old) => true;
}

/// The red Non-Reclose flag (a widget-sized painter).
class M6UtFlagPainter extends CustomPainter {
  const M6UtFlagPainter();

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    c.drawLine(Offset(1.5, 0), Offset(1.5, h), Paint()
      ..color = const Color(0xFF3A3A3A)
      ..strokeWidth = 2);
    final cloth = Path()
      ..moveTo(3, 1)
      ..lineTo(w, h * 0.2)
      ..lineTo(3, h * 0.48)
      ..close();
    c.drawPath(
      cloth,
      Paint()..shader = const LinearGradient(colors: [Color(0xFFE53935), Color(0xFFB71C1C)]).createShader(Rect.fromLTWH(0, 0, w, h)),
    );
  }

  @override
  bool shouldRepaint(M6UtFlagPainter old) => false;
}

/// The climbing boot (a widget-sized painter).
class M6UtBootPainter extends CustomPainter {
  const M6UtBootPainter({this.flip = false});
  final bool flip;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    if (flip) {
      c.translate(w, 0);
      c.scale(-1, 1);
    }
    final boot = Path()
      ..moveTo(w * 0.22, h * 0.08)
      ..lineTo(w * 0.52, h * 0.08)
      ..lineTo(w * 0.56, h * 0.58)
      ..lineTo(w * 0.92, h * 0.68)
      ..lineTo(w * 0.94, h * 0.9)
      ..lineTo(w * 0.18, h * 0.9)
      ..close();
    c.drawPath(boot, Paint()..shader = const LinearGradient(colors: [Color(0xFF6D4C2F), Color(0xFF3E2A18)]).createShader(Offset.zero & size));
    c.drawRect(Rect.fromLTWH(w * 0.16, h * 0.88, w * 0.8, h * 0.08), Paint()..color = const Color(0xFF1E1E1E));
  }

  @override
  bool shouldRepaint(M6UtBootPainter old) => old.flip != flip;
}

/// The line comes back while the trainee is on the pole: an arc at the top.
class M6UtFlashPainter extends CustomPainter {
  const M6UtFlashPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final r = 30 + 90 * v;
    c.drawCircle(
      at,
      r,
      Paint()
        ..shader = RadialGradient(colors: [
          Color.fromRGBO(255, 255, 240, 0.95 * (1 - v * 0.4)),
          Color.fromRGBO(120, 190, 255, 0.6 * (1 - v * 0.5)),
          const Color(0x00000000),
        ]).createShader(Rect.fromCircle(center: at, radius: r)),
    );
    final bolt = Paint()
      ..color = Color.fromRGBO(255, 255, 255, 1 - v * 0.6)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final rnd = math.Random(7);
    for (var k = 0; k < 6; k++) {
      final a = k * math.pi / 3 + 0.3;
      final pth = Path()..moveTo(at.dx, at.dy);
      var q = at;
      for (var s = 0; s < 4; s++) {
        q = q + Offset(math.cos(a + (rnd.nextDouble() - 0.5)), math.sin(a + (rnd.nextDouble() - 0.5))) * (8 + 14 * v);
        pth.lineTo(q.dx, q.dy);
      }
      c.drawPath(pth, bolt);
    }
  }

  @override
  bool shouldRepaint(M6UtFlashPainter old) => old.v != v || old.at != at;
}

/// The crew's isolation at the work section (ruling X1): in [v] 0..1 the
/// sub-line opens, then the tester shows dead, then the earths go on.
class M6UtCrewPainter extends CustomPainter {
  const M6UtCrewPainter({required this.spots, required this.groundY, required this.v});
  final M6UtCrewSpots spots;
  final double groundY;
  final double v;

  /// Stage [i] of 3 (0..1).
  double _st(int i) => ((v * 3) - i).clamp(0.0, 1.0);

  @override
  void paint(Canvas c, Size size) {
    final a = _st(0), b = _st(1), e = _st(2);
    final sp = spots;
    // 1. The isolation: the line opened (a gap with a raised blade).
    if (a > 0) {
      final o = sp.isolate;
      c.drawCircle(o, 11, Paint()..color = Color.fromRGBO(255, 255, 255, 0.85 * a));
      final blade = Paint()
        ..color = Color.fromRGBO(40, 40, 40, a)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      c.drawLine(o + const Offset(-7, 0), o + Offset(5, -9 * a), blade);
      c.drawCircle(o + const Offset(7, 0), 2.5, Paint()..color = Color.fromRGBO(40, 40, 40, a));
      c.drawCircle(o + const Offset(-7, 0), 2.5, Paint()..color = Color.fromRGBO(40, 40, 40, a));
    }
    // 2. The tester on its stick, hooked on the wire, its window green (0 V).
    if (b > 0) {
      final stick = Paint()
        ..color = Color.fromRGBO(214, 168, 40, b)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      final tip = Offset.lerp(sp.testerFoot, sp.testerTip, b)!;
      c.drawLine(sp.testerFoot, tip, stick);
      final win = sp.testerWindow;
      c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromCenter(center: win, width: 14, height: 18), const Radius.circular(3)),
        Paint()..color = Color.fromRGBO(30, 30, 30, b),
      );
      c.drawCircle(win, 4, Paint()..color = Color.fromRGBO(70, 200, 90, b));
    }
    // 3. The earths: a lead off each side down to a rod in the ground.
    if (e > 0) {
      final lead = Paint()
        ..color = Color.fromRGBO(60, 140, 60, e)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;
      final clamp = Paint()..color = Color.fromRGBO(180, 120, 40, e);
      void earth(Offset top, Offset foot) {
        final pth = Path()
          ..moveTo(top.dx, top.dy)
          ..quadraticBezierTo((top.dx + foot.dx) / 2 + 8 * sp.away, (top.dy + foot.dy) / 2, foot.dx, foot.dy);
        c.drawPath(pth, lead);
        c.drawCircle(top, 3.5, clamp);
        final rod = Paint()
          ..color = Color.fromRGBO(120, 120, 120, e)
          ..strokeWidth = 3;
        c.drawLine(foot, foot + const Offset(0, 10), rod);
        c.drawLine(foot + const Offset(-6, 0), foot + const Offset(6, 0), rod);
      }

      earth(sp.earthA, Offset(sp.earthA.dx - 24 * sp.away, groundY));
      earth(sp.earthB, sp.earthBFoot);
    }
  }

  @override
  bool shouldRepaint(M6UtCrewPainter old) => old.v != v || old.spots != spots || old.groundY != groundY;
}
