// Lesson 4.4 (ডিও ফিউজ পরিচালনা), কাজ 1 "ডিও খোলো নিয়মে": the rules (the
// rod from the rack; গ্লাভস + shield before the rod goes up; dry ground to the
// side; hook, face aside, one quick pull; all three open; heavy load = the
// load-break tool), the deal, the option libraries, and the level in the
// shell: idle perf, the guide first, a full clean play with the coworker
// refused, slip cards, the deadly freeze (heavy load pulled without the tool).
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
import 'package:slm_flutter/features/game/m4_do_open.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';

const _ctx = LevelContext(rungId: '4.4/do/0', kind: CatalogRungKind.doKind, lessonId: '4.4', lessonTitleBn: '', ladderStep: 0, doIndex: 1, doCount: 2);

final _pack = m4DoOpenPacks['do_4_4_a']!;

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

Future<void> _reason(WidgetTester t, List<String> right) async {
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 700);
  await _pickRight(t, right);
  await _pump(t, 6000);
}

/// Design px → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
M4DoOpenGeo get _geo => M4DoOpenGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
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
        builder: (_) => M4DoOpenPage(ctx: _ctx, pack: _pack, muted: true, seed: seed),
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

Future<void> _takeRod(WidgetTester t, M4DoOpenDeal deal, {M4DoOpenRod rod = M4DoOpenRod.good}) async {
  expect(await _pumpUntil(t, find.byKey(const ValueKey('rack-rod-0')), maxMs: 3000), isTrue, reason: 'the rack');
  await t.tap(find.byKey(ValueKey('rack-rod-${deal.rods.indexOf(rod)}')));
  await _pump(t, 600);
}

Future<void> _prep(WidgetTester t, M4DoOpenJob j, {bool kit = true, M4DoOpenHead? head}) async {
  expect(await _pumpUntil(t, find.text(M4DoOpenLines.raise), maxMs: 4000), isTrue, reason: 'get ready');
  for (final l in [
    if (kit) M4DoOpenLines.gloves,
    if (kit) M4DoOpenLines.shield,
    (head ?? (j.kind == M4DoOpenKind.heavy ? M4DoOpenHead.loadBreak : M4DoOpenHead.puller)) == M4DoOpenHead.loadBreak
        ? M4DoOpenLines.loadBreak
        : M4DoOpenLines.puller,
  ]) {
    await t.tap(_label(l));
    await _pump(t, 150);
  }
  await t.tap(find.text(M4DoOpenLines.raise));
  await _pump(t, 500);
}

Future<void> _standDry(WidgetTester t, M4DoOpenJob j) async {
  await t.tapAt(_screen(Offset(j.puddleLeft ? 80 : 130, _geo.groundY + 20)));
  await _pump(t, 900);
}

Future<void> _pullOpen(WidgetTester t, int phase, {bool face = true}) async {
  await t.tapAt(_screen(_geo.ringOf(phase)));
  await _pump(t, 400);
  if (face) {
    await t.tap(_label(M4DoOpenLines.faceAside));
    await _pump(t, 200);
  }
  await t.dragFrom(_screen(const Offset(200, 380)), const Offset(0, 140));
  await _pump(t, 800);
}

/// Plays job [i] right (refusing him on his job).
Future<void> _playRight(WidgetTester t, M4DoOpenDeal deal, int i) async {
  final j = deal.jobs[i];
  await _prep(t, j, kit: i == 0);
  await _standDry(t, j);
  if (i == deal.callAt) await _refuse(t, j.kind == M4DoOpenKind.heavy ? M4DoOpenLines.coworkerHeavy : M4DoOpenLines.coworkerFault);
  for (var p = 0; p < 3; p++) {
    if (p == j.blown) continue;
    await _pullOpen(t, p);
    expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'job $i, phase $p');
  }
  await t.tap(find.text(M4DoOpenLines.allOpen));
  await _pump(t, 400);
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'job $i');
  await _reason(t, M4DoOpenLines.whyRight(j.kind));
}

void main() {
  group('rules', () {
    test('deals two jobs: a fault and a heavy load; rods and his job dealt; fresh each play', () {
      final seen = <String>{};
      final calls = <M4DoOpenKind>{};
      for (var s = 0; s < 60; s++) {
        final d = m4DoOpenDeal(math.Random(s));
        expect(d.jobs.map((j) => j.kind).toSet(), M4DoOpenKind.values.toSet());
        for (final j in d.jobs) {
          expect(j.blown, j.kind == M4DoOpenKind.fault ? inInclusiveRange(0, 2) : -1);
        }
        expect(d.rods.toSet(), M4DoOpenRod.values.toSet());
        calls.add(d.jobs[d.callAt].kind);
        seen.add('${d.jobs.map((j) => '${j.kind.name}${j.blown}${j.puddleLeft}').join('|')}${d.rods}${d.callAt}');
      }
      expect(seen.length, greaterThan(40));
      expect(calls, M4DoOpenKind.values.toSet(), reason: 'he comes on either job');
    });

    M4DoOpenRun run1(M4DoOpenKind k, {int blown = -1, bool puddleLeft = true}) => M4DoOpenRun(
      M4DoOpenDeal(
        jobs: [M4DoOpenJob(kind: k, blown: blown, puddleLeft: puddleLeft)],
        rods: const [M4DoOpenRod.cracked, M4DoOpenRod.good, M4DoOpenRod.short],
        callAt: 0,
      ),
    )..stage = M4DoOpenStage.prep;

    test('the rod: the whole one is right; cracked and short are slips', () {
      for (final (i, m) in [(0, M4DoOpenMistakes.crackedRod), (1, null), (2, M4DoOpenMistakes.shortRod)]) {
        final r = run1(M4DoOpenKind.fault, blown: 0)..stage = M4DoOpenStage.rod;
        expect(r.pickRod(i), m);
        expect(r.stage, M4DoOpenStage.prep);
        expect(r.slips, m == null ? 0 : 1);
      }
    });

    test('the rod goes up with a head; no গ্লাভস / no shield are slips, put right', () {
      final a = run1(M4DoOpenKind.fault, blown: 1)..wear(M4DoOpenKit.shield);
      expect(a.raise(), (false, null), reason: 'no head: not scored');
      expect(a.stage, M4DoOpenStage.prep);
      a.fit(M4DoOpenHead.puller);
      expect(a.raise(), (true, M4DoOpenMistakes.noGloves));
      expect(a.kit, M4DoOpenKit.values.toSet());
      expect(a.stage, M4DoOpenStage.stand);
      final b = run1(M4DoOpenKind.fault, blown: 1)
        ..wear(M4DoOpenKit.gloves)
        ..fit(M4DoOpenHead.puller);
      expect(b.raise().$2, M4DoOpenMistakes.noShield);
      final c = run1(M4DoOpenKind.heavy)
        ..wear(M4DoOpenKit.gloves)
        ..wear(M4DoOpenKit.shield)
        ..fit(M4DoOpenHead.loadBreak);
      expect(c.raise(), (true, null));
      expect(c.caught, contains(M4DoOpenLines.caughtKit));
    });

    test('where to stand: under the set or in the puddle are slips; too far is not scored', () {
      expect(m4DoOpenSpotOf(230, puddleLeft: true), M4DoOpenSpot.under);
      expect(m4DoOpenSpotOf(180, puddleLeft: false), M4DoOpenSpot.under);
      expect(m4DoOpenSpotOf(130, puddleLeft: true), M4DoOpenSpot.wet);
      expect(m4DoOpenSpotOf(130, puddleLeft: false), M4DoOpenSpot.side);
      expect(m4DoOpenSpotOf(320, puddleLeft: false), M4DoOpenSpot.wet);
      expect(m4DoOpenSpotOf(80, puddleLeft: true), M4DoOpenSpot.side);
      expect(m4DoOpenSpotOf(40, puddleLeft: true), M4DoOpenSpot.far);
      for (final left in [true, false]) {
        expect(m4DoOpenSpotOf(m4DoOpenDryX(puddleLeft: left), puddleLeft: left), M4DoOpenSpot.side);
      }
      M4DoOpenRun up() => run1(M4DoOpenKind.fault, blown: 0)
        ..wear(M4DoOpenKit.gloves)
        ..wear(M4DoOpenKit.shield)
        ..fit(M4DoOpenHead.puller)
        ..raise();
      final a = up();
      expect(a.stand(30).$2, isNull);
      expect(a.stage, M4DoOpenStage.stand, reason: 'too far: the step stays');
      expect(a.stand(230).$2, M4DoOpenMistakes.underFuse);
      expect(a.stage, M4DoOpenStage.open);
      expect(up().stand(130).$2, M4DoOpenMistakes.wetGround);
      final b = up();
      expect(b.stand(80).$2, isNull);
      expect(b.caught, contains(M4DoOpenLines.caughtStand));
    });

    M4DoOpenRun atFuses(M4DoOpenKind k, {int blown = -1, M4DoOpenHead head = M4DoOpenHead.puller}) {
      final r = run1(k, blown: blown)
        ..wear(M4DoOpenKit.gloves)
        ..wear(M4DoOpenKit.shield)
        ..fit(head)
        ..raise()
        ..stand(80);
      expect(r.stage, M4DoOpenStage.open);
      return r;
    }

    test('the fault job: hook, face aside, one quick pull; the blown one is already open; all three to finish', () {
      final r = atFuses(M4DoOpenKind.fault, blown: 2);
      expect(r.open, [false, false, true]);
      expect(r.hook(2), isFalse, reason: 'already open');
      expect(r.pull(140, 200).$1, M4DoOpenPull.short, reason: 'not hooked');
      expect(r.hook(0), isTrue);
      expect(r.pull(30, 100).$1, M4DoOpenPull.short);
      expect(r.pull(140, 2000).$1, M4DoOpenPull.slow);
      expect(r.slips, 0);
      expect(r.pull(140, 300), (M4DoOpenPull.done, M4DoOpenMistakes.faceIn));
      expect(r.open, [true, false, true]);
      expect(r.confirm(), (false, M4DoOpenMistakes.notAllThree));
      expect(r.confirm(), (false, null), reason: 'booked once a job');
      r
        ..hook(1)
        ..turnFace();
      expect(r.pull(140, 300), (M4DoOpenPull.done, null));
      expect(r.confirm(), (true, null));
      expect(r.stage, M4DoOpenStage.done);
      expect(r.caught, containsAll([M4DoOpenLines.caughtPull, M4DoOpenLines.caughtAll]));
      expect(r.slips, 2);
    });

    test('the heavy job: without the load-break tool the pull is deadly; with it, clean', () {
      final a = atFuses(M4DoOpenKind.heavy)
        ..hook(1)
        ..turnFace();
      expect(a.pull(140, 300).$2, M4DoOpenMistakes.heavyNoTool);
      expect(a.deadly!.deadly, isTrue);
      expect(a.ended, isTrue);
      final b = atFuses(M4DoOpenKind.heavy, head: M4DoOpenHead.loadBreak);
      for (var p = 0; p < 3; p++) {
        b
          ..hook(p)
          ..turnFace();
        expect(b.pull(140, 300), (M4DoOpenPull.done, null));
      }
      expect(b.confirm(), (true, null));
      expect(b.caught, contains(M4DoOpenLines.caughtLbt));
      expect(b.clean, isTrue);
      // His say-so: the tool comes off and cannot go back on; the pull is deadly.
      final c = atFuses(M4DoOpenKind.heavy, head: M4DoOpenHead.loadBreak)..listenHeavy();
      expect(c.head, M4DoOpenHead.puller);
      c
        ..hook(0)
        ..turnFace();
      expect(c.pull(140, 300).$2, M4DoOpenMistakes.heavyNoTool);
    });

    test('listening on the fault job is the all-three slip (once a job); next() resets the job, keeps the kit', () {
      final r = atFuses(M4DoOpenKind.fault, blown: 0);
      expect(r.listenAll(), M4DoOpenMistakes.notAllThree);
      expect(r.listenAll(), isNull);
      r.slips = 3;
      expect(r.percent, 55);
      final d = m4DoOpenDeal(math.Random(4));
      final n = M4DoOpenRun(d)
        ..stage = M4DoOpenStage.prep
        ..wear(M4DoOpenKit.gloves)
        ..fit(M4DoOpenHead.puller)
        ..toolOff = true;
      n.next();
      expect(n.kit, {M4DoOpenKit.gloves});
      expect(n.head, M4DoOpenHead.none);
      expect(n.toolOff, isFalse);
      expect(n.stage, M4DoOpenStage.prep);
      expect(n.open, [for (var i = 0; i < 3; i++) i == d.jobs[1].blown]);
    });

    test('English digits only; every mistake has its picture and a stable key; one deadly', () {
      final all = <String>[
        ...M4DoOpenLines.guideLines,
        ...M4DoOpenLines.rodWhy,
        ...M4DoOpenLines.faultWhy,
        ...M4DoOpenLines.heavyWhy,
        ...M4DoOpenLines.whyWrong,
        for (final s in [M4DoOpenLines.coworkerHeavy, M4DoOpenLines.coworkerFault]) ...[...s.recordedLines, ...s.right, ...s.wrong],
        for (final m in M4DoOpenMistakes.all) m.textBn,
        for (final j in m4DoOpenDeal(math.Random(1)).jobs) M4DoOpenLines.jobBn(j),
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
      expect(M4DoOpenMistakes.all.where((m) => m.deadly).toSet(), {M4DoOpenMistakes.heavyNoTool});
      for (final m in M4DoOpenMistakes.all) {
        expect(m.key, startsWith('4.4/m4_do_open/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 2));
      }
      expect(M4DoOpenMistakes.all.map((m) => m.key).toSet().length, M4DoOpenMistakes.all.length);
      expect(m4DoOpenPacks.keys, ['do_4_4_a']);
      expect(_pack.quickMs, 70000);
      expect(M4DoOpenLines.intro.length, lessThan(60), reason: 'the intro stays short');
    });

    test('reasons fit, same length, big enough; his choices too', () {
      expectSameLength('why', [...M4DoOpenLines.rodWhy, ...M4DoOpenLines.faultWhy, ...M4DoOpenLines.heavyWhy, ...M4DoOpenLines.whyWrong]);
      for (final right in [M4DoOpenLines.rodWhy, M4DoOpenLines.faultWhy, M4DoOpenLines.heavyWhy]) {
        expectLibrary(right.first, right, M4DoOpenLines.whyWrong);
        for (var s = 0; s < 10; s++) {
          final deal = dealChoices(right, M4DoOpenLines.whyWrong, math.Random(s));
          expect(deal.where((o) => o.correct).length, 1);
          expect(deal.map((o) => o.textBn).toSet().length, 3);
        }
      }
      for (final s in [M4DoOpenLines.coworkerHeavy, M4DoOpenLines.coworkerFault]) {
        expectSameLength('choice', [...s.right, ...s.wrong]);
        expectLibrary('choice', s.right, s.wrong);
      }
      expect(M4DoOpenLines.recordLines, hasLength(2));
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

    int seedWhere(bool Function(M4DoOpenDeal d) ok) {
      var s = 0;
      while (!ok(m4DoOpenDeal(math.Random(s)))) {
        s++;
      }
      return s;
    }

    for (final reduce in [false, true]) {
      testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
        t.view.physicalSize = const Size(720, 1600);
        t.view.devicePixelRatio = 2.0;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        await t.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: M4DoOpenPage(ctx: _ctx, pack: _pack, muted: true, seed: 1),
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
        debugPrint('PERF m4_do_open ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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

    testWidgets('the guide comes first: a tap does not skip him; then the rack', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: M4DoOpenPage(ctx: _ctx, pack: _pack, muted: true, seed: 2),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.byKey(const ValueKey('rack-rod-0')), findsNothing);
      await waitIntro(t);
      await _pump(t, 600);
      expect(find.byKey(const ValueKey('rack-rod-0')), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final c = await _open(t, 3);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(M4DoOpenLines.askRod)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    for (final heavy in [true, false]) {
      testWidgets('flow: the rod, two jobs right, him refused (${heavy ? 'heavy' : 'fault'}) → pass', (t) async {
        final seed = seedWhere((d) => (d.jobs[d.callAt].kind == M4DoOpenKind.heavy) == heavy);
        final deal = m4DoOpenDeal(math.Random(seed));
        final c = await _open(t, seed);
        await _takeRod(t, deal);
        await _reason(t, M4DoOpenLines.rodWhy);
        for (var i = 0; i < 2; i++) {
          await _playRight(t, deal, i);
        }
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['4.4/do/0'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['4.4/do/0'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(M4DoOpenLines.caughtCall), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('the cracked rod: the slip card, then the right rod and its reason', (t) async {
      final seed = seedWhere((d) => d.callAt == 1);
      final deal = m4DoOpenDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _takeRod(t, deal, rod: M4DoOpenRod.cracked);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M4DoOpenMistakes.crackedRod.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      await _reason(t, M4DoOpenLines.rodWhy);
      expect(find.text(M4DoOpenLines.raise), findsOneWidget, reason: 'on to get ready');
      await _close(t, c);
    });

    testWidgets('standing in the puddle: the slip card, then he steps to dry ground', (t) async {
      final seed = seedWhere((d) => d.callAt == 1);
      final deal = m4DoOpenDeal(math.Random(seed));
      final j = deal.jobs[0];
      final c = await _open(t, seed);
      await _takeRod(t, deal);
      await _reason(t, M4DoOpenLines.rodWhy);
      await _prep(t, j);
      await t.tapAt(_screen(Offset(j.puddleLeft ? 134 : 320, _geo.groundY + 20)));
      await _pump(t, 900);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M4DoOpenMistakes.wetGround.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      expect(find.text(M4DoOpenLines.allOpen), findsOneWidget, reason: 'on to the fuses');
      await _close(t, c);
    });

    testWidgets('"সব ফিউজ খোলা" with a fuse still in: the all-three slip', (t) async {
      final seed = seedWhere((d) => d.jobs[0].kind == M4DoOpenKind.fault && d.callAt == 1);
      final deal = m4DoOpenDeal(math.Random(seed));
      final j = deal.jobs[0];
      final c = await _open(t, seed);
      await _takeRod(t, deal);
      await _reason(t, M4DoOpenLines.rodWhy);
      await _prep(t, j);
      await _standDry(t, j);
      await _pullOpen(t, (j.blown + 1) % 3);
      await t.tap(find.text(M4DoOpenLines.allOpen));
      await _pump(t, 600);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M4DoOpenMistakes.notAllThree.key);
      await _close(t, c);
    });

    testWidgets('heavy load pulled with the plain puller: the yard freezes first, then the card (near-miss)', (t) async {
      final seed = seedWhere((d) => d.jobs[0].kind == M4DoOpenKind.heavy && d.callAt == 1);
      final deal = m4DoOpenDeal(math.Random(seed));
      final j = deal.jobs[0];
      final c = await _open(t, seed);
      await _takeRod(t, deal);
      await _reason(t, M4DoOpenLines.rodWhy);
      await _prep(t, j, head: M4DoOpenHead.puller);
      await _standDry(t, j);
      await _pullOpen(t, 0);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, M4DoOpenMistakes.heavyNoTool.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('listening to him on the heavy job: the tool comes off, the pull is deadly', (t) async {
      final seed = seedWhere((d) => d.jobs[0].kind == M4DoOpenKind.heavy && d.callAt == 0);
      final deal = m4DoOpenDeal(math.Random(seed));
      final j = deal.jobs[0];
      final c = await _open(t, seed);
      await _takeRod(t, deal);
      await _reason(t, M4DoOpenLines.rodWhy);
      await _prep(t, j);
      await _standDry(t, j);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      final wrong = _onScreen(M4DoOpenLines.coworkerHeavy.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await _pump(t, 1500);
      await _pullOpen(t, 1);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.last.key, M4DoOpenMistakes.heavyNoTool.key);
      await _close(t, c);
    });
  });
}
