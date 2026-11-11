// Lesson 3.8 (সার্ভিস কেবিল ও এনার্জি মিটার), কাজ 1 "শেষ মাইল": the rules (the
// right cores for the docket's phase, no cut insulation, the bearer before
// the cable and then the clips, no taut cable, the U drip loop), the deal,
// the reason libraries, and the level in the shell: idle perf, the guide
// first, the guide's tap, a full clean play to a pass (with the coworker
// refused), slip cards (a wrong drum, the cable before the bearer, no drip
// loop) and listening to him.
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
import 'package:slm_flutter/features/game/level_frame.dart' show StruckOutCard;
import 'package:slm_flutter/features/game/level_shell.dart';
import 'package:slm_flutter/features/game/m3_service_drop.dart';
import 'package:slm_flutter/features/game/mistake_kit.dart';
import 'package:slm_flutter/features/game/scene_kit.dart' show GuideIntro;
import 'package:slm_flutter/features/game/spoken_once.dart';
import 'package:slm_flutter/features/guide/guide_director.dart';
import 'package:slm_flutter/features/guide/mascot_speech_library.dart';
import 'package:slm_flutter/features/zero_loss/zero_loss_fx.dart';

import 'support/intro_wait.dart';
import 'support/option_lengths.dart';

const _ctx = LevelContext(
  rungId: '3.8/do/0',
  kind: CatalogRungKind.doKind,
  lessonId: '3.8',
  lessonTitleBn: '',
  ladderStep: 0,
  doIndex: 1,
  doCount: 2,
);

final _pack = m3ServiceDropPacks['do_3_8_a']!;

/// The level's new art folder is not in pubspec.yaml yet (the director adds
/// it): serve unbundled assets from the repo so the mistake cards draw.
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

Future<void> _pickWrong(WidgetTester t, List<String> wrong) async {
  expect(find.byType(ChoiceDeck), findsOneWidget);
  final w = _onScreen(wrong);
  expect(w, isNotEmpty);
  await t.tap(w.first, warnIfMissed: false);
}

/// Design px → screen px on the 392 × 850 test screen.
const _k = 392 / 360;
M3ServiceDropGeo get _geo => M3ServiceDropGeo.forScene((360 * 850 / 392).clamp(560.0, 900.0), 0);
Offset _screen(Offset design) => design * _k;

Widget _app(Widget home, {GlobalKey<NavigatorState>? nav}) =>
    DefaultAssetBundle(bundle: _DiskBundle(), child: MaterialApp(navigatorKey: nav, home: home));

Future<ProviderContainer> _open(WidgetTester t, int seed) async {
  t.view.physicalSize = const Size(784, 1700);
  t.view.devicePixelRatio = 2.0;
  final c = ProviderContainer();
  final nav = GlobalKey<NavigatorState>();
  await t.pumpWidget(UncontrolledProviderScope(container: c, child: _app(const Scaffold(body: SizedBox()), nav: nav)));
  unawaited(nav.currentState!.push(MaterialPageRoute<bool>(
    builder: (_) => M3ServiceDropPage(ctx: _ctx, pack: _pack, muted: true, seed: seed),
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

Future<void> _reason(WidgetTester t, List<String> right) async {
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue, reason: '${right.first} deck');
  await _pump(t, 700);
  await _pickRight(t, right);
  await _pump(t, 4500);
}

Future<void> _gotIt(WidgetTester t) async {
  await t.tap(find.text(MistakeLines.gotIt));
  await _pump(t, 600);
  expect(find.byType(MistakeCard), findsNothing);
}

/// The drum station, done right.
Future<void> _cable(WidgetTester t, M3ServiceDropDeal d) async {
  await t.tapAt(_screen(_geo.drumRect(d.right).center));
  await _pump(t, 400);
  expect(find.byType(MistakeCard), findsNothing);
  await _reason(t, M3ServiceDropLines.whyRight(M3ServiceDropStation.cable, three: d.three));
  // He climbs the pole; then the coworker comes.
  await _pump(t, 1000);
}

/// He comes: refuse ([held]) or listen.
Future<void> _coworker(WidgetTester t, {required bool held}) async {
  expect(await _pumpUntil(t, find.byType(CoworkerPeek), maxMs: 6000), isTrue, reason: 'he comes');
  expect(await _pumpUntil(t, find.byType(ChoiceDeck)), isTrue);
  await _pump(t, 600);
  held ? await _pickRight(t, M3ServiceDropLines.coworker.right) : await _pickWrong(t, M3ServiceDropLines.coworker.wrong);
  await _pump(t, 2600);
}

Future<void> _use(WidgetTester t, String tool) async {
  await t.tap(_label(tool));
  await _pump(t, 200);
  await t.tapAt(_screen(_geo.spanRect.center));
  await _pump(t, 400);
}

void main() {
  group('rules', () {
    test('deals: single- or three-phase; one right drum, one cut of the same cores, one of the other cores; fresh every play', () {
      final seen = <String>{};
      for (var s = 0; s < 60; s++) {
        final d = m3ServiceDropDeal(math.Random(s));
        expect(d.drums, hasLength(3));
        expect(d.right, isNot(-1));
        expect(d.drums.where((x) => x.cut), hasLength(1));
        expect(d.drums[d.cut].four, d.three);
        expect(d.drums[d.wrong].four, isNot(d.three));
        expect({d.right, d.cut, d.wrong}, hasLength(3));
        seen.add('${d.three}${d.right}${d.cut}');
      }
      expect(seen.length, greaterThan(8));
    });

    M3ServiceDropRun run([bool three = false]) => M3ServiceDropRun(M3ServiceDropDeal(
          three: three,
          drums: [M3ServiceDropDrum(four: !three, cut: false), M3ServiceDropDrum(four: three, cut: true), M3ServiceDropDrum(four: three, cut: false)],
        ));

    test('cable: the wrong cores and cut insulation are slips; the right drum is taken', () {
      for (final three in [false, true]) {
        final r = run(three);
        expect(r.takeDrum(0), M3ServiceDropMistakes.wrongCore);
        expect(r.takeDrum(1), M3ServiceDropMistakes.cutInsulation);
        expect(r.taken, isNull);
        expect(r.slips, 2);
        expect(r.takeDrum(2), isNull);
        expect(r.taken, 2);
        expect(r.caught, contains(M3ServiceDropLines.caughtCore));
        expect(r.caught, isNot(contains(M3ServiceDropLines.caughtCut)), reason: 'he took the cut one first');
      }
      final clean = run();
      expect(clean.takeDrum(2), isNull);
      expect(clean.clean, isTrue);
      expect(clean.caught, contains(M3ServiceDropLines.caughtCut));
    });

    test('bearer: the cable before the bearer is a slip; bearer → cable → clips; listening is a slip', () {
      final r = run()..next();
      expect(r.station, M3ServiceDropStation.bearer);
      expect(r.clip(), isFalse, reason: 'nothing to clip');
      expect(r.layCable(), M3ServiceDropMistakes.noBearer);
      expect(r.cableOn, isFalse);
      expect(r.stringBearer(), isTrue);
      expect(r.clip(), isFalse, reason: 'no cable yet');
      expect(r.layCable(), isNull);
      expect(r.clip(), isTrue);
      expect(r.caught, contains(M3ServiceDropLines.caughtBearer));
      expect(r.slips, 1);
      r.listenTaut();
      expect(r.slips, 2);
    });

    test('loop: straight in from the top or the side is a slip; the U drip loop passes', () {
      final r = run()
        ..next()
        ..next();
      expect(r.station, M3ServiceDropStation.loop);
      expect(r.route(M3ServiceDropEntry.top), M3ServiceDropMistakes.noDripLoop);
      expect(r.route(M3ServiceDropEntry.side), M3ServiceDropMistakes.noDripLoop);
      expect(r.done, isFalse);
      expect(r.route(M3ServiceDropEntry.loop), isNull);
      expect(r.done, isTrue);
      expect(r.caught, contains(M3ServiceDropLines.caughtLoop));
      expect(r.percent, 70);
      expect(r.passed, isTrue);
    });

    test('English digits only; every mistake has its picture and lesson point; no deadly; unique keys', () {
      final all = <String>[
        M3ServiceDropLines.intro,
        ...M3ServiceDropLines.tasks,
        for (final s in M3ServiceDropStation.values) ...M3ServiceDropLines.whyRight(s),
        ...M3ServiceDropLines.cableWhyThree,
        ...M3ServiceDropLines.excuses,
        ...M3ServiceDropLines.coworker.recordedLines,
        ...M3ServiceDropLines.coworker.right,
        ...M3ServiceDropLines.coworker.wrong,
        ...M3ServiceDropLines.coworker.asks,
        for (final m in M3ServiceDropMistakes.all) m.textBn,
        M3ServiceDropLines.allSet,
        M3ServiceDropLines.fail,
      ];
      for (final l in all) {
        expect(RegExp('[০-৯]').hasMatch(l), isFalse, reason: l);
        expect(l.contains('পানি'), isFalse, reason: l);
      }
      expect(M3ServiceDropMistakes.all.where((m) => m.deadly), isEmpty);
      expect(M3ServiceDropMistakes.all.map((m) => m.key).toSet(), hasLength(M3ServiceDropMistakes.all.length));
      expect(M3ServiceDropMistakes.noDripLoop.lessonPoint, isNull, reason: 'pro tip');
      for (final m in M3ServiceDropMistakes.all) {
        if (m != M3ServiceDropMistakes.noDripLoop) expect(m.lessonPoint, 0, reason: m.key);
        expect(m.key, startsWith('3.8/m3_service_drop/'));
        expect(File(m.art).existsSync(), isTrue, reason: m.art);
      }
      expect(m3ServiceDropPacks.keys, ['do_3_8_a']);
      expect(_pack.quickMs, kM3ServiceDropQuickMs);
    });

    test('reasons: same length, big enough, one right per deal; his exit line is recorded', () {
      final every = [
        for (final s in M3ServiceDropStation.values) ...M3ServiceDropLines.whyRight(s),
        ...M3ServiceDropLines.cableWhyThree,
        ...M3ServiceDropLines.excuses,
      ];
      expectSameLength('why', every);
      for (final three in [false, true]) {
        for (final s in M3ServiceDropStation.values) {
          final right = M3ServiceDropLines.whyRight(s, three: three);
          expectLibrary('$s', right, M3ServiceDropLines.excuses);
          for (var i = 0; i < 10; i++) {
            final d = dealChoices(right, M3ServiceDropLines.excuses, math.Random(i));
            expect(d.where((o) => o.correct).length, 1);
            expect(d.map((o) => o.textBn).toSet().length, 3);
          }
        }
      }
      final cw = M3ServiceDropLines.coworker;
      expectSameLength('choice', [...cw.right, ...cw.wrong]);
      expectLibrary('choice', cw.right, cw.wrong);
      expect(LearnVoice.resolve(cw.exitLine, rival: true), isNotNull);
    });

    test('geometry: the tap targets do not overlap', () {
      final g = _geo;
      for (var i = 0; i < 3; i++) {
        for (var j = i + 1; j < 3; j++) {
          expect(g.drumRect(i).overlaps(g.drumRect(j)), isFalse);
        }
      }
      final es = M3ServiceDropEntry.values;
      for (var i = 0; i < es.length; i++) {
        for (var j = i + 1; j < es.length; j++) {
          expect(g.entryRect(es[i]).overlaps(g.entryRect(es[j])), isFalse, reason: '${es[i]} ${es[j]}');
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
        await t.pumpWidget(ProviderScope(child: _app(M3ServiceDropPage(ctx: _ctx, pack: _pack, muted: true, seed: 4))));
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
        debugPrint('PERF m3_service_drop ${reduce ? 'reduce' : 'anim'}: ${perSec.toStringAsFixed(0)} rebuilds/s, $frames frames idle');
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

    testWidgets('the guide comes first: a tap does not skip him; then the drums and the docket', (t) async {
      t.view.physicalSize = const Size(784, 1700);
      t.view.devicePixelRatio = 2.0;
      await t.pumpWidget(ProviderScope(child: _app(M3ServiceDropPage(ctx: _ctx, pack: _pack, muted: true, seed: 1))));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.byType(GuideIntro), findsOneWidget);
      await t.tapAt(const Offset(200, 400));
      await t.pump(const Duration(milliseconds: 400));
      expect(find.byType(GuideIntro), findsOneWidget);
      await waitIntro(t);
      await _pump(t, 1500);
      expect(find.text(M3ServiceDropLines.permit), findsOneWidget);
      final d = m3ServiceDropDeal(math.Random(1));
      expect(find.text(d.three ? M3ServiceDropLines.three : M3ServiceDropLines.single), findsOneWidget);
      expect(find.text(M3ServiceDropLines.twin), findsWidgets);
      expect(find.text(M3ServiceDropLines.four), findsWidgets);
      await t.pumpWidget(const SizedBox());
      await t.pump(const Duration(seconds: 15));
      MascotTalk.reset();
      t.view.reset();
    });

    testWidgets('tapping the guide repeats the task, a different way each time', (t) async {
      final c = await _open(t, 2);
      final guide = find.byKey(const ValueKey('hud-guide'));
      expect(guide, findsOneWidget);
      final lines = <String>[];
      for (var i = 0; i < 2; i++) {
        await t.tapAt(t.getBottomRight(guide) - const Offset(50, 50));
        await _pump(t, 400);
        lines.add(c.read(guideDirectorProvider).line);
      }
      expect(lines.every((l) => l.contains(M3ServiceDropLines.askCable)), isTrue, reason: '$lines');
      expect(lines.first, isNot(lines.last));
      await _close(t, c);
    });

    testWidgets('flow: the right drum, refuse him, bearer → cable → clips, the drip loop → pass', (t) async {
      const seed = 3;
      final deal = m3ServiceDropDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _cable(t, deal);
      expect(find.text(M3ServiceDropLines.bearer), findsNothing, reason: 'the tools come out after him');
      await _coworker(t, held: true);
      await _use(t, M3ServiceDropLines.bearer);
      await _use(t, M3ServiceDropLines.cable);
      await _use(t, M3ServiceDropLines.clip);
      expect(find.byType(MistakeCard), findsNothing);
      await _reason(t, M3ServiceDropLines.bearerWhy);
      await _pump(t, 1000);
      await t.tapAt(_screen(_geo.entryRect(M3ServiceDropEntry.loop).center));
      await _pump(t, 400);
      expect(find.byType(MistakeCard), findsNothing);
      await _reason(t, M3ServiceDropLines.loopWhy);
      await _pump(t, 3000);
      final s = c.read(gameSaveProvider);
      expect(s.rungProgress['3.8/do/0'], 'cleared');
      expect(s.mistakes, isEmpty);
      expect(s.starsByRung['3.8/do/0'], greaterThan(0));
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(find.text(M3ServiceDropLines.caughtCall), findsOneWidget);
      expect(find.text(M3ServiceDropLines.caughtCut), findsOneWidget);
      expect(t.takeException(), isNull);
      await _close(t, c);
    });

    testWidgets('slips: the cut drum, listening to him, the cable before the bearer → struck out', (t) async {
      const seed = 5;
      final deal = m3ServiceDropDeal(math.Random(seed));
      final c = await _open(t, seed);
      await t.tapAt(_screen(_geo.drumRect(deal.cut).center));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(find.text(MistakeLines.slipHead), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M3ServiceDropMistakes.cutInsulation.key);
      await _gotIt(t);
      await _cable(t, deal);
      await _coworker(t, held: false);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.map((m) => m.key), contains(M3ServiceDropMistakes.tautCable.key));
      await _gotIt(t);
      await _use(t, M3ServiceDropLines.cable);
      expect(find.byType(StruckOutCard), findsOneWidget);
      expect(c.read(gameSaveProvider).rungProgress['3.8/do/0'], isNot('cleared'));
      await _close(t, c);
    });

    testWidgets('no drip loop: the slip card; then the U loop passes', (t) async {
      const seed = 7;
      final deal = m3ServiceDropDeal(math.Random(seed));
      final c = await _open(t, seed);
      await _cable(t, deal);
      await _coworker(t, held: true);
      await _use(t, M3ServiceDropLines.bearer);
      await _use(t, M3ServiceDropLines.cable);
      await _use(t, M3ServiceDropLines.clip);
      await _reason(t, M3ServiceDropLines.bearerWhy);
      await _pump(t, 1000);
      await t.tapAt(_screen(_geo.entryRect(M3ServiceDropEntry.top).center));
      await _pump(t, 600);
      expect(find.byType(MistakeCard), findsOneWidget);
      expect(c.read(gameSaveProvider).mistakes.single.key, M3ServiceDropMistakes.noDripLoop.key);
      await _gotIt(t);
      await t.tapAt(_screen(_geo.entryRect(M3ServiceDropEntry.loop).center));
      await _pump(t, 400);
      await _reason(t, M3ServiceDropLines.loopWhy);
      await _pump(t, 3000);
      expect(find.byType(LevelPassPanel), findsOneWidget);
      expect(c.read(gameSaveProvider).rungProgress['3.8/do/0'], 'cleared');
      await _close(t, c);
    });
  });
}
