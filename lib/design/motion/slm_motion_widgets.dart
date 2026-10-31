import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/slm_motion.dart';
import 'slm_motion_scope.dart';

typedef SlmTactileBuilder = Widget Function(BuildContext context, double press, Widget? child);

/// Press physics shared by buttons and cards. [press] runs 0 → 1 while the
/// finger is down and springs slightly below 0 on release, so builders can
/// map it to depth, scale, shadow or glow.
class SlmTactile extends StatefulWidget {
  final SlmTactileBuilder builder;
  final Widget? child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool haptic;
  final String? semanticLabel;

  const SlmTactile({
    super.key,
    required this.builder,
    this.child,
    this.onTap,
    this.onLongPress,
    this.haptic = true,
    this.semanticLabel,
  });

  @override
  State<SlmTactile> createState() => _SlmTactileState();
}

class _SlmTactileState extends State<SlmTactile> with SingleTickerProviderStateMixin {
  late final AnimationController _press = AnimationController(
    vsync: this,
    lowerBound: -0.3,
    upperBound: 1,
    value: 0,
  );

  bool get _enabled => widget.onTap != null || widget.onLongPress != null;

  void _down() {
    if (slmReduceMotion(context)) return;
    _press.animateTo(1, duration: SlmMotion.instant, curve: SlmMotion.standard);
  }

  void _up() {
    if (slmReduceMotion(context)) return;
    final v = _press.value;
    // A quick tap may lift before the press shows; finish it first.
    final dip = v < 0.85
        ? _press.animateTo(1, duration: Duration(milliseconds: (70 * (1 - v)).round() + 10))
        : TickerFuture.complete();
    dip.whenCompleteOrCancel(() {
      if (mounted) _press.animateTo(0, duration: const Duration(milliseconds: 340), curve: Curves.easeOutBack);
    });
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _enabled;
    return Semantics(
      button: enabled,
      enabled: enabled,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _down() : null,
        onTapUp: enabled ? (_) => _up() : null,
        onTapCancel: enabled ? _up : null,
        onTap: widget.onTap == null
            ? null
            : () {
                if (widget.haptic) HapticFeedback.selectionClick();
                widget.onTap!();
              },
        onLongPress: widget.onLongPress,
        child: AnimatedBuilder(
          animation: _press,
          child: widget.child,
          builder: (context, child) => widget.builder(context, _press.value, child),
        ),
      ),
    );
  }
}

/// Tap feedback shared by tappable components: a slight press-in, a
/// selection haptic, and no reaction at all when [onTap] is null.
class SlmPressable extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final bool haptic;
  final String? semanticLabel;

  const SlmPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.97,
    this.haptic = true,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null || onLongPress != null;
    return SlmTactile(
      onTap: onTap,
      onLongPress: onLongPress,
      haptic: haptic,
      semanticLabel: semanticLabel,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.45,
        duration: SlmMotion.fast,
        child: child,
      ),
      builder: (context, press, child) => Transform.scale(
        scale: 1 - (1 - pressedScale) * press,
        child: child,
      ),
    );
  }
}

/// Fade-and-rise entrance. Give list items increasing [index] for a stagger.
/// Replays when the surrounding [SlmMotionScope] asks for it.
class SlmReveal extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;
  final double rise;
  final Duration duration;

  const SlmReveal({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = Duration.zero,
    this.rise = 14,
    this.duration = SlmMotion.slow,
  });

  @override
  State<SlmReveal> createState() => _SlmRevealState();
}

class _SlmRevealState extends State<SlmReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _t = CurvedAnimation(parent: _c, curve: SlmMotion.emphasized);
  int? _token;
  Timer? _wait;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final token = slmReplayToken(context);
    if (token == _token) return;
    _token = token;
    _wait?.cancel();
    if (slmReduceMotion(context)) {
      _c.value = 1;
      return;
    }
    _c.value = 0;
    _wait = Timer(widget.delay + SlmMotion.stagger * math.min(widget.index, 12), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _wait?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _t.value,
        child: Transform.translate(
          offset: Offset(0, widget.rise * (1 - _t.value)),
          child: child,
        ),
      ),
    );
  }
}

/// Paints a soft diagonal band of light across [child] at sweep position
/// [t] (0 = off the left edge, 1 = off the right edge).
class SlmSweepMask extends StatelessWidget {
  final double t;
  final double intensity;
  final Color color;
  final Widget child;

  const SlmSweepMask({
    super.key,
    required this.t,
    required this.child,
    this.intensity = 1,
    this.color = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    if (t <= 0 || t >= 1) return child;
    final a = (0.55 * intensity).clamp(0.0, 1.0);
    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (r) {
        final x = -0.5 * r.width + t * 2 * r.width;
        return LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            color.withValues(alpha: 0),
            color.withValues(alpha: a * 0.5),
            color.withValues(alpha: a),
            color.withValues(alpha: a * 0.5),
            color.withValues(alpha: 0),
          ],
          stops: const [0, 0.38, 0.5, 0.62, 1],
          transform: const GradientRotation(-0.35),
        ).createShader(Rect.fromLTWH(x - r.width * 0.18, 0, r.width * 0.36, r.height));
      },
      child: child,
    );
  }
}

/// A soft band of light that sweeps across [child] every [period].
/// The band covers the first 45% of a loop.
class SlmShimmer extends StatefulWidget {
  final Widget child;
  final Duration period;
  final double intensity;
  final bool enabled;

  const SlmShimmer({
    super.key,
    required this.child,
    this.period = const Duration(milliseconds: 3400),
    this.intensity = 1,
    this.enabled = true,
  });

  @override
  State<SlmShimmer> createState() => _SlmShimmerState();
}

class _SlmShimmerState extends State<SlmShimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period);
  bool _run = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant SlmShimmer old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    _run = widget.enabled && slmLoopsOn(context);
    if (_run && !_c.isAnimating) {
      _c.repeat();
    } else if (!_run && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || slmReduceMotion(context)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) => SlmSweepMask(
        t: Curves.easeInOutSine.transform((_c.value / 0.45).clamp(0.0, 1.0)),
        intensity: widget.intensity,
        child: child!,
      ),
    );
  }
}

/// Counts from the previous value to [value]; Western digits always.
class SlmCountUp extends StatelessWidget {
  final int value;
  final TextStyle style;
  final Duration duration;
  final String Function(int)? format;

  const SlmCountUp({
    super.key,
    required this.value,
    required this.style,
    this.duration = const Duration(milliseconds: 900),
    this.format,
  });

  @override
  Widget build(BuildContext context) {
    final f = format ?? (int v) => v.toString();
    if (slmReduceMotion(context)) return Text(f(value), style: style);
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.toDouble()),
      duration: duration,
      curve: SlmMotion.emphasized,
      builder: (context, v, _) => Text(f(v.round()), style: style),
    );
  }
}

/// Slow breathing halo behind [child], e.g. for the rank-one medallion.
class SlmPulse extends StatefulWidget {
  final Widget child;
  final Color color;
  final double maxBlur;

  const SlmPulse({super.key, required this.child, required this.color, this.maxBlur = 26});

  @override
  State<SlmPulse> createState() => _SlmPulseState();
}

class _SlmPulseState extends State<SlmPulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!slmLoopsOn(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_c.value);
        return DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.25 + 0.25 * t),
                blurRadius: widget.maxBlur * (0.6 + 0.4 * t),
                spreadRadius: 1 + 2 * t,
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }
}

/// Gentle vertical bob for hero elements. Off unless loops are allowed.
class SlmFloat extends StatefulWidget {
  final Widget child;
  final double amplitude;
  final Duration period;

  /// 0–1 offset so neighbours don't bob in step.
  final double phase;

  const SlmFloat({
    super.key,
    required this.child,
    this.amplitude = 3,
    this.period = const Duration(milliseconds: 4200),
    this.phase = 0,
  });

  @override
  State<SlmFloat> createState() => _SlmFloatState();
}

class _SlmFloatState extends State<SlmFloat> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period, value: widget.phase);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (slmLoopsOn(context)) {
      if (!_c.isAnimating) _c.repeat();
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, math.sin(_c.value * 2 * math.pi) * widget.amplitude),
        child: child,
      ),
    );
  }
}
