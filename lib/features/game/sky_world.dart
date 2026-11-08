import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// The roadside where the weather turns (ladder step 26, lesson 1.9 "আকাশ
// পড়ুন"): a drawn, layered place — the sky and its clouds (building, darkening),
// a far tree line and village, paddy fields, wind-bent trees, an 11 kV PCC pole
// with its cross-arm, porcelain pin insulators and three conductors running to
// the next pole, the verge and the road. The weather is a value
// ([SkyWeather]): cloud, darkness, drizzle, wind (km/h, bends the trees and
// makes the wires gallop) and lightning (a far cell on the horizon, or a near
// bolt) — flashes come from the page. No text in the art.
//
// Design: 360 wide × the scene's height; the ground row follows the bottom of
// the screen (a tall phone gets more sky).

/// Lightning in the scene.
enum SkyBolt { none, far, near }

/// Where things stand (design px, 360 wide).
@immutable
class SkyGeo {
  const SkyGeo({required this.height, required this.groundY, required this.length});

  factory SkyGeo.forScene(double h, double inset) {
    final g = h - 170 - inset;
    return SkyGeo(height: h, groundY: g, length: (g - 230).clamp(270.0, 430.0));
  }

  /// The pole's axis (left of centre: the guide stands bottom right).
  static const cx = 124.0;

  /// The next pole down the line (smaller: further away).
  static const farX = 318.0;

  final double height;
  final double groundY;
  final double length;

  double get s => length / 370;
  double get topY => groundY - length;
  double get armY => topY + 26 * s;
  double get horizonY => groundY - 78;
  double get ppm => length / 9;

  /// The insulator tops on the cross-arm (left, middle on the pole top, right).
  List<Offset> get pins => [
        Offset(cx - 56 * s, armY - 16 * s),
        Offset(cx, topY - 10 * s),
        Offset(cx + 56 * s, armY - 16 * s),
      ];

  double get farTop => horizonY - 150;
  double get farBase => horizonY + 40;
  List<Offset> get farPins => [
        Offset(farX - 20, farTop + 10),
        Offset(farX, farTop - 4),
        Offset(farX + 20, farTop + 10),
      ];

  @override
  bool operator ==(Object other) => other is SkyGeo && other.height == height && other.groundY == groundY && other.length == length;

  @override
  int get hashCode => Object.hash(height, groundY, length);
}

/// The weather in the scene.
@immutable
class SkyWeather {
  const SkyWeather({this.cloud = 0.2, this.dark = 0, this.rain = 0, this.wind = 8, this.bolt = SkyBolt.none});

  /// Cloud cover 0–1.
  final double cloud;

  /// How dark the sky is, 0–1.
  final double dark;

  /// Drizzle 0–1.
  final double rain;

  /// Wind, km/h.
  final double wind;
  final SkyBolt bolt;

  /// A fair morning (before the weather turns).
  static const fair = SkyWeather();

  static SkyWeather lerp(SkyWeather a, SkyWeather b, double t) => SkyWeather(
        cloud: ui.lerpDouble(a.cloud, b.cloud, t)!,
        dark: ui.lerpDouble(a.dark, b.dark, t)!,
        rain: ui.lerpDouble(a.rain, b.rain, t)!,
        wind: ui.lerpDouble(a.wind, b.wind, t)!,
        bolt: t > 0.6 ? b.bolt : a.bolt,
      );

  @override
  bool operator ==(Object other) =>
      other is SkyWeather && other.cloud == cloud && other.dark == dark && other.rain == rain && other.wind == wind && other.bolt == bolt;

  @override
  int get hashCode => Object.hash(cloud, dark, rain, wind, bolt);
}

/// A lightning flash's light at [v] (0–1 of the flash): two strokes.
double flashLight(double v) {
  if (v <= 0 || v >= 1) return 0;
  double pulse(double c, double w) => math.exp(-math.pow((v - c) / w, 2).toDouble());
  return math.max(pulse(0.08, 0.06), 0.75 * pulse(0.32, 0.07));
}

/// How far the wires swing at [wind] km/h (design px at scale 1): a gallop
/// above 40, a slight sway below.
double gallopOf(double wind) => wind >= 40 ? 12 + (wind - 40) * 0.45 : wind / 40 * 2;

/// The sky, the land, the trees, the pole and the wires. [t]: seconds of
/// motion (advances only while the scene is awake); [flash]: 0–1 of the
/// current lightning flash.
class SkyWorldPainter extends CustomPainter {
  SkyWorldPainter({required this.geo, required this.weather, required this.t, required this.flash, this.seed = 0})
      : super(repaint: Listenable.merge([t, flash]));
  final SkyGeo geo;
  final SkyWeather weather;
  final ValueListenable<double> t;
  final Animation<double> flash;
  final int seed;

  static Color _mix(Color a, Color b, double k) => Color.lerp(a, b, k.clamp(0.0, 1.0))!;

  @override
  void paint(Canvas c, Size size) {
    final w = size.width;
    final hz = geo.horizonY;
    final g = geo.groundY;
    final wx = weather;
    final time = t.value;
    final light = flashLight(flash.value);
    final dk = wx.dark;

    // --- sky ------------------------------------------------------------------
    final sky = Rect.fromLTWH(0, 0, w, hz + 6);
    c.drawRect(
      sky,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _mix(const Color(0xFF5F9ED3), const Color(0xFF232C3A), dk),
            _mix(const Color(0xFFA2C9E8), const Color(0xFF3E4857), dk),
            _mix(const Color(0xFFEDE6CF), const Color(0xFF666D74), dk),
          ],
          stops: const [0, 0.6, 1],
        ).createShader(sky),
    );
    // The sun's glow fades behind the cloud.
    final sunA = (1 - wx.cloud * 1.3).clamp(0.0, 1.0);
    if (sunA > 0.02) {
      final sun = Offset(w * 0.8, hz * 0.32);
      c.drawCircle(
          sun,
          110,
          Paint()
            ..shader = RadialGradient(colors: [Color.fromRGBO(255, 244, 210, 0.5 * sunA), const Color(0x00FFF4D2)])
                .createShader(Rect.fromCircle(center: sun, radius: 110)));
      c.drawCircle(sun, 15, Paint()..color = Color.fromRGBO(255, 246, 220, sunA));
    }

    // A far storm cell on the horizon (right), its rain shafts under it.
    if (wx.bolt == SkyBolt.far) _farCell(c, hz, light, time);

    // Clouds: puffs that build with the cover and darken with the sky; they
    // drift with the wind while the scene is awake.
    _clouds(c, w, hz, time);

    // A low overcast deck when the cover is heavy.
    if (wx.cloud > 0.55) {
      final a = ((wx.cloud - 0.55) / 0.45).clamp(0.0, 1.0);
      final deck = Rect.fromLTWH(0, 0, w, hz * 0.55);
      c.drawRect(
        deck,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.fromRGBO(40, 46, 56, 0.85 * a), const Color(0x00282E38)],
          ).createShader(deck),
      );
    }

    // The near bolt: from the cloud to a tree across the fields.
    if (wx.bolt == SkyBolt.near && light > 0.2) {
      _bolt(c, Offset(292, 0), Offset(306, hz + 8), light, 7, seed + 11, branches: true);
    }
    // The flash lights the whole sky.
    if (light > 0) {
      c.drawRect(sky, Paint()..color = Color.fromRGBO(235, 240, 255, (wx.bolt == SkyBolt.near ? 0.55 : 0.16) * light));
    }

    // --- far land -------------------------------------------------------------
    final farTone = _mix(const Color(0xFF4F7A55), const Color(0xFF26382C), dk);
    final tree = Path()..moveTo(0, hz);
    for (var x = 0.0; x <= w + 16; x += 16) {
      final bump = 13 + 8 * math.sin(x * 0.05) + 5 * math.sin(x * 0.17 + 1.1);
      tree.quadraticBezierTo(x + 8, hz - bump - 9, x + 16, hz - bump * 0.6);
    }
    tree
      ..lineTo(w, hz + 4)
      ..lineTo(0, hz + 4)
      ..close();
    c.drawPath(tree, Paint()..color = farTone);
    // Village huts with tin roofs among the trees (left).
    final hut = _mix(const Color(0xFFB59A74), const Color(0xFF5A5046), dk);
    final roof = _mix(const Color(0xFF8E979E), const Color(0xFF454B50), dk);
    for (final (x, sz) in const [(22.0, 1.0), (58.0, 0.8), (196.0, 0.9)]) {
      final b = Rect.fromLTWH(x, hz - 12 * sz, 24 * sz, 12 * sz);
      c.drawRect(b, Paint()..color = hut);
      c.drawPath(
          Path()
            ..moveTo(x - 3 * sz, hz - 11 * sz)
            ..lineTo(x + 12 * sz, hz - 20 * sz)
            ..lineTo(x + 27 * sz, hz - 11 * sz)
            ..close(),
          Paint()..color = roof);
    }

    // --- fields -------------------------------------------------------------------
    final field = Rect.fromLTRB(0, hz, w, g + 10);
    c.drawRect(
      field,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _mix(const Color(0xFF8DB860), const Color(0xFF3F5532), dk),
            _mix(const Color(0xFF6E9E45), const Color(0xFF34482A), dk),
          ],
        ).createShader(field),
    );
    // Paddy rows (perspective lines) — they ripple in the wind.
    final row = Paint()
      ..color = _mix(const Color(0x335A7F2E), const Color(0x33202C18), dk)
      ..strokeWidth = 1.2;
    for (var i = 1; i < 7; i++) {
      final y = hz + (g - hz) * (i / 7) * (i / 7) * 0.9;
      final ripple = math.sin(time * 2.4 + i) * wx.wind / 60;
      c.drawLine(Offset(0, y + ripple), Offset(w, y - ripple), row);
    }
    if (light > 0) c.drawRect(field, Paint()..color = Color.fromRGBO(230, 236, 255, (wx.bolt == SkyBolt.near ? 0.22 : 0.05) * light));

    // --- trees (wind-bent) ----------------------------------------------------------
    final bend = (wx.wind / 60).clamp(0.0, 1.3);
    double sway(double ph) => math.sin(time * (2.2 + bend * 2.4) + ph) * (0.03 + 0.07 * bend);
    _palm(c, Offset(262, hz + 22), 92, bend * 0.5 + sway(0.3), dk);
    _roundTree(c, Offset(34, hz + 30), 70, bend * 0.36 + sway(1.7), dk);
    _roundTree(c, Offset(206, hz + 14), 46, bend * 0.32 + sway(2.6), dk);
    _palm(c, Offset(348, hz + 34), 78, bend * 0.52 + sway(4.1), dk);

    // --- the far pole and the wires -------------------------------------------------
    final farPaint = Paint()..color = _mix(const Color(0xFF9B9890), const Color(0xFF55575A), dk);
    c.drawPath(
        Path()
          ..moveTo(SkyGeo.farX - 3, geo.farBase)
          ..lineTo(SkyGeo.farX - 2, geo.farTop)
          ..lineTo(SkyGeo.farX + 2, geo.farTop)
          ..lineTo(SkyGeo.farX + 3, geo.farBase)
          ..close(),
        farPaint);
    c.drawRect(Rect.fromLTWH(SkyGeo.farX - 24, geo.farTop + 10, 48, 3), Paint()..color = _mix(const Color(0xFF70757A), const Color(0xFF3C4044), dk));
    final porcelain = Paint()..color = _mix(const Color(0xFF7A4A2A), const Color(0xFF3F2716), dk);
    for (final p in geo.farPins) {
      c.drawRect(Rect.fromCenter(center: p.translate(0, 3), width: 4, height: 6), porcelain);
    }

    // --- the pole -------------------------------------------------------------------------
    _pole(c, dk, light);

    // The wires: from the left edge, over the pins, to the next pole. They
    // gallop in a strong wind.
    final amp = gallopOf(wx.wind) * geo.s;
    final wire = Paint()
      ..color = _mix(const Color(0xFF2E3338), const Color(0xFF15181B), dk)
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final gallop = wx.wind >= 40;
    for (var i = 0; i < 3; i++) {
      final a = geo.pins[i];
      final b = geo.farPins[i];
      final left = Offset(-20, a.dy + 26 + i * 4);
      // A span: the sag, plus a travelling wave — one and a half loops when
      // the wires gallop, a slight sway otherwise.
      Path span(Offset p, Offset q, double sag, double ph) {
        final path = Path()..moveTo(p.dx, p.dy);
        const n = 24;
        for (var j = 1; j <= n; j++) {
          final k = j / n;
          final env = math.sin(math.pi * k);
          final wave = gallop ? math.sin(k * math.pi * 3 + time * 3.2 + ph) * env : math.sin(time * 2.6 + ph) * env;
          final pt = Offset.lerp(p, q, k)!;
          path.lineTo(pt.dx, pt.dy + sag * 4 * k * (1 - k) + wave * amp);
        }
        return path;
      }

      c.drawPath(span(left, a, 20 * geo.s, i * 1.3 + 1), wire);
      c.drawPath(span(a, b, 30 * geo.s, i * 1.9), wire);
    }

    // --- the verge and the road -------------------------------------------------------------
    final verge = Rect.fromLTRB(0, g - 26, w, g + 30);
    c.drawRect(
      verge,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_mix(const Color(0xFF5E8E3A), const Color(0xFF2E4520), dk), _mix(const Color(0xFF7A6A48), const Color(0xFF3E362A), dk)],
        ).createShader(verge),
    );
    final road = Rect.fromLTRB(0, g + 30, w, size.height);
    c.drawRect(
      road,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _mix(const Color(0xFF8A7B62), const Color(0xFF3B3A38), dk + wx.rain * 0.3),
            _mix(const Color(0xFF6E624E), const Color(0xFF2A2927), dk + wx.rain * 0.3),
          ],
        ).createShader(road),
    );
    // Grass tufts (they lean with the wind).
    final tuft = Paint()
      ..color = _mix(const Color(0xFF4C7A2C), const Color(0xFF23361A), dk)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    for (var x = 6.0; x < w; x += 19) {
      final lean = 3 + bend * 7 + math.sin(time * 4 + x) * bend * 2;
      for (final k in const [-3.0, 0.0, 3.0]) {
        c.drawLine(Offset(x + k, g + 4), Offset(x + k + lean, g - 8 - (k == 0 ? 3 : 0)), tuft);
      }
    }
    // Puddles once it rains: grey sky in them.
    if (wx.rain > 0.05) {
      final pa = (wx.rain * 1.6).clamp(0.0, 1.0);
      for (final (x, y, rw) in [(40.0, g + 52, 54.0), (200.0, g + 74, 70.0), (300.0, g + 46, 40.0), (SkyGeo.cx + 26, g + 20, 34.0)]) {
        final r = Rect.fromCenter(center: Offset(x, y), width: rw, height: rw * 0.2);
        c.drawOval(r, Paint()..color = Color.fromRGBO(120, 132, 146, 0.55 * pa));
        c.drawOval(r.deflate(3), Paint()..color = Color.fromRGBO(170, 182, 196, 0.35 * pa));
      }
    }
    if (light > 0 && wx.bolt == SkyBolt.near) {
      c.drawRect(Rect.fromLTRB(0, hz, w, size.height), Paint()..color = Color.fromRGBO(230, 236, 255, 0.18 * light));
    }
  }

  void _clouds(Canvas c, double w, double hz, double time) {
    final wx = weather;
    final drift = time * (4 + wx.wind * 0.35);
    final tone = _mix(const Color(0xFFFFFFFF), const Color(0xFF4A515C), wx.dark * 1.1);
    final shade = _mix(const Color(0xFFDDE5EE), const Color(0xFF353B45), wx.dark * 1.1);
    const puffs = [
      (40.0, 0.30, 22.0),
      (250.0, 0.20, 18.0),
      (150.0, 0.42, 26.0),
      (330.0, 0.36, 20.0),
      (90.0, 0.12, 30.0),
      (210.0, 0.55, 24.0),
      (300.0, 0.08, 34.0),
      (10.0, 0.50, 28.0),
      (180.0, 0.05, 36.0),
      (120.0, 0.25, 32.0),
      (280.0, 0.62, 26.0),
      (60.0, 0.68, 22.0),
    ];
    final n = (puffs.length * (0.25 + wx.cloud * 0.75)).round().clamp(2, puffs.length);
    for (var i = 0; i < n; i++) {
      final (x0, yk, r0) = puffs[i];
      final r = r0 * (0.8 + wx.cloud * 0.7);
      final x = (x0 + drift * (0.6 + 0.1 * (i % 3))) % (w + 160) - 80;
      final y = hz * yk + 30;
      c.drawOval(Rect.fromCenter(center: Offset(x, y + r * 0.2), width: r * 4.4, height: r * 1.3), Paint()..color = shade);
      final p = Paint()..color = tone;
      c.drawOval(Rect.fromCenter(center: Offset(x, y), width: r * 4.0, height: r * 1.2), p);
      c.drawCircle(Offset(x - r * 0.7, y - r * 0.3), r * 0.8, p);
      c.drawCircle(Offset(x + r * 0.5, y - r * 0.5), r, p);
    }
  }

  void _farCell(Canvas c, double hz, double light, double time) {
    // A thundercloud far off on the right: a tall billowing tower, a flat
    // dark base high above the horizon, grey rain shafts under it.
    final base = hz - 58;
    final shaft = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x995A6676), Color(0x225A6676)],
      ).createShader(Rect.fromLTRB(230, base, 360, hz));
    c.drawPath(
        Path()
          ..moveTo(236, base)
          ..lineTo(352, base)
          ..lineTo(340, hz)
          ..lineTo(226, hz)
          ..close(),
        shaft);
    final rect = Rect.fromLTRB(206, base - 150, 372, base + 6);
    final body = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF8A93A0), Color(0xFF4A5260), Color(0xFF262C36)],
        stops: [0, 0.45, 1],
      ).createShader(rect);
    const puffs = [
      (232.0, -18.0, 22.0),
      (262.0, -30.0, 30.0),
      (300.0, -26.0, 32.0),
      (338.0, -20.0, 26.0),
      (360.0, -12.0, 18.0),
      (258.0, -62.0, 24.0),
      (290.0, -78.0, 30.0),
      (322.0, -66.0, 26.0),
      (282.0, -112.0, 24.0),
      (306.0, -120.0, 22.0),
    ];
    for (final (x, dy, r) in puffs) {
      c.drawCircle(Offset(x, base + dy), r, body);
    }
    // The spreading top.
    c.drawOval(Rect.fromCenter(center: Offset(296, base - 134), width: 132, height: 24), body);
    c.drawRect(Rect.fromLTRB(214, base - 16, 368, base + 2), Paint()..color = const Color(0xFF262C36));
    if (light > 0) {
      final glow = Offset(292, base - 50);
      c.drawCircle(
          glow,
          80,
          Paint()
            ..shader = RadialGradient(colors: [Color.fromRGBO(220, 228, 255, 0.85 * light), const Color(0x00DCE4FF)])
                .createShader(Rect.fromCircle(center: glow, radius: 80)));
      if (light > 0.3) _bolt(c, Offset(290, base), Offset(278, hz - 2), light, 2.2, seed + 3);
    }
  }

  /// A jagged lightning stroke from [a] to [b].
  void _bolt(Canvas c, Offset a, Offset b, double light, double width, int s, {bool branches = false}) {
    final rnd = math.Random(s);
    final pts = <Offset>[a];
    const steps = 9;
    for (var i = 1; i < steps; i++) {
      final k = i / steps;
      final p = Offset.lerp(a, b, k)!;
      pts.add(p.translate((rnd.nextDouble() - 0.5) * 26 * (width / 3 + 0.6), (rnd.nextDouble() - 0.5) * 8));
    }
    pts.add(b);
    final path = Path()..addPolygon(pts, false);
    c.drawPath(
        path,
        Paint()
          ..color = Color.fromRGBO(170, 190, 255, 0.55 * light)
          ..style = PaintingStyle.stroke
          ..strokeWidth = width * 3.4
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    final core = Paint()
      ..color = Color.fromRGBO(255, 255, 255, light.clamp(0.0, 1.0))
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeJoin = StrokeJoin.round;
    c.drawPath(path, core);
    if (branches) {
      for (final i in const [3, 5]) {
        final from = pts[i];
        final to = from.translate(rnd.nextBool() ? 30 : -30, 46);
        c.drawLine(from, Offset.lerp(from, to, 0.5)!.translate(6, 0), core..strokeWidth = width * 0.4);
        c.drawLine(Offset.lerp(from, to, 0.5)!.translate(6, 0), to, core);
      }
    }
  }

  void _pole(Canvas c, double dk, double light) {
    final s = geo.s;
    const cx = SkyGeo.cx;
    final g = geo.groundY;
    final top = geo.topY;
    final wet = weather.rain;
    final half0 = 9 * s + 2;
    final half1 = 5.5 * s + 1.5;
    final body = Path()
      ..moveTo(cx - half0, g + 4)
      ..lineTo(cx - half1, top)
      ..lineTo(cx + half1, top)
      ..lineTo(cx + half0, g + 4)
      ..close();
    final dry0 = _mix(const Color(0xFFC9C5BA), const Color(0xFF6E6C67), dk);
    final dry1 = _mix(const Color(0xFF9C988E), const Color(0xFF4C4A46), dk);
    final k = wet * 0.6;
    c.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(colors: [
          _mix(dry1, const Color(0xFF55585A), k),
          _mix(dry0, const Color(0xFF7D8184), k),
          _mix(dry1, const Color(0xFF44474A), k),
        ], stops: const [0, 0.45, 1])
            .createShader(Rect.fromLTRB(cx - half0, top, cx + half0, g)),
    );
    // Wet: water runs down it in shiny streaks.
    if (wet > 0.05) {
      final sheen = Paint()
        ..color = Color.fromRGBO(220, 232, 245, 0.55 * wet.clamp(0.0, 1.0))
        ..strokeWidth = 1.1;
      for (final (fx, y0, y1) in const [(-0.4, 0.05, 0.42), (0.2, 0.2, 0.75), (-0.1, 0.55, 0.95), (0.45, 0.6, 0.88)]) {
        final ya = top + (g - top) * y0;
        final yb = top + (g - top) * y1;
        c.drawLine(Offset(cx + fx * half0, ya), Offset(cx + fx * half0 * 1.05, yb), sheen);
      }
    }
    // Step bolts.
    final bolt = Paint()..color = _mix(const Color(0xFF6B7076), const Color(0xFF34373A), dk);
    for (var m = 2.0; m < 8.4; m += 0.8) {
      final y = g - m * geo.ppm;
      final left = (m * 10).round().isEven;
      c.drawRect(Rect.fromLTWH(left ? cx - half0 - 6 * s : cx + half1, y, 7 * s + 2, 2.2), bolt);
    }
    // The cross-arm (steel channel) and its braces.
    final arm = Paint()..color = _mix(const Color(0xFF6E757B), const Color(0xFF34393D), dk);
    c.drawRect(Rect.fromLTWH(cx - 66 * s, geo.armY - 4 * s, 132 * s, 8 * s), arm);
    if (wet > 0.05) {
      c.drawRect(Rect.fromLTWH(cx - 66 * s, geo.armY - 4 * s, 132 * s, 1.5), Paint()..color = Color.fromRGBO(220, 232, 245, 0.6 * wet.clamp(0.0, 1.0)));
    }
    final brace = Paint()
      ..color = arm.color
      ..strokeWidth = 2.4 * s + 0.6;
    c.drawLine(Offset(cx - 40 * s, geo.armY + 3 * s), Offset(cx - half1, geo.armY + 34 * s), brace);
    c.drawLine(Offset(cx + 40 * s, geo.armY + 3 * s), Offset(cx + half1, geo.armY + 34 * s), brace);
    // Brown-glazed porcelain pin insulators.
    for (final p in geo.pins) {
      final glaze = Paint()..color = _mix(const Color(0xFF7B4526), const Color(0xFF3C2212), dk);
      for (var i = 0; i < 3; i++) {
        final y = p.dy + 4 * s + i * 4.5 * s;
        c.drawOval(Rect.fromCenter(center: Offset(p.dx, y), width: (14 - i * 2) * s + 3, height: 4 * s + 1), glaze);
      }
      c.drawRect(Rect.fromLTWH(p.dx - 1.5, p.dy + 15 * s, 3, 8 * s), Paint()..color = arm.color);
    }
  }

  void _palm(Canvas c, Offset base, double h, double lean, double dk) {
    final trunk = Paint()
      ..color = _mix(const Color(0xFF7A5A3A), const Color(0xFF3A2C20), dk)
      ..strokeWidth = 4.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final top = base + Offset(math.sin(lean) * h, -math.cos(lean) * h);
    final ctrl = base + Offset(math.sin(lean) * h * 0.25, -h * 0.55);
    c.drawPath(
        Path()
          ..moveTo(base.dx, base.dy)
          ..quadraticBezierTo(ctrl.dx, ctrl.dy, top.dx, top.dy),
        trunk);
    final frond = Paint()
      ..color = _mix(const Color(0xFF3F7A33), const Color(0xFF1E3A1A), dk)
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 7; i++) {
      // Fronds stream downwind as the wind rises.
      final a = -math.pi / 2 + (i - 3) * 0.55 + lean * 1.6;
      final len = h * 0.42;
      final tip = top + Offset(math.cos(a) * len, math.sin(a) * len * 0.8 + len * 0.35);
      final mid = top + Offset(math.cos(a) * len * 0.5, math.sin(a) * len * 0.5 - 6);
      c.drawPath(
          Path()
            ..moveTo(top.dx, top.dy)
            ..quadraticBezierTo(mid.dx, mid.dy, tip.dx, tip.dy),
          frond);
    }
  }

  void _roundTree(Canvas c, Offset base, double h, double lean, double dk) {
    final top = base + Offset(math.sin(lean) * h * 0.7, -h * 0.62);
    c.drawLine(
        base,
        top,
        Paint()
          ..color = _mix(const Color(0xFF6A4E32), const Color(0xFF33261A), dk)
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round);
    final leaf = Paint()..color = _mix(const Color(0xFF4E8A3A), const Color(0xFF223D1C), dk);
    final dark = Paint()..color = _mix(const Color(0xFF3C7330), const Color(0xFF1A3016), dk);
    final r = h * 0.3;
    final shove = math.sin(lean) * r * 0.9;
    c.drawCircle(top + Offset(shove * 0.4, r * 0.2), r * 1.1, dark);
    c.drawCircle(top + Offset(-r * 0.7 + shove, 0), r * 0.85, leaf);
    c.drawCircle(top + Offset(r * 0.7 + shove * 1.3, r * 0.1), r * 0.9, leaf);
    c.drawCircle(top + Offset(shove, -r * 0.6), r * 0.95, leaf);
  }

  @override
  bool shouldRepaint(SkyWorldPainter old) => old.geo != geo || old.weather != weather || old.seed != seed || old.t != t || old.flash != flash;
}

/// The drizzle, in front of everything (also the worker): slanting with the
/// wind, falling while the scene is awake.
class SkyRainPainter extends CustomPainter {
  SkyRainPainter({required this.weather, required this.t}) : super(repaint: t);
  final SkyWeather weather;
  final ValueListenable<double> t;

  @override
  void paint(Canvas c, Size size) {
    final r = weather.rain;
    if (weather.wind >= 40) _gusts(c, size);
    if (r <= 0.02) return;
    final n = (r * 150).round();
    final slant = (weather.wind / 40).clamp(0.2, 1.4) * 7;
    final drop = Paint()
      ..color = Color.fromRGBO(210, 222, 236, 0.42 * r.clamp(0.0, 1.0) + 0.1)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    final time = t.value;
    for (var i = 0; i < n; i++) {
      final hx = ((i * 73) % 389) / 389;
      final hy = ((i * 151) % 467) / 467;
      final speed = 520 + (i % 5) * 60;
      final y = (hy * size.height + time * speed) % (size.height + 40) - 20;
      final x = (hx * (size.width + 60) + time * speed * slant / 18) % (size.width + 60) - 30;
      c.drawLine(Offset(x, y), Offset(x - slant, y + 13), drop);
    }
  }

  /// A strong wind: streaks of moving air, dust and torn leaves.
  void _gusts(Canvas c, Size size) {
    final time = t.value;
    final k = ((weather.wind - 40) / 25).clamp(0.3, 1.0);
    final streak = Paint()
      ..color = Color.fromRGBO(235, 238, 230, 0.32 * k)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 14; i++) {
      final y = 90 + ((i * 97) % 520).toDouble();
      final len = 30 + (i % 4) * 14.0;
      final x = ((i * 131) % 400 + time * (260 + i * 9)) % (size.width + 120) - 60;
      c.drawPath(
          Path()
            ..moveTo(x, y)
            ..quadraticBezierTo(x + len * 0.5, y - 5, x + len, y),
          streak..style = PaintingStyle.stroke);
    }
    final dust = Paint()..color = Color.fromRGBO(170, 140, 90, 0.5 * k);
    final leaf = Paint()..color = Color.fromRGBO(80, 120, 50, 0.8 * k);
    for (var i = 0; i < 18; i++) {
      final y = size.height * 0.45 + ((i * 53) % 260).toDouble() + math.sin(time * 5 + i) * 8;
      final x = ((i * 71) % 420 + time * (320 + i * 11)) % (size.width + 60) - 30;
      if (i % 3 == 0) {
        c.save();
        c.translate(x, y);
        c.rotate(time * 6 + i);
        c.drawOval(const Rect.fromLTWH(-4, -2, 8, 4), leaf);
        c.restore();
      } else {
        c.drawCircle(Offset(x, y), 1.4, dust);
      }
    }
  }

  @override
  bool shouldRepaint(SkyRainPainter old) => old.weather != weather || old.t != t;
}
