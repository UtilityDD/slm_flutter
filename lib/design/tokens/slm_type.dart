import 'package:flutter/material.dart';

import 'slm_palette.dart';

const slmFont = 'Noto Sans Bengali';
const _fallback = ['Roboto', 'Noto Sans', slmFont];

/// Keeps 0–9 as Western digits inside Bangla text.
const _digits = [FontFeature.localeAware(enable: false)];
const _tabular = [FontFeature.localeAware(enable: false), FontFeature.tabularFigures()];

final _bangla = RegExp(r'[\u0980-\u09FF]');

/// True when [text] contains any Bengali script.
bool slmIsBangla(String text) => _bangla.hasMatch(text);

/// Type scale. Heights are tuned for Latin; [adapt] relaxes them for Bangla,
/// whose vowel signs sit above and below the line and need more room.
@immutable
class SlmType {
  final TextStyle display;
  final TextStyle headline;
  final TextStyle title;
  final TextStyle titleSm;
  final TextStyle body;
  final TextStyle bodySm;
  final TextStyle label;
  final TextStyle caption;

  /// Small spaced capitals for English section tags. Spacing is dropped for Bangla.
  final TextStyle overline;

  /// Scores, ranks, timers: tabular so columns don't jitter while counting.
  final TextStyle number;

  const SlmType._({
    required this.display,
    required this.headline,
    required this.title,
    required this.titleSm,
    required this.body,
    required this.bodySm,
    required this.label,
    required this.caption,
    required this.overline,
    required this.number,
  });

  factory SlmType.of(SlmPalette p, {double scale = 1}) {
    TextStyle s(double size, FontWeight w, Color c, double h, {double spacing = 0, bool tab = false}) {
      return TextStyle(
        fontFamily: slmFont,
        fontFamilyFallback: _fallback,
        fontSize: size * scale,
        fontWeight: w,
        color: c,
        height: h,
        letterSpacing: spacing,
        fontFeatures: tab ? _tabular : _digits,
      );
    }

    return SlmType._(
      display: s(30, FontWeight.w700, p.ink, 1.18, spacing: -0.4),
      headline: s(22, FontWeight.w700, p.ink, 1.22, spacing: -0.2),
      title: s(18, FontWeight.w600, p.ink, 1.28),
      titleSm: s(15.5, FontWeight.w600, p.ink, 1.3),
      body: s(15, FontWeight.w400, p.inkSoft, 1.45),
      bodySm: s(13, FontWeight.w400, p.inkSoft, 1.4),
      label: s(13.5, FontWeight.w600, p.ink, 1.25, spacing: 0.1),
      caption: s(11.5, FontWeight.w500, p.inkMuted, 1.3),
      overline: s(11, FontWeight.w700, p.accent, 1.3, spacing: 1.4),
      number: s(16, FontWeight.w800, p.ink, 1.1, tab: true),
    );
  }

  /// Bangla-safe version of [style] for [text]: no letter spacing (it breaks
  /// conjuncts apart) and a taller line so matras never clip.
  static TextStyle adapt(TextStyle style, String text) {
    if (!slmIsBangla(text)) return style;
    final h = style.height ?? 1.3;
    return style.copyWith(
      letterSpacing: 0,
      height: h < 1.42 ? 1.42 : h,
    );
  }
}
