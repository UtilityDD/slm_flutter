import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../tokens/slm_colors.dart';
import 'slm_motion_scope.dart';

/// Now and then a few birds or a butterfly drift across the screen and fly
/// far away (owner, 2026-11-15). Home and the ladder map only, never inside a
/// level. Silent, drawn in code, taps pass through.
///
/// Put it behind the content: `Positioned.fill(child: SlmAmbientLife())`.
/// Between visitors only a [Timer] waits; the ticker runs only while one is
/// on screen. Nothing at all with "remove animations". No new visitor while
/// TickerMode is off (a route covers the screen), while a [SlmMotionScope]
/// pauses loops (the ladder's idle calm) or while the app is not resumed; a
/// visitor already in flight finishes its flight.
class SlmAmbientLife extends StatefulWidget {
  final bool enabled;

  /// Seeds the dice (tests); null: a new random sky each time.
  final int? seed;

  /// Wait before the first visitor; null: 8–18 s.
  final Duration? firstDelay;

  /// Usual wait between visitors (now and then a longer 40–60 s pause).
  final Duration minGap;
  final Duration maxGap;

  /// Told how many are on screen each time one arrives or leaves (tests).
  final ValueChanged<int>? onVisitors;

  static const maxVisitors = 2;

  const SlmAmbientLife({
    super.key,
    this.enabled = true,
    this.seed,
    this.firstDelay,
    this.minGap = const Duration(seconds: 10),
    this.maxGap = const Duration(seconds: 30),
    this.onVisitors,
  });

  @override
  State<SlmAmbientLife> createState() => _SlmAmbientLifeState();
}

class _SlmAmbientLifeState extends State<SlmAmbientLife> with SingleTickerProviderStateMixin {
  late final math.Random _rng = math.Random(widget.seed);
  late final Ticker _ticker = createTicker(_tick);
  late final AppLifecycleListener _life;
  final _visitors = <_Visitor>[];
  final _clock = ValueNotifier<Duration>(Duration.zero);
  Timer? _timer;
  var _first = true;
  var _now = Duration.zero;
  var _still = false;
  var _may = false;

  @override
  void initState() {
    super.initState();
    _life = AppLifecycleListener(onStateChange: (_) => _sync());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = !widget.enabled || slmReduceMotion(context);
    _may = TickerMode.valuesOf(context).enabled && slmLoopsOn(context);
    _sync();
  }

  @override
  void didUpdateWidget(covariant SlmAmbientLife old) {
    super.didUpdateWidget(old);
    _still = !widget.enabled || slmReduceMotion(context);
    _sync();
  }

  bool get _resumed {
    final s = WidgetsBinding.instance.lifecycleState;
    return s == null || s == AppLifecycleState.resumed;
  }

  void _sync() {
    if (!mounted) return;
    if (_still) {
      _timer?.cancel();
      _timer = null;
      if (_visitors.isNotEmpty) {
        _visitors.clear();
        _ticker.stop();
        widget.onVisitors?.call(0);
      }
    } else if (!_may || !_resumed) {
      _timer?.cancel();
      _timer = null;
    } else {
      _timer ??= Timer(_nextWait(), _arrive);
    }
  }

  Duration _between(Duration a, Duration b) =>
      a + Duration(microseconds: ((b - a).inMicroseconds * _rng.nextDouble()).round());

  Duration _nextWait() {
    if (_first) return widget.firstDelay ?? _between(const Duration(seconds: 8), const Duration(seconds: 18));
    if (_rng.nextDouble() < 0.15) return _between(const Duration(seconds: 40), const Duration(seconds: 60));
    return _between(widget.minGap, widget.maxGap);
  }

  void _arrive() {
    _timer = null;
    if (!mounted || _still || !_may || !_resumed) return;
    _first = false;
    if (_visitors.length < SlmAmbientLife.maxVisitors) {
      if (!_ticker.isActive) {
        _now = Duration.zero;
        _ticker.start();
      }
      // Butterflies come one at a time; birds may join one.
      final butterfly = !_visitors.any((v) => !v.bird) && _rng.nextDouble() < 0.45;
      _visitors.add(_Visitor(_rng, _now, bird: !butterfly));
      widget.onVisitors?.call(_visitors.length);
    }
    _sync();
  }

  void _tick(Duration elapsed) {
    _now = elapsed;
    final before = _visitors.length;
    _visitors.removeWhere((v) => elapsed - v.born >= v.life);
    _clock.value = elapsed; // the last paint clears the sky
    if (_visitors.isEmpty) _ticker.stop();
    if (_visitors.length != before) widget.onVisitors?.call(_visitors.length);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _life.dispose();
    _ticker.dispose();
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || slmReduceMotion(context)) return const SizedBox.expand();
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(painter: _AmbientPainter(_visitors, _clock), size: Size.infinite),
      ),
    );
  }
}

double _lerp(double a, double b, double t) => a + (b - a) * t;

Offset _quad(Offset a, Offset k, Offset b, double t) => a * ((1 - t) * (1 - t)) + k * (2 * (1 - t) * t) + b * (t * t);

/// One visit: a small flock of birds or a butterfly. Points are fractions of
/// the box: [a] where it enters, [k] the bend (a butterfly hovers there), [c]
/// where it vanishes.
class _Visitor {
  final bool bird;
  final Duration born;
  late final Duration life;
  late final Offset a, k, c;
  late final double size, phase, flapHz, hover;
  final flock = <Offset>[];

  _Visitor(math.Random r, this.born, {required this.bird}) {
    double d() => r.nextDouble();
    phase = d() * math.pi * 2;
    if (bird) {
      final dir = r.nextBool() ? 1.0 : -1.0;
      final y = 0.07 + d() * 0.2;
      a = Offset(dir > 0 ? -0.08 : 1.08, y);
      c = Offset(dir > 0 ? 0.5 + d() * 0.4 : 0.5 - d() * 0.4, math.max(0.02, y - 0.03 - d() * 0.09));
      k = Offset((a.dx + c.dx) / 2, (y + c.dy) / 2 + (d() - 0.65) * 0.14);
      life = Duration(milliseconds: 9000 + r.nextInt(5000));
      size = 5.5 + d() * 3;
      flapHz = 1.3 + d() * 0.8;
      hover = 0;
      flock.add(Offset.zero);
      final n = r.nextInt(3); // 1–3 birds in a loose V
      for (var i = 1; i <= n; i++) {
        flock.add(Offset(-dir * (2.4 + d() * 1.2) * ((i + 1) ~/ 2), (i.isOdd ? 1 : -1) * (1.1 + d() * 0.7)));
      }
    } else {
      final side = r.nextInt(3);
      a = switch (side) {
        0 => Offset(-0.05, 0.6 + d() * 0.3),
        1 => Offset(1.05, 0.6 + d() * 0.3),
        _ => Offset(0.15 + d() * 0.7, 1.05),
      };
      k = Offset(0.2 + d() * 0.6, 0.35 + d() * 0.3);
      c = Offset((k.dx + (d() - 0.5) * 0.5).clamp(0.05, 0.95), -0.06 + d() * 0.14);
      life = Duration(milliseconds: 8000 + r.nextInt(4500));
      size = 6 + d() * 3;
      flapHz = 4 + d() * 2;
      hover = d() < 0.6 ? 0.12 + d() * 0.12 : 0;
    }
  }
}

class _AmbientPainter extends CustomPainter {
  final List<_Visitor> visitors;
  final ValueListenable<Duration> clock;

  _AmbientPainter(this.visitors, this.clock) : super(repaint: clock);

  final _line = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  final _fill = Paint();

  @override
  void paint(Canvas canvas, Size size) {
    for (final v in visitors) {
      final age = clock.value - v.born;
      if (age.isNegative || age >= v.life) continue;
      final sec = age.inMicroseconds / 1e6;
      final t = age.inMicroseconds / v.life.inMicroseconds;
      v.bird ? _birds(canvas, size, v, t, sec) : _butterfly(canvas, size, v, t, sec);
    }
  }

  void _birds(Canvas canvas, Size box, _Visitor v, double t, double sec) {
    final p = _quad(v.a, v.k, v.c, Curves.easeOutSine.transform(t));
    final far = t < 0.4 ? 0.0 : math.pow((t - 0.4) / 0.6, 1.2).toDouble();
    final s = v.size * _lerp(1, 0.18, far);
    final alpha = 0.55 * math.min(1.0, t / 0.06) * (t < 0.65 ? 1 : 1 - math.pow((t - 0.65) / 0.35, 1.5));
    _line
      ..color = SlmColors.gold100.withValues(alpha: alpha)
      ..strokeWidth = math.max(0.7, s * 0.2);
    final at = Offset(p.dx * box.width, p.dy * box.height + math.sin(sec * 1.1 + v.phase) * 3);
    for (var i = 0; i < v.flock.length; i++) {
      final ph = sec * math.pi * 2 * v.flapHz + v.phase + i * 0.9;
      final glide = 0.35 + 0.65 * (0.5 + 0.5 * math.sin(sec * 0.8 + v.phase + i));
      final f = math.sin(ph) * glide + (1 - glide) * 0.3;
      final o = at + v.flock[i] * s;
      final tip = -s * 0.5 * f;
      final mid = -s * 0.28 * f - s * 0.12;
      canvas.drawPath(
        Path()
          ..moveTo(o.dx - s, o.dy + tip)
          ..quadraticBezierTo(o.dx - s * 0.45, o.dy + mid, o.dx, o.dy + s * 0.1)
          ..quadraticBezierTo(o.dx + s * 0.45, o.dy + mid, o.dx + s, o.dy + tip),
        _line,
      );
    }
  }

  void _butterfly(Canvas canvas, Size box, _Visitor v, double t, double sec) {
    final s1 = (1 - v.hover) * 0.45;
    final s2 = s1 + v.hover;
    Offset p;
    var away = 0.0;
    if (t < s1) {
      final k1 = Offset(_lerp(v.a.dx, v.k.dx, 0.3), _lerp(v.a.dy, v.k.dy, 0.8));
      p = _quad(v.a, k1, v.k, Curves.easeInOutSine.transform(t / s1));
    } else if (t < s2) {
      p = v.k;
    } else {
      away = (t - s2) / (1 - s2);
      final k2 = Offset(_lerp(v.k.dx, v.c.dx, 0.8), v.k.dy - 0.05);
      p = _quad(v.k, k2, v.c, Curves.easeInSine.transform(away));
    }
    final s = v.size * _lerp(1, 0.3, Curves.easeIn.transform(away));
    final alpha = math.min(1.0, t / 0.08) * (away < 0.55 ? 1 : 1 - (away - 0.55) / 0.45);
    final wobble = Offset(
      math.sin(sec * 1.9 + v.phase) * 12 + math.sin(sec * 4.3 + v.phase * 2) * 4,
      math.sin(sec * 2.7 + v.phase) * 9,
    );
    final open = 0.2 + 0.8 * math.sin(sec * math.pi * 2 * v.flapHz + v.phase).abs();
    canvas.save();
    canvas.translate(p.dx * box.width + wobble.dx, p.dy * box.height + wobble.dy);
    canvas.rotate(math.sin(sec * 1.3 + v.phase) * 0.25);
    _fill
      ..color = SlmColors.emerald300.withValues(alpha: 0.2 * alpha)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.9);
    canvas.drawCircle(Offset.zero, s * 1.5, _fill);
    _fill.maskFilter = null;
    canvas.save();
    canvas.scale(open, 1);
    for (final x in const [-1.0, 1.0]) {
      _fill.color = SlmColors.emerald300.withValues(alpha: 0.8 * alpha);
      canvas.drawOval(Rect.fromCenter(center: Offset(x * s * 0.55, -s * 0.32), width: s * 1.1, height: s * 0.9), _fill);
      _fill.color = SlmColors.gold300.withValues(alpha: 0.75 * alpha);
      canvas.drawOval(Rect.fromCenter(center: Offset(x * s * 0.4, s * 0.34), width: s * 0.8, height: s * 0.7), _fill);
    }
    canvas.restore();
    _line
      ..color = SlmColors.ivory.withValues(alpha: 0.7 * alpha)
      ..strokeWidth = math.max(0.8, s * 0.14);
    canvas.drawLine(Offset(0, -s * 0.5), Offset(0, s * 0.5), _line);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _AmbientPainter old) => old.visitors != visitors || old.clock != clock;
}
