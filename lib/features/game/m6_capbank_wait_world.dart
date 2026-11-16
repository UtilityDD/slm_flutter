import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The drawn world of lesson 6.7 কাজ 1 "ঘড়ি ধরে অপেক্ষা" (m6_capbank_wait.dart):
// a roadside 11 kV pole in the daytime. Up the pole: the line's three
// conductors on the crossarm (on some jobs the crew's line earth is set on
// them, its leads running down to the pole's earth point — set above the
// bank's own fuse), the capacitor bank's own switch (ON / OFF on its plate)
// and three fuse links, then the bank: a steel frame with 3 or 6 grey cans
// (star or delta busbars), a bushing terminal on each can, and the danger
// plate hung under the frame. At the pole foot the trainee (gloves), the van
// with the discharge rod leaning on it, the rod's earth lead and clamp on the
// ground, and the pole's earth point. On the small-capacitor job a ground
// panel stands by the pole instead: one LT power capacitor with three
// terminals, its earth bar and the same plate. Top left, a close-up of the
// trainee's big wristwatch: minute and hour hands and a rotating bezel.
//
// Nothing on the scene marks a terminal (no ring, no tick): the rod's spark
// is the only feedback, and only once per terminal. No text except what a
// worker reads: ON / OFF on the switch, DANGER on the plate, the bezel's
// minute numbers. Code-drawn, gradients, no bitmaps.
//
// Design: 360 wide × the scene's height; everything sits relative to the
// bottom (a tall phone gets more sky, never a stretched pole).

/// What the job is on.
enum M6CapKind {
  /// A pole bank; the line is shut down and the crew's earth is on it
  /// (above the bank's fuse: lesson myth 1).
  bankEarthed,

  /// A pole bank isolated by its own switch (lesson 6.7 point 2: every bank
  /// has a dedicated switch and fuse); the line stays in service above.
  bankAlone,

  /// A small LT power capacitor in a ground panel (lesson myth 2).
  small,
}

/// How the bank's cans are tied (lesson 6.7 point 2).
enum M6CapBus { star, delta }

/// Why the crew needs to get close (lesson 6.7 point 4 and pro tip 1).
enum M6CapFlavor { fuse, swollen, cold, small }

/// The line conductor (a decoy target on the earthed jobs).
const int m6CapLine = -1;

/// Where things are (design px, 360 wide).
@immutable
class M6CapGeo {
  const M6CapGeo._(this.height, this.base);

  factory M6CapGeo.forScene(double height, double inset) => M6CapGeo._(height, height - inset * 0.5);

  final double height;

  /// The visible bottom of the scene.
  final double base;

  // --- the watch (a close-up, fixed under the header) -------------------------
  static const Offset watchC = Offset(66, 207);
  static const double watchR = 48;
  Rect get watchHit => Rect.fromCircle(center: watchC, radius: watchR + 10);

  /// A point on the bezel ring at [minute] (0 = 12 o'clock).
  static Offset bezelAt(int minute, {double r = watchR - 5}) {
    final a = -math.pi / 2 + minute * math.pi / 30;
    return watchC + Offset(math.cos(a), math.sin(a)) * r;
  }

  // --- the pole and the line -------------------------------------------------
  static const double poleX = 262;
  double get lineY => base - 455;
  Rect get lineHit => Rect.fromLTWH(168, lineY - 13, 174, 26);
  Offset get lineSpot => Offset(300, lineY);

  /// The bank's switch and fuses (art only).
  double get switchY => base - 428;
  double get fuseY => base - 410;

  // --- the bank --------------------------------------------------------------
  double get bankTop => base - 395;

  /// Bank terminal [i] (3 cans: one row; 6 cans: two rows of three).
  Offset bankTerminal(int i, int cans) {
    final row = cans == 6 ? i ~/ 3 : 0;
    final col = i % 3;
    return Offset(190 + 60.0 * col, bankTop + 16 + 70.0 * row);
  }

  Rect bankCan(int i, int cans) {
    final t = bankTerminal(i, cans);
    return Rect.fromLTWH(t.dx - 20, t.dy + 18, 40, cans == 6 ? 32 : 50);
  }

  double bankBottom(int cans) => bankTop + (cans == 6 ? 140 : 90);

  /// The danger plate under the bank frame.
  Rect get bankPlate => Rect.fromLTWH(196, base - 250, 108, 26);

  // --- the small capacitor panel -----------------------------------------------
  Rect get panel => Rect.fromLTWH(150, base - 370, 160, 140);
  Offset smallTerminal(int i) => Offset(204 + 38.0 * i, base - 342);
  Rect get smallCan => Rect.fromLTWH(190, base - 324, 104, 54);
  Rect get smallPlate => Rect.fromLTWH(154, base - 332, 24, 64);
  Rect get earthBar => Rect.fromCenter(center: Offset(242, base - 252), width: 92, height: 26);

  // --- the pole foot -----------------------------------------------------------
  Offset get poleEarth => Offset(226, base - 92);
  Rect get poleEarthHit => Rect.fromCenter(center: poleEarth, width: 40, height: 36);

  /// The rod leaning on the van, its earth clamp on the ground.
  Offset get rodFoot => Offset(84, base - 96);
  Offset get rodHead => Offset(114, base - 202);
  Rect get rodHit => Rect.fromLTWH(66, base - 206, 60, 116);
  Offset get clampSpot => Offset(36, base - 80);
  Rect get clampHit => Rect.fromCenter(center: clampSpot, width: 46, height: 40);

  /// The rod in the trainee's hands.
  Offset get hands => Offset(178, base - 70);
  Offset get rodUp => Offset(206, base - 214);

  Rect get trainee => Rect.fromLTWH(150, base - 118, 46, 108);
  Rect get van => Rect.fromLTWH(0, base - 176, 112, 84);

  /// "নিরাপদ — ক্রুকে দিন" (a widget).
  Rect get handover => Rect.fromLTWH(8, base - 60, 196, 50);

  // --- per job -------------------------------------------------------------------
  int terminalCount(M6CapKind k, int cans) => k == M6CapKind.small ? 3 : cans;

  Offset terminal(M6CapKind k, int cans, int i) => i == m6CapLine ? lineSpot : (k == M6CapKind.small ? smallTerminal(i) : bankTerminal(i, cans));

  Rect terminalHit(M6CapKind k, int cans, int i) =>
      i == m6CapLine ? lineHit : Rect.fromCenter(center: terminal(k, cans, i), width: k == M6CapKind.small ? 34 : 44, height: 32);

  List<Rect> canHits(M6CapKind k, int cans) => k == M6CapKind.small ? [smallCan] : [for (var i = 0; i < cans; i++) bankCan(i, cans)];

  Rect plateHit(M6CapKind k) => k == M6CapKind.small ? smallPlate : bankPlate;

  Offset earth(M6CapKind k) => k == M6CapKind.small ? earthBar.center : poleEarth;
  Rect earthHit(M6CapKind k) => k == M6CapKind.small ? earthBar : poleEarthHit;

  @override
  bool operator ==(Object other) => other is M6CapGeo && other.height == height && other.base == base;

  @override
  int get hashCode => Object.hash(height, base);
}

/// What the pole shows now.
@immutable
class M6CapRig {
  const M6CapRig({
    required this.kind,
    required this.cans,
    required this.bus,
    required this.flavor,
    required this.badCan,
    this.switchOff = false,
    this.rodHeld = false,
    this.clampOn = false,
    this.hookAt,
  });

  final M6CapKind kind;
  final int cans;
  final M6CapBus bus;
  final M6CapFlavor flavor;

  /// The can that is swollen / cold / behind the blown fuse.
  final int badCan;

  final bool switchOff;
  final bool rodHeld;
  final bool clampOn;

  /// Where the held rod's hook rests (a terminal, [m6CapLine], or null).
  final int? hookAt;

  bool get earthed => kind == M6CapKind.bankEarthed;

  @override
  bool operator ==(Object other) =>
      other is M6CapRig &&
      other.kind == kind &&
      other.cans == cans &&
      other.bus == bus &&
      other.flavor == flavor &&
      other.badCan == badCan &&
      other.switchOff == switchOff &&
      other.rodHeld == rodHeld &&
      other.clampOn == clampOn &&
      other.hookAt == hookAt;

  @override
  int get hashCode => Object.hash(kind, cans, bus, flavor, badCan, switchOff, rodHeld, clampOn, hookAt);
}

const _steel = Color(0xFF7A848C);
const _steelDark = Color(0xFF4E565C);
const _can = Color(0xFFB9C1C6);
const _canDark = Color(0xFF7D878D);
const _porcelain = Color(0xFF8A4B2A);
const _copper = Color(0xFFC77B3A);
const _rodYellow = Color(0xFFF2C230);
const _earthGreen = Color(0xFF2E8B57);

class M6CapPainter extends CustomPainter {
  const M6CapPainter({required this.geo, required this.rig, required this.seed});

  final M6CapGeo geo;
  final M6CapRig rig;
  final int seed;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    final rnd = math.Random(seed);
    _sky(c, w, g, rnd);
    _ground(c, w, size.height, g);
    _pole(c, g);
    if (rig.kind == M6CapKind.small) {
      _panel(c, g);
    } else {
      _switchAndFuses(c, g);
      _bank(c, g);
      _plate(c, g.bankPlate);
    }
    if (rig.earthed) _lineEarth(c, g);
    _van(c, g);
    _poleEarth(c, g);
    _rodAndLead(c, g);
  }

  void _sky(Canvas c, double w, M6CapGeo g, math.Random rnd) {
    final sky = Rect.fromLTWH(0, 0, w, g.base - 120);
    c.drawRect(
      sky,
      Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF6FA8D6), Color(0xFFBFDDF0), Color(0xFFE9F2E4)]).createShader(sky),
    );
    final cloud = Paint()..color = const Color(0xCCFFFFFF);
    for (var i = 0; i < 3; i++) {
      final x = 30 + rnd.nextDouble() * 300;
      final y = 140 + rnd.nextDouble() * math.max(20, g.lineY - 170);
      c.drawOval(Rect.fromCenter(center: Offset(x, y), width: 70, height: 18), cloud);
      c.drawOval(Rect.fromCenter(center: Offset(x + 18, y - 7), width: 40, height: 18), cloud);
    }
    // Far trees.
    final tree = Paint()..color = const Color(0xFF5E8F5A);
    for (var x = -10.0; x < w + 20; x += 26 + rnd.nextDouble() * 14) {
      final r = 14 + rnd.nextDouble() * 10;
      c.drawCircle(Offset(x, g.base - 128 - r * 0.4), r, tree);
    }
  }

  void _ground(Canvas c, double w, double h, M6CapGeo g) {
    final verge = Rect.fromLTWH(0, g.base - 132, w, h - (g.base - 132));
    c.drawRect(verge, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8DB56A), Color(0xFF6C944C)]).createShader(verge));
    final road = Rect.fromLTWH(0, g.base - 36, w, 40);
    c.drawRect(road, Paint()..color = const Color(0xFF5B5F63));
    final dash = Paint()
      ..color = const Color(0xFFE8E2C8)
      ..strokeWidth = 2;
    for (var x = 6.0; x < w; x += 34) {
      c.drawLine(Offset(x, g.base - 16), Offset(x + 16, g.base - 16), dash);
    }
  }

  void _pole(Canvas c, M6CapGeo g) {
    const x = M6CapGeo.poleX;
    final top = g.lineY - 26;
    final r = Rect.fromLTRB(x - 7, top, x + 7, g.base - 110);
    c.drawRect(r, Paint()..shader = const LinearGradient(colors: [Color(0xFFB8B4AA), Color(0xFFE2DED4), Color(0xFF9C988E)]).createShader(r));
    // Crossarm, insulators and the three conductors.
    final arm = Rect.fromLTWH(x - 74, g.lineY + 6, 148, 7);
    c.drawRect(arm, Paint()..color = _steelDark);
    final wire = Paint()
      ..color = const Color(0xFF3C4246)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    for (final dx in [-62.0, 0.0, 62.0]) {
      final ins = Rect.fromCenter(center: Offset(x + dx, g.lineY), width: 9, height: 13);
      c.drawRRect(RRect.fromRectAndRadius(ins, const Radius.circular(3)), Paint()..color = _porcelain);
    }
    for (final dy in [-5.0, 0.0, 5.0]) {
      final p = Path()
        ..moveTo(0, g.lineY + dy - 4)
        ..quadraticBezierTo(180, g.lineY + dy + 6, 360, g.lineY + dy - 4);
      c.drawPath(p, wire);
    }
  }

  void _switchAndFuses(Canvas c, M6CapGeo g) {
    const x = M6CapGeo.poleX;
    // Drops from the line to the switch.
    final lead = Paint()
      ..color = const Color(0xFF3C4246)
      ..strokeWidth = 1.4;
    for (final dx in [-16.0, 0.0, 16.0]) {
      c.drawLine(Offset(x + dx, g.lineY + 4), Offset(x + dx, g.switchY - 6), lead);
    }
    // The switch: three blades, closed (ON) or swung open (OFF).
    final box = Rect.fromCenter(center: Offset(x, g.switchY), width: 54, height: 12);
    c.drawRect(box, Paint()..color = _steelDark);
    final blade = Paint()
      ..color = const Color(0xFFD9DDE0)
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    for (final dx in [-16.0, 0.0, 16.0]) {
      final from = Offset(x + dx, g.switchY - 6);
      final to = rig.switchOff ? from + const Offset(9, -8) : Offset(x + dx, g.switchY + 6);
      c.drawLine(from, to, blade);
    }
    _label(c, rig.switchOff ? 'OFF' : 'ON', Offset(x + 40, g.switchY), rig.switchOff ? const Color(0xFF2E7D32) : const Color(0xFFC62828));
    // Fuse links under the switch (one hangs blown on a fuse job).
    for (var k = 0; k < 3; k++) {
      final fx = x - 16 + 16.0 * k;
      final blown = rig.flavor == M6CapFlavor.fuse && k == rig.badCan % 3;
      final r = Rect.fromCenter(center: Offset(fx, g.fuseY), width: 5, height: 12);
      if (blown) {
        c.save();
        c.translate(fx, g.fuseY - 6);
        c.rotate(0.6);
        c.drawRect(const Rect.fromLTWH(-2.5, 0, 5, 12), Paint()..color = const Color(0xFF6B6B6B));
        c.restore();
      } else {
        c.drawRect(r, Paint()..color = const Color(0xFFCFC6B0));
      }
      c.drawLine(Offset(fx, g.fuseY + 6), Offset(fx, g.bankTop - 2), lead);
    }
  }

  void _bank(Canvas c, M6CapGeo g) {
    final n = rig.cans;
    final frame = Rect.fromLTRB(160, g.bankTop - 4, 340, g.bankBottom(n));
    final steel = Paint()
      ..color = _steel
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    c.drawRect(frame, steel);
    // The bus from the fuses along the frame top.
    final bus = Paint()
      ..color = const Color(0xFF8C9399)
      ..strokeWidth = 2;
    c.drawLine(Offset(166, g.bankTop - 2), Offset(334, g.bankTop - 2), bus);
    for (var i = 0; i < n; i++) {
      final body = g.bankCan(i, n);
      final swollen = rig.flavor == M6CapFlavor.swollen && i == rig.badCan;
      final shape = swollen
          ? (Path()
            ..moveTo(body.left, body.top)
            ..lineTo(body.right, body.top)
            ..quadraticBezierTo(body.right + 9, body.center.dy, body.right, body.bottom)
            ..lineTo(body.left, body.bottom)
            ..quadraticBezierTo(body.left - 9, body.center.dy, body.left, body.top)
            ..close())
          : (Path()..addRRect(RRect.fromRectAndRadius(body, const Radius.circular(3))));
      c.drawPath(shape, Paint()..shader = const LinearGradient(colors: [_canDark, _can, _canDark]).createShader(body.inflate(9)));
      if (swollen) {
        // An oil streak (lesson 6.7 point 4: swollen, leaking).
        c.drawLine(body.bottomCenter.translate(4, -2), body.bottomCenter.translate(4, 10), Paint()
          ..color = const Color(0xCC7A5A1C)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round);
      }
      _bushing(c, g.bankTerminal(i, n));
    }
    // Star: every can's tail on one bar; delta: links between the cans.
    final link = Paint()
      ..color = const Color(0xFFB0B6BA)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    if (rig.bus == M6CapBus.star) {
      final y = g.bankBottom(n) - 6;
      c.drawLine(Offset(170, y), Offset(330, y), link..strokeWidth = 2.4);
      for (var i = 0; i < n; i++) {
        final b = g.bankCan(i, n);
        c.drawLine(b.bottomCenter, Offset(b.center.dx, n == 6 && i < 3 ? b.bottom + 4 : y), link..strokeWidth = 1.4);
      }
    } else {
      for (var row = 0; row < (n == 6 ? 2 : 1); row++) {
        final a = g.bankCan(row * 3, n).bottomCenter.translate(0, 3);
        final b = g.bankCan(row * 3 + 1, n).bottomCenter.translate(0, 3);
        final d = g.bankCan(row * 3 + 2, n).bottomCenter.translate(0, 3);
        final p = Path()
          ..moveTo(a.dx, a.dy)
          ..lineTo(b.dx, b.dy)
          ..lineTo(d.dx, d.dy)
          ..quadraticBezierTo(b.dx, b.dy + 12, a.dx, a.dy);
        c.drawPath(p, link);
      }
    }
  }

  void _bushing(Canvas c, Offset t) {
    final shed = Paint()..color = _porcelain;
    for (var k = 0; k < 2; k++) {
      c.drawOval(Rect.fromCenter(center: t.translate(0, 6 + 5.0 * k), width: 14, height: 5), shed);
    }
    c.drawRect(Rect.fromCenter(center: t.translate(0, 9), width: 6, height: 12), shed);
    c.drawCircle(t, 3.4, Paint()..color = const Color(0xFFCFD3D6));
    c.drawCircle(t, 3.4, Paint()
      ..color = const Color(0xFF5C6266)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);
  }

  void _plate(Canvas c, Rect r) {
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), Paint()..color = const Color(0xFFF5C518));
    c.drawRRect(RRect.fromRectAndRadius(r.deflate(1.5), const Radius.circular(2)), Paint()
      ..color = const Color(0xFF1B1B1B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);
    if (r.width > r.height) {
      _label(c, 'DANGER', Offset(r.center.dx, r.top + 8), const Color(0xFFC62828), size: 7.5);
      final line = Paint()
        ..color = const Color(0xFF3A3A3A)
        ..strokeWidth = 1;
      c.drawLine(Offset(r.left + 10, r.top + 16), Offset(r.right - 10, r.top + 16), line);
      c.drawLine(Offset(r.left + 16, r.top + 20), Offset(r.right - 16, r.top + 20), line);
    } else {
      c.save();
      c.translate(r.center.dx, r.center.dy);
      c.rotate(-math.pi / 2);
      _label(c, 'DANGER', Offset.zero, const Color(0xFFC62828), size: 7);
      c.restore();
    }
  }

  void _panel(Canvas c, M6CapGeo g) {
    final p = g.panel;
    // Legs, the box, the open door.
    final leg = Paint()
      ..color = _steelDark
      ..strokeWidth = 4;
    c.drawLine(p.bottomLeft.translate(10, 0), Offset(p.left + 10, g.base - 112), leg);
    c.drawLine(p.bottomRight.translate(-10, 0), Offset(p.right - 10, g.base - 112), leg);
    c.drawRRect(RRect.fromRectAndRadius(p, const Radius.circular(4)), Paint()..shader = const LinearGradient(colors: [Color(0xFF9AA4A8), Color(0xFFC9D0D3)]).createShader(p));
    c.drawRect(p.deflate(6), Paint()..color = const Color(0xFF2F3A40));
    final door = Path()
      ..moveTo(p.right, p.top + 4)
      ..lineTo(p.right + 22, p.top + 14)
      ..lineTo(p.right + 22, p.bottom - 14)
      ..lineTo(p.right, p.bottom - 4)
      ..close();
    c.drawPath(door, Paint()..color = const Color(0xFFAEB7BB));
    // The capacitor and its three terminals.
    final can = g.smallCan;
    c.drawRRect(RRect.fromRectAndRadius(can, const Radius.circular(8)), Paint()..shader = const LinearGradient(colors: [_canDark, _can, _canDark]).createShader(can));
    for (var i = 0; i < 3; i++) {
      final t = g.smallTerminal(i);
      c.drawRect(Rect.fromCenter(center: t.translate(0, 8), width: 8, height: 14), Paint()..color = const Color(0xFF26292B));
      c.drawCircle(t, 3.4, Paint()..color = const Color(0xFFCFD3D6));
    }
    // The earth bar.
    final bar = g.earthBar.deflate(7);
    c.drawRect(bar, Paint()..color = _copper);
    for (var k = 0; k < 5; k++) {
      c.drawCircle(Offset(bar.left + 8 + 15.0 * k, bar.center.dy), 2, Paint()..color = const Color(0xFF6B3E18));
    }
    _plate(c, g.smallPlate);
  }

  void _lineEarth(Canvas c, M6CapGeo g) {
    final lead = Paint()
      ..color = _copper
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final to = g.poleEarth.translate(6, -6);
    for (final (k, dy) in [(0, -5.0), (1, 0.0), (2, 5.0)]) {
      final at = Offset(316 + 8.0 * k, g.lineY + dy + 2);
      c.drawRect(Rect.fromCenter(center: at, width: 6, height: 7), Paint()..color = _steelDark);
      final p = Path()
        ..moveTo(at.dx, at.dy + 3)
        ..quadraticBezierTo(at.dx + 14, (at.dy + to.dy) / 2, to.dx + 6.0 * k, to.dy);
      c.drawPath(p, lead);
    }
  }

  void _van(Canvas c, M6CapGeo g) {
    final v = g.van;
    final body = RRect.fromRectAndCorners(v, topLeft: const Radius.circular(6), topRight: const Radius.circular(14));
    c.drawRRect(body, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF4F4F0), Color(0xFFCFCFC8)]).createShader(v));
    c.drawRect(Rect.fromLTWH(v.right - 34, v.top + 10, 26, 22), Paint()..color = const Color(0xFF7FA3C0));
    c.drawRect(Rect.fromLTWH(v.left, v.top + 44, v.width, 6), Paint()..color = const Color(0xFF1F5F8F));
    for (final x in [v.left + 22, v.right - 24]) {
      c.drawCircle(Offset(x, v.bottom), 11, Paint()..color = const Color(0xFF222222));
      c.drawCircle(Offset(x, v.bottom), 5, Paint()..color = const Color(0xFF9A9A9A));
    }
  }

  void _poleEarth(Canvas c, M6CapGeo g) {
    final e = g.poleEarth;
    c.drawLine(Offset(M6CapGeo.poleX - 4, g.base - 112), e.translate(4, -4), Paint()
      ..color = _copper
      ..strokeWidth = 2);
    c.drawRect(Rect.fromCenter(center: e, width: 14, height: 10), Paint()..color = _earthGreen);
    c.drawRect(Rect.fromCenter(center: e.translate(0, 8), width: 20, height: 5), Paint()..color = const Color(0xFF6B5A3E));
  }

  void _rodAndLead(Canvas c, M6CapGeo g) {
    final Offset foot;
    final Offset head;
    if (rig.rodHeld) {
      foot = g.hands.translate(-8, 8);
      final h = rig.hookAt;
      head = h == null ? g.rodUp : g.terminal(rig.kind, rig.cans, h).translate(0, -2);
    } else {
      foot = g.rodFoot;
      head = g.rodHead;
    }
    // The earth lead from the rod to its clamp (on the ground or on earth).
    final clamp = rig.clampOn ? g.earth(rig.kind) : g.clampSpot;
    final lead = Path()
      ..moveTo(foot.dx, foot.dy)
      ..quadraticBezierTo((foot.dx + clamp.dx) / 2, math.max(foot.dy, clamp.dy) + 18, clamp.dx, clamp.dy);
    c.drawPath(lead, Paint()
      ..color = _copper
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: clamp, width: 12, height: 9), const Radius.circular(2)), Paint()..color = _steelDark);
    // The rod: yellow insulated stick, metal hook.
    c.drawLine(foot, head, Paint()
      ..color = _rodYellow
      ..strokeWidth = 4.2
      ..strokeCap = StrokeCap.round);
    final dir = (head - foot) / math.max(1.0, (head - foot).distance);
    final grip = foot + dir * 16;
    c.drawLine(foot, grip, Paint()
      ..color = const Color(0xFFC62828)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round);
    final hook = Path()
      ..moveTo(head.dx, head.dy)
      ..relativeLineTo(dir.dx * 7, dir.dy * 7)
      ..relativeQuadraticBezierTo(5, -4, 2, -9);
    c.drawPath(hook, Paint()
      ..color = const Color(0xFFD0D4D7)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke);
  }

  static void _label(Canvas c, String t, Offset centre, Color color, {double size = 8}) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: TextStyle(fontSize: size, fontWeight: FontWeight.w900, color: color, height: 1)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(M6CapPainter old) => old.geo != geo || old.rig != rig || old.seed != seed;
}

/// The big wristwatch (a close-up): repaints only when its minute or its
/// bezel changes ([repaint]); no seconds hand, so a still minute draws
/// nothing.
class M6WatchPainter extends CustomPainter {
  M6WatchPainter({required this.minute, required this.bezel, required this.hour}) : super(repaint: Listenable.merge([minute, bezel]));

  /// The watch's minute of the hour (any int; shown mod 60).
  final ValueListenable<int> minute;

  /// The bezel triangle's minute position (null: at 12).
  final ValueListenable<int?> bezel;

  /// The hour at the job's start (for the hour hand).
  final int hour;

  @override
  void paint(Canvas c, Size size) {
    const o = M6CapGeo.watchC;
    const r = M6CapGeo.watchR;
    // Strap.
    final strap = Rect.fromCenter(center: o, width: 46, height: r * 2 + 50);
    c.drawRRect(RRect.fromRectAndRadius(strap, const Radius.circular(10)), Paint()..color = const Color(0xFF3B2A1E));
    // Case and bezel ring.
    c.drawCircle(o, r + 3, Paint()..color = const Color(0x55000000));
    c.drawCircle(o, r, Paint()..shader = const RadialGradient(colors: [Color(0xFF3A4450), Color(0xFF1C232B)]).createShader(Rect.fromCircle(center: o, radius: r)));
    final b = bezel.value ?? 0;
    final numStyle = Paint()..color = const Color(0xFFE6E9EC);
    for (var k = 0; k < 60; k++) {
      final m = b + k;
      final a = -math.pi / 2 + m * math.pi / 30;
      final d = Offset(math.cos(a), math.sin(a));
      if (k % 10 == 0 && k != 0) {
        _text(c, '$k', o + d * (r - 6), 7);
      } else if (k % 5 == 0 && k != 0) {
        c.drawLine(o + d * (r - 9), o + d * (r - 3), numStyle..strokeWidth = 1.6);
      } else if (k != 0) {
        c.drawCircle(o + d * (r - 5), 0.8, numStyle);
      }
    }
    // The triangle (the bezel's 0).
    final ta = -math.pi / 2 + b * math.pi / 30;
    final td = Offset(math.cos(ta), math.sin(ta));
    final tn = Offset(-td.dy, td.dx);
    final tip = o + td * (r - 10);
    final tri = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo((o + td * (r - 2) + tn * 5).dx, (o + td * (r - 2) + tn * 5).dy)
      ..lineTo((o + td * (r - 2) - tn * 5).dx, (o + td * (r - 2) - tn * 5).dy)
      ..close();
    c.drawPath(tri, Paint()..color = const Color(0xFFF2C230));
    // Dial.
    const dr = r - 13;
    c.drawCircle(o, dr, Paint()..shader = const RadialGradient(colors: [Color(0xFFFDFBF5), Color(0xFFE3DED0)]).createShader(Rect.fromCircle(center: o, radius: dr)));
    final mark = Paint()
      ..color = const Color(0xFF2A2F35)
      ..strokeWidth = 1.4;
    for (var h = 0; h < 12; h++) {
      final a = h * math.pi / 6;
      final d = Offset(math.sin(a), -math.cos(a));
      c.drawLine(o + d * (dr - (h % 3 == 0 ? 6 : 3.5)), o + d * (dr - 1), mark..strokeWidth = h % 3 == 0 ? 2 : 1.2);
    }
    final m = minute.value;
    final hourA = ((hour % 12) + (m / 60)) * math.pi / 6;
    final minA = (m % 60) * math.pi / 30;
    c.drawLine(o, o + Offset(math.sin(hourA), -math.cos(hourA)) * (dr * 0.52), Paint()
      ..color = const Color(0xFF1E2329)
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round);
    c.drawLine(o, o + Offset(math.sin(minA), -math.cos(minA)) * (dr * 0.86), Paint()
      ..color = const Color(0xFF1E2329)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round);
    c.drawCircle(o, 2.6, Paint()..color = const Color(0xFFC62828));
  }

  static void _text(Canvas c, String t, Offset centre, double size) {
    final tp = TextPainter(
      text: TextSpan(text: t, style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, color: const Color(0xFFE6E9EC), height: 1)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(M6WatchPainter old) => old.minute != minute || old.bezel != bezel || old.hour != hour;
}

/// The rod's spark at a terminal ([v] 0 → 1 over its life).
class M6SparkPainter extends CustomPainter {
  const M6SparkPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    if (v >= 1) return;
    final a = (1 - v).clamp(0.0, 1.0);
    c.drawCircle(at, 6 + 10 * v, Paint()..color = Color.fromRGBO(255, 245, 180, 0.7 * a));
    final ray = Paint()
      ..color = Color.fromRGBO(255, 255, 255, a)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (var k = 0; k < 8; k++) {
      final ang = k * math.pi / 4 + 0.3;
      final d = Offset(math.cos(ang), math.sin(ang));
      c.drawLine(at + d * (4 + 6 * v), at + d * (10 + 12 * v), ray);
    }
  }

  @override
  bool shouldRepaint(M6SparkPainter old) => old.at != at || old.v != v;
}

/// A deadly touch: the stored charge flashes over at [at] in colour on the
/// grey scene ([v] 0 → 1).
class M6CapShockPainter extends CustomPainter {
  const M6CapShockPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final glow = Rect.fromCircle(center: at, radius: 30 + 60 * v);
    c.drawCircle(at, glow.width / 2, Paint()..shader = RadialGradient(colors: [Color.fromRGBO(255, 250, 210, 0.95 * v), Color.fromRGBO(120, 170, 255, 0.5 * v), const Color(0x00000000)]).createShader(glow));
    final bolt = Paint()
      ..color = Color.fromRGBO(200, 225, 255, v)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final rnd = math.Random(7);
    for (var k = 0; k < 6; k++) {
      final ang = k * math.pi / 3 + 0.4;
      var p = at;
      final path = Path()..moveTo(p.dx, p.dy);
      for (var s = 0; s < 4; s++) {
        p += Offset(math.cos(ang), math.sin(ang)) * (10 + 8 * v) + Offset(rnd.nextDouble() * 10 - 5, rnd.nextDouble() * 10 - 5);
        path.lineTo(p.dx, p.dy);
      }
      c.drawPath(path, bolt);
    }
  }

  @override
  bool shouldRepaint(M6CapShockPainter old) => old.at != at || old.v != v;
}
