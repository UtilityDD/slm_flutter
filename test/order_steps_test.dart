// The "order" move and its first level (lesson 1.5, কাজ 2: আগে মাটি, পরে লাইন):
// earth first, R/Y/B in any order, then the chain; off in reverse, earth last.
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:slm_flutter/features/game/discharge_order.dart';
import 'package:slm_flutter/features/game/order_steps.dart';

OrderRun _run() => OrderRun(dischargeRounds());

void main() {
  test('a clean play: earth, phases in any order, chain, then off with the earth last', () {
    final r = _run();
    expect(r.tap(DischargeIds.earth).kind, OrderTapKind.ok);
    expect(r.tap(DischargeIds.b).kind, OrderTapKind.ok);
    expect(r.tap(DischargeIds.r).kind, OrderTapKind.ok);
    expect(r.tap(DischargeIds.y).kind, OrderTapKind.ok);
    final c = r.tap(DischargeIds.chain);
    expect(c.roundDone, isTrue);
    expect(c.allDone, isFalse);
    expect(r.round, 1);
    expect(r.tap(DischargeIds.hookOff).kind, OrderTapKind.ok);
    expect(r.tap(DischargeIds.chainOff).kind, OrderTapKind.ok);
    final end = r.tap(DischargeIds.clampOff);
    expect(end.allDone, isTrue);
    expect(r.passed, isTrue);
    expect(r.percent, 100);
  });

  test('the hook on a wire before the earth is deadly and ends the play', () {
    final r = _run();
    final t = r.tap(DischargeIds.y);
    expect(t.kind, OrderTapKind.mistake);
    expect(t.mistake, DischargeMistakes.lineBeforeEarth);
    expect(t.mistake!.deadly, isTrue);
    expect(r.ended, isTrue);
    expect(r.passed, isFalse);
    expect(r.tap(DischargeIds.earth).kind, OrderTapKind.ignored);
  });

  test('the chain before the earth is "chain in place of the rod" (deadly)', () {
    final r = _run();
    expect(r.tap(DischargeIds.chain).mistake, DischargeMistakes.chainInsteadOfRod);
    expect(r.deadly, DischargeMistakes.chainInsteadOfRod);
  });

  test('slips cost marks but the play goes on', () {
    final r = _run();
    expect(r.tap(DischargeIds.rusty).mistake, DischargeMistakes.rustyEarth);
    expect(r.tap(DischargeIds.earth).kind, OrderTapKind.ok);
    expect(r.tap(DischargeIds.r).kind, OrderTapKind.ok);
    // Chain before all three phases: a slip, not a death.
    final early = r.tap(DischargeIds.chain);
    expect(early.mistake, DischargeMistakes.chainEarly);
    expect(early.mistake!.deadly, isFalse);
    expect(r.ended, isFalse);
    for (final p in [DischargeIds.y, DischargeIds.b, DischargeIds.chain]) {
      expect(r.tap(p).kind, OrderTapKind.ok);
    }
    // Earth off before the chain and the hook: a slip.
    expect(r.tap(DischargeIds.clampOff).mistake, DischargeMistakes.earthOffFirst);
    for (final p in [DischargeIds.chainOff, DischargeIds.hookOff, DischargeIds.clampOff]) {
      expect(r.tap(p).kind, OrderTapKind.ok);
    }
    expect(r.slips, 3);
    expect(r.percent, 55);
    expect(r.passed, isTrue);
  });

  test('a tap on a step already done is ignored', () {
    final r = _run();
    r.tap(DischargeIds.earth);
    expect(r.tap(DischargeIds.earth).kind, OrderTapKind.ignored);
    expect(r.slips, 0);
  });

  test('giving in to the pressure call is deadly', () {
    final r = _run()..failDeadly(DischargeMistakes.skipDischarge);
    expect(r.ended, isTrue);
    expect(r.passed, isFalse);
    expect(DischargeMistakes.skipDischarge.deadly, isTrue);
  });

  test('deals vary: earth side, call moment and caller all change', () {
    final deals = [for (var s = 0; s < 40; s++) dealDischarge(math.Random(s))];
    expect(deals.map((d) => d.goodLeft).toSet(), {true, false});
    expect(deals.map((d) => d.callAfter).toSet(), {0, 1, 2});
    expect(deals.map((d) => d.caller.id).toSet().length, dischargeCallers.length);
  });

  test('every mistake has a picture and points into the lesson', () {
    const all = [
      DischargeMistakes.lineBeforeEarth,
      DischargeMistakes.chainInsteadOfRod,
      DischargeMistakes.skipDischarge,
      DischargeMistakes.rustyEarth,
      DischargeMistakes.chainEarly,
      DischargeMistakes.earthOffFirst,
    ];
    expect(all.map((m) => m.key).toSet().length, all.length);
    for (final m in all) {
      expect(m.art, startsWith('assets/game/art/discharge/'));
      expect(m.lessonPoint, isNotNull);
      expect(m.key, startsWith('1.5/'));
    }
  });
}
