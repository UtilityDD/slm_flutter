// Lesson 1.6, কাজ 2 (সোনালি ধাপ ও লাইন ক্লিয়ার): the order rules for the
// permit and line clear, and the level in the shell (idle perf; full flow).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/order_steps.dart';
import 'package:slm_flutter/features/game/ptw_steps.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

const _ctx = LevelContext(
  rungId: '1.6/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '1.6',
  lessonTitleBn: '',
  ladderStep: 18,
  doIndex: 2,
  doCount: 2,
);

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  group('rules', () {
    test('the right order passes both rounds', () {
      final r = OrderRun(permitStepRounds());
      for (final c in permitCards) {
        expect(r.tap(c.id).kind, OrderTapKind.ok);
      }
      expect(r.round, 1);
      for (final c in clearCards) {
        expect(r.tap(c.id).kind, OrderTapKind.ok);
      }
      expect(r.passed, isTrue);
    });

    test('starting work before the permit is issued, or before the test, is deadly', () {
      final a = OrderRun(permitStepRounds())..tap(StepIds.request);
      expect(a.tap(StepIds.start).mistake, StepMistakes.noPermit);
      final b = OrderRun(permitStepRounds());
      for (final id in [StepIds.request, StepIds.isolate, StepIds.issue, StepIds.receive]) {
        b.tap(id);
      }
      expect(b.tap(StepIds.start).mistake, StepMistakes.skipTest);
      expect(b.ended, isTrue);
    });

    test('other steps out of order are slips; line clear before counting has its own reason', () {
      final a = OrderRun(permitStepRounds());
      expect(a.tap(StepIds.issue).mistake, StepMistakes.permitOrder);
      expect(a.ended, isFalse);
      final b = OrderRun(permitStepRounds());
      for (final c in permitCards) {
        b.tap(c.id);
      }
      expect(b.tap(StepIds.clear).mistake, StepMistakes.clearEarly);
      expect(b.tap(StepIds.unlock).mistake, StepMistakes.clearOrder);
      expect(b.slips, 2);
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
          child: MaterialApp(home: PtwStepsPage(ctx: _ctx, pack: stepsPack16, muted: true, seed: 2)),
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
        debugPrint('PERF steps ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
        expect(t.takeException(), isNull);
        expect(find.text('পাঠ 1.6 · কাজ 2/2'), findsOneWidget);
        expect(perSec, lessThan(20));
        expect(frames, lessThan(12));
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 15));
        MascotTalk.reset();
        t.platformDispatcher.clearAccessibilityFeaturesTestValue();
        t.view.reset();
      });
    }

    testWidgets('flow: one slip, then both sequences in order → pass', (t) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      final c = ProviderContainer();
      final nav = GlobalKey<NavigatorState>();
      await t.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
      ));
      unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
        builder: (_) => PtwStepsPage(ctx: _ctx, pack: stepsPack16, muted: true, seed: 3),
      )));
      await _pump(t, 2000);
      Finder card(String title) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == title);

      Future<void> tapCard(String title) async {
        await t.ensureVisible(card(title));
        await t.tap(card(title), warnIfMissed: false);
        await _pump(t, 350);
      }

      // Out of turn: the permit number before the request.
      await tapCard('অনুমোদন');
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 400);
      for (final s in permitCards) {
        await tapCard(s.titleBn);
      }
      await t.tap(find.text(StepLines.next));
      await _pump(t, 500);
      for (final s in clearCards) {
        await tapCard(s.titleBn);
      }
      await _pump(t, 3000);
      final save = c.read(gameSaveProvider);
      expect(save.rungProgress['1.6/do/1'], 'cleared');
      expect(save.mistakes.single.key, StepMistakes.permitOrder.key);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      c.dispose();
      t.view.reset();
    });
  });
}
