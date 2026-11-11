// Lesson 4.7 (ডিপি স্ট্রাকচার ড্রেসিং), কাজ 2 "পরিচ্ছন্নতার শিল্প": the rules
// (permit → test → earth both sides → harness → climb; climbing unearthed =
// deadly; dress top-down, tidy places left alone, the right fix per place;
// line clear in reverse), the deal, the libraries, and the level in the
// shell: idle perf, the guide first, a full clean play with the coworker
// refused, a slip card that keeps the round, three slips, the deadly freeze
// (climbing without earth; listening to him).
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
import 'package:slm_flutter/features/game/m4_dp_dress.dart';
import 'package:slm_flutter/features/game/m4_dp_dress_world.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';

const _ctx = LevelContext(
  rungId: '4.7/do/1',
  kind: CatalogRungKind.doKind,
  lessonId: '4.7',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 2,
  doCount: 2,
);

final _pack = m4DpDressPacks['do_4_7_b']!;

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
M4DpDressGeo get _geo => M4DpDressGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M4DpDressPage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
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

Future<void> _reason(WidgetTester t, List<String> right) async {
  expect(find.text(MistakeLines.slipHead), findsNothing);
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
  await _pump(t, 700);
  await _pickRight(t, right);
  await _pump(t, 6000);
}

/// Round ক, right: permit, tester, both earths, harness, climb; the reason.
Future<void> _prep(WidgetTester t) async {
  await _tool(t, M4DpDressLines.permit);
  await _tool(t, M4DpDressLines.tester);
  expect(find.text(M4DpDressLines.testerDead), findsOneWidget);
  await _tapAt(t, _geo.earthHit(true).center);
  await _tapAt(t, _geo.earthHit(false).center);
  await _tool(t, M4DpDressLines.harness);
  await _tool(t, M4DpDressLines.climb);
  await _pump(t, 1000);
  await _reason(t, M4DpDressLines.prepWhy);
}

List<M4DpDressSlot> _order(M4DpDressDeal d) => d.untidy.toList()..sort((a, b) => a.index - b.index);

/// Fixes place [s] right.
Future<void> _fix(WidgetTester t, M4DpDressSlot s) async {
  await _tapAt(t, _geo.slotHit(s).center);
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: '$s deck');
  await _pump(t, 700);
  await _pickRight(t, M4DpDressLines.fixRight[s]!);
  await _pump(t, 1200);
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: '$s');
}

/// Round খ, right (the coworker refused); the reason.
Future<void> _dress(WidgetTester t, M4DpDressDeal d) async {
  final order = _order(d);
  for (final (i, s) in order.indexed) {
    await _fix(t, s);
    if (i + 1 == d.callAfter) {
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes');
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await _pickRight(t, M4DpDressLines.coworker.right);
      await _pump(t, 2600);
    }
  }
  await _reason(t, M4DpDressLines.dressWhy[d.dressWhy]!);
}

/// Round গ, right: down, look, both earths off, line clear; the reason.
Future<void> _clear(WidgetTester t) async {
  await _tool(t, M4DpDressLines.down);
  await _tool(t, M4DpDressLines.look);
  await _tapAt(t, _geo.earthHit(true).center);
  await _tapAt(t, _geo.earthHit(false).center);
  await _tool(t, M4DpDressLines.lineClear);
  await _pump(t, 1000);
  await _reason(t, M4DpDressLines.clearWhy);
}

const _deal1 = M4DpDressDeal(
  untidy: {M4DpDressSlot.tangle, M4DpDressSlot.tail, M4DpDressSlot.tilt, M4DpDressSlot.ltCable},
  callAfter: 1,
  dressWhy: M4DpDressSlot.tail,
);

M4DpDressRun _upPole() {
  final r = M4DpDressRun(_deal1)
    ..use(M4DpDressTool.permit)
    ..use(M4DpDressTool.tester)
    ..tapEarth(true)
    ..tapEarth(false)
    ..use(M4DpDressTool.harness)
    ..use(M4DpDressTool.climb);
  return r..next();
}

void main() {
  group('rules', () {
    test('deals: four untidy places (≥1 LT, ≥2 HT); he comes after 1–2 fixes; the reason asks about a dealt place; plays differ', () {
      final seen = <String>{};
      for (var s = 0; s < 80; s++) {
        final d = m4DpDressDeal(math.Random(s));
        expect(d.untidy, hasLength(4));
        expect(d.untidy.intersection(m4DpDressLt), isNotEmpty);
        expect(d.untidy.difference(m4DpDressLt).length, greaterThanOrEqualTo(2));
        expect(d.callAfter, inInclusiveRange(1, 2));
        expect(d.untidy, contains(d.dressWhy));
        seen.add('${_order(d).map((x) => x.name).join(',')}|${d.callAfter}|${d.dressWhy.name}');
      }
      expect(seen.length, greaterThan(20));
    });

    test('শাটডাউন: permit → test → earth; climbing without both earths is deadly', () {
      final a = M4DpDressRun(_deal1);
      expect(a.use(M4DpDressTool.tester), M4DpDressMistakes.permitFirst);
      expect(a.tapEarth(true), M4DpDressMistakes.permitFirst);
      a.use(M4DpDressTool.permit);
      expect(a.tapEarth(true), M4DpDressMistakes.testFirst);
      expect(a.earthL, isFalse);
      expect(a.use(M4DpDressTool.tester), isNull);
      expect(a.tapEarth(true), isNull);
      expect(a.earthL, isTrue);
      expect(a.slips, 3);
      final m = a.use(M4DpDressTool.climb);
      expect(m, M4DpDressMistakes.noEarth, reason: 'one side only');
      expect(m!.deadly, isTrue);
      expect(a.ended, isTrue);
      final b = M4DpDressRun(_deal1);
      expect(b.use(M4DpDressTool.climb), M4DpDressMistakes.noEarth, reason: 'nothing done');
    });

    test('শাটডাউন: no harness = a slip; with it he climbs and the round is done', () {
      final r = M4DpDressRun(_deal1)
        ..use(M4DpDressTool.permit)
        ..use(M4DpDressTool.tester)
        ..tapEarth(true)
        ..tapEarth(false);
      expect(r.use(M4DpDressTool.climb), M4DpDressMistakes.noHarness);
      expect(r.aloft, isFalse);
      r.use(M4DpDressTool.harness);
      expect(r.use(M4DpDressTool.climb), isNull);
      expect(r.aloft, isTrue);
      expect(r.roundDone, isTrue);
      expect(r.thorough, isFalse);
      expect(r.caught, contains(M4DpDressLines.caughtEarth));
    });

    test('ড্রেসিং: a tidy place is a slip; LT before HT is a slip; a wrong fix is a slip (its place); right fixes finish', () {
      final r = _upPole();
      expect(r.round, M4DpDressRound.dress);
      expect(r.tapSlot(M4DpDressSlot.clearance), M4DpDressMistakes.needless);
      expect(r.tapSlot(M4DpDressSlot.ltCable), M4DpDressMistakes.topDown);
      expect(r.picking, isNull);
      expect(r.tapSlot(M4DpDressSlot.tail), isNull);
      expect(r.picking, M4DpDressSlot.tail);
      expect(r.pickFix(false), M4DpDressMistakes.wrongTail);
      expect(r.picking, M4DpDressSlot.tail, reason: 'still on it');
      expect(r.pickFix(true), isNull);
      for (final s in [M4DpDressSlot.tangle, M4DpDressSlot.tilt, M4DpDressSlot.ltCable]) {
        expect(r.tapSlot(s), isNull, reason: '$s');
        expect(r.pickFix(true), isNull);
      }
      expect(r.untidy, isEmpty);
      expect(r.roundDone, isTrue);
      expect(r.slips, 3);
      expect(r.caught, isNot(contains(M4DpDressLines.caughtTop)));
      expect(r.caught, isNot(contains(M4DpDressLines.caughtFix)));
    });

    test('লাইন ক্লিয়ার: earth off / look while aloft are slips; the line clear waits for down, look and both earths off', () {
      final r = _upPole();
      for (final s in _order(_deal1)) {
        r.tapSlot(s);
        r.pickFix(true);
      }
      expect(r.caught, containsAll([M4DpDressLines.caughtTop, M4DpDressLines.caughtFix]));
      r.next();
      expect(r.round, M4DpDressRound.clear);
      expect(r.tapEarth(true), M4DpDressMistakes.earthEarly);
      expect(r.earthL, isTrue);
      expect(r.use(M4DpDressTool.look), M4DpDressMistakes.lookAloft);
      expect(r.use(M4DpDressTool.lineClear), M4DpDressMistakes.clearEarly);
      r.use(M4DpDressTool.down);
      expect(r.aloft, isFalse);
      expect(r.use(M4DpDressTool.look), isNull);
      r.tapEarth(true);
      expect(r.use(M4DpDressTool.lineClear), M4DpDressMistakes.clearEarly, reason: 'one earth still on');
      r.tapEarth(false);
      expect(r.use(M4DpDressTool.lineClear), isNull);
      expect(r.roundDone, isTrue);
      r.next();
      expect(r.done, isTrue);
      expect(r.passed, isFalse, reason: '4 slips = 40 %');
    });

    test('English digits only; every mistake has its picture; one deadly; keys unique', () {
      final all = <String>[
        M4DpDressLines.intro,
        ...M4DpDressLines.tasks,
        ...M4DpDressLines.allWhyRight,
        ...M4DpDressLines.myths,
        ...M4DpDressLines.allFixRight,
        ...M4DpDressLines.fixWrong,
        ...M4DpDressLines.coworker.recordedLines,
        ...M4DpDressLines.coworker.right,
        ...M4DpDressLines.coworker.wrong,
        ...M4DpDressLines.coworker.asks,
        for (final m in M4DpDressMistakes.all) m.textBn,
        M4DpDressLines.allSet,
        M4DpDressLines.fail,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
      expect(M4DpDressMistakes.all.where((m) => m.deadly), [M4DpDressMistakes.noEarth]);
      expect(M4DpDressMistakes.all.map((m) => m.key).toSet(), hasLength(M4DpDressMistakes.all.length));
      for (final m in M4DpDressMistakes.all) {
        expect(m.key, startsWith('4.7/m4_dp_dress/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 2));
      }
      expect(m4DpDressPacks.keys, ['do_4_7_b']);
    });

    test('libraries: same length, big enough, never a rule marked wrong; his exit is recorded', () {
      expectSameLength('why', [...M4DpDressLines.allWhyRight, ...M4DpDressLines.myths]);
      expect(M4DpDressLines.myths.toSet().intersection(M4DpDressLines.allWhyRight.toSet()), isEmpty);
      for (final r in M4DpDressRound.values) {
        for (final s in M4DpDressSlot.values) {
          final right = M4DpDressLines.whyRight(r, s);
          expectLibrary('$r $s', right, M4DpDressLines.myths);
          expect(M4DpDressLines.whyQuestion(r, s), isNotEmpty);
          for (var k = 0; k < 10; k++) {
            final deal = dealChoices(right, M4DpDressLines.myths, math.Random(k));
            expect(deal.where((o) => o.correct), hasLength(1));
            expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
          }
        }
      }
      expectSameLength('fix', [...M4DpDressLines.allFixRight, ...M4DpDressLines.fixWrong]);
      expect(M4DpDressLines.fixWrong.toSet().intersection(M4DpDressLines.allFixRight.toSet()), isEmpty);
      for (final s in M4DpDressSlot.values) {
        expectLibrary('fix $s', M4DpDressLines.fixRight[s]!, M4DpDressLines.fixWrong);
      }
      final cw = M4DpDressLines.coworker;
      expectSameLength('choice', [...cw.right, ...cw.wrong]);
      expectLibrary('choice', cw.right, cw.wrong);
      expect(LearnVoice.resolve(cw.exitLine, rival: true), isNotNull);
    });

    test('tap areas do not overlap and stay on the 360-wide scene', () {
      for (final h in [560.0, 700.0, 780.0, 900.0]) {
        final g = M4DpDressGeo.forScene(h, 0);
        final rects = [for (final s in M4DpDressSlot.values) g.slotHit(s), g.earthHit(true), g.earthHit(false)];
        for (final r in rects) {
          expect(r.left, greaterThanOrEqualTo(0));
          expect(r.right, lessThanOrEqualTo(360));
          expect(r.top, greaterThan(120), reason: 'below the header');
          expect(r.bottom, lessThan(g.groundY), reason: 'above the tool row');
        }
        for (var i = 0; i < rects.length; i++) {
          for (var j = i + 1; j < rects.length; j++) {
            expect(rects[i].intersect(rects[j]).width <= 0 || rects[i].intersect(rects[j]).height <= 0, isTrue, reason: 'h $h: $i/$j');
          }
        }
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
        await t.pumpWidget(ProviderScope(child: MaterialApp(home: M4DpDressPage(ctx: _ctx, pack: _pack, muted: true, seed: 4))));
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
        debugPrint('PERF m4_dp_dress ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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

    testWidgets('the guide comes first: a tap does not skip him; then the tools', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M4DpDressPage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(_label(M4DpDressLines.permit), findsNothing);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_label(M4DpDressLines.permit), findsOneWidget);
      expect(_label(M4DpDressLines.climb), findsOneWidget);
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
      expect(lines.every((l) => l.contains(M4DpDressLines.askPrep)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    for (final seed in [7, 12]) {
      testWidgets('flow (seed $seed): shutdown, dress top-down, refuse him, line clear; right reasons → pass', (t) async {
        final deal = m4DpDressDeal(math.Random(seed));
        final c = await _open(t, seed);
        await _prep(t);
        await _dress(t, deal);
        await _clear(t);
        await _pump(t, 2000);
        final s = c.read(gameSaveProvider);
        expect(s.rungProgress['4.7/do/1'], 'cleared');
        expect(s.mistakes, isEmpty);
        expect(s.starsByRung['4.7/do/1'], greaterThan(0));
        expect(find.byType(LevelPassPanel), findsOneWidget);
        expect(find.text(M4DpDressLines.caughtCall), findsOneWidget);
        expect(find.text(M4DpDressLines.caughtTop), findsOneWidget);
        expect(t.takeException(), isNull);
        await _close(t, c);
      });
    }

    testWidgets('a slip (tester before the permit) shows its card; the same round goes on after it', (t) async {
      final c = await _open(t, 2);
      await _tool(t, M4DpDressLines.tester);
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(M4DpDressMistakes.permitFirst.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_label(M4DpDressLines.permit), findsOneWidget, reason: 'the same round');
      expect(c.read(gameSaveProvider).mistakes.single.key, M4DpDressMistakes.permitFirst.key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a wrong fix is a slip; the deck stays for the right one', (t) async {
      final deal = m4DpDressDeal(math.Random(9));
      final c = await _open(t, 9);
      await _prep(t);
      final s = _order(deal).first;
      await _tapAt(t, _geo.slotHit(s).center);
      expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
      await _pump(t, 700);
      final wrong = _onScreen(M4DpDressLines.fixWrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await _pump(t, 800);
      expect(find.text(M4DpDressMistakes.wrongFix(s).textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      await _pickRight(t, M4DpDressLines.fixRight[s]!);
      await _pump(t, 1200);
      expect(find.text(MistakeLines.slipHead), findsNothing);
      expect(c.read(gameSaveProvider).mistakes.single.key, M4DpDressMistakes.wrongFix(s).key);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final c = await _open(t, 2);
      for (var i = 0; i < 3; i++) {
        await _tool(t, M4DpDressLines.tester);
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

    testWidgets('climbing without the earths: the scene freezes first, then the card (near-miss)', (t) async {
      final c = await _open(t, 2);
      await _tool(t, M4DpDressLines.climb);
      await _pump(t, 500);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, M4DpDressMistakes.noEarth.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('listening to him = deadly: freeze, then the card', (t) async {
      final deal = m4DpDressDeal(math.Random(11));
      final c = await _open(t, 11);
      await _prep(t);
      final order = _order(deal);
      for (var i = 0; i < deal.callAfter; i++) {
        await _fix(t, order[i]);
      }
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      final wrong = _onScreen(M4DpDressLines.coworker.wrong);
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
