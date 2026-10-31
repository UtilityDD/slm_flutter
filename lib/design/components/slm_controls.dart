import 'package:flutter/material.dart';

import '../motion/slm_motion_widgets.dart';
import '../theme/slm_theme.dart';
import '../tokens/slm_colors.dart';
import '../tokens/slm_effects.dart';
import '../tokens/slm_layout.dart';
import '../tokens/slm_motion.dart';
import '../tokens/slm_type.dart';
import 'slm_tone.dart';

/// Pill tab switcher with a sliding gold thumb.
class SlmSegmented extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;

  const SlmSegmented({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.slm;
    final p = s.palette;
    final h = 44 * s.layout.scale;
    final n = labels.length;
    return Container(
      height: h,
      padding: const EdgeInsets.all(SlmSpace.xxs),
      decoration: BoxDecoration(
        color: p.surfaceSunken,
        borderRadius: SlmRadius.pillAll,
        border: Border.all(color: p.line),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth / n;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: SlmMotion.base,
                curve: SlmMotion.emphasized,
                left: w * selected,
                top: 0,
                bottom: 0,
                width: w,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: SlmGradients.gold,
                    borderRadius: SlmRadius.pillAll,
                    boxShadow: SlmShadows.glow(p.accent, strength: 0.45),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < n; i++)
                    Expanded(
                      child: SlmPressable(
                        onTap: i == selected ? null : () => onChanged(i),
                        pressedScale: 0.95,
                        semanticLabel: labels[i],
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: SlmSpace.xxs),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: AnimatedDefaultTextStyle(
                                duration: SlmMotion.fast,
                                style: SlmType.adapt(
                                  s.type.label.copyWith(
                                    color: i == selected ? SlmColors.navy950 : p.inkSoft,
                                    fontWeight: i == selected ? FontWeight.w700 : FontWeight.w600,
                                    height: 1.2,
                                  ),
                                  labels[i],
                                ),
                                child: Text(labels[i], maxLines: 1),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Compact tag. Tappable when [onTap] is set; filled when [selected].
class SlmChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final SlmTone tone;
  final bool selected;
  final VoidCallback? onTap;

  const SlmChip({
    super.key,
    required this.label,
    this.icon,
    this.tone = SlmTone.gold,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.slm;
    final p = s.palette;
    final c = tone.color(p);
    final fg = selected ? tone.onSolid(p) : c;
    final chip = AnimatedContainer(
      duration: SlmMotion.fast,
      padding: const EdgeInsets.symmetric(horizontal: SlmSpace.sm, vertical: 6),
      decoration: BoxDecoration(
        gradient: selected ? tone.gradient(p) : null,
        color: selected ? null : c.withValues(alpha: 0.12),
        borderRadius: SlmRadius.pillAll,
        border: Border.all(color: c.withValues(alpha: selected ? 0 : 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15 * s.layout.scale, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            maxLines: 1,
            style: SlmType.adapt(s.type.caption.copyWith(color: fg, fontWeight: FontWeight.w700), label),
          ),
        ],
      ),
    );
    if (onTap == null) return chip;
    return SlmPressable(onTap: onTap, semanticLabel: label, child: chip);
  }
}

/// Rounded progress track that animates to [value] (0–1).
class SlmProgressBar extends StatelessWidget {
  final double value;
  final SlmTone tone;
  final double height;

  const SlmProgressBar({
    super.key,
    required this.value,
    this.tone = SlmTone.emerald,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.slm.palette;
    final v = value.clamp(0.0, 1.0);
    return Semantics(
      value: '${(v * 100).round()}%',
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: p.surfaceSunken,
          borderRadius: SlmRadius.pillAll,
          border: Border.all(color: p.line.withValues(alpha: 0.5)),
        ),
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: v),
          duration: SlmMotion.page,
          curve: SlmMotion.emphasized,
          builder: (context, t, _) => FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: t,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: tone.gradient(p),
                borderRadius: SlmRadius.pillAll,
                boxShadow: SlmShadows.glow(tone.color(p), strength: 0.35),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
