// Module 2 rank gate (m2_gate_field.dart, pack gate_m2): the rules of all
// seven stations, the option libraries, the art on disk, and a full clean
// play in the shell that unlocks the জুনিয়র rank; a deadly pick freezes and
// shows its card; the idle screen stays quiet.
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
import 'package:slm_flutter/features/game/m2_gate_field.dart';
import 'package:slm_flutter/features/game/m2_gate_field_world.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';

const _rung = 'm2/gate';
final _pack = m2GateFieldPacks['gate_m2']!;

LevelContext _ctx() => const LevelContext(
      rungId: _rung,
      kind: CatalogRungKind.gate,
      lessonId: '2.10',
      lessonTitleBn: 'জুনিয়রের ডকেট · র‍্যাঙ্ক গেট',
      ladderStep: 59,
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
  await t.pump();
  // Wait for reason zoom (coworker decks have no proceed).
  for (var i = 0; i < 40 && find.byKey(const ValueKey('reason-proceed-btn')).evaluate().isEmpty; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
  final go = find.byKey(const ValueKey('reason-proceed-btn'));
  if (go.evaluate().isNotEmpty) {
    await t.tap(go, warnIfMissed: false);
    await t.pump();
  }
}

Future<void> _tapKey(WidgetTester t, String key, {int ms = 400}) async {
  final f = find.byKey(ValueKey(key));
  expect(f, findsOneWidget, reason: key);
  await t.tap(f, warnIfMissed: false);
  await _pump(t, ms);
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
    builder: (_) => M2GateFieldPage(ctx: _ctx(), pack: _pack, muted: true, seed: seed),
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

/// Plays station 1 right (inspect each tool; pack the docket ones, reject the traps).
Future<void> playPack(WidgetTester t, M2GateRun deal) async {
  for (final tool in deal.shelf) {
    await _tapKey(t, 'shelf-${tool.name}', ms: 300);
    await _tapKey(t, M2GateRun.traps.contains(tool) ? 'reject' : 'pack', ms: 300);
  }
  await _pump(t, 3000);
  expect(find.text(M2GateLines.whyPackQ), findsWidgets);
  await _pickRight(t, M2GateLines.whyPackRight);
  await _pump(t, 3500);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ZlFx.setMuted(true);
  });

  group('rules', () {
    test('deal: nine tools, one flawed twin, lugs/crimps/phase dealt; plays differ', () {
      final flaws = <M2Flaw>{};
      final orders = <String>{};
      final rev = <bool>{};
      for (var s = 0; s < 40; s++) {
        final r = M2GateRun(s);
        expect(r.shelf.toSet(), M2Tool.values.toSet());
        flaws.add(r.flaw);
        orders.add(r.shelf.map((e) => e.name).join());
        rev.add(r.phaseReversed);
      }
      expect(flaws, M2Flaw.values.toSet());
      expect(orders.length, greaterThan(30));
      expect(rev, {true, false});
    });

    test('1 pack: bamboo deadly, flawed twin a slip, good tools cannot be rejected', () {
      final r = M2GateRun(1);
      expect(r.packTool(M2Tool.bamboo), M2GateMistakes.bambooStick);
      expect(r.deadly, M2GateMistakes.bambooStick);

      final c = M2GateRun(1);
      final slip = c.packTool(M2Tool.flawed);
      expect(slip, c.flaw == M2Flaw.catTwo ? M2GateMistakes.catTwo : M2GateMistakes.damagedTool);
      expect(c.slips, 1);
      expect(c.rejectTool(M2Tool.pliers), isFalse);
      for (final tool in M2GateRun.docketTools) {
        expect(c.packTool(tool), isNull);
      }
      expect(c.packDone, isFalse);
      expect(c.rejectTool(M2Tool.flawed), isTrue);
      expect(c.rejectTool(M2Tool.bamboo), isTrue);
      expect(c.packDone, isTrue);
    });

    test('2 DO: on-load and under are deadly, no PPE a slip, off-load + side + PPE opens', () {
      final load = M2GateRun(2)..stance = M2Stance.side;
      expect(load.pullDo(0), M2GateMistakes.doOnLoad);

      final under = M2GateRun(2)
        ..switchLtOff()
        ..stance = M2Stance.under
        ..faceShield = true
        ..doGloves = true;
      expect(under.pullDo(0), M2GateMistakes.doUnder);

      final r = M2GateRun(2)
        ..switchLtOff()
        ..stance = M2Stance.side;
      expect(r.pullDo(0), M2GateMistakes.doNoPpe);
      expect(r.deadly, isNull);
      r
        ..faceShield = true
        ..doGloves = true;
      for (var i = 0; i < 3; i++) {
        expect(r.pullDo(i), isNull);
      }
      expect(r.doDone, isTrue);
      expect(r.caught, contains('অফ-লোডে DO খোলা'));
    });

    test('3 prove dead: V~ only, live-dead-live, HT is deadly', () {
      final r = M2GateRun(3)..dial = M2Dial.ohm;
      expect(r.probeLive(), M2GateMistakes.mmDial);
      r.dial = M2Dial.acV;
      expect(r.probePhase(0), M2GateMistakes.liveFirst);
      expect(r.probeLive(), isNull);
      expect(r.probePhase(0), isNull);
      expect(r.confirmDead(), M2GateMistakes.allPhases);
      expect(r.probePhase(1), isNull);
      expect(r.probePhase(2), isNull);
      expect(r.confirmDead(), M2GateMistakes.liveAfter);
      expect(r.probeLive(), isNull);
      expect(r.confirmDead(), isNull);
      expect(r.provenDead, isTrue);
      expect(M2GateRun(3).probeHt(), M2GateMistakes.mmOnHt);
    });

    test('4 skin and crimp: away from the body, AL 95, die 95, full cycle', () {
      final r = M2GateRun(4);
      expect(r.skin(awayFromBody: false), M2GateMistakes.skinToward);
      expect(r.skin(awayFromBody: true), isNull);
      expect(r.chooseLug(M2Lug.cu95), M2GateMistakes.lugMetal);
      expect(r.chooseLug(M2Lug.al70), M2GateMistakes.lugSize);
      expect(r.chooseLug(M2Lug.al120), M2GateMistakes.lugSize);
      expect(r.chooseLug(M2Lug.al95), isNull);
      expect(r.chooseCrimp(M2Crimp.pliers), M2GateMistakes.crimpPliers);
      expect(r.chooseCrimp(M2Crimp.hyd70), M2GateMistakes.wrongDie);
      expect(r.chooseCrimp(M2Crimp.hyd95), isNull);
      expect(r.crimp(fullCycle: false), M2GateMistakes.underCrimp);
      expect(r.crimp(fullCycle: true), isNull);
      expect(r.crimped, isTrue);
    });

    test('5 megger: discharge first, 500V, discharge after', () {
      final r = M2GateRun(5);
      expect(r.clipLead(line: true), M2GateMistakes.megUndischarged);
      r.dischargeCable();
      expect(r.clipLead(line: true), isNull);
      expect(r.runMegger(), isNull, reason: 'no test without both leads');
      expect(r.clipLead(line: false), isNull);
      r.megV = M2MegV.v5000;
      expect(r.runMegger(), M2GateMistakes.megVolt);
      r.megV = M2MegV.v500;
      expect(r.runMegger(), isNull);
      expect(r.removeLeads(), M2GateMistakes.megAfter);
      r.dischargeCable();
      expect(r.removeLeads(), isNull);
      expect(r.leadsOff, isTrue);
    });

    test('6 phase: gloves or death; reversed → swap dead; never swap live', () {
      final bare = M2GateRun(6);
      expect(bare.clipPhase(0), M2GateMistakes.phaseNoGloves);

      int seedFor(bool reversed) {
        var s = 0;
        while (M2GateRun(s).phaseReversed != reversed) {
          s++;
        }
        return s;
      }

      final rev = M2GateRun(seedFor(true))..phaseGloves = true;
      for (var i = 0; i < 3; i++) {
        expect(rev.clipPhase(i), isNull);
      }
      expect(rev.phaseFwd, isFalse);
      expect(rev.decidePhase(M2PhaseCall.keep), M2GateMistakes.phaseIgnored);
      expect(rev.decidePhase(M2PhaseCall.swapDead), isNull);
      expect(rev.phaseFwd, isTrue);
      expect(rev.decidePhase(M2PhaseCall.keep), isNull);
      expect(rev.phaseDone, isTrue);

      final fwd = M2GateRun(seedFor(false))..phaseGloves = true;
      for (var i = 0; i < 3; i++) {
        fwd.clipPhase(i);
      }
      expect(fwd.decidePhase(M2PhaseCall.swapDead), M2GateMistakes.phaseNeedless);
      expect(fwd.decidePhase(M2PhaseCall.swapLive), M2GateMistakes.phaseLiveSwap);
    });

    test('7 care and the mark: 15 per slip, pass at 55, all seven stations', () {
      final r = M2GateRun(7);
      expect(r.care(M2Care.pliers, right: false), M2GateMistakes.carePliers);
      for (final c in M2Care.values) {
        expect(r.care(c, right: true), isNull);
      }
      expect(r.careDone, isTrue);
      expect(r.percent, 85);
      for (var i = 0; i < M2GateStation.values.length; i++) {
        r.advanceStation();
      }
      expect(r.done, isTrue);
      expect(r.passed, isTrue);
      r.slips = 4;
      expect(r.passed, isFalse);
    });
  });

  group('content', () {
    test('reason libraries: ≥2 right, ≥5 wrong, lengths within 1.3×', () {
      final libs = {
        'pack': (M2GateLines.whyPackRight, M2GateLines.whyPackWrong),
        'do': (M2GateLines.whyDoRight, M2GateLines.whyDoWrong),
        'dead': (M2GateLines.whyDeadRight, M2GateLines.whyDeadWrong),
        'lug': (M2GateLines.whyLugRight, M2GateLines.whyLugWrong),
        'megger': (M2GateLines.whyMegRight, M2GateLines.whyMegWrong),
        'phase': (M2GateLines.whyPhaseRight, M2GateLines.whyPhaseWrong),
        for (final c in M2Care.values) 'care ${c.name}': (M2GateLines.careRight[c]!, M2GateLines.careWrong[c]!),
      };
      for (final e in libs.entries) {
        expectLibrary(e.key, e.value.$1, e.value.$2);
        expectSameLength(e.key, [...e.value.$1, ...e.value.$2]);
      }
      final cw = M2GateLines.coworker;
      expectLibrary('coworker', cw.right, cw.wrong, minRight: 2, minWrong: 4);
      expectSameLength('coworker', [...cw.right, ...cw.wrong]);
    });

    test('a deal: one right, three different options', () {
      final d = dealChoices(M2GateLines.whyMegRight, M2GateLines.whyMegWrong, math.Random(9));
      expect(d.where((o) => o.correct), hasLength(1));
      expect(d.map((o) => o.textBn).toSet(), hasLength(3));
    });

    test('mistakes: unique m2/gate keys, art on disk, a teaching lesson each', () {
      final keys = <String>{};
      for (final m in M2GateMistakes.all) {
        expect(m.key, startsWith('m2/gate/'));
        expect(keys.add(m.key), isTrue, reason: m.key);
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(M2GateMistakes.lessonOf[m.key], isNotNull, reason: m.key);
        expect(m.textBn.length, lessThan(140), reason: m.key);
      }
      expect(M2GateMistakes.all.where((m) => m.deadly).map((m) => m.key).toSet(), {
        'm2/gate/bamboo-stick',
        'm2/gate/do-on-load',
        'm2/gate/do-under',
        'm2/gate/mm-on-ht',
        'm2/gate/phase-no-gloves',
        'm2/gate/phase-live-swap',
      });
    });

    test('lines for recording; Bangla digits never on screen', () {
      expect(M2GateLines.recordable, isNotEmpty);
      final bnDigit = RegExp('[০-৯]');
      for (final l in [...M2GateLines.recordable, ...M2GateLines.stationTitles.values]) {
        expect(bnDigit.hasMatch(l), isFalse, reason: l);
      }
      for (final m in M2GateMistakes.all) {
        expect(bnDigit.hasMatch(m.textBn), isFalse, reason: m.key);
      }
    });
  });

  group('page', () {
    testWidgets('a full clean play: seven stations, the coworker refused, জুনিয়র unlocked', (t) async {
      // A reversed phase deal, so the swap-dead path is played too.
      var seed = 0;
      while (!M2GateRun(seed).phaseReversed) {
        seed++;
      }
      final deal = M2GateRun(seed);
      final c = await _open(t, seed);

      // 1 — pack.
      expect(find.text('হাতিয়ার গোছানো'), findsOneWidget);
      await playPack(t, deal);

      // 2 — DO.
      expect(find.text('DO খোলা · হট স্টিক'), findsOneWidget);
      await _tapKey(t, 'lt-switch');
      await t.tap(_label(M2GateLines.faceShield));
      await _pump(t, 200);
      await t.tap(_label(M2GateLines.gloves));
      await _pump(t, 200);
      await _tapKey(t, 'stand-side');
      for (var i = 0; i < 3; i++) {
        await _tapKey(t, 'do-$i', ms: 1200);
      }
      await _pump(t, 3000);
      expect(find.text(M2GateLines.whyDoQ), findsWidgets);
      await _pickRight(t, M2GateLines.whyDoRight);
      await _pump(t, 3500);

      // 3 — prove dead.
      expect(find.text('মৃত প্রমাণ'), findsOneWidget);
      await _tapKey(t, 'dial-acV');
      await _tapKey(t, 'live-point');
      for (var i = 0; i < 3; i++) {
        await _tapKey(t, 'term-$i');
      }
      await _tapKey(t, 'live-point');
      await t.tap(_label(M2GateLines.provenDead));
      await _pump(t, 3000);
      await _pickRight(t, M2GateLines.whyDeadRight);
      await _pump(t, 3500);

      // 4 — skin and crimp.
      expect(find.text('স্কিনিং ও ক্রিম্পিং'), findsOneWidget);
      await t.drag(find.byKey(const ValueKey('skin-hit')), const Offset(90, 0));
      await _pump(t, 1500);
      await t.tap(_label('AL 95'));
      await _pump(t, 400);
      await t.tap(_label('হাইড্রোলিক · ডাই 95'));
      await _pump(t, 400);
      final g = await t.startGesture(t.getCenter(find.byKey(const ValueKey('pump'))));
      await _pump(t, 2000);
      await g.up();
      await _pump(t, 3000);
      await _pickRight(t, M2GateLines.whyLugRight);
      await _pump(t, 3500);

      // 5 — megger; the coworker comes and is refused.
      expect(find.text('মেগার টেস্ট'), findsOneWidget);
      await _pump(t, 3000);
      await _pickRight(t, M2GateLines.coworker.right);
      await _pump(t, 2500);
      await t.tap(_label(M2GateLines.discharge));
      await _pump(t, 500);
      await _tapKey(t, 'lead-line');
      await _tapKey(t, 'lead-earth');
      await _tapKey(t, 'megv-v500');
      final m = await t.startGesture(t.getCenter(find.byKey(const ValueKey('test'))));
      await _pump(t, 2600);
      await m.up();
      await _pump(t, 300);
      await t.tap(_label(M2GateLines.discharge));
      await _pump(t, 500);
      await t.tap(_label(M2GateLines.leadsOff));
      await _pump(t, 3000);
      await _pickRight(t, M2GateLines.whyMegRight);
      await _pump(t, 3500);

      // 6 — phase sequence: reversed → switch off and swap → forward → keep.
      expect(find.text('ফেজ সিকোয়েন্স'), findsOneWidget);
      await t.tap(_label(M2GateLines.gloves));
      await _pump(t, 300);
      for (var i = 0; i < 3; i++) {
        await _tapKey(t, 'clip-$i');
      }
      await _tapKey(t, 'call-swapDead', ms: 1500);
      await _tapKey(t, 'call-keep', ms: 3000);
      await _pickRight(t, M2GateLines.whyPhaseRight);
      await _pump(t, 3500);

      // 7 — tool care.
      expect(find.text('হাতিয়ারের যত্ন'), findsOneWidget);
      for (final cc in M2Care.values) {
        await _tapKey(t, 'care-${cc.name}', ms: 900);
        await _pickRight(t, M2GateLines.careRight[cc]!);
        await _pump(t, 2000);
      }
      await _pump(t, 3000);

      final s = c.read(gameSaveProvider);
      expect(s.rungProgress[_rung], 'cleared');
      expect(s.rankIndex, 2);
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung[_rung], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text('নতুন র‍্যাঙ্ক: জুনিয়র · হাতিয়ারের ওস্তাদ'), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('packing the bamboo stick: the scene freezes, then the deadly card', (t) async {
      final c = await _open(t, 5);
      await _tapKey(t, 'shelf-bamboo');
      await _tapKey(t, 'pack', ms: 700);
      expect(find.byKey(const ValueKey('freeze')), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3000);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(M2GateMistakes.bambooStick.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.deadly, isTrue);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a good tool cannot be rejected (no strike, no card)', (t) async {
      final c = await _open(t, 8);
      await _tapKey(t, 'shelf-megger');
      await _tapKey(t, 'reject', ms: 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
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
        debugPrint('PERF m2_gate_field ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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
