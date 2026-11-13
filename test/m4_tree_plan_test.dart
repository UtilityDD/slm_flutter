// Lesson 4.8 (গাছের ডালপালা ছাঁটা), কাজ 1 "কাটার আগে পরিকল্পনা": the rules
// (survey only the branches grown into the line, none missed; the drop zone
// under the tree, off the road; শাটডাউন · PTW, a helper below, গ্লাভস ·
// গগলস, a rope for heavy branches and the tool by branch size — all before
// the first cut; the line live = deadly), the deal, the option libraries, and
// the level in the shell: idle perf, the guide first, a full clean play with
// the coworker refused (also on a fast play: শাটডাউন and কাটা শুরু wait for
// him), listening = a slip, a slip card, 3 slips strike out, the deadly freeze
// (no শাটডাউন), the drop off the tree = a slip with a neutral miss reply, the
// rack dealt out of order, and the gesture hint (a sweep, never one answer).
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
import 'package:slm_flutter/features/game/level_frame.dart';
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m4_tree_plan.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';
import 'support/reason_proceed.dart';

const _ctx = LevelContext(rungId: '4.8/do/0', kind: CatalogRungKind.doKind, lessonId: '4.8', lessonTitleBn: '', ladderStep: 0, doIndex: 1, doCount: 2);

final _pack = m4TreePlanPacks['do_4_8_a']!;

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
  await tapReasonProceed(t);
}

/// Design px → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
M4TreePlanGeo get _geo => M4TreePlanGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
Offset _screen(Offset design) => design * _k;

/// A point on branch [i], 80 % of the way to its tip (design px).
Offset _onBranch(M4TreePlanTree tree, int i) {
  final (a, c, tip) = _geo.branchOf(tree.branches[i], tree.treeX, tree.wire);
  const s = 0.8;
  return a * ((1 - s) * (1 - s)) + c * (2 * s * (1 - s)) + tip * (s * s);
}

Future<ProviderContainer> _open(WidgetTester t, int seed) async {
  t.view.physicalSize = const Size(784, 1700);
  t.view.devicePixelRatio = 2.0;
  final c = ProviderContainer();
  final nav = GlobalKey<NavigatorState>();
  await t.pumpWidget(
    UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        navigatorKey: nav,
        home: const Scaffold(body: SizedBox()),
      ),
    ),
  );
  unawaited(
    nav.currentState!.push(
      MaterialPageRoute<bool>(
        builder: (_) => M4TreePlanPage(ctx: _ctx, pack: _pack, muted: true, seed: seed),
      ),
    ),
  );
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

Future<void> _refuse(WidgetTester t) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, M4TreePlanLines.coworker.right);
  await _pump(t, 2000);
}

Future<void> _survey(WidgetTester t, M4TreePlanTree tree) async {
  for (final i in tree.toward) {
    await t.tapAt(_screen(_onBranch(tree, i)));
    await _pump(t, 200);
  }
  await t.tap(find.text(M4TreePlanLines.surveyDone));
  await _pump(t, 600);
}

Future<void> _dropRight(WidgetTester t, M4TreePlanTree tree) async {
  await t.tapAt(_screen(Offset(tree.treeX, _geo.groundY + 30)));
  await _pump(t, 600);
}

Future<void> _plan(WidgetTester t, M4TreePlanTree tree, {bool shutdown = true}) async {
  for (final l in [
    if (shutdown) M4TreePlanLines.shutdown,
    M4TreePlanLines.helper,
    M4TreePlanLines.ppe,
    if (tree.big) M4TreePlanLines.rope,
    tree.big ? M4TreePlanLines.chainsaw : M4TreePlanLines.pruner,
  ]) {
    await t.tap(_label(l));
    await _pump(t, 150);
  }
}

/// Plays tree [i] right (refusing him at his tree).
Future<void> _playRight(WidgetTester t, M4TreePlanDeal deal, int i) async {
  final tree = deal.trees[i];
  if (i == deal.callAt) await _refuse(t);
  await _survey(t, tree);
  await _dropRight(t, tree);
  expect(find.text(M4TreePlanLines.start), findsOneWidget, reason: 'plan, tree $i');
  await _plan(t, tree);
  await t.tap(find.text(M4TreePlanLines.start));
  await _pump(t, 2200);
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'tree $i');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 700);
  await _pickRight(t, M4TreePlanLines.whyRight(tree));
  await _pump(t, 6000);
}

void main() {
  group('rules', () {
    test('deals three trees: 11 kV and এবি কেবিল, thin and thick; topics differ; fresh each play', () {
      final seen = <String>{};
      final calls = <int>{};
      for (var s = 0; s < 60; s++) {
        final d = m4TreePlanDeal(math.Random(s));
        expect(d.trees.length, 3);
        expect(d.trees.map((t) => t.wire).toSet(), M4TreePlanWire.values.toSet());
        expect(d.trees.map((t) => t.size).toSet(), M4TreePlanSize.values.toSet());
        expect(d.trees.map((t) => t.topic).toSet().length, 3);
        calls.add(d.callAt);
        for (final t in d.trees) {
          expect(t.toward.length, inInclusiveRange(2, 3));
          expect(t.branches.length - t.toward.length, 3);
          if (t.topic == M4TreePlanTopic.abCable) expect(t.wire, M4TreePlanWire.abLt);
          // Every branch is tappable on its own: the tap point hits it.
          for (var i = 0; i < t.branches.length; i++) {
            expect(_geo.branchAt(_onBranch(t, i), t.branches, t.treeX, t.wire), i, reason: 'seed $s branch $i');
          }
          // The ones in the line reach the lowest wire; the others stay far below.
          for (final b in t.branches) {
            final (_, _, tip) = _geo.branchOf(b, t.treeX, t.wire);
            final gap = tip.dy - _geo.lowWireAt(t.wire, tip.dx);
            if (b.toward) {
              expect(gap.abs(), lessThan(4));
            } else {
              expect(gap, greaterThan(80));
            }
          }
        }
        seen.add(d.trees.map((t) => '${t.wire.name}${t.size.name}${t.topic.name}${t.treeX}${t.toward}').join('|') + d.callAt.toString());
      }
      expect(seen.length, greaterThan(50));
      expect(calls, {0, 1, 2});
    });

    test("the plan rack: every button once, dealt fresh, never in the plan's order", () {
      final racks = <String>{};
      final firsts = <M4TreePlanItem>{};
      for (var s = 0; s < 40; s++) {
        for (final t in m4TreePlanDeal(math.Random(s)).trees) {
          expect(t.rack.toSet(), M4TreePlanItem.values.toSet());
          expect(t.rack.length, M4TreePlanItem.values.length);
          expect(t.rack, isNot(orderedEquals(M4TreePlanItem.values)));
          racks.add(t.rack.map((i) => i.index).join());
          firsts.add(t.rack.first);
        }
      }
      expect(racks.length, greaterThan(100));
      expect(firsts.length, greaterThan(5), reason: 'any button can come first');
    });

    M4TreePlanRun run1({M4TreePlanSize size = M4TreePlanSize.small}) => M4TreePlanRun(
      M4TreePlanDeal(
        trees: [
          M4TreePlanTree(
            wire: M4TreePlanWire.hv11,
            size: size,
            treeX: 180,
            branches: m4TreePlanDeal(math.Random(4)).trees[0].branches,
            topic: M4TreePlanTopic.shutdown,
            walkerX: 80,
          ),
        ],
        callAt: 0,
      ),
    );
    M4TreePlanRun toPlan({M4TreePlanSize size = M4TreePlanSize.small}) {
      final r = run1(size: size);
      for (final i in r.tree.toward) {
        r.tap(i);
      }
      r
        ..surveyDone()
        ..drop(M4TreePlanDrop.zone, 180);
      expect(r.phase, M4TreePlanPhase.plan);
      return r;
    }

    test('survey: a branch clear of the line is a slip (once); one missed is a slip; all and only = clean', () {
      final a = run1();
      final clear = [for (var i = 0; i < a.tree.branches.length; i++) if (!a.tree.branches[i].toward) i];
      expect(a.tap(clear.first), M4TreePlanMistakes.wrongBranch);
      expect(a.tap(clear.first), isNull, reason: 'the same branch again is not counted');
      expect(a.slips, 1);
      expect(a.marked, isEmpty);
      final b = run1();
      b.tap(b.tree.toward.first);
      expect(b.surveyDone(), M4TreePlanMistakes.missedBranch);
      expect(b.marked, containsAll(b.tree.toward), reason: 'the guide marks the rest');
      expect(b.phase, M4TreePlanPhase.drop);
      final c = run1();
      for (final i in c.tree.toward) {
        expect(c.tap(i), isNull);
      }
      expect(c.surveyDone(), isNull);
      expect(c.caught, contains(M4TreePlanLines.caughtSurvey));
    });

    test('drop zone: far = not scored, stays; road = slip, moved under the tree; under the tree = right', () {
      M4TreePlanRun atDrop() {
        final r = run1();
        for (final i in r.tree.toward) {
          r.tap(i);
        }
        r.surveyDone();
        return r;
      }

      final g = _geo;
      final tr = run1().tree;
      expect(m4TreePlanDropOf(g, tr, 180, g.groundY + 30), M4TreePlanDrop.zone);
      expect(m4TreePlanDropOf(g, tr, 180, g.roadTop + 20), M4TreePlanDrop.road);
      expect(m4TreePlanDropOf(g, tr, 40, g.groundY + 30), M4TreePlanDrop.away);
      expect(m4TreePlanDropOf(g, tr, 330, g.groundY + 30), M4TreePlanDrop.away);
      expect(m4TreePlanDropOf(g, tr, 180, g.wireY), M4TreePlanDrop.far);
      final a = atDrop();
      expect(a.drop(M4TreePlanDrop.far, 40), isNull);
      expect(a.phase, M4TreePlanPhase.drop);
      expect(a.slips, 0, reason: 'a tap off the ground is a miss, not a choice');
      expect(a.drop(M4TreePlanDrop.road, 180), M4TreePlanMistakes.roadDrop);
      expect(a.dropX, 180);
      expect(a.phase, M4TreePlanPhase.plan);
      final b = atDrop();
      expect(b.drop(M4TreePlanDrop.zone, 300), isNull);
      expect(b.dropX, 240, reason: 'kept under the tree');
      expect(b.caught, contains(M4TreePlanLines.caughtDrop));
      final w = atDrop();
      expect(w.drop(M4TreePlanDrop.away, 40), M4TreePlanMistakes.awayDrop, reason: 'the cordon away from the tree costs');
      expect(w.dropX, 180, reason: 'the guide moves it under the tree');
      expect(w.phase, M4TreePlanPhase.plan);
      expect(w.caught, isNot(contains(M4TreePlanLines.caughtDrop)));
    });

    test('the plan: no tool = not started; no শাটডাউন = deadly; listening to him = a slip, শাটডাউন still on offer', () {
      final a = toPlan();
      expect(a.start(), (false, null));
      expect(a.phase, M4TreePlanPhase.plan);
      a
        ..wear(M4TreePlanKit.helper)
        ..wear(M4TreePlanKit.ppe)
        ..pick(M4TreePlanTool.pruner);
      expect(a.start(), (true, M4TreePlanMistakes.liveLine));
      expect(a.deadly!.deadly, isTrue);
      expect(a.ended, isTrue);
      final b = toPlan();
      expect(b.listen(), M4TreePlanMistakes.listened);
      expect(b.slips, 1);
      expect(M4TreePlanMistakes.listened.deadly, isFalse, reason: 'playbook row 8: listening = the slip');
      b
        ..wear(M4TreePlanKit.shutdown)
        ..wear(M4TreePlanKit.helper)
        ..wear(M4TreePlanKit.ppe)
        ..pick(M4TreePlanTool.pruner);
      expect(b.kit, contains(M4TreePlanKit.shutdown), reason: 'he cannot take the শাটডাউন off the plan');
      expect(b.start(), (true, null));
      expect(b.deadly, isNull);
      final c = toPlan()..listen();
      c.pick(M4TreePlanTool.pruner);
      expect(c.start().$2, M4TreePlanMistakes.liveLine, reason: 'cutting with the line live is still the deadly');
    });

    test('the plan: the most serious gap is the slip, the rest put right; a clean plan tags', () {
      DoMistake? go(M4TreePlanSize size, M4TreePlanTool tool, List<M4TreePlanKit> kit) {
        final r = toPlan(size: size)..wear(M4TreePlanKit.shutdown);
        for (final k in kit) {
          r.wear(k);
        }
        r.pick(tool);
        final (started, m) = r.start();
        expect(started, isTrue);
        expect(r.phase, M4TreePlanPhase.cut);
        expect(r.deadly, isNull);
        return m;
      }

      const all = [M4TreePlanKit.helper, M4TreePlanKit.ppe, M4TreePlanKit.rope];
      expect(go(M4TreePlanSize.small, M4TreePlanTool.plain, all), M4TreePlanMistakes.plainTool);
      expect(go(M4TreePlanSize.big, M4TreePlanTool.saw, all), M4TreePlanMistakes.smallTool);
      expect(go(M4TreePlanSize.big, M4TreePlanTool.pruner, all), M4TreePlanMistakes.smallTool);
      expect(go(M4TreePlanSize.small, M4TreePlanTool.chainsaw, all), M4TreePlanMistakes.bigTool);
      expect(go(M4TreePlanSize.small, M4TreePlanTool.pruner, [M4TreePlanKit.ppe]), M4TreePlanMistakes.alone);
      expect(go(M4TreePlanSize.small, M4TreePlanTool.saw, [M4TreePlanKit.helper]), M4TreePlanMistakes.noPpe);
      expect(go(M4TreePlanSize.big, M4TreePlanTool.chainsaw, [M4TreePlanKit.helper, M4TreePlanKit.ppe]), M4TreePlanMistakes.noRope);
      expect(go(M4TreePlanSize.small, M4TreePlanTool.pruner, [M4TreePlanKit.helper, M4TreePlanKit.ppe]), isNull, reason: 'no rope needed for thin branches');
      expect(go(M4TreePlanSize.big, M4TreePlanTool.chainsaw, all), isNull);
      final r = toPlan(size: M4TreePlanSize.big)..wear(M4TreePlanKit.shutdown);
      r.pick(M4TreePlanTool.plain);
      expect(r.start().$2, M4TreePlanMistakes.plainTool);
      expect(r.tool, M4TreePlanTool.chainsaw, reason: 'the guide hands the right tool');
      expect(r.kit, containsAll(all));
      final ok = toPlan()
        ..wear(M4TreePlanKit.shutdown)
        ..wear(M4TreePlanKit.helper)
        ..wear(M4TreePlanKit.ppe)
        ..pick(M4TreePlanTool.saw);
      expect(ok.start(), (true, null));
      expect(ok.caught, containsAll([M4TreePlanLines.caughtShutdown, M4TreePlanLines.caughtTool, M4TreePlanLines.caughtCrew]));
      expect(ok.clean, isTrue);
      ok.cutDone();
      expect(ok.phase, M4TreePlanPhase.done);
    });

    test('a toggle: tapping a plan item twice takes it back; a tool tapped twice is put down', () {
      final r = toPlan()..wear(M4TreePlanKit.helper);
      expect(r.kit, contains(M4TreePlanKit.helper));
      r.wear(M4TreePlanKit.helper);
      expect(r.kit, isEmpty);
      r
        ..pick(M4TreePlanTool.saw)
        ..pick(M4TreePlanTool.saw);
      expect(r.tool, M4TreePlanTool.none);
    });

    test('mark: 100 − 15 per slip; next tree clears the plan', () {
      final r = M4TreePlanRun(m4TreePlanDeal(math.Random(3)));
      r.slips = 3;
      expect(r.percent, 55);
      r.marked.add(0);
      r.next();
      expect(r.marked, isEmpty);
      expect(r.kit, isEmpty);
      expect(r.dropX, isNull);
      expect(r.phase, M4TreePlanPhase.survey);
    });

    test('English digits only; every mistake has its picture, a stable key; one deadly', () {
      final all = <String>[
        M4TreePlanLines.intro,
        ...M4TreePlanLines.tasks,
        ...M4TreePlanLines.shutdownWhy,
        ...M4TreePlanLines.cordonWhy,
        ...M4TreePlanLines.toolSmallWhy,
        ...M4TreePlanLines.toolBigWhy,
        ...M4TreePlanLines.directionalWhy,
        ...M4TreePlanLines.abWhy,
        ...M4TreePlanLines.whyWrong,
        ...M4TreePlanLines.shutdownWrong,
        ...M4TreePlanLines.cordonWrong,
        ...M4TreePlanLines.toolSmallWrong,
        ...M4TreePlanLines.toolBigWrong,
        ...M4TreePlanLines.directionalWrong,
        ...M4TreePlanLines.abWrong,
        M4TreePlanLines.dropFar,
        M4TreePlanLines.noTool,
        ...M4TreePlanLines.coworker.recordedLines,
        ...M4TreePlanLines.coworker.right,
        ...M4TreePlanLines.coworker.wrong,
        ...M4TreePlanLines.coworker.asks,
        for (final m in M4TreePlanMistakes.all) m.textBn,
        M4TreePlanLines.allSet,
        M4TreePlanLines.fail,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
      expect(M4TreePlanMistakes.all.where((m) => m.deadly).toSet(), {M4TreePlanMistakes.liveLine});
      for (final m in M4TreePlanMistakes.all) {
        expect(m.key, startsWith('4.8/m4_tree_plan/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 2));
      }
      expect(M4TreePlanMistakes.all.map((m) => m.key).toSet().length, M4TreePlanMistakes.all.length);
      expect(m4TreePlanPacks.keys, ['do_4_8_a']);
      expect(_pack.quickMs, 80000);
    });

    test('reasons fit the tree, same length, big enough; his choices too', () {
      expectSameLength('why', [
        ...M4TreePlanLines.shutdownWhy,
        ...M4TreePlanLines.cordonWhy,
        ...M4TreePlanLines.toolSmallWhy,
        ...M4TreePlanLines.toolBigWhy,
        ...M4TreePlanLines.directionalWhy,
        ...M4TreePlanLines.abWhy,
        ...M4TreePlanLines.whyWrong,
        ...M4TreePlanLines.shutdownWrong,
        ...M4TreePlanLines.cordonWrong,
        ...M4TreePlanLines.toolSmallWrong,
        ...M4TreePlanLines.toolBigWrong,
        ...M4TreePlanLines.directionalWrong,
        ...M4TreePlanLines.abWrong,
      ]);
      for (var s = 0; s < 20; s++) {
        for (final tr in m4TreePlanDeal(math.Random(s)).trees) {
          final right = M4TreePlanLines.whyRight(tr);
          expectLibrary('${tr.topic}', right, M4TreePlanLines.whyWrongFor(tr));
          if (tr.topic == M4TreePlanTopic.tool) expect(right, tr.big ? M4TreePlanLines.toolBigWhy : M4TreePlanLines.toolSmallWhy);
          final deal = M4TreePlanLines.dealWhy(tr, math.Random(s));
          expect(deal.where((o) => o.correct).length, 1);
          expect(deal.map((o) => o.textBn).toSet().length, 3);
          final wrongs = deal.where((o) => !o.correct).map((o) => o.textBn).toList();
          expect(wrongs.where(M4TreePlanLines.topicWrong(tr).contains), hasLength(1), reason: "one wrong in the tree's own words");
          expect(wrongs.where(M4TreePlanLines.whyWrong.contains), hasLength(1));
        }
      }
      final s = M4TreePlanLines.coworker;
      expectSameLength('choice', [...s.right, ...s.wrong]);
      expectLibrary('choice', s.right, s.wrong);
      expect(M4TreePlanLines.recordLines, hasLength(2));
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

    int seedWhere(bool Function(M4TreePlanDeal d) ok) {
      var s = 0;
      while (!ok(m4TreePlanDeal(math.Random(s)))) {
        s++;
      }
      return s;
    }

    for (final reduce in [false, true]) {
      testWidgets('waits quietly (${reduce ? 'reduce' : 'anim'})', (t) async {
        t.view.physicalSize = const Size(720, 1600);
        t.view.devicePixelRatio = 2.0;
        t.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(disableAnimations: reduce);
        final seed = seedWhere((d) => d.callAt != 0);
        await t.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: M4TreePlanPage(ctx: _ctx, pack: _pack, muted: true, seed: seed),
            ),
          ),
        );
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
        debugPrint('PERF m4_tree_plan ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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

    testWidgets('the guide comes first: a tap does not skip him; then the docket and the survey', (t) async {
      final seed = seedWhere((d) => d.callAt != 0);
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: M4TreePlanPage(ctx: _ctx, pack: _pack, muted: true, seed: seed),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(find.text(M4TreePlanLines.surveyDone), findsNothing);
      await waitIntro(t);
      await _pump(t, 600);
      expect(find.text(M4TreePlanLines.surveyDone), findsOneWidget);
      expect(find.text(M4TreePlanLines.treeBn(m4TreePlanDeal(math.Random(seed)).trees[0])), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final seed = seedWhere((d) => d.callAt != 0);
      final c = await _open(t, seed);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(M4TreePlanLines.askSurvey)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    for (final at in [0, 2]) {
      testWidgets('flow: three trees right, him refused (tree $at) → pass', (t) async {
        final seed = seedWhere((d) => d.callAt == at);
        final deal = m4TreePlanDeal(math.Random(seed));
        final c = await _open(t, seed);
        for (var i = 0; i < 3; i++) {
          await _playRight(t, deal, i);
        }
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['4.8/do/0'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['4.8/do/0'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(M4TreePlanLines.caughtCall), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('a branch clear of the line: the slip card, then the survey goes on', (t) async {
      final seed = seedWhere((d) => d.callAt != 0);
      final tree = m4TreePlanDeal(math.Random(seed)).trees[0];
      final c = await _open(t, seed);
      final clear = [for (var i = 0; i < tree.branches.length; i++) if (!tree.branches[i].toward) i];
      await t.tapAt(_screen(_onBranch(tree, clear.first)));
      await _pump(t, 900);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M4TreePlanMistakes.wrongBranch.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      expect(find.text(M4TreePlanLines.surveyDone), findsOneWidget, reason: 'on with the survey');
      await _close(t, c);
    });

    testWidgets('the cut without শাটডাউন: the stretch freezes first, then the card (near-miss)', (t) async {
      final seed = seedWhere((d) => d.callAt != 0);
      final tree = m4TreePlanDeal(math.Random(seed)).trees[0];
      final c = await _open(t, seed);
      await _survey(t, tree);
      await _dropRight(t, tree);
      await _plan(t, tree, shutdown: false);
      await t.tap(find.text(M4TreePlanLines.start));
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, M4TreePlanMistakes.liveLine.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('listening to him = a slip card; the শাটডাউন stays on offer and the tree passes', (t) async {
      final seed = seedWhere((d) => d.callAt == 0);
      final tree = m4TreePlanDeal(math.Random(seed)).trees[0];
      final c = await _open(t, seed);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await waitChoiceDeck(t);
      final wrong = _onScreen(M4TreePlanLines.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await confirmChoice(t);
      await _pump(t, 1500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.slipHead), findsOneWidget, reason: 'a slip, not a freeze');
      expect(find.byType(FreezeFrame), findsNothing);
      expect(c.read(gameSaveProvider).mistakes.single.key, M4TreePlanMistakes.listened.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      await _survey(t, tree);
      await _dropRight(t, tree);
      await _plan(t, tree);
      expect(find.text(M4TreePlanLines.shutdownOn), findsWidgets, reason: 'the শাটডাউন could still be taken');
      await t.tap(find.text(M4TreePlanLines.start));
      await _pump(t, 2200);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(c.read(gameSaveProvider).mistakes.single.key, M4TreePlanMistakes.listened.key, reason: 'no deadly');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      expect(find.byType(ChoiceDeck), findsOneWidget, reason: 'the reason deck of the tree');
      await _close(t, c);
    });

    testWidgets('he comes even on a fast play: the শাটডাউন tap waits for him', (t) async {
      final seed = seedWhere((d) => d.callAt == 0);
      final tree = m4TreePlanDeal(math.Random(seed)).trees[0];
      final c = await _open(t, seed);
      // As fast as a finger goes: survey, done, drop, then শাটডাউন.
      for (final i in tree.toward) {
        await t.tapAt(_screen(_onBranch(tree, i)));
        await t.pump(const Duration(milliseconds: 16));
      }
      await t.tap(find.text(M4TreePlanLines.surveyDone));
      await t.pump(const Duration(milliseconds: 16));
      await t.tapAt(_screen(Offset(tree.treeX, _geo.groundY + 30)));
      await t.pump(const Duration(milliseconds: 16));
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'not yet come by himself');
      await t.tap(_label(M4TreePlanLines.shutdown));
      await t.pump(const Duration(milliseconds: 50));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'the decisive tap waits for him');
      expect(find.text(M4TreePlanLines.shutdownOn), findsNothing, reason: 'the শাটডাউন tap did not go through under him');
      await waitChoiceDeck(t);
      await _pickRight(t, M4TreePlanLines.coworker.right);
      await _pump(t, 2000);
      expect(find.byType(CoworkerPeek), findsNothing);
      await _plan(t, tree);
      await t.tap(find.text(M4TreePlanLines.start));
      await _pump(t, 2200);
      expect(find.text(MistakeLines.slipHead), findsNothing);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('he comes even on a fast play: কাটা শুরু before the শাটডাউন waits for him (no cut under him)', (t) async {
      final seed = seedWhere((d) => d.callAt == 0);
      final tree = m4TreePlanDeal(math.Random(seed)).trees[0];
      final c = await _open(t, seed);
      for (final i in tree.toward) {
        await t.tapAt(_screen(_onBranch(tree, i)));
        await t.pump(const Duration(milliseconds: 16));
      }
      await t.tap(find.text(M4TreePlanLines.surveyDone));
      await t.pump(const Duration(milliseconds: 16));
      await t.tapAt(_screen(Offset(tree.treeX, _geo.groundY + 30)));
      await t.pump(const Duration(milliseconds: 16));
      for (final l in [M4TreePlanLines.helper, M4TreePlanLines.ppe, if (tree.big) M4TreePlanLines.rope, tree.big ? M4TreePlanLines.chainsaw : M4TreePlanLines.pruner]) {
        await t.tap(_label(l));
        await t.pump(const Duration(milliseconds: 16));
      }
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'not yet come by himself');
      await t.tap(find.text(M4TreePlanLines.start));
      await t.pump(const Duration(milliseconds: 50));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'the cut waits for him');
      expect(find.byType(FreezeFrame), findsNothing, reason: 'the tap did not start the cut');
      await waitChoiceDeck(t);
      await _pickRight(t, M4TreePlanLines.coworker.right);
      await _pump(t, 2000);
      await t.tap(_label(M4TreePlanLines.shutdown));
      await _pump(t, 150);
      await t.tap(find.text(M4TreePlanLines.start));
      await _pump(t, 2200);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'the reason deck of the tree');
      await _close(t, c);
    });

    testWidgets('three slips: the level strikes out (StruckOutCard), the strikes booked', (t) async {
      final seed = seedWhere((d) => d.callAt != 0);
      final tree = m4TreePlanDeal(math.Random(seed)).trees[0];
      final c = await _open(t, seed);
      final clear = [for (var i = 0; i < tree.branches.length; i++) if (!tree.branches[i].toward) i];
      expect(clear, hasLength(3));
      for (var k = 0; k < 3; k++) {
        await t.tapAt(_screen(_onBranch(tree, clear[k])));
        await _pump(t, 900);
        if (k < 2) {
          expect(find.text(MistakeLines.slipHead), findsOneWidget, reason: 'slip ${k + 1}');
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 800);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(find.byType(LevelPassPanel), findsNothing);
      expect(c.read(gameSaveProvider).rungProgress['4.8/do/0'], isNot('cleared'));
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('the drop: a tap off the ground is a neutral miss; the verge away from the tree = a slip', (t) async {
      // The tree right of centre: the verge on the left is free (the guide stands bottom right).
      final seed = seedWhere((d) => d.callAt != 0 && d.trees[0].treeX >= 180);
      final tree = m4TreePlanDeal(math.Random(seed)).trees[0];
      final c = await _open(t, seed);
      await _survey(t, tree);
      // Off the ground (the far bank): not a choice; the guide says the task again (never where).
      await t.tapAt(_screen(Offset(30, _geo.groundY - 40)));
      await _pump(t, 400);
      final line = c.read(guideDirectorProvider).line;
      expect(line, M4TreePlanLines.dropFar);
      expect(line.contains('গাছের নিচে'), isFalse, reason: 'neutral');
      expect(find.byType(MistakeCard), findsNothing);
      // The verge far from the tree: the cordon would miss the falling branches.
      const awayX = 30.0;
      expect(m4TreePlanDropOf(_geo, tree, awayX, _geo.groundY + 30), M4TreePlanDrop.away);
      await t.tapAt(_screen(Offset(awayX, _geo.groundY + 30)));
      await _pump(t, 900);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M4TreePlanMistakes.awayDrop.key);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      expect(find.text(M4TreePlanLines.start), findsOneWidget, reason: 'the guide moved it under the tree; on to the plan');
      await _close(t, c);
    });

    testWidgets('the gesture hint: idle in the survey → a sweep over every branch (never one answer)', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final seed = seedWhere((d) => d.callAt != 0);
      final tree = m4TreePlanDeal(math.Random(seed)).trees[0];
      final c = await _open(t, seed);
      final hint = t.state<IdleHintState>(find.byType(IdleHint).first);
      expect(hint.showing, isFalse);
      await _pump(t, 9000);
      expect(hint.showing, isTrue, reason: 'stuck in the survey');
      expect(hint.debugFrame, isNotNull);
      expect(hint.debugOptions, hasLength(tree.branches.length + 1), reason: 'over the branches in the line and the clear ones alike, then জরিপ শেষ');
      // Every in-line branch marked: the sweep never narrows to the ones left (the clear ones).
      for (final i in tree.toward) {
        await t.tapAt(_screen(_onBranch(tree, i)));
        await _pump(t, 200);
      }
      await _pump(t, 9000);
      expect(hint.showing, isTrue);
      expect(hint.debugOptions, hasLength(tree.branches.length + 1), reason: 'the same set after marking');
      // The plan: a sweep over every rack button and কাটা শুরু.
      await t.tap(find.text(M4TreePlanLines.surveyDone));
      await _pump(t, 600);
      await _dropRight(t, tree);
      expect(find.text(M4TreePlanLines.start), findsOneWidget);
      await _pump(t, 9000);
      expect(hint.showing, isTrue, reason: 'stuck on the plan');
      expect(hint.debugOptions, hasLength(M4TreePlanItem.values.length + 1));
      await _close(t, c);
    });
  });
}
