import 'dart:math' as math;

import 'package:flutter/material.dart';

// The drawn world of lesson 8.7 কাজ "দিনভর নজর" (m8_day_dial.dart): a
// meter-reading round along a village-market road, one premises per stop.
// Six kinds of premises are drawn (four of them dealt a play, the factory
// always): a house, a house with a front-room shop (its fridge runs in one
// dealt hour), a roadside shop, a field pump house, a pump house where a car
// is washed in one dealt hour, and a small factory.
//
// Above each premises a sky arc runs from dawn (left) to midnight (right) with
// a draggable sun that becomes the moon. Sky, shadows and lights follow the
// sun continuously; what runs at the premises depends on the hour (the "zone"
// the sun is in: morning, noon, evening, night). The zones are never labelled
// or marked. Nothing is ringed, captioned or brighter: the house with the shop
// fridge and the house with a home fridge look alike except for the counter,
// the shutter, the customer and the bottles that live in one dealt hour.
//
// Only words a worker reads are painted by widgets on the page (the meter
// card 'Type of Consumer: …', the bill clip lines); the painters here draw no
// text. Code-drawn with gradients; the mistake pictures are SVG.
//
// Design: 360 wide × the scene's height. The reading book (a widget on the
// page) stands on the bottom edge; the premises stand on a ground line well
// above it so the corner guide and his bubble never hide a part.

/// The four parts of the day (sun position → zone). Never labelled.
enum M8DayZone { morning, noon, evening, night }

/// What a premises really uses power for.
enum M8DayUse { domestic, commercial, agri }

/// The premises kinds.
enum M8DayKind { house, fridgeHouse, shop, pump, carPump, factory }

/// What can be seen running (drawn only in the zones it is dealt to).
enum M8DayAct {
  // house
  fan,
  tv,
  lamp,
  kitchen,
  doorOpen,
  homeFridge,
  nightLamp,
  // the front-room shop (misuse)
  shopOpen,
  // shop
  shopFridge,
  customer,
  // pump
  irrigate,
  carWash,
  // factory
  machine,
}

/// The meter card of a premises (the factory has none).
M8DayUse? m8DayCardOf(M8DayKind k) => switch (k) {
      M8DayKind.house || M8DayKind.fridgeHouse => M8DayUse.domestic,
      M8DayKind.shop => M8DayUse.commercial,
      M8DayKind.pump || M8DayKind.carPump => M8DayUse.agri,
      M8DayKind.factory => null,
    };

/// What really runs, whatever the card says (the factory has no stamp).
M8DayUse? m8DayTruthOf(M8DayKind k) => switch (k) {
      M8DayKind.fridgeHouse || M8DayKind.carPump => M8DayUse.commercial,
      _ => m8DayCardOf(k),
    };

/// A premises where the card and what runs differ in one dealt hour.
bool m8DayIsMisuse(M8DayKind k) => k == M8DayKind.fridgeHouse || k == M8DayKind.carPump;

/// A zone's sun-time range: [lo, hi).
(double, double) m8DayRange(M8DayZone z) => switch (z) {
      M8DayZone.morning => (0.0, 0.26),
      M8DayZone.noon => (0.26, 0.52),
      M8DayZone.evening => (0.52, 0.76),
      M8DayZone.night => (0.76, 1.0001),
    };

M8DayZone m8DayZoneOf(double t) {
  for (final z in M8DayZone.values) {
    final (lo, hi) = m8DayRange(z);
    if (t >= lo && t < hi) return z;
  }
  return t < 0 ? M8DayZone.morning : M8DayZone.night;
}

double m8DayMid(M8DayZone z) {
  final (lo, hi) = m8DayRange(z);
  return (lo + math.min(hi, 1.0)) / 2;
}

/// Sun-time t → arc position a (the sun stands at the top at t ≈ 0.39, the
/// middle of "noon"; both 0..1).
double m8DayArcA(double t) => t <= 0.39 ? t / 0.39 * 0.5 : 0.5 + (t - 0.39) / 0.61 * 0.5;
double m8DayTOfA(double a) => a <= 0.5 ? a / 0.5 * 0.39 : 0.39 + (a - 0.5) / 0.5 * 0.61;

double _lerpKeys(List<(double, double)> k, double t) {
  if (t <= k.first.$1) return k.first.$2;
  for (var i = 1; i < k.length; i++) {
    if (t <= k[i].$1) {
      final f = (t - k[i - 1].$1) / (k[i].$1 - k[i - 1].$1);
      return k[i - 1].$2 + (k[i].$2 - k[i - 1].$2) * f;
    }
  }
  return k.last.$2;
}

/// How dark it is at sun-time t (0 = full day, ~0.8 = deep night).
double m8DayDark(double t) => _lerpKeys(const [(0, 0.40), (0.10, 0.0), (0.55, 0.0), (0.65, 0.18), (0.74, 0.46), (0.84, 0.70), (1, 0.78)], t);

/// One dealt premises.
@immutable
class M8DayStop {
  const M8DayStop({required this.kind, required this.variant, this.misuseZone, this.pf = false, this.mirror = false});

  final M8DayKind kind;

  /// Which pattern the honest hours follow (0..2).
  final int variant;

  /// The one hour the misuse runs (fridge house, car wash); null otherwise.
  final M8DayZone? misuseZone;

  /// The factory's bill shows a PF penalty.
  final bool pf;

  /// Drawn mirrored.
  final bool mirror;

  M8DayUse? get card => m8DayCardOf(kind);
  M8DayUse? get truth => m8DayTruthOf(kind);
  bool get misuse => m8DayIsMisuse(kind);
  bool get factory => kind == M8DayKind.factory;

  @override
  bool operator ==(Object other) =>
      other is M8DayStop && other.kind == kind && other.variant == variant && other.misuseZone == misuseZone && other.pf == pf && other.mirror == mirror;

  @override
  int get hashCode => Object.hash(kind, variant, misuseZone, pf, mirror);
}

const List<Map<M8DayZone, Set<M8DayAct>>> _houseDays = [
  {
    M8DayZone.morning: {M8DayAct.kitchen, M8DayAct.fan},
    M8DayZone.noon: {M8DayAct.fan, M8DayAct.tv},
    M8DayZone.evening: {M8DayAct.lamp, M8DayAct.fan, M8DayAct.tv},
    M8DayZone.night: {M8DayAct.nightLamp},
  },
  {
    M8DayZone.morning: {M8DayAct.fan, M8DayAct.doorOpen, M8DayAct.homeFridge},
    M8DayZone.noon: {M8DayAct.kitchen},
    M8DayZone.evening: {M8DayAct.lamp, M8DayAct.tv, M8DayAct.kitchen},
    M8DayZone.night: {M8DayAct.fan, M8DayAct.nightLamp},
  },
  {
    M8DayZone.morning: {M8DayAct.kitchen, M8DayAct.tv},
    M8DayZone.noon: {M8DayAct.fan, M8DayAct.doorOpen, M8DayAct.homeFridge},
    M8DayZone.evening: {M8DayAct.lamp, M8DayAct.fan},
    M8DayZone.night: {M8DayAct.nightLamp, M8DayAct.fan},
  },
];

/// Open hours of the roadside shop (the night shutter is always down).
const List<Set<M8DayZone>> _shopOpen = [
  {M8DayZone.morning, M8DayZone.noon, M8DayZone.evening},
  {M8DayZone.morning, M8DayZone.evening},
  {M8DayZone.noon, M8DayZone.evening},
];

/// The pump's own watering hours (honest pump).
const List<Set<M8DayZone>> _pumpHours = [
  {M8DayZone.morning, M8DayZone.evening},
  {M8DayZone.noon, M8DayZone.night},
  {M8DayZone.morning, M8DayZone.night},
];

/// What runs at [s] in [z]. [factoryRun]: where the factory's machine runs.
Set<M8DayAct> m8DayActs(M8DayStop s, M8DayZone z, {M8DayZone factoryRun = M8DayZone.evening}) {
  switch (s.kind) {
    case M8DayKind.house:
      return _houseDays[s.variant % 3][z]!;
    case M8DayKind.fridgeHouse:
      final base = {..._houseDays[s.variant % 3][z]!};
      if (z == s.misuseZone) {
        base
          ..remove(M8DayAct.doorOpen)
          ..remove(M8DayAct.homeFridge)
          ..addAll({M8DayAct.shopOpen, M8DayAct.shopFridge, M8DayAct.customer});
      }
      return base;
    case M8DayKind.shop:
      return _shopOpen[s.variant % 3].contains(z) ? {M8DayAct.shopOpen, M8DayAct.shopFridge, if (z == M8DayZone.evening || s.variant == 1) M8DayAct.customer} : {};
    case M8DayKind.pump:
      return _pumpHours[s.variant % 3].contains(z) ? {M8DayAct.irrigate} : {};
    case M8DayKind.carPump:
      if (z == s.misuseZone) return {M8DayAct.carWash};
      // The pump waters the field in the zone after the misuse hour (or the
      // night), so the pump is seen doing its own job as well.
      final own = M8DayZone.values[(s.misuseZone!.index + 1 + s.variant) % 4];
      return z == own || z == M8DayZone.night && s.variant == 2 ? {M8DayAct.irrigate} : {};
    case M8DayKind.factory:
      return z == factoryRun ? {M8DayAct.machine} : {};
  }
}

/// Where things are (design px, 360 wide).
@immutable
class M8DayGeo {
  const M8DayGeo._(this.height, this.bookTop);

  factory M8DayGeo.forScene(double height, double inset) => M8DayGeo._(height, height - bookH - inset * 0.6);

  final double height;

  /// The top of the reading book.
  final double bookTop;

  static const double bookH = 112;
  static const double skyTop = 150;
  static const double arcCx = 180;
  static const double arcRx = 146;

  /// The premises stand on this line (clear of the guide and his bubble).
  double get groundY => bookTop - 140;

  double get _avail => math.max(120, groundY - skyTop);
  double get arcRy => (_avail * 0.36).clamp(46.0, 118.0);

  /// Where the sun stands at dawn and at midnight.
  double get horizonY => skyTop + arcRy + 16;

  /// Premises scale (virtual 360 × 200 → screen).
  double get s => ((groundY - horizonY + 34) / 200).clamp(0.55, 1.0);

  /// The sun's centre at sun-time [t].
  Offset sunAt(double t) {
    final a = m8DayArcA(t);
    return Offset(arcCx - arcRx * math.cos(math.pi * a), horizonY - arcRy * math.sin(math.pi * a));
  }

  /// Direction of travel along the arc at [t] (unit, forward).
  Offset tangentAt(double t) {
    final a = m8DayArcA(t);
    final d = Offset(arcRx * math.sin(math.pi * a), -arcRy * math.cos(math.pi * a));
    return d / d.distance;
  }

  /// The sun-time under a finger at screen x.
  double tAtX(double x) {
    final c = ((arcCx - x) / arcRx).clamp(-1.0, 1.0);
    return m8DayTOfA(math.acos(c) / math.pi);
  }

  /// The sun's touch circle radius.
  static const double sunHit = 28;

  /// Virtual premises point → screen (design px).
  Offset v(double x, double y, {bool mirror = false}) => Offset(180 + ((mirror ? 360 - x : x) - 180) * s, groundY - (190 - y) * s);

  Rect vRect(double l, double t, double r, double b, {bool mirror = false}) {
    final a = v(l, t, mirror: mirror);
    final c = v(r, b, mirror: mirror);
    return Rect.fromLTRB(math.min(a.dx, c.dx), a.dy, math.max(a.dx, c.dx), c.dy);
  }

  /// The meter card on its box (house, shop, pump).
  Rect card({bool mirror = false}) => vRect(250, 74, 352, 106, mirror: mirror);

  /// The bill clip at the factory gate.
  Rect billClip({bool mirror = false}) => vRect(262, 48, 348, 138, mirror: mirror);

  /// The owner (a silent drawn figure with a caption bubble) at the factory.
  Rect owner({bool mirror = false}) => vRect(252, 100, 356, 190, mirror: mirror);

  /// The reading book.
  Rect get book => Rect.fromLTWH(6, bookTop, 348, bookH - 6);

  /// The line the stamp lands on.
  Rect get slot => Rect.fromLTWH(14, bookTop + 22, 332, 34);

  /// A stamp on the pad (0 ডোমেস্টিক, 1 কমার্শিয়াল, 2 কৃষি).
  Rect stamp(int i) => Rect.fromLTWH(14 + 112.0 * i, bookTop + 62, 104, 42);

  /// The pad's gap between the first and second stamp (a drag hint starts
  /// here, never on a stamp).
  Offset get padGap => Offset(14 + 104 + 4, bookTop + 83);

  /// A dragged stamp lifts this far above the finger.
  static const double lift = 26;

  /// The trainee on the road, bottom left.
  Rect get trainee => Rect.fromLTWH(10, bookTop - 114, 46, 106);

  /// Where the guide's bubble sits (parts must stay clear of it).
  Rect get bubble => Rect.fromLTRB(128, bookTop - 166, 360, bookTop - 112);

  /// A drop on the line (a stamp springs back anywhere else).
  bool onSlot(Offset pin) => slot.inflate(14).contains(pin);

  /// The bracket's centre for sun-time [t].
  Offset bracketAt(double t) => sunAt(t);

  @override
  bool operator ==(Object other) => other is M8DayGeo && other.height == height && other.bookTop == bookTop;

  @override
  int get hashCode => Object.hash(height, bookTop);
}

/// Colours of the sky from dawn to midnight: (t, top, bottom).
const List<(double, Color, Color)> _skyKeys = [
  (0.00, Color(0xFFF2A777), Color(0xFFFFE2B8)),
  (0.12, Color(0xFF8EC3EA), Color(0xFFE6F2FA)),
  (0.40, Color(0xFF5FA3E0), Color(0xFFBFE0F6)),
  (0.58, Color(0xFF7FB0DA), Color(0xFFFFE2A8)),
  (0.68, Color(0xFFE9884E), Color(0xFFFFC27A)),
  (0.76, Color(0xFF4A4F8C), Color(0xFFB9778A)),
  (0.86, Color(0xFF111B3E), Color(0xFF223260)),
  (1.00, Color(0xFF070D24), Color(0xFF121C40)),
];

(Color, Color) m8DaySky(double t) {
  for (var i = 1; i < _skyKeys.length; i++) {
    if (t <= _skyKeys[i].$1) {
      final f = ((t - _skyKeys[i - 1].$1) / (_skyKeys[i].$1 - _skyKeys[i - 1].$1)).clamp(0.0, 1.0);
      return (Color.lerp(_skyKeys[i - 1].$2, _skyKeys[i].$2, f)!, Color.lerp(_skyKeys[i - 1].$3, _skyKeys[i].$3, f)!);
    }
  }
  return (_skyKeys.last.$2, _skyKeys.last.$3);
}

Paint _fill(Color c) => Paint()..color = c;
Paint _stroke(Color c, double w) => Paint()
  ..color = c
  ..strokeWidth = w
  ..style = PaintingStyle.stroke
  ..strokeCap = StrokeCap.round;

/// The sky, the far hills, the field band and the road (everything but the
/// premises), at sun-time [t].
class M8DayBackPainter extends CustomPainter {
  M8DayBackPainter({required this.geo, required this.t}) : super(repaint: t);
  final M8DayGeo geo;
  final ValueNotifier<double> t;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    final tt = t.value;
    final (top, bottom) = m8DaySky(tt);
    final skyR = Rect.fromLTWH(0, 0, w, g.groundY);
    c.drawRect(skyR, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [top, bottom]).createShader(skyR));
    final dark = m8DayDark(tt);
    // Stars once it is dusk.
    if (tt > 0.74) {
      final a = ((tt - 0.74) / 0.12).clamp(0.0, 1.0);
      final p = _fill(Color.fromRGBO(255, 250, 225, a * 0.85));
      for (var i = 0; i < 18; i++) {
        final x = (i * 53 % 340) + 10.0;
        final y = M8DayGeo.skyTop + 6 + (i * 37 % 100);
        c.drawCircle(Offset(x, y), i % 3 == 0 ? 1.5 : 1.0, p);
      }
    }
    // Far hills on the horizon.
    final hillY = g.horizonY + 4;
    final hill = Path()
      ..moveTo(0, hillY)
      ..quadraticBezierTo(60, hillY - 26, 130, hillY - 6)
      ..quadraticBezierTo(210, hillY - 34, 290, hillY - 8)
      ..quadraticBezierTo(330, hillY - 18, w, hillY - 4)
      ..lineTo(w, g.groundY)
      ..lineTo(0, g.groundY)
      ..close();
    c.drawPath(hill, _fill(Color.lerp(const Color(0xFF9DB89A), const Color(0xFF1B2A3A), dark)!));
    // The field band under the premises.
    final bandTop = g.groundY - 12;
    final band = Rect.fromLTRB(0, bandTop, w, g.groundY + 14);
    c.drawRect(band, _fill(Color.lerp(const Color(0xFFB4A57F), const Color(0xFF2C2E36), dark)!));
    // The road.
    final road = Rect.fromLTRB(0, g.groundY + 14, w, size.height);
    c.drawRect(road, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.lerp(const Color(0xFF8D8880), const Color(0xFF23252C), dark)!, Color.lerp(const Color(0xFF6B6762), const Color(0xFF14161B), dark)!]).createShader(road));
    c.drawRect(Rect.fromLTWH(0, g.groundY + 14, w, 5), _fill(Color.lerp(const Color(0xFFD6D1C4), const Color(0xFF3A3C46), dark)!));
    final dash = _fill(Color.lerp(const Color(0xFFE8E2CF), const Color(0xFF4A4C58), dark)!);
    for (var x = 8.0; x < w; x += 46) {
      c.drawRect(Rect.fromLTWH(x, g.groundY + 78, 24, 3), dash);
    }
  }

  @override
  bool shouldRepaint(M8DayBackPainter old) => old.geo != geo;
}

/// The sun's arc, the sun that becomes the moon, and (factory) the bracket.
class M8DayArcPainter extends CustomPainter {
  M8DayArcPainter({required this.geo, required this.t, required this.bracketT, required this.sunShown, required this.bracketShown})
      : super(repaint: Listenable.merge([t, bracketT]));
  final M8DayGeo geo;
  final ValueNotifier<double> t;
  final ValueNotifier<double> bracketT;
  final bool sunShown;
  final bool bracketShown;

  Path _arcBetween(double t0, double t1) {
    final p = Path();
    const n = 28;
    for (var i = 0; i <= n; i++) {
      final o = geo.sunAt(t0 + (t1 - t0) * i / n);
      i == 0 ? p.moveTo(o.dx, o.dy) : p.lineTo(o.dx, o.dy);
    }
    return p;
  }

  @override
  void paint(Canvas c, Size size) {
    final tt = t.value;
    final dark = m8DayDark(tt);
    // The arc: a faint dotted track (no zones marked).
    final track = _arcBetween(0, 1);
    final dotP = _stroke(Color.lerp(const Color(0x88FFFFFF), const Color(0x66C8D4FF), dark)!, 1.6);
    for (final m in track.computeMetrics()) {
      for (var d = 0.0; d < m.length; d += 9) {
        c.drawPath(m.extractPath(d, math.min(m.length, d + 3.5)), dotP);
      }
    }
    if (bracketShown) {
      final bt = bracketT.value;
      final span = _arcBetween(bt - 0.115, math.min(1.0, bt + 0.115));
      c.drawPath(span, _stroke(const Color(0xFF1A2438), 11));
      c.drawPath(span, _stroke(const Color(0xFFF2B431), 7));
      // The bracket's two ends.
      for (final e in [bt - 0.115, math.min(1.0, bt + 0.115)]) {
        final o = geo.sunAt(e);
        c.drawCircle(o, 8, _fill(const Color(0xFF1A2438)));
        c.drawCircle(o, 5.5, _fill(const Color(0xFFF2B431)));
      }
    }
    if (!sunShown) return;
    final o = geo.sunAt(tt);
    // Sun → moon around sunset.
    final moon = ((tt - 0.68) / 0.14).clamp(0.0, 1.0);
    final glow = Color.lerp(const Color(0x66FFE27A), const Color(0x44DCE6FF), moon)!;
    c.drawCircle(o, 25, _fill(glow));
    c.drawCircle(o, 16, _fill(Color.lerp(const Color(0xFFFFD84A), const Color(0xFFF1F1E4), moon)!));
    if (moon > 0.3) {
      c.drawCircle(o + const Offset(6, -3), 14 * moon, _fill(m8DaySky(tt).$1));
    }
    c.drawCircle(o, 16, _stroke(const Color(0xCCFFFFFF), 1.5));
  }

  @override
  bool shouldRepaint(M8DayArcPainter old) => old.geo != geo || old.sunShown != sunShown || old.bracketShown != bracketShown;
}

/// One premises with what runs in the hour the sun is in.
class M8DayPremisesPainter extends CustomPainter {
  M8DayPremisesPainter({required this.geo, required this.stop, required this.t, required this.factoryRun}) : super(repaint: Listenable.merge([t, factoryRun]));
  final M8DayGeo geo;
  final M8DayStop stop;
  final ValueNotifier<double> t;
  final ValueNotifier<M8DayZone> factoryRun;

  late Set<M8DayAct> _acts;
  late double _dark;
  final List<(Offset, double, Color)> _glows = [];

  @override
  void paint(Canvas c, Size size) {
    final tt = t.value;
    _dark = m8DayDark(tt);
    _acts = m8DayActs(stop, m8DayZoneOf(tt), factoryRun: factoryRun.value);
    _glows.clear();
    c.save();
    c.translate(180 - 180 * geo.s, geo.groundY - 190 * geo.s);
    c.scale(geo.s);
    if (stop.mirror) {
      c.translate(360, 0);
      c.scale(-1, 1);
    }
    // The meter pole and box (house, shop, pump); the factory has its gate.
    switch (stop.kind) {
      case M8DayKind.house:
      case M8DayKind.fridgeHouse:
        _house(c);
        _meterPole(c);
      case M8DayKind.shop:
        _shop(c);
        _meterPole(c);
      case M8DayKind.pump:
      case M8DayKind.carPump:
        _pump(c);
        _meterPole(c);
      case M8DayKind.factory:
        _factory(c);
    }
    // Dusk over everything drawn, then the lit things on top.
    if (_dark > 0.01) {
      c.drawRect(const Rect.fromLTRB(-20, -40, 380, 230), _fill(Color.fromRGBO(8, 14, 40, _dark * 0.85)));
    }
    final k = 0.35 + _dark * 0.65;
    for (final (o, r, col) in _glows) {
      c.drawCircle(o, r, _fill(col.withValues(alpha: col.a * k)));
    }
    c.restore();
  }

  void _glow(Offset o, double r, [Color col = const Color(0x88FFD66B)]) => _glows.add((o, r, col));

  // --- shared pieces -----------------------------------------------------------
  void _ground(Canvas c, {Color col = const Color(0xFFB4A57F)}) {
    c.drawRect(const Rect.fromLTRB(-20, 186, 380, 200), _fill(col));
  }

  void _meterPole(Canvas c) {
    c.drawRect(const Rect.fromLTWH(296, 110, 7, 80), _fill(const Color(0xFF8E9399)));
    final box = RRect.fromRectAndRadius(const Rect.fromLTWH(288, 118, 24, 32), const Radius.circular(3));
    c.drawRRect(box, _fill(const Color(0xFFDDE2E6)));
    c.drawRRect(box, _stroke(const Color(0xFF5B6168), 1.4));
    c.drawRect(const Rect.fromLTWH(292, 123, 16, 11), _fill(const Color(0xFF1E2A33)));
    c.drawRect(const Rect.fromLTWH(294, 125, 12, 6), _fill(const Color(0xFFB8E0B0)));
  }

  void _window(Canvas c, Rect r, {Color glass = const Color(0xFF8DB4C9)}) {
    c.drawRect(r.inflate(2.5), _fill(const Color(0xFF6A5A48)));
    c.drawRect(r, _fill(glass));
    c.drawLine(Offset(r.center.dx, r.top), Offset(r.center.dx, r.bottom), _stroke(const Color(0xFF6A5A48), 1.2));
  }

  void _fridge(Canvas c, Rect r, {required bool glassDoor, required bool lit}) {
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), _fill(glassDoor ? const Color(0xFFD8DEE2) : const Color(0xFFF1F3F4)));
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), _stroke(const Color(0xFF59626A), 1.2));
    if (glassDoor) {
      final g = r.deflate(3);
      c.drawRect(g, _fill(lit ? const Color(0xFFE9F6FF) : const Color(0xFF9CB4C0)));
      // Bottle rows.
      const cols = [Color(0xFFD94B3D), Color(0xFF3FA55B), Color(0xFFE8A92A), Color(0xFF3B7DD0)];
      for (var row = 0; row < 3; row++) {
        for (var i = 0; i < 4; i++) {
          c.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(g.left + 2 + i * (g.width - 4) / 4, g.top + 4 + row * (g.height - 6) / 3, (g.width - 8) / 4, (g.height - 10) / 3 - 2), const Radius.circular(1.5)),
            _fill(cols[(i + row) % 4]),
          );
        }
      }
      if (lit) _glow(r.center, r.longestSide * 0.7, const Color(0x44CFEFFF));
    } else {
      c.drawLine(Offset(r.left + 4, r.top + r.height * 0.4), Offset(r.right - 4, r.top + r.height * 0.4), _stroke(const Color(0xFF59626A), 1));
      c.drawLine(Offset(r.right - 5, r.top + 6), Offset(r.right - 5, r.top + 18), _stroke(const Color(0xFF59626A), 1.6));
    }
  }

  void _person(Canvas c, Offset base, {Color shirt = const Color(0xFF3F7DA0), double h = 42}) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: base.translate(0, -h * 0.38), width: 12, height: h * 0.56), const Radius.circular(4)), _fill(shirt));
    c.drawCircle(base.translate(0, -h * 0.82), 6, _fill(const Color(0xFFC98E62)));
    c.drawRect(Rect.fromLTWH(base.dx - 5, base.dy - h * 0.12, 4, h * 0.12), _fill(const Color(0xFF2B2B33)));
    c.drawRect(Rect.fromLTWH(base.dx + 1, base.dy - h * 0.12, 4, h * 0.12), _fill(const Color(0xFF2B2B33)));
  }

  // --- the house (and the house with a front-room shop) --------------------------
  void _house(Canvas c) {
    _ground(c);
    // Wall and roof.
    c.drawRect(const Rect.fromLTRB(50, 86, 250, 190), _fill(const Color(0xFFE8D9B8)));
    final roof = Path()
      ..moveTo(36, 90)
      ..lineTo(150, 44)
      ..lineTo(264, 90)
      ..close();
    c.drawPath(roof, _fill(const Color(0xFFA5503A)));
    c.drawPath(roof, _stroke(const Color(0xFF6E2F20), 1.6));
    // Chimney.
    c.drawRect(const Rect.fromLTRB(212, 54, 228, 84), _fill(const Color(0xFF9A5B48)));
    if (_acts.contains(M8DayAct.kitchen)) {
      for (var i = 0; i < 3; i++) {
        c.drawCircle(Offset(220 + i * 5.0, 46 - i * 12.0), 6 + i * 2.0, _fill(Color.fromRGBO(220, 220, 224, 0.6 - i * 0.14)));
      }
    }
    // The front room: closed door, an open room, or the shop.
    const room = Rect.fromLTRB(62, 108, 146, 190);
    if (_acts.contains(M8DayAct.shopOpen)) {
      _frontShop(c, room);
    } else if (_acts.contains(M8DayAct.doorOpen)) {
      c.drawRect(room.inflate(3), _fill(const Color(0xFF6A5A48)));
      c.drawRect(room, _fill(const Color(0xFFD8C7A0)));
      c.drawRect(const Rect.fromLTRB(62, 176, 146, 190), _fill(const Color(0xFFB59A74)));
      // A sofa, and the home fridge in the corner (no counter, no crates).
      c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTRB(68, 150, 108, 182), const Radius.circular(5)), _fill(const Color(0xFF7A4B3A)));
      if (_acts.contains(M8DayAct.homeFridge)) _fridge(c, const Rect.fromLTRB(114, 128, 138, 184), glassDoor: false, lit: false);
      if (_acts.contains(M8DayAct.fan)) _fanBlades(c, const Offset(104, 120));
    } else {
      c.drawRect(room.inflate(3), _fill(const Color(0xFF6A5A48)));
      c.drawRect(room, _fill(const Color(0xFF9A7B52)));
      for (var x = 70.0; x < 146; x += 10) {
        c.drawLine(Offset(x, 108), Offset(x, 190), _stroke(const Color(0xFF7C623F), 1));
      }
      c.drawCircle(const Offset(138, 152), 2.4, _fill(const Color(0xFFD9C27A)));
    }
    // The other window: lamp, TV, fan, steam or night lamp.
    const win = Rect.fromLTRB(168, 112, 234, 164);
    final lit = _acts.contains(M8DayAct.lamp) || _acts.contains(M8DayAct.kitchen);
    _window(c, win, glass: lit ? const Color(0xFFFFE8A8) : const Color(0xFF8DB4C9));
    if (_acts.contains(M8DayAct.tv)) {
      c.drawRect(const Rect.fromLTWH(178, 128, 30, 22), _fill(const Color(0xFF3B6FD8)));
      _glow(const Offset(193, 139), 26, const Color(0x663B6FD8));
    }
    if (_acts.contains(M8DayAct.fan)) _fanBlades(c, const Offset(201, 126));
    if (lit) _glow(win.center, 38, const Color(0x77FFD66B));
    if (_acts.contains(M8DayAct.nightLamp)) {
      c.drawCircle(const Offset(220, 150), 4, _fill(const Color(0xFFFFE9A6)));
      _glow(const Offset(220, 150), 24, const Color(0x66FFD66B));
    }
    // Step.
    c.drawRect(const Rect.fromLTRB(56, 186, 252, 192), _fill(const Color(0xFFB5AC9C)));
  }

  void _fanBlades(Canvas c, Offset o) {
    final p = _fill(const Color(0xAA3A3F46));
    for (final a in [0.2, 2.3, 4.4]) {
      c.save();
      c.translate(o.dx, o.dy);
      c.rotate(a);
      c.drawOval(const Rect.fromLTWH(0, -3, 22, 6), p);
      c.restore();
    }
    c.drawCircle(o, 3, _fill(const Color(0xFF22262B)));
    c.drawArc(Rect.fromCenter(center: o, width: 52, height: 22), 0.3, 1.6, false, _stroke(const Color(0x553A3F46), 3));
  }

  /// The house's front room turned into a shop for one hour (the counter, the
  /// open shutter, the bottle fridge, a bulb and the customer).
  void _frontShop(Canvas c, Rect room) {
    c.drawRect(room.inflate(3), _fill(const Color(0xFF6A5A48)));
    c.drawRect(room, _fill(const Color(0xFFE9DDB8)));
    c.drawRect(const Rect.fromLTRB(62, 106, 146, 112), _fill(const Color(0xFF9AA3AA)));
    _fridge(c, const Rect.fromLTRB(106, 118, 138, 170), glassDoor: true, lit: true);
    c.drawRect(const Rect.fromLTRB(62, 156, 112, 168), _fill(const Color(0xFF8A5E34)));
    c.drawRect(const Rect.fromLTRB(62, 168, 112, 190), _fill(const Color(0xFF6E4A28)));
    c.drawLine(const Offset(86, 112), const Offset(86, 124), _stroke(const Color(0xFF3A3A3A), 1));
    c.drawCircle(const Offset(86, 127), 3.2, _fill(const Color(0xFFFFEEA8)));
    _glow(const Offset(86, 127), 20, const Color(0x77FFD66B));
    if (_acts.contains(M8DayAct.customer)) _person(c, const Offset(124, 190), shirt: const Color(0xFFC0583A), h: 40);
  }

  // --- the roadside shop ---------------------------------------------------------
  void _shop(Canvas c) {
    _ground(c);
    c.drawRect(const Rect.fromLTRB(40, 84, 240, 190), _fill(const Color(0xFFD9C9A8)));
    c.drawRect(const Rect.fromLTRB(34, 76, 246, 90), _fill(const Color(0xFF8D7B68)));
    // Awning stripes.
    for (var i = 0; i < 10; i++) {
      c.drawRect(Rect.fromLTWH(50 + i * 18.0, 92, 18, 16), _fill(i.isEven ? const Color(0xFFC0392B) : const Color(0xFFF1E8DA)));
    }
    const mouth = Rect.fromLTRB(58, 110, 216, 190);
    c.drawRect(mouth.inflate(3), _fill(const Color(0xFF6A5A48)));
    if (_acts.contains(M8DayAct.shopOpen)) {
      c.drawRect(mouth, _fill(const Color(0xFFEADFC0)));
      c.drawRect(const Rect.fromLTRB(58, 112, 216, 118), _fill(const Color(0xFF9AA3AA)));
      _fridge(c, const Rect.fromLTRB(156, 122, 202, 184), glassDoor: true, lit: true);
      c.drawRect(const Rect.fromLTRB(64, 158, 150, 172), _fill(const Color(0xFF8A5E34)));
      c.drawRect(const Rect.fromLTRB(64, 172, 150, 190), _fill(const Color(0xFF6E4A28)));
      // Jars on the shelf.
      for (var i = 0; i < 4; i++) {
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(70 + i * 20.0, 134, 14, 20), const Radius.circular(3)), _fill([const Color(0xFFD9A441), const Color(0xFFB5523A), const Color(0xFF6F9E5A), const Color(0xFF4E7FB0)][i]));
      }
      c.drawLine(const Offset(120, 118), const Offset(120, 126), _stroke(const Color(0xFF3A3A3A), 1));
      c.drawCircle(const Offset(120, 129), 3.4, _fill(const Color(0xFFFFEEA8)));
      _glow(const Offset(120, 129), 22, const Color(0x77FFD66B));
      if (_acts.contains(M8DayAct.customer)) _person(c, const Offset(100, 190), shirt: const Color(0xFF4C8C7A), h: 44);
    } else {
      c.drawRect(mouth, _fill(const Color(0xFF9AA3AA)));
      for (var y = 114.0; y < 190; y += 7) {
        c.drawLine(Offset(58, y), Offset(216, y), _stroke(const Color(0xFF7A838A), 1));
      }
    }
    // A blank sign board.
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(222, 120, 16, 34), const Radius.circular(3)), _fill(const Color(0xFF3E5A7A)));
    c.drawRect(const Rect.fromLTRB(36, 186, 244, 192), _fill(const Color(0xFFB5AC9C)));
  }

  // --- the pump house (and the pump house where a car is washed) -------------------
  void _pump(Canvas c) {
    _ground(c, col: const Color(0xFF9C8B63));
    // The field rows.
    final wet = _acts.contains(M8DayAct.irrigate);
    final field = Rect.fromLTRB(150, 150, 280, 188);
    c.drawRect(field, _fill(wet ? const Color(0xFF6B7E3E) : const Color(0xFFA99B5A)));
    for (var i = 0; i < 6; i++) {
      c.drawLine(Offset(154 + i * 22.0, 188), Offset(164 + i * 22.0, 152), _stroke(wet ? const Color(0xFF4F8A3C) : const Color(0xFF7E9444), 3));
    }
    // The pump house: brick walls, a tin roof, the motor in the doorway.
    c.drawRect(const Rect.fromLTRB(34, 124, 124, 190), _fill(const Color(0xFFB5603F)));
    for (var y = 130.0; y < 190; y += 8) {
      c.drawLine(Offset(34, y), Offset(124, y), _stroke(const Color(0xFF8E4A2F), 0.8));
    }
    c.drawPath(
      Path()
        ..moveTo(26, 128)
        ..lineTo(79, 100)
        ..lineTo(132, 128)
        ..close(),
      _fill(const Color(0xFF8E959B)),
    );
    c.drawRect(const Rect.fromLTRB(54, 146, 104, 190), _fill(const Color(0xFF2C2F34)));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTRB(62, 160, 96, 184), const Radius.circular(5)), _fill(const Color(0xFF2E6F9A)));
    c.drawCircle(const Offset(79, 172), 6, _fill(const Color(0xFF9AA3AA)));
    // The pipe along the ground.
    c.drawRect(const Rect.fromLTRB(104, 176, 150, 182), _fill(const Color(0xFF5F6A73)));
    if (wet) {
      // Water running into the field.
      for (var i = 0; i < 4; i++) {
        final x = 160 + i * 28.0;
        final p = Path()
          ..moveTo(x, 156)
          ..quadraticBezierTo(x + 12, 140, x + 22, 158);
        c.drawPath(p, _stroke(const Color(0xCC8FD0FF), 2.4));
      }
      c.drawRect(const Rect.fromLTRB(150, 178, 280, 186), _fill(const Color(0x668FD0FF)));
    }
    if (_acts.contains(M8DayAct.carWash)) _carWash(c);
  }

  void _carWash(Canvas c) {
    // A car in the yard, a hose from the pump and foam on the roof.
    final body = RRect.fromRectAndRadius(const Rect.fromLTRB(150, 150, 252, 182), const Radius.circular(8));
    c.drawRRect(body, _fill(const Color(0xFFB03A48)));
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTRB(168, 134, 232, 154), const Radius.circular(8)), _fill(const Color(0xFF9E2F3C)));
    c.drawRect(const Rect.fromLTRB(174, 138, 196, 152), _fill(const Color(0xFFBBD7E8)));
    c.drawRect(const Rect.fromLTRB(200, 138, 226, 152), _fill(const Color(0xFFBBD7E8)));
    for (final x in [172.0, 232.0]) {
      c.drawCircle(Offset(x, 184), 11, _fill(const Color(0xFF22262B)));
      c.drawCircle(Offset(x, 184), 5, _fill(const Color(0xFFB8BEC4)));
    }
    for (final o in [const Offset(186, 146), const Offset(206, 140), const Offset(222, 148), const Offset(196, 156)]) {
      c.drawCircle(o, 6.5, _fill(const Color(0xDDFFFFFF)));
    }
    // The hose and its spray.
    final hose = Path()
      ..moveTo(116, 178)
      ..cubicTo(130, 196, 138, 140, 160, 138);
    c.drawPath(hose, _stroke(const Color(0xFF2F8F57), 3.2));
    for (var i = 0; i < 3; i++) {
      c.drawLine(Offset(162, 138), Offset(176 + i * 5.0, 128 + i * 6.0), _stroke(const Color(0xCC8FD0FF), 2));
    }
    // Puddle.
    c.drawOval(const Rect.fromLTRB(140, 184, 270, 192), _fill(const Color(0x668FD0FF)));
  }

  // --- the factory -----------------------------------------------------------------
  void _factory(Canvas c) {
    _ground(c, col: const Color(0xFF8E8A82));
    final on = _acts.contains(M8DayAct.machine);
    // Saw-tooth roof shed.
    c.drawRect(const Rect.fromLTRB(28, 96, 250, 190), _fill(const Color(0xFFA7AFB5)));
    final saw = Path()..moveTo(28, 96);
    for (var i = 0; i < 4; i++) {
      final x = 28 + i * 55.5;
      saw
        ..lineTo(x, 74)
        ..lineTo(x + 55.5, 96);
    }
    saw
      ..lineTo(250, 96)
      ..close();
    c.drawPath(saw, _fill(const Color(0xFF7C858C)));
    // Chimney (smoke while the machine runs).
    c.drawRect(const Rect.fromLTRB(226, 38, 242, 80), _fill(const Color(0xFF8E4A3A)));
    if (on) {
      for (var i = 0; i < 3; i++) {
        c.drawCircle(Offset(236 + i * 6.0, 30 - i * 11.0), 7 + i * 2.5, _fill(Color.fromRGBO(190, 190, 196, 0.62 - i * 0.15)));
      }
    }
    // The wide doorway and the machine inside.
    const door = Rect.fromLTRB(50, 112, 226, 190);
    c.drawRect(door.inflate(3), _fill(const Color(0xFF5F666C)));
    c.drawRect(door, _fill(const Color(0xFF2A2E33)));
    c.drawRect(const Rect.fromLTRB(60, 176, 216, 190), _fill(const Color(0xFF3B4046)));
    // Motor, belt and flywheel.
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTRB(70, 150, 112, 182), const Radius.circular(5)), _fill(const Color(0xFF2E6F9A)));
    c.drawLine(const Offset(112, 160), const Offset(166, 150), _stroke(const Color(0xFF111418), 4));
    c.drawLine(const Offset(112, 174), const Offset(166, 172), _stroke(const Color(0xFF111418), 4));
    c.drawCircle(const Offset(172, 162), 24, _fill(const Color(0xFF8C969E)));
    c.drawCircle(const Offset(172, 162), 24, _stroke(const Color(0xFF1B1F23), 2.4));
    c.drawCircle(const Offset(172, 162), 6, _fill(const Color(0xFF1B1F23)));
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2 + (on ? 0.5 : 0.0);
      c.drawLine(Offset(172 + 6 * math.cos(a), 162 + 6 * math.sin(a)), Offset(172 + 22 * math.cos(a), 162 + 22 * math.sin(a)), _stroke(const Color(0xFF1B1F23), 3));
    }
    if (on) {
      c.drawArc(Rect.fromCenter(center: const Offset(172, 162), width: 62, height: 62), 0.2, 1.4, false, _stroke(const Color(0x88FFFFFF), 3));
      c.drawArc(Rect.fromCenter(center: const Offset(172, 162), width: 62, height: 62), 3.4, 1.4, false, _stroke(const Color(0x88FFFFFF), 3));
      _glow(const Offset(138, 132), 26, const Color(0x55FFD66B));
      c.drawLine(const Offset(138, 112), const Offset(138, 124), _stroke(const Color(0xFF3A3A3A), 1));
      c.drawCircle(const Offset(138, 128), 4, _fill(const Color(0xFFFFEEA8)));
    }
    // The gate post the bill hangs by.
    c.drawRect(const Rect.fromLTWH(266, 120, 6, 70), _fill(const Color(0xFF8E9399)));
    c.drawRect(const Rect.fromLTRB(250, 186, 360, 192), _fill(const Color(0xFFB5AC9C)));
  }

  @override
  bool shouldRepaint(M8DayPremisesPainter old) => old.geo != geo || old.stop != stop;
}
