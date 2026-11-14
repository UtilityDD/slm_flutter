import 'dart:math' as math;

import '../game/game_save.dart';
import '../game/ladder_builder.dart';

// Where the climb stands, shared by the ladder (adventure_map.dart) and Home
// (home_screen.dart), so Home's "L<n>" is always the rung the ladder opens on.

/// Rungs the ladder draws as playable before the catalog has loaded (today's
/// playable prefix: Modules 1–5). Only drawing: rung taps wait for the catalog.
const ladderFallbackSpan = 150;

/// The contiguous playable prefix of the ladder (stops at the first Coming Soon).
int ladderPlayableSpan(BuiltLadder? built) {
  if (built == null) return ladderFallbackSpan;
  var n = 0;
  for (final r in built.rungs) {
    if (r.isComingSoon) break;
    n++;
  }
  return math.max(n, 1);
}

/// The player's current ladder rung: the engine's [unlocked] counter, moved
/// back to the first Do rung to prove again after a death, then on past every
/// cleared rung in `GameSave.rungProgress`.
int ladderFocus(BuiltLadder? built, GameSave save, int unlocked) {
  final len = built?.length ?? math.max(ladderFallbackSpan, 40);
  final maxPlayable = math.min(len, ladderPlayableSpan(built));
  var focus = unlocked.clamp(0, math.max(0, maxPlayable - 1)).toInt();
  if (built != null) {
    // After a death (fall option C) the climb resumes at the first Do level
    // to prove again, whatever the old unlock counter says.
    final prove = built.rungs.indexWhere((r) => save.rungProgress[r.id] == 'prove');
    if (prove >= 0 && prove < focus) focus = prove;
    for (var i = 0; i < maxPlayable; i++) {
      final r = built.rungs[i];
      final cleared = save.rungProgress[r.id] == 'cleared';
      if (cleared && i >= focus) {
        focus = (i + 1).clamp(0, math.max(0, maxPlayable - 1)).toInt();
      } else if (!cleared && i >= focus) {
        break;
      }
    }
  }
  return focus;
}

/// The sudden chests ("হঠাৎ উপহার") waiting on the ladder, by ladder index:
/// each stands one rung above the rung whose first clear dropped it
/// (game_save.dart: toolboxChestDrop). Claimed ones are left out.
Map<int, PendingChest> chestsByLadderIndex(BuiltLadder? built, GameSave save) {
  final chests = save.toolbox.chests;
  if (built == null || chests.isEmpty) return const {};
  final out = <int, PendingChest>{};
  for (final c in chests) {
    if (save.giftsClaimed.contains(c.claimId)) continue;
    final at = built.rungs.indexWhere((r) => r.id == c.rungId);
    if (at < 0) continue;
    final beside = math.min(at + 1, built.length - 1);
    out.putIfAbsent(beside, () => c);
  }
  return out;
}

/// What Home's "continue" card shows: the next rung and its module's progress.
class LadderNext {
  const LadderNext({
    required this.index,
    required this.step,
    required this.module,
    required this.cleared,
    required this.total,
    required this.stars,
    required this.starsMax,
    required this.allDone,
  });

  /// Ladder index of the rung (what [DutySlipEngine.ladderAnchor] takes).
  final int index;

  /// `L<step>`, as the level's top bar (`LevelContext.ladderStep`).
  final int step;

  /// Module number (the catalog module's order: 1, 2 …).
  final int module;

  /// Rungs of that module the ladder shows as cleared, of [total].
  final int cleared;
  final int total;

  /// Best stars earned on the module's rungs, of [starsMax] (3 per Do/gate rung).
  final int stars;
  final int starsMax;

  /// Every open rung is cleared: nothing new to play yet.
  final bool allDone;
}

/// The card for [focus] (from [ladderFocus]). Cleared counts the way the
/// ladder's coins do: a saved clear, or any playable rung below the focus,
/// never one waiting to be proved again.
LadderNext ladderNext(BuiltLadder built, GameSave save, int focus) {
  final i = focus.clamp(0, built.length - 1).toInt();
  final rung = built.rungs[i];
  var cleared = 0, total = 0, stars = 0, starsMax = 0;
  for (var j = 0; j < built.length; j++) {
    final r = built.rungs[j];
    if (r.module.id != rung.module.id) continue;
    total++;
    final state = save.rungProgress[r.id];
    if (state != 'prove' && (state == 'cleared' || (!r.isComingSoon && j < i))) cleared++;
    if (!r.isLearn) starsMax += 3;
    stars += (save.starsByRung[r.id] ?? 0).clamp(0, 3).toInt();
  }
  final last = ladderPlayableSpan(built) - 1;
  return LadderNext(
    index: i,
    step: i + 1,
    module: rung.module.order,
    cleared: cleared,
    total: total,
    stars: stars,
    starsMax: starsMax,
    allDone: i >= last && save.rungProgress[rung.id] == 'cleared',
  );
}
