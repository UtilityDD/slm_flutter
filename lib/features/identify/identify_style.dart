import 'package:flutter/material.dart';

class CategoryStyle {
  final Color color;
  final IconData icon;

  const CategoryStyle(this.color, this.icon);

  Color get wash => Color.lerp(color, Colors.white, 0.9)!;
  Color get soft => Color.lerp(color, Colors.white, 0.78)!;
}

const _known = {
  'PPE': CategoryStyle(Color(0xFFEA580C), Icons.health_and_safety_rounded),
  'Tools': CategoryStyle(Color(0xFF2563EB), Icons.handyman_rounded),
  'Insulators': CategoryStyle(Color(0xFF0F766E), Icons.bolt_rounded),
  'AB Cable Items': CategoryStyle(Color(0xFF7C3AED), Icons.cable_rounded),
  'Others': CategoryStyle(Color(0xFF8A5A3C), Icons.category_rounded),
  'Charts': CategoryStyle(Color(0xFF15803D), Icons.table_chart_rounded),
};

const _fallbackPalette = [
  Color(0xFFDB2777),
  Color(0xFF0891B2),
  Color(0xFFCA8A04),
  Color(0xFF4F46E5),
  Color(0xFF65A30D),
  Color(0xFFB45309),
];

/// New categories get a stable colour from their name.
CategoryStyle categoryStyle(String id) {
  final known = _known[id];
  if (known != null) return known;
  final hash = id.codeUnits.fold<int>(0, (a, b) => (a * 31 + b) & 0x7fffffff);
  return CategoryStyle(_fallbackPalette[hash % _fallbackPalette.length], Icons.inventory_2_rounded);
}

/// Display helper — always English digits (0–9), even in Bangla UI.
String bnNumber(Object value, bool bn) => '$value';
