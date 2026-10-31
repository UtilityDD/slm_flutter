import 'package:flutter/material.dart';

/// Raw brand palette: Midnight Navy, Emerald Green, Antique Gold.
///
/// Screens should read colours through [SlmPalette] (via `context.slm.palette`)
/// so day and night moods stay interchangeable. Use these raw values only
/// inside the design system.
abstract final class SlmColors {
  // Midnight Navy
  static const navy950 = Color(0xFF050A16);
  static const navy900 = Color(0xFF0A1428);
  static const navy850 = Color(0xFF0D1932);
  static const navy800 = Color(0xFF111F3D);
  static const navy700 = Color(0xFF182B52);
  static const navy600 = Color(0xFF223A6B);
  static const navy500 = Color(0xFF2E4B86);
  static const navy300 = Color(0xFF7D90B8);

  // Emerald Green
  static const emerald200 = Color(0xFFA7F3D0);
  static const emerald300 = Color(0xFF6EE7B7);
  static const emerald400 = Color(0xFF34D399);
  static const emerald500 = Color(0xFF10B981);
  static const emerald600 = Color(0xFF059669);
  static const emerald700 = Color(0xFF047857);
  static const emerald800 = Color(0xFF065F46);
  static const emerald900 = Color(0xFF053D2F);

  // Antique Gold
  static const gold100 = Color(0xFFFAF1DA);
  static const gold200 = Color(0xFFF1DFB0);
  static const gold300 = Color(0xFFE4C77F);
  static const gold400 = Color(0xFFD3AD5C);
  static const gold500 = Color(0xFFBF9443);
  static const gold600 = Color(0xFF9C7631);
  static const gold700 = Color(0xFF765822);

  // Neutrals
  static const ivory = Color(0xFFF8F3E7);
  static const ivoryDeep = Color(0xFFEFE6D2);
  static const mist = Color(0xFFC3CCDD);
  static const slate = Color(0xFF8A97B1);
  static const ink = Color(0xFF0B1426);

  // Medal metals
  static const silver = Color(0xFFC9D2E0);
  static const silverDeep = Color(0xFF8D99AE);
  static const bronze = Color(0xFFD69A62);
  static const bronzeDeep = Color(0xFF9A5E2E);

  // Semantic
  static const danger = Color(0xFFEF5350);
  static const warning = Color(0xFFF2A93B);
  static const info = Color(0xFF5B9BF8);
  static const success = emerald400;
}
