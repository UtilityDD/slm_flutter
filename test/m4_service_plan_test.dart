// Lesson 4.3 (নতুন সার্ভিস কানেকশন দেওয়া), কাজ 1 "কানেকশনের প্রস্তুতি":
// the deal (paper fault, routes, shelf, cards, the coworker's round), the
// rules of each round (papers, route, material, work order — all slips, none
// deadly), the mistakes book, reason and choice libraries, the mistake art,
// and the level in the shell: idle perf, the guide first, tapping the guide,
// a clean play (the coworker refused) → pass and save, a wrong move → its
// card, listening to the coworker → his shortcut's card, three slips → out.
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
import 'package:slm_flutter/features/game/m4_service_plan.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';

typedef _R = M4ServicePlanRound;
typedef _F = M4ServicePlanFault;
typedef _Rt = M4ServicePlanRoute;
typedef _I = M4ServicePlanItem;
typedef _S = M4ServicePlanStep;
typedef _L = M4ServicePlanLines;
typedef _M = M4ServicePlanMistakes;

const _ctx = LevelContext(
  rungId: '4.3/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '4.3',
  lessonTitleBn: '',
  ladderStep: 97,
  doIndex: 1,
  doCount: 2,
);

final _pack = m4ServicePlanPacks['do_4_3_a']!;

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
    builder: (_) => M4ServicePlanPage(ctx: _ctx, pack: _pack, muted: true, seed: seed),
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

/// On his round: wait for him and refuse him.
Future<void> _refuse(WidgetTester t, M4ServicePlanDeal deal) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes on round ${deal.callAt}');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, _L.coworkerFor(_R.values[deal.callAt]).right);
  await _pump(t, 2600);
}

Future<void> _tapKey(WidgetTester t, String key) async {
  await t.tap(find.byKey(ValueKey(key)));
  await _pump(t, 300);
}

Future<void> _tapText(WidgetTester t, String text) async {
  await t.tap(find.text(text));
  await _pump(t, 300);
}

/// Plays round [i] right, then its reason.
Future<void> _playRight(WidgetTester t, M4ServicePlanDeal deal, int i) async {
  if (i == deal.callAt) await _refuse(t, deal);
  final round = _R.values[i];
  switch (round) {
    case _R.papers:
      if (deal.fault == _F.none) {
        await _tapText(t, _L.papersGo);
      } else {
        await _tapKey(t, 'paper-${deal.fault.paper!.name}');
        await _tapText(t, _L.papersFetch);
      }
    case _R.route:
      // Look at a wrong one first (free), then the straight one.
      await _tapKey(t, 'route-${deal.routes.firstWhere((r) => r != _Rt.straight).name}');
      await _tapKey(t, 'route-straight');
      await _tapText(t, _L.routeGo);
    case _R.kit:
      await _tapKey(t, 'item-tape');
      await _tapKey(t, 'item-tape');
      for (final it in m4ServicePlanKit) {
        await _tapKey(t, 'item-${it.name}');
      }
      await _tapText(t, _L.kitGo);
    case _R.order:
      for (final s in _S.values) {
        await _tapKey(t, 'card-${s.name}');
      }
  }
  await _pump(t, 1500);
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'round $i');
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'reason deck $i');
  await _pump(t, 700);
  await _pickRight(t, _L.whyRight(round, fetched: deal.fault != _F.none));
  await _pump(t, 4500);
}

int _seedWhere(bool Function(M4ServicePlanDeal d) ok, {int from = 0}) {
  var s = from;
  while (!ok(dealM4ServicePlan(math.Random(s)))) {
    s++;
  }
  return s;
}

void main() {
  group('rules', () {
    test('deals: a paper fault (never none when he pushes on the papers), one straight + two wrong routes, the tree when he pushes on the route, shelf and cards shuffled', () {
      final plays = <String>{};
      final calls = <int>{};
      final faults = <_F>{};
      final wrongs = <_Rt>{};
      final mirrors = <bool>{};
      for (var s = 0; s < 120; s++) {
        final d = dealM4ServicePlan(math.Random(s));
        calls.add(d.callAt);
        faults.add(d.fault);
        mirrors.add(d.mirror);
        if (d.callAt == 0) expect(d.fault, isNot(_F.none));
        expect(d.routes, hasLength(3));
        expect(d.routes.toSet(), hasLength(3));
        expect(d.routes.where((r) => r == _Rt.straight), hasLength(1));
        wrongs.addAll(d.routes.where((r) => r != _Rt.straight));
        if (d.callAt == 1) expect(d.routes, contains(_Rt.tree));
        expect(d.shelf.toSet(), _I.values.toSet());
        expect(d.cards.toSet(), _S.values.toSet());
        expect(d.cards, isNot(_S.values), reason: 'never already in order');
        plays.add('${d.fault}${d.routes}${d.shelf}${d.cards}${d.callAt}${d.mirror}');
      }
      expect(calls, {0, 1, 2});
      expect(faults, _F.values.toSet());
      expect(wrongs, {_Rt.tree, _Rt.roof, _Rt.detour});
      expect(mirrors, {true, false});
      expect(plays.length, greaterThan(100), reason: 'plays differ');
    });

    test('the straight route is the shortest on the sketch; every other is its mistake', () {
      for (final r in _Rt.values) {
        if (r != _Rt.straight) expect(M4ServicePlanMap.length(r), greaterThan(M4ServicePlanMap.length(_Rt.straight)));
      }
      expect(_M.forRoute(_Rt.straight), isNull);
      expect(_M.forRoute(_Rt.tree), _M.routeTree);
      expect(_M.forRoute(_Rt.roof), _M.routeRoof);
      expect(_M.forRoute(_Rt.detour), _M.routeLong);
    });

    test('the material: the right six; each gap or trap is its mistake', () {
      expect(_M.forKit({...m4ServicePlanKit}), isNull);
      expect(_M.forKit({...m4ServicePlanKit, _I.thinCable}), _M.thinCable);
      expect(_M.forKit({...m4ServicePlanKit}..remove(_I.cable)), _M.thinCable);
      expect(_M.forKit({...m4ServicePlanKit}..remove(_I.giWire)), _M.noGiWire);
      expect(_M.forKit({...m4ServicePlanKit}..remove(_I.ipc)), _M.noIpc);
      expect(_M.forKit({...m4ServicePlanKit, _I.tape}), _M.noIpc);
      expect(_M.forKit({...m4ServicePlanKit}..remove(_I.rackBolt)), _M.noAnchor);
      expect(_M.forKit({...m4ServicePlanKit}..remove(_I.clamp)), _M.noAnchor);
      expect(_M.forKit({...m4ServicePlanKit}..remove(_I.straps)), _M.noStraps);
    });

    test('a play: papers, route, material, order; slips 15 each; pass ≥ 55', () {
      const deal = M4ServicePlanDeal(
        fault: _F.permitMissing,
        routes: [_Rt.tree, _Rt.straight, _Rt.roof],
        mirror: false,
        shelf: _I.values,
        cards: [_S.strap, _S.anchor, _S.connect, _S.giWire],
        callAt: 0,
      );
      final r = M4ServicePlanRun(deal);
      // Papers: fetching a fine one is a slip; the missing one is right.
      expect(r.papersFetch(), isNull, reason: 'nothing selected');
      r.selectPaper(M4ServicePlanPaper.permit);
      expect(r.papersFetch(), isNull);
      expect(r.shown, isTrue);
      expect(r.fetched, isTrue);
      expect(r.caught, [_L.caughtPapers]);
      r.next();
      // Route: picking is free; the tree route is the slip.
      r.selectRoute(_Rt.straight);
      r.selectRoute(_Rt.tree);
      expect(r.routeGo(), _M.routeTree);
      expect(r.slips, 1);
      r.next();
      // Material: toggling is free.
      for (final i in m4ServicePlanKit) {
        r.toggleItem(i);
      }
      r.toggleItem(_I.tape);
      r.toggleItem(_I.tape);
      expect(r.kitLoad(), isNull);
      r.next();
      // Work order.
      expect(r.tapCard(_S.anchor), isNull);
      expect(r.shown, isFalse);
      expect(r.tapCard(_S.anchor), isNull, reason: 'placed already');
      expect(r.tapCard(_S.strap), _M.orderWrong);
      expect(r.slips, 2);
      r.next();
      expect(r.done, isTrue);
      expect(r.percent, 70);
      expect(r.passed, isTrue);
    });

    test('papers: start is right only with all three; a wrong fetch is the misread slip', () {
      final ok = M4ServicePlanRun(const M4ServicePlanDeal(fault: _F.none, routes: [_Rt.straight, _Rt.tree, _Rt.roof], mirror: true, shelf: _I.values, cards: [_S.connect, _S.strap, _S.giWire, _S.anchor], callAt: 1));
      expect(ok.papersStart(), isNull);
      expect(ok.shown, isTrue);
      final bad = M4ServicePlanRun(const M4ServicePlanDeal(fault: _F.orderUnapproved, routes: [_Rt.straight, _Rt.tree, _Rt.roof], mirror: true, shelf: _I.values, cards: [_S.connect, _S.strap, _S.giWire, _S.anchor], callAt: 1));
      expect(bad.papersStart(), _M.paperMissing);
      final bad2 = M4ServicePlanRun(bad.deal)..selectPaper(M4ServicePlanPaper.meter);
      expect(bad2.papersFetch(), _M.paperMisread);
      final bad3 = M4ServicePlanRun(bad.deal);
      expect(bad3.takeShortcut(), _M.paperMissing);
      expect(_M.pushed(_R.route), _M.routeTree);
      expect(_M.pushed(_R.kit), _M.noGiWire);
    });

    test('mistakes book: unique 4.3 keys, pictures exist, lesson points 0–3, none deadly', () {
      final keys = <String>{};
      for (final m in _M.all) {
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        expect(keys.add(m.key), isTrue);
        expect(m.key, startsWith('4.3/m4_service_plan/'));
        expect(m.lessonPoint, inInclusiveRange(0, 3), reason: m.key);
        expect(m.deadly, isFalse, reason: m.key);
      }
      expect(_M.all, hasLength(11));
      // Everything the run can book is in the book.
      final booked = <DoMistake>{
        for (final r in _Rt.values) ?_M.forRoute(r),
        for (final r in _R.values) _M.pushed(r),
        _M.paperMissing,
        _M.paperMisread,
        _M.orderWrong,
        for (final i in _I.values) ?_M.forKit({...m4ServicePlanKit}..remove(i)),
        ?_M.forKit({...m4ServicePlanKit, _I.tape}),
        ?_M.forKit({...m4ServicePlanKit, _I.thinCable}),
      };
      expect(_M.all.toSet().containsAll(booked), isTrue);
    });

    test('quick bonus ≈ 85 % of a clean play: 70 s; one pack', () {
      expect(_pack.quickMs, 70000);
      expect(m4ServicePlanPacks.keys, ['do_4_3_a']);
    });

    test('reasons fit the round, same length, big enough; his choices too; his exit line is recorded', () {
      final every = <String>{
        for (final r in _R.values) ..._L.whyRight(r),
        ..._L.papersFetchWhy,
        ..._L.excuses,
      }.toList();
      expectSameLength('why', every);
      for (final right in [for (final r in _R.values) _L.whyRight(r), _L.papersFetchWhy]) {
        expectLibrary('why', right, _L.excuses);
        expect(right.toSet().intersection(_L.excuses.toSet()), isEmpty);
        for (var s = 0; s < 10; s++) {
          final deal = dealChoices(right, _L.excuses, math.Random(s));
          expect(deal.where((o) => o.correct).length, 1);
          expect(deal.map((o) => o.textBn).toSet().length, 3);
        }
      }
      for (final cw in [_L.coworkerPapers, _L.coworkerRoute, _L.coworkerKit]) {
        expectSameLength('choice', [...cw.right, ...cw.wrong]);
        expectLibrary('choice', cw.right, cw.wrong);
      }
      expect(LearnVoice.resolve(_L.coworkerExit, rival: true), isNotNull);
      expect(_L.toRecord, hasLength(3));
      expect(_L.intro.length, lessThan(80));
      for (final l in [..._L.guideLines, ..._L.toRecord]) {
        expect(l.contains('পানি'), isFalse, reason: l);
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
        final seed = _seedWhere((d) => d.callAt != 0);
        await t.pumpWidget(ProviderScope(
          child: MaterialApp(home: M4ServicePlanPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
        ));
        await t.pump(const Duration(milliseconds: 100));
        expect(find.text('শুরু'), findsNothing);
        await waitIntro(t);
        // A paper picked — then nothing more happens.
        await t.tap(find.byKey(const ValueKey('paper-meter')));
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
        debugPrint('PERF m4_service_plan ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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

    testWidgets('the guide comes first: a tap does not skip him; then the papers', (t) async {
      final seed = _seedWhere((d) => d.callAt != 0);
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M4ServicePlanPage(ctx: _ctx, pack: _pack, muted: true, seed: seed))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 600);
      for (final p in M4ServicePlanPaper.values) {
        expect(find.byKey(ValueKey('paper-${p.name}')), findsOneWidget);
      }
      expect(find.text(_L.papersGo), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final seed = _seedWhere((d) => d.callAt != 0);
      final c = await _open(t, seed);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(_L.ask(_R.papers))), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    for (final call in [0, 2]) {
      testWidgets('flow: four rounds right, reasons; refuse him on round $call → pass, saved', (t) async {
        final seed = _seedWhere((d) => d.callAt == call, from: 1);
        final deal = dealM4ServicePlan(math.Random(seed));
        final c = await _open(t, seed);
        for (var i = 0; i < 4; i++) {
          await _playRight(t, deal, i);
        }
        await _pump(t, 3000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['4.3/do/0'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['4.3/do/0'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(_L.caughtCall), findsOneWidget);
        expect(find.text(_L.caughtOrder), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('starting with a paper missing: its card (no deadly), then the route', (t) async {
      final seed = _seedWhere((d) => d.callAt != 0 && d.fault != _F.none);
      final c = await _open(t, seed);
      await _tapText(t, _L.papersGo);
      await _pump(t, 800);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, _M.paperMissing.key);
      expect(s.mistakes.single.deadly, isFalse);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      expect(find.byType(MistakeCard), findsNothing);
      expect(find.byKey(const ValueKey('route-straight')), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('listening to him on the papers: "কাগজ পরে হবে" is the slip', (t) async {
      final seed = _seedWhere((d) => d.callAt == 0);
      final c = await _open(t, seed);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      final wrong = _onScreen(_L.coworkerPapers.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await _pump(t, 1200);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, _M.paperMissing.key);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final seed = _seedWhere((d) => d.callAt == 2 && d.fault != _F.none);
      final deal = dealM4ServicePlan(math.Random(seed));
      final c = await _open(t, seed);
      await _tapText(t, _L.papersGo);
      await _pump(t, 1200);
      expect(find.byType(MistakeCard), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      await _tapKey(t, 'route-${deal.routes.firstWhere((r) => r != _Rt.straight).name}');
      await _tapText(t, _L.routeGo);
      await _pump(t, 1200);
      expect(find.byType(MistakeCard), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 800);
      // The material round: he comes; listening is the third slip.
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await t.tap(_onScreen(_L.coworkerKit.wrong).first, warnIfMissed: false);
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });
  });
}
