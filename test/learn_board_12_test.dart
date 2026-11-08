// Ladder step 4 — the lesson 1.2 picture board ("লক্ষ্মণ রেখা"): its content
// follows the board's rules and the lesson's distances; every picture exists.
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:slm_flutter/features/game/learn_board_deal.dart';
import 'package:slm_flutter/features/game/learn_board_models.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';

void main() {
  setUp(LearnDealer.resetMemory);
  const pack = learnBoardPack12;

  test('step 4 opens the lesson 1.2 picture board', () {
    expect(learnBoardPackFor('1.2'), same(learnBoardPack12));
    expect(learnBoardPackFor('1.1'), same(learnBoardPack11));
    expect(pack.lessonId, '1.2');
  });

  test('every round: safe pictures and enough traps; reasons with right and wrong', () {
    for (final s in pack.slots) {
      final safe = s.options.where((o) => o.correct).length;
      final traps = s.options.where((o) => !o.correct).length;
      expect(safe, greaterThanOrEqualTo(1), reason: '${s.id}: a safe picture');
      expect(traps, greaterThanOrEqualTo(s.cards - 1), reason: '${s.id}: enough traps for a hand');
      expect(s.options.map((o) => o.id).toSet().length, s.options.length, reason: '${s.id}: unique ids');
      for (final o in s.options.where((o) => !o.correct)) {
        expect(o.rejectBn, isNotEmpty, reason: '${s.id}/${o.id}: a trap says why');
      }
      expect(s.whyChips.where((w) => w.correct).length, greaterThanOrEqualTo(1), reason: '${s.id}: a right reason');
      expect(s.whyChips.where((w) => !w.correct).length, greaterThanOrEqualTo(s.whyCards - 1), reason: '${s.id}: wrong reasons');
    }
    expect(pack.myth.believeNoIsCorrect, isTrue, reason: 'the myth is false: arc flash jumps');
    expect(pack.myth.whyChips.where((w) => w.correct), isNotEmpty);
  });

  test('a dealt hand has exactly one safe picture', () {
    final d = LearnDealer(math.Random(7));
    for (final s in pack.slots) {
      for (var run = 0; run < 10; run++) {
        final hand = d.deal(s.id, s.options, count: s.cards);
        expect(hand.where((p) => p.correct), hasLength(1), reason: s.id);
      }
    }
  });

  test('the lesson\'s numbers: 11 kV at least 2.5 m, rain 10–12 ft, LT 1.2 m only for LT', () {
    final gap = pack.slots.firstWhere((s) => s.id == 'gap11');
    expect(gap.whyChips.firstWhere((w) => w.correct).textBn, contains('2.5'));
    expect(gap.options.firstWhere((o) => o.id == 'lt').rejectBn, contains('1.2'));
    final rain = pack.slots.firstWhere((s) => s.id == 'rain');
    expect(rain.whyChips.any((w) => w.correct && w.textBn.contains('10–12')), isTrue);
  });

  test('every picture exists (vector scenes from tool/lakshman_art.py)', () {
    for (final s in pack.slots) {
      for (final o in s.options) {
        expect(File(o.asset).existsSync(), isTrue, reason: o.asset);
        expect(o.asset, endsWith('.svg'));
      }
    }
  });

  test('the careless lineman says the myth in his own recorded voice', () {
    expect(LearnVoice.resolve(pack.myth.rivalLineBn, rival: true), isNotNull);
  });
}
