import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/supabase_service.dart';
import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../auth/auth_provider.dart';
import '../training/training_provider.dart';
import 'hero_card_carousel.dart';
import 'lesson_progress_store.dart';
import 'level_celebration_page.dart';
import 'level_lessons_sheet.dart';
import 'lineman_figure.dart';
import 'lineman_progress.dart';

/// Level 0 — path orientation: how learning works, step-by-step map of ranks.
class LevelZeroPage extends ConsumerStatefulWidget {
  final bool bn;

  const LevelZeroPage({super.key, required this.bn});

  @override
  ConsumerState<LevelZeroPage> createState() => _LevelZeroPageState();
}

class _LevelZeroPageState extends ConsumerState<LevelZeroPage> {
  bool _saving = false;

  Future<void> _completeAndOpenTrainee() async {
    if (_saving) return;
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();

    await markLessonCompletedLocally(ref, pathOrientationId);

    final auth = ref.read(authProvider);
    final userId = auth.isAuthenticated ? auth.profile?.id : null;
    if (userId != null) {
      try {
        final current = List<String>.from(auth.profile?.completedLessons ?? []);
        if (!current.contains(pathOrientationId)) {
          current.add(pathOrientationId);
          await SupabaseService.client.from('profiles').update({
            'completed_lessons': current,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', userId);
          await ref.read(authProvider.notifier).refreshProfile();
        }
      } catch (_) {}
    }

    ref.invalidate(trainingLadderProvider);
    if (!mounted) return;

    await markModuleCelebrated(ref, 0);
    await Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 480),
        pageBuilder: (_, __, ___) => LevelCelebrationPage(
          completedStep: 0,
          completedTitle: heroTitle(0, widget.bn),
          nextStep: 1,
          nextTitle: heroTitle(1, widget.bn),
          bn: widget.bn,
        ),
        transitionsBuilder: (_, anim, __, child) {
          final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
          return FadeTransition(opacity: curved, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bn = widget.bn;
    final done = isPathOrientationDone(ref.watch(allCompletedLessonsProvider));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
      backgroundColor: SlmColors.navy950,
      body: Stack(
        children: [
          Positioned.fill(
            child: Theme(
              data: SlmTheme.night(),
              child: const SlmBackground(constrain: false, child: SizedBox.expand()),
            ),
          ),
          SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 2, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: SlmColors.ivory),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: SlmColors.navy800,
                        borderRadius: SlmRadius.pillAll,
                        border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.55)),
                      ),
                      child: Text(
                        bn ? 'পথের মানচিত্র' : 'Path map',
                        style: const TextStyle(
                          fontFamily: banglaFont,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: SlmColors.gold100,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const SizedBox(
                          width: 86,
                          height: 114,
                          child: LinemanFigure(step: 0, enableHero: true),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bn ? 'লেভেল 0 · শুরু' : 'Level 0 · Start',
                                style: const TextStyle(
                                  fontFamily: banglaFont,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                  color: SlmColors.gold300,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                bn ? 'কীভাবে শিখবেন' : 'How you will learn',
                                style: const TextStyle(
                                  fontFamily: banglaFont,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  height: 1.25,
                                  color: SlmColors.ivory,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    SlmReveal(
                      child: _IntroCard(
                        title: bn ? 'এই অ্যাপের পথ' : 'Your path in the app',
                        body: bn
                            ? 'প্রথমে এই মানচিত্রটি পড়ুন। তারপর এক এক করে লেভেল খুলবে। প্রতিটি লেভেলে পাঠ আছে — আগের পাঠ শেষ না হলে পরেরটি খুলবে না।'
                            : 'Read this map first. Then levels open one by one. Inside each level, finish the previous lesson before the next unlocks.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    SlmReveal(
                      index: 1,
                      child: _IntroCard(
                        title: bn ? 'শিখবেন যেভাবে' : 'How learning works',
                        body: bn
                            ? '1) পাঠ পড়ুন বা শুনুন\n2) ধাপ ধাপ বুঝে এগোন\n3) শেষে পয়েন্ট নিন\n4) পরের পাঠ / লেভেল খুলবে'
                            : '1) Read or listen to a lesson\n2) Move step by step\n3) Collect points at the end\n4) The next lesson / level unlocks',
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      bn ? 'লেভেল ধাপে ধাপে' : 'Levels, step by step',
                      style: const TextStyle(
                        fontFamily: banglaFont,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: SlmColors.gold200,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (var i = 0; i < linemanChapters.length; i++)
                      SlmReveal(
                        index: i + 2,
                        child: _PathStepTile(
                          index: i + 1,
                          titleBn: linemanChapters[i].$1,
                          titleEn: linemanChapters[i].$2,
                          topic: staticChapterTitles[i],
                          bn: bn,
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(
                      bn
                          ? 'মানচিত্র শেষ হলে লেভেল 1 · ট্রেইনি খুলবে।'
                          : 'When you finish this map, Level 1 · Trainee opens.',
                      style: const TextStyle(
                        fontFamily: banglaFont,
                        fontSize: 13.5,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                        color: SlmColors.mist,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                child: Theme(
                  data: SlmTheme.night(),
                  child: SlmButton(
                    label: done
                        ? (bn ? 'লেভেল 1 খুলুন' : 'Open Level 1')
                        : (bn ? 'বুঝেছি · লেভেল 1 শুরু' : 'Got it · start Level 1'),
                    size: SlmButtonSize.large,
                    expand: true,
                    loading: _saving,
                    onPressed: _saving
                        ? null
                        : () {
                            if (done) {
                              Navigator.of(context).pop();
                              openLevelLessons(context, ref, step: 1, bn: bn);
                            } else {
                              _completeAndOpenTrainee();
                            }
                          },
                  ),
                ),
              ),
            ],
          ),
        ),
        ],
      ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  final String title;
  final String body;

  const _IntroCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        gradient: SlmGradients.navyHero,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 14, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: banglaFont,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: SlmColors.emerald300,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontFamily: banglaFont,
              fontSize: 15.5,
              height: 1.6,
              fontWeight: FontWeight.w500,
              color: SlmColors.ivory,
            ),
          ),
        ],
      ),
    );
  }
}

class _PathStepTile extends StatelessWidget {
  final int index;
  final String titleBn;
  final String titleEn;
  final String topic;
  final bool bn;

  const _PathStepTile({
    required this.index,
    required this.titleBn,
    required this.titleEn,
    required this.topic,
    required this.bn,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
      decoration: BoxDecoration(
        gradient: SlmGradients.navyCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: SlmGradients.emerald,
              shape: BoxShape.circle,
              border: Border.all(color: SlmColors.gold300.withValues(alpha: 0.7)),
            ),
            child: Text(
              '$index',
              style: const TextStyle(
                fontFamily: banglaFont,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bn ? titleBn : titleEn,
                  style: const TextStyle(
                    fontFamily: banglaFont,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: SlmColors.ivory,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  topic,
                  style: const TextStyle(
                    fontFamily: banglaFont,
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                    color: SlmColors.mist,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
