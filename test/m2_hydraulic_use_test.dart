// Lesson 2.9 (হাইড্রোলিক ক্রিম্পার ও কাটার), কাজ 2 "কাটার আগে নিশ্চিত হও":
// the rules (prove the docket's cable dead before the tool goes on it; the
// cutter's order — place, safety lock, pump; the crimper's — the chart's die,
// place, pump to the valve's click, let go; the free hand on the pump body; a
// cable that still reads voltage = stop and report), the deal, reason
// libraries, and the level in the shell: idle perf, the guide first, a full
// clean play with the coworker refused, a slip card, the deadly freeze (the
// tool on a cable not proved dead, also on his say-so), the 3-slip strike-out,
// the coworker on a fast play (every step waits for him), the needless stop
// (a slip, audit 2026-11-11) and the gesture hints (a sweep, never the answer).
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
import 'package:slm_flutter/features/game/level_frame.dart' show StruckOutCard, kStrikesToFail;
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m2_hydraulic_use.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';
import 'support/reason_proceed.dart';

const _ctx = LevelContext(
  rungId: '2.9/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '2.9',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m2HydraulicUsePacks['do_2_9_b']!;

/// The level's new art folder is not in pubspec yet (the director adds it):
/// tests read it from disk.
class _DiskBundle extends CachingAssetBundle {
  static const _dir = 'assets/game/art/m2_hydraulic_use/';
  @override
  Future<ByteData> load(String key) async {
    if (key.startsWith(_dir)) {
      final bytes = await File(key).readAsBytes();
      return ByteData.sublistView(bytes);
    }
    return rootBundle.load(key);
  }
}

Future<void> _pump(WidgetTester t, int ms) async {
  for (var i = 0; i < ms; i += 50) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

Future<bool> _pumpUntil(WidgetTester t, Finder f, {int maxMs = 8000}) async {
  for (var ms = 0; ms < maxMs; ms += 100) {
    if (f.evaluate().isNotEmpty) return true;
    await t.pump(const Duration(milliseconds: 100));
  }
  return f.evaluate().isNotEmpty;
}

Finder _label(String l) => find.byWidgetPredicate((w) => w is Semantics && w.properties.label == l);
List<Finder> _onScreen(List<String> texts) => [
      for (final x in texts)
        if (_label(x).evaluate().isNotEmpty) _label(x),
    ];

/// Picks the right card on the deck that is up (a reason deck: then its
/// এগিয়ে যান; a coworker deck closes by itself).
Future<void> _pickRight(WidgetTester t, List<String> right) async {
  await waitChoiceDeck(t);
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = _onScreen(right);
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
  await tapReasonProceed(t);
}

/// Waits for him on his job and refuses him.
Future<void> _refuseHim(WidgetTester t) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes');
  await _pickRight(t, HydLines.coworker.right);
  await _pump(t, 1800);
}

/// The slip card is up: read it and go on.
Future<void> _gotIt(WidgetTester t) async {
  await t.tap(find.text(MistakeLines.gotIt));
  await _pump(t, 800);
}

Widget _app(Widget home, {GlobalKey<NavigatorState>? nav}) =>
    DefaultAssetBundle(bundle: _DiskBundle(), child: MaterialApp(navigatorKey: nav, home: home));

Future<ProviderContainer> _open(WidgetTester t, int seed) async {
  t.view.physicalSize = const Size(784, 1700);
  t.view.devicePixelRatio = 2.0;
  final c = ProviderContainer();
  final nav = GlobalKey<NavigatorState>();
  await t.pumpWidget(UncontrolledProviderScope(container: c, child: _app(const Scaffold(body: SizedBox()), nav: nav)));
  unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
    builder: (_) => M2HydraulicUsePage(ctx: _ctx, pack: _pack, muted: true, seed: seed),
  )));
  await _pump(t, 1000);
  await waitIntro(t);
  await _pump(t, 600);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

Future<void> _step(WidgetTester t, HydJob j, HydStep s) async {
  await t.tap(_label(HydLines.stepBn(s, j.kind)), warnIfMissed: false);
  await _pump(t, 350);
}

/// Plays job [i] right (on his job: wait for him, refuse him first), then the reason.
Future<void> _playRight(WidgetTester t, HydDeal deal, int i) async {
  final j = deal.jobs[i];
  if (i == deal.callAt) await _refuseHim(t);
  await t.tap(_label(HydLines.cableLabel(j.tags[j.target])), warnIfMissed: false);
  await _pump(t, 300);
  await _step(t, j, HydStep.test);
  expect(find.text(j.liveTarget ? HydLines.live : HydLines.dead), findsOneWidget, reason: 'the reading, job $i');
  final HydEnd end;
  if (j.liveTarget) {
    await t.tap(find.text(HydLines.stop));
    end = HydEnd.stop;
  } else {
    await _step(t, j, HydStep.earth);
    if (!j.cut) {
      await _step(t, j, HydStep.die);
      await t.tap(_label(HydLines.dieOf(j.size)));
      await _pump(t, 350);
    }
    await _step(t, j, HydStep.place);
    if (j.cut) await _step(t, j, HydStep.lock);
    await t.tap(_label(HydLines.zoneHandle), warnIfMissed: false);
    await _pump(t, 300);
    for (var k = 0; k < kHydStrokes; k++) {
      await _step(t, j, HydStep.pump);
    }
    if (!j.cut) {
      expect(find.text(HydLines.click), findsOneWidget);
      await t.tap(find.text(HydLines.release));
    }
    end = j.cut ? HydEnd.cut : HydEnd.crimp;
  }
  await _pump(t, 600);
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'job $i');
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'reason deck, job $i');
  await _pickRight(t, HydLines.whyRight(end));
  await _pump(t, 3200);
}

HydRun _runFor(bool Function(HydJob j) want) {
  for (var seed = 0; seed < 500; seed++) {
    final r = HydRun(dealHyd(math.Random(seed)));
    if (want(r.current)) return r;
  }
  throw StateError('no deal');
}

void _prove(HydRun r) {
  r.select(r.current.target);
  r.test();
  r.earth();
}

void main() {
  group('rules', () {
    test('deals: three jobs, a cut and a crimp at least, he comes on a cut; the tray has the size and its near sizes', () {
      var lives = 0;
      final firsts = <String>{};
      for (var seed = 0; seed < 300; seed++) {
        final d = dealHyd(math.Random(seed));
        expect(d.jobs, hasLength(3));
        expect(d.jobs.any((j) => j.cut), isTrue);
        expect(d.jobs.any((j) => !j.cut), isTrue);
        expect(d.jobs[d.callAt].cut, isTrue);
        expect(d.jobs.where((j) => j.liveTarget).length, lessThanOrEqualTo(1));
        if (d.jobs.any((j) => j.liveTarget)) lives++;
        for (final j in d.jobs) {
          expect(j.tags.toSet(), hasLength(3));
          expect(j.steps.toSet(), hasLength(5));
          expect(j.steps.contains(HydStep.lock), j.cut);
          expect(j.steps.contains(HydStep.die), !j.cut);
          if (!j.cut) {
            expect(j.dies, contains(j.size));
            expect(j.dies, hasLength(4));
          }
          for (var s = 0; s < 3; s++) {
            expect(j.live(s), s != j.target || j.liveTarget);
          }
        }
        firsts.add('${d.jobs[0].kind}${d.jobs[0].steps}${d.jobs[0].target}');
      }
      expect(lives, inInclusiveRange(90, 210), reason: 'about half the plays have a live docket cable');
      expect(firsts.length, greaterThan(50), reason: 'plays differ');
    });

    test('the tool on a cable not proved dead is deadly (untested, unearthed, the wrong cable, a live one)', () {
      final cut = _runFor((j) => j.cut && !j.liveTarget);
      cut.select(cut.current.target);
      expect(cut.place().mistake, HydMistakes.cutUnproved);
      expect(cut.deadly, isNotNull);

      final untested = _runFor((j) => j.cut && !j.liveTarget);
      untested.select(untested.current.target);
      untested.earth();
      expect(untested.place().mistake!.deadly, isTrue);

      final unearthed = _runFor((j) => !j.cut && !j.liveTarget);
      unearthed.select(unearthed.current.target);
      unearthed.test();
      unearthed.pickDie(unearthed.current.size);
      expect(unearthed.place().mistake, HydMistakes.crimpUnproved);

      final live = _runFor((j) => j.liveTarget);
      live.select(live.current.target);
      live.test();
      expect(live.reading(live.current.target), isTrue);
      expect(live.place().mistake!.deadly, isTrue);

      final pushed = _runFor((j) => j.cut);
      expect(pushed.pushedCut().mistake, HydMistakes.cutUnproved);
    });

    test('the earth lead on a cable with voltage is a slip; the wrong cable tests live and is caught', () {
      final r = _runFor((j) => !j.liveTarget);
      final wrong = (r.current.target + 1) % 3;
      r.select(wrong);
      r.test();
      expect(r.reading(wrong), isTrue);
      expect(r.caught, contains(HydLines.caughtWrongCable));
      expect(r.earth().mistake, HydMistakes.earthLive);
      expect(r.slips, 1);
      expect(r.deadly, isNull);
    });

    test('cutter: proved, placed, safety lock, hand on the pump body, 6 strokes → cut; pumping unlocked is a slip', () {
      final r = _runFor((j) => j.cut && !j.liveTarget);
      _prove(r);
      expect(r.proved(r.current.target), isTrue);
      expect(r.lock().note, HydLines.placeFirst, reason: 'nothing to lock yet');
      expect(r.place().mistake, isNull);
      expect(r.pump().mistake, HydMistakes.noLock);
      expect(r.slips, 1);

      final ok = _runFor((j) => j.cut && !j.liveTarget);
      _prove(ok);
      ok.place();
      ok.lock();
      expect(ok.pump().note, HydLines.handFirst);
      expect(ok.putHand(HydZone.handle).mistake, isNull);
      HydAct last = HydAct.ok;
      for (var i = 0; i < kHydStrokes; i++) {
        last = ok.pump();
      }
      expect(last.end, HydEnd.cut);
      expect(ok.slips, 0);
      expect(ok.thorough, isFalse, reason: 'one not-scored line (pump before the hand)');
      expect(ok.caught, containsAll([HydLines.caughtProve, HydLines.caughtHand, HydLines.caughtLock]));
    });

    test('the free hand in the jaws or on the cable at them is a slip', () {
      for (final z in [HydZone.jaws, HydZone.cable]) {
        final r = _runFor((j) => !j.cut && !j.liveTarget);
        _prove(r);
        r.pickDie(r.current.size);
        r.place();
        expect(r.putHand(z).mistake, HydMistakes.fingersCrimp);
        final c = _runFor((j) => j.cut && !j.liveTarget);
        _prove(c);
        c.place();
        expect(c.putHand(z).mistake, HydMistakes.fingersCut);
      }
    });

    test('crimper: the chart\'s die, pump to the valve\'s click, then let go; a near size or letting go early is a slip', () {
      final wrong = _runFor((j) => !j.cut && !j.liveTarget);
      _prove(wrong);
      final near = wrong.current.dies.firstWhere((d) => d != wrong.current.size);
      expect(wrong.pickDie(near).mistake, HydMistakes.wrongDie);

      final noDie = _runFor((j) => !j.cut && !j.liveTarget);
      _prove(noDie);
      expect(noDie.place().mistake, HydMistakes.wrongDie);

      final early = _runFor((j) => !j.cut && !j.liveTarget);
      _prove(early);
      early.pickDie(early.current.size);
      early.place();
      early.putHand(HydZone.handle);
      expect(early.release().note, HydLines.pumpFirst);
      early.pump();
      early.pump();
      expect(early.release().mistake, HydMistakes.halfCrimp);

      final ok = _runFor((j) => !j.cut && !j.liveTarget);
      _prove(ok);
      ok.pickDie(ok.current.size);
      ok.place();
      ok.putHand(HydZone.handle);
      for (var i = 0; i < kHydStrokes; i++) {
        expect(ok.pump().end, isNull);
      }
      expect(ok.clicked, isTrue);
      expect(ok.release().end, HydEnd.crimp);
      expect(ok.thorough, isTrue);
      expect(ok.caught, containsAll([HydLines.caughtDie, HydLines.caughtClick]));
    });

    test('stop and report: right only when the docket cable tested live; any other stop is a needless-stop slip', () {
      final live = _runFor((j) => j.liveTarget);
      live.select(live.current.target);
      live.test();
      expect(live.stop().end, HydEnd.stop);
      expect(live.caught, contains(HydLines.caughtLive));
      expect(live.slips, 0);

      // Untested (even on the job whose cable is live): no reading, no reason.
      final untested = _runFor((j) => j.liveTarget);
      expect(untested.stop().mistake, HydMistakes.needlessStop);
      expect(untested.slips, 1);
      expect(untested.deadly, isNull);

      // Tested dead: a needless stop costs a slip (it was free before).
      final dead = _runFor((j) => !j.liveTarget);
      dead.select(dead.current.target);
      dead.test();
      expect(dead.stop().mistake, HydMistakes.needlessStop);
      expect(dead.slips, 1);
      expect(dead.deadly, isNull);

      // Only the neighbour (in service) read live: still a needless stop.
      final nb = _runFor((j) => !j.liveTarget);
      nb.select((nb.current.target + 1) % 3);
      nb.test();
      expect(nb.stop().mistake, HydMistakes.needlessStop);

      // Its card stays neutral: the rule, never which case it was.
      expect(HydMistakes.needlessStop.textBn, isNot(contains('ঠিক আছে')));
      expect(HydMistakes.needlessStop.deadly, isFalse);
    });

    test('three slips strike out; the third ends the play', () {
      final r = HydRun(dealHyd(math.Random(5)));
      for (var i = 0; i < 3; i++) {
        expect(r.stop().mistake, HydMistakes.needlessStop);
        r.next();
      }
      expect(r.slips, 3);
      expect(r.percent, 55);
      expect(kStrikesToFail, 3);
    });

    test('mark: 100 − 15 per slip; three jobs; pass ≥ 55', () {
      final r = HydRun(dealHyd(math.Random(3)));
      r.slips = 2;
      expect(r.percent, 70);
      for (var i = 0; i < 3; i++) {
        r.next();
      }
      expect(r.done, isTrue);
      expect(r.passed, isTrue);
    });

    test('every mistake has its picture on disk; lesson points 1–2 (earth-on-live, needless stop: none, not in 2.9)', () {
      for (final m in HydMistakes.all) {
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(m.key, startsWith('2.9/hyd/'));
        if (m == HydMistakes.earthLive || m == HydMistakes.needlessStop) {
          expect(m.lessonPoint, isNull);
        } else {
          expect(m.lessonPoint, inInclusiveRange(1, 2));
        }
      }
      expect(HydMistakes.all.where((m) => m.deadly), hasLength(2));
    });

    test('reasons fit the end, same length, big enough; his choice too', () {
      for (final e in HydEnd.values) {
        expectLibrary('why ${e.name}', HydLines.whyRight(e), HydLines.whyWrong(e));
        expectSameLength('why ${e.name}', [...HydLines.whyRight(e), ...HydLines.whyWrong(e)]);
      }
      final s = HydLines.coworker;
      expectLibrary('coworker', s.right, s.wrong);
      expectSameLength('coworker', [...s.right, ...s.wrong]);
      expect(s.recordedLines, hasLength(2));
      for (final l in [...HydLines.guideLines, ...s.recordedLines]) {
        expect(l.trim(), isNotEmpty);
      }
    });

    test('the docket shows English digits only', () {
      expect(HydLines.sqmm(240), '240 sq mm');
      expect(HydLines.dieOf(185), 'ডাই 185');
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
        var seed = 0;
        while (dealHyd(math.Random(seed)).callAt == 0) {
          seed++;
        }
        t.view.physicalSize = const Size(720, 1600);
        t.view.devicePixelRatio = 2.0;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        await t.pumpWidget(ProviderScope(child: _app(M2HydraulicUsePage(ctx: _ctx, pack: _pack, muted: true, seed: seed))));
        await t.pump(const Duration(milliseconds: 100));
        expect(find.text('শুরু'), findsNothing);
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
        debugPrint('PERF m2_hydraulic_use ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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

    testWidgets('the guide comes first: a tap does not skip him; then the docket and the tool row', (t) async {
      var seed = 0;
      while (dealHyd(math.Random(seed)).callAt == 0) {
        seed++;
      }
      final j = dealHyd(math.Random(seed)).jobs[0];
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: _app(M2HydraulicUsePage(ctx: _ctx, pack: _pack, muted: true, seed: seed))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text(HydLines.stop), findsNothing);
      await waitIntro(t);
      await _pump(t, 1500);
      expect(find.text(HydLines.stop), findsOneWidget);
      expect(find.text(j.cut ? HydLines.jobCut : HydLines.jobCrimp), findsOneWidget, reason: 'the docket');
      expect(find.text('${j.tags[j.target]} · ${HydLines.sqmm(j.size)}'), findsOneWidget);
      for (final s in j.steps) {
        expect(_label(HydLines.stepBn(s, j.kind)), findsOneWidget);
      }
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      var seed = 0;
      while (dealHyd(math.Random(seed)).callAt == 0) {
        seed++;
      }
      final j = dealHyd(math.Random(seed)).jobs[0];
      final c = await _open(t, seed);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(HydLines.ask(j))), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('flow: prove each cable dead, use the tool in order, refuse him, right reasons → pass', (t) async {
      var seed = 0;
      while (!dealHyd(math.Random(seed)).jobs.any((j) => j.liveTarget)) {
        seed++;
      }
      final deal = dealHyd(math.Random(seed));
      final c = await _open(t, seed);
      for (var i = 0; i < 3; i++) {
        await _playRight(t, deal, i);
      }
      expect(await _pumpUntil(t, find.byType(LevelPassPanel), maxMs: 6000), isTrue);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['2.9/do/1'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['2.9/do/1'], greaterThan(0));
      await _close(t, c);
    });

    testWidgets('the wrong die: a slip card with its picture, then the next job', (t) async {
      var seed = 0;
      late HydDeal deal;
      while (true) {
        deal = dealHyd(math.Random(seed));
        if (!deal.jobs[0].cut && !deal.jobs[0].liveTarget) break;
        seed++;
      }
      final j = deal.jobs[0];
      final c = await _open(t, seed);
      await _step(t, j, HydStep.die);
      await t.tap(_label(HydLines.dieOf(j.dies.firstWhere((d) => d != j.size))));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(t.takeException(), isNull);
      expect(c.read(gameSaveProvider).mistakes.single.key, HydMistakes.wrongDie.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      expect(find.byType(MistakeCard), findsNothing);
      expect(find.text(HydLines.ask(deal.jobs[1])), findsWidgets);
      await _close(t, c);
    });

    testWidgets('the cutter on a cable not tested: the trench freezes first, then the card (near-miss)', (t) async {
      var seed = 0;
      late HydDeal deal;
      while (true) {
        deal = dealHyd(math.Random(seed));
        if (deal.jobs[0].cut && deal.callAt != 0) break;
        seed++;
      }
      final j = deal.jobs[0];
      final c = await _open(t, seed);
      await t.tap(_label(HydLines.cableLabel(j.tags[j.target])), warnIfMissed: false);
      await _pump(t, 300);
      await _step(t, j, HydStep.place);
      await _pump(t, 400);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, HydMistakes.cutUnproved.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('a step before he came, on his job: he cuts in; listening = deadly freeze, then the card', (t) async {
      var seed = 0;
      while (dealHyd(math.Random(seed)).callAt != 0) {
        seed++;
      }
      final j = dealHyd(math.Random(seed)).jobs[0];
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      final c = ProviderContainer();
      await t.pumpWidget(UncontrolledProviderScope(container: c, child: _app(M2HydraulicUsePage(ctx: _ctx, pack: _pack, muted: true, seed: seed))));
      await waitIntro(t);
      await _pump(t, 200);
      expect(find.byType(CoworkerPeek), findsNothing);
      await t.tap(_label(HydLines.cableLabel(j.tags[j.target])), warnIfMissed: false);
      await _pump(t, 100);
      await _step(t, j, HydStep.test);
      expect(find.text(HydLines.dead), findsNothing, reason: 'the test waits: he cut in');
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 3000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      final wrong = _onScreen(HydLines.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('three slips strike out: the StruckOutCard, nothing cleared', (t) async {
      var seed = 0;
      late HydDeal deal;
      while (true) {
        deal = dealHyd(math.Random(seed));
        if (deal.callAt != 2) break;
        seed++;
      }
      final c = await _open(t, seed);
      for (var i = 0; i < 3; i++) {
        if (i == deal.callAt) await _refuseHim(t);
        // A stop with no LIVE reading on the docket's cable: a needless stop.
        await t.tap(find.text(HydLines.stop));
        await _pump(t, 600);
        if (i < 2) {
          expect(find.text(MistakeLines.slipHead), findsOneWidget, reason: 'slip $i');
          await _gotIt(t);
        }
      }
      expect(await _pumpUntil(t, find.byType(StruckOutCard), maxMs: 3000), isTrue);
      expect(find.byType(LevelPassPanel), findsNothing);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['2.9/do/1'], isNot('cleared'));
      expect(s.mistakes.map((m) => m.key), contains(HydMistakes.needlessStop.key));
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a needless stop after a dead reading costs a slip (it was free)', (t) async {
      var seed = 0;
      late HydDeal deal;
      while (true) {
        deal = dealHyd(math.Random(seed));
        if (deal.callAt != 0 && !deal.jobs[0].liveTarget) break;
        seed++;
      }
      final j = deal.jobs[0];
      final c = await _open(t, seed);
      await t.tap(_label(HydLines.cableLabel(j.tags[j.target])), warnIfMissed: false);
      await _pump(t, 300);
      await _step(t, j, HydStep.test);
      expect(find.text(HydLines.dead), findsOneWidget);
      await t.tap(find.text(HydLines.stop));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, HydMistakes.needlessStop.key);
      await _gotIt(t);
      expect(find.text(HydLines.ask(deal.jobs[1])), findsWidgets, reason: 'the next job');
      await _close(t, c);
    });

    testWidgets('he comes even on a fast play on a later job: the step waits, refuse him, then it works', (t) async {
      var seed = 0;
      late HydDeal deal;
      while (true) {
        deal = dealHyd(math.Random(seed));
        if (deal.callAt == 1 && !deal.jobs[1].liveTarget) break;
        seed++;
      }
      final c = await _open(t, seed);
      // Job 0: a quick slip (a needless stop) to reach his job.
      await t.tap(find.text(HydLines.stop));
      await _pump(t, 600);
      await _gotIt(t);
      // His job: the cable and the tester at once, before his timer.
      final j = deal.jobs[1];
      expect(find.byType(CoworkerPeek), findsNothing);
      await t.tap(_label(HydLines.cableLabel(j.tags[j.target])), warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 50));
      await t.tap(_label(HydLines.stepBn(HydStep.test, j.kind)), warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 50));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'the step held: he came now');
      expect(find.text(HydLines.dead), findsNothing, reason: 'the test waited for him');
      await _pickRight(t, HydLines.coworker.right);
      await _pump(t, 1800);
      expect(find.byType(CoworkerPeek), findsNothing);
      await _step(t, j, HydStep.test);
      expect(find.text(HydLines.dead), findsOneWidget, reason: 'after him the step works');
      expect(c.read(gameSaveProvider).mistakes, hasLength(1), reason: 'only the needless stop');
      await _close(t, c);
    });

    group('gesture hints', () {
      setUp(() => GestureHints.debugEnableInTests = true);
      tearDown(() => GestureHints.debugEnableInTests = false);
      final hand = find.byKey(const ValueKey('gesture-hint'));
      List<Rect> options(WidgetTester t) => t.state<IdleHintState>(find.byType(IdleHint).first).debugOptions;

      testWidgets('a sweep over all three cables, then over the whole tool row; never one target', (t) async {
        var seed = 0;
        late HydDeal deal;
        while (true) {
          deal = dealHyd(math.Random(seed));
          if (deal.callAt != 0) break;
          seed++;
        }
        final j = deal.jobs[0];
        t.view.physicalSize = const Size(784, 1700);
        t.view.devicePixelRatio = 2.0;
        final c = ProviderContainer();
        await t.pumpWidget(UncontrolledProviderScope(container: c, child: _app(M2HydraulicUsePage(ctx: _ctx, pack: _pack, muted: true, seed: seed))));
        await t.pump(const Duration(milliseconds: 300));
        for (var ms = 0; ms < 20000 && find.byType(GuideIntro).evaluate().isNotEmpty; ms += 500) {
          expect(hand, findsNothing, reason: 'not during the guide intro');
          await t.pump(const Duration(milliseconds: 500));
        }
        await waitIntro(t);
        await _pump(t, 9000);
        expect(hand, findsOneWidget, reason: 'idle on the cables');
        expect(options(t), hasLength(3), reason: 'all three cables');
        await t.tap(_label(HydLines.cableLabel(j.tags[j.target])), warnIfMissed: false);
        await t.pump();
        expect(hand, findsNothing, reason: 'any touch hides it');
        await _pump(t, 9000);
        expect(hand, findsOneWidget);
        expect(options(t), hasLength(j.steps.length + 1), reason: 'every step and the stop');
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 15));
        MascotTalk.reset();
        c.dispose();
        t.view.reset();
      });

      testWidgets('three taps on nothing show the hand at once', (t) async {
        var seed = 0;
        while (dealHyd(math.Random(seed)).callAt == 0) {
          seed++;
        }
        final c = await _open(t, seed);
        await _pump(t, 1000);
        expect(hand, findsNothing);
        for (var i = 0; i < 3; i++) {
          // The sky above the trench: no cable there.
          await t.tapAt(const Offset(200, 260));
          await t.pump(const Duration(milliseconds: 200));
        }
        await t.pump(const Duration(milliseconds: 100));
        expect(hand, findsOneWidget);
        await _close(t, c);
      });
    });
  });
}
