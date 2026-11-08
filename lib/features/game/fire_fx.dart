import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

// Lottie-style motion for the fire levels (lesson 1.8). The animations are
// vector JSON made by tool/lottie_gen.py (assets/game/anim/); the play is
// driven here so it stays cheap:
//  * loops (fire, smoke, sprays) run at 24 fps from a timer, only while
//    "awake" — a few seconds after each move — then hold a still frame, so an
//    idle screen draws nothing;
//  * one-shots (throws, bloom, flare-up) play once and report when done;
//  * with reduce-motion everything is a still frame and one-shots end at once.

abstract final class FireAnim {
  static const fire = 'fire_loop';
  static const smoke = 'smoke_loop';
  static const sprayDcp = 'spray_dcp';
  static const sprayCo2 = 'spray_co2';
  static const sand = 'sand_throw';
  static const water = 'water_throw';
  static const weak = 'weak_puff';
  static const bloom = 'rescue_bloom';
  static const flare = 'flare_up';

  static final Map<String, Future<LottieComposition>> _cache = {};

  static Future<LottieComposition> load(String name) =>
      _cache[name] ??= AssetLottie('assets/game/anim/$name.json').load();
}

/// How long a loop keeps moving after the last wake.
const kFxAwake = Duration(seconds: 5);

/// A looping animation at 24 fps while awake (bump [wake] to wake it); a
/// still frame otherwise.
class FxLoop extends StatefulWidget {
  const FxLoop(this.name, {super.key, required this.wake, this.paused = false, this.quiet = false, this.still = 0.35, this.fit = BoxFit.fill});

  final String name;

  /// Change it to keep the loop moving for [kFxAwake].
  final int wake;

  /// Under a card or after the level: hold still.
  final bool paused;
  final bool quiet;

  /// The still frame (0..1) shown when not moving.
  final double still;
  final BoxFit fit;

  @override
  State<FxLoop> createState() => _FxLoopState();
}

class _FxLoopState extends State<FxLoop> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, value: widget.still);
  LottieComposition? _comp;
  Timer? _tick;
  int _left = 0;
  static const _ms = 42;

  @override
  void initState() {
    super.initState();
    unawaited(FireAnim.load(widget.name).then((c) {
      if (!mounted) return;
      setState(() => _comp = c);
      _arm();
    }));
  }

  @override
  void didUpdateWidget(FxLoop old) {
    super.didUpdateWidget(old);
    if (old.wake != widget.wake || old.paused != widget.paused || old.quiet != widget.quiet) _arm();
  }

  void _arm() {
    if (_comp == null || widget.quiet || widget.paused) {
      _stop();
      return;
    }
    _left = kFxAwake.inMilliseconds ~/ _ms;
    _tick ??= Timer.periodic(const Duration(milliseconds: _ms), (_) => _step());
  }

  void _step() {
    final comp = _comp;
    if (!mounted || comp == null) return;
    if (--_left < 0) {
      _stop();
      return;
    }
    final n = math.max(1.0, comp.endFrame - comp.startFrame);
    _c.value = (_c.value + 1 / n) % 1.0;
  }

  void _stop() {
    _tick?.cancel();
    _tick = null;
  }

  @override
  void dispose() {
    _stop();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final comp = _comp;
    if (comp == null) return const SizedBox.expand();
    return IgnorePointer(child: Lottie(composition: comp, controller: _c, fit: widget.fit));
  }
}

/// A one-shot animation; [onDone] when it has played (at once when quiet).
class FxOnce extends StatefulWidget {
  const FxOnce(this.name, {super.key, this.ms = 1100, this.quiet = false, this.onDone, this.fit = BoxFit.fill});

  final String name;
  final int ms;
  final bool quiet;
  final VoidCallback? onDone;
  final BoxFit fit;

  @override
  State<FxOnce> createState() => _FxOnceState();
}

class _FxOnceState extends State<FxOnce> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: Duration(milliseconds: widget.ms));
  LottieComposition? _comp;
  var _done = false;

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((s) {
      if (s == AnimationStatus.completed) _finish();
    });
    if (widget.quiet) {
      _c.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
    } else {
      // Plays on time even before the art is loaded (the logic never waits).
      unawaited(_c.forward());
    }
    unawaited(FireAnim.load(widget.name).then((c) {
      if (mounted) setState(() => _comp = c);
    }));
  }

  void _finish() {
    if (_done || !mounted) return;
    _done = true;
    widget.onDone?.call();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final comp = _comp;
    if (comp == null || widget.quiet) return const SizedBox.expand();
    return IgnorePointer(child: Lottie(composition: comp, controller: _c, fit: widget.fit));
  }
}

/// Places a stream-like animation drawn left→right in a [w]x[h] box (from
/// [from] to [to] in its own pixels) so that it runs from [a] to [b] in the
/// parent's pixels. Use inside a Stack.
class FxBeam extends StatelessWidget {
  const FxBeam({super.key, required this.a, required this.b, required this.child, this.w = 320, this.h = 120, this.from = const Offset(10, 60), this.to = const Offset(300, 60), this.thick = 1});

  final Offset a;
  final Offset b;
  final double w;
  final double h;
  final Offset from;
  final Offset to;
  final Widget child;

  /// Extra thickness across the beam (a short beam would be a thin thread).
  final double thick;

  @override
  Widget build(BuildContext context) {
    final want = b - a;
    final own = to - from;
    final scale = want.distance / math.max(1, own.distance);
    final angle = want.direction - own.direction;
    final sy = scale * thick;
    return Positioned(
      left: a.dx - from.dx * scale,
      top: a.dy - from.dy * sy,
      width: w * scale,
      height: h * sy,
      child: Transform.rotate(
        angle: angle,
        alignment: Alignment(from.dx / w * 2 - 1, from.dy / h * 2 - 1),
        child: child,
      ),
    );
  }
}
