// Lesson 1.2, কাজ 1 (কতটা দূরে?): the লক্ষ্মণ রেখা rules, deal variety, and
// the level in the shell (idle perf; flow with a false stop and a pass).
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/distance_spot.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/rod_pick.dart' show RodRating;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';

const _ctx = LevelContext(
  rungId: '1.2/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '1.2',
  lessonTitleBn: '',
  ladderStep: 5,
  doIndex: 1,
  doCount: 2,
);

Set<String> _insideIds(StreetRound r) => {for (final f in r.figures) if (r.inside(f)) f.id};

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}


/// The level opens with the guide (no start button, as level 1): wait for him.
Future<void> _skipIntro(WidgetTester t) => waitIntro(t);

void main() {
  group('rules', () {
    test('lesson distances: LT 1.2, 11 kV 2.5, 33 kV 3.0; rain widens 11 kV to 3.5', () {
      expect(distanceFor(RodRating.lt), 1.2);
      expect(distanceFor(RodRating.kv11), 2.5);
      expect(distanceFor(RodRating.kv33), 3.0);
      expect(distanceFor(RodRating.kv11, rain: true), 3.5);
    });

    test('every street has someone inside and someone outside, with a clear margin', () {
      for (var s = 0; s < 80; s++) {
        final rounds = dealStreets(math.Random(s));
        expect(rounds.map((r) => r.line).first, RodRating.lt);
        expect(rounds.last.rain, isTrue);
        for (final r in rounds) {
          expect(r.figures.length, 3);
          expect(r.figures.any(r.inside), isTrue);
          expect(r.figures.any((f) => !r.inside(f)), isTrue);
          for (final f in r.figures) {
            // No figure sits on the edge: at least 0.25 m either side.
            expect((f.gapM - r.distanceM).abs(), greaterThan(0.25), reason: 'seed $s ${f.kind} ${f.gapM} vs ${r.distanceM}');
          }
        }
        // Street 2: a long tool's tip inside.
        expect(rounds[1].figures.any((f) => f.tool && rounds[1].inside(f)), isTrue);
        // Street 3: someone safe on a dry day but inside in the rain.
        expect(rounds[2].figures.any((f) => f.gapM >= 2.5 && f.gapM < 3.5), isTrue);
      }
    });

    test('marking exactly the ones inside is clean; a missed one is deadly with the right reason', () {
      final rounds = dealStreets(math.Random(9));
      final run = DistanceRun(rounds);
      for (var i = 0; i < 3; i++) {
        final c = run.check(_insideIds(run.current));
        expect(c.deadly, isNull);
        expect(c.falseStops, isEmpty);
        run.next();
      }
      expect(run.passed, isTrue);

      final rain = DistanceRun(dealStreets(math.Random(9)))..round = 2;
      final trap = rain.current.figures.firstWhere((f) => f.gapM >= 2.5 && f.gapM < 3.5);
      expect(rain.check(_insideIds(rain.current)..remove(trap.id)).deadly, DistanceMistakes.rainMissed);

      final tool = DistanceRun(dealStreets(math.Random(9)))..round = 1;
      final tip = tool.current.figures.firstWhere((f) => f.tool && tool.current.inside(f));
      expect(tool.check(_insideIds(tool.current)..remove(tip.id)).deadly, DistanceMistakes.toolTipMissed);
    });

    test('stopping someone outside is a slip per person', () {
      final run = DistanceRun(dealStreets(math.Random(2)));
      final all = {for (final f in run.current.figures) f.id};
      final c = run.check(all);
      expect(c.deadly, isNull);
      expect(c.falseStops, isNotEmpty);
      expect(run.slips, c.falseStops.length);
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
      testWidgets('waits quietly on the street (${reduce ? 'reduce' : 'anim'})', (t) async {
        t.view.physicalSize = const Size(720, 1600);
        t.view.devicePixelRatio = 2.0;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        await t.pumpWidget(ProviderScope(
          child: MaterialApp(home: DistanceSpotPage(ctx: _ctx, pack: distancePack12, muted: true, seed: 2)),
        ));
        await t.pump(const Duration(milliseconds: 100));
        await waitIntro(t);
        await _pump(t, 6000);
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
        debugPrint('PERF distance ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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

    testWidgets('flow: a false stop shows its card; three clean checks pass the rung', (t) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      const seed = 6;
      final rounds = dealStreets(math.Random(seed));
      final c = ProviderContainer();
      final nav = GlobalKey<NavigatorState>();
      await t.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
      ));
      unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
        builder: (_) => DistanceSpotPage(ctx: _ctx, pack: distancePack12, muted: true, seed: seed),
      )));
      await _pump(t, 2500);
      await _skipIntro(t);
      final people = find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'মানুষ');

      for (var i = 0; i < 3; i++) {
        final r = rounds[i];
        for (var k = 0; k < r.figures.length; k++) {
          final mark = r.inside(r.figures[k]) || (i == 0 && !r.inside(r.figures[k]) && k == r.figures.indexWhere((f) => !r.inside(f)));
          if (mark) {
            await t.tap(people.at(k), warnIfMissed: false);
            await _pump(t, 150);
          }
        }
        await t.tap(find.text(DistanceLines.check));
        await _pump(t, 1500);
        if (i == 0) {
          expect(find.text(MistakeLines.slipHead), findsOneWidget);
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 400);
        }
        await t.tap(find.text(i == 2 ? DistanceLines.finish : DistanceLines.next));
        await _pump(t, i == 2 ? 3000 : 600);
      }
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['1.2/do/0'], 'cleared');
      expect(s.mistakes.single.key, DistanceMistakes.falseStop.key);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      c.dispose();
      t.view.reset();
    });
  });
}
