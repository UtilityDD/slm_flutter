// Step 23 কোন আগুনে কী (fire_choose.dart) — the audit fixes of 2026-11-11:
// a fast play cannot skip the coworker, listening to him is a slip, three
// slips strike out, putting back a full extinguisher costs a slip, no word
// on the cards points at the right one, his deck up = the switch is still,
// and the gesture hint shows how to touch (a sweep / a hold), never which.
// The older rules and flows stay in test/fire_test.dart.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/choice_deck.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/coworker_moment.dart';
import 'package:slm_flutter/features/game/fire_choose.dart';
import 'package:slm_flutter/features/game/full_scene_frame.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/gesture_hint.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_frame.dart';
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';
import 'support/reason_proceed.dart';

LevelContext _ctx() => const LevelContext(
      rungId: '1.8/do/0',
      kind: CatalogRungKind.doKind,
      lessonId: '1.8',
      lessonTitleBn: '',
      ladderStep: 23,
      doIndex: 1,
      doCount: 2,
    );

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

/// The first seed whose deal matches [ok].
int _seed(bool Function(FireDeal d) ok) {
  var s = 0;
  while (!ok(dealFires(math.Random(s)))) {
    s++;
  }
  return s;
}

Finder _label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);
Finder _tool(FireTool x) => _label(FireLines.tool(x));

/// The option cards (by their texts) that are on screen.
List<Finder> _onScreen(List<String> texts) => [
      for (final x in texts)
        if (_label(x).evaluate().isNotEmpty) _label(x),
    ];

FireTool _full(FireDeal d) => d.empty == FireTool.dcp ? FireTool.co2 : FireTool.dcp;

void main() {
  group('fire choose rules (audit 2026-11-11)', () {
    test('a full extinguisher put back is a slip (a needless stop); the empty one put back is a catch', () {
      final d = dealFires(math.Random(4));
      final oil = d.fires.indexOf(FireKind.oil);
      final a = FireRun(d)..round = oil;
      expect(a.pick(_full(d)), isNull);
      expect(a.phase, FirePhase.gauge);
      expect(a.useHeld(use: false), FireMistakes.fullBack);
      expect(a.slips, 1);
      expect(a.phase, FirePhase.tool, reason: 'back to the stand');
      expect(a.spent, isNot(contains(_full(d))), reason: 'the full one can still be taken');
      expect(a.pick(_full(d)), isNull);
      expect(a.useHeld(use: true), isNull);
      expect(a.phase, FirePhase.out);
      final b = FireRun(d)..round = oil;
      b.pick(d.empty);
      expect(b.useHeld(use: false), isNull);
      expect(b.slips, 0);
      expect(b.caught, contains(FireLines.caughtGauge));
    });

    test('mistakes: unique keys; only water on oil / the live panel is deadly', () {
      final keys = FireMistakes.all.map((m) => m.key).toSet();
      expect(keys.length, FireMistakes.all.length);
      expect(FireMistakes.all, contains(FireMistakes.fullBack));
      expect([for (final m in FireMistakes.all) if (m.deadly) m], [FireMistakes.waterOil, FireMistakes.waterElectric]);
      expect(FireMistakes.waited.deadly, isFalse, reason: 'listening to the coworker is a slip');
    });

    test('no giveaway words: what the right cards say also stands on a wrong card', () {
      bool onWrong(List<String> wrong, String word) => wrong.any((w) => w.contains(word));
      // The tool just used must not point at the right reason.
      expect(onWrong(FireLines.whyGrassWrong, 'জল'), isTrue);
      expect(onWrong(FireLines.whyGrassWrong, 'ABC'), isTrue);
      expect(onWrong(FireLines.whyGrassWrong, 'ঘাস-কাঠ'), isTrue);
      expect(onWrong(FireLines.whyOilWrong, 'জল'), isTrue);
      expect(onWrong(FireLines.whyOilWrong, 'বালি'), isTrue);
      expect(onWrong(FireLines.whyOilWrong, 'ঢেকে'), isTrue);
      expect(onWrong(FireLines.whySwitchWrong, 'শক'), isTrue);
      expect(onWrong(FireLines.whySwitchWrong, 'বন্ধ'), isTrue);
      // His deck: "নেভাই / এখনই / দেরি / ছোট" are on wrong cards too.
      for (final w in ['নেভাই', 'এখনই', 'দেরি', 'ছোট']) {
        expect(onWrong(FireLines.choiceWrong, w), isTrue, reason: w);
      }
      // The hands actually dealt: no key word on the right card alone.
      for (final k in FireKind.values) {
        for (final used in [null, ...FireTool.values]) {
          for (var s = 0; s < 300; s++) {
            final hand = FireLines.whyDeal(k, used, math.Random(s));
            final right = hand.singleWhere((o) => o.correct).textBn;
            final wrong = [for (final o in hand) if (!o.correct) o.textBn];
            expect(wrong, hasLength(2));
            for (final w in FireLines.whyKeys[k]!) {
              if (right.contains(w)) expect(wrong.any((x) => x.contains(w)), isTrue, reason: '$k/$used seed $s: "$w" only on "$right"');
            }
          }
        }
      }
      // His deck is dealt by the kit (any two wrong cards): each key word of a
      // right card must stand on all but at most one wrong card.
      for (final r in FireLines.choiceRight) {
        for (final w in FireLines.choiceKeys) {
          if (!r.contains(w)) continue;
          final missing = FireLines.choiceWrong.where((x) => !x.contains(w)).length;
          expect(missing, lessThanOrEqualTo(1), reason: '"$w" on "$r" but missing from $missing wrong cards');
        }
      }
      for (var s = 0; s < 300; s++) {
        final hand = dealChoices(FireLines.choiceRight, FireLines.choiceWrong, math.Random(s));
        final right = hand.singleWhere((o) => o.correct).textBn;
        for (final w in FireLines.choiceKeys) {
          if (right.contains(w)) expect(hand.any((o) => !o.correct && o.textBn.contains(w)), isTrue, reason: 'seed $s: "$w" only on "$right"');
        }
      }
      expectSameLength('choice', [...FireLines.choiceRight, ...FireLines.choiceWrong]);
      expectSameLength('oil', [...FireLines.whyOilRight, ...FireLines.whyOilSand, ...FireLines.whyOilWrong]);
      expectSameLength('switch', [...FireLines.whySwitchRight, ...FireLines.whySwitchWrong]);
      expectSameLength('grass', [...FireLines.whyGrassWater, ...FireLines.whyGrassAbc, ...FireLines.whyGrassWrong]);
      expectLibrary('choice', FireLines.choiceRight, FireLines.choiceWrong);
      expectLibrary('grass', FireLines.whyGrassWater, FireLines.whyGrassWrong);
      expectLibrary('switch', FireLines.whySwitchRight, FireLines.whySwitchWrong);
    });

    test('the tool stand is shuffled (no fixed order to learn)', () {
      final orders = {for (var i = 0; i < 16; i++) dealFires(math.Random(i)).tools.map((t) => t.name).join(',')};
      expect(orders.length, greaterThan(4));
    });

    test('his lines are recorded in his voice', () {
      for (final l in FireLines.coworker.recordedLines) {
        expect(LearnVoice.resolve(l, rival: true), isNotNull, reason: l);
      }
    });
  });

  group('fire choose page (audit 2026-11-11)', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final c in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global', 'flutter_tts']) {
      m.setMockMethodCallHandler(MethodChannel(c), (_) async => 1);
    }
    ZlFx.setMuted(true);
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SpokenOnce.resetForTest();
    });
    tearDown(() => GestureHints.debugEnableInTests = false);

    Future<ProviderContainer> open(WidgetTester t, int seed) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      final c = ProviderContainer();
      final nav = GlobalKey<NavigatorState>();
      await t.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
      ));
      unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
          builder: (_) => FireChoosePage(ctx: _ctx(), pack: firePack18, muted: true, seed: seed))));
      await _pump(t, 1500);
      await waitIntro(t);
      return c;
    }

    Future<void> close(WidgetTester t, ProviderContainer c) async {
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      c.dispose();
      t.view.reset();
    }

    Future<void> gotIt(WidgetTester t) async {
      await t.tap(find.text(MistakeLines.gotIt).first);
      await _pump(t, 600);
    }

    testWidgets('a fast play cannot skip the coworker: a tool tapped before he comes waits for him', (t) async {
      final seed = _seed((d) => d.pushRound == 0 && d.fires.first == FireKind.oil);
      final c = await open(t, seed);
      // At once, before his 1.2–2.4 s: the sand would put the fire out.
      expect(find.byType(CoworkerPeek), findsNothing);
      await t.tap(_tool(FireTool.sand), warnIfMissed: false);
      await _pump(t, 300);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in now');
      expect(find.text(FireLines.coworkerLine), findsWidgets);
      await waitChoiceDeck(t);
      expect(_onScreen(FireLines.whyOilRight + FireLines.whyOilSand), isEmpty, reason: 'the fire is not out: no reason deck');
      await t.tap(_onScreen(FireLines.choiceRight).single, warnIfMissed: false);
      await tapReasonProceed(t);
      await _pump(t, 1800);
      expect(find.byType(CoworkerPeek), findsNothing);
      // Now the sand works.
      await t.tap(_tool(FireTool.sand), warnIfMissed: false);
      await _pump(t, 2700);
      expect(_onScreen(FireLines.whyRight(FireKind.oil, FireTool.sand)), hasLength(1), reason: 'the reason deck is up');
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('listening to the coworker is a slip (not deadly); play goes on', (t) async {
      final seed = _seed((d) => d.pushRound == 0 && d.fires.first == FireKind.grass);
      final c = await open(t, seed);
      await _pump(t, 2800);
      await waitChoiceDeck(t);
      final wrong = _onScreen(FireLines.choiceWrong);
      expect(wrong, hasLength(2));
      await t.tap(wrong.first, warnIfMissed: false);
      await tapReasonProceed(t);
      await _pump(t, 1200);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.text(MistakeLines.nearMissHead), findsNothing);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(find.text(FireMistakes.waited.textBn), findsWidgets);
      expect(c.read(gameSaveProvider).mistakes.map((e) => e.key), contains(FireMistakes.waited.key));
      await gotIt(t);
      // The fire still burns; the water works.
      await t.tap(_tool(FireTool.water), warnIfMissed: false);
      await _pump(t, 2700);
      expect(_onScreen(FireLines.whyRight(FireKind.grass, FireTool.water)), hasLength(1));
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('three slips: the level strikes out with the lesson card', (t) async {
      final seed = _seed((d) => d.pushRound != 0 && d.fires.first == FireKind.grass);
      final c = await open(t, seed);
      await t.tap(_tool(FireTool.co2), warnIfMissed: false);
      await _pump(t, 600);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      await gotIt(t);
      await t.tap(_tool(FireTool.sand), warnIfMissed: false);
      await _pump(t, 600);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      await gotIt(t);
      expect(find.byType(StruckOutCard), findsNothing);
      await t.tap(_tool(FireTool.co2), warnIfMissed: false);
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['1.8/do/0'], isNot('cleared'));
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('putting back a full extinguisher costs a slip; it can be taken again', (t) async {
      final seed = _seed((d) => d.pushRound != 0 && d.fires.first == FireKind.oil);
      final d = dealFires(math.Random(seed));
      final c = await open(t, seed);
      await t.tap(_tool(_full(d)), warnIfMissed: false);
      await _pump(t, 500);
      expect(find.text(FireLines.other), findsOneWidget);
      await t.tap(find.text(FireLines.other));
      await _pump(t, 800);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(find.text(FireMistakes.fullBack.textBn), findsWidgets);
      await gotIt(t);
      await t.tap(_tool(_full(d)), warnIfMissed: false);
      await _pump(t, 500);
      expect(find.text(FireLines.use), findsOneWidget, reason: 'the gauge opens again');
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('his choice deck up on the panel: the switch is still (the deck answers him)', (t) async {
      final seed = _seed((d) => d.pushRound == 0 && d.fires.first == FireKind.electrical);
      final c = await open(t, seed);
      await _pump(t, 2800);
      await waitChoiceDeck(t);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      await t.tap(_label(FireLines.switchLabel), warnIfMissed: false);
      await _pump(t, 400);
      expect(find.byType(ChoiceDeck), findsOneWidget, reason: 'he is still waiting for an answer');
      expect(find.byType(CoworkerPeek), findsOneWidget);
      await t.tap(_onScreen(FireLines.choiceRight).single, warnIfMissed: false);
      await tapReasonProceed(t);
      await _pump(t, 1800);
      // After him the switch works.
      await t.tap(_label(FireLines.switchLabel), warnIfMissed: false);
      await _pump(t, 500);
      final d = dealFires(math.Random(seed));
      await t.tap(_tool(_full(d)), warnIfMissed: false);
      await _pump(t, 500);
      expect(find.text(FireLines.use), findsOneWidget, reason: 'power off: the gauge opens');
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('full flow: a tool grabbed on the live push panel brings him (no slip); refuse, switch off, gauge, squeeze, reasons → pass', (t) async {
      // The panel first and his fire: the grab comes before his 1.2–2.4 s.
      final seed = _seed((d) => d.pushRound == 0 && d.fires.first == FireKind.electrical);
      final d = dealFires(math.Random(seed));
      final full = _full(d);
      final c = await open(t, seed);
      for (var i = 0; i < 3; i++) {
        final k = d.fires[i];
        if (i == d.pushRound) {
          // A fast grab while the switch is still ON: he cuts in first, and the
          // grab is not booked as "no power off".
          await t.tap(_tool(full), warnIfMissed: false);
          await _pump(t, 300);
          expect(find.byType(CoworkerPeek), findsOneWidget);
          expect(find.text(MistakeLines.slipHead), findsNothing);
          await waitChoiceDeck(t);
          await t.tap(_onScreen(FireLines.choiceRight).single, warnIfMissed: false);
          await tapReasonProceed(t);
          await _pump(t, 1800);
          expect(find.byType(CoworkerPeek), findsNothing, reason: 'he leaves');
        }
        if (k == FireKind.electrical) {
          await t.tap(_label(FireLines.switchLabel), warnIfMissed: false);
          await _pump(t, 500);
        }
        final pick = switch (k) {
          FireKind.oil => FireTool.sand,
          FireKind.grass => FireTool.water,
          FireKind.electrical => full,
        };
        await t.tap(_tool(pick), warnIfMissed: false);
        await _pump(t, 500);
        if (pick.extinguisher) {
          await t.tap(find.text(FireLines.use));
          await _pump(t, 500);
          final g = await t.startGesture(t.getCenter(find.text(FireLines.squeeze)));
          await _pump(t, 2200);
          await g.up();
          await _pump(t, 300);
        } else {
          await _pump(t, 1200);
        }
        expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'fire $i');
        await waitChoiceDeck(t);
        final right = _onScreen(FireLines.whyRight(k, pick));
        expect(right, hasLength(1), reason: 'one right reason dealt for fire $i');
        await t.tap(right.single, warnIfMissed: false);
        await tapReasonProceed(t);
        await _pump(t, i == 2 ? 5000 : 3500);
      }
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['1.8/do/0'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('water on the oil fire: during the freeze no other tool books a slip', (t) async {
      final seed = _seed((d) => d.pushRound != 0 && d.fires.first == FireKind.oil);
      final c = await open(t, seed);
      await t.tap(_tool(FireTool.water), warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 600));
      expect(find.byType(FreezeFrame), findsOneWidget);
      await t.tap(_tool(FireTool.co2), warnIfMissed: false);
      await t.tap(_tool(FireTool.sand), warnIfMissed: false);
      await _pump(t, 3000);
      expect(find.text(MistakeLines.slipHead), findsNothing);
      expect(find.byType(StruckOutCard), findsNothing);
      expect(c.read(gameSaveProvider).mistakes.where((e) => e.key == FireMistakes.wrongTool.key), isEmpty);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    // Smoke test only: once the fire is out the stand is hidden, so these taps
    // would hit nothing even without the tableBusy guard (in this level no
    // scene control is reachable in the praise window). It checks that the
    // window passes cleanly and the reason deck still comes.
    testWidgets('praise window (smoke): taps where the stand was book nothing; the reason deck still comes', (t) async {
      final seed = _seed((d) => d.pushRound != 0 && d.fires.first == FireKind.grass);
      final c = await open(t, seed);
      final at = t.getCenter(_tool(FireTool.co2));
      await t.tap(_tool(FireTool.water), warnIfMissed: false);
      // The water lands and the fire dies: its ◆ go on the table (praise).
      for (var i = 0; i < 40 && _onScreen(FireLines.whyRight(FireKind.grass, FireTool.water)).isEmpty; i++) {
        await t.tapAt(at);
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'a wrong tool in the praise window is not taken');
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await waitChoiceDeck(t);
      expect(_onScreen(FireLines.whyRight(FireKind.grass, FireTool.water)), hasLength(1));
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('gesture hint: a sweep over every tool while waiting (never one), a hold on the squeeze', (t) async {
      GestureHints.debugEnableInTests = true;
      final seed = _seed((d) => d.pushRound != 0 && d.fires.first == FireKind.oil);
      final d = dealFires(math.Random(seed));
      final c = await open(t, seed);
      IdleHintState hint() => t.state<IdleHintState>(find.descendant(of: find.byType(FullSceneFrame), matching: find.byType(IdleHint)).first);
      expect(hint().showing, isFalse);
      await _pump(t, 9000);
      expect(hint().showing, isTrue, reason: 'stuck at the stand: the hand shows');
      expect(hint().debugOptions, hasLength(4), reason: 'a sweep over all four tools');
      for (var i = 0; i < 20; i++) {
        await t.pump(const Duration(milliseconds: 120));
        final f = hint().debugFrame;
        if (f != null) expect(f.press, 0, reason: 'a sweep never presses a tool');
      }
      // Any touch hides it; the gauge: a sweep over both buttons.
      await t.tap(_tool(_full(d)), warnIfMissed: false);
      await _pump(t, 300);
      expect(hint().showing, isFalse);
      await _pump(t, 9000);
      expect(hint().showing, isTrue);
      expect(hint().debugOptions, hasLength(2), reason: 'both gauge buttons');
      await t.tap(find.text(FireLines.use));
      await _pump(t, 9000);
      // Spraying: the squeeze is the one way on — a hold.
      expect(hint().showing, isTrue);
      await t.pump(const Duration(milliseconds: 1200));
      expect(hint().debugFrame?.ring, isNotNull, reason: 'a hold ring on the squeeze');
      expect(t.takeException(), isNull);
      await close(t, c);
    });
  });
}
