// Lesson 4.5, কাজ 1 "তেলের মাপ" (m4_oil_level): the rules (read the conservator
// gauge with the weather in mind, find the leak, ঠিক / রিপোর্ট; low oil →
// the top-up: shutdown → test → earth → climb, the right drum, pour), the
// deal, the reason libraries, and the level in the shell: idle perf, the
// guide first, a full clean play (the coworker refused), a slip card, a wrong
// drum (the top-up goes on), and the deadly freeze (listening to him: up the
// live transformer).
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
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m4_oil_level.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';

const _ctx = LevelContext(
  rungId: '4.5/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '4.5',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

final _pack = m4OilLevelPacks['do_4_5_a']!;

/// The level's mistake art is in a new folder the director adds to pubspec;
/// until then the tests read it from disk.
class _DiskBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key.startsWith('assets/game/art/m4_oil_level/')) {
      final b = File(key).readAsBytesSync();
      return ByteData.view(b.buffer);
    }
    return rootBundle.load(key);
  }
}

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
M4OilLevelGeo get _geo => M4OilLevelGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);

Future<void> _readGauge(WidgetTester t) async {
  await t.tapAt(_geo.conservator.center * _k);
  await _pump(t, 500);
}

Future<void> _look(WidgetTester t, M4OilLevelSpot s) async {
  await t.tapAt(_geo.spot(s) * _k);
  await _pump(t, 300);
}

Future<void> _step(WidgetTester t, M4OilLevelStep s) async {
  await t.tap(find.byKey(ValueKey('step-${s.name}')));
  await _pump(t, 400);
}

Future<void> _drum(WidgetTester t, M4OilLevelDeal deal, M4OilLevelDrum d) async {
  await t.tapAt(_geo.drum(deal.drums.indexOf(d)).center * _k);
  await _pump(t, 400);
}

Future<void> _pourAll(WidgetTester t) async {
  final b = find.byKey(const ValueKey('hud-pour'));
  expect(b, findsOneWidget);
  final g = await t.startGesture(t.getCenter(b));
  await _pump(t, 3200);
  await g.up();
  await _pump(t, 300);
}

Future<ProviderContainer> _open(WidgetTester t, int seed) async {
  t.view.physicalSize = const Size(784, 1700);
  t.view.devicePixelRatio = 2.0;
  final c = ProviderContainer();
  final nav = GlobalKey<NavigatorState>();
  await t.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: DefaultAssetBundle(
      bundle: _DiskBundle(),
      child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
    ),
  ));
  unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
    builder: (_) => M4OilLevelPage(ctx: _ctx, pack: _pack, muted: true, seed: seed),
  )));
  await _pump(t, 1000);
  await waitIntro(t);
  await _pump(t, 1500);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

/// Into the top-up on the low transformer (the gauge read, the leak found,
/// the report).
Future<void> _toTopup(WidgetTester t, M4OilLevelCase c) async {
  await _readGauge(t);
  await _look(t, c.leak!);
  await t.tap(find.text(M4OilLevelLines.report));
  await _pump(t, 600);
}

/// Plays round [i] right: the gauge, every part of the tank, the verdict;
/// low oil: the coworker refused, shutdown → test → earth → climb, the right
/// drum, the pour. Then the reason.
Future<void> _playRight(WidgetTester t, M4OilLevelDeal deal, int i) async {
  final c = deal.cases[i];
  await _readGauge(t);
  expect(find.byKey(const ValueKey('gauge-card')), findsOneWidget);
  for (final s in M4OilLevelSpot.values) {
    await _look(t, s);
  }
  await t.tap(find.text(c.kind == M4OilLevelKind.fine ? M4OilLevelLines.ok : M4OilLevelLines.report));
  await _pump(t, 600);
  if (c.low) {
    expect(find.text(MistakeLines.slipHead), findsNothing);
    expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 4000), isTrue, reason: 'he comes on the top-up');
    await _pumpUntil(t, find.byType(ChoiceDeck));
    await _pump(t, 600);
    await _pickRight(t, M4OilLevelLines.coworker.right);
    await _pump(t, 1800);
    for (final s in M4OilLevelStep.values) {
      await _step(t, s);
      expect(find.text(MistakeLines.slipHead), findsNothing, reason: s.name);
    }
    expect(find.text(M4OilLevelLines.dead), findsOneWidget);
    await _drum(t, deal, M4OilLevelDrum.fresh);
    await _pourAll(t);
  }
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'round $i ${c.kind} ${c.weather}');
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'round $i');
  await _pump(t, 700);
  await _pickRight(t, M4OilLevelLines.whyRight(c));
  await _pump(t, 4000);
}

void main() {
  group('rules', () {
    test('deals: fine, leak and low once each, every weather once; levels fit the weather; two leak spots', () {
      final seen = <String>{};
      final calls = <int>{};
      for (var s = 0; s < 80; s++) {
        final d = dealM4OilLevel(math.Random(s));
        expect(d.cases.length, 3);
        expect(d.cases.map((c) => c.kind).toSet(), M4OilLevelKind.values.toSet());
        expect(d.cases.map((c) => c.weather).toSet(), M4OilLevelWeather.values.toSet());
        expect(d.cases.map((c) => c.dtrNo).toSet().length, 3);
        expect(d.drums.toSet(), M4OilLevelDrum.values.toSet());
        final leaks = [for (final c in d.cases) ?c.leak];
        expect(leaks.length, 2);
        expect(leaks.toSet().length, 2);
        for (final c in d.cases) {
          if (c.low) {
            expect(c.level, lessThan(kM4OilLevelMin));
            continue;
          }
          expect(c.level, inExclusiveRange(kM4OilLevelMin, kM4OilLevelMax));
          switch (c.weather) {
            case M4OilLevelWeather.winter:
              expect(c.level, lessThan(kM4OilLevelMark - 0.05), reason: 'cold: below the mark');
            case M4OilLevelWeather.summer:
              expect(c.level, greaterThan(kM4OilLevelMark + 0.05), reason: 'heat: above the mark');
            case M4OilLevelWeather.mild:
              expect((c.level - kM4OilLevelMark).abs(), lessThan(0.05));
          }
          if (c.kind == M4OilLevelKind.fine) expect(c.leak, isNull);
        }
        calls.add(d.callAt);
        seen.add(d.cases.map((c) => '${c.kind.name}${c.weather.name}${c.leak}').join('|') + d.drums.join());
      }
      expect(seen.length, greaterThan(50), reason: 'every play is dealt fresh');
      expect(calls, {0, 1, 2});
    });

    M4OilLevelRun run1(M4OilLevelCase c) => M4OilLevelRun(M4OilLevelDeal(cases: [c], drums: M4OilLevelDrum.values));
    M4OilLevelCase fine(M4OilLevelWeather w) => M4OilLevelCase(id: 'x', dtrNo: 7, kind: M4OilLevelKind.fine, weather: w, level: 0.5);
    const leak = M4OilLevelCase(id: 'x', dtrNo: 7, kind: M4OilLevelKind.leak, weather: M4OilLevelWeather.mild, level: 0.5, leak: M4OilLevelSpot.drain);
    const low = M4OilLevelCase(id: 'x', dtrNo: 7, kind: M4OilLevelKind.low, weather: M4OilLevelWeather.summer, level: 0.1, leak: M4OilLevelSpot.bushing);

    test('a verdict without the gauge is a slip; a fine one read and passed is right; reported = misread by weather', () {
      final a = run1(fine(M4OilLevelWeather.mild));
      expect(a.decide(report: false), M4OilLevelMistakes.noGauge);
      expect(a.shown, isTrue);
      final b = run1(fine(M4OilLevelWeather.winter))..readGauge();
      expect(b.decide(report: false), isNull);
      expect(b.caught, containsAll([M4OilLevelLines.caughtGauge, M4OilLevelLines.caughtTemp]));
      for (final w in M4OilLevelWeather.values) {
        final r = run1(fine(w))..readGauge();
        expect(r.decide(report: true), M4OilLevelMistakes.misread(w));
        expect(r.slips, 1);
      }
      expect(M4OilLevelMistakes.misread(M4OilLevelWeather.winter), M4OilLevelMistakes.misreadCold);
      expect(M4OilLevelMistakes.misread(M4OilLevelWeather.summer), M4OilLevelMistakes.misreadHot);
    });

    test('a leak with the level fine: passed or reported unfound = missed leak; found and reported = right', () {
      final a = run1(leak)..readGauge();
      expect(a.decide(report: false), M4OilLevelMistakes.missedLeak);
      final b = run1(leak)..readGauge();
      expect(b.look(M4OilLevelSpot.fin), isFalse);
      expect(b.decide(report: true), M4OilLevelMistakes.missedLeak);
      final c = run1(leak)..readGauge();
      for (final s in M4OilLevelSpot.values) {
        c.look(s);
      }
      expect(c.leakFound, isTrue);
      expect(c.thorough, isTrue);
      expect(c.decide(report: true), isNull);
      expect(c.caught, contains(M4OilLevelLines.caughtLeak));
    });

    test('low oil: passed = slip; reported → the top-up (an unfound leak is a slip, the top-up goes on)', () {
      final a = run1(low)..readGauge();
      expect(a.decide(report: false), M4OilLevelMistakes.missedLow);
      final b = run1(low)..readGauge();
      expect(b.decide(report: true), M4OilLevelMistakes.missedLeak);
      expect(b.phase, M4OilLevelPhase.topup);
      expect(b.shown, isFalse);
      final c = run1(low)
        ..readGauge()
        ..look(M4OilLevelSpot.bushing);
      expect(c.decide(report: true), isNull);
      expect(c.phase, M4OilLevelPhase.topup);
    });

    M4OilLevelRun topup() => run1(low)
      ..readGauge()
      ..look(M4OilLevelSpot.bushing)
      ..decide(report: true);

    test('climbing the live transformer is deadly; so is the earth on a live line', () {
      final a = topup();
      expect(a.step(M4OilLevelStep.climb), M4OilLevelMistakes.climbLive);
      expect(a.ended, isTrue);
      final b = topup();
      expect(b.step(M4OilLevelStep.earth), M4OilLevelMistakes.earthLive);
      expect(b.deadly!.deadly, isTrue);
    });

    test('the tester reads LIVE before the shutdown (no step); earth before the test and climbing unearthed are slips', () {
      final a = topup();
      expect(a.step(M4OilLevelStep.test), isNull);
      expect(a.lastTestLive, isTrue);
      expect(a.tested, isFalse);
      expect(a.step(M4OilLevelStep.shutdown), isNull);
      expect(a.step(M4OilLevelStep.earth), M4OilLevelMistakes.earthUntested);
      expect(a.step(M4OilLevelStep.climb), M4OilLevelMistakes.climbUnproven);
      expect(a.step(M4OilLevelStep.test), isNull);
      expect(a.lastTestLive, isFalse);
      expect(a.step(M4OilLevelStep.climb), M4OilLevelMistakes.climbUnproven, reason: 'tested but not earthed');
      expect(a.slips, 3);
      expect(a.ended, isFalse);
    });

    test('the right order, the right drum, the pour; wrong drums are slips and set aside', () {
      final a = topup();
      for (final s in M4OilLevelStep.values) {
        expect(a.step(s), isNull, reason: s.name);
        expect(a.stepDone(s), isTrue);
      }
      expect(a.canPour, isFalse, reason: 'no oil yet');
      expect(a.pick(M4OilLevelDrum.engine), M4OilLevelMistakes.engineOil);
      expect(a.pick(M4OilLevelDrum.used), M4OilLevelMistakes.usedOil);
      expect(a.pick(M4OilLevelDrum.wet), M4OilLevelMistakes.wetOil);
      expect(a.pick(M4OilLevelDrum.wet), isNull, reason: 'already set aside');
      expect(a.slips, 3);
      expect(a.pick(M4OilLevelDrum.fresh), isNull);
      expect(a.canPour, isTrue);
      expect(a.fill(), isTrue);
      expect(a.shown, isTrue);
      expect(a.caught, containsAll([M4OilLevelLines.caughtSafe, M4OilLevelLines.caughtOil]));
    });

    test('three slips fail the level (percent 55 is the line)', () {
      final d = M4OilLevelDeal(cases: [for (var i = 0; i < 3; i++) fine(M4OilLevelWeather.mild)], drums: M4OilLevelDrum.values);
      final run = M4OilLevelRun(d);
      for (var i = 0; i < 3; i++) {
        expect(run.decide(report: false), M4OilLevelMistakes.noGauge);
        run.next();
      }
      expect(run.done, isTrue);
      expect(run.percent, 55);
      expect(run.slips, 3);
    });

    test('libraries: decks of three, one right; lengths within 1.3×; the coworker; his exit line recorded; art; keys', () {
      final cases = [
        for (final w in M4OilLevelWeather.values) fine(w),
        leak,
        low,
      ];
      for (final c in cases) {
        final right = M4OilLevelLines.whyRight(c);
        final wrong = M4OilLevelLines.whyWrong(c);
        final name = 'why ${c.kind.name} ${c.weather.name}';
        expectLibrary(name, right, wrong);
        expectSameLength(name, [...right, ...wrong]);
        for (var s = 0; s < 10; s++) {
          final deal = dealChoices(right, wrong, math.Random(s));
          expect(deal.where((o) => o.correct).length, 1);
          expect(deal.map((o) => o.textBn).toSet().length, 3);
        }
      }
      final cw = M4OilLevelLines.coworker;
      expectSameLength('choice', [...cw.right, ...cw.wrong]);
      expectLibrary('choice', cw.right, cw.wrong);
      expect(LearnVoice.resolve(cw.exitLine, rival: true), isNotNull);
      final keys = <String>{};
      for (final m in M4OilLevelMistakes.all) {
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.key, startsWith('4.5/m4_oil_level/'));
        expect(keys.add(m.key), isTrue, reason: m.key);
      }
      expect(M4OilLevelMistakes.all.where((m) => m.deadly).toSet(), {M4OilLevelMistakes.climbLive, M4OilLevelMistakes.earthLive});
      expect(m4OilLevelPacks.keys, ['do_4_5_a']);
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

    for (final reduce in [false, true]) {
      testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
        t.view.physicalSize = const Size(720, 1600);
        t.view.devicePixelRatio = 2.0;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        await t.pumpWidget(ProviderScope(
          child: MaterialApp(home: M4OilLevelPage(ctx: _ctx, pack: _pack, muted: true, seed: 4)),
        ));
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
        debugPrint('PERF m4_oil_level ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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

    testWidgets('the guide comes first: a tap does not skip him', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M4OilLevelPage(ctx: _ctx, pack: _pack, muted: true, seed: 2))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text(M4OilLevelLines.ok), findsNothing);
      await waitIntro(t);
      await _pump(t, 1500);
      expect(find.text(M4OilLevelLines.ok), findsOneWidget);
      expect(find.text(M4OilLevelLines.report), findsOneWidget);
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
      expect(lines.every((l) => l.contains(M4OilLevelLines.ask)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('flow: gauge, leaks, verdicts; the top-up done right, the coworker refused → pass', (t) async {
      const seed = 5;
      final deal = dealM4OilLevel(math.Random(seed));
      final c = await _open(t, seed);
      for (var i = 0; i < 3; i++) {
        await _playRight(t, deal, i);
      }
      await _pump(t, 3000);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['4.5/do/0'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['4.5/do/0'], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(M4OilLevelLines.caughtCall), findsOneWidget, reason: 'he came and was refused');
      await _close(t, c);
    });

    testWidgets('a verdict without the gauge: the slip card, then the next transformer', (t) async {
      final c = await _open(t, 6);
      await t.tap(find.text(M4OilLevelLines.ok));
      await _pump(t, 800);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M4OilLevelMistakes.noGauge.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 1500);
      expect(find.byType(MistakeCard), findsNothing);
      expect(find.text(M4OilLevelLines.ok), findsOneWidget, reason: 'the next transformer');
      await _close(t, c);
    });

    testWidgets('a wrong drum on the top-up: the slip card, and the top-up goes on', (t) async {
      var seed = 0;
      while (dealM4OilLevel(math.Random(seed)).callAt != 0) {
        seed++;
      }
      final deal = dealM4OilLevel(math.Random(seed));
      final c = await _open(t, seed);
      await _toTopup(t, deal.cases[0]);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 4000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await _pickRight(t, M4OilLevelLines.coworker.right);
      await _pump(t, 1800);
      await _drum(t, deal, M4OilLevelDrum.engine);
      await _pump(t, 400);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M4OilLevelMistakes.engineOil.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 1200);
      expect(find.byKey(const ValueKey('step-shutdown')), findsOneWidget, reason: 'still on the top-up');
      await _close(t, c);
    });

    testWidgets('listening to him (oil in, live): deadly — freeze first, then the card', (t) async {
      var seed = 0;
      while (dealM4OilLevel(math.Random(seed)).callAt != 0) {
        seed++;
      }
      final deal = dealM4OilLevel(math.Random(seed));
      final c = await _open(t, seed);
      await _toTopup(t, deal.cases[0]);
      // A step before he came: he cuts in now.
      await t.tap(find.byKey(const ValueKey('step-climb')));
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 4000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      final wrong = _onScreen(M4OilLevelLines.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, M4OilLevelMistakes.climbLive.key);
      expect(s.mistakes.single.deadly, isTrue);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });
  });
}
