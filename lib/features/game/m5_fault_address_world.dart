import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

// The drawn world of lesson 5.2 কাজ 1 "ফল্টের ঠিকানা" (m5_fault_address.dart):
// an aerial-oblique feeder landscape in the morning haze that pans with the
// patrol van. The substation stands at the source end (left, or right on a
// mirrored call), the 11 kV main line runs on short poles beside a village
// road through paddy to the load end (a village with its DTR); one or two
// T-offs branch away north across the fields (one may run under a mango grove
// that hides its poles; other groves stand over the road with no line under
// them, so a grove alone tells nothing). FPI boxes hang on some poles — every
// box looks the same, its LED is seen only in the close-up; a sectionalizer
// sits on one pole in some calls. The road carries the van (and a second van
// on a long call). Code-drawn, gradients, no bitmaps; no text in the world
// except the substation's sign (the sectionalizer close-up reads 'খোলা').
//
// Design: 360 wide × the scene's height; the world is wider than the screen
// and the camera follows the van (world px − camera = scene px).

/// The kind of call.
enum M5FaKind { trip, long, sectionalizer }

/// Where the van is when the call comes in.
enum M5FaStart { depot, mid, loadEnd }

/// A T-off: a branch line leaving the main line at path position [s].
@immutable
class M5FaBranch {
  const M5FaBranch({required this.s, required this.grove, required this.lean});

  /// The junction on the main line (path position from the substation).
  final double s;

  /// A mango grove hides the branch's poles (it shows only on the map card).
  final bool grove;

  /// The branch leans a little as it runs away north (x drift per px up).
  final double lean;
}

/// A device on the feeder: an FPI box (or the sectionalizer).
@immutable
class M5FaNode {
  const M5FaNode({required this.id, required this.s, required this.order, required this.pole, this.branch, this.sectionalizer = false});

  /// Index in [M5FaCall.nodes].
  final int id;

  /// Path position on the main line (a branch device: its junction).
  final double s;

  /// Main line: 0, 1, 2 … from the substation. Branch: 1 (by the junction), 2.
  final int order;

  /// The pole number a worker reads.
  final String pole;

  /// null = on the main line; else the branch index.
  final int? branch;
  final bool sectionalizer;

  bool get main => branch == null;
}

/// One call: the feeder, its devices, the fault and where the van starts.
@immutable
class M5FaCall {
  const M5FaCall({
    required this.kind,
    required this.template,
    required this.length,
    required this.mirrored,
    required this.nodes,
    required this.branches,
    required this.faultAfter,
    required this.faultNext,
    required this.start,
    required this.startS,
    required this.feeder,
    required this.docket,
  });

  final M5FaKind kind;

  /// The route template it was dealt from.
  final int template;

  /// The main line's length (design px, substation 0 → load end).
  final double length;

  /// The substation is on the right.
  final bool mirrored;

  /// Main-line devices first (by s), then branch devices.
  final List<M5FaNode> nodes;
  final List<M5FaBranch> branches;

  /// The faulty section: from device [faultAfter] (fault current passed) to
  /// the next device on the same path, [faultNext] (it did not).
  final int faultAfter;
  final int faultNext;

  final M5FaStart start;

  /// The van's path position when the call starts.
  final double startS;
  final int feeder;
  final int docket;

  List<M5FaNode> get mains => [for (final n in nodes) if (n.main) n];
  List<M5FaNode> branchNodes(int k) => [for (final n in nodes) if (n.branch == k) n];
  M5FaNode get sourceFirst => mains.first;
  M5FaNode get loadLast => mains.last;
  bool get faultOnBranch => !nodes[faultAfter].main;
  bool get inService => kind == M5FaKind.sectionalizer;
  M5FaNode? get sectionalizerNode {
    for (final n in nodes) {
      if (n.sectionalizer) return n;
    }
    return null;
  }

  /// The device saw the fault current (an FPI's LED is lit; the sectionalizer
  /// has opened).
  bool lit(M5FaNode n) {
    final a = nodes[faultAfter];
    if (!a.main) {
      if (n.main) return n.s < branches[a.branch!].s;
      return n.branch == a.branch && n.order <= a.order;
    }
    if (!n.main) return false;
    return n.s <= a.s;
  }

  /// Where the fault is drawn on the map after the bracket (path position or
  /// a branch's).
  Set<int> get faultPair => {faultAfter, faultNext};
}

/// Path positions of the decoy groves on [call]: mango groves that reach the
/// road like the one over a grove T-off, but with no line under them. Kept
/// clear of every device and visible T-off (they hide nothing), apart from
/// each other; 1–2 on a short feeder, 2–3 on a long one.
List<double> m5FaDecoyGroves(M5FaCall call, int seed) {
  final rng = math.Random(seed * 17 + call.feeder * 5 + call.docket);
  final stops = [
    for (final n in call.mains) (n.s, 95.0),
    for (final b in call.branches) (b.s, b.grove ? 150.0 : 115.0),
  ];
  final spots = [
    for (var s = 30.0; s <= call.length - 30; s += 10)
      if (stops.every((t) => (s - t.$1).abs() >= t.$2)) s,
  ]..shuffle(rng);
  final want = (call.kind == M5FaKind.long ? 2 : 1) + rng.nextInt(2);
  final out = <double>[];
  for (final s in spots) {
    if (out.length >= want) break;
    if (out.every((o) => (o - s).abs() >= 200)) out.add(s);
  }
  return out..sort();
}

/// Where things are (design px; world x = scene x + camera).
@immutable
class M5FaGeo {
  const M5FaGeo._(this.height, this.lineY, this.call);

  factory M5FaGeo.forScene(double height, double inset, M5FaCall call) =>
      M5FaGeo._(height, math.max(300.0, (height - inset * 0.5) * 0.56), call);

  final double height;

  /// The main line's height on screen (the poles stand beside the road).
  final double lineY;
  final M5FaCall call;

  /// World margin before the substation and after the load end.
  static const double margin = 96;

  /// A van this close (path px) to a device's pole stands beside it.
  static const double besideRange = 40;

  /// The van snaps to a pole this close after a drag.
  static const double snapRange = 52;

  /// The van runs this many path px per scene px of finger travel.
  static const double dragGain = 1.8;

  double get roadY => lineY + 40;
  double get vanY => roadY + 4;
  double get worldWidth => call.length + 2 * margin;
  double get maxCamera => math.max(0, worldWidth - 360);

  /// World x of path position [s].
  double x(double s) => call.mirrored ? margin + call.length - s : margin + s;

  /// +1 when the load end is to the right.
  double get dir => call.mirrored ? -1 : 1;

  /// The branch poles' heights above the line (by order) and its end.
  static const List<double> branchUp = [0, 62, 132];
  double get branchEndY => math.max(118.0, lineY - 196);

  /// A branch's point at [up] px above the line.
  Offset branchAt(M5FaBranch b, double up) => Offset(x(b.s) + b.lean * up, lineY - up);

  /// The device box on its pole.
  Offset nodeAt(M5FaNode n) => n.main ? Offset(x(n.s), lineY - 6) : branchAt(call.branches[n.branch!], branchUp[n.order]);

  /// Tap area of a device (world px).
  Rect nodeHit(M5FaNode n) => Rect.fromCenter(center: nodeAt(n), width: 46, height: 50);

  /// The van on the road (world px).
  Offset vanAt(double s) => Offset(x(s), vanY);
  Rect vanHit(double s) => Rect.fromCenter(center: vanAt(s), width: 70, height: 42);

  /// The camera that keeps the van at [s] inside the middle of the screen,
  /// moving as little as it can from [cam].
  double follow(double s, double cam) {
    final vx = x(s);
    var c = cam;
    if (vx - c > 250) c = vx - 250;
    if (vx - c < 110) c = vx - 110;
    return c.clamp(0.0, maxCamera);
  }

  /// The camera centred on the van at [s].
  double centre(double s) => (x(s) - 180).clamp(0.0, maxCamera);

  /// The van's travel on the road (path px).
  double get minS => -44;
  double get maxS => call.length + 44;

  @override
  bool operator ==(Object other) => other is M5FaGeo && other.height == height && other.lineY == lineY && identical(other.call, call);

  @override
  int get hashCode => Object.hash(height, lineY, identityHashCode(call));
}

const _wire = Color(0xFF2E343A);
const _poleC = Color(0xFF8A8F94);
const _box = Color(0xFF7E8C99);

/// The feeder landscape with the camera at [cam]: fields, the road, the
/// substation, the line and its T-offs, the devices (all alike), the houses,
/// the van(s), the read marks (the player's chalk on the device) and the flags.
class M5FaWorldPainter extends CustomPainter {
  M5FaWorldPainter({
    required this.geo,
    required this.cam,
    required this.vanS,
    required this.van2S,
    required this.reads,
    required this.flags,
    required this.seed,
    this.drive,
    this.van2From,
    this.van2To,
    this.peek = const {},
  }) : super(repaint: drive);

  final M5FaGeo geo;
  final double cam;
  final double vanS;

  /// The second van (long call), or null.
  final double? van2S;

  /// Read devices → lit.
  final Map<int, bool> reads;

  /// Devices carrying a bracket flag.
  final List<int> flags;
  final int seed;

  /// The second van driving off to the far end (0..1), with its ends.
  final Animation<double>? drive;
  final double? van2From;
  final double? van2To;

  /// Grove T-offs (branch index) whose boxes show faintly through the canopy:
  /// the van is parked beside the junction.
  final Set<int> peek;

  M5FaCall get call => geo.call;

  double? get _van2Now {
    final d = drive;
    if (d != null && d.isAnimating && van2From != null && van2To != null) {
      return van2From! + (van2To! - van2From!) * Curves.easeInOut.transform(d.value);
    }
    return van2S;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    _sky(canvas, h);
    _fields(canvas, h);
    canvas.save();
    canvas.translate(-cam, 0);
    _road(canvas);
    _clumps(canvas);
    _houses(canvas);
    _substation(canvas);
    _village(canvas);
    _line(canvas);
    for (final (k, b) in call.branches.indexed) {
      _branch(canvas, k, b);
    }
    for (final n in call.nodes) {
      if (n.main) _device(canvas, n);
    }
    for (final s in m5FaDecoyGroves(call, seed)) {
      _groveAt(canvas, s, _decoyLean(s), seed * 7 + s.round());
    }
    for (final (k, b) in call.branches.indexed) {
      if (!b.grove) continue;
      _grove(canvas, b);
      if (peek.contains(k)) _peek(canvas, k);
    }
    for (final n in call.nodes) {
      final lit = reads[n.id];
      if (lit != null) _readMark(canvas, geo.nodeAt(n), lit);
    }
    for (final id in flags) {
      _flag(canvas, geo.nodeAt(call.nodes[id]));
    }
    final v2 = _van2Now;
    if (v2 != null) _van(canvas, v2, second: true);
    _van(canvas, vanS, second: false);
    canvas.restore();
  }

  void _sky(Canvas canvas, double h) {
    final top = h * 0.17;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, 360, top),
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF9CC3E2), Color(0xFFE6EEE6)]).createShader(Rect.fromLTWH(0, 0, 360, top)),
    );
    // Far tree line and hazy hills (slow parallax).
    final far = cam * 0.25;
    final hill = Path()..moveTo(0, top);
    for (var x = 0.0; x <= 360; x += 12) {
      hill.lineTo(x, top - 8 - 6 * math.sin((x + far) / 47) - 4 * math.sin((x + far) / 19));
    }
    hill
      ..lineTo(360, top + 2)
      ..lineTo(0, top + 2)
      ..close();
    canvas.drawPath(hill, Paint()..color = const Color(0xFF8FAF8A));
  }

  void _fields(Canvas canvas, double h) {
    final top = h * 0.17;
    final rect = Rect.fromLTWH(0, top, 360, h - top);
    canvas.drawRect(
      rect,
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF9DBE6E), Color(0xFF6E9A47)]).createShader(rect),
    );
    // Paddy rows: horizontal bands that widen toward the viewer.
    final row = Paint()..color = const Color(0x1A1F3D0E);
    var y = top + 6;
    var gap = 7.0;
    while (y < h) {
      canvas.drawRect(Rect.fromLTWH(0, y, 360, gap * 0.35), row);
      y += gap;
      gap *= 1.06;
    }
    // Field bunds (move with the ground).
    final bund = Paint()
      ..color = const Color(0x557A6A3E)
      ..strokeWidth = 2;
    const step = 132.0;
    final first = -((cam % step));
    for (var x = first; x < 360 + step; x += step) {
      canvas.drawLine(Offset(x + 30, top + 4), Offset(x - 20, h), bund);
    }
  }

  void _road(Canvas canvas) {
    final y = geo.roadY;
    final w = geo.worldWidth;
    canvas.drawRect(Rect.fromLTWH(0, y - 13, w, 30), Paint()..color = const Color(0xFFB59C70));
    canvas.drawRect(
      Rect.fromLTWH(0, y - 9, w, 22),
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8F8A80), Color(0xFF6E6A62)]).createShader(Rect.fromLTWH(0, y - 9, w, 22)),
    );
    final dash = Paint()
      ..color = const Color(0xCCE9E1C8)
      ..strokeWidth = 1.6;
    final c0 = (cam / 28).floor() * 28.0;
    for (var x = c0; x < cam + 380; x += 28) {
      canvas.drawLine(Offset(x, y + 2), Offset(x + 13, y + 2), dash);
    }
  }

  bool _onScreen(double x, [double pad = 60]) => x > cam - pad && x < cam + 360 + pad;

  /// Tree clumps and bushes in the fields — mango groves with no line under
  /// them as well, so a grove alone never tells where a T-off is.
  void _clumps(Canvas canvas) {
    final rng = math.Random(seed * 13 + call.feeder * 3 + call.length.round());
    final top = geo.branchEndY + 10;
    for (var x = 20.0; x < geo.worldWidth - 20; x += 150 + rng.nextInt(130)) {
      final far = rng.nextBool();
      final y = far ? top + 20 + rng.nextDouble() * 40 : geo.lineY - 110 - rng.nextDouble() * 30;
      final cx = x + rng.nextDouble() * 40;
      // Keep the clumps off the lines you can see (the grove T-off is under
      // trees anyway, so clumps may stand by it like anywhere else).
      if (call.branches.any((b) => !b.grove && (geo.x(b.s) - cx).abs() < 70)) continue;
      if (!_onScreen(cx, 80)) continue;
      // A big one is as tall and dense as the grove over a T-off.
      final big = rng.nextDouble() < 0.5;
      _clump(canvas, Offset(cx, y), big ? 18 + rng.nextInt(9) : 3 + rng.nextInt(3), rng, tall: big ? 70.0 : 22.0);
    }
    // Bushes by the road.
    final bush = Paint()..color = const Color(0xFF4E7F37);
    for (var x = 10.0; x < geo.worldWidth; x += 40 + rng.nextInt(70)) {
      if (!_onScreen(x, 20)) continue;
      canvas.drawOval(Rect.fromCenter(center: Offset(x, geo.roadY - 17), width: 14, height: 7), bush);
    }
  }

  void _clump(Canvas canvas, Offset at, int n, math.Random rng, {required double tall}) {
    final dark = Paint()..color = const Color(0xFF2F5E2B);
    final mid = Paint()..color = const Color(0xFF3C7434);
    final light = Paint()..color = const Color(0xFF4F8A40);
    for (var i = 0; i < n; i++) {
      final p = at.translate(-34 + rng.nextDouble() * 68, -tall + rng.nextDouble() * (tall + 22));
      final r = 12 + rng.nextDouble() * 9;
      canvas.drawCircle(p.translate(0, 3), r, dark);
      canvas.drawCircle(p, r * 0.86, mid);
      canvas.drawCircle(p.translate(-r * 0.25, -r * 0.3), r * 0.4, light);
    }
  }

  /// Huts along the road's south side (lit windows on an in-service line,
  /// upstream of the sectionalizer that opened).
  void _houses(Canvas canvas) {
    final rng = math.Random(seed * 31 + call.feeder);
    final sect = call.sectionalizerNode;
    for (var s = 40.0; s < call.length - 20; s += 70 + rng.nextInt(60)) {
      final x = geo.x(s);
      final big = rng.nextBool();
      if (!_onScreen(x)) continue;
      final lit = call.inService && sect != null && s < sect.s;
      _hut(canvas, Offset(x, geo.roadY + 34 + rng.nextInt(18)), big ? 1.15 : 0.9, lit);
    }
  }

  void _hut(Canvas canvas, Offset at, double k, bool lit) {
    final w = 30 * k;
    final h = 16 * k;
    final body = Rect.fromLTWH(at.dx - w / 2, at.dy - h, w, h);
    canvas.drawRect(body, Paint()..color = const Color(0xFFD9C7A1));
    final roof = Path()
      ..moveTo(at.dx - w / 2 - 4, at.dy - h)
      ..lineTo(at.dx - w / 2 + 6, at.dy - h - 11 * k)
      ..lineTo(at.dx + w / 2 - 6, at.dy - h - 11 * k)
      ..lineTo(at.dx + w / 2 + 4, at.dy - h)
      ..close();
    canvas.drawPath(roof, Paint()..color = const Color(0xFF8A5A3C));
    final win = Paint()..color = lit ? const Color(0xFFFFD86B) : const Color(0xFF4A4E55);
    canvas.drawRect(Rect.fromLTWH(at.dx - w / 2 + 5, at.dy - h + 4 * k, 6 * k, 6 * k), win);
    canvas.drawRect(Rect.fromLTWH(at.dx + w / 2 - 11 * k, at.dy - h + 4 * k, 6 * k, 6 * k), win);
  }

  void _substation(Canvas canvas) {
    final x = geo.x(-44);
    if (!_onScreen(x, 120)) return;
    final yard = Rect.fromCenter(center: Offset(x, geo.lineY - 24), width: 78, height: 62);
    canvas.drawRect(yard, Paint()..color = const Color(0xFFC9C5B8));
    // Fence.
    canvas.drawRect(
      yard,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = const Color(0xFF6B6F73),
    );
    // Power transformers and the gantry.
    for (final dx in [-20.0, 8.0]) {
      final t = Rect.fromLTWH(x + dx, geo.lineY - 40, 20, 22);
      canvas.drawRRect(
        RRect.fromRectAndRadius(t, const Radius.circular(2)),
        Paint()..shader = const LinearGradient(colors: [Color(0xFF7D8C7A), Color(0xFF4F5D4C)]).createShader(t),
      );
    }
    final gantry = Paint()
      ..color = const Color(0xFF5B6168)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(x - 32, geo.lineY - 50), Offset(x + 32, geo.lineY - 50), gantry);
    canvas.drawLine(Offset(x - 30, geo.lineY - 50), Offset(x - 30, geo.lineY - 10), gantry);
    canvas.drawLine(Offset(x + 30, geo.lineY - 50), Offset(x + 30, geo.lineY - 10), gantry);
    final tp = TextPainter(
      text: TextSpan(text: 'সাবস্টেশন', style: bangla(fontSize: 9, fontWeight: FontWeight.w800, color: const Color(0xFF1B2433), height: 1.1)),
      textDirection: TextDirection.ltr,
    )..layout();
    final sign = Rect.fromCenter(center: Offset(x, yard.bottom + 10), width: tp.width + 10, height: 14);
    canvas.drawRRect(RRect.fromRectAndRadius(sign, const Radius.circular(3)), Paint()..color = const Color(0xFFF2EBD3));
    tp.paint(canvas, Offset(sign.left + 5, sign.top + 1));
  }

  void _village(Canvas canvas) {
    final x = geo.x(call.length + 50);
    if (!_onScreen(x, 120)) return;
    for (final (dx, dy, k) in [(-26.0, -40.0, 0.9), (4.0, -52.0, 1.0), (24.0, -30.0, 1.1), (-6.0, -20.0, 0.8)]) {
      _hut(canvas, Offset(x + dx, geo.lineY + dy), k, false);
    }
    _palm(canvas, Offset(x + 40, geo.lineY - 10));
  }

  void _palm(Canvas canvas, Offset at) {
    canvas.drawLine(at, at.translate(2, -30), Paint()
      ..color = const Color(0xFF6B4E2E)
      ..strokeWidth = 2.4);
    final leaf = Paint()..color = const Color(0xFF3F7A3A);
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi / 3;
      canvas.drawOval(Rect.fromCenter(center: at.translate(2 + 8 * math.cos(a), -30 + 4 * math.sin(a)), width: 16, height: 6), leaf);
    }
  }

  void _pole(Canvas canvas, Offset top, {double height = 22}) {
    canvas.drawLine(top, top.translate(0, height), Paint()
      ..color = _poleC
      ..strokeWidth = 2.6);
    canvas.drawLine(top.translate(-6, 2), top.translate(6, 2), Paint()
      ..color = const Color(0xFF6A6F74)
      ..strokeWidth = 1.8);
  }

  void _line(Canvas canvas) {
    final y = geo.lineY - 10;
    final a = geo.x(-8);
    final b = geo.x(call.length + 30);
    final wire = Paint()
      ..color = _wire
      ..strokeWidth = 0.9;
    for (final dy in [0.0, 2.6, 5.2]) {
      canvas.drawLine(Offset(a, y + dy), Offset(b, y + dy), wire);
    }
    // Poles every ~58 px, and one under every main-line device.
    for (var s = 0.0; s <= call.length + 10; s += 58) {
      final x = geo.x(s);
      if (_onScreen(x)) _pole(canvas, Offset(x, y - 2));
    }
    for (final n in call.mains) {
      final x = geo.x(n.s);
      if (_onScreen(x)) _pole(canvas, Offset(x, y - 2));
    }
  }

  void _branch(Canvas canvas, int k, M5FaBranch b) {
    final j = geo.branchAt(b, 0);
    final top = geo.branchEndY;
    final end = geo.branchAt(b, geo.lineY - top);
    if (!_onScreen(math.min(j.dx, end.dx), 80) && !_onScreen(math.max(j.dx, end.dx), 80)) return;
    final wire = Paint()
      ..color = _wire
      ..strokeWidth = 0.9;
    for (final d in [0.0, 2.6]) {
      canvas.drawLine(j.translate(d, -10), end.translate(d, -8), wire);
    }
    for (var up = 30.0; up < geo.lineY - top; up += 34) {
      final p = geo.branchAt(b, up);
      _pole(canvas, p.translate(0, -10), height: 16);
    }
    // The hamlet at its end, with its DTR (lit on an in-service line when the
    // T-off leaves before the open sectionalizer).
    final sect = call.sectionalizerNode;
    final lit = call.inService && sect != null && b.s < sect.s;
    _hut(canvas, end.translate(-14, 4), 0.75, lit);
    _hut(canvas, end.translate(14, 10), 0.85, lit);
    for (final n in call.branchNodes(k)) {
      _device(canvas, n);
    }
  }

  /// An FPI box (all alike) or the sectionalizer, on its pole.
  void _device(Canvas canvas, M5FaNode n) {
    final c = geo.nodeAt(n);
    if (!_onScreen(c.dx)) return;
    if (!n.main) _pole(canvas, c.translate(0, -12), height: 22);
    if (n.sectionalizer) {
      final r = Rect.fromCenter(center: c.translate(0, 4), width: 13, height: 21);
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(4)),
        Paint()..shader = const LinearGradient(colors: [Color(0xFF5D6670), Color(0xFF2F363D)]).createShader(r),
      );
      canvas.drawRect(Rect.fromCenter(center: c.translate(0, 2), width: 5, height: 4), Paint()..color = const Color(0xFF8B949C));
      return;
    }
    final r = Rect.fromCenter(center: c.translate(0, 5), width: 15, height: 17);
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(2.5)),
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFA9B5C0), _box]).createShader(r),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(2.5)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0xFF55616C),
    );
    canvas.drawCircle(c.translate(0, 6), 3.2, Paint()..color = const Color(0xFF3B4148));
  }

  /// A mango grove: a dense canopy over the branch near the road.
  void _grove(Canvas canvas, M5FaBranch b) => _groveAt(canvas, b.s, b.lean, seed * 7 + b.s.round());

  /// A decoy grove's lean (the same range as a branch's).
  double _decoyLean(double s) => (math.Random(seed * 11 + s.round()).nextDouble() * 2 - 1) * 0.16;

  /// A grove canopy from the road at path position [s] up to the branch
  /// ends, drifting by [lean] (every grove is drawn the same way).
  void _groveAt(Canvas canvas, double s, double lean, int rngSeed) {
    final base = Offset(geo.x(s), geo.lineY);
    if (!_onScreen(base.dx, 100)) return;
    final rng = math.Random(rngSeed);
    final dark = Paint()..color = const Color(0xFF2F5E2B);
    final mid = Paint()..color = const Color(0xFF3C7434);
    final light = Paint()..color = const Color(0xFF4F8A40);
    final top = geo.lineY - geo.branchEndY + 6;
    for (var i = 0; i < 34; i++) {
      final up = 14 + rng.nextDouble() * top;
      final p = Offset(base.dx + lean * up, geo.lineY - up).translate(-40 + rng.nextDouble() * 80, 0);
      final r = 14 + rng.nextDouble() * 10;
      canvas.drawCircle(p.translate(0, 3), r, dark);
      canvas.drawCircle(p, r * 0.86, mid);
      canvas.drawCircle(p.translate(-r * 0.25, -r * 0.3), r * 0.4, light);
    }
  }

  /// The grove T-off's boxes (and their poles), faint through the canopy.
  void _peek(Canvas canvas, int k) {
    final nodes = call.branchNodes(k);
    if (nodes.isEmpty) return;
    var r = geo.nodeHit(nodes.first);
    for (final n in nodes.skip(1)) {
      r = r.expandToInclude(geo.nodeHit(n));
    }
    canvas.saveLayer(r.inflate(12), Paint()..color = const Color(0x8C000000));
    for (final n in nodes) {
      _device(canvas, n);
    }
    canvas.restore();
  }

  /// The player's chalk on a read device: lit = a bright yellow dot; not = a
  /// grey ring.
  void _readMark(Canvas canvas, Offset c, bool lit) {
    final at = c.translate(10, -10);
    if (lit) {
      canvas.drawCircle(at, 6.5, Paint()..color = const Color(0x66FFE27A));
      canvas.drawCircle(at, 4.2, Paint()..color = const Color(0xFFFFD23F));
    } else {
      canvas.drawCircle(at, 4.6, Paint()..color = const Color(0xFFE9ECEF));
      canvas.drawCircle(at, 2.6, Paint()..color = const Color(0xFF59616A));
    }
  }

  void _flag(Canvas canvas, Offset c) {
    final foot = c.translate(-12, 14);
    canvas.drawLine(foot, foot.translate(0, -34), Paint()
      ..color = const Color(0xFF3A2E22)
      ..strokeWidth = 1.8);
    final cloth = Path()
      ..moveTo(foot.dx, foot.dy - 34)
      ..lineTo(foot.dx - 15, foot.dy - 28)
      ..lineTo(foot.dx, foot.dy - 22)
      ..close();
    canvas.drawPath(cloth, Paint()..color = const Color(0xFFE53935));
  }

  /// The patrol van (oblique from above), its nose toward the load end.
  void _van(Canvas canvas, double s, {required bool second}) {
    final c = geo.vanAt(s);
    if (!_onScreen(c.dx, 80)) return;
    canvas.save();
    canvas.translate(c.dx, c.dy);
    if (geo.dir < 0) canvas.scale(-1, 1);
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, 9), width: 52, height: 10), Paint()..color = const Color(0x44000000));
    final body = RRect.fromRectAndCorners(const Rect.fromLTWH(-24, -12, 46, 20), topLeft: const Radius.circular(4), topRight: const Radius.circular(9), bottomLeft: const Radius.circular(3), bottomRight: const Radius.circular(3));
    canvas.drawRRect(
      body,
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFFFFFF), Color(0xFFC9CED4)]).createShader(const Rect.fromLTWH(-24, -12, 46, 20)),
    );
    canvas.drawRect(const Rect.fromLTWH(-24, -2, 46, 4), Paint()..color = second ? const Color(0xFF1E6FD0) : const Color(0xFFF08A1C));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(8, -10, 11, 7), const Radius.circular(2)), Paint()..color = const Color(0xFF5E7C96));
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-12, -16, 20, 5), const Radius.circular(2)), Paint()..color = const Color(0xFF9AA2AA));
    final tyre = Paint()..color = const Color(0xFF22262A);
    canvas.drawCircle(const Offset(-14, 8), 3.6, tyre);
    canvas.drawCircle(const Offset(12, 8), 3.6, tyre);
    canvas.restore();
  }

  @override
  bool shouldRepaint(M5FaWorldPainter old) =>
      old.geo != geo ||
      old.cam != cam ||
      old.vanS != vanS ||
      old.van2S != van2S ||
      !mapEquals(old.reads, reads) ||
      !listEquals(old.flags, flags) ||
      old.seed != seed ||
      old.drive != drive ||
      old.van2From != van2From ||
      old.van2To != van2To ||
      !setEquals(old.peek, peek);
}

/// The close-up of a device: an FPI box with its LED (bright and flashing, or
/// dark), or the sectionalizer with its window. [v] runs 0 → 1 once.
class M5FaCloseUpPainter extends CustomPainter {
  const M5FaCloseUpPainter({required this.lit, required this.sectionalizer, required this.v});
  final bool lit;
  final bool sectionalizer;
  final double v;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    // The pole behind.
    canvas.drawRect(Rect.fromCenter(center: c, width: 26, height: size.height), Paint()..color = const Color(0xFF9A9FA4));
    if (sectionalizer) {
      final r = Rect.fromCenter(center: c, width: 74, height: 118);
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(22)),
        Paint()..shader = const LinearGradient(colors: [Color(0xFF6E7883), Color(0xFF2E353C)]).createShader(r),
      );
      final win = Rect.fromCenter(center: c.translate(0, -12), width: 46, height: 26);
      canvas.drawRRect(RRect.fromRectAndRadius(win, const Radius.circular(4)), Paint()..color = const Color(0xFFDDE3E8));
      final tp = TextPainter(
        // The sectionalizer in this level has always opened (it is the
        // bracket's first end).
        text: TextSpan(text: 'খোলা', style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: const Color(0xFF1B7A3A), height: 1.1)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, win.center - Offset(tp.width / 2, tp.height / 2));
      return;
    }
    final r = Rect.fromCenter(center: c, width: 92, height: 104);
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(10)),
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFB7C2CC), Color(0xFF6F7D8A)]).createShader(r),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(r.deflate(6), const Radius.circular(7)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = const Color(0x55FFFFFF),
    );
    final led = c.translate(0, 8);
    // Flashing for a moment, then steady bright; or dark.
    final on = lit && (v >= 1 || (v * 7).floor().isEven);
    if (on) {
      canvas.drawCircle(led, 34, Paint()..color = const Color(0x55FFF3B0));
      canvas.drawCircle(led, 22, Paint()..color = const Color(0x99FFE45C));
    }
    canvas.drawCircle(led, 15, Paint()..color = const Color(0xFF2A2F35));
    canvas.drawCircle(led, 11, Paint()..color = on ? const Color(0xFFFFF6C2) : const Color(0xFF454B52));
    if (!on) canvas.drawCircle(led.translate(-4, -4), 3, Paint()..color = const Color(0x33FFFFFF));
  }

  @override
  bool shouldRepaint(M5FaCloseUpPainter old) => old.lit != lit || old.sectionalizer != sectionalizer || old.v != v;
}

/// The folded feeder map on the dashboard: substation, main line, every T-off
/// (also the one under the grove), the devices (one symbol for all), the
/// readings written in, the van(s).
class M5FaMapPainter extends CustomPainter {
  const M5FaMapPainter({required this.call, required this.reads, required this.vanS, required this.van2S});
  final M5FaCall call;
  final Map<int, bool> reads;
  final double vanS;
  final double? van2S;

  @override
  void paint(Canvas canvas, Size size) {
    final pad = 22.0;
    final w = size.width - pad * 2;
    final y = size.height * 0.68;
    double x(double s) {
      final f = (s + 30) / (call.length + 60);
      return pad + (call.mirrored ? 1 - f : f) * w;
    }

    final ink = Paint()
      ..color = const Color(0xFF2A3A55)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(x(0), y), Offset(x(call.length), y), ink);
    // Substation.
    canvas.drawRect(Rect.fromCenter(center: Offset(x(-18), y), width: 14, height: 14), Paint()..color = const Color(0xFF2A3A55));
    // Load end.
    canvas.drawCircle(Offset(x(call.length + 12), y), 5, Paint()..color = const Color(0xFF6B7A90));
    final branchTop = size.height * 0.18;
    for (final (k, b) in call.branches.indexed) {
      final j = Offset(x(b.s), y);
      final end = Offset(j.dx, branchTop);
      canvas.drawLine(j, end, ink);
      if (b.grove) {
        // The grove drawn as the map's tree mark beside the branch.
        canvas.drawCircle(Offset(j.dx + 12, y - 20), 6, Paint()..color = const Color(0xFF4E8A44));
      }
      for (final n in call.branchNodes(k)) {
        _symbol(canvas, Offset(j.dx, y - (y - branchTop) * (n.order == 1 ? 0.33 : 0.7)), n);
      }
    }
    for (final n in call.mains) {
      _symbol(canvas, Offset(x(n.s), y), n);
    }
    _van(canvas, Offset(x(vanS), y + 16), const Color(0xFFF08A1C));
    if (van2S != null) _van(canvas, Offset(x(van2S!), y + 16), const Color(0xFF1E6FD0));
  }

  void _symbol(Canvas canvas, Offset c, M5FaNode n) {
    final r = Rect.fromCenter(center: c, width: 11, height: 11);
    canvas.drawRect(r, Paint()..color = const Color(0xFFF7F1DF));
    canvas.drawRect(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = const Color(0xFF2A3A55),
    );
    final lit = reads[n.id];
    if (lit != null) {
      canvas.drawCircle(c.translate(10, -10), 4.5, Paint()..color = lit ? const Color(0xFFFFC21F) : const Color(0xFF8E98A4));
    }
  }

  void _van(Canvas canvas, Offset c, Color col) {
    final p = Path()
      ..moveTo(c.dx, c.dy - 6)
      ..lineTo(c.dx - 5, c.dy + 4)
      ..lineTo(c.dx + 5, c.dy + 4)
      ..close();
    canvas.drawPath(p, Paint()..color = col);
  }

  @override
  bool shouldRepaint(M5FaMapPainter old) => !identical(old.call, call) || !mapEquals(old.reads, reads) || old.vanS != vanS || old.van2S != van2S;
}
