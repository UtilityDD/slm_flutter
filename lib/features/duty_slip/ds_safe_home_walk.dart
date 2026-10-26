import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../zero_loss/zero_loss_fx.dart';
import '../zero_loss/zero_loss_ui.dart';
import 'duty_slip_engine.dart';

/// Daylight SAFE HOME walk — step 1 only (থামো ও বিপদ খুঁজো).
class DsSafeHomeWalk extends StatefulWidget {
  final DutySlipEngine engine;
  final VoidCallback onBack;
  final VoidCallback onDone;
  final bool muted;
  final Future<void> Function(String text) onSpeak;

  const DsSafeHomeWalk({
    super.key,
    required this.engine,
    required this.onBack,
    required this.onDone,
    required this.muted,
    required this.onSpeak,
  });

  @override
  State<DsSafeHomeWalk> createState() => _DsSafeHomeWalkState();
}

class _DsSafeHomeWalkState extends State<DsSafeHomeWalk> with TickerProviderStateMixin {
  late final AnimationController _walk;
  late final AnimationController _cam;
  late final AnimationController _shake;
  late final AnimationController _sun;
  var _planted = false;
  var _looking = false;
  var _done = false;
  var _wrongFlash = 0;

  @override
  void initState() {
    super.initState();
    _walk = AnimationController(vsync: this, duration: const Duration(milliseconds: 920))..repeat();
    _cam = AnimationController(vsync: this, duration: const Duration(milliseconds: 5600));
    _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _sun = AnimationController(vsync: this, duration: const Duration(milliseconds: 6400))..repeat(reverse: true);
    _cam.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) {
        setState(() {
          _looking = false;
          _done = true;
        });
      }
    });
    unawaited(ZlFx.cue('sounds/quiz_flip.wav', volume: 0.4, muted: widget.muted));
  }

  @override
  void dispose() {
    _walk.dispose();
    _cam.dispose();
    _shake.dispose();
    _sun.dispose();
    super.dispose();
  }

  void _tapPlate(int i) {
    if (_looking) return;
    if (_done) return;
    final step = dsSafeHome[i];
    if (i == 0) {
      _walk.stop();
      setState(() {
        _planted = true;
        _looking = true;
      });
      unawaited(ZlFx.cue('sounds/quiz_select.wav', volume: 0.5, muted: widget.muted));
      HapticFeedback.mediumImpact();
      unawaited(widget.onSpeak(step.whyBn));
      _cam.forward(from: 0);
      return;
    }
    setState(() => _wrongFlash = i);
    _shake.forward(from: 0);
    unawaited(ZlFx.cue('sounds/quiz_wrong.wav', muted: widget.muted));
    HapticFeedback.heavyImpact();
    unawaited(widget.onSpeak('না না — এটা বিপদ! আগে দাঁড়ান। চারদিক দেখুন।'));
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _wrongFlash = 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_walk, _cam, _shake, _sun]),
      builder: (_, _) {
        final shot = _shotFor(_cam.value);
        final shakeX = math.sin(_shake.value * math.pi * 6) * (1 - _shake.value) * 10;
        return Stack(
          fit: StackFit.expand,
          children: [
            Transform.translate(
              offset: Offset(shakeX, 0),
              child: ClipRect(
                child: Transform(
                  alignment: Alignment(shot.focus.dx * 2 - 1, shot.focus.dy * 2 - 1),
                  transform: Matrix4.identity()..scale(shot.zoom),
                  child: CustomPaint(
                    painter: _DaySitePainter(
                      walk: _walk.value,
                      planted: _planted ? 1 : 0,
                      sun: _sun.value,
                      look: shot.look,
                      headTurn: shot.head,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 168,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Color(0x99000000)],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              child: IconButton(
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1C1408)),
              ),
            ),
            if (shot.caption.isNotEmpty)
              Positioned(
                left: 18,
                right: 18,
                bottom: 168,
                child: _LookCaption(text: shot.caption),
              ),
            Positioned(
              left: 12,
              right: 12,
              bottom: _done ? 84 : 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _done
                        ? 'থামলেন। বিপদ দেখা গেল।'
                        : _looking
                            ? 'যা দেখছেন, সেটাই বিপদ।'
                            : 'আগে যেটা করতে হয়, সেটাই ছুঁবেন।',
                    textAlign: TextAlign.center,
                    style: zlText(14, weight: FontWeight.w800, height: 1.35, color: const Color(0xFFF6E7B0)).copyWith(
                      shadows: const [Shadow(color: Color(0xCC000000), blurRadius: 8)],
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (var r = 0; r < 4; r++)
                    Row(
                      children: [
                        for (var c = 0; c < 2; c++) ...[
                          if (c == 1) const SizedBox(width: 8),
                          Expanded(
                            child: _WalkPlate(
                              label: dsSafeHome[r * 2 + c].labelBn,
                              lit: _planted && r * 2 + c == 0,
                              danger: _wrongFlash == r * 2 + c,
                              onTap: () => _tapPlate(r * 2 + c),
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
            if (_done)
              Positioned(
                left: 0,
                right: 0,
                bottom: 10,
                child: Center(child: _WalkNext(onTap: widget.onDone)),
              ),
          ],
        );
      },
    );
  }
}

class _Shot {
  final Offset focus;
  final double zoom;
  final double head;
  final int look;
  final String caption;
  const _Shot(this.focus, this.zoom, this.head, this.look, this.caption);
}

_Shot _shotFor(double t) {
  const keys = <(double, Offset, double, double, int, String)>[
    (0.00, Offset(0.58, 0.38), 1.00, 0.15, 0, ''),
    (0.10, Offset(0.58, 0.34), 1.28, 0.00, 0, ''),
    (0.22, Offset(0.66, 0.62), 2.35, 0.55, 1, 'ছিঁড়ে পড়া তার'),
    (0.38, Offset(0.66, 0.62), 2.38, 0.55, 1, 'ছিঁড়ে পড়া তার'),
    (0.48, Offset(0.38, 0.58), 2.30, -0.25, 2, 'খুঁটির গোড়ায় জল'),
    (0.60, Offset(0.38, 0.58), 2.32, -0.25, 2, 'খুঁটির গোড়ায় জল'),
    (0.70, Offset(0.22, 0.32), 2.48, -0.7, 3, 'খুঁটিতে ফাটল'),
    (0.80, Offset(0.86, 0.56), 2.40, 0.85, 4, 'ঝোপে সাপের ভয়'),
    (0.90, Offset(0.58, 0.34), 1.22, 0.00, 0, ''),
    (1.00, Offset(0.58, 0.38), 1.00, 0.00, 0, ''),
  ];
  if (t <= 0) {
    final a = keys.first;
    return _Shot(a.$2, a.$3, a.$4, a.$5, a.$6);
  }
  if (t >= 1) {
    final a = keys.last;
    return _Shot(a.$2, a.$3, a.$4, a.$5, a.$6);
  }
  for (var i = 0; i < keys.length - 1; i++) {
    final a = keys[i];
    final b = keys[i + 1];
    if (t >= a.$1 && t <= b.$1) {
      final u = Curves.easeInOutCubic.transform(((t - a.$1) / (b.$1 - a.$1)).clamp(0.0, 1.0));
      return _Shot(
        Offset(ui.lerpDouble(a.$2.dx, b.$2.dx, u)!, ui.lerpDouble(a.$2.dy, b.$2.dy, u)!),
        ui.lerpDouble(a.$3, b.$3, u)!,
        ui.lerpDouble(a.$4, b.$4, u)!,
        u < 0.5 ? a.$5 : b.$5,
        u < 0.45 ? a.$6 : b.$6,
      );
    }
  }
  final a = keys.last;
  return _Shot(a.$2, a.$3, a.$4, a.$5, a.$6);
}

class _LookCaption extends StatelessWidget {
  final String text;
  const _LookCaption({required this.text});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xCC1C1408),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: zlText(13, weight: FontWeight.w800, color: const Color(0xFFF6E7B0)),
        ),
      ),
    );
  }
}

class _WalkPlate extends StatelessWidget {
  final String label;
  final bool lit;
  final bool danger;
  final VoidCallback onTap;
  const _WalkPlate({required this.label, required this.lit, required this.danger, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Ink(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: danger
                    ? const [Color(0xFFFFC9B8), Color(0xFFC45A3A), Color(0xFF6A2414)]
                    : lit
                        ? const [Color(0xFFFFF3C4), Color(0xFFE0B13A), Color(0xFF8A5A10)]
                        : const [Color(0xFFE8D39A), Color(0xFFB0892A), Color(0xFF6A4E12)],
              ),
              border: Border.all(
                color: danger
                    ? const Color(0xFF7A2010)
                    : lit
                        ? const Color(0xFFF6E7B0)
                        : const Color(0xFF5C4316),
                width: lit || danger ? 1.35 : 1,
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: zlText(14, weight: FontWeight.w900, color: const Color(0xFF1C1408)),
            ),
          ),
        ),
      ),
    );
  }
}

class _WalkNext extends StatelessWidget {
  final VoidCallback onTap;
  const _WalkNext({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF8A5A10), width: 1.6),
            color: const Color(0x33C9A227),
          ),
          child: const Icon(Icons.arrow_forward_rounded, size: 30, color: Color(0xFF6A4E12)),
        ),
      ),
    );
  }
}

class _DaySitePainter extends CustomPainter {
  final double walk;
  final double planted;
  final double sun;
  final int look;
  final double headTurn;
  const _DaySitePainter({
    required this.walk,
    required this.planted,
    required this.sun,
    required this.look,
    required this.headTurn,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final sky = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, h * 0.48),
        const [Color(0xFF7EB6D9), Color(0xFFC5DCE8), Color(0xFFE8D4A4)],
        const [0.0, 0.55, 1.0],
      );
    canvas.drawRect(Offset.zero & size, sky);

    final sunC = Offset(w * 0.86, h * 0.14);
    final halo = 0.82 + 0.18 * sun;
    canvas.drawCircle(
      sunC,
      w * 0.22 * halo,
      Paint()
        ..shader = ui.Gradient.radial(
          sunC,
          w * 0.22 * halo,
          [Color.fromRGBO(255, 244, 200, 0.55), const Color(0x00FFF4C8)],
        ),
    );
    canvas.drawCircle(sunC, w * 0.055, Paint()..color = const Color(0xFFFFF1B8));
    canvas.drawCircle(sunC, w * 0.038, Paint()..color = const Color(0xFFFFFDF2));

    final groundTop = h * 0.46;
    canvas.drawRect(
      Rect.fromLTWH(0, groundTop, w, h - groundTop),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, groundTop),
          Offset(0, h),
          const [Color(0xFFD2B07A), Color(0xFFB0894A), Color(0xFF8A6230)],
          const [0.0, 0.45, 1.0],
        ),
    );
    final road = Path()
      ..moveTo(w * 0.08, h)
      ..lineTo(w * 0.28, groundTop)
      ..lineTo(w * 0.78, groundTop)
      ..lineTo(w * 1.02, h)
      ..close();
    canvas.drawPath(road, Paint()..color = const Color(0xFFC9A066));
    canvas.drawPath(
      road,
      Paint()
        ..color = const Color(0x66FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    _pole(canvas, w, h, groundTop);
    _lineAndWire(canvas, w, h, groundTop);
    _puddle(canvas, w, h, groundTop);
    _jungle(canvas, w, h, groundTop);
    _man(canvas, Offset(w * 0.58, groundTop), h * 0.50);
  }

  void _pole(Canvas canvas, double w, double h, double groundTop) {
    final x = w * 0.22;
    final top = h * 0.08;
    final pole = RRect.fromLTRBR(x - 7, top, x + 7, groundTop + 8, const Radius.circular(3));
    canvas.drawRRect(pole, Paint()..color = const Color(0xFF6B4423));
    canvas.drawRRect(
      pole,
      Paint()
        ..color = const Color(0x33FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    final crack = Path()
      ..moveTo(x - 1.5, h * 0.28)
      ..cubicTo(x + 3, h * 0.34, x - 4, h * 0.40, x + 1, h * 0.48)
      ..cubicTo(x + 3.5, h * 0.52, x - 2, h * 0.55, x, groundTop - 4);
    canvas.drawPath(
      crack,
      Paint()
        ..color = look == 3 ? const Color(0xFF1A0E08) : const Color(0xFF3A2414)
        ..style = PaintingStyle.stroke
        ..strokeWidth = look == 3 ? 2.4 : 1.5
        ..strokeCap = StrokeCap.round,
    );
    if (look == 3) {
      canvas.drawPath(
        crack,
        Paint()
          ..color = const Color(0x88F59E0B)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
    }
    canvas.drawRect(Rect.fromCenter(center: Offset(x, top + 18), width: 52, height: 5), Paint()..color = const Color(0xFF4A3018));
  }

  void _lineAndWire(Canvas canvas, double w, double h, double groundTop) {
    final x = w * 0.22;
    final y = h * 0.08 + 18;
    final line = Paint()
      ..color = const Color(0xFF1F2933)
      ..strokeWidth = 1.7
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(x - 26, y), Offset(w * 0.08, y - 6), line);
    canvas.drawLine(Offset(x + 26, y), Offset(w * 0.92, y + 4), line);

    final snap = Path()
      ..moveTo(x + 26, y)
      ..cubicTo(w * 0.42, h * 0.22, w * 0.50, h * 0.48, w * 0.62, groundTop + 6)
      ..cubicTo(w * 0.66, groundTop + 10, w * 0.70, groundTop + 8, w * 0.68, groundTop + 4);
    canvas.drawPath(
      snap,
      Paint()
        ..color = look == 1 ? const Color(0xFF111827) : const Color(0xFF2A3340)
        ..style = PaintingStyle.stroke
        ..strokeWidth = look == 1 ? 2.6 : 1.8
        ..strokeCap = StrokeCap.round,
    );
    final tip = Offset(w * 0.68, groundTop + 4);
    canvas.drawCircle(tip, look == 1 ? 4.5 : 3, Paint()..color = const Color(0xFF111827));
    if (look == 1) {
      canvas.drawCircle(
        tip,
        14,
        Paint()
          ..color = const Color(0x55F59E0B)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
    canvas.drawLine(tip, tip + const Offset(-7, 9), Paint()..color = const Color(0xFF111827)..strokeWidth = 1.2);
    canvas.drawLine(tip, tip + const Offset(6, 10), Paint()..color = const Color(0xFF111827)..strokeWidth = 1.2);
  }

  void _puddle(Canvas canvas, double w, double h, double groundTop) {
    final r = Rect.fromCenter(center: Offset(w * 0.38, groundTop + h * 0.055), width: w * 0.22, height: h * 0.055);
    canvas.drawOval(
      r,
      Paint()
        ..shader = ui.Gradient.linear(
          r.topCenter,
          r.bottomCenter,
          look == 2
              ? const [Color(0xFF6FA8C9), Color(0xFF2E5A72)]
              : const [Color(0xFF7AA3B8), Color(0xFF3D5C6A)],
        ),
    );
    canvas.drawOval(
      r.deflate(3),
      Paint()
        ..color = const Color(0x55FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    if (look == 2) {
      canvas.drawOval(
        r.inflate(8),
        Paint()
          ..color = const Color(0x44F59E0B)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }
  }

  void _jungle(Canvas canvas, double w, double h, double groundTop) {
    final base = Offset(w * 0.88, groundTop + 8);
    for (var i = 0; i < 7; i++) {
      final px = base.dx - 28 + i * 9.0;
      final ph = 28.0 + (i % 3) * 10;
      canvas.drawPath(
        Path()
          ..moveTo(px, base.dy)
          ..quadraticBezierTo(px - 8, base.dy - ph * 0.5, px + 2, base.dy - ph)
          ..quadraticBezierTo(px + 10, base.dy - ph * 0.45, px + 6, base.dy),
        Paint()..color = Color.lerp(const Color(0xFF3F6B32), const Color(0xFF1E3D18), i / 7)!,
      );
    }
    final snake = Path()
      ..moveTo(base.dx - 36, base.dy - 6)
      ..cubicTo(base.dx - 22, base.dy - 18, base.dx - 10, base.dy - 4, base.dx + 2, base.dy - 14)
      ..cubicTo(base.dx + 8, base.dy - 18, base.dx + 10, base.dy - 22, base.dx + 6, base.dy - 26);
    canvas.drawPath(
      snake,
      Paint()
        ..color = look == 4 ? const Color(0xFF2A4A18) : const Color(0x882A4A18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = look == 4 ? 3.2 : 2.0
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(base.dx + 6, base.dy - 26),
      look == 4 ? 3.2 : 2.2,
      Paint()..color = const Color(0xFF1A3010),
    );
    if (look == 4) {
      canvas.drawCircle(
        Offset(base.dx - 10, base.dy - 10),
        18,
        Paint()
          ..color = const Color(0x55F59E0B)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
  }

  void _man(Canvas canvas, Offset feet, double body) {
    final phase = walk * math.pi * 2;
    final plant = planted.clamp(0.0, 1.0);
    final swing = (1 - plant) * 0.62;
    final hipL = math.sin(phase) * swing;
    final hipR = math.sin(phase + math.pi) * swing;
    final bob = (1 - plant) * math.sin(phase * 2).abs() * body * 0.04;
    final inkW = math.max(4.5, body * 0.028);
    final ink = Paint()
      ..color = const Color(0xFF1A140C)
      ..strokeWidth = inkW
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.save();
    canvas.translate(feet.dx, feet.dy - bob);

    void limb(double ang, double len, {double knee = 0, bool footLeft = true}) {
      canvas.save();
      canvas.rotate(ang);
      canvas.drawLine(Offset.zero, Offset(0, len), ink);
      canvas.save();
      canvas.translate(0, len);
      canvas.rotate(plant > 0.6 ? 0.12 : knee);
      canvas.drawLine(Offset.zero, Offset(0, len * 0.92), ink);
      canvas.drawLine(Offset(0, len * 0.92), Offset(footLeft ? -body * 0.07 : body * 0.07, len * 0.92), ink);
      canvas.restore();
      canvas.restore();
    }

    limb(hipL, body * 0.20, knee: hipL * 0.55, footLeft: true);
    limb(hipR, body * 0.20, knee: hipR * 0.55, footLeft: false);

    final chest = -body * 0.40;
    canvas.drawLine(Offset.zero, Offset(0, chest), ink);

    final vest = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(0, chest * 0.55), width: body * 0.20, height: body * 0.28),
      Radius.circular(body * 0.04),
    );
    canvas.drawRRect(vest, Paint()..color = const Color(0xFFF5C542));
    canvas.drawRRect(vest, ink);

    canvas.save();
    canvas.translate(0, chest + body * 0.06);
    canvas.rotate(-0.45 + hipR * 0.5);
    canvas.drawLine(Offset.zero, Offset(0, body * 0.22), ink);
    canvas.restore();
    canvas.save();
    canvas.translate(0, chest + body * 0.06);
    canvas.rotate(0.40 + hipL * 0.5);
    canvas.drawLine(Offset.zero, Offset(0, body * 0.22), ink);
    canvas.restore();

    canvas.save();
    canvas.translate(headTurn * body * 0.05, chest - body * 0.08);
    canvas.drawCircle(Offset.zero, body * 0.085, Paint()..color = const Color(0xFFE8C48A));
    canvas.drawCircle(Offset.zero, body * 0.085, ink);
    final helm = Path()
      ..moveTo(-body * 0.11, -body * 0.01)
      ..quadraticBezierTo(0, -body * 0.16, body * 0.11, -body * 0.01)
      ..lineTo(body * 0.12, body * 0.03)
      ..lineTo(-body * 0.12, body * 0.03)
      ..close();
    canvas.drawPath(helm, Paint()..color = const Color(0xFFF97316));
    canvas.drawPath(helm, ink);
    canvas.drawLine(
      Offset(-body * 0.12, body * 0.028),
      Offset(body * 0.12, body * 0.028),
      Paint()
        ..color = const Color(0xFF1A140C)
        ..strokeWidth = inkW
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DaySitePainter old) =>
      old.walk != walk || old.planted != planted || old.sun != sun || old.look != look || old.headTurn != headTurn;
}
