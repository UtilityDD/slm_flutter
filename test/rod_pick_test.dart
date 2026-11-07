// Lesson 1.5, কাজ 1 (সঠিক রড): rules of the store rack, deal variety, and the
// level in the shell (perf idle, flow to a pass with the job held on docket 3).
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/rod_pick.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

const _ctx = LevelContext(
  rungId: '1.5/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '1.5',
  lessonTitleBn: '',
  ladderStep: 14,
  doIndex: 1,
  doCount: 2,
);

RodItem _right(RodRoundDeal r) => r.rods.firstWhere((x) => x.rating == r.docket.line && x.flaw == RodFlaw.none);

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  group('rules', () {
    test('every deal: docket 1 and 2 have exactly one right rod; docket 3 has none', () {
      for (var s = 0; s < 60; s++) {
        final d = dealRods(math.Random(s));
        expect(d.rounds.length, 3);
        for (final r in d.rounds.take(2)) {
          expect(r.rods.where((x) => x.rating == r.docket.line && x.flaw == RodFlaw.none).length, 1);
          expect(r.rods.where((x) => x.jugaad).length, 1);
        }
        expect(d.rounds[1].docket.line, RodRating.kv33);
        expect(d.rounds[2].noneFits, isTrue);
        // Never a rod rated above the line: "higher is fine" is not what this level teaches.
        for (final r in d.rounds) {
          expect(r.rods.any((x) => x.rating != null && x.rating!.index > r.docket.line.index), isFalse);
        }
      }
    });

    test('a clean play: right rod, right rod, hold the job', () {
      final run = RodRun(dealRods(math.Random(3)));
      expect(run.take(_right(run.current)).verdict, RodVerdict.right);
      expect(run.take(_right(run.current)).verdict, RodVerdict.right);
      expect(run.holdJob().verdict, RodVerdict.right);
      expect(run.passed, isTrue);
      expect(run.percent, 100);
    });

    test('the jugaad and a lower rating are deadly', () {
      final a = RodRun(dealRods(math.Random(1)));
      expect(a.take(a.current.rods.firstWhere((x) => x.jugaad)).mistake, RodMistakes.jugaad);
      expect(a.ended, isTrue);

      final b = RodRun(dealRods(math.Random(1)));
      b.take(_right(b.current));
      final lower = b.current.rods.firstWhere((x) => x.rating == RodRating.kv11);
      expect(b.take(lower).mistake, RodMistakes.wrongRating);
      expect(b.deadly, RodMistakes.wrongRating);
    });

    test('a damaged rod is a slip and leaves the rack; holding the job too early is a slip', () {
      final run = RodRun(dealRods(math.Random(5)));
      run.take(_right(run.current));
      expect(run.holdJob().mistake, RodMistakes.heldWhenRight);
      final twin = run.current.rods.firstWhere((x) => x.rating == RodRating.kv33 && x.flaw != RodFlaw.none);
      final o = run.take(twin);
      expect(o.verdict, RodVerdict.slip);
      expect([RodMistakes.crack, RodMistakes.cable, RodMistakes.clamp], contains(o.mistake));
      expect(run.rejected, contains(twin.id));
      expect(run.slips, 2);
      expect(run.ended, isFalse);
    });

    test('deals vary', () {
      final deals = [for (var s = 0; s < 40; s++) dealRods(math.Random(s))];
      expect(deals.map((d) => d.rounds.first.docket.line).toSet(), {RodRating.lt, RodRating.kv11});
      expect(deals.map((d) => d.rounds.last.docket.line).toSet(), {RodRating.kv11, RodRating.kv33});
      expect(deals.map((d) => d.rounds[1].rods.firstWhere((x) => x.flaw != RodFlaw.none).flaw).toSet().length, 3);
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
      testWidgets('waits quietly on the rack (${reduce ? 'reduce' : 'anim'})', (t) async {
        t.view.physicalSize = const Size(720, 1600);
        t.view.devicePixelRatio = 2.0;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        await t.pumpWidget(ProviderScope(
          child: MaterialApp(home: RodPickPage(ctx: _ctx, pack: rodPickPack15, muted: true, seed: 2)),
        ));
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
        debugPrint('PERF rod pick ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
        expect(t.takeException(), isNull);
        expect(find.text('পাঠ 1.5 · কাজ 1/2'), findsOneWidget);
        expect(find.text(RodLines.docket), findsOneWidget);
        expect(perSec, lessThan(20));
        expect(frames, lessThan(12));
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 15));
        MascotTalk.reset();
        t.platformDispatcher.clearAccessibilityFeaturesTestValue();
        t.view.reset();
      });
    }

    testWidgets('flow: a damaged rod is a slip card; right, right, hold the job → pass', (t) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      const seed = 4;
      final deal = dealRods(math.Random(seed));
      final c = ProviderContainer();
      final nav = GlobalKey<NavigatorState>();
      await t.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
      ));
      unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
        builder: (_) => RodPickPage(ctx: _ctx, pack: rodPickPack15, muted: true, seed: seed),
      )));
      await _pump(t, 2500);

      final rods = find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'রড');
      Future<void> takeAt(RodRoundDeal r, RodItem rod) async {
        await t.tap(rods.at(r.rods.indexOf(rod)), warnIfMissed: false);
        await _pump(t, 500);
        expect(find.text(RodLines.take), findsOneWidget);
        await t.tap(find.text(RodLines.take));
        await _pump(t, 1200);
      }

      final r1 = deal.rounds[0];
      await takeAt(r1, _right(r1));
      final r2 = deal.rounds[1];
      // The damaged 33 kV twin first: a slip card, then the right one.
      await takeAt(r2, r2.rods.firstWhere((x) => x.rating == RodRating.kv33 && x.flaw != RodFlaw.none));
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 500);
      expect(find.text(RodLines.rejected), findsOneWidget);
      await takeAt(r2, _right(r2));
      // Docket 3: nothing fits — hold the job.
      await t.tap(find.text(RodLines.hold));
      await _pump(t, 3000);

      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['1.5/do/0'], 'cleared');
      expect(s.mistakes.length, 1);
      expect(find.text(RodLines.caughtHold), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      c.dispose();
      t.view.reset();
    });
  });
}
