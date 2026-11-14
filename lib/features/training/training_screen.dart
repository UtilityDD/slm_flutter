import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/en_digits.dart';
import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../game/game_save.dart';
import '../home/lesson_reader_page.dart';
import '../shell/shell_insets.dart';
import '../shell/shell_providers.dart';
import 'training_models.dart';
import 'training_provider.dart';

/// Lessons the player opened by passing their Learn level in the game, as
/// `M.C` ids. Owner rule: a training lesson opens only through a level pass,
/// so reading progress or the web profile never adds one here.
Set<String> passedLessonKeys(Map<String, String> rungProgress) => {
      for (final e in rungProgress.entries)
        if (e.value == 'cleared' && e.key.endsWith('/learn')) e.key.substring(0, e.key.length - '/learn'.length),
    };

final passedLessonKeysProvider = Provider<Set<String>>(
  (ref) => passedLessonKeys(ref.watch(gameSaveProvider.select((s) => s.rungProgress))),
);

/// Module numbers that hold at least one passed lesson, in order.
List<int> passedModules(Set<String> passed) {
  final mods = <int>{
    for (final key in passed) ?int.tryParse(key.split('.').first),
  }.toList()
    ..sort();
  return mods;
}

/// "আমার পাঠ": only the lessons unlocked by game level passes. Locked lessons
/// are not listed at all.
class TrainingScreen extends ConsumerStatefulWidget {
  const TrainingScreen({super.key});

  @override
  ConsumerState<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends ConsumerState<TrainingScreen> {
  int? _expandedModuleNumber;
  var _autoOpened = false;

  @override
  Widget build(BuildContext context) {
    final bn = ref.watch(languageProvider);
    final passed = ref.watch(passedLessonKeysProvider);
    final modules = passedModules(passed);
    if (!_autoOpened && modules.isNotEmpty) {
      _autoOpened = true;
      _expandedModuleNumber = modules.last;
    }

    return Theme(
      data: SlmTheme.night(),
      child: Scaffold(
        backgroundColor: SlmColors.navy950,
        appBar: AppBar(
          backgroundColor: SlmColors.navy950,
          surfaceTintColor: Colors.transparent,
          foregroundColor: SlmColors.ivory,
          elevation: 0,
          title: Text(
            tr(bn, 'আমার পাঠ', 'My lessons'),
            style: bangla(fontSize: 19, fontWeight: FontWeight.w900, color: SlmColors.gold200),
          ),
        ),
        body: modules.isEmpty
            ? _EmptyLessons(bn: bn)
            : ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16, 8, 16, shellDockBottomInset(context) + 16),
                itemCount: modules.length,
                itemBuilder: (context, index) => _moduleCard(modules[index], passed),
              ),
      ),
    );
  }

  Widget _moduleCard(int module, Set<String> passed) {
    final isExpanded = _expandedModuleNumber == module;
    final count = passed.where((k) => k.split('.').first == '$module').length;
    final title = module <= staticChapterTitles.length ? staticChapterTitles[module - 1] : 'অধ্যায় $module';
    const accent = SlmColors.gold300;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AnimatedContainer(
        duration: SlmMotion.base,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E2D4B), Color(0xFF111A30)],
          ),
          border: Border.all(color: accent.withValues(alpha: 0.5), width: 1.1),
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => setState(() => _expandedModuleNumber = isExpanded ? null : module),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    _StepBadge(number: module, accent: accent),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: bangla(fontSize: 17, fontWeight: FontWeight.w800, color: SlmColors.ivory),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.verified_rounded, size: 16, color: SlmColors.gold300),
                              const SizedBox(width: 4),
                              Text(
                                enDigits('$count টি পাঠ খোলা'),
                                style: bangla(fontSize: 12, fontWeight: FontWeight.w700, color: SlmColors.mist),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: SlmMotion.base,
                      child: const Icon(Icons.expand_more_rounded, color: accent),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: SlmMotion.base,
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: isExpanded
                  ? Column(
                      children: [
                        Divider(height: 1, color: SlmColors.gold400.withValues(alpha: 0.2)),
                        _lessonsList(module, passed),
                      ],
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lessonsList(int moduleNumber, Set<String> passed) {
    final lessonsAsync = ref.watch(moduleLessonsProvider(moduleNumber));
    void retry() {
      ref.invalidate(trainingModuleRowsProvider(moduleNumber));
      ref.invalidate(moduleLessonsProvider(moduleNumber));
    }

    const offline = 'পাঠগুলো এখন আনা যাচ্ছে না। ইন্টারনেট চালু করে আবার চেষ্টা করুন।';
    return lessonsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.5, color: SlmColors.gold300)),
      ),
      error: (e, _) => _OfflineNote(text: offline, onRetry: retry),
      data: (all) {
        final lessons = [
          for (final l in all)
            if (passed.contains('${l.moduleNumber}.${l.chapterNumber}')) l,
        ];
        // The module has passed lessons, so an empty list means the text
        // could not be fetched (offline, never read on this phone).
        if (lessons.isEmpty) return _OfflineNote(text: offline, onRetry: retry);
        return Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
          child: Column(
            children: [
              for (final lesson in lessons)
                _LessonRow(
                  lesson: lesson,
                  onTap: () => Navigator.of(context).push(
                    SlmPageRoute<void>(builder: (_) => LessonReaderPage(lesson: lesson, bn: true)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Nothing passed yet: point back to the ladder.
class _EmptyLessons extends StatelessWidget {
  const _EmptyLessons({required this.bn});

  final bool bn;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.school_rounded, size: 44, color: SlmColors.gold300),
            const SizedBox(height: 12),
            Text(
              tr(bn, 'এখনও কোনো পাঠ খোলেনি', 'No lessons open yet'),
              textAlign: TextAlign.center,
              style: bangla(fontSize: 18, fontWeight: FontWeight.w800, color: SlmColors.ivory),
            ),
            const SizedBox(height: 8),
            Text(
              tr(
                bn,
                'লেভেল পাস করলেই সংশ্লিষ্ট পাঠ এখানে আনলক হয়ে যাবে।',
                'Pass a level on the Deathless Path and its lesson opens here.',
              ),
              textAlign: TextAlign.center,
              style: bangla(fontSize: 15, fontWeight: FontWeight.w600, color: SlmColors.mist),
            ),
            const SizedBox(height: 18),
            SlmButton.gold(
              label: tr(bn, 'পথে ফিরে যান', 'Back to the path'),
              icon: Icons.arrow_back_rounded,
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.number, required this.accent});

  final int number;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: 0.16),
        border: Border.all(color: accent.withValues(alpha: 0.8), width: 1.6),
      ),
      child: Text(
        enDigits('$number'),
        style: bangla(fontSize: 20, fontWeight: FontWeight.w900, color: accent),
      ),
    );
  }
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({required this.lesson, required this.onTap});

  final LessonCardItem lesson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = lesson.isCompleted;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: SlmColors.navy950.withValues(alpha: 0.35),
              border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: done ? SlmGradients.gold : null,
                    color: done ? null : SlmColors.navy900,
                    border: Border.all(
                      color: done ? SlmColors.gold700 : SlmColors.gold400.withValues(alpha: 0.45),
                      width: 1.3,
                    ),
                  ),
                  child: done
                      ? const Icon(Icons.verified_rounded, color: SlmColors.navy950, size: 22)
                      : Text(
                          enDigits('${lesson.chapterNumber}'),
                          style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: SlmColors.gold200),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson.title,
                        style: bangla(fontSize: 15.5, fontWeight: FontWeight.w700, color: SlmColors.ivory),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        enDigits('পাঠ ${lesson.moduleNumber}.${lesson.chapterNumber}'),
                        style: bangla(fontSize: 12.5, fontWeight: FontWeight.w700, color: SlmColors.mist),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: SlmColors.navy900,
                    border: Border.all(color: SlmColors.gold400.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    done ? 'রিভিশন ↻' : 'পড়ুন',
                    style: bangla(fontSize: 12.5, fontWeight: FontWeight.w900, color: SlmColors.gold200),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OfflineNote extends StatelessWidget {
  const _OfflineNote({required this.text, required this.onRetry});

  final String text;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 40, color: SlmColors.gold300),
            const SizedBox(height: 10),
            Text(
              text,
              textAlign: TextAlign.center,
              style: bangla(fontSize: 15, fontWeight: FontWeight.w600, color: SlmColors.ivory),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'আবার চেষ্টা করুন',
                style: bangla(fontSize: 15, fontWeight: FontWeight.w800, color: SlmColors.gold300),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
