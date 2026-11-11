// Lesson 2.3 (ল্যাগস ক্রিম্পিং), কাজ 2 "ক্রিম্প করো ঠিকঠাক": the golden rules
// as a run (strip to the mark, brush, insert fully, the matching die, the tool
// on the barrel, the full cycle, the pull test before fitting), the tray of
// crimped lugs to inspect, the deal, the reason libraries, and the level in
// the shell: idle perf, the guide first, a full clean play with the coworker
// refused, a bad crimp that glows before its card and starts the job again,
// listening to him (pliers), a good lug set aside (not scored), 3 slips.
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
import 'package:slm_flutter/features/game/level_frame.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m2_crimp_steps.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';

const _ctx = LevelContext(
  rungId: '2.3/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '2.3',
  lessonTitleBn: '',
  ladderStep: 40,
  doIndex: 2,
  doCount: 2,
);

final _pack = m2CrimpStepsPacks['do_2_3_b']!;

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
Finder _key(String k) => find.byKey(ValueKey(k));
List<Finder> _onScreen(List<String> texts) => [
      for (final x in texts)
        if (_label(x).evaluate().isNotEmpty) _label(x),
    ];

Future<void> _pickRight(WidgetTester t, List<String> right) async {
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = _onScreen(right);
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
  await t.pump();
  // Wait for reason zoom (coworker decks have no proceed).
  for (var i = 0; i < 40 && find.byKey(const ValueKey('reason-proceed-btn')).evaluate().isEmpty; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
  final go = find.byKey(const ValueKey('reason-proceed-btn'));
  if (go.evaluate().isNotEmpty) {
    await t.tap(go, warnIfMissed: false);
    await t.pump();
  }
}

Future<void> _step(WidgetTester t, CrimpStep s, {int ms = 500}) async {
  await t.tap(_key('step-${s.name}'));
  await _pump(t, ms);
}

Future<void> _hold(WidgetTester t, String mode, int ms) async {
  final pad = _key('hud-hold-$mode');
  expect(pad, findsOneWidget, reason: mode);
  final g = await t.startGesture(t.getCenter(pad));
  await _pump(t, ms);
  await g.up();
  await _pump(t, 300);
}

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
    builder: (_) => M2CrimpStepsPage(ctx: _ctx, pack: _pack, muted: true, seed: seed),
  )));
  await _pump(t, 1000);
  await waitIntro(t);
  await _pump(t, 1200);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

/// Makes the crimp up to the tool on the barrel (strip, brush, paste on Al,
/// insert, die, crimp → place).
Future<void> _prepare(WidgetTester t, CrimpDeal deal, int i, {bool refuse = true}) async {
  final job = deal.rounds[i].job!;
  await _step(t, CrimpStep.strip);
  await t.tap(_key('mark-${job.marks.indexOf(1.0)}'));
  await _pump(t, 400);
  await _step(t, CrimpStep.clean, ms: 900);
  if (job.al) await _step(t, CrimpStep.paste);
  await _step(t, CrimpStep.insert);
  await _hold(t, 'insert', 1400);
  await _step(t, CrimpStep.die);
  await t.tap(_key('die-${job.size}'));
  await _pump(t, 400);
  await _step(t, CrimpStep.crimp);
  if (i == deal.callAt) {
    expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes on round $i');
    await _pumpUntil(t, find.byType(ChoiceDeck));
    await _pump(t, 600);
    if (!refuse) return;
    await _pickRight(t, CrimpLines.coworker.right);
    await _pump(t, 2600);
  }
}

Future<void> _playRight(WidgetTester t, CrimpDeal deal, int i) async {
  final r = deal.rounds[i];
  if (r.inspect) {
    for (final (k, lug) in r.lugs.indexed) {
      if (lug != LugKind.good) {
        await t.tap(_key('lug-$k'));
        await _pump(t, 300);
      }
    }
    await t.tap(find.text(CrimpLines.trayDone));
    await _pump(t, 2600);
  } else {
    await _prepare(t, deal, i);
    await t.tap(_key('spot-true'));
    await _pump(t, 400);
    await _hold(t, 'press', 1900);
    await _pump(t, 500);
    await _step(t, CrimpStep.pull, ms: 900);
    await _step(t, CrimpStep.fit, ms: 2600);
  }
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'round $i');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 700);
  await _pickRight(t, CrimpLines.whyRight(r, pasted: !r.inspect && r.job!.al));
  await _pump(t, 5000);
}

CrimpJob _job({int size = 16, CrimpMetal metal = CrimpMetal.al}) =>
    CrimpJob(size: size, metal: metal, marks: const [0.75, 1.0, 1.3], dies: [size - 6, size, size + 9]);
CrimpRun _make([CrimpJob? j]) => CrimpRun(CrimpDeal(rounds: [CrimpRound.make(j ?? _job())], callAt: 0));

/// Everything right up to the press.
CrimpRun _ready([CrimpJob? j]) {
  final r = _make(j)
    ..strip(1.0)
    ..clean()
    ..paste()
    ..setInserted(1)
    ..pickDie((j ?? _job()).size);
  expect(r.startCrimp(), isNull);
  expect(r.place(barrel: true), isNull);
  return r;
}

void main() {
  group('rules', () {
    test('deals: two crimps and one tray (2nd or 3rd), sizes differ, marks and dies hold the right one; he comes on a crimp', () {
      final seen = <String>{};
      final at = <int>{};
      final kinds = <LugKind>{};
      for (var s = 0; s < 80; s++) {
        final d = dealCrimp(math.Random(s));
        expect(d.rounds, hasLength(3));
        final trays = [
          for (final (i, r) in d.rounds.indexed)
            if (r.inspect) i,
        ];
        expect(trays, hasLength(1));
        expect(trays.single, inInclusiveRange(1, 2));
        at.add(trays.single);
        expect(d.rounds[d.callAt].inspect, isFalse);
        final jobs = [for (final r in d.rounds) ?r.job];
        expect(jobs.map((j) => j.size).toSet(), hasLength(2));
        for (final j in jobs) {
          expect(kCrimpSizes, contains(j.size));
          expect(j.marks, hasLength(3));
          expect(j.marks, contains(1.0));
          expect(j.dies.toSet(), hasLength(3));
          expect(j.dies, contains(j.size));
        }
        final tray = d.rounds[trays.single].lugs;
        expect(tray, hasLength(4));
        final good = tray.where((k) => k == LugKind.good).length;
        expect(good, inInclusiveRange(1, 2));
        expect(tray.where((k) => k != LugKind.good).toSet(), hasLength(4 - good), reason: 'bad ones of different kinds');
        kinds.addAll(tray);
        seen.add('${jobs.map((j) => '${j.size}${j.metal.name}${j.marks}${j.dies}').join()}$tray${d.callAt}');
      }
      expect(seen.length, greaterThan(70), reason: 'every play is dealt fresh');
      expect(at, {1, 2});
      expect(kinds, containsAll(LugKind.values));
    });

    test('the golden rules: strip to the mark, then the brush, then the conductor in', () {
      final r = _make();
      expect(r.clean(), CrimpMistakes.prep);
      expect(r.startInsert(), CrimpMistakes.prep);
      expect(r.strip(1.3), CrimpMistakes.stripLength);
      expect(r.strip(0.75), CrimpMistakes.stripLength);
      expect(r.stripped, isFalse);
      expect(r.slips, 4);
      expect(r.shown, isFalse, reason: 'order slips do not end the job');
      expect(r.strip(1.0), isNull);
      expect(r.paste(), CrimpMistakes.prep, reason: 'paste on a cleaned conductor');
      expect(r.startInsert(), CrimpMistakes.prep);
      expect(r.clean(), isNull);
      expect(r.startInsert(), isNull);
      r.setInserted(0.6);
      expect(r.fullyIn, isFalse);
      expect(r.startCrimp(), CrimpMistakes.notIn);
      expect(r.shown, isTrue, reason: 'a bad crimp: the job starts again');
      r.redo();
      expect(r.stripped, isFalse);
      expect(r.inserted, 0);
    });

    test('the die must match, the tool on the barrel, the full cycle; then the pull test before fitting', () {
      final noDie = _make()
        ..strip(1.0)
        ..clean()
        ..setInserted(1);
      expect(noDie.startCrimp(), CrimpMistakes.noDie);
      expect(noDie.shown, isFalse);
      final palm = _make()
        ..strip(1.0)
        ..clean()
        ..setInserted(1)
        ..pickDie(16);
      expect(palm.startCrimp(), isNull);
      expect(palm.place(barrel: false), CrimpMistakes.onPalm);
      expect(palm.shown, isTrue);
      expect(_ready().press(0.7), CrimpMistakes.halfPress);
      final wrong = _make()
        ..strip(1.0)
        ..clean()
        ..setInserted(1)
        ..pickDie(25);
      wrong
        ..startCrimp()
        ..place(barrel: true);
      expect(wrong.press(1), CrimpMistakes.wrongDie);
      final ok = _ready();
      expect(ok.press(1), isNull);
      expect(ok.crimped, isTrue);
      expect(ok.fit(), CrimpMistakes.noPull);
      expect(ok.pull(), PullResult.held);
      expect(ok.fit(), isNull);
      expect(ok.shown, isTrue);
      expect(ok.slips, 1);
      expect(ok.caught, containsAll([CrimpLines.caughtSteps, CrimpLines.caughtPaste, CrimpLines.caughtPull]));
    });

    test('pulling before the crimp: the conductor slides out (not a slip)', () {
      final r = _make()
        ..strip(1.0)
        ..clean()
        ..setInserted(1);
      expect(r.pull(), PullResult.slidOut);
      expect(r.inserted, 0);
      expect(r.slips, 0);
      expect(_make().pull(), PullResult.nothing);
    });

    test('the paste on aluminium is the +5 (a good habit, never a slip); copper has none', () {
      final al = _make()
        ..strip(1.0)
        ..clean();
      expect(al.thorough, isFalse);
      expect(al.paste(), isNull);
      expect(al.thorough, isTrue);
      final cu = _make(_job(metal: CrimpMetal.cu))
        ..strip(1.0)
        ..clean();
      expect(cu.paste(), isNull);
      expect(cu.pasted, isFalse);
      expect(cu.thorough, isTrue);
      expect(dealTray(_job(metal: CrimpMetal.cu), math.Random(1)), isNot(contains(CrimpStep.paste)));
      expect(dealTray(_job(), math.Random(1)), contains(CrimpStep.paste));
      final orders = {for (var s = 0; s < 20; s++) dealTray(_job(), math.Random(s)).join()};
      expect(orders.length, greaterThan(10), reason: 'the tray is shuffled');
    });

    test('pliers (the coworker) is a bad crimp', () {
      final r = _make();
      expect(r.pliers(), CrimpMistakes.pliers);
      expect(r.slips, 1);
      expect(r.shown, isTrue);
      expect(CrimpMistakes.ruins, containsAll([CrimpMistakes.pliers, CrimpMistakes.halfPress, CrimpMistakes.wrongDie, CrimpMistakes.notIn, CrimpMistakes.onPalm]));
    });

    test('the tray: every bad lug rejected passes; one let through is one slip; a good one set aside is put back unscored', () {
      CrimpRun tray(List<LugKind> l) => CrimpRun(CrimpDeal(rounds: [CrimpRound.inspect(l)], callAt: 0));
      const lugs = [LugKind.good, LugKind.cracked, LugKind.strands, LugKind.good];
      final a = tray(lugs)
        ..toggle(1)
        ..toggle(2);
      expect(a.falseRejects, isEmpty);
      expect(a.passTray(), isNull);
      expect(a.caught, containsAll([CrimpLines.caughtKind(LugKind.cracked), CrimpLines.caughtKind(LugKind.strands)]));
      expect(a.thorough, isTrue);
      final b = tray(lugs)
        ..toggle(1)
        ..toggle(0)
        ..toggle(3);
      expect(b.falseRejects, [0, 3]);
      b.unreject(b.falseRejects);
      expect(b.rejected, {1});
      expect(b.slips, 0);
      expect(b.thorough, isFalse);
      expect(b.passTray(), CrimpMistakes.passStrands);
      expect(b.slips, 1);
      expect(b.shown, isTrue);
      final c = tray(const [LugKind.under, LugKind.pliers, LugKind.good, LugKind.cracked]);
      expect(c.passTray(), CrimpMistakes.passUnder);
      expect(c.slips, 1, reason: 'one slip however many');
      for (final k in LugKind.values.where((k) => k != LugKind.good)) {
        expect(CrimpMistakes.passed(k).lessonPoint, 3);
      }
    });

    test('mark: 100 − 15 × slips; pass ≥ 55', () {
      final r = _make();
      for (var i = 0; i < 3; i++) {
        r.clean();
      }
      expect(r.percent, 55);
      r.clean();
      expect(r.percent, 40);
    });

    test('English digits; every mistake has its picture and key; no deadly; lesson points', () {
      final all = [
        ...CrimpLines.guideLines,
        ...CrimpLines.makeWhy,
        ...CrimpLines.trayWhy,
        CrimpLines.pasteWhy,
        ...CrimpLines.myths,
        ...CrimpLines.coworker.recordedLines,
        ...CrimpLines.coworker.right,
        ...CrimpLines.coworker.wrong,
        CrimpLines.cablePrint(_job()),
        CrimpLines.dieBn(16),
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
      }
      expect(CrimpLines.cablePrint(_job()), '16 sq.mm AL');
      for (final m in CrimpMistakes.all) {
        expect(m.deadly, isFalse, reason: m.key);
        expect(m.key, startsWith('2.3/crimp/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m != CrimpMistakes.pliers) expect(m.lessonPoint, inInclusiveRange(0, 3), reason: m.key);
      }
      expect(CrimpMistakes.all.map((m) => m.key).toSet(), hasLength(CrimpMistakes.all.length));
      expect(CrimpMistakes.pliers.lessonPoint, isNull, reason: 'the myth buster is not a lesson point');
      expect(m2CrimpStepsPacks.keys, ['do_2_3_b']);
      expect(_pack.quickMs, 80000);
    });

    test('reasons: same length, big enough, the wrong ones are myths; the coworker deck; his snarl is recorded', () {
      expectSameLength('why', [...CrimpLines.makeWhy, ...CrimpLines.trayWhy, CrimpLines.pasteWhy, ...CrimpLines.myths]);
      for (final r in [CrimpRound.make(_job()), CrimpRound.inspect(const [LugKind.good])]) {
        final right = CrimpLines.whyRight(r, pasted: true);
        expectLibrary('why', right, CrimpLines.myths);
        for (var s = 0; s < 10; s++) {
          final deal = dealChoices(right, CrimpLines.myths, math.Random(s));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      expect(CrimpLines.whyRight(CrimpRound.make(_job()), pasted: false), isNot(contains(CrimpLines.pasteWhy)));
      final cw = CrimpLines.coworker;
      expectSameLength('choice', [...cw.right, ...cw.wrong]);
      expectLibrary('choice', cw.right, cw.wrong);
      expect(LearnVoice.resolve(cw.exitLine, rival: true), isNotNull);
      // His push is new: device TTS until recorded (listed in REGISTER.md).
      expect(LearnVoice.resolve(cw.line, rival: true), isNull);
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
        t.view.physicalSize = const Size(720, 1600);
        t.view.devicePixelRatio = 2.0;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        await t.pumpWidget(ProviderScope(child: MaterialApp(home: M2CrimpStepsPage(ctx: _ctx, pack: _pack, muted: true, seed: 4))));
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
        debugPrint('PERF m2_crimp_steps ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
        expect(t.takeException(), isNull);
        expect(find.textContaining('ধাপ '), findsOneWidget);
        expect(perSec, lessThan(20));
        expect(frames, lessThan(12));
        await t.pumpWidget(const SizedBox());
        await t.pump(const Duration(seconds: 15));
        MascotTalk.reset();
        t.platformDispatcher.clearAccessibilityFeaturesTestValue();
        t.view.reset();
      });
    }

    testWidgets('the guide comes first: a tap does not skip him; tapping him restates the task differently', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      final c = ProviderContainer();
      await t.pumpWidget(UncontrolledProviderScope(container: c, child: MaterialApp(home: M2CrimpStepsPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(_key('step-strip'), findsNothing);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_key('step-strip'), findsOneWidget);
      final guide = find.byKey(const ValueKey('hud-guide'));
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(CrimpLines.askMake)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('flow: every round right, the coworker refused → pass, saved', (t) async {
      final deal = dealCrimp(math.Random(5));
      final c = await _open(t, 5);
      for (var i = 0; i < 3; i++) {
        await _playRight(t, deal, i);
      }
      await _pump(t, 2000);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['2.3/do/1'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['2.3/do/1'], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(CrimpLines.caughtCall), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a half press: the joint glows first, then the card; then the job starts again', (t) async {
      var seed = 0;
      while (dealCrimp(math.Random(seed)).callAt == 0) {
        seed++;
      }
      final deal = dealCrimp(math.Random(seed));
      final c = await _open(t, seed);
      await _prepare(t, deal, 0);
      await t.tap(_key('spot-true'));
      await _pump(t, 400);
      await _hold(t, 'press', 600);
      expect(find.byType(MistakeCard), findsNothing, reason: 'the glow comes first');
      await _pump(t, 2600);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, CrimpMistakes.halfPress.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      expect(find.byType(MistakeCard), findsNothing);
      // The same job again from the start: strip is open again.
      await _step(t, CrimpStep.strip);
      expect(_key('mark-0'), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('an order slip (brush before strip): its card, the job goes on', (t) async {
      final c = await _open(t, 2);
      await _step(t, CrimpStep.clean);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, CrimpMistakes.prep.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(_key('step-strip'), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('listening to him: pliers, the glow, the card', (t) async {
      var seed = 0;
      while (dealCrimp(math.Random(seed)).callAt != 0) {
        seed++;
      }
      final deal = dealCrimp(math.Random(seed));
      final c = await _open(t, seed);
      await _prepare(t, deal, 0, refuse: false);
      final wrong = _onScreen(CrimpLines.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await _pump(t, 3200);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, CrimpMistakes.pliers.key);
      await _close(t, c);
    });

    testWidgets('the tray: a good lug set aside is put back, not scored; a bad one let through is a slip', (t) async {
      var seed = 0;
      while (dealCrimp(math.Random(seed)).rounds[1].inspect == false || dealCrimp(math.Random(seed)).callAt != 0) {
        seed++;
      }
      final deal = dealCrimp(math.Random(seed));
      final c = await _open(t, seed);
      await _playRight(t, deal, 0);
      final lugs = deal.rounds[1].lugs;
      final good = lugs.indexOf(LugKind.good);
      await t.tap(_key('lug-$good'));
      await _pump(t, 300);
      await t.tap(find.text(CrimpLines.trayDone));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(c.read(guideDirectorProvider).line, CrimpLines.goodLug);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      // Now pass the tray as it is (every bad lug let through).
      await t.tap(find.text(CrimpLines.trayDone));
      await _pump(t, 3200);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, CrimpMistakes.passed(lugs.firstWhere((k) => k != LugKind.good)).key);
      await _close(t, c);
    });

    testWidgets('three slips fail the level', (t) async {
      final c = await _open(t, 2);
      for (var i = 0; i < 3; i++) {
        await _step(t, CrimpStep.clean);
        if (i < 2) {
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });
  });
}
