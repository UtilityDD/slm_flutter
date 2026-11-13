import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/do_games.dart';
import 'package:slm_flutter/features/game/kit_check.dart';
import 'package:slm_flutter/features/game/ladder_builder.dart';
import 'package:slm_flutter/features/game/level_shell.dart';

KitItem _pool(String id) => kitCheckPack11.pool.firstWhere((i) => i.id == id);

/// A fixed deal for rule tests: one of each kind per slot.
KitDeal _deal() {
  final shirt = _pool('shirt');
  final boot = _pool('boot');
  return KitDeal(
    items: [
      shirt,
      shirt.withFlaw(shirt.flaws.first),
      _pool('poly'),
      _pool('pant'),
      _pool('halfpant'),
      boot,
      boot.withFlaw(boot.flaws.first),
      _pool('slipper'),
    ],
    callBefore: KitSlot.feet,
    caller: kitCheckPack11.callers.first,
  );
}

KitItem _in(KitDeal d, String id) => d.items.firstWhere((i) => i.id == id);

void main() {
  group('kit check rules', () {
    test('wear the sound item, send back the damaged and the wrong ones', () {
      final shirt = _pool('shirt');
      final greasy = shirt.withFlaw(shirt.flaws.first);
      expect(judgeKit(shirt, KitChoice.wear).right, isTrue);
      expect(judgeKit(greasy, KitChoice.reject).right, isTrue);
      expect(judgeKit(greasy, KitChoice.reject).stampBn, kitStampReject);
      expect(judgeKit(_pool('poly'), KitChoice.reject).right, isTrue);

      final worn = judgeKit(greasy, KitChoice.wear);
      expect(worn.right, isFalse);
      expect(worn.wears, isFalse, reason: 'damaged kit never goes on the figure');
      expect(worn.reasonBn, greasy.flaw!.lineBn);
      expect(worn.stampBn, kitStampWrong);

      final rejectedGood = judgeKit(_pool('boot'), KitChoice.reject);
      expect(rejectedGood.right, isFalse);
      expect(rejectedGood.leavesTray, isFalse, reason: 'the sound item stays to be worn');
    });

    test('a clean play: every first decision right, call held → 100%, faults listed', () {
      final d = _deal();
      final r = KitCheckRound(d);
      expect(r.slot, KitSlot.torso);
      r.decide(_in(d, 'shirt#grease'), KitChoice.reject);
      r.decide(_in(d, 'poly'), KitChoice.reject);
      r.decide(_in(d, 'shirt'), KitChoice.wear);
      r.decide(_in(d, 'pant'), KitChoice.wear);
      expect(r.callDue, isTrue, reason: 'the call comes before the boots');
      r.answerCall(heldCheck: true);
      r.decide(_in(d, 'boot#boot-nail'), KitChoice.reject);
      r.decide(_in(d, 'boot'), KitChoice.wear);
      expect(r.done, isTrue);
      expect(r.percent, 100);
      expect(r.caught.map((i) => i.labelBn), ['গ্রিজ লাগা জামা', 'পলিয়েস্টার জামা', 'পেরেক গাঁথা বুট']);
    });

    test('wearing damaged kit and rushing on the call fails the play (slips only)', () {
      final boot = _pool('boot');
      final cracked = boot.withFlaw(boot.flaws.firstWhere((f) => f.kind == KitFlawKind.crack));
      final d = KitDeal(items: [..._deal().items, cracked], callBefore: KitSlot.feet, caller: kitCheckPack11.callers.first);
      final r = KitCheckRound(d);
      r.decide(_in(d, 'shirt#grease'), KitChoice.wear);
      r.decide(_in(d, 'shirt'), KitChoice.reject);
      r.decide(_in(d, 'shirt'), KitChoice.wear);
      r.decide(_in(d, 'pant'), KitChoice.wear);
      r.answerCall(heldCheck: false);
      r.decide(_in(d, 'boot#boot-crack'), KitChoice.wear);
      r.decide(_in(d, 'boot'), KitChoice.wear);
      expect(r.done, isTrue);
      expect(r.deadly, isNull, reason: 'grease and a cracked sole are slips');
      expect(r.passed, isFalse);
    });

    test('owner 2026-11-08: synthetic shirt and a nail in the sole are deadly; other faults stay slips', () {
      // Every synthetic item and every nail flaw is deadly when worn.
      for (final i in kitCheckPack11.pool) {
        final synthetic = i.id == 'poly';
        expect(judgeKit(i, KitChoice.wear).deadly, synthetic ? KitMistakes.synthetic : null, reason: i.id);
        expect(judgeKit(i, KitChoice.reject).deadly, isNull, reason: 'sending ${i.id} back is never deadly');
        for (final f in i.flaws) {
          final flawed = i.withFlaw(f);
          final o = judgeKit(flawed, KitChoice.wear);
          expect(o.deadly, f.kind == KitFlawKind.nail ? KitMistakes.nail : null, reason: flawed.id);
          expect(o.right, isFalse);
          expect(judgeKit(flawed, KitChoice.reject).deadly, isNull);
        }
      }
      expect([for (final i in kitCheckPack11.pool) for (final f in i.flaws) if (f.deadly != null) f.id], ['boot-nail', 'boot2-nail', 'boot3-nail']);
      expect(KitMistakes.all.every((m) => m.deadly), isTrue);
      expect(KitMistakes.synthetic.lessonPoint, 0);
      expect(KitMistakes.nail.lessonPoint, 2);
      for (final m in KitMistakes.all) {
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(kitCheckSpokenLines(kitCheckPack11), contains(m.textBn), reason: 'the guide reads it; in the voice list');
      }
    });

    test('wearing a deadly item ends the play unpassed, even with every other answer right', () {
      for (final id in ['poly', 'boot#boot-nail']) {
        final d = _deal();
        final r = KitCheckRound(d);
        r.decide(_in(d, 'shirt#grease'), KitChoice.reject);
        if (id == 'poly') {
          expect(r.decide(_in(d, 'poly'), KitChoice.wear).deadly, KitMistakes.synthetic);
        } else {
          r.decide(_in(d, 'poly'), KitChoice.reject);
          r.decide(_in(d, 'shirt'), KitChoice.wear);
          r.decide(_in(d, 'pant'), KitChoice.wear);
          r.answerCall(heldCheck: true);
          expect(r.decide(_in(d, id), KitChoice.wear).deadly, KitMistakes.nail);
        }
        expect(r.deadly, isNotNull);
        expect(r.passed, isFalse, reason: id);
      }
    });

    test('audit 2026-11-11: after a deadly item nothing more is recorded; the call counts once', () {
      final d = _deal();
      final r = KitCheckRound(d);
      expect(r.decide(_in(d, 'poly'), KitChoice.wear).deadly, KitMistakes.synthetic);
      expect(r.ended, isTrue);
      final asked = r.asked;
      r.decide(_in(d, 'shirt'), KitChoice.wear);
      r.answerCall(heldCheck: true);
      expect(r.asked, asked, reason: 'the play is over');
      expect(r.worn, isEmpty);

      final r2 = KitCheckRound(_deal());
      r2.answerCall(heldCheck: false);
      r2.answerCall(heldCheck: true);
      expect(r2.asked, 1, reason: 'one call per play');
      expect(r2.clean, 0);
    });

    test('listening to the coworker is a slip (never deadly) with the daily-check lesson point', () {
      final legs = KitMistakes.rushed(KitSlot.legs);
      final feet = KitMistakes.rushed(KitSlot.feet);
      expect(legs.key, KitMistakes.rushedKey);
      expect(legs.deadly, isFalse);
      expect(legs.lessonPoint, 0);
      expect(feet.lessonPoint, 2);
      expect(File(legs.art).existsSync(), isTrue, reason: legs.art);
      expect(KitMistakes.all.map((m) => m.key), isNot(contains(KitMistakes.rushedKey)), reason: 'all = the deadly pair only');
      expect(kitCheckSpokenLines(kitCheckPack11), contains(KitMistakes.rushedBn), reason: 'the booked slip text is in the voice list');
    });

    test('the reply to a sound item sent back is neutral (never "it was fine")', () {
      expect(KitLines.lookAgain, isNot(KitLines.rejectedGood));
      expect(KitLines.lookAgain.contains('ঠিক'), isFalse);
      expect(KitLines.coach, contains(KitLines.lookAgain));
    });

    test('a slip is booked with a stable key and its lesson point', () {
      final shirt = _pool('shirt');
      final greasy = shirt.withFlaw(shirt.flaws.first);
      final m = kitSlip(greasy, judgeKit(greasy, KitChoice.wear));
      expect(m.key, '1.1/kit/flaw/grease');
      expect(m.deadly, isFalse);
      expect(m.textBn, greasy.flaw!.lineBn);
      expect(m.lessonPoint, 0);
      final slipper = _pool('slipper');
      expect(kitSlip(slipper, judgeKit(slipper, KitChoice.wear)).lessonPoint, 2);
      final back = kitSlip(_pool('boot'), judgeKit(_pool('boot'), KitChoice.reject));
      expect(back.key, '1.1/kit/rejected-good');
      expect(back.textBn, isNotEmpty);
    });
  });

  group('kit check deal', () {
    test('every deal: one sound item per slot, a damaged look-alike for shirt and boots', () {
      for (var seed = 0; seed < 60; seed++) {
        final d = dealKit(kitCheckPack11, math.Random(seed));
        for (final slot in KitSlot.values) {
          final here = d.items.where((i) => i.slot == slot).toList();
          expect(here.where((i) => i.kind == KitKind.good), hasLength(1), reason: 'seed $seed $slot');
          expect(here.where((i) => i.kind == KitKind.wrong), isNotEmpty, reason: 'seed $seed $slot');
          expect(here.length, lessThanOrEqualTo(4), reason: 'tray fits a 360 dp phone');
          if (slot != KitSlot.legs) {
            expect(here.where((i) => i.kind == KitKind.flawed), hasLength(1), reason: 'seed $seed $slot');
          }
        }
        expect(d.items.map((i) => i.id).toSet(), hasLength(d.items.length), reason: 'ids unique');
        expect(kitCheckPack11.callBefore, contains(d.callBefore));
      }
    });

    test('plays differ: pictures, flaws, wrong items and callers all vary', () {
      final sets = <String>{};
      final callers = <String>{};
      final flaws = <KitFlawKind>{};
      for (var seed = 0; seed < 60; seed++) {
        final d = dealKit(kitCheckPack11, math.Random(seed));
        sets.add((d.items.map((i) => i.id).toList()..sort()).join(','));
        callers.add(d.caller.id);
        flaws.addAll(d.items.where((i) => i.flaw != null).map((i) => i.flaw!.kind));
      }
      expect(sets.length, greaterThan(20), reason: 'a player should rarely see the same set twice');
      expect(callers, hasLength(kitCheckPack11.callers.length));
      expect(flaws, containsAll(KitFlawKind.values));
    });

    test('all pictures exist, every fault says why, and flaw marks sit inside the picture', () {
      final sets = <Set<KitSlot>>[
        {},
        {KitSlot.torso},
        {KitSlot.torso, KitSlot.legs},
        {KitSlot.torso, KitSlot.feet},
        {KitSlot.legs, KitSlot.feet},
        {KitSlot.legs},
        {KitSlot.feet},
        {...KitSlot.values},
      ];
      for (final s in sets) {
        expect(File(kitFigureAsset(s)).existsSync(), isTrue, reason: kitFigureAsset(s));
      }
      for (final i in kitCheckPack11.pool) {
        expect(File(i.asset).existsSync(), isTrue, reason: i.asset);
        if (i.wornAsset != null) expect(File(i.wornAsset!).existsSync(), isTrue, reason: i.wornAsset);
        if (i.kind == KitKind.wrong) expect(i.lineBn, isNotEmpty, reason: '${i.id} must say why');
        for (final f in i.flaws) {
          expect(f.lineBn, isNotEmpty);
          for (final m in f.marks) {
            expect(m.dx, inInclusiveRange(0, 1));
            expect(m.dy, inInclusiveRange(0, 1));
          }
        }
      }
    });
  });

  group('level shell context', () {
    late BuiltLadder ladder;
    setUpAll(() {
      final raw = File('assets/game/catalog/content_catalog.json').readAsStringSync();
      ladder = const LadderBuilder().build(ContentCatalog.fromJson(jsonDecode(raw) as Map<String, dynamic>));
    });

    test('Do rungs know their place in the lesson, however many there are', () {
      final ctx = levelContextFor(ladder, '1.1/do/0')!;
      expect(ctx.isDo, isTrue);
      expect(ctx.lessonId, '1.1');
      expect(ctx.doIndex, 1);
      expect(ctx.doCount, ladder.rungs.where((r) => r.def.lessonId == '1.1' && r.def.kind == CatalogRungKind.doKind).length);
      expect(ctx.chipBn, contains('কাজ 1/'));
      expect(levelContextFor(ladder, '1.1/do/1')!.doIndex, 2);
      expect(levelContextFor(ladder, '1.1/learn')!.chipBn, 'পাঠ 1.1 · শেখা');
      expect(levelContextFor(ladder, 'm1/gate')!.chipBn, 'র‍্যাঙ্ক গেট');
    });

    test('lesson 1.1: কাজ 1 is the kit check, কাজ 2 the glove check; later Do rungs keep their level', () {
      final first = ladder.rungs.firstWhere((r) => r.id == '1.1/do/0');
      expect(first.pack.engineType, 'kit_check');
      expect(doGameFor(first.pack), isNotNull);
      final second = ladder.rungs.firstWhere((r) => r.id == '1.1/do/1');
      expect(second.pack.engineType, 'glove_check');
      expect(doGameFor(second.pack), isNotNull);
      // A Do rung that is not built yet has no shell game. Modules 1–5 are built
      // (Module 5 wired 2026-11-12), so the check uses Module 6's first Do rung, still a placeholder.
      final later = ladder.rungs.firstWhere((r) => r.id == '6.1/do/0');
      expect(later.pack.engineType, 'placeholder');
      expect(doGameFor(later.pack), isNull);
      final scan = ladder.rungs.firstWhere((r) => r.id == '1.10/do/0');
      expect(scan.pack.engineType, 'ten_sec_scan');
      expect(doGameFor(scan.pack), isNotNull);
    });
  });
}
