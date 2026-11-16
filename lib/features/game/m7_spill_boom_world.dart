import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The drawn world of lesson 7.8 কাজ 1 "এক ফোঁটাও মাটিতে নয়" (m7_spill_boom.dart).
//
// A village roadside DTR on its plinth, dry afternoon: a tube well and a pond
// far off; the DTR (drawn as background state, never scored: the AB switch on
// the pole open with all three blades seen, its handle locked and tagged, the
// earth set, the PTW tag) with the drain valve at the bottom of the tank; a
// roadside drain with a grating, the soil sloping to it; the red spill-kit box
// (pads, boom rolls), three containers on the ground in dealt places (a
// closed leak-proof drum, a second drum — sound or with a weeping seam — and an
// open bucket; none labelled), the hose, a red hazardous-waste bag and a green
// general bin. Design: 360 wide × the scene's height (560–900). The drain may be
// on either side (the whole yard mirrors). No text in the art; no outline shows
// where a boom goes.

/// What stands in a container slot.
enum M7SlotKind { drum, drumB, bucket }

/// Where the hose end can land.
enum M7Target { slot, drain, soil, none }

/// The incident's look: where the oil comes from.
enum M7Incident { couplingDrip, bungSpurt, sampleCan, gasketWeep }

/// The ring's verdict (drawn boom, closed or not, round the work spot).
enum M7RingJudge { tooShort, open, misses, ok }

// --- ring maths (pure) --------------------------------------------------------

/// A finger line shorter than this (design px) is no boom.
const double m7RingMinPath = 120;

/// The two ends may be this far apart (design px) and still close the ring.
const double m7RingCloseTol = 34;

double m7PathLen(List<Offset> pts) {
  var s = 0.0;
  for (var i = 1; i < pts.length; i++) {
    s += (pts[i] - pts[i - 1]).distance;
  }
  return s;
}

/// Ray casting (the polygon closes itself from the last point to the first).
bool m7Encloses(List<Offset> pts, Offset p) {
  var inside = false;
  for (var i = 0, j = pts.length - 1; i < pts.length; j = i++) {
    final a = pts[i];
    final b = pts[j];
    if ((a.dy > p.dy) != (b.dy > p.dy) && p.dx < (b.dx - a.dx) * (p.dy - a.dy) / (b.dy - a.dy) + a.dx) inside = !inside;
  }
  return inside;
}

/// A drawn boom: too short = nothing; ends apart = open; closed but missing a
/// point it must enclose = misses; else ok.
M7RingJudge m7JudgeRing(List<Offset> pts, List<Offset> mustEnclose) {
  if (pts.length < 3 || m7PathLen(pts) < m7RingMinPath) return M7RingJudge.tooShort;
  if ((pts.last - pts.first).distance > m7RingCloseTol) return M7RingJudge.open;
  for (final p in mustEnclose) {
    if (!m7Encloses(pts, p)) return M7RingJudge.misses;
  }
  return M7RingJudge.ok;
}

/// Where things are (design px, 360 wide).
@immutable
class M7SpillGeo {
  const M7SpillGeo._(this.height, this.gy, this.flip);

  /// [drainRight] false mirrors the whole yard (the drain on the left).
  factory M7SpillGeo.forScene(double height, double inset, {bool drainRight = true}) =>
      M7SpillGeo._(height, height - 290 - inset * 0.3, !drainRight);

  final double height;

  /// The ground reference line (the back of the work area).
  final double gy;
  final bool flip;

  double x(double v) => flip ? 360 - v : v;
  Offset _p(double px, double py) => Offset(x(px), py);
  Rect _r(double l, double t, double w, double h) => Rect.fromLTWH(flip ? 360 - l - w : l, t, w, h);

  /// The tank's bottom, the plinth and the ground's back edge.
  double get tankBottom => gy - 84;
  double get tankTop => math.max(122.0, gy - 200);
  double get groundTop => gy - 68;
  Rect get tank => _r(100, tankTop, 156, tankBottom - tankTop);
  Rect get plinth => _r(92, tankBottom, 172, 16);

  // --- the drain valve (a quarter-turn lever) ---------------------------------
  Offset get valvePivot => _p(178, gy - 100);
  static const double leverLen = 20;

  /// The lever's end at progress [p] (0 shut = across, 1 open = along the pipe).
  Offset knob(double p) {
    final a = (180 - 90 * p.clamp(0.0, 1.0)) * math.pi / 180;
    return _p(178 + math.cos(a) * leverLen, gy - 100 + math.sin(a) * leverLen);
  }

  /// The progress for a finger at [at] (by its angle round the pivot).
  double progressAt(Offset at) {
    final d = Offset(x(at.dx) - 178, at.dy - (gy - 100));
    final deg = math.atan2(d.dy, d.dx) * 180 / math.pi;
    return ((180 - deg) / 90).clamp(0.0, 1.0);
  }

  Rect knobHit(double p) => Rect.fromCenter(center: knob(p), width: 44, height: 44);

  /// The whole arc (where a hand sweep passes).
  Rect get valveArea => Rect.fromCenter(center: _p(172, gy - 90), width: 58, height: 52);

  // --- the work spot ------------------------------------------------------------
  Offset get spill => _p(178, gy - 34);
  Offset get pallet => _p(236, gy - 28);

  /// Pads dropped inside here are under the valve.
  Rect get padZone => _r(135, gy - 62, 130, 58);

  /// Where the placed pads lie (up to three).
  Offset padSpot(int i) => _p(156 + 28.0 * i, gy - 30 + (i.isOdd ? -6 : 4));

  /// Where an incident starts: between the valve spot and the pallet.
  Offset incident(double t, double dy) => Offset.lerp(spill, pallet, t.clamp(0.0, 1.0))! + Offset(0, dy);

  // --- the kit ---------------------------------------------------------------------
  Rect get kitBox => _r(24, gy - 52, 76, 48);
  Rect get kitHit => kitBox;
  Rect get padStackHit => _r(24, gy - 86, 36, 32);
  Rect get boomRollHit => _r(62, gy - 86, 38, 32);

  // --- the hose ------------------------------------------------------------------------
  Offset get hoseOutlet => _p(178, tankBottom + 2);
  Offset get hoseHome => _p(224, gy - 62);
  Rect hoseHit(Offset end) => Rect.fromCenter(center: end, width: 40, height: 40);

  // --- containers, bins, drain ---------------------------------------------------------
  Rect slot(int i) => _r(28.0 + 66 * i, gy + 4, 52, 44);

  /// Where the hose end lies once it is in slot [i].
  Offset slotMouth(int i) => slot(i).topCenter + const Offset(0, 8);
  Rect get redBin => _r(270, gy + 4, 40, 44);
  Rect get greenBin => _r(316, gy + 4, 40, 44);
  Rect get grating => _r(296, gy - 52, 58, 26);
  Rect get drainHit => _r(290, gy - 58, 70, 38);
  Rect get soilHit => _r(268, gy - 22, 56, 28);
  Offset get drainEdge => Offset(grating.center.dx, grating.center.dy);

  /// The bung on the container in slot [i] (the open top).
  Rect bungHit(int i) => Rect.fromCenter(center: slot(i).topCenter + const Offset(0, 10), width: 46, height: 28);

  /// The target a hose end let go at [p] lands on (and the slot, if one).
  (M7Target, int) targetAt(Offset p) {
    for (var i = 0; i < 3; i++) {
      if (slot(i).inflate(4).contains(p)) return (M7Target.slot, i);
    }
    if (drainHit.contains(p)) return (M7Target.drain, -1);
    if (soilHit.contains(p)) return (M7Target.soil, -1);
    return (M7Target.none, -1);
  }

  /// Where a hand sweep over the set-up passes (the kit, the valve, the hose
  /// end and the containers: none pressed).
  List<Rect> setupSweep() => [kitHit, valveArea, hoseHit(hoseHome), slot(0), slot(1), slot(2)];

  /// A neutral spot on the ground for the boom's hand (away from the valve
  /// spot and the puddle).
  Offset get boomHintAt => _p(112, gy + 14);

  /// The soak spot of a puddle centred [c] with half-width [r].
  Rect puddleHit(Offset c, double r) => Rect.fromCenter(center: c, width: math.max(56, r * 2 + 18), height: math.max(40, r * 1.2 + 18));

  Rect get traineeRect => _r(148, gy - 108, 44, 104);
  Rect get mateRect => _r(112, gy - 104, 40, 100);

  /// The ground-slice inset (a consequence picture only).
  static const Rect sliceCard = Rect.fromLTWH(70, 138, 220, 130);

  @override
  bool operator ==(Object other) => other is M7SpillGeo && other.height == height && other.gy == gy && other.flip == flip;

  @override
  int get hashCode => Object.hash(height, gy, flip);
}

/// What the painter shows now.
@immutable
class M7SpillRig {
  const M7SpillRig({
    required this.slots,
    required this.weeping,
    required this.incident,
    required this.dusk,
    this.kitOpen = false,
    this.pads = 0,
    this.ring1,
    this.ring2,
    this.valve = 0,
    this.hoseEnd,
    this.hoseSlot,
    this.puddleOn = false,
    this.puddleAt = Offset.zero,
    this.puddleR = 0,
    this.held = true,
    this.edge = 0,
    this.edgeDir = Offset.zero,
    this.left = 1,
    this.soaked = 0,
    this.usedPads = 0,
    this.bagged = false,
    this.bungShut = false,
    this.dripBung = false,
    this.dragPad,
  });

  final List<M7SlotKind> slots;
  final bool weeping;
  final M7Incident incident;
  final bool dusk;
  final bool kitOpen;
  final int pads;
  final List<Offset>? ring1;
  final List<Offset>? ring2;
  final double valve;

  /// The hose end now (null = at the valve, home) and the slot it is in.
  final Offset? hoseEnd;
  final int? hoseSlot;
  final bool puddleOn;
  final Offset puddleAt;
  final double puddleR;

  /// The puddle is held by the set-up ring (clipped to it).
  final bool held;

  /// How far the oil has run past the ring toward the drain, and which way.
  final double edge;
  final Offset edgeDir;

  /// How much of the puddle is left (1 whole … 0 soaked up).
  final double left;
  final int soaked;
  final int usedPads;
  final bool bagged;
  final bool bungShut;
  final bool dripBung;

  /// A pad being dragged out of the kit (where the finger is).
  final Offset? dragPad;

  @override
  bool operator ==(Object other) =>
      other is M7SpillRig &&
      listEquals(other.slots, slots) &&
      other.weeping == weeping &&
      other.incident == incident &&
      other.dusk == dusk &&
      other.kitOpen == kitOpen &&
      other.pads == pads &&
      identical(other.ring1, ring1) &&
      identical(other.ring2, ring2) &&
      other.valve == valve &&
      other.hoseEnd == hoseEnd &&
      other.hoseSlot == hoseSlot &&
      other.puddleOn == puddleOn &&
      other.puddleAt == puddleAt &&
      other.puddleR == puddleR &&
      other.held == held &&
      other.edge == edge &&
      other.edgeDir == edgeDir &&
      other.left == left &&
      other.soaked == soaked &&
      other.usedPads == usedPads &&
      other.bagged == bagged &&
      other.bungShut == bungShut &&
      other.dripBung == dripBung &&
      other.dragPad == dragPad;

  @override
  int get hashCode => Object.hashAll([
        Object.hashAll(slots),
        weeping,
        incident,
        dusk,
        kitOpen,
        pads,
        ring1,
        ring2,
        valve,
        hoseEnd,
        hoseSlot,
        puddleOn,
        puddleAt,
        puddleR,
        held,
        edge,
        edgeDir,
        left,
        soaked,
        usedPads,
        bagged,
        bungShut,
        dripBung,
        dragPad,
      ]);
}

const _steel = Color(0xFF6F7880);
const _steelDark = Color(0xFF454C53);
const _soilA = Color(0xFFA68B62);
const _soilB = Color(0xFF8B7350);
const _oil = Color(0xFF1B140F);
const _boom = Color(0xFFF1E4A6);
const _boomEdge = Color(0xFFB59A3C);
const _drumBlue = Color(0xFF2F5C9A);
const _kitRed = Color(0xFFC83A2C);
const _padTan = Color(0xFFD9CFB8);
const _earthGreen = Color(0xFF2E9E4F);
const _earthYellow = Color(0xFFF2C230);

class M7SpillPainter extends CustomPainter {
  M7SpillPainter({required this.geo, required this.rig, required this.stroke}) : super(repaint: stroke);

  final M7SpillGeo geo;
  final M7SpillRig rig;

  /// The boom being drawn right now (repaints without a rebuild).
  final ValueListenable<List<Offset>> stroke;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    final h = size.height;
    _background(c, w, h);
    _dtr(c);
    _ground(c, w, h);
    _kit(c);
    for (var i = 0; i < 3; i++) {
      _container(c, i);
    }
    _bins(c);
    _padsPlaced(c);
    final dp = rig.dragPad;
    if (dp != null) c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: dp, width: 30, height: 14), const Radius.circular(2)), Paint()..color = _padTan);
    _puddle(c);
    _hose(c);
    _valve(c);
    final r1 = rig.ring1;
    if (r1 != null) _boomPath(c, r1);
    final r2 = rig.ring2;
    if (r2 != null) _boomPath(c, r2);
    final live = stroke.value;
    if (live.length > 1) _boomPath(c, live, open: true);
    // The ground's bottom shade.
    c.drawRect(Rect.fromLTWH(0, g.gy + 56, w, h - g.gy - 56), Paint()..color = const Color(0x22000000));
  }

  void _background(Canvas c, double w, double h) {
    final g = geo;
    final sky = Rect.fromLTWH(0, 0, w, g.groundTop + 6);
    c.drawRect(
        sky,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: rig.dusk ? const [Color(0xFF36578A), Color(0xFFE8B98A), Color(0xFFEFD9B0)] : const [Color(0xFF4A86C4), Color(0xFFA5CDEB), Color(0xFFE6EFD9)],
          ).createShader(sky));
    // Far fields, trees, the pond and the tube well.
    final far = Paint()..color = const Color(0xFF6C9A5A);
    final rnd = math.Random(11);
    for (var x = -10.0; x < w + 20; x += 15 + rnd.nextDouble() * 14) {
      final r = 7 + rnd.nextDouble() * 8;
      c.drawCircle(Offset(x, g.groundTop - r * 0.3), r, far);
    }
    final pond = Rect.fromCenter(center: Offset(g.x(300), g.groundTop - 4), width: 70, height: 12);
    c.drawOval(pond, Paint()..color = const Color(0xFF5C93B5));
    c.drawOval(pond.deflate(3), Paint()..color = const Color(0xFF86B6D2));
    final wx = g.x(250);
    final wy = g.groundTop - 8;
    c.drawRect(Rect.fromLTWH(wx - 2, wy - 28, 4, 28), Paint()..color = _steelDark);
    c.drawRect(Rect.fromLTWH(wx - 9, wy - 32, 20, 5), Paint()..color = _steel);
    c.drawLine(Offset(wx + 9, wy - 30), Offset(wx + 20, wy - 22), Paint()
      ..color = _steelDark
      ..strokeWidth = 3);
  }

  /// The DTR on its plinth (background state, never scored): the AB switch on
  /// the pole open with all three blades seen, locked and tagged, the earth
  /// set, the PTW tag.
  void _dtr(Canvas c) {
    final g = geo;
    // The pole behind, left of the tank.
    final poleX = g.x(66);
    final pole = Rect.fromLTWH(poleX - 7, 0, 14, g.groundTop + 8);
    c.drawRect(pole, Paint()..shader = const LinearGradient(colors: [Color(0xFF9AA0A5), Color(0xFF5E656B)]).createShader(pole));
    // The AB cross-arm with three open blades.
    final armY = g.tankTop + 6;
    c.drawRect(Rect.fromLTWH(poleX - 44, armY, 88, 5), Paint()..color = _steelDark);
    for (var i = 0; i < 3; i++) {
      final px = poleX - 34 + 34.0 * i;
      c.drawRect(Rect.fromLTWH(px - 3, armY - 18, 6, 18), Paint()..color = const Color(0xFFD7DDE2));
      c.drawLine(Offset(px, armY - 18), Offset(px + 9, armY - 40), Paint()
        ..color = _steel
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round);
    }
    // The operating rod down to the locked handle with its tag.
    final handleY = g.tankBottom - 22;
    c.drawLine(Offset(poleX + 9, armY + 5), Offset(poleX + 9, handleY), Paint()
      ..color = _steelDark
      ..strokeWidth = 2.4);
    c.drawLine(Offset(poleX + 9, handleY), Offset(poleX + 22, handleY + 14), Paint()
      ..color = _steel
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round);
    c.drawCircle(Offset(poleX + 15, handleY + 7), 3.2, Paint()..color = const Color(0xFFE9B91F));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(poleX + 20, handleY + 12, 10, 14), const Radius.circular(2)), Paint()..color = const Color(0xFFE23B2E));
    // The earth lead to a rod.
    final lead = Path()
      ..moveTo(poleX - 8, g.tankBottom - 6)
      ..quadraticBezierTo(poleX - 26, g.tankBottom + 4, poleX - 26, g.groundTop + 6);
    c.drawPath(lead, Paint()
      ..color = _earthGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6);
    c.drawPath(lead, Paint()
      ..color = _earthYellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);
    // The plinth and the tank with its HG fuse drop on the pole side.
    c.drawRect(g.plinth, Paint()..color = const Color(0xFF9A9388));
    final tank = g.tank;
    c.drawRRect(
        RRect.fromRectAndRadius(tank, const Radius.circular(6)),
        Paint()
          ..shader = const LinearGradient(colors: [Color(0xFF7C8A93), Color(0xFF59666E), Color(0xFF7C8A93)]).createShader(tank));
    for (var i = 1; i < 6; i++) {
      c.drawLine(Offset(tank.left + 8, tank.top + tank.height * i / 6), Offset(tank.right - 8, tank.top + tank.height * i / 6), Paint()
        ..color = const Color(0x33000000)
        ..strokeWidth = 1.2);
    }
    // Bushings on top.
    for (var i = 0; i < 3; i++) {
      final bx = tank.left + 28 + 50.0 * i;
      c.drawRect(Rect.fromLTWH(bx - 4, tank.top - 12, 8, 12), Paint()..color = const Color(0xFFE6EBEF));
    }
    // The tank's drain pipe stub and the PTW tag on the tank.
    c.drawRect(Rect.fromCenter(center: Offset(g.valvePivot.dx, g.tankBottom - 8), width: 10, height: 16), Paint()..color = _steelDark);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(tank.left + 8, tank.top + 8, 16, 20), const Radius.circular(2)), Paint()..color = const Color(0xFFF7F1DE));
    c.drawRect(Rect.fromLTWH(tank.left + 10, tank.top + 12, 12, 3), Paint()..color = const Color(0xFFB03A2E));
  }

  void _ground(Canvas c, double w, double h) {
    final g = geo;
    final r = Rect.fromLTRB(0, g.groundTop, w, h);
    c.drawRect(
        r,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment(g.flip ? 1 : -1, 0),
            end: Alignment(g.flip ? -1 : 1, 0),
            colors: const [_soilA, _soilB],
          ).createShader(r));
    // Soil sloping toward the drain: faint stripes tilted to it.
    final stripe = Paint()
      ..color = const Color(0x1A3A2A12)
      ..strokeWidth = 2;
    for (var i = 0; i < 9; i++) {
      final y = g.groundTop + 14 + i * 16.0;
      c.drawLine(Offset(g.x(120), y), Offset(g.x(330), y + 8), stripe);
    }
    // The drain: a channel edge and the grating.
    final gr = g.grating;
    c.drawRect(gr.inflate(5), Paint()..color = const Color(0xFF6A6E72));
    c.drawRect(gr, Paint()..color = const Color(0xFF15181B));
    for (var x = gr.left + 4; x < gr.right - 2; x += 7) {
      c.drawLine(Offset(x, gr.top + 2), Offset(x, gr.bottom - 2), Paint()
        ..color = _steel
        ..strokeWidth = 2.4);
    }
  }

  void _kit(Canvas c) {
    final g = geo;
    final b = g.kitBox;
    c.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(5)), Paint()..color = _kitRed);
    c.drawRRect(
        RRect.fromRectAndRadius(b, const Radius.circular(5)),
        Paint()
          ..color = const Color(0xFF7D1D14)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    c.drawRect(Rect.fromLTWH(b.center.dx - 8, b.top + 4, 16, 8), Paint()..color = const Color(0xFFE9B91F));
    if (!rig.kitOpen) {
      // The closed lid.
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(b.left - 2, b.top - 8, b.width + 4, 10), const Radius.circular(3)), Paint()..color = const Color(0xFFA42E22));
      return;
    }
    // The lid up; a stack of pads and two rolls of boom stand out of the box.
    c.drawRect(Rect.fromLTWH(b.left + 2, b.top - 60, b.width - 4, 4), Paint()..color = const Color(0xFFA42E22));
    final ps = g.padStackHit;
    for (var i = 0; i < 4; i++) {
      c.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(ps.left + 2 + (i.isEven ? 0 : 2), ps.bottom - 8 - i * 6.5, ps.width - 4, 6), const Radius.circular(1.5)),
          Paint()..color = i.isEven ? _padTan : const Color(0xFFCABF9F));
    }
    final br = g.boomRollHit;
    for (var i = 0; i < 2; i++) {
      final rc = Rect.fromCenter(center: Offset(br.left + 10 + i * 18, br.bottom - 14), width: 16, height: 26);
      c.drawRRect(RRect.fromRectAndRadius(rc, const Radius.circular(8)), Paint()..color = _boom);
      c.drawRRect(
          RRect.fromRectAndRadius(rc, const Radius.circular(8)),
          Paint()
            ..color = _boomEdge
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4);
    }
  }

  void _container(Canvas c, int i) {
    final g = geo;
    final s = g.slot(i);
    final kind = rig.slots[i];
    if (kind == M7SlotKind.bucket) {
      // An open galvanised bucket.
      final body = Path()
        ..moveTo(s.left + 8, s.top + 8)
        ..lineTo(s.right - 8, s.top + 8)
        ..lineTo(s.right - 13, s.bottom)
        ..lineTo(s.left + 13, s.bottom)
        ..close();
      c.drawPath(body, Paint()..shader = const LinearGradient(colors: [Color(0xFFB9C2C8), Color(0xFF7D8890), Color(0xFFB9C2C8)]).createShader(s));
      c.drawOval(Rect.fromLTRB(s.left + 8, s.top + 3, s.right - 8, s.top + 13), Paint()..color = const Color(0xFF3B3F43));
      c.drawArc(Rect.fromLTRB(s.left + 8, s.top - 6, s.right - 8, s.top + 18), math.pi, math.pi, false, Paint()
        ..color = _steelDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6);
    } else {
      // A closed drum with ribs and a bung on top.
      final body = Rect.fromLTRB(s.left + 6, s.top + 8, s.right - 6, s.bottom);
      c.drawRRect(
          RRect.fromRectAndRadius(body, const Radius.circular(5)),
          Paint()
            ..shader = const LinearGradient(colors: [Color(0xFF5C84B8), _drumBlue, Color(0xFF244A7D)]).createShader(body));
      for (final f in [0.38, 0.7]) {
        c.drawLine(Offset(body.left, body.top + body.height * f), Offset(body.right, body.top + body.height * f), Paint()
          ..color = const Color(0x55000000)
          ..strokeWidth = 2);
      }
      c.drawOval(Rect.fromLTRB(s.left + 6, s.top + 3, s.right - 6, s.top + 14), Paint()..color = const Color(0xFF3F6BA6));
      // The bung: dark and open while the hose is in; plugged when shut.
      final plugged = rig.bungShut && rig.hoseSlot == i;
      c.drawCircle(Offset(s.center.dx + 8, s.top + 8.5), 3.6, Paint()..color = plugged ? const Color(0xFFE9B91F) : const Color(0xFF14181C));
      if (kind == M7SlotKind.drumB && rig.weeping) {
        // A weeping seam: a dark wet streak down the side and a drip below.
        final sx = s.left + 15;
        c.drawLine(Offset(sx, body.top + 6), Offset(sx, body.bottom - 3), Paint()
          ..color = _oil.withValues(alpha: 0.85)
          ..strokeWidth = 2.2);
        c.drawOval(Rect.fromCenter(center: Offset(sx, s.bottom + 3), width: 9, height: 5), Paint()..color = _oil.withValues(alpha: 0.8));
      }
      if (rig.hoseSlot == i && rig.valve > 0.5) {
        c.drawRect(Rect.fromLTWH(body.left + 4, body.bottom - 12, body.width - 8, 4), Paint()..color = const Color(0x66E9B91F));
      }
    }
  }

  void _bins(Canvas c) {
    final g = geo;
    // Red hazardous-waste bag.
    final rb = g.redBin;
    final bag = Path()
      ..moveTo(rb.left + 6, rb.top + 12)
      ..quadraticBezierTo(rb.left - 2, rb.bottom - 14, rb.left + 8, rb.bottom)
      ..lineTo(rb.right - 8, rb.bottom)
      ..quadraticBezierTo(rb.right + 2, rb.bottom - 14, rb.right - 6, rb.top + 12)
      ..close();
    c.drawPath(bag, Paint()..color = const Color(0xFFC62F2A));
    c.drawPath(
        bag,
        Paint()
          ..color = const Color(0xFF7D1613)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6);
    c.drawLine(Offset(rb.left + 8, rb.top + 12), Offset(rb.right - 8, rb.top + 12), Paint()
      ..color = const Color(0xFF7D1613)
      ..strokeWidth = 3);
    if (rig.bagged) {
      c.drawRect(Rect.fromLTWH(rb.left + 12, rb.top + 4, rb.width - 24, 8), Paint()..color = const Color(0xFF2A2018));
    }
    // Green general bin.
    final gb = g.greenBin;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(gb.left + 4, gb.top + 8, gb.width - 8, gb.height - 8), const Radius.circular(4)), Paint()..color = const Color(0xFF2F8F4E));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(gb.left + 1, gb.top + 3, gb.width - 2, 8), const Radius.circular(3)), Paint()..color = const Color(0xFF226B3A));
    c.drawLine(Offset(gb.center.dx, gb.top + 16), Offset(gb.center.dx, gb.bottom - 4), Paint()
      ..color = const Color(0x44000000)
      ..strokeWidth = 2);
  }

  void _padsPlaced(Canvas c) {
    final g = geo;
    for (var i = 0; i < rig.pads; i++) {
      final p = g.padSpot(i);
      final dark = i < rig.soaked || (rig.soaked >= 1 && rig.usedPads > 0 && i < rig.usedPads);
      c.drawRRect(
          RRect.fromRectAndRadius(Rect.fromCenter(center: p, width: 26, height: 12), const Radius.circular(2)),
          Paint()..color = dark ? const Color(0xFF3A3028) : _padTan);
    }
  }

  void _puddle(Canvas c) {
    if (!rig.puddleOn) return;
    final p = rig.puddleAt;
    final k = rig.left.clamp(0.0, 1.0);
    if (k <= 0.02) return;
    final rx = rig.puddleR * (0.35 + 0.65 * k);
    final ry = rx * 0.6;
    final blob = Path()..addOval(Rect.fromCenter(center: p, width: rx * 2, height: ry * 2));
    if (rig.edge > 0 && rig.edgeDir != Offset.zero) {
      // The tongue that ran past the ring toward the drain.
      final head = p + rig.edgeDir * (rig.puddleR + rig.edge);
      blob.addOval(Rect.fromCenter(center: Offset.lerp(p, head, 0.55)!, width: (head - p).distance * 1.1 * k, height: ry * 1.1));
      blob.addOval(Rect.fromCenter(center: head, width: 20 * k + 6, height: 12 * k + 4));
    }
    c.save();
    final r1 = rig.ring1;
    if (rig.held && r1 != null && r1.length > 2) {
      c.clipPath(Path()..addPolygon(r1, true));
    }
    c.drawPath(blob, Paint()..color = _oil.withValues(alpha: 0.9));
    c.drawPath(
        blob,
        Paint()
          ..shader = const LinearGradient(colors: [Color(0x553BA6E0), Color(0x55D86AC8), Color(0x5568D868)]).createShader(blob.getBounds()));
    c.restore();
  }

  void _hose(Canvas c) {
    final g = geo;
    final a = g.hoseOutlet;
    final b = rig.hoseEnd ?? g.hoseHome;
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..cubicTo(a.dx, a.dy + 26, b.dx, b.dy - 30, b.dx, b.dy);
    c.drawPath(path, Paint()
      ..color = const Color(0xFF14181C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round);
    c.drawPath(path, Paint()
      ..color = const Color(0xFF2D343A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: b, width: 14, height: 10), const Radius.circular(3)), Paint()..color = _steel);
    // The oil running down the hose while the valve is open and it is in a
    // container (a static thread: no animation).
    if (rig.valve > 0.5 && rig.hoseSlot != null) {
      c.drawPath(path, Paint()
        ..color = const Color(0xCCB07B2A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round);
    }
  }

  void _valve(Canvas c) {
    final g = geo;
    final pv = g.valvePivot;
    c.drawCircle(pv, 7, Paint()..color = _steelDark);
    c.drawLine(pv, g.knob(rig.valve), Paint()
      ..color = const Color(0xFFD94A2B)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round);
    c.drawCircle(g.knob(rig.valve), 5, Paint()..color = const Color(0xFFB03A2E));
    c.drawCircle(pv, 3, Paint()..color = const Color(0xFF9AA0A5));
    // The incident's source marks (coupling, bung, sample can, gasket).
    if (rig.puddleOn) {
      final at = rig.puddleAt;
      final mark = Paint()..color = _oil;
      switch (rig.incident) {
        case M7Incident.couplingDrip:
          c.drawCircle(at + const Offset(0, -14), 2.4, mark);
        case M7Incident.bungSpurt:
          c.drawLine(at + const Offset(0, -4), at + const Offset(8, -22), Paint()
            ..color = _oil
            ..strokeWidth = 2.4
            ..strokeCap = StrokeCap.round);
        case M7Incident.sampleCan:
          c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: at + const Offset(-12, -8), width: 12, height: 14), const Radius.circular(2)), Paint()..color = const Color(0xFF8A8F94));
        case M7Incident.gasketWeep:
          c.drawLine(at + const Offset(0, -18), at + const Offset(0, -6), Paint()
            ..color = _oil
            ..strokeWidth = 1.8);
      }
    }
  }

  void _boomPath(Canvas c, List<Offset> pts, {bool open = false}) {
    if (pts.length < 2) return;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx, pts[i].dy);
    }
    c.drawPath(path, Paint()
      ..color = _boomEdge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);
    c.drawPath(path, Paint()
      ..color = _boom
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(M7SpillPainter old) => old.geo != geo || old.rig != rig;
}

/// The ground-slice inset (a consequence picture only): soil layers, oil
/// soaking down, the groundwater below it going dark.
class M7SliceCard extends StatelessWidget {
  const M7SliceCard({super.key});

  @override
  Widget build(BuildContext context) => const CustomPaint(painter: _SlicePainter());
}

class _SlicePainter extends CustomPainter {
  const _SlicePainter();

  @override
  void paint(Canvas c, Size size) {
    final r = Offset.zero & size;
    final clip = RRect.fromRectAndRadius(r, const Radius.circular(12));
    c.save();
    c.clipRRect(clip);
    c.drawRect(r, Paint()..color = const Color(0xFFF7F1DE));
    c.drawRect(Rect.fromLTWH(0, 0, size.width, size.height * 0.18), Paint()..color = const Color(0xFFBBD8EE));
    c.drawRect(Rect.fromLTWH(0, size.height * 0.18, size.width, size.height * 0.32), Paint()..color = const Color(0xFF9B7D52));
    c.drawRect(Rect.fromLTWH(0, size.height * 0.5, size.width, size.height * 0.2), Paint()..color = const Color(0xFF7D6440));
    c.drawRect(Rect.fromLTWH(0, size.height * 0.7, size.width, size.height * 0.3), Paint()..color = const Color(0xFF3C7FB0));
    final oil = Paint()..color = _oil;
    // A pool on top, a stream down, a dark stain in the water.
    c.drawOval(Rect.fromCenter(center: Offset(size.width * 0.5, size.height * 0.2), width: 70, height: 12), oil);
    c.drawRect(Rect.fromLTWH(size.width * 0.5 - 4, size.height * 0.2, 8, size.height * 0.5), oil..color = _oil.withValues(alpha: 0.9));
    c.drawOval(Rect.fromCenter(center: Offset(size.width * 0.5, size.height * 0.78), width: 120, height: 34), Paint()..color = _oil.withValues(alpha: 0.55));
    c.restore();
    c.drawRRect(
        clip,
        Paint()
          ..color = const Color(0xFFC48A2E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);
  }

  @override
  bool shouldRepaint(_SlicePainter old) => false;
}
