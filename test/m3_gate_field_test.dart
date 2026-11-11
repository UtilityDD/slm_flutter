// Module 3 rank gate (m3_gate_field.dart, pack gate_m3): the rules of all
// seven stations, the option libraries, the art on disk, and a full clean
// play in the shell that unlocks the টেকনিশিয়ান rank; a deadly pick freezes
// and shows its card; the idle screen stays quiet.
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
import 'package:slm_flutter/features/game/m3_gate_field.dart';
import 'package:slm_flutter/features/game/m3_gate_field_world.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';

const _rung = 'm3/gate';
final _pack = m3GateFieldPacks['gate_m3']!;

LevelContext _ctx() => const LevelContext(
      rungId: _rung,
      kind: CatalogRungKind.gate,
      lessonId: '3.10',
      lessonTitleBn: 'টেকনিশিয়ানের ডকেট · র‍্যাঙ্ক গেট',
      ladderStep: 89,
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

Future<void> _tapLabel(WidgetTester t, String l, {int ms = 400}) async {
  expect(_label(l), findsOneWidget, reason: l);
  await t.tap(_label(l), warnIfMissed: false);
  await _pump(t, ms);
}

Future<void> _reason(WidgetTester t, String q, List<String> right) async {
  await _pump(t, 3000);
  expect(find.text(q), findsWidgets);
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
    builder: (_) => M3GateFieldPage(ctx: _ctx(), pack: _pack, muted: true, seed: seed),
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

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ZlFx.setMuted(true);
  });

  group('rules', () {
    test('deal: three faulty parts, every dealt choice varies; plays differ', () {
      final noMid = <bool>{};
      final la = <M3LaFault?>{};
      final guard = <M3GuardFault>{};
      final faults = <String>{};
      for (var s = 0; s < 60; s++) {
        final r = M3GateRun(s);
        expect(r.faults.values.where((f) => f != null), hasLength(3));
        noMid.add(r.noMid);
        la.add(r.laFault);
        guard.add(r.guardFault);
        faults.add(r.faults.entries.map((e) => '${e.key.name}${e.value?.name}').join());
      }
      expect(noMid, {true, false});
      expect(la, {null, M3LaFault.crack, M3LaFault.hanging});
      expect(guard, M3GuardFault.values.toSet());
      expect(faults.length, greaterThan(8));
    });

    test('1 SLD: wrong symbol a slip, missing NO deadly, AB + NO plans', () {
      final r = M3GateRun(1);
      expect(r.markSym(M3SldSym.la), M3GateMistakes.wrongSymbol);
      expect(r.markSym(M3SldSym.dtrA), M3GateMistakes.wrongSymbol);
      expect(r.slips, 2);
      expect(r.confirmPlan(), isNull, reason: 'nothing marked: no cost');
      expect(r.planned, isFalse);
      r.markSym(M3SldSym.ab);
      expect(r.confirmPlan(), M3GateMistakes.ringBackfeed);
      expect(r.deadly, M3GateMistakes.ringBackfeed);

      final n = M3GateRun(1)..markSym(M3SldSym.no);
      expect(n.confirmPlan(), M3GateMistakes.sourceAb);
      n.markSym(M3SldSym.ab);
      expect(n.confirmPlan(), isNull);
      expect(n.planned, isTrue);
    });

    test('2 patrol: a faulty part passed is its slip; a sound part cannot be flagged', () {
      final r = M3GateRun(2);
      for (final p in M3Part.values) {
        final f = r.faults[p];
        if (f == null) {
          expect(r.partFault(p), isFalse);
          expect(r.partOk(p), isNull);
        } else {
          expect(r.partOk(p), M3GateMistakes.forFault(f));
          expect(r.partFault(p), isTrue);
        }
      }
      expect(r.slips, 3);
      expect(r.patrolDone, isTrue);
    });

    test('3 DO and LA: all three open first; thick wire deadly; LA verdicts', () {
      final r = M3GateRun(3);
      expect(r.chooseLink(M3Link.rated), M3GateMistakes.allThree);
      for (var i = 0; i < 3; i++) {
        r.openDo(i);
      }
      expect(r.allDoOpen, isTrue);
      expect(r.chooseLink(M3Link.anyWire), M3GateMistakes.anyWire);
      expect(r.chooseLink(M3Link.overRated), M3GateMistakes.overRated);
      expect(r.chooseLink(M3Link.rated), isNull);
      expect(M3GateRun(3).chooseLink(M3Link.thickWire), M3GateMistakes.thickWire);

      var s = 0;
      while (M3GateRun(s).laFault != M3LaFault.hanging) {
        s++;
      }
      final bad = M3GateRun(s);
      expect(bad.laOk(), M3GateMistakes.laHanging);
      expect(bad.laReplace(), isTrue);
      s = 0;
      while (M3GateRun(s).laFault != null) {
        s++;
      }
      final good = M3GateRun(s);
      expect(good.laReplace(), isFalse);
      expect(good.laOk(), isNull);
      expect(good.laJudged, isTrue);
    });

    test('4 DTR: health first, LT on is deadly, LT off turns the tap', () {
      var s = 0;
      while (!(M3GateRun(s).gelPinkDealt && M3GateRun(s).oilLeakDealt)) {
        s++;
      }
      final r = M3GateRun(s);
      expect(r.turnTap(), isNull);
      expect(r.tapped, isFalse);
      expect(r.gelOk(), M3GateMistakes.gelPink);
      expect(r.oilOk(), M3GateMistakes.oilLeak);
      expect(r.gelReplace(), isTrue);
      expect(r.oilReport(), isTrue);
      expect(r.turnTap(), M3GateMistakes.tapLive);

      final ok = M3GateRun(s)
        ..gelReplace()
        ..oilReport()
        ..switchLtOff();
      expect(ok.turnTap(), isNull);
      expect(ok.tap, ok.tapTo);
    });

    test('5 pillar: PPE, test, the blown fuse, copper deadly, hot spot before lock', () {
      final r = M3GateRun(5);
      expect(r.testBus(), M3GateMistakes.pillarPpe);
      r
        ..pGloves = true
        ..pShield = true;
      expect(r.tapFuse(r.blownWay, r.blownPh), M3GateMistakes.noTest);
      expect(r.testBus(), isNull);
      r.tapFuse((r.blownWay + 1) % 3, r.blownPh);
      expect(r.pickingFuse, isFalse);
      r.tapFuse(r.blownWay, r.blownPh);
      expect(r.pickingFuse, isTrue);
      expect(r.fitHrc(M3Hrc.bigger), M3GateMistakes.hrcBigger);
      expect(r.fitHrc(M3Hrc.same), isNull);
      expect(r.lock(), M3GateMistakes.hotspot);
      r.tighten((r.hotBolt + 1) % 6);
      expect(r.tightened, isFalse);
      r.tighten(r.hotBolt);
      expect(r.lock(), isNull);
      expect(r.locked, isTrue);

      final c = M3GateRun(5)
        ..pGloves = true
        ..pShield = true
        ..testBus();
      c.tapFuse(c.blownWay, c.blownPh);
      expect(c.fitHrc(M3Hrc.copperStrip), M3GateMistakes.copperStrip);
      expect(c.deadly, isNotNull);
    });

    test('6 service and 7 guard: slips per step, bare-hand neutral and guard deadly', () {
      final r = M3GateRun(6);
      expect(r.serviceChoose(right: false), M3GateMistakes.wrongCore);
      expect(r.serviceChoose(right: true), isNull);
      expect(r.serviceChoose(right: false), M3GateMistakes.noBearer);
      expect(r.serviceChoose(right: true), isNull);
      expect(r.serviceChoose(right: false), M3GateMistakes.noDrip);
      expect(r.serviceChoose(right: true), isNull);
      expect(r.serviceChoose(right: false), M3GateMistakes.neutralBare);
      expect(r.deadly, M3GateMistakes.neutralBare);

      final g = M3GateRun(7);
      expect(g.touchGuard(g.guardFault), M3GateMistakes.guardBare);
      final h = M3GateRun(7)..gGloves = true;
      expect(h.energise(), h.guardFault == M3GuardFault.brokenWire ? M3GateMistakes.guardWire : M3GateMistakes.guardEarth);
      final other = M3GuardFault.values.firstWhere((f) => f != h.guardFault);
      expect(h.touchGuard(other), isNull);
      expect(h.guardFixed, isFalse);
      expect(h.touchGuard(h.guardFault), isNull);
      expect(h.energise(), isNull);
    });

    test('the mark: 15 per slip, pass at 55, all seven stations', () {
      final r = M3GateRun(8);
      for (var i = 0; i < M3GateStation.values.length; i++) {
        r.advanceStation();
      }
      expect(r.done, isTrue);
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
        'sld': (M3GateLines.whySldRight, M3GateLines.whySldWrong),
        'patrol': (M3GateLines.whyPatrolRight, M3GateLines.whyPatrolWrong),
        'fuse': (M3GateLines.whyFuseRight, M3GateLines.whyFuseWrong),
        'dtr': (M3GateLines.whyDtrRight, M3GateLines.whyDtrWrong),
        'pillar': (M3GateLines.whyPillarRight, M3GateLines.whyPillarWrong),
        'service': (M3GateLines.whyServiceRight, M3GateLines.whyServiceWrong),
        'guard': (M3GateLines.whyGuardRight, M3GateLines.whyGuardWrong),
      };
      for (final e in libs.entries) {
        expectLibrary(e.key, e.value.$1, e.value.$2);
        expectSameLength(e.key, [...e.value.$1, ...e.value.$2]);
      }
      final cw = M3GateLines.coworker;
      expectLibrary('coworker', cw.right, cw.wrong, minRight: 2, minWrong: 4);
      expectSameLength('coworker', [...cw.right, ...cw.wrong]);
    });

    test('a deal: one right, three different options', () {
      final d = dealChoices(M3GateLines.whyDtrRight, M3GateLines.whyDtrWrong, math.Random(9));
      expect(d.where((o) => o.correct), hasLength(1));
      expect(d.map((o) => o.textBn).toSet(), hasLength(3));
    });

    test('mistakes: unique keys led by their lesson id, art on disk, six deadly', () {
      final keys = <String>{};
      for (final m in M3GateMistakes.all) {
        expect(m.key, matches(RegExp(r'^3\.(10|[1-9])/m3_gate_field/[a-z-]+$')), reason: m.key);
        expect(keys.add(m.key), isTrue, reason: m.key);
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.textBn.length, lessThan(140), reason: m.key);
        expect(m.lessonPoint, isNotNull, reason: m.key);
      }
      expect(M3GateMistakes.all.where((m) => m.deadly).map((m) => m.key).toSet(), {
        '3.10/m3_gate_field/ring-no',
        '3.4/m3_gate_field/thick-wire',
        '3.6/m3_gate_field/tap-live',
        '3.7/m3_gate_field/copper-strip',
        '3.8/m3_gate_field/neutral-bare',
        '3.9/m3_gate_field/guard-bare',
      });
      expect(M3GateMistakes.lessonOf('3.10/m3_gate_field/ring-no'), '3.10');
    });

    test('lines for recording; Bangla digits never on screen; no পানি', () {
      expect(M3GateLines.recordable, isNotEmpty);
      final bnDigit = RegExp('[০-৯]');
      final all = [
        ...M3GateLines.recordable,
        ...M3GateLines.stationTitles.values,
        ...M3GateLines.linkNames.values,
        ...M3GateLines.hrcNames.values,
        for (final (a, b) in M3GateLines.serviceSteps) ...[a, b],
        for (final m in M3GateMistakes.all) m.textBn,
      ];
      for (final l in all) {
        expect(bnDigit.hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
    });
  });

  group('page', () {
    testWidgets('a full clean play: seven stations, the coworker refused, টেকনিশিয়ান unlocked', (t) async {
      const seed = 4;
      final deal = M3GateRun(seed);
      final c = await _open(t, seed);

      // 1 — SLD.
      expect(find.text('SLD পড়া'), findsOneWidget);
      await _tapKey(t, 'sym-ab');
      await _tapKey(t, 'sym-no');
      await _tapLabel(t, M3GateLines.planOk);
      await _reason(t, M3GateLines.whySldQ, M3GateLines.whySldRight);

      // 2 — patrol.
      expect(find.text('লাইন পেট্রোল'), findsOneWidget);
      for (final p in M3Part.values) {
        await _tapKey(t, 'part-${p.name}', ms: 300);
        await _tapKey(t, deal.faults[p] == null ? 'judge-ok' : 'judge-bad', ms: 500);
      }
      await _reason(t, M3GateLines.whyPatrolQ, M3GateLines.whyPatrolRight);

      // 3 — DO and LA.
      expect(find.text('DO ও LA'), findsOneWidget);
      for (var i = 0; i < 3; i++) {
        if (i != deal.dropped) await _tapKey(t, 'do-$i', ms: 1200);
      }
      await _tapKey(t, 'link-rated', ms: 600);
      await _tapKey(t, 'la', ms: 300);
      await _tapKey(t, deal.laFault == null ? 'judge-ok' : 'judge-bad', ms: 300);
      await _reason(t, M3GateLines.whyFuseQ, M3GateLines.whyFuseRight);

      // 4 — DTR; the coworker comes and is refused.
      expect(find.text('DTR ও ট্যাপ'), findsOneWidget);
      await _pump(t, 3000);
      await _pickRight(t, M3GateLines.coworker.right);
      await _pump(t, 2500);
      await _tapKey(t, 'gel', ms: 300);
      await _tapKey(t, deal.gelPinkDealt ? 'judge-bad' : 'judge-ok', ms: 500);
      await _tapKey(t, 'oil', ms: 300);
      await _tapKey(t, deal.oilLeakDealt ? 'judge-bad' : 'judge-ok', ms: 500);
      await _tapKey(t, 'lt-switch');
      await _tapKey(t, 'tap');
      await _reason(t, M3GateLines.whyDtrQ, M3GateLines.whyDtrRight);

      // 5 — feeder pillar.
      expect(find.text('ফিডার পিলার'), findsOneWidget);
      await _tapKey(t, 'door');
      await _tapLabel(t, M3GateLines.gloves, ms: 200);
      await _tapLabel(t, M3GateLines.faceShield, ms: 200);
      await _tapKey(t, 'bus');
      await _tapKey(t, 'fuse-${deal.blownWay}-${deal.blownPh}');
      await _tapKey(t, 'hrc-same', ms: 1500);
      await _tapKey(t, 'bolt-${deal.hotBolt}');
      await _tapLabel(t, M3GateLines.lockDoor);
      await _reason(t, M3GateLines.whyPillarQ, M3GateLines.whyPillarRight);

      // 6 — service drop.
      expect(find.text('সার্ভিস ড্রপ'), findsOneWidget);
      await _tapLabel(t, deal.threePhase ? 'ফোর-কোর কেবিল' : 'টুইন-কোর কেবিল', ms: 1500);
      await _tapLabel(t, 'বিয়ারার তারে ঝুলিয়ে', ms: 1500);
      await _tapLabel(t, 'U ড্রিপ লুপ করে', ms: 1500);
      await _tapLabel(t, 'গ্লাভস পরে নিউট্রাল');
      await _reason(t, M3GateLines.whyServiceQ, M3GateLines.whyServiceRight);

      // 7 — guard.
      expect(find.text('ক্রেডল গার্ডিং'), findsOneWidget);
      await _tapLabel(t, M3GateLines.gloves, ms: 200);
      await _tapKey(t, 'guard-${deal.guardFault.name}', ms: 1500);
      await _tapLabel(t, M3GateLines.guardOn);
      await _reason(t, M3GateLines.whyGuardQ, M3GateLines.whyGuardRight);
      await _pump(t, 3000);

      final s = c.read(gameSaveProvider);
      expect(s.rungProgress[_rung], 'cleared');
      expect(s.rankIndex, 3);
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung[_rung], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(M3GateRankText.stamp), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('planning without the NO point: the scene freezes, then the deadly card', (t) async {
      final c = await _open(t, 5);
      await _tapKey(t, 'sym-ab');
      await t.tap(_label(M3GateLines.planOk));
      await _pump(t, 700);
      expect(find.byKey(const ValueKey('freeze')), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3000);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(M3GateMistakes.ringBackfeed.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.deadly, isTrue);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a wrong symbol is a slip with its card', (t) async {
      final c = await _open(t, 6);
      await _tapKey(t, 'sym-la', ms: 800);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(M3GateMistakes.wrongSymbol.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes, hasLength(1));
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
        debugPrint('PERF m3_gate_field ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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
