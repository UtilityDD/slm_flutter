import 'package:flutter/widgets.dart';

/// 4-pt spacing scale.
abstract final class SlmSpace {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}

abstract final class SlmRadius {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
}

/// Minimum touch target, per Material accessibility guidance.
const double slmTapTarget = 48;

enum SlmSize { compact, regular, expanded }

/// Width-driven layout facts. Read with `context.slm.layout`.
@immutable
class SlmLayout {
  final double width;
  final SlmSize size;

  const SlmLayout._(this.width, this.size);

  factory SlmLayout.of(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final size = w < 360
        ? SlmSize.compact
        : w < 600
            ? SlmSize.regular
            : SlmSize.expanded;
    return SlmLayout._(w, size);
  }

  bool get isCompact => size == SlmSize.compact;
  bool get isExpanded => size == SlmSize.expanded;

  /// Multiplier for type and component sizes (small phones shrink slightly).
  double get scale => switch (size) {
        SlmSize.compact => 0.92,
        SlmSize.regular => 1.0,
        SlmSize.expanded => 1.08,
      };

  /// Page side padding.
  double get gutter => switch (size) {
        SlmSize.compact => SlmSpace.sm,
        SlmSize.regular => SlmSpace.md,
        SlmSize.expanded => SlmSpace.xxl,
      };

  /// Content never stretches wider than this on tablets.
  double get maxContent => 640;
}
