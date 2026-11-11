// Lesson 1.7 কাজ 1 (ছোঁবেন না!): rescue rules, deals, fair reason libraries
// that fit the scene, his recorded line, and the level in the shell: idle
// perf with the countdown ticking once a second, the guide first, a full
// clean play (pull the switch where it is at hand, elsewhere drag a dry
// non-conductor onto his arm or leg, the reasons, the coworker refused), a
// slip that keeps the scene, the 3-slip strike-out, and the deadly freeze
// (a tap on him; listening to the coworker).
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
import 'package:slm_flutter/features/game/level_frame.dart';
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/shock_rescue.dart';
import 'package:slm_flutter/features/game/shock_scene.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';

LevelContext _ctx() => const LevelContext(
      rungId: '1.7/do/0',
      kind: CatalogRungKind.doKind,
      lessonId: '1.7',
      lessonTitleBn: '',
      ladderStep: 20,
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

/// Taps the one right card on the deck now up.
Future<void> _pickRight(WidgetTester t, List<String> right) async {
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = _onScreen(right);
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
  await t.pump();
  // Wait for reason zoom (coworker decks have no proceed).
  for (var i = 0; i < 40 && find.byKey(const ValueKey('reason-proceed-btn')).evaluate().isEmpty; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
  final go = find.byKey(const ValueKey('reason-proceed-btn'));
  if (go.evaluate().isNotEmpty) {
    await t.tap(go, warnIfMissed: false);
    await t.pump();
  }
}

/// A seed whose deal satisfies [ok].
int _seedWhere(bool Function(RescueDeal d) ok, {int from = 0}) {
  var s = from;
  while (!ok(dealRescues(math.Random(s)))) {
    s++;
  }
  return s;
}

Future<ProviderContainer> _open(WidgetTester t, int seed, {RescuePack pack = rescuePack17}) async {
  t.view.physicalSize = const Size(784, 1700);
  t.view.devicePixelRatio = 2.0;
  final c = ProviderContainer();
  final nav = GlobalKey<NavigatorState>();
  await t.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
  ));
  unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
    builder: (_) => ShockRescuePage(ctx: _ctx(), pack: pack, muted: true, seed: seed),
  )));
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

/// Pull the switch's lever down.
Future<void> _pullSwitch(WidgetTester t) async {
  await t.drag(find.byKey(const ValueKey('switch')), const Offset(0, 140), warnIfMissed: false);
  await _pump(t, 300);
}

/// Drag the thing in slot [i] onto his [z].
Future<void> _dragOnto(WidgetTester t, int i, BodyZone z) async {
  final from = t.getCenter(find.byKey(ValueKey('slot-$i')));
  final to = t.getCenter(find.byKey(ValueKey('zone-${z.name}')));
  await t.dragFrom(from, to - from);
  await _pump(t, 300);
}

void main() {
  group('rules', () {
    test('deals: 3 scenes, a switch-at-hand and a no-switch scene, 1–2 dry things of 4; his scene; fresh each play', () {
      final seen = <String>{};
      final calls = <int>{};
      for (var s = 0; s < 80; s++) {
        final d = dealRescues(math.Random(s));
        expect(d.rounds.length, 3);
        expect(d.rounds.any((x) => x.scene.switchNear), isTrue);
        expect(d.rounds.any((x) => !x.scene.switchNear), isTrue);
        expect(d.callScene, inInclusiveRange(0, 2));
        calls.add(d.callScene);
        for (final x in d.rounds) {
          expect(x.objects.length, 4);
          expect(x.objects.toSet().length, 4);
          expect(x.objects.where((o) => o.safe).length, inInclusiveRange(1, 2));
        }
        seen.add(d.rounds.map((x) => '${x.scene}${x.objects}').join('|'));
      }
      expect(seen.length, greaterThan(40));
      expect(calls, {0, 1, 2});
    });

    test('a bare hand on him is deadly (the shirt counts); a wet stick, iron rod or ladder too — anywhere', () {
      final d = dealRescues(math.Random(1));
      expect(RescueRun(d).touch(BodyZone.arm), RescueMistakes.touch);
      expect(RescueRun(d).touch(BodyZone.leg), RescueMistakes.touch);
      expect(RescueRun(d).touch(BodyZone.chest), RescueMistakes.shirt);
      for (final i in [0, 1, 2]) {
        RescueRun at() => RescueRun(d)..round = i;
        expect(at().push(RescueObject.wetStick, BodyZone.leg), RescueMistakes.wetStick);
        expect(at().push(RescueObject.ironRod, BodyZone.arm), RescueMistakes.metal);
        expect(at().push(RescueObject.ladder, BodyZone.leg), RescueMistakes.metal);
        final r = at()..push(RescueObject.ironRod, BodyZone.arm);
        expect(r.ended, isTrue);
        expect(r.deadly!.deadly, isTrue);
      }
      for (final m in [RescueMistakes.touch, RescueMistakes.shirt, RescueMistakes.wetStick, RescueMistakes.metal]) {
        expect(m.deadly, isTrue);
      }
    });

    test('switch at hand: the lever frees him; a dry push is a slip and the scene stays', () {
      final d = dealRescues(math.Random(1));
      final near = d.rounds.indexWhere((x) => x.scene.switchNear);
      final a = RescueRun(d)..round = near;
      expect(a.push(RescueObject.bamboo, BodyZone.arm), RescueMistakes.switchNear);
      expect(a.slips, 1);
      expect(a.open, isTrue);
      expect(a.switchOff(), isTrue);
      expect(a.cleared, isTrue);
      expect(a.used, isNull);
      expect(a.caught, contains(RescueLines.caughtSwitch));
      final far = d.rounds.indexWhere((x) => !x.scene.switchNear);
      expect((RescueRun(d)..round = far).switchOff(), isFalse, reason: 'no switch there');
    });

    test('no switch: a dry thing on the arm or leg frees him; on the chest or head a slip and the scene stays', () {
      final d = dealRescues(math.Random(1));
      final far = d.rounds.indexWhere((x) => !x.scene.switchNear);
      for (final o in RescueObject.values.where((o) => o.safe)) {
        final b = RescueRun(d)..round = far;
        expect(b.push(o, BodyZone.chest), RescueMistakes.chestHead);
        expect(b.push(o, BodyZone.head), RescueMistakes.chestHead);
        expect(b.slips, 2);
        expect(b.open, isTrue);
        expect(b.push(o, BodyZone.leg), isNull);
        expect(b.cleared, isTrue);
        expect(b.used, o);
        expect(b.caught, containsAll([RescueLines.caughtObject, RescueLines.caughtPush]));
        expect(b.push(o, BodyZone.arm), isNull, reason: 'nothing after he is free');
        expect(b.slips, 2);
      }
    });

    test('running out of time is a slip and ends the scene; three slips leave 55', () {
      final run = RescueRun(dealRescues(math.Random(2)));
      expect(run.timeout(), RescueMistakes.late);
      expect(run.cleared, isTrue);
      expect(run.late, isTrue);
      expect(run.ended, isFalse);
      expect(run.timeout(), isNull);
      run.next();
      expect(run.open, isTrue);
      expect(run.late, isFalse);
      run
        ..timeout()
        ..next()
        ..timeout()
        ..next();
      expect(run.done, isTrue);
      expect(run.percent, 55);
      expect(run.passed, isTrue);
    });

    test('every mistake has its picture on disk and a lesson point of 1.7 (0–3)', () {
      for (final m in RescueMistakes.all) {
        expect(m.art, startsWith('assets/game/art/shock/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.lessonPoint, inInclusiveRange(0, 3));
        expect(m.key, startsWith('1.7/rescue/'));
      }
      expect(RescueMistakes.all.map((m) => m.key).toSet().length, RescueMistakes.all.length);
    });

    test('reasons: all about the same length, big enough, and they fit what the scene had', () {
      final safe = RescueObject.values.where((o) => o.safe).toList();
      expectSameLength('reasons', [
        ...RescueLines.switchHouse,
        ...RescueLines.switchPump,
        ...RescueLines.switchWrong,
        for (final o in safe) ...RescueLines.objectWhy(o),
        RescueLines.pushAny,
        ...RescueLines.pushWrong,
      ]);
      expectLibrary('switch house', RescueLines.whyRight(ShockScene.house, null), RescueLines.whyWrong(null));
      expectLibrary('switch pump', RescueLines.whyRight(ShockScene.pump, null), RescueLines.whyWrong(null));
      expect(RescueLines.whyRight(ShockScene.pump, null).every((t) => t.contains('পাম্পের সুইচ')), isTrue);
      expect(RescueLines.whyRight(ShockScene.house, null).every((t) => t.contains('সুইচ')), isTrue);
      // No length tell: the right cards are not longer than the wrong ones on average.
      double mean(List<String> l) => l.fold<int>(0, (a, t) => a + t.length) / l.length;
      for (final (scene, used) in [
        (ShockScene.house, null),
        (ShockScene.pump, null),
        for (final o in safe) (ShockScene.field, o),
      ]) {
        expect(mean(RescueLines.whyRight(scene, used)), lessThanOrEqualTo(mean(RescueLines.whyWrong(used)) + 1.5), reason: '$scene $used');
      }
      for (final o in safe) {
        for (final s in [ShockScene.field, ShockScene.roadside]) {
          final right = RescueLines.whyRight(s, o);
          expectLibrary('$o', right, RescueLines.whyWrong(o));
          for (final other in safe.where((x) => x != o)) {
            for (final t in RescueLines.objectWhy(other)) {
              expect(right, isNot(contains(t)), reason: '$o: a reason for $other');
            }
          }
          for (var k = 0; k < 12; k++) {
            final deal = dealChoices(right, RescueLines.whyWrong(o), math.Random(k));
            expect(deal.where((x) => x.correct).length, 1);
            expect(deal.map((x) => x.textBn).toSet().length, 3);
          }
        }
      }
      for (final o in RescueObject.values.where((o) => !o.safe)) {
        expect(RescueLines.objectWhy(o), isEmpty);
      }
    });

    test('the coworker: fair choice library; his lines are recorded in his voice', () {
      const c = RescueLines.coworker;
      expectSameLength('coworker', [...c.right, ...c.wrong]);
      expectLibrary('coworker', c.right, c.wrong);
      for (final l in c.recordedLines) {
        expect(LearnVoice.resolve(l, rival: true), isNotNull, reason: l);
      }
      expect(c.line, 'হাত দিয়ে টেনে নাও, তাড়াতাড়ি!');
    });

    test('the body zones: the push reaches the limb, a tap on the chest is the chest', () {
      const g = ShockGeo(height: 780, groundY: 584);
      for (final z in BodyZone.values) {
        expect(g.zoneAt(g.zone(z).center), z, reason: '$z');
      }
      expect(g.zoneAt(g.backArm.center), BodyZone.arm);
      expect(g.zoneAt(g.slot(0).center), isNull);
      expect(g.zoneAt(const Offset(40, 200)), isNull);
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

    // He comes later in the play: the first scene is left alone to idle.
    final idleSeed = _seedWhere((d) => d.callScene != 0);
    for (final reduce in [false, true]) {
      testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'}), the countdown ticking', (t) async {
        t.view.physicalSize = const Size(720, 1600);
        t.view.devicePixelRatio = 2.0;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        await t.pumpWidget(ProviderScope(
          child: MaterialApp(
            home: ShockRescuePage(ctx: _ctx(), pack: const RescuePack(id: 'do_1_7_a', titleBn: RescueLines.title, seconds: 60), muted: true, seed: idleSeed),
          ),
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
        debugPrint('PERF shock_rescue ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
        expect(t.takeException(), isNull);
        expect(find.textContaining('ধাপ '), findsOneWidget);
        expect(find.text(RescueLines.secs(46)), findsNothing, reason: 'the clock has moved on');
        expect(perSec, lessThan(20));
        expect(frames, lessThan(12));
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 15));
        MascotTalk.reset();
        t.platformDispatcher.clearAccessibilityFeaturesTestValue();
        t.view.reset();
      });
    }

    testWidgets('the guide comes first: no start button, a tap does not skip him, the clock waits', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(
        child: MaterialApp(home: ShockRescuePage(ctx: _ctx(), pack: rescuePack17, muted: true, seed: idleSeed)),
      ));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text('শুরু'), findsNothing);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await _pump(t, 2000);
      expect(find.text(RescueLines.secs(15)), findsOneWidget, reason: 'the clock waits for the guide');
      await waitIntro(t);
      await _pump(t, 2100);
      expect(find.text(RescueLines.secs(15)), findsNothing);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final c = await _open(t, idleSeed);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(RescueLines.ask)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('flow: the switch where at hand, a dry thing on the limb elsewhere, the reasons, him refused → pass', (t) async {
      const seed = 4;
      final deal = dealRescues(math.Random(seed));
      final c = await _open(t, seed);
      for (var i = 0; i < 3; i++) {
        final r = deal.rounds[i];
        if (i == deal.callScene) {
          // He peeps in a moment after the scene starts; the guide asks; refuse him.
          await _pump(t, 3000);
          expect(find.byType(CoworkerPeek), findsOneWidget);
          await _pickRight(t, RescueLines.coworker.right);
          await _pump(t, 2500);
        }
        RescueObject? used;
        if (r.scene.switchNear) {
          await _pullSwitch(t);
        } else {
          final k = r.objects.indexWhere((o) => o.safe);
          used = r.objects[k];
          await _dragOnto(t, k, i.isEven ? BodyZone.arm : BodyZone.leg);
        }
        expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'scene $i');
        expect(find.byType(FreezeFrame), findsNothing, reason: 'scene $i');
        await _pump(t, 2500);
        expect(find.text(used == null ? RescueLines.whySwitch : RescueLines.whyPush), findsWidgets, reason: 'scene $i');
        await _pickRight(t, RescueLines.whyRight(r.scene, used));
        await _pump(t, i == 2 ? 6000 : 3500);
      }
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['1.7/do/0'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['1.7/do/0'], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(RescueLines.caughtCall), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a push on the chest is a slip with its card; the scene stays; then the leg frees him', (t) async {
      final seed = _seedWhere((d) => !d.rounds[0].scene.switchNear && d.callScene != 0);
      final deal = dealRescues(math.Random(seed));
      final c = await _open(t, seed);
      final k = deal.rounds[0].objects.indexWhere((o) => o.safe);
      await _dragOnto(t, k, BodyZone.chest);
      await _pump(t, 600);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(find.text(MistakeLines.readLesson), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _dragOnto(t, k, BodyZone.leg);
      await _pump(t, 2500);
      expect(find.text(RescueLines.whyPush), findsWidgets);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, RescueMistakes.chestHead.key);
      await _close(t, c);
    });

    testWidgets('three dry pushes beside the switch: three slips strike the level out', (t) async {
      final seed = _seedWhere((d) => d.rounds[0].scene.switchNear && d.callScene != 0);
      final deal = dealRescues(math.Random(seed));
      final c = await _open(t, seed);
      final k = deal.rounds[0].objects.indexWhere((o) => o.safe);
      for (var i = 0; i < 3; i++) {
        await _dragOnto(t, k, BodyZone.arm);
        await _pump(t, 700);
        if (i < 2) {
          expect(find.text(MistakeLines.slipHead), findsOneWidget);
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      expect(find.byType(StruckOutCard), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.map((m) => m.key), contains(RescueMistakes.switchNear.key));
      await _close(t, c);
    });

    testWidgets('the clock runs out: the late slip, then the next scene comes by itself', (t) async {
      final seed = _seedWhere((d) => d.callScene != 0);
      final c = await _open(t, seed, pack: const RescuePack(id: 'do_1_7_a', titleBn: RescueLines.title, seconds: 3));
      await _pump(t, 3600);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, RescueMistakes.late.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.text(RescueLines.secs(3)), findsOneWidget, reason: 'a fresh countdown for the next scene');
      await _close(t, c);
    });

    testWidgets('a tap on him is the deadly touch: the scene freezes first, then the card', (t) async {
      final c = await _open(t, idleSeed);
      await t.tapAt(t.getCenter(find.byKey(const ValueKey('zone-leg'))));
      await _pump(t, 400);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byKey(const ValueKey('zap')), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, RescueMistakes.touch.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('a wet stick on him is deadly too', (t) async {
      final seed = _seedWhere((d) => d.callScene != 0 && d.rounds[0].objects.contains(RescueObject.wetStick));
      final deal = dealRescues(math.Random(seed));
      final c = await _open(t, seed);
      await _dragOnto(t, deal.rounds[0].objects.indexOf(RescueObject.wetStick), BodyZone.leg);
      await _pump(t, 300);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(c.read(gameSaveProvider).mistakes.single.key, RescueMistakes.wetStick.key);
      await _close(t, c);
    });

    testWidgets('his scene done before he came: he peeps in on the next one (once a play)', (t) async {
      final seed = _seedWhere((d) => d.callScene == 0 && d.rounds[0].scene.switchNear);
      final deal = dealRescues(math.Random(seed));
      final c = await _open(t, seed);
      await _pullSwitch(t);
      expect(find.byType(CoworkerPeek), findsNothing);
      await _pump(t, 2500);
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'not over the reason deck');
      await _pickRight(t, RescueLines.whyRight(deal.rounds[0].scene, null));
      await _pump(t, 3500);
      await _pump(t, 3000);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he comes on scene 2');
      await _pickRight(t, RescueLines.coworker.right);
      await _pump(t, 2500);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('listening to him ("হাত দিয়ে টেনে নাও") is the deadly touch: freeze first, then the card', (t) async {
      final seed = _seedWhere((d) => d.callScene == 0);
      final c = await _open(t, seed);
      await _pump(t, 3000);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      final wrong = _onScreen(RescueLines.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, RescueMistakes.touch.key);
      await _close(t, c);
    });
  });
}
