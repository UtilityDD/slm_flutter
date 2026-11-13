import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import '../home/lesson_reader_page.dart';
import '../training/training_models.dart';
import '../training/training_provider.dart';
import 'game_save.dart';
import 'level_shell.dart';

// Shared by every Do level built on the five moves (choose, inspect, spot,
// order, say no): one mistake = one picture + one line + "পাঠে দেখুন", and
// it goes into "আমার ভুলের খাতা". A deadly mistake ends the play: the very
// first one in the game is a near-miss (no death, no fall); after that it is
// a death and the Do levels passed since the last death must be proven again.

/// One mistake a level can catch.
@immutable
class DoMistake {
  const DoMistake({
    required this.key,
    required this.textBn,
    required this.art,
    this.deadly = false,
    this.lessonPoint,
  });

  /// Stable id, e.g. `1.5/discharge/line-before-earth` (mistakes book, voice once).
  final String key;

  /// The one line under the picture (also read aloud the first time).
  final String textBn;

  /// SVG (or WebP) that shows the mistake and the right way side by side.
  final String art;
  final bool deadly;

  /// 0-based lesson point that teaches it; null = no "পাঠে দেখুন".
  final int? lessonPoint;
}

enum MistakeTone { slip, nearMiss, deadly }

abstract final class MistakeLines {
  static const slipHead = 'ভুল হলো';
  static const nearMissHead = 'অল্পের জন্য বাঁচলেন!';
  static const nearMissSub = 'মাঠে এই ভুলে প্রাণ যায়। এবার শুধু সতর্কবার্তা — পরের বার আর নয়।';
  static const deadlyHead = 'মারাত্মক ভুল';
  static const deadlySub = 'মাঠে এখানেই শেষ। শেষ মৃত্যুর পরে পাস করা কাজগুলো আবার প্রমাণ করতে হবে।';
  static const readLesson = 'পাঠে দেখুন';
  static const gotIt = 'বুঝেছি';
  static const tryAgain = 'আবার চেষ্টা';
  static const toLadder = 'মইয়ে ফিরুন';
  static const offline = 'পাঠটা এখন খোলা যাচ্ছে না। ইন্টারনেট চালু করে আবার চেষ্টা করুন।';
}

/// The real lesson (live or the saved copy) for an id like `1.5`; null when
/// it can't be loaded (never waits forever: the provider retries offline).
Future<LessonCardItem?> findLessonById(WidgetRef ref, String lessonId) async {
  final parts = lessonId.split('.');
  final module = int.tryParse(parts.first) ?? 1;
  final chapter = parts.length > 1 ? (int.tryParse(parts[1]) ?? 1) : 1;
  try {
    final lessons = await ref.read(moduleLessonsProvider(module).future).timeout(const Duration(seconds: 12));
    for (final l in lessons) {
      if (l.chapterNumber == chapter && l.points.isNotEmpty) return l;
    }
  } catch (_) {}
  return null;
}

/// Opens the lesson reader at [point]; returns when the level is on top again.
/// Offline (lesson not loadable): a short note, nothing opens.
Future<void> openLessonPoint(
  BuildContext context,
  WidgetRef ref, {
  required String lessonId,
  int? point,
  bool muted = false,
}) async {
  HapticFeedback.selectionClick();
  final lesson = await findLessonById(ref, lessonId);
  if (!context.mounted) return;
  if (lesson == null) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: SlmColors.navy900,
        content: Text(MistakeLines.offline, style: bangla(fontSize: 14, fontWeight: FontWeight.w700, color: SlmColors.ivory)),
      ),
    );
    return;
  }
  await Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => LessonReaderPage(lesson: lesson, bn: true, muted: muted, startPoint: point)),
  );
  // The reader hands over to its seal page; wait until the level is on top again.
  while (context.mounted && !(ModalRoute.of(context)?.isCurrent ?? true)) {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }
}

/// `1.5` -> `1.1/learn`: the module base a death is counted against.
String moduleFirstRungOf(String lessonId) => '${lessonId.split('.').first}.1/learn';

/// What a deadly mistake costs in this play.
enum DeadlyOutcome { nearMiss, death }

/// Books a mistake; for a deadly one also decides near-miss or death. The
/// death itself is recorded by [recordDoDeath] when the level is left, so the
/// ladder's fall moment plays in view.
Future<DeadlyOutcome?> bookMistake(WidgetRef ref, LevelContext ctx, DoMistake m) async {
  final save = ref.read(gameSaveProvider.notifier);
  await save.addMistake(
    key: m.key,
    lessonId: ctx.lessonId,
    rungId: ctx.rungId,
    textBn: m.textBn,
    deadly: m.deadly,
    lessonPoint: m.lessonPoint,
  );
  if (!m.deadly) return null;
  return await save.useNearMiss() ? DeadlyOutcome.nearMiss : DeadlyOutcome.death;
}

/// Records the death of a Do level (call with the notifier read while mounted).
Future<void> recordDoDeath(GameSaveController save, LevelContext ctx, DoMistake m) => save.recordLethalDeath(
      cause: m.textBn,
      lessonId: ctx.lessonId,
      rungId: ctx.rungId,
      moduleFirstRungId: moduleFirstRungOf(ctx.lessonId),
    );

/// Deaths for a Do level page: book a deadly mistake (near-miss or death),
/// keep the death pending while the card is up, and record it once when the
/// level is left — or when the page goes away any other way.
mixin DoDeathGuard<T extends ConsumerStatefulWidget> on ConsumerState<T> {
  LevelContext get deathCtx;

  GameSaveController? _guardSave;
  DoMistake? _fatal;
  var _deathPending = false;
  var _deathRecorded = false;

  /// A death waits to be recorded (back / close must go through [dieAndLeave]).
  bool get deathPending => _deathPending;

  /// Books a deadly mistake. The latest play counts: a death leaves 0 for this
  /// level; a near-miss keeps [runScore].
  Future<DeadlyOutcome> bookDeadly(DoMistake m, {required int runScore}) async {
    final save = ref.read(gameSaveProvider.notifier);
    final ctx = deathCtx;
    _guardSave = save;
    _fatal = m;
    final outcome = await bookMistake(ref, ctx, m) ?? DeadlyOutcome.death;
    final death = outcome == DeadlyOutcome.death;
    await save.recordLevelResult(ctx.rungId, 0);
    await save.commitLevelScore(ctx.rungId, death ? 0 : runScore);
    if (death) {
      if (mounted) {
        _deathPending = true;
      } else if (!_deathRecorded) {
        _deathRecorded = true;
        unawaited(recordDoDeath(save, ctx, m));
      }
    }
    return outcome;
  }

  /// Leaves the level and records the pending death (once), so the ladder's
  /// fall moment plays in view.
  Future<void> dieAndLeave() async {
    final save = _guardSave;
    final m = _fatal;
    final record = _deathPending && !_deathRecorded && save != null && m != null;
    _deathRecorded = _deathRecorded || record;
    if (mounted) Navigator.of(context).pop(false);
    if (record) await recordDoDeath(save, deathCtx, m);
  }

  @override
  void dispose() {
    final save = _guardSave;
    final m = _fatal;
    if (_deathPending && !_deathRecorded && save != null && m != null) {
      _deathRecorded = true;
      unawaited(recordDoDeath(save, deathCtx, m));
    }
    super.dispose();
  }
}

/// The mistake card over a level: picture, one line, "পাঠে দেখুন" and the
/// way on (continue, try again, or back to the ladder).
class MistakeCard extends StatelessWidget {
  const MistakeCard({
    super.key,
    required this.mistake,
    required this.tone,
    required this.quiet,
    required this.onRead,
    required this.onGo,
    this.goLabel,
  });

  final DoMistake mistake;
  final MistakeTone tone;
  final bool quiet;

  /// Null hides "পাঠে দেখুন" (no lesson point).
  final VoidCallback? onRead;
  final VoidCallback onGo;
  final String? goLabel;

  @override
  Widget build(BuildContext context) {
    final deadly = tone == MistakeTone.deadly;
    final near = tone == MistakeTone.nearMiss;
    final edge = deadly ? SlmColors.danger : (near ? SlmColors.warning : SlmColors.gold500);
    final head = deadly ? MistakeLines.deadlyHead : (near ? MistakeLines.nearMissHead : MistakeLines.slipHead);
    final go = goLabel ?? (deadly ? MistakeLines.toLadder : (near ? MistakeLines.tryAgain : MistakeLines.gotIt));
    final art = mistake.art.endsWith('.svg')
        ? SvgPicture.asset(mistake.art, fit: BoxFit.contain)
        : Image.asset(mistake.art, fit: BoxFit.contain);
    // The card stays on until the player's button (no timer ever closes it).
    // It always fits the screen: the picture shrinks on a short screen, the
    // words scroll inside if long, and the buttons stay in reach (320×568,
    // landscape).
    final mq = MediaQuery.of(context);
    final maxH = (mq.size.height - mq.padding.vertical - 32).clamp(200.0, double.infinity);
    final artMaxH = mq.size.height * 0.3;
    return Positioned.fill(
      child: ColoredBox(
        color: deadly ? const Color(0xD9200608) : const Color(0xC0050A16),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: quiet ? 1 : 0, end: 1),
            duration: Duration(milliseconds: deadly ? 650 : 420),
            curve: Curves.easeOutBack,
            builder: (_, t, child) => Opacity(
              opacity: t.clamp(0.0, 1.0),
              child: Transform.scale(scale: 0.88 + 0.12 * t, child: child),
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              constraints: BoxConstraints(maxWidth: 420, maxHeight: maxH),
              decoration: BoxDecoration(
                color: SlmColors.ivory,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: edge, width: 3),
                boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 24, offset: Offset(0, 10))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (deadly || near) Text(deadly ? '💀' : '⚡', style: const TextStyle(fontSize: 22)),
                      if (deadly || near) const SizedBox(width: 6),
                      Flexible(
                        child: Text(head, style: bangla(fontSize: 18, fontWeight: FontWeight.w900, color: edge)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: SingleChildScrollView(
                      key: const ValueKey('mistake-card-scroll'),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(maxHeight: artMaxH),
                            child: AspectRatio(aspectRatio: 1.6, child: art),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            mistake.textBn,
                            textAlign: TextAlign.center,
                            style: bangla(fontSize: 16.5, fontWeight: FontWeight.w800, color: SlmColors.ink, height: 1.4),
                          ),
                          if (deadly || near) ...[
                            const SizedBox(height: 6),
                            Text(
                              deadly ? MistakeLines.deadlySub : MistakeLines.nearMissSub,
                              textAlign: TextAlign.center,
                              style: bangla(fontSize: 12.5, fontWeight: FontWeight.w700, color: const Color(0xFF5A4636), height: 1.35),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      if (onRead != null) ...[
                        Expanded(
                          child: _CardButton(label: MistakeLines.readLesson, filled: false, onTap: onRead!),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(child: _CardButton(label: go, filled: true, onTap: onGo)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardButton extends StatelessWidget {
  const _CardButton({required this.label, required this.filled, required this.onTap});
  final String label;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? SlmColors.navy800 : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: SlmColors.navy800, width: filled ? 0 : 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: filled ? SlmColors.ivory : SlmColors.navy800),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
