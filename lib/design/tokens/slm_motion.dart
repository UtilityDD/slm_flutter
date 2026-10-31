import 'package:flutter/animation.dart';

abstract final class SlmMotion {
  static const instant = Duration(milliseconds: 90);
  static const fast = Duration(milliseconds: 160);
  static const base = Duration(milliseconds: 240);
  static const slow = Duration(milliseconds: 380);
  static const page = Duration(milliseconds: 520);

  /// Gap between items in a staggered entrance.
  static const stagger = Duration(milliseconds: 55);

  static const standard = Curves.easeOutCubic;
  static const emphasized = Cubic(0.2, 0, 0, 1);
  static const exit = Curves.easeInCubic;
  static const settle = Curves.easeOutBack;
}
