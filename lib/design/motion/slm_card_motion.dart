import 'package:flutter/material.dart';

import '../components/slm_cards.dart';
import '../theme/slm_theme.dart';
import '../tokens/slm_layout.dart';
import '../tokens/slm_motion.dart';
import 'slm_motion_widgets.dart';

/// [SlmCard] with motion: staggered entrance, lift and gold edge light while
/// pressed, and an optional gentle float. Static unless touched (or [float]).
class SlmMotionCard extends StatelessWidget {
  final Widget child;
  final SlmCardVariant variant;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double radius;

  /// Position in a list, for the entrance stagger. Null skips the entrance.
  final int? index;

  /// Slow bob; keep to one hero card per screen.
  final bool float;

  const SlmMotionCard({
    super.key,
    required this.child,
    this.variant = SlmCardVariant.surface,
    this.padding,
    this.onTap,
    this.radius = SlmRadius.lg,
    this.index,
    this.float = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = context.slm.palette.accent;
    final card = SlmCard(variant: variant, padding: padding, radius: radius, child: child);

    Widget body = onTap == null
        ? card
        : SlmTactile(
            onTap: onTap,
            child: card,
            builder: (context, press, child) {
              final p = press.clamp(0.0, 1.0);
              return Transform.translate(
                offset: Offset(0, -3 * press),
                child: Transform.scale(
                  scale: 1 - 0.012 * press,
                  child: DecoratedBox(
                    position: DecorationPosition.foreground,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      border: Border.all(color: accent.withValues(alpha: 0.65 * p), width: 1.4),
                      boxShadow: [
                        BoxShadow(color: accent.withValues(alpha: 0.22 * p), blurRadius: 18 * p, spreadRadius: -2),
                      ],
                    ),
                    child: child,
                  ),
                ),
              );
            },
          );

    if (float) body = SlmFloat(amplitude: 3, phase: ((index ?? 0) * 0.17) % 1, child: body);
    if (index != null) body = SlmReveal(index: index!, child: body);
    return body;
  }
}

/// Cross-fades between children with a short rise, resizing smoothly.
/// Give each child a distinct key.
class SlmContentSwitcher extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const SlmContentSwitcher({super.key, required this.child, this.duration = SlmMotion.base});

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: duration,
      curve: SlmMotion.emphasized,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: duration,
        switchInCurve: SlmMotion.emphasized,
        switchOutCurve: SlmMotion.exit,
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topCenter,
          children: [...previous, ?current],
        ),
        transitionBuilder: (child, a) => FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, 0.04), end: Offset.zero).animate(a),
            child: child,
          ),
        ),
        child: child,
      ),
    );
  }
}
