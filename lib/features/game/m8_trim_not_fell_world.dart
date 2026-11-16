import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The drawn world of lesson 8.9 কাজ 1 "ছাঁটা, কাটা নয়" (m8_trim_not_fell.dart).
//
// A village lane under a pre-monsoon sky, 11 kV on PCC poles. The line is dead
// and earthed (the earth set is drawn on the near pole; nothing live is
// offered). A van with its docket stands far off. Each play walks past two
// trees of four kinds (a yard mango with the owner at his gate, a coconut by a
// house with the owner, a roadside tree, a forest-edge tree with a boundary
// pillar). The trainee stands below with a long pole pruner (a hook-blade head,
// a rope down the pole); a tarp lies on the ground. Design: 360 wide × the
// scene's height. No ring, band or outline anywhere: the line's clearance is a
// game rule the player reads off the picture, never drawn.

/// The four kinds of tree.
enum M8TreeKind { mango, coconut, roadside, forest }

/// How a branch stands to the line: resting on a conductor, hanging over its
/// path, or harmless.
enum M8BranchKind { rests, over, harmless }

/// Where the hook seated.
enum M8SeatKind { none, branch, trunk }

/// A tree with its owner standing at the gate (the consumer deck comes).
bool m8HasOwner(M8TreeKind k) => k == M8TreeKind.mango || k == M8TreeKind.coconut;

/// The corridor under the line, as an offset above the ground line (game rule,
/// never drawn): wood that reaches above this is "still in the line's path".
const double m8RowY = -212;

/// A branch (offsets from the trunk's foot; y up is negative).
@immutable
class M8Branch {
  const M8Branch({required this.side, required this.ay, required this.tipDx, required this.tipY, required this.kind, this.nestT});

  /// −1 left, +1 right of the trunk (before the scene mirrors).
  final int side;
  final double ay;
  final double tipDx;
  final double tipY;
  final M8BranchKind kind;

  /// A bird's nest at this part of the branch (null = none).
  final double? nestT;

  bool get endangers => kind != M8BranchKind.harmless;

  /// Where along the branch it first reaches the corridor.
  double get lineT => (ay - m8RowY) / (ay - tipY);

  /// A cut at or below this part leaves the nest on the stub.
  double get nestSafeT => (nestT ?? 0) + 0.04;
}

/// One tree of a play.
@immutable
class M8TreeDeal {
  const M8TreeDeal({required this.kind, required this.cx, required this.branches});
  final M8TreeKind kind;

  /// The trunk's x offset from the middle of the lane.
  final double cx;
  final List<M8Branch> branches;

  int? get nestIndex {
    for (var i = 0; i < branches.length; i++) {
      if (branches[i].nestT != null) return i;
    }
    return null;
  }

  int get endangering => branches.where((b) => b.endangers).length;
}

// The four branch slots of a tree: (side, attach height). The upper slot of each
// side is where a branch that endangers the line grows.
const List<(int, double)> _slots = [(-1, -150), (1, -128), (-1, -104), (1, -84)];

/// Deals one tree: 3–4 branches, 1–2 of them endangering the line, a nest on
/// none or one (the inner part of an endangering branch, or a harmless one).
M8TreeDeal m8DealTree(M8TreeKind kind, math.Random rng) {
  double r(double a, double b) => a + rng.nextDouble() * (b - a);
  final lower = [2, 3]..shuffle(rng);
  final use = <int>[0, 1, if (rng.nextBool()) lower[0], if (rng.nextBool()) lower[1]];
  if (use.length < 3) use.add(lower[0]);
  use.sort();
  final danger = <int>{
    if (rng.nextBool()) ...[0, 1] else rng.nextBool() ? 0 : 1,
  };
  final nestRoll = rng.nextDouble();
  int? nestOn;
  if (nestRoll >= 0.4 && nestRoll < 0.8) {
    nestOn = danger.elementAt(rng.nextInt(danger.length));
  } else if (nestRoll >= 0.8) {
    final h = use.where((s) => !danger.contains(s)).toList();
    if (h.isNotEmpty) nestOn = h[rng.nextInt(h.length)];
  }
  final branches = <M8Branch>[];
  for (final s in use) {
    final (side, ay0) = _slots[s];
    final ay = ay0 + r(-5, 5);
    if (danger.contains(s)) {
      final over = rng.nextBool();
      branches.add(M8Branch(
        side: side,
        ay: ay,
        tipDx: r(20, 62),
        tipY: over ? r(-282, -268) : r(-268, -246),
        kind: over ? M8BranchKind.over : M8BranchKind.rests,
        nestT: nestOn == s ? r(0.12, 0.22) : null,
      ));
    } else {
      final top = s < 2;
      branches.add(M8Branch(
        side: side,
        ay: ay,
        tipDx: r(50, 84),
        tipY: top ? r(-196, -170) : ay + r(-30, 6),
        kind: M8BranchKind.harmless,
        nestT: nestOn == s ? r(0.3, 0.7) : null,
      ));
    }
  }
  return M8TreeDeal(kind: kind, cx: r(-12, 12), branches: branches);
}

/// What a hook let go at a point sits on.
@immutable
class M8SeatHit {
  const M8SeatHit(this.kind, this.index, this.t);
  final M8SeatKind kind;
  final int index;
  final double t;
  static const none = M8SeatHit(M8SeatKind.none, -1, 0);
}

/// Where things are (design px, 360 wide).
@immutable
class M8TrimGeo {
  const M8TrimGeo._(this.height, this.gy, this.flip, this.poleLen);

  factory M8TrimGeo.forScene(double height, double inset, {bool mirror = false, double poleLen = 250}) =>
      M8TrimGeo._(height, height - 200 - inset * 0.3, mirror, poleLen);

  final double height;
  final double gy;
  final bool flip;

  /// The pruner pole's length.
  final double poleLen;

  double x(double v) => flip ? 360 - v : v;
  Rect _r(double l, double t, double w, double h) => Rect.fromLTWH(flip ? 360 - l - w : l, t, w, h);

  // --- the line ------------------------------------------------------------------
  double wireY(int i) => gy - 268 + 12.0 * i;
  double get rowY => gy + m8RowY;
  double get nearPoleX => x(22);
  double get farPoleX => x(338);

  // --- the trainee and his pruner -----------------------------------------------
  Rect get traineeRect => _r(30, gy - 108, 44, 104);
  Offset get hands => Offset(x(72), gy - 62);

  /// The pruner head at rest: up and a little out from the hands.
  Offset get headHome => hands + Offset(flip ? -28 : 28, -poleLen * 0.62);

  /// Where the rope hangs (a swipe down here pulls it).
  Rect get ropeHit => _r(56, gy - 76, 56, 92);
  Rect headBox(Offset head) => Rect.fromCenter(center: head, width: 52, height: 52);

  /// The finished button.
  Rect get doneBtn => Rect.fromLTWH(130, gy + 128, 100, 48);

  // --- the tree --------------------------------------------------------------------
  Offset origin(M8TreeDeal d) => Offset(x(180 + d.cx), gy);
  double _sx(M8Branch b) => flip ? -b.side.toDouble() : b.side.toDouble();
  Offset attachOf(M8TreeDeal d, M8Branch b) => origin(d) + Offset(_sx(b) * 9, b.ay);
  Offset tipOf(M8TreeDeal d, M8Branch b) => origin(d) + Offset(_sx(b) * b.tipDx, b.tipY);
  Offset pointOn(M8TreeDeal d, M8Branch b, double t) => Offset.lerp(attachOf(d, b), tipOf(d, b), t)!;
  double branchLen(M8TreeDeal d, M8Branch b) => (tipOf(d, b) - attachOf(d, b)).distance;
  Rect trunkHit(M8TreeDeal d) => Rect.fromCenter(center: origin(d) + const Offset(0, -86), width: 34, height: 168);

  /// The tarp on the ground in front of the trunk.
  Rect tarp(M8TreeDeal d) => Rect.fromCenter(center: Offset(origin(d).dx, gy + 36), width: 150, height: 40);

  /// Where the i-th cut piece lies on the tarp.
  Offset pieceSpot(M8TreeDeal d, int i) {
    final t = tarp(d);
    return Offset(t.left + 30 + (i * 37) % 90, t.top + 12 + (i * 11) % 16);
  }

  Rect get ownerRect => _r(296, gy - 88, 36, 84);

  /// A hook let go at [p]: the nearest standing branch it touches (the part
  /// [0.12, cut + a little] of it), else the trunk, else nothing.
  M8SeatHit seatAt(M8TreeDeal d, List<double> curT, List<bool> done, Offset p) {
    var best = M8SeatHit.none;
    var bestDist = 15.0;
    for (var i = 0; i < d.branches.length; i++) {
      if (done[i]) continue;
      final b = d.branches[i];
      final a = attachOf(d, b);
      final v = tipOf(d, b) - a;
      final t = (((p - a).dx * v.dx + (p - a).dy * v.dy) / (v.dx * v.dx + v.dy * v.dy)).clamp(0.0, 1.0);
      if (t < 0.12 || t > curT[i] + 0.03) continue;
      final dist = (p - (a + v * t)).distance;
      if (dist < bestDist) {
        bestDist = dist;
        best = M8SeatHit(M8SeatKind.branch, i, math.min(t, curT[i]));
      }
    }
    if (best.kind == M8SeatKind.branch) return best;
    return trunkHit(d).contains(p) ? const M8SeatHit(M8SeatKind.trunk, -1, 0) : M8SeatHit.none;
  }

  /// The pole's head for a finger at [finger]: along the pole from the hands,
  /// never longer than the pole, with a slight sway sideways ([swayPx] at [ms]).
  Offset headFor(Offset finger, {double swayPx = 0, int ms = 0}) {
    final d = finger - hands;
    final len = d.distance;
    if (len < 1) return hands + const Offset(0, -1);
    final dir = d / len;
    final head = hands + dir * math.min(len, poleLen);
    final perp = Offset(-dir.dy, dir.dx);
    return head + perp * (swayPx * math.sin(ms / 330));
  }

  @override
  bool operator ==(Object other) => other is M8TrimGeo && other.height == height && other.gy == gy && other.flip == flip && other.poleLen == poleLen;

  @override
  int get hashCode => Object.hash(height, gy, flip, poleLen);
}

/// A cut piece: a branch from one part to another (fell or lies on the tarp).
@immutable
class M8Piece {
  const M8Piece(this.branch, this.from, this.to);
  final int branch;
  final double from;
  final double to;
}

/// What the painter shows of one tree now.
@immutable
class M8TreeRig {
  const M8TreeRig({
    required this.deal,
    required this.curT,
    required this.done,
    required this.nestDown,
    required this.pieces,
    this.ownerAngry = false,
    this.ownerCalm = false,
    this.saw = false,
    this.sawBite = false,
  });

  final M8TreeDeal deal;
  final List<double> curT;
  final List<bool> done;
  final bool nestDown;
  final List<M8Piece> pieces;
  final bool ownerAngry;
  final bool ownerCalm;
  final bool saw;
  final bool sawBite;
}

/// The whole picture's state (equality by [rev], bumped by the page on every
/// visible change).
@immutable
class M8TrimRig {
  const M8TrimRig({required this.rev, required this.tree, this.prev, this.showPole = true, this.seated = false, this.falling, this.dusk = 0});
  final int rev;
  final M8TreeRig tree;
  final M8TreeRig? prev;
  final bool showPole;
  final bool seated;

  /// The piece that is falling now (animated by the fall clock).
  final M8Piece? falling;
  final int dusk;

  @override
  bool operator ==(Object other) =>
      other is M8TrimRig && other.rev == rev && identical(other.tree.deal, tree.deal) && identical(other.prev?.deal, prev?.deal) && other.showPole == showPole && other.seated == seated && other.falling == falling && other.dusk == dusk && other.tree.saw == tree.saw && other.tree.sawBite == tree.sawBite && other.tree.ownerAngry == tree.ownerAngry && other.tree.ownerCalm == tree.ownerCalm;

  @override
  int get hashCode => Object.hash(rev, tree.deal, prev?.deal, showPole, seated, falling, dusk);
}

const _bark = Color(0xFF6B4A2E);
const _barkDark = Color(0xFF4A3220);
const _steel = Color(0xFF8E979E);
const _steelDark = Color(0xFF4F565C);
const _wire = Color(0xFF1B1F23);
const _tarpBlue = Color(0xFF3F78C2);
const _earthGreen = Color(0xFF2E9E4F);
const _earthYellow = Color(0xFFF2C230);

const List<List<Color>> _skies = [
  [Color(0xFF5B7FA6), Color(0xFFB9C9D8), Color(0xFFE6E3D6)],
  [Color(0xFF6A7C8F), Color(0xFFC3C9CE), Color(0xFFE9E0CC)],
  [Color(0xFF8A6F8F), Color(0xFFE6B8A0), Color(0xFFF1DFB4)],
];

class M8TrimPainter extends CustomPainter {
  M8TrimPainter({required this.geo, required this.rig, required this.head, required this.slide, required this.fall}) : super(repaint: Listenable.merge([head, slide, fall]));

  final M8TrimGeo geo;
  final M8TrimRig rig;

  /// The pruner head now (follows the finger without a rebuild).
  final ValueListenable<Offset> head;

  /// 0 → 1 while the camera walks to the next tree.
  final ValueListenable<double> slide;

  /// 0 → 1 while a cut piece falls (and the rope is pulled).
  final ValueListenable<double> fall;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final s = slide.value;
    final prev = rig.prev;
    if (prev != null && s < 1) {
      _stage(c, size, prev, -s * w, falling: false);
      _stage(c, size, rig.tree, (1 - s) * w, falling: false);
    } else {
      _stage(c, size, rig.tree, 0, falling: true);
    }
    if (rig.showPole && (prev == null || s >= 1)) _pruner(c);
  }

  // --- one stage (a tree and its lane) -------------------------------------------------
  void _stage(Canvas c, Size size, M8TreeRig t, double dx, {required bool falling}) {
    final w = size.width;
    final h = size.height;
    c.save();
    c.translate(dx, 0);
    _sky(c, w, h);
    _backdrop(c, t.deal.kind, w);
    _ground(c, w, h, t.deal.kind);
    _line(c);
    _tarp(c, t);
    _tree(c, t, falling);
    _owner(c, t);
    c.restore();
  }

  void _sky(Canvas c, double w, double h) {
    final g = geo;
    final cols = _skies[rig.dusk % _skies.length];
    final sky = Rect.fromLTWH(0, 0, w, g.gy + 6);
    c.drawRect(sky, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: cols).createShader(sky));
    // Pre-monsoon clouds.
    final cloud = Paint()..color = const Color(0x55FFFFFF);
    for (final (cx, cy, r) in [(60.0, g.gy - 330, 34.0), (150.0, g.gy - 350, 26.0), (270.0, g.gy - 322, 38.0), (330.0, g.gy - 360, 22.0)]) {
      c.drawCircle(Offset(g.x(cx), cy), r, cloud);
      c.drawCircle(Offset(g.x(cx) + r * 0.9, cy + 6), r * 0.7, cloud);
    }
  }

  void _backdrop(Canvas c, M8TreeKind kind, double w) {
    final g = geo;
    final y = g.gy - 24;
    // Far fields and a tree line.
    final far = Paint()..color = const Color(0xFF7BA05F);
    final rnd = math.Random(7);
    for (var x = -8.0; x < w + 20; x += 16 + rnd.nextDouble() * 12) {
      final r = 8 + rnd.nextDouble() * 8;
      c.drawCircle(Offset(x, y - r * 0.2), r, far);
    }
    switch (kind) {
      case M8TreeKind.mango:
        // The yard fence and gate, a hut roof behind.
        final fence = Paint()..color = const Color(0xFF8B6B45);
        for (var x = g.x(236); (g.flip ? x > g.x(356) : x < g.x(356)); x += g.flip ? -12 : 12) {
          c.drawRect(Rect.fromLTWH(x - 2, g.gy - 46, 4, 44), fence);
        }
        c.drawRect(Rect.fromLTRB(math.min(g.x(236), g.x(356)), g.gy - 36, math.max(g.x(236), g.x(356)), g.gy - 32), fence);
        c.drawPath(
            Path()
              ..moveTo(g.x(262), g.gy - 62)
              ..lineTo(g.x(300), g.gy - 92)
              ..lineTo(g.x(344), g.gy - 62)
              ..close(),
            Paint()..color = const Color(0xFFB4533A));
      case M8TreeKind.coconut:
        // A tiled house by the tree.
        final hx = g.x(270);
        c.drawRect(Rect.fromCenter(center: Offset(hx, g.gy - 40), width: 96, height: 50), Paint()..color = const Color(0xFFE6D5A8));
        c.drawPath(
            Path()
              ..moveTo(hx - 56, g.gy - 64)
              ..lineTo(hx, g.gy - 100)
              ..lineTo(hx + 56, g.gy - 64)
              ..close(),
            Paint()..color = const Color(0xFFA9452E));
        c.drawRect(Rect.fromCenter(center: Offset(hx, g.gy - 28), width: 18, height: 26), Paint()..color = const Color(0xFF6B4A2E));
      case M8TreeKind.roadside:
        // The road with a milestone.
        c.drawRect(Rect.fromLTWH(0, g.gy - 16, w, 18), Paint()..color = const Color(0xFF6E6F72));
        c.drawRect(Rect.fromCenter(center: Offset(g.x(320), g.gy - 22), width: 12, height: 18), Paint()..color = const Color(0xFFEDE7D5));
      case M8TreeKind.forest:
        // The forest edge with a whitewashed boundary pillar.
        final dark = Paint()..color = const Color(0xFF2A5B34);
        for (var x = g.x(214); (g.flip ? x > g.x(360) : x < g.x(360)); x += g.flip ? -14 : 14) {
          c.drawCircle(Offset(x, y - 12 - (x * 7 % 9)), 18, dark);
        }
        final px = g.x(304);
        c.drawRect(Rect.fromLTWH(px - 6, g.gy - 40, 12, 38), Paint()..color = const Color(0xFFEEEBE0));
        c.drawRect(Rect.fromLTWH(px - 6, g.gy - 40, 12, 6), Paint()..color = const Color(0xFFB6B2A4));
    }
    // The van far off (its docket is drawn with the line).
    final vx = g.x(318);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(vx, g.gy - 120), width: 56, height: 28), const Radius.circular(4)), Paint()..color = const Color(0xFFF1F1EC));
  }

  void _ground(Canvas c, double w, double h, M8TreeKind kind) {
    final g = geo;
    final r = Rect.fromLTRB(0, g.gy - 4, w, h);
    c.drawRect(r, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: const [Color(0xFF8DA36A), Color(0xFF6E8550)]).createShader(r));
    // The lane's dust strip.
    c.drawRect(Rect.fromLTWH(0, g.gy + 78, w, 18), Paint()..color = const Color(0x22C9A877));
    if (kind == M8TreeKind.roadside) c.drawRect(Rect.fromLTWH(0, g.gy - 4, w, 8), Paint()..color = const Color(0xFF7C7D80));
  }

  /// The poles, the cross-arms and the three conductors; the earth set and the
  /// docket on the near pole.
  void _line(Canvas c) {
    final g = geo;
    for (final (px, near) in [(g.nearPoleX, true), (g.farPoleX, false)]) {
      final top = g.wireY(0) - 14;
      final pole = Rect.fromLTRB(px - (near ? 6 : 4), top, px + (near ? 6 : 4), g.gy);
      c.drawRect(pole, Paint()..shader = const LinearGradient(colors: [Color(0xFFC2BCB2), Color(0xFF8E887F)]).createShader(pole));
      c.drawRect(Rect.fromLTWH(px - 20, g.wireY(0) - 6, 40, 4), Paint()..color = _steelDark);
      for (var i = 0; i < 3; i++) {
        c.drawRect(Rect.fromLTWH(px - 16 + 16.0 * i, g.wireY(0) - 12, 4, 7), Paint()..color = const Color(0xFFE6EBEF));
      }
      if (near) {
        // The earth set: a green-yellow lead from the line to a rod, and the PTW tag.
        final lead = Path()
          ..moveTo(px + 8, g.wireY(2))
          ..quadraticBezierTo(px + 22, g.wireY(2) + 70, px + 10, g.gy - 6);
        c.drawPath(lead, Paint()..color = _earthGreen..style = PaintingStyle.stroke..strokeWidth = 2.6);
        c.drawPath(lead, Paint()..color = _earthYellow..style = PaintingStyle.stroke..strokeWidth = 1);
        c.drawRect(Rect.fromLTWH(px + 9, g.gy - 12, 2, 14), Paint()..color = _steelDark);
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(px - 16, g.gy - 130, 12, 16), const Radius.circular(2)), Paint()..color = const Color(0xFFF7F1DE));
        c.drawRect(Rect.fromLTWH(px - 14, g.gy - 127, 8, 2.4), Paint()..color = const Color(0xFFB03A2E));
      }
    }
    for (var i = 0; i < 3; i++) {
      final y = g.wireY(i);
      final p = Path()
        ..moveTo(g.nearPoleX, y)
        ..quadraticBezierTo(180, y + 6, g.farPoleX, y);
      c.drawPath(p, Paint()..color = _wire..style = PaintingStyle.stroke..strokeWidth = 2);
    }
    // The docket on the van door (a worker's label).
    final vx = g.x(318);
    final tp = TextPainter(
      text: const TextSpan(text: 'প্রি-মনসুন RoW · শাটডাউন · PTW · আর্থ', style: TextStyle(fontSize: 6.5, height: 1.15, color: Color(0xFF222222), fontWeight: FontWeight.w700)),
      textDirection: TextDirection.ltr,
      maxLines: 3,
    )..layout(maxWidth: 38);
    final paper = Rect.fromCenter(center: Offset(vx, g.gy - 120), width: 42, height: 30);
    c.drawRRect(RRect.fromRectAndRadius(paper, const Radius.circular(2)), Paint()..color = const Color(0xFFFFF8E1));
    tp.paint(c, paper.topLeft + const Offset(2, 2));
  }

  void _tarp(Canvas c, M8TreeRig t) {
    final g = geo;
    final r = g.tarp(t.deal);
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(4)), Paint()..color = _tarpBlue);
    c.drawRRect(RRect.fromRectAndRadius(r.deflate(3), const Radius.circular(3)), Paint()..color = const Color(0x22FFFFFF)..style = PaintingStyle.stroke..strokeWidth = 1.2);
    for (var i = 0; i < t.pieces.length; i++) {
      final p = t.pieces[i];
      _piece(c, t.deal, p, g.pieceSpot(t.deal, i), 1);
    }
    if (t.nestDown) {
      final n = r.center + const Offset(40, -2);
      c.drawOval(Rect.fromCenter(center: n, width: 16, height: 9), Paint()..color = const Color(0xFF8A6A3C));
      c.drawCircle(n + const Offset(-2, -3), 2.2, Paint()..color = const Color(0xFFEFE8D2));
      c.drawCircle(n + const Offset(3, -3), 2.2, Paint()..color = const Color(0xFFEFE8D2));
    }
  }

  Color _leaf(M8TreeKind k) => switch (k) {
        M8TreeKind.mango => const Color(0xFF2E7A3A),
        M8TreeKind.coconut => const Color(0xFF3C8F3B),
        M8TreeKind.roadside => const Color(0xFF5C9A3C),
        M8TreeKind.forest => const Color(0xFF1F5A33),
      };

  void _tree(Canvas c, M8TreeRig t, bool allowFall) {
    final g = geo;
    final d = t.deal;
    final o = g.origin(d);
    final leaf = _leaf(d.kind);
    // The canopy behind (kept clear of the line).
    c.drawOval(Rect.fromCenter(center: o + const Offset(0, -158), width: 168, height: 92), Paint()..color = leaf.withValues(alpha: 0.92));
    c.drawOval(Rect.fromCenter(center: o + const Offset(-22, -178), width: 96, height: 60), Paint()..color = Color.lerp(leaf, Colors.white, 0.12)!);
    // The trunk.
    final trunk = Path()
      ..moveTo(o.dx - 13, o.dy)
      ..lineTo(o.dx - 8, o.dy - 176)
      ..lineTo(o.dx + 8, o.dy - 176)
      ..lineTo(o.dx + 13, o.dy)
      ..close();
    c.drawPath(trunk, Paint()..shader = const LinearGradient(colors: [_barkDark, _bark, _barkDark]).createShader(Rect.fromLTWH(o.dx - 13, o.dy - 176, 26, 176)));
    if (d.kind == M8TreeKind.coconut) {
      for (var y = 10.0; y < 170; y += 14) {
        c.drawLine(Offset(o.dx - 11, o.dy - y), Offset(o.dx + 11, o.dy - y - 3), Paint()..color = const Color(0x33000000)..strokeWidth = 1.4);
      }
    }
    if (t.sawBite) {
      c.drawPath(
          Path()
            ..moveTo(o.dx - 12, o.dy - 52)
            ..lineTo(o.dx + 1, o.dy - 40)
            ..lineTo(o.dx - 12, o.dy - 30)
            ..close(),
          Paint()..color = const Color(0xFFE9D3A4));
      for (final p in const [Offset(-16, -34), Offset(-20, -44), Offset(-14, -26), Offset(-22, -36)]) {
        c.drawCircle(o + p, 1.4, Paint()..color = const Color(0xFFE9D3A4));
      }
    }
    // The branches (a cut branch ends at its stub).
    for (var i = 0; i < d.branches.length; i++) {
      final b = d.branches[i];
      final a = g.attachOf(d, b);
      final cut = t.curT[i];
      final end = Offset.lerp(a, g.tipOf(d, b), cut)!;
      c.drawLine(a, end, Paint()..color = _bark..strokeWidth = 7..strokeCap = StrokeCap.round);
      c.drawLine(a, end, Paint()..color = const Color(0x22FFFFFF)..strokeWidth = 2);
      // Leaf tufts on the outer part.
      final tufts = d.kind == M8TreeKind.coconut ? 4 : 3;
      for (var k = 0; k < tufts; k++) {
        final tt = (cut * (0.55 + 0.45 * k / (tufts - 1))).clamp(0.2, 1.0);
        final p = Offset.lerp(a, g.tipOf(d, b), tt)!;
        if (d.kind == M8TreeKind.coconut) {
          final side = (g.flip ? -b.side : b.side).toDouble();
          c.drawLine(p, p + Offset(side * 15, -9 + k * 2.0), Paint()..color = leaf..strokeWidth = 3..strokeCap = StrokeCap.round);
          c.drawLine(p, p + Offset(side * 12, 8.0 - k), Paint()..color = leaf..strokeWidth = 3..strokeCap = StrokeCap.round);
        } else {
          c.drawCircle(p + Offset(0, -3), 9 + (k == tufts - 1 ? 2 : 0), Paint()..color = leaf);
        }
      }
      // A cut stub shows its pale face.
      if (cut < 0.999) c.drawCircle(end, 3.6, Paint()..color = const Color(0xFFE9D3A4));
      // The nest, on the part of the branch it was dealt (while it is there).
      final nt = b.nestT;
      if (nt != null && !t.nestDown && nt <= cut) {
        final np = g.pointOn(d, b, nt) + const Offset(0, -8);
        c.drawOval(Rect.fromCenter(center: np, width: 17, height: 9), Paint()..color = const Color(0xFF8A6A3C));
        c.drawCircle(np + const Offset(-2.5, -3), 2.3, Paint()..color = const Color(0xFFEFE8D2));
        c.drawCircle(np + const Offset(3, -3), 2.3, Paint()..color = const Color(0xFFEFE8D2));
      }
    }
    // The piece in the air.
    final f = rig.falling;
    if (f != null && allowFall) {
      final s = fall.value;
      final spot = g.pieceSpot(d, t.pieces.length);
      final mid = Offset.lerp(g.pointOn(d, d.branches[f.branch], f.from), g.pointOn(d, d.branches[f.branch], f.to), 0.5)!;
      final pos = Offset(mid.dx + (spot.dx - mid.dx) * s, mid.dy + (spot.dy - mid.dy) * s * s);
      _piece(c, d, f, pos, s);
    }
    if (t.saw) _saw(c, o);
  }

  /// A cut piece of a branch centred at [at]: turning from the way it grew to
  /// lying flat as [s] goes 0 → 1 (a piece at rest has s = 1).
  void _piece(Canvas c, M8TreeDeal d, M8Piece p, Offset at, double s) {
    final g = geo;
    final b = d.branches[p.branch];
    final v = g.pointOn(d, b, p.to) - g.pointOn(d, b, p.from);
    final len = v.distance * 0.9;
    var ang = math.atan2(v.dy, v.dx);
    if (ang > math.pi / 2) ang -= math.pi;
    if (ang < -math.pi / 2) ang += math.pi;
    c.save();
    c.translate(at.dx, at.dy);
    c.rotate(ang * (1 - s) + 0.1 * s);
    final h = len / 2;
    c.drawLine(Offset(-h, 0), Offset(h, 0), Paint()..color = _bark..strokeWidth = 5..strokeCap = StrokeCap.round);
    c.drawCircle(Offset(h * 0.7, -2), 6, Paint()..color = _leaf(d.kind));
    c.drawCircle(Offset(h * 0.2, -3), 5, Paint()..color = _leaf(d.kind));
    c.drawCircle(Offset(-h, 0), 3, Paint()..color = const Color(0xFFE9D3A4));
    c.restore();
  }

  void _saw(Canvas c, Offset o) {
    c.save();
    c.translate(o.dx - 26, o.dy - 40);
    c.rotate(-0.5);
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-22, -9, 30, 18), const Radius.circular(3)), Paint()..color = const Color(0xFFE2761B));
    c.drawRect(const Rect.fromLTWH(8, -4, 30, 8), Paint()..color = _steel);
    for (var x = 10.0; x < 38; x += 4) {
      c.drawRect(Rect.fromLTWH(x, 4, 2, 3), Paint()..color = _steelDark);
    }
    c.drawRect(const Rect.fromLTWH(-14, -15, 14, 6), Paint()..color = const Color(0xFF2B2B2B));
    c.restore();
  }

  /// The owner at his gate: arms crossed, then calm.
  void _owner(Canvas c, M8TreeRig t) {
    if (!m8HasOwner(t.deal.kind)) return;
    final r = geo.ownerRect;
    final body = Paint()..color = const Color(0xFF8A4F38);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.left + 6, r.top + 22, r.width - 12, r.height - 22), const Radius.circular(6)), body);
    c.drawCircle(Offset(r.center.dx, r.top + 14), 11, Paint()..color = const Color(0xFFC08A5E));
    c.drawRect(Rect.fromLTWH(r.left + 8, r.top + 38, r.width - 16, 5), Paint()..color = const Color(0xFFD9C7A0));
    c.drawLine(Offset(r.center.dx - 12, r.top + 30), Offset(r.center.dx + 10, r.top + 46), Paint()..color = const Color(0xFF6E3C28)..strokeWidth = 5);
    // The brow: angry before he is talked to, calm after.
    final brow = Paint()..color = const Color(0xFF2B1A12)..strokeWidth = 2;
    if (t.ownerCalm) {
      c.drawLine(Offset(r.center.dx - 6, r.top + 10), Offset(r.center.dx - 2, r.top + 10), brow);
      c.drawLine(Offset(r.center.dx + 2, r.top + 10), Offset(r.center.dx + 6, r.top + 10), brow);
    } else {
      c.drawLine(Offset(r.center.dx - 7, r.top + 8), Offset(r.center.dx - 2, r.top + 11), brow);
      c.drawLine(Offset(r.center.dx + 7, r.top + 8), Offset(r.center.dx + 2, r.top + 11), brow);
    }
  }

  /// The pole pruner: the pole from the hands to the head, the hook-blade, the
  /// rope down the pole to its grip (pulled while a piece falls).
  void _pruner(Canvas c) {
    final g = geo;
    final h = head.value;
    final hands = g.hands;
    final v = h - hands;
    final len = v.distance;
    if (len < 2) return;
    final dir = v / len;
    final perp = Offset(-dir.dy, dir.dx);
    // The pole (a wooden grip near the hands, aluminium above).
    c.drawLine(hands - dir * 14, hands + dir * 46, Paint()..color = const Color(0xFF8A5A33)..strokeWidth = 5.4..strokeCap = StrokeCap.round);
    c.drawLine(hands + dir * 46, h, Paint()..color = _steel..strokeWidth = 3.6..strokeCap = StrokeCap.round);
    // The hook and the blade at the head.
    final hook = Path()
      ..moveTo(h.dx, h.dy)
      ..quadraticBezierTo(h.dx + perp.dx * 16 + dir.dx * 6, h.dy + perp.dy * 16 + dir.dy * 6, h.dx + perp.dx * 6 + dir.dx * 14, h.dy + perp.dy * 6 + dir.dy * 14);
    c.drawPath(hook, Paint()..color = _steelDark..style = PaintingStyle.stroke..strokeWidth = 4..strokeCap = StrokeCap.round);
    c.drawPath(
        Path()
          ..moveTo(h.dx - dir.dx * 4, h.dy - dir.dy * 4)
          ..lineTo(h.dx - dir.dx * 12 - perp.dx * 6, h.dy - dir.dy * 12 - perp.dy * 6)
          ..lineTo(h.dx - dir.dx * 2 - perp.dx * 2, h.dy - dir.dy * 2 - perp.dy * 2)
          ..close(),
        Paint()..color = const Color(0xFFD7DDE2));
    // The rope: from the head down the pole to a knotted grip.
    final s = fall.value;
    final pull = rig.falling != null ? math.sin(math.pi * s.clamp(0.0, 1.0)) * 22 : 0.0;
    final grip = hands + Offset(g.flip ? -14 : 14, 30 + pull);
    final rope = Path()
      ..moveTo(h.dx - dir.dx * 10, h.dy - dir.dy * 10)
      ..quadraticBezierTo(hands.dx + dir.dx * 60 + perp.dx * 10, hands.dy + dir.dy * 60 + perp.dy * 10, grip.dx, grip.dy);
    c.drawPath(rope, Paint()..color = const Color(0xFFEDE3C3)..style = PaintingStyle.stroke..strokeWidth = 1.6);
    c.drawCircle(grip, 3.4, Paint()..color = const Color(0xFFC5B07A));
  }

  @override
  bool shouldRepaint(M8TrimPainter old) => old.rig != rig || old.geo != geo;
}
