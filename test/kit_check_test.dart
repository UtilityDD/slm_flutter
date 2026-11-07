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

    test('wearing damaged kit and rushing on the call fails the play', () {
      final d = _deal();
      final r = KitCheckRound(d);
      r.decide(_in(d, 'shirt#grease'), KitChoice.wear);
      r.decide(_in(d, 'shirt'), KitChoice.reject);
      r.decide(_in(d, 'shirt'), KitChoice.wear);
      r.decide(_in(d, 'pant'), KitChoice.wear);
      r.answerCall(heldCheck: false);
      r.decide(_in(d, 'boot#boot-nail'), KitChoice.wear);
      r.decide(_in(d, 'boot'), KitChoice.wear);
      expect(r.done, isTrue);
      expect(r.passed, isFalse);
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
      // A lesson whose Do rungs are not rebuilt yet still opens its old level.
      final later = ladder.rungs.firstWhere((r) => r.id == '1.9/do/0');
      expect(doGameFor(later.pack), isNull);
      expect(later.pack.legacyLevel, isNotNull);
    });
  });
}
