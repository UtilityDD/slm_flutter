import 'dart:math' as math;

import 'learn_board_models.dart';

/// Deals cards from a question's pool so replays look different and a miss
/// brings in something new. Pure logic; the runner owns animation and sound.
class LearnDealer {
  LearnDealer([math.Random? rng]) : _rng = rng ?? math.Random();

  final math.Random _rng;

  /// Ids dealt last time per question key (this app session), so the next
  /// run leads with items the player hasn't just seen.
  static final Map<String, Set<String>> _recent = {};

  static void resetMemory() => _recent.clear();

  /// One correct pick plus up to [count] − 1 traps, in random order.
  List<T> deal<T extends LearnPick>(String key, List<T> pool, {required int count}) {
    final recent = _recent[key] ?? const <String>{};
    final safe = _freshFirst(pool.where((p) => p.correct).toList(), recent);
    final traps = _freshFirst(pool.where((p) => !p.correct).toList(), recent);
    final hand = <T>[
      if (safe.isNotEmpty) safe.first,
      ...traps.take(math.max(0, count - 1)),
    ]..shuffle(_rng);
    _recent[key] = {for (final p in hand) p.id};
    return hand;
  }

  /// After [missed] was tapped: replace it with a trap not yet [seen] in this
  /// question (when the pool has one), show a different picture of the
  /// correct item (so its look can't be memorised), then reshuffle.
  List<T> afterMiss<T extends LearnPick>(
    List<T> hand,
    T missed,
    List<T> pool,
    Set<String> seen,
  ) {
    final inHand = {for (final p in hand) p.id};
    final fresh = pool.where((p) => !p.correct && !seen.contains(p.id) && !inHand.contains(p.id)).toList();
    final otherSafe = _freshFirst(
      pool.where((p) => p.correct && !inHand.contains(p.id)).toList(),
      seen,
    );
    final next = [
      for (final p in hand)
        if (p.id == missed.id && fresh.isNotEmpty)
          fresh[_rng.nextInt(fresh.length)]
        else if (p.correct && otherSafe.isNotEmpty)
          otherSafe.first
        else
          p,
    ];
    if (next.length < 2) return next;
    final before = [for (final p in next) p.id].join('|');
    for (var i = 0; i < 6; i++) {
      next.shuffle(_rng);
      if ([for (final p in next) p.id].join('|') != before) break;
    }
    return next;
  }

  List<T> _freshFirst<T extends LearnPick>(List<T> items, Set<String> recent) {
    items.shuffle(_rng);
    return [
      ...items.where((p) => !recent.contains(p.id)),
      ...items.where((p) => recent.contains(p.id)),
    ];
  }
}
