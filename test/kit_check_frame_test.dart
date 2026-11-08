// Step 2 (কবচ যাচাই) on the shared level kit: a piece worn right puts its ◆
// on the table and "কেন এটা পরলেন?" follows; the careless coworker peeps in
// before the push slot and the guide asks; the option libraries are fair.
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
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/kit_check.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';

const _ctx = LevelContext(rungId: '1.1/do/0', kind: CatalogRungKind.doKind, lessonId: '1.1', lessonTitleBn: '', ladderStep: 2, doIndex: 1, doCount: 2);

final _cards = find.byWidgetPredicate((w) => w.runtimeType.toString() == 'DoTrayCard');

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

/// The tray order the page shows for [seed] (it deals, then shuffles).
List<KitItem> _trayFor(int seed, KitSlot slot) {
  final rng = math.Random(seed);
  final deal = dealKit(kitCheckPack11, rng);
  final order = [...deal.items]..shuffle(rng);
  return [for (final i in order) if (i.slot == slot) i];
}

/// Pick the sound item of [slot] and wear it.
Future<void> _wearGood(WidgetTester t, int seed, KitSlot slot) async {
  final tray = _trayFor(seed, slot);
  final at = tray.indexWhere((i) => i.kind == KitKind.good);
  await t.tap(_cards.at(at));
  await _pump(t, 500);
  await t.tap(find.text('পরে নিন'));
  await _pump(t, 200);
}

/// Opens the level on a route (so a death can leave it) with a save to read.
Future<ProviderContainer> _open(WidgetTester t, int seed, {bool reduce = false}) async {
  SharedPreferences.setMockInitialValues({});
  SpokenOnce.resetForTest();
  t.view.physicalSize = const Size(784, 1700);
  t.view.devicePixelRatio = 2.0;
  if (reduce) t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
  final c = ProviderContainer();
  final nav = GlobalKey<NavigatorState>();
  await t.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
  ));
  unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
    builder: (_) => KitCheckPage(ctx: _ctx, pack: kitCheckPack11, muted: true, seed: seed),
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
  t.platformDispatcher.clearAccessibilityFeaturesTestValue();
  t.view.reset();
}

/// Picks the item of [slot] that [which] names (the tray is still full) and wears it.
Future<void> _wear(WidgetTester t, int seed, KitSlot slot, bool Function(KitItem) which) async {
  final tray = _trayFor(seed, slot);
  final at = tray.indexWhere(which);
  expect(at, greaterThanOrEqualTo(0));
  await t.tap(_cards.at(at));
  await _pump(t, 500);
  await t.tap(find.text('পরে নিন'));
  await _pump(t, 200);
}

/// Answers "কেন এটা পরলেন?" right.
Future<void> _payReason(WidgetTester t, KitSlot slot) async {
  await _pump(t, 3000);
  final right = _onScreen(KitLines.whyRight(slot));
  expect(right, hasLength(1), reason: 'reason deck for $slot');
  await t.tap(right.single, warnIfMissed: false);
  await _pump(t, 2500);
}

/// Waits for the careless coworker and refuses him.
Future<void> _refuse(WidgetTester t) async {
  for (var i = 0; i < 40 && _onScreen(KitLines.choiceRight).isEmpty; i++) {
    await _pump(t, 250);
  }
  await _pump(t, 1200); // the cards finish dealing in
  final refuse = _onScreen(KitLines.choiceRight);
  expect(refuse, hasLength(1), reason: 'the coworker came and the guide asked');
  await t.tap(refuse.single, warnIfMissed: false);
  await _pump(t, 2000);
}

int _seedWhere(bool Function(KitDeal d) ok) {
  var seed = 0;
  while (!ok(dealKit(kitCheckPack11, math.Random(seed)))) {
    seed++;
  }
  return seed;
}

bool _isNailed(KitItem i) => i.flaw?.kind == KitFlawKind.nail;

void main() {
  test('step 2 libraries: same length, big enough; his lines are in his recorded voice', () {
    for (final s in KitSlot.values) {
      expectSameLength('why ${s.name}', [...KitLines.whyRight(s), ...KitLines.whyWrong(s)]);
      expectLibrary('why ${s.name}', KitLines.whyRight(s), KitLines.whyWrong(s));
    }
    expectSameLength('choice', [...KitLines.choiceRight, ...KitLines.choiceWrong]);
    expectLibrary('choice', KitLines.choiceRight, KitLines.choiceWrong);
    for (final c in [KitLines.coworkerHurry, KitLines.coworkerVan]) {
      for (final l in c.recordedLines) {
        expect(LearnVoice.resolve(l, rival: true), isNotNull, reason: l);
      }
    }
  });

  group('page', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final c in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global', 'flutter_tts']) {
      m.setMockMethodCallHandler(MethodChannel(c), (_) async => 1);
    }
    ZlFx.setMuted(true);

    testWidgets('wear the shirt → ◆ on the table → the reason → the next piece; the coworker before the push slot', (t) async {
      // A play whose push comes before the trousers.
      var seed = 0;
      while (dealKit(kitCheckPack11, math.Random(seed)).callBefore != KitSlot.legs) {
        seed++;
      }
      SharedPreferences.setMockInitialValues({});
      SpokenOnce.resetForTest();
      t.view.physicalSize = const Size(1080, 2340);
      t.view.devicePixelRatio = 3;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: KitCheckPage(ctx: _ctx, pack: kitCheckPack11, muted: true, seed: seed))));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      await _pump(t, 1500);

      await _wearGood(t, seed, KitSlot.torso);
      await _pump(t, 3000);
      expect(find.byType(ChoiceDeck), findsOneWidget, reason: 'the reason deck after a piece worn right');
      final right = _onScreen(KitLines.whyRight(KitSlot.torso));
      expect(right, hasLength(1));
      await t.tap(right.single, warnIfMissed: false);
      await _pump(t, 2500);
      expect(_onScreen([...KitLines.whyTorsoRight, ...KitLines.whyTorsoWrong]), isEmpty, reason: 'the reason was paid');

      // The trousers: the coworker peeps in; the guide asks; refuse him.
      await _pump(t, 1500);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      final refuse = _onScreen(KitLines.choiceRight);
      expect(refuse, hasLength(1));
      await t.tap(refuse.single, warnIfMissed: false);
      await _pump(t, 1800);
      expect(find.byType(CoworkerPeek), findsNothing);
      expect(t.takeException(), isNull);

      MascotTalk.reset();
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      t.view.reset();
    });
    testWidgets('a careful play clears: each piece worn, each reason right, the coworker refused', (t) async {
      final seed = _seedWhere((d) => d.callBefore == KitSlot.feet);
      final c = await _open(t, seed);
      for (final slot in KitSlot.values) {
        if (slot == KitSlot.feet) await _refuse(t);
        await _wear(t, seed, slot, (i) => i.kind == KitKind.good);
        expect(find.byType(FreezeFrame), findsNothing);
        await _payReason(t, slot);
      }
      await _pump(t, 4000);
      expect(find.byType(LevelPassPanel), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['1.1/do/0'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['1.1/do/0'], greaterThan(0));
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a wrong item that is not deadly is a slip: booked, no freeze, the play goes on', (t) async {
      final seed = _seedWhere((d) => d.items.any((i) => i.slot == KitSlot.torso && i.kind == KitKind.wrong && i.deadly == null));
      final slipItem = _trayFor(seed, KitSlot.torso).firstWhere((i) => i.kind == KitKind.wrong && i.deadly == null);
      final c = await _open(t, seed);
      await _wear(t, seed, KitSlot.torso, (i) => i.id == slipItem.id);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.byType(KitDeathView), findsNothing);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 2500);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, '1.1/kit/item/${slipItem.id}');
      expect(s.mistakes.single.deadly, isFalse);
      expect(_cards, findsWidgets, reason: 'the shirt tray is still there to finish');
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('wearing the synthetic shirt: the store freezes grey, the arc flash, then the card', (t) async {
      final seed = _seedWhere((d) => d.items.any((i) => i.id == 'poly'));
      final c = await _open(t, seed);
      await _wear(t, seed, KitSlot.torso, (i) => i.id == 'poly');
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      final view = t.widget<KitDeathView>(find.byType(KitDeathView));
      expect(view.kind, KitDeath.synthetic);
      expect(find.byType(MistakeCard), findsNothing, reason: 'the freeze comes first');
      expect(c.read(gameSaveProvider).mistakes.single.key, KitMistakes.synthetic.key, reason: 'booked at once, before the freeze ends');
      // Back during the freeze opens no exit sheet (leaving there cannot skip the card).
      await t.binding.handlePopRoute();
      await _pump(t, 300);
      expect(find.text('ধাপ ছাড়বেন?'), findsNothing);
      expect(find.byType(KitCheckPage), findsOneWidget);
      await _pump(t, 3000);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget, reason: 'the first deadly mistake in the game is a near-miss');
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, KitMistakes.synthetic.key);
      expect(s.mistakes.single.deadly, isTrue);
      expect(s.rungProgress['1.1/do/0'], isNot('cleared'));

      // The card waits quietly.
      await _pump(t, 6000);
      var frames = 0;
      for (var i = 0; i < 60; i++) {
        if (t.binding.hasScheduledFrame) frames++;
        await t.pump(const Duration(milliseconds: 16));
      }
      expect(frames, lessThan(12), reason: 'no loop runs under the death card');
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a nail in the boot sole: the freeze, the current through the nail, and a death after the near-miss', (t) async {
      final seed = _seedWhere((d) => d.callBefore == KitSlot.legs && d.items.any(_isNailed));
      for (final secondTime in [false, true]) {
        final c = await _open(t, seed);
        if (secondTime) await c.read(gameSaveProvider.notifier).useNearMiss();
        await _wear(t, seed, KitSlot.torso, (i) => i.kind == KitKind.good);
        await _payReason(t, KitSlot.torso);
        await _refuse(t);
        await _wear(t, seed, KitSlot.legs, (i) => i.kind == KitKind.good);
        await _payReason(t, KitSlot.legs);
        await _wear(t, seed, KitSlot.feet, _isNailed);
        await _pump(t, 800);
        expect(find.byType(FreezeFrame), findsOneWidget);
        expect(t.widget<KitDeathView>(find.byType(KitDeathView)).kind, KitDeath.nail);
        expect(find.byType(MistakeCard), findsNothing);
        await _pump(t, 3000);
        expect(find.byType(MistakeCard), findsOneWidget);
        expect(find.text(secondTime ? MistakeLines.deadlyHead : MistakeLines.nearMissHead), findsOneWidget);
        final s = c.read(gameSaveProvider);
        expect(s.mistakes.single.key, KitMistakes.nail.key);
        expect(s.mistakes.single.deadly, isTrue);
        if (secondTime) {
          // "মইয়ে ফিরুন" leaves the level and records the death.
          await t.tap(find.text(MistakeLines.toLadder));
          await _pump(t, 1500);
          expect(find.byType(KitCheckPage), findsNothing);
        }
        expect(t.takeException(), isNull);
        await _close(t, c);
      }
    });

    testWidgets('reduce motion: the deadly freeze still shows and ends on a still frame', (t) async {
      final seed = _seedWhere((d) => d.items.any((i) => i.id == 'poly'));
      final c = await _open(t, seed, reduce: true);
      await _wear(t, seed, KitSlot.torso, (i) => i.id == 'poly');
      await _pump(t, 100);
      expect(find.byType(KitDeathView), findsOneWidget);
      await _pump(t, 2000);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });
  });
}
