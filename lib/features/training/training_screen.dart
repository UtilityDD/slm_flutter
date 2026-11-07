import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/en_digits.dart';
import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../admin/dev_unlock.dart';
import '../auth/auth_provider.dart';
import '../auth/verify_gate.dart';
import '../auth/verify_hold.dart';
import '../auth/verify_sheet.dart';
import '../auth/verify_tick.dart';
import '../home/lesson_reader_page.dart';
import '../shell/shell_insets.dart';
import 'training_models.dart';
import 'training_provider.dart';

/// প্রশিক্ষণ জোন: modules and their lessons. Progress is shown as seals, not points.
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
    final ladderAsync = ref.watch(trainingLadderProvider);

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
            'প্রশিক্ষণ জোন',
            style: bangla(fontSize: 19, fontWeight: FontWeight.w900, color: SlmColors.gold200),
          ),
        ),
        body: ladderAsync.when(
          loading: () => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(strokeWidth: 3, color: SlmColors.gold300),
                const SizedBox(height: 16),
                Text('পাঠ সাজানো হচ্ছে...', style: bangla(fontSize: 16, fontWeight: FontWeight.w600, color: SlmColors.ivory)),
              ],
            ),
          ),
          error: (e, _) => _OfflineNote(
            text: 'পাঠ লোড করা যায়নি। ইন্টারনেট চালু করে আবার চেষ্টা করুন।',
            onRetry: () => ref.invalidate(trainingLadderProvider),
          ),
          data: (modules) {
            if (!_autoOpened) {
              _autoOpened = true;
              final active = modules.where((m) => m.isActive).firstOrNull ?? modules.firstOrNull;
              _expandedModuleNumber = active?.moduleNumber;
            }
            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(16, 8, 16, shellDockBottomInset(context) + 16),
              itemCount: modules.length,
              itemBuilder: (context, index) => _moduleCard(modules[index]),
            );
          },
        ),
      ),
    );
  }

  void _onModuleTap(TrainingModuleItem item, bool isExpanded) {
    final seal = lessonNeedsVerify(
      ref.read(authProvider),
      ref.read(verifyHoldProvider),
      ref.read(devUnlockProvider),
      item.moduleNumber,
    );
    if (seal) {
      showVerifySheet(context);
      return;
    }
    if (item.isLocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'আগের অধ্যায় শেষ করে এই পাঠ খুলুন।',
            style: bangla(fontSize: 15, fontWeight: FontWeight.w600, color: SlmColors.ivory),
          ),
          backgroundColor: SlmColors.navy900,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _expandedModuleNumber = isExpanded ? null : item.moduleNumber);
  }

  Widget _moduleCard(TrainingModuleItem item) {
    final isExpanded = _expandedModuleNumber == item.moduleNumber;
    final needsVerify = lessonNeedsVerify(
      ref.watch(authProvider),
      ref.watch(verifyHoldProvider),
      ref.watch(devUnlockProvider),
      item.moduleNumber,
    );
    final (accent, status) = switch (item.status) {
      LadderStepStatus.completed => (SlmColors.emerald300, 'সম্পন্ন'),
      LadderStepStatus.active => (SlmColors.gold300, 'চলছে'),
      LadderStepStatus.locked => (SlmColors.mist, 'পরে'),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AnimatedContainer(
        duration: SlmMotion.base,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: item.isLocked
                ? const [Color(0xFF141D33), Color(0xFF0D1426)]
                : const [Color(0xFF1E2D4B), Color(0xFF111A30)],
          ),
          border: Border.all(
            color: item.isActive ? SlmColors.gold400 : accent.withValues(alpha: item.isLocked ? 0.25 : 0.5),
            width: item.isActive ? 1.8 : 1.1,
          ),
          boxShadow: item.isActive
              ? [BoxShadow(color: SlmColors.gold400.withValues(alpha: 0.25), blurRadius: 20)]
              : const [],
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _onModuleTap(item, isExpanded),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    _StepBadge(number: item.moduleNumber, accent: accent, locked: item.isLocked),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                status,
                                style: bangla(fontSize: 12, fontWeight: FontWeight.w800, color: accent),
                              ),
                              const Spacer(),
                              if (needsVerify) const VerifyTick(size: 20),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.title,
                            style: bangla(fontSize: 17, fontWeight: FontWeight.w800, color: SlmColors.ivory),
                          ),
                          const SizedBox(height: 8),
                          _SealStrip(done: item.completedLessons, total: item.totalLessons),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (!item.isLocked)
                      AnimatedRotation(
                        turns: isExpanded ? 0.5 : 0,
                        duration: SlmMotion.base,
                        child: Icon(Icons.expand_more_rounded, color: accent),
                      )
                    else
                      const Icon(Icons.lock_rounded, size: 20, color: SlmColors.mist),
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
                        _lessonsList(item.moduleNumber),
                      ],
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lessonsList(int moduleNumber) {
    final lessonsAsync = ref.watch(moduleLessonsProvider(moduleNumber));
    return lessonsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.5, color: SlmColors.gold300)),
      ),
      error: (e, _) => _OfflineNote(
        text: 'পাঠগুলো এখন আনা যাচ্ছে না। ইন্টারনেট চালু করে আবার চেষ্টা করুন।',
        onRetry: () => ref.invalidate(moduleLessonsProvider(moduleNumber)),
      ),
      data: (lessons) {
        if (lessons.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'এই ধাপে কোনো সক্রিয় পাঠ পাওয়া যায়নি।',
              style: bangla(fontSize: 14, fontWeight: FontWeight.w600, color: SlmColors.mist),
            ),
          );
        }
        final nextIdx = lessons.indexWhere((l) => !l.isCompleted);
        return Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
          child: Column(
            children: [
              for (var i = 0; i < lessons.length; i++)
                _LessonRow(
                  lesson: lessons[i],
                  isNext: i == nextIdx,
                  onTap: () => Navigator.of(context).push(
                    SlmPageRoute<void>(builder: (_) => LessonReaderPage(lesson: lessons[i], bn: true)),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.number, required this.accent, required this.locked});

  final int number;
  final Color accent;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: locked ? 0.08 : 0.16),
        border: Border.all(color: accent.withValues(alpha: locked ? 0.3 : 0.8), width: 1.6),
      ),
      child: Text(
        enDigits('$number'),
        style: bangla(fontSize: 20, fontWeight: FontWeight.w900, color: accent),
      ),
    );
  }
}

/// One small seal per lesson in the step: gold when earned.
class _SealStrip extends StatelessWidget {
  const _SealStrip({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < total; i++)
          Icon(
            i < done ? Icons.verified_rounded : Icons.circle_outlined,
            size: 16,
            color: i < done ? SlmColors.gold300 : SlmColors.mist.withValues(alpha: 0.5),
          ),
        const SizedBox(width: 2),
        Text(
          enDigits('$done/$total সিল'),
          style: bangla(fontSize: 12, fontWeight: FontWeight.w700, color: SlmColors.mist),
        ),
      ],
    );
  }
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({required this.lesson, required this.isNext, required this.onTap});

  final LessonCardItem lesson;
  final bool isNext;
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
              color: isNext ? SlmColors.gold400.withValues(alpha: 0.1) : SlmColors.navy950.withValues(alpha: 0.35),
              border: Border.all(
                color: isNext ? SlmColors.gold400.withValues(alpha: 0.7) : SlmColors.gold400.withValues(alpha: 0.12),
              ),
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
                        enDigits(
                          'পাঠ ${lesson.moduleNumber}.${lesson.chapterNumber}'
                          '${done ? ' · সিল পেয়েছেন' : ''}',
                        ),
                        style: bangla(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: done ? SlmColors.gold300 : SlmColors.mist,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: isNext ? SlmGradients.gold : null,
                    color: isNext ? null : SlmColors.navy900,
                    border: Border.all(color: SlmColors.gold400.withValues(alpha: isNext ? 0 : 0.35)),
                  ),
                  child: Text(
                    done ? 'রিভিশন ↻' : (isNext ? 'এখান থেকে 👉' : 'পড়ুন'),
                    style: bangla(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      color: isNext ? SlmColors.navy950 : SlmColors.gold200,
                    ),
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
