// Lesson 2.8 (ফেজ সিকোয়েন্স মিটার), কাজ 2 "উল্টো ঘুরছে পাম্প": the rules
// (gloves for the live test, probes off the earth bar, read the meter, swap
// any two phases only with the switch OFF + lock/tag + proven dead, test
// again before START; swapping live = deadly), the deal, the reason
// libraries, and the level in the shell: idle perf, the guide first, a full
// clean play with the coworker refused, a slip card that keeps the site, the
// deadly freeze (a screwdriver on live terminals; listening to him).
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
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m2_phase_swap.dart';
import 'package:slm_flutter/features/game/m2_phase_swap_world.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';

const _ctx = LevelContext(
  rungId: '2.8/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '2.8',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m2PhaseSwapPacks['do_2_8_b']!;

/// The new art is not in pubspec yet (the director adds the folder): tests
/// read it from disk when the bundle does not have it.
class _DiskBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    try {
      return await rootBundle.load(key);
    } catch (_) {
      final f = File(key);
      if (!f.existsSync()) rethrow;
      return ByteData.sublistView(f.readAsBytesSync());
    }
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

/// Design px → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
PhaseGeo get _geo => PhaseGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
Future<void> _tapAt(WidgetTester t, Offset design) async {
  await t.tapAt(design * _k);
  await _pump(t, 300);
}

Future<void> _tool(WidgetTester t, String label) async {
  await t.tap(_label(label));
  await _pump(t, 300);
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M2PhaseSwapPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

/// Gloves, the meter, the three clips; then reads it right.
Future<void> _testRight(WidgetTester t, {required bool forward, bool gloves = true}) async {
  if (gloves) await _tool(t, PhaseLines.gloves);
  await _tool(t, PhaseLines.meter);
  for (var i = 0; i < 3; i++) {
    await _tapAt(t, _geo.terminals[i]);
  }
  expect(find.text(forward ? PhaseLines.sayFwd : PhaseLines.sayRev), findsOneWidget);
  await t.tap(find.text(forward ? PhaseLines.sayFwd : PhaseLines.sayRev));
  await _pump(t, 600);
}

/// Plays site [i] right (the coworker refused on his site).
Future<void> _playRight(WidgetTester t, PhaseDeal deal, int i) async {
  final s = deal.sites[i];
  await _testRight(t, forward: s.kind == PhaseKind.fwd);
  if (s.kind == PhaseKind.rev) {
    if (i == deal.callAt) {
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes on site $i');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await _pickRight(t, PhaseLines.coworker.right);
      await _pump(t, 2600);
    }
    await _tapAt(t, _geo.handlePivot); // OFF
    await _tool(t, PhaseLines.lock);
    await _tool(t, PhaseLines.tester);
    expect(find.text(PhaseLines.testerDead), findsOneWidget);
    await _tool(t, PhaseLines.driver);
    await _tapAt(t, _geo.terminals[1]);
    await _tapAt(t, _geo.terminals[2]);
    await _tool(t, PhaseLines.lock); // off
    await _tapAt(t, _geo.handlePivot); // ON
    await _testRight(t, forward: true, gloves: false);
  }
  await _tapAt(t, _geo.startButton);
  await _pump(t, 2200);
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'site $i');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 700);
  await _pickRight(t, PhaseLines.whyRight(s));
  await _pump(t, 6000);
}

void main() {
  group('rules', () {
    test('deals: three sites, two reversed and one right; he comes to a reversed one; plays differ', () {
      final seen = <String>{};
      for (var s = 0; s < 80; s++) {
        final d = dealPhase(math.Random(s));
        expect(d.sites, hasLength(3));
        expect(d.sites.where((x) => x.kind == PhaseKind.rev), hasLength(2));
        expect(d.sites[d.callAt].kind, PhaseKind.rev);
        final whys = d.sites.map((x) => x.why).toList();
        expect(whys.toSet(), hasLength(3), reason: 'each site asks its own reason');
        for (final x in d.sites) {
          expect(x.why == PhaseWhy.keep, x.kind == PhaseKind.fwd);
        }
        seen.add(d.sites.map((x) => '${x.kind.name}${x.meter.name}${x.job.name}${x.why.name}').join('|') + d.callAt.toString());
      }
      expect(seen.length, greaterThan(40));
    });

    PhaseRun run1(PhaseKind k) => PhaseRun(PhaseDeal(sites: [PhaseSite(id: 'x', kind: k, meter: PhaseMeter.disc, job: PhaseJob.newService, why: k == PhaseKind.fwd ? PhaseWhy.keep : PhaseWhy.swap)], callAt: 0));

    void clip(PhaseRun r) {
      if (r.tool != PhaseTool.meter) r.hold(PhaseTool.meter);
      for (var i = 0; i < 3; i++) {
        expect(r.tapTerminal(i), isNull);
      }
    }

    test('the live test: gloves first; probes never on the earth bar; a misread is a slip', () {
      final r = run1(PhaseKind.rev)..hold(PhaseTool.meter);
      expect(r.tapTerminal(0), PhaseMistakes.noGloves);
      expect(r.probes, isEmpty);
      r.putGloves();
      expect(r.tapEarth(), PhaseMistakes.probeEarth);
      clip(r);
      expect(r.readingUp, isTrue);
      expect(r.answer(true), PhaseMistakes.misread);
      expect(r.readingUp, isTrue, reason: 'still to read');
      expect(r.answer(false), isNull);
      expect(r.fixing, isTrue);
      expect(r.slips, 3);
      expect(r.caught, containsAll([PhaseLines.caughtTest, PhaseLines.caughtRev]));
    });

    test('START: untested is a slip; reversed is a slip; a right sequence runs', () {
      final a = run1(PhaseKind.fwd);
      expect(a.start(), PhaseMistakes.untested);
      expect(a.pumpOn, isFalse);
      a.putGloves();
      clip(a);
      expect(a.answer(true), isNull);
      expect(a.start(), isNull);
      expect(a.pumpOn, isTrue);
      expect(a.caught, contains(PhaseLines.caughtFwd));
      final b = run1(PhaseKind.rev)..putGloves();
      clip(b);
      b.answer(false);
      expect(b.start(), PhaseMistakes.reverseRun);
      expect(b.pumpOn, isFalse);
    });

    test('a screwdriver on the terminals with the switch ON is deadly (also before any reading)', () {
      for (final k in PhaseKind.values) {
        final r = run1(k)..hold(PhaseTool.driver);
        final m = r.tapTerminal(1);
        expect(m, PhaseMistakes.swapLive);
        expect(m!.deadly, isTrue);
        expect(r.ended, isTrue);
      }
    });

    test('the swap: OFF, lock + tag, proven dead, after a REV reading; then test again before START', () {
      final r = run1(PhaseKind.rev)..putGloves();
      clip(r);
      r.answer(false);
      expect(r.toggleLock(), isFalse, reason: 'no lock on an ON handle');
      expect(r.toggleSwitch(), isTrue);
      r.hold(PhaseTool.driver);
      expect(r.tapTerminal(0), PhaseMistakes.noLock);
      expect(r.toggleLock(), isTrue);
      expect(r.toggleSwitch(), isFalse, reason: 'locked');
      expect(r.tapTerminal(0), PhaseMistakes.noProve);
      expect(r.test(), isFalse, reason: 'dead');
      expect(r.tapTerminal(0), isNull);
      expect(r.lifted, 0);
      expect(r.tapTerminal(2), isNull);
      expect(r.wires, [2, 1, 0]);
      expect(r.swapped, isTrue);
      expect(r.forward, isTrue);
      expect(r.caught, containsAll([PhaseLines.caughtSafe, PhaseLines.caughtSwap]));
      r.toggleLock();
      expect(r.toggleSwitch(), isTrue);
      expect(r.proved, isFalse, reason: 'ON again: live again');
      expect(r.start(), PhaseMistakes.noRetest);
      clip(r);
      expect(r.answer(true), isNull);
      expect(r.start(), isNull);
      expect(r.pumpOn, isTrue);
      expect(r.caught, contains(PhaseLines.caughtRetest));
      expect(r.slips, 3);
    });

    test('no swap without a reading, and none when the meter showed R-Y-B', () {
      PhaseRun isolated(PhaseKind k) => run1(k)
        ..toggleSwitch()
        ..toggleLock()
        ..test()
        ..hold(PhaseTool.driver);
      expect(isolated(PhaseKind.rev).tapTerminal(0), PhaseMistakes.swapUnread);
      final f = run1(PhaseKind.fwd)..putGloves();
      clip(f);
      f.answer(true);
      f
        ..toggleSwitch()
        ..toggleLock()
        ..test()
        ..hold(PhaseTool.driver);
      expect(f.tapTerminal(0), PhaseMistakes.needlessSwap);
      expect(f.wires, [0, 1, 2]);
    });

    test('the meter on dead terminals shows nothing', () {
      final r = run1(PhaseKind.rev)
        ..putGloves()
        ..toggleSwitch();
      clip(r);
      expect(r.readingUp, isFalse);
      expect(r.blank, isTrue);
      r.clearProbes();
      expect(r.probes, isEmpty);
    });

    test('English digits only; every mistake has its picture; one deadly', () {
      final all = <String>[
        PhaseLines.intro,
        ...PhaseLines.tasks,
        ...PhaseLines.allRight,
        ...PhaseLines.myths,
        ...PhaseLines.coworker.recordedLines,
        ...PhaseLines.coworker.right,
        ...PhaseLines.coworker.wrong,
        ...PhaseLines.coworker.asks,
        for (final m in PhaseMistakes.all) m.textBn,
        PhaseLines.allSet,
        PhaseLines.fail,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
      }
      expect(PhaseMistakes.all.where((m) => m.deadly), [PhaseMistakes.swapLive]);
      for (final m in PhaseMistakes.all) {
        expect(m.key, startsWith('2.8/phase/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 2));
      }
      expect(m2PhaseSwapPacks.keys, ['do_2_8_b']);
    });

    test('reasons: same length, big enough, never a rule marked wrong; his exit is recorded', () {
      expectSameLength('why', [...PhaseLines.allRight, ...PhaseLines.myths]);
      for (final w in PhaseWhy.values) {
        final s = PhaseSite(id: 'x', kind: w == PhaseWhy.keep ? PhaseKind.fwd : PhaseKind.rev, meter: PhaseMeter.digital, job: PhaseJob.cable, why: w);
        final right = PhaseLines.whyRight(s);
        expectLibrary('$w', right, PhaseLines.myths);
        expect(PhaseLines.myths.toSet().intersection(PhaseLines.allRight.toSet()), isEmpty);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(right, PhaseLines.myths, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      final cw = PhaseLines.coworker;
      expectSameLength('choice', [...cw.right, ...cw.wrong]);
      expectLibrary('choice', cw.right, cw.wrong);
      expect(LearnVoice.resolve(cw.exitLine, rival: true), isNotNull);
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
        await t.pumpWidget(ProviderScope(child: MaterialApp(home: M2PhaseSwapPage(ctx: _ctx, pack: _pack, muted: true, seed: 4))));
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
        debugPrint('PERF m2_phase_swap ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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

    testWidgets('the guide comes first: a tap does not skip him; then the docket and the tools', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M2PhaseSwapPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(_label(PhaseLines.meter), findsNothing);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_label(PhaseLines.meter), findsOneWidget);
      expect(find.text(PhaseLines.jobBn(dealPhase(math.Random(3)).sites[0].job)), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final c = await _open(t, 5);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(PhaseLines.askTest)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('flow: test, read, swap safely, test again, run; refuse him; right reasons → pass', (t) async {
      final deal = dealPhase(math.Random(7));
      final c = await _open(t, 7);
      for (var i = 0; i < 3; i++) {
        await _playRight(t, deal, i);
      }
      await _pump(t, 2000);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['2.8/do/1'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['2.8/do/1'], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(PhaseLines.caughtCall), findsOneWidget);
      expect(find.text(PhaseLines.caughtRetest), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a slip (START untested) shows its card; the same site goes on after it', (t) async {
      final c = await _open(t, 2);
      await _tapAt(t, _geo.startButton);
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(PhaseMistakes.untested.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_label(PhaseLines.meter), findsOneWidget, reason: 'the same pump house');
      expect(c.read(gameSaveProvider).mistakes.single.key, PhaseMistakes.untested.key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final c = await _open(t, 2);
      for (var i = 0; i < 3; i++) {
        await _tapAt(t, _geo.startButton);
        await _pump(t, 600);
        if (i < 2) {
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('a screwdriver on live terminals: the scene freezes first, then the card (near-miss)', (t) async {
      final c = await _open(t, 2);
      await _tool(t, PhaseLines.driver);
      await _tapAt(t, _geo.terminals[0]);
      await _pump(t, 500);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, PhaseMistakes.swapLive.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('listening to him = deadly: freeze, then the card', (t) async {
      final deal = dealPhase(math.Random(11));
      final c = await _open(t, 11);
      for (var i = 0; i < deal.callAt; i++) {
        await _playRight(t, deal, i);
      }
      await _testRight(t, forward: false);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      final wrong = _onScreen(PhaseLines.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('switching OFF while he talks refuses him', (t) async {
      final deal = dealPhase(math.Random(11));
      final c = await _open(t, 11);
      for (var i = 0; i < deal.callAt; i++) {
        await _playRight(t, deal, i);
      }
      await _testRight(t, forward: false);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 300);
      await _tapAt(t, _geo.handlePivot);
      await _pump(t, 1500);
      expect(find.byType(CoworkerPeek), findsNothing);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });
  });
}
