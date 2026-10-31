import 'package:flutter/material.dart';

import '../motion/slm_motion_scope.dart';
import '../motion/slm_motion_widgets.dart';
import '../theme/slm_theme.dart';
import '../tokens/slm_colors.dart';
import '../tokens/slm_effects.dart';
import '../tokens/slm_layout.dart';
import '../tokens/slm_motion.dart';
import '../tokens/slm_type.dart';

enum SlmButtonVariant { primary, gold, secondary, ghost, danger }

enum SlmButtonSize { small, medium, large }

/// The one button. Long Bangla labels shrink to fit instead of wrapping.
/// Presses sink with real depth and spring back; each tap sends one light
/// sweep across the face.
class SlmButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final SlmButtonVariant variant;
  final SlmButtonSize size;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool expand;
  final bool loading;

  /// Light sweep across gold buttons; ignored for other variants.
  final bool shine;

  const SlmButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = SlmButtonVariant.primary,
    this.size = SlmButtonSize.medium,
    this.icon,
    this.trailingIcon,
    this.expand = false,
    this.loading = false,
    this.shine = false,
  });

  const SlmButton.gold({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = SlmButtonSize.medium,
    this.icon,
    this.trailingIcon,
    this.expand = false,
    this.loading = false,
    this.shine = true,
  }) : variant = SlmButtonVariant.gold;

  const SlmButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = SlmButtonSize.medium,
    this.icon,
    this.trailingIcon,
    this.expand = false,
    this.loading = false,
  })  : variant = SlmButtonVariant.secondary,
        shine = false;

  const SlmButton.ghost({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = SlmButtonSize.medium,
    this.icon,
    this.trailingIcon,
    this.expand = false,
    this.loading = false,
  })  : variant = SlmButtonVariant.ghost,
        shine = false;

  @override
  State<SlmButton> createState() => _SlmButtonState();
}

class _SlmButtonState extends State<SlmButton> with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 650),
  );

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  void _tap() {
    if (!slmReduceMotion(context) && widget.variant != SlmButtonVariant.ghost) {
      _sweep.forward(from: 0);
    }
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final SlmButton(:label, :onPressed, :variant, :size, :icon, :trailingIcon, :expand, :loading, :shine) = widget;
    final s = context.slm;
    final p = s.palette;
    final k = s.layout.scale;
    final height = switch (size) {
          SlmButtonSize.small => 40.0,
          SlmButtonSize.medium => 52.0,
          SlmButtonSize.large => 58.0,
        } *
        k;
    final fontSize = switch (size) {
          SlmButtonSize.small => 13.5,
          SlmButtonSize.medium => 15.5,
          SlmButtonSize.large => 17.0,
        } *
        k;
    final padX = switch (size) {
      SlmButtonSize.small => SlmSpace.sm,
      SlmButtonSize.medium => SlmSpace.lg,
      SlmButtonSize.large => SlmSpace.xl,
    };

    final (Gradient? fill, Color? flat, Color fg, BoxBorder? border, List<BoxShadow>? shadow) = switch (variant) {
      SlmButtonVariant.primary => (SlmGradients.emerald, null, SlmColors.navy950, null, SlmShadows.glow(p.primary, strength: 0.7)),
      SlmButtonVariant.gold => (SlmGradients.gold, null, SlmColors.navy950, null, SlmShadows.glow(p.accent, strength: 0.7)),
      SlmButtonVariant.secondary => (null, p.accent.withValues(alpha: 0.06), p.accent, Border.all(color: p.accent.withValues(alpha: 0.7), width: 1.3), null),
      SlmButtonVariant.ghost => (null, Colors.transparent, p.inkSoft, null, null),
      SlmButtonVariant.danger => (null, p.danger, Colors.white, null, SlmShadows.glow(p.danger, strength: 0.6)),
    };

    final text = SlmType.adapt(
      s.type.label.copyWith(fontSize: fontSize, fontWeight: FontWeight.w700, color: fg),
      label,
    );

    final content = loading
        ? SizedBox(
            width: 20 * k,
            height: 20 * k,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: fg),
          )
        : FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: fontSize + 4, color: fg),
                  SizedBox(width: SlmSpace.xs * k),
                ],
                Text(label, style: text, maxLines: 1),
                if (trailingIcon != null) ...[
                  SizedBox(width: SlmSpace.xs * k),
                  Icon(trailingIcon, size: fontSize + 4, color: fg),
                ],
              ],
            ),
          );

    final enabled = onPressed != null && !loading;
    final sweepColor = variant == SlmButtonVariant.primary ? SlmColors.gold100 : Colors.white;

    Widget face(double press) {
      final depth = press.clamp(0.0, 1.0);
      return AnimatedContainer(
        duration: SlmMotion.fast,
        height: height,
        width: expand ? double.infinity : null,
        constraints: BoxConstraints(minWidth: height),
        padding: EdgeInsets.symmetric(horizontal: padX * k),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: fill,
          color: flat,
          borderRadius: SlmRadius.pillAll,
          border: border,
          boxShadow: onPressed == null || shadow == null
              ? null
              : [
                  for (final b in shadow)
                    b.copyWith(
                      blurRadius: b.blurRadius * (1 - 0.55 * depth),
                      offset: b.offset * (1 - 0.7 * depth),
                    ),
                ],
        ),
        foregroundDecoration: depth > 0 && fill != null
            ? BoxDecoration(
                borderRadius: SlmRadius.pillAll,
                color: Colors.black.withValues(alpha: 0.1 * depth),
              )
            : null,
        child: content,
      );
    }

    Widget body = SlmTactile(
      onTap: enabled ? _tap : null,
      semanticLabel: label,
      builder: (context, press, _) => Transform.translate(
        offset: Offset(0, 2.2 * press),
        child: Transform.scale(
          scale: 1 - 0.022 * press,
          child: AnimatedBuilder(
            animation: _sweep,
            builder: (context, child) => SlmSweepMask(
              t: _sweep.isAnimating ? Curves.easeInOutSine.transform(_sweep.value) : 0,
              color: sweepColor,
              intensity: 0.9,
              child: child!,
            ),
            child: face(press),
          ),
        ),
      ),
    );

    if (variant == SlmButtonVariant.gold && shine) {
      body = SlmShimmer(intensity: 0.8, child: body);
    }

    return AnimatedOpacity(
      opacity: onPressed == null ? 0.45 : 1,
      duration: SlmMotion.fast,
      child: body,
    );
  }
}

enum SlmIconButtonVariant { glass, gold, primary }

/// Round icon button (back, next, close, actions). Always 48 px or more.
class SlmIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;
  final SlmIconButtonVariant variant;
  final double size;

  const SlmIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.variant = SlmIconButtonVariant.glass,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.slm.palette;
    final d = size < slmTapTarget ? slmTapTarget : size;
    final (Gradient? fill, Color? flat, Color fg, BoxBorder? border) = switch (variant) {
      SlmIconButtonVariant.glass => (
          null,
          p.surfaceRaised.withValues(alpha: p.isNight ? 0.72 : 0.92),
          p.accent,
          Border.all(color: p.line, width: 1.2),
        ),
      SlmIconButtonVariant.gold => (SlmGradients.gold, null, SlmColors.navy950, null),
      SlmIconButtonVariant.primary => (SlmGradients.emerald, null, SlmColors.navy950, null),
    };

    return Tooltip(
      message: tooltip,
      child: SlmPressable(
        onTap: onPressed,
        pressedScale: 0.92,
        semanticLabel: tooltip,
        child: Container(
          width: d,
          height: d,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: fill,
            color: flat,
            border: border,
            boxShadow: SlmShadows.soft(p),
          ),
          child: Icon(icon, size: d * 0.46, color: fg),
        ),
      ),
    );
  }
}
