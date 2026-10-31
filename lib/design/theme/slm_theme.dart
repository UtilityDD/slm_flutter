import 'package:flutter/material.dart';

import '../tokens/slm_layout.dart';
import '../tokens/slm_palette.dart';
import '../tokens/slm_type.dart';

/// Everything a component needs, resolved for the current context.
@immutable
class SlmTokens {
  final SlmPalette palette;
  final SlmType type;
  final SlmLayout layout;

  const SlmTokens(this.palette, this.type, this.layout);
}

extension SlmContext on BuildContext {
  /// Design tokens for this subtree. Falls back to the night mood when the
  /// surrounding theme has no [SlmPalette], so components work anywhere.
  SlmTokens get slm {
    final p = Theme.of(this).extension<SlmPalette>() ?? SlmPalette.night;
    final layout = SlmLayout.of(this);
    return SlmTokens(p, SlmType.of(p, scale: layout.scale), layout);
  }
}

abstract final class SlmTheme {
  static final ThemeData _night = _build(SlmPalette.night);
  static final ThemeData _day = _build(SlmPalette.day);

  static ThemeData night() => _night;
  static ThemeData day() => _day;

  static ThemeData _build(SlmPalette p) {
    final t = SlmType.of(p);
    final base = ThemeData(
      useMaterial3: true,
      brightness: p.brightness,
      fontFamily: slmFont,
    );
    final scheme = ColorScheme(
      brightness: p.brightness,
      primary: p.primary,
      onPrimary: p.onPrimary,
      secondary: p.accent,
      onSecondary: p.onAccent,
      tertiary: p.info,
      onTertiary: p.onPrimary,
      error: p.danger,
      onError: Colors.white,
      surface: p.surface,
      onSurface: p.ink,
      onSurfaceVariant: p.inkSoft,
      outline: p.line,
      outlineVariant: p.line,
      surfaceContainerHighest: p.surfaceRaised,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: p.canvas,
      canvasColor: p.canvas,
      dividerColor: p.line,
      splashFactory: InkSparkle.splashFactory,
      textTheme: base.textTheme.copyWith(
        displaySmall: t.display,
        headlineMedium: t.headline,
        titleLarge: t.title,
        titleMedium: t.titleSm,
        bodyLarge: t.body,
        bodyMedium: t.body,
        bodySmall: t.bodySm,
        labelLarge: t.label,
        labelSmall: t.caption,
      ),
      iconTheme: IconThemeData(color: p.inkSoft, size: 22),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.accent),
      dividerTheme: DividerThemeData(color: p.line, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.surfaceRaised,
        contentTextStyle: t.body.copyWith(color: p.ink),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: SlmRadius.mdAll),
      ),
      extensions: [p],
    );
  }
}
