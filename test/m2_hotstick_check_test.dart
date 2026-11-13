// Lesson 2.5, কাজ 1 (রডের স্বাস্থ্য): rules of the rod stand (rating vs
// docket, the lab-test sticker, the surface felt by hand, the dry cloth),
// deal variety, fair reason libraries that fit what the player did, his
// lines, and the level in the shell (idle perf; guide first; a full clean
// flow with the coworker, the bamboo aside, the slide, the wipe and the
// reasons; the coworker on a fast play; take dead while the cloth wipes;
// gesture hints; slip cards; deadly freezes; three slips fail).
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
import 'package:slm_flutter/features/game/gesture_hint.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_frame.dart' show FrameLines, StruckOutCard;
import 'package:slm_flutter/features/game/level_juice.dart' show FreezeFrame;
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m2_hotstick_check.dart';
import 'package:slm_flutter/features/game/m2_hotstick_check_world.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/ai_lineman_guide.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';
import 'support/reason_proceed.dart';

const _ctx = LevelContext(
  rungId: '2.5/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '2.5',
  lessonTitleBn: '',
  ladderStep: 40,
  doIndex: 1,
  doCount: 2,
);

final _today = DateTime(2026, 11, 11);

StickDeal _deal(int seed) => dealSticks(math.Random(seed), _today);

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

/// The first seed whose coworker comes on docket [round] (pushing [push], if given).
int _seedCalling(int round, {StickPush? push}) {
  for (var s = 0;; s++) {
    final d = _deal(s);
    if (d.callRound != round) continue;
    if (push != null && stickPushFor(d.rounds[round], const {}, const {}, preferWet: d.preferWet) != push) continue;
    return s;
  }
}

Finder _label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);
List<Finder> _onScreen(List<String> texts) => [
      for (final x in texts)
        if (_label(x).evaluate().isNotEmpty) _label(x),
    ];

Future<void> _pickRight(WidgetTester t, List<String> right) async {
  await waitChoiceDeck(t);
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = _onScreen(right);
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
  await confirmChoice(t);
  // A right reason zooms and waits for এগিয়ে যান; his deck closes by itself.
  await tapReasonProceed(t);
}

/// The first seed whose docket [round]'s good rod is wet, with the coworker
/// on a later docket (so nothing else moves in).
int _seedWet(int round) {
  for (var s = 0;; s++) {
    final d = _deal(s);
    if (d.rounds[round].good.flaw == StickMark.wet && d.callRound > round) return s;
  }
}

HotStick _bad(StickRoundDeal r) => r.rods.firstWhere((x) => x.rating == r.docket.line && kStickDamage.contains(x.flaw));

void main() {
  group('rules', () {
    test('every deal: one good rod per docket, one wet rod per play, 33 kV in the middle, a pushable docket for him', () {
      for (var s = 0; s < 80; s++) {
        final d = _deal(s);
        expect(d.rounds.length, 3);
        var wet = 0;
        for (final r in d.rounds) {
          final good = r.rods.where((x) => x.rating == r.docket.line && (x.flaw == StickMark.none || x.flaw == StickMark.wet));
          expect(good.length, 1);
          wet += r.rods.where((x) => x.flaw == StickMark.wet).length;
          expect(r.rods.any((x) => x.rating != null && x.rating!.index > r.docket.line.index), isFalse, reason: 'never a higher rating');
          expect(r.rods.any((x) => x.rating == r.docket.line && x.flaw != StickMark.none && x.flaw != StickMark.wet), isTrue, reason: 'a bad twin');
          for (final x in r.rods) {
            final overdue = x.due.isBefore(DateTime(_today.year, _today.month));
            expect(overdue, x.flaw == StickMark.overdue, reason: 'the sticker tells the truth');
          }
        }
        expect(wet, 1);
        expect(d.rounds[0].docket.line, StickRating.kv11);
        expect(d.rounds[1].docket.line, StickRating.kv33);
        expect(stickPushFor(d.rounds[d.callRound], const {}, const {}, preferWet: d.preferWet), isNotNull);
      }
    });

    test('a clean play: the good rod each docket (wiped when wet) — each waits for its reason', () {
      final run = HotStickRun(_deal(3));
      for (var i = 0; i < 3; i++) {
        final good = run.current.good;
        if (good.flaw == StickMark.wet) expect(run.wipe(good), isTrue);
        expect(run.take(good).verdict, StickVerdict.right);
        expect(run.tookWiped, good.flaw == StickMark.wet);
        expect(run.shown, isTrue);
        expect(run.round, i, reason: 'the docket moves on only after the reason');
        expect(run.take(run.current.rods.firstWhere((x) => x != good)).verdict, StickVerdict.slip);
        expect(run.slips, 0, reason: 'nothing counts on a decided docket');
        run.next();
      }
      expect(run.passed, isTrue);
      expect(run.percent, 100);
      expect(run.caught, containsAll([HotStickLines.caughtRating, HotStickLines.caughtWet]));
    });

    test('the bamboo, a lower rating and a wet stick not wiped are deadly', () {
      final a = HotStickRun(_deal(1));
      expect(a.take(a.current.rods.firstWhere((x) => x.bamboo)).mistake, HotStickMistakes.bamboo);
      expect(a.ended, isTrue);

      final b = HotStickRun(_deal(1))..round = 1;
      expect(b.take(b.current.rods.firstWhere((x) => x.rating == StickRating.kv11)).mistake, HotStickMistakes.lowRating);
      expect(b.deadly, HotStickMistakes.lowRating);

      final s = List.generate(40, (i) => i).firstWhere((s) => _deal(s).rounds[0].good.flaw == StickMark.wet);
      final c = HotStickRun(_deal(s));
      expect(c.take(c.current.good).mistake, HotStickMistakes.wet);
    });

    test('the cloth: a wet stick dries; a dry or damaged one does not change', () {
      final s = List.generate(40, (i) => i).firstWhere((s) => _deal(s).rounds[0].good.flaw == StickMark.wet);
      final run = HotStickRun(_deal(s));
      final good = run.current.good;
      expect(run.isWet(good), isTrue);
      expect(run.wipe(_bad(run.current)), isFalse);
      expect(run.wipe(good), isTrue);
      expect(run.isWet(good), isFalse);
      expect(run.wipe(good), isFalse);
      expect(run.putBack(good), isFalse, reason: 'a good rod goes back on the stand');
      expect(run.take(good).verdict, StickVerdict.right);
      run.next();
      expect(run.wiped, isEmpty, reason: 'a fresh docket');
    });

    test('a damaged or overdue rod taken is a slip and goes aside', () {
      final run = HotStickRun(_deal(5))..round = 2;
      final twin = _bad(run.current);
      final o = run.take(twin);
      expect(o.verdict, StickVerdict.slip);
      expect(o.mistake, HotStickMistakes.forFlaw(twin.flaw));
      expect(run.rejected, contains(twin.id));
      final old = run.current.rods.firstWhere((x) => x.flaw == StickMark.overdue);
      expect(run.take(old).mistake, HotStickMistakes.overdue);
      expect(run.slips, 2);
      expect(run.ended, isFalse);
    });

    test('putting back: bamboo, overdue, or a damaged rod found by hand go aside free; anything else back on the stand', () {
      final run = HotStickRun(_deal(5))..round = 2;
      final r = run.current;
      final twin = _bad(r);
      expect(run.putBack(r.good), isFalse);
      expect(run.putBack(twin), isFalse, reason: 'not felt: putting back gives nothing away');
      run.spot(r.good);
      expect(run.spotted.contains(r.good.id), r.good.flaw == StickMark.wet);
      run.spot(twin);
      expect(run.putBack(twin), isTrue);
      expect(run.putBack(r.rods.firstWhere((x) => x.flaw == StickMark.overdue)), isTrue, reason: 'the sticker is in plain sight');
      final other = r.rods.firstWhere((x) => x.bamboo || x.rating!.index < r.docket.line.index);
      expect(run.putBack(other), other.bamboo);
      expect(run.slips, 0);
      expect(run.caught, containsAll([HotStickLines.caughtFlaw, HotStickLines.caughtOverdue]));
    });

    test('the coworker pushes only what is still on the stand', () {
      final d = DateTime(2027);
      final rods = [HotStick(id: 'w', rating: StickRating.kv11, flaw: StickMark.wet, due: d), HotStick(id: 'b', due: d)];
      final r = StickRoundDeal(docket: StickDocket(line: StickRating.kv11, jobBn: '', feederBn: '', date: _today), rods: rods);
      expect(stickPushFor(r, {}, {}, preferWet: true), StickPush.wet);
      expect(stickPushFor(r, {}, {}, preferWet: false), StickPush.bamboo);
      expect(stickPushFor(r, {}, {'w'}, preferWet: true), StickPush.bamboo, reason: 'wiped dry');
      expect(stickPushFor(r, {'b'}, {}, preferWet: false), StickPush.wet);
      expect(stickPushFor(r, {'b'}, {'w'}, preferWet: true), isNull);
    });

    test('deals vary', () {
      final deals = [for (var s = 0; s < 60; s++) _deal(s)];
      expect(deals.map((d) => d.rounds.last.docket.line).toSet(), StickRating.values.toSet());
      expect(deals.map((d) => _bad(d.rounds[1]).flaw).toSet(), kStickDamage.toSet());
      expect(deals.map((d) => d.rounds.indexWhere((r) => r.good.flaw == StickMark.wet)).toSet(), {0, 2});
      expect(deals.map((d) => d.callRound).toSet(), {0, 1, 2});
      expect(deals.map((d) => d.preferWet).toSet(), {true, false});
      expect(deals.map((d) => d.rounds[0].rods.map((x) => x.flaw.name).join()).toSet().length, greaterThan(4));
    });

    test('the close look: a mark shows only where the hand has been', () {
      final all = {for (var i = 0; i < kStickBins; i++) i};
      expect(HotStickPainter.markFelt(StickMark.crack, {stickBin(0.1)}), isFalse);
      expect(HotStickPainter.markFelt(StickMark.crack, {stickBin(HotStickPainter.crackU)}), isTrue);
      expect(HotStickPainter.markFelt(StickMark.scratch, {stickBin(0.9)}), isFalse);
      expect(HotStickPainter.markFelt(StickMark.scratch, {stickBin(HotStickPainter.scratchU)}), isTrue);
      expect(HotStickPainter.markFelt(StickMark.glaze, {stickBin(0.3)}), isTrue);
      expect(HotStickPainter.markFelt(StickMark.wet, {stickBin(0.95)}), isFalse);
      expect(HotStickPainter.markFelt(StickMark.wet, {stickBin(0.5)}), isTrue);
      expect(HotStickPainter.markFelt(StickMark.none, all), isFalse);
      expect(HotStickPainter.markFelt(StickMark.overdue, all), isFalse, reason: 'the sticker is read, not felt');
      const s = Size(300, 150);
      expect(HotStickPainter.stickU(s, 0), 0);
      expect(HotStickPainter.stickU(s, 300), 1);
    });

    test('reason and choice libraries: same length, big enough, fit what was done; his lines', () {
      expectSameLength('pack', [
        for (final r in StickRating.values) ...HotStickLines.packRight(r, wiped: true),
        ...HotStickLines.packMyths,
      ]);
      for (final r in StickRating.values) {
        for (final w in [true, false]) {
          final right = HotStickLines.packRight(r, wiped: w);
          final wrong = HotStickLines.packWrong(r, wiped: w);
          expectLibrary('pack ${r.name} $w', right, wrong);
          expect(right, contains(HotStickLines.packMatch(r)));
          expect(wrong, isNot(contains(HotStickLines.packMatch(r))));
          expect(right.contains(HotStickLines.packWiped), w, reason: 'the wipe reason only when he wiped');
        }
      }
      for (final p in StickPush.values) {
        final c = HotStickLines.coworker(p);
        expectSameLength('choice ${p.name}', [...c.right, ...c.wrong]);
        expectLibrary('choice ${p.name}', c.right, c.wrong);
        for (final l in c.recordedLines) {
          final recorded = LearnVoice.resolve(l, rival: true) != null;
          expect(recorded || HotStickLines.toRecord.contains(l), isTrue, reason: l);
        }
      }
      expect(LearnVoice.resolve(HotStickLines.coworkerBamboo.line, rival: true), isNotNull);
    });

    test('no giveaway word: nothing on two or more right cards is missing from every wrong card', () {
      Set<String> words(String s) => s.split(RegExp(r'[\s,—।!?"\x27·:]+')).where((w) => w.isNotEmpty).toSet();
      void noTell(String name, List<String> right, List<String> wrong) {
        final inWrong = {for (final w in wrong) ...words(w)};
        final count = <String, int>{};
        for (final r in right) {
          for (final w in words(r)) {
            count[w] = (count[w] ?? 0) + 1;
          }
        }
        final tells = [for (final e in count.entries) if (e.value >= 2 && !inWrong.contains(e.key)) e.key];
        expect(tells, isEmpty, reason: '$name: words only the right cards share');
      }

      for (final p in StickPush.values) {
        final c = HotStickLines.coworker(p);
        noTell('coworker ${p.name}', c.right, c.wrong);
      }
      for (final r in StickRating.values) {
        for (final w in [true, false]) {
          noTell('pack ${r.name} $w', HotStickLines.packRight(r, wiped: w), HotStickLines.packWrong(r, wiped: w));
        }
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

    Widget page(int seed) => M2HotstickPage(ctx: _ctx, pack: m2HotstickPack25, muted: true, seed: seed, today: _today);

    Future<(ProviderContainer, StickDeal)> open(WidgetTester t, int seed) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      final c = ProviderContainer();
      final nav = GlobalKey<NavigatorState>();
      await t.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
      ));
      unawaited(nav.currentState!.push(MaterialPageRoute<bool>(builder: (_) => page(seed))));
      await _pump(t, 1500);
      await waitIntro(t);
      return (c, _deal(seed));
    }

    Future<void> close(WidgetTester t, ProviderContainer c) async {
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      c.dispose();
      t.view.reset();
    }

    final rods = _label(HotStickLines.rodLabel);

    Future<void> lift(WidgetTester t, StickRoundDeal r, HotStick rod) async {
      await t.tap(rods.at(r.rods.indexOf(rod)), warnIfMissed: false);
      await _pump(t, 600);
      expect(find.text(HotStickLines.take), findsOneWidget);
    }

    /// Runs a hand along the whole stick.
    Future<void> slide(WidgetTester t) async {
      final box = t.getRect(_label(HotStickLines.handLabel));
      final g = await t.startGesture(Offset(box.left + 4, box.center.dy));
      for (var i = 1; i <= 20; i++) {
        await g.moveTo(Offset(box.left + 4 + (box.width - 8) * i / 20, box.center.dy));
        await t.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await t.pump(const Duration(milliseconds: 100));
    }

    Future<void> wipe(WidgetTester t) async {
      await t.tap(find.text(HotStickLines.cloth));
      await _pump(t, 1200);
    }

    /// Takes the good rod of docket [r] (felt, wiped if wet) and gives the reason.
    Future<void> goodRod(WidgetTester t, StickRoundDeal r) async {
      await lift(t, r, r.good);
      await slide(t);
      if (r.good.flaw == StickMark.wet) await wipe(t);
      await t.tap(find.text(HotStickLines.take));
      await _pump(t, 3500);
      expect(find.text(MistakeLines.slipHead), findsNothing);
      await _pickRight(t, HotStickLines.packRight(r.docket.line, wiped: r.good.flaw == StickMark.wet));
      await _pump(t, 3500);
    }

    for (final reduce in [false, true]) {
      testWidgets('waits quietly at the stand (${reduce ? 'reduce' : 'anim'})', (t) async {
        t.view.physicalSize = const Size(720, 1600);
        t.view.devicePixelRatio = 2.0;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        await t.pumpWidget(ProviderScope(child: MaterialApp(home: page(_seedCalling(1)))));
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
        debugPrint('PERF hotstick ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
        expect(t.takeException(), isNull);
        expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
        expect(find.text(HotStickLines.docket), findsOneWidget);
        expect(perSec, lessThan(20));
        expect(frames, lessThan(12));
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 15));
        MascotTalk.reset();
        t.platformDispatcher.clearAccessibilityFeaturesTestValue();
        t.view.reset();
      });
    }

    testWidgets('guide first: no start button, a tap does not skip; tapping him restates the task differently', (t) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      final c = ProviderContainer();
      await t.pumpWidget(UncontrolledProviderScope(container: c, child: MaterialApp(home: page(_seedCalling(2)))));
      await _pump(t, 400);
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text('শুরু'), findsNothing);
      await t.tapAt(const Offset(360, 800));
      await _pump(t, 600);
      expect(find.byType(GuideIntro), findsOneWidget, reason: 'a tap does not skip');
      await waitIntro(t);
      final guide = t.getRect(find.byType(AiLinemanGuide).last);
      final heard = <String>{};
      for (var i = 0; i < 3; i++) {
        await t.tapAt(guide.bottomRight - const Offset(50, 50));
        await _pump(t, 200);
        final line = c.read(guideDirectorProvider).line;
        expect(line, contains(HotStickLines.ask));
        heard.add(line);
      }
      expect(heard.length, 3);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('flow: refuse the coworker, docket close, bamboo aside, feel, wipe, take, reasons → pass', (t) async {
      final (c, deal) = await open(t, _seedCalling(0));
      await _pump(t, 3500);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      await _pickRight(t, [...HotStickLines.coworkerWet.right, ...HotStickLines.coworkerBamboo.right]);
      await _pump(t, 2500);
      expect(find.byType(CoworkerPeek), findsNothing);

      final r1 = deal.rounds[0];
      await t.tap(find.text(HotStickLines.docket));
      await _pump(t, 500);
      expect(find.text(HotStickLines.line(r1.docket)), findsOneWidget);
      expect(find.text(HotStickLines.job(r1.docket)), findsOneWidget);
      await t.tapAt(const Offset(20, 760));
      await _pump(t, 400);
      expect(find.text(HotStickLines.job(r1.docket)), findsNothing);

      await lift(t, r1, r1.rods.firstWhere((x) => x.bamboo));
      await t.tap(find.text(HotStickLines.putBack));
      await _pump(t, 800);
      expect(find.text(HotStickLines.rejected), findsOneWidget, reason: 'the bamboo leans aside, tagged');

      // Docket 2: the damaged twin, felt along its length, goes aside.
      await goodRod(t, r1);
      final r2 = deal.rounds[1];
      await lift(t, r2, _bad(r2));
      expect(find.text(HotStickLines.tested(_bad(r2))), findsOneWidget, reason: 'the sticker is readable in hand');
      await slide(t);
      await t.tap(find.text(HotStickLines.putBack));
      await _pump(t, 800);
      expect(find.text(HotStickLines.rejected), findsOneWidget);
      await goodRod(t, r2);
      await goodRod(t, deal.rounds[2]);
      await _pump(t, 3000);

      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['2.5/do/0'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['2.5/do/0'], greaterThan(0));
      expect(find.text(HotStickLines.caughtCall), findsOneWidget);
      expect(find.text(HotStickLines.caughtWet), findsOneWidget);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('coworker: "একটু ভেজা" — listening is the deadly wet rod (freeze, then the card)', (t) async {
      final (c, _) = await open(t, _seedCalling(0, push: StickPush.wet));
      await _pump(t, 3500);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      await waitChoiceDeck(t);
      final wrong = _onScreen(HotStickLines.coworkerWet.wrong);
      expect(wrong, hasLength(2));
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 700);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3000);
      expect(find.text(HotStickMistakes.wet.textBn), findsOneWidget);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('mistakes: a damaged rod taken is a slip card and goes aside; the bamboo freezes first, then the card', (t) async {
      final (c, deal) = await open(t, _seedCalling(2));
      final r1 = deal.rounds[0];
      final twin = r1.rods.firstWhere((x) => x.rating == StickRating.kv11 && x.flaw != StickMark.none && x.flaw != StickMark.wet);
      await lift(t, r1, twin);
      await t.tap(find.text(HotStickLines.take));
      await _pump(t, 600);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(find.text(HotStickMistakes.forFlaw(twin.flaw).textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.text(HotStickLines.rejected), findsOneWidget);

      await lift(t, r1, r1.rods.firstWhere((x) => x.bamboo));
      await t.tap(find.text(HotStickLines.take));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(FreezeFrame), findsOneWidget, reason: 'the scene freezes first');
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3000);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(HotStickMistakes.bamboo.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.length, greaterThanOrEqualTo(1));
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('coworker comes even on a fast play: the first reach for a rod waits for him', (t) async {
      final (c, deal) = await open(t, _seedCalling(0));
      final r1 = deal.rounds[0];
      // Straight after the guide, before his timer: reach for a rod.
      await t.tap(rods.at(0), warnIfMissed: false);
      await t.pump();
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in now');
      expect(find.text(HotStickLines.take), findsNothing, reason: 'the reach did nothing');
      // His line fits: what he pushes is still on the stand, untouched.
      final push = stickPushFor(r1, const {}, const {}, preferWet: deal.preferWet)!;
      expect(find.byWidgetPredicate((w) => w is CoworkerPeek && w.lineBn == HotStickLines.coworker(push).line), findsOneWidget);
      // The stand waits while he is on screen.
      await t.tap(rods.at(1), warnIfMissed: false);
      await _pump(t, 300);
      expect(find.text(HotStickLines.take), findsNothing);
      await _pickRight(t, HotStickLines.coworker(push).right);
      await _pump(t, 2500);
      expect(find.byType(CoworkerPeek), findsNothing);
      await lift(t, r1, r1.good);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('the cloth: take and put back are dead until it has gone along the stick (a wiped rod is dry)', (t) async {
      final (c, deal) = await open(t, _seedWet(0));
      final r1 = deal.rounds[0];
      await lift(t, r1, r1.good);
      await slide(t);
      await t.tap(find.text(HotStickLines.cloth));
      await t.pump(const Duration(milliseconds: 150));
      await t.tap(find.text(HotStickLines.take), warnIfMissed: false);
      await t.tap(find.text(HotStickLines.putBack), warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(FreezeFrame), findsNothing, reason: 'mid-wipe take does nothing (was: deadly wet rod)');
      expect(find.text(HotStickLines.take), findsOneWidget, reason: 'still in hand');
      await _pump(t, 1200);
      await t.tap(find.text(HotStickLines.take));
      await t.pump(const Duration(milliseconds: 200));
      expect(find.byType(FreezeFrame), findsNothing);
      // The praise window: the stand takes no touch.
      await t.tap(rods.at(r1.rods.indexOf(r1.rods.firstWhere((x) => x != r1.good))), warnIfMissed: false);
      await _pump(t, 300);
      expect(find.text(HotStickLines.take), findsNothing);
      await _pump(t, 3200);
      await _pickRight(t, HotStickLines.packRight(r1.docket.line, wiped: true));
      await _pump(t, 1500);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes, isEmpty);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    group('gesture hints', () {
      setUp(() => GestureHints.debugEnableInTests = true);
      tearDown(() => GestureHints.debugEnableInTests = false);

      testWidgets('a sweep over every rod at the stand, a nudge along the stick in hand, never during the intro', (t) async {
        t.view.physicalSize = const Size(720, 1600);
        t.view.devicePixelRatio = 2.0;
        final seed = _seedCalling(2);
        final deal = _deal(seed);
        final c = ProviderContainer();
        await t.pumpWidget(UncontrolledProviderScope(container: c, child: MaterialApp(home: page(seed))));
        await _pump(t, 400);
        expect(find.byKey(const ValueKey('gesture-hint')), findsNothing, reason: 'not over the guide');
        await waitIntro(t);
        IdleHintState hint() => t.state<IdleHintState>(find.byType(IdleHint).first);
        await _pump(t, 9000);
        expect(hint().showing, isTrue, reason: 'idle at the stand');
        expect(hint().debugOptions.length, deal.rounds[0].rods.length, reason: 'a sweep over every rod, none singled out');
        // Any touch hides it; lift a rod.
        final r1 = deal.rounds[0];
        await lift(t, r1, r1.good);
        expect(hint().showing, isFalse);
        await _pump(t, 9000);
        expect(hint().showing, isTrue, reason: 'idle in hand');
        expect(hint().debugOptions, isEmpty, reason: 'a drag nudge, not a choice');
        await slide(t);
        await _pump(t, 9000);
        expect(hint().showing, isTrue);
        expect(hint().debugOptions.length, 3, reason: 'cloth, put back, take — all three');
        // Take it: while the reason deck is up the scene's hand stays away;
        // only the deck's own sweep (over every open card, never one) shows.
        if (r1.good.flaw == StickMark.wet) await wipe(t);
        await t.tap(find.text(HotStickLines.take));
        await waitChoiceDeck(t);
        expect(find.byType(ChoiceDeck), findsOneWidget);
        await _pump(t, 9000);
        expect(hint().showing, isFalse, reason: 'the scene hint waits while the reason deck is up');
        final deckHints = t.stateList<IdleHintState>(find.descendant(of: find.byType(ChoiceDeck), matching: find.byType(IdleHint)));
        for (final h in deckHints.where((h) => h.showing)) {
          expect(h.debugOptions.length, greaterThanOrEqualTo(2), reason: 'a sweep over the cards, none singled out');
        }
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 15));
        MascotTalk.reset();
        c.dispose();
        t.view.reset();
      });
    });

    testWidgets('three slips fail the level: the struck-out card insists on the lesson', (t) async {
      final (c, deal) = await open(t, _seedCalling(0, push: StickPush.bamboo));
      await _pump(t, 3500);
      await _pickRight(t, HotStickLines.coworkerBamboo.right);
      await _pump(t, 2500);
      Future<void> slipOn(StickRoundDeal r) async {
        await lift(t, r, r.rods.firstWhere((x) => x.rating == r.docket.line && x.flaw != StickMark.none && x.flaw != StickMark.wet));
        await t.tap(find.text(HotStickLines.take));
        await _pump(t, 800);
      }

      for (var i = 0; i < 2; i++) {
        await slipOn(deal.rounds[i]);
        expect(find.text(MistakeLines.slipHead), findsOneWidget, reason: 'slip ${i + 1} shows its card');
        await t.tap(find.text(MistakeLines.gotIt));
        await _pump(t, 400);
        await goodRod(t, deal.rounds[i]);
      }
      await slipOn(deal.rounds[2]);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.text(FrameLines.struckHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.levelScoreByRung.containsKey('2.5/do/0'), isTrue);
      expect(s.rungProgress['2.5/do/0'], isNot('cleared'));
      expect(t.takeException(), isNull);
      await close(t, c);
    });
  });
}
