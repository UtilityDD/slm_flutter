import 'package:flutter/material.dart';

import '../theme/slm_theme.dart';
import '../tokens/slm_colors.dart';
import '../tokens/slm_effects.dart';
import '../tokens/slm_layout.dart';
import 'slm_buttons.dart';
import 'slm_icons.dart';
import 'slm_text.dart';
import 'slm_tone.dart';

/// Page backdrop: palette canvas with two faint brand glows near the top.
/// Centres content and caps its width on tablets.
class SlmBackground extends StatelessWidget {
  final Widget child;
  final bool constrain;

  const SlmBackground({super.key, required this.child, this.constrain = true});

  @override
  Widget build(BuildContext context) {
    final s = context.slm;
    final p = s.palette;
    final glow = p.isNight ? 1.0 : 0.5;
    return DecoratedBox(
      decoration: BoxDecoration(gradient: SlmGradients.canvas(p)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -140,
            left: -120,
            width: 360,
            height: 360,
            child: _Glow(color: SlmColors.emerald500.withValues(alpha: 0.16 * glow)),
          ),
          Positioned(
            top: -90,
            right: -140,
            width: 340,
            height: 340,
            child: _Glow(color: SlmColors.gold400.withValues(alpha: 0.13 * glow)),
          ),
          if (constrain)
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: s.layout.maxContent),
                child: child,
              ),
            )
          else
            child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final Color color;
  const _Glow({required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

/// Screen header: optional back button, icon, title + subtitle, actions.
class SlmTopBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onBack;
  final String backLabel;
  final List<Widget> actions;

  const SlmTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.onBack,
    this.backLabel = 'Back',
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final g = context.slm.layout.gutter;
    return Padding(
      padding: EdgeInsets.fromLTRB(g, SlmSpace.sm, g, SlmSpace.xs),
      child: Row(
        children: [
          if (onBack != null) ...[
            SlmIconButton(icon: Icons.arrow_back_rounded, onPressed: onBack, tooltip: backLabel, size: 44),
            const SizedBox(width: SlmSpace.sm),
          ] else if (icon != null) ...[
            SlmIconBadge(icon: icon!, tone: SlmTone.gold, style: SlmIconStyle.medal, size: 44),
            const SizedBox(width: SlmSpace.sm),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SlmText(title, role: SlmTextRole.headline, maxLines: 1),
                if (subtitle != null)
                  SlmText(subtitle!, role: SlmTextRole.caption, maxLines: 1),
              ],
            ),
          ),
          for (final a in actions) ...[const SizedBox(width: SlmSpace.xs), a],
        ],
      ),
    );
  }
}

/// Section title with an optional small overline and trailing action.
class SlmSectionHeader extends StatelessWidget {
  final String title;
  final String? overline;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SlmSectionHeader({
    super.key,
    required this.title,
    this.overline,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SlmSpace.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (overline != null) SlmText(overline!, role: SlmTextRole.overline),
                SlmText(title, role: SlmTextRole.title, maxLines: 2),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null)
            SlmButton.ghost(label: actionLabel!, onPressed: onAction, size: SlmButtonSize.small),
        ],
      ),
    );
  }
}

/// Centered placeholder for empty, error and coming-soon states.
class SlmEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  const SlmEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: SlmSpace.xxl, vertical: SlmSpace.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SlmIconBadge(icon: icon, style: SlmIconStyle.medal, size: 68),
          const SizedBox(height: SlmSpace.md),
          SlmText(title, role: SlmTextRole.title, align: TextAlign.center),
          if (message != null) ...[
            const SizedBox(height: SlmSpace.xs),
            SlmText(message!, role: SlmTextRole.bodySm, align: TextAlign.center),
          ],
          if (action != null) ...[
            const SizedBox(height: SlmSpace.lg),
            action!,
          ],
        ],
      ),
    );
  }
}
