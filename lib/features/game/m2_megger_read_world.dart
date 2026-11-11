import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The pump house where the cable is tested (lesson 2.7 কাজ 2 "পড়ুন আর ছাড়ুন"):
// a drawn, layered place — the whitewashed wall and its starter panel (the
// isolator OFF, padlocked and tagged: the cable is disconnected), the floor
// and its cable trench, the LT pump cable standing out of the trench (steel
// wire armour, the brass gland, the earth clamp on the armour, three cores —
// red, yellow, blue — with their bare lugs lifted off), the insulation tester
// on a rubber mat (its L and E terminals, the analog MΩ scale with a needle,
// a small display, the test-voltage selector, the TEST button), its two
// leads and crocodile clips, and the earthed discharge rod against the wall.
// No hint text in the art: only what is printed on a real tester.
//
// Design: 360 wide × the scene's height; the floor follows the bottom of the
// screen (a tall phone gets more wall above).

/// Where things stand (design px, 360 wide).
@immutable
class MeggerGeo {
  const MeggerGeo({required this.height, required this.floorY});

  factory MeggerGeo.forScene(double h, double inset) => MeggerGeo(height: h, floorY: h - 216 - inset);

  final double height;
  final double floorY;

  /// The cable's axis.
  static const cx = 118.0;

  /// Vertical scale for the cable (a short phone squeezes the cores, never the tester).
  double get s => ((floorY - 150) / 444).clamp(0.55, 1.0);
  double up(double d) => floorY - d * s;

  double get glandY => up(84);

  /// Where the E clip bites on the armour (under the gland).
  Offset get armourAt => Offset(cx, up(46));

  /// The three cores' lug ends: R, Y, B.
  List<Offset> get coreEnds => [Offset(cx - 44, up(212)), Offset(cx, up(240)), Offset(cx + 44, up(212))];

  /// The tester (on its mat).
  Rect get meter => Rect.fromLTRB(178, floorY - 170, 354, floorY - 4);
  Offset get lTerminal => Offset(meter.left + 22, meter.top + 12);
  Offset get eTerminal => Offset(meter.left + 52, meter.top + 12);
  Rect get gauge => Rect.fromLTRB(meter.left + 10, meter.top + 26, meter.right - 10, meter.top + 92);
  Offset get pivot => Offset(gauge.center.dx, gauge.bottom - 6);
  double get needleLen => gauge.height - 16;
  Offset get knob => Offset(meter.left + 26, meter.bottom - 36);
  Rect get selector => Rect.fromLTRB(meter.left + 4, meter.top + 98, meter.left + 72, meter.bottom - 4);
  Rect get display => Rect.fromLTRB(meter.left + 74, meter.top + 102, meter.left + 126, meter.bottom - 18);
  Offset get testButton => Offset(meter.right - 26, meter.bottom - 34);
  static const testRadius = 23.0;

  /// The clips' places when they are not on the cable (resting on the tester's lid).
  Offset get lPark => Offset(meter.left + 92, meter.top - 12);
  Offset get ePark => Offset(meter.left + 124, meter.top - 12);

  /// The discharge rod lying on the floor in front of the mat: its foot and its hook.
  Offset get rodFoot => Offset(204, floorY + 44);
  Offset get rodRestTip => Offset(352, floorY + 36);

  /// The earth point the rod's lead and the armour's earth wire go to.
  Offset get earthPoint => Offset(cx + 30, floorY + 4);

  /// The rod in his hands, aimed at the cores.
  Offset get rodHeldGrip => Offset(58, floorY - 78);
  Offset get rodHeldTip => Offset(cx - 10, up(300));

  /// The panel on the wall (upper left).
  Rect get panel => Rect.fromLTWH(14, up(420), 78, up(290) - up(420));

  /// The trainee (left of the cable, facing it).
  Rect get trainee {
    const h = 150.0;
    return Rect.fromLTWH(-6, floorY - h + 2, h / 2, h);
  }

  @override
  bool operator ==(Object other) => other is MeggerGeo && other.height == height && other.floorY == floorY;

  @override
  int get hashCode => Object.hash(height, floorY);
}

/// The scale's place for an IR reading (MΩ): log scale, 0 at the left, ∞ at
/// the right; 0.1 · 1 · 10 · 100 · 1G at even steps.
double meggerScale(double mohm) {
  if (mohm.isInfinite) return 1;
  if (mohm <= 0.01) return 0;
  return ((math.log(mohm) / math.ln10 + 2) / 6).clamp(0.0, 0.97);
}

/// The scale's ticks and their printed labels.
const meggerTicks = <(double, String)>[(0, '0'), (1 / 6, '0.1'), (2 / 6, '1'), (3 / 6, '10'), (4 / 6, '100'), (5 / 6, '1G'), (1, '∞')];

/// The test voltages on the selector (lesson 2.7: 500, 1000, 2500, 5000 V).
const meggerVolts = [500, 1000, 2500, 5000];

const _font = 'Noto Sans Bengali';

void _text(Canvas c, String t, Offset centre, {double size = 10, Color color = const Color(0xFF1B1F24), FontWeight weight = FontWeight.w700, TextAlign align = TextAlign.center}) {
  final tp = TextPainter(
    text: TextSpan(text: t, style: TextStyle(fontFamily: _font, fontFamilyFallback: const ['Roboto'], fontSize: size, fontWeight: weight, color: color, height: 1)),
    textDirection: TextDirection.ltr,
    textAlign: align,
  )..layout();
  final dx = switch (align) {
    TextAlign.left => 0.0,
    TextAlign.right => -tp.width,
    _ => -tp.width / 2,
  };
  tp.paint(c, centre + Offset(dx, -tp.height / 2));
}

/// The still room: wall, panel, floor, trench, the cable and the tester's body.
class MeggerRoomPainter extends CustomPainter {
  const MeggerRoomPainter({required this.geo});
  final MeggerGeo geo;

  static const coreColours = [Color(0xFFC8352B), Color(0xFFE8B923), Color(0xFF2D63B8)];

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    // The wall: whitewash going grey at the top, a damp line, a skirting.
    c.drawRect(
        Rect.fromLTRB(0, 0, w, g.floorY),
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8E97A0), Color(0xFFD9D4C6), Color(0xFFE6E0D0)], stops: [0, 0.45, 1])
              .createShader(Rect.fromLTRB(0, 0, w, g.floorY)));
    final crack = Paint()
      ..color = const Color(0x33384048)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    c.drawPath(Path()..moveTo(220, g.up(470))..lineTo(232, g.up(430))..lineTo(226, g.up(400))..lineTo(240, g.up(360)), crack);
    // A small high window with bars (daylight).
    final win = Rect.fromLTWH(196, g.up(470), 92, 52 * g.s + 8);
    c.drawRect(win.inflate(4), Paint()..color = const Color(0xFF8A8173));
    c.drawRect(win, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFBFE3F7), Color(0xFFEAF6FC)]).createShader(win));
    for (var i = 1; i < 5; i++) {
      final x = win.left + win.width * i / 5;
      c.drawLine(Offset(x, win.top), Offset(x, win.bottom), Paint()..color = const Color(0xFF4F4A42)..strokeWidth = 2.4);
    }
    c.drawRect(Rect.fromLTRB(0, g.floorY - 12, w, g.floorY), Paint()..color = const Color(0xFF9C9584));
    // The floor: concrete, with the trench the cable comes out of.
    c.drawRect(
        Rect.fromLTRB(0, g.floorY, w, size.height),
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF7D7A73), Color(0xFF55534E)])
              .createShader(Rect.fromLTRB(0, g.floorY, w, size.height)));
    final trench = Rect.fromCenter(center: Offset(MeggerGeo.cx, g.floorY + 9), width: 64, height: 14);
    c.drawRRect(RRect.fromRectAndRadius(trench, const Radius.circular(3)), Paint()..color = const Color(0xFF26241F));
    c.drawLine(trench.topLeft, trench.topRight, Paint()..color = const Color(0xFF9A968C)..strokeWidth = 2);

    _panel(c);
    _cable(c);
    _meterBody(c);
  }

  void _panel(Canvas c) {
    final p = geo.panel;
    final body = RRect.fromRectAndRadius(p, const Radius.circular(4));
    c.drawRRect(body.shift(const Offset(3, 4)), Paint()..color = const Color(0x44000000));
    c.drawRRect(body, Paint()..shader = const LinearGradient(colors: [Color(0xFF6E8B74), Color(0xFF4D6A55)]).createShader(p));
    c.drawRRect(body, Paint()..color = const Color(0xFF2E4234)..style = PaintingStyle.stroke..strokeWidth = 1.6);
    // The isolator handle, down (OFF).
    final hub = Offset(p.center.dx, p.top + p.height * 0.42);
    c.drawCircle(hub, 9, Paint()..color = const Color(0xFF2A2A2A));
    c.drawLine(hub, hub + const Offset(0, 18), Paint()..color = const Color(0xFFB8322A)..strokeWidth = 6..strokeCap = StrokeCap.round);
    _text(c, 'ON', Offset(p.center.dx, p.top + 10), size: 8, color: const Color(0xFFE9F0EA));
    _text(c, 'OFF', Offset(p.center.dx, hub.dy + 30), size: 8, color: const Color(0xFFE9F0EA));
    // The padlock and its red tag.
    final lock = Offset(hub.dx + 20, hub.dy + 12);
    c.drawArc(Rect.fromCenter(center: lock - const Offset(0, 6), width: 10, height: 10), math.pi, math.pi, false, Paint()..color = const Color(0xFFB0B4B8)..style = PaintingStyle.stroke..strokeWidth = 2.2);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: lock, width: 13, height: 11), const Radius.circular(2)), Paint()..color = const Color(0xFFD9A62A));
    final tag = Rect.fromLTWH(lock.dx - 7, lock.dy + 7, 15, 20);
    c.drawRect(tag, Paint()..color = const Color(0xFFD23A2E));
    c.drawLine(lock, tag.topCenter, Paint()..color = const Color(0xFF333333)..strokeWidth = 1);
    // The empty glands at its foot: the cable is off.
    c.drawRect(Rect.fromLTWH(p.left + 16, p.bottom, 46, 6), Paint()..color = const Color(0xFF3A3F44));
  }

  void _cable(Canvas c) {
    final g = geo;
    const cx = MeggerGeo.cx;
    // The armour: grey steel wires spiralling up from the trench to the gland.
    final arm = Rect.fromLTRB(cx - 11, g.glandY, cx + 11, g.floorY + 8);
    c.drawRect(arm, Paint()..shader = const LinearGradient(colors: [Color(0xFF5E646A), Color(0xFFB9BEC2), Color(0xFF6A7076)]).createShader(arm));
    final wire = Paint()
      ..color = const Color(0x664A4F55)
      ..strokeWidth = 1.2;
    for (var y = arm.top + 4; y < arm.bottom; y += 5) {
      c.drawLine(Offset(arm.left, y + 4), Offset(arm.right, y), wire);
    }
    // The earth clamp band on the armour, with its green-yellow earth wire to the floor.
    final band = Rect.fromCenter(center: g.armourAt, width: 28, height: 9);
    c.drawRRect(RRect.fromRectAndRadius(band, const Radius.circular(2)), Paint()..color = const Color(0xFFB98A3A));
    c.drawCircle(band.centerRight + const Offset(2, 0), 3.4, Paint()..color = const Color(0xFF8C6A2C));
    final ew = Path()
      ..moveTo(band.right + 2, band.center.dy)
      ..quadraticBezierTo(band.right + 20, band.center.dy + 10, g.earthPoint.dx, g.earthPoint.dy);
    c.drawPath(ew, Paint()..color = const Color(0xFFE6CF2A)..strokeWidth = 3.4..style = PaintingStyle.stroke);
    c.drawPath(ew, Paint()..color = const Color(0xFF2E9A44)..strokeWidth = 1.6..style = PaintingStyle.stroke);
    // The brass gland where the cores come out.
    final gland = Rect.fromCenter(center: Offset(cx, g.glandY), width: 30, height: 12);
    c.drawRRect(RRect.fromRectAndRadius(gland, const Radius.circular(3)), Paint()..shader = const LinearGradient(colors: [Color(0xFF9C7A2E), Color(0xFFE6C66A), Color(0xFF9C7A2E)]).createShader(gland));
    // The black inner sheath a little above the gland.
    final sheath = Rect.fromLTRB(cx - 9, g.glandY - 20 * g.s, cx + 9, g.glandY - 4);
    c.drawRect(sheath, Paint()..color = const Color(0xFF26282B));
    // The three cores, fanning out, each with a bare copper end and a lug.
    for (var i = 0; i < 3; i++) {
      final from = Offset(cx - 6 + 6.0 * i, sheath.top + 1);
      final end = g.coreEnds[i];
      final ctrl = Offset(from.dx + (end.dx - from.dx) * 0.15, (from.dy + end.dy) / 2 + 10);
      final path = Path()
        ..moveTo(from.dx, from.dy)
        ..quadraticBezierTo(ctrl.dx, ctrl.dy, end.dx, end.dy + 14);
      c.drawPath(path, Paint()..color = const Color(0x55000000)..strokeWidth = 9..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
      c.drawPath(path, Paint()..color = coreColours[i]..strokeWidth = 7..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
      // Bare copper, then the lug ring.
      c.drawLine(end + const Offset(0, 14), end + const Offset(0, 5), Paint()..color = const Color(0xFFD4874A)..strokeWidth = 5);
      c.drawCircle(end, 6.5, Paint()..color = const Color(0xFFC9A061));
      c.drawCircle(end, 2.6, Paint()..color = const Color(0xFF6B5326));
    }
  }

  void _meterBody(Canvas c) {
    final g = geo;
    final m = g.meter;
    // The rubber mat under it.
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(m.left - 44, g.floorY - 6, m.right + 4, g.floorY + 30), const Radius.circular(6)), Paint()..color = const Color(0xFF22262B));
    final body = RRect.fromRectAndRadius(m, const Radius.circular(10));
    c.drawRRect(body.shift(const Offset(3, 5)), Paint()..color = const Color(0x55000000));
    c.drawRRect(body, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFE7B23A), Color(0xFFC88F1E)]).createShader(m));
    final face = RRect.fromRectAndRadius(m.deflate(5), const Radius.circular(7));
    c.drawRRect(face, Paint()..color = const Color(0xFF2B2F35));
    // Terminals: L (red) and E (black), and the printed name.
    c.drawCircle(g.lTerminal, 6, Paint()..color = const Color(0xFFC8352B));
    c.drawCircle(g.eTerminal, 6, Paint()..color = const Color(0xFF111111));
    c.drawCircle(g.eTerminal, 6, Paint()..color = const Color(0xFF8A8F96)..style = PaintingStyle.stroke..strokeWidth = 1.2);
    _text(c, 'L', g.lTerminal + const Offset(11, 0), size: 9, color: const Color(0xFFF2F2F2));
    _text(c, 'E', g.eTerminal + const Offset(11, 0), size: 9, color: const Color(0xFFF2F2F2));
    _text(c, 'INSULATION TESTER', Offset(m.right - 46, m.top + 13), size: 6.5, color: const Color(0xFFE7B23A), weight: FontWeight.w800);
    // The gauge: a cream scale with its ticks, labels and "MΩ".
    final gr = g.gauge;
    c.drawRRect(RRect.fromRectAndRadius(gr, const Radius.circular(5)), Paint()..color = const Color(0xFFF4EEDC));
    final arcR = g.needleLen;
    const a0 = math.pi * 1.16;
    const sweep = math.pi * 0.68;
    final tick = Paint()
      ..color = const Color(0xFF1B1F24)
      ..strokeWidth = 1.2;
    c.drawArc(Rect.fromCircle(center: g.pivot, radius: arcR), a0, sweep, false, Paint()..color = const Color(0xFF1B1F24)..style = PaintingStyle.stroke..strokeWidth = 1.4);
    for (var i = 0; i <= 30; i++) {
      final a = a0 + sweep * i / 30;
      final major = i % 5 == 0;
      final d = Offset(math.cos(a), math.sin(a));
      c.drawLine(g.pivot + d * arcR, g.pivot + d * (arcR - (major ? 6 : 3)), tick);
    }
    for (final (p, label) in meggerTicks) {
      final a = a0 + sweep * p;
      final d = Offset(math.cos(a), math.sin(a));
      _text(c, label, g.pivot + d * (arcR - 13), size: 8, weight: FontWeight.w800);
    }
    _text(c, 'MΩ', g.pivot + const Offset(0, -18), size: 8.5, weight: FontWeight.w900, color: const Color(0xFF6B5326));
    // The selector's printed voltages (the knob itself is drawn live).
    for (final (i, v) in meggerVolts.indexed) {
      _text(c, '$v', _voltLabel(i), size: 8.5, color: const Color(0xFFE9E3D2), align: TextAlign.left);
    }
    _text(c, 'V', g.knob + const Offset(0, 22), size: 8, color: const Color(0xFFE9E3D2));
    // The display window.
    c.drawRRect(RRect.fromRectAndRadius(g.display, const Radius.circular(3)), Paint()..color = const Color(0xFF9FB59A));
    // The TEST button's ring.
    c.drawCircle(g.testButton, MeggerGeo.testRadius + 2, Paint()..color = const Color(0xFF15181C));
    _text(c, 'TEST', g.testButton + const Offset(0, MeggerGeo.testRadius + 7), size: 7, color: const Color(0xFFE9E3D2), weight: FontWeight.w900);
  }

  Offset _voltLabel(int i) => Offset(geo.knob.dx + 18, geo.knob.dy - 20 + 12.0 * i);

  @override
  bool shouldRepaint(MeggerRoomPainter old) => old.geo != geo;
}

/// Where the discharge rod is.
enum RodPose { rest, held, touch }

/// The live parts: needle, display, selector knob, TEST button, leads and
/// clips, the discharge rod and a discharge spark. Text only as a tester prints it.
class MeggerLivePainter extends CustomPainter {
  const MeggerLivePainter({
    required this.geo,
    required this.needle,
    required this.topLine,
    required this.readout,
    required this.volts,
    required this.lAt,
    required this.eAt,
    required this.lLifted,
    required this.eLifted,
    required this.cracked,
    required this.rod,
    required this.rodTip,
    required this.pressed,
    required this.spark,
    required this.sparkAt,
    required this.tags,
  });

  final MeggerGeo geo;

  /// The needle's place on the scale (0–1).
  final double needle;
  final String topLine;
  final String readout;
  final int volts;

  /// Where each clip is (parked or on the cable).
  final Offset lAt;
  final Offset eAt;

  /// Picked up (in his hand, about to go on).
  final bool lLifted;
  final bool eLifted;

  /// The red lead's insulation is cracked (copper shows).
  final bool cracked;
  final RodPose rod;

  /// The rod's hook when it touches a core.
  final Offset? rodTip;
  final bool pressed;

  /// A discharge spark (0 → 1), and where.
  final double spark;
  final Offset? sparkAt;

  /// The cores done, with their tags: true = ঠিক, false = ফল্ট.
  final Map<int, bool> tags;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    _needle(c);
    // The display: the test voltage, and the seconds or the reading.
    final d = g.display;
    _text(c, topLine, Offset(d.center.dx, d.top + 8), size: 8, color: const Color(0xFF1E2A1C));
    _text(c, readout, Offset(d.center.dx, d.bottom - 11), size: readout.length > 6 ? 11 : 13, weight: FontWeight.w900, color: const Color(0xFF14200F));
    // The selector knob, its pointer on the chosen voltage.
    final k = g.knob;
    c.drawCircle(k, 13, Paint()..shader = const RadialGradient(colors: [Color(0xFF5A6068), Color(0xFF1C1F23)]).createShader(Rect.fromCircle(center: k, radius: 13)));
    final i = meggerVolts.indexOf(volts).clamp(0, 3);
    final target = Offset(k.dx + 18, k.dy - 20 + 12.0 * i);
    final dir = (target - k) / (target - k).distance;
    c.drawLine(k, k + dir * 12, Paint()..color = const Color(0xFFF4EEDC)..strokeWidth = 2.6..strokeCap = StrokeCap.round);
    c.drawCircle(target + const Offset(-3, 0), 2.2, Paint()..color = const Color(0xFFFFD34E));
    // TEST.
    final t = g.testButton;
    c.drawCircle(t, MeggerGeo.testRadius, Paint()..shader = RadialGradient(colors: pressed ? const [Color(0xFF9E2A20), Color(0xFF5C1510)] : const [Color(0xFFE2493B), Color(0xFF8F2219)]).createShader(Rect.fromCircle(center: t, radius: MeggerGeo.testRadius)));
    if (!pressed) c.drawCircle(t - const Offset(5, 6), 6, Paint()..color = const Color(0x33FFFFFF));
    // Tags on the cores already tested.
    for (final e in tags.entries) {
      final at = g.coreEnds[e.key] + const Offset(0, 30);
      final r = Rect.fromCenter(center: at, width: 30, height: 15);
      c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), Paint()..color = e.value ? const Color(0xFF2E8B45) : const Color(0xFFC0392B));
      _text(c, e.value ? 'OK' : 'FAULT', r.center, size: 7.5, color: Colors.white, weight: FontWeight.w900);
    }
    _lead(c, g.lTerminal, lAt, const Color(0xFFC8352B), cracked: cracked);
    _lead(c, g.eTerminal, eAt, const Color(0xFF16181B));
    _clip(c, lAt, const Color(0xFFC8352B), lLifted, g.coreEnds.any((e) => (e - lAt).distance < 2));
    _clip(c, eAt, const Color(0xFF16181B), eLifted, (g.armourAt - eAt).distance < 2);
    _rod(c);
    if (sparkAt != null && spark > 0 && spark < 1) _spark(c, sparkAt!, spark);
  }

  void _needle(Canvas c) {
    final g = geo;
    const a0 = math.pi * 1.16;
    const sweep = math.pi * 0.68;
    final a = a0 + sweep * needle.clamp(0.0, 1.0);
    final tip = g.pivot + Offset(math.cos(a), math.sin(a)) * (g.needleLen - 2);
    c.save();
    c.clipRect(g.gauge);
    c.drawLine(g.pivot, tip, Paint()..color = const Color(0xFFB3261E)..strokeWidth = 1.8..strokeCap = StrokeCap.round);
    c.drawCircle(g.pivot, 4, Paint()..color = const Color(0xFF1B1F24));
    c.restore();
  }

  void _lead(Canvas c, Offset from, Offset to, Color colour, {bool cracked = false}) {
    // Parked on the lid: a short loop up; on the cable: slack hanging down.
    final parked = to.dy < from.dy;
    final mid = Offset((from.dx + to.dx) / 2, parked ? to.dy - 22 : math.max(from.dy, to.dy) + 40);
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..quadraticBezierTo(mid.dx, mid.dy, to.dx, to.dy + 8);
    c.drawPath(path, Paint()..color = const Color(0x55000000)..strokeWidth = 5..style = PaintingStyle.stroke);
    c.drawPath(path, Paint()..color = colour..strokeWidth = 3.4..style = PaintingStyle.stroke);
    if (cracked) {
      // A split in the insulation near the terminal: bright copper inside.
      final m = path.computeMetrics().first;
      final p = m.getTangentForOffset(m.length * 0.18)!.position;
      c.drawOval(Rect.fromCenter(center: p, width: 9, height: 5), Paint()..color = const Color(0xFFF0A35A));
      c.drawOval(Rect.fromCenter(center: p, width: 9, height: 5), Paint()..color = const Color(0xFF4A1A12)..style = PaintingStyle.stroke..strokeWidth = 1);
    }
  }

  void _clip(Canvas c, Offset at, Color colour, bool lifted, bool on) {
    final p = lifted ? at + const Offset(0, -6) : at;
    if (lifted) c.drawCircle(p, 16, Paint()..color = const Color(0x55FFD34E));
    // A crocodile clip: insulated boot, two jaws.
    final boot = RRect.fromRectAndRadius(Rect.fromCenter(center: p + const Offset(0, 9), width: 9, height: 14), const Radius.circular(3));
    c.drawRRect(boot, Paint()..color = colour);
    final jaw = Paint()
      ..color = const Color(0xFFB9BEC2)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    final open = on ? 1.5 : 3.5;
    c.drawLine(p + const Offset(-2, 2), p + Offset(-open, -7), jaw);
    c.drawLine(p + const Offset(2, 2), p + Offset(open, -7), jaw);
  }

  void _rod(Canvas c) {
    final g = geo;
    final (Offset foot, Offset tip) = switch (rod) {
      RodPose.rest => (g.rodFoot, g.rodRestTip),
      RodPose.held => (g.rodHeldGrip, g.rodHeldTip),
      RodPose.touch => (g.rodHeldGrip, rodTip ?? g.rodHeldTip),
    };
    final dir = (tip - foot) / (tip - foot).distance;
    final hookStart = tip - dir * 8;
    // The insulated stick (red grip band near the foot), a metal hook at the top.
    c.drawLine(foot, hookStart, Paint()..color = const Color(0x55000000)..strokeWidth = 7..strokeCap = StrokeCap.round);
    c.drawLine(foot, hookStart, Paint()..color = const Color(0xFFE0B13A)..strokeWidth = 5..strokeCap = StrokeCap.round);
    c.drawLine(foot + dir * 4, foot + dir * 26, Paint()..color = const Color(0xFFB8322A)..strokeWidth = 6.4..strokeCap = StrokeCap.butt);
    final hook = Path()
      ..moveTo(hookStart.dx, hookStart.dy)
      ..lineTo(tip.dx, tip.dy)
      ..relativeQuadraticBezierTo(dir.dy * 6 + dir.dx * 4, -dir.dx * 6 + dir.dy * 4, dir.dy * 7, -dir.dx * 7);
    c.drawPath(hook, Paint()..color = const Color(0xFF9AA1A8)..strokeWidth = 2.6..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    // Its green earth lead to the earth point.
    final e = g.earthPoint;
    final lead = Path()
      ..moveTo(hookStart.dx, hookStart.dy)
      ..quadraticBezierTo((hookStart.dx + e.dx) / 2, math.max(hookStart.dy, e.dy) + 24, e.dx, e.dy);
    c.drawPath(lead, Paint()..color = const Color(0xFF2E9A44)..strokeWidth = 1.8..style = PaintingStyle.stroke);
    c.drawCircle(e, 3, Paint()..color = const Color(0xFF8C6A2C));
  }

  void _spark(Canvas c, Offset at, double v) {
    final r = 6 + 22 * v;
    c.drawCircle(at, r, Paint()..shader = RadialGradient(colors: [Color.fromRGBO(255, 250, 220, 1 - v), const Color(0x00FFC24A)]).createShader(Rect.fromCircle(center: at, radius: r)));
    final p = Paint()
      ..color = Color.fromRGBO(255, 214, 90, (1 - v).clamp(0.0, 1.0))
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 10; i++) {
      final a = i / 10 * math.pi * 2 + 0.4;
      final d0 = 5 + 16 * v;
      c.drawLine(at + Offset(math.cos(a), math.sin(a)) * d0, at + Offset(math.cos(a), math.sin(a)) * (d0 + 7), p);
    }
  }

  @override
  bool shouldRepaint(MeggerLivePainter old) =>
      old.geo != geo ||
      old.needle != needle ||
      old.topLine != topLine ||
      old.readout != readout ||
      old.volts != volts ||
      old.lAt != lAt ||
      old.eAt != eAt ||
      old.lLifted != lLifted ||
      old.eLifted != eLifted ||
      old.cracked != cracked ||
      old.rod != rod ||
      old.rodTip != rodTip ||
      old.pressed != pressed ||
      old.spark != spark ||
      old.sparkAt != sparkAt ||
      !mapEquals(old.tags, tags);
}

/// The charged core's arc to the hand (in colour over the frozen grey room).
class MeggerArcPainter extends CustomPainter {
  const MeggerArcPainter({required this.from, required this.to, required this.v});
  final Offset from;
  final Offset to;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final flick = v < 0.5 ? (0.6 + 0.4 * math.sin(v * 70).abs()) : (1 - (v - 0.5) * 1.2).clamp(0.35, 1.0);
    final rnd = math.Random(3);
    final pts = <Offset>[from];
    for (var i = 1; i < 7; i++) {
      final k = i / 7;
      final p = Offset.lerp(from, to, k)!;
      pts.add(p + Offset((rnd.nextDouble() - 0.5) * 16, (rnd.nextDouble() - 0.5) * 16));
    }
    pts.add(to);
    final path = Path()..addPolygon(pts, false);
    c.drawPath(path, Paint()..color = Color.fromRGBO(150, 175, 255, 0.7 * flick)..style = PaintingStyle.stroke..strokeWidth = 10..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    c.drawPath(path, Paint()..color = Color.fromRGBO(255, 255, 255, flick)..style = PaintingStyle.stroke..strokeWidth = 2.6..strokeJoin = StrokeJoin.round);
    for (final p in [from, to]) {
      final r = 10 + 20 * Curves.easeOut.transform(v.clamp(0.0, 1.0));
      c.drawCircle(p, r, Paint()..shader = RadialGradient(colors: [Color.fromRGBO(255, 245, 200, 0.9 * flick), const Color(0x00FFC24A)]).createShader(Rect.fromCircle(center: p, radius: r)));
    }
  }

  @override
  bool shouldRepaint(MeggerArcPainter old) => old.v != v || old.from != from || old.to != to;
}
