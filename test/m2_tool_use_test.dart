// Lesson 2.1 (লাইনম্যানের টুলবক্স পরিচিতি), কাজ 2 "সঠিক কাজে সঠিক হাতিয়ার":
// the deal (four jobs, the coworker's job, the tray), which tool is right for
// which job and which mistake each wrong one is (all slips, none deadly), the
// fit in the lens, reason and choice libraries, the mistake art, and the level
// in the shell: idle perf, the guide first, tapping the guide, a clean play
// (try, use, reason; the coworker refused) → pass and save, a wrong tool → its
// card, listening to the coworker → his shortcut's card, three slips → out,
// a fast play still meets the coworker (holdForCoworker), no scene move in a
// praise window (tableBusy), and the gesture hint (a sweep, never one tool).
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
import 'package:slm_flutter/features/game/full_scene_frame.dart';
import 'package:slm_flutter/features/game/game_save.dart';
import 'package:slm_flutter/features/game/gesture_hint.dart';
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_frame.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m2_tool_use.dart';
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
  rungId: '2.1/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '2.1',
  lessonTitleBn: '',
  ladderStep: 33,
  doIndex: 2,
  doCount: 2,
);

final _pack = m2ToolUsePacks['do_2_1_b']!;

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

Finder _tool(TuTool tool) => find.byKey(ValueKey('tool-${tool.name}'));

Future<ProviderContainer> _open(WidgetTester t, int seed) async {
  t.view.physicalSize = const Size(784, 1700);
  t.view.devicePixelRatio = 2.0;
  final c = ProviderContainer();
  final nav = GlobalKey<NavigatorState>();
  await t.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: MaterialApp(navigatorKey: nav, home: const Scaffold(body: SizedBox())),
  ));
  unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
    builder: (_) => M2ToolUsePage(ctx: _ctx, pack: _pack, muted: true, seed: seed),
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

/// On his job: wait for him and refuse him.
Future<void> _refuse(WidgetTester t, TuDeal deal) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes on job ${deal.callAt}');
  await _pickRight(t, TuLines.coworkerFor(deal.cases[deal.callAt].job).right);
  await _pump(t, 2600);
}

/// Plays job [i] right: (refuse him on his job,) try a wrong tool first on the
/// sized jobs and put it back, then the right tool, use it, the reason.
Future<void> _playRight(WidgetTester t, TuDeal deal, int i) async {
  final c = deal.cases[i];
  if (i == deal.callAt) await _refuse(t, deal);
  final wrongTry = switch (c.job) {
    TuJob.nut => c.right == TuTool.sp19 ? TuTool.sp13 : TuTool.sp19,
    TuJob.screw => c.right == TuTool.phillips ? TuTool.flatBig : TuTool.phillips,
    _ => null,
  };
  if (wrongTry != null) {
    await t.tap(_tool(wrongTry));
    await _pump(t, 300);
    await t.tap(find.text(TuLines.putBack));
    await _pump(t, 300);
  }
  await t.tap(_tool(c.right));
  await _pump(t, 300);
  await t.tap(find.text(TuLines.use));
  await _pump(t, 1800);
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'job $i');
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'reason deck $i');
  await _pump(t, 700);
  await _pickRight(t, TuLines.whyRight(c.job));
  await _pump(t, 4500);
}

/// The words of [card] (punctuation dropped), each with a crude Bangla stem.
Set<String> _words(String card) {
  const suffixes = ['ের', 'ে', 'টা', 'টাই', 'ই', 'র', 'সে'];
  final out = <String>{};
  for (final w in card.split(RegExp(r'[\s,!?।—]+')).where((w) => w.isNotEmpty)) {
    out.add(w);
    for (final suf in suffixes) {
      if (w.endsWith(suf) && w.length > suf.length + 1) out.add(w.substring(0, w.length - suf.length));
    }
  }
  return out;
}

/// Words on [minRight] or more right cards that start no word of a wrong card: a
/// player could pick the right card by the word alone.
Set<String> _tells(List<String> right, List<String> wrong, {int minRight = 2}) {
  final count = <String, int>{};
  for (final r in right) {
    for (final w in _words(r)) {
      count[w] = (count[w] ?? 0) + 1;
    }
  }
  return {
    for (final e in count.entries)
      if (e.value >= minRight && !wrong.any((x) => _words(x).any((w) => w.startsWith(e.key)))) e.key,
  };
}

int _seedWhere(bool Function(TuDeal d) ok, {int from = 0}) {
  var s = from;
  while (!ok(dealToolUse(math.Random(s)))) {
    s++;
  }
  return s;
}

void main() {
  group('rules', () {
    test('deals: four jobs (nut, screw, strip + neutral or crimp), he comes on nut/strip/crimp, a full tray', () {
      final orders = <String>{};
      final calls = <TuJob>{};
      final extra = <TuJob>{};
      final sizes = <int>{};
      final screws = <TuScrew>{};
      for (var s = 0; s < 80; s++) {
        final d = dealToolUse(math.Random(s));
        expect(d.cases, hasLength(4));
        final jobs = d.cases.map((c) => c.job).toList();
        expect(jobs, containsAll([TuJob.nut, TuJob.screw, TuJob.strip]));
        expect(jobs.toSet(), hasLength(4));
        extra.addAll(jobs.where((j) => j == TuJob.neutral || j == TuJob.crimp));
        final call = d.cases[d.callAt];
        expect(call.pushTool, isNotNull);
        calls.add(call.job);
        expect(d.tray.toSet(), TuTool.values.toSet());
        expect(d.tray, hasLength(13));
        for (final c in d.cases) {
          if (c.job == TuJob.nut) sizes.add(c.nutMm);
          if (c.job == TuJob.screw) screws.add(c.screw!);
        }
        orders.add('${jobs.join()}${d.tray.join()}');
      }
      expect(calls, {TuJob.nut, TuJob.strip, TuJob.crimp});
      expect(extra, {TuJob.neutral, TuJob.crimp});
      expect(sizes, {13, 17, 19});
      expect(screws, TuScrew.values.toSet());
      expect(orders.length, greaterThan(60), reason: 'plays differ');
    });

    test('the right tool per job; every wrong one is its lesson mistake, a slip (no deadly)', () {
      const nut17 = TuCase(id: 'a', job: TuJob.nut, nutMm: 17);
      expect(nut17.right, TuTool.sp17);
      expect(nut17.mistakeFor(TuTool.sp17), isNull);
      expect(nut17.mistakeFor(TuTool.sp19), TuMistakes.spannerSize);
      expect(nut17.mistakeFor(TuTool.sp13), TuMistakes.spannerSize);
      expect(nut17.mistakeFor(TuTool.pliersVde), TuMistakes.nutPliers);
      expect(nut17.mistakeFor(TuTool.pliersPlain), TuMistakes.nutPliers);
      expect(nut17.mistakeFor(TuTool.flatBig), TuMistakes.wrongTool);
      for (final s in TuScrew.values) {
        final c = TuCase(id: 'b', job: TuJob.screw, screw: s);
        expect(c.mistakeFor(c.right), isNull);
        for (final d in [TuTool.flatBig, TuTool.flatSmall, TuTool.phillips]) {
          if (d != c.right) expect(c.mistakeFor(d), TuMistakes.screwSize);
        }
        expect(c.mistakeFor(TuTool.pliersVde), TuMistakes.wrongTool);
      }
      const strip = TuCase(id: 'c', job: TuJob.strip);
      expect(strip.right, TuTool.stripper);
      for (final x in [TuTool.knife, TuTool.pliersVde, TuTool.pliersPlain, TuTool.cutter]) {
        expect(strip.mistakeFor(x), TuMistakes.stripNick, reason: '$x');
      }
      const neutral = TuCase(id: 'd', job: TuJob.neutral);
      expect(neutral.right, TuTool.meter);
      expect(neutral.mistakeFor(TuTool.tester), TuMistakes.testerNeutral);
      const crimp = TuCase(id: 'e', job: TuJob.crimp);
      expect(crimp.right, TuTool.pliersVde);
      expect(crimp.mistakeFor(TuTool.pliersPlain), TuMistakes.nonInsulated);
      expect(crimp.mistakeFor(TuTool.knife), TuMistakes.wrongTool);
      // His shortcuts are each a mistake.
      for (final c in [nut17, strip, crimp]) {
        expect(c.mistakeFor(c.pushTool!), isNotNull);
      }
      for (final m in TuMistakes.all) {
        expect(m.deadly, isFalse, reason: m.key);
      }
    });

    test('trying is free; using: right → caught, wrong → a slip; 15 a slip, pass ≥ 55', () {
      final d = dealToolUse(math.Random(3));
      final r = ToolUseRun(d);
      final c = r.current;
      final wrong = TuTool.values.firstWhere((t) => t != c.right);
      r.tryTool(wrong);
      r.putBack();
      r.tryTool(c.right);
      expect(r.slips, 0);
      expect(r.tried, {wrong, c.right});
      expect(r.use(), isNull);
      expect(r.shown, isTrue);
      expect(r.caught, [TuLines.caught(c.job)]);
      expect(r.use(), isNull, reason: 'once a job');
      r.next();
      expect(r.held, isNull);
      expect(r.tried, isEmpty);
      final c2 = r.current;
      r.tryTool(TuTool.values.firstWhere((t) => t != c2.right));
      expect(r.use(), isNotNull);
      expect(r.slips, 1);
      expect(r.percent, 85);
      r.next();
      expect(r.use(pushed: TuTool.values.firstWhere((t) => t != r.current.right)), isNotNull);
      r.next();
      r.tryTool(r.current.right);
      expect(r.use(), isNull);
      r.next();
      expect(r.done, isTrue);
      expect(r.percent, 70);
      expect(r.passed, isTrue);
    });

    test('the fit in the lens: the nut\'s spanner fits, bigger is loose, smaller will not go on; the driver seats or not', () {
      expect(tuFitOf(TuJob.nut, TuTool.sp17, nutMm: 17), TuFit.fits);
      expect(tuFitOf(TuJob.nut, TuTool.sp19, nutMm: 17), TuFit.loose);
      expect(tuFitOf(TuJob.nut, TuTool.sp13, nutMm: 17), TuFit.tooSmall);
      expect(tuFitOf(TuJob.screw, TuTool.flatSmall, screw: TuScrew.flatSmall), TuFit.fits);
      expect(tuFitOf(TuJob.screw, TuTool.flatSmall, screw: TuScrew.flatBig), TuFit.wrongTip);
      expect(tuFitOf(TuJob.strip, TuTool.knife), TuFit.other);
      expect(tuFitOf(TuJob.strip, null), TuFit.none);
    });

    test('every mistake has its picture and a lesson point (0–4, or the pro tip: none)', () {
      final keys = <String>{};
      for (final m in TuMistakes.all) {
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(keys.add(m.key), isTrue);
        expect(m.key, startsWith('2.1/'));
        if (m != TuMistakes.wrongTool) expect(m.lessonPoint, inInclusiveRange(0, 4), reason: m.key);
      }
      expect(TuMistakes.wrongTool.lessonPoint, isNull);
    });

    test('quick bonus ≈ 85 % of a clean play: 70 s; one pack', () {
      expect(_pack.quickMs, 70000);
      expect(m2ToolUsePacks.keys, ['do_2_1_b']);
    });

    test('reasons fit the job, same length, big enough; his choices too; his exit line is recorded', () {
      final every = <String>{for (final j in TuJob.values) ...[...TuLines.whyRight(j), ...TuLines.whyWrong(j)]}.toList();
      expectSameLength('why', every);
      for (final j in TuJob.values) {
        final right = TuLines.whyRight(j);
        final wrong = TuLines.whyWrong(j);
        expectLibrary('$j', right, wrong);
        expect(right.toSet().intersection(wrong.toSet()), isEmpty);
        for (var s = 0; s < 10; s++) {
          final deal = dealChoices(right, wrong, math.Random(s));
          expect(deal.where((o) => o.correct).length, 1);
          expect(deal.map((o) => o.textBn).toSet().length, 3);
        }
      }
      for (final cw in [TuLines.coworkerNut, TuLines.coworkerStrip, TuLines.coworkerCrimp]) {
        expectSameLength('choice', [...cw.right, ...cw.wrong]);
        expectLibrary('choice', cw.right, cw.wrong);
      }
      expect(LearnVoice.resolve(TuLines.coworkerExit, rival: true), isNotNull);
      expect(TuLines.toRecord, hasLength(3));
    });

    test('no giveaway words: the tool\'s name and the job\'s words are on wrong reasons too; "না"/"নেব" are on wrong choices', () {
      const toolWord = {
        TuJob.nut: 'স্প্যানার',
        TuJob.screw: 'ড্রাইভার',
        TuJob.strip: 'স্ট্রিপার',
        TuJob.neutral: 'মিটার',
        TuJob.crimp: 'VDE',
      };
      for (final j in TuJob.values) {
        final w = toolWord[j]!;
        expect(TuLines.whyRight(j).any((r) => r.contains(w)), isTrue, reason: '$j right names $w');
        expect(TuLines.whyWrong(j).where((r) => r.contains(w)).length, greaterThanOrEqualTo(2), reason: '$j: $w on wrong cards too');
      }
      for (final cw in [TuLines.coworkerNut, TuLines.coworkerStrip, TuLines.coworkerCrimp]) {
        expect(cw.right.every((r) => r.startsWith('না')), isFalse, reason: cw.line);
        expect(cw.wrong.any((r) => r.contains('না')), isTrue, reason: cw.line);
      }
      // No word of the right cards is on right cards only: not on every right
      // card, nor on two of them ("নাট", "তারে", "মাপ", "নেব"…).
      for (final j in TuJob.values) {
        expect(_tells(TuLines.whyRight(j), TuLines.whyWrong(j), minRight: TuLines.whyRight(j).length), isEmpty, reason: '$j: on every right reason only');
        expect(_tells(TuLines.whyRight(j), TuLines.whyWrong(j)), isEmpty, reason: '$j: on 2+ right reasons only');
      }
      for (final cw in [TuLines.coworkerNut, TuLines.coworkerStrip, TuLines.coworkerCrimp]) {
        expect(_tells(cw.right, cw.wrong, minRight: cw.right.length), isEmpty, reason: '${cw.line}: on every right choice only');
        expect(_tells(cw.right, cw.wrong), isEmpty, reason: '${cw.line}: on 2+ right choices only');
      }
      // His nut push fits a spanner already in hand (he may come on the use tap).
      expect(TuLines.coworkerNut.line, isNot(contains('খুঁজে')));
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
    tearDown(() {
      debugOnRebuildDirtyWidget = null;
      GestureHints.debugEnableInTests = false;
      CoworkerTiming.debugReadHoldInTests = false;
    });

    for (final reduce in [false, true]) {
      testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
        t.view.physicalSize = const Size(720, 1600);
        t.view.devicePixelRatio = 2.0;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        final seed = _seedWhere((d) => d.callAt != 0);
        await t.pumpWidget(ProviderScope(
          child: MaterialApp(home: M2ToolUsePage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
        ));
        await t.pump(const Duration(milliseconds: 100));
        expect(find.text('শুরু'), findsNothing);
        await waitIntro(t);
        // A tool in hand (the lens shows it) — then nothing more happens.
        await t.tap(_tool(TuTool.sp17));
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
        debugPrint('PERF m2_tool_use ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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

    testWidgets('the guide comes first: a tap does not skip him; then the docket and the tools', (t) async {
      final seed = _seedWhere((d) => d.callAt != 0);
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M2ToolUsePage(ctx: _ctx, pack: _pack, muted: true, seed: seed))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 600);
      expect(find.text(TuLines.jobBn(dealToolUse(math.Random(seed)).cases[0].job)), findsOneWidget, reason: 'the docket');
      for (final tool in TuTool.values) {
        expect(_tool(tool), findsOneWidget);
      }
      expect(find.text(TuLines.use), findsNothing, reason: 'no tool in hand yet');
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final seed = _seedWhere((d) => d.callAt != 0);
      final job = dealToolUse(math.Random(seed)).cases[0].job;
      final c = await _open(t, seed);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(TuLines.ask(job))), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('flow: try, use, reason each job; refuse him → pass, saved', (t) async {
      final seed = _seedWhere((d) => d.cases.any((c) => c.job == TuJob.crimp), from: 1);
      final deal = dealToolUse(math.Random(seed));
      final c = await _open(t, seed);
      for (var i = 0; i < 4; i++) {
        await _playRight(t, deal, i);
      }
      await _pump(t, 3000);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['2.1/do/1'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['2.1/do/1'], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(TuLines.caughtCall), findsOneWidget);
      expect(find.text(TuLines.caughtCrimp), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a wrong tool: its card (no deadly), then the next job', (t) async {
      final seed = _seedWhere((d) => d.callAt != 0 && d.cases[0].job == TuJob.nut);
      final c = await _open(t, seed);
      await t.tap(_tool(TuTool.pliersVde));
      await _pump(t, 300);
      await t.tap(find.text(TuLines.use));
      await _pump(t, 800);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, TuMistakes.nutPliers.key);
      expect(s.mistakes.single.deadly, isFalse);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      expect(find.byType(MistakeCard), findsNothing);
      expect(find.text(TuLines.jobBn(dealToolUse(math.Random(seed)).cases[1].job)), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('listening to him: his shortcut\'s card (a slip, not deadly)', (t) async {
      final seed = _seedWhere((d) => d.callAt == 0);
      final deal = dealToolUse(math.Random(seed));
      final c = await _open(t, seed);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await waitChoiceDeck(t);
      final wrong = _onScreen(TuLines.coworkerFor(deal.cases[0].job).wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 1200);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, deal.cases[0].mistakeFor(deal.cases[0].pushTool!)!.key);
      expect(s.mistakes.single.deadly, isFalse);
      await _close(t, c);
    });

    testWidgets('a fast play cannot skip him: "use" on his job before he comes waits for him', (t) async {
      final seed = _seedWhere((d) => d.callAt == 0);
      final deal = dealToolUse(math.Random(seed));
      final c = await _open(t, seed);
      // At once, before his 1.2–2.4 s: the right tool, straight to "use".
      expect(find.byType(CoworkerPeek), findsNothing);
      await t.tap(_tool(deal.cases[0].right));
      await t.pump(const Duration(milliseconds: 50));
      await t.tap(find.text(TuLines.use));
      await _pump(t, 300);
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'he cuts in now');
      expect(find.text(TuLines.stampDone), findsNothing, reason: 'the job waits for him');
      await _pickRight(t, TuLines.coworkerFor(deal.cases[0].job).right);
      await _pump(t, 2600);
      // Refused: the tool is still in hand; now "use" does the job.
      await t.tap(find.text(TuLines.use));
      await _pump(t, 1800);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck after the job');
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('beat 1 is his alone: tapping the guide while he talks says nothing; then his deck', (t) async {
      CoworkerTiming.debugReadHoldInTests = true;
      final seed = _seedWhere((d) => d.callAt == 0);
      final deal = dealToolUse(math.Random(seed));
      final c = await _open(t, seed);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      expect(find.byType(ChoiceDeck), findsNothing, reason: 'still beat 1');
      final before = c.read(guideDirectorProvider).line;
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
      await t.pump(const Duration(milliseconds: 200));
      expect(c.read(guideDirectorProvider).line, before, reason: 'the guide stays quiet while he talks');
      await _pickRight(t, TuLines.coworkerFor(deal.cases[0].job).right);
      await _pump(t, 2600);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('no scene move in the praise window: a tool tapped while ◆ wait on the table does nothing', (t) async {
      final seed = _seedWhere((d) => d.callAt != 0);
      final deal = dealToolUse(math.Random(seed));
      final c = await _open(t, seed);
      final right = deal.cases[0].right;
      await t.tap(_tool(right));
      await _pump(t, 300);
      await t.tap(find.text(TuLines.use));
      // The job turns (1.1 s) and its ◆ go on the table.
      await _pump(t, 1300);
      final other = TuTool.values.firstWhere((x) => x != right);
      await t.tap(_tool(other), warnIfMissed: false);
      await _pump(t, 200);
      // Note: `_run.shown` already blocks `_canPlay` for this whole window, so
      // this check alone would pass without `!tableBusy`; tableBusy is the kit's
      // extra guard (and also keeps him from coming, see coworkerCanCome).
      expect(find.text(TuLines.use), findsNothing, reason: 'no tool can be taken up in the praise window');
      expect(find.byType(MistakeCard), findsNothing);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pickRight(t, TuLines.whyRight(deal.cases[0].job));
      await _pump(t, 3000);
      expect(find.text(TuLines.jobBn(deal.cases[1].job)), findsOneWidget, reason: 'the next job');
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('gesture hint: a sweep over every tool while choosing, over both buttons with a tool in hand', (t) async {
      GestureHints.debugEnableInTests = true;
      final seed = _seedWhere((d) => d.callAt != 0);
      final c = await _open(t, seed);
      IdleHintState hint() => t.state<IdleHintState>(find.descendant(of: find.byType(FullSceneFrame), matching: find.byType(IdleHint)).first);
      expect(hint().showing, isFalse);
      await _pump(t, 9000);
      expect(hint().showing, isTrue, reason: 'stuck at the box: the hand shows');
      expect(hint().debugOptions, hasLength(TuTool.values.length), reason: 'a sweep over every tool, never one');
      for (var i = 0; i < 20; i++) {
        await t.pump(const Duration(milliseconds: 120));
        final f = hint().debugFrame;
        if (f != null) expect(f.press, 0, reason: 'a sweep never presses a tool');
      }
      await t.tap(_tool(TuTool.sp13));
      await _pump(t, 300);
      expect(hint().showing, isFalse, reason: 'a touch hides it');
      await _pump(t, 9000);
      expect(hint().showing, isTrue);
      expect(hint().debugOptions, hasLength(2), reason: 'use / put back');
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('three wrong tools strike the level out', (t) async {
      final seed = _seedWhere((d) => d.callAt == 3);
      final deal = dealToolUse(math.Random(seed));
      final c = await _open(t, seed);
      for (var i = 0; i < 3; i++) {
        final wrong = deal.cases[i].job == TuJob.neutral ? TuTool.tester : TuTool.knife;
        final tool = deal.cases[i].right == wrong ? TuTool.meter : wrong;
        await t.tap(_tool(tool == deal.cases[i].right ? TuTool.sp13 : tool));
        await _pump(t, 300);
        await t.tap(find.text(TuLines.use));
        await _pump(t, 1200);
        if (i < 2) {
          expect(find.byType(MistakeCard), findsOneWidget);
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 800);
        }
      }
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });
  });
}
