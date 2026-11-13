import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/en_digits.dart';
import '../../core/theme/app_theme.dart' show banglaFont;
import '../../design/slm_design.dart';
import '../game/game_save.dart';
import 'life_skills_data.dart';
import 'life_skills_screen.dart';

/// The toolbox sheet's "আমার জীবন দক্ষতা" row. Renders nothing until a life
/// skill is won (they are invisible before that); then shows the count and
/// opens the list. Drop it into the sheet's Column as is.
class LifeSkillsMenuRow extends ConsumerWidget {
  const LifeSkillsMenuRow({super.key, this.closeSheetFirst = true});

  /// Pops the sheet the row sits in before opening the list (like the other rows).
  final bool closeSheetFirst;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final won = ref.watch(gameSaveProvider.select((s) => s.toolbox.lifeSkills.where(kLifeSkillIds.contains).length));
    if (won == 0) return const SizedBox.shrink();
    return SlmPressable(
      key: const ValueKey('life-skills-menu-row'),
      onTap: () {
        final nav = Navigator.of(context);
        if (closeSheetFirst) nav.pop();
        nav.push(MaterialPageRoute<void>(builder: (_) => const LifeSkillsListPage()));
      },
      semanticLabel: LifeSkillLines.menu,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.auto_stories_rounded, color: SlmColors.gold200, size: 22),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                LifeSkillLines.menu,
                style: TextStyle(
                  fontFamily: banglaFont,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  letterSpacing: 0,
                  color: SlmColors.ivory,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.6)),
              ),
              child: Text(
                enDigits('$won/${kLifeSkillIds.length}'),
                key: const ValueKey('life-skills-count'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  color: SlmColors.gold200,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
