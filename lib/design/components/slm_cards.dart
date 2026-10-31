import 'package:flutter/material.dart';

import '../motion/slm_motion_widgets.dart';
import '../theme/slm_theme.dart';
import '../tokens/slm_effects.dart';
import '../tokens/slm_layout.dart';

enum SlmCardVariant {
  /// Default container.
  surface,

  /// Lifted, with a deeper shadow.
  raised,

  /// Gold hairline frame for prestige content.
  gold,

  /// Navy-to-emerald gradient with a gold frame; one per screen at most.
  hero,

  /// Recessed well for grouped rows.
  sunken,
}

class SlmCard extends StatelessWidget {
  final Widget child;
  final SlmCardVariant variant;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double radius;

  const SlmCard({
    super.key,
    required this.child,
    this.variant = SlmCardVariant.surface,
    this.padding,
    this.onTap,
    this.radius = SlmRadius.lg,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.slm.palette;
    final r = BorderRadius.circular(radius);
    final pad = padding ?? const EdgeInsets.all(SlmSpace.md);
    final framed = variant == SlmCardVariant.gold || variant == SlmCardVariant.hero;

    final fill = switch (variant) {
      SlmCardVariant.hero => BoxDecoration(gradient: SlmGradients.navyHero, borderRadius: r),
      SlmCardVariant.sunken => BoxDecoration(
          color: p.surfaceSunken,
          borderRadius: r,
          border: Border.all(color: p.line.withValues(alpha: 0.5)),
        ),
      _ when p.isNight => BoxDecoration(
          gradient: SlmGradients.navyCard,
          borderRadius: r,
          border: framed ? null : Border.all(color: p.line.withValues(alpha: 0.6)),
        ),
      _ => BoxDecoration(
          color: p.surface,
          borderRadius: r,
          border: framed ? null : Border.all(color: p.line.withValues(alpha: 0.6)),
        ),
    };

    Widget card = DecoratedBox(
      decoration: fill,
      child: Padding(padding: pad, child: child),
    );

    if (framed) {
      card = DecoratedBox(
        decoration: BoxDecoration(gradient: SlmGradients.goldEdge, borderRadius: r),
        child: Padding(
          padding: const EdgeInsets.all(1.2),
          child: ClipRRect(borderRadius: BorderRadius.circular(radius - 1.2), child: card),
        ),
      );
    }

    final shadow = switch (variant) {
      SlmCardVariant.raised || SlmCardVariant.hero => SlmShadows.raised(p),
      SlmCardVariant.sunken => null,
      _ => SlmShadows.soft(p),
    };

    card = DecoratedBox(
      decoration: BoxDecoration(borderRadius: r, boxShadow: shadow),
      child: card,
    );

    if (onTap == null) return card;
    return SlmPressable(onTap: onTap, pressedScale: 0.985, child: card);
  }
}
