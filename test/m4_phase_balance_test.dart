// Lesson 4.10 (এলটি লাইনের ফেজ ব্যালেন্সিং), কাজ "তিন ফেজে সমান ভার": the
// rules (gloves for the live tong test, the neutral too, read the heavy
// phase, a balanced chart, the coworker's "all new on one phase", tell the
// consumers, shutdown + PTW + proven dead + earth before the spanner — live =
// deadly —, earth off + PTW back before ON, measure again before the record),
// the deal, the reason libraries, and the level in the shell: idle perf, the
// guide first, a full clean play with the coworker refused, a slip card that
// keeps the stage, three slips, the deadly freeze.
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
import 'package:slm_flutter/features/game/m4_phase_balance.dart';
import 'package:slm_flutter/features/game/m4_phase_balance_world.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';

const _ctx = LevelContext(
  rungId: '4.10/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '4.10',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 1,
);

final _pack = m4PhaseBalancePacks['do_4_10_a']!;
typedef _L = M4PhaseBalanceLines;
typedef _M = M4PhaseBalanceMistakes;

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
}

/// Design px → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
M4PhaseBalanceGeo get _geo => M4PhaseBalanceGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M4PhaseBalancePage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

Future<void> _reason(WidgetTester t, M4PhaseBalanceStage s) async {
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 700);
  await _pickRight(t, _L.whyRight(s));
  await _pump(t, 6000);
}

/// Stage 1: gloves, the tong round all four cables; then the heavy phase.
Future<void> _measure(WidgetTester t, M4PhaseBalanceDeal deal) async {
  await _tool(t, _L.gloves);
  await _tool(t, _L.tong);
  for (var i = 0; i < 4; i++) {
    await _tapAt(t, _geo.clampAt(i));
  }
  await t.tap(find.text(_L.phaseBtn(deal.heavy)));
  await _pump(t, 600);
}

/// Stage 2: the chart to the deal's balanced plan.
Future<void> _plan(WidgetTester t, M4PhaseBalanceDeal deal) async {
  for (final l in deal.loads) {
    final to = deal.balanced[l.id]!;
    if (!l.isNew && deal.wired[l.id] == to) continue;
    await t.ensureVisible(find.byKey(ValueKey('chip-${l.id}')));
    await t.tap(find.byKey(ValueKey('chip-${l.id}')));
    await _pump(t, 200);
    await t.tap(find.byKey(ValueKey('total-$to')));
    await _pump(t, 200);
  }
  await t.tap(find.text(_L.planOk));
  await _pump(t, 600);
}

/// Stage 3: tell, OFF, PTW, prove dead, earth, spanner on the bars; earth
/// off, PTW back, ON; the tong round all four again; the record.
Future<void> _work(WidgetTester t) async {
  await _tool(t, _L.notice);
  await _tapAt(t, _geo.handlePivot); // OFF
  await _tool(t, _L.ptw);
  await _tool(t, _L.tester);
  expect(find.text(_L.testerDead), findsOneWidget);
  await _tool(t, _L.earth);
  await _tool(t, _L.spanner);
  await _tapAt(t, _geo.barsHit.center);
  await _tool(t, _L.earth); // off
  await _tool(t, _L.ptw); // back
  await _tapAt(t, _geo.handlePivot); // ON
  await _tool(t, _L.tong);
  for (var i = 0; i < 4; i++) {
    await _tapAt(t, _geo.clampAt(i));
  }
  await _tool(t, _L.book);
}

void main() {
  group('rules', () {
    test('deals: one clearly heavy phase; a balanced chart exists; two new connections; plays differ', () {
      final seen = <String>{};
      for (var s = 0; s < 120; s++) {
        final d = dealM4PhaseBalance(math.Random(s));
        expect(d.newLoads, hasLength(2));
        final a = m4PhaseBalanceAmps(d.loads, d.wired);
        final sorted = [...a]..sort();
        expect(a[d.heavy], sorted[2]);
        expect(a[d.heavy] - sorted[0], greaterThanOrEqualTo(45));
        expect(a[d.heavy] - sorted[1], greaterThanOrEqualTo(25));
        expect(m4PhaseBalanceNeutral(a), greaterThan(20));
        final b = m4PhaseBalanceAmps(d.loads, d.balanced);
        expect(b.reduce(math.max) - b.reduce(math.min), lessThanOrEqualTo(kM4PhaseBalanceSpread));
        expect(d.balanced.keys.toSet(), d.loads.map((l) => l.id).toSet());
        expect(d.loads.map((l) => l.no).toSet(), hasLength(d.loads.length), reason: 'consumer numbers unique');
        for (var p = 0; p < 3; p++) {
          expect(d.wired.values.where((x) => x == p).length, lessThanOrEqualTo(9));
        }
        seen.add('${d.heavy}|${a.join(',')}');
      }
      expect(seen.length, greaterThan(40));
      expect(seen.map((x) => x[0]).toSet(), hasLength(3), reason: 'any phase can be the heavy one');
    });

    test('the neutral: zero when equal; the lesson example ≈ 62 A', () {
      expect(m4PhaseBalanceNeutral([80, 80, 80]), 0);
      expect(m4PhaseBalanceNeutral([120, 70, 50]), 62);
      expect(m4PhaseBalanceNeutral([85, 80, 75]), 9);
    });

    M4PhaseBalanceRun fresh([int seed = 3]) => M4PhaseBalanceRun(dealM4PhaseBalance(math.Random(seed)));

    void clampAll(M4PhaseBalanceRun r, {bool neutral = true}) {
      if (r.tool != M4PhaseBalanceTool.tong) r.hold(M4PhaseBalanceTool.tong);
      for (var i = 0; i < (neutral ? 4 : 3); i++) {
        expect(r.clamp(i), isNull);
      }
    }

    M4PhaseBalanceRun atPlan() {
      final r = fresh()..putGloves();
      clampAll(r);
      expect(r.answerHeavy(r.deal.heavy), isNull);
      r.next();
      return r;
    }

    void solve(M4PhaseBalanceRun r) {
      for (final l in r.deal.loads) {
        r.tapChip(l.id);
        r.moveTo(r.deal.balanced[l.id]!);
      }
    }

    M4PhaseBalanceRun atWork() {
      final r = atPlan();
      solve(r);
      expect(r.confirmPlan(), isNull);
      r.next();
      return r;
    }

    test('measure: gloves first; the neutral too; the heavy phase read right', () {
      final r = fresh()..hold(M4PhaseBalanceTool.tong);
      expect(r.clamp(0), _M.noGloves);
      expect(r.readings, isEmpty);
      r.putGloves();
      clampAll(r, neutral: false);
      expect(r.readyToRead, isTrue);
      expect(r.answerHeavy(r.deal.heavy), _M.noNeutral);
      expect(r.clamp(3), isNull);
      expect(r.readings[3], m4PhaseBalanceNeutral(r.liveAmps));
      expect(r.readings[r.deal.heavy], r.liveAmps[r.deal.heavy]);
      expect(r.answerHeavy((r.deal.heavy + 1) % 3), _M.misread);
      expect(r.cleared, isFalse);
      expect(r.answerHeavy(r.deal.heavy), isNull);
      expect(r.cleared, isTrue);
      expect(r.slips, 3);
      expect(r.caught, containsAll([_L.caughtMeasure, _L.caughtHeavy]));
    });

    test('plan: the new ones need a phase; an unbalanced chart is a slip; the coworker piles them on the heavy phase', () {
      final r = atPlan();
      expect(r.planReady, isFalse);
      expect(r.confirmPlan(), isNull, reason: 'not ready: nothing happens');
      expect(r.slips, 0);
      for (final l in r.deal.newLoads) {
        r.tapChip(l.id);
        r.moveTo(r.deal.heavy);
      }
      expect(r.planReady, isTrue);
      expect(r.confirmPlan(), _M.badPlan);
      solve(r);
      expect(r.pileOn(), _M.pileOn);
      expect([for (final l in r.deal.newLoads) r.plan[l.id]], everyElement(r.deal.heavy));
      solve(r);
      expect(r.confirmPlan(), isNull);
      expect(r.cleared, isTrue);
      expect(r.slips, 2);
      expect(r.wired, r.deal.wired, reason: 'nothing moves on the bars yet');
    });

    test('tapping chips: pick, put down, move by tapping a chip in another column', () {
      final r = atPlan();
      final heavy = [for (final l in r.deal.loads) if (r.plan[l.id] == r.deal.heavy) l];
      final other = r.deal.loads.firstWhere((l) => r.plan[l.id] != null && r.plan[l.id] != r.deal.heavy);
      r.tapChip(heavy.first.id);
      expect(r.picked, heavy.first.id);
      r.tapChip(heavy.first.id);
      expect(r.picked, isNull);
      r.tapChip(heavy.first.id);
      r.tapChip(other.id);
      expect(r.plan[heavy.first.id], r.plan[other.id]);
      expect(r.picked, isNull);
    });

    test('a spanner on the bars with the LT main ON is deadly', () {
      final r = atWork()..hold(M4PhaseBalanceTool.spanner);
      final m = r.workBars();
      expect(m, _M.shiftLive);
      expect(m!.deadly, isTrue);
      expect(r.ended, isTrue);
    });

    test('the work: tell first; PTW; proven dead before earth; earth before the spanner; then earth off + PTW back before ON', () {
      final r = atWork();
      expect(r.toggleSwitch(), _M.noNotice);
      expect(r.switchOn, isTrue);
      r.tell();
      expect(r.togglePtw(), isFalse, reason: 'no PTW on a live pillar');
      expect(r.toggleSwitch(), isNull);
      expect(r.switchOn, isFalse);
      r.hold(M4PhaseBalanceTool.spanner);
      expect(r.workBars(), _M.noPtw);
      expect(r.togglePtw(), isTrue);
      expect(r.workBars(), _M.noEarth);
      expect(r.toggleEarth(), _M.noProve);
      expect(r.earth, isFalse);
      expect(r.test(), isFalse, reason: 'dead');
      expect(r.toggleEarth(), isNull);
      expect(r.togglePtw(), isFalse, reason: 'not while earthed');
      expect(r.workBars(), isNull);
      expect(r.shifted, isTrue);
      expect(r.wired, r.plan);
      expect(r.caught, containsAll([_L.caughtNotice, _L.caughtSafe]));
      expect(r.toggleSwitch(), _M.restoreEarly);
      r.toggleEarth();
      expect(r.toggleSwitch(), _M.restoreEarly, reason: 'PTW still out');
      r.togglePtw();
      expect(r.toggleSwitch(), isNull);
      expect(r.checking, isTrue);
      expect(r.slips, 6);
    });

    test('measure again before the record; the readings are balanced now', () {
      final r = atWork()..tell();
      r
        ..toggleSwitch()
        ..togglePtw()
        ..test()
        ..toggleEarth()
        ..hold(M4PhaseBalanceTool.spanner)
        ..workBars()
        ..toggleEarth()
        ..togglePtw()
        ..toggleSwitch();
      expect(r.writeBook(), _M.noCheck);
      clampAll(r);
      final a = [r.readings[0]!, r.readings[1]!, r.readings[2]!];
      expect(a.reduce(math.max) - a.reduce(math.min), lessThanOrEqualTo(kM4PhaseBalanceSpread));
      expect(r.readings[3], lessThanOrEqualTo(kM4PhaseBalanceSpread));
      expect(r.writeBook(), isNull);
      expect(r.cleared, isTrue);
      r.next();
      expect(r.done, isTrue);
      expect(r.passed, isTrue, reason: 'one slip still passes');
      expect(r.percent, 85);
      expect(r.caught, containsAll([_L.caughtCheck, _L.caughtBook]));
    });

    test('English digits only; every mistake has its picture and a unique key; one deadly', () {
      final all = <String>[
        _L.intro,
        ..._L.tasks,
        ..._L.allRight,
        ..._L.myths,
        for (final cw in _L.allCoworkers) ...[...cw.recordedLines, ...cw.right, ...cw.wrong, ...cw.asks],
        for (final m in _M.all) m.textBn,
        _L.allSet,
        _L.fail,
        _L.docketJob,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
      expect(_M.all.where((m) => m.deadly), [_M.shiftLive]);
      expect(_M.all.map((m) => m.key).toSet(), hasLength(_M.all.length));
      for (final m in _M.all) {
        expect(m.key, startsWith('4.10/m4_phase_balance/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 2));
      }
      expect(m4PhaseBalancePacks.keys, ['do_4_10_a']);
    });

    test('reasons: same length, big enough, never a rule marked wrong; his exit is recorded', () {
      expectSameLength('why', [..._L.allRight, ..._L.myths]);
      for (final s in [M4PhaseBalanceStage.measure, M4PhaseBalanceStage.plan, M4PhaseBalanceStage.work]) {
        final right = _L.whyRight(s);
        expectLibrary('$s', right, _L.myths);
        expect(_L.myths.toSet().intersection(_L.allRight.toSet()), isEmpty);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(right, _L.myths, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      for (final cw in _L.allCoworkers) {
        expectSameLength('choice', [...cw.right, ...cw.wrong]);
        expectLibrary('choice', cw.right, cw.wrong);
        expect(LearnVoice.resolve(cw.exitLine, rival: true), isNotNull);
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

    for (final reduce in [false, true]) {
      testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
        t.view.physicalSize = const Size(720, 1600);
        t.view.devicePixelRatio = 2.0;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        await t.pumpWidget(ProviderScope(child: MaterialApp(home: M4PhaseBalancePage(ctx: _ctx, pack: _pack, muted: true, seed: 4))));
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
        debugPrint('PERF m4_phase_balance ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M4PhaseBalancePage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(_label(_L.tong), findsNothing);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_label(_L.tong), findsOneWidget);
      expect(find.text(_L.docketJob), findsOneWidget);
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
      expect(lines.every((l) => l.contains(_L.askMeasure)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('flow: measure, read, plan (refuse him), shift safely, measure again, record → pass', (t) async {
      final deal = dealM4PhaseBalance(math.Random(7));
      final c = await _open(t, 7);
      await _measure(t, deal);
      expect(find.text(MistakeLines.slipHead), findsNothing);
      await _reason(t, M4PhaseBalanceStage.measure);
      // The chart; he comes.
      expect(find.byKey(const ValueKey('tray')), findsOneWidget);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await _pickRight(t, _L.coworker(deal.heavy).right);
      await _pump(t, 2600);
      await _plan(t, deal);
      expect(find.text(MistakeLines.slipHead), findsNothing);
      await _reason(t, M4PhaseBalanceStage.plan);
      await _work(t);
      expect(find.text(MistakeLines.slipHead), findsNothing);
      await _reason(t, M4PhaseBalanceStage.work);
      await _pump(t, 2000);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['4.10/do/0'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['4.10/do/0'], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(_L.caughtCall), findsOneWidget);
      expect(find.text(_L.caughtBook), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a slip (the tong without gloves) shows its card; the same stage goes on after it', (t) async {
      final c = await _open(t, 2);
      await _tool(t, _L.tong);
      await _tapAt(t, _geo.clampAt(0));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(_M.noGloves.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_label(_L.tong), findsOneWidget, reason: 'the same stage');
      expect(c.read(gameSaveProvider).mistakes.single.key, _M.noGloves.key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final c = await _open(t, 2);
      await _tool(t, _L.tong);
      for (var i = 0; i < 3; i++) {
        await _tapAt(t, _geo.clampAt(i));
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

    testWidgets('listening to him: the new ones land on the heavy phase, a slip card', (t) async {
      final deal = dealM4PhaseBalance(math.Random(11));
      final c = await _open(t, 11);
      await _measure(t, deal);
      await _reason(t, M4PhaseBalanceStage.measure);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      final wrong = _onScreen(_L.coworker(deal.heavy).wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await _pump(t, 1200);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(c.read(gameSaveProvider).mistakes.single.key, _M.pileOn.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byKey(const ValueKey('tray')), findsNothing, reason: 'he put them on the heavy phase');
      await _close(t, c);
    });

    testWidgets('a spanner on the live bars: the scene freezes first, then the card (near-miss)', (t) async {
      final deal = dealM4PhaseBalance(math.Random(13));
      final c = await _open(t, 13);
      await _measure(t, deal);
      await _reason(t, M4PhaseBalanceStage.measure);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await _pickRight(t, _L.coworker(deal.heavy).right);
      await _pump(t, 2600);
      await _plan(t, deal);
      await _reason(t, M4PhaseBalanceStage.plan);
      await _tool(t, _L.spanner);
      await _tapAt(t, _geo.barsHit.center);
      await _pump(t, 500);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, _M.shiftLive.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });
  });
}
