// Lesson 2.2 (মাল্টিমিটারের জাদু), কাজ 2 "লাইভ-ডেড-লাইভ": the rules (prove the
// meter on the known source → test every pair → prove again; a cut lead or a
// lead that breaks mid-test reads 0.0 everywhere; a ghost voltage goes to zero
// with a load; a live phase), the deal, the reason libraries, and the level
// in the shell: idle perf, the guide first, a full clean play (bad meters
// swapped, the ghost checked, the live line stopped, the coworker refused), a
// needless stop that is not scored, a slip card, and the deadly freeze
// (touching on an unproven meter's zero on his say-so; touching untested).
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
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m2_dead_test.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';

const _ctx = LevelContext(
  rungId: '2.2/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '2.2',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m2DeadTestPacks['do_2_2_b']!;

/// The level's mistake art is in a new folder the director adds to pubspec;
/// until then the tests read it from disk.
class _DiskBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key.startsWith('assets/game/art/m2_dead_test/')) {
      final b = File(key).readAsBytesSync();
      return ByteData.view(b.buffer);
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

Future<void> _pickRight(WidgetTester t, List<String> right) async {
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = _onScreen(right);
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
}

/// Design px → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
DeadGeo get _geo => DeadGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);

String _meter() {
  final f = find.byKey(const ValueKey('meter-value'));
  return f.evaluate().isEmpty ? '' : (f.evaluate().first.widget as Text).data ?? '';
}

Future<void> _prove(WidgetTester t) async {
  await t.tapAt(_geo.prover.center * _k);
  await _pump(t, 1000);
}

Future<void> _testPair(WidgetTester t, DeadSite s, DeadPair p) async {
  await t.tapAt(_geo.terminal(s, p.a) * _k);
  await _pump(t, 150);
  await t.tapAt(_geo.terminal(s, p.b) * _k);
  await _pump(t, 1000);
}

Future<ProviderContainer> _open(WidgetTester t, int seed) async {
  t.view.physicalSize = const Size(784, 1700);
  t.view.devicePixelRatio = 2.0;
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
    builder: (_) => M2DeadTestPage(ctx: _ctx, pack: _pack, muted: true, seed: seed),
  )));
  await _pump(t, 1000);
  await waitIntro(t);
  await _pump(t, 1500);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

/// Plays round [i] right: proofs (swapping a bad meter), every pair (the
/// ghost checked with a load), the proof again; on a live line, stop; his
/// round: he is refused. Then the reason.
Future<void> _playRight(WidgetTester t, DeadDeal deal, int i) async {
  final c = deal.cases[i];
  var cwDone = false;
  Future<void> coworker() async {
    if (i != deal.callAt || cwDone) return;
    if (!await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 3500)) return;
    cwDone = true;
    await _pumpUntil(t, find.byType(ChoiceDeck));
    await _pump(t, 600);
    await _pickRight(t, DeadLines.coworker.right);
    await _pump(t, 1500);
  }

  await _prove(t);
  if (c.fault == DeadFault.cutLead) {
    expect(_meter(), DeadLines.volts(0), reason: 'a cut lead reads 0.0 on the known source');
    await t.tap(_label(DeadLines.swap));
    await _pump(t, 300);
    await _prove(t);
  }
  expect(_meter(), DeadLines.volts(kProverVolts));
  Future<void> allPairs() async {
    final pairs = [...c.pairs];
    if (c.live) pairs.sort((a, b) => (a.has(c.livePoint!) ? 1 : 0) - (b.has(c.livePoint!) ? 1 : 0));
    for (final p in pairs) {
      await _testPair(t, c.site, p);
      if (c.line == DeadLine.ghost && p == c.ghostPair) {
        await t.tap(_label(DeadLines.load));
        await _pump(t, 1000);
      }
      await coworker();
    }
  }

  await allPairs();
  await _prove(t);
  if (c.fault == DeadFault.breaksMid) {
    expect(_meter(), DeadLines.volts(0), reason: 'the lead broke during the test');
    await t.tap(_label(DeadLines.swap));
    await _pump(t, 300);
    await _prove(t);
    await allPairs();
    await _prove(t);
  }
  expect(_meter(), DeadLines.volts(kProverVolts));
  await t.tap(find.text(c.live ? DeadLines.stop : DeadLines.touch));
  await _pump(t, 1500);
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'round $i ${c.line} ${c.fault}');
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'round $i');
  await _pump(t, 700);
  await _pickRight(t, DeadLines.whyRight(c));
  await _pump(t, 4000);
}

void main() {
  group('rules', () {
    test('deals: two LT boxes and a house board; dead, ghost and live once each; a cut lead every play', () {
      final seen = <String>{};
      final calls = <int>{};
      for (var s = 0; s < 80; s++) {
        final d = dealDead(math.Random(s));
        expect(d.cases.length, 3);
        expect(d.cases.where((c) => c.site == DeadSite.threePhase).length, 2);
        expect(d.cases.map((c) => c.line).toSet(), DeadLine.values.toSet());
        expect(d.cases.where((c) => c.fault == DeadFault.cutLead).length, 1);
        expect(d.cases.where((c) => c.fault == DeadFault.breaksMid).length, lessThanOrEqualTo(1));
        for (final c in d.cases) {
          if (c.live) expect(c.livePoint, isNot(DeadPoint.n));
          if (c.line == DeadLine.ghost) {
            expect(c.ghostPair!.has(DeadPoint.n), isTrue);
            expect(c.ghostVolts, inInclusiveRange(10, 50));
          }
        }
        final call = d.cases[d.callAt];
        expect(call.site == DeadSite.single && call.live, isFalse, reason: 'he needs a 0.0 on his round');
        calls.add(d.callAt);
        seen.add(d.cases.map((c) => '${c.site.name}${c.fault.name}${c.line.name}${c.livePoint}${c.ghostPair}').join('|') + d.callAt.toString());
      }
      expect(seen.length, greaterThan(50), reason: 'every play is dealt fresh');
      expect(calls, {0, 1, 2});
    });

    DeadRun run1(DeadCase c) => DeadRun(DeadDeal(cases: [c], callAt: 0));
    const r = DeadPoint.r, y = DeadPoint.y, b = DeadPoint.b, n = DeadPoint.n;
    void allPairs(DeadRun run) {
      for (final p in run.current.pairs) {
        run.test(p);
      }
    }

    test('every combination: phase-to-phase and phase-to-neutral (3φ six, 1φ one)', () {
      expect(deadPairs(DeadSite.threePhase).toSet().length, 6);
      expect(deadPairs(DeadSite.single), [const DeadPair(DeadPoint.p, DeadPoint.n)]);
      expect(const DeadPair(r, n), const DeadPair(n, r));
    });

    test('prove → all pairs → prove again → touch is right', () {
      final a = run1(const DeadCase(id: 'x', site: DeadSite.threePhase, fault: DeadFault.none, line: DeadLine.dead));
      expect(a.prove()!.volts, kProverVolts);
      allPairs(a);
      expect(a.prove()!.volts, kProverVolts);
      expect(a.decide(touch: true), isNull);
      expect(a.shown, isTrue);
      expect(a.caught, containsAll([DeadLines.caughtProve, DeadLines.caughtPairs]));
    });

    test('a zero from an unproven meter: touching is deadly; untested too', () {
      final a = run1(const DeadCase(id: 'x', site: DeadSite.threePhase, fault: DeadFault.cutLead, line: DeadLine.dead));
      expect(a.test(const DeadPair(r, n))!.volts, 0);
      expect(a.decide(touch: true), DeadMistakes.unproven);
      expect(a.ended, isTrue);
      final b = run1(const DeadCase(id: 'x', site: DeadSite.single, fault: DeadFault.none, line: DeadLine.dead));
      expect(b.decide(touch: true)!.deadly, isTrue, reason: 'no test at all');
    });

    test('a cut lead reads 0.0 on the known source and on the line; the other meter reads true', () {
      final a = run1(const DeadCase(id: 'x', site: DeadSite.single, fault: DeadFault.cutLead, line: DeadLine.live, livePoint: DeadPoint.p));
      expect(a.prove()!.volts, 0);
      expect(a.meterSuspect, isTrue);
      expect(a.test(const DeadPair(DeadPoint.p, n))!.volts, 0, reason: 'the lie that kills');
      expect(a.valid, isEmpty);
      a.swap();
      expect(a.prove()!.volts, kProverVolts);
      expect(a.test(const DeadPair(DeadPoint.p, n))!.volts, kLiveVolts);
      expect(a.decide(touch: true), DeadMistakes.touchLive);
      final ok = run1(const DeadCase(id: 'x', site: DeadSite.single, fault: DeadFault.none, line: DeadLine.live, livePoint: DeadPoint.p));
      expect(ok.decide(touch: false), isNull);
      expect(ok.shown, isTrue);
      expect(ok.caught, contains(DeadLines.caughtLive));
    });

    test('a lead that breaks mid-test: the proof after fails and voids the tests (touch = deadly); skipping it = slip', () {
      const c = DeadCase(id: 'x', site: DeadSite.threePhase, fault: DeadFault.breaksMid, line: DeadLine.dead, breakAfter: 2);
      final a = run1(c)..prove();
      allPairs(a);
      expect(a.meterOk, isFalse);
      expect(a.prove()!.volts, 0);
      expect(a.valid, isEmpty);
      expect(a.decide(touch: true), DeadMistakes.unproven);
      final b = run1(c)..prove();
      allPairs(b);
      expect(b.decide(touch: true), DeadMistakes.noReprove);
      expect(b.slips, 1);
      final ok = run1(c)..prove();
      allPairs(ok);
      ok
        ..prove()
        ..swap()
        ..prove();
      allPairs(ok);
      ok.prove();
      expect(ok.decide(touch: true), isNull);
      expect(ok.caught, contains(DeadLines.caughtBadMeter));
    });

    test('a pair left untested is a slip (unless it was the live one: deadly)', () {
      final a = run1(const DeadCase(id: 'x', site: DeadSite.threePhase, fault: DeadFault.none, line: DeadLine.dead))..prove();
      a.test(const DeadPair(r, n));
      a.prove();
      expect(a.decide(touch: true), DeadMistakes.missedPair);
      final l = run1(const DeadCase(id: 'x', site: DeadSite.threePhase, fault: DeadFault.none, line: DeadLine.live, livePoint: DeadPoint.b))..prove();
      l.test(const DeadPair(r, y));
      l.prove();
      expect(l.decide(touch: true)!.deadly, isTrue);
    });

    test('a ghost voltage: unsteady; a load takes it to zero; touching unchecked = slip; a real voltage stays', () {
      const c = DeadCase(id: 'x', site: DeadSite.threePhase, fault: DeadFault.none, line: DeadLine.ghost, ghostPair: DeadPair(y, n), ghostVolts: 31);
      final a = run1(c)..prove();
      allPairs(a);
      a.prove();
      expect(a.ghostSeen, isTrue);
      expect(a.decide(touch: true), DeadMistakes.ghostUnchecked);
      final ok = run1(c)..prove();
      final g = ok.test(const DeadPair(y, n))!;
      expect(g.volts, 31);
      expect(g.unsteady, isTrue);
      expect(ok.loadTest()!.volts, 0);
      expect(ok.ghostChecked, isTrue);
      allPairs(ok);
      ok.prove();
      expect(ok.decide(touch: true), isNull);
      expect(ok.thorough, isTrue);
      expect(ok.caught, contains(DeadLines.caughtGhost));
      final live = run1(const DeadCase(id: 'x', site: DeadSite.threePhase, fault: DeadFault.none, line: DeadLine.live, livePoint: DeadPoint.r))..prove();
      expect(live.test(const DeadPair(r, b))!.volts, kLiveVolts);
      expect(live.loadTest()!.volts, kLiveVolts);
    });

    test('a stop on a dead line is not scored: no mistake, the round stays', () {
      final a = run1(const DeadCase(id: 'x', site: DeadSite.single, fault: DeadFault.none, line: DeadLine.dead));
      expect(a.decide(touch: false), isNull);
      expect(a.shown, isFalse);
      expect(a.needless, 1);
      expect(a.slips, 0);
    });

    test('three slips fail the level (percent below 55)', () {
      final d = DeadDeal(cases: [
        for (var i = 0; i < 3; i++) const DeadCase(id: 'x', site: DeadSite.threePhase, fault: DeadFault.none, line: DeadLine.dead),
      ], callAt: 0);
      final run = DeadRun(d);
      for (var i = 0; i < 3; i++) {
        run.prove();
        run.test(const DeadPair(r, n));
        expect(run.decide(touch: true), DeadMistakes.missedPair);
        run.next();
      }
      expect(run.done, isTrue);
      expect(run.percent, 55);
      expect(run.slips, 3);
    });

    test('libraries: decks of three, one right; lengths within 1.3×; the coworker; his exit line recorded', () {
      for (final line in DeadLine.values) {
        final c = DeadCase(
            id: 'x',
            site: DeadSite.threePhase,
            fault: DeadFault.none,
            line: line,
            livePoint: line == DeadLine.live ? r : null,
            ghostPair: line == DeadLine.ghost ? const DeadPair(r, n) : null);
        final right = DeadLines.whyRight(c);
        final wrong = DeadLines.whyWrong(c);
        expectLibrary('why ${line.name}', right, wrong);
        expectSameLength('why ${line.name}', [...right, ...wrong]);
        if (line == DeadLine.ghost) expect(right, contains(DeadLines.ghostWhy));
        for (var s = 0; s < 10; s++) {
          final deal = dealChoices(right, wrong, math.Random(s));
          expect(deal.where((o) => o.correct).length, 1);
          expect(deal.map((o) => o.textBn).toSet().length, 3);
        }
      }
      final cw = DeadLines.coworker;
      expectSameLength('choice', [...cw.right, ...cw.wrong]);
      expectLibrary('choice', cw.right, cw.wrong);
      expect(LearnVoice.resolve(cw.exitLine, rival: true), isNotNull);
      for (final m in DeadMistakes.all) {
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
      }
      expect(m2DeadTestPacks.keys, ['do_2_2_b']);
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
        await t.pumpWidget(ProviderScope(
          child: MaterialApp(home: M2DeadTestPage(ctx: _ctx, pack: _pack, muted: true, seed: 4)),
        ));
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
        debugPrint('PERF m2_dead_test ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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

    testWidgets('a ghost reading settles to quiet too', (t) async {
      var seed = 0;
      while (dealDead(math.Random(seed)).cases[0].line != DeadLine.ghost || dealDead(math.Random(seed)).callAt == 0) {
        seed++;
      }
      final c0 = dealDead(math.Random(seed)).cases[0];
      final c = await _open(t, seed);
      await _testPair(t, c0.site, c0.ghostPair!);
      await _pump(t, 6000);
      var frames = 0;
      for (var i = 0; i < 60; i++) {
        if (t.binding.hasScheduledFrame) frames++;
        await t.pump(const Duration(milliseconds: 16));
      }
      expect(frames, lessThan(12));
      await _close(t, c);
    });

    testWidgets('the guide comes first: a tap does not skip him', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M2DeadTestPage(ctx: _ctx, pack: _pack, muted: true, seed: 2))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text(DeadLines.touch), findsNothing);
      await waitIntro(t);
      await _pump(t, 1500);
      expect(find.text(DeadLines.touch), findsOneWidget);
      expect(find.text(DeadLines.stop), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final c = await _open(t, 3);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(DeadLines.ask)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('flow: prove, every pair, prove again — bad meters swapped, ghost checked, live stopped, coworker refused → pass', (t) async {
      var seed = 1;
      while (!dealDead(math.Random(seed)).cases.any((c) => c.fault == DeadFault.breaksMid)) {
        seed++;
      }
      final deal = dealDead(math.Random(seed));
      final c = await _open(t, seed);
      for (var i = 0; i < 3; i++) {
        await _playRight(t, deal, i);
      }
      await _pump(t, 3000);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['2.2/do/1'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['2.2/do/1'], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(DeadLines.caughtCall), findsOneWidget, reason: 'he came and was refused');
      await _close(t, c);
    });

    testWidgets('a stop on a dead line is not scored: no card, the guide says the rule, the round stays', (t) async {
      var seed = 0;
      while (dealDead(math.Random(seed)).cases[0].line != DeadLine.dead || dealDead(math.Random(seed)).callAt == 0) {
        seed++;
      }
      final c = await _open(t, seed);
      await t.tap(find.text(DeadLines.stop));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(find.byType(ChoiceDeck), findsNothing);
      expect(c.read(guideDirectorProvider).line, DeadLines.needlessDead);
      expect(find.text(DeadLines.touch), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('one pair only, then touch: the slip card', (t) async {
      var seed = 0;
      while (true) {
        final d = dealDead(math.Random(seed));
        final c0 = d.cases[0];
        if (d.callAt != 0 && c0.site == DeadSite.threePhase && c0.line == DeadLine.dead && c0.fault == DeadFault.none) break;
        seed++;
      }
      final c = await _open(t, seed);
      await _prove(t);
      await _testPair(t, DeadSite.threePhase, const DeadPair(DeadPoint.r, DeadPoint.n));
      await _prove(t);
      await t.tap(find.text(DeadLines.touch));
      await _pump(t, 800);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, DeadMistakes.missedPair.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 1500);
      expect(find.byType(MistakeCard), findsNothing);
      await _close(t, c);
    });

    testWidgets('his zero on an unproven meter: listening = deadly — freeze first, then the card', (t) async {
      var seed = 0;
      late DeadDeal deal;
      while (true) {
        deal = dealDead(math.Random(seed));
        if (deal.callAt == 0 && deal.cases[0].fault == DeadFault.cutLead && deal.cases[0].site == DeadSite.threePhase) break;
        seed++;
      }
      final c = await _open(t, seed);
      // Straight onto the circuit: no proof.
      await _testPair(t, DeadSite.threePhase, const DeadPair(DeadPoint.r, DeadPoint.n));
      expect(_meter(), DeadLines.volts(0));
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 4000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      final wrong = _onScreen(DeadLines.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, deal.cases[0].live ? DeadMistakes.touchLive.key : DeadMistakes.unproven.key);
      expect(s.mistakes.single.deadly, isTrue);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });
  });
}
