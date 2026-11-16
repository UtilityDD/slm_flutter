import 'dart:math' as math;

import 'package:flutter/material.dart';

// The drawn world of lesson 7.1 কাজ "নিয়মের পাতা লাগান" (m7_rule_tag.dart):
// a neighbourhood patrol at mid-morning, one site at a time. Four kinds of
// site (three are dealt a play): a DTR on a double-pole structure by a lane,
// a feeder pillar at a market corner, a lane where a new house's balcony and
// a new rooftop room came up under the LT line, and a DTR on a plinth by a
// school wall. Every DTR is the WBSEDCL one: an AB switch with its HG fuses
// (ruling M7-9; no DO fuses anywhere in Module 7).
//
// Each site has 3–4 checkable parts drawn in their dealt state, all of them
// in both states across plays and never brighter, ringed or captioned:
//  danger plate — fixed at its spot / missing (two bare bolt holes) / lying
//    on the ground at the foot (lesson 7.1 point 3, রেগুলেশন 20);
//  body earth lead, neutral earth lead — clamped into the pit / cut (two
//    loose ends) / gone (an empty clamp) (রেগুলেশন 43 ও 50);
//  a person at the installation — a company man (helmet, uniform, ID card on
//    a lanyard) / a local electrician (no helmet, checked shirt, no card)
//    (রেগুলেশন 3);
//  the line over a new balcony / a new rooftop room — a clear gap / resting
//    on it (রেগুলেশন 60–63 ও 71; the lesson gives no numbers for 7.1, so the
//    only breach drawn is zero gap).
//
// Only words a worker reads are painted: 'বিপদ / DANGER' on a fixed plate,
// '11 kV' on a DTR tank, '415 V' on the pillar. Code-drawn with gradients.
//
// Design: 360 wide × the scene's height. The pocket rulebook stands on the
// bottom edge (a widget on the page); the installations stand on a ground
// line well above it so the corner guide and his bubble never hide a part.

/// The four kinds of site.
enum M7TagSiteKind { dtrPole, pillar, lane, plinth }

/// The four rulebook tabs, in booklet order (live CEA 2023 numbers, X3).
enum M7TagReg { r3, r20, r43, r60 }

/// The checkable parts.
enum M7TagPart { plate, bodyEarth, neutralEarth, person, balconySpan, roofSpan }

/// How a part is drawn.
enum M7TagLook {
  // plate
  fixed,
  missing,
  onGround,
  // earth leads
  connected,
  cut,
  gone,
  // person
  crew,
  local,
  // spans
  clear,
  resting,
}

/// The regulation a part is judged by.
M7TagReg m7TagRegOf(M7TagPart p) => switch (p) {
      M7TagPart.plate => M7TagReg.r20,
      M7TagPart.bodyEarth || M7TagPart.neutralEarth => M7TagReg.r43,
      M7TagPart.person => M7TagReg.r3,
      M7TagPart.balconySpan || M7TagPart.roofSpan => M7TagReg.r60,
    };

/// A look that breaks the rule.
bool m7TagBreach(M7TagLook l) => switch (l) {
      M7TagLook.missing || M7TagLook.onGround || M7TagLook.cut || M7TagLook.gone || M7TagLook.local || M7TagLook.resting => true,
      _ => false,
    };

/// The looks a part may be dealt.
List<M7TagLook> m7TagLooks(M7TagPart p, {required bool breach}) => switch (p) {
      M7TagPart.plate => breach ? const [M7TagLook.missing, M7TagLook.onGround] : const [M7TagLook.fixed],
      M7TagPart.bodyEarth || M7TagPart.neutralEarth => breach ? const [M7TagLook.cut, M7TagLook.gone] : const [M7TagLook.connected],
      M7TagPart.person => breach ? const [M7TagLook.local] : const [M7TagLook.crew],
      M7TagPart.balconySpan || M7TagPart.roofSpan => breach ? const [M7TagLook.resting] : const [M7TagLook.clear],
    };

/// The fixed parts of a site (a person may be added where one can stand).
List<M7TagPart> m7TagFixedParts(M7TagSiteKind k) => switch (k) {
      M7TagSiteKind.dtrPole => const [M7TagPart.plate, M7TagPart.neutralEarth, M7TagPart.bodyEarth],
      M7TagSiteKind.pillar => const [M7TagPart.neutralEarth, M7TagPart.plate, M7TagPart.bodyEarth],
      M7TagSiteKind.lane => const [M7TagPart.person, M7TagPart.balconySpan, M7TagPart.roofSpan],
      M7TagSiteKind.plinth => const [M7TagPart.plate, M7TagPart.neutralEarth, M7TagPart.bodyEarth],
    };

/// One dealt site: its parts in their looks, its side and (pillar) the door.
@immutable
class M7TagSite {
  const M7TagSite({required this.kind, required this.looks, this.mirror = false, this.doorOpen = false});

  final M7TagSiteKind kind;

  /// The checkable parts in scene order, each with its look.
  final Map<M7TagPart, M7TagLook> looks;

  /// Drawn mirrored (plates and earth leads on the other side).
  final bool mirror;

  /// The pillar's door stands open (always with a local electrician; some
  /// plays with the company man too, so the door alone tells nothing).
  final bool doorOpen;

  List<M7TagPart> get parts => looks.keys.toList();
  List<M7TagPart> get breaches => [for (final e in looks.entries) if (m7TagBreach(e.value)) e.key];

  @override
  bool operator ==(Object other) =>
      other is M7TagSite &&
      other.kind == kind &&
      other.mirror == mirror &&
      other.doorOpen == doorOpen &&
      other.looks.length == looks.length &&
      looks.entries.every((e) => other.looks[e.key] == e.value);

  @override
  int get hashCode => Object.hash(kind, mirror, doorOpen, Object.hashAll(looks.entries.map((e) => Object.hash(e.key, e.value))));
}

/// Where things are (design px, 360 wide).
@immutable
class M7TagGeo {
  const M7TagGeo._(this.height, this.bookTop);

  factory M7TagGeo.forScene(double height, double inset) => M7TagGeo._(height, height - bookH - inset * 0.6);

  final double height;

  /// The top of the pocket rulebook.
  final double bookTop;

  static const double bookH = 96;

  /// The installations stand on this line (clear of the guide and his bubble).
  double get groundY => bookTop - 176;

  /// The installations' working height.
  double get instH => groundY - 150;

  /// A height above the ground (0 = the ground, 1 = the top of the site).
  double y(double f) => groundY - f * instH;

  /// The rulebook, its spine and its four tabs (booklet order).
  Rect get book => Rect.fromLTWH(6, bookTop, 348, bookH - 6);
  Rect get spine => Rect.fromLTWH(6, bookTop, 26, bookH - 6);
  Rect tab(M7TagReg r) => Rect.fromLTWH(36 + 80.0 * r.index, bookTop + 6, 76, bookH - 18);

  /// The booklet's centre, between the 2nd and 3rd tab (never on one tab).
  Offset get bookCentre => Offset(194, bookTop + 6 + (bookH - 18) / 2);

  /// The inspection register clipboard (a swipe signs it).
  Rect get register => Rect.fromLTWH(10, bookTop - 124, 80, 110);

  /// The trainee (on the pavement in front).
  Rect get trainee => Rect.fromLTWH(98, bookTop - 116, 46, 106);

  /// A dragged tab's pin sits this far above the finger.
  static const double lift = 26;

  /// Where the guide's bubble sits (parts must stay clear of it).
  Rect get bubble => Rect.fromLTRB(128, bookTop - 166, 360, bookTop - 112);

  Rect _m(Rect r, bool mirror) => mirror ? Rect.fromLTRB(360 - r.right, r.top, 360 - r.left, r.bottom) : r;

  /// A part's touch box on a site.
  Rect partRect(M7TagSiteKind k, M7TagPart p, {bool mirror = false}) {
    final g = groundY + 6;
    final r = switch ((k, p)) {
      (M7TagSiteKind.dtrPole, M7TagPart.plate) => Rect.fromLTRB(69, y(0.36), 121, g),
      (M7TagSiteKind.dtrPole, M7TagPart.neutralEarth) => Rect.fromLTRB(138, y(0.42), 172, g),
      (M7TagSiteKind.dtrPole, M7TagPart.bodyEarth) => Rect.fromLTRB(208, y(0.42), 248, g),
      (M7TagSiteKind.pillar, M7TagPart.neutralEarth) => Rect.fromLTRB(84, y(0.24), 128, g),
      (M7TagSiteKind.pillar, M7TagPart.plate) => Rect.fromLTRB(142, y(0.64), 188, g),
      (M7TagSiteKind.pillar, M7TagPart.bodyEarth) => Rect.fromLTRB(202, y(0.24), 246, g),
      (M7TagSiteKind.lane, M7TagPart.person) => Rect.fromLTRB(12, y(0.82), 84, g),
      (M7TagSiteKind.lane, M7TagPart.balconySpan) => Rect.fromLTRB(96, y(0.98), 200, y(0.62)),
      (M7TagSiteKind.lane, M7TagPart.roofSpan) => Rect.fromLTRB(212, y(0.98), 322, y(0.62)),
      (M7TagSiteKind.plinth, M7TagPart.plate) => Rect.fromLTRB(108, y(0.42), 150, g),
      (M7TagSiteKind.plinth, M7TagPart.neutralEarth) => Rect.fromLTRB(160, y(0.32), 187, g),
      (M7TagSiteKind.plinth, M7TagPart.bodyEarth) => Rect.fromLTRB(196, y(0.42), 238, g),
      (_, M7TagPart.person) => Rect.fromLTRB(258, g - 106, 312, g),
      _ => Rect.zero,
    };
    return _m(r, mirror);
  }

  /// Where a pinned tag hangs on a part.
  Offset tagAt(M7TagSiteKind k, M7TagPart p, {bool mirror = false}) {
    final r = partRect(k, p, mirror: mirror);
    return Offset(r.center.dx, r.top + 12);
  }

  /// The part under a dragged tab's pin, or null.
  M7TagPart? partAt(M7TagSite s, Offset pin) {
    for (final p in s.parts) {
      if (partRect(s.kind, p, mirror: s.mirror).inflate(4).contains(pin)) return p;
    }
    return null;
  }

  @override
  bool operator ==(Object other) => other is M7TagGeo && other.height == height && other.bookTop == bookTop;

  @override
  int get hashCode => Object.hash(height, bookTop);
}

/// The morning light (dealt a play).
const List<List<Color>> kM7TagSkies = [
  [Color(0xFF7FB8E8), Color(0xFFCFE6F5), Color(0xFFFFF4D6)],
  [Color(0xFF9DB9CF), Color(0xFFD8E2E8), Color(0xFFF2EEE2)],
  [Color(0xFF6FA9DC), Color(0xFFB9DAF2), Color(0xFFF9E7C2)],
];

void _text(Canvas c, String text, Offset centre, {double size = 6.5, Color color = const Color(0xFF26303D), FontWeight weight = FontWeight.w800}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: weight, color: color, height: 1.0)),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  )..layout(maxWidth: 80);
  tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
}

Paint _fill(Color c) => Paint()..color = c;
Paint _stroke(Color c, double w) => Paint()
  ..color = c
  ..strokeWidth = w
  ..style = PaintingStyle.stroke
  ..strokeCap = StrokeCap.round;

/// The sky, the far houses and the lane (the same for every site, so the
/// camera pan slides only the site over them).
class M7TagBackPainter extends CustomPainter {
  const M7TagBackPainter({required this.geo, required this.light});
  final M7TagGeo geo;
  final int light;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final w = size.width;
    final sky = kM7TagSkies[light % kM7TagSkies.length];
    final skyR = Rect.fromLTWH(0, 0, w, g.groundY);
    c.drawRect(skyR, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: sky).createShader(skyR));
    // The sun, low in the east.
    c.drawCircle(Offset(w * 0.82, 120), 26, _fill(const Color(0x55FFF3B0)));
    c.drawCircle(Offset(w * 0.82, 120), 16, _fill(const Color(0xFFFFF0A8)));
    // Far houses and trees along the skyline.
    final far = _fill(const Color(0xFFB8C4CC));
    for (var i = 0; i < 9; i++) {
      final x = i * 44.0 - 10;
      final hgt = 40.0 + (i * 37 % 5) * 9;
      c.drawRect(Rect.fromLTWH(x, g.groundY - hgt - 30, 38, hgt + 30), far);
    }
    final tree = _fill(const Color(0xFF8FB08A));
    for (final x in [30.0, 150.0, 260.0, 345.0]) {
      c.drawCircle(Offset(x, g.groundY - 74), 22, tree);
    }
    // The ground under the site, the kerb, the pavement and the road.
    final ground = Rect.fromLTRB(0, g.groundY, w, size.height);
    c.drawRect(ground, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFB9A887), Color(0xFF9C9488), Color(0xFF6E6A66)]).createShader(ground));
    c.drawRect(Rect.fromLTWH(0, g.groundY + 22, w, 6), _fill(const Color(0xFFD6D1C4)));
    final road = Rect.fromLTRB(0, g.groundY + 28, w, size.height);
    c.drawRect(road, _fill(const Color(0xFF6F6B66)));
    for (var x = 8.0; x < w; x += 46) {
      c.drawRect(Rect.fromLTWH(x, g.groundY + 92, 24, 3), _fill(const Color(0xFFE8E2CF)));
    }
  }

  @override
  bool shouldRepaint(M7TagBackPainter old) => old.geo != geo || old.light != light;
}

/// One site with its parts in their dealt looks.
class M7TagSitePainter extends CustomPainter {
  const M7TagSitePainter({required this.geo, required this.site});
  final M7TagGeo geo;
  final M7TagSite site;

  bool get _mir => site.mirror;
  double _x(double x) => _mir ? 360 - x : x;
  Offset _o(double x, double y) => Offset(_x(x), y);
  Rect _r(double l, double t, double r, double b) => _mir ? Rect.fromLTRB(360 - r, t, 360 - l, b) : Rect.fromLTRB(l, t, r, b);

  @override
  void paint(Canvas c, Size size) {
    switch (site.kind) {
      case M7TagSiteKind.dtrPole:
        _dtrPole(c);
      case M7TagSiteKind.pillar:
        _pillar(c);
      case M7TagSiteKind.lane:
        _lane(c);
      case M7TagSiteKind.plinth:
        _plinth(c);
    }
    final p = site.looks[M7TagPart.person];
    if (p != null && site.kind != M7TagSiteKind.lane) {
      final r = geo.partRect(site.kind, M7TagPart.person, mirror: _mir);
      // No prop on either look (a breached look is never more noticeable).
      _person(c, Offset(r.center.dx, r.bottom - 6), local: p == M7TagLook.local, facingLeft: !_mir);
    }
  }

  // --- shared pieces -----------------------------------------------------------

  void _pole(Canvas c, double x, double top, {double w = 9}) {
    final r = Rect.fromLTRB(_x(x) - w / 2, top, _x(x) + w / 2, geo.groundY + 4);
    c.drawRect(r, Paint()..shader = const LinearGradient(colors: [Color(0xFF8E9399), Color(0xFFC9CDD1), Color(0xFF7C8187)]).createShader(r));
  }

  /// The danger plate at [at] (its centre), in the part's look.
  void _plate(Canvas c, Offset at, M7TagLook look) {
    // The two bolts are always there.
    final bolt = _fill(const Color(0xFF5B5F63));
    if (look != M7TagLook.fixed) {
      c.drawCircle(at + const Offset(-8, 0), 1.8, bolt);
      c.drawCircle(at + const Offset(8, 0), 1.8, bolt);
      c.drawCircle(at + const Offset(-8, 2.5), 1.4, _fill(const Color(0x668A4B22)));
      c.drawCircle(at + const Offset(8, 2.5), 1.4, _fill(const Color(0x668A4B22)));
    }
    if (look == M7TagLook.missing) return;
    if (look == M7TagLook.onGround) {
      // Lying tilted in the dust at the foot.
      c.save();
      c.translate(at.dx + (_mir ? -6 : 6), geo.groundY - 3);
      c.rotate(_mir ? 0.35 : -0.35);
      c.scale(1, 0.55);
      _plateFace(c, Offset.zero);
      c.restore();
      return;
    }
    _plateFace(c, at);
  }

  void _plateFace(Canvas c, Offset at) {
    final r = Rect.fromCenter(center: at, width: 26, height: 20);
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), _fill(const Color(0xFFF7F4EC)));
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(2)), _stroke(const Color(0xFFC62828), 1.6));
    // The skull-and-bolt sign.
    c.drawCircle(at + const Offset(-6.5, -1), 3, _fill(const Color(0xFF26303D)));
    final bolt = Path()
      ..moveTo(at.dx - 3, at.dy + 5)
      ..lineTo(at.dx - 6, at.dy + 1)
      ..lineTo(at.dx - 5, at.dy + 1)
      ..lineTo(at.dx - 8, at.dy - 3);
    c.drawPath(bolt, _stroke(const Color(0xFFC62828), 1));
    _text(c, 'বিপদ', at + const Offset(4.5, -3.5), size: 5.2, color: const Color(0xFFC62828));
    _text(c, 'DANGER', at + const Offset(4.5, 3.5), size: 3.8, color: const Color(0xFFC62828));
  }

  /// An earth lead from [top] down to its pit at [pitX] on the ground.
  void _earth(Canvas c, Offset top, double pitX, M7TagLook look) {
    final g = geo.groundY;
    // The pit's cover and its terminal.
    final pit = Rect.fromCenter(center: Offset(pitX, g + 2), width: 22, height: 8);
    c.drawRect(pit, _fill(const Color(0xFF8C8C86)));
    c.drawRect(pit, _stroke(const Color(0xFF5E5E58), 1));
    c.drawCircle(Offset(pitX, g - 1), 2, _fill(const Color(0xFF6B6F73)));
    // The clamp on the body / neutral.
    c.drawRect(Rect.fromCenter(center: top, width: 7, height: 6), _fill(const Color(0xFF6B6F73)));
    final lead = _stroke(const Color(0xFF8A7E4E), 2.2);
    final bend = Offset(pitX, top.dy + (g - top.dy) * 0.25);
    switch (look) {
      case M7TagLook.connected:
        c.drawPath(Path()..moveTo(top.dx, top.dy)..lineTo(bend.dx, bend.dy)..lineTo(pitX, g - 1), lead);
      case M7TagLook.cut:
        // Two loose ends with a gap at mid-height.
        final mid = bend.dy + (g - bend.dy) * 0.45;
        c.drawPath(Path()..moveTo(top.dx, top.dy)..lineTo(bend.dx, bend.dy)..lineTo(pitX, mid - 7)..lineTo(pitX + 4, mid - 3), lead);
        c.drawPath(Path()..moveTo(pitX, g - 1)..lineTo(pitX, mid + 9)..lineTo(pitX - 4, mid + 5), lead);
      case M7TagLook.gone:
        break;
      default:
        break;
    }
  }

  /// A person standing at [foot]: the company man or a local electrician.
  void _person(Canvas c, Offset foot, {required bool local, required bool facingLeft}) {
    final dir = facingLeft ? -1.0 : 1.0;
    final skin = _fill(const Color(0xFFA8714B));
    // Legs.
    final legs = local ? const Color(0xFF3F6E5A) : const Color(0xFF2E3A4E);
    if (local) {
      // A checked lungi to the shins.
      final lungi = Path()
        ..moveTo(foot.dx - 10, foot.dy - 44)
        ..lineTo(foot.dx + 10, foot.dy - 44)
        ..lineTo(foot.dx + 11, foot.dy - 10)
        ..lineTo(foot.dx - 11, foot.dy - 10)
        ..close();
      c.drawPath(lungi, _fill(legs));
      for (var i = 0; i < 4; i++) {
        c.drawLine(Offset(foot.dx - 10, foot.dy - 40 + i * 8.0), Offset(foot.dx + 10, foot.dy - 40 + i * 8.0), _stroke(const Color(0x66E8E2CF), 1));
      }
      c.drawLine(foot + const Offset(-5, -10), foot + const Offset(-5, 0), _stroke(const Color(0xFFA8714B), 3));
      c.drawLine(foot + const Offset(5, -10), foot + const Offset(5, 0), _stroke(const Color(0xFFA8714B), 3));
    } else {
      c.drawLine(foot + const Offset(-5, -44), foot + const Offset(-6, -2), _stroke(legs, 6));
      c.drawLine(foot + const Offset(5, -44), foot + const Offset(6, -2), _stroke(legs, 6));
      // Boots.
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: foot + const Offset(-6, -1), width: 10, height: 5), const Radius.circular(2)), _fill(const Color(0xFF2A2018)));
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: foot + const Offset(6, -1), width: 10, height: 5), const Radius.circular(2)), _fill(const Color(0xFF2A2018)));
    }
    // Body.
    final body = Rect.fromLTRB(foot.dx - 11, foot.dy - 76, foot.dx + 11, foot.dy - 42);
    final shirt = local ? const Color(0xFFC77B4A) : const Color(0xFF1F5F8F);
    c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(5)), _fill(shirt));
    if (local) {
      for (var i = 0; i < 4; i++) {
        c.drawLine(Offset(body.left + 4 + i * 5.0, body.top), Offset(body.left + 4 + i * 5.0, body.bottom), _stroke(const Color(0x55FFFFFF), 1));
      }
    } else {
      // The company ID card on its lanyard.
      c.drawLine(Offset(foot.dx - 5, body.top + 1), Offset(foot.dx, body.top + 14), _stroke(const Color(0xFFD7332A), 1.2));
      c.drawLine(Offset(foot.dx + 5, body.top + 1), Offset(foot.dx, body.top + 14), _stroke(const Color(0xFFD7332A), 1.2));
      c.drawRect(Rect.fromLTWH(foot.dx - 4, body.top + 14, 8, 10), _fill(const Color(0xFFF7F4EC)));
      c.drawRect(Rect.fromLTWH(foot.dx - 3, body.top + 15, 6, 3), _fill(const Color(0xFF1F5F8F)));
    }
    // Arms: one reaching toward the installation with a tool.
    c.drawLine(Offset(foot.dx + 9 * dir, body.top + 6), Offset(foot.dx + 24 * dir, body.top + 18), _stroke(shirt, 5));
    c.drawCircle(Offset(foot.dx + 25 * dir, body.top + 19), 3, skin);
    c.drawLine(Offset(foot.dx + 25 * dir, body.top + 19), Offset(foot.dx + 33 * dir, body.top + 14), _stroke(const Color(0xFF3A3F45), 2));
    c.drawLine(Offset(foot.dx - 9 * dir, body.top + 6), Offset(foot.dx - 11 * dir, body.top + 30), _stroke(shirt, 5));
    // Head.
    final head = Offset(foot.dx, foot.dy - 84);
    c.drawCircle(head, 7.5, skin);
    if (local) {
      c.drawArc(Rect.fromCircle(center: head, radius: 7.8), math.pi, math.pi, false, _stroke(const Color(0xFF1E1A16), 3));
    } else {
      // The helmet.
      c.drawArc(Rect.fromCircle(center: head + const Offset(0, -1), radius: 9), math.pi, math.pi, true, _fill(const Color(0xFFF2F2F2)));
      c.drawLine(head + const Offset(-11, -1), head + const Offset(11, -1), _stroke(const Color(0xFFDADADA), 2));
    }
  }

  /// The DTR tank with its '11 kV' plate, bushings and fins.
  void _tank(Canvas c, Rect r) {
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(3)), Paint()..shader = const LinearGradient(colors: [Color(0xFF6F8A78), Color(0xFF9FB8A6), Color(0xFF627C6B)]).createShader(r));
    for (var i = 1; i < 5; i++) {
      final x = r.left + r.width * i / 5;
      c.drawLine(Offset(x, r.top + 6), Offset(x, r.bottom - 4), _stroke(const Color(0x553A4A40), 1.5));
    }
    // HT bushings on top, LT on the side.
    for (var i = 0; i < 3; i++) {
      final x = r.left + 12 + i * (r.width - 24) / 2;
      c.drawRect(Rect.fromLTWH(x - 2.5, r.top - 12, 5, 12), _fill(const Color(0xFF8E5A3A)));
    }
    final plate = Rect.fromCenter(center: r.center.translate(0, 4), width: 24, height: 12);
    c.drawRect(plate, _fill(const Color(0xFFE8E4D8)));
    _text(c, '11 kV', plate.center, size: 5.6);
  }

  /// The AB switch on a crossarm at [y] between [x0] and [x1], with its HG
  /// fuses below and the operating rod down the pole at [rodX] (M7-9).
  void _abSwitch(Canvas c, double x0, double x1, double y, double rodX) {
    c.drawLine(_o(x0, y), _o(x1, y), _stroke(const Color(0xFF6E737A), 4));
    for (var i = 0; i < 3; i++) {
      final x = x0 + (x1 - x0) * (i + 0.5) / 3;
      // Post insulator and the closed blade.
      c.drawRect(Rect.fromCenter(center: _o(x, y - 7), width: 5, height: 10), _fill(const Color(0xFF8E5A3A)));
      c.drawLine(_o(x - 6, y - 13), _o(x + 6, y - 13), _stroke(const Color(0xFFB0B5BA), 2.2));
      // The HG fuse: two horns and the fuse wire.
      final fy = y + 16;
      c.drawLine(_o(x - 5, fy + 6), _o(x - 2, fy - 4), _stroke(const Color(0xFF9AA0A6), 1.6));
      c.drawLine(_o(x + 5, fy + 6), _o(x + 2, fy - 4), _stroke(const Color(0xFF9AA0A6), 1.6));
      c.drawLine(_o(x - 2, fy - 4), _o(x + 2, fy - 4), _stroke(const Color(0xFFCFD3D6), 0.8));
    }
    // The operating rod and the handle, locked at the foot.
    c.drawLine(_o(rodX, y + 2), _o(rodX, geo.groundY - 26), _stroke(const Color(0xFF5E6369), 2));
    c.drawLine(_o(rodX, geo.groundY - 26), _o(rodX + 9, geo.groundY - 32), _stroke(const Color(0xFF3A3F45), 3));
  }

  // --- the four sites -----------------------------------------------------------

  void _dtrPole(Canvas c) {
    final top = geo.y(0.98);
    _pole(c, 95, top);
    _pole(c, 215, top);
    // The LT/HT lines leaving the top.
    final wire = _stroke(const Color(0xFF3A3F45), 1.1);
    for (var i = 0; i < 3; i++) {
      c.drawLine(_o(0, top + 6 + i * 5.0), _o(360, top + 4 + i * 5.0), wire);
    }
    _abSwitch(c, 82, 228, geo.y(0.86), 103);
    // The platform and the tank.
    final py = geo.y(0.46);
    c.drawRect(_r(84, py, 226, py + 5), _fill(const Color(0xFF5E6369)));
    _tank(c, _r(122, geo.y(0.66), 188, py));
    // The plate on pole A at chest height.
    _plate(c, _o(95, geo.y(0.24)), site.looks[M7TagPart.plate]!);
    // The neutral lead from the tank's neutral down the middle; the body lead
    // down pole B's outer side.
    _earth(c, _o(150, py + 2), _x(155), site.looks[M7TagPart.neutralEarth]!);
    _earth(c, _o(186, py - 6), _x(232), site.looks[M7TagPart.bodyEarth]!);
  }

  void _pillar(Canvas c) {
    // A market corner: a shop shutter and an awning behind.
    c.drawRect(_r(10, geo.y(0.9), 350, geo.groundY), _fill(const Color(0xFFD9CDB6)));
    final shutter = _r(30, geo.y(0.72), 120, geo.groundY);
    c.drawRect(shutter, _fill(const Color(0xFF9AA3AA)));
    for (var yy = shutter.top + 4; yy < shutter.bottom; yy += 5) {
      c.drawLine(Offset(shutter.left, yy), Offset(shutter.right, yy), _stroke(const Color(0x667A838A), 1));
    }
    final awning = Path()
      ..moveTo(_x(20), geo.y(0.78))
      ..lineTo(_x(340), geo.y(0.78))
      ..lineTo(_x(330), geo.y(0.70))
      ..lineTo(_x(30), geo.y(0.70))
      ..close();
    c.drawPath(awning, _fill(const Color(0xFF3F7F6A)));
    // The plinth and the cabinet.
    c.drawRect(_r(116, geo.groundY - 10, 214, geo.groundY + 2), _fill(const Color(0xFFA9A49A)));
    final cab = _r(120, geo.y(0.6), 210, geo.groundY - 10);
    c.drawRRect(RRect.fromRectAndRadius(cab, const Radius.circular(3)), Paint()..shader = const LinearGradient(colors: [Color(0xFF8C9AA3), Color(0xFFB7C3CA), Color(0xFF82909A)]).createShader(cab));
    final door = _r(126, geo.y(0.38), 204, geo.groundY - 14);
    if (site.doorOpen) {
      // The open door swung out, the busbars inside.
      c.drawRect(door, _fill(const Color(0xFF2E353B)));
      for (var i = 0; i < 4; i++) {
        final yy = door.top + 8 + i * (door.height - 16) / 3;
        c.drawLine(Offset(door.left + 6, yy), Offset(door.right - 6, yy), _stroke([const Color(0xFFD7332A), const Color(0xFFE8C230), const Color(0xFF2E6FD8), const Color(0xFF1A1A1A)][i], 2.4));
      }
      final swing = _mir ? Rect.fromLTRB(door.right, door.top, door.right + 18, door.bottom) : Rect.fromLTRB(door.left - 18, door.top, door.left, door.bottom);
      c.drawRect(swing, _fill(const Color(0xFF7D8B94)));
    } else {
      c.drawRect(door, _stroke(const Color(0xFF5E6B74), 1.4));
      c.drawCircle(Offset(_mir ? door.left + 6 : door.right - 6, door.center.dy), 2, _fill(const Color(0xFF3A3F45)));
    }
    final volt = Rect.fromCenter(center: Offset(_x(165), geo.y(0.56)), width: 26, height: 10);
    c.drawRect(volt, _fill(const Color(0xFFE8E4D8)));
    _text(c, '415 V', volt.center, size: 5.2);
    // The plate on the fixed top panel; earth leads from the base corners.
    _plate(c, _o(165, geo.y(0.46)), site.looks[M7TagPart.plate]!);
    _earth(c, _o(124, geo.groundY - 16), _x(102), site.looks[M7TagPart.neutralEarth]!);
    _earth(c, _o(206, geo.groundY - 16), _x(226), site.looks[M7TagPart.bodyEarth]!);
  }

  void _lane(Canvas c) {
    final lineY = geo.y(0.84);
    _pole(c, 46, geo.y(0.98), w: 8);
    _pole(c, 340, geo.y(0.98), w: 8);
    // Two houses; the new balcony and the new rooftop room.
    final h1 = _r(92, geo.y(0.62), 202, geo.groundY);
    final h2 = _r(210, geo.y(0.56), 326, geo.groundY);
    for (final (h, col) in [(h1, const Color(0xFFE6D3B3)), (h2, const Color(0xFFD9C2C8))]) {
      c.drawRect(h, _fill(col));
      for (var i = 0; i < 2; i++) {
        for (var j = 0; j < 2; j++) {
          c.drawRect(Rect.fromLTWH(h.left + 14 + i * (h.width - 40), h.top + 16 + j * (h.height * 0.42), 12, 14), _fill(const Color(0xFF6E8796)));
        }
      }
    }
    final balcony = site.looks[M7TagPart.balconySpan]!;
    final roof = site.looks[M7TagPart.roofSpan]!;
    // The new balcony: a slab and a railing on top of house 1. Clear = well
    // below the wires on every scene height (never a near miss).
    final railTop = balcony == M7TagLook.resting ? lineY + 2 : geo.y(0.68);
    c.drawRect(_r(96, geo.y(0.64), 198, geo.y(0.62)), _fill(const Color(0xFFBFB6A6)));
    final rail = _r(100, railTop, 194, geo.y(0.64));
    c.drawLine(Offset(rail.left, rail.top), Offset(rail.right, rail.top), _stroke(const Color(0xFF7A6A55), 2.4));
    for (var x = rail.left; x <= rail.right; x += 9) {
      c.drawLine(Offset(x, rail.top), Offset(x, rail.bottom), _stroke(const Color(0xFF7A6A55), 1.4));
    }
    // The new rooftop room on house 2.
    final roomTop = roof == M7TagLook.resting ? lineY + 2 : geo.y(0.66);
    c.drawRect(_r(226, roomTop, 300, geo.y(0.56)), _fill(const Color(0xFFCBB0B8)));
    c.drawRect(_r(222, roomTop - 3, 304, roomTop), _fill(const Color(0xFF9E8A90)));
    // The four LT wires along the lane, sagging onto what came up under them.
    final wire = _stroke(const Color(0xFF2E3338), 1.2);
    for (var i = 0; i < 4; i++) {
      final dy = i * 4.0;
      final p = Path()..moveTo(_x(46), lineY - 8 + dy);
      final sagB = balcony == M7TagLook.resting ? railTop - (lineY - 8 + dy) - 1 + i * 0.6 : 1.5;
      final sagR = roof == M7TagLook.resting ? roomTop - 3 - (lineY - 8 + dy) - 1 + i * 0.6 : 1.5;
      p.quadraticBezierTo(_x(147), lineY - 8 + dy + sagB * 2, _x(205), lineY - 8 + dy + 2);
      p.quadraticBezierTo(_x(263), lineY - 8 + dy + sagR * 2, _x(340), lineY - 8 + dy);
      c.drawPath(p, wire);
    }
    // The person at the near pole, on a ladder.
    final r = geo.partRect(M7TagSiteKind.lane, M7TagPart.person, mirror: _mir);
    final look = site.looks[M7TagPart.person]!;
    final lad = _stroke(const Color(0xFFB08A4A), 2.4);
    final lx = _x(60);
    c.drawLine(Offset(lx, geo.groundY), Offset(_x(50), r.top + 6), lad);
    c.drawLine(Offset(lx + (_mir ? -10 : 10), geo.groundY), Offset(_x(50) + (_mir ? -10 : 10), r.top + 6), lad);
    _person(c, Offset(_x(66), geo.y(0.42)), local: look == M7TagLook.local, facingLeft: !_mir);
  }

  void _plinth(Canvas c) {
    // The school wall with its gate pillar and a painted band.
    final wall = _r(0, geo.y(0.55), 360, geo.groundY);
    c.drawRect(wall, _fill(const Color(0xFFE9D9A6)));
    c.drawRect(_r(0, geo.y(0.55), 360, geo.y(0.5)), _fill(const Color(0xFFB34A3A)));
    c.drawRect(_r(318, geo.y(0.7), 348, geo.groundY), _fill(const Color(0xFFD8C690)));
    // The AB pole beside the plinth with its HG fuses; the cable down to the tank.
    _pole(c, 40, geo.y(0.98), w: 8);
    _abSwitch(c, 20, 70, geo.y(0.88), 46);
    c.drawPath(
        Path()
          ..moveTo(_x(40), geo.y(0.76))
          ..quadraticBezierTo(_x(90), geo.y(0.74), _x(160), geo.y(0.62)),
        _stroke(const Color(0xFF2E3338), 1.6));
    // The plinth, the tank and the fence.
    c.drawRect(_r(132, geo.y(0.3), 222, geo.groundY), _fill(const Color(0xFFA9A49A)));
    _tank(c, _r(145, geo.y(0.62), 207, geo.y(0.3)));
    final fence = _stroke(const Color(0xFF55606A), 1.6);
    for (var x = 104.0; x <= 246; x += 12) {
      c.drawLine(_o(x, geo.y(0.4)), _o(x, geo.groundY), fence);
    }
    c.drawLine(_o(104, geo.y(0.38)), _o(246, geo.y(0.38)), _stroke(const Color(0xFF55606A), 2));
    c.drawLine(_o(104, geo.y(0.12)), _o(246, geo.y(0.12)), _stroke(const Color(0xFF55606A), 2));
    // The plate on the fence gate; the leads from the tank down to the pits.
    _plate(c, _o(129, geo.y(0.26)), site.looks[M7TagPart.plate]!);
    _earth(c, _o(165, geo.y(0.3) + 2), _x(171), site.looks[M7TagPart.neutralEarth]!);
    _earth(c, _o(204, geo.y(0.4)), _x(222), site.looks[M7TagPart.bodyEarth]!);
  }

  @override
  bool shouldRepaint(M7TagSitePainter old) => old.geo != geo || old.site != site;
}
