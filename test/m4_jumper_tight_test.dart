// Lesson 4.2 (জাম্পার কানেকশন ও টাইট করা), কাজ 2 "ঢিলে জাম্পার ধরো": the
// rules (spot the bad clamp; any tool on a live jumper = deadly; shutdown →
// tester → earth before the work; brush + paste before the wrenches; a melted
// clamp is replaced; the right torque band; the earth off before the line
// comes back; the recheck), the deal, the reason libraries, and the level in
// the shell: idle perf, the guide first, a full clean play with the coworker
// refused, a slip card that keeps the pole, three slips, the deadly freeze.
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
import 'package:slm_flutter/features/game/m4_jumper_tight.dart';
import 'package:slm_flutter/features/game/m4_jumper_tight_world.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';

const _ctx = LevelContext(
  rungId: '4.2/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '4.2',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m4JumperTightPacks['do_4_2_b']!;
typedef _L = M4JumperTightLines;
typedef _M = M4JumperTightMistakes;

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
M4JumperTightGeo get _geo => M4JumperTightGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
Future<void> _tapAt(WidgetTester t, Offset design) async {
  await t.tapAt(design * _k);
  await _pump(t, 300);
}

Future<void> _tapClamp(WidgetTester t, int phase, int end) => _tapAt(t, _geo.clamp(phase, end));

Future<void> _tool(WidgetTester t, String label) async {
  await t.tap(_label(label));
  await _pump(t, 300);
}

/// Holds "টাইট দিন" for [ms] (the needle runs 0 → 1 in 2600 ms).
Future<void> _holdTight(WidgetTester t, int ms) async {
  final g = await t.startGesture(t.getCenter(_label(_L.tighten)));
  await _pump(t, ms);
  await g.up();
  await _pump(t, 400);
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M4JumperTightPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

/// Plays pole [i] right (the coworker refused on his pole).
Future<void> _playRight(WidgetTester t, M4JumperTightDeal deal, int i) async {
  final s = deal.sites[i];
  await _tapClamp(t, s.phase, s.end);
  expect(_label(_L.shutdown), findsOneWidget, reason: 'spotted on pole $i');
  if (i == deal.callAt) {
    expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 8000), isTrue, reason: 'he comes on pole $i');
    await _pumpUntil(t, find.byType(ChoiceDeck));
    await _pump(t, 600);
    await _pickRight(t, _L.coworker.right);
    await _pump(t, 2600);
  }
  await _tool(t, _L.shutdown);
  await _tool(t, _L.tester);
  expect(find.text(_L.testerDead), findsOneWidget);
  await _tool(t, _L.earth);
  await _tool(t, _L.brush);
  await _tapClamp(t, s.phase, s.end);
  if (s.kind == M4JumperTightKind.melted) {
    await _tool(t, _L.clamp);
    await _tapClamp(t, s.phase, s.end);
  }
  await _tool(t, _L.wrench);
  await _tapClamp(t, s.phase, s.end);
  await _holdTight(t, 1900);
  await _tool(t, _L.earth); // off
  await _tool(t, _L.shutdown); // the PTW back
  await _tapClamp(t, s.phase, s.end); // the recheck
  await _pump(t, 2200);
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'pole $i');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 700);
  await _pickRight(t, _L.whyRight(s));
  await _pump(t, 6000);
}

/// A clamp that is not the bad one.
(int, int) _goodClamp(M4JumperTightSite s) => ((s.phase + 1) % 3, s.end);

void main() {
  group('rules', () {
    test('deals: three poles — glow, spark, melted; the melted asks "replace"; plays differ', () {
      final seen = <String>{};
      for (var s = 0; s < 80; s++) {
        final d = m4JumperTightDeal(math.Random(s));
        expect(d.sites, hasLength(3));
        expect(d.sites.map((x) => x.kind).toSet(), M4JumperTightKind.values.toSet());
        expect(d.sites.map((x) => x.why).toSet(), hasLength(3), reason: 'each pole asks its own reason');
        for (final x in d.sites) {
          expect(x.why == M4JumperTightWhy.replace, x.kind == M4JumperTightKind.melted);
          expect(x.phase, inInclusiveRange(0, 2));
          expect(x.end, inInclusiveRange(0, 1));
        }
        expect(d.callAt, inInclusiveRange(0, 2));
        seen.add(d.sites.map((x) => '${x.kind.name}${x.phase}${x.end}${x.why.name}').join('|') + d.callAt.toString());
      }
      expect(seen.length, greaterThan(60));
    });

    M4JumperTightRun run1(M4JumperTightKind k) => M4JumperTightRun(M4JumperTightDeal(
          sites: [M4JumperTightSite(id: 'x', kind: k, phase: 1, end: 0, why: k == M4JumperTightKind.melted ? M4JumperTightWhy.replace : M4JumperTightWhy.clean)],
          callAt: 0,
        ));

    M4JumperTightRun isolated(M4JumperTightKind k) {
      final r = run1(k);
      expect(r.tapClamp(1, 0), isNull);
      expect(r.toggleShutdown(), isNull);
      expect(r.test(), isFalse);
      expect(r.toggleEarth(), isNull);
      expect(r.up, isTrue);
      return r;
    }

    test('spot: the wrong clamp is a slip; the right one is spotted; no tools before it', () {
      final r = run1(M4JumperTightKind.glow);
      r.hold(M4JumperTightTool.wrench);
      expect(r.tool, M4JumperTightTool.none, reason: 'no tools before the spot');
      expect(r.toggleShutdown(), isNull);
      expect(r.shutdown, isFalse);
      expect(r.tapClamp(0, 0), _M.misSpot);
      expect(r.tapClamp(1, 1), _M.misSpot);
      expect(r.spotted, isFalse);
      expect(r.tapClamp(1, 0), isNull);
      expect(r.spotted, isTrue);
      expect(r.slips, 2);
      expect(r.caught, contains(_L.caughtSpot));
    });

    test('any tool on a jumper while the line is live is deadly (any clamp, any tool)', () {
      for (final tool in [M4JumperTightTool.brush, M4JumperTightTool.clamp, M4JumperTightTool.wrench]) {
        for (final (p, e) in [(1, 0), (2, 1)]) {
          final r = run1(M4JumperTightKind.spark)..tapClamp(1, 0);
          r.hold(tool);
          final m = r.tapClamp(p, e);
          expect(m, _M.workLive);
          expect(m!.deadly, isTrue);
          expect(r.ended, isTrue);
        }
      }
    });

    test('isolation order: earth or work before proving dead, work before earth = slips', () {
      final r = run1(M4JumperTightKind.glow)..tapClamp(1, 0);
      expect(r.toggleEarth(), _M.noProve, reason: 'earth on a live line');
      expect(r.toggleShutdown(), isNull);
      expect(r.live, isFalse);
      expect(r.toggleEarth(), _M.noProve, reason: 'not proven dead yet');
      r.hold(M4JumperTightTool.brush);
      expect(r.tapClamp(1, 0), _M.noProve);
      expect(r.test(), isFalse);
      expect(r.tapClamp(1, 0), _M.noEarth);
      expect(r.toggleEarth(), isNull);
      expect(r.tapClamp(1, 0), isNull);
      expect(r.cleaned, isTrue);
      expect(r.slips, 4);
      expect(r.caught, containsAll([_L.caughtSafe, _L.caughtClean]));
    });

    test('loose clamp: brush before the wrenches; the band; past it is a slip', () {
      final r = isolated(M4JumperTightKind.glow)..hold(M4JumperTightTool.wrench);
      expect(r.tapClamp(1, 0), _M.noClean);
      r.hold(M4JumperTightTool.brush);
      expect(r.tapClamp(1, 0), isNull);
      r.hold(M4JumperTightTool.wrench);
      expect(r.tapClamp(1, 0), isNull);
      expect(r.wrenchOn, isTrue);
      expect(r.toggleShutdown(), isNull, reason: 'busy with the wrenches');
      expect(r.torque(0.3), isNull);
      expect(r.tightened, isFalse, reason: 'still loose');
      expect(r.torque(0.95), _M.overTight);
      expect(r.wrenchOn, isTrue);
      expect(r.torque(0.7), isNull);
      expect(r.tightened, isTrue);
      expect(r.fixed, isTrue);
      expect(r.wrenchOn, isFalse);
      expect(r.slips, 2);
      expect(r.caught, contains(_L.caughtTorque));
    });

    test('melted clamp: tightening it is a slip; a new clamp (after the brush) then the wrenches', () {
      final r = isolated(M4JumperTightKind.melted)..hold(M4JumperTightTool.clamp);
      expect(r.tapClamp(1, 0), _M.noClean);
      r.hold(M4JumperTightTool.brush);
      r.tapClamp(1, 0);
      r.hold(M4JumperTightTool.wrench);
      expect(r.tapClamp(1, 0), _M.meltedTighten);
      r.hold(M4JumperTightTool.wrench);
      r.hold(M4JumperTightTool.clamp);
      expect(r.tapClamp(1, 0), isNull);
      expect(r.replaced, isTrue);
      expect(r.fixed, isFalse, reason: 'the new clamp is not tight yet');
      r.hold(M4JumperTightTool.wrench);
      r.tapClamp(1, 0);
      r.torque(0.7);
      expect(r.fixed, isTrue);
      expect(r.caught, contains(_L.caughtReplace));
    });

    test('the line back: never with the earth on, never before the fix; then the recheck ends the pole', () {
      final r = isolated(M4JumperTightKind.spark);
      expect(r.toggleShutdown(), _M.earthOn);
      r.toggleEarth();
      expect(r.toggleShutdown(), _M.unfinished);
      expect(r.shutdown, isTrue);
      r.toggleEarth();
      r.hold(M4JumperTightTool.brush);
      r.tapClamp(1, 0);
      r.hold(M4JumperTightTool.wrench);
      r.tapClamp(1, 0);
      r.torque(0.7);
      expect(r.tapClamp(1, 0), isNull);
      expect(r.checked, isFalse, reason: 'no recheck while shut down');
      expect(r.toggleShutdown(), _M.earthOn);
      r.toggleEarth();
      expect(r.toggleShutdown(), isNull);
      expect(r.live, isTrue);
      expect(r.back, isTrue);
      expect(r.tapClamp(0, 1), isNull);
      expect(r.checked, isFalse, reason: 'another clamp is no recheck');
      expect(r.tapClamp(1, 0), isNull);
      expect(r.checked, isTrue);
      expect(r.caught, contains(_L.caughtCheck));
      expect(r.slips, 3);
    });

    test('English digits only; every mistake has its picture; one deadly; unique keys', () {
      final all = <String>[
        _L.intro,
        ..._L.tasks,
        _L.torqueMore,
        ..._L.allRight,
        ..._L.myths,
        ..._L.coworker.recordedLines,
        ..._L.coworker.right,
        ..._L.coworker.wrong,
        ..._L.coworker.asks,
        for (final m in _M.all) m.textBn,
        _L.allSet,
        _L.fail,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
      expect(_M.all.where((m) => m.deadly), [_M.workLive]);
      expect(_M.all.map((m) => m.key).toSet(), hasLength(_M.all.length));
      for (final m in _M.all) {
        expect(m.key, startsWith('4.2/m4_jumper_tight/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 2));
      }
      expect(m4JumperTightPacks.keys, ['do_4_2_b']);
    });

    test('reasons: same length, big enough, never a rule marked wrong; his exit is recorded', () {
      expectSameLength('why', [..._L.allRight, ..._L.myths]);
      expect(_L.myths.toSet().intersection(_L.allRight.toSet()), isEmpty);
      for (final w in M4JumperTightWhy.values) {
        final s = M4JumperTightSite(id: 'x', kind: w == M4JumperTightWhy.replace ? M4JumperTightKind.melted : M4JumperTightKind.glow, phase: 0, end: 0, why: w);
        final right = _L.whyRight(s);
        expectLibrary('$w', right, _L.myths);
        expect(_L.whyQuestion(s), isNotEmpty);
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
        await t.pumpWidget(ProviderScope(child: MaterialApp(home: M4JumperTightPage(ctx: _ctx, pack: _pack, muted: true, seed: 4))));
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
        debugPrint('PERF m4_jumper_tight ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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

    testWidgets('the guide comes first: a tap does not skip him; the tools come after the spot', (t) async {
      final deal = m4JumperTightDeal(math.Random(3));
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M4JumperTightPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(find.byType(GuideIntro), findsNothing);
      expect(_label(_L.shutdown), findsNothing, reason: 'no tools before the spot');
      final s = deal.sites[0];
      await _tapClamp(t, s.phase, s.end);
      expect(_label(_L.shutdown), findsOneWidget);
      expect(_label(_L.wrench), findsOneWidget);
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
      expect(lines.every((l) => l.contains(_L.askSpot)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('flow: spot, shut down, test, earth, clean, (replace), torque, back, recheck; refuse him → pass', (t) async {
      final deal = m4JumperTightDeal(math.Random(7));
      final c = await _open(t, 7);
      for (var i = 0; i < 3; i++) {
        await _playRight(t, deal, i);
      }
      await _pump(t, 2000);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['4.2/do/1'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['4.2/do/1'], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(_L.caughtCall), findsOneWidget);
      expect(find.text(_L.caughtReplace), findsOneWidget);
      expect(find.text(_L.caughtCheck), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a slip (the wrong clamp) shows its card; the same pole goes on after it', (t) async {
      final deal = m4JumperTightDeal(math.Random(2));
      final c = await _open(t, 2);
      final (p, e) = _goodClamp(deal.sites[0]);
      await _tapClamp(t, p, e);
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(_M.misSpot.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      await _tapClamp(t, deal.sites[0].phase, deal.sites[0].end);
      expect(_label(_L.shutdown), findsOneWidget, reason: 'the same pole, spotted now');
      expect(c.read(gameSaveProvider).mistakes.single.key, _M.misSpot.key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a hold past the band is a slip; the needle starts again', (t) async {
      final deal = m4JumperTightDeal(math.Random(2));
      final s = deal.sites[0];
      final c = await _open(t, 2);
      await _tapClamp(t, s.phase, s.end);
      if (deal.callAt == 0) {
        await _pumpUntil(t, find.byType(ChoiceDeck), maxMs: 9000);
        await _pump(t, 600);
        await _pickRight(t, _L.coworker.right);
        await _pump(t, 2600);
      }
      await _tool(t, _L.shutdown);
      await _tool(t, _L.tester);
      await _tool(t, _L.earth);
      await _tool(t, _L.brush);
      await _tapClamp(t, s.phase, s.end);
      if (s.kind == M4JumperTightKind.melted) {
        await _tool(t, _L.clamp);
        await _tapClamp(t, s.phase, s.end);
      }
      await _tool(t, _L.wrench);
      await _tapClamp(t, s.phase, s.end);
      await _holdTight(t, 3000);
      expect(find.text(_M.overTight.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _holdTight(t, 1900);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_label(_L.shutdown), findsOneWidget, reason: 'tight: the tools are back');
      expect(c.read(gameSaveProvider).mistakes.single.key, _M.overTight.key);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final deal = m4JumperTightDeal(math.Random(2));
      final c = await _open(t, 2);
      final (p, e) = _goodClamp(deal.sites[0]);
      for (var i = 0; i < 3; i++) {
        await _tapClamp(t, p, e);
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

    testWidgets('a tool on the live jumper: the scene freezes first, then the card (near-miss)', (t) async {
      final deal = m4JumperTightDeal(math.Random(2));
      final s = deal.sites[0];
      final c = await _open(t, 2);
      await _tapClamp(t, s.phase, s.end);
      await _tool(t, _L.wrench);
      await _tapClamp(t, s.phase, s.end);
      await _pump(t, 500);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final sv = c.read(gameSaveProvider);
      expect(sv.mistakes.single.key, _M.workLive.key);
      expect(sv.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('listening to him = deadly: freeze, then the card', (t) async {
      final deal = m4JumperTightDeal(math.Random(11));
      final c = await _open(t, 11);
      for (var i = 0; i < deal.callAt; i++) {
        await _playRight(t, deal, i);
      }
      final s = deal.sites[deal.callAt];
      await _tapClamp(t, s.phase, s.end);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 8000), isTrue);
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
  });
}
