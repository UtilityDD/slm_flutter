import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/glove_check.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

GloveItem _pool(String id) => gloveCheckPack11.pool.firstWhere((g) => g.id == id);
GloveItem _pinholed(GloveItem g) => g.withFlaw(g.flaws.firstWhere((f) => f.kind == GloveFlawKind.pinhole));

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
        expect([1, 2], contains(d.callBefore));
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
      for (var i = 0; i < 60; i++) {
        await t.pump(const Duration(milliseconds: 50));
      }
      expect(find.text('পাঠ 1.1 · কাজ 2/2'), findsOneWidget);
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
}

// GloveCheckPage takes a const pack in tests through this alias.
final _packRef = gloveCheckPack11;
