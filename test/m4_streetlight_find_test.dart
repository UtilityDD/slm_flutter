// Lesson 4.9 (রাস্তার আলো মেরামত), কাজ 1 "অন্ধকার রাস্তা — দোষ কোথায়?":
// the rules (step 1 the supply at the terminals; 0 V = supply/fuse; then the
// lamp, then the ballast — matched to the lamp; hands in the fitting only
// with the MCB OFF and proven dead; live = deadly), the deal, the reason
// libraries, and the level in the shell: idle perf, the guide first, a full
// clean play with the coworker refused, a slip card that keeps the light, the
// deadly freeze (a lamp into a live fitting; listening to him).
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
import 'package:slm_flutter/features/game/m4_streetlight_find.dart';
import 'package:slm_flutter/features/game/m4_streetlight_find_world.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';

typedef _L = M4StreetlightFindLines;
typedef _M = M4StreetlightFindMistakes;
typedef _F = M4StreetlightFindFault;
typedef _T = M4StreetlightFindTool;

const _ctx = LevelContext(
  rungId: '4.9/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '4.9',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

final _pack = m4StreetlightFindPacks['do_4_9_a']!;

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
M4StreetlightFindGeo get _geo => M4StreetlightFindGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M4StreetlightFindPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

/// Step 1: the meter on the terminals with the MCB ON; read it right.
Future<void> _measure(WidgetTester t, {required bool live}) async {
  await _tool(t, _L.meter);
  await _tapAt(t, _geo.terminalBlock.center);
  expect(find.text(_L.sayLive), findsOneWidget);
  expect(_label(live ? '230 V' : '0 V'), findsOneWidget);
  await t.tap(find.text(live ? _L.sayLive : _L.sayDead));
  await _pump(t, 600);
}

/// MCB OFF and the meter proves the fitting dead.
Future<void> _isolate(WidgetTester t) async {
  await _tapAt(t, _geo.mcbHandle);
  await _tool(t, _L.meter);
  await _tapAt(t, _geo.terminalBlock.center);
  expect(_label('0 V'), findsOneWidget);
}

/// Plays light [i] right (the coworker refused on his light).
Future<void> _playRight(WidgetTester t, M4StreetlightFindDeal deal, int i) async {
  final p = deal.posts[i];
  await _measure(t, live: p.fault != _F.noSupply);
  if (p.fault != _F.noSupply) {
    if (i == deal.callAt) {
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes on light $i');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await _pickRight(t, _L.coworker.right);
      await _pump(t, 2600);
    }
    await _isolate(t);
    await _tool(t, _L.newLamp);
    await _tapAt(t, _geo.lamp.center);
    await _tapAt(t, _geo.mcbHandle); // ON
    if (p.fault == _F.gear) {
      await _pump(t, 600);
      await _isolate(t);
      await _tool(t, _L.ballast);
      await _tapAt(t, _geo.gear.center);
      await t.tap(find.text(_L.gearPick(p.lamp)));
      await _pump(t, 400);
      await _tapAt(t, _geo.mcbHandle); // ON
    }
  }
  await _pump(t, 1500);
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'light $i');
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: 'reason deck on light $i');
  await _pump(t, 700);
  await _pickRight(t, _L.whyRight(p));
  await _pump(t, 6000);
}

M4StreetlightFindRun _run1(_F f, {M4StreetlightFindLamp lamp = M4StreetlightFindLamp.hpsv70}) => M4StreetlightFindRun(M4StreetlightFindDeal(
      posts: [M4StreetlightFindPost(id: 'x', fault: f, lamp: lamp, pole: 12, why: M4StreetlightFindWhy.lamp)],
      callAt: 0,
    ));

/// Step 1 read right.
void _read(M4StreetlightFindRun r) {
  r.hold(_T.meter);
  expect(r.tapTerminals(), M4StreetlightFindProbe.reading);
  expect(r.answer(r.supply), isNull);
}

/// MCB OFF, proven dead.
void _off(M4StreetlightFindRun r) {
  expect(r.toggleMcb(), isTrue);
  expect(r.mcbOn, isFalse);
  if (r.tool != _T.meter) r.hold(_T.meter);
  expect(r.tapTerminals(), M4StreetlightFindProbe.dead);
  expect(r.proved, isTrue);
}

void main() {
  group('rules', () {
    test('deals: one of each fault; he comes to a light with supply; one repair asks "why off first"; plays differ', () {
      final seen = <String>{};
      for (var s = 0; s < 80; s++) {
        final d = m4StreetlightFindDeal(math.Random(s));
        expect(d.posts, hasLength(3));
        expect(d.posts.map((p) => p.fault).toSet(), _F.values.toSet());
        expect(d.posts[d.callAt].fault, isNot(_F.noSupply));
        expect(d.posts.where((p) => p.why == M4StreetlightFindWhy.isolate), hasLength(1));
        for (final p in d.posts) {
          expect(p.why == M4StreetlightFindWhy.supply, p.fault == _F.noSupply);
        }
        seen.add(d.posts.map((p) => '${p.fault.name}${p.lamp.name}${p.why.name}${p.matchFirst}').join('|') + d.callAt.toString());
      }
      expect(seen.length, greaterThan(40));
    });

    test('step 1: the meter reads 230 V or 0 V with the MCB ON; a misread is a slip; 0 V = supply or fuse, done', () {
      final a = _run1(_F.lamp)..hold(_T.meter);
      expect(a.tapTerminals(), M4StreetlightFindProbe.reading);
      expect(a.volts, 230);
      expect(a.answer(false), _M.misread);
      expect(a.readingUp, isTrue, reason: 'still to read');
      expect(a.answer(true), isNull);
      expect(a.measured, isTrue);
      expect(a.finished, isFalse);
      final b = _run1(_F.noSupply)..hold(_T.meter);
      b.tapTerminals();
      expect(b.volts, 0);
      expect(b.answer(true), _M.misread);
      expect(b.answer(false), isNull);
      expect(b.diagnosed, isTrue);
      expect(b.finished, isTrue);
      expect(b.caught, containsAll([_L.caughtMeasure, _L.caughtSupply]));
    });

    test('a lamp or a ballast into the fitting with the MCB ON is deadly (also before any reading)', () {
      for (final (f, tool) in [(_F.lamp, _T.lamp), (_F.gear, _T.gear), (_F.noSupply, _T.lamp)]) {
        final r = _run1(f)..hold(tool);
        final m = tool == _T.lamp ? r.tapLamp() : r.tapGear();
        expect(m, _M.liveWork);
        expect(m!.deadly, isTrue);
        expect(r.ended, isTrue);
      }
    });

    test('OFF but not proven dead, or no step-1 test yet: slips; a dead lamp → new lamp → ON lights it', () {
      final r = _run1(_F.lamp);
      expect(r.toggleMcb(), isTrue);
      r.hold(_T.lamp);
      expect(r.tapLamp(), _M.noProve);
      r.hold(_T.meter);
      expect(r.tapTerminals(), M4StreetlightFindProbe.dead);
      r.hold(_T.lamp);
      expect(r.tapLamp(), _M.noMeasure, reason: 'step 1 first');
      expect(r.relamped, isFalse);
      expect(r.slips, 2);
      final ok = _run1(_F.lamp);
      _read(ok);
      _off(ok);
      ok.hold(_T.lamp);
      expect(ok.tapLamp(), isNull);
      expect(ok.relamped, isTrue);
      expect(ok.toggleMcb(), isTrue);
      expect(ok.proved, isFalse, reason: 'ON again: live again');
      expect(ok.lit, isTrue);
      expect(ok.finished, isTrue);
      expect(ok.slips, 0);
      expect(ok.caught, containsAll([_L.caughtMeasure, _L.caughtIsolate, _L.caughtLamp]));
    });

    test('a dead ballast: lamp first (gear before = slip), still dark, then the matching ballast (wrong = slip)', () {
      final r = _run1(_F.gear, lamp: M4StreetlightFindLamp.mh150);
      _read(r);
      _off(r);
      r.hold(_T.gear);
      expect(r.tapGear(), _M.gearFirst);
      r.hold(_T.lamp);
      expect(r.tapLamp(), isNull);
      r.hold(_T.gear);
      expect(r.tapGear(), _M.gearFirst, reason: 'the new lamp not tried yet');
      r.toggleMcb();
      expect(r.lit, isFalse);
      expect(r.stillDark, isTrue);
      _off(r);
      r.hold(_T.gear);
      expect(r.tapGear(), isNull);
      expect(r.choosingGear, isTrue);
      expect(r.toggleMcb(), isFalse, reason: 'the fitting is open');
      expect(r.pickGear(false), _M.wrongBallast);
      expect(r.pickGear(true), isNull);
      expect(r.gearDone, isTrue);
      r.toggleMcb();
      expect(r.lit, isTrue);
      expect(r.slips, 3);
      expect(r.caught, contains(_L.caughtGear));
    });

    test('a new lamp does not light a light with no supply', () {
      final r = _run1(_F.noSupply);
      r.toggleMcb();
      r.hold(_T.meter);
      r.tapTerminals();
      r.hold(_T.lamp);
      expect(r.tapLamp(), _M.noMeasure);
    });

    test('English digits only; every mistake has its picture and its own key; one deadly', () {
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
        _L.supplyFound,
        _L.docketLine(23),
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
      expect(_M.all.where((m) => m.deadly), [_M.liveWork]);
      expect(_M.all.map((m) => m.key).toSet(), hasLength(_M.all.length));
      for (final m in _M.all) {
        expect(m.key, startsWith('4.9/m4_streetlight_find/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 2));
      }
      expect(m4StreetlightFindPacks.keys, ['do_4_9_a']);
    });

    test('reasons: same length, big enough, never a rule marked wrong; his exit is recorded', () {
      expectSameLength('why', [..._L.allRight, ..._L.myths]);
      expect(_L.myths.toSet().intersection(_L.allRight.toSet()), isEmpty);
      for (final w in M4StreetlightFindWhy.values) {
        final p = M4StreetlightFindPost(id: 'x', fault: _F.lamp, lamp: M4StreetlightFindLamp.hpsv70, pole: 1, why: w);
        final right = _L.whyRight(p);
        expectLibrary('$w', right, _L.myths);
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
        await t.pumpWidget(ProviderScope(child: MaterialApp(home: M4StreetlightFindPage(ctx: _ctx, pack: _pack, muted: true, seed: 4))));
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
        debugPrint('PERF m4_streetlight_find ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M4StreetlightFindPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(_label(_L.meter), findsNothing);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_label(_L.meter), findsOneWidget);
      expect(find.text(_L.docketLine(m4StreetlightFindDeal(math.Random(3)).posts[0].pole)), findsOneWidget);
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

    testWidgets('flow: measure, isolate, lamp, ballast; refuse him; right reasons → pass', (t) async {
      final deal = m4StreetlightFindDeal(math.Random(7));
      final c = await _open(t, 7);
      for (var i = 0; i < 3; i++) {
        await _playRight(t, deal, i);
      }
      await _pump(t, 2000);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['4.9/do/0'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['4.9/do/0'], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(_L.caughtCall), findsOneWidget);
      expect(find.text(_L.caughtGear), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a slip (new lamp before the supply test) shows its card; the same light goes on after it', (t) async {
      final c = await _open(t, 2);
      await _isolate(t);
      await _tool(t, _L.newLamp);
      await _tapAt(t, _geo.lamp.center);
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(_M.noMeasure.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_label(_L.meter), findsOneWidget, reason: 'the same light');
      expect(c.read(gameSaveProvider).mistakes.single.key, _M.noMeasure.key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final c = await _open(t, 2);
      await _tapAt(t, _geo.mcbHandle); // OFF, not proven
      await _tool(t, _L.newLamp);
      for (var i = 0; i < 3; i++) {
        await _tapAt(t, _geo.lamp.center);
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

    testWidgets('a new lamp into a live fitting: the scene freezes first, then the card (near-miss)', (t) async {
      final c = await _open(t, 2);
      await _tool(t, _L.newLamp);
      await _tapAt(t, _geo.lamp.center);
      await _pump(t, 500);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, _M.liveWork.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('listening to him = deadly: freeze, then the card', (t) async {
      final deal = m4StreetlightFindDeal(math.Random(11));
      final c = await _open(t, 11);
      for (var i = 0; i < deal.callAt; i++) {
        await _playRight(t, deal, i);
      }
      await _measure(t, live: true);
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

    testWidgets('switching the MCB OFF while he talks refuses him', (t) async {
      final deal = m4StreetlightFindDeal(math.Random(11));
      final c = await _open(t, 11);
      for (var i = 0; i < deal.callAt; i++) {
        await _playRight(t, deal, i);
      }
      await _measure(t, live: true);
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 300);
      await _tapAt(t, _geo.mcbHandle);
      await _pump(t, 1500);
      expect(find.byType(CoworkerPeek), findsNothing);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });
  });
}
