// Module 4 rank gate (m4_gate_field.dart, pack gate_m4): the rules of all
// nine stations, the option libraries, the art on disk, and a full clean
// play in the shell that unlocks the স্কিলড rank; a deadly move freezes and
// shows its card; a slip shows its card; three slips strike out; the
// coworker comes even on a fast play and listening to him is a slip; a
// station pays only from the table, once; no start button; the guide
// restates the task; the idle screen stays quiet.
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/beat_fx.dart' show UnifiedGameTopHud;
import 'package:slm_flutter/features/game/choice_deck.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/gesture_hint.dart';
import 'package:slm_flutter/features/game/level_frame.dart' show StruckOutCard;
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m4_gate_field.dart';
import 'package:slm_flutter/features/game/m4_gate_field_world.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';
import 'support/reason_proceed.dart';

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

/// The level score in the header (the number by its ◆).
int _score() {
  // The score pill's own row (◆ and its number), found from its ◆ — not by
  // font size: the shared top bar scales its fonts with the screen width.
  final diamond = find.descendant(of: find.byType(UnifiedGameTopHud), matching: find.text('◆'));
  expect(diamond, findsOneWidget);
  final pill = find.ancestor(of: diamond, matching: find.byType(Row)).first;
  final f = find.descendant(
    of: pill,
    matching: find.byWidgetPredicate((w) => w is Text && RegExp(r'^\d+$').hasMatch(w.data ?? '')),
  );
  expect(f, findsOneWidget);
  return int.parse((f.evaluate().single.widget as Text).data!);
}

Future<void> _pickRight(WidgetTester t, List<String> right) async {
  await waitChoiceDeck(t);
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = [
    for (final x in right)
      if (_label(x).evaluate().isNotEmpty) _label(x),
  ];
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
  await tapReasonProceed(t);
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
  // Guide first: no docket modal with a start button in the way.
  expect(find.byKey(const ValueKey('docket-modal')), findsNothing);
  await _pump(t, 400);
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

/// Station 2 played right.
Future<void> _playOil(WidgetTester t, M4GateRun deal) async {
  await _tapKey(t, 'gauge');
  await t.tap(_label(M4GateLines.irGun));
  await _pump(t, 400);
  await _tapKey(t, deal.oilLow ? 'oil-report' : 'oil-normal', ms: 200);
  await _reason(t, M4GateLines.whyOilQ, M4GateLines.whyOilRight);
}

/// Station 3 played right.
Future<void> _playEarth(WidgetTester t) async {
  await _tapKey(t, 'spike-0');
  await _tapKey(t, 'spike-1');
  await _tapKey(t, 'earth-test');
  await _tapKey(t, 'pit');
  await _tapKey(t, 'clamp');
  await _tapKey(t, 'earth-test');
  await _tapKey(t, 'earth-ok', ms: 200);
  await _reason(t, M4GateLines.whyEarthQ, M4GateLines.whyEarthRight);
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

    test('1 DO: on-load is deadly; under the fuse and no PPE are slips; off-load + side + PPE opens', () {
      final load = M4GateRun(2)..stance = M4GateStance.side;
      expect(load.pullDo(0), M4GateMistakes.doOnLoad);
      expect(load.deadly, M4GateMistakes.doOnLoad);
      expect(load.pullDo(1), isNull, reason: 'a dead play takes no more moves');
      final under = M4GateRun(2)
        ..switchLtOff()
        ..stance = M4GateStance.under
        ..faceShield = true
        ..doGloves = true;
      // A slip, as in m4_do_open (4.4a): the same act, one class.
      expect(under.pullDo(0), M4GateMistakes.doUnder);
      expect(under.deadly, isNull);
      expect(under.slips, 1);
      expect(under.doOpen[0], isFalse);
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

    test('2 oil: a hand on the tank, engine oil and a call unread are slips; low oil → report, normal → write', () {
      int seedFor(bool low) {
        var s = 0;
        while (M4GateRun(s).oilLow != low) {
          s++;
        }
        return s;
      }

      final low = M4GateRun(seedFor(true));
      // A call before the gauge and the heat are read is an over-call: a slip.
      expect(low.callOil(M4OilCall.report), M4GateMistakes.oilUnread);
      expect(low.oilDone, isFalse);
      expect(low.slips, 1);
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
      // "Earthing OK" with no reading is an over-call: a slip, not a reminder.
      expect(r.confirmEarth(), M4GateMistakes.earthUntested);
      expect(r.earthDone, isFalse);
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
      // A wrong flag costs a slip — never a free "this one is fine".
      expect(r.spotClamp(1 - r.hotSide), M4GateMistakes.jumperWrongClamp);
      expect(r.slips, 1);
      expect(r.hotFound, isFalse);
      expect(r.spotClamp(r.hotSide), isNull);
      expect(r.hotFound, isTrue);
      expect(r.spotClamp(1 - r.hotSide), isNull, reason: 'nothing once found');
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
      r.toggleMcb();
      expect(r.lit, isTrue, reason: 'a second tap never switches the won lamp off');
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
      final back = M4GateRun(9);
      for (var i = 0; i < 4; i++) {
        back.measure(i);
      }
      expect(back.callBalance(M4BalCall.liveBack), M4GateMistakes.balLive);
    });

    test('9 balance: four calls, no part shared by all the wrong ones with the right one', () {
      final r = M4GateRun(9);
      expect(r.balOpts.toSet(), M4BalCall.values.toSet());
      final labels = [for (final c in M4BalCall.values) M4GateLines.balCall(c, 'R', 'B')];
      expect(labels.toSet(), hasLength(4));
      // "শাটডাউন" and "R → B" each sit on exactly two of the four.
      expect(labels.where((l) => l.contains('শাটডাউন')), hasLength(2));
      expect(labels.where((l) => l.contains('R → B')), hasLength(2));
    });

    test('a station once won: a second call never wins (or pays) again', () {
      final r = M4GateRun(12)
        ..readGauge()
        ..measureTemp(ir: true);
      expect(r.callOil(r.oilLow ? M4OilCall.report : M4OilCall.normal), isNull);
      expect(r.oilDone, isTrue);
      expect(r.callOil(M4OilCall.engineOil), isNull, reason: 'no slip either after the win');
      expect(r.slips, 0);
    });

    test('the mark: 15 per slip; two slips still pass; three strike out', () {
      final r = M4GateRun(10);
      for (var i = 0; i < M4GateStation.values.length; i++) {
        r.advanceStation();
      }
      expect(r.done, isTrue);
      expect(r.passed, isTrue);
      r.slips = 2;
      expect(r.percent, 70);
      expect(r.passed, isTrue);
      // Three slips are the kit's strike-out: never a pass.
      r.slips = 3;
      expect(r.percent, 55);
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

    test('reason libraries: no word sits on every right option and on no wrong one', () {
      Set<String> words(String l) => l.replaceAll(',', ' ').split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toSet();
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
      libs['coworker'] = (M4GateLines.coworker.right, M4GateLines.coworker.wrong);
      for (final e in libs.entries) {
        final inWrong = {for (final w in e.value.$2) ...words(w)};
        final tell = e.value.$1.map(words).reduce((a, b) => a.intersection(b)).difference(inWrong);
        expect(tell, isEmpty, reason: '${e.key}: $tell');
      }
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

    test('content stays inside lessons 4.4 and 4.6 (no molten metal, no burning people)', () {
      final all = [...M4GateLines.recordable, ...M4GateLines.whyDoRight, ...M4GateLines.whyDoWrong, for (final m in M4GateMistakes.all) m.textBn].join('\n');
      expect(all.contains('গলিত ধাতু'), isFalse);
      expect(all.contains('মানুষ পুড়'), isFalse);
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
      await _playEarth(t);

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
      expect(find.byKey(const ValueKey('bal-liveBack')), findsOneWidget);
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
      // No control and no docket chip sit on top of the freeze.
      expect(find.byKey(const ValueKey('station-chip')), findsNothing);
      expect(find.byKey(const ValueKey('ppe-row')), findsNothing);
      // The frozen play takes no more moves (no second card, no slip booked).
      await t.tap(find.byKey(const ValueKey('do-1')), warnIfMissed: false);
      await t.tap(find.byKey(const ValueKey('stand-under')), warnIfMissed: false);
      await _pump(t, 3000);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(M4GateMistakes.doOnLoad.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes, hasLength(1));
      expect(c.read(gameSaveProvider).mistakes.single.deadly, isTrue);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('no start button: the docket opens from the chip and closes', (t) async {
      final c = await _open(t, 8);
      final start = RegExp('শুরু');
      bool startButton() => find
          .byWidgetPredicate((w) =>
              (w is Text && start.hasMatch(w.data ?? '')) || (w is Semantics && (w.properties.button ?? false) && start.hasMatch(w.properties.label ?? '')))
          .evaluate()
          .isNotEmpty;
      expect(startButton(), isFalse);
      await t.tap(find.text('ডকেট'));
      await _pump(t, 400);
      expect(find.byKey(const ValueKey('docket-modal')), findsOneWidget);
      expect(startButton(), isFalse);
      await t.tap(find.byKey(const ValueKey('docket-close')));
      await _pump(t, 400);
      expect(find.byKey(const ValueKey('docket-modal')), findsNothing);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('tapping the guide restates the task a different way, at no cost', (t) async {
      final c = await _open(t, 8);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final before = _score();
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      final tasks = M4GateLines.tasks[M4GateStation.doOpen]!;
      expect(lines.every(tasks.contains), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      expect(_score(), before);
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });

    testWidgets('three slips: the StruckOutCard, the play failed', (t) async {
      final c = await _open(t, 4);
      await _tapKey(t, 'lt-switch');
      await _tapKey(t, 'stand-side');
      for (var i = 0; i < 3; i++) {
        await _tapKey(t, 'do-0', ms: 1200);
        expect(find.text(M4GateMistakes.doNoPpe.textBn), findsOneWidget);
        expect(find.byKey(const ValueKey('freeze')), findsNothing);
        await t.tap(find.text(MistakeLines.gotIt));
        await _pump(t, 800);
      }
      expect(find.byType(StruckOutCard), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress[_rung], isNot('cleared'));
      expect(s.rankIndex, lessThan(4));
      expect(s.mistakes.where((m) => !m.deadly), isNotEmpty);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a station pays only from the table, once — a second tap is ignored', (t) async {
      const seed = 31;
      final deal = M4GateRun(seed);
      final c = await _open(t, seed);
      await _playDo(t);
      final before = _score();
      await _tapKey(t, 'gauge');
      await t.tap(_label(M4GateLines.irGun));
      await _pump(t, 400);
      final key = deal.oilLow ? 'oil-report' : 'oil-normal';
      await _tapKey(t, key, ms: 100);
      // Second and third taps in the praise window (and on a wrong call).
      await t.tap(find.byKey(ValueKey(key)), warnIfMissed: false);
      await t.tap(find.byKey(const ValueKey('oil-engineOil')), warnIfMissed: false);
      await _pump(t, 200);
      expect(_score(), before, reason: 'nothing is paid before the reason');
      expect(find.byType(MistakeCard), findsNothing);
      await _reason(t, M4GateLines.whyOilQ, M4GateLines.whyOilRight);
      final paid = _score() - before;
      expect(paid, greaterThan(0));
      expect(paid, lessThanOrEqualTo(40), reason: 'one station, one payout');
      expect(find.text('আর্থ টেস্ট'), findsOneWidget);
      await _pump(t, 3000);
      expect(find.byType(ChoiceDeck), findsNothing, reason: 'no second reason deck');
      expect(_score(), before + paid);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('the coworker comes even on a fast play; listening to him is a slip', (t) async {
      const seed = 21;
      final deal = M4GateRun(seed);
      final c = await _open(t, seed);
      await _playDo(t);
      await _playOil(t, deal);
      await _playEarth(t);
      expect(find.text('ইনসুলেটর বদল'), findsOneWidget);
      // At once, before his 1.2 s: the first earth waits for him.
      await t.tap(find.byKey(const ValueKey('earth-0')), warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const ValueKey('coworker')), findsOneWidget);
      await waitChoiceDeck(t);
      final wrong = [
        for (final x in M4GateLines.coworker.wrong)
          if (_label(x).evaluate().isNotEmpty) _label(x),
      ];
      expect(wrong, hasLength(2));
      await t.tap(wrong.first, warnIfMissed: false);
      await tapReasonProceed(t);
      await _pump(t, 1500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(M4GateMistakes.earthSkip.textBn), findsOneWidget);
      expect(find.byKey(const ValueKey('freeze')), findsNothing);
      final m = c.read(gameSaveProvider).mistakes;
      expect(m.where((x) => x.deadly), isEmpty, reason: 'listening is a slip');
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      // The play goes on: both earths, then the steps; he never comes back.
      await _tapKey(t, 'earth-0');
      await _tapKey(t, 'earth-1');
      expect(find.byKey(const ValueKey('coworker')), findsNothing);
      for (final s in M4InsStep.values) {
        await _tapKey(t, 'ins-${s.name}', ms: 500);
      }
      await _reason(t, M4GateLines.whyInsQ, M4GateLines.whyInsRight);
      expect(find.text('জাম্পার টাইট'), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('the cool clamp is a wrong flag: a slip card, no free answer', (t) async {
      const seed = 21;
      final deal = M4GateRun(seed);
      final c = await _open(t, seed);
      await _playDo(t);
      await _playOil(t, deal);
      await _playEarth(t);
      await _pump(t, 3000);
      await _pickRight(t, M4GateLines.coworker.right);
      await _pump(t, 2500);
      await _tapKey(t, 'earth-0');
      await _tapKey(t, 'earth-1');
      for (final s in M4InsStep.values) {
        await _tapKey(t, 'ins-${s.name}', ms: 500);
      }
      await _reason(t, M4GateLines.whyInsQ, M4GateLines.whyInsRight);
      await _tapKey(t, 'jclamp-${1 - deal.hotSide}', ms: 600);
      expect(find.text(M4GateMistakes.jumperWrongClamp.textBn), findsOneWidget);
      expect(c.read(guideDirectorProvider).line.contains('ঠিক আছে'), isFalse);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('over-calls cost a slip: "earthing OK" unread, an oil call unread', (t) async {
      final c = await _open(t, 6);
      await _playDo(t);
      // An oil call before the gauge and the heat are read.
      await _tapKey(t, 'oil-normal', ms: 600);
      expect(find.text(M4GateMistakes.oilUnread.textBn), findsOneWidget);
      expect(c.read(guideDirectorProvider).line.contains('ঠিক আছে'), isFalse);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      await _playOil(t, M4GateRun(6));
      // "Earthing OK" before any reading.
      await _tapKey(t, 'earth-ok', ms: 600);
      expect(find.text(M4GateMistakes.earthUntested.textBn), findsOneWidget);
      final m = c.read(gameSaveProvider).mistakes;
      expect(m.where((x) => x.deadly), isEmpty);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('gesture hint: after idle a sweep over every control, pressing none; a tap hides it', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, 8);
      final hint = find.byWidgetPredicate((w) => w is IdleHint && w.controller != null);
      expect(hint, findsOneWidget);
      IdleHintState state() => t.state<IdleHintState>(hint);
      expect(state().showing, isFalse);
      await _pump(t, GestureHints.idle.inMilliseconds + 600);
      expect(state().showing, isTrue, reason: 'the hand shows after idle');
      // Station 1 has the LT switch, two PPE, two stances and three DOs.
      expect(state().debugOptions.length, greaterThanOrEqualTo(6), reason: 'a sweep over all, never one answer');
      var pressed = false;
      for (var ms = 0; ms < 2000; ms += 50) {
        await t.pump(const Duration(milliseconds: 50));
        final f = state().debugFrame;
        if (f != null && (f.ripple != null || f.ring != null)) pressed = true;
      }
      expect(pressed, isFalse, reason: 'a sweep presses nothing');
      await t.tapAt(const Offset(200, 200));
      await t.pump(const Duration(milliseconds: 100));
      expect(state().showing, isFalse);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('gesture hint: three taps on the empty sky show the hand at once', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final c = await _open(t, 8);
      final hint = find.byWidgetPredicate((w) => w is IdleHint && w.controller != null);
      IdleHintState state() => t.state<IdleHintState>(hint);
      final before = _score();
      expect(state().showing, isFalse);
      for (var i = 0; i < GestureHints.missTaps; i++) {
        await t.tapAt(const Offset(60, 260));
        await t.pump(const Duration(milliseconds: 200));
      }
      await t.pump(const Duration(milliseconds: 100));
      expect(state().showing, isTrue, reason: 'taps on nothing count as misses');
      expect(_score(), before);
      expect(find.byType(MistakeCard), findsNothing);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('the docket chip and the guide wait while the reason deck is up', (t) async {
      final c = await _open(t, 8);
      await _tapKey(t, 'lt-switch');
      await t.tap(_label(M4GateLines.faceShield));
      await _pump(t, 200);
      await t.tap(_label(M4GateLines.gloves));
      await _pump(t, 200);
      await _tapKey(t, 'stand-side');
      for (var i = 0; i < 3; i++) {
        await _tapKey(t, 'do-$i', ms: 1200);
      }
      await _pump(t, 3000);
      await waitChoiceDeck(t);
      expect(find.byType(ChoiceDeck), findsOneWidget);
      final asked = c.read(guideDirectorProvider).line;
      await t.tap(find.text('ডকেট'), warnIfMissed: false);
      await _pump(t, 400);
      expect(find.byKey(const ValueKey('docket-modal')), findsNothing);
      final guide = find.byKey(const ValueKey('hud-guide'));
      await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
      await _pump(t, 400);
      expect(c.read(guideDirectorProvider).line, asked, reason: 'the open question stays');
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    test('two-button rows are dealt both ways across plays', () {
      final runs = [for (var s = 0; s < 64; s++) M4GateRun(s)];
      for (final (name, get) in <(String, bool Function(M4GateRun))>[
        ('temp', (r) => r.flipTemp),
        ('earth', (r) => r.flipEarth),
        ('dp', (r) => r.flipDp),
        ('lamp', (r) => r.flipLamp),
      ]) {
        expect(runs.map(get).toSet(), {true, false}, reason: name);
      }
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
