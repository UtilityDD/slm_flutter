// Lesson 1.8 (মাঠে আগুন): fire-class rules with the gauge, PASS order and
// standing place; both levels in the shell (idle perf; full flows).
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/choice_deck.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/fire_choose.dart';
import 'package:slm_flutter/features/game/fire_pass.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/order_steps.dart';
import 'package:slm_flutter/features/game/scene_kit.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/ai_lineman_guide.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';

LevelContext _ctx(int doIndex) => LevelContext(
      rungId: '1.8/do/${doIndex - 1}',
      kind: CatalogRungKind.doKind,
      lessonId: '1.8',
      lessonTitleBn: '',
      ladderStep: 22 + doIndex,
      doIndex: doIndex,
      doCount: 2,
    );

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

FireRun _runAt(FireKind k, {int seed = 1}) {
  final d = dealFires(math.Random(seed));
  return FireRun(d)..round = d.fires.indexOf(k);
}


/// The level opens with the guide (no start button, as level 1): wait for him.
Future<void> _skipIntro(WidgetTester t) => waitIntro(t);

/// The option cards (by their texts) that are on screen.
List<Finder> _onScreen(List<String> texts) => [
      for (final x in texts)
        if (find.byWidgetPredicate((w) => w is Semantics && w.properties.label == x).evaluate().isNotEmpty)
          find.byWidgetPredicate((w) => w is Semantics && w.properties.label == x),
    ];

void main() {
  group('fire rules', () {
    test('water on oil or electrical is deadly; on grass it is right', () {
      final oil = _runAt(FireKind.oil);
      expect(oil.pick(FireTool.water), FireMistakes.waterOil);
      final el = _runAt(FireKind.electrical)
        ..phase = FirePhase.tool;
      expect(el.pick(FireTool.water), FireMistakes.waterElectric);
      final grass = _runAt(FireKind.grass);
      expect(grass.pick(FireTool.water), isNull);
      expect(grass.phase, FirePhase.out);
    });

    test('tools by class; electrical asks for power-off first', () {
      expect(FireTool.sand.fits(FireKind.oil), isTrue);
      expect(FireTool.sand.fits(FireKind.electrical), isFalse);
      expect(FireTool.co2.fits(FireKind.grass), isFalse);
      expect(FireTool.dcp.fits(FireKind.grass), isTrue);
      final el = _runAt(FireKind.electrical);
      expect(el.phase, FirePhase.power);
      expect(el.power(off: false), FireMistakes.noPowerOff);
      expect(el.phase, FirePhase.tool);
      expect(el.pick(FireTool.sand), FireMistakes.wrongTool);
    });

    test('panel still live: a tool grabbed is a slip and the power must still go off; water is deadly', () {
      final el = _runAt(FireKind.electrical);
      expect(el.grabLive(FireTool.co2), FireMistakes.noPowerOff);
      expect(el.phase, FirePhase.power, reason: 'the switch is still ON');
      expect(el.slips, 1);
      expect(el.power(off: true), isNull);
      expect(el.phase, FirePhase.tool);
      final el2 = _runAt(FireKind.electrical);
      expect(el2.grabLive(FireTool.water), FireMistakes.waterElectric);
      expect(el2.deadly, isNotNull);
    });

    test('the reason pays the table; after a wrong reason burned it, a right one pays 5', () {
      expect(whyPayout(pending: 30, retried: false), 30);
      expect(whyPayout(pending: 0, retried: true), 5);
      expect(whyPayout(pending: 0, retried: false), 0);
    });

    test('grass: water or ABC powder, never CO2 (IS 2190 cl. 10.1, Table 3)', () {
      expect(FireTool.water.fits(FireKind.grass), isTrue);
      expect(FireTool.dcp.fits(FireKind.grass), isTrue);
      expect(FireTool.co2.fits(FireKind.grass), isFalse);
      expect(FireLines.tool(FireTool.dcp), contains('ABC'));
      for (final k in FireKind.values) {
        for (final used in [null, ...FireTool.values]) {
          final deal = FireLines.whyDeal(k, used, math.Random(k.index * 7 + (used?.index ?? 9)));
          expect(deal.length, 3);
          expect(deal.where((o) => o.correct).length, 1, reason: '$k/$used: one right reason');
          expect(deal.map((o) => o.textBn).toSet().length, 3, reason: 'three different options');
        }
      }
      // Grass put out with ABC powder: the right reason is about ABC.
      expect(FireLines.whyRight(FireKind.grass, FireTool.dcp).every((r) => r.contains('ABC')), isTrue);
    });

    test('option libraries: big enough not to repeat, all about the same length (no guessing by length)', () {
      void sameLength(String name, List<String> all) {
        final lens = all.map((t) => t.length).toList()..sort();
        expect(lens.last / lens.first, lessThanOrEqualTo(1.3), reason: '$name: lengths ${lens.first}..${lens.last}');
      }

      sameLength('choice', [...FireLines.choiceRight, ...FireLines.choiceWrong]);
      sameLength('oil', [...FireLines.whyOilRight, ...FireLines.whyOilSand, ...FireLines.whyOilWrong]);
      sameLength('switch', [...FireLines.whySwitchRight, ...FireLines.whySwitchWrong]);
      sameLength('grass', [...FireLines.whyGrassWater, ...FireLines.whyGrassAbc, ...FireLines.whyGrassWrong]);
      expect(FireLines.choiceWrong.length, greaterThanOrEqualTo(5));
      for (final k in FireKind.values) {
        expect(FireLines.whyWrong(k).length, greaterThanOrEqualTo(5));
      }
      // Different plays deal different sets.
      final sets = {for (var i = 0; i < 12; i++) FireLines.whyDeal(FireKind.oil, FireTool.sand, math.Random(i)).map((o) => o.textBn).toSet().join('|')};
      expect(sets.length, greaterThan(4));
    });

    test('the gauge: an empty extinguisher is a slip if used, a catch if put back', () {
      final d = dealFires(math.Random(4));
      final oil = d.fires.indexOf(FireKind.oil);
      final a = FireRun(d)..round = oil;
      a.pick(d.empty);
      expect(a.phase, FirePhase.gauge);
      expect(a.useHeld(use: true), FireMistakes.empty);
      expect(a.spent, contains(d.empty));
      final b = FireRun(d)..round = oil;
      b.pick(d.empty);
      expect(b.useHeld(use: false), isNull);
      expect(b.caught, contains(FireLines.caughtGauge));
      final good = d.empty == FireTool.dcp ? FireTool.co2 : FireTool.dcp;
      b.pick(good);
      expect(b.useHeld(use: true), isNull);
      expect(b.phase, FirePhase.out);
    });
  });

  group('PASS rules', () {
    test('order P-A-S-S; the right place depends on the wind', () {
      final r = OrderRun(passOrderRounds());
      expect(r.tap(PassIds.squeeze).mistake, PassMistakes.order);
      for (final c in passCards) {
        expect(r.tap(c.id).kind, OrderTapKind.ok);
      }
      expect(r.done, isTrue);
      final rounds = dealPass(math.Random(3));
      expect(rounds[0].windFromLeft, isNot(rounds[1].windFromLeft));
      expect(rounds.map((x) => x.kind).toSet().length, 2);
    });
  });


  group('juice rules', () {
    test('combo: ×2 after two clean moves, ×3 after four; a miss resets', () {
      final c = Combo();
      expect(c.hit(), (1, false));
      expect(c.hit(), (1, true));
      expect(c.mult, 2);
      c.hit();
      expect(c.hit(), (2, true));
      expect(c.mult, 3);
      c.miss();
      expect(c.mult, 1);
    });

    test('stars: 1 passed, 2 no strikes, 3 no strikes and quick', () {
      expect(starsFor(passed: false, strikes: 0, quick: true), 0);
      expect(starsFor(passed: true, strikes: 1, quick: true), 1);
      expect(starsFor(passed: true, strikes: 0, quick: false), 2);
      expect(starsFor(passed: true, strikes: 0, quick: true), 3);
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

    for (final which in ['choose', 'pass']) {
      for (final reduce in [false, true]) {
        testWidgets('$which waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
          t.view.physicalSize = const Size(720, 1600);
          t.view.devicePixelRatio = 2.0;
          t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
          await t.pumpWidget(ProviderScope(
            child: MaterialApp(
              home: which == 'choose'
                  ? FireChoosePage(ctx: _ctx(1), pack: firePack18, muted: true, seed: 2)
                  : FirePassPage(ctx: _ctx(2), pack: passPack18, muted: true, seed: 2),
            ),
          ));
        await t.pump(const Duration(milliseconds: 100));
        await waitIntro(t);
          // The guide (the app's mascot) ends its breath lap up to 6 s after a
          // line, then rests — measure the idle wait after that, as level 1 does.
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
          debugPrint('PERF fire $which ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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

    Future<ProviderContainer> open(WidgetTester t, Widget page) async {
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
      return c;
    }

    Future<void> close(WidgetTester t, ProviderContainer c) async {
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      c.dispose();
      t.view.reset();
    }


    testWidgets('guide first: full screen, the fire and "now", then the scene', (t) async {
      const seed = 5;
      final d = dealFires(math.Random(seed));
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      final c = ProviderContainer();
      final nav = GlobalKey<NavigatorState>();
      await t.pumpWidget(UncontrolledProviderScope(container: c, child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox()))));
      unawaited(nav.currentState!.push(MaterialPageRoute<bool>(builder: (_) => FireChoosePage(ctx: _ctx(1), pack: firePack18, muted: true, seed: seed))));
      await _pump(t, 1200);
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text(FireLines.alarmFirst(d.fires.first)), findsWidgets);
      // No pointing tour ("এটা? এটা?").
      expect(find.byType(GuidedTour), findsNothing);
      // It leaves by itself once the line has been said.
      await _pump(t, 12000);
      expect(find.byType(GuideIntro), findsNothing);
      expect(find.byWidgetPredicate((w) => w is Semantics && w.properties.label == FireLines.tool(FireTool.sand)), findsOneWidget);
      expect(t.takeException(), isNull);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      c.dispose();
      t.view.reset();
    });

    testWidgets('panel: a tool grabbed while the switch is ON is a slip; switch it off, then it works', (t) async {
      var seed = 0;
      while (true) {
        final d = dealFires(math.Random(seed));
        if (d.fires.first == FireKind.electrical && d.pushRound != 0) break;
        seed++;
      }
      final d = dealFires(math.Random(seed));
      final c = await open(t, FireChoosePage(ctx: _ctx(1), pack: firePack18, muted: true, seed: seed));
      Finder tool(FireTool x) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == FireLines.tool(x));
      final full = d.empty == FireTool.dcp ? FireTool.co2 : FireTool.dcp;
      await t.tap(tool(full), warnIfMissed: false);
      await _pump(t, 600);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt).first);
      await _pump(t, 600);
      final sw = find.byWidgetPredicate((w) => w is Semantics && w.properties.label == FireLines.switchLabel);
      await t.tap(sw, warnIfMissed: false);
      await _pump(t, 600);
      await t.tap(tool(full), warnIfMissed: false);
      await _pump(t, 500);
      expect(find.text(FireLines.use), findsOneWidget, reason: 'the gauge opens once the power is off');
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('water on the oil fire: the scene freezes first, then the card', (t) async {
      var seed = 0;
      while (true) {
        final d = dealFires(math.Random(seed));
        if (d.fires.first == FireKind.oil && d.pushRound != 0) break;
        seed++;
      }
      final c = await open(t, FireChoosePage(ctx: _ctx(1), pack: firePack18, muted: true, seed: seed));
      final water = find.byWidgetPredicate((w) => w is Semantics && w.properties.label == FireLines.tool(FireTool.water));
      await t.tap(water, warnIfMissed: false);
      await _pump(t, 600);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsNothing, reason: 'the card waits for the freeze');
      await _pump(t, 2400);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('the coworker peeps in; the guide (not he) asks the choice; tap the guide: the task again', (t) async {
      var seed = 0;
      while (true) {
        final d = dealFires(math.Random(seed));
        if (d.pushRound == 0 && d.fires.first == FireKind.grass) break;
        seed++;
      }
      final c = await open(t, FireChoosePage(ctx: _ctx(1), pack: firePack18, muted: true, seed: seed));
      // Tap the guide before he comes: the task, then the task another way.
      final g = t.getRect(find.byType(AiLinemanGuide).last);
      // The sprite sits at the bottom right (the bubble is above it).
      final sprite = Offset(g.right - 30, g.bottom - 30);
      await t.tapAt(sprite);
      await _pump(t, 200);
      final first = c.read(guideDirectorProvider).line;
      expect(FireLines.tapTool, contains(first));
      await t.tapAt(sprite);
      await _pump(t, 200);
      final second = c.read(guideDirectorProvider).line;
      expect(FireLines.tapTool, contains(second));
      expect(second, isNot(first), reason: 'a different way each time');
      await _pump(t, 2800);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      expect(find.text(FireLines.coworkerLine), findsOneWidget);
      // The guide puts it to the player, with the answers beside him.
      expect(FireLines.choiceAsk, contains(c.read(guideDirectorProvider).line));
      expect(find.byType(ChoiceDeck), findsOneWidget);
      expect(_onScreen(FireLines.choiceRight + FireLines.choiceWrong).length, 3, reason: 'three options dealt');
      await t.tap(_onScreen(FireLines.choiceRight).single, warnIfMissed: false);
      await _pump(t, 1800);
      expect(find.byType(CoworkerPeek), findsNothing);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('choose flow: refuse to wait, switch off, read the gauge, right tool, right reason each fire → pass', (t) async {
      const seed = 5;
      final d = dealFires(math.Random(seed));
      final c = await open(t, FireChoosePage(ctx: _ctx(1), pack: firePack18, muted: true, seed: seed));
      Finder tool(FireTool x) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == FireLines.tool(x));
      Finder label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);
      for (var i = 0; i < 3; i++) {
        if (i == d.pushRound) {
          // The careless coworker peeks in a moment after the fire is seen.
          await _pump(t, 2800);
          expect(find.byType(CoworkerPeek), findsOneWidget);
          expect(find.text(FireLines.coworkerLine), findsOneWidget);
          await t.tap(_onScreen(FireLines.choiceRight).single, warnIfMissed: false);
          await _pump(t, 1800);
          expect(find.byType(CoworkerPeek), findsNothing, reason: 'he leaves');
        }
        final k = d.fires[i];
        if (k == FireKind.electrical) {
          await t.tap(label(FireLines.switchLabel), warnIfMissed: false);
          await _pump(t, 500);
        }
        // Prefer a tool without a gauge where one fits; otherwise the full extinguisher.
        final full = d.empty == FireTool.dcp ? FireTool.co2 : FireTool.dcp;
        final pickTool = switch (k) {
          FireKind.oil => FireTool.sand,
          FireKind.grass => FireTool.water,
          FireKind.electrical => full,
        };
        await t.tap(tool(pickTool), warnIfMissed: false);
        await _pump(t, 500);
        if (pickTool.extinguisher) {
          await t.tap(find.text(FireLines.use));
          await _pump(t, 500);
          // Hands-on: hold the squeeze until the fire is gone (a short squeeze is not enough).
          final squeeze = find.text(FireLines.squeeze);
          expect(squeeze, findsOneWidget);
          final g = await t.startGesture(t.getCenter(squeeze));
          await _pump(t, 600);
          await g.up();
          await _pump(t, 200);
          expect(find.byType(GuideIntro), findsNothing);
          expect(squeeze, findsOneWidget, reason: 'still burning');
          final g2 = await t.startGesture(t.getCenter(squeeze));
          await _pump(t, 1500);
          await g2.up();
          await _pump(t, 500);
        } else {
          // Thrown: it lands and the fire dies by itself.
          await _pump(t, 1200);
        }
        expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'fire $i');
        // "কেন এটা নিলেন?" — the right reason pays the table; then on by itself.
        await _pump(t, 1500);
        final right = _onScreen(FireLines.whyRight(k, pickTool));
        expect(right.length, 1, reason: 'one right reason dealt for fire $i');
        await t.tap(right.single, warnIfMissed: false);
        await _pump(t, i == 2 ? 5000 : 3500);
      }
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['1.8/do/0'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['1.8/do/0'], greaterThanOrEqualTo(2));
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('pass flow: stand upwind, P-A(base)-S-S twice, send for refill → pass', (t) async {
      const seed = 6;
      final c = await open(t, FirePassPage(ctx: _ctx(2), pack: passPack18, muted: true, seed: seed));
      final spots = find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'জায়গা');
      Finder card(String title) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == title);
      final base = find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'গোড়া');
      for (var i = 0; i < 2; i++) {
        await t.tap(spots.first, warnIfMissed: false); // upwind is the first spot
        await _pump(t, 500);
        for (final s in passCards) {
          await t.ensureVisible(card(s.titleBn));
          await t.tap(card(s.titleBn), warnIfMissed: false);
          await _pump(t, 350);
          if (s.id == PassIds.aim) {
            await t.tap(base, warnIfMissed: false);
            await _pump(t, 350);
          }
        }
        expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'fire $i');
        await t.ensureVisible(find.text(PassLines.next));
        await t.tap(find.text(PassLines.next));
        await _pump(t, 600);
      }
      await t.tap(find.text(PassLines.holdOut));
      await _pump(t, 3000);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['1.8/do/1'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(find.text(PassLines.caughtRefill), findsOneWidget);
      expect(t.takeException(), isNull);
      await close(t, c);
    });
  });
}
