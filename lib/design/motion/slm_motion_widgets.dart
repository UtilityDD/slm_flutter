import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
  late final CurvedAnimation _t = CurvedAnimation(parent: _c, curve: SlmMotion.emphasized);
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
    _t.dispose();
    _c.dispose();
    super.dispose();
  }

  // Fade and rise run in the render tree: no widget rebuilds per frame.
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _t,
      child: _SlmRise(progress: _t, rise: widget.rise, child: widget.child),
    );
  }
}

/// Paints [child] `rise * (1 - progress)` px lower, repainting (not
/// rebuilding) as [progress] moves. Same result as Transform.translate.
class _SlmRise extends SingleChildRenderObjectWidget {
  final Animation<double> progress;
  final double rise;

  const _SlmRise({required this.progress, required this.rise, super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderSlmRise(progress, rise);

  @override
  void updateRenderObject(BuildContext context, _RenderSlmRise renderObject) {
    renderObject
      ..progress = progress
      ..rise = rise;
  }
}

class _RenderSlmRise extends RenderProxyBox {
  _RenderSlmRise(this._progress, this._rise);

  Animation<double> _progress;
  set progress(Animation<double> v) {
    if (identical(v, _progress)) return;
    if (attached) _progress.removeListener(markNeedsPaint);
    _progress = v;
    if (attached) _progress.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  double _rise;
  set rise(double v) {
    if (v == _rise) return;
    _rise = v;
    markNeedsPaint();
  }

  Offset get _shift => Offset(0, _rise * (1 - _progress.value));

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _progress.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _progress.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return result.addWithPaintOffset(
      offset: _shift,
      position: position,
      hitTest: (result, p) => super.hitTestChildren(result, position: p),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final c = child;
    if (c != null) context.paintChild(c, offset + _shift);
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final s = _shift;
    transform.translateByDouble(s.dx, s.dy, 0, 1);
  }
}

/// A shader mask whose element tree never changes shape. [shader] is asked
/// for a shader on every paint; returning null paints the child plainly (or
/// not at all with [hideWhenIdle]) without a compositing layer. [repaint]
/// repaints without rebuilding, so a loop can drive the light directly.
///
/// Prefer this to switching between `child` and `ShaderMask(child)`: that
/// swap re-inflates the subtree and drops any gesture in progress.
class SlmLiveShaderMask extends SingleChildRenderObjectWidget {
  final Shader? Function(Rect bounds) shader;
  final Listenable? repaint;
  final BlendMode blendMode;
  final bool hideWhenIdle;

  const SlmLiveShaderMask({
    super.key,
    required this.shader,
    this.repaint,
    this.blendMode = BlendMode.modulate,
    this.hideWhenIdle = false,
    super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderSlmLiveShaderMask(shader, repaint, blendMode, hideWhenIdle);

  @override
  void updateRenderObject(BuildContext context, RenderSlmLiveShaderMask renderObject) {
    renderObject
      ..shader = shader
      ..repaint = repaint
      ..blendMode = blendMode
      ..hideWhenIdle = hideWhenIdle;
  }
}

class RenderSlmLiveShaderMask extends RenderProxyBox {
  RenderSlmLiveShaderMask(this._shader, this._repaint, this._blendMode, this._hideWhenIdle);

  Shader? Function(Rect bounds) _shader;
  set shader(Shader? Function(Rect bounds) v) {
    if (identical(v, _shader)) return;
    _shader = v;
    markNeedsPaint();
  }

  Listenable? _repaint;
  set repaint(Listenable? v) {
    if (identical(v, _repaint)) return;
    if (attached) _repaint?.removeListener(markNeedsPaint);
    _repaint = v;
    if (attached) _repaint?.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  BlendMode _blendMode;
  set blendMode(BlendMode v) {
    if (v == _blendMode) return;
    _blendMode = v;
    markNeedsPaint();
  }

  bool _hideWhenIdle;
  set hideWhenIdle(bool v) {
    if (v == _hideWhenIdle) return;
    _hideWhenIdle = v;
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _repaint?.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _repaint?.removeListener(markNeedsPaint);
    super.detach();
  }

  @override
  bool get alwaysNeedsCompositing => child != null;

  @override
  ShaderMaskLayer? get layer => super.layer as ShaderMaskLayer?;

  @override
  void paint(PaintingContext context, Offset offset) {
    final c = child;
    if (c == null) {
      layer = null;
      return;
    }
    final shader = _shader(Offset.zero & size);
    if (shader == null) {
      layer = null;
      if (!_hideWhenIdle) context.paintChild(c, offset);
      return;
    }
    layer ??= ShaderMaskLayer();
    layer!
      ..shader = shader
      ..maskRect = offset & size
      ..blendMode = _blendMode;
    context.pushLayer(layer!, super.paint, offset);
  }
}

/// Paints a soft diagonal band of light across [child] at sweep position
/// [t] (0 = off the left edge, 1 = off the right edge).
///
/// The element tree is the same for every [t], so the subtree (and any tap
/// on it) survives the band coming and going.
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

  /// The band shader for sweep position [t] over [r], or null when the band
  /// is off the child (t <= 0 or t >= 1).
  static Shader? shaderFor(Rect r, double t, {double intensity = 1, Color color = Colors.white}) {
    if (t <= 0 || t >= 1) return null;
    final a = (0.55 * intensity).clamp(0.0, 1.0);
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
  }

  @override
  Widget build(BuildContext context) {
    return SlmLiveShaderMask(
      blendMode: BlendMode.srcATop,
      shader: (r) => shaderFor(r, t, intensity: intensity, color: color),
      child: child,
    );
  }
}

/// A soft band of light that sweeps across [child] every [period].
/// The band covers the first 45% of a loop; the rest of the loop is an idle
/// gap that schedules no frames.
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
  static const _band = 0.45;

  late final AnimationController _c = AnimationController(vsync: this, duration: widget.period * _band)
    ..addStatusListener(_onStatus);
  Timer? _gap;
  bool _run = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(covariant SlmShimmer old) {
    super.didUpdateWidget(old);
    if (old.period != widget.period) _c.duration = widget.period * _band;
    _sync();
  }

  void _sync() {
    final run = widget.enabled && slmLoopsOn(context);
    if (run == _run) return;
    _run = run;
    if (run) {
      _c.forward(from: 0);
    } else {
      _gap?.cancel();
      _c.stop();
      // A paused scope freezes the band; remove-animations or disabling clears it.
      if (!widget.enabled || slmReduceMotion(context)) _c.value = 0;
    }
  }

  void _onStatus(AnimationStatus s) {
    if (s != AnimationStatus.completed || !_run) return;
    _gap?.cancel();
    _gap = Timer(widget.period - widget.period * _band, () {
      if (mounted && _run) _c.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _gap?.cancel();
    _c.dispose();
    super.dispose();
  }

  Shader? _shader(Rect r) {
    final v = _c.value;
    if (v <= 0 || v >= 1) return null;
    return SlmSweepMask.shaderFor(r, Curves.easeInOutSine.transform(v), intensity: widget.intensity);
  }

  @override
  Widget build(BuildContext context) {
    return SlmLiveShaderMask(
      blendMode: BlendMode.srcATop,
      repaint: _c,
      shader: _shader,
      child: widget.child,
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
    slmSyncLoop(context, _c, reverse: true);
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
    slmSyncLoop(context, _c);
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
