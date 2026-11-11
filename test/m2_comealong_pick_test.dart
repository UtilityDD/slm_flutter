// Lesson 2.4, কাজ 1 (সঠিক কাম-অ্যালং): rules of the van's rack (plate tonnes
// vs the docket's pull, grip vs the docket's conductor, damaged tools, hold
// the job), the close look (a flaw shows only where the hand has been), deal
// variety, fair reason libraries that fit what the rack had, the coworker's
// lines, and the level in the shell (idle perf; a full clean flow; slips;
// the deadly freeze; the coworker deadly and slip pushes; three slips).
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
import 'package:slm_flutter/features/game/m2_comealong_pick.dart';
import 'package:slm_flutter/features/game/m2_comealong_world.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/ai_lineman_guide.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';

const _ctx = LevelContext(
  rungId: '2.4/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '2.4',
  lessonTitleBn: '',
  ladderStep: 40,
  doIndex: 1,
  doCount: 1,
);

CaItem _right(CaRoundDeal r) => r.items.firstWhere(r.fits);
CaItem _damagedMatch(CaRoundDeal r) => r.items.firstWhere((x) => r.matches(x) && x.flaw != CaFlaw.none);

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

/// The first seed whose coworker comes on docket [round] (and, if given, with
/// a docket-2 twin of that kind / a last docket of [last]).
int _seedCalling(int round, {CaKind? last}) {
  for (var s = 0;; s++) {
    final d = dealComeAlong(math.Random(s));
    if (d.callRound == round && (last == null || d.rounds[2].kind == last)) return s;
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

const _d = CaDocket(wire: CaWire.acsr, loadTenths: 15, feederBn: '');

/// Every fault a hold reason can name.
List<CaRoundDeal> get _holdCases => [
      for (final f in const [CaFlaw.latch, CaFlaw.pawl, CaFlaw.rope])
        CaRoundDeal(kind: CaKind.puller, docket: _d, items: [
          CaItem.puller(id: 'a', tons: 2, flaw: f),
          const CaItem.puller(id: 'b', tons: 1),
        ]),
      for (final w in CaWire.values)
        for (final f in const [CaFlaw.grease, CaFlaw.teeth])
          CaRoundDeal(kind: CaKind.grip, docket: CaDocket(wire: w, loadTenths: 12, feederBn: ''), items: [
            CaItem.grip(id: 'a', wire: w, flaw: f),
            for (final x in CaWire.values)
              if (x != w) CaItem.grip(id: x.name, wire: x),
          ]),
    ];

void main() {
  group('rules', () {
    test('every deal: dockets 1 and 2 have exactly one right tool; docket 3 none; pulls need more than a tonne', () {
      for (var s = 0; s < 80; s++) {
        final d = dealComeAlong(math.Random(s));
        expect(d.rounds.length, 3);
        expect(d.rounds[0].kind, CaKind.puller);
        expect(d.rounds[1].kind, CaKind.grip);
        for (final r in d.rounds.take(2)) {
          expect(r.items.where(r.fits).length, 1);
          expect(r.items.every((x) => x.kind == r.kind), isTrue);
        }
        expect(d.rounds[0].items.where(d.rounds[0].underRated), isNotEmpty);
        expect(d.rounds[1].items.where(d.rounds[1].wrongWire).length, 2);
        expect(d.rounds[2].noneFits, isTrue);
        expect(_damagedMatch(d.rounds[2]).flaw, isNot(CaFlaw.none));
        for (final r in d.rounds) {
          expect(r.docket.loadTenths, greaterThan(10));
          expect(caPushFor(r, {}), isNotNull, reason: 'he always has something to push');
        }
        expect(d.callRound, inInclusiveRange(0, 2));
      }
    });

    test('a clean play: right puller, right grip, hold the job — each waits for its reason', () {
      final run = M2ComeAlongRun(dealComeAlong(math.Random(3)));
      expect(run.take(_right(run.current)).verdict, CaVerdict.right);
      expect(run.shown, isTrue);
      expect(run.round, 0, reason: 'the docket moves on only after the reason');
      expect(run.take(run.current.items.firstWhere(run.current.underRated)).verdict, CaVerdict.slip, reason: 'nothing more on a decided docket');
      expect(run.deadly, isNull);
      run.next();
      expect(run.take(_right(run.current)).verdict, CaVerdict.right);
      run.next();
      expect(run.holdJob().verdict, CaVerdict.right);
      run.next();
      expect(run.passed, isTrue);
      expect(run.percent, 100);
      expect(run.caught, containsAll([M2ComeAlongLines.caughtRating, M2ComeAlongLines.caughtGrip, M2ComeAlongLines.caughtHold]));
    });

    test('a puller rated below the pull is deadly; the wrong grip is a slip (back on the rack)', () {
      final a = M2ComeAlongRun(dealComeAlong(math.Random(1)));
      expect(a.take(a.current.items.firstWhere((x) => x.tons == 1)).mistake, M2ComeAlongMistakes.underRated);
      expect(a.ended, isTrue);
      expect(M2ComeAlongMistakes.underRated.deadly, isTrue);

      final b = M2ComeAlongRun(dealComeAlong(math.Random(1)));
      b.take(_right(b.current));
      b.next();
      final wrong = b.current.items.firstWhere(b.current.wrongWire);
      final o = b.take(wrong);
      expect(o.verdict, CaVerdict.slip);
      expect(o.mistake, M2ComeAlongMistakes.wrongGrip);
      expect(b.rejected, isNot(contains(wrong.id)));
      expect(b.slips, 1);
      expect(b.ended, isFalse);
    });

    test('listening to him: the small puller is deadly, the wrong grip a slip', () {
      final a = M2ComeAlongRun(dealComeAlong(math.Random(2)));
      expect(a.heed(CaPush.rating).verdict, CaVerdict.deadly);
      expect(a.deadly, M2ComeAlongMistakes.underRated);
      final b = M2ComeAlongRun(dealComeAlong(math.Random(2)));
      expect(b.heed(CaPush.grip).mistake, M2ComeAlongMistakes.wrongGrip);
      expect(b.slips, 1);
      expect(b.ended, isFalse);
    });

    test('a damaged tool taken is a slip and goes aside; holding the job too early is a slip', () {
      final run = M2ComeAlongRun(dealComeAlong(math.Random(5)));
      run.take(_right(run.current));
      run.next();
      expect(run.holdJob().mistake, M2ComeAlongMistakes.heldWhenRight);
      final twin = _damagedMatch(run.current);
      final o = run.take(twin);
      expect(o.verdict, CaVerdict.slip);
      expect(o.mistake, M2ComeAlongMistakes.flaw(twin.flaw));
      expect(run.rejected, contains(twin.id));
      expect(run.slips, 2);
      expect(run.ended, isFalse);
    });

    test('putting back: only a damaged tool whose flaw was found goes aside, for free', () {
      final run = M2ComeAlongRun(dealComeAlong(math.Random(5)))..round = 1;
      final r = run.current;
      final twin = _damagedMatch(r);
      expect(run.putBack(_right(r)), isFalse);
      expect(run.putBack(r.items.firstWhere(r.wrongWire)), isFalse);
      expect(run.putBack(twin), isFalse, reason: 'not looked for: putting back gives nothing away');
      expect(run.caught, isNot(contains(M2ComeAlongLines.caughtFlaw)));
      run.spot(_right(r));
      expect(run.spotted, isEmpty, reason: 'a sound tool has nothing to find');
      run.spot(twin);
      expect(run.putBack(twin), isTrue);
      expect(run.slips, 0);
      expect(run.caught, contains(M2ComeAlongLines.caughtFlaw));
      expect(run.take(_right(r)).verdict, CaVerdict.right);
      run.next();
      expect(run.spotted, isEmpty, reason: 'a fresh docket');
    });

    test('the hold reason names the fault only once the player has seen it', () {
      for (final last in CaKind.values) {
        final seed = _seedCalling(0, last: last);
        final run = M2ComeAlongRun(dealComeAlong(math.Random(seed)))..round = 2;
        final r = run.current;
        expect(run.flawKnown, isFalse);
        expect(M2ComeAlongLines.holdRight(r, flawKnown: false), M2ComeAlongLines.holdSound);
        expect(M2ComeAlongLines.holdWrong(r, flawKnown: false), M2ComeAlongLines.holdExcuses);
        run.spot(_damagedMatch(r));
        expect(run.flawKnown, isTrue);
        expect(M2ComeAlongLines.holdRight(r, flawKnown: true), contains(M2ComeAlongLines.flawWhy(r, _damagedMatch(r).flaw)));
      }
    });

    test('the coworker pushes only a tool still on the rack, and only the one this docket can go wrong with', () {
      const pullers = CaRoundDeal(kind: CaKind.puller, docket: _d, items: [CaItem.puller(id: 'a', tons: 2), CaItem.puller(id: 'b', tons: 1)]);
      expect(caPushFor(pullers, {}), CaPush.rating);
      expect(caPushFor(pullers, {'b'}), isNull);
      const grips = CaRoundDeal(kind: CaKind.grip, docket: _d, items: [CaItem.grip(id: 'a', wire: CaWire.acsr), CaItem.grip(id: 'b', wire: CaWire.aaac)]);
      expect(caPushFor(grips, {}), CaPush.grip);
      expect(caPushFor(grips, {'b'}), isNull);
    });

    test('deals vary', () {
      final deals = [for (var s = 0; s < 60; s++) dealComeAlong(math.Random(s))];
      expect(deals.map((d) => d.rounds[1].docket.wire).toSet().length, 3);
      expect(deals.map((d) => d.rounds[0].docket.loadTenths).toSet().length, 3);
      expect(deals.map((d) => d.rounds[2].kind).toSet().length, 2);
      expect(deals.map((d) => _damagedMatch(d.rounds[1]).flaw).toSet(), {CaFlaw.grease, CaFlaw.teeth});
      expect(deals.map((d) => d.rounds[0].items.firstWhere((x) => x.flaw != CaFlaw.none).flaw).toSet().length, 3);
      expect(deals.map((d) => d.callRound).toSet(), {0, 1, 2});
      expect(deals.map((d) => d.rounds[0].items.indexWhere(d.rounds[0].fits)).toSet().length, 3);
    });

    test('the close look: a flaw shows only where the hand has been', () {
      const latch = CaItem.puller(id: 'x', tons: 2, flaw: CaFlaw.latch);
      const pawl = CaItem.puller(id: 'y', tons: 2, flaw: CaFlaw.pawl);
      const rope = CaItem.puller(id: 'z', tons: 2, flaw: CaFlaw.rope);
      const grease = CaItem.grip(id: 'g', wire: CaWire.acsr, flaw: CaFlaw.grease);
      const sound = CaItem.puller(id: 'w', tons: 2);
      final all = {for (var i = 0; i < kCaBins; i++) i};
      expect(CaToolPainter.flawSeen(latch, {}, all), isFalse, reason: 'the rope does not show the hook');
      expect(CaToolPainter.flawSeen(latch, {caBin(0.08)}, {}), isTrue);
      expect(CaToolPainter.flawSeen(pawl, {caBin(0.1)}, all), isFalse);
      expect(CaToolPainter.flawSeen(pawl, {caBin(0.46)}, {}), isTrue);
      expect(CaToolPainter.flawSeen(rope, all, {caBin(0.2)}), isFalse);
      expect(CaToolPainter.flawSeen(rope, {}, {caBin(0.6)}), isTrue);
      expect(CaToolPainter.flawSeen(grease, {caBin(0.3)}, {}), isTrue);
      expect(CaToolPainter.flawSeen(sound, all, all), isFalse);
      expect(CaToolPainter.flawSeen(pawl, null, null), isTrue, reason: 'null = all looked at');
      const s = Size(300, 120);
      final b = CaToolPainter.box(s, CaKind.grip);
      expect(b.width, lessThanOrEqualTo(120 * 2.6));
      expect(CaToolPainter.uAt(s, CaKind.grip, b.left), 0);
      expect(CaToolPainter.uAt(s, CaKind.grip, b.right), 1);
    });

    test('reason and choice libraries: same length, big enough, fit what the rack had', () {
      final dockets = [for (final l in const [12, 15, 18]) CaDocket(wire: CaWire.acsr, loadTenths: l, feederBn: '')];
      expectSameLength('puller', [for (final d in dockets) ...M2ComeAlongLines.pullerRight(d), ...M2ComeAlongLines.pullerMyths]);
      for (final d in dockets) {
        expectLibrary('puller ${d.loadTenths}', M2ComeAlongLines.pullerRight(d), M2ComeAlongLines.pullerWrong(d));
      }
      expectSameLength('grip', [for (final w in CaWire.values) ...M2ComeAlongLines.gripRight(w), ...M2ComeAlongLines.gripMyths]);
      for (final w in CaWire.values) {
        expectLibrary('grip ${w.name}', M2ComeAlongLines.gripRight(w), M2ComeAlongLines.gripWrong(w));
        expect(M2ComeAlongLines.gripRight(w), contains(M2ComeAlongLines.gripMatch(w)));
        expect(M2ComeAlongLines.gripWrong(w), isNot(contains(M2ComeAlongLines.gripMatch(w))));
      }
      expectSameLength('hold', [
        for (final c in _holdCases) ...M2ComeAlongLines.holdRight(c, flawKnown: true),
        for (final c in _holdCases) ...M2ComeAlongLines.holdWrong(c, flawKnown: true),
      ]);
      for (final c in _holdCases) {
        final f = c.items.first.flaw;
        expectLibrary('hold ${c.kind.name} ${f.name}', M2ComeAlongLines.holdRight(c, flawKnown: true), M2ComeAlongLines.holdWrong(c, flawKnown: true));
        expectLibrary('hold unseen ${c.kind.name}', M2ComeAlongLines.holdRight(c, flawKnown: false), M2ComeAlongLines.holdWrong(c, flawKnown: false));
        expect(M2ComeAlongLines.holdRight(c, flawKnown: true), contains(M2ComeAlongLines.flawWhy(c, f)));
        expect(M2ComeAlongLines.holdWrong(c, flawKnown: true), isNot(contains(M2ComeAlongLines.flawWhy(c, f))));
      }
      for (final p in CaPush.values) {
        final c = M2ComeAlongLines.coworker(p);
        expectSameLength('choice ${p.name}', [...c.right, ...c.wrong]);
        expectLibrary('choice ${p.name}', c.right, c.wrong);
        // His exit line is already in his recorded voice; his new push lines
        // go to device TTS until they are recorded (listed in toRecord).
        expect(LearnVoice.resolve(c.exitLine, rival: true), isNotNull);
        expect(M2ComeAlongLines.toRecord, contains(c.line));
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

    Future<(ProviderContainer, CaDeal)> open(WidgetTester t, int seed) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      final deal = dealComeAlong(math.Random(seed));
      final c = ProviderContainer();
      final nav = GlobalKey<NavigatorState>();
      await t.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
      ));
      unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
        builder: (_) => M2ComeAlongPage(ctx: _ctx, pack: m2ComeAlongPack24, muted: true, seed: seed),
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

    final tools = _label(M2ComeAlongLines.toolLabel);

    Future<void> lift(WidgetTester t, CaRoundDeal r, CaItem item) async {
      await t.tap(tools.at(r.items.indexOf(item)), warnIfMissed: false);
      await _pump(t, 600);
      expect(find.text(M2ComeAlongLines.take), findsOneWidget);
    }

    /// Runs a finger along the top and along the bottom of the tool in hand.
    Future<void> slide(WidgetTester t) async {
      final box = t.getRect(_label(M2ComeAlongLines.handLabel));
      for (final y in [0.3, 0.78]) {
        final g = await t.startGesture(Offset(box.left + 2, box.top + box.height * y));
        for (var i = 1; i <= 24; i++) {
          await g.moveTo(Offset(box.left + 2 + (box.width - 4) * i / 24, box.top + box.height * y));
          await t.pump(const Duration(milliseconds: 16));
        }
        await g.up();
        await t.pump(const Duration(milliseconds: 100));
      }
    }

    Future<void> takeRight(WidgetTester t, CaRoundDeal r) async {
      await lift(t, r, _right(r));
      await t.tap(find.text(M2ComeAlongLines.take));
      await _pump(t, 3500);
      expect(find.text(MistakeLines.slipHead), findsNothing);
      await _pickRight(t, r.kind == CaKind.puller ? M2ComeAlongLines.pullerRight(r.docket) : M2ComeAlongLines.gripRight(r.docket.wire));
      await _pump(t, 3500);
    }

    for (final reduce in [false, true]) {
      testWidgets('waits quietly at the van (${reduce ? 'reduce' : 'anim'})', (t) async {
        t.view.physicalSize = const Size(720, 1600);
        t.view.devicePixelRatio = 2.0;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        await t.pumpWidget(ProviderScope(
          child: MaterialApp(home: M2ComeAlongPage(ctx: _ctx, pack: m2ComeAlongPack24, muted: true, seed: _seedCalling(1))),
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
        debugPrint('PERF comealong ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
        expect(t.takeException(), isNull);
        expect(find.textContaining('ধাপ '), findsOneWidget);
        expect(find.text(M2ComeAlongLines.docket), findsOneWidget);
        expect(find.text(M2ComeAlongLines.hold), findsOneWidget);
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
        child: MaterialApp(home: M2ComeAlongPage(ctx: _ctx, pack: m2ComeAlongPack24, muted: true, seed: _seedCalling(2))),
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
        expect(line, contains(M2ComeAlongLines.askPuller));
        heard.add(line);
      }
      expect(heard.length, 3, reason: 'a different way each time');
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('flow: docket, refuse the coworker, slide, a damaged grip aside, reasons, hold the job → pass', (t) async {
      final seed = _seedCalling(0);
      final (c, deal) = await open(t, seed);

      // He peeps in on the first docket ("বড় তার? ছোটটাতেই হবে"); refuse him.
      await _pump(t, 3500);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      await _pickRight(t, M2ComeAlongLines.coworkerRating.right);
      await _pump(t, 2500);
      expect(find.byType(CoworkerPeek), findsNothing);

      // Docket 1: read it close, then the damaged puller put back without a
      // look (back on the rack, untagged), then the right one, felt and taken.
      final r1 = deal.rounds[0];
      await t.tap(find.text(M2ComeAlongLines.docket));
      await _pump(t, 500);
      expect(find.text(M2ComeAlongLines.line(r1.docket)), findsOneWidget);
      await t.tapAt(const Offset(20, 760));
      await _pump(t, 400);
      expect(find.text(M2ComeAlongLines.line(r1.docket)), findsNothing);
      await lift(t, r1, r1.items.firstWhere((x) => x.flaw != CaFlaw.none));
      await t.tap(find.text(M2ComeAlongLines.putBack));
      await _pump(t, 800);
      expect(find.text(M2ComeAlongLines.rejected), findsNothing);
      await lift(t, r1, _right(r1));
      await slide(t);
      await t.tap(find.text(M2ComeAlongLines.take));
      await _pump(t, 3500);
      await _pickRight(t, M2ComeAlongLines.pullerRight(r1.docket));
      await _pump(t, 3500);

      // Docket 2: the damaged twin, felt — the fault shows, so it goes aside.
      final r2 = deal.rounds[1];
      await lift(t, r2, _damagedMatch(r2));
      await slide(t);
      await t.tap(find.text(M2ComeAlongLines.putBack));
      await _pump(t, 800);
      expect(find.text(M2ComeAlongLines.rejected), findsOneWidget, reason: 'found by hand, so set aside');
      await takeRight(t, r2);

      // Docket 3: nothing fits — find the fault, hold the job, say why.
      final r3 = deal.rounds[2];
      await lift(t, r3, _damagedMatch(r3));
      await slide(t);
      await t.tap(find.text(M2ComeAlongLines.putBack));
      await _pump(t, 800);
      expect(find.text(M2ComeAlongLines.rejected), findsOneWidget);
      await t.tap(find.text(M2ComeAlongLines.hold));
      await _pump(t, 3500);
      await _pickRight(t, M2ComeAlongLines.holdRight(r3, flawKnown: true));
      await _pump(t, 6000);

      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['2.4/do/0'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['2.4/do/0'], greaterThan(0));
      expect(find.text(M2ComeAlongLines.caughtCall), findsOneWidget);
      expect(find.text(M2ComeAlongLines.caughtHold), findsOneWidget);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('coworker: listening to "ছোটটাতেই হবে" is deadly (freeze, then the card)', (t) async {
      final (c, _) = await open(t, _seedCalling(0));
      await _pump(t, 3500);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      final wrong = _onScreen(M2ComeAlongLines.coworkerRating.wrong);
      expect(wrong, hasLength(2));
      await t.tap(wrong.first, warnIfMissed: false);
      await _pump(t, 700);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3000);
      expect(find.text(M2ComeAlongMistakes.underRated.textBn), findsOneWidget);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('coworker on the grips: listening is a slip card, and play goes on', (t) async {
      final (c, deal) = await open(t, _seedCalling(1));
      await takeRight(t, deal.rounds[0]);
      await _pump(t, 3500);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      final wrong = _onScreen(M2ComeAlongLines.coworkerGrip.wrong);
      expect(wrong, hasLength(2));
      await t.tap(wrong.first, warnIfMissed: false);
      await _pump(t, 900);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(find.text(M2ComeAlongMistakes.wrongGrip.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await takeRight(t, deal.rounds[1]);
      expect(find.byType(MistakeCard), findsNothing);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('mistakes: a damaged grip taken is a slip and goes aside; a wrong grip is a slip; the small puller freezes first', (t) async {
      final (c, deal) = await open(t, _seedCalling(2));
      final r1 = deal.rounds[0];
      await takeRight(t, r1);

      final r2 = deal.rounds[1];
      await lift(t, r2, _damagedMatch(r2));
      await t.tap(find.text(M2ComeAlongLines.take));
      await _pump(t, 600);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.text(M2ComeAlongLines.rejected), findsOneWidget);

      await lift(t, r2, r2.items.firstWhere(r2.wrongWire));
      await t.tap(find.text(M2ComeAlongLines.take));
      await _pump(t, 600);
      expect(find.text(M2ComeAlongMistakes.wrongGrip.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.length, greaterThanOrEqualTo(2));
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('deadly: the 1-tonne puller on a heavier pull — the scene freezes first, then the card', (t) async {
      final (c, deal) = await open(t, _seedCalling(2));
      final r1 = deal.rounds[0];
      await lift(t, r1, r1.items.firstWhere((x) => x.tons == 1));
      await t.tap(find.text(M2ComeAlongLines.take));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(FreezeFrame), findsOneWidget, reason: 'the scene freezes first');
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3000);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(M2ComeAlongMistakes.underRated.textBn), findsOneWidget);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('three slips fail the level: the struck-out card insists on the lesson', (t) async {
      final (c, _) = await open(t, _seedCalling(2));
      for (var i = 0; i < 2; i++) {
        await t.tap(find.text(M2ComeAlongLines.hold));
        await _pump(t, 600);
        expect(find.text(MistakeLines.slipHead), findsOneWidget, reason: 'slip ${i + 1} shows its card');
        await t.tap(find.text(MistakeLines.gotIt));
        await _pump(t, 400);
      }
      await t.tap(find.text(M2ComeAlongLines.hold));
      await _pump(t, 800);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.text(FrameLines.struckHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.levelScoreByRung.containsKey('2.4/do/0'), isTrue);
      expect(s.rungProgress['2.4/do/0'], isNot('cleared'));
      expect(t.takeException(), isNull);
      await close(t, c);
    });
  });
}
