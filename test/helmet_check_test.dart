// Step 3's helmet station (lesson 1.1, after the gloves): the shelf deal, the
// three looks (a crack shows only under the torch), packing a bad helmet is a
// slip with its card, the libraries are fair, a full play through the gloves
// and the helmet clears, and the station waits quietly.
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slm_flutter/features/game/choice_deck.dart';
import 'package:slm_flutter/features/game/content_catalog.dart';
import 'package:slm_flutter/features/game/do_parts.dart';
import 'package:slm_flutter/features/game/coworker_moment.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/glove_check.dart';
import 'package:slm_flutter/features/game/helmet_check.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_frame.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/ai_lineman_guide.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';

const _ctx = LevelContext(rungId: '1.1/do/1', kind: CatalogRungKind.doKind, lessonId: '1.1', lessonTitleBn: '', ladderStep: 3, doIndex: 2, doCount: 2);

final _cards = find.byWidgetPredicate((w) => w.runtimeType.toString() == 'DoTrayCard');
const _all = {HelmetCheck.shell, HelmetCheck.inside, HelmetCheck.strap};

HelmetItem _flawed(HelmetFlawKind k) => helmetLine.withFlaw(helmetFlaws.firstWhere((f) => f.kind == k), crackAt: k == HelmetFlawKind.crack ? helmetCrackSpots.first : null);

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

/// Everything the page deals, in the page's order.
({GloveDeal gloves, List<List<GloveItem>> order, HelmetDeal helmets}) _dealFor(int seed) {
  final rng = math.Random(seed);
  final gloves = dealGloves(gloveCheckPack11, rng);
  final order = [for (final r in gloves.rounds) [...r]..shuffle(rng)];
  return (gloves: gloves, order: order, helmets: dealHelmets(rng));
}

void main() {
  group('helmet rules', () {
    test('the shelf: the sound line helmet, a look-alike with one hidden fault, one or two wrong helmets', () {
      final faults = <HelmetFlawKind>{};
      for (var seed = 0; seed < 80; seed++) {
        final d = dealHelmets(math.Random(seed));
        final good = d.shelf.where((h) => h.kind == HelmetKind.good).toList();
        final bad = d.shelf.where((h) => h.kind == HelmetKind.flawed).toList();
        final wrong = d.shelf.where((h) => h.kind == HelmetKind.wrong).toList();
        expect(good, hasLength(1));
        expect(bad, hasLength(1));
        expect(bad.single.asset, good.single.asset, reason: 'same picture: only the looks tell them apart');
        expect(wrong.length, inInclusiveRange(1, 2));
        expect(d.shelf.length, lessThanOrEqualTo(4));
        expect(d.shelf.map((h) => h.id).toSet(), hasLength(d.shelf.length));
        expect(d.month, inInclusiveRange(1, 12));
        if (bad.single.flaw!.kind == HelmetFlawKind.crack) {
          expect(bad.single.crackAt, isNotNull);
        } else {
          expect(bad.single.crackAt, isNull);
        }
        faults.add(bad.single.flaw!.kind);
      }
      expect(faults, HelmetFlawKind.values.toSet(), reason: 'every fault turns up');
      // Plays differ.
      final a = dealHelmets(math.Random(1)).shelf.map((h) => h.id).join();
      expect([for (var s = 2; s < 12; s++) dealHelmets(math.Random(s)).shelf.map((h) => h.id).join()].any((b) => b != a), isTrue);
    });

    test('a hairline crack shows only under the torch, clearest where the beam rakes across it', () {
      const crack = Offset(0.5, 0.4);
      const aspect = 688 / 621;
      expect(crackVisibility(null, crack, aspect), 0, reason: 'no light, no crack');
      expect(crackVisibility(const Offset(0.05, 0.9), crack, aspect), 0, reason: 'the beam elsewhere');
      final straight = crackVisibility(crack, crack, aspect);
      final raking = crackVisibility(crack.translate(kHelmetBeam * 0.45, 0), crack, aspect);
      expect(straight, greaterThan(0));
      expect(raking, greaterThan(straight), reason: 'the raking edge shows it best');
      expect(crackVisibility(crack.translate(kHelmetBeam * 1.01, 0), crack, aspect), 0);
      // Spotting: only a tap on the crack itself counts; a sound shell has none.
      expect(helmetSpotsCrack(crack, crack, aspect), isTrue);
      expect(helmetSpotsCrack(crack.translate(kHelmetSpotReach * 0.8, 0), crack, aspect), isTrue);
      expect(helmetSpotsCrack(crack.translate(kHelmetSpotReach * 1.3, 0), crack, aspect), isFalse);
      expect(helmetSpotsCrack(crack, null, aspect), isFalse);
      // Every crack spot is reached by a full sweep.
      for (final s in helmetCrackSpots) {
        expect(helmetSweepPoints.any((p) => helmetDist(p, s, aspect) <= kHelmetSweepReach), isTrue, reason: '$s');
      }
    });

    test('a sound helmet is packed only after all three looks', () {
      final half = judgeHelmet(helmetLine, GloveChoice.wear, checks: const {HelmetCheck.shell, HelmetCheck.inside});
      expect(half.right, isFalse);
      expect(half.packs, isFalse);
      expect(half.leavesTray, isFalse);
      expect(half.wordBn, HelmetLines.checkFirst);
      final ok = judgeHelmet(helmetLine, GloveChoice.wear, checks: _all);
      expect(ok.right && ok.clean && ok.packs, isTrue);
      expect(ok.delta, 10);
      expect(judgeHelmet(helmetLine, GloveChoice.reject, checks: _all).right, isFalse);
    });

    test('packing a bad helmet is a slip (never deadly); each fault is found by its own look', () {
      for (final k in HelmetFlawKind.values) {
        final h = _flawed(k);
        final packed = judgeHelmet(h, GloveChoice.wear, checks: _all);
        expect(packed.right, isFalse, reason: '$k');
        expect(packed.leavesTray, isTrue, reason: 'the guide takes it away');
        final m = helmetMistake(h, packed);
        expect(m.deadly, isFalse, reason: '$k: a slip, not deadly');
        expect(m.textBn, h.flaw!.lineBn);
        expect(m.lessonPoint, isNotNull);
        expect(File(m.art).existsSync(), isTrue);
        // Sent back after the right look: clean; without it: a lucky guess.
        final found = judgeHelmet(h, GloveChoice.reject, checks: {h.flaw!.check});
        expect(found.clean, isTrue);
        expect(found.delta, 5);
        final others = _all.difference({h.flaw!.check});
        final guess = judgeHelmet(h, GloveChoice.reject, checks: others);
        expect(guess.right, isTrue);
        expect(guess.clean, isFalse);
        expect(guess.delta, 0);
      }
      expect(_flawed(HelmetFlawKind.crack).flaw!.check, HelmetCheck.shell);
      expect(_flawed(HelmetFlawKind.metal).flaw!.check, HelmetCheck.inside);
      expect(_flawed(HelmetFlawKind.noStamp).flaw!.check, HelmetCheck.inside);
      expect(_flawed(HelmetFlawKind.strap).flaw!.check, HelmetCheck.strap);
    });

    test('a bike helmet or a vented cap: plain to see, sent back without a look; packing it is a slip', () {
      for (final h in helmetWrongs) {
        expect(judgeHelmet(h, GloveChoice.reject, checks: const {}).clean, isTrue);
        final o = judgeHelmet(h, GloveChoice.wear, checks: const {});
        expect(o.right, isFalse);
        expect(helmetMistake(h, o).deadly, isFalse);
      }
    });

    test('the stamp: date counted back from today (never stale), English digits; or none', () {
      final d = dealHelmets(math.Random(3));
      final now = DateTime.now();
      final fresh = helmetStampDate(helmetLine, d, now)!;
      expect(fresh, endsWith('/${now.year - kHelmetFreshAge}'));
      expect(fresh, matches(RegExp(r'^\d\d/\d{4}$')));
      expect(helmetStampDate(helmetLine, d, DateTime(2040, 6)), endsWith('/${2040 - kHelmetFreshAge}'));
      expect(helmetStampDate(_flawed(HelmetFlawKind.noStamp), d, now), isNull);
    });

    test('a clean station: catch the faulty one after its look, pack the sound one after all three', () {
      final r = HelmetRound(dealHelmets(math.Random(9)));
      for (final h in r.shelf.where((h) => h.kind != HelmetKind.good).toList()) {
        if (h.flaw != null) r.markChecked(h, h.flaw!.check);
        expect(r.decide(h, GloveChoice.reject).clean, isTrue);
      }
      final good = r.shelf.single;
      for (final c in HelmetCheck.values) {
        r.markChecked(good, c);
      }
      expect(r.decide(good, GloveChoice.wear).packs, isTrue);
      expect(r.done, isTrue);
      expect(r.clean, r.asked);
      expect(r.caught, isNotEmpty);
    });

    test('libraries: same length, big enough; his helmet push is in his recorded voice; every line set', () {
      expectSameLength('why', [...HelmetLines.whyRight, ...HelmetLines.whyWrong]);
      expectLibrary('why', HelmetLines.whyRight, HelmetLines.whyWrong);
      expectSameLength('choice', [...HelmetLines.choiceRight, ...HelmetLines.choiceWrong]);
      expectLibrary('choice', HelmetLines.choiceRight, HelmetLines.choiceWrong);
      for (final l in HelmetLines.coworker.recordedLines) {
        expect(LearnVoice.resolve(l, rival: true), isNotNull, reason: l);
      }
      expect(helmetCheckLines().every((l) => l.trim().isNotEmpty), isTrue);
      expect(gloveCheckLines(gloveCheckPack11), containsAll(helmetCheckLines()));
      for (final h in [helmetLine, ...helmetWrongs]) {
        expect(File(h.asset).existsSync(), isTrue, reason: h.asset);
      }
      // English digits only on screen.
      for (final l in helmetCheckLines()) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
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

    Future<ProviderContainer> open(WidgetTester t, int seed) async {
      SharedPreferences.setMockInitialValues({});
      SpokenOnce.resetForTest();
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      final c = ProviderContainer();
      await t.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(home: GloveCheckPage(ctx: _ctx, pack: gloveCheckPack11, muted: true, seed: seed)),
      ));
      await t.pump(const Duration(milliseconds: 100));
      await waitIntro(t);
      await _pump(t, 1500);
      return c;
    }

    Future<void> close(WidgetTester t, ProviderContainer c) async {
      MascotTalk.reset();
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      c.dispose();
      t.view.reset();
    }

    /// Wait for the coworker, then refuse him with the right card.
    Future<void> refuseCoworker(WidgetTester t, List<String> right) async {
      for (var i = 0; i < 160 && find.byType(CoworkerPeek).evaluate().isEmpty; i++) {
        await t.pump(const Duration(milliseconds: 50));
      }
      expect(find.byType(CoworkerPeek), findsOneWidget);
      for (var i = 0; i < 100 && _onScreen(right).isEmpty; i++) {
        await t.pump(const Duration(milliseconds: 50));
      }
      final r = _onScreen(right);
      expect(r, hasLength(1));
      await t.tap(r.single, warnIfMissed: false);
      await _pump(t, 2500);
      expect(find.byType(CoworkerPeek), findsNothing);
    }

    Future<void> payReason(WidgetTester t, List<String> right, List<String> wrong) async {
      for (var i = 0; i < 100 && find.byType(ChoiceDeck).evaluate().isEmpty; i++) {
        await t.pump(const Duration(milliseconds: 50));
      }
      expect(find.byType(ChoiceDeck), findsOneWidget, reason: 'the reason deck');
      final r = _onScreen(right);
      expect(r, hasLength(1));
      expect(_onScreen(wrong), hasLength(2));
      await t.tap(r.single, warnIfMissed: false);
      await t.pump();
      await t.tap(find.byKey(const ValueKey('reason-proceed-btn')), warnIfMissed: false);
      await _pump(t, 2500);
      expect(_onScreen([...right, ...wrong]), isEmpty, reason: 'paid');
    }

    /// The torch across every sweep point (the light sits 34 px above the finger).
    Future<void> sweep(WidgetTester t, {Offset? linger}) async {
      final area = find.byKey(const ValueKey('helmet-torch'));
      final tl = t.getTopLeft(area);
      final sz = t.getSize(area);
      Offset at(Offset p) => tl + Offset(p.dx * sz.width, p.dy * sz.height + 34);
      final g = await t.startGesture(at(helmetSweepPoints.first));
      for (final p in [...helmetSweepPoints, ?linger]) {
        for (var k = 1; k <= 6; k++) {
          await g.moveTo(at(p) + Offset(k.isEven ? 1 : -1, 0));
          await t.pump(const Duration(milliseconds: 16));
        }
      }
      await g.up();
      await t.pump(const Duration(milliseconds: 100));
    }

    Future<void> lookInside(WidgetTester t) async {
      await t.tap(find.byKey(const ValueKey('helmet-tab-inside')));
      await _pump(t, 200);
      await t.tap(find.byKey(const ValueKey('helmet-inside')));
      await _pump(t, 800);
    }

    Future<void> tryStrap(WidgetTester t) async {
      await t.tap(find.byKey(const ValueKey('helmet-tab-strap')));
      await _pump(t, 200);
      final area = find.byKey(const ValueKey('helmet-strap'));
      final w = t.getSize(area).width;
      final start = t.getTopLeft(area) + Offset(w * 0.27, t.getSize(area).height * 0.70);
      final g = await t.startGesture(start);
      for (var k = 1; k <= 10; k++) {
        await g.moveTo(start + Offset(w * 0.03 * k, 0));
        await t.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await _pump(t, 1000);
    }

    testWidgets('a full play: three tested pairs, then the helmet looked over and packed → pass, saved', (t) async {
      // A play whose coworker comes at the helmet station.
      var seed = 0;
      while (_dealFor(seed).gloves.callBefore != 3) {
        seed++;
      }
      final d = _dealFor(seed);
      final c = await open(t, seed);

      for (var r = 0; r < 3; r++) {
        final good = d.order[r].indexWhere((g) => g.kind == GloveKind.good);
        await t.tap(_cards.at(good));
        await _pump(t, 400);
        final g = await t.startGesture(t.getCenter(find.text(GloveLines.testButton)));
        for (var k = 0; k < 24; k++) {
          await t.pump(const Duration(milliseconds: 50));
        }
        await g.up();
        await _pump(t, 400);
        expect(find.text(GloveLines.holds), findsWidgets, reason: 'round $r');
        await t.tap(find.text('নিয়ে নিন'));
        await _pump(t, 3000);
        await payReason(t, GloveLines.whyRight, GloveLines.whyWrong);
        await _pump(t, 800);
      }

      // The helmet shelf; the coworker pushes; refuse him.
      expect(_cards, findsNWidgets(d.helmets.shelf.length));
      await refuseCoworker(t, HelmetLines.choiceRight);
      final good = d.helmets.shelf.indexWhere((h) => h.kind == HelmetKind.good);
      await t.tap(_cards.at(good));
      await _pump(t, 600);
      expect(find.byType(HelmetInspect), findsOneWidget);
      // Tap the guide in the close look: the current task again, said another way.
      final coach = find.descendant(of: find.byType(HelmetInspect), matching: find.byType(DoCoachStrip));
      expect(coach, findsOneWidget);
      final said = <String>{};
      for (var k = 0; k < 2; k++) {
        await t.tap(find.descendant(of: coach, matching: find.byType(AiLinemanGuide)), warnIfMissed: false);
        await _pump(t, 200);
        said.add(c.read(guideDirectorProvider).line);
      }
      expect(said, hasLength(2), reason: 'a different way each time');
      expect(said.every((l) => l.contains(HelmetLines.torchTask)), isTrue, reason: '$said');
      await sweep(t);
      await lookInside(t);
      await tryStrap(t);
      expect(find.text(HelmetLines.locked), findsWidgets);
      await t.tap(find.text('নিয়ে নিন'));
      await _pump(t, 2500);
      await payReason(t, HelmetLines.whyRight, HelmetLines.whyWrong);
      await _pump(t, 4000);

      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['1.1/do/1'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['1.1/do/1'], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('helmet station: the crack shows under the torch; packing the cracked one is a slip with its card', (t) async {
      // Skip the gloves: a play whose faulty helmet is cracked, opened at the helmet station.
      var seed = 0;
      while (true) {
        final d = _dealFor(seed);
        if (d.gloves.callBefore != 3 && d.helmets.shelf.any((h) => h.flaw?.kind == HelmetFlawKind.crack)) break;
        seed++;
      }
      final d = _dealFor(seed);
      final c = await open(t, seed);
      for (var r = 0; r < 3; r++) {
        if (r == d.gloves.callBefore) await refuseCoworker(t, GloveLines.choiceRight);
        final good = d.order[r].indexWhere((g) => g.kind == GloveKind.good);
        await t.tap(_cards.at(good));
        await _pump(t, 400);
        final g = await t.startGesture(t.getCenter(find.text(GloveLines.testButton)));
        for (var k = 0; k < 24; k++) {
          await t.pump(const Duration(milliseconds: 50));
        }
        await g.up();
        await _pump(t, 400);
        await t.tap(find.text('নিয়ে নিন'));
        await _pump(t, 3000);
        await payReason(t, GloveLines.whyRight, GloveLines.whyWrong);
        await _pump(t, 800);
      }

      final bad = d.helmets.shelf.indexWhere((h) => h.flaw?.kind == HelmetFlawKind.crack);
      await t.tap(_cards.at(bad));
      await _pump(t, 600);
      final crackPainter = find.byWidgetPredicate((w) => w is CustomPaint && w.painter is HelmetCrackPainter);
      expect(crackPainter, findsOneWidget);
      final painter = t.widget<CustomPaint>(crackPainter).painter! as HelmetCrackPainter;
      expect(crackVisibility(painter.torch.value, painter.at, painter.aspect), 0, reason: 'dark until the torch');
      await sweep(t, linger: d.helmets.shelf[bad].crackAt);
      final swept = t.widget<CustomPaint>(crackPainter).painter! as HelmetCrackPainter;
      expect(swept.shown, isFalse, reason: 'the game never rings the crack for the player');
      // A tap away from the crack: nothing. A tap on it: spotted, ringed, said.
      final area = find.byKey(const ValueKey('helmet-torch'));
      final tl = t.getTopLeft(area);
      final sz = t.getSize(area);
      final at = d.helmets.shelf[bad].crackAt!;
      final away = Offset(at.dx > 0.5 ? 0.15 : 0.85, 0.85);
      await t.tapAt(tl + Offset(away.dx * sz.width, away.dy * sz.height));
      await _pump(t, 200);
      expect((t.widget<CustomPaint>(crackPainter).painter! as HelmetCrackPainter).shown, isFalse);
      await t.tapAt(tl + Offset(at.dx * sz.width, at.dy * sz.height));
      await _pump(t, 300);
      expect((t.widget<CustomPaint>(crackPainter).painter! as HelmetCrackPainter).shown, isTrue, reason: 'the player spotted it');
      expect(find.text(HelmetLines.crackSpotted), findsWidgets);
      expect(find.byKey(const ValueKey('helmet-tab-shell')), findsOneWidget);

      // Pack it anyway: a slip, its card, booked; no freeze.
      await t.tap(find.text('নিয়ে নিন'));
      await _pump(t, 2200);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(find.text(MistakeLines.readLesson), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, '1.1/helmet/crack');
      expect(s.mistakes.single.deadly, isFalse);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_cards, findsNWidgets(d.helmets.shelf.length - 1), reason: 'the cracked one went back');
      expect(find.byType(StruckOutCard), findsNothing);
      expect(t.takeException(), isNull);
      await close(t, c);
    });
  });
}
