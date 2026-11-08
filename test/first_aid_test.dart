// Lesson 1.7 (শক লাগলে ফার্স্ট এইড): rescue rules and the golden-minute order
// and crowd myths; both levels in the shell (idle perf with the countdown
// ticking once a second; full flows).
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/golden_minute.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/order_steps.dart';
import 'package:slm_flutter/features/game/shock_rescue.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';

LevelContext _ctx(int doIndex) => LevelContext(
      rungId: '1.7/do/${doIndex - 1}',
      kind: CatalogRungKind.doKind,
      lessonId: '1.7',
      lessonTitleBn: '',
      ladderStep: 19 + doIndex,
      doIndex: doIndex,
      doCount: 2,
    );

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}


/// The level opens with the guide (no start button, as level 1): wait for him.
Future<void> _skipIntro(WidgetTester t) => waitIntro(t);

void main() {
  group('rescue rules', () {
    test('deals: a switch-at-hand scene and a no-switch scene; one or two safe objects', () {
      for (var s = 0; s < 60; s++) {
        final r = dealRescues(math.Random(s));
        expect(r.length, 3);
        expect(r.any((x) => x.scene.switchNear), isTrue);
        expect(r.any((x) => !x.scene.switchNear), isTrue);
        for (final x in r) {
          expect(x.objects.length, 4);
          expect(x.objects.where((o) => o.safe).length, inInclusiveRange(1, 2));
        }
      }
    });

    test('touching (hand or shirt) and wet / metal objects are deadly', () {
      final r = dealRescues(math.Random(1));
      expect(RescueRun(r).act(RescueAction.grabHand), RescueMistakes.touch);
      expect(RescueRun(r).act(RescueAction.grabShirt), RescueMistakes.shirt);
      final far = r.indexWhere((x) => !x.scene.switchNear);
      RescueRun sep() => RescueRun(r)
        ..round = far
        ..act(RescueAction.separate);
      expect(sep().pick(RescueObject.wetStick), RescueMistakes.wetStick);
      expect(sep().pick(RescueObject.ironRod), RescueMistakes.metal);
      expect(sep().pick(RescueObject.ladder), RescueMistakes.metal);
    });

    test('switch at hand: switching off is right, separating is a slip; push the limbs not chest/head', () {
      final r = dealRescues(math.Random(1));
      final near = r.indexWhere((x) => x.scene.switchNear);
      final a = RescueRun(r)..round = near;
      expect(a.act(RescueAction.separate), RescueMistakes.switchNear);
      expect(a.act(RescueAction.switchOff), isNull);
      expect(a.phase, RescuePhase.done);
      final far = r.indexWhere((x) => !x.scene.switchNear);
      final b = RescueRun(r)
        ..round = far
        ..act(RescueAction.separate)
        ..pick(RescueObject.bamboo);
      expect(b.push(BodyZone.chest), RescueMistakes.chestHead);
      expect(b.push(BodyZone.arm), isNull);
      expect(b.phase, RescuePhase.done);
      expect(b.slips, 1);
    });

    test('running out of time is a slip and ends the scene', () {
      final run = RescueRun(dealRescues(math.Random(2)));
      expect(run.timeout(), RescueMistakes.late);
      expect(run.phase, RescuePhase.done);
      expect(run.ended, isFalse);
    });
  });

  group('golden minute rules', () {
    test('the order: response, breathing, call, CPR, keep going; anything else is a slip', () {
      final r = OrderRun(goldenRounds());
      expect(r.tap(GoldenIds.cpr).mistake, GoldenMistakes.order);
      for (final c in goldenCards) {
        expect(r.tap(c.id).kind, OrderTapKind.ok);
      }
      expect(r.done, isTrue);
      expect(r.slips, 1);
      expect(GoldenMistakes.all.every((m) => !m.deadly), isTrue);
    });

    test('crowd: three different myths each play', () {
      for (var s = 0; s < 30; s++) {
        final c = dealCrowd(math.Random(s));
        expect(c.length, 3);
        expect(c.toSet().length, 3);
      }
    });
  });

  group('pages', () {
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

    for (final which in ['rescue', 'golden']) {
      for (final reduce in [false, true]) {
        testWidgets('$which waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
          t.view.physicalSize = const Size(720, 1600);
          t.view.devicePixelRatio = 2.0;
          t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
          await t.pumpWidget(ProviderScope(
            child: MaterialApp(
              home: which == 'rescue'
                  ? ShockRescuePage(ctx: _ctx(1), pack: const RescuePack(id: 'do_1_7_a', titleBn: RescueLines.title, seconds: 60), muted: true, seed: 2)
                  : GoldenMinutePage(ctx: _ctx(2), pack: goldenPack17, muted: true, seed: 2),
            ),
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
          debugPrint('PERF $which ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
          expect(t.takeException(), isNull);
          expect(perSec, lessThan(20));
          expect(frames, lessThan(12));
          await t.pumpWidget(const SizedBox());
          await t.pump(const Duration(seconds: 15));
          MascotTalk.reset();
          t.platformDispatcher.clearAccessibilityFeaturesTestValue();
          t.view.reset();
        });
      }
    }

    Future<(ProviderContainer, GlobalKey<NavigatorState>)> open(WidgetTester t, Widget page) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      final c = ProviderContainer();
      final nav = GlobalKey<NavigatorState>();
      await t.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
      ));
      unawaited(nav.currentState!.push(MaterialPageRoute<bool>(builder: (_) => page)));
      await _pump(t, 1500);
      await _skipIntro(t);
      return (c, nav);
    }

    Future<void> close(WidgetTester t, ProviderContainer c) async {
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      c.dispose();
      t.view.reset();
    }

    testWidgets('rescue flow: switch off where at hand; elsewhere a safe object and a push on the arm → pass', (t) async {
      const seed = 4;
      final rounds = dealRescues(math.Random(seed));
      final (c, _) = await open(t, ShockRescuePage(ctx: _ctx(1), pack: rescuePack17, muted: true, seed: seed));
      final objects = find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'জিনিস');
      final body = find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'শরীর');
      for (var i = 0; i < 3; i++) {
        final r = rounds[i];
        if (r.scene.switchNear) {
          await t.tap(find.text(RescueLines.action(RescueAction.switchOff, r.scene)));
          await _pump(t, 500);
        } else {
          await t.tap(find.text(RescueLines.action(RescueAction.separate, r.scene)));
          await _pump(t, 1200);
          await t.tap(objects.at(r.objects.indexWhere((o) => o.safe)), warnIfMissed: false);
          await _pump(t, 500);
          await t.tap(body.at(2), warnIfMissed: false); // arm (map order: head, chest, arm, leg)
          await _pump(t, 500);
        }
        expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'scene $i');
        await t.tap(find.text(i == 2 ? RescueLines.finish : RescueLines.next));
        await _pump(t, i == 2 ? 3000 : 500);
      }
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['1.7/do/0'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('golden minute flow: the order, then "না" to every myth → pass', (t) async {
      const seed = 3;
      final crowd = dealCrowd(math.Random(seed));
      final (c, _) = await open(t, GoldenMinutePage(ctx: _ctx(2), pack: goldenPack17, muted: true, seed: seed));
      Finder card(String title) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == title);
      for (final s in goldenCards) {
        await t.ensureVisible(card(s.titleBn));
        await t.tap(card(s.titleBn), warnIfMissed: false);
        await _pump(t, 350);
      }
      expect(find.text(GoldenLines.next), findsOneWidget, reason: 'order done');
      await t.tap(find.text(GoldenLines.next));
      await _pump(t, 600);
      for (final m in crowd) {
        await t.tap(find.text(GoldenLines.holdOut(m)));
        await _pump(t, 700);
      }
      await _pump(t, 2500);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['1.7/do/1'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(find.text(GoldenLines.caughtCrowd), findsOneWidget);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('golden minute: giving in to a myth shows its card, then the next bystander comes', (t) async {
      const seed = 3;
      final crowd = dealCrowd(math.Random(seed));
      final (c, _) = await open(t, GoldenMinutePage(ctx: _ctx(2), pack: goldenPack17, muted: true, seed: seed));
      Finder card(String title) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == title);
      for (final s in goldenCards) {
        await t.ensureVisible(card(s.titleBn));
        await t.tap(card(s.titleBn), warnIfMissed: false);
        await _pump(t, 300);
      }
      await t.tap(find.text(GoldenLines.next));
      await _pump(t, 600);
      await t.tap(find.text(GoldenLines.giveIn(crowd[0])));
      await _pump(t, 700);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.text('“${GoldenLines.myth(crowd[1])}”'), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, GoldenMistakes.myth(crowd[0]).key);
      expect(t.takeException(), isNull);
      await close(t, c);
    });
  });
}
