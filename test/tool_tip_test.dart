// Lesson 1.2, কাজ 2 (লম্বা টুলের ডগা): tool choice, reach-or-shutdown, the
// tip's rest, deal variety, fair reason libraries, his voice, and the level in
// the shell (idle perf; a full clean flow with the coworker and the reasons).
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
import 'package:slm_flutter/features/game/distance_spot.dart' show StreetGeo;
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/gesture_hint.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_frame.dart' show StruckOutCard;
import 'package:slm_flutter/features/game/level_juice.dart' show FreezeFrame;
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/rod_pick.dart' show RodRating;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/game/tool_tip.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';
import 'support/reason_proceed.dart';

Offset _kite(KiteRound r) => Offset(250, StreetGeo.y(r.gapM));

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


/// The level opens with the guide (no start button, as level 1): wait for him.
Future<void> _skipIntro(WidgetTester t) => waitIntro(t);

Finder _label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);
List<Finder> _onScreen(List<String> texts) => [
      for (final x in texts)
        if (_label(x).evaluate().isNotEmpty) _label(x),
    ];

/// Taps the one right card on the deck now up (a reason card then waits for
/// এগিয়ে যান; the coworker's deck closes by itself).
Future<void> _pickRight(WidgetTester t, List<String> right) async {
  await waitChoiceDeck(t);
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = _onScreen(right);
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
  await tapReasonProceed(t);
}

/// The first seed whose deal matches [ok].
int _seedWhere(bool Function(KiteDeal d) ok) {
  for (var s = 0;; s++) {
    if (ok(dealKites(math.Random(s)))) return s;
  }
}

/// Pumps in short steps until the scene's hand is up (true) or [maxMs] pass.
Future<bool> _waitHand(WidgetTester t, IdleHintState Function() hint, {int maxMs = 12000}) async {
  for (var ms = 0; ms < maxMs; ms += 50) {
    if (hint().showing) return true;
    await t.pump(const Duration(milliseconds: 50));
  }
  return hint().showing;
}

final _tools = find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'টুল');

/// The level in the shell, past the guide's intro.
Future<ProviderContainer> _open(WidgetTester t, int seed) async {
  t.view.physicalSize = const Size(720, 1600);
  t.view.devicePixelRatio = 2.0;
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
  await _skipIntro(t);
  // The tray's cards have dealt in (a card still flying in sits partly
  // outside the tray and misses a tap) — still long before his 1.2 s timer.
  await _pump(t, 450);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  expect(t.takeException(), isNull);
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

/// Round 1: the hot stick, then its reason — the kite is next.
Future<void> _firstTool(WidgetTester t, KiteDeal d) async {
  await t.tap(_tools.at(d.rounds[0].tools.indexOf(LongTool.hotStick)), warnIfMissed: false);
  await _pump(t, 200);
  await _pickRight(t, ToolTipLines.toolRight);
  await _pump(t, 3000);
}

/// Drags the stick's tip to [to] (design px of the street) and lets go.
Future<void> _dragTipTo(WidgetTester t, Offset to) async {
  final street = t.getRect(_label(ToolTipLines.stickLabel).first);
  final k = street.height / StreetGeo.size.height;
  final start = street.topLeft + const Offset(160, 380) * k;
  final end = street.topLeft + to * k;
  final g = await t.startGesture(start);
  for (var i = 1; i <= 10; i++) {
    await g.moveTo(Offset.lerp(start, end, i / 10)!);
    await t.pump(const Duration(milliseconds: 30));
  }
  await g.up();
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
      expect(b.phase, KitePhase.decide, reason: 'the kite is still to do');
      expect(b.restTip(b.current.distanceM + 0.2), isNull);
      expect(b.decide(reach: true), isNull);

      final c = KiteRun(d);
      for (var i = 0; i < 3; i++) {
        c.pickTool(LongTool.hotStick);
        expect(c.decide(reach: !c.current.inside), isNull);
        c.next();
      }
      expect(c.passed, isTrue);
      expect(c.percent, 100);
    });

    test('the tip resting inside the distance is deadly, outside is not', () {
      final run = KiteRun(dealKites(math.Random(4)))..pickTool(LongTool.hotStick);
      expect(run.restTip(run.current.distanceM + 0.3), isNull);
      expect(run.restTip(run.current.distanceM - 0.1), ToolTipMistakes.tipInside);
      expect(run.ended, isTrue);
    });

    test('reason and choice libraries: same length, big enough; his lines are recorded', () {
      expectSameLength('tool', [...ToolTipLines.toolRight, ...ToolTipLines.toolWrong]);
      expectLibrary('tool', ToolTipLines.toolRight, ToolTipLines.toolWrong);
      expectSameLength('decide', [...ToolTipLines.reachRight, ...ToolTipLines.shutRight, ...ToolTipLines.decideWrong]);
      expectLibrary('reach', ToolTipLines.reachRight, ToolTipLines.decideWrong);
      expectLibrary('shut', ToolTipLines.shutRight, ToolTipLines.decideWrong);
      const c = ToolTipLines.coworker;
      expectSameLength('choice', [...c.right, ...c.wrong]);
      expectLibrary('choice', c.right, c.wrong);
      for (final l in c.recordedLines) {
        expect(LearnVoice.resolve(l, rival: true), isNotNull, reason: l);
      }
    });

    test('no giveaway words: the key words of the right cards also sit on wrong cards', () {
      bool onWrong(List<String> wrong, String w) => wrong.any((x) => x.contains(w));
      for (final w in ['বিদ্যুৎ', 'ফাইবারগ্লাস', 'জুগাড়', 'বাঁশ', 'পিভিসি', 'আর্দ্রতা', 'ফাট']) {
        expect(onWrong(ToolTipLines.toolWrong, w), isTrue, reason: w);
      }
      for (final w in ['বাইরে', 'ভেতরে', 'লক্ষ্মণ', 'নিরাপদ', 'লাইন বন্ধ', 'ডগা']) {
        expect(onWrong(ToolTipLines.decideWrong, w), isTrue, reason: w);
      }
      // His deck: the refusals name the hot stick, and so do some ways to listen.
      for (final w in ['হট স্টিক', 'গাড়ি', 'পরীক্ষিত', 'বাঁশ']) {
        expect(onWrong(ToolTipLines.coworker.wrong, w), isTrue, reason: w);
      }
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
        debugPrint('PERF tool tip ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
        expect(t.takeException(), isNull);
        expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
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
      await _skipIntro(t);
      await _pump(t, 300);
      final tools = _tools;
      for (var i = 0; i < 3; i++) {
        final r = deal.rounds[i];
        if (i == deal.callRound) {
          // He peeps in; the guide asks; refuse him.
          await _pump(t, 3500);
          expect(find.byType(CoworkerPeek), findsOneWidget);
          await _pickRight(t, ToolTipLines.coworker.right);
          await _pump(t, 2500);
        }
        await t.tap(tools.at(r.tools.indexOf(LongTool.hotStick)), warnIfMissed: false);
        await _pump(t, i == 0 ? 3500 : 800);
        if (i == 0) {
          await _pickRight(t, ToolTipLines.toolRight);
          await _pump(t, 3000);
        }
        if (r.inside) {
          await t.tap(find.text(ToolTipLines.shutdown));
        } else {
          await _dragTipTo(t, _kite(r));
        }
        await _pump(t, 3500);
        expect(find.text(MistakeLines.slipHead), findsNothing);
        await _pickRight(t, r.inside ? ToolTipLines.shutRight : ToolTipLines.reachRight);
        await _pump(t, i == 2 ? 6000 : 3500);
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

    testWidgets('a fast pick on his round waits for him: he comes, then the pick works', (t) async {
      final seed = _seedWhere((d) => d.callRound == 0);
      final d = dealKites(math.Random(seed));
      final c = await _open(t, seed);
      // Long before his timer: the hot stick at once — twice, fast.
      final stick = t.getCenter(_tools.at(d.rounds[0].tools.indexOf(LongTool.hotStick)));
      await t.tapAt(stick);
      await t.pump();
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in now');
      expect(_tools, findsNothing, reason: 'the tray is away while he is on');
      await t.tapAt(stick);
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text(ToolTipLines.shutdown), findsNothing, reason: 'the pick did not go through');
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'a second fast tap does not answer him');
      // Beat 2: the guide asks, his deck rises (not the tool's reason); refuse him.
      await waitChoiceDeck(t);
      expect(_onScreen(ToolTipLines.toolRight), isEmpty);
      expect(_onScreen(ToolTipLines.coworker.right), hasLength(1));
      await _pickRight(t, ToolTipLines.coworker.right);
      await _pump(t, 2500);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      // Now the pick works: the ◆ waits, then the tool's reason deck.
      await t.tap(_tools.at(d.rounds[0].tools.indexOf(LongTool.hotStick)), warnIfMissed: false);
      await _pump(t, 200);
      await waitChoiceDeck(t);
      expect(_onScreen(ToolTipLines.toolRight), hasLength(1));
      await _close(t, c);
    });

    testWidgets('beat 1 is his alone: a guide tap stays quiet while he talks, then asks once his deck is up', (t) async {
      CoworkerTiming.debugReadHoldInTests = true;
      addTearDown(() => CoworkerTiming.debugReadHoldInTests = false);
      final seed = _seedWhere((d) => d.callRound == 0);
      final c = await _open(t, seed);
      for (var i = 0; i < 80 && find.byType(CoworkerPeek).evaluate().isEmpty; i++) {
        await t.pump(const Duration(milliseconds: 50));
      }
      expect(find.byType(CoworkerPeek), findsOneWidget);
      expect(find.byType(ChoiceDeck), findsNothing, reason: 'beat 1: he is still talking');
      final guide = find.byKey(const ValueKey('hud-guide'));
      final before = c.read(guideDirectorProvider).line;
      await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
      await t.pump(const Duration(milliseconds: 200));
      expect(c.read(guideDirectorProvider).line, before, reason: 'the guide never talks over his push');
      expect(find.byType(ChoiceDeck), findsNothing);
      await waitChoiceDeck(t, maxMs: 20000);
      expect(find.byType(ChoiceDeck), findsOneWidget);
      await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
      await _pump(t, 300);
      expect(ToolTipLines.coworker.asks, contains(c.read(guideDirectorProvider).line), reason: 'beat 2: the guide asks');
      await _pickRight(t, ToolTipLines.coworker.right);
      await _pump(t, 2500);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('praise window: no শাটডাউন button while the ◆ waits on the table', (t) async {
      final seed = _seedWhere((d) => d.callRound != 0);
      final d = dealKites(math.Random(seed));
      final c = await _open(t, seed);
      await t.tap(_tools.at(d.rounds[0].tools.indexOf(LongTool.hotStick)), warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 150));
      expect(find.byType(ChoiceDeck), findsNothing, reason: 'still the praise window');
      expect(find.text(ToolTipLines.shutdown), findsNothing, reason: 'no control in the praise window');
      await _pickRight(t, ToolTipLines.toolRight);
      await _pump(t, 3000);
      expect(find.text(ToolTipLines.shutdown), findsOneWidget, reason: 'after the reason, the kite');
      await _close(t, c);
    });

    testWidgets('three slips strike out: needless shutdowns on an outside kite', (t) async {
      final seed = _seedWhere((d) => d.callRound != 0 && !d.rounds[0].inside);
      final d = dealKites(math.Random(seed));
      final c = await _open(t, seed);
      await _firstTool(t, d);
      for (var i = 0; i < 3; i++) {
        await t.tap(find.text(ToolTipLines.shutdown));
        await _pump(t, 1500);
        if (i < 2) {
          expect(find.text(MistakeLines.slipHead), findsOneWidget, reason: 'slip ${i + 1}');
          expect(find.byType(StruckOutCard), findsNothing);
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.text(ToolTipLines.shutdown), findsNothing, reason: 'nothing more to play');
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['1.2/do/1'], isNot('cleared'));
      expect(s.mistakes.map((m) => m.key), contains(ToolTipMistakes.needlessShutdown.key));
      await _close(t, c);
    });

    testWidgets('listening to him (the dry bamboo) is deadly: freeze, then the card', (t) async {
      final seed = _seedWhere((d) => d.callRound == 0);
      final c = await _open(t, seed);
      await _pump(t, 3500);
      await waitChoiceDeck(t);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      final wrong = _onScreen(ToolTipLines.coworker.wrong);
      expect(wrong, hasLength(2));
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 600);
      expect(find.byType(FreezeFrame), findsOneWidget, reason: 'the street freezes first');
      await _pump(t, 4000);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('gesture hints: a sweep over the tools; on the kite a sweep over both ways; taps on the street call it', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
      const hand = ValueKey('gesture-hint');
      final seed = _seedWhere((d) => d.callRound != 0 && !d.rounds[0].inside);
      final d = dealKites(math.Random(seed));
      final c = await _open(t, seed);
      final sceneHint = find.byType(IdleHint).first;
      IdleHintState hint() => t.state<IdleHintState>(sceneHint);

      // Idle at the tray: the hand glides over all three tools, presses none.
      // (Under "remove animations" the still hand's controller runs at
      // Flutter's reduced speed, so it is up only briefly: poll for it.)
      expect(await _waitHand(t, hint), isTrue, reason: 'idle at the tray calls the hand');
      expect(find.byKey(hand), findsOneWidget);
      expect(hint().debugOptions, hasLength(3), reason: 'every tool, the same way');
      expect(find.text(ToolTipLines.shutdown), findsNothing, reason: 'a hint picks nothing');

      // On the kite: confused taps on the street call the hand at once, a
      // sweep over the stick's tip and the শাটডাউন button (both ways).
      await _firstTool(t, d);
      expect(find.byKey(hand), findsNothing);
      final street = t.getRect(_label(ToolTipLines.stickLabel).first);
      final k = street.height / StreetGeo.size.height;
      for (var i = 0; i < 3; i++) {
        await t.tapAt(street.topLeft + const Offset(60, 170) * k);
        await t.pump();
        if (i < 2) {
          expect(hint().showing, isFalse, reason: 'tap ${i + 1}: not yet');
          await t.pump(const Duration(milliseconds: 200));
        }
      }
      expect(find.byKey(hand), findsOneWidget, reason: 'confused taps call the hand');
      final opts = hint().debugOptions;
      expect(opts, hasLength(2));
      final kiteLocal = street.topLeft + _kite(d.rounds[0]) * k - t.getTopLeft(sceneHint);
      for (final r in opts) {
        expect(r.contains(kiteLocal), isFalse, reason: 'never on the kite');
      }
      expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'taps on nothing cost nothing');
      expect(c.read(gameSaveProvider).mistakes, isEmpty);

      // A card is up: no scene hand.
      await t.tap(find.text(ToolTipLines.shutdown));
      await _pump(t, 1500);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(await _waitHand(t, hint, maxMs: 10000), isFalse, reason: 'no scene hint over the mistake card');
      expect(hint().shows, 0);
      await _close(t, c);
    });
  });
}
