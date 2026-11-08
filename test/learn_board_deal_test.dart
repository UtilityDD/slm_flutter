import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:slm_flutter/features/game/learn_board_deal.dart';
import 'package:slm_flutter/features/game/learn_board_models.dart';

LearnBoardOption _o(String id, {bool ok = false}) =>
    LearnBoardOption(id: id, labelBn: id, asset: '', correct: ok);

void main() {
  setUp(LearnDealer.resetMemory);

  final pool = [
    _o('safe', ok: true),
    _o('safe2', ok: true),
    for (var i = 0; i < 6; i++) _o('trap$i'),
  ];

  test('a hand has exactly one safe card and count - 1 traps', () {
    final d = LearnDealer(math.Random(1));
    for (var run = 0; run < 20; run++) {
      final hand = d.deal('q', pool, count: 4);
      expect(hand, hasLength(4));
      expect(hand.where((p) => p.correct), hasLength(1));
      expect({for (final p in hand) p.id}, hasLength(4));
    }
  });

  test('the next run leads with traps not dealt last time', () {
    final d = LearnDealer(math.Random(2));
    final first = {for (final p in d.deal('q', pool, count: 4)) p.id};
    final second = {for (final p in d.deal('q', pool, count: 4)) p.id};
    expect(second.intersection(first), isEmpty);
  });

  test('a miss swaps in an unseen trap and reorders the board', () {
    final d = LearnDealer(math.Random(3));
    final hand = d.deal('q', pool, count: 4);
    final seen = {for (final p in hand) p.id};
    final missed = hand.firstWhere((p) => !p.correct);
    final next = d.afterMiss(hand, missed, pool, seen);
    expect(next, hasLength(4));
    expect(next.map((p) => p.id), isNot(contains(missed.id)));
    expect(next.where((p) => p.correct), hasLength(1));
    final freshTraps = next.where((p) => !p.correct && !seen.contains(p.id));
    expect(freshTraps, hasLength(1));
  });

  test('a miss also shows a different picture of the correct item', () {
    final d = LearnDealer(math.Random(5));
    final hand = d.deal('q', pool, count: 4);
    final safeBefore = hand.firstWhere((p) => p.correct).id;
    final next = d.afterMiss(hand, hand.firstWhere((p) => !p.correct), pool, {for (final p in hand) p.id});
    final safeAfter = next.where((p) => p.correct).toList();
    expect(safeAfter, hasLength(1));
    expect(safeAfter.single.id, isNot(safeBefore));
  });

  test('with no unseen traps left, a miss only reshuffles', () {
    final small = [_o('s', ok: true), _o('a'), _o('b')];
    final d = LearnDealer(math.Random(4));
    final hand = d.deal('q', small, count: 3);
    final next = d.afterMiss(hand, hand.firstWhere((p) => !p.correct), small, {'s', 'a', 'b'});
    expect({for (final p in next) p.id}, {'s', 'a', 'b'});
    expect([for (final p in next) p.id], isNot([for (final p in hand) p.id]));
  });

  test('every picture pack can deal full hands and its art exists', () {
    _checkPack(learnBoardPack11);
    // Ladder step 4 (lesson 1.2) is a picture board too.
    _checkPack(learnBoardPack12);
  });
}

void _checkPack(LearnBoardPack pack) {
    void checkPool(String where, List<LearnPick> items, int count) {
      expect({for (final p in items) p.id}, hasLength(items.length), reason: '$where: duplicate id');
      expect(items.where((p) => p.correct), isNotEmpty, reason: '$where: no correct item');
      expect(items.where((p) => !p.correct).length, greaterThanOrEqualTo(count - 1),
          reason: '$where: too few traps for $count cards');
    }

    for (final s in pack.slots) {
      checkPool(s.id, s.options, s.cards);
      expect(s.options.where((p) => p.correct).length, greaterThanOrEqualTo(2),
          reason: '${pack.lessonId}/${s.id}: need two correct pictures');
      checkPool('${s.id}/why', s.whyChips, s.whyCards);
      for (final o in s.options) {
        expect(File(o.asset).existsSync(), isTrue, reason: 'missing ${o.asset}');
        if (!o.correct) expect(o.rejectBn.trim(), isNotEmpty, reason: '${s.id}/${o.id}: no reason');
      }
    }
    checkPool('myth/why', pack.myth.whyChips, 3);
    expect(pack.slots.length, greaterThanOrEqualTo(3), reason: pack.lessonId);
  }
