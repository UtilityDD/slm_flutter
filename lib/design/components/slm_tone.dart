import 'package:flutter/material.dart';

import '../tokens/slm_colors.dart';
import '../tokens/slm_effects.dart';
import '../tokens/slm_palette.dart';

/// Colour intent for badges, chips and icon treatments.
enum SlmTone { emerald, gold, navy, danger, warning, info, neutral }

extension SlmToneColors on SlmTone {
  Color color(SlmPalette p) => switch (this) {
        SlmTone.emerald => p.primary,
        SlmTone.gold => p.accent,
        SlmTone.navy => p.isNight ? SlmColors.navy300 : SlmColors.navy600,
        SlmTone.danger => p.danger,
        SlmTone.warning => p.warning,
        SlmTone.info => p.info,
        SlmTone.neutral => p.inkSoft,
      };

  Gradient gradient(SlmPalette p) => switch (this) {
        SlmTone.emerald => SlmGradients.emerald,
        SlmTone.gold => SlmGradients.gold,
        SlmTone.navy => const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [SlmColors.navy500, SlmColors.navy700],
          ),
        _ => LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color(p), Color.lerp(color(p), Colors.black, 0.3)!],
          ),
      };

  /// Readable foreground on top of [gradient].
  Color onSolid(SlmPalette p) => switch (this) {
        SlmTone.emerald || SlmTone.gold || SlmTone.warning => SlmColors.navy950,
        _ => Colors.white,
      };
}
