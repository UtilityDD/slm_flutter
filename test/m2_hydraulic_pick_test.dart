// Lesson 2.9, কাজ 1 (দানবের যত্ন): rules of the tool store (choose the tool,
// the close look, the die case, pump to the click, the cutter's safety lock),
// deal variety, fair reason libraries, the coworker's pushes, and the level in
// the shell (idle perf; a full clean flow; a slip card; the coworker heard;
// three slips fail). Audit 2026-11-11: listening is always a slip; a fast
// take / last stroke waits for him; pumping on while he talks refuses him and
// the reason deck never opens over his deck; letting go while he says so is
// listening; the hold waits for him and a die put in while he talks is
// listening; the leaking tool never summons him (no giveaway); with the die
// lost he comes only on the hold, never on his timer at the die case; in his
// beat 1 every pegboard hook answers the same; a put-back gets one neutral
// line; the idle gesture hint sweeps over every tool.
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
import 'package:slm_flutter/features/game/gesture_hint.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_frame.dart' show FrameLines, StruckOutCard;
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m2_hydraulic_pick.dart';
import 'package:slm_flutter/features/game/m2_hydraulic_pick_world.dart';
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
  rungId: '2.9/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '2.9',
  lessonTitleBn: '',
  ladderStep: 40,
  doIndex: 1,
  doCount: 2,
);

/// This level's mistake pictures are not in pubspec yet (the director adds
/// the folder): the test serves them from disk.
class _DiskBundle extends CachingAssetBundle {
  static const _dir = 'assets/game/art/m2_hydraulic_pick/';
  @override
  Future<ByteData> load(String key) async {
    if (key.startsWith(_dir)) return ByteData.sublistView(File(key).readAsBytesSync());
    return rootBundle.load(key);
  }
}

HydTool _right(HydRoundDeal r) => r.tools.firstWhere((t) => r.fits(t) && t.flaw == HydFlaw.none);
HydTool _twin(HydRoundDeal r) => r.tools.firstWhere((t) => r.fits(t) && t.flaw != HydFlaw.none);

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

int _seedWhere(bool Function(HydDeal d) ok) {
  for (var s = 0;; s++) {
    if (ok(dealHyd(math.Random(s)))) return s;
  }
}

Finder _label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);
List<Finder> _onScreen(List<String> texts) => [
      for (final x in texts)
        if (find.text(x).evaluate().isNotEmpty) find.text(x),
    ];

Future<void> _pickRight(WidgetTester t, List<String> right) async {
  await waitChoiceDeck(t);
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = _onScreen(right);
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
  await confirmChoice(t);
  // The reason card zooms and waits for proceed (coworker decks have none).
  await tapReasonProceed(t);
}

/// A play where he comes on docket 1 to say "let go" mid-crimp (no leaking
/// tool to push first).
bool _releaseFirst(HydDeal d) => d.callRound == 0 && d.push == HydPush.release && _twin(d.rounds[0]).flaw != HydFlaw.leak;

/// Plays one docket clean in pure logic.
void _playClean(HydRun run) {
  final r = run.current;
  expect(run.take(_right(r)).verdict, HydVerdict.right);
  if (r.crimp) {
    if (r.dieMissing) {
      expect(run.holdJob().verdict, HydVerdict.right);
      return;
    }
    expect(run.pickDie(r.docket.size).verdict, HydVerdict.right);
  } else {
    run.toggleLock();
  }
  for (var i = 1; i < kHydStrokes; i++) {
    expect(run.stroke().verdict, HydVerdict.more);
  }
  expect(run.stroke().verdict, HydVerdict.right);
}

void main() {
  group('rules', () {
    test('every deal: crimp, cut, crimp; one sound tool for the job and one faulty twin; the coworker is dealt', () {
      for (var s = 0; s < 80; s++) {
        final d = dealHyd(math.Random(s));
        expect(d.rounds.map((r) => r.docket.job).toList(), [HydJob.crimp, HydJob.cut, HydJob.crimp]);
        for (final r in d.rounds) {
          expect(r.tools.where((t) => r.fits(t) && t.flaw == HydFlaw.none).length, 1);
          expect(r.tools.where((t) => r.fits(t) && t.flaw != HydFlaw.none).length, 1);
          expect(r.tools.where((t) => !t.kind.hydraulic).length, 1, reason: 'one hand tool / hacksaw decoy');
          for (final t in r.tools) {
            if (t.flaw == HydFlaw.battery) expect(t.kind, HydKind.batteryCrimper);
            if (t.flaw == HydFlaw.pump) expect(t.kind, isNot(HydKind.batteryCrimper));
          }
          if (r.crimp) {
            expect(r.slots, contains(r.docket.size));
            expect(r.slots.length, 5);
          }
        }
        expect(d.rounds[0].dieMissing, isFalse);
        expect(d.callRound, inInclusiveRange(0, 2));
        if (d.push == HydPush.leak) expect(_twin(d.rounds[d.callRound]).flaw, HydFlaw.leak);
        if (d.push == HydPush.die) {
          expect(d.callRound, 2);
          expect(d.rounds[2].dieMissing, isTrue);
        }
        if (d.push == HydPush.release) expect(d.rounds[d.callRound].crimp, isTrue);
        // Sizes stay within what the lesson names (50 to 400/630 sq mm).
        for (final r in d.rounds) {
          expect(r.docket.size, inInclusiveRange(50, 630));
        }
      }
    });

    test('a clean play: tool, die, pump to the click; lock and cut; each waits for its reason', () {
      final run = HydRun(dealHyd(math.Random(3)));
      _playClean(run);
      expect(run.shown, isTrue);
      expect(run.round, 0, reason: 'the docket moves on only after the reason');
      expect(run.stroke().verdict, HydVerdict.more, reason: 'nothing more on a decided docket');
      run.next();
      expect(run.stage, HydStage.tool);
      _playClean(run);
      run.next();
      _playClean(run);
      run.next();
      expect(run.passed, isTrue);
      expect(run.percent, 100);
      expect(run.caught, containsAll([HydLines.caughtDie, HydLines.caughtClick, HydLines.caughtLock]));
    });

    test('the wrong tool is a slip: hand crimper, hacksaw, a tool for the other job, a faulty tool', () {
      final run = HydRun(dealHyd(math.Random(5)));
      var r = run.current;
      expect(run.take(r.tools.firstWhere((t) => t.kind == HydKind.handCrimper)).mistake, HydMistakes.handTool);
      expect(run.take(r.tools.firstWhere((t) => t.kind == HydKind.cutter)).mistake, HydMistakes.wrongJob);
      final twin = _twin(r);
      expect(run.take(twin).mistake, HydMistakes.forFlaw(twin.flaw));
      expect(run.rejected, contains(twin.id), reason: 'a faulty tool taken goes to servicing');
      expect(run.slips, 3);
      expect(run.stage, HydStage.tool);
      run.next();
      r = run.current;
      expect(run.take(r.tools.firstWhere((t) => t.kind == HydKind.hacksaw)).mistake, HydMistakes.hacksaw);
      expect(run.take(r.tools.firstWhere((t) => t.kind.crimps)).mistake, HydMistakes.wrongJob);
    });

    test('the die: a near size is a slip; holding with the die there is a slip; a lost die → hold', () {
      final seed = _seedWhere((d) => d.rounds[2].dieMissing);
      final run = HydRun(dealHyd(math.Random(seed)));
      final r = run.current;
      run.take(_right(r));
      expect(run.stage, HydStage.die);
      expect(run.pickDie(hydNearDie(r)).mistake, HydMistakes.wrongDie);
      expect(run.holdJob().mistake, HydMistakes.heldWhenDie);
      expect(run.pickDie(r.docket.size).verdict, HydVerdict.right);
      run.round = 2;
      run.stage = HydStage.tool;
      final r3 = run.current;
      run.take(_right(r3));
      expect(r3.dies, isNot(contains(r3.docket.size)));
      expect(run.pickDie(r3.docket.size).verdict, HydVerdict.slip, reason: 'a lost die cannot be picked');
      expect(run.holdJob().verdict, HydVerdict.right);
      expect(run.caught, contains(HydLines.caughtHold));
    });

    test('pump: letting go before the click is a weak crimp; pumping the cutter unlocked is a slip', () {
      final run = HydRun(dealHyd(math.Random(9)));
      final r = run.current;
      run.take(_right(r));
      run.pickDie(r.docket.size);
      expect(run.release().verdict, HydVerdict.more, reason: 'nothing to let go yet');
      run.stroke();
      run.stroke();
      expect(run.release().mistake, HydMistakes.halfCrimp);
      expect(run.pressure, 0, reason: 'start again');
      run
        ..round = 0
        ..next();
      run.take(_right(run.current));
      expect(run.stroke().mistake, HydMistakes.noLock);
      run.toggleLock();
      expect(run.locked, isTrue);
      expect(run.stroke().verdict, HydVerdict.more);
      expect(run.slips, 2);
    });

    test('putting back: a tool whose fault was found goes aside for free; anything else back on its hook', () {
      final run = HydRun(dealHyd(math.Random(11)));
      final r = run.current;
      final twin = _twin(r);
      expect(run.putBack(_right(r)), isFalse);
      expect(run.putBack(twin), isFalse, reason: 'not looked at: gives nothing away');
      run.spot(_right(r));
      expect(run.spotted, isEmpty);
      run.spot(twin);
      expect(run.putBack(twin), isTrue);
      expect(run.slips, 0);
      expect(run.caught, contains(twin.flaw == HydFlaw.battery ? HydLines.caughtCharge : HydLines.caughtService));
    });

    test('the close look: a leak shows only where the finger has been; a sticking pump only after a stroke', () {
      final all = {for (var i = 0; i < kHydBins; i++) i};
      expect(HydToolPainter.flawSeen(HydFlaw.leak, {}, stroked: true), isFalse);
      expect(HydToolPainter.flawSeen(HydFlaw.leak, {hydBin(kHydLeakU)}, stroked: false), isTrue);
      expect(HydToolPainter.flawSeen(HydFlaw.leak, {kHydBins - 1}, stroked: false), isFalse);
      expect(HydToolPainter.flawSeen(HydFlaw.pump, all, stroked: false), isFalse);
      expect(HydToolPainter.flawSeen(HydFlaw.pump, {}, stroked: true), isTrue);
      expect(HydToolPainter.flawSeen(HydFlaw.battery, {}, stroked: false), isTrue, reason: 'the gauge reads at a glance');
      expect(HydToolPainter.flawSeen(HydFlaw.none, all, stroked: true), isFalse);
    });

    test('the coworker pushes only what is there now', () {
      final seed = _seedWhere((d) => d.rounds[2].dieMissing && _twin(d.rounds[0]).flaw == HydFlaw.leak);
      final run = HydRun(dealHyd(math.Random(seed)));
      expect(hydPushFor(run, prefer: HydPush.release), HydPush.leak);
      run.rejected.add(_twin(run.current).id);
      expect(hydPushFor(run, prefer: HydPush.leak), isNull, reason: 'the leaking tool is in the crate');
      run.take(_right(run.current));
      run.pickDie(run.current.docket.size);
      expect(hydPushFor(run, prefer: HydPush.leak), isNull, reason: 'release only once pumping');
      run.stroke();
      expect(hydPushFor(run, prefer: HydPush.leak), HydPush.release);
      run
        ..round = 1
        ..next();
      run.take(_right(run.current));
      expect(hydPushFor(run, prefer: HydPush.die), HydPush.die);
    });

    test('listening to him is always a slip, even when his act can no longer be done', () {
      final seed = _seedWhere((d) => _twin(d.rounds[0]).flaw == HydFlaw.leak);
      final run = HydRun(dealHyd(math.Random(seed)));
      final leak = _twin(run.current);
      expect(run.follow(HydPush.leak).mistake, HydMistakes.leak);
      expect(run.rejected, contains(leak.id), reason: 'the leaking tool goes to servicing');
      expect(run.follow(HydPush.leak).mistake, HydMistakes.leak, reason: 'no leaking tool left: still a slip');
      run.take(_right(run.current));
      run.pickDie(run.current.docket.size);
      run.stroke();
      expect(run.follow(HydPush.release).mistake, HydMistakes.halfCrimp);
      expect(run.pressure, 0);
      expect(run.follow(HydPush.release).verdict, HydVerdict.slip, reason: 'nothing pumped: still a slip');
      expect(run.follow(HydPush.die).mistake, HydMistakes.wrongDie);
      expect(run.slips, 5);
    });

    test('his moment: "let go" fits until the click; once nothing can fit on a docket he waits for the next', () {
      final run = HydRun(dealHyd(math.Random(_seedWhere(_releaseFirst))));
      expect(hydPushFor(run, prefer: HydPush.release), isNull);
      expect(hydPushLater(run), isTrue, reason: 'a crimp: letting go is still ahead');
      run.take(_right(run.current));
      run.pickDie(run.current.docket.size);
      expect(hydPushLater(run), isTrue);
      for (var i = 1; i < kHydStrokes; i++) {
        run.stroke();
        expect(hydPushFor(run, prefer: HydPush.release), HydPush.release, reason: 'pressure $i');
      }
      run.stroke();
      expect(run.shown, isTrue);
      expect(hydPushFor(run, prefer: HydPush.release), isNull);
      expect(hydPushLater(run), isFalse);
      run.next();
      expect(run.current.crimp, isFalse);
      run.take(_right(run.current));
      expect(hydPushLater(run), isFalse, reason: 'a cut: nothing more he can push');
    });

    test('deals vary', () {
      final deals = [for (var s = 0; s < 60; s++) dealHyd(math.Random(s))];
      expect(deals.map((d) => d.rounds[0].docket.size).toSet().length, 4);
      expect(deals.map((d) => d.rounds[1].docket.size).toSet(), {300, 400});
      expect(deals.map((d) => d.rounds[2].dieMissing).toSet(), {true, false});
      expect(deals.map((d) => d.callRound).toSet(), {0, 1, 2});
      expect(deals.map((d) => d.push).toSet(), HydPush.values.toSet());
      expect(deals.map((d) => _twin(d.rounds[1]).flaw).toSet(), {HydFlaw.leak, HydFlaw.pump});
      expect(deals.map((d) => _right(d.rounds[0]).kind).toSet(), {HydKind.crimper, HydKind.batteryCrimper});
    });

    test('reason and choice libraries: same length, big enough, fit what the docket had', () {
      final rounds = [
        for (var s = 0; s < 60; s++)
          for (final r in dealHyd(math.Random(s)).rounds) r,
      ];
      final crimps = rounds.where((r) => r.crimp).toList();
      expectSameLength('crimp', [for (final r in crimps) ...HydLines.crimpRight(r), for (final r in crimps) ...HydLines.crimpWrong(r)]);
      expectSameLength('cut', [...HydLines.cutRight, ...HydLines.cutWrong]);
      expectLibrary('cut', HydLines.cutRight, HydLines.cutWrong);
      expectSameLength('hold', [for (final r in crimps) ...HydLines.holdRight(r), for (final r in crimps) ...HydLines.holdWrong(r)]);
      for (final r in crimps) {
        expectLibrary('crimp ${r.docket.size}', HydLines.crimpRight(r), HydLines.crimpWrong(r));
        expectLibrary('hold ${r.docket.size}', HydLines.holdRight(r), HydLines.holdWrong(r));
        expect(HydLines.crimpWrong(r), isNot(contains(HydLines.dieMatch(r.docket.size))));
        expect(HydLines.holdWrong(r), isNot(contains(HydLines.holdMatch(r.docket.size))));
      }
      for (final p in HydPush.values) {
        final c = HydLines.coworker(p);
        expectSameLength('choice ${p.name}', [...c.right, ...c.wrong]);
        expectLibrary('choice ${p.name}', c.right, c.wrong);
        expect(LearnVoice.resolve(c.exitLine, rival: true), isNotNull, reason: 'his exit line is recorded');
      }
      expect(HydLines.recordLines, hasLength(3));
      for (final m in HydMistakes.all) {
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
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

    Future<(ProviderContainer, HydDeal)> open(WidgetTester t, int seed) async {
      t.view.physicalSize = const Size(720, 1600);
      t.view.devicePixelRatio = 2.0;
      final deal = dealHyd(math.Random(seed));
      final c = ProviderContainer();
      final nav = GlobalKey<NavigatorState>();
      await t.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: DefaultAssetBundle(
          bundle: _DiskBundle(),
          child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
        ),
      ));
      unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
        builder: (_) => M2HydraulicPage(ctx: _ctx, pack: m2HydraulicPack29a, muted: true, seed: seed),
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

    final tools = _label(HydLines.toolLabel);

    Future<void> lift(WidgetTester t, HydRoundDeal r, HydTool tool) async {
      await t.tap(tools.at(r.tools.indexOf(tool)), warnIfMissed: false);
      await _pump(t, 600);
      expect(find.text(HydLines.take), findsOneWidget);
    }

    /// Runs a finger along the whole body, then gives the pump a stroke.
    Future<void> lookOver(WidgetTester t, HydTool tool) async {
      final box = t.getRect(_label(HydLines.handLabel));
      final y = box.top + box.height * 0.6;
      final g = await t.startGesture(Offset(box.left + 2, y));
      for (var i = 1; i <= 24; i++) {
        await g.moveTo(Offset(box.left + 2 + (box.width - 4) * i / 24, y));
        await t.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await t.pump(const Duration(milliseconds: 100));
      final tryIt = find.text(tool.kind == HydKind.batteryCrimper ? HydLines.trigger : HydLines.pump);
      await t.tap(tryIt);
      await _pump(t, 700);
    }

    /// Does the job once the tool is taken (die, lock, pump to the click).
    Future<void> doJob(WidgetTester t, HydRoundDeal r, HydTool tool) async {
      if (r.crimp) {
        await t.tap(_label('${HydLines.dieLabel} ${r.docket.size}'));
        await _pump(t, 500);
      } else {
        await t.tap(find.text(HydLines.lock));
        await _pump(t, 300);
      }
      final p = find.text(tool.kind == HydKind.batteryCrimper ? HydLines.trigger : HydLines.pump);
      for (var i = 0; i < kHydStrokes; i++) {
        await t.tap(p);
        await _pump(t, 300);
      }
    }

    for (final reduce in [false, true]) {
      testWidgets('waits quietly in the store (${reduce ? 'reduce' : 'anim'})', (t) async {
        t.view.physicalSize = const Size(720, 1600);
        t.view.devicePixelRatio = 2.0;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        await t.pumpWidget(ProviderScope(
          child: MaterialApp(home: M2HydraulicPage(ctx: _ctx, pack: m2HydraulicPack29a, muted: true, seed: _seedWhere((d) => d.callRound == 1))),
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
        debugPrint('PERF hydraulic pick ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
        expect(t.takeException(), isNull);
        expect(find.textContaining(RegExp(r'^L\d+$')), findsOneWidget);
        expect(find.text(HydLines.docket), findsOneWidget);
        expect(tools, findsNWidgets(4));
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
        child: MaterialApp(home: M2HydraulicPage(ctx: _ctx, pack: m2HydraulicPack29a, muted: true, seed: _seedWhere((d) => d.callRound == 2))),
      ));
      await _pump(t, 400);
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.textContaining(RegExp('শুরু')), findsNothing, reason: 'no start button of any wording');
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
        expect(line, contains(HydLines.ask));
        heard.add(line);
      }
      expect(heard.length, 3, reason: 'a different way each time');
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('flow: refuse the coworker, faulty tool to servicing, die, pump to the click, lock and cut, reasons → pass', (t) async {
      final seed = _seedWhere((d) => d.callRound == 0 && d.push == HydPush.leak);
      final (c, deal) = await open(t, seed);

      // He peeps in on the first docket with the leaking tool; refuse him.
      await _pump(t, 3500);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      expect(find.text(HydLines.coworkerLeak.line), findsOneWidget);
      await _pickRight(t, HydLines.coworkerLeak.right);
      await _pump(t, 2500);
      expect(find.byType(CoworkerPeek), findsNothing);

      // The docket, read close.
      final r1 = deal.rounds[0];
      await t.tap(find.text(HydLines.docket));
      await _pump(t, 500);
      expect(find.text(HydLines.line(r1.docket)), findsOneWidget);
      await t.tapAt(const Offset(20, 760));
      await _pump(t, 400);

      for (var i = 0; i < 3; i++) {
        final r = deal.rounds[i];
        // The faulty twin, looked over: its fault shows, so it goes aside.
        final twin = _twin(r);
        await lift(t, r, twin);
        await lookOver(t, twin);
        await t.tap(find.text(HydLines.putBack));
        await _pump(t, 800);
        expect(find.text(twin.flaw == HydFlaw.battery ? HydLines.chargeTag : HydLines.serviceTag), findsOneWidget, reason: 'docket ${i + 1}');

        final tool = _right(r);
        await lift(t, r, tool);
        await lookOver(t, tool);
        await t.tap(find.text(HydLines.take));
        await _pump(t, 800);
        expect(find.text(MistakeLines.slipHead), findsNothing);
        if (r.dieMissing) {
          await t.tap(find.text(HydLines.hold));
          await _pump(t, 3500);
          await _pickRight(t, HydLines.holdRight(r));
        } else {
          await doJob(t, r, tool);
          if (r.crimp) expect(find.text(HydLines.click), findsOneWidget);
          await _pump(t, 3500);
          await _pickRight(t, r.crimp ? HydLines.crimpRight(r) : HydLines.cutRight);
        }
        await _pump(t, 4000);
      }
      await _pump(t, 3000);

      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['2.9/do/0'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['2.9/do/0'], greaterThan(0));
      expect(find.text(HydLines.caughtCall), findsOneWidget);
      expect(find.text(HydLines.caughtLock), findsOneWidget);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('coworker: taking the leaking tool on his word is a slip with its card', (t) async {
      final (c, _) = await open(t, _seedWhere((d) => d.callRound == 0 && d.push == HydPush.leak));
      await _pump(t, 3500);
      expect(find.byType(CoworkerPeek), findsOneWidget);
      final wrong = _onScreen(HydLines.coworkerLeak.wrong);
      expect(wrong, hasLength(2));
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 1500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(HydMistakes.leak.textBn), findsOneWidget);
      expect(find.text(HydLines.serviceTag), findsOneWidget, reason: 'the leaking tool goes to servicing');
      expect(c.read(gameSaveProvider).mistakes, isNotEmpty);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('gesture hint: idle in the store, the hand sweeps over every tool on the board, never one', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final (c, _) = await open(t, _seedWhere((d) => d.callRound == 1));
      expect(find.byType(IdleHint), findsWidgets);
      await _pump(t, 9000);
      final st = t.state<IdleHintState>(find.byType(IdleHint).first);
      expect(st.showing, isTrue);
      expect(st.debugOptions, hasLength(4), reason: 'a sweep over all four hooks');
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('coworker: a fast take does not skip him — the take waits until he has been answered', (t) async {
      final (c, deal) = await open(t, _seedWhere((d) => d.callRound == 0 && d.push == HydPush.leak));
      final r = deal.rounds[0];
      final tool = _right(r);
      // Straight to the sound tool and take it, before his timer.
      await t.tap(tools.at(r.tools.indexOf(tool)), warnIfMissed: false);
      await _pump(t, 300);
      expect(find.byType(CoworkerPeek), findsNothing);
      await t.tap(find.text(HydLines.take));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in on the decisive take');
      expect(find.text(HydLines.coworkerLeak.line), findsWidgets);
      expect(_label('${HydLines.dieLabel} ${r.docket.size}'), findsNothing, reason: 'the take waited');
      await _pickRight(t, HydLines.coworkerLeak.right);
      await _pump(t, 1500);
      expect(find.byType(CoworkerPeek), findsNothing);
      await t.tap(find.text(HydLines.take));
      await _pump(t, 800);
      expect(_label('${HydLines.dieLabel} ${r.docket.size}'), findsOneWidget, reason: 'now the take works');
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('coworker "let go": pumping on while he talks refuses him; the reason deck never opens over his deck', (t) async {
      CoworkerTiming.debugReadHoldInTests = true;
      addTearDown(() => CoworkerTiming.debugReadHoldInTests = false);
      final (c, deal) = await open(t, _seedWhere(_releaseFirst));
      final r = deal.rounds[0];
      final tool = _right(r);
      await lift(t, r, tool);
      await t.tap(find.text(HydLines.take));
      await _pump(t, 600);
      await t.tap(_label('${HydLines.dieLabel} ${r.docket.size}'));
      await _pump(t, 500);
      final p = find.text(tool.kind == HydKind.batteryCrimper ? HydLines.trigger : HydLines.pump);
      await t.tap(p);
      await _pump(t, 50);
      for (var i = 0; i < 80 && find.byType(CoworkerPeek).evaluate().isEmpty; i++) {
        await t.pump(const Duration(milliseconds: 50));
      }
      expect(find.byType(CoworkerPeek), findsOneWidget);
      expect(find.text(HydLines.coworkerRelease.line), findsWidgets);
      expect(find.byKey(const ValueKey('choice-deck')), findsNothing, reason: 'beat 1: he is still talking');
      // Pump on to the click while he talks.
      for (var i = 1; i < kHydStrokes; i++) {
        await t.tap(p, warnIfMissed: false);
        await _pump(t, 100);
      }
      expect(find.text(HydLines.click), findsOneWidget);
      await _pump(t, 1500);
      expect(find.byKey(const ValueKey('choice-deck')), findsNothing, reason: 'he left refused, no deck of his remains');
      expect(find.byKey(const ValueKey('why-deck')), findsOneWidget);
      // Taps in the praise / reason window never slip.
      await t.tap(find.text(HydLines.release), warnIfMissed: false);
      await _pump(t, 300);
      expect(find.byType(MistakeCard), findsNothing);
      await _pickRight(t, HydLines.crimpRight(r));
      await _pump(t, 2000);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('coworker "let go": letting go while he says so is listening — a slip with its card', (t) async {
      CoworkerTiming.debugReadHoldInTests = true;
      addTearDown(() => CoworkerTiming.debugReadHoldInTests = false);
      final (c, deal) = await open(t, _seedWhere(_releaseFirst));
      final r = deal.rounds[0];
      final tool = _right(r);
      await lift(t, r, tool);
      await t.tap(find.text(HydLines.take));
      await _pump(t, 600);
      await t.tap(_label('${HydLines.dieLabel} ${r.docket.size}'));
      await _pump(t, 500);
      await t.tap(find.text(tool.kind == HydKind.batteryCrimper ? HydLines.trigger : HydLines.pump));
      for (var i = 0; i < 80 && find.byType(CoworkerPeek).evaluate().isEmpty; i++) {
        await t.pump(const Duration(milliseconds: 50));
      }
      expect(find.byType(CoworkerPeek), findsOneWidget);
      await t.tap(find.text(HydLines.release), warnIfMissed: false);
      await _pump(t, 1200);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(HydMistakes.halfCrimp.textBn), findsOneWidget);
      expect(find.byKey(const ValueKey('choice-deck')), findsNothing);
      expect(c.read(gameSaveProvider).mistakes, isNotEmpty);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('coworker "let go": a fast last stroke waits for him; listening on his deck is a slip', (t) async {
      final (c, deal) = await open(t, _seedWhere(_releaseFirst));
      final r = deal.rounds[0];
      final tool = _right(r);
      await t.tap(tools.at(r.tools.indexOf(tool)), warnIfMissed: false);
      await _pump(t, 200);
      await t.tap(find.text(HydLines.take));
      await _pump(t, 200);
      await t.tap(_label('${HydLines.dieLabel} ${r.docket.size}'));
      await _pump(t, 200);
      final p = find.text(tool.kind == HydKind.batteryCrimper ? HydLines.trigger : HydLines.pump);
      var came = false;
      for (var i = 0; i < kHydStrokes && !came; i++) {
        await t.tap(p, warnIfMissed: false);
        await t.pump(const Duration(milliseconds: 30));
        came = find.byType(CoworkerPeek).evaluate().isNotEmpty;
      }
      expect(came, isTrue, reason: 'he comes before the click, however fast');
      expect(find.text(HydLines.click), findsNothing);
      await waitChoiceDeck(t);
      final wrong = _onScreen(HydLines.coworkerRelease.wrong);
      expect(wrong, hasLength(2));
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 1500);
      expect(find.text(HydMistakes.halfCrimp.textBn), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes, isNotEmpty);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    /// Plays one docket clean on the page, its reason included.
    Future<void> playDocket(WidgetTester t, HydRoundDeal r) async {
      final tool = _right(r);
      await lift(t, r, tool);
      await t.tap(find.text(HydLines.take));
      await _pump(t, 800);
      await doJob(t, r, tool);
      await _pump(t, 3500);
      await _pickRight(t, r.crimp ? HydLines.crimpRight(r) : HydLines.cutRight);
      await _pump(t, 4000);
    }

    testWidgets('coworker "near die": holding the job waits for him; a die put in while he talks is listening', (t) async {
      CoworkerTiming.debugReadHoldInTests = true;
      addTearDown(() => CoworkerTiming.debugReadHoldInTests = false);
      final (c, deal) = await open(t, _seedWhere((d) => d.callRound == 2 && d.push == HydPush.die && _twin(d.rounds[2]).flaw != HydFlaw.leak));
      await playDocket(t, deal.rounds[0]);
      await playDocket(t, deal.rounds[1]);
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'he is dealt on the last docket');
      final r = deal.rounds[2];
      expect(r.dieMissing, isTrue);
      await lift(t, r, _right(r));
      await t.tap(find.text(HydLines.take));
      await _pump(t, 300);
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'nothing he can push at the pegboard');
      // A die tap before he comes is simply wrong (no hold that names the lost die).
      // The hold is the decisive control: it waits for him.
      await t.tap(find.text(HydLines.hold));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in on the hold');
      expect(find.text(HydLines.coworkerDie.line), findsWidgets);
      expect(find.byKey(const ValueKey('why-deck')), findsNothing, reason: 'the hold waited');
      expect(find.byKey(const ValueKey('choice-deck')), findsNothing, reason: 'beat 1');
      // He says "the near one will do" — the player puts a die in: listened.
      await t.tap(_label('${HydLines.dieLabel} ${hydNearDie(r)}'), warnIfMissed: false);
      await _pump(t, 1200);
      expect(find.text(HydMistakes.wrongDie.textBn), findsOneWidget);
      expect(find.byKey(const ValueKey('choice-deck')), findsNothing);
      expect(c.read(gameSaveProvider).mistakes, isNotEmpty);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 400);
      // He has had his moment: the hold now goes straight to its reason.
      await t.tap(find.text(HydLines.hold));
      await _pump(t, 3500);
      expect(find.byType(CoworkerPeek), findsNothing);
      await _pickRight(t, HydLines.holdRight(r));
      await _pump(t, 5000);
      expect(c.read(gameSaveProvider).rungProgress['2.9/do/0'], 'cleared', reason: 'one slip: still a pass');
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    for (final push in [HydPush.die, HydPush.release]) {
      testWidgets('coworker, lost die (${push.name} dealt): he never comes on his timer at the die case, only on the hold', (t) async {
        CoworkerTiming.debugReadHoldInTests = true;
        addTearDown(() => CoworkerTiming.debugReadHoldInTests = false);
        final (c, deal) = await open(
          t,
          _seedWhere((d) => d.callRound == 2 && d.push == push && d.rounds[2].dieMissing && _twin(d.rounds[2]).flaw != HydFlaw.leak),
        );
        await playDocket(t, deal.rounds[0]);
        await playDocket(t, deal.rounds[1]);
        final r = deal.rounds[2];
        await lift(t, r, _right(r));
        await t.tap(find.text(HydLines.take));
        await _pump(t, 600);
        expect(_label('${HydLines.dieLabel} ${hydNearDie(r)}'), findsOneWidget, reason: 'at the die case');
        // Reading the die case a while: his "the right die isn't there?" would
        // give the lost die away, so his timer never brings him in here.
        await _pump(t, 4000);
        expect(find.byType(CoworkerPeek), findsNothing, reason: 'no arrival on his timer at the die case');
        expect(find.text(HydLines.coworkerDie.line), findsNothing);
        // The hold is the decisive control: he cuts in on it.
        await t.tap(find.text(HydLines.hold));
        await t.pump(const Duration(milliseconds: 100));
        expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in on the hold');
        expect(find.text(HydLines.coworkerDie.line), findsWidgets);
        expect(t.takeException(), isNull);
        await close(t, c);
      });
    }

    testWidgets('coworker beat 1: a tap on the leaking hook and on a sound hook answer the same — the pegboard waits', (t) async {
      CoworkerTiming.debugReadHoldInTests = true;
      addTearDown(() => CoworkerTiming.debugReadHoldInTests = false);
      final (c, deal) = await open(t, _seedWhere((d) => d.callRound == 0 && d.push == HydPush.leak));
      final r = deal.rounds[0];
      for (var i = 0; i < 100 && find.byType(CoworkerPeek).evaluate().isEmpty; i++) {
        await t.pump(const Duration(milliseconds: 50));
      }
      expect(find.byType(CoworkerPeek), findsOneWidget);
      expect(find.byKey(const ValueKey('choice-deck')), findsNothing, reason: 'beat 1');
      for (final tool in [_twin(r), _right(r)]) {
        await t.tap(tools.at(r.tools.indexOf(tool)), warnIfMissed: false);
        await _pump(t, 300);
        expect(find.text(HydLines.take), findsNothing, reason: '${tool.flaw.name}: no close look while he talks');
        expect(find.byType(CoworkerPeek), findsOneWidget, reason: '${tool.flaw.name}: he is still there');
        expect(find.text(HydLines.coworkerLeak.line), findsWidgets, reason: '${tool.flaw.name}: still talking');
        expect(find.byType(MistakeCard), findsNothing);
      }
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      // His deck still decides.
      await _pickRight(t, HydLines.coworkerLeak.right);
      await _pump(t, 1500);
      expect(find.byType(CoworkerPeek), findsNothing);
      await lift(t, r, _right(r));
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('coworker: taking the leaking tool before he comes slips on its own — he never names its fault', (t) async {
      final (c, deal) = await open(t, _seedWhere((d) => d.callRound == 0 && d.push == HydPush.leak));
      final r = deal.rounds[0];
      final twin = _twin(r);
      expect(twin.flaw, HydFlaw.leak);
      await t.tap(tools.at(r.tools.indexOf(twin)), warnIfMissed: false);
      await _pump(t, 200);
      await t.tap(find.text(HydLines.take));
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'no hold on the leaking tool');
      await _pump(t, 800);
      expect(find.text(HydMistakes.leak.textBn), findsOneWidget);
      expect(find.text(HydLines.coworkerLeak.line), findsNothing);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('putting back a tool not looked over gets the same neutral line for sound and faulty alike', (t) async {
      // (A flat battery reads at a glance on its gauge, so that twin is left out.)
      final (c, deal) = await open(t, _seedWhere((d) => d.callRound == 2 && _twin(d.rounds[0]).flaw != HydFlaw.battery));
      final r = deal.rounds[0];
      for (final tool in [_right(r), _twin(r)]) {
        await lift(t, r, tool);
        await t.tap(find.text(HydLines.putBack));
        await _pump(t, 300);
        expect(c.read(guideDirectorProvider).line, HydLines.putBackLine);
        await _pump(t, 600);
      }
      expect(find.text(HydLines.serviceTag), findsNothing);
      expect(find.text(HydLines.chargeTag), findsNothing);
      expect(t.takeException(), isNull);
      await close(t, c);
    });

    testWidgets('mistakes: letting go before the click is a slip card; three slips fail the level', (t) async {
      final (c, deal) = await open(t, _seedWhere((d) => d.callRound == 2));
      final r = deal.rounds[0];
      final tool = _right(r);
      await lift(t, r, tool);
      await t.tap(find.text(HydLines.take));
      await _pump(t, 600);
      // A near-size die: slip 1.
      await t.tap(_label('${HydLines.dieLabel} ${hydNearDie(r)}'));
      await _pump(t, 600);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(find.text(HydMistakes.wrongDie.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 400);
      // The right die, two strokes, let go: slip 2.
      await t.tap(_label('${HydLines.dieLabel} ${r.docket.size}'));
      await _pump(t, 500);
      final p = find.text(tool.kind == HydKind.batteryCrimper ? HydLines.trigger : HydLines.pump);
      await t.tap(p);
      await _pump(t, 300);
      await t.tap(p);
      await _pump(t, 300);
      await t.tap(find.text(HydLines.release));
      await _pump(t, 600);
      expect(find.text(HydMistakes.halfCrimp.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 400);
      await t.tap(p);
      await _pump(t, 300);
      await t.tap(find.text(HydLines.release));
      await _pump(t, 800);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.text(FrameLines.struckHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.levelScoreByRung.containsKey('2.9/do/0'), isTrue);
      expect(s.rungProgress['2.9/do/0'], isNot('cleared'));
      expect(t.takeException(), isNull);
      await close(t, c);
    });
  });
}
