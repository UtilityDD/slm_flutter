import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../life_skills/life_skills_menu_row.dart';
import '../shell/app_routes.dart';
import '../shell/shell_providers.dart';
import '../training/training_screen.dart';

/// Same gold circle used on Home, the intro, and the fear page.
class HomeToolboxButton extends StatelessWidget {
  final VoidCallback onTap;

  const HomeToolboxButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SlmPressable(
      onTap: onTap,
      semanticLabel: 'টুলবক্স',
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.6)),
          color: SlmColors.navy950.withValues(alpha: 0.45),
        ),
        child: const Icon(Icons.apps_rounded, size: 18, color: SlmColors.gold200),
      ),
    );
  }
}

/// Opens the shared toolbox sheet from any of the three path pages.
Future<void> openHomeToolbox(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: SlmColors.navy900,
    builder: (ctx) => Consumer(
      builder: (context, ref, _) {
        final bn = ref.watch(languageProvider);
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.viewPaddingOf(ctx).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr(bn, 'টুলবক্স', 'Toolbox'),
                style: const TextStyle(
                  fontFamily: banglaFont,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: 0,
                  color: SlmColors.ivory,
                ),
              ),
              const SizedBox(height: 8),
              _ToolRow(
                icon: Icons.emoji_events_rounded,
                label: tr(bn, 'র‍্যাঙ্ক', 'Rank'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).pushNamed(AppRoutes.rank);
                },
              ),
              // Only the lessons the player opened by passing game levels.
              _ToolRow(
                icon: Icons.school_rounded,
                label: tr(bn, 'আমার পাঠ', 'My lessons'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const TrainingScreen()),
                  );
                },
              ),
              const LifeSkillsMenuRow(),
              _ToolRow(
                icon: Icons.phone_in_talk_rounded,
                label: tr(bn, 'জরুরি নম্বর', 'Emergency'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).pushNamed(AppRoutes.emergency);
                },
              ),
              _ToolRow(
                icon: Icons.tune_rounded,
                label: tr(bn, 'সেটিংস', 'Settings'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).pushNamed(AppRoutes.more);
                },
              ),
            ],
          ),
        );
      },
    ),
  );
}

class _ToolRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ToolRow({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SlmPressable(
      onTap: onTap,
      semanticLabel: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: SlmColors.gold200, size: 22),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontFamily: banglaFont,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.2,
                letterSpacing: 0,
                color: SlmColors.ivory,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
