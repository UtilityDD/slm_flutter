import 'package:flutter/material.dart';

import '../theme/slm_theme.dart';
import '../tokens/slm_colors.dart';
import '../tokens/slm_effects.dart';
import '../tokens/slm_layout.dart';
import 'slm_tone.dart';

enum SlmIconStyle {
  /// Tinted rounded square, for lists and menus.
  soft,

  /// Gradient fill with a light top highlight, for primary entry points.
  solid,

  /// Round gold medallion with a navy core, for achievements and ranks.
  medal,
}

/// The single icon treatment used across the app.
class SlmIconBadge extends StatelessWidget {
  final IconData icon;
  final SlmTone tone;
  final SlmIconStyle style;
  final double size;

  const SlmIconBadge({
    super.key,
    required this.icon,
    this.tone = SlmTone.gold,
    this.style = SlmIconStyle.soft,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.slm.palette;
    final d = size * context.slm.layout.scale;
    final c = tone.color(p);
    final glyph = d * 0.5;

    switch (style) {
      case SlmIconStyle.soft:
        return Container(
          width: d,
          height: d,
          decoration: BoxDecoration(
            color: c.withValues(alpha: p.isNight ? 0.14 : 0.12),
            borderRadius: BorderRadius.circular(d * 0.32),
            border: Border.all(color: c.withValues(alpha: 0.28)),
          ),
          child: Icon(icon, size: glyph, color: c),
        );
      case SlmIconStyle.solid:
        return Container(
          width: d,
          height: d,
          decoration: BoxDecoration(
            gradient: tone.gradient(p),
            borderRadius: BorderRadius.circular(d * 0.32),
            boxShadow: SlmShadows.glow(c, strength: 0.55),
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(d * 0.32),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.center,
              colors: [Color(0x40FFFFFF), Color(0x00FFFFFF)],
            ),
          ),
          child: Icon(icon, size: glyph, color: tone.onSolid(p)),
        );
      case SlmIconStyle.medal:
        return Container(
          width: d,
          height: d,
          padding: EdgeInsets.all(d * 0.07),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SlmGradients.gold,
            boxShadow: SlmShadows.glow(SlmColors.gold400, strength: 0.6),
          ),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [SlmColors.navy700, SlmColors.navy900],
              ),
            ),
            child: Icon(icon, size: glyph * 0.9, color: SlmColors.gold300),
          ),
        );
    }
  }
}

/// Medal colour for a podium place (1 gold, 2 silver, 3 bronze).
enum SlmMedal { gold, silver, bronze }

extension SlmMedalLook on SlmMedal {
  Gradient get gradient => switch (this) {
        SlmMedal.gold => SlmGradients.gold,
        SlmMedal.silver => SlmGradients.silver,
        SlmMedal.bronze => SlmGradients.bronze,
      };

  Color get glow => switch (this) {
        SlmMedal.gold => SlmColors.gold400,
        SlmMedal.silver => SlmColors.silver,
        SlmMedal.bronze => SlmColors.bronze,
      };

  static SlmMedal? forRank(int rank) => switch (rank) {
        1 => SlmMedal.gold,
        2 => SlmMedal.silver,
        3 => SlmMedal.bronze,
        _ => null,
      };
}

/// Small numbered disc: metal for the top three, quiet outline after that.
class SlmRankDisc extends StatelessWidget {
  final int rank;
  final double size;

  const SlmRankDisc({super.key, required this.rank, this.size = 30});

  @override
  Widget build(BuildContext context) {
    final s = context.slm;
    final medal = SlmMedalLook.forRank(rank);
    final d = size * s.layout.scale;
    return Container(
      width: d,
      height: d,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: medal?.gradient,
        color: medal == null ? s.palette.surfaceSunken : null,
        border: medal == null ? Border.all(color: s.palette.line) : null,
      ),
      child: FittedBox(
        child: Padding(
          padding: const EdgeInsets.all(SlmSpace.xxs),
          child: Text(
            '$rank',
            style: s.type.number.copyWith(
              fontSize: d * 0.42,
              color: medal == null ? s.palette.inkSoft : SlmColors.navy950,
            ),
          ),
        ),
      ),
    );
  }
}
