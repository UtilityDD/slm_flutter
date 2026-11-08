import 'dart:math' as math;

import 'package:flutter/material.dart';

// A village roadside at mid-morning (lesson 1.3's pole reading): a drawn,
// layered place — sky and clouds, far village and paddy fields, the grass
// verge with bushes and banana plants, the dirt shoulder where the pole
// stands and the road in front. No text in the art.
//
// Walking round the pole turns the world behind it: the far layer is a
// panorama (village on one side, fields and a pond on the other) that slides
// once per turn; the nearer layers slide faster (parallax). Design: 360 wide ×
// the scene's height; the ground row follows the bottom of the screen.

/// Where things stand in the pole scene (design px, 360 wide).
@immutable
class PoleGeo {
  const PoleGeo({required this.height, required this.groundY, required this.length});

  /// The scene of design height [h] with [inset] (bottom system inset, design px).
  factory PoleGeo.forScene(double h, double inset) {
    final g = h - 170 - inset;
    return PoleGeo(height: h, groundY: g, length: (g - 160).clamp(300.0, 460.0));
  }

  /// The pole's axis (left of centre: the guide stands bottom right).
  static const cx = 124.0;

  /// The pole's height above the ground, in metres (drawing scale only).
  static const metres = 9.0;

  final double height;

  /// Where the pole enters the soil.
  final double groundY;

  /// The pole above the ground, design px.
  final double length;

  double get ppm => length / metres;
  double get topY => groundY - length;

  /// Scale against the 370-long reference drawing.
  double get s => length / 370;
  double get horizonY => groundY - 66;

  /// Design y of a point [m] metres above the ground.
  double y(double m) => groundY - m * ppm;

  /// Metres above the ground of design y [dy].
  double m(double dy) => (groundY - dy) / ppm;

  @override
  bool operator ==(Object other) => other is PoleGeo && other.height == height && other.groundY == groundY && other.length == length;

  @override
  int get hashCode => Object.hash(height, groundY, length);
}

/// The village roadside behind the pole. [orbit]: turns walked round the pole
/// (0 = front, 0.5 = back); [travel]: 1 → 0 while walking to the next pole.
class PoleYardPainter extends CustomPainter {
  const PoleYardPainter({required this.geo, required this.orbit, this.travel = 0});
  final PoleGeo geo;
  final double orbit;
  final double travel;

  /// Draws [draw] at its place in a strip of [period] slid by [shift], wrapped.
  static void _tiled(double period, double shift, void Function(double dx) draw) {
    final base = -(shift % period);
    for (final k in const [-1.0, 0.0, 1.0]) {
      draw(base + k * period);
    }
  }

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final h = s.height;
    final hz = geo.horizonY;
    final g = geo.groundY;
    final far = orbit * 720 + travel * 110;
    final mid = orbit * 1440 + travel * 240;
    final near = orbit * 2160 + travel * 420;

    // Sky.
    final sky = Rect.fromLTWH(0, 0, w, hz + 4);
    c.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5E9BD0), Color(0xFF9CC6E6), Color(0xFFE9E4CF)],
          stops: [0, 0.62, 1],
        ).createShader(sky),
    );
    // The sun's glow (high, behind on the right).
    final sun = Offset(w * 0.82, hz - 300);
    c.drawCircle(sun, 120, Paint()..shader = const RadialGradient(colors: [Color(0x80FFF4D2), Color(0x00FFF4D2)]).createShader(Rect.fromCircle(center: sun, radius: 120)));
    c.drawCircle(sun, 16, Paint()..color = const Color(0xFFFFF6DC));

    // Clouds (very far: they slide with the far layer, half as fast).
    final cloud = Paint()..color = const Color(0xD9FFFFFF);
    _tiled(720, far * 0.5, (dx) {
      for (final (x, y, r) in const [(60.0, 0.28, 22.0), (300.0, 0.18, 18.0), (470.0, 0.32, 26.0), (640.0, 0.22, 16.0)]) {
        final cy = hz * y + 40;
        final cxx = x + dx;
        c.drawOval(Rect.fromCenter(center: Offset(cxx, cy), width: r * 4.2, height: r * 1.3), cloud);
        c.drawCircle(Offset(cxx - r * 0.6, cy - r * 0.35), r * 0.8, cloud);
        c.drawCircle(Offset(cxx + r * 0.5, cy - r * 0.5), r, cloud);
      }
    });

    // Far: the tree line all round.
    _tiled(720, far, (dx) {
      final p = Path()..moveTo(dx, hz);
      for (var x = 0.0; x <= 720; x += 16) {
        final bump = 14 + 9 * math.sin(x * 0.045) + 6 * math.sin(x * 0.13 + 1.3);
        p.quadraticBezierTo(dx + x + 8, hz - bump - 10, dx + x + 16, hz - bump * 0.6);
      }
      p
        ..lineTo(dx + 720, hz)
        ..close();
      c.drawPath(p, Paint()..color = const Color(0xFF6E8F62));
    });

    // Far, front half: the village (tin roofs, coconut palms, a water tank).
    _tiled(720, far, (dx) {
      for (final (x, wd, ht, wall, roof) in const [
        (24.0, 52.0, 26.0, Color(0xFFE8D9B5), Color(0xFF7D8C99)),
        (92.0, 40.0, 22.0, Color(0xFFD9C3A0), Color(0xFF9A5B3C)),
        (206.0, 58.0, 30.0, Color(0xFFEAE3D2), Color(0xFF6F7F8C)),
        (282.0, 44.0, 24.0, Color(0xFFCFE0D4), Color(0xFF8C969E)),
      ]) {
        final l = x + dx;
        final base = hz + 4;
        c.drawRect(Rect.fromLTWH(l, base - ht, wd, ht), Paint()..color = wall);
        c.drawPath(
          Path()
            ..moveTo(l - 5, base - ht + 2)
            ..lineTo(l + wd * 0.5, base - ht - 13)
            ..lineTo(l + wd + 5, base - ht + 2)
            ..close(),
          Paint()..color = roof,
        );
        c.drawRect(Rect.fromLTWH(l + wd * 0.42, base - ht * 0.62, wd * 0.16, ht * 0.62), Paint()..color = const Color(0xFF5C4632));
        c.drawRect(Rect.fromLTWH(l + wd * 0.12, base - ht * 0.7, wd * 0.16, ht * 0.28), Paint()..color = const Color(0xFF4B5966));
      }
      // Water tank on legs.
      final tx = 160 + dx;
      final leg = Paint()
        ..color = const Color(0xFF8C8F92)
        ..strokeWidth = 2;
      c.drawLine(Offset(tx - 8, hz + 2), Offset(tx - 5, hz - 40), leg);
      c.drawLine(Offset(tx + 8, hz + 2), Offset(tx + 5, hz - 40), leg);
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(tx - 13, hz - 60, 26, 22), const Radius.circular(5)), Paint()..color = const Color(0xFF3F4A54));
      // Coconut palms.
      for (final x in const [70.0, 190.0, 340.0]) {
        _palm(c, Offset(x + dx, hz + 2), 62);
      }
    });

    // Far, back half: paddy fields, a pond, a haystack, a brick chimney.
    _tiled(720, far, (dx) {
      // Pond.
      final pond = Rect.fromLTWH(430 + dx, hz - 6, 120, 14);
      c.drawOval(pond, Paint()..color = const Color(0xFF8FB9D8));
      c.drawOval(pond.deflate(4), Paint()..color = const Color(0xFFB3D2E6));
      // Haystack.
      final hx = 610 + dx;
      c.drawPath(
        Path()
          ..moveTo(hx - 18, hz + 3)
          ..quadraticBezierTo(hx - 16, hz - 30, hx, hz - 34)
          ..quadraticBezierTo(hx + 16, hz - 30, hx + 18, hz + 3)
          ..close(),
        Paint()..color = const Color(0xFFD9B45E),
      );
      c.drawLine(Offset(hx, hz - 34), Offset(hx, hz - 46), Paint()
        ..color = const Color(0xFF6B4A2A)
        ..strokeWidth = 2);
      // A far brick chimney.
      c.drawPath(
        Path()
          ..moveTo(684 + dx, hz - 2)
          ..lineTo(688 + dx, hz - 88)
          ..lineTo(696 + dx, hz - 88)
          ..lineTo(700 + dx, hz - 2)
          ..close(),
        Paint()..color = const Color(0xFFA0614A),
      );
      for (final x in const [395.0, 520.0, 580.0]) {
        _palm(c, Offset(x + dx, hz + 2), 54);
      }
    });

    // The verge (grass) and the paddy rows that run toward the horizon.
    final verge = Rect.fromLTWH(0, hz, w, g - hz + 6);
    c.drawRect(
      verge,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF9DBB6A), Color(0xFF7FA352)],
        ).createShader(verge),
    );
    final row = Paint()
      ..color = const Color(0x2A2F5A1E)
      ..strokeWidth = 1.2;
    for (var i = 1; i < 6; i++) {
      final yy = hz + (g - hz) * (i / 6) * (i / 6);
      c.drawLine(Offset(0, yy), Offset(w, yy), row);
    }

    // Mid: bushes, banana plants, a bamboo fence.
    _tiled(720, mid, (dx) {
      for (final (x, r) in const [(20.0, 16.0), (150.0, 12.0), (300.0, 18.0), (420.0, 14.0), (560.0, 17.0), (690.0, 12.0)]) {
        final bx = x + dx;
        final by = hz + 30;
        c.drawCircle(Offset(bx, by - r * 0.4), r, Paint()..color = const Color(0xFF557B3E));
        c.drawCircle(Offset(bx + r * 0.8, by - r * 0.1), r * 0.75, Paint()..color = const Color(0xFF5F8846));
        c.drawCircle(Offset(bx - r * 0.7, by), r * 0.6, Paint()..color = const Color(0xFF4C7238));
      }
      for (final x in const [240.0, 500.0]) {
        _banana(c, Offset(x + dx, hz + 40));
      }
      // Bamboo fence.
      final fence = Paint()
        ..color = const Color(0xFFB59A62)
        ..strokeWidth = 2.2;
      for (var x = 600.0; x < 680; x += 9) {
        c.drawLine(Offset(x + dx, hz + 44), Offset(x + dx, hz + 22), fence);
      }
      c.drawLine(Offset(598 + dx, hz + 30), Offset(682 + dx, hz + 30), fence);
      c.drawLine(Offset(598 + dx, hz + 38), Offset(682 + dx, hz + 38), fence);
    });

    // The dirt shoulder where the pole stands, then the road.
    final shoulder = Rect.fromLTWH(0, g - 8, w, 44);
    c.drawRect(
      shoulder,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFB59468), Color(0xFF9E7E55)],
        ).createShader(shoulder),
    );
    final road = Rect.fromLTWH(0, g + 34, w, h - g - 34);
    c.drawRect(
      road,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6C6A66), Color(0xFF4E4C49)],
        ).createShader(road),
    );
    c.drawRect(Rect.fromLTWH(0, g + 34, w, 4), Paint()..color = const Color(0xFFD9D3C4));
    // Near: the centre dashes, pebbles and grass tufts slide fastest.
    _tiled(360, near, (dx) {
      final dash = Paint()..color = const Color(0xCCF1EBDC);
      for (var x = 10.0; x < 360; x += 90) {
        c.drawRect(Rect.fromLTWH(x + dx, g + 92, 46, 5), dash);
      }
      final stone = Paint()..color = const Color(0xFF8A7454);
      for (final (x, y, r) in const [(30.0, 10.0, 2.6), (88.0, 22.0, 2.0), (176.0, 16.0, 3.0), (250.0, 26.0, 2.2), (318.0, 8.0, 2.4)]) {
        c.drawOval(Rect.fromCenter(center: Offset(x + dx, g + y), width: r * 2.6, height: r * 1.6), stone);
      }
      final tuft = Paint()
        ..color = const Color(0xFF6C9446)
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round;
      for (final x in const [56.0, 214.0, 300.0]) {
        final b = Offset(x + dx, g - 4);
        for (final a in const [-0.5, -0.2, 0.15, 0.45]) {
          c.drawLine(b, b + Offset(math.sin(a) * 9, -math.cos(a) * 10), tuft);
        }
      }
    });
  }

  static void _palm(Canvas c, Offset foot, double ht) {
    final trunk = Path()
      ..moveTo(foot.dx - 2, foot.dy)
      ..quadraticBezierTo(foot.dx + 4, foot.dy - ht * 0.5, foot.dx + 6, foot.dy - ht)
      ..lineTo(foot.dx + 9, foot.dy - ht)
      ..quadraticBezierTo(foot.dx + 7, foot.dy - ht * 0.5, foot.dx + 2, foot.dy)
      ..close();
    c.drawPath(trunk, Paint()..color = const Color(0xFF7B6545));
    final crown = Offset(foot.dx + 7.5, foot.dy - ht);
    final leaf = Paint()
      ..color = const Color(0xFF4E7A3A)
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    for (final a in const [-2.6, -2.0, -1.2, -0.4, 0.3, 0.9]) {
      final end = crown + Offset(math.cos(a) * 20, math.sin(a) * 9 + 6);
      c.drawPath(
        Path()
          ..moveTo(crown.dx, crown.dy)
          ..quadraticBezierTo(crown.dx + math.cos(a) * 12, crown.dy - 6, end.dx, end.dy),
        leaf,
      );
    }
  }

  static void _banana(Canvas c, Offset foot) {
    c.drawRect(Rect.fromLTWH(foot.dx - 2.5, foot.dy - 34, 5, 34), Paint()..color = const Color(0xFF8BA35A));
    final leaf = Paint()..color = const Color(0xFF6FA046);
    for (final (a, l) in const [(-2.4, 26.0), (-1.6, 22.0), (-0.8, 26.0), (-0.2, 20.0)]) {
      final top = Offset(foot.dx, foot.dy - 34);
      final tip = top + Offset(math.cos(a) * l, math.sin(a) * l * 0.6);
      final n = Offset(-(tip.dy - top.dy), tip.dx - top.dx) / l * 5;
      c.drawPath(
        Path()
          ..moveTo(top.dx, top.dy)
          ..quadraticBezierTo((top.dx + tip.dx) / 2 + n.dx, (top.dy + tip.dy) / 2 + n.dy, tip.dx, tip.dy)
          ..quadraticBezierTo((top.dx + tip.dx) / 2 - n.dx, (top.dy + tip.dy) / 2 - n.dy, top.dx, top.dy),
        leaf,
      );
    }
  }

  @override
  bool shouldRepaint(PoleYardPainter old) => old.geo != geo || old.orbit != orbit || old.travel != travel;
}
