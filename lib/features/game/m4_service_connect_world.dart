import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The drawn world of lesson 4.3 কাজ 2 "সংযোগ দাও" (m4_service_connect.dart):
// a village lane at dusk — the LT pole on the left with its insulated LT line
// (four marked conductors R · Y · B · N), the anchor clamp under the line and
// the service fuse; the GI bearer wire from the clamp to the rack bolt on the
// consumer's new house; the service cable along it (hanging slack until it is
// strapped); at the house the drip loop, the meter board and its two
// incoming terminals (L, N), the two marked cores of the cable. Code-drawn,
// gradients, no bitmaps. Design space 360 wide; the ground sits
// [M4ServiceConnectGeo.floorUp] above the bottom so the two tool rows sit on it.

/// Where things are in the scene (design px, 360 wide).
@immutable
class M4ServiceConnectGeo {
  const M4ServiceConnectGeo._(this.height, this.groundY);

  factory M4ServiceConnectGeo.forScene(double height, double inset) => M4ServiceConnectGeo._(height, height - floorUp - inset * 0.5);

  final double height;

  /// The ground line.
  final double groundY;

  static const double floorUp = 176;
  static const double poleX = 46;

  // --- the LT line (four conductors, top → bottom) ---
  double get ltTop => groundY - 362;
  double conductorY(int k) => ltTop + 24.0 * k;
  Rect conductorHit(int k) => Rect.fromLTRB(64, conductorY(k) - 11, 214, conductorY(k) + 11);

  /// Where the IPC of fit [n] (0 or 1) sits on its conductor.
  double ipcX(int n) => 112 + 30.0 * n;
  Rect ipcHit(int n, int k) => Rect.fromCenter(center: Offset(ipcX(n), conductorY(k) + 4), width: 30, height: 26);

  // --- the pole end ---
  double get clampY => groundY - 252;
  Offset get clamp => Offset(poleX + 9, clampY);

  /// The cable's two marked cores at the pole (0 = L, 1 = N), before the IPC.
  List<Offset> get poleCores => [Offset(96, clampY - 20), Offset(122, clampY - 20)];
  Rect poleCoreHit(int c) => Rect.fromCenter(center: poleCores[c] + const Offset(0, 4), width: 26, height: 34);

  /// The service fuse on the pole.
  Rect get fuse => Rect.fromLTWH(poleX + 9, clampY + 30, 18, 30);

  // --- the span ---
  Offset get rackBolt => Offset(236, groundY - 206);
  Rect get spanHit => Rect.fromLTRB(118, clampY - 6, 214, rackBolt.dy + 30);

  /// A point on the bearer wire (0 = clamp, 1 = rack bolt).
  Offset bearerAt(double u) {
    final a = clamp;
    final b = rackBolt;
    final sag = 14 * 4 * u * (1 - u);
    return Offset(a.dx + (b.dx - a.dx) * u, a.dy + (b.dy - a.dy) * u + sag);
  }

  // --- the house end ---
  Rect get house => Rect.fromLTRB(224, groundY - 236, 360, groundY);

  /// Where the cable comes down the wall (tap to make the drip loop).
  Rect get entryHit => Rect.fromLTWH(222, rackBolt.dy + 4, 30, 44);
  Rect get meterBox => Rect.fromLTWH(256, groundY - 178, 66, 72);

  /// The two incoming terminals (left, right) under the meter's face.
  List<Offset> get terminals => [Offset(274, meterBox.bottom - 13), Offset(304, meterBox.bottom - 13)];
  Rect terminalHit(int i) => Rect.fromCenter(center: terminals[i], width: 28, height: 30);

  /// The cable's two marked cores at the house (0 = L, 1 = N), before they go in.
  List<Offset> get houseCores => [Offset(268, meterBox.bottom + 30), Offset(310, meterBox.bottom + 30)];
  Rect houseCoreHit(int c) => Rect.fromCenter(center: houseCores[c] + const Offset(0, 6), width: 30, height: 38);
  Rect get window => Rect.fromLTWH(334, groundY - 150, 22, 34);

  // --- the ground ---
  static const scrapXs = [236.0, 262.0, 292.0, 320.0];
  Rect scrapHit(double x) => Rect.fromCenter(center: Offset(x, groundY - 6), width: 38, height: 30);

  /// Where the lineman stands (on the ground), or hangs on the pole (harness on).
  Rect get traineeGround => Rect.fromLTWH(194, groundY - 140, 64, 140);
  Rect get traineePole => Rect.fromLTWH(-4, clampY - 46, 58, 116);

  @override
  bool operator ==(Object other) => other is M4ServiceConnectGeo && other.height == height && other.groundY == groundY;

  @override
  int get hashCode => Object.hash(height, groundY);
}

/// What the scene shows now.
@immutable
class M4ServiceConnectView {
  const M4ServiceConnectView({
    required this.ltOrder,
    required this.meterLeftIsL,
    required this.strapped,
    required this.drip,
    required this.houseIn,
    required this.ipcs,
    required this.sheared,
    required this.shutdown,
    required this.earthed,
    required this.harness,
    required this.fuseIn,
    required this.scraps,
    required this.lit,
    required this.selHouse,
    required this.selPole,
  });

  /// The conductors top → bottom: 0 R, 1 Y, 2 B, 3 N.
  final List<int> ltOrder;

  /// The meter's left incoming terminal is L (else N).
  final bool meterLeftIsL;
  final bool strapped;
  final bool drip;

  /// Cores in their meter terminal (0 = L, 1 = N).
  final Set<int> houseIn;

  /// Per core (0 = L, 1 = N): the conductor row it is on, and its fit order.
  final Map<int, (int row, int fit)> ipcs;
  final Set<int> sheared;
  final bool shutdown;
  final bool earthed;
  final bool harness;
  final bool fuseIn;
  final List<double> scraps;
  final bool lit;
  final int? selHouse;
  final int? selPole;

  @override
  bool operator ==(Object other) =>
      other is M4ServiceConnectView &&
      listEquals(other.ltOrder, ltOrder) &&
      other.meterLeftIsL == meterLeftIsL &&
      other.strapped == strapped &&
      other.drip == drip &&
      setEquals(other.houseIn, houseIn) &&
      mapEquals(other.ipcs, ipcs) &&
      setEquals(other.sheared, sheared) &&
      other.shutdown == shutdown &&
      other.earthed == earthed &&
      other.harness == harness &&
      other.fuseIn == fuseIn &&
      listEquals(other.scraps, scraps) &&
      other.lit == lit &&
      other.selHouse == selHouse &&
      other.selPole == selPole;

  @override
  int get hashCode => Object.hash(Object.hashAll(ltOrder), meterLeftIsL, strapped, drip, Object.hashAllUnordered(houseIn), Object.hashAllUnordered(ipcs.entries.map((e) => Object.hash(e.key, e.value))),
      Object.hashAllUnordered(sheared), shutdown, earthed, harness, fuseIn, Object.hashAll(scraps), lit, selHouse, selPole);
}

const m4ServiceConnectCoreColors = [Color(0xFFD63A2F), Color(0xFF1E1F22)];
const m4ServiceConnectConductorNames = ['R', 'Y', 'B', 'N'];

/// The lane: sky, far trees, the pole and its LT line, the span, the house.
class M4ServiceConnectPainter extends CustomPainter {
  M4ServiceConnectPainter({required this.geo, required this.view, required this.t, required this.seed}) : super(repaint: t);

  final M4ServiceConnectGeo geo;
  final M4ServiceConnectView view;
  final ValueListenable<double> t;
  final int seed;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    // Dusk sky.
    c.drawRect(
        Rect.fromLTWH(0, 0, w, g.groundY),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3F5E8C), Color(0xFF9DB4CF), Color(0xFFF0C99A)],
          ).createShader(Rect.fromLTWH(0, 0, w, g.groundY)));
    // Far trees and huts.
    final rnd = math.Random(seed);
    final horizon = g.groundY - 60;
    final tree = Paint()..color = const Color(0xFF47704A);
    for (var x = -10.0; x < w + 20; x += 20 + rnd.nextDouble() * 22) {
      final r = 12 + rnd.nextDouble() * 12;
      c.drawCircle(Offset(x, horizon - r * 0.5), r, tree);
    }
    c.drawRect(Rect.fromLTWH(0, horizon, w, g.groundY - horizon), Paint()..color = const Color(0xFF7FA35A));
    // The lane.
    final ground = Rect.fromLTRB(0, g.groundY, w, size.height);
    c.drawRect(ground, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFB59B76), Color(0xFF8C7556)]).createShader(ground));
    c.drawLine(Offset(0, g.groundY), Offset(w, g.groundY), Paint()
      ..color = const Color(0xFF6E5B42)
      ..strokeWidth = 2);

    _house(c, size);
    _pole(c);
    _lt(c, w);
    _span(c);
    _poleEnd(c);
    _houseEnd(c);
    _scraps(c);
  }

  void _pole(Canvas c) {
    final g = geo;
    const x = M4ServiceConnectGeo.poleX;
    final top = g.ltTop - 30;
    final pole = Path()
      ..moveTo(x - 6, top)
      ..lineTo(x + 6, top)
      ..lineTo(x + 10, g.groundY + 4)
      ..lineTo(x - 10, g.groundY + 4)
      ..close();
    c.drawPath(pole, Paint()..shader = const LinearGradient(colors: [Color(0xFF8D9197), Color(0xFFC9CDD2), Color(0xFF7E8288)]).createShader(Rect.fromLTWH(x - 10, top, 20, g.groundY - top)));
    // Danger plate.
    final plate = Rect.fromLTWH(x - 8, g.groundY - 120, 16, 20);
    c.drawRect(plate, Paint()..color = const Color(0xFFF3F0E6));
    c.drawRect(plate.deflate(2.5), Paint()..color = const Color(0xFFC62828));
    // Harness on the pole: the belt round it and the lanyard.
    if (view.harness) {
      final y = g.clampY - 4;
      c.drawLine(Offset(x - 14, y), Offset(x + 14, y), Paint()
        ..color = const Color(0xFFFF8F00)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round);
    }
  }

  void _lt(Canvas c, double w) {
    final g = geo;
    const x = M4ServiceConnectGeo.poleX;
    // The LT bracket and the four insulated conductors along the lane.
    for (var k = 0; k < 4; k++) {
      final y = g.conductorY(k);
      final isN = view.ltOrder[k] == 3;
      c.drawLine(Offset(0, y + 1.5), Offset(w, y + 1.5), Paint()
        ..color = const Color(0x33000000)
        ..strokeWidth = 4);
      c.drawLine(Offset(0, y), Offset(w, y), Paint()
        ..color = const Color(0xFF15171A)
        ..strokeWidth = 4.2);
      // The bracket clamp at the pole.
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(x, y), width: 22, height: 8), const Radius.circular(3)), Paint()..color = const Color(0xFF5B6168));
      // The core's marking tag near the pole.
      final tag = Rect.fromCenter(center: Offset(78, y - 8), width: 16, height: 13);
      c.drawRRect(RRect.fromRectAndRadius(tag, const Radius.circular(3)), Paint()..color = isN ? const Color(0xFF263238) : const Color(0xFFF4E6B8));
      _label(c, m4ServiceConnectConductorNames[view.ltOrder[k]], tag.center, 9, isN ? Colors.white : const Color(0xFF3A2A0A));
    }
    // The shutdown earth: a set clamped on all four conductors, its lead down the pole.
    if (view.earthed) {
      final ex = x + 26;
      for (var k = 0; k < 4; k++) {
        final y = g.conductorY(k);
        c.drawRect(Rect.fromCenter(center: Offset(ex, y), width: 8, height: 10), Paint()..color = const Color(0xFFB0882E));
      }
      c.drawLine(Offset(ex, g.conductorY(0)), Offset(ex, g.conductorY(3) + 6), Paint()
        ..color = const Color(0xFF3E9A3E)
        ..strokeWidth = 2.5);
      c.drawPath(
          Path()
            ..moveTo(ex, g.conductorY(3) + 6)
            ..quadraticBezierTo(ex + 6, g.clampY + 60, x + 9, g.groundY - 4),
          Paint()
            ..color = const Color(0xFF3E9A3E)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5);
      c.drawRect(Rect.fromLTWH(x + 4, g.groundY - 6, 14, 6), Paint()..color = const Color(0xFF8D6E3A));
    }
  }

  void _span(Canvas c) {
    final g = geo;
    // The GI bearer wire (clamp → rack bolt).
    final bearer = Path()..moveTo(g.clamp.dx, g.clamp.dy);
    for (var i = 1; i <= 20; i++) {
      final p = g.bearerAt(i / 20);
      bearer.lineTo(p.dx, p.dy);
    }
    c.drawPath(bearer, Paint()
      ..color = const Color(0xFF9EA6AD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
    // The service cable: under the bearer, strapped (or hanging slack).
    final cable = Path();
    for (var i = 0; i <= 20; i++) {
      final u = i / 20;
      final p = g.bearerAt(u);
      final slack = view.strapped ? 4.0 : 4 + 34 * 4 * u * (1 - u);
      if (i == 0) {
        cable.moveTo(p.dx, p.dy + 4);
      } else {
        cable.lineTo(p.dx, p.dy + slack);
      }
    }
    c.drawPath(cable, Paint()
      ..color = const Color(0xFF222428)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5);
    if (view.strapped) {
      for (var i = 1; i <= 6; i++) {
        final p = g.bearerAt(i / 7);
        c.drawRect(Rect.fromCenter(center: p + const Offset(0, 2.5), width: 3.4, height: 9), Paint()..color = const Color(0xFFF5F5F0));
      }
    }
    // The anchor clamp on the pole and the rack bolt on the wall.
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: g.clamp, width: 16, height: 10), const Radius.circular(3)), Paint()..color = const Color(0xFF6D747B));
    c.drawCircle(g.rackBolt, 5, Paint()..color = const Color(0xFF6D747B));
    c.drawCircle(g.rackBolt, 2, Paint()..color = const Color(0xFF2B2F33));
  }

  void _poleEnd(Canvas c) {
    final g = geo;
    // The service fuse on the pole (carrier in or out).
    final f = g.fuse;
    c.drawRRect(RRect.fromRectAndRadius(f, const Radius.circular(3)), Paint()..color = const Color(0xFFE9E4D6));
    c.drawRRect(
        RRect.fromRectAndRadius(f, const Radius.circular(3)),
        Paint()
          ..color = const Color(0xFF6E6650)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1);
    if (view.fuseIn) {
      c.drawRect(Rect.fromLTWH(f.left + 4, f.top + 6, f.width - 8, f.height - 12), Paint()..color = const Color(0xFF2E7D32));
    } else {
      c.drawRect(Rect.fromLTWH(f.left + 6, f.top + 9, f.width - 12, f.height - 18), Paint()..color = const Color(0xFF3B3B3B));
    }
    // The two cores from the cable end up to the line (IPC) or loose.
    final from = g.clamp + const Offset(12, 4);
    for (var core = 0; core < 2; core++) {
      final ipc = view.ipcs[core];
      final col = m4ServiceConnectCoreColors[core];
      final Offset end;
      if (ipc != null) {
        end = Offset(g.ipcX(ipc.$2), g.conductorY(ipc.$1) + 8);
      } else {
        end = g.poleCores[core];
      }
      final path = Path()
        ..moveTo(from.dx, from.dy)
        ..quadraticBezierTo(end.dx - 8, from.dy + 6, end.dx, end.dy);
      c.drawPath(path, Paint()
        ..color = col
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4);
      if (ipc == null) {
        _coreTag(c, end, core, selected: view.selPole == core);
      } else {
        _ipc(c, Offset(g.ipcX(ipc.$2), g.conductorY(ipc.$1)), sheared: view.sheared.contains(core));
      }
    }
  }

  /// An IPC on a conductor: the body, the nut and (until it shears) its head.
  void _ipc(Canvas c, Offset at, {required bool sheared}) {
    final body = Rect.fromCenter(center: at + const Offset(0, 3), width: 18, height: 14);
    c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(3)), Paint()..color = const Color(0xFF3A3F46));
    c.drawRect(Rect.fromCenter(center: at + const Offset(0, 13), width: 8, height: 6), Paint()..color = const Color(0xFF8B949B));
    if (!sheared) {
      c.drawRect(Rect.fromCenter(center: at + const Offset(0, 19), width: 10, height: 6), Paint()..color = const Color(0xFFE0A21E));
    }
  }

  void _coreTag(Canvas c, Offset at, int core, {required bool selected}) {
    if (selected) {
      c.drawCircle(at + const Offset(0, 6), 15, Paint()
        ..color = const Color(0xFFFFE08A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4);
    }
    // The bare-free end cap and the marking sleeve.
    final sleeve = Rect.fromCenter(center: at + const Offset(0, 8), width: 14, height: 12);
    c.drawRRect(RRect.fromRectAndRadius(sleeve, const Radius.circular(3)), Paint()..color = core == 0 ? const Color(0xFFF4E6B8) : const Color(0xFF263238));
    _label(c, core == 0 ? 'L' : 'N', sleeve.center, 8.5, core == 0 ? const Color(0xFF8A1C14) : Colors.white);
  }

  void _house(Canvas c, Size size) {
    final g = geo;
    final h = g.house;
    // Roof (a flat slab with a parapet) and the plastered wall.
    c.drawRect(h, Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFEFE2C6), Color(0xFFD6C29C)]).createShader(h));
    c.drawRect(Rect.fromLTRB(h.left - 4, h.top - 10, h.right, h.top), Paint()..color = const Color(0xFFBFAE8A));
    c.drawRect(Rect.fromLTRB(h.left, h.top, h.left + 5, h.bottom), Paint()..color = const Color(0x22000000));
    // The door.
    final door = Rect.fromLTWH(h.left + 16, g.groundY - 74, 26, 74);
    c.drawRect(door, Paint()..color = const Color(0xFF6B4A2E));
    c.drawCircle(Offset(door.right - 5, door.center.dy), 2, Paint()..color = const Color(0xFFE0C070));
    // The window: dark, or lit once the supply is on.
    final win = g.window;
    if (view.lit) {
      final glow = 0.75 + 0.25 * math.sin(t.value * 3).abs();
      c.drawRect(win.inflate(10), Paint()..shader = RadialGradient(colors: [Color.fromRGBO(255, 224, 140, 0.55 * glow), const Color(0x00FFE08C)]).createShader(win.inflate(14)));
      c.drawRect(win, Paint()..color = const Color(0xFFFFE6A0));
    } else {
      c.drawRect(win, Paint()..color = const Color(0xFF3D4A5C));
    }
    c.drawLine(win.topCenter, win.bottomCenter, Paint()
      ..color = const Color(0xFF6B4A2E)
      ..strokeWidth = 2);
    c.drawRect(
        win,
        Paint()
          ..color = const Color(0xFF6B4A2E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
  }

  void _houseEnd(Canvas c) {
    final g = geo;
    final rb = g.rackBolt;
    // Down the wall from the rack bolt: a drip loop (once made) or straight into the board.
    final down = Path()..moveTo(rb.dx, rb.dy + 4);
    final entry = Offset(g.meterBox.left - 2, g.meterBox.top + 18);
    if (view.drip) {
      down
        ..lineTo(rb.dx, rb.dy + 22)
        ..cubicTo(rb.dx - 2, rb.dy + 52, rb.dx + 18, rb.dy + 52, rb.dx + 16, rb.dy + 30)
        ..quadraticBezierTo(rb.dx + 16, entry.dy - 2, entry.dx, entry.dy);
    } else {
      down
        ..lineTo(rb.dx, entry.dy - 10)
        ..quadraticBezierTo(rb.dx, entry.dy, entry.dx, entry.dy);
    }
    c.drawPath(down, Paint()
      ..color = const Color(0xFF222428)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5);
    if (view.drip) {
      // A water drop falling off the bottom of the loop.
      c.drawCircle(Offset(rb.dx + 7, rb.dy + 54), 2.2, Paint()..color = const Color(0xFF7FB8E6));
    }

    // The meter board and the meter.
    final mb = g.meterBox;
    c.drawRRect(RRect.fromRectAndRadius(mb.inflate(6), const Radius.circular(4)), Paint()..color = const Color(0xFF7A5634));
    c.drawRRect(RRect.fromRectAndRadius(mb, const Radius.circular(6)), Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFF5F5F2), Color(0xFFD5D8DA)]).createShader(mb));
    final screen = Rect.fromLTWH(mb.left + 10, mb.top + 10, mb.width - 20, 16);
    c.drawRRect(RRect.fromRectAndRadius(screen, const Radius.circular(2)), Paint()..color = view.lit ? const Color(0xFF9FD8A4) : const Color(0xFF5E6B60));
    _label(c, 'kWh', Offset(mb.center.dx, mb.top + 36), 8, const Color(0xFF3A4047));
    // The terminal cover strip with the two incoming terminals and their marks.
    final strip = Rect.fromLTWH(mb.left + 6, mb.bottom - 24, mb.width - 12, 20);
    c.drawRRect(RRect.fromRectAndRadius(strip, const Radius.circular(3)), Paint()..color = const Color(0xFF2B2F33));
    for (var i = 0; i < 2; i++) {
      final at = g.terminals[i];
      c.drawCircle(at, 6, Paint()..shader = const RadialGradient(colors: [Color(0xFFF1F3F5), Color(0xFF8B949B)]).createShader(Rect.fromCircle(center: at, radius: 6)));
      final isL = (i == 0) == view.meterLeftIsL;
      _label(c, isL ? 'L' : 'N', at + const Offset(0, -15), 8.5, const Color(0xFF22282D));
    }
    _label(c, 'IN', Offset(mb.center.dx, mb.bottom - 31), 7, const Color(0xFF5A6066));

    // The two cores out of the cable: into their terminal, or hanging with their sleeve.
    for (var core = 0; core < 2; core++) {
      final col = m4ServiceConnectCoreColors[core];
      final from = Offset(mb.left - 2, mb.top + 18);
      final Offset end;
      if (view.houseIn.contains(core)) {
        final isL = core == 0;
        final term = (isL == view.meterLeftIsL) ? 0 : 1;
        end = g.terminals[term] + const Offset(0, 5);
      } else {
        end = g.houseCores[core];
      }
      final path = Path()
        ..moveTo(from.dx, from.dy)
        ..cubicTo(from.dx - 4, end.dy + 18, end.dx - 10, end.dy + 20, end.dx, end.dy);
      c.drawPath(path, Paint()
        ..color = col
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4);
      if (!view.houseIn.contains(core)) _coreTag(c, end, core, selected: view.selHouse == core);
    }
  }

  void _scraps(Canvas c) {
    final g = geo;
    for (final x in view.scraps) {
      final y = g.groundY - 5;
      c.drawPath(
          Path()
            ..moveTo(x - 14, y + 2)
            ..quadraticBezierTo(x - 2, y - 8, x + 12, y),
          Paint()
            ..color = const Color(0xFF222428)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round);
      c.drawCircle(Offset(x + 12, y), 2, Paint()..color = const Color(0xFFB87333));
      c.drawRect(Rect.fromLTWH(x - 6, y + 1, 9, 5), Paint()..color = const Color(0xFFEDEDED));
    }
  }

  void _label(Canvas c, String s, Offset centre, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontFamily: 'Roboto', fontSize: size, fontWeight: FontWeight.w900, color: color)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(M4ServiceConnectPainter old) => old.geo != geo || old.view != view || old.seed != seed;
}

/// The flash where a tool (or the earth set) touched the live LT line (the
/// deadly moment, in colour over the frozen scene).
class M4ServiceConnectArcPainter extends CustomPainter {
  const M4ServiceConnectArcPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final flick = v < 0.5 ? (0.65 + 0.35 * math.sin(v * 60).abs()) : (1 - (v - 0.5) * 1.2).clamp(0.4, 1.0);
    final r = 26 + 70 * Curves.easeOut.transform(v.clamp(0.0, 1.0));
    c.drawCircle(at, r, Paint()..shader = RadialGradient(colors: [Color.fromRGBO(255, 250, 220, 0.95 * flick), Color.fromRGBO(140, 170, 255, 0.5 * flick), const Color(0x00FFC24A)]).createShader(Rect.fromCircle(center: at, radius: r)));
    final spark = Paint()
      ..color = Color.fromRGBO(255, 214, 90, (1 - v).clamp(0.0, 1.0))
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 16; i++) {
      final a = i / 16 * math.pi * 2 + 0.2;
      final d0 = 10 + 50 * v;
      c.drawLine(at + Offset(math.cos(a), math.sin(a)) * d0, at + Offset(math.cos(a), math.sin(a)) * (d0 + 14), spark);
    }
    final white = (1 - v * 4).clamp(0.0, 1.0);
    if (white > 0) c.drawRect(Offset.zero & size, Paint()..color = Color.fromRGBO(255, 255, 255, 0.8 * white));
  }

  @override
  bool shouldRepaint(M4ServiceConnectArcPainter old) => old.v != v || old.at != at;
}
