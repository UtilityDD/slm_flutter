import 'package:flutter/foundation.dart';

import 'mistake_kit.dart';

// The "order" move: steps come in groups; inside a group any order is fine
// (R, Y, B), but a group must be finished before anything of a later group is
// touched. Touching a later step early is the group's mistake (or a
// target-specific one, e.g. the chain before the earth). Trap targets are
// always a mistake (a rusty earth point). Pure logic: no widgets, no timers.

/// One group of steps that may be done in any order.
@immutable
class OrderGroup {
  const OrderGroup(this.ids, {required this.skipMistake, this.earlyBy = const {}});

  final List<String> ids;

  /// Touching a later step while this group is unfinished.
  final DoMistake skipMistake;

  /// Per later target, a more exact mistake than [skipMistake].
  final Map<String, DoMistake> earlyBy;
}

/// One round: what the player must put in order.
@immutable
class OrderRoundSpec {
  const OrderRoundSpec({required this.groups, this.traps = const {}});

  final List<OrderGroup> groups;

  /// Targets that are always wrong, with their mistake.
  final Map<String, DoMistake> traps;

  int get stepCount => groups.fold(0, (n, g) => n + g.ids.length);

  int? groupOf(String id) {
    for (var i = 0; i < groups.length; i++) {
      if (groups[i].ids.contains(id)) return i;
    }
    return null;
  }
}

enum OrderTapKind { ok, ignored, mistake }

@immutable
class OrderTap {
  const OrderTap(this.kind, {this.mistake, this.roundDone = false, this.allDone = false});

  final OrderTapKind kind;
  final DoMistake? mistake;
  final bool roundDone;
  final bool allDone;
}

/// The play state of an order level.
class OrderRun {
  OrderRun(this.rounds) : assert(rounds.isNotEmpty);

  final List<OrderRoundSpec> rounds;
  int round = 0;
  final Set<String> _done = {};
  final List<String> doneOrder = [];

  /// Slips (non-deadly mistakes) in this play.
  int slips = 0;

  /// Set when a deadly mistake ended the play.
  DoMistake? deadly;

  bool get done => round >= rounds.length;
  bool get ended => done || deadly != null;
  OrderRoundSpec get spec => rounds[round.clamp(0, rounds.length - 1)];
  bool isDone(String id) => _done.contains(id);

  /// Steps done in the current round.
  int get stepsDone => _done.length;

  int get percent => (100 - 15 * slips).clamp(0, 100);
  bool get passed => done && deadly == null && percent >= 55;

  OrderTap tap(String id) {
    if (ended || _done.contains(id)) return const OrderTap(OrderTapKind.ignored);
    final s = spec;
    final trap = s.traps[id];
    if (trap != null) return _mistake(trap);
    final g = s.groupOf(id);
    if (g == null) return const OrderTap(OrderTapKind.ignored);
    for (var i = 0; i < g; i++) {
      final open = s.groups[i].ids.any((x) => !_done.contains(x));
      if (open) return _mistake(s.groups[i].earlyBy[id] ?? s.groups[i].skipMistake);
    }
    _done.add(id);
    doneOrder.add(id);
    if (_done.length < s.stepCount) return const OrderTap(OrderTapKind.ok);
    round++;
    _done.clear();
    return OrderTap(OrderTapKind.ok, roundDone: true, allDone: done);
  }

  /// A deadly answer outside the board (e.g. giving in to a pressure call).
  void failDeadly(DoMistake m) => deadly = m;

  OrderTap _mistake(DoMistake m) {
    if (m.deadly) {
      deadly = m;
    } else {
      slips++;
    }
    return OrderTap(OrderTapKind.mistake, mistake: m);
  }
}
