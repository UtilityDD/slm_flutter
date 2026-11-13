// Lesson 3.10 (লাইন ডায়াগ্রাম পড়া), কাজ "ম্যাপ দেখে বিচ্ছিন্ন": the rules
// (breaker before isolator — an isolator on load is deadly; the docket's
// feeder, not its neighbour; not the DO fuse; on a ring the NO point tagged,
// and when it is closed today the other feeder's breaker and the tie opened
// too; then tester, earth, work — work on a live section is deadly), the deal,
// the reason libraries, and the level in the shell: idle perf, the guide first,
// a full clean play with the coworker refused, a slip card that keeps the
// docket, three slips, the deadly freeze (isolator on load), listening to him
// (a slip), he comes even on a fast play (the tie waits for him), no work
// with a point on the map still closed, and the gesture hint (a sweep).
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
import 'package:slm_flutter/features/game/learn_voice.dart';
import 'package:slm_flutter/features/game/level_frame.dart';
import 'package:slm_flutter/features/game/level_juice.dart';
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m3_sld_isolate.dart';
import 'package:slm_flutter/features/game/m3_sld_isolate_world.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';
import 'support/reason_proceed.dart';

const _ctx = LevelContext(
  rungId: '3.10/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '3.10',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 1,
);

final _pack = m3SldIsolatePacks['do_3_10_a']!;

typedef _P = M3SldIsolatePoint;
typedef _K = M3SldIsolateKind;

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
  await waitChoiceDeck(t);
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final r = _onScreen(right);
  expect(r, hasLength(1), reason: right.first);
  await t.tap(r.single, warnIfMissed: false);
  await tapReasonProceed(t);
}

/// Design px → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
M3SldIsolateGeo _geo(M3SldIsolateDocket d) =>
    M3SldIsolateGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0, flip: d.flip, workLeft: d.workLeft);

Future<void> _tapPoint(WidgetTester t, M3SldIsolateDocket d, M3SldIsolatePoint p) async {
  await t.tapAt(_geo(d).point(p) * _k);
  await _pump(t, 300);
}

Future<void> _tool(WidgetTester t, String label) async {
  await t.tap(_label(label));
  await _pump(t, 300);
}

Future<ProviderContainer> _open(WidgetTester t, int seed, {int settleMs = 1200}) async {
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
    builder: (_) => DefaultAssetBundle(bundle: _DiskBundle(), child: M3SldIsolatePage(ctx: _ctx, pack: _pack, muted: true, seed: seed)),
  )));
  await _pump(t, 1000);
  await waitIntro(t);
  await _pump(t, settleMs);
  return c;
}

Future<void> _close(WidgetTester t, ProviderContainer c) async {
  await t.pumpWidget(const SizedBox());
  await t.pump(const Duration(seconds: 15));
  MascotTalk.reset();
  c.dispose();
  t.view.reset();
}

/// Waits for him on his docket and refuses him on the cards.
Future<void> _refuse(WidgetTester t) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 600);
  await _pickRight(t, M3SldIsolateLines.coworker.right);
  await _pump(t, 2600);
}

/// Plays docket [i] right (the coworker refused on his docket).
Future<void> _playRight(WidgetTester t, M3SldIsolateDeal deal, int i) async {
  final d = deal.dockets[i];
  if (i == deal.callAt) await _refuse(t);
  await _tapPoint(t, d, _P.cbA);
  await _tapPoint(t, d, _P.abA);
  if (d.kind == _K.ringNo) await _tapPoint(t, d, _P.tie);
  if (d.kind == _K.ringClosed) {
    await _tapPoint(t, d, _P.cbB);
    await _tapPoint(t, d, _P.tie);
  }
  await _tool(t, M3SldIsolateLines.tester);
  expect(find.text(M3SldIsolateLines.testerDead), findsOneWidget, reason: 'docket $i dead');
  await _tool(t, M3SldIsolateLines.earth);
  await _tool(t, M3SldIsolateLines.work);
  await _pump(t, 2200);
  expect(find.text(MistakeLines.slipHead), findsNothing, reason: 'docket $i');
  await _pumpUntil(t, find.byType(ChoiceDeck));
  await _pump(t, 700);
  await _pickRight(t, M3SldIsolateLines.whyRight(d));
  await _pump(t, 6000);
}

void main() {
  group('rules', () {
    test('deals: one docket of each kind; he comes to the ring closed today; plays differ', () {
      final seen = <String>{};
      for (var s = 0; s < 80; s++) {
        final d = m3SldIsolateDeal(math.Random(s));
        expect(d.dockets, hasLength(3));
        expect(d.dockets.map((x) => x.kind).toSet(), M3SldIsolateKind.values.toSet());
        expect(d.dockets[d.callAt].kind, _K.ringClosed);
        for (final x in d.dockets) {
          expect({x.feederA, x.feederX, x.feederB}, hasLength(3));
          expect(x.why == M3SldIsolateWhy.tag, x.kind == _K.ringNo);
          expect(x.why == M3SldIsolateWhy.both, x.kind == _K.ringClosed);
        }
        seen.add(d.dockets.map((x) => '${x.kind.name}${x.flip}${x.workLeft}${x.feederA}${x.why.name}').join('|'));
      }
      expect(seen.length, greaterThan(60));
    });

    M3SldIsolateRun run1(M3SldIsolateKind k) => M3SldIsolateRun(M3SldIsolateDeal(dockets: [
          M3SldIsolateDocket(
            id: 'x',
            kind: k,
            why: M3SldIsolateWhy.order,
            flip: false,
            workLeft: true,
            feederA: 'ক',
            feederX: 'খ',
            feederB: 'গ',
            firstPole: 7,
          ),
        ], callAt: 0));

    test('an isolator before its breaker is deadly (on load); breaker first is fine', () {
      final r = run1(_K.radial);
      final m = r.tap(_P.abA);
      expect(m, M3SldIsolateMistakes.abOnLoad);
      expect(m!.deadly, isTrue);
      expect(r.ended, isTrue);
      final ok = run1(_K.radial);
      expect(ok.tap(_P.cbA), isNull);
      expect(ok.tap(_P.abA), isNull);
      expect(ok.live, isFalse);
      expect(ok.caught, containsAll([M3SldIsolateLines.caughtFeeder, M3SldIsolateLines.caughtOrder]));
    });

    test('the wrong feeder and the DO fuse are slips and change nothing', () {
      final r = run1(_K.radial);
      expect(r.tap(_P.cbX), M3SldIsolateMistakes.wrongFeeder);
      expect(r.tap(_P.doFuse), M3SldIsolateMistakes.doFuse);
      expect(r.opened, isEmpty);
      expect(r.live, isTrue);
      expect(r.slips, 2);
      expect(r.tap(_P.tie), isNull, reason: 'no tie on a radial map');
      expect(r.tap(_P.cbB), isNull);
      expect(r.opened, isEmpty);
    });

    test('ring closed today: one side open is still live (backfeed) — tester slip, work deadly', () {
      final r = run1(_K.ringClosed)
        ..tap(_P.cbA)
        ..tap(_P.abA);
      expect(r.live, isTrue);
      final (live, m) = r.test();
      expect(live, isTrue);
      expect(m, M3SldIsolateMistakes.backfeedTest);
      expect(r.earth(), M3SldIsolateMistakes.earthUnproven);
      expect(r.start(), M3SldIsolateMistakes.backfeedWork);
      expect(r.deadly, M3SldIsolateMistakes.backfeedWork);
    });

    test('ring closed today: the tie on load is deadly; its breaker first, then the tie', () {
      final a = run1(_K.ringClosed)
        ..tap(_P.cbA)
        ..tap(_P.abA);
      expect(a.tap(_P.tie), M3SldIsolateMistakes.abOnLoad);
      final b = run1(_K.ringClosed)
        ..tap(_P.cbA)
        ..tap(_P.abA);
      expect(b.tap(_P.cbB), isNull);
      expect(b.tap(_P.tie), isNull);
      expect(b.live, isFalse);
      expect(b.isolated, isTrue);
      expect(b.test().$1, isFalse);
      expect(b.earth(), isNull);
      expect(b.start(), isNull);
      expect(b.workOn, isTrue);
      expect(b.slips, 0);
      expect(b.caught, containsAll([M3SldIsolateLines.caughtBackfeed, M3SldIsolateLines.caughtTest, M3SldIsolateLines.caughtEarth]));
    });

    test('a live test before isolating is no slip; work on it is deadly', () {
      final r = run1(_K.radial);
      expect(r.test(), (true, null));
      expect(r.slips, 0);
      expect(r.start(), M3SldIsolateMistakes.liveWork);
      expect(r.ended, isTrue);
    });

    test('dead section: work needs the test, the earth, and on an open ring the NO tag', () {
      final r = run1(_K.ringNo)
        ..tap(_P.cbA)
        ..tap(_P.abA);
      expect(r.live, isFalse, reason: 'the NO point is open');
      expect(r.isolated, isFalse);
      expect(r.start(), M3SldIsolateMistakes.noTest);
      expect(r.earth(), M3SldIsolateMistakes.earthUnproven);
      expect(r.test(), (false, null));
      expect(r.start(), M3SldIsolateMistakes.noEarth);
      expect(r.earth(), isNull);
      expect(r.start(), M3SldIsolateMistakes.noTag);
      expect(r.tap(_P.tie), isNull);
      expect(r.tieTagged, isTrue);
      expect(r.start(), isNull);
      expect(r.workOn, isTrue);
      expect(r.slips, 4);
      expect(r.caught, contains(M3SldIsolateLines.caughtNo));
      r.next();
      expect(r.done, isTrue);
      expect(r.opened, isEmpty);
    });

    test('ring closed today: the other breaker alone kills it, but work waits for the tie (audit)', () {
      final r = run1(_K.ringClosed)
        ..tap(_P.cbA)
        ..tap(_P.abA)
        ..tap(_P.cbB);
      expect(r.live, isFalse);
      expect(r.isolated, isFalse, reason: 'the tie is still closed');
      expect(r.test(), (false, null));
      expect(r.earth(), isNull);
      expect(r.start(), M3SldIsolateMistakes.notIsolated);
      expect(r.workOn, isFalse);
      expect(r.slips, 1);
      expect(r.tap(_P.tie), isNull);
      expect(r.start(), isNull);
      expect(r.workOn, isTrue);
    });

    test('radial: the breaker alone is not isolation — the isolator too', () {
      final r = run1(_K.radial)..tap(_P.cbA);
      expect(r.live, isFalse);
      expect(r.test(), (false, null));
      expect(r.earth(), isNull);
      expect(r.start(), M3SldIsolateMistakes.notIsolated);
      expect(r.tap(_P.abA), isNull);
      expect(r.start(), isNull);
      expect(r.slips, 1);
    });

    test('open ring: the other breaker is not needed — no slip, but no thorough bonus', () {
      final r = run1(_K.ringNo)
        ..tap(_P.cbA)
        ..tap(_P.abA)
        ..tap(_P.tie);
      expect(r.thorough, isTrue);
      expect(r.tap(_P.cbB), isNull);
      expect(r.slips, 0);
      expect(r.thorough, isFalse);
      expect(r.overCut, isTrue);
      r.next();
      expect(r.needless, isFalse);
      expect(r.overCut, isTrue, reason: 'the play keeps it: no quick star');
      // On the ring closed today the other breaker is needed: no cost.
      final b = run1(_K.ringClosed)..tap(_P.cbB);
      expect(b.needless || b.overCut, isFalse);
    });

    test('no word gives the right card away: the key words sit on wrong cards too', () {
      final cw = M3SldIsolateLines.coworker;
      for (final w in ['রিং', 'উল্টো', 'ম্যাপ', 'ব্যাকফিড', 'বিচ্ছিন্ন']) {
        expect(cw.wrong.any((x) => x.contains(w)), isTrue, reason: 'coworker wrong: $w');
      }
      for (final w in ['রিং', 'উল্টো', 'ব্যাকফিড', 'ম্যাপ', 'আইসোলেটর', 'ব্রেকার', 'টেস্টার', 'NO পয়েন্ট']) {
        expect(M3SldIsolateLines.myths.any((x) => x.contains(w)), isTrue, reason: 'myth: $w');
      }
    });

    test('listening to him is a slip (playbook row 8), not a death', () {
      final r = run1(_K.ringClosed);
      expect(r.listened(), M3SldIsolateMistakes.listened);
      expect(M3SldIsolateMistakes.listened.deadly, isFalse);
      expect(r.slips, 1);
      expect(r.ended, isFalse);
    });

    test('English digits only; every mistake has its picture; deadly ones; keys unique', () {
      final all = <String>[
        M3SldIsolateLines.intro,
        ...M3SldIsolateLines.tasks,
        ...M3SldIsolateLines.allRight,
        ...M3SldIsolateLines.myths,
        ...M3SldIsolateLines.coworker.recordedLines,
        ...M3SldIsolateLines.coworker.right,
        ...M3SldIsolateLines.coworker.wrong,
        ...M3SldIsolateLines.coworker.asks,
        for (final m in M3SldIsolateMistakes.all) m.textBn,
        M3SldIsolateLines.allSet,
        M3SldIsolateLines.fail,
        ...M3SldIsolateLines.feeders,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
      expect(M3SldIsolateMistakes.all.where((m) => m.deadly).toSet(),
          {M3SldIsolateMistakes.abOnLoad, M3SldIsolateMistakes.backfeedWork, M3SldIsolateMistakes.liveWork});
      expect(M3SldIsolateMistakes.all.map((m) => m.key).toSet(), hasLength(M3SldIsolateMistakes.all.length));
      for (final m in M3SldIsolateMistakes.all) {
        expect(m.key, startsWith('3.10/m3_sld_isolate/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
        if (m.lessonPoint != null) expect(m.lessonPoint, inInclusiveRange(0, 2));
      }
      expect(m3SldIsolatePacks.keys, ['do_3_10_a']);
    });

    test('reasons: same length, big enough, never a rule marked wrong; his exit is recorded', () {
      expectSameLength('why', [...M3SldIsolateLines.allRight, ...M3SldIsolateLines.myths]);
      for (final w in M3SldIsolateWhy.values) {
        final d = M3SldIsolateDocket(id: 'x', kind: _K.radial, why: w, flip: false, workLeft: true, feederA: 'ক', feederX: 'খ', feederB: 'গ', firstPole: 3);
        final right = M3SldIsolateLines.whyRight(d);
        expectLibrary('$w', right, M3SldIsolateLines.myths);
        expect(M3SldIsolateLines.myths.toSet().intersection(M3SldIsolateLines.allRight.toSet()), isEmpty);
        for (var k = 0; k < 10; k++) {
          final deal = dealChoices(right, M3SldIsolateLines.myths, math.Random(k));
          expect(deal.where((o) => o.correct), hasLength(1));
          expect(deal.map((o) => o.textBn).toSet(), hasLength(3));
        }
      }
      final cw = M3SldIsolateLines.coworker;
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
        // A seed whose first docket is not the coworker's.
        await t.pumpWidget(ProviderScope(child: MaterialApp(home: M3SldIsolatePage(ctx: _ctx, pack: _pack, muted: true, seed: _quietSeed()))));
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
        debugPrint('PERF m3_sld_isolate ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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

    testWidgets('the guide comes first: a tap does not skip him; then the tools', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: MaterialApp(home: M3SldIsolatePage(ctx: _ctx, pack: _pack, muted: true, seed: 3))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      expect(_label(M3SldIsolateLines.tester), findsNothing);
      await waitIntro(t);
      await _pump(t, 1200);
      expect(_label(M3SldIsolateLines.tester), findsOneWidget);
      expect(_label(M3SldIsolateLines.work), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final c = await _open(t, _quietSeed());
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(M3SldIsolateLines.askIsolate)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('flow: read the map, open in order, test, earth, work; refuse him; right reasons → pass', (t) async {
      final deal = m3SldIsolateDeal(math.Random(7));
      final c = await _open(t, 7);
      for (var i = 0; i < 3; i++) {
        await _playRight(t, deal, i);
      }
      await _pump(t, 2000);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['3.10/do/0'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['3.10/do/0'], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(M3SldIsolateLines.caughtCall), findsOneWidget);
      expect(find.text(M3SldIsolateLines.caughtBackfeed), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('a slip (the wrong feeder) shows its card; the same docket goes on after it', (t) async {
      final seed = _quietSeed();
      final d = m3SldIsolateDeal(math.Random(seed)).dockets[0];
      final c = await _open(t, seed);
      await _tapPoint(t, d, _P.cbX);
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(M3SldIsolateMistakes.wrongFeeder.textBn), findsOneWidget);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsNothing);
      expect(_label(M3SldIsolateLines.tester), findsOneWidget, reason: 'the same docket');
      expect(c.read(gameSaveProvider).mistakes.single.key, M3SldIsolateMistakes.wrongFeeder.key);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('three slips strike the level out', (t) async {
      final seed = _quietSeed();
      final d = m3SldIsolateDeal(math.Random(seed)).dockets[0];
      final c = await _open(t, seed);
      for (var i = 0; i < 3; i++) {
        await _tapPoint(t, d, i.isEven ? _P.cbX : _P.doFuse);
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

    testWidgets('an isolator on load: the scene freezes first, then the card (near-miss)', (t) async {
      final seed = _quietSeed();
      final d = m3SldIsolateDeal(math.Random(seed)).dockets[0];
      final c = await _open(t, seed);
      await _tapPoint(t, d, _P.abA);
      await _pump(t, 500);
      expect(find.byType(FreezeFrame), findsOneWidget);
      expect(find.byType(MistakeCard), findsNothing);
      await _pump(t, 3500);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.nearMissHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, M3SldIsolateMistakes.abOnLoad.key);
      expect(s.mistakes.single.deadly, isTrue);
      await _close(t, c);
    });

    testWidgets('listening to him = a slip: its card, no freeze; the docket goes on', (t) async {
      final deal = m3SldIsolateDeal(math.Random(11));
      final c = await _open(t, 11);
      for (var i = 0; i < deal.callAt; i++) {
        await _playRight(t, deal, i);
      }
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 600);
      await waitChoiceDeck(t);
      final wrong = _onScreen(M3SldIsolateLines.coworker.wrong);
      expect(wrong, isNotEmpty);
      await t.tap(wrong.first, warnIfMissed: false);
      await tapReasonProceed(t);
      await _pump(t, 800);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      final s = c.read(gameSaveProvider);
      expect(s.mistakes.single.key, M3SldIsolateMistakes.listened.key);
      expect(s.mistakes.single.deadly, isFalse);
      await t.tap(find.text(MistakeLines.gotIt));
      await _pump(t, 600);
      expect(_label(M3SldIsolateLines.tester), findsOneWidget, reason: 'the same docket goes on');
      expect(find.byType(CoworkerPeek), findsNothing);
      await _close(t, c);
    });

    testWidgets('opening the other feeder’s breaker while he talks refuses him', (t) async {
      final deal = m3SldIsolateDeal(math.Random(11));
      final c = await _open(t, 11);
      for (var i = 0; i < deal.callAt; i++) {
        await _playRight(t, deal, i);
      }
      final d = deal.dockets[deal.callAt];
      expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      await _pump(t, 300);
      await _tapPoint(t, d, _P.cbB);
      await _pump(t, 1500);
      expect(find.byType(CoworkerPeek), findsNothing);
      expect(find.byType(FreezeFrame), findsNothing);
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      await _close(t, c);
    });

    testWidgets('a fast play still meets him: the tie waits for the coworker', (t) async {
      final seed = _coworkerFirstSeed();
      final d = m3SldIsolateDeal(math.Random(seed)).dockets[0];
      final c = await _open(t, seed, settleMs: 0);
      // Faster than his 1.2 s entrance: the other breaker, then the tie.
      await t.tapAt(_geo(d).point(_P.cbB) * _k);
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CoworkerPeek), findsNothing, reason: 'not come yet');
      await t.tapAt(_geo(d).point(_P.tie) * _k);
      await t.pump(const Duration(milliseconds: 100));
      expect(find.byType(CoworkerPeek), findsOneWidget, reason: 'the tie held for him');
      await _pickRight(t, M3SldIsolateLines.coworker.right);
      await _pump(t, 2600);
      expect(find.text(M3SldIsolateLines.caughtCall), findsNothing, reason: 'no result yet');
      expect(c.read(gameSaveProvider).mistakes, isEmpty);
      // After him the tie works as usual.
      await _tapPoint(t, d, _P.cbA);
      await _tapPoint(t, d, _P.abA);
      await _tapPoint(t, d, _P.tie);
      await _tool(t, M3SldIsolateLines.tester);
      expect(find.text(M3SldIsolateLines.testerDead), findsOneWidget);
      await _tool(t, M3SldIsolateLines.earth);
      await _tool(t, M3SldIsolateLines.work);
      await _pumpUntil(t, find.byType(ChoiceDeck));
      expect(find.byType(MistakeCard), findsNothing);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('ring closed today: work with the tie still closed is a slip card (audit fix)', (t) async {
      final deal = m3SldIsolateDeal(math.Random(11));
      final c = await _open(t, 11);
      for (var i = 0; i < deal.callAt; i++) {
        await _playRight(t, deal, i);
      }
      final d = deal.dockets[deal.callAt];
      await _refuse(t);
      await _tapPoint(t, d, _P.cbA);
      await _tapPoint(t, d, _P.abA);
      await _tapPoint(t, d, _P.cbB);
      await _tool(t, M3SldIsolateLines.tester);
      await _tool(t, M3SldIsolateLines.earth);
      await _tool(t, M3SldIsolateLines.work);
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(M3SldIsolateMistakes.notIsolated.textBn), findsOneWidget);
      expect(find.byType(ChoiceDeck), findsNothing, reason: 'the job did not finish');
      expect(c.read(gameSaveProvider).mistakes.single.key, M3SldIsolateMistakes.notIsolated.key);
      await _close(t, c);
    });

    testWidgets('the guide stays neutral: after CB-1 + AB-1 a ring closed today sounds like a radial', (t) async {
      Future<String> guideLine(ProviderContainer c) async {
        final guide = find.byKey(const ValueKey('hud-guide'));
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        return c.read(guideDirectorProvider).line;
      }

      // A radial: CB-1 and AB-1 isolate it, but the guide must not say so.
      final rSeed = _radialFirstSeed();
      final r = m3SldIsolateDeal(math.Random(rSeed)).dockets[0];
      var c = await _open(t, rSeed);
      await _tapPoint(t, r, _P.cbA);
      await _tapPoint(t, r, _P.abA);
      await _pump(t, 2500);
      final radialLine = await guideLine(c);
      expect(radialLine, contains(M3SldIsolateLines.askIsolate), reason: radialLine);
      expect(radialLine, isNot(contains(M3SldIsolateLines.askNext)));
      // Only the dead tester (seen by the player) moves the ask on.
      await _tool(t, M3SldIsolateLines.tester);
      await _pump(t, 2500);
      expect(await guideLine(c), contains(M3SldIsolateLines.askNext));
      await _close(t, c);

      // The ring closed today: same two points, same ask.
      final kSeed = _coworkerFirstSeed();
      final k = m3SldIsolateDeal(math.Random(kSeed)).dockets[0];
      expect(k.kind, _K.ringClosed);
      c = await _open(t, kSeed);
      await _refuse(t);
      await _tapPoint(t, k, _P.cbA);
      await _tapPoint(t, k, _P.abA);
      await _pump(t, 2500);
      final ringLine = await guideLine(c);
      expect(ringLine, contains(M3SldIsolateLines.askIsolate), reason: ringLine);
      expect(ringLine, isNot(contains(M3SldIsolateLines.askNext)));
      await _close(t, c);
    });

    testWidgets('gesture hint: after idle a sweep passes over every switch and tool, pressing none', (t) async {
      GestureHints.debugEnableInTests = true;
      addTearDown(() => GestureHints.debugEnableInTests = false);
      final seed = _quietSeed();
      final d = m3SldIsolateDeal(math.Random(seed)).dockets[0];
      final c = await _open(t, seed);
      final st = t.state<IdleHintState>(find.byType(IdleHint).first);
      await _pump(t, 9500);
      expect(st.showing, isTrue);
      final onMap = M3SldIsolatePoint.values.where((p) => d.kind != _K.radial || (p != _P.cbB && p != _P.tie)).length;
      expect(st.debugOptions, hasLength(onMap + 3));
      expect(st.debugFrame?.press ?? 0, 0);
      await t.tapAt(const Offset(4, 400));
      await t.pump();
      expect(st.showing, isFalse, reason: 'any touch hides it');
      await _close(t, c);
    });
  });
}

/// A seed whose first docket is the coworker's (the ring closed today).
int _coworkerFirstSeed() {
  for (var s = 1;; s++) {
    if (m3SldIsolateDeal(math.Random(s)).callAt == 0) return s;
  }
}

/// A seed whose first docket is a radial (and not the coworker's).
int _radialFirstSeed() {
  for (var s = 1;; s++) {
    final d = m3SldIsolateDeal(math.Random(s));
    if (d.callAt != 0 && d.dockets[0].kind == _K.radial) return s;
  }
}

/// A seed whose first docket is not the coworker's (he stays away while idle).
int _quietSeed() {
  for (var s = 1;; s++) {
    if (m3SldIsolateDeal(math.Random(s)).callAt != 0) return s;
  }
}
