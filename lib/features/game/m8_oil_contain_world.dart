import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The drawn world of lesson 8.9 কাজ 2 "এক ফোঁটাও মাটিতে নয়" (m8_oil_contain.dart).
//
// Four stations, all in a 360-wide design space (the scene's height 560–900):
//  * oil: a village DTR plinth after a transformer change. The old transformer
//    lowered on the ground (electrical work finished: nothing live), its drain
//    valve on the dealt side; the van with গ্লাভস and a mask on its door; a
//    folded plastic sheet (four corners); an empty drum by the valve; later the
//    four destinations (a 'ডিসপোজাল সেন্টার' truck, a roadside drain, a paddy
//    field edge, the back of the store) in dealt places.
//  * store: a leaking drum on a rack, a floor drain, the wall with a sand
//    bucket, a sawdust sack, a hose and a broom (dealt order).
//  * battery: the battery-room door, a trolley of old batteries, a van with an
//    'অথরাইজড রিসাইক্লার' plate and a scrap cart ringing its bell (dealt sides).
//  * grass: the job-site grass, a rake, a scrap bag, cows at the field edge.
// No outline shows the drip zone, no tick shows a tight cap, offcuts stay
// hidden until raked. Text is real widgets in the page (plates), never painted.

enum M8Station { oil, store, battery, grass }

/// Where the sealed drum can be sent.
enum M8Dest { truck, drain, field, store }

/// The four things on the store wall.
enum M8Mat { sand, sawdust, hose, broom }

/// The two vehicles at the battery room.
enum M8Veh { van, cart }

enum M8Kit { gloves, mask }

// --- maths (pure) ---------------------------------------------------------------

double _cross(Offset o, Offset a, Offset b) => (a.dx - o.dx) * (b.dy - o.dy) - (a.dy - o.dy) * (b.dx - o.dx);

/// The convex hull of [pts] (monotone chain).
List<Offset> m8Hull(List<Offset> pts) {
  if (pts.length < 3) return [...pts];
  final p = [...pts]..sort((a, b) => a.dx != b.dx ? a.dx.compareTo(b.dx) : a.dy.compareTo(b.dy));
  final lo = <Offset>[];
  for (final q in p) {
    while (lo.length >= 2 && _cross(lo[lo.length - 2], lo.last, q) <= 0) {
      lo.removeLast();
    }
    lo.add(q);
  }
  final up = <Offset>[];
  for (final q in p.reversed) {
    while (up.length >= 2 && _cross(up[up.length - 2], up.last, q) <= 0) {
      up.removeLast();
    }
    up.add(q);
  }
  lo.removeLast();
  up.removeLast();
  return [...lo, ...up];
}

/// Is [q] inside the convex hull of the four sheet corners.
bool m8HullContains(List<Offset> pts, Offset q) {
  final h = m8Hull(pts);
  if (h.length < 3) return false;
  for (var i = 0; i < h.length; i++) {
    if (_cross(h[i], h[(i + 1) % h.length], q) < 0) return false;
  }
  return true;
}

/// The puddle's ellipse stops growing at this half-width; after it the oil
/// runs on as a tongue toward the drain.
const double m8StoreEllipseMax = 40;

/// Where things are (design px, 360 wide). [flip] mirrors the whole station
/// (the valve side at the DTR, the drain side in the store); [fx]/[fw] shift
/// and widen the old transformer's footprint.
@immutable
class M8Geo {
  const M8Geo._(this.height, this.gy, this.flip, this.fx, this.fw);

  factory M8Geo.forScene(double height, double inset, {bool flip = false, double fx = 0, double fw = 0}) =>
      M8Geo._(height, height - 290 - inset * 0.3, flip, fx, fw);

  final double height;

  /// The ground reference line.
  final double gy;
  final bool flip;
  final double fx;
  final double fw;

  double x(double v) => flip ? 360 - v : v;
  Offset _p(double px, double py) => Offset(x(px), py);
  Rect _r(double l, double t, double w, double h) => Rect.fromLTWH(flip ? 360 - l - w : l, t, w, h);

  // --- oil: the DTR yard ------------------------------------------------------------
  double get _trR => 146 + fx + 96 + fw;
  Rect get transformer => _r(146 + fx, gy - 76, 96 + fw, 70);
  Offset get valvePt => _p(_trR + 6, gy - 22);
  Rect get valveHit => Rect.fromCenter(center: valvePt, width: 46, height: 46);

  /// Where the oil drips (never drawn): under the valve and out to the drum.
  Rect get zone => _r(_trR - 30, gy - 4, 86, 52);

  /// The points the sheet must cover (the zone's corners and the middle of its
  /// two sides, a little inside).
  List<Offset> get zoneSamples {
    final z = zone.deflate(6);
    return [z.topLeft, z.topRight, z.bottomLeft, z.bottomRight, Offset(z.left, z.center.dy), Offset(z.right, z.center.dy)];
  }

  Rect get van => _r(4, gy - 104, 76, 96);
  Offset get glovesHome => _p(30, gy - 68);
  Offset get maskHome => _p(30, gy - 34);
  Offset kitHome(M8Kit k) => k == M8Kit.gloves ? glovesHome : maskHome;
  Rect kitHit(Offset c) => Rect.fromCenter(center: c, width: 46, height: 42);
  Rect get traineeRect => _r(90, gy - 108, 44, 104);
  Rect get wearZone => _r(76, gy - 126, 72, 128);

  /// The folded sheet's corners at home (TL, TR, BR, BL).
  List<Offset> get sheetHome => [_p(14, gy + 24), _p(52, gy + 24), _p(52, gy + 50), _p(14, gy + 50)];
  Rect get sheetStack => Rect.fromPoints(sheetHome[0], sheetHome[2]).inflate(10);

  /// A sheet corner stays on this ground.
  Rect get sheetBounds => Rect.fromLTRB(4, gy - 30, 356, gy + 104);
  Offset clampCorner(Offset p) => Offset(p.dx.clamp(sheetBounds.left, sheetBounds.right), p.dy.clamp(sheetBounds.top, sheetBounds.bottom));

  Rect get drum => _r(_trR - 7, gy + 4, 34, 50);
  Rect get drumHit => drum.inflate(8);
  Offset get capCentre => _p(_trR + 10, gy + 6);
  Rect get capHit => Rect.fromCenter(center: capCentre, width: 64, height: 56);

  Rect destSlot(int i) => Rect.fromLTWH(6 + 88.0 * i, gy + 60, 80, 50);

  /// The destination slot under [p], or -1.
  int destAt(Offset p) {
    for (var i = 0; i < 4; i++) {
      if (destSlot(i).inflate(6).contains(p)) return i;
    }
    return -1;
  }

  /// A neutral spot for the generic nudge on the kit.
  List<Rect> oilSweep() => [kitHit(glovesHome), kitHit(maskHome), valveHit, sheetStack];

  // --- store -----------------------------------------------------------------------------
  Rect matSlot(int i) => _r(16 + 82.0 * i, gy - 130, 70, 58);
  Rect get leakDrum => _r(40, gy - 50, 50, 58);
  Offset get leakPt => _p(70, gy + 36);
  Rect get floorDrain => _r(266, gy + 30, 56, 22);

  /// How far the oil can run before it reaches the drain.
  double get reachS => 190;

  double puddleHalf(double s) => math.min(s, m8StoreEllipseMax);

  /// The puddle's box now ([s] = its spread).
  Rect puddleRect(double s) {
    final r = puddleHalf(s);
    final ry = math.max(13.0, r * 0.5);
    return Rect.fromPoints(_p(70 - r, gy + 36 - ry), _p(70 + s, gy + 36 + ry));
  }

  /// A handful landing here (or its throw's end) is on the puddle.
  Rect flickZone(double s) => puddleRect(s).inflate(26);

  // --- battery -----------------------------------------------------------------------------
  Rect get trolley => Rect.fromLTWH(100, gy + 8, 160, 58);
  Offset batteryHome(int i) => Offset(134 + 46.0 * i, gy + 30);
  Rect batteryHit(Offset c) => Rect.fromCenter(center: c, width: 46, height: 42);
  Rect vehicle(int slot) => slot == 0 ? Rect.fromLTWH(4, gy - 118, 128, 86) : Rect.fromLTWH(228, gy - 118, 128, 86);
  Rect get batteryDoor => Rect.fromLTWH(144, gy - 140, 72, 108);
  Rect get batteryTrainee => Rect.fromLTWH(160, gy - 100, 44, 104);

  /// The vehicle slot under [p], or -1.
  int vehicleAt(Offset p) {
    for (var s = 0; s < 2; s++) {
      if (vehicle(s).inflate(8).contains(p)) return s;
    }
    return -1;
  }

  // --- grass ---------------------------------------------------------------------------------
  Rect get grass => Rect.fromLTWH(14, gy - 120, 332, 150);
  Rect get bag => Rect.fromLTWH(22, gy + 44, 60, 46);
  Rect get sweepBtn => Rect.fromLTWH(232, gy + 44, 108, 42);
  Offset offcutAt(double u, double v) {
    final g = grass.deflate(20);
    return Offset(g.left + u * g.width, g.top + v * g.height);
  }

  Rect offcutHit(Offset c) => Rect.fromCenter(center: c, width: 44, height: 40);

  /// A neutral strip a rake swipe may start on.
  Offset stripStart(int i) => Offset(grass.left + 28, grass.top + 22 + 44.0 * (i % 3));
  Rect get grassTrainee => Rect.fromLTWH(300, gy - 84, 44, 104);

  // --- the figures ------------------------------------------------------------------------
  Rect get storeTrainee => _r(140, gy - 104, 44, 104);

  /// The trainee's rect at [s].
  Rect trainee(M8Station s) => switch (s) {
        M8Station.oil => traineeRect,
        M8Station.store => storeTrainee,
        M8Station.battery => batteryTrainee,
        M8Station.grass => grassTrainee,
      };

  /// The act card (the consequence picture of listening to him).
  static const Rect actCard = Rect.fromLTWH(70, 138, 220, 130);

  @override
  bool operator ==(Object other) => other is M8Geo && other.height == height && other.gy == gy && other.flip == flip && other.fx == fx && other.fw == fw;

  @override
  int get hashCode => Object.hash(height, gy, flip, fx, fw);
}

/// What the painter shows now (the page builds a new one after every change).
class M8Rig {
  M8Rig({
    required this.station,
    this.dusk = false,
    // oil
    this.glovesOn = false,
    this.maskOn = false,
    this.kitDrag,
    this.kitDragAt,
    this.corners,
    this.stain = false,
    this.valveOpen = false,
    this.fill = 0,
    this.sealed = false,
    this.capTurn = 0,
    this.drumAt,
    this.destsUp = false,
    this.dests = const [],
    this.routed = false,
    // store
    this.mats = const [],
    this.selected,
    this.puddleS = 16,
    this.flicks = 0,
    this.flicksNeeded = 3,
    this.atDrain = false,
    this.sheen = false,
    this.covered = false,
    // battery
    this.vanSlot = 0,
    this.batteries = 2,
    this.loaded = const [],
    this.batDrag,
    this.batDragAt,
    // grass
    this.offcuts = const [],
    this.revealed = const [],
    this.bagged = const [],
    this.raked = const [],
    this.cow = 0,
    this.clean = false,
  });

  final M8Station station;
  final bool dusk;
  final bool glovesOn;
  final bool maskOn;
  final M8Kit? kitDrag;
  final Offset? kitDragAt;
  final List<Offset>? corners;
  final bool stain;
  final bool valveOpen;
  final double fill;
  final bool sealed;
  final double capTurn;
  final Offset? drumAt;
  final bool destsUp;
  final List<M8Dest> dests;
  final bool routed;
  final List<M8Mat> mats;
  final M8Mat? selected;
  final double puddleS;
  final int flicks;
  final int flicksNeeded;
  final bool atDrain;
  final bool sheen;
  final bool covered;
  final int vanSlot;
  final int batteries;
  final List<bool> loaded;
  final int? batDrag;
  final Offset? batDragAt;
  final List<Offset> offcuts;
  final List<bool> revealed;
  final List<bool> bagged;
  final List<List<Offset>> raked;
  final double cow;
  final bool clean;
}

const _steel = Color(0xFF6F7880);
const _steelDark = Color(0xFF454C53);
const _soilA = Color(0xFFA68B62);
const _soilB = Color(0xFF8B7350);
const _oil = Color(0xFF1B140F);
const _sheetBlue = Color(0xDD5BA8D6);
const _sand = Color(0xFFE0C98A);
const _grassA = Color(0xFF7DAE4F);
const _grassB = Color(0xFF5E9440);

Paint _fill(Color c) => Paint()..color = c;
Paint _line(Color c, double w) => Paint()
  ..color = c
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..style = PaintingStyle.stroke;

class M8Painter extends CustomPainter {
  M8Painter({required this.geo, required this.rig, required this.stroke}) : super(repaint: stroke);

  final M8Geo geo;
  final M8Rig rig;

  /// The rake stroke being drawn right now (repaints without a rebuild).
  final ValueListenable<List<Offset>> stroke;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final h = size.height;
    switch (rig.station) {
      case M8Station.oil:
        _sky(c, w, geo.gy - 74);
        _ground(c, w, h, geo.gy - 68, _soilA, _soilB);
        _oilYard(c, w);
      case M8Station.store:
        _wall(c, w, h);
        _store(c);
      case M8Station.battery:
        _wall(c, w, h);
        _batteryRoom(c);
      case M8Station.grass:
        _sky(c, w, geo.gy - 150);
        _ground(c, w, h, geo.gy - 130, _grassA, _grassB);
        _grassSite(c);
    }
    c.drawRect(Rect.fromLTWH(0, geo.gy + 114, w, h - geo.gy - 114), _fill(const Color(0x22000000)));
  }

  @override
  bool shouldRepaint(M8Painter old) => true;

  // --- shared backdrops ---------------------------------------------------------------
  void _sky(Canvas c, double w, double horizon) {
    final sky = Rect.fromLTWH(0, 0, w, horizon + 8);
    c.drawRect(
        sky,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: rig.dusk ? const [Color(0xFF36578A), Color(0xFFE8B98A), Color(0xFFEFD9B0)] : const [Color(0xFF4A86C4), Color(0xFFA5CDEB), Color(0xFFE6EFD9)],
          ).createShader(sky));
    final far = _fill(const Color(0xFF6C9A5A));
    final rnd = math.Random(5);
    for (var x = -10.0; x < w + 20; x += 15 + rnd.nextDouble() * 14) {
      final r = 7 + rnd.nextDouble() * 8;
      c.drawCircle(Offset(x, horizon - r * 0.3), r, far);
    }
  }

  void _ground(Canvas c, double w, double h, double top, Color a, Color b) {
    final r = Rect.fromLTWH(0, top, w, h - top);
    c.drawRect(r, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [a, b]).createShader(r));
  }

  void _wall(Canvas c, double w, double h) {
    final g = geo;
    final wall = Rect.fromLTWH(0, 0, w, g.gy - 10);
    c.drawRect(wall, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFD7D2C4), Color(0xFFBDB6A4)]).createShader(wall));
    for (var y = 120.0; y < g.gy - 14; y += 26) {
      c.drawLine(Offset(0, y), Offset(w, y), _line(const Color(0x14000000), 1));
    }
    final floor = Rect.fromLTWH(0, g.gy - 10, w, h - g.gy + 10);
    c.drawRect(floor, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF8E9195), Color(0xFF6A6E73)]).createShader(floor));
    c.drawRect(Rect.fromLTWH(0, g.gy - 12, w, 4), _fill(const Color(0xFF55595E)));
  }

  // --- the DTR yard ----------------------------------------------------------------------------
  void _oilYard(Canvas c, double w) {
    final g = geo;
    // The transformer on the ground (electrical work finished: nothing live).
    final t = g.transformer;
    c.drawRRect(RRect.fromRectAndRadius(t, const Radius.circular(5)), Paint()..shader = const LinearGradient(colors: [Color(0xFF8B969E), Color(0xFF5F6A72)]).createShader(t));
    for (var i = 1; i < 6; i++) {
      final fx = t.left + t.width * i / 6;
      c.drawLine(Offset(fx, t.top + 6), Offset(fx, t.bottom - 6), _line(const Color(0x33000000), 2));
    }
    c.drawRect(Rect.fromLTWH(t.left + 6, t.top - 8, 14, 10), _fill(_steelDark));
    c.drawRect(Rect.fromLTWH(t.right - 20, t.top - 8, 14, 10), _fill(_steelDark));
    // The drain valve and the pipe to the drum's mouth.
    final v = g.valvePt;
    final edge = geo.flip ? t.left : t.right;
    c.drawLine(Offset(edge, v.dy), v, _line(_steelDark, 6));
    c.drawCircle(v, 8, _fill(_steel));
    final across = Offset(geo.flip ? -14 : 14, 0);
    c.drawLine(v, v + (rig.valveOpen || rig.fill > 0 ? const Offset(0, 14) : across), _line(const Color(0xFFD94A2B), 4));
    // The sheet (under everything that stands on it).
    final cs = rig.corners ?? g.sheetHome;
    final folded = rig.corners == null;
    final path = Path();
    final hull = m8Hull(cs);
    if (hull.length >= 3) {
      path.moveTo(hull.first.dx, hull.first.dy);
      for (final p in hull.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      path.close();
      c.drawPath(path, _fill(folded ? const Color(0xFF4C93BF) : _sheetBlue));
      c.drawPath(path, _line(const Color(0xFF2E6C94), 1.6));
    }
    for (final p in cs) {
      c.drawCircle(p, folded ? 3.5 : 5, _fill(const Color(0xFF2E6C94)));
    }
    if (rig.stain) {
      c.drawOval(Rect.fromCenter(center: g.valvePt + const Offset(10, 40), width: 34, height: 14), _fill(const Color(0xCC1B140F)));
    }
    // The van with the kit on its door.
    final van = g.van;
    c.drawRRect(RRect.fromRectAndRadius(van, const Radius.circular(6)), _fill(const Color(0xFFE6E8EA)));
    c.drawRect(Rect.fromLTWH(van.left, van.bottom - 22, van.width, 14), _fill(const Color(0xFFC83A2C)));
    c.drawCircle(Offset(van.left + 16, van.bottom - 4), 8, _fill(const Color(0xFF22262B)));
    c.drawCircle(Offset(van.right - 16, van.bottom - 4), 8, _fill(const Color(0xFF22262B)));
    c.drawRect(Rect.fromLTWH(van.left + 8, van.top + 8, van.width - 16, 26), _fill(const Color(0xFF9FC4DD)));
    if (!rig.glovesOn && rig.kitDrag != M8Kit.gloves) _gloves(c, g.glovesHome);
    if (!rig.maskOn && rig.kitDrag != M8Kit.mask) _mask(c, g.maskHome);
    final kd = rig.kitDrag;
    final ka = rig.kitDragAt;
    if (kd != null && ka != null) {
      if (kd == M8Kit.gloves) {
        _gloves(c, ka);
      } else {
        _mask(c, ka);
      }
    }
    // The drum by the valve; it fills.
    _drum(c, rig.drumAt == null ? g.drum : g.drum.shift(rig.drumAt! - g.drum.center), rig.fill, rig.sealed);
    if (rig.valveOpen) {
      final mouth = g.capCentre;
      c.drawLine(v + const Offset(0, 8), Offset(v.dx, mouth.dy), _line(_oil, 4));
    }
    // The four destinations once the drum is sealed.
    if (rig.destsUp) {
      for (var i = 0; i < 4 && i < rig.dests.length; i++) {
        _dest(c, g.destSlot(i), rig.dests[i]);
      }
    }
  }

  void _gloves(Canvas c, Offset at) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: at, width: 26, height: 24), const Radius.circular(7)), _fill(const Color(0xFFC62828)));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: at + const Offset(0, 13), width: 20, height: 7), const Radius.circular(2)), _fill(const Color(0xFF8E1B1B)));
    for (var i = -1; i <= 1; i++) {
      c.drawLine(at + Offset(i * 6.0, -4), at + Offset(i * 6.0, -11), _line(const Color(0xFFC62828), 4));
    }
  }

  void _mask(Canvas c, Offset at) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: at, width: 30, height: 20), const Radius.circular(9)), _fill(const Color(0xFFEFF3F6)));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: at, width: 30, height: 20), const Radius.circular(9)), _line(const Color(0xFF9AA7B0), 1.5));
    c.drawLine(at + const Offset(-15, -2), at + const Offset(-21, -8), _line(const Color(0xFF9AA7B0), 1.5));
    c.drawLine(at + const Offset(15, -2), at + const Offset(21, -8), _line(const Color(0xFF9AA7B0), 1.5));
  }

  void _drum(Canvas c, Rect r, double fill, bool sealed) {
    final body = RRect.fromRectAndRadius(r, const Radius.circular(4));
    c.drawRRect(body, Paint()..shader = const LinearGradient(colors: [Color(0xFF3F6BA6), Color(0xFF244A7E)]).createShader(r));
    c.drawLine(Offset(r.left + 1, r.top + r.height * 0.33), Offset(r.right - 1, r.top + r.height * 0.33), _line(const Color(0x55000000), 2));
    c.drawLine(Offset(r.left + 1, r.top + r.height * 0.66), Offset(r.right - 1, r.top + r.height * 0.66), _line(const Color(0x55000000), 2));
    // A thin level window.
    final win = Rect.fromLTWH(r.right - 9, r.top + 8, 5, r.height - 16);
    c.drawRect(win, _fill(const Color(0xFFD9DEE3)));
    if (fill > 0) c.drawRect(Rect.fromLTWH(win.left, win.bottom - win.height * fill, win.width, win.height * fill), _fill(_oil));
    c.drawOval(Rect.fromLTWH(r.left, r.top - 4, r.width, 9), _fill(const Color(0xFF557EB4)));
    c.drawCircle(Offset(r.center.dx, r.top), 5.5, _fill(sealed ? const Color(0xFF22262B) : const Color(0xFF8A9199)));
    if (!sealed && fill >= 1) c.drawLine(Offset(r.center.dx - 4, r.top - 2), Offset(r.center.dx + 5, r.top - 6), _line(const Color(0xFF8A9199), 2));
  }

  void _dest(Canvas c, Rect r, M8Dest d) {
    switch (d) {
      case M8Dest.truck:
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.left + 4, r.top + 6, 50, 30), const Radius.circular(3)), _fill(const Color(0xFFF2F2F0)));
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.left + 54, r.top + 14, 22, 22), const Radius.circular(3)), _fill(const Color(0xFF2E7D4F)));
        c.drawRect(Rect.fromLTWH(r.left + 4, r.top + 30, 72, 5), _fill(const Color(0xFF2E7D4F)));
        c.drawCircle(Offset(r.left + 18, r.top + 38), 6, _fill(const Color(0xFF22262B)));
        c.drawCircle(Offset(r.left + 62, r.top + 38), 6, _fill(const Color(0xFF22262B)));
      case M8Dest.drain:
        final g = Rect.fromLTWH(r.left + 6, r.top + 14, 68, 24);
        c.drawRRect(RRect.fromRectAndRadius(g, const Radius.circular(3)), _fill(const Color(0xFF5E6368)));
        for (var x = g.left + 6; x < g.right - 4; x += 8) {
          c.drawLine(Offset(x, g.top + 3), Offset(x, g.bottom - 3), _line(const Color(0xFF1E2124), 2.4));
        }
      case M8Dest.field:
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.left + 2, r.top + 8, r.width - 4, 34), const Radius.circular(4)), _fill(const Color(0xFF8DBB5A)));
        for (var x = r.left + 8; x < r.right - 6; x += 9) {
          c.drawLine(Offset(x, r.top + 40), Offset(x - 2, r.top + 22), _line(const Color(0xFF4F8A34), 2));
          c.drawLine(Offset(x + 3, r.top + 40), Offset(x + 5, r.top + 24), _line(const Color(0xFF63A140), 2));
        }
        c.drawRect(Rect.fromLTWH(r.left + 2, r.top + 40, r.width - 4, 4), _fill(const Color(0xFF6E5A3C)));
      case M8Dest.store:
        c.drawRect(Rect.fromLTWH(r.left + 8, r.top + 4, 64, 40), _fill(const Color(0xFFCFC3A8)));
        c.drawRect(Rect.fromLTWH(r.left + 8, r.top, 64, 6), _fill(const Color(0xFF8A4B38)));
        c.drawRect(Rect.fromLTWH(r.left + 30, r.top + 16, 20, 28), _fill(const Color(0xFF5B4630)));
        c.drawCircle(Offset(r.left + 46, r.top + 32), 1.8, _fill(const Color(0xFFE6C44B)));
    }
  }

  // --- the store ---------------------------------------------------------------------------------
  void _store(Canvas c) {
    final g = geo;
    // The wall rack with the four things (dealt order).
    final shelf = Rect.fromLTWH(0, g.gy - 76, 360, 6);
    c.drawRect(shelf, _fill(const Color(0xFF6E5A3C)));
    for (var i = 0; i < 4 && i < rig.mats.length; i++) {
      final m = rig.mats[i];
      final r = g.matSlot(i);
      final picked = rig.selected == m;
      switch (m) {
        case M8Mat.sand:
          c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.left + 14, r.top + 16, 42, 42), const Radius.circular(5)), _fill(const Color(0xFF9A5B2E)));
          c.drawOval(Rect.fromLTWH(r.left + 14, r.top + 10, 42, 14), _fill(_sand));
          c.drawArc(Rect.fromLTWH(r.left + 14, r.top + 2, 42, 26), math.pi, math.pi, false, _line(const Color(0xFF6E3F1D), 3));
        case M8Mat.sawdust:
          c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.left + 12, r.top + 8, 46, 50), const Radius.circular(8)), _fill(const Color(0xFFD8BE8C)));
          c.drawLine(Offset(r.left + 14, r.top + 18), Offset(r.left + 56, r.top + 18), _line(const Color(0xFF8A6B3A), 2.6));
          c.drawCircle(Offset(r.center.dx, r.top + 38), 8, _fill(const Color(0xFFBCA06A)));
        case M8Mat.hose:
          c.drawCircle(r.center + const Offset(0, 4), 22, _line(const Color(0xFF2E8B57), 7));
          c.drawCircle(r.center + const Offset(0, 4), 12, _line(const Color(0xFF2E8B57), 6));
          c.drawLine(r.center + const Offset(18, 18), r.center + const Offset(32, 26), _line(const Color(0xFF2E8B57), 5));
        case M8Mat.broom:
          c.drawLine(Offset(r.center.dx, r.top + 2), Offset(r.center.dx, r.top + 40), _line(const Color(0xFF8A6B3A), 4));
          final bush = Path()
            ..moveTo(r.center.dx - 4, r.top + 38)
            ..lineTo(r.center.dx + 4, r.top + 38)
            ..lineTo(r.center.dx + 16, r.top + 58)
            ..lineTo(r.center.dx - 16, r.top + 58)
            ..close();
          c.drawPath(bush, _fill(const Color(0xFFC9A94B)));
      }
      if (picked) c.drawRRect(RRect.fromRectAndRadius(r.deflate(2), const Radius.circular(8)), _line(const Color(0xFFFFD34E), 3));
    }
    // The floor drain.
    final fd = g.floorDrain;
    c.drawRRect(RRect.fromRectAndRadius(fd, const Radius.circular(3)), _fill(const Color(0xFF3F4347)));
    for (var x = fd.left + 6; x < fd.right - 3; x += 7) {
      c.drawLine(Offset(x, fd.top + 3), Offset(x, fd.bottom - 3), _line(const Color(0xFF15181B), 2.4));
    }
    // The rack and the leaking drum.
    final d = g.leakDrum;
    c.drawRect(Rect.fromLTWH(d.left - 8, d.bottom, d.width + 16, 5), _fill(const Color(0xFF6E5A3C)));
    c.drawRect(Rect.fromLTWH(d.left - 4, d.bottom + 5, 4, 10), _fill(const Color(0xFF6E5A3C)));
    c.drawRect(Rect.fromLTWH(d.right, d.bottom + 5, 4, 10), _fill(const Color(0xFF6E5A3C)));
    _drum(c, d, 0, true);
    c.drawLine(Offset(d.center.dx, d.bottom - 12), Offset(d.center.dx, g.leakPt.dy - 6), _line(_oil, 2.4));
    // The puddle: an ellipse that runs on as a tongue toward the drain.
    final pr = g.puddleRect(rig.puddleS);
    final rr = RRect.fromRectAndRadius(pr, Radius.circular(pr.height / 2));
    c.drawRRect(rr, _fill(rig.covered || rig.flicks > 0 ? const Color(0xFF3A2E22) : const Color(0xE61B140F)));
    if (!rig.covered && rig.flicks == 0) {
      c.drawOval(Rect.fromCenter(center: pr.center + const Offset(-4, -2), width: pr.width * 0.4, height: pr.height * 0.3), _fill(const Color(0x33FFFFFF)));
    }
    // Sand over it, a layer per handful.
    final cover = rig.covered ? 1.0 : (rig.flicksNeeded == 0 ? 0.0 : rig.flicks / rig.flicksNeeded);
    if (rig.flicks > 0) {
      final rnd = math.Random(3);
      final n = (rig.covered ? 70 : 70 * cover).round();
      for (var i = 0; i < n; i++) {
        final px = pr.left + 6 + rnd.nextDouble() * (pr.width - 12);
        final py = pr.top + 4 + rnd.nextDouble() * (pr.height - 8);
        c.drawCircle(Offset(px, py), 3 + rnd.nextDouble() * 3, _fill(rnd.nextBool() ? _sand : const Color(0xFFC9AE72)));
      }
    }
    if (rig.sheen) {
      c.drawRRect(RRect.fromRectAndRadius(pr.inflate(10), Radius.circular(pr.height)), _line(const Color(0x995BA8D6), 3));
    }
    if (rig.atDrain) c.drawCircle(Offset(fd.left + 6, fd.center.dy), 6, _fill(const Color(0xFF1B140F)));
  }

  // --- the battery room -----------------------------------------------------------------------------
  void _batteryRoom(Canvas c) {
    final g = geo;
    // The battery-room door in the middle.
    final door = g.batteryDoor;
    c.drawRect(door.inflate(6), _fill(const Color(0xFF8D8776)));
    c.drawRect(door, _fill(const Color(0xFF4F5E6B)));
    c.drawLine(Offset(door.center.dx, door.top), Offset(door.center.dx, door.bottom), _line(const Color(0x55000000), 2));
    c.drawCircle(Offset(door.right - 10, door.center.dy), 3, _fill(const Color(0xFFE6C44B)));
    c.drawPath(
        Path()
          ..moveTo(door.center.dx, door.top + 14)
          ..lineTo(door.center.dx - 12, door.top + 36)
          ..lineTo(door.center.dx + 12, door.top + 36)
          ..close(),
        _fill(const Color(0xFFE6C44B)));
    // The two vehicles on their dealt sides.
    final vanSlot = rig.vanSlot;
    _recycler(c, g.vehicle(vanSlot));
    _cart(c, g.vehicle(1 - vanSlot));
    // The trolley and the batteries.
    final t = g.trolley;
    c.drawRRect(RRect.fromRectAndRadius(t, const Radius.circular(4)), _fill(const Color(0xFF6B7078)));
    c.drawRect(Rect.fromLTWH(t.left + 4, t.bottom - 8, t.width - 8, 4), _fill(const Color(0xFF3F4347)));
    c.drawCircle(Offset(t.left + 20, t.bottom + 6), 7, _fill(const Color(0xFF22262B)));
    c.drawCircle(Offset(t.right - 20, t.bottom + 6), 7, _fill(const Color(0xFF22262B)));
    c.drawLine(Offset(t.left, t.top), Offset(t.left - 14, t.top - 30), _line(const Color(0xFF3F4347), 4));
    for (var i = 0; i < rig.batteries; i++) {
      if (i < rig.loaded.length && rig.loaded[i]) continue;
      final at = rig.batDrag == i && rig.batDragAt != null ? rig.batDragAt! : g.batteryHome(i);
      _battery(c, at);
    }
  }

  void _battery(Canvas c, Offset at) {
    final r = Rect.fromCenter(center: at, width: 36, height: 28);
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), _fill(const Color(0xFF30363D)));
    c.drawRect(Rect.fromLTWH(r.left + 5, r.top - 4, 8, 5), _fill(const Color(0xFFB0B7BE)));
    c.drawRect(Rect.fromLTWH(r.right - 13, r.top - 4, 8, 5), _fill(const Color(0xFFB0B7BE)));
    c.drawRect(Rect.fromLTWH(r.left + 4, r.top + 8, r.width - 8, 6), _fill(const Color(0xFFD9B73A)));
    c.drawLine(Offset(r.left + 8, r.bottom - 4), Offset(r.left + 14, r.bottom - 4), _line(const Color(0xFFB0B7BE), 2));
  }

  void _recycler(Canvas c, Rect r) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.left + 4, r.top + 6, 90, 56), const Radius.circular(5)), _fill(const Color(0xFFF2F2F0)));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(r.left + 94, r.top + 24, 28, 38), const Radius.circular(5)), _fill(const Color(0xFF2E7D4F)));
    c.drawRect(Rect.fromLTWH(r.left + 98, r.top + 28, 20, 14), _fill(const Color(0xFF9FC4DD)));
    c.drawRect(Rect.fromLTWH(r.left + 4, r.top + 52, 118, 8), _fill(const Color(0xFF2E7D4F)));
    c.drawCircle(Offset(r.left + 26, r.top + 66), 9, _fill(const Color(0xFF22262B)));
    c.drawCircle(Offset(r.left + 100, r.top + 66), 9, _fill(const Color(0xFF22262B)));
  }

  void _cart(Canvas c, Rect r) {
    // A scrap cart, its bell ringing, a man waving cash.
    c.drawRect(Rect.fromLTWH(r.left + 10, r.top + 30, 84, 28), _fill(const Color(0xFF7B5A3A)));
    c.drawRect(Rect.fromLTWH(r.left + 6, r.top + 22, 92, 8), _fill(const Color(0xFF5E4429)));
    c.drawCircle(Offset(r.left + 28, r.top + 66), 12, _line(const Color(0xFF22262B), 4));
    c.drawCircle(Offset(r.left + 76, r.top + 66), 12, _line(const Color(0xFF22262B), 4));
    c.drawLine(Offset(r.left + 94, r.top + 30), Offset(r.left + 112, r.top + 10), _line(const Color(0xFF5E4429), 4));
    c.drawPath(
        Path()
          ..moveTo(r.left + 106, r.top + 4)
          ..lineTo(r.left + 118, r.top + 4)
          ..lineTo(r.left + 122, r.top + 14)
          ..lineTo(r.left + 102, r.top + 14)
          ..close(),
        _fill(const Color(0xFFE6C44B)));
    c.drawArc(Rect.fromLTWH(r.left + 96, r.top - 4, 30, 18), math.pi * 1.1, math.pi * 0.8, false, _line(const Color(0xFFE6C44B), 1.6));
    // The man: a head, a shirt, an arm up with a note.
    final mx = r.left + 52;
    c.drawCircle(Offset(mx, r.top - 6), 7, _fill(const Color(0xFFA86E48)));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(mx - 8, r.top, 16, 24), const Radius.circular(4)), _fill(const Color(0xFFB4492B)));
    c.drawLine(Offset(mx + 6, r.top + 4), Offset(mx + 18, r.top - 12), _line(const Color(0xFFA86E48), 4));
    c.drawRect(Rect.fromLTWH(mx + 14, r.top - 24, 14, 9), _fill(const Color(0xFF6BBF6A)));
  }

  // --- the grass ------------------------------------------------------------------------------------------
  void _grassSite(Canvas c) {
    final g = geo;
    final gr = g.grass;
    c.drawRRect(RRect.fromRectAndRadius(gr, const Radius.circular(10)), Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF86BA55), Color(0xFF6BA244)]).createShader(gr));
    final rnd = math.Random(8);
    for (var i = 0; i < 90; i++) {
      final px = gr.left + 6 + rnd.nextDouble() * (gr.width - 12);
      final py = gr.top + 6 + rnd.nextDouble() * (gr.height - 12);
      c.drawLine(Offset(px, py), Offset(px - 2, py - 7), _line(const Color(0xFF4F8A34), 1.6));
    }
    // The rake's strokes: lighter lines where it has passed.
    for (final s in rig.raked) {
      if (s.length > 1) _rakeLine(c, s);
    }
    final live = stroke.value;
    if (live.length > 1) _rakeLine(c, live);
    // Offcuts: revealed and not yet in the bag.
    for (var i = 0; i < rig.offcuts.length; i++) {
      if (i < rig.revealed.length && rig.revealed[i] && !rig.bagged[i]) _offcut(c, rig.offcuts[i], i);
    }
    // Cows at the field edge, a step closer with every step done.
    for (var k = 0; k < 2; k++) {
      final cx = 70 + 190.0 * k + (k == 0 ? 60 : -60) * rig.cow;
      final cy = gr.top - 18 + 54 * rig.cow + (k == 1 ? 8 : 0);
      _cow(c, Offset(cx, cy), k == 1);
    }
    // The scrap bag and the rake.
    final b = g.bag;
    c.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(10)), _fill(const Color(0xFF8C8F93)));
    c.drawPath(
        Path()
          ..moveTo(b.left + 12, b.top)
          ..quadraticBezierTo(b.center.dx, b.top - 14, b.right - 12, b.top)
          ..lineTo(b.right - 18, b.top + 10)
          ..lineTo(b.left + 18, b.top + 10)
          ..close(),
        _fill(const Color(0xFF6E7176)));
    final inBag = rig.bagged.where((x) => x).length;
    for (var i = 0; i < inBag; i++) {
      c.drawLine(Offset(b.left + 14 + 8.0 * i, b.top + 18), Offset(b.left + 22 + 8.0 * i, b.top + 30), _line(const Color(0xFFD9B73A), 2.6));
    }
    c.drawLine(Offset(112, g.gy + 86), Offset(176, g.gy + 40), _line(const Color(0xFF8A6B3A), 4));
    c.drawLine(Offset(170, g.gy + 38), Offset(190, g.gy + 50), _line(const Color(0xFF55595E), 5));
    for (var i = 0; i < 4; i++) {
      c.drawLine(Offset(172 + 5.0 * i, g.gy + 44 + 2.5 * i), Offset(176 + 5.0 * i, g.gy + 56 + 2.5 * i), _line(const Color(0xFF55595E), 2));
    }
  }

  void _rakeLine(Canvas c, List<Offset> pts) {
    final p = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (final q in pts.skip(1)) {
      p.lineTo(q.dx, q.dy);
    }
    c.drawPath(
        p,
        Paint()
          ..color = const Color(0x55D9E8B0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 16
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);
  }

  void _offcut(Canvas c, Offset at, int i) {
    final a = (i * 1.3) % math.pi;
    final d = Offset(math.cos(a), math.sin(a)) * 9;
    c.drawLine(at - d, at + d, _line(i.isEven ? const Color(0xFFD9B73A) : const Color(0xFFB87333), 3.4));
    c.drawLine(at - d + const Offset(0, 4), at + d * 0.4 + const Offset(0, 5), _line(i.isEven ? const Color(0xFFE8CE6A) : const Color(0xFFD99560), 2));
    c.drawCircle(at + d, 2.2, _fill(const Color(0xFFFFFFFF)));
  }

  void _cow(Canvas c, Offset at, bool dark) {
    final body = dark ? const Color(0xFF5B4636) : const Color(0xFFEDE6D8);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: at, width: 38, height: 20), const Radius.circular(9)), _fill(body));
    c.drawCircle(at + const Offset(-20, -4), 8, _fill(body));
    c.drawCircle(at + const Offset(-23, -6), 1.3, _fill(const Color(0xFF22262B)));
    for (final dx in [-12.0, -4.0, 6.0, 14.0]) {
      c.drawLine(at + Offset(dx, 8), at + Offset(dx, 18), _line(const Color(0xFF3B3028), 2.6));
    }
    if (!dark) c.drawCircle(at + const Offset(4, -2), 5, _fill(const Color(0xFF6B5B4A)));
  }
}

/// The consequence picture of listening to him (a card over the scene).
class M8ActCard extends StatelessWidget {
  const M8ActCard({super.key, required this.hose});

  /// false = the oil poured on the field; true = the hose turned on the spill.
  final bool hose;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: M8Geo.actCard.width,
        height: M8Geo.actCard.height,
        child: CustomPaint(painter: _ActPainter(hose: hose)),
      );
}

class _ActPainter extends CustomPainter {
  _ActPainter({required this.hose});
  final bool hose;

  @override
  void paint(Canvas c, Size s) {
    final card = RRect.fromRectAndRadius(Offset.zero & s, const Radius.circular(12));
    c.drawRRect(card, _fill(const Color(0xFFFDF8EC)));
    c.drawRRect(card, _line(const Color(0xFFC48A2E), 3));
    if (!hose) {
      // Oil poured on the field: the grass dies where it fell, the soil below goes dark.
      c.drawRect(Rect.fromLTWH(10, 70, s.width - 20, 18), _fill(const Color(0xFF6BA244)));
      c.drawRect(Rect.fromLTWH(10, 88, s.width - 20, 34), _fill(const Color(0xFF8B7350)));
      c.drawRect(Rect.fromLTWH(110, 70, 90, 18), _fill(const Color(0xFFB8A66A)));
      c.drawRect(Rect.fromLTWH(104, 88, 102, 30), _fill(const Color(0xFF2B2018)));
      c.drawPath(
          Path()
            ..moveTo(40, 34)
            ..lineTo(96, 24)
            ..lineTo(104, 44)
            ..lineTo(48, 54)
            ..close(),
          _fill(const Color(0xFF2F5C9A)));
      c.drawLine(const Offset(98, 40), const Offset(150, 68), _line(const Color(0xFF1B140F), 5));
    } else {
      // The hose on the spill: the oil spreads wider.
      c.drawRect(Rect.fromLTWH(10, 84, s.width - 20, 36), _fill(const Color(0xFF8E9195)));
      c.drawOval(Rect.fromLTWH(40, 92, s.width - 80, 22), _fill(const Color(0xCC1B140F)));
      c.drawLine(const Offset(30, 30), const Offset(90, 60), _line(const Color(0xFF2E8B57), 6));
      for (var i = 0; i < 5; i++) {
        c.drawLine(Offset(94 + i * 6.0, 62 + i * 4.0), Offset(112 + i * 9.0, 84), _line(const Color(0xAA5BA8D6), 2.4));
      }
    }
  }

  @override
  bool shouldRepaint(_ActPainter old) => old.hose != hose;
}
