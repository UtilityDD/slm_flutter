import 'package:flutter/material.dart';

/// Night-shift palette shared by every জিরো লস screen.
class ZlColors {
  static const bg = Color(0xFF0B1220);
  static const line = Color(0xFF26334D);
  static const text = Color(0xFFF1F5F9);
  static const soft = Color(0xFF94A3B8);
  static const amber = Color(0xFFF59E0B);
  static const green = Color(0xFF22C55E);
  static const red = Color(0xFFEF4444);
  static const orange = Color(0xFFFB923C);
  static const cream = Color(0xFFFFF5EE);
}

TextStyle zlText(double size, {FontWeight weight = FontWeight.w500, Color color = ZlColors.text, double? height}) =>
    TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      fontFamilyFallback: const ['Roboto', 'Noto Sans'],
      fontFeatures: const [FontFeature.localeAware(enable: false)],
    );
