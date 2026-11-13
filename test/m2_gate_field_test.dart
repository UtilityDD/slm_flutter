// Module 2 rank gate (m2_gate_field.dart, pack gate_m2): the rules of all
// seven stations (dealt readings, the hands-on tool care), the option
// libraries, the art on disk, and full plays in the shell: a clean pass that
// unlocks the জুনিয়র rank, the deadly freeze, slips that cost (a good tool
// rejected), three slips strike out, the guide restates the task, the
// coworker comes even on a fast play and listening to him is a slip, the
// station ◆ is paid only from the table, no start button, the idle screen
// stays quiet and the gesture hint shows while the level waits.
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/choice_deck.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/full_scene_frame.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/gesture_hint.dart';
import 'package:slm_flutter/features/game/learn_voice_map.dart';
import 'package:slm_flutter/features/game/level_frame.dart' show StruckOutCard;
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m2_gate_field.dart';
import 'package:slm_flutter/features/game/m2_gate_field_world.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';
import 'support/reason_proceed.dart';

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

final _anyStart = find.textContaining(RegExp('শুরু'));

/// Picks the one right card on the deck up now (reason or coworker deck).
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

Future<void> _hold(WidgetTester t, String key, int ms) async {
  final g = await t.startGesture(t.getCenter(find.byKey(ValueKey(key))));
  await _pump(t, ms);
  await g.up();
  await _pump(t, 200);
}

Future<void> _gotIt(WidgetTester t) async {
  await t.tap(find.text(MistakeLines.gotIt).last, warnIfMissed: false);
  await _pump(t, 500);
}

int _levelScore(WidgetTester t) => t.widget<FullSceneFrame>(find.byType(FullSceneFrame)).levelScore;

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
  expect(_anyStart, findsNothing);
  await waitIntro(t);
  await _pump(t, 800);
  // Guide first: the play starts by itself, no docket to dismiss.
  expect(find.byKey(const ValueKey('docket-modal')), findsNothing);
  expect(_anyStart, findsNothing);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

int _seedWhere(bool Function(M2GateRun r) ok) {
  var s = 0;
  while (!ok(M2GateRun(s))) {
    s++;
  }
  return s;
}

// --- station plays ----------------------------------------------------------

/// Station 1 right (inspect each tool; pack the docket ones, reject the
/// traps). The station's ◆ wait on the table until the right reason.
Future<void> _playPack(WidgetTester t, M2GateRun deal, {int settle = 3500}) async {
  for (final tool in deal.shelf) {
    await _tapKey(t, 'shelf-${tool.name}', ms: 300);
    await _tapKey(t, M2GateRun.traps.contains(tool) ? 'reject' : 'pack', ms: 300);
  }
  await _pump(t, 3000);
  expect(find.text(M2GateLines.whyPackQ), findsWidgets);
  expect(_levelScore(t), 0, reason: 'the station pays only from the table');
  await _pickRight(t, M2GateLines.whyPackRight);
  expect(_levelScore(t), 20, reason: 'the table pays once, via the reason');
  await _pump(t, settle);
}

Future<void> _playDo(WidgetTester t, {int settle = 3500}) async {
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
  await _pump(t, settle);
}

Future<void> _liveDeadLive(WidgetTester t) async {
  await _tapKey(t, 'live-point');
  for (var i = 0; i < 3; i++) {
    await _tapKey(t, 'term-$i');
  }
  await _tapKey(t, 'live-point');
}

Future<void> _playDead(WidgetTester t, M2GateRun deal, {int settle = 3500}) async {
  expect(find.text('মৃত প্রমাণ'), findsOneWidget);
  await _tapKey(t, 'dial-acV');
  if (deal.liveLeft != null) {
    // One phase still reads line voltage: stop; the line is isolated again.
    await _liveDeadLive(t);
    expect(find.text(M2GateLines.stoppedRight), findsNothing);
    await _tapKey(t, 'stop-call', ms: 1500);
  }
  await _liveDeadLive(t);
  await _tapKey(t, 'dead-call', ms: 3000);
  await _pickRight(t, M2GateLines.whyDeadRight);
  await _pump(t, settle);
}

Future<void> _playSkin(WidgetTester t, {int settle = 3500}) async {
  expect(find.text('স্কিনিং ও ক্রিম্পিং'), findsOneWidget);
  await t.drag(find.byKey(const ValueKey('skin-hit')), const Offset(90, 0));
  await _pump(t, 1500);
  await t.tap(_label('AL 95'));
  await _pump(t, 400);
  await t.tap(_label('হাইড্রোলিক · ডাই 95'));
  await _pump(t, 400);
  await _hold(t, 'pump', 2000);
  await _pump(t, 2800);
  await _pickRight(t, M2GateLines.whyLugRight);
  await _pump(t, settle);
}

Future<void> _megCycle(WidgetTester t) async {
  await t.tap(_label(M2GateLines.discharge));
  await _pump(t, 500);
  await _tapKey(t, 'lead-line');
  await _tapKey(t, 'lead-earth');
  await _tapKey(t, 'megv-v500');
  await _hold(t, 'test', 2600);
  await t.tap(_label(M2GateLines.discharge));
  await _pump(t, 500);
  await t.tap(_label(M2GateLines.leadsOff));
  await _pump(t, 500);
}

Future<void> _playMegger(WidgetTester t, M2GateRun deal) async {
  expect(find.text('মেগার টেস্ট'), findsOneWidget);
  // The coworker comes and is refused.
  await _pickRight(t, M2GateLines.coworker.right);
  await _pump(t, 2500);
  await _megCycle(t);
  if (deal.megLowFirst) {
    expect(find.text(M2GateRun.megText(deal.megLowValue)), findsNothing, reason: 'the reading is painted, not a caption');
    await _tapKey(t, 'meg-bad-btn', ms: 1500);
    await _megCycle(t);
  }
  await _tapKey(t, 'meg-ok-btn', ms: 3000);
  await _pickRight(t, M2GateLines.whyMegRight);
  await _pump(t, 3500);
}

Future<void> _playPhase(WidgetTester t, M2GateRun deal) async {
  expect(find.text('ফেজ সিকোয়েন্স'), findsOneWidget);
  await t.tap(_label(M2GateLines.gloves));
  await _pump(t, 300);
  for (var i = 0; i < 3; i++) {
    await _tapKey(t, 'clip-$i');
  }
  if (deal.phaseReversed) await _tapKey(t, 'call-swapDead', ms: 1500);
  await _tapKey(t, 'call-keep', ms: 3000);
  await _pickRight(t, M2GateLines.whyPhaseRight);
  await _pump(t, 3500);
}

Future<void> _playCare(WidgetTester t) async {
  expect(find.text('হাতিয়ারের যত্ন'), findsOneWidget);
  await _tapKey(t, 'care-stick');
  await _hold(t, 'wipe', 1300);
  await _tapKey(t, 'spot-hooks', ms: 2200);
  await _tapKey(t, 'care-meter');
  await _tapKey(t, 'meter-switch');
  await _tapKey(t, 'spot-toolbox', ms: 2200);
  await _tapKey(t, 'care-pliers');
  await _hold(t, 'wipe', 1300);
  await _tapKey(t, 'oil-can-btn');
  await _tapKey(t, 'oil-joint');
  await _tapKey(t, 'spot-toolbox', ms: 2200);
  await _pump(t, 3000);
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ZlFx.setMuted(true);
  });

  group('rules', () {
    test('deal: nine tools, one flawed twin; lugs, crimps, phase, readings and call order dealt; plays differ', () {
      final flaws = <M2Flaw>{};
      final orders = <String>{};
      final rev = <bool>{};
      final live = <int?>{};
      final low = <bool>{};
      final good = <double>{};
      final calls = <String>{};
      for (var s = 0; s < 60; s++) {
        final r = M2GateRun(s);
        expect(r.shelf.toSet(), M2Tool.values.toSet());
        flaws.add(r.flaw);
        orders.add(r.shelf.map((e) => e.name).join());
        rev.add(r.phaseReversed);
        live.add(r.liveLeft);
        low.add(r.megLowFirst);
        good.add(r.megGoodValue);
        calls.add(r.phaseCalls.map((c) => c.name).join());
        expect(r.megLowValue, lessThan(1));
        expect(r.megGoodValue, greaterThanOrEqualTo(120));
      }
      expect(flaws, M2Flaw.values.toSet());
      expect(orders.length, greaterThan(40));
      expect(rev, {true, false});
      expect(live, {null, 0, 1, 2});
      expect(low, {true, false});
      expect(good.length, greaterThan(10));
      expect(calls.length, greaterThan(3));
    });

    test('1 pack: bamboo deadly, flawed twin a slip, rejecting a good tool is a slip', () {
      final r = M2GateRun(1);
      expect(r.packTool(M2Tool.bamboo), M2GateMistakes.bambooStick);
      expect(r.deadly, M2GateMistakes.bambooStick);

      final c = M2GateRun(1);
      final slip = c.packTool(M2Tool.flawed);
      expect(slip, c.flaw == M2Flaw.catTwo ? M2GateMistakes.catTwo : M2GateMistakes.damagedTool);
      expect(c.slips, 1);
      expect(c.rejectTool(M2Tool.pliers), M2GateMistakes.goodRejected);
      expect(c.slips, 2);
      expect(c.rejected, isEmpty, reason: 'the good tool stays on the shelf');
      for (final tool in M2GateRun.docketTools) {
        expect(c.packTool(tool), isNull);
      }
      expect(c.packDone, isFalse);
      expect(c.rejectTool(M2Tool.flawed), isNull);
      expect(c.rejectTool(M2Tool.bamboo), isNull);
      expect(c.packDone, isTrue);
      expect(c.slips, 2);
    });

    test('after a deadly move nothing else counts (ended guards)', () {
      final r = M2GateRun(1)..packTool(M2Tool.bamboo);
      expect(r.ended, isTrue);
      expect(r.rejectTool(M2Tool.flawed), isNull);
      expect(r.rejected, isEmpty);
      expect(r.packTool(M2Tool.pliers), isNull);
      expect(r.packed, isEmpty);
      expect(r.rejectTool(M2Tool.megger), isNull);
      r.dial = M2Dial.ohm;
      expect(r.probeLive(), isNull);
      expect(r.confirmDead(), isNull);
      expect(r.stopWork(), isNull);
      expect(r.listenedToCoworker(), isNull);
      expect(r.storeHeld(M2CareSpot.floor), isNull);
      expect(r.slips, 0);
      r.advanceStation();
      expect(r.completed, isEmpty);
      expect(r.deadly, M2GateMistakes.bambooStick);
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

    test('3 prove dead (dead line): V~ only, live-dead-live, HT deadly, a needless stop is a slip', () {
      final r = M2GateRun(_seedWhere((r) => r.liveLeft == null))..dial = M2Dial.ohm;
      expect(r.probeLive(), M2GateMistakes.mmDial);
      r.dial = M2Dial.acV;
      expect(r.probePhase(0), M2GateMistakes.liveFirst);
      expect(r.probeLive(), isNull);
      expect(r.readingLive(), matches(RegExp(r'^2[23]\d V$')));
      expect(r.probePhase(0), isNull);
      expect(r.readingPhase(0), matches(RegExp(r'^0\.\d V$')));
      expect(r.confirmDead(), M2GateMistakes.allPhases);
      expect(r.probePhase(1), isNull);
      expect(r.probePhase(2), isNull);
      expect(r.stopWork(), M2GateMistakes.needlessStop);
      expect(r.confirmDead(), M2GateMistakes.liveAfter);
      expect(r.probeLive(), isNull);
      expect(r.confirmDead(), isNull);
      expect(r.provenDead, isTrue);
      expect(M2GateRun(3).probeHt(), M2GateMistakes.mmOnHt);
    });

    test('3 prove dead (a phase still live): calling it dead is a slip; stop → isolate again → re-test', () {
      final r = M2GateRun(_seedWhere((r) => r.liveLeft != null))..dial = M2Dial.acV;
      final live = r.liveLeft!;
      expect(r.stopWork(), M2GateMistakes.needlessStop, reason: 'nothing read yet');
      r.probeLive();
      for (var i = 0; i < 3; i++) {
        r.probePhase(i);
      }
      expect(r.readingPhase(live), matches(RegExp(r'^2[23]\d V$')));
      r.probeLive();
      expect(r.confirmDead(), M2GateMistakes.deadCallLive);
      expect(r.stopWork(), isNull);
      expect(r.liveLeft, isNull);
      expect(r.tested, isEmpty);
      expect(r.liveBefore, isFalse);
      expect(r.readingPhase(live), matches(RegExp(r'^0\.\d V$')));
      r.probeLive();
      for (var i = 0; i < 3; i++) {
        r.probePhase(i);
      }
      r.probeLive();
      expect(r.confirmDead(), isNull);
      expect(r.slips, 2);
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

    void megTest(M2GateRun r) {
      r.dischargeCable();
      r.clipLead(line: true);
      r.clipLead(line: false);
      r.megV = M2MegV.v500;
      expect(r.runMegger(), isNull);
      r.dischargeCable();
      expect(r.removeLeads(), isNull);
    }

    test('5 megger: discharge first, 500V, discharge after; a good reading goes on, keeping it off is a slip', () {
      final r = M2GateRun(_seedWhere((r) => !r.megLowFirst));
      expect(r.clipLead(line: true), M2GateMistakes.megUndischarged);
      r.dischargeCable();
      expect(r.clipLead(line: true), isNull);
      expect(r.runMegger(), isNull, reason: 'no test without both leads');
      expect(r.clipLead(line: false), isNull);
      r.megV = M2MegV.v5000;
      expect(r.runMegger(), M2GateMistakes.megVolt);
      r.megV = M2MegV.v500;
      expect(r.runMegger(), isNull);
      expect(r.judgeMegger(ok: true), isNull, reason: 'no call before the leads are off');
      expect(r.removeLeads(), M2GateMistakes.megAfter);
      r.dischargeCable();
      expect(r.removeLeads(), isNull);
      expect(r.leadsOff, isTrue);
      expect(r.megValue, greaterThanOrEqualTo(1));
      expect(r.judgeMegger(ok: false), M2GateMistakes.megNeedless);
      expect(r.judgeMegger(ok: true), isNull);
      expect(r.megJudged, isTrue);
    });

    test('5 megger: below 1 MΩ the cable stays off — passing it is a slip; refusing replaces it and the test starts over', () {
      final r = M2GateRun(_seedWhere((r) => r.megLowFirst));
      megTest(r);
      expect(r.megValue, lessThan(1));
      expect(M2GateRun.megText(r.megValue), matches(RegExp(r'^0\.\d MΩ$')));
      expect(r.judgeMegger(ok: true), M2GateMistakes.megLow);
      expect(r.judgeMegger(ok: false), isNull);
      expect(r.cableReplaced, isTrue);
      expect(r.megTested || r.leadsOn || r.dischargedBefore || r.leadsOff, isFalse);
      expect(r.judgeMegger(ok: true), isNull, reason: 'not before the new test');
      megTest(r);
      expect(r.megValue, greaterThanOrEqualTo(120));
      expect(r.judgeMegger(ok: true), isNull);
      expect(r.megJudged, isTrue);
      expect(r.slips, 1);
    });

    test('6 phase: gloves or death; reversed → swap dead; never swap live', () {
      final bare = M2GateRun(6);
      expect(bare.clipPhase(0), M2GateMistakes.phaseNoGloves);

      final rev = M2GateRun(_seedWhere((r) => r.phaseReversed))..phaseGloves = true;
      for (var i = 0; i < 3; i++) {
        expect(rev.clipPhase(i), isNull);
      }
      expect(rev.phaseFwd, isFalse);
      expect(rev.decidePhase(M2PhaseCall.keep), M2GateMistakes.phaseIgnored);
      expect(rev.decidePhase(M2PhaseCall.swapDead), isNull);
      expect(rev.phaseFwd, isTrue);
      expect(rev.decidePhase(M2PhaseCall.keep), isNull);
      expect(rev.phaseDone, isTrue);

      final fwd = M2GateRun(_seedWhere((r) => !r.phaseReversed))..phaseGloves = true;
      for (var i = 0; i < 3; i++) {
        fwd.clipPhase(i);
      }
      expect(fwd.decidePhase(M2PhaseCall.swapDead), M2GateMistakes.phaseNeedless);
      expect(fwd.decidePhase(M2PhaseCall.swapLive), M2GateMistakes.phaseLiveSwap);
    });

    test('7 care by hand: wipe, meter OFF, oil the joint (not the handle), a place — never the floor', () {
      final r = M2GateRun(7);
      expect(r.storeHeld(M2CareSpot.hooks), isNull, reason: 'nothing in hand');
      r.pickCare(M2Care.stick);
      expect(r.storeHeld(M2CareSpot.hooks), M2GateMistakes.careStick, reason: 'not wiped');
      r.wipeHeld();
      expect(r.storeHeld(M2CareSpot.floor), M2GateMistakes.careStick);
      expect(r.storeHeld(M2CareSpot.toolbox), M2GateMistakes.careStick);
      expect(r.storeHeld(M2CareSpot.bag), isNull);
      expect(r.careHeld, isNull);

      r.pickCare(M2Care.meter);
      expect(r.storeHeld(M2CareSpot.toolbox), M2GateMistakes.careMeter, reason: 'still ON');
      r.switchMeterOff();
      expect(r.storeHeld(M2CareSpot.floor), M2GateMistakes.careFloor);
      expect(r.storeHeld(M2CareSpot.toolbox), isNull);

      r.pickCare(M2Care.pliers);
      r.wipeHeld();
      expect(r.storeHeld(M2CareSpot.toolbox), M2GateMistakes.carePliers, reason: 'not oiled');
      expect(r.oilPliers(joint: false), M2GateMistakes.carePliers);
      expect(r.oilPliers(joint: true), isNull);
      expect(r.storeHeld(M2CareSpot.toolbox), isNull);
      expect(r.careDone, isTrue);
      expect(r.slips, 7);
    });

    test('the mark: 15 per slip, pass at 55, all seven stations', () {
      final r = M2GateRun(7)..slips = 3;
      expect(r.percent, 55);
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

    test('the two-way calls read alike (no word only on the right one)', () {
      expectSameLength('dead calls', [M2GateLines.provenDead, M2GateLines.stopLive]);
      expectSameLength('megger calls', [M2GateLines.megOk, M2GateLines.megBad]);
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

    test('lines for recording; Bangla digits never on screen; no "এটা তো ঠিক" giveaway', () {
      expect(M2GateLines.recordable, isNotEmpty);
      final bnDigit = RegExp('[০-৯]');
      final screen = [
        ...M2GateLines.recordable,
        ...M2GateLines.stationTitles.values,
        ...M2GateLines.careSpots.values,
        M2GateLines.provenDead,
        M2GateLines.stopLive,
        M2GateLines.megOk,
        M2GateLines.megBad,
      ];
      for (final l in screen) {
        expect(bnDigit.hasMatch(l), isFalse, reason: l);
        expect(l.contains('এটা তো ঠিক'), isFalse, reason: l);
      }
      for (final m in M2GateMistakes.all) {
        expect(bnDigit.hasMatch(m.textBn), isFalse, reason: m.key);
      }
    });

    test('the coworker lines are known to the voice map or listed as unrecorded', () {
      // His clips are recorded by the director in one batch; until then a
      // line with no clip is silent (caption held), never the guide's voice.
      final cw = M2GateLines.coworker;
      for (final l in [cw.line, cw.exitLine]) {
        expect(l.trim(), isNotEmpty);
        expect(learnRivalVoice[l] == null || learnRivalVoice[l]!.startsWith('sounds/learn_voice/r_'), isTrue, reason: l);
      }
    });
  });

  group('page', () {
    testWidgets('a full clean play: seven stations, a live phase stopped, a low IR refused, the coworker refused, জুনিয়র unlocked',
        (t) async {
      // A deal with every branch: reversed phases, a phase still live after
      // the DO, and a first megger reading below 1 MΩ.
      final seed = _seedWhere((r) => r.phaseReversed && r.liveLeft != null && r.megLowFirst);
      final deal = M2GateRun(seed);
      final c = await _open(t, seed);

      expect(find.text('হাতিয়ার গোছানো'), findsOneWidget);
      await _playPack(t, deal);
      await _playDo(t);
      await _playDead(t, deal);
      await _playSkin(t);
      await _playMegger(t, deal);
      await _playPhase(t, deal);
      await _playCare(t);

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

    testWidgets('no start button: the docket opens from the station chip and only closes', (t) async {
      final c = await _open(t, 4);
      await t.tap(find.text('ডকেট').first);
      await _pump(t, 400);
      expect(find.byKey(const ValueKey('docket-modal')), findsOneWidget);
      expect(_anyStart, findsNothing);
      await t.tap(find.text(M2GateLines.closeDocket));
      await _pump(t, 400);
      expect(find.byKey(const ValueKey('docket-modal')), findsNothing);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('packing the bamboo stick: the scene freezes and takes no touch, then the one deadly card', (t) async {
      final c = await _open(t, 5);
      await _tapKey(t, 'shelf-bamboo');
      await _tapKey(t, 'pack', ms: 700);
      expect(find.byKey(const ValueKey('freeze')), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      // A tap on another tool during the freeze does nothing.
      await t.tap(find.byKey(const ValueKey('shelf-pliers')), warnIfMissed: false);
      await _pump(t, 300);
      expect(find.byKey(const ValueKey('inspect')), findsNothing);
      expect(find.byKey(const ValueKey('freeze')), findsOneWidget);
      await _pump(t, 3000);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(M2GateMistakes.bambooStick.textBn), findsOneWidget);
      final saved = c.read(gameSaveProvider).mistakes;
      expect(saved, hasLength(1));
      expect(saved.single.deadly, isTrue);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('rejecting a good tool costs a slip with its card (no "it is fine" reply)', (t) async {
      final c = await _open(t, 8);
      await _tapKey(t, 'shelf-megger');
      await _tapKey(t, 'reject', ms: 600);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(M2GateMistakes.goodRejected.textBn), findsOneWidget);
      expect(find.textContaining('এটা তো ঠিক'), findsNothing);
      expect(c.read(gameSaveProvider).mistakes.single.key, 'm2/gate/good-rejected');
      await _gotIt(t);
      // The megger is still on the shelf to pack.
      await _tapKey(t, 'shelf-megger');
      expect(find.byKey(const ValueKey('inspect')), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('the praise window takes no touch: a step tapped while the ◆ wait on the table does nothing', (t) async {
      final seed = _seedWhere((r) => r.liveLeft == null);
      final deal = M2GateRun(seed);
      final c = await _open(t, seed);
      await _playPack(t, deal);
      await _tapKey(t, 'lt-switch');
      await t.tap(_label(M2GateLines.faceShield));
      await _pump(t, 200);
      await t.tap(_label(M2GateLines.gloves));
      await _pump(t, 200);
      await _tapKey(t, 'stand-side');
      for (var i = 0; i < 2; i++) {
        await _tapKey(t, 'do-$i', ms: 1200);
      }
      final worker = find.byKey(const ValueKey('worker'));
      final before = t.getRect(worker);
      // The last DO: the station is won and its ◆ go on the table.
      await t.tap(find.byKey(const ValueKey('do-2')), warnIfMissed: false);
      await _pump(t, 700);
      // A step under the DO now must not move the worker (nor cost a slip).
      await t.tap(find.byKey(const ValueKey('stand-under')), warnIfMissed: false);
      await _pump(t, 300);
      expect(t.getRect(worker), before);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _pickRight(t, M2GateLines.whyDoRight);
      expect(_levelScore(t), greaterThan(20), reason: 'the DO station paid from the table');
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('three slips strike out: the StruckOutCard insists on the lesson', (t) async {
      final c = await _open(t, 9);
      for (final tool in [M2Tool.pliers, M2Tool.megger, M2Tool.crimper]) {
        await _tapKey(t, 'shelf-${tool.name}');
        await _tapKey(t, 'reject', ms: 600);
        expect(find.byType(MistakeCard), findsOneWidget);
        await _gotIt(t);
      }
      expect(find.byType(StruckOutCard), findsOneWidget);
      // The same slip three times: one book entry, counted three times.
      final saved = c.read(gameSaveProvider).mistakes;
      expect(saved, hasLength(1));
      expect(saved.single.key, 'm2/gate/good-rejected');
      expect(saved.single.count, 3);
      // Struck out: the scene takes no more moves.
      await t.tap(find.byKey(const ValueKey('shelf-hotStick')), warnIfMissed: false);
      await _pump(t, 300);
      expect(find.byKey(const ValueKey('inspect')), findsNothing);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('tapping the guide restates the task, a different way each time', (t) async {
      final c = await _open(t, 2);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      final tasks = M2GateLines.tasks[M2GateStation.pack]!;
      expect(lines.every(tasks.contains), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('the coworker comes even on a fast play (TEST waits for him); listening is a slip', (t) async {
      final seed = _seedWhere((r) => r.liveLeft == null && !r.megLowFirst);
      final deal = M2GateRun(seed);
      final c = await _open(t, seed);
      await _playPack(t, deal);
      await _playDo(t);
      await _playDead(t, deal);
      await _playSkin(t, settle: 0);

      // Megger at once, faster than his timer.
      expect(find.text('মেগার টেস্ট'), findsOneWidget);
      await t.tap(_label(M2GateLines.discharge));
      await _pump(t, 50);
      await _tapKey(t, 'lead-line', ms: 50);
      await _tapKey(t, 'lead-earth', ms: 50);
      await _tapKey(t, 'megv-v500', ms: 50);
      expect(find.byKey(const ValueKey('coworker')), findsNothing);
      final g = await t.startGesture(t.getCenter(find.byKey(const ValueKey('test'))));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const ValueKey('coworker')), findsOneWidget, reason: 'TEST held for him');
      await g.up();
      await waitChoiceDeck(t);
      final listen = [
        for (final x in M2GateLines.coworker.wrong)
          if (_label(x).evaluate().isNotEmpty) _label(x),
      ];
      expect(listen, isNotEmpty);
      await t.tap(listen.first, warnIfMissed: false);
      await tapReasonProceed(t);
      await _pump(t, 600);
      expect(find.text(M2GateMistakes.megSkip.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, 'm2/gate/megger-skip');
      await _gotIt(t);
      // The megger still has to be done: the test runs now.
      await _hold(t, 'test', 2600);
      await t.tap(_label(M2GateLines.discharge));
      await _pump(t, 500);
      await t.tap(_label(M2GateLines.leadsOff));
      await _pump(t, 500);
      expect(find.byKey(const ValueKey('meg-ok-btn')), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a strike-out at the megger: the coworker never walks in over the StruckOutCard', (t) async {
      final seed = _seedWhere((r) => r.liveLeft == null && !r.megLowFirst);
      final deal = M2GateRun(seed);
      final c = await _open(t, seed);
      // Two slips on the shelf: reject two good tools (they stay to be packed).
      final good = [for (final x in deal.shelf) if (!M2GateRun.traps.contains(x)) x];
      for (final tool in good.take(2)) {
        await _tapKey(t, 'shelf-${tool.name}');
        await _tapKey(t, 'reject', ms: 600);
        expect(find.byType(MistakeCard), findsOneWidget);
        await _gotIt(t);
      }
      for (final tool in deal.shelf) {
        await _tapKey(t, 'shelf-${tool.name}', ms: 300);
        await _tapKey(t, M2GateRun.traps.contains(tool) ? 'reject' : 'pack', ms: 300);
      }
      await _pump(t, 3000);
      await _pickRight(t, M2GateLines.whyPackRight);
      await _pump(t, 3500);
      await _playDo(t);
      await _playDead(t, deal);
      await _playSkin(t, settle: 0);

      // Megger at once: a lead clipped before discharging is the third slip.
      expect(find.text('মেগার টেস্ট'), findsOneWidget);
      expect(find.byKey(const ValueKey('coworker')), findsNothing);
      await _tapKey(t, 'lead-line', ms: 600);
      expect(find.text(M2GateMistakes.megUndischarged.textBn), findsOneWidget);
      await _gotIt(t);
      expect(find.byType(StruckOutCard), findsOneWidget);
      // His timer keeps trying; his moment is over.
      await _pump(t, 4500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.byKey(const ValueKey('coworker')), findsNothing);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('the gesture hint shows while the level waits (and not over the intro)', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final hand = find.byKey(const ValueKey('gesture-hint'));
      final c = await _open(t, 6);
      expect(hand, findsNothing);
      await _pump(t, 9000);
      expect(hand, findsOneWidget);
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
