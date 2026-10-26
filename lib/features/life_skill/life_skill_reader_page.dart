import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../shell/shell_insets.dart';
import '../shell/shell_providers.dart';
import 'life_skill_listen_bar.dart';
import 'life_skill_models.dart';

class LifeSkillReaderPage extends ConsumerWidget {
  final LifeSkillModule module;
  final LifeSkillManuscript manuscript;

  const LifeSkillReaderPage({
    super.key,
    required this.module,
    required this.manuscript,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bn = ref.watch(languageProvider);
    final tone = lifeSkillTone(module.category);
    final audio = module.audioUrl(bn);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(module.code),
      ),
      body: ListView(
        padding: shellScrollPadding(context, left: 16, top: 8, right: 16, extraBottom: 20),
        children: [
          Text(
            lsDigits(manuscript.title.isNotEmpty ? manuscript.title : module.title(bn)),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, height: 1.3, color: AppColors.ink),
          ),
          if (manuscript.briefing.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              lsDigits(manuscript.briefing),
              style: const TextStyle(fontSize: 15, height: 1.55, fontWeight: FontWeight.w500, color: AppColors.inkSoft),
            ),
          ],
          if (audio.isNotEmpty) ...[
            const SizedBox(height: 16),
            LifeSkillListenBar(audioUrl: audio, accent: tone.accent, bn: bn),
          ],
          const SizedBox(height: 18),
          for (final section in manuscript.sections) ...[
            _SectionCard(section: section, tone: tone, bn: bn),
            const SizedBox(height: 12),
          ],
          if (manuscript.tips.isNotEmpty)
            _TipCard(title: manuscript.tipTitle, tips: manuscript.tips, bn: bn),
          if (manuscript.myths.isNotEmpty) ...[
            const SizedBox(height: 12),
            _MythCard(title: manuscript.mythTitle, myths: manuscript.myths, bn: bn),
          ],
          if (manuscript.helpline.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFDBA74)),
              ),
              child: Text(
                lsDigits(manuscript.helpline),
                style: const TextStyle(fontSize: 14, height: 1.45, fontWeight: FontWeight.w600, color: Color(0xFF9A3412)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final LifeSkillSection section;
  final LifeSkillTone tone;
  final bool bn;

  const _SectionCard({required this.section, required this.tone, required this.bn});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x40D6BDA4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lsDigits(section.title),
            style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, color: tone.accent),
          ),
          for (final point in section.points) ...[
            const SizedBox(height: 12),
            Text(lsDigits(point.name), style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: AppColors.ink)),
            if (point.caption.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(lsDigits(point.caption), style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: tone.accent)),
            ],
            if (point.specs.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(lsDigits(point.specs), style: const TextStyle(fontSize: 14.5, height: 1.5, fontWeight: FontWeight.w500, color: AppColors.inkSoft)),
            ],
            if (point.importance.isNotEmpty) ...[
              const SizedBox(height: 8),
              _LabeledNote(
                label: tr(bn, 'কেন জরুরি', 'Why it matters'),
                body: lsDigits(point.importance),
                color: const Color(0xFF0F766E),
                soft: const Color(0xFFECFDF5),
              ),
            ],
            if (point.dailyCheck.isNotEmpty) ...[
              const SizedBox(height: 8),
              _LabeledNote(
                label: tr(bn, 'আজকের চেক', 'Today’s check'),
                body: lsDigits(point.dailyCheck),
                color: const Color(0xFFB45309),
                soft: const Color(0xFFFFFBEB),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _LabeledNote extends StatelessWidget {
  final String label;
  final String body;
  final Color color;
  final Color soft;

  const _LabeledNote({
    required this.label,
    required this.body,
    required this.color,
    required this.soft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 3),
          Text(body, style: const TextStyle(fontSize: 13.5, height: 1.45, fontWeight: FontWeight.w500, color: AppColors.inkSoft)),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  final String title;
  final List<String> tips;
  final bool bn;

  const _TipCard({required this.title, required this.tips, required this.bn});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF6EE7B7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lsDigits(title.isNotEmpty ? title : tr(bn, 'সহজ নিয়ম', 'Quick rules')),
            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: Color(0xFF047857)),
          ),
          const SizedBox(height: 8),
          for (final tip in tips) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(lsDigits(tip), style: const TextStyle(fontSize: 14, height: 1.45, fontWeight: FontWeight.w500, color: AppColors.inkSoft)),
            ),
          ],
        ],
      ),
    );
  }
}

class _MythCard extends StatelessWidget {
  final String title;
  final List<LifeSkillMyth> myths;
  final bool bn;

  const _MythCard({required this.title, required this.myths, required this.bn});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFECDD3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lsDigits(title.isNotEmpty ? title : tr(bn, 'ভুল ধারণা', 'Myth buster')),
            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700, color: Color(0xFFBE123C)),
          ),
          for (final myth in myths) ...[
            const SizedBox(height: 10),
            Text(tr(bn, 'ভুল:', 'Myth:'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF9F1239))),
            Text(lsDigits(myth.myth), style: const TextStyle(fontSize: 13.5, height: 1.45, fontWeight: FontWeight.w500, color: AppColors.inkSoft)),
            const SizedBox(height: 6),
            Text(tr(bn, 'সত্য:', 'Reality:'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF047857))),
            Text(lsDigits(myth.reality), style: const TextStyle(fontSize: 13.5, height: 1.45, fontWeight: FontWeight.w500, color: AppColors.inkSoft)),
          ],
        ],
      ),
    );
  }
}
