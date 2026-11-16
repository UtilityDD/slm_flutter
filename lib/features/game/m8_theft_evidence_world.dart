import 'dart:math' as math;

import 'package:flutter/material.dart';

// The scene of lesson 8.2 কাজ "আগে প্রমাণ, পরে কাটা" (pack do_8_2_b): an
// evening lane (3-4 premises) and, per premises, a close-up of the pole top,
// the wires and the house wall. Design pixels, 360 wide. Everything that
// differs between a stealing premises and an honest one is drawn the same way
// everywhere (same line weight, a tree over a wire at any premises, the same
// service cable): the hook is only a small curl on the conductor.

/// What a premises is (never shown by a caption).
enum M8Kind { hooking, bypass, shop, normal }

bool m8IsTheft(M8Kind k) => k == M8Kind.hooking || k == M8Kind.bypass;

/// One premises' look (dealt).
@immutable
class M8Look {
  const M8Look({
    required this.kind,
    this.hookRow = 1,
    this.hookCol = 1,
    this.entry = 0,
    this.sag = 1,
    this.tree = false,
    this.dusk = false,
    this.cut = false,
  });

  final M8Kind kind;

  /// Which of the four conductors carries the hook, and where along it.
  final int hookRow;
  final int hookCol;

  /// Where the thrown wire reaches the wall, and how it hangs.
  final int entry;
  final int sag;

  /// A tree over a wire (drawn at every premises).
  final bool tree;
  final bool dusk;

  /// Disconnected: the hook or loop is gone, the windows dark.
  final bool cut;

  M8Look withCut(bool c) => M8Look(kind: kind, hookRow: hookRow, hookCol: hookCol, entry: entry, sag: sag, tree: tree, dusk: dusk, cut: c);

  @override
  bool operator ==(Object other) =>
      other is M8Look &&
      other.kind == kind &&
      other.hookRow == hookRow &&
      other.hookCol == hookCol &&
      other.entry == entry &&
      other.sag == sag &&
      other.tree == tree &&
      other.dusk == dusk &&
      other.cut == cut;

  @override
  int get hashCode => Object.hash(kind, hookRow, hookCol, entry, sag, tree, dusk, cut);
}

/// Close-up geometry in the block's own pixels (360 x 400, origin top-left;
/// the page offsets it by [oyFor]).
abstract final class M8Geo {
  static const w = 360.0;
  static const blockH = 400.0;
  static const poleX = 54.0;
  static const rows = [84.0, 96.0, 108.0, 120.0];
  static const hookXs = [128.0, 150.0, 172.0, 194.0];
  static const entries = [Offset(226, 226), Offset(232, 254)];
  static const sags = [34.0, 52.0, 70.0];
  static const meter = Rect.fromLTWH(298, 222, 44, 54);
  static const clamp = Offset(54, 150);

  /// The block's top in the scene, below the header.
  static double oyFor(double sceneH, {double topInset = 0}) => math.max(70.0 + topInset, (sceneH - blockH) / 2 - 30);

  static Offset hookPoint(M8Look l) => Offset(hookXs[l.hookCol], rows[l.hookRow]);

  static Offset _quad(Offset a, Offset c, Offset b, double t) {
    final u = 1 - t;
    return Offset(u * u * a.dx + 2 * u * t * c.dx + t * t * b.dx, u * u * a.dy + 2 * u * t * c.dy + t * t * b.dy);
  }

  static List<Offset> _densify(List<Offset> p, double step) {
    final out = <Offset>[p.first];
    for (var i = 1; i < p.length; i++) {
      final d = (p[i] - p[i - 1]).distance;
      final n = math.max(1, (d / step).ceil());
      for (var k = 1; k <= n; k++) {
        out.add(Offset.lerp(p[i - 1], p[i], k / n)!);
      }
    }
    return out;
  }

  static Offset hookControl(M8Look l) {
    final a = hookPoint(l);
    final b = entries[l.entry];
    return Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2 + sags[l.sag]);
  }

  /// The thrown wire: from the conductor to the wall (about 6 px apart).
  static List<Offset> hookWire(M8Look l) {
    final a = hookPoint(l), c = hookControl(l), b = entries[l.entry];
    return _densify([for (var i = 0; i <= 24; i++) _quad(a, c, b, i / 24)], 6);
  }

  static const _svcCtrl = Offset(170, 214);
  static const _svcEnd = Offset(298, 238);

  /// The honest service cable: the pole clamp to the meter box.
  static List<Offset> service() => _densify([for (var i = 0; i <= 24; i++) _quad(clamp, _svcCtrl, _svcEnd, i / 24)], 6);

  static const loopA = Offset(276, 233);
  static const loopB = Offset(350, 262);

  /// The loop round the meter box (bypass): a tap on the cable, over the box,
  /// back to the load side.
  static List<Offset> loop() {
    const a = loopA, c1 = Offset(284, 190), c2 = Offset(352, 196), b = loopB;
    return _densify([
      for (var i = 0; i <= 24; i++)
        () {
          final t = i / 24, u = 1 - t;
          return Offset(
            u * u * u * a.dx + 3 * u * u * t * c1.dx + 3 * u * t * t * c2.dx + t * t * t * b.dx,
            u * u * u * a.dy + 3 * u * u * t * c1.dy + 3 * u * t * t * c2.dy + t * t * t * b.dy,
          );
        }(),
    ], 6);
  }

  /// The target a clip must follow at a stealing premises (null elsewhere).
  static List<Offset>? target(M8Look l) => switch (l.kind) {
        M8Kind.hooking => hookWire(l),
        M8Kind.bypass => loop(),
        _ => null,
      };
}

/// What a trace holds of the theft (judged only at the disconnect).
@immutable
class M8Verdict {
  const M8Verdict(this.valid, this.coverage, this.precision);
  final bool valid;
  final double coverage;
  final double precision;
}

const m8Tol = 26.0;

/// A finger trace (block pixels): valid when it follows the stealing wire from
/// end to end and not much else. Honest premises have nothing to follow.
M8Verdict m8Judge(List<Offset> trace, M8Look look) {
  final target = M8Geo.target(look);
  if (target == null || trace.length < 2) return const M8Verdict(false, 0, 0);
  final dense = M8Geo._densify(trace, 8);
  double near(Offset p, List<Offset> to) {
    var m = double.infinity;
    for (final q in to) {
      final d = (p - q).distanceSquared;
      if (d < m) m = d;
    }
    return math.sqrt(m);
  }

  var covered = 0;
  for (final q in target) {
    if (near(q, dense) <= m8Tol) covered++;
  }
  final cov = covered / target.length;
  final ends = near(target.first, dense) <= m8Tol && near(target.last, dense) <= m8Tol;
  var close = 0;
  for (final p in dense) {
    if (near(p, target) <= m8Tol * 1.6) close++;
  }
  final prec = close / dense.length;
  return M8Verdict(ends && cov >= 0.85 && prec >= (look.kind == M8Kind.bypass ? 0.5 : 0.6), cov, prec);
}

/// A wire's path, drawn with the same weight everywhere.
void _wire(Canvas c, List<Offset> p, Offset ctrl, {Color color = const Color(0xFF1E252B), double width = 2.2}) {
  final path = Path()..moveTo(p.first.dx, p.first.dy);
  path.quadraticBezierTo(ctrl.dx, ctrl.dy, p.last.dx, p.last.dy);
  c.drawPath(
    path,
    Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round,
  );
}

void _text(Canvas c, String s, Offset centre, double size, Color color, {FontWeight weight = FontWeight.w800}) {
  final tp = TextPainter(
    text: TextSpan(text: s, style: TextStyle(fontSize: size, fontWeight: weight, color: color)),
    textDirection: TextDirection.ltr,
  )..layout();
  tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
}

/// The close-up of one premises.
class M8CloseUpPainter extends CustomPainter {
  const M8CloseUpPainter({required this.look, required this.oy, required this.seed});
  final M8Look look;
  final double oy;
  final int seed;

  @override
  void paint(Canvas c, Size size) {
    final sky = look.dusk ? const [Color(0xFF2B3A67), Color(0xFFE8A06A)] : const [Color(0xFF3B5A86), Color(0xFFF4C98B)];
    c.drawRect(
      Offset.zero & size,
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: sky).createShader(Offset(0, oy) & Size(size.width, M8Geo.blockH * 0.85)),
    );
    c.save();
    c.translate(0, oy);
    paintBlock(c, Size(size.width, size.height));
    c.restore();
  }

  /// The block (360 x 400) in its own pixels; the ground runs to the bottom.
  void paintBlock(Canvas c, Size size) {
    final ground = Paint()..color = const Color(0xFF4A4338);
    c.drawRect(Rect.fromLTRB(0, 330, size.width, size.height + 400), ground);
    c.drawRect(Rect.fromLTWH(0, 330, size.width, 6), Paint()..color = const Color(0xFF5E5547));
    // Far trees.
    final tree = Paint()..color = const Color(0xFF2E4A3A);
    for (final x in [20.0, 120.0, 200.0]) {
      c.drawOval(Rect.fromCenter(center: Offset(x, 318), width: 70, height: 46), tree);
    }
    // The pole.
    c.drawRect(const Rect.fromLTWH(50, 64, 8, 270), Paint()..color = const Color(0xFF6B523C));
    // Conductors.
    final wire = Paint()
      ..color = const Color(0xFF1E252B)
      ..strokeWidth = 1.8;
    for (final y in M8Geo.rows) {
      c.drawLine(Offset(0, y), Offset(M8Geo.w, y), wire);
      c.drawCircle(Offset(M8Geo.poleX, y), 3.2, Paint()..color = const Color(0xFFB0BEC5));
    }
    // The service clamp and a neighbour's cable going off to the left.
    c.drawRect(Rect.fromCenter(center: M8Geo.clamp, width: 12, height: 8), Paint()..color = const Color(0xFF78909C));
    _wire(c, [M8Geo.clamp, const Offset(0, 250)], const Offset(24, 190));
    _house(c);
    // The honest cable to the meter.
    final svc = M8Geo.service();
    _wire(c, [svc.first, svc.last], const Offset(170, 214));
    // The theft wires: same weight, the hook a small curl on the conductor.
    if (!look.cut) {
      if (look.kind == M8Kind.hooking) {
        final w = M8Geo.hookWire(look);
        _wire(c, [w.first, w.last], M8Geo.hookControl(look));
        final hp = M8Geo.hookPoint(look);
        c.drawArc(
          Rect.fromCircle(center: hp + const Offset(0, -2), radius: 5),
          0.3,
          5.6,
          false,
          Paint()
            ..color = const Color(0xFF1E252B)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2,
        );
      } else if (look.kind == M8Kind.bypass) {
        final p = Path()
          ..moveTo(M8Geo.loopA.dx, M8Geo.loopA.dy)
          ..cubicTo(284, 190, 352, 196, M8Geo.loopB.dx, M8Geo.loopB.dy);
        c.drawPath(
          p,
          Paint()
            ..color = const Color(0xFF1E252B)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2
            ..strokeCap = StrokeCap.round,
        );
      }
    }
    // A tree canopy over the middle of a wire, at any premises (dealt).
    if (look.tree) {
      final mid = look.kind == M8Kind.hooking
          ? M8Geo.hookWire(look)[M8Geo.hookWire(look).length ~/ 2]
          : M8Geo.service()[M8Geo.service().length ~/ 2];
      final leaf = Paint()..color = const Color(0xFF2F6B3A).withValues(alpha: 0.5);
      for (final d in const [Offset(-12, -6), Offset(10, -10), Offset(0, 8), Offset(-2, -2)]) {
        c.drawOval(Rect.fromCenter(center: mid + d, width: 34, height: 26), leaf);
      }
    }
  }

  void _house(Canvas c) {
    final shop = look.kind == M8Kind.shop;
    final wall = Paint()..color = shop ? const Color(0xFFCFB98A) : const Color(0xFFE2B4A0);
    final roof = Paint()..color = const Color(0xFF7A3E34);
    final dark = Paint()..color = const Color(0xFF3A2E26);
    final glow = look.cut ? const Color(0xFF2A2F36) : const Color(0xFFFFD27A);
    if (shop) {
      c.drawRect(const Rect.fromLTWH(212, 200, 146, 130), wall);
      // Awning stripes and the sign.
      for (var i = 0; i < 8; i++) {
        c.drawRect(Rect.fromLTWH(212 + i * 18.25, 190, 18.25, 24), Paint()..color = i.isEven ? const Color(0xFFC0392B) : const Color(0xFFF2EBDD));
      }
      c.drawRect(const Rect.fromLTWH(226, 160, 118, 26), Paint()..color = const Color(0xFF14202B));
      _text(c, 'দোকান', const Offset(285, 173), 15, const Color(0xFFFFE08A));
      c.drawRect(const Rect.fromLTWH(232, 232, 54, 98), Paint()..color = glow);
      c.drawRect(const Rect.fromLTWH(232, 232, 54, 30), dark);
    } else {
      c.drawRect(const Rect.fromLTWH(220, 190, 132, 140), wall);
      c.drawPath(Path()..moveTo(204, 190)..lineTo(368, 190)..lineTo(286, 140)..close(), roof);
      c.drawRect(const Rect.fromLTWH(244, 226, 30, 26), Paint()..color = glow);
      c.drawRect(const Rect.fromLTWH(236, 286, 30, 44), dark);
    }
    // The meter box and its load wire.
    c.drawRRect(RRect.fromRectAndRadius(M8Geo.meter, const Radius.circular(4)), Paint()..color = const Color(0xFF455A64));
    c.drawCircle(M8Geo.meter.center.translate(0, -6), 11, Paint()..color = const Color(0xFFCFD8DC));
    c.drawLine(M8Geo.meter.center.translate(0, -6), M8Geo.meter.center.translate(5, -10), Paint()..color = const Color(0xFF263238)..strokeWidth = 1.6);
    c.drawLine(Offset(M8Geo.meter.center.dx, M8Geo.meter.bottom), Offset(M8Geo.meter.center.dx, M8Geo.meter.bottom + 24), Paint()..color = const Color(0xFF1E252B)..strokeWidth = 2.2);
    if (shop) {
      // The meter card: a domestic card on a shop.
      c.drawRect(const Rect.fromLTWH(296, 281, 48, 17), Paint()..color = const Color(0xFFFFFDF5));
      _text(c, 'গৃহস্থ', const Offset(320, 289.5), 11, const Color(0xFF14202B), weight: FontWeight.w700);
    }
  }

  @override
  bool shouldRepaint(M8CloseUpPainter old) => old.look != look || old.oy != oy || old.seed != seed;
}

/// A clip's thumbnail: the close-up scaled into the box, with the trace on it
/// (whatever it holds: every clip is saved).
class M8ThumbPainter extends CustomPainter {
  const M8ThumbPainter({required this.look, required this.trace});
  final M8Look look;
  final List<Offset> trace;

  @override
  void paint(Canvas c, Size size) {
    final s = size.width / M8Geo.w;
    c.save();
    c.clipRect(Offset.zero & size);
    c.scale(s);
    final sky = look.dusk ? const [Color(0xFF2B3A67), Color(0xFFE8A06A)] : const [Color(0xFF3B5A86), Color(0xFFF4C98B)];
    c.drawRect(
      const Rect.fromLTWH(0, 0, M8Geo.w, 400),
      Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: sky).createShader(const Rect.fromLTWH(0, 0, 360, 340)),
    );
    M8CloseUpPainter(look: look, oy: 0, seed: 0).paintBlock(c, const Size(M8Geo.w, 0));
    if (trace.length > 1) {
      c.drawPath(
        Path()..addPolygon(trace, false),
        Paint()
          ..color = const Color(0xFFFFC94A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
    c.restore();
  }

  @override
  bool shouldRepaint(M8ThumbPainter old) => old.look != look || !identical(old.trace, trace);
}

/// The live trace under the finger (repaints with [tick] only).
class M8TracePainter extends CustomPainter {
  M8TracePainter({required this.trace, required this.oy, required Listenable tick}) : super(repaint: tick);
  final List<Offset> trace;
  final double oy;

  @override
  void paint(Canvas c, Size size) {
    if (trace.isEmpty) return;
    c.save();
    c.translate(0, oy);
    final p = Paint()
      ..color = const Color(0xFFFFC94A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    if (trace.length > 1) c.drawPath(Path()..addPolygon(trace, false), p);
    c.drawCircle(trace.first, 5, Paint()..color = const Color(0xFFFFC94A));
    c.restore();
  }

  @override
  bool shouldRepaint(M8TracePainter old) => old.trace != trace || old.oy != oy;
}

/// The lane's geometry: n premises in a row, each a pole and a house.
@immutable
class M8LaneGeo {
  const M8LaneGeo(this.n, this.h);
  final int n;
  final double h;

  @override
  bool operator ==(Object other) => other is M8LaneGeo && other.n == n && other.h == h;

  @override
  int get hashCode => Object.hash(n, h);

  double get lineY => h * 0.2;
  double get groundY => h * 0.6;
  double get step => 336.0 / n;
  double get houseW => math.min(74.0, step - 14);
  double poleX(int i) => 16 + i * step;
  Rect house(int i) => Rect.fromLTWH(poleX(i) + 12, groundY - 70, houseW, 70);

  /// The tap area of premises [i]: its pole and its house.
  Rect premises(int i) => Rect.fromLTRB(poleX(i) - 8, lineY - 6, poleX(i) + 12 + houseW + 2, groundY + 6);

  /// Where the trainee stands to visit [i] (centre x).
  double standX(int i) => poleX(i) + 12 + houseW / 2;
  double get traineeY => groundY + 96;
  Rect trainee(double x) => Rect.fromCenter(center: Offset(x, traineeY), width: 62, height: 92);
  Rect get van => Rect.fromLTWH(262, groundY + 22, 92, 44);
}

/// The lane at evening, with every premises (the hook is too small to see).
class M8LanePainter extends CustomPainter {
  const M8LanePainter({required this.geo, required this.looks});
  final M8LaneGeo geo;
  final List<M8Look> looks;

  @override
  void paint(Canvas c, Size size) {
    final dusk = looks.isNotEmpty && looks.first.dusk;
    c.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: dusk ? const [Color(0xFF2B3A67), Color(0xFFE8A06A)] : const [Color(0xFF3B5A86), Color(0xFFF4C98B)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, geo.groundY)),
    );
    final g = geo;
    c.drawRect(Rect.fromLTRB(0, g.groundY, size.width, size.height), Paint()..color = const Color(0xFF4A4338));
    c.drawRect(Rect.fromLTRB(0, g.groundY + 70, size.width, size.height), Paint()..color = const Color(0xFF5B5446));
    final hill = Paint()..color = const Color(0xFF2E4A3A);
    for (final x in [30.0, 140.0, 240.0, 330.0]) {
      c.drawOval(Rect.fromCenter(center: Offset(x, g.groundY - 8), width: 120, height: 50), hill);
    }
    // The LT line across the lane.
    final wire = Paint()
      ..color = const Color(0xFF1E252B)
      ..strokeWidth = 1.4;
    for (var k = 0; k < 4; k++) {
      c.drawLine(Offset(0, g.lineY + k * 6), Offset(size.width, g.lineY + k * 6), wire);
    }
    for (var i = 0; i < g.n; i++) {
      final l = looks[i];
      final px = g.poleX(i);
      c.drawRect(Rect.fromLTRB(px - 3, g.lineY - 4, px + 3, g.groundY + 4), Paint()..color = const Color(0xFF6B523C));
      final r = g.house(i);
      final shop = l.kind == M8Kind.shop;
      c.drawRect(r, Paint()..color = shop ? const Color(0xFFCFB98A) : const Color(0xFFE2B4A0));
      if (shop) {
        for (var k = 0; k < 4; k++) {
          c.drawRect(Rect.fromLTWH(r.left + k * r.width / 4, r.top - 2, r.width / 4, 12), Paint()..color = k.isEven ? const Color(0xFFC0392B) : const Color(0xFFF2EBDD));
        }
        c.drawRect(Rect.fromLTWH(r.left + 8, r.top + 22, r.width - 16, 48), Paint()..color = l.cut ? const Color(0xFF2A2F36) : const Color(0xFFFFD27A));
      } else {
        c.drawPath(Path()..moveTo(r.left - 6, r.top)..lineTo(r.right + 6, r.top)..lineTo(r.center.dx, r.top - 26)..close(), Paint()..color = const Color(0xFF7A3E34));
        c.drawRect(Rect.fromLTWH(r.left + 8, r.top + 16, 16, 14), Paint()..color = l.cut ? const Color(0xFF2A2F36) : const Color(0xFFFFD27A));
        c.drawRect(Rect.fromLTWH(r.right - 22, r.top + 28, 14, 42), Paint()..color = const Color(0xFF3A2E26));
      }
      // The service drop, thin, at every premises.
      c.drawLine(Offset(px, g.lineY + 24), Offset(r.left + 2, r.top + 10), Paint()..color = const Color(0xFF1E252B)..strokeWidth = 1.2);
    }
    // The crew van.
    final v = g.van;
    c.drawRRect(RRect.fromRectAndRadius(v, const Radius.circular(8)), Paint()..color = const Color(0xFFECEFF1));
    c.drawRect(Rect.fromLTWH(v.left + 62, v.top + 6, 24, 16), Paint()..color = const Color(0xFF78909C));
    c.drawRect(Rect.fromLTWH(v.left + 4, v.top + 24, 56, 5), Paint()..color = const Color(0xFFE53935));
    for (final x in [v.left + 18, v.left + 70]) {
      c.drawCircle(Offset(x, v.bottom), 8, Paint()..color = const Color(0xFF263238));
    }
  }

  @override
  bool shouldRepaint(M8LanePainter old) => old.geo != geo || !sameLooks(old.looks, looks);

  static bool sameLooks(List<M8Look> a, List<M8Look> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
