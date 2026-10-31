import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../components/slm_icons.dart';
import '../components/slm_text.dart';
import '../theme/slm_theme.dart';
import '../tokens/slm_colors.dart';
import '../tokens/slm_effects.dart';
import '../tokens/slm_layout.dart';
import '../tokens/slm_type.dart';
import 'slm_motion_scope.dart';
import 'slm_motion_widgets.dart';
import 'slm_safety_shield.dart';
import 'slm_sparks.dart';

double _seg(double t, double a, double b, [Curve curve = Curves.linear]) =>
    curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

// ---------------------------------------------------------------------------
// XP toast
// ---------------------------------------------------------------------------

/// Floats a "+N XP" chip up from [anchor] (or the lower middle of the screen)
/// with a small gold burst. Display only: it never changes any score.
void showSlmXpToast(BuildContext context, {required int amount, String unit = 'XP', BuildContext? anchor}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;
  Offset? at;
  final box = anchor?.findRenderObject();
  if (box is RenderBox && box.hasSize) {
    at = box.localToGlobal(box.size.center(Offset.zero));
  }
  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _XpToast(
      label: '+$amount $unit',
      at: at,
      onDone: () => entry.remove(),
    ),
  );
  overlay.insert(entry);
  HapticFeedback.lightImpact();
}

class _XpToast extends StatefulWidget {
  final String label;
  final Offset? at;
  final VoidCallback onDone;

  const _XpToast({required this.label, required this.at, required this.onDone});

  @override
  State<_XpToast> createState() => _XpToastState();
}

class _XpToastState extends State<_XpToast> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.isAnimating || _c.isCompleted) return;
    if (slmReduceMotion(context)) _c.duration = const Duration(milliseconds: 1200);
    _c.forward().whenCompleteOrCancel(() {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.slm;
    final size = MediaQuery.sizeOf(context);
    final at = widget.at ?? Offset(size.width / 2, size.height * 0.62);
    final still = slmReduceMotion(context);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          final rise = still ? 0.0 : -64 * _seg(t, 0, 0.75, Curves.easeOutCubic);
          final pop = still ? 1.0 : 0.6 + 0.4 * _seg(t, 0, 0.22, Curves.easeOutBack);
          final alpha = _seg(t, 0, 0.12) * (1 - _seg(t, 0.72, 1));
          return Stack(
            children: [
              Positioned(
                left: at.dx - 70,
                top: at.dy - 70,
                width: 140,
                height: 140,
                child: const SlmSparkBurst(playOnMount: true, radius: 70, count: 12),
              ),
              Positioned(
                left: 0,
                right: 0,
                top: at.dy - 22 + rise,
                child: Center(
                  child: Opacity(
                    opacity: alpha,
                    child: Transform.scale(
                      scale: pop,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: SlmSpace.md, vertical: SlmSpace.xs),
                        decoration: BoxDecoration(
                          gradient: SlmGradients.gold,
                          borderRadius: SlmRadius.pillAll,
                          boxShadow: SlmShadows.glow(SlmColors.gold400, strength: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt_rounded, size: 18, color: SlmColors.navy950),
                            const SizedBox(width: 4),
                            Text(
                              widget.label,
                              style: s.type.number.copyWith(fontSize: 16, color: SlmColors.navy950),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared celebration stage
// ---------------------------------------------------------------------------

/// Soft light rays turning slowly behind a celebration.
class SlmRays extends StatefulWidget {
  final double size;
  final Color color;
  final double opacity;

  const SlmRays({super.key, required this.size, this.color = SlmColors.gold300, this.opacity = 0.14});

  @override
  State<SlmRays> createState() => _SlmRaysState();
}

class _SlmRaysState extends State<SlmRays> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 18));

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
    final c = widget.color;
    final a = widget.opacity;
    return IgnorePointer(
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: widget.size,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) => Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  transform: GradientRotation(_c.value * 2 * math.pi),
                  colors: [
                    for (var i = 0; i < 10; i++) ...[c.withValues(alpha: 0), c.withValues(alpha: a)],
                    c.withValues(alpha: 0),
                  ],
                ),
              ),
              foregroundDecoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [SlmColors.navy950.withValues(alpha: 0), SlmColors.navy950],
                  stops: const [0.25, 1],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> _showStage(
  BuildContext context, {
  required Widget child,
  Duration? dismissAfter,
  String barrierLabel = 'Close',
}) {
  Timer? timer;
  final nav = Navigator.of(context, rootNavigator: true);
  final route = showGeneralDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    barrierLabel: barrierLabel,
    barrierColor: SlmColors.navy950.withValues(alpha: 0.78),
    transitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (ctx, _, _) => Theme(
      data: SlmTheme.night(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(ctx).maybePop(),
        child: Center(child: child),
      ),
    ),
    transitionBuilder: (ctx, a, _, child) => FadeTransition(opacity: a, child: child),
  );
  if (dismissAfter != null) {
    timer = Timer(dismissAfter, () {
      if (nav.mounted) nav.maybePop();
    });
  }
  return route.whenComplete(() => timer?.cancel());
}

// ---------------------------------------------------------------------------
// Badge unlock
// ---------------------------------------------------------------------------

/// Badge entrance: scale + turn into place, gold light pass, emerald/gold
/// halo, a small spark burst, then the achievement name.
class SlmBadgeUnlock extends StatefulWidget {
  final IconData icon;
  final String title;
  final String caption;
  final double size;

  const SlmBadgeUnlock({
    super.key,
    required this.icon,
    required this.title,
    required this.caption,
    this.size = 128,
  });

  @override
  State<SlmBadgeUnlock> createState() => _SlmBadgeUnlockState();
}

class _SlmBadgeUnlockState extends State<SlmBadgeUnlock> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700));
  int _burst = 0;

  static final _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.2, end: 1.12).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 55),
    TweenSequenceItem(tween: Tween(begin: 1.12, end: 1.0).chain(CurveTween(curve: Curves.easeInOutSine)), weight: 45),
  ]);
  static final _turn = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: -0.55, end: 0.07).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 60),
    TweenSequenceItem(tween: Tween(begin: 0.07, end: 0.0).chain(CurveTween(curve: Curves.easeInOutSine)), weight: 40),
  ]);

  @override
  void initState() {
    super.initState();
    _c.addListener(() {
      if (_burst == 0 && _c.value > 0.32) setState(() => _burst = 1);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.isAnimating || _c.isCompleted) return;
    if (slmReduceMotion(context)) {
      _c.value = 1;
    } else {
      _c.forward();
      HapticFeedback.mediumImpact();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.size * context.slm.layout.scale;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox.square(
          dimension: d * 2,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _c,
                builder: (context, child) => Opacity(opacity: _seg(_c.value, 0.15, 0.6), child: child),
                child: SlmRays(size: d * 2),
              ),
              AnimatedBuilder(
                animation: _c,
                builder: (context, _) {
                  final glow = _seg(_c.value, 0.25, 0.6, Curves.easeOut);
                  return Container(
                    width: d * 1.25,
                    height: d * 1.25,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        SlmColors.emerald400.withValues(alpha: 0.28 * glow),
                        SlmColors.gold300.withValues(alpha: 0.12 * glow),
                        SlmColors.gold300.withValues(alpha: 0),
                      ], stops: const [0, 0.55, 1]),
                    ),
                  );
                },
              ),
              SlmSparkBurst(trigger: _burst == 0 ? null : _burst, radius: d * 0.95, count: 18),
              AnimatedBuilder(
                animation: _c,
                builder: (context, child) {
                  final t = _c.value;
                  return Opacity(
                    opacity: _seg(t, 0, 0.18),
                    child: Transform.rotate(
                      angle: _turn.transform(t),
                      child: Transform.scale(
                        scale: _scale.transform(t),
                        child: SlmSweepMask(t: _seg(t, 0.42, 0.85, Curves.easeInOutSine), child: child!),
                      ),
                    ),
                  );
                },
                child: SlmIconBadge(icon: widget.icon, style: SlmIconStyle.medal, size: widget.size),
              ),
            ],
          ),
        ),
        AnimatedBuilder(
          animation: _c,
          builder: (context, child) {
            final t = _seg(_c.value, 0.5, 0.85, Curves.easeOutCubic);
            return Opacity(opacity: t, child: Transform.translate(offset: Offset(0, 12 * (1 - t)), child: child));
          },
          child: Column(
            children: [
              SlmText(widget.caption, role: SlmTextRole.overline, align: TextAlign.center),
              const SizedBox(height: SlmSpace.xxs),
              SlmText(widget.title, role: SlmTextRole.headline, align: TextAlign.center),
            ],
          ),
        ),
      ],
    );
  }
}

/// Full-screen badge celebration. Tap anywhere to close.
Future<void> showSlmBadgeUnlock(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String caption,
  Duration? dismissAfter = const Duration(milliseconds: 3600),
}) {
  return _showStage(
    context,
    dismissAfter: dismissAfter,
    child: SlmBadgeUnlock(icon: icon, title: title, caption: caption),
  );
}

// ---------------------------------------------------------------------------
// Level up
// ---------------------------------------------------------------------------

/// Level-up moment: the shield emblem arrives, the level number rolls from
/// [fromLevel] to [toLevel], then the title and reward chip appear.
class SlmLevelUp extends StatefulWidget {
  final int fromLevel;
  final int toLevel;
  final String heading;
  final String title;
  final String? reward;

  const SlmLevelUp({
    super.key,
    required this.fromLevel,
    required this.toLevel,
    required this.heading,
    required this.title,
    this.reward,
  });

  @override
  State<SlmLevelUp> createState() => _SlmLevelUpState();
}

class _SlmLevelUpState extends State<SlmLevelUp> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));
  int _burst = 0;

  @override
  void initState() {
    super.initState();
    _c.addListener(() {
      if (_burst == 0 && _c.value > 0.5) setState(() => _burst = 1);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.isAnimating || _c.isCompleted) return;
    if (slmReduceMotion(context)) {
      _c.value = 1;
    } else {
      _c.forward();
      HapticFeedback.heavyImpact();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.slm;
    final k = s.layout.scale;
    final shield = 200 * k;
    final numStyle = s.type.number.copyWith(
      fontSize: 64 * k,
      color: s.palette.accent,
      shadows: [Shadow(color: SlmColors.gold400.withValues(alpha: 0.6), blurRadius: 18)],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _c,
          builder: (context, child) {
            final t = _seg(_c.value, 0, 0.2, Curves.easeOut);
            return Opacity(opacity: t, child: Transform.translate(offset: Offset(0, -10 * (1 - t)), child: child));
          },
          child: SlmText(widget.heading, role: SlmTextRole.overline, align: TextAlign.center),
        ),
        const SizedBox(height: SlmSpace.xs),
        SizedBox(
          width: shield * 1.5,
          height: shield,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              AnimatedBuilder(
                animation: _c,
                builder: (context, child) => Opacity(opacity: _seg(_c.value, 0.1, 0.5), child: child),
                child: SlmRays(size: shield * 1.5, opacity: 0.12),
              ),
              AnimatedSafetyShield(size: shield, intensity: 1.1),
              SlmSparkBurst(trigger: _burst == 0 ? null : _burst, radius: shield * 0.55, count: 18),
            ],
          ),
        ),
        SizedBox(
          height: 80 * k,
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final out = _seg(_c.value, 0.3, 0.5, Curves.easeInCubic);
              final inn = _seg(_c.value, 0.45, 0.72, Curves.easeOutBack);
              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  if (out < 1)
                    Opacity(
                      opacity: 1 - out,
                      child: Transform.translate(
                        offset: Offset(0, -30 * out),
                        child: Text('${widget.fromLevel}', style: numStyle.copyWith(color: s.palette.inkMuted)),
                      ),
                    ),
                  if (inn > 0)
                    Opacity(
                      opacity: inn.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, 30 * (1 - inn)),
                        child: Transform.scale(scale: 0.8 + 0.2 * inn, child: Text('${widget.toLevel}', style: numStyle)),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        AnimatedBuilder(
          animation: _c,
          builder: (context, child) {
            final t = _seg(_c.value, 0.66, 0.92, Curves.easeOutCubic);
            return Opacity(opacity: t, child: Transform.translate(offset: Offset(0, 14 * (1 - t)), child: child));
          },
          child: Column(
            children: [
              SlmText(widget.title, role: SlmTextRole.headline, align: TextAlign.center),
              if (widget.reward != null) ...[
                const SizedBox(height: SlmSpace.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: SlmSpace.md, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: SlmGradients.gold,
                    borderRadius: SlmRadius.pillAll,
                    boxShadow: SlmShadows.glow(SlmColors.gold400, strength: 0.6),
                  ),
                  child: Text(
                    widget.reward!,
                    style: SlmType.adapt(
                      s.type.label.copyWith(color: SlmColors.navy950, fontWeight: FontWeight.w800),
                      widget.reward!,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Full-screen level-up celebration. Tap anywhere to close.
Future<void> showSlmLevelUp(
  BuildContext context, {
  required int fromLevel,
  required int toLevel,
  required String heading,
  required String title,
  String? reward,
  Duration? dismissAfter = const Duration(milliseconds: 4200),
}) {
  return _showStage(
    context,
    dismissAfter: dismissAfter,
    child: SlmLevelUp(
      fromLevel: fromLevel,
      toLevel: toLevel,
      heading: heading,
      title: title,
      reward: reward,
    ),
  );
}
