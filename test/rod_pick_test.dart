// Lesson 1.5, কাজ 1 (সঠিক রড): rules of the van's rack, the close look (a flaw
// shows only where the hand has been), deal variety, fair reason libraries
// that fit what the rack had, his recorded lines, and the level in the shell
// (idle perf; a full clean flow with the docket, a rod set aside, the slide,
// the reasons and the coworker; a slip card; a deadly freeze).
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
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_frame.dart' show FrameLines, StruckOutCard;
import 'package:slm_flutter/features/game/level_juice.dart' show FreezeFrame;
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/rod_pick.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/ai_lineman_guide.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';

const _ctx = LevelContext(
  rungId: '1.5/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '1.5',
  lessonTitleBn: '',
  ladderStep: 14,
  doIndex: 1,
  doCount: 2,
);

RodItem _right(RodRoundDeal r) => r.rods.firstWhere((x) => x.rating == r.docket.line && x.flaw == RodFlaw.none);

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

/// The first seed whose coworker comes on docket [round].
int _seedCalling(int round) {
  for (var s = 0;; s++) {
    if (dealRods(math.Random(s)).callRound == round) return s;
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
}

/// Every stick and lead fault a hold reason can name, on 11 and 33 kV dockets.
List<RodRoundDeal> get _holdCases => [
      for (final line in const [RodRating.kv11, RodRating.kv33])
        for (final f in const [RodFlaw.crack, RodFlaw.cable, RodFlaw.clamp])
          RodRoundDeal(
            docket: RodDocket(line: line, feederBn: '', timeBn: ''),
            rods: [RodItem(id: 'a', rating: line, flaw: f), RodItem(id: 'b', rating: line == RodRating.kv33 ? RodRating.kv11 : RodRating.lt), const RodItem(id: 'c')],
          ),
    ];

void main() {
  group('rules', () {
    test('every deal: docket 1 and 2 have exactly one right rod; docket 3 has none; the coworker is dealt', () {
      for (var s = 0; s < 60; s++) {
        final d = dealRods(math.Random(s));
        expect(d.rounds.length, 3);
        for (final r in d.rounds.take(2)) {
          expect(r.rods.where((x) => x.rating == r.docket.line && x.flaw == RodFlaw.none).length, 1);
          expect(r.rods.where((x) => x.jugaad).length, 1);
        }
        expect(d.rounds[1].docket.line, RodRating.kv33);
        expect(d.rounds[2].noneFits, isTrue);
        expect(d.rounds[2].rods.where((x) => x.rating == d.rounds[2].docket.line).single.flaw, isNot(RodFlaw.none));
        // Never a rod rated above the line: "higher is fine" is not what this level teaches.
        for (final r in d.rounds) {
          expect(r.rods.any((x) => x.rating != null && x.rating!.index > r.docket.line.index), isFalse);
        }
        expect(d.callRound, inInclusiveRange(0, 2));
        if (d.callRating) expect(d.rounds[d.callRound].docket.line, RodRating.kv33);
      }
    });

    test('a clean play: right rod, right rod, hold the job — each waits for its reason', () {
      final run = RodRun(dealRods(math.Random(3)));
      expect(run.take(_right(run.current)).verdict, RodVerdict.right);
      expect(run.shown, isTrue);
      expect(run.round, 0, reason: 'the docket moves on only after the reason');
      expect(run.take(run.current.rods.firstWhere((x) => x.jugaad)).verdict, RodVerdict.slip, reason: 'nothing more on a decided docket');
      expect(run.deadly, isNull);
      run.next();
      expect(run.take(_right(run.current)).verdict, RodVerdict.right);
      run.next();
      expect(run.holdJob().verdict, RodVerdict.right);
      run.next();
      expect(run.passed, isTrue);
      expect(run.percent, 100);
      expect(run.caught, containsAll([RodLines.caughtRating, RodLines.caughtHold]));
    });

    test('the jugaad and a lower rating are deadly', () {
      final a = RodRun(dealRods(math.Random(1)));
      expect(a.take(a.current.rods.firstWhere((x) => x.jugaad)).mistake, RodMistakes.jugaad);
      expect(a.ended, isTrue);

      final b = RodRun(dealRods(math.Random(1)));
      b.take(_right(b.current));
      b.next();
      final lower = b.current.rods.firstWhere((x) => x.rating == RodRating.kv11);
      expect(b.take(lower).mistake, RodMistakes.wrongRating);
      expect(b.deadly, RodMistakes.wrongRating);
    });

    test('a damaged rod taken is a slip and goes aside; holding the job too early is a slip', () {
      final run = RodRun(dealRods(math.Random(5)));
      run.take(_right(run.current));
      run.next();
      expect(run.holdJob().mistake, RodMistakes.heldWhenRight);
      final twin = run.current.rods.firstWhere((x) => x.rating == RodRating.kv33 && x.flaw != RodFlaw.none);
      final o = run.take(twin);
      expect(o.verdict, RodVerdict.slip);
      expect(o.mistake, switch (twin.flaw) { RodFlaw.crack => RodMistakes.crack, RodFlaw.cable => RodMistakes.cable, _ => RodMistakes.clamp });
      expect(run.rejected, contains(twin.id));
      expect(run.slips, 2);
      expect(run.ended, isFalse);
    });

    test('putting back: the jugaad, or a broken rod whose flaw was found, goes aside for free; anything else back on the rack', () {
      final run = RodRun(dealRods(math.Random(5)))..round = 1;
      final r = run.current;
      final twin = r.rods.firstWhere((x) => x.rating == RodRating.kv33 && x.flaw != RodFlaw.none);
      expect(run.putBack(_right(r)), isFalse);
      expect(run.putBack(r.rods.firstWhere((x) => x.rating == RodRating.kv11)), isFalse);
      expect(run.putBack(r.rods.firstWhere((x) => x.jugaad)), isTrue, reason: 'PVC shows to the eye');
      // Not looked for: putting it back gives nothing away.
      expect(run.putBack(twin), isFalse);
      expect(run.rejected, isNot(contains(twin.id)));
      expect(run.caught, isNot(contains(RodLines.caughtFlaw)));
      // Found by hand: now it goes aside.
      run.spot(_right(r));
      expect(run.spotted, isEmpty, reason: 'a sound rod has nothing to find');
      run.spot(twin);
      expect(run.putBack(twin), isTrue);
      expect(run.rejected.length, 2);
      expect(run.slips, 0);
      expect(run.caught, containsAll([RodLines.caughtJugaad, RodLines.caughtFlaw]));
      expect(run.take(_right(r)).verdict, RodVerdict.right);
      run.next();
      expect(run.spotted, isEmpty, reason: 'a fresh docket');
    });

    test('the hold reason names the fault only once the player has seen it', () {
      final run = RodRun(dealRods(math.Random(7)))..round = 2;
      final r = run.current;
      final bad = r.rods.firstWhere((x) => x.rating == r.docket.line);
      expect(run.flawKnown, isFalse);
      expect(RodLines.holdRight(r, flawKnown: false), RodLines.holdSound);
      expect(RodLines.holdWrong(r, flawKnown: false), RodLines.holdExcuses);
      run.spot(r.rods.firstWhere((x) => x.jugaad));
      expect(run.flawKnown, isFalse, reason: 'only the right-rated rod\'s fault counts');
      run.spot(bad);
      expect(run.flawKnown, isTrue);
      // Taking it (a slip) shows the fault on the card: known too.
      final b = RodRun(dealRods(math.Random(7)))..round = 2;
      expect(b.take(b.current.rods.firstWhere((x) => x.rating == b.current.docket.line)).verdict, RodVerdict.slip);
      expect(b.flawKnown, isTrue);
    });

    test('the coworker pushes only a rod still on the rack', () {
      const d33 = RodDocket(line: RodRating.kv33, feederBn: '', timeBn: '');
      const d11 = RodDocket(line: RodRating.kv11, feederBn: '', timeBn: '');
      const rods = [RodItem(id: 'a', rating: RodRating.kv33), RodItem(id: 'b', rating: RodRating.kv11), RodItem(id: 'j')];
      const r33 = RodRoundDeal(docket: d33, rods: rods);
      expect(rodPushFor(r33, {}, preferRating: true), RodPush.rating);
      expect(rodPushFor(r33, {}, preferRating: false), RodPush.jugaad);
      expect(rodPushFor(r33, {'j'}, preferRating: false), RodPush.rating, reason: 'the jugaad hangs on the door');
      expect(rodPushFor(r33, {'b'}, preferRating: true), RodPush.jugaad);
      expect(rodPushFor(r33, {'b', 'j'}, preferRating: true), isNull);
      const r11 = RodRoundDeal(docket: d11, rods: [RodItem(id: 'b', rating: RodRating.kv11), RodItem(id: 'l', rating: RodRating.lt), RodItem(id: 'j')]);
      expect(rodPushFor(r11, {}, preferRating: true), RodPush.jugaad, reason: 'the 11 kV push only on a 33 kV line');
      expect(rodPushFor(r11, {'j'}, preferRating: false), isNull);
    });

    test('deals vary', () {
      final deals = [for (var s = 0; s < 40; s++) dealRods(math.Random(s))];
      expect(deals.map((d) => d.rounds.first.docket.line).toSet(), {RodRating.lt, RodRating.kv11});
      expect(deals.map((d) => d.rounds.last.docket.line).toSet(), {RodRating.kv11, RodRating.kv33});
      expect(deals.map((d) => d.rounds[1].rods.firstWhere((x) => x.flaw != RodFlaw.none).flaw).toSet().length, 3);
      expect(deals.map((d) => d.callRound).toSet(), {0, 1, 2});
      expect(deals.map((d) => d.callRating).toSet(), {true, false});
    });

    test('the close look: a flaw shows only where the hand has been', () {
      const crack = RodItem(id: 'x', rating: RodRating.kv11, flaw: RodFlaw.crack);
      const cut = RodItem(id: 'y', rating: RodRating.kv11, flaw: RodFlaw.cable);
      const rust = RodItem(id: 'z', rating: RodRating.kv11, flaw: RodFlaw.clamp);
      const sound = RodItem(id: 'w', rating: RodRating.kv11);
      final all = {for (var i = 0; i < kRodBins; i++) i};
      expect(RodPainter.flawSeen(crack, {}, all), isFalse, reason: 'the lead does not show the stick');
      expect(RodPainter.flawSeen(crack, {rodBin(0.62)}, {}), isTrue);
      expect(RodPainter.flawSeen(cut, all, {0, 1, 2}), isFalse);
      expect(RodPainter.flawSeen(cut, {}, {rodBin(0.52)}), isTrue);
      expect(RodPainter.flawSeen(rust, {}, {rodBin(0.5)}), isFalse);
      expect(RodPainter.flawSeen(rust, {}, {kRodBins - 1}), isTrue);
      expect(RodPainter.flawSeen(sound, all, all), isFalse);
      expect(RodPainter.flawSeen(crack, null, null), isTrue, reason: 'null = all looked at');
      // The hand's position maps along the stick and the lead.
      const s = Size(300, 130);
      expect(RodPainter.stickU(s, 30), 0);
      expect(RodPainter.stickU(s, 270), 1);
      expect(RodPainter.leadU(s, RodPainter.leadAt(s, 0.7).dx), closeTo(0.7, 0.03));
    });

    test('reason and choice libraries: same length, big enough, fit what the rack had; his lines are recorded', () {
      expectSameLength('pack', [for (final r in RodRating.values) ...RodLines.packRight(r), ...RodLines.packMyths]);
      for (final r in RodRating.values) {
        expectLibrary('pack ${r.name}', RodLines.packRight(r), RodLines.packWrong(r));
        expect(RodLines.packRight(r), contains(RodLines.packMatch(r)));
        expect(RodLines.packWrong(r), isNot(contains(RodLines.packMatch(r))));
      }
      expectSameLength('hold', [
        for (final c in _holdCases) ...RodLines.holdRight(c, flawKnown: true),
        ...RodLines.holdExcuses,
        for (final c in _holdCases) ...RodLines.holdWrong(c, flawKnown: true),
      ]);
      for (final c in _holdCases) {
        final f = c.rods.first.flaw;
        expectLibrary('hold ${c.docket.line.name} ${f.name}', RodLines.holdRight(c, flawKnown: true), RodLines.holdWrong(c, flawKnown: true));
        expectLibrary('hold unseen ${c.docket.line.name} ${f.name}', RodLines.holdRight(c, flawKnown: false), RodLines.holdWrong(c, flawKnown: false));
        expect(RodLines.holdRight(c, flawKnown: true), contains(RodLines.flawWhy(c.docket.line, f)));
        expect(RodLines.holdWrong(c, flawKnown: true), isNot(contains(RodLines.flawWhy(c.docket.line, f))));
        for (final x in const [RodFlaw.crack, RodFlaw.cable, RodFlaw.clamp]) {
          expect([...RodLines.holdRight(c, flawKnown: false), ...RodLines.holdWrong(c, flawKnown: false)], isNot(contains(RodLines.flawWhy(c.docket.line, x))),
              reason: 'a fault never looked for is never a card');
        }
      }
      for (final p in RodPush.values) {
        final c = RodLines.coworker(p);
        expectSameLength('choice ${p.name}', [...c.right, ...c.wrong]);
        expectLibrary('choice ${p.name}', c.right, c.wrong);
        for (final l in c.recordedLines) {
          expect(LearnVoice.resolve(l, rival: true), isNotNull, reason: l);
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

    Future<(ProviderContainer, RodDeal)> open(WidgetTester t, int seed) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      final deal = dealRods(math.Random(seed));
      final c = ProviderContainer();
      final nav = GlobalKey<NavigatorState>();
      await t.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
      ));
      unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
        builder: (_) => RodPickPage(ctx: _ctx, pack: rodPickPack15, muted: true, seed: seed),
      )));
      await _pump(t, 1500);
      await waitIntro(t);
      return (c, deal);
    }

    Future<void> close(WidgetTester t, ProviderContainer c) async {
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      c.dispose();
      t.view.reset();
    }

    final rods = _label(RodLines.rodLabel);

    /// Takes the rod [rod] of docket [r] off the rack, into the hands.
    Future<void> lift(WidgetTester t, RodRoundDeal r, RodItem rod) async {
      await t.tap(rods.at(r.rods.indexOf(rod)), warnIfMissed: false);
      await _pump(t, 600);
      expect(find.text(RodLines.take), findsOneWidget);
    }

    /// Runs a finger along the stick and along the lead to the clamp.
    Future<void> slide(WidgetTester t) async {
      final box = t.getRect(_label(RodLines.handLabel));
      for (final y in [0.36, 0.82]) {
        final g = await t.startGesture(Offset(box.left + 4, box.top + box.height * y));
        for (var i = 1; i <= 20; i++) {
          await g.moveTo(Offset(box.left + 4 + (box.width - 8) * i / 20, box.top + box.height * y));
          await t.pump(const Duration(milliseconds: 16));
        }
        await g.up();
        await t.pump(const Duration(milliseconds: 100));
      }
    }

    for (final reduce in [false, true]) {
      testWidgets('waits quietly at the van (${reduce ? 'reduce' : 'anim'})', (t) async {
        t.view.physicalSize = const Size(720, 1600);
        t.view.devicePixelRatio = 2.0;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        // He comes on a later docket, so the first one stays quiet.
        await t.pumpWidget(ProviderScope(
          child: MaterialApp(home: RodPickPage(ctx: _ctx, pack: rodPickPack15, muted: true, seed: _seedCalling(1))),
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
        debugPrint('PERF rod pick ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
        expect(t.takeException(), isNull);
        expect(find.textContaining('ধাপ '), findsOneWidget);
        expect(find.text(RodLines.docket), findsOneWidget);
        expect(find.text(RodLines.hold), findsOneWidget);
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
      await t.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(home: RodPickPage(ctx: _ctx, pack: rodPickPack15, muted: true, seed: _seedCalling(2))),
      ));
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
        expect(line, contains(RodLines.ask));
        heard.add(line);
      }
      expect(heard.length, 3, reason: 'a different way each time');
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('flow: docket, jugaad aside, slide and take, reasons, refuse the coworker, hold the job → pass', (t) async {
      final seed = _seedCalling(0);
      final (c, deal) = await open(t, seed);

      // He peeps in on the first docket; the guide asks; refuse him.
      await _pump(t, 3500);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      await _pickRight(t, [...RodLines.coworkerJugaad.right, ...RodLines.coworkerRating.right]);
      await _pump(t, 2500);
      expect(find.byType(CoworkerPeek), findsNothing);

      // Docket 1: read the docket close, set the jugaad aside, then the right rod.
      final r1 = deal.rounds[0];
      await t.tap(find.text(RodLines.docket));
      await _pump(t, 500);
      expect(find.text(RodLines.line(r1.docket)), findsOneWidget);
      await t.tapAt(const Offset(20, 760));
      await _pump(t, 400);
      expect(find.text(RodLines.line(r1.docket)), findsNothing);

      await lift(t, r1, r1.rods.firstWhere((x) => x.jugaad));
      await t.tap(find.text(RodLines.putBack));
      await _pump(t, 800);
      expect(find.text(RodLines.rejected), findsOneWidget, reason: 'the jugaad leans aside, tagged');

      for (var i = 0; i < 2; i++) {
        final r = deal.rounds[i];
        if (i == 1) {
          // The damaged twin put back without a look: it goes back on the
          // rack, untagged — putting back gives nothing away.
          await lift(t, r, r.rods.firstWhere((x) => x.rating == RodRating.kv33 && x.flaw != RodFlaw.none));
          await t.tap(find.text(RodLines.putBack));
          await _pump(t, 800);
          expect(find.text(RodLines.rejected), findsNothing);
          expect(find.text(RodLines.take), findsNothing);
        }
        await lift(t, r, _right(r));
        await slide(t);
        await t.tap(find.text(RodLines.take));
        await _pump(t, 3500);
        expect(find.text(MistakeLines.slipHead), findsNothing);
        await _pickRight(t, RodLines.packRight(r.docket.line));
        await _pump(t, 3500);
      }

      // Docket 3: the right-rated rod, felt along its length — the fault
      // shows, so it goes aside tagged; nothing fits — hold the job, say why.
      final r3 = deal.rounds[2];
      await lift(t, r3, r3.rods.firstWhere((x) => x.rating == r3.docket.line));
      await slide(t);
      await t.tap(find.text(RodLines.putBack));
      await _pump(t, 800);
      expect(find.text(RodLines.rejected), findsOneWidget, reason: 'found by hand, so set aside');
      await t.tap(find.text(RodLines.hold));
      await _pump(t, 3500);
      await _pickRight(t, RodLines.holdRight(r3, flawKnown: true));
      await _pump(t, 6000);

      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['1.5/do/0'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['1.5/do/0'], greaterThan(0));
      expect(find.text(RodLines.caughtCall), findsOneWidget);
      expect(find.text(RodLines.caughtHold), findsOneWidget);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('coworker: listening to him is the deadly jugaad (freeze, then the card)', (t) async {
      final (c, _) = await open(t, _seedCalling(0));
      await _pump(t, 3500);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      final wrong = _onScreen(RodLines.coworkerJugaad.wrong);
      expect(wrong, hasLength(2));
      await t.tap(wrong.first, warnIfMissed: false);
      await _pump(t, 700);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3000);
      expect(find.text(RodMistakes.jugaad.textBn), findsOneWidget);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('mistakes: a broken rod taken is a slip card and goes aside; the jugaad freezes first, then the card', (t) async {
      final seed = _seedCalling(2);
      final (c, deal) = await open(t, seed);
      final r1 = deal.rounds[0];
      await lift(t, r1, _right(r1));
      await t.tap(find.text(RodLines.take));
      await _pump(t, 3500);
      await _pickRight(t, RodLines.packRight(r1.docket.line));
      await _pump(t, 3500);

      final r2 = deal.rounds[1];
      await lift(t, r2, r2.rods.firstWhere((x) => x.rating == RodRating.kv33 && x.flaw != RodFlaw.none));
      await t.tap(find.text(RodLines.take));
      await _pump(t, 600);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.text(RodLines.rejected), findsOneWidget);

      await lift(t, r2, r2.rods.firstWhere((x) => x.jugaad));
      await t.tap(find.text(RodLines.take));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(FreezeFrame), findsOneWidget, reason: 'the scene freezes first');
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3000);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(RodMistakes.jugaad.textBn), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.length, greaterThanOrEqualTo(1));
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('three slips fail the level: the struck-out card insists on the lesson', (t) async {
      // He comes on the last docket, so docket 1 stays clear for the slips.
      final (c, _) = await open(t, _seedCalling(2));
      // Docket 1 has a right rod, so holding the job is a slip — three times.
      for (var i = 0; i < 2; i++) {
        await t.tap(find.text(RodLines.hold));
        await _pump(t, 600);
        expect(find.text(MistakeLines.slipHead), findsOneWidget, reason: 'slip ${i + 1} shows its card');
        await t.tap(find.text(MistakeLines.gotIt));
        await _pump(t, 400);
      }
      await t.tap(find.text(RodLines.hold));
      await _pump(t, 800);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.text(FrameLines.struckHead), findsOneWidget);
      expect(find.text(MistakeLines.slipHead), findsNothing);
      final s = c.read(gameSaveProvider);
      expect(s.levelScoreByRung.containsKey('1.5/do/0'), isTrue);
      expect(s.rungProgress['1.5/do/0'], isNot('cleared'));
      expect(t.takeException(), isNull);
      await close(t, c);
    });
  });
}
