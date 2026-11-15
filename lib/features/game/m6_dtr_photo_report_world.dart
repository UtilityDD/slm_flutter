import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The drawn world of lesson 6.1 কাজ 1 "দু'মিনিটের ছবি-রিপোর্ট"
// (m6_dtr_photo_report.dart): a roadside pole-mounted distribution
// transformer on a two-pole structure, seen from the ground where the trainee
// stands with his phone. Layers: the sky (light dealt: morning, noon,
// evening) → far houses and trees → the verge → the two poles with the 11 kV
// line on the top cross-arm, the AB switch (its operating pipe down the left
// pole) and the three HG (horn-gap) fuses (module 6 ruling M6-2: a WBSEDCL DTR
// has an AB switch plus HG fuses, no DO) → the DTR on its platform: the tank
// with its fins on both sides, the conservator drum across the top with the
// MIN/MAX glass gauge on its end and the breather (silica gel window) hanging
// below it, three tall HT bushings and four short LT bushings on the lid, the
// nameplate on the tank's face, the drain valve → the ground under the tank.
//
// Every part the JE can ask for is drawn with the same care, healthy or
// faulty: a wet oil stain and a dry dusty patch are the same size; a cracked,
// flash-marked bushing and a clean one carry a mark of the same size; the gel
// shows its granules in any colour. No text except labels a worker reads (the
// gauge's MIN / MAX, the nameplate's rows).
//
// Design: 360 wide × the scene's height; the ground follows the bottom of the
// screen (the phone's controls and the photo tray stand under it), the
// structure grows with the height up to 470 (a tall phone gets more sky).

/// The parts the JE asks for (lesson 6.1 points 2–5: the six-point check
/// plus the parts' jobs).
enum M6Part { stain, gauge, gel, ht, lt, fins, drum, plate }

/// The breather's silica gel: dry (blue or orange) or spent (pink or white).
enum M6Gel { blue, orange, pink, white }

/// Where a leak comes from (lesson 6.1 point 3: a bushing gasket, a cracked
/// joint, a loose drain valve).
enum M6LeakAt { gasket, joint, drain }

/// A bushing fault (a fine crack and a black flash mark) on the HT or the LT
/// side, or none.
enum M6Bush { clean, ht, lt }

/// The light of the day.
enum M6Light { morning, noon, evening }

/// The viewfinder at zoom 1 (design px, 4:3); it shrinks as the zoom grows.
const double m6FrameW = 200;
const double m6FrameH = 150;
const double m6ZoomMin = 1;
const double m6ZoomMax = 4;

/// How much of [part] lies inside [frame] (0..1).
double m6Coverage(Rect part, Rect frame) {
  final i = part.intersect(frame);
  if (i.width <= 0 || i.height <= 0) return 0;
  return (i.width * i.height) / (part.width * part.height);
}

/// The phone camera: the frame's centre on the scene and the zoom.
@immutable
class M6Cam {
  const M6Cam(this.center, this.zoom);
  final Offset center;
  final double zoom;

  Rect get frame => Rect.fromCenter(center: center, width: m6FrameW / zoom, height: m6FrameH / zoom);

  @override
  bool operator ==(Object other) => other is M6Cam && other.center == center && other.zoom == zoom;

  @override
  int get hashCode => Object.hash(center, zoom);
}

/// Where things are (design px, 360 wide).
@immutable
class M6PhotoGeo {
  const M6PhotoGeo._(this.height, this.groundY, this.topY, this.footY);

  /// [inset] the bottom system inset and [topInset] the status bar, both in
  /// design px. The structure grows upward until its highest part (the gauge
  /// glass) sits just under the JE's chat ([partsTop] + [topInset]), up to
  /// 470 tall: the pole tops, the AB switch and the HG fuses may stand under
  /// the header and the chat (never asked for), and on a 16:9 phone the parts
  /// stand far enough apart for a frame to hold one of them alone.
  factory M6PhotoGeo.forScene(double height, double inset, {double topInset = 0}) {
    final g = height - floorUp - inset * 0.5;
    final top = math.max(g - 470, (partsTop + topInset - partsFrom * g) / (1 - partsFrom));
    return M6PhotoGeo._(height, g, top, height - 172 - inset * 0.5);
  }

  /// The highest part's top under the JE's chat (design px below the status
  /// bar: the chat starts 62 down and holds up to three lines).
  static const double partsTop = 156;

  /// The highest part (the gauge glass) starts this far down the structure.
  static const double partsFrom = 0.385;

  final double height;

  /// The ground line at the poles' feet (the structure stands a little back
  /// across the verge).
  final double groundY;

  /// The pole tops.
  final double topY;

  /// The near verge where the trainee stands (the shutter row and the photo
  /// tray are under it).
  final double footY;

  /// The structure's feet sit this far above the bottom: the guide and his
  /// speech bubble stand on the near verge in front, below every part.
  static const double floorUp = 290;

  /// The two poles' axes.
  static const double lp = 62;
  static const double rp = 262;

  /// The three phases on the cross-arms.
  static const List<double> phaseX = [112, 162, 212];

  /// The structure's height.
  double get h => groundY - topY;

  /// A height on the structure (0 = the pole tops, 1 = the ground).
  double y(double f) => topY + f * h;

  double get armY => y(0.03);
  double get abY => y(0.11);
  double get hgY => y(0.22);

  /// The tank on its platform.
  Rect get tank => Rect.fromLTRB(104, y(0.55), 222, y(0.75));
  Rect get platform => Rect.fromLTRB(lp - 6, y(0.75), rp + 6, y(0.775));
  Rect get drumBody => Rect.fromLTRB(100, y(0.405), 158, y(0.465));
  Rect get gaugeGlass => Rect.fromLTRB(90, y(0.39), 98, y(0.475));
  Rect get breather => Rect.fromLTRB(70, y(0.535), 84, y(0.625));
  Rect get finsLeft => Rect.fromLTRB(88, y(0.57), 104, y(0.73));
  Rect get finsRight => Rect.fromLTRB(222, y(0.57), 238, y(0.73));
  Rect get nameplate => Rect.fromLTRB(144, y(0.605), 186, y(0.685));
  Offset get drainValve => Offset(114, y(0.765));

  /// The bushings' axes (base on the lid).
  List<double> get htX => const [174, 191, 208];
  List<double> get ltX => const [116, 128, 140, 152];
  double get htTop => y(0.40);
  double get ltTop => y(0.505);

  /// What the JE can ask for: the area a good photo must hold.
  Rect part(M6Part p) => switch (p) {
        M6Part.stain => Rect.fromLTRB(125, groundY - 16, 205, groundY + 2),
        M6Part.gauge => Rect.fromLTRB(70, y(0.385), 100, y(0.48)),
        M6Part.gel => Rect.fromLTRB(68, y(0.53), 86, y(0.63)),
        M6Part.ht => Rect.fromLTRB(162, y(0.395), 218, y(0.55)),
        M6Part.lt => Rect.fromLTRB(108, y(0.50), 158, y(0.55)),
        M6Part.fins => Rect.fromLTRB(222, y(0.565), 240, y(0.735)),
        M6Part.drum => Rect.fromLTRB(100, y(0.405), 158, y(0.465)),
        M6Part.plate => Rect.fromLTRB(142, y(0.60), 188, y(0.69)),
      };

  /// Where a leak starts.
  Offset leakFrom(M6LeakAt at) => switch (at) {
        M6LeakAt.gasket => Offset(ltX[1], y(0.552)),
        M6LeakAt.joint => Offset(tank.right - 4, y(0.70)),
        M6LeakAt.drain => drainValve.translate(0, 4),
      };

  /// Where the trainee stands (left of the structure, on the verge).
  Rect get trainee => Rect.fromLTWH(8, footY - 96, 40, 96);

  /// The frame's centre may go anywhere the frame stays on the scene.
  M6Cam clampCam(M6Cam c) {
    final z = c.zoom.clamp(m6ZoomMin, m6ZoomMax).toDouble();
    final w = m6FrameW / z, fh = m6FrameH / z;
    final x = c.center.dx.clamp(w / 2, 360 - w / 2).toDouble();
    final top = 128 + fh / 2;
    final bottom = math.max(top, groundY + 24 - fh / 2);
    return M6Cam(Offset(x, c.center.dy.clamp(top, bottom).toDouble()), z);
  }

  /// Where the camera starts a play: the whole structure's middle, zoom 1.
  M6Cam get startCam => clampCam(M6Cam(Offset(180, y(0.55)), 1));

  @override
  bool operator ==(Object other) => other is M6PhotoGeo && other.height == height && other.groundY == groundY && other.topY == topY && other.footY == footY;

  @override
  int get hashCode => Object.hash(height, groundY, topY, footY);
}

/// What the DTR shows this play.
@immutable
class M6DtrLook {
  const M6DtrLook({
    this.wet = false,
    this.leakAt = M6LeakAt.gasket,
    this.gaugeLow = false,
    this.gel = M6Gel.blue,
    this.bush = M6Bush.clean,
    this.faultBushing = 1,
    this.kva = 63,
    this.serial = '610428',
    this.light = M6Light.noon,
  });

  final bool wet;
  final M6LeakAt leakAt;
  final bool gaugeLow;
  final M6Gel gel;
  final M6Bush bush;

  /// Which bushing of the faulty side carries the crack (0-based).
  final int faultBushing;
  final int kva;
  final String serial;
  final M6Light light;

  @override
  bool operator ==(Object other) =>
      other is M6DtrLook &&
      other.wet == wet &&
      other.leakAt == leakAt &&
      other.gaugeLow == gaugeLow &&
      other.gel == gel &&
      other.bush == bush &&
      other.faultBushing == faultBushing &&
      other.kva == kva &&
      other.serial == serial &&
      other.light == light;

  @override
  int get hashCode => Object.hash(wet, leakAt, gaugeLow, gel, bush, faultBushing, kva, serial, light);
}

const _steel = Color(0xFF6F7880);
const _wire = Color(0xFF3C4248);
const _porcelain = Color(0xFFE9EDF0);
const _porcelainEdge = Color(0xFF8A9399);
const _tankA = Color(0xFF8FA293);
const _tankB = Color(0xFF6D8172);
const _oil = Color(0xFF241505);

class M6DtrPainter extends CustomPainter {
  const M6DtrPainter({required this.geo, required this.look, required this.seed});

  final M6PhotoGeo geo;
  final M6DtrLook look;
  final int seed;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    const w = 360.0;
    final rnd = math.Random(seed);
    final sky = Rect.fromLTWH(0, 0, w, g.groundY);
    final skyColors = switch (look.light) {
      M6Light.morning => const [Color(0xFF7FA9CF), Color(0xFFCFE0EA), Color(0xFFF3E6CC)],
      M6Light.noon => const [Color(0xFF3F7FC0), Color(0xFF9DC8EA), Color(0xFFE3EEDA)],
      M6Light.evening => const [Color(0xFF5B5C93), Color(0xFFE59A73), Color(0xFFF6D29A)],
    };
    c.drawRect(sky, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: skyColors).createShader(sky));
    final cloud = Paint()..color = const Color(0xBBFFFFFF);
    for (var i = 0; i < 3; i++) {
      final cx = 30 + rnd.nextDouble() * 300;
      final cy = 60 + rnd.nextDouble() * 120;
      for (var k = 0; k < 4; k++) {
        c.drawOval(Rect.fromCenter(center: Offset(cx + k * 12 - 18, cy - (k.isOdd ? 4 : 0)), width: 30, height: 14), cloud);
      }
    }
    final horizon = g.groundY - math.min(150.0, g.h * 0.3);
    _farHouses(c, w, horizon, rnd);
    // The verge.
    final floor = Rect.fromLTRB(0, g.groundY - 30, w, size.height);
    c.drawRect(floor, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFB0946A), Color(0xFF7A6345)]).createShader(floor));
    // The road across the verge, between the structure and the trainee.
    final road = Rect.fromLTRB(0, g.groundY + 30, w, math.max(g.groundY + 40, math.min(g.footY - 40, g.groundY + 110)));
    c.drawRect(road, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF6A6E73), Color(0xFF55595E)]).createShader(road));
    final dash = Paint()
      ..color = const Color(0xCCE8E2C8)
      ..strokeWidth = 2;
    for (var x = 6.0; x < w; x += 34) {
      c.drawLine(Offset(x, road.center.dy), Offset(x + 16, road.center.dy), dash);
    }
    final pebble = Paint()..color = const Color(0x33402E1A);
    for (var i = 0; i < 30; i++) {
      c.drawCircle(Offset(rnd.nextDouble() * w, g.groundY - 26 + rnd.nextDouble() * (size.height - g.groundY + 22)), 1 + rnd.nextDouble() * 1.6, pebble);
    }
    _poles(c);
    _line(c);
    _abSwitch(c);
    _hgFuses(c);
    _platform(c);
    _fins(c, g.finsLeft);
    _fins(c, g.finsRight);
    _tank(c);
    _drum(c);
    _gauge(c);
    _breather(c);
    _bushings(c);
    _plate(c);
    _ground(c);
    _ltCables(c);
  }

  void _farHouses(Canvas c, double w, double horizon, math.Random rnd) {
    final tint = look.light == M6Light.evening ? const Color(0xFF8C7A86) : const Color(0xFFA9B7C2);
    final roof = look.light == M6Light.evening ? const Color(0xFF6E5A64) : const Color(0xFF7F8E99);
    for (var x = -8.0; x < w; x += 46 + rnd.nextDouble() * 18) {
      final hh = 18 + rnd.nextDouble() * 22;
      c.drawRect(Rect.fromLTWH(x, horizon - hh, 38, hh), Paint()..color = tint);
      c.drawRect(Rect.fromLTWH(x - 2, horizon - hh - 4, 42, 5), Paint()..color = roof);
      final win = Paint()..color = const Color(0x55344452);
      c.drawRect(Rect.fromLTWH(x + 8, horizon - hh + 7, 6, 6), win);
      c.drawRect(Rect.fromLTWH(x + 24, horizon - hh + 7, 6, 6), win);
    }
    final tree = Paint()..color = const Color(0xFF5E8A55);
    for (var i = 0; i < 6; i++) {
      final x = 20 + rnd.nextDouble() * 320;
      final r = 8 + rnd.nextDouble() * 8;
      c.drawCircle(Offset(x, horizon - r * 0.6), r, tree);
    }
    c.drawRect(Rect.fromLTRB(0, horizon, w, geo.groundY - 30), Paint()..color = const Color(0xFF9DB06C));
  }

  void _poles(Canvas c) {
    final g = geo;
    for (final x in const [M6PhotoGeo.lp, M6PhotoGeo.rp]) {
      final r = Rect.fromLTRB(x - 5, g.topY, x + 5, g.groundY + 4);
      c.drawRect(r, Paint()..shader = const LinearGradient(colors: [Color(0xFFB4B9BD), Color(0xFF8B9196), Color(0xFFA6ABAF)]).createShader(r));
      // The earth strip down the pole.
      c.drawLine(Offset(x + 6, g.y(0.3)), Offset(x + 6, g.groundY), Paint()
        ..color = const Color(0xFF7D5A3A)
        ..strokeWidth = 1.6);
    }
  }

  void _line(Canvas c) {
    final g = geo;
    final arm = Paint()..color = _steel;
    c.drawRect(Rect.fromLTRB(M6PhotoGeo.lp - 30, g.armY - 3, M6PhotoGeo.rp + 30, g.armY + 3), arm);
    final wire = Paint()
      ..color = _wire
      ..strokeWidth = 1.4;
    for (final x in M6PhotoGeo.phaseX) {
      _pinInsulator(c, Offset(x, g.armY - 3));
    }
    for (final (i, x) in M6PhotoGeo.phaseX.indexed) {
      c.drawLine(Offset(0, g.armY - 14 - i * 2.0), Offset(360, g.armY - 13 - i * 2.0), wire);
      // The drop to the AB switch.
      c.drawLine(Offset(x, g.armY - 13), Offset(x, g.abY - 8), wire);
    }
  }

  void _pinInsulator(Canvas c, Offset base) {
    final p = Paint()..color = _porcelain;
    final e = Paint()
      ..color = _porcelainEdge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (var k = 0; k < 2; k++) {
      final r = Rect.fromCenter(center: base.translate(0, -4 - k * 5.0), width: 12 - k * 3.0, height: 4);
      c.drawOval(r, p);
      c.drawOval(r, e);
    }
  }

  void _abSwitch(Canvas c) {
    final g = geo;
    c.drawRect(Rect.fromLTRB(M6PhotoGeo.lp - 8, g.abY - 2, M6PhotoGeo.rp + 8, g.abY + 3), Paint()..color = _steel);
    final blade = Paint()
      ..color = const Color(0xFFB9C2C8)
      ..strokeWidth = 2.4;
    for (final x in M6PhotoGeo.phaseX) {
      _pinInsulator(c, Offset(x - 9, g.abY - 1));
      _pinInsulator(c, Offset(x + 9, g.abY - 1));
      // Closed: the blade lies across the two posts.
      c.drawLine(Offset(x - 9, g.abY - 12), Offset(x + 9, g.abY - 12), blade);
    }
    // The operating pipe down the left pole to the handle (locked).
    final pipe = Paint()
      ..color = const Color(0xFF59636B)
      ..strokeWidth = 2.2;
    c.drawLine(Offset(M6PhotoGeo.lp + 9, g.abY), Offset(M6PhotoGeo.lp + 9, g.y(0.86)), pipe);
    c.drawRect(Rect.fromCenter(center: Offset(M6PhotoGeo.lp + 9, g.y(0.86)), width: 14, height: 6), Paint()..color = const Color(0xFF3B4248));
  }

  void _hgFuses(Canvas c) {
    final g = geo;
    c.drawRect(Rect.fromLTRB(M6PhotoGeo.lp - 8, g.hgY - 2, M6PhotoGeo.rp + 8, g.hgY + 3), Paint()..color = _steel);
    final horn = Paint()
      ..color = const Color(0xFF9AA3A9)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    final wire = Paint()
      ..color = _wire
      ..strokeWidth = 1.4;
    for (final (i, x) in M6PhotoGeo.phaseX.indexed) {
      _pinInsulator(c, Offset(x - 8, g.hgY - 1));
      _pinInsulator(c, Offset(x + 8, g.hgY - 1));
      // Two horns in a V with the fuse wire across their feet.
      c.drawPath(Path()
        ..moveTo(x - 8, g.hgY - 12)
        ..quadraticBezierTo(x - 10, g.hgY - 22, x - 3, g.hgY - 28), horn);
      c.drawPath(Path()
        ..moveTo(x + 8, g.hgY - 12)
        ..quadraticBezierTo(x + 10, g.hgY - 22, x + 3, g.hgY - 28), horn);
      c.drawLine(Offset(x - 8, g.hgY - 12), Offset(x + 8, g.hgY - 12), Paint()
        ..color = const Color(0xFFB87333)
        ..strokeWidth = 1);
      c.drawLine(Offset(x, g.abY + 3), Offset(x, g.hgY - 12), wire);
      // The jumper down to the HT bushing.
      final top = Offset(g.htX[i], g.htTop - 2);
      c.drawPath(
          Path()
            ..moveTo(x + 8, g.hgY)
            ..quadraticBezierTo(x + 8, (g.hgY + top.dy) / 2, top.dx, top.dy),
          Paint()
            ..color = _wire
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4);
    }
  }

  void _platform(Canvas c) {
    final r = geo.platform;
    c.drawRect(r, Paint()..color = const Color(0xFF4E565D));
    c.drawRect(Rect.fromLTRB(r.left, r.top, r.right, r.top + 2), Paint()..color = const Color(0xFF6B747B));
  }

  void _fins(Canvas c, Rect r) {
    final back = Paint()..color = _tankB;
    c.drawRect(r, back);
    final fin = Paint()
      ..color = const Color(0xFF55675A)
      ..strokeWidth = 1.4;
    final hi = Paint()
      ..color = const Color(0x66C9D6CC)
      ..strokeWidth = 0.8;
    for (var x = r.left + 2; x < r.right - 1; x += 3.2) {
      c.drawLine(Offset(x, r.top + 2), Offset(x, r.bottom - 2), fin);
      c.drawLine(Offset(x + 1.2, r.top + 3), Offset(x + 1.2, r.bottom - 3), hi);
    }
    c.drawRect(Rect.fromLTRB(r.left, r.top, r.right, r.top + 2.5), Paint()..color = const Color(0xFF4C5D50));
    c.drawRect(Rect.fromLTRB(r.left, r.bottom - 2.5, r.right, r.bottom), Paint()..color = const Color(0xFF4C5D50));
  }

  void _tank(Canvas c) {
    final g = geo;
    final t = g.tank;
    c.drawRRect(RRect.fromRectAndRadius(t, const Radius.circular(3)),
        Paint()..shader = const LinearGradient(colors: [_tankB, _tankA, Color(0xFF7E9283), _tankB]).createShader(t));
    // The lid rim and the bolts.
    c.drawRect(Rect.fromLTRB(t.left - 3, t.top - 3, t.right + 3, t.top + 2), Paint()..color = const Color(0xFF5E7064));
    final bolt = Paint()..color = const Color(0xFF3F4D43);
    for (var x = t.left + 4; x < t.right; x += 10) {
      c.drawCircle(Offset(x, t.top - 0.5), 1.1, bolt);
    }
    // The drain valve.
    final v = g.drainValve;
    c.drawRect(Rect.fromCenter(center: v, width: 9, height: 7), Paint()..color = const Color(0xFF4A4F53));
    c.drawCircle(v.translate(0, 4), 2.2, Paint()..color = const Color(0xFF2F3437));
    // A leak: a dark wet streak from its source down the tank and the
    // platform, drops to the ground.
    if (look.wet) {
      final s = g.leakFrom(look.leakAt);
      final streak = Paint()
        ..color = _oil.withValues(alpha: 0.82)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      final bottom = look.leakAt == M6LeakAt.drain ? s.dy + 8 : t.bottom;
      c.drawLine(s, Offset(s.dx, bottom), streak);
      if (look.leakAt != M6LeakAt.drain) c.drawLine(Offset(s.dx, t.bottom), Offset(s.dx, g.platform.bottom), streak..strokeWidth = 2.2);
      final drop = Paint()..color = _oil.withValues(alpha: 0.7);
      for (var k = 0; k < 3; k++) {
        c.drawOval(Rect.fromCenter(center: Offset(s.dx, g.platform.bottom + 10 + k * (g.groundY - g.platform.bottom - 24) / 3), width: 2.6, height: 4.2), drop);
      }
    }
  }

  void _drum(Canvas c) {
    final g = geo;
    final d = g.drumBody;
    // Two legs from the lid.
    final leg = Paint()
      ..color = const Color(0xFF55675A)
      ..strokeWidth = 3;
    c.drawLine(Offset(d.left + 12, d.bottom), Offset(d.left + 12, g.tank.top - 2), leg);
    c.drawLine(Offset(d.right - 10, d.bottom), Offset(d.right - 10, g.tank.top - 2), leg);
    c.drawRRect(RRect.fromRectAndRadius(d, Radius.circular(d.height / 2)),
        Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFA5B7A9), _tankA, _tankB]).createShader(d));
    c.drawRRect(RRect.fromRectAndRadius(d, Radius.circular(d.height / 2)), Paint()
      ..color = const Color(0xFF4C5D50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1);
  }

  void _gauge(Canvas c) {
    final g = geo;
    final gl = g.gaugeGlass;
    c.drawRRect(RRect.fromRectAndRadius(gl.inflate(1.5), const Radius.circular(3)), Paint()..color = const Color(0xFF4C5D50));
    c.drawRRect(RRect.fromRectAndRadius(gl, const Radius.circular(2.5)), Paint()..color = const Color(0xFFEFF5F8));
    final maxY = gl.top + gl.height * 0.18;
    final minY = gl.top + gl.height * 0.82;
    final oilTop = look.gaugeLow ? minY + (gl.bottom - minY) * 0.45 : gl.top + gl.height * 0.48;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(gl.left + 1.5, oilTop, gl.right - 1.5, gl.bottom - 1.5), const Radius.circular(1.5)), Paint()..color = const Color(0xFFC7861E));
    c.drawLine(Offset(gl.left + 1.5, oilTop), Offset(gl.right - 1.5, oilTop), Paint()
      ..color = const Color(0xFF7A4B0C)
      ..strokeWidth = 1);
    final tick = Paint()
      ..color = const Color(0xFF22282C)
      ..strokeWidth = 1;
    c.drawLine(Offset(gl.left - 3, maxY), Offset(gl.right + 1, maxY), tick);
    c.drawLine(Offset(gl.left - 3, minY), Offset(gl.right + 1, minY), tick);
    _label(c, 'MAX', Offset(gl.left - 4, maxY), 5.6);
    _label(c, 'MIN', Offset(gl.left - 4, minY), 5.6);
  }

  /// Right-aligned label ending at [at] (vertically centred).
  void _label(Canvas c, String text, Offset at, double size, {Color color = const Color(0xFF22282C), bool left = false}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: FontWeight.w800, color: color, height: 1)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(left ? at.dx : at.dx - tp.width, at.dy - tp.height / 2));
  }

  void _breather(Canvas c) {
    final g = geo;
    final b = g.breather;
    // The pipe from the drum to the canister.
    c.drawPath(
        Path()
          ..moveTo(g.drumBody.left + 6, g.drumBody.bottom)
          ..lineTo(g.drumBody.left + 6, g.drumBody.bottom + 8)
          ..lineTo(b.center.dx, g.drumBody.bottom + 8)
          ..lineTo(b.center.dx, b.top - 3),
        Paint()
          ..color = const Color(0xFF55675A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2);
    c.drawRect(Rect.fromLTRB(b.left - 1, b.top - 4, b.right + 1, b.top + 1), Paint()..color = const Color(0xFF4C5D50));
    c.drawRect(Rect.fromLTRB(b.left - 1, b.bottom - 1, b.right + 1, b.bottom + 3), Paint()..color = const Color(0xFF4C5D50));
    c.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(3)), Paint()..color = const Color(0xFFEFF5F8));
    final (a, z) = switch (look.gel) {
      M6Gel.blue => (const Color(0xFF3D6FD6), const Color(0xFF2E58B8)),
      M6Gel.orange => (const Color(0xFFE88A2A), const Color(0xFFCF7417)),
      M6Gel.pink => (const Color(0xFFF2AFC4), const Color(0xFFE596AE)),
      M6Gel.white => (const Color(0xFFF4F1EA), const Color(0xFFDCD7CC)),
    };
    final rnd = math.Random(17);
    for (var yy = b.top + 3; yy < b.bottom - 2; yy += 3.4) {
      for (var xx = b.left + 2.6; xx < b.right - 1.5; xx += 3.4) {
        c.drawCircle(Offset(xx + rnd.nextDouble() * 0.8, yy), 1.5, Paint()..color = rnd.nextBool() ? a : z);
      }
    }
    c.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(3)), Paint()
      ..color = const Color(0x8899A6AD)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8);
  }

  void _bushings(Canvas c) {
    final g = geo;
    for (final (i, x) in g.htX.indexed) {
      _bushing(c, x, g.tank.top - 2, g.tank.top - 2 - g.htTop, 6, 7.5, look.bush == M6Bush.ht && i == look.faultBushing % 3);
    }
    for (final (i, x) in g.ltX.indexed) {
      _bushing(c, x, g.tank.top - 2, g.tank.top - 2 - g.ltTop, 2, 4.4, look.bush == M6Bush.lt && i == look.faultBushing % 4);
    }
  }

  /// A porcelain bushing: [sheds] sheds of half-width [shed] over a core.
  /// Every bushing carries one mark of the same size: a highlight streak when
  /// clean, a fine crack with a black flash mark when faulty.
  void _bushing(Canvas c, double x, double base, double tall, int sheds, double shed, bool faulty) {
    final core = Rect.fromLTRB(x - shed * 0.42, base - tall, x + shed * 0.42, base);
    c.drawRect(core, Paint()..color = const Color(0xFFCBD1D5));
    final fill = Paint()..color = _porcelain;
    final edge = Paint()
      ..color = _porcelainEdge
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    for (var k = 0; k < sheds; k++) {
      final yy = base - 3 - k * (tall - 6) / math.max(1, sheds - 1);
      final r = Rect.fromCenter(center: Offset(x, yy), width: shed * 2, height: 3.2);
      c.drawOval(r, fill);
      c.drawOval(r, edge);
    }
    // The terminal stud.
    c.drawRect(Rect.fromCenter(center: Offset(x, base - tall - 1.5), width: 2.4, height: 4), Paint()..color = const Color(0xFF8C6A3C));
    final mid = Offset(x, base - tall * 0.55);
    if (faulty) {
      c.drawOval(Rect.fromCenter(center: mid.translate(1, 1), width: shed * 1.3, height: math.max(5, tall * 0.28)), Paint()..color = const Color(0x99161616));
      c.drawPath(
          Path()
            ..moveTo(mid.dx - 1.5, mid.dy - tall * 0.2)
            ..lineTo(mid.dx + 1, mid.dy - tall * 0.05)
            ..lineTo(mid.dx - 1, mid.dy + tall * 0.08)
            ..lineTo(mid.dx + 1.5, mid.dy + tall * 0.2),
          Paint()
            ..color = const Color(0xFF111111)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.9);
    } else {
      c.drawOval(Rect.fromCenter(center: mid.translate(-1, 0), width: shed * 0.6, height: math.max(5, tall * 0.28)), Paint()..color = const Color(0x88FFFFFF));
    }
  }

  void _plate(Canvas c) {
    final p = geo.nameplate;
    c.drawRRect(RRect.fromRectAndRadius(p, const Radius.circular(1.5)), Paint()..color = const Color(0xFFCBD2D6));
    c.drawRRect(RRect.fromRectAndRadius(p, const Radius.circular(1.5)), Paint()
      ..color = const Color(0xFF5B6266)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8);
    // Dust in the corners (readable when the phone zooms in).
    c.drawRect(Rect.fromLTRB(p.left, p.bottom - 4, p.right, p.bottom), Paint()..color = const Color(0x33584A36));
    final rows = ['HV 11000 V', 'LV 415 V', '${look.kva} kVA', 'Sr ${look.serial}', 'Dyn11'];
    final step = (p.height - 4) / rows.length;
    for (final (i, r) in rows.indexed) {
      _label(c, r, Offset(p.left + 3, p.top + 2 + step * (i + 0.5)), math.min(5.4, step * 0.82), left: true, color: const Color(0xFF1F2427));
    }
    for (final at in [p.topLeft.translate(1.6, 1.6), p.topRight.translate(-1.6, 1.6), p.bottomLeft.translate(1.6, -1.6), p.bottomRight.translate(-1.6, -1.6)]) {
      c.drawCircle(at, 0.8, Paint()..color = const Color(0xFF5B6266));
    }
  }

  void _ground(Canvas c) {
    final r = geo.part(M6Part.stain);
    final patch = Rect.fromCenter(center: r.center.translate(0, 1), width: r.width * 0.92, height: r.height * 0.8);
    if (look.wet) {
      c.drawOval(patch, Paint()..color = _oil.withValues(alpha: 0.88));
      c.drawOval(Rect.fromCenter(center: patch.center.translate(-patch.width * 0.18, -2), width: patch.width * 0.3, height: 3), Paint()..color = const Color(0x55FFFFFF));
    } else {
      c.drawOval(patch, Paint()..color = const Color(0xFFCBB48A));
      final dust = Paint()..color = const Color(0x55856A43);
      final rnd = math.Random(5);
      for (var k = 0; k < 9; k++) {
        c.drawCircle(Offset(patch.left + 6 + rnd.nextDouble() * (patch.width - 12), patch.top + 3 + rnd.nextDouble() * (patch.height - 6)), 1.2, dust);
      }
      // A dry leaf.
      c.drawOval(Rect.fromCenter(center: patch.center.translate(patch.width * 0.22, 0), width: 9, height: 4), Paint()..color = const Color(0xFF9C7A3C));
    }
  }

  void _ltCables(Canvas c) {
    final g = geo;
    final cable = Paint()
      ..color = const Color(0xFF1E2226)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    for (final (i, x) in g.ltX.indexed) {
      c.drawPath(
          Path()
            ..moveTo(x, g.ltTop - 1)
            ..quadraticBezierTo(x - 8, g.ltTop - 10, M6PhotoGeo.lp + 12 + i * 1.6, g.ltTop + 4)
            ..lineTo(M6PhotoGeo.lp + 12 + i * 1.6, g.groundY),
          cable);
    }
  }

  @override
  bool shouldRepaint(M6DtrPainter old) => old.geo != geo || old.look != look || old.seed != seed;
}

/// The world painted through a crop (the phone's live view and the photos in
/// the tray): [crop] fills the box; with [cam] it follows the camera.
class M6CropPainter extends CustomPainter {
  M6CropPainter({required this.world, this.crop, this.cam}) : super(repaint: cam);

  final M6DtrPainter world;
  final Rect? crop;
  final ValueListenable<M6Cam>? cam;

  @override
  void paint(Canvas c, Size size) {
    final r = crop ?? cam?.value.frame;
    if (r == null || r.width <= 0) return;
    c.save();
    c.clipRect(Offset.zero & size);
    final s = math.max(size.width / r.width, size.height / r.height);
    c.translate((size.width - r.width * s) / 2, (size.height - r.height * s) / 2);
    c.scale(s);
    c.translate(-r.left, -r.top);
    world.paint(c, Size(360, world.geo.height));
    c.restore();
  }

  @override
  bool shouldRepaint(M6CropPainter old) => old.world != world || old.crop != crop || old.cam != cam;
}

/// The viewfinder on the scene: a soft veil outside the frame, white corner
/// brackets, a centre cross and the zoom. Its look never depends on what is
/// under it.
class M6FramePainter extends CustomPainter {
  M6FramePainter({required this.cam}) : super(repaint: cam);

  final ValueListenable<M6Cam> cam;

  @override
  void paint(Canvas c, Size size) {
    final cm = cam.value;
    final f = cm.frame;
    final veil = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addRect(f);
    c.drawPath(veil, Paint()..color = const Color(0x3D000000));
    final dark = Paint()
      ..color = const Color(0x66000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4;
    final white = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final l = math.min(16.0, f.shortestSide * 0.3);
    for (final p in [dark, white]) {
      c.drawPath(
          Path()
            ..moveTo(f.left, f.top + l)
            ..lineTo(f.left, f.top)
            ..lineTo(f.left + l, f.top)
            ..moveTo(f.right - l, f.top)
            ..lineTo(f.right, f.top)
            ..lineTo(f.right, f.top + l)
            ..moveTo(f.right, f.bottom - l)
            ..lineTo(f.right, f.bottom)
            ..lineTo(f.right - l, f.bottom)
            ..moveTo(f.left + l, f.bottom)
            ..lineTo(f.left, f.bottom)
            ..lineTo(f.left, f.bottom - l),
          p);
    }
    c.drawRect(f, Paint()
      ..color = const Color(0x66FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8);
    final cross = Paint()
      ..color = const Color(0xCCFFFFFF)
      ..strokeWidth = 1;
    c.drawLine(f.center.translate(-5, 0), f.center.translate(5, 0), cross);
    c.drawLine(f.center.translate(0, -5), f.center.translate(0, 5), cross);
  }

  @override
  bool shouldRepaint(M6FramePainter old) => old.cam != cam;
}

/// What a sound looks like on the phone's recorder: the steady hum, the hum
/// with knocks (খটখট-গরগর), the hum with sparking crackle (ছড়ছড়). [kind] null
/// = nothing heard yet (a flat line). [v] reveals it left to right.
class M6WavePainter extends CustomPainter {
  const M6WavePainter({required this.kind, this.v = 1});

  /// 0 hum, 1 rattle, 2 crackle; null = silence.
  final int? kind;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final r = Offset.zero & size;
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(10)), Paint()..color = const Color(0xF20B1A33));
    final mid = size.height / 2;
    c.drawLine(Offset(8, mid), Offset(size.width - 8, mid), Paint()
      ..color = const Color(0x33FFFFFF)
      ..strokeWidth = 1);
    final k = kind;
    if (k == null) return;
    final rnd = math.Random(40 + k);
    final path = Path()..moveTo(8, mid);
    final end = 8 + (size.width - 16) * v.clamp(0.0, 1.0);
    final amp = size.height * 0.32;
    var knock = 0.0;
    for (var x = 8.0; x <= end; x += 1.5) {
      final t = (x - 8) / 9;
      var yv = math.sin(t * 2.2) * amp * 0.38;
      if (k == 1) {
        if (knock <= 0 && rnd.nextDouble() < 0.05) knock = 1;
        yv += knock * amp * math.sin(t * 7) * 1.1;
        knock = math.max(0, knock - 0.12);
        yv += math.sin(t * 0.6) * amp * 0.22;
      } else if (k == 2) {
        if (rnd.nextDouble() < 0.35) yv += (rnd.nextDouble() * 2 - 1) * amp * 0.95;
      }
      path.lineTo(x, mid + yv);
    }
    c.drawPath(
        path,
        Paint()
          ..color = const Color(0xFF7FD3FF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(M6WavePainter old) => old.kind != kind || old.v != v;
}

/// The arc as the climber comes near the live HT side: a flash in colour off
/// the frozen grey scene.
class M6FlashPainter extends CustomPainter {
  const M6FlashPainter({required this.at, required this.v});
  final Offset at;
  final double v;

  @override
  void paint(Canvas c, Size size) {
    final r = 30 + 150 * v;
    c.drawCircle(at, r, Paint()
      ..shader = RadialGradient(colors: [
        Colors.white.withValues(alpha: (1 - v * 0.6).clamp(0.0, 1.0)),
        const Color(0xFF9FD8FF).withValues(alpha: (0.8 - v * 0.5).clamp(0.0, 1.0)),
        const Color(0x009FD8FF),
      ]).createShader(Rect.fromCircle(center: at, radius: r)));
    final bolt = Paint()
      ..color = Colors.white.withValues(alpha: (1 - v).clamp(0.0, 1.0))
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke;
    final rnd = math.Random(3);
    for (var k = 0; k < 5; k++) {
      final a = k * 1.25 + 0.4;
      var p = at;
      final path = Path()..moveTo(p.dx, p.dy);
      for (var s = 0; s < 4; s++) {
        p = p + Offset(math.cos(a), math.sin(a)) * (12 + 10 * v) + Offset(rnd.nextDouble() * 8 - 4, rnd.nextDouble() * 8 - 4);
        path.lineTo(p.dx, p.dy);
      }
      c.drawPath(path, bolt);
    }
  }

  @override
  bool shouldRepaint(M6FlashPainter old) => old.at != at || old.v != v;
}
