// Lesson 3.9 (গার্ড ওয়্যার ও ক্রেডল গার্ডিং), কাজ 2 "জাল মেরামত": the rules
// (shutdown → PTW → test → earth, traffic held, then up; every fault tagged;
// the right fix for each — tension to the right level, GI lacing, spanner,
// pipe then earth lead; clearance, down, earth off, then line clear; up on a
// live cradle or the earth on a live line = deadly), the deal, the reason
// libraries, and the level in the shell: idle perf, the guide first, a full
// clean play with the coworker refused, a slip card that keeps the station,
// three slips, the deadly freeze (climbing live; listening to him).
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
import 'package:slm_flutter/features/game/m3_guard_repair.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';

const _ctx = LevelContext(
  rungId: '3.9/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '3.9',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m3GuardRepairPacks['do_3_9_b']!;
typedef _L = M3GuardRepairLines;
typedef _M = M3GuardRepairMistakes;

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
M3GuardGeo get _geo => M3GuardGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
Future<void> _tapAt(WidgetTester t, Offset design) async {
  await t.tapAt(design * _k);
  await _pump(t, 300);
}

Future<void> _tapFault(WidgetTester t, M3GuardFault f) => _tapAt(t, _geo.hit(f).center);

Future<void> _tool(WidgetTester t, String label) async {
  await t.tap(_label(label));
  await _pump(t, 300);
}

Future<void> _button(WidgetTester t, String text) async {
  await t.tap(find.text(text));
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M3GuardRepairPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
  )));
  await _pump(t, 1000);
  await waitIntro(t);
  await _pump(t, 300);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

/// Ask for the shutdown: he walks in; refuse him on the deck.
Future<void> _refuse(WidgetTester t) async {
  await _tool(t, _L.shutdown);
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes before the shutdown');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, _L.coworker.right);
  await _pump(t, 2600);
}

Future<void> _reason(WidgetTester t, List<String> right) async {
  expect(find.text(MistakeLines.slipHead), findsNothing);
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
  await _pump(t, 700);
  await _pickRight(t, right);
  await _pump(t, 5000);
}

Future<void> _prepRight(WidgetTester t) async {
  await _tool(t, _L.ptw);
  await _tool(t, _L.tester);
  expect(find.text(_L.testerDead), findsOneWidget);
  await _tool(t, _L.earthSet);
  await _tool(t, _L.traffic);
  await _tool(t, _L.climb);
}

Future<void> _repairRight(WidgetTester t, M3GuardRepairDeal d) async {
  for (final f in d.faults) {
    switch (f.kind) {
      case M3GuardFaultKind.sag:
        await _tool(t, _L.toolBn(M3GuardTool.tension));
        await _tapFault(t, f);
        for (var i = 0; i < d.need; i++) {
          await _button(t, _L.pull);
        }
        await _button(t, _L.tensionOk);
      case M3GuardFaultKind.lacing:
        await _tool(t, _L.toolBn(M3GuardTool.gi));
        await _tapFault(t, f);
      case M3GuardFaultKind.clamp:
        await _tool(t, _L.toolBn(M3GuardTool.spanner));
        await _tapFault(t, f);
      case M3GuardFaultKind.earth:
        await _tool(t, _L.toolBn(M3GuardTool.pipe));
        await _tapFault(t, f);
        await _tool(t, _L.toolBn(M3GuardTool.earthLead));
        await _tapFault(t, f);
    }
  }
}

void main() {
  group('rules', () {
    test('deals: the sag always and two other faults, apart; plays differ', () {
      final seen = <String>{};
      final geo = M3GuardGeo.forScene(780, 0);
      for (var s = 0; s < 80; s++) {
        final d = m3GuardRepairDeal(math.Random(s));
        expect(d.faults, hasLength(3));
        expect(d.faults.where((f) => f.kind == M3GuardFaultKind.sag), hasLength(1));
        expect(d.faults.map((f) => f.kind).toSet(), hasLength(3));
        expect(d.need, inInclusiveRange(3, 5));
        expect(d.faults.map((f) => f.kind), contains(d.repairAsk));
        // No two faults' tap areas overlap.
        for (var i = 0; i < 3; i++) {
          for (var j = i + 1; j < 3; j++) {
            expect(geo.hit(d.faults[i]).overlaps(geo.hit(d.faults[j])), isFalse, reason: '${d.faults[i].kind} / ${d.faults[j].kind}');
          }
        }
        seen.add('${d.faults.map((f) => '${f.kind.name}${f.side}${f.lacing}').join('|')}${d.need}${d.repairAsk.name}${d.closeAsk.name}');
      }
      expect(seen.length, greaterThan(40));
    });

    M3GuardRepairRun run([int seed = 1]) => M3GuardRepairRun(m3GuardRepairDeal(math.Random(seed)));

    test('prep: the PTW only after the shutdown; the earth only after a dead test', () {
      final r = run();
      expect(r.takePtw(), _M.ptwEarly);
      expect(r.test(), isTrue, reason: 'live before the shutdown');
      expect(r.proved, isFalse);
      r.callShutdown();
      expect(r.putEarth(), _M.earthUntested);
      expect(r.test(), isFalse);
      expect(r.putEarth(), isNull);
      expect(r.takePtw(), isNull);
      expect(r.slips, 2);
    });

    test('the earth on a live line is deadly; up on a live cradle is deadly', () {
      final a = run()..holdTraffic();
      final m = a.putEarth();
      expect(m, _M.earthLive);
      expect(m!.deadly, isTrue);
      expect(a.ended, isTrue);
      final b = run();
      expect(b.climbUp(), _M.climbLive);
      expect(b.ended, isTrue);
    });

    test('up: every step first — PTW, test, earth, traffic', () {
      final r = run()..callShutdown();
      expect(r.climbUp(), _M.noPtw);
      r.takePtw();
      expect(r.climbUp(), _M.noTest);
      r.test();
      expect(r.climbUp(), _M.noEarth);
      r.putEarth();
      expect(r.climbUp(), _M.noTraffic);
      r.holdTraffic();
      expect(r.climbUp(), isNull);
      expect(r.up, isTrue);
      expect(r.stationDone, isTrue);
      expect(r.caught, containsAll([_L.caughtSafe, _L.caughtTraffic]));
    });

    M3GuardRepairRun upRun([int seed = 1]) {
      final r = run(seed)
        ..callShutdown()
        ..takePtw()
        ..test()
        ..putEarth()
        ..holdTraffic();
      expect(r.climbUp(), isNull);
      r.next();
      return r;
    }

    test('inspect: a missed fault is a slip (and then tagged); all found → ok', () {
      final r = upRun();
      expect(r.tagFault(0), isTrue);
      expect(r.tagFault(0), isFalse);
      expect(r.doneLooking(), _M.missedFault);
      expect(r.allTagged, isTrue);
      expect(r.doneLooking(), isNull);
      expect(r.caught, contains(_L.caughtAll));
    });

    test('repair: the right fix for each; wrong tools, a rope, a bare lead and over-pulling are slips', () {
      for (var seed = 0; seed < 30; seed++) {
        final r = upRun(seed);
        for (var i = 0; i < 3; i++) {
          r.tagFault(i);
        }
        r
          ..doneLooking()
          ..next();
        for (final (i, f) in r.faults.indexed) {
          switch (f.kind) {
            case M3GuardFaultKind.sag:
              r.hold(M3GuardTool.spanner);
              expect(r.apply(i), _M.wrongFix);
              r.hold(M3GuardTool.tension);
              expect(r.apply(i), isNull);
              expect(r.tensioning, isTrue);
              expect(r.tensionDone(), M3GuardTensionCheck.slack);
              for (var k = 0; k < r.deal.need; k++) {
                expect(r.pullOnce(), isNull);
              }
              expect(r.pullOnce(), _M.overTension);
              expect(r.tension, 1);
              expect(r.tensionDone(), M3GuardTensionCheck.ok);
            case M3GuardFaultKind.lacing:
              r.hold(M3GuardTool.rope);
              expect(r.apply(i), _M.rope);
              r.hold(M3GuardTool.gi);
              expect(r.apply(i), isNull);
            case M3GuardFaultKind.clamp:
              r.hold(M3GuardTool.gi);
              expect(r.apply(i), _M.wrongFix);
              r.hold(M3GuardTool.spanner);
              expect(r.apply(i), isNull);
            case M3GuardFaultKind.earth:
              r.hold(M3GuardTool.earthLead);
              expect(r.apply(i), _M.bareEarth);
              r.hold(M3GuardTool.pipe);
              expect(r.apply(i), isNull);
              expect(r.fixed.contains(i), isFalse);
              r.hold(M3GuardTool.earthLead);
              expect(r.apply(i), isNull);
          }
          expect(r.fixed.contains(i), isTrue, reason: '${f.kind}');
        }
        expect(r.allFixed, isTrue);
        expect(r.stationDone, isTrue);
        expect(r.slips, 4, reason: 'one slip per fault (the sag: two)');
      }
    });

    test('close: clearance, down, earth off, then the line clear', () {
      final r = upRun();
      for (var i = 0; i < 3; i++) {
        r.tagFault(i);
      }
      r
        ..doneLooking()
        ..next()
        ..fixed.addAll([0, 1, 2])
        ..next();
      expect(r.station, M3GuardStation.close);
      expect(r.takeEarthOff(), _M.earthOffUp);
      expect(r.giveLineClear(), _M.clearUp);
      expect(r.comeDown(), _M.noClearance);
      r.measure();
      expect(r.comeDown(), isNull);
      expect(r.giveLineClear(), _M.clearEarthed);
      expect(r.takeEarthOff(), isNull);
      expect(r.giveLineClear(), isNull);
      expect(r.stationDone, isTrue);
      r.next();
      expect(r.finished, isTrue);
      expect(r.passed, isFalse, reason: '4 slips → 40 %');
      expect(r.caught, containsAll([_L.caughtClearance, _L.caughtClose]));
    });

    test('English digits only; every mistake has its picture and its own key; two deadly', () {
      final all = <String>[
        _L.intro,
        ..._L.tasks,
        ..._L.allRight,
        ..._L.myths,
        ..._L.coworker.recordedLines,
        ..._L.coworker.right,
        ..._L.coworker.wrong,
        ..._L.coworker.asks,
        for (final m in _M.all) m.textBn,
        _L.allSet,
        _L.fail,
        _L.permitNo(4821),
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
      expect(_M.all.where((m) => m.deadly), [_M.climbLive, _M.earthLive]);
      expect(_M.all.map((m) => m.key).toSet(), hasLength(_M.all.length));
      for (final m in _M.all) {
        expect(m.key, startsWith('3.9/m3_guard_repair/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 3));
      }
      expect(m3GuardRepairPacks.keys, ['do_3_9_b']);
    });

    test('reasons: same length, big enough, never a rule marked wrong; his exit is recorded', () {
      expectSameLength('why', [..._L.allRight, ..._L.myths]);
      expect(_L.myths.toSet().intersection(_L.allRight.toSet()), isEmpty);
      final libs = [
        _L.prepWhy,
        _L.inspectWhy,
        for (final k in M3GuardFaultKind.values) _L.repairWhy(k),
        for (final w in M3GuardCloseWhy.values) _L.closeWhy(w),
      ];
      for (final right in libs) {
        expectLibrary(right.first, right, _L.myths);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(right, _L.myths, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      final cw = _L.coworker;
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
        await t.pumpWidget(ProviderScope(child: MaterialApp(home: M3GuardRepairPage(ctx: _ctx, pack: _pack, muted: true, seed: 4))));
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
        debugPrint('PERF m3_guard_repair ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M3GuardRepairPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(_label(_L.shutdown), findsNothing);
      await waitIntro(t);
      await _pump(t, 300);
      expect(_label(_L.shutdown), findsOneWidget);
      expect(find.text(_L.job), findsOneWidget);
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
      expect(lines.every((l) => l.contains(_L.askPrep)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('flow: prep in order, refuse him, tag, fix, close; right reasons → pass', (t) async {
      final deal = m3GuardRepairDeal(math.Random(7));
      final c = await _open(t, 7);
      await _refuse(t);
      await _prepRight(t);
      await _reason(t, _L.prepWhy);
      for (final f in deal.faults) {
        await _tapFault(t, f);
      }
      await _button(t, _L.doneLooking);
      await _reason(t, _L.inspectWhy);
      await _repairRight(t, deal);
      await _reason(t, _L.repairWhy(deal.repairAsk));
      await _tool(t, _L.measure);
      await _tool(t, _L.comeDown);
      await _tool(t, _L.earthOff);
      await _tool(t, _L.lineClear);
      await _reason(t, _L.closeWhy(deal.closeAsk));
      await _pump(t, 2000);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['3.9/do/1'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['3.9/do/1'], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(_L.caughtCall), findsOneWidget);
      expect(find.text(_L.caughtClose), findsOneWidget);
      expect(find.text(_L.caughtSafe), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a slip (PTW before the shutdown) shows its card; the prep goes on after it', (t) async {
      final c = await _open(t, 2);
      await _tool(t, _L.ptw);
      await _pump(t, 300);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(_M.ptwEarly.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_label(_L.shutdown), findsOneWidget, reason: 'the same station');
      expect(c.read(gameSaveProvider).mistakes.single.key, _M.ptwEarly.key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final c = await _open(t, 2);
      for (var i = 0; i < 3; i++) {
        await _tool(t, _L.ptw);
        await _pump(t, 300);
        if (i < 2) {
          await t.tap(find.text(MistakeLines.gotIt));
          await _pump(t, 600);
        }
      }
      await _pump(t, 1500);
      expect(find.byType(StruckOutCard), findsOneWidget);
      await _close(t, c);
    });

    testWidgets('up on the cradle with the line live: the scene freezes first, then the card (near-miss)', (t) async {
      final c = await _open(t, 2);
      await _tool(t, _L.climb);
      await _pump(t, 300);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, _M.climbLive.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('listening to him = deadly: freeze, then the card', (t) async {
      final c = await _open(t, 11);
      await _tool(t, _L.shutdown);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      final wrong = _onScreen(_L.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsOneWidget);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('a fault left untagged: the card, and then all are tagged', (t) async {
      final deal = m3GuardRepairDeal(math.Random(13));
      final c = await _open(t, 13);
      await _refuse(t);
      await _prepRight(t);
      await _reason(t, _L.prepWhy);
      await _tapFault(t, deal.faults.first);
      await _button(t, _L.doneLooking);
      expect(find.text(_M.missedFault.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _button(t, _L.doneLooking);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'all tagged now: the reason');
      await _close(t, c);
    });
  });
}
