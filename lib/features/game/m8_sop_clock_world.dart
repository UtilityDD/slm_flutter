import 'dart:math' as math;

import 'package:flutter/material.dart';

// The drawn world of lesson 8.3 কাজ 1 "ঘড়ি টিক-টিক" (m8_sop_clock.dart):
// a section map seen from a little above and, on arrival, a close-up of the
// complaint.
//
//  * The map (360 wide, the scene's height): a dense town block with its DTR
//    on the left, the bazaar in the middle (counted as town: the lesson has
//    only শহর and গ্রাম), rural fields with a village and its DTR on the
//    right, the section office and the crew van at the bottom. Every complaint
//    pin is the SAME pin: no colour, size, badge or order shows a limit, a
//    deadline or whether the work is done. Positions are in map units
//    (320 x 380) so a play's travel times never depend on the screen.
//  * The close-up (push-in): the fuse unit, the loose contact, the burnt DTR
//    (AB switch with its handle locked and tagged, HG fuses, smoke, an oil
//    stain), the broken line, the storm-broken pole and fallen tree, the burnt
//    meter. A small 'শাটডাউন · PTW · আর্থ' tag says the crew works under the
//    house rules. The houses behind light up once the repair is done.
//
// No text in the art except labels a worker reads. Code-drawn, gradients, no
// bitmaps, no logos.

/// The seven complaint types (lesson 8.3: ফিউজ অফ, ব্রেকডাউন, DTR, মিটার,
/// ভোল্টেজ — the storm is a breakdown whose delay is force majeure).
enum M8SopKind { urbanFuse, ruralFuse, wireBreak, storm, dtr, meter, loose }

/// The lesson's two areas (the bazaar counts as town).
enum M8SopZone { town, rural }

/// What a storm close-up shows to photograph.
enum M8SopDamage { pole, tree }

/// The map in map units.
const double kM8SopMapW = 320;
const double kM8SopMapH = 380;

/// Town (with the bazaar) lies left of this, rural right of it.
const double kM8SopTownEdge = 215;

/// The section office.
const Offset kM8SopOffice = Offset(130, 362);

/// Game minutes per map unit of driving (pacing only).
const double kM8SopMinPerUnit = 0.17;

/// Where things are (design px, 360 wide; the floor follows the bottom).
@immutable
class M8SopGeo {
  const M8SopGeo._(this.height, this.inset);

  factory M8SopGeo.forScene(double height, double inset) => M8SopGeo._(height, inset);

  final double height;
  final double inset;

  /// The top of the working area (under the header and the clock).
  static const double top = 150;

  /// The toolbar row (phone, camera) at the bottom left.
  double get toolbarTop => height - 84 - inset;
  Rect get phoneBtn => Rect.fromLTWH(12, toolbarTop, 56, 56);
  Rect get camBtn => Rect.fromLTWH(76, toolbarTop, 56, 56);
  Rect get toolbar => Rect.fromLTRB(12, toolbarTop, 132, toolbarTop + 56);

  /// The hold-to-work button of a close-up.
  Rect get workBtn => Rect.fromLTWH(12, toolbarTop - 72, 180, 60);

  /// The five hold targets of a burnt DTR (four contacts and 'পরে করব'), two
  /// columns, three rows up from the work row.
  Rect contact(int i) => Rect.fromLTWH(12.0 + (i % 2) * 118, toolbarTop - 66 - (i ~/ 2) * 54, 112, 46);

  /// The map's area on the scene.
  Rect get mapRect => Rect.fromLTRB(20, top, 340, toolbarTop - 20);

  /// A map point (map units) on the scene.
  Offset mapPoint(double u, double v) => Offset(mapRect.left + u / kM8SopMapW * mapRect.width, mapRect.top + v / kM8SopMapH * mapRect.height);

  Offset mapAt(Offset unit) => mapPoint(unit.dx, unit.dy);

  /// A pin's tip stands on its point; the body is above. A fat tap area.
  Rect pinHit(Offset unit) {
    final p = mapAt(unit);
    return Rect.fromCenter(center: p.translate(0, -16), width: 56, height: 60);
  }

  /// The van (centre at a map point).
  Rect vanRect(Offset unit) => Rect.fromCenter(center: mapAt(unit), width: 48, height: 30);
  Rect vanHit(Offset unit) => Rect.fromCenter(center: mapAt(unit), width: 72, height: 56);

  /// The close-up's picture area (a burnt DTR leaves room for its contacts).
  Rect closeup({bool dtr = false}) => Rect.fromLTRB(0, top, 360, (dtr ? contact(4).top : workBtn.top) - 8);

  /// The trainee in a close-up (left, standing on the ground line).
  Rect trainee({bool dtr = false}) {
    final a = closeup(dtr: dtr);
    return Rect.fromLTWH(4, a.bottom - 104, 46, 104);
  }

  /// The storm's damage (the camera's targets), inside the close-up.
  Rect damage(M8SopDamage d) {
    final a = closeup();
    return switch (d) {
      M8SopDamage.pole => Rect.fromLTWH(a.left + 96, a.top + 24, 70, a.height - 70),
      M8SopDamage.tree => Rect.fromLTWH(a.left + 182, a.top + a.height * 0.42, 150, a.height * 0.5),
    };
  }

  /// The scene as four tiles (the camera hint sweeps over all of them).
  List<Rect> get tiles {
    final a = closeup();
    final w = a.width / 2, h = a.height / 2;
    return [for (var r = 0; r < 2; r++) for (var c = 0; c < 2; c++) Rect.fromLTWH(c * w, a.top + r * h, w, h)];
  }

  @override
  bool operator ==(Object other) => other is M8SopGeo && other.height == height && other.inset == inset;

  @override
  int get hashCode => Object.hash(height, inset);
}

Paint _fill(Color c) => Paint()..color = c;
Paint _stroke(Color c, double w) => Paint()
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..color = c
  ..strokeCap = StrokeCap.round;

void _text(Canvas c, String text, Offset centre, {double size = 8, Color color = const Color(0xFFF4F1EA), FontWeight weight = FontWeight.w800, double maxWidth = 140}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: TextStyle(fontSize: size, fontWeight: weight, color: color, height: 1.1)),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  )..layout(maxWidth: maxWidth);
  tp.paint(c, centre - Offset(tp.width / 2, tp.height / 2));
}

// ============================================================================
// The map
// ============================================================================

/// The still map: the three areas, roads, buildings, the two DTRs and the
/// section office. Repaints only when the geometry changes.
class M8SopMapPainter extends CustomPainter {
  const M8SopMapPainter({required this.geo});
  final M8SopGeo geo;

  @override
  void paint(Canvas c, Size size) {
    final g = geo;
    final sky = Rect.fromLTWH(0, 0, size.width, size.height);
    c.drawRect(
        sky,
        Paint()
          ..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF16213F), Color(0xFF2B3B63), Color(0xFF3E5A63)]).createShader(sky));
    final m = g.mapRect;
    final edge = g.mapPoint(kM8SopTownEdge, 0).dx;
    final bazaar = g.mapPoint(105, 0).dx;
    // Town (left), the bazaar (middle), fields (right).
    final town = Rect.fromLTRB(m.left, m.top, bazaar, m.bottom);
    final bz = Rect.fromLTRB(bazaar, m.top, edge, m.bottom);
    final fields = Rect.fromLTRB(edge, m.top, m.right, m.bottom);
    c.drawRRect(RRect.fromRectAndRadius(town, const Radius.circular(10)), _fill(const Color(0xFF55606E)));
    c.drawRRect(RRect.fromRectAndRadius(bz, const Radius.circular(10)), _fill(const Color(0xFF8A7A5C)));
    c.drawRRect(RRect.fromRectAndRadius(fields, const Radius.circular(10)), Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF5F8F4A), Color(0xFF3F6B38)]).createShader(fields));
    // Crop strips in the fields.
    for (var k = 0; k < 6; k++) {
      final y = fields.top + 20 + k * (fields.height - 40) / 6;
      c.drawLine(Offset(fields.left + 8, y), Offset(fields.right - 8, y), _stroke(const Color(0x33FFFFFF), 1.2));
    }
    // Town blocks (tall) and bazaar stalls (low, awnings).
    for (var r = 0; r < 4; r++) {
      for (var k = 0; k < 2; k++) {
        final b = Rect.fromLTWH(town.left + 8 + k * 44, town.top + 18 + r * town.height / 4.4, 34, town.height / 4.4 - 14);
        c.drawRRect(RRect.fromRectAndRadius(b, const Radius.circular(3)), _fill(Color(0xFF8A94A3 + (r * 0x080808))));
        for (var w = 0; w < 3; w++) {
          c.drawRect(Rect.fromLTWH(b.left + 5 + w * 9, b.top + 6, 5, 6), _fill(const Color(0x88FFE9A8)));
        }
      }
    }
    for (var r = 0; r < 5; r++) {
      for (var k = 0; k < 2; k++) {
        final s = Rect.fromLTWH(bz.left + 8 + k * 46, bz.top + 14 + r * bz.height / 5.2, 36, bz.height / 5.2 - 16);
        c.drawRect(s, _fill(const Color(0xFFB5A27A)));
        c.drawRect(Rect.fromLTWH(s.left, s.top, s.width, 8), _fill(r.isEven ? const Color(0xFFC0493A) : const Color(0xFF3A7AA8)));
      }
    }
    // The village: huts with thatch.
    for (var i = 0; i < 5; i++) {
      final hx = fields.left + 14 + (i % 2) * 46 + (i == 4 ? 20 : 0);
      final hy = fields.top + 24 + i * (fields.height - 70) / 5;
      c.drawRect(Rect.fromLTWH(hx, hy + 8, 26, 16), _fill(const Color(0xFFC9B68A)));
      c.drawPath(Path()..moveTo(hx - 3, hy + 9)..lineTo(hx + 13, hy - 2)..lineTo(hx + 29, hy + 9)..close(), _fill(const Color(0xFF8A6A3A)));
    }
    // Roads: from the office up through the bazaar, a branch to each side.
    final office = g.mapAt(kM8SopOffice);
    final road = _stroke(const Color(0xFF2B2F36), 9);
    c.drawLine(office, Offset(bazaar + 8, m.top + 6), road);
    c.drawLine(Offset(bazaar + 8, m.center.dy), Offset(town.right - 52, m.center.dy), road);
    c.drawLine(Offset(bazaar + 8, m.center.dy + 20), Offset(edge + 28, m.center.dy + 40), road);
    c.drawLine(Offset(bazaar + 8, m.center.dy), Offset(bazaar + 8, m.top + 6), _stroke(const Color(0x55FFFFFF), 1.2));
    // The two DTRs on their poles (town left, village right).
    _dtr(c, g.mapPoint(20, 190));
    _dtr(c, g.mapPoint(300, 120));
    // The section office.
    final ob = Rect.fromCenter(center: office.translate(-34, -4), width: 62, height: 38);
    c.drawRRect(RRect.fromRectAndRadius(ob, const Radius.circular(4)), _fill(const Color(0xFFD9D2C0)));
    c.drawRect(Rect.fromLTWH(ob.left - 3, ob.top - 6, ob.width + 6, 8), _fill(const Color(0xFF3A5A8A)));
    c.drawRect(Rect.fromCenter(center: ob.center.translate(0, 6), width: 14, height: 20), _fill(const Color(0xFF4A3A2A)));
    _text(c, 'সেকশন অফিস', ob.topCenter.translate(0, -12), size: 7.5, color: const Color(0xFFE8E2D0));
    // Area tags.
    _text(c, 'শহর', Offset((town.left + bz.right) / 2, m.top - 8), size: 9, color: const Color(0xFFE8E2D0));
    _text(c, 'গ্রাম', Offset((fields.left + fields.right) / 2, m.top - 8), size: 9, color: const Color(0xFFE8E2D0));
  }

  void _dtr(Canvas c, Offset at) {
    c.drawRect(Rect.fromLTWH(at.dx - 2, at.dy - 22, 4, 26), _fill(const Color(0xFF6A4A30)));
    c.drawRect(Rect.fromLTWH(at.dx - 11, at.dy - 22, 22, 4), _fill(const Color(0xFF4A3622)));
    final t = Rect.fromCenter(center: at.translate(0, -30), width: 16, height: 14);
    c.drawRRect(RRect.fromRectAndRadius(t, const Radius.circular(2)), _fill(const Color(0xFF9AA3AB)));
    c.drawRect(Rect.fromLTWH(t.left + 2, t.top - 3, t.width - 4, 3), _fill(const Color(0xFF6B737C)));
  }

  @override
  bool shouldRepaint(M8SopMapPainter old) => old.geo != geo;
}

/// One pin on the map. All pins look alike.
@immutable
class M8SopPinView {
  const M8SopPinView({required this.unit, this.pop = 1});
  final Offset unit;

  /// 0..1 while it drops in; 1 at rest.
  final double pop;
}

/// The pins, the van and the dragged van. Repaints with [repaint] (the drive
/// and drop animations); otherwise only when its inputs change.
class M8SopPinsPainter extends CustomPainter {
  const M8SopPinsPainter({required this.geo, required this.pins, required this.van, this.vanTo, this.driveT, this.ghost, this.vanHidden = false, this.dropT, super.repaint});

  final M8SopGeo geo;
  final List<M8SopPinView> pins;
  final Offset van;

  /// While driving: where the van is going (map units) and the drive's value.
  final Offset? vanTo;
  final Animation<double>? driveT;
  final Offset? ghost;
  final bool vanHidden;

  /// The drop animation's value (0..1) for pins whose [M8SopPinView.pop] < 1.
  final Animation<double>? dropT;

  @override
  void paint(Canvas c, Size size) {
    for (final p in pins) {
      final t = p.pop >= 1 ? 1.0 : (dropT?.value ?? 1.0);
      _pin(c, geo.mapAt(p.unit), t);
    }
    if (!vanHidden) {
      final to = vanTo;
      final t = driveT;
      final at = to != null && t != null ? Offset.lerp(van, to, Curves.easeInOut.transform(t.value.clamp(0.0, 1.0)))! : van;
      _van(c, geo.mapAt(at), ghost: false);
    }
    final gh = ghost;
    if (gh != null) _van(c, gh, ghost: true);
  }

  void _pin(Canvas c, Offset tip, double t) {
    final lift = (1 - Curves.bounceOut.transform(t.clamp(0.0, 1.0))) * -90;
    final o = tip.translate(0, lift);
    c.drawOval(Rect.fromCenter(center: tip.translate(0, 1), width: 16, height: 5), _fill(const Color(0x66000000)));
    final body = Path()
      ..moveTo(o.dx, o.dy)
      ..cubicTo(o.dx - 17, o.dy - 18, o.dx - 14, o.dy - 38, o.dx, o.dy - 38)
      ..cubicTo(o.dx + 14, o.dy - 38, o.dx + 17, o.dy - 18, o.dx, o.dy)
      ..close();
    c.drawPath(body, Paint()..shader = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFFF6A5A), Color(0xFFC62828)]).createShader(Rect.fromLTWH(o.dx - 16, o.dy - 38, 32, 38)));
    c.drawPath(body, _stroke(const Color(0xFF7A1010), 1.4));
    c.drawCircle(o.translate(0, -23), 6.5, _fill(const Color(0xFFFFF4E0)));
    // A little bolt: a complaint (the same on every pin).
    final bolt = Path()
      ..moveTo(o.dx + 1.5, o.dy - 29)
      ..lineTo(o.dx - 3, o.dy - 22.5)
      ..lineTo(o.dx - 0.2, o.dy - 22.5)
      ..lineTo(o.dx - 1.6, o.dy - 17)
      ..lineTo(o.dx + 3.4, o.dy - 24)
      ..lineTo(o.dx + 0.5, o.dy - 24)
      ..close();
    c.drawPath(bolt, _fill(const Color(0xFFC62828)));
  }

  void _van(Canvas c, Offset at, {required bool ghost}) {
    final a = ghost ? 0.78 : 1.0;
    Color k(Color x) => x.withValues(alpha: a);
    final body = Rect.fromCenter(center: at.translate(0, -3), width: 44, height: 20);
    c.drawOval(Rect.fromCenter(center: at.translate(0, 11), width: 46, height: 6), _fill(const Color(0x55000000)));
    c.drawRRect(RRect.fromRectAndRadius(body, const Radius.circular(4)), _fill(k(const Color(0xFFF0A020))));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(body.right - 14, body.top + 2, 12, 9), const Radius.circular(2)), _fill(k(const Color(0xFF9FD3F0))));
    c.drawRect(Rect.fromLTWH(body.left + 4, body.top + 12, 16, 3), _fill(k(const Color(0xFF3A3A3A))));
    for (final dx in [-13.0, 13.0]) {
      c.drawCircle(at.translate(dx, 8), 4.2, _fill(k(const Color(0xFF222222))));
      c.drawCircle(at.translate(dx, 8), 1.6, _fill(k(const Color(0xFFBBBBBB))));
    }
    // A ladder on the roof: the crew's van.
    c.drawLine(Offset(body.left + 6, body.top - 3), Offset(body.right - 16, body.top - 3), _stroke(k(const Color(0xFFCCCCCC)), 1.6));
  }

  @override
  bool shouldRepaint(M8SopPinsPainter old) => old.geo != geo || old.van != van || old.vanTo != vanTo || old.ghost != ghost || old.vanHidden != vanHidden || !_same(old.pins, pins);

  static bool _same(List<M8SopPinView> a, List<M8SopPinView> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].unit != b[i].unit || a[i].pop != b[i].pop) return false;
    }
    return true;
  }
}

// ============================================================================
// The close-up
// ============================================================================

/// What a close-up shows now.
@immutable
class M8SopScene {
  const M8SopScene({required this.kind, required this.zone, required this.worked, this.informed = false, this.flash = 0});
  final M8SopKind kind;
  final M8SopZone zone;

  /// The repair is done: the houses are lit.
  final bool worked;

  /// A DTR's JE / station manager has been told.
  final bool informed;

  /// The camera's flash (0..1).
  final double flash;

  @override
  bool operator ==(Object other) => other is M8SopScene && other.kind == kind && other.zone == zone && other.worked == worked && other.informed == informed && other.flash == flash;

  @override
  int get hashCode => Object.hash(kind, zone, worked, informed, flash);
}

class M8SopCloseupPainter extends CustomPainter {
  const M8SopCloseupPainter({required this.geo, required this.scene});
  final M8SopGeo geo;
  final M8SopScene scene;

  @override
  void paint(Canvas c, Size size) {
    final s = scene;
    final dtr = s.kind == M8SopKind.dtr;
    final a = geo.closeup(dtr: dtr);
    final storm = s.kind == M8SopKind.storm;
    final skyRect = Rect.fromLTRB(0, 0, size.width, size.height);
    c.drawRect(
        skyRect,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: storm ? const [Color(0xFF2A3042), Color(0xFF59627A), Color(0xFF7C8496)] : const [Color(0xFF2C4E86), Color(0xFF7AA6D6), Color(0xFFD9C79E)],
          ).createShader(skyRect));
    final ground = Rect.fromLTRB(0, a.bottom - 30, size.width, size.height);
    c.drawRect(ground, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: s.zone == M8SopZone.rural ? const [Color(0xFF5D7F44), Color(0xFF3B5530)] : const [Color(0xFF59595F), Color(0xFF3A3A40)]).createShader(ground));
    _houses(c, a);
    switch (s.kind) {
      case M8SopKind.urbanFuse || M8SopKind.ruralFuse:
        _poleFuse(c, a);
      case M8SopKind.loose:
        _looseContact(c, a);
      case M8SopKind.wireBreak:
        _wireBreak(c, a);
      case M8SopKind.storm:
        _storm(c, a);
      case M8SopKind.dtr:
        _burntDtr(c, a);
      case M8SopKind.meter:
        _burntMeter(c, a);
    }
    // The crew works under the house rules (a worker's tag, not a hint).
    final tag = Rect.fromLTWH(a.right - 156, a.top + 6, 150, 20);
    c.drawRRect(RRect.fromRectAndRadius(tag, const Radius.circular(10)), _fill(const Color(0xCC0B1324)));
    c.drawRRect(RRect.fromRectAndRadius(tag, const Radius.circular(10)), _stroke(const Color(0xFFE8B44A), 1.2));
    _text(c, 'শাটডাউন · PTW · আর্থ', tag.center, size: 9, color: const Color(0xFFFFF4D6));
    if (s.flash > 0) c.drawRect(skyRect, _fill(Color.fromRGBO(255, 255, 255, 0.85 * s.flash)));
  }

  /// Three houses behind; lit once the repair is done.
  void _houses(Canvas c, Rect a) {
    final base = a.bottom - 30;
    final rural = scene.zone == M8SopZone.rural;
    for (var i = 0; i < 3; i++) {
      final w = 70.0;
      final h = rural ? 42.0 : 62.0 - i * 6;
      final x = a.left + 70 + i * 96.0;
      final r = Rect.fromLTWH(x, base - h, w, h);
      c.drawRect(r, _fill(rural ? const Color(0xFFC9B68A) : const Color(0xFF9AA3AF)));
      if (rural) {
        c.drawPath(Path()..moveTo(r.left - 6, r.top + 2)..lineTo(r.center.dx, r.top - 20)..lineTo(r.right + 6, r.top + 2)..close(), _fill(const Color(0xFF8A6A3A)));
      } else {
        c.drawRect(Rect.fromLTWH(r.left - 2, r.top - 4, r.width + 4, 5), _fill(const Color(0xFF6B737C)));
      }
      final lit = scene.worked && scene.kind != M8SopKind.dtr;
      for (var k = 0; k < 2; k++) {
        final w0 = Rect.fromLTWH(r.left + 12 + k * 30, r.top + 12, 16, 14);
        if (lit) c.drawRect(w0.inflate(5), _fill(const Color(0x33FFE9A8)));
        c.drawRect(w0, _fill(lit ? const Color(0xFFFFE9A8) : const Color(0xFF1B2030)));
      }
    }
  }

  void _pole(Canvas c, double x, double top, double bottom, {double lean = 0}) {
    c.drawLine(Offset(x + lean, top), Offset(x, bottom), _stroke(const Color(0xFF6A4A30), 9));
    c.drawLine(Offset(x + lean - 26, top + 10), Offset(x + lean + 26, top + 10), _stroke(const Color(0xFF4A3622), 5));
    for (final dx in [-24.0, 0.0, 24.0]) {
      c.drawCircle(Offset(x + lean + dx, top + 6), 3.4, _fill(const Color(0xFFB87333)));
    }
  }

  void _poleFuse(Canvas c, Rect a) {
    final base = a.bottom - 30;
    final x = a.left + 130;
    _pole(c, x, a.top + 44, base);
    // The fuse unit on the pole: its carrier hangs open (blown) until fixed.
    final box = Rect.fromLTWH(x + 8, a.top + 96, 26, 18);
    c.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(3)), _fill(const Color(0xFF9AA3AB)));
    final open = !scene.worked;
    final carrier = Offset(box.center.dx, box.bottom);
    final end = open ? carrier.translate(14, 22) : carrier.translate(0, 26);
    c.drawLine(carrier, end, _stroke(const Color(0xFF3A3A3A), 5));
    c.drawLine(Offset(x - 24, a.top + 50), Offset(a.right, a.top + 56), _stroke(const Color(0xFF222222), 1.8));
    c.drawLine(Offset(x + 24, a.top + 50), Offset(x + 90, a.top + 56), _stroke(const Color(0xFF222222), 1.8));
  }

  void _looseContact(Canvas c, Rect a) {
    final base = a.bottom - 30;
    final x = a.left + 130;
    _pole(c, x, a.top + 44, base);
    // A service connection with a loose contact: a clamp with a spark mark.
    final clamp = Offset(x + 18, a.top + 120);
    c.drawLine(Offset(x, a.top + 70), clamp, _stroke(const Color(0xFF222222), 2));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: clamp, width: 16, height: 12), const Radius.circular(2)), _fill(const Color(0xFFB87333)));
    c.drawLine(clamp, Offset(a.right - 40, a.top + 150), _stroke(const Color(0xFF222222), 2));
    if (!scene.worked) {
      c.drawCircle(clamp.translate(8, -6), 4, _fill(const Color(0x88FFD54F)));
    }
  }

  void _wireBreak(Canvas c, Rect a) {
    final base = a.bottom - 30;
    final x1 = a.left + 90;
    final x2 = a.left + 270;
    _pole(c, x1, a.top + 44, base);
    _pole(c, x2, a.top + 44, base);
    final p1 = Offset(x1 + 26, a.top + 54);
    final p2 = Offset(x2 - 26, a.top + 54);
    final mid = Offset((p1.dx + p2.dx) / 2, a.top + 54);
    if (scene.worked) {
      c.drawPath(Path()..moveTo(p1.dx, p1.dy)..quadraticBezierTo(mid.dx, mid.dy + 14, p2.dx, p2.dy), _stroke(const Color(0xFF222222), 2));
    } else {
      // The wire has snapped: both ends hang clear of the ground.
      c.drawPath(Path()..moveTo(p1.dx, p1.dy)..quadraticBezierTo(p1.dx + 18, p1.dy + 40, p1.dx + 28, p1.dy + 62), _stroke(const Color(0xFF222222), 2));
      c.drawPath(Path()..moveTo(p2.dx, p2.dy)..quadraticBezierTo(p2.dx - 18, p2.dy + 40, p2.dx - 28, p2.dy + 62), _stroke(const Color(0xFF222222), 2));
    }
  }

  void _storm(Canvas c, Rect a) {
    final base = a.bottom - 30;
    final pole = geo.damage(M8SopDamage.pole);
    final tree = geo.damage(M8SopDamage.tree);
    final broken = !scene.worked;
    // The pole: snapped halfway while broken, whole again after the repair.
    final x = pole.center.dx;
    if (broken) {
      c.drawLine(Offset(x, base), Offset(x, pole.top + pole.height * 0.55), _stroke(const Color(0xFF6A4A30), 9));
      c.drawLine(Offset(x, pole.top + pole.height * 0.55), Offset(x + 52, pole.top + pole.height * 0.55 + 26), _stroke(const Color(0xFF6A4A30), 9));
      c.drawPath(Path()..moveTo(x + 52, pole.top + pole.height * 0.55 + 26)..quadraticBezierTo(x + 80, pole.top + 90, x + 110, pole.top + 100), _stroke(const Color(0xFF222222), 2));
    } else {
      _pole(c, x, pole.top, base);
    }
    // The fallen tree.
    final trunk = Rect.fromLTRB(tree.left, tree.bottom - 24, tree.right - 30, tree.bottom - 4);
    c.drawRRect(RRect.fromRectAndRadius(trunk, const Radius.circular(10)), _fill(broken ? const Color(0xFF5A4028) : const Color(0xFF6A5236)));
    for (var i = 0; i < 4; i++) {
      c.drawCircle(Offset(tree.right - 40 + (i % 2) * 14, tree.bottom - 28 - i * 10), 18, _fill(const Color(0xFF2F6B3A)));
    }
    if (broken) {
      // The crew's cordon tape already up.
      c.drawLine(Offset(a.left + 56, base - 4), Offset(a.left + 56, base - 54), _stroke(const Color(0xFF7A6A55), 3));
      c.drawLine(Offset(a.left + 300, base - 4), Offset(a.left + 300, base - 54), _stroke(const Color(0xFF7A6A55), 3));
      c.drawLine(Offset(a.left + 56, base - 46), Offset(a.left + 300, base - 46), _stroke(const Color(0xFFE8B44A), 4));
    }
    // Rain streaks.
    final rain = _stroke(const Color(0x55CFE3FF), 1);
    for (var i = 0; i < 18; i++) {
      final rx = a.left + 10 + i * 19.0;
      final ry = a.top + 30 + (i * 37) % 90;
      c.drawLine(Offset(rx, ry), Offset(rx - 6, ry + 14), rain);
    }
  }

  void _burntDtr(Canvas c, Rect a) {
    final base = a.bottom - 30;
    final x = a.left + 150;
    _pole(c, x, a.top + 26, base);
    // The DTR tank on the pole: scorched, smoking, an oil stain below.
    final tank = Rect.fromCenter(center: Offset(x + 2, a.top + 108), width: 62, height: 58);
    c.drawRRect(RRect.fromRectAndRadius(tank, const Radius.circular(5)), _fill(const Color(0xFF4A4F55)));
    for (var i = 0; i < 4; i++) {
      c.drawRect(Rect.fromLTWH(tank.left + 6 + i * 14, tank.top + 8, 6, tank.height - 14), _fill(const Color(0xFF3A3E43)));
    }
    c.drawRect(Rect.fromLTWH(tank.left, tank.top - 6, tank.width, 6), _fill(const Color(0xFF2A2D31)));
    final soot = Rect.fromLTWH(tank.left, tank.top, tank.width, 18);
    c.drawRect(soot, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xCC000000), Color(0x00000000)]).createShader(soot));
    for (var i = 0; i < 4; i++) {
      c.drawCircle(Offset(tank.center.dx - 6 + i * 6, tank.top - 18 - i * 17), 10 + i * 4.0, _fill(Color.fromRGBO(120, 120, 126, 0.55 - i * 0.1)));
    }
    c.drawOval(Rect.fromCenter(center: Offset(x + 18, base - 4), width: 90, height: 14), _fill(const Color(0xAA1A1208)));
    // The AB switch on the crossarm: three blades open, its handle locked and
    // tagged; HG fuses below it.
    final arm = a.top + 30;
    for (var i = 0; i < 3; i++) {
      final bx = x - 24 + i * 24.0;
      c.drawLine(Offset(bx, arm + 4), Offset(bx + 8, arm - 16), _stroke(const Color(0xFFDDDDDD), 2.4));
      c.drawLine(Offset(bx, arm + 4), Offset(bx, arm + 26), _stroke(const Color(0xFF9AA3AB), 3));
    }
    _text(c, 'AB', Offset(x - 40, arm - 8), size: 9, color: const Color(0xFFFFF4D6));
    c.drawLine(Offset(x + 14, arm + 28), Offset(x + 14, a.top + 78), _stroke(const Color(0xFF8A8A8A), 2.4));
    c.drawCircle(Offset(x + 14, a.top + 82), 4, _fill(const Color(0xFFC9A227)));
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x + 20, a.top + 76, 12, 15), const Radius.circular(2)), _fill(const Color(0xFFD7332A)));
    for (var i = 0; i < 3; i++) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x - 28 + i * 20, arm + 30, 8, 18), const Radius.circular(3)), _fill(const Color(0xFFB8A27A)));
    }
    _text(c, 'HG', Offset(x - 42, arm + 40), size: 8, color: const Color(0xFFFFF4D6));
  }

  void _burntMeter(Canvas c, Rect a) {
    final wall = Rect.fromLTRB(a.left + 70, a.top + 50, a.right - 70, a.bottom - 30);
    c.drawRect(wall, _fill(const Color(0xFFC9BFA5)));
    final m = Rect.fromCenter(center: wall.center.translate(0, -10), width: 70, height: 84);
    c.drawRRect(RRect.fromRectAndRadius(m, const Radius.circular(6)), _fill(const Color(0xFF3A3A3E)));
    c.drawRect(Rect.fromLTWH(m.left + 8, m.top + 10, m.width - 16, 20), _fill(const Color(0xFF111111)));
    final soot = Rect.fromLTWH(m.left, m.top, m.width, m.height);
    c.drawRect(soot, Paint()..shader = const RadialGradient(colors: [Color(0xAA000000), Color(0x00000000)]).createShader(soot));
    c.drawLine(Offset(m.center.dx, m.bottom), Offset(m.center.dx, wall.bottom), _stroke(const Color(0xFF222222), 3));
  }

  @override
  bool shouldRepaint(M8SopCloseupPainter old) => old.geo != geo || old.scene != scene;
}

/// A viewfinder: four corners and a cross (the camera is up).
class M8SopViewfinderPainter extends CustomPainter {
  const M8SopViewfinderPainter({required this.area});
  final Rect area;

  @override
  void paint(Canvas c, Size size) {
    final r = area.deflate(14);
    final p = _stroke(const Color(0xFFFFFFFF), 2.4);
    const l = 24.0;
    for (final (corner, dx, dy) in [(r.topLeft, 1.0, 1.0), (r.topRight, -1.0, 1.0), (r.bottomLeft, 1.0, -1.0), (r.bottomRight, -1.0, -1.0)]) {
      c.drawLine(corner, corner.translate(dx * l, 0), p);
      c.drawLine(corner, corner.translate(0, dy * l), p);
    }
    c.drawLine(r.center.translate(-8, 0), r.center.translate(8, 0), _stroke(const Color(0xAAFFFFFF), 1.4));
    c.drawLine(r.center.translate(0, -8), r.center.translate(0, 8), _stroke(const Color(0xAAFFFFFF), 1.4));
    c.drawCircle(r.topLeft.translate(34, 14), 4, _fill(const Color(0xFFE53935)));
  }

  @override
  bool shouldRepaint(M8SopViewfinderPainter old) => old.area != area;
}

/// A ring that fills as a hold goes on (the work button, a contact).
class M8SopRingPainter extends CustomPainter {
  const M8SopRingPainter({required this.progress, super.repaint});
  final Animation<double> progress;

  @override
  void paint(Canvas c, Size size) {
    final v = progress.value;
    if (v <= 0) return;
    final r = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(16)).deflate(2);
    final path = Path()..addRRect(r);
    final metrics = path.computeMetrics().first;
    c.drawPath(metrics.extractPath(0, metrics.length * v), _stroke(const Color(0xFFFFD54F), 4));
  }

  @override
  bool shouldRepaint(M8SopRingPainter old) => old.progress != progress;
}

/// A little helper for tests and layout: the distance in map units.
double m8SopDistance(Offset a, Offset b) => math.sqrt((a.dx - b.dx) * (a.dx - b.dx) + (a.dy - b.dy) * (a.dy - b.dy));
