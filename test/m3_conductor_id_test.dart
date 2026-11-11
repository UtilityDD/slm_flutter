// Lesson 3.1, কাজ 1 (কোন তার কোনটা): rules of the yard (identify before
// loading, the docket's conductor, a cut strand found by hand, telling the
// store), deal variety, fair reason libraries, the close look (grime, magnet,
// wraps), and the level in the shell (idle perf; guide first; a full clean
// flow with the docket, the coworker refused, a cut drum set aside, the store
// told, the reasons; slip cards; listening to him; three slips).
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
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m3_conductor_id.dart';
import 'package:slm_flutter/features/game/m3_conductor_id_world.dart';
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
  rungId: '3.1/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '3.1',
  lessonTitleBn: '',
  ladderStep: 60,
  doIndex: 1,
  doCount: 2,
);

typedef _Drum = M3ConductorIdDrum;
typedef _Round = M3ConductorIdRound;

_Drum _good(_Round r) => r.drums.firstWhere((d) => d.kind == r.job.need && !d.cut);
_Drum _other(_Round r) => r.drums.firstWhere((d) => d.kind != r.job.need);
_Drum _cut(_Round r) => r.drums.firstWhere((d) => d.kind == r.job.need && d.cut);

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

int _seed({int? call, int? hold, bool? strand}) {
  for (var s = 0;; s++) {
    final d = m3ConductorIdDeal(math.Random(s));
    if (call != null && d.callRound != call) continue;
    if (hold != null && !d.rounds[hold].noneFits) continue;
    if (strand != null && d.preferStrand != strand) continue;
    return s;
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
    test('every deal: three jobs with both conductors; exactly one has no good drum; every row has the other conductor', () {
      for (var s = 0; s < 100; s++) {
        final d = m3ConductorIdDeal(math.Random(s));
        expect(d.rounds.length, 3);
        expect(d.rounds.map((r) => r.job.need).toSet(), M3ConductorIdKind.values.toSet());
        expect(d.rounds.where((r) => r.noneFits), hasLength(1));
        for (final r in d.rounds) {
          expect(r.drums.length, 3);
          expect(r.drums.any((x) => x.kind != r.job.need), isTrue);
          if (r.noneFits) {
            expect(r.drums.where((x) => x.kind == r.job.need), everyElement(predicate<_Drum>((x) => x.cut)));
            expect(r.drums.any((x) => x.kind == r.job.need), isTrue, reason: 'a cut drum of the right conductor to find');
          } else {
            expect(r.drums.where((x) => x.kind == r.job.need && !x.cut), hasLength(1));
          }
          final where = r.job.need == M3ConductorIdKind.aaac ? M3ConductorIdLines.aaacWhere : M3ConductorIdLines.acsrWhere;
          expect(where, contains(r.job.whereBn));
          for (final x in r.drums) {
            expect(m3ConductorIdLayouts[x.kind], contains(x.layout));
            expect(x.layout.steelRings > 0, x.kind == M3ConductorIdKind.acsr, reason: 'only ACSR has a steel core');
            if (x.cut) expect(x.cutU, inInclusiveRange(0.1, 0.9));
          }
        }
        expect(d.rounds.map((r) => r.job.feederBn).toSet().length, 3);
      }
    });

    test('a clean play: identify, load, wait for the reason; the store told on the job with no good drum', () {
      final run = M3ConductorIdRun(m3ConductorIdDeal(math.Random(3)));
      for (var i = 0; i < 3; i++) {
        final r = run.current;
        if (r.noneFits) {
          expect(run.holdJob().verdict, M3ConductorIdVerdict.right);
        } else {
          final g = _good(r);
          expect(run.magnet(g), g.kind == M3ConductorIdKind.acsr);
          expect(run.load(g).verdict, M3ConductorIdVerdict.right);
          expect(run.loaded[i], g);
        }
        expect(run.shown, isTrue);
        expect(run.round, i, reason: 'moves on only after the reason');
        expect(run.holdJob().verdict, M3ConductorIdVerdict.slip, reason: 'nothing more on a decided job');
        run.next();
      }
      expect(run.passed, isTrue);
      expect(run.percent, 100);
      expect(run.loaded.length, 2);
      expect(run.caught, containsAll([M3ConductorIdLines.caughtMagnet, M3ConductorIdLines.caughtLoad, M3ConductorIdLines.caughtHold]));
    });

    test('the other conductor loaded is a slip (the docket\'s card), and it gets chalked; a guess is a slip and stays', () {
      final run = M3ConductorIdRun(m3ConductorIdDeal(math.Random(_seed(hold: 2))));
      final r = run.current;
      final o = run.load(_other(r));
      expect(o.verdict, M3ConductorIdVerdict.slip);
      expect(o.mistake!.key, M3ConductorIdMistakes.wrongKind(r.job.need).key);
      expect(o.mistake!.deadly, isFalse);
      expect(run.checked, contains(_other(r).id));
      final g = _good(r);
      expect(run.load(g).mistake, M3ConductorIdMistakes.unchecked);
      expect(run.rejected, isNot(contains(g.id)), reason: 'a right drum goes back in the row');
      run.sawCore(g);
      expect(run.load(g).verdict, M3ConductorIdVerdict.right);
      expect(run.slips, 2);
      expect(run.caught, contains(M3ConductorIdLines.caughtCore));
    });

    test('a cut strand: loading it is a slip and it goes aside; found by hand, putting it back sets it aside for free', () {
      final s = _seed(hold: 0);
      final a = M3ConductorIdRun(m3ConductorIdDeal(math.Random(s)));
      final c = _cut(a.current);
      a.magnet(c);
      final o = a.load(c);
      expect(o.mistake, M3ConductorIdMistakes.cutStrand);
      expect(a.rejected, contains(c.id));
      expect(a.holdJob().verdict, M3ConductorIdVerdict.right);

      final b = M3ConductorIdRun(m3ConductorIdDeal(math.Random(s)));
      final c2 = _cut(b.current);
      expect(b.putBack(c2), isFalse, reason: 'not looked for: putting back gives nothing away');
      expect(b.putBack(_other(b.current)), isFalse);
      b.spot(_other(b.current));
      expect(b.spotted, isEmpty);
      b.spot(c2);
      expect(b.putBack(c2), isTrue);
      expect(b.slips, 0);
      expect(b.caught, contains(M3ConductorIdLines.caughtCut));
      b.holdJob();
      b.next();
      expect(b.spotted, isEmpty);
      expect(b.rejected, isEmpty);
      expect(b.checked, isEmpty);
    });

    test('telling the store when a good drum stands in the row is a slip', () {
      final run = M3ConductorIdRun(m3ConductorIdDeal(math.Random(_seed(hold: 2))));
      expect(run.holdJob().mistake, M3ConductorIdMistakes.heldWhenRight);
      expect(run.slips, 1);
    });

    test('the coworker pushes only a drum still in the row', () {
      const al = M3ConductorIdLayout(rings: [1, 6], steelRings: 0);
      const st = M3ConductorIdLayout(rings: [1, 6], steelRings: 1);
      const r = M3ConductorIdRound(
        job: M3ConductorIdJob(need: M3ConductorIdKind.aaac, feederBn: 'f', whereBn: 'w'),
        drums: [
          _Drum(id: 'o', kind: M3ConductorIdKind.acsr, layout: st),
          _Drum(id: 'g', kind: M3ConductorIdKind.aaac, layout: al),
          _Drum(id: 'c', kind: M3ConductorIdKind.aaac, layout: al, cutU: 0.4),
        ],
      );
      expect(m3ConductorIdPushFor(r, {}, preferStrand: true), M3ConductorIdPush.strand);
      expect(m3ConductorIdPushFor(r, {}, preferStrand: false), M3ConductorIdPush.nearest);
      expect(m3ConductorIdPushFor(r, {'c'}, preferStrand: true), M3ConductorIdPush.nearest);
      expect(m3ConductorIdPushed(r, M3ConductorIdPush.nearest, {})!.id, 'o');
      expect(m3ConductorIdPushed(r, M3ConductorIdPush.strand, {})!.id, 'c');
      expect(m3ConductorIdPushed(r, M3ConductorIdPush.strand, {'c'}), isNull);
    });

    test('deals vary', () {
      final deals = [for (var s = 0; s < 60; s++) m3ConductorIdDeal(math.Random(s))];
      expect(deals.map((d) => d.rounds.map((r) => r.job.need.index).join()).toSet().length, greaterThan(3));
      expect(deals.map((d) => d.rounds.indexWhere((r) => r.noneFits)).toSet(), {0, 1, 2});
      expect(deals.map((d) => d.callRound).toSet(), {0, 1, 2});
      expect(deals.map((d) => d.preferStrand).toSet(), {true, false});
      expect(deals.map((d) => d.rounds.first.job.whereBn).toSet().length, greaterThan(3));
      expect(deals.expand((d) => d.rounds).expand((r) => r.drums).map((x) => x.layout).toSet().length, 4);
    });

    test('the close look: the core shows once the centre is clean; a cut strand only where the hand has been', () {
      expect(M3ConductorIdEndPainter.coreSeen({}), isFalse);
      expect(M3ConductorIdEndPainter.coreSeen(M3ConductorIdEndPainter.coreCells), isTrue);
      expect(M3ConductorIdEndPainter.coreSeen(null), isTrue);
      const s = Size(120, 120);
      expect(M3ConductorIdEndPainter.coreCells, contains(M3ConductorIdEndPainter.cellAt(s, const Offset(60, 60))));
      expect(M3ConductorIdEndPainter.cellAt(s, Offset.zero), 0);
      expect(M3ConductorIdEndPainter.cellAt(s, const Offset(119, 119)), kM3ConductorIdGrid * kM3ConductorIdGrid - 1);
      for (final u in [0.15, 0.5, 0.85]) {
        expect(M3ConductorIdWrapPainter.cutSeen(u, {}), isFalse);
        expect(M3ConductorIdWrapPainter.cutSeen(u, {m3ConductorIdBin(u)}), isTrue);
        final far = {for (var i = 0; i < kM3ConductorIdBins; i++) if ((i - m3ConductorIdBin(u)).abs() > 2) i};
        expect(M3ConductorIdWrapPainter.cutSeen(u, far), isFalse);
      }
      expect(M3ConductorIdWrapPainter.cutSeen(null, null), isFalse);
      const w = Size(300, 70);
      expect(M3ConductorIdWrapPainter.uAt(w, M3ConductorIdWrapPainter.xAt(w, 0.4)), closeTo(0.4, 0.001));
    });

    test('reason and choice libraries: same length, big enough; his exit line is recorded; the mistakes book', () {
      expectSameLength('load', [for (final k in M3ConductorIdKind.values) ...[...M3ConductorIdLines.loadRight(k), ...M3ConductorIdLines.loadWrong(k)]]);
      for (final k in M3ConductorIdKind.values) {
        expectLibrary('load ${k.name}', M3ConductorIdLines.loadRight(k), M3ConductorIdLines.loadWrong(k));
        for (final w in M3ConductorIdLines.loadWrong(k)) {
          expect(M3ConductorIdLines.loadRight(k).contains(w), isFalse);
        }
      }
      expectSameLength('hold', [...M3ConductorIdLines.holdRight, ...M3ConductorIdLines.holdWrong]);
      expectLibrary('hold', M3ConductorIdLines.holdRight, M3ConductorIdLines.holdWrong);
      for (final p in M3ConductorIdPush.values) {
        final c = M3ConductorIdLines.coworker(p);
        expectSameLength('choice ${p.name}', [...c.right, ...c.wrong]);
        expectLibrary('choice ${p.name}', c.right, c.wrong);
        expect(LearnVoice.resolve(c.exitLine, rival: true), isNotNull);
      }
      final all = M3ConductorIdMistakes.all;
      expect(all.map((m) => m.key).toSet().length, all.length);
      for (final m in all) {
        expect(m.art, startsWith('assets/game/art/m3_conductor_id/'));
        expect(m.lessonPoint, inInclusiveRange(0, 3));
        expect(m.key, startsWith('3.1/m3_conductor_id/'));
        expect(m.deadly, isFalse);
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

    Future<(ProviderContainer, M3ConductorIdDeal)> open(WidgetTester t, int seed) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      final deal = m3ConductorIdDeal(math.Random(seed));
      final c = ProviderContainer();
      final nav = GlobalKey<NavigatorState>();
      await t.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
      ));
      unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
        builder: (_) => M3ConductorIdPage(ctx: _ctx, pack: m3ConductorIdPack31, muted: true, seed: seed),
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

    final drums = _label(M3ConductorIdLines.drumLabel);

    Future<void> lift(WidgetTester t, _Round r, _Drum d) async {
      await t.tap(drums.at(r.drums.indexOf(d)), warnIfMissed: false);
      await _pump(t, 600);
      expect(find.text(M3ConductorIdLines.load), findsOneWidget);
    }

    Future<void> slideWrap(WidgetTester t) async {
      final box = t.getRect(_label(M3ConductorIdLines.wrapLabel));
      final g = await t.startGesture(Offset(box.left + 2, box.center.dy));
      for (var i = 1; i <= 24; i++) {
        await g.moveTo(Offset(box.left + 2 + (box.width - 4) * i / 24, box.center.dy));
        await t.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await t.pump(const Duration(milliseconds: 100));
    }

    Future<void> rubFace(WidgetTester t) async {
      final box = t.getRect(_label(M3ConductorIdLines.faceLabel));
      final g = await t.startGesture(box.center - const Offset(10, 0));
      for (var i = 0; i < 6; i++) {
        await g.moveTo(box.center + Offset(i.isEven ? 10 : -10, 4.0 * (i - 3)));
        await t.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await t.pump(const Duration(milliseconds: 100));
    }

    for (final reduce in [false, true]) {
      testWidgets('waits quietly in the yard (${reduce ? 'reduce' : 'anim'})', (t) async {
        t.view.physicalSize = const Size(720, 1600);
        t.view.devicePixelRatio = 2.0;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        await t.pumpWidget(ProviderScope(
          child: MaterialApp(home: M3ConductorIdPage(ctx: _ctx, pack: m3ConductorIdPack31, muted: true, seed: _seed(call: 2))),
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
        debugPrint('PERF m3 conductor id ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
        expect(t.takeException(), isNull);
        expect(find.textContaining('ধাপ '), findsOneWidget);
        expect(find.text(M3ConductorIdLines.docket), findsOneWidget);
        expect(find.text(M3ConductorIdLines.hold), findsOneWidget);
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
      final seed = _seed(call: 2);
      final deal = m3ConductorIdDeal(math.Random(seed));
      final c = ProviderContainer();
      await t.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: MaterialApp(home: M3ConductorIdPage(ctx: _ctx, pack: m3ConductorIdPack31, muted: true, seed: seed)),
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
        expect(line, contains(M3ConductorIdLines.ask(deal.rounds.first.job.need)));
        heard.add(line);
      }
      expect(heard.length, 3, reason: 'a different way each time');
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('flow: refuse the coworker, docket, rub and magnet, cut drum aside, tell the store → pass', (t) async {
      final seed = _seed(call: 0);
      final (c, deal) = await open(t, seed);

      await _pump(t, 3500);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      await _pickRight(t, [...M3ConductorIdLines.coworkerNearest.right, ...M3ConductorIdLines.coworkerStrand.right]);
      await _pump(t, 2500);
      expect(find.byType(CoworkerPeek), findsNothing);

      await t.tap(find.text(M3ConductorIdLines.docket));
      await _pump(t, 500);
      expect(find.textContaining(deal.rounds.first.job.feederBn), findsOneWidget);
      await t.tapAt(const Offset(20, 760));
      await _pump(t, 400);
      expect(find.textContaining(deal.rounds.first.job.feederBn), findsNothing);

      for (var i = 0; i < 3; i++) {
        final r = deal.rounds[i];
        if (r.noneFits) {
          await lift(t, r, _cut(r));
          await slideWrap(t);
          await t.tap(find.text(M3ConductorIdLines.putBack));
          await _pump(t, 800);
          expect(find.text(M3ConductorIdLines.rejected), findsOneWidget, reason: 'the cut drum is tagged');
          await t.tap(find.text(M3ConductorIdLines.hold));
          await _pump(t, 3500);
          await _pickRight(t, M3ConductorIdLines.holdRight);
          await _pump(t, i == 2 ? 6000 : 4000);
          continue;
        }
        final g = _good(r);
        await lift(t, r, g);
        if (i.isEven) {
          await t.tap(_label(M3ConductorIdLines.magnetLabel));
          await _pump(t, 1200);
          expect(c.read(guideDirectorProvider).line, g.kind == M3ConductorIdKind.acsr ? M3ConductorIdLines.stuck : M3ConductorIdLines.fell);
        } else {
          await rubFace(t);
        }
        await slideWrap(t);
        await t.tap(find.text(M3ConductorIdLines.load));
        await _pump(t, 3500);
        expect(find.text(MistakeLines.slipHead), findsNothing);
        await _pickRight(t, M3ConductorIdLines.loadRight(r.job.need));
        await _pump(t, i == 2 ? 6000 : 3500);
      }

      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['3.1/do/0'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['3.1/do/0'], greaterThan(0));
      expect(find.text(M3ConductorIdLines.caughtCall), findsOneWidget);
      expect(find.text(M3ConductorIdLines.caughtHold), findsOneWidget);
      expect(find.text(M3ConductorIdLines.caughtCut), findsOneWidget);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('coworker: listening to him loads what he pushed — a slip card, never deadly', (t) async {
      final seed = _seed(call: 0);
      final (c, deal) = await open(t, seed);
      await _pump(t, 3500);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      final push = m3ConductorIdPushFor(deal.rounds.first, {}, preferStrand: deal.preferStrand)!;
      final wrong = _onScreen(M3ConductorIdLines.coworker(push).wrong);
      expect(wrong, hasLength(2));
      await t.tap(wrong.first, warnIfMissed: false);
      await _pump(t, 1500);
      final mk = push == M3ConductorIdPush.nearest ? M3ConductorIdMistakes.wrongKind(deal.rounds.first.job.need) : M3ConductorIdMistakes.cutStrand;
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(find.text(mk.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes, isNotEmpty);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('mistakes: the other conductor is a slip card and then chalked; a guess is a slip card', (t) async {
      final (c, deal) = await open(t, _seed(call: 2, hold: 2));
      final r = deal.rounds[0];
      await lift(t, r, _other(r));
      await t.tap(find.text(M3ConductorIdLines.load));
      await _pump(t, 600);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(find.text(M3ConductorIdMistakes.wrongKind(r.job.need).textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.text(_other(r).kind.tag), findsWidgets, reason: 'his chalk mark on the drum');

      await lift(t, r, _good(r));
      await t.tap(find.text(M3ConductorIdLines.load));
      await _pump(t, 600);
      expect(find.text(M3ConductorIdMistakes.unchecked.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.length, greaterThanOrEqualTo(2));
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('three slips fail the level: the struck-out card insists on the lesson', (t) async {
      final (c, _) = await open(t, _seed(call: 2, hold: 2));
      for (var i = 0; i < 2; i++) {
        await t.tap(find.text(M3ConductorIdLines.hold));
        await _pump(t, 600);
        expect(find.text(MistakeLines.slipHead), findsOneWidget, reason: 'slip ${i + 1} shows its card');
        await t.tap(find.text(MistakeLines.gotIt));
        await _pump(t, 400);
      }
      await t.tap(find.text(M3ConductorIdLines.hold));
      await _pump(t, 800);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.text(FrameLines.struckHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.levelScoreByRung.containsKey('3.1/do/0'), isTrue);
      expect(s.rungProgress['3.1/do/0'], isNot('cleared'));
      expect(t.takeException(), isNull);
      await close(t, c);
    });
  });
}
