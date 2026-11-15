import 'dart:math' as math;

import 'package:flutter/material.dart';

// The drawn world of lesson 6.2 কাজ 2 "তিন অবস্থান" (m6_breaker_rack.dart):
// a substation breaker room in the daytime, one feeder panel close up. The
// panel's top (control) door carries a row of lamps (ON red, OFF green, TRIP
// amber, TC HEALTHY white, HEATER blue), the operation counter, the spring
// flag (CHARGED / DISCHARGED), the ON and OFF push buttons and the manual
// spring-charge socket; its lower (breaker) door the racking crank, the
// position window (SERVICE · TEST · ISOLATED rolling past one pointer) and a
// viewing glass on the breaker truck. Through the glass the truck is seen
// from the side: at the back the three spouts (the fixed contacts), the truck
// on its rails rolling forward as it is racked out, and its control plug —
// in its socket at SERVICE and TEST, hanging free beyond TEST (lesson 6.2
// point 4: ISOLATED = power and control both out). The panel lamps are fed by
// that control plug, so they go dark once it is out (the HEATER lamp is on
// the panel's own supply). The neighbour panels stand at both sides; the
// docket is clipped to the right-hand one (a widget, not painted here).
//
// No text in the art except labels a worker reads (the nameplate, lamp and
// button names, the window, the flag). Code-drawn, gradients, no bitmaps.
//
// Design: 360 wide × the scene's height; the floor follows the bottom of the
// screen (a tall phone gets a taller panel, never stretched sideways).

/// The breaker on the truck (lesson 6.2 point 2).
enum M6RackFace { vcb, ocb }

/// The truck's three positions (lesson 6.2 point 4).
enum M6RackPos { service, test, isolated }

/// The truck's travel in position steps: 0 = SERVICE, 1 = TEST, 2 = ISOLATED.
const double kM6RackMax = 2;

/// How far from a position the truck still sits in it (in steps).
const double kM6RackSeat = 0.14;

/// The position the truck sits in at [t], or null between positions.
M6RackPos? m6RackPosAt(double t) {
  final k = t.round().clamp(0, 2);
  return (t - k).abs() <= kM6RackSeat ? M6RackPos.values[k] : null;
}

/// The control plug is in its socket (SERVICE, TEST and the way between).
bool m6RackControlOn(double t) => t <= 1 + kM6RackSeat;

/// Where things are (design px, 360 wide).
@immutable
class M6RackGeo {
  const M6RackGeo._(this.height, this.floorY);

  factory M6RackGeo.forScene(double height, double inset) => M6RackGeo._(height, height - floorUp - inset * 0.5);

  final double height;

  /// The floor line at the panel's foot.
  final double floorY;

  /// The floor sits this far above the bottom (the action row stands on it).
  static const double floorUp = 96;

  /// The top of the panel's working face (under the header).
  static const double top = 132;

  /// The face's working height.
  double get a => floorY - top - 8;

  /// A height on the face (0 = the top, 1 = the foot).
  double y(double f) => top + f * a;

  /// The panel (its nameplate sits just above [top]).
  Rect get panel => Rect.fromLTRB(58, 112, 250, floorY);

  /// The control door / breaker door seam.
  double get seamY => y(0.36);

  /// The five lamps: ON, OFF, TRIP, TC HEALTHY, HEATER.
  Offset lamp(int i) => Offset(80 + 36.0 * i, y(0.04));

  Rect get counter => Rect.fromLTWH(72, y(0.12), 70, 22);
  Rect get flag => Rect.fromLTWH(152, y(0.12), 86, 22);

  Offset get onBtn => Offset(92, y(0.24));
  Offset get offBtn => Offset(138, y(0.24));
  Rect get onHit => Rect.fromCenter(center: onBtn, width: 42, height: 42);
  Rect get offHit => Rect.fromCenter(center: offBtn, width: 42, height: 42);

  /// The manual spring-charge socket, and where the fitted handle is stroked.
  Offset get socket => Offset(212, y(0.24));
  Rect get socketHit => Rect.fromCenter(center: socket, width: 48, height: 48);
  Rect get strokeHit => Rect.fromLTRB(socket.dx - 26, socket.dy - 30, socket.dx + 44, socket.dy + 24);

  /// The fitted handle's grip (a pump lever out to the right, clear of the
  /// flag; a stroke starts here).
  Offset get grip => socket.translate(34, -4);

  /// The position window.
  Rect get window => Rect.fromLTWH(72, y(0.44), 86, (0.12 * a).clamp(34.0, 60.0));

  /// The racking crank: its socket, the arm's reach and the touch circle.
  Offset get crank => Offset(206, y(0.50));
  double get crankR => (0.07 * a).clamp(26.0, 40.0);
  double get crankTouch => crankR + 18;
  bool inCrank(Offset p) {
    final d = (p - crank).distance;
    return d <= crankTouch && d >= 4;
  }

  Rect get crankHit => Rect.fromCircle(center: crank, radius: crankTouch);

  /// The grip at the end of the arm at truck travel [t] (one turn a step;
  /// clockwise racks in, as on a withdrawable VCB/OCB truck).
  Offset crankGrip(double t) {
    final th = -math.pi / 2 - t * 2 * math.pi;
    return crank + Offset(math.cos(th), math.sin(th)) * crankR;
  }

  /// The viewing glass on the breaker door.
  Rect get glass => Rect.fromLTRB(72, y(0.64), 238, y(0.95));

  /// The docket on the neighbour panel (a widget).
  static const Rect docket = Rect.fromLTWH(266, 138, 86, 104);

  /// Where the trainee stands (left of the panel).
  Rect get trainee => Rect.fromLTWH(6, floorY - 104, 44, 104);

  /// Where a deadly flash comes off (the breaker contacts behind the glass).
  Offset get flashAt => Offset(glass.left + 24, glass.center.dy);

  @override
  bool operator ==(Object other) => other is M6RackGeo && other.height == height && other.floorY == floorY;

  @override
  int get hashCode => Object.hash(height, floorY);
}

/// What the panel shows now (everything but the truck's travel).
@immutable
class M6RackRig {
  const M6RackRig({
    required this.face,
    required this.feeder,
    required this.counter,
    this.controlOn = true,
    this.breakerOn = false,
    this.healthy = true,
    this.springCharged = true,
    this.handleFitted = false,
    this.strokes = 0,
  });

  final M6RackFace face;
  final int feeder;
  final int counter;

  /// The control plug is in (the lamps can light).
  final bool controlOn;
  final bool breakerOn;

  /// The trip circuit is healthy (its lamp lights while the control is in).
  final bool healthy;
  final bool springCharged;

  /// The manual handle in its socket, and the strokes given so far.
  final bool handleFitted;
  final int strokes;

  @override
  bool operator ==(Object other) =>
      other is M6RackRig &&
      other.face == face &&
      other.feeder == feeder &&
      other.counter == counter &&
      other.controlOn == controlOn &&
      other.breakerOn == breakerOn &&
      other.healthy == healthy &&
      other.springCharged == springCharged &&
      other.handleFitted == handleFitted &&
      other.strokes == strokes;

  @override
  int get hashCode => Object.hash(face, feeder, counter, controlOn, breakerOn, healthy, springCharged, handleFitted, strokes);
}

/// Which lamps are lit: ON, OFF, TRIP, TC HEALTHY, HEATER.
List<bool> m6RackLamps(M6RackRig r) => [
      r.controlOn && r.breakerOn,
      r.controlOn && !r.breakerOn,
      false,
      r.controlOn && r.healthy,
      true,
    ];

const _lampNames = ['ON', 'OFF', 'TRIP', 'TC HEALTHY', 'HEATER'];
const _lampLit = [Color(0xFFFF3B30), Color(0xFF34C759), Color(0xFFFFB020), Color(0xFFFFFBEA), Color(0xFF4FA3FF)];
const _lampDark = [Color(0xFF5A2320), Color(0xFF1F4429), Color(0xFF5A4518), Color(0xFF5C5A52), Color(0xFF203A58)];

void _label(Canvas c, String text, Offset centre, {double size = 6.5, Color color = const Color(0xFF26303D), FontWeight weight = FontWeight.w800}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: weight, color: color, letterSpacing: 0.3, height: 1.05)),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  )..layout(maxWidth: 120);
  tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
}

/// The room, the panels and the panel's still parts (the lamps, counter,
/// flag, buttons and socket). The truck, window and crank arm are on
/// [M6RackTrolleyPainter], which repaints while the crank turns.
class M6RackPanelPainter extends CustomPainter {
  const M6RackPanelPainter({required this.geo, required this.rig});

  final M6RackGeo geo;
  final M6RackRig rig;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    // The wall.
    final wall = Rect.fromLTWH(0, 0, w, g.floorY);
    c.drawRect(
        wall,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF8FA39A), Color(0xFFB9C6BC), Color(0xFFA7B5AA)],
          ).createShader(wall));
    // A high window strip and a cable tray along the top.
    c.drawRect(Rect.fromLTWH(0, 70, w, 10), Paint()..color = const Color(0xFF6E7C76));
    for (var x = 8.0; x < w; x += 22) {
      c.drawLine(Offset(x, 70), Offset(x, 80), Paint()
        ..color = const Color(0xFF55615C)
        ..strokeWidth = 1.2);
    }
    // The floor and the rubber mat in front of the panels.
    final floor = Rect.fromLTRB(0, g.floorY, w, size.height);
    c.drawRect(floor, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF6B6F72), Color(0xFF45494C)]).createShader(floor));
    c.drawRect(Rect.fromLTRB(0, g.floorY, w, g.floorY + 14), Paint()..color = const Color(0xFF23272B));
    for (var x = 4.0; x < w; x += 9) {
      c.drawLine(Offset(x, g.floorY + 2), Offset(x + 4, g.floorY + 12), Paint()
        ..color = const Color(0xFF31363B)
        ..strokeWidth = 1);
    }
    // The neighbour panels (the right one carries the docket).
    _neighbour(c, Rect.fromLTRB(-40, 112, 52, g.floorY));
    _neighbour(c, Rect.fromLTRB(256, 112, w + 40, g.floorY));
    _panel(c);
  }

  void _neighbour(Canvas c, Rect r) {
    c.drawRect(r, Paint()..shader = const LinearGradient(colors: [Color(0xFF9EA6AE), Color(0xFF858D95)]).createShader(r));
    c.drawRect(r, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = const Color(0xFF5E666E));
    final seam = r.top + (r.height * 0.36);
    c.drawLine(Offset(r.left, seam), Offset(r.right, seam), Paint()
      ..color = const Color(0xFF5E666E)
      ..strokeWidth = 1.5);
    for (var i = 0; i < 3; i++) {
      final x = r.left + 18 + i * 22.0;
      if (x > r.right - 8 || x < r.left + 6) continue;
      c.drawCircle(Offset(x, r.top + 40), 6, Paint()..color = const Color(0xFF3E464E));
    }
  }

  void _panel(Canvas c) {
    final g = geo;
    final p = g.panel;
    final vcb = rig.face == M6RackFace.vcb;
    final body = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: vcb ? const [Color(0xFFD9DEE3), Color(0xFFC3CAD1), Color(0xFFB2BAC2)] : const [Color(0xFFCFD2B8), Color(0xFFB9BE9F), Color(0xFFA5AA8C)],
      ).createShader(p);
    c.drawRRect(RRect.fromRectAndRadius(p, const Radius.circular(4)), Paint()..color = const Color(0x55000000));
    c.drawRRect(RRect.fromRectAndRadius(p.deflate(1), const Radius.circular(4)), body);
    c.drawRRect(
        RRect.fromRectAndRadius(p.deflate(1), const Radius.circular(4)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = const Color(0xFF66707A));
    // Nameplate.
    final plate = Rect.fromLTWH(p.left + 30, p.top + 4, p.width - 60, 15);
    c.drawRRect(RRect.fromRectAndRadius(plate, const Radius.circular(2)), Paint()..color = const Color(0xFF1C2E4A));
    _label(c, 'FEEDER ${rig.feeder}  ·  ${vcb ? 'VCB' : 'OCB'}', plate.center, size: 8, color: const Color(0xFFF2EBD8));
    // Door seams and hinges.
    final seam = Paint()
      ..color = const Color(0xFF7A848E)
      ..strokeWidth = 1.6;
    c.drawLine(Offset(p.left + 4, g.seamY), Offset(p.right - 4, g.seamY), seam);
    for (final hy in [g.y(0.08), g.y(0.28), g.y(0.5), g.y(0.86)]) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(p.right - 7, hy, 5, 14), const Radius.circular(2)), Paint()..color = const Color(0xFF59626B));
    }
    // Lamps.
    final lit = m6RackLamps(rig);
    for (var i = 0; i < 5; i++) {
      final o = g.lamp(i);
      c.drawCircle(o, 11.5, Paint()..color = const Color(0xFF3A4048));
      if (lit[i]) c.drawCircle(o, 15, Paint()..color = _lampLit[i].withValues(alpha: 0.35));
      c.drawCircle(
          o,
          9,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-0.3, -0.3),
              colors: lit[i] ? [Colors.white, _lampLit[i]] : [_lampDark[i].withValues(alpha: 0.85), _lampDark[i]],
            ).createShader(Rect.fromCircle(center: o, radius: 9)));
      final name = _lampNames[i];
      _label(c, name == 'TC HEALTHY' ? 'TC\nHEALTHY' : name, o.translate(0, name == 'TC HEALTHY' ? 19 : 16), size: 5.6);
    }
    // Counter.
    final cr = g.counter;
    _label(c, 'COUNTER', cr.topCenter.translate(0, -5), size: 5.4);
    c.drawRRect(RRect.fromRectAndRadius(cr, const Radius.circular(3)), Paint()..color = const Color(0xFF15191E));
    final digits = rig.counter.toString().padLeft(5, '0');
    for (var i = 0; i < 5; i++) {
      final cell = Rect.fromLTWH(cr.left + 4 + i * 12.6, cr.top + 3, 11, cr.height - 6);
      c.drawRect(cell, Paint()..color = const Color(0xFF2B3138));
      _label(c, digits[i], cell.center, size: 10, color: const Color(0xFFF4F4F4), weight: FontWeight.w700);
    }
    // Spring flag: the same plate whatever it says (it must be read).
    final fr = g.flag;
    _label(c, 'SPRING', fr.topCenter.translate(0, -5), size: 5.4);
    c.drawRRect(RRect.fromRectAndRadius(fr, const Radius.circular(3)), Paint()..color = const Color(0xFF3A4048));
    final face = fr.deflate(3);
    c.drawRect(face, Paint()..color = const Color(0xFFEFE8D2));
    _label(c, rig.springCharged ? 'CHARGED' : 'DISCHARGED', face.center, size: 8.4, color: const Color(0xFF26303D), weight: FontWeight.w900);
    // Push buttons.
    for (final (o, col, name) in [(g.onBtn, const Color(0xFFD7332A), 'ON'), (g.offBtn, const Color(0xFF2E9E4F), 'OFF')]) {
      c.drawCircle(o, 17, Paint()..color = const Color(0xFF2E343B));
      c.drawCircle(
          o,
          13,
          Paint()
            ..shader = RadialGradient(center: const Alignment(-0.35, -0.35), colors: [Color.lerp(col, Colors.white, 0.35)!, col]).createShader(Rect.fromCircle(center: o, radius: 13)));
      _label(c, name, o.translate(0, 24), size: 6.4);
    }
    // The manual spring-charge socket (always drawn), the handle when fitted.
    final s = g.socket;
    final hex = Path();
    for (var i = 0; i < 6; i++) {
      final a = math.pi / 6 + i * math.pi / 3;
      final pt = s + Offset(math.cos(a), math.sin(a)) * 12;
      i == 0 ? hex.moveTo(pt.dx, pt.dy) : hex.lineTo(pt.dx, pt.dy);
    }
    hex.close();
    c.drawPath(hex, Paint()..color = const Color(0xFF4A525B));
    c.drawCircle(s, 5, Paint()..color = const Color(0xFF15191E));
    _label(c, 'MANUAL\nCHARGE', s.translate(0, 22), size: 5.2);
    if (rig.handleFitted) {
      final lean = rig.strokes.isEven ? -0.12 : 0.18;
      final tip = s + Offset(math.cos(lean), math.sin(lean)) * 34;
      c.drawLine(s, tip, Paint()
        ..color = const Color(0xFF2B3138)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: tip, width: 16, height: 11), const Radius.circular(5)), Paint()..color = const Color(0xFFD0352B));
    }
    // The breaker door's labels.
    _label(c, 'POSITION', g.window.topCenter.translate(0, -6), size: 5.6);
    _label(c, 'RACKING', g.crank.translate(0, g.crankR + 12), size: 5.6);
  }

  @override
  bool shouldRepaint(M6RackPanelPainter old) => old.geo != geo || old.rig != rig;
}

/// The moving parts: the position window, the crank arm and the truck seen
/// through the glass. [t] = the truck's travel (0 SERVICE … 2 ISOLATED).
class M6RackTrolleyPainter extends CustomPainter {
  const M6RackTrolleyPainter({required this.geo, required this.t, required this.face});

  final M6RackGeo geo;
  final double t;
  final M6RackFace face;

  static const _names = ['SERVICE', 'TEST', 'ISOLATED'];

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    // The position window: one strip rolls past a fixed pointer; every
    // label alike (no colour, no notch per position).
    final win = g.window;
    c.drawRRect(RRect.fromRectAndRadius(win.inflate(3), const Radius.circular(4)), Paint()..color = const Color(0xFF3A4048));
    c.drawRect(win, Paint()..color = const Color(0xFF101418));
    c.save();
    c.clipRect(win);
    final step = win.height * 0.92;
    for (var i = 0; i < 3; i++) {
      final cy = win.center.dy + (i - t) * step;
      _label(c, _names[i], Offset(win.center.dx, cy), size: 10.5, color: const Color(0xFFF1F1F1), weight: FontWeight.w900);
    }
    c.restore();
    final pointer = Paint()..color = const Color(0xFFFFC94A);
    for (final x in [win.left - 3, win.right + 3]) {
      final dir = x < win.center.dx ? 1.0 : -1.0;
      c.drawPath(
          Path()
            ..moveTo(x, win.center.dy - 5)
            ..lineTo(x + dir * 6, win.center.dy)
            ..lineTo(x, win.center.dy + 5)
            ..close(),
          pointer);
    }
    // The crank: the round track, the socket, the arm (one turn a step).
    final o = g.crank;
    c.drawCircle(o, g.crankR + 6, Paint()..color = const Color(0x22000000));
    c.drawCircle(
        o,
        g.crankR,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..color = const Color(0x6626303D));
    c.drawCircle(o, 11, Paint()..color = const Color(0xFF3A4048));
    c.drawCircle(o, 5, Paint()..color = const Color(0xFF15191E));
    final grip = g.crankGrip(t);
    c.drawLine(o, grip, Paint()
      ..color = const Color(0xFF59626B)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round);
    c.drawCircle(grip, 9.5, Paint()..shader = const RadialGradient(colors: [Color(0xFFE2504A), Color(0xFF9E2620)]).createShader(Rect.fromCircle(center: grip, radius: 9.5)));
    _glass(c);
  }

  void _glass(Canvas c) {
    final g = geo;
    final gl = g.glass;
    c.drawRRect(RRect.fromRectAndRadius(gl.inflate(4), const Radius.circular(6)), Paint()..color = const Color(0xFF59626B));
    c.drawRRect(
        RRect.fromRectAndRadius(gl, const Radius.circular(4)),
        Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1B232C), Color(0xFF2C3640)]).createShader(gl));
    c.save();
    c.clipRRect(RRect.fromRectAndRadius(gl, const Radius.circular(4)));
    // Back wall: the three spouts (fixed contacts) and the shutter rails.
    final back = gl.left + 14;
    final ys = [for (final f in [0.26, 0.48, 0.70]) gl.top + gl.height * f];
    for (final yy in ys) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(gl.left + 2, yy - 6, 14, 12), const Radius.circular(3)), Paint()..color = const Color(0xFFB79A62));
      c.drawRect(Rect.fromLTWH(back, yy - 2.5, 6, 5), Paint()..color = const Color(0xFFD9A441));
    }
    // Rails.
    final railY = gl.bottom - 8;
    c.drawLine(Offset(gl.left, railY), Offset(gl.right, railY), Paint()
      ..color = const Color(0xFF8A939C)
      ..strokeWidth = 2);
    // The truck.
    const truckW = 62.0;
    final travel = (gl.width - 30 - truckW - 6) / kM6RackMax;
    final x0 = back + 16 + t * travel;
    final top = gl.top + gl.height * 0.14;
    final body = Rect.fromLTRB(x0, top, x0 + truckW, railY - 6);
    // Its cluster contacts (arms) reaching back to the spouts.
    for (final yy in ys) {
      c.drawLine(Offset(x0 - 10, yy), Offset(x0, yy), Paint()
        ..color = const Color(0xFFD9A441)
        ..strokeWidth = 4);
    }
    if (face == M6RackFace.vcb) {
      c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(3)), Paint()..color = const Color(0xFF4F5963));
      // Three vacuum bottles.
      for (var i = 0; i < 3; i++) {
        final b = Rect.fromLTWH(body.left + 8 + i * 17.0, body.top + 6, 12, body.height * 0.62);
        c.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(5)),
            Paint()..shader = const LinearGradient(colors: [Color(0xFFEDE3C8), Color(0xFFC9B98F)]).createShader(b));
      }
    } else {
      // The oil tank with its level glass.
      c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(5)),
          Paint()..shader = const LinearGradient(colors: [Color(0xFF4E6A4A), Color(0xFF34492F)]).createShader(body));
      c.drawRect(Rect.fromLTWH(body.right - 12, body.top + 10, 5, body.height * 0.5), Paint()..color = const Color(0xFFC79A3A));
    }
    // Wheels.
    for (final wx in [body.left + 10, body.right - 10]) {
      c.drawCircle(Offset(wx, railY - 3), 4.5, Paint()..color = const Color(0xFF15191E));
    }
    // The control plug: in its socket at SERVICE / TEST, hanging free beyond.
    final sock = Offset(gl.left + 22, gl.top + 7);
    c.drawRect(Rect.fromCenter(center: sock, width: 12, height: 8), Paint()..color = const Color(0xFF8A939C));
    final from = Offset(body.left + 12, body.top);
    final cable = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..color = const Color(0xFF15191E);
    if (m6RackControlOn(t)) {
      c.drawPath(
          Path()
            ..moveTo(from.dx, from.dy)
            ..quadraticBezierTo((from.dx + sock.dx) / 2, sock.dy + 10, sock.dx + 4, sock.dy),
          cable);
    } else {
      final end = from.translate(-14, 10);
      c.drawPath(
          Path()
            ..moveTo(from.dx, from.dy)
            ..quadraticBezierTo(from.dx - 4, from.dy - 10, end.dx, end.dy),
          cable);
      c.drawRect(Rect.fromCenter(center: end, width: 10, height: 7), Paint()..color = const Color(0xFF8A939C));
    }
    c.restore();
    // A glint on the glass.
    c.drawLine(gl.topLeft.translate(10, 30), gl.topLeft.translate(40, 4), Paint()
      ..color = const Color(0x22FFFFFF)
      ..strokeWidth = 6);
  }

  @override
  bool shouldRepaint(M6RackTrolleyPainter old) => old.t != t || old.geo != geo || old.face != face;
}

/// The arc flash off the contacts (a deadly mistake), in colour over the
/// grey scene.
class M6RackFlashPainter extends CustomPainter {
  const M6RackFlashPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final flick = v < 0.5 ? (0.65 + 0.35 * math.sin(v * 60).abs()) : (1 - (v - 0.5) * 1.2).clamp(0.4, 1.0);
    final r = 30 + 80 * Curves.easeOut.transform(v.clamp(0.0, 1.0));
    c.drawCircle(
        at,
        r,
        Paint()
          ..shader = RadialGradient(colors: [Color.fromRGBO(255, 250, 225, 0.95 * flick), Color.fromRGBO(130, 165, 255, 0.5 * flick), const Color(0x00FFC24A)])
              .createShader(Rect.fromCircle(center: at, radius: r)));
    final spark = Paint()
      ..color = Color.fromRGBO(255, 214, 90, (1 - v).clamp(0.0, 1.0))
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 16; i++) {
      final a = i / 16 * math.pi * 2 + 0.2;
      final d0 = 10 + 56 * v;
      c.drawLine(at + Offset(math.cos(a), math.sin(a)) * d0, at + Offset(math.cos(a), math.sin(a)) * (d0 + 14), spark);
    }
    final white = (1 - v * 4).clamp(0.0, 1.0);
    if (white > 0) c.drawRect(Offset.zero & size, Paint()..color = Color.fromRGBO(255, 255, 255, 0.8 * white));
  }

  @override
  bool shouldRepaint(M6RackFlashPainter old) => old.v != v || old.at != at;
}
