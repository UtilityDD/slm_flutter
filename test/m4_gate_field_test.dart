// Module 4 rank gate (m4_gate_field.dart, pack gate_m4): the rules of all
// nine stations, the option libraries, the art on disk, and a full clean
// play in the shell that unlocks the স্কিলড rank; a deadly move freezes and
// shows its card; a slip shows its card; the idle screen stays quiet.
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/choice_deck.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m4_gate_field.dart';
import 'package:slm_flutter/features/game/m4_gate_field_world.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';

const _rung = 'm4/gate';
final _pack = m4GateFieldPacks['gate_m4']!;

LevelContext _ctx() => const LevelContext(
      rungId: _rung,
      kind: CatalogRungKind.gate,
      lessonId: '4.10',
      lessonTitleBn: 'স্কিলডের ডকেট · র‍্যাঙ্ক গেট',
      ladderStep: 119,
    );

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Finder _label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);

Future<void> _pickRight(WidgetTester t, List<String> right) async {
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = [
    for (final x in right)
      if (_label(x).evaluate().isNotEmpty) _label(x),
  ];
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
}

Future<void> _tapKey(WidgetTester t, String key, {int ms = 400}) async {
  final f = find.byKey(ValueKey(key));
  expect(f, findsOneWidget, reason: key);
  await t.tap(f, warnIfMissed: false);
  await _pump(t, ms);
}

/// A station's reason deck: the question is up, the right card is picked.
Future<void> _reason(WidgetTester t, String q, List<String> right) async {
  await _pump(t, 3000);
  expect(find.text(q), findsWidgets, reason: q);
  await _pickRight(t, right);
  await _pump(t, 3500);
}

Future<ProviderContainer> _open(WidgetTester t, int seed) async {
  t.view.physicalSize = const Size(720, 1600);
  t.view.devicePixelRatio = 2.0;
  final c = ProviderContainer();
  final nav = GlobalKey<NavigatorState>();
  await t.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
  ));
  unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
    builder: (_) => M4GateFieldPage(ctx: _ctx(), pack: _pack, muted: true, seed: seed),
  )));
  await _pump(t, 600);
  expect(find.byType(GuideIntro), findsOneWidget);
  expect(find.text('শুরু'), findsNothing);
  await waitIntro(t);
  await _pump(t, 400);
  expect(find.byKey(const ValueKey('docket-modal')), findsOneWidget);
  await t.tap(find.text('ডকেট বুঝে নিলাম · কাজ শুরু'));
  await _pump(t, 800);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

/// Station 1 played right.
Future<void> _playDo(WidgetTester t) async {
  await _tapKey(t, 'lt-switch');
  await t.tap(_label(M4GateLines.faceShield));
  await _pump(t, 200);
  await t.tap(_label(M4GateLines.gloves));
  await _pump(t, 200);
  await _tapKey(t, 'stand-side');
  for (var i = 0; i < 3; i++) {
    await _tapKey(t, 'do-$i', ms: 1200);
  }
  await _reason(t, M4GateLines.whyDoQ, M4GateLines.whyDoRight);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ZlFx.setMuted(true);
  });

  group('rules', () {
    test('deal: oil, broken insulator, hot clamp, heavy phase and button orders differ', () {
      final oil = <bool>{};
      final broken = <int>{};
      final hot = <int>{};
      final heavy = <int>{};
      final orders = <String>{};
      for (var s = 0; s < 40; s++) {
        final r = M4GateRun(s);
        oil.add(r.oilLow);
        broken.add(r.broken);
        hot.add(r.hotSide);
        heavy.add(r.heavy);
        orders.add('${r.insOrder.map((e) => e.index).join()}${r.cutOpts.map((e) => e.index).join()}');
        expect({r.heavy, r.mid, r.light}, {0, 1, 2});
        expect(r.earthHighOhm, greaterThan(8));
        expect(r.earthGoodOhm, lessThan(5));
      }
      expect(oil, {true, false});
      expect(broken, {0, 1, 2});
      expect(hot, {0, 1});
      expect(heavy, {0, 1, 2});
      expect(orders.length, greaterThan(30));
    });

    test('1 DO: on-load and under are deadly, no PPE a slip, off-load + side + PPE opens', () {
      final load = M4GateRun(2)..stance = M4GateStance.side;
      expect(load.pullDo(0), M4GateMistakes.doOnLoad);
      final under = M4GateRun(2)
        ..switchLtOff()
        ..stance = M4GateStance.under
        ..faceShield = true
        ..doGloves = true;
      expect(under.pullDo(0), M4GateMistakes.doUnder);
      final r = M4GateRun(2)
        ..switchLtOff()
        ..stance = M4GateStance.side;
      expect(r.pullDo(0), M4GateMistakes.doNoPpe);
      r
        ..faceShield = true
        ..doGloves = true;
      for (var i = 0; i < 3; i++) {
        expect(r.pullDo(i), isNull);
      }
      expect(r.doDone, isTrue);
      expect(r.deadly, isNull);
    });

    test('2 oil: a hand on the tank and engine oil are slips; low oil → report, normal → write', () {
      int seedFor(bool low) {
        var s = 0;
        while (M4GateRun(s).oilLow != low) {
          s++;
        }
        return s;
      }

      final low = M4GateRun(seedFor(true));
      expect(low.callOil(M4OilCall.report), isNull, reason: 'nothing before reading');
      expect(low.oilDone, isFalse);
      expect(low.measureTemp(ir: false), M4GateMistakes.touchTank);
      expect(low.measureTemp(ir: true), isNull);
      low.readGauge();
      expect(low.callOil(M4OilCall.engineOil), M4GateMistakes.engineOil);
      expect(low.callOil(M4OilCall.normal), M4GateMistakes.oilIgnored);
      expect(low.callOil(M4OilCall.report), isNull);
      expect(low.oilDone, isTrue);

      final ok = M4GateRun(seedFor(false))
        ..readGauge()
        ..measureTemp(ir: true);
      expect(ok.callOil(M4OilCall.report), M4GateMistakes.oilNeedless);
      expect(ok.callOil(M4OilCall.normal), isNull);
    });

    test('3 earth: two spikes, a high reading cannot pass, water + clamp then retest', () {
      final r = M4GateRun(3)..placeSpike(0);
      expect(r.runEarthTest(), M4GateMistakes.earthSpikes);
      r.placeSpike(1);
      expect(r.runEarthTest(), isNull);
      expect(r.earthOhm, greaterThan(8));
      expect(r.confirmEarth(), M4GateMistakes.earthHigh);
      r.waterPit();
      expect(r.runEarthTest(), isNull);
      expect(r.earthGood, isFalse, reason: 'the rusty clamp still loose');
      r.tightenClamp();
      expect(r.confirmEarth(), M4GateMistakes.earthHigh, reason: 'fixed but not measured again');
      expect(r.runEarthTest(), isNull);
      expect(r.earthOhm, lessThan(5));
      expect(r.confirmEarth(), isNull);
      expect(r.earthDone, isTrue);
    });

    test('4 insulator: no earths is deadly; rope before the insulator; the order', () {
      final bare = M4GateRun(4)..placeEarth(0);
      expect(bare.insStep(M4InsStep.unbind), M4GateMistakes.noEarth);

      final r = M4GateRun(4)
        ..placeEarth(0)
        ..placeEarth(1);
      expect(r.insStep(M4InsStep.removeOld), M4GateMistakes.insNoRope);
      expect(r.insStep(M4InsStep.rope), M4GateMistakes.insOrder);
      for (final s in M4InsStep.values) {
        expect(r.insStep(s), isNull);
      }
      expect(r.insDoneAll, isTrue);
      expect(r.slips, 2);
      expect(r.deadly, isNull);
    });

    test('5 jumper: find the hot clamp, brush before two wrenches, never one', () {
      final r = M4GateRun(5);
      expect(r.jumperAct(M4JumperAct.twoWrench), isNull, reason: 'nothing before it is found');
      expect(r.spotClamp(1 - r.hotSide), isFalse);
      expect(r.spotClamp(r.hotSide), isTrue);
      expect(r.jumperAct(M4JumperAct.twoWrench), M4GateMistakes.jumperDirty);
      expect(r.jumperAct(M4JumperAct.oneWrench), M4GateMistakes.jumperOneWrench);
      expect(r.jumperAct(M4JumperAct.brush), isNull);
      expect(r.jumperAct(M4JumperAct.twoWrench), isNull);
      expect(r.jumperTight, isTrue);
    });

    test('6 DP: top to bottom, nothing left, nuts tight', () {
      final r = M4GateRun(6);
      expect(r.fixDp(M4DpFault.ltCables), M4GateMistakes.dpOrder);
      expect(r.fixDp(M4DpFault.jumper), isNull);
      expect(r.finishDp(), M4GateMistakes.dpUnfinished);
      expect(r.fixDp(M4DpFault.tail), isNull);
      expect(r.fixDp(M4DpFault.ltCables), isNull);
      expect(r.finishDp(), M4GateMistakes.dpLoose);
      r.tightenNuts();
      expect(r.finishDp(), isNull);
      expect(r.dpDone, isTrue);
    });

    test('7 tree: never topping; cordon, rope, then the three cuts in order', () {
      final r = M4GateRun(7);
      expect(r.cut(M4Cut.topping), M4GateMistakes.treeTopping);
      expect(r.cut(M4Cut.under), M4GateMistakes.treeCordon);
      r.cordoned = true;
      expect(r.cut(M4Cut.under), M4GateMistakes.treeRope);
      r.roped = true;
      expect(r.cut(M4Cut.top), M4GateMistakes.treeCutOrder);
      for (final c in [M4Cut.under, M4Cut.top, M4Cut.finish]) {
        expect(r.cut(c), isNull);
      }
      expect(r.treeDone, isTrue);
    });

    test('8 street light: lamp on a live MCB is deadly, untested a slip; MCB on lights it', () {
      final live = M4GateRun(8);
      expect(live.testFixture(), '230 V');
      expect(live.replaceLamp(), M4GateMistakes.lampLive);

      final r = M4GateRun(8)..toggleMcb();
      expect(r.mcbOn, isFalse);
      expect(r.replaceLamp(), M4GateMistakes.lampUntested);
      expect(r.testFixture(), '0 V');
      expect(r.replaceLamp(), isNull);
      expect(r.lit, isFalse);
      r.toggleMcb();
      expect(r.lit, isTrue);
    });

    test('9 balance: measure all four; live is deadly, wrong way a slip; measure again', () {
      final r = M4GateRun(9);
      expect(r.amps(r.heavy), greaterThan(r.amps(r.light)));
      expect(r.callBalance(M4BalCall.shiftDead), isNull);
      expect(r.balShifted, isFalse, reason: 'not before all four are measured');
      for (var i = 0; i < 4; i++) {
        r.measure(i);
      }
      expect(r.callBalance(M4BalCall.wrongWay), M4GateMistakes.balWrongWay);
      expect(r.callBalance(M4BalCall.shiftDead), isNull);
      expect(r.amps(3), lessThan(10));
      r.measure(3);
      expect(r.confirmBalance(), M4GateMistakes.balNoRecheck);
      for (var i = 0; i < 4; i++) {
        r.measure(i);
      }
      expect(r.confirmBalance(), isNull);
      expect(M4GateRun(9).callBalance(M4BalCall.shiftLive), isNull);
      final live = M4GateRun(9);
      for (var i = 0; i < 4; i++) {
        live.measure(i);
      }
      expect(live.callBalance(M4BalCall.shiftLive), M4GateMistakes.balLive);
    });

    test('the mark: 15 per slip, pass at 55, all nine stations', () {
      final r = M4GateRun(10);
      for (var i = 0; i < M4GateStation.values.length; i++) {
        r.advanceStation();
      }
      expect(r.done, isTrue);
      expect(r.passed, isTrue);
      r.slips = 3;
      expect(r.percent, 55);
      expect(r.passed, isTrue);
      r.slips = 4;
      expect(r.passed, isFalse);
    });
  });

  group('content', () {
    test('reason libraries: ≥2 right, ≥5 wrong, lengths within 1.3×', () {
      final libs = {
        'do': (M4GateLines.whyDoRight, M4GateLines.whyDoWrong),
        'oil': (M4GateLines.whyOilRight, M4GateLines.whyOilWrong),
        'earth': (M4GateLines.whyEarthRight, M4GateLines.whyEarthWrong),
        'ins': (M4GateLines.whyInsRight, M4GateLines.whyInsWrong),
        'jumper': (M4GateLines.whyJumperRight, M4GateLines.whyJumperWrong),
        'dp': (M4GateLines.whyDpRight, M4GateLines.whyDpWrong),
        'tree': (M4GateLines.whyTreeRight, M4GateLines.whyTreeWrong),
        'lamp': (M4GateLines.whyLampRight, M4GateLines.whyLampWrong),
        'bal': (M4GateLines.whyBalRight, M4GateLines.whyBalWrong),
      };
      for (final e in libs.entries) {
        expectLibrary(e.key, e.value.$1, e.value.$2);
        expectSameLength(e.key, [...e.value.$1, ...e.value.$2]);
      }
      final cw = M4GateLines.coworker;
      expectLibrary('coworker', cw.right, cw.wrong, minRight: 2, minWrong: 4);
      expectSameLength('coworker', [...cw.right, ...cw.wrong]);
    });

    test('a deal: one right, three different options', () {
      final d = dealChoices(M4GateLines.whyEarthRight, M4GateLines.whyEarthWrong, math.Random(9));
      expect(d.where((o) => o.correct), hasLength(1));
      expect(d.map((o) => o.textBn).toSet(), hasLength(3));
    });

    test('mistakes: unique keys by lesson, art on disk, short text', () {
      final keys = <String>{};
      final lessons = {for (var i = 1; i <= 10; i++) '4.$i'};
      for (final m in M4GateMistakes.all) {
        expect(m.key, contains('/m4_gate_field/'));
        expect(lessons, contains(M4GateMistakes.lessonOf(m)), reason: m.key);
        expect(keys.add(m.key), isTrue, reason: m.key);
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.lessonPoint, isNotNull, reason: m.key);
        expect(m.textBn.length, lessThan(140), reason: m.key);
      }
      // Every lesson of the module teaches at least one station.
      expect({for (final m in M4GateMistakes.all) M4GateMistakes.lessonOf(m)}, lessons..remove('4.3'));
      expect(M4GateMistakes.all.where((m) => m.deadly).map((m) => m.key.split('/').last).toSet(), {
        'do-on-load',
        'do-under',
        'no-earth',
        'lamp-live',
        'bal-live',
      });
    });

    test('lines for recording; Bangla digits never on screen', () {
      expect(M4GateLines.recordable, isNotEmpty);
      final bnDigit = RegExp('[০-৯]');
      for (final l in [...M4GateLines.recordable, ...M4GateLines.stationTitles.values]) {
        expect(bnDigit.hasMatch(l), isFalse, reason: l);
      }
      for (final m in M4GateMistakes.all) {
        expect(bnDigit.hasMatch(m.textBn), isFalse, reason: m.key);
      }
      expect(RegExp('পানি').hasMatch(M4GateLines.recordable.join()), isFalse);
    });
  });

  group('page', () {
    testWidgets('a full clean play: nine stations, the coworker refused, স্কিলড unlocked', (t) async {
      const seed = 21;
      final deal = M4GateRun(seed);
      final c = await _open(t, seed);

      // 1 — DO.
      expect(find.text('DO খোলা'), findsOneWidget);
      await _playDo(t);

      // 2 — oil and temperature.
      expect(find.text('তেল ও তাপ'), findsOneWidget);
      await _tapKey(t, 'gauge');
      expect(find.byKey(const ValueKey('gauge-lens')), findsOneWidget);
      await t.tap(_label(M4GateLines.irGun));
      await _pump(t, 400);
      await _tapKey(t, deal.oilLow ? 'oil-report' : 'oil-normal', ms: 200);
      await _reason(t, M4GateLines.whyOilQ, M4GateLines.whyOilRight);

      // 3 — earth.
      expect(find.text('আর্থ টেস্ট'), findsOneWidget);
      await _tapKey(t, 'spike-0');
      await _tapKey(t, 'spike-1');
      await _tapKey(t, 'earth-test');
      await _tapKey(t, 'pit');
      await _tapKey(t, 'clamp');
      await _tapKey(t, 'earth-test');
      await _tapKey(t, 'earth-ok', ms: 200);
      await _reason(t, M4GateLines.whyEarthQ, M4GateLines.whyEarthRight);

      // 4 — insulator; the coworker comes and is refused.
      expect(find.text('ইনসুলেটর বদল'), findsOneWidget);
      await _pump(t, 3000);
      await _pickRight(t, M4GateLines.coworker.right);
      await _pump(t, 2500);
      await _tapKey(t, 'earth-0');
      await _tapKey(t, 'earth-1');
      for (final s in M4InsStep.values) {
        await _tapKey(t, 'ins-${s.name}', ms: 500);
      }
      await _reason(t, M4GateLines.whyInsQ, M4GateLines.whyInsRight);

      // 5 — jumper.
      expect(find.text('জাম্পার টাইট'), findsOneWidget);
      await _tapKey(t, 'jclamp-${deal.hotSide}');
      await _tapKey(t, 'jumper-brush');
      await _tapKey(t, 'jumper-twoWrench', ms: 200);
      await _reason(t, M4GateLines.whyJumperQ, M4GateLines.whyJumperRight);

      // 6 — DP dressing, top to bottom.
      expect(find.text('ডিপি ড্রেসিং'), findsOneWidget);
      for (final f in M4DpFault.values) {
        await _tapKey(t, 'fault-${f.name}');
      }
      await _tapKey(t, 'dp-nuts');
      await _tapKey(t, 'dp-done', ms: 200);
      await _reason(t, M4GateLines.whyDpQ, M4GateLines.whyDpRight);

      // 7 — tree.
      expect(find.text('ডাল ছাঁটা'), findsOneWidget);
      await _tapKey(t, 'tree-cordon');
      await _tapKey(t, 'tree-rope');
      for (final cut in [M4Cut.under, M4Cut.top, M4Cut.finish]) {
        await _tapKey(t, 'cut-${cut.name}', ms: 500);
      }
      await _reason(t, M4GateLines.whyTreeQ, M4GateLines.whyTreeRight);

      // 8 — street light.
      expect(find.text('স্ট্রিট লাইট'), findsOneWidget);
      await _tapKey(t, 'mcb');
      await _tapKey(t, 'lamp-test');
      await _tapKey(t, 'lamp-new');
      await _tapKey(t, 'mcb', ms: 200);
      await _reason(t, M4GateLines.whyLampQ, M4GateLines.whyLampRight);

      // 9 — phase balance: measure, shift under shutdown, measure again.
      expect(find.text('ফেজ ব্যালেন্স'), findsOneWidget);
      for (var i = 0; i < 4; i++) {
        await _tapKey(t, 'wire-$i');
      }
      await _tapKey(t, 'bal-shiftDead', ms: 2000);
      for (var i = 0; i < 4; i++) {
        await _tapKey(t, 'wire-$i');
      }
      await _tapKey(t, 'bal-ok', ms: 200);
      await _reason(t, M4GateLines.whyBalQ, M4GateLines.whyBalRight);
      await _pump(t, 3000);

      final s = c.read(gameSaveProvider);
      expect(s.rungProgress[_rung], 'cleared');
      expect(s.rankIndex, 4);
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung[_rung], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(M4GateLines.rankStamp), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('pulling a DO on load: the scene freezes, then the deadly card', (t) async {
      final c = await _open(t, 5);
      await _tapKey(t, 'stand-side');
      await _tapKey(t, 'do-0', ms: 1000);
      expect(find.byKey(const ValueKey('freeze')), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3000);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(M4GateMistakes.doOnLoad.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.deadly, isTrue);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a hand on the tank is a slip: its card, no freeze', (t) async {
      final c = await _open(t, 6);
      await _playDo(t);
      await t.tap(_label(M4GateLines.handOnTank));
      await _pump(t, 600);
      expect(find.byKey(const ValueKey('freeze')), findsNothing);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(M4GateMistakes.touchTank.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.deadly, isFalse);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    for (final reduce in [false, true]) {
      testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
        var rebuilds = 0;
        debugOnRebuildDirtyWidget = (_, _) => rebuilds++;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        final c = await _open(t, 3);
        await _pump(t, 14000);
        rebuilds = 0;
        for (var i = 0; i < 125; i++) {
          await t.pump(const Duration(milliseconds: 16));
        }
        final perSec = rebuilds / 2.0;
        var frames = 0;
        for (var i = 0; i < 60; i++) {
          if (t.binding.hasScheduledFrame) frames++;
          await t.pump(const Duration(milliseconds: 16));
        }
        debugPrint('PERF m4_gate_field ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
        debugOnRebuildDirtyWidget = null;
        expect(t.takeException(), isNull);
        expect(perSec, lessThan(20));
        expect(frames, lessThan(12));
        t.platformDispatcher.clearAccessibilityFeaturesTestValue();
        await _close(t, c);
      });
    }
  });
}
