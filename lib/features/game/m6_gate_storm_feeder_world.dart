import 'dart:math' as math;

import 'package:flutter/material.dart';

// The drawn places of the Module 6 rank gate (m6_gate_storm_feeder.dart): one
// feeder after a stormy night as a ~4-screen panorama (1440 design px wide,
// panned by swipe) — the substation window, recloser R-12, AB-1, the road
// crossing with its UG riser poles, the capacitor bank (some plays), a main
// line pole, the junction pole with S-3 and branch A (AB-A, its houses),
// AB-2, the DTR with its LT box, the AB-cable lane to houses, and the tie
// AB-T to ফিডার-5 on the main line (index 13, drawn after the bank). All in
// design pixels (360 wide, [M6GGeo.h] high). Nothing here names a fault: the
// devices are drawn the same way whatever their state; only the windows (the
// live cue), the player's own earths and the crew show what happened.

/// What does not change in a play (the painter's plan).
@immutable
class M6GPlan {
  const M6GPlan({required this.bank, required this.excavator, required this.kva, required this.ways, required this.fam});
  final bool bank;
  final bool excavator;
  final int kva;
  final int ways;

  /// The family's index (the UG family's excavator dug the road).
  final int fam;

  @override
  bool operator ==(Object other) => other is M6GPlan && other.bank == bank && other.excavator == excavator && other.kva == kva && other.ways == ways && other.fam == fam;
  @override
  int get hashCode => Object.hash(bank, excavator, kva, ways, fam);
}

/// What the panorama shows now.
@immutable
class M6GView {
  const M6GView({
    this.pan = 0,
    this.open = const {},
    this.earthed = const {},
    this.crewAt,
    this.lights = const [],
    this.lit = 1,
  });

  /// The panorama's left edge (world px).
  final double pan;

  /// Isolators drawn open (device index).
  final Set<int> open;

  /// Earth sets hanging: 0 main (at AB-1 and AB-2), 1 branch, 2 DTR.
  final Set<int> earthed;

  /// The crew at work (device index) or null.
  final int? crewAt;

  /// Each house window lit (world order).
  final List<bool> lights;

  /// The light-up beat (0 → 1).
  final double lit;

  @override
  bool operator ==(Object other) =>
      other is M6GView &&
      other.pan == pan &&
      other.crewAt == crewAt &&
      other.lit == lit &&
      _setEq(other.open, open) &&
      _setEq(other.earthed, earthed) &&
      _listEq(other.lights, lights);
  @override
  int get hashCode => Object.hash(pan, crewAt, lit, open.length, earthed.length, lights.length);
}

bool _setEq(Set<int> a, Set<int> b) => a.length == b.length && a.containsAll(b);
bool _listEq(List<bool> a, List<bool> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Layout of the gate's scene (design px; world x for the panorama).
@immutable
class M6GGeo {
  const M6GGeo(this.h, this.inset);
  final double h;
  final double inset;

  static const worldW = 1440.0;
  static const maxPan = worldW - 360;

  // --- the docket band -------------------------------------------------------
  Rect get docket => const Rect.fromLTWH(8, 100, 344, 64);
  Rect get chalk => const Rect.fromLTWH(14, 128, 46, 32);
  Rect sketch(int i) => Rect.fromLTWH(66 + i * 58.0, 128, 54, 32);
  Rect get watch => const Rect.fromLTWH(270, 103, 78, 22);

  // --- the panorama ------------------------------------------------------------
  double get beltTop => h - inset - 92;
  double get panoTop => 168;
  Rect get pano => Rect.fromLTRB(0, panoTop, 360, beltTop - 4);
  double get groundY => beltTop - 34;
  double get lineY => math.max(panoTop + 70, groundY - (groundY - panoTop) * 0.58);

  /// Each device's world x (left to right, in [M6GDev] order).
  static const devX = [78.0, 214.0, 320.0, 456.0, 564.0, 700.0, 800.0, 878.0, 968.0, 1060.0, 1176.0, 1176.0, 1330.0, 632.0];

  /// A device's hit box in world px.
  Rect devWorld(int i) {
    final x = devX[i];
    return switch (i) {
      0 => Rect.fromLTRB(x - 54, groundY - 128, x + 54, groundY - 20), // the substation window
      3 => Rect.fromLTRB(x - 66, groundY - 70, x + 66, groundY + 14), // the road crossing
      10 => Rect.fromLTRB(x - 44, lineY - 6, x + 44, groundY - 64), // the DTR and its AB
      11 => Rect.fromLTRB(x - 40, groundY - 60, x + 40, groundY + 10), // the LT box
      12 => Rect.fromLTRB(x - 80, groundY - 110, x + 80, groundY + 10), // the lane
      4 || 13 => Rect.fromLTRB(x - 30, lineY - 46, x + 30, groundY - 10), // the bank, the tie (narrower)
      _ => Rect.fromLTRB(x - 36, lineY - 46, x + 36, groundY - 10),
    };
  }

  /// A device's box on screen (design px) at [pan].
  Rect dev(int i, double pan) => devWorld(i).shift(Offset(-pan, 0));

  /// The pan that centres device [i].
  static double panFor(int i) => (devX[i] - 180).clamp(0.0, maxPan);

  /// House windows (world x of each house; the last three are the DTR lane).
  static const houseX = [430.0, 516.0, 930.0, 1000.0, 1262.0, 1330.0, 1398.0];

  // --- the belt ------------------------------------------------------------------
  Rect tok(int i) {
    const w = (344 - 6 * 4) / 7;
    return Rect.fromLTWH(8 + i * (w + 4), beltTop + 10, w, 66);
  }

  List<Rect> get tokens => [for (var i = 0; i < 7; i++) tok(i)];

  @override
  bool operator ==(Object other) => other is M6GGeo && other.h == h && other.inset == inset;
  @override
  int get hashCode => Object.hash(h, inset);
}

// ============================================================================
// The panorama
// ============================================================================

/// The tie's far feeder (a worker-readable plate).
const _feeder5 = 'ফিডার-5';

class M6GWorldPainter extends CustomPainter {
  const M6GWorldPainter({required this.geo, required this.plan, required this.view});
  final M6GGeo geo;
  final M6GPlan plan;
  final M6GView view;

  static final _pole = Paint()..color = const Color(0xFF6E6A63);
  static final _wire = Paint()
    ..color = const Color(0xFF1C2126)
    ..strokeWidth = 1.6
    ..style = PaintingStyle.stroke;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final pano = g.pano;
    c.save();
    c.clipRect(Rect.fromLTRB(0, 0, 360, g.beltTop));
    // Sky: a wet night after the storm.
    c.drawRect(
      Rect.fromLTRB(0, 0, 360, g.groundY),
      Paint()
        ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0B1424), Color(0xFF1C2A40), Color(0xFF2E3B4E)])
            .createShader(Rect.fromLTRB(0, 0, 360, g.groundY)),
    );
    // Torn clouds (far, slow parallax).
    final cloud = Paint()..color = const Color(0x33A9B8CC);
    for (var i = 0; i < 9; i++) {
      final x = (i * 190.0 - view.pan * 0.2) % 560 - 100;
      c.drawOval(Rect.fromCenter(center: Offset(x, pano.top + 14 + (i % 3) * 16), width: 120, height: 18), cloud);
    }
    // Far roofs (parallax ~0.35).
    final far = Paint()..color = const Color(0xFF1A2333);
    for (var i = 0; i < 26; i++) {
      final x = i * 70.0 - view.pan * 0.35;
      if (x < -80 || x > 440) continue;
      final hgt = 26.0 + (i * 37 % 30);
      c.drawRect(Rect.fromLTWH(x, g.groundY - 40 - hgt, 52, hgt + 40), far);
    }
    // Ground and puddles.
    c.drawRect(Rect.fromLTRB(0, g.groundY, 360, g.beltTop), Paint()..color = const Color(0xFF2B3320));
    c.save();
    c.translate(-view.pan, 0);
    final puddle = Paint()..color = const Color(0x553E5B7A);
    for (var i = 0; i < 12; i++) {
      c.drawOval(Rect.fromCenter(center: Offset(60 + i * 118.0, g.groundY + 12 + (i % 2) * 8), width: 46, height: 7), puddle);
    }
    _road(c);
    _substation(c);
    _mainLine(c);
    _houses(c);
    _dtr(c);
    _earths(c);
    _crew(c);
    c.restore();
    c.restore();
  }

  void _poleAt(Canvas c, double x, {double top = 0}) {
    final g = geo;
    final t = top == 0 ? g.lineY - 14 : top;
    c.drawRect(Rect.fromLTRB(x - 3.5, t, x + 3.5, g.groundY + 4), _pole);
    // The cross-arm.
    c.drawRect(Rect.fromLTRB(x - 22, g.lineY - 4, x + 22, g.lineY + 1), Paint()..color = const Color(0xFF4F4A42));
    final ins = Paint()..color = const Color(0xFFCBD2D8);
    for (final dx in [-18.0, 0.0, 18.0]) {
      c.drawRect(Rect.fromLTRB(x + dx - 2, g.lineY - 10, x + dx + 2, g.lineY - 3), ins);
    }
  }

  void _plate(Canvas c, String text, Offset at) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Color(0xFF1C2126))),
      textDirection: TextDirection.ltr,
    )..layout();
    final r = Rect.fromCenter(center: at, width: tp.width + 8, height: tp.height + 3);
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), Paint()..color = const Color(0xFFF2EBD8));
    tp.paint(c, Offset(r.left + 4, r.top + 1.5));
  }

  /// An isolator on its pole: three blades, closed or open (all alike).
  void _ab(Canvas c, double x, String label, {required bool open}) {
    final g = geo;
    _poleAt(c, x);
    final y = g.lineY - 22;
    final blade = Paint()
      ..color = const Color(0xFFB9C0C7)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (final dx in [-16.0, 0.0, 16.0]) {
      final a = Offset(x + dx - 6, y);
      final b = open ? Offset(x + dx - 2, y - 12) : Offset(x + dx + 6, y);
      c.drawLine(a, b, blade);
    }
    // The operating rod down the pole and the ground handle with its lead.
    final rod = Paint()
      ..color = const Color(0xFF8D949B)
      ..strokeWidth = 1.4;
    c.drawLine(Offset(x + 6, y + 2), Offset(x + 6, g.groundY - 26), rod);
    c.drawRect(Rect.fromLTRB(x + 2, g.groundY - 30, x + 16, g.groundY - 24), Paint()..color = const Color(0xFFB23A2E));
    c.drawLine(Offset(x + 9, g.groundY - 24), Offset(x + 18, g.groundY + 2), Paint()
      ..color = const Color(0xFF3F7A3A)
      ..strokeWidth = 1.2);
    _plate(c, label, Offset(x - 18, g.groundY - 60));
  }

  void _road(Canvas c) {
    final g = geo;
    const x = 456.0;
    c.drawRect(Rect.fromLTRB(x - 70, g.groundY - 4, x + 70, g.groundY + 22), Paint()..color = const Color(0xFF30343A));
    final dash = Paint()..color = const Color(0xFFE8E2C4);
    for (var i = 0; i < 6; i++) {
      c.drawRect(Rect.fromLTWH(x - 64 + i * 24, g.groundY + 8, 12, 2), dash);
    }
    // The two riser poles and the cable under the road.
    for (final px in [x - 58, x + 58]) {
      _poleAt(c, px);
      c.drawRect(Rect.fromLTRB(px + 4, g.lineY + 4, px + 8, g.groundY + 4), Paint()..color = const Color(0xFF26292D));
    }
    if (plan.excavator || plan.fam == 2) {
      // An excavator by the road (in the UG family it dug the road).
      final y = g.groundY - 6;
      c.drawRect(Rect.fromLTWH(x - 30, y - 22, 34, 18), Paint()..color = const Color(0xFFE0A21B));
      c.drawLine(Offset(x + 4, y - 18), Offset(x + 28, y - 34), Paint()
        ..color = const Color(0xFFE0A21B)
        ..strokeWidth = 4);
      c.drawRect(Rect.fromLTWH(x - 34, y - 4, 42, 6), Paint()..color = const Color(0xFF2A2A2A));
    }
  }

  void _substation(Canvas c) {
    final g = geo;
    const x = 78.0;
    c.drawRect(Rect.fromLTRB(x - 66, g.groundY - 140, x + 66, g.groundY + 2), Paint()..color = const Color(0xFF5E6670));
    c.drawRect(Rect.fromLTRB(x - 66, g.groundY - 148, x + 66, g.groundY - 138), Paint()..color = const Color(0xFF454C55));
    // The window with the breaker panel (two equal lamps, relay case).
    final win = Rect.fromLTRB(x - 48, g.groundY - 120, x + 48, g.groundY - 34);
    c.drawRect(win, Paint()..color = const Color(0xFFC9D4DE));
    c.drawRect(win.deflate(5), Paint()..color = const Color(0xFF2E353D));
    for (final dx in [-26.0, -12.0]) {
      c.drawCircle(Offset(x + dx, g.groundY - 96), 4.5, Paint()..color = const Color(0xFF8C939A));
    }
    c.drawRect(Rect.fromLTRB(x + 2, g.groundY - 106, x + 36, g.groundY - 70), Paint()..color = const Color(0xFF151A1F));
    _plate(c, 'VCB', Offset(x - 19, g.groundY - 112));
    // The feeder leaves the building.
    c.drawLine(Offset(x + 66, g.lineY - 6), Offset(214, g.lineY - 6), _wire);
  }

  void _mainLine(Canvas c) {
    final g = geo;
    // The main line: substation → R-12 → AB-1 → road → bank → pole → junction → AB-2 → DTR.
    final y = g.lineY - 6;
    c.drawLine(Offset(144, y), Offset(1176, y), _wire);
    c.drawLine(Offset(144, y + 6), Offset(1176, y + 6), _wire);
    // R-12 with its control box, counter window and handle.
    const rx = 214.0;
    _poleAt(c, rx);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(rx - 18, y + 8, rx + 18, y + 34), const Radius.circular(4)), Paint()..color = const Color(0xFF7D868E));
    c.drawRect(Rect.fromLTRB(rx - 12, g.groundY - 54, rx + 12, g.groundY - 30), Paint()..color = const Color(0xFF59626C));
    _plate(c, 'R-12', Offset(rx - 22, g.groundY - 66));
    _ab(c, 320, 'AB-1', open: view.open.contains(2));
    if (plan.bank) {
      const bx = 564.0;
      _poleAt(c, bx);
      final can = Paint()..color = const Color(0xFFA9B1B9);
      for (var i = 0; i < 3; i++) {
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(bx - 22 + i * 15.0, y + 22, 12, 26), const Radius.circular(2)), can);
      }
      c.drawRect(Rect.fromLTWH(bx - 18, g.groundY - 46, 36, 22), Paint()..color = const Color(0xFFF4E04D));
    }
    // The tie AB-T up to ফিডার-5 (normally open; drawn as its blades are).
    const tx = 632.0;
    final f5 = g.lineY - 50;
    c.drawLine(Offset(tx - 40, f5), Offset(tx + 50, f5), _wire);
    c.drawLine(Offset(tx - 16, g.lineY - 34), Offset(tx - 16, f5), _wire);
    _plate(c, _feeder5, Offset(tx + 28, f5 - 8));
    _ab(c, tx, 'AB-T', open: view.open.contains(13));
    _poleAt(c, 700);
    // The junction pole with S-3, and branch A up to its houses.
    const jx = 800.0;
    _poleAt(c, jx);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(jx - 10, y + 6, jx + 10, y + 26), const Radius.circular(3)), Paint()..color = const Color(0xFF6B7580));
    _plate(c, 'S-3', Offset(jx + 22, y + 16));
    c.drawLine(Offset(jx, y), Offset(1010, y - 30), _wire);
    _ab(c, 878, 'AB-A', open: view.open.contains(7));
    _poleAt(c, 968, top: g.lineY - 44);
    _ab(c, 1060, 'AB-2', open: view.open.contains(9));
  }

  void _houses(Canvas c) {
    final g = geo;
    for (var i = 0; i < M6GGeo.houseX.length; i++) {
      final x = M6GGeo.houseX[i];
      final body = Rect.fromLTRB(x - 26, g.groundY - 44, x + 26, g.groundY);
      c.drawRect(body, Paint()..color = const Color(0xFF6D5A47));
      final roof = Path()
        ..moveTo(x - 30, g.groundY - 44)
        ..lineTo(x, g.groundY - 64)
        ..lineTo(x + 30, g.groundY - 44)
        ..close();
      c.drawPath(roof, Paint()..color = const Color(0xFF4A3A2C));
      final on = i < view.lights.length && view.lights[i];
      final win = Paint()..color = on ? Color.lerp(const Color(0xFF2A2F36), const Color(0xFFFFD36B), view.lit)! : const Color(0xFF2A2F36);
      c.drawRect(Rect.fromLTWH(x - 18, g.groundY - 34, 12, 12), win);
      c.drawRect(Rect.fromLTWH(x + 6, g.groundY - 34, 12, 12), win);
      if (i >= 4) {
        // The veranda meter.
        c.drawRect(Rect.fromLTWH(x - 4, g.groundY - 20, 8, 10), Paint()..color = const Color(0xFFDAD6CC));
      }
    }
  }

  void _dtr(Canvas c) {
    final g = geo;
    const x = 1176.0;
    // The DTR double pole with its AB, HG sets and the tank.
    _ab(c, x - 22, '', open: view.open.contains(10));
    _poleAt(c, x + 22);
    final hg = Paint()..color = const Color(0xFFCBD2D8);
    for (final dx in [-14.0, 0.0, 14.0]) {
      c.drawRect(Rect.fromLTWH(x + dx - 2, g.lineY + 6, 4, 14), hg);
    }
    final tank = Rect.fromLTRB(x - 26, g.lineY + 30, x + 26, g.groundY - 72);
    c.drawRRect(RRect.fromRectAndRadius(tank, const Radius.circular(4)), Paint()..color = const Color(0xFF7C8A7A));
    for (var i = 0; i < 5; i++) {
      c.drawRect(Rect.fromLTWH(tank.left - 6, tank.top + 6 + i * (tank.height - 12) / 5, 4, (tank.height - 12) / 6), Paint()..color = const Color(0xFF66745F));
    }
    _plate(c, '${plan.kva} kVA', Offset(x, tank.center.dy));
    // The drain valve and the earth strip down to the ground.
    c.drawRect(Rect.fromLTWH(x + 18, tank.bottom - 8, 8, 6), Paint()..color = const Color(0xFF3A3A3A));
    c.drawLine(Offset(x - 24, tank.bottom), Offset(x - 30, g.groundY + 4), Paint()
      ..color = const Color(0xFF8C6A3A)
      ..strokeWidth = 2);
    // The LT box on the plinth.
    final lt = Rect.fromLTRB(x - 30, g.groundY - 54, x + 30, g.groundY - 6);
    c.drawRRect(RRect.fromRectAndRadius(lt, const Radius.circular(3)), Paint()..color = const Color(0xFF8B9299));
    for (var i = 0; i < plan.ways; i++) {
      c.drawRect(Rect.fromLTWH(lt.left + 6 + i * (48 / plan.ways), lt.top + 18, 48 / plan.ways - 4, 18), Paint()..color = const Color(0xFFE9E3D3));
    }
    _plate(c, 'LT', Offset(lt.center.dx, lt.top + 8));
    // The AB-cable lane to the houses.
    c.drawLine(Offset(x + 30, g.groundY - 40), Offset(1420, g.groundY - 54), Paint()
      ..color = const Color(0xFF111111)
      ..strokeWidth = 2.4);
  }

  void _earths(Canvas c) {
    final g = geo;
    final p = Paint()
      ..color = const Color(0xFF3FA34D)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    void at(double x) {
      for (final dx in [-6.0, 0.0, 6.0]) {
        c.drawLine(Offset(x + dx, g.lineY - 4), Offset(x + 10, g.groundY - 2), p);
      }
      c.drawRect(Rect.fromLTWH(x + 6, g.groundY - 4, 10, 4), Paint()..color = const Color(0xFF3FA34D));
    }

    if (view.earthed.contains(0)) {
      at(346);
      at(1034);
    }
    if (view.earthed.contains(1)) at(904);
    if (view.earthed.contains(2)) at(1188);
  }

  void _crew(Canvas c) {
    final i = view.crewAt;
    if (i == null) return;
    final g = geo;
    final x = M6GGeo.devX[i] + 14;
    final y = i == 11 || i == 12 || i == 3 ? g.groundY - 20 : g.lineY + 30;
    final body = Paint()..color = const Color(0xFFF2B632);
    c.drawCircle(Offset(x, y - 14), 5, Paint()..color = const Color(0xFFFFFFFF));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, y), width: 12, height: 18), const Radius.circular(3)), body);
  }

  @override
  bool shouldRepaint(M6GWorldPainter old) => old.geo != geo || old.plan != plan || old.view != view;
}

/// A deadly move plays out in colour over the frozen scene (0 → 1).
class M6GHarmPainter extends CustomPainter {
  const M6GHarmPainter({required this.at, required this.k});
  final Offset at;
  final double k;

  @override
  void paint(Canvas c, Size size) {
    if (k <= 0) return;
    final r = 18 + 140 * Curves.easeOut.transform(k.clamp(0.0, 1.0));
    c.drawCircle(
      at,
      r,
      Paint()
        ..shader = RadialGradient(colors: [
          Colors.white.withValues(alpha: (1 - k) * 0.95),
          const Color(0xFFFFE066).withValues(alpha: (1 - k) * 0.8),
          const Color(0x00FF8A00),
        ]).createShader(Rect.fromCircle(center: at, radius: r)),
    );
    final bolt = Paint()
      ..color = const Color(0xFFFFF59D).withValues(alpha: (1 - k).clamp(0.0, 1.0))
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final path = Path()..moveTo(at.dx, at.dy - 60);
    for (var i = 1; i <= 5; i++) {
      path.lineTo(at.dx + (i.isOdd ? 12 : -12), at.dy - 60 + i * 12);
    }
    c.drawPath(path, bolt);
  }

  @override
  bool shouldRepaint(M6GHarmPainter old) => old.k != k || old.at != at;
}
