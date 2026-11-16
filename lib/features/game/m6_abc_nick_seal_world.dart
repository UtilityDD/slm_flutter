import 'dart:math' as math;

import 'package:flutter/material.dart';

// The drawn world of lesson 6.6 কাজ 2 "কাটা আবরণ সিল করো" (m6_abc_nick_seal.dart).
//
// One span of an LT AB cable run on a residential road, daytime: two poles
// (numbered plates — the patrol names the span by them), the twisted bundle
// sagging between them, the road and the houses behind. Each job is a
// different place on the road (six looks: a tree whose branch reaches near
// the bundle, a shop sign, a service drop on an IPC, a street lamp, a
// boundary wall with a gate, an open plot). The trainee is up the left pole
// in a full-body harness, helmet and gloves; the crew's earth lead hangs from
// the bundle by the left pole (X1: PTW, isolation, tester and earths done by
// the crew — drawn, not scored).
//
// The player zooms the span 1×–3× (double-tap or pinch) and pans along it.
// Below [m6NickDetailZoom] the bundle is a plain twisted cable: no nick and
// no decoy can be seen. At 3× the bundle shows its cores and every small
// mark on them alike: printing, dust, a bird dropping, a ridge, a fallen
// twig — and the nick (a notch with the bright conductor showing). Nothing
// glows; no ring; no coverage bar.
//
// No text in the art except what a worker reads (the pole numbers). Code-drawn,
// gradients, no bitmaps. Design: 360 wide × the scene's height (560–900).

/// The place on the road (one per job; 3 of 6 dealt).
enum M6NickSpan { branch, shop, drop, lamp, wall, plot }

/// A small mark on the bundle that is not a nick.
enum M6NickDecoy { print, dust, dropping, ridge, twig }

/// The repair material dealt for a job.
enum M6NickMat { tape, tube }

/// The bundle shows its cores and marks from this zoom up.
const double m6NickDetailZoom = 2.4;

/// The most the span zooms.
const double m6NickMaxZoom = 3;

/// One tape turn covers this much of the span (t units).
const double m6NickTapeW = 0.012;

/// A heat-shrink tube's length (t units) and the end of it that does not
/// seal (each side).
const double m6NickTubeLen = 0.09;
const double m6NickTubeEdge = 0.005;

/// A mark on the bundle (t along the span, the core it sits on 0–2).
@immutable
class M6NickMark {
  const M6NickMark(this.kind, this.t, this.core);
  final M6NickDecoy kind;
  final double t;
  final int core;
}

/// Where things are (design px, 360 wide).
@immutable
class M6NickGeo {
  const M6NickGeo._(this.height, this.attachY, this.groundY);

  factory M6NickGeo.forScene(double height, double inset) {
    final a = 230 + (height - 560) * 0.42;
    final g = height - 96 - inset * 0.5;
    return M6NickGeo._(height, a, g);
  }

  final double height;

  /// Where the bundle hangs on the poles.
  final double attachY;

  /// The road's near edge.
  final double groundY;

  static const double spanL = 22;
  static const double spanR = 338;
  static const double spanW = spanR - spanL;
  static const double sag = 34;

  /// The bundle's half thickness (world px).
  static const double half = 4.2;

  /// The bundle's centre at [t] (0 = the left pole, 1 = the right).
  Offset cable(double t) => Offset(spanL + t * spanW, attachY + sag * 4 * t * (1 - t));

  /// The span place under world x.
  double tAt(double x) => ((x - spanL) / spanW).clamp(0.0, 1.0);

  /// The middle of the layer (the view's anchor).
  Offset get centre => Offset(180, height / 2);

  Rect get world => Rect.fromLTWH(0, 0, 360, height);

  /// The left pole's top, where the trainee is.
  Offset get trainee => Offset(spanL + 14, attachY + 26);
}

/// The camera on the span: zoom [z] around the world point [f].
@immutable
class M6NickView {
  const M6NickView(this.z, this.f);
  final double z;
  final Offset f;

  static M6NickView whole(M6NickGeo g) => M6NickView(1, g.centre);

  Offset toLayer(Offset w, M6NickGeo g) => (w - f) * z + g.centre;
  Offset toWorld(Offset l, M6NickGeo g) => (l - g.centre) / z + f;

  /// Zoom kept in 1–3, the view kept on the world.
  M6NickView clamped(M6NickGeo g) {
    final zz = z.clamp(1.0, m6NickMaxZoom);
    final hw = 180 / zz;
    final hh = g.height / 2 / zz;
    return M6NickView(zz, Offset(f.dx.clamp(hw, 360 - hw), f.dy.clamp(hh, g.height - hh)));
  }

  static M6NickView lerp(M6NickView a, M6NickView b, double v) => M6NickView(a.z + (b.z - a.z) * v, Offset.lerp(a.f, b.f, v)!);

  bool get detail => z >= m6NickDetailZoom - 1e-6;

  @override
  bool operator ==(Object other) => other is M6NickView && other.z == z && other.f == f;
  @override
  int get hashCode => Object.hash(z, f);
}

/// What the world shows now.
@immutable
class M6NickRig {
  const M6NickRig({
    required this.span,
    required this.poles,
    required this.nickT,
    required this.nickLen,
    required this.nickCore,
    required this.decoys,
    this.mark,
    this.turns = const [],
    this.tubeT,
    this.shrunk = false,
    this.rain = 0,
    this.sealed = false,
    this.bare = false,
  });

  final M6NickSpan span;

  /// The two poles' numbers (the patrol names them).
  final (int, int) poles;
  final double nickT;
  final double nickLen;
  final int nickCore;
  final List<M6NickMark> decoys;

  /// The player's chalk mark (t), if any.
  final double? mark;
  final List<double> turns;
  final double? tubeT;
  final bool shrunk;

  /// The drizzle after 'শেষ' (0–1) and whether the nick is sealed.
  final double rain;
  final bool sealed;

  /// The gloves are off (the deadly frame only).
  final bool bare;

  /// Same picture as [o] (turns only grow within a job, so their count is
  /// enough; the job's own fields change with the job).
  bool sameAs(M6NickRig o) =>
      span == o.span &&
      poles == o.poles &&
      nickT == o.nickT &&
      mark == o.mark &&
      turns.length == o.turns.length &&
      tubeT == o.tubeT &&
      shrunk == o.shrunk &&
      rain == o.rain &&
      sealed == o.sealed &&
      bare == o.bare;
}

/// The core's offset across the bundle (world px).
double m6NickCoreDy(int core) => (core - 1) * 2.3;

class M6NickWorldPainter extends CustomPainter {
  M6NickWorldPainter({required this.geo, required this.rig, required this.view});

  final M6NickGeo geo;
  final M6NickRig rig;
  final M6NickView view;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(geo.centre.dx, geo.centre.dy);
    canvas.scale(view.z);
    canvas.translate(-view.f.dx, -view.f.dy);
    _sky(canvas);
    _houses(canvas);
    _road(canvas);
    _place(canvas);
    _pole(canvas, M6NickGeo.spanL, rig.poles.$1);
    _pole(canvas, M6NickGeo.spanR, rig.poles.$2);
    _earth(canvas);
    _bundle(canvas);
    if (view.detail) _marks(canvas);
    _repair(canvas);
    _chalk(canvas);
    _traineeFig(canvas);
    if (rig.rain > 0) _drizzle(canvas);
    canvas.restore();
  }

  void _sky(Canvas c) {
    final r = geo.world;
    c.drawRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF9CC7E8), Color(0xFFDCEBF4), Color(0xFFF6EEDC)],
        ).createShader(r),
    );
    final cloud = Paint()..color = const Color(0xCCFFFFFF);
    for (final p in [Offset(70, geo.attachY - 150), Offset(250, geo.attachY - 175)]) {
      c.drawOval(Rect.fromCenter(center: p, width: 70, height: 18), cloud);
      c.drawOval(Rect.fromCenter(center: p.translate(14, -8), width: 40, height: 18), cloud);
    }
  }

  void _houses(Canvas c) {
    final base = geo.groundY - 40;
    final rng = math.Random(rig.span.index * 7 + 3);
    var x = -6.0;
    while (x < 366) {
      final w = 52 + rng.nextDouble() * 30;
      final h = 70 + rng.nextDouble() * 60;
      final r = Rect.fromLTWH(x, base - h, w, h);
      final tone = [const Color(0xFFE9D6B4), const Color(0xFFD8C7A8), const Color(0xFFCFD8C8), const Color(0xFFE4C9B8)][rng.nextInt(4)];
      c.drawRect(r, Paint()..color = tone);
      c.drawRect(Rect.fromLTWH(x - 2, base - h - 5, w + 4, 6), Paint()..color = const Color(0xFF9A8A72));
      final win = Paint()..color = const Color(0xFF6D8796);
      for (var wy = base - h + 14; wy < base - 18; wy += 26) {
        for (var wx = x + 9; wx < x + w - 14; wx += 20) {
          c.drawRect(Rect.fromLTWH(wx, wy, 10, 12), win);
        }
      }
      x += w + 4;
    }
  }

  void _road(Canvas c) {
    final top = geo.groundY - 40;
    c.drawRect(Rect.fromLTRB(0, top, 360, top + 14), Paint()..color = const Color(0xFFBDB3A1));
    final road = Rect.fromLTRB(0, top + 14, 360, geo.height);
    c.drawRect(road, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF6B6E73), Color(0xFF4A4D52)]).createShader(road));
    final dash = Paint()
      ..color = const Color(0xFFE8E2D0)
      ..strokeWidth = 3;
    for (var x = 8.0; x < 360; x += 40) {
      c.drawLine(Offset(x, top + 44), Offset(x + 20, top + 44), dash);
    }
  }

  void _place(Canvas c) {
    final base = geo.groundY - 40;
    switch (rig.span) {
      case M6NickSpan.branch:
        // A tree on the right; one branch reaches toward the bundle.
        final trunk = Paint()..color = const Color(0xFF6B4A2E);
        c.drawRect(Rect.fromLTWH(270, base - 120, 12, 120), trunk);
        final leaf = Paint()..color = const Color(0xFF4F8A3C);
        c.drawCircle(Offset(276, base - 140), 46, leaf);
        c.drawCircle(Offset(240, base - 128), 30, leaf);
        final b = geo.cable(0.72);
        c.drawLine(Offset(262, base - 110), b.translate(4, 22), trunk..strokeWidth = 4..strokeCap = StrokeCap.round);
        c.drawCircle(b.translate(0, 24), 9, leaf);
      case M6NickSpan.shop:
        final board = Rect.fromLTWH(70, base - 74, 110, 30);
        c.drawRRect(RRect.fromRectAndRadius(board, const Radius.circular(3)), Paint()..color = const Color(0xFFC0392B));
        c.drawRect(board.deflate(5), Paint()..color = const Color(0xFFF4D03F));
        c.drawRect(Rect.fromLTWH(70, base - 44, 110, 44), Paint()..color = const Color(0xFF7F8C8D));
        c.drawRect(Rect.fromLTWH(80, base - 38, 90, 38), Paint()..color = const Color(0xFF3E4A52));
      case M6NickSpan.drop:
        // A service drop off an IPC at t 0.3, down to a house.
        final ipc = geo.cable(0.3);
        c.drawLine(ipc, Offset(ipc.dx + 30, base - 70), Paint()
          ..color = const Color(0xFF222222)
          ..strokeWidth = 1.6);
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: ipc.translate(0, 3), width: 6, height: 9), const Radius.circular(1.5)), Paint()..color = const Color(0xFF1C1C1C));
        c.drawRect(Rect.fromLTWH(ipc.dx + 24, base - 76, 12, 8), Paint()..color = const Color(0xFFDADADA));
      case M6NickSpan.lamp:
        final p = Paint()..color = const Color(0xFF7D858C);
        c.drawRect(Rect.fromLTWH(196, base - 150, 5, 150), p);
        c.drawLine(Offset(198, base - 150), const Offset(222, 0).translate(0, base - 156), p..strokeWidth = 3);
        c.drawOval(Rect.fromCenter(center: Offset(224, base - 152), width: 16, height: 7), Paint()..color = const Color(0xFFF7E6A1));
      case M6NickSpan.wall:
        c.drawRect(Rect.fromLTWH(0, base - 36, 360, 36), Paint()..color = const Color(0xFFD9A47A));
        for (var x = 0.0; x < 360; x += 24) {
          c.drawLine(Offset(x, base - 36), Offset(x, base), Paint()
            ..color = const Color(0xFFB88560)
            ..strokeWidth = 1);
        }
        c.drawRect(Rect.fromLTWH(150, base - 46, 60, 46), Paint()..color = const Color(0xFF2F4F4F));
      case M6NickSpan.plot:
        c.drawRect(Rect.fromLTWH(0, base - 22, 360, 22), Paint()..color = const Color(0xFF9DBB6A));
        final bush = Paint()..color = const Color(0xFF5E8C3A);
        for (final x in [60.0, 130.0, 230.0, 300.0]) {
          c.drawCircle(Offset(x, base - 22), 16, bush);
        }
    }
  }

  void _pole(Canvas c, double x, int no) {
    final top = geo.attachY - 30;
    final r = Rect.fromLTRB(x - 5, top, x + 5, geo.groundY - 20);
    c.drawRect(r, Paint()..shader = const LinearGradient(colors: [Color(0xFF9AA1A8), Color(0xFF6E767E)]).createShader(r));
    // The clamp bracket.
    c.drawRect(Rect.fromLTWH(x - 7, geo.attachY - 4, 14, 6), Paint()..color = const Color(0xFF4A5056));
    // The number plate (a worker reads it).
    final plate = Rect.fromCenter(center: Offset(x, geo.attachY + 70), width: 22, height: 14);
    c.drawRect(plate, Paint()..color = const Color(0xFFF5F0E0));
    c.drawRect(plate, Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF333333)
      ..strokeWidth = 0.8);
    final tp = TextPainter(
      text: TextSpan(text: '$no', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, plate.center - Offset(tp.width / 2, tp.height / 2));
  }

  /// The crew's earth lead off the bundle by the left pole (X1).
  void _earth(Canvas c) {
    final a = geo.cable(0.03);
    final p = Paint()
      ..color = const Color(0xFF3E8E41)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(a.dx, a.dy + 3)
      ..quadraticBezierTo(a.dx - 18, (a.dy + geo.groundY) / 2, M6NickGeo.spanL - 10, geo.groundY - 22);
    c.drawPath(path, p);
    c.drawRect(Rect.fromCenter(center: a.translate(0, 3), width: 5, height: 4), Paint()..color = const Color(0xFFB8860B));
    c.drawRect(Rect.fromLTWH(M6NickGeo.spanL - 12, geo.groundY - 24, 4, 10), Paint()..color = const Color(0xFF8C6D3F));
    // The crew's tester beside the earth rod, its lamp showing 'dead proven'
    // (X1: done by the crew, unscored).
    final tb = Rect.fromLTWH(M6NickGeo.spanL - 4, geo.groundY - 20, 6, 10);
    c.drawRRect(RRect.fromRectAndRadius(tb, const Radius.circular(1.2)), Paint()..color = const Color(0xFFF2C230));
    c.drawCircle(tb.topCenter.translate(0, 2.6), 1.4, Paint()..color = const Color(0xFF2E9E44));
    c.drawLine(tb.bottomCenter, tb.bottomCenter.translate(0, 3), Paint()
      ..color = const Color(0xFF1A1A1A)
      ..strokeWidth = 1);
  }

  Path _cablePath() {
    final p = Path()..moveTo(geo.cable(0).dx, geo.cable(0).dy);
    for (var i = 1; i <= 60; i++) {
      final q = geo.cable(i / 60);
      p.lineTo(q.dx, q.dy);
    }
    return p;
  }

  void _bundle(Canvas c) {
    c.drawPath(
      _cablePath(),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = M6NickGeo.half * 2
        ..color = const Color(0xFF26292E),
    );
    // The twist: diagonal strands across the bundle.
    final s = Paint()
      ..color = const Color(0xFF454A52)
      ..strokeWidth = 0.9;
    for (var x = M6NickGeo.spanL + 3; x < M6NickGeo.spanR - 2; x += 5) {
      final p = geo.cable(geo.tAt(x));
      c.drawLine(p.translate(-1.6, -M6NickGeo.half + 0.6), p.translate(1.6, M6NickGeo.half - 0.6), s);
    }
    if (view.detail) {
      // The cores' seams (seen only up close).
      final seam = Paint()
        ..color = const Color(0xFF1A1C20)
        ..strokeWidth = 0.35
        ..style = PaintingStyle.stroke;
      for (final dy in [-1.15, 1.15]) {
        c.drawPath(_cablePath().shift(Offset(0, dy)), seam);
      }
    }
  }

  void _marks(Canvas c) {
    for (final d in rig.decoys) {
      _decoy(c, d);
    }
    _nick(c);
  }

  void _decoy(Canvas c, M6NickMark d) {
    final p = geo.cable(d.t).translate(0, m6NickCoreDy(d.core));
    switch (d.kind) {
      case M6NickDecoy.print:
        final pr = Paint()
          ..color = const Color(0xFFA7ADB4)
          ..strokeWidth = 0.6;
        for (var i = -1; i <= 1; i++) {
          c.drawLine(p.translate(i * 2.4 - 0.8, 0), p.translate(i * 2.4 + 0.8, 0), pr);
        }
      case M6NickDecoy.dust:
        c.drawOval(Rect.fromCenter(center: p, width: 5.5, height: 2.6), Paint()..color = const Color(0x998B7355));
      case M6NickDecoy.dropping:
        c.drawOval(Rect.fromCenter(center: p.translate(0, -0.6), width: 3.6, height: 2.4), Paint()..color = const Color(0xFFF1F0EA));
        c.drawCircle(p.translate(0.6, -0.8), 0.6, Paint()..color = const Color(0xFF8C8C80));
      case M6NickDecoy.ridge:
        c.drawLine(p.translate(-2.8, -0.5), p.translate(2.8, -0.5), Paint()
          ..color = const Color(0xFF5D636B)
          ..strokeWidth = 0.7);
      case M6NickDecoy.twig:
        c.drawLine(p.translate(-4, -2.6), p.translate(4, 1.8), Paint()
          ..color = const Color(0xFF7A5434)
          ..strokeWidth = 0.9
          ..strokeCap = StrokeCap.round);
    }
  }

  /// The nick: a notch in one core with the bright conductor showing.
  void _nick(Canvas c) {
    final w = rig.nickLen * M6NickGeo.spanW;
    final p = geo.cable(rig.nickT).translate(0, m6NickCoreDy(rig.nickCore));
    final notch = Path()
      ..moveTo(p.dx - w / 2, p.dy - 0.4)
      ..lineTo(p.dx - w / 4, p.dy - 1.2)
      ..lineTo(p.dx, p.dy - 0.7)
      ..lineTo(p.dx + w / 4, p.dy - 1.3)
      ..lineTo(p.dx + w / 2, p.dy - 0.3)
      ..lineTo(p.dx + w / 4, p.dy + 0.9)
      ..lineTo(p.dx - w / 4, p.dy + 0.8)
      ..close();
    c.drawPath(notch, Paint()..color = const Color(0xFF0E0F11));
    c.drawOval(Rect.fromCenter(center: p, width: w * 0.62, height: 0.9), Paint()..color = const Color(0xFFC9D1D8));
  }

  void _repair(Canvas c) {
    final tape = Paint()..color = const Color(0xFF151515);
    final sheen = Paint()
      ..color = const Color(0x55FFFFFF)
      ..strokeWidth = 0.4;
    final tw = m6NickTapeW * M6NickGeo.spanW;
    for (final t in rig.turns) {
      final p = geo.cable(t);
      final r = Rect.fromCenter(center: p, width: tw, height: M6NickGeo.half * 2 + 1.6);
      c.save();
      c.translate(p.dx, p.dy);
      c.rotate(-0.18);
      c.translate(-p.dx, -p.dy);
      c.drawRect(r, tape);
      c.drawLine(r.topLeft.translate(0.6, 0.4), r.bottomLeft.translate(0.6, -0.4), sheen);
      c.restore();
    }
    final tt = rig.tubeT;
    if (tt != null) {
      final p = geo.cable(tt);
      final len = m6NickTubeLen * M6NickGeo.spanW;
      final hgt = M6NickGeo.half * 2 + (rig.shrunk ? 1.2 : 5);
      final r = RRect.fromRectAndRadius(Rect.fromCenter(center: p, width: len, height: hgt), Radius.circular(hgt / 2));
      c.drawRRect(r, Paint()..color = rig.shrunk ? const Color(0xFF111214) : const Color(0xCC2C2F35));
      c.drawRRect(
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5
          ..color = rig.shrunk ? const Color(0x66FFFFFF) : const Color(0xFF8A9099),
      );
    }
  }

  /// The player's chalk: a short V under the bundle pointing up at the spot.
  void _chalk(Canvas c) {
    final m = rig.mark;
    if (m == null) return;
    final p = geo.cable(m).translate(0, M6NickGeo.half + 2.2);
    final s = Paint()
      ..color = const Color(0xFFF7F3E3)
      ..strokeWidth = 0.9
      ..strokeCap = StrokeCap.round;
    c.drawLine(p, p.translate(-2.4, 4), s);
    c.drawLine(p, p.translate(2.4, 4), s);
  }

  /// The trainee up the left pole: harness, helmet, gloves (or not).
  void _traineeFig(Canvas c) {
    final o = geo.trainee;
    final body = Paint()..color = const Color(0xFF2F5D8A);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: o, width: 9, height: 16), const Radius.circular(3)), body);
    c.drawRect(Rect.fromCenter(center: o.translate(0, 13), width: 8, height: 12), Paint()..color = const Color(0xFF263A52));
    final strap = Paint()
      ..color = const Color(0xFFE67E22)
      ..strokeWidth = 1.4;
    c.drawLine(o.translate(-3.5, -7), o.translate(3, 6), strap);
    c.drawLine(o.translate(3.5, -7), o.translate(-3, 6), strap);
    // The lanyard round the pole.
    c.drawLine(o.translate(-4, 2), Offset(M6NickGeo.spanL, o.dy + 1), strap..strokeWidth = 1);
    c.drawCircle(o.translate(0, -12), 3.6, Paint()..color = const Color(0xFFE8B98F));
    c.drawArc(Rect.fromCenter(center: o.translate(0, -13), width: 9, height: 7), math.pi, math.pi, true, Paint()..color = const Color(0xFFF4C430));
    // The arm up to the bundle; the hand gloved.
    final hand = geo.cable(0.06).translate(0, 4);
    c.drawLine(o.translate(3, -5), hand, Paint()
      ..color = const Color(0xFF2F5D8A)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round);
    c.drawCircle(hand, 2.2, Paint()..color = rig.bare ? const Color(0xFFE8B98F) : const Color(0xFFC0392B));
  }

  void _drizzle(Canvas c) {
    final v = rig.rain;
    final vis = Rect.fromCenter(center: view.f, width: 360 / view.z, height: geo.height / view.z);
    final rng = math.Random(11);
    final drop = Paint()
      ..color = const Color(0x886FA8DC)
      ..strokeWidth = 0.8 / view.z * 1.4;
    for (var i = 0; i < 46; i++) {
      final x = vis.left + rng.nextDouble() * vis.width;
      final y0 = vis.top + rng.nextDouble() * vis.height;
      final y = vis.top + ((y0 - vis.top + v * vis.height * 0.9) % vis.height);
      c.drawLine(Offset(x, y), Offset(x - 1.2 / view.z * 3, y + 6 / view.z * 2), drop);
    }
    final n = geo.cable(rig.nickT).translate(0, m6NickCoreDy(rig.nickCore));
    if (rig.sealed) {
      // Beads roll off the repair and drop away.
      for (var k = 0; k < 3; k++) {
        final p = n.translate((k - 1) * 3.0, M6NickGeo.half + 1 + v * 14 + k * 2.0);
        c.drawCircle(p, 0.9, Paint()..color = const Color(0xCC8EC3EA));
      }
    } else {
      // Water creeps in at the open part.
      c.drawCircle(n, 0.6 + v * 2.6, Paint()..color = Color.fromRGBO(70, 140, 220, 0.25 + 0.5 * v));
    }
  }

  @override
  bool shouldRepaint(M6NickWorldPainter old) => !old.rig.sameAs(rig) || old.view != view || old.geo.height != geo.height;
}

/// The deadly moment: a flash at the bare hand on the bundle.
class M6NickFlashPainter extends CustomPainter {
  const M6NickFlashPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas canvas, Size size) {
    final r = 20 + 90 * v;
    canvas.drawCircle(
      at,
      r,
      Paint()
        ..shader = RadialGradient(colors: [
          Color.fromRGBO(255, 255, 255, 0.95 * (1 - v * 0.6)),
          Color.fromRGBO(140, 200, 255, 0.7 * (1 - v * 0.5)),
          const Color(0x00508CFF),
        ]).createShader(Rect.fromCircle(center: at, radius: r)),
    );
    final bolt = Paint()
      ..color = Color.fromRGBO(255, 245, 160, 1 - v * 0.5)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final p = Path()..moveTo(at.dx, at.dy);
    var q = at;
    final rng = math.Random(5);
    for (var i = 0; i < 5; i++) {
      q = q.translate(-8 + rng.nextDouble() * 16, 12);
      p.lineTo(q.dx, q.dy);
    }
    canvas.drawPath(p, bolt);
  }

  @override
  bool shouldRepaint(M6NickFlashPainter old) => old.v != v || old.at != at;
}
