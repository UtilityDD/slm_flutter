// Lesson 4.7 (ডিপি স্ট্রাকচার ড্রেসিং), কাজ 1 "এলোমেলো স্ট্রাকচার": the rules
// (mark only what is untidy; the list with nothing missed; HT before LT; the
// coworker's myths; the dressing only after shutdown, PTW, test and earth),
// the deal, the option libraries, the tap zones, and the level in the shell:
// idle perf, the guide first, a full clean play with the coworker refused,
// the slip cards (a tidy part marked; a fault missed), the deadly plan.
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/choice_deck.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/coworker_moment.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m4_dp_survey.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';

const _ctx = LevelContext(rungId: '4.7/do/0', kind: CatalogRungKind.doKind, lessonId: '4.7', lessonTitleBn: '', ladderStep: 0, doIndex: 1, doCount: 2);

final _pack = m4DpSurveyPacks['do_4_7_a']!;

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Future<bool> _pumpUntil(WidgetTester t, Finder f, {int maxMs = 8000}) async {
  for (var ms = 0; ms < maxMs; ms += 100) {
    if (f.evaluate().isNotEmpty) return true;
    await t.pump(const Duration(milliseconds: 100));
  }
  return f.evaluate().isNotEmpty;
}

Finder _label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);
List<Finder> _onScreen(List<String> texts) => [
  for (final x in texts)
    if (_label(x).evaluate().isNotEmpty) _label(x),
];

Future<void> _pickRight(WidgetTester t, List<String> right) async {
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = _onScreen(right);
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
}

/// Design px → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
M4DpSurveyGeo get _geo => M4DpSurveyGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
Offset _screen(Offset design) => design * _k;

Future<ProviderContainer> _open(WidgetTester t, int seed) async {
  t.view.physicalSize = const Size(784, 1700);
  t.view.devicePixelRatio = 2.0;
  final c = ProviderContainer();
  final nav = GlobalKey<NavigatorState>();
  await t.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        navigatorKey: nav,
        home: const Scaffold(body: SizedBox()),
      ),
    ),
  );
  unawaited(
    nav.currentState!.push(
      MaterialPageRoute<bool>(
        builder: (_) => M4DpSurveyPage(ctx: _ctx, pack: _pack, muted: true, seed: seed),
      ),
    ),
  );
  await _pump(t, 1000);
  await waitIntro(t);
  await _pump(t, 600);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

Future<void> _refuse(WidgetTester t, CoworkerScript s) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, s.right);
  await _pump(t, 2000);
}

Future<void> _tapPart(WidgetTester t, M4DpSurveyFault f) async {
  await t.tapAt(_screen(_geo.zoneOf(f).center));
  await _pump(t, 300);
}

/// Plays DP [i] right (refusing him on his DP).
Future<void> _playDp(WidgetTester t, M4DpSurveyDeal deal, int i) async {
  final s = deal.structures[i];
  final faults = [
    for (final f in M4DpSurveyFault.values)
      if (s.faults.contains(f)) f,
  ];
  for (final (k, f) in faults.indexed) {
    await _tapPart(t, f);
    if (k == 0 && i == deal.callAt) {
      await _refuse(t, deal.insulated ? M4DpSurveyLines.coworkerInsulated : M4DpSurveyLines.coworkerAsIs);
    }
  }
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'DP $i marks');
  await t.tap(find.text(s.tidy ? M4DpSurveyLines.allTidy : M4DpSurveyLines.submit));
  await _pump(t, 600);
  if (s.needsOrder) {
    for (final f in faults) {
      await t.tap(find.byKey(ValueKey('order-${f.name}')));
      await _pump(t, 250);
    }
  }
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'DP $i');
  expect(await _pumpUntil(t, find.byKey(const ValueKey('why-deck'))), isTrue, reason: 'reason, DP $i');
  await _pump(t, 700);
  await _pickRight(t, M4DpSurveyLines.whyRight(s.topic));
  await _pump(t, 6000);
}

M4DpSurveyRun _run1(Set<M4DpSurveyFault> faults, {bool insulated = false}) => M4DpSurveyRun(
  M4DpSurveyDeal(
    structures: [
      M4DpSurveyStructure(
        look: M4DpSurveyLook(faults: faults),
        topic: M4DpSurveyTopic.tidy,
      ),
    ],
    callAt: 0,
    insulated: insulated,
  ),
);

void main() {
  group('rules', () {
    test('deals three DPs: 0–3 faults, at most one tidy, him on a DP with faults; fresh each play', () {
      final seen = <String>{};
      final kinds = <M4DpSurveyFault>{};
      var tidyPlays = 0;
      var insulated = 0;
      for (var s = 0; s < 80; s++) {
        final d = dealM4DpSurvey(math.Random(s));
        expect(d.structures.length, 3);
        final tidy = d.structures.where((x) => x.tidy).length;
        expect(tidy, lessThanOrEqualTo(1));
        if (tidy == 1) tidyPlays++;
        expect(d.structures[d.callAt].tidy, isFalse);
        if (d.insulated) {
          insulated++;
          final f = d.structures[d.callAt].faults;
          expect(f.contains(M4DpSurveyFault.touch) || f.contains(M4DpSurveyFault.clearance), isTrue);
        }
        for (final x in d.structures) {
          expect(x.faults.length, inInclusiveRange(0, 3));
          kinds.addAll(x.faults);
          if (x.tidy) {
            expect(x.topic, M4DpSurveyTopic.tidy);
          } else if (x.topic == M4DpSurveyTopic.order) {
            expect(x.needsOrder, isTrue);
          } else {
            expect(x.faults.map(m4DpSurveyTopicOf), contains(x.topic));
          }
        }
        expect(d.structures.map((x) => x.look.plate).toSet().length, 3);
        seen.add(d.structures.map((x) => '${x.faults.map((f) => f.name).toList()..sort()}${x.topic.name}').join('|') + d.callAt.toString());
      }
      expect(seen.length, greaterThan(60));
      expect(kinds, M4DpSurveyFault.values.toSet());
      expect(tidyPlays, inInclusiveRange(20, 60));
      expect(insulated, greaterThan(0));
    });

    test('mark: an untidy part goes on the list; a tidy part marked is a slip; twice is nothing', () {
      final r = _run1({M4DpSurveyFault.jumper, M4DpSurveyFault.ltCables});
      expect(r.mark(M4DpSurveyFault.jumper), (true, null));
      expect(r.mark(M4DpSurveyFault.jumper), (false, null));
      expect(r.mark(M4DpSurveyFault.tilt), (false, M4DpSurveyMistakes.falseMark));
      expect(r.slips, 1);
      expect(r.marked, [M4DpSurveyFault.jumper]);
    });

    test('the list: a fault left off = one slip (the top one), all rung; HT+LT → the order step', () {
      final r = _run1({M4DpSurveyFault.tail, M4DpSurveyFault.tilt, M4DpSurveyFault.touch});
      r.mark(M4DpSurveyFault.touch);
      expect(r.submit(), M4DpSurveyMistakes.missedTail);
      expect(r.slips, 1);
      expect(r.missed, {M4DpSurveyFault.tail, M4DpSurveyFault.tilt});
      expect(r.marked.toSet(), r.structure.faults);
      expect(r.phase, M4DpSurveyPhase.order);
      final ok = _run1({M4DpSurveyFault.jumper, M4DpSurveyFault.clearance});
      ok
        ..mark(M4DpSurveyFault.clearance)
        ..mark(M4DpSurveyFault.jumper);
      expect(ok.submit(), isNull);
      expect(ok.phase, M4DpSurveyPhase.why, reason: 'all HT: no order step');
      expect(ok.caught, containsAll([M4DpSurveyLines.nameOf(M4DpSurveyFault.jumper), M4DpSurveyLines.nameOf(M4DpSurveyFault.clearance)]));
      final tidy = _run1({});
      expect(tidy.submit(), isNull);
      expect(tidy.caught, [M4DpSurveyLines.caughtTidy]);
      final miss = _run1({M4DpSurveyFault.ltCables});
      expect(miss.submit(), M4DpSurveyMistakes.missedLtCables, reason: '"সব পরিপাটি" on an untidy DP');
    });

    test('the order: HT before LT; LT first is a slip and the guide puts it right', () {
      final r = _run1({M4DpSurveyFault.tail, M4DpSurveyFault.ltCables, M4DpSurveyFault.touch});
      for (final f in r.structure.faults) {
        r.mark(f);
      }
      r.submit();
      expect(r.pick(M4DpSurveyFault.touch), M4DpSurveyMistakes.bottomUp);
      expect(r.order, [M4DpSurveyFault.tail, M4DpSurveyFault.ltCables, M4DpSurveyFault.touch]);
      expect(r.phase, M4DpSurveyPhase.why);
      final ok = _run1({M4DpSurveyFault.tilt, M4DpSurveyFault.ltCables, M4DpSurveyFault.touch});
      for (final f in ok.structure.faults) {
        ok.mark(f);
      }
      ok.submit();
      expect(ok.pick(M4DpSurveyFault.tilt), isNull);
      expect(ok.pick(M4DpSurveyFault.touch), isNull);
      expect(ok.pick(M4DpSurveyFault.ltCables), isNull);
      expect(ok.phase, M4DpSurveyPhase.why);
      expect(ok.caught, contains(M4DpSurveyLines.caughtOrder));
      expect(ok.clean, isTrue);
    });

    test('his myths are slips; the plan: dressing live is deadly, the safe way ends the play', () {
      expect(_run1({M4DpSurveyFault.touch}).listen(), M4DpSurveyMistakes.asIsMyth);
      expect(_run1({M4DpSurveyFault.touch}, insulated: true).listen(), M4DpSurveyMistakes.insulatedMyth);
      M4DpSurveyRun toPlan() {
        final r = _run1({M4DpSurveyFault.jumper})
          ..mark(M4DpSurveyFault.jumper)
          ..submit()
          ..next();
        expect(r.phase, M4DpSurveyPhase.plan);
        return r;
      }

      final bad = toPlan();
      expect(bad.plan(safe: false), M4DpSurveyMistakes.liveDressing);
      expect(bad.deadly!.deadly, isTrue);
      expect(bad.passed, isFalse);
      final good = toPlan();
      expect(good.plan(safe: true), isNull);
      expect(good.passed, isTrue);
      expect(good.caught, contains(M4DpSurveyLines.caughtPlan));
    });

    test('mark: 100 − 15 per slip; the next DP clears the list', () {
      final r = M4DpSurveyRun(dealM4DpSurvey(math.Random(3)));
      r.slips = 3;
      expect(r.percent, 55);
      for (final f in r.structure.faults) {
        r.mark(f);
      }
      r.submit();
      r.phase = M4DpSurveyPhase.why;
      r.next();
      expect(r.index, 1);
      expect(r.marked, isEmpty);
      expect(r.phase, M4DpSurveyPhase.survey);
    });

    test('tap zones: none overlap, big enough, each centre finds its part (short to tall screens)', () {
      for (final h in [560.0, 700.0, 780.0, 900.0]) {
        final g = M4DpSurveyGeo.forScene(h, 0);
        for (final a in M4DpSurveyFault.values) {
          final r = g.zoneOf(a);
          expect(r.height, greaterThanOrEqualTo(h < 600 ? 20 : 34), reason: '$a @ $h');
          expect(r.width, greaterThanOrEqualTo(100), reason: '$a');
          expect(g.zoneAt(r.center), a, reason: '$a @ $h');
          for (final b in M4DpSurveyFault.values) {
            if (a != b) expect(r.overlaps(g.zoneOf(b)), isFalse, reason: '$a / $b @ $h');
          }
        }
        expect(g.zoneOf(M4DpSurveyFault.tail).top, greaterThan(90), reason: 'below the header');
        expect(g.zoneOf(M4DpSurveyFault.ltCables).bottom, lessThan(g.groundY));
      }
    });

    test('English digits only; every mistake has its picture, a stable key; one deadly', () {
      final all = <String>[
        M4DpSurveyLines.intro,
        ...M4DpSurveyLines.tasks,
        for (final tp in M4DpSurveyTopic.values) ...[M4DpSurveyLines.why(tp), ...M4DpSurveyLines.whyRight(tp)],
        ...M4DpSurveyLines.whyWrong,
        ...M4DpSurveyLines.planRight,
        ...M4DpSurveyLines.planWrong,
        for (final s in [M4DpSurveyLines.coworkerAsIs, M4DpSurveyLines.coworkerInsulated]) ...[...s.recordedLines, ...s.right, ...s.wrong, ...s.asks],
        for (final m in M4DpSurveyMistakes.all) m.textBn,
        for (final f in M4DpSurveyFault.values) M4DpSurveyLines.nameOf(f),
        M4DpSurveyLines.allSet,
        M4DpSurveyLines.fail,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
      expect(M4DpSurveyMistakes.all.where((m) => m.deadly).toSet(), {M4DpSurveyMistakes.liveDressing});
      for (final f in M4DpSurveyFault.values) {
        expect(M4DpSurveyMistakes.all, contains(M4DpSurveyMistakes.missed(f)));
      }
      for (final m in M4DpSurveyMistakes.all) {
        expect(m.key, startsWith('4.7/m4_dp_survey/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 2));
      }
      expect(M4DpSurveyMistakes.all.map((m) => m.key).toSet().length, M4DpSurveyMistakes.all.length);
      expect(m4DpSurveyPacks.keys, ['do_4_7_a']);
      expect(_pack.quickMs, kM4DpSurveyQuickMs);
    });

    test('reasons, plan and his choices: same length, big enough, one right per deal', () {
      expectSameLength('why', [for (final tp in M4DpSurveyTopic.values) ...M4DpSurveyLines.whyRight(tp), ...M4DpSurveyLines.whyWrong]);
      for (final tp in M4DpSurveyTopic.values) {
        final right = M4DpSurveyLines.whyRight(tp);
        final wrong = M4DpSurveyLines.whyWrongFor(tp);
        expectLibrary('$tp', right, wrong);
        for (var s = 0; s < 10; s++) {
          final deal = dealChoices(right, wrong, math.Random(s));
          expect(deal.where((o) => o.correct).length, 1);
          expect(deal.map((o) => o.textBn).toSet().length, 3);
        }
      }
      expect(M4DpSurveyLines.whyWrongFor(M4DpSurveyTopic.tidy), isNot(contains(M4DpSurveyLines.whyWrong[1])));
      expectSameLength('plan', [...M4DpSurveyLines.planRight, ...M4DpSurveyLines.planWrong]);
      expectLibrary('plan', M4DpSurveyLines.planRight, M4DpSurveyLines.planWrong);
      for (final s in [M4DpSurveyLines.coworkerAsIs, M4DpSurveyLines.coworkerInsulated]) {
        expectSameLength('choice', [...s.right, ...s.wrong]);
        expectLibrary('choice', s.right, s.wrong);
      }
      expect(M4DpSurveyLines.recordLines, hasLength(2));
    });
  });

  group('page', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final c in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global', 'flutter_tts']) {
      m.setMockMethodCallHandler(MethodChannel(c), (_) async => 1);
    }
    ZlFx.setMuted(true);
    var rebuilds = 0;
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SpokenOnce.resetForTest();
      debugOnRebuildDirtyWidget = (_, _) => rebuilds++;
    });
    tearDown(() => debugOnRebuildDirtyWidget = null);

    int seedWhere(bool Function(M4DpSurveyDeal d) ok) {
      var s = 0;
      while (!ok(dealM4DpSurvey(math.Random(s)))) {
        s++;
      }
      return s;
    }

    for (final reduce in [false, true]) {
      testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
        t.view.physicalSize = const Size(720, 1600);
        t.view.devicePixelRatio = 2.0;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        final seed = seedWhere((d) => d.callAt != 0);
        await t.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: M4DpSurveyPage(ctx: _ctx, pack: _pack, muted: true, seed: seed),
            ),
          ),
        );
        await t.pump(const Duration(milliseconds: 100));
        expect(find.text('শুরু'), findsNothing);
        await waitIntro(t);
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
        debugPrint('PERF m4_dp_survey ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
        expect(t.takeException(), isNull);
        expect(find.textContaining('ধাপ '), findsOneWidget);
        expect(perSec, lessThan(20));
        expect(frames, lessThan(12));
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 15));
        MascotTalk.reset();
        t.platformDispatcher.clearAccessibilityFeaturesTestValue();
        t.view.reset();
      });
    }

    testWidgets('the guide comes first: a tap does not skip him; then the list and the button', (t) async {
      final seed = seedWhere((d) => d.callAt != 0);
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: M4DpSurveyPage(ctx: _ctx, pack: _pack, muted: true, seed: seed),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text(M4DpSurveyLines.allTidy), findsNothing);
      await waitIntro(t);
      await _pump(t, 600);
      expect(find.text(M4DpSurveyLines.allTidy), findsOneWidget);
      final s0 = dealM4DpSurvey(math.Random(seed)).structures[0];
      expect(find.textContaining(M4DpSurveyLines.plateBn(s0.look)), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final seed = seedWhere((d) => d.callAt != 0);
      final c = await _open(t, seed);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(M4DpSurveyLines.askSurvey)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    for (final ins in [false, true]) {
      testWidgets('flow: three DPs right, him refused (${ins ? 'insulated myth' : 'as-is myth'}), safe plan → pass', (t) async {
        final seed = seedWhere((d) => d.insulated == ins && d.structures.any((s) => s.needsOrder));
        final deal = dealM4DpSurvey(math.Random(seed));
        final c = await _open(t, seed);
        for (var i = 0; i < 3; i++) {
          await _playDp(t, deal, i);
        }
        expect(await _pumpUntil(t, find.byKey(const ValueKey('plan-deck'))), isTrue, reason: 'the plan');
        await _pump(t, 700);
        await _pickRight(t, M4DpSurveyLines.planRight);
        await _pump(t, 4000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['4.7/do/0'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['4.7/do/0'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(M4DpSurveyLines.caughtCall), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('a tidy part marked: the slip card, then the survey goes on', (t) async {
      final seed = seedWhere((d) => d.callAt != 0 && d.structures[0].faults.length < 3);
      final s0 = dealM4DpSurvey(math.Random(seed)).structures[0];
      final c = await _open(t, seed);
      final tidyPart = M4DpSurveyFault.values.firstWhere((f) => !s0.faults.contains(f));
      await _tapPart(t, tidyPart);
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M4DpSurveyMistakes.falseMark.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      expect(find.byType(MistakeCard), findsNothing);
      expect(find.text(M4DpSurveyLines.allTidy), findsOneWidget, reason: 'still surveying');
      await _close(t, c);
    });

    testWidgets('"সব পরিপাটি" on an untidy DP: the missed card, the guide rings it, then the reason', (t) async {
      final seed = seedWhere((d) => d.callAt != 0 && !d.structures[0].tidy && !d.structures[0].needsOrder);
      final s0 = dealM4DpSurvey(math.Random(seed)).structures[0];
      final first = M4DpSurveyFault.values.firstWhere(s0.faults.contains);
      final c = await _open(t, seed);
      await t.tap(find.text(M4DpSurveyLines.allTidy));
      await _pump(t, 800);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M4DpSurveyMistakes.missed(first).key);
      await t.tap(find.text(MistakeLines.gotIt));
      expect(await _pumpUntil(t, find.byKey(const ValueKey('why-deck'))), isTrue, reason: 'on to the reason');
      await _close(t, c);
    });

    testWidgets('listing LT work before HT: the order slip, then the reason', (t) async {
      final seed = seedWhere((d) => d.callAt != 0 && d.structures[0].needsOrder);
      final s0 = dealM4DpSurvey(math.Random(seed)).structures[0];
      final c = await _open(t, seed);
      for (final f in s0.faults) {
        await _tapPart(t, f);
      }
      await t.tap(find.text(M4DpSurveyLines.submit));
      await _pump(t, 600);
      final lt = s0.faults.firstWhere((f) => !f.isHt);
      await t.tap(find.byKey(ValueKey('order-${lt.name}')));
      await _pump(t, 800);
      expect(c.read(gameSaveProvider).mistakes.single.key, M4DpSurveyMistakes.bottomUp.key);
      await t.tap(find.text(MistakeLines.gotIt));
      expect(await _pumpUntil(t, find.byKey(const ValueKey('why-deck'))), isTrue);
      await _close(t, c);
    });

    testWidgets('dressing it live: the structure freezes first, then the card (near-miss)', (t) async {
      final seed = seedWhere((d) => true);
      final deal = dealM4DpSurvey(math.Random(seed));
      final c = await _open(t, seed);
      for (var i = 0; i < 3; i++) {
        await _playDp(t, deal, i);
      }
      expect(await _pumpUntil(t, find.byKey(const ValueKey('plan-deck'))), isTrue);
      await _pump(t, 700);
      final wrong = _onScreen(M4DpSurveyLines.planWrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await _pump(t, 900);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, M4DpSurveyMistakes.liveDressing.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });
  });
}
