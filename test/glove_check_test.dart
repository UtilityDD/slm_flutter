import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/coworker_moment.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/gesture_hint.dart';
import 'package:slm_flutter/features/game/glove_check.dart';
import 'package:slm_flutter/features/game/helmet_check.dart';
import 'package:slm_flutter/features/game/level_frame.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/reason_proceed.dart';

GloveItem _pool(String id) => gloveCheckPack11.pool.firstWhere((g) => g.id == id);
GloveItem _pinholed(GloveItem g) => g.withFlaw(g.flaws.firstWhere((f) => f.kind == GloveFlawKind.pinhole));

typedef _Deal = ({GloveDeal gloves, List<List<GloveItem>> order});

/// The gloves the page deals for [seed], in the page's tray order.
_Deal _dealFor(int seed) {
  final rng = math.Random(seed);
  final gloves = dealGloves(gloveCheckPack11, rng);
  return (gloves: gloves, order: [for (final r in gloves.rounds) [...r]..shuffle(rng)]);
}

final _trayCards = find.byWidgetPredicate((w) => w.runtimeType.toString() == 'DoTrayCard');

Future<void> _pumpMs(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Finder _semLabel(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);
List<Finder> _shown(List<String> texts) => [
      for (final x in texts)
        if (_semLabel(x).evaluate().isNotEmpty) _semLabel(x),
    ];

const _ctx = LevelContext(
  rungId: '1.1/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '1.1',
  lessonTitleBn: '',
  ladderStep: 3,
  doIndex: 2,
  doCount: 2,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('glove rules: test before you trust', () {
    test('a sound rubber pair is packed only after the air test', () {
      final g = _pool('rubber_orange');
      final untested = judgeGlove(g, GloveChoice.wear, tested: false);
      expect(untested.packs, isFalse);
      expect(untested.wordBn, GloveLines.testFirst);
      expect(untested.leavesTray, isFalse, reason: 'it stays to be tested');
      expect(judgeGlove(g, GloveChoice.wear, tested: true).packs, isTrue);
    });

    test('a pinholed pair sent back untested is a lucky guess, not clean', () {
      final bad = _pinholed(_pool('rubber_cream'));
      final guess = judgeGlove(bad, GloveChoice.reject, tested: false);
      expect(guess.right, isTrue);
      expect(guess.clean, isFalse);
      expect(guess.delta, 0);
      final tested = judgeGlove(bad, GloveChoice.reject, tested: true);
      expect(tested.clean, isTrue);
      expect(tested.delta, 5);
      expect(judgeGlove(bad, GloveChoice.wear, tested: true).right, isFalse);
    });

    test('wrong gloves need no test: send them back', () {
      final cotton = _pool('cotton');
      expect(cotton.rubber, isFalse);
      expect(judgeGlove(cotton, GloveChoice.reject, tested: false).clean, isTrue);
      expect(judgeGlove(cotton, GloveChoice.wear, tested: false).right, isFalse);
    });

    test('a clean play: test, catch, pack three pairs → 100%', () {
      final deal = dealGloves(gloveCheckPack11, math.Random(5));
      final r = GloveRound(deal);
      while (!r.done) {
        if (r.callDue) {
          r.answerCall(heldCheck: true);
          continue;
        }
        for (final g in r.tray.where((g) => g.kind != GloveKind.good)) {
          if (g.rubber) r.markTested(g);
          r.decide(g, GloveChoice.reject);
        }
        final good = r.tray.firstWhere((g) => g.kind == GloveKind.good);
        r.markTested(good);
        r.decide(good, GloveChoice.wear);
      }
      expect(r.packed, hasLength(3));
      expect(r.percent, 100);
      expect(r.caught, isNotEmpty);
    });
  });

  group('glove deal', () {
    test('every round: one sound pair and its pinholed look-alike; fits a phone', () {
      for (var seed = 0; seed < 60; seed++) {
        final d = dealGloves(gloveCheckPack11, math.Random(seed));
        expect(d.rounds, hasLength(3));
        expect([1, 2, 3], contains(d.callBefore), reason: '3 = the helmet station');
        for (final hand in d.rounds) {
          final good = hand.where((g) => g.kind == GloveKind.good).toList();
          expect(good, hasLength(1), reason: 'seed $seed');
          expect(hand.any((g) => g.leaks && g.asset == good.first.asset), isTrue, reason: 'same picture, hidden pinhole');
          expect(hand.any((g) => g.kind == GloveKind.wrong), isTrue);
          expect(hand.length, lessThanOrEqualTo(4));
          expect(hand.map((g) => g.id).toSet(), hasLength(hand.length));
        }
      }
    });

    test('pictures exist and every fault says why', () {
      for (final g in gloveCheckPack11.pool) {
        expect(File(g.asset).existsSync(), isTrue, reason: g.asset);
        if (g.kind != GloveKind.good) expect(g.lineBn, isNotEmpty, reason: g.id);
        for (final f in g.flaws) {
          expect(f.lineBn, isNotEmpty);
          for (final m in f.marks) {
            expect(m.dx, inInclusiveRange(0, 1));
            expect(m.dy, inInclusiveRange(0, 1));
          }
        }
      }
      expect(gloveCheckLines(gloveCheckPack11).every((l) => l.trim().isNotEmpty), isTrue);
    });
  });

  group('air test on screen', () {
    setUp(() {
      final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      for (final c in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global', 'flutter_tts']) {
        m.setMockMethodCallHandler(MethodChannel(c), (_) async => 1);
      }
      ZlFx.setMuted(true);
      SharedPreferences.setMockInitialValues({});
      SpokenOnce.resetForTest();
    });

    testWidgets('hold to puff the glove; a short press asks for more; a pinhole hisses', (t) async {
      t.view.physicalSize = const Size(1080, 2340);
      t.view.devicePixelRatio = 3;
      await t.pumpWidget(ProviderScope(
        child: MaterialApp(home: GloveCheckPage(ctx: _ctx, pack: _packRef, muted: true, seed: 2)),
      ));
        await t.pump(const Duration(milliseconds: 100));
        await waitIntro(t);
      for (var i = 0; i < 60; i++) {
        await t.pump(const Duration(milliseconds: 50));
      }
      expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
      final cards = find.byWidgetPredicate((w) => w.runtimeType.toString() == 'DoTrayCard');
      expect(cards, findsWidgets);

      // Open cards until a rubber pair with a pinhole is in the close-up.
      final deal = dealGloves(gloveCheckPack11, math.Random(2));
      final hasPin = deal.rounds.first.any((g) => g.leaks);
      expect(hasPin, isTrue);
      var found = false;
      for (var i = 0; i < cards.evaluate().length && !found; i++) {
        await t.tap(cards.at(i));
        for (var k = 0; k < 8; k++) {
          await t.pump(const Duration(milliseconds: 50));
        }
        final button = find.text(GloveLines.testButton);
        if (button.evaluate().isEmpty) {
          await t.tapAt(const Offset(20, 120)); // not rubber: put it back
          await t.pump(const Duration(milliseconds: 300));
          continue;
        }
        // A short press is not enough.
        final g1 = await t.startGesture(t.getCenter(button));
        for (var k = 0; k < 4; k++) {
          await t.pump(const Duration(milliseconds: 50));
        }
        await g1.up();
        await t.pump(const Duration(milliseconds: 400));
        expect(find.text(GloveLines.holds), findsNothing);
        expect(find.text(GloveLines.leaks), findsNothing);
        // A long hold completes the test.
        final g2 = await t.startGesture(t.getCenter(button));
        for (var k = 0; k < 24; k++) {
          await t.pump(const Duration(milliseconds: 50)); // frame by frame, like a phone
        }
        await g2.up();
        for (var k = 0; k < 6; k++) {
          await t.pump(const Duration(milliseconds: 50));
        }
        final leaked = find.text(GloveLines.leaks).evaluate().isNotEmpty;
        final held = find.text(GloveLines.holds).evaluate().isNotEmpty;
        expect(leaked || held, isTrue, reason: 'the test always gives an answer');
        found = leaked;
        await t.tapAt(const Offset(20, 120));
        await t.pump(const Duration(milliseconds: 300));
      }
      expect(found, isTrue, reason: 'the pinholed pair hisses on the air test');
      expect(t.takeException(), isNull);

      MascotTalk.reset();
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      t.view.reset();
    });
  });

  group('audit 2026-11-11: neutral replies, booked slips', () {
    test('sending back a sound pair costs a slip with a neutral reply (never "it was fine")', () {
      final g = _pool('rubber_red');
      final untested = judgeGlove(g, GloveChoice.reject, tested: false);
      final tested = judgeGlove(g, GloveChoice.reject, tested: true);
      for (final o in [untested, tested]) {
        expect(o.right, isFalse);
        expect(o.delta, -5);
        expect(o.wordBn, isNot(contains('ঠিক')), reason: o.wordBn);
      }
      expect(untested.wordBn, GloveLines.rejectedGood);
      expect(tested.wordBn, GloveLines.rejectedTested);
      // The air test only finds leaks: its result never calls a pair "fine".
      expect(GloveLines.holds, isNot(contains('ঠিক')));
      // The helmet's twin reply is neutral too.
      final helmet = judgeHelmet(helmetLine, GloveChoice.reject, checks: const {});
      expect(helmet.right, isFalse);
      expect(helmet.wordBn, isNot(contains('ঠিক')));
      expect(helmet.reasonBn, isNot(contains('এটাই নেওয়ার')));
      // Packing a sound helmet unchecked: the card never says it was sound
      // (the helmet goes back next to its look-alike flawed twin).
      final unchecked = judgeHelmet(helmetLine, GloveChoice.wear, checks: const {});
      expect(unchecked.right, isFalse);
      expect(unchecked.reasonBn, HelmetLines.uncheckedCard);
      expect(unchecked.reasonBn, isNot(contains('ঠিক')));
      expect(unchecked.wordBn, isNot(contains('ঠিক')));
    });

    test('glove slips are booked with stable keys and the lesson point', () {
      final good = _pool('rubber_orange');
      final unchecked = gloveMistake(good, judgeGlove(good, GloveChoice.wear, tested: false));
      expect(unchecked.key, '1.1/glove/untested');
      expect(unchecked.textBn, GloveLines.uncheckedCard);
      expect(unchecked.lessonPoint, kGloveLessonPoint);
      expect(gloveMistake(good, judgeGlove(good, GloveChoice.reject, tested: true)).key, '1.1/glove/rejected-good');
      final pin = _pinholed(good);
      final m = gloveMistake(pin, judgeGlove(pin, GloveChoice.wear, tested: false));
      expect(m.key, '1.1/glove/pinhole');
      expect(m.textBn, isNotEmpty);
      expect(m.deadly, isFalse, reason: 'owner decision pending (ladder lists it as deadly)');
      final cut = _pool('cut');
      expect(gloveMistake(cut, judgeGlove(cut, GloveChoice.wear, tested: false)).lessonPoint, kCutGloveLessonPoint);
      expect(gloveMistake(_pool('cotton'), judgeGlove(_pool('cotton'), GloveChoice.wear, tested: false)).key, '1.1/glove/cotton');
      // Listening to the coworker: a slip, never deadly.
      expect(GloveLines.listenMistake.deadly, isFalse);
      expect(HelmetLines.listenMistake.deadly, isFalse);
      expect(gloveCheckLines(gloveCheckPack11), containsAll([GloveLines.listenCard, GloveLines.uncheckedCard, GloveLines.rejectedCard, HelmetLines.listenCard]));
      for (final l in gloveCheckLines(gloveCheckPack11)) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: 'English digits: $l');
      }
    });

    test('the tray sweep stops sit on the cards, side by side, inside the tray', () {
      const tray = Rect.fromLTWH(0, 600, 392, 114);
      for (var n = 1; n <= 4; n++) {
        final cells = gloveTrayCells(tray, n);
        expect(cells, hasLength(n));
        for (var i = 0; i < n; i++) {
          expect(tray.contains(cells[i].center), isTrue);
          if (i > 0) expect(cells[i].left, greaterThanOrEqualTo(cells[i - 1].right));
        }
      }
    });
  });

  group('page (audit 2026-11-11)', () {
    setUp(() {
      final m = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      for (final c in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global', 'flutter_tts']) {
        m.setMockMethodCallHandler(MethodChannel(c), (_) async => 1);
      }
      ZlFx.setMuted(true);
      SharedPreferences.setMockInitialValues({});
      SpokenOnce.resetForTest();
    });
    tearDown(() => GestureHints.debugEnableInTests = false);

    Future<ProviderContainer> open(WidgetTester t, int seed) async {
      t.view.physicalSize = const Size(1080, 2340);
      t.view.devicePixelRatio = 3;
      final c = ProviderContainer();
      await t.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(home: GloveCheckPage(ctx: _ctx, pack: gloveCheckPack11, muted: true, seed: seed)),
      ));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      await _pumpMs(t, 1500);
      return c;
    }

    Future<void> close(WidgetTester t, ProviderContainer c) async {
      MascotTalk.reset();
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      c.dispose();
      t.view.reset();
    }

    Future<void> airTest(WidgetTester t) async {
      final g = await t.startGesture(t.getCenter(find.text(GloveLines.testButton)));
      for (var k = 0; k < 24; k++) {
        await t.pump(const Duration(milliseconds: 50));
      }
      await g.up();
      await _pumpMs(t, 400);
    }

    /// Round 0: test and pack the sound pair, pick the right reason, proceed.
    Future<void> packFirst(WidgetTester t, _Deal d) async {
      final good = d.order[0].indexWhere((g) => g.kind == GloveKind.good);
      await t.tap(_trayCards.at(good));
      await _pumpMs(t, 400);
      await airTest(t);
      await t.tap(find.text('নিয়ে নিন'));
      await waitChoiceDeck(t);
      final right = _shown(GloveLines.whyRight);
      expect(right, hasLength(1));
      await t.tap(right.single, warnIfMissed: false);
      await tapReasonProceed(t);
    }

    testWidgets('three slips: the strike-out card; every glove slip is booked', (t) async {
      const seed = 11;
      final d = _dealFor(seed);
      final c = await open(t, seed);
      final left = [...d.order[0]];
      Future<void> decide(bool Function(GloveItem g) which, String button) async {
        final i = left.indexWhere(which);
        expect(i, isNonNegative);
        await t.tap(_trayCards.at(i));
        await _pumpMs(t, 400);
        await t.tap(find.text(button));
        await _pumpMs(t, 2600);
        if (button == 'নিয়ে নিন' && left[i].kind != GloveKind.good) left.removeAt(i);
      }

      await decide((g) => g.kind == GloveKind.wrong, 'নিয়ে নিন'); // slip 1
      expect(find.byType(StruckOutCard), findsNothing);
      await decide((g) => g.leaks, 'নিয়ে নিন'); // slip 2: packed untested
      expect(find.byType(StruckOutCard), findsNothing);
      await decide((g) => g.kind == GloveKind.good, 'বাদ দিন'); // slip 3
      await _pumpMs(t, 600);
      expect(find.byType(StruckOutCard), findsOneWidget);
      final keys = c.read(gameSaveProvider).mistakes.map((m) => m.key).toSet();
      final wrong = d.order[0].firstWhere((g) => g.kind == GloveKind.wrong);
      expect(keys, containsAll(['1.1/glove/${wrong.id}', '1.1/glove/pinhole', '1.1/glove/rejected-good']));
      expect(c.read(gameSaveProvider).mistakes.every((m) => !m.deadly), isTrue);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('a fast play cannot skip the coworker: the first touch of his round brings him in', (t) async {
      var seed = 0;
      while (_dealFor(seed).gloves.callBefore != 1) {
        seed++;
      }
      final d = _dealFor(seed);
      final c = await open(t, seed);
      await packFirst(t, d);
      // Straight on to the partner's pair, well before his timer (1.2–2.4 s).
      await _pumpMs(t, 700);
      expect(find.byType(CoworkerPeek), findsNothing);
      await t.tap(_trayCards.first, warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 50));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in at the pick');
      expect(find.text(GloveLines.testButton), findsNothing, reason: 'the pair stays on the tray');
      await waitChoiceDeck(t);
      final refuse = _shown(GloveLines.choiceRight);
      expect(refuse, hasLength(1));
      await t.tap(refuse.single, warnIfMissed: false);
      await tapReasonProceed(t);
      await _pumpMs(t, 2500);
      expect(find.byType(CoworkerPeek), findsNothing);
      // Now the pick works.
      final good = d.order[1].indexWhere((g) => g.kind == GloveKind.good);
      await t.tap(_trayCards.at(good));
      await _pumpMs(t, 400);
      expect(find.text(GloveLines.testButton), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('listening to the coworker is a slip: booked, its card, not deadly', (t) async {
      var seed = 0;
      while (_dealFor(seed).gloves.callBefore != 1) {
        seed++;
      }
      final d = _dealFor(seed);
      final c = await open(t, seed);
      await packFirst(t, d);
      await waitChoiceDeck(t);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      final listen = _shown(GloveLines.choiceWrong);
      expect(listen, hasLength(2));
      await t.tap(listen.first, warnIfMissed: false);
      await tapReasonProceed(t);
      await _pumpMs(t, 1500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(GloveLines.listenCard), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, '1.1/glove/listened');
      expect(s.mistakes.single.deadly, isFalse);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pumpMs(t, 800);
      expect(find.byType(MistakeCard), findsNothing);
      expect(find.byType(StruckOutCard), findsNothing);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('gesture hints: a sweep over the tray when idle, then the hold on the air test', (t) async {
      GestureHints.debugEnableInTests = true;
      const seed = 3;
      final d = _dealFor(seed);
      final c = await open(t, seed);
      final scene = find.byWidgetPredicate((w) => w is IdleHint && w.controller != null);
      expect(scene, findsOneWidget);
      await _pumpMs(t, 9000);
      expect(find.byKey(const ValueKey('gesture-hint')), findsOneWidget);
      expect(t.state<IdleHintState>(scene).debugOptions, hasLength(d.order[0].length), reason: 'every card, never one');
      // A touch hides it; open a rubber pair and wait: the hold is shown.
      final rubber = d.order[0].indexWhere((g) => g.rubber);
      await t.tap(_trayCards.at(rubber));
      await _pumpMs(t, 400);
      expect(find.byKey(const ValueKey('gesture-hint')), findsNothing);
      await _pumpMs(t, 9000);
      expect(t.state<IdleHintState>(scene).showing, isTrue);
      expect(t.state<IdleHintState>(scene).debugOptions, isEmpty, reason: 'a hold, not a sweep');
      expect(t.takeException(), isNull);
      await close(t, c);
    });
  });
}

// GloveCheckPage takes a const pack in tests through this alias.
final _packRef = gloveCheckPack11;
