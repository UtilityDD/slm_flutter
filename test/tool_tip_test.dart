// Lesson 1.2, কাজ 2 (লম্বা টুলের ডগা): tool choice, reach-or-shutdown, deal
// variety, and the level in the shell (idle perf; a full clean flow).
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
import 'package:slm_flutter/features/game/rod_pick.dart' show RodRating;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/game/tool_tip.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

const _ctx = LevelContext(
  rungId: '1.2/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '1.2',
  lessonTitleBn: '',
  ladderStep: 6,
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
    test('deals: each voltage once, an inside and an outside kite, clear margins', () {
      for (var s = 0; s < 80; s++) {
        final d = dealKites(math.Random(s));
        expect(d.rounds.map((r) => r.line).toSet(), RodRating.values.toSet());
        expect(d.rounds.any((r) => r.inside), isTrue);
        expect(d.rounds.any((r) => !r.inside), isTrue);
        for (final r in d.rounds) {
          expect((r.gapM - r.distanceM).abs(), greaterThan(0.25), reason: 'seed $s');
          expect(r.tools.toSet(), LongTool.values.toSet());
        }
        expect(d.callRound, inInclusiveRange(0, 2));
      }
    });

    test('bamboo and PVC are deadly; the hot stick moves on to the decision', () {
      expect(KiteRun(dealKites(math.Random(1))).pickTool(LongTool.bamboo), ToolTipMistakes.bamboo);
      expect(KiteRun(dealKites(math.Random(1))).pickTool(LongTool.pvc), ToolTipMistakes.pvc);
      final run = KiteRun(dealKites(math.Random(1)));
      expect(run.pickTool(LongTool.hotStick), isNull);
      expect(run.phase, KitePhase.decide);
    });

    test('reach inside = deadly; shutdown outside = slip; the right call each round passes', () {
      final d = dealKites(math.Random(4));
      final inside = d.rounds.indexWhere((r) => r.inside);
      final outside = d.rounds.indexWhere((r) => !r.inside);

      final a = KiteRun(d)..round = inside;
      a.pickTool(LongTool.hotStick);
      expect(a.decide(reach: true), ToolTipMistakes.tipInside);
      expect(a.ended, isTrue);

      final b = KiteRun(d)..round = outside;
      b.pickTool(LongTool.hotStick);
      expect(b.decide(reach: false), ToolTipMistakes.needlessShutdown);
      expect(b.slips, 1);
      expect(b.ended, isFalse);

      final c = KiteRun(d);
      for (var i = 0; i < 3; i++) {
        c.pickTool(LongTool.hotStick);
        expect(c.decide(reach: !c.current.inside), isNull);
        c.next();
      }
      expect(c.passed, isTrue);
      expect(c.percent, 100);
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
          child: MaterialApp(home: ToolTipPage(ctx: _ctx, pack: toolTipPack12, muted: true, seed: 3)),
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
        debugPrint('PERF tool tip ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
        expect(t.takeException(), isNull);
        expect(find.text('পাঠ 1.2 · কাজ 2/2'), findsOneWidget);
        expect(perSec, lessThan(20));
        expect(frames, lessThan(12));
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 15));
        MascotTalk.reset();
        t.platformDispatcher.clearAccessibilityFeaturesTestValue();
        t.view.reset();
      });
    }

    testWidgets('flow: refuse the helper, hot stick each time, right call each kite → pass', (t) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      const seed = 5;
      final deal = dealKites(math.Random(seed));
      final c = ProviderContainer();
      final nav = GlobalKey<NavigatorState>();
      await t.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
      ));
      unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
        builder: (_) => ToolTipPage(ctx: _ctx, pack: toolTipPack12, muted: true, seed: seed),
      )));
      await _pump(t, 2000);
      final tools = find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'টুল');

      for (var i = 0; i < 3; i++) {
        final r = deal.rounds[i];
        if (i == deal.callRound) {
          expect(find.text(ToolTipLines.holdOut), findsOneWidget);
          await t.tap(find.text(ToolTipLines.holdOut));
          await _pump(t, 600);
        }
        await t.tap(tools.at(r.tools.indexOf(LongTool.hotStick)), warnIfMissed: false);
        await _pump(t, 600);
        await t.tap(find.text(r.inside ? ToolTipLines.shutdown : ToolTipLines.reach));
        await _pump(t, 1200);
        expect(find.text(MistakeLines.slipHead), findsNothing);
        await t.tap(find.text(i == 2 ? ToolTipLines.finish : ToolTipLines.next));
        await _pump(t, i == 2 ? 3000 : 600);
      }
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['1.2/do/1'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(find.text(ToolTipLines.caughtCall), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      c.dispose();
      t.view.reset();
    });
  });
}
