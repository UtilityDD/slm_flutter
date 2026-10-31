import 'package:flutter/material.dart';

import 'slm_colors.dart';
import 'slm_palette.dart';

/// Brand gradients. Directional ones run top-left to bottom-right.
abstract final class SlmGradients {
  static const emerald = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [SlmColors.emerald400, SlmColors.emerald600, SlmColors.emerald800],
    stops: [0, 0.55, 1],
  );

  /// Brushed antique-gold foil.
  static const gold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [SlmColors.gold200, SlmColors.gold400, SlmColors.gold600, SlmColors.gold300],
    stops: [0, 0.38, 0.72, 1],
  );

  static const silver = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF1F4F9), SlmColors.silver, SlmColors.silverDeep],
  );

  static const bronze = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF2C79B), SlmColors.bronze, SlmColors.bronzeDeep],
  );

  /// Night card fill: a faint lift at the top edge.
  static const navyCard = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [SlmColors.navy800, SlmColors.navy850],
  );

  /// Hero card: deep navy with a hint of emerald in the far corner.
  static const navyHero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [SlmColors.navy700, SlmColors.navy850, Color(0xFF0B2A2A)],
    stops: [0, 0.6, 1],
  );

  /// Gold hairline used as a card border via [SlmGradientBorder].
  static const goldEdge = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xCCE4C77F), Color(0x1AE4C77F), Color(0x80BF9443)],
    stops: [0, 0.5, 1],
  );

  static LinearGradient canvas(SlmPalette p) => p.isNight
      ? const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [SlmColors.navy900, SlmColors.navy950],
        )
      : const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [SlmColors.ivory, SlmColors.ivoryDeep],
        );
}

abstract final class SlmShadows {
  static List<BoxShadow> soft(SlmPalette p) => [
        BoxShadow(
          color: p.isNight ? const Color(0x66000000) : const Color(0x140B1426),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> raised(SlmPalette p) => [
        BoxShadow(
          color: p.isNight ? const Color(0x8C000000) : const Color(0x1F0B1426),
          blurRadius: 28,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: p.isNight ? const Color(0x33000000) : const Color(0x0A0B1426),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];

  /// Coloured halo for highlighted elements (CTA, rank one, focus).
  static List<BoxShadow> glow(Color c, {double strength = 1}) => [
        BoxShadow(
          color: c.withValues(alpha: 0.38 * strength),
          blurRadius: 22 * strength,
          spreadRadius: -2,
          offset: const Offset(0, 6),
        ),
      ];
}
