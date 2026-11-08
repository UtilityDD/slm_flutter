import 'dart:math' as math;

import 'package:flutter/material.dart';

// Behind the work van before the job (lesson 1.5, কাজ 1 "সঠিক রড"): a drawn
// scene — late-morning sky and clouds, the substation's gantries and poles
// far off, the road, and the van seen from the back with both rear doors
// open: the rod rack inside (the rods are widgets on it), the docket's
// clipboard on the left door, room on the right door for rods set aside.
// No text in the art. Design: 360 wide × any height; the van stands on the
// ground row, so a tall phone gets more sky, never a stretched van.

/// Where things are, in design pixels (360 × [h]).
@immutable
class RodVanGeo {
  const RodVanGeo(this.h);
  final double h;

  /// The road's edge (the van's wheels stand on it).
  double get ground => h - 112;

  /// The van's roof.
  double get top => ground - 372;

  Rect get body => Rect.fromLTRB(74, top, 286, ground - 30);

  /// The open back: the rack stands in it.
  Rect get opening => Rect.fromLTRB(90, top + 24, 270, ground - 48);

  Rect get leftDoor => Rect.fromLTRB(4, top + 10, 76, ground - 44);
  Rect get rightDoor => Rect.fromLTRB(284, top + 10, 356, ground - 44);

  /// The docket's clipboard on the left door.
  Rect get docket => Rect.fromLTWH(9, top + 84, 62, 116);

  /// Slot [i] of [n] on the rack: a rod stands in it, hook up.
  Rect slot(int i, int n) {
    final w = opening.width / n;
    return Rect.fromLTWH(opening.left + w * i, opening.top + 6, w, opening.height - 14);
  }

  /// Where the [i]th rod set aside leans, on the right door.
  Rect aside(int i) => Rect.fromLTWH(rightDoor.left + 4 + i * 20.0, rightDoor.top + 86, 32, rightDoor.height - 92);

  /// The trainee, by the left door.
  Rect get trainee => Rect.fromLTWH(-6, ground - 118, 68, 136);
}

class RodVanPainter extends CustomPainter {
  const RodVanPainter(this.geo);
  final RodVanGeo geo;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final h = s.height;
    final g = geo.ground;

    // Sky.
    final sky = Rect.fromLTWH(0, 0, w, g);
    c.drawRect(
      sky,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4E8FCB), Color(0xFF9CC6E6), Color(0xFFE6EEF0)],
          stops: [0, 0.62, 1],
        ).createShader(sky),
    );
    final sun = Offset(w * 0.82, math.max(70, geo.top - 40));
    c.drawCircle(sun, 120, Paint()..shader = const RadialGradient(colors: [Color(0x80FFF6D8), Color(0x00FFF6D8)]).createShader(Rect.fromCircle(center: sun, radius: 120)));
    c.drawCircle(sun, 18, Paint()..color = const Color(0xFFFFF4CF));

    // Clouds (soft, still).
    void cloud(double x, double y, double k) {
      final p = Paint()..color = const Color(0xE6FFFFFF);
      c.drawOval(Rect.fromCenter(center: Offset(x, y), width: 92 * k, height: 26 * k), p);
      c.drawCircle(Offset(x - 18 * k, y - 8 * k), 16 * k, p);
      c.drawCircle(Offset(x + 10 * k, y - 13 * k), 20 * k, p);
      c.drawOval(Rect.fromCenter(center: Offset(x, y + 6 * k), width: 96 * k, height: 10 * k), Paint()..color = const Color(0x22506A88));
    }

    cloud(70, math.max(120, geo.top * 0.42), 1.0);
    cloud(250, math.max(150, geo.top * 0.62), 0.8);
    if (geo.top > 260) cloud(170, geo.top * 0.25, 0.7);

    // Far: the substation behind its wall — tall gantries and a tower rise
    // above the van's roof (their feet are hidden behind the van), hazy.
    final fy = g - 40;
    final rise = (geo.top - 60).clamp(0.0, 130.0);
    if (rise > 8) {
      final far = Paint()..color = const Color(0xFF9DB2C3);
      final lattice = Paint()
        ..color = const Color(0xFF9DB2C3)
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke;
      final wire = Paint()
        ..color = const Color(0xFF8297A8)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      // Two-column gantries with a beam and lattice.
      final beams = <Rect>[];
      for (final (x, span, k) in const [(36.0, 58.0, 0.78), (150.0, 66.0, 1.0), (268.0, 52.0, 0.7)]) {
        final top = geo.top - rise * k;
        for (final cx in [x, x + span]) {
          c.drawRect(Rect.fromLTWH(cx - 2.5, top, 5, fy - top), far);
        }
        final beam = Rect.fromLTWH(x - 8, top, span + 16, 6);
        c.drawRect(beam, far);
        beams.add(beam);
        for (var y = top + 6; y < geo.top + 10; y += 22) {
          c.drawLine(Offset(x, y), Offset(x + span, y + 22), lattice);
          c.drawLine(Offset(x + span, y), Offset(x, y + 22), lattice);
        }
        // Insulator strings under the beam.
        for (var i = 1; i <= 3; i++) {
          final ix = x + span * i / 4;
          c.drawLine(Offset(ix, top + 6), Offset(ix, top + 18), lattice);
        }
      }
      // The busbars, sagging from gantry to gantry.
      for (var i = 0; i + 1 < beams.length; i++) {
        final a = beams[i];
        final b = beams[i + 1];
        for (var j = 1; j <= 3; j++) {
          final y0 = a.top + 18;
          final y1 = b.top + 18;
          final p0 = Offset(a.left + a.width * j / 4, y0);
          final p1 = Offset(b.left + b.width * j / 4, y1);
          c.drawPath(
            Path()
              ..moveTo(p0.dx, p0.dy)
              ..quadraticBezierTo((p0.dx + p1.dx) / 2, math.max(y0, y1) + 10, p1.dx, p1.dy),
            wire,
          );
        }
      }
      // A line leaves to the left, over the poles.
      c.drawPath(
        Path()
          ..moveTo(beams.first.left + 8, beams.first.top + 18)
          ..quadraticBezierTo(16, beams.first.top + 30, -4, beams.first.top + 26),
        wire,
      );
    }
    // The substation's boundary wall.
    c.drawRect(Rect.fromLTWH(0, fy - 6, w, 46), Paint()..color = const Color(0xFFC9C2B2));
    c.drawRect(Rect.fromLTWH(0, fy - 6, w, 4), Paint()..color = const Color(0xFFB2A992));

    // The road.
    final road = Rect.fromLTWH(0, g, w, h - g);
    c.drawRect(
      road,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF8E8B85), Color(0xFF66635E)],
        ).createShader(road),
    );
    c.drawRect(Rect.fromLTWH(0, g, w, 4), Paint()..color = const Color(0xFFB9B2A4));
    for (var x = 8.0; x < w; x += 46) {
      c.drawRect(Rect.fromLTWH(x, g + 64, 24, 4), Paint()..color = const Color(0x55F2EEE4));
    }

    final b = geo.body;
    // Shadow under the van.
    c.drawOval(Rect.fromLTRB(b.left - 30, g - 10, b.right + 30, g + 14), Paint()..color = const Color(0x55000000));

    // Wheels (seen under the back).
    final tyre = Paint()..color = const Color(0xFF1C1F24);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(b.left + 8, g - 38, b.left + 38, g), const Radius.circular(6)), tyre);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(b.right - 38, g - 38, b.right - 8, g), const Radius.circular(6)), tyre);

    // The body.
    final body = RRect.fromRectAndCorners(b, topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: const Radius.circular(4), bottomRight: const Radius.circular(4));
    c.drawRRect(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFFD8DDE1), Color(0xFFF6F8F9), Color(0xFFD3D8DC)],
        ).createShader(b),
    );
    // Roof ladder.
    final rail = Paint()..color = const Color(0xFF9AA2A9);
    c.drawRect(Rect.fromLTRB(b.left + 14, b.top - 12, b.right - 14, b.top - 9), rail);
    c.drawRect(Rect.fromLTRB(b.left + 14, b.top - 4, b.right - 14, b.top - 1), rail);
    for (var x = b.left + 20; x < b.right - 16; x += 14) {
      c.drawRect(Rect.fromLTWH(x, b.top - 12, 2, 11), rail);
    }
    // The blue band and the tail lights on the pillars.
    c.drawRect(Rect.fromLTRB(b.left, b.bottom - 76, b.right, b.bottom - 66), Paint()..color = const Color(0xFF2F6FD0));
    final lamp = Paint()..color = const Color(0xFFD23A2C);
    final amber = Paint()..color = const Color(0xFFF2A13A);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(b.left + 3, b.bottom - 120, 11, 34), const Radius.circular(3)), lamp);
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(b.right - 14, b.bottom - 120, 11, 34), const Radius.circular(3)), lamp);
    c.drawRect(Rect.fromLTWH(b.left + 3, b.bottom - 84, 11, 10), amber);
    c.drawRect(Rect.fromLTWH(b.right - 14, b.bottom - 84, 11, 10), amber);

    // Inside the open back.
    final o = geo.opening;
    c.drawRect(
      o,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1B2128), Color(0xFF2F363E), Color(0xFF3A424B)],
        ).createShader(o),
    );
    // A dome light's glow on the ceiling.
    c.drawOval(Rect.fromCenter(center: Offset(o.center.dx, o.top + 4), width: 110, height: 26), Paint()..color = const Color(0x33FFF2C8));
    // The rack: a rail with clips at the top, a trough at the bottom.
    final metal = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFB9C1C8), Color(0xFF6F7880)],
      ).createShader(Rect.fromLTWH(o.left, o.top + 30, o.width, 10));
    c.drawRect(Rect.fromLTWH(o.left + 4, o.top + 30, o.width - 8, 8), metal);
    final trough = Rect.fromLTRB(o.left + 4, o.bottom - 30, o.right - 4, o.bottom - 8);
    c.drawRRect(RRect.fromRectAndRadius(trough, const Radius.circular(3)), Paint()..color = const Color(0xFF5B636B));
    c.drawRect(Rect.fromLTRB(trough.left, trough.top, trough.right, trough.top + 3), Paint()..color = const Color(0xFF8D969E));
    // The floor lip.
    c.drawRect(Rect.fromLTRB(o.left - 4, o.bottom, o.right + 4, o.bottom + 8), Paint()..color = const Color(0xFF4A525A));

    // The bumper and step.
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTRB(b.left - 6, b.bottom - 10, b.right + 6, b.bottom + 4), const Radius.circular(3)), Paint()..color = const Color(0xFF30353B));
    c.drawRect(Rect.fromLTRB(b.center.dx - 40, b.bottom + 4, b.center.dx + 40, b.bottom + 10), Paint()..color = const Color(0xFF50575E));

    // The open doors (inner faces), a window at the top of each.
    for (final d in [geo.leftDoor, geo.rightDoor]) {
      final r = RRect.fromRectAndRadius(d, const Radius.circular(8));
      c.drawRRect(r.shift(const Offset(0, 4)), Paint()..color = const Color(0x33000000));
      c.drawRRect(
        r,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFC7CDD2), Color(0xFFAEB5BB)],
          ).createShader(d),
      );
      c.drawRRect(
        RRect.fromRectAndRadius(d.deflate(5), const Radius.circular(6)),
        Paint()
          ..color = const Color(0x22000000)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
      final win = Rect.fromLTRB(d.left + 9, d.top + 10, d.right - 9, d.top + 64);
      c.drawRRect(
        RRect.fromRectAndRadius(win, const Radius.circular(5)),
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7FA7C2), Color(0xFF4F7590)],
          ).createShader(win),
      );
      c.drawLine(Offset(win.left + 8, win.bottom - 8), Offset(win.left + 24, win.top + 8), Paint()
        ..color = const Color(0x55FFFFFF)
        ..strokeWidth = 3);
      // Hinges on the van's side, the handle in the middle.
      final hinge = Paint()..color = const Color(0xFF6F777E);
      final hx = d == geo.leftDoor ? d.right - 3 : d.left - 3;
      for (final y in [d.top + 30, d.bottom - 40]) {
        c.drawRect(Rect.fromLTWH(hx, y, 6, 14), hinge);
      }
    }
    final lh = geo.leftDoor;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(lh.left + 26, lh.bottom - 60, 22, 7), const Radius.circular(3)), Paint()..color = const Color(0xFF5B636B));
    final rh = geo.rightDoor;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(rh.left + 26, rh.bottom - 60, 22, 7), const Radius.circular(3)), Paint()..color = const Color(0xFF5B636B));
    // Two hooks on the right door, for rods set aside.
    for (var i = 0; i < 3; i++) {
      c.drawCircle(Offset(rh.left + 20 + i * 20.0, rh.top + 82), 3, Paint()..color = const Color(0xFF5B636B));
    }

    // The clipboard on the left door (the docket sheet is a widget on it).
    final cb = geo.docket.inflate(3);
    c.drawRRect(RRect.fromRectAndRadius(cb.shift(const Offset(1, 3)), const Radius.circular(4)), Paint()..color = const Color(0x44000000));
    c.drawRRect(RRect.fromRectAndRadius(cb, const Radius.circular(4)), Paint()..color = const Color(0xFF8B5E34));
  }

  @override
  bool shouldRepaint(RodVanPainter old) => old.geo.h != geo.h;
}
