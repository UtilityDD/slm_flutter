import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'fire_choose.dart' show FireKind, FireTool, FireToolFacts;

// The substation yard for lesson 1.8 as layered scenery, seen through a
// 360 x 420 camera that pans along a 1000-wide world:
//   sky + drifting clouds (barely move) → far village, palms, tower
//   (parallax 0.35) → yard: fence, gantry, overhead line, transformer, feeder
//   panel, pole with dry grass (parallax 1).
// Flames, smoke and sprays are Lottie on top (fire_fx.dart); characters and
// the fire-point rack are in front (fire_choose.dart). No text in the art.

abstract final class FireWorld {
  static const width = 1000.0;
  static const viewW = 360.0;
  static const ground = 262.0;

  /// The isolator switch on its post, beside the feeder panel (world pixels,
  /// centre of the switch box).
  static const isolator = Offset(468, 226);

  /// Base of each fire in world pixels, and its size.
  static (Offset, double) fireAt(FireKind k) => switch (k) {
        FireKind.oil => (const Offset(300, 302), 0.8),
        FireKind.electrical => (const Offset(556, 284), 0.42),
        FireKind.grass => (const Offset(772, 310), 0.7),
      };

  /// The camera's left edge when looking at [k] (the fire sits right of
  /// centre; the mentor and trainee stand on the left).
  static double cameraFor(FireKind k) => (fireAt(k).$1.dx - 255).clamp(0.0, width - viewW);
}

/// Everything behind the flames, for camera [camX] and clock [t] (seconds).
class FireWorldPainter extends CustomPainter {
  FireWorldPainter({
    required this.camX,
    required this.t,
    required this.burning,
    required this.done,
    required this.powerOn,
    this.lift = 0,
  });

  final double camX;
  final double t;

  /// The fire burning now (null between fires).
  final FireKind? burning;

  /// Fires already put out (scorched).
  final Set<FireKind> done;

  /// The panel is still live (sparks).
  final bool powerOn;

  /// The yard is drawn this much lower (a tall screen gets more sky).
  final double lift;

  static final _rnd = math.Random(8);
  static final List<(double, double, double)> _gravel = [
    for (var i = 0; i < 320; i++) (_rnd.nextDouble() * FireWorld.width, FireWorld.ground + 4 + _rnd.nextDouble() * 520, 0.8 + _rnd.nextDouble() * 1.8),
  ];
  static final List<(double, double, double)> _trees = [
    for (var x = -40.0; x < 760; x += 18 + (x * 7 % 13)) (x, 0.7 + ((x * 13) % 10) / 20, ((x * 3) % 7) / 7),
  ];

  @override
  void paint(Canvas c, Size s) {
    c.clipRect(Offset.zero & s);
    _sky(c, s);
    c.save();
    c.translate(-camX * 0.35, lift);
    _far(c);
    c.restore();
    c.save();
    c.translate(-camX, lift);
    _yard(c, s);
    c.restore();
  }

  void _sky(Canvas c, Size s) {
    final g = FireWorld.ground + lift;
    c.drawRect(
      Rect.fromLTWH(0, 0, s.width, g),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF5E9BD4), Color(0xFFA8CBE8), Color(0xFFF2D9B2)],
          stops: [0, 0.6, 1],
        ).createShader(Rect.fromLTWH(0, 0, 360, g)),
    );
    c.drawCircle(
      Offset(290 - camX * 0.04, 58),
      70,
      Paint()..shader = const RadialGradient(colors: [Color(0x88FFF6DA), Color(0x00FFF6DA)]).createShader(Rect.fromCircle(center: Offset(290 - camX * 0.04, 58), radius: 70)),
    );
    for (final (x0, y, k) in const [(40.0, 46.0, 1.0), (210.0, 30.0, 0.8), (330.0, 70.0, 1.15), (480.0, 40.0, 0.9)]) {
      final x = ((x0 - camX * 0.12 + t * 5) % 560) - 100;
      _cloud(c, Offset(x, y), k);
    }
  }

  void _cloud(Canvas c, Offset o, double k) {
    final p = Paint()..color = const Color(0xE6FFFFFF);
    for (final (dx, dy, r) in const [(0.0, 0.0, 16.0), (18.0, -8.0, 20.0), (40.0, -2.0, 17.0), (56.0, 4.0, 12.0), (24.0, 6.0, 15.0)]) {
      c.drawCircle(o + Offset(dx, dy) * k, r * k, p);
    }
  }

  void _far(Canvas c) {
    const g = FireWorld.ground;
    final hills = Path()..moveTo(-60, g);
    for (var x = -60.0; x <= 760; x += 40) {
      hills.lineTo(x, g - 30 - 10 * math.sin(x / 70) - 6 * math.sin(x / 23));
    }
    hills
      ..lineTo(760, g)
      ..close();
    c.drawPath(hills, Paint()..color = const Color(0xFF9DB4C0));
    // Village houses between trees.
    for (final x in const [30.0, 150.0, 300.0, 470.0, 610.0]) {
      c.drawRect(Rect.fromLTWH(x, g - 34, 30, 22), Paint()..color = const Color(0xFFCDBB9E));
      c.drawPath(
        Path()
          ..moveTo(x - 4, g - 34)
          ..lineTo(x + 15, g - 46)
          ..lineTo(x + 34, g - 34)
          ..close(),
        Paint()..color = const Color(0xFF9C5B43),
      );
      c.drawRect(Rect.fromLTWH(x + 11, g - 24, 7, 12), Paint()..color = const Color(0xFF6E5A48));
    }
    // Tree line.
    for (final (x, k, v) in _trees) {
      final col = Color.lerp(const Color(0xFF6C8C7E), const Color(0xFF557566), v)!;
      c.drawCircle(Offset(x, g - 18 * k), 14 * k, Paint()..color = col);
    }
    // Coconut palms.
    for (final x in const [90.0, 380.0, 560.0, 700.0]) {
      final top = Offset(x + 8, g - 92);
      c.drawPath(
        Path()
          ..moveTo(x, g - 8)
          ..quadraticBezierTo(x + 2, g - 50, top.dx, top.dy),
        Paint()
          ..color = const Color(0xFF6F6152)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5,
      );
      final leaf = Paint()
        ..color = const Color(0xFF4E7260)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 7; i++) {
        final a = -math.pi + i * math.pi / 6;
        final end = top + Offset(math.cos(a), math.sin(a).abs() * 0.5 + 0.2) * 24;
        c.drawPath(Path()
          ..moveTo(top.dx, top.dy)
          ..quadraticBezierTo(top.dx + math.cos(a) * 14, top.dy - 8, end.dx, end.dy), leaf);
      }
    }
    // A transmission tower far away.
    final tw = Paint()
      ..color = const Color(0xFF7E8E9A)
      ..strokeWidth = 1.4;
    const bx = 250.0;
    c.drawLine(const Offset(bx - 14, g - 10), const Offset(bx - 3, g - 120), tw);
    c.drawLine(const Offset(bx + 14, g - 10), const Offset(bx + 3, g - 120), tw);
    for (var y = g - 20; y > g - 115; y -= 16) {
      final w = 14 * (y - (g - 120)) / 110;
      c.drawLine(Offset(bx - w, y), Offset(bx + w, y - 14), tw);
      c.drawLine(Offset(bx + w, y), Offset(bx - w, y - 14), tw);
    }
    c.drawLine(const Offset(bx - 24, g - 104), const Offset(bx + 24, g - 104), tw);
    c.drawLine(const Offset(bx - 18, g - 116), const Offset(bx + 18, g - 116), tw);
  }

  void _yard(Canvas c, Size s) {
    const g = FireWorld.ground;
    final view = Rect.fromLTWH(camX, 0, s.width, s.height);
    c.drawRect(
      Rect.fromLTWH(view.left, g, view.width, s.height - g - lift),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFBFAE8C), Color(0xFFA48F6B)],
        ).createShader(Rect.fromLTWH(view.left, g, view.width, s.height - g - lift)),
    );
    final speck = Paint()..color = const Color(0x55665238);
    final light = Paint()..color = const Color(0x55F3E6C8);
    for (final (x, y, r) in _gravel) {
      if (x < view.left - 4 || x > view.right + 4) continue;
      c.drawCircle(Offset(x, y), r, (x * 10).floor().isEven ? speck : light);
    }
    _gantry(c);
    _fence(c, view);
    _overhead(c);
    _transformer(c);
    _isolatorCable(c);
    _panel(c);
    _pole(c);
  }

  /// The isolator's post and the cable to the panel (the switch itself is a
  /// widget: it is tapped).
  void _isolatorCable(Canvas c) {
    final x = FireWorld.isolator.dx;
    final y = FireWorld.isolator.dy;
    c.drawRect(Rect.fromLTWH(x - 3, y + 20, 6, 290 - (y + 20)), Paint()..color = const Color(0xFF7D868E));
    c.drawPath(
      Path()
        ..moveTo(x + 14, y + 6)
        ..quadraticBezierTo(x + 30, y + 4, 508, 196),
      Paint()
        ..color = const Color(0xFF2B2F35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  void _gantry(Canvas c) {
    final st = Paint()
      ..color = const Color(0xFF8D98A3)
      ..strokeWidth = 1.6;
    for (final x in const [430.0, 680.0]) {
      c.drawLine(Offset(x - 8, FireWorld.ground - 4), Offset(x - 4, 120), st);
      c.drawLine(Offset(x + 8, FireWorld.ground - 4), Offset(x + 4, 120), st);
      for (var y = FireWorld.ground - 14; y > 126; y -= 14) {
        c.drawLine(Offset(x - 7, y), Offset(x + 7, y - 12), st);
      }
    }
    c.drawLine(const Offset(426, 122), const Offset(684, 122), st..strokeWidth = 3);
    c.drawLine(const Offset(426, 132), const Offset(684, 132), st..strokeWidth = 1.6);
    final ins = Paint()..color = const Color(0xFFB07A4A);
    for (final x in const [490.0, 555.0, 620.0]) {
      for (var i = 0; i < 4; i++) {
        c.drawOval(Rect.fromCenter(center: Offset(x, 136 + i * 5.0), width: 9, height: 3.5), ins);
      }
    }
  }

  void _fence(Canvas c, Rect view) {
    const top = FireWorld.ground - 46;
    const g = FireWorld.ground;
    final mesh = Paint()
      ..color = const Color(0x667B858E)
      ..strokeWidth = 0.8;
    final x0 = (view.left / 12).floor() * 12.0 - 60;
    for (var x = x0; x < view.right + 60; x += 12) {
      c.drawLine(Offset(x, top), Offset(x + 46, g), mesh);
      c.drawLine(Offset(x + 46, top), Offset(x, g), mesh);
    }
    final post = Paint()..color = const Color(0xFF8B949C);
    for (var x = (view.left / 70).floor() * 70.0; x < view.right + 70; x += 70) {
      c.drawRect(Rect.fromLTWH(x - 2, top - 6, 4, 52), post);
    }
    final wire = Paint()
      ..color = const Color(0xFF6C757D)
      ..strokeWidth = 1;
    c.drawLine(Offset(view.left, top), Offset(view.right, top), wire);
    c.drawLine(Offset(view.left, top - 5), Offset(view.right, top - 5), wire);
  }

  void _overhead(Canvas c) {
    final w = Paint()
      ..color = const Color(0xFF3D434A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;
    for (final dy in const [0.0, 9.0]) {
      c.drawPath(
        Path()
          ..moveTo(0, 82 + dy)
          ..quadraticBezierTo(400, 112 + dy, 772, 62 + dy)
          ..quadraticBezierTo(890, 80 + dy, 1000, 70 + dy),
        w,
      );
    }
  }

  void _scorch(Canvas c, Offset base, double w) {
    c.drawOval(Rect.fromCenter(center: base.translate(0, 2), width: w, height: 14), Paint()..color = const Color(0xCC2A2118));
  }

  void _transformer(Canvas c) {
    const cx = 300.0;
    final burning = this.burning == FireKind.oil;
    final scorched = done.contains(FireKind.oil);
    c.drawRect(const Rect.fromLTRB(cx - 72, 290, cx + 72, 306), Paint()..color = const Color(0xFFA19D93));
    c.drawRect(const Rect.fromLTRB(cx - 72, 290, cx + 72, 293), Paint()..color = const Color(0xFFBDB9AF));
    if (burning || scorched) {
      c.drawOval(const Rect.fromLTRB(cx - 85, 296, cx + 85, 312), Paint()..color = const Color(0xFF2B1D0E));
    }
    const tank = Rect.fromLTRB(cx - 46, 192, cx + 44, 290);
    c.drawRRect(
      RRect.fromRectAndRadius(tank, const Radius.circular(5)),
      Paint()..shader = const LinearGradient(colors: [Color(0xFF66746C), Color(0xFF8B9991), Color(0xFF5B6861)], stops: [0, 0.4, 1]).createShader(tank),
    );
    final fin = Paint()..color = const Color(0xFF66726B);
    for (var x = cx + 47; x < cx + 70; x += 5) {
      c.drawRect(Rect.fromLTWH(x, 204, 3.2, 78), fin);
    }
    c.drawRect(const Rect.fromLTWH(cx + 44, 210, 26, 3), fin);
    c.drawRect(const Rect.fromLTWH(cx + 44, 274, 26, 3), fin);
    // Conservator tank on brackets.
    const cons = Rect.fromLTWH(cx - 40, 164, 76, 18);
    c.drawRRect(RRect.fromRectAndRadius(cons, const Radius.circular(9)),
        Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF93A199), Color(0xFF5E6B64)]).createShader(cons));
    c.drawRect(const Rect.fromLTWH(cx - 30, 182, 4, 10), fin);
    c.drawRect(const Rect.fromLTWH(cx + 24, 182, 4, 10), fin);
    // HV bushings: porcelain sheds.
    final por = Paint()..color = const Color(0xFFB98454);
    for (final x in const [cx - 28, cx - 2, cx + 24]) {
      for (var i = 0; i < 5; i++) {
        c.drawOval(Rect.fromCenter(center: Offset(x, 186 - i * 6.0), width: 13 - i * 0.6, height: 4.2), por);
      }
      c.drawRect(Rect.fromLTWH(x - 1, 150, 2, 12), Paint()..color = const Color(0xFF8C7A5F));
    }
    if (burning || scorched) {
      c.drawRect(const Rect.fromLTRB(cx - 46, 250, cx + 44, 290), Paint()..color = const Color(0x55201812));
    }
  }

  void _panel(Canvas c) {
    const l = 506.0, r = 606.0, top = 180.0, bot = 296.0;
    final burning = this.burning == FireKind.electrical;
    final scorched = done.contains(FireKind.electrical);
    c.drawRect(const Rect.fromLTRB(l - 10, bot - 4, r + 10, bot + 8), Paint()..color = const Color(0xFFA19D93));
    const box = Rect.fromLTRB(l, top, r, bot);
    c.drawRRect(RRect.fromRectAndRadius(box, const Radius.circular(4)),
        Paint()..shader = const LinearGradient(colors: [Color(0xFF7C858D), Color(0xFFA2ABB3), Color(0xFF7C858D)]).createShader(box));
    c.drawRect(const Rect.fromLTRB(l + 8, top + 10, r - 8, bot - 8), Paint()..color = const Color(0xFF25292F));
    // The open door.
    c.drawPath(
      Path()
        ..moveTo(r, top + 2)
        ..lineTo(r + 34, top + 14)
        ..lineTo(r + 34, bot + 2)
        ..lineTo(r, bot - 2)
        ..close(),
      Paint()..shader = const LinearGradient(colors: [Color(0xFF9AA3AB), Color(0xFFBCC4CB)]).createShader(const Rect.fromLTRB(r, top, r + 34, bot)),
    );
    final bus = Paint()
      ..color = const Color(0xFFC08A4E)
      ..strokeWidth = 4;
    for (final y in const [204.0, 222.0, 240.0]) {
      c.drawLine(Offset(l + 16, y), Offset(r - 30, y), bus);
    }
    // Breaker: handle up (on, red lamp) or down (off, green lamp).
    const hb = Rect.fromLTWH(r - 26, 196, 14, 30);
    c.drawRRect(RRect.fromRectAndRadius(hb, const Radius.circular(2)), Paint()..color = const Color(0xFF3A3F46));
    c.drawRect(Rect.fromLTWH(r - 22, powerOn ? 198 : 214, 6, 10), Paint()..color = const Color(0xFFE8E2D4));
    c.drawCircle(const Offset(r - 19, 234), 3.2, Paint()..color = powerOn ? const Color(0xFFE5483A) : const Color(0xFF39B86A));
    if (burning && powerOn) {
      // Crackling arc on the busbar.
      final k = (t * 14).floor();
      final rnd = math.Random(k);
      const sp = Offset(548, 226);
      final ray = Paint()
        ..color = const Color(0xFFFFF0A0)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 7; i++) {
        final a = rnd.nextDouble() * math.pi * 2;
        final len = 8 + rnd.nextDouble() * 14;
        c.drawLine(sp + Offset(math.cos(a), math.sin(a)) * 3, sp + Offset(math.cos(a), math.sin(a)) * len, ray);
      }
      c.drawCircle(sp, 6, Paint()..shader = const RadialGradient(colors: [Color(0xFFFFFFFF), Color(0x00FFE066)]).createShader(Rect.fromCircle(center: sp, radius: 12)));
    }
    if (scorched || burning) {
      c.drawRect(const Rect.fromLTRB(l + 8, top + 10, r - 8, top + 50), Paint()..color = const Color(0x66000000));
    }
  }

  void _pole(Canvas c) {
    const x = 830.0;
    final burning = this.burning == FireKind.grass;
    final scorched = done.contains(FireKind.grass);
    final pole = Path()
      ..moveTo(x - 6, 40)
      ..lineTo(x + 6, 40)
      ..lineTo(x + 9, 312)
      ..lineTo(x - 9, 312)
      ..close();
    c.drawPath(pole, Paint()..shader = const LinearGradient(colors: [Color(0xFF9F9C94), Color(0xFFCFCBC2), Color(0xFF9A978F)]).createShader(const Rect.fromLTWH(x - 9, 40, 18, 272)));
    c.drawRect(const Rect.fromLTWH(x - 40, 56, 80, 6), Paint()..color = const Color(0xFF5F676F));
    final ins = Paint()..color = const Color(0xFFE6EBEF);
    for (final dx in const [-34.0, 34.0]) {
      c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x + dx - 4, 44, 8, 12), const Radius.circular(3)), ins);
    }
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(x - 4, 30, 8, 12), const Radius.circular(3)), ins);
    if (scorched || burning) _scorch(c, const Offset(772, 310), 150);
    if (!scorched) {
      final grass = Paint()
        ..color = const Color(0xFFC9A55A)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round;
      final rnd = math.Random(5);
      for (var i = 0; i < 90; i++) {
        final gx = 690 + rnd.nextDouble() * 180;
        c.drawLine(Offset(gx, 312), Offset(gx + (rnd.nextDouble() - 0.5) * 10, 296 - rnd.nextDouble() * 16), grass);
      }
    }
  }

  @override
  bool shouldRepaint(FireWorldPainter old) =>
      old.camX != camX || old.t != t || old.burning != burning || old.done.length != done.length || old.powerOn != powerOn || old.lift != lift;
}

/// The fire point in front: a red stand with two buckets and two
/// extinguishers (one tool per slot). [taken] is in someone's hands; [spent]
/// was found empty.
class RackToolPainter extends CustomPainter {
  RackToolPainter({required this.tool, required this.taken, required this.spent});
  final FireTool tool;
  final bool taken;
  final bool spent;

  @override
  void paint(Canvas c, Size s) {
    final w = s.width;
    final h = s.height;
    // Hook / bracket.
    c.drawRect(Rect.fromLTWH(w / 2 - 1.5, 0, 3, h * 0.12), Paint()..color = const Color(0xFF3B3F45));
    if (taken) {
      c.drawCircle(Offset(w / 2, h * 0.12), 3, Paint()..color = const Color(0xFF3B3F45));
      return;
    }
    final a = spent ? 0.38 : 1.0;
    Color k(Color col) => col.withValues(alpha: a);
    if (tool.extinguisher) {
      final body = Rect.fromLTWH(w / 2 - w * 0.2, h * 0.2, w * 0.4, h * 0.78);
      c.drawRRect(
        RRect.fromRectAndRadius(body, Radius.circular(w * 0.16)),
        Paint()..shader = LinearGradient(colors: [k(const Color(0xFF8E1F16)), k(const Color(0xFFE5483A)), k(const Color(0xFF9E2419))], stops: const [0, 0.45, 1]).createShader(body),
      );
      final band = Rect.fromLTWH(body.left, h * 0.46, body.width, h * 0.17);
      c.drawRect(band, Paint()..color = k(tool == FireTool.co2 ? const Color(0xFF2B2F35) : const Color(0xFF2F6FD0)));
      final tp = TextPainter(
        text: TextSpan(
          text: tool == FireTool.co2 ? 'CO2' : 'ABC',
          style: TextStyle(fontSize: band.height * 0.78, fontWeight: FontWeight.w900, color: k(const Color(0xFFF5F7FA)), height: 1),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: band.width + 6);
      tp.paint(c, band.center - Offset(tp.width / 2, tp.height / 2));
      c.drawRect(Rect.fromLTWH(w / 2 - w * 0.09, h * 0.1, w * 0.18, h * 0.12), Paint()..color = k(const Color(0xFF4A4F55)));
      final hose = Paint()
        ..color = k(const Color(0xFF1E2126))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4;
      if (tool == FireTool.co2) {
        c.drawPath(Path()
          ..moveTo(w / 2 + w * 0.08, h * 0.14)
          ..quadraticBezierTo(w * 0.95, h * 0.2, w * 0.86, h * 0.5), hose);
        c.drawPath(
          Path()
            ..moveTo(w * 0.86, h * 0.48)
            ..lineTo(w * 0.98, h * 0.7)
            ..lineTo(w * 0.72, h * 0.7)
            ..close(),
          Paint()..color = k(const Color(0xFF1E2126)),
        );
      } else {
        c.drawPath(Path()
          ..moveTo(w / 2 + w * 0.08, h * 0.14)
          ..quadraticBezierTo(w * 0.95, h * 0.18, w * 0.84, h * 0.62), hose);
      }
    } else {
      // A red conical fire bucket; water or sand inside.
      final b = Path()
        ..moveTo(w * 0.12, h * 0.3)
        ..lineTo(w * 0.88, h * 0.3)
        ..lineTo(w * 0.64, h * 0.95)
        ..lineTo(w * 0.36, h * 0.95)
        ..close();
      c.drawPath(b, Paint()..shader = LinearGradient(colors: [k(const Color(0xFF8E1F16)), k(const Color(0xFFE5483A)), k(const Color(0xFF9E2419))]).createShader(Rect.fromLTWH(0, h * 0.3, w, h * 0.65)));
      c.drawOval(Rect.fromLTWH(w * 0.12, h * 0.25, w * 0.76, h * 0.1), Paint()..color = k(tool == FireTool.water ? const Color(0xFF5AA0D8) : const Color(0xFFD8B26A)));
      c.drawArc(Rect.fromLTWH(w * 0.1, h * 0.1, w * 0.8, h * 0.4), math.pi, math.pi, false, Paint()
        ..color = k(const Color(0xFF2B2F35))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8);
    }
  }

  @override
  bool shouldRepaint(RackToolPainter old) => old.tool != tool || old.taken != taken || old.spent != spent;
}
