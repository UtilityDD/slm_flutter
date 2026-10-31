import 'package:flutter/material.dart';

import 'slm_colors.dart';

/// Role-based colours. Components only ever ask for a role (surface, ink,
/// primary…), never a raw hex, so a mood swap restyles everything at once.
@immutable
class SlmPalette extends ThemeExtension<SlmPalette> {
  final Brightness brightness;

  /// Page background, darkest layer.
  final Color canvas;

  /// Default card / sheet fill.
  final Color surface;

  /// Raised card fill (one step lighter than [surface] at night).
  final Color surfaceRaised;

  /// Pressed / selected fill inside surfaces.
  final Color surfaceSunken;

  /// Hairline borders and dividers.
  final Color line;

  final Color ink;
  final Color inkSoft;
  final Color inkMuted;

  /// Emerald — main actions, success, progress.
  final Color primary;
  final Color primaryDeep;
  final Color onPrimary;

  /// Antique gold — prestige, rank, highlights, focus.
  final Color accent;
  final Color accentDeep;
  final Color onAccent;

  final Color danger;
  final Color warning;
  final Color info;
  final Color success;

  const SlmPalette({
    required this.brightness,
    required this.canvas,
    required this.surface,
    required this.surfaceRaised,
    required this.surfaceSunken,
    required this.line,
    required this.ink,
    required this.inkSoft,
    required this.inkMuted,
    required this.primary,
    required this.primaryDeep,
    required this.onPrimary,
    required this.accent,
    required this.accentDeep,
    required this.onAccent,
    required this.danger,
    required this.warning,
    required this.info,
    required this.success,
  });

  bool get isNight => brightness == Brightness.dark;

  /// Signature premium mood: midnight navy canvas, gold and emerald accents.
  static const night = SlmPalette(
    brightness: Brightness.dark,
    canvas: SlmColors.navy950,
    surface: SlmColors.navy850,
    surfaceRaised: SlmColors.navy800,
    surfaceSunken: SlmColors.navy900,
    line: Color(0x2EE4C77F),
    ink: SlmColors.ivory,
    inkSoft: SlmColors.mist,
    inkMuted: SlmColors.slate,
    primary: SlmColors.emerald400,
    primaryDeep: SlmColors.emerald700,
    onPrimary: SlmColors.navy950,
    accent: SlmColors.gold300,
    accentDeep: SlmColors.gold600,
    onAccent: SlmColors.navy950,
    danger: SlmColors.danger,
    warning: SlmColors.warning,
    info: SlmColors.info,
    success: SlmColors.success,
  );

  /// Daylight mood: ivory canvas with navy ink, same accents.
  static const day = SlmPalette(
    brightness: Brightness.light,
    canvas: SlmColors.ivory,
    surface: Colors.white,
    surfaceRaised: Colors.white,
    surfaceSunken: SlmColors.ivoryDeep,
    line: Color(0x339C7631),
    ink: SlmColors.ink,
    inkSoft: SlmColors.navy700,
    inkMuted: Color(0xFF5E6B85),
    primary: SlmColors.emerald600,
    primaryDeep: SlmColors.emerald800,
    onPrimary: Colors.white,
    accent: SlmColors.gold500,
    accentDeep: SlmColors.gold700,
    onAccent: SlmColors.navy950,
    danger: Color(0xFFD32F2F),
    warning: Color(0xFFC77700),
    info: Color(0xFF2F6FDB),
    success: SlmColors.emerald600,
  );

  @override
  SlmPalette copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceRaised,
    Color? surfaceSunken,
    Color? line,
    Color? ink,
    Color? inkSoft,
    Color? inkMuted,
    Color? primary,
    Color? primaryDeep,
    Color? onPrimary,
    Color? accent,
    Color? accentDeep,
    Color? onAccent,
    Color? danger,
    Color? warning,
    Color? info,
    Color? success,
  }) {
    return SlmPalette(
      brightness: brightness,
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      surfaceSunken: surfaceSunken ?? this.surfaceSunken,
      line: line ?? this.line,
      ink: ink ?? this.ink,
      inkSoft: inkSoft ?? this.inkSoft,
      inkMuted: inkMuted ?? this.inkMuted,
      primary: primary ?? this.primary,
      primaryDeep: primaryDeep ?? this.primaryDeep,
      onPrimary: onPrimary ?? this.onPrimary,
      accent: accent ?? this.accent,
      accentDeep: accentDeep ?? this.accentDeep,
      onAccent: onAccent ?? this.onAccent,
      danger: danger ?? this.danger,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      success: success ?? this.success,
    );
  }

  @override
  SlmPalette lerp(SlmPalette? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return SlmPalette(
      brightness: t < 0.5 ? brightness : other.brightness,
      canvas: l(canvas, other.canvas),
      surface: l(surface, other.surface),
      surfaceRaised: l(surfaceRaised, other.surfaceRaised),
      surfaceSunken: l(surfaceSunken, other.surfaceSunken),
      line: l(line, other.line),
      ink: l(ink, other.ink),
      inkSoft: l(inkSoft, other.inkSoft),
      inkMuted: l(inkMuted, other.inkMuted),
      primary: l(primary, other.primary),
      primaryDeep: l(primaryDeep, other.primaryDeep),
      onPrimary: l(onPrimary, other.onPrimary),
      accent: l(accent, other.accent),
      accentDeep: l(accentDeep, other.accentDeep),
      onAccent: l(onAccent, other.onAccent),
      danger: l(danger, other.danger),
      warning: l(warning, other.warning),
      info: l(info, other.info),
      success: l(success, other.success),
    );
  }
}
