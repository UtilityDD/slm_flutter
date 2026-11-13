import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/en_digits.dart';
import '../../core/theme/app_theme.dart';
import 'pole_read.dart' show PoleCase, PoleDefect, PoleFlaw, PoleKind, PoleSide;
import 'pole_yard.dart';

// The drawn world of the Module 1 rank gate (step 30, gate_watch.dart): one
// job, two places — beside the van (VanYardPainter, close: the crew dresses
// and checks the kit) and at pole 17 on the village roadside (PoleYardPainter
// + PolePainter, with a camera that zooms on the pole's foot or top). The
// crew (a lead and two linemen) are drawn here in code, big enough that what
// they wear and hold reads on a 360 dp phone. Nothing in the art names or
// rings a fault: the cue is only what a watcher would see (or hear).
//
// Everything is in design pixels: the van world and the pole world are 360 ×
// the scene's height (FullSceneFrame); [GateCam] maps the pole world to the
// screen. [gateZones] gives each fault's tap area at moment time t; the
// painters draw from the same geometry.

// ============================================================================
// What can happen (the job's order)
// ============================================================================

/// One step of the job, in the job's order (the deal keeps this order).
enum GateSlot { helmet, shirt, boots, gloves, kite, permit, rod, harness, poleCheck, discharge, anchor, sky, fire, clear }

/// A fault a crew member makes in a moment (null on a moment done right).
enum GateFault {
  vented,
  strapOpen,
  polyester,
  sleeves,
  nail,
  pinhole,
  cotton,
  bamboo,
  pvcHook,
  phonePermit,
  wrongFeeder,
  wrongRating,
  jugaadRod,
  waistBelt,
  chestHigh,
  skipCheck,
  hollow,
  hive,
  lineFirst,
  skipDischarge,
  brokenArm,
  lightning,
  waterFire,
  keptPermit,
}

extension GateFaultSlot on GateFault {
  GateSlot get slot => switch (this) {
        GateFault.vented || GateFault.strapOpen => GateSlot.helmet,
        GateFault.polyester || GateFault.sleeves => GateSlot.shirt,
        GateFault.nail => GateSlot.boots,
        GateFault.pinhole || GateFault.cotton => GateSlot.gloves,
        GateFault.bamboo || GateFault.pvcHook => GateSlot.kite,
        GateFault.phonePermit || GateFault.wrongFeeder => GateSlot.permit,
        GateFault.wrongRating || GateFault.jugaadRod => GateSlot.rod,
        GateFault.waistBelt || GateFault.chestHigh => GateSlot.harness,
        GateFault.skipCheck || GateFault.hollow || GateFault.hive => GateSlot.poleCheck,
        GateFault.lineFirst || GateFault.skipDischarge => GateSlot.discharge,
        GateFault.brokenArm => GateSlot.anchor,
        GateFault.lightning => GateSlot.sky,
        GateFault.waterFire => GateSlot.fire,
        GateFault.keptPermit => GateSlot.clear,
      };
}

/// Where the camera is for a moment.
enum GateSpot { van, wide, base, top }

extension GateSlotSpot on GateSlot {
  GateSpot get spot => switch (this) {
        GateSlot.helmet || GateSlot.shirt || GateSlot.boots || GateSlot.gloves || GateSlot.clear => GateSpot.van,
        GateSlot.permit || GateSlot.rod || GateSlot.harness => GateSpot.base,
        GateSlot.anchor || GateSlot.sky => GateSpot.top,
        _ => GateSpot.wide,
      };

  bool get atVan => spot == GateSpot.van;

  /// How long the moment plays (ms) — the same as a still under reduced motion.
  int get ms => switch (this) {
        GateSlot.poleCheck || GateSlot.discharge => 5600,
        GateSlot.sky || GateSlot.fire || GateSlot.kite => 5000,
        _ => 4600,
      };

  /// The still shown under reduced motion (the cue in view).
  double get stillT => switch (this) {
        GateSlot.helmet => 0.8,
        GateSlot.gloves => 0.55,
        GateSlot.boots => 0.5,
        GateSlot.poleCheck => 0.55,
        GateSlot.discharge => 0.62,
        GateSlot.sky => 0.5,
        GateSlot.fire => 0.65,
        _ => 0.6,
      };
}

/// What the painters need to draw a moment at time [t] (0 → 1).
@immutable
class GateShot {
  const GateShot({
    required this.slot,
    required this.fault,
    required this.t,
    required this.kv,
    required this.feeder,
    required this.permitFeeder,
    required this.poleNo,
    this.swap = false,
    this.gone = false,
  });

  final GateSlot slot;
  final GateFault? fault;
  final double t;

  /// The docket's line voltage (11 or 33).
  final int kv;

  /// The docket's feeder (on the pole's tag) and the one on the permit.
  final String feeder;
  final String permitFeeder;
  final int poleNo;

  /// Swap the two linemen's looks (who does the work, dealt).
  final bool swap;

  /// The worker has fallen (a missed fall plays out): not drawn in place.
  final bool gone;

  bool get right => fault == null;

  @override
  bool operator ==(Object other) =>
      other is GateShot &&
      other.slot == slot &&
      other.fault == fault &&
      other.t == t &&
      other.kv == kv &&
      other.feeder == feeder &&
      other.permitFeeder == permitFeeder &&
      other.poleNo == poleNo &&
      other.swap == swap &&
      other.gone == gone;

  @override
  int get hashCode => Object.hash(slot, fault, t, kv, feeder, permitFeeder, poleNo, swap, gone);
}

// ============================================================================
// Geometry and camera
// ============================================================================

/// Where things stand (design px) for a scene of height [h].
@immutable
class GateGeo {
  GateGeo(this.h, this.inset) : pole = PoleGeo.forScene(h, inset);
  final double h;
  final double inset;
  final PoleGeo pole;

  double get ground => pole.groundY;
  double get ppm => pole.ppm;
  double get cx => PoleGeo.cx;
  double y(double m) => pole.y(m);

  /// A crew member in the pole world (1.75 m).
  double get man => 1.75 * ppm;

  /// Beside the van: where the feet stand, and the crew's height (close up).
  double get vanFeet => h - 128 - inset;
  double get vanMan => math.min(0.5 * h, vanFeet - 176);

  /// The right cross-arm conductor's seat, and the top one (approximate,
  /// from PolePainter's porcelain pins).
  Offset get wireRight => Offset(cx + 64 * pole.s, y(8.4) - 18 * pole.s);
  Offset get wireTop => Offset(cx, pole.topY - 18 * pole.s);
  Offset get wireLeft => Offset(cx - 64 * pole.s, y(8.4) - 18 * pole.s);

  /// The right conductor's height at [x] (its sag to the scene's edge).
  double wireYAt(double x) {
    final p0 = wireRight;
    final x2 = cx + 400;
    final u = ((x - p0.dx) / (x2 - p0.dx)).clamp(0.0, 1.0);
    final ctl = p0.dy + 16;
    final end = p0.dy + 4;
    return (1 - u) * (1 - u) * p0.dy + 2 * (1 - u) * u * ctl + u * u * end;
  }

  @override
  bool operator ==(Object other) => other is GateGeo && other.h == h && other.inset == inset;

  @override
  int get hashCode => Object.hash(h, inset);
}

/// The camera on the pole world: [focus] (a world point) sits at the screen's
/// centre, the world [scale]d. Identity for the wide view and the van.
@immutable
class GateCam {
  const GateCam(this.scale, this.focus);
  final double scale;
  final Offset focus;

  static GateCam lerp(GateCam a, GateCam b, double t) =>
      GateCam(a.scale + (b.scale - a.scale) * t, Offset.lerp(a.focus, b.focus, t)!);

  Offset centre(double h) => Offset(180, h / 2);
  Offset toScreen(Offset w, double h) => (w - focus) * scale + centre(h);
  Offset toWorld(Offset s, double h) => (s - centre(h)) / scale + focus;
  Rect rectToScreen(Rect r, double h) => Rect.fromPoints(toScreen(r.topLeft, h), toScreen(r.bottomRight, h));

  Matrix4 matrix(double h) {
    final c = centre(h);
    return Matrix4.identity()
      ..translateByDouble(c.dx, c.dy, 0, 1)
      ..scaleByDouble(scale, scale, 1, 1)
      ..translateByDouble(-focus.dx, -focus.dy, 0, 1);
  }

  @override
  bool operator ==(Object other) => other is GateCam && other.scale == scale && other.focus == focus;

  @override
  int get hashCode => Object.hash(scale, focus);
}

/// The camera for [slot] (kept inside the world, so no edge shows).
GateCam gateCamFor(GateSlot slot, GateGeo g) {
  GateCam clamp(double s, Offset f) {
    final hw = 180 / s;
    final hh = g.h / 2 / s;
    return GateCam(s, Offset(f.dx.clamp(hw, 360 - hw), f.dy.clamp(hh, g.h - hh)));
  }

  if (slot == GateSlot.kite) return clamp(1.5, Offset(g.cx + 120, g.y(3.8)));
  if (slot == GateSlot.fire) return clamp(1.7, Offset(g.cx + 110, g.y(1.6)));
  // The discharge: close enough that the earth clamp (on the spike, or still
  // loose on the ground) reads, with the line and the rod's hook in view.
  if (slot == GateSlot.discharge) return clamp(1.45, Offset(g.cx + 26, g.y(4.2)));
  return switch (slot.spot) {
    GateSpot.van || GateSpot.wide => GateCam(1, Offset(180, g.h / 2)),
    GateSpot.base => switch (slot) {
        GateSlot.permit => clamp(2.2, Offset(g.cx + 44, g.ground - 1.3 * g.ppm)),
        GateSlot.harness => clamp(2.6, Offset(g.cx + 58, g.ground - 1.05 * g.ppm)),
        _ => clamp(2.0, Offset(g.cx + 64, g.ground - 1.3 * g.ppm)),
      },
    GateSpot.top => clamp(1.9, Offset(g.cx + 14, g.y(7.7))),
  };
}

// ============================================================================
// The crew
// ============================================================================

enum CrewHelmet { solid, vented }

enum CrewShirt { cotton, jersey, rolled }

enum CrewGloves { bare, rubber, cotton }

enum CrewHarness { none, full, belt, chestHigh }

@immutable
class CrewLook {
  const CrewLook({required this.helmet, required this.shirt, required this.pants, this.skin = const Color(0xFFA86E48), this.moustache = false});
  final Color helmet;
  final Color shirt;
  final Color pants;
  final Color skin;
  final bool moustache;

  /// The crew lead (white helmet, blue shirt) and the two linemen.
  static const lead = CrewLook(helmet: Color(0xFFF4F4EE), shirt: Color(0xFF3E6E9E), pants: Color(0xFF2B3440), skin: Color(0xFF9C6440), moustache: true);
  static const a = CrewLook(helmet: Color(0xFFFFD34E), shirt: Color(0xFFD9CBA3), pants: Color(0xFF39424E));
  static const b = CrewLook(helmet: Color(0xFFF08A24), shirt: Color(0xFFCDBF97), pants: Color(0xFF2E3742), skin: Color(0xFFB27A50));
}

@immutable
class CrewGear {
  const CrewGear({
    this.helmet = CrewHelmet.solid,
    this.strap = true,
    this.wearsHelmet = true,
    this.shirt = CrewShirt.cotton,
    this.gloves = CrewGloves.bare,
    this.harness = CrewHarness.none,
  });
  final CrewHelmet helmet;
  final bool strap;
  final bool wearsHelmet;
  final CrewShirt shirt;
  final CrewGloves gloves;
  final CrewHarness harness;
}

/// Limb angles (radians from straight down; + swings toward where he faces).
@immutable
class CrewPose {
  const CrewPose({
    this.armB = 0.12,
    this.foreB = 0.05,
    this.armF = -0.12,
    this.foreF = -0.05,
    this.thighB = 0.03,
    this.shinB = 0,
    this.thighF = -0.03,
    this.shinF = 0,
    this.lean = 0,
  });
  final double armB, foreB, armF, foreF, thighB, shinB, thighF, shinF, lean;

  static CrewPose lerp(CrewPose a, CrewPose b, double t) {
    double l(double x, double y) => x + (y - x) * t;
    return CrewPose(
      armB: l(a.armB, b.armB),
      foreB: l(a.foreB, b.foreB),
      armF: l(a.armF, b.armF),
      foreF: l(a.foreF, b.foreF),
      thighB: l(a.thighB, b.thighB),
      shinB: l(a.shinB, b.shinB),
      thighF: l(a.thighF, b.thighF),
      shinF: l(a.shinF, b.shinF),
      lean: l(a.lean, b.lean),
    );
  }

  static const stand = CrewPose();
  static const chest = CrewPose(armB: 0.45, foreB: 2.45, armF: 0.4, foreF: 2.5);
  static const head = CrewPose(armB: 2.5, foreB: 2.95, armF: 2.6, foreF: 3.0);
  static const chin = CrewPose(armB: 0.12, foreB: 0.05, armF: 0.75, foreF: 2.85);
  static const phone = CrewPose(armB: 0.4, foreB: 1.5, armF: 0.85, foreF: 2.95);
  static const hold = CrewPose(armB: 0.3, foreB: 1.55, armF: 0.25, foreF: 1.6);
  static const reach = CrewPose(armB: 2.6, foreB: 2.9, armF: 2.75, foreF: 3.0, lean: 0.05);
  static const sit = CrewPose(armB: 0.5, foreB: 2.3, armF: 0.45, foreF: 2.35, thighB: 1.45, shinB: 0.1, thighF: 1.4, shinF: 0.05);
  static const climbA = CrewPose(armB: 2.4, foreB: 2.75, armF: 2.8, foreF: 3.05, thighB: 0.35, shinB: -0.25, thighF: 1.05, shinF: 0.15, lean: 0.12);
  static const climbB = CrewPose(armB: 2.8, foreB: 3.05, armF: 2.4, foreF: 2.75, thighB: 1.05, shinB: 0.15, thighF: 0.35, shinF: -0.25, lean: 0.12);

  /// A walking step at phase [p] (0 → 1, one stride).
  static CrewPose walk(double p) {
    final s = math.sin(2 * math.pi * p);
    return CrewPose(
      armB: 0.1 + 0.3 * s,
      foreB: 0.2 + 0.3 * s,
      armF: -0.1 - 0.3 * s,
      foreF: 0.1 - 0.3 * s,
      thighB: -0.32 * s,
      shinB: -0.32 * s - 0.25 * math.max(0, -s),
      thighF: 0.32 * s,
      shinF: 0.32 * s - 0.25 * math.max(0, s),
    );
  }

  /// Climbing at phase [p] (hands and feet change over).
  static CrewPose climb(double p) => lerp(climbA, climbB, 0.5 - 0.5 * math.cos(2 * math.pi * p));
}

/// Where a figure's joints are (design px).
@immutable
class CrewJoints {
  const CrewJoints({
    required this.hip,
    required this.neck,
    required this.headC,
    required this.headR,
    required this.shoulder,
    required this.elbowB,
    required this.handB,
    required this.elbowF,
    required this.handF,
    required this.kneeB,
    required this.footB,
    required this.kneeF,
    required this.footF,
    required this.dir,
    required this.h,
  });
  final Offset hip, neck, headC, shoulder, elbowB, handB, elbowF, handF, kneeB, footB, kneeF, footF;
  final double headR;

  /// +1 faces right, −1 faces left.
  final double dir;

  /// The figure's standing height.
  final double h;

  /// Chest centre (where the chest strap belongs).
  Offset get chest => Offset.lerp(neck, hip, 0.38)!;
  Rect get body => Rect.fromPoints(neck - Offset(0.13 * h, 0), hip + Offset(0.13 * h, 0));
}

/// The joints of a figure [h] tall whose hip is at [hip].
CrewJoints crewJoints(Offset hip, double h, CrewPose p, {double dir = 1}) {
  Offset v(double a, double len) => Offset(math.sin(a) * dir, math.cos(a)) * len;
  final neck = hip + Offset(math.sin(p.lean) * dir, -math.cos(p.lean)) * (0.31 * h);
  final headC = neck + Offset(math.sin(p.lean) * dir * 0.6, -1) * (0.085 * h);
  final shoulder = neck + Offset(0, 0.025 * h);
  final elbowB = shoulder + v(p.armB, 0.17 * h);
  final elbowF = shoulder + v(p.armF, 0.17 * h);
  final kneeB = hip + v(p.thighB, 0.25 * h);
  final kneeF = hip + v(p.thighF, 0.25 * h);
  return CrewJoints(
    hip: hip,
    neck: neck,
    headC: headC,
    headR: 0.07 * h,
    shoulder: shoulder,
    elbowB: elbowB,
    handB: elbowB + v(p.foreB, 0.16 * h),
    elbowF: elbowF,
    handF: elbowF + v(p.foreF, 0.16 * h),
    kneeB: kneeB,
    footB: kneeB + v(p.shinB, 0.24 * h),
    kneeF: kneeF,
    footF: kneeF + v(p.shinF, 0.24 * h),
    dir: dir,
    h: h,
  );
}

/// The hip of a figure standing with its feet on [feetY] at [x].
Offset standHip(double x, double feetY, double h) => Offset(x, feetY - 0.49 * h);

Color _shade(Color c, double k) => Color.lerp(c, const Color(0xFF000000), k)!;

/// The chest strap's buckle (metal), big enough to read where it sits.
void _buckle(Canvas c, Offset at, double h) {
  final r = Rect.fromCenter(center: at, width: 0.05 * h, height: 0.042 * h);
  c.drawRect(r, Paint()..color = const Color(0xFFB8C0C8));
  c.drawRect(r, Paint()
    ..color = const Color(0xFF4A5058)
    ..style = PaintingStyle.stroke
    ..strokeWidth = math.max(0.8, 0.006 * h));
}

const _webbing = Color(0xFFF57C00);
const _rubber = Color(0xFFE3A21A);
const _cottonGlove = Color(0xFFEFEADC);
const _jersey = Color(0xFF1E7FD8);

/// Paints a crew member at [j].
void paintCrew(Canvas c, CrewJoints j, CrewLook look, CrewGear gear) {
  final h = j.h;
  final dir = j.dir;
  Paint limb(Color col, double w) => Paint()
    ..color = col
    ..strokeWidth = w
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  final line = Paint()
    ..color = const Color(0xFF1C222B)
    ..strokeWidth = math.max(1.0, 0.006 * h)
    ..style = PaintingStyle.stroke;

  void leg(Offset knee, Offset foot, bool back) {
    final col = back ? _shade(look.pants, 0.25) : look.pants;
    c.drawLine(j.hip, knee, limb(col, 0.09 * h));
    c.drawLine(knee, foot, limb(col, 0.08 * h));
    // The boot: toe toward where he faces.
    final boot = RRect.fromRectAndRadius(
      Rect.fromCenter(center: foot + Offset(0.03 * h * dir, 0.005 * h), width: 0.12 * h, height: 0.055 * h),
      Radius.circular(0.02 * h),
    );
    c.drawRRect(boot, Paint()..color = back ? const Color(0xFF241A12) : const Color(0xFF34261A));
    c.drawLine(Offset(boot.left, boot.bottom), Offset(boot.right, boot.bottom), limb(const Color(0xFF0E0B08), 0.012 * h));
  }

  void arm(Offset elbow, Offset hand, bool back) {
    final sh = back ? 0.22 : 0.0;
    final sleeve = gear.shirt == CrewShirt.jersey ? _jersey : look.shirt;
    final skin = _shade(look.skin, sh);
    if (gear.shirt == CrewShirt.jersey) {
      // Short sleeves: the jersey stops a third down the upper arm.
      final mid = Offset.lerp(j.shoulder, elbow, 0.45)!;
      c.drawLine(Offset.lerp(j.shoulder, elbow, 0.3)!, elbow, limb(skin, 0.05 * h));
      c.drawLine(elbow, hand, limb(skin, 0.048 * h));
      c.drawLine(j.shoulder, mid, limb(_shade(sleeve, sh), 0.07 * h));
    } else {
      c.drawLine(j.shoulder, elbow, limb(_shade(sleeve, sh), 0.065 * h));
      if (gear.shirt == CrewShirt.rolled) {
        c.drawLine(elbow, hand, limb(skin, 0.05 * h));
        // The rolled-up cuff, a thick band at the elbow.
        final e2 = Offset.lerp(elbow, hand, 0.12)!;
        c.drawLine(elbow, e2, limb(_shade(sleeve, sh + 0.12), 0.08 * h));
      } else {
        c.drawLine(elbow, hand, limb(_shade(sleeve, sh), 0.06 * h));
        final cuff = Offset.lerp(elbow, hand, 0.86)!;
        c.drawLine(cuff, Offset.lerp(elbow, hand, 0.95)!, limb(_shade(sleeve, sh + 0.2), 0.064 * h));
      }
    }
    switch (gear.gloves) {
      case CrewGloves.rubber:
        // A gauntlet: up the forearm, thick.
        c.drawLine(Offset.lerp(elbow, hand, 0.55)!, hand, limb(_shade(_rubber, sh), 0.07 * h));
        c.drawCircle(hand, 0.042 * h, Paint()..color = _shade(_rubber, sh));
      case CrewGloves.cotton:
        c.drawLine(Offset.lerp(elbow, hand, 0.82)!, hand, limb(_shade(_cottonGlove, sh), 0.064 * h));
        c.drawCircle(hand, 0.036 * h, Paint()..color = _shade(_cottonGlove, sh));
        final knit = Paint()..color = _shade(const Color(0xFFC9C2AE), sh);
        for (var k = 0; k < 5; k++) {
          c.drawCircle(hand + Offset(math.cos(k * 1.3), math.sin(k * 1.3)) * (0.018 * h), 0.004 * h, knit);
        }
      case CrewGloves.bare:
        c.drawCircle(hand, 0.03 * h, Paint()..color = skin);
    }
  }

  // Back limbs first.
  leg(j.kneeB, j.footB, true);
  arm(j.elbowB, j.handB, true);

  // Torso.
  final sw = 0.115 * h;
  final hw = 0.095 * h;
  final up = (j.neck - j.hip) / (j.neck - j.hip).distance;
  final side = Offset(-up.dy, up.dx);
  final torso = Path()
    ..moveTo(j.shoulder.dx + side.dx * sw, j.shoulder.dy + side.dy * sw)
    ..lineTo(j.shoulder.dx - side.dx * sw, j.shoulder.dy - side.dy * sw)
    ..lineTo(j.hip.dx - side.dx * hw, j.hip.dy - side.dy * hw)
    ..lineTo(j.hip.dx + side.dx * hw, j.hip.dy + side.dy * hw)
    ..close();
  final shirt = gear.shirt == CrewShirt.jersey ? _jersey : look.shirt;
  c.drawPath(torso, Paint()..color = shirt);
  if (gear.shirt == CrewShirt.jersey) {
    // Shiny synthetic: bright stripes and a glossy sheen.
    final clip = Path.from(torso);
    c.save();
    c.clipPath(clip);
    final stripe = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 0.022 * h;
    for (final k in const [-0.06, 0.06]) {
      c.drawLine(j.shoulder + side * (k * h) - up * (0.02 * h), j.hip + side * (k * h + 0.04 * h), stripe);
    }
    c.drawLine(Offset.lerp(j.shoulder, j.hip, 0.55)! - side * sw, Offset.lerp(j.shoulder, j.hip, 0.55)! + side * sw,
        Paint()
          ..color = const Color(0xFFFF5A3C)
          ..strokeWidth = 0.03 * h);
    c.drawOval(Rect.fromCenter(center: Offset.lerp(j.shoulder, j.hip, 0.3)! + side * (0.04 * h), width: 0.07 * h, height: 0.16 * h),
        Paint()..color = const Color(0x88FFFFFF));
    c.restore();
    // A round neck, no collar, no buttons.
    c.drawCircle(j.neck + Offset(0, 0.012 * h), 0.03 * h, Paint()..color = const Color(0xFF145FA8));
  } else {
    // Cotton shirt: collar, the button line, pocket.
    final placket = Paint()
      ..color = _shade(shirt, 0.25)
      ..strokeWidth = math.max(1.0, 0.008 * h);
    c.drawLine(j.neck + Offset(0, 0.03 * h), Offset.lerp(j.neck, j.hip, 0.95)!, placket);
    for (var k = 1; k <= 4; k++) {
      c.drawCircle(Offset.lerp(j.neck, j.hip, 0.12 + k * 0.18)!, 0.008 * h, Paint()..color = const Color(0xFFE9E2CF));
    }
    final collar = Path()
      ..moveTo(j.neck.dx - 0.05 * h, j.neck.dy)
      ..lineTo(j.neck.dx, j.neck.dy + 0.05 * h)
      ..lineTo(j.neck.dx + 0.05 * h, j.neck.dy)
      ..lineTo(j.neck.dx + 0.035 * h, j.neck.dy + 0.035 * h)
      ..lineTo(j.neck.dx, j.neck.dy + 0.05 * h)
      ..lineTo(j.neck.dx - 0.035 * h, j.neck.dy + 0.035 * h)
      ..close();
    c.drawPath(collar, Paint()..color = _shade(shirt, 0.18));
    c.drawRect(Rect.fromCenter(center: Offset.lerp(j.neck, j.hip, 0.3)! + side * (-0.055 * h * dir), width: 0.05 * h, height: 0.045 * h),
        Paint()
          ..color = _shade(shirt, 0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(1.0, 0.006 * h));
  }
  c.drawPath(torso, line);
  // Trouser belt.
  c.drawLine(j.hip - side * hw, j.hip + side * hw, limb(const Color(0xFF2A2018), 0.025 * h));

  // Harness or belt on top of the shirt.
  final webbing = limb(_webbing, 0.024 * h);
  final edge = limb(const Color(0xFF8A6A10), 0.03 * h);
  void strap(Offset a, Offset b) {
    c.drawLine(a, b, edge);
    c.drawLine(a, b, webbing);
  }

  switch (gear.harness) {
    case CrewHarness.full:
    case CrewHarness.chestHigh:
      final l0 = j.shoulder + side * (sw * 0.55);
      final r0 = j.shoulder - side * (sw * 0.55);
      final l1 = j.hip + side * (hw * 0.75);
      final r1 = j.hip - side * (hw * 0.75);
      strap(l0, l1);
      strap(r0, r1);
      // Chest strap: across the middle of the chest (worn right). Worn wrong
      // it rides up to the throat — drawn after the head, below.
      if (gear.harness == CrewHarness.full) {
        final cl = Offset.lerp(l0, l1, 0.42)!;
        final cr = Offset.lerp(r0, r1, 0.42)!;
        strap(cl, cr);
        _buckle(c, Offset.lerp(cl, cr, 0.5)!, h);
      }
      // Leg loops round the tops of the thighs.
      for (final knee in [j.kneeB, j.kneeF]) {
        final a = Offset.lerp(j.hip, knee, 0.25)!;
        c.drawCircle(a, 0.05 * h, edge..style = PaintingStyle.stroke);
        c.drawCircle(a, 0.05 * h, webbing..style = PaintingStyle.stroke);
      }
      strap(j.hip - side * hw, j.hip + side * hw);
    case CrewHarness.belt:
      // Only a waist belt, a ring on the side.
      c.drawLine(j.hip - side * (hw * 1.05), j.hip + side * (hw * 1.05), limb(const Color(0xFF5A3A1E), 0.05 * h));
      c.drawLine(j.hip - side * (hw * 1.05), j.hip + side * (hw * 1.05), limb(const Color(0xFF7A5230), 0.03 * h));
      c.drawCircle(j.hip + side * (hw * 0.95 * -dir), 0.028 * h,
          Paint()
            ..color = const Color(0xFFB8BEC4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.012 * h);
    case CrewHarness.none:
      break;
  }

  // Front leg.
  leg(j.kneeF, j.footF, false);

  // Neck and head.
  c.drawLine(j.neck, j.headC, limb(look.skin, 0.05 * h));
  c.drawCircle(j.headC, j.headR, Paint()..color = look.skin);
  c.drawCircle(j.headC + Offset(-0.045 * h * dir, 0.005 * h), 0.016 * h, Paint()..color = _shade(look.skin, 0.15));
  final eye = Paint()..color = const Color(0xFF1C1712);
  c.drawCircle(j.headC + Offset(0.03 * h * dir, -0.005 * h), 0.008 * h, eye);
  c.drawCircle(j.headC + Offset(0.058 * h * dir, -0.005 * h), 0.007 * h, eye);
  if (look.moustache) {
    c.drawLine(j.headC + Offset(0.022 * h * dir, 0.03 * h), j.headC + Offset(0.06 * h * dir, 0.028 * h), limb(const Color(0xFF2A1E16), 0.012 * h));
  }
  c.drawLine(j.headC + Offset(0.028 * h * dir, 0.045 * h), j.headC + Offset(0.052 * h * dir, 0.043 * h), limb(_shade(look.skin, 0.45), 0.006 * h));
  if (gear.wearsHelmet) paintHelmet(c, j.headC, j.headR, dir, look.helmet, gear.helmet, gear.strap);

  // Front arm last.
  arm(j.elbowF, j.handF, false);

  if (gear.harness == CrewHarness.chestHigh) {
    // The chest strap up at the throat: across the neck, above the shoulders,
    // tied into the shoulder straps (the chest itself bare of any strap);
    // over the arm's root so it always reads.
    final up2 = up * (0.012 * h);
    final tl = j.neck + side * (sw * 0.55) + up2;
    final tr = j.neck - side * (sw * 0.55) + up2;
    strap(j.shoulder + side * (sw * 0.55), tl);
    strap(j.shoulder - side * (sw * 0.55), tr);
    strap(tl, tr);
    _buckle(c, Offset.lerp(tl, tr, 0.5)!, h);
  }
}

/// A safety helmet on a head at [headC] (radius [r]); vented = air holes in
/// the shell; the chin strap fastened under the chin or hanging open.
void paintHelmet(Canvas c, Offset headC, double r, double dir, Color col, CrewHelmet kind, bool strap, {bool worn = true}) {
  final top = headC - Offset(0, r * 0.2);
  final dome = Rect.fromCenter(center: top, width: r * 2.5, height: r * 2.4);
  final shell = Path()
    ..addArc(dome, math.pi, math.pi)
    ..close();
  c.drawPath(shell, Paint()..color = col);
  c.drawArc(dome.deflate(r * 0.28), math.pi * 1.15, math.pi * 0.35, false,
      Paint()
        ..color = const Color(0x66FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.18
        ..strokeCap = StrokeCap.round);
  // Ridge and brim (the peak toward where he faces).
  c.drawLine(Offset(top.dx, dome.top + r * 0.1), Offset(top.dx, top.dy - r * 0.05),
      Paint()
        ..color = _shade(col, 0.12)
        ..strokeWidth = r * 0.16);
  final brim = RRect.fromRectAndRadius(
    Rect.fromLTRB(top.dx - r * 1.35 + (dir > 0 ? 0 : -r * 0.35), top.dy - r * 0.08, top.dx + r * 1.35 + (dir > 0 ? r * 0.35 : 0), top.dy + r * 0.2),
    Radius.circular(r * 0.14),
  );
  c.drawRRect(brim, Paint()..color = _shade(col, 0.1));
  if (kind == CrewHelmet.vented) {
    final hole = Paint()..color = const Color(0xFF1A1F26);
    for (final o in const [Offset(-0.62, -0.42), Offset(-0.12, -0.72), Offset(0.4, -0.55), Offset(0.78, -0.18)]) {
      c.save();
      c.translate(top.dx + o.dx * r, top.dy + o.dy * r);
      c.rotate(o.dx * 0.6);
      c.drawOval(Rect.fromCenter(center: Offset.zero, width: r * 0.42, height: r * 0.2), hole);
      c.restore();
    }
  }
  if (!worn) return;
  final band = Paint()
    ..color = const Color(0xFF2C2620)
    ..strokeWidth = math.max(1.4, r * 0.15)
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final earL = Offset(headC.dx - r * 0.9, top.dy + r * 0.15);
  final earR = Offset(headC.dx + r * 0.9, top.dy + r * 0.15);
  final chin = headC + Offset(r * 0.25 * dir, r * 1.08);
  if (strap) {
    c.drawPath(Path()..moveTo(earL.dx, earL.dy)..quadraticBezierTo(earL.dx, chin.dy, chin.dx, chin.dy)..quadraticBezierTo(earR.dx, chin.dy, earR.dx, earR.dy), band);
    c.drawRect(Rect.fromCenter(center: chin, width: r * 0.3, height: r * 0.22), Paint()..color = const Color(0xFF15110D));
  } else {
    // Open: both ends hang loose beside the jaw, the buckle swinging.
    final back = dir > 0 ? earL : earR;
    final front = dir > 0 ? earR : earL;
    c.drawLine(back, back + Offset(-r * 0.15 * dir, r * 1.4), band);
    c.drawLine(front, front + Offset(r * 0.25 * dir, r * 1.05), band);
    c.drawRect(Rect.fromCenter(center: back + Offset(-r * 0.15 * dir, r * 1.5), width: r * 0.3, height: r * 0.24), Paint()..color = const Color(0xFF15110D));
  }
}

// ============================================================================
// Speech and sounds over the scene (widgets on the page, never on the art)
// ============================================================================

/// A line said in the scene (a crew member's words) or a sound (a knock, a
/// hiss), anchored at a world point.
@immutable
class GateBubble {
  const GateBubble(this.at, this.text, {this.sound = false});
  final Offset at;
  final String text;
  final bool sound;
}

abstract final class GateSceneWords {
  // The crew lead's words (what a watcher would hear, never what is wrong).
  static const permitIn = 'পারমিট এসে গেছে — শুরু করো!';
  static const phoneSays = 'হ্যাঁ, লাইন বন্ধ — শুরু করো!';
  static const fiveMin = 'চলো, সোজা উঠে পড়ো!';
  static const earthFirst = 'আগে মাটি, তারপর লাইন।';
  static const clearCall = 'কন্ট্রোল রুম? কাজ শেষ — পারমিট ফেরত দিচ্ছি।';
  static const homeGo = 'চলো, সবাই গাড়িতে ওঠো!';
  static const powerOff = 'কন্ট্রোল রুম? এখানে আগুন — পাওয়ার বন্ধ করুন!';
  static const allFine = 'সব তো ঠিক ছিল!';

  // Sounds (only the sound, never its meaning) — lesson 1.3's knock words.
  static const solid = 'ঠক্ ঠক্';
  static const hollow = 'দপ্ দপ্';
  static const hiss = 'ফুস্…';
  static const thunder = 'গুড়ুম!';
}

/// What is said or heard in [s] now, if anything.
GateBubble? gateBubble(GateShot s, GateGeo g) {
  final t = s.t;
  switch (s.slot) {
    case GateSlot.permit:
      if (t < 0.12) return null;
      final lead = _leadPermit(s, g);
      return GateBubble(lead.headC - Offset(0, lead.headR * 1.6), s.fault == GateFault.phonePermit ? GateSceneWords.phoneSays : GateSceneWords.permitIn);
    case GateSlot.discharge:
      if (t < 0.08 || t > 0.7) return null;
      final lead = crewJoints(standHip(g.cx + 128, g.ground, g.man), g.man, CrewPose.stand, dir: -1);
      return GateBubble(lead.headC - Offset(0, lead.headR * 1.6), s.fault == GateFault.skipDischarge ? GateSceneWords.fiveMin : GateSceneWords.earthFirst);
    case GateSlot.clear:
      if (t < 0.1 || t > 0.85) return null;
      final lead = _leadClear(s, g);
      return GateBubble(lead.headC - Offset(0, lead.headR * 1.7), s.fault == GateFault.keptPermit ? GateSceneWords.homeGo : GateSceneWords.clearCall);
    case GateSlot.fire:
      if (s.fault != null || t < 0.12 || t > 0.8) return null;
      final lead = crewJoints(standHip(g.cx + 60, g.ground, g.man), g.man, CrewPose.phone, dir: 1);
      return GateBubble(lead.headC - Offset(0, lead.headR * 1.6), GateSceneWords.powerOff);
    case GateSlot.poleCheck:
      if (s.fault == GateFault.skipCheck) return null;
      if (t < 0.44 || t > 0.62) return null;
      return GateBubble(Offset(g.cx + 34, g.ground - 0.9 * g.ppm), s.fault == GateFault.hollow ? GateSceneWords.hollow : GateSceneWords.solid, sound: true);
    case GateSlot.gloves:
      if (s.fault != GateFault.pinhole || t < 0.42 || t > 0.66) return null;
      final j = _vanActor(s, g, _glovesPose(s));
      return GateBubble(_gloveAt(s, g, j) + Offset(g.vanMan * 0.1, -g.vanMan * 0.12), GateSceneWords.hiss, sound: true);
    case GateSlot.sky:
      if (t < 0.42 || t > 0.62) return null;
      return GateBubble(Offset(70, g.y(10.6)), GateSceneWords.thunder, sound: true);
    default:
      return null;
  }
}

// ============================================================================
// Where each fault is (tap zones), at moment time t
// ============================================================================

/// The tap areas of [s]'s fault (world px of its spot), generous for a finger.
List<Rect> gateZones(GateShot s, GateGeo g) {
  final f = s.fault;
  if (f == null) return const [];
  Rect pad(Rect r, [double k = 12]) => r.inflate(k);
  Rect around(Offset p, double w, double h) => Rect.fromCenter(center: p, width: w, height: h);
  final vm = g.vanMan;
  switch (f.slot) {
    case GateSlot.helmet:
      final j = _vanActor(s, g, _helmetPose(s));
      final at = _helmetAt(s, g, j);
      return [pad(around(at + Offset(0, f == GateFault.strapOpen ? vm * 0.05 : 0), vm * 0.3, vm * 0.32))];
    case GateSlot.shirt:
      final j = _vanActor(s, g, _shirtPose(s));
      if (f == GateFault.polyester) return [pad(Rect.fromPoints(j.neck - Offset(vm * 0.14, vm * 0.02), j.hip + Offset(vm * 0.14, 0)))];
      return [pad(Rect.fromPoints(j.elbowB, j.handB)), pad(Rect.fromPoints(j.elbowF, j.handF))];
    case GateSlot.boots:
      return [pad(_bootRect(s, g), 16)];
    case GateSlot.gloves:
      final j = _vanActor(s, g, _glovesPose(s));
      return [pad(around(_gloveAt(s, g, j), vm * 0.26, vm * 0.26)), pad(around(j.handF, vm * 0.12, vm * 0.12)), pad(around(j.handB, vm * 0.12, vm * 0.12))];
    case GateSlot.kite:
      final (hand, tip) = _kiteStick(s, g);
      return [pad(Rect.fromPoints(Offset.lerp(hand, tip, 0.3)!, tip), 18), pad(around(_kiteRest(g), 34, 44))];
    case GateSlot.permit:
      final lead = _leadPermit(s, g);
      if (f == GateFault.phonePermit) return [pad(around(lead.handF, 26, 26)), pad(around(lead.headC, lead.headR * 3, lead.headR * 3))];
      return [pad(_clipboard(lead, g), 8)];
    case GateSlot.rod:
      final j = _rodActor(s, g);
      final (lo, hi) = _rodEnds(s, g, j);
      return [pad(Rect.fromPoints(lo, hi), 10)];
    case GateSlot.harness:
      final j = _harnessActor(s, g);
      return [pad(Rect.fromPoints(j.neck - Offset(g.man * 0.16, g.man * 0.04), j.hip + Offset(g.man * 0.16, g.man * 0.08)), 6)];
    case GateSlot.poleCheck:
      if (f == GateFault.hive) return [pad(Rect.fromLTRB(g.cx - 34 * g.pole.s, g.y(9.3), g.cx + 34 * g.pole.s, g.y(7.6)), 10)];
      final j = _poleCheckActor(s, g).$1;
      final base = Rect.fromLTRB(g.cx - 26, g.y(1.8), g.cx + 26, g.ground + 6);
      return [pad(j.body.expandToInclude(Rect.fromPoints(j.footF, j.headC)), 8), pad(base, 6)];
    case GateSlot.discharge:
      final (a, rod) = _dischargeRig(s, g);
      if (f == GateFault.lineFirst) {
        return [pad(around(rod.$2, 36, 36)), pad(around(_clampAt(s, g), 34, 26)), pad(around(Offset(g.cx + 55, g.ground - 8), 30, 30))];
      }
      return [pad(a.body.expandToInclude(Rect.fromPoints(a.handF, a.headC)), 10), pad(around(Offset(g.cx + 72, g.ground - 4), 60, 22))];
    case GateSlot.anchor:
      final (hook, _) = _anchorLine(s, g);
      return [pad(around(hook, 34, 30)), pad(Rect.fromLTRB(g.cx, g.y(8.4) - 12, g.cx + 70 * g.pole.s, g.y(8.4) + 26), 6)];
    case GateSlot.sky:
      final j = _skyActor(s, g);
      return [pad(j.body.expandToInclude(Rect.fromPoints(j.handF, j.headC)), 14), pad(Rect.fromLTRB(16, g.y(12.2), 120, g.y(6.2)))];
    case GateSlot.fire:
      final b = _fireActor(s, g);
      return [pad(around(b.handF, 40, 40)), pad(_boxRect(g).inflate(10)), pad(Rect.fromPoints(b.handF, _boxRect(g).center), 6)];
    case GateSlot.clear:
      final lead = _leadClear(s, g);
      return [pad(Rect.fromPoints(lead.neck - Offset(vm * 0.18, 0), lead.hip + Offset(vm * 0.2, vm * 0.05)))];
  }
}

/// Wide areas the "look everywhere" gesture hint sweeps over for [spot]
/// (the same set whatever the fault — never pointing at one).
List<Rect> gateLookAreas(GateSpot spot, GateGeo g) {
  final h = g.h;
  return switch (spot) {
    GateSpot.van => [
        Rect.fromLTWH(60, h * 0.36, 130, 90),
        Rect.fromLTWH(60, h * 0.5, 130, 90),
        Rect.fromLTWH(200, h * 0.48, 120, 90),
        Rect.fromLTWH(60, h * 0.66, 160, 70),
      ],
    _ => [
        Rect.fromLTWH(40, h * 0.22, 150, 90),
        Rect.fromLTWH(190, h * 0.3, 140, 90),
        Rect.fromLTWH(40, h * 0.55, 150, 90),
        Rect.fromLTWH(190, h * 0.6, 120, 80),
      ],
  };
}

// ============================================================================
// Each moment's actors (shared by the painter and the zones)
// ============================================================================

double _seg(double t, double a, double b) => ((t - a) / (b - a)).clamp(0.0, 1.0);
double _ease(double x) => Curves.easeInOut.transform(x.clamp(0.0, 1.0));

CrewLook _lineman(GateShot s, {bool other = false}) => (s.swap != other) ? CrewLook.b : CrewLook.a;

/// The lineman who does the work in [s] (his look, for the consequence).
CrewLook gateActorLook(GateShot s) => _lineman(s);

CrewJoints _vanActor(GateShot s, GateGeo g, CrewPose p) {
  final vm = g.vanMan;
  return crewJoints(standHip(118, g.vanFeet, vm), vm, p, dir: 1);
}

CrewPose _helmetPose(GateShot s) {
  final t = s.t;
  if (t < 0.4) return CrewPose.lerp(CrewPose.chest, CrewPose.head, _ease(_seg(t, 0.05, 0.36)));
  if (s.fault == GateFault.strapOpen) return CrewPose.lerp(CrewPose.head, CrewPose.stand, _ease(_seg(t, 0.42, 0.62)));
  if (t < 0.75) return CrewPose.lerp(CrewPose.head, CrewPose.chin, _ease(_seg(t, 0.42, 0.6)));
  return CrewPose.lerp(CrewPose.chin, CrewPose.stand, _ease(_seg(t, 0.78, 0.95)));
}

/// The helmet: in his hands until 0.38, then on his head.
Offset _helmetAt(GateShot s, GateGeo g, CrewJoints j) {
  if (s.t < 0.38) return Offset.lerp(j.handB, j.handF, 0.5)! + Offset(0, -j.headR * 0.3);
  return j.headC;
}

CrewPose _shirtPose(GateShot s) {
  final t = s.t;
  if (s.fault == GateFault.sleeves) {
    // He rolls each sleeve up: arms bent in front.
    if (t < 0.7) return CrewPose.lerp(CrewPose.stand, const CrewPose(armB: 0.35, foreB: 1.3, armF: 0.3, foreF: 1.45), _ease(_seg(t, 0.05, 0.25)));
    return CrewPose.lerp(const CrewPose(armB: 0.35, foreB: 1.3, armF: 0.3, foreF: 1.45), CrewPose.stand, _ease(_seg(t, 0.72, 0.9)));
  }
  if (t < 0.7) {
    final k = _ease(_seg(t, 0.05, 0.22));
    final down = _seg(t, 0.22, 0.68);
    final p = CrewPose(armB: 0.45 - 0.15 * down, foreB: 2.45 - 0.5 * down, armF: 0.4 - 0.15 * down, foreF: 2.5 - 0.5 * down);
    return CrewPose.lerp(CrewPose.stand, p, k);
  }
  return CrewPose.lerp(const CrewPose(armB: 0.3, foreB: 1.95, armF: 0.25, foreF: 2.0), CrewPose.stand, _ease(_seg(t, 0.72, 0.9)));
}

CrewPose _glovesPose(GateShot s) {
  final t = s.t;
  if (t < 0.66) return CrewPose.lerp(CrewPose.stand, CrewPose.chest, _ease(_seg(t, 0.02, 0.14)));
  // Pulling the glove on: hands together low, then down.
  return CrewPose.lerp(const CrewPose(armB: 0.35, foreB: 1.7, armF: 0.3, foreF: 1.75), CrewPose.stand, _ease(_seg(t, 0.85, 1)));
}

/// The glove he holds up (inflated for the air test).
Offset _gloveAt(GateShot s, GateGeo g, CrewJoints j) => Offset.lerp(j.handB, j.handF, 0.5)! + Offset(j.h * 0.02, -j.h * 0.11);

double _gloveInflate(GateShot s) {
  if (s.fault == GateFault.cotton) return 0;
  final t = s.t;
  final up = _ease(_seg(t, 0.14, 0.4));
  if (s.fault == GateFault.pinhole) return up * (1 - _ease(_seg(t, 0.44, 0.64)));
  return up * (1 - _ease(_seg(t, 0.62, 0.7)));
}

Rect _bootRect(GateShot s, GateGeo g) {
  final vm = g.vanMan;
  final j = crewJoints(Offset(118, g.vanFeet - 0.3 * vm), vm, CrewPose.sit, dir: 1);
  final held = Offset.lerp(j.handB, j.handF, 0.5)! + Offset(vm * 0.05, -vm * 0.04);
  final down = _ease(_seg(s.t, 0.66, 0.92));
  final at = Offset.lerp(held, j.footF, down)!;
  final w = vm * (0.14 - 0.05 * down);
  final h = vm * (0.3 - 0.2 * down);
  return Rect.fromCenter(center: at, width: w, height: h);
}

CrewJoints _leadClear(GateShot s, GateGeo g) {
  final vm = g.vanMan;
  final t = s.t;
  final CrewPose p;
  if (s.fault == GateFault.keptPermit) {
    // The permit goes into his shirt pocket; he waves them to the van.
    p = t < 0.55 ? CrewPose.lerp(CrewPose.hold, const CrewPose(armB: 0.1, foreB: 0.05, armF: 0.3, foreF: 2.6), _ease(_seg(t, 0.25, 0.5))) : CrewPose.lerp(CrewPose.stand, const CrewPose(armB: 0.1, foreB: 0.05, armF: 2.2, foreF: 2.6), 0.5 + 0.5 * math.sin(t * 18));
  } else {
    p = CrewPose.lerp(CrewPose.hold, const CrewPose(armB: 0.3, foreB: 1.55, armF: 0.85, foreF: 2.95), _ease(_seg(t, 0.05, 0.2)));
  }
  return crewJoints(standHip(104, g.vanFeet, vm), vm, p, dir: 1);
}

/// Where the permit paper is in the clear moment (null: in his pocket).
Rect? _clearPaper(GateShot s, GateGeo g, CrewJoints lead) {
  final vm = g.vanMan;
  if (s.fault == GateFault.keptPermit) {
    final k = _ease(_seg(s.t, 0.25, 0.5));
    if (k >= 1) return null;
    final from = lead.handB + Offset(vm * 0.04, -vm * 0.02);
    final to = Offset.lerp(lead.neck, lead.hip, 0.3)! + Offset(vm * 0.055, 0);
    final c = Offset.lerp(from, to, k)!;
    return Rect.fromCenter(center: c, width: vm * (0.16 - 0.1 * k), height: vm * (0.2 - 0.13 * k));
  }
  return Rect.fromCenter(center: lead.handB + Offset(vm * 0.06, -vm * 0.02), width: vm * 0.16, height: vm * 0.2);
}

CrewJoints _leadPermit(GateShot s, GateGeo g) {
  final p = s.fault == GateFault.phonePermit
      ? CrewPose.lerp(CrewPose.stand, CrewPose.phone, _ease(_seg(s.t, 0.02, 0.15)))
      : CrewPose.lerp(CrewPose.stand, CrewPose.hold, _ease(_seg(s.t, 0.02, 0.15)));
  return crewJoints(standHip(g.cx + 86, g.ground, g.man), g.man, p, dir: -1);
}

/// The permit on its clipboard in the lead's hands (big enough to read).
Rect _clipboard(CrewJoints lead, GateGeo g) {
  final c = Offset.lerp(lead.handB, lead.handF, 0.5)! + Offset(0, -g.man * 0.12);
  return Rect.fromCenter(center: c, width: g.man * 0.56, height: g.man * 0.5);
}

(Offset, Offset) _kiteStick(GateShot s, GateGeo g) {
  final j = _kiteActor(s, g);
  final hand = j.handF;
  final kite = _kiteRest(g);
  // The stick's tip rises from beside him to the kite in the tree (the same
  // reach with every tool: what is wrong is the tool, never the reach).
  final target = kite + const Offset(-4, 10);
  final start = hand + Offset(0.3 * g.ppm, -2.6 * g.ppm);
  final k = _ease(_seg(s.t, 0.08, 0.56));
  var tip = Offset.lerp(start, target, k)!;
  if (s.t > 0.56 && s.t < 0.74) tip += Offset(math.sin(s.t * 40) * 2.5, math.cos(s.t * 34) * 2);
  if (s.t >= 0.74 && s.fault == null) tip = Offset.lerp(target, start, _ease(_seg(s.t, 0.74, 0.95)))!;
  return (hand, tip);
}

CrewJoints _kiteActor(GateShot s, GateGeo g) => crewJoints(
      standHip(g.cx + 74, g.ground, g.man),
      g.man,
      CrewPose.lerp(CrewPose.stand, const CrewPose(armB: 1.6, foreB: 2.2, armF: 2.0, foreF: 2.5, lean: 0.04), _ease(_seg(s.t, 0.02, 0.2))),
      dir: 1,
    );

/// The tree beside the pole: trunk foot and crown centre (the kite is caught
/// in it, well below the line — as in lesson 1.2's long-tool task).
Offset _treeFoot(GateGeo g) => Offset(g.cx + 186, g.ground);
Offset _treeCrown(GateGeo g) => Offset(g.cx + 186, g.y(4.9));

/// Where the kite is caught.
Offset _kiteRest(GateGeo g) => Offset(g.cx + 150, g.y(4.7));

/// The kite now: in the tree, or (done right) freed and falling to his feet.
Offset _kiteAt(GateShot s, GateGeo g) {
  final rest = _kiteRest(g);
  if (s.fault != null || s.t < 0.74) return rest;
  final fall = _ease(_seg(s.t, 0.76, 0.98));
  return Offset.lerp(rest, Offset(g.cx + 120, g.ground - 0.3 * g.ppm), fall)!;
}

CrewJoints _rodActor(GateShot s, GateGeo g) =>
    crewJoints(standHip(g.cx + 64, g.ground, g.man), g.man, CrewPose.lerp(CrewPose.stand, const CrewPose(armB: 0.6, foreB: 1.4, armF: 0.45, foreF: 1.2), _ease(_seg(s.t, 0.05, 0.35))), dir: 1);

/// The rod's foot and head: lifted from the ground, then held upright.
(Offset, Offset) _rodEnds(GateShot s, GateGeo g, CrewJoints j) {
  final up = _ease(_seg(s.t, 0.08, 0.4));
  final grip = Offset.lerp(j.handB, j.handF, 0.5)!;
  final len = 3.4 * g.ppm;
  final ang = (1 - up) * 1.35; // from lying (≈ flat) to upright
  final dirV = Offset(math.sin(ang), -math.cos(ang));
  final lo = grip - dirV * (len * 0.3);
  final hi = grip + dirV * (len * 0.7);
  return (lo, hi);
}

CrewJoints _harnessActor(GateShot s, GateGeo g) {
  final t = s.t;
  // Tugging the straps tight (to 0.4), then the arms out of the way so the
  // fit is in plain view while it matters (stillT 0.6), then the reach.
  CrewPose tug(double t) {
    final k = 0.5 + 0.5 * math.sin(t * 22);
    return CrewPose(armB: 0.45, foreB: 2.3 + 0.2 * k, armF: 0.4, foreF: 2.4 + 0.2 * k);
  }

  // Hands on the hips: the chest and the throat clear of the arms.
  const clear = CrewPose(armB: -0.5, foreB: 0.6, armF: 0.5, foreF: -0.6);
  final CrewPose p;
  if (t < 0.4) {
    p = CrewPose.lerp(CrewPose.stand, tug(t), _ease(_seg(t, 0.04, 0.16)));
  } else if (t < 0.64) {
    p = CrewPose.lerp(tug(0.4), clear, _ease(_seg(t, 0.4, 0.5)));
  } else {
    p = CrewPose.lerp(clear, CrewPose.reach, _ease(_seg(t, 0.64, 0.86)));
  }
  return crewJoints(standHip(g.cx + 58, g.ground, g.man), g.man, p, dir: -1);
}

/// The pole check: (joints, behind the pole?).
(CrewJoints, bool) _poleCheckActor(GateShot s, GateGeo g) {
  final t = s.t;
  final m = g.man;
  final skip = s.fault == GateFault.skipCheck;
  final climbFrom = skip ? 0.32 : 0.66;
  if (t >= climbFrom) {
    final k = _seg(t, climbFrom, 1);
    final hip = Offset(g.cx + 26, g.ground - 0.49 * m - k * 2.6 * g.ppm);
    return (crewJoints(hip, m, CrewPose.climb(k * 2.2), dir: -1), false);
  }
  if (skip) {
    final x = g.cx + 150 - 124 * _ease(_seg(t, 0, 0.3));
    return (crewJoints(standHip(x, g.ground, m), m, CrewPose.walk(t * 3), dir: -1), false);
  }
  if (t < 0.2) {
    final x = g.cx + 150 - 110 * _ease(_seg(t, 0, 0.2));
    return (crewJoints(standHip(x, g.ground, m), m, CrewPose.walk(t * 4), dir: -1), false);
  }
  if (t < 0.31) {
    // Round the back of the pole (behind it), to the far side.
    final x = g.cx + 40 - 84 * _seg(t, 0.2, 0.31);
    return (crewJoints(standHip(x, g.ground - 4, m * 0.97), m * 0.97, CrewPose.walk(t * 5), dir: -1), true);
  }
  if (t < 0.42) {
    final x = g.cx - 44 + 78 * _seg(t, 0.31, 0.42);
    return (crewJoints(standHip(x, g.ground, m), m, CrewPose.walk(t * 5), dir: 1), false);
  }
  // Knocking at the foot with the hammer (two blows).
  final blow = 0.5 + 0.5 * math.cos((t - 0.42) / 0.12 * 2 * math.pi);
  return (
    crewJoints(standHip(g.cx + 36, g.ground, m), m, CrewPose(armB: 0.2, foreB: 0.4, armF: 0.6 + 0.5 * blow, foreF: 1.0 + 0.7 * blow, lean: 0.15), dir: -1),
    false,
  );
}

/// The discharge: the lineman on the pole with the rod (joints, (foot, head)).
(CrewJoints, (Offset, Offset)) _dischargeRig(GateShot s, GateGeo g) {
  final t = s.t;
  final m = g.man;
  final skip = s.fault == GateFault.skipDischarge;
  var hipM = 4.4;
  if (skip) hipM = 4.4 + 2.6 * _ease(_seg(t, 0.25, 0.7));
  final hip = Offset(g.cx + 24, g.y(hipM));
  final pose = skip
      ? (t < 0.7 ? CrewPose.climb(_seg(t, 0.25, 0.7) * 2) : CrewPose.lerp(CrewPose.climbA, const CrewPose(armB: 2.4, foreB: 2.75, armF: 2.3, foreF: 2.55, thighB: 0.35, shinB: -0.25, thighF: 1.05, shinF: 0.15, lean: 0.1), _ease(_seg(t, 0.72, 0.9))))
      : const CrewPose(armB: 2.3, foreB: 2.6, armF: 2.5, foreF: 2.75, thighB: 0.35, shinB: -0.25, thighF: 1.05, shinF: 0.15, lean: 0.1);
  final j = crewJoints(hip, m, pose, dir: 1);
  if (skip) {
    // The rod lies on the ground by the spike.
    return (j, (Offset(g.cx + 50, g.ground - 2), Offset(g.cx + 50 + 3.0 * g.ppm, g.ground - 6)));
  }
  final grip = j.handF;
  // Touches: R (right), then the top, then the left conductor.
  final right = g.wireRight;
  final topW = g.wireTop + const Offset(6, 0);
  final left = g.wireLeft + const Offset(8, 0);
  final lineFirst = s.fault == GateFault.lineFirst;
  final Offset head;
  if (lineFirst) {
    final k = _ease(_seg(t, 0.06, 0.24));
    final rest = grip + Offset(0.9 * g.ppm, -2.4 * g.ppm);
    head = Offset.lerp(rest, right + const Offset(0, -2), k)!;
  } else {
    final rest = grip + Offset(0.9 * g.ppm, -2.4 * g.ppm);
    if (t < 0.42) {
      head = rest;
    } else if (t < 0.56) {
      head = Offset.lerp(rest, right + const Offset(0, -2), _ease(_seg(t, 0.42, 0.52)))!;
    } else if (t < 0.72) {
      head = Offset.lerp(right + const Offset(0, -2), topW, _ease(_seg(t, 0.58, 0.68)))!;
    } else {
      head = Offset.lerp(topW, left, _ease(_seg(t, 0.74, 0.86)))!;
    }
  }
  final d = head - grip;
  final foot = grip - d / d.distance * (0.7 * g.ppm);
  return (j, (foot, head));
}

/// Where the rod's earth clamp is: on the ground by the helper, or on the spike.
Offset _clampAt(GateShot s, GateGeo g) {
  final spike = Offset(g.cx + 55, g.ground - 0.42 * g.ppm);
  final loose = Offset(g.cx + 92, g.ground - 3);
  final k = s.fault == GateFault.lineFirst ? _ease(_seg(s.t, 0.62, 0.82)) : _ease(_seg(s.t, 0.1, 0.34));
  return Offset.lerp(loose, spike, k)!;
}

(Offset, bool) _anchorLine(GateShot s, GateGeo g) {
  // The hook goes out to its anchor: round the pole (a sling) or the arm's end.
  final j = _anchorActor(s, g);
  final bad = s.fault == GateFault.brokenArm;
  final target = bad ? Offset(g.cx + 52 * g.pole.s, g.y(8.4) + 2) : Offset(g.cx + 2, g.y(8.75));
  final k = _ease(_seg(s.t, 0.1, 0.42));
  return (Offset.lerp(j.handF, target, k)!, k >= 1);
}

CrewJoints _anchorActor(GateShot s, GateGeo g) {
  final lean = _ease(_seg(s.t, 0.5, 0.7)) * 0.12;
  final p = s.t < 0.45
      ? CrewPose.lerp(CrewPose.climbA, const CrewPose(armB: 2.4, foreB: 2.75, armF: 1.9, foreF: 2.2, thighB: 0.35, shinB: -0.25, thighF: 1.05, shinF: 0.15, lean: 0.1), _ease(_seg(s.t, 0.05, 0.2)))
      : CrewPose(armB: 2.4, foreB: 2.75, armF: 2.2, foreF: 2.5, thighB: 0.35, shinB: -0.25, thighF: 1.05, shinF: 0.15, lean: 0.1 - lean);
  return crewJoints(Offset(g.cx + 24, g.y(6.9)), g.man, p, dir: -1);
}

CrewJoints _skyActor(GateShot s, GateGeo g) {
  final t = s.t;
  var hipM = 6.9;
  CrewPose p = CrewPose(armB: 2.4, foreB: 2.75, armF: 2.5 + 0.15 * math.sin(t * 20), foreF: 2.8, thighB: 0.35, shinB: -0.25, thighF: 1.05, shinF: 0.15, lean: 0.1);
  if (s.fault == null && t > 0.52) {
    final k = _seg(t, 0.52, 1);
    hipM = 6.9 - 3.4 * k;
    p = CrewPose.climb(k * 2.4);
  }
  return crewJoints(Offset(g.cx + 24, g.y(hipM)), g.man, p, dir: -1);
}

Rect _boxRect(GateGeo g) => Rect.fromLTWH(g.cx + 160, g.ground - 1.55 * g.ppm, 0.75 * g.ppm, 0.8 * g.ppm);

CrewJoints _fireActor(GateShot s, GateGeo g) {
  final t = s.t;
  final water = s.fault == GateFault.waterFire;
  final CrewPose p;
  if (water) {
    // The bucket swung back, then forward.
    final back = _ease(_seg(t, 0.2, 0.45));
    final fwd = _ease(_seg(t, 0.48, 0.6));
    p = CrewPose(armB: 0.2 - 0.9 * back + 2.0 * fwd, foreB: 0.1 - 0.9 * back + 2.0 * fwd, armF: 0.2 - 0.9 * back + 2.0 * fwd, foreF: 0.3 - 0.9 * back + 1.9 * fwd, lean: 0.12 * fwd);
  } else {
    p = CrewPose.lerp(CrewPose.stand, const CrewPose(armB: 0.6, foreB: 1.3, armF: 0.9, foreF: 1.45, lean: 0.05), _ease(_seg(t, 0.15, 0.4)));
  }
  final x = g.cx + 108 + 14 * _ease(_seg(t, 0, 0.2));
  return crewJoints(standHip(x, g.ground, g.man), g.man, p, dir: 1);
}

// ============================================================================
// Painters
// ============================================================================

/// The pole for [s] (PolePainter): a sound PCC pole, the hive or the loose
/// cross-arm only in their moments.
PoleCase gatePoleFor(GateShot? s) {
  final flaws = <PoleFlaw>[
    if (s?.fault == GateFault.hive) const PoleFlaw(PoleDefect.hive, PoleSide.front),
    if (s?.fault == GateFault.brokenArm) const PoleFlaw(PoleDefect.crossArm, PoleSide.front),
  ];
  return PoleCase(id: 'gate-${flaws.length}-${s?.fault?.name}', kind: PoleKind.pcc, flaws: flaws);
}

enum GateLayer { back, front }

/// The crew and props of a pole-world moment. [layer] back = behind the pole.
class GatePolePainter extends CustomPainter {
  const GatePolePainter({required this.shot, required this.geo, required this.layer});
  final GateShot shot;
  final GateGeo geo;
  final GateLayer layer;

  @override
  void paint(Canvas c, Size size) {
    final s = shot;
    final g = geo;
    if (layer == GateLayer.back) {
      if (s.slot == GateSlot.sky) _storm(c);
      if (s.slot == GateSlot.poleCheck) {
        final (j, behind) = _poleCheckActor(s, g);
        if (behind && !s.gone) paintCrew(c, j, _lineman(s), const CrewGear(gloves: CrewGloves.rubber, harness: CrewHarness.full));
      }
      return;
    }
    _tag(c);
    switch (s.slot) {
      case GateSlot.kite:
        _kite(c);
      case GateSlot.permit:
        _permit(c);
      case GateSlot.rod:
        _rod(c);
      case GateSlot.harness:
        _harness(c);
      case GateSlot.poleCheck:
        _poleCheck(c);
      case GateSlot.discharge:
        _discharge(c);
      case GateSlot.anchor:
        _anchor(c);
      case GateSlot.sky:
        final j = _skyActor(s, g);
        _lanyardTo(c, j, Offset(g.cx + 2, g.y(8.75)));
        paintCrew(c, j, _lineman(s), const CrewGear(gloves: CrewGloves.rubber, harness: CrewHarness.full));
      case GateSlot.fire:
        _fire(c);
      default:
        break;
    }
  }

  /// The pole's number plate with the feeder's name (a label a worker reads).
  void _tag(Canvas c) {
    final g = geo;
    final r = Rect.fromCenter(center: Offset(g.cx, g.y(2.25)), width: 1.25 * g.ppm, height: 0.46 * g.ppm);
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), Paint()..color = const Color(0xFFF7F3E6));
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)),
        Paint()
          ..color = const Color(0xFF7A1F1F)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8);
    _text(c, shot.feeder, r.center - Offset(0, r.height * 0.2), r.height * 0.3, const Color(0xFF7A1F1F), FontWeight.w800, r.width * 0.96);
    _text(c, enDigits('${shot.poleNo}'), r.center + Offset(0, r.height * 0.24), r.height * 0.3, const Color(0xFF1C222B), FontWeight.w800, r.width);
  }

  void _kite(Canvas c) {
    final s = shot;
    final g = geo;
    // The tree (a neem by the roadside), the kite caught in its crown.
    final foot = _treeFoot(g);
    final crown = _treeCrown(g);
    c.drawPath(
      Path()
        ..moveTo(foot.dx - 9, foot.dy)
        ..quadraticBezierTo(foot.dx - 5, (foot.dy + crown.dy) / 2, foot.dx - 3, crown.dy + 0.6 * g.ppm)
        ..lineTo(foot.dx + 5, crown.dy + 0.6 * g.ppm)
        ..quadraticBezierTo(foot.dx + 6, (foot.dy + crown.dy) / 2, foot.dx + 10, foot.dy)
        ..close(),
      Paint()..color = const Color(0xFF6B4E33),
    );
    for (final (o, r, col) in const [
      (Offset(-1.1, 0.3), 0.95, Color(0xFF4F7A3A)),
      (Offset(0.9, 0.2), 1.0, Color(0xFF4A7336)),
      (Offset(0, -0.75), 1.05, Color(0xFF5A8742)),
      (Offset(-0.2, 0.55), 0.9, Color(0xFF557F3E)),
    ]) {
      c.drawCircle(crown + o * g.ppm, r * g.ppm, Paint()..color = col);
    }
    final kite = _kiteAt(s, g);
    // The kite: red and yellow, its tail and string tangled in the leaves.
    final kp = Path()
      ..moveTo(kite.dx, kite.dy - 16)
      ..lineTo(kite.dx + 11, kite.dy)
      ..lineTo(kite.dx, kite.dy + 18)
      ..lineTo(kite.dx - 11, kite.dy)
      ..close();
    c.drawPath(kp, Paint()..color = const Color(0xFFE53935));
    c.drawPath(Path()..moveTo(kite.dx, kite.dy - 16)..lineTo(kite.dx + 11, kite.dy)..lineTo(kite.dx, kite.dy + 18)..close(), Paint()..color = const Color(0xFFFDD835));
    c.drawLine(kite + const Offset(0, -16), kite + const Offset(0, 18), Paint()
      ..color = const Color(0xFF5D4037)
      ..strokeWidth = 1);
    final string = Path()..moveTo(kite.dx, kite.dy + 18);
    string.cubicTo(kite.dx + 10, kite.dy + 34, kite.dx + 20, kite.dy + 20, kite.dx + 30, kite.dy + 30);
    c.drawPath(string, Paint()
      ..color = const Color(0xFFECEFF1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1);
    final j = _kiteActor(s, g);
    final (hand, tip) = _kiteStick(s, g);
    final back = hand + (hand - tip) / (hand - tip).distance * (0.6 * g.ppm);
    switch (s.fault) {
      case GateFault.bamboo:
        // A bamboo pole: green-brown with dark knots.
        c.drawLine(back, tip, Paint()
          ..color = const Color(0xFF9DAA4E)
          ..strokeWidth = 5.2
          ..strokeCap = StrokeCap.round);
        for (var k = 1; k < 9; k++) {
          final p = Offset.lerp(back, tip, k / 9)!;
          final n = (tip - back) / (tip - back).distance;
          c.drawLine(p - Offset(-n.dy, n.dx) * 3.6, p + Offset(-n.dy, n.dx) * 3.6, Paint()
            ..color = const Color(0xFF5E5A22)
            ..strokeWidth = 2.2);
        }
      case GateFault.pvcHook:
        c.drawLine(back, tip, Paint()
          ..color = const Color(0xFFE6E6DE)
          ..strokeWidth = 4.6
          ..strokeCap = StrokeCap.butt);
        for (var k = 1; k < 4; k++) {
          final p = Offset.lerp(back, tip, k / 4)!;
          c.drawCircle(p, 3.4, Paint()..color = const Color(0xFFBDBDB4));
        }
        _hook(c, tip, (tip - back) / (tip - back).distance, const Color(0xFF7D858C));
      default:
        // A tested fibreglass hot stick: yellow, red bands, its hook.
        c.drawLine(back, tip, Paint()
          ..color = const Color(0xFFF2B632)
          ..strokeWidth = 4.2
          ..strokeCap = StrokeCap.round);
        for (final k in const [0.18, 0.5]) {
          final p = Offset.lerp(back, tip, k)!;
          c.drawCircle(p, 2.8, Paint()..color = const Color(0xFFC62828));
        }
        _hook(c, tip, (tip - back) / (tip - back).distance, const Color(0xFF5E6870));
    }
    paintCrew(c, j, _lineman(s, other: true), const CrewGear(gloves: CrewGloves.rubber));
  }

  void _hook(Canvas c, Offset tip, Offset n, Color col) {
    final side = Offset(-n.dy, n.dx);
    c.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(tip.dx + n.dx * 8, tip.dy + n.dy * 8)
        ..quadraticBezierTo(tip.dx + n.dx * 13 + side.dx * 6, tip.dy + n.dy * 13 + side.dy * 6, tip.dx + n.dx * 8 + side.dx * 7, tip.dy + n.dy * 8 + side.dy * 7),
      Paint()
        ..color = col
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  void _permit(Canvas c) {
    final s = shot;
    final g = geo;
    // Lineman ready at the pole.
    paintCrew(c, crewJoints(standHip(g.cx + 30, g.ground, g.man), g.man, CrewPose.stand, dir: 1), _lineman(s), const CrewGear(gloves: CrewGloves.rubber, harness: CrewHarness.full));
    final lead = _leadPermit(s, g);
    paintCrew(c, lead, CrewLook.lead, const CrewGear());
    if (s.fault == GateFault.phonePermit) {
      final ph = RRect.fromRectAndRadius(Rect.fromCenter(center: lead.handF, width: g.man * 0.05, height: g.man * 0.1), const Radius.circular(1.5));
      c.drawRRect(ph, Paint()..color = const Color(0xFF20262E));
      c.drawRect(ph.outerRect.deflate(0.8), Paint()..color = const Color(0xFF6FA8DC));
      return;
    }
    final board = _clipboard(lead, g);
    c.drawRRect(RRect.fromRectAndRadius(board, const Radius.circular(1.5)), Paint()..color = const Color(0xFF8D6E4A));
    final paper = board.deflate(board.width * 0.07);
    c.drawRect(paper, Paint()..color = const Color(0xFFFFFDF5));
    c.drawRect(Rect.fromCenter(center: Offset(board.center.dx, board.top + 1), width: board.width * 0.35, height: board.height * 0.06), Paint()..color = const Color(0xFF9AA3AB));
    final fs = paper.height * 0.13;
    _text(c, 'পারমিট', Offset(paper.center.dx, paper.top + fs * 0.9), fs * 0.95, const Color(0xFF1C222B), FontWeight.w800, paper.width);
    _text(c, s.permitFeeder, Offset(paper.center.dx, paper.top + fs * 2.4), fs * 1.05, const Color(0xFF7A1F1F), FontWeight.w800, paper.width);
    _text(c, enDigits('পোল ${s.poleNo}'), Offset(paper.center.dx, paper.top + fs * 3.8), fs * 0.85, const Color(0xFF1C222B), FontWeight.w700, paper.width);
    // The signature.
    final sig = Path()..moveTo(paper.left + paper.width * 0.2, paper.bottom - fs * 0.8);
    for (var k = 0; k < 4; k++) {
      sig.relativeQuadraticBezierTo(paper.width * 0.06, -fs * 0.8, paper.width * 0.13, 0);
    }
    c.drawPath(sig, Paint()
      ..color = const Color(0xFF1F4E9E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7);
  }

  void _rod(Canvas c) {
    final s = shot;
    final g = geo;
    final j = _rodActor(s, g);
    final (lo, hi) = _rodEnds(s, g, j);
    final n = (hi - lo) / (hi - lo).distance;
    final side = Offset(-n.dy, n.dx);
    paintCrew(c, j, _lineman(s), const CrewGear(gloves: CrewGloves.rubber));
    if (s.fault == GateFault.jugaadRod) {
      // A cut PVC water pipe, a metal hook on top, a thin wire for earth.
      c.drawLine(lo, hi, Paint()
        ..color = const Color(0xFFE8E8E0)
        ..strokeWidth = 4.4);
      for (final k in const [0.3, 0.62]) {
        c.drawLine(Offset.lerp(lo, hi, k)! - side * 3.6, Offset.lerp(lo, hi, k)! + side * 3.6, Paint()
          ..color = const Color(0xFFB9B9AE)
          ..strokeWidth = 4);
      }
      _hook(c, hi, n, const Color(0xFF7D858C));
      c.drawPath(Path()..moveTo(hi.dx, hi.dy)..quadraticBezierTo(hi.dx + 18, (hi.dy + lo.dy) / 2, lo.dx + 10, lo.dy + 6), Paint()
        ..color = const Color(0xFF9A9A9A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8);
    } else {
      // A standard rod: fibreglass, a red hand-guard, the rating label.
      c.drawLine(lo, hi, Paint()
        ..color = const Color(0xFFE9A830)
        ..strokeWidth = 4.2);
      final guard = Offset.lerp(lo, hi, 0.42)!;
      c.drawLine(guard - side * 4.5, guard + side * 4.5, Paint()
        ..color = const Color(0xFFC62828)
        ..strokeWidth = 3);
      _hook(c, hi, n, const Color(0xFF5E6870));
      c.drawPath(Path()..moveTo(hi.dx, hi.dy)..quadraticBezierTo(hi.dx + 22, (hi.dy + lo.dy) / 2, lo.dx + 12, lo.dy + 4), Paint()
        ..color = const Color(0xFFC77B30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6);
    }
    // The rating label (the PVC jugaad has none).
    if (s.fault != GateFault.jugaadRod) {
      final kv = s.fault == GateFault.wrongRating ? 11 : s.kv;
      final at = Offset.lerp(lo, hi, 0.58)!;
      c.save();
      c.translate(at.dx, at.dy);
      c.rotate(math.atan2(n.dy, n.dx) + math.pi / 2);
      final r = Rect.fromCenter(center: Offset.zero, width: 0.22 * g.ppm, height: 0.58 * g.ppm);
      c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(1.5)), Paint()..color = const Color(0xFFFFF6C8));
      c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(1.5)), Paint()
        ..color = const Color(0xFF3B3F45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6);
      c.rotate(-math.pi / 2);
      _text(c, enDigits('$kv kV'), Offset.zero, r.width * 0.62, const Color(0xFF1C222B), FontWeight.w900, r.height);
      c.restore();
    }
  }

  void _harness(Canvas c) {
    final s = shot;
    final kind = switch (s.fault) {
      GateFault.waistBelt => CrewHarness.belt,
      GateFault.chestHigh => CrewHarness.chestHigh,
      _ => CrewHarness.full,
    };
    if (!s.gone) paintCrew(c, _harnessActor(s, geo), _lineman(s), CrewGear(gloves: CrewGloves.rubber, harness: kind));
  }

  void _poleCheck(Canvas c) {
    final s = shot;
    final (j, behind) = _poleCheckActor(s, geo);
    if (behind || s.gone) return;
    paintCrew(c, j, _lineman(s), const CrewGear(gloves: CrewGloves.rubber, harness: CrewHarness.full));
    // The hammer while knocking.
    if (s.fault != GateFault.skipCheck && s.t >= 0.42 && s.t < 0.66) {
      final n = (j.handF - j.elbowF) / (j.handF - j.elbowF).distance;
      final head = j.handF + n * (0.16 * j.h);
      c.drawLine(j.handF, head, Paint()
        ..color = const Color(0xFF6D4C2F)
        ..strokeWidth = 0.025 * j.h
        ..strokeCap = StrokeCap.round);
      c.drawRect(Rect.fromCenter(center: head, width: 0.07 * j.h, height: 0.045 * j.h), Paint()..color = const Color(0xFF5E6870));
    }
  }

  void _discharge(Canvas c) {
    final s = shot;
    final g = geo;
    // The earth spike by the pole's foot.
    final spikeTop = Offset(g.cx + 55, g.ground - 0.42 * g.ppm);
    c.drawLine(spikeTop, Offset(g.cx + 55, g.ground + 6), Paint()
      ..color = const Color(0xFF5E6368)
      ..strokeWidth = 6.4);
    c.drawLine(spikeTop, Offset(g.cx + 55, g.ground + 6), Paint()
      ..color = const Color(0xFFA8AEB4)
      ..strokeWidth = 3.6);
    c.drawCircle(spikeTop, 4.4, Paint()..color = const Color(0xFF6B7075));
    final (a, (foot, head)) = _dischargeRig(s, g);
    final clamp = _clampAt(s, g);
    // The helper by the spike (the earth clamp is in his hand, or on it).
    final bHip = standHip(g.cx + 96, g.ground, g.man);
    final reachK = s.fault == GateFault.lineFirst ? _seg(s.t, 0.6, 0.85) : _seg(s.t, 0.08, 0.36);
    final bPose = CrewPose.lerp(CrewPose.stand, const CrewPose(armB: 0.6, foreB: 0.9, armF: 0.95, foreF: 1.05, lean: 0.35), math.sin(reachK * math.pi));
    paintCrew(c, crewJoints(bHip, g.man, bPose, dir: -1), _lineman(s, other: true), const CrewGear(gloves: CrewGloves.rubber));
    // The lead watching (says "earth first", or his "5 minutes" myth).
    paintCrew(c, crewJoints(standHip(g.cx + 128, g.ground, g.man), g.man, CrewPose.stand, dir: -1), CrewLook.lead, const CrewGear());
    // The cable: copper, from the rod's head to the clamp.
    final cable = Path()
      ..moveTo(head.dx, head.dy)
      ..cubicTo(head.dx + 30, head.dy + 40, clamp.dx + 30, clamp.dy - 90, clamp.dx, clamp.dy);
    c.drawPath(cable, Paint()
      ..color = const Color(0xFF6B3A12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.2);
    c.drawPath(cable, Paint()
      ..color = const Color(0xFFE08A3A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6);
    // The earth clamp: a big brass jaw with a T-screw (on the spike's head,
    // or lying loose on the ground) — the same clamp in every moment.
    final jaw = RRect.fromRectAndRadius(Rect.fromCenter(center: clamp, width: 22, height: 15), const Radius.circular(3));
    c.drawRRect(jaw, Paint()..color = const Color(0xFFD9A62E));
    c.drawRRect(jaw, Paint()
      ..color = const Color(0xFF3B2A0A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6);
    c.drawLine(clamp + const Offset(-6, -11), clamp + const Offset(6, -11), Paint()
      ..color = const Color(0xFF3B3F45)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round);
    c.drawLine(clamp + const Offset(0, -11), clamp + const Offset(0, -6), Paint()
      ..color = const Color(0xFF3B3F45)
      ..strokeWidth = 2.4);
    // The rod.
    final n = (head - foot) / (head - foot).distance;
    c.drawLine(foot, head, Paint()
      ..color = const Color(0xFFE9A830)
      ..strokeWidth = 3.4);
    _hook(c, head, n, const Color(0xFF5E6870));
    paintCrew(c, a, _lineman(s), const CrewGear(gloves: CrewGloves.rubber, harness: CrewHarness.full));
    // A spark at each touch once earthed (lesson 1.5: a small spark is good).
    // Its absence on a mistake is part of the fault itself: with no earth (or
    // no discharge) there is no safe path for the charge to spark through.
    if (s.fault == null) {
      for (final (k0, at) in [(0.52, g.wireRight), (0.68, g.wireTop + const Offset(6, 0)), (0.86, g.wireLeft + const Offset(8, 0))]) {
        final k = _seg(s.t, k0, k0 + 0.06);
        if (k > 0 && k < 1) _spark(c, at, 7 * math.sin(k * math.pi));
      }
    }
  }

  void _spark(Canvas c, Offset at, double r) {
    final p = Paint()
      ..color = const Color(0xFFFFF59D)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var k = 0; k < 8; k++) {
      final a = k * math.pi / 4;
      c.drawLine(at, at + Offset(math.cos(a), math.sin(a)) * r * (k.isEven ? 1.4 : 0.8), p);
    }
    c.drawCircle(at, r * 0.4, Paint()..color = const Color(0xFFFFFFFF));
  }

  void _anchor(Canvas c) {
    final s = shot;
    final g = geo;
    final j = _anchorActor(s, g);
    final (hook, set) = _anchorLine(s, g);
    final bad = s.fault == GateFault.brokenArm;
    if (set && !bad) {
      // The sling round the pole above the cross-arm.
      final y = g.y(8.75);
      final hw = 12 * g.pole.s;
      c.drawOval(Rect.fromCenter(center: Offset(g.cx, y), width: hw * 2.6, height: 5), Paint()
        ..color = const Color(0xFFE65100)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2);
    }
    if (s.gone) return;
    _lanyardTo(c, j, hook);
    paintCrew(c, j, _lineman(s), const CrewGear(gloves: CrewGloves.rubber, harness: CrewHarness.full));
  }

  /// The lanyard from the harness's back D-ring to [hook].
  void _lanyardTo(Canvas c, CrewJoints j, Offset hook) {
    final ring = Offset.lerp(j.neck, j.hip, 0.2)! + Offset(-j.dir * 0.06 * j.h, 0);
    c.drawPath(Path()..moveTo(ring.dx, ring.dy)..quadraticBezierTo((ring.dx + hook.dx) / 2 + 6, math.max(ring.dy, hook.dy) + 10, hook.dx, hook.dy), Paint()
      ..color = const Color(0xFFE65100)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
    c.drawCircle(hook, 3, Paint()
      ..color = const Color(0xFF9AA3AB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6);
  }

  /// Weather coming: the sky darkens and lightning strikes on the horizon.
  void _storm(Canvas c) {
    final s = shot;
    final g = geo;
    final dark = _ease(_seg(s.t, 0.1, 0.45));
    if (dark > 0) {
      c.drawRect(Rect.fromLTWH(0, 0, 360, g.ground), Paint()..color = Color.fromRGBO(30, 38, 58, 0.55 * dark));
      final cloud = Paint()..color = Color.fromRGBO(52, 58, 74, 0.95 * dark);
      for (final o in const [Offset(10, 11.6), Offset(60, 12.0), Offset(110, 11.4), Offset(30, 10.9), Offset(150, 12.2)]) {
        c.drawCircle(Offset(o.dx, g.y(o.dy)), 34, cloud);
      }
    }
    final flash = _seg(s.t, 0.42, 0.5);
    if (flash > 0 && flash < 1 || (s.t >= 0.5 && s.t < 0.56)) {
      final bolt = Path()
        ..moveTo(62, g.y(11.8))
        ..lineTo(48, g.y(9.9))
        ..lineTo(64, g.y(9.6))
        ..lineTo(40, g.y(7.2))
        ..lineTo(58, g.y(7.5))
        ..lineTo(36, g.y(5.0));
      c.drawPath(bolt, Paint()
        ..color = const Color(0xFFFFFDE7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.4
        ..strokeJoin = StrokeJoin.round);
      c.drawPath(bolt, Paint()
        ..color = const Color(0x88B3E5FC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeJoin = StrokeJoin.round);
    }
  }

  void _fire(Canvas c) {
    final s = shot;
    final g = geo;
    final box = _boxRect(g);
    // The roadside LT box on its stand, burning and sparking.
    c.drawRect(Rect.fromLTWH(box.center.dx - 3, box.bottom, 6, g.ground - box.bottom), Paint()..color = const Color(0xFF5E6870));
    c.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(2)), Paint()..color = const Color(0xFF7D8890));
    c.drawRect(box.deflate(4), Paint()
      ..color = const Color(0xFF4E5860)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);
    final water = s.fault == GateFault.waterFire;
    final out = water ? 0.0 : _ease(_seg(s.t, 0.55, 0.95));
    final f = (1 - out) * (0.85 + 0.15 * math.sin(s.t * 30));
    if (f > 0.02) {
      final flame = Path()
        ..moveTo(box.left + 2, box.top + 4)
        ..quadraticBezierTo(box.left - 4, box.top - 22 * f, box.left + box.width * 0.3, box.top - 34 * f)
        ..quadraticBezierTo(box.left + box.width * 0.45, box.top - 18 * f, box.center.dx, box.top - 46 * f)
        ..quadraticBezierTo(box.right - 4, box.top - 20 * f, box.right + 4, box.top + 4)
        ..close();
      c.drawPath(flame, Paint()..color = const Color(0xFFFF7043));
      c.drawPath(flame.shift(const Offset(0, 6)), Paint()..color = const Color(0xCCFFCA28));
      _spark(c, box.topRight + const Offset(-4, 6), 6 * f);
    }
    final b = _fireActor(s, g);
    if (!water) {
      // The lead on the phone to the control room.
      paintCrew(c, crewJoints(standHip(g.cx + 60, g.ground, g.man), g.man, CrewPose.phone, dir: 1), CrewLook.lead, const CrewGear());
      final ph = crewJoints(standHip(g.cx + 60, g.ground, g.man), g.man, CrewPose.phone, dir: 1).handF;
      c.drawRect(Rect.fromCenter(center: ph, width: 3, height: 6), Paint()..color = const Color(0xFF20262E));
    }
    paintCrew(c, b, _lineman(s, other: true), const CrewGear(gloves: CrewGloves.rubber));
    if (water) {
      // A bucket of water swung at the fire.
      final hand = Offset.lerp(b.handB, b.handF, 0.5)!;
      c.drawPath(
        Path()
          ..moveTo(hand.dx - 7, hand.dy)
          ..lineTo(hand.dx + 7, hand.dy)
          ..lineTo(hand.dx + 5, hand.dy + 12)
          ..lineTo(hand.dx - 5, hand.dy + 12)
          ..close(),
        Paint()..color = const Color(0xFF1E88E5),
      );
      final k = _seg(s.t, 0.5, 0.8);
      if (k > 0) {
        final to = Offset.lerp(hand, box.center, k)!;
        c.drawPath(Path()..moveTo(hand.dx, hand.dy)..quadraticBezierTo((hand.dx + to.dx) / 2, math.min(hand.dy, to.dy) - 26, to.dx, to.dy), Paint()
          ..color = const Color(0xCC64B5F6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round);
      }
    } else {
      // The red ABC extinguisher, aimed at the base of the fire.
      final hand = b.handF;
      final body = Rect.fromCenter(center: b.handB + const Offset(2, 8), width: 9, height: 22);
      c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(3)), Paint()..color = const Color(0xFFD32F2F));
      c.drawRect(Rect.fromCenter(center: body.center, width: 9, height: 6), Paint()..color = const Color(0xFFF5F5F5));
      _text(c, 'ABC', body.center, 3.6, const Color(0xFF1C222B), FontWeight.w900, 12);
      c.drawLine(body.topCenter, hand, Paint()
        ..color = const Color(0xFF263238)
        ..strokeWidth = 1.4);
      final k = _seg(s.t, 0.42, 0.95);
      if (k > 0 && k < 1) {
        final base = Offset(box.left + 4, box.bottom - 6);
        c.drawPath(
          Path()
            ..moveTo(hand.dx, hand.dy)
            ..lineTo(base.dx, base.dy - 10)
            ..lineTo(base.dx, base.dy + 6)
            ..close(),
          Paint()..color = const Color(0xCCF5F5F5),
        );
      }
    }
  }

  @override
  bool shouldRepaint(GatePolePainter old) => old.shot != shot || old.geo != geo || old.layer != layer;
}

/// The crew and kit beside the van (dressing, the checks, the line clear).
class GateVanPainter extends CustomPainter {
  const GateVanPainter({required this.shot, required this.geo});
  final GateShot shot;
  final GateGeo geo;

  @override
  void paint(Canvas c, Size size) {
    final s = shot;
    final g = geo;
    final vm = g.vanMan;
    // The road in front of the van gets a little shade where the crew stands.
    c.drawOval(Rect.fromCenter(center: Offset(130, g.vanFeet + 4), width: vm * 0.6, height: vm * 0.06), Paint()..color = const Color(0x33000000));
    switch (s.slot) {
      case GateSlot.helmet:
        final j = _vanActor(s, g, _helmetPose(s));
        final kind = s.fault == GateFault.vented ? CrewHelmet.vented : CrewHelmet.solid;
        final on = s.t >= 0.38;
        final strap = s.fault != GateFault.strapOpen && s.t >= 0.62;
        paintCrew(c, j, _lineman(s), CrewGear(wearsHelmet: on, helmet: kind, strap: strap));
        if (!on) paintHelmet(c, _helmetAt(s, g, j), j.headR, 1, _lineman(s).helmet, kind, false, worn: false);
      case GateSlot.shirt:
        final j = _vanActor(s, g, _shirtPose(s));
        final shirt = switch (s.fault) {
          GateFault.polyester => CrewShirt.jersey,
          GateFault.sleeves when s.t >= 0.32 => CrewShirt.rolled,
          _ => CrewShirt.cotton,
        };
        paintCrew(c, j, _lineman(s), CrewGear(shirt: shirt));
      case GateSlot.boots:
        _boots(c);
      case GateSlot.gloves:
        _gloves(c);
      case GateSlot.clear:
        _clear(c);
      default:
        break;
    }
  }

  void _boots(Canvas c) {
    final s = shot;
    final g = geo;
    final vm = g.vanMan;
    // A crate to sit on.
    final crate = Rect.fromLTWH(70, g.vanFeet - 0.3 * vm, 0.36 * vm, 0.3 * vm);
    c.drawRect(crate, Paint()..color = const Color(0xFF8D6E4A));
    for (var k = 1; k < 3; k++) {
      c.drawLine(Offset(crate.left, crate.top + crate.height * k / 3), Offset(crate.right, crate.top + crate.height * k / 3), Paint()
        ..color = const Color(0xFF6B5237)
        ..strokeWidth = 2);
    }
    final j = crewJoints(Offset(118, g.vanFeet - 0.3 * vm), vm, CrewPose.sit, dir: 1);
    paintCrew(c, j, _lineman(s), const CrewGear());
    // The boot in his hands, sole toward us; then onto his foot.
    final r = _bootRect(s, g);
    final turn = _ease(_seg(s.t, 0.05, 0.3));
    final sole = Rect.fromCenter(center: r.center, width: r.width * (0.25 + 0.75 * turn), height: r.height);
    if (s.t >= 0.66) {
      // Back on: a side view of the boot.
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: r.center, width: r.height * 1.3, height: r.width * 0.9), Radius.circular(r.width * 0.2)), Paint()..color = const Color(0xFF34261A));
      return;
    }
    final soleP = Path()..addRRect(RRect.fromRectAndCorners(sole, topLeft: Radius.circular(sole.width / 2), topRight: Radius.circular(sole.width / 2), bottomLeft: Radius.circular(sole.width * 0.35), bottomRight: Radius.circular(sole.width * 0.35)));
    c.drawPath(soleP, Paint()..color = const Color(0xFF2B2B2B));
    if (turn > 0.6) {
      final tread = Paint()
        ..color = const Color(0xFF555555)
        ..strokeWidth = sole.width * 0.06;
      for (var k = 1; k < 8; k++) {
        final y = sole.top + sole.height * k / 8.5;
        c.drawLine(Offset(sole.left + sole.width * 0.18, y), Offset(sole.right - sole.width * 0.18, y), tread);
      }
      c.drawLine(Offset(sole.left, sole.top + sole.height * 0.66), Offset(sole.right, sole.top + sole.height * 0.66), Paint()
        ..color = const Color(0xFF1A1A1A)
        ..strokeWidth = sole.width * 0.08);
      if (s.fault == GateFault.nail) {
        // A nail driven into the sole: its head shines.
        final at = Offset(sole.center.dx + sole.width * 0.12, sole.top + sole.height * 0.3);
        c.drawCircle(at, sole.width * 0.2, Paint()..color = const Color(0xFFB0B7BE));
        c.drawCircle(at - Offset(sole.width * 0.06, sole.width * 0.06), sole.width * 0.07, Paint()..color = const Color(0xFFF2F4F6));
        c.drawCircle(at, sole.width * 0.2, Paint()
          ..color = const Color(0xFF6B7178)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2);
      }
    }
  }

  void _gloves(Canvas c) {
    final s = shot;
    final g = geo;
    final j = _vanActor(s, g, _glovesPose(s));
    final cotton = s.fault == GateFault.cotton;
    final on = s.t >= 0.78;
    paintCrew(c, j, _lineman(s), CrewGear(gloves: on ? (cotton ? CrewGloves.cotton : CrewGloves.rubber) : CrewGloves.bare));
    if (on) return;
    final at = _gloveAt(s, g, j);
    final inflate = _gloveInflate(s);
    final k = s.t < 0.66 ? 1.0 : 1 - _ease(_seg(s.t, 0.66, 0.78));
    _glove(c, at, j.h * 0.11 * (1 + 0.35 * inflate) * (0.6 + 0.4 * k), cotton ? _cottonGlove : _rubber, inflate, cotton);
    if (s.fault == GateFault.pinhole && s.t > 0.44 && s.t < 0.66) {
      // Air leaking out of a fingertip.
      final tip = at + Offset(-j.h * 0.05, -j.h * 0.16 * (1 + 0.35 * inflate));
      final p = Paint()
        ..color = const Color(0xCCFFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6;
      for (var r = 1; r <= 3; r++) {
        c.drawArc(Rect.fromCircle(center: tip, radius: 5.0 * r + 3 * math.sin(s.t * 40)), -2.4, 1.4, false, p);
      }
    }
  }

  /// A glove held up by the cuff ([size] = palm half-height).
  void _glove(Canvas c, Offset at, double size, Color col, double inflate, bool knit) {
    final paint = Paint()..color = col;
    final palm = Rect.fromCenter(center: at, width: size * (1.3 + 0.3 * inflate), height: size * 1.6);
    c.drawRRect(RRect.fromRectAndRadius(palm, Radius.circular(size * 0.5)), paint);
    for (var k = 0; k < 4; k++) {
      final x = palm.left + palm.width * (0.14 + k * 0.24);
      final fw = size * (0.28 + 0.12 * inflate);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - fw / 2, palm.top - size * (0.75 - 0.08 * (k - 1.5).abs()), fw, size * 0.95), Radius.circular(fw / 2)), paint);
    }
    c.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(palm.left - size * 0.42, palm.center.dy - size * 0.3, size * 0.6, size * 0.34), Radius.circular(size * 0.17)),
      paint,
    );
    // The cuff (rolled to trap the air for the test).
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(palm.left + size * 0.05, palm.bottom - size * 0.1, palm.width - size * 0.1, size * 0.55), Radius.circular(size * 0.12)), Paint()..color = _shade(col, 0.12));
    if (knit) {
      final dot = Paint()..color = const Color(0xFFC9C2AE);
      for (var k = 0; k < 14; k++) {
        c.drawCircle(Offset(palm.left + palm.width * ((k * 37 % 10) / 10), palm.top + palm.height * ((k * 53 % 10) / 10)), 1.1, dot);
      }
    } else {
      c.drawOval(Rect.fromCenter(center: palm.center - Offset(size * 0.25, size * 0.25), width: size * 0.4, height: size * 0.6), Paint()..color = const Color(0x55FFFFFF));
    }
  }

  void _clear(Canvas c) {
    final s = shot;
    final g = geo;
    final vm = g.vanMan;
    // The two linemen walk back to the van (smaller, behind).
    final k = _seg(s.t, 0, 1);
    for (final (i, x0) in [(0, 300.0), (1, 250.0)]) {
      final x = x0 - 20 * k;
      final j = crewJoints(standHip(x, g.vanFeet - vm * 0.16, vm * 0.62), vm * 0.62, CrewPose.walk(s.t * 3 + i * 0.4), dir: 1);
      paintCrew(c, j, i == 0 ? CrewLook.a : CrewLook.b, const CrewGear(gloves: CrewGloves.rubber));
    }
    final lead = _leadClear(s, g);
    paintCrew(c, lead, CrewLook.lead, const CrewGear());
    final paper = _clearPaper(s, g, lead);
    if (paper != null) {
      c.drawRect(paper, Paint()..color = const Color(0xFFFFFDF5));
      c.drawRect(paper, Paint()
        ..color = const Color(0xFF9AA3AB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);
      if (paper.width > vm * 0.1) {
        _text(c, 'পারমিট', paper.topCenter + Offset(0, paper.height * 0.22), paper.height * 0.16, const Color(0xFF1C222B), FontWeight.w800, paper.width);
        for (var r = 0; r < 3; r++) {
          final y = paper.top + paper.height * (0.45 + r * 0.14);
          c.drawLine(Offset(paper.left + paper.width * 0.15, y), Offset(paper.right - paper.width * 0.15, y), Paint()
            ..color = const Color(0xFFB0B7BE)
            ..strokeWidth = 1);
        }
      }
    }
    if (s.fault != GateFault.keptPermit) {
      final ph = lead.handF;
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: ph, width: vm * 0.035, height: vm * 0.07), const Radius.circular(2)), Paint()..color = const Color(0xFF20262E));
    }
  }

  @override
  bool shouldRepaint(GateVanPainter old) => old.shot != shot || old.geo != geo;
}

void _text(Canvas c, String text, Offset centre, double size, Color color, FontWeight w, double maxWidth) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: bangla(fontSize: size, fontWeight: w, color: color, height: 1.1)),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
    maxLines: 1,
    ellipsis: '…',
  )..layout(maxWidth: math.max(1.0, maxWidth));
  tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
}

// ============================================================================
// A missed deadly mistake, in colour over the frozen grey scene
// ============================================================================

enum GateHarm { flash, fall, flare }

GateHarm gateHarmOf(GateFault f) => switch (f) {
      GateFault.hollow || GateFault.waistBelt || GateFault.brokenArm => GateHarm.fall,
      GateFault.waterFire => GateHarm.flare,
      _ => GateHarm.flash,
    };

/// Where the harm happens for [s] (world px of its spot).
Offset gateHarmAt(GateShot s, GateGeo g) {
  final f = s.fault!;
  final vm = g.vanMan;
  switch (f.slot) {
    case GateSlot.helmet:
    case GateSlot.shirt:
      return _vanActor(s, g, CrewPose.stand).chest;
    case GateSlot.boots:
      return Offset(150, g.vanFeet - vm * 0.05);
    case GateSlot.gloves:
      return _vanActor(s, g, CrewPose.stand).handF;
    case GateSlot.kite:
      return _kiteStick(s, g).$2;
    case GateSlot.permit:
    case GateSlot.rod:
    case GateSlot.discharge:
      return g.wireRight;
    case GateSlot.harness:
      // Up the pole on a belt, he slips (in the zoomed view's top).
      return Offset(g.cx + 34, g.y(2.9));
    case GateSlot.poleCheck:
      return Offset(g.cx + 26, g.y(3.6));
    case GateSlot.anchor:
      return _anchorActor(s, g).hip;
    case GateSlot.sky:
      return _skyActor(s, g).headC;
    case GateSlot.fire:
      return _boxRect(g).center;
    case GateSlot.clear:
      return _leadClear(s, g).chest;
  }
}

/// The consequence at [at] ([k] 0 → 1): a flash, a fall to the ground, a
/// flare-up — never gore.
class GateHarmPainter extends CustomPainter {
  const GateHarmPainter({required this.kind, required this.at, required this.k, required this.ground, required this.man, required this.look});
  final GateHarm kind;
  final Offset at;
  final double k;
  final double ground;
  final double man;
  final CrewLook look;

  @override
  void paint(Canvas c, Size size) {
    switch (kind) {
      case GateHarm.flash:
        final r = 20 + 70 * Curves.easeOut.transform(k);
        c.drawCircle(at, r * 1.6, Paint()..shader = RadialGradient(colors: [Color.fromRGBO(255, 255, 255, 0.9 * (1 - k)), const Color(0x00B3E5FC)]).createShader(Rect.fromCircle(center: at, radius: r * 1.6)));
        final bolt = Paint()
          ..color = Color.fromRGBO(129, 212, 250, 1 - k * 0.6)
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < 10; i++) {
          final a = i * math.pi / 5 + k;
          var p = at;
          for (var s = 0; s < 3; s++) {
            final q = p + Offset(math.cos(a + (s.isEven ? 0.3 : -0.3)), math.sin(a + (s.isEven ? 0.3 : -0.3))) * (r * 0.35);
            c.drawLine(p, q, bolt);
            p = q;
          }
        }
      case GateHarm.fall:
        // He falls to the ground; dust where he lands.
        final y = at.dy + (ground - at.dy - man * 0.2) * Curves.easeIn.transform(k);
        final j = crewJoints(Offset(at.dx + 20 * k, y), man, CrewPose.lerp(CrewPose.reach, CrewPose.sit, k), dir: -1);
        final lines = Paint()
          ..color = const Color(0xCCFFFFFF)
          ..strokeWidth = 2;
        for (var i = -1; i <= 1; i++) {
          c.drawLine(Offset(at.dx + i * 12 + 20 * k, y - man * 0.6), Offset(at.dx + i * 12 + 20 * k, y - man * 0.6 - 30 * k), lines);
        }
        paintCrew(c, j, look, const CrewGear(gloves: CrewGloves.rubber));
        if (k > 0.85) {
          final d = (k - 0.85) / 0.15;
          for (var i = 0; i < 6; i++) {
            c.drawCircle(Offset(at.dx + 20 + (i - 2.5) * 14 * d, ground - 6 - 8 * d * (i.isEven ? 1 : 0.5)), 8 + 6 * d, Paint()..color = Color.fromRGBO(190, 160, 120, 0.7 * (1 - d * 0.5)));
          }
        }
      case GateHarm.flare:
        final f = 1 + 2.2 * Curves.easeOut.transform(k);
        final flame = Path()
          ..moveTo(at.dx - 30 * f, at.dy + 10)
          ..quadraticBezierTo(at.dx - 26 * f, at.dy - 40 * f, at.dx, at.dy - 60 * f)
          ..quadraticBezierTo(at.dx + 26 * f, at.dy - 40 * f, at.dx + 30 * f, at.dy + 10)
          ..close();
        c.drawPath(flame, Paint()..color = const Color(0xFFFF5722));
        c.drawPath(flame.shift(Offset(0, 14 * f)), Paint()..color = const Color(0xDDFFC107));
        final arc = Paint()
          ..color = const Color(0xFF81D4FA)
          ..strokeWidth = 2.6;
        for (var i = 0; i < 5; i++) {
          final a = math.pi + i * 0.25 + k * 2;
          c.drawLine(at, at + Offset(math.cos(a), math.sin(a) * 0.4) * (60 * f), arc);
        }
    }
  }

  @override
  bool shouldRepaint(GateHarmPainter old) => old.k != k || old.at != at || old.kind != kind;
}
