import 'package:flutter/material.dart';

import '../../core/en_digits.dart';
import '../../core/theme/app_theme.dart';
import '../../design/slm_design.dart';
import 'beat_fx.dart';
import 'content_catalog.dart';
import 'ladder_builder.dart';

/// Where a level sits in the climb, read from the catalog — never hard-coded.
/// A lesson has one Learn rung and any number of Do rungs (the catalog decides:
/// 1, 2, 4 …), so a Do level knows it is "কাজ k of N" for its own lesson.
@immutable
class LevelContext {
  const LevelContext({
    required this.rungId,
    required this.kind,
    required this.lessonId,
    required this.lessonTitleBn,
    required this.ladderStep,
    this.doIndex = 0,
    this.doCount = 0,
  });

  final String rungId;
  final CatalogRungKind kind;
  final String lessonId;
  final String lessonTitleBn;

  /// 1-based rung number on the ladder (what the player sees there).
  final int ladderStep;

  /// 1-based position among this lesson's Do rungs, and how many it has.
  final int doIndex;
  final int doCount;

  bool get isDo => kind == CatalogRungKind.doKind;
  bool get isGate => kind == CatalogRungKind.gate;

  /// Header chip, the same shape on every level: "পাঠ 1.1 · শেখা",
  /// "পাঠ 1.1 · কাজ 1/2", or "র‍্যাঙ্ক গেট".
  String get chipBn {
    if (isGate) return 'র‍্যাঙ্ক গেট';
    if (isDo) {
      return enDigits(doCount > 1 ? 'পাঠ $lessonId · কাজ $doIndex/$doCount' : 'পাঠ $lessonId · কাজ');
    }
    return enDigits('পাঠ $lessonId · শেখা');
  }
}

/// Context of the rung at ladder [index]; null when the ladder is not built.
LevelContext? levelContextAt(BuiltLadder? built, int index) {
  if (built == null || index < 0 || index >= built.length) return null;
  final rung = built.rungs[index];
  final lessonId = rung.def.lessonId ?? rung.lesson?.id ?? '';
  final dos = [
    for (final r in built.rungs)
      if (r.def.kind == CatalogRungKind.doKind && (r.def.lessonId ?? '') == lessonId && lessonId.isNotEmpty) r.id,
  ];
  return LevelContext(
    rungId: rung.id,
    kind: rung.def.kind,
    lessonId: lessonId,
    lessonTitleBn: rung.lesson?.titleBn ?? '',
    ladderStep: index + 1,
    doIndex: dos.indexOf(rung.id) + 1,
    doCount: dos.length,
  );
}

/// Context for a rung id (when only the saved current rung is known).
LevelContext? levelContextFor(BuiltLadder? built, String rungId) {
  if (built == null) return null;
  final i = built.rungs.indexWhere((r) => r.id == rungId);
  return i < 0 ? null : levelContextAt(built, i);
}

/// Rank of a finished Do play from its first-try mark (same words as before).
String doRankBn(int mark) => mark >= 90 ? 'দারুণ' : (mark >= 60 ? 'মোটামুটি' : 'আবার');

/// The one top bar every level uses (owner's brief): close · "ধাপ N" (the
/// ladder step — lesson and কাজ numbers are internal) · this level's score
/// (chips fly into it) · 💀 · an optional clock ([trailing]) · mute. The
/// title stays for screen readers only.
class LevelShellBar extends StatelessWidget {
  const LevelShellBar({
    super.key,
    required this.context_,
    required this.titleBn,
    required this.scoreKey,
    required this.levelScore,
    required this.muted,
    required this.onClose,
    required this.onToggleMute,
    this.deathKey,
    this.trailing,
    this.bare = false,
  });

  /// Float on a full-screen scene (no bar), as level 1.
  final bool bare;

  final LevelContext context_;
  final String titleBn;
  final GlobalKey scoreKey;
  final GlobalKey? deathKey;
  final int levelScore;
  final bool muted;
  final VoidCallback onClose;
  final VoidCallback onToggleMute;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: titleBn,
      child: UnifiedGameTopHud(
        scoreKey: scoreKey,
        deathKey: deathKey,
        badgeText: 'ধাপ ${context_.ladderStep}',
        titleText: titleBn,
        stepOnly: true,
      closeIcon: Icons.close_rounded,
      muted: muted,
      levelScore: levelScore,
      onClose: onClose,
        onToggleMute: onToggleMute,
        trailingExtra: trailing,
        bare: bare,
      ),
    );
  }
}

/// Three stars, the earned ones popping in one after another (once).
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.stars, this.size = 38});
  final int stars;
  final double size;

  @override
  Widget build(BuildContext context) {
    final quiet = MediaQuery.disableAnimationsOf(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: quiet || i >= stars ? 1 : 0, end: 1),
            duration: Duration(milliseconds: 420 + 260 * i),
            curve: Curves.elasticOut,
            builder: (_, t, child) => Transform.scale(scale: t.clamp(0.0, 1.4), child: child),
            child: Icon(
              i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
              size: i == 1 ? size + 8 : size,
              color: i < stars ? const Color(0xFFF2B632) : const Color(0x55A08A5A),
            ),
          ),
      ],
    );
  }
}

/// A passed Do play: rank, this play's score, time. Comes in once, then still.
class LevelPassPanel extends StatelessWidget {
  const LevelPassPanel({
    super.key,
    required this.mark,
    required this.levelScore,
    required this.totalDelta,
    required this.ms,
    required this.onNext,
    required this.onRetry,
    this.caughtBn = const [],
    this.quickBonus = false,
    this.stars,
  });

  /// Stars earned this play (1–3); null hides the row.
  final int? stars;

  /// Faults the player caught this play ("আজ যা ধরলেন").
  final List<String> caughtBn;

  /// A clean, quick play earned the "ঝটপট ও নির্ভুল" bonus.
  final bool quickBonus;

  final int mark;
  final int levelScore;

  /// Change to the main ◆ (the latest play replaced the last one).
  final int totalDelta;
  final int ms;
  final VoidCallback onNext;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final rank = doRankBn(mark);
    final s = (ms / 1000).round();
    final time = '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
    final delta = totalDelta == 0 ? 'মোট ◆ একই' : (totalDelta > 0 ? 'মোট ◆ +$totalDelta' : 'মোট ◆ $totalDelta');
    return SlmReveal(
      rise: 26,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        decoration: BoxDecoration(
          color: SlmColors.ivory,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 24, offset: Offset(0, 10))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (stars != null) ...[
              StarRow(stars: stars!),
              const SizedBox(height: 4),
            ],
            Text(rank, style: bangla(fontSize: 34, fontWeight: FontWeight.w900, color: SlmColors.gold700, height: 1.1)),
            const SizedBox(height: 6),
            Text(
              enDigits('নম্বর $mark% · সময় $time'),
              style: bangla(fontSize: 14, fontWeight: FontWeight.w700, color: SlmColors.ink),
            ),
            const SizedBox(height: 14),
            Text(
              enDigits('এই কাজে ◆ $levelScore'),
              style: bangla(fontSize: 22, fontWeight: FontWeight.w900, color: SlmColors.ink),
            ),
            Text(
              enDigits(delta),
              style: bangla(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF3A4660)),
            ),
            if (quickBonus) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: SlmColors.gold400, borderRadius: BorderRadius.circular(999)),
                child: Text(
                  enDigits('ঝটপট ও নির্ভুল · +10'),
                  style: bangla(fontSize: 13, fontWeight: FontWeight.w900, color: SlmColors.navy950),
                ),
              ),
            ],
            if (caughtBn.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text('আজ যা ধরলেন', style: bangla(fontSize: 13, fontWeight: FontWeight.w800, color: SlmColors.gold700)),
              const SizedBox(height: 6),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final c in caughtBn)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0x1AC0392B),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0x55C0392B)),
                      ),
                      child: Text(c, style: bangla(fontSize: 12.5, fontWeight: FontWeight.w700, color: SlmColors.ink)),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0x553A4660)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: onRetry,
                      child: Text('আবার খেলুন', style: bangla(fontSize: 15, fontWeight: FontWeight.w700, color: SlmColors.ink)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: SlmColors.gold700,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: onNext,
                      child: Text('পরের ধাপ', style: bangla(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
