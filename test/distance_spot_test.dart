// Lesson 1.2, কাজ 1 (কতটা দূরে?): the লক্ষ্মণ রেখা rules, deal variety, the
// band check, fair reason libraries, and the level in the shell (idle perf;
// flow with a short band's slip, three right bands and their reasons).
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/choice_deck.dart';
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
import 'support/option_lengths.dart';

const _ctx = LevelContext(
  rungId: '1.2/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '1.2',
  lessonTitleBn: '',
  ladderStep: 5,
  doIndex: 1,
  doCount: 2,
);

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Finder _label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);
List<Finder> _onScreen(List<String> texts) => [
      for (final x in texts)
        if (_label(x).evaluate().isNotEmpty) _label(x),
    ];

/// Sets the band's edge to [m] metres by a tap on the street.
Future<void> _setBand(WidgetTester t, double m) async {
  final street = t.getRect(_label(DistanceLines.dragLabel).first);
  final k = street.height / StreetGeo.size.height;
  final y = street.top + (StreetGeo.lineY + (m + 0.02) * StreetGeo.ppm) * k;
  await t.tapAt(Offset(street.center.dx, y));
  await _pump(t, 200);
}

void main() {
  group('rules', () {
    test('lesson distances: LT 1.2, 11 kV 2.5, 33 kV 3.0; rain widens 11 kV to 10–12 ft', () {
      expect(distanceFor(RodRating.lt), 1.2);
      expect(distanceFor(RodRating.kv11), 2.5);
      expect(distanceFor(RodRating.kv33), 3.0);
      expect(distanceFor(RodRating.kv11, rain: true), 3.0);
      final rain = dealStreets(math.Random(1)).last;
      expect(rain.minM * 3.281, closeTo(10, 0.2));
      expect(rain.maxM * 3.281, closeTo(12, 0.2));
      expect(DistanceLines.readout(2.5), '2.5 মি · 8 ফুট');
      expect(DistanceLines.readout(1.2), '1.2 মি · 4 ফুট');
    });

    test('every street has someone inside and someone outside, none in the accepted band', () {
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
            // A right band never stops a safe person.
            expect(f.gapM > r.minM && f.gapM < r.maxM, isFalse, reason: 'seed $s ${f.gapM} in ${r.minM}..${r.maxM}');
          }
        }
        // Street 2: a long tool's tip inside.
        expect(rounds[1].figures.any((f) => f.tool && rounds[1].inside(f)), isTrue);
        // Street 3: someone safe on a dry day but inside in the rain.
        expect(rounds[2].figures.any((f) => f.gapM >= 2.5 && f.gapM < 3.0), isTrue);
      }
    });

    test('a band at the lesson distance is clean on every street; the run passes', () {
      final run = DistanceRun(dealStreets(math.Random(9)));
      for (var i = 0; i < 3; i++) {
        final c = run.checkBand(run.current.minM);
        expect(c.deadly, isNull);
        expect(c.slip, isNull);
        expect(c.caught, isNotEmpty);
        run.next();
      }
      expect(run.passed, isTrue);
      expect(run.slips, 0);
    });

    test('a band that leaves someone inside is deadly with the right reason', () {
      final rain = DistanceRun(dealStreets(math.Random(9)))..round = 2;
      final c = rain.checkBand(2.5);
      expect(c.deadly, DistanceMistakes.rainMissed);
      expect(c.missed, isNotNull);

      final tool = DistanceRun(dealStreets(math.Random(9)))..round = 1;
      final tip = tool.current.figures.firstWhere((f) => f.tool && tool.current.inside(f));
      final others = tool.current.figures.where((f) => tool.current.inside(f) && f != tip);
      if (others.every((f) => f.gapM < tip.gapM)) {
        expect(tool.checkBand(tip.gapM - 0.05).deadly, DistanceMistakes.toolTipMissed);
      }
    });

    test('short (no one left), too long, or stopping a safe person: one slip each', () {
      final short = DistanceRun(dealStreets(math.Random(2)));
      final deepest = short.current.figures.where(short.current.inside).map((f) => f.gapM).reduce(math.max);
      final c1 = short.checkBand((deepest + 0.1).clamp(0, short.current.minM - 0.1));
      expect(c1.deadly, isNull);
      expect(c1.slip, DistanceMistakes.bandShort);
      expect(short.slips, 1);

      final wide = DistanceRun(dealStreets(math.Random(2)));
      final c2 = wide.checkBand(DistanceRun.bandMax);
      expect(c2.slip, DistanceMistakes.falseStop);
      expect(c2.falseStops, isNotEmpty);
      expect(wide.slips, 1, reason: 'one slip however many were stopped');

      final rain = DistanceRun(dealStreets(math.Random(2)))..round = 2;
      expect(rain.checkBand(2.9).slip, DistanceMistakes.rainShort);
    });

    test('reason libraries: same length, big enough, the right ones fit the street', () {
      final right = [...DistanceLines.whyLt, ...DistanceLines.whyKv11, ...DistanceLines.whyKv33, ...DistanceLines.whyTool, ...DistanceLines.whyRain];
      expectSameLength('why', [...right, ...DistanceLines.whyWrong]);
      final rounds = dealStreets(math.Random(4));
      for (final r in rounds) {
        expectLibrary('why ${r.line}', DistanceLines.whyRight(r), DistanceLines.whyWrong);
      }
      expect(DistanceLines.whyRight(rounds[1]), containsAll(DistanceLines.whyTool));
      expect(DistanceLines.whyRight(rounds[2]), containsAll(DistanceLines.whyRain));
      expect(DistanceLines.whyRight(rounds[2]), isNot(containsAll(DistanceLines.whyKv11)));
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

    testWidgets('flow: a short band slips and shows the real band; three right bands and reasons clear the rung', (t) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      const seed = 6;
      final rounds = dealStreets(math.Random(seed));
      final deepest = rounds[0].figures.where(rounds[0].inside).map((f) => f.gapM).reduce(math.max);
      expect(deepest, lessThan(1.0), reason: 'seed: a 1.0 m band leaves no one inside on street 1');
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
      await waitIntro(t);
      await _pump(t, 1500);

      // Street 1: short of 1.2 m, no one left inside → a slip, the real band shows.
      await _setBand(t, 1.0);
      expect(find.text(DistanceLines.readout(1.0)), findsOneWidget);
      expect(find.text(DistanceLines.band(rounds[0])), findsNothing, reason: 'no hint before the check');
      await t.tap(find.text(DistanceLines.check));
      await _pump(t, 1500);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(find.text(DistanceLines.band(rounds[0])), findsOneWidget, reason: 'the hint after the mistake');
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);

      for (var i = 0; i < 3; i++) {
        await _setBand(t, rounds[i].minM);
        await t.tap(find.text(DistanceLines.check));
        await _pump(t, 3500);
        expect(find.byType(ChoiceDeck), findsOneWidget, reason: 'street ${i + 1}: the reason deck');
        final right = _onScreen(DistanceLines.whyRight(rounds[i]));
        expect(right, hasLength(1));
        await t.tap(right.single, warnIfMissed: false);
        await _pump(t, i == 2 ? 6000 : 3500);
      }
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['1.2/do/0'], 'cleared');
      expect(s.mistakes.single.key, DistanceMistakes.bandShort.key);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      c.dispose();
      t.view.reset();
    });
  });
}
