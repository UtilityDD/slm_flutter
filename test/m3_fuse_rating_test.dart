// Lesson 3.4, কাজ 1 (সঠিক ফিউজ তার): rules of the docket (the plate's
// rating, wrong ratings, plain wire, thick copper = deadly, sooty contacts,
// a slack tie), deal variety, fair reason libraries, and the level in the
// shell (idle perf; the guide first; a full clean flow with the plate, a reel
// put back, the barrel, the reasons and the coworker; listening to him is
// deadly — freeze first; slip cards; three slips fail).
import 'dart:async';
import 'dart:io';
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
import 'package:slm_flutter/features/game/m3_fuse_rating.dart';
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
  rungId: '3.4/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '3.4',
  lessonTitleBn: '',
  ladderStep: 9,
  doIndex: 1,
  doCount: 2,
);

/// Serves this level's mistake art from disk (its folder joins pubspec when
/// the director wires the level), everything else from the app bundle.
class _ArtBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key.startsWith('assets/game/art/m3_fuse_rating/')) {
      final b = File(key).readAsBytesSync();
      return ByteData.view(Uint8List.fromList(b).buffer);
    }
    return rootBundle.load(key);
  }
}

Widget _app(Widget home, {GlobalKey<NavigatorState>? nav}) => MaterialApp(
      navigatorKey: nav,
      builder: (context, child) => DefaultAssetBundle(bundle: _ArtBundle(), child: child!),
      home: home,
    );

M3FuseRatingReel _of(M3FuseRatingRound r, M3FuseRatingKind k) => r.reels.firstWhere((x) => x.kind == k);
M3FuseRatingReel _wrongLink(M3FuseRatingRound r) => r.reels.firstWhere((x) => x.kind == M3FuseRatingKind.link && x.amps != r.amps);

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

/// The first seed whose coworker comes on DTR [round].
int _seedCalling(int round) {
  for (var s = 0;; s++) {
    if (m3FuseRatingDeal(math.Random(s)).callRound == round) return s;
  }
}

Finder _label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);
List<Finder> _onScreen(List<String> texts) => [
      for (final x in texts)
        if (_label(x).evaluate().isNotEmpty) _label(x),
    ];

Future<void> _pickRight(WidgetTester t, List<String> right) async {
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = _onScreen(right);
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
}

void main() {
  group('rules', () {
    test('every deal: three DTRs; each tray has one right link, the other rating, copper and GI wire', () {
      for (var s = 0; s < 80; s++) {
        final d = m3FuseRatingDeal(math.Random(s));
        expect(d.rounds.length, 3);
        expect(d.rounds[0].amps, isNot(d.rounds[1].amps), reason: 'both plates come up');
        for (final r in d.rounds) {
          expect(kM3FuseRatingAmps, contains(r.amps));
          expect(r.reels.length, 4);
          expect(r.reels.where(r.fits).length, 1);
          expect(r.reels.where((x) => x.kind == M3FuseRatingKind.copper).length, 1);
          expect(r.reels.where((x) => x.kind == M3FuseRatingKind.plain).length, 1);
          expect(r.reels.map((x) => x.id).toSet().length, 4);
        }
        expect(d.rounds[0].dirty, isEmpty);
        expect(d.rounds[1].dirty.length, 1, reason: 'the contacts reason needs soot to wipe');
        expect([for (final r in d.rounds) r.ask], M3FuseRatingAsk.values);
        expect(d.callRound, inInclusiveRange(0, 2));
      }
    });

    test('a clean play: right link, wipe, pull taut, tie — three times', () {
      final run = M3FuseRatingRun(m3FuseRatingDeal(math.Random(3)));
      for (var i = 0; i < 3; i++) {
        final r = run.current;
        expect(run.take(r.right).verdict, M3FuseRatingVerdict.right);
        expect(run.tying, isTrue);
        expect(run.take(_of(r, M3FuseRatingKind.copper)).mistake, isNull, reason: 'nothing more while tying');
        for (final s in r.dirty) {
          run.wipe(s);
        }
        expect(run.dirtyLeft, isEmpty);
        expect(run.tie(1).verdict, M3FuseRatingVerdict.right);
        expect(run.shown, isTrue);
        expect(run.round, i, reason: 'the DTR moves on only after the reason');
        run.next();
      }
      expect(run.passed, isTrue);
      expect(run.percent, 100);
      expect(run.caught, containsAll([M3FuseRatingLines.caughtRating, M3FuseRatingLines.caughtClean, M3FuseRatingLines.caughtTie]));
    });

    test('a wrong rating, plain wire: each a slip and set aside; thick copper is deadly and ends the play', () {
      final run = M3FuseRatingRun(m3FuseRatingDeal(math.Random(5)));
      final r = run.current;
      final wrong = _wrongLink(r);
      expect(run.take(wrong).mistake, wrong.amps > r.amps ? M3FuseRatingMistakes.tooBig : M3FuseRatingMistakes.tooSmall);
      expect(run.take(_of(r, M3FuseRatingKind.plain)).mistake, M3FuseRatingMistakes.plainWire);
      expect(run.rejected.length, 2);
      expect(run.slips, 2);
      expect(run.take(wrong).mistake, isNull, reason: 'already aside');
      final o = run.take(_of(r, M3FuseRatingKind.copper));
      expect(o.verdict, M3FuseRatingVerdict.deadly);
      expect(o.mistake, M3FuseRatingMistakes.thickCopper);
      expect(run.ended, isTrue);
      expect(run.passed, isFalse);
      expect(run.take(r.right).mistake, isNull, reason: 'over');
    });

    test('both directions of a wrong rating are caught', () {
      const big = M3FuseRatingRound(amps: 10, reels: [M3FuseRatingReel(id: 'a', kind: M3FuseRatingKind.link, amps: 25)], dirty: {}, ask: M3FuseRatingAsk.rating);
      const small = M3FuseRatingRound(amps: 25, reels: [M3FuseRatingReel(id: 'a', kind: M3FuseRatingKind.link, amps: 10)], dirty: {}, ask: M3FuseRatingAsk.rating);
      expect(M3FuseRatingRun(M3FuseRatingDeal(rounds: const [big], callRound: 0)).take(big.reels.single).mistake, M3FuseRatingMistakes.tooBig);
      expect(M3FuseRatingRun(M3FuseRatingDeal(rounds: const [small], callRound: 0)).take(small.reels.single).mistake, M3FuseRatingMistakes.tooSmall);
    });

    test('the barrel: a sooty contact left, then a slack tie — slips; wiping a clean contact counts for nothing', () {
      final run = M3FuseRatingRun(m3FuseRatingDeal(math.Random(9)))..round = 1;
      final r = run.current;
      expect(run.tie(1).mistake, isNull, reason: 'no link yet');
      run.take(r.right);
      final clean = M3FuseRatingSpot.values.firstWhere((s) => !r.dirty.contains(s));
      run.wipe(clean);
      expect(run.wiped, isEmpty);
      expect(run.tie(1).mistake, M3FuseRatingMistakes.dirtyContact);
      run.wipe(r.dirty.single);
      expect(run.tie(kM3FuseRatingTaut - 0.05).mistake, M3FuseRatingMistakes.looseTie);
      expect(run.tying, isTrue);
      expect(run.slips, 2);
      expect(run.tie(kM3FuseRatingTaut).verdict, M3FuseRatingVerdict.right);
      run.next();
      expect(run.wiped, isEmpty, reason: 'a fresh barrel');
      expect(run.fitted, isNull);
    });

    test('deals vary', () {
      final deals = [for (var s = 0; s < 60; s++) m3FuseRatingDeal(math.Random(s))];
      expect(deals.map((d) => d.rounds[0].amps).toSet(), kM3FuseRatingAmps.toSet());
      expect(deals.map((d) => d.rounds[2].amps).toSet(), kM3FuseRatingAmps.toSet());
      expect(deals.map((d) => d.rounds[1].dirty.single).toSet(), M3FuseRatingSpot.values.toSet());
      expect(deals.map((d) => d.rounds[2].dirty.length).toSet(), {0, 1, 2});
      expect(deals.map((d) => d.callRound).toSet(), {0, 1, 2});
      expect(deals.map((d) => d.rounds[0].reels.indexWhere(d.rounds[0].fits)).toSet().length, greaterThan(2));
    });

    test('reason and choice libraries: same length, big enough, fit the plate; his exit line is recorded; the mistakes book', () {
      final all = [
        for (final a in kM3FuseRatingAmps) ...M3FuseRatingLines.ratingRight(a),
        ...M3FuseRatingLines.ratingMyths,
        ...M3FuseRatingLines.contactsRight,
        ...M3FuseRatingLines.contactsWrong,
        ...M3FuseRatingLines.tieRight,
        ...M3FuseRatingLines.tieWrong,
      ];
      expectSameLength('reasons', all);
      for (final a in kM3FuseRatingAmps) {
        expectLibrary('rating $a', M3FuseRatingLines.ratingRight(a), M3FuseRatingLines.ratingWrong(a));
        expect(M3FuseRatingLines.ratingWrong(a), isNot(contains(M3FuseRatingLines.ratingMatch(a))));
      }
      expectLibrary('contacts', M3FuseRatingLines.contactsRight, M3FuseRatingLines.contactsWrong);
      expectLibrary('tie', M3FuseRatingLines.tieRight, M3FuseRatingLines.tieWrong);
      const c = M3FuseRatingLines.coworker;
      expectSameLength('coworker', [...c.right, ...c.wrong]);
      expectLibrary('coworker', c.right, c.wrong);
      expect(LearnVoice.resolve(c.exitLine, rival: true), isNotNull, reason: c.exitLine);
      expect(M3FuseRatingLines.newRivalLines, contains(c.line));
      // Lesson 3.4's points: 1 = DO fuse (the barrel), 3 = choosing the fuse element.
      final keys = <String>{};
      for (final m in M3FuseRatingMistakes.all) {
        expect(m.key, startsWith('3.4/m3_fuse_rating/'));
        expect(keys.add(m.key), isTrue, reason: 'unique ${m.key}');
        expect(m.deadly, m == M3FuseRatingMistakes.thickCopper);
        expect(m.lessonPoint, anyOf(1, 3));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
      }
      expect(m3FuseRatingPacks['do_3_4_a'], m3FuseRatingPack34);
    });
  });

  group('page', () {
    TestWidgetsFlutterBinding.ensureInitialized();
    final msg = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final c in ['xyz.luan/audioplayers', 'xyz.luan/audioplayers.global', 'flutter_tts']) {
      msg.setMockMethodCallHandler(MethodChannel(c), (_) async => 1);
    }
    ZlFx.setMuted(true);
    var rebuilds = 0;
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      SpokenOnce.resetForTest();
      debugOnRebuildDirtyWidget = (_, _) => rebuilds++;
    });
    tearDown(() => debugOnRebuildDirtyWidget = null);

    Future<(ProviderContainer, M3FuseRatingDeal)> open(WidgetTester t, int seed) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      final deal = m3FuseRatingDeal(math.Random(seed));
      final c = ProviderContainer();
      final nav = GlobalKey<NavigatorState>();
      await t.pumpWidget(UncontrolledProviderScope(container: c, child: _app(const Scaffold(body: SizedBox()), nav: nav)));
      unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
        builder: (_) => M3FuseRatingPage(ctx: _ctx, pack: m3FuseRatingPack34, muted: true, seed: seed),
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

    final reels = _label(M3FuseRatingLines.reelLabel);

    Future<void> lift(WidgetTester t, M3FuseRatingRound r, M3FuseRatingReel x) async {
      await t.tap(reels.at(r.reels.indexOf(x)), warnIfMissed: false);
      await _pump(t, 600);
      expect(find.text(M3FuseRatingLines.take), findsOneWidget);
      expect(find.text(M3FuseRatingLines.reelBn(x)), findsOneWidget, reason: 'read up close');
      if (x.tag.isNotEmpty) expect(find.text(x.tag), findsOneWidget);
    }

    /// Rubs a contact with the cloth, back and forth.
    Future<void> rub(WidgetTester t, M3FuseRatingSpot s) async {
      final box = t.getRect(_label(s == M3FuseRatingSpot.top ? M3FuseRatingLines.topLabel : M3FuseRatingLines.bottomLabel));
      final g = await t.startGesture(box.center);
      for (var i = 0; i < 16; i++) {
        await g.moveTo(box.center + Offset(i.isEven ? 20 : -20, 0));
        await t.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await t.pump(const Duration(milliseconds: 100));
    }

    /// At the barrel: wipe [wipe], pull the tail taut if [pull], tie.
    Future<void> barrel(WidgetTester t, Set<M3FuseRatingSpot> wipe, {bool pull = true}) async {
      expect(find.text(M3FuseRatingLines.tie), findsOneWidget);
      for (final s in wipe) {
        await rub(t, s);
      }
      if (pull) {
        await t.drag(_label(M3FuseRatingLines.tailLabel), const Offset(400, 0));
        await t.pump(const Duration(milliseconds: 50));
      }
      await t.tap(find.text(M3FuseRatingLines.tie));
      await _pump(t, 900);
    }

    for (final reduce in [false, true]) {
      testWidgets('waits quietly at the van (${reduce ? 'reduce' : 'anim'})', (t) async {
        t.view.physicalSize = const Size(720, 1600);
        t.view.devicePixelRatio = 2.0;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        await t.pumpWidget(ProviderScope(child: _app(M3FuseRatingPage(ctx: _ctx, pack: m3FuseRatingPack34, muted: true, seed: _seedCalling(1)))));
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
        debugPrint('PERF fuse rating ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
        expect(t.takeException(), isNull);
        expect(find.textContaining('ধাপ '), findsOneWidget);
        expect(reels, findsNWidgets(4));
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
        child: _app(M3FuseRatingPage(ctx: _ctx, pack: m3FuseRatingPack34, muted: true, seed: _seedCalling(2))),
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
        expect(line, contains(M3FuseRatingLines.ask));
        heard.add(line);
      }
      expect(heard.length, 3, reason: 'a different way each time');
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('flow: refuse the coworker, read the plate, a reel put back, three barrels, reasons → pass', (t) async {
      final (c, deal) = await open(t, _seedCalling(0));

      // He peeps in on the first DTR; the guide asks; refuse him.
      await _pump(t, 3500);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      await _pickRight(t, M3FuseRatingLines.coworker.right);
      await _pump(t, 2500);
      expect(find.byType(CoworkerPeek), findsNothing);

      // DTR 1: read the plate close; the other rating put back (no cost, no tag).
      final r1 = deal.rounds[0];
      await t.tap(_label(M3FuseRatingLines.plateLabel));
      await _pump(t, 500);
      expect(find.text(M3FuseRatingLines.plateBn(r1.amps)), findsOneWidget);
      await t.tapAt(const Offset(20, 760));
      await _pump(t, 400);
      expect(find.text(M3FuseRatingLines.plateBn(r1.amps)), findsNothing);
      await lift(t, r1, _wrongLink(r1));
      await t.tap(find.text(M3FuseRatingLines.putBack));
      await _pump(t, 800);
      expect(find.text(M3FuseRatingLines.rejected), findsNothing);

      for (final r in deal.rounds) {
        await lift(t, r, r.right);
        await t.tap(find.text(M3FuseRatingLines.take));
        await _pump(t, 800);
        await barrel(t, r.dirty);
        await _pump(t, 2500);
        expect(find.text(MistakeLines.slipHead), findsNothing);
        await _pickRight(t, M3FuseRatingLines.right(r));
        await _pump(t, 3500);
      }
      await _pump(t, 3000);

      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['3.4/do/0'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['3.4/do/0'], greaterThan(0));
      expect(find.text(M3FuseRatingLines.caughtCall), findsOneWidget);
      expect(find.text(M3FuseRatingLines.caughtClean), findsOneWidget);
      expect(find.text(M3FuseRatingLines.caughtTie), findsOneWidget);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('coworker: listening to him puts thick copper in — deadly: freeze first, then the card', (t) async {
      final (c, _) = await open(t, _seedCalling(0));
      await _pump(t, 3500);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      final wrong = _onScreen(M3FuseRatingLines.coworker.wrong);
      expect(wrong, hasLength(2));
      await t.tap(wrong.first, warnIfMissed: false);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, M3FuseRatingMistakes.thickCopper.key);
      expect(s.mistakes.single.deadly, isTrue);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('mistakes: plain wire is a slip and goes aside; a slack tie is a slip and the barrel comes again', (t) async {
      final (c, deal) = await open(t, _seedCalling(2));
      final r1 = deal.rounds[0];
      await lift(t, r1, _of(r1, M3FuseRatingKind.plain));
      await t.tap(find.text(M3FuseRatingLines.take));
      await _pump(t, 600);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(find.text(M3FuseRatingMistakes.plainWire.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.text(M3FuseRatingLines.rejected), findsOneWidget);

      await lift(t, r1, r1.right);
      await t.tap(find.text(M3FuseRatingLines.take));
      await _pump(t, 800);
      await barrel(t, const {}, pull: false);
      expect(find.text(M3FuseRatingMistakes.looseTie.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      await barrel(t, const {});
      await _pump(t, 2500);
      await _pickRight(t, M3FuseRatingLines.right(r1));
      await _pump(t, 3500);
      expect(reels, findsNWidgets(4), reason: 'on to DTR 2');
      expect(c.read(gameSaveProvider).mistakes.length, 2);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('three slips fail the level: the struck-out card insists on the lesson', (t) async {
      final (c, deal) = await open(t, _seedCalling(2));
      final r1 = deal.rounds[0];
      for (final x in [_of(r1, M3FuseRatingKind.plain), _wrongLink(r1)]) {
        await lift(t, r1, x);
        await t.tap(find.text(M3FuseRatingLines.take));
        await _pump(t, 600);
        expect(find.text(MistakeLines.slipHead), findsOneWidget);
        await t.tap(find.text(MistakeLines.gotIt));
        await _pump(t, 400);
      }
      await lift(t, r1, r1.right);
      await t.tap(find.text(M3FuseRatingLines.take));
      await _pump(t, 800);
      await barrel(t, const {}, pull: false);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.text(FrameLines.struckHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.levelScoreByRung.containsKey('3.4/do/0'), isTrue);
      expect(s.rungProgress['3.4/do/0'], isNot('cleared'));
      expect(t.takeException(), isNull);
      await close(t, c);
    });
  });
}
